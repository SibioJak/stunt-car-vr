# Fix Brief 5 — Stunt Car Racer VR, Test 1 (Fix Pass 5: the feel pass)

Base: commit add1990 (master, remote-verified). Source: Chris's run 5
(2026-10-26 16:20–16:33 CDT) and his references to the original game.
Repo rules: never commit `*.uid` or `game/tests/*.png.import`; ONE commit;
push to origin master (repo's configured sshCommand) and verify
`git ls-remote origin master` == new HEAD. No audio.

UNLIKE passes 1–4, this pass is AUTHORIZED to change the driving model
(item 1). Where honest physics changes a previously identical smoke number,
report the new number and why; keep the sim deterministic and re-derive the
affected assertions — never tune the model to make an old number pass.

Chris's governing line for the whole pass: "That all gets to the view and
how it behaves. I want to feel that suspension when it hits the road."

## Item 1 — Suspension and mass (headline)

References (Chris-supplied): the original Amiga game — at ~1:25 of the
longplay (youtube.com/watch?v=KncdXpc4jlE) the tires visibly bounce up and
down; his GIF (makeagif.com/i/syclFy, Drop Start + launch) shows the nose
and the front tires, visible at the edges of the cockpit view, working
against the fixed cockpit surround. Chris: "you get a lot of air in original
game just bouncing." Crammond's bounce was a simulation RESULT.

Build:
a) **Wheel load in the driving model.** Each axle (per-corner if the model
   supports it cleanly) carries suspension travel driven by the road
   profile under it, landing impacts, and accel/brake weight transfer.
   Wheels visually travel relative to the body within a plausible stroke;
   the nose/front wheels as seen from the cockpit must visibly work.
b) **Rebound air.** When travel/rebound over a crest or undulation at speed
   unloads a wheel fully, the car goes genuinely airborne (no scripted
   jumps): steering authority fades while airborne, touchdown is graded by
   the existing landing logic, and damage coupling stays as built.
c) **View behaviour.** The seat stack gains suspension-driven motion,
   additive over the anchor (anchor = rest state; offsets transient, zero
   at rest, never moving the anchor itself): compression dive on touchdown
   scaled by landing grade (clean = deep, smooth, one overshoot and a
   settle; hard = bottoming jolt, short and sharp), squat under
   acceleration, dip under braking, and small continuous working motion
   while rolling. Amplitudes conservative — sell mass, don't fight the
   player's head.
d) Keep the car visually one piece with its suspension: body pitch/roll
   follows the axle loads (nose dives, body leans on its springs in the
   bank) — the visible car and the view must tell the same story.

## Item 2 — Lever grab-zone activation

Dash/prep activation for lever-shaped controls is measured to the lever's
grab segment (base point → tip point, closest distance from hand origin to
the segment), still at the 0.15 m radius. Buttons/point controls keep point
measure. Chris's hand arrives at the shaft; the tip cap must no longer be
the only live spot. Update the stage-2d-style smoke assertions accordingly
(hand at mid-shaft activates; hand 0.20 m from the whole segment doesn't).

## Item 3 — Precarious sway, compliant chains

Rebuild the dangle motion (Drop Start and drone recovery share it):
- Two pendulum axes, out of phase, so the resultant path is diagonal and
  never settles into a clean single-plane rhythm; amplitude clearly above
  the current 0.74 m single-axis sway.
- Drone dips: brief vertical/attitude disturbances with a visible
  correction (the drone is working to hold the load), irregular timing.
- Compliance: the car follows the drone through a lagged, damped
  second-order response — overshoot at swing extremes, secondary settle,
  and on a dip the lines go briefly slack: the car drops a touch faster
  than the drone before the lines catch.
- Car attitude (pitch/roll) follows the swing state diagonally.
- FAIRNESS CONSTRAINT: the Drop Start skill stays honest — the swing state
  at release carries into the drop (timing the release remains the skill),
  and a release at swing centre must still land on the ribbon. Re-derive
  the hang/drop smoke assertions for the new model and state plainly how
  release interacts with sway now.

## Item 4 — Lean view-tilt amplification

The lean experiment gains feedback: while lean is ON, the view rolls with
gain on the player's lean (named constant, start ~2.5×, applied in the
seat/car stack — never by writing the HMD pose). Symmetric, zero at centre,
and OFF when the experiment is off. Grip effects unchanged. This revises the
experiment's original "no added camera roll" rule at Chris's direction
("the view would have to tilt more"). If panel or README text describes
lean, update it; the panel must still list every command accurately.

## Verification (all required)
- Clean headless import, exit 0, zero script errors; GDScript preflight
  audit on all changed code.
- API-surface guard passing (extend for any new live-path engine calls).
- Smoke: full suite green under the NEW model, with new assertions —
  suspension travel occurs over the test road and at touchdown; a crest at
  speed produces a measured airborne interval (bounce-air); touchdown
  compression depth orders correctly by landing grade; grab-zone segment
  checks; dangle resultant path is multi-axis (both axes exceed a floor
  amplitude) with hang-centre release still landing on the ribbon; lean
  tilt gain present when ON, absent when OFF. Report every changed legacy
  number with its reason.
- Render proofs: cockpit view; lift view showing the car hanging at a
  diagonal; a frame (or short frame strip) catching visible front-wheel
  travel/nose dive at a landing if the test rig can stage it.
- Frame stats. Report format as in prior passes, ending with what Chris is
  judging on run 6, and the standing line: all live feel UNVERIFIED until
  his headset says so.
