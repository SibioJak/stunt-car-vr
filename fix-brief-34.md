# Fix Pass 34 — Nothing Moves the View but the Driver

Base: FP33 final (50e960c). Owner's GO 2026-11-01 ("Get the rear in
gear"). BUILD_STAMP updates to "FP34 · 2026-11-01" per the FP33 ritual.

## The conviction

Field video + code trace, 2026-11-01: pressing TRK yawed the view
~15–20° and it stayed yawed. Chain: `_cycle_track` → `_set_track` →
`start_race()` → `_arm_anchor()` (non-explicit). Every race start
re-arms the cockpit anchor; the non-explicit arm still landed with
FP11's 25° yaw cone, so a head turned toward the dash at press time
baked part of its yaw as the new forward. Second defect, spotted by
the owner from the seat: the both-grips squeeze is an FP11 recenter
gesture (explicit bake) — the same gesture as two-handed steering.
Its gate (`_recenter_allowed`) had a same-frame hole: both hands
landing on the wheel together could edge-fire the recenter before
`grab_hand` was set. The owner's deliberate recenter is the LEFT
STICK CLICK, which never consults that gate.

## Item 1 — Position-only restarts

A non-explicit anchor arm (race start, track change, any
`start_race` caller) re-seats the eye's POSITION (and height) only:
the yaw reference is preserved EXACTLY (applied origin yaw delta
== 0.0 in staging, with the simulated head yawed ±20° at arm time).
The explicit recenter keeps the full bake semantics, unchanged.
Implement the split on the existing bake flag's semantics — do not
fork a parallel anchor system. Enumerate the `start_race` callers
in the README.

## Item 2 — The both-grips recenter dies

Remove the `both_grips` edge → `_recenter` path and
`_recenter_allowed()` with it (grep-clean: no orphan references).
The left stick click recenter remains, byte-identical behaviour,
now the ONLY recenter. Update the in-game commands list and README
controls (the both-grips line is deleted — every listed command
must be real, and every real command listed).

## Item 3 — The neighbour audit

The owner's original report: TRK shifts the view slightly, "the one
next to it is even worse." Identify the dash controls physically
adjacent to TRK (the purple button), trace each one's full fire
path for anything that can touch the anchor, the origin, or the
view. Bring any offender under the FP34 law (no dash control may
rotate the view; restarts are position-only anyway under Item 1).
Report in the README: the neighbour's identity, its path, and its
disposition. If the neighbour proves innocent of the anchor and its
"worse" shift has another mechanism, name that mechanism with
evidence — do not leave it unexplained.

## Item 4 — Proof

New stage(s): (a) restart with head yawed +20° and −20° → origin
yaw delta 0.000, position re-seated (assert both); (b) explicit
stick-click recenter with head yawed → bakes as before (control);
(c) both grips squeezed from a no-hands state in DRIVE and in AIR,
same frame → no recenter event, anchor state untouched (negative
control); (d) TRK press path end-to-end → start_race runs, anchor
arms position-only. Census: enumerate every stage whose
expectations touch anchor yaw on restart — re-derive and flag
each; everything else byte-identical.

Standard gates: godot_gdscript_preflight audit, parse
warnings-as-errors, ClassDB XR guard, full smoke suite, render
proof. No *.uid / *.png.import in the commit.

## Results (as built)

- Smoke ALL 661 (642 + 19 net), API guard ALL 71, zero engine
  errors. Render proof 172/173 — the one failure is the
  pre-existing sandbox hub-reach artifact, identical on the
  FP31–FP33 baselines.
- Item 1: `_apply_seat_anchor(false)` lands translation with an
  IDENTITY basis; the cone constant, `anchor_yaw_pending`, and the
  deferred-yaw watch are deleted whole. Stage 63: yaw delta
  0.0000 rad at head ±20°, eye re-seated err 0.000 m.
- Item 2: gate and gesture deleted, grep-clean; panel reads
  "Recenter: L stick click"; stick click is the only recenter.
- Item 3: the neighbour is RESTART (red, x 0.40 — TRK's only
  dash-top neighbour at x 0.57). Its path is `start_race()`
  directly — the same bake mechanism, "even worse" consistent with
  a longer look at the button from deeper inside the old cone.
  Brought under the law by Item 1. VIEW (gain only), SIDE (mirror
  only) and DROP (`_do_release`, no anchor contact) traced clean.
- `start_race` callers: `_set_track`; Y button (hang long-press /
  drive edge); desktop R; `_activate_dash_ctl("restart")`.
- Census exceptions (all flagged in place): stage 22(c) re-derived
  (2 cone checks → 5 exact-preservation checks); stage 32's two
  gate checks → two behavioural squeeze controls; stage 62 stamp
  string FP33 → FP34; stage 63 new (+16). Everything else
  byte-identical to the FP33 baseline, check name for check name.
