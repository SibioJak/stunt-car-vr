# Fix Pass 20 — The Button (lever retired)

Ordered by the owner (Jaklar), Thu 2026-10-29 17:52 CDT, run 18 on
FP18: "Lever is still not consistent. why is a lever so hard? Im
sick of going round and round with the lever, make it a button
for now." FP19 (the lever's phase law) was killed mid-build on
this order; remote master never moved (7377bc3). Base: 7377bc3.

## Item 1 — The drop lever is retired; a button replaces it

- REMOVE the drop lever as the release control: mesh, grab zone,
  pull tracking, detent logic, DRP telemetry. (The seat-trim
  levers are a different family and stay.)
- DROP BUTTON: a large dash button in the lever's current spot
  (dash face; side follows the persisted lever/side setting and
  the SIDE control, semantics unchanged). It uses the existing
  dash-button mechanics: fat activation volume (0.15 class),
  physical dip on press, FP16 Schmitt latch hygiene, witness.
- Semantics (the owner's law applies to the button):
  - Press in ANY hang phase registers: dip + tick + log
    (BTN line, phase-tagged).
  - Press in DANGLE → release, downstream identical to the old
    lever fire.
  - Press in ATTACH/CARRY → felt refusal: grind rumble burst in
    the pressing hand (the grind floor), log BTN SPENT (phase).
    Chains hold.
  - Press in DRIVE/AIR → the button still answers (dip + dull
    tick, log phase-tagged); it does nothing. It never sits mute.
- Why a button (record, not decoration): a lever pull is a
  multi-sample act — zone entry, squeeze threshold, sustained
  grip, swept tracking through a throw — each sample a chance
  for the live grip/tracking stream to flicker, and staging's
  perfect 0/1 squeezes could never reproduce the failure. A
  button is a single threshold event in a fat zone: the one
  mechanism staging CAN certify honestly.

## Item 2 — Centre band OFF

The owner's run-18 verdict on the (finally visible) FP15 band:
"has one long stripe, not what I wanted. going down center."
Remove the continuous centre band from the surface build; the
grey field + dashed amber edges carry the road until the tracks
pass designs the sectioned markings he actually asked for.
Mesh-build change only; nothing else on the road moves.

## Item 3 — Backwards drop: diagnose, fix, instrument

Run-18 report: a crane recovery "dropped me backwards facing
wrong way on track." Staged census: force falls at
representative sections across the circuit's families (climb,
descent, straight/diagonal, banked), run the full recovery,
record RELEASE HEADING vs SECTION TRAVEL DIRECTION per case.
Convict the source (candidates: fall-time heading preserved
through the hang; section-direction lookup wrong for one
family; release re-based on the pendulum frame). Fix so release
heading matches travel direction within tolerance on every
family, stage-proven on the same census. EITHER WAY: add
release heading + section direction to the drop telemetry/DIAG
permanently — surface the ruling, so if it ever recurs his log
convicts it. If the census cannot reproduce it, say so in the
README and ship the instrumentation with items 1–2.

## Standing constraints

No drive numbers move. FP16/FP17 arbitration and thresholds
unchanged for surviving controls. In-game commands list updated
in the same commit (lever entries → the button). No
`*.uid` / `*.png.import` commits. ClassDB guard green; all prior
stages re-pass (staged expectations encoding the lever are
replaced by button expectations and flagged, not silently
edited). README results section with tallies and a
"What you're judging" summary.
