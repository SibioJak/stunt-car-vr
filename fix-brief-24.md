# Fix Pass 24 — Turbo Meter + Air Economy + Air Audit (+ smoke kill)

Commissioned by the owner (Jaklar), Fri 2026-10-30 09:18–09:26
CDT. The design of record is `~/workspace/stunt-car-vr/
boost-economy.md` — read it first; this brief is its build
order. Base: master @ FP23 final (dispatch chains to FP23).

## Item 1 — The economy (per the design note)

- Capacity 120 units, initial stock 60, drain 30/s unchanged;
  boost power (accel multiplier) NOT retuned.
- Payout on graded landings: air_seconds × grade_mult × 10
  units (CLEAN 1.0 / SCRUBBED 0.5 / CROSSED-UP 0.2); minimum
  payable flight 0.15 s; racing separations only — a payable
  flight begins as a separation from the road under power and
  ends in a graded on-road landing; crane-released falls and
  off-road landings pay 0; rebound second flights pay as their
  own landing. Payout clamps at capacity.
- The three dials (capacity, initial stock, rate P) are named
  constants at the top of the boost section — the owner's
  tuning surface.

## Item 2 — The meter

Dash bar in the button cluster, always visible (no panel):
fill = stock/capacity, bright at full, dark at empty; a payout
lands as a visible chunk + brief flash on the bar at the
moment the landing is graded. DIAG gains BOOST stock/cap and
LAST PAY lines (surface the ruling; the grab log records every
payout with flight time + grade).

## Item 3 — The air audit (track-design instrument)

A staged reference lap per track (circuit + ribbon) printing
the AIR GEOGRAPHY to the README results section: payable
air-seconds per 250 m sector, projected income per lap at the
shipped rate, longest air-starved stretch. Test-mode only; no
runtime cost in the shipped game. This map is a tracks-pass
design input.

## Item 4 — Kill the smoke blob (owner's tap, 09:26 CDT)

Delete the Test-1 smoke-puff sphere outright: mesh, trigger,
pulse, all of it (run-15 conviction; re-confirmed on run 19).
The nose-dent visual is separate and stays. Real smoke, if it
ever exists, belongs to the carnage build.

## Stages

Economy: staged flights of known duration/grade pay the exact
computed units; sub-0.15 s hops pay 0; crane-drop falls pay 0;
off-road landings pay 0; payout clamps at capacity; drain
unchanged; start stock = 60 on race start. Meter state staged
(fill fraction matches stock/capacity; payout flash state
set on a graded payout). Audit stage runs and prints both
tracks' maps. All prior stages re-pass; drive census
frame-identity OUTSIDE boost-active frames stated honestly
(boost behaviour itself only changes where the meter value
now persists/refills — enumerate any stage that assumed the
one-shot ration and flag amendments).

## Standing constraints

No `*.uid` / `*.png.import` commits. ClassDB guard green.
Commands list updated same-commit if descriptions change.
README results section: economy constants as shipped, audit
maps for both tracks, tallies, "What you're judging" (meter
readability at speed, payout feel, boost availability across a
lap; the smoke blob's absence; NOT in: inside-line/limit
earners, sections, envelope, loop).
