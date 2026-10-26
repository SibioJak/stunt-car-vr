# Fix Brief 3 — Stunt Car VR Test 1: live-interaction pass (2026-10-26)

Project: `~/workspace/stunt-car-vr/game/` (Godot 4.7, at commit 7672115, origin master).
Read first: design-spec.md, fix-brief-1.md, fix-brief-2.md, hotfix-brief-1.md, the README, and the CURRENT `~/workspace/custom-skills/godot_gdscript_preflight/SKILL.md`. Follow the preflight skill before writing GDScript.

## Field evidence this pass answers (Chris, run 3, headset video + report)

- No black screen (Hotfix 1 confirmed). Track reads well ("tracks have curve now").
- The seat anchor has NOT visibly taken effect in the live run: framing is still the old on-top-of-the-car view; the steering wheel never enters his frame. (Your from-anchor render proof shows the intended framing — he is not getting it.)
- Grip-based interaction fails live: he works the controller reps around the prep switches during a drone lift and nothing flips; the wheel is never grabbed. Trigger/button inputs DO work (release, throttle, drone call all fired). The action map DOES contain a "grip" action, and the anchor processor runs every physics frame — the failures live in live values/poses/timing, which headless cannot see.
- Chris's wave test: "the controller graphics are ahead of my hands by about a controller's length" (~12–18 cm forward offset of the drawn controllers vs his real hands).
- Queued from desktop observation: the wheel reads FLAT (face pointing up like a plate) and the car presents a phantom LEAN on a straight with no cornering input.

Because two live-path failures have now hidden behind clean headless results, this pass is built differently: **instrument first, harden the mechanisms, and make the next live run self-diagnosing.**

## Item 1 — Panel DIAG block (the point of this pass)

Add a live diagnostics block to the in-cockpit panel, updated at ~5 Hz, showing at minimum:
- MODE and hang/drive state (already partly there — keep).
- ANCHOR: state (PENDING / APPLIED-STABLE / APPLIED-FALLBACK), HMD tracking bool (the hotfix helper's result), and the camera's current height in car space in metres (2 dp).
- Per hand (L/R): raw "grip" analog value (2 dp), "grip_click" bool, hand-to-wheel-hub distance in cm, NEAR-WHEEL flag, and whether that hand currently holds the grab.
- The wheel angle in degrees.
Keep the full command list on the panel (standing rule: every accepted command listed). The DIAG lines are how Chris's next screenshot/video reports the machine state — make them legible at panel distance.

## Item 2 — Anchor: apply on a STABLE pose, recover from an early bad apply

Current suspicion (labelled inference): the correction is computed from the first tracked pose the runtime hands over, which on this rig (Virtual Desktop) may be a transient/garbage pose; a rigid correction baked from a bad snapshot then misplaces the driver for the whole session.
Requirements:
- Apply the anchor only after the HMD pose is valid AND stable: camera local position changes by < 1 cm across 20 consecutive physics frames while tracking data is present.
- If the existing ~10 s fallback fires first (no stable pose yet), mark APPLIED-FALLBACK and, when a stable tracked pose later appears, re-apply ONCE from the real pose (APPLIED-STABLE).
- Recenter (L stick click / C) re-arms the same stability-gated application.
- DIAG reports which path applied (Item 1).
- In your report, state your best determination of why run 3's framing never changed, honestly labelled as inference where it is inference.

## Item 3 — Grip robustness

- Grab/switch activation condition becomes: analog "grip" > 0.65 OR "grip_click" is true OR "grip_force" > 0.65 (whichever the runtime actually delivers on this rig; DIAG shows the raw analog so we learn which). Same condition everywhere grip is consumed (wheel grab + dash controls).
- Proximity radii up: wheel near 0.30 → 0.40 m (hub-centre distance), dash controls 0.24 → 0.32 m.
- Controller reps: rebuild so the visible body is centred on the node origin, plus a small bright sphere exactly AT the origin — the point the math measures from is the point he sees. (His offset report may be pose semantics — aim vs grip — that we cannot settle headless; the origin marker + radii + DIAG are the honest mitigations. If you find the controllers' pose property is not the grip/"default" pose, set it explicitly and say so.)

## Item 4 — Wheel plane: stand it up

- The wheel reads flat from the seat (and the missing anchor made it worse, but don't rely on the anchor alone): increase the wheel's tilt toward the driver so the rim plane sits ~20–25° off vertical as seen from the anchored eye (column follows). Target: in the from-anchor cockpit render, the rim's ellipse minor/major ratio is ≥ ~0.55 — visibly a wheel facing the driver, not a plate.
- Grab-angle math must stay consistent with the new plane (the existing comment already fudges tilt tracking — re-derive honestly for the new tilt and keep the mapping 1:1 at the rim).

## Item 5 — Phantom lean on straights: diagnose and fix

- Chris, desktop fallback, no cornering input, straight track: the car presents leaned/rolled. Find what drives the car's visual roll in that condition (candidates: steering-coupled visual roll latching, lean-experiment state leaking into the car visual, or bank sampling at the sampled section), fix it, and state the cause plainly in your report.
- Add a smoke assertion: on the start straight, at standstill and at cruise with zero steering input, car visual roll stays within 1° of level.

## Verification (mandatory)

- Clean headless import, 0 errors; preflight audit; the ClassDB API-surface guard from Hotfix 1 must still pass and must be EXTENDED if you call any new engine API on a live-only path (e.g., grip_click/grip_force reads go through the same get_input — if you touch XRServer/tracker APIs, add them).
- Full smoke passes, including all previous assertions with identical driving numbers, plus the new Item 5 assertion.
- Render proofs: cockpit view from the anchor showing (a) the stood-up wheel with the ellipse-ratio target met — report the measured ratio from the render, (b) the DIAG block legible on the panel.
- Frame stats in the same trivial range.
- State UNVERIFIED plainly: everything live (anchor stability behaviour against VD's real pose stream, which grip channel VD delivers, hand offset) awaits Chris's run 4 — the DIAG block exists precisely so that run reports facts instead of impressions.

## Git

- Repo `~/workspace/stunt-car-vr/`, branch master, one clean commit, NEVER commit `*.uid` (verify git status), push via existing config, verify `git ls-remote origin` = new local HEAD, report both hashes.

## Report back

Per item: what you changed and the numbers you chose; for Items 2 and 5, the mechanism/cause as best you can determine (inference labelled); DIAG block contents; smoke + guard results; proof paths + measured wheel ellipse ratio; frame stats; commit + remote verification; what Chris is judging on run 4 (read the DIAG block first, then: seated framing, switch flips while dangling, wheel grab + turn, wheel plane, no lean on the straight).
