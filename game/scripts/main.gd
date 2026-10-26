extends Node3D

## Stunt Car VR - DE Test 1 "Drop & Dangle"
## Throwaway FEEL prototype (Godot 4.7 / OpenXR, Quest-native target).
## One ribbon track, one placeholder Odd Rod car, grab-wheel steering,
## Drop Start + drone recovery with cockpit prep while dangling, and the
## lean-for-traction experiment. See design-spec.md items 1-16.
## Fix Pass 6 adds the project's first audio: synthesized engine + skid
## as an information channel (see the AUDIO constants block).
##
## Driving is a custom kinematic path model (path distance s + lateral
## offset), Crammond-flavoured: rationed boost, slope gravity, banked
## corner drift you must counter-steer, ballistic gap jumps, touchdown
## quality from impact speed + alignment, dent + smoke on hard landings.
##
## Grab rule (documented choice): the LAST hand to squeeze grip near the
## wheel drives it; if that hand releases while the other still grips,
## the other hand takes over (its angle reference resets on takeover).

const MODE_HANG: int = 0
const MODE_DRIVE: int = 1
const MODE_AIR: int = 2
const MODE_DONE: int = 3

# Fix Pass 6 (Item 2): the road is 8 m wide. Chris, run 6: the
# original "gave you the sense the road was wide and massive... there
# was room to manoeuvre," and he needs the width to properly test
# steering. Everything derived from HALF_WIDTH (surface, skirts,
# edge strips, gantry, off-track and landing checks) follows.
const HALF_WIDTH: float = 4.0
const RIBBON_DEPTH: float = 0.45 # box-section depth so the ribbon reads edge-on
const CLEARANCE: float = 0.35
const HANG_LEN: float = 5.5
const HANG_CLEAR: float = 1.2
const GRAV: float = 9.8
const SWITCH_NAMES: Array[String] = ["FUEL", "SPARK", "BOOST"]
const PREP_BOOST_CREDIT: float = 25.0
# Fix Pass 2: fixed driver eye anchor in car space. The seat offset rig
# lands the player's HMD exactly here on spawn/recenter, so physical
# seated height no longer floats the driver on top of the car. The wheel
# hub sits 0.45 m forward of the eye and 0.26 m below it (natural reach).
const EYE_ANCHOR: Vector3 = Vector3(0.0, 1.14, 0.05)
const WHEEL_HUB: Vector3 = Vector3(0.0, 0.88, -0.40)
# Fix Pass 3: the wheel is STOOD UP. Godot's TorusMesh ring lies in the
# XZ plane (axis +Y); the old -22 deg X-tilt therefore left the rim
# plane ~68 deg off vertical - a flat plate with its face pointing up.
# The tilt node rotates WHEEL_TILT_DEG about X, which puts the rim
# plane 90 - 68 = 22 deg off vertical, face toward the driver, and the
# rim spins about its own axis inside that node.
const WHEEL_TILT_DEG: float = 68.0
# Fix Pass 3: grip proximity radii widened (live hands land where they
# land; the origin-true controller reps are the other half of this).
# Fix Pass 4: run 4 live-verified the grip channels, so the dash
# insurance radius became the defect (Chris: switches "activated fairly
# far away from my hand") - dash/prep activation is now near-touch at
# 0.15 m, applied in the one place proximity is computed
# (_dash_ctl_near). The wheel radius STAYS 0.40: it measures hand to
# hub centre, and a hand ON the rim already reads ~0.2 m, so
# tightening it would break rim grabs; the complaint named the levers.
const WHEEL_GRAB_RADIUS: float = 0.40
const DASH_CTL_RADIUS: float = 0.15
# Fix Pass 5 (the feel pass) - suspension / mass model. Per-axle spring
# states (front/rear compression in metres) chase geometry targets
# derived from the road: how far the road surface at each axle sits
# above/below the centre tangent plane (wheelbase filtering), scaled by
# a crest load factor (the road falling away unloads the springs), plus
# accel/brake weight transfer. Body heave/pitch are DERIVED from the
# spring attach heights (attach = road rise - compression), so the
# visible car, the wheel travel and the view all read the same state.
# Rebound air is a result, not a script: when both axles reach full
# droop still extending fast (or the crest load factor hits ~zero at
# both axles), the car leaves the road ballistically.
const SUSP_TRAVEL: float = 0.34 # full stroke, metres of compression
const SUSP_REST: float = 0.10 # compression at rest under the car's weight
const SUSP_K: float = 160.0 # spring rate toward target (1/s^2)
const SUSP_DAMP: float = 4.6 # underdamped on purpose: it must overshoot
const SUSP_TRANSFER_K: float = 0.0055 # compression shift per m/s^2 of long. accel
const AXLE_F: float = 1.55 # front axle, metres ahead of car origin along s
const AXLE_R: float = 1.45 # rear axle, metres behind
const WHEELBASE: float = 3.0
# Fix Pass 5 - suspension-driven view behaviour, applied on a dedicated
# node in the seat stack (car -> SeatOffset -> ViewSpring -> XROrigin).
# The anchor correction stays on SeatOffset and is never touched by
# this; the view offsets are transient, zero at rest, and only exist
# while grounded (DRIVE/AIR) - the hang has its own motion.
const VIEW_PITCH_GAIN: float = 0.6
const VIEW_HEAVE_GAIN: float = 0.35
# Fix Pass 5 - lean view-tilt amplification (Chris, run 5: "i'm not
# really getting a sense of leaning, the view would have to tilt
# more"). This REVISES the experiment's original "input only, no
# camera roll" rule at his direction: while the experiment is ON, the
# view rolls LEAN_TILT_STEP_DEG per full lean times LEAN_VIEW_GAIN.
const LEAN_VIEW_GAIN: float = 1.25
const LEAN_TILT_STEP_DEG: float = 10.0
# Fix Pass 5 - precarious dangle. Two pendulum axes on DIFFERENT
# lengths (out of phase -> the resultant path is diagonal and never
# settles into a single-plane rhythm), light damping, plus drone dips:
# the pivot drops briefly and corrects; on a big dip the lines go
# slack and the car free-falls a beat before they catch.
const PEND_LEN_F: float = 5.5
const PEND_LEN_L: float = 3.9
const PEND_DAMP: float = 0.10
const DIP_K: float = 30.0
const DIP_DAMP: float = 6.5
const DIP_SLACK_IMPULSE: float = -1.5 # dip impulse at/below this -> lines slack
# Fix Pass 3: the seat anchor applies only on a STABLE tracked pose:
# the camera's local position must move less than ANCHOR_STABLE_EPS
# across ANCHOR_STABLE_FRAMES consecutive physics frames. The old code
# applied on the first frame any tracking data existed - a single
# snapshot of whatever transient pose the runtime handed over first.
const ANCHOR_STABLE_FRAMES: int = 20
const ANCHOR_STABLE_EPS: float = 0.01
const ANCHOR_FALLBACK_FRAMES: int = 600
# Fix Pass 6 (Item 1) - driver-BODY seat spring, the "Star Wars
# effect". A second, independent spring layer for the driver's body
# in the seat, stacked ABOVE the car's ViewSpring (car ->
# SeatOffset -> ViewSpring -> BodySpring -> XROrigin). The car's
# suspension moves the whole cockpit; this layer moves ONLY the
# viewpoint rig inside it - on a touchdown the car stops on its
# springs and then the driver's eyes keep sinking INTO the seat and
# rebound a beat later. Two different sensations at once (Chris).
# Character: SOFTER and LAGGIER than the car springs - lower natural
# frequency (BODY_OMEGA ~1.6 Hz vs the car springs' ~2 Hz) and its
# own damping - driven by EVENTS (touchdown impulse scaled by
# impact, suspension bottoming, hard accel/brake body pitch, the
# dangle's line-catch thump), never by the anchor. Zero at rest.
const BODY_K: float = 100.0 # body spring rate (1/s^2) - softer than SUSP_K
const BODY_DAMP: float = 5.2 # underdamped: sink, overshoot, settle late
const BODY_MAX_SINK: float = 0.055 # depth cap, m (a few cm at a hard landing)
const BODY_IMPULSE_K: float = 0.13 # sink velocity per m/s of touchdown impact
const BODY_PITCH_K: float = 0.35 # body pitch per unit of sink travel
const BODY_BRAKE_PITCH_K: float = 0.0016 # forward body pitch per m/s^2 of braking
const BODY_ACCEL_SINK_K: float = 0.0022 # seat press per m/s^2 of longitudinal accel
const BODY_CATCH_IMPULSE: float = 0.16 # line-catch thump into the seat, m/s
const BODY_MIN_IMPULSE: float = 2.2 # impacts below this vy barely register
# Fix Pass 6 (Item 3) - engine + skid audio, the project's first
# audio. Synthesized sources only (generated in code, no assets);
# audio is an INFORMATION channel: the engine note tracks
# speed/load/boost (airborne = revs unload), the skid gain tracks
# the model's TRUE tire slip state (the grip-modified cornering
# drift) - silent while gripping, rising at the limit, silent while
# airborne. Conservative fixed levels, no new user commands.
const AUDIO_ENGINE_DB: float = -17.0 # engine level at full song
const AUDIO_ENGINE_IDLE_DB: float = -23.0 # engine level at idle / hang
const AUDIO_SKID_MAX_DB: float = -13.0 # skid level at full slip
const AUDIO_SKID_FLOOR_DB: float = -34.0 # skid level at the onset of slip
const AUDIO_SLIP_ONSET: float = 1.2 # |drift| (m/s) where tires start to sing
const AUDIO_SLIP_SPAN: float = 3.8 # |drift| range from onset to full slip
const AUDIO_STALL_MS: int = 600 # physics-tick gap that counts as a stall

# --- track samples ---
var t_pts: Array[Vector3] = []
var t_tan: Array[Vector3] = []
var t_bank: Array[float] = []
var t_curv: Array[float] = []
var t_gap: Array[bool] = []
var t_kv: Array[float] = [] # vertical curvature per sample (crest +)
var track_len: float = 0.0
var gap_s0: float = 0.0
var gap_s1: float = 0.0

# --- sim state ---
var mode: int = MODE_HANG
var hang_phase: String = "dangle"
var is_drop_start: bool = true
var car_s: float = 0.0
var car_lat: float = 0.0
var lat_vel: float = 0.0
var speed: float = 0.0
var wheel_angle: float = 0.0
var boost_meter: float = 60.0
var dent_level: int = 0
var smoke_on: bool = false
var last_touchdown: String = "-"
var was_airborne: bool = false
var finished_time: float = 0.0
var race_time: float = 0.0

# ballistic state
var air_vel: Vector3 = Vector3.ZERO
var air_time: float = 0.0
var air_s_est: float = 0.0
var air_from_gap: bool = false

# pendulum state (hang)
var pend_th_f: float = 0.30
var pend_th_l: float = 0.12
var pend_om_f: float = 0.0
var pend_om_l: float = 0.0
var anchor_pos: Vector3 = Vector3.ZERO
var anchor_from: Vector3 = Vector3.ZERO
var anchor_target: Vector3 = Vector3.ZERO
var anchor_t: float = 0.0
var hang_from_pos: Vector3 = Vector3.ZERO
var drop_target_s: float = 2.0

# prep sequence
var prep_order: Array[int] = []
var prep_index: int = 0
var prep_done: bool = false
var switch_on: Array[bool] = [false, false, false]

# lean experiment
var lean_on: bool = false
var lean_neutral_x: float = 0.0
var lean_value: float = 0.0
var grip_mult: float = 1.0
var test_lean: float = -99.0 # smoke/render override; -99 = off

# inputs (merged XR + desktop + test overrides)
var in_throttle: float = 0.0
var in_brake: float = 0.0
var in_boost: bool = false
var test_mode: bool = false
var test_throttle: float = 0.0
var test_brake: float = 0.0
var test_boost: bool = false
var test_release_queued: bool = false

# Fix Pass 5 suspension state (per-axle spring model; see constants).
# susp_x/susp_v are gone: compression lives in c_f/c_r now.
var c_f: float = SUSP_REST
var c_r: float = SUSP_REST
var cv_f: float = 0.0
var cv_r: float = 0.0
var geom_f: float = 0.0 # road rise at the front axle rel. centre plane
var geom_r: float = 0.0
var load_f: float = 1.0 # crest load factors (1 = fully planted)
var load_r: float = 1.0
var pitch_extra: float = 0.0 # body pitch from spring attach heights, rad
var heave_off: float = 0.0 # body height offset from springs, m
var long_accel_f: float = 0.0 # filtered longitudinal accel, m/s^2
var prev_speed: float = 0.0
var bounce_pending: bool = false # suspension asked to go airborne
var bounce_vy: float = 0.0
var susp_peak_c: float = SUSP_REST # recent peak avg compression (decays)
var wheel_mis: Array[MeshInstance3D] = []
var wheel_axle: Array[int] = [] # 0 = front, 1 = rear, parallel to wheel_mis
var view_node: Node3D # seat-stack node carrying suspension view motion

# Fix Pass 5 dangle state: drone dips, line slack, catch blend, and a
# lagged orientation direction (compliance - the car settles a beat
# behind the swing instead of being rigidly framed to the pivot).
var pivot_pos: Vector3 = Vector3.ZERO # effective hang pivot (anchor + dip)
var dip_y: float = 0.0
var dip_vy: float = 0.0
var dip_accel: float = 0.0
var dip_timer: float = 2.0
var dip_seed: int = 0
var slack_t: float = 0.0
var hang_pos: Vector3 = Vector3.ZERO # car position while lines are slack
var hang_vel: Vector3 = Vector3.ZERO
var catch_t: float = 1.0
var catch_from: Vector3 = Vector3.ZERO
var orient_dir: Vector3 = Vector3.DOWN
var orient_have: bool = false

# Fix Pass 6 (Item 1) driver-body spring state: sink depth (positive
# = sunk into the seat) and its velocity, integrated every physics
# frame in _update_body_spring. body_node carries the offset in the
# seat stack; body_node_fb mirrors it for the desktop fallback cam.
var body_sink: float = 0.0
var body_sink_v: float = 0.0
var body_bottom_cool: float = 0.0 # cooldown between bottoming thumps
var body_node: Node3D
var body_node_fb: Node3D

# Fix Pass 6 (Item 3) audio state. slip_state is the model's tire
# slip (0 = gripping .. 1 = fully sliding), computed in
# _update_drive from the grip-modified drift and consumed by the
# skid gain - it is a physics output, not an input proxy.
# Teardown discipline: audio_latched is set by application
# focus-out / close request / scene-tree exit and STOPS both
# players; it clears only on a genuine focus-in while a race is
# live. audio_stalled is the watchdog state (physics ticks gone
# quiet): gains are cut while it holds, physics resuming clears it.
var slip_state: float = 0.0
var race_started: bool = false
var audio_latched: bool = false
var audio_stalled: bool = false
var audio_last_physics_ms: int = 0
var audio_rpm: float = 0.8 # smoothed engine speed factor (pitch scale)
var audio_skid_now: float = 0.0 # smoothed skid gain, 0..1
var engine_player: AudioStreamPlayer
var skid_player: AudioStreamPlayer

# --- nodes ---
var car: Node3D
var car_body: Node3D
var nose_mi: MeshInstance3D
var wheel_node: Node3D # tilt node (stood-up wheel plane)
var wheel_spin: Node3D # spin node inside it (rotates about the wheel axis)
var smoke_mi: MeshInstance3D
var lean_needle: MeshInstance3D
var drone: Node3D
var drone_rotors: Array[MeshInstance3D] = []
var line_mis: Array[MeshInstance3D] = []
var switch_pivots: Array[Node3D] = []
var dash_ctl_nodes: Array[Node3D] = []
var dash_ctl_kinds: Array[String] = []
var state_label: Label3D
var panel_label: Label3D
var prep_label: Label3D
# Fix Pass 4: the DIAG block lives on its own small board (diag_label
# under diag_root); panel_label keeps the status + command list.
var diag_label: Label3D
var panel_root: Node3D
var diag_root: Node3D

var seat_offset: Node3D
var anchor_pending: bool = false
var anchor_wait_frames: int = 0
# Fix Pass 3 anchor state (reported on the panel DIAG block):
# NONE / PENDING / APPLIED-STABLE / APPLIED-FALLBACK. After a fallback
# apply, anchor_reapply_watch stays set so a later stable pose triggers
# exactly one re-apply from the real pose.
var anchor_state: String = "NONE"
var anchor_stable_frames: int = 0
var anchor_last_cam_pos: Vector3 = Vector3.ZERO
var anchor_have_last: bool = false
var anchor_reapply_watch: bool = false
# Fix Pass 3 live diagnostics (panel DIAG block, refreshed at ~5 Hz):
# raw grip-channel values per hand, exactly as the runtime delivers.
var diag_grip: Dictionary = {"L": 0.0, "R": 0.0}
var diag_click: Dictionary = {"L": false, "R": false}
var diag_force: Dictionary = {"L": 0.0, "R": 0.0}
var diag_block: String = ""
var diag_timer: float = 0.0
var origin: XROrigin3D
var xr_cam: XRCamera3D
var hand_ctrl: Dictionary = {}
var ctrl_rep: Dictionary = {}
var xr_ok: bool = false
var fallback_cam: Camera3D

# grab state
var grab_hand: String = ""
var grab_prev_ang: float = 0.0
var gripping: Dictionary = {"L": false, "R": false}
var prev_btn: Dictionary = {}


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m


func _mat_unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _box(parent: Node, size: Vector3, pos: Vector3, mat: Material, bname: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	if mat != null:
		mi.material_override = mat
	if bname != "":
		mi.name = bname
	parent.add_child(mi)
	return mi


func _ready() -> void:
	_build_environment()
	_build_track()
	_build_car()
	_build_drone()
	_build_rig()
	_build_audio()
	start_race()
	set_process(true)


func _notification(what: int) -> void:
	# Fix Pass 6 (Item 3) audio teardown discipline: the latch is
	# set by application focus-out, by a close request, and by
	# scene-tree exit; it clears ONLY on a genuine focus-in (and
	# the audio update additionally requires a live race before
	# anything sounds). Audio never resumes uninvited.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT \
			or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_EXIT_TREE:
		_set_audio_latched(true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_set_audio_latched(false)


func _build_rig() -> void:
	# Rig stack: car -> seat_offset -> ViewSpring -> BodySpring ->
	# XROrigin3D -> camera/controllers. The seat offset carries the
	# Fix Pass 2 anchor correction; the origin itself stays at zero
	# so tracked poses pass through untouched (the lean experiment
	# reads the camera local to the origin).
	seat_offset = Node3D.new()
	seat_offset.name = "SeatOffset"
	car.add_child(seat_offset)
	# Fix Pass 5: ViewSpring sits between the anchor correction and
	# the origin and carries ONLY transient suspension/lean view
	# motion (zero at rest). The anchor math never sees it.
	view_node = Node3D.new()
	view_node.name = "ViewSpring"
	seat_offset.add_child(view_node)
	# Fix Pass 6: BodySpring sits ABOVE ViewSpring and moves ONLY
	# the viewpoint rig (the driver's body in the seat) - the
	# cockpit around it does not move. Zero at rest; never written
	# by the anchor math.
	body_node = Node3D.new()
	body_node.name = "BodySpring"
	view_node.add_child(body_node)
	origin = XROrigin3D.new()
	origin.name = "Origin"
	body_node.add_child(origin)
	xr_cam = XRCamera3D.new()
	origin.add_child(xr_cam)
	var xr_interface: XRInterface = XRServer.find_interface("OpenXR")
	if xr_interface != null and xr_interface.is_initialized():
		get_viewport().use_xr = true
		xr_ok = true
	else:
		# The desktop fallback camera gets the same two spring
		# layers: it is parented to a mirror BodySpring node in car
		# space (its position stays EYE_ANCHOR at rest).
		body_node_fb = Node3D.new()
		body_node_fb.name = "BodySpringFB"
		car.add_child(body_node_fb)
		fallback_cam = Camera3D.new()
		fallback_cam.position = EYE_ANCHOR
		fallback_cam.name = "FallbackCam"
		body_node_fb.add_child(fallback_cam)
		fallback_cam.current = true
	for hand: String in ["L", "R"]:
		# Tracker binding per the Duel field census on this rig (Quest 3):
		# plain "left_hand"/"right_hand". Pose is now set EXPLICITLY to
		# "default" (the action map's default_pose action, bound to the
		# aim path): the same census found live data only on the
		# "default"/"palm_pose" tracker poses on this VDXR rig, so
		# "grip_pose" must NOT be selected - it carries no live data
		# here and the controllers would freeze.
		var tracker_name: StringName = &"left_hand" if hand == "L" else &"right_hand"
		var c := XRController3D.new()
		c.tracker = tracker_name
		c.pose = &"default"
		origin.add_child(c)
		hand_ctrl[hand] = c
		_build_controller_rep(c, hand)


func _build_controller_rep(ctrl: XRController3D, hand: String) -> void:
	# Fix Pass 3: the rep is rebuilt ORIGIN-TRUE. Chris's wave test put
	# the drawn controllers ~a controller's length ahead of his real
	# hands; the old rep's body sat offset from the node origin the
	# grab math measures from, and the "default" (aim) pose origin is
	# itself forward of the palm. Now the visible body is CENTRED on
	# the node origin and a bright sphere sits exactly AT the origin:
	# the point he sees is the point the math measures from.
	var rep := Node3D.new()
	rep.name = "ControllerRep" + hand
	ctrl.add_child(rep)
	ctrl_rep[hand] = rep
	var accent: Color = Color(0.25, 0.85, 1.0) if hand == "L" else Color(1.0, 0.55, 0.2)
	_box(rep, Vector3(0.040, 0.028, 0.110), Vector3.ZERO, _mat(Color(0.16, 0.16, 0.18)))
	_box(rep, Vector3(0.044, 0.010, 0.034), Vector3(0, 0.019, -0.008), _mat_unshaded(accent))
	var origin_dot := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.013
	sm.height = 0.026
	origin_dot.mesh = sm
	origin_dot.position = Vector3.ZERO
	origin_dot.material_override = _mat_unshaded(accent)
	rep.add_child(origin_dot)


func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.55, 0.85)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.72, 0.85)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.68, 0.88)
	# Fix Pass 1: fog cut back hard (was 0.0016) - distant ribbon segments
	# washed out into the sky and the track read as invisible.
	env.fog_density = 0.00015
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.15
	add_child(sun)
	# Distant ground plane - the height reference. 30+ m below the ribbon.
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(2400.0, 2400.0)
	ground.mesh = pm
	ground.position = Vector3(0.0, 0.0, -300.0)
	ground.material_override = _mat(Color(0.23, 0.38, 0.20))
	add_child(ground)
	# A few ground blocks so the drop reads as motion, not void.
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i: int in 40:
		var bx: float = rng.randf_range(-260.0, 260.0)
		var bz: float = rng.randf_range(-560.0, 160.0)
		var bs: float = rng.randf_range(8.0, 30.0)
		_box(self, Vector3(bs, rng.randf_range(1.0, 4.0), bs), Vector3(bx, 0.8, bz),
			_mat(Color(0.30, 0.44, 0.26)))


# ---------------------------------------------------------------- track

var _gen_pos: Vector3 = Vector3.ZERO
var _gen_yaw: float = 0.0
var _gen_phi: float = 0.0
var _gen_bank: float = 0.0


func _gen_append(is_gap: bool, curv: float) -> void:
	var hd := Vector3(-sin(_gen_yaw), 0.0, -cos(_gen_yaw))
	var tanv: Vector3 = (hd * cos(_gen_phi) + Vector3.UP * sin(_gen_phi)).normalized()
	t_pts.append(_gen_pos)
	t_tan.append(tanv)
	t_bank.append(_gen_bank)
	t_curv.append(curv)
	t_gap.append(is_gap)


func _walk(steps: int, yaw_rate: float, phi_target: float, bank_target: float, is_gap: bool, phi_rate: float = 0.006, bank_rate: float = 0.012) -> void:
	for i: int in steps:
		_gen_phi = move_toward(_gen_phi, phi_target, phi_rate)
		_gen_bank = move_toward(_gen_bank, bank_target, bank_rate)
		_gen_yaw += yaw_rate
		var hd := Vector3(-sin(_gen_yaw), 0.0, -cos(_gen_yaw))
		var tanv: Vector3 = (hd * cos(_gen_phi) + Vector3.UP * sin(_gen_phi)).normalized()
		_gen_pos += tanv * 1.0
		_gen_append(is_gap, yaw_rate)


func _build_track() -> void:
	t_pts.clear()
	t_tan.clear()
	t_bank.clear()
	t_curv.clear()
	t_gap.clear()
	_gen_pos = Vector3(0.0, 30.0, 0.0)
	_gen_yaw = 0.0
	_gen_phi = 0.0
	_gen_bank = 0.0
	_gen_append(false, 0.0)
	_walk(50, 0.0, 0.0, 0.0, false) # start straight
	_walk(80, 0.0, deg_to_rad(16.0), 0.0, false) # steep climb
	_walk(47, deg_to_rad(90.0) / 47.0, 0.0, deg_to_rad(34.0), false) # banked corner (left, R~30)
	# Fix Pass 3 (phantom lean): the default bank convergence
	# (0.012 rad/sample) left the corner's bank on ~50 m of following
	# STRAIGHT - measured 27 deg of bank at s=185, on the "flat run" -
	# so the car presented rolled on straights with no cornering
	# input, and the gap was crossed on a banked frame. The post-
	# corner walks converge bank at 0.10 rad/sample instead: the
	# track is truly flat ~6 m past the corner exit.
	_walk(20, 0.0, 0.0, 0.0, false, 0.006, 0.10) # flat run to the lip
	_walk(10, 0.0, deg_to_rad(10.0), 0.0, false, 0.030, 0.10) # launch lip
	gap_s0 = float(t_pts.size())
	_walk(14, 0.0, deg_to_rad(2.0), 0.0, true, 0.020) # THE GAP - no ribbon
	gap_s1 = float(t_pts.size())
	_walk(40, 0.0, deg_to_rad(-3.4), 0.0, false, 0.020) # landing straight
	_walk(90, 0.0, deg_to_rad(-13.7), 0.0, false) # descent
	_walk(50, 0.0, 0.0, 0.0, false) # finish straight
	track_len = float(t_pts.size() - 1)
	# Fix Pass 5: per-sample vertical curvature of the road profile,
	# kv = -d(elevation angle)/ds. Positive over a crest (the road
	# falls away); the suspension's crest load factor reads it.
	t_kv.clear()
	for ki: int in t_tan.size():
		var km: int = maxi(ki - 1, 0)
		var kp: int = mini(ki + 1, t_tan.size() - 1)
		var phi_m: float = asin(clampf(t_tan[km].y, -1.0, 1.0))
		var phi_p: float = asin(clampf(t_tan[kp].y, -1.0, 1.0))
		t_kv.append(-(phi_p - phi_m) / float(kp - km))

	# --- ribbon mesh (box section: dark top + orange skirt sides/bottom,
	# unshaded edge strips) and stilts, merged ---
	# Fix Pass 1: the flat grey ribbon washed out against the sky and read
	# edge-on as nothing but pylons. It is now a 0.45 m deep box section:
	# near-black top against the light sky, saturated orange skirts so it
	# reads as a solid object from the cockpit and from above, unshaded
	# amber edge strips marking the driving line at distance.
	var surf_pos := PackedVector3Array()
	var surf_nrm := PackedVector3Array()
	var surf_col := PackedColorArray()
	var skirt_pos := PackedVector3Array()
	var skirt_nrm := PackedVector3Array()
	var skirt_col := PackedColorArray()
	var edge_pos := PackedVector3Array()
	var edge_nrm := PackedVector3Array()
	var edge_col := PackedColorArray()
	var stilt_pos := PackedVector3Array()
	var stilt_nrm := PackedVector3Array()
	var stilt_col := PackedColorArray()
	var hw: float = HALF_WIDTH
	var surf_c := Color(0.07, 0.07, 0.09)
	var skirt_c := Color(1.0, 0.5, 0.05)
	var bot_c := Color(0.55, 0.27, 0.03)
	var edge_c := Color(1.0, 0.72, 0.10)
	for i: int in t_pts.size() - 1:
		if t_gap[i] or t_gap[i + 1]:
			continue
		var frame0: Dictionary = _frame_at(float(i))
		var frame1: Dictionary = _frame_at(float(i + 1))
		var p0: Vector3 = frame0["pos"]
		var p1: Vector3 = frame1["pos"]
		var s0: Vector3 = frame0["side"]
		var s1: Vector3 = frame1["side"]
		var u0: Vector3 = frame0["up"]
		var u1: Vector3 = frame1["up"]
		var l0: Vector3 = p0 - s0 * hw
		var r0: Vector3 = p0 + s0 * hw
		var l1: Vector3 = p1 - s1 * hw
		var r1: Vector3 = p1 + s1 * hw
		var bl0: Vector3 = l0 - u0 * RIBBON_DEPTH
		var br0: Vector3 = r0 - u0 * RIBBON_DEPTH
		var bl1: Vector3 = l1 - u1 * RIBBON_DEPTH
		var br1: Vector3 = r1 - u1 * RIBBON_DEPTH
		var up_avg: Vector3 = (u0 + u1) * 0.5
		var side_avg: Vector3 = (s0 + s1) * 0.5
		_add_quad(surf_pos, surf_nrm, surf_col, l0, r0, r1, l1, up_avg, surf_c)
		# box-section sides (skirts) + underside
		_add_quad(skirt_pos, skirt_nrm, skirt_col, l0, l1, bl1, bl0, -side_avg, skirt_c)
		_add_quad(skirt_pos, skirt_nrm, skirt_col, r1, r0, br0, br1, side_avg, skirt_c)
		_add_quad(skirt_pos, skirt_nrm, skirt_col, bl1, br1, br0, bl0, -up_avg, bot_c)
		# edge strips, raised 0.02 (unshaded: they stay bright at distance)
		_add_quad(edge_pos, edge_nrm, edge_col,
			l0 + u0 * 0.02, l0 + s0 * 0.36 + u0 * 0.02, l1 + s1 * 0.36 + u1 * 0.02, l1 + u1 * 0.02,
			up_avg, edge_c)
		_add_quad(edge_pos, edge_nrm, edge_col,
			r0 - s0 * 0.36 + u0 * 0.02, r0 + u0 * 0.02, r1 + u1 * 0.02, r1 - s1 * 0.36 + u1 * 0.02,
			up_avg, edge_c)
		# stilts every 10 m down to the ground
		if i % 10 == 0:
			var top: Vector3 = p0
			var bot := Vector3(p0.x, 0.0, p0.z)
			_add_box_verts(stilt_pos, stilt_nrm, stilt_col, (top + bot) * 0.5,
				Vector3(0.55, top.y - bot.y, 0.55), Color(0.42, 0.42, 0.46))
	_add_mesh(surf_pos, surf_nrm, surf_col, "TrackSurface")
	_add_mesh(skirt_pos, skirt_nrm, skirt_col, "TrackSkirt")
	_add_mesh(edge_pos, edge_nrm, edge_col, "TrackEdges", true)
	_add_mesh(stilt_pos, stilt_nrm, stilt_col, "Stilts")
	_build_gantry(2.0, Color(0.15, 0.6, 0.2), "START")
	_build_gantry(track_len - 2.0, Color(0.7, 0.15, 0.15), "FINISH")


func _add_quad(pp: PackedVector3Array, nn: PackedVector3Array, cc: PackedColorArray,
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	# two triangles a-b-c, a-c-d (CCW seen from the normal side)
	for v: Vector3 in [a, b, c, a, c, d]:
		pp.append(v)
		nn.append(n)
		cc.append(col)


func _add_box_verts(pp: PackedVector3Array, nn: PackedVector3Array, cc: PackedColorArray,
		center: Vector3, size: Vector3, col: Color) -> void:
	var h: Vector3 = size * 0.5
	var corners: Array[Vector3] = []
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				corners.append(center + Vector3(sx * h.x, sy * h.y, sz * h.z))
	# faces: index quads in corners[] order (x-,x+ by outer loop)
	var faces: Array = [
		[0, 1, 3, 2, Vector3(-1, 0, 0)], [4, 6, 7, 5, Vector3(1, 0, 0)],
		[0, 4, 5, 1, Vector3(0, -1, 0)], [2, 3, 7, 6, Vector3(0, 1, 0)],
		[0, 2, 6, 4, Vector3(0, 0, -1)], [1, 5, 7, 3, Vector3(0, 0, 1)],
	]
	for f: Array in faces:
		var n: Vector3 = f[4]
		var idxs: Array = [f[0], f[1], f[2], f[0], f[2], f[3]]
		for ix: int in idxs:
			pp.append(corners[ix])
			nn.append(n)
			cc.append(col)


func _add_mesh(pp: PackedVector3Array, nn: PackedVector3Array, cc: PackedColorArray, mname: String, unshaded: bool = false) -> void:
	if pp.is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = pp
	arrays[Mesh.ARRAY_NORMAL] = nn
	arrays[Mesh.ARRAY_COLOR] = cc
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = mname
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.9
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	add_child(mi)


func _build_gantry(s: float, col: Color, _label: String) -> void:
	var fr: Dictionary = _frame_at(s)
	var p: Vector3 = fr["pos"]
	var sd: Vector3 = fr["side"]
	var up: Vector3 = fr["up"]
	var g := Node3D.new()
	g.name = "Gantry" + _label
	add_child(g)
	_box(g, Vector3(0.35, 4.6, 0.35), p - sd * (HALF_WIDTH + 0.4) + up * 2.3, _mat(Color(0.2, 0.2, 0.22)))
	_box(g, Vector3(0.35, 4.6, 0.35), p + sd * (HALF_WIDTH + 0.4) + up * 2.3, _mat(Color(0.2, 0.2, 0.22)))
	var banner := _box(g, Vector3((HALF_WIDTH + 0.4) * 2.0, 0.7, 0.3), p + up * 4.6, _mat_unshaded(col))
	banner.global_transform = Transform3D(Basis(fr["side"], fr["up"], -fr["tan"]), banner.global_position)


## Frame (pos/side/up/tan/bank/curv/gap) at path distance s (float).
func _frame_at(s: float) -> Dictionary:
	var sf: float = clampf(s, 0.0, track_len)
	var i0: int = int(floor(sf))
	var i1: int = mini(i0 + 1, t_pts.size() - 1)
	var fr: float = sf - float(i0)
	var pos: Vector3 = t_pts[i0].lerp(t_pts[i1], fr)
	var tanv: Vector3 = t_tan[i0].lerp(t_tan[i1], fr).normalized()
	var bank: float = lerpf(t_bank[i0], t_bank[i1], fr)
	var side: Vector3 = tanv.cross(Vector3.UP).normalized()
	if side.length() < 0.1:
		side = Vector3.RIGHT
	var upv: Vector3 = side.cross(tanv).normalized()
	var side_b: Vector3 = (side * cos(bank) + upv * sin(bank)).normalized()
	var up_b: Vector3 = side_b.cross(tanv).normalized()
	return {
		"pos": pos, "tan": tanv, "side": side_b, "up": up_b,
		"bank": bank, "curv": lerpf(t_curv[i0], t_curv[i1], fr),
		"gap": t_gap[i0] or t_gap[i1],
		"kv": lerpf(t_kv[i0], t_kv[i1], fr),
	}


# ---------------------------------------------------------------- car

func _build_car() -> void:
	car = Node3D.new()
	car.name = "Car"
	add_child(car)
	car_body = Node3D.new()
	car_body.name = "Body"
	car.add_child(car_body)
	var paint := _mat(Color(0.85, 0.35, 0.08))
	var dark := _mat(Color(0.13, 0.13, 0.15))
	# Floor + side pods (driver sits centre, eye anchor at EYE_ANCHOR)
	_box(car_body, Vector3(1.30, 0.16, 3.30), Vector3(0, 0.32, 0), dark)
	_box(car_body, Vector3(0.34, 0.42, 2.60), Vector3(-0.72, 0.48, 0.1), paint)
	_box(car_body, Vector3(0.34, 0.42, 2.60), Vector3(0.72, 0.48, 0.1), paint)
	# Long nose with the engine block + blower you see from the seat
	nose_mi = _box(car_body, Vector3(0.86, 0.34, 1.50), Vector3(0, 0.52, -1.95), paint, "Nose")
	_box(car_body, Vector3(0.62, 0.30, 0.80), Vector3(0, 0.78, -1.85), dark) # engine block
	_box(car_body, Vector3(0.30, 0.26, 0.44), Vector3(0, 1.04, -1.85), _mat(Color(0.75, 0.75, 0.78))) # blower
	_box(car_body, Vector3(0.10, 0.20, 0.10), Vector3(-0.28, 1.0, -2.45), _mat(Color(0.6, 0.6, 0.62))) # stacks
	_box(car_body, Vector3(0.10, 0.20, 0.10), Vector3(0.28, 1.0, -2.45), _mat(Color(0.6, 0.6, 0.62)))
	# Roll bar behind the seat + rear deck
	_box(car_body, Vector3(0.08, 0.62, 0.08), Vector3(-0.42, 1.05, 0.78), dark)
	_box(car_body, Vector3(0.08, 0.62, 0.08), Vector3(0.42, 1.05, 0.78), dark)
	_box(car_body, Vector3(0.92, 0.08, 0.08), Vector3(0, 1.36, 0.78), dark)
	_box(car_body, Vector3(1.15, 0.30, 0.85), Vector3(0, 0.52, 1.55), paint)
	# Wheels (visual). Fix Pass 5: references are kept, tagged by axle,
	# so the suspension model can move them through their travel
	# relative to the body (the bounce you can SEE from the cockpit:
	# the nose and front tires working against the fixed surround).
	for wx: float in [-0.78, 0.78]:
		for wz: float in [-1.55, 1.45]:
			var w := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.34
			cm.bottom_radius = 0.34
			cm.height = 0.24
			w.mesh = cm
			w.rotation_degrees = Vector3(0, 0, 90)
			w.position = Vector3(wx, 0.34, wz)
			w.material_override = dark
			w.name = "WheelF" if wz < 0.0 else "WheelR"
			car_body.add_child(w)
			wheel_mis.append(w)
			wheel_axle.append(0 if wz < 0.0 else 1)
	# Smoke puff (basic dent carnage placeholder)
	smoke_mi = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.30
	sph.height = 0.60
	smoke_mi.mesh = sph
	smoke_mi.position = Vector3(0, 1.25, -1.85)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.25, 0.25, 0.25, 0.55)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mi.material_override = sm
	smoke_mi.visible = false
	car_body.add_child(smoke_mi)
	_build_cockpit()


func _build_cockpit() -> void:
	# Dash slab
	_box(car_body, Vector3(1.24, 0.30, 0.14), Vector3(0, 0.78, -0.62), _mat(Color(0.10, 0.10, 0.11)))
	# Steering column + grab wheel (wood-rimmed: this car's character).
	# Hub position from Fix Pass 2 stands: WHEEL_HUB, 0.45 m ahead of
	# EYE_ANCHOR and 0.26 m below it. Fix Pass 3 stands the wheel UP:
	# the tilt node rotates WHEEL_TILT_DEG about X so the rim plane
	# sits 22 deg off vertical facing the driver (see the WHEEL_TILT
	# note at the constants); the column is aligned to the wheel axis
	# (the tilt node's local +Y in car space) and runs from the dash
	# into the hub; the spin node inside the tilt node rotates about
	# that same axis, so the rim spins IN its plane - the old build
	# set rotation.z on the flat-tilted node, which precessed the
	# rim like a coin instead of spinning it.
	var tilt_rad: float = deg_to_rad(WHEEL_TILT_DEG)
	var wheel_axis := Vector3(0.0, cos(tilt_rad), sin(tilt_rad))
	var col := MeshInstance3D.new()
	var colm := CylinderMesh.new()
	colm.top_radius = 0.03
	colm.bottom_radius = 0.03
	colm.height = 0.34
	col.mesh = colm
	col.position = WHEEL_HUB - wheel_axis * 0.13
	col.rotation_degrees = Vector3(WHEEL_TILT_DEG, 0, 0)
	car_body.add_child(col)
	wheel_node = Node3D.new()
	wheel_node.name = "Wheel"
	wheel_node.position = WHEEL_HUB
	wheel_node.rotation_degrees = Vector3(WHEEL_TILT_DEG, 0, 0)
	car_body.add_child(wheel_node)
	wheel_spin = Node3D.new()
	wheel_spin.name = "WheelSpin"
	wheel_node.add_child(wheel_spin)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.185
	torus.outer_radius = 0.225
	rim.mesh = torus
	rim.material_override = _mat(Color(0.45, 0.28, 0.12)) # wood rim
	wheel_spin.add_child(rim)
	# spokes lie IN the rim plane (local XZ; thickness along local Y)
	_box(wheel_spin, Vector3(0.40, 0.03, 0.045), Vector3(0, 0, 0), _mat(Color(0.55, 0.55, 0.58)))
	_box(wheel_spin, Vector3(0.045, 0.03, 0.40), Vector3(0, 0, 0), _mat(Color(0.55, 0.55, 0.58)))
	var hub := MeshInstance3D.new()
	var hubm := CylinderMesh.new()
	hubm.top_radius = 0.055
	hubm.bottom_radius = 0.055
	hubm.height = 0.05
	hub.mesh = hubm
	hub.material_override = _mat_unshaded(Color(1.0, 0.75, 0.15))
	wheel_spin.add_child(hub)
	# 3 prep switches on the dash (lever pivots)
	var switch_cols: Array[Color] = [Color(0.9, 0.2, 0.15), Color(0.95, 0.8, 0.15), Color(0.2, 0.5, 0.95)]
	for i: int in 3:
		var piv := Node3D.new()
		piv.position = Vector3(-0.30 + 0.30 * float(i), 0.90, -0.60)
		piv.rotation_degrees = Vector3(-38, 0, 0)
		car_body.add_child(piv)
		switch_pivots.append(piv)
		_box(piv, Vector3(0.055, 0.20, 0.055), Vector3(0, 0.08, 0), _mat(Color(0.65, 0.65, 0.68)))
		_box(piv, Vector3(0.085, 0.06, 0.085), Vector3(0, 0.19, 0), _mat_unshaded(switch_cols[i]))
		_register_dash_ctl(piv, "switch%d" % i)
	# Red RESTART button + green LEAN toggle button (physical dash controls)
	var rst := Node3D.new()
	rst.position = Vector3(0.48, 0.90, -0.60)
	car_body.add_child(rst)
	var rst_mi := MeshInstance3D.new()
	var rst_m := CylinderMesh.new()
	rst_m.top_radius = 0.05
	rst_m.bottom_radius = 0.05
	rst_m.height = 0.04
	rst_mi.mesh = rst_m
	rst_mi.material_override = _mat_unshaded(Color(0.9, 0.1, 0.1))
	rst.add_child(rst_mi)
	_register_dash_ctl(rst, "restart")
	var lnt := Node3D.new()
	lnt.position = Vector3(-0.52, 0.90, -0.60)
	car_body.add_child(lnt)
	var ln_mi := MeshInstance3D.new()
	var ln_m := CylinderMesh.new()
	ln_m.top_radius = 0.045
	ln_m.bottom_radius = 0.045
	ln_m.height = 0.04
	ln_mi.mesh = ln_m
	ln_mi.material_override = _mat_unshaded(Color(0.15, 0.75, 0.3))
	ln_mi.name = "LeanBtnMesh"
	lnt.add_child(ln_mi)
	_register_dash_ctl(lnt, "lean")
	# Lean indicator needle on the dash (experiment feedback)
	# (rides up with the raised wheel so it stays clear of the rim)
	lean_needle = _box(car_body, Vector3(0.03, 0.13, 0.02), Vector3(0, 1.155, -0.615), _mat_unshaded(Color(0.2, 0.9, 1.0)))
	# Big state label above the dash
	state_label = Label3D.new()
	state_label.position = Vector3(0, 1.52, -0.85)
	state_label.font_size = 64
	state_label.pixel_size = 0.0022
	state_label.text = "DROP START"
	state_label.modulate = Color(1.0, 0.85, 0.2)
	state_label.outline_size = 8
	car_body.add_child(state_label)
	# Prep prompt label, under the state label
	prep_label = Label3D.new()
	prep_label.position = Vector3(0, 1.34, -0.85)
	prep_label.font_size = 40
	prep_label.pixel_size = 0.0016
	prep_label.text = ""
	prep_label.modulate = Color(0.6, 0.95, 1.0)
	prep_label.outline_size = 6
	car_body.add_child(prep_label)
	# Controls panel placard + separate DIAG board (Fix Pass 4 rework).
	# STANDING RULE: the panel lists EVERY command the game accepts.
	# Run 4 verdict on the Fix Pass 3 layout: "Panel isn't readable" -
	# the single 0.76x1.56 board at 0.9 m subtended ~80 deg vertically
	# (clipped at the view edge) and its lower DIAG lines sat behind
	# the car's right side pod from the anchored eye. Fix Pass 4 splits
	# the boards and moves them onto clear sightlines:
	# - Commands board (status + full command list, 20 lines, measured
	#   text 0.74 x 1.01 m at font 30) sits ahead-right at ~1.8 m, yawed
	#   toward the driver: every text corner projects inside the
	#   central view with margin, and the sightlines clear the dash,
	#   nose, wheel rim and switch knobs (proven geometrically in
	#   tests/render_proof.gd - the knobs dictated the height: the
	#   bottom text row's sightlines pass just over the right knob).
	# - DIAG board (5 lines, smaller type) sits low-left above the
	#   dash like an instrument cluster, clear of the wheel rim's left
	#   arc and the dash slab.
	panel_root = Node3D.new()
	panel_root.name = "PanelRoot"
	panel_root.position = Vector3(0.78, 1.53, -1.66)
	panel_root.rotation_degrees = Vector3(-2, -24, 0)
	car_body.add_child(panel_root)
	_box(panel_root, Vector3(0.80, 1.24, 0.02), Vector3(0, 0, 0), _mat(Color(0.05, 0.07, 0.12)), "PanelBoard")
	panel_label = Label3D.new()
	panel_label.position = Vector3(-0.368, 0.555, 0.02)
	panel_label.font_size = 30
	panel_label.pixel_size = 0.00115
	panel_label.width = 640.0
	panel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_label.modulate = Color(0.92, 0.95, 1.0)
	panel_label.outline_size = 5
	panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	panel_root.add_child(panel_label)
	diag_root = Node3D.new()
	diag_root.name = "DiagRoot"
	diag_root.position = Vector3(-0.53, 1.17, -0.85)
	diag_root.rotation_degrees = Vector3(-10, 28, 0)
	car_body.add_child(diag_root)
	_box(diag_root, Vector3(0.68, 0.34, 0.02), Vector3(0, 0, 0), _mat(Color(0.05, 0.07, 0.12)), "DiagBoard")
	diag_label = Label3D.new()
	diag_label.position = Vector3(-0.28, 0.125, 0.02)
	diag_label.font_size = 26
	diag_label.pixel_size = 0.00105
	diag_label.width = 600.0
	diag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diag_label.modulate = Color(0.92, 0.95, 1.0)
	diag_label.outline_size = 5
	diag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	diag_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	diag_root.add_child(diag_label)
	_update_panel()


func _register_dash_ctl(node: Node3D, kind: String) -> void:
	dash_ctl_nodes.append(node)
	dash_ctl_kinds.append(kind)


func _panel_text() -> String:
	var mode_txt: String = "XR LIVE" if xr_ok else "DESKTOP FALLBACK"
	var lines: Array[String] = []
	lines.append("STUNT CAR VR - TEST 1 [%s]" % mode_txt)
	lines.append("SPD %d  BOOST %d  DENT %d" % [int(round(speed * 3.6)), int(round(boost_meter)), dent_level])
	lines.append("STATE %s  TD %s" % [_state_name(), last_touchdown])
	lines.append("LEAN EXP %s  GRIP x%.2f" % ["ON" if lean_on else "OFF", grip_mult])
	lines.append("-- VR CONTROLS --")
	lines.append("Grab wheel: GRIP near wheel, turn hand")
	lines.append("Throttle R trigger / Brake L trigger")
	lines.append("Boost: R A button (while driving)")
	lines.append("Release: R trigger (when dangling)")
	lines.append("Flip switch: GRIP near a dash switch")
	lines.append("Call drone: L X button (while driving)")
	lines.append("Dash buttons (GRIP near):")
	lines.append("red = restart, green = lean on/off")
	lines.append("Recenter view: L stick click")
	lines.append("Restart race: L Y button")
	lines.append("-- DESKTOP --")
	lines.append("W/S throttle/brake, A/D steer, SHIFT boost")
	lines.append("SPACE release, 1/2/3 flip FUEL/SPARK/BOOST")
	lines.append("L call lift, T lean on/off, Q/E lean body")
	lines.append("R restart race, C recenter view")
	# Fix Pass 4: the DIAG block no longer appends here - it renders
	# on its own board (diag_label) via _update_panel.
	return "\n".join(lines)


func _update_panel() -> void:
	if panel_label != null:
		panel_label.text = _panel_text()
	if diag_label != null:
		diag_label.text = diag_block


# Fix Pass 3 (Item 1): the DIAG block. Refreshed at ~5 Hz from
# _physics_process into the cached diag_block string; since Fix
# Pass 4 it renders on its own board (diag_label, set in
# _update_panel) instead of under the command list. Everything
# live-only reports its RAW values here (anchor state + which apply
# path fired, HMD tracking, camera height in car space, per-hand
# grip channels and hub distance, wheel angle) so Chris's next
# screenshot is a bug report by itself.
func _build_diag_block() -> String:
	var lines: Array[String] = []
	lines.append("-- DIAG --")
	if xr_ok:
		var cam_car: Transform3D = car.global_transform.affine_inverse() * xr_cam.global_transform
		lines.append("ANCHOR %s TRK %s CAMH %.2f" % [
			anchor_state, "Y" if _hmd_has_tracking_data() else "N", cam_car.origin.y])
	else:
		lines.append("ANCHOR DESKTOP (cam on anchor) CAMH %.2f" % EYE_ANCHOR.y)
	lines.append(_diag_hand_line("L"))
	lines.append(_diag_hand_line("R"))
	lines.append("WHEEL %+d DEG" % int(round(rad_to_deg(wheel_angle))))
	return "\n".join(lines)


func _diag_hand_line(hand: String) -> String:
	var dist_m: float = _hand_pos(hand).distance_to(car.global_transform * _wheel_hub_local())
	var flags: String = ""
	if dist_m < WHEEL_GRAB_RADIUS:
		flags += " NEAR"
	if grab_hand == hand:
		flags += " HOLD"
	return "%s GRIP %.2f CLK %d FRC %.2f %dcm%s" % [
		hand, float(diag_grip[hand]), 1 if bool(diag_click[hand]) else 0,
		float(diag_force[hand]), int(round(dist_m * 100.0)), flags]


func _state_name() -> String:
	match mode:
		MODE_HANG:
			return "DANGLING(%s)" % hang_phase.to_upper()
		MODE_DRIVE:
			return "DRIVING"
		MODE_AIR:
			return "AIRBORNE"
		MODE_DONE:
			return "FINISHED"
	return "?"


# ---------------------------------------------------------------- drone

func _build_drone() -> void:
	drone = Node3D.new()
	drone.name = "Drone"
	add_child(drone)
	var body_mat := _mat(Color(0.18, 0.19, 0.22))
	_box(drone, Vector3(0.85, 0.22, 0.85), Vector3.ZERO, body_mat)
	_box(drone, Vector3(0.30, 0.16, 0.30), Vector3(0, -0.16, 0), _mat_unshaded(Color(1.0, 0.75, 0.15)))
	for ax: float in [-0.62, 0.62]:
		for az: float in [-0.62, 0.62]:
			_box(drone, Vector3(0.30, 0.06, 0.30), Vector3(ax * 0.8, 0.05, az * 0.8), body_mat)
			var rot := MeshInstance3D.new()
			var rm := CylinderMesh.new()
			rm.top_radius = 0.30
			rm.bottom_radius = 0.30
			rm.height = 0.02
			rot.mesh = rm
			rot.position = Vector3(ax, 0.10, az)
			rot.material_override = _mat(Color(0.75, 0.78, 0.82))
			drone.add_child(rot)
			drone_rotors.append(rot)
	# 4 lift lines (unit cylinders, stretched between drone and car corners)
	for i: int in 4:
		var lm := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.012
		cm.bottom_radius = 0.012
		cm.height = 1.0
		lm.mesh = cm
		lm.material_override = _mat_unshaded(Color(0.1, 0.1, 0.1))
		lm.visible = false
		add_child(lm)
		line_mis.append(lm)


func _set_line(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var mid: Vector3 = (a + b) * 0.5
	var dirv: Vector3 = b - a
	var lenv: float = dirv.length()
	if lenv < 0.01:
		mi.visible = false
		return
	mi.visible = true
	var basis := Basis(Quaternion(Vector3.UP, dirv / lenv))
	mi.global_transform = Transform3D(basis, mid)
	mi.scale = Vector3(1.0, lenv, 1.0)


func _drone_corners() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var xf: Transform3D = drone.global_transform
	for ax: float in [-0.62, 0.62]:
		for az: float in [-0.62, 0.62]:
			out.append(xf * Vector3(ax, -0.05, az))
	return out


func _car_corners() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var xf: Transform3D = car.global_transform
	for cx: float in [-0.60, 0.60]:
		for cz: float in [-1.35, 1.35]:
			out.append(xf * Vector3(cx, 1.05, cz))
	return out


# ---------------------------------------------------------------- input

func _input_float(ctrl: XRController3D, action: StringName) -> float:
	var v: Variant = ctrl.get_input(action)
	if v == null:
		return 0.0
	return float(v)


func _input_bool(ctrl: XRController3D, action: StringName) -> bool:
	var v: Variant = ctrl.get_input(action)
	if v == null:
		return false
	return bool(v)


func _btn_edge(key: String, now: bool) -> bool:
	var was: bool = bool(prev_btn.get(key, false))
	prev_btn[key] = now
	return now and not was


func _hand_pos(hand: String) -> Vector3:
	var c: XRController3D = hand_ctrl[hand]
	return c.global_position


func _poll_inputs(delta: float) -> void:
	in_throttle = 0.0
	in_brake = 0.0
	in_boost = false
	# --- desktop continuous ---
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		in_throttle = 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		in_brake = 1.0
	if Input.is_key_pressed(KEY_SHIFT):
		in_boost = true
	# desktop steering drives the wheel toward a target
	var steer_key: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer_key -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer_key += 1.0
	if grab_hand == "":
		if steer_key != 0.0:
			wheel_angle = clampf(wheel_angle + steer_key * 2.6 * delta, -PI, PI)
		else:
			wheel_angle = move_toward(wheel_angle, 0.0, 2.2 * delta)
	# --- XR continuous ---
	if xr_ok:
		var rc: XRController3D = hand_ctrl["R"]
		var lc: XRController3D = hand_ctrl["L"]
		in_throttle = maxf(in_throttle, _input_float(rc, &"trigger"))
		in_brake = maxf(in_brake, _input_float(lc, &"trigger"))
		if _input_bool(rc, &"ax_button"):
			in_boost = true
		_poll_grab("L", lc, delta)
		_poll_grab("R", rc, delta)
		# edges
		if _btn_edge("r_trig_click", _input_bool(rc, &"trigger_click")):
			if mode == MODE_HANG and hang_phase == "dangle":
				_do_release()
		if _btn_edge("l_ax", _input_bool(lc, &"ax_button")):
			if mode == MODE_DRIVE:
				_call_drone()
		if _btn_edge("r_by", _input_bool(rc, &"by_button")):
			_toggle_lean()
		if _btn_edge("l_by", _input_bool(lc, &"by_button")):
			start_race()
		if _btn_edge("l_stick_click", _input_bool(lc, &"primary_click")):
			_recenter()
	# test overrides win last
	if test_mode:
		in_throttle = test_throttle
		in_brake = test_brake
		in_boost = test_boost
		if test_release_queued:
			test_release_queued = false
			_do_release()


func _input(event: InputEvent) -> void:
	var k: InputEventKey = event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_SPACE:
			if mode == MODE_HANG and hang_phase == "dangle":
				_do_release()
		KEY_L:
			if mode == MODE_DRIVE:
				_call_drone()
		KEY_T:
			_toggle_lean()
		KEY_R:
			start_race()
		KEY_C:
			_recenter()
		KEY_1:
			_flip_switch(0)
		KEY_2:
			_flip_switch(1)
		KEY_3:
			_flip_switch(2)


func _recenter() -> void:
	# Fix Pass 2: recenter means "put my eye on the cockpit anchor", not
	# the raw XR reference reset (center_on_hmd left the tracked seated
	# height stacked on top of the cockpit offset - the driver floated).
	# Fix Pass 3: recenter re-arms the stability-gated application.
	if xr_ok:
		_arm_anchor()


func _arm_anchor() -> void:
	anchor_pending = true
	anchor_wait_frames = 0
	anchor_stable_frames = 0
	anchor_have_last = false
	anchor_reapply_watch = false
	anchor_state = "PENDING"


func _process_anchor_pending() -> void:
	if not xr_ok:
		anchor_pending = false
		return
	# Fix Pass 3 (Item 2): pose stability is tracked continuously - a
	# pose counts as stable only after the camera's local position has
	# moved < ANCHOR_STABLE_EPS across ANCHOR_STABLE_FRAMES consecutive
	# physics frames WITH tracking data present. The pre-pass code
	# applied on the first frame tracking data existed: on the
	# Virtual Desktop rig the first valid pose can be a transient
	# snapshot (headset not yet worn, stream not yet settled), and a
	# rigid correction baked from it misplaces the driver for the
	# whole session (run 3: framing never changed, wheel never
	# entered his frame - inference, labelled as such in the report).
	if _hmd_has_tracking_data():
		var cam_pos: Vector3 = xr_cam.transform.origin
		if anchor_have_last and cam_pos.distance_to(anchor_last_cam_pos) < ANCHOR_STABLE_EPS:
			anchor_stable_frames += 1
		else:
			anchor_stable_frames = 0
		anchor_last_cam_pos = cam_pos
		anchor_have_last = true
	else:
		anchor_stable_frames = 0
		anchor_have_last = false
	if anchor_pending:
		anchor_wait_frames += 1
		if anchor_stable_frames >= ANCHOR_STABLE_FRAMES:
			_apply_seat_anchor()
			anchor_state = "APPLIED-STABLE"
			anchor_pending = false
		elif anchor_wait_frames > ANCHOR_FALLBACK_FRAMES:
			# ~10 s with no stable pose: apply from whatever pose
			# exists (graceful degradation, as before) - but keep
			# watching: when a stable tracked pose later appears,
			# re-apply ONCE from the real pose.
			_apply_seat_anchor()
			anchor_state = "APPLIED-FALLBACK"
			anchor_pending = false
			anchor_reapply_watch = true
	elif anchor_reapply_watch and anchor_stable_frames >= ANCHOR_STABLE_FRAMES:
		_apply_seat_anchor()
		anchor_state = "APPLIED-STABLE"
		anchor_reapply_watch = false


func _hmd_has_tracking_data() -> bool:
	# XRCamera3D has NO tracking query in Godot 4.7: get_is_tracking does
	# not exist anywhere, and get_has_tracking_data is XRNode3D-only -
	# XRCamera3D is not an XRNode3D (Hotfix 1: the old call error-spammed
	# every physics frame in XR mode and wedged the run). Ask the head
	# tracker's pose directly instead; tests/api_guard in the smoke test
	# asserts every XR API name used here against ClassDB.
	var head_tracker: XRTracker = XRServer.get_tracker(&"head")
	if head_tracker == null:
		return false
	var pose_tracker: XRPositionalTracker = head_tracker as XRPositionalTracker
	if pose_tracker == null:
		return false
	var head_pose: XRPose = pose_tracker.get_pose(&"default")
	return head_pose != null and head_pose.has_tracking_data


func _apply_seat_anchor() -> void:
	# Offset the seat so the HMD lands exactly on EYE_ANCHOR in car space,
	# yaw-aligned to the car's heading. The correction is rigid and sits
	# ABOVE the XR origin, so head motion (and the lean reading, which is
	# measured local to the origin) afterwards is relative to the anchor.
	var cam_car: Transform3D = car.global_transform.affine_inverse() * xr_cam.global_transform
	var fwd: Vector3 = -cam_car.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.05:
		fwd = Vector3(0.0, 0.0, -1.0)
	fwd = fwd.normalized()
	# Yaw that rotates the current horizontal view direction onto the
	# car's forward (-Z in car space).
	var yaw: float = atan2(fwd.z, fwd.x) + PI * 0.5
	var rot := Basis(Vector3.UP, yaw)
	var corr := Transform3D(rot, EYE_ANCHOR - rot * cam_car.origin)
	seat_offset.transform = corr * seat_offset.transform
	_capture_lean_neutral()


func _toggle_lean() -> void:
	lean_on = not lean_on
	if lean_on:
		_capture_lean_neutral()


func _capture_lean_neutral() -> void:
	if xr_cam != null:
		lean_neutral_x = xr_cam.transform.origin.x


# --- grab wheel ---
func _wheel_hub_local() -> Vector3:
	# single source: wheel_node.position in _build_cockpit is WHEEL_HUB too
	return WHEEL_HUB


func _wheel_plane_v() -> Vector3:
	# The rim lives in the tilt node's local XZ plane; this is the
	# tilt-local +Z axis expressed in car space (tilt = WHEEL_TILT_DEG
	# about X). Paired with car-space +X it spans the wheel plane.
	var t: float = deg_to_rad(WHEEL_TILT_DEG)
	return Vector3(0.0, -sin(t), cos(t))


func _hand_wheel_angle(hand: String) -> float:
	# Fix Pass 3 (Item 4): the hand's angle is measured IN THE WHEEL
	# PLANE (the old code used atan2(y, x) in car space, an
	# approximation for the flat wheel). With the rim stood up, the
	# angle is taken about the wheel axis: atan2 over the plane
	# basis (car +X, tilt-local +Z). Turning the hand clockwise as
	# the driver sees it (top of the rim -> driver's right) increases
	# this angle, and _poll_grab ADDS the delta to wheel_angle while
	# the visual spin is wheel_spin.rotation.y = -wheel_angle: the
	# pair keeps the rim point under the hand glued to the hand,
	# 1:1 at the rim, and clockwise steers right like a real car.
	var local: Vector3 = car.to_local(_hand_pos(hand)) - _wheel_hub_local()
	return atan2(local.dot(_wheel_plane_v()), local.x)


func _poll_grab(hand: String, ctrl: XRController3D, _delta: float) -> void:
	# Fix Pass 3 (Item 3): grip is active if ANY channel the runtime
	# actually delivers says so - analog "grip" > 0.65 OR "grip_click"
	# OR "grip_force" > 0.65 (all read through XRController3D
	# .get_input, the API-guarded call). The raw values are stashed
	# for the panel DIAG block so the next live run shows which
	# channel Virtual Desktop really feeds.
	var grip_v: float = _input_float(ctrl, &"grip")
	var grip_click: bool = _input_bool(ctrl, &"grip_click")
	var grip_force: float = _input_float(ctrl, &"grip_force")
	diag_grip[hand] = grip_v
	diag_click[hand] = grip_click
	diag_force[hand] = grip_force
	var now: bool = grip_v > 0.65 or grip_click or grip_force > 0.65
	var near_wheel: bool = _hand_pos(hand).distance_to(car.global_transform * _wheel_hub_local()) < WHEEL_GRAB_RADIUS
	var was: bool = gripping[hand]
	# switch / dash-control flipping on a fresh grip near a dash control
	if now and not was:
		var ctl: int = _dash_ctl_near(_hand_pos(hand))
		if ctl >= 0:
			_activate_dash_ctl(dash_ctl_kinds[ctl])
	gripping[hand] = now
	if mode != MODE_DRIVE and mode != MODE_AIR:
		if grab_hand == hand:
			grab_hand = ""
		return
	if now and near_wheel:
		if grab_hand == "":
			grab_hand = hand
			grab_prev_ang = _hand_wheel_angle(hand)
		elif grab_hand == hand:
			var ang: float = _hand_wheel_angle(hand)
			var d: float = wrapf(ang - grab_prev_ang, -PI, PI)
			wheel_angle = clampf(wheel_angle + d, -PI, PI)
			grab_prev_ang = ang
	elif grab_hand == hand and not now:
		grab_hand = ""
		# other hand takes over if it is still gripping the wheel
		var other: String = "R" if hand == "L" else "L"
		if bool(gripping[other]) and _hand_pos(other).distance_to(car.global_transform * _wheel_hub_local()) < WHEEL_GRAB_RADIUS:
			grab_hand = other
			grab_prev_ang = _hand_wheel_angle(other)
	if grab_hand == "" and mode == MODE_DRIVE:
		wheel_angle = move_toward(wheel_angle, 0.0, 1.6 * _delta)


# Fix Pass 5 (Item 2): lever-shaped controls (the prep switches) are
# measured to their GRAB SEGMENT - base of the shaft to the cap - not
# to a point at the tip. Chris's hand arrives at the shaft; the old
# point measure (at the pivot origin the coloured cap sits ~0.19 m
# along the lever from) left the tip as the only reliably live spot.
# Buttons keep the point measure.
func _dash_ctl_segment(i: int) -> Array[Vector3]:
	var node: Node3D = dash_ctl_nodes[i]
	if dash_ctl_kinds[i].begins_with("switch"):
		var xf: Transform3D = node.global_transform
		return [xf * Vector3(0.0, -0.02, 0.0), xf * Vector3(0.0, 0.19, 0.0)]
	var p: Vector3 = node.global_position
	return [p, p]


func _seg_point_dist(a: Vector3, b: Vector3, p: Vector3) -> float:
	var ab: Vector3 = b - a
	var len2: float = ab.length_squared()
	if len2 < 1e-9:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len2, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _dash_ctl_near(world_pos: Vector3) -> int:
	for i: int in dash_ctl_nodes.size():
		var seg: Array[Vector3] = _dash_ctl_segment(i)
		if _seg_point_dist(seg[0], seg[1], world_pos) < DASH_CTL_RADIUS:
			return i
	return -1


func _activate_dash_ctl(kind: String) -> void:
	if kind.begins_with("switch"):
		_flip_switch(int(kind.substr(6)))
	elif kind == "restart":
		start_race()
	elif kind == "lean":
		_toggle_lean()


# ---------------------------------------------------------------- actions

func start_race() -> void:
	mode = MODE_HANG
	hang_phase = "dangle"
	is_drop_start = true
	car_s = 0.0
	car_lat = 0.0
	lat_vel = 0.0
	speed = 0.0
	wheel_angle = 0.0
	boost_meter = 60.0
	dent_level = 0
	smoke_on = false
	last_touchdown = "-"
	was_airborne = false
	race_time = 0.0
	finished_time = 0.0
	race_started = true # Fix Pass 6: audio may start from here on
	body_sink = 0.0
	body_sink_v = 0.0
	slip_state = 0.0
	_reset_suspension()
	_reset_dangle_feel()
	drop_target_s = 2.0
	_arm_anchor()
	var fr: Dictionary = _frame_at(drop_target_s)
	# Fix Pass 2: hang anchor offset along WORLD up, so at swing centre
	# the car hangs plumb over the ribbon centreline regardless of the
	# section's slope/bank (the frame-up offset drifted sideways).
	anchor_pos = fr["pos"] + Vector3.UP * (HANG_LEN + HANG_CLEAR)
	anchor_target = anchor_pos
	pivot_pos = anchor_pos
	# Fix Pass 5: bigger, out-of-phase starting swing (see PEND_LEN_*).
	pend_th_f = 0.34
	pend_th_l = 0.26
	pend_om_f = 0.0
	pend_om_l = 0.0
	_prep_new_sequence()
	_capture_lean_neutral()
	_refresh_car_visuals()


func _reset_suspension() -> void:
	c_f = SUSP_REST
	c_r = SUSP_REST
	cv_f = 0.0
	cv_r = 0.0
	geom_f = 0.0
	geom_r = 0.0
	load_f = 1.0
	load_r = 1.0
	pitch_extra = 0.0
	heave_off = 0.0
	long_accel_f = 0.0
	prev_speed = 0.0
	bounce_pending = false
	bounce_vy = 0.0
	susp_peak_c = SUSP_REST


func _reset_dangle_feel() -> void:
	dip_y = 0.0
	dip_vy = 0.0
	dip_accel = 0.0
	dip_timer = 2.0
	slack_t = 0.0
	catch_t = 1.0
	orient_have = false


func _prep_new_sequence() -> void:
	prep_order = [0, 1, 2]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i: int in range(2, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = prep_order[i]
		prep_order[i] = prep_order[j]
		prep_order[j] = tmp
	prep_index = 0
	prep_done = false
	switch_on = [false, false, false]
	_refresh_switch_visuals()
	_update_prep_label()


func _flip_switch(idx: int) -> void:
	if mode != MODE_HANG:
		return
	if prep_done:
		switch_on[idx] = not switch_on[idx]
		_refresh_switch_visuals()
		return
	if idx == prep_order[prep_index]:
		switch_on[idx] = true
		prep_index += 1
		if prep_index >= prep_order.size():
			prep_done = true
			boost_meter = minf(boost_meter + PREP_BOOST_CREDIT, 100.0)
	else:
		# wrong switch: sequence resets, flipped switches go back off
		prep_index = 0
		switch_on = [false, false, false]
	_prep_update_labels()
	_refresh_switch_visuals()


func _refresh_switch_visuals() -> void:
	for i: int in switch_pivots.size():
		switch_pivots[i].rotation_degrees.x = 22.0 if switch_on[i] else -38.0


func _update_prep_label() -> void:
	if prep_label == null:
		return
	if mode != MODE_HANG:
		prep_label.text = ""
		return
	if prep_done:
		prep_label.text = "PREP COMPLETE +%d BOOST" % int(PREP_BOOST_CREDIT)
		return
	var parts: Array[String] = []
	for i: int in prep_order.size():
		var nm: String = SWITCH_NAMES[prep_order[i]]
		if i < prep_index:
			parts.append("[%s]" % nm)
		else:
			parts.append(nm)
	prep_label.text = "PREP: " + " -> ".join(parts)


func _prep_update_labels() -> void:
	_update_prep_label()
	_update_panel()


func _call_drone() -> void:
	if mode != MODE_DRIVE:
		return
	_begin_recovery(car.global_position, car_s)


func _begin_recovery(catch_pos: Vector3, from_s: float) -> void:
	mode = MODE_HANG
	is_drop_start = false
	speed = 0.0
	hang_phase = "attach"
	anchor_t = 0.0
	hang_from_pos = catch_pos
	drop_target_s = _find_drop_s(from_s)
	var fr: Dictionary = _frame_at(drop_target_s)
	# Fix Pass 2: world-up hang anchor (see start_race) - the car must
	# hang centred over the ribbon, not offset along a tilted frame up.
	anchor_target = fr["pos"] + Vector3.UP * (HANG_LEN + HANG_CLEAR)
	anchor_pos = catch_pos + Vector3.UP * (HANG_LEN + 1.6)
	pivot_pos = anchor_pos
	_reset_dangle_feel()
	# initial pendulum angles from the catch offset
	var off: Vector3 = catch_pos - anchor_pos
	pend_th_f = clampf(off.dot(fr["tan"]) / HANG_LEN, -0.6, 0.6)
	pend_th_l = clampf(off.dot(fr["side"]) / HANG_LEN, -0.6, 0.6)
	pend_om_f = 0.0
	pend_om_l = 0.0
	_prep_new_sequence()


func _find_drop_s(from_s: float) -> float:
	# Nearest suitable hang section ahead: no gap, near-straight, flat,
	# and UNBANKED. Fix Pass 2: the old search accepted slopes up to
	# tan.y 0.12 and ignored bank entirely - the corner's bank decays
	# over ~50 samples past the corner, so drops were offered over
	# still-banked ribbon where the hang point drifted a full half-width
	# sideways ("barely over the track"). The car hangs plumb (world up)
	# from the anchor, so a level, unbanked section keeps the swing
	# centre squarely over the centreline.
	var limit: float = track_len - 4.0
	var cand: float = from_s + 4.0
	while cand < limit:
		var fr: Dictionary = _frame_at(cand)
		if not bool(fr["gap"]) and absf(float(fr["curv"])) < 0.004 \
				and absf(float(fr["tan"].y)) < 0.08 and absf(float(fr["bank"])) < 0.03:
			return cand
		cand += 3.0
	# Relaxed fallback (pre-fix criteria) if nothing strict qualifies.
	cand = from_s + 4.0
	while cand < limit:
		var fr2: Dictionary = _frame_at(cand)
		if not bool(fr2["gap"]) and absf(float(fr2["curv"])) < 0.004 \
				and absf(float(fr2["tan"].y)) < 0.12:
			return cand
		cand += 3.0
	return clampf(from_s + 8.0, 0.0, limit)


func _do_release() -> void:
	if mode != MODE_HANG or hang_phase != "dangle":
		return
	var fr: Dictionary = _frame_at(drop_target_s)
	var f: Vector3 = fr["tan"]
	var r: Vector3 = fr["side"]
	# pendulum tip velocity + a little forward push: you drop swinging
	var tip: Vector3 = (f * (pend_om_f * cos(pend_th_f)) + r * (pend_om_l * cos(pend_th_l))) * HANG_LEN
	# Fix Pass 5: the swing state at release IS the drop - both axes'
	# tip velocity carries in (timing the release stays the skill),
	# and a release mid-slack keeps the car's free-fall velocity.
	air_vel = tip + f * 3.0
	if slack_t > 0.0:
		air_vel = hang_vel + f * 3.0
	air_vel.y += dip_vy * 0.5
	air_s_est = drop_target_s
	air_time = 0.0
	air_from_gap = false
	mode = MODE_AIR
	prep_label.text = ""


# ---------------------------------------------------------------- sim

func _physics_process(delta: float) -> void:
	_process_anchor_pending()
	# Fix Pass 3: refresh the panel DIAG block at ~5 Hz.
	diag_timer += delta
	if diag_timer >= 0.2:
		diag_timer = 0.0
		diag_block = _build_diag_block()
	_poll_inputs(delta)
	race_time += delta
	match mode:
		MODE_HANG:
			_update_hang(delta)
		MODE_DRIVE:
			_update_drive(delta)
		MODE_AIR:
			_update_air(delta)
		MODE_DONE:
			speed = move_toward(speed, 0.0, 8.0 * delta)
	if mode != MODE_DRIVE:
		slip_state = 0.0 # tires unloaded: no slip, no skid
	_update_lean_reading()
	_update_suspension(delta)
	_update_body_spring(delta)
	_refresh_car_visuals()
	_update_audio(delta)
	_update_drone_visual(delta)


func _process(_delta: float) -> void:
	# rotor spin (visual only)
	for r: MeshInstance3D in drone_rotors:
		r.rotation.y += 28.0 * _delta
	# Fix Pass 6 audio stall watchdog: if the physics loop has
	# gone quiet (main loop stalled / app wedged), cut the gains
	# so a looping buffer can never drone on unattended. Physics
	# ticks clear the flag in _update_audio; a latched state is
	# handled there too (players stopped, nothing to cut).
	if race_started and not audio_latched and engine_player != null:
		if Time.get_ticks_msec() - audio_last_physics_ms > AUDIO_STALL_MS:
			audio_stalled = true
			engine_player.volume_db = -60.0
			skid_player.volume_db = -60.0


func _update_drive(delta: float) -> void:
	# Fix Pass 5: the suspension asked to leave the road (rebound
	# droop or a full crest unload, decided in _update_suspension).
	# The car's velocity at separation is the road velocity plus the
	# rebound's upward throw; from here it is plain ballistics and
	# the existing touchdown grading decides the landing.
	if bounce_pending:
		bounce_pending = false
		var fr_b: Dictionary = _frame_at(car_s)
		air_vel = fr_b["tan"] * speed + fr_b["up"] * bounce_vy
		air_s_est = car_s
		air_time = 0.0
		air_from_gap = false
		was_airborne = true
		mode = MODE_AIR
		return
	var fr: Dictionary = _frame_at(car_s)
	var tanv: Vector3 = fr["tan"]
	# longitudinal
	var accel: float = in_throttle * 10.0
	accel -= in_brake * 14.0
	accel -= speed * 0.10
	accel += -GRAV * tanv.y * 0.85 # slope gravity: climbs bite, descents push
	if in_boost and boost_meter > 0.0 and in_throttle > 0.05:
		accel += 9.0
		boost_meter = maxf(boost_meter - 30.0 * delta, 0.0)
	speed = clampf(speed + accel * delta, -6.0, 34.0)
	if in_brake > 0.05 and speed < 0.5 and speed > -0.5:
		speed = 0.0
	car_s += speed * delta
	# lateral: steering sets a target lateral velocity; corner drift pushes
	# the car OUT of the turn, scaled down by grip (lean experiment).
	var steer: float = clampf(wheel_angle / PI, -1.0, 1.0)
	var curv: float = float(fr["curv"])
	grip_mult = _grip_for(curv)
	var drift: float = curv * speed * speed * 0.22 / grip_mult
	# Fix Pass 6: the tire slip state - how hard the tires are
	# working laterally AFTER the grip modification (lean included):
	# the sideways load the road imposes on the car. This is the
	# skid audio's source and the model's honest "losing traction".
	slip_state = clampf((absf(drift) - AUDIO_SLIP_ONSET) / AUDIO_SLIP_SPAN, 0.0, 1.0)
	var target_lat_vel: float = steer * maxf(speed, 0.0) * 0.34 + drift
	lat_vel = move_toward(lat_vel, target_lat_vel, 14.0 * delta)
	car_lat += lat_vel * delta
	# entering the gap -> ballistic
	if bool(fr["gap"]) and speed > 0.0:
		air_vel = tanv * speed
		air_s_est = car_s
		air_time = 0.0
		air_from_gap = true
		was_airborne = true
		mode = MODE_AIR
		return
	# off the side -> ballistic fall
	if absf(car_lat) > HALF_WIDTH:
		air_vel = tanv * speed + fr["side"] * lat_vel
		air_s_est = car_s
		air_time = 0.0
		air_from_gap = false
		mode = MODE_AIR
		return
	if car_s >= track_len - 0.5:
		mode = MODE_DONE
		finished_time = race_time
		state_label.text = "FINISH!"
	# place the car
	_place_car_on_track(fr)


func _grip_for(curv: float) -> float:
	if not lean_on:
		return 1.0
	# lean into the turn (lean sign matches turn direction) = more grip.
	# Turn left (curv>0) needs lean left (negative head offset) -> product
	# test below uses -lean_value*curv so that matching signs give >1.
	var lv: float = lean_value
	if test_lean > -50.0:
		lv = test_lean
	if absf(curv) < 0.0005:
		return 1.0 + 0.05 * absf(lv)
	var match_amt: float = clampf(-lv * signf(curv), -1.0, 1.0)
	return clampf(1.0 + 0.28 * match_amt, 0.75, 1.30)


func _place_car_on_track(fr: Dictionary) -> void:
	# Fix Pass 5: the body rides on its springs - heave_off is the
	# spring attach height (0 at rest, negative compressed, positive
	# at droop), so the whole car settles/rises with the suspension.
	var pos: Vector3 = fr["pos"] + fr["side"] * car_lat + fr["up"] * (CLEARANCE + heave_off)
	var basis := Basis(fr["side"], fr["up"], -fr["tan"])
	car.global_transform = Transform3D(basis, pos)


func _update_air(delta: float) -> void:
	air_time += delta
	air_vel.y -= GRAV * delta
	var pos: Vector3 = car.global_position + air_vel * delta
	car.global_position = pos
	# track s estimate from forward motion
	var fr_est: Dictionary = _frame_at(air_s_est)
	air_s_est += air_vel.dot(fr_est["tan"]) * delta
	air_s_est = clampf(air_s_est, 0.0, track_len)
	var fr: Dictionary = _frame_at(air_s_est)
	var rel: Vector3 = pos - fr["pos"]
	var lat: float = rel.dot(fr["side"])
	var h: float = rel.dot(fr["up"])
	if not bool(fr["gap"]) and h <= CLEARANCE + 0.05 and h > -2.2 and absf(lat) <= HALF_WIDTH and air_vel.y < 2.5:
		_land(fr, lat, h)
		return
	# missed it: the drone catches you
	if air_time > 2.4 or h < -13.0:
		_begin_recovery(pos, air_s_est)


func _land(fr: Dictionary, lat: float, h: float) -> void:
	# coming in below the ribbon edge costs extra impact (edge-catch rule)
	var vy: float = absf(minf(air_vel.y, 0.0)) + maxf(0.0, CLEARANCE - h) * 1.5
	var up_now: Vector3 = car.global_transform.basis.y.normalized()
	var misalign: float = rad_to_deg(up_now.angle_to(fr["up"]))
	var quality: String = "FLAT"
	if vy > 9.0 or misalign > 30.0:
		quality = "HARD"
	elif vy > 6.2 or misalign > 18.0:
		quality = "ROUGH"
	elif vy > 4.2 or misalign > 9.0:
		quality = "OK"
	last_touchdown = "%s (vy %.1f, tilt %.0f)" % [quality, vy, misalign]
	if quality == "HARD":
		dent_level += 1
		smoke_on = true
	# Fix Pass 5: the impact goes INTO the springs. Compression is set
	# from impact speed (front biased - the nose arrives first, so it
	# dives first), with compressing velocity so the spring dynamics
	# continue honestly from the hit: deep smooth compression on a
	# clean landing, clamped at full travel (bottoming out) on a hard
	# one, then an underdamped rebound - which is where bounce-air
	# comes from. The view dive reads this same state.
	c_f = clampf(SUSP_REST + vy * 0.045 * 1.15, 0.0, SUSP_TRAVEL)
	c_r = clampf(SUSP_REST + vy * 0.045 * 0.90, 0.0, SUSP_TRAVEL)
	cv_f = vy * 0.35
	cv_r = vy * 0.35
	# Fix Pass 6: the same impact arrives in the DRIVER a beat
	# later - an impulse into the body spring, scaled by impact.
	_body_impulse(vy)
	car_s = air_s_est
	car_lat = lat
	lat_vel = 0.0
	speed = clampf(air_vel.dot(fr["tan"]), 4.0, 34.0)
	mode = MODE_DRIVE
	was_airborne = false
	_place_car_on_track(fr)


func _update_hang(delta: float) -> void:
	_update_dip(delta)
	match hang_phase:
		"attach":
			anchor_t += delta / 1.0
			_step_pendulum(delta)
			var target_car: Vector3 = _hang_car_pos(_frame_at(drop_target_s))
			var t: float = clampf(anchor_t, 0.0, 1.0)
			var e: float = t * t * (3.0 - 2.0 * t)
			car.global_position = hang_from_pos.lerp(target_car, e)
			_orient_car_hang(delta, true)
			if anchor_t >= 1.0:
				hang_phase = "carry"
				anchor_from = anchor_pos
				anchor_t = 0.0
			return
		"carry":
			var dist: float = anchor_pos.distance_to(anchor_target)
			var step: float = 9.0 * delta
			if dist <= step:
				anchor_pos = anchor_target
				hang_phase = "dangle"
			else:
				anchor_pos = anchor_pos.move_toward(anchor_target, step)
		"dangle":
			pass
	_step_pendulum(delta)
	var fr: Dictionary = _frame_at(drop_target_s)
	if hang_phase == "dangle" and slack_t > 0.0:
		# Lines slack: the car is in free fall for a beat, pendulum
		# frozen. When the lines catch, the pendulum state is
		# re-derived from where the car actually is (below).
		slack_t -= delta
		hang_vel.y -= GRAV * delta
		hang_pos += hang_vel * delta
		car.global_position = hang_pos
		if slack_t <= 0.0:
			_catch_lines(fr)
	elif hang_phase == "dangle" and catch_t < 1.0:
		# Just caught: blend from the fallen position back onto the
		# pendulum sphere so the catch reads as a settle, not a snap.
		catch_t = minf(catch_t + delta / 0.18, 1.0)
		var e2: float = catch_t * catch_t * (3.0 - 2.0 * catch_t)
		car.global_position = catch_from.lerp(_hang_car_pos(fr), e2)
	else:
		car.global_position = _hang_car_pos(fr)
	_orient_car_hang(delta, hang_phase == "attach")


func _update_dip(delta: float) -> void:
	# Drone dips (dangle only): irregular brief drops of the pivot with
	# a spring correction - the drone is visibly working to hold the
	# load. Deterministic hash scheduling (same dangle, same dips -
	# the smoke depends on reproducible behaviour). A hard dip drops
	# the pivot out from under the car faster than the car can
	# follow: the lines go slack (see the dangle branch above).
	if hang_phase == "dangle":
		dip_timer -= delta
		if dip_timer <= 0.0:
			dip_seed += 1
			var h1: float = sin(float(dip_seed) * 12.9898) * 43758.5453
			var frac1: float = h1 - floor(h1)
			var h2: float = sin(float(dip_seed) * 78.233) * 12543.21
			var frac2: float = h2 - floor(h2)
			dip_vy = -(0.9 + 1.1 * frac1)
			dip_timer = 2.4 + 2.2 * frac2
			if dip_vy <= DIP_SLACK_IMPULSE and slack_t <= 0.0 and catch_t >= 1.0:
				slack_t = 0.15
				hang_pos = car.global_position
				var fr_s: Dictionary = _frame_at(drop_target_s)
				hang_vel = (fr_s["tan"] * (pend_om_f * cos(pend_th_f))
					+ fr_s["side"] * (pend_om_l * cos(pend_th_l))) * HANG_LEN
				hang_vel.y += dip_vy
	dip_accel = -DIP_K * dip_y - DIP_DAMP * dip_vy
	dip_vy += dip_accel * delta
	dip_y += dip_vy * delta
	pivot_pos = anchor_pos + Vector3(0.0, dip_y, 0.0)


func _catch_lines(fr: Dictionary) -> void:
	# Re-derive the pendulum from the car's real offset/velocity so
	# the swing continues from the fall, not from stale angles.
	var dirv: Vector3 = (car.global_position - pivot_pos).normalized()
	pend_th_f = asin(clampf(dirv.dot(fr["tan"]), -1.0, 1.0))
	pend_th_l = asin(clampf(dirv.dot(fr["side"]), -1.0, 1.0))
	pend_om_f = clampf(hang_vel.dot(fr["tan"]) / (HANG_LEN * maxf(cos(pend_th_f), 0.3)), -2.0, 2.0)
	pend_om_l = clampf(hang_vel.dot(fr["side"]) / (HANG_LEN * maxf(cos(pend_th_l), 0.3)), -2.0, 2.0)
	catch_from = car.global_position
	catch_t = 0.0
	# Fix Pass 6: the catch thumps the DRIVER into the seat - a
	# body-spring impulse as the lines take the car's weight.
	body_sink_v += BODY_CATCH_IMPULSE


func _step_pendulum(delta: float) -> void:
	# Fix Pass 5: two axes on DIFFERENT pendulum lengths (PEND_LEN_F /
	# PEND_LEN_L), so the resultant path is a diagonal Lissajous that
	# never settles into a clean single-plane rhythm, with light
	# damping so the swing persists. The pivot's own acceleration
	# modulates effective gravity (drone dip = the swing goes soft;
	# the correction = it firms up) - the compliance lives here and
	# in the slack/catch path, not in a cosmetic wobble.
	if slack_t > 0.0:
		return
	var g_eff: float = clampf(GRAV + dip_accel, 2.0, 22.0)
	pend_om_f += (-(g_eff / PEND_LEN_F) * sin(pend_th_f) - PEND_DAMP * pend_om_f) * delta
	pend_om_l += (-(g_eff / PEND_LEN_L) * sin(pend_th_l) - PEND_DAMP * pend_om_l) * delta
	pend_th_f += pend_om_f * delta
	pend_th_l += pend_om_l * delta


func _hang_car_pos(fr: Dictionary) -> Vector3:
	var dirv: Vector3 = (fr["tan"] * sin(pend_th_f) + fr["side"] * sin(pend_th_l)
		- Vector3.UP * (cos(pend_th_f) * cos(pend_th_l))).normalized()
	return pivot_pos + dirv * HANG_LEN


func _orient_car_hang(delta: float, snap: bool) -> void:
	var fr: Dictionary = _frame_at(drop_target_s)
	var down_dir: Vector3 = (car.global_position - pivot_pos).normalized()
	# Fix Pass 5 compliance: the car's attitude follows a LAGGED hang
	# direction - it settles a beat behind the swing instead of being
	# rigidly framed to the pivot (Chris: "chains feel too taut").
	if snap or not orient_have:
		orient_dir = down_dir
		orient_have = true
	else:
		orient_dir = orient_dir.lerp(down_dir, clampf(7.0 * delta, 0.0, 1.0)).normalized()
	down_dir = orient_dir
	var y_axis: Vector3 = -down_dir
	var facing: Vector3 = fr["tan"]
	var z_raw: Vector3 = -facing - y_axis * ((-facing).dot(y_axis))
	var z_axis: Vector3 = z_raw.normalized()
	if z_raw.length() < 0.1:
		z_axis = -facing
	var x_axis: Vector3 = y_axis.cross(z_axis).normalized()
	car.global_transform.basis = Basis(x_axis, y_axis, z_axis).orthonormalized()


func _update_lean_reading() -> void:
	if xr_cam != null and xr_ok:
		lean_value = clampf((xr_cam.transform.origin.x - lean_neutral_x) / 0.16, -1.0, 1.0)
	elif Input.is_key_pressed(KEY_Q):
		lean_value = move_toward(lean_value, -1.0, 0.05)
	elif Input.is_key_pressed(KEY_E):
		lean_value = move_toward(lean_value, 1.0, 0.05)
	else:
		lean_value = move_toward(lean_value, 0.0, 0.05)
	if lean_needle != null:
		lean_needle.position.x = lean_value * 0.16


func _lean_effective() -> float:
	# The lean the game acts on: test override wins (same pattern as
	# _grip_for), else the live head/body reading.
	if test_lean > -50.0:
		return test_lean
	return lean_value


func _susp_integrate(target_f: float, target_r: float, delta: float) -> void:
	cv_f += ((target_f - c_f) * SUSP_K - SUSP_DAMP * cv_f) * delta
	cv_r += ((target_r - c_r) * SUSP_K - SUSP_DAMP * cv_r) * delta
	c_f = clampf(c_f + cv_f * delta, 0.0, SUSP_TRAVEL)
	c_r = clampf(c_r + cv_r * delta, 0.0, SUSP_TRAVEL)
	# Body pose derives from the spring ATTACH heights (road rise
	# minus compression at each axle): steady state on a steady slope
	# is level with the frame (springs absorb the shape); transients -
	# slope breaks, landings, transfer - pitch and settle the body.
	var attach_f: float = geom_f - c_f
	var attach_r: float = geom_r - c_r
	pitch_extra = atan2(attach_f - attach_r, WHEELBASE)
	heave_off = (attach_f + attach_r) * 0.5 + SUSP_REST


func _update_suspension(delta: float) -> void:
	# Fix Pass 5: per-axle spring model (see the constants block).
	if mode == MODE_DRIVE:
		var fr: Dictionary = _frame_at(car_s)
		var fr_f: Dictionary = _frame_at(car_s + AXLE_F)
		var fr_r: Dictionary = _frame_at(car_s - AXLE_R)
		geom_f = (fr_f["pos"] - fr["pos"]).dot(fr["up"])
		geom_r = (fr_r["pos"] - fr["pos"]).dot(fr["up"])
		# Crest load: following the road over a crest needs downward
		# acceleration v^2 * kv; what gravity cannot supply unloads
		# the springs. Computed per axle from the road's own profile.
		var cos_phi: float = maxf(sqrt(maxf(1.0 - fr["tan"].y * fr["tan"].y, 0.0)), 0.5)
		load_f = clampf(1.0 - speed * speed * float(fr_f["kv"]) / (GRAV * cos_phi), 0.0, 1.25)
		load_r = clampf(1.0 - speed * speed * float(fr_r["kv"]) / (GRAV * cos_phi), 0.0, 1.25)
		# Weight transfer from filtered longitudinal acceleration:
		# accelerating loads the rear (squat), braking loads the
		# front (dive).
		if delta > 0.0:
			var la: float = clampf((speed - prev_speed) / delta, -12.0, 12.0)
			long_accel_f = lerpf(long_accel_f, la, 0.25)
		prev_speed = speed
		var transfer: float = long_accel_f * SUSP_TRANSFER_K
		var target_f: float = clampf((SUSP_REST + geom_f) * load_f - transfer, 0.0, SUSP_TRAVEL)
		var target_r: float = clampf((SUSP_REST + geom_r) * load_r + transfer, 0.0, SUSP_TRAVEL)
		_susp_integrate(target_f, target_r, delta)
		susp_peak_c = maxf((c_f + c_r) * 0.5, susp_peak_c - 0.10 * delta)
		# Rebound air, two honest routes in:
		# (1) REBOUND: a real hit recently drove the springs deep
		# (peak gate) and they have now thrown back to full droop
		# still extending fast - stored spring energy leaves the
		# road. The peak gate is what separates this from a crest
		# the springs merely bleed down over: at the climb-top
		# crest (load ~0.27 sustained) compressions sag to ~0 too,
		# but from ~rest, with no stored energy - the wheels stay
		# planted, as they should at 27% weight.
		# (2) CREST: the unload factor is ~zero at both axles - the
		# road is falling away faster than gravity can follow.
		if susp_peak_c > 0.19 and (c_f + c_r) * 0.5 <= 0.010 and cv_f + cv_r < -0.6:
			bounce_pending = true
			bounce_vy = clampf(-(cv_f + cv_r) * 0.55, 0.5, 2.6)
		elif load_f <= 0.03 and load_r <= 0.03 and speed > 8.0:
			bounce_pending = true
			bounce_vy = 0.35
	elif mode == MODE_DONE:
		geom_f = 0.0
		geom_r = 0.0
		load_f = 1.0
		load_r = 1.0
		_susp_integrate(SUSP_REST, SUSP_REST, delta)
	else:
		# AIR / HANG: no road contact - springs extend to full droop
		# (the dangling car's wheels hang; the flying car's settle).
		geom_f = 0.0
		geom_r = 0.0
		load_f = 1.0
		load_r = 1.0
		_susp_integrate(0.0, 0.0, delta)


func _refresh_car_visuals() -> void:
	# wheel visual follows steering angle: the spin node rotates
	# about the wheel's own axis (see the grab-math derivation note
	# at _hand_wheel_angle for the sign pairing)
	if wheel_spin != null:
		wheel_spin.rotation.y = -wheel_angle
	if car_body != null:
		var steer: float = clampf(wheel_angle / PI, -1.0, 1.0)
		car_body.rotation.z = -steer * 0.05 - lat_vel * 0.012
		# Fix Pass 5: body pitch IS the suspension pitch (nose dives
		# on landing, squats under power, works over slope breaks).
		car_body.rotation.x = pitch_extra
	# Fix Pass 5: wheel travel - each wheel rides its axle's spring:
	# compressed = up into the body, drooped = hanging low.
	for wi: int in wheel_mis.size():
		var c_axle: float = c_f if wheel_axle[wi] == 0 else c_r
		wheel_mis[wi].position.y = 0.34 + (c_axle - SUSP_REST)
	_update_view_spring()
	# dent carnage placeholder: nose crumples/tilts with dent level
	if nose_mi != null:
		nose_mi.rotation_degrees.z = float(dent_level) * 4.0
		nose_mi.scale = Vector3(1.0, 1.0 - 0.10 * float(denti_clamp()), 1.0 - 0.08 * float(denti_clamp()))
	if smoke_mi != null:
		smoke_mi.visible = smoke_on
		if smoke_on:
			var pulse: float = 1.0 + 0.25 * sin(Time.get_ticks_msec() / 180.0)
			smoke_mi.scale = Vector3.ONE * pulse
	# state label text
	if state_label != null:
		if mode == MODE_HANG:
			state_label.text = "DROP START" if is_drop_start and hang_phase == "dangle" else (
				"PRESS RELEASE" if hang_phase == "dangle" else "DRONE LIFT...")
		elif mode == MODE_DONE:
			state_label.text = "FINISH!"
		elif mode == MODE_AIR:
			state_label.text = "AIRBORNE"
		else:
			state_label.text = "GO!" if race_time < 3.0 and is_drop_start else ""
	_update_panel()


func _update_view_spring() -> void:
	# Fix Pass 5 (Items 1c + 4): the view rides the suspension, on the
	# ViewSpring node between the anchor and the origin (the desktop
	# fallback camera gets the same offsets). All offsets are
	# transient and zero at rest; they exist only while grounded
	# (DRIVE/AIR) - the hang has its own motion and the anchor framing
	# stays clean there.
	# - pitch follows the spring pitch (dive on landing, squat under
	#   acceleration, dip under braking) at VIEW_PITCH_GAIN;
	# - heave adds a fraction of the spring compression on top of the
	#   body's own ride motion;
	# - roll is the lean experiment's amplified tilt (Item 4): view
	#   roll = -lean * step * gain (lean right tips the view right),
	#   present only while the experiment is ON.
	var active: bool = mode == MODE_DRIVE or mode == MODE_AIR
	var v_pitch: float = 0.0
	var v_y: float = 0.0
	var v_roll: float = 0.0
	if active:
		v_pitch = pitch_extra * VIEW_PITCH_GAIN
		v_y = -((c_f + c_r) * 0.5 - SUSP_REST) * VIEW_HEAVE_GAIN
		if lean_on:
			v_roll = -_lean_effective() * deg_to_rad(LEAN_TILT_STEP_DEG) * LEAN_VIEW_GAIN
	if view_node != null:
		view_node.rotation = Vector3(v_pitch, 0.0, v_roll)
		view_node.position = Vector3(0.0, v_y, 0.0)
	# Fix Pass 6: the BODY layer rides on top of the car-spring view
	# motion - the eyes sink INTO the seat on the body spring's own
	# phase (see _update_body_spring). The fallback camera, parented
	# to its mirror BodySpring node, gets the identical offsets.
	var b_pitch: float = body_sink * BODY_PITCH_K \
		+ clampf(-long_accel_f * BODY_BRAKE_PITCH_K, 0.0, 0.016)
	if body_node != null:
		body_node.position = Vector3(0.0, -body_sink, 0.0)
		body_node.rotation = Vector3(b_pitch, 0.0, 0.0)
	if body_node_fb != null:
		body_node_fb.position = Vector3(0.0, -body_sink, 0.0)
		body_node_fb.rotation = Vector3(b_pitch, 0.0, 0.0)
	if fallback_cam != null:
		fallback_cam.rotation = Vector3(v_pitch, 0.0, v_roll)
		fallback_cam.position = EYE_ANCHOR + Vector3(0.0, v_y, 0.0)


func _body_impulse(impact_vy: float) -> void:
	# Fix Pass 6: a touchdown lands in the driver a beat after it
	# lands in the car - converted to a sink velocity here, scaled
	# by impact past a floor (soft arrivals barely register).
	var over: float = maxf(impact_vy - BODY_MIN_IMPULSE, 0.0)
	body_sink_v += over * BODY_IMPULSE_K


func _update_body_spring(delta: float) -> void:
	# Fix Pass 6 (Item 1): the driver-body spring. A soft, laggy
	# oscillator for the viewpoint's sink INTO the seat, integrated
	# independently of the car springs - its natural frequency
	# (~1.6 Hz) is lower and its phase later, so on a touchdown the
	# car compresses FIRST and the driver's peak sink follows.
	# Longitudinal load gives it a moving rest point: acceleration
	# presses the body into the seat, braking unloads it forward
	# (the pitch half of that lives in _update_view_spring).
	var rest_off: float = 0.0
	if mode == MODE_DRIVE:
		rest_off = clampf(long_accel_f * BODY_ACCEL_SINK_K, -0.012, 0.016)
	# Suspension bottoming thumps through the seat: an axle at full
	# travel and still compressing kicks the body spring (cooldown
	# so a sustained bottomed state kicks once, not per frame).
	body_bottom_cool = maxf(body_bottom_cool - delta, 0.0)
	if body_bottom_cool <= 0.0 and mode == MODE_DRIVE:
		if (c_f >= SUSP_TRAVEL - 0.001 and cv_f > 0.4) \
				or (c_r >= SUSP_TRAVEL - 0.001 and cv_r > 0.4):
			body_sink_v += 0.10
			body_bottom_cool = 0.4
	var acc: float = (rest_off - body_sink) * BODY_K - BODY_DAMP * body_sink_v
	body_sink_v += acc * delta
	body_sink = clampf(body_sink + body_sink_v * delta, -0.02, BODY_MAX_SINK)


func denti_clamp() -> int:
	return mini(dent_level, 3)


# ---------------------------------------------------------------- audio
# Fix Pass 6 (Item 3): synthesized engine + skid. Both streams are
# generated in code at build time (no audio assets): the engine is
# a one-second harmonic loop whose PLAYBACK RATE (pitch_scale) is
# the rev counter; the skid is a looped, seam-crossfaded noise
# buffer whose gain follows slip_state. Teardown discipline is
# implemented in _notification + _set_audio_latched + the stall
# watchdog in _process: latched OFF on focus-out / close / exit,
# gains cut while the physics loop is stalled, never started
# before a race is live, never resumed uninvited.

func _build_audio() -> void:
	engine_player = AudioStreamPlayer.new()
	engine_player.name = "EngineAudio"
	engine_player.stream = _make_engine_stream()
	engine_player.volume_db = AUDIO_ENGINE_IDLE_DB
	add_child(engine_player)
	skid_player = AudioStreamPlayer.new()
	skid_player.name = "SkidAudio"
	skid_player.stream = _make_skid_stream()
	skid_player.volume_db = -60.0
	add_child(skid_player)


func _make_engine_stream() -> AudioStreamWAV:
	# 1 s at 22050 Hz holding exactly 55 cycles of a 55 Hz
	# fundamental - the loop wraps seamlessly, and pitch_scale
	# moves the whole harmonic stack like an engine note.
	var rate: int = 22050
	var frames: int = rate
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i: int in frames:
		var ph: float = TAU * 55.0 * float(i) / float(rate)
		var v: float = sin(ph) + 0.55 * sin(ph * 2.0) + 0.30 * sin(ph * 3.0) \
			+ 0.16 * sin(ph * 4.0) + 0.08 * sin(ph * 7.0)
		v = clampf(v * 0.42, -0.85, 0.85)
		var s16: int = int(round(v * 32767.0))
		if s16 < 0:
			s16 += 65536
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


func _make_skid_stream() -> AudioStreamWAV:
	# 1 s of white noise (deterministic seed - same buffer every
	# build), one-pole low-passed toward tire hiss, with the last
	# 30 ms crossfaded into the head so the loop seam disappears.
	var rate: int = 22050
	var frames: int = rate
	var raw: Array[float] = []
	raw.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var lp: float = 0.0
	for i: int in frames:
		var wht: float = rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, wht, 0.35)
		raw[i] = lp * 1.4
	var fade: int = 660
	for i2: int in fade:
		var t: float = float(i2) / float(fade)
		raw[frames - fade + i2] = lerpf(raw[frames - fade + i2], raw[i2], t)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for j: int in frames:
		var s16b: int = int(round(clampf(raw[j], -0.8, 0.8) * 32767.0))
		if s16b < 0:
			s16b += 65536
		data[j * 2] = s16b & 0xFF
		data[j * 2 + 1] = (s16b >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frames
	return stream


func _set_audio_latched(on: bool) -> void:
	# The single door for the teardown latch (called from
	# _notification and the smoke). Latching STOPS both players -
	# not just gains down - so nothing can sound while latched.
	audio_latched = on
	if on:
		if engine_player != null and engine_player.playing:
			engine_player.stop()
		if skid_player != null and skid_player.playing:
			skid_player.stop()


func _update_audio(delta: float) -> void:
	# Runs on the physics tick: records the tick for the stall
	# watchdog (_process) and drives both channels from sim state.
	audio_last_physics_ms = Time.get_ticks_msec()
	audio_stalled = false
	if engine_player == null:
		return
	var running: bool = race_started and not audio_latched
	if not running:
		if engine_player.playing:
			engine_player.stop()
		if skid_player.playing:
			skid_player.stop()
		return
	if not engine_player.playing:
		engine_player.play()
	if not skid_player.playing:
		skid_player.play()
	# Engine: the rev target follows speed first; throttle flares
	# it, boost lifts it further, and AIRBORNE unloads it - with
	# the throttle open the revs climb free of the road.
	var rpm_target: float = 0.8
	var gain_target: float = AUDIO_ENGINE_IDLE_DB
	if mode == MODE_DRIVE or mode == MODE_DONE:
		rpm_target = 0.8 + clampf(speed / 34.0, 0.0, 1.0) * 1.85 \
			+ in_throttle * 0.22
		if in_boost and boost_meter > 0.0:
			rpm_target += 0.35
		gain_target = AUDIO_ENGINE_DB
	elif mode == MODE_AIR:
		rpm_target = 1.05 + in_throttle * 1.45
		gain_target = AUDIO_ENGINE_DB
	audio_rpm = lerpf(audio_rpm, rpm_target,
		clampf(delta * (3.2 if rpm_target > audio_rpm else 1.6), 0.0, 1.0))
	engine_player.pitch_scale = audio_rpm
	engine_player.volume_db = gain_target
	# Skid: fast attack (tires speak the moment they slide), fast
	# release (unloaded tires go quiet). slip_state is already 0
	# outside DRIVE, so the skid is silent airborne by construction.
	var rate_k: float = 16.0 if slip_state > audio_skid_now else 22.0
	audio_skid_now = lerpf(audio_skid_now, slip_state, clampf(delta * rate_k, 0.0, 1.0))
	if audio_skid_now < 0.01:
		skid_player.volume_db = -60.0
	else:
		skid_player.volume_db = lerpf(AUDIO_SKID_FLOOR_DB, AUDIO_SKID_MAX_DB, audio_skid_now)


func audio_engine_pitch() -> float:
	# Test accessor: the engine's current pitch factor (rev state).
	return audio_rpm


func audio_skid_gain() -> float:
	# Test accessor: the skid's current gain, 0..1 of full slip.
	return audio_skid_now


func _update_drone_visual(_delta: float) -> void:
	if drone == null:
		return
	if mode == MODE_HANG:
		drone.global_position = pivot_pos + Vector3.UP * 0.35
		# tilt toward travel while carrying; Fix Pass 5: a dip tilts
		# the drone as it drops and corrects (it is WORKING to hold
		# the load, not parked above it).
		var tilt: float = 0.16 if hang_phase == "carry" else 0.03 * sin(pend_th_f)
		tilt += dip_vy * 0.05
		# Fix Pass 6 (Item 4): the drone is a LIFT RIG, not a free
		# quad - during the hang it holds its YAW aligned to the
		# car's heading, so lift-line i runs drone corner i ->
		# car corner i and no pair of lines can cross (Chris's
		# run-6 photo: the wires crossed into an X). The corner
		# ORDER in _drone_corners/_car_corners matches (x-major,
		# then z); with yaw shared, the plan-view segments form a
		# quad's sides, never its diagonals. The yaw source is the
		# track frame at the drop target until the car is close
		# under the drone, then the car's own heading (its swing
		# yaw stays within a few degrees of the frame's - the
		# pendulum swings in the frame's axes).
		var fwd_src: Vector3 = _frame_at(drop_target_s)["tan"]
		if hang_phase == "dangle":
			fwd_src = -car.global_transform.basis.z
		var flat_fwd: Vector3 = Vector3(fwd_src.x, 0.0, fwd_src.z)
		var hang_yaw: float = drone.rotation.y
		if flat_fwd.length() > 0.05:
			hang_yaw = atan2(-flat_fwd.normalized().x, -flat_fwd.normalized().z)
		drone.rotation_degrees = Vector3(rad_to_deg(tilt), rad_to_deg(hang_yaw),
			rad_to_deg(pend_th_l * 0.4) + dip_vy * 2.2)
		var dc: Array[Vector3] = _drone_corners()
		var cc: Array[Vector3] = _car_corners()
		for i: int in 4:
			_set_line(line_mis[i], dc[i], cc[i])
	else:
		# drone shadows the car from above-behind, lines tucked away
		var want: Vector3 = car.global_position + Vector3.UP * 7.5 + car.global_transform.basis.z * 4.0
		drone.global_position = drone.global_position.lerp(want, 0.04)
		drone.rotation_degrees = Vector3.ZERO
		for lm: MeshInstance3D in line_mis:
			lm.visible = false


# --- debug/test helpers (smoke + render scripts) ---

func debug_warp_to_s(s: float) -> void:
	car_s = clampf(s, 0.0, track_len - 2.0)
	car_lat = 0.0
	lat_vel = 0.0
	speed = 14.0
	mode = MODE_DRIVE
	_place_car_on_track(_frame_at(car_s))


func debug_set_hang_dangle() -> void:
	if mode == MODE_HANG:
		hang_phase = "dangle"
		anchor_pos = anchor_target
		pivot_pos = anchor_pos


func debug_stage_landing(s: float, height: float, fwd_speed: float) -> void:
	# Fix Pass 5 render-proof staging: put the car ballistic above
	# the ribbon at s, falling - the production _update_air/_land
	# path (and its suspension impulse) does the rest.
	var fr: Dictionary = _frame_at(s)
	mode = MODE_AIR
	air_from_gap = false
	air_time = 0.0
	air_s_est = s
	air_vel = fr["tan"] * fwd_speed
	car.global_transform = Transform3D(
		Basis(fr["side"], fr["up"], -fr["tan"]),
		fr["pos"] + fr["up"] * (CLEARANCE + height))
