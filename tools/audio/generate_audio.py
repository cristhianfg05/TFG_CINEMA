#!/usr/bin/env python3
"""Run only the approved local Stable Audio 3 Small models into audio_source/raw."""

from __future__ import annotations

import argparse
import os
import subprocess
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUNTIME = Path(r"C:\Users\crist\.codex\tools\stable-audio-3\optimized\tflite")
RUNTIME_ROOT = Path(os.environ.get("CINEMA_STABLE_AUDIO_HOME", DEFAULT_RUNTIME))
MODEL_BY_FAMILY = {"sfx": "sm-sfx", "music": "sm-music"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("family", choices=MODEL_BY_FAMILY, help="Approved audio family.")
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--seconds", type=float, default=8.0)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", type=int)
    parser.add_argument("--threads", type=int, default=8)
    parser.add_argument("--steps", type=int, default=8, help="Sampling steps; raise for difficult short tonal effects.")
    parser.add_argument("--cfg", type=float, default=1.0, help="Optional Stable Audio prompt guidance (default: 1.0).")
    parser.add_argument("--negative-prompt", help="Optional sounds to steer away from when CFG is enabled.")
    args = parser.parse_args()

    output = args.output.resolve()
    raw_root = (PROJECT_ROOT / "audio_source" / "raw").resolve()
    if raw_root not in output.parents:
        parser.error("--output must stay under audio_source/raw/")
    if args.seconds <= 0 or args.seconds > 120:
        parser.error("--seconds must be between 0 and 120")
    if not 1.0 <= args.cfg <= 10.0:
        parser.error("--cfg must be between 1.0 and 10.0")
    if not 1 <= args.steps <= 64:
        parser.error("--steps must be between 1 and 64")
    if args.negative_prompt and args.cfg == 1.0:
        parser.error("--negative-prompt requires --cfg above 1.0")

    python = RUNTIME_ROOT / ".venv" / "Scripts" / "python.exe"
    cli = RUNTIME_ROOT / "scripts" / "sa3_tflite.py"
    if not python.is_file() or not cli.is_file():
        parser.error("Stable Audio runtime is unavailable; see docs/pipeline/AUDIO_PIPELINE.md")

    output.parent.mkdir(parents=True, exist_ok=True)
    command = [
        str(python), str(cli), "--prompt", args.prompt,
        "--dit", MODEL_BY_FAMILY[args.family], "--decoder", "same-s",
        "--seconds", str(args.seconds), "--threads", str(args.threads), "--out", str(output),
        "--steps", str(args.steps),
    ]
    if args.seed is not None:
        command.extend(["--seed", str(args.seed)])
    if args.cfg != 1.0:
        command.extend(["--cfg", str(args.cfg)])
    if args.negative_prompt:
        command.extend(["--negative-prompt", args.negative_prompt])
    return subprocess.run(command, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
