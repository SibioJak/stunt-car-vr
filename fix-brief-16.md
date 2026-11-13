# Fix Pass 16 — OPERATION FIX THE FUCKING LEVERS

Ordered by the owner (Jaklar), Thu 2026-10-29 09:49 CDT, mid-run-15,
in those words. Base: master @ 84d0922 (FP15 final). Repo:
SibioJak/stunt-car-vr, game/. This operation is SINGLE-FOCUS: cockpit
grab/lever actuation. The tracks pass and everything else waits.

Owner's verdicts driving it (run 15, on FP15): "It's fiddly as hell,
like most levers so far. Sometimes it work, sometimes it don't." And
the amendment, same breath: "And make em smaller, I feel like an
Oompa Loompa." Plus two folded items from the same run: only ONE hand
ever renders on the wheel though both are grabbed (standing since
Test 1), and the drop lever's SIDE setting flipped itself mid-session
and persisted, silently.

HISTORY THAT CONSTRAINS THIS PASS: staged fixes have "fixed" the
levers four times (FP9 level-based activation, FP10 binding audit +
nearest pickup, FP13 articulation, FP15 zone-vs-mesh audit) and the
live hands still fail intermittently. CONCLUSION THE BRIEF STARTS
FROM: the fault lives in the LIVE XR input path, which the headless
suite exercises only with simulated hands (exact poses, clean digital
grip edges). STAGED-GREEN IS NOT EVIDENCE IN THIS PASS. The
deliverable therefore includes live-path TELEMETRY that ships in the
build (below), so the owner's next session produces verdict-grade
evidence either way.

Standing constraints: no `*.uid` / `*.png.import` commits; ClassDB
guard green; the in-interface controls list names every command —
same-commit updates for any change; steering/grab semantics otherwise
unchanged; all existing stages re-pass.

---

## Item 0 — Research + the differential (before any fix)

(a) EXTERNAL ("contact other nations"): a parallel research agent is
writing ~/workspace/stunt-car-vr/research/xr-grab-reliability.md —
Godot XR Tools grab patterns, OpenXR squeeze action behaviour,
Virtual Desktop/VDXR grip-value reports, VTOL-style lever handling.
Read it if present when you reach fix design; if it lands later, the
coordinator will forward anything load-bearing.

(b) INTERNAL: read the ENTIRE live grab path end to end (input
actions → per-frame grip values → zone tests → latch → throw
tracking → actuation → visual/haptic feedback) and write the
mechanism differential into the README results: each suspect below
marked CONVICTED (code evidence), EXONERATED (code evidence), or
UNDETERMINED-LIVE (cannot be settled headless — telemetry target).
Named suspects, from the project's own history:
  1. Analog grip threshold (0.65) with no hysteresis — a partial or
     tiring squeeze hovers at the threshold and the latch chatters.
  2. Zone TUNNELING — a fast hand crosses a small zone between
     physics frames; entry never registers.
  3. REP-vs-POSE offset — the rendered controller rep sits ahead of
     the real hand (run 3 measured ~a controller's length; "origin-
     true reps" shipped in FP3 but the ZONE TEST's position source
     vs the RENDERED position source has never been asserted equal).
  4. THROW-TRACKING dropout — once latched, a pull that carries the
     hand outside a radius/zone silently cancels mid-throw (the drop
     lever's 0.50 detent throw is the longest pull in the cockpit).
  5. GRIP VALUE SOURCE — get_input("grip") vs grip_click/grip_force
     fallbacks (FP3 added fallbacks; FP10 found grip_force bound
     NOWHERE, so that fallback is dead code reading 0.00 forever).
  6. FEEDBACK ABSENCE — a latch that gives no immediate visible +
     haptic confirmation reads as "didn't work" even when it did
     (the inverse fault is also real: it trains double-grabs that
     toggle state back off).

## Item 1 — Fix every convicted mechanism

Whatever Item 0 convicts gets its fix, with the design rule that
governs all of them: **a grab, once honestly made, must be very hard
to lose accidentally and impossible to miss silently.** Expected
shapes (adapt to the evidence): hysteresis on the grip latch
(engage high, release low); swept or velocity-scaled capture volumes
so fast hands cannot tunnel; zone tests and rendering driven from
ONE pose source, asserted equal in a stage; latch-to-control throw
tracking (the control owns the hand until grip release, travel
clamped to the control's arc — the VTOL pattern); a latch
confirmation (hand visibly closes on the control + a short haptic
pulse) on every successful grab, and a distinct release cue.

## Item 2 — Smaller levers, decoupled grab volumes

The owner feels like an Oompa Loompa: the cockpit levers are
oversized for the hands and the seat. Shrink the lever furniture
(drop lever, seat-trim levers; dash buttons may follow if the audit
says they're in the same class) to a hand-plausible scale — report
before/after dimensions. CRITICAL: visual size and interaction size
DECOUPLE. The invisible grab volumes stay at least as generous as
today's zones (grow them where Item 0's evidence says misses happen)
— smaller levers must come out of this pass EASIER to grab, not
harder. The zone-vs-mesh audit is re-run under the new rule: every
grab volume must CONTAIN its mesh with margin; a volume smaller than
its mesh is a violation now.

## Item 3 — Both hands visible on the wheel

Folded in (same hand-representation system the diagnosis touches):
when both hands are grabbed on the wheel, BOTH hand reps render
attached at their grab points and travel with the rim; one-hand and
zero-hand states render as today. Proof per the standing VR rule: a
rendered frame through the XR layer (fake-tracker rendered proof as
in FP10-era practice), not a tally — the headless suite cannot see
this layer and the README must say so.

## Item 4 — SIDE flips: deliberate and announced

The drop lever's side setting must not flip on a stray grab. Make
the SIDE actuation deliberate (e.g. a sustained hold, distinct from
a tap) AND announce any flip where the driver can see it (panel/DIAG
banner flash + the existing DIAG DRP R/L line). The persisted setting
itself is unchanged in kind; the owner's current left setting is HIS
and stays.

## Item 5 — Telemetry that ships

A DIAG GRAB line (and, cheaply, a session log in user://) recording,
per grab attempt on any cockpit control: hand, grip value at latch
and at release, zone entry/exit, latch outcome, throw completion or
the frame/reason it dropped. Always on, one line, no performance
excuse accepted. This is the operation's insurance: if any fiddliness
survives Items 1–2, the owner's next session names the mechanism from
his own log instead of from memory.

---

## Results section requirements

README gains a Fix Pass 16 section: the Item 0 differential with its
verdicts, per-fix before/after (dimensions, thresholds, volumes),
tallies, the rendered both-hands proof frame, and honest residuals —
leading with whatever remains UNDETERMINED-LIVE and exactly what the
telemetry will show if it recurs.
