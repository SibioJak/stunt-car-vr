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
the drone catches you) → descent → finish gantry.

Fall off anywhere, or call the drone yourself: it carries you back over
the ribbon, you dangle, you may flip the 3-switch prep sequence shown
on the dash (wrong switch = restart the sequence; finishing pays +25
boost), then you time the release again. Release away from the track
and you fall — and the drone catches you again.

## Controls (also listed on the in-cockpit panel — every command)

VR (Quest):
- **Grab wheel:** squeeze GRIP near the wheel, turn the hand. Last
  hand to grab drives; the other hand takes over when it lets go.
- Throttle: right trigger · Brake: left trigger · Boost: right A
  button (while driving)
- **Release from the drone:** right trigger (while dangling)
- Flip a prep switch / press a dash button: GRIP near it (while
  dangling)
- Call the drone (while driving): left X button
- Restart race: left Y button · Lean experiment on/off: right B button
  (or the green dash button; red dash button = restart)
- Recenter: click the left stick

Desktop fallback (no headset): the mirror rig drives the same car.
- W/S throttle/brake · A/D steer · SHIFT boost · SPACE release
- 1/2/3 flip FUEL/SPARK/BOOST · L call drone · R restart
- T lean experiment on/off · Q/E lean body left/right · C recenter
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
  with the lean at LEAN_VIEW_GAIN 2.5× a 10° step (symmetric, zero
  at centre); OFF restores the level view exactly. Grip effects
  unchanged.

UNVERIFIED (live feel — only headset run 6 proves these): whether
the suspension reads as HEAVY, whether the bounce and the dangle's
new precariousness land as feel rather than motion, and whether
the amplified lean tilt registers without fighting his head.

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
