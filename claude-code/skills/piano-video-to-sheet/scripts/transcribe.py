#!/usr/bin/env python3
"""Audio -> raw MIDI with Spotify basic-pitch (ONNX). Usage: transcribe.py in.wav out.mid"""
import sys, os, tempfile, shutil, glob, subprocess

def main(wav, out_mid):
    tmp = tempfile.mkdtemp()
    bp = os.path.join(os.path.dirname(sys.executable), "basic-pitch")
    # default model path expects TensorFlow; force ONNX serialization.
    subprocess.run([bp, tmp, wav, "--save-midi", "--model-serialization", "onnx"], check=True)
    mid = glob.glob(os.path.join(tmp, "*.mid"))[0]
    shutil.move(mid, out_mid)
    shutil.rmtree(tmp, ignore_errors=True)
    print("wrote", out_mid)

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
