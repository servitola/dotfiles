#!/usr/bin/env python3
"""
Velocity from per-note audio energy + sustain pedal (CC64) inferred from the loudness envelope.
Usage: velocity_pedal.py [in.mid=_fused.mid] [audio.wav=_audio.wav] [out.mid=_final.mid]
"""
import sys, subprocess, numpy as np, pretty_midi, bisect

def decode(wav, sr=22050):
    raw = subprocess.run(["ffmpeg","-v","quiet","-i",wav,"-ac","1","-ar",str(sr),"-f","f32le","-"],
                         capture_output=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64), sr

def main(in_mid="_fused.mid", wav="_audio.wav", out_mid="_final.mid"):
    y, sr = decode(wav); dur_total = len(y)/sr
    pm = pretty_midi.PrettyMIDI(in_mid); inst = pm.instruments[0]; notes = inst.notes

    # ---- velocity from spectral energy at each note's pitch (with harmonics) ----
    nfft, hop = 4096, 256; win = np.hanning(nfft); nfr = 1 + (len(y)-nfft)//hop
    S = np.empty((nfft//2+1, nfr))
    for i in range(nfr): S[:, i] = np.abs(np.fft.rfft(y[i*hop:i*hop+nfft]*win))
    freqs = np.fft.rfftfreq(nfft, 1/sr); hop_t = hop/sr
    def energy(f0, fr0, fr1):
        e = 0.0
        for h, w in [(1,1.0),(2,0.6),(3,0.35)]:
            f = f0*h; bins = np.where((freqs >= f*2**(-0.6/12)) & (freqs <= f*2**(0.6/12)))[0]
            if len(bins) and fr1 > fr0: e += w*S[bins, fr0:fr1].max(0).max()
        return e
    loud = []
    for n in notes:
        f0 = 440*2**((n.pitch-69)/12); fr = int(n.start/hop_t)
        loud.append(energy(f0, max(0,fr), min(nfr, fr+int(0.09/hop_t)+1)) or 1e-6)
    db = 20*np.log10(np.array(loud)+1e-6); p5, p95 = np.percentile(db,5), np.percentile(db,95)
    vel = np.clip(28 + (db-p5)/max(1e-6,p95-p5)*(124-28), 15, 127).astype(int)
    for n, v in zip(notes, vel): n.velocity = int(v)

    # ---- pedal: lifts = prominent dips in the loudness envelope (harmony changes) ----
    fr = int(0.01*sr); m = len(y)//fr
    env = 20*np.log10(np.array([np.sqrt(np.mean(y[i*fr:(i+1)*fr]**2)+1e-9) for i in range(m)])+1e-6)
    es = np.convolve(env, np.ones(5)/5, mode='same'); lifts = []
    for i in range(3, len(es)-3):
        if es[i] <= es[i-1] and es[i] < es[i+1]:
            prom = min(es[max(0,i-20):i].max(), es[i:i+20].max()) - es[i]
            if prom > 3.5: lifts.append((i*0.01, prom))
    lifts.sort(); L = []
    for t, p in lifts:
        if L and t-L[-1] < 0.4: continue
        L.append(t)
    def next_lift(t):
        i = bisect.bisect_right(L, t+0.05); return L[i] if i < len(L) else dur_total
    for n in notes:                                   # ring until the next pedal lift (capped)
        target = min(next_lift(n.start), n.end+1.2, n.start+3.0)
        if target > n.end+0.03: n.end = float(min(target, dur_total))
    cc = [pretty_midi.ControlChange(64, 127, 0.0)]
    for t in L:
        cc.append(pretty_midi.ControlChange(64, 0, float(max(0, t-0.03))))
        cc.append(pretty_midi.ControlChange(64, 127, float(t+0.05)))
    inst.control_changes = cc
    pm.write(out_mid)
    print(f"velocity set (dynamic range {p95-p5:.0f} dB); {len(L)} pedal lifts -> {out_mid}")

if __name__ == "__main__":
    main(*sys.argv[1:])
