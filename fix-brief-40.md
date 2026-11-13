# FIX PASS 40 — THE PHYSICS PASS (as built)

Owner's GO: 2026-11-03. Base: master `2e836c4` (FP39).
BUILD_STAMP: "FP40 · 2026-11-03".

## Item 1 — warp-through fix

- **Audit verdict**: staged ballistic arrivals NEVER warp (flat
  falls to −38 m/s, circuit faces/crests/dive — all landed; max
  honest tick drop 0.45 m vs a 2.6 m window at 90 Hz: frame-step
  tunnelling REFUTED). The warp is a **micro-hop storm** on steep
  fast descents: after the Escalator crest-off flight lands at
  T13's head (−15°, −26° bank), the car re-lands every ~0.5 m,
  each graded HARD at the road's own fall rate (vy read 4→10),
  springs slamming, height-over-road ratcheting 0.43 → 0.16 m —
  the car rides buried in the ribbon. Mechanism: `_land` graded
  `air_vel.y` in world axes; a flight's vy is born as the
  slope-following component (≈ −11 m/s on that descent), so
  gentle re-contacts graded as ~10 m/s slams.
- **Fix**: (a) road-relative arrival — `_slope_vy_at()` (the
  `_enter_air` composition, factored out); the landing test's
  bound and `_land`'s severity read `slope_vy − air_vel.y`.
  Bit-identical on flat (stage 61 unmoved). Rising faces grade
  harder than world (honest face-slam). (b) swept contact in
  `_update_air` (prev-tick h history; land at the interpolated
  crossing), BOUNDED to a 1.2 m step — the unbounded form
  "rescued" debug teleports (stage 49 convicted it); all direct
  AIR entries (debug_stage_landing, debug_force_fall_at) now
  reset the sweep history like `_enter_air`/`_do_release`.
- **Proof**: sweep re-run all landed; storm fixture (stage 68):
  1 touchdown, 0 HARD, min heave +0.077, +0 dents (pre-fix
  ~30 TDs/20 m, mostly HARD, heave ratcheting to −0.18).

## Item 2 — gearbox

4 ratios, automatic, no new command. Bands/forces (bottom →
top with the 0.25 band fade): 1st 0–11 @ 22.0, 2nd 11–19 @
19.0, 3rd 19–33 @ 15.5, 4th 33–48 @ 12.0. Shift = 0.13 s
engine gap + gear_rev drop (audio reads gear_rev; DIAG shows
GEAR). Downshift hysteresis 1.5 m/s. Boost +16 after the box,
spin-exempt as ever.
- Floored: spin peak 1.00 (FP36 0.72), 0.84 @ 8 m/s, hooked
  0.02 @ 20; drop-start spin 0.83 (was 0.34). Feather 0.45
  never spins; 0.65 spins, hooks by 8 (0.07).
- Times (circuit opening): 0–30 2.31 → 2.86 s; 0–45 3.54 →
  5.13 s; 0–48 ≈ 5.76 s; top 48 unchanged. Boosted 0–30 1.21 s.
- Corner spread (stage 65, frozen wheel): 5.11 → 4.62 m,
  still > 3.0, both runs on the road.
- Stage 26 fixture convicted en route: its brake-stop never
  closed the throttle, so the stop depended on the leftover
  test_throttle from the lap stages — at the gearbox's pace
  the leftover was 1.0, engine and brake cruised at ~14 m/s,
  and the "standing start" began rolling at s 141 (brow at
  41.4). The fixture now stages both pedals and requires a
  grounded stop (`speed` freezes airborne — a hop must not
  read as stopped). Bands re-derived in place; stage 68's
  gearbox stop carries the same staging.

## Item 3 — fishtail

Bleed's load factor × sqrt(1 − 0.75·rear_u²), rear_u = engine
demand / FP36 spin-test cap. Cruise ~0.95 (untouched),
corner demand ~0.79, floored 0.50. Throttle-regulated by
construction (lift → tax gone). The rate was sized by
measurement on both sides: 0.60 read +0.29° of slip at the
standard corner; 1.00 (the true circle) saturated the slip
state in the lab's off-camber S (stage 58 P5: slip 0.47 →
1.00, |lat| 1.49 → 6.14, off the road) — past "a little"
and destabilising. At 0.75: P5 slip 0.55 / |lat| 1.65, and
stage 68's standard corner reads lift 1.76° → full 2.09°
of slip. Stage 65's drumbeat authority with it live:
−3.61° (FP36: −3.6°) — unmoved (that fixture is at closed
throttle; the tax is demand-driven).

## Item 4 — landing costs

Retention in `_land` on the forward component, after the
min-forward guarantee; drops exempt; payout untouched.
Curve: CLEAN clamp(1.02 − 0.006·vy, 0.90, 1.0); SCRUBBED
clamp(0.92 − 0.020·vy, 0.62, 0.88); CROSSED-UP clamp(0.78 −
0.022·vy, 0.30, 0.62); × clamp(1.05 − 0.006·misalign, 0.75,
1.0). Staged: CLEAN vy6 → 0.985; SCRUBBED vy9 → 0.734;
CROSSED vy9 → 0.575; CLEAN vy21 → 0.761; slam in stage 68.
Repricing (reported, not compensated): circuit income
174.8 → 185.1/lap; ribbon 104.2; starved 500 m unchanged.

## Gates

Preflight import + quit-after clean; full smoke **ALL 781**,
ClassDB guard **ALL 71** on the shipped tree. Render proof
part-ran in the sandbox (43 checks in ~25 min under load;
the only failure the standing wheel-hub reach artifact,
0.31 m below the eye, unchanged since FP31; no seat/wheel
geometry touched) — captures in the commit remain the FP39
set, per the FP37 precedent. No *.uid / *.png.import in
the commit (zz probes deleted).
