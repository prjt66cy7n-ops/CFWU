"""Generate original draft instrumental music and feedback sounds; no external samples."""
from pathlib import Path
import math, random, struct, wave
ROOT = Path(__file__).resolve().parents[1] / 'YourFarmWithUnicorns' / 'Resources'
RATE = 22050
ROOT.mkdir(exist_ok=True)
def write(name, seconds, sample):
    data = bytearray()
    for index in range(int(seconds * RATE)):
        value = max(-0.9, min(0.9, sample(index / RATE)))
        data.extend(struct.pack('<h', int(value * 32767)))
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as output:
        output.setnchannels(1); output.setsampwidth(2); output.setframerate(RATE); output.writeframes(data)
def hz(note): return 440 * 2 ** ((note - 69) / 12)
patterns = {
    'farm': [60, 64, 67, 64, 69, 67, 62, 67],
    'stables': [60, 67, 64, 62, 60, 64, 69, 67],
    'washBay': [62, 66, 69, 66, 71, 69, 64, 62],
    'arena': [64, 67, 71, 67, 74, 71, 67, 64],
    'roundYard': [60, 62, 64, 67, 69, 67, 64, 62],
    'paddock': [55, 59, 62, 59, 64, 62, 57, 55],
    'chickenCoop': [67, 71, 74, 71, 76, 74, 69, 67],
    'farmhouse': [60, 64, 65, 69, 67, 64, 62, 60],
    'flight': [60, 64, 67, 72, 76, 74, 72, 79]
}
for scene, notes in patterns.items():
    duration = 38 if scene == 'flight' else 16
    beat = 1 if scene == 'flight' else 2
    def sample(t, notes=notes, scene=scene, duration=duration, beat=beat):
        i = int(t / beat) % len(notes); age = t % beat
        freq = hz(notes[i]); volume = 0.055 if scene != 'flight' else 0.045 + 0.035 * min(1, t / 35)
        melody = math.sin(2 * math.pi * freq * t) + 0.22 * math.sin(4 * math.pi * freq * t)
        pluck = (1 - math.exp(-age * 45)) * math.exp(-age * 2.8)
        pad = 0.025 * sum(math.sin(2 * math.pi * hz(notes[0] - 12 + n) * t) for n in [0, 4, 7])
        if scene == 'flight':
            strings = sum(math.sin(2 * math.pi * freq * k * t) / (k * k) for k in range(1, 5))
            melody = 0.5 * melody + 0.5 * strings
        fade = min(1, t / 0.4, (duration - t) / 0.4)
        return (volume * melody * pluck + pad) * fade
    write('music-' + scene, duration, sample)
for name, pitches in [('wand', [72, 76, 79, 84]), ('magic', [79, 84]), ('ribbon', [60, 64, 67, 72, 76, 79])]:
    def sample(t, pitches=pitches):
        value = 0
        for i, note in enumerate(pitches):
            age = t - i * 0.09
            if age >= 0:
                value += 0.1 * (1 - math.exp(-age * 100)) * math.exp(-age * 6) * math.sin(2 * math.pi * hz(note) * age)
        return value
    write('sfx-' + name, 1.2, sample)
write('sfx-pick', 0.15, lambda t: 0.2 * math.exp(-t * 55) * math.sin(2 * math.pi * 900 * t))
write('sfx-chicken', 0.4, lambda t: 0.13 * math.sin(2 * math.pi * (1000 * t - 500 * t * t)) * math.exp(-t * 8) * (0.5 + 0.5 * math.sin(t * 80)))
rng = random.Random(66)
write('sfx-water', 0.55, lambda t: 0.04 * (rng.random() * 2 - 1) + 0.04 * math.sin(t * 2200) * math.exp(-t * 4))
for i in range(1, 4):
    write('sfx-horse-' + str(i), 0.65, lambda t, i=i: 0.11 * math.sin(2 * math.pi * ((280 + i * 50) * t + 90 * t * t)) * math.sin(t * 25) ** 2 * math.exp(-t * 3))
write('sfx-horse-fart', 0.3, lambda t: 0.14 * math.sin(t * 2 * math.pi * 65) * (0.5 + 0.5 * math.sin(t * 170)) * math.exp(-t * 10))
print('Generated 9 original instrumental music tracks and 10 synthetic feedback/animal clips.')

# Food-specific original crunch/chew textures, kept reproducible with fixed seeds.
for food_index, food_name in enumerate(['carrot', 'apple', 'liquorice', 'hay']):
    eating_rng = random.Random(660 + food_index)
    previous_noise = [0.0]
    def crunch(t, index=food_index, rng=eating_rng, previous=previous_noise):
        age = t % 0.28
        envelope = math.exp(-age * (23 if index == 0 else 16)) * (1 - math.exp(-age * 400))
        noise = rng.uniform(-1, 1); high = noise - previous[0]; previous[0] = noise
        frequency = [2600, 950, 450, 3400][index]
        sound = 0.28 * high + 0.1 * math.sin(t * 2 * math.pi * frequency)
        if index == 1: sound = 0.22 * noise + 0.15 * math.sin(2 * math.pi * 380 * t) * math.exp(-age * 8)
        if index == 2: sound = 0.12 * noise + 0.14 * math.sin(2 * math.pi * frequency * t) * (0.5 + 0.5 * math.sin(110 * t))
        if index == 3: sound = 0.22 * high * (0.6 + 0.4 * math.sin(260 * t))
        return sound * envelope
    write('sfx-crunch-' + food_name, 1.25, crunch)
print('Generated four food-specific eating clips.')
