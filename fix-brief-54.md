# FIX BRIEF 54 — THREE COUNTS: the tilt's onset, the downhill, the brakes

Base: `aaf618f` (FP53, verified remote). Stamp on ship: FP54 · 2026-11-09.

Chris's drive session on FP53 (2026-11-09) returned three counts. His words:

1. **The tilt's onset:** "the tilt is better, but not quite there. It feels like you lift off a jump, flatten out....but stay flat too long, before the downward tilt kicks in."
2. **The downhill:** "need to pick up speed going down hill."
3. **The brakes:** "brakes are too strong, you can stop this thing on a dime if you want."

Plus his track note the same hour, which raises the downhill's stakes: "Lot of elevation changes are fun, especially downhill curves" — downhill pieces only pay once descents actually add speed (filed in design-spec.md, TRACK GEOGRAPHY).

## What the code says today (Hal's read of _update_drive at FP53 — starting points, to be confirmed by measurement, not assumed)

- **Slope gravity exists:** FP41's term `accel += -GRAV * d41.y * 0.85` = 8.33·sin(grade) along the car's forward. But rolling drag is `vf * 0.10` (5.0 m/s² at 50 m/s, 6.8 at 68) and top-gear force fades to 8.5·(1−fade): on ordinary grades at speed, slope push ≈ drag — the car HOLDS speed downhill instead of gathering it.
- **The brake is a flat −14.0 m/s²** (~1.43 g), applied as `accel -= in_brake * 14.0` with NO reference to the tires' longitudinal budget (GRIP_LAT_ACCEL / μ = 11.0). It outmuscles slope gravity up to a ~20° grade. 60 → 0 in ~4.3 s / ~129 m at any speed.
- **The film build is quadratic:** offset = −0.5 · 0.349 · t², capped −0.489 rad — ≈4° of travel at 0.5 s, ≈16° at 1.0 s. Its travel is back-loaded by construction: the start of every flight is nearly flat BY DESIGN. FP53's trim fade (TAU 1.5 s, floor 0.10) additionally holds most of a bought share through the first second. Hal's hypothesis for count 1: the flat phase Chris feels is the SUM of those two slow starts. MEASURE the onset before choosing the cure (below).

## Method — measure first, inside the pass (the FP53-retry shape, compressed)

This pass carries its own conviction step, in order, before production is touched:

1. **Descent measurement:** speed traces on the roster's real descents (the Dive; Track 01's catalogue descents; a ribbon descent) at held throttle and at coast: entry speed, exit speed, peak acceleration on the grade. State the equilibrium the traces show.
2. **Stop measurement:** full-brake stops from 30 and from 60 on the flat: time and distance, as shipped.
3. **Onset measurement:** on the ridge 1.8 s and 3.13 s flights (the FP53 probe's staging, logs in ~/fp53-retry-scratch/), the dense pitch trace read for ONSET: time from separation until sustained nose-down travel is under way (state your operational definition), hands-off and throttle-held, FP53 as shipped.

Then fix, per item. Every fix states its numbers in the report; the pass conditions below are what they must satisfy.

## Item 1 — The tilt starts when the flight starts

Pass condition (Chris's law, extended by this verdict): the car leaves, and the nose-down travel is under way promptly — no flat phase the driver can feel. A held control may correct a flight; it may not hold the car level against its physics, EARLY or late.

- The cure follows the onset measurement: if the film build's quadratic onset is the laggard, its early shape is the fix (an onset that starts travelling sooner — e.g. a linear-plus-quadratic blend or a re-fitted early rate — while its TOTAL travel and cap stay what FP14/FP53 proved: arrival attitudes on the catalogue flights stay in their proven neighbourhoods, hands-off arrivals bit-comparable in spirit: same arrivals, earlier travel). If the trim's fade is the laggard, the spend starts sooner. If both, both — each stated separately.
- FP53's whole result is protected: no plateau returns (the ridge traces still descend throughout), throttle-held arrivals stay in the FP53 neighbourhood (−3.6° / −9.8° class), hands-off arrivals unchanged in total travel.
- The four FP52/FP53 re-proofs re-run: arrest, release, ridge drive, crest law (peak == launch).

## Item 2 — A descent adds speed

Pass condition: on the roster's real descents, the car GAINS speed — at held throttle plainly, and at coast measurably (gravity alone must be able to beat drag on a real grade; a coast that merely holds speed on a steep descent fails). The gain must read in the traces as acceleration ON the grade, not a number tuned on a test slope.

- The mechanism is the builder's to convict from the descent measurement: candidates are the drag term's size/shape at speed, the 0.85 drivetrain factor on the slope term, and top-gear fade — singly or in combination. State which, and why the traces convict it.
- Protected: the Odd Rod law — flat-ground equilibrium stays ≈67–68 and the 71 clamp stays a reserve reached only with help (a descent IS help: arriving at the clamp down a long grade is the law working, not a violation; sitting at it on the flat would be). Gear bands/forces otherwise untouched. Peel-out and the feather law untouched. Climb bite preserved: climbs must still cost what they cost (the slope term is symmetric — do not buy descents by flattening climbs).

## Item 3 — Brakes the tires can cash

Pass condition: full brake can no longer out-stop the tires. Braking force is capped by the tires' longitudinal budget (μ = 11.0, read through the same load story the drive model already uses), so a stop from speed takes honestly longer than today's dime — state the before/after stop times and distances from 30 and 60 as the headline numbers.

- What happens past the cap (extra pedal travel doing nothing, vs a lockup story) is the builder's stated choice — the minimum honest form is preferred: pedal demand past the tire budget simply doesn't transmit. NO new failure theatre in this pass.
- Slope interaction is part of the item: on a descent, gravity's push now fights an honest brake — a full-brake hold on the roster's steepest descent grade must still hold the car (or creep honestly — measure it and report which; do not leave the car unable to stop on a hill it can drive down).
- Brake's other job is untouched: in the air, brake is the nose-down trim — FP51's direction, FP53's spending shape, both preserved exactly. This item is the GROUND brake only.

## Protected (all of it)

- FP53 entire (spending trim: fade TAU/floor, bleed, per-direction clock, re-application rule — Item 1 may adjust the fade's EARLY shape only on the onset measurement's conviction, and must say so).
- FP52's gate and margins; FP51's conservation, ROOF, crane stand-in, DAMAGED.
- Small hills: closed by Chris's verdict (FP52). Hands-off flight totals. Stage 58 crest law.
- The boost economy: report-only, as always — repricing from Items 2–3 is reported, never chased.

## Verification shape — DE, as FP53 proved

- Timeboxes on EVERY run; a hung run is killed and reported, never sat on. Total pass budget: 3 hours wall clock (three items, each small). If the gates aren't done in the window: commit what's proven, report what remains, stop.
- Order: (1) the three measurements; (2) fixes; (3) before/after traces per item (descent traces, stop numbers, onset traces); (4) protected re-proofs; (5) ONE full smoke run; (6) API guard; (7) render proof, captures regenerated for real. A failure gets a conviction (production vs staging), fixed minimally or disclosed — never ground at, never bound-moved into green.
- Amended stages re-derived with reasons flagged in place, house style.
- No *.uid / *.png.import sidecars; probe tooling in ~/fp54-scratch/, never committed.

## Report (when this pass lands)

Trimmed, in the Stunt Car chat only: per item — the measurement, the mechanism and its numbers, the before/after proof. Then the re-proofs, gates, commit, economy repricing if any, and what remains unverified until the seat judges (all three counts are feel counts; the traces convict mechanisms, Chris's right foot and eyes return the verdicts).

## Named, NOT in this pass

- The lab chasm rebound (conserves −1.31…−1.40, DAMAGED all channels; enters as a fresh separation). Recorded since the retry traces; not this pass.
- The crane stick (2026-11-08, self-released). Its own item when called.
- Ridge pin-40 forward tumble. Pre-existing; stands.
