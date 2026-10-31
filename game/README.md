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
- Throttle: right trigger · Brake: left trigger · Boost: right A
  button (while driving) — since Fix Pass 24 the boost is a
  tank (120 units = 4 s, 60 dealt at the start) that racing
  air refills at graded landings; the dash-face bar in the
  button cluster's row is its meter
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
- Call the drone (while driving): left X button
- Restart race: left Y button · Info panels show/hide: right B
  button (Fix Pass 12 — the boards are hidden by default; B
  calls them up and puts them away. Lean experiment on/off
  lives on the green dash button now; red dash button = restart)
- Switch track (while dangling): GRIP near the purple dash button —
  the mountain circuit (default) and the original test ribbon;
  a circuit race is 3 laps to the finish, the ribbon is
  point-to-point
- Recenter: click the left stick
- Road-jitter experiment on/off: click the right stick (state shows
  as JIT in the DIAG block; default ON)

Desktop fallback (no headset): the mirror rig drives the same car.
- W/S throttle/brake · A/D steer · SHIFT boost · SPACE release
- 1/2/3 flip FUEL/SPARK/BOOST · L call drone · R restart · V switch track
- T lean experiment on/off · Q/E lean body left/right · C recenter
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
# sequence -> boost credit -> release -> driving -> lean grip A/B
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
