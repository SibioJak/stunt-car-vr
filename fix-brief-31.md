# Fix Pass 31 — Nuke Lean

**Chris's order (2026-10-31):** "nuke lean and the blue lean
indicator." Whole mechanic, cleanly out. Context: lean (the green
dash button's ×1.25 body-lean toggle) went in before FP21's
per-corner load physics made load transfer real; Chris judges it
vestigial now, and a control that does ~nothing is the
decorative-control defect class. No A/B measurement — he has
decided. (Note: an earlier landing-feel proposal informally carried
the FP31 number in conversation; the lean order took the number.
The landing pass is un-ordered and will take a later number.)

## Scope (from the brief)

1. The lean INPUT: the green dash button (roster entry, arbitration
   candidacy, press handling, button MESH — no dead button left;
   the flask beside it does not move). Any keyboard twin or other
   binding of the same toggle.
2. The lean STATE and persistence: on/off state, persisted setting
   key, DIAG fields, commands-list/README mentions.
3. The lean EFFECT everywhere: model terms (load/grip/roll bias
   the ×1.25 feeds), body presentation, view/camera terms. After
   removal the car is everywhere in the former lean-OFF state.
4. THE BLUE LEAN INDICATOR: lean_needle (cyan, Color(0.2, 0.9,
   1.0)) — mesh and update path gone. Housing question answered
   during inventory: it had NO housing — a lone box on car_body —
   so the mesh alone was removed; report in README (done).
5. Grep-clean: no dangling references, no dead constants.

## Touchpoint inventory (found before deleting)

- Dash: green button mesh "LeanBtnMesh" at (-0.52, 0.95, -0.60),
  colour Color(0.15, 0.75, 0.3) (unique), registered kind "lean"
  (idx 1); `_activate_dash_ctl("lean")` → `_toggle_lean()`; DIAG
  short tag "lean": "LEAN"; ZONE row slot.
- Input: desktop T (toggle), Q/E (lean body) inside
  `_update_lean_reading`. No joypad binding existed.
- State: `lean_on`, `lean_neutral_x`, `lean_value`, `grip_mult`,
  `test_lean`, `lean_needle`; functions `_toggle_lean`,
  `_capture_lean_neutral` (3 call sites: both seat-anchor
  branches + hang setup), `_update_lean_reading`,
  `_lean_effective`, `_grip_for`; constants `LEAN_VIEW_GAIN`
  (1.25), `LEAN_TILT_STEP_DEG` (10.0).
- Model: `grip_mult` fed the lateral bleed term, the FP15
  telegraph ratios, and `_contact_long_cap`'s budget/spend.
  Lean OFF ⇒ `_grip_for` returned exactly 1.0, so deletion =
  lean-OFF behaviour everywhere, no retune.
- View: view-spring roll term `-_lean_effective() × 10° × 1.25`.
- Panel/DIAG: "LEAN EXP %s GRIP x%.2f" line; commands list
  "green lean"; desktop help T / Q/E lines.
- Persistence: NONE FOUND — settings carry only seat/trim,
  lever/left, steer/mode (git history searched for a lean key:
  none ever). Orphan-key disposition: tolerated on load (loader
  reads known keys only), scrubbed on next save (file rewritten
  from live state). Proven in stage 7.
- Needle: lone `_box` on car_body at (-0.18, 1.04, -0.615), no
  housing/backing, x driven from `_update_lean_reading`.
- Tests: stage 7/7b (the only lean-ON staged driving), stages
  11a/11b/11c/15/33/46(a)/59(vi) used lean as a generic dash
  observable; roster enumerations at stages 5, 22, 25 (print),
  30, 44, 56 and the render proof; proof panel keyword "lean".

## Census disposition (baseline FP30 624 → FP31 629)

Only stage 7/7b staged driving with lean ON. All other census
lines byte-identical except the flagged amendments listed in the
README's FP31 section (observable swaps LEAN→VIEW with identical
event counts — stage 46 ring holds at 225; index shifts at stages
22/44/56; stage 15 loses the lean reach line; stages 11c/33 gain
one restore check each; stage 7 replaced 4 checks with 8 negative
controls). Delta accounted exactly: −4 +8 +1 +1 −1 = +5.

## Gates

- Preflight: engine import parse clean (only the pre-existing
  hand-tracking property notice); headless boot run exit 0;
  inference audit by eye on all new test code (patterns mirror
  the suite's existing typed forms; the full suite executing to
  completion is the analyzer's verdict).
- ClassDB XR API guard: 71/71.
- Smoke: 629/629 (baseline 624/624).
- Render proof: 163/164 — the one failure is the pre-existing
  sandbox llvmpipe hub-reach artifact, identical on FP29/FP30.
  New proof checks: flask unmoved at FLASK_POS; no lean cyan /
  button green on any cockpit mesh; roster exactly seven.
  dash_top_view.png before/after inspected: green button and
  cyan needle visibly gone, flask in place, ZONE line LEAN-free.
- No *.uid / *.png.import in the commits.
