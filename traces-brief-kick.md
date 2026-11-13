# MEASUREMENT — THE MISSING KICK (measure only, no fix)

Base: `715e915` (FP61, current remote HEAD). This pass changes NO production code. Probe tooling lives in `~/kick-scratch/`, never committed. Budget: 90 minutes hard.

## The owner's report (Chris, 2026-11-13, FP61 seat verdict)

At the ribbon's banked ramp (s131–177): the speed trim is gone ("not slowing me down anymore") and the recording says the inside (left) tires now reach zero press there — "but I'm also not getting the kick upwards I'd expect." His video's flights read shallow and skimming: the car leaves crests flat, no upward punch.

Working theory to test, NOT to assume: FP61 changed the press ledger (the number that gates when a tire counts as lifted); the car's body motion still comes from the carried frame following the surface plus the suspension, whose return stroke is damped soft by old design (an FP51-era code note records the gated return throw reaching only 1.33 m/s of a 3.66 cap at a staged landing). If true, the unload never becomes a shove.

## Jobs — drive the ramp, record the leaving

Drive the ramp through the production input path at the entries that now complete it (governed 15.7 and 18.8, held 18.8 — the FP61 measurement family). Log per physics tick across s120–190:

- the car's upward speed (world-Y velocity of the body) and its height above the surface;
- per-corner press and air state;
- per-corner suspension travel and how fast it is extending;
- body roll and roll rate.

Answer, in numbers:

1. At the moment the lefts unload (first tick a left tire's press reaches the liftoff line or its air flag sets), what upward speed does the car have — and what is its peak upward speed in the half-second after?
2. What do the springs do at that moment: how much travel remains in each corner, how fast do they extend, and does that extension show up as body motion or is it absorbed? Quote against the FP51-era note (1.33 of 3.66) if the same quantity still exists in the code.
3. When the car leaves the ground fully just past the ramp, with what upward speed does it leave — and how much of that speed came from the road rising under it versus from the springs?
4. Control: one ordinary crest flight elsewhere on the ribbon (the hoppy crests in his video) — upward speed at leaving, same accounting.

## Verdict shape

Convict or acquit the theory with the numbers. Then name the fix family: where an upward kick would have to enter (spring return at unload, the velocity the car keeps when a tire lets go, the frame's follow — whichever the numbers point at), and its blast radius in one line. Do NOT implement it.

## Report

Trimmed: the four answers as numbers, the verdict, the fix family. Raw logs in the scratch dir, named.
