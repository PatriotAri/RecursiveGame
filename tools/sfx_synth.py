"""Procedural placeholder sound effects for Recursive.

Writes 16-bit mono WAVs into recursive/game/audio/sfx/. Every sound is built
from sine/square/noise primitives with envelopes, so they're deterministic
(seeded) and can be regenerated or tweaked here instead of hunting for files.
They're placeholders: swap any .wav for a real recording with the same name
and the SoundEffect resources pick it up unchanged.

    python3 tools/sfx_synth.py
"""
import os
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "recursive", "game", "audio", "sfx")
rng = np.random.default_rng(7)


def t(dur):
    return np.arange(int(RATE * dur)) / RATE


def env(n, attack=0.005, release=None, curve=3.0):
    """Linear attack, exponential-ish decay to zero over the rest."""
    a = max(1, int(RATE * attack))
    e = np.ones(n)
    e[:a] = np.linspace(0, 1, a)
    rest = n - a
    if rest > 0:
        e[a:] = np.linspace(1, 0, rest) ** curve
    return e


def sweep(f0, f1, dur, shape="sine"):
    """Frequency glide from f0 to f1 Hz (exponential)."""
    tt = t(dur)
    f = f0 * (f1 / f0) ** (tt / dur)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    if shape == "square":
        return np.sign(np.sin(phase))
    if shape == "tri":
        return 2 / np.pi * np.arcsin(np.sin(phase))
    return np.sin(phase)


def noise(dur):
    return rng.uniform(-1, 1, int(RATE * dur))


def lowpass(x, cutoff):
    """One-pole lowpass; cutoff may be a scalar or a per-sample array."""
    cutoff = np.broadcast_to(cutoff, x.shape)
    y = np.zeros_like(x)
    acc = 0.0
    for i, s in enumerate(x):
        a = 1 - np.exp(-2 * np.pi * cutoff[i] / RATE)
        acc += a * (s - acc)
        y[i] = acc
    return y


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def write(name, x, gain=0.8):
    x = x / (np.max(np.abs(x)) + 1e-9) * gain
    data = (np.clip(x, -1, 1) * 32767).astype("<i2")
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print("wrote", name)


def swing():
    d = 0.16
    n = noise(d)
    cut = np.linspace(600, 3500, len(n)) * np.sin(np.linspace(0.2, np.pi, len(n)))
    return lowpass(n, cut + 200) * env(len(n), attack=0.04, curve=1.5)


def hit():
    d = 0.12
    thump = sweep(180, 60, d) * env(int(RATE * d), curve=2)
    crack = lowpass(noise(0.05), 4000) * env(int(RATE * 0.05), attack=0.001, curve=4)
    return mix(thump, crack * 0.7)


def player_hurt():
    d = 0.22
    tone = sweep(420, 160, d, "square") * env(int(RATE * d), curve=2) * 0.4
    return mix(hit() * 0.8, lowpass(tone, 2500))


def enemy_death():
    d = 0.45
    squelch = sweep(300, 50, d, "tri") * env(int(RATE * d), attack=0.01, curve=1.6)
    wobble = 1 + 0.5 * np.sin(2 * np.pi * 18 * t(d))
    bubbles = lowpass(noise(d), 900) * env(int(RATE * d), curve=2) * 0.5
    return mix(squelch * wobble, bubbles)


def player_death():
    d = 0.9
    a = sweep(330, 82, d, "square") * env(int(RATE * d), attack=0.01, curve=1.2)
    b = sweep(332, 83, d, "square") * env(int(RATE * d), attack=0.01, curve=1.2)
    return lowpass(mix(a, b) * 0.5, 1800)


def enemy_attack():
    d = 0.14
    s = sweep(140, 320, d, "tri") * env(int(RATE * d), attack=0.02, curve=2)
    return mix(s, lowpass(noise(d), 1200) * env(int(RATE * d), curve=3) * 0.4)


def pickup():
    a = sweep(988, 988, 0.06, "square") * env(int(RATE * 0.06), attack=0.001, curve=1)
    b = sweep(1319, 1319, 0.12, "square") * env(int(RATE * 0.12), attack=0.001, curve=2)
    return lowpass(np.concatenate([a, b]) * 0.5, 5000)


def soul_pickup():
    notes = [523, 659, 784, 1047]
    parts = []
    for f in notes:
        d = 0.07
        parts.append(sweep(f, f, d) * env(int(RATE * d), attack=0.002, curve=1.5))
    tail = sweep(1047, 1047, 0.25) * env(int(RATE * 0.25), attack=0.002, curve=2)
    x = np.concatenate(parts + [tail])
    shimmer = 1 + 0.3 * np.sin(2 * np.pi * 9 * np.arange(len(x)) / RATE)
    return x * shimmer


def potion():
    parts = []
    for f in [380, 440, 520]:
        d = 0.08
        parts.append(sweep(f * 0.7, f * 1.4, d) * env(int(RATE * d), attack=0.005, curve=2))
        parts.append(np.zeros(int(RATE * 0.02)))
    return np.concatenate(parts)


def equip():
    d = 0.18
    partials = [1200, 2750, 4100]
    x = sum(sweep(f, f, d) * env(int(RATE * d), attack=0.001, curve=4 + i) for i, f in enumerate(partials))
    return mix(x, lowpass(noise(0.02), 6000) * 0.5)


def ui_click():
    d = 0.035
    return sweep(1800, 900, d, "square") * env(int(RATE * d), attack=0.001, curve=3) * 0.5


def throw():
    d = 0.12
    n = noise(d)
    return lowpass(n, np.linspace(2500, 5000, len(n))) * env(len(n), attack=0.02, curve=2)


def projectile_hit():
    d = 0.08
    return mix(sweep(900, 300, d, "square") * env(int(RATE * d), curve=3) * 0.4,
               lowpass(noise(d), 5000) * env(int(RATE * d), attack=0.001, curve=4))


def fireball_cast():
    d = 0.35
    roar = lowpass(noise(d), np.linspace(300, 2200, int(RATE * d))) * env(int(RATE * d), attack=0.06, curve=1.3)
    tone = sweep(110, 330, d, "tri") * env(int(RATE * d), attack=0.05, curve=2) * 0.4
    return mix(roar, tone)


def fireball_hit():
    d = 0.5
    boom = sweep(120, 35, d) * env(int(RATE * d), attack=0.002, curve=2.5)
    crackle = lowpass(noise(d), 3000) * env(int(RATE * d), attack=0.002, curve=1.8) * 0.8
    return mix(boom, crackle)


def door():
    d = 0.4
    creak = sweep(180, 240, d, "square") * (1 + 0.6 * np.sin(2 * np.pi * 30 * t(d)))
    return lowpass(creak, 900) * env(int(RATE * d), attack=0.05, curve=1.5)


def round_start():
    notes = [392, 523, 659]
    parts = [sweep(f, f, 0.1, "square") * env(int(RATE * 0.1), attack=0.002, curve=1.5) for f in notes]
    return lowpass(np.concatenate(parts) * 0.6, 4000)


def purchase():
    return mix(pickup(), np.concatenate([np.zeros(int(RATE * 0.08)), pickup()]) * 0.7)


def denied():
    d = 0.18
    return lowpass(sweep(160, 120, d, "square") * env(int(RATE * d), attack=0.002, curve=1), 1500)


SOUNDS = {
    "swing": swing, "hit": hit, "player_hurt": player_hurt,
    "enemy_death": enemy_death, "player_death": player_death,
    "enemy_attack": enemy_attack, "pickup": pickup, "soul_pickup": soul_pickup,
    "potion": potion, "equip": equip, "ui_click": ui_click,
    "throw": throw, "projectile_hit": projectile_hit,
    "fireball_cast": fireball_cast, "fireball_hit": fireball_hit,
    "door": door, "round_start": round_start, "purchase": purchase, "denied": denied,
}

if __name__ == "__main__":
    for name, fn in SOUNDS.items():
        write(name, fn())
