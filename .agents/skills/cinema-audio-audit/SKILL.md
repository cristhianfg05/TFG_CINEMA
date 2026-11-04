---
name: cinema-audio-audit
description: Audita sistemas y assets de audio de CinemaCleaner sin sustituirlos automáticamente.
---

# Auditoría de audio

1. Busca `AudioStreamPlayer`, `AudioStreamWAV`, `AudioServer`, streams asignados y llamadas a reproducción.
2. Detecta sonido generado desde GDScript, muestras únicas repetidas, buses incorrectos, clipping, archivos no usados y loops defectuosos.
3. Lee WAV de producción con `tools/audio/validate_audio.py`.
4. Reporta ruta, disparador, bus, riesgo y recomendación. No borra ni sustituye audio legacy.
