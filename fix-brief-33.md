# Fix Pass 33 (micro) — The Build Stamp

**Chris's request (2026-11-01):** "since this particular
project has this Discard Changes thing going, can we put
build name in small text, lower right, so I know for sure
I'm playing right version." Base: FP32 (2b8281b).

## Why

The clone lives in OneDrive; GitHub Desktop nags Discard
Changes over per-machine Godot sidecar churn, and a stale
build already cost one false verdict (run 14). In-view
proof of the running build ends the guessing.

## Items

1. `BUILD_STAMP` constant in scripts/main.gd (beside
   GRAB_LOG_BUILD), format exactly `FPnn · YYYY-MM-DD`;
   this build: `FP33 · 2026-11-01`.
2. A Label3D from `_make_stamp_label()` parented to the
   XRCamera3D and to the desktop fallback camera: lower
   right of the field, small, dim neutral grey, unshaded,
   no outline, no depth test. No rotation (a Y-flip
   mirrored it — caught on the first capture inspection).
3. Standing ritual, documented in the README: every
   future fix pass updates BUILD_STAMP at delivery;
   smoke stage 62 format-checks it (regex) and asserts
   both labels' text equals the constant verbatim.
4. Render proof capture 31 (build_stamp_view.png): the
   stamp visible in the lower right; its projected rect
   fully inside the frame and clear of both boards'
   text rects.
5. Nothing else: no physics, no input, no census
   movement beyond the new checks.

## Gates (as run)

- Preflight: engine `--import` clean (standing XR
  settings warning only); the stamp regex probe-verified
  against good/bad strings before the suite ran.
- Smoke: ALL 642 (FP32's 636 + stage 62's 6); API guard
  ALL 71; zero engine errors (the OpenXR loader noise is
  the sandbox having no runtime).
- Render proof: 171/172 — the one failure is the
  pre-existing sandbox hub-reach artifact, identical on
  the FP31/FP32 baseline proofs. Capture 31 inspected by
  eye: the stamp reads "FP33 · 2026-11-01", lower right,
  centre at 77% × 84% of the frame.
- UNVERIFIED (the device's verdict): in-headset
  legibility of the stamp.
