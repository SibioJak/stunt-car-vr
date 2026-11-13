# Fix Pass 26 — Flask Meter, Higher Drop, Button Up

Ordered live from the seat by the owner (Jaklar), Fri
2026-10-30 17:00–17:02 CDT, run 20/21 on c809233. Base:
master @ c809233 (FP25 final). Three items, one dash-and-crane
conversation.

## Item 1 — The turbo meter becomes a liquid flask

The FP24 dash-face bar is OBSCURED BY THE STEERING WHEEL from
the real seat (owner's screenshot: the blue fill reads as a
sliver behind the wheel's spoke). The bar is REMOVED.

His redesign, in his words: "a liquid flasky meter where one
of those flat buttons is along the dash, like the green one.
sloshes around with car movement, drains some on use."

- A flask/vessel gauge set INTO the dash button row — the row
  the driver can actually see (green/amber/red buttons all
  read clearly in his capture). A vessel silhouette, visibly
  NOT a pressable button; it is a gauge, never a control.
- The liquid level = boost stock vs capacity. While boosting,
  the level visibly drains. A payout raises it in a chunk at
  the grading moment (keep a brief brightening then).
- The liquid SLOSHES: its surface responds to the car's
  lateral/longitudinal acceleration and attitude through its
  own damped spring — it lags and settles like liquid, not a
  mirror of the inputs. In the hang it hangs/sways honestly.
- Placement must pass the sightline discipline the bar failed:
  verify from the shipped eye anchor, through the wheel at
  centre AND at full lock both ways, that the flask is never
  behind the rim or spokes. DIAG BOOST / LAST PAY lines stay.

## Item 2 — Crane drop height ×2 or more

"We need a higher crane drop by around x2 or more." The
dangle station holds the car at TWICE the current height
above the road (or a touch more); the chains lengthen to
match and the crane reads at the new scale. Expected physics,
to be verified staged: fall ~0.41 s → ~0.58 s; pendulum
period ×~1.41 with the FP15 gust/jib-flex character kept.
Touchdown grading is lateral/heading-based and does NOT
change. Every stage encoding the old fall time, hang
clearance, or station geometry is amended and FLAGGED (FP14
drop-fall, stage 34 fall timings, stage 28 clearances, any
other the builder finds).

## Item 3 — Drop button UP

Raise the drop button on the dash face from its current low
spot to the upper dash face — clear of the wheel's rim sweep
at full lock and clear of the new flask; the grab zone moves
with it; SIDE mirroring and the persisted side setting are
preserved. Any stage encoding the button's coordinates is
amended and FLAGGED.

## Standing constraints

Economy constants unchanged (120 / 60 / 30 / rate 10). Drive
census frame-identical; hang/drop prints change only where
Item 2's geometry honestly changes them, enumerated in the
README. Commands list updated same-commit (flask description;
button position wording if any). ClassDB guard green. No
`*.uid` / `*.png.import` commits.

## README "What you're judging"

The flask: readable at a glance from the seat, sloshing as
the car moves, draining under boost, jumping on a payout. The
drop: a fall with real air under it, and the sway that comes
with the longer chains. The button: up where the hand expects
it. NOT in: any economy number, any drive feel.
