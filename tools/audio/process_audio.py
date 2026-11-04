#!/usr/bin/env python3
'''Convert a raw candidate into a Godot-ready WAV using FFmpeg.'''

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
from pathlib import Path


def _find_media_tool(name: str) -> str | None:
    direct = shutil.which(name)
    if direct:
        return direct
    local_app_data = os.environ.get("LOCALAPPDATA")
    if not local_app_data:
        return None
    packages = Path(local_app_data) / "Microsoft" / "WinGet" / "Packages"
    for candidate in packages.glob(f"Gyan.FFmpeg_*/*/bin/{name}.exe"):
        if candidate.is_file():
            return str(candidate)
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--target-lufs", type=float, default=-16.0)
    args = parser.parse_args()

    if not args.source.is_file():
        parser.error(f"Source file not found: {args.source}")
    if args.output.suffix.lower() != ".wav":
        parser.error("Output must be a .wav file")
    ffmpeg = _find_media_tool("ffmpeg")
    if not ffmpeg:
        parser.error("FFmpeg is required; install it and reopen the terminal")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    filters = (
        "silenceremove=start_periods=1:start_duration=0.03:start_threshold=-45dB,"
        "areverse,"
        "silenceremove=start_periods=1:start_duration=0.03:start_threshold=-45dB,"
        "afade=t=in:st=0:d=0.015,"
        "areverse,"
        "afade=t=in:st=0:d=0.005,"
        f"loudnorm=I={args.target_lufs}:TP=-1.5:LRA=7"
    )
    command = [
        ffmpeg, "-y", "-v", "error", "-i", str(args.source), "-af", filters,
        "-ar", "44100", "-ac", "2", "-c:a", "pcm_s16le", str(args.output),
    ]
    result = subprocess.run(command, check=False, text=True, capture_output=True)
    if result.returncode:
        print(result.stderr.strip(), flush=True)
        return result.returncode
    print(f"Processed: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
