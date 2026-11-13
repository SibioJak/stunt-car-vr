# FINISHER BRIEF — FP61, FINISH THE PASS (weight shift sideways)

Context: FP61's builder was interrupted mid-pass on 2026-11-12 (a parking order elsewhere; since lifted). Its work is IN THE TREE, uncommitted. Your job: audit what it left, finish what's missing, ship it — or report honestly where it fails. Do not restart the pass from scratch; the diff and the measurements are the starting point. Budget: 2 hours. Probe tooling stays in `~/fp61-scratch/`.

## What's already in the tree (Hal's inventory, verify it)

- `game/scripts/main.gd`: +69/−1 — the sideways weight-shift term in the press law, per `~/workspace/stunt-car-vr/fix-brief-61.md` (read the brief; its rails bind you).
- Test render PNGs regenerated (the tree's modified files are main.gd + captures).
- `~/fp61-scratch/` holds the measurement set: base and post-change ramp drives (drive_base*/drive_p*/drive_r* CSVs), per-track census logs (census61_{circuit,ribbon,lab,funlab}.log), and analyze.py.

## One number that already smells wrong — explain it

The ribbon census log's own summary reads: `inside_air_frames=0 inside_light_frames=142 inside_episodes=0` on a completed lap, with FL/FR air 99 ticks and RL/RR 31 (reads like crest flight, symmetric). If the shift term shipped at a size that never produces inside air ANYWHERE on the ribbon lap, either (a) the term is undersized against brief-61's sizing target, (b) that census drive never corners hard enough to earn it, or (c) the census's own "inside" bookkeeping is broken. Determine which, with numbers. The brief's sizing target is the contract: at the ramp (ribbon s131–177) at the governed/held entries from the recording family (15.7 / 18.8), the inside (left) tires' minimum press must reach the liftoff neighbourhood — compare drive_base* against the post-change drives at the same entries and quote the before/after minimums per left tire.

## Remaining work, in order

1. Audit the diff against brief-61's rails (demand-driven not steering-driven; zero-sum per axle; bank not fought; front-back squat untouched; steep-regime branch decision stated). Quote the factor's value and its demand signal.
2. Settle the census question above; if the term is undersized, size it to the brief's target and re-run the affected measurements — if sizing to target breaks a protected fixture (stage 68 step-out, stage 58 P5, the staircase, the crests), STOP and report the numbers; that trade is the owner's.
3. Fixtures + witnesses: re-read the named fixtures against FP60's values; re-derive the press-pinned witnesses (stage 54 audit — repricing reported plainly; smoke gates; separation stages) where they honestly move, flagged in place.
4. Gates: ONE full smoke run (timeboxed; if it timeboxes again, complete the tail standalone as FP59/FP60 did and disclose), API guard, render proof (standing pair expected), strips.
5. Re-stamp FP61 · 2026-11-13, commit, push, verify remote == local.

## Report

Trimmed, in the brief's shape: the term and its factor in one sentence; the ramp's left-press before/after at the same entries; the census settled (where inside air is new, per track, counted — or the honest reason there is none); fixtures held or moved; gates; commit. The judging line is the seat's: that ramp again — whether the lefts finally breathe.
