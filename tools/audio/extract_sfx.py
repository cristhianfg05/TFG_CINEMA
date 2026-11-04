#!/usr/bin/env python3
"""Extract the most active short moment from a processed PCM WAV candidate.

Stable Audio may place a single requested event midway through its output. This
keeps the model-generated event while producing a short, click-free gameplay SFX.
"""

from __future__ import annotations

import argparse
import sys
import wave
from array import array
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--seconds", type=float, required=True)
    parser.add_argument("--peak-focus", action="store_true", help="Keep a brief transient near the clip start.")
    args = parser.parse_args()
    if args.seconds <= 0:
        parser.error("--seconds must be positive")
    with wave.open(str(args.source), "rb") as source:
        channels, width, rate = source.getnchannels(), source.getsampwidth(), source.getframerate()
        if (channels, width, rate) != (2, 2, 44100):
            parser.error("source must be stereo 16-bit PCM at 44100 Hz")
        samples = array("h")
        samples.frombytes(source.readframes(source.getnframes()))
    if sys.byteorder != "little":
        samples.byteswap()

    frames = len(samples) // 2
    window = min(frames, round(args.seconds * rate))
    if window == 0:
        parser.error("source contains no audio")
    if args.peak_focus:
        peak_frame = max(
            range(frames),
            key=lambda frame: max(abs(samples[2 * frame]), abs(samples[2 * frame + 1])),
        )
        start = max(0, min(peak_frame - round(0.04 * rate), frames - window))
    else:
        # Search on a 10 ms grid to avoid allocating a full-resolution prefix sum.
        block = 441
        energies = [
            sum(abs(samples[2 * frame]) + abs(samples[2 * frame + 1])
                for frame in range(begin, min(begin + block, frames)))
            for begin in range(0, frames, block)
        ]
        prefix = [0]
        for energy in energies:
            prefix.append(prefix[-1] + energy)
        blocks_per_window = max(1, (window + block - 1) // block)
        best_block = max(
            range(max(1, len(energies) - blocks_per_window + 1)),
            key=lambda index: prefix[min(index + blocks_per_window, len(energies))] - prefix[index],
        )
        start = min(best_block * block, frames - window)
        start = max(0, start - round(0.015 * rate))
    end = start + window
    if end > frames:
        end = frames
        start = max(0, end - window)
    clip = samples[2 * start:2 * end]
    fade_in = min(round(0.005 * rate), window // 3)
    fade_out = min(round(0.018 * rate), window // 3)
    for frame in range(window):
        gain = 1.0
        if frame < fade_in:
            gain = min(gain, frame / max(1, fade_in))
        if frame >= window - fade_out:
            gain = min(gain, (window - 1 - frame) / max(1, fade_out))
        clip[2 * frame] = round(clip[2 * frame] * gain)
        clip[2 * frame + 1] = round(clip[2 * frame + 1] * gain)
    if sys.byteorder != "little":
        clip.byteswap()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(args.output), "wb") as output:
        output.setparams((2, 2, rate, 0, "NONE", "not compressed"))
        output.writeframes(clip.tobytes())
    print(f"Extracted {window / rate:.3f}s from {start / rate:.3f}s: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
