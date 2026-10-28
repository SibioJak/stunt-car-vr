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
  button (while driving)
- **Release from the drone:** pull the DROP SHIFTER on the right
  pod, forward beside the wheel (while dangling) — Fix Pass 11
  retired the trigger release for the lever, Fix Pass 12 moved
  it forward and shortened it into a gear shifter
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
