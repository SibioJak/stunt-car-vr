# Loop spur entrance — diagnosis audit (NO code changed)

Master audited: `11c65b2`. Method: the shipped `_build_spur` in
`game/scripts/main.gd` read directly; geometry dumped from the built
game's own runtime data (`track_data["circuit"]["spur"]` arrays and
`_frame_at` / `_spur_frame_at` frames — the same numbers the driving
model uses); POV frames rendered through the game's own fallback
camera at the eye anchor, the same camera the FP render proofs use.

Owner's impression under audit: "It SEEMS the entrance is wrong, I'd
have to do a U-turn."

## Verdict: (C) MIXED — predominantly (A)

The entry joint and the path are geometrically correct and
continuous; **no U-turn exists anywhere in the spur**. The entrance
*reads* wrong from the seat for four measured presentation reasons
(below). There is one small genuine geometry defect — at the
**merge**, not the entry — and one documentation mismatch in the
capture rule.

## 1. The path, measured

Home straight: flat, level, heading constant (yaw step 0.000°/m
through the whole entry/merge span). Spur total length 253.28 m.

| Phase | spur_s | What happens |
|---|---|---|
| Diverge ease | 0–35 m | Centreline eases 0 → **3.4 m LEFT**, staying at road height (**Δh = 0.00 m** the whole phase). Heading deviates at most **+8.2°** (left) at the ease midpoint, back to +1.9° by 35 m. |
| Turn + descent | 35–92 m | Turns left at ≤ **1.00°/m** (the leg's max yaw rate) to **45.5° left** of the straight; descends to **−7.53 m**. |
| The ring | 92.0–161.1 m | Full vertical circle, R = 11 m, kv = −0.091 ≈ −1/R as designed. Base at **83.0 m past the entry point, 28.9 m left of the straight's centreline**; ring top at +14.5 m over road level. |
| Exit leg | 161–253 m | Bezier return: first bows **further left, to 38.5 m off the straight** (spur_s ≈183), then curves back, climbing to road level; net heading swing −44.5°. |

**Entry joint continuity (main s=170 → spur s=0):** position step
**0.000 m**, heading step **0.47°**, pitch 0.00° on both sides,
first-metre yaw rates 0.4–0.9°/m. Clean.

**Ribbons in plan:** both surfaces are 12 m wide. The spur ribbon
lies *on* the main road for the first ~36 m and the two ribbons do
not fully separate in plan until **spur_s ≈ 66 m** — by then the
spur is ~3 m below road level and heading ~34° left.

## 2. The capture rule, as shipped (main.gd, spur capture block)

- Window: circuit only, `car_s` in **[168, 243)**, car moving forward.
- Fires when the spur projection is past the fork's nose
  (`spur_s > 10`), the car's centre is within **1.2 m** of the spur
  centreline, and the car is measurably off the main centreline
  (`|car_lat| > 0.5`). (The block's header comment says 1.3 m; the
  code tests `< 1.2` — documentation mismatch, corridor is 0.1 m
  tighter than documented.)
- What that line is on the road: at spur_s 10 the spur centreline
  is only **0.68 m left** of the main centreline; at 20 m, 2.06 m
  left; at 35 m, 3.41 m left. So the capture line is a gentle
  leftward drift across the road's left-centre — a centred car is
  never captured (by design), and there is no visible line to aim
  at: see §3.

## 3. Why it reads wrong from the seat (the POV evidence)

Ring sightlines from the seated anchor (eye 1.26 m + car clearance):

| Station | Ring centre distance | Azimuth | Ring subtends |
|---|---|---|---|
| 100 m before entry | 185 m | 9.0° left | 6.8° |
| 50 m before entry | 135 m | 12.3° left | 9.3° |
| 20 m before entry | 106 m | 15.8° left | 11.8° |
| 5 m before entry | 92 m | 18.3° left | 13.7° |

1. **The fork has no mouth.** Through the whole commit zone the
   spur is a lateral ease *on* the road surface at identical
   height, deviating ≤8.2°. In all four approach POV frames the
   road ahead is one unbroken surface — there is no visible branch,
   gap, or second surface to steer for. The first unambiguous
   spur surface appears ~66 m past the entry point, already
   diving below the road's left edge.
2. **The ring presents its back.** The ring's plane is rotated
   45.5° to the straight and its base sits 7.5 m *below* the road.
   From the seat you see the ribbon's dark outer side (the driving
   surface faces the ring's centre, away from you); the entry
   mouth at the base is the lowest part of the hoop, tucked under
   its near rim and below the main road's left edge line. In the
   panels-off seat frame (`pov_005m_before_entry_nopanels.png`)
   it reads as a dark barrel lying across a dip — not as a road
   that loops. The approach leg that would explain it dives
   behind the road's own left edge, so the connecting story is
   occluded exactly where it starts.
3. **The DIAG board sits on the ring.** In the as-driven cockpit
   the DIAG board occupies left-of-centre — precisely the ring's
   approach window (9–18° left, ~+1° elevation). In all four
   panelled POV frames the ring's position is behind the board;
   only a sliver of stilt arc shows at the frame's left edge.
   (The run-12 panels verdict and the queued panel toggle would
   also cure this.)
4. **The visible spur ribbon points away.** The spur surfaces a
   driver *can* see from the straight — the descent leg after
   separation, and the exit leg bowing out to 38.5 m left — both
   run down-and-away to the left. Nothing visible runs *toward*
   the ring's mouth. Combined with (2), the gestalt is "the road
   over there goes the wrong way", i.e. the owner's U-turn read.

## 4. The (B) component — merge joint (small, real)

- Merge point placement is exact: spur ends at **2.007 m left** of
  centreline at main s=330 (design −2.0), height step −0.001 m.
- But heading: the spur arrives at **−2.54°** (pointing 2.5° to the
  *right* of the straight's heading) while the main frame is 0° —
  a **2.5° heading step** at the handover, vs 0.47° at the entry.
- And the exit leg is still turning as it arrives: per-metre yaw
  rate over the last 12 m runs **1.6 → 3.4°/m**, peaking at
  **3.45°/m in the final metre** — vs ≤1.00°/m anywhere on the
  entry/descent leg. The Bezier exit does its unwinding late; the
  join carries a small but real swerve demand.

## 5. Presentation options (no physics moved) — for the owner

1. **Paint the fork line on the road.** A diverging amber guide
   strip on the main surface tracing the capture corridor
   (spur_s 0–35 path) so the invisible line becomes a visible one.
   Cheapest, attacks cause (1) directly.
2. **A fork gantry/sign** at ~s 150–165 (LOOP + left arrow) — the
   track already speaks gantry at the lap line; gives the driver a
   decision point before the mouth he can't see.
3. **Light the ring's back.** The ring reads dark because from
   outside you see the ribbon's underside band. A bright edge
   treatment on the ring's outer rim (or the skirt orange carried
   over the outer band) would make the hoop read as a loop of
   ribbon from the approach instead of a barrel.
4. **Chevron/arrow markers down the descent leg**, so the visible
   spur surface tells the direction story the mouth can't.
5. **Panels hidden by default** (already the run-12 direction)
   removes occlusion cause (3).
6. NOT recommended without builder review: visually sinking the
   spur mesh's first metres to fake an earlier mouth — mesh and
   physics surface would disagree under the wheels in the capture
   zone.

## Evidence files (this folder)

- `plan_and_profile.png` — plan view in driver coordinates +
  elevation profile, phases and joints annotated.
- `pov_100m_before_entry.png`, `pov_050m_before_entry.png`,
  `pov_020m_before_entry.png`, `pov_005m_before_entry.png` —
  seated-anchor approach frames, panels as driven.
- `pov_005m_before_entry_nopanels.png` — same station, boards
  hidden: the ring and descent as they actually present.
- `aim_ring_centre_from_5m.png` — free camera at the eye aimed at
  the ring centre (caught the car from behind; shows the spur
  complex's stilts/descent from outside).
- `aim_45left_from_5m.png` — free camera 45° left of heading.

Caveats: POV frames are the desktop fallback camera at the anchor
(75° FOV), the project's standing from-the-seat proxy — not a
headset capture. All geometry numbers are from the shipped build's
own arrays, not a re-derivation.
