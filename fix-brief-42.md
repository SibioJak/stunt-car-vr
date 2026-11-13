# FIX PASS 42 — THE MORE PASS (as built)

Owner's GO: 2026-11-03, on his FP40 verdict: "everything is
so subtle as far as changes. more of everything is needed" —
with warping confirmed gone from the seat. Base: master
`8455831` (FP41). BUILD_STAMP: "FP42 · 2026-11-03".
FP40's deltas were honest on paper and timid in the car;
this pass turns every FP40 dial up until the seat can feel
it, and adds the body-pitch channel the owner specified
from his film study of the original: "tilting forward,
backward on shifting and launch will help sell it."

## Item 1 — gearbox, MORE

- `GEAR_TOP_SPEEDS` [11, 19, 33, 48] -> [12.5, 19, 33, 48]:
  first gear stretches so the burnout lives in first a beat
  longer and hooks just before the shift — bite, then shift,
  two events instead of one chirp.
- `GEAR_FORCES` [22, 19, 15.5, 12] -> [22, 19, 16.5, 12.5]:
  the top gears pull harder after each change, so the shift
  gap reads against a stronger bite on the far side.
- `SHIFT_GAP_S` 0.13 -> 0.22 s: the thrust gap is an event,
  not a footnote.
- `SPIN_KINETIC` 0.85 -> 0.72: a spinning tire pulls less,
  so the burn lasts longer in TIME and the hook contrasts
  harder when it comes.
- In the ear: inside the shift gap the rev fall rate is
  9.0/s (the standing smoothing was 1.6/s), so the note sags
  with the gap and climbs the new band. Measured: the
  one-tick audio-rpm drop at a shift goes 0.028 -> 0.164.
- The under-cap feather law is untouched by construction
  (0.45 throttle x 22 = 9.9 < the 11.0 cap): a gentle launch
  still hooks clean.
- Before -> after (FP40 -> FP42, staged floored launch):
  spin peak 1.00 -> 1.00; spin at 8 m/s 0.84 -> 0.87; last
  frame over 0.5 spin 0.99 s -> 1.19 s; hook (spin < 0.05)
  1.76 s -> 1.93 s; 0-30 2.86 -> 3.14 s; 0-45 5.13 ->
  5.40 s; time-to-top 5.77 -> 5.98 s; top speed 48.00
  unchanged; shifts at 12.55 / 19.05 / 33.03 m/s; biggest
  one-tick gear_rev drop 0.99 (unchanged — the drop was
  already full-size on paper; it was the EAR that couldn't
  hear it, and the gap it falls into is now 0.22 s).
  Drop Start launch spin 0.83 (FP40) — the smoking start
  stays. Feathers: 0.45 -> peak 0.00; 0.65 -> peak 0.38,
  0.08 at 8 m/s.

## Item 2 — fishtail, MORE

- `FISHTAIL_TAX` 0.75 -> 2.00 (twice the true friction
  circle) and the factor floor 0.16 -> 0.0625 (factor never
  under 0.25). FP40's ceiling was set by the staged driver
  leaving the lab's off-camber S at TAX 1.00; the owner's
  hands asked past it, so the tax no longer works alone —
- THE CATCH: when the driver's foot comes off (in_throttle
  falling > 0.05 between frames), a catch window arms for
  `FISHTAIL_CATCH_S` 0.30 s at `FISHTAIL_CATCH_GAIN` 0.35:
  the bleed factor is restored toward the tire's loaded
  ceiling (clamped at GRIP_LOAD_MAX 1.15, never past it).
  The trigger is the FOOT, not the demand: the first form
  armed on any rear_u fall and probe measurement caught it
  armed 31% of frames in a HELD-throttle corner (shift gaps
  and load noise), diluting the tax it was meant to protect.
  On the foot trigger it arms 0% of held-corner frames, and
  pursuit modulation in the S still arms it — the staged S
  driver lifts, and the catch is what he catches on.
  A catch armed before a flight does not carry across it
  (cleared in _land); throttle_prev keeps its pre-flight
  value, so a driver who lifted mid-flight arms the re-bite
  on the first DRIVE frame.
- Measured (standard corner, stage 68 fixture): lift slip
  1.76 deg (unchanged — lift still restores full bleed the
  same frame). Under full power FP40 read 1.99-2.09 deg and
  that was all of it; FP42 SUSTAINS 2.09 deg (s >= 645
  mean, against lift's 0.37) and PEAKS at 3.59 deg — the
  sustained angle is the new attitude, the peak is the
  step-out the driver sees. Exit-line spread lift-vs-full
  4.65 -> 5.14 m, full exit lat +2.81 against the 7.17
  fall line. The tuck (stage 70):
  floored to s 650, throttle cut — slip >= 1.5 deg at the
  cut and dead under 0.6 deg within 45 frames (0.5 s).
- The S keeps its margin: lab P5 off-camber at the shipped
  setting reads slip_state 0.47, |lat| 1.43 — its FP40
  margins (0.48-0.55 / 1.47-1.65 against the 3.5 bound),
  because P5's driver modulates and the catch pays his
  lifts back as grip. More tail and the same S survival
  coexist; no trade had to be reported.

## Item 3 — landing costs, spread wide

Retention of the forward component in _land, boost payout
dials untouched (owner's economy ruling):

- CLEAN: clampf(1.02 - vy*0.003, 0.96, 1.0) — a
  slope-matched arrival keeps essentially everything
  (staged ~1.000; FP40 0.962-0.985). Keeping your speed IS
  the reward.
- SCRUBBED: clampf(0.87 - vy*0.024, 0.45, 0.78) — staged
  ~0.60 (FP40 0.694).
- CROSSED-UP / slam form: clampf(0.68 - vy*0.024, 0.24,
  0.52) — staged crossed-up ~0.41 (FP40 0.544); the
  nose-first slam (12 m, side-pushed) ~0.22 (FP40 0.338) —
  almost nothing kept.
- Misalignment multiplier: clampf(1.05 - misalign*0.007,
  0.70, 1.0) (was 0.006 / floor 0.75). Crane drops stay
  exempt at 1.000.
- Repricing (reported, not compensated): the payout dials
  are untouched and stage 54's identity holds (income is
  the grade-weighted offer, <= air x rate). The audit lap's
  projected offer moves only with its pace: circuit 185.1
  -> 181.3 units/lap (payable air 18.51 -> 18.13 s - the
  new retention changes which flights the audit driver
  makes), ribbon 104.2 -> 104.5, longest starved stretches
  unchanged (circuit 500 m, ribbon 250 m). What retention
  reprices is realized speed after a landing, not boost.

## Item 4 — the body-pitch channel

One honest force-driven channel, not scripted animation —
the Crammond law from the owner's film study: pitch is a
load gauge.

- New oscillator in _update_body_spring: target =
  -LOAD_PITCH_K * long_accel_f in DRIVE, 0 otherwise
  (airborne and hanging the channel settles; FP32's sink
  follow untouched). LOAD_PITCH_K 0.0055 rad per m/s^2,
  spring 48.0 (omega ~6.9 rad/s), damping 5.8
  (zeta ~0.42), clamp LOAD_PITCH_MAX 0.11 rad (~6.3 deg).
- _update_view_spring: b_pitch = body_sink*BODY_PITCH_K
  + load_pitch. The old one-sided brake term
  (BODY_BRAKE_PITCH_K 0.0016, clamped positive-only) is
  DELETED — the channel covers both signs at full strength.
- DIAG's SPD line appends PITCH %+.1f (degrees of
  load_pitch) — the channel is surfaced, per the standing
  rule that rulings the driver judges get shown.
- Measured before -> after: FP40's channel (sink term +
  the clamped brake term) read launch -0.01..+0.46 deg and
  braking max 0.73 deg — a rumor. FP42: launch squat
  -4.48 deg; at the first shift the body swings 3.68 deg
  (squat -3.5..-4.1 deg through the gears, dipping forward
  as thrust cuts in the gap, squatting again as the next
  gear bites); full brake dive +4.50 deg. Touchdown sink
  timing unmoved (stage 61's FP32 numbers: peak 0.298 m,
  time-to-peak 0.122 s — bit-identical, the channel is
  additive over the sink, not in its path).

## Census

- Stage 9 amendment (flagged in place): the
  outside-staircase GEOMETRY height tier 0.014 -> 0.022.
  The step is the FP8 mechanism — sweeper-exit bank unwind
  acting through the car's lateral offset — and Item 2's
  tax makes the staged car run wider through that exit
  (lat +5.03 at s 165 vs FP41's +1.8). One-variable proof
  (probe42b): FP42 tree 0.0174 solo / 0.0180 in-suite; the
  same tree with ONLY tax/floor reverted to 0.75/0.16
  reads 0.0090 with lat tucked at +0.8 — FP41's line and
  FP41's step. The wider line is the item working as
  ordered; the car stays on the road (edge 6.0, fall line
  7.17) and the lap completes. Pitch tier (0.205 deg read)
  and staircase tier (0.0124 m) unmoved.
- Stage 68 amendments (flagged in place): the corner
  fixture returns sustained slip; new checks pin the
  sustained delta (full > lift + 1.0, full > 1.5) from the
  probe table (lift 0.37 / full 2.09 sustained, peak 3.59);
  retention bands re-derived for Item 3's curve: SCRUBBED
  [0.66, 0.82] -> [0.52, 0.68], CROSSED-UP [0.50, 0.66] ->
  [0.34, 0.48], slam [0.28, 0.50] -> [0.15, 0.29]; CLEAN
  [0.94, 1.0] kept.
- Stage 70 new: launch squat < -3 deg and first-shift swing
  > 2 deg from a settled floored start; brake dive
  > +3 deg; DIAG PITCH surfacing; the tuck (cut at s 650:
  slip >= 1.5 deg, dead < 0.6 deg within 45 frames). The
  tuck staging was amended in-pass (flagged in place): the
  first form held the wheel pinned past the cut and could
  never pass - at 32 m/s and full lock the corner's own
  slip floor is ~1.1 deg on any bleed setting and the lock
  walks the car off the road at +140 frames (probe42c).
  Restaged as the driver's real input pair, lift + unwind:
  crosses at ~+17 frames shipped; with the catch gain
  zeroed, ~+20 - the tax restoration on lift is the
  dominant term, the catch is margin on top, and the check
  guards the pair as shipped.
- Everything else in the FP41 census holds: tangent-model
  laws, the loop's clean window and crown, funlab rulings,
  the FP39 storm law, FP32 landing timing, the economy
  identity (stage 54).

## Gates

- Preflight: import clean, brief runtime run clean (only
  the standing OpenXR headless noise).
- SMOKE: ALL 803 CHECKS PASSED (stage 70's tuck reads 19
  frames in-suite; stage 9 passes under the amended tier).
- API GUARD: ALL 71 CHECKS PASSED (inside the suite run).
- Render proof: 172/173 - the only failure is the standing
  wheel-hub reach artifact (0.31 m below the eye, identical
  on every baseline since FP31; this pass touched no seat
  or wheel geometry). Captures refreshed.
