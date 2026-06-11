#!/usr/bin/env python3
"""
Fuse audio pitches (_raw.mid) with falling-bar timing/confirmation (_occ.npy).
Keeps audio notes the bars confirm, snaps each onset to the exact frame, drops the rest.
Outputs: _notes.json ([midi,start,end,vel]) and _fused.mid
"""
import json, numpy as np, pretty_midi

SHIFT = 6        # bars are detected ~6 frames before the strike
SUPPORT = 0.40   # bar occupancy that counts as "this key is really played"
KEEP_LONG = 0.35 # keep an unconfirmed audio note if it is at least this long (occlusion)

def main():
    km = json.load(open("_keymodel.json")); midis = list(km["midis"]); fps = km.get("fps", 30.0)
    col = {m: i for i, m in enumerate(midis)}
    O = np.load("_occ.npy")
    Os = np.copy(O)                                   # temporal median (de-flicker)
    for k in range(O.shape[1]):
        c = O[:, k]
        Os[:, k] = np.median(np.stack([np.r_[c[0], c[:-1]], c, np.r_[c[1:], c[-1]]]), axis=0)

    pm = pretty_midi.PrettyMIDI("_raw.mid")
    an = sorted(pm.instruments[0].notes, key=lambda n: n.start)
    out = pretty_midi.PrettyMIDI(); inst = pretty_midi.Instrument(program=0, name="Piano")
    notes = []
    for n in an:
        dur = n.end - n.start
        if n.pitch not in col:
            if dur >= KEEP_LONG: keep, start = True, n.start
            else: continue
        else:
            c = col[n.pitch]; sf = int(round(n.start*fps)) - SHIFT
            seg = Os[max(0, sf-5):min(Os.shape[0], sf+6), c]
            sup = float(seg.max()) if len(seg) else 0.0
            keep = sup >= SUPPORT or dur >= KEEP_LONG
            start = n.start
            if sup >= SUPPORT and len(seg):
                idx = np.where(seg >= SUPPORT)[0]
                if len(idx):
                    cand = (max(0, sf-5) + idx[0] + SHIFT) / fps
                    if abs(cand - n.start) < 0.13: start = cand
        if not keep: continue
        end = n.end if n.end > start else start + 0.08
        inst.notes.append(pretty_midi.Note(velocity=n.velocity, pitch=n.pitch, start=float(start), end=float(end)))
        notes.append([int(n.pitch), float(start), float(end), int(n.velocity)])
    out.instruments.append(inst); out.write("_fused.mid")
    json.dump(notes, open("_notes.json", "w"))
    print(f"audio notes {len(an)} -> kept {len(notes)}")

if __name__ == "__main__":
    main()
