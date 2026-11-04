# Cartoon lever spark selection (2026-09-27)

The player approved **03**. Its 0.250-second, -14.6 dBFS preview is preserved
at `audio_source/generated/sfx/machines/manager_lever_cartoon_spark_v2_03.wav`
and copied unchanged to
`assets/audio/sfx/machines/manager_lever_cartoon_spark_03.wav`. SHA-256 of
both is `165790D651250C939365C06EA10933EBCC615A364CE30306E2FDB24FBED3B1F2`.
The source generation is
`audio_source/raw/sfx/machines/manager_lever_cartoon_spark_v2_02.wav`
(Stable Audio 3 Small-SFX, seed 927202, 4 seconds, CFG 3.0); the chosen
event occupies its first 0.25 seconds.

The rejected 01/02 preview WAVs and their shared raw 01 generation were
removed at the player's request. A third raw generation, raw 03 (seed 927203),
was never offered because it contained sustained noise; it remains only in
`audio_source/raw/sfx/machines/` for audit. The earlier
`manager_lever_spark_candidate_*` set was also rejected and removed.

The approved event uses 5 ms entry and 20 ms exit fades, with no frequency
filtering or synthetic layer. `process_audio.py` was tested on the crop but
trimmed its natural decay to about 0.05 seconds, so the final WAV instead
preserves the 0.25-second crop and uses FFmpeg `loudnorm` and -13 dB finishing
gain. `validate_audio.py --max-seconds 0.5` passed on both the preview and
production copy: stereo 44.1 kHz PCM16, non-silent, no clipping. Four exact
simultaneous copies mixed at -2.6 dBFS peak before spatial attenuation.

`ManagerLeverBox` has one 3D `Machines` voice per lever, each using the same
approved stream with a subtle 0.98–1.02 pitch variation. Its busy state is
per-lever, so rapid activations may overlap without cutting off one another.
Godot headless import, `cinema_room_audio_smoke.gd`,
`manager_lever_overlap_smoke.gd`, and `manager_lever_import_smoke.gd` passed.
