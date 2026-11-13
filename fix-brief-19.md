# Fix Pass 19 (micro) — The Lever Always Moves

Ordered by the owner (Jaklar), Thu 2026-10-29 16:14 CDT, overruling
Hal's defence of the phase gate: "i think a moron should be able to
drop off the track if they want, so that lever should always move.
whether it does anything or not is in the context of whats happening."
Base: master @ FP18 final (dispatch chains to FP18's landing).
Repo: SibioJak/stunt-car-vr, game/. MICRO-PASS, two items.

## The law this implements

Physical controls NEVER freeze. Software context decides what an
action DOES; it never decides whether the control responds. The
dangle-only gate (an FP13 drone-era inheritance: "nothing arms in
transport") is repealed for the lever family.

## Item 1 — The drop lever is live in every hang phase

In MODE_HANG, all phases (attach / carry / dangle): the drop lever
latches, articulates, tracks the pull, and logs exactly as it does
in the dangle today (FP16 latch semantics, FP17 arbitration and
telemetry all unchanged).
- Detent completed in DANGLE → release, exactly as today.
- Detent completed in ATTACH or CARRY → the pull is SPENT: log a
  distinct outcome line (DRP SPENT, with the phase), the chains
  hold, the lever returns when released. Nothing else happens to
  the car.
- THE REFUSAL IS FELT (owner's refinement, 16:16 CDT: "if nothing
  else, it should grind if it can't do something, feel the rumble
  in your controller"): while a pull is in progress in a non-armed
  phase, the pulling hand's controller GRINDS — a low haptic pulse
  train through the existing haptic path, scaling with pull
  fraction, so the driver feels the lever straining against the
  chains in his hand; the SPENT detent lands with a heavier grind
  burst. In the dangle (armed), the pull is clean — no grind.
  Silence is the only forbidden state: full function, contextual
  effect, felt refusal — never nothing.
- SPENT is spent: if the phase flips to dangle while the driver
  is still holding a completed pull, it does NOT fire. A fresh
  pull is required. (State this in the README.)
- All DRP log lines gain the hang phase tag, so the next uploaded
  log explains itself.

## Item 2 — The wheel dials during the carry too

Same gate family (FP13 gated both together): the wheel is live to
grab and turn during attach/carry, and a lock dialled there
carries through the release exactly as a dangle-dialled lock does
today. Authority unchanged: NO yaw authority over the hanging car
in any phase; steering effect begins at touchdown as today.

## Non-goals (explicit)

- NO mid-carry release. The reading above (lever always moves;
  effect contextual) is the owner's words implemented literally.
  If he wants early drops, that is a new instruction.
- Drop-point selection, crane motion, hang phases themselves:
  unchanged. FP16 thresholds, FP17 arbitration: unchanged.
- The FP13 hang BUTTON gates (Y restart long-press, A boost
  suppression, both-grips recenter) are a different family and
  stay as they are.

## Stages

New: carry-phase lever pull → LAT/PULL/SPENT, no release event,
car still hanging; spent-then-dangle-while-held → no fire, fresh
pull fires; carry-dialled wheel lock present at touchdown.
Re-run: FP17 stage 47 family and all prior stages; any staged
expectation that encoded the old gate is amended and flagged in
the README, not silently edited.

## Standing constraints

No `*.uid` / `*.png.import` commits; ClassDB guard green; controls
list updated same-commit if any command description changes (the
lever's description now differs by phase — check the list text);
README results section with the spent/fired stage evidence and
tallies.
