# FIX PASS 36 — THE BURNOUT PASS (powertrain character + hop-train authority)

Stunt Car Racer VR, Godot 4.7, ~/workspace/stunt-car-vr/game. Base: master
daa3446 (FP35). Chris's GO given 2026-11-02 ("we'll need burning out
physics"). BUILD_STAMP -> "FP36 · 2026-11-02" per the ritual.

## HIS NOTES (the law for this pass)

1. HOP-TRAIN AUTHORITY: "Once you start hopping from hill to hill, player
   has basically no control over the car. The wheel can turned in an
   extreme direction and it has no real impact on the direction of the
   car when it briefly touches road."
2. THE ODD ROD NOTE: "We need to be burning some rubber. These cars
   need fast acceleration if gas is fully pressed. That leads to control
   keeping control if you're gunning it, a plus. Speed wise, this thing
   feels like a normal car. Not an odd rod."
3. THROTTLE IS A LINE TOOL: "It becomes part of the steering calculation
   as a driver, screaming out of a turn and hugging our edge." Power
   widens the exit line; lift tucks it in; the throttle must be strong
   enough to CALCULATE with.

## PART A — AUDITS FIRST (before any tuning; all numbers in the README)

- A1. Powertrain baseline: acceleration vs speed curve, 0-30 m/s time at
  full throttle, top speed, boosted equivalents.
- A2. Corner-exit baseline: through one standard corner, exit-line
  lateral displacement at throttle settings (lift / half / full), wheel
  held constant.
- A3. Hop-authority baseline: direction (velocity-vector) change per
  touchdown at full lock, plotted against contact duration; the lateral
  grip factor through the first 0.25 s of contact. FP32's load ramp
  (25% bite + 0.10 s ramp) is the PRIME SUSPECT for taxing the lateral
  axis — convict or clear it with these numbers.

## PART B — POWERTRAIN RETUNE (tune in the open; before/after for every Part A figure)

- B1. Violent full-throttle acceleration with Odd Rod character
  (engine strong, boost = 2x engine, kept). 0-30 in genuine drag
  territory — final numbers proposed from the audit and stated.
- B2. LAUNCH WHEELSPIN: full throttle from standstill/low speed spins
  the driven wheels — while spinning, longitudinal grip drops (the car
  burns rubber instead of leaping), hooking up as speed rises or the
  throttle feathers. The spin state MUST be surfaced: audible tell +
  visual tell (a simple smoke emitter at the driven wheels is enough —
  placeholder-grade visuals, real state). Wheelspin also applies at
  the Drop Start race launch — a scrubbed, smoking start is the
  intended texture.
- B3. THROTTLE-AS-LINE: after the retune, A2 must show the throttle
  measurably steering the exit line (full throttle runs measurably
  wider than lift through the same corner, same wheel). Report the
  spread in metres.
- B4. Pace consequence: report how the retune reprices flight — lab
  air times at the new pace vs the FP35 baseline (the flight-time
  budget) — as a REPORT, not a fix; track shaping is deferred by the
  owner's ruling.

## PART C — HOP AUTHORITY FIX

Follow A3's evidence. Expected shape if the ramp is convicted: lateral
bite decouples from the vertical load ramp — the vertical keeps FP32's
sink behaviour EXACTLY (its staged numbers must not move), while
lateral grip reaches authority fast on contact. If the ramp is
innocent, fix what the audit actually convicts (crest unweighting,
lateral velocity kill) and say so. After: A3 re-measured — full lock
through a drumbeat-length contact must produce a real direction
change; name the number.

## CONSTRAINTS

- FP32's landing numbers hold (no regression).
- The boost economy is NOT retuned — report the repricing (lab payout
  totals before/after) and flag if it breaks badly.
- Car-selection cosmetic parity holds (one powertrain).
- Commands list/README updated for anything the driver can now do
  (wheelspin is a state, not a command — document it in the car-feel
  notes).

## Standard gates

godot_gdscript_preflight audit, parse warnings-as-errors, ClassDB XR
guard, full smoke suite, render proof. No *.uid / *.png.import in the
commit. README fix-pass entry (audits, retune table, spin model,
census) + this brief. Commit to master, push via the repo's
sshCommand route, verify with git ls-remote, REPORT IN FULL.
