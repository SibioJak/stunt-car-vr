# Fix Pass 12 — Shifter, panel toggle, drone clearance/speed, road visibility, jump-snatch audit, loop entrance presentation

Base: master 11c65b2. Owner's run-12 verdicts on FP11 + the loop-entry audit (research/loop-entry-audit/AUDIT.md). Six items. Diagnose-first where the brief says so; report measured causes, don't invent fixes for unmeasured problems.

## Item 1 — Drop lever becomes a gear shift (owner: works, but "too far back of player seating, should be moved forward, shortened by 1/3, more like a gear shift")
- Relocate the release lever forward beside the wheel (shifter position: ahead of the seat, at hanging-hand height, right pod forward area). Shorten the shaft 0.50 → ~0.33 m. Keep the mechanism exactly: grab latches per hand, lever follows the hand's arc, detent fires the release once per pull, haptic pulse at the detent, early release springs home unfired.
- Re-run the item-2 geometric audit over the new placement (zone on the visible handle, in rest and full throw) and the DIAG ZONE entry. Stage through production _poll_grab as before. Update the panel wording ("drop lever" copy may now say shifter if it reads better — owner's word is "more like a gear shift"; keep it honest: it is the DROP control).
- Deliver a cockpit proof showing the new placement relative to wheel and seat.

## Item 2 — Panels: hidden by default, one button (owner: "Need to do something about the big panels, hard to see. Button calls them up, makes em go away")
- Both boards (commands board + DIAG board) start HIDDEN. One input toggles both up / both away: right controller's B button + Tab on desktop. Visibility state is session state (not persisted).
- The mid-view state text (DRONE LIFT / AIRBORNE / PREP sequence / PRESS RELEASE banners) is NOT a panel — leave it as is.
- Note the loop-audit bonus in your report: with boards hidden, the loop's approach window (9–18° left) is uncovered.
- Stage: spawn state hidden; toggle round-trip both ways; prep/DIAG flows unaffected when hidden (ZONE/DIAG simply not visible — nothing else changes).

## Item 3 — Drone: stop flying through the world, and hurry (owner: "still nuts and slow. Flies through road and pylon a lot"; run-12 video: two carries consumed most of the session; owner quit mid-second-carry)
- Collision-free carry: the carrier's altitude profile along its route must clear the highest intervening ribbon/stilt the route crosses, plus a stated clearance margin. Sample the track along the route (the ribbon is analytic — use it) and set target altitude = max(route road height + hang length + clearance). Stage-assert: on representative circuit recoveries (including a walk-back whose route crosses the climb), the carried car's lowest point never intersects ribbon or stilts along the whole carry.
- Speed: raise the carrier's cruise/climb rates so end-to-end recovery (fall → releasable at the drop) is materially faster. Measure the current end-to-end time on a staged long walk-back FIRST, then after; report both numbers. The pendulum/pivot model and FP11's approach-alignment behaviour are NOT to be regressed — faster flight through the same physics; if a rate change excites the pendulum beyond its staged decay behaviour, say so and bound it.
- Walk-back placement tiers, run-up rule, approach heading: unchanged.

## Item 4 — Road visibility at speed (owner: "Part of road is invisible till you're in it") — DIAGNOSE FIRST
- Reproduce before fixing: sightline runs on the circuit at 48 m/s from the seated anchor (render proofs at staged distances on the climb/valley approaches), and inspect how the ribbon is built/chunked — is there a generation/visibility range (literal pop-in), a culling artefact, or is the far ribbon drawn but camouflaged (sand-on-sand palette + fog 0.0003 in flat Compatibility light)?
- Fix the measured cause: guaranteed-visible ribbon at driving sight distances for 48 m/s. If camouflage contributes, strengthen the far read (edge strips' contrast at range, fog balance, skirt contrast) without touching the driving model or the near look. Report before/after proof frames at the same stations.

## Item 5 — Jump snatch audit (owner: "A jump seems to find you suddenly being carried by drone") — DIAGNOSE FIRST
- Audit the fall/recovery trigger against long-flight cases at the new envelope: the 14 m gap at 48, loop detach inside the ring, hump-row overshoot, a flight that leaves the ribbon laterally but would land on a lower piece ahead. For each staged case, record WHEN the trigger fires relative to the flight (mid-flight? at/below road level? after rest?).
- Rule to enforce: recovery engages only when the car is genuinely lost — below the road it could still land on and still falling, or come to rest off-road. Never mid-flight while a landing remains geometrically possible. If the current trigger already satisfies this in code, the defect is presentational: the failure must READ before the pickup (the car visibly misses/falls; the drone's arrival is an event, not a state flip) — in that case report exactly which beat is missing and implement the minimal honest version of it.
- Stage all cases through the production path; report trigger timings per case before/after.

## Item 6 — Loop entrance presentation (owner picked ALL FOUR garnishes from the audit) + merge residual fix
- Amber guide strip painted on the road surface along the capture corridor (diverging from the main centreline to the spur line through the window s∈[168,243)).
- LOOP gantry/sign ahead of the entry (place ~s 150–165, consistent with the existing gantry language).
- Ring outer rim band brightened so the hoop reads as ribbon from behind/above.
- Chevron markers down the descent leg.
- MERGE FIX (the audit's one true geometry defect): the exit leg arrives at s=330 with a −2.54° heading residual, still unwinding at 1.6–3.45°/m over the last 12 m. Rework the exit leg's unwind so the merge arrives aligned (target: residual ≤0.5°, per-metre yaw rate in the last 12 m comparable to the entry side's ≤1.00°/m) with position continuity held. Re-run the FP10 loop stages (30 m/s completes; slowed run detaches honestly) after the change.
- Presentation elements are visual only — no physics, no capture-rule changes. New proof: driver-POV approach series with panels hidden, garnishes in place.

## Standing constraints (every pass)
- Smoke/API/proofs all green, ClassDB guard included. Steering response ≤24 m/s numerically identical to FP11. Audio teardown discipline untouched; no new audio.
- No *.uid or *.png.import sidecars. Item-sized commits on master, pushed; final report per item with shipped numbers, measurements, and the standing list of what's unverifiable headless.
