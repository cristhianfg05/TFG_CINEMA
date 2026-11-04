---
name: cinema-audio-sfx
description: Genera y prepara efectos de sonido locales para CinemaCleaner con Stable Audio 3 Small-SFX.
---

# SFX de CinemaCleaner

1. Lee `docs/pipeline/AUDIO_BIBLE.md`, `AUDIO_PIPELINE.md` y la auditoría actual.
2. Comprueba si la familia ya tiene variantes aprobadas en `assets/audio/` antes de generar otras.
3. Genera solo la cantidad solicitada con `tools/audio/generate_audio.py sfx`; guarda el bruto en `audio_source/raw/sfx/`.
4. Procesa cada candidato con `process_audio.py` y valida con `validate_audio.py`.
5. Escucha o inspecciona los resultados. Descarta clips estridentes, confusos, cansinos o con artefactos.
6. Conserva candidatos y resultados; no sustituye referencias de Godot ni borra audio legacy. Para integrar, usa `cinema-audio-integrate`.
