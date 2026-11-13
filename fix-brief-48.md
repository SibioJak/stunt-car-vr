# FIX PASS 48 — THE LOOP, RIGHT-SIZED: NARROW SURFACE, ROLL CLOSED INSIDE, CLEAN BASE

Repo: ~/workspace/stunt-car-vr, Godot project in game/. Branch master.
**Base commit: 25c7c10 (FP47). VERIFY FIRST: `git log --oneline -1` must show 25c7c10
before any edit.**

## Why this pass exists

FP47 built the right FORM (a hoop, legs side by side, sky through the hole) and
the owner drove it: "we're getting there, but not there." His video convicts
three things (both driven attempts end AIRBORNE off the descending side):

1. **The ring is a skyscraper.** FP47 bought the open-hole proportion with
   height (crown +49.77 m). A ~50 m crown means a ~50 m fall down the back:
   the car arrives at the descent's bottom at speeds no driver manages on a
   surface that is also rolling. Proportion must come from the other side of
   the ratio — the toy track is narrow, the ring modest.
2. **The exit roll was apologised away, not closed.** FP47's twist left ~27–35°
   of transported roll at the exit foot, re-levelled over the following 90 m.
   The owner, verbatim: "the loops exit has too much tilt, I don't think full
   loop is possible like that." An element isn't finished if the road after it
    has to straighten it up.
3. **The base is a construction site.** At the side-by-side feet: a support
   post stands IN the roadway between the lanes, and the exit slab overlaps
   the entry's edge with a gap under it ("weird construction at the base").

Also carried as law from FP47's failure: its "clean 18–26" was RECORDER-clean —
the staged driver steered by an in-plane bearing law a human eye cannot
replicate on a rolling surface. Proof in this pass must be human-plausible
(see Proof).

## The rebuild (TRK2, E1 only; the bowl is untouched this pass)

KEEP from FP47: the hoop as structure (band, cheeks, outer rim, supports), the
shallow-helix drift (descending leg lands beside the ascending leg), clothoid
feet, the chequer threshold, sky through the hole from the approach.

1. **Right-size it.** Ring radius back to the 16–18 m class (crown ~32–36 m),
   and narrow the driving surface through the element to ~6 m, flaring to the
   full 12 m at the feet over a clean transition. Target proportion: ring
   diameter ≈ 5–6× the surface width through the element — reached by the
   narrow surface and the modest ring together. The lateral drift stays one
   SURFACE width (the narrowed width) so the legs land side by side as in the
   owner's model.
2. **Roll closes inside the element.** The surface's roll (bank channel) is a
   designed budget: 0 at the entry foot, whatever the twist needs mid-ring,
   and **0 at the exit foot by construction** — the twist's holonomy absorbed
   inside the element by counter-roll distribution, NOT by any re-level run on
   the following road. Mesh and drive frame must read the same roll (the car
   exits level because the ROAD is level). The 30 m after the exit foot are
   flat, full stop — assert it in the suite.
3. **The base, built clean.** Entry and exit lanes side by side, coplanar and
   flat at the feet. Every support/gusset plants OUTSIDE the driving lanes —
   nothing stands in the roadway, nothing overlaps a lane's edge, no gap under
   a slab at either foot. The footing pad sits below the lanes or beside them.
   Prove with driver's-eye frames from the approach and a low external frame
   of the base zone.
4. **Board.** Re-derive the drive board honestly and rewrite the E1 board text
   to match what the driver must actually do (if it still asks for steering
   through the arc, say how much and why; if it takes a centred wheel at band
   speeds, say that). Jump-in re-derived if stations move.

## Proof — human-plausible, through the exit

- Pins across the band run from the run-up THROUGH the ring, the exit foot,
  and 30 m beyond on the flat. A pin only counts clean if it is still clean
  at +30 m past the exit.
- The staged driver for this element uses the SAME steering law as the staged
  laps on the other tracks (road-following, human-plausible gains). No special
  in-plane/bearing steering law invented for this element. If the element
  cannot be staged clean under the ordinary law, that is a finding about the
  element — report it, do not engineer the driver around it.
- Report entry speed AND exit speed per pin (the descent's gain is part of
  the element's honesty) and the exit-foot roll per pin (must read ~0.0°).
- Driver's-eye approach series + base frames as in FP47.

## Standing gates (every pass)
Full smoke green incl. the ClassDB API-surface guard (71); census outside TRK2
UNMOVED, exceptions confessed with one-variable proof. Rendered-frame proof.
Preflight GDScript audit clean. No *.uid or game/tests/*.png.import sidecars.
BUILD_STAMP = "FP48 · 2026-11-05". Commit on master, push, VERIFY with
git ls-remote. TIMEBOX every run; a hung run is killed and reported.
Report: the new geometry (R, surface width, crown height, proportion), the roll
budget (mid-ring peak, exit-foot readings), the pin table with entry/exit
speeds, the base construction, every re-derived number, commit hash, suite
totals.
