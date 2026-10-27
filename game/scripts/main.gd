extends Node3D

## Stunt Car VR - DE Test 1 "Drop & Dangle"
## Throwaway FEEL prototype (Godot 4.7 / OpenXR, Quest-native target).
## One ribbon track, one placeholder Odd Rod car, grab-wheel steering,
## Drop Start + drone recovery with cockpit prep while dangling, and the
## lean-for-traction experiment. See design-spec.md items 1-16.
## Fix Pass 6 adds the project's first audio: synthesized engine + skid
## as an information channel (see the AUDIO constants block).
##
## Driving WAS a kinematic path model (path distance s + lateral
## offset) until Fix Pass 9. Chris, run 9: "I don't really have a
## sensation of the car turning, it more slides... like the Autopia
## ride, riding a rail." Correct - the old model slaved heading to
## the track frame and deflected the car laterally. Fix Pass 9
## replaces the core with a FREE-HEADING model: the car owns its
## yaw (steering -> front-wheel angle -> yaw rate with inertia,
## authority scaled by speed), velocity is its own world vector
## and decomposes against the heading into forward + lateral
## parts, and tire grip bleeds the lateral part toward zero up to
## a lateral grip limit (the lean modifiers apply to that limit).
## Demanding more than the limit leaves REAL slip - the car
## travels at an angle to where it points, recoverable by counter-
## steer - and slip_state derives from that actual lateral
## velocity. The track frame keeps only its proper jobs: road
## height/bank under the wheels, off-track/fall detection from
## (s, lat), gap spanning, lap/feature logic, drone targeting.
## Still Crammond-flavoured elsewhere: rationed boost, slope
## gravity, ballistic gap jumps, touchdown quality from impact
## speed + alignment, dent + smoke on hard landings.
##
## Grab rule (documented choice): the LAST hand to squeeze grip near the
## wheel drives it; if that hand releases while the other still grips,
## the other hand takes over (its angle reference resets on takeover).

const MODE_HANG: int = 0
const MODE_DRIVE: int = 1
const MODE_AIR: int = 2
const MODE_DONE: int = 3

# Fix Pass 9 (Item 3): the road's width is set by PROPORTION,
# Crammond's own: his road is exactly 6.0x his car's wheel track
# (384 road units vs a 64-unit track; crammond-notes.md Q1), and
# Chris's memory of the original "dwarfing" the car is that ratio,
# not an absolute width. MEASURED on this build: the front wheels
# sit at x = +-0.78 (the _build_car wheel loop, single-sourced
# below as WHEEL_LOCALS), so the front wheel track is 1.56 m and
# the Crammond-proportion road is 6.0 x 1.56 = 9.36 m full width.
# (Fix Pass 6 set 8 m by metres alone, ~4.4x our track - still
# narrow in the proportion the eye reads.) Everything derived
# from HALF_WIDTH (surface, skirts, edge strips, gantry,
# off-track and landing checks) follows.
const WHEEL_TRACK_M: float = 1.56 # front wheel-to-wheel, metres (measured)
# Wheel positions in car space (x = lateral, y = longitudinal with
# forward = -Z): FL, FR, RL, RR. Single source for the visual
# wheels, the suspension's support sampling, and the measurement
# above (front axle at z = -1.55 = AXLE_F ahead, rear at +1.45).
const WHEEL_LOCALS: Array[Vector2] = [
	Vector2(-0.78, -1.55), Vector2(0.78, -1.55),
	Vector2(-0.78, 1.45), Vector2(0.78, 1.45)]
const HALF_WIDTH: float = 3.0 * WHEEL_TRACK_M # full width = 6.0 x track = 9.36 m
# Fix Pass 9 (Item 2) - free-heading steering model constants.
# The grabbed wheel (+-180 deg) maps to a front-wheel angle of
# +-MAX_LOCK_RAD, scaled down with speed (a full lock at 30 m/s
# is a spin, not a steer); yaw rate follows the bicycle relation
# omega = vf / wheelbase * tan(front angle), capped, and chases
# its target through a first-order lag of YAW_TAU seconds - the
# yaw INERTIA that makes the car feel massive, not twitchy. At a
# standstill the bicycle target is exactly zero: no rotation on
# the spot (crawl-speed manoeuvre comes from crawl-speed motion).
const MAX_LOCK_RAD: float = 0.56 # front-wheel lock at full wheel, ~32 deg
const STEER_FALLOFF_SPEED: float = 26.0 # lock scale = 1 / (1 + (vf/this)^2)
const MAX_YAW_RATE: float = 1.6 # rad/s, either direction
const YAW_TAU: float = 0.16 # s, yaw-rate lag (inertia)
# Tire grip: the lateral velocity (velocity across the heading)
# is bled toward zero by a lateral acceleration that is
# proportional to the slip (GRIP_BITE_RATE per second) up to the
# lateral grip limit GRIP_LAT_ACCEL - the lean experiment's grip
# multiplier scales both. Below the limit the velocity follows
# the heading (the car turns); demanding more yaw than the limit
# can curve the velocity through leaves the excess as slip.
# Sizing: holding the R30 banked sweeper at the stage-2f pinned
# 24 m/s needs ~19.2 m/s^2 of lateral acceleration; the bank's
# own gravity supplies ~4.9, so the tires supply ~14 - ABOVE the
# limit below, which is the point: the corner at full pace runs
# at a real, sustained slip (equilibrium lateral velocity
# ~2.0 m/s, slip_state ~0.22) while at autopilot cornering pace
# (~18 m/s, ~6 m/s^2 of tire work) the car runs clean.
const GRIP_BITE_RATE: float = 7.0 # 1/s, proportional lateral bleed
const GRIP_LAT_ACCEL: float = 11.0 # m/s^2, lateral grip limit (~1.1 g)
# Fix Pass 9 (Item 2, scope addition) - the edge-straddle save.
# Chris recalls the original's tires running off the ribbon
# edge: "they'd really wobble but you could save it and get
# back on track." The converted source confirms the mechanism
# (Car Behaviour.cpp, CalculateIfCarOffRoad): each wheel's
# support height is independent; past the edge the road has
# "invisible sloping sides" - the wheel's height drops
# PROGRESSIVELY with overshoot - and only beyond 3/4 of the car
# width past the edge is that wheel fully unsupported. Ours:
# each wheel's support drops EDGE_SLOPE per metre of overshoot
# up to EDGE_CUTOFF (= 3/4 of the wheel track past the edge),
# where support is gone. The whole car falls only when its
# CENTRE overshoot exceeds EDGE_CUTOFF + half the track - the
# point where even the innermost wheel has lost the shoulder,
# i.e. support is truly gone, not at first edge contact.
const EDGE_SLOPE: float = 0.55 # support drop per metre of wheel overshoot
const EDGE_CUTOFF: float = 0.75 * WHEEL_TRACK_M # 1.17 m: wheel fully unsupported past this
const EDGE_FALL_OVERSHOOT: float = EDGE_CUTOFF + 0.5 * WHEEL_TRACK_M # 1.95 m centre overshoot = fall
const EDGE_ROLL_LAG: float = 7.0 # 1/s, the wobble is lagged, not a snap
const DESERT_FLOOR_Y: float = -30.0 # ~60 m below the track datum (y=30)
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
# Fix Pass 8 (Item 2) - airborne is a LOAD decision (see
# _update_suspension): the geometry route fires when the crest
# load factor sits at ~zero at BOTH axles for AIR_SUSTAIN_FRAMES
# consecutive frames (the road is falling away faster than
# gravity - no stored-energy history is required or consulted);
# the rebound route fires when the springs reach full droop
# still throwing faster than REBOUND_THROW_VEL (stored energy
# leaving) but only at full supporting load (the load floor
# below). The climb-top case the old >0.19 m peak-compression
# gate protected is handled by that floor, not by history:
# there the load is partial (~0.27) and sustained, never
# ~zero, so the geometry route cannot fire, and the rebound
# route is closed because at partial load the road's
# geometry, not the springs, holds the car (measured: both
# springs still sag to droop there, the rear extending at
# ~0.57 m/s - droop + velocity alone cannot tell a bleed
# from a bounce; the load level can).
const AIR_LOAD_EPS: float = 0.03 # crest load factor that counts as unloaded
const AIR_SUSTAIN_FRAMES: int = 3 # frames at ~zero load before separation
const REBOUND_THROW_VEL: float = -0.6 # cv_f + cv_r (m/s) that counts as a throw
const REBOUND_LOAD_FLOOR: float = 0.8 # rebound route needs the road fully supporting
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
const AUDIO_SLIP_ONSET: float = 1.2 # |lateral velocity| (m/s) where tires start to sing
const AUDIO_SLIP_SPAN: float = 3.8 # lateral-velocity range from onset to full slip
const AUDIO_STALL_MS: int = 600 # physics-tick gap that counts as a stall
# Fix Pass 7 (Item 2) - the Crammond jitter mechanism, reproduced
# structurally (crammond-notes.md Q3): the original's road profiles
# are smooth analytic ramps - its tire jitter EMERGES from faceted
# segments, heights quantised to coarse steps, few-point wheel
# sampling, and a wheel response whose derivative term amplifies
# the steps. Our version of the same structure: the SUSPENSION
# samples a quantised elevation profile - control heights snapped
# to JITTER_STEP_M at facet boundaries JITTER_FACET_M apart along
# the track, linear between boundaries. The visible ribbon mesh,
# the car placement and the slip/skid path all keep reading the
# SMOOTH profile: it looked smooth; it drove rough. No camera
# shake, no noise anywhere - the tremble arises through the
# existing springs' response to the stepped surface. Constants
# tuned BY MEASUREMENT (smoke stage 2g's shelf protocol): at
# FACET 5 m / STEP 0.05 m the steady climb's per-axle suspension
# travel trembles 12-14 mm peak-to-peak (the brief's 5-15 mm
# band); the 0.025 m starting step measured only ~3 mm - the
# mechanism was real but under the model's own grid noise.
const JITTER_FACET_M: float = 5.0 # along-track facet length, m
const JITTER_STEP_M: float = 0.05 # height snap at facet boundaries, m

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
# Fix Pass 7 (Item 1): extension anchors, recorded by the generator
# (s of the extension's first sample, the mirrored sweeper's span,
# and the second gap's span) so tests/proofs reference the built
# track instead of hand-copied numbers.
var ext_s0: float = 0.0
var sweeper_s0: float = 0.0
var sweeper_s1: float = 0.0
var gap2_s0: float = 0.0
var gap2_s1: float = 0.0
# Fix Pass 8: the staircase's span, for stage 9's two-tier step
# bounds (the staircase's drops are designed hammerings; the
# strict continuous bound applies outside them).
var stairs_s0: float = 0.0
var stairs_s1: float = 0.0

# --- sim state ---
var mode: int = MODE_HANG
var hang_phase: String = "dangle"
var is_drop_start: bool = true
# Fix Pass 9 (Item 2): car_s / car_lat are DERIVED state now -
# the car's world position projected onto the track spine each
# DRIVE/AIR frame (_project_to_spine). They keep their old jobs
# (feature logic, drone targeting, tests) but nothing integrates
# them; the car's own state is its world position (the node),
# its heading, and its velocity vector.
var car_s: float = 0.0
var car_lat: float = 0.0
var lat_vel: float = 0.0 # velocity across the heading (the real slip velocity)
var speed: float = 0.0 # velocity along the heading (panel/audio/tests read this)
var car_heading: float = 0.0 # the car's own yaw, rad (never read from the frame)
var yaw_rate: float = 0.0 # rad/s, lagged toward the bicycle target
var vel2: Vector2 = Vector2.ZERO # world-XZ velocity, m/s (velocity != heading)
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
var jitter_on: bool = true # Fix Pass 7 (Item 2): jitter experiment toggle, default ON
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
# Fix Pass 8 (Item 0): synthetic hand inputs for the smoke's
# grip-path stage - an analog grip level per hand and, when
# test_hand_set, the hand positions _hand_pos reports. Read
# ONLY under test_mode (never set in the shipped game); the
# production XR reads are untouched.
var test_grip: Dictionary = {"L": 0.0, "R": 0.0}
var test_hand_set: bool = false
var test_hand_pos: Dictionary = {"L": Vector3.ZERO, "R": Vector3.ZERO}

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
var air_load_frames: int = 0 # consecutive frames at ~zero crest load, both axles
var wheel_mis: Array[MeshInstance3D] = []
var wheel_axle: Array[int] = [] # 0 = front, 1 = rear, parallel to wheel_mis
# Fix Pass 9 (Item 2, scope addition): per-WHEEL support state,
# written by _update_suspension every DRIVE frame (wheel order
# FL, FR, RL, RR - WHEEL_LOCALS). sup_rise is each wheel's road
# rise relative to the centre frame (drops included); sup_ok is
# false once a wheel is past EDGE_CUTOFF (fully unsupported).
# edge_roll is the lagged body roll toward an unsupported side -
# the straddle wobble - and feeds the placement basis.
var sup_rise: Array[float] = [0.0, 0.0, 0.0, 0.0]
var sup_ok: Array[bool] = [true, true, true, true]
var sup_s: Array[float] = [0.0, 0.0, 0.0, 0.0] # each wheel's spine s (load sampling)
var edge_roll: float = 0.0
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
# _update_drive from the car's REAL lateral velocity (Fix Pass 9:
# velocity across the heading, post-grip-bleed) and consumed by
# the skid gain - it is a physics output, not an input proxy.
# Teardown discipline: audio_latched is set by application
# focus-out / close request / scene-tree exit and STOPS both
# players; it clears only on a genuine focus-in while a race is
# live. audio_stalled is the watchdog state (physics ticks gone
# quiet): gains are cut while it holds, physics resuming clears it.
var slip_state: float = 0.0
var race_started: bool = false

# Fix Pass 8 (Item 1) step logger: when step_log_on is set (the
# smoke's stage 9), every physics frame appends one row AFTER all
# updates: [s_pos, mode, view_y, view_pitch, frame_us]. view_y is
# the camera-height proxy - the car's world height plus the seat
# stack's vertical offsets (ViewSpring heave minus body sink), the
# quantity the driver's eye actually rides; view_pitch is the
# car's world pitch plus the view/body spring pitch offsets.
# frame_us is the wall time since the previous physics frame -
# it separates a step that correlates with a long frame (a hitch)
# from a step that repeats at a place (a mechanism). Inert unless
# enabled: no behaviour reads it.
var step_log_on: bool = false
var step_rows: Array = []
var _step_last_us: int = 0
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
# Fix Pass 9 (Item 1): the dash control each hand has already
# fired during its current continuous grab-and-zone entry
# (-1 = armed). Level-based activation: the control fires once
# when a gripping hand is in its zone with this latch unset for
# it; the latch clears when the grip releases or the hand
# leaves every zone, and moving zone-to-zone fires on entry.
var dash_ctl_fired: Dictionary = {"L": -1, "R": -1}


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
	# Fix Pass 9: raised a notch (0.0003) now that there is a world
	# to fade - the desert hills at 600-900 m soften into haze so a
	# horizon reads, while the ribbon at driving distances (tens of
	# metres) is untouched.
	env.fog_density = 0.0003
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	sun.light_energy = 1.15
	add_child(sun)
	# Fix Pass 9 (Item 3): THE DESERT. Until now the ribbon floated
	# in a featureless void with a green plane at y=0 - and a void
	# gives the eye no ruler, so nothing can be DWARFED by it
	# (Chris, run 9, with the original's cockpit screenshot: half
	# the frame is sky, the desert runs flat to a low horizon, and
	# the track dwarfs the car). Now: a vast flat desert floor
	# ~60 m below the track datum (the ribbon starts at y=30 and
	# its lowest sections sit ~85-95 m above this floor), a ring
	# of distant low hills a few hundred metres out, and a few
	# mesas - a handful of large flat-shaded meshes in total,
	# sand-toned against the existing sky. The desert is SCENERY:
	# the fall/recovery logic is untouched (the drone catches the
	# car ~13 m below the ribbon, far above this floor; the car
	# never lands on the desert). The old green ground blocks are
	# gone - they floated at the old plane's height.
	var desert := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5000.0, 5000.0)
	desert.mesh = pm
	desert.position = Vector3(0.0, DESERT_FLOOR_Y, -450.0)
	desert.material_override = _mat(Color(0.76, 0.62, 0.42))
	desert.name = "DesertFloor"
	add_child(desert)
	# Distant low hills: one ring of stretched, slightly rotated
	# boxes around the track's extent (the ribbon runs z 0..-1250,
	# x roughly +-250 after its corners). Flat-shaded, a touch
	# darker and greyer than the floor so they read as distance.
	var hill_mat := _mat(Color(0.62, 0.52, 0.42))
	var hills: Array = [
		[Vector2(-620.0, -700.0), 700.0, 46.0, 10.0],
		[Vector2(240.0, -980.0), 820.0, 58.0, -6.0],
		[Vector2(760.0, -420.0), 640.0, 38.0, 24.0],
		[Vector2(680.0, 260.0), 760.0, 42.0, -18.0],
		[Vector2(-40.0, 480.0), 900.0, 34.0, 4.0],
		[Vector2(-780.0, 140.0), 680.0, 50.0, 14.0],
		[Vector2(-420.0, -1320.0), 780.0, 40.0, -10.0],
		[Vector2(420.0, -1420.0), 860.0, 52.0, 8.0],
	]
	for hi: int in hills.size():
		var hd: Array = hills[hi]
		var hxz: Vector2 = hd[0]
		var hill := _box(self, Vector3(float(hd[1]), float(hd[2]), 190.0),
			Vector3(hxz.x, DESERT_FLOOR_Y + float(hd[2]) * 0.32, hxz.y), hill_mat,
			"Hill%d" % hi)
		hill.rotation_degrees.y = float(hd[3])
	# A few flat-topped mesas standing on the floor, nearer in -
	# parallax when the car is high on the climbs.
	var mesa_mat := _mat(Color(0.68, 0.55, 0.40))
	var mesas: Array = [
		[Vector2(-190.0, -260.0), 90.0, 16.0],
		[Vector2(230.0, -520.0), 120.0, 22.0],
		[Vector2(-260.0, -830.0), 105.0, 13.0],
		[Vector2(180.0, -1080.0), 140.0, 19.0],
	]
	for mi2: int in mesas.size():
		var md: Array = mesas[mi2]
		var mxz: Vector2 = md[0]
		_box(self, Vector3(float(md[1]), float(md[2]), float(md[1]) * 0.62),
			Vector3(mxz.x, DESERT_FLOOR_Y + float(md[2]) * 0.5, mxz.y), mesa_mat,
			"Mesa%d" % mi2)


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
	# corner walks converge bank fast instead (0.10 rad/sample in
	# Fix Pass 3; Fix Pass 8 shapes it 0.03 -> 0.075, flat ~10
	# samples past the corner exit - see below).
	# Fix Pass 8 (Item 1): the bank unwind is SHAPED - 3 samples
	# at 0.03, then 0.075 - instead of a flat 0.10 from the first
	# sample. The flat 0.10 was the generator's fastest rate,
	# and its start/stop rate steps were the worst view-height
	# steps in the run-8 measurement (s~178: the car's lateral
	# offset rides the banked frame's side vector as it swings).
	# The unwind still completes in ~10 samples, so the frame
	# is flat well before the s=195 check and the lip.
	_walk(3, 0.0, 0.0, 0.0, false, 0.006, 0.03) # flat run: bank unwind, gentle first
	_walk(17, 0.0, 0.0, 0.0, false, 0.006, 0.075) # flat run to the lip: unwind completes
	# Fix Pass 8: the lip's phi entry is shaped the same way
	# (2 samples at 0.012, then 0.034) - its rate step was a
	# top-10 height step in the BEFORE table.
	_walk(2, 0.0, deg_to_rad(10.0), 0.0, false, 0.012, 0.10) # launch lip, shaped entry
	_walk(8, 0.0, deg_to_rad(10.0), 0.0, false, 0.034, 0.10) # launch lip
	gap_s0 = float(t_pts.size())
	_walk(14, 0.0, deg_to_rad(2.0), 0.0, true, 0.020) # THE GAP - no ribbon
	gap_s1 = float(t_pts.size())
	_walk(40, 0.0, deg_to_rad(-3.4), 0.0, false, 0.020) # landing straight
	_walk(90, 0.0, deg_to_rad(-13.7), 0.0, false) # descent
	_walk(50, 0.0, 0.0, 0.0, false) # finish straight (the old lap's end)
	# Fix Pass 7 (Item 1): THE EXTENSION. Everything above this line
	# is the Fix Pass 6 lap, generated exactly as before (six runs of
	# verdicts compare against it); the ribbon now CONTINUES past
	# the old finish instead of ending there, roughly tripling the
	# lap: rolling crests -> a banked sweeper mirrored from the
	# first corner (the lap banked only one way; steering must be
	# judgeable both ways) -> a descending staircase -> a second
	# gap at the same 14 m spec -> a final climb and a long home
	# straight to the new finish (the gantry below derives from
	# track_len, so it follows on its own).
	ext_s0 = float(t_pts.size() - 1)
	# Fix Pass 8 (Item 2): the crest straight's gentle rollers
	# (Fix Pass 7: 4 x +-5 deg over 70 m, kv ~0.006) compressed
	# the springs - 0.162 m peak - but NEVER unloaded them: at
	# 24 m/s the load factor only fell to ~0.65, and Chris got
	# no air on the little hills. They are now TRUE HUMPS,
	# shaped by the unload arithmetic. A hump is three walks:
	# climb in at +11 deg (phi rate 0.016/m - the concave-up
	# entry LOADS the springs, the valley before the crest),
	# over the top sweeping phi +11 -> -11 deg at 0.021 rad/m,
	# then flatten at 0.016/m. Over the top the road's vertical
	# curvature kv ~ +0.021/m, so at the stage's stated cruise
	# of 24 m/s: v^2 * kv = 576 * 0.021 = 12.1 > g = 9.8 -
	# the surface falls away faster than the car's ballistic
	# path and the crest load factor clamps to zero at both
	# axles for ~0.5 s: geometry-driven air, Crammond's Hump
	# Back energy. Each hump stands ~2.2 m over a 45 m
	# wavelength; five of them, then the settle flat.
	for hump: int in 5: # true humps: climb in, over the top, flatten
		_walk(13, 0.0, deg_to_rad(11.0), 0.0, false, 0.016) # climb in (loads the springs)
		_walk(19, 0.0, deg_to_rad(-11.0), 0.0, false, 0.021) # over the top (kv ~0.021: unloads)
		_walk(13, 0.0, 0.0, 0.0, false, 0.016) # flatten out (the landing side)
	_walk(20, 0.0, 0.0, 0.0, false) # settle flat out of the humps
	sweeper_s0 = float(t_pts.size())
	_walk(47, -deg_to_rad(90.0) / 47.0, 0.0, deg_to_rad(-34.0), false) # banked sweeper, mirrored
	sweeper_s1 = float(t_pts.size())
	_walk(3, 0.0, 0.0, 0.0, false, 0.006, 0.03) # flatten out: shaped bank unwind, as post-corner
	_walk(17, 0.0, 0.0, 0.0, false, 0.006, 0.075) # flatten out: unwind completes
	# Fix Pass 8 (Item 1): the staircase keeps UNIFORM phi
	# increments - 0.077 rad/sample down and back, the same
	# rate at every join of the cycle - instead of the original
	# instant switch between 0 and 0.06 at the cycle edges
	# (rate steps were part of the run-8 step family; measured
	# in stage 9's BEFORE table). Uniform increments mean the
	# only rate changes are the four level joins per cycle, all
	# the same size, and the build-time profile smoothing below
	# spreads each over ~2 samples. Phi reaches the full -22
	# deg (the old 0.06-rate cycle only reached -17 deg in its
	# 5 samples), each cycle drops ~1.9 m, and the suspension
	# still bottoms on every drop (stage 8 asserts it): the
	# staircase still reads as steps.
	stairs_s0 = float(t_pts.size() - 1)
	for step_i: int in 6: # descending staircase: drop, tread, drop...
		_walk(5, 0.0, deg_to_rad(-22.0), 0.0, false, 0.077)
		_walk(6, 0.0, 0.0, 0.0, false, 0.077)
	stairs_s1 = float(t_pts.size() - 1)
	_walk(30, 0.0, 0.0, 0.0, false, 0.020) # flat run to the second lip
	_walk(2, 0.0, deg_to_rad(10.0), 0.0, false, 0.012, 0.10) # second launch lip, shaped entry
	_walk(8, 0.0, deg_to_rad(10.0), 0.0, false, 0.034, 0.10) # second launch lip
	gap2_s0 = float(t_pts.size())
	_walk(14, 0.0, deg_to_rad(2.0), 0.0, true, 0.020) # THE SECOND GAP - same 14 m spec
	gap2_s1 = float(t_pts.size())
	_walk(40, 0.0, deg_to_rad(-3.4), 0.0, false, 0.020) # second landing straight
	_walk(90, 0.0, deg_to_rad(13.0), 0.0, false) # final climb
	_walk(200, 0.0, 0.0, 0.0, false) # long home straight to the new finish
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
	# Fix Pass 8 (Item 1): curvature is what a 3 m wheelbase FEELS
	# - an average over the contact patches, not a point value -
	# so the stored profile gets one [0.25, 0.5, 0.25] smoothing
	# pass. The raw per-sample kv stepped the suspension's crest
	# load factor at every sample join (part of the run-8 step
	# family); a plateau (the humps' fall-away, the climb-top
	# bend) is several samples long and survives the pass intact.
	var kv_raw: Array[float] = []
	kv_raw.assign(t_kv)
	for ki2: int in t_kv.size():
		var km2: int = maxi(ki2 - 1, 0)
		var kp2: int = mini(ki2 + 1, t_kv.size() - 1)
		t_kv[ki2] = 0.25 * kv_raw[km2] + 0.5 * kv_raw[ki2] + 0.25 * kv_raw[kp2]
	# Fix Pass 8 (Item 1): the same [0.25, 0.5, 0.25] pass over
	# the stored POINTS and TANGENTS. The generator's profile is
	# a polygon - slope corners at every sample - and a frame
	# straddling a corner concentrates the slope change into one
	# view step (the run-8 jumps: measured worst 0.019 m /
	# 1.57 deg, all at joins). One smoothing pass rounds every
	# corner over ~2 samples: a join's step spreads across
	# neighbouring frames instead of snapping in one. The
	# deviation is small and honest - at most ~1.5 cm at the
	# sharpest corners (the staircase edges), millimetres on
	# the gentle profile - and everything downstream (mesh,
	# placement, suspension, the air line) reads the same
	# smoothed arrays through _frame_at, so the world stays
	# self-consistent. The quantised jitter surface (_elev_smooth
	# / _elev_quantised) reads the smoothed profile too and
	# re-facets it at 5 m / 0.05 m, so the Crammond tremble is
	# unchanged in kind (stage 2g re-measures its band).
	var pts_raw: Array[Vector3] = []
	pts_raw.assign(t_pts)
	var tan_raw: Array[Vector3] = []
	tan_raw.assign(t_tan)
	for si: int in t_pts.size():
		var sm: int = maxi(si - 1, 0)
		var sp: int = mini(si + 1, t_pts.size() - 1)
		t_pts[si] = 0.25 * pts_raw[sm] + 0.5 * pts_raw[si] + 0.25 * pts_raw[sp]
		t_tan[si] = (0.25 * tan_raw[sm] + 0.5 * tan_raw[si] + 0.25 * tan_raw[sp]).normalized()

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
		# stilts every 10 m down to the ground (Fix Pass 9: the
		# desert floor, ~60 m below the datum - the stilts now
		# land on something instead of ending in the void)
		if i % 10 == 0:
			var top: Vector3 = p0
			var bot := Vector3(p0.x, DESERT_FLOOR_Y, p0.z)
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
	# Fix Pass 8 (Item 1): this interpolation stays LINEAR, on
	# measured evidence. The run-8 steps (stage 9's BEFORE
	# table: worst 1.57 deg pitch / 0.019 m height, all at
	# profile joins, none on a long frame) indicted the joins
	# themselves, and a cubic-Hermite frame was tried first in
	# this pass: it measured WORSE (6.3 deg at the staircase) -
	# the generator's stored tangents are the ARRIVING step
	# directions, so on the staircase's cornered profile the
	# Hermite tangent overshoots past both endpoint tangents
	# mid-segment and oscillates at the sample frequency. The
	# fix that measured better lives in the data this lerp
	# reads: the stored points/tangents get one [0.25, 0.5,
	# 0.25] smoothing pass at build (see _build_track), the
	# staircase's phi increments are uniform, the corner-exit
	# bank unwind and the lip phi entries are rate-shaped, and
	# t_kv is smoothed the same way - so the rates this lerp
	# produces sweep over ~2-3 samples instead of switching
	# in one.
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


# Fix Pass 7 (Item 2): the quantised physics surface. The smooth
# elevation profile resampled the Crammond way: control heights at
# facet boundaries JITTER_FACET_M apart, each snapped to the
# JITTER_STEP_M grid, linear interpolation between boundaries - the
# profile the SUSPENSION feels is faceted and stepped while
# remaining recognisably the same road. Read ONLY by the
# suspension's geom targets (see _update_suspension); over a gap
# span it returns the profile's air line, exactly as the smooth
# surface does - the gap itself stays un-quantised air.
func _elev_smooth(s: float) -> float:
	var p: Vector3 = _frame_at(s)["pos"]
	return p.y


func _elev_quantised(s: float) -> float:
	var s_clamped: float = clampf(s, 0.0, track_len)
	var facet: float = floor(s_clamped / JITTER_FACET_M)
	var s0: float = facet * JITTER_FACET_M
	var frac: float = (s_clamped - s0) / JITTER_FACET_M
	var h0: float = snappedf(_elev_smooth(s0), JITTER_STEP_M)
	var h1: float = snappedf(_elev_smooth(s0 + JITTER_FACET_M), JITTER_STEP_M)
	return lerpf(h0, h1, frac)


# ------------------------------------------------- Fix Pass 9 helpers
# The heading convention: heading h has forward (-sin h, 0, -cos h)
# and right (cos h, 0, -sin h), matching Basis(Vector3.UP, h) and
# the frame convention (a frame with tangent t has yaw
# atan2(-t.x, -t.z) - the same formula, so frame yaw and car
# heading are directly comparable).

func _frame_yaw(tanv: Vector3) -> float:
	return atan2(-tanv.x, -tanv.z)


func _heading_fwd() -> Vector3:
	return Vector3(-sin(car_heading), 0.0, -cos(car_heading))


func _heading_right() -> Vector3:
	return Vector3(cos(car_heading), 0.0, -sin(car_heading))


## Project a world point onto the track spine: returns [s, lat]
## with lat measured along the frame side at s. Searches the
## segments around the hint first; if the best segment sits at
## the window's edge the search widens once (a landing or a warp
## can put the car far from its hint). This is how car_s/car_lat
## are DERIVED from the car's actual position under the
## free-heading model - nothing integrates them anymore.
func _project_to_spine(p: Vector3, hint: float, wide: bool = false) -> Array:
	var n: int = t_pts.size()
	var centre: int = clampi(int(round(hint)), 0, n - 2)
	var rad: int = 280 if wide else 8
	var i0: int = maxi(0, centre - rad)
	var i1: int = mini(n - 2, centre + rad)
	var best_i: int = centre
	var best_t: float = 0.0
	var best_d2: float = 1e18
	for i: int in range(i0, i1 + 1):
		var a: Vector3 = t_pts[i]
		var ab: Vector3 = t_pts[i + 1] - a
		var l2: float = ab.length_squared()
		var t: float = 0.0
		if l2 > 1e-9:
			t = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
		var d2: float = p.distance_squared_to(a + ab * t)
		if d2 < best_d2:
			best_d2 = d2
			best_i = i
			best_t = t
	if not wide and (best_i == i0 or best_i == i1) and (i0 > 0 or i1 < n - 2):
		return _project_to_spine(p, hint, true)
	var s: float = clampf(float(best_i) + best_t, 0.0, track_len)
	var fr: Dictionary = _frame_at(s)
	return [s, (p - fr["pos"]).dot(fr["side"])]


func _sync_vel2_from_speed_lat() -> void:
	# Rebuild the world velocity from the heading-frame pair
	# (speed, lat_vel) - used at transitions where those two are
	# the authoritative state (air entry from the suspension).
	var f: Vector3 = _heading_fwd()
	var r: Vector3 = _heading_right()
	vel2 = Vector2(f.x, f.z) * speed + Vector2(r.x, r.z) * lat_vel


func _enter_air(from_gap: bool, extra_vy: float) -> void:
	# Fix Pass 9: air entry from the velocity VECTOR. The vertical
	# component follows the road slope the velocity is actually
	# travelling along (the velocity's own projection on the
	# spine tangent), not the heading - a sliding car leaves the
	# lip along its motion. Heading is NOT integrated in AIR:
	# no yaw authority airborne (the original's discipline too).
	var fr: Dictionary = _frame_at(car_s)
	var t3: Vector3 = fr["tan"]
	var t2 := Vector2(t3.x, t3.z)
	var vy: float = vel2.dot(t2) * t3.y / maxf(t2.length_squared(), 0.04) + extra_vy
	air_vel = Vector3(vel2.x, vy, vel2.y)
	air_s_est = car_s
	air_time = 0.0
	air_from_gap = from_gap
	was_airborne = true
	mode = MODE_AIR


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
	# Fix Pass 9: positions come from WHEEL_LOCALS (FL, FR, RL, RR) -
	# the same table the suspension samples support from.
	for wi: int in WHEEL_LOCALS.size():
		var wl: Vector2 = WHEEL_LOCALS[wi]
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.34
		cm.bottom_radius = 0.34
		cm.height = 0.24
		w.mesh = cm
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = Vector3(wl.x, 0.34, wl.y)
		w.material_override = dark
		w.name = "WheelF" if wl.y < 0.0 else "WheelR"
		car_body.add_child(w)
		wheel_mis.append(w)
		wheel_axle.append(0 if wl.y < 0.0 else 1)
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
	# Fix Pass 10 (Item 0): raised 3.5 cm - the DIAG block grew a
	# sixth line (the per-control ZONE readout) and the new
	# bottom row's sightline clipped the wheel rim's left arc in
	# the render proof's occlusion sweep.
	diag_root.position = Vector3(-0.53, 1.205, -0.85)
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
	lines.append("Jitter exp: R stick click")
	lines.append("Dash buttons (GRIP near):")
	lines.append("red restart, green lean")
	lines.append("Recenter: L stick click, restart: L Y")
	lines.append("-- DESKTOP --")
	lines.append("W/S throttle/brake, A/D steer, SHIFT boost")
	lines.append("SPACE release, 1/2/3 flip FUEL/SPARK/BOOST")
	lines.append("L lift, T lean, J jitter, Q/E lean body")
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
	lines.append(_diag_zone_line())
	lines.append("WHEEL %+d DEG JIT %s" % [int(round(rad_to_deg(wheel_angle))), "ON" if jitter_on else "OFF"])
	return "\n".join(lines)


func _diag_zone_line() -> String:
	# Fix Pass 10 (Item 0): per-control IN-ZONE readout - for
	# each dash control, which hand (L / R / B = both / - =
	# neither) currently sits inside its activation zone, by
	# the production _dash_ctl_near. Run 10's forensics had to
	# be reconstructed from a whole video; with this line the
	# owner's next capture states outright whether a dead
	# lever is a dead CHANNEL (grip reads 0.00 above) or a
	# hand that never entered the zone.
	var short: Dictionary = {"switch0": "FUEL", "switch1": "SPARK",
		"switch2": "BOOST", "restart": "RST", "lean": "LEAN", "track": "TRK"}
	var near_l: int = _dash_ctl_near(_hand_pos("L"))
	var near_r: int = _dash_ctl_near(_hand_pos("R"))
	var tags: Array[String] = []
	for i: int in dash_ctl_nodes.size():
		var who: String = "-"
		if near_l == i and near_r == i:
			who = "B"
		elif near_l == i:
			who = "L"
		elif near_r == i:
			who = "R"
		tags.append("%s:%s" % [String(short.get(dash_ctl_kinds[i], "?")), who])
	return "ZONE " + " ".join(tags)


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
	# Fix Pass 8 (Item 0): under test_mode the smoke may pose
	# the hands synthetically (see test_hand_pos) so the
	# production grip path - edge detection, segment proximity,
	# activation - runs headless. Inert in the shipped game.
	if test_mode and test_hand_set:
		return test_hand_pos[hand]
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
		if _btn_edge("r_stick_click", _input_bool(rc, &"primary_click")):
			_toggle_jitter()
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
		KEY_J:
			_toggle_jitter()
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


func _toggle_jitter() -> void:
	jitter_on = not jitter_on


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
	# Fix Pass 8 (Item 0): test_mode substitutes the synthetic
	# grip level for the controller's channels, so the edge /
	# proximity / activation logic below is the production code
	# running on posed inputs. The XR reads above are what the
	# headset path uses; they are API-guarded and were
	# live-verified in runs 4-8 - what no headless run can
	# reproduce is a runtime delivering stuck channel VALUES.
	if test_mode:
		grip_v = float(test_grip[hand])
		grip_click = false
		grip_force = 0.0
	diag_grip[hand] = grip_v
	diag_click[hand] = grip_click
	diag_force[hand] = grip_force
	var now: bool = grip_v > 0.65 or grip_click or grip_force > 0.65
	var near_wheel: bool = _hand_pos(hand).distance_to(car.global_transform * _wheel_hub_local()) < WHEEL_GRAB_RADIUS
	# Fix Pass 9 (Item 1): LEVEL-based dash activation. Chris, run 9:
	# "I press grip near a lever, the panel says HOLD, levers don't
	# move" - the flip used to fire only on a fresh grip EDGE while
	# the hand was already in the zone, and a human hand squeezes
	# first and reaches second, spending the edge in empty air (the
	# HOLD readout proved grip arrived and the hand was placed).
	# Now a gripping hand inside a control's zone fires it ONCE
	# per continuous grab-and-zone entry (dash_ctl_fired); the
	# latch re-arms when the grip releases or the hand leaves
	# every zone, so a held grip sweeping from one control to the
	# next fires each on entry - squeeze-and-touch IS the gesture.
	var ctl_now: int = _dash_ctl_near(_hand_pos(hand)) if now else -1
	if ctl_now >= 0 and int(dash_ctl_fired[hand]) != ctl_now:
		dash_ctl_fired[hand] = ctl_now
		_activate_dash_ctl(dash_ctl_kinds[ctl_now])
	elif ctl_now < 0:
		dash_ctl_fired[hand] = -1
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
	# Fix Pass 10 (Item 0): the NEAREST control inside the radius
	# wins, not the first listed. The zones just touch at the
	# switch row's midpoints (controls 0.30 m apart, radius
	# 0.15 m), and first-match made the winner there an accident
	# of list order - with buttons in the row (restart sits
	# 0.17 m from the Fix Pass 10 track button), an in-between
	# hand must fire the control it is actually closest to,
	# never a neighbour it merely also grazes.
	var best: int = -1
	var best_d: float = DASH_CTL_RADIUS
	for i: int in dash_ctl_nodes.size():
		var seg: Array[Vector3] = _dash_ctl_segment(i)
		var d: float = _seg_point_dist(seg[0], seg[1], world_pos)
		if d < best_d:
			best_d = d
			best = i
	return best


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
	# Fix Pass 9: free-heading state starts aligned to the drop
	# section, at rest (the release re-derives it anyway).
	vel2 = Vector2.ZERO
	yaw_rate = 0.0
	edge_roll = 0.0
	car_heading = _frame_yaw(_frame_at(2.0)["tan"])
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
	air_load_frames = 0
	# Fix Pass 9: per-wheel support back to fully held.
	sup_rise = [0.0, 0.0, 0.0, 0.0]
	sup_ok = [true, true, true, true]
	sup_s = [0.0, 0.0, 0.0, 0.0]
	edge_roll = 0.0


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
	lat_vel = 0.0
	vel2 = Vector2.ZERO
	yaw_rate = 0.0
	edge_roll = 0.0
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
	# Fix Pass 9: the released car flies and lands under the
	# heading it HUNG with - aligned to the drop section (the
	# hang orients the car to the section; see _orient_car_hang).
	# The horizontal air velocity becomes the velocity vector.
	car_heading = _frame_yaw(f)
	yaw_rate = 0.0
	vel2 = Vector2(air_vel.x, air_vel.z)
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
	if step_log_on:
		_step_log_row()


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
	# Fix Pass 9 (Item 2): THE FREE-HEADING MODEL. This replaces
	# the spine-slaved model whole: up to Fix Pass 8 the car's
	# heading was welded to the track frame and "steering" only
	# deflected a lateral offset, which is why Chris's run-9
	# verdict was "I don't really have a sensation of the car
	# turning, it more slides... like the Autopia ride, riding a
	# rail." Now the car owns its heading and its velocity:
	# - the grabbed wheel sets a front-wheel angle; the yaw rate
	#   follows the bicycle relation through a first-order lag
	#   (yaw inertia), with lock authority scaled down by speed;
	# - velocity is its own world vector, decomposed against the
	#   heading each frame into forward (vf) and lateral (vl);
	# - tire grip bleeds vl toward zero at up to the lateral grip
	#   limit (the lean experiment's multiplier scales it), and
	#   the bank's gravity feeds vl along the frame side;
	# - whatever lateral velocity survives IS the slip:
	#   slip_state derives from it, so the skid audio sings on
	#   real sliding. Demanding more yaw than the tires can
	#   curve the velocity through leaves the car sliding wide,
	#   recoverable by centring the wheel or counter-steering.
	# The track frame keeps only its remaining jobs: road
	# height/bank under the wheels (in _update_suspension),
	# slope gravity, gap/fall checks, and lap logic. car_s and
	# car_lat are re-derived from the car's world position by
	# projection at the end of the step - never integrated.
	# Suspension air entry (Fix Pass 5/8, unchanged rule): the
	# load decision was made in _update_suspension last frame.
	if bounce_pending:
		bounce_pending = false
		_sync_vel2_from_speed_lat()
		_enter_air(false, bounce_vy)
		return
	var fr: Dictionary = _frame_at(car_s)
	var tanv: Vector3 = fr["tan"]
	# Decompose the velocity against the CURRENT heading.
	var f0: Vector3 = _heading_fwd()
	var r0: Vector3 = _heading_right()
	var vf: float = vel2.dot(Vector2(f0.x, f0.z))
	var vl: float = vel2.dot(Vector2(r0.x, r0.z))
	# Longitudinal: engine / brake / boost / drag / slope gravity -
	# the same terms the slaved model had, applied to vf.
	var accel: float = in_throttle * 10.0
	accel -= in_brake * 14.0
	accel -= vf * 0.10
	accel += -GRAV * tanv.y * 0.85 # slope gravity: climbs bite, descents push
	if in_boost and boost_meter > 0.0 and in_throttle > 0.05:
		accel += 9.0
		boost_meter = maxf(boost_meter - 30.0 * delta, 0.0)
	vf = clampf(vf + accel * delta, -6.0, 34.0)
	if in_brake > 0.05 and vf < 0.5 and vf > -0.5:
		vf = 0.0
	# Steering: wheel -> front-wheel angle -> yaw rate target,
	# chased through the inertia lag. Bicycle kinematics give
	# omega ~ vf, so at a standstill the target is exactly zero -
	# no rotation on the spot. SIGN: a positive wheel angle is
	# clockwise-from-the-driver = steer RIGHT (the grab math's
	# convention, and the old model's positive lateral velocity);
	# with forward = (-sin h, -cos h) a right turn DECREASES the
	# heading, hence the negated bicycle term.
	var steer: float = clampf(wheel_angle / PI, -1.0, 1.0)
	var lock_scale: float = 1.0 / (1.0 + (vf / STEER_FALLOFF_SPEED) * (vf / STEER_FALLOFF_SPEED))
	var front_angle: float = steer * MAX_LOCK_RAD * lock_scale
	var omega_target: float = clampf(-vf / WHEELBASE * tan(front_angle), -MAX_YAW_RATE, MAX_YAW_RATE)
	yaw_rate = lerpf(yaw_rate, omega_target, clampf(delta / YAW_TAU, 0.0, 1.0))
	car_heading = wrapf(car_heading + yaw_rate * delta, -PI, PI)
	# The accelerated velocity, decomposed against the NEW
	# heading: turning the car under a fixed velocity vector is
	# what creates lateral velocity in the first place.
	var v_acc: Vector3 = f0 * vf + r0 * vl
	var f1: Vector3 = _heading_fwd()
	var r1: Vector3 = _heading_right()
	vf = v_acc.dot(f1)
	vl = v_acc.dot(r1)
	var side_align: float = Vector3(fr["side"]).dot(r1)
	vl += -GRAV * sin(float(fr["bank"])) * side_align * delta
	grip_mult = _grip_for(yaw_rate / maxf(absf(vf), 2.0))
	var bleed: float = clampf(-GRIP_BITE_RATE * vl * grip_mult,
		-GRIP_LAT_ACCEL * grip_mult, GRIP_LAT_ACCEL * grip_mult)
	vl += bleed * delta
	# Mild scrub: sliding sideways scrubs forward speed.
	vf -= vf * 0.015 * absf(vl) * delta
	# Fix Pass 9: the tire slip state is the REAL lateral velocity
	# that survived the grip bleed (Fix Pass 6 read a cornering-
	# load proxy). The skid audio consumes this unchanged.
	slip_state = clampf((absf(vl) - AUDIO_SLIP_ONSET) / AUDIO_SLIP_SPAN, 0.0, 1.0)
	speed = vf
	lat_vel = vl
	vel2 = Vector2(f1.x, f1.z) * vf + Vector2(r1.x, r1.z) * vl
	# Integrate the world position; height comes from placement.
	car.global_position += Vector3(vel2.x, 0.0, vel2.y) * delta
	# Derive (s, lat) from where the car actually is now.
	var pr: Array = _project_to_spine(car.global_position, car_s)
	car_s = float(pr[0])
	car_lat = float(pr[1])
	var fr_now: Dictionary = _frame_at(car_s)
	# Entering the gap -> ballistic (velocity vector carries over).
	if bool(fr_now["gap"]) and vf > 0.0:
		_enter_air(true, 0.0)
		return
	# Off the side -> fall, but only once support is truly gone:
	# the centre overshoot past which even the innermost wheel
	# has run off the shoulder (Item 2 scope addition). Inside
	# that line the straddle state in _update_suspension holds
	# the car up - wobbling, but held.
	if absf(car_lat) > HALF_WIDTH + EDGE_FALL_OVERSHOOT:
		_enter_air(false, 0.0)
		return
	if car_s >= track_len - 0.5:
		mode = MODE_DONE
		finished_time = race_time
		state_label.text = "FINISH!"
	# place the car
	_place_car_on_track(fr_now)


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
	# Fix Pass 9: the orientation is the car's OWN heading now.
	# The frame's pitch (slope) and bank are re-expressed in the
	# car's axes through the heading-vs-frame angle psi (driving
	# across a slope pitches AND rolls you - the straddle wobble
	# and the angled-landing tilt both live here), and the
	# lagged edge roll from the per-wheel support is added.
	# pitch_extra stays OFF this basis - it rides on car_body
	# (the spring pitch visual), exactly as before.
	var pos: Vector3 = fr["pos"] + fr["side"] * car_lat + fr["up"] * (CLEARANCE + heave_off)
	var psi: float = wrapf(car_heading - _frame_yaw(fr["tan"]), -PI, PI)
	var slope_ang: float = asin(clampf(Vector3(fr["tan"]).y, -1.0, 1.0))
	var bank: float = float(fr["bank"])
	var pitch_a: float = slope_ang * cos(psi) - bank * sin(psi)
	var roll_a: float = bank * cos(psi) + slope_ang * sin(psi) + edge_roll
	var b := Basis(Vector3.UP, car_heading)
	b = b.rotated(b.x, pitch_a)
	b = b.rotated(b.z, roll_a)
	car.global_transform = Transform3D(b, pos)


func _update_air(delta: float) -> void:
	air_time += delta
	air_vel.y -= GRAV * delta
	var pos: Vector3 = car.global_position + air_vel * delta
	car.global_position = pos
	# Fix Pass 9: the track s estimate comes from projecting the
	# car's ACTUAL position (the old forward-motion integration
	# assumed the velocity followed the spine - under the
	# free-heading model a sliding car leaves at an angle). The
	# heading is deliberately untouched here: no yaw authority
	# while airborne.
	var pr: Array = _project_to_spine(pos, air_s_est)
	air_s_est = float(pr[0])
	var fr: Dictionary = _frame_at(air_s_est)
	var rel: Vector3 = pos - fr["pos"]
	var lat: float = rel.dot(fr["side"])
	var h: float = rel.dot(fr["up"])
	# Fix Pass 9: the landing window widens to the straddle
	# shoulder - touching down with wheels on the shoulder is a
	# landing (the support model takes it from there), not a miss.
	if not bool(fr["gap"]) and h <= CLEARANCE + 0.05 and h > -2.2 and absf(lat) <= HALF_WIDTH + EDGE_FALL_OVERSHOOT and air_vel.y < 2.5:
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
	# Fix Pass 9: the velocity vector lands with the car - the
	# horizontal air velocity becomes vel2 under the (frozen)
	# heading, keeping its lateral part, with the old minimum
	# forward guarantee (a dead drop still rolls away at 4 m/s
	# along the heading). (s, lat) are then re-derived from the
	# car's actual position by wide projection.
	vel2 = Vector2(air_vel.x, air_vel.z)
	var f2: Vector3 = _heading_fwd()
	var r2: Vector3 = _heading_right()
	var vf_land: float = vel2.dot(Vector2(f2.x, f2.z))
	if vf_land < 4.0:
		vel2 += Vector2(f2.x, f2.z) * (4.0 - vf_land)
		vf_land = 4.0
	elif vf_land > 34.0:
		vel2 -= Vector2(f2.x, f2.z) * (vf_land - 34.0)
		vf_land = 34.0
	speed = vf_land
	lat_vel = vel2.dot(Vector2(r2.x, r2.z))
	yaw_rate = 0.0
	var pr: Array = _project_to_spine(car.global_position, air_s_est, true)
	car_s = float(pr[0])
	car_lat = float(pr[1])
	mode = MODE_DRIVE
	was_airborne = false
	_place_car_on_track(_frame_at(car_s))


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
		# Fix Pass 9 (Item 2): PER-WHEEL support sampling. Each
		# wheel's world position (from the car's own pose - the
		# heading decides where the wheels actually are) projects
		# to the spine, and the wheel's road rise is measured
		# against the centre frame exactly as the old per-axle
		# geom was. The axles' geom/loads/targets are the means of
		# their wheels, so on a centred, aligned car this reduces
		# to the Fix Pass 5/7/8 model unchanged.
		# THE STRADDLE (Item 2 scope addition, Crammond's own
		# mechanism - Car Behaviour.cpp, CalculateIfCarOffRoad):
		# a wheel past the ribbon edge rides an invisible sloping
		# shoulder - its support height falls EDGE_SLOPE per metre
		# of overshoot - until EDGE_CUTOFF (3/4 of the wheel track
		# past the edge), where it is fully unsupported: target =
		# full droop, and its support line hangs below the
		# shoulder's end, so the body rolls toward the dead side
		# (the wobble) through the lagged edge_roll in placement.
		# Steering back restores the support: the save.
		var car_pos: Vector3 = car.global_position
		var hf: Vector3 = _heading_fwd()
		var hr: Vector3 = _heading_right()
		var up_c: Vector3 = fr["up"]
		var pos_c: Vector3 = fr["pos"]
		for wi: int in 4:
			var wl: Vector2 = WHEEL_LOCALS[wi]
			var wp: Vector3 = car_pos + hr * wl.x - hf * wl.y
			var pr: Array = _project_to_spine(wp, car_s)
			sup_s[wi] = float(pr[0])
			var wlat: float = float(pr[1])
			var wfr: Dictionary = _frame_at(sup_s[wi])
			var rise: float = (Vector3(wfr["pos"]) - pos_c).dot(up_c)
			var over: float = absf(wlat) - HALF_WIDTH
			if over > EDGE_CUTOFF:
				sup_ok[wi] = false
				sup_rise[wi] = rise - EDGE_CUTOFF * EDGE_SLOPE - 0.30
			else:
				sup_ok[wi] = true
				sup_rise[wi] = rise - maxf(over, 0.0) * EDGE_SLOPE
		geom_f = (sup_rise[0] + sup_rise[1]) * 0.5
		geom_r = (sup_rise[2] + sup_rise[3]) * 0.5
		# Fix Pass 7 (Item 2): the suspension samples the QUANTISED
		# surface (see _elev_quantised). Swap only the ELEVATION
		# component of each axle's road rise - subtract the smooth
		# world-Y rise, add the quantised one - so the frame
		# projection (bank/pitch geometry) and every other reader
		# keep the smooth model, and the springs' own load/derivative
		# response turns the steps into tremble. Fix Pass 9: the
		# swap is sampled at each axle's mean WHEEL s (the slip
		# path never comes through here - it is the real lateral
		# velocity in _update_drive, untouched by quantisation).
		var s_f: float = (sup_s[0] + sup_s[1]) * 0.5
		var s_r: float = (sup_s[2] + sup_s[3]) * 0.5
		if jitter_on:
			var e_c: float = _elev_quantised(car_s)
			geom_f += (_elev_quantised(s_f) - e_c) - (_frame_at(s_f)["pos"].y - pos_c.y)
			geom_r += (_elev_quantised(s_r) - e_c) - (_frame_at(s_r)["pos"].y - pos_c.y)
		# Crest load: following the road over a crest needs downward
		# acceleration v^2 * kv; what gravity cannot supply unloads
		# the springs. Computed per axle from the road's own profile
		# (sampled at the axle's mean wheel s, as the geom is).
		var fr_f: Dictionary = _frame_at(s_f)
		var fr_r: Dictionary = _frame_at(s_r)
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
		# Per-wheel targets: a supported wheel asks for the road's
		# rise under it (its OWN rise now, not the axle mean - a
		# straddling wheel's spring extends down the shoulder);
		# an unsupported wheel asks for full droop. The axle
		# spring integrates the mean, as before. The FP7 jitter
		# swap lives in geom_f/geom_r (the axle means), so each
		# wheel's target also carries its axle's jitter delta -
		# the difference between the swapped geom and the smooth
		# mean (identically zero with jitter OFF).
		var jit_f: float = geom_f - (sup_rise[0] + sup_rise[1]) * 0.5
		var jit_r: float = geom_r - (sup_rise[2] + sup_rise[3]) * 0.5
		var tw: Array[float] = [0.0, 0.0, 0.0, 0.0]
		for wi2: int in 4:
			if sup_ok[wi2]:
				var ld: float = load_f if wi2 < 2 else load_r
				var tr: float = -transfer if wi2 < 2 else transfer
				var jd: float = jit_f if wi2 < 2 else jit_r
				tw[wi2] = clampf((SUSP_REST + sup_rise[wi2] + jd) * ld + tr, 0.0, SUSP_TRAVEL)
			else:
				tw[wi2] = 0.0
		var target_f: float = (tw[0] + tw[1]) * 0.5
		var target_r: float = (tw[2] + tw[3]) * 0.5
		_susp_integrate(target_f, target_r, delta)
		# The straddle wobble: body roll toward the side whose
		# support line sits lower, lagged so it wallows instead
		# of snapping. Zero whenever all four wheels are home.
		var rise_l: float = (sup_rise[0] + sup_rise[2]) * 0.5
		var rise_r: float = (sup_rise[1] + sup_rise[3]) * 0.5
		var er_target: float = atan2(rise_r - rise_l, WHEEL_TRACK_M)
		edge_roll = lerpf(edge_roll, er_target, clampf(EDGE_ROLL_LAG * delta, 0.0, 1.0))
		# Fix Pass 8 (Item 2): leaving the road is a LOAD decision,
		# the same rule for both honest ways it happens - this
		# REPLACES Fix Pass 5's peak-compression history gate,
		# which demanded stored energy that geometry-driven
		# unloading never has (the crest straight compressed -
		# 0.162 m peak, stage 8 - but never unloaded, because its
		# gentle rollers never drove the load to ~zero AND the
		# rebound route was gated on a deep hit first).
		# (1) GEOMETRY: the crest load factor is ~zero at BOTH
		# axles, sustained - the surface falls away faster than
		# gravity can pull the car after it (v^2*kv > g). No
		# history: load level + duration are the whole rule.
		# (2) REBOUND: the springs reach full droop still throwing
		# fast - stored energy leaving - but ONLY while the road
		# is fully supporting the car (load >= REBOUND_LOAD_FLOOR
		# at both axles). That load floor is the discriminator
		# against the climb-top bleed, and it is a mechanism, not
		# a history: measured on the bleed (34 m/s, stage-3
		# protocol) the load sits at 0.27 sustained while BOTH
		# springs sag to full droop, the rear still extending at
		# ~0.57 m/s as it chases its falling target - droop +
		# throw velocity alone cannot tell a bleed from a bounce.
		# What differs is who holds the car: at partial load the
		# road's geometry holds it (and only route (1), load
		# ~zero, can release it); at full load the springs hold
		# it, and their release is a genuine throw. A landing
		# rebound happens on flat/supporting road (load ~1), so
		# it keeps its air. Smoke stage 10a is the negative
		# control; stage 3 is the regression that found this.
		if load_f <= AIR_LOAD_EPS and load_r <= AIR_LOAD_EPS and speed > 8.0:
			air_load_frames += 1
		else:
			air_load_frames = 0
		if air_load_frames >= AIR_SUSTAIN_FRAMES:
			bounce_pending = true
			bounce_vy = 0.35
			air_load_frames = 0
		elif (c_f + c_r) * 0.5 <= 0.005 and cv_f + cv_r < REBOUND_THROW_VEL \
				and load_f >= REBOUND_LOAD_FLOOR and load_r >= REBOUND_LOAD_FLOOR:
			bounce_pending = true
			bounce_vy = clampf(-(cv_f + cv_r) * 0.55, 0.5, 2.6)
	elif mode == MODE_DONE:
		geom_f = 0.0
		geom_r = 0.0
		load_f = 1.0
		load_r = 1.0
		air_load_frames = 0
		edge_roll = lerpf(edge_roll, 0.0, clampf(EDGE_ROLL_LAG * delta, 0.0, 1.0))
		_susp_integrate(SUSP_REST, SUSP_REST, delta)
	else:
		# AIR / HANG: no road contact - springs extend to full droop
		# (the dangling car's wheels hang; the flying car's settle).
		geom_f = 0.0
		geom_r = 0.0
		load_f = 1.0
		load_r = 1.0
		air_load_frames = 0
		edge_roll = lerpf(edge_roll, 0.0, clampf(EDGE_ROLL_LAG * delta, 0.0, 1.0))
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

func _view_pitch_now() -> float:
	# The pitch the driver's eye inherits: the car's world pitch
	# (from its forward axis) plus the seat stack's pitch offsets
	# (ViewSpring's suspension pitch + the body spring's pitch).
	var fwd: Vector3 = -car.global_transform.basis.z
	var p: float = asin(clampf(fwd.y, -1.0, 1.0))
	if view_node != null:
		p += view_node.rotation.x
	if body_node != null:
		p += body_node.rotation.x
	return p


func _step_log_row() -> void:
	# Fix Pass 8 (Item 1): one instrumented-lap row per physics
	# frame (see the step_log_on declaration). s is the car's
	# path position in whatever mode is live.
	var now_us: int = Time.get_ticks_usec()
	var frame_us: int = 0
	if _step_last_us > 0:
		frame_us = now_us - _step_last_us
	_step_last_us = now_us
	var s_pos: float = car_s
	if mode == MODE_AIR:
		s_pos = air_s_est
	elif mode == MODE_HANG:
		s_pos = drop_target_s
	var vy_off: float = 0.0
	if view_node != null:
		vy_off = view_node.position.y
	# Columns: s, mode, view_y, view_pitch, frame_us, then the
	# pitch decomposition (frame pitch from the car's forward
	# axis; the suspension's pitch_extra), the mean spring
	# compression, and frame_y - the height the ROAD GEOMETRY
	# alone places the car at (frame position + lateral/bank
	# terms + clearance, without the spring heave) - so a step
	# in the table can be attributed to the sampled geometry,
	# the springs, or the seat stack by name. The springs and
	# the seat stack are integrators (continuous except at the
	# genuine events: _land's impulse, bottoming); the sampled
	# geometry is where steps can hide.
	var fwd2: Vector3 = -car.global_transform.basis.z
	var fr_l: Dictionary = _frame_at(s_pos)
	var frame_y: float = float(fr_l["pos"].y) \
		+ float(fr_l["side"].y) * car_lat + float(fr_l["up"].y) * CLEARANCE
	step_rows.append([s_pos, float(mode),
		car.global_position.y + vy_off - body_sink,
		_view_pitch_now(), float(frame_us),
		asin(clampf(fwd2.y, -1.0, 1.0)), pitch_extra,
		(c_f + c_r) * 0.5, frame_y])


func debug_warp_to_s(s: float) -> void:
	# Fix Pass 9: a warp now places the full free-heading state -
	# heading aligned to the frame, velocity along it, no yaw,
	# no slip - the same clean state the old model warped into.
	car_s = clampf(s, 0.0, track_len - 2.0)
	car_lat = 0.0
	lat_vel = 0.0
	speed = 14.0
	yaw_rate = 0.0
	edge_roll = 0.0
	var frw: Dictionary = _frame_at(car_s)
	car_heading = _frame_yaw(frw["tan"])
	vel2 = Vector2(frw["tan"].x, frw["tan"].z).normalized() * 14.0
	mode = MODE_DRIVE
	_place_car_on_track(frw)


func debug_pin_speed(v: float) -> void:
	# Fix Pass 9 test fixture: hold the car at speed v along its
	# own heading with zero slip - the free-heading replacement
	# for poking `speed` directly (the model now integrates
	# vel2, so a bare speed assignment would be overwritten by
	# the decomposition on the next frame). Yaw rate is left
	# alone: fixtures that pin per-frame on a straight (the
	# shelf, the climb-top control) still need their steering.
	speed = v
	lat_vel = 0.0
	var f2: Vector3 = _heading_fwd()
	vel2 = Vector2(f2.x, f2.z) * v


func debug_set_hang_dangle() -> void:
	if mode == MODE_HANG:
		hang_phase = "dangle"
		anchor_pos = anchor_target
		pivot_pos = anchor_pos


func debug_stage_landing(s: float, height: float, fwd_speed: float) -> void:
	# Fix Pass 5 render-proof staging: put the car ballistic above
	# the ribbon at s, falling - the production _update_air/_land
	# path (and its suspension impulse) does the rest.
	# Fix Pass 9: the landing is judged under the car's heading -
	# align it to the frame so the staged landing grades as before.
	var fr: Dictionary = _frame_at(s)
	mode = MODE_AIR
	air_from_gap = false
	air_time = 0.0
	air_s_est = s
	car_heading = _frame_yaw(fr["tan"])
	yaw_rate = 0.0
	air_vel = fr["tan"] * fwd_speed
	car.global_transform = Transform3D(
		Basis(fr["side"], fr["up"], -fr["tan"]),
		fr["pos"] + fr["up"] * (CLEARANCE + height))
