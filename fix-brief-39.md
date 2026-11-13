# FIX PASS 39 — TRACK 01 REWORK: FAIR HILLS

Owner's conviction (2026-11-02, from the seat): "the part that feel
frustrating and probably unfair is consistent: coming out a turn straight
into a tall hill. A: You're probably not gonna be straight, so you're
guaranteed to go flying off the track. B. You don't get any sense what's
on the other side of the hill because between the turn and the hill, your
view is pretty much blocked."

## The two laws being restored (both were in the FP37 brief; the layout broke them)

A. LATERAL VELOCITY: a short link after a turn restores position but not
sideways velocity. A turn exit flowing into a tall climb converts that
sideways speed into a launch angle off the road.
B. HONEST SIGHTLINES: no blind launch — from the driver's eye at the turn
exit, the far side of a climb must be readable before he commits.

## Work

1. AUDIT every turn-exit -> climb join on Track 01 with the staged driver
at racing pace: lateral velocity at the climb's foot, and a geometric
sightline check from the cockpit eye height (1.26 m). Publish the table
in the README.
2. FIX the guilty joins by layout surgery: settle/run-out links sized
from the measured lateral velocity and the FP36 bleed law; re-sight the
blind joins. THE HILLS STAY TALL: grades and drops are not the defect;
arrival state and visibility are. Track length and sector order may
change as the surgery requires.
3. RE-PROVE: feasibility (3 laps, zero falls), the payout/air audit
repriced, a post-fix audit table with the same instruments. Census:
every stage keyed to the old geometry flagged in place; ribbon/lab/TRK2
stages must not move.

## What the audit found (summary — full tables in the README's FP39 section)

- Every one of the six joins was blind from the turn exit (B1: no road
  past any lip visible), and four of the six launched the staged driver
  26–147 m. The worst: the S -> Wall join, where the car separated at
  the 48 m/s clamp on the Wall's own crest flatten and flew 147 m over
  the whole Edge Run.
- The geometry result that shaped the fix: from a lower eye, a far-side
  point past a convex lip is visible only if the far side rises back
  above the lip's sightline. Falling far sides (the Dive, Drumbeat
  Ridge, the Long Right) can never be read from the turn exit — so every
  turn-fed launch was GROUNDED instead of re-sighted: pitches stay,
  pitch sheds stretch until v^2.kv < g at the fastest honest arrival.
- The storm law, learned across audit runs: on a sustained grade
  nothing caps the speed — a floored car (the staged driver, and the
  owner) accelerates along the early shed, which is still a climb, and
  separates wherever v^2.kv crosses g. Final law: EVERY convex shed on
  Track 01 runs at 0.0032/m (v^2.kv = 7.4 at the 48 clamp, no crossing
  at any speed). The Last Hump's back runs 0.007 (its arrival is
  curvature-capped by the sweeper itself).
- Links: S -> Wall 18 -> 60 m (slide measured +3.8 m/s at the arc exit,
  bled to zero ~19 m into the link; the rest is the staged driver's own
  correction ripple dying out — foot reads -0.17 m/s at 46 m/s). Flair
  settle 20 -> 35 m.
- Compensation, honestly booked: Dive -18 x 170 -> 282 (with a brow-rate
  entry ramp — a grounded car now arrives at ~44), Edge Run 110 -> 90,
  T13 grade -9 -> -15. A chasm exit trim (55 -> 30) made during the
  closure search was reverted after stage 35's rebound census convicted
  it (the rebound off the rising ground vanished inside the stage's
  window; restored, it reads 0.64x). Lap 3,493 -> 4,066 m. T9 CREST
  LAUNCHES renamed THE TWIN CRESTS.
  Solver: lr 238, phi_h -0.02 deg, R_e 99, residual 0.003 m.

## Post-fix audit (same instruments, two staged laps, zero falls)

Every foot |lat_vel| <= 0.23 m/s (threshold 0.5); zero separations in
every grounded join's zone; every far side reveals itself 17–27 m
before its lip from a grounded eye. Feasibility and repricing stand in
the README's FP39 section with the suite's numbers.
