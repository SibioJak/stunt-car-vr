extends Node3D

## Stunt Car VR - DE Test 1 "Drop & Dangle"
## Throwaway FEEL prototype (Godot 4.7 / OpenXR, Quest-native target).
## One ribbon track, one placeholder Odd Rod car, grab-wheel steering,
## Drop Start + drone recovery with cockpit prep while dangling, and the
## lean-for-traction experiment. NO AUDIO. See design-spec.md items 1-16.
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

const HALF_WIDTH: float = 2.3
const RIBBON_DEPTH: float = 0.45 # box-section depth so the ribbon reads edge-on
const CLEARANCE: float = 0.35
const HANG_LEN: float = 5.5
const HANG_CLEAR: float = 1.2
const GRAV: float = 9.8
const SWITCH_NAMES: Array[String] = ["FUEL", "SPARK", "BOOST"]
const PREP_BOOST_CREDIT: float = 25.0

# --- track samples ---
var t_pts: Array[Vector3] = []
var t_tan: Array[Vector3] = []
var t_bank: Array[float] = []
var t_curv: Array[float] = []
var t_gap: Array[bool] = []
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

# suspension visual spring
var susp_x: float = 0.0
var susp_v: float = 0.0

# --- nodes ---
var car: Node3D
var car_body: Node3D
var nose_mi: MeshInstance3D
var wheel_node: Node3D
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
	start_race()
	set_process(true)


func _build_rig() -> void:
	origin = XROrigin3D.new()
	origin.name = "Origin"
	# Driver head anchor inside the cockpit; the origin rides the car.
	origin.position = Vector3(0.0, 1.02, 0.28)
	car.add_child(origin)
	xr_cam = XRCamera3D.new()
	origin.add_child(xr_cam)
	var xr_interface: XRInterface = XRServer.find_interface("OpenXR")
	if xr_interface != null and xr_interface.is_initialized():
		get_viewport().use_xr = true
		xr_ok = true
	else:
		fallback_cam = Camera3D.new()
		fallback_cam.position = Vector3(0.0, 1.02, 0.28)
		fallback_cam.name = "FallbackCam"
		car.add_child(fallback_cam)
		fallback_cam.current = true
	for hand: String in ["L", "R"]:
		# Tracker binding per the Duel field census on this rig (Quest 3):
		# plain "left_hand"/"right_hand", pose left at class default.
		var tracker_name: StringName = &"left_hand" if hand == "L" else &"right_hand"
		var c := XRController3D.new()
		c.tracker = tracker_name
		origin.add_child(c)
		hand_ctrl[hand] = c
		_build_controller_rep(c, hand)


func _build_controller_rep(ctrl: XRController3D, hand: String) -> void:
	var rep := Node3D.new()
	rep.name = "ControllerRep" + hand
	ctrl.add_child(rep)
	ctrl_rep[hand] = rep
	var accent: Color = Color(0.25, 0.85, 1.0) if hand == "L" else Color(1.0, 0.55, 0.2)
	_box(rep, Vector3(0.038, 0.026, 0.105), Vector3(0, 0, -0.02), _mat(Color(0.16, 0.16, 0.18)))
	_box(rep, Vector3(0.042, 0.010, 0.030), Vector3(0, 0.018, -0.03), _mat_unshaded(accent))
	var tip := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.011
	sm.height = 0.022
	tip.mesh = sm
	tip.position = Vector3(0, 0.01, -0.085)
	tip.material_override = _mat_unshaded(accent)
	rep.add_child(tip)


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


func _walk(steps: int, yaw_rate: float, phi_target: float, bank_target: float, is_gap: bool, phi_rate: float = 0.006) -> void:
	for i: int in steps:
		_gen_phi = move_toward(_gen_phi, phi_target, phi_rate)
		_gen_bank = move_toward(_gen_bank, bank_target, 0.012)
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
	_walk(20, 0.0, 0.0, 0.0, false) # flat run to the lip
	_walk(10, 0.0, deg_to_rad(10.0), 0.0, false, 0.030) # launch lip
	gap_s0 = float(t_pts.size())
	_walk(14, 0.0, deg_to_rad(2.0), 0.0, true, 0.020) # THE GAP - no ribbon
	gap_s1 = float(t_pts.size())
	_walk(40, 0.0, deg_to_rad(-3.4), 0.0, false, 0.020) # landing straight
	_walk(90, 0.0, deg_to_rad(-13.7), 0.0, false) # descent
	_walk(50, 0.0, 0.0, 0.0, false) # finish straight
	track_len = float(t_pts.size() - 1)

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
	# Floor + side pods (driver sits centre, head anchor at car-local (0,1.02,0.28))
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
	# Wheels (visual; front pair yaws with steering)
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
	# Steering column + grab wheel (wood-rimmed three-spoke: this car's character)
	# Fix Pass 1: wheel raised ~13.5 cm (hub 0.92 -> 1.055) and tipped a
	# little more toward the driver (-18 -> -22 deg) - Chris's field note
	# was "wheel is too low" for a comfortable seated grab. Column
	# lengthened/re-aimed to meet the new hub.
	var col := MeshInstance3D.new()
	var colm := CylinderMesh.new()
	colm.top_radius = 0.03
	colm.bottom_radius = 0.03
	colm.height = 0.38
	col.mesh = colm
	col.position = Vector3(0, 0.90, -0.54)
	col.rotation_degrees = Vector3(90, 0, 0)
	car_body.add_child(col)
	wheel_node = Node3D.new()
	wheel_node.name = "Wheel"
	wheel_node.position = Vector3(0, 1.055, -0.40)
	wheel_node.rotation_degrees = Vector3(-22, 0, 0)
	car_body.add_child(wheel_node)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.185
	torus.outer_radius = 0.225
	rim.mesh = torus
	rim.material_override = _mat(Color(0.45, 0.28, 0.12)) # wood rim
	wheel_node.add_child(rim)
	_box(wheel_node, Vector3(0.40, 0.045, 0.03), Vector3(0, 0, 0), _mat(Color(0.55, 0.55, 0.58)))
	_box(wheel_node, Vector3(0.045, 0.20, 0.03), Vector3(0, -0.10, 0), _mat(Color(0.55, 0.55, 0.58)))
	var hub := MeshInstance3D.new()
	var hubm := CylinderMesh.new()
	hubm.top_radius = 0.055
	hubm.bottom_radius = 0.055
	hubm.height = 0.05
	hub.mesh = hubm
	hub.rotation_degrees = Vector3(90, 0, 0)
	hub.material_override = _mat_unshaded(Color(1.0, 0.75, 0.15))
	wheel_node.add_child(hub)
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
	# Controls panel placard (right side, angled toward the driver, on a
	# dark backing board so it stays legible against the sky).
	# STANDING RULE: this lists EVERY command the game accepts.
	var panel_root := Node3D.new()
	panel_root.position = Vector3(0.80, 1.08, -0.38)
	panel_root.rotation_degrees = Vector3(-6, -38, 0)
	car_body.add_child(panel_root)
	_box(panel_root, Vector3(0.66, 0.90, 0.02), Vector3(0, 0, 0), _mat(Color(0.05, 0.07, 0.12)))
	panel_label = Label3D.new()
	panel_label.position = Vector3(-0.30, 0.41, 0.02)
	panel_label.font_size = 30
	panel_label.pixel_size = 0.00115
	panel_label.width = 540.0
	panel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_label.modulate = Color(0.92, 0.95, 1.0)
	panel_label.outline_size = 5
	panel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	panel_root.add_child(panel_label)
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
	lines.append("Grab wheel: squeeze GRIP near wheel, turn hand")
	lines.append("Throttle R trigger / Brake L trigger")
	lines.append("Boost: R A button (while driving)")
	lines.append("Release from drone: R trigger (when dangling)")
	lines.append("Flip switch: GRIP near a dash switch")
	lines.append("Call drone lift: L X button (while driving)")
	lines.append("Dash buttons: GRIP near red=restart, green=lean on/off")
	lines.append("Recenter view: L stick click / Restart race: L Y button")
	lines.append("-- DESKTOP --")
	lines.append("W/S throttle/brake, A/D steer, SHIFT boost")
	lines.append("SPACE release, 1/2/3 flip FUEL/SPARK/BOOST")
	lines.append("L call lift, T lean on/off, Q/E lean body")
	lines.append("R restart race, C recenter view")
	return "\n".join(lines)


func _update_panel() -> void:
	if panel_label != null:
		panel_label.text = _panel_text()


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
	# Godot 4.7 API: RotationMode enum (RESET_FULL_ROTATION + keep_height=false
	# recentres rotation AND position).
	XRServer.center_on_hmd(XRServer.RESET_FULL_ROTATION, false)


func _toggle_lean() -> void:
	lean_on = not lean_on
	if lean_on:
		_capture_lean_neutral()


func _capture_lean_neutral() -> void:
	if xr_cam != null:
		lean_neutral_x = xr_cam.transform.origin.x


# --- grab wheel ---
func _wheel_hub_local() -> Vector3:
	# must match wheel_node.position in _build_cockpit (raised in Fix Pass 1)
	return Vector3(0, 1.055, -0.40)


func _hand_wheel_angle(hand: String) -> float:
	var local: Vector3 = car.to_local(_hand_pos(hand)) - _wheel_hub_local()
	return atan2(local.y, local.x)


func _poll_grab(hand: String, ctrl: XRController3D, _delta: float) -> void:
	var grip_v: float = _input_float(ctrl, &"grip")
	var near_wheel: bool = _hand_pos(hand).distance_to(car.global_transform * _wheel_hub_local()) < 0.30
	var was: bool = gripping[hand]
	var now: bool = grip_v > 0.65
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
			# wheel is tilted -22 deg about X; hand rotation about the
			# car's Z still tracks the rim closely enough for a feel test.
			wheel_angle = clampf(wheel_angle - d, -PI, PI)
			grab_prev_ang = ang
	elif grab_hand == hand and not now:
		grab_hand = ""
		# other hand takes over if it is still gripping the wheel
		var other: String = "R" if hand == "L" else "L"
		if bool(gripping[other]) and _hand_pos(other).distance_to(car.global_transform * _wheel_hub_local()) < 0.30:
			grab_hand = other
			grab_prev_ang = _hand_wheel_angle(other)
	if grab_hand == "" and mode == MODE_DRIVE:
		wheel_angle = move_toward(wheel_angle, 0.0, 1.6 * _delta)


func _dash_ctl_near(world_pos: Vector3) -> int:
	for i: int in dash_ctl_nodes.size():
		if world_pos.distance_to(dash_ctl_nodes[i].global_position) < 0.24:
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
	susp_x = 0.0
	susp_v = 0.0
	drop_target_s = 2.0
	var fr: Dictionary = _frame_at(drop_target_s)
	anchor_pos = fr["pos"] + fr["up"] * (HANG_LEN + HANG_CLEAR)
	anchor_target = anchor_pos
	pend_th_f = 0.30
	pend_th_l = 0.12
	pend_om_f = 0.0
	pend_om_l = 0.0
	_prep_new_sequence()
	_capture_lean_neutral()
	_refresh_car_visuals()


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
	anchor_target = fr["pos"] + fr["up"] * (HANG_LEN + HANG_CLEAR)
	anchor_pos = catch_pos + Vector3.UP * (HANG_LEN + 1.6)
	# initial pendulum angles from the catch offset
	var off: Vector3 = catch_pos - anchor_pos
	pend_th_f = clampf(off.dot(fr["tan"]) / HANG_LEN, -0.6, 0.6)
	pend_th_l = clampf(off.dot(fr["side"]) / HANG_LEN, -0.6, 0.6)
	pend_om_f = 0.0
	pend_om_l = 0.0
	_prep_new_sequence()


func _find_drop_s(from_s: float) -> float:
	# nearest suitable straight: ahead, no gap, near-flat, near-straight
	var best: float = clampf(from_s + 8.0, 0.0, track_len - 4.0)
	var cand: float = from_s + 4.0
	while cand < track_len - 4.0 and cand < from_s + 90.0:
		var fr: Dictionary = _frame_at(cand)
		if not bool(fr["gap"]) and absf(float(fr["curv"])) < 0.004 and absf(float(fr["tan"].y)) < 0.12:
			best = cand
			break
		cand += 3.0
	return best


func _do_release() -> void:
	if mode != MODE_HANG or hang_phase != "dangle":
		return
	var fr: Dictionary = _frame_at(drop_target_s)
	var f: Vector3 = fr["tan"]
	var r: Vector3 = fr["side"]
	# pendulum tip velocity + a little forward push: you drop swinging
	var tip: Vector3 = (f * (pend_om_f * cos(pend_th_f)) + r * (pend_om_l * cos(pend_th_l))) * HANG_LEN
	air_vel = tip + f * 3.0
	air_s_est = drop_target_s
	air_time = 0.0
	air_from_gap = false
	mode = MODE_AIR
	prep_label.text = ""


# ---------------------------------------------------------------- sim

func _physics_process(delta: float) -> void:
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
	_update_lean_reading()
	_update_suspension(delta)
	_refresh_car_visuals()
	_update_drone_visual(delta)


func _process(_delta: float) -> void:
	# rotor spin (visual only)
	for r: MeshInstance3D in drone_rotors:
		r.rotation.y += 28.0 * _delta


func _update_drive(delta: float) -> void:
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
	var pos: Vector3 = fr["pos"] + fr["side"] * car_lat + fr["up"] * (CLEARANCE + susp_x * 0.06)
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
	susp_v = -vy * 0.55
	car_s = air_s_est
	car_lat = lat
	lat_vel = 0.0
	speed = clampf(air_vel.dot(fr["tan"]), 4.0, 34.0)
	mode = MODE_DRIVE
	was_airborne = false
	_place_car_on_track(fr)


func _update_hang(delta: float) -> void:
	match hang_phase:
		"attach":
			anchor_t += delta / 1.0
			_step_pendulum(delta)
			var target_car: Vector3 = _hang_car_pos(_frame_at(drop_target_s))
			var t: float = clampf(anchor_t, 0.0, 1.0)
			var e: float = t * t * (3.0 - 2.0 * t)
			car.global_position = hang_from_pos.lerp(target_car, e)
			_orient_car_hang()
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
	car.global_position = _hang_car_pos(fr)
	_orient_car_hang()


func _step_pendulum(delta: float) -> void:
	# damped pendulum, spring form; anchor motion excites it a little
	var k: float = GRAV / HANG_LEN
	pend_om_f += (-k * sin(pend_th_f) - 0.30 * pend_om_f) * delta
	pend_om_l += (-k * sin(pend_th_l) - 0.30 * pend_om_l) * delta
	pend_th_f += pend_om_f * delta
	pend_th_l += pend_om_l * delta


func _hang_car_pos(fr: Dictionary) -> Vector3:
	var dirv: Vector3 = (fr["tan"] * sin(pend_th_f) + fr["side"] * sin(pend_th_l)
		- Vector3.UP * (cos(pend_th_f) * cos(pend_th_l))).normalized()
	return anchor_pos + dirv * HANG_LEN


func _orient_car_hang() -> void:
	var fr: Dictionary = _frame_at(drop_target_s)
	var down_dir: Vector3 = (car.global_position - anchor_pos).normalized()
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


func _update_suspension(delta: float) -> void:
	# spring toward 0; kicks come from _land
	susp_v += (-120.0 * susp_x - 11.0 * susp_v) * delta
	susp_x += susp_v * delta
	susp_x = clampf(susp_x, -1.0, 1.0)


func _refresh_car_visuals() -> void:
	# wheel visual follows steering angle; body roll leans with lat motion
	if wheel_node != null:
		wheel_node.rotation.z = -wheel_angle
	if car_body != null:
		var steer: float = clampf(wheel_angle / PI, -1.0, 1.0)
		car_body.rotation.z = -steer * 0.05 - lat_vel * 0.012
		car_body.rotation.x = susp_x * 0.05
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


func denti_clamp() -> int:
	return mini(dent_level, 3)


func _update_drone_visual(_delta: float) -> void:
	if drone == null:
		return
	if mode == MODE_HANG:
		drone.global_position = anchor_pos + Vector3.UP * 0.35
		# tilt toward travel while carrying
		var tilt: float = 0.16 if hang_phase == "carry" else 0.03 * sin(pend_th_f)
		drone.rotation_degrees = Vector3(rad_to_deg(tilt), 0.0, rad_to_deg(pend_th_l * 0.4))
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
