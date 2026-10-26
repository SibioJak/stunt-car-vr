# Crammond Notes — Stunt Car Racer original-model study

**Purpose:** calibration knowledge mined from the converted Stunt Car Racer source
(`~/workspace/stuntcarracer-ref`, fluffyfreak/stuntcarracer — a PC conversion of the
Amiga original using Crammond's physics algorithms, the original track data, and the
disassembled Amiga original in `Reference only/StuntCarRacer.s`).

**STUDY ONLY.** Nothing here is copied into our game — no code, no track data, no
samples. These notes describe what the original model *does* so our own VR
implementation can match its behaviour honestly.

**Citation convention:** `file:line` refers to the reference repo. Values are quoted
exactly as they appear in the code. Anything not determined is flagged
**[NOT DETERMINED]** rather than guessed.

---

## Q1 — Width ratio, and whether tracks vary in width

### The constants

| Quantity | Value | Source |
|---|---|---|
| Road width `ROAD_WIDTH` | `0x0180` = **384 units** | `Car Behaviour.cpp:82` |
| Car physics width `CAR_WIDTH` | **64 units** | `Car Behaviour.h:8` |
| Car physics length `CAR_LENGTH` | **128 units** | `Car Behaviour.h:9` |
| Drawn car width `VCAR_WIDTH` | 162 (drawing coords) | `Car.h:9` |
| Drawn car length `VCAR_LENGTH` | 256 (drawing coords) | `Car.h:10` |
| Drawn car height `VCAR_HEIGHT` | 162 (drawing coords) | `Car.h:11` |
| Segment length | 256 units | piece templates, `Track.cpp:969–1148` |
| Piece (cube) size | 2048 units | `Track.h` (`CUBE_SIZE 0x04000000`, `LOG_CUBE_SIZE 26`) |
| `PC_FACTOR` | 2 | `Track.h:13` |

**Physics wheel sample points:** the physics samples the road at only **three**
points — FRONT_LEFT, FRONT_RIGHT, and a single REAR point
(`CalculateRoadWheelHeights`, `Car Behaviour.cpp:~1217–1265`). Front wheels sit at
±`CAR_WIDTH`/2 = ±32 lateral and +`CAR_LENGTH`/2 = +64 forward; the rear point at
−64 (`CalculateWheelXZOffsets`, `Car Behaviour.cpp:1076–1089`). So the physics
wheel track is 64 units wide.

**Ratios:**

- **Road / physics wheel track = 384 / 64 = exactly 6.0 car-widths.**
- The *drawn* body is wider than the physics track: the header's own arithmetic
  ((27+27) × 384/256) × 2 = 162 drawing units implies a visible body ≈ 81 world
  units wide (`Car.h:9–11`), so **road / visible body ≈ 384 / 81 ≈ 4.74**.
- Drawn length 256 drawing units = exactly 128 world units, matching physics
  length; the width discrepancy (64 physics vs ~81 drawn) is real in the source —
  the visible car overhangs its physics footprint laterally.

### WIDTH.REDUCTION is NOT a width variation

`StuntCarRacer.s:27–28`:

```
ROAD.WIDTH      equ $180
WIDTH.REDUCTION equ 65536/(ROAD.WIDTH-1)     ; = 65536/383 ≈ 171
```

It is a fixed-point reciprocal used to normalise a lateral position 0..383 down to
0..255 for the height routine (asm comment at `StuntCarRacer.s:~9199`: "Reduce
wheel.road.x.position from (0 - road width) to (0 - 255) and save it"). Every piece
template stores the same WIDTH.REDUCTION byte. It encodes the *one* width, not a
per-section width.

**There is no width field in the track data at all.** The per-track file layout
(`ReadAmigaTrackData`, `Track.cpp:2661–2698`) is: piece count, start piece, piece
X/Z positions, piece angle+template bytes, left/right Y-profile IDs, left/right
overall Y shifts, boost reserves. Width comes only from the piece *template*
geometry. Template number = low nibble of the angle/template byte
(`Track.cpp:1333`).

### Per-track width census (all eight tracks)

Measured two ways: (a) every row of every piece-template XZ array in
`Track.cpp:969–1148` spans **383.3–385.0 units** — a constant 384 within rounding,
for straights, curves, and diagonals alike; (b) template census parsed from each
`Tracks/*.bin` (804 bytes each):

| Track | Pieces | Template mix (template: count) | Width, every section |
|---|---|---|---|
| LittleRamp | 44 | 0:24, 1:1, 3:1, 4:2, 6:3, 7:3, 10:10 | **384** |
| BigRamp | 44 | 0:24, 1:1, 3:1, 4:2, 6:3, 7:3, 10:10 | **384** |
| HighJump | 52 | 0:40, 1:1, 3:1, 4:2, 6:3, 7:3, 10:2 | **384** |
| HumpBack | 53 | 0:41, 1:2, 4:2, 6:4, 7:4 | **384** |
| SteppingStones | 56 | 0:48, 6:4, 7:4 | **384** |
| DrawBridge | 78 | 0:62, 6:8, 7:8 | **384** |
| RollerCoaster | 78 | 0:62, 6:8, 7:8 | **384** |
| SkiJump | 40 | 0:15, 1:3, 3:1, 4:4, 6:3, 7:3, 10:11 | **384** |

Template key (`Piece_Templates`, `Track.cpp:1166–1180`): 0 = straight (8 segments),
1/3 = curve right/left (8), 4 = diagonal (13), 6/7 = curve right/left (9),
10 = diagonal (11). **Templates 2, 5, 8, 9 are referenced by no track and have NULL
geometry in the conversion** — unused slots.

**Width variance across the entire game: zero.** No track, and no section of any
track, is wider or narrower than any other. What varies per track is length
(40–78 pieces), elevation profile, and curve/diagonal mix. The two "special"
tracks do not change width either: DrawBridge's moving section (pieces ~48–52)
animates only Y (`Track.cpp:~2470–2500`), and no special-case width code exists
for SteppingStones — its gaps are longitudinal (missing surface along the
direction of travel), not lateral narrowing. *(The gap encoding itself was not
traced line-by-line; flagged as inference from the absence of special handling.)*

### ✅ VERDICT — article claim vs. user memory (cross-check)

The Generation Amiga article claims: *"Track widths were deliberately narrow,
increasing gameplay tension while also reducing rendering complexity."*

**The code does not support "deliberately narrow."** The road is exactly **6.0× the
car's physics width** (≈4.7× the visible body width) — by racing-game standards
that is generous, with room to manoeuvre, correct a slide, and pass. The user's
memory ("wide and massive… room to manoeuvre") matches the ratio.

Both can be partly true in different frames: the road *is* a narrow ribbon in
absolute terms — a single constant-width strip suspended in the sky with void on
both sides, and falling off is the core punishment. But there is no per-section
narrowing, no width tuning per track, and at 6 car-widths the ribbon is not narrow
*relative to the car*. If any one track seeded the "wide and massive" memory, the
data can't distinguish it by width — the plausible carriers are the long elevated
all-sky ribbons (RollerCoaster / DrawBridge, 78 pieces, 79% straights) where the
full 384 units reads uninterrupted, versus the kinked SkiJump (40 pieces, 27%
diagonals) which *feels* tighter purely from geometry changes, not width.

**For our build:** one constant road width, 6.0× car physics width. Do not vary
width per section — the original never does.

---

## Q2 — Suspension model

There is no spring-mass suspension in the modern sense. The model is: **sample the
road height at 3 points, compute per-wheel penetration, and push back with a
proportional + derivative (PD) force.** Everything else follows from that.

### Road height at a point

- The surface is defined only at segment boundaries: each piece has 8–13 segments
  of 256 units, with a left and right Y at each boundary (per-piece Y profiles plus
  overall left/right Y shifts, applied in `ConvertAmigaTrack`,
  `Track.cpp:~1448–1475`). A segment whose |Δy| ≥ 640×`PC_FACTOR` is coloured black
  (a visible step warning), `Track.cpp:~1490`.
- Height inside a segment is **bilinear interpolation** over the four corner
  heights. Amiga original: `calculate.road.surface.height`,
  `StuntCarRacer.s:9448`, with lateral/longitudinal fractions in **0..255** steps
  across the patch. PC conversion: `CalculateWorldRoadHeight`,
  `Car Behaviour.cpp:~1380–1650`, same method with fractions in `SURFACE_SIZE`
  steps — `#define SURFACE_SIZE 1024`, `LOG_SURFACE_SIZE 10`
  (`Car Behaviour.cpp:84–85`), with the code's own comment that the Amiga used 256
  and 1024 is "smoother!"
- The conversion is candid that its piece/segment location method is its own:
  "following method is not taken from Amiga StuntCarRacer" and "VALUES FROM
  FOLLOWING ARE SLIGHTLY DIFFERENT TO AMIGA STUNT CAR RACER, BUT WORK OK"
  (`Car Behaviour.cpp:~1214–1225`).
- **Temporal smoothing:** if |player_z_speed| < 0xA00 **and** |car x_angle| < 0x600,
  the new wheel height is averaged with the previous value, (h + prev)/2 —
  comment: "possibly for when the car is being lowered onto the road"
  (`CalculateRoadWheelHeight`, `Car Behaviour.cpp:~1267–1290`). The Amiga does the
  same (average unless |z speed| ≥ $A00 or |x angle| > $500 in its angle units) —
  `calculate.road.wheel.height`, immediately following `StuntCarRacer.s:9448`.

### Wheel response — the PD "spring"

Per wheel, per frame (`CalculateWheelCollision`, `Car Behaviour.cpp:~2187–2260`):

```
height_difference = road_height − actual_height − wreck_wheel_height_reduction
height_difference clamped to [−0x300, +0x1400]
amount_below_road = ((height_difference − old_difference) × INCREASE >> 8)
                    + height_difference
amount_below_road clamped to max 0x11ff; if < 0 → 0 (no force)
```

- `INCREASE` = 276 (276/256 ≈ 1.078) — `Car Behaviour.h:~24`. The
  (Δpenetration × 1.078) term is the **damping/derivative** term; the raw
  penetration is the **proportional** term. Note the derivative gain is >1, which
  is why landings overshoot into a bounce rather than settling dead.
- `actual_height` per wheel is derived from car position + pitch/roll sine terms
  (`CalculateActualWheelHeights`, `Car Behaviour.cpp:1902–1945`) — a rigid body,
  no independent wheel travel.
- The three wheels' `amount_below_road` values are averaged (front pair averaged,
  then averaged with rear) and applied as one collision acceleration **along the
  road-surface normal**, whose inclination is derived from the height differences
  themselves (`CalculateCarCollisionAcceleration`, `Car Behaviour.cpp:~2290–2350`).
- `touching_road = (average_amount_below_road != 0)` (`Car Behaviour.cpp:~2119`).

### Attitude (pitch/roll) — the part at Car Behaviour.cpp:~3060

`CalculateXZRotationAcceleration` (`Car Behaviour.cpp:~3063–3090`):

```
player_x_rotation_acceleration = overall_difference_below_road
                                 − (player_x_rotation_speed >> 4)
player_z_rotation_acceleration = front_difference_below_road
                                 − (player_z_rotation_speed >> 4)
```

- `overall_difference_below_road` = average front penetration − rear penetration
  (pitch error, `Car Behaviour.cpp:~2114–2119`).
- `front_difference_below_road` = (front_left − front_right) × 3, clamped
  ±0x1000 (roll error, `Car Behaviour.cpp:~2105–2115`).
- **Damping is the `−(rotation_speed >> 4)` term** — rotation acceleration is
  proportional to attitude error minus 1/16 of current rotation speed. It is a
  spring-damper on attitude, driven by wheel penetration differences, not by the
  geometric road angle.
- While touching the road, longitudinal acceleration pitches the car:
  `player_x_rotation_acceleration += (player_z_acceleration >> 2)` — nose lifts
  under acceleration, dives under braking (`Car Behaviour.cpp:~3078–3083`).
- Rotation speeds and world speeds are integrated with `REDUCTION` = 238
  (238/256 ≈ 0.93 velocity retention per frame) — `Car Behaviour.h:~23`,
  `UpdatePlayersRotationSpeed` / `UpdatePlayersWorldSpeed`,
  `Car Behaviour.cpp:~3095–3185`.
- Pitch is clamped to ±45° normally, ±11° when all wheels are off-road and the car
  is on the ground (`UpdatePlayersPosition`, `Car Behaviour.cpp:~3230–3250`).

### Gravity, bounce, airborne

- Gravity is a constant acceleration `GRAVITY_ACCELERATION 317`
  (`Car Behaviour.cpp:80`; asm: `CAR.WEIGHT equ 317`, `StuntCarRacer.s:29`),
  decomposed along the car's axes via the Y column of the trig matrix
  (`CalculateGravityAcceleration`, `Car Behaviour.cpp:2010–2035`) — i.e. on a
  slope, gravity gains a along-slope component automatically.
- The car leaves the ground whenever all wheels' `amount_below_road` reach 0 —
  road falling away under a crest, a jump lip, or an upward bounce overshoot.
  There is no separate "airborne" trigger; ballistic flight is just gravity with
  no road force.
- **In-air attitude:** when not touching the road, `overall_difference_below_road`
  is forced toward −128 (nose-down) if the pitch angle is ≥ 0, −256 if pitch ≥
  0x1000, and only −8 on Ski Jump when pitched up (`CarCollisionDetection`,
  `Car Behaviour.cpp:~2125–2155`) — the car rotates nose-down in flight, which is
  why landings are usually front-first.
- **Landing:** penetration + penetration-rate feed the PD force above. The same
  event is the damage sensor (next section) and the "Grounded" sound trigger:
  a wheel counts as *grounded* when its amount crosses 0x400 upward from < 0x200
  (`CalculateWheelCollision`, `Car Behaviour.cpp:~2225`).

### Off the edge

- A wheel counts off-road beyond (3×`CAR_WIDTH`)/4 lateral from the road centre
  line's edge reference; its height is dropped by (x×16) + 0x100 — "invisible
  sloping sides", so the car slides/falls off gradually instead of floating on a
  knife-edge (`CalculateIfCarOffRoad`, `Car Behaviour.cpp:~1293–1340`).
  `OFF_ROAD_HEIGHT 0x1000` (`Car Behaviour.cpp:86`) flags whole-car-off-road.

---

## Damage model — granularity verdict (cross-check)

The article's "component damage" claim, checked against the code:

**Verdict: there is no component damage.** No part of the car (engine, steering,
suspension, wheels) has its own damage state or its own performance effect. What
exists is:

1. **Three corner accumulators** — `front_left_damage`, `front_right_damage`,
   `rear_damage` (globals, `Car Behaviour.cpp:~113–116`) — matching the 3 physics
   sample points. They are bookkeeping only: per-corner handling effects are never
   read from them individually.
2. **One averaged damage value for display** — `new_damage =
   ((FL + FR)/2 + rear)/2`, comment: "value new_damage must be used to draw damage
   line" (`UpdateDamage`, `Car Behaviour.cpp:4050–4057`).
3. **Bodywork visuals in two stages** — cracks (smash graphic) progressing to a
   hole, plus sounds (below).
4. **One binary wreck state** — the only mechanical consequence (below).

### What a hard landing actually does, step by step

Per wheel, in `CalculateWheelCollision` (`Car Behaviour.cpp:~2187–2260`):

- `damage = amount_below_road − (road_cushion_value × 256)`, where
  `road_cushion_value` is 0 in the standard league, 1 in the super league
  (`Car Behaviour.cpp:~2046`). **Landings with amount below the threshold register
  no damage at all — they are free.**
- If `damage ≥ 0x700`: the wheel's corner accumulator grows by
  `((damage − 0x600) / 256) × 1.5`, capped at 0xFF per corner; the `damaged` flag
  (0x80) is set. Damage events are rate-limited: `damaged_limit = 10`
  ("actually track/league dependant", `Car Behaviour.cpp:~2045`) events counted
  inside a 14-frame window mechanism (`fourteen_frames_elapsed`).
- `damage_value` (the max over wheels) drives feedback: if `damage_value ≥
  0x1400`, `UpdateDamage` plays the **Smash** sound and starts
  `smashed_countdown = 69`; when the countdown passes 69 the smash graphic is
  replaced by the **hole** graphic ("change smash to hole, by copying 'damage
  hole' graphic to damage.hole.position", `Car Behaviour.cpp:4059–4085`). Below
  that threshold a damaging hit plays the **Creak** sound at volume
  clamp((damage_value>>8)×4, 28, 64) (`Car Behaviour.cpp:4087–4105`).

### The wreck state — the only mechanical damage effect

- Trigger (Amiga): `car.is.wrecked` (`StuntCarRacer.s:11690–11717`) fires when the
  accumulated-damage byte `B.1bbe2` reaches $40 or $80, sets
  `wreck_wheel_height_reduction = 0x200`, raises the "wreck" prompt, and sets a
  lockout byte ($3C). **[NOT DETERMINED: the exact accumulation path of B.1bbe2
  was not fully traced in the disassembly.]**
- In the PC conversion `wreck_wheel_height_reduction` is declared
  ("0x200 if wrecked", `Car Behaviour.cpp:183`) and reset (`:395`) but **never
  assigned 0x200 anywhere in the shipped .cpp/.h code** — the wreck transition
  appears unwired in the conversion; the Amiga routine above is the authority.
- Mechanical effects while `WRECKED` (`wreck_wheel_height_reduction != 0`,
  `Car Behaviour.cpp:90–92`):
  - **Engine cut:** the engine-acceleration block is gated on `NOT_WRECKED`
    (`Car Behaviour.cpp:837`) — a wrecked car cannot accelerate; the race is
    effectively over.
  - **Boost disabled:** `BoostPower` gated on `NOT_WRECKED`
    (`Car Behaviour.cpp:882`).
  - **Ride height:** 0x200 is subtracted from *every* wheel's height_difference
    (`Car Behaviour.cpp:2199`) — the car sits lower / its effective suspension
    travel is eaten, so it scrapes.
  - **Extra drag:** `ReduceWorldAcceleration` uses reduction factor 3 when
    wrecked (`Car Behaviour.cpp:2995–3000`).
  - **Scraping feedback:** `DrawSparks` plays the Wreck scrape sound (and is the
    sparks hook) when wrecked and touching the road at speed
    (`Car Behaviour.cpp:4010–4043`).

**For our build:** damage = per-corner *scoring* → averaged display + crack/hole
visual stages → one global wreck threshold with global effects. If we want
per-component damage, that is our invention, not Crammond's model.

---

## Q3 — The jitter: verdict

**User memory:** the road "wasn't perfectly smooth even though it looked like it —
the tires would constantly jitter up and down."

**Verdict: the jitter is emergent, not authored. There is no roughness/noise data
anywhere in the surface.** It comes from three stacked properties of the model:

1. **Faceted surface.** Heights exist only at segment boundaries (every 256 units
   = two car-lengths). Between boundaries the surface is one bilinear plane per
   segment, so the slope changes *discontinuously* at every boundary. Each of the
   3 wheel sample points crosses boundaries at different times, so at speed the
   car receives a constant stream of small, unsynchronised pitch/roll kicks.
2. **Coarsely quantised heights.** The Amiga stores Y in a packed byte format
   decoded as `((b & 0xF) << 8) | ((b << 1) & 0xE0)` with a final `asr #5`
   (`fetch.surface.y.coord`, `StuntCarRacer.s:9047+`). Decoded profile values are
   multiples of 32 — the profile can only step, never curve smoothly.
3. **The PD wheel response amplifies steps.** The derivative term uses
   `INCREASE` = 276/256 > 1 (`CalculateWheelCollision`,
   `Car Behaviour.cpp:~2187–2260`), so a step in sampled height produces an
   overshooting force, and the temporal height-averaging (Q2) lags and catches
   up asymmetrically per wheel. The system trembles on its own quantisation.

**Evidence the surface data itself is smooth:** decoded Y profiles from
`Amiga_Piece_Y` (`Track.cpp:824+`) are analytic ramps with zero small-scale
variation — e.g. profile B1037 is 14 zeros; B1078 climbs at a constant +64 per
segment then flattens; B1092 is its mirror at −64; B1051's deltas grow smoothly
(192, 256, 320, 384, 448, 512, 512, 512). No noise term exists in any height path
in either the conversion or the disassembly.

**Corroboration from the converter himself:** the PC port's curve handling notes
that treating curved pieces as true circular arcs (instead of the original
chorded method) *"removes the 'jitter' problem"* (`CalcSurfacePosition`,
`Car Behaviour.cpp:~1770`) — i.e. the jitter was a known artefact of the faceted
sampling in the original, visible enough to name.

**For our build:** do NOT author noise into the road. Reproduce the mechanism —
segment-scale facets (≈2 car-lengths), quantised heights, per-wheel sampling of a
faceted surface, and a PD response with derivative gain slightly >1 — and the
jitter will occur on its own. (Our skid/slip calculation must not read this
tremble as slip; the original has no slip model at all — see Q5.)

---

## Q4 — Scale & constants

### Core constants

| Constant | Value | Source |
|---|---|---|
| `GRAVITY_ACCELERATION` (asm `CAR.WEIGHT`) | 317 per-frame² (speed units) | `Car Behaviour.cpp:80`; `StuntCarRacer.s:29` |
| `REDUCTION` (velocity retention) | 238/256 ≈ 0.930 /frame | `Car Behaviour.h:~23` |
| `INCREASE` (derivative gain) | 276/256 ≈ 1.078 | `Car Behaviour.h:~24` |
| Engine acceleration, standard / super league | 240 / 320 | `Car Behaviour.cpp:157` |
| Brake / reverse acceleration | −240 | `Car Behaviour.cpp:~854` |
| Engine cut-off | engine force only while `player_z_speed < 120×256` = 30720 | `Car Behaviour.cpp:837` |
| Steering input magnitude | ±15 (only when touching road, not on chains) | `Car Behaviour.cpp:~824` |
| Display speed | `z_speed × 183 >> 15` | `CalculateDisplaySpeed`, `Car Behaviour.cpp:3630–3643` |

### Boost

- Boost **doubles** `engine_z_acceleration` (`BoostPower`,
  `Car Behaviour.cpp:876–905`); it is not a separate force.
- Reserve drains 1 unit per 17 frames of boost (standard) or 13 frames (super):
  `boost_unit_value` = 16 standard / 12 super (`Car Behaviour.cpp:158`), one
  reserve unit consumed each time the per-frame counter underflows past it.
- Reserve size is **per-track data** (last two bytes of each `Tracks/*.bin`,
  read at `Track.cpp:2697–2698`):

| Track | StandardBoost | SuperBoost |
|---|---|---|
| LittleRamp | 34 | 47 |
| BigRamp | 43 | 41 |
| HighJump | 44 | 42 |
| HumpBack | 41 | 49 |
| SteppingStones | 48 | 52 |
| DrawBridge | 72 | 72 |
| RollerCoaster | 80 | 89 |
| SkiJump | 43 | 40 |

(At the standard drain, RollerCoaster's 80 units ≈ 1,360 frames of boost.)

### Speed in translatable form

- Display calibration is exact: at the engine cut-off (z_speed = 30720) the
  dashboard value is 30720 × 183 / 32768 ≈ **171.6** — the game's top speed reads
  ≈172 (mph in the original's HUD). Speeds above the cut-off are possible
  downhill (no engine force, but drag-only), and boost cannot push past it
  either, since boost only doubles the (zeroed) engine term.
- Position integration (Amiga): Δx/z per frame = speed × (238/256) × 64 position
  units; Δy = speed × (238/256) × 128 (`update.players.position`,
  `StuntCarRacer.s:~15681`). One geometry unit = 32768 position units
  (cube = 2^26 position units per 2048 geometry units), so at cut-off the car
  covers ≈ **55.8 geometry units/frame**.

### Units per metre — conditional, flagged

**[NOT DETERMINED exactly.]** The physics timestep is one rendered frame, and the
original's frame rate is render-bound and variable (the conversion's
`HIGHER_FRAME_RATE` ifdefs exist precisely to rescale for a different rate). The
code therefore contains no fixed seconds-based scale. What can be said:

- *If* the frame rate is taken as 50 Hz (PAL) and the display value as mph, the
  speed anchor gives ≈ **36 units/metre**: road ≈ 10.5 m wide, car ≈ 3.5 m long ×
  1.76 m wide, segment ≈ 7.0 m, piece ≈ 56 m. These are plausible real-world
  sizes, which is weak evidence the anchor is roughly right.
- A gravity cross-check does **not** close: the conversion explicitly rescales Y
  at the physics/drawing boundary by `LOCAL_Y_FACTOR 4`
  (`Car Behaviour.cpp:94`, `:509`, `:601`), so vertical quantities in the
  conversion are not in the same unit chain as XZ, and 317 should be treated as
  a tuned per-frame constant, not converted to m/s².
- **Practical rule for our build:** adopt ~36 units/m (i.e. treat 384 units ≈
  10.5 m, car length 128 ≈ 3.5 m) for proportions, and tune gravity/boost by
  feel against the *ratios* above (boost = 2× engine accel; engine accel ≈
  gravity × 240/317 ≈ 0.76 g standard, ≈ 1.0 g super at 320/317), not by unit
  conversion.

---

## Q5 — Audio (reference only — trigger logic)

### Samples present (`Sounds/`, 15 files)

Chime, Creak, EnginePitch2, EnginePitch3, EnginePitch4, EnginePitch5,
EnginePitch6, EnginePitch7, EnginePitch8 (seven pitch steps — there is no
EnginePitch1), Grounded, HitCar, OffRoad, Smash, TickOver, Wreck.

**There is no skid sample, and no slip-driven sound anywhere.** The original has
no tyre-slip model: surface sound is *contact* sound (grounding thumps, off-road
rumble, wreck scraping), not traction sound. Any skid audio in our build is our
own addition — the honest original analogue is the OffRoad/Grounded logic below.

### Engine — driven by speed, not throttle

`UpdateEngineRevs` (`Car Behaviour.cpp:3650–3736`), "Tested against Amiga":

- **On the road:** target revs derive from |player_z_speed|:
  `target = ((|z_speed| & ~0xF) + 0x580) >> 3`. The engine note *is* the speed.
- **Airborne:** if accelerate or brake is held, target heads to a 0x9000-based
  free-rev value; otherwise revs decay — and the negative clamp is much softer in
  air (−0x20/frame vs −0x100/frame grounded), so revs *hang* during a jump.
- Revs approach target at (target − revs) >> 3 per frame, clamped to
  +0x100/frame; below 192 revs the change is forced to +2/frame (slow spin-up at
  race start).
- `engineFluctuation = rand() & 0xF` every frame (`Car Behaviour.cpp:~3730`) —
  deliberate random roughness in the engine note.

`FramesWheelsEngine` (`Car Behaviour.cpp:3755–3890`) — playback:

- `period = 4800000 / (revs + 378)`; the sample index starts at 6 and the period
  is halved until < 256, stepping the index down — i.e. **seven octave-spaced
  samples**, each played within one octave band, frequency =
  `AMIGA_PAL_HZ (3546895) / period`. The fluctuation is OR'd into the period.
- On an octave switch, the new sample starts at the old play cursor ×2 or ÷2
  (phase-continuous through the switch). TickOver is the idle/bottom sample of
  the set. **[NOT DETERMINED: the exact buffer-index ↔ file mapping in the loader
  was not verified; a code comment places "tick over" at index 0 and the first
  pitch sample at index 1.]**

### Surface & event sounds — trigger table

| Sound | Trigger | Driving variable | Source |
|---|---|---|---|
| Grounded | any wheel "grounds" (penetration-rate event) | volume = clamp((damage_value>>8)×4, 28, 64); 5-frame retrigger delay | `CarCollisionDetection`, `Car Behaviour.cpp:~2160–2190` |
| OffRoad | off_map_status ≠ 0 while touching road (dust clouds) | playback freq = `AMIGA_PAL_HZ / (450 + (rand & 0x1C))` — randomised rumble pitch | `DrawDustClouds`, `Car Behaviour.cpp:~3965–3999` |
| Wreck (scrape) | car is WRECKED, or sitting on a road edge (`which_side_byte`), while touching road | period from \|z_speed\|>>8, clamped ≤ 50 → frequency | `DrawSparks`, `Car Behaviour.cpp:4010–4043` |
| Smash | a damage event with damage_value ≥ 0x1400 | one-shot; starts the crack→hole visual countdown | `UpdateDamage`, `Car Behaviour.cpp:4059–4085` |
| Creak | lesser damage events | volume ∝ damage_value, clamped 28–64 | `UpdateDamage`, `Car Behaviour.cpp:4087–4105` |
| HitCar | car-to-car collision with opponent | one-shot | `Opponent Behaviour.cpp:1843` |
| Chime | **[NOT DETERMINED]** — present as a sample; trigger not located in the behaviour code (likely menu/countdown) | — | `Sounds/Chime.wav` |

Wheel rotation speed exists as a variable but its setter is commented "(not
needed yet)" with the Amiga logic preserved in a comment
(`Car Behaviour.cpp:~1970–2000`): grounded → wheel speed = |z_speed|×8 (or
×2 + 0x3000 above 0x800, capped 0xFF00); airborne → decays by ¼ per frame. It
drives wheel *graphics*, not audio, in this conversion.

---

## Q6 — Drop start & off-track recovery

The crane/drop and the recovery are **the same mechanism**: teleport the car
above a piece, then let it fall. There is no crane object or animation in the
physics code — in this conversion the "crane" is purely `PositionCarAbovePiece`
plus gravity.

### The shared path (`CarBehaviour`, `Car Behaviour.cpp:519–562`)

```
if (off_track_count > OFF_TRACK_LIMIT) or new game or replay requested:
    ResetPlayer()
    if off-track:  PositionCarAbovePiece(player_current_piece)
    else:          PositionCarAbovePiece(PlayersStartPiece)
    drop_start_done = FALSE
    off_track_count = 0
```

- `OFF_TRACK_LIMIT` = **64** (frames) — `Car Behaviour.cpp:89`, comment: "count
  after which player is put back on track."
- `off_track_count` increments only while **all three** hold: `off_map_status
  != 0`, `touching_road`, and `player_y < 0x1000000`; it resets to 0 as soon as
  the car is back within bounds (`Car Behaviour.cpp:980–995`).
  `off_map_status` is set when `player_distance_off_road ≥ (256 − ROAD_WIDTH/2)`
  = 64 (`Car Behaviour.cpp:~980`). So recovery triggers after ~64 consecutive
  frames fully off the road surface and in contact with the ground plane — a car
  still airborne off the edge is not yet recovered.
- While off-track the pitch clamp tightens to ±11° (Q2), so the car sits flat
  for the pickup.

### PositionCarAbovePiece (`Car Behaviour.cpp:3544–3600`)

- Walks **backwards** through pieces until it finds one the car may be lowered
  onto: `sections_car_can_be_put_on[template] & 0x80` marks forbidden templates —
  per the table's own comment (`Track.cpp:40–48`) those are the **curve**
  templates (1, 3, 6, 7). Cars are only ever dropped onto straights/diagonals.
- Places the car at the piece centre (`CUBE_SIZE/2` in x/z), at
  **road height + 0xC00** (internal height units, then ×256 into player_y space;
  absolute conversion **[NOT DETERMINED]**, see Q4), x/z angles zeroed, heading =
  the piece's rough angle (+180° if the piece runs in the opposite direction).
- `drop_start_done` is set TRUE the first frame the car touches the road
  (`Car Behaviour.cpp:596`, with the comment "Amiga StuntCarRacer does this
  differently"). The descent is softened by the height-averaging path in Q2,
  which exists explicitly "for when the car is being lowered onto the road."

### Race start

A new race takes the same path with `PlayersStartPiece` (per-track byte in the
track file, `Track.cpp:2661+`). **[NOT DETERMINED: the countdown/timer sequence
after the drop (start lights, engine-rev gate at 192 revs in Q5) was not traced
in the front-end code.]**

### Related: DrawBridge timing

The DrawBridge section's Y values are generated dynamically:
`draw_bridge_frame_count` cycles a bridge height 0..15, and the bridge **freezes
while a car is on or approaching pieces 48–52** (`Track.cpp:~2470–2500`). Not a
recovery mechanism, but it is the one place the original animates road geometry
at runtime.

---

## Consolidated unknowns (flagged, not guessed)

1. Absolute units-per-metre — frame-rate-dependent; ~36 u/m is a conditional
   estimate from the speed anchor at 50 Hz (Q4).
2. Drop height +0xC00 in absolute terms — same unit-chain problem (Q6).
3. Exact accumulation path of the Amiga wreck-trigger byte `B.1bbe2` (Q2 damage).
4. Engine sample buffer-index ↔ filename mapping; Chime trigger (Q5).
5. Race-start countdown sequence after the drop (Q6).
6. SteppingStones gap encoding — inferred to be height-data only (Q1).
7. The conversion's own caveat stands over everything above: several PC-side
   methods are the converter's reconstruction, "slightly different to Amiga
   Stunt Car Racer, but work OK" (`Car Behaviour.cpp:~1214–1225`). Where Amiga
   asm was checked (bilinear height, height averaging, WIDTH.REDUCTION, wreck
   routine), it agreed with the conversion.
