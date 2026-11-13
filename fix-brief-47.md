# FIX PASS 47 — THE LOOP AS A HOOP: A STRUCTURE THE ROAD THREADS

Repo: ~/workspace/stunt-car-vr, Godot project in game/. Branch master.
**Base commit: 6c78f34 (FP46). VERIFY FIRST: `git log --oneline -1` must show 6c78f34
before any edit.**

## Why this pass exists — read this first

Three passes have now produced the same result (owner's words: "I keep getting the
same result back… visually it's completely wrong… I'm driving through the loop to
get to the loop"). The failure is structural, and it is in the briefs, not the
concept: our track system builds ROADS — a centreline skinned as a 12 m ribbon —
and every pass asked that system for a loop, so every pass got a curled road: a
wide wall that curls overhead. FP41 made the curl drivable, FP43 made it
symmetric, FP46 put signs on it. From the side a curled ribbon is a perfect ring;
from the driver's eye (the only seat that matters) it is a wall — no hole, no sky,
and the descending leg overhangs the approach so the driver passes UNDER the
structure before the road climbs.

Hard Drivin' did this loop in 1989 because its loop is what the owner's reference
photo shows (READ IT: ~/workspace/user/media_library/image/Loop-de-Loop.webp): a
HOOP — a structure standing on the ground, its hole open to the sky — and the road
runs flat into its base and bends up its inside. This pass builds THAT. The
owner's words for the transition: "its gotta bend/twist."

## The element, rebuilt

1. **A structure, not a curl.** Build the loop as a placed object: a hoop band
   following a vertical circle, with visible structure — band thickness, an outer
   rim, side supports/struts planted on the ground beside the road. The band is
   NOT the road ribbon and must not inherit the ribbon's skirt/underside. The
   FP46 rails and portal are superseded by the structure itself (remove or absorb
   them; the chequer threshold may stay).
2. **The legs meet at the base.** Entry and exit legs cross/meet at ONE base
   zone (within ~2 m), clothoid-style: there is no ground-level run through the
   ring's footprint and nothing overhangs the approach. The road arrives flat,
   reaches the base point, and bends up. The exit resumes the same straight.
3. **The bend.** The driving surface transitions from the flat bed into the
   hoop's inner surface with a curvature RAMP (clothoid feet at both ends), not
   a tangent-to-circle step. The surface the car drives is the hoop's inner face
   through the element.
4. **The hole stays open — proportions.** From the driver's eye the ring's hole
   must show sky at every approach distance. Reference proportion (the photo):
   ring diameter ≈ 5–6× the driving-surface width. Ours was 2.15× (Ø 25.8 m vs
   12 m road) — the far leg filled the hole. Reach the proportion by ring size
   and/or narrowing the surface through the element (flared transitions at the
   feet), builder's design — with these guardrails: crown hold speed √(gR) must
   keep the clean band's floor at or below ~20 m/s (a toy loop takes a mid-pace
   car; if your R forces the floor higher, narrow the surface or revisit R);
   the drive stays honest — no grip or gravity cheats to manufacture the band.
5. **Design from the driver's eye, in that order.** Render the approach frames
   (120/80/50/30/15/5 m, driver's eye) from the NEW geometry BEFORE finalizing
   the drive profile, and judge them against the photo: hoop, hole, sky, the bed
   bending up. Only then fit and prove the drive.

## Drive proof (after the form)

Re-derive the element's drive board completely: clean band (pins across it),
floored behaviour, edge pins (below-band separation must fail honestly — fall
inside the ring to the road, crane collects; never a wedge), exit on the entry
line. Update the E1 board text to the new band. Re-derive the E1 jump-in if
stations move. The BOWL (E2), its board and jump-in are untouched except any
station shift the new element forces — report it if so.

## Standing gates (every pass)
Full smoke green incl. the ClassDB API-surface guard (71); Track 01 / ribbon /
Feature Lab census UNMOVED — any exception confessed with a one-variable proof.
Rendered-frame proof: driver's-eye approach series before/after AND an external
side frame of the finished hoop. Preflight GDScript audit clean. No *.uid or
game/tests/*.png.import sidecars. BUILD_STAMP = "FP47 · 2026-11-04". Commit on
master, push, VERIFY with git ls-remote. TIMEBOX every run; a hung run is killed
and reported, never sat on.
Report: the new geometry (R, surface width through the element, base crossing,
clothoid feet), the hold band measured, the approach-frame verdict against the
photo, every re-derived number, commit hash, suite totals.
