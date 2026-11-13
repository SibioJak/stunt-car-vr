# Fix Pass 13 — The Compact Cockpit + The Split Drone

Dispatched by the owner (Jaklar), Wed 2026-10-28, at his "GO."
Base: master @ aaceb9d (FP12 final). Repo: SibioJak/stunt-car-vr, game/ subfolder.

Run 13 produced six items. The theme the owner named himself: the hang
compacts. Prep is DELETED as a design (his call, this pass) — no sequence,
no reaction game, no boost payout at the drop. What remains in the hang:
read the sway, hold the wheel, pick the moment. Several items exist
because of that deletion; read Item 1 first, it shrinks the others.

Standing constraints (all previous passes): steering at ≤24 m/s stays
numerically identical to FP10's approved response (float-equality
asserted) unless an item below explicitly changes touchdown behaviour —
cruise/drive steering is NOT in scope. No `*.uid` or `game/tests/*.png.import`
commits. ClassDB API-surface guard stays green. Audio teardown pattern
untouched. Panels/commands list must name every control the game accepts
after this pass, and nothing it no longer accepts.

---

## Item 1 (G) — Prep deletion + touchdown connection

DELETE prep, completely:
- The shuffled 3-switch FUEL/SPARK/BOOST sequence, its state machine,
  its dash switches (the three controls at the top of the console),
  the prep banner/labels, and the boost credit on completion
  (PREP_BOOST_CREDIT and every path that pays it). The car's rationed
  on-track boost system is NOT touched — only the drop payout dies.
- No boost is awarded at the Drop Start or at any recovery drop.

TOUCHDOWN CONNECTION — the owner's replacement design, verbatim shape:
"How fast you can get going should be dependent on how well your wheels
connect on impact, which is judged from the drone sway."
- First VERIFY IN CODE what the release already converts: FP5's design
  says release converts the full swing state into the drop. Establish
  with a staged measurement whether touchdown inherits (a) lateral
  velocity from the pendulum, (b) heading error vs the road tangent,
  (c) per-wheel contact timing from car attitude — and whether the
  FP9 slip model then scrubs a crossed-up landing into a measurably
  slower getaway.
- Stage it: releases at sway-zero (pendulum settled, car aligned) vs
  sway-peak (maximum swing velocity / displacement) from the same
  drop point; measure time-to-20 m/s (full throttle, wheel centred)
  for both. The spread must be MATERIAL (target ≥ 1.5 s difference;
  report the actual numbers whatever they are).
- If the spread is trivially small, tune ONLY the touchdown/contact
  path (what the swing state hands to the contact state) until the
  connection honestly governs the getaway. Do not touch cruise grip,
  do not add a scripted penalty timer or a fake "bad landing" slow —
  the cost must come out of the tire/slip model.
- SURFACE THE RULING: after every touchdown, show a brief connection
  readout (state label or dash line, ~2.5 s): a grade word from the
  measured contact state (e.g. CLEAN / SCRUBBED / CROSSED-UP) plus
  the two numbers that decided it (lateral speed at contact, heading
  error at contact). Thresholds derived from the staged distribution,
  stated in the README. The DIAG block gains a CONTACT line with the
  same numbers for captures.

## Item 2 (B) — Drop control to the centre dash, vertical throw

- The drop lever LEAVES the right pod (the FP11 lever and FP12's
  forward relocation are both superseded — remove that lever).
- New drop control: CENTRE of the dash, where the driver's right hand
  naturally points. A lever whose throw is VERTICAL — pull DOWN /
  push UP through a detent to fire the release (owner: "it should go
  up and down"). Pick the direction that reads as "release the load"
  and state your choice; detent + fire semantics from FP11 carry over
  (grab latches per hand, passing the detent fires once + haptic
  pulse, early release springs home unfired).
- Born under the zone-geometry audit like every cockpit control: its
  activation segment asserted against its visible handle, audit at
  0 violations. Update the render proof (drop_lever_view.png or a
  successor) to the centre placement.
- Either hand may work it (centre dash is reachable by both); keep
  per-hand latch semantics.

## Item 3 (E) — Wheel grab during the dangle

- Wheel grab is currently inert while dangling (a Test-1-era rule the
  owner has now explicitly overridden). Enable grab in MODE_HANG's
  dangle phase (and the Drop Start dangle): the driver lands HOLDING
  the wheel.
- Steering input while hanging turns the wheel mesh and the front
  wheels (visual + state), but applies NO yaw authority to the
  hanging car — the car stays a pendulum load.
- The wheel_angle held at the moment of release carries into the
  drop untouched: the car touches down with the driver's dialled
  lock already in. Stage it: set a lock during the dangle, release,
  assert the drive model receives that lock on the first DRIVE frame.
- Grab during transport phases (Item 5) stays inert — the wheel arms
  with the dangle.

## Item 4 (C) — Hang-mode button gate + live input logging

Code facts (verified by Hal in main.gd @ aaceb9d — re-verify, don't
trust): right A (held) sets in_boost in ALL modes; left X calls the
drone only in MODE_DRIVE; left Y calls start_race() with NO mode gate;
right B toggles panels; both-grips edge calls _recenter().
- In MODE_HANG, face buttons go quiet: left Y must NOT restart the
  race while dangling (restart from the hang requires a deliberate
  long-press ≥ 0.8 s, or is DRIVE/DONE-only — pick one, state it);
  right A must not set in_boost during the hang nor carry a held
  boost through touchdown (clear/ignore until the first DRIVE frame
  after landing reads a FRESH press state); left X stays inert in
  the hang (already true — assert it in a stage).
- Both-grips recenter: suppressed while mode == MODE_HANG, and
  suppressed in any mode while a cockpit control (drop lever, trim
  lever, wheel) is latched/held. The L-stick-click recenter path
  stays available as the deliberate route.
- Right B panel toggle stays live in all modes (owner's FP12 ask —
  deliberate, not cross-talk).
- LIVE LOGGING: during MODE_HANG, record every face-button edge
  (action name + race_time) into a small ring buffer shown in the
  DIAG block (last ~6 events). If any ungated influence survives,
  the owner's next capture names it.

## Item 5 (D) — Trim levers articulate

- The seat-trim levers on the left pod WORK (seat moves) but their
  meshes don't move. Fix: a held trim lever's mesh deflects for as
  long as it's held (and returns on release), matching the seat's
  motion direction. Assert in a stage via mesh rotation/position
  delta while the trim is driven through the production input path.
- General rule this pass enforces: every cockpit control that
  actuates also articulates. Audit the remaining controls against
  it and list the audit in the README (the drop lever already
  articulates; state the wheel's status).

## Item 6 (F) — Drone: split travel from hang (owner's tapped decision)

Recovery and Drop Start become two distinct phases:
- TRANSPORT: after pickup, the carrier flies the car DIRECTLY to the
  station point above the drop target — a direct route at transport
  speed, at the FP12 clearance profile altitude (max intervening
  road height + hang stack + clearance), NOT the retrace path. The
  pendulum is live physics during transport (it inherits whatever
  the flight does to it — honest), but NOTHING arms during transport:
  no drop lever, no wheel grab, no release. Transport speed: fast
  enough that a representative mid-circuit recovery's transport leg
  completes in a small number of seconds — stage two representative
  falls (short walk-back and the long s900-class walk-back) and
  report transport seconds for each, before and after.
- STATION: on arrival over the drop point the carrier holds station
  and the DANGLE begins (hang_phase "dangle"): sway settles from
  whatever the arrival handed it, drop lever arms, wheel grab arms,
  release at the driver's word. The arrival-to-dangle transition
  must not zero the pendulum state (no teleporting the swing away —
  the arrival's swing is the driver's first read).
- The FP11 approach rule survives in compressed form: the carrier
  still arrives aligned to the drop heading (yaw goal = drop heading
  during the final approach, gated before the dangle arms) — the
  alignment is achieved in flight, not dangled through.
- Drop Start gets the same shape: short transport from the pickup
  point to over the start line, then the dangle.
- The FP10 walk-back/drop-point SELECTION rules are unchanged (the
  owner passed on changing them — do not touch tier logic or
  DROP_MIN_RUNUP_M).
- Stage asserts: drop lever pull during transport does nothing;
  dangle begins only after station arrival; pendulum state is
  continuous across the transport→dangle boundary (angles/omegas
  equal within float noise at the handover frame).

---

## Suites & delivery

- Smoke/API/proofs all green, grown with stages for every assert
  named above. Steering ≤24 m/s float-equality vs FP10 asserted as
  always. Zone audit at 0 violations including the new centre lever.
- Render proofs: centre drop lever view; dash-top AFTER prep removal
  (the console without the three switches); transport/station
  sequence frames if practical.
- README: per-item report with the staged numbers (touchdown spread,
  transport seconds before/after, gate stage results), every brief
  mismatch found, and anything honestly NOT fixed.
- Per-item commits, push to origin master, tree clean, no sidecars.
