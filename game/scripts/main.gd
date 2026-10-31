extends Node3D

## Stunt Car VR - DE Test 1 "Drop & Dangle"
## Throwaway FEEL prototype (Godot 4.7 / OpenXR, Quest-native target).
## One ribbon track, one placeholder Odd Rod car, grab-wheel steering,
## Drop Start + crane recovery while dangling, and the
## lean-for-traction experiment. See design-spec.md items 1-16.
## (Fix Pass 15 retired the drone that stood here from FP5 to
## FP14 - the crane is the original's rig; see Item 2.)
## (Fix Pass 13 deleted the dangle prep sequence entirely: the
## hang is sway, wheel and release timing now - see Item 1.)
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
## (s, lat), gap spanning, lap/feature logic, crane targeting.
## Still Crammond-flavoured elsewhere: rationed boost, slope
## gravity, ballistic gap jumps, touchdown quality from impact
## speed + alignment, dent on hard landings.
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
# Fix Pass 25 (Items 2-4): the steering CONNECTION - visual
# only, every value below moves meshes and nothing else. The
# FP25 sightline audit (render proof, run BEFORE this remedy)
# measured the shipped front tires 87% in-frame but only 8%
# VISIBLE from the eye anchor at rest: of 86 sampled surface
# points per tire, the side pod hid 25, the floor 17, the
# dash slab 12, the tire's own far side 11. The remedy is on
# the tire, not the bodywork: the front VISUAL tyre grows to
# 0.33 m radius and steps 0.14 m outboard, out from behind
# the pod. WHEEL_RAD_F itself is a physics constant (it sets
# the suspension attach heights) and does NOT move; the
# visual centre rises by the radius growth so the visual
# contact patch stays on the model's plane (capture 20's
# planted-plane checks measure exactly this), and the dust
# emitters keep marking the TRUE patch at WHEEL_LOCALS.
const WHEEL_RAD_F_VIS: float = 0.33 # front VISUAL tyre radius, m (mesh only)
const WHEEL_OUT_F_VIS: float = 0.14 # front visual outboard step, m (mesh only)
const WHEEL_FWD_F_VIS: float = 0.40 # front visual forward step, m (mesh only) - the dragster's long nose: from the seat, a tire ahead of the pod's front face clears the pod's sightline shadow, one behind it cannot (audit rounds: outboard+radius alone moved rest visibility 8% -> 9%; +0.25 forward -> 17%; +0.40 -> see the README table)
# The displayed steer angle is GAINED at small lock so a
# quarter-turn of the cockpit wheel reads clearly on the
# tires, converging to the honest angle at STEER_VIS_FULL:
# gain = 1 + (GAIN0 - 1) * (1 - smoothstep(0, FULL, |steer|)).
const STEER_VIS_GAIN0: float = 2.2 # display gain at centre
const STEER_VIS_FULL: float = 0.55 # steer fraction at/above which the display is honest
# The slip angle joins the display (Item 3): the front tires
# yaw toward where the car is actually sliding by
# atan2(lat_vel, |speed|), honestly scaled and capped, so a
# slide beginning is visible on the tires themselves.
const SLIP_VIS_CAP_RAD: float = 0.18 # ~10.3 deg
const SLIP_VIS_MIN_SPEED: float = 4.0 # m/s atan2 floor (no blowup parked)
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
# Fix Pass 14 (Item 5): grip follows LOAD. The bleed above ran
# at full strength whenever the car was in DRIVE - including
# across a crest at the moment the road had unloaded the
# car - so a slide started on a crest was killed at full-grip
# rate while the car was still light (the FP9-era crest flick
# measured its slide dead at the landing). The bleed rate
# and cap now scale by load_grip: the car's mean road
# load - the two axles' load factors (the v^2.kv channel
# that also decides separation) averaged - raised to
# GRIP_LOAD_EXP and clamped to [GRIP_LOAD_MIN,
# GRIP_LOAD_MAX]. The power is tire load sensitivity:
# real grip grows sublinearly with load, so the factor
# holds ~1.0 near full load and falls away as the road
# truly unloads the car. It needs the help: the "flat"
# home straight is a shallow crest (kv 0.006 - at 20 m/s
# its load is already 0.75), and a LINEAR factor moved
# the flat flick from 28 / 59 to 34 / 79 on that alone;
# exponent 0.5 read 31 / 69, 0.35 reads 30 / 66 (the
# tuning record is in the FP14 README section). Per-wheel
# load variation enters through the axles' independent
# channels (the front unloads ~20 frames before the rear
# at a crest - stage 38); full per-wheel kv is the
# extension Item 4 recorded.
# (One carrier was tried and rejected on measurements,
# in the FP14 README section: corner COMPRESSION - it
# sags under slide geometry and pitch transfer while the
# true load factor stays 1.00, moving the flat flick to
# 36 / 87. A wheel off the edge is the straddle/fall
# system's story, not the bleed's, so support does not
# weight the factor either.)
const GRIP_LOAD_MIN: float = 0.15
const GRIP_LOAD_MAX: float = 1.15
const GRIP_LOAD_EXP: float = 0.35
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
# Fix Pass 26 (Item 2): the drop DOUBLES, on the owner's
# run-20 order ("we need a higher crane drop by around x2 or
# more"). The quantity that doubles is the air under the car
# at the station - the wheel clearance HANG_CLEAR - CLEARANCE
# goes 0.85 -> 1.70 m, so the staged fall runs ~0.41 -> ~0.59 s
# (free fall over twice the distance). The chains lengthen
# with it: HANG_LEN 5.5 -> 11.0, and both pendulum lengths
# double (PEND_LEN_F/L below), so the sway period stretches
# x1.41 (sqrt 2) with the FP15 gust/jib-flex character kept.
# The crane post's height formula (HANG_LEN + HANG_CLEAR +
# 1.1 in _place_crane) reads the new scale on its own.
const HANG_LEN: float = 11.0
const HANG_CLEAR: float = 2.05
const GRAV: float = 9.8
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
# Fix Pass 16 (Item 1) - OPERATION FIX THE FUCKING LEVERS: the
# grab rebuild's thresholds. The squeeze is read as an ANALOG
# FLOAT ONLY (the runtime-converted "grip_click" bool imported
# VDXR's undocumented press/release thresholds into every latch;
# "grip_force" has no binding in any interaction profile and no
# squeeze/force endpoint exists on Touch Plus - both are gone
# from the latch math; click is still read for the DIAG block).
# The float runs through OUR Schmitt trigger: engage above
# GRIP_ENGAGE, release below GRIP_RELEASE, hold state between.
# Before: a single 0.65 cut on (grip OR click OR force), so a
# squeeze hovering at the cut chattered every latch it fed -
# dash toggles double-fired, the drop lever's pull cancelled
# mid-throw, the wheel grab dropped and re-took. The seat
# levers' capture radius is decoupled from the buttons' in
# Item 2 (bigger volume, smaller mesh); see _dash_ctl_radius.
const GRIP_ENGAGE: float = 0.55
const GRIP_RELEASE: float = 0.30
const DASH_CTL_RADIUS_SEAT: float = 0.19
# Fix Pass 16 (Item 4): the SIDE button fires only on a
# SUSTAINED in-zone hold of this length - a stray brush of the
# dash can no longer flip the drop lever's side mid-session
# (run 15: it flipped itself, silently, and persisted).
const SIDE_HOLD_S: float = 0.6
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
const SUSP_DAMP: float = 11.0 # FP14 (Item 2): was 4.6 (zeta ~0.18, rang 4 overshoots / 2.2 s parked) - the film settles in ~1 s with <=1 overshoot (zeta ~0.36 here) # underdamped on purpose: it must overshoot
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
# load factor sits at ~zero at BOTH axles for a sustained
# run of consecutive frames (the road is falling away faster than
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
const AIR_LOAD_EPS: float = 0.03 # load factor that counts as unloaded (FP21: per corner on the main track)
const REBOUND_THROW_VEL: float = -1.6 # cv_f + cv_r (m/s) that counts as a throw (FP14: staged from the joint trace below)
const REBOUND_LOAD_FLOOR: float = 0.8 # rebound route needs the road fully supporting
# Fix Pass 14 (Item 2): the throw route's travel condition.
# FP5/8 fired at full droop (mean compression <= 0.005),
# which the old underdamped ring (zeta ~0.18) always reached
# by slamming to the stop. The Item 2 damping (zeta ~0.44)
# settles a drop landing WITHOUT crossing droop - and
# silently deleted the Drop Start's soft bounce (stage 2c:
# hop peak 0.16 m -> 0.00 m) and with it ~0.4 s of FP13's
# sway-getaway spread (stage 30: 1.60 s -> 1.19 s), because
# the hop's airborne beat was part of the crossed-up price.
# The throw IS the extension velocity, not the droop
# position: the route now fires as the springs cross
# near-droop still extending fast. The load floor above
# remains the bleed discriminator (unchanged), and the
# velocity floor keeps tremble and gentle returns grounded.
# Staged refinement (M8/M8b probes): the joint trace of a
# drop landing at the new damping reads - extension
# velocity peaks (cv sum -2.93) while the springs are still
# at 0.20 m, crosses rest (0.10) at -2.25..-1.55, and by
# the time the mean compression bottoms (0.060) the throw
# is spent (-0.22). Waiting for near-droop throws the
# energy away: a wheel separates when its spring passes
# natural length still extending fast, not at the stop.
# The route therefore fires mid-stroke: mean compression
# at/below 0.16 with the summed extension velocity past
# -1.6 (the trace crosses that pair at bounce 1.5 m/s,
# hop ~0.12 m - the film's soft bounce). And the
# stored-energy evidence sits where it belongs: a DEEP
# HIT (mean compression >= REBOUND_DEEP_HIT) within the
# last half second. Gentle returns and sagging chases
# (the climb-top bleed never compresses deep) stay grounded.
const REBOUND_FIRE_TRAVEL: float = 0.16 # mean compression (m) at/below which a committed return separates
const REBOUND_DEEP_HIT: float = 0.22 # mean compression (m) that counts as stored energy
const REBOUND_DEEP_HIT_WINDOW: float = 0.5 # seconds a deep hit stays evidence
# Fix Pass 14 (Item 1) - THE REBOUND, energy-gated. The film
# study's headline: every big jump in the original lands and
# REBOUNDS into a second flight of ~1/2-2/3 the first (High
# Jump 1.93 s -> ~0.6 s contact -> 1.16 s); it NEVER sticks a
# big landing. Ours stuck: the FP5/8 spring-throw route above
# caps its throw at 2.6 m/s, so a gap landing at 30 m/s
# measured flight 0.98 s -> contact -> flight 0.28 s (0.29x)
# and the hump row at 48 m/s landed at vy 7.2-8.8 with the
# same low cap. The gate is the landing's own impact speed,
# staged from the measured distribution: Drop Start drops
# land at vy 3.9 and drumbeat hops at ~3 or less - both keep
# the stock throw untouched (FP13's stage-30 getaways depend
# on it); gap and hump-launch landings land at 4.4 and up.
# Above the gate the throw cap scales with the impact
# (flight time is proportional to throw speed, so a throw of
# 0.62x the impact speed yields ~0.62x the flight on the same
# slope), and the return may fire only ONCE per landing
# chain: the rebound's own landing is absorbed, not returned
# again - the film settles after ONE bounce (notes section 4).
# Drone DROPS are excluded outright (air_from_release): a
# sway-carrying release can land above the gate, and its
# landing is FP13 touchdown behaviour, not a jump.
const REBOUND_GATE_VY: float = 4.5 # impact vy (m/s) that arms the energy return
const REBOUND_THROW_FRAC: float = 0.62 # gated throw cap = this x impact vy
const REBOUND_THROW_CAP: float = 6.2 # absolute ceiling on the gated throw, m/s
const REBOUND_CHAIN_RESET_S: float = 0.5
# Fix Pass 14 (Item 7): flight attitude. The film study
# (section 3): through a real flight the nose-down attitude
# BUILDS - the car leaves on the lip's angle and arrives
# slope-matched, nose-first. The build is quadratic in air
# time (a constant angular acceleration of the attitude),
# capped so a very long flight cannot arrive inverted.
const AIR_NOSE_DOWN_ACCEL: float = 0.349 # rad/s^2 of attitude build (~20 deg/s^2)
const AIR_NOSE_DOWN_MAX: float = 0.489 # rad (~28 deg) cap on the build # grounded seconds that re-arm the return
# The return stroke itself (measured, see _susp_integrate):
# with the stock rate the gated throw reached only 1.33 m/s
# of its 3.66 cap on the staged gap landing - the impact's
# kinetic share is damped away against the travel clamp
# before the stroke can return it. Crammond's wheel force
# clamp is asymmetric for the same reason ([-0x300, +0x1400]:
# the push-back may be far stronger than the resistance).
# While a gated return is live and a spring is deep, its
# rate multiplies and its extension damping cuts - the
# bump-stop shove that throws the car back into the air.
const REBOUND_RETURN_DEPTH: float = 0.24 # compression (m) past which the return stiffens
const REBOUND_RETURN_K_MULT: float = 3.0 # spring-rate multiplier on the gated return
const REBOUND_RETURN_DAMP_MULT: float = 0.5 # extension-damping multiplier on the gated return
const REBOUND_GATE_EXPIRY_S: float = 1.2 # an unfired gate lapses (a later crest strike is not a landing return)
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
const PEND_LEN_F: float = 11.0 # FP26 (Item 2): doubled with the chains (was 5.5) - period x1.41
const PEND_LEN_L: float = 7.8 # FP26 (Item 2): doubled with the chains (was 3.9)
const PEND_DAMP: float = 0.10
# Fix Pass 10 (Item 2) gave the hang a PIVOT-DRIVEN carrier:
# real state - position (anchor_pos), velocity, measured
# acceleration - flying a path, with the pendulum integrating
# the pivot's MEASURED acceleration. Fix Pass 15 (Item 2)
# retires the flying carrier entirely: after four passes of
# transports failing from the chair the owner scrapped the
# drone and restored the original's rig - a fixed CRANE on
# the service pad beside the drop piece. There is no flight
# and no retrace: the car is collected OFF-STAGE (as in
# 1989 - no collection animation exists), placed on the pad
# under the jib, lifted on the chains, and the trolley SLEWS
# the hanging car sideways to the drop station, where the
# dangle is the fixed-pivot pendulum the original had -
# kept honest-irregular by desert gusts on the jib and the
# jib's own flex lagging the load (see _step_crane), never a
# clean Lissajous. The pivot-state names survive from the
# flight era (anchor_pos / carrier_vel / carrier_yaw /
# carrier_path) so the hang machinery and its tests did not
# have to be rewritten around a rename.
const CRANE_SLEW_SPEED: float = 2.4 # m/s - trolley slew cap (a crane, not an aircraft)
const CRANE_SLEW_ACCEL: float = 1.6 # m/s^2 - slew accel/brake limit
const CARRIER_YAW_RATE: float = 0.9 # rad/s the jib turns the load at (name kept from the flight era)
# Fix Pass 15 (Item 2): where the rig stands. The pickup sits
# on the service pad CRANE_PICKUP_OFF beyond the road edge
# (sidewalk to sidewalk: road 6.0 + pad to ~9.7); the post
# stands CRANE_POST_OFF out, at the pad's far edge.
const CRANE_PICKUP_OFF: float = 2.4 # m beyond the ribbon edge: pickup centreline
const CRANE_POST_OFF: float = 3.6 # m beyond the ribbon edge: the post
# The dangle's swing budget: the pivot's total excursion from
# the station (gust + flex together) never exceeds this - the
# release-consistency promise the drop staging measures.
const PIVOT_OFF_MAX_M: float = 0.30
# Desert gusts on the jib: the station target steps by up to
# GUST_AMP per axis on a 1.2-2.2 s hash schedule (the FP14
# wander's honest successor - same mechanism class, a fixed
# rig in weather instead of a flying station-keeper).
const GUST_AMP: float = 0.14 # m, per axis
# Jib flex: the pivot leans after the swinging load through a
# first-order lag (a lag cannot resonate; a spring near the
# pendulum's own frequency could pump the swing). Lean cap
# per axis JIB_FLEX_M at full deflection.
const JIB_FLEX_M: float = 0.16 # m, per axis at |sin th| = 1
const JIB_FLEX_TAU: float = 0.7 # s, the lag's time constant
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
# Fix Pass 15 (Item 1) - THE TELEGRAPHED LIMIT. The skid speaks
# only once the tires are already sliding (slip_state derives
# from the lateral velocity that SURVIVED the bleed), so the
# limit arrived unannounced (the owner's run-14 verdict: losing
# traction "just of happens and feels too late"). The telegraph
# is a demand-vs-capacity ratio computed in _update_drive from
# the steering demand itself: lateral acceleration the driven
# yaw asks for (|vf * omega_target|) against the lateral grip
# cap the bleed actually enforces at each axle (GRIP_LAT_ACCEL
# x grip_mult x that axle's load factor - the FP14 Item 5
# carrier, same exponent/floor/cap). The ratio exists BEFORE
# any slide does, and every cue in this item (the tire song's
# pre-limit band, the contact-patch dust, the controller
# rumble) hangs off it, so ear, eye, hand and physics agree by
# construction. The edge family (off-road rumble, edge scrape)
# hangs off the per-wheel support state in _update_suspension
# for the same reason: a cue that can play when its state says
# otherwise is a lie, and lies are worse than silence.
const TIRE_BAND_LO: float = 0.70 # ratio where the song/dust start (the band's lower edge)
const TIRE_BAND_HI: float = 1.00 # ratio at the bleed's cap (breakaway)
const TIRE_HAPTIC_EDGE: float = 0.90 # ratio where the controller rumble joins (final stretch)
const AUDIO_SONG_MAX_DB: float = -19.0 # the tire song at full band (under the skid's -13 peak)
const AUDIO_SONG_FLOOR_DB: float = -34.0 # the song at the band's lower edge
const AUDIO_RUMBLE_MAX_DB: float = -16.0 # off-road rumble with a full side off the ribbon
const AUDIO_SCRAPE_MAX_DB: float = -17.0 # edge scrape at full straddle slide
# Fix Pass 13 (Item 1) - touchdown connection grading. The
# grade is read off the measured contact state (see _land):
# lateral speed at contact and heading error vs the road
# tangent. Thresholds sit between the staged sway-zero and
# sway-peak releases of smoke stage 30 (zero swing lands at
# ~0.1-0.3 m/s lateral and <1 deg; a peak-swing release lands
# at ~4-5 m/s and several degrees - the bands are set from
# that distribution, see the Fix Pass 13 README section).
const CONTACT_CLEAN_LAT: float = 1.0 # m/s
const CONTACT_CLEAN_HDG: float = 3.0 # deg
const CONTACT_SCRUB_LAT: float = 3.0 # m/s
const CONTACT_SCRUB_HDG: float = 8.0 # deg
const CONTACT_READOUT_S: float = 2.5 # s the touchdown readout stays up
const CONTACT_LOAD_RAMP_S: float = 0.65 # s for the springs to take the car's weight at contact
const CONTACT_LOAD_FLOOR: float = 0.10 # tire capacity fraction at the first contact instant
# Fix Pass 24 (Item 1) - the boost economy (design of record:
# boost-economy.md in the project root). The meter is no
# longer a one-shot ration: it is a TANK that racing air
# refills. All quantities in the code's long-standing units
# (30 units = 1 s of boost at the shipped drain). The three
# dials are the owner's tuning surface - capacity, the
# starting stake, the air exchange rate. The drain and the
# boost POWER (the +9.0 tire_long term in _update_drive)
# are not economy dials and do not move in this pass.
const BOOST_CAPACITY: float = 120.0 # the tank: 4.0 s of boost
const BOOST_START_STOCK: float = 60.0 # the stake at race start: 2.0 s (the old whole ration)
const BOOST_DRAIN_PER_S: float = 30.0 # unchanged since Test 1
const BOOST_AIR_RATE: float = 10.0 # units paid per second of payable air, at CLEAN
const BOOST_PAY_MIN_AIR_S: float = 0.15 # s: flights shorter than this pay nothing (texture hops)
const BOOST_GRADE_MULT: Dictionary = {"CLEAN": 1.0, "SCRUBBED": 0.5, "CROSSED-UP": 0.2}
const PAY_FLASH_S: float = 0.35 # s the meter fill flashes after a payout lands
# Fix Pass 24 (Item 3): the air audit's sector width - the
# geography the audit maps a track's payable air onto.
const AUDIT_SECTOR_M: float = 250.0
# Fix Pass 24 (Item 2) put a fill BAR on the dash face at
# (0, 0.845, -0.543). Fix Pass 26 (Item 1) DELETES it: from
# the real seat the steering wheel hides it (the owner's
# run-20 screenshot shows the blue fill as a sliver behind
# a spoke). The meter is now a LIQUID FLASK set into the
# dash-TOP button row (see _build_cockpit) - the row the
# driver can actually see. FLASK_POS sits between the green
# LEAN button (-0.52) and the amber VIEW button (-0.35):
# sightlines from the eye anchor to that spot cross the
# wheel plane at radius ~0.33-0.42 m, OUTSIDE the rim band
# (0.155-0.245) and beyond the spokes' reach (0.20) at any
# wheel angle - the render proof's capture-25 sweep asserts
# it at centre and full lock both ways. The flask is a
# gauge, never a control: it is not registered as a dash
# control and has no grab zone.
const FLASK_POS: Vector3 = Vector3(-0.435, 0.93, -0.60) # dash top surface, in the button row
const FLASK_LIQ_MIN_H: float = 0.012 # m of liquid standing in the vessel at empty
const FLASK_LIQ_MAX_H: float = 0.078 # m at capacity (never brim-full)
const FLASK_SLOSH_K: float = 55.0 # the liquid spring, 1/s^2 (~1.2 Hz)
const FLASK_SLOSH_C: float = 5.2 # its damping - underdamped: lags, overshoots a little, settles
const FLASK_SLOSH_MAX_RAD: float = 0.26 # the surface's display cap
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
# Fix Pass 23: the FP10 loop spur is REMOVED (owner's
# verdict after run 19: "nuke it, we'll deal with it
# later"). The branch, the ring, its sibling driver and
# suspension, and all its presentation are gone; the home
# straight is one clean line and no branch state remains.
var lap_count: int = 0
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
var boost_meter: float = BOOST_START_STOCK
var dent_level: int = 0
# Fix Pass 24 (Item 1): the last payout's record - what the
# DIAG LAST PAY line and the stages read. _pay_for_landing
# rewrites it at EVERY graded landing (zeroed when the
# landing paid nothing), so it always states the last
# landing's ruling, not a stale one.
var last_pay_units: float = 0.0
var last_pay_air_s: float = 0.0
var last_pay_grade: String = "-"
# Fix Pass 24 (Item 2): the meter's rendered state - the
# fill fraction (stock / capacity) the meter draws, and
# the payout flash's remaining seconds (set by
# _pay_for_landing, decayed by _update_turbo_meter).
# Fix Pass 26 (Item 1): what draws them is the flask - the
# liquid's level (flask_level_h, mapped from the fraction)
# and its slosh spring (flask_tilt / flask_tilt_vel, two
# axes in rad, integrated in _update_turbo_meter from the
# car's measured acceleration; test_flask_accel* is the
# staging override, the test_pivot_accel pattern).
var turbo_fill_frac: float = 0.5
var pay_flash_t: float = 0.0
var flask_node: Node3D = null
var flask_liquid_pivot: Node3D = null
var flask_liquid_mi: MeshInstance3D = null
var flask_liquid_mat: StandardMaterial3D = null
var flask_level_h: float = 0.0
var flask_tilt: Vector2 = Vector2.ZERO
var flask_tilt_vel: Vector2 = Vector2.ZERO
var flask_prev_pos: Vector3 = Vector3.ZERO
var flask_prev_vel: Vector3 = Vector3.ZERO
var flask_have_prev: bool = false
var test_flask_accel_on: bool = false
var test_flask_accel: Vector3 = Vector3.ZERO
# Fix Pass 24 (Item 3): the air audit's recorder state (see
# debug_audit_begin / _pay_for_landing / _enter_air). All
# inert unless a test arms it - the shipped game never does.
var audit_on: bool = false
var audit_flights: Array = [] # Fix Pass 28: per-flight records [start_s, air_s, gross_units] - the piece-resolution view of the same bookings the sectors aggregate
var audit_sectors: Array[float] = []
var audit_income: float = 0.0
var audit_air_s: float = 0.0
var audit_flight_open: bool = false
var audit_flight_s: float = 0.0
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

# Fix Pass 13 (Item 1): the prep sequence is DELETED (owner's
# call - no sequence, no reaction game, no boost payout at the
# drop). The hang is: read the sway, hold the wheel, pick the
# moment. Touchdown connection state (see _land): the measured
# contact that grades the getaway.
var contact_grade: String = "-"
var contact_lat_speed: float = 0.0 # |lateral velocity| at contact, m/s
var contact_head_err: float = 0.0 # heading error vs road tangent at contact, deg
var contact_readout_t: float = 0.0 # seconds the touchdown readout stays up
var contact_transient_t: float = 0.0 # seconds of contact-governed tires left (see _land)
var contact_load_age: float = 0.0 # seconds since touchdown (the load ramp's clock)

# lean experiment
var lean_on: bool = false
var jitter_on: bool = true # Fix Pass 7 (Item 2): jitter experiment toggle, default ON
var view_gain_mode: int = 0 # Fix Pass 14 (Item 6): the view-coupling A/B - 0 = A (0.6x, as shipped through FP13), 1 = B (1.0x, camera = car). Session state, NOT persisted: every boot starts at A and the owner flips it from the dash.
var lean_neutral_x: float = 0.0
var lean_value: float = 0.0
var grip_mult: float = 1.0
var load_grip: float = 1.0 # FP14 (Item 5): mean road-load factor on the bleed (see GRIP_LOAD_MIN)
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
# Fix Pass 14 (Item 3): the springs are PER-CORNER now -
# susp_c/susp_cv in WHEEL_LOCALS order [FL, FR, RL, RR],
# integrated by _susp_integrate_corners on the main track.
# c_f/c_r/cv_f/cv_r remain as the corner MEANS: every pre-FP14
# reader (air-entry tests, landing checks, view heave, the
# body spring, the stages) reads the means unchanged, and the
# axle integrator (air, hang, done) still writes them -
# and mirrors them into the corners, grouped by axle, so the
# two states never desync.
var c_f: float = SUSP_REST
var c_r: float = SUSP_REST
var cv_f: float = 0.0
var cv_r: float = 0.0
var susp_c: Array[float] = [SUSP_REST, SUSP_REST, SUSP_REST, SUSP_REST]
var susp_cv: Array[float] = [0.0, 0.0, 0.0, 0.0]
var susp_geom: Array[float] = [0.0, 0.0, 0.0, 0.0] # per-corner road rise (support rise + its axle's jitter delta)
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
var pending_rebound: bool = false # FP14 (Item 1): the pending bounce is the spring-throw route
var air_from_rebound: bool = false # FP14 (Item 1): this flight began as a spring rebound
var air_basis0: Basis = Basis.IDENTITY # FP14 (Item 7): the takeoff basis a road flight's attitude builds from
var air_from_release: bool = false # FP14 (Item 1): this flight began as a drone release (a drop, not a jump)
var rebound_gate_vy: float = 0.0 # FP14 (Item 1): impact vy of an armed energy return (0 = unarmed)
var deep_hit_age: float = 9.0 # FP14 (Item 2): seconds since the last deep compression (route-2 evidence)
var bounce_chain: int = 0 # FP14 (Item 1): spring throws since the last settled ground run
var grounded_t: float = 0.0 # FP14 (Item 1): continuous grounded seconds (chain re-arm clock)
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
var sup_lat: Array[float] = [0.0, 0.0, 0.0, 0.0] # Fix Pass 21: each wheel's lateral offset at its own s
# Fix Pass 21 (Items 1+2): PER-CORNER load state. wheel_kv is
# the vertical curvature of the surface AT the wheel's contact
# patch (see _patch_kv - bank unwind and lateral surface fall
# count, which the centreline kv cannot see); wheel_load is the
# corner's own crest-load factor from it. load_f/load_r survive
# as the corner MEANS of their axle (every pre-FP21 reader -
# the FP15 telegraph, the rebound floor, the stages - keeps its
# meaning). wheel_air is the corner's separation state: the
# road at that patch is falling away faster than the corner's
# ballistic arc (wheel_load ~zero), so the corner dangles at
# full droop and carries nothing. wheel_air_frames is the
# cumulative evidence counter the stages read.
var wheel_kv: Array[float] = [0.0, 0.0, 0.0, 0.0]
var wheel_load: Array[float] = [1.0, 1.0, 1.0, 1.0]
var wheel_air: Array[bool] = [false, false, false, false]
var wheel_air_frames: Array[int] = [0, 0, 0, 0]
var edge_roll: float = 0.0
var view_node: Node3D # seat-stack node carrying suspension view motion

# Dangle state: line slack, catch blend, and a lagged orientation
# direction (compliance - the car settles a beat behind the swing
# instead of being rigidly framed to the pivot).
# Fix Pass 10 (Item 2): pivot_pos IS the rig's pivot (anchor_pos
# - no procedural offset). The pivot state (names kept from the
# flight era - see the constants block): position, slew
# velocity, measured acceleration the pendulum feeds on, the
# jib's heading, and the slew's target list (exactly one
# station since FP15 - no retrace exists).
var pivot_pos: Vector3 = Vector3.ZERO # the jib pivot (== anchor_pos)
var carrier_vel: Vector3 = Vector3.ZERO
var carrier_accel: Vector3 = Vector3.ZERO # measured, lightly filtered
var carrier_yaw: float = 0.0 # the jib's heading
var carrier_path: Array[Vector3] = [] # slew targets: [the drop station]
var carrier_wp: int = 0
# Fix Pass 11 (Item 3): time spent at the station waiting for
# the arrival yaw gate (bounded - see _step_crane).
var station_wait_t: float = 0.0
var orient_yaw: float = 0.0 # the car's facing under the lines (springy)
var orient_yaw_v: float = 0.0
var dip_t: float = -1.0 # flown-dip progress; -1 = not dipping
var dip_depth: float = 0.0
var dip_timer: float = 2.0
var dip_seed: int = 0
# Fix Pass 14 (Item 8) gave the flying carrier a station
# WANDER so the hang never settled to a clean Lissajous.
# Fix Pass 15 (Item 2): the crane's fixed pivot gets its
# irregularity honestly instead - desert GUSTS stepping the
# station target (below) plus the jib's FLEX lagging the
# load (flex_off, a first-order lag on the swing direction).
var gust_seed: int = 0
var gust_t: float = 0.0
var gust_off: Vector2 = Vector2.ZERO
var flex_off: Vector2 = Vector2.ZERO
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
# Fix Pass 15 (Item 1): the telegraph state. tire_ratio is the
# demand-vs-capacity max over the two axles (0 outside DRIVE);
# tire_ratio_axle names the axle nearer its limit (0 front,
# 1 rear, -1 = both); tire_band is the ratio
# mapped through the band edges. edge_rumble_now / edge_scrape_now
# are the support-state strengths from _update_suspension.
var tire_ratio: float = 0.0
var tire_ratio_axle: int = 0
var tire_band: float = 0.0
var edge_rumble_now: float = 0.0
var edge_scrape_now: float = 0.0
var sup_over: Array[float] = [0.0, 0.0, 0.0, 0.0] # per-wheel overshoot past the rim, m
var audio_song_now: float = 0.0 # smoothed song gain (the band fraction), 0..1
var audio_rumble_now: float = 0.0 # smoothed off-road rumble gain, 0..1
var audio_scrape_now: float = 0.0 # smoothed edge scrape gain, 0..1
var rumble_haptic_now: float = 0.0 # controller rumble strength, 0..1 (final-stretch warning)
var song_player: AudioStreamPlayer
var rumble_player: AudioStreamPlayer
var scrape_player: AudioStreamPlayer
var dust_emitters: Array[GPUParticles3D] = [] # per-wheel contact-patch dust (FL, FR, RL, RR)

# --- nodes ---
var car: Node3D
var car_body: Node3D
var nose_mi: MeshInstance3D
var wheel_node: Node3D # tilt node (stood-up wheel plane)
var wheel_spin: Node3D # spin node inside it (rotates about the wheel axis)
var lean_needle: MeshInstance3D
# Fix Pass 15 (Item 2): the crane rig's nodes (built once,
# posed per hang by _place_crane, hidden outside MODE_HANG).
var crane: Node3D
var crane_foot: MeshInstance3D
var crane_post: MeshInstance3D
var crane_pad: MeshInstance3D
var crane_jib: MeshInstance3D
var crane_counter: MeshInstance3D
var crane_trolley: MeshInstance3D
var crane_spreader: Node3D
var line_mis: Array[MeshInstance3D] = []

var dash_ctl_nodes: Array[Node3D] = []
var dash_ctl_kinds: Array[String] = []
var state_label: Label3D
var panel_label: Label3D
var contact_label: Label3D # Fix Pass 13 (Item 1): the touchdown readout (was the prep prompt)
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
# --- Fix Pass 20: the DROP BUTTON (the lever is retired) ---
# History: FP11 built the release as a big physical lever;
# FP12/13 moved it twice; FP15 put it on the dash face;
# FP16/17 rebuilt its grab twice. The owner's run-18 verdict
# retired the mechanism: "Lever is still not consistent...
# Im sick of going round and round with the lever, make it
# a button for now." The reason, for the record: a lever pull
# is a MULTI-SAMPLE act - zone entry, squeeze threshold,
# sustained grip, swept-hand tracking through a throw - and
# every sample is a fresh chance for the live grip/tracking
# stream to flicker, while staging's perfect 0/1 squeezes
# could never reproduce a failure that lived between the
# samples. A button is a SINGLE threshold event in a fat
# zone: the one mechanism staging can certify honestly.
# The button is a DASH CONTROL (kind "drop", registered
# last so no earlier index moves) standing on the dash FACE
# where the lever stood - same spot (the FP15 placement:
# right of the wheel hub, on its bracket), same persisted
# side (the settings key lever/left predates the button and
# is kept), same SIDE toggle + M key. Its release semantics
# live in _press_drop_button; the dash path gives it the fat
# 0.15 m volume, the Schmitt latch and the dip for free.
# PLACEMENT (zone-driven, as FP15 found): the button's point
# (0.42, 0.70, -0.44) sits 0.50 m from the wheel hub (outside
# the 0.40 grab radius, so a press is never a wheel grab) and
# >= 0.29 m from every dash-top button's point (outside
# their 0.15 zones), mirrored on the left face.
# Fix Pass 26 (Item 3): the button comes UP, on the owner's
# run-20 order ("drop button needs to come up") - FACE_Y
# 0.70 -> 0.85, the upper dash face, its bracket top flush
# with the slab top. The zone math still holds at the new
# point: 0.44 m from the hub (outside the grab radius),
# 0.19 m from the nearest dash-top button's point (restart
# right / view left, outside their 0.15 zones), 0.11 m clear
# of the rim's outer edge in x (the wheel's sweep never
# reaches it), and clear of the FP26 flask on the dash top
# (0.21 m from the mirrored-left point). Mirroring and the
# persisted side are untouched - _apply_drop_btn_side reads
# these constants.
const DROP_BTN_FACE_X: float = 0.42 # |x| of the button on the face (the lever's spot)
const DROP_BTN_FACE_Y: float = 0.85 # FP26 (Item 3): raised to the upper dash face (was 0.70)
const DROP_BTN_FACE_Z: float = -0.44
var drop_btn_node: Node3D # the registered dash control node
var drop_btn_bracket: MeshInstance3D
var drop_btn_left: bool = false # persisted mirror (lefty option)
var drop_btn_base_z: float = DROP_BTN_FACE_Z # the dip's rest (articulation moves z, not y)
# (FP20's felt-refusal grind state lived here until Fix Pass
# 22 deleted the SPENT outcome it served - see _press_drop_button.)
var xr_iface: XRInterface # stored at rig build for haptics
# Fix Pass 3 live diagnostics (panel DIAG block, refreshed at ~5 Hz):
# raw grip-channel values per hand, exactly as the runtime delivers.
var diag_grip: Dictionary = {"L": 0.0, "R": 0.0}
var diag_click: Dictionary = {"L": false, "R": false}
# (diag_force was deleted in Fix Pass 16 - the channel it read
# has no binding in any interaction profile; see Item 0.)
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
# Fix Pass 16 (Item 1): grab-rebuild state. prev_hand_pos feeds
# the SWEPT zone tests (the segment the hand travelled this
# frame, not just its endpoint - a fast hand can no longer pass
# through a volume unsampled). grab_in_band marks a held grab
# whose squeeze has dipped into the hysteresis rescue band
# (below the old 0.65 cut, above GRIP_RELEASE): each entry is a
# grab the FP15 latch would have dropped, and Item 5's telemetry
# counts them. side_hold_t is Item 4's deliberate-hold clock for
# the SIDE button. cand_kind/cand_ctl are the per-hand CANDIDATE
# (nearest control in reach, gripped or not) that drives the
# rep cue and the acquisition tick.
var prev_hand_pos: Dictionary = {"L": Vector3.ZERO, "R": Vector3.ZERO}
var prev_hand_valid: Dictionary = {"L": false, "R": false}
var grab_in_band: Dictionary = {"L": false, "R": false}
var side_hold_t: Dictionary = {"L": 0.0, "R": 0.0}
var cand_kind: Dictionary = {"L": "", "R": ""}
var cand_ctl: Dictionary = {"L": -1, "R": -1}
var cand_tick_t: Dictionary = {"L": 0.0, "R": 0.0}
var rep_dot: Dictionary = {} # hand -> the rep's origin-dot mesh (the candidate/latch cue)
# Fix Pass 16 (Item 3): the passenger hand's rim attachment -
# while the OTHER hand drives the wheel, a gripping hand on the
# rim has its point stored in wheel-spin local space and its
# rep rides the rim (see _update_rim_attach).
var rim_attach: Dictionary = {"L": false, "R": false}
var rim_local: Dictionary = {"L": Vector3.ZERO, "R": Vector3.ZERO}
# Fix Pass 16 (Item 5): grab telemetry. grab_events is the
# session's event ring (also written to user://grab_log.txt);
# the counters and per-hand session squeeze peaks ride along so
# a flatlined channel or a low-peaking squeeze is visible in
# the log, not just in a screenshot.
var grab_events: Array[String] = []
var grab_last_event: String = ""
var grab_fire_count: int = 0
var grab_wheel_count: int = 0
var grab_drop_count: int = 0 # FP20: the drop button's presses (was the lever's latch count)
var grab_early_count: int = 0
var grab_chatter_count: int = 0
var grab_peak: Dictionary = {"L": 0.0, "R": 0.0}
var grab_log_file: FileAccess = null
var prev_zone: Dictionary = {"L": -1, "R": -1}
# Fix Pass 20 (Item 3): the last release's heading record -
# the car's heading at the moment of release against the
# drop section's travel direction, both degrees, and their
# wrapped difference. Written by _do_release on EVERY drop
# (and logged as a RELEASE grab event), so a backwards drop
# leaves its ruling in the driver's own log instead of
# vanishing. -1 / 0 until the first release.
var last_release_s: float = -1.0
var last_release_hdg_deg: float = 0.0
var last_release_sec_deg: float = 0.0
var last_release_err_deg: float = 0.0
# Fix Pass 17 (Item 2): the grab log's build tag, stamped into
# each launch's session header next to the wall-clock time.
# Updated per pass, like the README's own accounting.
const GRAB_LOG_BUILD: String = "FP24 (base 1669c3e)"
const GRAB_LOG_MAX_BYTES: int = 262144 # 256 KB tail kept across launches


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
	# Fix Pass 16 (Item 5): the grab session log - one line per
	# grab event at user://grab_log.txt (next to settings.cfg).
	# If a grab ever fails silently in the headset again, this
	# file is the witness the staged suite structurally cannot
	# be. Fix Pass 17 (Item 2): the log APPENDS across launches -
	# FP16 truncated per launch, so the run-16 upload carried
	# only the owner's last short session and the attempts that
	# failed him were already gone. Each launch stamps a session
	# header (build tag + wall clock) and the file is tail-
	# trimmed to GRAB_LOG_MAX_BYTES, oldest lines first, so the
	# next upload carries every attempt since the build landed.
	var prior17: String = ""
	if FileAccess.file_exists("user://grab_log.txt"):
		var old17: FileAccess = FileAccess.open("user://grab_log.txt", FileAccess.READ)
		if old17 != null:
			prior17 = old17.get_as_text()
			old17.close()
	while prior17.length() > GRAB_LOG_MAX_BYTES:
		var nl17: int = prior17.find("\n")
		if nl17 < 0:
			prior17 = ""
			break
		prior17 = prior17.substr(nl17 + 1)
	grab_log_file = FileAccess.open("user://grab_log.txt", FileAccess.WRITE)
	if grab_log_file != null:
		if prior17 != "":
			grab_log_file.store_string(prior17)
			if not prior17.ends_with("\n"):
				grab_log_file.store_line("")
		grab_log_file.store_line("=== SESSION %s %s ===" % [GRAB_LOG_BUILD, Time.get_datetime_string_from_system()])
		grab_log_file.store_line("grab log - events: LAT latch, FIRE activation, REL latch release, NOLAT zone entry unlatched, RIM passenger attach, BTN the drop button (FIRE on the chains, any hang phase / PRESS in drive or air), RELEASE the drop's heading record (HDG vs SEC travel direction, ERR the difference), PAY a graded landing's boost payout (units paid, AIR the flight's seconds, the touchdown grade)")
		grab_log_file.flush()
	_load_settings()
	_build_environment()
	track_data["ribbon"] = _build_ribbon()
	track_data["circuit"] = _build_circuit()
	track_data["lab"] = _build_lab() # Fix Pass 28: the feature lab
	_build_car()
	_build_crane()
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
		if what == NOTIFICATION_EXIT_TREE and grab_log_file != null:
			grab_log_file.close() # FP16 (Item 5): the session log ends with the session
			grab_log_file = null
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
	rep_dot[hand] = origin_dot # FP16 (Item 1): the candidate/latch cue scales this dot


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
	# S1: home straight
	_walk(380, 0.0, 0.0, 0.0, false)
	feats["home_len"] = 380.0
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
	return d



func _build_lab() -> Dictionary:
	# Fix Pass 28: THE FEATURE LAB. The owner's method call
	# (2026-10-30): "prototype-first - candidate features as
	# test pieces, assemble the track from what proves out."
	# A dedicated open course stringing EIGHT candidate
	# pieces in sequence, each approached from a clean flat
	# entry so every piece is judged from the same state,
	# each carrying a roadside number board (PIECE 1..8) so
	# verdicts map to pieces. Every piece is sized from THIS
	# car's measured envelope - top speed 48 m/s, lateral
	# grip limit 11.0 m/s^2, the staged ~1.2 s / ~36 m flight
	# at 30 m/s - never from SCR's shapes, which encode a
	# different car (owner: "scrs tracks are probably no
	# good for our physics"). The circuit and the test
	# ribbon are untouched; their censuses must not move.
	# Piece spans land in features["pieces"] as
	# [name, s0, s1, entry_speed] - stage 58 drives and
	# audits against them, and the README's per-piece table
	# is printed from the same numbers.
	var root := Node3D.new()
	root.name = "TrackLab"
	add_child(root)
	b_pts = []
	b_tan = []
	b_bank = []
	b_curv = []
	b_gap = []
	_gen_pos = Vector3(800.0, 30.0, 600.0)
	_gen_yaw = 0.0
	_gen_phi = 0.0
	_gen_bank = 0.0
	_gen_append(false, 0.0)
	var pieces: Array = []
	# HEAD: the Drop Start flat (the drop station is s 2 on
	# every track; 90 m of flat runup and settle).
	_walk(90, 0.0, 0.0, 0.0, false)
	# --- PIECE 1: DRUMBEAT ROWS x3 gentlenesses -----------
	# Flat-based hump rows (the FP8 template: climb in at
	# +A, over the top to -A, flatten) at three shapes
	# bracketing the FP21 finding. The middle row IS the
	# ribbon's spec (A=11, top rate 0.021, kv ~0.020 - the
	# control: it flies ~1 s hops at cruise, measured). The
	# band the piece hunts (0.1-0.4 s) lives at SHARP SMALL
	# humps - a short, strong top curvature unloads briefly
	# where a spread one arcs long - so the gentle leg is
	# small and sharp (A=7 over a 9 m top, kv ~0.027) and
	# the strong leg is tall and sharper still (A=13, kv
	# ~0.045). (First form, probed and replaced in-pass: an
	# amplitude-only bracket - the gentle leg's kv ~0.016
	# never unloaded at 24 (v^2 kv ~8.9 < g) and the spread
	# rows all flew ~1 s regardless of amplitude.) Four
	# humps per row, a 25 m settle between rows.
	var p1_s0: float = float(b_pts.size() - 1)
	var p1_rows: Array = []
	var row_specs: Array = [
		[7.0, 10, 0.020, 9, 0.027, 10],
		[11.0, 13, 0.016, 19, 0.021, 13],
		[13.0, 11, 0.024, 10, 0.045, 11]]
	for ri: int in row_specs.size():
		var rs: Array = row_specs[ri]
		var row_s0: float = float(b_pts.size() - 1)
		for hump: int in 4:
			_walk(int(rs[1]), 0.0, deg_to_rad(float(rs[0])), 0.0, false, float(rs[2]))
			_walk(int(rs[3]), 0.0, deg_to_rad(-float(rs[0])), 0.0, false, float(rs[4]))
			_walk(int(rs[5]), 0.0, 0.0, 0.0, false, float(rs[2]))
		p1_rows.append([row_s0, float(b_pts.size() - 1)])
		if ri < row_specs.size() - 1:
			_walk(25, 0.0, 0.0, 0.0, false)
	pieces.append(["P1 DRUMBEAT ROWS", p1_s0, float(b_pts.size() - 1), 24.0])
	_walk(60, 0.0, 0.0, 0.0, false)
	# --- PIECE 2: THE FLAIR, FORMALISED x2 severities -----
	# The run-18 discovery as FP21 convicted it: at a banked
	# sweeper's exit the bank unwinds, the falling side's
	# surface drops away under its wheels (patch curvature
	# the centreline cannot see), and that side catches air
	# while the held side stays loaded. Two left sweepers
	# with the house shaped unwind (3 at 0.03, then 0.075):
	# (a) MILD - R~60, bank 26 (circuit A's bank on a
	# tighter radius); (b) RUN-18 - R~45, bank 34 (the
	# ribbon corner's bank). The falling side is the RIGHT.
	var p2_s0: float = float(b_pts.size() - 1)
	_walk(94, deg_to_rad(90.0) / 94.0, 0.0, deg_to_rad(26.0), false)
	_walk(3, 0.0, 0.0, 0.0, false, 0.006, 0.03)
	_walk(17, 0.0, 0.0, 0.0, false, 0.006, 0.075)
	var p2_mild: Array = [p2_s0, float(b_pts.size() - 1)]
	_walk(45, 0.0, 0.0, 0.0, false)
	var p2b_s0: float = float(b_pts.size() - 1)
	_walk(70, deg_to_rad(90.0) / 70.0, 0.0, deg_to_rad(34.0), false)
	_walk(3, 0.0, 0.0, 0.0, false, 0.006, 0.03)
	_walk(17, 0.0, 0.0, 0.0, false, 0.006, 0.075)
	var p2_run18: Array = [p2b_s0, float(b_pts.size() - 1)]
	pieces.append(["P2 THE FLAIR", p2_s0, float(b_pts.size() - 1), 24.0])
	_walk(55, 0.0, 0.0, 0.0, false)
	# --- PIECE 3: CREST LAUNCHES x3 steepnesses -----------
	# The tumble country, measured: three crests launching
	# at +8 / +14 / +20 deg, each top swept sharp (phi rate
	# 0.055) so the launch angle is the angle, each landing
	# slope-matched on its own descent. Entry pinned 30.
	# Stage 58 records flight time and the body's pitch
	# story per crest - where the car starts wanting to go
	# over is data for the flight-model question.
	var p3_s0: float = float(b_pts.size() - 1)
	var p3_crests: Array = []
	for li: int in 3:
		var lang: float = [8.0, 14.0, 20.0][li]
		var crest_s0: float = float(b_pts.size() - 1)
		_walk(40, 0.0, deg_to_rad(lang), 0.0, false, 0.030)
		_walk(40, 0.0, deg_to_rad(-lang), 0.0, false, 0.055)
		p3_crests.append([crest_s0, float(b_pts.size() - 1)])
		if li < 2:
			_walk(40, 0.0, 0.0, 0.0, false, 0.020)
	pieces.append(["P3 CREST LAUNCHES", p3_s0, float(b_pts.size() - 1), 30.0])
	# The settle must be FLAT before the chasm's lip: at
	# the default pitch rate the -20 deg landing tail is
	# still descending 16 m out from the lip (measured
	# -3.2 deg there, -8.7 at 32 m), so piece 4 would be
	# entered off a slope like no other piece. An explicit
	# 0.020 return completes the pitch in ~18 steps and
	# leaves true flat ahead of the lip (FP28 in-pass
	# fix; nothing downstream moves).
	# The settle is LONG (125 m) for a measured reason:
	# crest 3's flight at the pinned 30 lands ~52 m past
	# the piece's recorded end, and its rebound second
	# flight carries ~45 m further - on the first form's
	# 55 m settle the continuous audit lap touched down
	# at s 1301 and was still mid-rebound when the lip
	# arrived at 1303, separated at the lip's base with a
	# flat pitch, and dropped into the chasm (stage 58's
	# audit, in-pass). The pieces must not overlap when
	# driven continuously: touchdown, rebound, and a
	# settled ground run all complete before the lip.
	_walk(125, 0.0, 0.0, 0.0, false, 0.020)
	# --- PIECE 4: THE MEASURED CHASM ----------------------
	# One slope-matched gap at the staged flight envelope:
	# the ribbon gap's proven shape (lip +10 shaped, gap
	# phi +2, landing -3.4) stretched to 28 m of air. At the
	# 30 m/s entry the ballistic clears ~35-42 m before the
	# landing straight falls to meet it (the feasibility
	# arithmetic is in the README; stage 58 proves the
	# crossing at the pinned entry before it ships).
	_walk(2, 0.0, deg_to_rad(10.0), 0.0, false, 0.012, 0.10)
	_walk(8, 0.0, deg_to_rad(10.0), 0.0, false, 0.034, 0.10)
	var p4_s0: float = float(b_pts.size() - 1)
	var lab_gap_s0: float = float(b_pts.size())
	_walk(28, 0.0, deg_to_rad(2.0), 0.0, true, 0.020)
	var lab_gap_s1: float = float(b_pts.size())
	_walk(40, 0.0, deg_to_rad(-3.4), 0.0, false, 0.020)
	pieces.append(["P4 THE CHASM", p4_s0, float(b_pts.size() - 1), 30.0])
	_walk(60, 0.0, 0.0, 0.0, false)
	# --- PIECE 5: OFF-CAMBER S ----------------------------
	# Law 1's proof: no air at all, attention only. Two
	# R~70 corners (70 deg each) at ADVERSE bank - the
	# surface leans OUT of the turn, adding ~1.7 m/s^2 to
	# the lateral demand at 24 m/s (v^2/R = 8.2 + 1.7 =
	# 9.9 against the 11.0 limit): at the limit's edge,
	# sliding, survivable at the pursuit pace. (First form
	# probed and replaced in-pass: R55 summed to 12.2 -
	# over the limit - and the speed-managed pursuit,
	# which caps by curvature alone and cannot know the
	# bank is adverse, slid off the outside into a hang.)
	# Right then left, an 18 m link between, bank unwound
	# on the exits.
	var p5_s0: float = float(b_pts.size() - 1)
	_walk(85, -deg_to_rad(70.0) / 85.0, 0.0, deg_to_rad(10.0), false, 0.006, 0.020)
	_walk(18, 0.0, 0.0, 0.0, false, 0.006, 0.060)
	_walk(85, deg_to_rad(70.0) / 85.0, 0.0, deg_to_rad(-10.0), false, 0.006, 0.020)
	_walk(18, 0.0, 0.0, 0.0, false, 0.006, 0.060)
	pieces.append(["P5 OFF-CAMBER S", p5_s0, float(b_pts.size() - 1), 24.0])
	_walk(55, 0.0, 0.0, 0.0, false)
	# --- PIECE 6: COMPRESSION -> REBOUND ------------------
	# A dip-and-crest pair tuned to FP14's rebound: fall
	# -14 into a 10 m valley (both transitions concave -
	# the springs load), climb +14 out, and crest off to
	# -8 sharp (0.045) so the stored energy and the crest
	# unload arrive together: land, compress, second
	# flight by design. Entry pinned 28.
	var p6_s0: float = float(b_pts.size() - 1)
	_walk(25, 0.0, deg_to_rad(-14.0), 0.0, false, 0.030)
	_walk(10, 0.0, 0.0, 0.0, false, 0.030)
	_walk(25, 0.0, deg_to_rad(14.0), 0.0, false, 0.030)
	_walk(12, 0.0, deg_to_rad(-8.0), 0.0, false, 0.045)
	pieces.append(["P6 COMPRESSION-REBOUND", p6_s0, float(b_pts.size() - 1), 28.0])
	_walk(30, 0.0, 0.0, 0.0, false, 0.020)
	_walk(25, 0.0, 0.0, 0.0, false)
	# --- PIECE 7: EDGE SLALOM -----------------------------
	# 240 m of flat with marker blocks alternating ON the
	# edge line (lat +/-5.85) every 30 m: thread a marker
	# closely and the outside wheels ride into the
	# straddle zone (support fades past the edge, fully
	# gone 1.17 m past it) - the straddle physics as
	# line-choice gameplay. (First form probed in-pass:
	# markers at +/-4.7 never engaged the straddle at all
	# - a car centred on one keeps its outside wheels
	# 0.5 m inside the edge, fully supported.) The
	# markers themselves are furniture (see _build_lab_
	# furniture); the road is plain flat.
	var p7_s0: float = float(b_pts.size() - 1)
	_walk(240, 0.0, 0.0, 0.0, false)
	pieces.append(["P7 EDGE SLALOM", p7_s0, float(b_pts.size() - 1), 24.0])
	_walk(35, 0.0, 0.0, 0.0, false)
	# --- PIECE 8: THE TAXED STRAIGHT ----------------------
	# Law 1 on the spend straight: 225 m of swells at
	# +/-3 deg, then 225 m at +/-6 deg, 90 m wavelength.
	# Boost country (audit window pins 40) that still
	# pitches and heaves under the driver - no cruising.
	# The second half's phi rate is doubled (0.0095): a
	# sinusoidal +/-6 at 0.0047 measured ZERO air at 40 in
	# the in-pass probe (v^2 kv ~7.5 - heave only); the
	# sharpened crests (kv ~0.0095, v^2 kv ~15) hop.
	var p8_s0: float = float(b_pts.size() - 1)
	for k8: int in 5:
		_walk(45, 0.0, deg_to_rad(3.0 if k8 % 2 == 0 else -3.0), 0.0, false, 0.0024)
	for k8b: int in 5:
		_walk(45, 0.0, deg_to_rad(-6.0 if k8b % 2 == 0 else 6.0), 0.0, false, 0.0095)
	pieces.append(["P8 TAXED STRAIGHT", p8_s0, float(b_pts.size() - 1), 40.0])
	_walk(60, 0.0, 0.0, 0.0, false)
	var feats: Dictionary = {
		"gap_s0": lab_gap_s0, "gap_s1": lab_gap_s1,
		"gap2_s0": lab_gap_s0, "gap2_s1": lab_gap_s1,
		"ext_s0": -1.0, "sweeper_s0": -1.0, "sweeper_s1": -1.0,
		"stairs_s0": -1.0, "stairs_s1": -1.0,
		"pieces": pieces,
		"subs": {"p1_rows": p1_rows, "p2_mild": p2_mild,
			"p2_run18": p2_run18, "p3_crests": p3_crests}}
	var d: Dictionary = _finalize_track(false, feats)
	d["root"] = root
	d["sections"] = true
	_activate_track(d)
	_build_track_meshes(d)
	_build_lab_furniture(root, pieces)
	return d


func _build_lab_furniture(root: Node3D, pieces: Array) -> void:
	# Fix Pass 28: the lab's furniture - one number board
	# per piece at its entry (the verdict map), and piece
	# 7's slalom markers. Runs with the lab ACTIVE (the
	# builder's order), so _frame_at reads the lab's spine.
	# Boards stand on the RIGHT at +(HALF_WIDTH + 1.7): a
	# post and a billboarded Label3D in the state label's
	# amber - billboarded so the number reads from the
	# driver's seat at any approach angle, on any heading
	# the course has turned to by then.
	for pi: int in pieces.size():
		var s_b: float = float(pieces[pi][1]) - 2.0
		var frb: Dictionary = _frame_at(s_b)
		var base: Vector3 = Vector3(frb["pos"]) + Vector3(frb["side"]) * (HALF_WIDTH + 1.7)
		var up: Vector3 = frb["up"]
		var bnode := Node3D.new()
		bnode.name = "PieceBoard%d" % (pi + 1)
		root.add_child(bnode)
		_box(bnode, Vector3(0.22, 3.2, 0.22), base + up * 1.6, _mat(Color(0.2, 0.2, 0.22)))
		var lab := Label3D.new()
		lab.name = "PieceLabel"
		lab.text = "PIECE %d" % (pi + 1)
		lab.font_size = 96
		lab.pixel_size = 0.0075
		lab.modulate = Color(1.0, 0.85, 0.2)
		lab.outline_size = 12
		lab.outline_modulate = Color(0.05, 0.05, 0.06)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.position = base + up * 3.7
		bnode.add_child(lab)
	# Piece 7's markers: bright blocks ON the surface at
	# the edge line (lat +/-5.85), alternating every 30 m
	# from 15 m in - threading one puts the outside
	# wheels on the straddle fade.
	var p7: Array = pieces[6]
	for mk: int in 8:
		var s_m: float = float(p7[1]) + 15.0 + float(mk) * 30.0
		var frm: Dictionary = _frame_at(s_m)
		var lat_m: float = 5.85 if mk % 2 == 0 else -5.85
		var pos_m: Vector3 = Vector3(frm["pos"]) + Vector3(frm["side"]) * lat_m + Vector3(frm["up"]) * 0.31
		_box(root, Vector3(0.55, 0.6, 0.55), pos_m, _mat_unshaded(Color(1.0, 0.72, 0.10)), "SlalomMarker%d" % mk)


func _project_wide_s(pos: Vector3) -> float:
	# Whole-track nearest sample (coarse then refined) - used
	# when the crane needs a main-track fall origin with no
	# trustworthy hint (off-station releases, FP22).
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
	# dash's purple button / desktop V) - a track switch is
	# a full reset.
	if not track_data.has(tname):
		return
	active_track = tname
	_activate_track(track_data[tname])
	start_race()
	_update_panel()


func _cycle_track() -> void:
	# Fix Pass 28: the purple button / V key cycles the full
	# roster - circuit -> ribbon -> lab -> circuit (FP10's
	# two-way toggle, extended for the feature lab).
	var order: Array[String] = ["circuit", "ribbon", "lab"]
	_set_track(order[(order.find(active_track) + 1) % order.size()])


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
	# Fix Pass 18 (micro): the main field is ASPHALT GREY
	# (was near-black 0.07/0.07/0.09, which read brown
	# against the tan desert - the owner: "more road
	# colored, not brown"). Neutral with a faint cool bias
	# so the warm sun cannot push it back toward tan; it
	# separates from the desert (0.76/0.62/0.42) by hue AND
	# value. Colour only: no geometry, no markings change -
	# the amber centre band and edge strips keep their
	# identity, and the band's step over the surface is now
	# carried by hue plus ~2x luminance (was ~8x luminance
	# over the near-black; see the FP15 note below, whose
	# step figure predates this re-base).
	# Fix Pass 18 (micro): the main field goes from
	# near-black (0.07, 0.07, 0.09) to ASPHALT GREY - the
	# owner's word was "more road colored, not brown". Cool
	# neutral, a clear step DOWN in luminance from the tan
	# desert (0.76, 0.62, 0.42) and up from the old field,
	# so the ribbon separates from the terrain by value as
	# well as hue. Colour only: no geometry, fog, or light
	# changes in this pass; the tracks pass owns those.
	var surf_c := Color(0.30, 0.30, 0.33)
	var skirt_c := Color(1.0, 0.5, 0.05)
	var bot_c := Color(0.55, 0.27, 0.03)
	var edge_c := Color(1.0, 0.72, 0.10)
	# Fix Pass 15 (Item 4) baked a CONTINUOUS centre band
	# into this surface (three strips per quad: asphalt,
	# band, asphalt) against the invisible-road contrast
	# failure. Fix Pass 20 (Item 2) REMOVES it on the owner's
	# run-18 verdict - the band only became visible at all
	# with FP18's winding fix, and what he saw was "one long
	# stripe, not what I wanted. going down center." The
	# surface is one full-width asphalt quad per segment
	# again; the grey field + the dashed amber edge strips
	# carry the road until the tracks pass designs the
	# SECTIONED markings he actually asked for. Smoke stage
	# 45 now asserts the band's ABSENCE for both tracks.
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
		# the surface: one full-width asphalt quad (FP20
		# removed the FP15 centre band - see the note above)
		_add_quad_m(surf_pos, surf_nrm, surf_col, l0, r0, r1, l1, up_avg, surf_c)
		# box-section sides (skirts) + underside
		_add_quad_m(skirt_pos, skirt_nrm, skirt_col, l0, l1, bl1, bl0, -side_avg, skirt_c)
		_add_quad_m(skirt_pos, skirt_nrm, skirt_col, r1, r0, br0, br1, side_avg, skirt_c)
		_add_quad_m(skirt_pos, skirt_nrm, skirt_col, bl1, br1, br0, bl0, -up_avg, bot_c)
		# edge strips, raised 0.02 (unshaded: they stay bright at distance)
		# Fix Pass 11 (Item 5): DASHED (3 m on / 2 m off) - optic
		# flow for the raised top speed; a continuous strip on a
		# flat untextured surface gives the eye nothing temporal
		# to measure speed against.
		if i % 5 < 3:
			_add_quad_m(edge_pos, edge_nrm, edge_col,
				l0 + u0 * 0.02, l0 + s0 * EDGE_STRIP_W + u0 * 0.02, l1 + s1 * EDGE_STRIP_W + u1 * 0.02, l1 + u1 * 0.02,
				up_avg, edge_c)
			_add_quad_m(edge_pos, edge_nrm, edge_col,
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
	# Fix Pass 27: the lines are painted on the road (see
	# _add_line_stripe) - start at s 2.0 on both tracks, plus
	# the finish at the ribbon's end on the open track. On the
	# closed circuit start IS the finish (same s, one stripe).
	var line_pos := PackedVector3Array()
	var line_nrm := PackedVector3Array()
	var line_col := PackedColorArray()
	_add_line_stripe(line_pos, line_nrm, line_col, 2.0)
	if not bool(d["closed"]):
		_add_line_stripe(line_pos, line_nrm, line_col, track_len - 2.0)
	# Fix Pass 28: the lab wears the BORN-IN SECTION rhythm
	# (the new track's presentation, prototyped here): a
	# transverse stripe every 15 m - the sections the owner
	# asked for in run 16 ("lines/sections on the road... to
	# visually sell speed and distance"), designed in from
	# the first mesh instead of retrofitted. At racing pace
	# (24-36 m/s) 15 m spacing reads ~2 stripes per second.
	if bool(d.get("sections", false)):
		var sec_s: float = 17.0
		while sec_s < track_len - 4.0:
			_add_section_stripe(line_pos, line_nrm, line_col, sec_s)
			sec_s += 15.0
	var troot: Node3D = d["root"]
	_add_mesh(surf_pos, surf_nrm, surf_col, "TrackSurface", false, troot)
	_add_mesh(skirt_pos, skirt_nrm, skirt_col, "TrackSkirt", false, troot)
	_add_mesh(edge_pos, edge_nrm, edge_col, "TrackEdges", true, troot)
	_add_mesh(stilt_pos, stilt_nrm, stilt_col, "Stilts", false, troot)
	_add_mesh(line_pos, line_nrm, line_col, "TrackLine", true, troot)
	_build_gantry(2.0, "START", troot)
	if not bool(d["closed"]):
		_build_gantry(track_len - 2.0, "FINISH", troot)


func _add_quad(pp: PackedVector3Array, nn: PackedVector3Array, cc: PackedColorArray,
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	# two triangles a-b-c, a-c-d (CCW seen from the normal side)
	for v: Vector3 in [a, b, c, a, c, d]:
		pp.append(v)
		nn.append(n)
		cc.append(col)


func _add_quad_m(pp: PackedVector3Array, nn: PackedVector3Array, cc: PackedColorArray,
		a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color) -> void:
	# Fix Pass 18: MIRRORED corner order (a-d-c-b). _add_quad's
	# a-b-c / a-c-d walk is back-facing from the stated normal's
	# side in this renderer - FP12 convicted the same bug on the
	# guide strip and chevrons and mirrored them locally; the
	# ribbon box sections (surface, skirts, underside, edge
	# strips) kept the naive order, so the road's top has been
	# culled from above since the box section was built and the
	# driver has been looking at the box's UNDERSIDE (bot_c
	# brown) through it - the FP15 centre band, present in the
	# mesh data, never rendered at all. Proven by bisect: the
	# built surface with flipped triangle order renders its
	# vertex colours from above; unflipped it draws nothing
	# there under any material. The stated normals were always
	# correct - only the winding was inverted.
	_add_quad(pp, nn, cc, a, d, c, b, n, col)


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


func _build_gantry(s: float, _label: String, parent: Node = null) -> void:
	# Fix Pass 27: the overhead BANNER is deleted (owner, run
	# 22: the green span "pops into view sometimes as you're
	# swinging" - at the doubled hang station it slabbed
	# across the sky dead ahead of the dangling driver). The
	# line itself is now a road-surface stripe (_add_line_
	# stripe, same s - the lap logic never read the banner).
	# The POSTS stay, on geometry: they stand at +/-(HALF_
	# WIDTH + 0.4) at the line's own s - beside the dangling
	# car, ~81 deg off the forward axis, tops at 4.6 m, below
	# the crane pivot and in the family of trackside furniture
	# (the crane post stands taller and stays by design). They
	# flank the line; nothing spans over it. Stage 57 asserts
	# both halves: no Gantry child is a span, and the posts'
	# azimuth from the dangle eye stays in the far periphery
	# across the sway cone.
	var fr: Dictionary = _frame_at(s)
	var p: Vector3 = fr["pos"]
	var sd: Vector3 = fr["side"]
	var up: Vector3 = fr["up"]
	var g := Node3D.new()
	g.name = "Gantry" + _label
	(parent if parent != null else self).add_child(g)
	_box(g, Vector3(0.35, 4.6, 0.35), p - sd * (HALF_WIDTH + 0.4) + up * 2.3, _mat(Color(0.2, 0.2, 0.22)))
	_box(g, Vector3(0.35, 4.6, 0.35), p + sd * (HALF_WIDTH + 0.4) + up * 2.3, _mat(Color(0.2, 0.2, 0.22)))


# Fix Pass 27: the start/finish line as ROAD PAINT - a
# chequered stripe across the full width at the line's s,
# 1.0 m deep (2 rows of 0.5 m), 12 cells of 1.0 m across,
# lifted the same +0.02 the edge strips ride at so it sits
# flush on the surface without z-fighting. Built with
# _add_quad_m in the road mesh family, so it inherits the
# FP18 winding-correct rendering. Chequer over plain: at
# racing pace a chequer band strobes black/white across the
# whole width - unmistakable for a line, where a plain band
# could read as another surface treatment.
func _add_line_stripe(pp: PackedVector3Array, nn: PackedVector3Array, cc: PackedColorArray, s_line: float) -> void:
	var f0: Dictionary = _frame_at(s_line)
	var f1: Dictionary = _frame_at(s_line + 0.5)
	var f2: Dictionary = _frame_at(s_line + 1.0)
	var frames: Array = [f0, f1, f2]
	var cw: Color = Color(0.92, 0.92, 0.92)
	var cb: Color = Color(0.04, 0.04, 0.05)
	for row: int in range(2):
		var fa: Dictionary = frames[row]
		var fb: Dictionary = frames[row + 1]
		var pa: Vector3 = fa["pos"]
		var pb: Vector3 = fb["pos"]
		var sa: Vector3 = fa["side"]
		var sb: Vector3 = fb["side"]
		var ua: Vector3 = fa["up"]
		var ub: Vector3 = fb["up"]
		var nrm: Vector3 = (ua + ub).normalized()
		for cell: int in range(12):
			var lat0: float = -HALF_WIDTH + float(cell) * 1.0
			var lat1: float = lat0 + 1.0
			var col: Color = cw if (row + cell) % 2 == 0 else cb
			_add_quad_m(pp, nn, cc,
				pa + sa * lat0 + ua * 0.02, pa + sa * lat1 + ua * 0.02,
				pb + sb * lat1 + ub * 0.02, pb + sb * lat0 + ub * 0.02,
				nrm, col)


# Fix Pass 28: one section stripe for the lab's born-in
# rhythm - a 0.4 m transverse band across the full width,
# pale grey against the asphalt, riding the same +0.02
# lift as the line paint, in the road mesh family (FP18
# winding via _add_quad_m). Subtle by design: the rhythm
# is the message, not the stripe.
func _add_section_stripe(pp: PackedVector3Array, nn: PackedVector3Array, cc: PackedColorArray, s_sec: float) -> void:
	var fa: Dictionary = _frame_at(s_sec)
	var fb: Dictionary = _frame_at(s_sec + 0.4)
	var pa: Vector3 = fa["pos"]
	var pb: Vector3 = fb["pos"]
	var sa: Vector3 = fa["side"]
	var sb: Vector3 = fb["side"]
	var ua: Vector3 = fa["up"]
	var ub: Vector3 = fb["up"]
	_add_quad_m(pp, nn, cc,
		pa - sa * HALF_WIDTH + ua * 0.02, pa + sa * HALF_WIDTH + ua * 0.02,
		pb + sb * HALF_WIDTH + ub * 0.02, pb - sb * HALF_WIDTH + ub * 0.02,
		(ua + ub).normalized(), Color(0.52, 0.52, 0.56))


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


func _surf_height_at(s: float, lat: float) -> float:
	# Fix Pass 21: the road surface's world height at arc
	# position s and lateral offset lat - the height of the
	# surface point a wheel at that offset actually touches.
	var frs: Dictionary = _frame_at(s)
	return (Vector3(frs["pos"]) + Vector3(frs["side"]) * lat).y


func _patch_kv(s_w: float, lat_w: float) -> float:
	# Fix Pass 21 (Item 1): the vertical curvature of the
	# surface AT a wheel's contact patch, from finite
	# differences of the patch height along the wheel's own
	# line (lat held - it changes slowly against a 5 m
	# stencil). Same sign convention as t_kv: positive over a
	# crest, where the road falls away. The centreline t_kv
	# cannot see this quantity's lateral half: on a banked
	# exit the surface under the outside wheels falls as the
	# bank unwinds while the centreline runs level (kv = 0,
	# axle load 1.00) - the owner's "inside flair" lived
	# exactly there (conviction traces, FP21 README). The
	# stencil spans 5 m, the same averaging scale the build's
	# own t_kv smoothing uses (~a wheelbase).
	var d: float = 2.5
	var hm: float = _surf_height_at(s_w - d, lat_w)
	var h0: float = _surf_height_at(s_w, lat_w)
	var hp: float = _surf_height_at(s_w + d, lat_w)
	var slope: float = (hp - hm) / (2.0 * d)
	var hpp: float = (hp - 2.0 * h0 + hm) / (d * d)
	return -hpp / pow(1.0 + slope * slope, 1.5)


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
	if audit_on:
		# Fix Pass 24 (Item 3): a road-born separation opens an
		# audit flight at this s (the payout closes it in
		# _pay_for_landing; crane falls never reach _enter_air).
		audit_flight_open = true
		audit_flight_s = car_s
	air_basis0 = car.global_transform.basis # FP14 (Item 7): attitude builds from the takeoff basis
	air_from_rebound = false # FP14 (Item 1): callers that throw the car set this after entry
	air_from_release = false # FP14 (Item 1): a road-born flight; _do_release marks its own
	grounded_t = 0.0
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
		# Fix Pass 25 (Item 4): the front MESH is the visual
		# radius, stepped outboard and centred higher by the
		# growth (see the constants note) - the built position
		# is only frame zero; _refresh_car_visuals poses the
		# fronts every frame.
		cm.top_radius = WHEEL_RAD_R if is_rear_w else WHEEL_RAD_F_VIS
		cm.bottom_radius = WHEEL_RAD_R if is_rear_w else WHEEL_RAD_F_VIS
		cm.height = WHEEL_WID_R if is_rear_w else WHEEL_WID_F
		w.mesh = cm
		w.rotation_degrees = Vector3(0, 0, 90)
		if is_rear_w:
			w.position = Vector3(wl.x, WHEEL_RAD_REF, wl.y)
		else:
			w.position = Vector3(wl.x + signf(wl.x) * WHEEL_OUT_F_VIS,
				WHEEL_RAD_REF + (WHEEL_RAD_F_VIS - WHEEL_RAD_F)
					+ WHEEL_FWD_F_VIS * (WHEEL_RAD_R - WHEEL_RAD_F) / WHEELBASE,
				wl.y - WHEEL_FWD_F_VIS)
		w.material_override = dark
		w.name = "WheelF" if wl.y < 0.0 else "WheelR"
		car_body.add_child(w)
		wheel_mis.append(w)
		wheel_axle.append(0 if wl.y < 0.0 else 1)
	# Fix Pass 15 (Item 1): contact-patch DUST - one small
	# GPUParticles3D per wheel at its patch, driven by the
	# telegraph (see _update_telegraph). Flat unshaded puffs,
	# tan like the desert the tires are worrying at; emitted
	# in world space (local_coords off) so the dust stays
	# where the tire shed it.
	for wi2: int in WHEEL_LOCALS.size():
		var wl2: Vector2 = WHEEL_LOCALS[wi2]
		var em := GPUParticles3D.new()
		em.name = "Dust%d" % wi2
		em.amount = 18
		em.lifetime = 0.8
		em.local_coords = false
		em.emitting = false
		em.amount_ratio = 0.0
		em.visibility_aabb = AABB(Vector3(-40.0, -15.0, -40.0), Vector3(80.0, 30.0, 80.0))
		em.position = Vector3(wl2.x, 0.06 if wl2.y < 0.0 else -0.08, wl2.y)
		var pm := ParticleProcessMaterial.new()
		pm.direction = Vector3(0.0, 1.0, 0.45)
		pm.spread = 32.0
		pm.initial_velocity_min = 0.7
		pm.initial_velocity_max = 1.6
		pm.gravity = Vector3(0.0, -0.5, 0.0)
		pm.damping_min = 0.8
		pm.damping_max = 1.4
		pm.scale_min = 0.10
		pm.scale_max = 0.24
		var grad := Gradient.new()
		grad.set_color(0, Color(0.80, 0.72, 0.55, 0.50))
		grad.set_color(1, Color(0.80, 0.72, 0.55, 0.0))
		var gtex := GradientTexture1D.new()
		gtex.gradient = grad
		pm.color_ramp = gtex
		em.process_material = pm
		var puff := SphereMesh.new()
		puff.radius = 0.16
		puff.height = 0.32
		puff.radial_segments = 6
		puff.rings = 3
		var pmat := StandardMaterial3D.new()
		pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pmat.albedo_color = Color(0.80, 0.72, 0.55)
		pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff.material = pmat
		em.draw_pass_1 = puff
		car_body.add_child(em)
		dust_emitters.append(em)
	# Fix Pass 24 (Item 4): the Test-1 smoke-puff sphere that
	# lived here is DELETED outright (owner's tap, 2026-10-30
	# 09:26 CDT) - mesh, trigger and pulse, all of it. The run-15
	# video convicted it: a grey unshaded disc that faded in
	# after a hard landing and throbbed in the driver's face
	# until the next reset; run 19 re-confirmed it. The
	# nose-dent visual is separate and stays. Real smoke, if
	# it ever exists, belongs to the carnage build.
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
	# Fix Pass 13 (Item 1): the three prep switches that lived
	# on the dash top are DELETED with the prep sequence - the
	# dash top is bare now. The dash controls that remain are
	# the three buttons below (restart / lean / track), the
	# seat levers on the left pod, and (since Fix Pass 20) the
	# DROP BUTTON on the dash face.
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
	rst_m.top_radius = 0.040 # FP16 (Item 2): was 0.05 - smaller furniture, the 0.15 volume stays
	rst_m.bottom_radius = 0.040
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
	ln_m.top_radius = 0.036 # FP16 (Item 2): was 0.045
	ln_m.bottom_radius = 0.036
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
	trk_m.top_radius = 0.036 # FP16 (Item 2): was 0.045
	trk_m.bottom_radius = 0.036
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
		_box(spiv, Vector3(0.030, 0.15, 0.030), Vector3(0, 0.075, 0), _mat(Color(0.65, 0.65, 0.68))) # FP16 (Item 2): shaft was 0.055 x 0.20 at y 0.08; the base sits on the pivot plane, not sunk in the pod
		_box(spiv, Vector3(0.052, 0.05, 0.052), Vector3(0, 0.145, 0), _mat_unshaded(seat_cols[si])) # FP16 (Item 2): cap was 0.085 x 0.06 at y 0.19; the grab SEGMENT (0.02..0.19) deliberately outlives the mesh
		_register_dash_ctl(spiv, seat_kinds[si])
		# Fix Pass 13 (Item 5): the pivots are kept so the
		# held lever can DEFLECT (see _update_ctl_articulation).
		seat_pivots.append(spiv)
	# Fix Pass 14 (Item 6): amber VIEW button - the
	# view-coupling A/B toggle (0.6x <-> 1.0x, see
	# _view_gain). Registered LAST of the dash controls so
	# every earlier control's index (and the stages keyed
	# on them) is untouched. It sits left of restart at the
	# same 0.17 m spacing the restart/track pair uses;
	# activation is nearest-control, so the closer wins.
	var vwt := Node3D.new()
	vwt.position = Vector3(-0.35, 0.95, -0.60) # on the dash (as restart)
	car_body.add_child(vwt)
	var vw_mi := MeshInstance3D.new()
	var vw_m := CylinderMesh.new()
	vw_m.top_radius = 0.036 # FP16 (Item 2): was 0.045
	vw_m.bottom_radius = 0.036
	vw_m.height = 0.04
	vw_mi.mesh = vw_m
	vw_mi.material_override = _mat_unshaded(Color(0.95, 0.65, 0.10))
	vw_mi.name = "ViewBtnMesh"
	vwt.add_child(vw_mi)
	_register_dash_ctl(vwt, "view")
	# Fix Pass 15 (Item 3): light-blue SIDE button - the
	# drop-control mirror toggle (right side <-> left side of
	# the dash face, the lefty option; since Fix Pass 20 it
	# mirrors the DROP BUTTON). It takes the dash-top CENTRE
	# the drop lever vacated in this same pass, and is
	# registered LAST so no earlier control's index moves.
	var sdt := Node3D.new()
	sdt.position = Vector3(0.0, 0.95, -0.60) # on the dash (as restart)
	car_body.add_child(sdt)
	var sd_mi := MeshInstance3D.new()
	var sd_m := CylinderMesh.new()
	sd_m.top_radius = 0.036 # FP16 (Item 2): was 0.045
	sd_m.bottom_radius = 0.036
	sd_m.height = 0.04
	sd_mi.mesh = sd_m
	sd_mi.material_override = _mat_unshaded(Color(0.35, 0.75, 0.95))
	sd_mi.name = "SideBtnMesh"
	sdt.add_child(sd_mi)
	_register_dash_ctl(sdt, "side")
	# Fix Pass 20 (Item 1): the DROP BUTTON stands where the
	# lever stood - on the dash FACE, right of the wheel (the
	# owner's run-14 placement, kept), mirrored left by the
	# SIDE button above / M key for lefties. It is a BIG red
	# dash button: a 0.07 m radius cylinder turned to face
	# the driver, on the lever's bracket (re-based so its
	# back meets the slab face). Registered LAST of the dash
	# controls (index 7) so no earlier control's index moves;
	# its zone is the dash family's fat 0.15 m point volume,
	# its latch the FP16 Schmitt one-shot, its dip the
	# articulation's - along its facing (z), not down (y).
	# Clearances at the point (0.42, 0.85, -0.44) since Fix
	# Pass 26 raised it to the upper dash face (FP20's point
	# was (0.42, 0.70, -0.44)): 0.44 m from the wheel hub (a
	# press never reads as a wheel grab), >= 0.19 m from
	# every dash-top button point.
	drop_btn_bracket = _box(car_body, Vector3(0.18, 0.16, 0.09), Vector3(DROP_BTN_FACE_X, DROP_BTN_FACE_Y, DROP_BTN_FACE_Z - 0.065), _mat(Color(0.10, 0.10, 0.12)))
	var dbt := Node3D.new()
	dbt.name = "DropButton"
	dbt.position = Vector3(DROP_BTN_FACE_X, DROP_BTN_FACE_Y, DROP_BTN_FACE_Z)
	car_body.add_child(dbt)
	var db_mi := MeshInstance3D.new()
	var db_m := CylinderMesh.new()
	db_m.top_radius = 0.07 # the big red button: twice the dash buttons' radius
	db_m.bottom_radius = 0.07
	db_m.height = 0.05
	db_mi.mesh = db_m
	db_mi.rotation_degrees = Vector3(90, 0, 0) # the cylinder's axis turns to face the driver
	db_mi.material_override = _mat_unshaded(Color(0.90, 0.12, 0.10))
	db_mi.name = "DropBtnMesh"
	dbt.add_child(db_mi)
	drop_btn_node = dbt
	_register_dash_ctl(dbt, "drop")
	_apply_drop_btn_side()
	# Fix Pass 26 (Item 1): the TURBO FLASK - the boost meter
	# as a liquid vessel set into the dash-TOP button row,
	# built with the cockpit (NOT on either info panel: it
	# never hides). It replaces FP24's dash-face bar, which
	# the steering wheel hid from the real seat. The owner's
	# redesign, in his words: "a liquid flasky meter where
	# one of those flat buttons is along the dash, like the
	# green one. sloshes around with car movement, drains
	# some on use." A squat tinted-glass vessel in a socket
	# bezel, a collar at its neck - a gauge's silhouette,
	# never a pressable button (no dash registration, no
	# zone). Inside it the liquid: a narrow box on a pivot,
	# its height the tank, its surface sloshing on the
	# spring _update_turbo_meter integrates. Every part is
	# >= 0.024 m in every dimension (the FP24 lesson: the
	# dash audit's buried test grows AABBs by -0.01 and a
	# thinner box goes negative under it).
	flask_node = Node3D.new()
	flask_node.name = "TurboFlask"
	flask_node.position = FLASK_POS
	car_body.add_child(flask_node)
	var fbase := MeshInstance3D.new()
	var fbm := CylinderMesh.new()
	fbm.top_radius = 0.054
	fbm.bottom_radius = 0.058
	fbm.height = 0.024
	fbase.mesh = fbm
	fbase.position = Vector3(0.0, 0.012, 0.0)
	fbase.material_override = _mat(Color(0.10, 0.10, 0.12))
	fbase.name = "FlaskBase"
	flask_node.add_child(fbase)
	flask_liquid_pivot = Node3D.new()
	flask_liquid_pivot.name = "FlaskLiquidPivot"
	flask_liquid_pivot.position = Vector3(0.0, 0.024, 0.0)
	flask_node.add_child(flask_liquid_pivot)
	flask_liquid_mi = MeshInstance3D.new()
	var flm := BoxMesh.new()
	flm.size = Vector3(0.046, 1.0, 0.046) # unit height: the pivot scales it to the level
	flask_liquid_mi.mesh = flm
	flask_liquid_mi.name = "FlaskLiquid"
	flask_liquid_mat = _mat_unshaded(Color(0.25, 0.55, 0.95))
	flask_liquid_mi.material_override = flask_liquid_mat
	flask_liquid_pivot.add_child(flask_liquid_mi)
	var fglass := MeshInstance3D.new()
	var fgm := BoxMesh.new()
	fgm.size = Vector3(0.088, 0.095, 0.088)
	fglass.mesh = fgm
	fglass.position = Vector3(0.0, 0.0715, 0.0)
	var fgmat := StandardMaterial3D.new()
	fgmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fgmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fgmat.albedo_color = Color(0.75, 0.88, 1.0, 0.30)
	fglass.material_override = fgmat
	fglass.name = "FlaskGlass"
	flask_node.add_child(fglass)
	_box(flask_node, Vector3(0.056, 0.024, 0.056), Vector3(0.0, 0.131, 0.0), _mat(Color(0.55, 0.55, 0.58)), "FlaskCollar")
	# Lean indicator needle on the dash (experiment feedback)
	# (rides up with the raised wheel so it stays clear of the rim)
	# Fix Pass 13 (Item 2): shifted left off the centreline -
	# the centre drop lever's arc sweeps the space it sat in.
	# Fix Pass 15 (Item 3): the needle DROPS toward the
	# dash (y 1.155 -> 1.04, mount x back to FP13's -0.18):
	# the DIAG text grew in this pass (SIDE zone tag + DRP
	# side readout), and the board's lower sightlines from
	# the anchored eye pass through the needle's old float
	# height (render proof sweep: 2 of 63 blocked; shifting
	# the needle sideways only moved the block to the next
	# column - the eye-to-board fan crosses its whole x
	# span). Below y 1.105 every board sightline passes
	# over it, and it reads as dash-mounted instead of
	# floating. The FP13 x-centre stands.
	lean_needle = _box(car_body, Vector3(0.03, 0.13, 0.02), Vector3(-0.18, 1.04, -0.615), _mat_unshaded(Color(0.2, 0.9, 1.0)))
	# Big state label above the dash
	state_label = Label3D.new()
	state_label.position = Vector3(0, 1.52, -0.85)
	state_label.font_size = 64
	state_label.pixel_size = 0.0022
	state_label.text = "DROP START"
	state_label.modulate = Color(1.0, 0.85, 0.2)
	state_label.outline_size = 8
	car_body.add_child(state_label)
	# Touchdown readout label, under the state label (Fix
	# Pass 13, Item 1: it shows the connection grade for ~2.5 s
	# after each landing - it was the prep prompt's node).
	contact_label = Label3D.new()
	contact_label.position = Vector3(0, 1.34, -0.85)
	contact_label.font_size = 40
	contact_label.pixel_size = 0.0016
	contact_label.text = ""
	contact_label.modulate = Color(0.6, 0.95, 1.0)
	contact_label.outline_size = 6
	car_body.add_child(contact_label)
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
	# Fix Pass 24 (Item 1): raised 5 cm more and the board
	# grows 0.34 -> 0.44 tall - the DIAG block gains the BOOST
	# and LAST PAY lines (eleven rows; the live block measures
	# 0.42 m tall with its wraps). The first growth (0.40)
	# still left the text overhanging the board's lower edge
	# and one of the proof's 63 DIAG sightlines grazed -
	# the FP11 lesson, relearned at this board's expense.
	diag_root.position = Vector3(-0.54, 1.34, -1.00)
	diag_root.rotation_degrees = Vector3(-10, 28, 0)
	car_body.add_child(diag_root)
	_box(diag_root, Vector3(1.02, 0.44, 0.02), Vector3(0, 0, 0), _mat(Color(0.05, 0.07, 0.12)), "DiagBoard")
	diag_label = Label3D.new()
	diag_label.position = Vector3(-0.45, 0.175, 0.02) # FP24: same 0.045 top inset on the taller board
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
	dash_ctl_base_y.append(node.position.y) # FP13: button-dip rest height


# --- Fix Pass 13 (Item 5): articulation ---
# Run 13: "the seat levers actuate and work, but I notice the
# lever doesn't actually move." The rule this item enforces:
# every cockpit control that ACTUATES also ARTICULATES. (The
# drop lever swung with the hand until Fix Pass 20 retired
# it; the DROP BUTTON dips along its facing like the dash
# buttons dip down.) The wheel spins and, since Item 3, the
# front road wheels show the steer. The seat levers DEFLECT while held -
# SEAT+ tips up (toward upright), SEAT- presses forward-down,
# matching the seat's motion - and every dash BUTTON dips
# 8 mm while a gripping hand holds it fired. Momentary
# buttons' other feedback stays their visible effect (needle,
# panel, world), stated in the pass report's audit.
const SEAT_LEVER_REST_DEG: float = -20.0
const SEAT_TRIM_DEFLECT_DEG: float = 18.0
const BTN_DIP_M: float = 0.008
var seat_pivots: Array[Node3D] = [] # [seatup, seatdn] pivots
var dash_ctl_base_y: Array[float] = []
var seat_key_dir: float = 0.0 # desktop PgUp/PgDn direction, per frame


func _update_ctl_articulation(delta: float) -> void:
	# Seat levers: deflect toward held, spring back to rest.
	var held_kind: String = _seat_trim_held()
	for si: int in seat_pivots.size():
		var kind: String = "seatup" if si == 0 else "seatdn"
		var target: float = SEAT_LEVER_REST_DEG
		if held_kind == kind or (seat_key_dir > 0.0 and kind == "seatup") \
				or (seat_key_dir < 0.0 and kind == "seatdn"):
			target += SEAT_TRIM_DEFLECT_DEG if kind == "seatup" else -SEAT_TRIM_DEFLECT_DEG
		var rd: Vector3 = seat_pivots[si].rotation_degrees
		rd.x = move_toward(rd.x, target, 240.0 * delta)
		seat_pivots[si].rotation_degrees = rd
	# Dash buttons: dip while any gripping hand holds them.
	for ci: int in dash_ctl_nodes.size():
		if dash_ctl_kinds[ci].begins_with("seat"):
			continue
		var dipped: bool = (bool(gripping["L"]) and int(dash_ctl_fired["L"]) == ci) \
			or (bool(gripping["R"]) and int(dash_ctl_fired["R"]) == ci)
		var node: Node3D = dash_ctl_nodes[ci]
		if dash_ctl_kinds[ci] == "drop":
			# Fix Pass 20 (Item 1): the drop button faces the
			# driver off the dash face - its dip runs along its
			# facing (into the face, -z), not down.
			var tz: float = drop_btn_base_z - (BTN_DIP_M if dipped else 0.0)
			node.position.z = move_toward(node.position.z, tz, 0.08 * delta)
			continue
		var ty: float = dash_ctl_base_y[ci] - (BTN_DIP_M if dipped else 0.0)
		node.position.y = move_toward(node.position.y, ty, 0.08 * delta)


func _panel_text() -> String:
	var mode_txt: String = "XR LIVE" if xr_ok else "DESKTOP FALLBACK"
	var lines: Array[String] = []
	lines.append("STUNT CAR VR - TEST 1 [%s]" % mode_txt)
	lines.append("SPD %d  BOOST %d  DENT %d  TRK %s" % [int(round(speed * 3.6)), int(round(boost_meter)), dent_level,
		"CIRCUIT" if active_track == "circuit" else ("LAB" if active_track == "lab" else "RIBBON")])
	if track_closed:
		lines.append("STATE %s  LAP %d/%d  TD %s" % [_state_name(), mini(lap_count + 1, RACE_LAPS), RACE_LAPS, last_touchdown])
	else:
		lines.append("STATE %s  TD %s" % [_state_name(), last_touchdown])
	lines.append("LEAN EXP %s  GRIP x%.2f" % ["ON" if lean_on else "OFF", grip_mult])
	lines.append("-- VR CONTROLS --")
	lines.append("Grab wheel: GRIP near wheel, turn hand")
	lines.append("Throttle R trigger / Brake L trigger")
	lines.append("Boost: R A button (while driving) - the dash-top FLASK's liquid is the tank; air pays it back")
	lines.append("Release: DROP BUTTON (upper dash face) - on chains it drops you, any time")
	lines.append("Seat: GRIP-HOLD SEAT+/SEAT- pod levers")
	lines.append("Call crane: L X button (while driving)")
	lines.append("Jitter exp: R stick click")
	lines.append("Dash buttons (GRIP): red restart, green lean, purple track, amber view A/B, blue drop side")
	lines.append("Recenter: L stick click / BOTH grips")
	lines.append("restart race: L Y button")
	lines.append("Panels: R B button (show/hide)")
	lines.append("-- DESKTOP --")
	lines.append("W/S throttle/brake, A/D steer, SHIFT boost")
	lines.append("SPACE release")
	lines.append("TAB panels, L lift, T lean, J jitter, G view A/B, M drop side, Q/E lean body")
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
	lines.append("WHEEL %+d DEG JIT %s SEAT %+.2f VIEW %s DROP %s" % [int(round(rad_to_deg(wheel_angle))), "ON" if jitter_on else "OFF", seat_trim, "B" if view_gain_mode == 1 else "A", "L" if drop_btn_left else "R"])
	# Fix Pass 13 (Item 1): the last touchdown's connection,
	# same numbers the readout showed - so a capture carries
	# the ruling with it.
	if contact_grade == "-":
		lines.append("CONTACT -")
	else:
		lines.append("CONTACT %s LAT %.1f HDG %+.1f" % [contact_grade, contact_lat_speed, contact_head_err])
	# Fix Pass 24 (Items 1+2): the economy on the board - the
	# tank's state and the last payout's ruling, in the open
	# like every other ruling this game makes.
	lines.append("BOOST %d/%d" % [int(round(boost_meter)), int(BOOST_CAPACITY)])
	if last_pay_units > 0.0:
		lines.append("LAST PAY +%.1f AIR %.2fs %s" % [last_pay_units, last_pay_air_s, last_pay_grade])
	else:
		lines.append("LAST PAY -")
	# Fix Pass 13 (Item 4): the hang input log - the last six
	# face-button edges during MODE_HANG, oldest first, each
	# "racetime:TAG" (RA/RB/LX/LY).
	if hang_btn_log.is_empty():
		lines.append("BTN -")
	else:
		lines.append("BTN " + " ".join(hang_btn_log))
	# Fix Pass 16 (Item 5): the last grab event rides the board -
	# the grab path's own account, in the driver's face.
	lines.append("GRAB %s" % (grab_last_event if grab_last_event != "" else "-"))
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
	var short: Dictionary = {"restart": "RST", "lean": "LEAN", "track": "TRK",
		"seatup": "SUP", "seatdn": "SDN", "view": "VIEW", "side": "SIDE", "drop": "DROP"}
	var near_l: int = _dash_ctl_near(_hand_pos("L"))
	var near_r: int = _dash_ctl_near(_hand_pos("R"))
	# Fix Pass 20 (Item 1): the drop control is a dash control
	# now, so its zone reads in the row like every other (the
	# FP11 DRP tag, which existed because the lever was not
	# one, is retired with it).
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
	# Fix Pass 16 (Item 1): the FRC column is GONE - grip_force
	# has no binding in any profile and no endpoint on this
	# hardware, so the column read 0.00 for six passes and said
	# nothing. HLD shows the Schmitt latch state instead: the
	# debounced value every grab actually consumes.
	return "%s GRIP %.2f CLK %d HLD %d %dcm%s" % [
		hand, float(diag_grip[hand]), 1 if bool(diag_click[hand]) else 0,
		1 if bool(gripping[hand]) else 0, int(round(dist_m * 100.0)), flags]


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


# ---------------------------------------------------------------- crane

# Fix Pass 15 (Item 2): the crane rig, built once and re-posed
# per hang by _place_crane. Static furniture (post, footing,
# service pad) is posed in the drop frame's space at placement
# time; the jib, counter-jib and trolley are posed every frame
# by _update_crane_visual from the live pivot state. The rig
# reads in the game's block language: a lattice-free post, a
# beam jib, a counterweight block, and the four chains the
# manual's Drop Start describes.
func _build_crane() -> void:
	crane = Node3D.new()
	crane.name = "Crane"
	crane.visible = false
	add_child(crane)
	var steel := _mat(Color(0.85, 0.55, 0.08)) # crane yellow, weathered flat
	var dark := _mat(Color(0.16, 0.16, 0.18))
	# Static furniture (positions set by _place_crane).
	crane_foot = _box(crane, Vector3(1.6, 0.35, 1.6), Vector3.ZERO, dark)
	crane_post = _box(crane, Vector3(0.42, 1.0, 0.42), Vector3.ZERO, steel) # unit-height post, scaled at placement
	crane_pad = _box(crane, Vector3(0.9, 0.06, 3.9), Vector3.ZERO, _mat(Color(0.45, 0.42, 0.38))) # service pad: long axis on Z (= side at placement)
	# Dynamic members (posed per frame).
	crane_jib = _beam_instance(steel)
	crane_counter = _beam_instance(dark)
	crane_trolley = _box(crane, Vector3(0.55, 0.34, 0.55), Vector3.ZERO, dark)
	# Fix Pass 26: the spreader frame the chains hang from -
	# a car-proportioned rectangle (0.90 x 2.03 m) at the
	# corners' plane, posed per frame in _update_crane_visual.
	crane_spreader = Node3D.new()
	crane_spreader.name = "CraneSpreader"
	crane.add_child(crane_spreader)
	_box(crane_spreader, Vector3(0.06, 0.06, 2.145), Vector3(-0.45, 0.0, 0.0), dark)
	_box(crane_spreader, Vector3(0.06, 0.06, 2.145), Vector3(0.45, 0.0, 0.0), dark)
	_box(crane_spreader, Vector3(0.96, 0.06, 0.06), Vector3(0.0, 0.0, -1.0125), dark)
	_box(crane_spreader, Vector3(0.96, 0.06, 0.06), Vector3(0.0, 0.0, 1.0125), dark)
	crane.add_child(crane_jib)
	crane.add_child(crane_counter)
	# 4 chains (unit cylinders, stretched between the trolley's
	# spreader frame and the car corners - the manual's chains).
	for i: int in 4:
		var lm := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.014
		cm.bottom_radius = 0.014
		cm.height = 1.0
		lm.mesh = cm
		lm.material_override = _mat_unshaded(Color(0.08, 0.08, 0.08))
		lm.visible = false
		add_child(lm)
		line_mis.append(lm)


func _beam_instance(mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.34, 0.30, 1.0) # unit length on Z, stretched by _set_beam
	mi.mesh = bm
	mi.material_override = mat
	return mi


# Stretch a unit beam between two world points.
func _set_beam(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var dirv: Vector3 = b - a
	var lenv: float = dirv.length()
	if lenv < 0.05:
		mi.visible = false
		return
	mi.visible = true
	var basis := Basis.looking_at(dirv / lenv, Vector3.UP)
	mi.global_transform = Transform3D(basis, (a + b) * 0.5)
	mi.scale = Vector3(1.0, 1.0, lenv)


# Pose the rig on the drop piece: the post stands on the
# service pad CRANE_POST_OFF beyond the ribbon edge, its top
# a metre above the pivot line; the pad runs from the ribbon
# edge out past the pickup point, its top flush with the road
# surface so the car rests on it like road.
func _place_crane(drop_s: float) -> void:
	var fr: Dictionary = _frame_at(drop_s)
	var side: Vector3 = fr["side"]
	var post_base: Vector3 = fr["pos"] + side * (HALF_WIDTH + CRANE_POST_OFF)
	var post_h: float = HANG_LEN + HANG_CLEAR + 1.1
	# The furniture stands gravity-vertical in the road's
	# heading frame: basis X = travel direction, Z = side
	# (the pad's long axis runs out from the ribbon edge).
	var tan_h: Vector3 = Vector3(fr["tan"].x, 0.0, fr["tan"].z).normalized()
	var side_h: Vector3 = tan_h.cross(Vector3.UP).normalized()
	var fb := Basis(tan_h, Vector3.UP, side_h)
	# Footing + post + pad are children of the (untransformed)
	# crane root - set their world transforms directly.
	crane_foot.global_transform = Transform3D(fb, post_base + Vector3(0.0, 0.17, 0.0))
	crane_post.global_transform = Transform3D(fb, post_base + Vector3(0.0, post_h * 0.5, 0.0))
	crane_post.scale = Vector3(1.0, post_h, 1.0)
	var pad_c: Vector3 = fr["pos"] + side * (HALF_WIDTH + 1.9)
	crane_pad.global_transform = Transform3D(fb, pad_c + Vector3(0.0, -0.03, 0.0))
	crane.visible = true


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


# The chains' top corners: a spreader frame under the trolley,
# hung from the pivot in the jib's heading frame (same axis
# order as _car_corners so the line pairing matches).
func _crane_corners() -> Array[Vector3]:
	# Fix Pass 26 (Item 2 consequence): the spreader rectangle
	# is PROPORTIONAL to the car's attach rectangle (half
	# 0.60 x 1.35) at the same 0.45 half-width - fore-aft half
	# 0.45 x (1.35 / 0.60) = 1.0125. FP6's no-cross rule was
	# proven for a SQUARE spreader (+-0.45 both axes), and the
	# doubled chains broke it: the same diagonal hang displaces
	# the car twice as far in plan, and past that displacement
	# the diagonal pair's line order flips (the render proof's
	# sweep counted 9 crossings at the staged 0.30/0.24 dangle,
	# all the 1-2 pair at the fore turning point). Similar
	# rectangles at the same yaw cannot cross at ANY
	# displacement - the fan keeps its cyclic order by
	# construction - and a car-sized spreader frame is what a
	# real lift hangs a car from. The frame is built in
	# _build_crane and posed with these corners.
	var out: Array[Vector3] = []
	var xf := Transform3D(Basis(Vector3.UP, carrier_yaw), pivot_pos)
	for ax: float in [-0.45, 0.45]:
		for az: float in [-1.0125, 1.0125]:
			out.append(xf * Vector3(ax, -0.30, az))
	return out


# Fix Pass 15 (Item 2): pose the rig from the live pivot
# state - the jib reaches from the post top to a point half a
# metre above the trolley, the counter-jib reaches back with
# its weight, the trolley block rides at the pivot. Hidden
# outside MODE_HANG (the rig exists only at a Drop Start /
# recovery, placed by _place_crane).
func _update_crane_visual() -> void:
	if crane == null:
		return
	var show: bool = mode == MODE_HANG
	crane.visible = show
	if not show:
		for lm: MeshInstance3D in line_mis:
			lm.visible = false
		return
	var top: Vector3 = crane_post.global_position + Vector3(0.0, crane_post.scale.y * 0.5, 0.0)
	var hook: Vector3 = pivot_pos + Vector3(0.0, 0.5, 0.0)
	_set_beam(crane_jib, top, hook)
	var back: Vector3 = top + (top - hook).normalized() * 2.2 + Vector3(0.0, 0.1, 0.0)
	_set_beam(crane_counter, top, back)
	crane_trolley.global_position = pivot_pos
	if crane_spreader != null:
		crane_spreader.global_transform = Transform3D(
			Basis(Vector3.UP, carrier_yaw), pivot_pos + Vector3(0.0, -0.30, 0.0))
	# Fix Pass 6 (Item 4) wire rule holds: chain i runs trolley
	# corner i -> car corner i and no pair can cross - the car's
	# facing seeks this same carrier_yaw (with lag), so the two
	# yaws never diverge past a few degrees, and (FP26) the
	# spreader rectangle is proportional to the car's, so the
	# fan keeps its order at any hang displacement.
	var tops: Array[Vector3] = _crane_corners()
	var bots: Array[Vector3] = _car_corners()
	for i: int in 4:
		_set_line(line_mis[i], tops[i], bots[i])


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
	seat_key_dir = 0.0 # Fix Pass 13 (Item 5): feeds the lever deflection
	if Input.is_key_pressed(KEY_PAGEUP):
		_apply_seat_trim(seat_trim + SEAT_TRIM_RATE * delta)
		seat_key_dir = 1.0
	if Input.is_key_pressed(KEY_PAGEDOWN):
		_apply_seat_trim(seat_trim - SEAT_TRIM_RATE * delta)
		seat_key_dir = -1.0
	# desktop steering drives the wheel toward a target
	var steer_key: float = 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer_key -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer_key += 1.0
	if grab_hand == "":
		if steer_key != 0.0:
			wheel_angle = clampf(wheel_angle + steer_key * 2.6 * delta, -PI, PI)
		elif mode == MODE_DRIVE:
			# Fix Pass 13 (Item 3): the return-to-centre runs
			# ONLY in DRIVE. It used to run in every mode, so a
			# lock dialled into the wheel during the dangle was
			# silently centred away during the fall - the first
			# DRIVE frame must receive the lock the driver set.
			wheel_angle = move_toward(wheel_angle, 0.0, 2.2 * delta)
	# --- XR continuous ---
	if xr_ok:
		var rc: XRController3D = hand_ctrl["R"]
		var lc: XRController3D = hand_ctrl["L"]
		in_throttle = maxf(in_throttle, _input_float(rc, &"trigger"))
		in_brake = maxf(in_brake, _input_float(lc, &"trigger"))
		_poll_grab("L", lc, delta)
		_poll_grab("R", rc, delta)
		# Fix Pass 13 (Item 4): the face/stick buttons live in
		# _poll_xr_buttons now (hang gates + the hang input
		# log); gripping[] was just refreshed by the grabs.
		# Fix Pass 11 (Item 4): the XR right-trigger release is
		# RETIRED - the drop lever is THE release now (the panel
		# says so). What remains as a non-lever path is desktop /
		# test only: SPACE and the stage hook (test_release_queued
		# below).
		_poll_xr_buttons(delta)
	# test overrides win last
	if test_mode:
		in_throttle = test_throttle
		in_brake = test_brake
		in_boost = test_boost
		if test_release_queued:
			test_release_queued = false
			_do_release()


# --- Fix Pass 13 (Item 4): the hang button gate + input log ---
# Run 13: while droned, mashing around the left stick for X
# (drone call) kept hitting Y (restart) - "weird influence on
# the chains or view" - and a wandering grip pair fired the
# both-grips recenter mid-sway. The pendulum reads NO player
# input; both mysteries were this block. The gates:
#   - Left Y (restart) in MODE_HANG needs a LONG PRESS
#     (>= HANG_RESTART_HOLD_S); everywhere else the edge
#     fires at once, as before.
#   - Right A (boost) is inert in the hang, and a press HELD
#     through the hang cannot arm boost at touchdown: the
#     first boost after a drop is always a fresh press.
#   - The both-grips recenter is suppressed in MODE_HANG and
#     while a cockpit control (drop lever, wheel, seat trim)
#     is latched/held. The stick-click recenter is the
#     deliberate route and is never gated.
#   - Left X stays exactly as gated as it was (DRIVE only) -
#     asserted in stage 32.
# And every face-button edge during MODE_HANG is logged to
# the DIAG board (BTN line) with its race time, so the next
# mystery names itself.
const HANG_RESTART_HOLD_S: float = 0.8
var boost_arm_blocked: bool = false
var y_hold_t: float = 0.0
var y_hold_fired: bool = false
var hang_btn_log: Array[String] = []
var test_btn: Dictionary = {"L": {}, "R": {}} # posed button states (test_mode)


func _btn_state(hand: String, ctrl: XRController3D, action: StringName) -> bool:
	# test_mode substitutes posed button states (same pattern
	# as test_grip in _poll_grab) so the smoke drives the
	# production button logic headless.
	if test_mode and (test_btn[hand] as Dictionary).has(action):
		return bool((test_btn[hand] as Dictionary)[action])
	return _input_bool(ctrl, action)


func _hang_btn_note(tag: String) -> void:
	hang_btn_log.append("%d:%s" % [int(race_time), tag])
	while hang_btn_log.size() > 6:
		hang_btn_log.pop_front()


func _seat_trim_held() -> String:
	# "" or the seat ctl kind a gripping hand is holding in
	# its zone right now (dash_ctl_fired is the level latch).
	for h: String in ["L", "R"]:
		var fi: int = int(dash_ctl_fired[h])
		if bool(gripping[h]) and fi >= 0 and fi < dash_ctl_kinds.size():
			var k: String = dash_ctl_kinds[fi]
			if k == "seatup" or k == "seatdn":
				return k
	return ""


func _recenter_allowed() -> bool:
	# The both-grips recenter's gate (see the item header).
	# The stick-click recenter never consults this.
	if mode == MODE_HANG:
		return false
	# Fix Pass 20 (Item 1): the lever's latch in this gate is
	# now any dash latch (the drop button among them).
	if int(dash_ctl_fired["L"]) >= 0 or int(dash_ctl_fired["R"]) >= 0 or grab_hand != "":
		return false
	return _seat_trim_held() == ""


func _poll_xr_buttons(delta: float) -> void:
	var rc: XRController3D = hand_ctrl["R"]
	var lc: XRController3D = hand_ctrl["L"]
	var a_now: bool = _btn_state("R", rc, &"ax_button")
	var b_now: bool = _btn_state("R", rc, &"by_button")
	var x_now: bool = _btn_state("L", lc, &"ax_button")
	var y_now: bool = _btn_state("L", lc, &"by_button")
	var a_edge: bool = _btn_edge("r_ax", a_now)
	var b_edge: bool = _btn_edge("r_by", b_now)
	var x_edge: bool = _btn_edge("l_ax", x_now)
	var y_edge: bool = _btn_edge("l_by", y_now)
	if mode == MODE_HANG:
		if a_edge:
			_hang_btn_note("RA")
		if b_edge:
			_hang_btn_note("RB")
		if x_edge:
			_hang_btn_note("LX")
		if y_edge:
			_hang_btn_note("LY")
	# Fix Pass 11 (Item 1): squeeze BOTH grips = recenter.
	# Fix Pass 13 (Item 4): gated by _recenter_allowed().
	if _btn_edge("both_grips", bool(gripping["L"]) and bool(gripping["R"])) and _recenter_allowed():
		_recenter()
	# Right A: boost (hang rules in the item header).
	if mode == MODE_HANG and a_now:
		boost_arm_blocked = true
	if not a_now:
		boost_arm_blocked = false
	if a_now and not boost_arm_blocked:
		in_boost = true
	# Left X: the drone call - DRIVE only, unchanged.
	if x_edge and mode == MODE_DRIVE:
		_call_crane()
	# Fix Pass 12 (Item 2): the right B button is the PANEL
	# toggle (the owner's run-12 ask). Deliberate in every
	# mode, hang included - and logged there like the rest.
	if b_edge:
		_toggle_panels()
	# Left Y: restart (hang long-press in the item header).
	if y_now:
		y_hold_t += delta
		if mode == MODE_HANG:
			if y_hold_t >= HANG_RESTART_HOLD_S and not y_hold_fired:
				y_hold_fired = true
				start_race()
		elif y_edge:
			start_race()
	else:
		y_hold_t = 0.0
		y_hold_fired = false
	if _btn_edge("l_stick_click", _btn_state("L", lc, &"primary_click")):
		_recenter()
	if _btn_edge("r_stick_click", _btn_state("R", rc, &"primary_click")):
		_toggle_jitter()


func _input(event: InputEvent) -> void:
	var k: InputEventKey = event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_SPACE:
			# Fix Pass 22: the desktop twin of the drop button
			# follows it - on the chains, any phase, it drops.
			if mode == MODE_HANG:
				_do_release()
		KEY_L:
			if mode == MODE_DRIVE:
				_call_crane()
		KEY_T:
			_toggle_lean()
		KEY_V:
			_cycle_track()
		KEY_J:
			_toggle_jitter()
		KEY_G:
			_toggle_view_gain()
		KEY_M:
			_toggle_drop_btn_side()
		KEY_R:
			start_race()
		KEY_TAB:
			_toggle_panels()
		KEY_C:
			_recenter()



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
		drop_btn_left = bool(cfg.get_value("lever", "left", false))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("seat", "trim", seat_trim)
	cfg.set_value("lever", "left", drop_btn_left) # the key predates the button (FP20) and is kept
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


func _view_gain() -> float:
	# Fix Pass 14 (Item 6): the A/B view-coupling gain. A is
	# the shipped VIEW_PITCH_GAIN (the seat adds 0.6x of the
	# spring pitch/roll on top of the placement basis, which
	# already carries them at 1.0x); B makes the seat add the
	# full motion - camera = car. The view path holds NO lag
	# or smoothing state (the offsets are pure functions of
	# the current physics state), so B's added lag over A is
	# zero frames by construction; what changes is amplitude
	# only. The heave channel and the body-spring layer are
	# NOT scaled in either mode.
	return 1.0 if view_gain_mode == 1 else VIEW_PITCH_GAIN


func _toggle_view_gain() -> void:
	view_gain_mode = 1 - view_gain_mode


# Fix Pass 15 (Item 3) set the side mechanism; Fix Pass 20
# (Item 1) retargets it on the DROP BUTTON. _apply places the
# button + bracket on the face at the current side (build,
# toggle, and any future caller share it); _toggle flips,
# applies, and persists with the seat trim.
func _apply_drop_btn_side() -> void:
	var sx: float = -DROP_BTN_FACE_X if drop_btn_left else DROP_BTN_FACE_X
	if drop_btn_node != null:
		drop_btn_node.position = Vector3(sx, DROP_BTN_FACE_Y, DROP_BTN_FACE_Z)
	if drop_btn_bracket != null:
		drop_btn_bracket.position = Vector3(sx, DROP_BTN_FACE_Y, DROP_BTN_FACE_Z - 0.065)


func _toggle_drop_btn_side() -> void:
	drop_btn_left = not drop_btn_left
	_apply_drop_btn_side()
	_save_settings()
	_update_panel()
	# Fix Pass 16 (Item 4): the flip is ANNOUNCED on the
	# touchdown readout (run 15's flip was silent and only
	# discovered later). The DIAG DROP line and the persisted
	# setting already name the side; now the moment does too.
	if contact_label != null:
		contact_label.text = "DROP SIDE: %s" % ("LEFT" if drop_btn_left else "RIGHT")
		contact_readout_t = 2.5


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


## Fix Pass 20 (Item 1): the drop button's point in world
## space - the dash family's point measure runs on it (the
## FP11-FP19 lever had a grab SEGMENT here; a button has a
## point, and its volume is the dash radius about it).
## Shared by the stages and the render proof's overlay.
func debug_drop_btn_point() -> Vector3:
	if drop_btn_node == null:
		return Vector3.ZERO
	return drop_btn_node.global_position


func _press_drop_button(hand: String) -> void:
	# Fix Pass 20 (Item 1): the drop button's one press, with
	# the owner's law applied - "a thing that doesn't
	# interact is boring and frustrating": the press REGISTERS
	# in every phase (the dip, the tick, and a BTN line in the
	# grab log, phase-tagged), and what it DOES is the
	# context:
	#   on the chains -> FIRE: the release.
	#   drive/air     -> PRESS: it answers (a dull tick) and
	#                    does nothing - not on chains, nothing
	#                    to release. It never sits mute.
	# Fix Pass 22 (Item 1): FP20's middle row - attach/carry
	# SPENT, the chains hold, the refusal grinds - is DELETED
	# by the owner's run-19 ruling, delivered with the button
	# in his hands: "when you're being droned... the button
	# doesn't release you even though you're over track. It
	# won't activate until the text changes to something or
	# other. Need to get rid of that. If you're on chains, the
	# button works. period. Not over the track? Don't press
	# the button." The gate was the defect: on the chains -
	# ANY hang phase, any position - the press fires the
	# release, and where the car falls is the driver's
	# business. (The grind machinery went with the SPENT
	# outcome it served: there is no un-armed state left for
	# a refusal to refuse.)
	var g20: float = float(diag_grip[hand])
	if mode == MODE_HANG:
		_grab_event("%s BTN FIRE %s g%.2f" % [hand, hang_phase, g20])
		_pulse_detent(hand)
		_do_release()
	else:
		var ph20: String = "drive" if mode == MODE_DRIVE else ("air" if mode == MODE_AIR else "done")
		_grab_event("%s BTN PRESS %s g%.2f" % [hand, ph20, g20])
		_pulse_hand(hand, 0.25, 0.05)


func _pulse_hand(hand: String, amp: float, dur: float) -> void:
	# Fix Pass 16 (Item 1): the one haptic door. A short pulse
	# on one hand through the action map's existing "haptic"
	# output action. Null-safe - no live interface (tests,
	# desktop) means no pulse and no error. Whether a pulse is
	# perceptible on the live rig is the owner's verdict:
	# unverifiable headless, listed as such in the pass report.
	# API guarded: XRInterface.trigger_haptic_pulse (the call
	# lives on the BASE class, not OpenXRInterface).
	if not xr_ok or xr_iface == null:
		return
	xr_iface.trigger_haptic_pulse(&"haptic",
		&"left_hand" if hand == "L" else &"right_hand", 0.0, amp, dur, 0.0)


func _pulse_detent(hand: String) -> void:
	# The detent is FELT (Fix Pass 11): the strong pulse, kept
	# distinct from Item 1's lighter latch/candidate ticks.
	_pulse_hand(hand, 0.7, 0.12)


func _grab_event(ev: String) -> void:
	# Fix Pass 16 (Item 5): one telemetry event - into the ring,
	# onto the DIAG GRAB line (via grab_last_event), and into
	# the session log file when it is open.
	grab_last_event = ev
	grab_events.append("T%.1f %s" % [race_time, ev])
	while grab_events.size() > 400:
		grab_events.pop_front()
	if grab_log_file != null:
		grab_log_file.store_line("T%.1f %s" % [race_time, ev])
		grab_log_file.flush()


func _hand_owner(hand: String) -> String:
	# Fix Pass 17 (Item 1): hand ownership - the grab path's
	# arbitration state. A hand owns at most one control class
	# at a time: the wheel (driver), the rim (passenger), or a
	# dash latch (one-shots and the seat trims alike). Every
	# acquisition in _poll_grab is gated on the hand owning
	# NOTHING - or the dash class itself, for Fix Pass 9's
	# squeeze-and-sweep between dash controls. Ownership ends
	# only on grip release (the FP16 latches' own clearing),
	# never on a zone exit. The owner's own run-16 log
	# convicted the need: at T14.8 one squeeze both fired the
	# drop lever and rim-attached (L RIM ATT + L DRP FIRE) -
	# with the wheel free, that hand could have latched the
	# WHEEL and pulled a steer instead of a drop.
	# Fix Pass 20 (Item 1): the drop control is a dash latch
	# now, so the "lever" owner class is retired with the
	# lever - a button press and a rim attach can no more
	# share a squeeze than the pull and the attach could.
	if grab_hand == hand:
		return "wheel"
	if bool(rim_attach[hand]):
		return "rim"
	if int(dash_ctl_fired[hand]) >= 0:
		return "dash"
	return ""


func _poll_grab(hand: String, ctrl: XRController3D, _delta: float) -> void:
	# Fix Pass 16 (Item 1) - OPERATION FIX THE FUCKING LEVERS:
	# this function was rebuilt around the Item 0 differential
	# (see the README's FP16 section). The design rules:
	#   - The squeeze is the ANALOG FLOAT ONLY, through our own
	#     Schmitt trigger (GRIP_ENGAGE / GRIP_RELEASE). FP15's
	#     `grip_v > 0.65 or grip_click or grip_force > 0.65`
	#     OR-term imported the runtime's undocumented bool
	#     threshold (grip_click is squeeze/value through VDXR's
	#     own conversion - no squeeze/click endpoint exists on
	#     Touch Plus) and read a channel with no binding in any
	#     profile (grip_force - no squeeze/force endpoint on
	#     this hardware; its DIAG column read 0.00 forever).
	#     Click is still READ, for the DIAG block only.
	#   - LATCH semantics (the XR Tools / VTOL pattern): a grab,
	#     once honestly made, ends on grip RELEASE - never on a
	#     zone exit, a radius, or a one-frame value dip. One-shot
	#     dash latches clear only on release, so a leave-and-
	#     return inside one squeeze cannot double-toggle; the
	#     seat levers trim on the latch, in or out of the zone;
	#     the wheel tracks its hand at any radius (soft lock).
	#   - Zone tests are SWEPT: the segment the hand travelled
	#     this frame (prev -> now), not just its endpoint.
	var grip_v: float = _input_float(ctrl, &"grip")
	var grip_click: bool = _input_bool(ctrl, &"grip_click")
	# Fix Pass 8 (Item 0): test_mode substitutes the synthetic
	# grip level for the controller's channels, so the latch /
	# proximity / activation logic below is the production code
	# running on posed inputs. The XR reads above are what the
	# headset path uses; they are API-guarded - what no headless
	# run can reproduce is a runtime delivering stuck VALUES.
	if test_mode:
		grip_v = float(test_grip[hand])
		grip_click = false
	diag_grip[hand] = grip_v
	diag_click[hand] = grip_click
	grab_peak[hand] = maxf(float(grab_peak[hand]), grip_v)
	# The Schmitt trigger. gripping[] IS this state - every
	# downstream reader (articulation, the recenter gate, the
	# hang button gates) gets the debounced value.
	var held: bool = bool(gripping[hand])
	if held and grip_v < GRIP_RELEASE:
		held = false
	elif not held and grip_v > GRIP_ENGAGE:
		held = true
	gripping[hand] = held
	# Chatter accounting (Item 5): a held grab whose squeeze
	# dips below the OLD 0.65 cut without reaching GRIP_RELEASE
	# is a grab FP15's latch would have dropped mid-use. Count
	# the episode once; the session log carries the total.
	if held and grip_v < 0.65:
		if not bool(grab_in_band[hand]):
			grab_in_band[hand] = true
			grab_chatter_count += 1
	else:
		grab_in_band[hand] = false
	var pos: Vector3 = _hand_pos(hand)
	var prev: Vector3 = pos
	if bool(prev_hand_valid[hand]):
		prev = prev_hand_pos[hand]
	# A sweep longer than this is not a pass-through - it is a
	# TELEPORT (tracking loss + reacquisition, or a posed jump):
	# test the endpoint only. An uncapped sweep drags through
	# every zone on its path - its first conviction was the
	# suite's own stage 25, where the latch poll's sweep crossed
	# RESTART and reset the race mid-sequence (hang phase back
	# to "attach", the detent fire gated, no drop). A live
	# dropout + reacquire across the cockpit would have done
	# the same to the owner. 0.25 m per physics frame is
	# 15 m/s of hand - far past any real pass-through.
	if prev.distance_to(pos) > 0.25:
		prev = pos
	# Fix Pass 17 (Item 1): cross-class arbitration. An unowned,
	# held hand inside several tests in the same frame takes
	# the NEAREST (the tests' own distances, swept like the
	# acquisitions they gate); entries in different frames are
	# ordered by ownership itself - the first acquisition owns
	# the hand until release, so later arrivals never evaluate.
	# Exact ties resolve in this poll's own order: dash, wheel
	# (strict <, first minimum kept). The loser records
	# nothing: no latch, no attach, no event.
	# Fix Pass 20 (Item 1): the drop lever's own candidate is
	# gone - the DROP BUTTON is a dash control, so it competes
	# inside the dash distance like every other button.
	var owner17: String = _hand_owner(hand)
	var win17: String = ""
	if held and owner17 == "":
		var d_dash17: float = 1e9
		var d_wheel17: float = 1e9
		var cd17: Array = _dash_ctl_near_swept_d(prev, pos)
		if int(cd17[0]) >= 0:
			d_dash17 = float(cd17[1])
		var wl17: bool = mode == MODE_DRIVE or mode == MODE_AIR \
			or (mode == MODE_HANG and hang_phase == "dangle")
		if wl17 and grab_hand == "":
			d_wheel17 = _seg_point_dist(prev, pos, car.global_transform * _wheel_hub_local())
			if d_wheel17 >= WHEEL_GRAB_RADIUS:
				d_wheel17 = 1e9
		var best17: float = 1e9
		if d_dash17 < best17:
			best17 = d_dash17
			win17 = "dash"
		if d_wheel17 < best17:
			best17 = d_wheel17
			win17 = "wheel"
	# Item 5 telemetry: a zone ENTRY with no latch is the
	# near-miss signature - it separates "the hand never
	# arrived" (no entry) from "the grip never read" (entry,
	# low value) in the owner's own log.
	var zone_now: int = _dash_ctl_near(pos)
	if zone_now != int(prev_zone[hand]):
		if zone_now >= 0 and not held:
			_grab_event("%s ZONE %s g%.2f NOLAT" % [hand,
				dash_ctl_kinds[zone_now].to_upper(), grip_v])
		prev_zone[hand] = zone_now
	# --- (the drop lever's latch block stood here FP11-FP19;
	# Fix Pass 20 (Item 1) deleted it with the lever. The DROP
	# BUTTON is a dash control: its press is the "drop" case
	# in the dash branch below.) ---
	# --- DASH CONTROLS (Fix Pass 9's level activation, Item 1's latch) ---
	# A gripping hand inside a control's volume fires it ONCE
	# per latch (dash_ctl_fired); the latch now clears ONLY on
	# grip release, so zone exits and value dips inside one
	# squeeze can neither re-fire a toggle nor stop a held seat
	# lever. Moving zone-to-zone inside one squeeze still fires
	# each control on entry - squeeze-and-sweep is the gesture.
	# Fix Pass 16 (Item 4): the SIDE button is the exception -
	# entry starts a deliberate hold (SIDE_HOLD_S), not a fire.
	var ctl_now: int = _dash_ctl_near_swept(prev, pos) if held else -1
	if not held:
		# Fix Pass 17 (Item 2): a seat lever's release is logged
		# (the lever-class REL - the drop lever's DRP REL twin;
		# the seat trims share the latch path, so their latch
		# ends are witnessed the same way). One-shot buttons log
		# nothing here: their FIRE is the record.
		var rel17: int = int(dash_ctl_fired[hand])
		if rel17 >= 0 and rel17 < dash_ctl_kinds.size() and dash_ctl_kinds[rel17].begins_with("seat"):
			_grab_event("%s %s REL g%.2f" % [hand, dash_ctl_kinds[rel17].to_upper(), grip_v])
		dash_ctl_fired[hand] = -1
		side_hold_t[hand] = 0.0
	elif ctl_now >= 0 and (owner17 == "dash" or win17 == "dash"):
		# FP17 (Item 1): a hand owning the wheel or the rim
		# cannot take a dash control mid-squeeze; a dash owner
		# keeps the FP9 sweep, and an unowned hand takes the
		# control only when the dash won arbitration.
		var kind: String = dash_ctl_kinds[ctl_now]
		if kind == "drop" and int(dash_ctl_fired[hand]) != ctl_now:
			# Fix Pass 20 (Item 1): the DROP BUTTON's press. The
			# latch is the dash one-shot (one press per squeeze,
			# clears on release); what the press DOES is the
			# phase's business (see _press_drop_button) - the
			# generic FIRE line would lie about two of the
			# three outcomes, so the button logs its own.
			dash_ctl_fired[hand] = ctl_now
			grab_drop_count += 1
			_press_drop_button(hand)
		elif kind == "side" and int(dash_ctl_fired[hand]) != ctl_now:
			side_hold_t[hand] = float(side_hold_t[hand]) + _delta
			if float(side_hold_t[hand]) >= SIDE_HOLD_S:
				dash_ctl_fired[hand] = ctl_now
				side_hold_t[hand] = 0.0
				grab_fire_count += 1
				_grab_event("%s SIDE FIRE g%.2f" % [hand, grip_v])
				_pulse_hand(hand, 0.35, 0.06)
				_activate_dash_ctl(kind)
		elif kind.begins_with("seat"):
			if int(dash_ctl_fired[hand]) != ctl_now:
				dash_ctl_fired[hand] = ctl_now
				_grab_event("%s %s LAT g%.2f" % [hand, kind.to_upper(), grip_v])
				_pulse_hand(hand, 0.35, 0.06)
			var sdir: float = 1.0 if kind == "seatup" else -1.0
			_apply_seat_trim(seat_trim + sdir * SEAT_TRIM_RATE * _delta)
		elif int(dash_ctl_fired[hand]) != ctl_now:
			dash_ctl_fired[hand] = ctl_now
			grab_fire_count += 1
			_grab_event("%s %s FIRE g%.2f" % [hand, kind.to_upper(), grip_v])
			_pulse_hand(hand, 0.35, 0.06)
			_activate_dash_ctl(kind)
	else:
		# Held, outside every volume: a latched seat lever keeps
		# trimming on its latch; the SIDE hold clock resets (the
		# hold must be IN the zone - deliberate means staying).
		var fi: int = int(dash_ctl_fired[hand])
		if fi >= 0 and fi < dash_ctl_kinds.size() and dash_ctl_kinds[fi].begins_with("seat"):
			var sdir2: float = 1.0 if dash_ctl_kinds[fi] == "seatup" else -1.0
			_apply_seat_trim(seat_trim + sdir2 * SEAT_TRIM_RATE * _delta)
		side_hold_t[hand] = 0.0
	# --- THE WHEEL (soft lock) ---
	# Fix Pass 13 (Item 3): the wheel is also live in the
	# DANGLE - the driver dials in the landing lock while the
	# car hangs, and _do_release/_land never reset wheel_angle,
	# so the lock carries into the drive. Transport does not
	# arm it: the gate is the dangle phase, not MODE_HANG alone.
	var wheel_live: bool = mode == MODE_DRIVE or mode == MODE_AIR \
		or (mode == MODE_HANG and hang_phase == "dangle")
	if not wheel_live:
		if grab_hand == hand:
			grab_hand = ""
		rim_attach[hand] = false
		prev_hand_pos[hand] = pos
		prev_hand_valid[hand] = true
		return
	var hub_w: Vector3 = car.global_transform * _wheel_hub_local()
	if grab_hand == hand:
		if not held:
			grab_hand = ""
			_grab_event("%s WHEEL REL g%.2f" % [hand, grip_v])
			# other hand takes over if it is still gripping the wheel
			var other: String = "R" if hand == "L" else "L"
			if bool(gripping[other]) and _hand_pos(other).distance_to(hub_w) < WHEEL_GRAB_RADIUS \
					and (_hand_owner(other) == "" or _hand_owner(other) == "rim"):
				# FP17 (Item 1): the takeover is an acquisition too -
				# a hand owning the lever or a dash latch cannot be
				# handed the wheel; a rim passenger promotes freely.
				grab_hand = other
				grab_prev_ang = _hand_wheel_angle(other)
		else:
			# Soft lock: the latched hand steers at ANY radius -
			# the angle is read about the hub, so an arm that
			# extends through a big turn never drops the wheel.
			var ang: float = _hand_wheel_angle(hand)
			var d: float = wrapf(ang - grab_prev_ang, -PI, PI)
			wheel_angle = clampf(wheel_angle + d, -PI, PI)
			grab_prev_ang = ang
	elif held and grab_hand == "" \
			and _seg_point_dist(prev, pos, hub_w) < WHEEL_GRAB_RADIUS \
			and win17 == "wheel": # FP17 (Item 1): arbitration - see the candidate block above (FP20: the lever-hand term is gone with the lever; arbitration carries the exclusion)
		# Fix Pass 16 (Item 3): the latch takes only a FREE wheel.
		# FP15's branch let a second gripping hand STEAL the
		# wheel (re-basing grab_prev_ang to its own angle), so
		# two held hands fought over grab_hand every frame and
		# neither ever read as holding - half the both-hands
		# defect, in the latch itself. A gripping hand on an
		# OWNED wheel is the passenger instead (rim attach).
		grab_hand = hand
		grab_prev_ang = _hand_wheel_angle(hand)
		grab_wheel_count += 1
		_grab_event("%s WHEEL LAT g%.2f" % [hand, grip_v])
		_pulse_hand(hand, 0.35, 0.06)
	if grab_hand == "" and mode == MODE_DRIVE:
		wheel_angle = move_toward(wheel_angle, 0.0, 1.6 * _delta)
	_update_rim_attach(hand, held, pos)
	# --- the CANDIDATE cue (Item 1's witness) ---
	# The nearest control this hand could take right now. A new
	# candidate while ungripped earns a faint tick - XR Tools'
	# acquisition pulse - so "my hand is on something" is felt
	# BEFORE the squeeze, not discovered after a silent miss.
	var ck: String = ""
	var cc: int = -1
	if zone_now >= 0:
		ck = "dash"
		cc = zone_now
	elif pos.distance_to(hub_w) < WHEEL_GRAB_RADIUS:
		ck = "wheel"
	if ck != String(cand_kind[hand]):
		cand_kind[hand] = ck
		if ck != "" and not held and race_time >= float(cand_tick_t[hand]):
			cand_tick_t[hand] = race_time + 0.25
			_pulse_hand(hand, 0.18, 0.04)
	cand_ctl[hand] = cc
	prev_hand_pos[hand] = pos
	prev_hand_valid[hand] = true


func _seg_seg_dist(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	# Closest distance between two segments (Ericson's
	# segment-segment closest point). The swept zone tests are
	# built on it: a hand's per-frame travel vs a control's
	# grab segment.
	var d1: Vector3 = q1 - p1
	var d2: Vector3 = q2 - p2
	var r: Vector3 = p1 - p2
	var a: float = d1.dot(d1)
	var e: float = d2.dot(d2)
	var f: float = d2.dot(r)
	var s: float = 0.0
	var t: float = 0.0
	if a <= 1e-9 and e <= 1e-9:
		return r.length()
	if a <= 1e-9:
		t = clampf(f / e, 0.0, 1.0)
	else:
		var c: float = d1.dot(r)
		if e <= 1e-9:
			s = clampf(-c / a, 0.0, 1.0)
		else:
			var b: float = d1.dot(d2)
			var denom: float = a * e - b * b
			s = clampf((b * f - c * e) / denom, 0.0, 1.0) if denom > 1e-9 else 0.0
			t = (b * s + f) / e
			if t < 0.0:
				t = 0.0
				s = clampf(-c / a, 0.0, 1.0)
			elif t > 1.0:
				t = 1.0
				s = clampf((b - c) / a, 0.0, 1.0)
	return (p1 + d1 * s - (p2 + d2 * t)).length()


func _dash_ctl_near_swept(a: Vector3, b: Vector3) -> int:
	# The swept twin of _dash_ctl_near: the hand's travel this
	# frame against every control's grab segment, each with
	# its own radius; nearest wins, as in the point test.
	var best: int = -1
	var best_d: float = 1e9
	for i: int in dash_ctl_nodes.size():
		var seg: Array[Vector3] = _dash_ctl_segment(i)
		var d: float = _seg_seg_dist(a, b, seg[0], seg[1])
		if d < _dash_ctl_radius(i) and d < best_d:
			best_d = d
			best = i
	return best


func _dash_ctl_near_swept_d(a: Vector3, b: Vector3) -> Array:
	# Fix Pass 17 (Item 1): the swept dash test with its winning
	# distance - the cross-class arbitration in _poll_grab
	# compares the tests' own distances, so the point/swept pair
	# gains a third sibling that reports how near the nearest
	# control was. Returns [index, distance]; index -1 and
	# distance 1e9 when nothing is inside its radius.
	var best: int = -1
	var best_d: float = 1e9
	for i: int in dash_ctl_nodes.size():
		var seg: Array[Vector3] = _dash_ctl_segment(i)
		var d: float = _seg_seg_dist(a, b, seg[0], seg[1])
		if d < _dash_ctl_radius(i) and d < best_d:
			best_d = d
			best = i
	return [best, best_d]


func _update_rim_attach(hand: String, held: bool, pos: Vector3) -> void:
	# Fix Pass 16 (Item 3): the passenger hand rides the rim.
	# The DRIVING hand's rim point is glued by construction
	# (the wheel's angle deltas come from its own motion, so
	# the rim point under it never slips); a second gripping
	# hand on the rim instead gets its grab point stored in
	# wheel-spin local space, and _refresh_car_visuals poses
	# its rep from the spin node - both hands read as holding
	# the wheel. Attach requires: this hand gripping, on the
	# rim, and the OTHER hand driving. It ends on release, on
	# becoming the driver, or when the wheel goes non-live
	# (the caller clears it on that path).
	var other: String = "R" if hand == "L" else "L"
	var want: bool = held and grab_hand == other \
		and pos.distance_to(car.global_transform * _wheel_hub_local()) < WHEEL_GRAB_RADIUS \
		and int(dash_ctl_fired[hand]) < 0
	# FP17 (Item 1): the attach is gated on the hand owning
	# nothing else - run 16's T14.8 (RIM ATT in the same instant
	# as DRP FIRE) cannot recur: a dash-latched hand (FP20: the
	# drop button's press included) never attaches.
	if want and not bool(rim_attach[hand]):
		rim_attach[hand] = true
		rim_local[hand] = wheel_spin.global_transform.affine_inverse() * pos
		_grab_event("%s RIM ATT g%.2f" % [hand, float(diag_grip[hand])])
	elif not want and bool(rim_attach[hand]):
		rim_attach[hand] = false


# Fix Pass 5 (Item 2): lever-shaped controls (the seat levers; the
# prep switches this was written for were deleted in Fix Pass 13) are
# measured to their GRAB SEGMENT - base of the shaft to the cap - not
# to a point at the tip. Chris's hand arrives at the shaft; the old
# point measure (at the pivot origin the coloured cap sits ~0.19 m
# along the lever from) left the tip as the only reliably live spot.
# Buttons keep the point measure.
func _dash_ctl_segment(i: int) -> Array[Vector3]:
	var node: Node3D = dash_ctl_nodes[i]
	if dash_ctl_kinds[i].begins_with("seat"):
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


func _dash_ctl_radius(i: int) -> float:
	# Fix Pass 16 (Item 2): capture radii are per-control and
	# DECOUPLED from the meshes - the seat levers (smaller
	# furniture after this pass) carry the generous volume;
	# the buttons keep FP4's near-touch 0.15.
	return DASH_CTL_RADIUS_SEAT if dash_ctl_kinds[i].begins_with("seat") else DASH_CTL_RADIUS


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
	var best_d: float = 1e9
	for i: int in dash_ctl_nodes.size():
		var seg: Array[Vector3] = _dash_ctl_segment(i)
		var d: float = _seg_point_dist(seg[0], seg[1], world_pos)
		if d < _dash_ctl_radius(i) and d < best_d:
			best_d = d
			best = i
	return best


func _activate_dash_ctl(kind: String) -> void:
	if kind == "restart":
		start_race()
	elif kind == "lean":
		_toggle_lean()
	elif kind == "track":
		_cycle_track()
	elif kind == "view":
		_toggle_view_gain()
	elif kind == "side":
		_toggle_drop_btn_side()


# ---------------------------------------------------------------- actions

func start_race() -> void:
	# Fix Pass 16 (Item 5): close the previous race's grab
	# account into the session log before the state resets -
	# fires, latches, early releases, rescued chatter dips, and
	# each hand's session squeeze peak (a channel that never
	# rises, or a squeeze that never peaks, reads here).
	if grab_fire_count + grab_wheel_count + grab_drop_count + grab_chatter_count > 0:
		_grab_event("SUMMARY fire %d wheel %d drop %d early %d chatter %d peak L %.2f R %.2f" % [
			grab_fire_count, grab_wheel_count, grab_drop_count,
			grab_early_count, grab_chatter_count,
			float(grab_peak["L"]), float(grab_peak["R"])])
	mode = MODE_HANG
	hang_phase = "attach" # Fix Pass 13 (Item 6): Drop Start is a pickup + transport now
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
	boost_meter = BOOST_START_STOCK # Fix Pass 24: the stake (was the whole one-shot ration)
	dent_level = 0
	last_pay_units = 0.0 # Fix Pass 24: no payout yet this race
	last_pay_air_s = 0.0
	last_pay_grade = "-"
	pay_flash_t = 0.0
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
	anchor_target = fr["pos"] + Vector3.UP * (HANG_LEN + HANG_CLEAR)
	# Fix Pass 13 (Item 6) made Drop Start a pickup; Fix Pass
	# 15 (Item 2) changes the rig, not the shape: the car
	# starts ON THE SERVICE PAD beside the start line - the
	# pickup point, CRANE_PICKUP_OFF beyond the ribbon edge
	# at road height - the crane stands over the drop piece,
	# the chains attach, the winch lifts the car to hang
	# height, and the trolley slews it sideways to the
	# station over the road. The drone's climb-cruise-descend
	# transport is gone; the slew is the whole journey.
	# anchor_target above is unchanged (the FP2 station).
	var pickup: Vector3 = Vector3(fr["pos"]) + Vector3(fr["side"]) * (HALF_WIDTH + CRANE_PICKUP_OFF)
	pickup.y = float(fr["pos"].y) + 0.4
	hang_from_pos = pickup
	car.global_position = pickup
	# The pivot rides at the rig's fixed height over the DROP
	# piece's road - the same height as the station, so the
	# attach lift is exactly the car's rest offset (0.8 m).
	anchor_pos = Vector3(pickup.x, float(fr["pos"].y) + HANG_LEN + HANG_CLEAR, pickup.z)
	pivot_pos = anchor_pos
	anchor_t = 0.0
	carrier_vel = Vector3.ZERO
	carrier_accel = Vector3.ZERO
	carrier_path.clear()
	carrier_wp = 0
	carrier_path.append(anchor_target)
	carrier_yaw = _frame_yaw(fr["tan"])
	orient_yaw = carrier_yaw
	orient_yaw_v = 0.0
	_place_crane(drop_target_s)
	# Fix Pass 5: bigger, out-of-phase starting swing (see PEND_LEN_*).
	# Fix Pass 13 (Item 6): the seed is set at ATTACH and the
	# pendulum evolves continuously through the carry - the
	# swing judged at the drop is the journey's own, never a
	# state imposed at the station.
	pend_th_f = 0.34
	pend_th_l = 0.26
	pend_om_f = 0.0
	pend_om_l = 0.0
	_capture_lean_neutral()
	_refresh_car_visuals()


func _reset_suspension() -> void:
	c_f = SUSP_REST
	c_r = SUSP_REST
	cv_f = 0.0
	cv_r = 0.0
	susp_c = [SUSP_REST, SUSP_REST, SUSP_REST, SUSP_REST]
	susp_cv = [0.0, 0.0, 0.0, 0.0]
	susp_geom = [0.0, 0.0, 0.0, 0.0]
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
	pending_rebound = false
	air_from_rebound = false
	air_from_release = false
	rebound_gate_vy = 0.0
	deep_hit_age = 9.0
	bounce_chain = 0
	grounded_t = 0.0
	# Fix Pass 9: per-wheel support back to fully held.
	sup_rise = [0.0, 0.0, 0.0, 0.0]
	sup_ok = [true, true, true, true]
	sup_s = [0.0, 0.0, 0.0, 0.0]
	sup_over = [0.0, 0.0, 0.0, 0.0] # Fix Pass 15 (Item 1)
	sup_lat = [0.0, 0.0, 0.0, 0.0] # Fix Pass 21
	wheel_kv = [0.0, 0.0, 0.0, 0.0] # Fix Pass 21
	wheel_load = [1.0, 1.0, 1.0, 1.0] # Fix Pass 21
	wheel_air = [false, false, false, false] # Fix Pass 21
	wheel_air_frames = [0, 0, 0, 0] # Fix Pass 21
	edge_rumble_now = 0.0
	edge_scrape_now = 0.0
	tire_ratio = 0.0
	tire_band = 0.0
	edge_roll = 0.0


func _reset_dangle_feel() -> void:
	# Fix Pass 10 (Item 2): the dip state is the FLOWN-dip state
	# (progress/depth/cadence); the procedural pivot offset is gone.
	# Fix Pass 15 (Item 2): the dips read as WINCH dips now, and
	# the nudge state is the gust + jib-flex pair.
	dip_t = -1.0
	dip_depth = 0.0
	dip_timer = 2.0
	dip_seed = 0
	gust_seed = 0
	gust_t = 0.0
	gust_off = Vector2.ZERO
	flex_off = Vector2.ZERO
	slack_t = 0.0
	catch_t = 1.0
	orient_have = false


func _call_crane() -> void:
	if mode != MODE_DRIVE:
		return
	_begin_recovery(car.global_position, car_s)


func _begin_recovery(_catch_pos: Vector3, from_s: float) -> void:
	mode = MODE_HANG
	is_drop_start = false
	speed = 0.0
	lat_vel = 0.0
	vel2 = Vector2.ZERO
	yaw_rate = 0.0
	edge_roll = 0.0
	hang_phase = "attach"
	anchor_t = 0.0
	drop_target_s = _find_drop_s(from_s)
	var fr: Dictionary = _frame_at(drop_target_s)
	# Fix Pass 2: world-up hang anchor (see start_race) - the car must
	# hang centred over the ribbon, not offset along a tilted frame up.
	anchor_target = fr["pos"] + Vector3.UP * (HANG_LEN + HANG_CLEAR)
	# Fix Pass 15 (Item 2): THE COLLECTION HAPPENS OFF-STAGE.
	# The drone era's problem was never one bug: FP10 retraced
	# the road with the car dangling (1911 frames home), FP12
	# added a clearance profile (still ~1500), FP13 split
	# travel from the hang and flew direct - and the owner's
	# run-14 verdict closed the file ("the DRONE, good lord,
	# it just gets worst. its doing loop de loops now... we'll
	# just use crane"). The original never showed a collection
	# at all: the car comes back on the crane at the drop
	# piece. So the fall site is abandoned where it lies -
	# _catch_pos now serves only the caller's bookkeeping -
	# and the car is placed on the service pad under the rig,
	# exactly as at the Drop Start: attach, lift, slew,
	# dangle. anchor_target itself is untouched: the dangle
	# station is exactly where Fix Pass 2 put it. The wheel
	# still latches only in the dangle; the DROP BUTTON,
	# since Fix Pass 22, fires from any phase (on chains it
	# drops you, period - an early press just falls from
	# wherever the slew had reached). The pendulum state is
	# never touched by the phase transitions, so the swing
	# the car arrives with is the swing it dangles with.
	var pickup: Vector3 = Vector3(fr["pos"]) + Vector3(fr["side"]) * (HALF_WIDTH + CRANE_PICKUP_OFF)
	pickup.y = float(fr["pos"].y) + 0.4
	hang_from_pos = pickup
	car.global_position = pickup
	anchor_pos = Vector3(pickup.x, float(fr["pos"].y) + HANG_LEN + HANG_CLEAR, pickup.z)
	pivot_pos = anchor_pos
	carrier_vel = Vector3.ZERO
	carrier_accel = Vector3.ZERO
	carrier_yaw = _frame_yaw(fr["tan"])
	station_wait_t = 0.0
	carrier_path.clear()
	carrier_wp = 0
	carrier_path.append(anchor_target)
	_place_crane(drop_target_s)
	_reset_dangle_feel()
	# The pendulum seeds on the rig's own fixed swing (the
	# Drop Start's shape, slightly smaller) - the fall's
	# geometry no longer reaches into the hang.
	pend_th_f = 0.30
	pend_th_l = 0.22
	pend_om_f = 0.0
	pend_om_l = 0.0


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
	if mode != MODE_HANG:
		return
	# Fix Pass 22 (Item 1): the phase gate that stood here
	# (dangle only) is DELETED - the owner's run-19 ruling:
	# on the chains, the button drops you, from any phase.
	# The DANGLE path below is byte-identical to FP20. An
	# off-station (attach/carry) release differs only where
	# the crane's state honestly differs:
	#   - it falls from where the car IS: the section under
	#     the car seeds the air (air_s_est / air_start_s) and
	#     takes the heading record, not the drop station;
	#   - it keeps the carrier's horizontal velocity - the
	#     pivot is moving mid-slew, and the car's world
	#     velocity is the pivot's plus the pendulum tip's.
	# The pendulum axes stay the drop frame's in every phase
	# (_step_pendulum), so the tip construction is unchanged.
	var at_station: bool = hang_phase == "dangle"
	var rel_s: float = drop_target_s if at_station else _project_wide_s(car.global_position)
	var fr: Dictionary = _frame_at(drop_target_s)
	var sec_fr: Dictionary = fr if at_station else _frame_at(rel_s)
	var f: Vector3 = fr["tan"]
	var r: Vector3 = fr["side"]
	# pendulum tip velocity + a little forward push: you drop swinging
	var tip: Vector3 = (f * (pend_om_f * cos(pend_th_f)) + r * (pend_om_l * cos(pend_th_l))) * HANG_LEN
	# Fix Pass 5: the swing state at release IS the drop - both axes'
	# tip velocity carries in (timing the release stays the skill),
	# and a release mid-slack keeps the car's free-fall velocity.
	air_vel = tip + f * 3.0
	if not at_station:
		air_vel += Vector3(carrier_vel.x, 0.0, carrier_vel.z)
	if slack_t > 0.0:
		air_vel = hang_vel + f * 3.0
	# Fix Pass 10 (Item 2): the carrier's vertical motion at the
	# release carries in (was the procedural dip velocity).
	air_vel.y += carrier_vel.y * 0.5
	air_s_est = rel_s
	air_start_s = rel_s # a botched release falls from HERE
	air_time = 0.0
	below_band_t = 0.0 # FP12: a release is a new air episode
	lost_lat_t = 0.0
	air_exit_y = float(_frame_at(rel_s)["pos"].y)
	air_from_gap = false
	air_from_release = true # FP14 (Item 1): a drop is not a jump - its landing never arms the rebound gate
	# Fix Pass 9: the released car flies and lands under the
	# heading it HUNG with (see _orient_car_hang - Fix Pass 10:
	# that heading is the spring-settled orient_yaw, which at a
	# settled dangle equals the drop section's direction).
	# The horizontal air velocity becomes the velocity vector.
	car_heading = orient_yaw
	# Fix Pass 20 (Item 3): SURFACE THE RULING - every release
	# records its heading against the drop section's travel
	# direction and logs it (the grab log file, the event ring,
	# and the DIAG GRAB line all carry it; last_release_* holds
	# it for the stages). The run-18 backwards drop left no
	# trace anywhere; from this pass on, a wrong-way release
	# states its own error in the driver's log.
	# Fix Pass 22: releases fire from any phase now; an
	# off-station release is measured against the section
	# UNDER THE CAR at release (sec_fr), not the station it
	# never reached.
	last_release_s = rel_s
	last_release_hdg_deg = rad_to_deg(car_heading)
	last_release_sec_deg = rad_to_deg(_frame_yaw(sec_fr["tan"]))
	last_release_err_deg = rad_to_deg(wrapf(car_heading - _frame_yaw(sec_fr["tan"]), -PI, PI))
	_grab_event("RELEASE s%.0f HDG %+.1f SEC %+.1f ERR %+.1f" % [
		last_release_s, last_release_hdg_deg, last_release_sec_deg, last_release_err_deg])
	yaw_rate = 0.0
	vel2 = Vector2(air_vel.x, air_vel.z)
	mode = MODE_AIR
	contact_label.text = ""
	contact_readout_t = 0.0


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
	# Fix Pass 13 (Item 1): the touchdown readout's clock.
	if contact_readout_t > 0.0:
		contact_readout_t -= delta
		if contact_readout_t <= 0.0 and contact_label != null:
			contact_label.text = ""
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
		tire_ratio = 0.0 # Fix Pass 15 (Item 1): and no telegraph either
		tire_band = 0.0
	_update_turbo_meter(delta) # Fix Pass 24 (Item 2): the meter's fill + flash state
	_update_ctl_articulation(delta) # Fix Pass 13 (Item 5): seat levers + button dips
	_update_lean_reading()
	_update_suspension(delta)
	_update_body_spring(delta)
	_refresh_car_visuals()
	_update_audio(delta)
	_update_telegraph(delta) # Fix Pass 15 (Item 1): dust + controller rumble off the same signal
	_update_crane_visual()
	if step_log_on:
		_step_log_row()


func _process(_delta: float) -> void:
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
			song_player.volume_db = -60.0 # Fix Pass 15 (Item 1): the watchdog covers every voice
			rumble_player.volume_db = -60.0
			scrape_player.volume_db = -60.0


## Fix Pass 11 (Item 5): the steering lock scale. At
## |v| <= 24 m/s this
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


## Fix Pass 25 (Items 2+3): the front tires' DISPLAYED yaw,
## in the model's sign convention (positive = toward +X, a
## right lock). The drive model computes its own front_angle
## from wheel_angle and never reads this. The display is:
## the model's angle with its steer fraction run through the
## visual gain curve (STEER_VIS_GAIN0 at centre, honest from
## STEER_VIS_FULL up), plus - in DRIVE only - the slip angle
## atan2(lat_vel, |speed|) capped at SLIP_VIS_CAP_RAD, so the
## tires yaw toward the slide the car is actually in. The
## dangle display runs through the same gain (speed 0 -> full
## lock scale): the promise the release keeps is the one the
## driver saw dialled in.
func _steer_display_angle() -> float:
	var steer: float = clampf(wheel_angle / PI, -1.0, 1.0)
	var gain: float = 1.0 + (STEER_VIS_GAIN0 - 1.0) * (1.0 - smoothstep(0.0, STEER_VIS_FULL, absf(steer)))
	var fa: float = steer * gain * MAX_LOCK_RAD * _lock_scale(speed)
	if mode == MODE_DRIVE:
		fa += clampf(atan2(lat_vel, maxf(absf(speed), SLIP_VIS_MIN_SPEED)),
			-SLIP_VIS_CAP_RAD, SLIP_VIS_CAP_RAD)
	return fa


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
	# Fix Pass 14 (Item 1): the chain re-arm clock (see the
	# rebound route in _update_suspension).
	grounded_t += delta
	# Fix Pass 13 (Item 1): the contact transient's clock runs
	# on drive frames (a bounce back into the air pauses it;
	# the next landing re-arms it from its own contact).
	if contact_transient_t > 0.0:
		contact_transient_t -= delta
		contact_load_age += delta
	# Suspension air entry (Fix Pass 5/8, unchanged rule): the
	# load decision was made in _update_suspension last frame.
	if bounce_pending:
		bounce_pending = false
		_sync_vel2_from_speed_lat()
		_enter_air(false, bounce_vy)
		# Fix Pass 14 (Item 1): remember HOW this flight began -
		# a rebound's own landing must not arm a second energy
		# return (the film settles after one bounce).
		air_from_rebound = pending_rebound
		pending_rebound = false
		rebound_gate_vy = 0.0
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
	var tire_long: float = in_throttle * 10.0
	if in_boost and boost_meter > 0.0 and in_throttle > 0.05:
		tire_long += 9.0
		boost_meter = maxf(boost_meter - BOOST_DRAIN_PER_S * delta, 0.0)
	# Fix Pass 13 (Item 1): COMBINED SLIP at a governed contact.
	# One tire has one friction budget: while the contact
	# transient runs (see _land) the lateral bleed is spending
	# it, and the engine gets only what the friction ellipse
	# leaves - sqrt(budget^2 - a_lat^2) - further scaled by the
	# load ramp while the springs take the car's weight. The
	# cruise model is untouched: with no transient running this
	# cap does not exist, and at a clean contact (no lateral
	# velocity) the ellipse leaves the full budget anyway.
	var cap13: float = _contact_long_cap(vl)
	if cap13 >= 0.0:
		tire_long = minf(tire_long, cap13)
	var accel: float = tire_long
	accel -= in_brake * 14.0
	accel -= vf * 0.10
	accel += -GRAV * tanv.y * 0.85 # slope gravity: climbs bite, descents push
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
	# Fix Pass 14 (Item 5): the bleed scales by the load the
	# corners carry (load_grip, from _update_suspension). A
	# slide across an unloading crest keeps most of its
	# lateral velocity until the car is weighted again -
	# the fight the film shows. During the FP13 contact
	# transient the factor is NOT applied: the transient's
	# own ramp already owns the load story there, and the
	# corners read deep at a touchdown (factor > 1), which
	# would double-count.
	var lg5: float = load_grip if contact_transient_t <= 0.0 else 1.0
	var bleed: float = clampf(-GRIP_BITE_RATE * vl * grip_mult * lg5,
		-GRIP_LAT_ACCEL * grip_mult * lg5, GRIP_LAT_ACCEL * grip_mult * lg5)
	# Fix Pass 13 (Item 1): during the contact transient the
	# bleed itself is load-limited - a tire still taking the
	# car's weight cannot bite at full rate yet (the same ramp
	# that caps the engine in _contact_long_cap).
	if contact_transient_t > 0.0:
		bleed *= _contact_load_factor()
	vl += bleed * delta
	# Fix Pass 15 (Item 1): THE TELEGRAPH SIGNAL. The bleed
	# above is the tire's capacity being spent; this ratio
	# measures the DEMAND against that capacity before any of
	# it is spent: the lateral acceleration the current yaw
	# asks the velocity to curve through (|vf * omega_target|)
	# over the cap the bleed enforces at each axle - the same
	# GRIP_LAT_ACCEL x grip_mult, with each axle's own FP14
	# load factor (during the contact transient the bleed's cap
	# drops the load factor, so the ratio does too - one rule).
	# Per-AXLE, deliberately: FP14 tried per-corner carriers
	# for the bleed itself and corner compression "sags under
	# slide geometry while the true load factor stays 1.00" -
	# the axle load is the honest grain here, and the max over
	# the axles names the end that lets go first. The signal
	# only speaks while the road holds the car (both axles
	# meaningfully loaded, real speed): an unloading crest is
	# the drumbeat's territory, not the tire song's.
	var lgf15: float = 1.0
	var lgr15: float = 1.0
	if contact_transient_t <= 0.0:
		lgf15 = clampf(pow(maxf(load_f, 0.0), GRIP_LOAD_EXP), GRIP_LOAD_MIN, GRIP_LOAD_MAX)
		lgr15 = clampf(pow(maxf(load_r, 0.0), GRIP_LOAD_EXP), GRIP_LOAD_MIN, GRIP_LOAD_MAX)
	if load_f > 0.05 and load_r > 0.05 and absf(vf) > 2.0:
		var dem15: float = absf(vf * omega_target)
		var rf15: float = dem15 / maxf(GRIP_LAT_ACCEL * grip_mult * lgf15, 0.01)
		var rr15: float = dem15 / maxf(GRIP_LAT_ACCEL * grip_mult * lgr15, 0.01)
		tire_ratio = maxf(rf15, rr15)
		tire_ratio_axle = 0 if rf15 >= rr15 else 1
	else:
		tire_ratio = 0.0
	tire_band = clampf((tire_ratio - TIRE_BAND_LO) / (TIRE_BAND_HI - TIRE_BAND_LO), 0.0, 1.0)
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
	# Fix Pass 14 (Item 7): the flight attitude - nose-down
	# builds quadratically through the flight from the
	# takeoff basis (film study section 3: slope-matched,
	# nose-first arrivals). Absolute from air_basis0 each
	# frame, never integrated, so there is no drift to
	# unwind at the landing; _land reads this basis for its
	# tilt ruling, so a slope-matched arrival grades like
	# one. Drone drops are EXCLUDED (air_from_release):
	# FP13's touchdown behaviour is the drop's whole
	# contract, and a 0.44 s fall would only pick up ~2 deg
	# of build against the pendulum's own tilt story.
	if not air_from_release:
		var off7: float = clampf(-0.5 * AIR_NOSE_DOWN_ACCEL * air_time * air_time, -AIR_NOSE_DOWN_MAX, 0.0)
		if off7 != 0.0:
			car.global_transform = Transform3D(air_basis0.rotated(air_basis0.x.normalized(), off7), pos)
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
	# Fix Pass 14 (Item 2): the vertical-velocity bound drops
	# from 2.5 to 0.5. The FP5/8 spring throw left the ground
	# from full droop (car placed ~0.46 m up, above the window),
	# so the old bound never met a rising car; the Item 2
	# mid-stroke throw leaves from c ~0.155 (car at ~0.31 m,
	# INSIDE the window) and the old test re-landed it on the
	# first airborne tick - the hop existed in the state
	# (bounce_pending fired, bounce_vy 1.53) but never in the
	# air. A car rising faster than 0.5 m/s is leaving, not
	# landing; falls and arcs come back through the bound on
	# their way down, and the below-window case (h far under
	# the ribbon) is unaffected in practice - it lands when it
	# falls back through, a few frames later.
	if not bool(fr["gap"]) and h <= CLEARANCE + 0.05 and h > -2.2 and absf(lat) <= HALF_WIDTH + EDGE_FALL_OVERSHOOT and air_vel.y < 0.5:
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
	# Fix Pass 14 (Item 1): arm the energy return for THIS
	# landing (consumed by the spring-throw route in
	# _update_suspension). A landing that itself began as a
	# rebound never re-arms - one bounce, then settle. And a
	# DRONE DROP never arms at any sway: stage 26 caught a
	# sway-carrying release landing hard enough to arm, and
	# its oversized hop sagged the engine-rev staging - but
	# the real point is FP13's: drops are the drone's
	# behaviour, with ONE soft stock bounce (film section 4),
	# however the swing was moving at release.
	rebound_gate_vy = vy if (vy >= REBOUND_GATE_VY and not air_from_rebound and not air_from_release) else 0.0
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
		dent_level += 1 # Fix Pass 24 (Item 4): the dent stays; the smoke puff it used to light is deleted
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
	# Fix Pass 14 (Item 3): the impact sets the corners grouped
	# by axle (a landing arrives as an axle event; the corners
	# diverge from the next sampled frame onward).
	susp_c[0] = c_f
	susp_c[1] = c_f
	susp_c[2] = c_r
	susp_c[3] = c_r
	susp_cv[0] = cv_f
	susp_cv[1] = cv_f
	susp_cv[2] = cv_r
	susp_cv[3] = cv_r
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
	# Fix Pass 13 (Item 1): the minimum-forward guarantee tops
	# up only a FORWARD contact. The old code floored every
	# landing to the same 4 m/s, which erased the fore-aft half
	# of the swing: a release at backward sway-peak landed with
	# the pendulum's backward tip velocity and was handed the
	# same 4 m/s as a settled drop. A backward contact now
	# keeps its velocity - the car touches down rolling
	# backward and the driver recovers it, which is the cost
	# of the mistimed release, honestly come by.
	if vf_land >= 0.0 and vf_land < 4.0:
		vel2 += Vector2(f2.x, f2.z) * (4.0 - vf_land)
		vf_land = 4.0
	elif vf_land > TOP_SPEED:
		vel2 -= Vector2(f2.x, f2.z) * (vf_land - TOP_SPEED)
		vf_land = TOP_SPEED
	speed = vf_land
	lat_vel = vel2.dot(Vector2(r2.x, r2.z))
	yaw_rate = 0.0
	# Fix Pass 13 (Item 1): SURFACE THE RULING - the touchdown
	# connection, measured from the contact state itself: how
	# much lateral velocity the tires met, and how far the car's
	# heading sat from the road's tangent. These two numbers
	# ARE the getaway: the drive model's grip bleed has to kill
	# the lateral part before the car is truly going anywhere,
	# and the heading error is the angle it must be killed
	# across. Graded against thresholds taken from the staged
	# sway-zero / sway-peak distribution (smoke stage 30).
	contact_lat_speed = absf(lat_vel)
	contact_head_err = rad_to_deg(wrapf(car_heading - _frame_yaw(fr["tan"]), -PI, PI))
	if contact_lat_speed <= CONTACT_CLEAN_LAT and absf(contact_head_err) <= CONTACT_CLEAN_HDG:
		contact_grade = "CLEAN"
	elif contact_lat_speed <= CONTACT_SCRUB_LAT and absf(contact_head_err) <= CONTACT_SCRUB_HDG:
		contact_grade = "SCRUBBED"
	else:
		contact_grade = "CROSSED-UP"
	contact_readout_t = CONTACT_READOUT_S
	if contact_label != null:
		contact_label.text = "TOUCHDOWN %s - LAT %.1f M/S, HDG %+.1f DEG" % [
			contact_grade, contact_lat_speed, contact_head_err]
	_pay_for_landing() # Fix Pass 24 (Item 1): the air exchange (crane drops refused inside)
	# The contact TRANSIENT: for as long as this touchdown's
	# own slide takes to bleed (the model's bleed law integrated
	# against the contact's lateral speed), the tires are
	# governed by the contact, not the cruise model: combined
	# slip caps the engine force at what the friction ellipse
	# leaves after the lateral bleed, and the load ramp scales
	# both while the springs take the car's weight. Set here,
	# consumed in _update_drive, expired by the bleed itself.
	contact_transient_t = _bleed_time(contact_lat_speed)
	contact_load_age = 0.0
	var pr: Array = _project_to_spine(car.global_position, air_s_est, true)
	car_s = float(pr[0])
	car_lat = float(pr[1])
	mode = MODE_DRIVE
	was_airborne = false
	_place_car_on_track(_frame_at(car_s))


func _pay_for_landing() -> void:
	# Fix Pass 24 (Item 1): the air exchange, read off the
	# landing _land just graded. What pays: a RACING
	# separation - a flight that began off the road under
	# power (road lip, gap, suspension rebound) and ends in
	# this graded on-road landing. What never pays:
	#   - a crane drop (air_from_release): the chains are
	#     transport, not flight - FP13's "no boost payout at
	#     the drop" ruling, kept;
	#   - a flight under BOOST_PAY_MIN_AIR_S: texture hops
	#     are the road's grain, not income.
	# Off-road flights never reach _land at all (they go to
	# recovery), so they cannot pay by construction. A
	# rebound's second flight is a racing separation with
	# its own landing: it pays as its own landing, at its
	# own shorter time. The payout clamps at the tank.
	last_pay_units = 0.0
	last_pay_air_s = air_time
	last_pay_grade = contact_grade
	if air_from_release or air_time < BOOST_PAY_MIN_AIR_S:
		return
	var mult: float = float(BOOST_GRADE_MULT.get(contact_grade, 0.0))
	if audit_on:
		# Fix Pass 24 (Item 3): the audit books the track's
		# GROSS offer - the full grade-weighted payout before
		# the tank clamp (the clamp is the car's state, not
		# the track's geography) - and files the flight's air
		# under the sector it separated in.
		audit_air_s += air_time
		audit_income += air_time * mult * BOOST_AIR_RATE
		if audit_flight_open:
			var ai: int = clampi(int(audit_flight_s / AUDIT_SECTOR_M), 0, audit_sectors.size() - 1)
			audit_sectors[ai] += air_time
			audit_flight_open = false
			# Fix Pass 28: the same booking at flight
			# resolution, for the lab's per-piece report.
			audit_flights.append([audit_flight_s, air_time, air_time * mult * BOOST_AIR_RATE])
	var pay: float = minf(air_time * mult * BOOST_AIR_RATE, BOOST_CAPACITY - boost_meter)
	if pay <= 0.0:
		return
	boost_meter += pay
	last_pay_units = pay
	pay_flash_t = PAY_FLASH_S
	_grab_event("PAY %.1f AIR %.2f %s" % [pay, air_time, contact_grade])


func _bleed_time(v0: float) -> float:
	# Fix Pass 13 (Item 1): how long the drive model's own
	# lateral bleed law (proportional at GRIP_BITE_RATE, capped
	# at GRIP_LAT_ACCEL) takes to bring a lateral velocity of
	# v0 under 0.3 m/s - integrated at the physics step so the
	# contact transient lasts exactly as long as the slide it
	# governs, no longer. Zero for a clean contact. The
	# integration applies the SAME load factor the bleed will
	# live under (the tires are not fully weighted yet - see
	# _contact_load_factor), so the estimate is the slide's
	# real duration, not the fully-weighted fiction: with the
	# shipped ramp (floor 0.10 over 0.65 s) a sway-peak slide
	# governs for ~1 s, not the ~0.57 s the bare law gives.
	# The constants were tuned on the staged getaways (stage
	# 30): clean 1.82 s to 20 m/s (no transient - untouched),
	# Drop-Start seed swing 2.61 s, sway-peak 3.42 s - a
	# 1.60 s spread against the brief's 1.5 s floor.
	var v: float = v0
	var t: float = 0.0
	var dt: float = 1.0 / 90.0
	while v > 0.3 and t < 3.0:
		var lf: float = clampf(CONTACT_LOAD_FLOOR + (1.0 - CONTACT_LOAD_FLOOR) \
			* (t / CONTACT_LOAD_RAMP_S), CONTACT_LOAD_FLOOR, 1.0)
		v -= minf(GRIP_BITE_RATE * v, GRIP_LAT_ACCEL) * lf * dt
		t += dt
	return t


func _contact_long_cap(vl_now: float) -> float:
	# Fix Pass 13 (Item 1): the longitudinal tire force the
	# friction ellipse leaves during the contact transient, or
	# -1 when no contact governs the tires. budget is the
	# frame's lateral limit (the lean multiplier scales both
	# sides of the ellipse, as it scales the bleed); a_lat is
	# what the bleed is about to spend of it.
	if contact_transient_t <= 0.0:
		return -1.0
	var budget: float = GRIP_LAT_ACCEL * grip_mult
	var a_lat: float = minf(GRIP_BITE_RATE * absf(vl_now) * grip_mult, budget)
	return sqrt(maxf(budget * budget - a_lat * a_lat, 0.0)) * _contact_load_factor()


func _contact_load_factor() -> float:
	# Tire capacity while the springs take the car's weight
	# after a touchdown: ramps from CONTACT_LOAD_FLOOR to full
	# over CONTACT_LOAD_RAMP_S (the suspension's compression
	# timescale - SUSP_K's quarter period is ~0.12 s; the tires
	# are fully weighted about twice that after first contact).
	if contact_transient_t <= 0.0:
		return 1.0
	return clampf(CONTACT_LOAD_FLOOR + (1.0 - CONTACT_LOAD_FLOOR) \
		* (contact_load_age / CONTACT_LOAD_RAMP_S), CONTACT_LOAD_FLOOR, 1.0)


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


func _step_crane(delta: float) -> void:
	# Fix Pass 15 (Item 2): the crane's pivot integrator - what
	# _step_carrier was to the drone. There is no flight: the
	# pivot is the trolley's position on the jib, and it has
	# exactly three jobs. In ATTACH it holds over the pickup
	# while the chains settle. In CARRY it SLEWS - sideways, at
	# crane speed, under a braking-curve cap - from above the
	# pad to the drop station, turning the load to the drop
	# heading as it goes (the FP11 approach lesson, kept: the
	# turn is travelled, not dangled). In DANGLE it holds the
	# station against the winch dips and the gust/flex nudge.
	# Through all of it carrier_accel is MEASURED from the
	# velocity change the limits allowed - the pendulum (and
	# the slack trigger) read that, never a schedule.
	var target: Vector3 = anchor_target
	var target_vel: Vector3 = Vector3.ZERO
	if hang_phase == "attach":
		target = anchor_pos # hold over the pickup while the chains settle
	elif hang_phase == "carry":
		target = anchor_target
	elif hang_phase == "dangle":
		# Winch dips on the old hash cadence (deterministic -
		# the smoke depends on reproducible behaviour): the
		# station target descends on the dip profile and the
		# winch follows it down and back. (FP10-FP14 flew this
		# very profile with the drone; depths and cadence are
		# unchanged - only the reader of the motion changed.)
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
		# Fix Pass 15 (Item 2): the fixed pivot's honest
		# irregularity. FP14 kept the flying station from
		# settling to a clean Lissajous with a hash WANDER of
		# the station target (+-0.28 m per axis, re-picked
		# every 1.2-2.2 s); the crane's equivalents are
		# weather and structure. Desert GUSTS step the target
		# on the same house hash and cadence (+-GUST_AMP per
		# axis), and the JIB FLEXES: the pivot leans after
		# the swinging load through a first-order lag on the
		# load's direction - a lag couples the two swing
		# axes into each other and can never resonate or
		# pump (a spring near the pendulum's own frequency
		# could). Gust + flex together are clamped to the
		# PIVOT_OFF_MAX_M budget, so the pivot's total
		# excursion from the station is a NUMBER the drop
		# staging can assert, not a hope.
		gust_t -= delta
		if gust_t <= 0.0:
			gust_seed += 1
			var hg1: float = sin(float(gust_seed) * 12.9898) * 43758.5453
			var hg2: float = sin(float(gust_seed) * 78.233) * 12543.21
			var hg3: float = sin(float(gust_seed) * 37.719) * 28001.83
			gust_off = Vector2((hg1 - floor(hg1)) * 2.0 - 1.0, (hg2 - floor(hg2)) * 2.0 - 1.0) * GUST_AMP
			gust_t = 1.2 + 1.0 * (hg3 - floor(hg3))
		var flex_want := Vector2(sin(pend_th_f), sin(pend_th_l)) * JIB_FLEX_M
		flex_off += (flex_want - flex_off) * (1.0 - exp(-delta / JIB_FLEX_TAU))
		var fr_n: Dictionary = _frame_at(drop_target_s)
		var off_h: Vector2 = gust_off + flex_off
		if off_h.length() > PIVOT_OFF_MAX_M:
			off_h = off_h.normalized() * PIVOT_OFF_MAX_M
		target = anchor_target + fr_n["tan"] * off_h.x + fr_n["side"] * off_h.y \
			+ Vector3(0.0, doff.x, 0.0)
		target_vel = Vector3(0.0, doff.y, 0.0)
	# velocity command
	var desired: Vector3
	if test_pivot_accel_on:
		desired = carrier_vel # acceleration is injected below
	elif hang_phase == "carry":
		# The slew: a P-law closing on the station under a
		# braking-curve cap (the FP12 flare's shape, at crane
		# numbers): |v| <= sqrt(2 * 1.2 * d) and never above
		# CRANE_SLEW_SPEED, so the trolley is already slow
		# when it arrives and the pendulum is never dragged
		# at flight accelerations.
		desired = (target - anchor_pos) * 1.4
		var d_rem: float = anchor_pos.distance_to(target)
		var cap: float = minf(CRANE_SLEW_SPEED, sqrt(2.0 * 1.2 * maxf(d_rem - 0.05, 0.0)))
		if desired.length() > cap:
			desired = desired.normalized() * cap
	elif hang_phase == "dangle":
		# Split authority at the station: the WINCH (vertical)
		# keeps the flown-dip authority (gain 2.2, cap 2.0) -
		# the deep dips need it to slack the chains. The
		# HORIZONTAL nudge (gusts + flex) is crept after at a
		# gentler gain and cap: a crane trolley easing against
		# the weather, and the pendulum is nudged, never
		# kicked - the settle checks stage this.
		var dv_v: float = clampf(target_vel.y + (target.y - anchor_pos.y) * 2.2, -2.0, 2.0)
		var dh: Vector2 = Vector2(target.x - anchor_pos.x, target.z - anchor_pos.z) * 1.1
		if dh.length() > 0.6:
			dh = dh.normalized() * 0.6
		desired = Vector3(dh.x, dv_v, dh.y)
	else:
		desired = target_vel + (target - anchor_pos) * 2.2
		if desired.length() > 2.0:
			desired = desired.normalized() * 2.0
	# integrate under the accel limit; station-keeping gets a
	# higher limit (the winch works hard over the drop point -
	# that authority is what lets it fly the deep dips).
	var prev_vel: Vector3 = carrier_vel
	if test_pivot_accel_on:
		carrier_vel += test_pivot_accel * delta
	else:
		var accel_lim: float = 11.0 if hang_phase == "dangle" else CRANE_SLEW_ACCEL
		var dv: Vector3 = desired - carrier_vel
		var max_dv: float = accel_lim * delta
		if dv.length() > max_dv:
			dv = dv.normalized() * max_dv
		carrier_vel += dv
	var inst_accel: Vector3 = (carrier_vel - prev_vel) / maxf(delta, 0.0001)
	carrier_accel = carrier_accel.lerp(inst_accel, 0.5)
	anchor_pos += carrier_vel * delta
	pivot_pos = anchor_pos
	# Jib yaw: the load's facing turns toward the drop heading
	# through the slew and holds it at the station (rate-limited,
	# so the car is twisted gently, never snapped).
	var yaw_goal: float = _frame_yaw(_frame_at(drop_target_s)["tan"])
	var max_turn: float = CARRIER_YAW_RATE * delta
	carrier_yaw += clampf(wrapf(yaw_goal - carrier_yaw, -PI, PI), -max_turn, max_turn)
	# Slack: a hard winch descent drops the pivot out from
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
	# Arrival at the station ends the slew.
	# Fix Pass 11 (Item 3): a yaw gate joins the position and
	# velocity conditions - the slew does not end until the jib
	# has turned its alignment in (within 0.08 rad of the drop
	# heading), so the car is releasable on arrival instead of
	# dangling through a station spin. The gate is BOUNDED
	# (3 s of station wait): a pathologically short slew
	# degrades to the old behaviour, never to a stuck recovery.
	if hang_phase == "carry":
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
	_step_crane(delta)
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
			pass # the trolley slews the pivot (see _step_crane)
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
		lean_needle.position.x = -0.18 + lean_value * 0.16 # FP13: centred on its shifted mount


func _lean_effective() -> float:
	# The lean the game acts on: test override wins (same pattern as
	# _grip_for), else the live head/body reading.
	if test_lean > -50.0:
		return test_lean
	return lean_value


func _susp_integrate(target_f: float, target_r: float, delta: float) -> void:
	# Fix Pass 14 (Item 1): the gated return stroke. While an
	# energy return is armed (a landing at/above
	# REBOUND_GATE_VY that has not thrown yet) and the car is
	# on the main track, a spring compressed past
	# REBOUND_RETURN_DEPTH works at the multiplied rate, and
	# its EXTENSION damping is cut - the asymmetric shove
	# (Crammond's force clamp is asymmetric the same way).
	# Ungated driving never sees either change.
	var gated: bool = rebound_gate_vy > 0.0 and mode == MODE_DRIVE
	var kf: float = SUSP_K * REBOUND_RETURN_K_MULT if (gated and c_f > REBOUND_RETURN_DEPTH) else SUSP_K
	var kr: float = SUSP_K * REBOUND_RETURN_K_MULT if (gated and c_r > REBOUND_RETURN_DEPTH) else SUSP_K
	# While the gate is live the whole landing cycle is the
	# return event, so its damping is cut on BOTH strokes (the
	# compression loss is what capped the throw at ~2.73 m/s
	# against a 3.7 cap in staging); the settle discipline of
	# Item 2 applies to the UNGATED landings - drops, soft
	# landings, and this landing's own rebound coming back
	# down - which all keep the full rate.
	var df: float = SUSP_DAMP * REBOUND_RETURN_DAMP_MULT if gated else SUSP_DAMP
	var dr: float = SUSP_DAMP * REBOUND_RETURN_DAMP_MULT if gated else SUSP_DAMP
	cv_f += ((target_f - c_f) * kf - df * cv_f) * delta
	cv_r += ((target_r - c_r) * kr - dr * cv_r) * delta
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
	# Fix Pass 14 (Item 3): the axle path (air, hang,
	# done) mirrors its state into the corners, grouped by
	# axle, so the corner state never desyncs from the means.
	susp_c[0] = c_f
	susp_c[1] = c_f
	susp_c[2] = c_r
	susp_c[3] = c_r
	susp_cv[0] = cv_f
	susp_cv[1] = cv_f
	susp_cv[2] = cv_r
	susp_cv[3] = cv_r


func _susp_integrate_corners(tw: Array, delta: float) -> void:
	# Fix Pass 14 (Item 3): FOUR springs, one per wheel. The
	# sampling has been per-wheel since Fix Pass 9 - support,
	# rise and target are already computed per wheel in
	# _update_suspension - but the INTEGRATION averaged the
	# targets to two axle springs, so a diagonal crest-edge
	# crossing compressed both front springs together though
	# the wheels meet the edge a beat apart (the film's
	# per-wheel independence, notes section 2, is a phase
	# behaviour before it is anything else). Same rate and
	# damping semantics as the axle integrator, including
	# Item 1's gated return (per corner now: a corner deeper
	# than REBOUND_RETURN_DEPTH works at the multiplied
	# rate while the gate is live; the damping cut stays
	# global to the gated landing, as staged).
	# Body attitude derives from the four corner ATTACH
	# heights (road rise - compression + tyre-radius term):
	# pitch is the FP5 formula on the front/rear means,
	# heave the four-mean, and ROLL is new as a derived
	# quantity - atan2 of the right-mean minus left-mean
	# attach over the wheel track - REPLACING the lagged
	# rise-difference edge_roll the straddle used before:
	# the springs' own dynamics are the lag now, and the
	# roll answers compression, not just road shape (a
	# corner that compresses rolls the body even on flat
	# road - weight transfer made visible).
	var gated: bool = rebound_gate_vy > 0.0 and mode == MODE_DRIVE
	var damp: float = SUSP_DAMP * REBOUND_RETURN_DAMP_MULT if gated else SUSP_DAMP
	for wi: int in 4:
		var k: float = SUSP_K * REBOUND_RETURN_K_MULT if (gated and susp_c[wi] > REBOUND_RETURN_DEPTH) else SUSP_K
		susp_cv[wi] += ((float(tw[wi]) - susp_c[wi]) * k - damp * susp_cv[wi]) * delta
		susp_c[wi] = clampf(susp_c[wi] + susp_cv[wi] * delta, 0.0, SUSP_TRAVEL)
	c_f = (susp_c[0] + susp_c[1]) * 0.5
	c_r = (susp_c[2] + susp_c[3]) * 0.5
	cv_f = (susp_cv[0] + susp_cv[1]) * 0.5
	cv_r = (susp_cv[2] + susp_cv[3]) * 0.5
	var at_fl: float = susp_geom[0] - susp_c[0] + (WHEEL_RAD_F - WHEEL_RAD_REF)
	var at_fr: float = susp_geom[1] - susp_c[1] + (WHEEL_RAD_F - WHEEL_RAD_REF)
	var at_rl: float = susp_geom[2] - susp_c[2] + (WHEEL_RAD_R - WHEEL_RAD_REF)
	var at_rr: float = susp_geom[3] - susp_c[3] + (WHEEL_RAD_R - WHEEL_RAD_REF)
	var at_f: float = (at_fl + at_fr) * 0.5
	var at_r: float = (at_rl + at_rr) * 0.5
	var at_l: float = (at_fl + at_rl) * 0.5
	var at_ri: float = (at_fr + at_rr) * 0.5
	pitch_extra = atan2(at_f - at_r, WHEELBASE)
	heave_off = (at_f + at_r) * 0.5 + SUSP_REST
	edge_roll = atan2(at_ri - at_l, WHEEL_TRACK_M)


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
			sup_over[wi] = over # Fix Pass 15 (Item 1): the edge family's raw fact
			if over > EDGE_CUTOFF:
				sup_ok[wi] = false
				sup_rise[wi] = rise - EDGE_CUTOFF * EDGE_SLOPE - 0.30
			else:
				sup_ok[wi] = true
				sup_rise[wi] = rise - maxf(over, 0.0) * EDGE_SLOPE
			# Fix Pass 21 (Item 1): the corner's OWN load. The
			# patch curvature at (sup_s, wlat) - not the
			# centreline kv at an axle mean s - decides how
			# hard the road can hold this corner: following
			# the surface over a crest needs downward
			# acceleration v^2 * kv_patch, and what gravity
			# cannot supply unloads the corner. An
			# unsupported (past-cutoff) corner carries
			# nothing by definition.
			sup_lat[wi] = wlat
			wheel_kv[wi] = _patch_kv(sup_s[wi], wlat)
			var tan_wy: float = Vector3(wfr["tan"]).y
			var cos_w: float = maxf(sqrt(maxf(1.0 - tan_wy * tan_wy, 0.0)), 0.5)
			wheel_load[wi] = clampf(1.0 - speed * speed * wheel_kv[wi] / (GRAV * cos_w), 0.0, 1.25) if sup_ok[wi] else 0.0
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
		# Crest load: Fix Pass 21 (Item 1) - the load is
		# computed PER CORNER in the sampling loop above
		# (patch curvature at the wheel's own contact patch);
		# the axle factors survive as the corner means, so
		# every reader built on them (the FP15 telegraph, the
		# rebound route's load floor, the stages) keeps its
		# meaning. (Pre-FP21 this block computed the factors
		# from the centreline kv at each axle's mean wheel s -
		# the scalar that could not see a one-side unload.)
		load_f = (wheel_load[0] + wheel_load[1]) * 0.5
		load_r = (wheel_load[2] + wheel_load[3]) * 0.5
		# Fix Pass 21 (Item 2): SEPARATION, per corner. A
		# corner is airborne when its patch load sits at
		# ~zero - the road there falls away faster than the
		# corner's ballistic arc (v^2 * kv_patch >= g) - and
		# it re-contacts the moment the load returns. No
		# sustain counter, no history: the comparison IS
		# the physics, sampled at the corner. Entry asks
		# real speed (below it the load factor itself
		# returns to ~1 as v^2 falls, so a slowing car
		# re-contacts on its own); a corner past the edge
		# cutoff belongs to the straddle, not to this.
		for wi5: int in 4:
			if sup_ok[wi5] and speed > 8.0 and wheel_load[wi5] <= AIR_LOAD_EPS:
				wheel_air[wi5] = true
			elif not sup_ok[wi5] or wheel_load[wi5] > AIR_LOAD_EPS:
				wheel_air[wi5] = false
			if wheel_air[wi5]:
				wheel_air_frames[wi5] += 1
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
		# an unsupported wheel asks for full droop. (FP14 Item 3:
		# the corners now integrate these targets individually -
		# before, the axle spring integrated their mean.) The FP7 jitter
		# swap lives in geom_f/geom_r (the axle means), so each
		# wheel's target also carries its axle's jitter delta -
		# the difference between the swapped geom and the smooth
		# mean (identically zero with jitter OFF).
		var jit_f: float = geom_f - (sup_rise[0] + sup_rise[1]) * 0.5
		var jit_r: float = geom_r - (sup_rise[2] + sup_rise[3]) * 0.5
		var tw: Array[float] = [0.0, 0.0, 0.0, 0.0]
		for wi2: int in 4:
			if sup_ok[wi2] and not wheel_air[wi2]:
				# Fix Pass 21 (Item 1): the corner's target
				# scales by its OWN load now, not its axle's -
				# on a centred, aligned car over centreline
				# terrain the two agree; over a one-sided
				# unload only the corner's own value is true.
				var ld: float = wheel_load[wi2]
				var tr: float = -transfer if wi2 < 2 else transfer
				var jd: float = jit_f if wi2 < 2 else jit_r
				tw[wi2] = clampf((SUSP_REST + sup_rise[wi2] + jd) * ld + tr, 0.0, SUSP_TRAVEL)
			else:
				# Unsupported (straddle) or separated (FP21):
				# the corner asks for full droop and dangles.
				tw[wi2] = 0.0
		# Fix Pass 14 (Item 3): the corners integrate their
		# OWN targets (the axle means survive as c_f/c_r -
		# see _susp_integrate_corners). Each corner's road
		# rise for the attach derivation is its own support
		# rise plus its axle's jitter delta.
		for wi3: int in 4:
			susp_geom[wi3] = sup_rise[wi3] + (jit_f if wi3 < 2 else jit_r)
		_susp_integrate_corners(tw, delta)
		# Fix Pass 14 (Item 5): the load the tires actually
		# carry this frame - the mean road load raised to
		# GRIP_LOAD_EXP (a crest at full unload floors it).
		# Feeds the lateral bleed in _update_drive (one
		# frame stale, like bounce_pending). Fix Pass 21:
		# the mean is over the four CORNER loads - a
		# two-wheel unload halves the carried load, which
		# is what the contact patch count says. (The value
		# equals the old axle-mean wherever the corners of
		# an axle agree.)
		load_grip = clampf(pow(maxf((wheel_load[0] + wheel_load[1] + wheel_load[2] + wheel_load[3]) * 0.25, 0.0), GRIP_LOAD_EXP), GRIP_LOAD_MIN, GRIP_LOAD_MAX)
		# Fix Pass 15 (Item 1): THE EDGE FAMILY's strengths, read
		# straight off the support state this loop just computed -
		# the original's contact layer (Crammond had no skid, but
		# his surfaces were audible: an off-road rumble, a scrape
		# on hard contact). A wheel fully past the cutoff is OFF
		# (rumble, strength by how much of the car is off, and
		# only while the car is actually moving); a wheel in the
		# straddle band (on the shoulder, not off) with the car
		# running along the rim GRINDS (scrape, strength by
		# penetration and speed, sharpened by lateral slide).
		# Both are zero by construction the frame the state says
		# otherwise: fully-on wheels are silent, a fully-off
		# wheel rumbles but never scrapes.
		var off_n15: float = 0.0
		var scr15: float = 0.0
		for wi4: int in 4:
			if not sup_ok[wi4]:
				off_n15 += 1.0
			elif sup_over[wi4] > 0.0:
				scr15 = maxf(scr15, clampf(sup_over[wi4] / EDGE_CUTOFF, 0.0, 1.0)
					* clampf(absf(speed) / 14.0, 0.0, 1.0)
					* clampf(0.45 + absf(lat_vel) / 2.0, 0.0, 1.0))
		edge_rumble_now = clampf(off_n15 * 0.5, 0.0, 1.0) * clampf(absf(speed) / 4.0, 0.0, 1.0)
		edge_scrape_now = scr15
		# The straddle wobble is now INSIDE the corner
		# derivation: edge_roll comes from the corner attach
		# heights (an unsupported side's corners droop, its
		# attach line falls, the body rolls toward it - the
		# FP9 mechanism with the springs themselves as the
		# lag, replacing the separate lagged rise-difference
		# channel that used to be computed here).
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
		# Fix Pass 21 (Item 2): route (1) is PER-CORNER now.
		# The both-axle sustain rule is REPLACED on the main
		# track: each corner separates on its own patch
		# comparison (see the separation state above), and
		# the CAR flies when all four corners have separated
		# - the sustain counter's last job (waiting for the
		# rear axle to arrive at the crest the front had
		# already left) is exactly the glue the owner
		# reported.
		# (2) REBOUND: the springs cross near-droop still throwing
		# fast - stored energy leaving (FP14 Item 2: the crossing
		# is the condition, not the droop stop - see
		# REBOUND_FIRE_TRAVEL) - but ONLY while the road
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
		# Fix Pass 21: the FP8 sustain counter stood here;
		# per-corner separation (above) replaced it on the
		# main track (FP23 removed the counter with the spur).
		# Fix Pass 14 (Item 2): stored-energy evidence for the
		# throw route - a deep compression inside the window.
		if (c_f + c_r) * 0.5 >= REBOUND_DEEP_HIT:
			deep_hit_age = 0.0
		else:
			deep_hit_age += delta
		if grounded_t > REBOUND_CHAIN_RESET_S:
			bounce_chain = 0
		# Fix Pass 14 (Item 1): an armed return that has not
		# thrown inside its window lapses - the gate belongs
		# to the landing that armed it, not to whatever deep
		# compression happens along later.
		if rebound_gate_vy > 0.0 and grounded_t > REBOUND_GATE_EXPIRY_S:
			rebound_gate_vy = 0.0
		if wheel_air[0] and wheel_air[1] and wheel_air[2] and wheel_air[3] and speed > 8.0:
			# Fix Pass 21 (Item 2): every corner has
			# separated on its own comparison - nothing
			# holds the car, so the car flies. Same entry
			# terms as the FP8 geometry route (0.35 on top
			# of the slope-following vertical the velocity
			# already carries, see _enter_air).
			bounce_pending = true
			bounce_vy = 0.35
			pending_rebound = false
		elif (c_f + c_r) * 0.5 <= REBOUND_FIRE_TRAVEL and cv_f + cv_r < REBOUND_THROW_VEL \
				and load_f >= REBOUND_LOAD_FLOOR and load_r >= REBOUND_LOAD_FLOOR \
				and bounce_chain == 0 and deep_hit_age <= REBOUND_DEEP_HIT_WINDOW:
			# Fix Pass 14 (Item 1): the throw. Ungated landings
			# (drops, drumbeat hops) keep the FP5/8 cap exactly;
			# an armed energy return raises the cap with the
			# impact that stored the energy. The chain guard
			# (one throw per landing chain) is what makes the
			# sequence flight -> contact -> flight -> SETTLE
			# instead of a pogo: the rebound's own landing
			# finds bounce_chain == 1 and the route stays shut
			# until the car has driven settled for
			# REBOUND_CHAIN_RESET_S.
			bounce_pending = true
			pending_rebound = true
			bounce_chain += 1
			if rebound_gate_vy > 0.0:
				bounce_vy = clampf(-(cv_f + cv_r) * 0.55, 0.5,
					clampf(REBOUND_THROW_FRAC * rebound_gate_vy, 2.6, REBOUND_THROW_CAP))
			else:
				bounce_vy = clampf(-(cv_f + cv_r) * 0.55, 0.5, 2.6)
	elif mode == MODE_DONE:
		geom_f = 0.0
		geom_r = 0.0
		load_f = 1.0
		load_r = 1.0
		wheel_air = [false, false, false, false] # Fix Pass 21
		edge_roll = lerpf(edge_roll, 0.0, clampf(EDGE_ROLL_LAG * delta, 0.0, 1.0))
		edge_rumble_now = 0.0 # Fix Pass 15 (Item 1): no road contact, no edge voice
		edge_scrape_now = 0.0
		_susp_integrate(SUSP_REST, SUSP_REST, delta)
	else:
		# AIR / HANG: no road contact - springs extend to full droop
		# (the dangling car's wheels hang; the flying car's settle).
		geom_f = 0.0
		geom_r = 0.0
		load_f = 1.0
		load_r = 1.0
		wheel_air = [false, false, false, false] # Fix Pass 21: separation is a DRIVE-frame state
		edge_roll = lerpf(edge_roll, 0.0, clampf(EDGE_ROLL_LAG * delta, 0.0, 1.0))
		edge_rumble_now = 0.0 # Fix Pass 15 (Item 1): airborne/hanging - the edge family is silent
		edge_scrape_now = 0.0
		_susp_integrate(0.0, 0.0, delta)


func _update_turbo_meter(delta: float) -> void:
	# Fix Pass 24 (Item 2): the meter's per-frame state - the
	# fill fraction the meter and the stages both read, and
	# the payout flash's decay. Bright at full, dark at
	# empty, so the level reads in peripheral vision; while
	# the flash runs the fill goes boost-bright, so a payout
	# is SEEN in the same moment the landing is graded.
	# Fix Pass 26 (Item 1): what renders that state is the
	# flask's LIQUID. Its level is the fraction (a payout
	# raises it in a chunk at the grading moment; boosting
	# drains it visibly). Its surface SLOSHES: a two-axis
	# damped spring chasing the effective-gravity direction
	# in body space, driven by the car's MEASURED world
	# acceleration (position-derived, so it answers in every
	# mode - the hang's swing included) - underdamped, so it
	# lags the car and settles like liquid, never a mirror.
	turbo_fill_frac = clampf(boost_meter / BOOST_CAPACITY, 0.0, 1.0)
	if pay_flash_t > 0.0:
		pay_flash_t = maxf(pay_flash_t - delta, 0.0)
	if flask_liquid_mi == null:
		return
	flask_level_h = lerpf(FLASK_LIQ_MIN_H, FLASK_LIQ_MAX_H, turbo_fill_frac)
	flask_liquid_pivot.position.y = 0.024 + flask_level_h * 0.5
	flask_liquid_mi.scale = Vector3(1.0, flask_level_h, 1.0)
	if pay_flash_t > 0.0:
		flask_liquid_mat.albedo_color = Color(0.85, 0.97, 1.0)
	else:
		flask_liquid_mat.albedo_color = Color(0.25, 0.55, 0.95).lerp(
			Color(0.03, 0.05, 0.10), 1.0 - turbo_fill_frac)
	# --- the slosh spring ---
	var a_world: Vector3 = Vector3.ZERO
	if test_flask_accel_on:
		a_world = test_flask_accel
		flask_have_prev = false # re-derive the measured state cleanly afterwards
	elif flask_have_prev and delta > 0.0001:
		var vel: Vector3 = (car.global_position - flask_prev_pos) / delta
		a_world = (vel - flask_prev_vel) / delta
		flask_prev_vel = vel
		if a_world.length() > 40.0:
			a_world = a_world.normalized() * 40.0 # warps/fixtures are not weather
	flask_prev_pos = car.global_position
	if not flask_have_prev:
		flask_prev_vel = Vector3.ZERO
		flask_have_prev = true
	var g_eff: Vector3 = Vector3(0.0, -GRAV, 0.0) - a_world
	var gb: Vector3 = car_body.global_transform.basis.transposed() * g_eff
	var target := Vector2(
		clampf(atan2(-gb.z, -gb.y), -FLASK_SLOSH_MAX_RAD, FLASK_SLOSH_MAX_RAD),
		clampf(atan2(gb.x, -gb.y), -FLASK_SLOSH_MAX_RAD, FLASK_SLOSH_MAX_RAD))
	flask_tilt_vel += ((target - flask_tilt) * FLASK_SLOSH_K
		- flask_tilt_vel * FLASK_SLOSH_C) * delta
	flask_tilt += flask_tilt_vel * delta
	flask_liquid_pivot.rotation = Vector3(flask_tilt.x, 0.0, flask_tilt.y)


func _refresh_car_visuals() -> void:
	# wheel visual follows steering angle: the spin node rotates
	# about the wheel's own axis (see the grab-math derivation note
	# at _hand_wheel_angle for the sign pairing)
	if wheel_spin != null:
		wheel_spin.rotation.y = -wheel_angle
	# Fix Pass 16 (Item 3): a rim-attached passenger rep is posed
	# FROM the spin node - its stored grab point rides the rim,
	# so the hand reads as holding the wheel while it turns.
	# A detached rep returns to its build transform (identity
	# under its controller node: the measured hand point).
	for h3: String in ["L", "R"]:
		var rep3: Node3D = ctrl_rep.get(h3)
		if rep3 == null:
			continue
		if bool(rim_attach[h3]) and wheel_spin != null:
			var lp3: Vector3 = rim_local[h3]
			rep3.global_transform = Transform3D(
				wheel_spin.global_transform.basis, wheel_spin.global_transform * lp3)
		elif rep3.transform != Transform3D.IDENTITY:
			rep3.transform = Transform3D.IDENTITY
	# Fix Pass 16 (Item 1): the origin dot is the hand's witness -
	# swollen while the hand has a CANDIDATE in reach, more while
	# it holds a LATCH. If the dot is small, the hand is on
	# nothing: no silent misses, the state is on the hand itself.
	for h1: String in ["L", "R"]:
		var dot1: MeshInstance3D = rep_dot.get(h1)
		if dot1 == null:
			continue
		var latched1: bool = grab_hand == h1 \
			or bool(rim_attach[h1]) \
			or (bool(gripping[h1]) and int(dash_ctl_fired[h1]) >= 0)
		var s1: float = 2.1 if latched1 else (1.5 if String(cand_kind[h1]) != "" else 1.0)
		dot1.scale = Vector3.ONE * s1
	if car_body != null:
		var steer: float = clampf(wheel_angle / PI, -1.0, 1.0)
		car_body.rotation.z = -steer * 0.05 - lat_vel * 0.012
		# Fix Pass 5: body pitch IS the suspension pitch (nose dives
		# on landing, squats under power, works over slope breaks).
		car_body.rotation.x = pitch_extra
	# Fix Pass 5: wheel travel - each wheel rides its spring:
	# compressed = up into the body, drooped = hanging low.
	# Fix Pass 14 (Item 3): per-CORNER travel now (wheel_mis is
	# WHEEL_LOCALS-ordered, so the corner index is the wheel's own).
	# Fix Pass 13 (Item 3): the FRONT wheels also show the steer
	# angle (until now they only travelled). The yaw is the drive
	# model's own expression, so what the driver sees on the road
	# wheels is what the car will do - including a lock dialled
	# in during the dangle (speed 0 -> full lock scale), which is
	# the visible promise the release then keeps. Rear wheels
	# never yaw. Sign: a positive (right) lock turns the wheels
	# toward +X, which is -Y rotation for a wheel modelled
	# rolling toward -Z.
	# Fix Pass 25 (Items 2+3): the yaw now comes from
	# _steer_display_angle() - the model's angle through the
	# visual gain curve (the promise is the same promise, drawn
	# bigger at small lock, identical at full lock), plus the
	# slip-angle offset in DRIVE. The model never reads it back.
	var fa_vis: float = _steer_display_angle()
	for wi: int in wheel_mis.size():
		wheel_mis[wi].position.y = WHEEL_RAD_REF + (susp_c[wi] - SUSP_REST)
		if wheel_axle[wi] == 0:
			# Fix Pass 25 (Item 4): the fronts ride their
			# visual presentation - outboard, centred higher
			# by the visual radius growth (travel delta
			# unchanged: the (susp_c - SUSP_REST) term above
			# is the model's own).
			var wl25: Vector2 = WHEEL_LOCALS[wi]
			wheel_mis[wi].position.x = wl25.x + signf(wl25.x) * WHEEL_OUT_F_VIS
			# The rake term: the visual centre also rises by
			# the rake slope x the forward step, so the visual
			# bottom stays on the world contact plane the
			# raked body pitches it off (capture 20 measures).
			wheel_mis[wi].position.y += (WHEEL_RAD_F_VIS - WHEEL_RAD_F) \
				+ WHEEL_FWD_F_VIS * (WHEEL_RAD_R - WHEEL_RAD_F) / WHEELBASE
			wheel_mis[wi].position.z = wl25.y - WHEEL_FWD_F_VIS
			wheel_mis[wi].rotation_degrees.y = -rad_to_deg(fa_vis)
	_update_view_spring()
	# dent carnage placeholder: nose crumples/tilts with dent level
	if nose_mi != null:
		nose_mi.rotation_degrees.z = float(dent_level) * 4.0
		nose_mi.scale = Vector3(1.0, 1.0 - 0.10 * float(denti_clamp()), 1.0 - 0.08 * float(denti_clamp()))
	# state label text
	if state_label != null:
		if mode == MODE_HANG:
			# Fix Pass 22 (Item 2): ONE line for the whole hang,
			# in the crane's name, saying the one true thing -
			# the button drops you, from any phase. The phase
			# variants it replaces ("DRONE LIFT..." until the
			# dangle, then "PRESS RELEASE") were the dead
			# gate's visible face: they implied a permission
			# window, and named a drone that no longer flies.
			state_label.text = "CRANE LIFT — BUTTON TO DROP"
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
	# - roll carries the suspension roll (FP14 Item 3, below)
	#   plus the lean experiment's amplified tilt (Item 4): view
	#   roll = -lean * step * gain (lean right tips the view right),
	#   present only while the experiment is ON.
	var active: bool = mode == MODE_DRIVE or mode == MODE_AIR
	var v_pitch: float = 0.0
	var v_y: float = 0.0
	var v_roll: float = 0.0
	if active:
		v_pitch = pitch_extra * _view_gain()
		v_y = -((c_f + c_r) * 0.5 - SUSP_REST) * VIEW_HEAVE_GAIN
		# Fix Pass 14 (Item 3): the view also rides the
		# suspension ROLL (edge_roll - corner-derived since
		# this pass) through the same gained path the pitch
		# uses: the placement basis already carries the roll
		# at 1.0x, and the seat adds the A/B gain of it,
		# exactly the pitch treatment. (Item 6's A/B switch
		# scales this gain for pitch and roll together.)
		v_roll = edge_roll * _view_gain()
		if lean_on:
			v_roll += -_lean_effective() * deg_to_rad(LEAN_TILT_STEP_DEG) * LEAN_VIEW_GAIN
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
	# Fix Pass 15 (Item 1): the telegraph's three voices - the
	# tire SONG (pre-limit band), the off-road RUMBLE and the
	# edge SCRAPE. Same discipline as the first two players:
	# synthesized loops, started only in a live race, stopped
	# (not faded) by the teardown latch, gains cut by the
	# stall watchdog.
	song_player = AudioStreamPlayer.new()
	song_player.name = "TireSongAudio"
	song_player.stream = _make_song_stream()
	song_player.volume_db = -60.0
	add_child(song_player)
	rumble_player = AudioStreamPlayer.new()
	rumble_player.name = "OffroadRumbleAudio"
	rumble_player.stream = _make_rumble_stream()
	rumble_player.volume_db = -60.0
	add_child(rumble_player)
	scrape_player = AudioStreamPlayer.new()
	scrape_player.name = "EdgeScrapeAudio"
	scrape_player.stream = _make_scrape_stream()
	scrape_player.volume_db = -60.0
	add_child(scrape_player)


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


func _make_song_stream() -> AudioStreamWAV:
	# Fix Pass 15 (Item 1): the tire song - 1 s at 22050 Hz
	# holding exactly 110 cycles of a 110 Hz fundamental with
	# a harmonic stack that thins upward (a tire's hum has a
	# clear tone where the skid's hiss has none). pitch_scale
	# carries the strain: as the band fraction climbs the
	# whole stack rises, the way a real tire's note climbs
	# toward the squeal. The skid stream stays the noise; this
	# one is deliberately its tonal opposite.
	var rate: int = 22050
	var frames: int = rate
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i: int in frames:
		var ph: float = TAU * 110.0 * float(i) / float(rate)
		var v: float = sin(ph) + 0.52 * sin(ph * 2.0) + 0.26 * sin(ph * 3.0) \
			+ 0.12 * sin(ph * 5.0)
		v = clampf(v * 0.40, -0.85, 0.85)
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


func _make_rumble_stream() -> AudioStreamWAV:
	# Fix Pass 15 (Item 1): the off-road rumble - the skid's
	# noise pushed through a much harder one-pole low-pass
	# (0.35 -> 0.06) until only the bottom is left: dirt and
	# stone under the tires, felt as much as heard. Same loop
	# seam treatment as the skid (tail crossfaded into head).
	var rate: int = 22050
	var frames: int = rate
	var raw: Array[float] = []
	raw.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var lp: float = 0.0
	for i: int in frames:
		var wht: float = rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, wht, 0.06)
		raw[i] = lp * 3.2
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


func _make_scrape_stream() -> AudioStreamWAV:
	# Fix Pass 15 (Item 1): the edge scrape - high-passed
	# noise (the skid's hiss with the body removed) plus two
	# exact-cycle metallic partials (523 and 1046 Hz, integer
	# cycles in the 1 s loop so the seam is silent): metal
	# and stone grinding along the rim. Distinct from the
	# rumble (all bottom) and the song (all tone) by
	# construction.
	var rate: int = 22050
	var frames: int = rate
	var raw: Array[float] = []
	raw.resize(frames)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9182
	var lp: float = 0.0
	for i: int in frames:
		var wht: float = rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, wht, 0.30)
		var ph: float = TAU * float(i) / float(rate)
		raw[i] = (wht - lp) * 0.9 + 0.13 * sin(ph * 523.0) + 0.08 * sin(ph * 1046.0)
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
	# _notification and the smoke). Latching STOPS all players -
	# not just gains down - so nothing can sound while latched.
	audio_latched = on
	if on:
		for pl: AudioStreamPlayer in [engine_player, skid_player, song_player, rumble_player, scrape_player]:
			if pl != null and pl.playing:
				pl.stop()


func _update_audio(delta: float) -> void:
	# Runs on the physics tick: records the tick for the stall
	# watchdog (_process) and drives both channels from sim state.
	audio_last_physics_ms = Time.get_ticks_msec()
	audio_stalled = false
	if engine_player == null:
		return
	var running: bool = race_started and not audio_latched
	if not running:
		for pl2: AudioStreamPlayer in [engine_player, skid_player, song_player, rumble_player, scrape_player]:
			if pl2 != null and pl2.playing:
				pl2.stop()
		audio_song_now = 0.0 # Fix Pass 15 (Item 1): the smoothed drives die with the race
		audio_rumble_now = 0.0
		audio_scrape_now = 0.0
		return
	for pl3: AudioStreamPlayer in [engine_player, skid_player, song_player, rumble_player, scrape_player]:
		if pl3 != null and not pl3.playing:
			pl3.play()
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
	# Fix Pass 15 (Item 1): the SONG - the band fraction,
	# smoothed a touch slower than the skid (the warning should
	# feel like strain building, not a switch). Gain rides the
	# band edges; pitch climbs 0.85 -> 1.75 across the band, so
	# the note itself leans toward the squeal it precedes. The
	# post-limit skid above is untouched: below its own onset
	# the song owns the tire voice, past it the two overlap for
	# the stretch where the tires sing AND slip at once.
	var song_k: float = 10.0 if tire_band > audio_song_now else 7.0
	audio_song_now = lerpf(audio_song_now, tire_band, clampf(delta * song_k, 0.0, 1.0))
	if audio_song_now < 0.01:
		song_player.volume_db = -60.0
	else:
		song_player.volume_db = lerpf(AUDIO_SONG_FLOOR_DB, AUDIO_SONG_MAX_DB, audio_song_now)
	song_player.pitch_scale = 0.85 + 0.90 * audio_song_now
	# The RUMBLE: strength straight from the support state;
	# pitch wanders slowly (the original's randomised-pitch
	# rumble) on a half-second hash cadence, independent of
	# everything else in the car.
	var rum_k: float = 12.0 if edge_rumble_now > audio_rumble_now else 8.0
	audio_rumble_now = lerpf(audio_rumble_now, edge_rumble_now, clampf(delta * rum_k, 0.0, 1.0))
	if audio_rumble_now < 0.01:
		rumble_player.volume_db = -60.0
	else:
		rumble_player.volume_db = lerpf(-34.0, AUDIO_RUMBLE_MAX_DB, audio_rumble_now)
	var hw15: float = sin(float(int(race_time * 2.0)) * 12.9898) * 43758.5453
	rumble_player.pitch_scale = 0.72 + 0.30 * (hw15 - floor(hw15))
	# The SCRAPE: same smoothing family; its pitch rises with
	# the grind's strength (deeper penetration, harder grind).
	var scr_k: float = 14.0 if edge_scrape_now > audio_scrape_now else 10.0
	audio_scrape_now = lerpf(audio_scrape_now, edge_scrape_now, clampf(delta * scr_k, 0.0, 1.0))
	if audio_scrape_now < 0.01:
		scrape_player.volume_db = -60.0
	else:
		scrape_player.volume_db = lerpf(-32.0, AUDIO_SCRAPE_MAX_DB, audio_scrape_now)
	scrape_player.pitch_scale = 0.90 + 0.35 * audio_scrape_now


func audio_engine_pitch() -> float:
	# Test accessor: the engine's current pitch factor (rev state).
	return audio_rpm


func audio_skid_gain() -> float:
	# Test accessor: the skid's current gain, 0..1 of full slip.
	return audio_skid_now


func audio_song_gain() -> float:
	# Fix Pass 15 (Item 1) test accessor: the tire song's gain
	# (the smoothed band fraction), 0..1.
	return audio_song_now


func audio_rumble_gain() -> float:
	# Fix Pass 15 (Item 1) test accessor: the off-road rumble's
	# smoothed gain, 0..1.
	return audio_rumble_now


func audio_scrape_gain() -> float:
	# Fix Pass 15 (Item 1) test accessor: the edge scrape's
	# smoothed gain, 0..1.
	return audio_scrape_now


func telegraph_rumble_now() -> float:
	# Fix Pass 15 (Item 1) test accessor: the controller
	# rumble's current strength, 0..1.
	return rumble_haptic_now


func _update_telegraph(_delta: float) -> void:
	# Fix Pass 15 (Item 1): the non-audio voices of the one
	# signal. DUST: each wheel's emitter speaks for its axle -
	# the end nearer its limit sheds dust at its contact
	# patches, from the band's lower edge, thickening toward
	# breakaway (amount_ratio IS the band fraction). Cost,
	# stated: 4 GPUParticles3D x 18 particles of 6x3-segment
	# spheres - 72 particles worst case, a rounding error next
	# to the ribbon; the emitters exist from build and idle at
	# emitting=false. RUMBLE: the controller buzz joins only in
	# the final stretch (ratio past TIRE_HAPTIC_EDGE), light
	# (0.30 amplitude at full stretch) and scaling; it is
	# derived from the same ratio in the same frame, and the
	# ratio is 0 on a centred straight by construction, so it
	# cannot fire there.
	for wi: int in dust_emitters.size():
		var em: GPUParticles3D = dust_emitters[wi]
		var axle_w: int = wheel_axle[wi]
		var amt: float = 0.0
		if mode == MODE_DRIVE and tire_band > 0.0:
			if tire_ratio_axle < 0 or tire_ratio_axle == axle_w:
				amt = tire_band
		em.emitting = amt > 0.02
		em.amount_ratio = amt
	rumble_haptic_now = 0.0
	if mode == MODE_DRIVE:
		rumble_haptic_now = clampf((tire_ratio - TIRE_HAPTIC_EDGE) / (1.0 - TIRE_HAPTIC_EDGE), 0.0, 1.0)
	if xr_ok and xr_iface != null and rumble_haptic_now > 0.0:
		for trk15: StringName in [&"left_hand", &"right_hand"]:
			xr_iface.trigger_haptic_pulse(&"haptic", trk15, 0.0,
				0.08 + 0.22 * rumble_haptic_now, 0.09, 0.0)





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
		# Fix Pass 13 (Item 6): pose the full ARRIVED state,
		# facing included - the real arrival gate guarantees
		# the carrier within 0.08 rad of the drop heading, and
		# a hook that left the pickup-facing yaw in place
		# dropped test cars sideways off the road.
		carrier_yaw = _frame_yaw(_frame_at(drop_target_s)["tan"])
		orient_yaw = carrier_yaw
		orient_yaw_v = 0.0


func debug_force_fall_at(s: float) -> void:
	# Fix Pass 20 (Item 3): stage a fall FROM s through the
	# production loss path - the car is placed in AIR 20 m
	# below the road at s with air_start_s = s, so
	# _update_air's lost trigger charges the recovery from s:
	# the same state a real fall reaches, entered the way
	# debug_stage_landing enters its landings. Everything
	# downstream - the drop search, the crane recovery, the
	# hang, the release - is production.
	var frf: Dictionary = _frame_at(s)
	mode = MODE_AIR
	air_from_gap = false
	air_from_release = false
	air_from_rebound = false
	air_time = 0.0
	air_s_est = s
	air_start_s = s
	air_exit_y = float(frf["pos"].y)
	below_band_t = 0.0
	lost_lat_t = 0.0
	air_vel = Vector3(0.0, -6.0, 0.0)
	car.global_position = frf["pos"] - Vector3.UP * 20.0


func debug_audit_begin() -> void:
	# Fix Pass 24 (Item 3): arm the air audit's recorder for
	# the ACTIVE track (see _pay_for_landing / _enter_air).
	# A staged reference lap is then driven over it by the
	# test (stage 54's protocol: pinned-24 pursuit, the
	# proven gap-window drivers at the gaps). Test-mode
	# only - the shipped game never arms this.
	audit_sectors.clear()
	audit_flights.clear()
	var n: int = int(ceil(track_len / AUDIT_SECTOR_M))
	for i: int in n:
		audit_sectors.append(0.0)
	audit_income = 0.0
	audit_air_s = 0.0
	audit_flight_open = false
	audit_on = true


func debug_audit_end() -> Dictionary:
	# Fix Pass 24 (Item 3): close the audit and hand back the
	# geography: payable air-seconds per sector, the lap's
	# total payable air, its projected income at the shipped
	# dials (gross, before the tank clamp), and the longest
	# air-starved stretch (the longest run of zero sectors).
	audit_on = false
	var best: int = 0
	var run: int = 0
	for v: float in audit_sectors:
		if v <= 0.0:
			run += 1
			best = maxi(best, run)
		else:
			run = 0
	return {"sectors": audit_sectors.duplicate(), "air_s": audit_air_s,
		"income": audit_income, "longest_starved_m": float(best) * AUDIT_SECTOR_M,
		"track_len": track_len, "flights": audit_flights.duplicate()}


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
# Fix Pass 16 (Item 2): the INVERTED audit's margin - a grab
# volume must contain its mesh by at least this much (the
# audit's worst reads (mesh distance - radius), so containment
# with margin is worst <= -DASH_AUDIT_MARGIN).
const DASH_AUDIT_MARGIN: float = 0.03
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


func _aabb_sample_points(a: AABB) -> Array[Vector3]:
	# The 8 corners + centre of a mesh's local AABB - the
	# extreme points the containment audit measures.
	var pts: Array[Vector3] = []
	for xi: int in 2:
		for yi: int in 2:
			for zi: int in 2:
				pts.append(a.position + Vector3(
					a.size.x * float(xi), a.size.y * float(yi), a.size.z * float(zi)))
	pts.append(a.get_center())
	return pts


func debug_dash_ctl_audit() -> Dictionary:
	# Fix Pass 16 (Item 2): THE RULE INVERTS. Through FP15 this
	# audit kept grab zones honest against their meshes (no zone
	# point floating off its control). Item 2 decouples the two
	# on purpose - smaller furniture, generous volumes - so the
	# guarantee that matters is the converse: every control's
	# grab VOLUME must CONTAIN its mesh, with margin, or part of
	# the visible control is a dead surface a hand can touch and
	# miss. worst = the largest (mesh-point distance to the grab
	# segment - the radius) over every sampled point of every
	# mesh: contained-with-margin reads <= -DASH_AUDIT_MARGIN.
	# The old buried rule survives: no mesh point inside foreign
	# bodywork (an invisible control is still a defect).
	var car_xf: Transform3D = car_body.global_transform
	var all_meshes: Array[MeshInstance3D] = []
	_collect_meshes(car_body, all_meshes)
	var worst: float = -1e9
	var violations: Array[String] = []
	for i: int in dash_ctl_nodes.size():
		var node: Node3D = dash_ctl_nodes[i]
		var seg: Array[Vector3] = _dash_ctl_segment(i)
		var r: float = _dash_ctl_radius(i)
		var own: Array[MeshInstance3D] = []
		_collect_meshes(node, own)
		for mi: MeshInstance3D in own:
			for lp: Vector3 in _aabb_sample_points(mi.get_aabb()):
				var wp: Vector3 = mi.global_transform * lp
				worst = maxf(worst, _seg_point_dist(seg[0], seg[1], wp) - r)
				for other: MeshInstance3D in all_meshes:
					if own.has(other):
						continue
					var la: Vector3 = other.global_transform.affine_inverse() * wp
					if other.get_aabb().grow(-0.01).has_point(la): # >1 cm inside on every axis - a base seated in its mount is not buried
						violations.append("%s mesh point buried in %s" % [
							dash_ctl_kinds[i], other.name])
						break
	# Fix Pass 20 (Item 1): the drop lever's own audit block
	# stood here (it answered the rule at rest and at full
	# throw, its volume riding the arc). The DROP BUTTON is a
	# dash control, so the loop above audits it like the rest.
	return {"worst": worst, "violations": violations}

