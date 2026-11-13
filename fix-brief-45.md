# FIX PASS 45 — THE TURNED BLOCK + THE TOP-GEAR VOICE

Repo: ~/workspace/stunt-car-vr, Godot project in game/. Branch master.
**Base commit: fcc9afd (FP44). VERIFY FIRST: `git log --oneline -1` must show fcc9afd
before any edit; remote === local (Hal ls-remote-verified at dispatch).**

Two small items, both from the owner's FP44 seat verdicts. Nothing else in this pass:
no gearing changes, no funlab work, no economy dials.

## ITEM 1 (HEAD) — The orange block under the engine gets TURNED and stays turned

Field report (owner, FP44, twice, with photo): "I don't know when it happens,
probably on a hard landing, its happened twice now: the orange block under the
engine gets turned. I dont know if that supposed to be damage or what."
It is NOT damage — no damage system exists. It is a visual-state bug: one orange
body piece directly under/ahead of the black engine box ends up yawed relative to
the car and PERSISTS. Photo (read it first):
~/workspace/user/media_library/image/VirtualDesktop.Android-20261104-133211.jpg
(the twisted orange slab is centre-frame, below the engine box, ahead of the wheel).

METHOD — audit and convict, do not guess:
1. Inventory every per-frame write to the transform/basis of car visual nodes
   (car_body and its children, body_node/body_node_fb, any part oriented from the
   road frame or the drive frame). Known landmarks: the FP44 yaw hunt rotates the
   drive frame d41 in _update_drive (~line 7500: `d41.rotated(up41, (yaw_rate +
   hunt_yaw) * delta)`); the FP44 shudder writes body_node.position only
   (~line 9171); the blower box is built at ~line 4328. NOTE: neither landmark
   SHOULD be able to rotate a single part — which is why this needs evidence.
2. Reproduce in a probe: stage the hardest honest landings the suite owns (the
   retention battery's CROSSED-UP and nose-slam cases, the Track 01 lap's worst
   arrivals, crane drops) and dump every car-visual part's basis (or at least every
   orange part's) before/after each landing. The convicted write is the one whose
   part's basis changes across a landing and does not restore.
3. Fix AT THE MECHANISM: the part's orientation must be a pure function of state
   that cannot leak across the landing transition (re-derive from parent/state each
   frame, or clear the leaked accumulator on the transition — whichever the
   convicted mechanism dictates). Do NOT freeze cosmetic channels wholesale (the
   house lever doctrine: controls and cosmetic motion never freeze; they just must
   not leak).
4. Proof: a probe battery post-fix shows basis delta 0.000 for every car part
   across every staged landing; promote that battery into the suite as a new stage
   so the leak cannot regress silently.

CENSUS EXPECTATION: this is a visual-only defect — the FP41–FP44 census should not
move AT ALL. If the convicted mechanism couples into drive state, report the
coupling and every moved number with its one-variable proof instead of hiding it.

## ITEM 2 — Top gear sounds lazy

Owner: "last gear sounds so low, it doesn't 'feel' very powerful." Mechanism (from
the FP44 numbers): 4th spans 41–71 m/s, so gear_rev lives at 0.1–0.3 through the
whole working range and the engine note sits at the bottom of its curve exactly
where the car should feel endless.
FIX (audio mapping only): remap the AUDIO rev in top gear so the working range
reads alive — e.g., audio_rev = 0.35 + 0.65 × gear_rev in gear 4, or an equivalent
compression of the band's audio span; the exact curve is yours within these bounds:
- at 55–65 m/s in 4th the note must read clearly higher/keener than FP44's read;
- it still rises toward the 71 reserve and tops out at the clamp;
- gears 1–3 audio IDENTICAL; shift blips, the shift sag, and every other audio
  behaviour untouched;
- the gear_rev STATE itself (DIAG, shift logic, hysteresis) untouched — this is a
  presentation mapping on the audio side only.
Proof: extend the powertrain stage (or stage 71) to assert the audio-rev read at
staged speeds in 4th; report the before/after audio-rev at 48 / 55 / 62 / 68.

## Standing gates (every pass)
Full smoke green incl. the ClassDB API-surface guard (71) and the census EXCEPT the
exceptions you re-derive, flag in place, and prove one-variable (Item 1 expects
zero). Rendered-frame proof. Preflight GDScript audit clean. No *.uid or
game/tests/*.png.import sidecars in the commit. BUILD_STAMP = "FP45 · 2026-11-04".
Commit on master, push, VERIFY with git ls-remote (must equal local HEAD; the
sandbox proxy route is per-repo — if the push fails on connection reset, check the
repo's core.sshCommand shape before diagnosing keys).
Report: the convicted mechanism for Item 1 with the probe evidence (part, write,
transition), the before/after basis deltas, Item 2's audio-rev table, commit hash,
suite totals, every census exception with its proof — or an explicit "census
unmoved."
