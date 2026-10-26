# Hotfix Brief 1 — black screen in headset (2026-10-26)

Project: `~/workspace/stunt-car-vr/game/` (Godot 4.7, at commit ac73338, origin master).

## Bug (diagnosed, confirmed)

Chris: after Fix Pass 2, launching in the headset = black screen, desktop mirror frozen on a still frame. Launching WITHOUT the headset loads fine on desktop.

Root cause, verified against Godot 4.7's ClassDB from this machine: `game/scripts/main.gd` line ~903 calls `xr_cam.get_is_tracking()` — **that method does not exist** in Godot 4.7 (checked: XRCamera3D.get_is_tracking = false, XRNode3D.get_is_tracking = false). The correct call is `get_has_tracking_data()` (XRNode3D, exists = true). In XR mode `_process_anchor_pending()` runs every physics frame while the anchor is pending, so the invalid call error-spams and wedges the run. In desktop/fallback mode `xr_ok` is false, the function returns early, and the line never executes — which is why every headless check passed and only the live headset broke. It passed static import because the call dispatches dynamically at runtime despite the typed variable.

Full-project audit already done by Hal: the only other live XR API calls are `XRController3D.get_input` (exists = true) and `XRInterface.is_initialized` (exists = true). Line 903 is the single bad call.

## Fix (surgical — nothing else changes)

1. Replace `xr_cam.get_is_tracking()` with `xr_cam.get_has_tracking_data()` at that call site.
2. Add a PERMANENT guard so this class of bug is caught headless forever: extend the test suite (smoke or a small dedicated check that runs with it) with a ClassDB API-surface assertion covering every XR API method the game code calls by name — at minimum: XRNode3D.get_has_tracking_data, XRController3D.get_input, XRInterface.is_initialized, XRServer.find_interface — asserting `ClassDB.class_has_method(...)` for each, failing loudly if a name doesn't exist in the running engine version. Wire it so it runs in the same headless pass as the smoke test and report its result separately.
3. Do NOT change anchor math, drone logic, visuals, physics, or anything else in this hotfix.

## Verification

- Clean headless import, 0 errors. Follow the current `~/workspace/custom-skills/godot_gdscript_preflight/SKILL.md`.
- Full smoke passes (16/16 as after Fix Pass 2) PLUS the new API-surface guard passes.
- Render proof re-run passes; no visual change expected.
- Commit (one clean commit, no `*.uid`), push to origin master via existing repo config, verify `git ls-remote origin` = new local HEAD, report both hashes.
- In your report, state plainly what remains UNVERIFIED: the anchor now executing against a live tracked pose in Chris's headset — that's his re-run.
