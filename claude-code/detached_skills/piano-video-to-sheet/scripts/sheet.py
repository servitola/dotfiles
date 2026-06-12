#!/usr/bin/env python3
"""
Engrave _notes.json into sheet music. Usage: sheet.py _audio.wav "Song Title"
Outputs: "<Title> - sheet.pdf" and "<Title> - sheet.musicxml"
Tempo-warps rubato onto a beat grid, quantizes to 16ths, splits hands at middle C,
detects the key and respells enharmonics to fit it (fewer visible accidentals).
"""
import sys, os, re, io, json, warnings, numpy as np
warnings.filterwarnings("ignore")
import librosa, pretty_midi
from music21 import stream, note, chord, meter, key, tempo, clef, metadata, layout, pitch

G = 0.25; SPLIT = 60
FLAT  = {0:'C',1:'D-',2:'D',3:'E-',4:'E',5:'F',6:'G-',7:'G',8:'A-',9:'A',10:'B-',11:'B'}
SHARP = {0:'C',1:'C#',2:'D',3:'D#',4:'E',5:'F',6:'F#',7:'G',8:'G#',9:'A',10:'A#',11:'B'}

def warp(audio):
    y, sr = librosa.load(audio)
    bpm, beats = librosa.beat.beat_track(y=y, sr=sr, units='time')
    bpm = float(np.atleast_1d(bpm)[0]); beats = np.asarray(beats); bi = np.median(np.diff(beats))
    B = np.concatenate([[beats[0]-2*bi, beats[0]-bi], beats, [beats[-1]+bi, beats[-1]+2*bi, beats[-1]+3*bi]])
    def to_beat(t):
        i = max(0, min(np.searchsorted(B, t)-1, len(B)-2)); return i + (t-B[i])/(B[i+1]-B[i])
    return bpm, to_beat

def build(notes, name_map, sharps, bpm):
    q = lambda x: round(x/G)*G
    hands = {'R': {}, 'L': {}}
    for p, s, e, v in notes:
        h = 'R' if p >= SPLIT else 'L'; hands[h].setdefault(q(s), []).append((p, max(G, q(e-s)), v))
    def spell(m): return pitch.Pitch(name_map[m % 12] + str(m//12 - 1))
    def part(hd, cl):
        pt = stream.Part(); pt.insert(0, cl); ons = sorted(hd)
        for i, on in enumerate(ons):
            grp = hd[on]; nxt = ons[i+1] if i+1 < len(ons) else on + max(g[1] for g in grp)
            dur = max(G, round(min(max(g[1] for g in grp), nxt-on)/G)*G)
            ps = sorted({g[0] for g in grp}); vel = int(np.median([g[2] for g in grp]))
            el = note.Note(spell(ps[0])) if len(ps) == 1 else chord.Chord([spell(x) for x in ps])
            el.quarterLength = dur; el.volume.velocity = vel; pt.insert(on, el)
        pt.makeRests(fillGaps=True, inPlace=True); return pt
    sc = stream.Score(); pR = part(hands['R'], clef.TrebleClef()); pL = part(hands['L'], clef.BassClef())
    for p in (pR, pL): p.insert(0, key.KeySignature(sharps)); p.insert(0, meter.TimeSignature('4/4'))
    pR.insert(0, tempo.MetronomeMark(number=int(round(bpm)), referent=note.Note(type='quarter')))
    sc.insert(0, pR); sc.insert(0, pL)
    sg = layout.StaffGroup([pR, pL], symbol='brace'); sg.barTogether = True; sc.insert(0, sg)
    sc.makeNotation(inPlace=True); return sc

def main(audio, title):
    notes = json.load(open("_notes.json"))
    bpm, to_beat = warp(audio)
    base = to_beat(min(n[1] for n in notes))
    wnotes = [[int(p), to_beat(s)-base, to_beat(e)-base, int(v)] for p, s, e, v in notes]
    json.dump({"tempo": bpm, "notes": wnotes}, open("_warped.json", "w"))
    # pass 1: detect key with neutral spelling
    k = build(wnotes, SHARP, 0, bpm).analyze('key')
    name_map = FLAT if k.sharps < 0 else SHARP
    sc = build(wnotes, name_map, k.sharps, bpm)
    sc.metadata = metadata.Metadata(); sc.metadata.title = title
    ed = f"{title} - sheet.musicxml"; sc.write('musicxml', fp=ed)
    print(f"key: {k} ({k.correlationCoefficient:.2f}); editable -> {ed}")
    engrave(ed, f"{title} - sheet.pdf", bpm, title)

def engrave(musicxml, pdf, bpm, title):
    import verovio, cairosvg
    from pypdf import PdfWriter, PdfReader
    xml = open(musicxml).read()
    # Verovio draws the metronome glyph as a box -> replace with plain bold text.
    xml = re.sub(r'<direction\b(?:(?!</direction>).)*?<metronome(?:(?!</direction>).)*?</direction>', '', xml, flags=re.S)
    words = (f'<direction placement="above"><direction-type><words font-weight="bold" '
             f'font-style="italic" font-size="11">{int(round(bpm))} BPM</words></direction-type>'
             f'<sound tempo="{int(round(bpm))}"/></direction>')
    i = xml.find("</attributes>"); tmp = "_pdf.musicxml"
    open(tmp, "w").write(xml[:i+13] + words + xml[i+13:])
    tk = verovio.toolkit()
    tk.setOptions({"font":"Leipzig","pageHeight":2970,"pageWidth":2100,"scale":40,"adjustPageHeight":False,
                   "spacingStaff":12,"spacingSystem":26,"header":"none","footer":"none",
                   "pageMarginTop":130,"pageMarginBottom":90,"pageMarginLeft":110,"pageMarginRight":110})
    tk.loadFile(tmp); w = PdfWriter()
    for p in range(1, tk.getPageCount()+1):
        w.add_page(PdfReader(io.BytesIO(cairosvg.svg2pdf(bytestring=tk.renderToSVG(p).encode()))).pages[0])
    with open(pdf, "wb") as f: w.write(f)
    print(f"engraved -> {pdf}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
