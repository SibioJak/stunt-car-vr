# Fix Pass 10 — levers (left grip), drone logic + pivot flight, 12 m width, the MOUNTAIN CIRCUIT, loop spur

Base: ac8e6fe (master). Owner's word: "Greenlit" (2026-10-27) on the full load.
Owner verdicts driving this pass (run 10): steering LANDED ("a lot better, more squirrely,
harder to control" — do not soften it); levers 1-of-3 (video forensics: the LEFT grip
channel reads 0.00 on every channel in every frame of a full capture while R cycles to
1.00 — the signal never arrives); drone drops are stupid (in front of jumps; AHEAD of the
fall = free progress); track still reads tight for TWO cars (road-to-BODY is the measure
that matters for the sumo game: Crammond's was ~4.74× body, ours is ~4.25×).

SEQUENCE: items 0–2 first, proven on the EXISTING ribbon (its staged geography is the
regression baseline). Then item 3 (circuit) with items 0–2 re-verified on it, then item 4
(loop spur — the experimental item; if it blocks beyond reasonable effort, ship 0–3 and
report item 4 blocked with the mechanism. Do not let the experiment sink the pass.)
Commit locally per item group; push everything to master at the end.

## Item 0 — Levers: the left grip channel is dead live

- Audit `game/openxr_action_map.tres` (and the action setup in code) for left/right
  asymmetry on the grip actions (squeeze value / click / force). The working hypothesis:
  one hand's bindings are missing, mis-pathed (wrong `/user/hand/...` user path), or named
  differently from what Virtual Desktop emits. Repair to canonical, SYMMETRIC OpenXR
  bindings for both hands.
- ALSO make the game robust to a one-channel-dead world: activation must not depend on a
  specific hand (it already isn't in logic — the geometry is the risk). Verify from the
  anchored seat that ONE hand (either) can physically reach all three dash controls'
  activation segments; if a control is unreachable one-handed, say so in the report and
  adjust zone geometry minimally (do not move the dash).
- ADD A STATIC GUARD to the API-surface test suite: parse the action map resource and
  ASSERT per-hand binding symmetry for every action used by the game (grip, trigger,
  primary click, stick). This class of failure (one-sided binding shipping silently) must
  become unshippable.
- DIAG: add a per-control line showing, for each dash control, whether either hand is
  currently IN ZONE (and which), so the owner's next capture self-diagnoses.
- Stage 11 (production grip path) must now also cover: a simulated DEAD left channel —
  full prep completed right-hand-only — and a simulated dead right channel, left-hand-only.

## Item 1 — Drone placement logic (track awareness)

Owner's rules, verbatim intent: never drop in front of a jump; never drop ahead of the fall.
- The drop target s may NEVER exceed the s at which the car left the road (for Drop Start,
  the gantry). "Left the road" = the s where support was lost (fall start), captured at
  fall detection — not where the car ended up after tumbling/sliding.
- Walk BACK from that s to the nearest valid drop piece: flat and straight (no bank, no
  crest/hump, no staircase, no lip), AND with at least DROP_MIN_RUNUP_M (name the constant;
  start at 25 m) of hazard-free road ahead of the drop point before the next feature
  (gap lip, hump, staircase, steep section, sharp bank entry).
- On the circuit (item 3) all of this wraps across the start/finish seam correctly.
- Drop Start placement obeys the same validity rule (the gantry piece qualifies by
  construction — assert it).
- Assertions (staged falls): just past gap 1, just past gap 2, mid-banked-corner, one car
  length before hump 1, ON the staircase, and (circuit) just before the circuit's gap and
  just after crossing the seam. Every case: drop_s ≤ fall_s; drop piece flat/straight;
  run-up ≥ DROP_MIN_RUNUP_M.

## Item 2 — Pivot-driven drone flight

Implement the filed principle (owner's question, 2026-10-27: drone motion must DRIVE the
car's swing, not decorate it):
- The carrier (drone) has real flight state: it accelerates, cruises, turns, and dips
  between the pickup point and the drop point (path may curve; respect the desert/track
  space — no flying through the ribbon).
- The car hangs from the carrier's pivot: its swing (both pendulum axes) is INTEGRATED
  FROM PIVOT ACCELERATION (lag on acceleration, overshoot on deceleration/turns, settle
  when the carrier holds station). Drone yaw turns twist the car after them with lag —
  alignment is a TARGET with a slow seek, never a rigid lock.
- Line tension from carrier height changes: dips ease tension (short free-fall feel),
  climbs catch. The existing release gates do not change: prep complete + swing settled
  (pendulum energy under the existing threshold) + near-zero bank to release.
- Keep the standing numbers as starting points where they still make sense (pendulum
  lengths 5.5/3.9 m etc.) but the DRIVER of the swing is now the pivot, not a procedural
  schedule. Retire/replace the hash dip schedule honestly: dips happen because the
  carrier's path dips.
- Assertions: swing phase measurably lags carrier turn/accel inputs; injected carrier
  turn produces car yaw overshoot then settle; a calm straight carrier flight produces a
  calm hang (pendulum energy below release threshold without procedural help); Drop Start
  hang (carrier holding station) unchanged in character.

## Item 3 — The mountain circuit + 12 m width

- WIDTH FIRST (applies to everything, ribbon included): HALF_WIDTH 4.68 → 6.0 (12.0 m
  full). MEASURE the car's body width (widest body extent) and report road width in
  bodies alongside metres. All derived values (edge straddle distances, fall thresholds,
  stilts, skirts) follow and are re-derived/verified, as in FP6/FP9.
- NEW TRACK: a CLOSED circuit, 2.8–3.4 km, built from the existing generator vocabulary
  with EXACT closure (total heading change 360°, elevation returns to the gantry datum;
  the seam must be invisible in the per-frame step metrics — same bounds class as FP8's
  post-fix numbers, measured ACROSS the seam too).
- Owner's geography, in his words: "huge tall ramps, massive dips, big swinging curves,
  some straightaways." Concretely: one signature climb of at least +60 m; one massive dip
  (a descent giving back at least 45 m into a valley, then out); at least two long banked
  swinging curves, one left and one right, generous radius; at least two straightaways of
  ≥350 m; PLUS continuity vocabulary carried from the test ribbon — one 14 m gap and the
  five-hump row (same specs as FP7/FP8) — so prior feel verdicts transfer.
- LAP LOGIC: the gantry is a lap line. Crossing it in DRIVE increments the lap; a race is
  3 laps → finish state (then free-run continues or restart offered as today). Drop Start
  hangs at the gantry. Drone walk-back (item 1) wraps the seam.
- TRACK SELECTION: the circuit is the DEFAULT track. The existing test ribbon stays
  selectable (panel command + key) as "TEST RIBBON" so every historical smoke stage keeps
  its geography; the in-game controls list gains the track toggle in the same commit
  (house rule: the list names EVERY command).
- Smoke: all existing stages run on the ribbon unchanged; NEW stages assert the circuit:
  full autopilot lap(s) to the 3-lap finish, closure/seam step bounds, staged falls under
  item 1 rules, hump air + gap on the circuit geography.
- Perf discipline: report node/draw-call/primitive counts for the circuit scene; keep the
  FP9 budget class (desert world already proved net-negative is possible — be as frugal).

## Item 4 — The loop spur (EXPERIMENT — owner's ask: "see if its possible")

Settled design item #13 (loops "if they work") gets its verdict experiment:
- On the circuit's longest straightaway: an off-ramp diverges, runs out to a VERTICAL
  RING (radius ≈ 11 m, same 12 m road width), and an exit ramp merges back onto the
  straight ≥120 m downstream of the entry. This is the game's first track branch: the
  active frame switches to the spur while the car is on it and back at the merge; lap/s
  accounting must stay sane (the spur is optional distance: taking it must not break lap
  timing or the drone rules — drone service on the spur returns the car to the MAIN track
  under item 1's walk-back rule).
- Physics HONEST, no glue: the existing load model decides. At the ring's top, load =
  v²κ − g·(surface-normal gravity component); below ≈ √(gR) ≈ 10.4 m/s at the top the car
  unloads, goes airborne under the existing air rules, and falls INSIDE the ring → off-road
  → drone. Entry speed is the skill (the straight + boost provide it). Do NOT add adhesion,
  magnetism, or scripted completion.
- The frame machinery must carry pitch through a full 360° without a flip/snap (orientation
  continuity asserted through the ring, sampled densely).
- Assertions: autopilot enters at 30 m/s → completes the ring, exits at the merge, lap
  continues; enters at ~16 m/s → detaches near the top, falls inside the ring, drone
  recovers to the main track; heading/frame continuity through the ring within step bounds.
- Proofs: renders of the spur from the straight (entry), trackside view of the ring with a
  car at the top, and the from-cockpit view mid-ring.

## House rules (unchanged, binding)

- Never commit `*.uid` or `game/tests/*.png.import`. Check `git status` before every commit.
- Controls list on the panel names EVERY command — any command added/changed updates the
  panel + README in the same commit.
- Audio teardown discipline untouched by this pass (no audio changes are in scope; do not
  regress the latch/watchdog/lease behaviour).
- Report honestly: measured numbers per item, any blocked item named with its mechanism,
  no invented fixes for anything not reproduced. Feel is the owner's verdict — report
  controls as UNVERIFIED until he runs it.
