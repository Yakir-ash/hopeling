#!/usr/bin/env python3
"""The score and the sound mix for the Hopeling film.

Everything here is synthesised from scratch with numpy: no samples, no
loops, no third-party recordings, so the music is original and carries no
licence to clear. The only recorded sound is the storyteller's voice, which
is Hopeling's own narration (audio/*.mp3, see audio/manifest.json).

    python3 film/score.py film/out/spec-main.json film/out/hopeling-film.wav

The spec (written by film/build.sh from film/film.cjs) carries the cut's
length, its cue times, and the voice lines with their start times.
"""
import json, subprocess, sys, wave
import numpy as np

SR = 44100
rng = np.random.default_rng(7)


def midi(n): return 440.0 * 2 ** ((n - 69) / 12)
NOTE = {n: i for i, n in enumerate(['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'])}
def hz(name):  # 'F#4'
    return midi(12 * (int(name[-1]) + 1) + NOTE[name[:-1]])


class Mix:
    def __init__(self, dur):
        self.n = int((dur + 4) * SR)
        self.dry = np.zeros((self.n, 2)); self.wet = np.zeros((self.n, 2))

    def add(self, t, sig, pan=0.0, gain=1.0, send=0.3):
        i = int(max(0, t) * SR)
        if i >= self.n: return
        sig = sig[: self.n - i] * gain
        l, r = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        self.dry[i:i + len(sig), 0] += sig * l; self.dry[i:i + len(sig), 1] += sig * r
        self.wet[i:i + len(sig), 0] += sig * l * send; self.wet[i:i + len(sig), 1] += sig * r * send


def env(n, a, r):
    e = np.ones(n); na, nr = min(n, int(a * SR)), min(n, int(r * SR))
    if na: e[:na] = 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, na))
    if nr: e[-nr:] *= 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, nr))
    return e


def pad(f, dur, bright=1.0):
    """A warm sustained voice: three slightly detuned stacks of soft harmonics."""
    n = int(dur * SR); t = np.arange(n) / SR; out = np.zeros(n)
    for det in (-0.0035, 0, 0.004):
        ph = rng.uniform(0, 6.28)
        for h in range(1, 7):
            out += np.sin(2 * np.pi * f * (1 + det) * h * t + ph * h) / (h ** (2.1 - 0.5 * bright))
    out *= (1 + 0.06 * np.sin(2 * np.pi * 0.21 * t + rng.uniform(0, 6))) * env(n, min(1.8, dur * 0.35), min(2.4, dur * 0.45))
    return out / 5.5


def piano(f, dur=3.2, soft=1.0):
    n = int(dur * SR); t = np.arange(n) / SR; out = np.zeros(n)
    for h in range(1, 9):
        inh = h * np.sqrt(1 + 0.0004 * h * h)
        out += np.sin(2 * np.pi * f * inh * t) * np.exp(-t * (0.9 + 0.55 * h) / soft) / (h ** 1.5)
    out *= env(n, 0.006, 0.25)
    return out / 2.2


def bell(f, dur=3.0):
    n = int(dur * SR); t = np.arange(n) / SR; out = np.zeros(n)
    for ratio, amp, dec in ((1, 1, 1.5), (2.0, 0.35, 2.2), (2.76, 0.42, 2.8), (5.4, 0.2, 4.5), (8.9, 0.08, 6)):
        out += amp * np.sin(2 * np.pi * f * ratio * t) * np.exp(-t * dec)
    return out * env(n, 0.003, 0.3) / 1.8


def pluck(f, dur=0.9):
    n = int(dur * SR); t = np.arange(n) / SR; out = np.zeros(n)
    for h in range(1, 6): out += np.sin(2 * np.pi * f * h * t) * np.exp(-t * (5 + 2.2 * h)) / h
    return out * env(n, 0.004, 0.1) / 1.6


def bass(f, dur):
    n = int(dur * SR); t = np.arange(n) / SR
    return (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)) * env(n, 0.25, min(1.5, dur * 0.4)) / 1.3


def smooth(x, k):
    c = np.cumsum(np.insert(x, 0, 0.0)); return (c[k:] - c[:-k]) / k


def air(dur, lo=60, hi=400):
    """Filtered noise with a swell: wind, or the breath between scenes."""
    n = int(dur * SR); x = rng.standard_normal(n + hi)
    y = smooth(x, lo)[:n] - smooth(x, hi)[:n]
    return y / (np.abs(y).max() + 1e-9) * np.sin(np.linspace(0, np.pi, n)) ** 2


def tick():
    n = int(0.05 * SR); t = np.arange(n) / SR
    return (np.sin(2 * np.pi * 1700 * t) * np.exp(-t * 160) + 0.4 * rng.standard_normal(n) * np.exp(-t * 320)) * 0.5


def drop():
    n = int(0.5 * SR); t = np.arange(n) / SR
    f = 520 + 900 * np.exp(-t * 26)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 11)


def chirp(base):
    """A small synthetic bird: three quick rising notes. Not a recording of any real species."""
    out = np.zeros(int(0.6 * SR))
    for k in range(3):
        n = int(0.09 * SR); t = np.arange(n) / SR
        f = base * (1 + 0.25 * k) * (1 + 1.6 * t)
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.linspace(0, np.pi, n)) ** 2
        i = int(k * 0.15 * SR); out[i:i + n] += s
    return out * 0.5


def reverb(x, seconds=2.6):
    n = int(seconds * SR); t = np.arange(n) / SR; out = np.zeros_like(x)
    size = 1 << int(np.ceil(np.log2(len(x) + n)))
    for ch in range(2):
        ir = rng.standard_normal(n) * np.exp(-t * 2.6) * (1 - np.exp(-t * 90))
        ir = smooth(np.concatenate([ir, np.zeros(8)]), 8)[:n]            # darker tail
        out[:, ch] = np.fft.irfft(np.fft.rfft(x[:, ch], size) * np.fft.rfft(ir, size), size)[: len(x)]
    return out / (np.abs(out).max() + 1e-9)


def load_voice(path):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-f', 'f32le', '-ac', '1', '-ar', str(SR), '-'], capture_output=True).stdout
    v = np.frombuffer(raw, dtype=np.float32).astype(np.float64)
    return v / (np.abs(v).max() + 1e-9) * 0.9


CH = {  # voicings: (bass, pad notes)
    'D': ('D2', ['D3', 'A3', 'F#4', 'A4']), 'Dsus': ('D2', ['D3', 'A3', 'E4', 'A4']), 'G': ('G2', ['G3', 'B3', 'D4', 'G4']),
    'A': ('A2', ['A3', 'C#4', 'E4', 'A4']), 'Asus': ('A2', ['A3', 'D4', 'E4']), 'Bm': ('B1', ['B2', 'F#3', 'D4', 'F#4']),
    'Em': ('E2', ['E3', 'G3', 'B3', 'E4']), 'F#m': ('F#2', ['F#3', 'A3', 'C#4']), 'G/B': ('B1', ['B2', 'G3', 'D4']), 'D/A': ('A2', ['A3', 'D4', 'F#4']),
}


def chord(m, t, name, dur, level=1.0, bright=1.0, low=True):
    b, notes = CH[name]
    for i, nm in enumerate(notes):
        m.add(t, pad(hz(nm), dur + 1.2, bright), pan=(-0.5, 0.2, 0.5, -0.2)[i % 4], gain=0.085 * level, send=0.5)
    if low: m.add(t, bass(hz(b), dur + 0.6), gain=0.105 * level, send=0.1)


def progression(m, t0, t1, names, bar=4.0, **kw):
    t, i = t0, 0
    while t < t1 - 0.3:
        d = min(bar, t1 - t); chord(m, t, names[i % len(names)], d, **kw); t += bar; i += 1


def arp(m, t0, t1, names, bar=4.0, step=0.5, inst=pluck, gain=0.11, octave=1):
    t, i = t0, 0
    while t < t1 - step:
        notes = CH[names[int((t - t0) // bar) % len(names)]][1]
        k = i % (2 * len(notes) - 2) if len(notes) > 1 else 0
        nm = notes[k if k < len(notes) else 2 * len(notes) - 2 - k]
        m.add(t, inst(hz(nm) * 2 ** octave), pan=np.sin(i * 1.3) * 0.5, gain=gain * (0.75 + 0.25 * np.sin(i * 0.7)), send=0.4)
        t += step; i += 1


def compose(spec):
    dur, q = spec['dur'], spec['cues']; m = Mix(dur)
    has = lambda k: q.get(k, -1) is not None and q.get(k, -1) >= 0
    order = sorted([(q[k], k) for k in ('lab', 'school', 'kids', 'act', 'close') if has(k)])
    nxt = lambda k: next((t for t, kk in order if t > q[k]), dur)

    # --- dawn: one held chord, birds, and bells as the light arrives
    first = order[0][0] if order else dur
    d_end = q['question'] if has('question') else first
    m.add(0, air(min(7, d_end), 80, 600), gain=0.055, send=0.6)
    chord(m, 0.3, 'Dsus', q['sunrise'] - 0.3 + 1, level=0.7, bright=0.6)
    progression(m, q['sunrise'], d_end, ['D', 'G', 'D/A', 'A'], level=0.9)
    for i, nm in enumerate(['F#5', 'A5', 'D6', 'A5', 'B5', 'D6', 'F#6']):
        t = q['sunrise'] + 0.2 + i * 1.15
        if t < d_end - 0.5: m.add(t, bell(hz(nm)), pan=(-0.4, 0.4)[i % 2], gain=0.10, send=0.6)
    for i, t in enumerate(np.arange(1.2, d_end - 0.6, 1.7)):
        m.add(t + rng.uniform(0, 0.5), chirp(rng.choice([2300, 2700, 3200, 3600])), pan=rng.uniform(-0.8, 0.8), gain=0.045, send=0.7)

    # --- the question and the name: suspended, then home
    if has('question'):
        chord(m, q['question'], 'G', q['mark'] - q['question'] - 1.2, level=0.8)
        chord(m, q['mark'] - 1.4, 'Asus', 1.6, level=0.8)
        m.add(q['mark'] - 1.5, air(1.6), gain=0.07, send=0.5)
        chord(m, q['mark'], 'D', q['lab'] - q['mark'], level=1.0, bright=1.2)
        for i, nm in enumerate(['D5', 'A5', 'D6']): m.add(q['mark'] + 0.15 + i * 0.12, bell(hz(nm), 4), pan=(i - 1) * 0.5, gain=0.12, send=0.7)
        for i, nm in enumerate(['B4', 'D5', 'G5', 'B5']): m.add(q['question'] + 0.6 + i * 1.1, piano(hz(nm)), pan=-0.2 + i * 0.15, gain=0.17, send=0.5)

    # --- the lab: a clock, and a meadow thinning in B minor
    if has('lab'):
        a, b = q['lab'], nxt('lab'); loss = q['loss']
        chord(m, a, 'D', max(0.5, loss - a), level=0.7)
        progression(m, loss, b - 0.4, ['Bm', 'G', 'Em', 'F#m', 'Bm', 'G', 'Em', 'A'], level=0.85, bright=0.7)
        for t in np.arange(a + 1.0, b - 1.0, 1.0): m.add(t, tick(), pan=0.3, gain=0.05, send=0.25)      # the model's own clock
        line = ['F#5', 'E5', 'D5', 'B4', 'D5', 'B4', 'A4', 'F#4', 'B4', 'A4', 'G4', 'E4', 'F#4', 'E4', 'D4', 'C#4']
        for i, nm in enumerate(line):
            t = loss + 0.5 + i * 1.25
            if t < b - 1.2: m.add(t, piano(hz(nm), 3.6), pan=-0.25 + 0.5 * (i % 2), gain=0.2, send=0.55)

    # --- school: curiosity, lighter on its feet
    if has('school'):
        a, b = q['school'], nxt('school'); names = ['D', 'A', 'Bm', 'G']
        progression(m, a, b - 0.3, names, bar=2.4, level=0.8, bright=1.1)
        arp(m, a + 0.4, b - 0.4, names, bar=2.4, step=0.3, gain=0.09)
        m.add(a - 0.5, air(1.2), gain=0.06, send=0.5)

    # --- kids: a music box, six seeds, and the meadow coming back
    if has('kids'):
        a, b, grow = q['kids'], nxt('kids'), q['grow']
        progression(m, a, grow, ['G', 'D/A', 'Em', 'A'], bar=max(2.0, (grow - a) / 4), level=0.6, bright=0.6)
        for i, nm in enumerate(['B5', 'D6', 'A5', 'G5', 'B5', 'A5']):
            t = a + 0.5 + i * (q['taps'][0] - a - 1.0) / 6
            if t < q['taps'][0] - 0.3: m.add(t, bell(hz(nm), 2.2), pan=(-0.3, 0.3)[i % 2], gain=0.075, send=0.6)
        for i, (t, nm) in enumerate(zip(q['taps'], ['D5', 'E5', 'F#5', 'A5', 'B5', 'D6'])):                 # each seed a step up the scale
            m.add(t, bell(hz(nm), 2.6), pan=-0.6 + i * 0.24, gain=0.17, send=0.6); m.add(t, drop(), pan=-0.6 + i * 0.24, gain=0.07, send=0.3)
        m.add(grow - 1.0, air(2.4, 40, 500), gain=0.09, send=0.6)
        progression(m, grow, b, ['D', 'G', 'D/A', 'A'], bar=max(1.6, (b - grow) / 4), level=1.05, bright=1.3)
        arp(m, grow + 0.2, b - 0.2, ['D', 'G', 'D/A', 'A'], bar=max(1.6, (b - grow) / 4), step=0.25, inst=piano, gain=0.12)
        for i, t in enumerate(np.arange(grow + 1.0, b - 0.5, 1.3)): m.add(t, chirp(rng.choice([2500, 3000, 3500])), pan=rng.uniform(-0.8, 0.8), gain=0.05, send=0.7)

    # --- act: a held breath, a drop, then rain
    if has('act'):
        a, b, pr = q['act'], nxt('act'), q['press']
        progression(m, a, b, ['Bm', 'G', 'D/A', 'A'], bar=max(1.6, (b - a) / 4), level=0.75)
        for i, nm in enumerate(['F#4', 'A4', 'D5', 'F#5']):
            if a + 0.4 + i * 1.0 < pr: m.add(a + 0.4 + i * 1.0, piano(hz(nm)), pan=-0.3 + i * 0.2, gain=0.17, send=0.5)
        m.add(pr, drop(), gain=0.3, send=0.6); m.add(pr, bell(hz('D6'), 3), gain=0.14, send=0.7); m.add(pr, bass(hz('D2'), 1.2), gain=0.2, send=0.1)
        scale = ['D5', 'E5', 'F#5', 'A5', 'B5', 'D6', 'E6', 'F#6']
        for i in range(26):
            t = pr + 0.5 + i * 0.085 + rng.uniform(0, 0.04)
            if t < b + 0.6: m.add(t, pluck(hz(rng.choice(scale)), 0.7), pan=rng.uniform(-0.9, 0.9), gain=0.06, send=0.6)

    # --- the close: home, and held
    a, card, end = q['close'], q['card'], q['end']
    if card - a > 3:
        progression(m, a, card, ['D', 'G', 'Bm', 'A'], bar=max(1.8, (card - a) / 4), level=1.0, bright=1.2)
        arp(m, a + 0.3, card - 0.3, ['D', 'G', 'Bm', 'A'], bar=max(1.8, (card - a) / 4), step=0.5, inst=piano, gain=0.13)
    chord(m, card, 'D', end - card, level=1.1, bright=1.3)
    for i, nm in enumerate(['D5', 'F#5', 'A5', 'D6']): m.add(card + 0.1 + i * 0.16, bell(hz(nm), 5), pan=-0.5 + i * 0.33, gain=0.13, send=0.7)
    for i, nm in enumerate(['A4', 'F#4', 'D4']): m.add(card + 2.2 + i * 0.8, piano(hz(nm), 4), gain=0.16, send=0.6)
    return m


def main():
    spec = json.load(open(sys.argv[1])); out = sys.argv[2]; dur = spec['dur']
    m = compose(spec)
    music = m.dry + 0.5 * reverb(m.wet) * np.abs(m.wet).max() * 3.2
    n = int(dur * SR); music = music[:n]
    # the voice, and the music stepping back for it
    vo = np.zeros(n)
    for t, path, trim in spec['voice']:
        v = load_voice(path)
        if trim: v = v[: int(trim * SR)] * env(min(len(v), int(trim * SR)), 0.01, 0.25)
        i = int(t * SR); v = v[: n - i]; vo[i:i + len(v)] += v
    k = int(0.35 * SR); duck = smooth(np.concatenate([np.zeros(k // 2), (np.abs(vo) > 0.02).astype(float), np.zeros(k)]), k)[:n]
    duck = np.clip(smooth(np.concatenate([duck, np.zeros(k)]), k)[:n] * 1.6, 0, 1)
    music *= (1 - 0.6 * duck)[:, None]
    fade = np.ones(n); fo = int(2.6 * SR); fade[-fo:] = 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, fo)); fi = int(1.0 * SR); fade[:fi] = np.linspace(0, 1, fi)
    music *= fade[:, None]
    music /= (np.abs(music).max() + 1e-9); music *= 0.5
    voiced = duck > 0.9
    if voiced.any():
        r = lambda a: 20 * np.log10(np.sqrt((a ** 2).mean()) + 1e-9)
        print(f'under the voice: voice {r(vo[voiced] * 0.86):.1f} dB, music {r(music[voiced]):.1f} dB')
    vwet = reverb(np.stack([vo, vo], 1), 1.2) * 0.05
    mix = music + (np.stack([vo, vo], 1) * 0.86 + vwet) * fade[:, None]
    mix = np.tanh(mix * 1.1) / np.tanh(1.1) * 0.94                        # a soft ceiling instead of a hard clip
    pcm = (np.clip(mix, -1, 1) * 32767).astype('<i2')
    with wave.open(out, 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    print('score', out, f'{dur:.1f}s', 'peak', f'{np.abs(mix).max():.2f}')


if __name__ == '__main__':
    main()
