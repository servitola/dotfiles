#!/usr/bin/env python3
"""
Export _warped.json (beat-aligned notes, written by sheet.py) to a Guitar Pro .gp5,
then round-trip read it back and report note match vs the source.
Usage: guitarpro.py "Song Title"
Piano is mapped onto octave-tuned strings: the tab looks unusual but pitch is exact.
"""
import sys, math, json
import guitarpro as gp
from guitarpro import Song, Track, GuitarString, Beat, Note, NoteType, Duration, BeatStatus

G = 0.25; SPLIT = 60
TUNING = [96, 84, 72, 60, 48, 36, 24]      # 7 strings, octave spacing — covers the piano range
UNITS = [(16,1,False),(12,2,True),(8,2,False),(6,4,True),(4,4,False),(3,8,True),(2,8,False),(1,16,False)]

def split16(n):
    out = []
    while n > 0:
        for sz, val, dot in UNITS:
            if sz <= n: out.append((val, dot)); n -= sz; break
    return out

def assign(pitches):
    used, res = set(), []
    for p in sorted(pitches, reverse=True):
        best = None
        for si, t in enumerate(TUNING):
            if (si+1) in used or p-t < 0: continue
            if best is None or p-t < best[1]: best = (si+1, p-t)
        if best is None:
            for si, t in enumerate(TUNING):
                if (si+1) not in used and p-t >= 0: best = (si+1, p-t); break
        if best: used.add(best[0]); res.append((best[0], best[1]))
    return res

def main(title):
    d = json.load(open("_warped.json")); notes = d["notes"]; bpm = int(round(d.get("tempo", 120)))
    q = lambda x: round(x/G)*G
    hands = {'R': {}, 'L': {}}
    for p, s, e, v in notes:
        hands['R' if p >= SPLIT else 'L'].setdefault(q(s), set()).add(int(p))
    MEAS = int(math.ceil((max(q(e) for _,_,e,_ in notes)+0.001)/4.0))

    song = Song(title=title[:60], artist="video transcription", tempo=bpm)   # cp1252: keep Latin
    def setup(tr, nm):
        tr.name = nm; tr.strings = [GuitarString(i+1, t) for i, t in enumerate(TUNING)]; tr.channel.instrument = 0
    setup(song.tracks[0], "Piano RH"); left = Track(song); song.tracks.append(left); setup(left, "Piano LH")
    for _ in range(MEAS-1): song.newMeasure()

    def fill(track, hd):
        ons = sorted(hd)
        for m in range(MEAS):
            m0, m1 = m*4.0, m*4.0+4.0; voice = track.measures[m].voices[0]; voice.beats = []
            ev = [o for o in ons if m0 <= o < m1-1e-9]
            def emit(a, b, ps):
                n16 = int(round((b-a)/G))
                for k, (val, dot) in enumerate(split16(n16)):
                    bt = Beat(voice); bt.duration = Duration(value=val, isDotted=dot)
                    if ps:
                        bt.status = BeatStatus.normal
                        for st, fr in assign(ps):
                            bt.notes.append(Note(bt, value=fr, string=st,
                                                 type=(NoteType.normal if k == 0 else NoteType.tie)))
                    else: bt.status = BeatStatus.rest
                    voice.beats.append(bt)
            cur = m0
            for i, o in enumerate(ev):
                if o > cur: emit(cur, o, None)
                nxt = ev[i+1] if i+1 < len(ev) else m1
                emit(o, min(nxt, m1), hd[o]); cur = min(nxt, m1)
            if cur < m1-1e-9: emit(cur, m1, None)
    fill(song.tracks[0], hands['R']); fill(left, hands['L'])
    fn = f"{title} - guitarpro.gp5"; gp.write(song, fn)

    # round-trip cross-check
    s2 = gp.parse(fn); got = set()
    for tr in s2.tracks:
        tun = [g.value for g in tr.strings]
        for mi, meas in enumerate(tr.measures):
            pos = 0.0
            for b in meas.voices[0].beats:
                for nt in b.notes:
                    if nt.type != NoteType.tie: got.add((nt.value+tun[nt.string-1], round(mi*4.0+pos, 2)))
                pos += (4.0/b.duration.value)*(1.5 if b.duration.isDotted else 1)
    src = {(int(p), round(q(s), 2)) for p, s, e, v in notes}
    inter = src & got
    print(f"{fn}: match {len(inter)}/{len(src)} ({100*len(inter)/len(src):.1f}%)")

if __name__ == "__main__":
    main(sys.argv[1])
