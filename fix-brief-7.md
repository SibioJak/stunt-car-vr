# Fix Brief 7 — Stunt Car Racer VR, Test 1 (Fix Pass 7)

Base: commit bd43f76 (master, remote-verified; Fix Pass 6 at 54626cb +
Crammond notes). Source: Chris's run 7 verdict ("much better", 2026-10-26
19:04 CDT), his request for a longer track ("it's awfully short"), and his
🟪 tap bundling the Crammond jitter mechanism into this pass. Read
`crammond-notes.md` (repo root) for the jitter mechanism evidence before
designing item 2. Repo rules: never commit `*.uid` or
`game/tests/*.png.import`; ONE commit; push to origin master (repo's
configured sshCommand) and verify `git ls-remote origin master` == new HEAD.

## Item 1 — Track extension (≈3× length)

The current lap stays BYTE-IDENTICAL through today's finish point (six
runs of verdicts compare against it). Past it, the ribbon continues:

1. **Crest straight** — a long straight carrying 3–4 rolling crests
   (bounce-air and body-spring country; also the jitter's home straight).
2. **Banked LEFT sweeper** — the bank machinery mirrored (the test track
   banks only right today; steering must be judgeable both ways).
3. **Descending staircase** — a stepped descent: a series of short drops,
   a suspension workout of repeated compressions.
4. **Second gap** — same spec as the first (14 m), no difficulty change.
5. **Final climb → long home straight → new finish.** Finish detection,
   banner/props, vents, and everything derived from the segment list
   follow the generator to the new end.

Road stays 8 m wide. Report the new total ribbon length and the smoke
drive's measured full-lap time (target ≈3 min). Every feature-referencing
smoke stage (climb heights, gap positions) is re-derived honestly if its
anchors moved, with reasons — the extension stages are new.

## Item 2 — The Crammond jitter mechanism (NOT authored noise)

Evidence (crammond-notes.md): the original's road profiles are smooth
analytic ramps; its tire jitter EMERGES from (a) faceted segments, (b)
road heights quantised to coarse steps, (c) few-point wheel sampling,
(d) a wheel response whose derivative term amplifies steps. The original
ALSO looked smooth — the roughness lives in the physics surface, not the
visible mesh. Reproduce that structure:

- **Quantised physics surface.** The suspension samples a quantised
  version of the road: heights snapped to a step at facet intervals along
  the track (named constants, e.g. `JITTER_FACET_M` along-track facet
  length, `JITTER_STEP_M` height snap; starting points ≈4–6 m facets,
  ≈2–3 cm steps — tune by measurement, below). The VISIBLE ribbon mesh
  does not change: it keeps the smooth profile. It looked smooth; it
  drove rough.
- **Emergence only.** The jitter must arise through the EXISTING
  suspension (its load/derivative response to the stepped surface). No
  camera shake, no view noise, no random offsets anywhere. If the current
  suspension filters the steps out entirely, adjust its response honestly
  and say so — do not bolt on a shake.
- **Skid stays truthful.** The slip_state / skid-audio path reads the
  UN-quantised surface (or an equivalently filtered load): jitter must not
  make the skid chatter. Same staged inputs → same slip readings as
  Fix Pass 6.
- **Landing/gap integrity.** Touchdown grades, gap detection, and the
  staged landing checks must behave as before (re-derive honestly if the
  quantisation moves a number; the gap span itself is un-quantised air).
- **In-headset A/B.** Jitter gets an experiment toggle like lean: R-stick
  click + "J" key, state shown in DIAG, DEFAULT ON, and — per the standing
  rule — the commands board and game/README.md gain the new command in
  this same pass.
- **Measured band.** Smoke additions: (a) at cruise on the flat start
  straight with jitter ON, per-axle suspension travel shows non-zero
  high-frequency variation inside a bounded band — target order 5–15 mm
  peak-to-peak; report the measured number (tune the constants to land in
  band; if the band proves wrong for the mechanism, report what the
  mechanism actually gives rather than forcing it); (b) NEGATIVE CONTROL:
  the same measurement with jitter OFF ≈ 0; (c) skid slip readings under
  staged inputs identical ON vs OFF; (d) staged landings/gap stages pass.

## Verification (all required)
- Clean headless import, exit 0, zero script errors; GDScript preflight
  audit; API-surface guard (extend for any new live-path calls, incl.
  the new input actions).
- Full smoke green incl. the new extension-lap and jitter stages; render
  proofs refreshed (incl. one frame down the new crest straight and one
  in the left sweeper); frame stats (expect node/primitive growth from
  the extension — report it).
- Report per prior passes, ending with what Chris is judging on run 8.
  All feel — jitter included — is UNVERIFIED until his headset says so.
