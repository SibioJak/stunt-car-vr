# MEASUREMENT — DO THE LEFT TIRES GO LIGHT AT THE RAMP? (measure only, no fix)

Base: `f8f2816` (FP60, current remote HEAD). This pass changes NO production code. Probe tooling lives in `~/traces-ramp-scratch/`, never committed. Budget: 90 minutes hard.

## The owner's question, in his words

Video of the ribbon's banked ramp (the first banked corner, s131–177, entry half s131–154 — the feature from the 17-second-hill traces): "It's not trimming as much speed as before, but I still feel left tires should get a little air there."

His expectation: banked into a left, on that cambered ramp, the INSIDE (left) tires should unload — to the point of a little daylight under them. In his FP60 drive all four stayed planted. The question is whether the model's physics ever lets that happen there, and if not, what holds the lefts down.

## Jobs

1. Drive the feature on the current build at the paces that now complete it (the FP60 census entries, ~15.7 and ~18.8 m/s, plus one at his video's apparent pace), through the production input path, held throttle and feathered. Log per physics tick across s120–190: `wheel_load` per corner (FL/FR/RL/RR), each wheel's contact/airborne state as the model represents it, suspension travel per corner if the model keeps it, car roll vs surface bank, speed.
2. Answer, in numbers:
   - The minimum load each LEFT wheel reaches across the feature, per run, and where (station) the minimum occurs.
   - Whether the model's support can represent PARTIAL lift at all: can one or two wheels leave the road while the car stays in DRIVE on the others — or is airborne an all-or-nothing state in this model? Cite the code path that decides it.
   - What carries the lefts down if they never go light: the surface's own cross-profile at the car's lateral position, the carried frame's roll follow, the suspension's behaviour — whichever the numbers convict.
3. If partial lift IS representable but never triggers here, state what load threshold/profile change would let the lefts breathe at this feature — as a named fix family with its expected side-effect surface (every other place per-corner unloading would newly appear). Do NOT implement it.

## Report

Trimmed: the left wheels' minimum loads per run, the partial-lift answer (representable or not, with the deciding code named in one line), what holds them down, and the fix family if one exists. Raw logs in the scratch dir, named.
