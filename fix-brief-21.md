# Fix Pass 21 — AIR (feel pass)

Ordered by the owner (Jaklar), Thu 2026-10-29 17:56–17:58 CDT,
from his run-18 feel report: "im just not getting the air I feel
i should be getting, I come out of turn and hit the little inside
flair and I expect those left wheels to catch some air. This is
really apparent at the hills, where the car feels like it wants
to stick to road instead of bounce." Yardstick (owner,
2026-10-26): "you get a lot of air in original game just
bouncing." Base: master @ FP20 final (dispatch chains to FP20).

## Conviction first (instrument, then touch)

Stage the owner's two scenarios on the CURRENT build and print
the load traces before changing anything:
(a) TURN-EXIT INSIDE FLAIR — the banked sweeper exit at cruise:
    per-corner load (or its per-axle proxy) across the lip.
(b) CRESTS — the climb-top crest and the hump country at cruise
    and at top speed: load trace + whether separation occurs.
Expected conviction from the record: FP5's air routes (deep-hit
rebound; crest load ≈ 0 at BOTH axles, with the peak-compression
gate installed for the 27%-sustained case) cannot see a one-side
unload and never open at mid-band crest load, so the car is
carried down falling profiles. Print what the traces actually
say; if they acquit the gates, the brief's fix shape is wrong
and the README says so instead.

## Item 1 — Per-wheel load

Replace the per-axle crest-load scalar with per-wheel load
sampling (each corner samples the ribbon at its own contact
patch: height + curvature), feeding suspension, grip and the
view exactly as the per-axle value does today. This is the
extension identified in FP14; it unlocks asymmetric unload
(downhill/inside side first, per the film study).

## Item 2 — Separation by physics, not gates

A wheel is airborne when the road falls away faster than the
car's ballistic arc at that corner — separation emerges from
the profile-vs-trajectory comparison, not from load thresholds.
Keep FP5's rebound-energy route for bounce-air off hits; remove
or subordinate any gate that can keep a separating wheel glued.
Guards: flat ribbon stays DEAD STEADY (film study rule 1 — zero
bounce on flat); no manufactured yaw wobble; the FP14 rebound
and one-bounce settle survive; drops/crane unaffected.

## Staged acceptance (owner's scenarios, in his terms)

- Inside flair: the inside wheels record airborne frames > 0
  crossing the lip at cruise while the outside wheels stay
  loaded; the car does NOT fully leave (it is a two-wheel
  event).
- Crests: at cruise and at top speed the load trace reaches
  zero and the car flies — flight times on the hump country
  counted in the 0.1–0.4 s drumbeat band (FP14 item 4's
  unmet target; count honestly, whatever the count is).
- Census: flat/straight stages frame-identical or every delta
  enumerated; R30 grip baselines (FP9/FP14) re-measured and
  reported, not assumed.

## Standing constraints

Drive numbers MAY move in this pass under the FP14 precedent —
every moved number reported with before/after and its reason;
lock behaviour ≤24 m/s reported explicitly. No `*.uid` /
`*.png.import` commits; ClassDB guard green; all prior stages
re-pass or are amended-and-flagged. README results section:
the conviction traces, what changed, the scenario evidence,
tallies, and a "What you're judging" summary (the flair, the
hills, rebound/settle regression-watch; sections/envelope/loop
deliberately NOT in this pass).
