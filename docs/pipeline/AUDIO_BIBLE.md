# CinemaCleaner Audio Bible

## Dirección

**Soft stylized cartoon game audio.** El juego suena cozy, ligero, limpio y agradable: con carácter suficiente para leerse durante el juego, pero nunca estridente, agresivo ni cinematográfico.

## Principios

- Priorizar sonidos suaves, cortos, legibles y ligeramente exagerados.
- Evitar timbres de casino, UI móvil exagerada, subgraves grandes y realismo invasivo.
- Todo SFX repetido debe tener variación audible: muy frecuente, 5-8 variantes; frecuente, 3-6; ocasional, 2-3.
- Godot puede aplicar pequeñas variaciones de pitch y volumen a una selección ya aprobada; no sintetiza el sonido final.
- Los sonidos deben convivir. Si un efecto llama más la atención que la interacción a la que acompaña, se descarta.

## Producción

- Fuente: `audio_source/raw/`; resultados intermedios: `audio_source/generated/`; audio de juego: `assets/audio/`.
- Entregar WAV PCM de 16 bits, estéreo y 44.1 kHz salvo una excepción documentada.
- Dejar margen de pico (objetivo de procesado: -1.5 dBTP aprox.) y comprobar clipping antes de integrar.
- Añadir fades mínimos para evitar clicks: 5 ms de entrada y 15 ms de salida por defecto.

## Buses previstos

`Music`, `SFX` (con `Player`, `Trash`, `Tools`, `Machines` y `World`), `Ambience` y `UI` envían a `Master` según `default_bus_layout.tres`.
