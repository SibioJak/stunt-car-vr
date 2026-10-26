# Fix Brief 4 — Stunt Car Racer VR, Test 1 (Fix Pass 4)

Base: commit 4a74289 (master, remote-verified). Two items from Chris's run 4
(2026-10-26 15:43 CDT, his first run with working grip). Do not touch the
driving model, track, anchor logic, wheel geometry, or anything not named.
Repo rules: never commit `*.uid` or `game/tests/*.png.import`; ONE commit;
push to origin master (`ssh://git@ssh.github.com:443/...` with core.sshCommand
as configured) and verify `git ls-remote origin master` == new HEAD. No audio.

Run-4 facts this pass answers:
- Grip is now LIVE-VERIFIED (Chris: "levers moved"); the panel DIAG showed
  ANCHOR APPLIED-STABLE / TRK Y / CAMH 1.12 in his photo.
- Chris: switches "activated fairly far away from my hand" — the Fix Pass 3
  insurance radii are now a defect, not a safeguard.
- Chris: "Panel isn't readable" — in his photo the enlarged board (0.76 ×
  1.56 m) clips at the view edge and the car's bodywork occludes the lower
  DIAG lines (L/R grip values unreadable).

## Item 1 — Near-touch dash activation

- Dash/prep control activation radius: 0.32 m → **0.15 m** (hand origin to the
  control's interact point). Apply it in the single place proximity is
  computed so switches, buttons, and takeover all use it.
- The **wheel grab radius stays 0.40 m** — do not tighten it. (The wheel
  measure is hand-to-hub-centre; a hand ON the rim already reads ~0.2 m, so a
  small radius would break rim grabs. Chris's complaint named the levers.)
- Update any smoke assertion/constants comments that encode 0.32.

## Item 2 — Panel readable from the seat

Rework panel placement/scale so that, from the anchored eye (0, 1.14, 0.05)
car space:
- the ENTIRE board — full command list AND the full DIAG block, last line
  included — sits inside the central view at seated distance, with margin on
  all sides (nothing clipped at a typical seated FOV edge);
- NO car geometry (bodywork, dash, wheel) occludes any part of the board from
  that eye position — verify by ray/depth check or by rendering from the
  anchor with the car fully present and inspecting the frame;
- text remains at a readable angular size (do not solve clipping purely by
  shrinking the text into illegibility).

You may choose the mechanism: move the board (further forward/down, yawed
toward the driver), resize it, and/or split the DIAG block onto its own small
board in clear view. Keep the command list complete (standing rule: the panel
lists EVERY command the game accepts) and keep the DIAG fields as built in
Fix Pass 3. If the board moves, update game/README.md's panel description if
it names a position.

## Verification (all required)
- Clean headless import, exit 0, zero script errors; full GDScript preflight
  audit on changed code (typed inference rules per the skill).
- API-surface guard still passing (extend only if new live-path calls appear).
- Full smoke suite passing with all previous driving numbers identical; add/
  update assertions for the 0.15 m dash radius.
- Render proof from the anchor camera WITH the car present: the full board
  visible and unobstructed; plus a close crop of the DIAG lines legible.
  Save as the standard tests/*.png proofs (refresh cockpit_view.png at
  minimum).
- Report: what moved/resized and why, the from-anchor proof description,
  smoke/proof counts, frame stats, commit hash, ls-remote verification.
  State plainly that live feel (activation distance, readability) remains
  unverified until Chris's run 5.
