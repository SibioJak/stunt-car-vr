# FIX BRIEF 53 (RETRY) — THE GLIDE: the trim spends itself

Base: `10d91e4` (FP52, verified clean local = remote, 2026-11-09). Stamp on ship: FP53 · 2026-11-09.

Chris's verdict on FP52 (2026-11-08, headset): "car still feels too light, flying horizontally without nose coming down at all. Smaller hill are fine, the big jumps I nearly glide."

The conviction behind this brief is MEASURED, not theorised — the traces-only pass (2026-11-09, full report ~/fp53-retry-scratch/TRACE-REPORT.md, probe and logs in the same scratch):

- The channel eating the nose-down travel is the FP51 trim under held throttle (the racing input). FP52 capped its rate (0.40 rad/s) and share (+0.40 rad) — but the film build's own cap is only −0.489 rad, so the trim's share is 83% of the film build. On any flight long enough to saturate both, held throttle cancels the film build almost exactly: net −0.089 rad ≈ −5° of travel across the whole flight, however long it runs. The trim buys its share in the first ~1.2 s of armed air and holds it forever — capped in rate and size, never in PERSISTENCE.
- Hands-off does NOT glide: the film build runs pure and arrives nose-first, trace-identical to FP50. The film build is innocent.
- Numbers (ridge hump 1, pin 48, launch ≈ +10°, ~1.8 s): hands-off +10° → −18° CLEAN; throttle held: flattens onto a +6° plateau, arrival +4.7° (on the ridge's 3.13 s flight, arrival +8.6° — nose-up after 3 s of air); brake held: stacks to −41.2°, DAMAGED on every ridge flight. The trim is a second attitude engine senior to the film build in BOTH directions.
- "Too light" — MEASURED NOT GUILTY: air times ±0.01 s, apex heights ±0.02 m, height traces sample-for-sample vs FP50 on every flight. "Light" is the level attitude alone. No second defect; do not go hunting for one.

## Pass condition (Chris's law, from his verdict)

On a big jump the car rotates nose-down through the flight and arrives nose-first. A held control may CORRECT a flight; it may not hold the car level against its own physics for the whole flight.

## Item 1 — The trim spends itself (the fix: ONE mechanism)

Make the trim's authority finite in TIME as well as size, by the trace report's Option 1 — a bought share that spends itself:

- While a trim input is held, the share it has bought DECAYS back toward zero on a time constant, so the authority envelope peaks early in the flight and fades: a correction lands early; the film build owns the rest of the flight. Held throttle can still arrest a bad rotation early (FP52's arrest proof depends on early authority — preserve it), but it cannot park the car at +6° for three seconds.
- SYMMETRIC: brake's bought share spends itself the same way, curing the −41° stack with the same stroke. No separate brake mechanism.
- A pulse released and re-applied is a fresh correction — how re-application interacts with a partially spent share is the builder's design detail; state the rule and its numbers in the report.
- The decay's time constant and floor are the builder's numbers to set and state — the pass/fail lines below are what they must satisfy, not the numbers themselves:
  - On the ridge 3.13 s flight at held throttle, arrival pitch must land within the hands-off trace's neighbourhood (the film build's arrival, ±a few degrees — not +8.6°).
  - On the ridge 1.8 s flight at held throttle, no +6° plateau: pitch keeps travelling down through the flight (the dense trace shows travel, not a stall).
  - FP52's arrest case still passes: full opposite trim, applied at the gate rate, still bottoms the rotation and returns the car gradeable.
  - The release case still passes: letting go decays a bought rate to zero (FP52's law), and a partially spent share does not resurrect.
- Hands-off traces must stay bit-comparable to FP52/FP50 (the film build untouched, the trim untouched when unheld). If hands-off moves, the fix has leaked outside its fence — fail.

## Protected

- FP52 entire: windowed gate (0.25 rad/s, ordinary margin 0.163), trim direction/arming (0.35 s), rate cap, share cap, neutral decay, the arrest/release/ridge proofs — the arrest proof is re-run, not assumed.
- FP51 entire: conservation above the gate, ROOF ruling, crane stand-in, DAMAGED grade.
- Stage 58's crest law (peak == launch) — those flights are too short to arm the trim; untouched by construction, still proven.
- Small hills: closed by Chris's verdict. Any regression there fails the pass.
- Economy: report-only, as always. No retunes.

## Verification shape — DE, learned the hard way

The last two long builders died in the combined fix-and-verify grind (FP51 ~4 h, FP53 attempt one ~5.5 h, both killed at Chris's order). This pass is built to land:

- Timeboxes on EVERY run; a hung run is killed and reported, never sat on in silence. Total pass budget: 2.5 hours wall clock. If the gates aren't done in that window, commit what is proven, report what remains, and stop — a partial ship beats another corpse.
- Verification order: (1) preflight; (2) the three-way traces re-run on the ridge flights + chasm, before/after against the retry pass's logs — the pass condition is judged on THESE, dense pitch traces, not endpoints; (3) the four protected re-proofs (arrest, release, ridge, crest law); (4) ONE full smoke run; (5) API guard; (6) render proof with captures regenerated for real. No extra suite iterations beyond what a named failure requires — a failure gets convicted (production vs staging, house precedent) and either fixed minimally or disclosed, never ground at.
- Dense frames across one long held-throttle flight in the render proof: the nose visibly travelling down through the flight.
- Amended stages: re-derived with reasons flagged in place, house style. Bound-moving until green is forbidden — a stage that fails gets a conviction first.
- No *.uid / *.png.import sidecars; probe tooling in ~/fp53-fix-scratch/, never committed.

## Report (when this pass lands)

Trimmed, in the Stunt Car chat only: the mechanism and its numbers (decay constant, floor, re-application rule); before/after three-way traces on the ridge flights (arrival pitches + the plateau's fate); the four protected re-proofs' results; gates; commit; and what remains unverified until the seat judges (the glide's cure is Chris's eyes, not the traces').

## Named, NOT in this pass

- The lab chasm rebound observation (retry traces): the chasm's rebound flight conserves −1.31…−1.40 rad/s and arrives DAMAGED in all channels on FP52 (FP50: −1.7°) — it enters as a fresh separation, so the gate's rebound exemption doesn't cover it. Recorded; not this pass's count; no fix smuggled in.
- The crane stick (Chris, 2026-11-08): a few seconds stuck on the crane, no sway, self-released, after a long-glide crash. Different system; its own item when called.
- Ridge pin-40 forward tumble (named by FP52): pre-existing, full laps cross clean. Stands.
