#!/usr/bin/env python3
"""
Calibrate the 88-key keyboard from a median frame and read falling-bar occupancy.
Usage: video_notes.py _video.mp4
Outputs: _median.jpg, _calib.png (verify green lines on white-key gaps),
         _keymodel.json, _occ.npy  (frames x 88 bar-occupancy 0..1)

Tunables (adjust if the Synthesia layout differs, then rerun):
"""
LOW_MIDI = 21            # leftmost key (A0 for a full 88-key board)
N_WHITE  = 52            # white keys for 88-key
CALIB_Y  = (498, 520)    # band (low on white keys) to find white-key separators
BAR_BAND = (318, 346)    # detection band just ABOVE the strike line (read bars here)
HALF_W_WHITE, HALF_W_BLACK = 9, 5

import sys, json, numpy as np, cv2

def find_valleys(profile, distance=14, prominence=8):
    inv = profile.max() - profile
    cand = [i for i in range(1, len(inv)-1) if inv[i] >= inv[i-1] and inv[i] > inv[i+1] and inv[i] > prominence]
    cand.sort(key=lambda i: -inv[i]); keep = []
    for i in cand:
        if all(abs(i-k) >= distance for k in keep): keep.append(i)
    return sorted(keep)

def main(video):
    cap = cv2.VideoCapture(video)
    N = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)); W = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    FPS = cap.get(cv2.CAP_PROP_FPS) or 30.0
    # median frame -> clean static keyboard
    idx = np.linspace(0, N-1, 120).astype(int); acc = []
    for i in idx:
        cap.set(cv2.CAP_PROP_POS_FRAMES, int(i)); ok, f = cap.read()
        if ok: acc.append(f)
    med = np.median(np.stack(acc), axis=0).astype(np.uint8)
    cv2.imwrite("_median.jpg", med)

    g = cv2.cvtColor(med, cv2.COLOR_BGR2GRAY).astype(np.float32)
    band = g[CALIB_Y[0]:CALIB_Y[1], :].mean(0)
    prof = cv2.GaussianBlur(band.reshape(1, -1), (0, 0), 1.2).ravel()
    peaks = find_valleys(prof)
    assert len(peaks) == N_WHITE-1, f"expected {N_WHITE-1} white separators, got {len(peaks)} — adjust CALIB_Y"

    white_midis = [m for m in range(LOW_MIDI, LOW_MIDI+88) if m % 12 in (0,2,4,5,7,9,11)][:N_WHITE]
    bounds = [0] + peaks + [W-1]
    white_centers = [(bounds[i]+bounds[i+1])//2 for i in range(N_WHITE)]
    keys = []
    for i in range(N_WHITE):
        keys.append((white_midis[i], white_centers[i]))
        if i < N_WHITE-1 and white_midis[i+1]-white_midis[i] == 2:
            keys.append((white_midis[i]+1, peaks[i]))     # black key on whole-step boundary
    keys.sort(key=lambda k: k[0])
    midis = [k[0] for k in keys]; xs = [k[1] for k in keys]
    json.dump({"midis": midis, "xs": xs, "fps": FPS}, open("_keymodel.json", "w"))

    dbg = med.copy()
    for p in peaks: cv2.line(dbg, (int(p), 360), (int(p), 545), (0,255,0), 1)
    cv2.imwrite("_calib.png", dbg)

    # bar occupancy per key per frame
    cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
    O = np.zeros((N, 88), np.float32); fi = 0
    y0, y1 = BAR_BAND
    while True:
        ok, f = cap.read()
        if not ok: break
        c = f[y0:y1].astype(np.float32); B,G,R = c[:,:,0], c[:,:,1], c[:,:,2]
        V = np.maximum(np.maximum(B,G), R); purp = np.minimum(B,R) - G
        fill = ((V > 70) & (purp > 15)).astype(np.float32).mean(0)
        for ki, x in enumerate(xs):
            hw = HALF_W_BLACK if midis[ki] % 12 in (1,3,6,8,10) else HALF_W_WHITE
            O[fi, ki] = fill[max(0,x-hw):min(W,x+hw+1)].mean()
        fi += 1
    cap.release()
    np.save("_occ.npy", O[:fi])
    print(f"calibrated 88 keys (MIDI {midis[0]}..{midis[-1]}); occupancy {O[:fi].shape}; check _calib.png")

if __name__ == "__main__":
    main(sys.argv[1])
