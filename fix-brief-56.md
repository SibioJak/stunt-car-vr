# FIX BRIEF 56 (MICRO) — THE SMOKE, CRANKED

Base: `195c63e` (FP55, verified remote). Stamp on ship: FP56 · 2026-11-09.

Chris's verdict on FP55's smoke (2026-11-09, headset): **"smokes needs to be cranked up, can barely be seen, but placement looks okay."** Placement is PASSED and fenced; presence is the whole pass. This is a dials-only micro-pass on FP55's Item 3 machinery: the exhaust emitters at the side-pipe tips (`exhaust_emitters`, FP55) — today amount 22, lifetime 0.85, puff sphere radius 0.16, amount_ratio driven by engine state.

## Pass condition

From the seat, at the events that already trigger it (idle puffs, launch bloom, shift puffs, hard-throttle haze), the smoke now READS — unmistakably present at both edges of the forward view — without crossing into the centre of the view or touching the sightline FP55 measured. If Chris has to look for it, it fails; if it walls off the road, it fails the other way.

## The crank

- Raise the channel's presence substantially: emitter amount, puff scale, opacity, lifetime, and the amount_ratio curve's working range are all in play — singly or together, builder's measurement call. "Cranked" means a step change, not a nudge: target roughly 2–3× the shipped visual density at the launch event, stated as measured numbers in the report.
- Measure presence the way FP55 measured placement: the staged-launch driver's-eye capture, before (FP55's committed capture) vs after, same staging — puff coverage in the frame periphery quantified (count/area), not eyeballed. The plume angle stays in FP55's proven 40–85° band (measured 48°) — the crank must not migrate the plume into the centre corridor.
- The puff construction question is NOT opened by this pass: the spheres read bubbly up close (FP55's disclosed item) — if the crank makes that read worse, report it plainly as the follow-on question; do not rebuild the puff system inside a micro-pass.

## Protected

- Placement: emitter positions, the zoomie exits, the 48° plume — untouched.
- Stage 74's contracts: smoke is DRIVE-only — emitting=false and ratio exactly 0.0 on the crane/hang, zero with a dead engine state. The crank changes amounts, never the gating.
- FP55 entire otherwise: parts, sightline measurement, the vibration channel (its seat component included).
- Zero physics contact, as FP55. No new controls. Commands list untouched.
- Quest performance discipline: state the new particle counts; if the crank's cost is more than modest, say so in the report instead of hiding it.

## Verification shape — micro

- Timeboxes on every run. Total budget: 90 minutes. Commit-what's-proven inside it.
- Order: (1) dials; (2) the launch capture pair (before/after) + a glance frame; (3) ONE smoke run; (4) API guard if the suite run doesn't carry it; (5) render proof captures for the smoke views only, regenerated for real. No full re-proof of unrelated systems — FP55's gates stand behind this pass's fence.

## Report

Trimmed: the dials moved (before → after values), the measured density change, the plume angle re-check, the capture pair named, gates, commit — and the bubbly-read follow-on question stated if the crank exposed it. The amount is Chris's eyes to settle; the report claims presence measured, not presence felt.
