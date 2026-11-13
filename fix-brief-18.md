# Fix Pass 18 (micro) — Asphalt

Ordered by the owner (Jaklar), Thu 2026-10-29 15:15–15:16 CDT
("can we get the track more road colored, not brown" / placement
delegated: "whatever is best"). Base: master @ 8288719 (FP17
final). Repo: SibioJak/stunt-car-vr, game/. MICRO-PASS: road
surface COLOUR only.

## The item

The ribbon's main surface field changes from its current brown
family to an asphalt-grey "road" family, on every driving surface
that shares the surface build (mountain circuit, test ribbon, the
loop spur). Edge strips and the centre band keep their amber
identity; report in the README if the grey makes any existing
marking read worse and what you did about it (within colour only).

Deliberately OUT of scope: geometry, sections/markings design
(that is the tracks pass — this pass exists to isolate the colour
variable ahead of it, per the owner's sequencing), fog, lighting,
drive numbers, cockpit. Colour constants / vertex colours only.

## Measurement

Re-run FP12's wash-fraction instrument (road-vs-desert contrast
at the standard sightline stations: dip_floor, before_dip,
mid_straight, loop_approach, home_straight) before and after, and
report both columns in the README. State the standing caveat with
the numbers: the sandbox renderer does not reproduce the owner's
device colours at driving angles (FP15 finding) — the fractions
show the direction of the change, his headset gives the verdict.

## Standing constraints

No `*.uid` / `*.png.import` commits; ClassDB guard green; all
FP17 stages re-pass; controls list untouched; README results
section with before/after albedo values and the wash table.
