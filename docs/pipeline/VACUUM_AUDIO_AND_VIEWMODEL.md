# Aspiradora: audio y presentación en primera persona

## Decisiones aprobadas

- Arranque: `vacuum_start_candidate_01.wav`, primero acortado de 2,468 s a 1,234 s. El derivado de juego actual `assets/audio/sfx/tools/vacuum_start_01_half.wav` dura 0,617 s: primera mitad del derivado anterior, con 20 ms de fade de salida. El WAV de 1,234 s permanece intacto para revertir.
- Aspirado: `vacuum_suction_candidate_03.wav`. El derivado anterior `vacuum_suction_03_loop.wav` duraba 4,895 s. El actual `vacuum_suction_03_steady_loop.wav` toma el tramo estable entre 0,45 y 4,2 s y une 200 ms de final/principio con crossfade; dura 3,55 s y Godot lo repite en bucle. Ambos WAV previos permanecen intactos.
- Apagado: reproduce exactamente el mismo `vacuum_start_01_half.wav` de 0,617 s, según la elección del usuario. Los tres candidatos `vacuum_stop_candidate_*.wav` se apartaron de `assets/audio/` a `audio_source/rejected/sfx/`, de donde se pueden recuperar; los brutos siguen en `audio_source/raw/sfx/`.
- El primer bruto del aspirado 03 quedaba prácticamente mudo tras procesarse. Se conserva; el WAV final procede de `audio_source/raw/sfx/vacuum_suction_candidate_03_v2.wav`.

## Reproducción y reversión

`GameplayManager` usa el bus `Tools`: loop a −13 dB y transición a −14 dB. El loop comienza al activar la aspiradora y sube suavemente durante 0,425 s mientras suena el arranque. Al soltar el gatillo o agotar batería, el loop baja durante 0,07 s y suena el mismo clip corto de transición. Si se reactiva durante el fundido, el tween anterior se cancela antes de comenzar el nuevo. El método procedural `_make_vacuum_wind()` se conserva; la propiedad exportada `use_legacy_vacuum_audio` permite volver a él con el nivel anterior de −17 dB sin cambiar assets. Para volver a los WAV aprobados previamente, basta restaurar las dos rutas `VACUUM_*_STREAM` y los tiempos 0,85/0,14 s.

## Presentación visual

En `GameplayHUD`, la escala del GLB legado baja de 2,35 a 2,05 (−12,8 %); no se modifica el modelo original. Continúan el seguimiento suave de caminata/carrera y la pose de uso. Al aspirar se suma un tambaleo sinusoidal pequeño: posición ±0,009 m y ±0,006 m a 7,5 y 11 Hz; giro ±0,65° y ±0,45°. La mezcla de pose suaviza tanto la entrada como la salida.

El viento no usa partículas costosas ni modifica el GLB: son 24 instancias de una malla compartida de cinta curva, fina y afilada, sin sombras y con alpha suave gris azulado. Su color y opacidad disminuyen en las puntas para evitar el aspecto de rectángulos. Viajan de una corona delante de la boca hacia un ancla en la coordenada local `(-0.385, 0.14, 0.0)` del modelo. Como el ancla es hija del GLB instanciado, el destino acompaña al balanceo y siempre termina en el cabezal. Cada estela tiene una velocidad y fase ligeramente distintas, un pequeño desvío sinusoidal, orientación según el flujo y desvanecimiento al entrar y salir. El efecto solo se dibuja cuando la aspiradora está equipada, visible y activa. Se hizo en Godot porque la trayectoria debe seguir el cabezal frame a frame; Blender no aporta ventaja para este efecto dinámico.

## Comprobación

- `tests/vacuum_smoke.gd`: compra, mejoras, succión física, batería, escala, ancla, WAV en loop y bus `Tools`.
- `tests/vacuum_visual_capture.gd`: ejecución con renderer real, comprueba que el loop está activo y que el apagado se dispara; guarda [captura de aspiradora activa](screenshots/vacuum/vacuum_active.png). Godot emite al salir del test oculto los mismos avisos de liberación de texturas OpenGL observados en otras capturas; el smoke headless no emite errores nuevos.
- Los dos WAV de juego actuales pasan `tools/audio/validate_audio.py` como PCM16 estéreo de 44,1 kHz, sin clipping (picos 16996 y 18292/32767). Los antiguos se conservan.

Queda pendiente escuchar y ajustar los niveles en una partida interactiva con Godot MCP, que no estaba conectado durante esta verificación.
