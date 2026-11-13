# Fix Pass 32 — The Landing

**Chris's conviction (2026-10-31, from his lab-lap video):**
landings feel "flat and rigid when hitting road" — "isn't
sinking down." GO given 2026-11-01. Base: FP31 (1bc901d).

## The forensics behind the conviction

- Video frames at 8 fps show NO visible body sink at contact.
- The capture's audio level at every touchdown is
  indistinguishable from mid-flight (RMS ~1440–1485 vs
  ~1435–1463): there is NO landing sound at all.
- The model's facts: SUSP_TRAVEL is 0.34 m, but FP5's
  touchdown initialiser sets compression INSTANTLY as a
  state (c = SUSP_REST + vy × 0.045 × axle factors),
  SUSP_DAMP 11.0 kills the stroke fast, and the shipped
  seat gains tax the heave before the eye.

## Item 0 — Measure first, publish in the README

A staged probe reporting, for landings at several
severities (a drumbeat hop, a staged 1.2 s-class flight,
a hard crest landing): peak per-axle compression, time
from contact to peak compression, total sink visible at
the CAMERA, and settle duration — BEFORE (pristine FP31)
and AFTER. The after-numbers must show the sink as a
motion (time-to-peak in the 0.12–0.30 s band) and the
camera receiving ≥ 85% of the body sink in BOTH view
modes.

## Item 1 — Compression as a motion

Replace the instant-set touchdown initialisation: at
first contact the compression starts near the rolling
state and the impact drives the compression VELOCITY,
so the stroke develops over ~0.15–0.25 s, overshoots
ONCE, and settles in about a second (the film-study
law). Hard hits use meaningfully more of the 0.34 m
stroke. Per-axle sequencing preserved (a nose-first
landing sinks the front first). The rebound machinery's
contract survives intact: the gated return still fires
its second flight at ~0.43–0.57× the first on staged
big landings. The body_sink layer (BODY_K / BODY_DAMP
5.2) is the presentation ally, not a rival — reconcile,
don't stack two sinks fighting.

## Item 2 — The view channel

The landing sink reaches the eye at ≥ 85% in BOTH VIEW
A and VIEW B, implemented on the sink/body-heave
channel specifically; the global view-spring character
for ordinary driving is NOT retuned (A stays 0.6× for
the road-following layer). No camera shake, no added
lag: the sink the eye gets is the body's actual sink,
transmitted, not an effect layered on top.

## Item 3 — The contact sound

A landing thump scaled by impact severity (vertical
velocity at contact + compression rate), low-frequency
body, no tinny edge, routed through the existing audio
system with its teardown discipline untouched: drumbeat
hops earn small ticks, full flights earn the full
thump, CROSSED-UP/HARD landings the heaviest.
First-contact per-axle timing (a nose-first landing's
thump lands with the front). Measurably present: the
audio level in the 150 ms after contact exceeds the
in-flight bed by a clear margin (numbers reported like
Item 0). Existing layers unchanged in behaviour; the
thump ducks nothing and stacks cleanly.

## Census discipline

Landing initialisation feeds trajectories, so census
movement is expected — enumerate EVERY affected stage,
re-derive expectations from the new stroke law, flag
each in the README with before/after values. Touchdown
GRADE boundaries and boost payout amounts must not
shift silently: any staged grade or PAY change is
flagged in its own list with the reason. Standard
gates: preflight audit, parse warnings-as-errors,
ClassDB XR guard, full smoke, render proof. No *.uid /
*.png.import in the commit.

## Execution addendum (what the pass actually did)

- The instant set is deleted. `_land` now derives a
  per-axle compression VELOCITY from the impact
  (vy × LAND_CV_K 0.85, front bias 1.15 / rear 0.90 —
  FP5's own bias factors), delivered as a 25% bite at
  first touch with the rest feeding in over a 0.10 s
  load ramp (a one-frame velocity step peaked the
  stroke at 0.100 s at every severity; a linear
  system's peak time answers its input's shape). The
  arriving compression state is KEPT, and the
  placement continuity FP5 got from its set is
  re-derived analytically at the landing frame
  (heave/pitch from the arriving attach heights), so
  nothing teleports. LAND_CV_K was measured up in
  three steps (0.50 → 0.58 → 0.72 → 0.85) against real
  arrivals, not the staged probe alone: at 0.58 the
  Drop Start's droop arrival peaked 0.216 (4 mm under
  the rebound's deep-hit evidence) and the gated gap
  throw fired 2.37 against its 2.6 proof line; at 0.72
  the return crossed the fire travel too early in its
  velocity build (throw 1.19, snatched by the air
  window's vy < 0.5 bound on the way up, hop 0.029 m);
  at 0.85 the drop peaks 0.273, throws 1.36, hops
  0.067 m, and the gap throw clears its proof line.
- Body layer reconciled, not stacked: the old instant
  _body_impulse (which fired the sink from the SET
  value) is deleted and replaced by a landing FOLLOW —
  for 1.2 s after a landing, the body spring's rest
  point tracks the suspension's actual sink excursion
  at BODY_FOLLOW_K 0.22 (at most ~5.3 cm of added rest
  offset, inside the layer's own 5.5 cm cap), timed by
  construction to peak AFTER the car's own peak
  (stage 2e's phase law). The FP14 bottoming kick and
  the ordinary road-following rest point are untouched.
- View: no gain was retuned anywhere. The transmission
  was never short of travel (baseline 1.37–1.51) — it
  was short of TIME (the sink arrived in 1–3 frames).
  With the stroke a motion, the same channels carry it
  over ~0.13–0.25 s: measured transmission 1.44–1.48
  in both modes (= 1.00 placement + the shipped 0.35
  seat-heave gain + ~0.1 body follow at the camera
  minimum; FP32 adds no camera term of its own).
- Sound: a seventh voice family — two one-shot
  players (front/rear axle), a generated 52 Hz body +
  low-passed thock (0.45 s, seeded), fired per axle at
  the moment that axle's stroke crosses rest still
  compressing (true first-contact timing), severity =
  max(the landing's armed share, the axle's live
  compression rate), −23 dB (hop tick) to −4 dB (full
  thump) by sev^1.15. Armed at _land, expires unfired
  after 0.6 s. Inside the latch/watchdog discipline
  exactly like the loop voices; ducks nothing.
- New smoke stage 61 proves the stroke law, the
  transmission in both view modes, and the thump's
  severity ordering on staged arrivals. Stage 2c's
  touchdown checks are re-derived from the instant set
  to the stroke's peak (flagged in place), and stage
  29's fly_case fixture now cancels the landing ramp
  with the rest of the spring state (flagged in place —
  staged cold inside the previous case's 0.10 s
  delivery, the leftover velocity slammed the warped
  car low and fizzled the flight into a frame-1
  "landing"; warps are test-only, and a real landing's
  own _land always restarts its delivery).
- One rebound constant re-derived (flagged at the
  constant and in the README): REBOUND_DEEP_HIT
  0.22 → 0.20. FP14 set the stored-energy evidence
  line against the instant law's depths (a vy 4.1
  landing was SET to 0.285); the velocity stroke
  peaks that landing at 0.218, 2 mm under the line,
  and its return rang twice with no bounce — the
  first full run's one film-law failure. The line
  moves to where the energy now lives; the throw's
  other terms are untouched, and the isolation diff
  (stages 51/54/58 value-identical with and without)
  proves it added no throw anywhere else. Final
  tallies: smoke 636/636, API guard 71/71.
