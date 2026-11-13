# Fix Pass 44 — LONG GEARS + THE PEEL-OUT

Ordered on the owner's FP42 verdict (2026-11-03): "Gear ratios
just aren't right. It runs through them too quickly, you reach
top speed too quickly and are usually left wanting for more.
An odd rod should always have more to give." Plus: "still not
feeling effect from rear tires, no peeling out sensation."
Base: master 44bf45e (FP43). BUILD_STAMP → "FP44 · 2026-11-03".

## Item 1 — LONG GEARS

The spread is rebuilt TALL. The law it serves, the owner's:
TOP SPEED IS A RESERVE, NOT A STATE — on flat ground at full
throttle the car is still pulling through every speed our
tracks use; the ceiling is reached only with help (a descent,
boost, or a genuinely long run). It interlocks with his
straights-are-breaths law (2026-11-03): tall gears + short
straights = never parked at the ceiling.

| | FP42 (before) | FP44 (after) |
|---|---|---|
| Gear top speeds (m/s) | 12.5 / 19 / 33 / 48 | 16 / 30 / 41 / 71 |
| Gear forces | 22 / 19 / 16.5 / 12.5 | 22 / 15 / 11 / 8.5 |
| Clamp (TOP_SPEED) | 48 | 71 (a reserve) |
| Shift points (staged) | ~1.9 / 3.1 / 4.6 s | 1.64 / 3.21 / 5.37 s |
| 0–30 m/s | 3.14 s | 3.20 s |
| 0–45 m/s | 5.40 s | 6.76 s |
| 0–48 m/s (the old ceiling) | 6.01 s | 7.63 s, in gear 4 at rev 0.23 |
| Time to top | 5.98 s to the 48 clamp | no flat-ground top: equilibrium ~67–68 |
| Staged lap vmax (Track 01) | 48.00 (the clamp) | 62.3 |
| **Time AT the ceiling, staged lap** | **10.74 s of 125.7 s** | **0.00 s** |

First gear is untouched at 22: the burnout and the 0.45
feather law survive by construction (0.45 × 22 = 9.9 < the
11.0 spin cap). The ceiling justification: top gear's faded
force (8.5 × 0.75 ≈ 6.4) meets the 0.10·vf drag at ~67–68 m/s
on the flat, so 71 is a true reserve — staged proofs: pinned
at 60 the car still pulls (62.15 after 2.25 s); pinned at 70
it falls AWAY from the clamp toward equilibrium (68.97 after
2.25 s); from 60, boost buys the ceiling back (70 in 0.62 s).
At the old 48 point the car is deep in top gear (rev 0.23)
still pulling +3.2 m/s². Kept whole: the 0.22 s shift gap,
the rev sag in the gap, automatic shifting, GEAR on DIAG,
boost = +16 after the box (still doubles the gear force's
share — staged boosted 0–30 in 1.26 s).

## Item 2 — THE PEEL-OUT, AS A SENSATION

FP42's spin was real in the model (peak 1.00) but no channel
reaching a seated driver carried it. The package is built
where the driver sits:

(a) AUDIO — a dedicated spin voice (660 Hz fundamental,
exact-cycle partials at 1.5×/2×/3× + high-passed shred noise),
keyed to wheelspin × rear load, peaking at −10 dB against the
engine's −17 dB song. Staged: gain peaks 1.00 in the burn,
0.003 one second after the hook. It obeys the standing audio
discipline (latched teardown incl. the stall watchdog,
silence-by-default). The skid voice's wheelspin component is
removed (flagged in place) — the skid is slip-only again; the
spin has its own voice now.

(b) SEAT — a spin-driven shudder through the body application
(8 Hz, ±6 mm vertical peak-to-peak 0.0119 m in the burn,
0.0001 m once hooked), synthesised on its own envelope so
FP32's sink law and FP42's pitch channel are untouched —
`body_sink` itself is never written with it (stage 2e reads
it directly and does not see it).

(c) YAW HUNT — while wheelspin > 0.35 under power with the
rear loaded, a 2.1 Hz yaw oscillation (0.38 rad/s amplitude)
the driver corrects with the wheel. Staged: heading wander
3.23° peak-to-peak in the burn, 0.18° after the hook, 0.000°
on a feathered launch. It is applied as an offset on the
frame's applied yaw only, never written into the yaw state —
a separation stores the wheel's yaw (stage 65's contract),
and the first form (adding it to the persistent state, which
the yaw lag then integrated ~6× to a 20.7° wander) was
convicted by its own probe and rebuilt before the suite
ever saw it.

No new driver command was added, so the commands list is
unchanged; DIAG already carries GEAR. Rear smoke emitters
left as they are (the package is a+b+c).

## Census — what held, what legitimately moved

Held (full suite): the loop window and crown
(held 18 CLEAN, floored exit 36.6, pin 16 off at the crown
approach), the helix hold (inverts fully, min up.y −1.00),
the wall-ride law, the FP39 storm law (1 touchdown, 0 HARD,
+0 dents), stage 9's geometry family, stage 65's
spin/hook/feather/boost numbers. The retention curve's LAW
is untouched and its fixtures pass in their FP42 bands —
but their point readings moved (1.000 / 0.631 / 0.446 /
0.228, crane 1.000) because the staged arrivals' tilts are
finally honest (5° / 11° / 11° / 27° against the stale
basis's 12° / 17° / 17° / 34°) — see fixture defect 3; the
FP42-era readings were taken through the same stale basis.

Moved, re-derived and flagged in place:
- Fishtail at the standard corner: peak 3.59° → 2.52°,
  sustained 2.09° → 1.76° (lift 0.37 unchanged). The corner
  is staged at ~18 m/s, which is second gear in both eras;
  FP44's fresh second (15) asks less of the rear than FP42's
  faded second did at that speed, so the tax bites less.
  The regulation law (sustained full > lift + 1.0 and > 1.5)
  holds with margin. TAX/FLOOR/CATCH constants untouched.
- Stage 26's two powertrain stations: its floored run now
  ends at the s 220 hump's flight (vmax 47.7 is an ARRIVAL
  speed — the old "≥47.9 = the clamp" check's premise is
  gone; the bound is now > 46 with past-48 given to stage
  71), and its engine-pitch stations move into third gear
  (31 / 40.5 m/s; read 0.99 / 2.39 against the formula's
  0.97 / 2.56 — the old 34/48 pair read 1.43 / 1.24, which
  matches the rev formula at the new bands to the digit).
- Stage 9's height tier 0.022 → 0.030: the long gears
  change the staged car's speed trace at the fixture's
  capped pace (still pulling in second through the corner
  unwind where FP42 cruised in third); worst step read
  0.0255 twice. One-variable proof: the same tree with
  FP43 constants reads 0.0175 (inside the old tier). Pitch
  and staircase tiers unmoved.
- Stages 2f / 65 / 68 bands that read the powertrain's
  signature (shift-drop pin, 0–30 and 0–45 windows) moved
  with the spread and are flagged at each check.

## Three fixture defects the pass caught (all flagged)

1. THE HANG WEDGE (stages 19/20/67/68/71 lap loops). At the
   raised pace the staged lap cranes once at the Dive exit
   (fall at s 1216, lat −7.96). The loops released the same
   frame the chains attached; an off-station release (FP22's
   any-phase ruling) drops the car where it hangs — still
   the fall site, off the edge — so it fell, was collected
   at the same site, and cycled forever (probe: 4 identical
   cycles). The loops now release at the dangle, the crane's
   arrival contract (stage 49's settle wait is the same
   idea). Production's any-phase release is untouched — a
   driver who drops at attach gets an honest fall, which is
   the FP22 ruling working as ruled.
2. STAGE 67's audit pace. The fairness audit's lap ran the
   raised envelope; its driver enters the Dive at ~62,
   cannot brake down the descent against gravity, flies the
   exit at 43 and lands in the off-camber S, crossing the
   Wall's foot still sliding (−7.64 m/s). At FP43 constants
   the same driver brakes to ~30 and walks the S (peak
   −3.45, damped); spin and hunt read 0.00 through the S on
   the FP44 tree — the car and the track are unchanged, the
   audit's pace was never 71. The audit lap now runs at its
   design pace (cap 48, J2 reads 0.02); the raised pace's
   lap is stage 71's interlock (completes, ceiling 0.00 s;
   cranes 0 on the green run — a prior run craned twice at
   the Dive exit and the dangle gate carried it home).
3. THE STALE TAKEOFF BASIS (stage 68's retention). Direct
   AIR entries (debug_stage_landing / debug_force_fall_at)
   never set air_basis0 — only _enter_air does — so staged
   landings flew and graded on whatever basis the suite's
   last real takeoff left behind (~7° off the ribbon's
   frame after FP44's reshuffle; every fixture graded
   SCRUBBED). It passed for years on that coincidence. Both
   helpers now record their staged basis (one line each,
   test-only paths); the fixtures then read their honest
   arrivals (lat spd 0.00 / 2.00 / 5.00 / 3.50, hdg err
   −0.00 across the board) and pass in their bands.
   Stage 68 also gains a
   printed account per staged landing (quality, lat spd,
   hdg err, retention) so a future move confesses itself.

## Economy repricing (report only — dials untouched)

Per the owner's 2026-11-02 ruling the payout dials are not
touched; the new pace reprices the offer on its own:
Track 01 projected income 181.3 → 187.0/lap (payable air
18.13 → 18.70 s, starved stretch unchanged at 500 m);
the ribbon 104.5 → 96.3/lap (payable air 11.66 s, starved
250 m). Stage 54's audit pins 24 m/s outside its gap
windows, so most of the move is gap-window driving at the
new pace.

## Gates

Preflight audit clean; parse clean; ClassDB API GUARD ALL
71; SMOKE ALL 832 (810 at FP43 + stage 71's 22 new checks);
render proof 172/173 (the standing sandbox wheel-hub reach
artifact only, identical on every baseline since FP31 —
captures via llvmpipe cannot settle it; the seat is the
verdict). No *.uid / *.png.import in the commit.

Stamp: FP44 · 2026-11-03. What the seat still owes: whether
the long pulls feel like an Odd Rod that always has more to
give, whether the peel-out package lands (the squeal over
the engine, the shudder through the seat, the hunt at the
wheel), and the carried-over FP43 verdicts (helix from the
seat, wall-ride, jump-ins) plus the loop's 16 m/s transient.
