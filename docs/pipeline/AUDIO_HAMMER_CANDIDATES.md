# Audio de la maza

## Golpe sobre el muro

La variante **02** de piedra fue aprobada. Se conserva su candidato en `assets/audio/sfx/hammer/candidates/hammer_stone_candidate_02.wav` y una copia estable en `assets/audio/sfx/hammer/hammer_stone_02.wav`. `HammerController` la reproduce solo cuando el swing impacta el muro final, en el bus 3D `World`, con variación leve de pitch (0,97–1,03) y polifonía de cuatro golpes. Las variantes de piedra 01 y 03 siguen como candidatos, sin uso.

## Swing de palo cortando el viento: variante 01 aprobada

Las tandas de swing anteriores se descartaron por sonido de interferencia. Sus WAV procesados y archivos de importación se retiraron de `assets/audio/sfx/hammer/candidates/` y se conservaron en `audio_source/rejected/sfx/hammer/`; las fuentes originales permanecen disponibles para auditoría. Estas son **tres tomas nuevas**, generadas con Stable Audio 3 Small-SFX (`sm-sfx` + `same-s`) como un palo que pasa rápido cerca del micrófono, sin impacto:

| Variante | Archivo para escuchar | Duración | Semilla |
| --- | --- | ---: | ---: |
| 01 | `assets/audio/sfx/hammer/candidates/hammer_stick_whoosh_v3_candidate_01.wav` | 0,153 s | 48101 |
| 02 | `assets/audio/sfx/hammer/candidates/hammer_stick_whoosh_v3_candidate_02.wav` | 0,482 s | 48122 |
| 03 | `assets/audio/sfx/hammer/candidates/hammer_stick_whoosh_v3_candidate_03.wav` | 0,440 s | 48123 |

Se generaron fuentes de 4 segundos con CFG 3,0 y guía negativa contra estática, interferencia, chisporroteos, música y voz. Cada salida larga contenía varios impulsos; se extrajo **uno** por candidato antes de pasar por `process_audio.py` a -18 LUFS. Las fuentes (`01`, `02_retry`, `03_retry2`) están en `audio_source/raw/sfx/hammer/` y los recortes en `audio_source/generated/sfx/hammer/`. Las tomas intermedias demasiado cortas o agudas se guardaron en `audio_source/rejected/sfx/hammer/`, no se publicaron como candidatos. Los tres finales pasan `validate_audio.py`: PCM16 estéreo, 44,1 kHz, menos de un segundo, sin clipping ni silencio.

El usuario eligió **01**. Una copia idéntica a su candidato se integra como `assets/audio/sfx/hammer/hammer_swing_01.wav`, en el bus `Tools` a -18 dB. Suena durante la aceleración del swing (tras la preparación, antes del impacto) con pitch aleatorio suave 0,96–1,04; el golpe de piedra 02 sigue sonando únicamente al acertar el muro. Los candidatos 02 y 03 permanecen sin uso ni aprobación. No se tocaron los sonidos legacy ni se añadieron dependencias.
