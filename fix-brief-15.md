# Fix Pass 15 — Telegraphs, the Crane, and the Dash Face

Released by the owner (Jaklar), Wed 2026-10-28 19:39 CDT, at his
"go for go." DISPATCH CONDITION: this pass builds on Fix Pass 14's
LANDED head, not on 3ca7390. Item 0 exists for that reason. Repo:
SibioJak/stunt-car-vr, game/.

Owner context, run 14 (on FP13, verified build): "the feel is getting
there iteration by iteration. Where Im not feeling it is losing
traction, and thats around curves. it just of happens and feels too
late at that point" — followed by: "missing an audio cue or visual
cues to sell it," and the original's lesson: "in SCR you really heard
when the tires were slipping off road, as well, it started grinding,
like the chassis of your car was scraping edge." Same run: the drone
did loop-de-loops from the chair on staged-green transports; the owner
scrapped the flying carrier himself and restored the crane: "we'll
just use crane with some swing that still makes the drop a challenge."

Standing constraints: no `*.uid` / `*.png.import` commits; ClassDB
guard green; audio teardown discipline applies to every new sound
(latched kill, watchdog, silence-by-default); the in-interface
controls list names EVERY command the game accepts — any command this
pass adds or changes updates that list in the same commit; steering
lock scale ≤24 m/s stays bit-identical. Drive numbers may move only
where an item demands it, reported before/after.

---

## Item 0 — Rebase and reconcile

FP14 landed between this brief's writing and its dispatch. Read
FP14's README results section and its final constants. Where this
brief names a system FP14 changed (per-wheel grip, per-wheel
suspension/view, view coupling, hang model), build on FP14's landed
form and say so in the results. All FP13 and FP14 stages must pass on
the final tree, adapted only where an item below deliberately retires
the behaviour they stage (Item 2 retires the drone stages — replace
them with crane equivalents of equal strength).

## Item 1 — The telegraphed limit (headline)

One measured signal, several honest voices. Compute a per-wheel (or
per-axle, if per-wheel proves noisy — say which and why)
demand-vs-capacity ratio: lateral force demanded by the current
steering/speed/curvature against what that wheel's load can hold.
The signal EXISTS BEFORE breakaway — that is the whole item.

- AUDIO, pre-limit band: the tire voice gains a band below the
  existing skid. As the ratio climbs through the last stretch of the
  envelope (stage the band edges; a starting shape: audible from
  ~0.7, rising in gain and pitch to the break point), the tire SINGS
  before it SQUEALS. The existing post-limit skid is untouched below
  its own threshold. Curve driving at honest speeds must be able to
  live in the band — that is its purpose.
- AUDIO, edge family (the original's contact layer; Crammond had no
  skid, but his surfaces were audible): (a) OFF-ROAD RUMBLE — wheels
  off the ribbon produce a rumble at a slowly randomised pitch,
  gain ∝ off-road wheel count/load; (b) EDGE SCRAPE — while a wheel
  straddles and the car slides along the edge (support partial and
  lateral motion along the rim), a grinding scrape, distinct in
  character from both rumble and tire song. Both driven by the
  per-wheel support state the straddle model already computes —
  the sounds must be incapable of playing when the state says
  otherwise.
- VISUAL: contact-patch evidence scaling with the same ratio —
  dust wisps at the loaded tires from ~the band's lower edge,
  thickening toward breakaway. Cheap flat-shaded sprites/particles;
  perf budget is Quest's, keep it lean and state the cost. Load
  transfer itself is already visible via FP14's per-wheel view;
  do not double it.
- RUMBLE: controller vibration as the final-stretch warning (ratio
  above a staged high edge), light, scaling; must never fire on a
  centred straight.
- Staging: on the R30 sweeper, log ratio vs time through a
  progressive entry: the band must open measurably BEFORE slip_state
  first rises, and the scrape/rumble legs stage on a deliberate
  edge ride and an off-road excursion respectively, with negative
  controls (clean lap sections: no band, no rumble, no scrape, no
  vibration). Report the lead: how many metres/seconds of warning
  the band gives at the sweeper's honest entry speed.

## Item 2 — The crane (drone scrapped by the owner)

The flying carrier is OUT, entirely: vehicle, transport flight,
station-keeping, arrival logic. In its place, the original's rig:

- Crane posts as trackside furniture at drop points — the crane is
  JUST THERE (Crammond's own method: no crane object in his code;
  the car is placed above the piece). Staging covers Drop Start and
  the recovery drop points the walk-back rules can produce.
- Jib swings out over the road; CHAINS down to the car (the record
  says chains — manual, Drop Start account, owner's brain dump #2).
  The collection beat (fall site → chains) happens off-stage, as in
  1989; everything from the hang down is shown and physical.
- The hang keeps its game: pivot-driven pendulum from the FIXED jib
  pivot, sway irregular in the film's character (FP14 item 8's
  measurements are the baseline), wheel grabbable in the dangle,
  drop lever release, FP13's touchdown-connection/getaway system
  untouched downstream of the release.
- SWING BUDGET, stage-asserted: pendulum amplitude at the stationary
  pivot stays bounded (state the cap; no full rotations are possible
  by construction — assert it), and the Drop Start fall time stays
  in the film's 0.3–0.4 s class.
- Recovery staging replaces the retired drone stages at equal
  strength: every fall class that staged a transport now stages a
  crane recovery — placement correctness (walk-back rules and
  DROP_MIN_RUNUP_M 25.0 unchanged), hang behaviour, release,
  touchdown grades.
- Spec housekeeping in this pass: design-spec.md item 4's "drone
  (crane updated to drone — LOCKED)" reverses to the crane, noting
  the owner's 2026-10-28 decision; the wreck long-repair's arms move
  from drone to crane in the spec text (the repair show itself stays
  carnage-build scope — NOT built here).

## Item 3 — Drop lever to the dash face + lefty mirror

Owner, run 14: "its on top of dash, it want it on the side of the
dash, facing player, up/down, right side of wheel" — and "there
should be a game option to switch sides for lefties."

- The drop lever leaves the dash top. New home: the dash's
  driver-facing vertical face, RIGHT of the wheel. Vertical throw;
  detent at +0.50 and pull-DOWN-to-fire carried from FP13 unless the
  face geometry forces a change — if it does, report the change and
  why. The retired dash-top position leaves no orphan mesh or zone.
- LEFTY MIRROR: a persisted setting (user://settings.cfg, alongside
  seat trim) mirroring the lever to the dash face LEFT of the wheel.
  Switchable from the cockpit without restarting (a dash/panel
  control in the existing control language), DIAG shows the current
  side, and the setting survives relaunch. Default: right.
- Zone-vs-mesh audit re-run: 0 violations. Render proofs from the
  driver's seat, both sides, delivered with the results. Grab,
  detent, haptic pulse and release semantics are FP13's — this item
  moves the furniture, not the mechanism.

## Item 4 — The invisible road (surface only)

Two in-headset photo reports (run 14, FP12 and FP13 builds): at the
bottom of the big dip the ribbon ahead blends into the desert. FP12
diagnosed low contrast at long valley sightlines (not pop-in, not
fog) and could not move its mid_straight wash figure.

- Diagnose-first on the current tree: reproduce at the named dip
  from the driver's eye at approach speed; measure the road/desert
  contrast as rendered (the FP12 wash metric or an equivalent —
  state which).
- Fix the measured cause within SURFACE AND CONTRAST ONLY: albedo
  separation between ribbon and desert, edge-strip contrast that
  survives distance, a centreline cue — choose by measurement, not
  taste. GEOMETRY IS OUT OF SCOPE: width and banking belong to the
  tracks-meet-physics pass that follows FP14's verdict; do not move
  a single vertex of the ribbon in this item.
- Proof: before/after frames from the same staged approach, plus the
  contrast figure, in the results. The at-speed read remains the
  owner's call.

---

## Results section requirements

README gains a Fix Pass 15 section: per item, what shipped, the
staged numbers (Item 1's warning lead; Item 2's swing measurements;
Item 3's audit + setting behaviour; Item 4's contrast before/after),
every constant changed with before/after, and the honest residuals —
including anything staged-green that the owner still has to judge
from the chair.
