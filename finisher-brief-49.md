# FINISHER BRIEF — FIX PASS 49 (Stunt Car Racer VR)

You are the FINISHER for Fix Pass 49 (Godot 4.7, repo ~/workspace/stunt-car-vr, Godot project in game/, branch master). The original builder was stopped by the owner at a watchdog flag (its confirmation suites ran long and silent on a contended sandbox). Its implementation is complete in the tree — your job is to audit it, reconcile one open data point, run the gates, and ship. Do NOT restart the design.

Read first: ~/workspace/stunt-car-vr/fix-brief-49.md (the assignment — two spatial-separation laws, protected FP48 wins) and the scratch state in ~/fp49-scratch/ (loop_measure.py, probe_out*.txt, pins_out.txt, caps/, readme_entry.txt, smoke_fp49.log, smoke_fp49_run2.log).

## Inherited state (verified at the stop)

- HEAD is 32857c2 (FP48). The FP49 implementation is UNCOMMITTED: game/scripts/main.gd (~+198) and game/tests/smoke_test.gd (~+141) modified. Probe tooling sits untracked at game/tests/fp49_probe.gd, fp49_pins.gd, fp49_caps.gd — it must NOT be committed (delete the files and any orphan .uid sidecars, as the FP48 finisher did).
- Neither confirmation suite completed: run 1 reached ~stage 58 with zero FAILs and died at its box edge; run 2 was stopped at ~stage 18. No green suite exists yet.
- Pins on the new geometry (~/fp49-scratch/pins_out.txt): loop 16/17/20/22/24/26 CLEAN, exit = entry, max lat ≤ 0.54; 13 separates late but completes dirty; 15 separates once, completes; 18 AND 19 HUNG in that sweep. Course is now 823 m (E1 span s 110..220, E2 s 340..563).

## Steps, in order

1. AUDIT the tree against brief 49:
   (a) both separation laws BY MEASUREMENT from the shipped geometry — the loop descent's lateral overlap over the entrance lane's span (law: zero; neither leg cuts the other's usable width anywhere in the element) and the bowl exit's minimum vertical + lateral clearance against the bowl's own structure (car height included);
   (b) the protected FP48 wins — crown in the ~33 m class, 6 m surface through the loop, roll 0° at both loop feet, bowl core geometry, census outside TRK2 unmoved;
   (c) BUILD_STAMP reads "FP49 · 2026-11-06";
   (d) driver's-eye frames exist in ~/fp49-scratch/caps/ showing the entrance road whole and the bowl exit clear — verify them visually.
2. RECONCILE THE BAND: run the loop pin sweep more than once. If 18/19 hang consistently, the honest robust band stands at 20–26 and the marginal zone is 13–19 — make the suite's assertions and the board text say exactly that. If a small geometry nudge recovers 18/19 WITHOUT breaking either separation law or a protected win, you may take it and re-verify everything it touches; a large rework is out of scope — report instead. Never assert a band the sweeps don't support.
3. GATES, each HARD-TIMEBOXED (~55 min max per run): full smoke green; API guard green; preflight clean. If a box expires mid-suite, read the streamed count and re-run ONCE in a fresh box. Render proof: run the check phase; attempt capture regeneration ONCE in a box — if the sandbox stalls it (the standing failure), ship with the ~/fp49-scratch/caps frames and disclose in the README entry and commit message, exactly as FP48 did. No *.uid or game/tests/*.png.import sidecars in the commit.
4. SHIP: README entry (draft at ~/fp49-scratch/readme_entry.txt — verify against your final measured numbers, including the honest band), commit ONLY game/scripts/main.gd, game/tests/smoke_test.gd, game/README.md (plus regenerated test captures ONLY if regeneration actually completed), push, VERIFY with git ls-remote.

## Report

Your final report is the deliverable: both laws' before/after measurements, the reconciled pin table and band, the protected wins' status, gates, commit hash. If you hit a wall you cannot pass, stop and report what you have — a partial honest report beats another silence.
