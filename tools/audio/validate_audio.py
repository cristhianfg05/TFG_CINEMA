#!/usr/bin/env python3
"""Validate Godot-ready PCM WAV files for format, length, silence and clipping."""

from __future__ import annotations

import argparse
import struct
import wave
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path)
    parser.add_argument("--min-seconds", type=float, default=0.03)
    parser.add_argument("--max-seconds", type=float, default=120.0)
    args = parser.parse_args()
    failures: list[str] = []

    if not args.file.is_file():
        parser.error(f"File not found: {args.file}")
    if args.file.suffix.lower() != ".wav":
        failures.append("file is not WAV")

    try:
        with wave.open(str(args.file), "rb") as stream:
            channels = stream.getnchannels()
            sample_width = stream.getsampwidth()
            sample_rate = stream.getframerate()
            frame_count = stream.getnframes()
            frames = stream.readframes(frame_count)
    except (wave.Error, OSError) as error:
        print(f"INVALID: unreadable WAV ({error})")
        return 1

    duration = frame_count / sample_rate if sample_rate else 0.0
    if channels != 2:
        failures.append(f"expected stereo, got {channels} channel(s)")
    if sample_width != 2:
        failures.append(f"expected 16-bit PCM, got {sample_width * 8}-bit")
    if sample_rate != 44100:
        failures.append(f"expected 44100 Hz, got {sample_rate} Hz")
    if not args.min_seconds <= duration <= args.max_seconds:
        failures.append(f"duration {duration:.3f}s outside {args.min_seconds:.3f}-{args.max_seconds:.3f}s")

    samples = struct.unpack("<%dh" % (len(frames) // 2), frames) if frames else ()
    peak = max((abs(sample) for sample in samples), default=0)
    if peak == 0:
        failures.append("file is silent")
    if peak >= 32700:
        failures.append(f"possible clipping (peak {peak}/32767)")

    if failures:
        print("INVALID:")
        for failure in failures:
            print(f"- {failure}")
        return 1
    print(f"VALID: {args.file} | {duration:.3f}s | stereo 44.1 kHz PCM16 | peak {peak}/32767")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
