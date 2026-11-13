# FIX PASS 41 — THE LOOP PASS (as built)

Owner's GO: 2026-11-03. Base: master `3320b61` (FP40).
BUILD_STAMP: "FP41 · 2026-11-03".
Called by the owner after his first TRK2 session: "funlab is
brokelab. Silly robots dont know how to do a loop. Cant get
around loop so cant see other track elements" — with his
reference photo: the classic loop-de-loop, a full ring driven
on the inside, in and out in the same direction.

## Item 1 — the surgery: velocity along the road tangent

- **State**: `vel3: Vector3` is the velocity; `drive_fwd:
  Vector3` is the car's forward in the road tangent plane.
  `vel2` and `car_heading` survive as accessors (vel2 = vel3's
  XZ shadow; car_heading get = atan2 of drive_fwd when its XZ
  length > 0.05 else the backing `_heading_yaw`, set = stores
  the backing and re-aims drive_fwd in DRIVE) — the staged
  fixtures that poke them (stages 29/37/49/62/63) keep working.
- **DRIVE**: the forward is transported into the current
  frame's plane each tick (project out the road up,
  renormalize; fallback = the frame tangent); velocity
  decomposes against it and its in-plane right; steering
  rotates the forward about the road's up by the same yaw
  increment the heading used to integrate; position integrates
  in 3D; (s, lat) re-derived by projection as before. Slope
  gravity = −GRAV·drive_fwd.y·0.85 (identical to the old
  −GRAV·tan.y·0.85 wherever the car follows the road). Bank
  gravity = −GRAV·r.y (the old term carried an extra cos(bank)
  of projection; ≤13% of a ≤4.9 m/s² feed at bank ≤30°,
  bleed-damped — flagged, and it is the term the corkscrew
  needs past 90°). Gearbox/brake/drag/ellipse/spin/fishtail
  code untouched.
- **The frame fold (found in-pass, fixed)**: `_frame_at`'s up
  comes from tan × world-UP and folds at the vertical — the
  ring's back half read as a crest, car on the outside. At
  build, `_finalize_track` walks the stations: where the level
  up flips against its predecessor (dot < 0 — only reachable
  near the vertical) it TRANSPORTS the up by minimal rotations
  until the level up agrees again (dot > 0.99 off the
  vertical); the carried array is stored as the track's `up0`
  and `_frame_at` prefers it. Only TRK2 folds. The global
  alternative was measured and rejected: parallel transport on
  Track 01 deviates up to 74° from the level frame the roads
  are authored against (ribbon 77°, lab 68°). Stage 69 guards
  the boundary (census tracks carry no upfix).
- **The load law (found in-pass, fixed)**: where a patch's
  road up tips past ~60° (up.y < 0.5 — TRK2 only; Track 01
  peaks at 0.87), the height-stencil curvature is meaningless
  (divides by the tangent's horizontal run). The load there is
  the road-frame normal force N = −v²·kvf + g·(up.y), in g
  units, clamped [0, 1.25]. `kvf` = −(dT/ds)·up_b differenced
  from the build's smoothed tangents with the carried frame
  (ring: −0.0765 = −1/13.05 end to end; rolls ≈ 0). In the
  regime, wheels separate at any speed and the all-four air
  entry drops its speed > 8 demand when all four corners are
  in the regime — the crown lets a slow car go; a car stopped
  on the front wall (load = up.y ∈ (0, 0.5)) stays glued and
  rolls back in DRIVE.
- **Placement**: the car basis is the frame itself —
  Basis(in-plane right, road up, −drive_fwd) with edge_roll on
  top (the asin re-expression it replaces folded at the
  vertical). Wheel sampling offsets ride the in-plane axes.
- **Landings**: `_land` takes the flight in the road frame —
  forward = the flight basis's forward projected into the
  landing frame; the road takes the normal component of
  air_vel, the plane keeps the rest; FP40's road-relative
  grading/retention above it untouched; heading error is the
  in-plane angle (reproduces the old sign convention on flat).
  `_enter_air` is now just vel3 + the caller's vy increment.

## Item 2 — the loop (TRK2 E1, ring R ≈ 13.05, s 110..192)

Staged entries (pin = speed held, floor = throttle past the
mouth), final model:

| entry | outcome |
|---|---|
| pin 22–32 | clean, 0 airs, crown load pegged 1.25, exit = entry |
| floor 24 / 30 | clean, 0 airs, exit 46.7 / 47.6 |
| pin 14 | completes, 2 join hops, crown load 0.53 = (v²/R−g)/g exactly |
| pin 12 | completes, 1 exit hop |
| pin 11 | completes ragged, 5 hops |
| pin 10 | comes off the ring, crane collects it — no wedge |
| pin 16 | around, rebound throw on the crown's back drops it inside → crane |
| pin 18 / 20 | around, exit-join throw (vy ≈ 0.9) hops it where the ring's front wall passes 1.6 m over the exit road; the landing projection catches the wall and re-stations it at the entry — it laps the ring again |
| coast 16 / 20 / 24 | around (2–3 join hops), coasts to a stop on the run-out |

Crown law check: the fall line v = √(gR) = 11.3 m/s sits
exactly between pin 11 (around) and pin 10 (off). Crown
inversion in DRIVE: basis up.y −0.9999. The 16–20 held band
is the pass's honest defect: the FP14 rebound fires at the
ring's curvature STEPS (the FP38 ring steps 0 → −1/R at both
joins; Track 01's brow law never allowed a step) — reported
in the README, not tuned away (the throw is FP14's settled
mechanism; easing the ring's joins is a geometry call for
the owner).

Board: "CLEAN 22+ OR FLOORED - UNDER 12 THE CROWN LETS GO".

## Item 3 — corkscrew and barrel roll, re-audited

- **E2 corkscrew**: separates at bank ≈ 92° at every entry
  (pin 18–26, floor 30), max lat 0.21, crane collects it at
  the separation point. Physics: straight centreline ⇒ the
  normal force is g·cos(bank) — zero at the quarter-turn, no
  speed term exists. FP38's "carried to 165°" was the old
  bookkeeping's lie. Board: "LETS GO AT THE QUARTER-TURN -
  NO SPEED HOLDS IT".
- **E3 barrel roll**: completes pin 20 / 26 and floor 36 / 42
  with 23–26 short flights (the tube re-catches it each
  time), exit at entry speed, max lat ≤ 2.1; floor 24 / 30
  drifts out (max lat 7.9 > 7.17) to the crane. Board: "HOPS
  ALL THE WAY ROUND - HELD 20-26, FLOOR 36+".

## Item 4 — funlab jump-ins

- Stations searched at build with the recovery criteria
  (2 m strides BACKWARD from mouth − 20; `_drop_piece_ok` +
  `_drop_runup_ok`): E1 → s 86, E2 → s 320, E3 → s 643,
  stored as the element rows' 6th field.
- `_setup_hang_at()` extracted from `_begin_recovery` (one
  hang setup for recovery and jump-ins alike). `_goto_element(i)`
  mirrors the recovery's head and stations the crane there;
  `_cycle_element()` picks the next element ahead of the
  hang's station or the car's s, wrapping to E1. Both inert
  off TRK2.
- Controls: green ELEM dash button at (−0.52, 0.95, −0.60)
  — the lean button's vacated spot — registered LAST (no
  existing index moves; stage 23's audit covers it). DIAG
  short name ELEM. Desktop: E cycles, F1/F2/F3 direct
  (1/2/3 remain the prep switches — a conflict caught during
  the pass; the panel and README both say F-keys). Panel
  lists the control in its VR and desktop sections (standing
  rule); README controls mirror it.
- DROP releases from the jump-in hang in every phase (it IS
  the recovery hang — FP22's law). Stage 69 proves per
  element: hangs at its own station → releases → drives →
  the first element span entered is its own.

## Census exceptions found in-pass (all flagged in place)

- **Stage 38 (sweeper exit unload)**: the tangent bookkeeping
  carries the velocity with the road frame, so through the
  banked sweeper the velocity lags the road's turning as
  lateral velocity for the bleed — the pinned 30 line rides
  ~0.3 m wider than the heading-frame line (A/B traces against
  the FP40 tree: lat +0.65 vs +0.34 at the bank's peak) and the
  downhill side stays loaded ~30 frames longer: the exit
  unload order inverts from FP21's left-first (229/249/237/259)
  to right-first (279/248/292/258 — the right side's frames
  unmoved; the left side's delay is the whole delta). The
  wheelbase phase is unmoved. A world-yaw steering-gain
  compensation (rotate by yaw/up.y) was tried and REJECTED on
  measurement: the line ran wider still (+0.87 m) — the
  mechanism is the frame carrying the velocity, which is the
  surgery's premise. Stage 38 amended in place with the
  mechanism written down; this is the pass's one genuine
  handling-line change on an existing road, reported as such.
- **Stage 29 (climb-top flight)**: lands at 145 frames vs the
  staged > 150 — the old air-entry composed the launch
  vertical as vf·tan φ (the horizontal speed's slope rate);
  the tangent state carries the along-road speed, whose
  vertical is vf·sin φ. At the climb top's 28° the launch is
  3.0 m/s softer. Window re-based (120, 320), flagged.
- **Stages 7 / 22 / 25 / 44 (dash roster)**: the ELEM button
  is a deliberate 8th control registered last — roster counts
  and "registered last" superlatives amended in place, every
  existing index verified unmoved.
- **Stage 66**: amended in place to the new elements' rulings
  (Items 2–3 above). **Stage 69** is new (this pass's proof:
  flat invariants, the carried-frame boundary, crown
  inversion in DRIVE, the three jump-ins, off-lab inertness).

## Census and gates

Baseline (unmodified 3320b61, re-run before the surgery):
SMOKE ALL 781, API GUARD ALL 71. FP41 tree: **SMOKE ALL
797 PASSED, API GUARD ALL 71 PASSED**, parse/import and
--quit-after clean, render proof 172/173 with only the
standing wheel-hub reach artifact (identical on FP31–FP40
baselines; the headset settles reach/colour). The render
proof also caught the commands panel overflowing its
board with the new ELEM lines (1.31 m of text vs the
1.24 m board) — type shrunk by the measured ratio (the
FP12/FP29 remedy) to pixel_size 0.000785; panel fits, no
occluded sightline, dash census amended to eight controls.

UNMOVED to the digit: FP32 landing census; FP40 retention
(0.962 / 0.694 / 0.544 / 0.338, crane exempt 1.000); FP40
gearbox (gears in order, 0–45 in 5.13 s, spin peak 1.00,
rev drop 0.99) and stage 65 launches (1.00 / 0.83); FP39
storm law (1 touchdown, heave 0.077, dents +0).

MOVED, re-derived and flagged in place: stage 38 sweeper
unload flips right-first (road-frame velocity lags the
road's turning; line rides ~0.3 m wider downhill; a
world-yaw gain compensation was measured and rejected);
stage 29 climb-top flight 145 frames (launch vertical is
vf·sin φ now, not vf·tan φ; window (120, 320)); stage 58
piece 2 lift pattern (never full air; per-wheel ≤ 12) and
piece 3 crest-2 flight 2.88 s (window [2.7, 3.7], same
tan→sin family); stage 68's launch now waits out a live
contact transient (the staged (1b) arrival honestly
grades CROSSED-UP — lat 24.3, hdg −99.5°, 2.30 s
transient — where FP40's heading-based grading read
every staged landing as lat 0 / hdg 0; the spin model
itself peaks 0.996 untransiented on this tree); roster
stages 7/22/25/44/56 (eight controls, ELEM last, indices
unmoved); stage 66 replaced with the measured funlab
rulings; stage 69 new (15 checks — tangent tracking
exact, carried frame TRK2-only, loop glued at pin 24
with the crown driven inverted, three jump-ins proven
non-gating).

FOUND, NOT FIXED (owner's call): debug_stage_landing
seeds its swept-contact history from the pre-teleport
position, so a staged landing's first contact can fire
across the teleport segment against a foreign frame —
the stage 68 arrival is that artifact. Identical code on
FP40, masked there by construction. Real play seeds the
history at every real takeoff; fixing the helper
re-derives every staged landing in the suite and is its
own pass.
