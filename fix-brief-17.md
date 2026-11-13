# Fix Pass 17 — One Hand, One Control (+ throw telemetry)

Ordered by the owner (Jaklar), Thu 2026-10-29 14:15 CDT, on his tap,
after reading his own run-16 grab log. Base: master @ ddf0612
(FP16 final). Repo: SibioJak/stunt-car-vr, game/. SURGICAL pass —
two items, nothing else. The queued load (smoke kill, banner,
tire story, toggle grip) is NOT in this pass.

## The evidence (his data, not our staging)

~/workspace/stunt-car-vr/research/grab-log-run16.txt — 14 events
from his live session. Two findings drive this pass:

1. CROSS-TALK, CONVICTED IN HIS OWN LINES: at T14.8 the left hand
   rim-attached (L RIM ATT) in the same instant it fired the drop
   lever (L DRP FIRE). One squeeze grabbed two controls: FP16 grew
   the lever's grab radius to 0.20 m, and that volume overlaps the
   wheel's rim-attach test. Harmless in that fragment (the right
   hand held the wheel, so the lever hand could only ride as a
   passenger) — but with the wheel FREE, a lever grab can latch
   the WHEEL, and pulling the "lever" then steers instead of
   dropping. Fits his report exactly: first drop works (set up
   deliberately, wheel held), later drops iffy (recoveries, hands
   everywhere).

2. THE LOG'S BLIND SPOT: it records LAT and FIRE but nothing of
   the pull between them, and no latch-release line for the lever.
   A pull that stalls short of the detent leaves no trace. Also,
   the file he uploaded held only his last short session — earlier
   attempts were not in it.

His grips, for the record, are healthy (latch 0.78–1.00 both hands,
releases 0.14–0.25). Do not touch thresholds in this pass.

## Item 1 — One hand, one control

A hand owns at most one control at a time, enforced in the grab
path's arbitration, both directions:
- A hand latched to any cockpit control (drop lever, seat trims,
  dash buttons' grabs where applicable) cannot rim-attach and
  cannot latch the wheel until it releases that control.
- A hand latched to the wheel (driver) or attached (passenger)
  cannot latch a cockpit control until it leaves the wheel.
- Arbitration must be deterministic when a squeeze arrives with
  the hand inside multiple tests in the same frame: the control
  whose test the hand entered FIRST (or nearest, if simultaneous
  entry cannot be ordered) wins, and the loser records nothing —
  no attach, no latch, no witness. State the rule you implement
  in the README.
Stage it: a simulated lever grab with the wheel free must produce
LAT+FIRE and ZERO rim/wheel events for that hand; a simulated
wheel grab inside lever range must produce the wheel and zero
lever events; FP16's both-hands case (one hand wheel, other hand
lever) must still work exactly as staged in FP16.

## Item 2 — Throw telemetry (close the blind spot)

Extend the shipped grab log (same file, same DIAG line family):
- Lever pull progress: while a lever is latched, log crossings of
  pull fraction 0.25 / 0.50 / 0.75 (one line each, with grip).
- FIRE lines gain the pull duration.
- A latch that ends without firing logs ORPHAN with the peak
  pull fraction reached and the grip at release.
- Lever latch release is logged (DRP REL, and equivalents for
  the other lever-class controls if they share the path).
- The log file APPENDS across launches with a session header
  (build hash + timestamp) per launch, capped at a sane size
  with oldest-first trimming — the next upload must carry every
  attempt since the build landed, not just the last session.

## Standing constraints

No `*.uid` / `*.png.import` commits; ClassDB guard green; all
FP16 stages re-pass (amended only where Item 1's arbitration
deliberately changes staged expectations — say so where it does);
controls list unchanged (no new commands); no drive numbers move;
thresholds (0.55 / 0.30) untouched. README results section: the
arbitration rule, before/after log format with a sample of the
new lines from a staged run, tallies, honest residuals.
