# FIX BRIEF 55 — THE CAR: an Odd Rod, built from parts

Base: `24117eb` (FP54 `4c14e76` + the spec filing; game code is FP54's). Stamp on ship: FP55 · 2026-11-09.

The want, on record since 2026-11-01 in Chris's words: a car that doesn't look like *"a 5 piece lego set."* The placeholder is five boxes — white cube blower, black slab, orange wedges. This pass replaces it. His load for the pass (2026-11-09, complete in his words — "thats it"):

1. One hero car, built from **discrete parts**.
2. **Odd Rods proportions** — reference sheet on file: ~/workspace/stunt-car-vr/research/odd-rods-reference-sheet.jpg (7 Donruss cards: DEALER, FIREBIRD, PUSHIN INTO, NO HANDS, BOSS 429 + 2). The sheet's shared language: late-'60s muscle silhouette (long hood, short deck), rear tires MASSIVELY oversized with skinny fronts, jacked-up rear drag rake, hood cut for a blown motor, side pipes/zoomies, candy paint, chrome.
3. **View first** — his note on the sheet: "lets try to not obscure view too much with blowers and such." This AMENDS the old "blowers taller than the car" line: the induction reads big from outside; from the seat it stays out of the sightline.
4. **"Make it look powerful"** — the headline, his words.
5. **Engine vibration** — the engine felt in the visual channels.
6. **Smoke in the periphery** — exhaust smoke where the driver can catch it.

## Pass condition

From the crane view and the chase angles, the car reads as an Odd Rod — card proportions, blown, raked, candy — unmistakably more powerful than the placeholder. From the seat, the road view is as clear as it is today, and the engine's presence reaches the driver: a tremble he can see in the blower hat and bodywork, and exhaust smoke at the edges of his vision. Nothing about how the car DRIVES changes: this pass is presentation only.

## Item 1 — The body, from parts

- Rebuild the car body as discrete part meshes (the current body is procedural boxes in main.gd — `_box()` and friends under `car_body`; `nose_mi` etc.). Every part is a named node: body shell/panels, hood, fenders, the blower (case, scoop/hat, butterflies), intake, exhaust stacks/side pipes or zoomies, wheels (fronts skinny, rears huge) with tires, wing/spoiler if the silhouette wants it, chrome trim, cockpit surround. The parts list IS the deliverable's inventory: print it in the README entry — it is the carnage build's flying-parts inventory by construction, so parts must be genuinely separable nodes, not a merged mesh with part names painted on.
- Proportions from the sheet, honest to the physics: the car's footprint, wheelbase, wheel positions and ride height are PHYSICS (the drive model's contact patches and the suspension's story) — the visual wheels must sit where the model's wheels are and turn/steer with them (they already do; keep the contract). Visual tire WIDTHS and body overhangs are art: rears read massively oversized, fronts skinny, the shell raked (nose low, tail high) — rake is achieved in the BODYWORK's lines, not by tilting the physics body or moving the contact patches.
- Candy paint + chrome materials, in the project's existing material style. One hero car, one colour scheme — the builder picks from the sheet's palette and states it (the purples and the pea-green and the red all appear on the sheet; a deep candy purple or red reads "powerful" best against the desert — builder's call, stated, Chris repaints by verdict if he wants).
- **The sightline law, made measurable:** from the driver's eye position (the shipping camera, both view modes A and B), the blower/scoop/hat assembly must not intrude into the road view beyond what the current placeholder's hood line already takes. The render proof gains a driver's-eye capture with the new body, compared against the FP54 capture of the same framing: the road visible ahead must be no less. The blower can be TALL behind/around the sightline's edges and wide — the cards' drama — but its mass stays out of the central view corridor. State the measured intrusion (degrees or pixels of the forward view the assembly occupies, before vs after) in the report.

## Item 2 — Engine vibration (visual channel)

- A new engine-state vibration channel, PRESENTATION ONLY: driven by the engine's existing state (gear_rev / audio_rev, throttle, wheelspin) — an idle lope at rest (slow, uneven, the car visibly alive on the crane and at the drop), building in frequency and settling in amplitude with revs, with a harder shake under wheelspin and a blip-shudder on shifts.
- Where it lands: (a) the blower/scoop assembly trembles on its mounts (its own small offset, the classic blown-car tell — the hat shaking is THE Odd Rods idle image); (b) a fine buzz through the body shell; (c) the seat channel — extend FP44's shudder plumbing (SHUDDER_* exists, wheelspin-only today) so engine state adds its own component through the same body-node path. Amplitudes are the builder's to set and state; the discipline: visible in captures/proof frames as a tremble, never a judder that reads as a bug; at speed it should smooth into the car's existing motion, not sit on top of it.
- The audio side is OUT of this pass (engine/spin voices are shipped and judged separately) — this item is what the eyes get. Do not retune audio.
- Hard fence: zero physics contact. The vibration writes ONLY presentation offsets (the FP44 shudder's own-envelope/body-node-translation pattern is the precedent: it must not enter vf, the contact model, the carried frame, or any staged measurement). Stage 72's guard (below) is the tripwire.

## Item 3 — Smoke in the periphery

- Exhaust smoke emitted from the side pipes'/zoomies' exits — which sit at the car's flanks, in the driver's peripheral view from the seat — replacing/augmenting the current wheelspin smoke story (which lives behind the car where the driver never sees it; FP42's lesson, in the code's own comments).
- Events: idle puffs (irregular, loping with Item 2's idle), a launch bloom under wheelspin, shift puffs, and a hard-throttle haze. Rate/opacity follow the engine state; the smoke reads at the EDGES of the forward view from the seat — the render proof's driver's-eye capture under a staged launch must show smoke in frame periphery, not centre, not absent.
- Performance discipline: Quest-native is the shipping target — use the project's existing particle approach if one exists; if building new, keep counts modest and state them. No post-processing, no volumetrics.
- Smoke must obey the standing audio-era discipline's visual cousin: it dies with the car state that makes it (no smoke while hung on the crane, none in the hang, none after a wreck stops the engine state — wreck/engine-off states read zero throttle/rev inputs honestly).

## Protected

- The drive model ENTIRE: physics, contacts, suspension story, flight, crane, hang — untouched. Any measured drive behaviour change = the pass has leaked; fail.
- Stage 72 (the FP45 body-part guard): it audits every body part's local-transform behaviour (born from the turned-block conviction). The parts rebuild changes the inventory — re-derive the guard against the NEW parts list with the reason flagged in place, and keep its teeth: an uncommanded part rotation must still fail it.
- All smoke stages' staged numbers: the suite's drivers read physics, not paint — a green suite with moved staged numbers needs a conviction, not a shrug.
- The commands list: no control changes in this pass; if any presentation toggle is added (e.g. vibration off), it joins the in-game commands list in the same pass — prefer NO new controls.
- BUILD_STAMP → FP55 · 2026-11-09 (the suite regex-asserts it).

## Verification shape — DE

- Timeboxes on every run; hung run killed and reported. Total budget: 3 hours. Commit-what's-proven stop inside the budget.
- Order: (1) preflight; (2) the body build; (3) render proof with captures regenerated for real — MUST include: driver's-eye (both views if cheap) with the sightline comparison, a crane/hang view (the car reads Odd Rod hanging), a three-quarter chase view, an idle frame pair or strip dense enough to show the hat tremble (two frames at lope extremes), and a staged-launch driver's-eye frame with peripheral smoke in frame; (4) smoke suite (one full run); (5) API guard; (6) frame strips if touched.
- Dense frames rule for the tremble: sampled stills prove poses exist, not motion — the idle proof is a short dense strip across one lope cycle, frames traced, or it isn't proven.
- The report states plainly: art is Chris's verdict, not the proof's — the captures are evidence for his eyes, not a claim the car looks right.

## Report (when this pass lands)

Trimmed, in the Stunt Car chat only: the parts inventory (count + the list, short), the colour call, the sightline measurement before/after, the vibration channel's numbers (idle lope rate, amplitudes, what drives it), the smoke events and where they read from the seat, the captures that prove each, gates, commit — and what remains unverified until the seat judges (the look, the tremble's feel, the smoke's presence — all his).

## Named, NOT in this pass

- Carnage itself (parts DETACHING is the next build; this pass only makes them exist as parts).
- The crane dead-pause (confirmed ×3, roof landings): its own item; not folded in here.
- Brakes "a little more work": its own item, direction to be asked, not guessed.
- Rival CRAMMOND's car: later — he gets his own variant when carnage/season calls.
- Roster variants / car selection: cosmetic variants are later art; one hero car now.
