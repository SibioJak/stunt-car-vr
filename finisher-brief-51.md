# FINISHER BRIEF 51 — salvage FP51 (the flight model)

FP51's builder was KILLED at Chris's order 2026-11-07 17:47 CST after ~4 hours, deep in verification (sixth smoke run). Its work is IN THE TREE, uncommitted. Your job: audit it against ~/workspace/stunt-car-vr/fix-brief-51.md, fix what is actually broken, run the gates, and SHIP — or report exactly what cannot be salvaged. Do not restart the design. Do not widen scope.

## What the tree holds (inventory at the kill)

- `game/scripts/main.gd` +294 lines: the flight-model implementation.
- `game/tests/smoke_test.gd` +306: new stage(s) (stage 73 area — crest episodes, conservation, threshold, trim, roof outcome).
- `game/tests/frame_strips.gd` +45, `game/tests/render_proof.gd` +31.
- `design-spec.md` modified (check what it says; keep only what the brief sanctions).
- Scratch in ~/fp51-scratch/: probe_before/after logs, census_after.log, smoke1–6 logs, the census51.gd probe script (probe tooling is NEVER committed).

## The known open wound

smoke6.log's only failures are **stage 8**: "FULL extended lap driven to the finish (s=759 mode=0, track 1163 m)" and "airborne over the second gap (s 820-834)" — the staged full-lap driver now dies mid-lap on the ribbon. First question to answer, with evidence: is this the new flight model honestly changing a staged flight the old driver flew by the old rules (a staging/expectation defect — the FP48 extraction precedent), or a production defect in the flight model itself? Reproduce it, read the flight that fails, and convict the right layer. If the fix belongs in the test's staging, say so in the commit and the report; if it belongs in production, fix production minimally.

## Your procedure

1. Read fix-brief-51.md in full. Audit the tree against it item by item — conservation law and its threshold (is the threshold a measured number with evidence in the logs?), trim arming and authority, the roof outcome and its crane stand-in, the grades' honest bottom, the protected work untouched (FP14 ground behaviour, economy numbers, funlab geometry, census).
2. Run the preflight audit (GDScript type inference — the house preflight skill applies). Then ONE full confirmation smoke run, timeboxed; the API guard; the render proof with captures regenerated for real this time.
3. Check the before/after evidence the builder left in ~/fp51-scratch/ (probe_before vs probe_after, census_after): the +18.8° crest flight must show rotation through the flight; ordinary flights' grades/payouts unmoved outside the threshold's reach. If the evidence is missing or doesn't show it, produce it — dense frames across the violent flight's arc.
4. Commit in the FP51 shape (stamp FP51 · 2026-11-07 — verify BUILD_STAMP carries it; no *.uid, no game/tests/*.png.import, no probe scripts committed), push via the repo's configured route, verify with git ls-remote.
5. Report in the standard shape: what the audit found (including anything in the tree that does NOT match the brief — name it and what you did about it), the stage-8 conviction and its layer, the threshold and its evidence, before/after flight numbers, census, gates, commit hash — and what remains unverified until the seat judges.

Hard timeboxes on every run. If a run hangs, kill it and report; never sit in silence.
