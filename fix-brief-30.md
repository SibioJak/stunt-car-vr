# Fix Pass 30 — The Wheel Is Live for the Whole Hang + The Centre Gauge

Ruled from the field (Jaklar), Sat 2026-10-31 16:21 CDT,
minutes after the FP29 verdict ("steering is much
better"): "the steering wheel still doesn't work during
the first phase of being craned. It activates well into
the process." And at 16:22, the addition: "The steering
wheel needs a centering line until we get the tires
looking a little better."

## Item 1 — the wheel is live for the whole hang

Convicted in code: the wheel block's FP13-era gate —
`wheel_live = DRIVE or AIR or (HANG and hang_phase ==
"dangle")` — with the same dangle term in the FP17
arbitration candidate and the FP29 stick poll. During
attach and carry the per-hand update returned early and
cleared the grab. Same family as the drop gate FP22
repealed under the FULL MORON CLAUSE and the
interactivity doctrine: physical controls never freeze;
context decides what an action DOES. It survived FP29
only because that brief was drive-phase semantics.

The fix: all three gates take `mode == MODE_HANG`
unconditionally. Semantics identical to the dangle's —
grab/steer/two-hand line/stick rules as FP29 left them.
wheel_angle is never reset by release or landing
(verified in code: the only reset is race start), so a
lock dialled during the ride up persists through the
drop into the drive — that persistence is the POINT.
The car's heading during attach/carry stays
crane-driven; wheel input there is cockpit state only
and touches neither the carrier, the sway, nor the
release mechanics.

Proof (new stage 60 + amended stage 34): in ATTACH a
scripted hand grabs (+0.50 rad steered), a passenger
rides and the line steers (+0.30, join jump 0.000°); the
grab survives the attach→carry transition and steering
answers in CARRY (+0.30); the dialled 1.10 rad crosses
_do_release bit-exact, the landing inherits it at
1.1000 rad, and it is present in the drive's first
frames; the stick steers in ATTACH at rate (+1.30 rad
per 0.5 s). Stage 34's FP13-era expectation ("the wheel
does not grab during transport") is REPLACED and
flagged in place — the probe now asserts grab + steer
in transport, then lets go before the drop press as
before.

## Item 2 — the centre gauge (interim instrumentation)

The owner's reason, verbatim-ish: a centering line
"until we get the tires looking a little better" —
while tire readability is weak, the wheel itself
carries the centre reference.

- CENTRE STRIPE: a band wrapped on the rim at its
  12 o'clock (spin-local (0, 0, −0.205), wheel-plane
  angle −PI/2 at wheel_angle 0), INSIDE the wheel_spin
  node, so it rotates with the wheel exactly and its
  clock position IS the lock readout — in the dangle
  too, where Item 1 makes the wheel live for dialling
  the landing lock. 48 mm of arc, sized proud of the
  40 mm rim tube on every face (0.048 × 0.046 × 0.044),
  in the hub's own unshaded amber (1.0, 0.75, 0.15) —
  the wheel's existing accent, no new palette.
- FIXED TICK: a small near-white tab (0.014 × 0.032 ×
  0.030) on the tilt node at top centre, standing just
  off the rim's driver-side face — never spins.
  Stripe-vs-tick offset reads as an angle: a gauge
  pair, not just a stripe.
- No physics, no input change.

Proof: smoke stage 60 asserts parentage (stripe's
parent == wheel_spin; tick's == wheel_node) and 1:1
tracking read from LOCAL transforms in wheel-node
space (stripe at wheel_angle − PI/2, r = 0.205 m, at
locks 0 / +PI/2 / +PI / −PI/2; the tick pinned at
−PI/2 throughout). Render proof captures 28–30 (the
dangle at centre / quarter / full lock, from the eye
anchor) assert the stripe's displacement off the tick
equals the staged lock (measured +0.00 / +0.79 / −3.14
rad). Observed in the captures: at full lock the
stripe sits at 6 o'clock, below the fallback camera's
frame — the inverted spokes carry that read; in the
headset a glance down finds it.

## In-pass conviction

The first FP30 smoke run passed every check but
carried 90 engine errors the FP29 baseline did not:
"AABB size is negative" from debug_dash_ctl_audit —
the audit grows every car mesh's AABB by −0.01 and the
tick, at 14 mm wide, grows to a negative AABB (an
engine error, and a meaningless test: nothing can sit
1 cm inside a 14 mm mesh on that axis). The audit now
skips degenerate shrinks; every pre-FP30 mesh takes the
identical path, and the audit's verdicts are unchanged.

## Census

Baseline = FP29 final (3a3a912) re-run this session.
Smoke: ALL 624 CHECKS PASSED (595 baseline + stage 34
amendment +1 net + stage 60's 28). API guard: ALL 71.
Byte-level diff of check lines, baseline vs FP30 —
the ONLY differences: stage 34's flagged replacement
(1 line → 2); stage 46's printed telemetry ring count
223 → 225 (the amended stage-34 probe's WHEEL LAT +
REL events entering the ring; the assertion is
unchanged — the same knock-on class FP29 documented
for its stage-32 amendment); stage 60's 28 additions.
All other 594 baseline lines identical. Render proof:
162 of 163 — the one failure is the pre-existing
sandbox hub-reach artifact ("wheel hub 0.31 m below
the eye"), identical in the FP29 baseline proof run
this session (151 of 152 there, same single failure);
FP30's proof adds 5 gauge checks + 3 captures
(163 = 152 + 5 + 3×2 snap lines).

## Delivery

Pushed 2026-10-31: master f430bb2 (commits c69a685
main, 89a57ec stages+proof, f430bb2 README),
ls-remote-verified, zero *.uid / *.png.import in the
tree. Confirmation smoke run after the audit fix:
ALL 624 CHECKS PASSED, zero engine errors, check
lines identical to the first FP30 run.

## UNVERIFIED (the owner's, in the seat)

Whether the wheel answering from the first second of
the lift FEELS right — dialling the landing lock during
the ride is the new skill this pass creates; the stripe
and tick's legibility at cockpit distance in the
headset (the sandbox captures are llvmpipe structure
evidence, not colour truth); and whether the gauge
earns its keep until the tires read better.
