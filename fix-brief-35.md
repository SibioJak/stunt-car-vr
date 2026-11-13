# Fix Pass 35 — THE CAPTURE WINDOW

Chris's GO given 2026-11-01. BUILD_STAMP -> "FP35 · 2026-11-01".

## The mechanism (Chris's isolation experiment, field-verified)

- still + centred + RESTART -> no view change
- STRETCH (arm reach, head unmoved) + TRK -> no view change
- LEAN over + either button -> view changes

FP34 killed the yaw bake, but the anchor's POSITION re-seat still
samples the head pose at apply time: `_process_anchor_pending`
applies after ANCHOR_STABLE_FRAMES of pose stability — a HELD LEAN
is stable enough to pass, so the origin is computed from the leaned
pose, and when the driver sits back his eye is offset by the lean
vector until the next re-seat. A stretch cannot poison the sample
(the head never moved).

## The fix

The anchor may only APPLY from a representative seated pose. A
capture window gates every application branch in
`_process_anchor_pending`:

1. STABLE branch, FALLBACK (~10 s) branch, REAPPLY-WATCH branch —
   all three gated identically: apply only when the camera's
   tracked position in car space is within ANCHOR_WINDOW_M of
   `_eye_anchor()` (so the window follows the seat trim exactly).
2. An arm that cannot apply because the head is out-of-window
   STAYS PENDING (or in watch) — it lands promptly once the driver
   returns to the seat. No timeout may force a poisoned apply for
   RESTART/TRACK arms. For the BOOT arm (no application has ever
   landed, so no valid seat exists yet): extended patience
   in-window, and after the fallback timeout a first seat MAY be
   taken from an out-of-window pose — but the reapply watch is
   armed with it, so the first in-window stable pose corrects it.
3. The explicit recenter (L stick click, force_bake) is the
   driver's deliberate act: it keeps FP11 semantics unchanged,
   INCLUDING applying from a leaned pose. The window gates
   automatic arms only.

While an automatic arm is ripe but held, anchor_state reads
"HELD-WINDOW" so the DIAG line says why the re-seat has not landed.

## Window radius derivation

ANCHOR_WINDOW_M = 0.15 m, measured in car space from the trimmed
eye anchor:

- A real lean (reaching the dash buttons) moves the head
  ~0.25–0.45 m. 0.15 sits below the smallest real lean with
  >= 0.10 m of margin — a lean is always OUTSIDE.
- Ordinary seated variation is always INSIDE: postural sway and
  breathing move the tracked head a few cm (~0.05 m worst case);
  the driver-body spring's whole excursion stack is capped near
  0.08 m (BODY_MAX_SINK 0.055 + accel-sink terms). 0.15 clears
  the stack with margin.
- Seat trim does not eat the window: the measurement is taken
  against `_eye_anchor()`, which already carries the trim.

## Proof (stage 64)

- (a) Restart arm with the head leaned 0.35 m forward, stable:
  NO application while leaned (seat correction bit-unchanged, arm
  still pending, state HELD-WINDOW); head returns -> applies
  through the production gate, eye error ~0.
- (b) Seated control: applies on the same stability count as
  before the pass (timing unchanged).
- (c) Fallback branch, permanently leaned head, restart arm:
  650 gate calls past the fallback timeout — no poisoned apply.
- (d) Boot arm (seated-once cleared): leaned past the fallback
  timeout -> the first seat IS taken (grace) and the reapply
  watch corrects it from the first in-window stable pose.
- (e) Explicit click recenter while leaned: still bakes/seats
  per FP11 semantics (control) — the window does not gate it.
