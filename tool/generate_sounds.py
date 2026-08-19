#!/usr/bin/env python3
"""Generates DayForge's bundled reminder tones.

The tones are synthesised (pure sine partials with exponential decay) rather
than sourced, so the repo carries no third-party audio licence. Output:

    assets/sounds/<id>.ogg              # Flutter asset (Linux notifications)
    android/app/src/main/res/raw/<id>.ogg   # Android channel sound

Run after changing a tone definition:  python3 tool/generate_sounds.py
Requires numpy and ffmpeg (ogg encode). Ids must stay lowercase a-z0-9_ —
they double as Android raw-resource names.
"""
import os
import shutil
import struct
import subprocess
import sys
import tempfile

import numpy as np

RATE = 44100
ASSET_DIR = "assets/sounds"
RAW_DIR = "android/app/src/main/res/raw"


def tone(freq, dur, decay=6.0, harmonics=(1.0,), start=0.0):
    """One decaying note; returns (offset_seconds, samples)."""
    t = np.linspace(0, dur, int(RATE * dur), endpoint=False)
    wave = np.zeros_like(t)
    for i, amp in enumerate(harmonics, start=1):
        wave += amp * np.sin(2 * np.pi * freq * i * t)
    wave *= np.exp(-decay * t)
    # 5 ms fade-in kills the click at note onset.
    fade = int(RATE * 0.005)
    wave[:fade] *= np.linspace(0, 1, fade)
    return start, wave


def mix(notes, total):
    """Lays notes on a silent buffer of `total` seconds, normalised to -1 dBFS."""
    buf = np.zeros(int(RATE * total))
    for start, wave in notes:
        at = int(RATE * start)
        end = min(at + len(wave), len(buf))
        buf[at:end] += wave[: end - at]
    peak = np.abs(buf).max()
    if peak:
        buf *= 0.89 / peak
    return buf


def chime():
    return mix([tone(880, 1.6, 4.0, (1.0, 0.3)),
                tone(659.25, 1.8, 3.5, (1.0, 0.3), start=0.28)], 2.2)


def beep():
    return mix([tone(880, 0.16, 1.0, (1.0,), start=i * 0.28) for i in range(3)], 1.0)


def bell():
    return mix([tone(523.25, 3.0, 1.6, (1.0, 0.6, 0.35, 0.2, 0.1))], 3.0)


def alarm():
    """Classic two-tone alarm: 800/1000 Hz alternating, four cycles."""
    notes = []
    for i in range(8):
        notes.append(tone(1000 if i % 2 else 800, 0.24, 0.6, (1.0, 0.35),
                          start=i * 0.26))
    return mix(notes, 2.3)


def buzz():
    """Urgent low buzz: dense partials, short hard bursts."""
    notes = []
    for i in range(4):
        notes.append(tone(220, 0.3, 2.0, (1.0, 0.9, 0.7, 0.5, 0.35, 0.2),
                          start=i * 0.42))
    return mix(notes, 1.9)


TONES = {
    "chime": chime,
    "beep": beep,
    "bell": bell,
    "alarm": alarm,
    "buzz": buzz,
}


def write_wav(path, samples):
    pcm = (np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes()
    with open(path, "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 36 + len(pcm)) + b"WAVEfmt ")
        f.write(struct.pack("<IHHIIHH", 16, 1, 1, RATE, RATE * 2, 2, 16))
        f.write(b"data" + struct.pack("<I", len(pcm)) + pcm)


def main():
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg is required to encode the .ogg files")
    os.makedirs(ASSET_DIR, exist_ok=True)
    os.makedirs(RAW_DIR, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name, build in TONES.items():
            wav = os.path.join(tmp, f"{name}.wav")
            ogg = os.path.join(ASSET_DIR, f"{name}.ogg")
            write_wav(wav, build())
            subprocess.run(
                ["ffmpeg", "-y", "-loglevel", "error", "-i", wav,
                 "-c:a", "libvorbis", "-q:a", "4", ogg],
                check=True,
            )
            shutil.copyfile(ogg, os.path.join(RAW_DIR, f"{name}.ogg"))
            print(f"{name}.ogg  {os.path.getsize(ogg)} bytes")


if __name__ == "__main__":
    main()
