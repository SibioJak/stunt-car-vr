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
# Fix Pass 11 (Item 6) - THE RAKE. The owner, judging the
# Look Test: "what we're missing are big beefy tires at the
# rear that tilt the car up in the back." The car gets the
# Odd Rods dragster stance: rear tyres 1.38x the old radius
# and half again as wide, fronts slightly smaller than the
# old equal wheels. This is a deliberate deviation from
# Crammond's equal-wheel car, at the owner's direction.
# The stance is HONEST in the driving model, not a visual
# tilt: the per-axle radius enters the suspension's attach
# heights in _susp_integrate (the rear axle's ride height is
# raised by the radius difference), so the body pitch the
# springs derive - and the view spring reads - carries the
# rake: atan((0.47 - 0.30) / 3.0) = 3.24 deg nose-down at
# rest on flat road. The wheel CENTRES stay at the reference
# height in body space (their struts are unchanged); the
# radius difference lives in the tyre meshes and in the
# attach terms, which is what puts both contact patches on
# one plane in the raked pose (proven in the render proof's
# side-profile capture: both wheel bottoms level, body
# pitched). The (s, lat) support sampling is positional and
# radius-free by construction in this model - the radius's
# physical job here is the ride height, and that is where
# it enters.
const WHEEL_RAD_F: float = 0.30 # front tyre radius, m (was 0.34 all round)
const WHEEL_RAD_R: float = 0.47 # rear tyre radius, m (1.38x the old 0.34)
const WHEEL_RAD_REF: float = 0.34 # centre height the bookkeeping was tuned around
const WHEEL_WID_F: float = 0.24 # front tyre width, m (unchanged)
const WHEEL_WID_R: float = 0.36 # rear slick width, m (visibly wider)
# Fix Pass 10 (Item 3): the owner, run 10 - the road must be
# "wide enough for two cars to pass each other; it isn't." The
# 9.36 m Crammond proportion (6.0x the wheel track, Fix Pass 9)
# is superseded by an absolute: HALF_WIDTH 6.0 = 12.0 m full
# width everywhere. Everything derived from HALF_WIDTH
# (surface, skirts, edge strips, gantry, off-track / straddle /
# landing checks) follows from this one constant; stage 2f
# asserts it and reports the width in car bodies
# (debug_body_width_m: the body measures 1.80 m, so the road
# is 6.67 bodies wide - Crammond's own ratio was ~4.74).
const HALF_WIDTH: float = 6.0
# Fix Pass 12 (Item 4): the amber edge strips widened
# 0.36 -> 0.55 m. They are the road's far read: at 300-600 m
# a 0.36 m strip is ~1 px and the dash gaps erase it between
# samples; 0.55 m survives ~1.5x farther. Same colour, same
# dash rhythm, same 0.02 raise - only the width changed.
const EDGE_STRIP_W: float = 0.55
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
# --- Fix Pass 11 (Item 5): the speed envelope ---
# TOP_SPEED rises 34 -> 48 m/s (172.8 km/h on the dash's
# scale - the Crammond car showed ~171.6 at the top of its
# range; the coincidence is noted, not engineered). The
# engine/brake/drag terms are UNCHANGED (10 / 14 / 0.10), so
# the run up is the same curve reaching further.
const TOP_SPEED: float = 48.0
# Steering above the FP10 envelope: the falloff speed blends
# 26 -> 40 m/s across 24..40 m/s (smoothstep), so lock at 48
# is 0.410 instead of the old curve's 0.227 - present but
# not twitchy. At and below 24 m/s _lock_scale returns the
# FP10 expression VERBATIM (the owner's squirrely verdict is
# a <= 24 m/s property and stays numerically untouched).
const STEER_FALLOFF_HI: float = 40.0
const STEER_BLEND_LO: float = 24.0
const STEER_BLEND_HI: float = 40.0
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
# Fix Pass 11 (Item 1): the anchor rises +0.12 m and the hub rises
# +0.09 m with it (drop now 0.29 m). Run 11 verdict: from the old seat
# the road hid behind the nose stack, worst on descents. The raise is
# sightline geometry over the RAKED car (Item 6): the binding
# obstruction is the engine block's top-front edge; the render proof
# measures the nearest visible road from the live AABBs at the old
# and new heights and asserts the improvement, so the number lives
# there rather than in this comment. The driver trims +-SEAT_TRIM_MAX
# around this default from the cockpit seat levers (VTOL-style).
const EYE_ANCHOR: Vector3 = Vector3(0.0, 1.26, 0.05)
const WHEEL_HUB: Vector3 = Vector3(0.0, 0.97, -0.40)
# Fix Pass 11 (Item 1): the Look Test patch-2 yaw cone, ported.
# Automatic anchor applications bake the head's yaw into the seat
# correction only when the head sits within this cone of the car's
# forward; outside it they land translation only and the yaw waits
# for the head to enter the cone on a stable pose. An explicit
# recenter always bakes (see _apply_seat_anchor).
const ANCHOR_YAW_CONE_DEG: float = 25.0
const SEAT_TRIM_MAX: float = 0.15
const SEAT_TRIM_RATE: float = 0.30 # m/s while a seat lever is held
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
# Fix Pass 10 (Item 2) - PIVOT-DRIVEN FLIGHT. The Fix Pass 5 dip
# was a procedural hash schedule moving a virtual pivot offset;
# the brief retires it: the carrier (drone) now has real flight
# state - position (anchor_pos), velocity, measured acceleration
# - and flies an actual path: it brakes to a hover at the catch,
# retraces the road back to the drop point, and holds station
# over it. The pendulum integrates the pivot's MEASURED
# acceleration (lag under acceleration, overshoot on braking
# and turns, settle at station), the car's yaw seeks the
# carrier's yaw on a laggy spring (never rigid), and the dips
# survive as FLOWN manoeuvres: the carrier descends on a smooth
# profile and climbs back, so line tension, slack and the catch
# all follow from the carrier's real vertical acceleration.
const CARRIER_SPEED: float = 15.0 # m/s cruise (FP12 item 3: was 9.0)
const CARRIER_ACCEL: float = 9.0 # m/s^2 - flight accel/brake limit (FP12 item 3: was 6.0)
const CARRIER_YAW_RATE: float = 0.9 # rad/s the carrier turns at speed
# Fix Pass 12 (Item 3): extra clearance the carry's altitude
# profile holds over the highest intervening road surface -
# on top of the hang stack (HANG_LEN + HANG_CLEAR) the drop
# station itself uses. (0.8 as first shipped measured a
# 0.17 m graze on the staged s900 carry - the swinging car
# reaches metres past the anchor's column, where the road
# can stand higher than the profile's window maximum; the
# window widened to +-45 m in the same fix, and the margin
# went to 1.0.)
const CARRIER_ROUTE_CLEAR_M: float = 1.0
# Fix Pass 12 (Item 5): the air-recovery trigger's terms.
# Below-band dwell: how long the car must stay below the
# landing band, descending, before it counts as lost (a
# lower piece ahead re-opens the landing the moment h
# climbs back into the band). Failsafe: an absolute air-time
# ceiling no ballistic on this track can honestly reach -
# the longest genuine flight measured is 3.64 s.
const AIR_LOST_BELOW_T: float = 0.3
const AIR_FAILSAFE_T: float = 8.0
const ORIENT_YAW_K: float = 3.2 # car-facing seek spring (overshoots)
const ORIENT_YAW_DAMP: float = 2.0
const DIP_DUR: float = 1.6 # s, one flown dip
const DIP_SLACK_ACCEL: float = -5.5 # measured carrier accel (m/s^2) that slacks the lines
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
# Fix Pass 10 (Item 3): two tracks, one live set of arrays.
# track_data holds each track's Dictionary (arrays, length,
# closed flag, feature spans, scene root); _activate_track
# points the live arrays at one of them.
var track_data: Dictionary = {}
var active_track: String = ""
const RACE_LAPS: int = 3 # circuit race length (the ribbon is point-to-point)
# Fix Pass 10 (Item 4): the loop spur branches off the circuit's
# home straight at SPUR_ENTRY_S and merges back at SPUR_JOIN_S;
# the ring radius sets the loop-the-loop detach speed sqrt(g*R)
# ~= 10.4 m/s at the top.
const SPUR_ENTRY_S: float = 170.0
const SPUR_JOIN_S: float = 330.0
const SPUR_RING_R: float = 11.0
var lap_count: int = 0
# Fix Pass 10 (Item 4): loop-spur state - the spur is a branch
# surface off the circuit with its own arc parameter (spur_s);
# while on_spur, driving/suspension read the spur's frames.
var on_spur: bool = false
var spur_s: float = 0.0
var spur_lat: float = 0.0
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
var below_band_t: float = 0.0 # FP12 item 5: dwell below the landing band
var lost_lat_t: float = 0.0 # FP12 item 5: dwell out past the ribbon, below the exit plane
var air_exit_y: float = 0.0 # FP12 item 5: road height where this flight left the ground
var air_s_est: float = 0.0
var air_from_gap: bool = false
# Fix Pass 10 (Item 1): the s at which the car LEFT the road,
# recorded at air entry. The drone's drop may never be ahead of
# this - where the car ended up after flying/tumbling is not
# where it fell (a long flight past an obstacle it failed must
# not pay out progress). Read by _update_air's recovery call.
var air_start_s: float = 0.0
# Fix Pass 10 (Item 3 prep): the active track is a closed
# circuit (s wraps) or an open ribbon. Set by _set_track;
# the ribbon default keeps every Fix Pass <=9 code path as-is.
var track_closed: bool = false

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

# Dangle state: line slack, catch blend, and a lagged orientation
# direction (compliance - the car settles a beat behind the swing
# instead of being rigidly framed to the pivot).
# Fix Pass 10 (Item 2): pivot_pos IS the carrier's position now
# (anchor_pos - no procedural offset). The carrier's flight state:
var pivot_pos: Vector3 = Vector3.ZERO # the carrier's position (== anchor_pos)
var carrier_vel: Vector3 = Vector3.ZERO
var carrier_accel: Vector3 = Vector3.ZERO # measured, lightly filtered
var carrier_yaw: float = 0.0 # the carrier's own heading
var carrier_path: Array[Vector3] = [] # retrace waypoints for the carry
var carrier_wp: int = 0
# Fix Pass 11 (Item 3): time spent at the station waiting for
# the arrival yaw gate (bounded - see _step_carrier).
var station_wait_t: float = 0.0
var orient_yaw: float = 0.0 # the car's facing under the lines (springy)
var orient_yaw_v: float = 0.0
var dip_t: float = -1.0 # flown-dip progress; -1 = not dipping
var dip_depth: float = 0.0
var dip_timer: float = 2.0
var dip_seed: int = 0
# Test hooks (smoke only, same pattern as test_grip): inject a
# pivot acceleration / a yaw target to prove the pendulum and the
# facing seek answer the PIVOT, not a schedule.
var test_pivot_accel_on: bool = false
var test_pivot_accel: Vector3 = Vector3.ZERO
var test_yaw_target_on: bool = false
var test_yaw_target: float = 0.0
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
# Fix Pass 12 (Item 2): the two info BOARDS are hidden by
# default and toggled as a pair (right-controller B button /
# desktop Tab). Run 12: "Need to do something about the big
# panels, hard to see. Button calls them up, makes em go
# away." Session state only, never persisted. The mid-view
# state/prep banners are NOT panels and stay always-on.
var panels_visible: bool = false

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
# Fix Pass 11 (Item 1): yaw-cone state (ported from the Look Test).
# anchor_yaw_pending: an automatic application landed translation
# only; the yaw half is owed and lands when the head enters the
# cone. anchor_bake_yaw: the NEXT application is explicit (a
# recenter) and bakes the facing it finds.
var anchor_yaw_pending: bool = false
var anchor_bake_yaw: bool = false
# Fix Pass 11 (Item 1): seat trim in metres, the driver's offset
# from EYE_ANCHOR, clamped to +-SEAT_TRIM_MAX. Persisted in
# user://settings.cfg - NOTE: the game had NO settings/profile
# persistence before this pass (checked: no ConfigFile, no
# user:// writes anywhere); that one key is the whole file for
# now. Reported as a brief/code mismatch in the pass report.
var seat_trim: float = 0.0
# --- Fix Pass 11 (Item 4): the drop lever ---
# The recovery release is a big physical lever on the RIGHT
# pod, in the cockpit's lever-forward language: grab the
# upper shaft, pull it toward you through a real throw; past
# the DETENT the car lets go. Let go of the grip earlier and
# it springs back and nothing drops. Angles are the pivot's
# rotation.x (lever-local +Y is the shaft): rest leans
# forward, the pull sweeps it back toward the driver.
const DROP_LEVER_REST_RAD: float = -0.30
const DROP_LEVER_DETENT_RAD: float = 0.40
const DROP_LEVER_MAX_RAD: float = 0.65
const DROP_LEVER_GRAB_RADIUS: float = 0.16
const DROP_LEVER_SPRING_RATE: float = 3.5 # rad/s back to rest
var drop_lever_pivot: Node3D
var drop_lever_angle: float = DROP_LEVER_REST_RAD
var drop_lever_hand: String = "" # "" / "L" / "R" while gripped
var drop_lever_fired: bool = false # detent latch for this pull
var xr_iface: XRInterface # stored at rig build for haptics
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
	_load_settings()
	_build_environment()
	track_data["ribbon"] = _build_ribbon()
	track_data["circuit"] = _build_circuit()
	_build_car()
	_build_drone()
	_build_rig()
	_build_audio()
	_set_track("circuit") # Fix Pass 10 (Item 3): the mountain circuit is the default track
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
	xr_iface = xr_interface
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
		fallback_cam.position = _eye_anchor()
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
	# Fix Pass 12 (Item 4): cut to 0.00012. The run-12 "part of
	# the road is invisible till you're in it" was DIAGNOSED,
	# not guessed (ID-pass renders at staged stations): not
	# pop-in (the ribbon is one merged mesh per track part,
	# visibility ranges all zero), not the far plane (4000 m).
	# The ribbon IS on screen - washed out: at the dip/valley
	# sightlines 8.7-14.1% of ribbon pixels sat within 0.10 RGB
	# of their background band (vs 1.9-4.8% on straights),
	# because from there the visible ribbon is 0.6-2.5 km away
	# and the fog mixes the near-black surface most of the way
	# to the horizon colour, while the thin dashed edges alias
	# away. The density cut is sized to roughly halve the fog
	# factor at 1 km; the hills keep some haze, and at driving
	# distances (< 150 m) the change is negligible either way.
	# The edge strips widened with it (EDGE_STRIP_W).
	env.fog_density = 0.00012
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
# Fix Pass 10 (Item 3): generation writes into BUILD arrays,
# not the live ones - a finished track is a data Dictionary
# (see _finalize_track) and _activate_track points the live
# t_* arrays at it. Two tracks now exist (the test ribbon and
# the mountain circuit) and each keeps its own arrays.
var b_pts: Array[Vector3] = []
var b_tan: Array[Vector3] = []
var b_bank: Array[float] = []
var b_curv: Array[float] = []
var b_gap: Array[bool] = []


func _gen_append(is_gap: bool, curv: float) -> void:
	var hd := Vector3(-sin(_gen_yaw), 0.0, -cos(_gen_yaw))
	var tanv: Vector3 = (hd * cos(_gen_phi) + Vector3.UP * sin(_gen_phi)).normalized()
	b_pts.append(_gen_pos)
	b_tan.append(tanv)
	b_bank.append(_gen_bank)
	b_curv.append(curv)
	b_gap.append(is_gap)


func _gen_step(step_len: float, yaw_rate: float, phi_target: float, bank_target: float, is_gap: bool, phi_rate: float, bank_rate: float) -> void:
	_gen_phi = move_toward(_gen_phi, phi_target, phi_rate * step_len)
	_gen_bank = move_toward(_gen_bank, bank_target, bank_rate * step_len)
	_gen_yaw += yaw_rate * step_len
	var hd := Vector3(-sin(_gen_yaw), 0.0, -cos(_gen_yaw))
	var tanv: Vector3 = (hd * cos(_gen_phi) + Vector3.UP * sin(_gen_phi)).normalized()
	_gen_pos += tanv * step_len
	_gen_append(is_gap, yaw_rate)


func _walk(steps: int, yaw_rate: float, phi_target: float, bank_target: float, is_gap: bool, phi_rate: float = 0.006, bank_rate: float = 0.012) -> void:
	for i: int in steps:
		_gen_step(1.0, yaw_rate, phi_target, bank_target, is_gap, phi_rate, bank_rate)


func _walkf(steps_f: float, yaw_rate: float, phi_target: float, bank_target: float, is_gap: bool, phi_rate: float = 0.006, bank_rate: float = 0.012) -> void:
	# Fractional-length walk (the circuit solver's tail): whole
	# steps plus one partial step, so a section's length or
	# radius is a continuous variable the solver can trim.
	var whole: int = int(floor(steps_f))
	var frac: float = steps_f - float(whole)
	for i: int in whole:
		_gen_step(1.0, yaw_rate, phi_target, bank_target, is_gap, phi_rate, bank_rate)
	if frac > 0.001:
		_gen_step(frac, yaw_rate, phi_target, bank_target, is_gap, phi_rate, bank_rate)


func _build_ribbon() -> Dictionary:
	# The Fix Pass 1-9 test ribbon, generated exactly as before
	# (six-plus runs of verdicts compare against it) - now into
	# build arrays, and returned as a track data Dictionary.
	var root := Node3D.new()
	root.name = "TrackRibbon"
	add_child(root)
	b_pts = []
	b_tan = []
	b_bank = []
	b_curv = []
	b_gap = []
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
	gap_s0 = float(b_pts.size())
	_walk(14, 0.0, deg_to_rad(2.0), 0.0, true, 0.020) # THE GAP - no ribbon
	gap_s1 = float(b_pts.size())
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
	ext_s0 = float(b_pts.size() - 1)
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
	sweeper_s0 = float(b_pts.size())
	_walk(47, -deg_to_rad(90.0) / 47.0, 0.0, deg_to_rad(-34.0), false) # banked sweeper, mirrored
	sweeper_s1 = float(b_pts.size())
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
	stairs_s0 = float(b_pts.size() - 1)
	for step_i: int in 6: # descending staircase: drop, tread, drop...
		_walk(5, 0.0, deg_to_rad(-22.0), 0.0, false, 0.077)
		_walk(6, 0.0, 0.0, 0.0, false, 0.077)
	stairs_s1 = float(b_pts.size() - 1)
	_walk(30, 0.0, 0.0, 0.0, false, 0.020) # flat run to the second lip
	_walk(2, 0.0, deg_to_rad(10.0), 0.0, false, 0.012, 0.10) # second launch lip, shaped entry
	_walk(8, 0.0, deg_to_rad(10.0), 0.0, false, 0.034, 0.10) # second launch lip
	gap2_s0 = float(b_pts.size())
	_walk(14, 0.0, deg_to_rad(2.0), 0.0, true, 0.020) # THE SECOND GAP - same 14 m spec
	gap2_s1 = float(b_pts.size())
	_walk(40, 0.0, deg_to_rad(-3.4), 0.0, false, 0.020) # second landing straight
	_walk(90, 0.0, deg_to_rad(13.0), 0.0, false) # final climb
	_walk(200, 0.0, 0.0, 0.0, false) # long home straight to the new finish
	var feats: Dictionary = {
		"gap_s0": gap_s0, "gap_s1": gap_s1, "gap2_s0": gap2_s0, "gap2_s1": gap2_s1,
		"ext_s0": ext_s0, "sweeper_s0": sweeper_s0, "sweeper_s1": sweeper_s1,
		"stairs_s0": stairs_s0, "stairs_s1": stairs_s1}
	var d: Dictionary = _finalize_track(false, feats)
	d["root"] = root
	_activate_track(d)
	_build_track_meshes(d)
	return d


var _cir_start: Vector3 = Vector3.ZERO


func _build_circuit() -> Dictionary:
	# Fix Pass 10 (Item 3): THE MOUNTAIN CIRCUIT. A closed loop
	# built from the same generator vocabulary as the ribbon,
	# to the owner's geography: "huge tall ramps, massive dips,
	# big swinging curves, some straightaways." One signature
	# climb (+70 m), one massive dip (~50 m down to a valley and
	# back out), four long banked swinging curves (radii
	# 100-140 m, both directions), two straightaways >= 350 m,
	# the 14 m gap and the five-hump row carried over at their
	# FP7/FP8 shapes. Total heading change is exactly 360 deg
	# by construction (each curve's yaw rate is its total angle
	# over its step count); elevation and plan closure are
	# SOLVED on the tail (return-straight length / pitch and
	# the last curve's radius are continuous variables trimmed
	# by a Newton iteration, see _solve_circuit_tail).
	var root := Node3D.new()
	root.name = "TrackCircuit"
	add_child(root)
	b_pts = []
	b_tan = []
	b_bank = []
	b_curv = []
	b_gap = []
	_cir_start = Vector3(0.0, 60.0, 0.0)
	_gen_pos = _cir_start
	_gen_yaw = 0.0
	_gen_phi = 0.0
	_gen_bank = 0.0
	_gen_append(false, 0.0)
	var feats: Dictionary = {}
	var curves: Array = []
	# S1: home straight (spur entry/merge spans recorded for Item 4)
	_walk(380, 0.0, 0.0, 0.0, false)
	feats["home_len"] = 380.0
	feats["spur_entry_s"] = SPUR_ENTRY_S
	feats["spur_join_s"] = SPUR_JOIN_S
	# S2: curve A - left, the long opening sweeper (R~244),
	# tipping the lap westward and gently down toward the dip
	var a_s0: float = float(b_pts.size() - 1)
	_walk(340, deg_to_rad(80.0) / 340.0, deg_to_rad(-2.0), deg_to_rad(26.0), false)
	_walk(3, 0.0, deg_to_rad(-2.0), 0.0, false, 0.006, 0.03)
	_walk(17, 0.0, deg_to_rad(-2.0), 0.0, false, 0.006, 0.075)
	curves.append([a_s0, float(b_pts.size() - 1), 1.0, 340.0 / deg_to_rad(80.0)])
	# S3-S4: THE DIP - a long descent to a valley floor, then flat
	var dip_s0: float = float(b_pts.size() - 1)
	_walk(180, 0.0, deg_to_rad(-16.0), 0.0, false)
	_walk(90, 0.0, 0.0, 0.0, false)
	feats["dip_s0"] = dip_s0
	feats["dip_s1"] = float(b_pts.size() - 1)
	# S5: climb out of the valley
	_walk(140, 0.0, deg_to_rad(13.0), 0.0, false)
	# S6: mid straight (second >= 350 m straightaway)
	_walk(350, 0.0, deg_to_rad(2.0), 0.0, false)
	feats["mid_len"] = 350.0
	# S7: curve B - left HAIRPIN (R~108): the lap turns back
	# east for the climb side
	var b_s0: float = float(b_pts.size() - 1)
	_walk(340, deg_to_rad(180.0) / 340.0, deg_to_rad(3.0), deg_to_rad(26.0), false)
	_walk(3, 0.0, deg_to_rad(3.0), 0.0, false, 0.006, 0.03)
	_walk(17, 0.0, deg_to_rad(3.0), 0.0, false, 0.006, 0.075)
	curves.append([b_s0, float(b_pts.size() - 1), 1.0, 340.0 / deg_to_rad(180.0)])
	# S8: link
	_walk(35, 0.0, 0.0, 0.0, false)
	# S9: THE SIGNATURE CLIMB - 240 m at up to +17.5 deg (~+70 m)
	feats["climb_s0"] = float(b_pts.size() - 1)
	_walk(235, 0.0, deg_to_rad(17.5), 0.0, false)
	feats["climb_s1"] = float(b_pts.size() - 1)
	# S10: shelf, then the carried-over lip + 14 m gap + landing
	_walk(25, 0.0, 0.0, 0.0, false)
	_walk(2, 0.0, deg_to_rad(10.0), 0.0, false, 0.012, 0.10)
	_walk(8, 0.0, deg_to_rad(10.0), 0.0, false, 0.034, 0.10)
	feats["gap_s0"] = float(b_pts.size())
	_walk(14, 0.0, deg_to_rad(2.0), 0.0, true, 0.020)
	feats["gap_s1"] = float(b_pts.size())
	feats["gap2_s0"] = feats["gap_s0"]
	feats["gap2_s1"] = feats["gap_s1"]
	_walk(40, 0.0, deg_to_rad(-3.4), 0.0, false, 0.020)
	# S11: the five-hump row, carried over at FP8's shape on a
	# descending base (climb in +3, over the top to -19, out at
	# the -8 base - the same 22-degree sweep per hump)
	feats["ext_s0"] = float(b_pts.size() - 1)
	for hump: int in 5:
		_walk(13, 0.0, deg_to_rad(3.0), 0.0, false, 0.016)
		_walk(19, 0.0, deg_to_rad(-19.0), 0.0, false, 0.021)
		_walk(13, 0.0, deg_to_rad(-8.0), 0.0, false, 0.016)
	_walk(20, 0.0, deg_to_rad(-8.0), 0.0, false)
	feats["hump_s1"] = float(b_pts.size() - 1)
	# S12: curve C - right, the long return sweeper (R~236),
	# descending, setting the lap due south for the tail
	var c_s0: float = float(b_pts.size() - 1)
	_walk(330, -deg_to_rad(80.0) / 330.0, deg_to_rad(-7.0), deg_to_rad(-26.0), false)
	_walk(3, 0.0, deg_to_rad(-7.0), 0.0, false, 0.006, 0.03)
	_walk(17, 0.0, deg_to_rad(-7.0), 0.0, false, 0.006, 0.075)
	curves.append([c_s0, float(b_pts.size() - 1), -1.0, 330.0 / deg_to_rad(80.0)])
	feats["curves"] = curves
	feats["sweeper_s0"] = -1.0
	feats["sweeper_s1"] = -1.0
	feats["stairs_s0"] = -1.0
	feats["stairs_s1"] = -1.0
	# S13-S15: the solver tail (return straight -> curve D ->
	# curve E unwinding its bank onto the seam)
	var snap: Array = [_gen_pos, _gen_yaw, _gen_phi, _gen_bank,
		b_pts.size(), b_tan.size(), b_bank.size(), b_curv.size(), b_gap.size()]
	var sol: Array = _solve_circuit_tail(snap)
	feats["tail"] = [sol[0], sol[1], sol[2]]
	feats["closure_err_m"] = sol[3]
	var d: Dictionary = _finalize_track(true, feats)
	d["root"] = root
	_activate_track(d)
	_build_track_meshes(d)
	_build_spur(d)
	return d

func _build_spur(d: Dictionary) -> void:
	# Fix Pass 10 (Item 4): THE LOOP SPUR - a branch surface off
	# the circuit's home straight: diverge left, descend, run
	# in level, a full vertical ring (R = SPUR_RING_R), then a
	# Bezier exit merging back >= 120 m downstream. Geometry is
	# built as POSITIONS first (phases below), then tangents by
	# finite difference, sides by PARALLEL TRANSPORT (the
	# _frame_at tan x UP construction degenerates at the ring's
	# vertical tangents), and kv as the signed pitch rate about
	# the side axis - in the ring that is a constant -1/R, which
	# is what makes the suspension's physical load form give
	# the honest loop physics (see _update_suspension_spur).
	var pts: Array[Vector3] = []
	# Phase 1: diverge along the home straight, the centreline
	# easing from the road centre to 3.4 m left (outside).
	for i: int in range(0, 36):
		var fr1: Dictionary = _frame_at(SPUR_ENTRY_S + float(i))
		var u1: float = clampf(float(i) / 35.0, 0.0, 1.0)
		var lat1: float = -3.4 * (u1 * u1 * (3.0 - 2.0 * u1))
		pts.append(Vector3(fr1["pos"]) + Vector3(fr1["side"]) * lat1)
	# Phases 2-3: a SHORT local walk - turn left 45 deg while
	# descending at up to -16 deg, then level off at the base.
	# The walk is deliberately brief: every metre it spends
	# paralleling the straight is a metre stolen from the
	# exit leg, and a cramped exit kinks (measured: a 53 m
	# exit spiked to 23 deg/m at the ring junction; this
	# layout leaves the exit ~90 m to blend back).
	var pos: Vector3 = pts[pts.size() - 1]
	var dprev: Vector3 = (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized()
	var yaw: float = atan2(-dprev.x, -dprev.z)
	var phi: float = asin(clampf(dprev.y, -1.0, 1.0))
	for i2: int in 45:
		yaw += deg_to_rad(1.0)
		phi = move_toward(phi, deg_to_rad(-16.0), 0.006)
		var dir2 := Vector3(-sin(yaw) * cos(phi), sin(phi), -cos(yaw) * cos(phi))
		pos += dir2
		pts.append(pos)
	for i3: int in 12:
		phi = move_toward(phi, 0.0, 0.024)
		var dir3 := Vector3(-sin(yaw) * cos(phi), sin(phi), -cos(yaw) * cos(phi))
		pos += dir3
		pts.append(pos)
	# Phase 4: THE RING - exact circle samples in the vertical
	# plane of the base heading. First and last samples are the
	# base point; the exit continues from it.
	var base_b: Vector3 = pos
	var hhat := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var ring_s0: float = float(pts.size() - 1)
	for k: int in range(1, 70):
		var th: float = TAU * float(k) / 69.0
		pts.append(base_b + hhat * (SPUR_RING_R * sin(th)) + Vector3.UP * (SPUR_RING_R - SPUR_RING_R * cos(th)))
	# Phase 5: exit - a cubic Bezier in 3D from the ring base
	# to the merge point on the home straight (2 m left of the
	# centreline), arc-length resampled at ~1 m.
	var frm: Dictionary = _frame_at(SPUR_JOIN_S)
	var m_pt: Vector3 = Vector3(frm["pos"]) + Vector3(frm["side"]) * -2.0
	var m_tan: Vector3 = frm["tan"]
	var chord: float = base_b.distance_to(m_pt)
	# Long entry control, shorter exit control: the exit must
	# leave the ring base along the ring's own heading and do
	# its turning mid-leg, not in a curvature spike at B.
	var c1: Vector3 = base_b + hhat * clampf(chord * 0.55, 25.0, 110.0)
	var c2: Vector3 = m_pt - m_tan * clampf(chord * 0.30, 15.0, 80.0)
	var raw: Array[Vector3] = []
	for j: int in 201:
		var t5: float = float(j) / 200.0
		var a5: Vector3 = base_b.lerp(c1, t5)
		var b5: Vector3 = c1.lerp(c2, t5)
		var cc5: Vector3 = c2.lerp(m_pt, t5)
		raw.append(a5.lerp(b5, t5).lerp(b5.lerp(cc5, t5), t5))
	var acc: float = 0.0
	for j2: int in range(1, raw.size()):
		acc += raw[j2].distance_to(raw[j2 - 1])
		if acc >= 1.0:
			pts.append(raw[j2])
			acc = 0.0
	if pts[pts.size() - 1].distance_to(m_pt) > 0.01:
		pts.append(m_pt)
	# Two light smoothing passes over the positions (the main
	# generator's own join medicine - see _frame_at's note):
	# the phase joins otherwise concentrate their turning
	# into 20+ deg/m curvature spikes. The first/last two
	# samples stay exact (entry and merge are surveyed points).
	for sp_pass: int in 2:
		var sm: Array[Vector3] = pts.duplicate()
		for i5: int in range(2, pts.size() - 2):
			sm[i5] = pts[i5 - 1] * 0.25 + pts[i5] * 0.5 + pts[i5 + 1] * 0.25
		pts = sm
	# Tangents: centred finite differences of the positions.
	var n: int = pts.size()
	var tans: Array[Vector3] = []
	for i6: int in n:
		var pa: Vector3 = pts[maxi(i6 - 1, 0)]
		var pb: Vector3 = pts[mini(i6 + 1, n - 1)]
		tans.append((pb - pa).normalized())
	# Sides: parallel transport from the entry frame's side -
	# carry the side forward, re-orthogonalising against each
	# new tangent. This stays well-defined through the ring's
	# vertical tangents, where tan x UP collapses.
	var sides: Array[Vector3] = []
	var sd: Vector3 = Vector3(_frame_at(SPUR_ENTRY_S)["side"])
	for i7: int in n:
		sd = (sd - tans[i7] * sd.dot(tans[i7])).normalized()
		sides.append(sd)
	# kv: minus the signed pitch rate about the side axis
	# (centred), so a crest reads positive and the ring reads
	# a constant -1/R, exactly the main track's convention.
	var kvs: Array[float] = []
	for i8: int in n:
		var ia: int = maxi(i8 - 1, 0)
		var ib: int = mini(i8 + 1, n - 1)
		var cr: Vector3 = tans[ia].cross(tans[ib])
		var ang: float = atan2(cr.dot(sides[i8]), clampf(tans[ia].dot(tans[ib]), -1.0, 1.0))
		var ds: float = maxf(pts[ib].distance_to(pts[ia]), 0.05)
		kvs.append(-ang / ds)
	# Cumulative arc length (samples are ~1 m; the ring steps
	# are 2*pi*R/69 = 1.002 m).
	var cum: Array[float] = [0.0]
	for i9: int in range(1, n):
		cum.append(cum[i9 - 1] + pts[i9].distance_to(pts[i9 - 1]))
	d["spur"] = {"pts": pts, "tan": tans, "side": sides, "kv": kvs,
		"cum": cum, "len": cum[n - 1], "ring_s0": ring_s0,
		"ring_s1": ring_s0 + TAU * SPUR_RING_R}
	# Meshes: the same box-section treatment as the tracks,
	# parented to the circuit root, plus stilts to the desert.
	var root: Node3D = d["root"]
	var sp: Dictionary = d["spur"]
	var surf_pos := PackedVector3Array()
	var surf_nrm := PackedVector3Array()
	var surf_col := PackedColorArray()
	var skirt_pos := PackedVector3Array()
	var skirt_nrm := PackedVector3Array()
	var skirt_col := PackedColorArray()
	var edge_pos := PackedVector3Array()
	var edge_nrm := PackedVector3Array()
	var edge_col := PackedColorArray()
	var surf_c := Color(0.07, 0.07, 0.09)
	var skirt_c := Color(1.0, 0.5, 0.05)
	var bot_c := Color(0.55, 0.27, 0.03)
	var edge_c := Color(1.0, 0.72, 0.10)
	for i10: int in range(0, n - 1):
		var p0: Vector3 = pts[i10]
		var p1: Vector3 = pts[i10 + 1]
		var s0: Vector3 = sides[i10]
		var s1: Vector3 = sides[i10 + 1]
		var u0: Vector3 = s0.cross(tans[i10]).normalized()
		var u1: Vector3 = s1.cross(tans[i10 + 1]).normalized()
		var l0: Vector3 = p0 - s0 * HALF_WIDTH
		var r0: Vector3 = p0 + s0 * HALF_WIDTH
		var l1: Vector3 = p1 - s1 * HALF_WIDTH
		var r1: Vector3 = p1 + s1 * HALF_WIDTH
		var bl0: Vector3 = l0 - u0 * RIBBON_DEPTH
		var br0: Vector3 = r0 - u0 * RIBBON_DEPTH
		var bl1: Vector3 = l1 - u1 * RIBBON_DEPTH
		var br1: Vector3 = r1 - u1 * RIBBON_DEPTH
		var up_avg: Vector3 = (u0 + u1) * 0.5
		var side_avg: Vector3 = (s0 + s1) * 0.5
		_add_quad(surf_pos, surf_nrm, surf_col, l0, r0, r1, l1, up_avg, surf_c)
		_add_quad(skirt_pos, skirt_nrm, skirt_col, l0, l1, bl1, bl0, -side_avg, skirt_c)
		_add_quad(skirt_pos, skirt_nrm, skirt_col, r1, r0, br0, br1, side_avg, skirt_c)
		_add_quad(skirt_pos, skirt_nrm, skirt_col, bl1, br1, br0, bl0, -up_avg, bot_c)
		# Fix Pass 11 (Item 5): the edge strips are DASHED
		# (3 m on / 2 m off) - optic flow for the raised top
		# speed; a continuous strip on a flat surface gives the
		# eye nothing temporal to measure speed against.
		if i10 % 5 < 3:
			_add_quad(edge_pos, edge_nrm, edge_col,
				l0 + u0 * 0.02, l0 + s0 * 0.36 + u0 * 0.02, l1 + s1 * 0.36 + u1 * 0.02, l1 + u1 * 0.02,
				up_avg, edge_c)
			_add_quad(edge_pos, edge_nrm, edge_col,
				r0 + u0 * 0.02, r0 - s0 * 0.36 + u0 * 0.02, r1 - s1 * 0.36 + u1 * 0.02, r1 + u1 * 0.02,
				up_avg, edge_c)
		if i10 % 12 == 0:
			var tp: Vector3 = p0 + s0 * 0.3
			var bp: Vector3 = Vector3(tp.x, -30.0, tp.z)
			_add_quad(skirt_pos, skirt_nrm, skirt_col,
				p0 - s0 * 0.3, tp, bp, Vector3(p0.x - s0.x * 0.3, -30.0, p0.z - s0.z * 0.3),
				tans[i10], bot_c)
	_add_mesh(surf_pos, surf_nrm, surf_col, "SpurSurface", false, root)
	_add_mesh(skirt_pos, skirt_nrm, skirt_col, "SpurSkirt", false, root)
	_add_mesh(edge_pos, edge_nrm, edge_col, "SpurEdges", true, root)


func _spur_frame_at(s: float) -> Dictionary:
	# A frame on the spur at arc s: lerped over the spur's own
	# samples (positions are ~1 m apart; cum[] maps arc to
	# index). Returns the same key set _frame_at does.
	var sp: Dictionary = track_data["circuit"]["spur"]
	var cum: Array = sp["cum"]
	var sc: float = clampf(s, 0.0, float(sp["len"]))
	var i0: int = 0
	while i0 < cum.size() - 2 and float(cum[i0 + 1]) < sc:
		i0 += 1
	var seg: float = maxf(float(cum[i0 + 1]) - float(cum[i0]), 0.001)
	var fr: float = clampf((sc - float(cum[i0])) / seg, 0.0, 1.0)
	var pts: Array = sp["pts"]
	var tans: Array = sp["tan"]
	var sides: Array = sp["side"]
	var kvs: Array = sp["kv"]
	var pos: Vector3 = Vector3(pts[i0]).lerp(Vector3(pts[i0 + 1]), fr)
	var tanv: Vector3 = Vector3(tans[i0]).lerp(Vector3(tans[i0 + 1]), fr).normalized()
	var side: Vector3 = Vector3(sides[i0]).lerp(Vector3(sides[i0 + 1]), fr).normalized()
	var upv: Vector3 = side.cross(tanv).normalized()
	return {"pos": pos, "tan": tanv, "side": side, "up": upv,
		"bank": 0.0, "kv": lerpf(float(kvs[i0]), float(kvs[i0 + 1]), fr),
		"gap": false}


func _project_to_spur(pos: Vector3, hint_s: float) -> Array:
	# [s, lat, centreline distance] from the spur samples near
	# the hint - a windowed search like _project_to_spine.
	var sp: Dictionary = track_data["circuit"]["spur"]
	var pts: Array = sp["pts"]
	var cum: Array = sp["cum"]
	var sides: Array = sp["side"]
	var ci: int = 0
	while ci < cum.size() - 1 and float(cum[ci]) < hint_s:
		ci += 1
	var best: int = ci
	var best_d2: float = 1e18
	for i: int in range(maxi(ci - 30, 0), mini(ci + 31, pts.size())):
		var d2: float = pos.distance_squared_to(pts[i])
		if d2 < best_d2:
			best_d2 = d2
			best = i
	var lat: float = (pos - Vector3(pts[best])).dot(Vector3(sides[best]))
	return [float(cum[best]), lat, sqrt(best_d2)]


func _project_wide_s(pos: Vector3) -> float:
	# Whole-track nearest sample (coarse then refined) - used
	# when a car leaves the spur and the drone needs a main-
	# track fall origin with no trustworthy hint.
	var best: int = 0
	var best_d2: float = 1e18
	var i: int = 0
	while i < t_pts.size():
		var d2: float = pos.distance_squared_to(t_pts[i])
		if d2 < best_d2:
			best_d2 = d2
			best = i
		i += 10
	for j: int in range(maxi(best - 10, 0), mini(best + 11, t_pts.size())):
		var d2b: float = pos.distance_squared_to(t_pts[j])
		if d2b < best_d2:
			best_d2 = d2b
			best = j
	return float(best)


func _spur_frame_yaw(fr: Dictionary) -> float:
	# The spur frame's heading, derived from its SIDE vector:
	# side = (cos yaw, 0, -sin yaw) in plan, and the side is
	# parallel-transported - constant through the ring, where
	# the tangent's own plan projection degenerates (a
	# vertical tangent has no plan heading, and atan2 of the
	# near-zero projection flips 180 deg mid-loop).
	var sd: Vector3 = fr["side"]
	return atan2(-sd.z, sd.x)


func _place_car_on_spur(fr: Dictionary) -> void:
	# Placement on the spur: the frame's own basis (side, up,
	# -tan) carries the car through the ring's full rotation;
	# the driver's heading offset yaws around the frame's up,
	# and the lagged edge roll rides on top, exactly the roles
	# they play in _place_car_on_track.
	var pos: Vector3 = Vector3(fr["pos"]) + Vector3(fr["side"]) * spur_lat 		+ Vector3(fr["up"]) * (CLEARANCE + heave_off)
	var psi: float = wrapf(car_heading - _spur_frame_yaw(fr), -PI, PI)
	var b := Basis(Vector3(fr["side"]), Vector3(fr["up"]), -Vector3(fr["tan"]))
	b = b.rotated(Vector3(fr["up"]), psi)
	b = b.rotated(b.z, edge_roll)
	car.global_transform = Transform3D(b, pos)


func _spur_leave_air() -> void:
	# Leaving the spur ballistically (a slow ring entry
	# detaching past vertical, or running off the chute's
	# side): the velocity is the car's real 3D velocity along
	# the chute, and the fall origin for the drone is a
	# main-track s from a wide projection - the recovery
	# drops the car on the MAIN track under Item 1's rules.
	var fr: Dictionary = _spur_frame_at(spur_s)
	on_spur = false
	air_vel = Vector3(fr["tan"]) * speed + Vector3(fr["side"]) * lat_vel
	air_s_est = _project_wide_s(car.global_position)
	air_start_s = air_s_est
	air_time = 0.0
	below_band_t = 0.0
	lost_lat_t = 0.0
	air_exit_y = float(fr["pos"].y)
	air_from_gap = false
	was_airborne = true
	mode = MODE_AIR


func _update_drive_spur(delta: float) -> void:
	# Driving on the spur: the free-heading model's plan math
	# is unchanged (the heading is a yaw; the chute's pitch
	# lives in the frame), but progress is spur_s INTEGRATED
	# from the along-chute speed - pure position projection
	# stalls on the ring, where the nearest centreline point
	# stops advancing as the tangent goes vertical. spur_lat
	# is the lateral offset, corrected by projection.
	if bounce_pending:
		bounce_pending = false
		_spur_leave_air()
		return
	var fr: Dictionary = _spur_frame_at(spur_s)
	var tanv: Vector3 = fr["tan"]
	var f0: Vector3 = _heading_fwd()
	var r0: Vector3 = _heading_right()
	var vl: float = vel2.dot(Vector2(r0.x, r0.z))
	var accel: float = in_throttle * 10.0
	accel -= in_brake * 14.0
	accel -= speed * 0.10
	accel += -GRAV * tanv.y * 0.85
	if in_boost and boost_meter > 0.0 and in_throttle > 0.05:
		accel += 9.0
		boost_meter = maxf(boost_meter - 30.0 * delta, 0.0)
	speed = clampf(speed + accel * delta, -6.0, TOP_SPEED)
	if in_brake > 0.05 and speed < 0.5 and speed > -0.5:
		speed = 0.0
	var steer: float = clampf(wheel_angle / PI, -1.0, 1.0)
	var lock_scale: float = _lock_scale(speed)
	var front_angle: float = steer * MAX_LOCK_RAD * lock_scale
	var omega_target: float = clampf(-speed / WHEELBASE * tan(front_angle), -MAX_YAW_RATE, MAX_YAW_RATE)
	yaw_rate = lerpf(yaw_rate, omega_target, clampf(delta / YAW_TAU, 0.0, 1.0))
	car_heading = wrapf(car_heading + yaw_rate * delta, -PI, PI)
	var f1: Vector3 = _heading_fwd()
	var r1: Vector3 = _heading_right()
	grip_mult = _grip_for(yaw_rate / maxf(absf(speed), 2.0))
	var bleed: float = clampf(-GRIP_BITE_RATE * vl * grip_mult,
		-GRIP_LAT_ACCEL * grip_mult, GRIP_LAT_ACCEL * grip_mult)
	vl += bleed * delta
	slip_state = clampf((absf(vl) - AUDIO_SLIP_ONSET) / AUDIO_SLIP_SPAN, 0.0, 1.0)
	lat_vel = vl
	var psi: float = wrapf(car_heading - _spur_frame_yaw(fr), -PI, PI)
	spur_s += speed * cos(psi) * delta
	# the heading's side drift: yawing +psi turns the nose
	# toward -side (frame side is +X of the heading frame),
	# so the drift term is -sin(psi) * speed
	spur_lat += (vl - sin(psi) * speed) * delta
	# vel2 keeps its plan meaning for the other consumers:
	# the heading's plan direction at the plan-projected speed.
	var plan_frac: float = Vector2(tanv.x, tanv.z).length()
	vel2 = Vector2(f1.x, f1.z) * speed * plan_frac + Vector2(r1.x, r1.z) * vl
	# Projection as a bounded correction on the lateral only.
	var pr: Array = _project_to_spur(car.global_position, spur_s)
	if absf(float(pr[0]) - spur_s) < 3.0:
		spur_lat = lerpf(spur_lat, float(pr[1]), 0.5)
	# Off the chute's side -> fall (to a main-track recovery).
	if absf(spur_lat) > HALF_WIDTH + EDGE_FALL_OVERSHOOT:
		_spur_leave_air()
		return
	# The merge: hand back to the main projection at the join.
	var sp_len: float = float(track_data["circuit"]["spur"]["len"])
	if spur_s >= sp_len - 0.5:
		on_spur = false
		var prm: Array = _project_to_spine(car.global_position, SPUR_JOIN_S)
		car_s = float(prm[0])
		car_lat = float(prm[1])
		_place_car_on_track(_frame_at(car_s))
		return
	_place_car_on_spur(_spur_frame_at(spur_s))


func _update_suspension_spur(delta: float) -> void:
	# Suspension on the spur: axle frames sampled along the
	# chute, and the PHYSICAL crest-load form - the road's
	# normal load is gravity's component along the frame up
	# minus the centripetal demand v^2 * kv. In the ring kv
	# is -1/R throughout, so the load is cos(theta) +
	# v^2/(gR): pressed at the bottom, zero at the top when
	# v = sqrt(gR) ~= 10.4 m/s, negative (separation) below
	# that past vertical. No adhesion anywhere: the same
	# sustained-zero-load rule as the main track lets go.
	var fr_c: Dictionary = _spur_frame_at(spur_s)
	var fr_f: Dictionary = _spur_frame_at(spur_s + WHEELBASE * 0.5)
	var fr_r: Dictionary = _spur_frame_at(spur_s - WHEELBASE * 0.5)
	geom_f = (Vector3(fr_f["pos"]) - Vector3(fr_c["pos"])).dot(Vector3(fr_c["up"]))
	geom_r = (Vector3(fr_r["pos"]) - Vector3(fr_c["pos"])).dot(Vector3(fr_c["up"]))
	load_f = clampf(Vector3(fr_f["up"]).y - speed * speed * float(fr_f["kv"]) / GRAV, 0.0, 1.25)
	load_r = clampf(Vector3(fr_r["up"]).y - speed * speed * float(fr_r["kv"]) / GRAV, 0.0, 1.25)
	if delta > 0.0:
		var la: float = clampf((speed - prev_speed) / delta, -12.0, 12.0)
		long_accel_f = lerpf(long_accel_f, la, 0.25)
	prev_speed = speed
	var transfer: float = long_accel_f * SUSP_TRANSFER_K
	for wi: int in 4:
		sup_ok[wi] = true
		sup_s[wi] = spur_s + (WHEELBASE * 0.5 if wi < 2 else -WHEELBASE * 0.5)
		sup_rise[wi] = geom_f if wi < 2 else geom_r
	var tw: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for wi2: int in 4:
		var ld: float = load_f if wi2 < 2 else load_r
		var tr: float = -transfer if wi2 < 2 else transfer
		var rs: float = geom_f if wi2 < 2 else geom_r
		tw[wi2] = clampf((SUSP_REST + rs) * ld + tr, 0.0, SUSP_TRAVEL)
	_susp_integrate((tw[0] + tw[1]) * 0.5, (tw[2] + tw[3]) * 0.5, delta)
	edge_roll = lerpf(edge_roll, 0.0, clampf(EDGE_ROLL_LAG * delta, 0.0, 1.0))
	if load_f <= AIR_LOAD_EPS and load_r <= AIR_LOAD_EPS and speed > 8.0:
		air_load_frames += 1
	else:
		air_load_frames = 0
	if air_load_frames >= AIR_SUSTAIN_FRAMES:
		bounce_pending = true
		bounce_vy = 0.0
		air_load_frames = 0



func _gen_circuit_tail(snap: Array, lr: float, phi_h: float, r_e: float) -> Vector3:
	# (Re)generate the circuit's tail from the snapshot and
	# return the closure residual: where the NEXT step after
	# the last sample would land, minus the start point. Zero
	# residual = exact closure (the wrap segment then has the
	# same ~1 m length and heading as every other segment).
	_gen_pos = snap[0]
	_gen_yaw = snap[1]
	_gen_phi = snap[2]
	_gen_bank = snap[3]
	b_pts.resize(int(snap[4]))
	b_tan.resize(int(snap[5]))
	b_bank.resize(int(snap[6]))
	b_curv.resize(int(snap[7]))
	b_gap.resize(int(snap[8]))
	# return straight: pitch ramps from the snapshot's phi to
	# phi_h over 45 m, holds for the rest of lr, ramps to 0
	var phi_s: float = _gen_phi
	_walkf(45.0, 0.0, phi_h, 0.0, false, absf(phi_h - phi_s) / 45.0)
	_walkf(maxf(lr - 90.0, 0.0), 0.0, phi_h, 0.0, false)
	_walkf(45.0, 0.0, 0.0, 0.0, false, absf(phi_h) / 45.0)
	# curve E - the closing HAIRPIN, left 180 deg at the
	# solver radius; its bank unwinds over the final 20 m so
	# the seam itself is flat and unbanked
	var arc_e: float = deg_to_rad(180.0) * r_e
	_walkf(arc_e - 20.0, 1.0 / r_e, 0.0, deg_to_rad(26.0), false)
	_walkf(20.0, 1.0 / r_e, 0.0, 0.0, false, 0.006, deg_to_rad(26.0) / 20.0)
	var hd := Vector3(-sin(_gen_yaw), 0.0, -cos(_gen_yaw))
	var tanv: Vector3 = (hd * cos(_gen_phi) + Vector3.UP * sin(_gen_phi)).normalized()
	return (_gen_pos + tanv * 1.0) - _cir_start


func _solve_circuit_tail(snap: Array) -> Array:
	# Newton iteration (finite-difference Jacobian, damped) on
	# (return-straight length, its hold pitch, curve E radius)
	# against the 3-component closure residual. The couplings
	# are weak (pitch barely moves the plan; length/radius
	# barely move elevation), so this converges in a few
	# iterations to sub-centimetre closure.
	var x: Array = [190.0, 0.0, 102.0]
	var f0: Vector3 = _gen_circuit_tail(snap, float(x[0]), float(x[1]), float(x[2]))
	var deltas: Array = [0.6, 0.002, 0.6]
	for it: int in 10:
		if maxf(absf(f0.x), maxf(absf(f0.y), absf(f0.z))) < 0.01:
			break
		var cols: Array = []
		for j: int in 3:
			var xp: Array = x.duplicate()
			xp[j] = float(xp[j]) + float(deltas[j])
			var fp: Vector3 = _gen_circuit_tail(snap, float(xp[0]), float(xp[1]), float(xp[2]))
			cols.append((fp - f0) / float(deltas[j]))
		var a: Vector3 = cols[0]
		var b: Vector3 = cols[1]
		var c: Vector3 = cols[2]
		var det: float = a.dot(b.cross(c))
		if absf(det) < 1e-9:
			break
		var nf: Vector3 = -f0
		x[0] = clampf(float(x[0]) + nf.dot(b.cross(c)) / det * 0.85, 80.0, 420.0)
		x[1] = clampf(float(x[1]) + a.dot(nf.cross(c)) / det * 0.85, -0.03, 0.20)
		x[2] = clampf(float(x[2]) + a.dot(b.cross(nf)) / det * 0.85, 80.0, 150.0)
		f0 = _gen_circuit_tail(snap, float(x[0]), float(x[1]), float(x[2]))
	_gen_circuit_tail(snap, float(x[0]), float(x[1]), float(x[2]))
	return [x[0], x[1], x[2], f0.length()]


func _finalize_track(closed: bool, features: Dictionary) -> Dictionary:
	# Shared track finalization for both tracks: per-sample
	# vertical curvature, then the smoothing passes. On a
	# CLOSED track every neighbour index wraps the seam, so
	# the seam is smoothed and curved exactly like any other
	# join (that is what makes it invisible in the step
	# metrics - stage 19 measures across it).
	# Fix Pass 5: kv = -d(elevation angle)/ds, positive over a
	# crest (the road falls away); the suspension reads it.
	var n: int = b_pts.size()
	var kv: Array[float] = []
	kv.resize(n)
	for ki: int in n:
		var km: int = (ki - 1 + n) % n if closed else maxi(ki - 1, 0)
		var kp: int = (ki + 1) % n if closed else mini(ki + 1, n - 1)
		var phi_m: float = asin(clampf(b_tan[km].y, -1.0, 1.0))
		var phi_p: float = asin(clampf(b_tan[kp].y, -1.0, 1.0))
		kv[ki] = -(phi_p - phi_m) / (2.0 if closed else float(kp - km))
	# Fix Pass 8 (Item 1): one [0.25, 0.5, 0.25] smoothing pass
	# over kv (curvature is what a 3 m wheelbase FEELS - an
	# average over the contact patches, not a point value),
	# then the same pass over the stored POINTS and TANGENTS
	# (the generator's polygon corners otherwise concentrate
	# each slope change into one view step). Everything
	# downstream reads the same smoothed arrays through
	# _frame_at, so the world stays self-consistent.
	var kv_raw: Array[float] = []
	kv_raw.assign(kv)
	for ki2: int in n:
		var km2: int = (ki2 - 1 + n) % n if closed else maxi(ki2 - 1, 0)
		var kp2: int = (ki2 + 1) % n if closed else mini(ki2 + 1, n - 1)
		kv[ki2] = 0.25 * kv_raw[km2] + 0.5 * kv_raw[ki2] + 0.25 * kv_raw[kp2]
	var pts_raw: Array[Vector3] = []
	pts_raw.assign(b_pts)
	var tan_raw: Array[Vector3] = []
	tan_raw.assign(b_tan)
	for si: int in n:
		var sm: int = (si - 1 + n) % n if closed else maxi(si - 1, 0)
		var sp: int = (si + 1) % n if closed else mini(si + 1, n - 1)
		b_pts[si] = 0.25 * pts_raw[sm] + 0.5 * pts_raw[si] + 0.25 * pts_raw[sp]
		b_tan[si] = (0.25 * tan_raw[sm] + 0.5 * tan_raw[si] + 0.25 * tan_raw[sp]).normalized()
	return {
		"pts": b_pts, "tan": b_tan, "bank": b_bank, "curv": b_curv,
		"gap": b_gap, "kv": kv,
		"len": float(n) if closed else float(n - 1),
		"closed": closed, "features": features}


func _activate_track(d: Dictionary) -> void:
	# Point the live arrays at one track's data and mirror its
	# feature spans into the globals the game logic reads
	# (gap_s0 and friends always describe the ACTIVE track).
	t_pts = d["pts"]
	t_tan = d["tan"]
	t_bank = d["bank"]
	t_curv = d["curv"]
	t_gap = d["gap"]
	t_kv = d["kv"]
	track_len = float(d["len"])
	track_closed = bool(d["closed"])
	var f: Dictionary = d["features"]
	gap_s0 = float(f["gap_s0"])
	gap_s1 = float(f["gap_s1"])
	gap2_s0 = float(f["gap2_s0"])
	gap2_s1 = float(f["gap2_s1"])
	ext_s0 = float(f["ext_s0"])
	sweeper_s0 = float(f["sweeper_s0"])
	sweeper_s1 = float(f["sweeper_s1"])
	stairs_s0 = float(f["stairs_s0"])
	stairs_s1 = float(f["stairs_s1"])
	lap_count = 0
	for key: String in track_data:
		(track_data[key]["root"] as Node3D).visible = key == active_track


func _set_track(tname: String) -> void:
	# Switch the active track and restart the race on it (the
	# dash's purple button / desktop V). Item 4's spur state
	# resets here too - a track switch is a full reset.
	if not track_data.has(tname):
		return
	active_track = tname
	_activate_track(track_data[tname])
	on_spur = false
	spur_s = 0.0
	start_race()
	_update_panel()


func _build_track_meshes(d: Dictionary) -> void:
	# Meshes for one track, parented to its root (only the
	# active track's root is visible). Reads _frame_at, so the
	# track must be ACTIVE when this runs (the builders do).
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
	var seg_n: int = t_pts.size() if bool(d["closed"]) else t_pts.size() - 1
	for i: int in seg_n:
		var frame0: Dictionary = _frame_at(float(i))
		if bool(frame0["gap"]):
			continue
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
		# Fix Pass 11 (Item 5): DASHED (3 m on / 2 m off) - optic
		# flow for the raised top speed; a continuous strip on a
		# flat untextured surface gives the eye nothing temporal
		# to measure speed against.
		if i % 5 < 3:
			_add_quad(edge_pos, edge_nrm, edge_col,
				l0 + u0 * 0.02, l0 + s0 * EDGE_STRIP_W + u0 * 0.02, l1 + s1 * EDGE_STRIP_W + u1 * 0.02, l1 + u1 * 0.02,
				up_avg, edge_c)
			_add_quad(edge_pos, edge_nrm, edge_col,
				r0 - s0 * EDGE_STRIP_W + u0 * 0.02, r0 + u0 * 0.02, r1 + u1 * 0.02, r1 - s1 * EDGE_STRIP_W + u1 * 0.02,
				up_avg, edge_c)
		# stilts every 10 m down to the ground (Fix Pass 9: the
		# desert floor, ~60 m below the datum - the stilts now
		# land on something instead of ending in the void)
		if i % 10 == 0:
			var top: Vector3 = p0
			var bot := Vector3(p0.x, DESERT_FLOOR_Y, p0.z)
			_add_box_verts(stilt_pos, stilt_nrm, stilt_col, (top + bot) * 0.5,
				Vector3(0.55, top.y - bot.y, 0.55), Color(0.42, 0.42, 0.46))
	var troot: Node3D = d["root"]
	_add_mesh(surf_pos, surf_nrm, surf_col, "TrackSurface", false, troot)
	_add_mesh(skirt_pos, skirt_nrm, skirt_col, "TrackSkirt", false, troot)
	_add_mesh(edge_pos, edge_nrm, edge_col, "TrackEdges", true, troot)
	_add_mesh(stilt_pos, stilt_nrm, stilt_col, "Stilts", false, troot)
	_build_gantry(2.0, Color(0.15, 0.6, 0.2), "START", troot)
	if not bool(d["closed"]):
		_build_gantry(track_len - 2.0, Color(0.7, 0.15, 0.15), "FINISH", troot)


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


func _add_mesh(pp: PackedVector3Array, nn: PackedVector3Array, cc: PackedColorArray, mname: String, unshaded: bool = false, parent: Node = null) -> void:
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
	(parent if parent != null else self).add_child(mi)


func _build_gantry(s: float, col: Color, _label: String, parent: Node = null) -> void:
	var fr: Dictionary = _frame_at(s)
	var p: Vector3 = fr["pos"]
	var sd: Vector3 = fr["side"]
	var up: Vector3 = fr["up"]
	var g := Node3D.new()
	g.name = "Gantry" + _label
	(parent if parent != null else self).add_child(g)
	_box(g, Vector3(0.35, 4.6, 0.35), p - sd * (HALF_WIDTH + 0.4) + up * 2.3, _mat(Color(0.2, 0.2, 0.22)))
	_box(g, Vector3(0.35, 4.6, 0.35), p + sd * (HALF_WIDTH + 0.4) + up * 2.3, _mat(Color(0.2, 0.2, 0.22)))
	var banner := _box(g, Vector3((HALF_WIDTH + 0.4) * 2.0, 0.7, 0.3), p + up * 4.6, _mat_unshaded(col))
	banner.global_transform = Transform3D(Basis(fr["side"], fr["up"], -fr["tan"]), banner.global_position)


## Frame (pos/side/up/tan/bank/curv/gap) at path distance s (float).
func _frame_at(s: float) -> Dictionary:
	# Fix Pass 10 (Item 3): on a CLOSED track s wraps and the
	# neighbour index wraps with it - a frame straddling the
	# start/finish seam lerps across it like any other join.
	var sf: float
	var i0: int
	var i1: int
	var fr: float
	if track_closed:
		sf = wrapf(s, 0.0, track_len)
		i0 = int(floor(sf)) % t_pts.size()
		i1 = (i0 + 1) % t_pts.size()
		fr = sf - floor(sf)
	else:
		sf = clampf(s, 0.0, track_len)
		i0 = int(floor(sf))
		i1 = mini(i0 + 1, t_pts.size() - 1)
		fr = sf - float(i0)
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
	if track_closed:
		# Fix Pass 10 (Item 3): the window wraps the seam -
		# segments are indexed unwrapped around the hint and
		# mapped mod n, so a car crossing the line projects
		# continuously; the returned s is wrapped to [0, len).
		var rad: int = 280 if wide else 8
		var centre: int = int(round(hint))
		var best_iu: int = centre
		var best_t: float = 0.0
		var best_d2: float = 1e18
		for di: int in range(-rad, rad + 1):
			var iu: int = centre + di
			var i: int = ((iu % n) + n) % n
			var a: Vector3 = t_pts[i]
			var ab: Vector3 = t_pts[(i + 1) % n] - a
			var l2: float = ab.length_squared()
			var t: float = 0.0
			if l2 > 1e-9:
				t = clampf((p - a).dot(ab) / l2, 0.0, 1.0)
			var d2: float = p.distance_squared_to(a + ab * t)
			if d2 < best_d2:
				best_d2 = d2
				best_iu = iu
				best_t = t
		if not wide and (best_iu == centre - rad or best_iu == centre + rad):
			return _project_to_spine(p, hint, true)
		var s_w: float = wrapf(float(best_iu) + best_t, 0.0, track_len)
		var fr_w: Dictionary = _frame_at(s_w)
		return [s_w, (p - fr_w["pos"]).dot(fr_w["side"])]
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
	air_start_s = car_s # Fix Pass 10 (Item 1): the fall starts HERE
	air_time = 0.0
	below_band_t = 0.0
	lost_lat_t = 0.0
	air_exit_y = float(fr["pos"].y)
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
		# Fix Pass 11 (Item 6): per-axle tyre size - smaller
		# fronts, big wide rear slicks. The centre stays at
		# WHEEL_RAD_REF (see the Item 6 constants note): the
		# radius lives in the mesh and in the suspension's
		# attach heights, not in the strut length.
		var is_rear_w: bool = wl.y > 0.0
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = WHEEL_RAD_R if is_rear_w else WHEEL_RAD_F
		cm.bottom_radius = WHEEL_RAD_R if is_rear_w else WHEEL_RAD_F
		cm.height = WHEEL_WID_R if is_rear_w else WHEEL_WID_F
		w.mesh = cm
		w.rotation_degrees = Vector3(0, 0, 90)
		w.position = Vector3(wl.x, WHEEL_RAD_REF, wl.y)
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
	# EYE_ANCHOR and 0.26 m below it (Fix Pass 11: both rose, the
	# drop is 0.29 m now). Fix Pass 3 stands the wheel UP:
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
	# Fix Pass 11 (Item 2): the pivots sat at y 0.90, INSIDE the
	# dash slab (its top is 0.93) - the lever's base and the
	# first ~3 cm of its activation segment lived below the
	# surface the driver sees, which is exactly where run 11
	# put the left lever's sweet spot ("looks below lever,
	# maybe inside console"). Pivots now sit ON the surface.
	var switch_cols: Array[Color] = [Color(0.9, 0.2, 0.15), Color(0.95, 0.8, 0.15), Color(0.2, 0.5, 0.95)]
	for i: int in 3:
		var piv := Node3D.new()
		piv.position = Vector3(-0.30 + 0.30 * float(i), 0.93, -0.60)
		piv.rotation_degrees = Vector3(-38, 0, 0)
		car_body.add_child(piv)
		switch_pivots.append(piv)
		_box(piv, Vector3(0.055, 0.20, 0.055), Vector3(0, 0.08, 0), _mat(Color(0.65, 0.65, 0.68)))
		_box(piv, Vector3(0.085, 0.06, 0.085), Vector3(0, 0.19, 0), _mat_unshaded(switch_cols[i]))
		_register_dash_ctl(piv, "switch%d" % i)
	# Red RESTART button + green LEAN toggle button (physical dash controls)
	# Fix Pass 10 (Item 3): restart shifts left (0.48 -> 0.40) to
	# make room for the purple TRACK button at 0.57 - the pair
	# sits 0.17 m apart, inside the 0.15 m activation radius of
	# each other only at their exact midpoints; activation is
	# nearest-control (Item 0), so the closer button wins.
	var rst := Node3D.new()
	# Fix Pass 11 (Item 2): was y 0.90 - the button cylinder
	# (height 0.04) spanned 0.88..0.92, ENTIRELY inside the
	# dash slab (top 0.93): an invisible control that fired by
	# proximity alone. It now sits ON the dash (0.93..0.97).
	rst.position = Vector3(0.40, 0.95, -0.60)
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
	lnt.position = Vector3(-0.52, 0.95, -0.60) # on the dash (Item 2, as restart)
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
	# Purple TRACK button: ribbon <-> mountain circuit
	var trk := Node3D.new()
	trk.position = Vector3(0.57, 0.95, -0.60) # on the dash (Item 2, as restart)
	car_body.add_child(trk)
	var trk_mi := MeshInstance3D.new()
	var trk_m := CylinderMesh.new()
	trk_m.top_radius = 0.045
	trk_m.bottom_radius = 0.045
	trk_m.height = 0.04
	trk_mi.mesh = trk_m
	trk_mi.material_override = _mat_unshaded(Color(0.55, 0.2, 0.85))
	trk_mi.name = "TrackBtnMesh"
	trk.add_child(trk_mi)
	_register_dash_ctl(trk, "track")
	# Fix Pass 11 (Item 1): seat trim levers on the LEFT pod -
	# VTOL-style physical seat adjustment in the cockpit's
	# lever-forward language, worked with the same grip-near
	# gesture as every other control: white SEAT+ (front) raises
	# the eye, black SEAT- (rear) lowers it, HOLDING the hand in
	# the zone trims continuously (see _poll_grab). Same lever
	# build as the dash switches (pivot on the surface, shaft +
	# cap), pivots on the pod top (pod spans y 0.27..0.69, top
	# 0.69), so Item 2's zone audit covers them like the rest.
	# Registered after track: indices 6 and 7 (stages key on the
	# first six registrations staying in their FP10 order).
	var seat_cols: Array[Color] = [Color(0.95, 0.95, 0.95), Color(0.22, 0.22, 0.25)]
	var seat_kinds: Array[String] = ["seatup", "seatdn"]
	var seat_zs: Array[float] = [-0.30, 0.10]
	for si: int in 2:
		var spiv := Node3D.new()
		spiv.position = Vector3(-0.72, 0.69, seat_zs[si])
		spiv.rotation_degrees = Vector3(-20, 0, 0)
		car_body.add_child(spiv)
		_box(spiv, Vector3(0.055, 0.20, 0.055), Vector3(0, 0.08, 0), _mat(Color(0.65, 0.65, 0.68)))
		_box(spiv, Vector3(0.085, 0.06, 0.085), Vector3(0, 0.19, 0), _mat_unshaded(seat_cols[si]))
		_register_dash_ctl(spiv, seat_kinds[si])
	# Fix Pass 11 (Item 4): the DROP LEVER on the RIGHT pod -
	# the recovery release, worked like the real thing: a big
	# lever (0.50 m shaft, red knob) on the pod top at
	# (0.72, 0.69, -0.10), 0.80 m from the wheel hub - well
	# outside the 0.40 m wheel-grab radius, so the two grabs
	# can never fight. Rest angle leans it forward; the pull
	# sweeps it back toward the driver through the detent.
	# Grab/pull/spring/haptic live in _poll_grab /
	# _update_drop_lever; Item 2's audit covers its zone.
	# Fix Pass 12 (Item 1): the lever becomes a GEAR SHIFTER.
	# Run 12's verdict on the FP11 placement: "too far back of
	# player seating, should be moved forward, shortened by
	# 1/3, more like a gear shift." The pivot moves to the
	# right pod's FORWARD end (0.72, 0.71, -0.60) - beside the
	# wheel, at hanging-hand height - and the shaft shortens
	# 0.50 -> 0.33 m (knob centre 0.35). The MECHANISM is
	# untouched: same rest/detent/max angles, same per-hand
	# latch, same hand-arc follow (the pull reads the hand's
	# angle about the pivot, so shaft length never entered
	# it), same spring-home, same haptic pulse. Clearances at
	# the new spot, computed: rest knob (0.72, 1.04, -0.70) is
	# 0.78 m from the wheel hub (grab radius 0.40) and 0.21 m
	# from the TRK dash button (zone radius 0.15); the shaft
	# at x = 0.72 never crosses the dash slab (x +-0.62).
	_box(car_body, Vector3(0.18, 0.03, 0.30), Vector3(0.72, 0.70, -0.60), _mat(Color(0.10, 0.10, 0.12)))
	drop_lever_pivot = Node3D.new()
	drop_lever_pivot.name = "DropLever"
	drop_lever_pivot.position = Vector3(0.72, 0.71, -0.60)
	drop_lever_pivot.rotation.x = DROP_LEVER_REST_RAD
	car_body.add_child(drop_lever_pivot)
	_box(drop_lever_pivot, Vector3(0.06, 0.33, 0.06), Vector3(0, 0.165, 0), _mat(Color(0.55, 0.55, 0.58)))
	_box(drop_lever_pivot, Vector3(0.11, 0.11, 0.11), Vector3(0, 0.35, 0), _mat_unshaded(Color(0.90, 0.12, 0.10)))
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
	# Fix Pass 11 (Item 1): raised 5 cm - the command list grew
	# (seat trim lines) and the wheel hub rose 9 cm with the
	# seat; the bottom rows' sightlines clipped the rim and the
	# right switch knob in the render proof again.
	# Fix Pass 11 (Item 2): +4 cm more - Item 2 put the switch
	# pivots ON the dash (+3 cm), and the BOOST cap now grazes
	# the bottom row the FP4 layout threaded just over it.
	panel_root.position = Vector3(0.78, 1.62, -1.66)
	panel_root.rotation_degrees = Vector3(-2, -24, 0)
	car_body.add_child(panel_root)
	_box(panel_root, Vector3(0.80, 1.24, 0.02), Vector3(0, 0, 0), _mat(Color(0.05, 0.07, 0.12)), "PanelBoard")
	panel_label = Label3D.new()
	panel_label.position = Vector3(-0.368, 0.555, 0.02)
	panel_label.font_size = 30
	panel_label.pixel_size = 0.00105 # FP12: the controls list grew (shifter/panels lines); ~9% smaller type keeps it on its board
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
	# Fix Pass 11 (Item 1): raised 8.5 cm more - the rim rose
	# 9 cm with the seat (Item 1) and the raked body pitch
	# (Item 6) drops the board's bottom edge toward the left
	# switch cap; the sweep clipped both again.
	# Fix Pass 11 (Item 1): the board widens (0.68 -> 0.84) and
	# shifts left with it - the ZONE line gained the two seat
	# tags (SUP/SDN) and wrapped at the old 600 px label width;
	# the full tag names stay.
	# Fix Pass 11 (Item 4): widened again (0.84 -> 1.02, label
	# 760 -> 900 px) - the ZONE line gained the DRP tag and
	# wrapped again; the tag names still stay full.
	diag_root.position = Vector3(-0.54, 1.29, -1.00)
	diag_root.rotation_degrees = Vector3(-10, 28, 0)
	car_body.add_child(diag_root)
	_box(diag_root, Vector3(1.02, 0.34, 0.02), Vector3(0, 0, 0), _mat(Color(0.05, 0.07, 0.12)), "DiagBoard")
	diag_label = Label3D.new()
	diag_label.position = Vector3(-0.45, 0.125, 0.02)
	diag_label.font_size = 26
	diag_label.pixel_size = 0.00105
	diag_label.width = 900.0
	diag_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diag_label.modulate = Color(0.92, 0.95, 1.0)
	diag_label.outline_size = 5
	diag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	diag_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	diag_root.add_child(diag_label)
	# Fix Pass 12 (Item 2): boards start hidden (see
	# panels_visible) - _toggle_panels() is the one switch.
	panel_root.visible = false
	diag_root.visible = false
	_update_panel()


func _register_dash_ctl(node: Node3D, kind: String) -> void:
	dash_ctl_nodes.append(node)
	dash_ctl_kinds.append(kind)


func _panel_text() -> String:
	var mode_txt: String = "XR LIVE" if xr_ok else "DESKTOP FALLBACK"
	var lines: Array[String] = []
	lines.append("STUNT CAR VR - TEST 1 [%s]" % mode_txt)
	lines.append("SPD %d  BOOST %d  DENT %d  TRK %s" % [int(round(speed * 3.6)), int(round(boost_meter)), dent_level,
		"CIRCUIT" if active_track == "circuit" else "RIBBON"])
	if track_closed:
		lines.append("STATE %s  LAP %d/%d  TD %s" % [_state_name(), mini(lap_count + 1, RACE_LAPS), RACE_LAPS, last_touchdown])
	else:
		lines.append("STATE %s  TD %s" % [_state_name(), last_touchdown])
	lines.append("LEAN EXP %s  GRIP x%.2f" % ["ON" if lean_on else "OFF", grip_mult])
	lines.append("-- VR CONTROLS --")
	lines.append("Grab wheel: GRIP near wheel, turn hand")
	lines.append("Throttle R trigger / Brake L trigger")
	lines.append("Boost: R A button (while driving)")
	lines.append("Release: pull the DROP SHIFTER (right pod, fwd)")
	lines.append("Flip switch: GRIP near a dash switch")
	lines.append("Seat: GRIP-HOLD SEAT+/SEAT- pod levers")
	lines.append("Call drone: L X button (while driving)")
	lines.append("Jitter exp: R stick click")
	lines.append("Dash buttons (GRIP): red restart, green lean, purple track")
	lines.append("Recenter: L stick click / BOTH grips")
	lines.append("restart race: L Y button")
	lines.append("Panels: R B button (show/hide)")
	lines.append("-- DESKTOP --")
	lines.append("W/S throttle/brake, A/D steer, SHIFT boost")
	lines.append("SPACE release, 1/2/3 flip FUEL/SPARK/BOOST")
	lines.append("TAB panels, L lift, T lean, J jitter, Q/E lean body")
	lines.append("PgUp/PgDn seat trim, R restart race")
	lines.append("C recenter, V track")
	# Fix Pass 4: the DIAG block no longer appends here - it renders
	# on its own board (diag_label) via _update_panel.
	return "\n".join(lines)


func _update_panel() -> void:
	if panel_label != null:
		panel_label.text = _panel_text()
	if diag_label != null:
		diag_label.text = diag_block


## Fix Pass 12 (Item 2): the one panel switch - both boards
## together, hidden by default. Label text keeps refreshing
## while hidden (prep and DIAG flows are unaffected); only
## the boards' visibility flips.
func _toggle_panels() -> void:
	panels_visible = not panels_visible
	if panel_root != null:
		panel_root.visible = panels_visible
	if diag_root != null:
		diag_root.visible = panels_visible


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
		lines.append("ANCHOR DESKTOP (cam on anchor) CAMH %.2f" % _eye_anchor().y)
	lines.append(_diag_hand_line("L"))
	lines.append(_diag_hand_line("R"))
	lines.append(_diag_zone_line())
	# Fix Pass 11 (Item 1): the seat trim rides the WHEEL line -
	# the ANCHOR and ZONE lines are at the label's wrap width
	# already (the proof's cockpit capture showed both wrapping
	# when SEAT and the two new zone tags first landed).
	lines.append("WHEEL %+d DEG JIT %s SEAT %+.2f" % [int(round(rad_to_deg(wheel_angle))), "ON" if jitter_on else "OFF", seat_trim])
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
		"switch2": "BOOST", "restart": "RST", "lean": "LEAN", "track": "TRK",
		"seatup": "SUP", "seatdn": "SDN"}
	var near_l: int = _dash_ctl_near(_hand_pos("L"))
	var near_r: int = _dash_ctl_near(_hand_pos("R"))
	# Fix Pass 11 (Item 4): the drop lever's zone joins the
	# readout (DRP:L / DRP:R / DRP:-).
	var drp: String = "-"
	if _hand_near_drop_lever("L") and _hand_near_drop_lever("R"):
		drp = "B"
	elif _hand_near_drop_lever("L"):
		drp = "L"
	elif _hand_near_drop_lever("R"):
		drp = "R"
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
	tags.append("DRP:%s" % drp)
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
	# Fix Pass 11 (Item 1): desktop seat trim (the cockpit levers'
	# keyboard twin; hold to move).
	if Input.is_key_pressed(KEY_PAGEUP):
		_apply_seat_trim(seat_trim + SEAT_TRIM_RATE * delta)
	if Input.is_key_pressed(KEY_PAGEDOWN):
		_apply_seat_trim(seat_trim - SEAT_TRIM_RATE * delta)
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
		# Fix Pass 11 (Item 1): squeeze BOTH grips = recenter,
		# ported with the Look Test patch-2 anchor cure (there it
		# was the owner's chosen recenter; the L stick click
		# below remains as the other input). gripping[] was just
		# refreshed by the _poll_grab calls above.
		if _btn_edge("both_grips", bool(gripping["L"]) and bool(gripping["R"])):
			_recenter()
		# edges
		# Fix Pass 11 (Item 4): the XR right-trigger release is
		# RETIRED - the drop lever is THE release now (the panel
		# says so). What remains as a non-lever path is desktop /
		# test only: SPACE and the stage hook (test_release_queued
		# below).
		if _btn_edge("l_ax", _input_bool(lc, &"ax_button")):
			if mode == MODE_DRIVE:
				_call_drone()
		# Fix Pass 12 (Item 2): the right B button is the PANEL
		# toggle now (the owner's run-12 ask: "Button calls
		# them up, makes em go away"). It used to toggle the
		# lean experiment; lean still toggles from the green
		# dash button (GRIP) and desktop T - the panel never
		# listed R B for lean, and now lists it for panels.
		if _btn_edge("r_by", _input_bool(rc, &"by_button")):
			_toggle_panels()
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
		KEY_V:
			_set_track("ribbon" if active_track == "circuit" else "circuit")
		KEY_J:
			_toggle_jitter()
		KEY_R:
			start_race()
		KEY_TAB:
			_toggle_panels()
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
	# Fix Pass 11 (Item 1): a recenter is EXPLICIT - the head's facing
	# when it lands becomes the car's forward (standard recenter
	# semantics), so it arms with the bake flag and the yaw cone
	# below does not apply to it.
	if xr_ok:
		_arm_anchor(true)


func _arm_anchor(explicit_bake: bool = false) -> void:
	anchor_pending = true
	anchor_wait_frames = 0
	anchor_stable_frames = 0
	anchor_have_last = false
	anchor_reapply_watch = false
	anchor_bake_yaw = explicit_bake
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
			var bake: bool = anchor_bake_yaw
			anchor_bake_yaw = false
			var yawed: bool = _apply_seat_anchor(bake)
			anchor_state = "APPLIED-STABLE" if yawed else "APPLIED-NOYAW"
			anchor_pending = false
		elif anchor_wait_frames > ANCHOR_FALLBACK_FRAMES:
			# ~10 s with no stable pose: apply from whatever pose
			# exists (graceful degradation, as before) - but keep
			# watching: when a stable tracked pose later appears,
			# re-apply ONCE from the real pose.
			var bake2: bool = anchor_bake_yaw
			anchor_bake_yaw = false
			var yawed2: bool = _apply_seat_anchor(bake2)
			anchor_state = "APPLIED-FALLBACK" if yawed2 else "APPLIED-NOYAW"
			anchor_pending = false
			anchor_reapply_watch = true
	elif anchor_reapply_watch and anchor_stable_frames >= ANCHOR_STABLE_FRAMES:
		var bake3: bool = anchor_bake_yaw
		anchor_bake_yaw = false
		var yawed3: bool = _apply_seat_anchor(bake3)
		anchor_state = "APPLIED-STABLE" if yawed3 else "APPLIED-NOYAW"
		anchor_reapply_watch = false
	elif anchor_yaw_pending and anchor_stable_frames >= ANCHOR_STABLE_FRAMES \
			and absf(_head_yaw_dev()) <= deg_to_rad(ANCHOR_YAW_CONE_DEG):
		# Fix Pass 11 (Item 1): the deferred yaw half of an
		# automatic application - the head has come inside the
		# cone on a stable pose, so baking now maps his
		# near-forward onto the car's forward, never a turned
		# head. (Ported from the Look Test, patch 2.)
		_apply_seat_anchor(true)
		anchor_state = "APPLIED-STABLE"


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


func _cam_in_car() -> Transform3D:
	# The HMD's transform in car space.
	return car.global_transform.affine_inverse() * xr_cam.global_transform


func _head_fwd_car(cam_car: Transform3D) -> Vector3:
	# The HMD's horizontal forward in car space.
	var fwd: Vector3 = -cam_car.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.05:
		return Vector3(0.0, 0.0, -1.0)
	return fwd.normalized()


func _yaw_dev_of(fwd: Vector3) -> float:
	# Signed yaw of a horizontal car-space forward away from the
	# car's forward (-Z in car space): 0 looking down the car,
	# +PI/2 looking out the right side, -PI/2 out the left.
	return atan2(fwd.x, -fwd.z)


func _head_yaw_dev() -> float:
	return _yaw_dev_of(_head_fwd_car(_cam_in_car()))


func _eye_anchor() -> Vector3:
	# The seat anchor the driver actually gets: the fixed
	# EYE_ANCHOR plus his cockpit trim (Fix Pass 11, Item 1).
	# Every consumer (anchor math, fallback camera, DIAG) reads
	# the anchor through here so trim moves all of them at once.
	return EYE_ANCHOR + Vector3(0.0, seat_trim, 0.0)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		seat_trim = clampf(float(cfg.get_value("seat", "trim", 0.0)),
			-SEAT_TRIM_MAX, SEAT_TRIM_MAX)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("seat", "trim", seat_trim)
	cfg.save("user://settings.cfg")


func _apply_seat_trim(new_trim: float) -> void:
	# The one funnel for every trim input (cockpit seat levers,
	# desktop PgUp/PgDn): clamp, persist, and move the LIVE seat
	# by the delta so a trim mid-drive takes effect without a
	# recenter. seat_offset's origin is expressed in car space,
	# so shifting its Y is a pure eye-height change in car space
	# whatever its basis holds. The desktop fallback camera is
	# re-placed from _eye_anchor() every frame by the view code.
	var clamped: float = clampf(new_trim, -SEAT_TRIM_MAX, SEAT_TRIM_MAX)
	var delta: float = clamped - seat_trim
	if absf(delta) < 0.00005:
		return
	seat_trim = clamped
	if seat_offset != null:
		seat_offset.transform.origin.y += delta
	_save_settings()


func _apply_seat_anchor(force_bake: bool) -> bool:
	# Offset the seat so the HMD lands exactly on the eye anchor in car
	# space, yaw-aligned to the car's heading. The correction is rigid
	# and sits ABOVE the XR origin, so head motion (and the lean
	# reading, which is measured local to the origin) afterwards is
	# relative to the anchor.
	#
	# Fix Pass 11 (Item 1), ported from the Look Test patch 2: the
	# yaw half of this correction maps the head's CURRENT facing
	# onto the car's forward - it bakes. That is the definition of
	# an explicit recenter (force_bake), but an AUTOMATIC
	# application must not bake a head that happens to be turned
	# when the pose settles: the stability gate watches position
	# only, so a still-but-turned head passes it and the turn
	# becomes "forward" for the whole session (the Look Test's
	# 45-degree view; the game carried the same latent flaw).
	# Automatic calls therefore land the translation only when
	# the head sits outside ANCHOR_YAW_CONE_DEG, and leave
	# anchor_yaw_pending set; the yaw lands when the head enters
	# the cone (see the watch in _process_anchor_pending).
	# Returns true when the yaw was applied (correction complete).
	# The lean neutral is captured on BOTH halves - a
	# translation-only landing still moves the head's frame.
	var cam_car: Transform3D = _cam_in_car()
	var fwd: Vector3 = _head_fwd_car(cam_car)
	if not force_bake and absf(_yaw_dev_of(fwd)) > deg_to_rad(ANCHOR_YAW_CONE_DEG):
		var corr_t := Transform3D(Basis.IDENTITY, _eye_anchor() - cam_car.origin)
		seat_offset.transform = corr_t * seat_offset.transform
		anchor_yaw_pending = true
		_capture_lean_neutral()
		return false
	# Yaw that rotates the current horizontal view direction onto the
	# car's forward (-Z in car space).
	var yaw: float = atan2(fwd.z, fwd.x) + PI * 0.5
	var rot := Basis(Vector3.UP, yaw)
	var corr := Transform3D(rot, _eye_anchor() - rot * cam_car.origin)
	seat_offset.transform = corr * seat_offset.transform
	anchor_yaw_pending = false
	_capture_lean_neutral()
	return true


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


## Fix Pass 11 (Item 4): the drop lever's grab segment in
## world space - the upper shaft and knob. Shared by the
## grab test, Item 2's audit and the render proof's
## overlay. Fix Pass 12 (Item 1): the shifter's shaft is
## 0.33 m, so the segment is pivot-local (0, 0.17, 0) to
## (0, 0.36, 0) - still the upper shaft plus the knob
## (knob centre 0.35, span 0.295..0.405).
func debug_drop_lever_segment() -> Array:
	if drop_lever_pivot == null:
		return []
	var xf: Transform3D = drop_lever_pivot.global_transform
	return [xf * Vector3(0, 0.17, 0), xf * Vector3(0, 0.36, 0)]


func _hand_near_drop_lever(hand: String) -> bool:
	var seg: Array = debug_drop_lever_segment()
	if seg.size() != 2:
		return false
	return _seg_point_dist(seg[0], seg[1], _hand_pos(hand)) <= DROP_LEVER_GRAB_RADIUS


func _update_drop_lever_pull(hand: String) -> void:
	# The lever follows the gripped hand along its arc: the
	# hand's angle about the pivot, measured in car space on
	# the lever's own swing plane (fore-aft), clamped to the
	# throw. Crossing the detent fires the release once.
	var lp: Vector3 = car_body.global_transform.affine_inverse() * _hand_pos(hand)
	var v: Vector3 = lp - drop_lever_pivot.position
	var ang: float = clampf(atan2(v.z, v.y), DROP_LEVER_REST_RAD, DROP_LEVER_MAX_RAD)
	drop_lever_angle = ang
	if ang >= DROP_LEVER_DETENT_RAD and not drop_lever_fired:
		drop_lever_fired = true
		_pulse_detent(hand)
		_do_release() # self-gated: only a dangle lets go


func _update_drop_lever(delta: float) -> void:
	# Spring home when ungripped (early release = no drop),
	# and the single writer of the pivot's rotation.
	if drop_lever_hand == "":
		if drop_lever_angle > DROP_LEVER_REST_RAD:
			drop_lever_angle = maxf(DROP_LEVER_REST_RAD,
				drop_lever_angle - DROP_LEVER_SPRING_RATE * delta)
		if drop_lever_angle < DROP_LEVER_DETENT_RAD - 0.10:
			drop_lever_fired = false
	if drop_lever_pivot != null:
		drop_lever_pivot.rotation.x = drop_lever_angle


func _pulse_detent(hand: String) -> void:
	# The detent is FELT: a short pulse on the pulling hand
	# through the action map's existing "haptic" output
	# action (bound to /user/hand/{left,right}/output/haptic
	# in project.godot). Null-safe - no live interface (tests,
	# desktop) means no pulse and no error. Whether it is
	# perceptible on the live rig is the owner's verdict:
	# unverifiable headless, listed as such in the pass report.
	# API guarded: XRInterface.trigger_haptic_pulse (the call
	# lives on the BASE class, not OpenXRInterface).
	if not xr_ok or xr_iface == null:
		return
	xr_iface.trigger_haptic_pulse(&"haptic",
		&"left_hand" if hand == "L" else &"right_hand", 0.0, 0.7, 0.12, 0.0)


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
	# --- Fix Pass 11 (Item 4): THE DROP LEVER ---
	# Latched per hand while gripped: the lever follows the
	# hand along its arc; crossing the detent fires the
	# release (plus a haptic pulse on the pulling hand) once
	# per pull. Releasing the grip early leaves the lever to
	# spring home in _update_drop_lever - no drop. Its zone
	# overlaps no dash zone and sits outside the wheel-grab
	# radius, so the grabs can never fight.
	if drop_lever_hand == hand:
		if not now:
			drop_lever_hand = ""
		else:
			_update_drop_lever_pull(hand)
	elif now and drop_lever_hand == "" and _hand_near_drop_lever(hand):
		drop_lever_hand = hand
		drop_lever_fired = false
		_update_drop_lever_pull(hand)
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
	# Fix Pass 11 (Item 1): the seat levers are HOLD controls - a
	# gripping hand resting in the zone trims continuously at
	# SEAT_TRIM_RATE instead of entry-firing a one-shot action.
	if ctl_now >= 0 and dash_ctl_kinds[ctl_now].begins_with("seat"):
		var sdir: float = 1.0 if dash_ctl_kinds[ctl_now] == "seatup" else -1.0
		_apply_seat_trim(seat_trim + sdir * SEAT_TRIM_RATE * _delta)
		dash_ctl_fired[hand] = ctl_now
	elif ctl_now >= 0 and int(dash_ctl_fired[hand]) != ctl_now:
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
	if dash_ctl_kinds[i].begins_with("switch") or dash_ctl_kinds[i].begins_with("seat"):
		var xf: Transform3D = node.global_transform
		# Fix Pass 11 (Item 2): the segment starts at local
		# +0.02, just above the mounting surface - it used to
		# start at -0.02, under the (then buried) pivot, so the
		# first part of every lever's zone was inside the dash.
		# The far end stays at the cap centre (0.19): the zone
		# IS the visible handle's path, asserted geometrically
		# by debug_dash_ctl_audit (smoke stage 23).
		return [xf * Vector3(0.0, 0.02, 0.0), xf * Vector3(0.0, 0.19, 0.0)]
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
	elif kind == "track":
		_set_track("ribbon" if active_track == "circuit" else "circuit")


# ---------------------------------------------------------------- actions

func start_race() -> void:
	mode = MODE_HANG
	hang_phase = "dangle"
	is_drop_start = true
	on_spur = false
	spur_s = 0.0
	spur_lat = 0.0
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
	lap_count = 0
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
	# Fix Pass 10 (Item 2): carrier at station over the gantry.
	carrier_vel = Vector3.ZERO
	carrier_accel = Vector3.ZERO
	carrier_path.clear()
	carrier_wp = 0
	carrier_yaw = _frame_yaw(fr["tan"])
	orient_yaw = carrier_yaw
	orient_yaw_v = 0.0
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
	# Fix Pass 10 (Item 2): the dip state is the FLOWN-dip state
	# (progress/depth/cadence); the procedural pivot offset is gone.
	dip_t = -1.0
	dip_depth = 0.0
	dip_timer = 2.0
	dip_seed = 0
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
	# Fix Pass 10 (Item 2): the carrier starts at a hover over the
	# catch and flies the RETRACE path back to the drop point -
	# spine samples every ~30 m at hang height plus a clearance
	# margin, so it follows the road's shape (climbs, descends)
	# instead of cutting a straight line through it.
	# Fix Pass 12 (Item 3): the path now flies a COLLISION-FREE
	# ALTITUDE PROFILE. FP10 took each waypoint's altitude from
	# its own sample only, so between samples the carrier flew
	# chords and the hanging car sagged toward the road it
	# crossed - measured on staged recoveries, the car's centre
	# passed ~1.5 m over the surface (wheels ~0.7 m) at the
	# worst sag, and on a route crossing the hump row a crest
	# between samples stands higher than both neighbours: the
	# run-12 "flies through road and pylon a lot". Now the
	# route is sampled every ~5 m first, and each waypoint's
	# altitude is the HIGHEST road surface within +-45 m of
	# route travel around it (the window also covers where
	# the SWINGING car actually reaches - metres ahead of and
	# behind the anchor's column on a sloped route), plus the hang stack
	# (HANG_LEN + HANG_CLEAR) plus CARRIER_ROUTE_CLEAR_M -
	# so the chord between adjacent waypoints also clears
	# (both endpoints sit at or above every surface in the
	# segment's window). Stilts of OTHER pieces cannot be
	# hit: the circuit's closest plan approach between
	# distinct pieces is 57 m (measured, this pass), and the
	# spur's stilts stand under a surface at or below the
	# road the route follows. The suite asserts the carried
	# car intersects neither ribbon nor stilt on staged
	# carries (over the humps, across the climb, out of the
	# gap). anchor_target itself is untouched: the dangle
	# station is exactly where Fix Pass 2 put it, and a
	# profiled penultimate point 15 m of travel before the
	# drop keeps the final dive short and local.
	carrier_vel = Vector3.ZERO
	carrier_accel = Vector3.ZERO
	carrier_yaw = _frame_yaw(_frame_at(from_s)["tan"])
	station_wait_t = 0.0
	carrier_path.clear()
	carrier_wp = 0
	var back_dist: float = wrapf(from_s - drop_target_s, 0.0, track_len) if track_closed \
		else maxf(0.0, from_s - drop_target_s)
	var route_y: Array[float] = []
	var rd: float = 0.0
	while rd <= back_dist + 0.01:
		var s_r: float = wrapf(from_s - rd, 0.0, track_len) if track_closed else from_s - rd
		route_y.append(float(_frame_at(s_r)["pos"].y))
		rd += 5.0
	var prof_alt = func(route_d: float) -> float:
		var m: float = -1.0e30
		for j: int in route_y.size():
			if absf(float(j) * 5.0 - route_d) <= 45.0:
				m = maxf(m, route_y[j])
		return m + HANG_LEN + HANG_CLEAR + CARRIER_ROUTE_CLEAR_M
	# Climb-out first: a deep catch (a gap fall is caught ~13 m
	# below the road) starts UNDER the surface it must cross.
	# If the hover sits below the profile, the first path
	# point is straight above the catch at profile altitude -
	# the carrier climbs out of the hole vertically before it
	# travels, instead of dragging the car diagonally through
	# the lip it fell past.
	if anchor_pos.y < prof_alt.call(0.0) - 0.05:
		var p_0: Vector3 = anchor_pos
		p_0.y = prof_alt.call(0.0)
		carrier_path.append(p_0)
	# The 30 m samples stop 20 m short of the drop: the first
	# FP12 build let the last sample land past the penultimate
	# (back_dist 158 -> sample at s 750, penultimate at s 757),
	# doubling the path back on itself - the carrier reversed
	# twice at the station and rang there for ~7 s (traced).
	var steps: int = int(maxf(back_dist - 20.0, 0.0) / 30.0)
	for k: int in range(1, steps + 1):
		var s_k: float = wrapf(from_s - 30.0 * float(k), 0.0, track_len) if track_closed \
			else from_s - 30.0 * float(k)
		var fr_k: Dictionary = _frame_at(s_k)
		var p_k: Vector3 = fr_k["pos"]
		p_k.y = maxf(float(fr_k["pos"].y) + HANG_LEN + HANG_CLEAR + 1.2, prof_alt.call(30.0 * float(k)))
		carrier_path.append(p_k)
	if back_dist > 20.0:
		var s_p: float = wrapf(drop_target_s + 15.0, 0.0, track_len) if track_closed \
			else drop_target_s + 15.0
		var fr_p: Dictionary = _frame_at(s_p)
		var p_p: Vector3 = fr_p["pos"]
		p_p.y = maxf(float(fr_p["pos"].y) + HANG_LEN + HANG_CLEAR + 1.2, prof_alt.call(back_dist - 15.0))
		carrier_path.append(p_p)
	carrier_path.append(anchor_target)
	_reset_dangle_feel()
	# initial pendulum angles from the catch offset
	var off: Vector3 = catch_pos - anchor_pos
	pend_th_f = clampf(off.dot(fr["tan"]) / HANG_LEN, -0.6, 0.6)
	pend_th_l = clampf(off.dot(fr["side"]) / HANG_LEN, -0.6, 0.6)
	pend_om_f = 0.0
	pend_om_l = 0.0
	_prep_new_sequence()


# Fix Pass 10 (Item 1): DROP_MIN_RUNUP_M - the hazard-free road a
# drop point must have IN FRONT of it before the next feature
# (gap lip, hump, staircase, steep section, sharp bank entry).
# The owner's rules, verbatim intent: never drop in front of a
# jump; never drop ahead of the fall.
const DROP_MIN_RUNUP_M: float = 25.0


func _drop_piece_ok(s: float) -> bool:
	# A valid drop piece in itself: on the road (no gap), flat,
	# straight, unbanked - the Fix Pass 2 hang-centring criteria
	# (a level, unbanked section keeps the plumb hang centred
	# over the centreline).
	var fr: Dictionary = _frame_at(s)
	return not bool(fr["gap"]) and absf(float(fr["curv"])) < 0.004 \
		and absf(float(fr["tan"].y)) < 0.08 and absf(float(fr["bank"])) < 0.03


func _drop_runup_ok(drop_s: float) -> bool:
	# DROP_MIN_RUNUP_M of hazard-free road ahead of the drop
	# point: no gap sample, no crest that unloads the car (kv
	# above the hump band - the humps peak at ~0.021), nothing
	# steep (the staircase reads tan.y ~-0.37, lips ~0.17+ on
	# their approaches), no banked or curving section.
	var s: float = drop_s + 1.0
	var end: float = drop_s + DROP_MIN_RUNUP_M
	while s <= end:
		var fr: Dictionary = _frame_at(s)
		if bool(fr["gap"]):
			return false
		if float(fr["kv"]) > 0.010:
			return false
		if absf(float(fr["tan"].y)) > 0.20:
			return false
		if absf(float(fr["bank"])) > 0.10:
			return false
		if absf(float(fr["curv"])) > 0.006:
			return false
		s += 1.0
	return true


func _find_drop_s(from_s: float) -> float:
	# Fix Pass 10 (Item 1): the drop search walks BACK, never
	# forward (the pre-fix search walked AHEAD from the fall -
	# free progress, and it could set the car down right in
	# front of the next jump: both of the owner's run-10
	# complaints in one function). from_s is where the car left
	# the road (air_start_s for falls, car_s for an on-demand
	# lift) and is the ceiling: candidates step back from it in
	# 2 m strides to the nearest piece that is itself valid
	# (_drop_piece_ok) AND has DROP_MIN_RUNUP_M of clear road
	# ahead (_drop_runup_ok). On a closed track the walk wraps
	# the start/finish seam and may search the whole lap.
	# Fallbacks, in order, each still honouring the ceiling:
	# the nearest valid piece ignoring the run-up; the nearest
	# piece under the pre-Fix Pass 10 relaxed criteria (slope
	# < 0.12, bank ignored); then the start line itself.
	var origin_s: float
	var max_back: float
	if track_closed:
		origin_s = wrapf(from_s, 0.0, track_len)
		max_back = track_len
	else:
		origin_s = clampf(from_s, 2.0, track_len - 2.0)
		max_back = origin_s - 2.0
	var back: float = 0.0
	while back <= max_back:
		var cand: float = wrapf(origin_s - back, 0.0, track_len) if track_closed else origin_s - back
		if _drop_piece_ok(cand) and _drop_runup_ok(cand):
			return cand
		back += 2.0
	back = 0.0
	while back <= max_back:
		var cand2: float = wrapf(origin_s - back, 0.0, track_len) if track_closed else origin_s - back
		if _drop_piece_ok(cand2):
			return cand2
		back += 2.0
	back = 0.0
	while back <= max_back:
		var cand3: float = wrapf(origin_s - back, 0.0, track_len) if track_closed else origin_s - back
		var fr3: Dictionary = _frame_at(cand3)
		if not bool(fr3["gap"]) and absf(float(fr3["curv"])) < 0.004 \
				and absf(float(fr3["tan"].y)) < 0.12:
			return cand3
		back += 2.0
	return 2.0 if not track_closed else wrapf(origin_s - max_back, 0.0, track_len)


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
	# Fix Pass 10 (Item 2): the carrier's vertical motion at the
	# release carries in (was the procedural dip velocity).
	air_vel.y += carrier_vel.y * 0.5
	air_s_est = drop_target_s
	air_start_s = drop_target_s # a botched release falls from HERE
	air_time = 0.0
	below_band_t = 0.0 # FP12: a release is a new air episode
	lost_lat_t = 0.0
	air_exit_y = float(_frame_at(drop_target_s)["pos"].y)
	air_from_gap = false
	# Fix Pass 9: the released car flies and lands under the
	# heading it HUNG with (see _orient_car_hang - Fix Pass 10:
	# that heading is the spring-settled orient_yaw, which at a
	# settled dangle equals the drop section's direction).
	# The horizontal air velocity becomes the velocity vector.
	car_heading = orient_yaw
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
	_update_drop_lever(delta) # Fix Pass 11 (Item 4): spring + pose
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


## Fix Pass 11 (Item 5): the steering lock scale, shared by
## both drivers (main track and spur). At |v| <= 24 m/s this
## is the FP10 expression verbatim - same operands, same
## order - so the response the owner approved is numerically
## identical there. Above 24 the effective falloff speed
## blends smoothly to STEER_FALLOFF_HI at 40 m/s.
func _lock_scale(v: float) -> float:
	if absf(v) <= STEER_BLEND_LO:
		return 1.0 / (1.0 + (v / STEER_FALLOFF_SPEED) * (v / STEER_FALLOFF_SPEED))
	var t: float = smoothstep(STEER_BLEND_LO, STEER_BLEND_HI, absf(v))
	var fs: float = lerpf(STEER_FALLOFF_SPEED, STEER_FALLOFF_HI, t)
	return 1.0 / (1.0 + (v / fs) * (v / fs))


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
	# Fix Pass 10 (Item 4): on the loop spur a sibling driver
	# runs (integrated spur_s, spur frames - see
	# _update_drive_spur).
	if on_spur:
		_update_drive_spur(delta)
		return
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
	vf = clampf(vf + accel * delta, -6.0, TOP_SPEED)
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
	var lock_scale: float = _lock_scale(vf)
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
	var prev_s: float = car_s
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
	if track_closed:
		# Fix Pass 10 (Item 3): on the circuit the gantry is a
		# LAP LINE - crossing it in DRIVE (wrapped s jumps the
		# seam) counts a lap; RACE_LAPS laps finish the race.
		if prev_s > track_len - 60.0 and car_s < 60.0:
			lap_count += 1
			if lap_count >= RACE_LAPS:
				mode = MODE_DONE
				finished_time = race_time
				state_label.text = "FINISH!"
	elif car_s >= track_len - 0.5:
		mode = MODE_DONE
		finished_time = race_time
		state_label.text = "FINISH!"
	# Fix Pass 10 (Item 4): spur capture - in the entry window
	# past SPUR_ENTRY_S, a car whose centre is within 1.3 m of
	# the spur centreline is on the spur (the driver steered
	# onto the fork's line); a car staying right never is.
	if active_track == "circuit" and track_data["circuit"].has("spur"):
		var d_in: float = wrapf(car_s - SPUR_ENTRY_S + 2.0, 0.0, track_len)
		if d_in < 75.0 and vf > 0.0:
			var spc: Array = _project_to_spur(car.global_position,
				clampf(car_s - SPUR_ENTRY_S + 8.0, 0.0, 60.0))
			# The spur starts ON the centreline, so proximity
			# alone would capture a car driving straight down
			# the middle. Capture needs the diverge underway:
			# the spur point is past the fork's nose and the
			# car is measurably off the main centreline,
			# following the fork's line.
			if float(spc[0]) > 10.0 and float(spc[2]) < 1.2 and absf(car_lat) > 0.5:
				on_spur = true
				spur_s = float(spc[0])
				spur_lat = float(spc[1])
				_place_car_on_spur(_spur_frame_at(spur_s))
				return
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
	# missed it so far - but the drone is called only when the
	# car is GENUINELY LOST. Fix Pass 10 (Item 1): the recovery
	# is charged from air_start_s - where the car LEFT the
	# road - not from air_s_est, which by now includes the
	# whole flight (and would drop the car ahead of its fall,
	# past obstacles it failed: the run-10 cheat).
	# Fix Pass 12 (Item 5): the old trigger's bare
	# `air_time > 2.4` term is DELETED - convicted by staging:
	# a 48 m/s launch off the climb top (s 2125, rebound 2.0)
	# was snatched at 2.41 s while its counterfactual
	# ballistic landed cleanly 1.23 s later at s 2303, lat
	# 0.0 - the run-12 video's "a jump seems to find you
	# suddenly being carried by drone", reproduced. The
	# dip-lip flight lands at 2.32 s, 0.08 s from the same
	# fate. The landing test above is honest and stays; the
	# trigger is positional now: (a) h < -13 - fallen far
	# below the road (unchanged); (b) below the landing band
	# (h < -2.2), descending, and STAYING below for
	# AIR_LOST_BELOW_T - if a lower piece ahead brings h back
	# into the band the dwell resets and the landing reopens;
	# (c) the AIR_FAILSAFE_T ceiling for states no ballistic
	# can reach (longest honest flight measured: 3.64 s);
	# (d) the LATERAL exit: |lat| beyond the landing window's
	# reach (HALF_WIDTH + 2.5) with the car below its EXIT
	# plane, held for the same dwell. Added on measurement:
	# the staged lateral lip exit took 2.90 s to declare on
	# rule (b) alone, because over the plunging dip road the
	# spine-relative h is masked by the road's own descent.
	# The exit plane is not masked, and a car that far off
	# the ribbon, below where it left, cannot come back -
	# there is no lateral control in the air. It is lost by
	# construction, so the drone stops waiting politely.
	if h < -2.2 and air_vel.y < 0.0:
		below_band_t += delta
	else:
		below_band_t = 0.0
	if absf(lat) > HALF_WIDTH + 2.5 and pos.y < air_exit_y - 1.0:
		lost_lat_t += delta
	else:
		lost_lat_t = 0.0
	if h < -13.0 or below_band_t > AIR_LOST_BELOW_T or lost_lat_t > AIR_LOST_BELOW_T or air_time > AIR_FAILSAFE_T:
		_begin_recovery(pos, air_start_s)


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
	elif vf_land > TOP_SPEED:
		vel2 -= Vector2(f2.x, f2.z) * (vf_land - TOP_SPEED)
		vf_land = TOP_SPEED
	speed = vf_land
	lat_vel = vel2.dot(Vector2(r2.x, r2.z))
	yaw_rate = 0.0
	var pr: Array = _project_to_spine(car.global_position, air_s_est, true)
	car_s = float(pr[0])
	car_lat = float(pr[1])
	mode = MODE_DRIVE
	was_airborne = false
	_place_car_on_track(_frame_at(car_s))


func _carrier_dip_offset() -> Vector2:
	# (y offset, y velocity) of the FLOWN dip at its current
	# progress: a raised-cosine descent 0 -> -depth -> 0 over
	# DIP_DUR. Peak vertical acceleration = depth * 2pi^2 /
	# DIP_DUR^2 (6.6-10.8 m/s^2 over the depth range) - deep
	# dips outrun the car's ability to follow and slack the
	# lines; shallow ones just soften the swing.
	if dip_t < 0.0:
		return Vector2.ZERO
	var ph: float = dip_t / DIP_DUR
	var y: float = -dip_depth * (0.5 - 0.5 * cos(TAU * ph))
	var vy: float = -dip_depth * (PI / DIP_DUR) * sin(TAU * ph)
	return Vector2(y, vy)


func _step_carrier(delta: float) -> void:
	# Fix Pass 10 (Item 2): the carrier's flight integrator. It
	# replaces both the old constant-speed carry step and the
	# procedural dip offset: anchor_pos is a flown position with
	# velocity and an acceleration LIMIT, and carrier_accel is
	# MEASURED from the velocity change the limit allowed -
	# the pendulum (and the slack trigger) read that, never a
	# schedule.
	var target: Vector3 = anchor_target
	var target_vel: Vector3 = Vector3.ZERO
	var arrive: bool = true # true: closing behaviour; false: cruise through
	if hang_phase == "attach":
		target = anchor_pos # hold station over the catch while lines settle
	elif hang_phase == "carry":
		if carrier_wp < carrier_path.size():
			target = carrier_path[carrier_wp]
			arrive = carrier_wp == carrier_path.size() - 1
			# Advance on proximity OR on passing the waypoint
			# abeam (a chord-cutting carrier can pass a point
			# metres off and orbit it at cruise otherwise).
			if not arrive and (anchor_pos.distance_to(target) < 2.5 or \
					(anchor_pos.distance_to(target) < 7.0 and \
					carrier_vel.dot(target - anchor_pos) < 0.0)):
				carrier_wp += 1
				target = carrier_path[carrier_wp]
				arrive = carrier_wp == carrier_path.size() - 1
	elif hang_phase == "dangle":
		# Flown dips on the old hash cadence (deterministic -
		# the smoke depends on reproducible behaviour), but the
		# dip is a manoeuvre: the station target descends on the
		# dip profile and the carrier flies down to it and back.
		if dip_t < 0.0:
			dip_timer -= delta
			if dip_timer <= 0.0:
				dip_seed += 1
				var h1: float = sin(float(dip_seed) * 12.9898) * 43758.5453
				var h2: float = sin(float(dip_seed) * 78.233) * 12543.21
				dip_depth = 0.85 + 0.55 * (h1 - floor(h1))
				dip_timer = 6.5 + 4.5 * (h2 - floor(h2))
				dip_t = 0.0
		else:
			dip_t += delta
			if dip_t >= DIP_DUR:
				dip_t = -1.0
		var doff: Vector2 = _carrier_dip_offset()
		target = anchor_target + Vector3(0.0, doff.x, 0.0)
		target_vel = Vector3(0.0, doff.y, 0.0)
	# velocity command
	var desired: Vector3
	if test_pivot_accel_on:
		desired = carrier_vel # acceleration is injected below
	elif arrive:
		desired = target_vel + (target - anchor_pos) * 1.4
		if desired.length() > CARRIER_SPEED:
			desired = desired.normalized() * CARRIER_SPEED
		# Fix Pass 12 (Item 3): the arrival FLARE, shipped form -
		# a braking-curve speed cap on the carry's final leg:
		# |v| <= sqrt(2 * 5 * d). Full-limit braking from the
		# new 15 m/s cruise otherwise holds the pendulum near
		# atan(9/9.8) ~ 43 deg through the arrival, and a
		# release in that swing throws the car metres sideways
		# (the instrumented stage-11c release measured om_l
		# -2.65 rad/s, a ~14 m/s tip velocity, and a clean miss
		# of the road). On the curve the carrier decelerates at
		# ~5 m/s^2 the whole way in - gentle on the pendulum,
		# and, unlike an accel cap, it cannot overshoot the
		# P-law station: speed is a function of distance left.
		if hang_phase == "carry":
			var d_app: float = (target - anchor_pos).length()
			var cap_app: float = sqrt(2.0 * 5.0 * maxf(d_app - 0.05, 0.0))
			if desired.length() > cap_app:
				desired = desired.normalized() * cap_app
	else:
		var to: Vector3 = target - anchor_pos
		desired = to.normalized() * CARRIER_SPEED if to.length() > 0.01 else Vector3.ZERO
	# integrate under the accel limit; station-keeping gets a
	# higher limit (the rig works hard over the drop point -
	# that authority is what lets it fly the deep dips).
	var prev_vel: Vector3 = carrier_vel
	if test_pivot_accel_on:
		carrier_vel += test_pivot_accel * delta
	else:
		var accel_lim: float = 11.0 if hang_phase == "dangle" else CARRIER_ACCEL
		# (The FP12 flare's first form - an accel cap of 5 on
		# this branch - was measured RINGING against the P-law
		# for ~18 s at the station: too weak to shed 15 m/s
		# inside the P-law's braking distance, it overshot and
		# oscillated. The shipped flare is the braking-curve
		# speed cap in the velocity command below.)
		var dv: Vector3 = desired - carrier_vel
		var max_dv: float = accel_lim * delta
		if dv.length() > max_dv:
			dv = dv.normalized() * max_dv
		carrier_vel += dv
	var inst_accel: Vector3 = (carrier_vel - prev_vel) / maxf(delta, 0.0001)
	carrier_accel = carrier_accel.lerp(inst_accel, 0.5)
	anchor_pos += carrier_vel * delta
	pivot_pos = anchor_pos
	# Carrier yaw: at speed it faces its velocity; at station it
	# faces the drop section - both rate-limited, so a heading
	# change is a turn the car gets twisted through afterwards.
	# Fix Pass 11 (Item 3): the return is flown as an APPROACH.
	# The velocity the carrier arrives on points back along the
	# walk-back - ~180 deg from the drop tangent on a straight -
	# so facing velocity to the very end left the whole turn to
	# be spun through at the station while the car dangled
	# (run 11: "comes in facing the direction you came and
	# takes a painfully long time to turn around"). From the
	# final approach on - the last waypoint, or the last ~45 m
	# (at cruise 9 m/s and CARRIER_YAW_RATE that is >= 5 s,
	# enough for the full 180) - the yaw goal is the DROP
	# heading: the turn is flown, not dangled.
	var yaw_goal: float = carrier_yaw
	var hv: Vector3 = Vector3(carrier_vel.x, 0.0, carrier_vel.z)
	var on_approach: bool = hang_phase == "dangle" or (hang_phase == "carry" \
		and (arrive or anchor_pos.distance_to(anchor_target) < 45.0))
	if on_approach:
		yaw_goal = _frame_yaw(_frame_at(drop_target_s)["tan"])
	elif hv.length() > 0.8:
		yaw_goal = atan2(-hv.normalized().x, -hv.normalized().z)
	var max_turn: float = CARRIER_YAW_RATE * delta
	carrier_yaw += clampf(wrapf(yaw_goal - carrier_yaw, -PI, PI), -max_turn, max_turn)
	# Slack: a hard flown descent drops the carrier out from
	# under the car faster than the car can follow - measured
	# acceleration, not the old impulse threshold on a schedule.
	if hang_phase == "dangle" and carrier_accel.y < DIP_SLACK_ACCEL \
			and slack_t <= 0.0 and catch_t >= 1.0:
		slack_t = 0.15
		hang_pos = car.global_position
		var fr_s: Dictionary = _frame_at(drop_target_s)
		hang_vel = (fr_s["tan"] * (pend_om_f * cos(pend_th_f))
			+ fr_s["side"] * (pend_om_l * cos(pend_th_l))) * HANG_LEN
		hang_vel += carrier_vel
	# Arrival at the drop point ends the carry.
	# Fix Pass 11 (Item 3): a yaw gate joins the position and
	# velocity conditions - the carry does not end until the
	# carrier has flown its alignment (within 0.08 rad of the
	# drop heading), so the car is releasable on arrival instead
	# of dangling through a station spin. The gate is BOUNDED
	# (3 s of station wait): a pathologically short final leg
	# degrades to the old behaviour, never to a stuck recovery.
	if hang_phase == "carry" and carrier_wp >= carrier_path.size() - 1:
		if anchor_pos.distance_to(anchor_target) < 0.08 and carrier_vel.length() < 0.35:
			var drop_yaw_g: float = _frame_yaw(_frame_at(drop_target_s)["tan"])
			if absf(wrapf(carrier_yaw - drop_yaw_g, -PI, PI)) < 0.08:
				anchor_pos = anchor_target
				carrier_vel = Vector3.ZERO
				hang_phase = "dangle"
				station_wait_t = 0.0
			else:
				station_wait_t += delta
				if station_wait_t > 3.0:
					anchor_pos = anchor_target
					carrier_vel = Vector3.ZERO
					hang_phase = "dangle"
					station_wait_t = 0.0
		else:
			station_wait_t = 0.0


func _update_hang(delta: float) -> void:
	_step_carrier(delta)
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
			pass # the carrier flies the retrace path (see _step_carrier)
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
	# damping so the swing persists.
	# Fix Pass 10 (Item 2): the pivot is the CARRIER, and the
	# pendulum integrates its measured acceleration: effective
	# gravity gains the carrier's vertical acceleration (a flown
	# dip softens the swing, the climb-out firms it), and the
	# carrier's horizontal acceleration along each pendulum axis
	# drives that axis directly (equilibrium tilt -atan(a/g) -
	# the car lags when the carrier accelerates, overshoots when
	# it brakes or turns, and settles when it holds station).
	# Axes stay the DROP section's frame: the hang geometry
	# (_hang_car_pos, _catch_lines) is written in that frame.
	if slack_t > 0.0:
		return
	var fr: Dictionary = _frame_at(drop_target_s)
	var g_eff: float = clampf(GRAV + carrier_accel.y, 2.0, 22.0)
	var a_f: float = carrier_accel.dot(fr["tan"])
	var a_l: float = carrier_accel.dot(fr["side"])
	pend_om_f += (-(g_eff / PEND_LEN_F) * sin(pend_th_f)
		- (a_f / PEND_LEN_F) * cos(pend_th_f) - PEND_DAMP * pend_om_f) * delta
	pend_om_l += (-(g_eff / PEND_LEN_L) * sin(pend_th_l)
		- (a_l / PEND_LEN_L) * cos(pend_th_l) - PEND_DAMP * pend_om_l) * delta
	pend_th_f += pend_om_f * delta
	pend_th_l += pend_om_l * delta


func _hang_car_pos(fr: Dictionary) -> Vector3:
	var dirv: Vector3 = (fr["tan"] * sin(pend_th_f) + fr["side"] * sin(pend_th_l)
		- Vector3.UP * (cos(pend_th_f) * cos(pend_th_l))).normalized()
	return pivot_pos + dirv * HANG_LEN


func _orient_car_hang(delta: float, snap: bool) -> void:
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
	# Fix Pass 10 (Item 2): the car's FACING is no longer the drop
	# frame's tangent (rigid - the car snapped to the drop heading
	# for the whole carry). It seeks the CARRIER's yaw on an
	# underdamped spring: when the drone turns, the car twists
	# after it, overshoots a little, and settles - alignment is a
	# target chased slowly, never a lock.
	var yaw_goal: float = test_yaw_target if test_yaw_target_on else carrier_yaw
	if snap:
		orient_yaw = yaw_goal
		orient_yaw_v = 0.0
	else:
		var yerr: float = wrapf(yaw_goal - orient_yaw, -PI, PI)
		orient_yaw_v += (ORIENT_YAW_K * yerr - ORIENT_YAW_DAMP * orient_yaw_v) * delta
		orient_yaw += orient_yaw_v * delta
	var y_axis: Vector3 = -down_dir
	var facing: Vector3 = Vector3(-sin(orient_yaw), 0.0, -cos(orient_yaw))
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
	# Fix Pass 11 (Item 6): each axle's attach also carries its
	# tyre radius relative to the reference radius - the bigger
	# rear tyre holds the rear of the body higher by the radius
	# difference (the rake, derived here rather than painted on).
	var attach_f: float = geom_f - c_f + (WHEEL_RAD_F - WHEEL_RAD_REF)
	var attach_r: float = geom_r - c_r + (WHEEL_RAD_R - WHEEL_RAD_REF)
	pitch_extra = atan2(attach_f - attach_r, WHEELBASE)
	heave_off = (attach_f + attach_r) * 0.5 + SUSP_REST


func _update_suspension(delta: float) -> void:
	# Fix Pass 5: per-axle spring model (see the constants block).
	# Fix Pass 10 (Item 4): on the spur a sibling model runs
	# (spur frames, physical load form - _update_suspension_spur).
	if mode == MODE_DRIVE and on_spur:
		_update_suspension_spur(delta)
		return
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
		wheel_mis[wi].position.y = WHEEL_RAD_REF + (c_axle - SUSP_REST)
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
		fallback_cam.position = _eye_anchor() + Vector3(0.0, v_y, 0.0)


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
		rpm_target = 0.8 + clampf(speed / TOP_SPEED, 0.0, 1.0) * 1.85 \
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
		# Fix Pass 10 (Item 2): the drone IS the carrier - it sits
		# at the pivot, yaws with carrier_yaw, and tilts INTO its
		# measured acceleration like a real lift rig working the
		# load (nose down accelerating, back under braking, rolled
		# into a turn). The canned carry tilt and dip wiggles are
		# retired with the procedural pivot they served.
		# Fix Pass 6 (Item 4) wire rule still holds: lift-line i
		# runs drone corner i -> car corner i and no pair can
		# cross - the car's facing seeks this same carrier_yaw
		# (with lag), so the two yaws never diverge past a few
		# degrees in a turn, far from the ~90 deg a crossing
		# would need.
		var cf: Vector3 = Vector3(-sin(carrier_yaw), 0.0, -cos(carrier_yaw))
		var cr: Vector3 = Vector3(-cf.z, 0.0, cf.x)
		var a_fwd: float = carrier_accel.dot(cf)
		var a_lat: float = carrier_accel.dot(cr)
		var tilt: float = clampf(a_fwd * 0.030, -0.38, 0.38) + 0.03 * sin(pend_th_f)
		var roll: float = clampf(-a_lat * 0.030, -0.38, 0.38) + pend_th_l * 0.4
		drone.rotation_degrees = Vector3(rad_to_deg(tilt), rad_to_deg(carrier_yaw),
			rad_to_deg(roll))
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
		carrier_vel = Vector3.ZERO
		carrier_accel = Vector3.ZERO


func debug_body_width_m() -> float:
	# Fix Pass 10 (Item 3): the car BODY's widest extent in
	# metres, measured off the built meshes (every mesh instance
	# under car_body, AABBs transformed into car space). The
	# body is symmetric in x, so the width is 2x the max |x|
	# reach. Reported alongside the road width in stage 2f -
	# road-in-bodies is the proportion the eye actually reads.
	var max_x: float = 0.0
	var stack: Array[Node] = [car_body]
	while not stack.is_empty():
		var nd: Node = stack.pop_back()
		# The commands/DIAG boards ride in the cockpit but are
		# documentation surfaces, not bodywork - the widest of
		# them reaches 1.16 m and would fake the body at 2.32 m.
		if nd == panel_root or nd == diag_root:
			continue
		for ch: Node in nd.get_children():
			stack.append(ch)
		var mi: MeshInstance3D = nd as MeshInstance3D
		if mi != null and mi.mesh != null:
			var t: Transform3D = car_body.global_transform.affine_inverse() * mi.global_transform
			var ab: AABB = t * mi.mesh.get_aabb()
			max_x = maxf(max_x, maxf(absf(ab.position.x), absf(ab.position.x + ab.size.x)))
	return max_x * 2.0


func debug_carrier_turn(dyaw: float) -> void:
	# Fix Pass 10 (Item 2, stage 17): step the carrier's yaw -
	# the drone "has turned"; the car's facing must chase it on
	# the orient spring (overshoot, then settle), which is what
	# the stage measures.
	carrier_yaw = wrapf(carrier_yaw + dyaw, -PI, PI)


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


# --- Fix Pass 11 (Item 2): the lever-zone geometry audit ---------
# Standing assertion machinery - smoke stage 23 and the render
# proof run it on every pass from here on, so a future mesh edit
# that displaces a zone fails the suite instead of shipping.
# For every control _poll_grab can fire:
#   (a) each sample along its activation segment must sit within
#       DASH_AUDIT_TOL of the control's OWN meshes (point-to-AABB
#       in each mesh's local space - the zone lies ON the handle);
#   (b) no sample may be buried inside any OTHER car-body mesh
#       (inside its AABB shrunk by 5 mm) - the buried buttons and
#       the below-the-console lever base of run 11, as a test.
const DASH_AUDIT_TOL: float = 0.035
const DASH_AUDIT_SAMPLES: int = 5


func _pt_aabb_dist(p: Vector3, ab: AABB) -> float:
	var dx: float = maxf(maxf(ab.position.x - p.x, 0.0), p.x - ab.end.x)
	var dy: float = maxf(maxf(ab.position.y - p.y, 0.0), p.y - ab.end.y)
	var dz: float = maxf(maxf(ab.position.z - p.z, 0.0), p.z - ab.end.z)
	return Vector3(dx, dy, dz).length()


func _pt_in_aabb(p: Vector3, ab: AABB, shrink: float) -> bool:
	return p.x > ab.position.x + shrink and p.x < ab.end.x - shrink \
		and p.y > ab.position.y + shrink and p.y < ab.end.y - shrink \
		and p.z > ab.position.z + shrink and p.z < ab.end.z - shrink


func _collect_meshes(n: Node, out: Array[MeshInstance3D]) -> void:
	for child: Node in n.get_children():
		if child is MeshInstance3D:
			out.append(child as MeshInstance3D)
		_collect_meshes(child, out)


func debug_dash_ctl_audit() -> Dictionary:
	var all_meshes: Array[MeshInstance3D] = []
	_collect_meshes(car_body, all_meshes)
	var worst: float = 0.0
	var violations: Array[String] = []
	for i: int in dash_ctl_nodes.size():
		var node: Node3D = dash_ctl_nodes[i]
		var own: Array[MeshInstance3D] = []
		_collect_meshes(node, own)
		if node is MeshInstance3D:
			own.append(node as MeshInstance3D)
		var seg: Array[Vector3] = _dash_ctl_segment(i)
		for si: int in DASH_AUDIT_SAMPLES:
			var t: float = float(si) / float(DASH_AUDIT_SAMPLES - 1)
			var p: Vector3 = seg[0].lerp(seg[1], t)
			var best: float = 1e9
			for mi: MeshInstance3D in own:
				var lp: Vector3 = mi.global_transform.affine_inverse() * p
				best = minf(best, _pt_aabb_dist(lp, mi.get_aabb()))
			worst = maxf(worst, best)
			if best > DASH_AUDIT_TOL:
				violations.append("%s sample %d: %.3f m from its own mesh" % [dash_ctl_kinds[i], si, best])
			for mi2: MeshInstance3D in all_meshes:
				if own.has(mi2):
					continue
				var lp2: Vector3 = mi2.global_transform.affine_inverse() * p
				if _pt_in_aabb(lp2, mi2.get_aabb(), 0.005):
					violations.append("%s sample %d: buried in %s" % [dash_ctl_kinds[i], si, mi2.name])
	# Fix Pass 11 (Item 4): the drop lever's zone joins the
	# audit, sampled at rest AND at full throw (the segment
	# moves with the handle by construction; both poses must
	# track its own shaft/knob and stay unburied).
	if drop_lever_pivot != null:
		var lown: Array[MeshInstance3D] = []
		_collect_meshes(drop_lever_pivot, lown)
		var saved_ang: float = drop_lever_pivot.rotation.x
		for ang: float in [DROP_LEVER_REST_RAD, DROP_LEVER_MAX_RAD]:
			drop_lever_pivot.rotation.x = ang
			var lseg: Array = debug_drop_lever_segment()
			if lseg.size() == 2:
				for si2: int in DASH_AUDIT_SAMPLES:
					var t2: float = float(si2) / float(DASH_AUDIT_SAMPLES - 1)
					var p2: Vector3 = (lseg[0] as Vector3).lerp(lseg[1] as Vector3, t2)
					var best2: float = 1e9
					for mi3: MeshInstance3D in lown:
						var lp3: Vector3 = mi3.global_transform.affine_inverse() * p2
						best2 = minf(best2, _pt_aabb_dist(lp3, mi3.get_aabb()))
					worst = maxf(worst, best2)
					if best2 > DASH_AUDIT_TOL:
						violations.append("droplever sample %d at %.2f rad: %.3f m from its own mesh" % [si2, ang, best2])
					for mi4: MeshInstance3D in all_meshes:
						if lown.has(mi4):
							continue
						var lp4: Vector3 = mi4.global_transform.affine_inverse() * p2
						if _pt_in_aabb(lp4, mi4.get_aabb(), 0.005):
							violations.append("droplever sample %d at %.2f rad: buried in %s" % [si2, ang, mi4.name])
		drop_lever_pivot.rotation.x = saved_ang
	return {"worst": worst, "violations": violations}
