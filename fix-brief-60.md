# FIX BRIEF 60 — THE TAX STOPS TAXING CORNERING; THE CRANE STOPS IDLING

Base: `a6282b8` (FP59, current remote HEAD). Stamp on ship: FP60 · 2026-11-11.
Owner's sequencing (tap, 2026-11-11): Item 1 first, Item 2 in the same pass behind it.

## Item 1 — the fishtail tax stops spending the rear's cornering capacity

**Conviction** (`~/traces-hill-scratch/TRACE-REPORT.md`, read it): at the ribbon's first banked corner (s131–177), cornering demand runs 12–18 m/s² while the lateral capacity under held throttle is 1.6–4.2 m/s². The tax factor `sqrt(1 − FISHTAIL_TAX·rear_u²)` (main.gd ~9211, FISHTAIL_TAX 2.00 since FP42) sits at 0.25–0.43 under power because `rear_u` (engine demand over the spin cap) sits at 0.64–0.70 in sustained cornering drive — the engine is working, so the formula prices the rear as if it were at the edge of its friction circle, and the cornering bleed starves. Held-throttle entries at 15.7–39.6 m/s ALL depart the road at s151–154; feathered at the same speed and steering, the car completes corner and gap. The angle was never the problem (bank tracking ≤0.5°); the grip under power was.

**What the tax is FOR (protected):** FP40 built it and FP42 made it MORE at the owner's hands — gunning it out of a corner taxes the bleed so the tail steps out a little, and the lift triggers the catch (FISHTAIL_CATCH). The corner-exit step-out is FIELD-LOVED. It must survive this pass intact: staged corner-exit slip (stage 68's measure) holds its FP42 read, and the lab's off-camber S (stage 58 P5) keeps its margin.

**The distinction this pass prices:** engine demand is not tire saturation. `rear_u` conflates the two — it reads high whenever the engine works hard, including sustained banked cornering where the rear tires are nowhere near their lateral limit. The fix re-prices the tax's input so it spends against what the tax was built to price — the rear's actual saturation/spin state (the wheelspin/slip family of signals the model already keeps) — rather than raw engine demand. The design space is yours inside these rails:

- Under sustained held-throttle cornering at the ribbon corner, the effective lateral cap must recover to the feathered run's class (~7 m/s²): the corner becomes *drivable under power* the way the governed/feathered control drove it.
- The corner-exit step-out under a throttle punch must still happen (stage 68 is the instrument; its band is the contract).
- The catch on lift must still fire as FP42 built it.
- If no re-pricing of the input achieves both, say so in the report with the numbers — do not ship a corner that drives by killing the step-out, and do not ship the step-out by keeping the corner undrivable. That trade is the owner's, not yours.

**Proof:** the traces instrument, re-run: held-throttle entries at the ribbon corner across the entry-speed family (15–40 m/s) — the pass presents completion/departure per entry speed, slip trace through the corner, and the speed itemisation against the traces report's (scrub no longer the thief at working entries). Stage 54's audit will move with any drive change — report the new numbers plainly as repricing (standing rule: repricing is reported, never silently absorbed); the stage-68 and stage-58 P5 reads are quoted against their FP42/FP54 values.

## Item 2 — the crane stand-in stops idling (roof recoveries)

**Ruling** (Chris, 2026-11-11): "the crane pause is annoying when landing on hood" — the fifth strike. Mechanism (verified): `_begin_recovery` charges a roof recovery by setting `anchor_t = −ROOF_HOLD_EXTRA_S` (6.0 s); the attach phase then runs 6 s long while the presentation shows nothing working — no sway seeds until the phase turns (the pendulum seeds at dangle entry), no visible strain, banner static. The length was never the complaint; the DEAD AIR is.

**The fix, inside the stand-in's own terms:**

- The dead hold shrinks to a short strain beat (~1 s class — size it by what reads as work, and state the number).
- From the first frame of the roof attach, the collection READS AS WORK: the car arrives inverted (it landed on its roof — the pose at pickup must say so) and the attach visibly rights it — a rotation to upright across the attach, eased, completing as the lift begins; the pendulum/sway machinery seeds from the attach (small swing from frame one — the car hangs from chains, it should never hang statue-still), growing into the dangle's normal swing rather than switching on at a phase boundary.
- The roof penalty survives as TIME ON THE CHAINS overall (the owner's 2026-11-07 ruling: the recovery's extra time is the penalty) — the righting and the longer lift carry it; what dies is only the motionless wait.
- The Full Moron clause is untouched: the drop button releases in every phase, and an early release off a roof hang behaves exactly as it does off any hang.
- DIAG/grab-log still name the ROOF ruling; stage gates covering the stand-in (incl. stage 74's dead-on-crane checks and the roof-recovery timing checks) are re-derived where the timing honestly changes, flagged in place — never loosened silently.

**Proof:** a staged roof recovery rendered across its whole timeline at dense frames: frame 1 inverted at pickup, righting visibly under way within the first second, sway present from the attach, total roof-recovery time quoted against the ordinary recovery's (the penalty delta stated as a number).

## Protected

- No track geometry changes (family 3 was NOT chosen). No bank-budget changes (family 2 was NOT chosen). The corner's honest costs (slope, drag, its over-tightness above ~17 m/s even feathered) stay — this pass removes the tax's theft, not the corner's character.
- Flight model, boost economy dials (repricing reported only), smoke, flames, world: untouched.
- The in-game commands list: no command changes expected; if any timing the list names changes, update it in-pass.

## Verification shape

- Timebox every run; total budget 3 hours; commit what's proven inside it. Order: Item 1 (re-price, corner census, step-out/catch re-proofs) → Item 2 (stand-in rework + roof timeline proof) → ONE full smoke run → API guard → render proof (standing pair expected).

## Report

Trimmed: Item 1 — the re-pricing in one sentence, the corner census before/after (entries × completion), the step-out and catch reads against their old values, the audit repricing; Item 2 — the new roof timeline (strain beat, righting, sway-from-frame-one, total time vs ordinary); gates; commit. Close with the two judging lines — the ribbon corner under power, and a hood landing's wait — as the seat's calls.
