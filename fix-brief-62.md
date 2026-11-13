# FIX BRIEF 62 — THE KICK GETS WIRED

Base: `715e915` (FP61, current remote HEAD). Stamp on ship: FP62 · 2026-11-13.
Owner's go (tap, 2026-11-13): build the kick fix the recording named.

## What the recording convicted (`~/kick-scratch/TRACE-REPORT.md`, read it)

- When the car leaves the ground because its tires unloaded, the flight is born from the road's rise rate plus a **flat 0.35** increment — the same at every speed, every load, every crest (the gap route gets +0.0). The hoppy crests in the owner's videos are the road's rise plus that token; the springs contribute **0.00 m/s**, measured.
- Worse, the body's spring-driven upward motion at the moment of leaving is **discarded**: the heave was carrying the body up at 0.27–0.63 m/s into the lip separation and the flight's increment read exactly 0.000.
- The game has one real spring-to-flight converter — the landing throw (`clamp(−(cv_f+cv_r)·0.55, 0.5, cap)`, fired +3.05 m/s on a flat lap stretch) — but it is gated to landings on four conditions (deep stored compression, full support, armed gate, unspent chain) that an unload fails all of. **The kick exists; it was never wired to unloads.**

## The item

For **load-driven separations only** — the car leaves because its tires unloaded (the press/geometry route; the ramp, the crests, the hops) — the flat 0.35 dies. The birth increment is priced from the suspension's state at the moment of separation:

- the body's spring-driven upward velocity (the heave the current code discards) is **inherited**, not zeroed; plus
- an extension-priced term in the landing throw's own family (the 0.55-style pricing of the corners' compression/extension state), so a separation with genuinely loaded, snapping-back springs leaves harder than one whose springs are already spent.

Rails:

- **Bounded, in the throw's family:** the total increment gets a stated cap, measured and reported — never above the throw route's own caps. No unbounded energy, ever.
- **Honest accounting:** the increment spends only what the suspension state holds at that separation. Where the state is spent, the increment is small and that's the truth — report the ramp's numbers as they land (at the ramp unload the inside springs read near-full extension; the loaded outside pair is where the stored state lives — the pricing reads the car's state, not one corner's).
- **The drumbeat must not pump:** consecutive hops (the ridge humps, the staircase) each price only their own separation's state. The census must show hop heights in a chain do NOT grow hop-over-hop from the new term; FP14's chain/pogo guards are re-argued for unload-born energy, in writing, in the commit.
- **Routes kept separate:** gap entries keep +0.0; off-edge/fall entries keep their terms; the landing throw and its four gates are UNTOUCHED — this pass wires a second, smaller door for unloads, it does not re-gate the throw.

## Proof

- The kick recording's instrument re-run: at the ramp and at the lip, the leaving speed now splits road vs spring with the spring share priced and non-token where the state holds energy; the same split quoted at the control crest (s417 family).
- Whole-game census per track (standing standard, never a sample): air times, landing-grade distribution, departures — against FP61's reads. The drumbeat chain priced hop by hop.
- Fixtures: the landing fixtures (the throw's staged reads) hold byte-class; air-time-pinned witnesses re-derived where they honestly move, flagged in place; stage 54 audit repricing reported plainly.
- Dense seat frames at the ramp's leaving: the car visibly kicked — nose/body rising off the ramp — or the numbers explaining the size of what the seat gets.

## Protected

- FP60's tax re-price, FP61's sideways transfer, the catch, the flight model beyond the birth increment (conservation, trim, gates untouched), boost dials, track geometry, smoke/flames/world/crane.
- If honest pricing at the ramp yields ~nothing because the state there is spent, STOP and report — do not invent energy to make the number pretty. That finding would move the fix to a different family, and the choice is the owner's.

## Verification shape

- Timebox every run; total budget 3 hours; commit what's proven inside it. Order: the increment + cap sizing at the ramp → census + drumbeat check → witness re-derivation → ONE full smoke run → API guard → render proof (standing pair expected).

## Report

Trimmed: the pricing in one sentence, the cap's value, the ramp/lip/crest leaving splits before/after, the census deltas, the drumbeat verdict, gates, commit. Close with the judging line — leaving that ramp — as the seat's call.
