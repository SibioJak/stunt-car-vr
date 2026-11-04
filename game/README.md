# Stunt Car VR — DE Test 1 "Drop & Dangle"

A Godot 4.7 / OpenXR **feel prototype**, not a game. It exists to answer
five questions in the headset (Quest 3 target):

1. Does the **Drop Start** — dangling under a drone on 4 lines, swaying,
   timing your own release — feel as good as it sounds?
2. Do the **jump and the descent** churn the stomach the right amount?
3. Does flipping the **prep switches while dangling** work as cockpit
   prep (a completed sequence pays out a small boost credit)?
4. Does **grabbing the wheel** and physically turning it steer well?
5. **Lean experiment:** does leaning into the banked corner for bonus
   grip feel like a real technique (bonus only, never required)?
   — RETIRED in Fix Pass 31 (owner's order): judged vestigial
   once FP21's per-corner loads made load transfer real; the
   whole mechanic is deleted, see the Fix Pass 31 section.

Design contract: `../design-spec.md` (v0.1 as amended, items 1–16) and
`../build-brief-test1.md`. Deliberately NOT in this test: rivals/sumo,
loops, season, track designer, random tracks, boost pads, car choice,
real carnage (dent + smoke placeholder only), audio, multiplayer.

## The run

Drop Start dangle → time the release (touchdown is scored FLAT / OK /
ROUGH / HARD) → start straight → steep climb → banked left corner →
launch lip → **the gap** (cross it with speed; boost helps; fall and
the drone catches you) → descent → and since Fix Pass 7 the ribbon
keeps going: a crest straight of five true humps (since Fix Pass 8
they unload the car completely at cruising speed — expect real air,
~1 s a hump, and no steering while you're up there) → a banked
right sweeper → a descending staircase → a **second gap** → a final
climb → a long home straight → the finish gantry (1,163 m in all).

Fall off anywhere, or call the drone yourself: it carries you back over
the ribbon, you dangle, you may flip the 3-switch prep sequence shown
on the dash (wrong switch = restart the sequence; finishing pays +25
boost), then you time the release again. Release away from the track
and you fall — and the drone catches you again.

**Scale (Fix Pass 9):** the road is **9.36 m wide** — Crammond's
proportion, 6.0× the car's measured 1.56 m front wheel track — and it
no longer floats in a void: a desert floor runs ~60 m below the track
datum (the ribbon's lowest sections sit ~85–90 m above it), with mesas
and a ring of distant low hills to a hazy horizon.

**Edges (Fix Pass 9):** run a wheel off the ribbon and it rides an
invisible sloping shoulder — that wheel's support drops progressively
with overshoot, the body wobbles and rolls toward the off side, and
steering back onto the ribbon restores full support (the save). A
wheel is fully unsupported 1.17 m past the edge (¾ of the wheel
track); the whole car falls only when its centre is ~1.95 m past the
edge — support truly gone, not at first edge contact.

## Controls (also listed on the in-cockpit panel — every command)

VR (Quest):
- **Grab wheel:** squeeze GRIP near the wheel, turn the hand. Last
  hand to grab drives; the other hand takes over when it lets go.
  Since Fix Pass 29 the wheel's semantics are the rebuilt ones:
  letting go HOLDS the angle (no bleed to centre), a hand coming
  back from a dash button takes the wheel in one step, two hands
  steer by the line between them, and the right thumbstick is a
  steering source in its own right — the fallback in WHEEL steer
  mode, the primary in STICK mode (persisted; hold the right A
  button while hanging to flip it, N on desktop; the DIAG WHEEL
  line's SRC field names the live source over the mode). Since
  Fix Pass 30 the wheel is live for the WHOLE hang — grab and
  steer from the first second of the lift and dial the landing
  lock during the crane ride, not only at the dangle; an amber
  centre stripe on the rim, read against the fixed white tick
  at top centre, shows the lock (stripe over tick = straight)
- Throttle: right trigger · Brake: left trigger · Boost: right A
  button (while driving) — since Fix Pass 24 the boost is a
  tank (120 units = 4 s, 60 dealt at the start) that racing
  air refills at graded landings; the dash-face bar in the
  button cluster's row is its meter
- **The gearbox is AUTOMATIC (Fix Pass 40) — there is no shift
  command, and the cockpit list above stays complete.** Four
  ratios shift themselves on road speed: each shift is a real
  event (the engine note drops and climbs per gear, the thrust
  gaps for a beat), each gear pulls hardest just after its
  shift and fades toward the next, and first gear is savage —
  floor it from a stop and the rear tires burn until they
  hook. The DIAG SPD line shows the live gear. Car feel that
  comes with it, also command-free: gunning it out of a corner
  steps the tail out a little until the tires catch (lift and
  it tucks back), and landings are priced in speed — a clean,
  slope-matched touchdown keeps ~all of it, a scrubbed one
  spends a share, a crossed-up arrival or a nose-first slam
  into a hill face spends most of it (speed only; damage is a
  later build's business)
- **Release:** press the DROP BUTTON on the dash face (while
  dangling) — a big red button at the old lever's spot; GRIP
  near it. It answers in every phase: at the dangle it drops
  you; during the crane's attach/carry it refuses with a grind
  (nothing drops); while driving it just thocks. Fix Pass 20
  retired the drop lever (FP11–FP19) for this button. Its side
  follows the blue SIDE dash button / M key (lefty mirror) and
  persists between sessions
- Flip a prep switch / press a dash button: GRIP near it (while
  dangling) — since Fix Pass 9 either order works: squeeze-then-touch
  or touch-then-squeeze; the flip fires when grip and proximity
  meet, once per entry
- Call the drone (while driving): left X button — and since Fix
  Pass 29, left X while HANGING is the drop (the same release as
  the DROP BUTTON / SPACE, in every hang phase; the crane call
  is DRIVE-only, so X keeps both jobs)
- Restart race: left Y button · Info panels show/hide: right B
  button (Fix Pass 12 — the boards are hidden by default; B
  calls them up and puts them away. Red dash button = restart)
- Switch track (while dangling): GRIP near the purple dash button —
  Track 01 (default), the original test ribbon, the Feature Lab
  and TRK2 (the funlab); a Track 01 race is 3 laps to the finish,
  the ribbon is point-to-point, the lab is the piece library as a
  practice lap, TRK2 is the extremes course — loop, corkscrew,
  barrel roll and wall-ride on one straight line
- Jump to a TRK2 element (Fix Pass 41): GRIP near the green ELEM
  dash button — the crane collects the car from wherever it is
  and stations it at the NEXT element's run-up, so no element
  gates another; desktop E cycles and F1/F2/F3/F4 jump straight
  to E1/E2/E3/E4 (F4 added Fix Pass 43 with the fourth element).
  On any other track the button is inert
- Recenter: click the left stick
- Road-jitter experiment on/off: click the right stick (state shows
  as JIT in the DIAG block; default ON)

Desktop fallback (no headset): the mirror rig drives the same car.
- W/S throttle/brake · A/D steer · SHIFT boost · SPACE release
- 1/2/3 flip FUEL/SPARK/BOOST · L call drone · R restart · V switch track
- C recenter
- J road-jitter experiment on/off (default ON)
- Mouse drag steers while the left button is held

## Run it

Desktop: open the project in Godot 4.7 and run, or
`Godot_v4.7 --path . ` — with no HMD it boots into the fallback rig
automatically (window 1280×800, mouse/keyboard as above).

## Tests (all headless, all scripted through production code paths)

```
# logic smoke: drop start -> release -> touchdown scored -> climb ->
# bank held -> gap crossed airborne -> drone lift on demand -> prep
# sequence -> boost credit -> release -> driving -> at the bank,
# stage 7 proves the lean experiment's deletion (Fix Pass 31);
# stage 61 proves the landing stroke law, the sink's view
# transmission in both A/B modes and the per-axle contact
# thump's severity ordering (Fix Pass 32);
# stage 63 proves the view law: restarts re-seat position
# only at ±20 deg of head yaw, the stick-click bake survives,
# and a both-grips squeeze fires nothing (Fix Pass 34);
# stage 64 proves the anchor capture window (Fix Pass 35);
# stage 65 proves the burnout pass: the floored launch spins
# and hooks, the feathered launch does not, the sliding
# touchdown answers inside a drumbeat contact, the yaw
# carries through a hop, and the throttle steers the exit
# line (Fix Pass 36);
# stage 66 proves TRK2, the funlab: the roster's fourth
# track, its three elements' built shapes and boards,
# Drop Start + crane recovery on the course, the loop's
# measured wedge at the vertical, the corkscrew's
# sideways loss short of inverted, the barrel roll's
# completion with its toss, and the course's finish
# crossed under power (Fix Pass 38)
# The smoke run first executes the API GUARD (reported separately):
# every XR API method/property the game code calls by name is asserted
# against ClassDB in the running engine. Hotfix 1 added it after
# main.gd called the nonexistent XRCamera3D.get_is_tracking() on a
# line that only executes in XR mode, wedging the live headset run;
# the HMD tracking check now goes through the head tracker's pose
# (XRServer.get_tracker("head") -> XRPositionalTracker.get_pose ->
# XRPose.has_tracking_data).
Godot --headless --path . --script tests/smoke_test.gd

# rendered-frame proof (needs GL; use Xvfb, NOT --headless):
# writes tests/cockpit_view.png and tests/lift_view.png and asserts
# the panel lists every command. Fix Pass 1 added two more captures:
# tests/sightline_view.png (long offset sightline, climb -> bank -> lip)
# and tests/ribbon_side_view.png (grazing side angle: ribbon thickness
# and skirt) - the track must visibly exist, not read as pylons only.
# Fix Pass 4 added tests/diag_closeup.png (the split DIAG board shot
# from a camera parented to the board) plus geometric panel checks
# from the eye anchor: text fits its board, all text corners project
# inside the frame with >= 8% margin, and no car mesh crosses the
# sightlines to the text (segment vs each mesh's local AABB; the
# wheel rim/hub via a plane-crossing annulus test).
# Fix Pass 2: cockpit_view is shot from the driver eye anchor (fallback
# camera) and the proof asserts hub-vs-anchor reach geometry plus the
# recovery hang's centreline offset; the smoke asserts the same
# centring for the Drop Start and the recovery, and that a release at
# swing centre lands on the ribbon.
xvfb-run -a Godot --path . --script tests/render_proof.gd

# frame discipline probe (nodes / draw calls / primitives)
xvfb-run -a Godot --path . --script tests/frame_stats.gd
```

## Fix Pass 3 (after headset run 3: panel legible, track reads —
## but the seat anchor never visibly took effect, grip interactions
## never fired, drawn controllers sat ~a controller's length ahead
## of his hands, the wheel read flat, phantom lean on straights)

- **Panel DIAG block (new).** Live block under the command list,
  refreshed ~5 Hz: anchor state (PENDING / APPLIED-STABLE /
  APPLIED-FALLBACK) + HMD-tracking flag + camera height in car
  space; per hand the raw grip / grip_click / grip_force values,
  hand-to-hub distance in cm, NEAR and HOLD flags; wheel angle in
  degrees. The next headset screenshot is a bug report by itself.
  The board grew to 0.76 × 1.56 m (sized from the label's measured
  1.40 m rendered height) so list + DIAG physically fit on it.
- **Seat anchor, stability-gated.** The correction applies only
  after the tracked HMD pose is stable (camera local position
  moves < 1 cm across 20 consecutive physics frames), not on the
  first frame tracking data exists — a correction baked from a
  transient first pose (headset not yet worn / stream unsettled)
  is the working explanation (inference) for run 3. If the ~10 s
  fallback fires first it applies anyway, then re-applies ONCE
  when a stable pose appears. Recenter re-arms the gated path.
- **Grip robustness.** Grip is active if ANY channel says so —
  analog grip > 0.65 OR grip_click OR grip_force > 0.65 — one
  combined condition everywhere. Wheel-grab radius 0.30 → 0.40 m;
  dash-control radius 0.24 → 0.32 m. Controller reps rebuilt
  centred on their node origin with a bright sphere exactly AT
  the origin (the point shown = the point the math measures).
  Controller pose set explicitly to "default" (field census: only
  "default"/"palm_pose" poses carry live data on this rig).
- **Wheel stood up.** Rim plane now 22° off vertical facing the
  driver (tilt 68° about X; it was 68° OFF vertical — a flat
  plate). Rebuilt honestly: tilt node + spin node on the wheel
  axis, spokes/hub in the rim plane, column aligned to the axis;
  grab-angle math re-derived in the wheel plane, 1:1 at the rim,
  clockwise steers right. Measured in the from-anchor render:
  rim ellipse minor/major ratio **0.86** (target ≥ 0.55).
- **Phantom lean: diagnosed + fixed.** Cause (measured): the
  track generator converged the corner's bank at 0.012 rad per
  1 m sample, leaving 27° of bank at s=185 on the nominally flat
  run to the jump — the car honestly followed a banked frame on a
  "straight". Post-corner walks now converge bank at 0.10
  rad/sample (flat ~6 m past the corner exit); frame bank at
  s=195 is 0.00° (negative control with the old rate: 19.9°).
  New smoke stage 2b asserts standstill AND cruise on the start
  straight stay within 1° of level at zero steering input.
  Smoke 19/19, API guard 8/8 (also asserts the XRNode3D.pose
  property), render proof 35/35.

UNVERIFIED by design (XR layer — only headset run 4 proves these):
read the panel DIAG block first — it says whether the anchor
applied (APPLIED-STABLE expected), which grip channel Virtual
Desktop actually feeds, and whether hands register NEAR/HOLD at
the wheel. Then judge: seated framing on the anchor, switch flips
WHILE DANGLING, wheel grab + 1:1 turn, the stood-up wheel plane,
and no phantom lean on the start straight. Headless numbers:
centreline offsets 0.000 m, start-straight roll 0.00°, wheel
ellipse 0.86 — his view is the verdict.

## Fix Pass 4 (after headset run 4: grip live-verified, anchor
## APPLIED-STABLE in his photo — but switches fired from too far
## away, and the enlarged panel was not readable in the headset)

- **Near-touch dash activation.** Run 4 proved the grip channels
  live, so the Fix Pass 3 insurance radius became the defect:
  DASH_CTL_RADIUS 0.32 → **0.15 m**, applied in the one place
  proximity is computed (`_dash_ctl_near` — switches, buttons and
  takeover all use it). The wheel grab radius STAYS 0.40 m: it
  measures hand-to-hub-centre and a hand ON the rim already reads
  ~0.2 m. Smoke stage 2d asserts both constants and the production
  query's behaviour (0.10 m activates, 0.20 m does not).
- **Panel split + moved onto clear sightlines.** The single
  0.76 × 1.56 m board is now two: the **commands board** (status +
  the full command list, same font size as before) at
  (0.78, 1.53, −1.66) ahead-right, yawed toward the driver; and a
  small **DIAG board** (the same DIAG fields, slightly smaller
  type) at (−0.53, 1.17, −0.85) low-left over the dash. Placement
  was driven by the render proof's new geometric checks from the
  eye anchor: both boards' text fits its board, every text corner
  projects inside the frame (worst margin 10.5% commands / 12.3%
  DIAG — the fallback frame is narrower than the Quest's, so the
  headset has more room), and 0 of 63 sampled sightlines per board
  are blocked by car geometry. The switch knobs dictated the
  commands board's height (the bottom row's sightlines pass just
  over the right knob), and the DIAG board's right column clears
  the left knob the same way. Known transient cosmetic overlap,
  unchanged in kind from earlier passes: the big state/prep HUD
  labels (not car geometry) can cross the commands board's left
  strip while they are displayed.
  Smoke 23/23, API guard 8/8, render proof 46/46, all previous
  driving numbers identical.

UNVERIFIED (live feel — only headset run 5 proves these): whether
0.15 m reads as touching the switch rather than reaching for it,
and whether both boards are readable at a glance in the headset.
Headless geometry says the sightlines are clear and the text is
in frame; his eyes are the verdict.

## Fix Pass 5 (after headset run 5: the feel pass — DIAG readable
## and activation better, but levers fired only at the tip, the
## dangle was too tame, the chains felt taut, lean was invisible,
## and the car had no mass: "i'm missing the feeling that i'm in
## something heavy on big beefy shocks... i want to feel that
## suspension when it hits the road")

- **Suspension and mass (headline).** A per-axle spring model now
  lives in the driving model: front/rear compression states chase
  road-geometry targets (wheelbase-filtered road rise at each
  axle), scaled by a crest load factor (v²·κ vs gravity — the road
  falling away unloads the springs) plus accel/brake weight
  transfer. Body heave/pitch derive from the spring attach heights;
  the wheels visibly travel; the view rides the same state on a
  ViewSpring node in the seat stack (anchor untouched, offsets
  transient, grounded modes only): compression dive on touchdown
  scaled by landing grade, squat/dip under power/brakes, small
  continuous working motion. **Rebound air is a result**: both
  axles at full droop still extending (or a full crest unload at
  speed) puts the car genuinely airborne — the original got "a lot
  of air just bouncing"; so does this, now.
- **Lever grab-zone activation.** Switches are measured to the
  lever's grab segment (base→cap) at the same 0.15 m; buttons keep
  the point measure. The tip is no longer the only live spot.
- **Precarious sway, compliant chains.** The dangle is two pendulum
  axes on different lengths (5.5 / 3.9 m) — a diagonal resultant
  that never settles single-plane — with light damping, irregular
  drone dips (the pivot drops and corrects; effective gravity in
  the pendulum follows the pivot), brief line-slack free-falls on
  hard dips with a blended catch, and a lagged car attitude (the
  car settles a beat behind the swing). Release still converts the
  full swing state into the drop: timing it stays the skill, and a
  centred release still lands on the ribbon (smoke stage 6).
- **Lean view tilt.** The experiment's "no camera roll" rule is
  revised at Chris's direction: while lean is ON, the view rolls
  with the lean at LEAN_VIEW_GAIN 1.25× a 10° step (symmetric, zero
  at centre); OFF restores the level view exactly. Grip effects
  unchanged.

UNVERIFIED (live feel — only headset run 6 proves these): whether
the suspension reads as HEAVY, whether the bounce and the dangle's
new precariousness land as feel rather than motion, and whether
the amplified lean tilt registers without fighting his head.

## Fix Pass 6 (after headset run 6: lean tilt trimmed to ×1.25 —
## shipped ahead of this pass, commit db54be5 — suspension landed,
## but the DRIVER's own weight was missing from the view, the road
## felt narrow, there was no engine/skid sound, and the drone's
## lift wires crossed)

- **Driver-body seat spring.** Run 6: "when car hits road and
  tires hit, player should feel like his view is also sinking
  down within the seat… two different sensations at once — car
  spring + body spring… that's the Star Wars effect." A second
  spring now sits between the car's ViewSpring and the headset:
  soft, laggy, driven by touchdown impulses (through the
  production landing path), suspension-bottoming thumps, the
  dangle's line-catch, and longitudinal load (acceleration
  presses you in, braking tips you forward). Its signature is
  phase: the car's springs peak first, the driver's sink peaks
  after. Zero at rest; sink clamps at 55 mm so it can never feel
  like the seat is falling away. Tuning constants: `BODY_K`,
  `BODY_DAMP`, `BODY_MAX_SINK`, `BODY_IMPULSE_K`,
  `BODY_MIN_IMPULSE`, `BODY_PITCH_K`, `BODY_CATCH_IMPULSE`.
  Smoke stage 2e measures it (a calm touchdown sinks ~8 mm,
  peaking ~10 frames after the car springs; a rough one drives
  it to the clamp); the render proof reads 0.035 m of sink at
  its staged touchdown.
- **The road is 8 m wide.** Run 6: "Stunt Car Racer gave you
  the sense the road was wide and massive, not a rollercoaster…
  there was room to manoeuvre." `HALF_WIDTH` 2.3 → 4.0 m; the
  ribbon, its supports, the off-line rule (2.15× half width)
  and the vent all derive from it. New capture:
  `tests/wide_road_view.png`.
- **First audio: engine + skid, both synthesized in code** (no
  audio assets). A harmonic loop whose playback rate is the rev
  counter — speed first, throttle flare, boost lift, airborne
  unload — and a noise loop whose gain follows the model's TRUE
  lateral slip state (the curvature drift after the lean grip
  modification), so it sounds exactly when the tires are losing
  the argument and is silent while gripping or airborne. Levels
  are conservative (engine −17 dB, skid peaks −13 dB). Teardown
  discipline, per the standing rule: a latch stops both players
  on application focus-out / window close / tree exit; a stall
  watchdog cuts gains if the physics loop goes quiet; nothing
  sounds before a race is live and nothing resumes except on a
  genuine focus-in. NO new controls — the panel is unchanged.
  Smoke stage 2f asserts the state machine (pitch 1.31 → 2.02
  across ~6 → ~26 m/s; skid 0 gripping, 0.80 under forced bank
  slip, ~0 airborne; the latch stops both players).
- **Lift wires uncrossed.** Run-6 photo: "the wires are crossed."
  Cause: the drone held world yaw 0 while the car hung yawed
  with the track, so numbered corners paired across the quad.
  During the hang the drone now holds its yaw aligned to the
  car's heading (the track frame at the drop target; the car's
  own heading in the dangle), corner i → corner i. Proven two
  ways: a plan-view segment-intersection sweep over 30 sampled
  hang states (0 crossings) and capture `tests/wires_view.png`
  from below — four lines in a clean fan.

UNVERIFIED (live feel and ALL sound — only headset run 7 proves
these): whether the body sink reads as YOUR weight landing in
two stages (car, then you); whether the wide road's manoeuvre
room is real at the bank; and whether the engine and skid tell
you what the tires are doing, at the right levels. Sound quality
is Chris's ears' verdict alone.

## Fix Pass 7 (after headset run 7: "much better" — and "can I
## get some longer track? it's awfully short"; Chris bundled the
## Crammond jitter mechanism into the same pass)

- **The lap is ~3× longer: 1,218 m.** The original lap is
  generated exactly as before through the old finish (six runs
  of verdicts compare against it); past it the ribbon continues:
  a 280 m crest straight (four rolling crests), a banked RIGHT
  sweeper mirrored from the first corner (the lap banked only
  one way — steering is now judgeable both ways), a descending
  staircase of six drop/tread steps, a second gap at the same
  14 m spec, a final climb and a 200 m home straight to the
  relocated finish gantry. Smoke stage 8 drives the FULL lap
  from a fresh Drop Start to MODE_DONE: measured full-lap time
  **38.1 s on the game clock** at autopilot pace (throttle 0.9,
  boost at both gaps — the model's speeds are high; the 3× is
  in the ribbon, 401 → 1,218 m). New captures:
  `tests/crest_view.png` (driver's view down the crest
  straight) and `tests/sweeper_view.png` (the mirrored bank
  from trackside).
- **The Crammond jitter mechanism** (crammond-notes.md Q3: the
  original's profiles are smooth analytic ramps; its tire
  jitter EMERGES from faceted segments, coarsely quantised
  heights, few-point sampling and a derivative-happy wheel
  response). Reproduced structurally: the SUSPENSION now
  samples a quantised elevation profile — control heights
  snapped to `JITTER_STEP_M` (0.05 m) at facet boundaries
  `JITTER_FACET_M` (5 m) apart, linear between — while the
  visible mesh, car placement, crest load and the slip/skid
  path all keep the smooth profile. It looked smooth; it drove
  rough. No camera shake, no authored noise anywhere: the
  tremble arises through the existing springs. Measured (smoke
  stage 2g, steady-slope shelf of the climb at a pinned
  20 m/s): per-axle suspension travel trembles **14.2 mm
  (front) / 12.0 mm (rear) peak-to-peak** with jitter ON —
  inside the 5–15 mm target band — and collapses to 0.6 mm
  with jitter OFF (the negative control). Two honest wrinkles,
  per the brief's own escape clause: on the DEAD-FLAT start
  straight the quantised profile is identical to the smooth
  one (max diff 0.0000 m — on a mathematically flat road the
  mechanism is silent, exactly as in the original, whose
  flattest decoded profile is 14 zeros), so the cruise
  measurement lives on the climb, where the quantisation
  bites (max diff 0.0299 m); and the brief's 2–3 cm starting
  step measured only ~3 mm of tremble — under the model's own
  grid noise — so the step was tuned to 0.05 m BY MEASUREMENT
  to land the band. The skid cannot hear the tremble: forced-
  slip readings at the bank are identical ON vs OFF (0.799 vs
  0.799), because slip reads the smooth curvature, never the
  quantised surface. Landing/gap behaviour is unchanged (the
  gap span is un-quantised air; stages 2c/2e/3/8 all pass on
  the same numbers as Fix Pass 6).
- **A/B in the headset:** jitter toggles with the RIGHT stick
  click (desktop: J), default ON, state shown as JIT in the
  DIAG block — and per the standing rule the commands board
  lists the new command in this same pass (two panel lines
  were merged to hold the board's line count, after a longer
  merged line widened the label and put 2 of 63 proof
  sightlines behind car geometry — the proof caught it).
  API guard unchanged at 21: the toggle reuses
  XRController3D.get_input with the pre-existing
  `primary_click` action (the left stick's), so there is no
  new ClassDB surface to guard.
- Frame stats: 140 nodes (unchanged — the extension grows the
  merged ribbon meshes, not the node count), 66 draw calls,
  29,098 primitives (was 18,458; the longer ribbon and its
  stilts are the growth).

UNVERIFIED (only headset run 8 proves these): whether the
longer lap fixes "awfully short" and how the new sections
feel — the crests at speed, steering through a right-hand
bank for the first time, the staircase under the wheels;
and THE jitter question: whether the tremble reads as the
original's living road surface (tires worrying at a real
road) or as anything else. A/B it with the right stick
click, JIT ON vs OFF, on the climb and the crest straight.

## Fix Pass 8 (after headset run 8: "it really frame jumps in
## certain spots" — with a capture showing JIT OFF throughout, so
## the jitter mechanism was exonerated — and "I'm not getting any
## air on the little hills")

- **Frame steps: measured first, then fixed where the data
  pointed.** A step logger (inert in normal play) recorded a
  full autopilot lap per physics frame: view height/pitch, the
  geometry-only frame pitch and road height alongside, and the
  wall frame time. A step is a SECOND difference — the change
  of the per-frame delta — since raw deltas are just velocity
  (0.108 m/frame up the climb is legitimate travel). BEFORE
  (2,694 DRIVE frames, median frame 13,742 µs, **zero hitch
  frames** — no top step sits on a long frame; every offender
  is a place, not a hitch): worst view-height step **0.0191 m
  at the staircase (s=798)**, then 0.0183 m at the corner exit
  (s=178), 0.0173/0.0166 m at the sweeper exit (s=749), lip
  entries at 0.0146/0.0116 m; worst view-pitch step **1.570°
  at the staircase (s=801)**, with the lip entry (s=871) and
  staircase joins filling the table. The mechanism: the road
  is a 1 m-sampled polygon, and at every slope join the
  frame's vertical velocity and pitch rate SWITCHED in one
  sample instead of sweeping. A cubic-Hermite frame was tried
  first and measured WORSE (6.3° at the staircase — the
  generator's tangents are arriving-step directions, so the
  cubic overshoots mid-segment on cornered data); it was
  reverted on that evidence. The shipped fix works on the
  data the linear frame reads: one `[0.25, 0.5, 0.25]`
  smoothing pass over the stored points and tangents at build
  (every join's corner rounds over ~2 samples; deviation at
  most ~1.5 cm at the sharpest edges, millimetres elsewhere;
  mesh, placement, suspension and the air line all read the
  same smoothed arrays, and t_kv is smoothed the same way);
  the corner-exit bank unwind and both lip entries are
  rate-shaped (0.03 → 0.075 and 0.012 → 0.034 instead of flat
  0.10 / 0.030 from the first sample); the staircase's phi
  increments are uniform (0.077 rad/sample down and back,
  reaching the full −22° the old cycle never did). AFTER,
  the asserted GEOMETRY channels (frame pitch; frame_y — the
  height the sampled road alone gives the car) hold: outside
  the staircase **0.0127 m / 0.277° worst anywhere on the
  lap** (the lip joins and the sweeper-exit unwind through
  the car's lateral offset set the tier); at the staircase
  0.0289 m / 1.185°, which is the feature's own curvature at
  speed — six 22° drops the suspension still bottoms on
  (stage 8 asserts it) — not a sampling snap. The full-view
  table's top entries after the fix sit at the staircase and
  at landing/hop ring-down tails on the descent and humps,
  where the geometry channels at the same s are quiet: the
  residual view motion rides the spring integrators after
  genuine events, which is the suspension working, not the
  road stepping. Stage 2g re-derived honestly under the
  smoothing: its dead-flat window moved to the start
  straight's middle (the join rounding means the metres
  before the climb are no longer mathematically flat);
  there quantised == smooth still holds exactly (0.0000 m),
  and the tremble band is unchanged (14.2 / 11.8 mm per axle,
  6.8 mm avg, 0.9 mm OFF, skid 0.799 vs 0.799).
- **Real air on the crest straight.** The four gentle rollers
  (±5°, measured 0.162 m peak compression — they never even
  unloaded the springs) are replaced by five true humps:
  13 m climbing in at +11°, 19 m over the top at −11°
  (κ ≈ 0.021/m), 13 m flattening — ~2.2 m tall over 45 m.
  The arithmetic: at the stated cruise of 24 m/s, v²κ =
  576 × 0.021 ≈ **12.1 > g = 9.8**, so over each crest the
  road falls away faster than gravity pulls the car down
  and the wheel load clamps to zero at both axles. The lap
  is 1,163 m now; the full-lap smoke measures 37.0 s.
- **The rebound-air gate is reworked.** Fix Pass 5's rule —
  no air without a prior >0.19 m spring compression — is
  deleted; a compression prerequisite is exactly what a
  geometry crest never produces. Air is now a LOAD decision:
  (1) GEOMETRY route: load ≤ 0.03 at both axles sustained
  3 frames above 8 m/s; (2) REBOUND route: springs at full
  droop and still extending — but only from a genuinely
  loaded state (load ≥ 0.8 at the decision). The floor
  exists because measurement indicted its absence: at the
  climb-top bend at 34 m/s the load sits at ~0.27 sustained
  while both springs bleed to full droop chasing the falling
  road, rear still extending at ~0.57 m/s — droop + velocity
  alone read that bleed as a bounce and separated the car
  mid-corner; the load level is what tells a bleed from a
  bounce (at partial load the road's geometry holds the car;
  at full load the springs hold it, and their release is a
  throw). Stage 10 proves both sides: the NEGATIVE CONTROL
  runs the climb-top bend pinned at 30 m/s — no airborne,
  minimum load 0.43, partial by mechanism, not by a
  compression alibi; and the humps at 24 m/s give **5
  flights, 7.78 s of air total (~1.5 s per hump — separation
  on the shoulder with upward path velocity makes long
  arcs), minimum load 0.000**, lateral state frozen across
  every flight against a hard-over wheel poke (no ground
  steering authority while airborne), and all five landings
  grade through the normal production path — ROUGH, dent
  unchanged at 0. (Air time stated in true seconds: 5.19 s
  total, ≈1.0 s a hump — an earlier draft of stage 10b
  divided frames by 60 on a 90 Hz sim; the check now divides
  by 90.) New captures: `tests/hump_view.png` (the
  car leaving the road over a hump, trackside) and
  `tests/stairs_view.png` (the staircase stepping down).
  No new commands; the API guard grows to 22 (the step
  logger's `Time.get_ticks_usec`). Frame stats: 140 nodes,
  65 draw calls, 28,354 primitives.
- **Item 0 — the dead levers (Chris, mid-pass: "at some
  point, the lever stopped working").** In run 8 the prep
  levers worked at the Drop Start and died later in the
  session, while the wheel — same hands, same grip channels,
  same `_poll_grab` — kept working. The flip is
  EDGE-triggered (a fresh grip near a switch) where the
  wheel is level-triggered, so the hunt targeted state that
  could stop fresh edges or re-arming. Static audit: prep
  re-arms via `_prep_new_sequence()` in BOTH `start_race()`
  and `_begin_recovery()`; `gripping[hand]` is rewritten
  from the live channels every poll and cannot latch in
  code; the Fix Pass 7 jitter toggle reads the stick's
  `primary_click` through its own `_btn_edge` key and shares
  no state with the grip path, so it cannot eat or gate a
  flip; this pass's sampling changes never touch the
  interaction code. Dynamic audit: new smoke stage 11 runs
  the prep sequence through the PRODUCTION grip path —
  synthetic hand posed on each switch's grab segment,
  `_poll_grab`'s edge, `_dash_ctl_near` proximity,
  `_activate_dash_ctl` — on three successive dangles (Drop
  Start; drone recovery after a driven fall off the edge;
  fresh Drop Start after FINISH + restart), with a
  held-grip probe (six polls at full grip flip exactly
  once) and a wrong-order reset probe. **All pass: the bug
  does not reproduce headless, and no fix has been invented
  for it.** What stage 11 cannot reproduce is a live
  runtime delivering stuck channel VALUES — a grip channel
  stuck high from Virtual Desktop would kill every fresh
  edge (levers dead) while the level-triggered wheel keeps
  working, which matches the run-8 symptom split exactly;
  that is a hypothesis, labelled as such. The live
  diagnostic is already on the panel: the DIAG block prints
  each hand's raw GRIP / CLICK / FORCE every 0.2 s — if the
  levers die again, a FORCE or CLICK reading stuck on with
  the hand open names the channel. Stage 11 stands as the
  regression guard for the code side. Smoke 88/88, render
  proofs 69/69.

UNVERIFIED (only headset run 9 proves these): whether the
"certain spots" frame jumps are gone where you felt them —
the staircase above all, which should now hammer as
distinct steps under the wheels without the view snapping;
whether the hump air feels right at cruise — ~1 s flights,
steering dead while you're up, ROUGH-grade landings on the
clean line; whether the prep levers stay alive all session
(the code side is now guarded by smoke stage 11; if they
die again, the DIAG block's per-hand GRIP / CLICK / FORCE
readings are the evidence — note which channel, if any, is
stuck on with your hand open); and the carried opens from
run 8: the body-sink (the Star Wars effect) per-surface
detail, skid usefulness and levels, and the lean tilt at
×1.25.

## Fix Pass 9 (after headset run 9: the levers still dead with the
## panel saying HOLD; "I don't really have a sensation of the car
## turning, it more slides… like the Autopia ride, riding a rail";
## and "the scale isn't right — the original track really dwarfed
## your car")

- **Levers: level-based activation (Item 1).** Run 9 closed the
  hunt Fix Pass 8 opened: the panel's HOLD readout proved grip
  arrived and the hand was in range, yet nothing flipped — the
  flip fired on the grip EDGE inside the zone, and a human hand
  squeezes FIRST and reaches SECOND, spending the edge in empty
  air. (Fix Pass 8's stage 11 posed the hand first and gripped
  second — the inhuman order — so it passed.) Activation is now
  level-based: a gripping hand inside a control's zone fires it
  ONCE per continuous grab-and-zone entry; the latch re-arms on
  grip release or zone exit, and a held grip sweeping from one
  control to the next fires each on entry — squeeze-and-touch
  IS the prep gesture. Stage 11 now covers both human orders:
  grip-first-then-reach (nothing fires in empty air; the flip
  lands on zone entry), a held-grip sweep completing the whole
  sequence, a parked-grip exactly-once probe, plus the original
  pose-then-grip three-dangle run and wrong-order reset.
- **The free-heading model (Item 2).** The spine-slaved model
  is replaced whole. The car owns its heading: the grabbed
  wheel sets a front-wheel angle (±MAX_LOCK_RAD 0.56 rad,
  authority scaled down with speed, 1/(1+(v/26)²)); yaw rate
  follows the bicycle relation ω = v/wheelbase · tan(lock),
  capped at 1.6 rad/s and chased through a first-order lag
  (YAW_TAU 0.16 s — the yaw inertia, the mass in the turn);
  at a standstill the bicycle target is exactly zero, so the
  car cannot rotate on the spot. Velocity is its own world
  vector, decomposed against the heading each frame into
  forward/lateral parts; tire grip bleeds the lateral part
  toward zero proportionally (GRIP_BITE_RATE 7.0/s) up to the
  lateral grip limit (GRIP_LAT_ACCEL 11.0 m/s², ~1.1 g; the
  lean experiment's multiplier, ×0.75–1.28, scales both), the
  bank's gravity feeds the lateral part along the frame side,
  and whatever survives the bleed IS the slip — `slip_state`
  derives from the real lateral velocity, so the skid audio
  sings on honest sliding. The track frame keeps only its
  proper jobs: road height/bank under the wheels (per-wheel
  projection), slope gravity, gap/fall checks, lap logic;
  (s, lat) are re-derived from the car's world position by
  projection every step — nothing integrates them, and the
  heading never comes from the frame. Air discipline is
  preserved: the heading is NOT integrated while airborne.
  Measured on the new model (smoke stage 12): a held wheel on
  a straight turns the heading **13.8°** off the frame while
  the car stays on the ribbon (max |lat| 0.29 m); a hard
  flick at 20 m/s peaks at slip **0.95**; centring the wheel
  recovers in 59 frames, counter-steer in **28**. Through the
  banked sweeper the heading runs a real slip angle against
  the frame (stage 8: max divergence 6.0°, typical 3.3°). And
  the R30 corner at a pinned 24 m/s now honestly saturates
  the tires (slip 1.00, skid gain 1.00): it demands ~19 m/s²
  against ~11 at the tires plus the bank's help — at the
  autopilot's grip-paced ~18 m/s the same corner runs clean.
  The smoke autopilot is a steering driver now (pure pursuit
  on the car's own heading, curvature-capped speed — test
  code only; no self-drive ships). Its full lap measures
  **46.8 s** against the old model's 38.1 s — the difference
  is the driver braking for corners like a driver, not the
  car slowing. Everything above the model re-proves: stage 9's
  geometry steps IMPROVE under it (0.0091 m / 0.214° worst
  outside the staircase; 0.0222 m / 0.823° at it — the FP8
  bounds stand unraised); the climb-top negative control
  still holds by mechanism (min load 0.43 at a pinned
  30 m/s); the humps still give 5 flights, 5.30 s of air,
  heading frozen against a hard-over wheel poke across every
  flight; stage 2g's tremble is 11.1 / 11.5 mm per axle
  (5.4 mm avg, 0.9 mm OFF) with skid slip identical ON vs OFF
  (1.000 vs 1.000 — both saturated at the bank).
- **The edge-straddle save (Item 2, scope addition — Chris:
  "they'd really wobble but you could save it").** Crammond's
  own mechanism, verified in his code (CalculateIfCarOffRoad):
  each wheel's support is independent. Here: every wheel's
  world position projects to the spine each frame; past the
  ribbon edge its support height falls progressively —
  EDGE_SLOPE 0.55 per metre of overshoot — to EDGE_CUTOFF
  1.17 m (¾ of the wheel track), where it is fully
  unsupported; that corner's spring target drops with it, and
  the body rolls toward the dead side through a lagged edge
  roll (the wobble). The whole car falls only when its CENTRE
  overshoot passes 1.95 m — the point where even the
  innermost wheel has lost the shoulder. Stage 13 drives it
  on both edges: at centre overshoot 0.35 m the car holds the
  shoulder line (car_lat 5.09 / −5.20 m) rolled **~26° / ~23°**
  toward the off side, steering back restores the centreline
  and the wobble is gone (roll 0.000); past the cutoff the
  normal fall/drone path engages.
- **Scale (Item 3).** Measured front wheel track: **1.56 m**
  (wheels at x = ±0.78) — so Crammond's 6.0× proportion gives
  a **9.36 m** road (HALF_WIDTH 4.68), not the brief's
  guessed 10.5–11 m: the ratio is the rule, the build's car
  is narrower than the guess. The old 8 m was ~4.4× our
  track — narrow in exactly the proportion the eye reads.
  Off-line audit: the "2.15× multiplier" does not exist in
  the shipped code (the fall rule was a plain
  |car_lat| > HALF_WIDTH); under the straddle that line is
  now HALF_WIDTH + 1.95 m (see above), and hang geometry,
  skirts, edge strips and gantries all derive from
  HALF_WIDTH as before. **The desert:** a 5 km sand floor at
  y = −30 (~60 m below the track datum; the lowest ribbon
  sits ~88 m above it), 8 flat-shaded hills ringing the
  track at 500–900 m, 4 nearer mesas, stilts extended to
  actually land on the floor, the old green placeholder
  blocks removed, fog density 0.00015 → 0.0003 so the hills
  haze into a horizon. The desert is scenery — fall/recovery
  is untouched and the drone still catches the car ~13 m
  below the ribbon. Frame cost is net NEGATIVE: **112 nodes /
  54 draw calls / 28,222 primitives** (was 140 / 65 / 28,354
  — 40 scattered blocks out, 13 large meshes in). New
  captures: `tests/desert_below_view.png` (down past the
  dangling car to the floor) and `tests/desert_wide_view.png`
  (ribbon on stilts, desert, mesas, horizon); capture 1's
  cockpit frame now includes the desert and horizon from the
  seat. Smoke 112/112, API guard 22/22 (no new live-path
  calls), render proofs 73/73. No new commands — the panel
  is unchanged.

UNVERIFIED (only headset run 10 proves these): above all
whether TURNING feels like turning now — the heading is the
car's own, the yaw has inertia, the tires break loose and
recover; whether the levers stay alive in both grip orders
all session; whether the road reads WIDE and the world
dwarfs the car the way the original's screenshot does;
whether the straddle wobble is feelable and the save
satisfying rather than alarming; and everything still
carried: hump air feel at cruise, skid usefulness/levels,
lean tilt at ×1.25, sustained comfort.

## Fix Pass 10 (after headset run 10: the steering landed —
"squirrely is good" — but the left grip channel never fired
a lever in the headset, the drone dropped the car ahead of
its falls like a cheat, the road was too narrow for two
cars, and Chris asked for the mountain: "huge tall ramps,
massive dips, big swinging curves, some straightaways" —
plus a loop-the-loop spur as an experiment)

- **Item 0 — LEVERS.** The audit cleared the map: parsing the
  shipped `openxr_action_map.tres` shows every action the
  game reads already binds BOTH hands in all four
  interaction profiles — the suspected missing left grip
  binding does not exist, and no repair was invented for a
  fault not reproduced. Two real findings: `grip_force` is
  bound NOWHERE (so DIAG's FRC column can never read
  non-zero on this map — harmless; it is one of three OR'd
  grip channels), and the face buttons are asymmetric by
  hardware design (left X/Y vs right A/B). What shipped: a
  static guard in the API suite asserting per-hand binding
  symmetry for the 10 game actions across all 4 profiles;
  dash-control pickup now takes the NEAREST control in
  radius instead of the first match; DIAG gained a ZONE
  line naming which hand is in each control's zone; the
  DIAG board moved up 3.5 cm so the new line clears the
  wheel rim; and the prep test now proves a full prep with
  a simulated DEAD channel on each side (worst reach
  0.83 m against the 0.90 bound). The live left-grip death
  itself was NOT reproduced headless — VDXR remains the
  suspect, and the ZONE line is the instrument that will
  see it next run.
- **Item 1 — DRONE PLACEMENT.** The drop s never exceeds
  the s where the car LEFT the road (`air_start_s`, recorded
  at air entry — previously the drop was computed from the
  end-of-flight estimate, landing the car past obstacles it
  had failed). The walk-back is tiered: a piece that is
  flat, unbanked, gap-free AND has >= 25 m of hazard-free
  run-up (`DROP_MIN_RUNUP_M`), then piece-only, then the
  old relaxed criteria, then s=2. It wraps the circuit
  seam. Stage 16 stages the brief's falls (past both gaps,
  mid-banked-corner, a car length before hump 1, on the
  staircase) plus a live gap fall (fell at 207, dropped at
  57 — the walk-back legitimately crosses a lip, a corner
  and a climb before anything qualifies).
- **Item 2 — PIVOT-DRIVEN DRONE FLIGHT.** The procedural
  dip schedule is retired. The carrier has real flight
  state (position, measured acceleration, yaw, a retrace
  waypoint path); the pendulum integrates the MEASURED
  pivot acceleration; the car's yaw seeks the carrier's
  heading through an underdamped spring (stage 17: a
  target step overshoots 10.6 deg and settles to 0.97 deg —
  lazy, as briefed); flown dips at the dangle are carrier
  manoeuvres whose measured acceleration (-8.1 m/s^2 at
  full depth) fires the line slack through the same
  threshold as any other carrier motion. Release gates
  are unchanged (note: the brief described prep/swing/bank
  gates on release — the code has never had them; nothing
  was added). One number for the owner's eye: the
  production staircase carry excites the pendulum to a
  1.179 rad peak — the physics of a 5.5 m pendulum with
  0.10 damping, not a defect claim either way.
- **Item 3 — WIDTH + THE MOUNTAIN CIRCUIT.** HALF_WIDTH is
  6.0 m (12 m road). The car BODY measures 1.80 m across
  (mesh AABBs, boards excluded), so the road is 6.67
  bodies wide — Crammond's own ratio was ~4.74. The
  circuit: a closed 3,319 m loop (Newton-solved tail,
  closure residual 0.007 m), home straight 380 m, a left
  sweeper (R 244), a dip giving back 63.7 m, a 350 m mid
  straight, a left hairpin (R 108), the signature climb
  (+63.2 m), the 14 m gap and the five-hump row carried
  over, a right return sweeper (R 236), and a closing
  180 deg hairpin. Three laps to the finish at the gantry.
  The circuit is the default track; the purple dash
  button (or V) switches to the ribbon and back. Seam
  geometry steps measure 0.0057 m / 0.013 deg against
  stage 9's 0.014 / 0.35 tiers — the join is invisible to
  the instruments. Frame stats on the circuit: 124 nodes /
  53 draw calls / 57,906 primitives (ribbon: 112 / 54 /
  28,222).
- **Item 4 — THE LOOP SPUR (experiment, landed).** Off the
  home straight at s=170, merging at s=330: diverge,
  descend, a full vertical ring at R=11 m, Bezier exit.
  Frames are parallel-transported; the suspension reads
  the physical load (gravity along the frame up minus
  v^2 kv), so the ring holds at speed, and past vertical
  below sqrt(gR) ~= 10.4 m/s at the top it lets go — the
  car falls inside the ring and the drone recovers it onto
  the main track. Stage 21 drives it: 364 deg of ring
  rotation at 30 m/s, worst orientation step 2.02 deg, and
  the slowed run detaches at spur_s 123, just past the
  top. Full suite: SMOKE 184/184, API guard 69/69. Render proofs 87/87.

UNVERIFIED (only the headset proves these): the left
grip's live behaviour and the ZONE line's testimony about
it; the carried swing's feel at a 1.179 rad peak; whether
the circuit's geography reads as the mountain it measures
as; the spur's legibility at the fork and the ring's feel
from the seat; and everything still carried from run 10.

## Fix Pass 11 (after headset run 11: seat, zones, rake, drone,
## lever, speed — six items, one commit each)

Built in the owner's order where the brief demanded it:
rake geometry first (the seat and zone measurements are
taken on the raked car), speed last (re-derived on the
final car). Every number below is from the suites on the
final tree unless a stage is named.

**Item 6 — rake / big rear tyres (aa705f2).** Rear radius
0.34 → 0.47 m (Ø 0.94), front stays 0.30; widths 0.24 /
0.36. The radius enters through the suspension attach
terms (the (s, lat) support sampling is positional and
radius-free), so the stance is derived: measured body
pitch −3.37° against the atan(0.17/3.0) = 3.24° prediction,
wheel-bottom offset front/rear 0.010 m on one contact
plane, rear tyre AABB Ø 0.99 vs front 0.63 m
(tests/rake_profile_view.png). A deliberate deviation
from Crammond's equal-wheel car, at the owner's direction,
noted in the constants.

**Item 1 — seat (0806d02).** EYE_ANCHOR +0.12 m to
(0, 1.26, 0.05); the wheel hub rose with it (drop 0.29,
forward 0.45). Measured with a per-mesh grazing
construction in the render proof: nearest visible road
20.6 m at the raised seat vs 54.9 m at the old height
(the binding obstruction is the blower's top-front edge).
In-cockpit trim: two hold levers on the left pod
(white SEAT+ front, black SEAT− rear), ±0.15 m at
0.30 m/s, live, shown on the DIAG WHEEL line.
BRIEF/CODE MISMATCH: "persists in the profile" had no
referent — the game had no persistence at all. A minimal
user://settings.cfg now stores seat.trim only.
The anchor yaw cure is ported from the look test: a 25°
cone — automatic anchor applies land translation only
outside it (yaw debt is caught up when the head is stable
and inside the cone); the explicit bake (both-grips
squeeze, also ported, or the stick click) always applies.
Staged in smoke stage 22, including a posed 40° case:
translation applied, eye error 0.000 m, yaw held.

**Item 2 — lever zones are geometry (d494309).** Measured
defects first: the three dash buttons were cylinders
spanning y 0.88..0.92 inside a dash slab topping at
0.93 — fully buried, invisible, firing on proximity
alone; the switch pivots sat at 0.90 with activation
segments starting below the surface (the run-11 "sweet
spot inside the console"). Fixes: pivots on the surface
(0.93), buttons on it (0.95), every segment now runs
along its visible handle (+0.02 → cap centre).
debug_dash_ctl_audit() is PERMANENT (smoke stage 23 +
the render proof's pose): segment samples within
0.035 m of the control's own meshes and inside no other
car mesh. Measured: 0 violations, worst deviation
0.000 m. tests/zone_overlay_view.png draws every zone
over its control.

**Item 3 — drone approach (09a174a).** The carrier faced
its velocity for the whole carry; a walk-back's velocity
points back along the track, so it arrived ~180° from
the drop heading and spun at the station. Now the yaw
goal is the drop heading from the final approach (last
waypoint or < 45 m), and the carry→dangle transition
has a yaw gate (< 0.08 rad, bounded by a 3 s station
wait so a short leg degrades, never sticks). Pendulum
and walk-back tiers untouched. Stage 24 stages the
owner's case (circuit s 900, drop 158 m behind): max
yaw error mid-carry 180°, error at the dangle 0.0°,
aligned 30 frames before arrival.

**Item 4 — the drop lever (b30fae1).** Big lever on the
right pod (0.50 m shaft, red knob) at (0.72, 0.71, −0.10),
0.80 m from the hub — outside the wheel-grab radius,
overlapping no dash zone. Grip near the upper shaft
latches it; it follows the hand's arc angle (rest −0.30,
detent +0.40, max +0.65 rad); past the detent the release
fires once per pull with a haptic pulse on the pulling
hand (XRInterface.trigger_haptic_pulse via the existing
"haptic" action, API-guarded, null-safe). Early grip
release: springs home at 3.5 rad/s, no drop. The XR
trigger release is retired — the panel names the lever;
SPACE/test hooks remain the desktop path. The lever is
inside Item 2's audit (rest and full throw) and the DIAG
ZONE line (DRP:). Stage 25 stages latch / follow /
detent-drop / spring-home through _poll_grab.
tests/drop_lever_view.png: the lever mid-pull.

**Item 5 — speed (8f910b6).** TOP_SPEED 34 → 48 m/s
(173 km/h on the panel). Engine/brake/drag unchanged.
Stage 26, standing start on the circuit's opening
straight: vmax = the 48.0 clamp, 0→45 in 6.0 s,
0→24 in 2.0 s. Steering re-derived via a shared
_lock_scale(): at ≤ 24 m/s it is the FP10 expression
verbatim (stage 26 asserts float equality at
0/6/12/18/24); above, the falloff blends 26 → 40 across
24..40: lock 0.507 @30, 0.523 @34, 0.518 @38, 0.410 @48
(old extrapolation: 0.227). Engine pitch renormalised
(settled 1.99 @ pin 34, 2.57 @ pin 48). Humps at pin 48:
the car flies and lands throughout, no drone call —
fresh car 31 flights, longest 1.7 s; in-suite, after 25
stages of accumulated state, 50 short hops. NO hump
re-tune: the evidence does not force one, and the call
is recorded here rather than buried. Gaps cross at the
raised envelope (stage 20 on autopilot_fast); stage 19's
three laps complete in 19,119 frames; stage 9 and the
other calibrated fixtures keep the 34 cap. Optic flow:
edge strips dashed 3 m on / 2 m off (both tracks + spur),
no FOV tricks — and frame cost fell: 55,510 prims vs
60,754 at the pass baseline (137 nodes / 57 draws).

Suites on the final tree: SMOKE 224/224, API guard
70/70, render proof 106/106.

Brief/code mismatches found this pass (2): the profile
that did not exist (Item 1, above), and Item 6's "radius
in suspension sampling" — sampling is positional; the
radius enters via attach/ride-height and the meshes.
Item 2 also surfaced a fact the brief did not state:
the FP10 buttons were wholly inside the dash slab.

UNVERIFIED (only the headset proves these): the raised
seat's sightline and the trim levers' ergonomics in the
headset; whether the anchor yaw cure and the both-grips
recenter behave on the live rig (the stability-gate chain
is staged headless only); lever-zone feel against the
new geometry; the drop lever's throw, detent and whether
the haptic pulse is perceptible at all; the drone's
approach as seen from the dangle; whether 48 m/s FEELS
fast (the dashes are the one lever pulled — the sensation
itself is the owner's verdict); the hump row at 48 in the
stomach, not the log; and everything still carried from
run 11 (his FP10 circuit and loop verdicts were still
open when this pass was briefed).

## Fix Pass 12 (after headset run 12: the drop lever works
## but sits too far back, the boards block the road, the
## drone is "still nuts and slow", road goes invisible in
## the dips, a jump snatches the car into the drone, and
## the loop entrance reads wrong — six items, one commit
## each, plus this README + the pass's proof captures)

Run 12 also said the feel is starting to happen ("i
barely saved tires on edge and it felt like i was
fighting a bit") while the car still reads light overall
— the mass/tune pass stays queued behind this one.
Every number below is from the suites on the final tree
unless a stage is named.

**Item 1 — the drop lever becomes a gear shifter
(a13b240).** Chris: "too far back of player seating,
should be moved forward, shortened by 1/3, more like a
gear shift." Pivot (0.72, 0.71, −0.10) → (0.72, 0.71,
−0.60), right pod forward beside the wheel; shaft
0.50 → 0.33 m; knob at the new top. The mechanism is
untouched — rest −0.30 / detent +0.40 / max +0.65 rad,
per-hand latch, hand-arc follow (shaft-length
independent), spring home 3.5 rad/s, haptic. Clearances:
rest knob 0.78 m from the wheel hub (grab radius 0.40),
0.21 m from the TRK button (zone 0.15). Stage 23's
geometric zone audit re-ran clean with the shifter in
place (0 violations, worst deviation 0.000 m); stage 25
re-proves the mechanics; the stage-25 grab segment is now
asserted at its new length (0.19 m).

**Item 2 — info boards hidden by default (06052e1).**
Chris: "Need to do something about the big panels, hard
to see. Button calls them up, makes em go away." New
panels_visible (default false, session-only) and the one
switch _toggle_panels(); both board roots build hidden.
Right-controller B is remapped from lean to the panel
toggle (desktop Tab does the same) — lean keeps its
green dash button and the desktop T key, and the panel's
own controls list never listed B for lean, so nothing
the panel promises was taken away. Content keeps
refreshing while hidden (stage 27 drives the real Tab
input path both ways and asserts it); state/prep mid-view
banners are not panels and are untouched. Growth
control: the panel text gained lines (Item 1's shifter
line, the Panels line) and was trimmed by two elsewhere,
and the type drops ~9% (pixel_size 0.00115 → 0.00105) —
the grown list measured 1.30 m tall against a 1.24 m
board with 3 of 63 sightlines blocked by cockpit
geometry; it fits now, 0 blocked. Proof capture 1 is
shot boards-hidden, the spawn state.

**Item 3 — drone clearance profile + speed (885255a).**
Chris: "Drone still nuts and slow. Flies through road
and pylon a lot" (and he quit mid-carry, run 10's
frustration signature). CARRIER_SPEED 9 → 15 m/s,
CARRIER_ACCEL 6 → 9. The path flies a collision-free
altitude profile: route sampled every 5 m, each waypoint
at the highest road surface within ±45 m of route travel
+ hang stack (HANG_LEN 5.5 + HANG_CLEAR 1.2) + 1.0 m —
the window and margin grew from a first form of ±30 m /
0.8 m after a staged carry measured a 0.17 m graze (the
swinging car reaches metres past the anchor's column,
where the road stands higher than the window max). A
climb-out waypoint takes deep catches straight up to
profile altitude first; a penultimate waypoint flies the
last 15 m at profile altitude; anchor_target itself is
untouched. Two defects found by tracing the carry, not
by staring at constants: (1) waypoint samples now stop
20 m short of the drop — at back_dist 158 the last 30 m
sample landed PAST the penultimate and the path doubled
back on itself twice at the station; waypoint advance
also fires on passing abeam now. (2) The arrival flare
ships as a braking-curve speed cap, |v| ≤ sqrt(2·5·d) —
an instrumented run convicted the plain full-limit
braking first (release at pendulum om_l −2.65 rad/s,
≈14 m/s tip velocity, car missed the road: the stage 11c
regression), and the flare's first form (an accel cap)
then rang ~18 s against the P-law at the station;
the braking curve cannot overshoot it. Timings, staged:
s900 walk-back FP11 1911 → FP12 1482–1559 frames
end-to-end; climb-top walk-back 2901 → 1990. Stage 28
asserts the carried car intersects neither ribbon nor
stilt on three staged carries (walk-back, hump-span
crossing, gap-fall return): route hits 0, case H minimum
clearance +0.74 m. Two bounded brushes are counted and
printed, NOT asserted away: the station settle (within
10 m plan of the drop, the still-swinging car's low AABB
corner brushes the road plane, worst depth ~0.17 m for
~0.4 s) and the gap fall-site cell (the catch wedges the
car ~4.7 m BELOW the far lip's surface at its plan
position, where the lip's own stilt stands — any
extraction crosses that one cell; a lateral-dodge
experiment did not clear it, 36 stilt + 175 ribbon hits.
Documented wart, not claimed fixed; a lateral stilt-
dodge manoeuvre is the named future fix). Stage 24's
FP11 approach proof still passes at the new rates
(arrives aligned, 0.0° yaw error). Item 5's trigger
constants ride in this commit's const block (one hunk);
Item 5's logic is its own commit.

**Item 4 — road visibility: diagnosed, then fixed
(e3a524f).** Chris: "Part of road is invisible till
you're in it." Diagnosis first, per the brief: NOT
pop-in — the track is 4 merged meshes per track, no
chunking, visibility ranges open; ID-pass renders
(magenta swap) prove the ribbon is on screen at every
station (27k–36k px). NOT the far plane (4000). The
cause is a low-contrast wash at the dip/valley
sightlines: fog mixing the near-black surface toward the
horizon colour over 0.6–2.5 km sight distances, plus
thin-geometry aliasing (0.36 m dashed edges ≈1 px at
300–600 m). Measured as the ribbon fraction within
0.10 RGB of local background: dip_floor 14.1%,
before_dip 8.7%, against 1.9–4.8% at healthy stations.
Fix: fog_density 0.0003 → 0.00012, and the edge strips —
the far read — widen 0.36 → 0.55 m (EDGE_STRIP_W).
After, same frozen protocol: dip_floor 4.3%,
before_dip 3.3%, loop_approach 1.6%, home_straight 0.0%,
climb_top 4.6%, climb_mid 4.3%. mid_straight is UNMOVED
(12.8% → 12.5%) — its wash is not fog; it reads as
thin-geometry/raster blending and is stated here, not
claimed fixed. MSAA was considered and deferred
(project-wide rendering change, Quest-perf implications
— out of this pass's scope). The proof gains a standing
dip-valley capture (dip_valley_view.png).

**Item 5 — the jump snatch: trigger convicted, rebuilt
positional (b278505).** Chris: "A jump seems to find you
suddenly being carried by drone." Convicted: the old
trigger's bare air_time > 2.4 term in _update_air.
Staged at 48 m/s with production _enter_air: a climb-top
launch (s 2125, rebound 2.0) was SNATCHED at 2.41 s
while its counterfactual ballistic LANDS 1.23 s later at
s 2303, lat 0.0 — honest flight 3.64 s total. The
dip-lip flight (s 735) lands at 2.32 s, 0.08 s from the
same fate; the gap crosses cleanly at 1.66 s; the
h < −13 term produced no false positives. The new rule
(landing test unchanged) fires recovery only on: (a)
h < −13 (unchanged); (b) h < −2.2 AND descending, held
continuously AIR_LOST_BELOW_T = 0.3 s (below_band_t,
reset whenever the car is back in band or ascending —
a lower piece ahead re-opens the landing); (d) the
lateral exit — |lat| > HALF_WIDTH + 2.5 AND below the
EXIT plane captured at launch (air_exit_y), same 0.3 s
dwell — added on measurement: a staged lateral lip exit
took 2.90 s to declare on rule (b) alone, because
spine-relative h is masked by the plunging road's own
descent; a car 8.5 m off the centreline below its exit
plane has no air control and cannot return, so with (d)
it declares at 0.87 s; (c) AIR_FAILSAFE_T = 8.0 s
absolute ceiling. Stage 29 stages all three: climb-top
LANDS after 3.68 s, dip-lip LANDS after 2.32 s, lateral
exit drones at 0.87 s. The brief's alternative — if the
trigger proves honest, add the minimal missing
presentational beat — does NOT apply: the trigger was
not honest, no beat was added; the trigger itself was
the dishonesty.

**Item 6 — loop entrance presentation + merge (a11d601).**
Chris: "It SEEMS the entrance is wrong, I'd have to do a
U-Turn. But I havent completed a circuit yet so I dont
know for sure." The audit (research/loop-entry-audit/)
found no U-turn — entry joint clean (heading step
0.47°) — and three presentation defects plus one real
geometry defect; Chris approved all four garnishes.
MERGE (the real defect): the exit leg's last 40 m of
points is blended onto the surveyed merge line,
smoothstep weight reaching full at 15 m out, applied
after the smoothing passes and before tangents.
Residual −2.54° → 0.00°; last-12 m unwind peak
3.45°/m → 0.00°/m (stage 29; entry side ≤ 1.00°/m). A
first, weaker blend (30 m, full weight only at the join)
zeroed the residual but left 3.79°/m of unwind in-suite
— strengthened to the shipped form. GUIDE STRIP: amber
unshaded 0.55 m strip on the main road, s 160–212,
centred until s 170 then easing to −3.4 m down the
capture corridor — the mouth the audit found missing.
As first built it was culled from every view (corner
order faced DOWN; convicted by render experiment —
12,568 px with culling off, 0 with it on); the mirrored
order ships and reads in the 20 m approach frame as an
amber thread curving left to the ring's mouth (61
sampled px in the road band; the spur's own dashed edge
strips, a similar amber, were the false lead chased
first). GANTRY at s 158, beam + "LOOP" — the beam reads
clearly in the 20 m approach frame; the text itself is
not legible at that distance in llvmpipe stills. RING
RIM BAND: the ring's underside segments painted bright
amber (1.0, 0.58, 0.06; 414 verts, stage 29) with
continuous amber underside edge strips 2 cm proud — the
ring now presents a lit face instead of its black back.
DESCENT CHEVRONS: unshaded arrow pairs at spur_s
44–84 — the entry leg's dive from y 60 to the ring base
at 52.5 (that dive IS the brief's descent leg) — wings
±2.4 m, stroke half-width 0.45 m. They had the guide
strip's winding bug: the pixel count sat at a constant
117 px through three size increases (only the far pair,
where the chute's roll tips the culled side toward the
camera) before the census convicted it; mirrored, they
read at 722 px with a proper Λ in spur_descent_view.png.
The size stayed motorway-scale — it suits 48 m/s. The
capture-rule comment is corrected 1.3 m → 1.2 m (comment
only; the rule was always 1.2). Proof: driver-POV
approach series at 100/50/20 m, boards hidden — its
staging parks the car at each station after start_race()
(earlier captures left it rolling driverless, or sitting
on the spur from a prior capture, and photographed a
recovery dangle instead of the approach). Stage 21's
loop proofs re-pass (ring turns the car ~365°).

Suites on the final tree: SMOKE 246/246, API guard
70/70, render proof 125/125.

Brief/code mismatches and Hal's own errors found this
pass (4): the capture-rule comment said 1.3 m where the
code (and the audit) said 1.2 (Item 6, comment fixed);
stage 28's first version forgot to reselect the circuit
after stage 26 leaves the test ribbon active and
measured ribbon recoveries — Hal's staging bug, caught
by the numbers not matching the diag harness, fixed in
both the staged case and case G; Item 3's const block
carries Item 5's two trigger constants (one hunk, noted
in both commit messages); and git apply in this sandbox
proved unable to match patch context against a shifted
index (it applied Item 1 to the pristine tree, then
rejected byte-identical context for Item 2, as did GNU
patch) — Items 2–6 were therefore staged by blob
reconstruction from the item-split diffs, and every
commit's blobs were verified equal to the computed
per-item tree states before committing (state 1
reproduces Item 1's commit exactly; state 6 equals the
suite-green working tree).

UNVERIFIED (only the headset proves these): the
shifter's ergonomics and feel at the new forward spot;
the R B edge in the live XR input path (code-reviewed
and stage-tested through _toggle_panels()/Tab — the live
by_button value path is XR-only); drone feel at 15 m/s
cruise and the arrival swing in the headset; whether the
station-settle brush and the gap fall-site brush are
even visible as events from the cockpit; the far read of
the road in the headset against llvmpipe captures
(Item 4 was measured by pixel statistics, not by eye —
and mid_straight's residual wash is unfixed); guide
strip / gantry / rim / chevron legibility at headset
resolution and in motion, including the "LOOP" gantry
text; whether the loop entrance now READS right at
speed (the original complaint was presentational —
garnishes built, the owner's eye decides); and the
loop's feel/stomach verdict, still owed from run 10.

## Fix Pass 13 (after headset run 13: the prep levers
## are broken live and their meshes never move, the
## drop lever's pod spot is rejected, the drop control
## cross-talks into view resets, the wheel can't be
## grabbed before the drop, A/X exert "weird influence"
## in the dangle, and "the drone remains a nightmare" —
## six items, one commit each, plus this README + the
## pass's proof captures)

Run 13's decisions, taken before the build: PREP IS
DELETED (the owner: "how fast you can get going should
be dependent on how well your wheels connect on impact,
which is judged from the drone sway" — the 2026-10-26
"good prep = boost" reward is superseded; the rationed
on-track boost is untouched), and the drone is SPLIT —
travel and hang become separate modes with separate
rules. Every number below is from the suites on the
final tree unless a stage is named.

**Item 1 — prep deleted; touchdown connection is the
drop reward (364eeb3).** The whole prep machine is out:
the FUEL/SPARK/BOOST switches, their state, meshes,
desktop 1/2/3 keys, panel lines, the DIAG prep line and
the release-time boost gate. The dash control set is
now exactly [restart, lean, track, seatup, seatdn]. The
brief's code-verification questions, answered from
_do_release/_land: (a) lateral velocity at contact is
inherited IN FULL (pendulum tip velocity → air velocity
→ the velocity the ground model decomposes at
touchdown); (b) heading error at a settled dangle is
~0° — the swing hands over a VELOCITY error, not a
heading error; (c) per-wheel contact timing DOES NOT
EXIST — landing is a single event at the car centre,
and attitude enters only through the misalign term in
the landing grade. So the connection is graded and
priced where the model actually keeps it: _land now
records the contact lateral speed and heading error and
grades CLEAN (≤1.0 m/s, ≤3°) / SCRUBBED (≤3.0, ≤8°) /
CROSSED-UP, shown on the drop readout for 2.5 s
("TOUCHDOWN CLEAN — LAT 0.0 M/S, HDG −0.1 DEG") and on
the DIAG board's CONTACT line. Tuning, contact path
only (steering ≤24 m/s is bit-identical — stage 26):
the 4 m/s landing floor now tops up only FORWARD
contacts (a backward-crossed touchdown at −1.4 m/s is
no longer gifted forward pace); during the contact
transient the engine force is capped by a combined-slip
ellipse against the lateral budget the bleed is
spending; and a load ramp (floor 0.10 → 1.0 over
0.65 s) scales both the bleed and the cap while the
suspension "loads" — with _bleed_time now integrating
the same load factor it predicts. Getaway, Drop Start,
touchdown → 20 m/s, staged releases (stage 30): before
this tuning the spread was ~0.01 s (the floor and the
uncapped engine erased the connection entirely); after:
CLEAN release (no swing) **1.82 s**; the Drop-Start
seed swing (lat 2.25 m/s at contact, SCRUBBED)
**2.61 s**; sway-peak release (lat 5.21, CROSSED-UP)
**3.42 s** — spread **1.60 s** against the brief's 1.5
target. Two honest notes: the spur driver does NOT get
the ellipse cap (it is a separate tuned system; the cap
lives on the ribbon/circuit drive path), and stage 30's
staging had to learn to wait for the car's facing to
settle and re-pose at the plumb point before release —
zeroing the swing state alone left the car falling from
its last mid-swing pose, an artifact worth up to 5.6 m
of landing offset that briefly masqueraded as tuning
signal.

**Item 2 — the drop lever moves to the centre dash,
vertical throw (653e36f).** The owner rejected the pod
spot outright: centre of dash, straight up/down. The
FP11 pod lever and the FP12 shifter are gone; one lever
now stands on a bracket at car_body (0, 0.88, −0.70),
shaft straight up at rest (0.0 rad), detent +0.50, max
+0.70. Direction (the brief specified the throw, not
the sense): pull DOWN toward the driver, through the
detent — the crane-release pull; up is home, spring
3.5 rad/s. Grab radius 0.16, staged grab segment
0.19 m. The lean needle moved left to x −0.18 to clear
the lever's arc. Stage 23's zone audit re-ran at the
new geometry: 0 violations, worst handle deviation
0.000 m; stage 25 re-proves latch/arc/spring on the new
pivot. New capture: dash_top_view (the post-prep dash
from above); drop_lever_view reframed on the centre
lever.

**Item 3 — the wheel is grabbable in the dangle
(6930894).** Run 13: the steering had to be settable
before the drop, not discovered after it. In the
dangle the wheel now latches like the lever does (the
transport does NOT arm it — Item 6's nothing-arms
rule), with strict hand mutual exclusion against the
drop lever. The wheel has NO yaw authority while
hanging (nothing reads it there); the dialled lock
simply persists into the release, and the front road
wheels now SHOW the steer angle (they take the drive
model's own fa_vis; the rears never yaw) so the setting
is visible from the seat. Stage 31: 0.60 rad dialled in
the dangle, wheels at −6.1°, lock intact after the grip
opens, and the first DRIVE frames steer by it. The
stage also convicted a real production bug: the
desktop return-to-centre ran in every mode and silently
erased a dangle-dialled lock during the fall — centring
is DRIVE-only now.

**Item 4 — hang button gate + live input logging
(1fe3473).** Button handling now lives in one handler
(_poll_xr_buttons, states resolved through _btn_state
so the suite can drive the production path). In
MODE_HANG: left Y restart needs a 0.8 s long-press (a
tap does nothing; in DRIVE/DONE the edge fires as
before); right A is inert and latches boost_arm_blocked
until A is seen released, so a button mashed through
the drop can never become a boost on the ground; left X
unchanged (DRIVE-only drone call, inert in the hang);
right B panel toggle stays live in every mode —
deliberate, it is the owner's window control. The
both-grips recenter is gated by _recenter_allowed():
never in the hang, never while the drop lever, wheel or
a seat trim is latched or held (stick-click recenter is
never gated). Every face-button edge in the hang is
logged to the DIAG board's BTN line (last 6, racetime
tags). Root cause for the run-13 "weird influence on
the chains": the pendulum reads NO player input at
all — what the owner felt was the ungated Y restarting
the run mid-sway and the both-grips recenter sweeping
the view; both are gated now, and stage 32 proves the
whole set headless, the X-in-hang and long-press cases
included.

**Item 5 — every control that actuates also articulates
(5f9b166).** Run 13: the trim lever meshes never moved.
The audit, control by control: drop lever swings and
springs (and Item 2 re-sited it); the wheel spins and
the front wheels show the steer (Item 3); the seat
trim levers now deflect ±18° from their −20° rest at
240°/s while the trim is held — by a gripping hand or
by PgUp/PgDn — and spring home on release; every other
dash button dips 8 mm while a gripping hand holds it
fired (a momentary button's remaining feedback is its
visible effect: needle, boards, world). Stage 33 drives
it through the production grab path: SEAT+ held → lever
at −2.0° and the trim moving; released → back at −20°;
LEAN dipped exactly 0.0080 m and returned flush.

**Item 6 — drone split: fast direct transport, slow
hang (75739df).** Travel and hang are separate modes
now. TRANSPORT flies a DIRECT route — climb-out above
the catch if needed, then a straight cruise to above
the station — at a route altitude computed from the
track itself (highest spine surface within 45 m in
plan of the chord + HANG_LEN 5.5 + HANG_CLEAR 1.2 +
1.0 m margin); the FP10/FP12 retrace-the-circuit
routing is deleted. Cruise 15 → 26 m/s, accel 9 → 10.
One fix mattered more than the speed: FP12's braking
curve (decel 5, kept per the brief) previously guarded
only the final approach leg, so the carrier crossed
the last route point at 11+ m/s and overshot the
station by ~5 m with the car swinging into the road
beside it (stage 28 measured 4 hits, −4.21 m worst
clearance, ~1700–1830 frames a recovery); the curve now
guards the whole approach and the measured overshoot
is 0.00 m. The Drop Start is now a PICKUP, not a
summon: the car starts on the ground beside the start
line and the carrier collects it — race start and
recovery are one machinery, and nothing (lever, wheel)
arms during transport (stage 34 asserts it). Numbers,
catch → dangle, end to end: Drop Start pickup **4.6 s**;
fall A (circuit s900 → drop s742) **16.0 s** — against
FP11's 1911 frames (21.2 s) for the same recovery and
FP12's 1482–1559 frames for its carry portion ALONE;
fall B (hairpin s3279 → s2975) **13.9 s**; the hump-span
case runs 1711 frames with 0 hits, 0 station brush and
+1.07 m worst car-floor clearance (fall A: +0.85 m).
The pendulum state is continuous across the
carry→dangle handover (measured jump 0.035 rad), and in
the hang the carrier keeps FP12's station-keeping and
sway exactly — slow was never the hang's problem. Where
the remaining seconds live, plainly: the arrival flare
and gate the brief told this pass to keep (braking
decel ~5, the ≤0.08 rad yaw gate) — long recoveries are
still ~14–16 s, and neither the speed nor the flare was
pushed past the brief to hide that.

Suites on the final tree: SMOKE 285/285, API guard
70/70, render proof 127/127. Frame stats (boot frame):
134 nodes / 41 draw calls / 49,682 primitives (FP12
closed at 137 / 57 on its circuit frame).

Brief/code mismatches and findings this pass (4): (1)
Item 1's question (c) — per-wheel contact timing does
not exist in this model; the connection is priced at
the single centre event instead (above). (2) The spur
driver does not carry the contact ellipse cap — the
brief scoped tuning to the contact path and the spur
is a separate tuned system; recorded, not hidden.
(3) The render proof's FP12 approach series was
mis-staged: its "20 m" frame was snapped with the car
still in the Drop Start dangle (the frame's own state
label reads PREP), and from a genuinely parked s 150
the guide strip — which starts at s 160, past the
gantry and over the entry crest — does not read
(2 sampled px). The proof now stations that frame at
s 168, where the strip reads clearly (~70 sampled px);
whether the entrance reads at DRIVING speed is the
owner's headset call, and the strip itself is unchanged
since FP12. (4) Hunk entanglement in the per-item
commits: _poll_grab and the button handler carry
neighbouring items' lines where the code interleaves
(each commit names its item; the six commits together
reproduce the suite-green tree exactly, verified by an
empty final diff).

UNVERIFIED (only the headset proves these): the centre
lever's ergonomics — reach, throw direction feel, the
detent at +0.50 — and whether pull-down reads as
"release" in the hand; the touchdown grades as FELT
(whether a SCRUBBED getaway is information or noise,
and whether 1.6 s of sway-priced spread is the right
price); the wheel dial in the dangle with live hand
tracking (headless stages prove the latch logic on
synthetic grips only); whether the hang gates end the
cross-talk the owner felt, and whether the BTN log
catches the next weird input live; seat lever deflection
and button dip as seen in the headset; transport at
26 m/s watched from the ground and the dangle — the
split's whole point is that travel should feel like a
machine fetching the car, and the hang like hanging;
and whether 14–16 s is now short enough, or the kept
flare has to go back on the table.

## Fix Pass 14 — the Tune Pass (rebound, settle, per-wheel, grip, view A/B)

Eight items staged against the original's film study
(`research/original-feel-notes.md`, §10). All numbers below are
before → after, measured by the smoke stages cited (the suite
is deterministic; the measurement harness reproduced the stage
numbers exactly wherever both ran).

**Item 1 — Rebound landings (energy-gated).** The film: every
big jump lands and rebounds into a second flight ~½–⅔ the
first; the original never sticks a big landing. Before: the
gap flight went 0.98 s → 0.24 s contact → 0.28 s (0.29×).
After: a landing at impact vy ≥ `REBOUND_GATE_VY` 4.5 m/s arms
a one-shot return — the springs, compressed deeper than
`REBOUND_RETURN_DEPTH` 0.24 m, work at `REBOUND_RETURN_K_MULT`
3.0× stiffness with damping halved, and the throw caps at
`REBOUND_THROW_FRAC` 0.62 of impact (cap `REBOUND_THROW_CAP`
6.2 m/s). Circuit gap at 33 m/s: flight 1.20 s → 0.11 s
contact → 0.52–0.59 s (0.43–0.49×, stage 35). A rebound's own
landing never re-arms (chain guard, 0.5 s settled reset), and
drone drops never arm at any sway — the Drop Start keeps its
FP13 behaviour exactly (stage 30 re-verified below).

**Item 2 — One-bounce settle.** The overshoot was a damping
problem, not a stiffness problem: `SUSP_DAMP` 4.6 → 11.0
(ζ 0.18 → ~0.44), stiffness untouched. Parked 0.30 m poke:
4 overshoots / 2.18 s settle / return slamming to full droop
(0.000 m) → 1 overshoot / 0.77 s / min compression 0.049 m
(stage 36 stages the gentler 0.20 poke: 0–1 overshoots,
13–69 frames). Two mechanism couplings surfaced: the spring
throw route fired at full droop, which the damped ring never
reaches — it now fires mid-stroke (mean c ≤ 0.16, extension
velocity sum < −1.6, deep-hit ≥ 0.22 m within 0.5 s, chain
guard as Item 1); and the landing window's `air_vel.y < 2.5`
bound re-landed the mid-stroke throw on its first tick —
now < 0.5. The staged hop off a poke reads 0.09 m (base
0.16 m — the damped model's honest bounce).

**Stage 30 re-derivation (Item 2's cost, stated plainly).**
FP13's getaway spread floor (1.5 s) was measured when the
CLEAN drop could not bounce (the old throw needed a droop
slam a flat landing never reaches) while tilted sway
landings could. The film (§4) gives every drop one soft
bounce, so the clean getaway now spends 22 frames airborne:
t20 1.82 → 2.09 s, spread 1.60 → 1.29 s, floor re-derived
to 1.25 s. The sway cases match FP13 to 0.04 s and the
grades are untouched. Stage 26's 34 m/s pitch tolerance
widened 0.12 → 0.18 for the same reason (the drop bounce
puts ~0.3 s of its settle window airborne).

**Item 3 — Per-wheel suspension and view.** Sampling was
per-wheel since FP9 but integration averaged each axle.
Now `susp_c`/`susp_cv`/`susp_geom` are per-corner; `c_f`/`c_r`
survive as the means. Body attitude derives from the four
corner attach heights (heave = mean, pitch = front/rear,
roll = right/left), replacing the separate lagged
rise-difference roll channel — the springs are the lag now.
Diagonal step-edge crossing: the leading front corner
extends 2 frames before the trailing one (square control:
0 — the phase is small because the crest load channel is
per-axle; the rise channel carries it). Straddle: off-side
corners 0.000/0.000 at full droop while the held side
carries at 0.080/0.089 — a state the axle model could not
represent; body roll −18.3°, view roll −0.191 rad (stage 37).

**Item 4 — The crest drumbeat at 48 m/s: NOT ACHIEVED, and
not a mechanism defect.** Census (stage 38): hump row at a
pinned 48 — flights 1.67 s (vy0 7.4) and 2.16 s (vy0 11.3);
at 32 — five flights of 1.19–1.29 s (vy0 ~5.0); at 20 — no
separation at all (min load 0.14 > threshold). In the film's
0.1–0.4 s band: zero, at every speed. The row's vertical
curvature peaks at kv 0.021/m with ±15° slopes; separation
(v²·kv crossing g) happens on the hump's face where the
slope is already near peak, so vy0 = v·sin(φ_sep) is
5–11 m/s. A 0.1–0.4 s hop at 48 needs vy0 ≤ 2 m/s — slopes
≤ ~2.4° at separation, humps ~6× gentler (kv ~ 0.006).
Producing the drumbeat means re-profiling the track, a
design call; no hops are scripted. The sweeper-exit unload
is likewise only half the film's story in this model: first
unload frames FL 284 / FR 284 / RL 304 / RR 304 — the front
axle lets go ~20 frames before the rear (wheelbase phase),
but left and right go together. The crest load is a
per-axle scalar from the centreline kv; the ribbon frame
carries no per-side vertical curvature, so the film's
downhill-side-first unload is **not expressible** here. The
identified extension — per-wheel kv sampled at each wheel's
own (s, lat) — is recorded in stage 38's comment.

**Item 5 — Grip follows load.** The lateral bleed (rate
7.0/s, cap 11.0) now scales by `load_grip`: the mean axle
road load raised to `GRIP_LOAD_EXP` 0.35 — tire load
sensitivity, sublinear so the factor holds ~1.0 near full
load — floored at 0.15, capped at 1.15. During the FP13
contact transient the factor is not applied (the transient's
own ramp owns the load story there). Crest flick at 24
(harness protocol): the factor floors at 0.15 mid-flick;
the slide arrives at the landing at **2.32 m/s** (base
1.81). Flat flick at 20 (stage 12b): 28 counter-steered /
59 centred at base → **30 / 66**. The drift is the road's
own confession: the "flat" home straight is a kv 0.006
shallow crest whose load at 20 m/s is already 0.75.
Stage 39 stages the persistence pair directly: the flat
flick at 24 bleeds out in 75 frames (slide −4.75 m/s);
the crest flick, factor min 0.37 in suite staging, builds
−6.41 m/s and needs 98 frames (+31%) — and in the
settled-entry harness run, whose car separates mid-flick,
the slide lands aboard at the 2.32 above and takes 170
frames against the flat's 89, the airborne slide unable
to bleed at all. (Suite staging note, recorded in the
stage: from the suite's history the flick's own scrub and
the hump-face slope gravity pull the speed ~0.5 m/s under
the separation line mid-flick, so the suite's car stays
grounded — the grounded face of the same law.)
Rejected carriers, on measurements: corner compression
(36 / 87 — compression sags under slide geometry while the
true load factor stays 1.00); a linear axle-load factor
(34 / 79); support-weighted corners (79 / 34 — a flick
recovery slides a front wheel past the support cutoff and
zeroes its share); exponent 0.5 (31 / 69). R30 corner
still cannot be taken at 24 (stage 12's saturation
asserts hold).

**Observed, out of scope:** at a pinned 40 m/s the
descent-entry crest produces a micro-bounce limit cycle
(sub-second 1-frame air entries on the landing window over
a steepening slope). Pre-existing, Item-1-independent
(the gate needs vy ≥ 4.5; these never arm), left for a
future pass rather than bundled here.

**Item 6 — View-coupling A/B.** Chris's standing question
— the original's camera *is* the car; ours passed 0.6× of
the spring pitch — is now a switch he flips himself:
amber VIEW button on the dash (registered last, index 5,
so no existing control moves), G key on desktop, DIAG
WHEEL line reads VIEW A / VIEW B. A = 0.6× (the shipped
feel; boot default every session — the mode is never
persisted), B = 1.0× (camera = car). The gain scales the
seat's pitch and corner-roll channels together; the heave
channel and the FP6 body-spring layer are not scaled in
either mode. The view path holds **no lag or smoothing
state** — the offsets are pure functions of the current
physics state — so B's added lag over A is zero frames by
construction; only amplitude changes. Stage 40 asserts
the ratio on live samples both ways: view pitch = gain ×
pitch_extra over the hump row (worst error 0.0000 rad in
both modes), view roll = gain × body roll on the held
straddle (B: −0.426 vs −0.426 rad; A: −0.199 vs
0.6 × −0.331), both toggle paths, both DIAG tags. His
pick between A and B is a run-14 verdict; the default
stays A until he says otherwise.

**Item 7 — Guards, and flight attitude.** The guards
first, both green: on the flat (stage 41, the harness
protocol verbatim — home straight, pin 30, unsteered,
jitter off, springs poked to rest) the view heave p2p is
**0.11 mm** (base harness 0.7–1.9 mm) and the heading's
max deviation from its mean is **0.0000°** — Items 1–6
bought no flat-road noise, and nothing manufactures yaw.
The attitude itself: at base the car's basis was *frozen*
at the takeoff pitch through a flight (the +10° lip
against the −3.4° landing slope, verbatim). Now the
nose-down pitch builds quadratically from the takeoff
basis — −½ × 0.349 rad/s² × t², capped at 0.489 rad —
applied absolutely each airborne frame, so there is no
integration drift to unwind, and `_land` reads the built
basis for its tilt ruling: a slope-matched arrival grades
like one. Circuit gap at 33: pitch **+9.74° → −3.61°**
(13.35° of build over the 105-frame flight; the law
predicts 13.7°) against a landing slope of −3.40° —
slope-matched to 0.21°. Heading drift through the
flight: 0.0000°. Drone drops are excluded
(`air_from_release`): FP13's touchdown behaviour is the
drop's contract, and a 0.44 s fall would only pick up
~2° against the pendulum's own tilt story.

**Item 8 — Hang wander; the short drop verified.** The
base dangle's sway was a perfectly periodic Lissajous —
fore half-period 2.36 s, min = max (harness census, dips
frozen) — where the film's hang is irregular and nudged.
The carrier's station target now wanders: hash-scheduled
horizontal offsets (±0.28 m per axis, re-picked every
1.2–2.2 s on the house hash, on its own cadence
independent of the dip schedule), flown through the same
P-law as every other carrier motion, so the pendulum is
nudged by the *measured* carrier acceleration — the
irregularity is flown, never scripted into the pendulum.
Dangle phase only; the carry, the flare and the release
are untouched. Stage 42 repeats the census with the
wander live and the dips frozen: fore half-periods
n = 12, mean **2.38 s** (the pendulum's own — the wander
does not retune it), min 2.26, max 2.57 — spread
**0.31 s** against the base's 0.01; lateral spread
0.17 s. Drop fall **0.41 s** (base 0.44) — inside the
film's 0.3–0.5 s band, so no hang shortening was needed
or made (HANG_LEN unchanged).

**Frame strips (dense visual proof, ≥10 fps at 90 Hz).**
`tests/frame_strips.gd` (Xvfb, same harness family as the
render proof) composites two strips into `tests/`:
`rebound_strip.png` — the circuit gap at 40 m/s from a
car-anchored tracking camera: lip, flight, contact, the
rebound flight, settle (38 tiles); and
`crest_edge_strip.png` — stage 37's diagonal step-edge
crossing from a front-quarter anchor, the front corners
reaching over the steps a beat apart (45 tiles).

**Suites on the final tree:** smoke **335/335** with the
XR API-surface guard **70/70**; render proof **129/129**.
FP13's stages re-verified on the final tree as required:
28 (drone split), 30 (touchdown spread 1.29 s — the
Item 2 re-derivation above), 31 (wheel in the dangle),
32 (hang gate), 34 (split transport) all pass; stage 19's
3-lap census runs 19,204 frames to DONE. The one number
that moved legitimately: stage 19 +9 frames (the wander
nudges a recovery). Everything else that moved is
re-derived in its item section above, with the reason.

**What you're judging in run 14** (feel verdicts are
yours; all Hal-side numbers are unverified until the
headset says so): the rebound under big landings (does
the second flight read as the original's, or as a
pogo?), the one-bounce settle, whether the per-wheel
phase shows at edges and straddles, the crest slide's
persistence, VIEW A vs B (amber dash button / G — flip
it mid-run and compare), the hang's new irregularity
against your timing of the release, and Item 4's open
call: the drumbeat needs a gentler hump profile
(~6× softer) — a track design decision, not a tune
number, left deliberately untouched.



## Fix Pass 15 — telegraphed limit, the crane, dash-face lever, centre band

Base: FP14 final (2b92605). Four items, one commit each, in brief
order. Tallies on the final tree: SMOKE 373/373, API GUARD
70/70, RENDER PROOF 136/136. Everything below is
probe-verified only; the feel verdicts (audio cues, crane swing,
lever ergonomics, road readability) are the owner's on his device.

### Item 1 — the limit, telegraphed (commit 1b66ba0)

Traction loss no longer "just happens": a per-axle
demand-vs-capacity signal (demanded lateral acceleration against
FP14's load-scaled grip cap, load_grip = clamp(mean axle
load^0.35, 0.15, 1.15)) drives three cue families before the
bleed, all under the standing audio teardown discipline
(latched kill, watchdog, silence-by-default):

- Tire song: tonal 110 Hz stack whose gain follows the approach
  band, band = clamp((ratio − 0.70) / 0.30) — silent below ratio
  0.70, full at 1.00 (−34 dB floor → −19 dB).
- Haptics: controller rumble above ratio 0.90 (TIRE_HAPTIC_EDGE).
- Dust: kicked off the saturating axle's contact patches.
- Edge family, per wheel from FP14's support state: straddling
  the edge line scrapes (AUDIO_SCRAPE_MAX_DB −17); fully off the
  ribbon is a rumble strip (AUDIO_RUMBLE_MAX_DB −16).

Staged (stage 43): negative control peak ratio 0.00, all voices
silent. Held-16 m/s sweeper: 151 band frames, ratio peak 0.98,
slip peak 0.00 — the cues live in the approach, not the slide.
Progressive entry (the money number): band opens at frame 294,
slip at frame 329 — **warning lead 0.39 s / 8.9 m** — with song,
haptic and dust all peaking at 1.00. Edge legs staged on the
circuit home straight: straddle held at lat 6.06 → scrape 0.33;
deep ride at lat 6.92 → rumble 1.00, scrape 0.05. Stage 19's
census is frame-identical to FP14 (19,204 frames): no drive
numbers moved.

### Item 2 — the crane replaces the drone (commit 34795b8)

The drone is deleted (Run 14: "it just gets worst — loop de
loops"). In its place, the owner's own call: a fixed crane on a
service pad beside the drop piece, chains per the manual,
collection off-stage as in 1989. Flow: attach (1 s lift) →
trolley slew → dangle. Internal carrier names kept; phases
attach/carry/dangle. Constants: CRANE_PICKUP_OFF 2.4,
CRANE_POST_OFF 3.6, CRANE_SLEW_SPEED 2.4, CRANE_SLEW_ACCEL 1.6,
HANG_LEN 5.5, HANG_CLEAR 1.2; DROP_MIN_RUNUP_M 25.0 unchanged.

The FP14 hang irregularity came from drone station wander; a
fixed pivot must not regress to FP13's clean Lissajous (fore
half-period spread 0.01 s). The crane's honest nudge sources:
desert gusts stepping the station target (house hash, re-pick
every 1.2–2.2 s, GUST_AMP 0.14) and jib flex as a first-order
lag (JIB_FLEX_TAU 0.7 s, JIB_FLEX_M 0.16 — a lag, not a spring,
so it cannot resonate); split station-keeping (winch vertical
2.2 / cap 2.0 keeps dip authority; horizontal nudge 1.1 /
cap 0.6); pivot excursion clamped at PIVOT_OFF_MAX_M 0.30.
Census (2,700 frames, dips frozen): **fore half-period spread
0.39 s** — at or above FP14's wander-driven 0.31 s, honestly
sourced — mean period 2.26 s, max swing cone 0.40 rad, max
pivot offset 0.14 m. Fall A/B recovery: 605 frames end-to-end
against FP13's 1,439 and FP12's 1,482–1,559 carry-only.
Retired drone stages replaced at equal strength: 17 (slew
assertion replaces drone path length), 24 (restated: the crane
is built facing the drop heading — pivot never leaves the drop
piece, jib yaw within 5°), 28 (analytic clearance over attach +
slew; the fall-site exemption retired with the drone), 34 (pad
pickup at HALF_WIDTH + 2.4, tol 0.05), 42 (spread floor kept,
plus cone < 1.05 rad and anchor excursion ≤ 0.45 m budgets).
Panel text "Call drone" → "Call crane"; design-spec updated
(crane lock with the 2026-10-28 reversal note, wreck-repair
arms live on the crane, weather bends the jib).

### Item 3 — drop lever to the dash face, lefty mirror (commit 49b759e)

The lever leaves the dash top for the dash face, at the right
of the wheel, facing the driver, throw up/down as before:
DROP_LEVER_FACE_X 0.42, FACE_Y 0.70, FACE_Z −0.44 (was dash
top (0, 0.88, −0.70)). The placement is zone-driven, because
the first candidate face spot was a live fault: its grip point
(shaft + 0.27 m) sat **0.117 m from the RESTART button's
centre — inside its 0.15 m dash zone — so latching the lever
restarted the race** (caught by stage 25's latch poll). The
shipped spot clears the restart zone by 0.162 m and the wheel
grab radius by 0.422 m at rest, more along the throw; stage 44
sweeps the whole grip arc on both faces against every dash zone
and the wheel radius as a standing guard. Mechanism untouched
(detent 0.50, max throw 0.70, spring 3.5).

Lefty mirror: a light-blue SIDE dash button — the seventh dash
control, registered last so the FP10–14 six keep their indices
(VIEW stays index 5) — flips the lever to the left face;
desktop twin **M**. The side persists in settings (lever/left)
beside seat trim, defaults right, and the DIAG wheel line reads
DRP R / DRP L. The panel controls list names both in the same
commit (VR line: blue lever side button; desktop line: M lever
side). One knock-on fix: the widened DIAG readout put the
board's lower sightlines through the lean needle (proof sweep:
2 of 63 blocked) — the needle drops to y 1.04 (was 1.155) and
the sweep is clean.

### Item 4 — the invisible road: a centre band (commit c212ec8)

Surface/contrast only; no ribbon geometry changed, per the
brief. What shipped: a **continuous 1.1 m centre band in the
descent guides' amber (1.0, 0.60, 0.04), baked into the surface
mesh** — every surface quad is built as three strips (asphalt,
band, asphalt), so a third of the surface vertices carry the
band on both main tracks. Stage 45 asserts exactly that, at
data level, for both tracks.

What was tried and measured first, honestly:

- Fog thinning (0.00012 → 0.00005): no improvement at the dip
  sightline. Not shipped; fog is unchanged.
- A separate raised decal mesh (+0.03 over the surface, the
  first build): in the render proof's fallback renderer it won
  ~0 pixels at driving angles (driver-view A/B counts identical
  shown vs hidden; it rendered only alone in an emptied scene
  or lifted metres into the air). Rejected — a marking that
  cannot be verified in the project's own proof does not ship.
  The baked band cannot be depth-eaten and uses the same
  _add_quad/_add_mesh vertex-colour path as the field-verified
  edge strips and descent guides.

Residual, stated plainly: the fallback renderer does not
reproduce the surface's vertex colours faithfully at driving
angles (in its captures the road's top variously reads as the
surface's near-black or the box underside's brown), so the
band's readability is **not** established by these tallies — it
is the owner's verdict on his device, like every visual in
this project. And at the dip's descent-top sightline itself,
the road ahead presents nearly edge-on: no surface marking of
any width survives that projection. That sightline is a
profile problem, of the same family as FP14's crest verdict,
and belongs to the queued tracks pass (which also owns road
width and banking) — along with the stilt tops that poke
through the surface on pitched segments and cross the band
every 10 m.

### Yardsticks held

Stage 30 touchdown spread floor 1.25 s and stage 26 pitch
tolerance 0.18 stand as FP14 left them — not re-derived. The
crane's drop behaviour is reported against FP14's numbers in
Item 2 above. Steering lock scale ≤ 24 m/s untouched.

## Fix Pass 16 — OPERATION FIX THE FUCKING LEVERS

Base: FP15 final (84d0922). One subject only: the cockpit grab
path — dash buttons, seat levers, the drop lever, the wheel.
Ordered after run 15 ("It's fiddly as hell, like most levers
so far. Sometimes it work, sometimes it don't"), which also
brought the standing both-hands-on-wheel defect ("only one
hand can visually grab wheel at a time, even though both are
grabbed — been a problem since start"), a SIDE button that
flipped the drop lever's side by itself mid-session, and the
owner's sizing amendment: "make em smaller, I feel like an
Oompa Loompa." Five items, one commit each, in brief order.
Tallies on the final tree: SMOKE 395/395, API GUARD
70/70, RENDER PROOF 146/146. Everything below is
probe-verified only. Whether the grabs FEEL fixed is the
owner's verdict on his device — this pass is explicit that
staged-green is not evidence about the live path, which is
why Item 0 comes first and Item 5 ships.

### Item 0 — the differential (before any fix) (commit cc8db14)

The whole live grab path was read end-to-end and each suspect
given a verdict; the external research note
(research/xr-grab-reliability.md — XR Tools / VTOL VR patterns,
OpenXR action semantics) was checked against the code.

1. **Analog threshold, no hysteresis — CONVICTED.**
   `_poll_grab` computed the held state fresh every physics
   frame as `grip_v > 0.65 or grip_click or grip_force > 0.65`
   and assigned it directly to every latch. A squeeze hovering
   at the cut — nerves, sensor noise, a weakening grip — drops
   for one frame and returns: a toggle control's latch cleared
   and refired (double-flip), the drop lever's latch died
   mid-pull and the lever sprang home (the pull silently
   cancelled), the wheel grab dropped and re-took. Slow
   deliberate staged squeezes (0.0 / 1.0, parked) never produce
   the flicker, which is why four staged fixes missed it.
2. **Zone tunneling at physics rate — EXONERATED by
   arithmetic** for the shipped geometry (smallest zone
   diameter 0.30 m; a full crossing between 60 Hz polls needs
   an 18 m/s hand). Swept tests still shipped (Item 1) as the
   permanent guard — and promptly convicted a different
   mechanism (see the teleport cap, Item 1).
3. **Rep-vs-pose offset — EXONERATED as a code divergence.**
   The rendered rep is a child of the same XRController3D
   whose global_position `_hand_pos()` measures, origin dot
   exactly at the node origin; one transform source for render
   and test (stage 46 asserts the equality). Residual: the
   OpenXR "default" (aim) pose origin sits forward of the
   physical palm, and the alternative grip pose carries no
   live data on this VDXR rig — how much that offset
   contributes is **UNDETERMINED-LIVE**.
4. **Throw-tracking dropout — CONVICTED, routed through
   suspect 1.** Once latched, the pull reads the hand's angle
   about the pivot at ANY distance (no radius condition — the
   one piece of the old design that was right); the only
   mid-throw cancel path was the latch dying on a flickered
   grip frame. Same root, same fix.
5. **Grip value source — CONVICTED twice.** (a) `grip_force`
   has NO binding in any of the four interaction profiles
   (verified programmatically against
   openxr_action_map.tres): `get_input("grip_force")` returned
   null → 0.0 forever — the DIAG FRC column's permanent 0.00
   was expected behaviour on this hardware (Touch Plus has no
   squeeze/force endpoint), not a bug, and the channel is
   deleted. (b) `grip_click` is bound to squeeze/value — the
   SAME analog squeeze read through the runtime's own
   undocumented press threshold (the OpenXR spec leaves
   bool-conversion thresholds to the runtime; Godot's docs
   prescribe Float + your own threshold). It was never an
   independent rescue channel; it imported VDXR's threshold
   into every latch. Removed from the latch math; still read
   for the DIAG block as evidence.
6. **Feedback absence — CONVICTED (partially).** No haptic
   confirmation existed on any dash fire or wheel/lever latch
   (only the detent pulse). A grab could fail with NO signal
   on any channel; and the visual articulation that did exist
   keyed off the chattering held state, so even it flickered.

Also from the research: the classic conjunctive-coincidence
failure (a grab requiring the grip EDGE and zone entry in the
same sample — humans pre-squeeze 2–5 cm before contact) was
this codebase's FP9-era bug, already fixed by level-based
activation; the re-audit confirms no surviving path requires
a grip edge coincident with zone presence. Claims of a
VDXR-specific grip bug or per-hand channel asymmetry are
UNVERIFIED in the research and were not chased; run 10's
flatlined left channel remains a channel-level zero that only
live telemetry can classify (Item 5 logs per-hand squeeze
peaks for exactly this).

### Item 1 — the grab rebuild (commit cc8db14)

`_poll_grab` was rebuilt around the verdicts:

- **Analog-only Schmitt trigger.** Held = the analog squeeze
  through our own hysteresis: engage above **0.55**, release
  below **0.30** (before: a single 0.65 cut on the three-way
  OR). `gripping[]` IS the debounced state, so articulation,
  the recenter gate and the hang button gates all read the
  same held value the latches do.
- **Latch semantics everywhere** (the XR Tools / VTOL
  pattern: a grab once honestly made ends on grip RELEASE,
  never on a zone exit or a value dip). One-shot dash latches
  clear only on release — leave-and-return inside one squeeze
  can no longer double-toggle. Seat levers trim on the latch,
  in or out of the zone. The wheel **soft-locks**: the latched
  hand steers at any radius (its angle is read about the hub);
  the existing other-hand takeover on release is unchanged.
  Squeeze-and-sweep across controls still fires each on entry.
- **Swept zone tests** — the hand's per-frame travel segment
  against each control's grab segment (segment-segment
  distance), so a fast pass-through registers. Capped: a
  sweep longer than **0.25 m is a teleport**, not a
  pass-through, and falls back to the endpoint test. The cap
  exists because the uncapped sweep convicted itself in
  verification: stage 25's latch poll swept from the previous
  stage's parked pose across RESTART, resetting the race
  mid-sequence (hang phase back to "attach", the detent fire
  gated — the stage failed for a day under three wrong
  theories before an instrumented run printed
  `phase=attach`). A live tracking dropout + reacquisition
  across the cockpit would have done the same to the owner.
- **Witnesses, not silence.** The hand rep's origin dot swells
  with state (×1.5 with a CANDIDATE in reach, ×2.1 latched);
  a new candidate while ungripped earns a faint tick
  (0.18 amp / 0.04 s, rate-limited) — acquisition feedback
  BEFORE the squeeze, per XR Tools; latch and fire pulse
  0.35 / 0.06 s; an early lever release after a real pull
  (> 0.15 rad) gets its own tick (0.30 / 0.08) plus a
  telemetry event — a dropped pull is announced, never
  silent. The detent pulse (0.7 / 0.12) is unchanged. Whether
  any of these pulses are perceptible on the live rig is the
  owner's verdict, unverifiable headless.
- **Chatter accounting.** A held grab whose squeeze dips
  below the old 0.65 cut without reaching the 0.30 release is
  a grab FP15 would have dropped; each episode increments the
  counter Item 5 reports.
- DIAG: the dead FRC column is replaced by **HLD**, the
  Schmitt latch state.

Staged in the new stage 46: hysteresis holds a toggle's latch
through a dip to 0.45 with no re-fire on recovery (and the
rescue is counted); the drop lever's pull survives the same
dip mid-throw and still fires; the wheel tracks its hand at
0.55 m radius, past the 0.40 grab zone; a grazing chord whose
two endpoint samples both sit outside the zone still fires
its control via the swept segment; the rep-source equality
(suspect 3) is asserted for both hands.

### Item 2 — smaller levers, decoupled volumes (commit 2b71436)

The amendment is a pair: the furniture shrinks, the grab
volumes stay or grow — visual and interaction size are now
independent numbers, and the zone audit's rule inverts to
match (below).

| control | mesh before | mesh after | grab volume |
|---|---|---|---|
| drop lever shaft | 0.05 thick × 0.34 | 0.028 × 0.30 | radius 0.16 → **0.20** |
| drop lever knob | 0.10 cube @ 0.36 | 0.055 cube @ 0.315 | segment 0.18–0.37 → 0.13–0.32 (span kept 0.19) |
| seat lever shaft | 0.055 × 0.20 | 0.030 × 0.15 | segment 0.02–0.19 **unchanged** |
| seat lever cap | 0.085 × 0.06 @ 0.19 | 0.052 × 0.05 @ 0.145 | radius → **0.19** (seat-only) |
| dash buttons | r 0.045 (restart 0.05) | r 0.036 (restart 0.040) | radius 0.15 unchanged |

The audit (`debug_dash_ctl_audit`) previously kept zones ON
their meshes (no segment sample farther than 0.035 from its
own mesh). Inverted: every control's volume must **contain**
its mesh with margin — worst (mesh-point distance − radius)
over every mesh's AABB corners+centre must read
≤ −0.03 m — and no mesh point may sit > 1 cm inside foreign
bodywork (a base seated in its mount is not burial; the
run-11 buried buttons were centimetres deep). Final tree:
**worst slack −0.068 m**, zero violations, asserted in smoke
stage 23 and in the render proof's pose.

### Item 3 — both hands on the wheel (commit a8124df)

The defect had two halves. In the latch: FP15's wheel branch
let a second gripping hand STEAL the wheel (re-basing
`grab_prev_ang` to its own angle), so two held hands fought
over `grab_hand` every frame. The latch now takes only a FREE
wheel. In the render: the driving hand's rim point is glued
by construction (wheel deltas come from its own motion), but
a passenger hand's rep hung at the raw controller pose while
the rim turned under it. Now a gripping hand on an owned
wheel **attaches**: its grab point is stored in wheel-spin
local space (`rim_local`), and `_refresh_car_visuals` poses
its rep from the spin node each frame — the rep rides the rim
(orientation and position), detaching on release, on becoming
the driver, or when the wheel goes non-live.

Proof: the render proof stages it in the settled dangle
through the production grab path and measures the REP's
transform: attaches, sits at its grab point (0.60 rad), rides
to 1.10 rad when the driver turns 0.5 rad, radius constant,
driver rep identical to its controller pose throughout.
Frame: `tests/both_hands_wheel.png`. Stated plainly, per the
brief: **the headless smoke cannot see this layer** — it
exercises the grab path with simulated hands and no
controller reps under test; the defect survived four
staged-green passes for exactly that reason. The render proof
(fake trackers, real scene graph) is the only staged witness,
and the owner's eyes in the headset are the verdict.

### Item 4 — SIDE flips are deliberate (commit 503b453)

Run 15's flip was silent and self-inflicted (the button sits
in the grab playground; a brush during other work latched it
and the setting persisted). Now: entry starts a hold clock;
the flip fires only on a **sustained 0.6 s in-zone hold**, and
firing ANNOUNCES itself on the touchdown readout
("LEVER SIDE: LEFT/RIGHT", 2.5 s) — the DIAG DRP line and the
persisted setting already named the side; now the moment does
too. The M key stays instant (a keypress is deliberate by
nature). Staged in 46(f): a 0.2 s brush does not flip; a
sustained hold does, with the announcement on the label. The
owner's current setting (left, from run 15 — "where I
actually kind of like it") is untouched: the default remains
right, his persisted choice remains his.

### Item 5 — telemetry that ships (commit ceb19dc)

If a grab fails live again, it will not fail silently or
anecdotally. Every latch, fire, early release, zone entry
without a latch, rim attach and release writes an event
(`T<racetime> <hand> <WHAT> g<grip at the moment>`) to three
places: the DIAG block's new **GRAB** line (the last event,
in the driver's face), an in-memory ring, and a per-session
log file at **user://grab_log.txt** (truncated at launch;
next to settings.cfg — on the owner's machine under
%APPDATA%\Godot\app_userdata\Stunt Car VR - DE Test 1\).
At each
race start the previous race's account closes into the log as
a SUMMARY: fires, wheel latches, lever latches, early
releases, chatter rescues, and **each hand's session squeeze
peak**. The signatures separate: zone entries with NOLAT at a
low value = the hand arrived and the squeeze never read (or
peaked low — see the peak); NO zone entries = the hand never
arrived (aim/pose); EARLY lines = pulls dropped mid-throw,
with the angle reached; a rising chatter count with no
complaints = the hysteresis earning its keep. Staged in
46(g): the ring carries the stage's own DRP FIRE and WHEEL
LAT events, the DIAG block carries GRAB, the log is open.

### Honest residuals

- **UNDETERMINED-LIVE, first:** what VDXR actually delivers
  per hand in the headset — the analog squeeze's shape and
  noise at partial press, and any per-hand difference. Every
  threshold above (0.55 / 0.30) is set from the research
  pattern and staged values, not from the owner's live
  signal; the grab log's peaks and NOLAT values are the
  instrument that will convict or clear this, and the engage
  point can move on that evidence.
- **UNDETERMINED-LIVE:** the aim-pose-vs-palm offset
  (suspect 3's residue) — the measured point is the
  controller's "default" pose origin, which sits forward of
  the physical palm; if the owner consistently lands long or
  short of the furniture, this is the remaining suspect and
  the volumes (0.15–0.20 m) are the current allowance for it.
- Haptic perceptibility (candidate tick, latch pulses,
  early-release tick) is unverifiable headless, as with every
  pulse since FP11.
- The research-flagged **Toggle Grip** option (VTOL ships
  one: tap to latch, tap to release) is an owner decision,
  NOT shipped here — it changes what a squeeze means and is
  his call, not a fix.
- The grey throbbing circle from run 15 is untouched by this
  pass (unidentified; it is not a grab-path feature and no
  staged surface reproduces it).

### Yardsticks held

No drive numbers moved: the grab rebuild touches only the
input path, and stage 19's autopilot census runs 19,355
frames on this tree — frame-identical to the FP15 code
(84d0922) run in the same environment before the pass began
(FP15's README reports 19,204 from its own builder's
environment; the number is environment-consistent, and it
did not move). All FP15 stages re-pass unmodified except
stage 44's SIDE presses, which now run through the deliberate
hold (the helper polls the hold out — the assertions are
unchanged), and stage 23, whose audit assertion is Item 2's
inverted rule.


## Fix Pass 17 — One Hand, One Control (+ throw telemetry)

Base: FP16 final (ddf0612). Surgical pass, two items, ordered
on the owner's tap after he read his own run-16 grab log
(archived at `research/grab-log-run16.txt`). His grips in that
log are healthy (latch 0.78–1.00 both hands, releases
0.14–0.25), so FP16's thresholds (engage 0.55 / release 0.30)
are untouched, no drive numbers moved, no commands were added
(the controls list is unchanged), and the queued load (smoke
puff, banner rename, tire story, toggle grip) is NOT in this
pass. Tallies on the final tree: SMOKE 421/421, API GUARD
70/70, RENDER PROOF 146/146. Everything below is
probe-verified only — whether the lever finally behaves is
the owner's verdict in the headset; what this pass guarantees
is that one squeeze can no longer grab two controls, and
that a failed pull now leaves evidence.

### Item 1 — one hand, one control (commit 2368416)

The conviction came from the owner's own lines: at T14.8 his
left hand rim-attached (`L RIM ATT`) in the same instant it
fired the drop lever (`L DRP FIRE`). FP16 grew the lever's
grab radius to 0.20 m, and that tube overlaps the wheel's rim
test beside the shaft — one squeeze, two grabs. Harmless in
that fragment (the other hand drove, so the lever hand could
only ride as passenger); with the wheel FREE, the same hand
could latch the wheel and pull a steer instead of a drop —
which fits his report exactly: first drop works (set up
deliberately, wheel held), later drops iffy (recoveries,
hands everywhere).

THE RULE, as implemented (`_hand_owner` + arbitration in
`_poll_grab`): a hand owns at most one control class at a
time — wheel (driver), rim (passenger), drop lever, or a
dash latch (one-shots and seat trims alike). Every
acquisition is gated on the hand owning NOTHING, in both
directions: a lever/dash hand cannot rim-attach or latch
the wheel; a wheel/rim hand cannot latch the lever or a
dash control; the driver-takeover is an acquisition too
(a rim passenger may promote; a lever/dash owner may not
be handed the wheel). Ownership ends only on grip release,
never on a zone exit. The one exception is inside the dash
family: a dash owner keeps FP9's squeeze-and-sweep between
dash controls. When an unowned, held hand is inside several
tests in the same frame, the NEAREST wins — the tests' own
swept distances compared directly; exact ties resolve in
poll order (lever, dash, wheel). Entries in different
frames need no tiebreak: the first acquisition owns the
hand, so later arrivals never evaluate. The loser records
nothing — no latch, no attach, no event.

Stage 47 stages the log's own script: (a1) T14.8 verbatim —
driver + lever pull — now produces LAT+FIRE with ZERO rim/
wheel events for the lever hand; (a2) the lever with the
wheel free fires and latches nothing else; (b) a HELD wheel
moved inside lever range keeps the wheel and the lever
never latches; (b2) a fresh squeeze inside both volumes
resolves to exactly one acquisition; (e) a seat-latched
hand taken to the wheel gets nothing. FP16's both-hands
case is preserved exactly (render proof: driver latches,
passenger attaches and rides the rim, 146/146).

Two staging notes, stated plainly. First, (b) is staged as
a held wheel inside lever range rather than a fresh
simultaneous squeeze: the geometry forbids the pure case —
the lever segment's nearest point sits 0.422 m from the
hub, so the overlap lens (within 0.20 m of the segment AND
0.40 m of the hub) lies entirely on the lever's side of the
bisector; no pose inside both volumes is nearer the hub
than the segment, and (b2) covers the simultaneous entry
that can actually occur (it resolves NEAREST: lever
≈0.13 m over hub 0.30 m). Second, one FP16 staged
expectation deliberately changed (the brief's flag): stage
25's lever grab squeezed from a latch an earlier stage left
held; arbitration requires a release between controls, as a
real driver does, so stage 25's script gained one release
poll before the grab. The grab it stages is unchanged.

### Item 2 — throw telemetry (commit 6148c1b)

FP16's log recorded LAT and FIRE but nothing of the pull
between them — a pull that stalled short of the detent left
no trace — and it truncated per launch, so the run-16
upload carried only the owner's last short session. Both
blind spots are closed:

- Pull fraction (progress toward the detent, REST→DETENT)
  logs its quarter crossings: `DRP PULL 0.25 / 0.50 / 0.75`,
  each with the grip.
- `DRP FIRE` gains the pull duration: `dt<seconds>` from
  latch to detent.
- A latch that ends unfired logs `DRP ORPHAN peak <fraction>
  g<grip at release>`; FP16's EARLY witness (a real pull let
  go early) is unchanged and fires alongside it.
- Every lever release logs `DRP REL`; the seat trims, which
  share the latch path, log `SEATUP REL` / `SEATDN REL`.
- The log file APPENDS across launches under a per-launch
  header (`=== SESSION FP17 (base ddf0612) <wall clock> ===`),
  tail-trimmed to 256 KB, oldest lines first. Verified live
  in this environment: three FP17 session headers
  accumulated over the preserved FP16 content of the
  previous file — the next upload carries every attempt
  since the build landed.

Before (FP16), a fired pull and a stalled pull:

```
T14.6 L DRP LAT g0.78
T14.8 L DRP FIRE g1.00
(stalled pull: LAT, then nothing — the blind spot)
```

After (FP17), from stage 47's staged runs in the shipped
log (race clock reads 0.0 in staged manual polls; live lines
carry real race times):

```
T0.0 R DRP LAT g1.00
T0.0 R DRP PULL 0.25 g1.00
T0.0 R DRP PULL 0.50 g1.00
T0.0 R DRP PULL 0.75 g1.00
T0.0 R DRP FIRE g1.00 dt0.00
T0.0 R DRP REL g0.00
T0.0 R DRP LAT g1.00
T0.0 R DRP PULL 0.25 g1.00
T0.0 R DRP ORPHAN peak 0.30 g0.00
T0.0 R DRP EARLY g0.00 @0.15
T0.0 R DRP REL g0.00
```

### Honest residuals

- The arbitration is staged on synthetic poses like every
  grab fix before it; the live proof is the owner's next
  session — whose log now records latch, pull, fire/orphan
  and release for every attempt, appended across launches,
  so a surviving failure names its own shape.
- NEAREST arbitration means a hand arriving exactly between
  two controls takes the closer one. In the cockpit's real
  geometry the volumes barely overlap (the lever/wheel lens
  is the convicted case); if the owner ever grabs a
  neighbour he didn't intend, the log will show which test
  won and by how much is inferable from the pose he
  describes — the thresholds and radii themselves were not
  moved in this pass.
- One full-suite attempt during this pass died silently at
  stage 13 with no error in its log (harness session lost);
  the identical tree then passed 421/421 clean, and the
  stage-13 content (fall/cutoff physics) is untouched by
  either item. Recorded here rather than smoothed over.
- The session header's build tag is a per-pass constant
  (GRAB_LOG_BUILD), updated by hand like this README's own
  accounting; it names the pass and its base, not the
  delivery commit, which cannot know its own hash.


## Fix Pass 18 (micro) — Asphalt, and the winding conviction

Base: FP17 final (8288719). Ordered as a colour-only micro-pass
("can we get the track more road colored, not brown" — placement
delegated). It did not stay colour-only, and this section says
why, plainly: halfway through verification the colour change
proved INVISIBLE — not subtle, not renderer-dependent, but
absent under every material, including a diagnostic pure-green
surface that rendered nowhere on the road. The bisect convicted
the ribbon's box sections of inverted triangle winding: the
road's top has been back-face culled from above since the box
section was built, and what every run has shown as "the road"
is the box's underside (bot_c brown) seen through the culled
top. The FP15 centre band has been present in the mesh data
the whole time (stage 45 verifies it) and has never rendered.
The pass therefore ships two things: the winding mirror that
makes the surface exist, and the asphalt colour the owner
asked for. Tallies on the final tree: SMOKE 421/421,
API GUARD 70/70, RENDER PROOF 146/146. Controls list
untouched; no drive numbers, geometry, fog, or lighting moved.
Everything below is probe-verified only — the verdict is the
owner's in the headset, and it now includes seeing the road's
actual surface (grey field, amber band, dashed amber edges)
for the first time.

### Item 1 — the winding mirror (scope deviation, evidence-led)

`_add_quad`'s corner walk (a-b-c / a-c-d) is back-facing from
the stated normal's side in this renderer. FP12 convicted the
same bug on the spur's guide strip and chevrons and mirrored
those two locally ("as first built these faced DOWN... the
mirrored corner order"); the box sections in
`_build_track_meshes` and `_build_spur` — surface strips,
skirt sides, underside, edge strips — kept the naive order.
Proof, in order: (1) the built mesh's arrays carry the new
colours verbatim (surface, band, spur all sampled); (2) the
material is exactly as designed (vertex colour as albedo, no
texture, nothing overriding it at render time); (3) a test
quad built through the same path renders its colour
correctly in the same frame where the road renders brown;
(4) isolating TrackSurface alone renders nothing from above
(the frame is pure desert — the brown band in full views is
the skirt/underside); (5) forcing an unshaded pure-green
material onto TrackSurface changes nothing at the road's
pixels; (6) the same mesh with each triangle's winding
flipped renders the amber band at the centreline from above,
exactly where the data says it is. The fix is a mirrored
helper, `_add_quad_m` (a-d-c-b), applied to the box-section
and edge-strip call sites in both builders — the same remedy
FP12 applied, generalised. NOT touched: the spur's guide
strip and chevrons (already mirrored in FP12), the stilt
blades (their stated normal points down-track and they render
toward the approaching driver under the same inversion —
flipping them would hide them; unaudited beyond that, and the
stilt family belongs to the tracks pass anyway), gantry and
desert meshes (engine geometry). The stated normals were
always correct; only the winding was inverted. Physics never
reads the mesh, and the full suite re-passes.

### Item 2 — asphalt grey (the briefed change)

Main field, both builders (`surf_c` in `_build_track_meshes`,
which serves circuit and test ribbon, and in `_build_spur`):

- before: Color(0.07, 0.07, 0.09) — near-black slate
- after: Color(0.30, 0.30, 0.33) — asphalt grey, cool neutral

The grey is a clear luminance step down from the tan desert
(0.76, 0.62, 0.42) and up from the old field, so the ribbon
separates from the terrain by value as well as by family.
Markings report, as the brief asked: the amber edge strips
(1.0, 0.72, 0.10) and centre band (1.0, 0.60, 0.04) keep their
identity on the grey — hue separation is strong (warm amber on
cool grey) — but the band's luminance step over the field
drops from ~8x (against near-black) to ~2x. Within colour
only, no remedy was applied: in the sandbox captures the band
reads clearly, and raising the band's brightness would push
it toward the guides' unshaded punch it deliberately doesn't
have. If it reads weak on device, the colour-only lever is
band albedo up; the sections/markings design that would
settle it properly belongs to the tracks pass. (The band is
in any case rendered for the first time — see Item 1.)

### Measurement — FP12 wash instrument, three states

FP12's instrument (ID-pass swap; low-contrast fraction =
ribbon pixels within 0.10 RGB of the row-band background mean;
frozen warp protocol, 1280x800, this sandbox's renderer).
Three columns because two changes shipped: BEFORE is the
base build (culled top, dark field), WINDING is the mirror
alone on the old field, AFTER is the final tree.

| station | before | winding only | after (asphalt) |
|---|---|---|---|
| home_straight | 0.0% | 0.0% | 9.5% |
| climb_mid | 6.5% | 0.0% | 0.0% |
| before_dip | 3.7% | 2.4% | 2.4% |
| dip_floor | 0.0% | 0.0% | 0.0% |
| climb_top | 8.0% | 0.0% | 0.0% |
| mid_straight | 15.2% | 20.1% | 20.1% |
| loop_approach | 0.0% | 0.2% | 0.2% |

Read honestly: the winding fix is the mover (climb stations
to zero; ribbon pixel counts rise ~15% because the top now
renders at distance). mid_straight's fraction RISES under the
fix and stays — in the culled state much of the far ribbon
simply wasn't drawn to be counted; drawn, the far straight
still washes in this renderer, and neither colour moves it.
That residual belongs to the tracks pass (sections/geometry),
as already filed. home_straight moves 0.0% -> 9.5% on the
colour change alone: mid-grey sits closer to that station's
sky-dominated background mean than near-black did — a
luminance-distance artefact of the metric, reported rather
than tuned away; on device the road there now also carries
the band and edge dashes it never had. Standing caveat
(FP15): the sandbox renderer does not reproduce the owner's
device colours at driving angles — these fractions show
direction only; his headset gives the verdict.

### Verification notes

Two, for the record. The render proof's first run here
failed the wheel-hub reach check at 0.31 m (band 0.22-0.30):
the smoke suite had persisted a seat trim of 0.024 into
`settings.cfg`, and the proof's precondition is trim 0.
Trim zeroed, the proof re-ran 146/146 (hub 0.29 m) — an
environment artefact, not a regression; no seat code moved.
And the wires_view colour-count check (>25 sampled colours)
is now MARGINAL: 11 in one run, 32 in the next, against a
bar calibrated on the see-through frame. From below, that
frame is now legitimately dominated by the flat underside;
whether it passes depends on the hang phase at capture.
It passes on the delivery tree, but the margin is a
tracks-pass note (underside treatment), not a number to
trust blindly — the check itself was left untouched.

### What you're judging (run 18)

- The road's surface itself, for the first time: asphalt grey
  field, the continuous amber centre band, dashed amber edges
  — all previously culled or, in the band's case, never seen.
- Whether the grey reads as road against the desert on device,
  and whether the band still carries at dip ranges at ~2x
  luminance step + hue.
- NOT in this pass: sections/markings, the speed-envelope
  decision, dip re-profile, stilt tops, the loop entry — the
  tracks pass, still gated on the owner's word.


## Fix Pass 20 — The Button (the lever is retired)

Base: FP18 final (7377bc3). Ordered out of run 18 and the
lever's whole history: five passes of staged-green fixes
(FP11's lever, FP12's shifter, FP13's centre lever, FP15's
face lever, FP16's Schmitt rebuild, FP17's arbitration) and
the control still failed in the owner's hands — because a
pull is a multi-sample act (zone, threshold, sustained grip,
a swept hand tracked through a 0.19 m throw), and staging's
perfect squeezes certify the samples, never what happens
between them. The owner's words: "Lever is still not
consistent. why is a lever so hard? Im sick of going round
and round with the lever, make it a button for now." A button
is a single threshold event in a fat zone — the one mechanism
staging can certify honestly. Run 18 also carried the
interactivity law from the run-17 post-mortem (the FP17 lever
was polled only at the dangle, so recovery pulls mid-carry
were disarmed AND silent): **physical controls never freeze;
context decides what a pull DOES, never whether the control
responds** — and where a press can't do the thing, the floor
is a FELT REFUSAL (a grind in the controller), never silence.
Tallies on the final tree: SMOKE 449/449, API GUARD 70/70,
RENDER PROOF 146/146. No drive numbers moved (the suite's
frame-identity stages re-pass unchanged). Everything below
is probe-verified only — the verdict is the owner's in the
headset.

### Item 1 — the DROP BUTTON

The lever (pivot, shaft, knob, bracket, its whole latch /
pull-tracking / throw-telemetry machinery) is deleted. In
its spot on the dash face stands a big red button: unshaded
cylinder, r 0.07 m, on a bracket box, face point at
(±0.42, 0.70, −0.44) — 0.50 m from the wheel hub (outside the
0.40 m grab radius) and ≥0.29 m from every dash-top button.
It is a DASH CONTROL (kind "drop", registered last of eight),
so it inherits the dash mechanics whole: Schmitt latch (one
press per squeeze), swept zone test, the FP17 one-hand-one-
control arbitration (stage 47's suite, rewritten against the
button — including simultaneous hub/button entry, where the
button wins as the nearer candidate, 0.14 m vs 0.38 m). Its
side follows the persisted mirror (the settings key stays
"lever"/"left" — the owner's existing setting carries over)
and the blue SIDE button / M key, exactly as the lever's did.

**A press registers in every phase** (`_press_drop_button`):

- **dangle** — the release fires (BTN FIRE + the pulse
  detent), as the lever's completed pull did.
- **attach / carry** — BTN SPENT is logged with the phase,
  and the GRIND runs: 0.40 s of rough pulse train (0.55 amp
  every 0.07 s) in the pressing controller. The chains hold;
  nothing drops; the press is never mute. This is the run-17
  failure — four silent pulls during the carry — answered.
- **drive / air / done** — BTN PRESS is logged and a dull
  pulse answers (0.25 amp). Nothing else happens.

The button dips 12 mm into its bracket while a squeeze holds
(the articulation follows the dash latch, along −z instead
of the seat levers' −y). The panel names it ("Release: press
the DROP BUTTON (dash face)"), DIAG's short tag is DROP with
the side (DROP L / DROP R), and the grab log's vocabulary is
BTN FIRE / BTN SPENT / BTN PRESS now — DRP/PULL/ORPHAN are
gone with the throw they described. The in-game commands
list and this README's Controls section name the button in
the same commits.

HONESTY NOTE: the grind and the pulses are issued through
the same haptic path as every prior pass's detents, and
**haptics cannot be proven from this sandbox** — whether the
refusal reads as a grind in the hand is UNVERIFIED-LIVE, the
owner's verdict on device, like every feel claim before it.

### Item 2 — the centre band is removed

Run 18, on seeing the surface render for the first time
(FP18's winding fix): the grey is right, but the band "has
one long stripe, not what I wanted. going down center." The
band is out of `_build_track_meshes` — each segment is one
full-width asphalt quad again (the spur never had one). What
remains: FP18's asphalt grey, the dashed amber edges.
Stage 45 now asserts the ABSENCE (0 band-coloured vertices;
the surface uniformly asphalt) where FP15–FP18 asserted its
presence. Mesh-build only: physics never reads the mesh, no
geometry or drive numbers moved. The sectioned markings the
owner actually wants are the tracks pass's subject, still
gated on his word — this item only removes what he rejected.

### Item 3 — the backwards drop: census, no conviction, telemetry shipped

Run 18: a crane recovery "dropped me backwards facing wrong
way on track." The hunt was staged as a CENSUS (new stage
49), not a sample: a forced fall in each of the circuit's
ten segment families, through the production path (fall →
recovery → hang → dangle → release once the sway settles),
reading the release's heading error from the new telemetry:

| family | fall s | drop s | heading | section | error |
|---|---|---|---|---|---|
| home straight | 150 | 150 | +0.0° | −0.0° | **+0.0°** |
| curve A (banked) | 550 | 362 | +0.0° | −0.0° | **+0.0°** |
| dip descent | 830 | 742 | +80.0° | +80.0° | **+0.0°** |
| dip floor | 960 | 960 | +80.0° | +80.0° | **+0.0°** |
| mid straight | 1300 | 1300 | +80.0° | +80.0° | **+0.0°** |
| hairpin (banked) | 1650 | 1474 | +80.0° | +80.0° | **+0.0°** |
| signature climb | 2000 | 1902 | −100.0° | −100.0° | **+0.0°** |
| hump descent | 2300 | 2206 | −100.0° | −100.0° | **+0.0°** |
| curve C (banked) | 2600 | 2206 | −100.0° | −100.0° | **+0.0°** |
| tail return | 3050 | 2974 | −180.0° | −180.0° | **+0.0°** |

**Could not reproduce.** Every family's release heads
exactly along its drop section's travel — including the
tail return, whose section itself travels at −180° (the
return leg runs opposite the start heading, and the car
correctly drops facing −180°: along travel, not "backwards"
in any sense the physics recognises). Code analysis agrees:
the carrier's yaw is initialised from the drop piece's frame
in both race start and recovery, and the station gate won't
dangle until the carrier has swung onto it. Two honest
caveats. (1) The census releases at settle, as staged drops
do; a LIVE release happens whenever the owner presses —
mid-sway included — and a mid-sway release keeps the sway's
heading at that instant. (2) No code path was found that
flips a heading ~180°, but the owner's eyes have beaten
staging before (the winding conviction was his catch too).

So the pass ships the instrument instead of a fix: **every
release now records itself** — `_do_release` stores the drop
s, the release heading, the section's travel heading and
the error, and writes `RELEASE s… HDG … SEC … ERR …` into
the grab log (and the DIAG GRAB line). If a backwards drop
ever happens again, his own log carries the numbers from
the instant it happened, and the hunt reopens with evidence
instead of recollection.

### Staged-expectation changes (flagged, never silent)

Every staged expectation that encoded the lever was replaced
by its button successor and is flagged in place: stage 22
(control count 7→8; VIEW's index unmoved), stage 25
(rewritten — the button's stage), stage 34 (transport probe:
SPENT + grind replaces "the lever does not latch during
transport" — the phase freeze the interactivity law
repealed), stage 44 (rewritten — the button's mirror),
stage 45 (band ABSENCE replaces presence), stage 46(b) (the
button's latch through the grip dip replaces the lever's
mid-throw dip), stage 46(f)/(g) (side + telemetry names),
stage 47 (the arbitration suite rewritten against the
button; case (e) is unchanged — it never touched the lever),
stage 49 (NEW — the heading census). Render proof: panel
keywords (DROP BUTTON / drop side / M drop side), the
eight-control list, the zone overlay's button marker, and
the release portrait (now `drop_btn_view.png` /
`drop_btn_view_left.png`).

### Verification notes

The sandbox fought this pass harder than the code did: three
suite attempts died to the engine's known threading crash /
host restarts mid-run (stages 3, 10a, 18, 28 across attempts,
zero FAIL lines before each death) before the final tree ran
clean end to end — SMOKE 449/449, API GUARD 70/70. The
render proof passed 146/146 on the final tree; its
wires_view colour check remains the FP18-documented marginal
one (11 colours in two runs, 26 in the passing run — the
from-below frame's census swings with the hang phase at
capture; FP20 touches nothing in that frame and the check
was left untouched, as FP18 left it). The seat-trim hygiene
note from FP18 applies as ever: the smoke suite persists a
trim, so the proof runs from trim 0.

### What you're judging (run 19)

- **The button, in every phase.** At the dangle: one press,
  car goes. During a recovery's attach/carry: press it —
  it should answer with the grind and a BTN SPENT you can
  feel, and the car should stay chained. While driving:
  a press should thock dully and do nothing. Any press,
  anywhere, that feels like NOTHING is the bug this pass
  exists to kill — say so.
- **The button's placement and size** — the lever's spot on
  the dash face, mirrored if you flip SIDE; a fat red target
  instead of a shaft to thread.
- **The road without its stripe** — plain asphalt grey +
  dashed amber edges. (Sections/markings are NOT in this
  pass; the tracks pass designs them.)
- **Drop headings after recoveries** — if any drop ever
  faces you wrong again, it is now on the record: the grab
  log (%APPDATA%\Godot\app_userdata\Stunt Car VR - DE Test
  1\grab_log.txt) carries a RELEASE line per drop with the
  heading error at that instant.
- Both-hands re-check rides along as ever (the arbitration
  suite is re-staged against the button; your hands are
  the verdict).
- NOT in this pass: sections/markings design, the smoke-puff
  and banner-text cleanups, visual steering, the tracks
  pass, button gates of any kind (the button has none —
  that is the point).


## Fix Pass 21 — AIR (per-corner load, separation by physics)

Ordered from the owner's run-18 report (2026-10-29): "im just
not getting the air I feel i should be getting, I come out of
turn and hit the little inside flair and I expect those left
wheels to catch some air… at the hills, where the car feels
like it wants to stick to road instead of bounce." Two
suspects named in the brief: the per-axle crest-load scalar
(blind to one-side unloads) and the FP8 flight-entry gate
(both axles at ~zero load, sustained — a gate small hops
cannot pass). Per the brief, the conviction ran FIRST:
load traces on the unmodified tree (456c456) through a
diagnostic harness reading the production state plus the
per-corner patch load the model did not yet compute.

### The conviction (traces before any change)

- **Curve A exit / the bank unwind (autopilot) — CONVICTED.**
  Zero air episodes; the axle loads read 1.00 flat through
  the whole unwind. The centreline kv there is 0.000 — the
  unwind is a BANK change, not a centreline crest — while
  the patch kv at the falling (right) side's wheels spikes
  to +0.021/+0.025: patch load 0.00 sustained for ~10 m,
  the held side at 1.25. A one-side unload the per-axle
  scalar cannot see, by construction.
- **Ribbon corner exit + launch lip (pinned 24) —
  CONVICTED.** Axle loads 1.00 throughout while the corner
  patch loads swung 0.00 ↔ 1.25, alternating sides (FR at
  0.00 while FL sat at 1.25).
- **Climb-top bend at cruise — the model is honest, the
  ask is not available.** Loads bottom at 0.47 (front) /
  0.53 (rear); the rear springs bleed to c ≈ 0.00–0.02
  chasing the falling road (the FP5 bleed) — but at
  24–34 m/s, v²·kv < g at kv 0.006: no ballistic separation
  exists at cruise on that bend. At 43–46 m/s the bend DID
  fire the old gate and fly. Partial load at cruise is the
  correct physics, and FP21 keeps it (stage 51 stages it
  as a negative control).
- **Circuit hump row, pinned 24 — CONVICTED.** Three real
  flights (0.66 / 1.07 / 0.13 s) buried in ~90 one-frame
  mode-flicker episodes — the sustain gate chattering at
  its own threshold. One flight in the 0.1–0.4 s drumbeat
  band. At 48: three flights of 1.6–2.2 s, none in band.

Verdict: the gates were convicted — the scalar is
structurally blind to the flair, and the sustain gate eats
the small hops at the hills.

### Item 1 — per-corner load sampling

The crest load is now computed PER CORNER from the vertical
curvature of the surface at the wheel's own contact patch:
`_patch_kv(s, lat)` takes the second difference of the
surface height at the patch (±2.5 m stencil along the
frame, slope-corrected) — sign convention: positive over a
crest. `wheel_load[4]` is each corner's clamped load;
`load_f`/`load_r` survive as the corner means of their axle,
so every pre-FP21 reader keeps its meaning. Spring targets
scale by the corner's OWN load; `load_grip` is the same
formula over the four-corner mean — arithmetically identical
to the old value wherever the corners agree (straights,
flat, symmetric crests unchanged). Scope line, deliberate:
the spring GEOMETRY (rise/support heights) stays
centreline-based per FP9's design; the per-wheel height +
curvature enter through the load channel, which is where
the owner's two scenarios live.

### Item 2 — separation by physics

A corner is airborne when its patch load is ~zero
(`wheel_load ≤ 0.03`) at speed — the road falling away
faster than that corner's ballistic arc. An airborne corner
targets full droop and carries nothing; it re-contacts the
frame its load returns. The CAR flies when all four corners
have separated: on the main track this replaces the FP8
both-axle sustain counter (the spur keeps its own FP8 form,
mirroring the corner state from its axle loads). FP5/14's
rebound-energy route is untouched — the separation entry
explicitly does not arm it. Guards: entry needs speed > 8
(and the load factor itself re-contacts a slowing car,
v²·kv → 0); corners the support projection has already
given up (past the cutoff) stay the straddle's business —
no separation state exists off-support; crane/dangle/drop
paths clear the corner state and never read it.

### Evidence (after)

Stage 51 (NEW) stages the owner's scenarios on the circuit:

- (a) The flair: through curve A's unwind the corner-air
  counters move FL 6 / FR 14 / RL 6 / RR 14 frames — the
  falling side leads (right 28 vs left 12), and the car
  NEVER fully leaves: a two-wheel event, as ordered.
- (b) Circuit humps at cruise (pinned 24): 10 flights,
  5.59 s of air total. The drumbeat band count on this row
  is reported honestly, not quota'd: the row descends at
  −8° under its humps, a separated car stays out ~1.1 s per
  hump, and the band fills only via phase-sensitive
  re-flights — the diag protocol measured 4 in band, the
  suite protocol 0, same model.
- (b2) Ribbon humps at cruise (the flat-based row — the
  band's home geometry): 8 flights [1.1, 0.33, 1.1, 1.1,
  0.33, 1.1, 1.1, 0.7] — 2 in the drumbeat band, mid-band
  and stable across both measurement protocols, hops
  interleaved with the long flights.
- (c) Climb-top negative control: no separation at cruise;
  minimum axle load 0.54 — partial, as the physics
  requires.
- (d) Flat guard: the home straight at 34 m/s separates
  NOTHING — zero corner-air frames, minimum corner load
  1.00.

Diag protocol (fresh boot, same scenarios): curve A window
(s 690–750) FR 15 / RR 15 corner-air frames with the car
grounded throughout; circuit row at 24: 11 episodes, 4 in
the band (0.47 s), ~6.6 s total, and the ~90 one-frame
flickers collapse to a single 0.011 s episode (a few 1–2
frame re-contact blips remain under the suite protocol —
mechanically inert, the landing window absorbs them the
next frame; noted, not gated). Stage 38's sweeper exit now
measures the asymmetry FP14 could only document: first
unload FL 229 / FR 249 / RL 237 / RR 259 — the falling side
leads by 20/22 frames at the two axles, the wheelbase phase
unchanged. Stage 20 counts 10 circuit-hump flights under
autopilot.

### Census and moved numbers

NO drive constant moved — springs, sag, rebound energy,
grip slope/exponent, steering, lock, speeds all carry their
FP20 values. What changed is the load signal's source and
the flight-entry rule. Behaviour deltas, enumerated: stage 8
full lap 46.8 s (ribbon, 1163 m); stage 9's step census
passes (worst outside-event step 0.0274 m / 0.675° against
0.05 m / 1.2° tiers); stage 19 three laps in 18133 frames,
seam steps 0.0027 m / 0.015°; stage 12b's flick baselines
hold (peak slip 1.00, counter-steer recovery 30 vs 66
frames). Lock behaviour at ≤24 m/s: the lock-scale path is
untouched, corner loads on flat and straights are exactly
1.00, stages 12a/12b pass — steering at and under 24 should
feel as it did, except where the road itself unloads a
corner.

### Amendments (flagged, never silent)

- **Stage 35**: the 48 m/s hump-row flight-count floor
  drops 3 → 2. Per-corner separation re-phases the row:
  measured contact 22 / flight 164 / contact 5 / flight 163
  / contact 6 — contacts are four-corner events now and run
  5–6 frames (FP14's comment said 16–25), so the third
  flight starts past the window edge. The pattern check and
  stage 38's independent lock on the same row are intact.
- **Stage 37**: the diagonal-crossing order may now lead
  by one frame for the trailing corner (measured −1, was
  +2). FP14's shared axle channel could not lead; the
  per-corner channel reads through a ±2.5 m stencil that
  sees the edge early. The corners still move a beat apart;
  the square-crossing control is unchanged.
- **Stage 38**: the documented left/right SYMMETRY limit is
  retired and its check inverted — it now asserts the
  left-first asymmetric unload FP21 exists to produce. The
  stage's comment records the retirement and the measured
  frames.

### Verification notes

SMOKE 459/459 on the final tree. API GUARD 70/70. Render proof 146/146 under
Xvfb from seat trim 0 (the suite persists trim 0.024 — the
FP18 hygiene note applies as ever; the proof's first
attempt this pass stalled at its first capture because it
was launched --headless, which its own header forbids —
frame_post_draw never fires there; the Xvfb rerun passed
clean in under a minute). The first full-suite run of the
final code scored 457/458, the one failure being stage
51(b)'s original band quota on the circuit row — the stage
was restructured (band counted there, quota'd on the ribbon
row) rather than the model touched, and the suite rerun
clean. Everything above is staged evidence; the feel is
UNVERIFIED-LIVE until the owner drives it.

### What you're judging (run 20)

- **The flair.** Out of the banked turns — curve A's exit
  is the staged one — the falling side's wheels should
  catch air briefly while the car stays planted on the
  held side: a two-wheel lightness, not a jump, not a
  slide.
- **The hills.** Hump country at cruise should patter now:
  wheels leaving individually over crests, short hops
  between the long flights. At top speed the jumps stay
  jumps.
- **Rebound/settle regression watch.** Landings — the gap,
  the staircase, crest chains — plus drops and crane
  recoveries: all re-pass staged with the rebound route
  untouched, but any new harshness, float, or second
  bounce is the regression to name.
- **The climb at cruise stays glued-but-light** — measured
  partial load, no separation; that is the honest physics
  at that curvature and speed. If you want air there at
  cruise, it is a track-shape conversation, not a model
  one.
- NOT in this pass: sections/markings, the smoke-puff /
  banner-text / visual-steering cleanups (a separate load
  awaits its own pass), the loop, the envelope, any new
  track.

## Fix Pass 22 (micro) — On Chains, the Button Drops You. Period.

Base: FP21 final (d8be713). Ordered by the owner, Fri
2026-10-30 09:17 CDT, from run 19 with the FP20 button in
his hands: "when you're being droned, Text says DRONE
LIFT, and the button doesn't release you even though
you're over track. It won't activate until the text
changes to something or other. Need to get rid of that.
If you're on chains, the button works. period. Not over
the track? Don't press the button." This corrects the
conservative reading Hal took of the owner's earlier
"moron" sentence (mid-carry press = SPENT, chains hold).
With the mechanism in his hands the owner rules the full
version: THE GATE IS THE DEFECT.

### Item 1 — the release gate is deleted

- In MODE_HANG, a drop-button press fires `_do_release()`
  in EVERY phase (attach / carry / dangle). The phase gate
  in `_press_drop_button`, the self-gate inside
  `_do_release()`, the SPENT outcome, and the felt-refusal
  grind machinery that served SPENT (pulse train, state,
  constant — it has no un-armed state left to refuse) are
  all deleted. The desktop SPACE twin follows the button:
  on the chains, any phase, it drops.
- The DANGLE path is byte-identical to FP20 — the staged
  census below is frame-identical to the FP21 baseline.
  An off-station release differs only where the crane's
  state honestly differs: it falls from where the car IS
  (the section under the car, via the wide projection,
  seeds `air_s_est` / `air_start_s` and takes the heading
  record), and it keeps the carrier's horizontal velocity
  — mid-slew the pivot is moving, and the car's world
  velocity is the pivot's plus the pendulum tip's. The
  pendulum axes stay the drop frame's in every phase, so
  the tip construction is unchanged; the FP5 slack branch
  (a dangle-only state) is untouched.
- Where it falls is the driver's business: the existing
  air/landing/recovery flow takes it from there — a
  mid-slew drop that lands drives, one that misses is
  re-recovered, no new landing rules. DRIVE/AIR presses
  are unchanged: the button answers (dull pulse + BTN
  PRESS line) and does nothing.
- Telemetry: BTN lines keep their phase tags (now always
  FIRE on the chains); the RELEASE record (s / HDG / SEC /
  ERR) fires for any-phase releases, with SEC/ERR measured
  against the section under the car at release. The grab
  log's session header now reads FP22 and its legend
  describes the new BTN semantics.

### Item 2 — the hang banner stops implying a wait

The state label's phase-variant hang text ("DRONE LIFT..."
until the dangle, then "PRESS RELEASE") was the dead
gate's visible face — and named a drone that no longer
flies. Across ALL hang phases the label now reads one
line, in the crane's name: **CRANE LIFT — BUTTON TO
DROP**. The render proof's cockpit capture shows it
legible from the driver's seat at the Drop Start dangle.
This absorbs the queued banner-rename item from the
next-pass load; the smoke sphere and the visual steering
connection stay queued separately. The commands panel's
Release line is updated in the same commit: "DROP BUTTON
(dash face) - on chains it drops you, any time".

### Staged evidence

New stage 52 carries the CARRY press and the banner:
mid-slew at a staged fall from s 900 (carrier moving,
phase carry), the press fires — BTN FIRE carry, mode
AIR; the resulting `air_vel` matches the analytic
conversion (swing tip + forward push + the carrier's own
velocity) to the printed digit; the heading record is
taken against s 741, the section under the car (the
station it never reached is 742); the drop resolves sane
(re-recovery — it fell wide of the road mid-slew, and the
crane took it again). The banner asserts identical in
ATTACH and at the dangle. Stages 34(a) and 47(d) carry
the ATTACH press (the Drop Start early press): FIRE +
RELEASE, the car leaves the chains in attach.

### Census

No drive numbers moved, and none hid: the drive census
prints are byte-identical to the FP21 baseline run
(stages 8, 12, 18, 19, 30, the stage 49 heading census —
worst ERR still 0.0° across ten families — and stage
51's AIR evidence all print the same numbers). Recovery
timings unchanged (stage 34: 605 frames trigger→dangle,
both staged falls).

### Amendments (flagged, never silent)

- **Stage 34(a)**: FP20's SPENT + grind expectations are
  REPLACED by release expectations (BTN FIRE attach, the
  heading record, mode AIR). The wheel's transport gate
  probe moves BEFORE the press (the press now ends the
  hang it was probed in), and the stage restarts after
  the press so the pendulum-continuity run rides a fresh
  hang (handover jump 0.006 rad, as before).
- **Stage 47(d)**: the SPENT-in-attach expectation is
  replaced by FIRE-in-attach; the grind check is deleted
  with the machinery; the stage restarts between the
  attach and dangle halves. **47(f)**: the grab-log file
  check now looks for BTN FIRE (no SPENT line can exist).
- The stage 22/25/44/45/46 amendments from FP20 stand as
  they were; nothing else was edited.

### Verification notes

SMOKE 468/468 on the final tree (459 FP21 baseline + 9
net new: stage 52's nine, stage 34 +1, stage 47 −1).
API GUARD 70/70. Render proof 146/146 under Xvfb from
seat trim 0 — the first two attempts failed the two
documented sandbox environmentals (the persisted 0.024
seat trim inflating the hub-drop check, and the
wires_view colour count flapping 11 → 13 → pass on
identical code, the FP18/FP20 marginal); with the trim
zeroed the hub check passes and the third attempt is
clean. Engine preflight: `--import` clean, a 10-frame
real run clean (OpenXR loader noise only — no runtime in
this sandbox, as ever).

### What you're judging (run 20)

- **Drops from anywhere on the chains.** Press the button
  during the lift, mid-slew, whenever — the car lets go
  from where it hangs, keeps the crane's motion, and
  lands where it lands. Not over the track? Don't press
  the button. Whether a mid-carry drop FEELS right — the
  swing, the drift, the fall — is UNVERIFIED-LIVE: staging
  verifies the state conversion, not the sensation.
- **The banner.** One line, CRANE LIFT — BUTTON TO DROP,
  the whole hang. The word "drone" no longer appears over
  your windshield.
- NOT in this pass: the smoke-puff sphere, the visual
  steering connection (both still queued), sections,
  the loop, the envelope.

## Fix Pass 23 — Nuke the Loop

Base: FP22 final (8aec38a). Ordered by the owner, Fri
2026-10-30 09:52 CDT, after the run-19 tape traced a
cross-country arrival at the ring resolving as TOUCHDOWN
CROSSED-UP at LAT 26.3 m/s: "the loop has been a mess
since day 1" — "nuke it, we'll deal with it later." The
loop entered FP10 as an "if they work" experiment; the
condition failed on three builds (illegible entry, run
16; presentation pass, FP12; the detonation, run 19).
The original game has no loops. "Later" means a loop may
return only on a purpose-built track with an on-line
mouth, as a designed feature — not as this spur.

### What was removed

- The spur entire: branch geometry (entry s 170, join
  s 330), the ring (R 11 m), its support path, and every
  piece of presentation — the LOOP gantry at s 158, the
  amber guide strip, the lit rim band, the descent
  chevrons, the spur's surface/skirt/edge meshes and
  stilts. Stage 21 asserts the absence structurally: no
  "spur" data on the circuit, and SpurSurface /
  SpurSkirt / SpurEdges / SpurGuide / SpurChevrons /
  GantryLOOP all null on the circuit root.
- The machinery: `_build_spur`, the spur frame and
  projection helpers, the sibling spur driver
  (`_update_drive_spur`) and spur suspension, the capture
  test in `_update_drive`, and the spur branches in the
  drive/suspension dispatch and both rebound gates. The
  FP8 sustain counter (AIR_SUSTAIN_FRAMES /
  air_load_frames) existed only for the spur since FP21
  and is removed with it. Genuinely shared machinery
  stays: `_project_wide_s` (the crane's fall origin) and
  `_build_gantry` (START/FINISH).
- The test ribbon is untouched.

### Circuit before / after

The spur was a parallel branch, and the mainline did not
move — verified, not assumed: circuit length 3319 m
before and after (stage 18), still a closed circuit at
3 laps (stage 19: DONE in 18133 frames, seam steps
identical). New stage 21 drives the home straight
through the old fork span pinned at 30 m/s: worst |lat|
0.06 m across s 150–360 — one clean line, no swerve
where the fork peeled off.

### Census

No drive numbers moved: every recorded census print is
identical to the FP22 baseline run — stage 8 (ribbon lap
46.8 s over 1163 m), stage 19 (18133 frames; seam
0.0027 m / 0.015 deg), stage 20 (10 hump flights),
stage 51 (hump air 5.59 s; the flair at FL 6 / FR 14 /
RL 6 / RR 14; the flat home straight still separates
nothing, min corner load 1.00). Honest note: the
baseline log file itself was lost when the sandbox VM
rebooted mid-pass; the comparison is against the census
values extracted from it before the reboot and the
numbers recorded in the FP22 section above.

### Amendments (flagged, never silent)

- **Stage 21**: FP10's spur runs (fork capture, ring
  continuity at 30 m/s, slow-entry detach, crane
  recovery) are DELETED; the stage is repurposed as the
  absence stage (9 checks: no spur data, six node
  absences, the clean-line drive).
- **Stage 28**: the spur's hang-clearance candidate
  samples are DELETED (guarded code that would have gone
  inert); the stage's main-track cases are unchanged
  and pass as before.
- **Stage 29**: Item 6's spur checks (merge heading
  residual, exit-leg unwind, guide strip, chevrons,
  LOOP gantry, rim band) are DELETED. Item 5 (the air
  trigger) is unchanged; the stage header is amended to
  match.
- **Render proof**: captures 17–19 (fork / ring /
  cockpit mid-ring) and 23 (descent chevrons) are
  DELETED, their tracked PNGs removed from the repo.
  The 20–22 loop-approach series is REPLACED by a
  home-straight series at the same stations
  (home_straight_100m / 50m / 20m.png), with the FP12
  amber test INVERTED: the guide-strip/rim amber family
  must now be absent from the road band — it reads
  0 px, and the 20 m frame shows grey road running
  straight to the horizon, no ring anywhere in it.

### Verification notes

SMOKE 464/464 (468 FP22 baseline − 13 deleted spur
checks + 9 new stage-21 checks, reconciled). API GUARD
70/70 — green, and it runs inside the smoke. Render
proof 134/135 under Xvfb: the single failure is the
wires_view sampled-colour count (20 this attempt; it
read 11 and 18 on two others) — and it is NOT this
pass: the pristine FP22 tree, run as an A/B control in
the same sandbox session, fails the same single check
(145/146, 20 colours). It is the documented sandbox
renderer marginal (FP22 recorded the same flap on
identical code), on this sandbox's Compatibility /
llvmpipe renderer — whose captures are not colour truth
in any case, here or on the control. The hub-drop check
needed the sandbox's persisted seat trim zeroed
(0.024 → 0), the same environmental FP22 documented;
the owner's machine is unaffected. The grab log's
session header now reads FP23.

### What you're judging (run 20)

- **A home straight with no ring on the horizon and no
  swerve in it.** Nothing else in this pass.

## Fix Pass 24 — Turbo Meter + Air Economy + Air Audit (+ smoke kill)

Base: FP23 final (1669c3e). Commissioned by the owner,
Fri 2026-10-30 09:18–09:26 CDT: a turbo meter ("im
thinking we need a turbo meter"), a refresh scheme based
on getting some good air ("start with air"), an economy
that "works on any track" - balancing track distance,
initial available turbo, drain rate and air payout - the
audit's measurements used "to devise tracks," and the
smoke blob's execution folded in by tap. Design of
record: `boost-economy.md` in the project root. The
inside-line and limit-riding earners he named were
evaluated and deliberately NOT built - one earner first.

### Item 1 — the economy

Measured before designing (the census rule): the shipped
code's whole boost ration was 60 units drained at 30/s -
exactly 2.0 s of boost per race, refilled by nothing.
The economy, all in those units (30 units = 1 s of
boost):

- CAPACITY 120 (4.0 s) / START STOCK 60 (2.0 s) / DRAIN
  30/s unchanged. The boost POWER (the +9.0 tire-force
  term) is not an economy dial and did not move.
- PAYOUT at a graded landing: air_seconds x grade x 10 -
  CLEAN 1.0, SCRUBBED 0.5, CROSSED-UP 0.2 - clamped at
  the tank. Payable flights only: racing separations
  (road lip, gap, suspension rebound - a rebound's
  second flight pays as its own landing) of at least
  0.15 s. Crane drops pay 0 (FP13's ruling, kept: the
  chains are transport, not flight); off-road flights
  never reach a landing, so they cannot pay by
  construction.
- The three dials are named constants at the top of the
  boost block - BOOST_CAPACITY, BOOST_START_STOCK,
  BOOST_AIR_RATE - the owner's tuning surface after a
  race on it.
- Staged exact (new stage 53): a staged 1.00 s CLEAN
  flight pays 10.0; SCRUBBED pays 5.0; a 0.71 s
  CROSSED-UP pays 1.42; a rebound flight pays 10.0; a
  0.12 s hop pays 0; paying 10 into 115 clamps at 120
  (5.0 lands); a crane drop's 0.40 s fall pays 0; a lost
  flight pays 0 and writes nothing; 90 boosted frames
  drain exactly 30.0.
- Surfacing: every payout writes a PAY line to the grab
  log (units, air seconds, grade); the DIAG block gains
  BOOST stock/capacity and LAST PAY lines. The DIAG
  board grows 0.34 -> 0.40 m tall, its root raised half
  the growth so the bottom edge (and its rim sightline)
  stays where FP11 put it.

### Item 2 — the meter

A fill bar on the dash face in the button cluster's row:
0.70 m wide at (0, 0.845, -0.543), the fill anchored at
the trough's left edge, built with the cockpit - on no
info panel, so it never hides. Fill = stock/capacity;
bright at full, dark at empty; a payout flashes the fill
boost-bright for 0.35 s in the moment the landing is
graded (the chunk and the flash are the ruling, seen).
Stage 53 stages the state (fill 0.50 at the stake, 0.42
after the staged payout, flash at 0.34 s on the landing
frame); render capture 25 is its portrait (staged 70%
fill, flash lit).

### Item 3 — the air audit (new stage 54)

A recorder in the sim (`debug_audit_begin/end`, hooks in
`_enter_air` and `_pay_for_landing`, inert unless a test
arms it - the shipped game never does) plus a staged
reference lap per track: pinned-24 pursuit (the stage-51
air protocol) with the proven gap-window drivers at the
gaps. It books the track's GROSS offer - grade-weighted,
before the tank clamp; the clamp is the car's state, not
the track's geography - as payable air-seconds per
250 m sector. Measured:

- CIRCUIT (3,319 m): 7.70 s payable air, 77.0 units of
  projected income per lap. The geography is one rich
  province: sectors s 2000-2250 (3.29 s) and 2250-2500
  (4.41 s) - the climb/hump country - hold ALL of it;
  the longest air-starved stretch is 2,000 m. (The
  design note's estimate was 50-80 units/lap; measured
  77.0.)
- RIBBON (1,163 m): 9.67 s payable air, 96.7 units per
  lap - the bounce garden: sectors [0.63, 2.54, 5.87,
  0.62, 0.0]; longest starved stretch 250 m.
- Every audited landing graded CLEAN under the pursuit
  driver, so both incomes sit at the all-CLEAN bound
  (air x 10). A human's grades will pay less - that is
  the economy working, not a misprint.
- This map is a tracks-pass design input: tracks get
  devised in earn/spend rhythm, and a track is not done
  until it has been audited.

### Item 4 — the smoke blob, executed

The Test-1 smoke-puff sphere is deleted outright: the
mesh (build), the trigger (the HARD landing's smoke_on),
the pulse (the visuals update) and the state -
grep-clean in main.gd, and stage 53 asserts no sphere
mesh rides the car body. The nose-dent visual is
separate and stays: a HARD landing still dents. Real
smoke, if it ever exists, belongs to the carnage build.

### Census

No drive numbers moved. Every measured print and PASS
line from this session's FP23 baseline run (SMOKE
464/464, API GUARD 70/70 on the pristine tree) is
identical in the FP24 runs - stage 8's lap, stage 19's
18,133 frames and seam steps, stage 20's flights,
stage 30's 1.31 s getaway spread (still "no boost is
paid at the drop", deltas +0.0 / +0.0), the stage 38/51
air censuses - with three stated exceptions, none of
them drive physics:

- Stage 9's wall-clock frame-time line (median us, hitch
  count) differs between runs: host timing on a loaded
  sandbox, not sim state (the 2,978 DRIVE frames and the
  raw |dy| max are identical).
- Stage 46's telemetry ring count rises 132 -> 218: the
  ring now also carries the PAY events from the graded
  landings the earlier stages fly. The new logging, not
  a behaviour change.
- Boost-active frames are the one place behaviour can
  differ by design: a refill can keep boost alive past
  the old one-shot ration. In the suite's scripted boost
  windows every trajectory and census outcome above is
  unchanged.

### Amendments (flagged, never silent)

- NO prior stage's expectations were amended. Stage 30's
  FP13 assertion (no boost paid at the drop) stands
  unamended and passes - drops are releases, and
  releases never pay.
- The one failure in FP24's first full run was stage
  53's OWN drain check (meter 39.7 against ~30): the
  measurement window opened on the warp-in transient
  the recovery hang's suspension state left behind -
  ~29 airborne frames inside the window, 61 drain
  frames, the arithmetic exact. A standalone probe
  convicted the fixture (the same warp + window from a
  settled car drains exactly 30.00 with zero AIR
  frames); the stage now settles 45 frames before the
  window and asserts DRIVE at its opening (window then
  reads 30.0, 0 AIR frames). Game code was not touched
  for it.

### Verification notes

SMOKE 496/496 (464 FP23 baseline + 31 new checks in
stages 53/54 + 1 settle-gate check added with the
stage-53 fixture fix, reconciled). API GUARD 70/70 -
green, and it runs inside the smoke. Render proof
138/139 under Xvfb: the single failure is the
wires_view sampled-colour count (19 this attempt; 18
and 18 on two others) - the documented sandbox
renderer marginal, not this pass: the Fix Pass 23
section records the same single failure on the
pristine FP22 tree run as an A/B control (counts
11/18/20), on this sandbox's Compatibility / llvmpipe
renderer, whose captures are not colour truth in any
case. Two proof findings WERE this pass, and both were
fixed before delivery:

- The first proof run's hub-drop read 0.31 m because
  the sandbox's persisted seat trim sat at 0.024 -
  zeroed, per the FP22/23 environmental note (the
  owner's machine carries his own trim and is
  unaffected); the re-run reads 0.29 m, in band.
- The grown DIAG board's first size (0.40 m) left the
  0.42 m text block overhanging its lower edge and one
  of the proof's 63 DIAG sightlines grazed. Board
  0.40 -> 0.44 m, root up 2 cm more: the final proof
  reads text 0.42 m inside a 0.44 m board, 0 of 63
  sightlines blocked.
- Louder, and caught by the same re-checks: the meter
  bar's first boxes (10/12 mm deep) went NEGATIVE under
  the dash audit's 1 cm AABB shrink - 180 engine errors
  per suite run, the two meshes silently exempting
  themselves from the audit's buried test while every
  check still "passed". The bar is now a 24 mm raised
  gauge housing; the audit covers it like any other
  mesh, and the final runs carry zero such errors.

Sandbox suite weather, for the record: attempt A died
to an engine SIGSEGV (signal 11, a
propagate_notification thread error) during stage 28
with zero FAIL lines before it - the point passed
clean on every other attempt, and the sandbox has form
for this (FP20, FP23). Attempt B completed at 495/496
(the stage-53 drain fixture, above). Attempt C was
killed silently (no banner, process gone) during
stage 54's ribbon lap after 490 green checks. Attempts
D and E ran the full suite to ALL 496 PASSED - E on
the final tree, after the bar/DIAG geometry fixes.
The grab log's session header now reads FP24.

### What you're judging (run 20)

- **The meter at speed**: a bar on the dash face in the
  button cluster's row - readable in peripheral vision,
  bright at full, dark at empty.
- **The payout feel**: land a real flight and the bar
  jumps a chunk and flashes as the grade lands; fly
  sloppy and it pays sloppy (SCRUBBED half, CROSSED-UP
  a fifth). The DIAG's LAST PAY line and the grab log's
  PAY lines carry the same ruling in writing.
- **Boost availability across a lap**: you start with
  2 s, the tank holds 4 s, and on the circuit a lap's
  income lives in one province (the climb/hump country,
  s 2000-2500) - expect to run poor on the long starved
  stretches. That is the design; the dials (stake,
  tank, rate) are yours to move after a race on it.
- **The smoke blob's absence**: hard landings dent the
  nose; nothing grey throbs in your face any more.
- **NOT in this pass**: inside-line / limit-riding
  earners, road sections, the speed envelope, any
  change to boost power or the drain rate.

## Fix Pass 25 — The Steering Connection (visual only)

Base: FP24 final (92c523b). Ordered by the owner
2026-10-29 10:04–10:05 CDT, GO given Fri 2026-10-30 09:26
CDT: "there needs to be a visual connection between wheel
and steering wheel" / "The tires are telling a story, with
their wobbling and bouncing, but we gotta see it." This
pass is PRESENTATION ONLY: no physics value moves, and the
drive census below says so in numbers.

### Item 1 — the sightline audit (measured BEFORE any remedy)

A new section of the render proof classifies a sampled
grid over each front tire's surface (86 points: both
sidewall discs + the tread band) from the shipped eye
anchor, through the fallback camera (whose frame is
NARROWER than the Quest's — the audit is conservative):
in-frame, and visible = in-frame with a clear sightline
(the FP4 local-AABB segment test against every car mesh;
the tire's own AABB counts, so its far side reads hidden,
as it should). On the shipped geometry (0.30 m tires at
WHEEL_LOCALS):

- rest: 87% in-frame, **8% visible**
- full compression: 100% in-frame, 21% visible
- full droop: 74% in-frame, 7% visible

Blockers at rest, per tire: the side pod 25 samples, the
floor 17, the dash slab 12, the tire itself 11, the nose
1. The tires were in the frame the whole time — behind
the car's own bodywork. Gain alone cannot fix what can't
be seen, so Item 4's condition was met.

### Item 4 — tire presence (the audit demanded it)

The remedy is on the tire, not the bodywork (pods, dash
and floor are untouched): the front VISUAL tyre grows to
0.33 m radius and steps 0.14 m outboard and 0.40 m
forward — the Odd Rods dragster's long nose, the Pro
promo's exposed wheels. Audit rounds, rest visibility:
radius+outboard alone 9% (the pod still walled the
sightlines); forward 0.25 m, 17%; **as shipped (forward
0.40 m): rest 100% in-frame / 22% visible, full
compression 35%, full droop 21%** — and of the surface an
eye could ever reach (in-frame minus the self-hidden far
side), roughly a third is visible at rest and half under
compression. The remaining rest blockers: the tire itself
~32, the dash slab 15, the pod 16, the floor 2.

WHEEL_RAD_F is a physics constant (it sets the suspension
attach heights) and did not move — the bigger radius is a
mesh-only WHEEL_RAD_F_VIS. The visual centre rises by the
radius growth PLUS the rake slope × the forward step, so
the visual bottom stays on the model's contact plane:
capture 20's planted-plane checks pass unamended (front
bottom 0.329 m rel road, baseline 0.330; rears still
dwarf the fronts, measured dia 0.99 vs 0.70 m). The dust
emitters keep marking the TRUE contact patch at
WHEEL_LOCALS; the travel delta the tire displays is the
model's own (susp_c − SUSP_REST), unchanged.

### Item 2 — the visual steer gain

`_steer_display_angle()` is the only reader of the curve;
the drive model keeps computing its own front_angle from
wheel_angle and never reads the display. Gain =
1 + (2.2 − 1) × (1 − smoothstep(0, 0.55, |steer|)):
×2.20 at centre, honest from 55% lock up. Staged exact
(new stage 55): a 0.3 rad wheel shows −6.45° against the
honest −3.06° (×2.10); a quarter lock in the dangle
(capture 26) shows −13.5° against −8.0° honest; full lock
shows −32.09°, the model's own −32.09°. The dangle runs
through the same gain (stage 31, amended — below): the
promise the release keeps is the one the driver saw.

### Item 3 — slip made visible

In DRIVE the display adds the slip angle
atan2(lat_vel, max(|speed|, 4.0)), honestly scaled, capped
at ±0.18 rad (10.3°): the front tires yaw toward where the
car is actually sliding. Stage 55 pokes it synchronously:
2.0 m/s at 20 m/s shows −5.71° (atan2's own −5.71°), a
leftward slide +5.71°, a violent 9.0 m/s at 6 m/s caps at
−10.31°. Airborne and hanging, the term is zero — unloaded
tires tell no slip story, the FP15 ruling in visual form.

### Census

The drive census prints are byte-identical to the FP24
baseline run (stages 8, 12, 18, 19, 30, 49, 51, 53, 54 —
lap times, air evidence, heading census, economy and both
audit geographies print the same numbers) with three
accounted exceptions, none of them physics: stage 9's
wall-clock µs annotations jitter between any two runs
(its step values and track positions are identical);
stage 2f's mesh-measured body width prints 2.08 m (was
1.92) — the outboard front tires are now the widest
meshes on the car, which is Item 4 measured, and the
road-proportion check beside it (6.0 × WHEEL_LOCALS
track) is unmoved; stage 28's carry-clearance prints read
0.44 / 0.38 m (was 0.57 / 0.51) because its merged-AABB
sampler now bottoms on the bigger, forward visual tire
during the carry — the asserted verdicts are identical
(hits 0, station brush 0, same 603 frames end to end).

### Amendments (flagged, never silent)

- **Stage 31**: the front-wheel display expectation moves
  from the honest −6.1° to the gained band around −11.4°
  (measured −11.4°). The lock, the dangle's yaw authority
  and the release checks in the same stage are unmoved.
- **The audit helper** samples WHEEL_RAD_F_VIS — the mesh
  the driver sees. The pre-remedy audit above was run when
  the shipped mesh was the 0.30 m WHEEL_RAD_F, and its
  numbers were recorded with that size.

### Verification

Smoke 503/503 (496 at FP24 + stage 55's 7), API guard
70/70. Render proof 142/144 — the 2 failures are the same
2 the UNMODIFIED baseline shows in this sandbox (137/139):
the wheel-hub reach band reading 0.31 m because this
sandbox's persisted seat trim puts the anchor at 1.284 m
rather than 1.26, and wires_view's colour count under
llvmpipe. All proof captures this pass rendered through
the sandbox's Compatibility/llvmpipe stack — structure
and geometry only, not colour truth.

### What you're judging (run 21)

The wheel↔tire connection at small inputs — a
quarter-turn of the cockpit wheel now moves the front
tires ~13.5° where it showed 8°; the tires yawing into a
slide as it begins; the new stance — bigger front tires
stepped out and forward, out from behind the pods; and
the tires' bounce reading from the seat at last. NOT in:
any feel change — there is none by construction (the
census above); any bodywork change — the pods, dash and
floor are exactly where they were; the tire moved, not
the car.

## Fix Pass 26 — The Flask, the Doubled Drop, the Raised Button

Base: FP25 final (c809233). Ordered by the owner live in
run 20/21, Fri 2026-10-30 17:00–17:02 CDT, from the
dangle: the FP24 meter read as a blue sliver behind a
wheel spoke in his own screenshot ("make it a liquid
flasky meter where one of those flat buttons is along the
dash, like the green one — sloshes around with car
movement, drains some on use"), "We need a higher crane
drop by around x2 or more," and "drop button needs to
come up." Economy constants are untouched (capacity 120,
stake 60, drain 30/s, air rate 10/unit-s): this pass moves
surfaces and geometry, not numbers he is still owed a
feel verdict on.

### Item 1 — the flask (the bar is deleted)

FP24's trough-and-fill bar is gone outright — stage 56
asserts no TurboFill/TurboTrough node exists. In its
place, a vessel in the dash-top button row at
(-0.435, 0.93, -0.60), beside the green LEAN button as
ordered: a dark base, a glass box, a collar, and the
liquid — a blue column whose LEVEL is the tank (12 mm of
heel at empty to 78 mm at full, inside the 95 mm glass).
The spot was chosen by the sightline math, not by eye:
from the shipped eye anchor, sightlines to the centre-row
spots cross the wheel plane inside the rim band (the side
button's crossing radius is 0.081 m — spoke territory);
only |x| ≳ 0.30 m clears the rim at every wheel angle,
and the flask's crossings run 0.33–0.42 m. It is NOT a
dash control — the eight-control roster is unchanged and
stage 56 asserts the flask is not among them. A gauge,
never a button.

The liquid SLOSHES on its own damped spring (stiffness
55, damping 5.2, target tilt capped at 0.26 rad), driven
by the car's measured acceleration (position-delta,
warp-guarded) against gravity, resolved in body space —
so it leans under braking and cornering, sloshes off the
humps, and hangs tilted in a banked dangle. Boosting
drains it at the drain rate's own pace; a graded payout
raises it in a chunk and lights it pale for the FP24
flash's 0.6 s (PAY lines and DIAG BOOST / LAST PAY are
unchanged). Stage 56 stages the level at empty / stake /
full, the spring's lag under a staged acceleration
(0.022 rad at 0.06 s against 0.318 at 0.5 s — it is not
a mirror; the underdamped surface overshoots its target
and comes back), and its settle (drift 0.007 rad). The render proof's capture 25 is
the flask's portrait plus the sweep the bar never faced:
520 sampled sightlines over the flask's silhouette from
the eye anchor, wheel at centre, full lock both ways and
both quarter locks — 0 blocked, worst wheel-plane
crossing radius 0.268 m against the rim band's 0.245.

### Item 2 — the drop, doubled

HANG_LEN 5.5 → 11.0 and HANG_CLEAR 1.2 → 2.05: the air
under the hanging car's wheels goes 0.85 → 1.70 m,
exactly ×2, and the station pivot rides 13.05 m over the
drop frame (was 6.70). The pendulum's lateral length
follows (PEND_LEN_L 3.9 → 7.8), so the sway slows by
√2: staged fore half-period 3.33 s (FP25 measured 2.26),
drop fall 0.58 s staged (was 0.40). The crane post
stands 14.15 m; the jib, chains and trolley scale from
the same constants. FP15's gust walk and jib flex are
untouched — same torques on a longer pendulum, which is
the brief's "same character, slower." Touchdown grading
is unchanged and stage 30's ladder proves it in the old
numbers: contact lat 0.06 / 2.31 / 5.27 m/s grading
CLEAN / SCRUBBED / CROSSED-UP, getaway spread 1.31 s —
identical to FP25's prints (see Amendments for the seed
form that preserves them).

One consequence the proof caught: at the staged diagonal
dangle (0.30 / 0.24 rad), the doubled plan displacement
flipped the diagonal lift-wire pair's order — 9 plan
crossings in the FP6 sweep, all at the fore turning
point. The fix is the spreader: _crane_corners' rectangle
is now PROPORTIONAL to the car's attach rectangle
(±0.45 × ±1.0125 against the car's ±0.60 × ±1.35), with a
visible frame mesh at the corners' plane — similar
rectangles at the same yaw cannot cross at any
displacement, and a car-sized spreader is what a real
lift hangs a car from. The sweep now counts 0.

### Item 3 — the button, raised

DROP_BTN_FACE_Y 0.70 → 0.85: the button rides the upper
dash face at (0.42, 0.85, -0.44), its bracket top flush
with the dash slab's top. Clearances, all geometric: the
rim's outer edge passes 0.11 m to its left at full lock;
its centre sits 0.44 m from the hub — outside the 0.40 m
wheel-grab radius, so a squeeze on the button can never
latch the wheel; 0.19 m from the nearest dash-top button
(zones are 0.15); 0.21 m from the flask's mirrored spot.
The grab zone, the R-fire path and the telemetry derive
from the same constants (stage 25 re-reads them); SIDE
mirroring moves the raised button, and the persisted
side setting is untouched (stages 44/46 hold).

### Census

The drive census is FP25's, number for number: stage 54
prints the circuit at 7.70 s payable air / 77.0 units /
sectors [0×8, 3.29, 4.41, 0×5] / longest starved 2000 m
in 12225 frames, and the ribbon at 9.67 s / 96.7 units in
4492 frames — the economy's geography did not move. The
hang/drop prints that honestly changed, all Item 2's
geometry: stage 42's sway means (fore 2.26 → 3.33 s, lat
1.99 → 2.84 s) and drop fall (0.40 → 0.58 s); stage 28's
carry clearances (0.44 → 1.39 m and 0.38 → 1.31 m — the
car rides its longer chains over the same route; the
asserted verdicts are identical: hits 0, station brush 0,
603 / 603 / 605 frames end to end); stage 34's recoveries
arrive in the same 605 frames (the slew is horizontal;
the stack cancels). Stage 30's t20s moved by hundredths
(2.09 → 2.16 clean, 2.59 → 2.67 seed, 3.40 → 3.47 peak) —
the longer fall's drift at the same contact velocities.

### Amendments (flagged, never silent)

- **Stage 25**: the position check's prose names the
  upper dash face; it reads the shipped constants, as
  before.
- **Stage 30**: the getaway seeds halved (-0.45/0.41 →
  -0.225/0.205; -0.80/0.95 → -0.40/0.475). The seeds
  encode TIP VELOCITIES (om × HANG_LEN, both axes — the
  release fires at the seeded om; measured on both
  geometries). A first FP26 form scaled them by the
  pendulum's frequency ratio instead and printed contact
  lat 3.24 / 7.41: the seed leg graded CROSSED-UP and the
  peak car never reached 20 m/s. Halved, the ladder
  reproduces FP25's contact velocities, grades and spread
  exactly. The swing angle the seeds ride at halves with
  them; no check reads it, and the dangle's full envelope
  is staged by stages 1/42/52.
- **Stage 42**: the sway sample window grows 2700 → 3600
  frames (the slower pendulum needs the frames for the
  same cycle count); the mean half-period band moves to
  [2.8, 3.9] around the new pendulum's own 3.33 (measured
  3.33); the drop-fall band moves to [0.50, 0.70] around
  the doubled drop's 0.59 (measured 0.58) — the film's
  0.3–0.5 s band governed the old short drop and is
  recorded as superseded in the stage, not deleted.
- **Stage 46(c)**: the hand is parked away and released
  before the rim approach. The raised button sits
  0.212 m from the staged rim point — inside the 0.25 m
  teleport cap — so the old one-poll jump's sweep started
  inside the button's zone and the FP17 arbitration
  honestly awarded the squeeze to the button. A real hand
  arrives continuously and engages at the rim, where the
  button is no candidate; the park makes the staged jump
  endpoint-tested like the arrival it stands for. The
  claim (rim latch, soft lock) is unmoved.
- **Stage 53**: the meter-identity check names the flask
  (FP24's bar mesh is the deleted subject); the stage's
  economy claims are untouched.
- **Stage 56 (new)**: pins the pendulum for its slosh
  sequence — the dangle is never still (FP15's gusts work
  it; an unpinned first form watched its rest sample
  wander 0.09 rad). The pin is test-side only.
- **Stages 28/35 comments**: the station-exemption and
  rebound-gate notes updated to the new geometry (the
  gate's drop exclusion was always the air_from_release
  flag, never the fall speed — drops now land at vy 5.8,
  over the gate's 4.5 face value, and stay excluded by
  the flag).

### Verification

Smoke 510/510 (503 at FP25 + stage 56's 7), API guard
70/70. Render proof 144/145 — the one failure is the
sandbox seat-trim artifact (the hub reading 0.31 m below
the eye), which the UNMODIFIED baseline also fails in
this sandbox whenever the persisted trim sits where the
suites leave it (A/B'd today: baseline 142/144 and
143/144 across runs, the failures moving between the hub
band and wires_view's llvmpipe colour count, which read
11–13 colours across runs; both checks pass on other
runs of identical code). One /tmp diagnostic run also
showed a single commands-panel occlusion (1 of 63) that
neither the baseline re-run nor the official run on the
final tree reproduces. All proof captures rendered
through the sandbox's Compatibility/llvmpipe stack —
structure and geometry only, not colour truth.

### What you're judging (run 22)

The flask: readable at a glance from the seat, the level
honest (half a vessel at race start), the slosh alive
without being a distraction, the drain visible while you
boost, the chunk-and-brighten when a landing pays. The
drop: twice the air under the car — the fall should READ
now (0.58 s staged) — and the sway's new slow character
on the long chains; the crane and its new spreader frame
at the doubled scale. The button: up where the hand
expects it, clear of the rim at full lock. NOT in: any
economy number (120/60/30/10 stand), any drive feel (the
census above is number-identical), and the first real
track — that is the next pass, per your call.

## Fix Pass 27 — Ditch the Green Beam

Base: FP26 final (844efb3). Ordered by the owner live in
run 22, Fri 2026-10-30 19:21 CDT, with a screenshot from
the dangle: "we need to ditch the green finish line beam,
it pops into view sometimes as you're swinging." At the
FP26 doubled station the sway gives the driver a sky full
of nothing, and then the gantry's unshaded green span
slabs across it. The span is the defect; the line was
never the problem.

### What changed

- **The banner is deleted** — both gantries, both tracks
  (`_build_gantry` no longer builds a span; its colour
  parameter went with it). Nothing about the lap changed:
  the line's s never moved, and no timing or crossing
  logic ever read the mesh.
- **The line is road paint now**: a chequered stripe
  across the full 12 m width at the line's s, 1.0 m deep
  (2 rows × 12 cells of 1.0 × 0.5 m), riding the edge
  strips' +0.02 lift, built with `_add_quad_m` in the road
  mesh family so it inherits the FP18 winding-correct
  rendering (`TrackLine`, unshaded like the edges).
  Chequer over plain, on the record: at racing pace the
  band strobes black/white across the whole width —
  unmistakable for a line, where a plain band could read
  as another surface treatment. The circuit wears one
  stripe at s 2 (start IS the finish); the open ribbon
  wears two, s 2 and len − 2.
- **The posts stay** — on geometry, not nostalgia. They
  stand at ±(HALF_WIDTH + 0.4) at the line's own s: beside
  the dangling car, never overhead. Stage 57 measures it
  from the Drop Start dangle eye across seven staged sway
  samples: worst post-top azimuth **54.1°** off the
  forward axis, worst elevation **22.6°** (against the
  car's own up, so the sway tilt inflates it). The banner
  sat dead ahead spanning the width; a post 54° off-axis
  is trackside furniture in the crane post's family. The
  render proof's new capture 23 (`finish_line_view.png`,
  driver's seat 8 m before the seam) shows the result:
  chequer band across the road, a post flanking each
  edge, clean sky.

### Amendments (flagged, never silent)

- **Stage 57 (new)**: no Gantry child is a span on either
  track (every member post-sized); the TrackLine mesh
  carries near-white AND near-black chequer vertices at
  the line's s on both tracks (nearest stripe vertex
  0.020 m from the line centre); the post sightline
  geometry above. Its elevation bound is 30°, moved from
  a 20° first form on the stage's own first run, which
  measured 22.6° — the mechanism (car-space elevation
  under sway tilt, at 54° azimuth) is recorded in the
  stage's comment. The azimuth bound (50°) never moved.
- No prior stage's expectations were amended; no prior
  stage asserted the banner's presence anywhere (the
  smoke's "gantry rule" is the drop-station rule, a
  different thing, untouched).
- Render proof gains capture 23 and two checks: chequer
  presence in the road band (sampled white 362 / black
  385 px against bounds of 8 / 4) and banner-green
  absence in the sky band (0 px).

### Verification

Smoke **515/515** (510 at FP26 + stage 57's 5), API
guard **70/70**. Drive census frame-identical, proven by
diff against a baseline smoke run on the pristine FP26
tree in the same session (510/510 there): every baseline
PASS line appears identically in the FP27 run, and with
wall-clock annotations normalised the only differing
evidence print in the entire run is stage 57's own new
line. Render proof **148/149**; the one failure is the
wheel-hub reach band (0.31 m), A/B-proven a sandbox
seat-trim artifact — the pristine FP26 tree, run as a
control in the same session, fails the identical check
at the identical value (144/145). All proof captures
rendered through the sandbox's Compatibility/llvmpipe
stack — structure and geometry only, not colour truth.

### What you're judging (run 23)

A finish line you cross, not one that falls across your
sky. Nothing else in this pass.

## Fix Pass 28 — The Feature Lab

Base: FP27 final (fa48206). The owner's method call,
2026-10-30 19:26 CDT, after the sector plan for Track 01
died ("scrs tracks are probably no good for our
physics"): PROTOTYPE-FIRST. Candidate features are built
as test pieces on a lab course, driven and judged one at
a time; Track 01 gets assembled only from what proves
out. This pass builds the lab. It does not build
Track 01.

### What changed

- **A third track: `lab`** — an open 2,684 m course in
  the roster (circuit → ribbon → lab → circuit, on the
  dash TRK button and V), staged in empty country well
  clear of the other two tracks. A 90 m head flat carries
  the Drop Start; eight pieces follow in sequence, each
  approached from its own flat, unbanked entry, each
  wearing a roadside board — PIECE 1 … PIECE 8 — so a
  verdict names a piece, not a vibe. The lab wears the
  born-in section rhythm: transverse section stripes
  every 15 m across the full width, plus the FP27 dashed
  edges and chequer start paint. Drop Start at the head
  and crane recovery throughout are the FP26 furniture
  at the doubled height, unchanged (the staged recovery
  dangle floats the car 2.05 m over the road, origin
  height — wheels at the doubled 1.70 m clearance).
- **The circuit and the ribbon are not touched.** Their
  build code paths are byte-identical; the smoke census
  below is the proof.
- **The FP24 audit learned to itemise**: flight records
  (start s, seconds, payout) are now kept alongside the
  totals, so the audit reports payable air PER PIECE
  (stage 58's table). Stage 54's totals and prints are
  unchanged.
- **One old stage amended, flagged**: stage 11a's
  held-grip sweep fired the TRK button once and expected
  the circuit; with a third track in the cycle that fire
  now lands on the lab. The sweep now proves the lab is
  the cycle's middle stop, releases the grip (the FP9
  latch clears only on release), and fires again to land
  on the circuit — the stage's original evidence line is
  unchanged, and it now covers the lab's roster seat too.

### The eight pieces (stage 58 drives each one; audit = one continuous lab lap)

| # | Piece | Span (m) | Entry | Geometry | Measured behaviour (staged) | Payable air / lap |
|---|-------|----------|-------|----------|------------------------------|-------------------|
| 1 | Drumbeat rows | 90–564 | 24 m/s pinned | Three hump rows: sharp-small (7°), the ribbon row (11°, the FP21 control), sharp-tall (13°) | Rows fly 5 / 6 / 4 times, totalling 2.71 / 5.02 / 4.51 s; primaries run 0.64–1.10 s. **The 0.1–0.4 s band is populated by the rebound second flights (0.18–0.33 s), not the primaries** — on this car the drumbeat lives in the rebound | 13.52 s (135 units) |
| 2 | The flair, formalised | 624–873 | pursuit | Two banked sweepers whose banks unwind across the exit (R60/+26° mild; R45/+34°, the run-18 spec) | The unwind lifts the falling-side wheels only — corner air [FL 0, FR 12, RL 0, RR 13] mild, [0, 4, 0, 7] run-18 — never the whole car | 0.00 s — two-wheel air is not flight; the flair pays nothing |
| 3 | Crest launches | 928–1248 | 30 m/s pinned | Three launch ramps, +8° / +14° / +20°, slope-matched landings | Flights 1.54 / 2.28 / 2.99 s; launch pitch +7.2° / +12.9° / +18.8°; **peak pitch equals launch pitch in every flight** — the flight model only ever drives the nose down (to ≈ launch − 28°), so this car cannot pitch over, however violent the crest. Tumble country is a model question, not a track question | 8.07 s (81 units) |
| 4 | The chasm | 1383–1451 | 30 m/s pinned | 28 m gap (s 1384–1412), +10° launch lip (the ribbon gap's proven shape, stretched), −3.4° landing side | Crossed CLEAN at the pinned 30: 0.97 s gap flight in both the piece drive and the audit lap. Feasibility is not marginal at the stated entry | 0.97 s (10 units) |
| 5 | Off-camber S | 1511–1717 | 24 m/s (see note) | Two R≈70 corners, bank ∓10° ADVERSE | The adverse bank spends g·sin10° ≈ 1.7 of the 11.0 grip budget: at-limit entry is ≈25.5 m/s by the arithmetic. Staged at a capped pursuit 24 (demand 9.9): survives, \|lat\| ≤ 1.05, real slip (peak 0.26). The staged speed law is curvature-only and cannot know the bank is adverse; pin fixtures can't stage it at all (a pin zeroes the slip velocity every frame) — the limit is the owner's to find | 0.00 s (no air — attention only, as designed) |
| 6 | Compression → rebound | 1772–1844 | 28 m/s pinned | −10° dip into a +14° crest, FP14-tuned | Dip flight 1.06 s → rebound 0.26 s; crest flight 1.44 s; the dip compresses the car to −0.195 m heave. The crest's own rebound second flight (0.84 s, 0.57× — the film band) fired in this pass's probe and is phase-sensitive in staging (stage 51's documented behaviour): present some runs, absent others | 3.64 s (36 units) |
| 7 | Edge slalom | 1899–2139 | 24 m/s | Flat; marker blocks ON the edge line (lat ±5.85) every 30 m | Parked on either edge line the car stays supported at lat ±6.38 and rolls toward the void (0.46 / −0.16). (First form probed with markers at ±4.7: a car centred on one never straddles anything — outside wheels 0.5 m inside the edge, fully supported. The markers moved to the edge line.) | 0.00 s |
| 8 | The taxed straight | 2174–2624 | 40 m/s pinned | 225 m of ±3° swells, then 225 m of ±6° at a sharpened crest rate | The gentle half only heaves — zero flight at 40. The sharp half hops: 5 flights, 4.18 s in the piece drive. No cruising even on the spend straight (Law 1) | 4.54 s (45 units) |

Lab lap totals (audit): 32.37 s payable air, 324 units
of income against the 60-unit start stake —
the lab is rich by design; it is a tasting menu, not a
race. The unattributed remainder is 1.62 s (crest 3's
rebound second flight starts ~97 m past piece 3's
recorded end, in the long settle — see below). Economy
constants are unchanged (capacity 120, stake 60, 10/s).

### In-pass redesigns (probed first forms that failed, and what replaced them)

- **Piece 1's bracket**: the first form bracketed
  amplitude at sinusoidal gentleness — the gentle row
  never unloaded at all (v²κ ≈ 8.9 < g) and no primary
  anywhere landed in the 0.1–0.4 s band. The bracket now
  varies sharpness (walk rate), and the band finding
  above is the measured result.
- **Piece 5's radius**: R≈55 at ∓10° adverse demanded
  12.2 > 11.0 at the staged entry — the staged driver
  slid off and hung. R≈70 brings the demand to 9.9 at 24
  with the limit entry at ≈25.5.
- **Piece 8's second half**: sinusoidal ±6° at the
  gentle rate measured ZERO air at 40 (v²κ ≈ 7.5 — heave
  only). The crest rate doubled (κ ≈ 0.0095); it hops.
- **Piece 4's entry, twice over**: the settle after
  piece 3 first returned the −20° landing pitch at the
  default rate — still −3.2° sixteen metres before the
  lip, the lab's one un-flat entry; the return is now
  explicit (0.020). Then the audit lap convicted the
  settle's LENGTH: crest 3's flight lands ~52 m past
  piece 3's recorded end and its rebound carries ~45 m
  more, so on the 55 m settle the lap was still
  mid-rebound when the lip arrived, separated at the
  lip's base with a flat pitch, and dropped into the
  chasm. The settle is 125 m: touchdown, rebound, and a
  settled ground run all complete before the lip. The
  pieces must not overlap when driven continuously.
- **The audit's chasm window**: stage 54's fast+boost
  idiom is speed-managed — it reads the lip's κ in its
  46 m lookahead, caps itself at 24 and brakes toward
  it, arriving near 17 m/s and dropping in. The window
  now drives the piece's stated entry (pinned 30), as
  the piece drive proves. The ribbon's 24 m gap never
  noticed the idiom's cap; a 28 m chasm does.

### Verification

- Smoke: **ALL 559 CHECKS PASSED** (was 515; +44 =
  stage 58's 43 and stage 11a's new middle-stop line).
  API guard: **ALL 70 CHECKS PASSED**. Zero script
  errors.
- Census: every circuit/ribbon evidence line is
  identical to the FP27 baseline except two run-variance
  lines (stage 9's wall-clock frame timing; stage 46's
  telemetry event count 218 → 220, both passing — the
  phase-sensitive rebound variance documented since
  FP21) and the additions above. No circuit or ribbon
  physics, geometry, or behaviour changed.
- Render proof: 151 of 152 checks passed, incl.
  capture 27 (lab_drumbeat_view.png — the PIECE 1
  approach: board on the right, section stripe in the
  foreground, the first row ahead). The one failure is
  the pre-existing sandbox wheel-hub reach artifact,
  present identically in the FP27 baseline proof on
  pristine FP26 code — not an FP28 regression.
  Captures render through the sandbox's Compatibility /
  llvmpipe pipeline: structure and geometry evidence,
  NOT colour truth. The board amber and stripe grey are
  the device's to judge.

### What you're judging

The lab, one piece at a time (TRK button or V cycles to
it). Eight pieces, each from the same clean entry:
which does the car love? Piece 1: three drumbeat rows —
which gentleness sings, and does the rebound-band
finding hold in your hands? Piece 2: the flair at two
severities. Piece 3: three crest launches — and the
standing question behind them (the staged car cannot
pitch over; if you still feel it SHOULD at the violent
one, that's the flight-model conversation, now with
numbers). Piece 4: the chasm at 30. Piece 5: the
off-camber S — its limit sits at ~25.5, find it. Piece
6: the dip-and-crest pair. Piece 7: threading the edge
markers. Piece 8: the taxed straight at boost pace.
Strike the dead, keep the proven — Track 01 is assembled
from the survivors only. Not in this pass: Track 01
itself, the desert setting's dressing (the lab is
deliberately bare country), any physics or economy
change.

## Fix Pass 29 — The Wheel, Rebuilt (steering semantics)

Base: FP28 final (4171a87). The owner's ruling,
2026-10-31: after driving the lab he named steering as
the problem before anything else — "trying to reapply
your grip, or readjust, just feel futile and you feel
control rapidly slipping away… even pressing the red
button is dangerous because you have to quickly grip
the wheel again and it may not be at a great angle" —
and the root cause in his own words: "the problem is,
as a player, you're holding nothing." A research pass
(the field's shipped behaviour for virtual wheels)
supplied the spec; he picked the rebuild over the
VTOL-tilt and stick-primary alternatives (the stick
became an option inside it — his addition: "thumbstick
driving should be an option for people"). This pass
changes INPUT SEMANTICS ONLY: the car model, tire
physics, the FP25 wheel visual/gain, the economy, the
crane and all three tracks are untouched.

### What changed

- **Hold state (Item 1).** The ungripped bleed is
  deleted: through FP28, a released wheel in DRIVE was
  centred by THREE stacked terms — _poll_grab's 1.6
  rad/s move_toward running in BOTH hand polls (3.2
  rad/s effective) plus the desktop block's 2.2 rad/s,
  which ran in XR too. At a half-second button press
  the wheel could unwind ~45° mid-corner while the
  driver blind-grabbed for it: the "control rapidly
  slipping away" of the report, in code. No shipped VR
  wheel game found auto-centres at a fixed rate with
  the hand off; the documented behaviour is hold-state
  (a real car's self-centring is caster torque —
  speed/load-dependent, ~zero standing still). Now: in
  XR an ungripped wheel holds its angle EXACTLY, and
  the desktop steering block (keys + its 2.2 rad/s
  DRIVE centring) is gated to the desktop path, where
  its behaviour is byte-identical to before.
- **One-step regrip (Item 2a).** FP17's ownership law
  (a dash latch ends only on grip release) made the
  press-a-button-then-steer sequence two steps:
  release, re-squeeze. Repealed for the wheel: a
  gripping hand that owns a dash latch, has left every
  dash zone, and arrives inside the wheel's radius
  takes the wheel in the SAME poll; the latch ends
  cleanly as part of the transfer (a seat latch writes
  its REL record from the transfer; nothing is left
  stuck "fired"). The arrival test is zone-exit plus
  radius, never radius alone — the dash-top row lives
  inside the wheel's 0.40 m radius, so a hand still ON
  its button (the SIDE hold above all) keeps its latch,
  and the seat levers (0.82 m from the hub) are never
  stolen mid-trim. The reverse stays sticky: a hand
  DRIVING the wheel is never taken by dash proximity
  (stage 47(b), unchanged).
- **Clamp absorption (Item 2b).** Turn past the ±PI
  lock and the steering reference advances WITH the
  hand while the wheel sits pinned — the clamped
  excess is absorbed into the reference — so return
  travel bites on the first degree back. No dead
  unwind. (Both steering modes: single-hand
  grab_prev_ang and the two-hand line_prev_ang.)
- **Two-hand line steering (Item 3).** With a passenger
  on the rim, the steering delta is the change in the
  clock angle of the LINE between the two hands about
  the hub axis (the documented two-hand model:
  translating both hands together does not steer;
  either hand orbiting does). Join re-bases the line
  reference at the join frame; leave re-bases the
  remaining hand's around-hub reference at the leave
  frame — staged jumps: 0.000° both ways. A hand
  within 0.06 m of the hub axis freezes the reference
  (a crossing hand's line is degenerate); the exit
  re-bases — staged hub-cross spike: 0.000°. Haptics:
  a small tick on the joining/leaving hand, and a soft
  pulse on any wheel release, lighter than the grab's
  (release confirmation is half of what a rim tells
  you; whether any of it is perceptible on the rig is
  UNVERIFIED — the owner's ears-and-hands rule).
- **Stick fallback + STEERING MODE (Item 4).** The
  RIGHT thumbstick's primary X axis is a steering RATE
  input (2.6 rad/s at full deflection — the desktop
  keys' rate; 0.12 deadzone); the angle HOLDS when the
  stick centres. It substitutes for the wheel exactly
  where the wheel is live (drive, air, the dangle —
  the pre-dialled lock included) and only while no
  hand grips: a grab seizes mid-frame (the stick poll
  runs after the grabs), releasing hands authority
  back with the angle held — last touched wins, no
  jump in either direction, because the stick only
  ever ADDS rate to the held angle. The persisted
  STEERING MODE (user://settings.cfg, "steer"/"mode",
  beside the seat trim and drop side) names the
  at-rest authority: WHEEL (default — the stick is the
  fallback) or STICK (the stick is the primary; a grab
  still seizes). Toggled by HOLDING the right A button
  in the hang for 0.8 s — the Y restart's own gesture,
  in the mode where A has no other job — or the
  desktop N key; the flip is announced on the
  touchdown readout and written to the grab log. The
  DIAG WHEEL line gains SRC <live source>/<mode>, so
  a screenshot states what was steering.
- **Drop to X (Item 5).** Left X in the hang fires the
  release — its own event line (LX DROP FIRE), the
  detent pulse, _do_release — in every hang phase
  (FP22's law), the dash button's exact outcome with
  the hand never leaving the wheel. X's prior jobs are
  untouched: the hang press still writes its BTN-log
  note, and the DRIVE crane call stands (the modes
  never overlap; X keeps both jobs). The physical
  dash button remains fully functional.
- **Commands list** (panel): the steering line now
  names the stick, the release line names X, a steer
  mode line names the A-hold, and the desktop line
  names N. Every accepted input is listed, per the
  standing rule.

### Census — the stages that changed, and only those

Baseline FP28 smoke re-run on the untouched tree this
session: ALL 559 PASSED (guard 70). The FP29 run's
evidence lines were diffed against it line by line:

- **Stage 32 (amended, flagged)**: "X in the hang is
  inert (the crane call is DRIVE-only)" is replaced —
  X now DROPS in the hang (LX DROP FIRE + the RELEASE
  heading record in the stage's own events), the press
  is still named in the hang input log, and the stage
  re-dangles so its boost-arming checks run in the hang
  they were written against. Old expectation: mode
  stays HANG/dangle after the press. New: mode AIR,
  then DRIVE, then a fresh dangle. (+3 checks net.)
- **Stage 47(e) (amended, flagged)**: FP17's "a
  dash-latched hand cannot take the wheel mid-squeeze"
  is replaced by the new law — the seat-latched hand
  arriving at the rim takes the wheel in the same poll
  (WHEEL LAT), the transfer writes the SEATUP REL, and
  the hand steers +0.30 rad on the next poll. (+1 check
  net.) The rest of stage 47 (a1/a2/b/b2/d) is
  byte-identical: a free wheel is still not latched by
  a pressing hand (the press is not an arrival), and a
  held wheel still cannot press.
- **Stage 46 (printed value only)**: its telemetry
  check prints the SESSION ring's cumulative size;
  the count moved 220 -> 223 on the strength of the
  new event lines the amended stage 32 writes (LX
  DROP FIRE + RELEASE and kin). The assertion itself
  is unchanged and passes.
- **Every other stage is byte-identical** — same
  verdicts, same measured values (this run's diff
  shows not even the usual stage-9/stage-46 run
  variance). In particular, NO existing stage's
  scripted driving releases the wheel mid-drive
  through the grab path and reads the angle afterwards
  (the drive stages poke wheel_angle directly or hold
  it every frame), so the hold-state repeal has no
  other staged expectation to re-derive; stage 31's
  dangle hold ("releasing the grip keeps the lock
  dialled") already lived outside the bleed's
  DRIVE-only reach and is unchanged.
- **New: stage 59** (31 checks) — the pass's own
  proofs, listed in the brief: toggle input +
  persistence, X-drop, STICK from rest / seize /
  return, HOLD (a lock dialled at a pinned 20 m/s,
  released, and bit-exact after 240 ungripped polls),
  one-step regrip, clamp absorption (pin at PI, +30°
  absorbed, −10° answers with −10°), the line (join
  0.000°, +30° of line = +29.8° of wheel, leave
  0.000°, hub-cross frozen with a 0.000° exit), and
  the WHEEL-mode fallback (rate-exact +1.30 rad per
  0.5 s at full stick, centre holds, grab seizes with
  zero jump). API guard gains XRController3D
  .get_vector2 (71 total).

### Verification

- Smoke: **ALL 595 CHECKS PASSED** (was 559 baseline).
  API guard: **ALL 71 CHECKS PASSED**. Zero script errors;
  the preflight audit (grammar parse + inference scan
  of every changed hunk) is clean, and both scripts
  pass the engine's own analyzer check.
- Render proof: **151 of 152 checks passed; the one failure is the pre-existing sandbox hub-reach artifact ("wheel hub 0.31 m below the eye"), identical in the FP28 baseline proof — not an FP29 regression** (any failure named
  and compared against the FP28 baseline proof's
  pre-existing sandbox artifact). The proof itself
  convicted two FP29 defects on its first run, both
  fixed in-pass: (1) the commands panel's text had
  grown past its board (1.46 m of text on the 1.24 m
  board, 4 of 63 text sightlines occluded) - the
  label's pixel size takes the FP12 remedy again
  (0.00105 -> 0.00084; the text now measures
  0.54 x 1.16 m, 0 sightlines blocked); (2) the
  both-hands capture's staged driver move vanished
  whole (delta 0.0) because the line reference was
  based at the driver's next poll instead of at the
  join - the reference is now born in
  _update_rim_attach, at the attach instant, and the
  capture's expectations are re-derived under the
  line law and flagged in place (one hand moving
  0.5 rad about the hub with the other fixed turns
  the wheel by the chord delta, measured 0.25 rad;
  the passenger rep rides exactly that).
- UNVERIFIED (XR layer, by design): whether the
  hold/one-step/line semantics FEEL right in the
  headset; stick steering feel and the 0.12 deadzone;
  haptic tick/pulse perceptibility; the DIAG SRC
  field's legibility in situ; panel line lengths at
  the new wording. Headless stages prove the logic on
  synthetic poses/states; the verdict is the owner's,
  in the seat.

### What you're judging

The wheel, from your hands only. Let go mid-corner:
the lock HOLDS — the car keeps the line you left it
on instead of unwinding toward centre while you
blink. Press the red button (or don't — X drops you
now, hand never leaving the wheel) and come back:
one squeeze on the rim and you are steering, no
release-and-regrip two-step, and the wheel is at the
angle your hand expects. Turn past the lock and the
first degree back bites. Put both hands on: the line
between them steers, and hands joining, leaving, or
crossing the hub never jump the wheel. And the
option, for you or for anyone who'd rather: hold R A
in the hang to flip STEERING MODE to STICK and drive
on the right thumbstick — the angle holds when you
centre it, and grabbing the wheel still seizes
steering for exactly as long as you hold it. Not in
this pass: any change to how the car itself drives —
same tires, same gain curve, same economy. If the
car feels different, it is because the wheel finally
stays where you put it.

## Fix Pass 30 — The Wheel Is Live for the Whole Hang + The Centre Gauge

Base: FP29 final (3a3a912). The owner's field report,
2026-10-31, minutes after the FP29 verdict ("steering
is much better"): "the steering wheel still doesn't
work during the first phase of being craned. It
activates well into the process." Convicted in code:
the FP13-era gate — the wheel live in DRIVE, in AIR,
and in the hang ONLY at the dangle — with the same
dangle term in the FP17 arbitration candidate and the
FP29 stick poll. During attach and carry the per-hand
update returned early and cleared the grab. It is the
drop gate's sibling (FP22 repealed that one under the
FULL MORON CLAUSE): a physical control never freezes;
context decides what an action DOES. It survived FP29
only because that brief was drive-phase semantics.

### What changed

- **The whole hang (Item 1).** All three gates now
  take MODE_HANG unconditionally. Grab, steer,
  two-hand line and stick behave in attach and carry
  exactly as they do at the dangle. The car's heading
  during attach/carry stays crane-driven — wheel
  input there is cockpit state only and touches
  neither the carrier, the sway, nor the release
  mechanics. And since neither the release nor the
  landing ever reset wheel_angle, the lock dialled
  during the ride up is the lock the landing inherits:
  pre-setting the landing lock on the way up is now a
  thing the driver can do, from the first second of
  the lift.
- **The centre gauge (Item 2).** Interim
  instrumentation, the owner's words: "The steering
  wheel needs a centering line until we get the tires
  looking a little better." A rally-style band wrapped
  on the rim at its 12 o'clock — 48 mm of arc, proud
  of the rim tube on every face, in the hub's own
  unshaded amber — lives INSIDE the spin node, so it
  rotates with the wheel exactly and its clock
  position IS the lock readout, in the dangle too. A
  small near-white tick fixed to the tilt node stands
  at top centre just off the rim's driver-side face:
  stripe-vs-tick offset reads as an angle — a gauge
  pair, not just a stripe. No physics, no input
  change. (Observed in the proof captures: at full
  lock the stripe sits at 6 o'clock, below the
  fallback camera's frame — the inverted spokes carry
  that read; a glance down finds it in the headset.)
- **Audit hardening (in-pass conviction).** The
  first FP30 smoke run passed every check but carried
  90 engine errors the baseline did not: the dash
  audit grows every car mesh's AABB by −0.01, and the
  new tick — 14 mm wide — grows to a negative AABB,
  which has_point rejects with an error (and a
  meaningless test: nothing can sit 1 cm inside a
  14 mm mesh on that axis). The audit now skips
  degenerate shrinks; every pre-FP30 mesh takes the
  identical path and the audit's verdicts are
  unchanged.

### Verification

- Smoke: **ALL 624 CHECKS PASSED** (FP29 baseline
  re-run this session: 595). API guard: **ALL 71
  CHECKS PASSED**. New stage 60 (28 checks) stages
  the whole claim through production paths: grab +
  steer in ATTACH (+0.50 rad), a rim passenger and
  the line in attach (+0.30 rad, join jump 0.000°),
  the grab surviving attach→carry with steering in
  CARRY (+0.30 rad), the dialled 1.10 rad crossing
  the release bit-exact and the landing at 1.1000,
  the stick at rate in attach, and the gauge's
  parentage + 1:1 tracking (stripe at wheel_angle −
  PI/2, r 0.205 m, tick pinned, at four locks). Stage
  34's FP13-era expectation ("the wheel does not grab
  during transport") is REPLACED and flagged in
  place: the probe now asserts grab + steer in
  transport. Census diff vs the baseline, check line
  by check line: the only differences are that
  flagged replacement, stage 60's additions, and
  stage 46's printed telemetry ring count 223 → 225
  (the amended probe's WHEEL LAT/REL events entering
  the ring; the assertion unchanged — the knock-on
  class FP29 documented for its own stage-32
  amendment). Every other baseline line identical.
- Render proof: **162 of 163 checks passed; the one
  failure is the pre-existing sandbox hub-reach
  artifact ("wheel hub 0.31 m below the eye"),
  identical in the FP29 baseline proof this session
  (151 of 152, same single failure).** Captures
  28–30 are the gauge's portraits — the dangle at
  centre, quarter lock and full lock from the eye
  anchor — with the stripe's displacement off the
  tick asserted equal to the staged lock (measured
  +0.00 / +0.79 / −3.14 rad).
- UNVERIFIED (XR layer, by design): whether dialling
  the lock during the ride feels right; the stripe
  and tick's legibility at cockpit distance in the
  headset (the sandbox's captures are llvmpipe
  structure evidence, not colour truth); whether the
  gauge earns its keep until the tires read better.

### What you're judging

From the first second of the lift, the wheel is
yours: grab it on the pad, steer it on the ride up,
and set the landing lock while the crane is still
slewing — the drop lands on the angle you dialled,
not the one you had time for at the dangle. And the
amber stripe against the white tick is your centre
reference while the tires are still hard to read:
stripe over tick is a straight wheel, wherever the
stripe sits is where your lock is. Not in this pass:
any change to the crane, the car, or the drive — if
the ride feels different, it is because your hands
are allowed on the wheel for all of it now.

## Fix Pass 31 — Lean, Nuked (the mechanic deleted whole)

Base: FP30 final (f430bb2). The owner's order,
2026-10-31: "nuke lean and the blue lean indicator."
No A/B, no measurement — decided. The lean experiment
(body lean feeding a grip multiplier, in since the
first test build) went in before FP21's per-corner
load physics made load transfer real; with the loads
honest, the ×1.25 factor was a second, fictional
load system riding on top, and a control that does
~nothing is the decorative-control defect. It is
deleted whole: input, state, effect, indicator.

### The touchpoint inventory (what "lean" touched)

- **Input.** The green dash button (dash kind "lean",
  second in the roster, at (-0.52, 0.95, -0.60)) —
  roster entry, arbitration candidacy, press handling
  and the button mesh itself; the desktop twin T
  (toggle) and Q/E (lean body left/right). No other
  binding existed.
- **State.** lean_on, lean_neutral_x, lean_value,
  grip_mult, the test_lean staging hook, and the
  functions _toggle_lean, _capture_lean_neutral
  (called from the seat anchor and the hang setup),
  _update_lean_reading, _lean_effective, _grip_for.
- **Persistence.** NONE — lean was never persisted:
  the settings file only ever carried seat trim, drop
  side and steering mode. A file carrying the orphaned
  key loads cleanly (the loader reads only known
  keys); the orphan is TOLERATED on load and SCRUBBED
  on the next save, which rewrites the file from live
  state. Both halves are proven in stage 7.
- **Model effect.** grip_mult biased the lateral
  bleed term, the FP15 telegraph ratios, and the
  contact-patch long-cap budget. With lean OFF
  _grip_for returned exactly 1.0, so deleting the
  factor leaves the car in what was the lean-OFF
  behaviour everywhere — no retune, no re-derivation.
- **View effect.** The view spring's added roll term
  (-lean × 10° × 1.25 gain) is gone; the constants
  LEAN_VIEW_GAIN and LEAN_TILT_STEP_DEG go with it.
- **Reporting.** The DIAG block's "LEAN EXP / GRIP"
  line, the ZONE row's LEAN slot, the commands list's
  "green lean" entry and the desktop T / Q/E lines.
- **The blue indicator.** lean_needle — a lone cyan
  box (0.2, 0.9, 1.0) riding car_body at the dash,
  its x driven by the lean reading. It had NO housing
  or backing of its own — the mesh was the whole
  indicator — so the mesh and its update path are
  simply gone; nothing else shared the spot. The
  flask beside the vacated button does not move
  (stage 7 + render proof assert FLASK_POS exactly).

### Census disposition

A pristine FP30 baseline (624 checks) was run first;
the FP31 log was diffed line by line against it.
**Only stage 7/7b ever staged driving with lean ON**
(the A/B: grip x1.28 into the bank, x0.75 against).
Every other stage that touched lean used it as a
generic dash observable with the reading at zero —
grip exactly 1.0 — so their driving expectations
are the lean-off behaviour already. Amended lines,
one by one, each flagged in the test source:

- **stage 7/7b** — REPLACED: the four A/B checks give
  way to eight deletion proofs (no lean properties,
  no lean methods, roster of seven without "lean",
  the vacated spot inside no control zone, gripping
  there changes nothing, neither the needle cyan nor
  the button green survives on any cockpit mesh, the
  orphaned settings key tolerated/scrubbed, and the
  bank view roll is the suspension roll alone).
- **stage 5 / stage 30** — roster prints lose "lean"
  (the checks compare the live roster; mechanical).
- **stage 11a/11b/11c, 15, 33, 46(a), 59(vi)** — the
  generic dash observable moves from LEAN to VIEW
  (same machinery, same event counts; stage 46's
  telemetry ring holds at 225 events). Stage 11c and
  stage 33 each gain one restore check so later
  stages inherit the view mode they expect.
- **stage 15** — the per-button reach record loses
  its lean line (the button is gone; seven remain)
  and the ZONE printout loses the LEAN slot.
- **stage 22** — registration indices move by the
  deletion (seat levers 3/4 → 2/3, VIEW 5 of 8 →
  4 of 7).
- **stage 25** — print only: the drop button is idx
  6 of 7 (its check was always computed).
- **stage 44** — SIDE is sixth of seven, DROP last.
- **stage 56** — the flask check's roster size 8 → 7.

**Every other census line is byte-identical** —
including all driving, flight, landing and lab-audit
expectations. That is the behavioural proof: the
car everywhere behaves as the old lean-OFF car,
because in staging it almost always was.

### Numbers

- Baseline FP30: smoke 624/624, API guard 71/71.
- FP31: smoke 629/629, API guard 71/71, render
  proof 163/164 (the one failure is the
  pre-existing sandbox llvmpipe hub-reach artifact,
  identical on the FP30 baseline). The dash captures
  (dash_top_view.png) show the green button and the
  cyan needle gone and the flask where it always was.
- No *.uid or *.png.import sidecars in the commits.

### What you're judging

Two absences. On the dash, the green button is gone
— the row runs restart, flask, track, seat, view,
side, drop, with nothing dead left behind. Above
the dash, the cyan lean needle is gone. Everything
else should feel exactly as it did: the car is in
what was always its lean-off state, so if a corner
feels different, that is a bug in this pass, not the
deletion working as intended. Not in this pass: the
landing-sink work, the dash-button view nudge, and
the FP30 items still awaiting your verdict (wheel
live through the whole hang, the centre gauge).

## Fix Pass 32 — The Landing

Base: FP31 final (1bc901d). The owner's conviction,
from his FP29-build lab-lap video (2026-10-31):
landings feel "flat and rigid when hitting road" —
"isn't sinking down." Forensics on the capture agreed
twice over: dense frames show no visible body sink at
contact, and the audio track's level at every
touchdown is indistinguishable from mid-flight —
there was no landing sound at all. The model's facts
convicted the mechanism: SUSP_TRAVEL is 0.34 m, but
FP5's touchdown initialiser set compression INSTANTLY
as a state (c = rest + vy × 0.045 × axle factors),
so the stroke existed on paper and never in time.

### Item 0 — the measurement (staged probe, published)

Protocol: ribbon start straight, car warped and
settled, rolling camera baseline sampled, then a
staged arrival through the production `_land` at
three severities; 270 frames at 90 Hz per case.
Body sink = peak mean compression over rest; camera
sink = rolling camera height over its post-contact
minimum (the step log's own accounting: car height +
view-spring offset − body sink); transmission =
camera sink / body sink. View A and View B measured
separately; they are identical to the last digit,
because the heave/body channels the sink travels are
not the channels the A/B gain touches (it gains
pitch/roll only). BEFORE is the pristine FP31 build,
same probe, same staging:

| arrival | peak F | peak R | time to peak | body sink | camera sink | transm. | settle | audio margin |
|---|---|---|---|---|---|---|---|---|
| vy 3.0 BEFORE | 0.265 | 0.236 | 0.033 s | 0.150 m | 0.206 m | 1.37 | 0.23 s | 0.0 dB (no voice) |
| vy 3.0 AFTER | 0.207 | 0.190 | 0.133 s | 0.099 m | 0.143 m | 1.45 | 0.58 s | +2.3 dB (tick −16.7/−18.2 dB) |
| vy 6.0 BEFORE | 0.340 | 0.340 | 0.011 s | 0.240 m | 0.341 m | 1.42 | 0.81 s | 0.0 dB |
| vy 6.0 AFTER | 0.323 | 0.281 | 0.133 s | 0.202 m | 0.291 m | 1.44 | 0.92 s | +6.6 dB (thump −9.0/−12.4 dB) |
| vy 8.5 BEFORE | 0.340 | 0.340 | 0.011 s | 0.240 m | 0.362 m | 1.51 | 0.82 s | 0.0 dB |
| vy 8.5 AFTER | 0.340 | 0.340 | 0.111 s | 0.240 m | 0.356 m | 1.48 | 1.18 s | +10.9 dB (thump −4.0/−7.2 dB) |

Read the BEFORE rows first: vy 6.0 and vy 8.5 are
the SAME row — both teleported to the 0.34 clamp in
one frame (time-to-peak 0.011 s is one physics tick
plus the rear axle's beat). Severity did not exist.
AFTER: severity orders by depth, settle and voice;
time-to-peak sits at 0.133 s, inside the brief's
0.12–0.30 band, at every severity; the vy 8.5 row
bottoms both axles (mean peak time 0.111 s is the
clamp arriving, front at 0.089 — a 1.2 s-class flight
onto flat at full droop IS a bottoming hit, and the
FP14 bottoming kick is its voice in the body layer).
Transmission was never short of travel (1.37–1.51
before) — it was short of TIME. The sink now arrives
over ~0.13–0.25 s instead of 1–3 frames, through the
same channels, nothing retuned (Item 2 below).

### Item 1 — compression as a motion

- **The instant set is deleted.** `_land` no longer
  assigns compression. The arriving state (post-droop,
  post-flight, whatever it is) is KEPT, and the impact
  enters as a compression VELOCITY: per axle,
  vy × LAND_CV_K (0.85) with FP5's own axle bias
  (front 1.15, rear 0.90) — a nose-first arrival
  carries more front velocity and sinks front first,
  in depth and in voice.
- **Placement continuity, re-derived.** The old set
  was also secretly the placement: it put the car at
  the compressed height in the same frame. That is
  now computed honestly at the landing frame — heave
  and pitch re-derived from the ARRIVING attach
  heights through the body spring's own formulas, so
  the placed car is continuous with the flying car,
  and the sink that follows is the integrator's.
- **The delivery ramp.** A one-frame velocity step
  peaked the stroke at 0.100 s at every severity
  (probe round 1): a linear system's peak time
  answers its input's shape, not its size. The impact
  velocity now delivers like the contact itself does
  — a 25% bite at first touch, the rest over 0.10 s
  (the same load-ramp idea as CONTACT_LOAD_RAMP_S) —
  which moves the peak to 0.133 s without touching
  the spring's stiffness or damping.
- **LAND_CV_K was measured up in the open, three
  steps, against real arrivals** (the staged probe
  reads ~0.02 m deeper than a droop arrival at the
  same vy, so the probe alone would have shipped it
  shy): at 0.58 the Drop Start's stroke peaked
  0.216 — 4 mm under the rebound's deep-hit evidence,
  no hop, and the gated gap throw fired 2.37 against
  its 2.6 proof line; at 0.72 the deep hit registered
  (peak 0.245) but the return crossed the fire travel
  early in its velocity build — throw 1.19 m/s, which
  the air window's vy < 0.5 bound snatched on the way
  up (hop 0.029 m); at 0.85 the drop peaks 0.273,
  throws 1.36 and hops 0.067 m, and the gap throw
  fires 3.62 (FP31: 3.80) for a 0.41× second flight
  (FP31: 0.48×) — the film band, on the machinery's
  own terms.
- **REBOUND_DEEP_HIT 0.22 → 0.20 (flagged
  re-derivation).** FP14 set the stored-energy
  evidence line against the instant law, where a
  vy 4.1 landing was SET to 0.285. The velocity law
  peaks that landing at 0.218 (stage-36 trace), 2 mm
  under the line — so its return rang twice with no
  bounce, the one film-law failure of the first full
  run. The line moves to where the energy now lives;
  the throw's other terms (fire travel, velocity and
  load floors, chain rule, gated cap) are untouched,
  and the isolation diff is clean: stages 51/54/58
  are value-identical with and without the move —
  it added no throw anywhere in the audited drives.
  With it, the parked soft landing reads exactly the
  film shape: one overshoot, one soft bounce
  (0.97 m/s), settled in 71 frames (FP31: 86).
- **Body layer reconciled, not stacked.** The old
  instant `_body_impulse` fired the body sink from
  the SET value — it would now peak before the car
  compresses. It is deleted. In its place, a landing
  FOLLOW: for 1.2 s after a landing the body spring's
  rest point tracks the suspension's actual sink
  excursion × BODY_FOLLOW_K 0.22 (≤ ~5.3 cm, inside
  the layer's own cap) — it cannot precede what it
  follows, so stage 2e's phase law (body peak after
  car peak) holds by construction: car peak frame
  2 → 11, body peak 12 → 23, calm sink 0.008 →
  0.022 m. The bottoming kick (BODY_CATCH_IMPULSE)
  and the road-following rest point are untouched.

### Item 2 — the view channel

No gain was retuned anywhere — not the A 0.6× spring,
not the seat heave gain. The after-transmission
(1.44–1.48 in BOTH modes) decomposes as 1.00 from
placement (the car body physically sits lower by the
sink) + the shipped 0.35 seat-heave term + ~0.1 of
body follow at the camera minimum. FP32 adds no
camera term of its own: what changed is that the
body's sink is now a motion, so the same channels
carry it over a quarter second instead of a frame.
Stage 61 proves ≥ 0.85 in both modes on staged
arrivals (1.44 / 1.44); stage 9's geometry-bounded
view steps all still pass with margin (worst outside
the staircase 0.0083 m vs bound 0.014; at the
staircase 0.0215 vs 0.032) — the largest full-view
event tail grows 0.0139 → 0.0266 m at the dip-lip
landing zone, which is the sink arriving, on the
record as an event tail, not a step defect.

### Item 3 — the contact sound

A seventh voice family joins the five loops: two
one-shot players (front/rear axle) carrying a
generated 0.45 s thump — a 52 Hz body under a
low-passed thock, no tinny edge, seeded so it is the
same sound every run. `_land` arms each axle with
its share of the impact (the 1.15/0.90 bias over the
grade's vy, CROSSED-UP/HARD arrivals at the top of
the range); the axle's voice fires at the moment
that axle actually loads — its compression crossing
rest still driving in, checked on the physics tick
right after integration — so a nose-first landing's
thump lands with the front, and severity at the
crossing can only raise the arm's estimate
(compression rate is the second witness). Level:
−23 dB (a drumbeat hop's tick) to −4 dB (the full
thump) by severity^1.15. An arm that never loads
expires silent after 0.6 s. The voices sit inside
the existing discipline exactly like the loops: the
latch stops them, the stall watchdog cuts them, a
pre-race or latched fire is refused; they duck
nothing and stack on the bed. Measured on the
probe's analytic mix (the five loops' own accounting
extended to the thumps): the 150 ms after contact
runs +2.3 dB over the in-flight bed for a hop,
+6.6 dB for the 1.2 s class, +10.9 dB for the hard
arrival — against 0.0 dB everywhere before, when
there was no voice to measure. Stage 61 proves the
firing and the ordering in-suite (flight thump
−9.0 dB, hop tick −19.0 dB on its staging).

### Census disposition

A pristine FP31 baseline (629 checks) was run
first; the FP32 log was diffed line by line.
Landing initialisation feeds every trajectory, so
movement is the expectation — the full list of
changed observables, each with its before/after:

- **stage 2c** — AMENDED IN PLACE (flagged in the
  test source): the touchdown checks now read the
  stroke's PEAK over the following second instead of
  the instant set, and the calm margin re-derives
  +0.08 → +0.05 (the instant law set a vy 3.0 arrival
  to 0.238; the velocity law peaks it at 0.199).
  Drop hop 0.13 → 0.07 m (a softer bounce — the old
  hop rode the teleport-to-clamp's stored energy);
  diag return cv sum −3.60 → −2.95.
- **stage 2e** — body-layer values move with the
  follow: calm sink peak 0.008 → 0.022 m, rough
  0.055 → 0.055 m, phase frames car 2 → 11 / body
  12 → 23 (law intact, both later — the stroke
  develops slower, the body still lands after it).
- **stage 3** — peak average compression over the
  instrumented lap 0.227 → 0.178 m (driven
  compressions now develop against their targets
  instead of inheriting landing sets).
- **stage 8** — staircase peak 0.340 → 0.335 m;
  sweeper heading max 6.1 → 6.2°, lap 47.4 → 47.2 s.
- **stage 9** — DRIVE frames 2941 → 3037; full-view
  worst event tail (height) 0.0139 → 0.0266 m at the
  dip-lip zone (Item 2 above); every bounded
  geometry check passes with margin.
- **stage 10b** — hump air 6.90 → 7.08 s; grades:
  see the grade list below.
- **stage 29** — AMENDED IN PLACE (flagged): the
  fly_case fixture now cancels the landing ramp
  with the rest of the spring state it zeroes.
  Staged cold inside the previous case's 0.10 s
  delivery, the leftover velocity (a 22 m/s climb
  landing's, ~15 m/s of it) slammed the warped car
  low and the dip-lip flight fizzled into a frame-1
  "landing." Warps are test-only; a real landing's
  own `_land` always restarts its delivery, so the
  game never meets this. Both flights then measure
  exactly their FP31 values (3.68 s / 2.32 s).
- **stage 30** — getaway times: clean 2.16 → 2.04 s,
  seeded 2.67 → 2.61 s, sway-peak 3.47 → 3.42 s;
  grades and boost deltas UNCHANGED (grade list);
  the sway spread (the penalty) 1.31 → 1.38 s.
- **stage 35** — the gap landing's ground contact
  7 → 17 frames (the developing stroke is on the
  ground longer — inside the stage's 5–45 window);
  rebound ratio 0.48× → 0.41× (band 0.4–0.75);
  gated throw 3.80 → 3.62 m/s. Hump row frame-class
  identical.
- **stage 36** — the parked soft landing: FP31's
  shape restored by the deep-hit re-derivation
  (overshoots 1, one bounce, settle 86 → 71 frames).
  The poked-spring cases (a)/(b) are byte-identical.
- **stage 46** — telemetry ring 225 → 228 events.
- **stage 51** — hump-row flight lists reshuffle at
  frame grain: circuit total air 5.59 → 5.87 s with
  one 0.30 s drumbeat flight appearing; ribbon band
  count 2 → 1 (the drumbeat check reads ≥ 1).
- **Trajectory-noise class** (values move, no check
  near a bound): stages 11b (816 → 814 frames), 13
  (micro), 19 (18108 → 18204 frames), 26 (end s
  2498 → 2496), 38 (vy0 +0.01–0.02), 40 (397 crest
  samples vs 400), 43 (band lead 0.39 → 0.38 s).

### Grade and PAY changes (flagged, own list)

No grade BOUNDARY and no payout CONSTANT moved —
the FP13/FP24 thresholds and the FP24 formula are
untouched. What moved is what the unchanged rules
measure, because arrivals now develop in time:

- **Grades.** Stage 10b's hump landings: two of
  eight re-grade FLAT → OK (arrival heading/lat
  state shifted by the new stroke upstream; dent 0
  in both runs). Stage 30's three staged drops grade
  CLEAN / SCRUBBED / CROSSED-UP in the same slots as
  FP31, boost deltas +0.0 throughout. Stage 58's P6
  episodes grade CLEAN ×3 in both runs; its rebound
  episode lengthens 0.26 → 0.48 s and lands further
  out (lat 0.18 → 3.45) — the crest's rebound now
  rides the gated return's full arc. Every other
  staged grade print is byte-identical.
- **PAY (stage 54/58 audits, formula-unchanged
  projections).** Circuit lap: air 7.70 → 7.97 s,
  income 77.0 → 79.7 units. Ribbon lap: air 9.67 →
  10.28 s, income 96.7 → 100.6 (the growth sits in
  sector 4, 0.62 → 1.06 s — rebound second flights
  paying as their own landings, FP24's own rule).
  Lab: P1 135 → 134, P3 81 → 81, P4 10 → 15 (the
  chasm crossing now carries a payable rebound
  flight: air 0.97 → 1.47 s), P6 36 → 30, P8 45 →
  44; totals 324 → 312 units on 32.37 → 31.21 s.

### Numbers

- Baseline FP31: smoke 629/629, API guard 71/71.
- FP32: smoke **636/636** (629 + stage 61's seven),
  API guard 71/71, render proof 163/164 — the one
  failure is the pre-existing sandbox llvmpipe
  hub-reach artifact, identical on the FP31 baseline
  proof. New stage 61 (7 checks): the stroke law,
  both-mode transmission, thump firing + ordering.
- No *.uid or *.png.import sidecars in the commits.

### What you're judging

Three surfaces, all in the landing. (1) THE SINK:
a real landing should now visibly travel — the car
drops into its springs over a quarter second and
comes back once; drumbeat hops stay small, the big
crest flights should use the stroke. (2) THE BOUNCE
AFTER: big landings still rebound (that contract is
staged at 0.41×), and the Drop Start should land
with its one soft bounce, a touch softer than
before. (3) THE THUMP: every touchdown now speaks,
per axle — hops tick, flights thump, crossed-up
arrivals hit hardest; judge the low end (there
should be no tinny edge) and whether the front/rear
stagger reads on nose-first arrivals. Deliberately
not in this pass: the flight model / tumble question
and long-air agency (the physics queue's next item,
your placement call), the dash-button view nudge,
the Extremes Lab, and the still-owed VIEW A/B
ruling. One pull note: if GitHub Desktop nags about
discarding changes, glance at the Changes tab before
discarding — the fingerprint check from FP31 stands.

## Fix Pass 33 — The Build Stamp

Base: FP32 final (2b8281b). The owner's request
(2026-11-01): "since this particular project has this
Discard Changes thing going, can we put build name in
small text, lower right, so I know for sure I'm
playing right version." This clone lives in OneDrive;
GitHub Desktop periodically nags Discard Changes over
per-machine Godot sidecar churn, and a stale build
already cost one false verdict (run 14). The running
build should be provable from the seat.

### The stamp

- **One constant.** `BUILD_STAMP` in main.gd, beside
  the grab log's build tag, in the exact form
  `FPnn · YYYY-MM-DD` — the newest fix pass in the
  build and its delivery date. This build's stamp
  reads **FP33 · 2026-11-01**.
- **STANDING RULE: every fix pass updates BUILD_STAMP
  as part of its delivery.** The rule has teeth: smoke
  stage 62 regex-checks the format
  (`^FP[0-9]+ · [0-9]{4}-[0-9]{2}-[0-9]{2}$` — the
  pattern itself was probe-verified against good and
  bad strings before the suite ran), so a forgotten
  or sloppy stamp fails the suite loudly.
- **Presentation.** A Label3D built once by
  `_make_stamp_label()` and parented to BOTH cameras
  (the XRCamera3D and the desktop fallback camera), so
  it holds the lower right of the visual field
  whatever the car does, in VR and on the desktop
  alike. Small (48 px type at 0.0005 pixel size),
  dim neutral grey, unshaded, no outline, drawn with
  no depth test so it reads from any pose. No
  rotation: a Label3D's readable face looks down its
  own −Z, the way the camera looks — the first FP33
  capture caught a Y-flip build reading
  MIRROR-imaged, and capture 31 stands as the guard
  that it never ships that way.
- **Placement proof.** Render proof capture 31
  (tests/build_stamp_view.png — the cockpit from the
  eye anchor) projects the stamp's AABB to a screen
  rect: fully inside the frame, centre at 77% × 84%
  (the lower right), and clear of BOTH boards' text
  rects — the stamp is permanent, so it may never sit
  on text the driver reads.

### Census

Nothing else changes: no physics, no input. Smoke
ALL 642 (FP32's 636 + stage 62's 6), every prior
check line identical; API guard ALL 71. Render proof
171/172 — the one failure is the pre-existing sandbox
hub-reach artifact, identical on the FP31/FP32
baseline proofs; the proof gains capture 31's 8
checks. Every regenerated cockpit capture now
carries the stamp in its lower right — that is the
feature working, not drift.

### What you're judging

One surface: glance lower right in the headset. The
stamp should read FP33 · 2026-11-01, small and grey —
there when you look for it, ignorable when you don't.
Its in-headset legibility is the device's verdict
(the sandbox proof can only prove placement and
orientation). And if a future build ever shows an
older stamp than the delivery message names, the pull
didn't take — that's the Discard Changes tell this
was built to expose.

## Fix Pass 34 — Nothing Moves the View but the Driver

Base: FP33 final (50e960c). The owner's field video
(2026-11-01): centred, controller wiggled as a
reference, hand to the dash, TRK pressed — and the
view yawed ~15–20° over the following seconds and
STAYED yawed. His words: "This the not centered text
debacle for this game." Same family, same tell: the
state banner rides the car's centreline, so a baked
yaw shows as text sitting off-centre. Traced chain:
`_cycle_track` → `_set_track` → `start_race()` →
`_arm_anchor()` (non-explicit). Every race start
re-armed the cockpit anchor, and FP11's yaw cone
still baked any head position inside 25° of forward —
a head turned toward the dash at press time became
the new forward. From the same seat he spotted the
second defect: "both grips. I use both grips when Im
steering, that messing anything up?" Yes — the
both-grips squeeze was FP11's recenter gesture, an
explicit bake wearing the same shape as two-handed
steering, and its gate (`_recenter_allowed`) had a
same-frame hole: two hands landing on the wheel
together could edge-fire it before the wheel claimed
the first hand.

### Item 1 — position-only restarts

The split is implemented on the existing bake flag's
semantics; no parallel anchor system was forked.
`_apply_seat_anchor(force_bake=false)` now lands the
translation with an IDENTITY basis — the seat's yaw
is preserved bit-for-bit at any head angle — and
FP11's deferred-yaw machinery is deleted whole: the
`ANCHOR_YAW_CONE_DEG` constant, the
`anchor_yaw_pending` state, and the cone watch branch
in `_process_anchor_pending`. An automatic
application owes nothing afterwards, on any later
pose either. `force_bake=true` (the explicit
recenter) is byte-identical: the bake still exists,
exactly where it belongs. Stage 63 stages the field
case: restart applied with the simulated head yawed
+20° and −20° — seat yaw delta 0.0000 rad both ways,
eye re-seated (err 0.000 m).

Every `start_race` caller inherits the law:

- `_set_track` (track change: the TRK dash button,
  the desktop V key, and the boot path)
- the Y button — hang long-press and drive edge
  (restart race)
- the desktop R key
- `_activate_dash_ctl("restart")` — the red RESTART
  dash button

### Item 2 — the both-grips recenter dies

The `both_grips` edge → `_recenter` path and
`_recenter_allowed()` are deleted, grep-clean (the
names survive only in tombstone comments recording
the repeal). The left stick click is now the ONLY
recenter, its behaviour byte-identical — it never
consulted the gate. The in-game panel line reads
"Recenter: L stick click"; the README controls list
already said exactly that, so no line needed deleting
there. Squeezing both grips is now only ever what it
looks like: holding the wheel with both hands.

### Item 3 — the neighbour audit

TRK (purple) sits on the dash-top row at x 0.57. Its
only dash-top neighbour is **RESTART (red, x 0.40,
0.17 m away)** — that is "the one next to it." Its
fire path is `_activate_dash_ctl("restart")` →
`start_race()` directly: the SAME non-explicit anchor
arm as TRK's, convicted by the same mechanism — and
"even worse" is consistent with the path, because a
restart press is typically made looking straight at
the button a beat longer, deeper inside the old cone,
so more of the turn got baked. Under Item 1 both
paths are position-only; no dash control can rotate
the view. The rest of the row was traced too: VIEW
(amber, x −0.35) only flips the view-coupling gain —
it changes how much of the car's motion reaches the
eye, never the yaw reference; SIDE (light blue,
x 0.0) only mirrors the drop button's side; the DROP
button itself (dash face, 0.24 m from TRK) fires
`_do_release` and never touches the anchor. No other
offender found.

### Proof — stage 63 (16 checks)

(a) `start_race` arms non-explicit; restart applies
at head yaw ±20° → yaw delta 0.0000 rad, position
re-seated. (b) Control: `_recenter()` arms explicit
and the application bakes the posed head onto the
car's forward (dev 0.000 rad) — the bake survives
where it belongs. (c) Negative controls: both grips
landing together from a no-hands state, in AIR and
in DRIVE → no recenter event, anchor state and seat
basis untouched; `has_method("_recenter_allowed")`
is false. (d) The TRK press path end-to-end through
the production grab poll → track cycles, restart
arms position-only. Stage 63's header notes the one
thing staging cannot prove: the anchor's stability
gate is live-rig only, as it has been since stage 22.

### Census

Smoke **ALL 661** (FP33's 642 + 19 net), API guard
ALL 71, zero engine errors. Every changed check line
is one of four flagged groups, each marked in place:
stage 22(c) re-derived — FP11–FP33's cone staging
(two checks: translation-only at 40° with yaw owed;
bake clears the debt) replaced by five: automatic
apply preserves the seat basis EXACTLY at 40° off
and at 20° off (inside the old cone — the field
case), translation err 0.000 m, a property-list
check that `anchor_yaw_pending` no longer exists,
and the explicit bake kept as the control. Stage
32's two gate checks ("suppressed in the hang" /
"allowed in DRIVE") replaced by two behavioural
squeeze controls (snapshot anchor state and seat
basis, squeeze both grips across two production
polls, assert all unchanged — hang and DRIVE).
Stage 62's stamp string moves FP33 → FP34 (the
standing ritual). Stage 63 is new (+16). Everything
else is byte-identical to the FP33 baseline run,
check name for check name. Render proof 172/173 —
the one failure is the pre-existing sandbox hub-reach
artifact, identical on the FP31–FP33 baselines; the
proof's panel sweep was amended (flagged) to require
"Recenter: L stick click" and forbid "BOTH grips",
and capture 31 reads the new stamp verbatim.

BUILD_STAMP moves to **FP34 · 2026-11-01** per the
standing ritual.

### What you're judging

Three things, all from the seat: (1) press TRK or
RESTART with your head turned wherever it turns —
the view must not swing or settle anywhere new; the
car re-seats under you, your forward stays yours.
(2) Squeeze both grips onto the wheel, any time,
anywhere — nothing should happen but steering.
(3) Click the left stick — that, and only that,
should still recenter you. As always, glance at
GitHub Desktop's Changes tab before pulling: if
`game\scripts\main.gd` shows as locally modified
there, the pull won't take cleanly and the stamp in
the lower right will tell on it.

## Fix Pass 35 — the capture window (2026-11-01)

**The conviction.** FP34 ended the yaw bake, but the owner's
isolation experiment (run on FP34, from the seat) showed the
view still moving after dash presses — and he pinned the
variable himself: still + centred + RESTART -> no change;
STRETCH (arm reach, head unmoved) + TRK -> no change; LEAN
over + either button -> view changes. The anchor's position
re-seat was still sampling the head pose at apply time, and
the stability gate watches position only — a held lean is
stable enough to pass, so the re-seat was computed from the
leaned pose and the eye stayed offset by the lean vector when
he sat back. FP34 had closed the rotation half of the sample;
the translation half was still poisonable.

**The law.** An automatic anchor application may only land
from a representative seated pose. `_process_anchor_pending`
now consults the capture window — `_anchor_in_window()`: the
tracked head within `ANCHOR_WINDOW_M` of the seat's eye
anchor, in car space — on every application branch:

- **Stable branch:** an automatic arm lands only while the
  head is in the window. A ripe arm held by the window stays
  pending, reports `HELD-WINDOW` on the DIAG anchor line,
  and lands the moment the driver is back in the seat.
- **Fallback branch (~10 s):** the timeout may still land an
  explicit arm or an in-window pose, as before — and the
  BOOT arm (below). A restart/track arm with the head out of
  window gets **no** fallback: no timeout may force a
  poisoned apply.
- **Reapply watch:** gated identically. The watch exists to
  re-seat from the real pose, and a leaned pose is not it.
- **The explicit recenter (L stick click)** is the driver's
  deliberate act and is **not** window-gated: it keeps FP11
  semantics whole, including seating a leaned pose when he
  asks it to. The window gates automatic arms only.

**The window.** `ANCHOR_WINDOW_M = 0.15` m, measured through
`_eye_anchor()`, so the window follows the driver's seat
trim exactly (trim never eats the window). Derivation: a
real lean — reaching the dash buttons — moves the head
0.25–0.45 m, so the window must close below 0.25; ordinary
seated variation must stay inside it: postural sway and
breathing move the tracked head a few cm (~0.05 m worst
case), and the driver-body spring's whole excursion stack
is capped near 0.08 m (BODY_MAX_SINK 0.055 + the accel-sink
terms). 0.15 m clears the ordinary stack with margin and
sits a full 0.10 m below the smallest real lean. A head
merely TURNED toward the dash barely moves the camera
origin (it rotates about the neck), so looking at a button
never leaves the window; only a real lean does — which is
exactly the distinction the owner's stretch test drew.

**The boot arm.** An arm made before any application has
ever landed (`anchor_arm_boot`, captured in `_arm_anchor`)
has no valid seat to preserve, so it keeps a graceful path:
extended patience for an in-window stable pose first, and
after the fallback timeout a first seat may be taken from
an out-of-window pose — with the reapply watch armed, so
the first in-window stable pose corrects it. Two honest
limits, named rather than hidden. First, the watch keeps
FP11's semantics — it fires on the first stable in-window
pose — and a take puts the eye on the anchor by
construction, so a head sitting still inside the seat it
just took spends the watch on that pose at once; the
watch's real corrective work is for a head still settling
after the take, within the taken seat's window. Second, if
a boot seat was taken from a pose more than a window's
width from the driver's true seat, the watch cannot reach
his true pose on its own at all — every later automatic arm
will hold at HELD-WINDOW instead of re-poisoning, and the
deliberate click, never gated, is the guaranteed one-press
correction.

**Proof — stage 64** drives the production gate itself
(`_process_anchor_pending`, synchronously) behind a posed
tracked head (`test_hmd_tracking` + origin posing — the
test-hook pattern of stages past; xr_ok is flipped only
around the synchronous driving): a restart arm leaned
0.35 m forward is HELD-WINDOW with the seat correction
bit-unchanged and lands on return (eye error 0.000 m); a
0.10 m slouch stays inside the window; the seated control
lands on the 21st gate call, the pre-pass timing unchanged;
650 calls past the fallback timeout with the head leaned
force no apply; the boot arm takes its first seat from the
leaned pose after the timeout, the watch refuses the
un-leaned pose (outside the taken seat's window) and
corrects from the first in-window pose; the explicit click
seats the leaned pose as the control. Census: every prior
check line identical except stage 62's stamp string (FP34
-> FP35, the standing ritual). Smoke ALL 680, API guard
ALL 71. Render proof 172/173 (the one failure is the
pre-existing sandbox hub-reach artifact, identical on the
FP34 baseline).

**What you're judging:** lean over and press TRK or
RESTART — the view must not move, and the re-seat should
land quietly a moment after you sit back. The DIAG anchor
line will read HELD-WINDOW while a re-seat waits for you
to sit back; that's the window telling the truth, not an
error.

## Fix Pass 36 — THE BURNOUT PASS (powertrain character + hop-train authority)

The owner's three notes, verbatim, are the pass's law: (1) the
hop train — "Once you start hopping from hill to hill, player has
basically no control over the car. The wheel can turned in an
extreme direction and it has no real impact on the direction of
the car when it briefly touches road." (2) the Odd Rod note —
"we need to be burning some rubber. By that I mean, these cars
need fast acceleration if gas is fully pressed… Speed wise, this
thing feels like a normal car. Not an odd rod." (3) throttle is
a line tool — "it becomes part of the steering calculation as a
driver, screaming out of a turn and hugging our edge." Audits
first (Part A), then the retune in the open (Part B), then the
authority fix where the evidence pointed (Part C). The boost
economy is NOT retuned; its repricing is reported. FP32's
landing numbers do not move (stage 61 byte-identical).

### Part A — the audits (on FP35, before any tuning)

Instruments: a scratch audit driver reusing the suite's own
staging idioms (debug warp/pin/stage-landing, the lane-PD
driver, the stage-54 payout protocol verbatim).

**A1 — powertrain baseline.** The powertrain was a single linear
law, `accel = 10 − 0.1·v` (boosted `19 − 0.1·v`), measured on
the circuit's flat window exactly as modelled: 9.50 m/s² at
5 m/s falling to 5.50 at 45; 0–30 m/s in **3.57 s** (0–10 1.06,
0–20 2.23, 0–40 5.11); top speed 48.00 (the TOP_SPEED clamp,
not a drag equilibrium). Boosted: 0–30 in 1.72 s, same 48 top.
A family-sedan launch curve — the audit agrees with the owner.

**A2 — corner-exit baseline.** The standard corner: the first
40 m of the Feature Lab P2 sweeper's R60 arc (s 624→664), entry
18.0 m/s pinned-settled, the wheel bisected at quarter throttle
(held −0.340 rad) and then FROZEN for all three runs:

| throttle | exit lat | lat @ 25 m | exit speed |
|---|---|---|---|
| lift (0.0) | −1.39 m | −1.42 m | 12.8 m/s |
| half (0.5) | +1.13 m | −0.43 m | 24.3 m/s |
| full (1.0) | +2.71 m * | +0.27 m | 32.4 m/s |

*the full-throttle run left the road 24.6 m into the corner; the
+2.71 is the fall-line reading, not a gate reading. Spread
lift→full: 4.10 m at the gate (tainted), 1.69 m at the honest
25 m gate. The throttle already talked to the line — through a
weak engine, at the price of leaving the road to prove it.

**A3 — hop-authority baseline.** Two fixtures. The controlled
one stages landings at 24 m/s on the flat (the
`debug_stage_landing` instrument) and reads the velocity
direction change at full lock:

| arrival | FP35: slide at 0.20 s | Δdir 0.30 s | Δdir 0.50 s |
|---|---|---|---|
| clean (0 m/s in) | — | −6.13° | −11.42° |
| scrubbed (1.5 m/s in) | +1.74 m/s (alive) | −1.33° | −4.00° |
| crossed (3.0 m/s in) | — | −0.60° | −3.48° |

The wild one drives the lab's drumbeat rows at full lock: the
first contact answers (−10.9°, a long clean contact), then the
train goes deaf — contact 2 lands with 10.98 m/s of lateral
velocity and the direction moves **+0.35°** while the heading
swings −10.75°; the effective lateral grip factor through the
contact's first 0.25 s measures **0.26**. And at every landing
the yaw rate reads **0.00**.

**The conviction.** The brief's prime suspect — FP32's load
ramp (LAND_RAMP_BITE 0.25 over LAND_RAMP_S 0.10 s) — is
**innocent of the lateral axis**: it shapes only the vertical
compression velocity, and the staged clean landing above is
bitten by it identically before and after this pass. The tax
is FP13's **contact-transient load factor** (`_contact_load_
factor()`: 0.10 at touchdown ramping over 0.65 s), which
multiplied the lateral bleed in every transient — 0.18 at
0.06 s after touchdown, still only 0.52 at 0.30 s — while the
transient itself (priced by the old bleed law) governed the
first ~1.4 s of a hard landing's contact. Accomplice:
`_land()` zeroed `yaw_rate`, so every touchdown also restarted
the 0.16 s yaw lag from standstill — the wheel's demand and
the car's rotation both began each hop contact from zero.

### Part B — the retune

**B1 — the engine.** ENGINE_ACCEL 10 → **16**; BOOST_ACCEL
9 → **16**, so boosted total is 32 = exactly 2× engine (the
original's ratio, which FP24's 19/10 only approximated). Drag
(0.1·v) and the 48 m/s top-speed clamp unchanged — the top end
was never the complaint.

**B2 — wheelspin.** A traction state on the driven (rear)
wheels. The engine's applied force is tested against the
contact patch's longitudinal capacity — the same friction
circle the lateral law spends (SPIN_GRIP_ACCEL = GRIP_LAT_
ACCEL = 11.0 m/s², one μ for the car), scaled by the rear
suspension load and, inside a contact transient, by the
contact load factor; the test cap grows with road speed
(+0.55 per m/s — gearing: a floored launch hooks by ~9 m/s).
Excess demand spins: the state (0..1) attacks at 10/s,
releases at 3.5/s, and the transmitted force blends toward
the kinetic patch (0.85× cap). The boost share is never
tested — the flask's thrust is not wheel torque, so boosting
off the line is the clean leap (its own 2× violence, no
smoke tax on the meter's purchase). Feathering under the cap
never spins (measured: a fixed 0.65 launch is spin-free).
Surfacing, per the situational-awareness doctrine: the
engine note flares with the state, the skid voice takes it
as input, and two smoke emitters at the rear wheels emit in
proportion (placeholder-grade particles, real state — the
FP15 dust construction). The Drop Start launch goes through
the same path: a floored drop is a scrubbed, smoking start.

After (same instruments):

| figure | FP35 | FP36 |
|---|---|---|
| accel at 15 m/s (floored) | 8.50 | 14.03 |
| 0–10 / 0–20 / 0–30 / 0–40, floored | 1.06 / 2.23 / 3.57 / 5.11 s | **0.84 / 1.57 / 2.31 / 3.11 s** |
| 0–30 boosted | 1.72 s | **1.04 s** |
| launch spin peak (floored) | — | 0.72, hooked by ~9 m/s |
| launch spin (feathered 0.65) | — | 0.00 |
| top speed | 48.00 | 48.00 (unchanged) |

**B3 — throttle-as-line, after.** Same corner, wheel
re-bisected at the new quarter-throttle power (−0.360 rad)
and frozen: lift **−2.08 m**, half **+1.55 m**, full
**+3.03 m** — spread **5.11 m** at the exit gate (2.27 m at
the 25 m gate, vs 1.69), and the full-throttle run now stays
on the road to the gate (exit 39.9 m/s) instead of departing
to prove the point. The throttle is a steering input with
five metres of authority across one corner.

**B4 — pace repricing (REPORT ONLY, per the owner's
physics-first ruling; no track shaping).** The stage-54
protocol re-flown on the suite's own driver: circuit
payable air 7.97 → 7.94 s, income **79.7 → 79.4**; ribbon
air identical (10.28 s) but its landing grades soften
slightly at pace, income **100.6 → 96.4**. The lab (same
protocol, scratch driver): payable air 31.20 → **27.27 s**
— the lab lap takes 9,788 frames against 13,212, the car
spends 26% less time there and its flights are a smaller
share of a faster lap — income **312.0 → 272.7**. Payout
per payable second is untouched everywhere (air × grade ×
10); the longest starved stretches are unchanged (circuit
2000 m, ribbon 250 m, lab 750 m). The economy is NOT
broken — capacity, grades and rates all stand — but income
per lap is down 0.4–13% at the new pace, worst where the
flying was densest; if that ever wants correcting it is a
pricing dial for a later pass, deliberately not touched
here.

### Part C — the authority fix

Three changes, all downstream of A3's conviction:

1. **The lateral bleed is decoupled from the contact load
   factor.** The bleed now runs at the road's own load
   (`load_grip`) in every contact state — full authority
   from the first frame of a touchdown, modulated only by
   how hard the road is actually pressing the car up. The
   FP13 factor keeps its remaining job (the longitudinal
   combined-slip ellipse cap) untouched. FP15's telegraph
   factors follow the same decoupling.
2. **The transient is repriced by the law that now runs.**
   `_bleed_time` integrates the decoupled bleed at the
   LANDING frame's own load (computed from its curvature —
   the build's first after-run caught the estimate reading
   the takeoff frame's stale ~0 load at a crest separation
   and pricing a hop transient at the 3.0 s cap; the
   landing's road, not the takeoff's, is the honest sample).
   A hard slide now governs ~0.6–1.0 s, not ~1.4 s.
3. **Yaw carries through flight.** Separation stores the
   yaw rate (`air_yaw_rate`); the landing restores it,
   damped by the flight (×0.85 per airborne second — a
   long flight mostly forgets, a hop remembers). Crane
   releases carry nothing (the car hangs plumb). Heading
   still cannot change airborne (the FP8 law) — what
   crosses the flight is the rotation the car left with,
   handed back at touchdown.

After (same fixtures): the scrubbed arrival's slide is
**dead by 0.20 s** (lat_vel −1.65 — already the wheel's own
turn) and the direction answers **−3.56° by 0.30 s,
−8.92° by 0.50 s** (FP35: −1.33° / −4.00°); the crossed
arrival reaches −6.52° by 0.50 s (−3.48°); the clean arrival
is byte-identical (−6.13° / −11.42°) — cruise was never the
complaint. On the drumbeat rows the comparable first contact
is unchanged (−10.3°) and the second contact now reads:
yaw at landing **−1.37 rad/s** (was 0.00), effective lateral
factor through the first 0.25 s **1.03** (was 0.26),
transient 0.97 s (was 1.39) — and the velocity still only
concedes −3.26° there, because that contact lands with
10.5 m/s of slide, a demand past any tire; what changed is
that the car now visibly FIGHTS it (heading −54.9° through
the contact) instead of sailing deaf. The headline number
for a drumbeat-length contact on a sane arrival: **−3.6° of
direction in 0.30 s where FP35 gave −1.3°**, with the slide
already dead — and a carried yaw the wheel can build on
hop after hop.

### Census

Full suite against the FP35 baseline log (680 checks):
**698 checks, all passing** — stage 65 (new, 18 checks)
guards the pass; the API guard stands at 71. The moved
checks, each re-derived in place with its mechanism on the
record:

- **Stage 13** (the edge-straddle saves): the stage is
  staged at a fixed engine FORCE (2.5 m/s²); its throttle
  setting is re-derived 0.25 → 0.15625 for the new engine.
  At the old number (now worth 4.0) the manoeuvre outran
  the home straight and the lap ended mid-save (mode DONE
  at s = track_len, measured standalone).
- **Stage 26** (standing-start 0→45): the check's band is
  the powertrain's signature and the powertrain was
  replaced — band re-derived [4.5, 8.0] → [3.0, 4.5]
  around the measured 3.5 s (audit 3.54).
- **Stage 30** (Drop Start getaway spread): floor 1.25 →
  0.90 under the measured 1.03 (clean 1.36 / seed 1.61 /
  peak 2.39 — the peak's relative cost GREW, +63% → +76%;
  grades and contact velocities identical).
- **Stage 58, piece 2**: the rising-side rear corner's
  allowance goes 1 → 2 frames at run18 (the pursuit's
  hotter entry unloads it briefly over the unwind; deltas
  [0, 4, 0, 7] → [0, 5, 2, 8], mild unchanged).
- **Stage 54's prints** move with the pace (the B4 table
  above); its checks all pass.
- **Stage 61 (FP32's landing suite)**: the landing LAW is
  untouched — the controlled fixture's clean landing is
  bit-identical before/after (Part C) — but the stage's
  staged figures move a frame or two (time-to-peak
  0.133 → 0.122 s, inside its 0.12–0.30 film band; stroke
  peaks within 0.02 m; view transmission 1.44 → 1.41):
  its approach legs run the new powertrain, so the car
  arrives at each staging a hair differently. The pass's
  hard constraint — FP32's sink behaviour — holds.
- **Stage 43 (the telegraph)**: the band's warning lead
  moves 0.38 → 0.32 s at the sweeper — the FP15 factors
  now read the axle loads through a transient (the same
  decoupling) and the entry is faster; the check passes.
- **Stage 62**: the stamp string, FP35 → FP36 (the
  ritual).
- The remaining diffs are measured values inside passing
  check text (frame counts, drift distances, event
  tallies — stages 8/9/11b/12/19/46/51/58-audit): the
  pace's fingerprints, no assertion moved.
- Everything else byte-identical.

Stage 65's own staging took three attempts to make honest,
and the record should say so: its first C1 replicated the
A3 audit from memory instead of from the instrument —
the slide written into lat_vel/vel2 (which the landing
rebuilds from air_vel, discarding it) and the direction
read in the mirror convention — and measured a fiction
(+5.58°). Its launch fixtures never staged the BRAKE:
the suite's pursuit driver parks the car on
test_brake = 0.7, and the launches sat at speed 0.00
against it, spin pinned at 1.00 (a brake-stand, faithfully
modelled, entirely unintended). Both are fixed by staging
exactly what the audit stages — the air-velocity slide
injection, the heading-convention direction, and both
pedals by hand — and the stage now reproduces the audit's
numbers to the digit (−1.65 / −3.56° / −8.92°; 0.72 spin;
2.31 s; 5.10 m of corner spread).

### What you're judging

- The launch: floored from a stop and off the Drop Start —
  the spin, the smoke, the hook-up. Feather it and it
  should leap clean.
- 0–30 pace everywhere: the Odd Rod character — violent
  standing-start acceleration, same 48 top end.
- The hop train: drumbeat rows at the lab — the wheel
  should talk to the direction inside each contact now,
  and a correction built before a hop should still be
  there after it.
- Corner exits: lift vs floor it — the exit line should
  move metres, on purpose.
- NOT judged here: payout totals at the new pace (report
  above — pricing is a later dial if you want it), track
  shapes (deferred by your ruling), the smoke's look
  (placeholder particles; the state is what's real).


## Fix Pass 37 — TRACK 01: the first real circuit

The owner's order (2026-11-02, queued behind FP36): "after
that I'd like to see a track put together, a circuit, with
all the track elements we have so far. lots of turns in
both directions, steep climbs, steep descents. jumps." —
and "replace first test track with it." The FP10 mountain
circuit is REPLACED in slot 1: TRK now cycles Track 01 →
the ribbon → the Feature Lab. The lab is untouched (it
stays the piece library and the audit instrument) and so
is the ribbon. BUILD_STAMP "FP37 · 2026-11-02".

### The layout (3,493 m, closed, Drop Start at the head)

Assembled per the prototype-first method: every sector is
a piece already driven in the lab / on the ribbon / on the
old circuit, plus the owner's steep grades built as
first-class pieces. Spans are the builder's own
(features["sectors"] — stage 18's census and stage 49's
fall census read the same table):

| sector | span (m) | what it is |
|---|---|---|
| T1 THE OPENING | 0–285 | Drop Start flat, ONE FP8 hump at s 220 — the launch straight is taxed from the first lap; its length also sets the tail's return |
| T2 THE FLAIR | 285–595 | left sweeper R185, 26° bank, the shaped unwind at the exit (stage 51a stages here now) |
| T2b FIRST CREST | 595–675 | a +12° slope-matched launch |
| T3 THE DIVE | 675–965 | STEEP DESCENT −18° × 170 m, a flatten, one hump on the valley floor, a 55 m settle |
| T4 OFF-CAMBER S | 965–1128 | the lab P5 family at R85, adverse ±10° banks, 30° per arc with a 55 m settle link (see "the S" below) |
| T5 THE WALL | 1128–1343 | STEEP CLIMB +20° × 170 m, then a long soft crest flatten |
| T6 THE EDGE RUN | 1343–1453 | flat taxed by edge markers on the line (lat ±5.85) + a ±4° bank sway |
| T7 THE CHASM | 1453–1616 | the lab P4 piece: shaped +10° lip, 28 m of air, −3.4° landing straight, +8° exit climb |
| T8 WEST HAIRPIN | 1616–1762 | left 180° at R40, banked 24° — the lap's slow corner |
| T9 CREST LAUNCHES | 1762–1977 | the lab P3 pair (+14°, +20°), slope-matched |
| T10 DRUMBEAT RIDGE | 1977–2222 | the FP8 hump row verbatim (five humps + settle, 245 m) |
| T11 COMPRESSION→REBOUND | 2222–2344 | the lab P6 piece verbatim |
| T12 STAIRCASE + ESCALATOR | 2344–2605 | six −22° steps down, then the second STEEP CLIMB +17° × 100 m, cresting off sharp — the top of the climb is itself a launch |
| T13 THE LONG RIGHT HOME | 2605–2783 | right sweeper R100 at −26° bank, DESCENDING at −9° |
| T14 THE LAST HUMP | 2783–2858 | one FP8 hump on the run south — the approach to the tail is taxed too |
| T15 THE TAIL | 2858–3493 | solver territory: return straight (bank sway + its own FP8 hump 90 m into the hold) → closing left hairpin R118 |

Closure is solved on the tail exactly as FP10 did it
(return length / hold pitch / hairpin radius are the
continuous variables): lr 247 m, phi_h −0.3°, R_e 123 m,
residual 0.004 m. Lap elevation runs 5.2 m (the valley
floor) to 85.5 m (the Escalator's crest). Head layout was
iterated against a replica of the generator until the
solver landed mid-range on all three variables — phi_h
sat on its −0.03 rad clamp at one point (the head ended
5.1 m too high for the return to shed), which is why T13
descends at −9° rather than −7.5°: its grade is part of
the lap's elevation budget, not decoration.

### The grades, verified

| grade | design | measured |
|---|---|---|
| THE DIVE (T3) | −18° × 170 m | drops 55.0 m from lip to valley floor (stage 18's census reads it off the built frames) |
| THE WALL (T5) | +20° × 170 m | gains 52.4 m across the climb span (stage 18); topped at pace in every feasibility lap — the engine's 16 m/s² against the slope's 3.4 m/s² gravity component is never close |
| THE ESCALATOR (T12) | +17° × 100 m | crests at the lap's high point, 85.5 m |
| THE STAIRCASE (T12) | −22° steps × 6 | −11 m over 66 m |
| THE LONG RIGHT (T13) | −9° × 157 m | gives back 19.8 m across the sector while turned at R100 |

### Two convictions from the feasibility drive

1. **The Dive → S sequence wedged the car (v2 layout).**
   The valley hump's rebound second flight landed
   CROSSED-UP inside the S's first arc (~s 861): the car
   scrubbed to a stop on the adverse bank and pogoed on
   its springs in a permanent AIR/DRIVE flicker no
   lost-trigger could fire on. A track sequence defect
   under the lab's own sequencing law (touchdown,
   rebound and a settled run complete before the next
   piece begins): the Dive's settle is 55 m in the final
   layout, and the S is entered settled.
2. **The S runs wide at racing pace (v3, then v4).** The
   lab's 70°-per-arc piece survives the lab because its
   feeders deliver it slowly; fed at racing pace off the
   Dive it entered at 30.5 m/s and the adverse camber's
   pull (~1.7 m/s² on top of the cornering demand, which
   at the curvature cap already spends the whole grip
   budget) bled lat to −4 m inside 50 m and off the road
   at s 998. Shortening the sweep to 40° per arc was NOT
   enough: the first arc's slide (−4.6 at the link) left
   lateral velocity the 18 m link couldn't kill, and
   the reversal threw the car off the second arc at
   s 1085 carrying ~9 m/s sideways. The final circuit
   instance keeps the piece's radius (R85) and banks
   (±10° adverse), sweeps 30° per arc, and puts a 55 m
   settle link between the arcs where the lateral
   velocity dies: measured traversal at a sustained
   30.7 m/s peaks at −2.89 m in the first arc and
   +1.71 m in the second. The lab keeps the full piece
   as the library original. The full feasibility drive
   (stage 19's protocol) then ran 3 laps to DONE in
   20,596 frames with ZERO falls.

### The audits, repriced (stage 54's protocol, one lap)

Track 01: **30.63 s of payable air, 259.1 units of
projected income per lap, longest starved stretch
250 m** — against the design target of < ~500 m, beaten
by 2x. The sector geography (payable air per 250 m
sector): [1.09, 0.77, 3.14, 1.33, 0, 1.00, 0.93, 6.84,
6.07, 3.96, 1.73, 1.87, 1.90, 0] — only two zero sectors
in the lap, each isolated (the S/Wall sector and the
seam sector), so no two starved sectors ever touch.
Alongside the standing figures: the lab pays 272.7, the
ribbon 96.4, and the old circuit paid 79.4 with a
2,000 m longest starved stretch — Track 01 pays
near-lab income across a full 3.5 km lap and starves
nowhere longer than a single sector.

### Census — every stage the old circuit's geometry fed

Re-derived and flagged in place (each carries its FP37
note at the stage): **18** (lap band, the Wall's gain,
the 28 m chasm, the home/mid straightaways replaced by
the 16-sector census; the dip depth, curves census, seam
and drop-qualification trio are features-driven and
stand), **21** (the absence assertions stand; the
clean-line window is now the opening flat, s 30–200,
before the hump), **29** (stagings moved off
literals onto the features — climb_s1 and gap_s0 — after
the first form's hard-coded lip went stale by 9 m when
the S grew; measured at the anchors: climb 314 frames,
lip 166, the lost case's bound re-derived < 230 from
its measured 208), **35** (the warp's spring-zeroing
hygiene added — without it a spurious hop precedes the
gap flight; and the gated case re-staged at 48 m/s:
Track 01's chasm lip launches the car upward, so at the
old 33 m/s staging the impact never armed the gate and
the spring route answered at 2.57 — at 48 the flight
lands on the rising exit climb, throw 4.13, rebound
ratio 0.64 in the film band, the original bounds all
standing), **49** (the fall census list re-derived from
the sector table, sixteen falls), **51(a)** (the flair
re-staged on Track 01's arc: warp 200, snapshot at 567,
window to 600 — and the falling-side assertions
mirrored: Track 01's flair is a LEFT sweeper, the event
reproduces on the left wheels, FL 6 / RL 7), **51(c)**
(the load band's floor re-derived to 0.02: the Wall's
long soft crest unloads to 0.06 at cruise — near-
separation without separating; the no-separation
control itself stands), **51(d)** (the flat guard's
window is s 60–200, before the opening hump). Verified unaffected
and untouched: 19 (the feasibility laps themselves), 20
(features-driven off gap/ext spans), 26 (its speed-run
measurements complete by s ~120, before the hump), 34
(its hairpin fall at s 3279 still lands inside the
closing hairpin), 51(b)/(c) (features-driven off the
ext/climb spans), 52(a), 54, 57, 58, 65. Ribbon and lab
stages do not move; a failure there would be a real
regression, not a census item.

### Gates

Preflight audit clean; parse warnings-as-errors
clean; ClassDB XR guard ALL 71; full smoke **ALL 716
CHECKS PASSED** (698 at FP36 + the census growth above).
The render proof is the one gate the sandbox could not
run to completion this pass: under neighbour load it
segfaulted once at 429 MB free and then crawled at
under 1% CPU, reaching 42 checks with the only failure
being the standing hub-reach artifact (identical on
the FP31-FP36 baselines). Nothing in this pass touches
the rendering, cockpit or crane paths its captures
exercise, and the FP37 stamp it would photograph is
asserted in-suite by stage 62. The proof should be
re-run on a quiet box; its captures in this commit are
the FP36 set. No *.uid / *.png.import in the commit.
UNVERIFIED until the owner drives it: the whole lap's
feel — the S's new sweep, the Wall at pace, the
Escalator's crest launch, and whether 3,493 m is the
right lap length for a 3-lap race.

## Fix Pass 38 — TRK2: THE FUNLAB (loop, corkscrew, barrel roll)

The owner's order (2026-11-02): "and I still need a loop,
barrel roll, corkscrew funlab, TRK2" — queued behind
Track 01, which landed as FP37. TRK2 is a FOURTH track
appended to the roster: TRK now cycles Track 01 → the
ribbon → the Feature Lab → TRK2 → Track 01, and the dash
panel names it TRK2. It is not a race circuit: a straight
test course in the Feature Lab's spirit, staged in empty
country at (-1600, 30, -1400) heading -z, Drop Start at
the head, crane recovery throughout, each element
separated by honest run-up and run-out so each can be
taken repeatedly and judged alone. All three elements
are SURFACE pieces — the road does the rolling; the car
is never spun by code. The lab and Track 01 are
untouched. BUILD_STAMP "FP38 · 2026-11-02".

### The course (849 m, open)

- Head: 110 m flat.
- **E1 THE LOOP** (s 110–192): a full vertical loop in
  the road, mouth on the racing line (legal under FP23's
  tombstone: purpose-built, on-line). Built as a regular
  82-sided polygon walked at a constant pitch rate of
  360°/82 m — it closes EXACTLY (residual 0.0000 m,
  verified off the built arrays): radius ≈ 13.05 m,
  crown 26.1 m above the entry. Pitch profile off the
  built tangents: 1.1° at the mouth → 87.8° → 180.0° at
  mid-span → 267.8° → 358.9° at the exit.
- 120 m flat run-out.
- E2 run-in: 20 m pitch ramp to −6.5°, 10 m hold.
- **E2 THE CORKSCREW** (s 342–502): the road rolls
  continuously through 360° of bank while descending at
  −6.5° (a helix): 10 m easing in, 140 m at full roll
  rate, 10 m easing out; drops ≈ 18 m across the piece.
  Bank reads 180° at mid-span and 0.00° three metres
  past the end.
- 20 m pitch ramp out; a climb home at +7° (15 m ramp /
  75 m hold / 15 m out); 40 m flat.
- **E3 THE BARREL ROLL** (s 667–719): the same 360° of
  bank compressed into 52 m on the flat — the road
  twists the car over in one quick motion at racing
  pace rather than a sustained helix. Bank 180° at
  mid-span, 0.00° past the end.
- 130 m flat run-out to the finish.

Each element gets a roadside board in the lab's style
(post + billboarded amber name), plus a smaller
pale-blue advisory line under it — the measured ruling
for that piece, stated below. The course uses the lab's
15 m section stripes (no racing paint on a test course).

### The verdicts — measured, per element

Staged drives (the FP38 probes, deleted before the
commit; stage 66 re-asserts the headline outcomes):
each element was attempted across an entry-speed sweep,
floored (pedal down past the mouth) and pinned (speed
held at the entry value the whole way, isolating the
surface from the throttle), with a lane-keeping driver.

**E1 THE LOOP — DOES NOT WORK, at any speed. The car
wedges at the vertical.** All 11 probe configurations
— floored entries 14/18/22/26/30/36/42, entries governed
down to 11.5, a coast entry at 22 — ended the same way:
the car climbs the front wall fully supported (corner
loads 0.61–1.00 throughout the climb; the wall HOLDS
it) and stops dead at road pitch φ ≈ 87.8–92.2°, about
20 m into the 82 m piece, max height y ≈ 43.5. It never
separates, never falls, never needs the crane to be
called for it. The stall is exact: at entry 18 floored,
samples every 1500 frames from t = 17 s to t = 167 s
are bit-identical — s = 130.4, φ = 87.8°, speed 48.0
(floored, saturated at the top-speed clamp), mode
DRIVE, y = 43.4; ds/dt = 0. The mechanism is the DRIVE
model itself, not grip: the car's velocity is a
HORIZONTAL 2D vector and road progress is re-derived by
projection onto the spine, so forward progress along
the road goes as vf·cos φ → 0 at a vertical road — a
singularity in the drive model. There is NO minimum
clean entry speed; none exists. The question the piece
was built to ask — what does ribbon-proximity support
do at the crown? — is answered one level earlier: the
car can never be presented to the crown in DRIVE. The
crown, the whole back half (52 of the 82 m), is never
touched by a driven car. It is not a soft-lock: L X
(the crane call) extracts the wedged car, and the
recovery drops it at s 86.4, back on the flat before
the loop. Board: **NO CLEAN SPEED - IT WEDGES AT THE
WALL.**

**E2 THE CORKSCREW — NEVER COMPLETES. It lets go
sideways, ~15° short of inverted.** Floored entries
14/17/20/26/32/38/44: all failed to the crane. The
descent accelerates the car regardless of entry
(separation speeds 41–48), first separation at bank
≈ 110–113° (s ≈ 393), up to a dozen air episodes,
landings mostly crossed-up, and a fall. Held (pinned)
entries are the honest isolation: at 20/26/32 the car
is carried deep into the roll on a single air episode,
separating at s ≈ 415–417, bank 164–168°. The dense
trace at held 26 names the mechanism: corner loads
decline steadily through the roll (1.00 at bank 6° →
≈ 0.70 at 92° → ≈ 0.55 at 122°) — the twisting surface
taxes the patches — but the car is still about a third
supported when it leaves, and it does NOT leave by load
separation (the suspension's wheel-air flags never
fire). What fails is the LATERAL bookkeeping: the car's
measured lateral offset walks off monotonically through
the roll (0.07 m at bank 6° → 0.55 at 30° → 1.31 at 61°
→ 2.57 at 92° → 4.71 at 122° → 7.14 at 153°) even with
speed pinned and the lane-keeper steering to centre —
past ~90° of bank the frame's "sideways" points
increasingly at the sky, and a horizontal velocity
vector read against a rolling frame cannot hold the
centreline; steering corrections act in world space,
where the error is becoming vertical. At bank ≈ 153°
the left wheels' samples run past the rolled road's
edge (support cut off), and at ≈ 165° the centre passes
the fall line (lat 7.98 against the 7.17 threshold) and
the car leaves by the lateral-exit door — air velocity
y = −2.93, no separation bounce. The landing after is
botched; the crane finishes it. No clean speed exists;
the furthest line is a held ~20 (separates at bank
167.8°). Board: **NO CLEAN LINE - HELD 20 GOES
FURTHEST.**

**E3 THE BARREL ROLL — WORKS, with a toss. It completes
at every speed tried and is never clean.** Floored
entries 20/26/32/38/44: all completed, exit speeds
41.4–48.0, lateral discipline never the problem
(max |lat| 3.0–5.7 in the probes, 6.1 in stage 66's
own run — all well under the 7.17 fall line). Held 26: exactly ONE separation, at s 715.3,
bank 350.6° — inside the final roll-rate ramp-down,
~9° before flat; the car lands and drives out at its
entry speed, max |lat| 3.0. Held 36: a mid-roll
separation joins it (bank 90.8°) — 7 air episodes —
still completes. The dense trace at held 26 shows the
roll's rhythm: at bank ~15° the fast twist already
scatters the corner loads ([0.39, 1.25, 1.03, 0.97]);
at bank ~107° the left corners separate and return
(the car stays — separation needs all four); at bank
~222° the surface slams every patch to the 1.25 clamp
(the valley phase); and the exit hop itself is the
geometry route — all four loads hit 0.00 together in
the final untwist and the car leaves with air velocity
y = +0.35, the suspension route's exact signature. The
twist costs nothing measurable in forward speed: held
entries exit at their entry speed. Board: **ANY SPEED
- ONE HOP AT THE EXIT.**

### Proof — stage 66

Stage 66 (in tests/smoke_test.gd) re-asserts the
measured outcomes through production paths: the roster
(funlab present, open, 849 m, three elements with the
shipped spans), the cycle's two new links (lab →
funlab here; stage 58 amended, below), the three
boards' name + advisory text exact, the built shapes
(loop inverted at mid-span, crown > 25 m over the
entry, both rolls inverted at their middles and flat
past their ends), every element's entry state (flat /
−6.5° descent, unbanked), Drop Start at TRK2's head
plus a mid-course crane recovery, the loop drive
(floored 24 → the wedge: DRIVE throughout, max pitch
inside 75–105°, no separation, no hang) and its crane
extraction back onto the flat, the corkscrew at its
held 20 (separates past bank 140°, crane finishes it —
no clean completion), the barrel floored at 30
(completes, at least one air episode, no crane, max
|lat| under the fall line), and the course's finish
crossed under power at a held 26.

### Census

Two amendments, each FLAGGED in place with its FP38
note; everything else stands byte-identical, and a
failure anywhere else would be a real regression, not
a census item. **Stage 11a**: the second held-grip TRK
sweep now lands on the funlab instead of the circuit
(the roster grew a fourth stop; the stage's subject —
the sweep firing on zone entry, exactly once — is
untouched), and its trailing comment corrected to
match. **Stage 58**: the roster comment's wrap check
now asserts lab → funlab (stage 66 asserts the funlab
→ circuit wrap that closes the cycle). The controls
roster above and the tests blurb name TRK2.

### Gates

Preflight audit clean; parse warnings-as-errors
clean; ClassDB XR guard ALL 71; full smoke **ALL 734
CHECKS PASSED** (716 at FP37 + stage 66's 18). The
render proof — the gate FP37's sandbox could not
finish — RAN TO COMPLETION this pass on the current
code: 172 of 173 checks passed, and the single failure
is the standing hub-reach artifact (the wheel hub sits
0.31 m below the eye, outside the proof's natural-reach
band) — the same failure the FP31–FP36 baselines carry
and the one FP37's partial run reached; nothing in
this pass touches the cockpit or wheel geometry. Its
captures in this commit are the fresh FP38 set
(capture 31 photographs the FP38 stamp in the lower
right). No *.uid / *.png.import in the commit.
UNVERIFIED until the owner drives it: the wedge, the
roll and the hop are staged findings — his hands are
the verdict on all three.

### What you're judging

TRK2 itself, three pieces, one at a time — TRK cycles to
it from the lab. The loop: drive at the wall and feel
the wedge for yourself — it stops at the vertical and
sits there, engine and all, until you call the crane
(L X). The physics says no entry speed fixes that; if
you want a loop that can be driven, that's a drive-model
conversation, now with numbers. The corkscrew: hold
about 20 if you can and watch how deep the roll carries
you before it lets go sideways — the board says how far
the staged car got (bank ~168° of 360°). The barrel
roll is the one that works: any speed, and judge the
hop at the exit — one toss as the road flattens, then
it drives out.

## Quest export — status

The full chain is assembled and correct up to the last step:

- `export_presets.cfg`: preset **"Android Quest"** — arm64, Gradle
  build, XR Mode = OpenXR, Meta plugin enabled, Quest 3 support on.
- Godot OpenXR Vendors plugin 5.1.0-stable in `addons/godotopenxrvendors`.
- Android build template installed in `android/` (gitignored —
  regenerate any time via Project → Install Android Build Template).
- Toolchain used here (in `~/workspace/tools/android/`): Temurin JDK
  17, SDK platform 35 + build-tools 35.0.0 (fetched as direct zips —
  `sdkmanager` can't tunnel this sandbox's egress proxy), debug
  keystore generated; Godot editor settings point at both.

**Blocker in this sandbox:** Gradle builds fail because the Gradle
daemon's client↔daemon IPC dies here ("Could not receive a message
from the daemon" — the daemon starts, registers and accepts, then the
channel fails and it is stopped ~10 s later). Reproduced with a bare
`gradlew help` in `android/build/`, outside Godot, so it is the
sandbox environment, not the project. A non-Gradle template export
succeeds and signs, but the Vendors plugin's AAR/manifest integration
only applies to Gradle builds, so that APK would not register as a VR
app on Quest — it is deliberately **not** shipped.

On a normal desktop: open the project, confirm the Android preset,
Export → "Android Quest" → `builds/stunt-car-test1.apk`.

## Fix Pass 39 — Track 01 rework: fair hills

BUILD_STAMP "FP39 · 2026-11-02". The owner's conviction from the seat
(2026-11-02, after his first Track 01 field runs): "the part that feel
frustrating and probably unfair is consistent: coming out a turn
straight into a tall hill. A: You're probably not gonna be straight, so
you're guaranteed to go flying off the track. B. You don't get any
sense what's on the other side of the hill because between the turn
and the hill, your view is pretty much blocked."

Both halves were already law in the FP37 brief (lateral velocity
survives a short link; no blind launches). The layout broke them. This
pass audits every turn-exit -> climb join on Track 01 with the staged
driver and a geometric sightline check, fixes the guilty joins by
layout surgery, and re-proves with the same instruments.

### Instruments and verdicts

A: at the climb's foot, the staged driver's |lat_vel| (the FP36 bleed
law's quantity) must be <= 0.5 m/s, with no road departure through the
join and peak |car_lat| <= 4.0 m through the climb.
B: if the staged drive separates at the crest, the landing must be
readable at the commit point — B1, the first road visible past the lip
from the turn-exit eye (cockpit eye height 1.26 m), within the
measured flight distance + 10 m. For grounded joins there is no launch
to be blind about; B2 (the first eye position with any far-side
visibility) is published as context.

One geometry result shaped everything: from a lower eye, a far-side
point past a convex lip is visible only if the far side rises back
above the lip's sightline (the chasm's rising exit is the pattern).
Falling or flat far sides — the Dive, Drumbeat Ridge, the Long Right —
can never satisfy B1 for a launch, at any link length. So every
turn-fed launch on the lap was GROUNDED, not re-sighted: the pitches
stay (the hills stay tall — the Wall is still +20 deg x 170 m), and
their sheds stretch until v^2.kv < g at the fastest honest arrival.

The fastest honest arrival turned out to be the pass's real subject.
On a sustained grade the smoothed kv is ~0 mid-face, so nothing caps
the speed: a floored car — the staged driver, and the owner — storms
the whole climb toward the 48 m/s clamp, and the early shed is still a
climb, so it keeps accelerating along the shed and separates wherever
v^2.kv crosses g. Measured along the way: a 0.010 brow separated at
the clamp (a 147 m flight over the whole Edge Run); 0.006 sheds
separated mid-shed at 36-40 m/s; even 0.0042 separated at 47.6-48.0
(the smoothed kv runs a few percent over nominal). ONE BROW LAW: every
convex shed on Track 01 runs at 0.0032/m — v^2.kv = 7.4 m/s^2 at the
clamp, no crossing at any speed. The only exception is the Last Hump's
back at 0.007, whose arrival is curvature-capped by the sweeper
itself. Concave transitions (pitch rising) keep their fast rates —
settles and run-outs are not sheds.

### Pre-fix audit (FP37 geometry, staged driver, 2 laps)

| join | arc-exit slide | foot lat_vel @ speed | peak \|lat\| | crest flight | sightline |
|---|---|---|---|---|---|
| Flair -> First Crest | +0.16 | -0.06 @ 28.6 | 0.14 | sep 625.8 @ 23.9, 39 m flight (+45 m rebound off the Dive hump) | B1 none; reveal 7 m before lip |
| S -> The Wall | +3.81 | +0.39 @ 35.9 | 1.21 | sep 1299.4 @ 48.0 (the clamp), 147 m flight over the whole Edge Run | B1 none; reveal 17 m before lip |
| Hairpin -> Crest Launches 1 | +0.51 | -0.23 @ 23.9 | 0.23 | sep 1802.4 @ 24.0, 50 m flight | B1 none; reveal 9 m before lip |
| Crest 2 (fed by crest 1) | airborne | airborne | — | sep 1907.4 @ 23.8, 65 m flight to Drumbeat's doorstep | B1 none; reveal 6 m before lip |
| Long Right -> Last Hump | -0.09 | (staging error; see note) | 3.46 | sep 2813.3 @ 23.9, 26 m flight | B1 none; reveal 9 m before lip |
| Staircase -> Escalator | descent-fed | -0.00 @ 33.7 | 0.07 | sep 2536.3 @ 24.8, 31 m flight | B1 none; reveal 9 m before lip |

Every join was blind from the turn exit (B1 = none at all six), and
five of the six launched the staged driver. The S -> Wall join also
carried the S's exit slide (+3.81 m/s at the arc's end, +0.39 still
live at the foot) — the FP37 conviction's join exactly. (J4's first
foot sample was a probe staging error — it read mid-corner; the
post-fix table carries the corrected staging.)

### The surgery (per join)

- Flair -> First Crest: the unwind/settle link grows 20 -> 35 m; the
  crest's back stretches to 131 m at the brow law (was ~35 m at 0.030).
  The +12 deg face is untouched.
- The Dive (the First Crest's far side): -18 deg now runs 282 m (was
  170), opening with a 35 m brow-rate entry ramp — a grounded car now
  arrives at the descent at ~44 m/s, and the shipped 0.010 entry
  pitch-on would itself have thrown it (v^2.kv ~19). The hump, flatten
  and settle are as shipped.
- S -> The Wall: the trailing link grows 18 -> 60 m. The slide was
  measured at +3.8 m/s at the arc exit; the bleed trace across the new
  link shows it crossing zero ~19 m in, the rest of the link being the
  staged driver's own correction ripple dying out — foot reads
  -0.17 m/s at 46 m/s. The climb (+20 deg x 170 m) is untouched; its
  crest flatten becomes a 115 m brow at 0.0032 (was 45 m at 0.008).
- Hairpin -> the crests: T9 CREST LAUNCHES is renamed THE TWIN
  CRESTS. Crest 1's back stretches to 153 m at the brow law (was ~52 m
  at 0.030); crest 2's back to 185 m at the brow law to -14 deg (was
  ~47 m), with a 40 m glide at -14 deg paying elevation before the
  run-out. Faces (+14 / +20 deg) untouched.
- Escalator: the 100 m +17 deg climb is untouched; its 30 m crest-off
  at 0.030 becomes a 93 m brow at 0.0032. The settle after it is
  restored to 40 m (see T13 below).
- Long Right -> Last Hump: the hump's back gentles 0.021 -> 0.007 over
  30 m — its arrival is curvature-capped at ~24 m/s by the sweeper
  itself, so the brow law's rate is not needed; what it needed was a
  back that does not throw a 24 m/s car (v^2.kv was 12.1).
- Compensation, honestly booked: the Dive pays most of the growth
  (170 -> 282 m at -18 deg), the Edge Run trims 110 -> 90 m, and the
  Long Right's grade deepens -9 -> -15 deg as an elevation-budget trim
  (the FP37 precedent; -16 deg was tried with a shortened Escalator
  settle and the staged driver fell in the arc — the pair was restored
  together, settle 40 m and grade -15). A chasm exit trim (55 -> 30 m)
  made during the closure search was REVERTED: stage 35's rebound
  census convicted it (at 48 m/s the gap flight ate the whole
  shortened exit and the rebound off the rising ground — that piece's
  second act — never happened inside the stage's window; on the
  restored geometry the rebound reads 0.64x, in its film band). The
  tail solver closes at lr 238 m,
  phi_h -0.02 deg, R_e 99 m, residual 0.003 m. Lap 4,066 m (was
  3,493 m); elevation -27.2 to +94.4 m; the Wall's climb-span gain
  still 52.4 m; stage 18's dip measure reads 96.3 m.

New sector table: T1 THE OPENING [0,285] · T2 THE FLAIR [285,610] ·
T2b FIRST CREST [610,771] · T3 THE DIVE [771,1173] · T4 OFF-CAMBER S
[1173,1378] · T5 THE WALL [1378,1663] · T6 THE EDGE RUN [1663,1753] ·
T7 THE CHASM [1753,1916] · T8 WEST HAIRPIN [1916,2062] · T9 THE TWIN
CRESTS [2062,2559] · T10 DRUMBEAT RIDGE [2559,2804] · T11
COMPRESSION-REBOUND [2804,2926] · T12 STAIRCASE + ESCALATOR
[2926,3250] · T13 THE LONG RIGHT HOME [3250,3428] · T14 THE LAST HUMP
[3428,3514] · T15 THE TAIL [3514,4066].

### Post-fix audit (same instruments, staged driver, 2 laps, zero falls)

| join | foot lat_vel @ speed | peak \|lat\| | separations in zone | far side readable |
|---|---|---|---|---|
| Flair -> First Crest | -0.08 @ 28.6 | 0.12 | none | reveal 26 m before lip |
| S -> The Wall | -0.17 @ 45.9 | 0.22 | none | reveal 27 m before lip |
| Hairpin -> Twin Crest 1 | -0.23 @ 24.1 | 0.22 | none | reveal 26 m before lip |
| Twin Crest 2 | -0.00 @ 24.3 | 0.11 | none | reveal 26 m before lip |
| Long Right -> Last Hump | +0.21 @ 24.1 | 0.36 | none | reveal 17 m before lip |
| Staircase -> Escalator | -0.00 @ 33.5 | 0.51 | none | reveal 27 m before lip |

Every foot is inside the 0.5 m/s threshold (worst: 0.23), no join
launches the staged driver at all, and every far side shows itself
17-27 m before its lip to a grounded eye. The only air left in the
audited windows is the Long Right arc's pre-existing wheel-flicker
pair (≈2.5 m hops, texture, unchanged). Feasibility re-proven by
stage 19 (3 laps, zero falls) on the new geometry.

### Repriced economy (stage 54's reference lap)

Payable air 17.48 s per lap (FP37: 30.63 s); projected income
174.8 units per lap (FP37: 259.1); longest starved stretch 500 m
(FP37: 250 m).

The blind flights were income: grounding them removed 13.2 s of the
lap's payable air and a third of its income. The starved stretch is
the price of the grounded Wall complex and the Escalator brow
standing back to back with their neighbours. Per the owner's standing
note (2026-11-02), the boost economy is revisited whole when he calls
it — this pass reports the repricing and does not retune it.

### New stage and census

- Stage 67 (new): the FP39 audit as standing proof — lap band and
  sector census, kv guards on every reworked shed (First Crest back,
  both Twin Crest backs <= 0.0055; Wall and Escalator brows
  <= 0.0045; Last Hump back <= 0.0085), the B2 reveal checks, and a
  one-lap drive audit staging all six feet, zone flights and falls.
- AMENDED (FP39, FLAGGED): stage 18 — lap band only (3,998 -> 4,066 m
  class); the Wall's gain, the dip, the curves census stand.
- AMENDED (FP39, FLAGGED): stage 29 — the climb-top launch case's
  band re-derived: a launch staged at the Wall's top now lands ON
  THE BROW (206 frames, 2.29 s) instead of flying to the Edge Run;
  the case's point (a real flight lands, no snatch) stands.
- AMENDED (FP39, FLAGGED): stage 49 — the fall-census stations
  re-derived from the reworked spans; "crest launches" reads "twin
  crests." No ribbon/lab/TRK2 stage moved; stage 35's conviction is
  what restored the chasm exit (above), not an amendment — its checks
  stand as written and pass on the restored geometry.
- Gates: smoke ALL 761 · ClassDB XR guard ALL 71 · render proof
  172/173 (the one miss is the standing sandbox hub-reach artifact,
  unchanged from FP38; the proof ran under Xvfb after the sandbox's
  headless draw path stopped firing frame_post_draw mid-pass — an
  environment fault, reproduced with a minimal script, not a build
  fault) · preflight inference audit clean on the two changed files.
  Two of stage 67's own kv windows and one zone tail were corrected
  in-pass (each had sampled a neighbouring piece — the corrections
  are flagged in the stage's comments; the geometry never moved).

🟨 **You're judging:** Track 01 in the headset — whether coming out of
the turns now reads fair: straight at the climbs' feet, and the far
side visible before you commit. The numbers above are Hal-side; the
verdict is your hands.

## Fix Pass 40 — THE PHYSICS PASS (warp fix, gearbox, fishtail, landing costs)

Four items from the owner's post-FP36/FP39 notes: a warp bug on
the biggest landings ("landing and going warping through
road… on especially high jumps"), a powertrain verdict ("hits
top speed too quickly, like the thing has 2 gears"; the launch
still not a burnout), a texture note ("a little fishtailing in
the rear when gunning it, until the tires finally catch"),
and a fairness note ("slamming into the side of hill nose
first" should cost speed; smooth landings should keep it).
Audits first, as ever — and the audit this time REFUTED the
brief's prime mechanism before convicting a subtler one.

### Item 1 — the warp: audit, conviction, fix

**What the audit staged.** Ballistic arrivals across a
vertical-speed sweep (ribbon flat: falls to 45 m, arrival vy
to −38 m/s; circuit: the Wall's face, the Twin Crests, the
Dive at −33 m/s, the Escalator, the First Crest, the Last
Hump) — and full-send driven runs over every jump sector.
**Pure frame-step tunnelling is REFUTED**: at 90 ticks/s the
landing window is 2.6 m tall, the fastest honest tick drop
measured was 0.45 m (at a −38 m/s arrival), and every staged
arrival — all sites, all speeds — landed. No warp there.

**Where it lives.** The driven runs found it on the first
sector they floored: after the circuit's biggest flight (the
Escalator's crest-off, 3.73 s, vy −20.9) lands at the head of
T13 — the long right home, −15° grade, −26° bank — the car
enters a **micro-hop storm**: it separates and re-lands every
~0.5 m, each re-contact graded HARD with the touchdown
readout climbing vy 4 → 10, the springs slamming to their
stops twice a metre, and the measured height over the road
ratcheting 0.43 → 0.16 m before saturating at the compression
clamp — the car riding visibly buried in the ribbon, hopping,
dent counter spinning. From the seat: you land from a big
jump and go warping through the road. It is layout-indepen-
dent (any steep, fast descent or crest train does it), which
matches the owner's "on original track as well".

**The mechanism.** `_land` graded the arrival by `air_vel.y`
in WORLD axes. A flight's vertical velocity is born (in
`_enter_air`) as the velocity's slope-following component —
on a −15° descent at 44 m/s that is ≈ −11 m/s of the road's
own fall rate. Every gentle re-contact was therefore graded
as a ~10 m/s HARD slam: full compression-velocity slam
(FP32's cv), rebound gate armed, dent, thump — and the next
separation (the road genuinely falls away at that pace)
started the cycle again, each slam driving the body lower
than the last. The landing law was charging the car for the
road's motion.

**The fix, two parts.** (a) **Road-relative arrival**: the
landing test's velocity bound and `_land`'s severity now read
the fall relative to the surface — `slope_vy − air_vel.y`,
where slope_vy is the surface's own vertical rate under the
car (the exact composition `_enter_air` builds a flight's vy
from, factored out as `_slope_vy_at`). On flat road slope_vy
is 0 and every number is the pre-FP40 one (stage 61's FP32
stroke proof is bit-identical: peak 0.298 m, time-to-peak
0.122 s). On a descent a re-contact now grades at the ~0.3 m/s
it actually closed at; into a rising face it grades HARDER
than the world reading (the staged Wall-face arrival and a
45 m fall onto the ribbon's climb face both read vy ≈ 31
relative against ~25 world — the face-slam is a face-slam).
(b) **Swept contact**: `_update_air` keeps the previous tick's
height, and a one-tick jump from above the landing plane to
below the window floor lands the car at the interpolated
crossing point — the structural guard so no projection
discontinuity can ever skip the window. The step is BOUNDED
at 1.2 m: the first, unbounded form convicted itself in
staging, "rescuing" debug-forced falls teleported 20 m under
the road (stage 49's census caught it — five recoveries
landed on the road instead of reaching the crane); the
debug AIR entries now also reset the sweep history, as
`_enter_air` and `_do_release` already did.

**Proof.** The staged sweep re-run: every arrival lands
(flat 45 m, Dive, Wall face — stage 68 holds them). The storm
fixture (stage 68): the same T13-head arrival + 1,500 floored
ticks now logs ONE touchdown and NO hard grade, min heave
+0.077 (the body never even dips to its rest offset, let
alone ratchets under the road), +0 dents. FP36's hop
authority is untouched (stage 65: drumbeat contact still
turns the velocity −3.61° in 0.30 s; the fishtail tax is
throttle-driven and that fixture runs at closed throttle).

### Item 2 — the gearbox

A real automatic box, 4 ratios, no new driver command.

| gear | band (m/s) | force at band bottom | at band top (×0.75 fade) |
|---|---|---|---|
| 1st | 0–11 | 22.0 | 16.5 |
| 2nd | 11–19 | 19.0 | 14.3 |
| 3rd | 19–33 | 15.5 | 11.6 |
| 4th | 33–48 (clamp) | 12.0 | 9.0 |

Force fades GEAR_BAND_FADE (0.25) across each band — the
power band: fattest just after a shift, breathless at the
top. A shift cuts the engine share for 0.13 s (the thrust
gap) and drops gear_rev (the band fraction), so the engine
audio — which now reads gear_rev instead of road speed —
sawtooths: measured pitch stations 0.98 at 34 m/s (4th's
bottom) vs 2.46 at 48 (its top), and stage 2f now proves a
climb inside first gear plus the drop across the 1→2 shift.
Downshifts carry 1.5 m/s of hysteresis. **First gear is
savage**: 22.0 of demand against the FP36 spin test's 11.0
cap — a floored launch now spins at peak **1.00** (FP36:
0.72), still spinning 0.84 at 8 m/s, hooked by 20 (0.02);
the Drop Start launch burns too (peak 0.83, was 0.34). The
under-cap feather moved: 0.45 (demand 9.9 < cap) never spins;
0.65 now spins at the line and hooks by 8 m/s (0.07) — both
are stage 65's standing cases now. Boost is unchanged (+16
after the box, never spin-tested): boosted 0–30 in 1.21 s.

**The run stretches into an event** (circuit opening,
standing start, audit instruments):

| figure | FP36 (flat 16) | FP40 (gearbox) |
|---|---|---|
| 0–10 / 0–20 | 0.84 / 1.57 s | 0.96 / 1.97 s |
| 0–30 | 2.31 s | **2.86 s** |
| 0–40 / 0–45 | 3.11 / 3.54 s | 4.28 / **5.13 s** |
| 0–48 | ~4.4 s | 5.76 s |
| top speed | 48.00 | 48.00 (unchanged) |

**The corner law survives**: stage 65's standard corner,
same frozen wheel — lift −2.06 m, full +2.58 m, spread
**4.65 m** (FP36: 5.11), both runs on the road. The throttle
still steers the line; third gear's slightly softer pull at
corner pace costs half a metre of spread, reported not
compensated.

**Fixture conviction (stage 26)**: the pass's first suite
runs failed the standing-start run (vmax 41.4, twice, to the
tenth) — an instrumented copy caught the cause: the fixture's
brake-stop set the brake but never closed the throttle, so
the stop silently depended on the test_throttle the autopilot
lap stages happened to leave behind. At FP36's pace the
leftover was 0 and the stop held; at the gearbox's pace the
laps end on a different autopilot phase, the leftover was
1.0, engine and brake fought to a ~14 m/s cruise (the diag
printed it holding 13.1 → 14.2 for the loop's whole 900
frames), and the "standing start" began rolling at s 141,
meeting the brow at 41.4. The fixture now stages both pedals
and requires a GROUNDED stop (mode DRIVE and speed ~0 —
`speed` freezes airborne, so a hop in the window must not
read as stopped either). Stage 68's gearbox stop carries the
same staging. Under the honest fixture the run reads exactly
the audit's numbers (top 48.0, 0–45 in 5.13 s, gears
[1, 2, 3, 4]).

### Item 3 — the fishtail

The rear axle's lateral capacity is taxed by its longitudi-
nal demand (one friction circle): the bleed's effective load
factor is multiplied by sqrt(1 − 0.75 · rear_u²), where
rear_u is the engine's applied demand over the FP36 spin
test cap — the same two numbers the wheelspin law already
reads. At cruise demand the factor is ~0.95 (the cruise
model is untouched for practical purposes); at a corner's
working demand (u ≈ 0.7) ~0.79; at full saturation 0.50.
The velocity lags the heading a beat longer under power and
the tail steps out; as the tires hook rear_u falls and the
bleed catches the slide — the catch-and-sway. Lift off and
the tax vanishes the same frame: the tail tucks back. The
rate was sized by measurement on both sides: 0.60 read only
+0.29° of slip over the lift-off run at the standard corner;
1.00 (the true circle) saturated the slip state outright in
the lab's off-camber S at working throttle (stage 58 P5:
slip 0.47 → 1.00, |lat| 1.49 → 6.14 — off the road), past
"a little" and destabilising, which the brief forbids. At
0.75: P5 keeps its margin (probe: slip 0.54, |lat| 1.63
against the 3.5 bound) and the standard corner reads
lift 1.76° → full 2.09° (stage 68 holds the pair). The
owner's spec was "a little", twice — this is texture, not a
drift mode, and stage 65's spread (above) and drumbeat
authority (−3.61°) both hold with it live.

### Item 4 — landing costs

A speed-retention curve inside `_land`, keyed to the arrival
the grade system already measures — contact grade, the
road-relative vy, and the body mismatch (misalign). Applied
to the forward component only, after the minimum-forward
guarantee; crane drops exempt (the drop's contract is
FP13's). Staged points (audit + stage 68):

| arrival (stage 68's staged set) | grade | retention |
|---|---|---|
| slope-matched, vy ~6 | CLEAN | 0.962 |
| vy ~9, lat 2.0 in | SCRUBBED | 0.694 |
| vy ~9, lat 5.0 in | CROSSED-UP | 0.544 |
| 12 m drop, side-pushed, into the face | CROSSED-UP | 0.338 |
| the crane drop | (exempt) | 1.000 |

(The audit's own staged points agree: CLEAN vy 5.8 → 0.985,
SCRUBBED/CROSSED vy 9.3 → 0.734/0.575, and a CLEAN vy 21.4
arrival under 34° of body tilt → 0.761 — the mismatch term
biting exactly as priced.)

The payout dials are UNTOUCHED (the owner's ruling: the
whole economy is revisited after the physics settles). The
repricing the curve + relative law cause, reported per that
ruling: stage 54's reference lap — circuit income 174.8 →
**185.1** units/lap (the managed driver keeps more speed
through its landings, so it flies more: lap air 18.51 s),
ribbon 104.2; longest starved stretch unchanged at 500 m.

### Census and gates

Full smoke suite on the shipped tree: **ALL 781 checks**,
ClassDB XR guard **ALL 71**; preflight (engine import +
quit-after) clean. Render proof: part-ran in the sandbox
(43 checks in ~25 minutes under neighbour load; the only
failure the standing wheel-hub reach reading, 0.31 m below
the eye — an llvmpipe capture artifact unchanged since
FP31, and FP40 touched no seat or wheel geometry). Its
captures in this commit remain the FP39 set, as FP37 did
before; the sandbox cannot settle colour or reach anyway —
the headset can.
Re-derived, each
flagged in place: stage 2f (rev law is the gearbox's:
within-gear climb + shift drop replace the speed pins),
stage 26 (the stop stages both pedals and waits for a
grounded stop; 0–45 band [4.6, 5.7]; pitch stations are
4th gear's band ends), stage 65 (0–30 band brackets the
stretch [2.5, 3.3]; the feather cases re-based at the
under-cap 0.45 + the 0.65 hook case). New: stage 68, this
pass's standing proof (18 checks — the arrival sweep, the
storm fixture, the gearbox run, the fishtail pair, the
retention curve and the drop exemption).
Unmoved: FP32's stroke (stage 61, bit-identical), FP36's
hop authority and yaw carry (stage 65), the funlab verdicts
(stage 66), the fair-hills census (stage 67), stage 49's
heading census (its five FP40-caught cases now drop at the
baseline's own stations: 100 / 1664 / 2202 / 3016 / 3560).

## Fix Pass 41 — THE LOOP PASS (tangent drive model, the loop-de-loop, funlab jump-ins)

Called by the owner after his first TRK2 session: "funlab is
brokelab. Silly robots dont know how to do a loop. Cant get
around loop so cant see other track elements" — with his
reference photo of the classic loop-de-loop: a full ring,
driven on the inside, in and out in the same direction. Four
items: the drive-model surgery, the loop working, the other
two elements re-audited on the new model, and jump-in access
so no element ever gates another.

### Item 1 — the surgery: velocity lives along the road tangent

The FP38 conviction was geometric: DRIVE carried the car's
velocity as a HORIZONTAL 2D vector and re-derived road
progress by projection, so progress died as the road went
vertical (progress ∝ vf·cos φ → 0 at φ = 90°) — the loop
wedged at φ ≈ 88–92°, fully supported, forever. The surgery
moves the state into the road's own frame: the velocity is a
3D vector (vel3) and the car's forward is a 3D direction
(drive_fwd) that lives in the road's tangent plane; each
DRIVE frame transports the forward into the current frame's
plane, decomposes the velocity against it and its in-plane
right, steers by rotating the forward about the road's up,
and integrates the position in 3D. Support, slope gravity
(gravity's component along the car's own forward; the
standing 0.85 drivetrain factor kept), bank gravity
(gravity's component along the in-plane right — the old term
carried one extra cos(bank) of projection) and the landing
conversion are all read in the same frame. On flat and
ordinary roads the frame IS the horizontal one and the two
models agree term for term; vel2 and car_heading survive as
accessors over the new state for the staged fixtures that
poke them.

Two folds had to be found and fixed on the way, both the
same disease one level down:

- **The frame itself folded.** _frame_at derived the road's
  up from the WORLD up (tan × UP), which dies at the
  vertical and comes back pointing out of the road's far
  side — past the fold the whole back half of the ring read
  as a crest with the car on the outside, and the
  road-frame curvature (kvf, below) flipped sign there.
  Fix: at build, a walk detects the fold (the level up
  flipping against its own predecessor — reachable only
  within a degree or two of the vertical) and TRANSPORTS
  the up through it by each step's minimal rotation,
  rejoining the level up where they agree again (for a full
  ring, exactly the exit flat). The carried up is stored per
  station and _frame_at prefers it where it exists. Only
  TRK2 has one: a parallel-transport frame everywhere was
  measured first and rejected — it deviates from the level
  frame by up to ~74° on Track 01, whose roads are authored
  against the level law. Stage 69 guards the boundary:
  circuit/ribbon/lab carry no upfix array, the funlab does.
- **The load law's curvature folded.** The suspension's
  load read the surface through world heights and the
  elevation angle's rate (kv, asin-based — the back half of
  a ring is indistinguishable from a crest through it).
  Where a patch's road up tips past ~60° from the world's
  (up.y < 0.5 — only TRK2 reaches it; Track 01's steepest
  reads 0.87), the load is now the road-frame NORMAL FORCE,
  N = −v²·kvf + g·(up), with kvf the frame curvature
  differenced from the tangent vectors themselves at build
  (the ring reads −1/R end to end). At the crown it is
  v²/R − g: a slow car is held by nothing and falls, a fast
  one is pressed in. In the same regime a wheel separates at
  any speed (its law does not return to 1 as v falls) and
  the all-four air entry no longer demands speed > 8 when
  every corner is in the regime — a car that stops ON the
  front wall (load = up.y, small but real) stays glued and
  rolls back in DRIVE; only the crown lets go.

The wheel sampling also moved into the plane: the four
patches are offset along the car's in-plane axes (on a wall
the front wheels are UP the wall, not ahead on the flat).
Everything else about the model — gearbox, fishtail,
retention, rebound, straddle, the FP39 storm law — is
untouched code reading the new frame's numbers.

### Item 2 — the loop-de-loop, working

TRK2's E1 was already the owner's reference geometry (full
ring, R ≈ 13 m, in and out at the base in the same
direction) — it was the model that could not drive it. On
the tangent model, staged entries measure:

- **Held at 22–32 m/s: clean.** No separations, no dents,
  exit at entry speed; the crown is driven fully inverted
  (car basis up.y −0.9999 in DRIVE) with the load pegged at
  its 1.25 clamp.
- **Floored from 24–30: clean**, around and out at 47–48.
- **The low edge is the crown's own line**, v = √(gR) ≈
  11.3 m/s: held at 14 the crown load reads 0.53 — exactly
  (v²/R − g)/g — and the car completes with two small hops
  at the entry/exit joins; held at 12 it completes with one
  exit hop; held at 11 it gets around ragged (five hops);
  held at 10 it comes off the ring and the crane collects
  it. Nothing wedges at any speed.
- **The honest defect band, held at 16–20:** the car goes
  around every time, but the FP14 rebound throw fires at
  the ring's abrupt curvature steps (the ring's curvature
  is a step at both joins — Track 01's brow law never
  allowed one, the FP38 ring was built with them). The hop
  is small (vy ≈ 0.9), but at 18–20 it lands the car past
  the exit where the ring's front wall passes 1.6 m over
  the exit road — close enough that the landing projection
  can catch the wall and put the car back at the entry: it
  laps the ring again instead of leaving. At 16 the throw
  comes on the crown's back and drops the car inside the
  ring to the crane. Floored entries sail over the band
  (the exit is taken at 46+); the band is a held-speed
  artefact, reported, not hidden.

The board now reads: CLEAN 22+ OR FLOORED - UNDER 12 THE
CROWN LETS GO.

### Item 3 — the other two, re-audited on the new model

- **E2 THE CORKSCREW: it lets go at the quarter-turn.** The
  FP38 reading (carried to bank ~165°, lost sideways) was
  the flat-world bookkeeping crediting support the road
  cannot give: the twist's centreline is straight, so the
  normal force is gravity's own component along the road's
  up — full at bank 0, zero at 90°, negative beyond, and no
  speed changes that. On the new model the car is carried
  centred (max lat 0.2 m) to bank ≈ 92° and separates, at
  every entry the probes ran (held 18–26, floored 30); the
  crane finishes it. Board: LETS GO AT THE QUARTER-TURN -
  NO SPEED HOLDS IT.
- **E3 THE BARREL ROLL: it hops all the way round.** The
  same law over a shorter twist: unsupported past the
  quarter-turn, but the tube keeps catching the car — it
  completes held at 20–26 and floored at 36+, in 23–26
  short flights, exiting at entry speed. Floored at 24–30
  the hops drift it out of the tube (max lat 7.9, past the
  7.17 fall line) and the crane collects it. Board: HOPS
  ALL THE WAY ROUND - HELD 20-26, FLOOR 36+.

### Item 4 — funlab access: the jump-ins

The owner's second count was a lab-design error: the
elements stood in series behind a known blocker. Each
element now has a jump-in station, searched at build with
the recovery search's own criteria (the nearest drop-ok
piece at least 20 m before the mouth whose 25 m run-up
reads clean, searched BACKWARD so a station can never sit
inside another element): E1 → s 86, E2 → s 320, E3 → s 643.
The green ELEM dash button (the spot the lean toggle
vacated in FP31; registered last so no existing control's
index moves) cranes the car to the NEXT element's station;
desktop E cycles, F1/F2/F3 jump direct (1/2/3 stay the prep
switches). The jump-in is the recovery's own hang — same
setup code — so the DROP button releases from it in every
phase (FP22's law) and the crane answers from any state the
new model can reach. Off TRK2 the control is inert. The
panel's command list names it in both its VR and desktop
sections, the standing rule. Stage 69 proves each element
reachable without passing another: hang at the station,
release, drive — the first element span entered is its own.

### Census and gates

Baseline first: the unmodified FP40 tree (3320b61) was
re-run on this machine before the surgery — SMOKE: ALL 781
CHECKS PASSED, API GUARD: ALL 71 CHECKS PASSED. That is
the census the new model had to reproduce. On the FP41
tree: **SMOKE: ALL 797 CHECKS PASSED** (781 + stage 69's
15 new checks + 1 net from the in-place amendments),
**API GUARD: ALL 71 CHECKS PASSED**, parse/import clean,
and the render proof at 172/173 — the one failure is the
standing wheel-hub reach artifact, identical on every
baseline since FP31 (the sandbox cannot settle reach or
colour; the headset can). The render proof also caught
the commands panel overflowing its board with the two
new ELEM lines (text 1.31 m vs the 1.24 m board); the
type shrank by the measured ratio — the FP12/FP29 remedy —
and the panel fits again with no occluded sightline.

UNMOVED, verified on the new model to the digit: the
FP32 landing census (stages 30–32, 49, 61); FP40's
retention numbers (CLEAN 0.962 / SCRUBBED 0.694 /
CROSSED-UP 0.544 / face slam 0.338, crane drops exempt
1.000); FP40's gearbox (gears [1, 2, 3, 4] in order,
0–45 m/s in 5.13 s, launch spin peak 1.00, biggest
one-tick rev drop 0.99) and stage 65's launches (floored
spin 1.00, Drop Start 0.83); the FP39 storm law (stage
68(1b): 1 touchdown, min heave 0.077, dents +0); FP36's
authority family. The heartland holds.

What legitimately moved — each re-derived and flagged in
place in the suite, none silently re-based:

- **Stage 38 (ribbon sweeper exit unload)**: the unload
  order flips RIGHT-FIRST (FP40: left-first at both
  axles, ~20 frames apart). A/B on the pristine FP40
  tree convicts the mechanism, not a bug: the tangent
  model carries velocity IN the road frame, so through
  the sweeper the velocity lags the road's own turning
  as lateral velocity the bleed must kill; the pinned
  line rides ~0.3 m wider on the downhill side and that
  side stays loaded ~50 frames longer. The wheelbase
  phase (front axle first) is intact. A world-yaw gain
  compensation was tried and REJECTED on measurement
  (the line ran wider still). This is the pass's one
  genuine handling-line change on an existing road.
- **Stage 29 (climb-top flight)**: lands at 145 frames
  vs the staged (150, 320) window. The old air-entry
  composed the launch vertical as vf·tan φ (the
  horizontal speed's slope rate); the tangent state
  carries the along-road speed, whose vertical is
  vf·sin φ — at the climb top's 28° the launch is
  3.0 m/s softer. Window re-based to (120, 320).
- **Stage 58 (lab flair)**: piece 2's bank-unwind lift
  pattern no longer reads "falling wheels only" (FP41
  measures mild [5, 7, 6, 9], run18 [7, 0, 9, 0], never
  full air); the check now guards the surviving law
  (never the whole car, total air frames at scale, no
  single wheel over 12). Piece 3's crest-2 flight
  measures 2.88 s vs [2.95, 3.7] — the same tan→sin
  composition as stage 29 (nominal 20°: 30·tan20 = 10.9
  vs 30·sin20 = 10.3 m/s) — window re-based to [2.7, 3.7].
- **Stage 68 (gearbox launch)**: the launch now waits
  out any live contact transient first (flagged in
  place). The (1b) STAGED arrival grades CROSSED-UP on
  the new model (lat 24.3 m/s, hdg −99.5°) and its
  honest 2.30 s contact transient — FP32/FP36 law: the
  tires are governed by the contact until the slide
  bleeds off — survives the warp and the 0.92 s staged
  stop and strangles the launch's spin (peak 0.00). The
  spin model itself is unmoved (the identical launch
  with no live transient peaks 0.996 on this tree, as
  on FP40); the stage's law is "first gear burns out
  from a standstill," and a standstill means a settled
  contact, so the precondition is explicit now. With
  it, the run reproduces FP40 exactly (above).
- **Stages 7 / 22 / 25 / 44 / 56 + the render proof's
  dash census**: the roster is eight controls — ELEM
  registered last; every existing index verified
  unmoved.
- **Stage 66**: the funlab verdicts replaced with the
  new model's measured rulings (Items 2–3).
- **Stage 69**: new (15 checks) — the tangent state
  tracks the road frame (fwd·tan 1.0000, vel.y −4.77 vs
  slope rate −4.77 at ribbon s 300's −13.7° descent;
  the check's first cut assumed flat ground there and
  failed on its own premise — the measured forward was
  the tangent's to the digit), the carried frame exists
  only on TRK2, the loop pinned at 24 goes around glued
  and drives inverted at the crown (basis up.y −1.00 in
  DRIVE), and the three jump-ins each hang at their own
  station, release, and enter their own element first.

FOUND, NOT FIXED (reported, owner's call): the staged
landing helper (debug_stage_landing) seeds its
swept-contact history from the car's PRE-teleport
position, so a staged landing's first contact can fire
across the teleport segment against a foreign frame —
the stage 68 arrival above is that artifact. The code
is identical on FP40, where the old heading-based
grading structurally masked it (every staged landing
read lat 0 / hdg 0 by construction). FP41's road-frame
grading exposes it. In real play the history is seeded
by the real _enter_air at every takeoff, so no shipped
behaviour carries it; fixing the helper re-derives
every staged landing in the suite and is its own pass,
not a stowaway in this one.

## Fix Pass 42 — THE MORE PASS (gearbox, fishtail, landing costs, the body-pitch channel)

Ordered on the owner's FP40 verdict: "everything is so
subtle as far as changes. more of everything is needed" —
warping confirmed gone from the seat. FP40's deltas were
honest on paper and timid in the car; this pass turns
every FP40 dial up until the seat can feel it, and adds
the amplifier the owner specified from his film study of
the original: "tilting forward, backward on shifting and
launch will help sell it."

### Item 1 — gearbox, MORE

First gear stretches ([11, 19, 33, 48] → [12.5, 19, 33,
48]) so the burnout lives in first a beat longer and
hooks just before the shift — bite, then shift, two
events. The top gears pull harder ([22, 19, 15.5, 12] →
[22, 19, 16.5, 12.5]). The shift gap lengthens 0.13 →
0.22 s. SPIN_KINETIC 0.85 → 0.72: a spinning tire pulls
less, so the burn lasts longer in time and the hook
contrasts harder. And the ear gets its share: inside the
gap the rev fall rate is 9.0/s (the standing smoothing
was 1.6/s), so the note sags with the gap and climbs the
new band — the one-tick audio-rpm drop at a shift goes
0.028 → 0.164. Staged floored launch, FP40 → FP42: spin
peak 1.00 → 1.00; spin at 8 m/s 0.84 → 0.87; last frame
over 0.5 spin 0.99 s → 1.19 s; hook 1.76 s → 1.93 s;
0–30 2.86 → 3.14 s; 0–45 5.13 → 5.40 s; time-to-top
5.77 → 5.98 s; top speed 48.00 unchanged; shifts at
12.55 / 19.05 / 33.03 m/s; biggest one-tick gear_rev
drop 0.99 (already full-size on paper — it was the ear
that couldn't hear it). The under-cap feather law is
untouched by construction (0.45 × 22 = 9.9 < the 11.0
cap): feathers 0.45 → spin peak 0.00; 0.65 → 0.38, 0.08
at 8 m/s. Drop Start launch spin 0.83 — the smoking
start stays.

### Item 2 — fishtail, MORE

FISHTAIL_TAX 0.75 → 2.00 (twice the true friction
circle), factor floor 0.16 → 0.0625. FP40's ceiling was
set by the staged driver leaving the lab's off-camber S
at TAX 1.00; the owner's hands asked past it, so the tax
no longer works alone — the CATCH: when the driver's
foot comes off (in_throttle falling > 0.05), a 0.30 s
window restores the bleed toward the tire's loaded
ceiling (× 1.35 peak, clamped at GRIP_LOAD_MAX 1.15,
never past it). The trigger is the foot, not the demand:
the first form armed on any rear_u fall and probe
measurement caught it armed 31% of frames in a
HELD-throttle corner (shift gaps and load noise),
diluting the tax it protected; on the foot trigger it
arms 0% of held-corner frames, and the S driver's
modulation still arms it — which is what he catches on.
A catch armed before a flight does not carry across it.
Measured, standard corner: lift slip 1.76° (unchanged —
lift restores full bleed the same frame); under full
power FP40 read 1.99–2.09° and that was all of it; FP42
sustains 2.09° (late-corner mean; lift's is 0.37) and
peaks 3.59° — the sustained angle is the new attitude,
the peak is the step-out the driver sees. Exit spread
lift-vs-full 4.65 → 5.14 m, full exit lat +2.81 against
the 7.17 fall line. The S keeps its margin at the new
setting (slip_state 0.47, |lat| 1.43 — its FP40 margins
against the 3.5 bound): more tail and the same S
survival coexist, no trade to report.

### Item 3 — landing costs, spread wide

Retention of the forward component in _land; payout
dials untouched (economy ruling). CLEAN:
clampf(1.02 − vy·0.003, 0.96, 1.0) — a slope-matched
arrival keeps essentially everything (staged ~1.000;
FP40 0.962–0.985). SCRUBBED: clampf(0.87 − vy·0.024,
0.45, 0.78) — staged ~0.60 (FP40 0.694). CROSSED-UP:
clampf(0.68 − vy·0.024, 0.24, 0.52) — staged ~0.41
(FP40 0.544); the nose-first slam (12 m, side-pushed)
~0.22 (FP40 0.338) — almost nothing kept. Misalignment
multiplier floor 0.75 → 0.70. Crane drops stay exempt
at 1.000. Repricing, reported not compensated: the
offer's dials are unchanged and stage 54's identity
holds; the audit lap's projected offer moves only with
its pace — circuit 185.1 → 181.3 units/lap (payable air
18.51 → 18.13 s), ribbon 104.2 → 104.5, longest starved
stretches unchanged (circuit 500 m, ribbon 250 m). What
retention reprices is realized speed, not boost.

### Item 4 — the body-pitch channel

One honest force-driven channel, not scripted animation
— the Crammond law from the owner's film study: pitch
is a load gauge. A damped oscillator (LOAD_PITCH_K
0.0055 rad per m/s², spring 48.0, damping 5.8, clamp
0.11 rad ≈ 6.3°) targets −K × the filtered longitudinal
acceleration in DRIVE and settles to 0 out of it; it
adds over the suspension sink in the view spring. The
old one-sided brake term (a clamped 0.0016 rad per unit,
positive-only) is deleted — the channel covers both
signs at full strength. DIAG's SPD line appends PITCH
%+.1f degrees: the channel is surfaced, per the rule
that what the driver judges gets shown. FP40's channel
read launch −0.01..+0.46° and braking 0.73° — a rumor.
FP42 measures: launch squat −4.48°; a 3.37–3.68° swing
at the first shift (squat through the gear, dip forward
as thrust cuts in the gap, squat again as the next gear
bites); full-brake dive +4.44°. Touchdown sink timing
unmoved — stage 61's FP32 numbers (peak 0.298 m,
time-to-peak 0.122 s) are bit-identical; the channel is
additive over the sink, not in its path.

### Census

- **Stage 9 (flagged in place)**: the outside-staircase
  GEOMETRY height tier 0.014 → 0.022. The step is the
  FP8 mechanism — sweeper-exit bank unwind acting
  through the car's lateral offset — and Item 2's tax
  makes the staged car run a genuinely wider powered
  line through that exit (lat +5.03 at s 165 vs FP41's
  +1.8). One-variable proof (probe42b): FP42 tree reads
  0.0174 solo / 0.0180 in-suite; the same tree with ONLY
  the tax and floor reverted to FP40's 0.75 / 0.16 reads
  0.0090 with lat tucked at +0.8 — FP41's line, FP41's
  step. The car stays on the road (edge 6.0, fall line
  7.17), the lap completes, and the wider line is the
  item working as ordered. Pitch tier (0.205° read) and
  staircase tier (0.0124 m) unmoved.
- **Stage 68 (flagged in place)**: the corner fixture
  returns sustained slip; new checks pin the sustained
  delta (full > lift + 1.0, full > 1.5) from the probe
  table; retention bands re-derived for Item 3's curve
  (SCRUBBED [0.66, 0.82] → [0.52, 0.68], CROSSED-UP
  [0.50, 0.66] → [0.34, 0.48], slam [0.28, 0.50] →
  [0.15, 0.29]; CLEAN [0.94, 1.0] kept).
- **Stage 70 new**: launch squat and shift swing from a
  settled floored start (reads −4.48° / 3.37°), brake
  dive (+4.44°), DIAG PITCH surfacing, and the tuck.
  The tuck's staging was amended in-pass (flagged in
  place): the first form held the wheel pinned past the
  cut and could never pass — at 32 m/s and full lock the
  corner's own slip floor is ~1.1° on any bleed setting,
  and the lock walks the car off the road at +140 frames
  (probe42c). Restaged as the driver's real input pair,
  lift + unwind: slip 2.20° at the cut dies under 0.6°
  at ~+17 frames, lat_vel reversed by +30. A/B with the
  catch gain zeroed crosses at ~+20 frames — the tax
  restoration on lift is the dominant term, the catch is
  margin on top, and the check guards the pair as
  shipped.
- Everything else in the FP41 census holds: the tangent
  model's laws, the loop's clean window and crown,
  funlab rulings, the FP39 storm law, FP32 landing
  timing, the economy identity.

Gates: preflight audit clean; parse clean; SMOKE ALL
803, API GUARD ALL 71; render proof 172/173 (the
standing wheel-hub reach artifact only — 0.31 m below
the eye, identical on every baseline since FP31; this
pass touched no seat or wheel geometry).

Stamp: FP42 · 2026-11-03. What the seat still owes: the
verdict. A burnout you manage, a tail you can see, a
slam that costs you the run's speed, and a body that
leans on its springs when the box changes its mind —
all of it is tuned past the staged ceilings on the
owner's word, and only his hands can say whether MORE
was the right amount.

## Fix Pass 43 — THE FUNLAB REBUILD (the loop at its base, the true helix, the wall-ride)

Ordered on the owner's FP41 field verdicts: the loop
"works as a loop" but "doesn't have correct entry, exit
point"; the corkscrew "just doesn't have any stick, not
gonna work." The reference shelf is his Hot Wheels
census: every HW loop is tangent at its base (entry and
exit are the same straight), the Mega Garage tower is a
true helix, and the near-flat rings are wall-ride 360s.
The funlab is rebuilt to those three forms. Course
length 849 → 1,048 m.

### Item 1 — the loop, rebuilt at the base

The ring is planted on the road's own line: a 92-step
index-symmetric curvature profile (smoothstep ramps
over the first and last 12% of the ring, plateau
R = 12.89 m) whose step-end geometry closes exactly —
the exit lands ON the entry line, 11.0 m ahead, same
direction (closure: d_lat 0.000, d_up −0.001), crown
26.0 m over the entry. The curvature now eases at the
joins: max |Δkvf| 0.0102 per station against the old
ring's 0.0765 in a single step. Staged audit: pins
18/20/22 go around CLEAN, zero airs, exit at entry
speed; floored from 24 exits at 42.7. Pin 16 comes off
on the crown approach (s 151, ~160° around, one air,
the crane collects it) — not at a join: the static
crown load at 16 is +1.02 g, the loss is a transient on
the way up, and FP41's 16–20 rebound defect band (the
rebound throw firing at the ring's curvature steps) is
retired — the joins are clean at every speed tested.
Pin 14 hops over the top (9 airs) and comes off at the
exit ease. Board: "CLEAN 18+ OR FLOORED - 16 COMES OFF
AT THE TOP".

### Item 2 — the corkscrew, rebuilt as a true helix

The straight-centreline roll is replaced by a helix:
the centreline itself spirals (orbit radius 5.0 m, axis
advance 10.0 m per radian, axis = the −6.5° run-in
tangent, ~69 stations), and the road's up follows the
path's principal normal, so the surface curvature reads
kvf = −0.0399 through the core — κ = a/(a²+c²) = 0.0400,
the helix's own. The holding force is the path's,
provably, not a script's. On a helix of this pitch the
pressing surface rolls ~640° per orbit (the 360° orbit
plus the tangent cone's twist): this is a DOUBLE-roll
corkscrew, two inversions on every completing run (min
up.y −1.00) — a one-roll surface cannot press here;
mid-element it faces ~167° off the turn and its
curvature flips sign. The run-in pre-rolls across its
30 m at 0.0673 rad/m to meet the helix's first-station
bank (−115.7°) within 4°. Static minimum loads, read at
the deep crown: +0.25 g at 14, +0.63 at 16, +0.85 at 18,
+0.95 at 20, +1.20 at 24. Drives: 14–20 complete, exit
at entry speed, with 1–3 short hops at the tube-bottom
twist (frame up.y ≈ +0.9) — the surface-twist tax, the
same family as the barrel roll's hops. At 24+ the
failure is lateral, not load (the crown still reads
+1.20 g): the car slides off the exit wall at ~8 m of
lat and the crane collects it. Board: "DOUBLE ROLL,
TWO INVERSIONS - HOLDS 14-20 - 24+ SLIDES OFF THE EXIT
WALL".

### Item 3 — NEW PROTOTYPE E4: the wall-ride 360

A full-circle steeply banked turn that rejoins its own
entry (the hw6 form): R = 28 m, bank 55°, yaw trapezoid
ramps, 200 m of course. Neutral speed √(g·R·tanβ) =
19.8 m/s. Closure: d_fwd 24.83, d_lat 0.030, d_up
0.000; the frame's up.y holds 0.54–0.57 all the way
round — banked hard, never in the steep regime. Staged
audit: pins 14/17/20/23/26/30 ALL clean, zero airs,
exit at entry speed, heading sweep 360–362°, lateral
band −0.38..+1.84 m. Hands-off at 20 sheds (lat 8.0) —
it is a banked turn, not a slot; the line is the
driver's. Board: "STEER IT - HOLDS 14-30, NEUTRAL
AT 20".

### Jump-ins, and the one defect the suite caught

Stations re-derived on the rebuilt course: E1 90,
E2 298 (the search walks back past the pre-rolled
run-in), E3 562, E4 704. Stage 69 proves each one
hangs, releases, and drives into its OWN element first
(F4 joins F1/F2/F3 on the desktop; the commands panel
names it). The suite caught one real defect on the
way: E3's search first returned 298 — the barrel
roll's approach rides at −2 whole turns of stored bank
(the offset chain that keeps the course's bank scalar
seamless), and _drop_piece_ok / _drop_runup_ok read the
raw stored value as "banked," walking the search back
to the corkscrew's run-in. The helpers now read the
wrapped bank (flagged in place); the same fix covers
recovery drops anywhere on the funlab. No census track
stores a whole turn of bank, so the wrap is
behaviour-identical off the funlab — the full suite
re-proves it. E3 itself is untouched except its
station: floored at 36 it still completes in 28 hops,
exit 16.2, max lat 2.43 — its FP41 signature intact.

- Everything else in the FP41/FP42 census holds: the
  tangent model's laws, the FP39 storm law (1
  touchdown, 0 HARD after the T13 arrival), the gearbox
  (0–45 in 5.40 s, four gears in order), the fishtail
  (peak 3.59°, sustained 2.09°), landing retention
  (0.964 / 0.600 / 0.424 / 0.215, crane drop 1.000),
  the body-pitch channel.

Gates: preflight audit clean; parse clean; SMOKE ALL
810, API GUARD ALL 71; render proof 172/173 (the
standing wheel-hub reach artifact only — 0.31 m below
the eye, identical on every baseline since FP31).

Stamp: FP43 · 2026-11-03. What the seat still owes: the
verdict — the loop's feel (including the old 16–20
band, now joins-clean), whether the helix's two rolls
read as a corkscrew from the driver's seat, the
wall-ride's wall, and the four jump-ins.

## Fix Pass 44 — LONG GEARS + THE PEEL-OUT

Ordered on the owner's FP42 verdict: "Gear ratios just
aren't right. It runs through them too quickly, you
reach top speed too quickly and are usually left
wanting for more. An odd rod should always have more
to give." Plus: "still not feeling effect from rear
tires, no peeling out sensation."

### Item 1 — long gears: top speed is a reserve

The spread is rebuilt tall: bands [16, 30, 41, 71],
forces [22, 15, 11, 8.5] (FP42: [12.5, 19, 33, 48] /
[22, 19, 16.5, 12.5]), and the clamp rises 48 → 71 —
not a new state to sit in but a reserve: top gear's
faded force meets the drag at ~67–68 m/s on the flat,
so the clamp is reached only with help. Staged: shifts
at 1.64 / 3.21 / 5.37 s; 0–30 in 3.20 s (FP42: 3.14);
0–45 in 6.76 s (5.40); the old 48 point arrives at
7.63 s (6.01) deep in top gear at rev 0.23, still
pulling +3.2 m/s². Pinned at 60 the car still pulls
(62.15 after 2.25 s); pinned at 70 it falls away from
the clamp toward equilibrium (68.97); boost from 60
buys the ceiling back (70 in 0.62 s). THE INTERLOCK,
against the owner's straights-are-breaths law: a
staged Track 01 lap spent 10.74 s of 125.7 s AT the
48 ceiling under FP42's box; under FP44 it spends
0.00 s at the ceiling, with lap vmax 62.3 — past the
old ceiling, never at the new one. First gear is
untouched at 22, so the burnout and the 0.45 feather
law survive by construction; the shift gap, rev sag,
automatic box and GEAR on DIAG are kept whole.

### Item 2 — the peel-out, as a sensation

FP42's spin was real (peak 1.00) but reached the
seated driver through no channel. Three channels now
carry it, all staged in the new stage 71:

- AUDIO: a dedicated spin voice (660 Hz fundamental
  with exact-cycle partials + shredded noise), keyed
  to wheelspin × rear load, peaking at −10 dB over the
  engine's −17 dB song; staged gain 1.00 in the burn,
  0.003 a second after the hook. Full latch/watchdog/
  silence-by-default discipline. The skid voice's
  wheelspin component is removed (flagged) — the spin
  has its own voice now.
- SEAT: a spin-driven shudder at the body application
  (8 Hz; 0.0119 m peak-to-peak in the burn, 0.0001 m
  once hooked), on its own envelope — FP32's sink law
  and FP42's pitch channel are untouched, and
  `body_sink` never carries it.
- YAW HUNT: a 2.1 Hz yaw oscillation under power
  while the rears spin (3.23° peak-to-peak of heading
  wander in the burn, 0.18° after the hook, 0.000° on
  a feather). Applied as an offset on the frame's yaw
  only — never written into the yaw state, so a
  separation still stores the wheel's yaw. (The first
  form wrote it into the state and the yaw lag
  integrated it ~6×, to a 20.7° wander; its own probe
  convicted it before the suite saw it.)

### Census and the three fixture defects

The FP41–43 census holds (loop window and crown,
helix hold, wall-ride law, storm law, stage 65's
spin law). The retention law is untouched and its
fixtures pass in their FP42 bands; their point
readings are now 1.000 / 0.631 / 0.446 / 0.228
because the staged arrivals finally fly on their
own basis (tilts 5° / 11° / 11° / 27° — the FP42-era
readings were taken through a stale one).
Legitimate moves, re-derived and flagged in place:
the fishtail's standard-corner readings (peak
3.59° → 2.52°, sustained 2.09° → 1.76° — second gear
asks less of the rear at the staged 18 m/s in both
eras; the tax constants are untouched), stage 26's
powertrain stations (its run now ends at the s 220
hump at 47.7; its pitch stations move into third
gear, reading 0.99 / 2.39 against the formula's
0.97 / 2.56), and stage 9's height tier (0.022 →
0.030 on a one-variable proof: FP43 constants on
this tree read 0.0175). The pass also caught three
fixture defects, all flagged at the site: the lap
loops' instant release wedging forever on an
attach-phase drop at a fall site (they now release
at the dangle; production's any-phase release is
untouched); stage 67's fairness-audit lap running
the raised envelope its driver cannot brake for
(it now runs at its design pace — J2's foot reads
0.02 — and the raised pace's lap is stage 71's
subject); and the staged-landing helpers never
recording a takeoff basis, so graded landings flew
on stale state (one line each; the fixtures now
read their staged arrivals honestly).

Economy repricing, report only (dials untouched,
per the 2026-11-02 ruling): Track 01's projected
income 181.3 → 187.0/lap on payable air 18.70 s;
the ribbon 104.5 → 96.3 on 11.66 s; starved
stretches unchanged (500 m / 250 m).

Gates: preflight audit clean; parse clean; SMOKE
ALL 832 (810 + stage 71's 22), API GUARD ALL 71;
render proof 172/173 (the standing wheel-hub reach
artifact only, identical on every baseline since
FP31).

Stamp: FP44 · 2026-11-03. What the seat still owes:
whether the long pulls feel like an Odd Rod that
always has more to give; whether the peel-out lands
— the squeal over the engine, the shudder through
the seat, the hunt at the wheel; and the carried
FP43 verdicts (loop feel incl. the 16 m/s crown
transient, the helix from the seat, the wall-ride,
the four jump-ins).
