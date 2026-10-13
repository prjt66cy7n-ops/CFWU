"""Reproducible original eating Foley-style effects, without pitched oscillators.

Layer brittle bite fragments over irregular, band-limited chewing/grinding noise.
These are synthesized effects, not recordings of a person or animal.
Run independently to leave music and other effects unchanged.
"""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / 'YourFarmWithUnicorns' / 'Resources'
RATE = 44100
DURATION = 3.1


def eating(food, seed):
    rng = random.Random(seed)
    samples = [0.0] * int(RATE * DURATION)
    # Crunchiness, dry grind and mouth-body mix vary with the food.
    crack, grit, mouth = {
        'carrot': (1.0, 0.52, 0.24),
        'apple': (0.8, 0.40, 0.42),
        'liquorice': (0.28, 0.44, 0.48),
        'hay': (0.60, 0.78, 0.15),
    }[food]

    def grain(start, duration, gain, texture, attack=0.004):
        first = int(start * RATE)
        count = int(duration * RATE)
        slow = fast = body = 0.0
        for i in range(count):
            if first + i >= len(samples):
                break
            t = i / RATE
            noise = rng.uniform(-1, 1)
            # Several damped broadband bands, without a sine-wave pitch.
            slow += 0.055 * (noise - slow)
            fast += 0.42 * (noise - fast)
            body += 0.014 * (noise - body)
            if texture == 'snap':
                value = (noise - fast) * 0.60 + (fast - slow) * 1.4
                envelope = min(1, t / attack) * math.exp(-t * 5 / duration)
            elif texture == 'grind':
                value = (fast - slow) * 2.8 + slow * 0.65
                envelope = min(1, t / attack) * math.sin(math.pi * i / count) ** 1.4
            else:
                value = slow * 2.3 + body * 2.5
                envelope = min(1, t / attack) * math.sin(math.pi * i / count) ** 1.5
            samples[first + i] += value * gain * envelope

    # A first bite fractures into many tiny, differently timed cracks.
    for i in range(23):
        onset = 0.025 + rng.random() ** 1.5 * 0.24
        grain(onset, rng.uniform(0.008, 0.035), crack * rng.uniform(0.09, 0.27), 'snap', 0.0004)
    grain(0.04, 0.27, 0.32 * grit, 'grind')
    grain(0.075, 0.22, 0.28 * mouth, 'mouth', 0.012)

    # Uneven jaw strokes: rough pressure, brief cracks, softer mouth release.
    onset = 0.39
    while onset < DURATION - 0.36:
        length = rng.uniform(0.19, 0.31)
        gain = rng.uniform(0.8, 1.15)
        grain(onset, length, grit * 0.29 * gain, 'grind', 0.015)
        grain(onset + 0.055, length + 0.035, mouth * 0.33 * gain, 'mouth', 0.02)
        for _ in range(rng.randint(5, 10)):
            grain(onset + rng.random() * length, rng.uniform(0.006, 0.026),
                  crack * rng.uniform(0.035, 0.13) * gain, 'snap', 0.0006)
        onset += rng.uniform(0.37, 0.49)

    peak = max(abs(s) for s in samples)
    scale = 0.83 / peak
    data = bytearray()
    for i, sample in enumerate(samples):
        # Fade both edges; peak-normalize without clipping transient fragments.
        edge = min(1, i / (RATE * 0.012), (len(samples) - 1 - i) / (RATE * 0.07))
        data.extend(struct.pack('<h', round(sample * scale * edge * 32767)))
    ROOT.mkdir(exist_ok=True)
    with wave.open(str(ROOT / f'sfx-crunch-{food}.wav'), 'wb') as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(data)


for seed, food in enumerate(('carrot', 'apple', 'liquorice', 'hay'), start=6660):
    eating(food, seed)
print('Generated four 3.1-second bite, chew and grinding effects at 44.1 kHz.')
