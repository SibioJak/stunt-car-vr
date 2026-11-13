# Tune Pass (Fix Pass 14) — The Hanging-On Tune

Dispatched by the owner (Jaklar), Wed 2026-10-28, at his "go."
Base: master @ 3ca7390 (FP13 final). Repo: SibioJak/stunt-car-vr, game/.

This pass has one customer: the feel verdicts. The owner, run 12:
"overall, the feel is starting to happen" at the edges — and "car
still overall, very light." The original's character, in his words:
"you always felt you were just barely hanging on, fighting to keep
control." The film study (research/original-feel-notes.md — read it,
§10 especially) measured where that character lives. This pass moves
those measured behaviours into our model. Every item is staged with
numbers; every number that changes gets reported with its reason.

AUTHORIZATION (FP5 precedent): this pass MAY change driving/suspension
numbers where an item demands it — report before/after for each. The
steering LOCK SCALE at ≤24 m/s stays bit-identical (stage 26 stays
green verbatim); grip/slide behaviour below is explicitly in scope.
FP13's stage 30 (touchdown spread) must be re-verified on the final
tree; rebound (Item 1) is gated by landing energy so near-zero-speed
drops keep FP13's staged behaviour.

Standing constraints: no `*.uid` / `*.png.import` commits; ClassDB
guard green; audio teardown untouched; panels list stays truthful.

---

## Item 1 — The rebound (mass suspect #1)

Film: every big jump lands and REBOUNDS into a second flight of
~½–⅔ the first (High Jump 1.93 s → ~0.6 s contact → 1.16 s). The
original NEVER sticks a big landing. Ours sticks.
- Above a landing-energy threshold (vertical impact speed — pick it
  from staged jumps and state it), the landing's stored suspension
  energy returns the car into a second flight; target rebound flight
  duration 0.4–0.75× the first flight on the staged cases (the 14 m
  gap at speed; a hump-row launch at 48 m/s).
- After the rebound: ONE bounce, settle, rolling — no third flight
  above noise on the staged cases.
- Below the threshold (drumbeat hops, Item 4; all drops — Item 6
  verifies), landings behave as they do today.
- Deliverable proof: a dense frame strip (≥10 fps sampling) of a gap
  landing showing flight → contact → flight → contact, plus the
  measured durations.

## Item 2 — One-bounce settle, everywhere

Film: suspension is stiff, heavily damped PD; at most ONE overshoot
after a disturbance; settles ~1 s.
- Stage a landing disturbance and a crest strike: spring compression
  trace shows ≤1 overshoot and settle (within noise band) in ~1 s.
  Report current behaviour first; tune damping/stiffness only as far
  as the trace demands. Do not soften the car into wallow — flat
  stays dead steady (Item 7's guard).

## Item 3 — Per-wheel travel independence in the view

Today the suspension is per-AXLE. Film is per-WHEEL: crossing a crest
edge, one side droops a full beat before the other.
- Move the suspension/view sampling to per-wheel (four corners),
  derived body attitude from the four corners (heave/pitch/roll).
- Stage: a diagonal crest-edge crossing — left and right compression
  traces show a real phase offset (>0, measured); a square crossing
  shows ~0 offset (negative control).
- The view must show it: crest-edge roll enters the seat stack via
  the existing view path, not a new camera trick.

## Item 4 — The crest drumbeat at 48 m/s

Film: small air 0.1–0.4 s is the drumbeat (12 hops in 25 s on one
stretch); off banked turns the unload is ASYMMETRIC — the downhill
side lets go first — rolling into exit-crest air.
- Run the crest straight + hump row at a pinned 48 m/s: count flights
  in the 0.1–0.4 s band and total air time; report before/after. If
  the drumbeat is absent or sparse at top speed, find the mechanism
  (load threshold? FP8's load-floor gate?) and fix the mechanism —
  no scripted hops.
- Banked-sweeper exit: stage the exit-crest unload and report
  per-side load traces; the downhill side must unload first. If the
  model can't express it, say so plainly instead of faking it.

## Item 5 — Per-wheel grip + persistent slides (the fight, spread inward)

The owner's mechanism (accepted into this pass's plan 2026-10-27):
Crammond's grip varies per wheel with per-wheel support; ours bleeds
lateral velocity too dependably, so slides self-resolve.
- Grip becomes a function of per-wheel load (Item 3's corners): an
  unloaded wheel contributes ~no grip; total lateral authority
  breathes with the road instead of being a constant.
- Lateral bleed becomes load-dependent: at full load it stays near
  today's dependable bite; as load falls, bleed falls with it, so a
  slide begun on a crest PERSISTS and demands counter-steer instead
  of healing itself.
- Stage against FP9's recorded baselines: the 20 m/s flick test
  (recovery 28 frames counter-steered / 59 centred on a FLAT road —
  flat-road behaviour should stay close to those numbers; the change
  must show up where load varies: flick at a crest, mid-corner
  unload). Report before/after per case. The R30 saturation honesty
  stays: the corner still can't be taken at 24.

## Item 6 — View coupling A/B: camera = car

Film: camera = car, zero lag/smoothing, 15 minutes of it. Ours
passes 0.6× of body pitch through a spring — a softening nobody
voted on. The owner's dip verdict: FAR-field blindness (honest pitch
coupling hiding the road beyond a crest) is the original's
difficulty engine and is to be PRESERVED, not cushioned.
- A DIAG-labelled toggle (button/key, named on the panel): A = the
  current 0.6× spring path; B = 1.0× pitch AND roll coupling with
  no added smoothing/lag beyond the seat stack's own motion.
- Default stays A on boot until the owner rules from the headset.
  Stage asserts both gains and B's added lag ≈ 0 frames.

## Item 7 — Guards (the tune must not manufacture the wrong life)

- FLAT = DEAD STEADY: 10 s on the home straight at 30 m/s, jitter
  OFF — view heave peak-to-peak stays in the low millimetres (FP7's
  OFF baseline: 0.6 mm). Jitter ON unchanged.
- YAW HONESTY: no yaw wobble is added anywhere. Heading trace on a
  straight shows no periodic yaw component; the flick/crest cases
  in Item 5 are the only new yaw behaviour, and they are
  load-driven, not oscillators.
- FLIGHT ATTITUDE: nose-down BUILDS through a long flight; landings
  slope-matched, nose-first. Stage the gap at speed: car pitch at
  contact within a few degrees of the landing slope. Report
  before/after; today the attitude is largely the launch attitude
  carried — if so, build the build-up.

## Item 8 — Hang checks (post-FP13 shape)

- Dangle sway irregularity: film sway is irregular/nudged (period
  ~1.5–2.5 s, never a clean sine). Measure the FP13 station dangle
  for 30 s: report the sway period's drift/variation. If it has
  locked into a clean periodic Lissajous, the honest nudge source
  is the drone itself: station-keeping corrections (small,
  irregular, hash-scheduled like FP5's dips) so the pivot breathes
  the way a holding drone does. No sine-shaping at the car.
- Short drop: measure release → contact time at the Drop Start.
  Film: ~0.3–0.4 s. If ours is materially longer, shorten the hang
  (station altitude) to land in ~0.3–0.5 s and re-run FP13's
  transport/station stages.

---

## Suites & delivery

- Smoke/API/proofs green on the final tree, grown with every stage
  named above; FP13 stages 28/30/31/32/34 re-verified (re-derived
  only with the change and its reason recorded).
- README: per-item report, before/after numbers for every changed
  constant, the rebound threshold, drumbeat counts, A/B assert
  results, hang measurements, brief mismatches, honest failures.
- Dense frame strips for the rebound and one crest-edge crossing.
- Per-item commits, push to origin master, tree clean, no sidecars.
