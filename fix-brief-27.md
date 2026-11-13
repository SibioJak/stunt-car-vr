# Fix Pass 27 — Ditch the Green Beam

Ordered live from the seat by the owner (Jaklar), Fri
2026-10-30 19:21 CDT, run 22 on 844efb3: "we need to ditch
the green finish line beam, it pops into view sometimes as
you're swinging." Base: master @ 844efb3 (FP26 final).

## Scope

- Remove the START/FINISH gantry's green overhead BEAM — the
  span that slabs across the sky view during the hang sway at
  the doubled station (owner's screenshot, 2026-10-30).
- The finish line becomes a ROAD-SURFACE marking: a stripe
  across the ribbon at the line (chequered or plain — builder
  picks the more legible at speed, reports the choice), flush
  with the surface, part of the road mesh family so it
  inherits the winding-correct rendering.
- The gantry POSTS: if they stand clear of the sway sightline
  and read as furniture, they may stay; if any part of the
  remaining structure can still cross the dangle view, it goes
  too. Report what remains and why.
- Both tracks (circuit + ribbon) get the same treatment where
  the same structure exists.
- Lap timing / line-crossing logic is untouched: the line's s
  does not move; only its presentation changes.

## Stages

Any stage or proof capture asserting the beam's presence is
amended and FLAGGED; a new check asserts the beam's absence
and the stripe's presence in the road band of the line frame.
Drive census frame-identical. ClassDB guard green. No
`*.uid` / `*.png.import` commits.

## README "What you're judging"

A finish line you cross, not one that falls across your sky.
Nothing else in this pass.
