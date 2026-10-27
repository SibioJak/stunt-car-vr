# Fix Pass 11 — Seat, levers (geometry), speed, drone approach, drop lever, rake

Base: master 7a74f59. Owner's run-11 verdicts on FP10 + the Look Test fallout. Six items. Internal build order is yours, but note item 6 (rake) changes car-space geometry that item 1 (seat) and item 2 (lever zones) are measured against — settle the rake first, then measure the rest on the final car. Item 5 (speed) re-derives its dependent numbers LAST, on the final geometry. Steering feel is NOT to be softened (owner's FP10 verdict: squirrely is good).

## Item 6 — The rake (owner-directed at the Look Test, 2026-10-27)
The car gets the Odd Rods dragster stance: BIG beefy rear tires, tail up, nose down.
- Rear wheels: diameter ~1.3–1.4× current, visibly wider slicks. Fronts: same or slightly smaller than current.
- The stance must be HONEST in the driving model, not a visual tilt: per-axle wheel radius in the suspension sampling, rear axle ride height raised by the radius difference, body mesh pitched to match (rake ≈ atan(Δr / wheelbase), expect ~3–4°). The eye anchor is in car space — it rises with the rear by construction; item 1 measures from there.
- This is a deliberate deviation from Crammond's equal-wheel car, at the owner's direction. Note it as such in code comments/README.
- Re-prove everything the geometry touches: suspension stages, straddle, humps, staircase, drop/hang anchors. Deliver a side-profile proof render where the rake reads clearly.

## Item 1 — Seat: raise + physical trim + the anchor yaw cure
- Raise the default eye anchor from (0, 1.14, 0.05) — owner's complaint: road hides behind the nose/dash, worst on dips. Choose the raise by geometry (sightline over the raked nose on a descent), expect +0.10–0.15 m, and report the number you shipped and why.
- VTOL-style seat trim IN the cockpit (promoted from the backlog; lever-forward language): physical controls the driver works to raise/lower his seat within ±0.15 m of the default. Trim persists in the profile like other settings. DIAG shows current seat height.
- Port the Look Test patch-2 yaw cure into the game's anchor (the game carries the same latent flaw; look-test/scripts/main.gd at 7a74f59 is the reference): 25° yaw cone on automatic applies (outside the cone → translation only, yaw lands when the head enters the cone on a stable pose); explicit recenter bakes facing; add squeeze-BOTH-grips as a recenter input alongside the existing ones. Controls list updated in the same commit.

## Item 2 — Lever zones are GEOMETRY (owner: left lever's sweet spot "looks below lever, maybe inside console"; middle iffy; right okay)
- Audit EVERY dash control's activation segment against its visible mesh in car space (three prep levers, purple track button, everything _poll_grab can fire). Correct offsets so each segment lies ON the control's visible handle path.
- Add a PERMANENT geometric assertion to the suites: for every dash control, its activation segment must lie within a stated tolerance of the visible handle's path — the suite fails if a future mesh edit displaces a zone.
- Deliver a cockpit proof render with the activation zones drawn as markers over the controls.

## Item 5 — Speed (owner: "no real sense of speed, full tilt feels way too slow")
- Raise the envelope toward the original's proportions (Crammond's dash read to 230, display top ≈171; our smoke cap is ~34 m/s). Targets: straight-line top speed ≥ 45 m/s; acceleration scaled so time-to-speed stays honest. Report the shipped numbers.
- Steering: response at ≤ 24 m/s must remain NUMERICALLY IDENTICAL to FP10 (the authority curve's low-speed behaviour is his verified feel). Above that, the taper may fall off more gently than the old 1/(1+(v/26)²) would — re-derive and document.
- Re-derive and re-prove every speed-dependent staged number on the final geometry: hump flights (keep them ~1 s class at the new cruise — re-tune curvature if flights turn silly), the 14 m gap, loop entry/top load math, staircase bounds, autopilot lap.
- Engine audio: extend the pitch range to the new envelope. Skid unchanged. Audio teardown discipline untouched.
- Optic flow: IF measurements support it, add restrained peripheral speed references (e.g., segmented edge striping/posts at regular intervals on the ribbon). No dynamic FOV changes in VR.

## Item 3 — Drone approach (owner: carrier "comes in facing the direction you came and takes a painfully long time to turn around")
- The return is flown as an APPROACH: the carrier targets the drop heading from mid-flight, not at station. It arrives aligned with the drop piece's track tangent — stage-asserted within a few degrees.
- Bound arrival-to-releasable time and stage it (target: releasable within ~2 s of station arrival; the big yaw correction is flown, not dangled through).
- The pivot-driven pendulum stays as shipped in FP10 — FP11 changes the carrier's flight path/yaw profile, not the pendulum model. Walk-back placement rules (tiers, 25 m run-up) unchanged.

## Item 4 — The DROP LEVER (owner directive: "we need a wicked lever for dropping the car, not a controller button")
- A big physical lever in the cockpit: the driver grabs the handle (zone audited under item 2's assertion, like every control) and PULLS it through a real throw along its arc. The lever follows the grabbed hand along the arc while grip is held; passing the detent fires the release. Let go early → it springs back, no drop. Controller pulse at the detent if the rig supports it.
- The lever becomes THE release, named as such in the controls list. The old button release stays only as a test/smoke path, not the presented control.
- Stage it through the production path: grab-and-pull completes a drop; early release does not; works on every dangle (Drop Start and recovery).

## Standing constraints (every pass)
- Smoke/API/proofs all green, ClassDB API-surface guard included. No *.uid or *.png.import sidecar files committed.
- Audio: teardown discipline exactly as shipped (latch on hide/quit/focus loss, watchdog, silence-by-default). No new audio surfaces beyond the engine pitch extension.
- Track geometry and race structure unchanged (circuit, ribbon, 3 laps, walk-back tiers) except where item 5's re-derivation forces a hump-curvature re-tune — any such change reported explicitly with before/after numbers.
- Commit in item-sized pieces on master, push, and report per item: shipped numbers, what was measured, what remains unverifiable headless (all live feel, as always — the owner's headset is the verdict).
