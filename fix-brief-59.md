# FIX BRIEF 59 — SMOKE THAT ANSWERS THE SKID (single item)

Base: `f2bf5b1` (FP58, verified remote). Stamp on ship: FP59 · 2026-11-11.

## The ruling this pass implements

Chris (2026-11-11): "for now, focus on smoke coming from tires during loss of traction, when car makes the skidding sound around turns."

The event is lateral loss of traction in turns — the moments the skid audio sings. Wheelspin smoke is OUT of scope ("for now"): the spin keeps its audio voice only. The exhaust and launch cases do not exist in this pass.

## Ground truth (Hal, code read)

- The skid voice's drive already exists and is proven in the owner's ears: `audio_skid_now` — `slip_state` smoothed (attack 16/s, release 22/s) in `_update_audio`; `slip_state = clampf((|vl| − 1.2)/3.8)` at line ~9232 (onset at 1.2 m/s lateral velocity, full at 5.0); the gain maps −34 dB at onset to −13 dB at full. FP44's amendment made the skid voice slip-only — "one voice per physical story."
- FP58's smoke failed in the seat (Chris's video, 2026-11-10) for two convicted reasons: (1) its trigger regime was the extremes (the proof staged a sustained full-lock slide; ordinary driven cornering barely fires it), and (2) construction: fast billboards streamed along the wake vector read as a diagonal streak sheet at bodywork height — "looks like engine is having problems and tires are t involved at all."

## The item

**One law: when you hear the skid, you see the smoke.** The tire-smoke channel's drive becomes the skid's own drive — `audio_skid_now`'s value (or the identical smoothing of `slip_state` computed in the same place) — so the visual and audio channels are the same signal and can never disagree about whether the tires are sliding. Amount follows that drive, gated per tire by `wheel_load` as FP58 built it (loaded tires smoke, unloaded don't), at all four patches with the fronts first-class — in a turning slide the fronts are the tires the driver can see working.

**Construction changes species.** The streak sheet is convicted: kill the fast streaming along the wake vector. Skid smoke BOILS at the sliding patch and EXPANDS: puffs born at the patch with low relative velocity (roughly keeping pace with the car, not racing along its wake), growing fast and large, rising around the fenders into the forward periphery while the slide lasts, thinning as the drive falls. Target read is the reference photo (`research/tire-smoke-reference-front.jpg`) translated to cornering: dense white mass present at the front of the car, in the driver's airspace, for exactly the skid's duration. The soft billboard sprite may stay; its motion law is what changes. If the billboard family cannot boil without streaking, say so and change construction inside this item — the read is the requirement, not the technique.

**The spin term comes OUT of the smoke drive.** FP58's `maxf(slip, wheelspin)` at the rears is removed from the smoke channel (the spin AUDIO voice is untouched). Smoke at idle, at launch, on the crane: zero, gated exactly as stage 74 holds today — its terms are re-pointed at the new drive, teeth re-verified.

## Proof standard (standing, from FP58's conviction)

- The proof drives ORDINARY cornering at the skid threshold — the regime in Chris's own video (Track 01 or the ribbon, working pace, pursuit steering through the production input path) — NOT a sustained full-lock slide. Dense seat frames (10+ fps) across two or three skid events, with the skid gain logged beside the frames: each audible-skid event shows smoke in the forward airspace, and frame ranges with skid gain at zero show none. The sync log line is the conviction instrument: smoke amount vs `audio_skid_now`, sampled together, correlation stated as numbers.
- A standstill or locked-slide proof is not evidence and will be returned.

## Protected

- Zero physics/drive change; the skid audio itself untouched (drive, gains, smoothing); stage-54 audit digit-identical to FP58 (185.4 / 91.7) or deviation convicted and disclosed.
- Flames, terrain, world — untouched. FP58's load-gate plumbing is reused, not rebuilt.
- Particle budget stated; if the boil costs more than FP58's 224, the report says the number plainly.

## Verification shape

- Timeboxes on every run; total budget 2 hours; commit what's proven inside it. Order: drive re-point + construction change → the driven proof → ONE full smoke run → API guard → render proof (standing pair expected).

## Report

Trimmed: the drive source named (one sentence), the construction change (one sentence), the sync numbers from the driven proof, frames named, budget, gates, commit. Close with the judging line — smoke present exactly when the skid sings, in real cornering — as the seat's call.
