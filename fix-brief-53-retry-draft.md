# FIX BRIEF 53 (RETRY, DRAFT — NOT DISPATCHED) — THE GLIDE: traces only, then stop

Base: `10d91e4` (FP52, verified clean local = remote, 2026-11-09). Stamp on ship: FP53 · date of dispatch.

Chris's verdict on FP52 (2026-11-08, headset): "car still feels too light, flying horizontally without nose coming down at all. Smaller hill are fine, the big jumps I nearly glide."

Split verdict already closed: small hills are FIXED and stay closed. The only open count is the big-jump glide — the car leaves, holds level, sails, nose never travels down.

## Why this retry is shaped differently

The first FP53 attempt (2026-11-08) ran 5.5 hours, combined traces + fix + full gates in one builder, and was incinerated at Chris's order with no trace; the tree reverted clean to FP52. The last two long builders both died in the combined fix-and-verify grind. This retry is DE-shaped: **measurement first, as its own pass, with a hard stop. No production code is touched in this pass.**

## Pass condition

On a big jump the car must rotate nose-down through the flight and arrive nose-first — the film signature Chris's verdict names by its absence ("flying horizontally without nose coming down at all"). A held control may correct a flight; it may not hold the car level against its own physics for the whole flight.

## Item 1 — Three-way traces on the catalogue long flights (ONLY item)

On identical staging, for each long flight in the catalogue:

- Hands off
- Throttle held through the flight (the racing input — the seat holds power in the air)
- Brake held through the flight

Per flight, per channel, report: air time, pitch at separation, pitch travel through the flight (dense trace, not endpoints), arrival pitch and grade, and which channel's trace diverges from hands-off and by how much.

Convict, from those traces alone, which channel eats the nose-down travel on long flights:
- Prime suspect (Hal's theory, to be proven or killed by the traces, not assumed): FP52 capped the trim's rate and share but not its PERSISTENCE — held throttle buys its nose-up share up to the cap and holds it against the film build for the entire flight.
- If hands-off also glides, the suspect is the film build's own long-flight balance instead.

## Item 2 — "Too light," measured

Air time and descent profile on the big jumps against FP50 (`3e63d20`) on identical staging. A number, not a vibe: either FP52 flies longer / descends slower than FP50, or it doesn't and "light" is the level attitude alone.

## Hard stop and timeboxes

- This pass ENDS with the trace report: the conviction, the three-way numbers, the FP50 comparison. No fix is written, no bounds are moved, no stages are re-derived in this pass.
- Every run timeboxed; a hung run is killed and reported, never sat on. Total pass budget: 90 minutes wall clock. If the traces aren't done in that window, report what exists and stop.
- The fix brief is written AFTER Chris (or Hal, on his word) reads the conviction — its shape follows the convicted channel: e.g. trim finite in TIME as well as size, or film build senior to held trim on established flights. Not pre-decided here.

## Protected

- FP52 entire: windowed gate (0.25 rad/s, ordinary margin 0.163), bounded trim (rate cap 0.40, share cap 0.40, decay 1.2), the stage-73 arrest/release/ridge proofs.
- FP51's mechanisms: conservation above the gate, ROOF ruling, crane stand-in, DAMAGED grade.
- Small hills: closed by Chris's verdict. Any trace regression there fails this pass.
- No *.uid / *.png.import sidecars committed; probe tooling stays in scratch, never committed.

## Report shape (when this pass lands)

Trimmed, in the Stunt Car chat only: what the traces convicted, the three numbers that prove it (per channel), the FP50 "light" verdict, and the proposed fix shape as the next decision. Chris's go on the fix is a separate word.
