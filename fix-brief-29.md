# Fix Pass 29 — The Wheel, Rebuilt (steering semantics)

Ruled by the owner (Jaklar), Sat 2026-10-31 11:16 CDT: the
grabbed wheel STAYS; its semantics are rebuilt to the
research-proven spec. Input semantics ONLY — the car model,
tire physics, wheel visual/gain (FP25), boost economy,
crane, and all tracks are untouched.

## Why

The player holds nothing. Reproducing an absolute angle
blind errs ~23°; the documented shipped behaviour for
virtual wheels is HOLD-STATE on release (no fixed-rate
auto-centre exists in any shipped VR wheel game found),
delta-only steering, and seamless hand join/leave. Our
defects, convicted in code (wheel block, _poll_grab):
(1) wheel_angle bleeds to centre at 1.6 rad/s per poll —
twice per frame, L and R — whenever ungripped in DRIVE,
with the desktop block's 2.2 rad/s centring stacked on top
in XR; (2) re-grip is two-step — FP17 ownership requires
the returning hand to fully release its dash latch before
the wheel accepts it; (3) rotating past the ±PI clamp
leaves the reference behind, so return travel must unwind
before it bites. Plus the owner's addition (11:17 CDT):
thumbstick driving should be an OPTION for people — the
stick becomes a selectable control scheme, not only a
silent fallback.

## Item 1 — Hold state

In XR, an ungripped wheel in MODE_DRIVE holds wheel_angle
exactly. The _poll_grab bleed is deleted; the desktop
steering block (keys + its 2.2 rad/s DRIVE centring) is
gated to the desktop path (not xr_ok), where its behaviour
is byte-identical to before. The dangle dial-in already
held (neither decay ran outside DRIVE) and still does.

## Item 2 — One-step regrip + clamp absorption

(a) A gripping hand that owns a dash latch and arrives at
the wheel — inside the grab radius and OUTSIDE every dash
zone (it has left the buttons; the dash-top row lives
inside the wheel's radius, so zone exit is the arrival
test) — takes the wheel in the same poll. The dash latch
ends cleanly as part of the transfer (a seat latch writes
its REL record, the SIDE hold clock resets; nothing is
left stuck "fired"). The reverse stays sticky: a hand
DRIVING the wheel is never stolen by dash proximity
(unchanged). FP17's stage 47(e) staged the old law ("a
dash-latched hand cannot take the wheel mid-squeeze") —
it is amended, flagged, to stage the new one.
(b) While held and pinned at the ±PI clamp, the steering
reference (grab_prev_ang; line_prev_ang in two-hand mode)
advances WITH the hand — the clamped excess is absorbed
into the reference, so return travel bites on the first
degree back. No dead unwind.

## Item 3 — Two-hand line steering

When both hands hold the wheel (driver + rim passenger),
the steering delta is the change in the clock angle of
the LINE between the two hands about the hub axis (the
WiiCompiled model): translating both hands together does
not steer; either hand orbiting does. Join re-bases the
line reference at the join frame (jump 0); leave re-bases
the remaining hand's around-hub reference at the leave
frame (jump 0). If either hand comes within 0.06 m of
the hub axis the line reference freezes (input holds)
until it exits, then re-bases — crossing the hub cannot
spike the wheel. A small haptic tick lands on the
joining/leaving hand; any wheel release gets a soft
pulse, lighter than the grab pulse. Single-hand steering
remains the shipped around-hub delta, unchanged.

## Item 4 — Stick fallback + STEERING MODE

The RIGHT thumbstick's primary X axis is a RATE input
(2.6 rad/s at full deflection — the desktop key rate);
the angle HOLDS when the stick centres. A persisted
setting, STEERING MODE, names the at-rest authority:
- WHEEL (default): the stick steers only while no hand
  grips the wheel.
- STICK: the stick steers from rest, no grip needed.
In BOTH modes, last touched wins: grabbing the wheel
seizes steering while held; releasing returns authority
to the mode's at-rest source with the angle held — no
jumps in either direction, ever. The DIAG WHEEL line
gains SRC <live source>/<mode>. The mode toggles by
holding the R A button in the hang for 0.8 s (the Y
restart's own pattern — A has no hang job; the flip is
announced on the touchdown readout) or the desktop N
key. Persisted in user://settings.cfg ("steer"/"mode")
beside the seat trim and drop side.

## Item 5 — Drop to X

Left X in MODE_HANG fires the same release as the dash
DROP BUTTON / SPACE (_do_release, every hang phase,
FP22 semantics). X's prior jobs are untouched: in the
hang it only wrote the BTN-log note (the note stays, and
the press now also drops); the DRIVE crane call is a
different mode and stands. Stage 32's "X in the hang is
inert" expectation staged the old gating — amended,
flagged. The physical dash button remains fully
functional. Commands list and README updated (standing
rule: every accepted input is listed).

## Item 6 — Staging + census discipline

New stage 59 proves: hold (release at a dialled lock in
DRIVE; wheel_angle identical after 2.0 s of ungripped
polls); one-step regrip (dash latch → wheel in one poll,
steers next poll, latch ended clean); clamp absorption
(past lock by 30°, return 10°, wheel moves 10° at once);
two-hand line (line +30° → wheel +30°; join/leave jumps
≤ 0.5°; hub cross spike ≤ 1°); stick fallback (rate
2.6 rad/s ± tolerance, centre holds, grip seizes with no
jump); steering mode (persists across save/load; STICK
steers from rest; a grab in STICK seizes and returns
cleanly); X-drop in the hang with the note kept.

Census: every existing stage whose scripted driving
releases the wheel mid-drive is enumerated in the README
with old vs new expectations; all other census stages
byte-identical. Standing gates: preflight audit,
warnings-as-errors parse, ClassDB XR API guard (gains
XRController3D.get_vector2), full smoke, render proof.
No *.uid / *.png.import in the commit.

## README "What you're judging"

The wheel, from your hands only: let go mid-corner and
the lock HOLDS; press a button and come back — one
squeeze and you're steering, no release-and-regrip
two-step; turn past the lock and the first degree back
bites; put both hands on and the line between them
steers, hands joining and leaving without a jump. And
the option: hold R A in the hang to flip STEERING MODE
to STICK and drive on the right thumbstick, grabbing
the wheel whenever you reach for it. X drops you from
the chains now, same as the red button.

---

## AS BUILT (2026-10-31)

Shipped as briefed, plus the steer-mode addition
(Chris, 11:17 CDT). Two defects were convicted BY the
render proof during staging and fixed in-pass:

1. **Line reference basing moved to the attach.** As
   first built, the two-hand line reference based at
   the driver's next poll after a join; the proof's
   staged driver move — compressed into a single poll
   — was swallowed whole (wheel delta 0.0 measured).
   The reference is now born in _update_rim_attach at
   the attach instant (join tick likewise), so the
   driver's first poll already reads a true delta.
   The proof's both-hands expectations were re-derived
   under the line law and flagged in place: one hand
   moving 0.5 rad about the hub with the other fixed
   turns the wheel by the chord delta (measured
   0.25 rad); the passenger rep rides exactly that.
2. **Panel text overflow.** The FP29 commands-list
   lines grew the panel text to 1.46 m against the
   1.24 m board (4 of 63 sightlines occluded). The
   FP12 remedy re-applied: panel pixel_size 0.00105
   -> 0.00084; text now 0.54 x 1.16 m, 0 occluded.

Final gates: smoke ALL 595 PASSED, API guard ALL 71
PASSED, render proof 151/152 (the one failure is the
pre-existing sandbox hub-reach artifact, identical in
the FP28 baseline). Census exceptions: stage 32 and
stage 47(e) amended and flagged; stage 46's printed
ring count moved 220 -> 223 (cumulative counter,
assertion unchanged); all else byte-identical.
