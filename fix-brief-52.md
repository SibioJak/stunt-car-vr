# FIX BRIEF 52 — THE FLIGHT, REPAIRED: kill the backward tilt, restore ordinary pace

Base: `df7886e` (FP51). Stamp: **FP52 · 2026-11-08**.

FP51 shipped the flight model and the seat rejected it as tuned (Chris, 2026-11-08, with a ~110 s driving video on Track 01). His words: "If you go fast off a jump, you almost fly, even off little jumps, and it starts tilting backwards, beyond control. It's making little hills near corner more difficult because I seem to be flying forward more."

The film shows: repeated AIRBORNE banners off ordinary hills at pace; around 0:23 a launch off the climb rolling BACKWARD through the flight, past vertical, arriving DAMAGED and off the road into a crane lift; the same again off the ridge near 1:44. This pass is a repair, not a redesign: FP51's three mechanisms (conservation, trim, roof ruling) all stay — what changes is where they fire and whether the driver can fight them.

## Item 1 — Convict the backward tilt (measure on driven roads first)

FP51's lab census recorded violent separations as NOSE-DOWN; the driven car at driven speed leaves crests NOSE-UP and keeps rotating backward, beyond the trim's authority. The staged pins did not reproduce the driven car — the staged-driver gap, again. Before touching production:

- Instrument separations on DRIVEN laps (the census driver at real pace, Track 01's hills and the ribbon staircase, several laps): per separation — speed, road pitch rate through the approach, the measured separation rate and its sign, peak attitude travel, arrival grade. Report the distribution, ordinary hills included.
- Convict, with that evidence, where backward (nose-up) rotation is born: candidates include the approach-rate measurement's sign or window at real speed, the low-pass lagging the crest so the rate read at separation belongs to the climb face, or the film build's stand-down letting a nose-up rate the old model used to correct run free. Name the convicted layer in the report; the fix follows the conviction, not this list.

## Item 2 — Ordinary pace gets its manners back

Pass condition, in the owner's terms: little hills near corners at speed are HILLS again — the car leaves the ground the way FP50's did (brief hops, film-shaped arrivals), and a working lap of Track 01 at pace carries no backward-rotating flights and no DAMAGED arrivals off ordinary terrain. Concretely:

- Conservation must not engage on ordinary traffic. Whatever gate survives Item 1's conviction — direction, threshold, or a speed/terrain condition — is set from the DRIVEN distribution measured in Item 1, with the margin stated as numbers: the fastest ordinary separation measured vs the gate.
- FP50's flight behaviour at ordinary pace is the regression target: the before/after probes on staged ordinary flights already exist from FP51; the driven-lap flight census (flights per lap, air time distribution, grades) on Track 01 must return to FP50's character. FP50's census numbers are on file in its report; if a driven-lap baseline must be re-measured on `3e63d20`, measure it — do not argue from staging.

## Item 3 — The trim must be able to win

"beyond control" is the second count. On any flight the gate lets through below the genuinely-violent country, full opposite trim must be able to arrest the rotation and bring the car back toward a landable attitude within the flight's own duration. Measure it: staged and driven flights at the top of the ordinary band, trim held against the rotation from separation — rotation arrested, arrival gradeable. If the trim's authority (0.50 rad/s²) cannot do it at the top of the ordinary band, the gate is set where it CAN — the line between "the driver can fight it" and "violence" is drawn by the trim's measured strength, and that reasoning goes in the report. The genuinely violent case (staircase at lap pace, the end-over-end case) stays beyond saving by design — that was the order.

## Protected

- FP51's mechanisms and rulings: conservation above the gate, trim direction (throttle up / brake down) and its 0.35 s arming, the ROOF ruling and crane stand-in, the DAMAGED bottom grade. This pass moves gates and fixes the convicted defect; it does not re-open the design.
- Everything FP50 and earlier field-passed: ground behaviour, gearbox, funlab, census discipline. Economy numbers report-only, never retuned.
- The commands list names every command; if any control changes, the list updates in the same commit (none is expected).

## Proof and gates

- The Item 1 driven-separation census, before and after the fix, on Track 01 and the ribbon: separation rates with signs, flights per lap, grades per lap.
- Dense frames across one driven backward-tilt flight BEFORE the fix (the moving part's path traced) and the same terrain AFTER: no backward rotation at ordinary pace.
- The staged violent case still goes over end-to-end (FP51's strip case re-run): the repair must not quietly un-invent the tumble.
- Full gates: preflight clean, smoke green (any amended stage re-derived with its reason flagged in place, in the house style), API guard green, render proof with captures regenerated for real. HARD TIMEBOXES on every run; scratch in ~/fp52-scratch/; probe tooling never committed; no *.uid / *.png.import sidecars.
- Report in the standard shape: the conviction and its evidence, the gate and its margin in numbers, before/after driven censuses, trim-arrest measurement, gates, commit — and what remains unverified until the seat judges.
