#!/usr/bin/env python3
"""Streaming color pass (low memory): per game state -> tireL, tireR, skyfrac."""
import subprocess, glob, os
import numpy as np
from PIL import Image

SRC = 'original-all-tracks.mp4'
SKY = np.array([73, 147, 255], dtype=np.int16)

def extract(start, dur, tag):
    d = f'seqc/{tag}'
    os.makedirs(d, exist_ok=True)
    if not glob.glob(d + '/*.png'):
        subprocess.run(['ffmpeg', '-v', 'error', '-ss', str(start), '-i', SRC,
                        '-t', str(dur), '-vf', 'scale=960:540',
                        d + '/f%04d.png'], check=True)
    return sorted(glob.glob(d + '/*.png'))

def tire_top(gray, x0, x1):
    band = gray[275:385, x0:x1]
    dark = band < 70
    rows = np.where(dark.sum(axis=1) >= 6)[0]
    return (rows.min() + 275) if len(rows) else -1

def analyze(start, dur, tag):
    files = extract(start, dur, tag)
    win = lambda a: a[80:380, 140:820]
    prev = None; diffs = []
    for f in files:
        g = np.asarray(Image.open(f).convert('L'), dtype=np.float32)
        if prev is not None:
            diffs.append(np.abs(win(g) - win(prev)).mean())
        prev = g
    diffs = np.array(diffs)
    states = [0] + [i + 1 for i, d in enumerate(diffs) if d > 0.5]
    rows = []
    for gi in states:
        im = np.asarray(Image.open(files[gi]).convert('RGB'), dtype=np.int16)
        gray = im.mean(axis=2)
        upper = im[75:300, 140:820]
        skyfrac = (np.abs(upper - SKY).sum(axis=2) < 60).mean()
        rows.append((start + gi / 30.0, gi, tire_top(gray, 128, 176),
                     tire_top(gray, 784, 832), skyfrac))
    arr = np.array(rows, dtype=np.float64)
    np.save(f'seqc/{tag}_trace.npy', arr)
    print(f"[{tag}] {start}s +{dur}s: {len(states)} states "
          f"({len(states)/dur:.1f}/s)", flush=True)
    return arr

if __name__ == '__main__':
    jobs = [
        (25, 10, 'ds'),      # Little Ramp DROP START
        (380, 26, 'hjA'),    # High Jump: the jump itself
        (408, 34, 'hjB'),    # High Jump: smoke + crane recovery
        (475, 45, 'rcA'),    # Roller Coaster first half
        (520, 45, 'rcB'),    # Roller Coaster second half
        (570, 40, 'dbA'),    # Draw Bridge: bridge jump
        (610, 38, 'dbB'),    # Draw Bridge rest
        (660, 45, 'sjA'),    # Ski Jump: climb + jump
        (705, 48, 'sjB'),    # Ski Jump: landing + crane
    ]
    for s, d, t in jobs:
        analyze(s, d, t)
