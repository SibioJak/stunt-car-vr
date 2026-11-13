# FIX PASS 38 — TRK2: THE FUNLAB (loop, corkscrew, barrel roll)

Stunt Car Racer VR, Godot 4.7, ~/workspace/stunt-car-vr/game. Base: master
7ea339d (FP37). Chris's order (2026-11-02): "and I still need a loop,
barrel roll, corkscrew funlab, TRK2" — queued behind Track 01, which
landed as FP37. BUILD_STAMP -> "FP38 · 2026-11-02" per the ritual.

## THE BUILD

1. SLOT: a FOURTH track appended to the roster. TRK cycles
   Track 01 -> ribbon -> Feature Lab -> TRK2 -> Track 01; the dash
   panel names it TRK2. The lab and Track 01 are untouched.
2. FORM: not a race circuit — a straight-line test course in the
   Feature Lab's spirit, staged in empty country at (-1600, 30,
   -1400) heading -z, 849 m, open, Drop Start at the head (s 2),
   crane recovery throughout, lab-style 15 m section stripes.
3. ELEMENTS (all SURFACE pieces — the road does the rolling; the
   car is never spun by code), each with an honest run-up/run-out
   and a roadside board (lab style: post + billboarded amber name)
   carrying a second, pale-blue advisory line with the measured
   ruling:
   - E1 THE LOOP (s 110-192): full vertical loop, mouth on the
     racing line (legal under FP23's tombstone: purpose-built,
     on-line). Regular 82-gon at a constant pitch rate of
     360 deg/82 m — closes EXACTLY (residual 0.0000 m off the
     built arrays), R ~= 13.05 m, crown 26.1 m over the entry.
     110 m flat head before it, 120 m flat run-out after.
   - E2 THE CORKSCREW (s 342-502): 360 deg of bank while
     descending at -6.5 deg (helix): 10 m ease-in, 140 m full
     rate, 10 m ease-out; drops ~= 18 m. Entered off a 20 m pitch
     ramp + 10 m hold at -6.5 deg; 20 m ramp out, then a +7 deg
     climb home and 40 m flat.
   - E3 THE BARREL ROLL (s 667-719): the same 360 deg of bank in
     52 m on the flat — one quick twist at racing pace, rate
     profiled (slow-fast-slow). 130 m flat run-out to the finish.
   Builder note: _gen_step applies cos/sin of the accumulated
   pitch/bank, so after a full 360 deg the builder resets
   _gen_phi/_gen_bank to 0.0 — otherwise every later walk would
   unwind the piece it just built.
4. PROOF: staged drives attempt each element across an entry-speed
   sweep (floored + pinned policies, lane-keeping driver) and the
   outcome table lands in the README; stage 66 re-asserts the
   headline outcomes in-suite. The course is traversable end to
   end with the crane covering the failures (below).

## THE VERDICTS (measured — the deliverable)

1. E1 THE LOOP — DOES NOT WORK at any speed; the car WEDGES AT
   THE VERTICAL. All 11 probe configurations (floored entries
   14-42, governed-to-11.5 entries, a coast entry) end identically:
   climbs the front wall fully supported (loads 0.61-1.00) and
   stops at road pitch phi ~= 87.8-92.2 deg, ~20 m into the piece.
   Stall trace (entry 18 floored): s = 130.4, phi = 87.8 deg,
   speed 48.0 (clamp), DRIVE, y = 43.4 — bit-identical from
   t = 17 s to t = 167 s. No separation, no fall, ever. Mechanism:
   DRIVE velocity is a HORIZONTAL 2D vector and road progress is
   re-derived by projection, so progress ~ vf*cos(phi) -> 0 at a
   vertical road — a singularity in the drive model, not a grip
   failure. NO minimum clean entry speed exists; the crown (and
   the whole back half, 52 of 82 m) is never presented to a driven
   car. Not a soft-lock: the crane (L X) extracts the wedged car
   and drops it at s 86.4, on the flat before the loop. Board:
   "NO CLEAN SPEED - IT WEDGES AT THE WALL".
2. E2 THE CORKSCREW — NEVER COMPLETES; lets go SIDEWAYS ~15 deg
   short of inverted. Floored entries 14-44 all crane out (the
   descent accelerates every entry to separation speeds 41-48;
   first separation at bank ~= 110-113 deg). Held entries 20/26/32
   get deep: one air episode, separation at s ~= 415-417, bank
   164-168 deg. Dense trace at held 26: loads decline 1.00 ->
   ~0.55 by bank 122 deg (patch tax of the twist) but the car is
   still ~1/3 supported at the end and the suspension route never
   fires (wheel-air flags stay false). The failure is lateral:
   car_lat walks 0.07 -> 7.14 m between bank 6 and 153 deg with
   speed pinned and the lane-keeper centred — past ~90 deg of
   bank the frame's sideways points at the sky and a horizontal
   velocity vector cannot hold the centreline; at bank ~= 153 deg
   the left samples pass the rolled edge (support cut), at
   ~= 165 deg the centre passes the fall line (lat 7.98 vs the
   7.17 threshold) -> lateral-exit door (air_vel.y = -2.93, no
   bounce). No clean speed; furthest line is held ~20 (bank
   167.8 deg). Board: "NO CLEAN LINE - HELD 20 GOES FURTHEST".
3. E3 THE BARREL ROLL — WORKS, WITH A TOSS; completes at every
   speed tried, never clean. Floored 20-44 all complete (exits
   41.4-48.0, max |lat| 3.0-5.7). Held 26: exactly one separation
   at s 715.3, bank 350.6 deg (the exit untwist unloads all four
   patches together; air_vel.y = +0.35, the geometry route's
   signature), lands, exits at entry speed. Held 36 adds a
   mid-roll separation at bank 90.8 deg, 7 episodes, still
   completes. Trace detail at held 26: left corners separate and
   return at bank ~107 deg; all patches slam to the 1.25 clamp
   at ~222 deg (valley phase). Board: "ANY SPEED - ONE HOP AT
   THE EXIT".

## CENSUS

Two amendments, FLAGGED in place: stage 11a (second TRK sweep
lands on funlab, not circuit — roster geography only; subject
unchanged) and stage 58 (wrap check asserts lab -> funlab; stage
66 asserts funlab -> circuit). Everything else byte-identical.

## HOUSEKEEPING OWED FROM FP37

The render proof could not complete in FP37's sandbox (memory
pressure; 42 checks reached, FP36's captures shipped). FP38
re-runs the FULL render proof on current code and reports it
cleanly; if the sandbox defeats it again, it says so exactly.

## GATES

Preflight audit clean; parse warnings-as-errors clean; ClassDB XR
guard ALL 71; full smoke ALL 734 CHECKS PASSED (716 at FP37 + stage
66's 18; stage 66's drive outcomes reproduced to the digit across
two full runs). Render proof — FP37's unfinished housekeeping —
RAN TO COMPLETION on FP38 code: 172 of 173 checks passed, the
single failure the standing hub-reach artifact (wheel hub 0.31 m
below the eye; identical on the FP31-FP36 baselines; nothing here
touches cockpit/wheel geometry); the fresh FP38 capture set ships
in the stages commit. No *.uid / *.png.import in the commit.
