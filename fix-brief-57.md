# FIX BRIEF 57 — THE WORLD, AND THE ENGINE'S NEW VOICE

Base: `9aff3d8` (FP56, verified remote). Stamp on ship: FP57 · 2026-11-10.

Three items, one pass (Chris's tap, 2026-11-10): (A) the world — terrain that meets the track, a solid base instead of stilts, landscape objects; (B) flame jets at the engine on shifts, replacing the exhaust smoke channel; (C) smoke moved to the tires, synced to skid and spin. Sequencing law behind the pass (Chris): crash play-out comes AFTER this — "no point crashing if there's nothing to crash into."

Verified ground truth (Hal, code read 2026-11-10): the desert floor/hills/mesas exist since FP9 but sit ~85–95 m below the ribbon as pure scenery; the fall is caught ~13 m below the ribbon and the car never lands; the track mesh is a 0.45 m box section on merged stilts; `_build_environment()` holds sky/fog/desert, `_build_track_meshes(d)` builds ribbon+stilts per track; the FP55 shift event already fires (`vib_blip = 1.0`, main.gd ~10814) and the FP44 shift audio blip exists; spin smoke emitters live at the rear patches since FP36 (`spin_emitters`, driven by the telegraph); the FP55/56 exhaust channel is `exhaust_emitters` at the side-pipe tips.

## ITEM A — THE WORLD

**Character ruling (Hal's recommendation, carried into the brief; Chris folds a different call in with his word if he wants): the ground meets the road where the road is low; the high country stays honestly airborne on real structure.**

- Terrain: a sculpted ground surface under each track that RISES to meet the ribbon where the ribbon runs low — earth shoulder/apron under and beside the road there, falling away with distance into the existing desert. Where the road flies high, the terrain stays down in the valley and the gap is honest. The terrain's height logic derives from the track's own station frames (the ribbon's height field), not a hand-authored heightmap per track — all four track slots (Track 01, the ribbon, the Feature Lab, the funlab) get the world by the same rule, or the report states plainly which got it and why the others differ.
- The base: where the road is airborne, the stilts are replaced by structure that reads SOLID from the seat and from the crane dangle — piers/abutments with real section, spaced like engineering, not a forest of poles. The loop's footing pad (FP47) is the existing precedent for how structure meets ground.
- Landscape objects: desert forms near the driving world — rock outcrops, mesas at mid-distance, boulders — plus the trackside furniture family deepened where it already exists (gantries, crane posts). Objects are placed clear of the road corridor by measured clearance (the FP49/FP50 corridor discipline applies: audit placements against the built corridor, zero intrusions, clearances stated). These objects are VISUAL ONLY in this pass — no collision, no physics change; they are what the future crash play-out will meet, and the report must say so plainly so nobody mistakes them for live obstacles.
- Sightline and visibility law holds: nothing new may occlude the road ahead within the honest-sightlines envelope on any track; the fog/colour separation work (FP12/18) is protected — terrain tones must keep the ribbon readable at distance (measure, don't eyeball: the desert/ribbon captures regenerated).
- Performance: the world is a handful of large merged meshes, not a node forest — state primitive/node counts before/after, Quest budget in mind.

**Pass condition (Item A):** from the seat and from the crane dangle, the track sits IN a landscape: ground under the low road, structure under the high road, desert forms around — and the stilts read is gone. Before/after capture pairs: `desert_below_view`, `circuit_wide_view`, plus one low-country station shot the builder chooses and names.

## ITEM B — FLAMES ON SHIFTS (the exhaust channel's replacement)

- The FP55/56 exhaust smoke channel RETIRES: emitters, ratio curve, its stage-74 terms — removed whole, not dialled to zero. (The side pipes and zoomie parts stay — they're the car; only the blob system dies.)
- NEW: little flame jets at the engine — short, bright, directional bursts out of the header/zoomie exits at the block, keyed to the EXISTING shift event (the `vib_blip` firing) — the visual twin of FP44's shift blip and FP55's shift shudder: one event, three channels (sound, shake, flame). Chris's words: "little flames jetting out of engine block during shifts."
- The original's precedent (his Amiga film, 2026-11-03): boost was visible as exhaust flames — IF the boost state is cheaply available at the same hook, a boost flame state (sustained while boosting) rides the same system; if it complicates the pass, shifts only, and the report says boost flames are the named follow-on. Builder's honest call, disclosed either way.
- Form: cones/jets with a hot core (white-yellow to orange), lifetimes in the tens of milliseconds-to-tenths, scale little — the pass condition is a PERIPHERAL FLASH the driver registers without looking, impossible to mistake for smoke. NOT spheres, no soft particles: hard-edged little jets matching the game's flat-shaded language. If a particle system is used, its draw pass is a stretched jet form, not the retired sphere construction.
- Gating: DRIVE only, exactly as the retired channel's stage-74 contracts held — no flames on the crane, none with a dead engine. Stage 74 is REWRITTEN for the new channel (flames gated; tire smoke's own terms per Item C), its teeth re-verified (force the gate open in a scratch copy, watch it fail).

## ITEM C — SMOKE AT THE TIRES, SYNCED

- Smoke's job is now the tires' story: emitted at the CONTACT PATCHES, driven by the states that are actually slipping — wheelspin (the FP36/FP44 spin state) and lateral skid (the slip state the telegraph already computes). "If it syncs up with skidding" is the pass condition: smoke amount follows the slip/spin magnitude, starts and stops with it, no idle/throttle/exhaust terms at all.
- Placement/visibility: patches are behind/below the seat (the FP42 lesson: behind-the-car smoke is invisible). The builder measures what the seat actually catches — front patches in yaw (the original showed front wheels at the frame edges in slides), rear plume drift into the periphery — via staged captures at working slip, and states the measured read. If patch smoke provably can't reach the driver's eye, the report says so plainly instead of faking a channel (the fallback question — glance/mirror read — is Chris's, not this pass's to invent).
- Construction: the blob verdict applies here too — the retired sphere construction does NOT carry over. Use a flat, soft-edged form in the game's language (flat-shaded low-poly puffs are acceptable IF they read as smoke in motion at the capture; the FP56 lesson is that stills flatter nothing — judge from the staged-slip capture sequence, dense frames, not one frame).
- The dust emitters (per-wheel contact dust) are a separate existing channel — do not conflate; if smoke and dust fight visually at the same patch, say so in the report.

## Protected (all items)

- Zero physics/drive-model change. The fall/catch and recovery logic UNTOUCHED (the world is visual; the car still never lands on terrain in this pass — crash play-out is a later pass and will change the catch deliberately, with its own brief). Stage-54 audit digit-identical to FP56, or any deviation convicted and disclosed.
- FP55 whole: the 39 parts, sightline measurement, vibration channel. FP56's dials die with their channel — nothing else of FP56 exists.
- The corridor/intrusion audits (FP49/50 discipline) run for every placed object and terrain feature near the road.
- No new controls; commands list untouched. Audio teardown discipline untouched (no new audio expected; if flame audio is added, it joins the existing latched teardown and the report says so).

## Verification shape

- Timeboxes on every run; total budget 3.5 hours; commit what's proven inside it. If Item A overruns, A ships alone only with the report saying B/C wait — do not silently halve an item.
- Order: (1) Item A build + capture pairs; (2) B (retire + flames) with a staged-shift capture sequence (dense frames across a shift); (3) C with a staged-slip capture sequence; (4) full smoke suite ONCE on the final tree; (5) API guard; (6) render proof (standing pair expected); (7) strips as affected.
- Stage-74 rewrite is part of the pass, not an afterthought: the suite's count changes are flagged in place with reasons, as FP54's amendments were.

## Report

Trimmed, in the standing shape: what Item A's world is made of (terrain rule, base treatment, object census + clearances), before/after captures named; Item B's hook (shift event, boost state in or named follow-on), the flame form and its staged-shift frames; Item C's sync source (which slip/spin signals, measured start/stop), the seat-read measurement; stage-54 audit line; gates; commit. Close with the honest sentence: the world is visual until the crash pass gives it physics — Chris judges the look, and the play-out brief gets written against what he sees.
