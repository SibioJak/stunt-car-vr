# FIX BRIEF 61 — WEIGHT SHIFTS SIDEWAYS

Base: `f8f2816` (FP60, current remote HEAD). Stamp on ship: FP61 · 2026-11-12.

## The owner's want, in his words

After the FP60 drive at the ribbon's banked ramp: "I still feel left tires should get a little air there." He tapped GO on the fix the recording named.

## What the recording convicted (`~/traces-ramp-scratch/TRACE-REPORT.md`, read it)

- How hard each tire presses is decided by one law (main.gd ~10592): `wheel_load = clamp(1 − speed² × wheel_kv / (GRAV × cos_w), 0, 1.25)` — speed and the road's up-down curve under that tire only. **It contains no sideways weight shift at all**, and at the ramp the up-down curve is the same under all four tires, so all four press within 0.01 of each other: lefts never lighter than ~0.67, liftoff at 0.03, zero air frames in clean cornering.
- Lifting one side IS possible in this model: separation is per-corner (main.gd ~10638 — load ≤ 0.03 with the speed gate or steep-regime flag → that wheel is air, the body rolls toward it, the car keeps driving). The machinery waits for a press signal that never comes.
- The model's only weight-shift term today is front-back squat, and it moves suspension targets, never press.

## The item

Add a sideways weight-shift term to the press law: when the car corners, press moves from the inside tires to the outside tires — zero-sum per axle (what the inside loses, the outside gains), proportional to the cornering demand the model already computes (the lateral-acceleration story — use the same demand family the cornering/grip code reads, not a new invention), scaled by one factor in the CG-height/track-width family. Rails:

- **Sizing target, from the recording:** at the ribbon ramp at working pace (governed/held entries in the 15.7–18.8 family), the inside (left) tires' press must be able to reach the liftoff neighbourhood — the recording's lefts sat at 0.67–0.82 with the crest's uniform unload (~0.69) already applied, so the shift must be worth roughly half a tire's weight at that corner's demand. Size the factor by measurement at this feature, not by feel: present the lefts' minimum press before/after at the same entries.
- **It must be demand-driven, not steering-driven:** press follows how hard the car is actually cornering (a slide, a banked carve, and a straight-line crest must each read honestly). On a banked road, gravity's feed into the turn is real — don't let the term fight the bank (the frame-fall/bank handling in the FP41 code nearby is the local law for what the surface does).
- **Air must be the honest outcome where the numbers reach it** — no special-casing this one corner. Inside lift appears wherever demand earns it (Track 01's tight corners, the lab S) — that is the point of the change, and the census below prices it.
- Front-back squat behaviour unchanged. The steep-regime (loop) branch of the press law: leave its arithmetic alone unless the shift term provably belongs there too — state which way you went and why, in one line.
- `wheel_load`'s readers inherit the change (separation, `load_grip`, the FP59 smoke gate) — that's intended; each one's new behaviour gets witnessed, not assumed.

## Proof

- The ramp recording re-run: same entries, lefts' minimum press before/after, air frames at the inside tires now present or honestly absent (with the demand numbers saying why).
- A whole-game census per track (the standing census standard — never a sample): where inside lift newly appears, counted; landing grades and departures compared against FP60's reads at the named fixtures (stage 68, stage 58 P5, the crests, the staircase).
- The witnesses pinned on press get re-derived where they honestly move — stage 54's audit, the smoke gates (stage 65's terms), separation stages — flagged in place, never loosened silently.
- Dense seat frames at the ramp after: the inside tires visibly light/drooping through the corner, or the numbers explaining why the read is subtler.

## Protected

- No change to the tax (FP60), the catch, the flight model, boost dials (audit repricing reported, never absorbed), track geometry, smoke (beyond its gate inheriting press), flames, world, crane.
- If sizing the shift to reach liftoff at the ramp makes any protected fixture break its character (the step-out, the S, the staircase), stop and report the numbers — that trade is the owner's, not yours.

## Verification shape

- Timebox every run; total budget 3 hours; commit what's proven inside it. Order: the term + sizing at the ramp → the per-track census + fixture re-reads → witness re-derivation → ONE full smoke run → API guard → render proof (standing pair expected).

## Report

Trimmed: the term in one sentence, the factor's value, the ramp's before/after left-press numbers, the census (where inside air newly appears, per track, counted), fixtures held or honestly moved, gates, commit. Close with the judging line — the ramp's inside tires — as the seat's call.
