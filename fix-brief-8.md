# Fix Brief 8 — Stunt Car Racer VR, Test 1 (Fix Pass 8)

Base: commit 1e96552 (master, remote-verified). Source: Chris's run 8
report (2026-10-26 19:42 CDT, with his 46 s capture): (1) "it really frame
jumps in certain spots" — and his DIAG reads JIT OFF for the whole
captured drive, so the jitter mechanism is EXONERATED as the primary
cause; leave it alone except where item 1's sampling change touches it.
(2) "I'm not getting any air on the little hills" — the crest straight
compresses (0.162 m peak, stage 8) but never unloads. Repo rules: never
commit `*.uid` or `game/tests/*.png.import`; ONE commit; push to origin
master (repo's configured sshCommand) and verify ls-remote == new HEAD.

## Item 1 — Kill the frame steps (MEASURE FIRST)

The diagnosis is part of the deliverable; do not fix on a guess.

1. **Instrument a full lap.** Autopilot drive logging, per physics frame:
   body/view vertical position and pitch, their per-frame deltas, the
   s-position, and frame time (ms). Deliver a top-10 table of the largest
   view steps OUTSIDE genuine events (gap flight, staged landings, Drop
   Start): s-position + magnitude + whether the step correlates with a
   long frame (a hitch) or with a place (a mechanism).
2. **Suspects to test against that data:** (a) the suspension's 1 m
   sample grid stepping its target heights on slopes; (b) the staircase's
   six hard height discontinuities; (c) facet kinks where the crest-
   straight profile joins segments.
3. **Fix what the data indicts.** Expected shape of the fix: continuous
   (interpolated) suspension sampling of the road profile at the axle
   positions instead of grid-stepped targets; staircase tread edges given
   short ramp transitions (the staircase must still READ as steps under
   the wheels — repeated distinct compressions — without a view snap);
   profile joins smoothed where they kink. If the data indicts something
   else, fix that and say what it was.
4. **Success metric:** re-run the instrumented lap; report the before/
   after top-10 table. Outside genuine events, per-frame view steps must
   fall to a small continuous bound (state the bound you achieve). Run
   the measurement with JIT OFF (Chris's condition); then confirm the
   jitter stage (2g band) still passes with JIT ON after the sampling
   change — re-derive its numbers honestly if they moved, with reasons.

## Item 2 — Real air on the little hills

1. **Reshape the crests into true humps.** The crest straight's hills get
   curvature that unloads the car at cruise: the road must fall away
   faster than the car's ballistic path (v²κ > g at a stated cruise
   speed — pick the speed the stage will drive, e.g. ~24 m/s, and show
   the arithmetic). Shorter wavelength / more amplitude than the current
   gentle rollers; landing zones stay sane and the sweeper entry is not
   compromised. The mesh and the profile change together here — these
   hills are SUPPOSED to look like humps (Crammond's Hump Back energy,
   not a rollercoaster rail).
2. **Rework the rebound-air gate.** Fix Pass 5's >0.19 m peak-compression
   prerequisite is the wrong rule for road-falls-away air: it demands a
   stored-energy history that geometry-driven unloading never has. New
   rule: airborne when wheel load reaches ≈0 at both axles BECAUSE the
   surface falls away (load computed from geometry/speed), sustained for
   a few frames. Preserve the climb-top protection by its actual
   mechanism — there the load is partial (~27%) and sustained, never
   ≈0, so the wheels stay planted WITHOUT any compression-history gate.
   If the new rule needs a discriminator beyond load level/duration,
   find the honest one and document it in code. Remove or repurpose the
   old gate; do not leave two rules fighting.
3. **Assertions:** (a) at the stated cruise speed over the crest
   straight, the car is airborne (both axles unloaded, AIR state) for a
   measured total across the humps — report the number; (b) no ground
   steering authority during that window (the existing light-steering
   behaviour, asserted); (c) the landing after a hump flight grades
   normally; (d) NEGATIVE CONTROL: no airborne at the big climb's top
   crest at cruise (the case the old gate existed for); (e) the two gap
   flights and all prior stages pass, re-derived honestly where the
   reshaped profile moves them.

## Verification (all required)
- Clean headless import, exit 0, zero script errors; GDScript preflight
  audit; API-surface guard (extend for any new live-path calls).
- Full smoke green incl. the new step-table and air stages; render
  proofs refreshed (incl. one frame over a hump at the moment of unload
  if capturable, and the staircase). Frame stats.
- No new user commands; panel/README change only if behaviour notes need
  it (the humps' reshaping is worth one README line).
- Report per prior passes, ending with what Chris is judging on run 9.
  All feel — smoothness and air above all — is UNVERIFIED until his
  headset says so.
