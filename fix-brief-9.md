# Fix Brief 9 — Stunt Car Racer VR, Test 1 (Fix Pass 9)

Base: commit 505936a (master, remote-verified). Source: Chris's run 9
verdicts (Tue 2026-10-27 03:25–03:29 CDT). This pass replaces the driving
model's core; expect wholesale re-derivation of driving numbers and say
so in the report. Repo rules: never commit `*.uid` or
`game/tests/*.png.import`; ONE commit; push to origin master (repo's
configured sshCommand) and verify `git ls-remote origin master` == HEAD.

## Item 1 — Levers: level-based activation (the grip-order bug)

Run 9 evidence: Chris grips near a lever, the panel shows HOLD (grip
arrives, hand in range), and nothing flips. Mechanism: activation fires
on a fresh grip EDGE while in the zone — a natural hand squeezes FIRST
and reaches SECOND, spending the edge outside the zone. (Fix Pass 8's
stage 11 posed the hand first and gripped second — the inhuman order —
so it passed.) Fix:

- Dash-control activation becomes LEVEL-based inside the zone: while a
  hand is gripping (the existing multi-channel condition) AND inside a
  control's activation zone (the existing segment measure), the control
  fires ONCE per continuous grab-and-zone entry. It re-arms when the
  grip is released OR the hand leaves the zone. Both human orders must
  work. A held grip sweeping from one control's zone into another's
  fires the second on entry (squeeze-and-touch is the intended prep
  gesture). Wrong-order prep handling is unchanged.
- Stage 11 gains the missing sequences: (a) grip engaged OUTSIDE the
  zone, hand then moves in → flip fires; (b) held-grip sweep across two
  controls → each fires exactly once, in entry order; (c) the original
  pose-then-grip sequence and the three-dangle run still pass; (d) a
  held grip parked inside one zone fires it exactly once (no machine-gun).

## Item 2 — Free-heading driving model (the Autopia fix)

Chris: "I don't really have a sensation of the car turning, it more
slides… like the Autopia ride, riding a rail." Correct: the current
model slaves heading to the track frame and deflects the car laterally.
Replace the core:

- **Independent heading.** The car owns a yaw, integrated from steering:
  the grabbed wheel sets a front-wheel angle (named max-lock constant,
  authority scaled by speed), yaw rate follows with yaw inertia (a named
  constant — the car must feel massive, not twitchy). No rotation at a
  standstill beyond crawl-speed manoeuvre authority.
- **Velocity ≠ heading.** Velocity is its own vector (track-plane).
  Each step it decomposes against the heading into forward and lateral
  parts; tire grip bleeds the lateral part toward zero up to a lateral
  grip limit (named constants; the lean experiment's grip modifiers,
  ×1.28 / ×0.75, apply to this limit as they did to drift before).
  Demanding more than the limit leaves real slip: the car travels at an
  angle to where it points, recoverable by counter-steer. A front/rear
  grip split (bicycle-lite) is welcome if it stays a clean minimal
  model — no black boxes, every constant named and reported.
- **Slip becomes real.** `slip_state` derives from actual slip (lateral
  speed vs forward speed / demanded-vs-available lateral force), and the
  skid audio reads it as before — now honestly. Jitter isolation stands:
  slip ignores the quantised surface.
- **The track frame keeps only its proper jobs:** road height/bank under
  the car's wheels (wheel world positions from car pose, projected onto
  the spine), off-track/fall detection from (s, lat), gap spanning, lap
  and feature logic, drone/drop targeting. The car's (s, lat) derive
  from its world position each step; heading never comes from the frame.
- **Air discipline preserved:** no steering yaw authority while
  airborne (heading carries), landing grades/damage as before.
- **Everything above the model re-proves itself:** suspension + body
  spring, hump air (stage 10), gaps, staircase, jitter band (stage 2g),
  Drop Start, drone recovery, prep, engine/skid states. The smoke
  autopilot becomes a STEERING driver in test code (lookahead/pure-
  pursuit against the spine, feeding the production input path) — no
  self-drive mode ships in production code.
- **New model assertions:** (a) on the start straight at set speed, a
  held wheel angle makes heading diverge from frame heading by a stated
  threshold while the car is still on the ribbon (the car POINTS across
  the road); (b) a hard wheel flick at speed drives slip_state past the
  skid threshold with real lateral velocity, and centring the wheel lets
  grip recover (slip decays) — counter-steer shortens it; (c) the
  steering autopilot completes the full lap; (d) through the banked
  sweeper, heading vs frame heading diverge measurably (report typical
  values); (e) while airborne over a hump, steering input changes
  heading by ~nothing.
- **Scope addition (Chris, 2026-10-27 03:31 CDT) — the edge-straddle
  save.** Chris recalls the original's tires running off the ribbon
  edge: "they'd really wobble but you could save it and get back on
  track." The converted source confirms the mechanism (Car
  Behaviour.cpp, CalculateIfCarOffRoad, ~line 1294): each wheel's
  support height is independent; past the edge the road has "invisible
  sloping sides" — the wheel's height drops PROGRESSIVELY with
  overshoot (height -= x*16 + 0x100) — and only beyond 3/4 of the car
  width past the edge is that wheel fully unsupported
  (OFF_ROAD_HEIGHT). Whole-car recovery counting runs only when fully
  off-map and grounded, so straddling is a supported, recoverable
  state. Implement the equivalent in the new model:
  - Per-WHEEL support: each wheel's world position projects to the
    spine; a wheel beyond the ribbon edge gets a support height that
    falls progressively with its overshoot (named slope constant), up
    to a cutoff (named, on the order of 3/4 car width past the edge)
    where it is fully unsupported.
  - The corner's suspension responds to the dropped support (droop on
    that side, body roll toward the unsupported side — the wobble),
    and steering back onto the ribbon restores full support: a save.
  - Whole-car fall/recovery logic is unchanged in spirit: it engages
    only when support is truly gone, not at first edge contact.
  - Assertions: (a) a straddle drive at moderate overshoot — car stays
    supported, measurable roll toward the off side, no fall, and
    steering back restores full support (the save); (b) beyond the
    cutoff the car goes over and the normal fall/drone path engages;
    (c) symmetric on both edges.
  - The README gains a line on edge behaviour.

## Item 3 — Scale: Crammond-proportion road + a world to dwarf it

- **Measure, then set.** Report the build's front wheel track (wheel-to-
  wheel, metres). Set the road's full width to **6.0 × wheel track**
  (Crammond's proportion; expect ≈10.5–11 m) via HALF_WIDTH; everything
  derived follows (hang geometry, vents, off-line rules — audit the
  2.15× off-line multiplier at the new width and report what you set).
- **Desert world.** A vast flat desert floor far below the ribbon (set
  its depth so the ribbon's lowest sections still sit convincingly high
  — on the order of 50–70 m below the track datum), a ring of distant
  low hills (a few hundred metres out), flat-shaded, palette-consistent
  with the existing sky/fog; adjust fog so a horizon reads. A handful of
  large meshes only — report the frame-stat cost. The desert is scenery:
  the fall/recovery logic is untouched (recovery triggers exactly as
  now, far above the floor; the car never lands on the desert).
- **Proofs:** cockpit frame from the dangle (ribbon + desert + horizon),
  a looking-down-past-the-car dangle shot (the scale money shot), and a
  trackside wide shot. Frame stats for the whole scene.

## Verification (all required)
- Clean headless import, exit 0, zero script errors; GDScript preflight
  audit; API-surface guard (extend for any new live-path calls).
- Full smoke green incl. items 1–2's new stages; render proofs as above;
  driving numbers that moved are listed with reasons (expect many —
  this pass authorizes them; never tune backwards to preserve a number).
- No new user commands. README updated for the model change, the lever
  behaviour, and the new width/world.
- Report ends with what Chris is judging on run 10. All feel —
  turning above all — is UNVERIFIED until his headset says so.
