# Original Stunt Car Racer — Feel Study

Frame-by-frame study of the owner's all-tracks Amiga video, done 2026-10-27.
Source: `original-all-tracks.mp4` in this folder (the LemonAmiga "Track-by-track
Guide Review" playthrough the owner downloaded from YouTube via Google Drive).
Purpose: feel evidence for tuning OUR driving model later. Nothing in the game
or the design spec was changed by this study.

Video times are `mm:ss` into the file. Race times are the game's own on-screen
timer where readable. Strips referenced live in `strips/` next to this file;
per-window machine traces (tire positions, sky fraction per game state) live in
`traces/` and can be re-derived from the video with `analyze3.py`.

---

## 0. The fps basis — read this before trusting any duration

- The video file is 1920×1080, **30 fps container**, 15:00 long. Every frame is
  unique (no duplicated frames).
- The GAME inside it does **not** update at 30/s. Frame-differencing the
  capture shows the picture changes in steps: the game renders a new state,
  which then holds for 1–5 video frames. Measured update cadence varies by
  section: **~14/s at the slowest (drop-start hangs, High Jump), ~16–20/s in
  racing, average ≈ 17/s**. (This squares with the owner's memory that the
  original ran at "basically 5 fps" in feel — it didn't, but the steps are
  big and visible.)
- **Every duration below is counted in game update states** and converted to
  seconds at the cadence measured for that window. Nothing is quoted at
  30 fps, and nothing assumes the Amiga's 50 Hz — the capture doesn't carry it.

## 1. How anything could be measured from a cockpit-only video

All footage is the cockpit view. The engine/blower/exhaust assembly in it is a
**fixed overlay — pixel-identical in every state** (verified across hang,
racing, and corners; it is the car's nose, locked to the camera). What actually
moves on screen:

1. **The front tires**, visible at the windshield's extreme left/right edges.
   Their top edge rides up and down over ≥148 px (full-res) of travel between
   full compression and full droop — that is the suspension, drawn. A detector
   tracked both tires in every game state of the windows below (validated by
   eye against strips at both extremes).
2. **The world** — ribbon, horizon, sky fraction of the upper windshield —
   which gives pitch/attitude (nose-up = world sinks, airborne = sky fills).
3. **The HUD** — speed bar (scale 0–230), lap/boost readout, and the signed
   gap counter to the opponent (positive = opponent ahead; it counts down as
   you close).
4. **The opponent car itself**, when in view, measured against the surface and
   its own shadow.

Cockpit limits, stated honestly: tire position conflates suspension travel
with the car dipping below the ribbon plane, and on steep descents the tire
signal saturates at droop even though the wheels may be loaded (nose-down
pitch alone can pin them). Where a "droop" reading could be pitch instead of
air, the notes say so, and flight claims are only made where the strip shows
the surface gone / sky full.

---

## 2. Suspension & bounce in ordinary running

**On flat ground there is no bounce at all.** Little Ramp's start straight
(video 0:33–0:38, race 0:02–0:07): the front-tire trace is constant within
2 px — quantisation flicker only. The car runs dead, nailed-down steady.
Whatever bounce the original is famous for is **not a resting jiggle**.

**Over features, the wheels work hard and independently.** Crossing Little
Ramp's rolling ground (video 0:38–0:45), tire travel swings ≈100 px
(full-res) peak-to-peak, left and right frequently out of phase — crossing a
crest edge-first, one tire droops a full update or two before the other
(visible at the jump lip, video 0:50.63–0:50.80). Total travel from clipped
full compression (tire pinned at the top of its range) to full droop is
≥148 px ≈ 14% of frame height — huge, legible wheel movement.

**The bounce period is the track's period.** On Hump Back's hump train the
suspension cycles once per hump — roughly one compression→droop cycle every
0.5–1.0 s at racing speed, each one authored by a ribbon facet, not by a
spring oscillation. After a disturbance the trace shows at most ONE overshoot
cycle (see the drop-start landing, §5) — the system settles in about a second
and never rings on its own. Character: **stiff, heavily damped, feature-driven**
— a PD controller's behaviour, not a bouncy spring's (this matches the source
mining: per-wheel PD, no spring term, derivative gain > 1).

*Strip: `player_humps.png` — Hump Back, video 2:21.9–2:23.2, every state:
boost on up the face, flames off at the crest, wheels dropping away as the
far side falls, dip-bottom compression, straight into the next hump.*

## 3. Small air — crests, humps, sloped turns

Small air is **constant** in this game. Counted from the tire traces
(both wheels at droop, surface verified in strips where it mattered):

| Where | Event | Air time |
|---|---|---|
| Hump Back (video 2:17.4) | crest unload | 5 states ≈ **0.29 s** |
| Hump Back (video 2:22.2) | crest unload | 7 states ≈ **0.36 s** |
| Hump Back (video 2:09.7, 2:10.8, 2:13.3, 2:14.9) | hump train | 0.06–0.16 s each |
| Roller Coaster back half (video 8:52–8:54) | washboard crests | 4 hops in 1.6 s: 0.10–0.20 s each |
| Draw Bridge back half (video 10:15–10:39) | crest drumbeat | **12 hops in 25 s**, 0.16–0.53 s |
| Stepping Stones (video 4:22.3–4:22.6) | player's stone hop | 3 states ≈ 0.33 s, amid 60 ms skips |

- **Off crests:** boost is cut *before* the crest (flames out in
  `player_humps.png`), the car unloads, flies briefly **nose-level to
  slightly nose-down** — never nose-up floaty — and lands already compressing
  into the next dip. Air here is a by-product of speed over shape.
- **Off sloped/banked turns:** one clean mechanism, seen twice. On Hump Back's
  ~30° banked turn the car unloads **one side at a time** — asymmetric droop
  clusters (downhill side lets go first, video 2:09.1–2:11.0) — and at the
  bank's exit crest that rolls into brief full air. The bank itself rolls the
  whole cockpit ~30° (camera locked to the car; `opponent_banked_pass.png`).
  Honest limit: a long both-wheels flight off a *pure* bank was not isolated;
  what the footage shows is side-unload on the bank → crest air at the exit.
- **In the air the car settles nose-down progressively** (the source's forced
  nose-down): on every longer flight the horizon visibly sinks further the
  longer the flight lasts, so landings arrive nose-first onto downslopes.

## 4. Big air — ramps & gaps

The big features share ONE signature, seen on three tracks:

**Flight → hard downslope contact → REBOUND into a second flight → settle.**

| Feature | First flight | Contact | Second flight |
|---|---|---|---|
| Little Ramp main jump (video 0:51–0:53) | ≈ **2.0 s** (race clock 0:19.7→0:21.7), lands on a steep downslope far below takeoff | — | (descent blends into the dip) |
| High Jump (video 6:31.7–6:35.2) | 23 states ≈ **1.93 s**, sky fills the windshield completely | ≈0.6 s on the landing slope | 13 states ≈ **1.16 s** |
| Draw Bridge chasm (video 9:56–10:04) | ≈ **3 s** sail at full boost, boost cut mid-flight | downslope touchdown | ≈1 s rebound flight into the banked exit |
| Ski Jump (video 11:39.9–11:43.6) | 21 states ≈ **1.74 s** — at peak height the surface drops out of the frame entirely | ≈0.7 s | 10 states ≈ **1.40 s** |

- Takeoff attitude comes off the lip still climbing; the nose-down then builds
  through the flight. By touchdown the car is pitched well nose-down and
  meets the slope close to parallel — the landings are slope-matched, not
  flat slams (except when the player gets it wrong — §6).
- The **rebound is the tell**: a correctly-landed big jump does not stick.
  The suspension returns the energy and the car flies *again* for roughly
  half to two-thirds of the first flight's time. If our landings ever look
  "planted" where the original bounces back into the air, that is the
  difference.
- Draw Bridge opens with a plunge, not a straight: from the drop, the car is
  at full droop for ~7 s of combined falling and steep descent (video
  9:36.7–9:44.3, `drawbridge_start.png`) — the slope falls away faster than
  the car at first. Cockpit signal saturates here; the split between true
  air and steep grounded dive can't be separated from inside.

*Strips: `highjump_flight.png`, `drawbridge_jump.png`, `skijump_flight.png`
— each shows the full pattern: sky, landing hill rushing up, surface filling
the frame, sky again.*

## 5. The Drop Start (and crane drops)

Little Ramp drop start, traced state-by-state (video 0:25–0:35):

- **The hang (0:25–0:30.7):** wheels hang at full droop. The car **sways
  gently and irregularly** on the chains — one-sided tire excursions (one
  wheel rising ~40–70 px for a few states, subsiding, the other side later),
  a slow rock with a period of roughly 1.5–2.5 s between disturbances, never
  a clean sine. It reads as a pendulum being nudged, not driven.
- **The drop (0:30.8–0:31.1):** ≈0.3–0.4 s of fall — the crane holds the car
  only just above the track. This is a *short* drop.
- **Touchdown (0:31.1–0:32.0):** ONE soft bounce — compression overshoots
  once (~32 px in frame) and settles. Rolling by ~1 s after release.
- Mid-race crane drops are the player's own trigger: the High Jump recovery
  strip shows **"PRESS FIRE"** on screen while hanging — you pick your
  moment, then the same short fall and single-bounce settle.

*Strip: `highjump_crash_crane.png` (the recovery; the Little Ramp hang
numbers above are from `traces/ds_trace.npy`).*

## 6. Crashes, the crane, damage cues

High Jump, video 6:53.5–7:04 (the player under-runs a landing into the wall):

1. **Smoke first:** a wall of white-grey puffs fills the lower windshield
   and takes ~2 s to thin. The car stops dead in its own smoke. That cloud
   *is* the crash feedback — no explosion, no camera shake visible in the
   overlay (there can't be; the overlay is fixed — the verdict is carried by
   smoke + stop).
2. **Chains arrive** and the car is lifted; the crane flies it back along the
   track for ~4–5 s. From the hang you see the ribbon laid out far below —
   the recovery doubles as a look at the track you're about to rejoin.
3. Sway in the carry is gentle, same character as the drop-start hang.
4. "PRESS FIRE" → drop → the landing spot is chosen well (here: flat,
   just before a banked climb) → racing again. Whole episode ≈7 s from
   impact to rolling. A second crane episode on Ski Jump (video 12:03–12:10)
   shows the same sky/signature profile, ~8 s of hang and carry.

Damage elsewhere is the cockpit-frame crack (visible at the frame's top in
post-crash states) — the game shows wear on the *frame*, not the car body,
from this view.

## 7. The opponent

The opponent runs the **same physics** — same hop heights off the same
stones, same bounce character (Crammond's notes already say the AI pushes
the same wheel model; the footage agrees). What differs is how it *reads*:

- **It looks lighter because you watch it from outside.** On Stepping Stones
  (video 4:21.3–4:24.3, `opponent_stones.png`, every state) the opponent hops
  stone-to-stone: 2–4 states airborne (0.1–0.25 s) per gap, body staying
  strikingly **level** — it bobs vertically far more than it pitches — shadow
  separating cleanly from the body at each hop. Over the same stones a moment
  later the player's own trace shows scrappier 60 ms skips and one landing
  that bottoms the suspension out (tire trace clips at full compression).
- **Banked turns:** it takes the high line, body rolled with the bank,
  grounded, shadow hugging the surface (`opponent_banked_pass.png`, video
  2:02) — from the player's seat it sits *above* your eye-line, which is the
  moment that reads as "floating" until you see the shadow.
- **It can be beaten off the track:** Hump Back (video 2:17.5–2:18.5,
  `opponent_edge_fall.png`, every state): chasing it up the steep banked
  right edge, it rides the edge, tips, and **falls off the track entirely**,
  landing on the ground beyond and running there while the player passes.
  Edge behaviour matches the source: per-wheel support fading over the
  "invisible slope" past the edge, then nothing.
- **Contact:** closing the gap counter 0025→0000 in ~10 s on Hump Back ends
  in a visible shove as the cars touch at ~video 2:08.3 — the opponent gets
  pushed sideways and both cars keep their lines (no spin, no bounce-off);
  sustained-push character, consistent with the settled sumo rule.
- Big air: no clean shot of the opponent over a headline jump was captured
  (it's usually out of frame by then). Its hops that ARE visible match the
  player's heights over the same features — no evidence it flies higher or
  lands softer. Stated as a gap, not a finding.

## 8. Speed sensation

- The game lives at **~130–170 on the HUD scale** (0–230), touching
  **~200–210 only at full boost on straights** (speed-bar sampled from the
  traces; approximate — bar calibration from the printed ticks). Features
  are taken at surprisingly moderate speed; the terror is not velocity.
- What sells speed: (1) the ribbon edges and red/white edge blocks streaming
  past at ~17 updates/s — big, discrete per-update steps, so the world moves
  in *lunges*; (2) the stilts/supports dropping away under the high sections;
  (3) the surface texture bands (facet shading) sweeping under the nose;
  (4) in corners, the whole world rolling with the car's body roll.
- Straights vs corners: edge-block pass rate scales with the speedo
  honestly, but corners *feel* faster than their speed because the view
  rolls and the outside edge wall sweeps across the frame.

## 9. Other feel details

- **Boost is a decision, not a default:** flames appear for launches, starts,
  and chases, and are cut *before* crests and jumps — the player in this
  video manages boost around features constantly. (Little Ramp's whole
  first lap runs with boost held at the *start*, then managed.)
- **Engine-off silence in the air:** not measurable from video — but the
  boost flames visibly die in flight even when the run-up was boosted on the
  Draw Bridge sail (part throttle discipline, part the game cutting drive
  with no wheel contact; audio would settle it — flagged, not claimed).
- **Steering wobble:** none. At no point in 15 minutes does the car fish-tail
  or oscillate in yaw on a straight. All the life is vertical.
- **The TNT section** (video ~12:32 on) is a modified version (different
  cockpit, new tracks) — excluded from every claim above; original-tracks
  footage only.
- **Camera = car.** There is no independent camera lag, smoothing, or
  look-ahead anywhere in the footage: pitch and roll are the car's, instantly.
  The *only* softness in the whole presentation is the suspension itself.

---

## 10. What this asks of OUR driving model

Questions/targets for the tune call — each is traceable to a section above.
No numbers here that the footage doesn't support.

1. **Resting state:** is our car dead steady on flat ribbon (zero visible
   tremble), with ALL wheel motion coming from the surface? (§2 — if we
   have any idle jiggle, it is un-original.)
2. **Wheel independence:** do our front wheels visibly work *separately* —
   one side drooping over an edge/crest a beat before the other? (§2, §3)
3. **Crest unload tuning:** at our FP11 top speeds, do ordinary crests give
   0.1–0.4 s of air as a matter of course, several times a lap — and does air
   frequency read as the *drumbeat* of the lap (a dozen hops in 25 s on a
   washboard section)? (§3)
4. **Flight attitude:** does our nose-down in flight *build* through the
   flight (landings slope-matched, nose-first), or do we leave level and
   land flat? (§3, §4)
5. **The rebound test — the single biggest one:** after our biggest jump,
   does the car bounce back into a second flight of ~half the first one's
   length, or does it stick the landing? The original NEVER sticks a big
   landing. What in our suspension (damping on high penetration rates?)
   decides this? (§4)
6. **One-bounce settle:** after the drop start and after crane drops, do we
   settle in ONE overshoot inside ~1 s? More ringing than that is wrong;
   none at all (a dead splat) is also wrong. (§5)
7. **Hang sway:** does our hanging car sway *irregularly* — nudged, damped,
   never a clean pendulum sine — and is the drop itself short (fall ≈0.3–0.4 s,
   prep not plummet)? (§5)
8. **Opponent parity:** does our AI rival visibly hop with a *level body*
   (vertical bob, little pitch) over the same features — and can it be
   pushed off an edge exactly like the player, fading support first? (§7)
9. **Speed read:** our sense of speed should come from edges/supports
   streaming and view roll, at honest speeds — if a section only feels fast
   at speeds the original would call absurd (>210 on its scale), the
   trackside dressing is too sparse, not the car too slow. (§8)
10. **Vertical-only life:** yaw stays honest — no fishtail wobble on
    straights. If our car feels busy, it should be busy *vertically*. (§9)

## Appendix — strips in `strips/`

- `player_humps.png` — bounce + crest unload, player's view (Hump Back)
- `opponent_stones.png` — opponent-air sequence (Stepping Stones, every state)
- `opponent_edge_fall.png` — opponent rides the edge and falls off (Hump Back)
- `opponent_banked_pass.png` — opponent on the high line of the banked turn
- `opponent_contact.png` — the passing shove (Hump Back)
- `highjump_flight.png` — the flight → contact → rebound pattern (High Jump)
- `highjump_crash_crane.png` — crash smoke, crane carry, PRESS FIRE, re-drop
- `drawbridge_jump.png`, `drawbridge_start.png` — the chasm sail + opening plunge
- `skijump_flight.png` — the biggest flight in the game
- `coaster_banked_crest.png`, `coaster_first_drop.png` — Roller Coaster crests/plunge

Working files: `original-all-tracks.mp4` (source), `traces/*.npy` (per-state
tire/sky traces), `analyze3.py` (the streaming extractor that made them).
Intermediate frame dumps (~3.9 GB) were deleted after the strips and traces
were taken; everything above can be re-derived from the video + scripts.
