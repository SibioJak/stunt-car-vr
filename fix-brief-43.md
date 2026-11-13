# Fix Pass 43 — THE FUNLAB REBUILD (the loop at the base, the true helix, the wall-ride)

Ordered by the owner's FP41 field verdicts (2026-11-03): the loop
"works as a loop" but "doesn't have correct entry, exit point"; the
corkscrew "just doesn't have any stick, not gonna work" — he could
not get past it. Reference shelf: research/hot-wheels/ (hw1–hw7).
Base: master 3f3fea7 (FP42). BUILD_STAMP → "FP43 · 2026-11-03".

## Item 1 — THE LOOP, REBUILT AT THE BASE

The FP41 ring stood beside the road's line: the car entered,
looped, and exited on a parallel offset. The rebuild plants the
ring ON the road's line, Hot Wheels form (every HW loop is tangent
at its base): a 92-step index-symmetric curvature profile
(smoothstep ramps over the first/last 12% of steps, plateau
R = 12.89 m) whose closure is exact under the generator's own
step-end scheme — measured on the shipped arrays: the exit lands
ON the entry line (d_lat 0.000, d_up −0.001), 11.0 m ahead of the
entry point, crown 25.98 m over the base. The eased joins retire
the old ring's curvature steps: max |Δkvf| per station 0.0102
against the old ring's 0.0765 single step at each join.

Staged audit (pin ladder + floored), before → after:
- FP41: clean held 22–32 and floored; 16–20 the defect band (the
  rebound throw fired at the joins' curvature steps — at 16 it
  dropped the car inside the ring); 14 ragged; under ~11.3 the
  crown lets go.
- FP43: held 18 / 20 / 22 CLEAN — no separations, exit = entry
  speed to the tenth. Floored from 24 exits at 42.7. At 16 the car
  comes off at the crown approach (s 151 of 110..202, one flight,
  crane collects) — note the static law reads the crown itself at
  +1.02 g at 16, so the loss is a transient on the approach, not
  the crown letting go; the band's join-hop mechanism is gone with
  the joins. At 14 the car hops (9 short flights), gets over the
  top inverted, and comes off at the exit ease (s 198).
Board: "CLEAN 18+ OR FLOORED - 16 COMES OFF AT THE TOP".

## Item 2 — THE CORKSCREW, REBUILT AS A TRUE HELIX

The FP41 piece rolled the road around a straight centreline —
physically incapable past the quarter-turn (road-frame normal
force = g·cos(bank), no speed term). The rebuild's centreline is a
helix about the entry tangent axis (orbit radius 5 m, axis advance
10 m/rad, one full turn, ~69 stations, ~7.1 m drop, entry/exit
tangents = the axis itself), and the road's up faces the path's
principal normal, so the steep-regime load law reads the path's
own curvature (kvf −0.0399 = −κ_h through the core,
κ_h = a/(a²+c²) = 0.04). Three construction facts the audit
forced, all measured:

1. THE SURFACE MUST FACE THE TURNING. Two gentler constructions
   were built and convicted by staged drives first: a tube-normal
   surface (up → −r̂) unloads at the entry — the centreline's dip
   is a crest to the patch law while the frame is still near
   level (all pins separated at the door, s 355); a parallel-
   transport + scheduled-twist surface runs up to 35° off the
   turning direction in the transition quarters (kvf to +0.10,
   loads to −2.7 g). Only the normal-facing surface presses
   everywhere (kvf ≤ −0.033 at every station).
2. THE PRE-ROLL. The path's first curvature points sideways and
   down, so the normal-facing surface starts at −116° of bank.
   The run-in pre-rolls the road across its whole 30 m
   (0.067 rad/m — gentler than the barrel roll's own entry twist)
   to meet it: measured seam, bank −112° at s0−1 against −116° at
   s0+1. No snap at the door.
3. THE DOUBLE ROLL. On a helix of this pitch the turning
   direction accumulates ~700° in the road's frame over one orbit
   (the orbit's 360 plus the tangent cone's twist) — the piece is
   a double-roll corkscrew, two inversions, the Arrow form. Bank
   is stored unwrapped; the run-out untwists to the frame-flat
   branch (−2·TAU) and the scalar offset rides through the climb
   home into E3's targets, whose closing reset absorbs the whole
   chain — no bank seam anywhere on the course (E3 re-audited
   after the offset: floored 36, 28 hops, exit 16.2, max lat 2.43
   — its FP41 signature intact).

Hold trace (static, off the shipped arrays, steep law at the
deep crown s 400): +0.25 g at 14, +0.63 g at 16 — the force is
the path's.
Staged drives: held 14 / 16 / 18 / 20 all complete, exit = entry
speed, fully inverted twice every run (min basis up.y −0.99 to
−1.00), 1–3 short hops (one at the bottom twist, ~s 373). At 24
and floored 30 the car slides off the exit wall (max lat ~8.0
against the 7.17 fall line) and the crane collects it — a lateral
limit, not a load limit (the static crown load at 24 is +1.20 g).
Ease profile asymmetric (in 0.26 / out 0.42 of the turn) — the
long exit ease moved the shed point but did not cure it; the
window is boarded as measured.
Board: "DOUBLE ROLL, TWO INVERSIONS - HOLDS 14-20 - 24+ SLIDES OFF
THE EXIT WALL".

## Item 3 — NEW PROTOTYPE E4: THE WALL-RIDE 360

Off hw6's near-flat rings: a full-circle banked turn, R 28 m at a
constant 55° of bank, rejoining its own entry line — bank + turn
only, no inversion. Yaw is a trapezoid in step index (ramps of
4 × 6 m, mirrored) summing to TAU + 0.00003; closure measured:
exit 24.83 m ahead of the entry point on the entry line
(d_lat 0.030, d_up 0.000), bank 0 / 55.0 / 0 at entry / mid / exit.
Bank law: neutral speed v* = √(g·R·tanβ) = 19.8 m/s; loads
(g·cosβ + v²/R·sinβ)/g run 1.34 g at 16 to 2.59 g at 26; the frame
up.y bottoms at 0.54 ≈ cos 55°, so the piece never enters the
steep regime. Staged: held 14 / 17 / 20 / 23 / 26 / 30 — every run
clean, no separations, exit = entry speed, heading sweep
360–362°, lateral band −0.38..+1.84 m (the 7.17 fall line never
threatened). Hands-off at 20 it sheds off the wall by sweep 20° —
it is a banked turn, not a slot; the line is the driver's.
Board: "STEER IT - HOLDS 14-30, NEUTRAL AT 20".

## Constraints honoured

- ELEM jump-ins re-derived for E1–E4 (stations 90 / 298 / 562 /
  704 on the shipped course, len 1,048 m) and non-gating
  re-proven in stage 69 (each jump-in drives into its own element
  first). Desktop F4 added for E4; the in-game commands list and
  the README controls carry it in the same pass.
- E3 untouched except its station and the bank-scalar offset
  (frame-identical; re-audited above).
- Census: the FP41/FP42 laws re-verified on every other track by
  the full suite (tangent laws, storm law, gearbox, fishtail,
  retention, pitch channel) — see counts. Baseline re-run on the
  pristine FP42 tree before the rebuild: SMOKE ALL 803, API 71.

## Gates

SMOKE ALL 810, API GUARD 71/71, render proof 172/173 (the standing wheel-hub artifact only).
Stage 66 amended in place (four elements/boards; the helix's
inversion + untwist checks; E2's entry state is the pre-roll;
E3's bank readings taken wrapped against its −2·TAU offset; the
pin-18 loop check that retires the defect band; E2's held-20
double-roll and held-24 shed checks; the E4 wall-ride check;
fin66 now runs E3 → E4's wall → the course end). Stage 69's
jump-in loops run to 4. As built: stage 69 caught E3's jump-in
station at 298 (the barrel approach's −2-turn stored bank read
as "banked" by the drop-search helpers, walking the search back
to E2's run-in); _drop_piece_ok / _drop_runup_ok now read the
wrapped bank, E3's station is 562, and the full suite re-passed
at ALL 810 with the fix in.
