"""Sintetiza os sons do jogo em WAV (Python puro, sem dependências). Saída: tools/assets/sounds/*.wav
Uso: python tools/make_sounds.py
Todos os sons são gerados por código (ruído filtrado, senoides, envelopes): sem direitos de terceiros."""
import math
import pathlib
import random
import struct
import wave

SR = 44100
OUT = pathlib.Path(__file__).parent / "assets" / "sounds"
OUT.mkdir(parents=True, exist_ok=True)
TAU = 2 * math.pi
rng = random.Random(7)


def write(name, samples, peak=0.85):
    top = max(1e-9, max(abs(s) for s in samples))
    scale = peak / top
    frames = b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(frames)
    print(f"{name}.wav  {len(samples) / SR:.2f}s")


def noise(n):
    return [rng.uniform(-1, 1) for _ in range(n)]


def lowpass(x, cutoff):
    a = 1 - math.exp(-TAU * cutoff / SR)
    y, out = 0.0, []
    for v in x:
        y += a * (v - y)
        out.append(y)
    return out


def lowpass_mod(x, cutoffs):
    y, out = 0.0, []
    for v, fc in zip(x, cutoffs):
        a = 1 - math.exp(-TAU * fc / SR)
        y += a * (v - y)
        out.append(y)
    return out


def highpass(x, cutoff):
    low = lowpass(x, cutoff)
    return [v - l for v, l in zip(x, low)]


def mix(*layers):
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for layer in layers:
        for i, v in enumerate(layer):
            out[i] += v
    return out


def gain(x, g):
    return [v * g for v in x]


def make_loop(x, fade):
    """Funde o fim com o começo para o som emendar sem estalo."""
    n = len(x) - fade
    out = x[:n]
    for i in range(fade):
        w = i / fade
        out[i] = x[i] * w + x[n + i] * (1 - w)
    return out


def delay(x, seconds, level):
    d = int(seconds * SR)
    return [0.0] * d + [v * level for v in x]


def echoes(x, taps):
    return mix(x, *[delay(x, t, l) for t, l in taps])


# ---------------------------------------------------------------- ambientes (loops)

def cave_drone():
    T = 24
    n = T * SR
    out = []
    for i in range(n):
        t = i / SR
        lfo = 0.65 + 0.35 * math.sin(TAU * t / 24)
        lfo2 = 0.7 + 0.3 * math.sin(TAU * 2 * t / 24 + 1.3)
        s = (math.sin(TAU * 55 * t) * 0.5
             + math.sin(TAU * 55.5 * t) * 0.35
             + math.sin(TAU * 82.5 * t + 0.7 * math.sin(TAU * t / 24)) * 0.3 * lfo
             + math.sin(TAU * 110.25 * t) * 0.18 * lfo2
             + math.sin(TAU * 165.5 * t) * 0.06 * lfo)
        out.append(s)
    hiss = gain(lowpass(noise(n), 500), 0.35)
    return make_loop(mix(out, hiss), SR * 2)


def cave_wind():
    n = 20 * SR
    cutoffs = [260 + 220 * math.sin(TAU * i / SR / 10) + 80 * math.sin(TAU * i / SR / 3.3) for i in range(n)]
    wind = lowpass_mod(noise(n), cutoffs)
    wind = highpass(wind, 90)
    amp = [0.6 + 0.4 * math.sin(TAU * i / SR / 6.7) for i in range(n)]
    return make_loop([w * a for w, a in zip(wind, amp)], SR * 2)


def lobby_ambience():
    n = 22 * SR
    cutoffs = [500 + 300 * math.sin(TAU * i / SR / 9) for i in range(n)]
    wind = [v * 0.5 for v in lowpass_mod(noise(n), cutoffs)]
    chirps = [0.0] * n
    for _ in range(26):
        start = rng.randint(0, n - SR)
        base = rng.uniform(2600, 4200)
        for burst in range(rng.randint(2, 4)):
            offset = start + int(burst * 0.11 * SR)
            length = int(0.07 * SR)
            for i in range(length):
                t = i / SR
                f = base * (1 + 0.35 * t / 0.07)
                env = math.sin(math.pi * i / length)
                if offset + i < n:
                    chirps[offset + i] += math.sin(TAU * f * t) * env * 0.18
    return make_loop(mix(wind, chirps), SR * 2)


def forest_ambience():
    n = 22 * SR
    cutoffs = [350 + 200 * math.sin(TAU * i / SR / 8) for i in range(n)]
    wind = [v * 0.5 for v in lowpass_mod(noise(n), cutoffs)]
    crickets = [0.0] * n
    for voice in range(3):
        freq = 4100 + voice * 230
        rate = 24 + voice * 3
        phase = rng.random()
        for i in range(n):
            t = i / SR
            gate = 1.0 if ((t * rate + phase) % 1.0) < 0.45 else 0.0
            slow = 0.5 + 0.5 * math.sin(TAU * t / (3.1 + voice))
            crickets[i] += math.sin(TAU * freq * t) * gate * slow * 0.05
    return make_loop(mix(wind, crickets), SR * 2)


def heartbeat():
    n = int(1.5 * SR)
    out = [0.0] * n

    def thump(at, level):
        for i in range(int(0.3 * SR)):
            t = i / SR
            s = math.sin(TAU * 52 * t) * math.exp(-t / 0.07) * level
            if at + i < n:
                out[at + i] += s

    thump(0, 1.0)
    thump(int(0.33 * SR), 0.7)
    return out


# ---------------------------------------------------------------- eventos (uma vez)

def drip(f0, seed):
    r = random.Random(seed)
    n = int(1.4 * SR)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f0 * (1 + 0.6 * (1 - math.exp(-t / 0.03)))
        phase += TAU * f / SR
        out.append(math.sin(phase) * math.exp(-t / 0.09))
    out = echoes(out, [(0.21, 0.35), (0.43, 0.2), (0.7, 0.1)])
    return gain(out, 1.0)


def rumble():
    n = 4 * SR
    base = lowpass(noise(n), 90)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, t / 0.4) * math.exp(-max(0.0, t - 0.4) / 1.6)
        wobble = 0.8 + 0.2 * math.sin(TAU * 7 * t)
        out.append((base[i] * 3 + math.sin(TAU * 38 * t) * 0.6) * env * wobble)
    return out


def footstep(seed):
    r = random.Random(seed)
    n = int(0.5 * SR)
    body = lowpass([r.uniform(-1, 1) for _ in range(n)], 450)
    out = []
    for i in range(n):
        t = i / SR
        out.append(body[i] * 2.2 * math.exp(-t / 0.05) + math.sin(TAU * (58 + seed * 3) * t) * math.exp(-t / 0.09))
    return out


def growl():
    n = int(2.8 * SR)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        vib = 1 + 0.07 * math.sin(TAU * 9 * t) + 0.03 * math.sin(TAU * 23 * t)
        phase += TAU * 64 * vib / SR
        saw = 2 * ((phase / TAU) % 1.0) - 1
        env = min(1.0, t / 0.35) * (1.0 if t < 1.9 else math.exp(-(t - 1.9) / 0.35))
        out.append(math.tanh(3 * saw) * env)
    grit = lowpass(noise(n), 900)
    shaped = [o + g * 0.5 * (0.4 + 0.6 * abs(math.sin(TAU * 5 * i / SR))) for i, (o, g) in enumerate(zip(out, grit))]
    return lowpass(shaped, 800)


def clang():
    n = int(2.0 * SR)
    partials = [(210, 1.0, 0.6), (395, 0.7, 0.45), (560, 0.55, 0.35), (835, 0.4, 0.25), (1110, 0.3, 0.18)]
    out = []
    for i in range(n):
        t = i / SR
        out.append(sum(a * math.sin(TAU * f * t) * math.exp(-t / tau) for f, a, tau in partials))
    click = [v * math.exp(-i / SR / 0.004) for i, v in enumerate(lowpass(noise(n), 3000))]
    return mix(out, gain(click, 1.2))


def laugh():
    n = int(2.2 * SR)
    out = [0.0] * n
    f0 = 200
    for syllable in range(4):
        start = int((0.15 + syllable * 0.38) * SR)
        length = int(0.22 * SR)
        f = f0 * (1 - syllable * 0.07)
        for i in range(length):
            t = i / SR
            env = math.sin(math.pi * i / length) ** 1.5
            wave_ = sum(math.sin(TAU * f * h * t) / h for h in range(1, 9))
            if start + i < n:
                out[start + i] += math.tanh(wave_ * 1.4) * env
    return echoes(lowpass(out, 1500), [(0.18, 0.3), (0.4, 0.15)])


def mimic_voice():
    n = int(1.6 * SR)
    breath = noise(n)
    formant_a = [a - b for a, b in zip(lowpass(breath, 1300), lowpass(breath, 600))]
    out = []
    phase = 0.0
    for i in range(n):
        t = i / SR
        env = math.sin(math.pi * min(1.0, t / 1.5)) ** 1.2 * (0.5 + 0.5 * abs(math.sin(TAU * 1.3 * t)))
        phase += TAU * (95 + 12 * math.sin(TAU * 4 * t)) / SR
        voiced = sum(math.sin(phase * h) / h for h in range(1, 7))
        out.append((voiced * 0.5 + formant_a[i] * 5) * env)
    return echoes(lowpass(out, 1800), [(0.25, 0.3), (0.5, 0.15)])


def rock_drop():
    n = int(0.9 * SR)
    burst = lowpass(noise(n), 1800)
    out = [burst[i] * math.exp(-i / SR / 0.03) * 1.5 + math.sin(TAU * 90 * i / SR) * math.exp(-i / SR / 0.1) for i in range(n)]
    return echoes(out, [(0.16, 0.3), (0.34, 0.15)])


def ding():
    n = int(1.4 * SR)
    return [(math.sin(TAU * 987.8 * i / SR) + 0.4 * math.sin(TAU * 1975 * i / SR)) * math.exp(-i / SR / 0.35) for i in range(n)]


def pickup():
    n = int(0.45 * SR)
    out = []
    for i in range(n):
        t = i / SR
        f = 660 if t < 0.12 else 990
        env = math.exp(-(t if t < 0.12 else t - 0.12) / 0.08)
        out.append(math.sin(TAU * f * t) * env)
    return out


if __name__ == "__main__":
    write("cave_drone", cave_drone(), 0.7)
    write("cave_wind", cave_wind(), 0.7)
    write("lobby_ambience", lobby_ambience(), 0.7)
    write("forest_ambience", forest_ambience(), 0.7)
    write("heartbeat", heartbeat(), 0.9)
    for index, f0 in enumerate((1250, 1480, 1090)):
        write(f"drip{index + 1}", drip(f0, index), 0.8)
    write("rumble", rumble(), 0.95)
    for index in (1, 2):
        write(f"footstep{index}", footstep(index), 0.9)
    write("growl", growl(), 0.95)
    write("clang", clang(), 0.85)
    write("laugh", laugh(), 0.85)
    write("mimic_voice", mimic_voice(), 0.85)
    write("rock_drop", rock_drop(), 0.9)
    write("ding", ding(), 0.8)
    write("pickup", pickup(), 0.8)
