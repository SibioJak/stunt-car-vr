# FIX PASS 37 — TRACK 01: THE FIRST REAL CIRCUIT

Stunt Car Racer VR, Godot 4.7, ~/workspace/stunt-car-vr/game. Base: master
7b1a691 (FP36). Chris's order (2026-11-02, queued behind FP36): "after
that I'd like to see a track put together, a circuit, with all the track
elements we have so far. lots of turns in both directions, steep climbs,
steep descents. jumps." — and "replace first test track with it."
BUILD_STAMP -> "FP37 · 2026-11-02" per the ritual.

## THE BUILD

1. SLOT: Track 01 REPLACES the FP10 mountain circuit in slot 1. TRK
   cycles Track 01 -> ribbon -> Feature Lab. The lab and the ribbon
   are untouched (the lab stays the piece library + audit instrument).
2. FORM: closed desert circuit, 3,493 m, 3 laps per race, Drop Start
   at the head, crane recovery everywhere, finish line closing the
   loop. Closure is solved on the tail (return length / hold pitch /
   closing-hairpin radius): lr 247 m, phi_h -0.3 deg, R_e 123 m,
   residual 0.004 m.
3. CONTENT (prototype-first — every sector a proven piece, spans from
   the builder's features["sectors"]): T1 the Opening (Drop Start
   flat + one FP8 hump at s 220 — no rest sections, the launch
   straight is taxed) · T2 the Flair (left R185, 26 deg bank, shaped
   unwind) · T2b First Crest (+12 deg) · T3 THE DIVE (-18 deg x 170 m
   steep descent, valley hump, 55 m settle) · T4 the Off-Camber S
   (R85, adverse +-10 deg, 30 deg per arc + a 55 m settle link — see CONVICTIONS) · T5 THE
   WALL (+20 deg x 170 m steep climb, soft crest flatten) · T6 the
   Edge Run (markers on the edge line + bank sway) · T7 the Chasm
   (28 m, lab P4 verbatim + rising exit) · T8 West Hairpin (left
   180 deg, R40) · T9 Crest Launches (+14/+20 deg) · T10 Drumbeat
   Ridge (FP8 row verbatim) · T11 Compression->Rebound (lab P6
   verbatim) · T12 Staircase (-22 deg steps) + THE ESCALATOR
   (+17 deg x 100 m, sharp crest-off) · T13 the Long Right Home
   (right R100, -26 deg bank, descending -9 deg) · T14 the Last
   Hump · T15 the Tail (return with bank sway + its own FP8 hump,
   closing hairpin).
4. GRADES VERIFIED against the car's envelope: the Wall gains
   52.4 m on its span (stage 18 census), the Dive drops 57.9 m
   (stage 18's dip measure), the Escalator crests at the lap's
   high point (85.5 m; valley floor 5.2 m). The feasibility drive
   (stage 19, 3 laps, production car) tops every climb at pace.
5. PROOF: (a) stage 19 completes 3 laps to DONE; (b) stage 54's
   air/payout audit repriced for Track 01 (figures in the README);
   (c) the grades table in the README with measured outcomes.
6. CENSUS: stages keyed to the old circuit re-derived + flagged in
   place — 18, 21, 29, 35, 49, 51(a), 51(c), 51(d) amended; 19, 20, 26, 34,
   51(b)(c), 52(a), 54, 57, 58, 65 verified unaffected. Ribbon/lab
   stages untouched.

## CONVICTIONS (found by the feasibility drive, fixed in the track)

1. V2 WEDGE: the Dive's valley-hump rebound landed CROSSED-UP inside
   the S and the car pogoed on its springs in a permanent AIR/DRIVE
   flicker (no lost-trigger can fire; air_time resets each entry).
   A sequence defect under the lab's own law — the final layout
   gives the rebound a 55 m settle and the S is entered settled.
2. V3/V4 WIDE S: the lab's 70 deg adverse arcs, fed at racing pace
   off the Dive, entered at 30.5 m/s and ran off at s 998 (camber
   pull ~1.7 m/s^2 on top of a cornering demand that already spends
   the grip budget at the curvature cap). At 40 deg per arc the
   first arc's slide still killed the second — the 18 m link let
   the driver recover position but not lateral velocity, and the
   reversal threw the car off at s 1085 with ~9 m/s sideways. The
   final instance sweeps 30 deg per arc at the same radius and
   banks, with a 55 m settle link between the arcs (measured
   traversal peaks: -2.89 m / +1.71 m at 30.7 m/s). The lab keeps
   the full piece.
3. SOLVER CLAMP: an intermediate head ended +5.1 m too high and
   phi_h sat on its -0.03 rad clamp (residual 0.79 m). T13's
   descent steepened to -9 deg as part of the lap's elevation
   budget; the final head solves with phi_h at -0.4 deg, mid-range.

## GATES

Preflight audit, parse warnings-as-errors, ClassDB XR guard, full
smoke, render proof — figures in the README's FP37 entry. No
*.uid / *.png.import in the commit. The scratch probe
(tests/zz_probe37.gd) is deleted before the commit, per house rule.
