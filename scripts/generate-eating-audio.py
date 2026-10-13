"""Prepare licensed source recordings/effects; requires ffmpeg, no downloads.
Original source clips and licence/provenance are retained under audio/.
All four food variants contain recorded carrot mastication plus eating crunches.
"""
from pathlib import Path
import subprocess
ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'audio' / 'sources'
DEST = ROOT / 'YourFarmWithUnicorns' / 'Resources'
for number, (food, start, bite_volume, chew_volume) in enumerate([
    ('carrot', 0.05, 0.55, 1.0), ('apple', 0.30, 0.50, 0.90),
    ('liquorice', 0.65, 0.25, 0.90), ('hay', 0.15, 0.40, 0.85)
], start=1):
    filters = (f'[0:a]atrim=start={start}:duration=3.4,asetpts=PTS-STARTPTS,highpass=f=65,volume={chew_volume}[chew];'
               f'[1:a]volume={bite_volume}[bite];'
               '[chew][bite]amix=inputs=2:duration=first:normalize=0,'
               'alimiter=limit=0.85:level=0,afade=t=in:d=0.008,afade=t=out:st=3.25:d=0.15[out]')
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', str(SOURCES / 'inspectorj-chewing-carrot.ogg'),
                    '-i', str(SOURCES / f'starninjas-crunch{number}.wav'), '-filter_complex', filters,
                    '-map', '[out]', '-ar', '44100', '-ac', '1', '-c:a', 'pcm_s16le',
                    str(DEST / f'sfx-crunch-{food}.wav')], check=True)
subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', str(SOURCES / 'rubberduck-water-flowing.m4a'),
                '-ar', '44100', '-ac', '1', '-c:a', 'pcm_s16le', str(DEST / 'sfx-water.wav')], check=True)
print('Prepared four recorded chewing/crunch variants and a licensed flowing-water loop.')
