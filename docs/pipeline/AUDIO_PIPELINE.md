# Pipeline de audio local

## Alcance

Stable Audio 3 genera candidatos locales; el procesado los convierte en WAV aptos para Godot; Godot únicamente reproduce, randomiza, espacializa y mezcla. Nunca se reemplaza ni elimina un sonido legacy sin una prueba jugable aprobada.

## Instalación local preparada

- Runtime: Stable Audio 3 TFLite para CPU, en `C:\Users\crist\.codex\tools\stable-audio-3\optimized\tflite`.
- Python del runtime: `.venv\Scripts\python.exe` (Python 3.11).
- FFmpeg: instalado para conversión y análisis.
- Ruta de pesos de trabajo: `C:\Users\crist\.codex\tools\stable-audio-3\optimized\tflite\models\tflite`. Hugging Face mantiene además la caché en el perfil local del usuario.
- No usar Medium sin autorización explícita. Este equipo usa el backend TFLite/XNNPACK de CPU; la Intel Arc detectada no aporta una ruta CUDA para Medium.

## Modelos autorizados

- `sm-sfx` / `same-s`: SFX cortos y de gameplay.
- `sm-music` / `same-s`: música y loops candidatos.

## Generar un candidato

No generar una biblioteca completa sin aprobación. Para una petición aprobada, desde la raíz del proyecto:

```powershell
python tools/audio/generate_audio.py sfx --prompt "soft cartoon paper rustle, clean, short, no harsh highs" --seconds 4 --output audio_source/raw/sfx/trash_rustle_01.wav
python tools/audio/generate_audio.py music --prompt "cozy light instrumental cinema lobby loop, gentle, no vocals" --seconds 30 --output audio_source/raw/music/lobby_candidate_01.wav
```

El script solo acepta `sfx` y `music`, guarda en `audio_source/raw/` y llama al runtime local con los Small correspondientes.

## Procesar y validar

```powershell
python tools/audio/process_audio.py audio_source/raw/sfx/trash_rustle_01.wav assets/audio/sfx/trash/trash_rustle_01.wav
python tools/audio/validate_audio.py assets/audio/sfx/trash/trash_rustle_01.wav --max-seconds 12
```

`process_audio.py` requiere FFmpeg y recorta solo el silencio inicial y final (conserva pausas internas), aplica fades mínimos, normalización razonable y WAV PCM estéreo a 44.1 kHz. `validate_audio.py` comprueba formato, duración, silencio y clipping. Un resultado válido sigue necesitando escucha humana.

## Integración en Godot

1. Conservar la referencia legacy.
2. Añadir y probar el archivo nuevo en `assets/audio/`.
3. Asignar el bus adecuado y, para acciones repetidas, un `AudioStreamRandomizer` con las variantes aprobadas.
4. Ejecutar la escena y comprobar juego, log y niveles.
5. Sustituir una única referencia y repetir la prueba.
6. Retirar código o assets antiguos solo cuando no exista ninguna referencia y la migración esté aprobada.
