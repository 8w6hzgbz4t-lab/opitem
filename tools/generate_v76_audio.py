"""Synthesize an original loop and UI/gameplay effects; no sampled/copyrighted material.

The score is composed here at 148 BPM in E minor, with changing synth/arp/drum
layers and original note phrases. Circular delay tails make its 32 bars loop.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import subprocess
import wave
from pathlib import Path
import numpy as np

RATE = 44100
RNG = np.random.default_rng(760148)


def frequency(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def tone(midi, seconds, kind='lead', gain=1):
    n = max(2, round(seconds * RATE))
    t = np.arange(n) / RATE
    f = frequency(midi)
    phase = 2 * np.pi * f * t
    if kind == 'bass':
        x = np.sin(phase) + .22 * np.sin(phase * 2) + .12 * np.sin(phase * 3)
    elif kind == 'bell':
        x = np.sin(phase + 1.5 * np.exp(-t * 7) * np.sin(phase * 2))
    elif kind == 'pad':
        x = sum(np.sin(phase * (1 + detune)) for detune in (-.003, 0, .003)) / 3
    else:
        x = sum(np.sin(phase * k) / k ** 1.55 for k in range(1, 8)) / 1.5
        x += .12 * np.sin(phase * 1.003)
    attack = .004 if kind == 'bass' else .012 if kind != 'pad' else .1
    release = min(.12 if kind != 'pad' else .3, seconds * .45)
    env = np.minimum(t / attack, 1) * np.minimum((seconds - t) / release, 1)
    if kind == 'bell':
        env *= np.exp(-t * 3)
    return x * np.maximum(env, 0) * gain


def drum(kind):
    seconds = {'kick': .28, 'snare': .18, 'hat': .07}[kind]
    t = np.arange(round(seconds * RATE)) / RATE
    noise = RNG.standard_normal(len(t))
    if kind == 'kick':
        phase = 2 * np.pi * (43 * t + 65 * (1 - np.exp(-t * 28)) / 28)
        x = np.sin(phase) * np.exp(-t * 15) + .07 * noise * np.exp(-t * 120)
    elif kind == 'snare':
        high = noise - np.roll(noise, 1)
        x = .24 * high * np.exp(-t * 24) + .25 * np.sin(2 * np.pi * 185 * t) * np.exp(-t * 28)
    else:
        x = (noise - np.roll(noise, 1)) * np.exp(-t * 70) * .1
    return x * np.minimum(t / .001, 1)


def mix(target, signal, when, gain=1, pan=0, circular=False):
    start = round(when * RATE)
    left = np.sqrt((1 - pan) / 2)
    right = np.sqrt((1 + pan) / 2)
    stereo = np.column_stack((signal * left, signal * right)) * gain
    if circular:
        for offset in range(0, len(stereo), len(target)):
            piece = stereo[offset:offset + len(target)]
            pos = (start + offset) % len(target)
            take = min(len(piece), len(target) - pos)
            target[pos:pos + take] += piece[:take]
            if take < len(piece):
                target[:len(piece) - take] += piece[take:]
    elif start < len(target):
        take = min(len(stereo), len(target) - start)
        target[start:start + take] += stereo[:take]


def master(x):
    x = np.tanh(x * 1.15)
    peak = float(np.max(np.abs(x)))
    if peak:
        x *= .88 / peak
    return x


def write_wav(path, x):
    with wave.open(str(path), 'wb') as file:
        file.setnchannels(2)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes((x * 32767).astype('<i2').tobytes())


def music():
    beat = 60 / 148
    x = np.zeros((round(32 * 4 * beat * RATE), 2), dtype=np.float64)
    # E minor / C / A minor / B tension; a self-composed syncopated eight-bar phrase.
    roots = [40, 40, 36, 38, 33, 36, 35, 35]
    chords = [(64, 67, 71), (64, 67, 74), (60, 64, 67), (62, 66, 69),
              (57, 60, 64), (60, 64, 67), (59, 63, 66), (59, 63, 69)]
    phrases = [
        [76, 0, 79, 78, 76, 0, 71, 74, 76, 0, 83, 81, 79, 78, 74, 0],
        [76, 0, 74, 71, 67, 0, 71, 74, 78, 0, 79, 78, 74, 71, 74, 0],
        [76, 0, 79, 0, 84, 83, 79, 76, 79, 0, 83, 81, 79, 76, 74, 0],
        [78, 0, 81, 78, 74, 0, 69, 74, 78, 0, 81, 83, 81, 78, 74, 0],
        [76, 0, 72, 0, 69, 72, 76, 79, 81, 0, 79, 76, 72, 0, 71, 0],
        [79, 0, 76, 72, 67, 0, 72, 76, 79, 0, 84, 83, 79, 76, 72, 0],
        [78, 0, 75, 71, 66, 0, 71, 75, 78, 0, 81, 78, 75, 71, 70, 0],
        [71, 0, 75, 78, 81, 0, 83, 81, 78, 75, 71, 70, 71, 74, 75, 78],
    ]
    kick, snare, hat = (drum(k) for k in ('kick', 'snare', 'hat'))
    for bar in range(32):
        start = bar * beat * 4
        section = bar // 8
        progression = bar % 8
        chord = chords[progression]
        for midi in chord:
            mix(x, tone(midi - 12, beat * 4.3, 'pad', .032), start, pan=(midi % 3 - 1) * .5, circular=True)
        for step in range(8):
            mix(x, tone(roots[progression] + (12 if step in (3, 7) else 0), beat * .39, 'bass', .24), start + step * beat / 2, circular=True)
            mix(x, hat, start + step * beat / 2, .54 if step % 2 else .8, pan=.3 if step % 2 else -.3, circular=True)
        for tick in (0, 1.5, 2, 3.5):
            mix(x, kick, start + tick * beat, .52, circular=True)
        for tick in (1, 3):
            mix(x, snare, start + tick * beat, .47, pan=-.08, circular=True)
        for step, note in enumerate(phrases[progression]):
            if note and (section != 0 or step % 2 == 0 or bar >= 4):
                mix(x, tone(note, beat * .235, 'lead', .11 if section != 2 else .075),
                    start + step * beat / 4, pan=-.12, circular=True)
        if section in (1, 2, 3):
            for step in range(16):
                note = chord[step % 3] + (12 if step % 4 == 3 else 0)
                mix(x, tone(note, beat * .22, 'bell', .055), start + step * beat / 4, pan=.5, circular=True)
        if bar % 8 == 7:
            for step in range(4):
                mix(x, snare, start + (3 + step / 4) * beat, .18 + step * .04, circular=True)
    x += np.roll(x, round(beat * .75 * RATE), axis=0) * .12
    x += np.roll(x[:, ::-1], round(beat * 1.5 * RATE), axis=0) * .06
    # A 10 ms smooth endpoint correction avoids a click at the loop seam.
    ramp = np.linspace(0, 1, round(.01 * RATE))
    ramp = ramp * ramp * (3 - 2 * ramp)
    x[-len(ramp):] += np.outer(ramp, x[0] - x[-1])
    return master(x)


def effect(name):
    definitions = {
        'purchase': [(76, 0, .11), (79, .09, .11), (83, .18, .22)],
        'delivered': [(64, 0, .15), (71, .1, .15), (76, .2, .32), (83, .25, .25)],
        'level-up': [(64, 0, .18), (67, .08, .18), (71, .16, .18), (76, .24, .22), (83, .36, .48)],
        'base-lock': [(48, 0, .13), (60, .06, .13), (67, .14, .24)],
        'base-unlock': [(67, 0, .13), (60, .1, .13), (48, .2, .24)],
        'item-lost': [(67, 0, .13), (61, .09, .13), (52, .18, .32)],
        'shield': [(64, 0, .35), (71, .02, .32), (83, .05, .42)],
        'power-cast': [(52, 0, .12), (64, .05, .16), (76, .1, .22)],
        'power-hit': [(40, 0, .24), (52, .02, .2), (59, .04, .15)],
        'ui-tick': [(88, 0, .055)],
    }
    notes = definitions[name]
    seconds = max(when + duration for _, when, duration in notes) + .12
    x = np.zeros((round(seconds * RATE), 2))
    for note, when, duration in notes:
        mix(x, tone(note, duration, 'bell', .35), when)
    if name in ('power-hit', 'base-lock', 'item-lost'):
        mix(x, drum('kick'), 0, .3)
    if name == 'power-cast':
        mix(x, drum('hat'), 0, .8)
    return master(x)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, default=Path('releases/Version76/Audio'))
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    track = music()
    temporary = args.out / '.relic-rivalry.wav'
    write_wav(temporary, track)
    target = args.out / 'relic-rivalry-loop.ogg'
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(temporary), '-c:a', 'libvorbis', '-q:a', '6',
                    '-metadata', 'title=Relic Rivalry', '-metadata', 'comment=Original procedural score for Steal An OP Item', str(target)], check=True)
    temporary.unlink()
    decoded_bytes = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(target), '-f', 'f32le',
                                    '-acodec', 'pcm_f32le', 'pipe:1'], check=True, capture_output=True).stdout
    decoded = np.frombuffer(decoded_bytes, dtype='<f4').reshape(-1, 2)
    effects = ['power-cast', 'power-hit', 'shield', 'purchase', 'item-lost', 'delivered',
               'base-lock', 'base-unlock', 'level-up', 'ui-tick']
    metrics = {}
    for name in effects:
        signal = effect(name)
        write_wav(args.out / (name + '.wav'), signal)
        metrics[name] = {'seconds': len(signal) / RATE, 'peak': float(np.max(np.abs(signal))),
                         'rms': float(np.sqrt(np.mean(signal ** 2)))}
    report = {'original_composition': True, 'sampled_audio': False, 'tempo_bpm': 148, 'bars': 32,
              'sample_rate': RATE, 'music_seconds': len(track) / RATE,
              'music_peak': float(np.max(np.abs(track))), 'music_rms': float(np.sqrt(np.mean(track ** 2))),
              'music_loop_boundary_jump': float(np.max(np.abs(track[0] - track[-1]))),
              'decoded_ogg': {'samples': len(decoded), 'seconds': len(decoded) / RATE,
                              'peak': float(np.max(np.abs(decoded))),
                              'rms': float(np.sqrt(np.mean(decoded ** 2))),
                              'loop_boundary_jump': float(np.max(np.abs(decoded[0] - decoded[-1]))),
                              'all_finite': bool(np.all(np.isfinite(decoded)))},
              'effects': metrics, 'asset_ids_configured': False,
              'generator_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              'files': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(args.out.iterdir()) if p.suffix in ('.wav', '.ogg')}}
    assert report['music_peak'] < .9 and report['music_rms'] > .08
    assert report['music_loop_boundary_jump'] < .04
    assert report['decoded_ogg']['all_finite'] and report['decoded_ogg']['peak'] < 1
    assert report['decoded_ogg']['loop_boundary_jump'] < .04 and len(decoded) == len(track)
    assert all(.01 < item['rms'] < .7 and item['peak'] < .9 for item in metrics.values())
    (args.out / 'audio-metrics.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f"Created original {report['music_seconds']:.2f}s loop and {len(effects)} effects; no clipping; loop delta {report['music_loop_boundary_jump']:.5f}")


if __name__ == '__main__':
    main()
