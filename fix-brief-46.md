# FIX PASS 46 — THE FUNLAB RE-CUT: LOOP ENTRY DECODE + THE HOT WHEELS DIRECTION

Repo: ~/workspace/stunt-car-vr, Godot project in game/. Branch master.
**Base commit: 9dc1ce2 (FP45). VERIFY FIRST: `git log --oneline -1` must show 9dc1ce2
before any edit.**

Scope: TRK2 (the funlab) ONLY. Track 01, the ribbon, and the Feature Lab do not
change. No economy dials. No powertrain changes. The owner's direction verdict
(2026-11-03) governs this pass: "The only thing that's working for me is the loop…
the overall design of typical hot wheels tracks is the direction." The test for
every piece in this lab, in the owner's words: would it work for an UNGUIDED toy
car? A piece that only works inside a narrow entry window is fiddly = not fun =
no use.

## ITEM 1 (HEAD) — Decode the loop entry, from the driver's seat

Standing state: the FP43 loop itself is PROVEN (index-symmetric base-tangent
profile, R 12.89 plateau; clean 18/20/22 and floored; FP41's 16–20 rebound band
retired). The owner looped it himself on 2026-11-03 — and immediately added:
"the entry to the loop remains a non entry." Clarified in conversation: the entry
doesn't READ or SOLVE from the driver's approach. The loop is not the problem.
The way in is.

METHOD — diagnose from the seat, not the spine:
1. Render the approach through the driver's eye at honest approach speeds (18–24
   m/s): frames from ~120 m out to the mouth, both cameras. Study what the driver
   actually sees: how much straight run-in precedes the ring, whether the road is
   still curving/banking off the previous ground when the ring arrives, whether
   the ring's mouth and the road's continuation through it read at speed, where
   the ring's legs/mass sit against the road's vanishing line.
2. State the convicted defect(s) in driver terms BEFORE fixing (e.g., "the road
   arrives at the ring still unwinding from X, so the driver is mid-correction at
   the mouth" / "the mouth doesn't read until 30 m out"). Evidence = the frames.
3. Fix at the convicted level. The Hot Wheels form is the reference (research
   shelf ~/workspace/stunt-car-vr/research/hot-wheels/): a toy loop sits on a
   STRAIGHT, LEVEL run-in aligned on the ring's base tangent; the ring straddles
   the track, legs beside the road, threshold flush — a car (or a hand) cannot
   arrive wrong. Expect the fix to be an approach re-lay (station work before the
   ring) and/or ring placement/dressing — NOT a change to the proven ring profile.
4. HARD CONSTRAINT: the ring's proven numbers must not degrade. After any
   approach change, re-prove the full FP43 loop board: clean 18/20/22, floored
   from 24, pin behaviour at 14/16 as FP43 recorded it, exit on the entry line.
   Update the element board text (ELEM board) to whatever the driver now needs to
   know about the entry.
5. Re-derive the E1 jump-in if stations move; keep desktop F1 and the ELEM button
   path working.

## ITEM 2 — Re-cut the lab to the Hot Wheels direction

CONVICTED by the direction verdict — remove from the TRK2 layout: the helix
corkscrew (E2: "just doesn't have any stick, not gonna work"), the barrel roll
(E3), and the wall-ride 360 (E4). They are fiddly pieces with narrow windows;
the verdict is final. (Their removal re-derives funlab stations, ELEM jumps, and
the funlab stages — re-derive honestly and report.)

IN: the SPIRAL BOWL takes the E2 slot — the Hot Wheels spiral (shelf hw7): a
wide-radius, banked, descending spiral. Design targets (the unguided-car test
made numeric):
- Generous radius (circuit-scale, not tube-scale): entry radius ≥ 25 m,
  tightening or constant — builder's design within the toy idiom.
- Bank matched to a NEUTRAL speed in the middle of a WIDE hold band: the piece
  must hold cleanly across at least a 12 m/s-wide band (e.g., pins at 16/20/24/28
  all complete), shedding speed gracefully above the band (slide up/wide, no
  ejection) and holding (not falling in) below it.
- Descending: the spiral pays out height as it turns (a toy car trades height
  for the run), total drop in the 4–8 m range, ≥ 360° of turn.
- Entry and exit on the car's line: entry from a straight, exit onto a straight,
  no mid-piece correction required inside the hold band.
- ELEM jump-in for the bowl (E2), board text written for the driver (band +
  "steer it" / "hands off" honesty, as the wall-ride board did).
The remaining layout after the bowl: plain runout apron on the former E3/E4
ground, then home. Do not invent replacement pieces for E3/E4 in this pass.

RE-PROVE the whole lab after the re-cut: loop board (Item 1), bowl band pins,
staged laps of TRK2 end-to-end, ELEM access to both elements.

## Standing gates (every pass)
Full smoke green incl. the ClassDB API-surface guard (71) and the census EXCEPT
the funlab numbers this pass legitimately re-derives — flag each in place, prove
one-variable, and list them all in the report. Track 01 / ribbon / Feature Lab
census must not move. Rendered-frame proof, including DRIVER'S-EYE approach
frames for Item 1 (before and after). Preflight GDScript audit clean. No *.uid or
game/tests/*.png.import sidecars. BUILD_STAMP = "FP46 · 2026-11-04". Commit on
master, push, VERIFY with git ls-remote. TIMEBOX every run; a hung run is killed
and reported, never sat on.
Report: Item 1's convicted entry defect(s) with the frame evidence and what
changed; the loop board re-proven; the bowl's design numbers and its measured
hold band; every re-derived funlab number; commit hash; suite totals.
