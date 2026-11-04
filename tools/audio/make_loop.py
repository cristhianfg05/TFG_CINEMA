#!/usr/bin/env python3
"""Make a PCM16 stereo music candidate wrap without a click or abrupt cut."""

from __future__ import annotations

import argparse
import math
import struct
import wave
from array import array
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--crossfade-seconds", type=float, default=0.75)
    args = parser.parse_args()

    with wave.open(str(args.source), "rb") as stream:
        channels = stream.getnchannels()
        rate = stream.getframerate()
        width = stream.getsampwidth()
        frames = stream.getnframes()
        data = stream.readframes(frames)
    if channels != 2 or width != 2 or rate != 44100:
        parser.error("source must be stereo 44.1 kHz PCM16")
    overlap = round(args.crossfade_seconds * rate)
    if overlap < 1 or frames <= overlap * 3:
        parser.error("crossfade must fit comfortably within the source")

    samples = struct.unpack(f"<{frames * channels}h", data)
    # Shift the splice a few milliseconds to a quiet waveform transition.
    search = round(0.02 * rate)
    overlap = min(
        range(max(1, overlap - search), min(frames // 3, overlap + search) + 1),
        key=lambda frame: sum(
            abs(samples[frame * channels + channel] - samples[(frame - 1) * channels + channel])
            for channel in range(channels)
        ),
    )
    body = list(samples[overlap * channels : (frames - overlap) * channels])
    for frame in range(overlap):
        weight = 0.5 - 0.5 * math.cos(math.pi * (frame + 1) / overlap)
        for channel in range(channels):
            tail = samples[((frames - overlap) + frame) * channels + channel]
            head = samples[frame * channels + channel]
            body.append(max(-32768, min(32767, round(tail * (1.0 - weight) + head * weight))))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(args.output), "wb") as stream:
        stream.setnchannels(channels)
        stream.setsampwidth(width)
        stream.setframerate(rate)
        stream.writeframes(array("h", body).tobytes())
    print(f"Loop-ready: {args.output} | {len(body) // channels / rate:.3f}s | {overlap / rate:.3f}s seam")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
