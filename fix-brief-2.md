# Fix Brief 2 — Stunt Car VR Test 1 (Chris's field verdicts, run 2, 2026-10-26)

Project: `~/workspace/stunt-car-vr/game/` (Godot 4.7, currently at commit 428e24d, pushed to origin master).
Chris re-ran Test 1 after Fix Pass 1. CONFIRMED FIXED, do not touch: ribbon visibility ("track is there now"). Two new field defects follow. Fix ONLY these. No other behavior, physics, content, or scope changes; NO audio.

First read: `~/workspace/stunt-car-vr/design-spec.md`, `~/workspace/stunt-car-vr/fix-brief-1.md`, the project README, and the CURRENT `~/workspace/custom-skills/godot_gdscript_preflight/SKILL.md` (reread it) and follow it before writing GDScript.

## Fix A — The driver sits ON the car, not IN it; wheel at max arm extension

Chris's words: "Still sitting way too high. Photo represents my arms at max extension reaching for wheel." His screenshot: the view looks down over the car's whole top deck; the wheel is small and far at the bottom of the view. Fix Pass 1 raised the wheel 13.5 cm and it did not cure this — the root cause is the driver eye/seat position relative to the cockpit, and the wheel's distance from the driver, not wheel height alone.

Required outcome — an anchored seated position:
- Give the cockpit a fixed DRIVER EYE ANCHOR in car space and make recenter (and initial spawn) place the player's eye at that anchor: the player's physical seated height/posture must no longer float them above the car. (Standard approach: on recenter, offset the XR origin so the current HMD position lands exactly on the anchor, keeping yaw from the car's heading. Desktop fallback camera sits at the anchor.)
- Anchor targets (solve exact coordinates from the existing cockpit layout):
  - Eye ~1.10–1.18 m above the ribbon surface.
  - Wheel hub ~0.42–0.48 m forward of the eye and ~0.22–0.30 m below it — a natural seated reach with elbows bent, NOT full arm extension. Move the wheel/column to satisfy this relative to the anchor rather than nudging blindly; grab mapping, handoff rule, switch layout otherwise unchanged (switches must stay comfortably reachable too — they are flipped while dangling, when the same anchor applies).
  - From the anchor, the view must read as sitting IN the car: hood/blower low in the lower frame, wheel large in the lower-center, dash row reachable below the rim — not the whole car roof/top deck spread out below like a hood ornament view.
- The in-cockpit panel stays legible from the anchor (move it only if the anchor change makes it unreadable, and flag any move).
- The lean experiment reads HMD offset relative to the rig — make sure the anchor/recenter change does not break lean reading (lean is measured from the anchored position, not the raw tracker origin).

## Fix B — Drone recovery barely gets you over the track

Chris's words: "drone is evil cause it doesnt bring you over the track, well it does, barely." On recovery the drone hovers him only marginally over the ribbon, so a release is precarious and off-drops are common.

Required outcome:
- The recovery dangle position is CENTERED over the ribbon centerline (lateral offset ~0, within a few cm), car aligned with the ribbon's heading at that point, hanging over a flat, straight section of ribbon at/near the recovery point — with real margin on both sides, so a decently timed release lands ON the track, centered.
- Same standard for the Drop Start initial dangle: centered over the start straight.
- Keep the pendulum sway and the player-timed release exactly as they are — the sway around a centered hang point is the game; the hang POINT is what's wrong. Sway amplitude unchanged.
- Releasing while swung wide can still miss — that's player timing, intended. What's fixed is the centered case: at swing center, the car must be squarely over the ribbon.

## Verification (mandatory)

- Clean headless import, 0 script/parse errors; preflight audit per the skill.
- Existing smoke test passes in full (13/13) with the driving numbers unchanged.
- EXTEND the smoke or add assertions proving Fix B mechanically: at recovery dangle, the car's lateral offset from the ribbon centerline at swing center is within tolerance (state the measured value), and a release at swing center lands the car on the ribbon.
- Rendered-frame proofs (fallback camera at the new eye anchor), PNGs in game/tests/:
  1. Cockpit view from the anchor at the Drop Start: wheel large in lower-center at natural size, dash/switches reachable in frame, hood low, ribbon ahead — compare against the old "sitting on top" framing.
  2. Drone dangle/recovery shot showing the car hanging centered over the ribbon (e.g., a slightly offset external view where centerline alignment is visible).
- Report frame stats; keep them in the same trivial range as now (~130 nodes / ~64 draw calls).
- XR-only feel (actual reach comfort, anchor feel in the headset) remains UNVERIFIED until Chris runs it — report it as such; never describe the fix as confirmed from renders alone.

## Git

- Existing repo `~/workspace/stunt-car-vr/`, branch master. One clean commit. NEVER commit `*.uid` files (verify `git status` first).
- Push to origin master via the repo's existing git config. Verify `git ls-remote origin` equals your new local HEAD; report both hashes.

## Report back

What changed (concretely: anchor coordinates, how recenter/spawn applies it, wheel/hub new position relative to the eye, drone hang-point logic and the measured centerline offset from the smoke), smoke results incl. the new Fix B assertions, proof PNG paths, frame stats, commit hash + ls-remote verification, and a short "what Chris is judging" section: seated position in the car, wheel reach with elbows bent, drone centering on recovery and at the Drop Start. Explicitly list anything unverified.
