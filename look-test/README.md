# LOOK TEST — what Godot can actually do to our car

A throwaway spike, built 2026-10-27. **Not the game.** The game in
`../game` is untouched — this is a separate project that happens to
star the same car, on the same ribbon, over the same desert.

Why it exists: every build so far bought *feel* — the game runs the
Compatibility renderer with flat-shaded placeholder geometry, so
what you've been judging in the headset is a clay model. This scene
dresses the game's own subjects with Godot 4.7's full **Forward+**
renderer, so expectations can be calibrated against our own assets
before any look direction is committed.

## Run it (two steps)

1. **GitHub Desktop → Pull** (this `look-test/` folder arrives with
   the repo).
2. **Godot 4.7 → Import → select `look-test/project.godot` → Open**,
   then press **▶ Run (F5)**. With Virtual Desktop connected it
   opens in the headset.

That's it. No exports, no settings to change — OpenXR is already
enabled in the project, and the rig uses the same tracker pattern
as the game (plain `left_hand` / `right_hand`, `default` pose).

## What you're looking at

- You spawn **seated in the cockpit** at the game's exact eye
  anchor (0, 1.14, 0.05 in car space). Look around.
- **The seat is anchored, like the game.** The rig carries the
  game's seat-anchor correction (its Fix Pass 2/3): once your
  tracked head pose settles, a rigid offset lands your eye
  exactly on the anchor — your seated height no longer stacks on
  top of it and floats you over the car. (The first version of
  this package skipped the anchor and perched the driver a metre
  too high — the "high chair." Fixed 2026-10-27.) Virtual
  Desktop's own reset view does *not* do this; the anchoring is
  the game's job, and it happens automatically at spawn.
- **Which way is forward, at spawn:** the anchor also aligns
  your facing with the car's — but an automatic application
  refuses to bake in a turned head. If your head is more than
  ~25° off the car's forward when the pose settles, only the
  height/position half lands; the yaw half applies itself the
  moment you look back down the car. (Before this fix, a head
  held still but turned at spawn became "forward" for the whole
  session — the view sat ~45° off and nothing would shift it.)
  If the world ever sits rotated, look down the car and squeeze
  both grips (below).
- **Re-seat any time:** **squeeze BOTH grip buttons together** —
  that's the one you can't miss — or either controller's **menu
  button**, or **R** on the keyboard. A re-seat is explicit, so
  it uses standard recenter semantics: *where you are facing
  when it lands becomes forward.* Look where you want forward
  to be, hold still for a beat, then re-seat. The Meta/system
  recenter does **not** do this — the offset lives in the game,
  above the runtime's reference frame.
- **C key** (or the **right controller's A button**) toggles to a
  slow **outside orbit** — the rig itself steps out of the car and
  circles it, so you can judge the car and ribbon from off-board.
  Same input toggles back. The thumbstick clicks used to fire
  this by accident; they now do nothing.
- No headset? It runs on the desktop too: mouse looks around the
  cockpit, **C** toggles the orbit, click re-captures the mouse,
  Esc releases it.
- There is **no driving**. Stillness judged well beats motion
  judged badly; the driving model stays in the real game.

The scene: the Odd Rod — part-for-part the game's car layout (same
boxes, same positions, body 1.80 m wide, wheel track 1.56 m) —
re-dressed: candy paint with metal flake under clearcoat, a chrome
blower, grain-bumped rubber on steel rims, vinyl dash and seat,
the wood-rimmed grab wheel. (Two honest additions the feel build
never needed: a seat, because the driver normally *is* the seat,
and exhaust tips.) It's parked on the opening straight of a ribbon
stretch built the game's way — 12 m wide box section on stilts —
running into a 16 m climb and a long banked curve, over the desert
floor 60 m below, hills and mesas beyond. A "DROP START" gantry
stands 20 m ahead.

The dress: procedural sky at golden hour; a low warm sun with
real-time shadows; image-based light and reflections from the sky
(the chrome mirrors that sky — at golden hour it reads pale gold,
not mirror-bright; judge it in the headset, not from the stills);
ACES tonemapping;
exponential haze with sun scatter; glow; SSAO and SSIL for contact
grounding; a whisper of volumetric fog; dust motes hanging in the
light around the car.

## Captures

`tests/` holds three frames rendered from this exact scene
(cockpit / external three-quarter / wide vista) — useful for a
first look without putting the headset on, though the headset is
the real judge, as always.

## Honest frame cost

Measured on the vista framing (1280×800, this scene, full
dressing): **101 nodes, 219 draw calls, 82,272 primitives** —
`tests/capture.gd` re-measures and prints this on every run.
(The bundled capture frames were rendered on a software Vulkan
driver, since the build sandbox has no GPU; the scene itself is
unchanged, and a real GPU renders it interactively.)
Against the real game's circuit (~124 nodes / 53 calls / ~58k
prims in Compatibility), the geometry here is the same weight
class; the extra draw calls are the shadow cascades and the
Forward+ passes, and the real cost of this look is *per-pixel*
(PBR shading, screen-space effects, volumetrics), not geometry.

What that means for the actual game, plainly:

- On a PC GPU (your PCVR route) this class of look is cheap.
- Quest-native would NOT run this scene as-is: SSAO/SSIL,
  volumetric fog and 4-split shadows are PC-class features. A
  Quest look would keep the same art direction — sky, sun, PBR
  materials, ACES — and shed the screen-space layer. That trade
  is a later decision, made with numbers, not in this spike.

## If you re-run the captures

```
xvfb-run -a Godot_v4.7 --path . --script tests/capture.gd
```
(add `-- --lt-lite` to drop SSAO/SSIL/volumetrics for
software-rendered runs; a real GPU doesn't need it).
