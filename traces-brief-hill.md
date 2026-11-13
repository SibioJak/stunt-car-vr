# TRACES PASS — THE 17-SECOND HILL (measure only, no fix)

Base: `a6282b8` (FP59, current remote HEAD). This pass changes NO production code. Probe tooling lives in `~/traces-hill-scratch/`, never committed. Budget: 90 minutes hard.

## The claim (Chris, 2026-11-11, from his driven FP59 video)

"after first left turn, there's a little angled hill that's trimming a lot of speed from car, when it should be angling the car" — located at the 17-second mark of his video: on the RIBBON, just past the drop-start straight, a raised banked ramp/hump on the LEFT of the road (cambered crest, orange trim); the car rides up onto it, then comes off sideways into the banked corner that follows. His expectation: the feature should give the car ANGLE (bank/attitude to carry through the turn) instead of costing it SPEED.

## Job 1 — identify the feature exactly

From the ribbon's track data: the station range of this hump (the first significant banked rise after the drop start / first left). Report: station range, length, peak grade, peak bank, and the grade/bank RATE of change per metre at entry and exit (the sharpness numbers). Name which ribbon feature this is in the track's own terms (ext_s0 ridge? staircase approach? other) — from the data, not the video.

## Job 2 — drive it and log everything

Drive the feature through the production input path at Chris's pace: drop start, held throttle, the steering a driver gives it. Log per physics tick across the feature ± 30 m: speed, throttle, gear, car pitch/bank vs surface pitch/bank (the mismatch, signed), contact state per wheel (or the model's contact summary), airborne intervals, slip_state, and every landing grade ruled inside the window. Also log the same drive on the CURRENT build and, for the control, the identical drive with the feature's stations noted against a nearby plain section.

Report, in numbers:
1. Speed at feature entry, at crest, at exit, and 30 m past exit — and what a plain section costs over the same distance at the same entry speed.
2. Where the speed went, itemised as far as the model allows: slope-gravity integral over the window, drag integral, any landing-retention multiplier applied inside the window (grades ruled + their factors), any airborne time and what the recontact cost.
3. The attitude story: car bank/pitch vs surface bank/pitch across the feature — does the car take the feature's angle (and when, with what lag), or does it stay level and scrub? Peak mismatch and where.
4. Contact story: any separation/recontact inside the feature, however brief.

## Verdict shape

End with a conviction or an acquittal, in plain terms: which mechanism eats the speed (name it with its number), or "the feature is honest — the cost is X m/s of pure climb, the angle IS imparted (peak bank taken: N°)" if that's what the traces say. If the traces convict a mechanism, name the smallest fix family that addresses it — do NOT implement it; the fix is a separate pass on the owner's word.

## Report

Trimmed: feature identity (one line), the four numbers, the itemised cost, the attitude mismatch peak, the verdict. Raw logs in the scratch dir, named.
