# STUNT CAR VR — Spec v0.1 (DRAFT for Chris's verdict)

*One-page spec + DE test plan. Drafted 2026-10-26 in the Stunt Car chat from the Idea Hub decisions + Chris's brain dump that morning; decisions continued through item 16 (controls, wheel character, multiplayer, lean experiment, prep reward, Quest ratification, comfort policy). **BUILD GO GIVEN by Chris 2026-10-26 ("Thunderbirds are go") — DE Test 1 is building.** The duel was not formally parked (Chris never chose that option). Status tags: **LOCKED** = Chris's decision · **TENTATIVE** = floated, not settled · **OPEN** = needs Chris's call.*

## The game in three seconds

Geoff Crammond's *Stunt Car Racer* (1989) in VR: cockpit view, a ribbon track on stilts over empty sky, one rival, rationed boost — and every fall ends with you dangling in your car under a drone, working your cockpit while you sway, waiting for the right moment to drop. Reads instantly to anyone; the VR adds the truth of the height.

## Platform — Quest-native. RATIFIED (Chris, 2026-10-26: "Yes on quest")

- **Target: standalone Quest (Quest 3 first, 3S-compatible), Godot + OpenXR.** The priority call for this project *is* the demographic — "much bigger demographic, better chance of success" — and that audience has no gaming PC. PCVR would test the wrong product.
- This game is unusually Quest-shaped: the original is *sparse* — one ribbon, empty sky, **one** opponent per race. Low geometry, physics budget spent on the car, not the scenery.
- Porting down from PC later is the classic failure path. Build to the Quest budget from day one; the DE test runs standalone so the first verdict is on the real target — DE: prove the path *in the actual system*.
- PC is still used for development iteration, never for the verdict build.

## Locked design (Chris's decisions)

1. **Cars: Odd Rods look, no monsters.** Exaggerated hot rods — blowers taller than the car, absurd proportions, names lettered like card titles. **LOCKED (corrected):** Chris is *not sold on monsters* — creature drivers and the "monster hands" cockpit idea are **out unless he revives them**.
2. **Car selection is required and COSMETIC ONLY.** Every car drives identically — same physics, same handling. Selection is identity, not mechanics. Crammond's skill-only purity intact.
3. **Track designer is required.** Build elevated ribbon track in space, by hand in VR. A **feasibility ghost** drives your line at speed and proves whether jumps land — the designer never lies about physics.
4. **The lift must be FELT.** The recovery is not a fade or teleport. You hang on lines under the **drone** (crane updated to drone — LOCKED), rocking and swaying, and the sway is *in your view* — the Star Wars trench / Falcon turret standard: the camera is subject to the motion, not watching it.
5. **The lift is prep time.** While you dangle, you prep the car in the cockpit — pilot-style, flipping real switches with your hands while the car rocks. **TENTATIVE extension:** the prep is a randomized/changing puzzle, and how well you do influences performance after the drop. **Reward DECIDED (Chris, 2026-10-26): good prep gets you a little boost at the start** — the moment you drop and get underway. Small and earned, one clean variable, not a shop. (Hal's reading: this applies at the Drop Start and at recovery restarts alike — Chris can split them. Boost-meter credit vs a brief surge off the drop is test tuning.)
6. **Drop Start, Chris's version.** The race starts with you swinging above the start line. *You* time the release, and a flat four-wheel touchdown is the good start. (Better than the original: its start drop was automatic on a random timer; timed release was only in the mid-race recovery.)
7. **Damage is visual carnage.** No crack-meter, no HUD bar. Your car visibly wrecks in front of you — crushed, bent, shedding pieces — worse with every hard landing and every fight.
8. **Bumping is sumo.** Car-to-car contact has real mass: sustained pushing, leaning, grinding. Putting a rival off the ribbon is *earned*, never a tap.
9. **Season mode with rivals.** A league spine, not standalone time trials: recurring rival drivers you meet again across a season. (The original's shape is the template, confirmed by Chris from the game itself 2026-10-26: 4 divisions × 3 named caricature rivals — Div I: Hot Rod, Whizz Kid, Bad Guy · Div II: The Dodger, Big Ed, Max Boost · Div III: Dare Devil, High Flyer, Bully Boy · Div IV: Jumpin' Jack, Road Hog, Jaklar — promotion/relegation between them, its tracks per division as listed in item 12's sources. The original also had a **practice mode** — that belongs in our structure too; Test 1's on-demand lift button is its seed — and **link multiplayer**, which maps to our later add-on, item 14.)
10. **Randomized track mode. TENTATIVE-hard:** Chris flags it himself as difficult; the whole trick is guaranteeing a generated track is completable. Same answer as the designer: generation inside the car's physics envelope, validated by the feasibility ghost before a human ever sees it.
11. **Track boosts & unboosts, F-Zero-style — OPTIONAL FEATURE.** Speed pads and sap pads in the track surface, distinct from the car's rationed boost. The feature itself can be switched off; the core game never depends on it.
12. **Track vocabulary, expanded carefully.** Original (verified): ramps, steep climbs/descents, banked corners, jumps, gaps/chasms, stepping stones, drawbridge — *no loops, no oil slicks*. New, all **TENTATIVE**: hazards/traps (including an oil-type hazard that can appear/accumulate as a race goes on), quicker routes / shortcut lines, and **loops — only if they work** in physics and in the stomach.

13. **Controls: a wheel you grab. LOCKED as the starting scheme (Chris, 2026-10-26):** both hands on a virtual wheel, turned physically — "let's start with" a grab wheel, so the DE test judges it and it can be revisited on feel. It makes the car a physical object and sets up the lift contrast: hands *on* the wheel driving, hands *off* it working the cockpit while you dangle. **The wheel itself has character (Chris, 2026-10-26):** each car gets its own wheel — different shapes, designs, and materials — because in cockpit VR the wheel is the part of the car's identity you're actually holding the whole race. Per the cosmetic-only rule this is look/material character, not a handling difference (flagged: Chris can override). Sub-point still open for test tuning: throttle/brake/boost mapping while both hands grip (the original was accelerate/brake on the stick, boost on fire).

14. **Multiplayer is a later add-on. LOCKED (Chris, 2026-10-26):** v1 is a single-player season against AI rivals. Multiplayer arrives later as an add-on, not a launch feature — don't preclude it in the architecture, but spend nothing on it in v1 scope.

15. **Lean-for-traction — EXPERIMENT, approved for the DE test (Chris, 2026-10-26).** The player's physical lean into a turn transfers weight and buys traction — the counterplay for holding a fast banked corner. Rules: (a) **bonus, never required** — every corner is makeable sitting upright; (b) read as input only, the game adds **no camera roll** of its own; (c) **symmetric** — lean the wrong way and grip drops; (d) **small** — a few inches of head/shoulder shift, seated. It lives or dies on Chris's Test 1 verdict at the banked corner (lean on vs off).

16. **Comfort policy: this is a stomach-churning game — to a certain extent. DECIDED in principle (Chris, 2026-10-26).** The churn is the point, not a defect to sanitize out: full sway, real drops, view in the motion. What Test 1 calibrates is only where "a certain extent" ends — the line past which churn turns into sickness — judged by Chris in the headset. The cockpit frame stays the anchor. (Whether a reduced-motion option exists for other players is a commercial call for later, not a design compromise now.)

## Open decisions

- None outstanding. Every fork raised during drafting has been decided or assigned to Test 1's verdict.

## DE TEST PLAN — "Drop & Dangle" (Test 1)

*Start low, cheap, short. One track, one car, no season, no designer, no menu chrome. This test proves the path; it is a throwaway feel prototype, not the game.*

**Build:** Quest-native APK (Godot/OpenXR). One placeholder Odd Rod car, grab-wheel steering, cockpit with working switches, rationed boost, hard-landing damage (basic dent + smoke only). One ribbon track, ~60-second lap: start straight → steep climb → banked corner → gap jump → descent → finish. Empty sky, ground far below. One drone.

**The run you judge:**
1. **Drop Start** — swing above the line, time your release, land it flat or don't.
2. **Drive the lap** — climb, bank, the gap jump, the descent. Run the banked corner twice: lean experiment OFF, then ON, and compare.
3. **Drone recovery, on demand** — a practice button triggers the lift whenever you want it (no waiting on a lucky fall to judge it): sway on the lines, flip the prep switches while dangling, time your own drop back onto the ribbon.

**What you're judging (your verdict, in the headset — no test counts):**
- Does your stomach drop on the jump and the descent?
- Does the height *read* when you look down?
- Is the Drop Start timing a skill moment or an annoyance?
- Does the dangling sway feel physical — and where is your comfort line after ~10 minutes of it?
- Is prepping switches while swinging fun, or fiddly?
- Does the car land with heft — mass, not float?
- Lean experiment: does leaning into the bank visibly hold a line you lose sitting upright — and does it feel like *driving*, or like a party trick?

**Pass:** you want another lap immediately, and comfort holds. **Fail signals:** sickness, floaty car, dead-feeling lift — any one kills the premise cheaply, which is the point of testing it first.

**Deliberately NOT in Test 1:** rival/sumo (Test 2, with one AI rival + full visual carnage), loops (Test 2 prototype, only if Test 1's motion works), season, designer, random tracks, boost pads, car selection beyond the one car.

## Later backlog (post-Test 1 — NOT in any current build)

- **Seat adjust buttons** (Chris, 2026-10-26, future feature request — his note: "stole this idea from VTOL," VTOL VR's fully physical cockpits): physical controls on the side of the cockpit/seat that let each player trim their seated position themselves — the anchor gets you into the car, the seat adjust fits it to your body. Reached for in the world like a real car's seat controls, not a settings menu.
- **Component cars + creator screen** (Chris, 2026-10-26: "if the cars were somehow made of components, players could mix and match their own design in a creator screen"). The evolution of item 12's car selection: instead of picking a finished car, the player assembles one from a kit — in the Odd Rods language: body shell, blower/engine stack, wheels, exhausts, wing, paint, and the steering wheel as a component (which fits item 13's wheel character). Cosmetic status: **just cosmetic** for selection and wheels (Chris). For COMPONENTS he is now exploring an amendment (same day, tentative): **cost-versus-design trade-offs** — a part may carry a mechanical effect, but every advantage is bought with a disadvantage elsewhere; no free lunch, no strictly-better build. His example: spikes on the wheels for a bit of extra damage (plays straight into sumo bumping + visual carnage), at the expense of something else (grip / mass / top speed are the natural currencies). UNSETTLED — leaning trade-off, not decided.
- **Weather effects** (Chris, 2026-10-26, while Test 1 was building: "later: weather effects"). Interesting because weather here is physics, not wallpaper — wind would push the dangling car and the drone, rain would change traction. And in the set: **snow, "for the masochists"** (Chris) — the hardest tier, worst grip on a rail-less ribbon in the sky. Parked until Test 1 is judged.

---
*Sources inside the project: Idea Book entry "Stunt Car Racer in VR"; brain-dump items #1–13 + corrections, Stunt Car chat, 2026-10-26; original-game facts (8 tracks, Drop Start, Press Fire recovery, crack/hole damage, no loops, no oil) verified against the manual and references that morning.*
