# XR Grab Reliability — Research for Operation Fix the Fucking Levers

*Compiled 2026-10-29. Scope: why our hand-rolled cockpit levers (Godot 4.7,
OpenXR, Quest 3 Touch Plus controllers via Virtual Desktop / VDXR) actuate
intermittently in live play while every headless staged test passes, and what
the reference implementations do differently. Items that could not be verified
from a source are marked **UNVERIFIED** rather than guessed.*

---

## 1. Godot XR Tools (godot-xr-tools) — how the reference implementation grabs

Source basis: the XR Tools docs' Pickup page, plus a vendored copy of
`XRToolsFunctionPickup` source from a third-party project (the action wiring in
that copy looks locally adapted — it polls a trigger-named action in the grip
handler — but the detection/latch/hysteresis structure is the shipped design).
Corroborated by the XR Tools changelog (v3.1.0: "Use value based grip input
with threshold").

**Detection is a fat sphere + a candidate list, not a precision test.**

- Each hand's pickup node creates its own `Area3D` ("GrabArea") carrying a
  `SphereShape3D` whose radius is the configurable **Grab Distance, default
  0.3 m** — a 0.6 m diameter capture bubble around the hand, deliberately far
  larger than any object visual. Objects are tracked via area/body
  entered/exited signals into a candidate list.
- Every frame, the pickup picks the **closest** candidate by origin distance
  and marks it as the grab target. When the closest target changes/appears,
  the object is **highlighted** and the controller fires a **haptic pulse**
  (`trigger_haptic_pulse`, 0.1 s) — the player is told "your hand is on
  something" *before* they squeeze.
- A separate ranged-grab cylinder (default 5 m, 5° cone) exists for distant
  grabs; irrelevant for a cockpit, but it shows the same philosophy: generous
  volumes, nearest wins.

**Grip reading is analog, with an explicit hysteresis band.**

- The pickup polls the analog float action in `_process` (render-rate, **not**
  `_physics_process`) and applies its own Schmitt trigger:
  press when `value > grip_threshold + 0.1`, release when
  `value < grip_threshold − 0.1`, where `grip_threshold` comes from XR Tools'
  project configuration. **UNVERIFIED:** the numeric default of that setting
  (the ±0.1 hysteresis band around a configurable centre is verified from
  source; the centre value is not).
- It does **not** trust a runtime-supplied boolean conversion of the squeeze
  (see §2 for why that matters).

**Holding is a latch, not a continuous zone test.**

- On the grip-press edge, the pickup calls `pick_up()` on the closest
  candidate and stores it as `picked_up_object`. From that moment, zone/area
  membership is **never re-tested**. The object stays held until the grip
  release edge — or, for pickables with `press_to_hold = false` (the default
  is `true`), until the *next* grip press toggles it off. Both semantics are
  first-class options.
- While held, a grab-driver drives the object from **grab points**: the
  relative transform captured at the grab is preserved and the object is moved
  each physics frame to `hand_transform * stored_relative_transform`. The hand
  may wander well off the object's visual without dropping it.
- XR Tools also ships dedicated **interactables for exactly our case** — a
  grabbable handle/hinge/joystick/slider family (see the interactables demo
  its maintainer points lever questions at). The handle is grabbed and latched
  the same way; its motion is then *constrained* (hinge limits, one DOF) and
  reported via signals (`hinge_moved`, etc.). The lever never detaches from its
  machine; the hand's motion is projected onto the lever's one allowed motion.

**Lessons for a fixed cockpit lever with a throw arc:**

1. Detection volume ≫ visual size; nearest candidate wins; announce the
   candidate (highlight + haptic) before the squeeze.
2. Analog read + own hysteresis; never a runtime bool.
3. Grab = latch + stored relative transform. The throw is computed by
   projecting the hand's motion onto the arc. Zone membership is a
   *starting* condition only, never a *continuing* one.
4. Hold-vs-toggle is a per-control choice; both are legitimate.

---

## 2. OpenXR squeeze on Quest Touch via Virtual Desktop / VDXR

**What the hardware/profile actually offers (verified from Unity's OpenXR
profile documentation for Meta Quest Touch Plus, which mirrors Meta's
interaction profile):**

- The Touch Plus profile exposes **`/input/squeeze/value`** (analog float).
  There is **no `/input/squeeze/click` endpoint** in the profile — Unity lists
  `gripPressed` as a *Boolean cast of the float*. Any boolean "grip clicked"
  state is manufactured by thresholding the analog value.
- There is **no `/input/squeeze/force`** on Touch/Touch Plus (Touch Plus does
  expose `/input/trigger/force`; squeeze force sensing is a Valve Index
  feature, and Touch Pro adds trigger/stylus force, not squeeze force).
  **Consequence: a `grip_force` action on Quest Touch has nothing to read and
  will sit at zero — this matches our FP10 finding (FRC column permanently
  0.00, `grip_force` bound nowhere useful). It is expected hardware behaviour,
  not a bug to chase.**
- Godot's default action names follow the same split: `grip` (float,
  squeeze/value), `grip_click` (bool, squeeze/click), `grip_force` (float,
  squeeze/force).

**Who chooses the click threshold? The runtime. (Verified twice over.)**

- OpenXR specification, on binding a boolean action to a scalar input: *"a
  threshold must be applied to the value and values over that threshold will
  be XR_TRUE. The runtime should use hysteresis when applying this threshold.
  The threshold and hysteresis range may vary from device to device or
  component to component and are left as an implementation detail."*
- Godot's own XR action-map documentation says the same thing operationally:
  *"Where analogue inputs are queried as buttons a threshold is applied. This
  threshold is currently managed exclusively by the XR runtime"* — and, in its
  warning box: *"OpenXR does automatic conversions from analogue controls
  however not all XR Runtimes currently apply sensible thresholds. We
  recommend as a workaround to use the `Float` type when interacting with
  triggers and grip buttons and apply your own threshold."*

So if a grab system reads the squeeze as a **bool** (`grip_click`, or
`is_button_pressed` on an analog-backed action), its effective press point is
whatever VDXR chose, it can differ per hand/component, and it is not tunable.
If it reads the **float** and thresholds it itself, the behaviour is identical
on every runtime. This is the single most portable reliability rule in this
document.

**VDXR-specific behaviour — mostly UNVERIFIED, with structural caveats:**

- No authoritative public source was found documenting VDXR grip dropouts, a
  VDXR-specific squeeze dead-zone, or per-hand grip asymmetry. **Treat any
  claim of a specific VDXR grip bug as UNVERIFIED.** (For calibration: VDXR
  input streams have had documented corruption issues in at least one other
  channel — a published VR mod's notes describe a glitch filter for "corrupted
  Quest Pro / VDXR stick streams" — but that is thumbsticks, not squeeze, and
  is not evidence about grip.)
- What is structurally true: VDXR is a third-party runtime; controller state
  originates on the headset, crosses VD's Wi-Fi streaming pipeline, and is
  presented to the PC app as OpenXR action state. Godot syncs action state
  once per frame (`xrSyncActions` cadence), so the app only ever sees
  per-frame samples of the value — never the peak between samples. A squeeze
  that rises and falls entirely inside one frame interval can be missed by
  edge logic; human squeezes are normally ≥80–100 ms, so this is a minor
  contributor compared to §4, but any design that requires the threshold
  crossing and another event to land in the *same* sample is fragile by
  construction.
- Our project's own live evidence (run 10 video forensics: left GRIP reading
  0.00 in every frame while the right hand cycled to 1.00) is a *channel-level*
  zero, not a near-threshold miss. If that recurs, it points at binding /
  profile / action-set state for that hand (an inactive action returns exactly
  0.0 per spec), not at thresholds — and it is diagnosable from logged live
  values in a way staged tests cannot reproduce.

**Analog value characteristics to design around:**

- The squeeze is a physical button travel under the middle finger; the value
  is only as high as the player actually squeezes. A relaxed "holding"
  squeeze and a deliberate crush produce very different peaks.
  **UNVERIFIED:** any specific numeric range for a "natural" grab on Touch
  Plus (no trustworthy published figure found). The correct way to set the
  press threshold is to log real peaks from our own DIAG during live play and
  set the threshold below the observed natural-grab peak with margin — not to
  copy a number from another project.

---

## 3. VTOL VR and respected cockpit implementations

VTOL VR is the reference cockpit for grabbed levers (Boundless Dynamics;
sources: Road to VR's hands-on/developer interview, the VTOL VR settings wiki
— community-maintained, flagged as such — and contemporary player reports).

- **Bind, don't track.** Pressing grip near the stick or throttle **binds**
  the hand to the control *in the location and orientation the hand has at
  that moment* (a stored relative transform — the same pattern as XR Tools'
  grab points). The control then follows hand rotation/translation from that
  offset.
- **"Soft lock."** Once grabbed, the system deliberately tolerates the hand
  moving to a more comfortable position that is *no longer aligned* with the
  virtual control — the developer describes this as a feature (rest the
  controller on your thigh as a pivot). The grab does **not** require
  continued proximity or alignment; it ends on release, not on geometry.
- **Toggle or hold, player's choice.** The settings include **Toggle Grip**:
  *"Allow toggling throttle/joystick grip by tapping grip button. Holding
  grip still allows releasing after letting go."* Large flight controls get
  latch semantics so a momentary squeeze dip can't drop the throttle
  mid-flight.
- **Two grab verbs by control size.** Small controls (switches, knobs) are
  worked with the **trigger**: point a finger at the switch (a tooltip appears
  on proximity), squeeze the trigger to grasp it, move/twist, release. The
  **grip** button is reserved for the big controls (stick, throttle). Players
  consistently describe this split as why the cockpit feels reliable.
- **Confirmation is constant and physical.** "Pretty much every control of
  necessity had a nice haptic touch to let you know you had grasp of it"
  (Gaming Nexus preview); there is a **Flight Control Haptics** intensity
  setting, and the stick/throttle buzz subtly *while they move*, so a held
  control keeps confirming it is held, and detents/ends are felt rather than
  seen. Nothing in the cockpit fails silently: if you didn't feel the buzz,
  you didn't grab it, and you know immediately.

DCS World and MSFS sit at the other end (laser-pointer + click interaction);
their forum debates still converge on the same conclusion — "grab and drag is
best" — citing VTOL VR as the model. For a lever-forward cockpit, VTOL's
pattern is the one to copy: **proximity candidate → grip press binds with
stored offset → motion projected onto the control's axis → haptic confirmation
on bind, during travel, and at detents → release is an explicit edge (or a
second tap in toggle mode).**

---

## 4. Zone tunneling and sampling failure modes (and standard mitigations)

Our symptom signature — *staged tests with simulated hands pass; live play is
intermittent* — is exactly what the following failure modes produce. The
simulated hand in a staged test is teleported/parked inside the zone and
*then* squeezes, in order, at physics rate. A human hand does none of those
things.

**The arithmetic (Godot defaults; hand speeds are typical-range estimates):**

- Default physics tick is **60 Hz** (Godot's physics troubleshooting docs list
  60 as the default and suggest 120/180/240 as multipliers) → 16.7 ms between
  physics samples. HMDs render at 72–120 Hz, so physics-rate interaction tests
  sample the hand *less often* than the player sees it move.
- Hand displacement per physics step: 0.5 m/s → ~8 mm; 1 m/s → ~17 mm;
  2 m/s → ~33 mm; 3 m/s → ~50 mm. A natural grab approach is commonly in the
  1–2 m/s band in the last 10 cm.
- Samples inside a spherical zone of radius *r* crossed through its centre:
  ≈ 2r / (v·Δt). For a knob-sized zone (r = 25 mm): ~3 samples at 1 m/s,
  ~1.5 at 2 m/s, ~1 at 3 m/s — and off-centre chords are shorter
  (2√(r²−d²)), so grazing approaches get **zero** samples inside. The hand
  was "on" the lever to the player's eye; no sample ever saw it there.

**Failure mode A — conjunctive coincidence.** The test requires *grip edge*
and *inside zone* to be true in the same sample (or requires zone-entry to be
observed before the edge is accepted). Humans pre-squeeze: the squeeze starts
2–5 cm *before* contact, so the threshold crossing typically fires while the
hand is still short of the knob, and the crossing into the zone happens a few
samples later with no new edge. Result: perfect grabs read as nothing.
Slow, deliberate, staged-style grabs (park, then squeeze) work every time —
which is why the failure is intermittent and correlates with how *confidently*
the player moves.

**Failure mode B — physics Area3D overlap transience.** Overlap lists are
computed at physics flush; a fast pass can enter and exit between flushes, or
never register in `get_overlapping_*` at the moment it is polled (a known
Godot forum-reported behaviour for high-speed Area3D; Godot's official
troubleshooting gives the matching remedies: make collision shapes **thicker
than the visual**, scale the shape with speed, or raise the physics tick
rate; forum consensus adds ShapeCast3D sweeps). Any lever logic built on
area-entered/exited events inherits this wholesale.

**Failure mode C — continuing-membership dropouts.** If staying grabbed
requires staying in the zone (or staying above one analog threshold with no
hysteresis), normal hand tremor and the natural arc of the pulling hand —
which moves *away* from the knob along the throw — break the condition
mid-throw. The lever "sometimes don't" work even after a good grab. XR Tools
and VTOL both eliminate this class entirely by latching (§1, §3).

**Failure mode D — runtime bool threshold (see §2).** If any part of the
chain reads the squeeze as a runtime-converted bool, the press point is
VDXR's undocumented choice and can differ from the float value the DIAG
displays — the display says "squeezing," the bool says "not yet."

**Standard mitigations, in the order the field applies them:**

1. **Latch semantics** (§1/§3): zone/proximity is only a *candidate*
   condition; the press edge latches; only the release edge unlatches.
2. **Temporal buffering ("coyote time" for grabs):** accept a press edge that
   occurs within a short window (~100 ms) before zone entry, and a zone entry
   within the same window after an edge. This single change kills failure
   mode A.
3. **Decoupled capture volume:** interaction radius 2–4× the visual knob
   (XR Tools' default is a 0.3 m *radius* sphere — an order of magnitude
   bigger than a lever knob), nearest candidate wins.
4. **Swept tests instead of point tests:** segment (previous hand position →
   current position) vs. capture sphere, or a ShapeCast3D along the hand's
   per-step motion — the documented fix for mode B.
5. **Do the test with distance math at render rate** (`_process`), not with
   physics areas at physics rate: for fixed cockpit controls the lever
   positions are known constants, so `hand_pos.distance_to(knob_pos)` each
   render frame is cheaper, deterministic, and immune to physics-step
   aliasing.
6. **Own hysteresis on the analog value** (§1/§2), tuned from logged live
   peaks.
7. **Feedback on candidate and latch** (highlight + haptic pulse; haptic tick
   at detents): converts silent misses into instantly-correctable ones.

---

## 5. Ranked recommendations for our hand-rolled system (Godot 4.7)

1. **Rebuild lever grabbing as latch + projection.** Per hand, maintain a
   *candidate* lever (nearest knob within capture radius, updated every render
   frame by distance math). On grip-press edge, latch to the candidate and
   store the hand's transform relative to the lever pivot. While latched,
   drive the throw purely by projecting hand motion onto the lever's arc;
   ignore zone membership entirely. Unlatch only on the grip-release edge.
   (Fixes modes A and C; this is the XR Tools + VTOL consensus design.)
2. **Read squeeze as float everywhere; set our own hysteresis.** Press at a
   high threshold, release at a clearly lower one (XR Tools uses ±0.1 around
   a configurable centre — copy the *structure*). Audit every read of the
   squeeze: any `grip_click` / bool read in the chain imports VDXR's
   undocumented threshold and must go. Log live per-hand squeeze peaks for a
   session and set the press threshold from those numbers.
3. **Add grab coyote time (~100 ms both directions).** A press edge just
   before capture-radius entry, or entry just after an edge, still latches.
   Cheap, and specifically targets the pre-squeeze habit that makes live
   grabs fail while staged grabs pass.
4. **Grow the capture radius to 2–3× the knob visual** and resolve
   multi-control overlaps by nearest-knob-wins. Our levers sit close together
   on one dash face; nearest-wins is what keeps a fat radius from causing
   cross-grabs (and stage 44's arc sweep stays as the guard for actuation
   *effects*, while selection is by distance).
5. **Give every state change a witness:** highlight/emissive on candidate,
   haptic pulse on latch, haptic tick at the detent and at both arc ends,
   lever visibly in the hand (hand pose closes on the knob). No silent
   failures: if it didn't buzz, it didn't grab, and the player knows before
   the drop, not after.
6. **Consider VTOL-style toggle as an option for the drop lever
   specifically:** tap grip to latch, tap again to release (hold-to-release
   still honoured). The drop lever is worked during the crane dangle, often
   one-handed while the other hand holds the wheel — it is the worst possible
   control to require a sustained crush-grip from. This is a design decision
   for the owner, flagged here because VTOL ships exactly this option for
   exactly this reason.
7. **Instrument, then judge:** before the next feel verdict, record one live
   session's per-hand squeeze traces + latch/drop events (the DIAG already
   surfaces GRIP/CLK/FRC). If a hand flatlines at 0.00, that's a
   binding/profile problem to fix in the action map, not a tuning problem;
   if peaks cluster low, that's a threshold to lower. No more staged-pass
   verdicts on a live-path disease.
8. **Only if physics areas are retained anywhere in the chain:** sweep them
   (ShapeCast3D along hand motion) or raise physics ticks to 120 — the
   documented Godot remedies. Prefer recommendation 1/5's distance math,
   which makes this moot for cockpit controls.

---

## Sources

- Godot XR Tools — Pickup Function docs:
  https://godotvr.github.io/godot-xr-tools/docs/pickup/
- XRToolsFunctionPickup source (vendored copy in a third-party project; action
  wiring appears locally adapted, structure as shipped):
  https://git.vrg.party/hiina/xrjamfeb2025/raw/commit/76bf56d8d5b9906136c2d5cc8f6d77b6d49e65a5/addons/godot-xr-tools/functions/function_pickup.gd
- XR Tools changelog (v3.1.0, "Use value based grip input with threshold"),
  vendored VERSIONS.md:
  https://gitty.informatik.hs-mannheim.de/2110867/Paradox_VR/src/commit/cc0d4df4dc66adf0395102dec174137250cbbe1d/addons/godot-xr-tools/VERSIONS.md
- Godot documentation — The XR action map (runtime-managed bool thresholds;
  "use the Float type… and apply your own threshold"):
  https://docs.godotengine.org/en/stable/tutorials/xr/xr_action_map.html
- OpenXR Specification (boolean-from-scalar conversion: runtime threshold +
  hysteresis "left as an implementation detail"):
  https://registry.khronos.org/OpenXR/specs/1.1-khr/html/xrspec.html
- Unity OpenXR — Meta Quest Touch Plus controller profile (squeeze/value
  only; gripPressed is a float cast; trigger/force present, squeeze/force
  absent):
  https://docs.unity3d.com/Packages/com.unity.xr.openxr@1.17/manual/features/metaquesttouchpluscontrollerprofile.html
- Godot XR controller input naming (grip_click vs grip pressure values),
  Snopek Games tutorial:
  https://www.snopekgames.com/tutorial/2023/how-make-vr-game-webxr-godot-4/
- Road to VR — VTOL VR hands-on / developer interview ("soft lock", haptics):
  https://roadtovr.com/vtol-vr-hands-on-developer-interview-paolo-encarnacion/
- VTOL VR settings wiki (Toggle Grip; Flight Control Haptics) — community
  wiki, treat as observational:
  https://vtol-vr.fandom.com/wiki/Settings
- Gaming Nexus — VTOL VR preview (haptic grasp confirmation on controls):
  https://www.gamingnexus.com/Article/5486/VTOL-VR/
- Godot documentation — Troubleshooting physics issues (tunneling remedies:
  thicker shapes, speed-scaled shapes, higher tick rates; 60 Hz default):
  https://trinovantes.github.io/godot-docs/tutorials/physics/troubleshooting_physics_issues.html
- Godot forum — "Area3D not detecting anything at high-speeds" (ShapeCast
  remedy):
  https://forum.godotengine.org/t/area3d-not-detecting-anything-at-high-speeds/135933
