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
- **Release from the drone:** right trigger (while dangling)
- Flip a prep switch / press a dash button: GRIP near it (while
  dangling) — since Fix Pass 9 either order works: squeeze-then-touch
  or touch-then-squeeze; the flip fires when grip and proximity
  meet, once per entry
- Call the drone (while driving): left X button
- Restart race: left Y button · Lean experiment on/off: right B button
  (or the green dash button; red dash button = restart)
- Recenter: click the left stick
- Road-jitter experiment on/off: click the right stick (state shows
  as JIT in the DIAG block; default ON)

Desktop fallback (no headset): the mirror rig drives the same car.
- W/S throttle/brake · A/D steer · SHIFT boost · SPACE release
- 1/2/3 flip FUEL/SPARK/BOOST · L call drone · R restart
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
