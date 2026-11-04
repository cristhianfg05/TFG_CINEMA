# Música candidata para Acción y Miedo

Estado: **Acción 01 y Miedo 03 aprobados e integrados**. Los otros cuatro previews se conservan como candidatos no usados; no se asignan al juego. Se generaron localmente con Stable Audio 3 Small-Music (`sm-music` + `same-s`), 24 s por toma, sin servicios de pago.

Las copias de producción son `assets/audio/music/music_room3_action_01.wav` (22,740 s) y `assets/audio/music/music_room4_fear_03.wav` (13,423 s). `scenes/main/main.tscn` las asigna al `enabled_music` de Sala 3 y Sala 4, respectivamente. Tras activar la palanca de la sala, `CinemaRoomAudioController` inicia el loop en los dos altavoces grandes y todos los laterales, funde la interferencia principal y `CinemaRoomAudioSystem` reduce la música global mientras el jugador permanezca allí. Las fuentes y previews anteriores no se modificaron.

| Sala | Variante | Semilla | Preview en bucle | Duración |
| --- | --- | ---: | --- | ---: |
| Acción | 01: riff de guitarra ligero, bajo y batería suave | 75301 | `audio_source/generated/music/music_room_action_loop_review_01.wav` | 22,740 s |
| Acción | 02: ritmo rock más contenido, guitarra apagada | 75302 | `audio_source/generated/music/music_room_action_loop_review_02.wav` | 22,740 s |
| Acción | 03: guitarra melódica de aventura, pulso estable | 75303 | `audio_source/generated/music/music_room_action_loop_review_03.wav` | 22,740 s |
| Miedo | 01: motivo repetido de piano agudo con fondo oscuro | 75401 | `audio_source/generated/music/music_room_fear_loop_review_01.wav` | 19,639 s |
| Miedo | 02: piano fino y tensión suave sostenida | 75402 | `audio_source/generated/music/music_room_fear_loop_review_02.wav` | 18,304 s |
| Miedo | 03: ostinato agudo y notas ligeramente disonantes | 75403 | `audio_source/generated/music/music_room_fear_loop_review_03.wav` | 13,423 s |

Las tomas originales están en `audio_source/raw/music/music_room_{action,fear}_candidate_0X.wav`. Cada una pasó por `tools/audio/process_audio.py` a -20 LUFS y un crossfade circular de 1,2 s para unir final y principio; el resultado editable intermedio permanece en `audio_source/generated/music/`. Los seis previews finales pasan `tools/audio/validate_audio.py`: WAV PCM16 estéreo, 44,1 kHz, no silenciosos y sin clipping. Diferencia de muestra en la unión: 156–463/32767. Las dos copias de producción se validaron de nuevo tras copiarse. `tests/room3_4_approved_music_smoke.gd` comprueba loop, bus `Music`, emisores grandes y laterales, activación, ducking global y restauración desde partida guardada.
