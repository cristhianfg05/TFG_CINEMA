# Auditoría de audio actual

Fecha: 2026-09-21. Alcance: lectura; ningún sonido legacy se ha borrado ni sustituido.

## Inventario

- No hay archivos WAV, OGG, MP3 o FLAC de producción en el proyecto.
- No existía `default_bus_layout.tres`; los reproductores actuales salen por `Master`.
- `scenes/gameplay/gameplay_manager.tscn` contiene cuatro `AudioStreamPlayer`: `PickupAudio` (-12 dB), `EmptyAudio` (-10 dB), `RejectAudio` (-9 dB) y `VacuumAudio` (-17 dB).
- `scripts/gameplay_manager.gd` sintetiza sus cuatro streams en memoria como `AudioStreamWAV`: tonos de recogida y vaciado, tono de rechazo y ruido/tono de aspiradora en loop. Son formatos mono de 8 bits a 22.05 kHz.
- Disparadores: recogida completada, vaciado de bolsa, intento de recogida rechazado y estado activo de aspiradora.
- `scripts/arcade_reel_rescue.gd` crea `ArcadeChiptune`, un `AudioStreamPlayer` con loop procedural de 16 bits a 11.025 kHz, al abrir el minijuego.
- `scripts/game_intro.gd` puede reproducir un `intro_audio_stream` exportado, pero no tiene asset asignado actualmente.

## Excluido del inventario de juego

`addons/godot_mcp/commands/audio_commands.gd` expone comandos de automatización del editor; no es audio de gameplay.

## Riesgos y prioridad

Los cuatro SFX de `GameplayManager` son el primer bloque de migración: son audibles, repetitivos y sintetizados. Empezar por recogida de basura (`Trash`, 5-8 variantes) tras aprobación. Mantener la aspiradora procedural hasta disponer de un loop externo validado.
