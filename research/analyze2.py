#!/usr/bin/env python3
"""Color pass: per game state measure tire rows, sky fraction of the upper
windshield, and the world silhouette row (pitch proxy)."""
import subprocess, glob, os, sys
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
    imgs = [np.asarray(Image.open(f).convert('RGB'), dtype=np.int16) for f in files]
    gray = [im.mean(axis=2) for im in imgs]
    win = lambda a: a[80:380, 140:820]
    diffs = np.array([np.abs(win(gray[i+1]) - win(gray[i])).mean()
                      for i in range(len(imgs) - 1)])
    states = [0] + [i + 1 for i, d in enumerate(diffs) if d > 0.5]
    rows = []
    for gi in states:
        im = imgs[gi]
        upper = im[75:300, 140:820]
        skyfrac = (np.abs(upper - SKY).sum(axis=2) < 60).mean()
        # world silhouette: topmost non-sky row in center columns of upper win
        colreg = im[60:330, 300:660]
        notsky = (np.abs(colreg - SKY).sum(axis=2) >= 60)
        colhit = notsky.sum(axis=1)
        sil = np.argmax(colhit > 40) + 60 if (colhit > 40).any() else -1
        rows.append((start + gi / 30.0, gi, tire_top(gray[gi], 128, 176),
                     tire_top(gray[gi], 784, 832), skyfrac, sil))
    arr = np.array(rows, dtype=np.float64)
    np.save(f'seqc/{tag}_trace.npy', arr)
    print(f"[{tag}] {start}s +{dur}s: {len(states)} states "
          f"({len(states)/dur:.1f}/s)")
    return arr

if __name__ == '__main__':
    jobs = [(48, 12, 'lrjump'), (128, 26, 'hbopp'), (33, 12, 'lrstart')]
    for s, d, t in jobs:
        analyze(s, d, t)
