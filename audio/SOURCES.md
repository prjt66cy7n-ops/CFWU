# Audio source credits and licences

The game bundles these edited files for offline playback. The original sound
creators retain authorship. Replacements are external sourced audio, not the
previous synthesized noise. Source copies are retained in `audio/sources/`.

## Recorded chewing

**“Chewing carrot” — InspectorJ**, Freesound 412068.
Original: https://freesound.org/people/InspectorJ/sounds/412068/
Licence: Creative Commons Attribution 3.0 Unported (CC BY 3.0):
https://creativecommons.org/licenses/by/3.0/
Retrieved mirror and explicit credit/licence statement:
https://github.com/mit-mit-randomprojectlab/pyweek27_chimera/tree/51a60f8c737bd28f133de5a6c92c6923a53bf2f0
File: `data/snd/eating.ogg`; attribution in the repository's README.md.
Changes: edited excerpts, high-pass filtering, mixing with eating-crunch clips,
level limiting, short fades, mono 44.1 kHz PCM conversion. Four food variants
use this real mastication recording; they are not four separate food recordings.
The creator, title and licence are also credited in the app's Sound settings.

## Eating crunches

**“7 Eating Crunches” — StarNinjas**, CC0 1.0 public domain.
Licence: https://creativecommons.org/publicdomain/zero/1.0/
Retrieved files and explicit per-asset licence statement:
https://github.com/ana0/feed/tree/2d24cdf841e6727f5948c214d3237c57b674f4be
Files: `public/crunch1.wav` through `public/crunch4.wav`; README.md credits
“7 Eating Crunches” by StarNinjas in its CC0 asset table.
Changes: levels, mixing into the four food variants, fades, PCM conversion.

## Flowing water

**“Water Flowing”, from “30 SFX loops” — rubberduck**, CC0 1.0 public domain.
Original pack: https://opengameart.org/content/30-cc0-sfx-loops
Licence: https://creativecommons.org/publicdomain/zero/1.0/
Retrieved file and explicit pack licence/attribution manifest:
https://github.com/novincode/atomcut-library/tree/391f87ff50bdad7645f9007708fef8ff07c8a00a/packs/opengameart-30-cc0-sfx-loops
File: `audio/water-flowing.m4a`, originally `sfx-loops/water_flowing.ogg`.
Changes: mono 44.1 kHz PCM conversion. Playback loops continuously during
water flow and stops when filling stops. The source labels this as a nature
water loop; no claim is made about its original recording method.

Regenerate the five bundled files with `python scripts/generate-eating-audio.py`
(requires ffmpeg). No asset download or internet connection is used by the app.
