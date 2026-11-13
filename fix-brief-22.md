# Fix Pass 22 (micro) — On Chains, the Button Drops You. Period.

Ordered by the owner (Jaklar), Fri 2026-10-30 09:17 CDT, run 19
on FP21: "when you're being droned, Text says DRONE LIFT, and
the button doesn't release you even though you're over track.
It won't activate until the text changes to something or other.
Need to get rid of that. If you're on chains, the button works.
period. Not over the track? Don't press the button."
Base: master @ d8be713 (FP21 final).

## The ruling (it corrects Hal's earlier reading)

Yesterday Hal implemented the owner's "moron" sentence
conservatively: mid-carry press = SPENT, chains hold. With the
button in his hands the owner rules the full version, and the
record is corrected: THE GATE IS THE DEFECT. Whenever the car
is on the chains — any hang phase, any position — the button
releases it. Where it falls is the driver's business.

## Item 1 — Delete the release gate

- In MODE_HANG, a button press fires `_do_release()` in EVERY
  phase (attach / carry / dangle). The phase gate in the fire
  path and the SPENT outcome are deleted.
- The fall converts the crane's current state (position,
  velocity, swing) exactly as a dangle release does today; the
  car lands where it lands; off-track outcomes flow into the
  existing recovery as they already do. No new landing rules.
- DRIVE/AIR presses unchanged: the button still answers (dull
  pulse + log) and does nothing — not on chains, nothing to
  release.
- BTN telemetry keeps phase tags; the RELEASE telemetry
  (s / HDG / SEC / ERR) now fires for any-phase releases, with
  SEC/ERR measured against the section under the car at
  release.

## Item 2 — The hang banner stops implying a wait (absorbs the
queued banner rename)

The state label's non-dangle hang text ("DRONE LIFT...") is
the visible face of the dead gate — and the wrong word. Across
all hang phases the label now says the one true thing, in the
crane's name: e.g. "CRANE LIFT — BUTTON TO DROP" (exact wording
builder's, one line, no phase variants that imply permission
windows). The queued load's banner item is thereby absorbed;
the smoke sphere + steering items stay queued separately.

## Stages

- New: press during CARRY from a known crane position → the
  car releases, falls with the crane's state, lands, and the
  mode flow stays sane (drive or re-recovery); press during
  ATTACH likewise; Drop Start early press likewise.
- Amended-and-flagged: stage 34's SPENT/grind expectations are
  replaced by release expectations (the grind has no un-armed
  state left to refuse). All other stages re-pass; census
  frame-identity on drive stages unchanged.

## Standing constraints

No drive numbers move. No `*.uid` / `*.png.import` commits.
ClassDB guard green. Commands list: the button's description
updated in the same commit (it no longer mentions waiting for
the station). README results section with tallies and a
"What you're judging" summary (any-phase drops; the new
banner line; NOT in: smoke sphere, steering connection).
