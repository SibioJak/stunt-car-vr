# Boost economy — design note (owner-commissioned, 2026-10-30)

Owner's commission (Fri 2026-10-30 09:18–09:22 CDT): a turbo
meter, a refresh scheme "based on getting some good air," and
an economy that "works on any track" — balancing track
distance, initial available turbo, drain rate, and air payout.
And: the economy's measurements "may actually use that info
to devise tracks." Status: DESIGNED, not built. Build = FP23,
chained behind FP22.

## Where the code stands today (measured, not remembered)

- `boost_meter` starts at 60.0 (reset at race start), drains
  at 30.0/s while boosting under throttle. In driver units:
  **the entire current ration is 2.0 seconds of boost per
  race, and nothing refills it.** The meter he asked for would
  today be a gauge on a one-shot resource.

## The economy (all quantities in boost-seconds; 30 units = 1 s)

- CAPACITY (the tank): 120 units = 4.0 s of boost.
- INITIAL STOCK: 60 units = 2.0 s (today's ration becomes the
  starting stake, not the whole game).
- DRAIN: 30 units/s while boosting — unchanged. The car's
  boost power (2× engine accel) is NOT retuned; this pass is
  the economy around it, not the engine.
- PAYOUT (the air exchange): on a graded landing, pay
  air_seconds × grade × P, with P = 10 units per air-second:
  CLEAN ×1.0, SCRUBBED ×0.5, CROSSED-UP ×0.2.
  - A solid 1.0 s flight, cleanly landed, pays 10 units =
    0.33 s of boost. A drumbeat 0.3 s hop pays 3 units.
  - Minimum payable flight: 0.15 s (texture hops pay nothing).
  - Only racing air pays: the flight must begin as a
    separation from the road under power and end in a graded
    on-road landing. Crane drops and off-road landings pay 0.
  - Rebound second flights are real air with real landings:
    they pay as their own landing, at their own shorter time.

## Balance (worked on the two real tracks)

- Circuit (3,319 m × 3 laps): staged air on the hump sector
  alone was 5.59 s at training pace; a full lap's payable air
  at race pace ≈ 6–10 s → income ≈ 50–80 units/lap (1.7–2.7 s
  of boost) against a free-spend appetite of 20–30 s of
  boostable straight per lap. Boost stays a decision: income
  covers roughly a quarter of appetite. Start poor, earn by
  flying, spend on the straights.
- Test ribbon (1,218 m): ~5.9 s air per 47 s lap → air-rich,
  income ≈ 55 units/lap. Correct behaviour: the ribbon is a
  bounce garden; the economy follows the track's character
  instead of a per-track table.

## "Works on any track" — the invariants

1. No per-track numbers anywhere: tank, stake, drain, exchange
   rate are properties of the CAR.
2. Income is keyed only to airtime × landing grade — both
   measured the same way on any ribbon.
3. The one track-dependent quantity (how much air a lap
   offers) is not tuned away; it is MEASURED and shown (the
   audit, below). A zero-air track makes boost a pure stake —
   visible at design time, fixed track-side, not economy-side.

## The air audit — the track-design instrument (his addition)

A staged reference lap per track that prints the AIR
GEOGRAPHY: payable air-seconds per 250 m sector, projected
income per lap at the current rate, and the longest
air-starved stretch. Tracks get devised in earn/spend rhythm:
air features are where the driver earns; long straights are
where he spends. The tracks pass uses the circuit's map as a
design input, and every future track gets audited before it
is declared done. (Lineage: the feasibility ghost — the same
idea pointed at income instead of landability.)

## The meter

Dash bar in the button cluster, always visible: fill = stock
vs capacity; a payout lands as a visible chunk + flash on the
bar the moment the landing is graded (surface the ruling).
DIAG gains BOOST stock/cap and last-payout lines. Full =
bright, empty = dark, readable in peripheral vision.

## Tuning dials left to the owner (by feel, after FP23)

Initial stock, capacity, and P. The structure (what pays, what
never pays, the invariants) is the design; the three numbers
are his to move after a race on it.
