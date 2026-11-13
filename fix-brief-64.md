# FIX BRIEF 64 — THE SMOKE GETS A LIFE

Base: `dbb95d2` (FP63, current remote HEAD). Stamp on ship: FP64 · 2026-11-13.
Owner's verdict on FP59's smoke (2026-11-11, sync confirmed in the wild): "it looks like it just kind of sits there… some different shades would help give it depth." His go for this pass: 2026-11-13.

## The drive is PROVEN — do not touch it

The smoke's drive (`audio_skid_now`, read in `_update_telegraph`, per-tire `wheel_load` gate, spin excluded) is confirmed from the seat: smoke when it should, synced to the skid sound. This pass changes PRESENTATION ONLY — where puffs are born, how they move, what shade they are. The stage-54 audit is expected digit-identical to FP63's reads (circuit 213.9 / ribbon 101.8); any movement is a disclosure, not a shrug.

## Item 1 — the cloud stops travelling with the car

History, so it isn't re-litigated: FP58 emitted in world space with walking-pace drift and NO inherited velocity — the smoke existed only behind the car (convicted). FP59 fixed visibility by emitting in CAR space — and the cloud now rides along with the car, which is exactly the "sits there" the owner named. The correct form is the third one: **emit in WORLD space, birth velocity = the patch's world velocity at that frame, then air drag** — a puff is born moving at the car's speed and slows in the air, so from the seat the cloud boils past and falls behind while the car drives through and out of it. Keep FP59's boil character at birth (rise, spread, buoyant lift) composed on top of the inherited velocity, not instead of it. Churn: widen the angular-velocity variance and make growth asymmetric (puffs don't all swell on the same curve), so the mass reads as boiling, not as copies of one stamp.

## Item 2 — shades for depth (AMENDED 2026-11-13 16:15, owner's reference image)

One flat white is why it reads flat. Per-particle shade variation across the cloud: bright white at the core births to mid-grey at the edges and age — neighbouring puffs visibly differ. Same texture family as FP59's soft puff unless the shade mechanism needs a ramp — argue it in the notes if so.

**AMENDMENT — the colour mix is the owner's, from his reference image** (`~/workspace/stunt-car-vr/research/smoke-colour-reference.jpg`, a Niagara chimney-smoke plume; his words: "thats the type of color mix i see in my head"): the plume reads as a LIT VOLUME — a bright warm-white core on the lit side, shading through soft neutral greys, into **cool blue-grey / teal-grey in the shadowed mass and older puffs**. The earlier "no new hues" line is superseded: the cool shadow tint IS part of the mix he wants. So the ramp runs warm-white → grey → cool shadow grey, keyed to a puff's age/shadow side as the mechanism allows. The image's structure also backs Item 1's churn: big turbulent billow, puff sizes varying widely, nothing stamped twice.

## Proof standard (standing law)

Driven, not staged: a slide DRIVEN through the production input path at speed (the ribbon banked corner is the proven site), seat-view dense tiles. Standstill/burnout proofs are banned as cockpit evidence. The sync re-proves as numbers on the driven run (smoke present iff the skid sounds, peaks tracking) — the drive is untouched, so this is a regression check, not a research project. Report the slide-ENTRY read honestly: the diagonal grain at entry was still visible in the FP59 video; if the churn softens it, say how much from the tiles; if it doesn't, say that.

## Rails

- No physics, no drive-signal, no onset/gate changes. Presentation diff only.
- The commands list: unchanged (no new commands).
- Stage 65/74 and capture terms that assert smoke behaviour get re-pointed at the new construction, flagged in place — never silently.

## Budget and report

- 2.5 hours; timebox every run; standalone replication of every check the diff touches is mandatory; the full suite runs if the budget honestly holds it, else disclose exactly what ran.
- Trimmed report: what changed in the cloud's motion and shading (plain terms), the driven tiles' read, sync numbers, audit line, gates, commit.
