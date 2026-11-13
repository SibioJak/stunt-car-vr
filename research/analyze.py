#!/usr/bin/env python3
"""Per-game-update tracker for Stunt Car Racer cockpit footage.

For each game-state frame in a window, measures:
  tireL, tireR : row (half-res px) of the top of each front tire at the
                 windshield edge (smaller = tire sits higher in frame).
  wdy          : accumulated vertical shift of the windshield world content
                 vs window start (phase correlation, + = world moved down).
Game states are detected by a windshield diff threshold (codec noise floor
is ~0.02; real updates are >0.5).
"""
import subprocess, glob, os, sys
import numpy as np
from PIL import Image

SRC = 'original-all-tracks.mp4'

def extract(start, dur, tag):
    d = f'seq/{tag}'
    os.makedirs(d, exist_ok=True)
    if not glob.glob(d + '/*.png'):
        subprocess.run(['ffmpeg', '-v', 'error', '-ss', str(start), '-i', SRC,
                        '-t', str(dur), '-vf', 'scale=960:540,format=gray',
                        d + '/f%04d.png'], check=True)
    return sorted(glob.glob(d + '/*.png'))

def tire_top(fr, x0, x1):
    band = fr[275:385, x0:x1]
    dark = band < 70
    rows = np.where(dark.sum(axis=1) >= 6)[0]
    return (rows.min() + 275) if len(rows) else -1

def phase_dy(a, b):
    A = np.fft.rfft2(a - a.mean()); B = np.fft.rfft2(b - b.mean())
    R = A * np.conj(B); R /= (np.abs(R) + 1e-9)
    c = np.fft.irfft2(R, s=a.shape)
    y = np.unravel_index(np.argmax(c), c.shape)[0]
    if y > a.shape[0] // 2: y -= a.shape[0]
    return -y  # + means content of b moved down vs a

def analyze(start, dur, tag):
    files = extract(start, dur, tag)
    frames = [np.asarray(Image.open(f), dtype=np.float32) for f in files]
    win = lambda a: a[80:380, 140:820]
    diffs = np.array([np.abs(win(frames[i+1]) - win(frames[i])).mean()
                      for i in range(len(frames) - 1)])
    states = [0] + [i + 1 for i, d in enumerate(diffs) if d > 0.5]
    rows = []
    wdy = 0.0; prev = None
    for gi in states:
        fr = frames[gi]
        if prev is not None:
            wdy += phase_dy(win(prev)[0:200, :], win(fr)[0:200, :])
        prev = fr
        rows.append((start + gi / 30.0, gi, tire_top(fr, 128, 176),
                     tire_top(fr, 784, 832), wdy))
    arr = np.array(rows, dtype=np.float64)
    np.save(f'seq/{tag}_trace.npy', arr)
    print(f"[{tag}] window {start}s +{dur}s | video frames {len(frames)} | "
          f"game updates {len(states)} ({len(states)/dur:.1f}/s)")
    return arr

if __name__ == '__main__':
    jobs = [
        (31, 44, 'lr'),      # Little Ramp: drop start + race to ~1:15
        (122, 63, 'hb'),     # Hump Back: opponent + humps
        (200, 75, 'ss'),     # Stepping Stones: opponent ahead
        (365, 95, 'hj'),     # High Jump: big air, smoke, crane
        (470, 95, 'rc'),     # Roller Coaster: banks, dips, crests
        (565, 80, 'db'),     # Draw Bridge: bridge jump
        (655, 95, 'sj'),     # Ski Jump: the big one + crane
    ]
    for s, d, t in jobs:
        analyze(s, d, t)
