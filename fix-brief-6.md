# Fix Brief 6 — Stunt Car Racer VR, Test 1 (Fix Pass 6)

Base: commit db54be5 (master, remote-verified; includes the lean-gain trim
2.5 → 1.25 from run 6). Source: Chris's run 6 notes, 2026-10-26 18:28–18:34
CDT. Repo rules: never commit `*.uid` or `game/tests/*.png.import`; ONE
commit; push to origin master (repo's configured sshCommand) and verify
`git ls-remote origin master` == new HEAD.

## Item 1 — Driver-body seat spring (the "Star Wars effect")

Chris, run 6: suspension is "much better," but "whats missing in terms of
feeling is the sense of the player having weight in the car… when car hits
road and tires hit, player should feel like his view is also sinking down
within the seat" — "two different sensations at once."

Build a SECOND spring layer for the DRIVER'S BODY, distinct from the
car's suspension (Fix Pass 5's ViewSpring):
- New layer in the seat stack above ViewSpring (car → SeatOffset →
  ViewSpring → BodySpring → XROrigin; desktop fallback camera gets the
  same treatment). It moves ONLY the viewpoint rig — the cockpit does not
  move with it — so the eyes sink relative to the cockpit (dash/wheel
  appear to rise slightly around the view).
- Driven by the car's events: touchdown impulses (scaled by landing
  grade/impact), suspension bottoming, hard accel/brake (small fore-aft
  body pitch/slide against the harness), and the dangle's line-slack catch
  (a body thump into the seat when the lines catch).
- Character: SOFTER and LAGGIER than the car springs — lower natural
  frequency, its own damping — mostly vertical sink (order of a few cm at
  a hard landing) with a small pitch component. Its signature is PHASE:
  peak sink lands AFTER the car's peak compression, and it settles after
  the car does. Zero at rest; never writes the anchor.
- Named tuning constants (body spring stiffness/damping/depth cap), so
  run 7 can tune by number.

Smoke additions: staged touchdowns at two impact levels — assert (a) a
view-height dip relative to the car-spring-only trace, (b) its peak occurs
after the car springs' peak compression, (c) depth orders by impact,
(d) the offset returns to ~zero at rest.

## Item 2 — Road widened to 8 m

HALF_WIDTH 2.3 → **4.0** (full width 4.6 → 8.0 m) on the test track. Chris:
the original "gave you the sense the road was wide and massive… there was
room to manoeuvre," and he needs the width to properly test steering.
Everything derived from HALF_WIDTH (surface, skirts, edge strips, pylons,
banner, off-track and landing checks) must follow consistently. Re-derive
any width-dependent smoke expectations honestly and report changes (drift/
fall behaviour on the bank is the expected mover). Nothing else about the
track changes: same line, same gap, same bank profile.

## Item 3 — Engine + skid audio (the project's first audio)

Chris: "an engine and skid sfx would be helpful as well, to know when im
losing traction." Audio here is an INFORMATION channel:
- **Engine:** continuous synthesized note; pitch tracks speed (with load/
  boost colouring — e.g., pitch/timbre lift under boost), present while
  driving, changing honestly with state (airborne = revs unload).
- **Skid:** synthesized tire noise whose gain tracks the model's tire slip
  state — silent while gripping, rising as the tires approach and pass the
  grip limit (including lean-modified grip), silent while airborne. It
  must sound when the physics says slip, not on a steering-input proxy.
- Synthesized sources only (generated streams/buffers in code — no audio
  asset files). Conservative fixed levels. NO new user commands (panel
  text stays as-is).
- **Teardown discipline (STANDING RULE, non-negotiable):** audio is
  latched OFF on application focus-out and on exit (use Godot's
  focus/pause notifications), a lightweight watchdog cuts gains if the
  main loop stalls, and audio never starts before the player is in a run
  and never resumes uninvited after a latch. State the implementation in
  the report in those terms.
- Smoke: audio state machine checks headless where possible (skid gain
  ≈ 0 while gripping and airborne, > 0 under forced slip; engine pitch
  monotonic with speed; focus-out latch flips and silences). Sound QUALITY
  cannot be verified headless — say so; Chris's ears are the verdict.

## Item 4 — Uncross the lift wires

Chris's run-6 photo (looking up from the car): the drone's lift lines
CROSS each other (an X) between drone and car. Fix: during the hang the
drone holds its yaw aligned to the car's heading (it is a lift rig, not a
free quad), and lines pair drone-corner → corresponding car-corner, so no
pair of lines intersects in plan view at any point of the swing/dips.
Proof: a from-below render in the style of his photo (car below, drone
above, lines clean) + a geometric assertion sampling hang states
(segment-intersection test in plan view across the sample set = zero
crossings).

## Verification (all required)
- Clean headless import, exit 0, zero script errors; GDScript preflight
  audit on all changed code; API-surface guard (extend for any new
  live-path engine calls, incl. audio/notification APIs if used).
- Full smoke green with the new assertions above; report every changed
  legacy number with its reason.
- Render proofs: cockpit view (8 m road ahead), from-below wires proof,
  refreshed standard set. Frame stats.
- Report per prior passes, ending with what Chris is judging on run 7 —
  and the standing line that all live feel AND all sound quality are
  UNVERIFIED until his headset and ears say so.
