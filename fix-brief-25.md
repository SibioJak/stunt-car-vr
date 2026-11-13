# Fix Pass 25 — The Steering Connection (visual only)

Ordered by the owner (Jaklar) 2026-10-29 10:04–10:05 CDT, GO
given Fri 2026-10-30 09:26 CDT. His words: "there needs to be
a visual connection between wheel and steering wheel" / "The
tires are telling a story, with their wobbling and bouncing,
but we gotta see it." Base: master @ FP24 final (chains).

## The problem

Since FP13 the front wheels DO show the steer angle — but from
the seat they are barely visible and the angle at small inputs
is too subtle to read. The wheel in his hands and the tires on
the road feel disconnected. This pass is PRESENTATION ONLY:
no physics value moves (drive census frame-identical).

## Item 1 — Sightline audit first

From the shipped eye anchor, measure how much of each front
tire is in the driver's view at rest and at full travel, in
the render proof. Report the numbers before changing anything
— the remedy sizes itself to the measured blindness.

## Item 2 — Visual steer gain

The front wheels' DISPLAYED steer angle gets a gain curve:
exaggerated at small lock (so a quarter-turn of the wheel
reads clearly on the tires), converging to the honest angle
at full lock. The drive model keeps using the true angle;
only the mesh yaw is gained. Curve constants named and
reported; the dangle dial-in display inherits the same gain
(the promise the release keeps must be the one he saw).

## Item 3 — Slip made visible

Add the front tires' slip angle to the display: a small,
honestly-scaled yaw offset (capped) so a slide beginning is
something he can SEE on the tires, completing the FP15
limit-warning story in the visual channel. Visual only.

## Item 4 — Tire presence (only if the audit demands it)

If the audit shows the tires are geometrically out of view
(gain alone can't fix what can't be seen), the minimal
presentation change that puts them in frame: front tire
visual size/offset within the Odd Rods language (the Pro
promo's huge exposed wheels are the owner's filed reference),
contact patch and travel display unchanged in behaviour.

## Standing constraints

Physics untouched — census frame-identical, stated in the
README. No `*.uid` / `*.png.import` commits. ClassDB guard
green. All prior stages re-pass or amended-and-flagged (the
FP13 steer-display stage expectations move to the gained
values, flagged). README results: audit numbers, gain curve,
tallies, "What you're judging" (wheel↔tire connection at
small inputs, slide visibility; NOT in: any feel change —
there is none by construction).
