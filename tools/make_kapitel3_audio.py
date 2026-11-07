"""Erzeugt die Sounds für Kapitel 3 (selbst berechnet, frei verwendbar).

Aufruf:  python3 tools/make_kapitel3_audio.py assets/audio/kapitel3
Braucht: numpy, ffmpeg (für .ogg)
"""
import numpy as np, subprocess, os, sys, wave, shutil

SR = 44100
OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/audio/kapitel3"
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(303)


# ------------------------------------------------------------------ Werkzeuge
def t_axis(seconds):
    return np.arange(int(seconds * SR)) / SR


def fft_filter(x, response):
    """Kreisförmiger FFT-Filter: response(freqs) -> Verstärkung (kreisförmig = nahtlose Schleifen)."""
    spectrum = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / SR)
    return np.fft.irfft(spectrum * response(freqs), len(x))


def lowpass(cut, order=2):
    return lambda f: 1 / np.sqrt(1 + (f / cut) ** (2 * order))


def highpass(cut, order=2):
    return lambda f: 1 / np.sqrt(1 + (cut / np.maximum(f, 1e-3)) ** (2 * order))


def bandpass(low, high, order=2):
    return lambda f: lowpass(high, order)(f) * highpass(low, order)(f)


def peak(fc, q):
    """Resonanz (Formant)"""
    return lambda f: 1 / (1 + ((f - fc) / (fc / q)) ** 2)


def noise(n):
    return rng.standard_normal(n)


def pink(n):
    return fft_filter(noise(n), lambda f: 1 / np.sqrt(np.maximum(f, 20)))


def brown(n):
    return fft_filter(noise(n), lambda f: 1 / np.maximum(f, 15))


def normalize(x, level=0.9):
    return x / (np.max(np.abs(x)) + 1e-9) * level


def fade(x, fade_in=0.005, fade_out=0.05):
    x = x.copy()
    a, b = int(fade_in * SR), int(fade_out * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b)
    return x


def reverb(x, seconds=2.0, mix=0.3, tone=3500, tail=True):
    n = int(seconds * SR)
    ir = noise(n) * np.exp(-np.arange(n) / SR * (6.9 / seconds))
    ir = fft_filter(ir, lowpass(tone))
    ir /= np.sqrt(np.sum(ir ** 2))
    size = len(x) + n
    wet = np.fft.irfft(np.fft.rfft(x, size) * np.fft.rfft(ir, size), size)
    dry = np.concatenate([x, np.zeros(n)])
    out = dry * (1 - mix) + wet * mix * 0.6
    return out if tail else out[: len(x)]


def loop_reverb(x, seconds=1.5, mix=0.3, tone=3000):
    """Hall, der am Ende wieder vorne ankommt (für Schleifen)"""
    n = min(int(seconds * SR), len(x))
    ir = np.zeros(len(x))
    ir[:n] = noise(n) * np.exp(-np.arange(n) / SR * (6.9 / seconds))
    ir = fft_filter(ir, lowpass(tone))
    ir /= np.sqrt(np.sum(ir ** 2))
    wet = np.fft.irfft(np.fft.rfft(x) * np.fft.rfft(ir), len(x))
    return x * (1 - mix) + wet * mix * 0.6


def place(track, start, sig, wrap=False):
    a = int(start * SR)
    if wrap:
        idx = (np.arange(len(sig)) + a) % len(track)
        np.add.at(track, idx, sig)
        return
    if a >= len(track):
        return
    b = min(a + len(sig), len(track))
    track[a:b] += sig[: b - a]


def add(*parts):
    """Signale verschiedener Länge zusammenmischen"""
    out = np.zeros(max(len(p) for p in parts))
    for p in parts:
        out[: len(p)] += p
    return out


def resonate(x, freqs, decay, length=0.15):
    """Körper (Holz/Metall): kurze Resonanzen auf jeden Impuls"""
    n = int(length * SR)
    tt = np.arange(n) / SR
    kernel = sum(np.sin(2 * np.pi * f * tt) * np.exp(-tt * decay * (1 + i * 0.3)) / (1 + i * 0.5) for i, f in enumerate(freqs))
    return np.convolve(x, kernel)[: len(x)]


def impulse(n, at=0):
    x = np.zeros(n)
    x[int(at * SR)] = 1
    return x


def thump(seconds, f_start, f_end, decay):
    t = t_axis(seconds)
    freq = f_end + (f_start - f_end) * np.exp(-t * 18)
    return np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t * decay)


def burst(seconds, lo, hi, decay):
    t = t_axis(seconds)
    return fft_filter(noise(len(t)), bandpass(lo, hi)) * np.exp(-t * decay)


def tv_filter(x, center, width=0.5, frame=1024, order=2):
    """Zeitlich veränderlicher Bandpass: center(Zeit in s) -> Mittenfrequenz"""
    hop = frame // 2
    win = np.hanning(frame)
    xp = np.concatenate([x, np.zeros(frame)])
    out = np.zeros(len(xp))
    norm = np.zeros(len(xp))
    freqs = np.fft.rfftfreq(frame, 1 / SR)
    for start in range(0, len(x), hop):
        seg = xp[start : start + frame] * win
        c = center((start + frame / 2) / SR)
        gain = bandpass(c * (1 - width), c * (1 + width), order)(freqs)
        out[start : start + frame] += np.fft.irfft(np.fft.rfft(seg) * gain, frame) * win
        norm[start : start + frame] += win ** 2
    return out[: len(x)] / np.maximum(norm[: len(x)], 1e-3)


def loopify(x, overlap):
    """Ende in den Anfang überblenden -> nahtlose Schleife"""
    o = int(overlap * SR)
    y = x[: len(x) - o].copy()
    ramp = np.linspace(0, 1, o)
    y[:o] = x[:o] * np.sqrt(ramp) + x[len(x) - o :] * np.sqrt(1 - ramp)
    return y


def throat(seconds, base, rough, env, formants=(60, 900, 250, 600)):
    """Tiefe, rauhe Stimme (Knurren, Brüllen): Pulse mit zitternder Tonhöhe durch Formanten"""
    n = int(seconds * SR)
    t = np.arange(n) / SR
    wobble = 1 + 0.08 * np.sin(2 * np.pi * 5.5 * t) + 0.05 * fft_filter(noise(n), lowpass(8))
    b = base(t) if callable(base) else base
    phase = np.cumsum(b * wobble / SR)
    pulses = (np.mod(phase, 1) < 0.18).astype(float) - 0.18
    voice = fft_filter(pulses, bandpass(formants[0], formants[1])) + 0.6 * fft_filter(pulses, bandpass(formants[2], formants[3]))
    rasp = fft_filter(noise(n), bandpass(300, 2600)) * (0.5 + 0.5 * np.sin(2 * np.pi * phase)) * rough
    return (voice + rasp) * env(t)


def save(name, x, level=None, drive=None):
    if drive:
        x = np.tanh(normalize(x, 1.0) * drive) / np.tanh(drive)
    if not name.endswith("_loop"):
        # Stille am Ende abschneiden (Hallfahne bis -54 dB behalten)
        loud = np.nonzero(np.abs(x) > np.max(np.abs(x)) * 0.002)[0]
        if len(loud):
            x = fade(x[: min(len(x), loud[-1] + int(0.05 * SR))], 0, 0.05)
    if level is not None:
        x = normalize(x, level)
    x = np.clip(x, -1, 1)
    wav = os.path.join(OUT, name + ".wav")
    with wave.open(wav, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "6", os.path.join(OUT, name + ".ogg")], check=True)
    os.remove(wav)
    print(f"{name}.ogg  {len(x) / SR:.1f}s")


# ------------------------------------------------------------------ Bausteine
def crack(amp=1.0, bright=1.0):
    """Knacken (Knochen, Holz): sehr kurzer Impuls mit harter Resonanz"""
    n = int(0.09 * SR)
    t = np.arange(n) / SR
    click = fft_filter(noise(n), highpass(1200 * bright)) * np.exp(-t * 320)
    body = resonate(impulse(n), [rng.uniform(1500, 2200) * bright, rng.uniform(2800, 3600) * bright, rng.uniform(600, 900)], 140, 0.08)
    return (click * 0.8 + body * 0.5) * amp


def wood_knock(amp=1.0, pitch=1.0, n_seconds=0.5):
    n = int(n_seconds * SR)
    t = np.arange(n) / SR
    hit = fft_filter(noise(n), lowpass(2500)) * np.exp(-t * 90)
    body = resonate(impulse(n), [180 * pitch, 410 * pitch, 690 * pitch, 1150 * pitch], 22, 0.4)
    low = thump(n_seconds, 120 * pitch, 70 * pitch, 18)
    return (hit * 0.5 + body * 0.8 + low * 0.6) * amp


def metal_clang(amp=1.0, pitch=1.0, seconds=1.6):
    n = int(seconds * SR)
    t = np.arange(n) / SR
    partials = [(520, 3.5), (1236, 4.2), (1987, 5), (2911, 6.5), (3830, 8), (5210, 10)]
    tone = sum(np.sin(2 * np.pi * f * pitch * t + rng.uniform(0, 6)) * np.exp(-t * d) / (1 + i * 0.4) for i, (f, d) in enumerate(partials))
    hit = burst(seconds, 1500, 8000, 120)
    return (tone * 0.6 + hit * 0.5) * amp


def leaves(seconds, density=60, amp=1.0):
    """Rascheln: viele kleine Körnchen aus hellem Rauschen"""
    n = int(seconds * SR)
    out = np.zeros(n)
    grain_n = int(0.02 * SR)
    gt = np.arange(grain_n) / SR
    for _ in range(int(density * seconds)):
        g = fft_filter(noise(grain_n), bandpass(rng.uniform(1500, 3000), rng.uniform(5000, 9000))) * np.exp(-gt * rng.uniform(120, 300))
        place(out, rng.uniform(0, seconds), g * rng.uniform(0.2, 1.0))
    return out * amp


def whisper_voice(seconds, rate=5.0, amp=1.0):
    """Flüstern: Silben aus Rauschen mit wechselnden Vokal-Formanten, dazwischen 'sss'"""
    n = int(seconds * SR)
    out = np.zeros(n)
    time = rng.uniform(0, 0.3)
    while time < seconds:
        length = rng.uniform(0.1, 0.28)
        m = int(length * SR)
        tt = np.arange(m) / SR
        if rng.random() < 0.15:
            syl = fft_filter(noise(m), bandpass(4000, 7500)) * 0.6
        else:
            f1, f2, f3 = rng.uniform(300, 800), rng.uniform(900, 2300), rng.uniform(2400, 3200)
            syl = fft_filter(noise(m), lambda f: peak(f1, 6)(f) + 0.8 * peak(f2, 8)(f) + 0.4 * peak(f3, 10)(f))
            syl += 0.12 * fft_filter(noise(m), bandpass(3000, 6000))
        env = np.minimum(tt / 0.03, 1) * np.minimum((length - tt) / 0.07, 1)
        place(out, time, syl * np.maximum(env, 0) * rng.uniform(0.5, 1.0))
        time += length + (rng.uniform(0.02, 0.1) if rng.random() < 0.8 else rng.uniform(0.3, 0.9))
    return out * amp


def sting(seconds=3.0, root=110.0, bright=1.0, suck=0.5):
    """Schreck-Ton: kurzer Sog (rückwärts), dann Schlag mit schiefem Metall-Cluster und Boom"""
    n = int(seconds * SR)
    out = np.zeros(n)
    t = np.arange(n) / SR
    # Sog
    if suck > 0:
        m = int(suck * SR)
        place(out, 0, fft_filter(noise(m), bandpass(300, 6000)) * np.linspace(0, 1, m) ** 3 * 0.5)
    hit_at = suck
    ht = t_axis(seconds - hit_at)
    cluster = sum(np.sin(2 * np.pi * root * r * bright * ht + rng.uniform(0, 6)) * np.exp(-ht * (1.2 + i * 0.4)) for i, r in enumerate([1, 1.06, 1.414, 2.13, 2.83, 3.97, 5.6]))
    screech = sum(np.sin(2 * np.pi * f * bright * ht * (1 + 0.004 * np.sin(2 * np.pi * 6 * ht))) for f in [1870, 1940, 2410]) * np.exp(-ht * 2.2) * 0.35
    boom = thump(seconds - hit_at, 90, 38, 2.5) * 1.4
    crash = burst(seconds - hit_at, 2000, 10000, 9) * 0.5
    place(out, hit_at, np.tanh((cluster * 0.5 + screech + boom + crash) * 1.5))
    return out


# ------------------------------------------------------------------ Ritualsaal
def ritual_whisper_loop():
    d = 12
    x = sum(whisper_voice(d + 2, amp=rng.uniform(0.6, 1.0)) for _ in range(5))
    x = fft_filter(x, bandpass(250, 5500))
    x = loopify(x, 2.0)
    x = loop_reverb(x, 2.4, 0.5, 4000)
    # tiefes Summen darunter (leise)
    t = np.arange(len(x)) / SR
    hum = sum(np.sin(2 * np.pi * f * t) for f in [55, 55 * 1.5, 110.5]) * (0.5 + 0.5 * np.sin(2 * np.pi * t / (len(x) / SR)) ** 2)
    return normalize(x, 0.8) + hum * 0.04


def neck_crack():
    d = 0.6
    out = np.zeros(int(d * SR))
    time = 0.02
    for k in range(rng.integers(4, 6)):
        place(out, time, crack(rng.uniform(0.5, 1.0), rng.uniform(0.8, 1.2)))
        time += rng.uniform(0.025, 0.07)
    place(out, time + 0.05, add(crack(1.0, 0.7), thump(0.15, 140, 80, 40) * 0.3))
    return reverb(out, 0.8, 0.2, 5000)


def ritual_sting():
    return reverb(sting(3.2, 98, 1.0, 0.12), 3.0, 0.4, 4000)


def sarp_step():
    d = 1.0
    out = np.zeros(int(d * SR))
    place(out, 0, thump(0.7, 75, 38, 9) * 1.2)
    place(out, 0, burst(0.2, 200, 2500, 35) * 0.5)
    # Schleifen danach (der Fuß wird nachgezogen)
    sc = int(0.45 * SR)
    st = np.arange(sc) / SR
    scrape = fft_filter(noise(sc), bandpass(250, 1800)) * np.sin(np.pi * st / 0.45) * (0.7 + 0.3 * np.sin(2 * np.pi * 23 * st))
    place(out, 0.18, scrape * 0.45)
    return reverb(out, 1.2, 0.25, 3000)


def sarp_breath():
    d = 2.6
    t = t_axis(d)
    env_in = np.clip(np.sin(np.pi * np.clip(t / 1.1, 0, 1)), 0, 1)
    env_out = np.clip(np.sin(np.pi * np.clip((t - 1.25) / 1.25, 0, 1)), 0, 1)
    air_in = fft_filter(noise(len(t)), lambda f: bandpass(300, 2200)(f) + peak(1100, 4)(f)) * env_in * 0.6
    air_out = fft_filter(noise(len(t)), lambda f: bandpass(150, 1500)(f) + peak(650, 3)(f)) * env_out
    rattle = fft_filter(noise(len(t)), bandpass(60, 400)) * (env_in + env_out) * (0.55 + 0.45 * np.sign(np.sin(2 * np.pi * 28 * t)))
    return reverb(air_in + air_out + rattle * 0.9, 1.0, 0.2, 3000)


def claw_swipe():
    d = 0.55
    t = t_axis(d)
    env = np.sin(np.pi * np.clip(t / d, 0, 1)) ** 2
    x = tv_filter(noise(len(t)), lambda s: 500 + 3500 * (s / d) ** 1.5, 0.45) * env
    return reverb(x, 0.6, 0.15, 6000)


def claw_hit():
    d = 1.0
    out = np.zeros(int(d * SR))
    place(out, 0, claw_swipe()[: int(0.35 * SR)] * 0.7)
    place(out, 0.2, thump(0.5, 110, 55, 14) * 0.9)
    # reißender Stoff
    tear_n = int(0.3 * SR)
    tt = np.arange(tear_n) / SR
    gate = (rng.random(tear_n) < 0.004).astype(float)
    gate = np.convolve(gate, np.exp(-np.arange(200) / 30))[:tear_n]
    tear = fft_filter(noise(tear_n), bandpass(1200, 6000)) * np.minimum(gate, 1) * np.exp(-tt * 6)
    place(out, 0.2, tear * 0.8)
    place(out, 0.2, burst(0.25, 400, 3000, 25) * 0.6)
    return reverb(out, 0.9, 0.2, 4000)


def sarp_grab():
    d = 1.8
    out = np.zeros(int(d * SR))
    place(out, 0, thump(0.4, 100, 55, 16) * 0.8)
    place(out, 0, leaves(0.4, 120, 0.6))
    env = lambda t: np.clip(t / 0.15, 0, 1) * np.clip((1.4 - t) / 0.6, 0, 1)
    place(out, 0.1, throat(1.4, 52, 1.1, env) * 0.9)
    return reverb(np.tanh(out * 1.4), 1.6, 0.3, 2500)


def body_fall():
    d = 1.4
    out = np.zeros(int(d * SR))
    place(out, 0, thump(0.9, 85, 40, 8) * 1.3)
    place(out, 0, burst(0.15, 100, 1500, 30) * 0.8)
    place(out, 0.14, thump(0.5, 70, 45, 14) * 0.6)
    place(out, 0.05, leaves(0.5, 60, 0.35))
    return reverb(out, 1.6, 0.3, 2500)


def candelabrum_fall():
    d = 2.6
    out = np.zeros(int(d * SR))
    for at, amp, pitch in [(0.0, 1.0, 1.0), (0.32, 0.6, 0.97), (0.55, 0.4, 1.03), (0.72, 0.25, 0.99), (0.83, 0.15, 1.01)]:
        place(out, at, metal_clang(amp, pitch, d - at))
    # rollt kurz nach
    roll_n = int(0.6 * SR)
    rt = np.arange(roll_n) / SR
    roll = fft_filter(noise(roll_n), bandpass(2000, 6000)) * (0.5 + 0.5 * np.sin(2 * np.pi * 14 * rt)) * np.exp(-rt * 4) * 0.15
    place(out, 0.9, roll)
    place(out, 0.05, thump(0.3, 90, 60, 20) * 0.4)
    return reverb(out, 2.2, 0.35, 5000)


def fire_burst():
    d = 2.8
    t = t_axis(d)
    whoosh = tv_filter(noise(len(t)), lambda s: 200 + 1100 * min(s / 0.4, 1), 0.6) * np.minimum(t / 0.08, 1) * np.exp(-t * 1.2)
    roar = fft_filter(brown(len(t)), lowpass(700)) * np.minimum(t / 0.1, 1) * np.exp(-t * 0.7)
    out = whoosh + normalize(roar, 1.0) * 0.8
    for _ in range(40):
        place(out, rng.uniform(0.1, d - 0.2), crack(rng.uniform(0.05, 0.25), rng.uniform(1.0, 1.6)))
    return reverb(out, 1.5, 0.25, 4000)


def sarp_burn_scream():
    d = 3.2
    t = t_axis(d)
    env = lambda tt: np.clip(tt / 0.08, 0, 1) * np.clip((d - tt) / 1.4, 0, 1)
    pitch = lambda tt: 150 + 120 * np.sin(np.pi * np.clip(tt / d, 0, 1)) + 15 * np.sin(2 * np.pi * 7 * tt)
    voice = throat(d, pitch, 2.0, env, formants=(200, 3000, 700, 1300))
    low = throat(d, lambda tt: pitch(tt) / 2.02, 1.2, env)
    shriek = fft_filter(noise(len(t)), lambda f: peak(1300, 5)(f) + peak(2600, 6)(f)) * env(t) * 0.5
    fire = fire_crackle_bed(d) * 0.3
    return reverb(np.tanh((voice + low * 0.6 + shriek) * 2.2) + fire, 2.4, 0.35, 4000)


def puppet_collapse():
    d = 1.6
    out = np.zeros(int(d * SR))
    place(out, 0.15, thump(0.6, 80, 45, 10) * 0.8)
    for at in [0.0, 0.08, 0.18, 0.27, 0.4]:
        place(out, at + rng.uniform(-0.01, 0.01), wood_knock(rng.uniform(0.3, 0.6), rng.uniform(1.6, 2.4), 0.3))
    place(out, 0.1, leaves(0.5, 40, 0.3))
    return reverb(out, 1.4, 0.3, 3000)


def qte_success():
    d = 0.7
    out = np.zeros(int(d * SR))
    for at, f in [(0.0, 659.25), (0.08, 987.77)]:
        t = t_axis(d - at)
        tone = (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t) + 0.1 * np.sin(2 * np.pi * 3 * f * t)) * np.exp(-t * 7) * np.minimum(t / 0.004, 1)
        place(out, at, tone * 0.5)
    return reverb(out, 0.8, 0.25, 6000)


def qte_fail():
    d = 0.8
    t = t_axis(d)
    f = 160 - 60 * t / d
    tone = np.sign(np.sin(2 * np.pi * np.cumsum(f) / SR)) * 0.3 + np.sin(2 * np.pi * np.cumsum(f * 1.06) / SR) * 0.4
    tone = fft_filter(tone, lowpass(1200)) * np.exp(-t * 3) * np.minimum(t / 0.005, 1)
    return reverb(tone + thump(d, 90, 50, 10) * 0.5, 0.8, 0.2, 3000)


# ------------------------------------------------------------------ Flucht und Verwandlung
def sarp_roar():
    d = 3.0
    env = lambda t: np.clip(t / 0.15, 0, 1) * np.clip((d - t) / 1.3, 0, 1)
    x = throat(d, lambda t: 62 + 18 * np.sin(np.pi * np.clip(t / d, 0, 1)), 1.8, env) + 0.5 * throat(d, 95, 1.3, env)
    shriek = fft_filter(noise(int(d * SR)), bandpass(1200, 4000)) * env(t_axis(d)) * 0.3
    return reverb(np.tanh((x + shriek) * 2.6), 3.0, 0.4, 3000)


def run_breath_loop():
    cycle = 0.72
    d = cycle * 6
    t = t_axis(d)
    phase = np.mod(t, cycle) / cycle
    env_in = np.where(phase < 0.42, np.sin(np.pi * phase / 0.42), 0)
    env_out = np.where(phase >= 0.48, np.sin(np.pi * np.clip((phase - 0.48) / 0.48, 0, 1)), 0)
    air_in = fft_filter(noise(len(t)), lambda f: bandpass(500, 4000)(f) * (0.4 + peak(1500, 3)(f))) * env_in * 0.55
    air_out = fft_filter(noise(len(t)), lambda f: bandpass(250, 3000)(f) * (0.4 + peak(900, 2.5)(f))) * env_out
    # Stimme schwingt beim Ausatmen leicht mit (Keuchen)
    voice = np.sin(2 * np.pi * 180 * t + 3 * np.sin(2 * np.pi * 5 * t)) * env_out ** 3 * 0.05
    return loop_reverb(air_in + air_out + voice, 0.6, 0.15, 5000)


def chase_music_loop():
    bpm = 120
    beat = 60 / bpm
    bars = 8
    d = bars * 4 * beat  # 16 s
    n = int(d * SR)
    drums = np.zeros(n)
    sub = np.zeros(n)
    ticks = np.zeros(n)
    strings = np.zeros(n)
    t_all = np.arange(n) / SR
    # große Trommeln (wie Taiko): 1, "und" von 2, 3 ... mit Variation am Ende jeder 2. Takte
    hit_n = int(1.2 * SR)
    def drum(amp, pitch=1.0):
        return (thump(1.2, 140 * pitch, 55 * pitch, 7) + burst(1.2, 150, 2500, 28) * 1.1) * amp
    for bar in range(bars):
        base = bar * 4 * beat
        pattern = [(0, 1.0), (1.5, 0.7), (2, 0.85), (3.25, 0.5), (3.5, 0.6)] if bar % 2 == 0 else [(0, 1.0), (1, 0.6), (1.5, 0.7), (2, 0.9), (2.75, 0.5), (3, 0.7), (3.5, 0.8), (3.75, 0.9)]
        for at, amp in pattern:
            place(drums, base + at * beat, drum(amp, rng.uniform(0.95, 1.05)), wrap=True)
        # tiefer Puls in Achteln (D)
        for k in range(8):
            pt = t_axis(beat / 2)
            pulse = (np.sin(2 * np.pi * 73.4 * pt) + 0.3 * np.sin(2 * np.pi * 146.8 * pt)) * np.exp(-pt * 7)
            place(sub, base + k * beat / 2, pulse * (0.9 if k % 2 == 0 else 0.6), wrap=True)
        # Ticken (Metall) in Sechzehnteln
        for k in range(16):
            tk = t_axis(0.06)
            tick = fft_filter(noise(len(tk)), highpass(7000)) * np.exp(-tk * 90)
            place(ticks, base + k * beat / 4, tick * (0.5 if k % 4 == 2 else 0.25), wrap=True)
    # schiefe Streicher-Fläche: D und Es, langsam auf- und abschwellend; nach 8 s eine Stufe höher
    for f, start, length in [(146.8, 0, d / 2), (155.6, 0, d / 2), (164.8, d / 2, d / 2), (174.6, d / 2, d / 2)]:
        st = t_axis(length)
        saw = sum(np.sin(2 * np.pi * f * k * (1 + dt) * st) / k for k in range(1, 9) for dt in (-0.003, 0.003))
        env = np.minimum(st / 1.5, 1) * np.minimum((length - st) / 1.5, 1)
        place(strings, start, saw * env * 0.08, wrap=True)
    strings = fft_filter(strings, lowpass(1800))
    # treibendes Streicher-Ostinato in Sechzehnteln (Mitten: hört man auch auf kleinen Lautsprechern)
    ostinato = np.zeros(n)
    figure = [146.8, 146.8, 174.6, 146.8, 155.6, 146.8, 146.8, 130.8]
    for k in range(bars * 16):
        f = figure[k % len(figure)] * (1.0 if k < bars * 8 else 1.122)
        nt = t_axis(beat / 4 + 0.05)
        note = sum(np.sin(2 * np.pi * f * h * nt) / h for h in range(1, 10)) * np.exp(-nt * 18) * np.minimum(nt / 0.004, 1)
        place(ostinato, k * beat / 4, note * (1.0 if k % 4 == 0 else 0.6), wrap=True)
    ostinato = fft_filter(ostinato, bandpass(120, 2600))
    # hoher, zitternder Ton (Spannung)
    tremolo = np.sin(2 * np.pi * 1174.7 * t_all) * (0.5 + 0.5 * np.sin(2 * np.pi * 8 * t_all)) * 0.025
    mix = (
        normalize(loop_reverb(drums, 1.8, 0.35, 2500), 1.0) * 0.8
        + normalize(fft_filter(sub, lowpass(300)), 1.0) * 0.2
        + normalize(ticks, 1.0) * 0.15
        + normalize(loop_reverb(strings + tremolo * 2, 2.5, 0.5, 4000), 1.0) * 0.5
        + normalize(loop_reverb(ostinato, 1.2, 0.25, 4000), 1.0) * 0.75
    )
    return np.tanh(normalize(mix, 1.0) * 1.2)


def transform_crack():
    d = 6.5
    n = int(d * SR)
    out = np.zeros(n)
    time = 0.1
    while time < d - 0.5:
        density = 0.25 - 0.18 * (time / d)  # wird immer dichter
        place(out, time, crack(rng.uniform(0.4, 1.0), rng.uniform(0.6, 1.3)))
        if rng.random() < 0.25:
            place(out, time, thump(0.2, 160, 90, 25) * 0.3)
        time += rng.uniform(0.02, density)
    # nasses, schmatzendes Geräusch darunter
    t = np.arange(n) / SR
    squelch = fft_filter(noise(n), bandpass(80, 700)) * (0.5 + 0.5 * np.sin(2 * np.pi * 3.3 * t + 2 * np.sin(2 * np.pi * 0.7 * t))) * np.minimum(t / 1.0, 1) * 0.35
    env = lambda tt: np.clip(tt / 1.5, 0, 1) * np.clip((d - tt) / 1.0, 0, 1)
    groan = throat(d, lambda tt: 38 + 10 * tt / d, 0.9, env) * 0.5
    return reverb(out + squelch + groan, 2.0, 0.3, 3500)


def jumpscare():
    d = 2.0
    t = t_axis(d)
    env = np.minimum(t / 0.01, 1) * np.exp(-t * 1.6)
    screech = sum(np.sin(2 * np.pi * np.cumsum(f0 * (1 + 0.25 * t / d) * (1 + 0.01 * np.sin(2 * np.pi * 9 * t))) / SR) for f0 in [1210, 1290, 1720, 2390, 3100])
    noise_hit = fft_filter(noise(len(t)), bandpass(800, 9000)) * np.exp(-t * 3)
    boom = thump(d, 80, 35, 2.2) * 1.5
    return reverb(np.tanh((screech * 0.35 + noise_hit * 0.8) * env * 3 + boom), 1.8, 0.3, 6000)


# ------------------------------------------------------------------ Hindernisse und Wetter
def thunder():
    d = 8.0
    n = int(d * SR)
    t = np.arange(n) / SR
    crack_part = fft_filter(noise(n), highpass(800)) * np.exp(-t * 7) * 0.6
    snaps = np.zeros(n)
    for _ in range(25):
        place(snaps, rng.uniform(0, 0.5), crack(rng.uniform(0.2, 0.7), rng.uniform(0.5, 1.0)))
    rumble = np.zeros(n)
    for start, amp, length in [(0.05, 1.0, 5.5), (0.9, 0.7, 4.5), (2.2, 0.5, 4.0), (3.6, 0.35, 3.5)]:
        m = int(length * SR)
        rt = np.arange(m) / SR
        r = fft_filter(brown(m), bandpass(25, 220)) * np.minimum(rt / 0.3, 1) * np.exp(-rt * 0.9)
        r *= 0.6 + 0.4 * np.abs(fft_filter(noise(m), lowpass(4)))
        place(rumble, start, normalize(r, amp))
    return fft_filter(reverb(crack_part * 0.6 + snaps * 0.4 + rumble * 1.4, 3.5, 0.35, 1800), lowpass(5000))


def creak(seconds, rate_base, freqs, amp=1.0):
    n = int(seconds * SR)
    tt = np.arange(n) / SR
    rate = rate_base * (0.6 + 0.6 * np.sin(np.pi * tt / seconds)) + 6 * np.sin(2 * np.pi * 1.3 * tt)
    phase = np.cumsum(rate) / SR
    pulses = np.zeros(n)
    ticks = np.nonzero(np.diff(np.floor(phase)) > 0)[0]
    pulses[ticks] = rng.uniform(0.5, 1.0, len(ticks))
    env = np.sin(np.pi * np.clip(tt / seconds, 0, 1)) ** 0.7
    return resonate(pulses * env, freqs, 40) * amp


def tree_crash():
    d = 5.0
    out = np.zeros(int(d * SR))
    place(out, 0, creak(1.3, 30, [240, 410, 690, 1100]) * 0.8)
    place(out, 1.25, crack(1.0, 0.6) + crack(0.8, 0.8))
    for _ in range(8):
        place(out, 1.25 + rng.uniform(0, 0.15), crack(rng.uniform(0.3, 0.7), rng.uniform(0.5, 0.9)))
    fall_n = int(1.2 * SR)
    ft = np.arange(fall_n) / SR
    whoosh = tv_filter(noise(fall_n), lambda s: 300 + 900 * s / 1.2, 0.6) * (ft / 1.2) ** 2 * 0.6
    place(out, 1.3, whoosh + leaves(1.2, 90, 0.4) * (ft / 1.2))
    place(out, 2.5, thump(2.0, 70, 30, 2.5) * 1.6)
    place(out, 2.5, burst(1.2, 80, 2500, 5) * 0.8)
    place(out, 2.5, leaves(1.5, 220, 0.9) * np.exp(-t_axis(1.5) * 2))
    for _ in range(14):
        place(out, 2.5 + rng.uniform(0, 0.6), crack(rng.uniform(0.2, 0.6), rng.uniform(0.6, 1.0)))
    return reverb(out, 2.5, 0.35, 3000)


def wood_splinter():
    d = 1.4
    out = np.zeros(int(d * SR))
    time = 0.0
    for k in range(12):
        place(out, time, crack(rng.uniform(0.4, 1.0), rng.uniform(0.5, 0.9)))
        time += rng.uniform(0.01, 0.05)
    place(out, 0.0, wood_knock(0.9, 0.8, 0.6))
    place(out, 0.05, burst(0.6, 300, 4000, 8) * 0.4)
    return reverb(out, 1.4, 0.3, 4000)


def stumble():
    d = 1.0
    out = np.zeros(int(d * SR))
    sc = int(0.25 * SR)
    place(out, 0, fft_filter(noise(sc), bandpass(300, 3000)) * np.sin(np.pi * np.arange(sc) / sc) * 0.5)
    place(out, 0.2, thump(0.5, 90, 50, 12) * 0.9)
    place(out, 0.2, leaves(0.5, 120, 0.5))
    place(out, 0.4, thump(0.3, 70, 45, 18) * 0.4)
    return reverb(out, 1.0, 0.2, 3000)


def head_hit():
    d = 0.9
    out = np.zeros(int(d * SR))
    place(out, 0, wood_knock(1.0, 0.85, 0.8))
    place(out, 0, thump(0.6, 140, 70, 12) * 0.8)
    return reverb(out, 1.0, 0.25, 3000)


def jump_land():
    d = 0.7
    out = np.zeros(int(d * SR))
    place(out, 0, thump(0.5, 95, 50, 14) * 0.9)
    place(out, 0, leaves(0.4, 150, 0.6))
    place(out, 0, burst(0.12, 200, 3000, 40) * 0.4)
    return reverb(out, 0.8, 0.2, 3000)


def mud_step():
    d = 0.7
    t = t_axis(d)
    squish = fft_filter(noise(len(t)), bandpass(80, 900)) * np.minimum(t / 0.02, 1) * np.exp(-t * 9)
    suction = tv_filter(noise(len(t)), lambda s: 300 + 900 * min(s / 0.25, 1), 0.25, order=3) * np.exp(-((t - 0.22) / 0.07) ** 2) * 0.8
    out = squish + suction
    for _ in range(4):
        bt = t_axis(0.04)
        f0 = rng.uniform(300, 700)
        bubble = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 2 * bt / 0.04)) / SR) * np.exp(-bt * 80)
        place(out, rng.uniform(0.15, 0.4), bubble * 0.25)
    return reverb(out, 0.6, 0.15, 3000)


def splash():
    d = 1.0
    t = t_axis(d)
    spray = fft_filter(noise(len(t)), bandpass(700, 9000)) * np.minimum(t / 0.01, 1) * np.exp(-t * 7)
    plop = thump(d, 160, 70, 18) * 0.5
    out = spray + plop
    for _ in range(14):
        bt = t_axis(0.05)
        f0 = rng.uniform(500, 1600)
        bubble = np.sin(2 * np.pi * np.cumsum(f0 * (1 + 1.5 * bt / 0.05)) / SR) * np.exp(-bt * 60)
        place(out, rng.uniform(0.05, 0.6), bubble * rng.uniform(0.1, 0.3))
    return reverb(out, 0.9, 0.2, 5000)


def bush_rustle():
    d = 1.5
    t = t_axis(d)
    x = leaves(d, 260, 1.0) * np.minimum(t / 0.05, 1) * np.exp(-t * 1.6)
    x += fft_filter(noise(len(t)), bandpass(400, 3000)) * np.exp(-t * 3) * 0.3
    place(x, 0.1, crack(0.7, 0.7))
    return reverb(x, 0.8, 0.2, 5000)


def beast_lunge():
    d = 1.8
    t = t_axis(d)
    env = lambda tt: np.clip(tt / 0.04, 0, 1) * np.clip((d - tt) / 1.0, 0, 1)
    voice = throat(d, lambda tt: 210 + 90 * np.exp(-tt * 3), 2.2, env, formants=(300, 3500, 900, 1800))
    shriek = fft_filter(noise(len(t)), lambda f: peak(2200, 4)(f) + peak(3400, 5)(f)) * env(t) * 0.6
    whoosh = tv_filter(noise(len(t)), lambda s: 400 + 2500 * min(s / 0.4, 1), 0.5) * np.exp(-t * 4) * 0.5
    return reverb(np.tanh((voice + shriek) * 2.4) + whoosh, 1.8, 0.3, 5000)


# ------------------------------------------------------------------ Brücke
def bridge_crack():
    d = 2.4
    out = np.zeros(int(d * SR))
    place(out, 0, creak(1.6, 22, [310, 520, 840]) * 0.7)  # Seil dehnt sich
    place(out, 0.3, creak(1.4, 40, [600, 980, 1500]) * 0.5)  # Holz knarrt
    for at in [1.2, 1.55, 1.9]:
        place(out, at, add(crack(1.0, 0.7), wood_knock(0.4, 1.3, 0.3)))
    return reverb(out, 2.0, 0.35, 4000)


def bridge_collapse():
    d = 4.5
    out = np.zeros(int(d * SR))
    for _ in range(10):
        place(out, rng.uniform(0, 0.15), crack(rng.uniform(0.5, 1.0), rng.uniform(0.5, 0.9)))
    whip_n = int(0.35 * SR)
    wt = np.arange(whip_n) / SR
    whip = tv_filter(noise(whip_n), lambda s: 400 + 4000 * s / 0.35, 0.4) * np.sin(np.pi * wt / 0.35) ** 2
    place(out, 0.1, whip * 0.6)
    place(out, 0.18, whip * 0.5)
    # Bretter poltern und fallen weg (werden leiser und dumpfer)
    time = 0.2
    while time < 3.6:
        fade_amount = 1 - time / 3.8
        place(out, time, fft_filter(wood_knock(rng.uniform(0.3, 0.8) * fade_amount, rng.uniform(1.2, 2.2), 0.3), lowpass(4000 * fade_amount + 300)))
        time += rng.uniform(0.04, 0.16) + time * 0.03
    place(out, 0, thump(1.5, 80, 35, 3) * 0.9)
    return reverb(out, 3.0, 0.4, 3000)


# ------------------------------------------------------------------ Hütte
def cabin_ambience_loop():
    d = 14
    n = int(d * SR)
    t = np.arange(n) / SR
    wind = fft_filter(brown(n), bandpass(40, 500)) * (0.6 + 0.4 * np.sin(2 * np.pi * t / d * 2 + 1))
    whistle = fft_filter(noise(n), lambda f: peak(820, 25)(f)) * (0.3 + 0.7 * np.sin(2 * np.pi * t / d * 3) ** 2) * 0.15
    out = normalize(wind, 0.5) + normalize(whistle, 0.08)
    for at in [2.3, 7.1, 11.4]:
        place(out, at, creak(rng.uniform(0.8, 1.4), rng.uniform(25, 45), [220, 380, 610, 980], 0.25), wrap=True)
    return loop_reverb(out, 1.5, 0.25, 3000)


def fire_crackle_bed(d):
    n = int(d * SR)
    out = fft_filter(brown(n), bandpass(60, 500))
    out = normalize(out, 0.2)
    for _ in range(int(18 * d)):
        place(out, rng.uniform(0, d), crack(rng.uniform(0.1, 0.6), rng.uniform(0.8, 1.6)) * 1.2, wrap=True)
    for _ in range(int(2 * d)):
        place(out, rng.uniform(0, d), add(thump(0.08, 300, 150, 60), crack(0.5, 0.9)) * rng.uniform(0.2, 0.5), wrap=True)
    return out


def fire_crackle_loop():
    return loop_reverb(fire_crackle_bed(10), 0.6, 0.15, 6000)


def phone_band(x):
    return np.tanh(fft_filter(x, bandpass(300, 3400, 3)) * 1.5)


def phone_key():
    d = 0.2
    t = t_axis(d)
    tone = (np.sin(2 * np.pi * 770 * t) + np.sin(2 * np.pi * 1336 * t)) * (t < 0.13) * np.minimum(t / 0.003, 1)
    click = burst(0.02, 2000, 8000, 300) * 0.6
    out = phone_band(tone * 0.5)
    place(out, 0, click)
    return out


def phone_pickup():
    d = 1.8
    out = np.zeros(int(d * SR))
    place(out, 0, add(wood_knock(0.5, 3.0, 0.2), burst(0.05, 1500, 7000, 120) * 0.5))
    t = t_axis(1.5)
    dial = (np.sin(2 * np.pi * 350 * t) + np.sin(2 * np.pi * 440 * t)) * np.minimum(t / 0.02, 1) * np.minimum((1.5 - t) / 0.2, 1)
    place(out, 0.25, phone_band(dial * 0.4))
    return out


def phone_ring_loop():
    d = 6.0
    t = t_axis(d)
    on = (t < 2.0).astype(float)
    on = np.convolve(on, np.ones(200) / 200, mode="same")
    tone = (np.sin(2 * np.pi * 440 * t) + np.sin(2 * np.pi * 480 * t)) * on * 0.4
    return phone_band(tone) + fft_filter(noise(len(t)), bandpass(300, 3400)) * 0.004


def phone_wrong():
    d = 3.0
    t = t_axis(d)
    on = (np.mod(t, 1.0) < 0.5).astype(float)
    on = np.convolve(on, np.ones(150) / 150, mode="same")
    tone = (np.sin(2 * np.pi * 480 * t) + np.sin(2 * np.pi * 620 * t)) * on * 0.4
    return fade(phone_band(tone), 0.005, 0.05)


def phone_hangup():
    d = 0.8
    out = np.zeros(int(d * SR))
    place(out, 0, add(wood_knock(0.8, 2.6, 0.4), burst(0.04, 1200, 6000, 150) * 0.6))
    place(out, 0.05, metal_clang(0.08, 2.2, 0.7))  # leise Klingel im Gehäuse
    return reverb(out, 0.6, 0.15, 5000)


def hut_whisper_loop():
    d = 10
    x = sum(whisper_voice(d + 2, rate=4, amp=rng.uniform(0.6, 1.0)) for _ in range(2))
    x = fft_filter(x, bandpass(350, 5000))
    x = loopify(x, 2.0)
    return loop_reverb(x, 2.8, 0.55, 4000)


def light_flicker():
    d = 1.8
    t = t_axis(d)
    buzz = sum(np.sin(2 * np.pi * 120 * k * t) / k for k in range(1, 12))
    buzz = fft_filter(buzz, bandpass(100, 3000))
    gate = np.zeros(len(t))
    time = 0.0
    while time < d:
        length = rng.uniform(0.03, 0.15)
        a, b = int(time * SR), int((time + length) * SR)
        gate[a:b] = rng.uniform(0.3, 1.0)
        time += length + rng.uniform(0.02, 0.12)
    gate = np.convolve(gate, np.ones(100) / 100, mode="same")
    out = buzz * gate * 0.5
    for _ in range(6):
        place(out, rng.uniform(0, d - 0.1), burst(0.03, 3000, 9000, 200) * 0.5)
    return fade(out, 0.005, 0.1)


def mirror_scare():
    return reverb(sting(2.2, 123, 1.15, 0.0), 2.4, 0.35, 5000)


def photo_scare():
    x = sting(2.2, 87, 0.9, 0.0)
    # metallisches Kreischen, das nach oben zieht
    t = t_axis(2.1)
    scrape = tv_filter(noise(len(t)), lambda s: 1500 + 2500 * s / 2.1, 0.08, order=3) * np.exp(-t * 1.5)
    place(x, 0.0, scrape * 0.6)
    return reverb(x, 2.4, 0.35, 5000)


def hallucination_fade():
    d = 6.0
    t = t_axis(d)
    env = np.minimum(t / 0.05, 1) * np.exp(-t * 0.6)
    ring = (np.sin(2 * np.pi * 7200 * t) * 0.5 + np.sin(2 * np.pi * 4100 * t + 0.3 * np.sin(2 * np.pi * 2 * t)) * 0.3) * env
    rumble = fft_filter(brown(len(t)), lowpass(120)) * env
    hiss = fft_filter(noise(len(t)), bandpass(2000, 8000)) * env * 0.1
    return normalize(ring, 0.25) + normalize(rumble, 0.4) + hiss


# ------------------------------------------------------------------ Ende
def siren_far_loop():
    d = 8.0
    t = t_axis(d)
    f = 950 + 420 * np.sin(2 * np.pi * t / 4.0 - np.pi / 2)  # zwei ganze Heul-Zyklen
    phase = np.cumsum(f) / SR
    tone = sum(np.sin(2 * np.pi * k * phase) / k ** 1.2 for k in range(1, 7))
    tone = fft_filter(tone, lowpass(2200))  # weit weg: dumpfer
    tone *= 0.8 + 0.2 * np.sin(2 * np.pi * t / d * 3)
    return loop_reverb(tone, 2.0, 0.55, 2500)


def police_knock():
    d = 1.8
    out = np.zeros(int(d * SR))
    for at in [0.0, 0.3, 0.6]:
        place(out, at, add(wood_knock(1.0, 0.75, 0.6), thump(0.4, 110, 60, 14) * 0.8))
    return reverb(out, 1.2, 0.3, 3000)


def car_door():
    d = 1.2
    out = np.zeros(int(d * SR))
    place(out, 0, thump(0.8, 95, 50, 10) * 1.1)
    place(out, 0, add(metal_clang(0.25, 0.6, 0.6), burst(0.05, 1500, 6000, 120) * 0.5))
    place(out, 0.04, burst(0.03, 3000, 8000, 200) * 0.4)
    return reverb(out, 1.0, 0.2, 3500)


def car_engine_start():
    d = 3.6
    n = int(d * SR)
    t = np.arange(n) / SR
    # Anlasser
    crank_env = np.clip(t / 0.05, 0, 1) * np.clip((1.0 - t) / 0.05, 0, 1)
    whine = np.sin(2 * np.pi * np.cumsum(900 + 100 * np.sin(2 * np.pi * 12 * t)) / SR) * 0.15
    chug = (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 12 * t))) * fft_filter(noise(n), bandpass(80, 600))
    crank = (whine + chug * 0.6) * crank_env
    # Motor springt an, dreht kurz hoch, dann Leerlauf
    rpm = np.where(t < 0.95, 0, 30 + 35 * np.exp(-np.maximum(t - 1.3, 0) * 2.5) * np.clip((t - 0.95) / 0.3, 0, 1))
    phase = np.cumsum(rpm) / SR
    engine = sum(np.sin(2 * np.pi * k * phase + rng.uniform(0, 6)) / k ** 0.8 for k in range(1, 12))
    engine = fft_filter(engine * (0.6 + 0.4 * np.maximum(np.sin(2 * np.pi * phase), 0)), lowpass(900)) * (t > 0.95)
    out = crank + normalize(engine, 0.8)
    return fade(reverb(out, 0.8, 0.15, 3000), 0.005, 0.4)


def car_drive_loop():
    d = 6.0
    n = int(d * SR)
    t = np.arange(n) / SR
    firing = 40  # ganze Perioden in 6 s
    engine = sum(np.sin(2 * np.pi * firing * k * t + rng.uniform(0, 6)) / k ** 0.8 for k in range(1, 12))
    engine = fft_filter(engine, lowpass(800))
    gravel = np.zeros(n)
    for _ in range(int(220 * d)):
        g_n = int(0.015 * SR)
        g = fft_filter(noise(g_n), bandpass(800, 5000)) * np.exp(-np.arange(g_n) / SR * 250)
        place(gravel, rng.uniform(0, d), g * rng.uniform(0.1, 0.6), wrap=True)
    rumble = fft_filter(brown(n), bandpass(30, 200))
    return normalize(engine, 0.45) + normalize(gravel, 0.35) + normalize(rumble, 0.3)


def piano_note(freq, seconds, velocity):
    t = t_axis(seconds)
    env = np.exp(-t * 1.1) * (1 - np.exp(-t * 400))
    tone = sum(np.sin(2 * np.pi * freq * k * (1 + 0.0004 * k * k) * t) * np.exp(-t * (0.8 + k * 0.6)) / k ** 1.3 for k in range(1, 8))
    hammer = fft_filter(noise(len(t)), bandpass(1500, 5000)) * np.exp(-t * 80) * 0.05
    return (tone + hammer) * env * velocity


def ending_music():
    beat = 60 / 64  # langsam
    chords = [
        (110.0, [220.0, 261.63, 329.63, 440.0]),  # Am
        (87.31, [174.61, 220.0, 261.63, 349.23]),  # F
        (130.81, [196.0, 261.63, 329.63, 392.0]),  # C
        (98.0, [196.0, 246.94, 293.66, 392.0]),  # G
        (110.0, [220.0, 261.63, 329.63, 440.0]),  # Am
        (87.31, [174.61, 220.0, 261.63, 349.23]),  # F
        (82.41, [164.81, 207.65, 246.94, 329.63]),  # E
        (110.0, [220.0, 261.63, 329.63, 440.0]),  # Am (Schluss)
    ]
    melody = [659.25, 587.33, 523.25, 493.88, 523.25, 440.0, 493.88, 440.0]
    length = len(chords) * 4 * beat + 6
    n = int(length * SR)
    piano = np.zeros(n)
    pad = np.zeros(n)
    for i, (root, notes) in enumerate(chords):
        start = i * 4 * beat
        last = i == len(chords) - 1
        place(piano, start, piano_note(root, 5, 0.35))
        for k, note in enumerate([notes[0], notes[1], notes[2], notes[3], notes[2], notes[1]] if not last else [notes[0], notes[2], notes[3]]):
            place(piano, start + beat * 0.5 + k * beat * 0.55, piano_note(note, 4, 0.18 + 0.04 * (k % 2)))
        place(piano, start + beat * 2, piano_note(melody[i] * (1 if not last else 1), 5, 0.26))
        pt = t_axis(4 * beat + 2)
        env = np.minimum(pt / 1.5, 1) * np.exp(-np.maximum(pt - 4 * beat, 0) * 1.5)
        swell = sum(np.sin(2 * np.pi * f * (1 + dt) * pt) for f in notes[:3] for dt in (-0.002, 0.002))
        place(pad, start, swell * env * 0.025)
    pad = fft_filter(pad, lowpass(1200))
    mix = reverb(piano + pad, 3.5, 0.45, 4500)
    mix = mix[: n]
    return fade(normalize(mix, 0.8), 0.5, 4.0)


# ------------------------------------------------------------------ Los
# leise, kurze Knack-Geräusche etwas kräftiger machen (weiche Sättigung)
DRIVE = {
    "neck_crack": 3, "wood_splinter": 2.5, "phone_hangup": 2, "head_hit": 2, "bush_rustle": 2, "splash": 2,
    "claw_hit": 2, "police_knock": 1.8, "puppet_collapse": 1.8, "candelabrum_fall": 1.5, "bridge_collapse": 1.8,
    "bridge_crack": 1.8, "fire_crackle_loop": 2.2, "stumble": 1.6, "jump_land": 1.6, "car_door": 1.6, "body_fall": 1.5,
}

SOUNDS = [
    ("ritual_whisper_loop", ritual_whisper_loop, 0.8),
    ("neck_crack", neck_crack, 0.9),
    ("ritual_sting", ritual_sting, 0.95),
    ("sarp_step", sarp_step, 0.9),
    ("sarp_breath", sarp_breath, 0.8),
    ("claw_swipe", claw_swipe, 0.85),
    ("claw_hit", claw_hit, 0.9),
    ("sarp_grab", sarp_grab, 0.9),
    ("body_fall", body_fall, 0.9),
    ("candelabrum_fall", candelabrum_fall, 0.85),
    ("fire_burst", fire_burst, 0.9),
    ("sarp_burn_scream", sarp_burn_scream, 0.9),
    ("puppet_collapse", puppet_collapse, 0.85),
    ("qte_success", qte_success, 0.7),
    ("qte_fail", qte_fail, 0.75),
    ("sarp_roar", sarp_roar, 0.95),
    ("run_breath_loop", run_breath_loop, 0.7),
    ("chase_music_loop", chase_music_loop, 0.85),
    ("transform_crack", transform_crack, 0.9),
    ("jumpscare", jumpscare, 0.95),
    ("thunder", thunder, 0.95),
    ("tree_crash", tree_crash, 0.95),
    ("wood_splinter", wood_splinter, 0.9),
    ("stumble", stumble, 0.85),
    ("head_hit", head_hit, 0.9),
    ("jump_land", jump_land, 0.85),
    ("mud_step", mud_step, 0.8),
    ("splash", splash, 0.85),
    ("bush_rustle", bush_rustle, 0.85),
    ("beast_lunge", beast_lunge, 0.95),
    ("bridge_crack", bridge_crack, 0.9),
    ("bridge_collapse", bridge_collapse, 0.95),
    ("cabin_ambience_loop", cabin_ambience_loop, 0.6),
    ("fire_crackle_loop", fire_crackle_loop, 0.7),
    ("phone_key", phone_key, 0.6),
    ("phone_pickup", phone_pickup, 0.7),
    ("phone_ring_loop", phone_ring_loop, 0.6),
    ("phone_wrong", phone_wrong, 0.6),
    ("phone_hangup", phone_hangup, 0.75),
    ("hut_whisper_loop", hut_whisper_loop, 0.6),
    ("light_flicker", light_flicker, 0.7),
    ("mirror_scare", mirror_scare, 0.95),
    ("photo_scare", photo_scare, 0.95),
    ("hallucination_fade", hallucination_fade, 0.7),
    ("siren_far_loop", siren_far_loop, 0.7),
    ("police_knock", police_knock, 0.9),
    ("car_door", car_door, 0.85),
    ("car_engine_start", car_engine_start, 0.85),
    ("car_drive_loop", car_drive_loop, 0.75),
    ("ending_music", ending_music, 0.8),
]

if __name__ == "__main__":
    only = set(sys.argv[2:])
    for name, make, level in SOUNDS:
        if only and name not in only:
            continue
        save(name, make(), level, DRIVE.get(name))
    # schon vorhandene Sounds (aus assets/audio), die Kapitel 3 auch braucht: mit in den
    # Ordner kopieren, damit man alles auf einmal hochladen kann
    here = os.path.dirname(os.path.abspath(__file__))
    source = os.path.join(here, "..", "assets", "audio")
    for existing in ["beast_roar", "beast_step", "beast_breath_loop", "heartbeat_loop", "door_creak", "door_slam"]:
        path = os.path.join(source, existing + ".ogg")
        if os.path.exists(path) and not only:
            shutil.copy(path, os.path.join(OUT, existing + ".ogg"))
            print(f"{existing}.ogg  (kopiert)")
