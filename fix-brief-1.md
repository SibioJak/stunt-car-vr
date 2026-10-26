# Fix Brief 1 — Stunt Car VR Test 1 (Chris's field verdict, 2026-10-26 10:08 CDT)

Project: `~/workspace/stunt-car-vr/game/` (Godot 4.7, currently at commit 0fd920e, pushed to origin master).
Chris ran Test 1 in his headset (PCVR via editor) and finished the loop. Two field defects gate everything else. Fix ONLY these two. Nothing else changes: no behavior, physics, controls, scope, or content changes; NO audio.

First read: `~/workspace/stunt-car-vr/design-spec.md`, `~/workspace/stunt-car-vr/build-brief-test1.md`, the project README, and the CURRENT `~/workspace/custom-skills/godot_gdscript_preflight/SKILL.md` (reread it — it was updated) and follow it before writing GDScript.

## Fix 1 — The track must visibly exist

Chris's words: "the track is mostly invisible" / "or there is no track, just pylons." The grey ribbon washes out against the teal fog/void, and from the cockpit (grazing angle) the thin ribbon presents edge-on and disappears, leaving only the support pylons visible. A driver must be able to read the ribbon's line far ahead at speed.

Required outcomes (implementation choices are yours within these):
- Ribbon gets real THICKNESS (a box-section ribbon, visibly deep — on the order of 0.4 m) with a CONTRASTING SIDE SKIRT/BAND on both sides, in a saturated color clearly distinct from sky, void, and the top surface, so the ribbon reads as a solid object from driver angles, including edge-on and from above during the dangle.
- Top surface gets strong contrast against the environment (dark surface against the light sky/void reads well; exact palette yours, but it must not be grey-on-teal).
- Continuous EDGE STRIPS along both edges of the top surface, full ribbon length, bright/emissive-leaning, so the driving line reads at distance.
- Fog: cut it back hard (much lower density and/or much farther start) so distant ribbon segments no longer wash out; the ribbon must stay legible across the full climb-to-descent sightline.
- Keep the frame budget: the scene was 129 nodes / 63 draw calls / ~24k prims. Merge geometry as the original build did; the fix must stay trivially inside Quest 90 fps budget. Report the new frame stats.
- The kinematic driving model (path distance + lateral offset) must be unaffected — this is visuals only; ribbon collision/path data unchanged.

## Fix 2 — Raise the steering wheel

Chris's words: "wheel is too low." Raise the cockpit steering wheel (rim center and column) by roughly 12–15 cm and, if the column tilt needs it, angle it slightly more toward the driver, so it sits at a comfortable seated grab height in the headset. Grab detection, wheel-angle mapping, handoff rule, and the panel layout otherwise unchanged. The dash switches/buttons stay reachable; nudge them only if the wheel move collides with them, and say so if you do.

## Verification (mandatory)

- Clean headless import, 0 script/parse errors; preflight audit per the skill.
- Existing headless smoke test must still pass in full (13/13); re-run and report.
- NEW rendered-frame proofs (fallback camera, PNGs in game/tests/):
  1. Cockpit view at the Drop Start / start straight: the raised wheel visible AND the ribbon reading clearly ahead into the climb.
  2. A long sightline shot along the ribbon (e.g., from the climb looking through the bank toward the gap, or an airborne-style offset shot like a driver leaving the track would see): ribbon surface, edge strips, and side skirts all legible at distance; pylons no longer the only visible structure.
  3. A side/grazing-angle shot of the ribbon showing its thickness and skirt.
- Report frame stats (nodes / draw calls / prims) for the main proof frame.
- Anything XR-only remains UNVERIFIED — report it as such; Chris's headset is the judge. Never describe the fix as confirmed from renders alone.

## Git

- Work in the existing repo `~/workspace/stunt-car-vr/` on branch master. Commit the fix as one clean commit. NEVER commit `*.uid` files (gitignore already covers them — verify `git status` before committing).
- Push to origin master using the repo's existing git config (core.sshCommand with the stuntcar deploy key is already set). Verify with `git ls-remote origin` that remote master equals your new local HEAD, and report both hashes.

## Report back

What changed (concretely, with the numbers you chose: ribbon depth, colors, fog values, wheel raise), smoke result, proof PNG paths, frame stats, commit hash + ls-remote verification, and a short "what Chris is judging" section: ribbon legibility at distance and at the grazing cockpit angle, skirt/thickness read, wheel height/grab comfort. Explicitly list anything unverified.
