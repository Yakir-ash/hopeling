# Hopeling sound identity, first pass: synthesized, soft, watery.
# Pure Python, no dependencies - writes 16-bit mono WAVs to
# app/assets/sfx/. Regenerate any time: python scripts/sfx.py
#
# Design rules: everything in a warm pentatonic (A major), fast
# attacks, long gentle decays, nothing above -6 dBFS, and no sound
# that could ever read as a buzzer or a scold. The bump is a soft
# water thud, not a mistake noise.

import math
import os
import random
import struct
import wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'app', 'assets', 'sfx')

random.seed(7)


def write_wav(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    norm = 0.5 / peak  # about -6 dBFS
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + '.wav')
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, s * norm)) * 32767))
            for s in samples))
    print(f'{name}.wav  {len(samples)/SR:.2f}s  {os.path.getsize(path)//1024}KB')


def env(i, n, attack=0.002, decay=4.0):
    t = i / SR
    a = min(1.0, t / attack) if attack > 0 else 1.0
    return a * math.exp(-decay * t) if decay > 0 else a


def bell(freq, dur, decay=5.0, harmonics=((1, 1.0), (2, 0.35), (3, 0.12))):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        s = sum(a * math.sin(2 * math.pi * freq * h * t)
                for h, a in harmonics)
        out.append(s * env(i, n, 0.003, decay))
    return out


def mix(base, add, at):
    off = int(SR * at)
    while len(base) < off + len(add):
        base.append(0.0)
    for i, s in enumerate(add):
        base[off + i] += s
    return base


def lowpass(samples, cutoff):
    rc = 1.0 / (2 * math.pi * cutoff)
    dt = 1.0 / SR
    alpha = dt / (rc + dt)
    out, y = [], 0.0
    for s in samples:
        y += alpha * (s - y)
        out.append(y)
    return out


# tick - the app's fingertip: tiny marimba touch
def tick():
    n = int(SR * 0.06)
    out = []
    for i in range(n):
        t = i / SR
        s = math.sin(2 * math.pi * 1760 * t) + 0.3 * math.sin(
            2 * math.pi * 3520 * t)
        out.append(s * env(i, n, 0.001, 55.0))
    return out


# drop - the dewdrop: a falling water note
def drop():
    n = int(SR * 0.30)
    out = []
    for i in range(n):
        t = i / SR
        f = 1320 - 440 * min(1.0, t / 0.12)  # E6 gliding down
        s = math.sin(2 * math.pi * f * t) + 0.25 * math.sin(
            2 * math.pi * f * 2 * t)
        out.append(s * env(i, n, 0.002, 14.0))
    return out


# pop - a bloom opening: a happy rising blip
def pop():
    n = int(SR * 0.11)
    out = []
    for i in range(n):
        t = i / SR
        f = 550 + 550 * min(1.0, t / 0.06)
        out.append(math.sin(2 * math.pi * f * t) * env(i, n, 0.002, 26.0))
    return out


# whoosh - a leap through air: breath, not jet
def whoosh():
    n = int(SR * 0.28)
    noise = [random.uniform(-1, 1) for _ in range(n)]
    out = []
    for i, s in enumerate(noise):
        t = i / SR
        sweep = 0.5 + 0.5 * math.sin(math.pi * min(1.0, t / 0.28))
        out.append(s * sweep)
    out = lowpass(out, 1400)
    return [s * env(i, n, 0.03, 9.0) * 3.0 for i, s in enumerate(out)]


# splash - water taking something in, then two droplets
def splash():
    n = int(SR * 0.30)
    noise = [random.uniform(-1, 1) for _ in range(n)]
    body = lowpass(noise, 1100)
    out = [s * env(i, n, 0.004, 12.0) * 3.0 for i, s in enumerate(body)]
    mix(out, [s * 0.35 for s in drop()], 0.16)
    mix(out, [s * 0.2 for s in pop()], 0.26)
    return out


# bump - a soft underwater thud; neutral, never a buzzer
def bump():
    n = int(SR * 0.16)
    out = []
    for i in range(n):
        t = i / SR
        f = 150 - 60 * min(1.0, t / 0.1)
        out.append(math.sin(2 * math.pi * f * t) * env(i, n, 0.003, 18.0))
    return lowpass(out, 400)


# chime - three bells up the A pentatonic: the sound of done
def chime():
    out = []
    mix(out, bell(440.0, 0.9, 4.5), 0.0)      # A4
    mix(out, bell(554.37, 0.9, 4.5), 0.13)    # C#5
    mix(out, bell(659.25, 1.1, 3.8), 0.26)    # E5
    return out


# flip - a leaf turning: quick soft brush
def flip():
    n = int(SR * 0.09)
    noise = [random.uniform(-1, 1) for _ in range(n)]
    out = lowpass(noise, 2600)
    return [s * env(i, n, 0.008, 30.0) * 2.5 for i, s in enumerate(out)]


for name, fn in [('tick', tick), ('drop', drop), ('pop', pop),
                 ('whoosh', whoosh), ('splash', splash), ('bump', bump),
                 ('chime', chime), ('flip', flip)]:
    write_wav(name, fn())
print('done - assets in app/assets/sfx/')
