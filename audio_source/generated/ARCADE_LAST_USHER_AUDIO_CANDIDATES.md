# El último acomodador — candidatos de audio

Estado: **selección aprobada e integrada**. Música 03, disparo 02, órbitas 01, cinta 02 y corazón 03. Las variantes no seleccionadas permanecen como candidatos, sin referencias de juego.

Generados localmente con Stable Audio 3 Small (`sm-music` y `sm-sfx`), procesados a WAV PCM16 estéreo/44,1 kHz. Los SFX se extrajeron de la región útil de cada bruto, con fades cortos y reducción moderada de ruido. Los tres temas tienen empalme cruzado para repetición.

| Familia | 01 | 02 | 03 | Duración |
| --- | --- | --- | --- | --- |
| Música | [Arcade 80s enérgico](music/arcade_last_usher_music_loop_01.wav) | [Synthwave oscuro](music/arcade_last_usher_music_loop_02.wav) | [Acción pixel heroica](music/arcade_last_usher_music_loop_03.wav) | 28,57–29,19 s, loop |
| Disparo | [01](sfx/arcade_last_usher/shot_candidate_01_clean.wav) | [02](sfx/arcade_last_usher/shot_candidate_02_clean.wav) | [03](sfx/arcade_last_usher/shot_candidate_03_clean.wav) | 0,306–0,450 s |
| Órbitas | [01](sfx/arcade_last_usher/orbit_candidate_01_clean.wav) | [02](sfx/arcade_last_usher/orbit_candidate_02_clean.wav) | [03](sfx/arcade_last_usher/orbit_candidate_03_clean.wav) | 0,850 s |
| Cinta | [01](sfx/arcade_last_usher/tape_pickup_candidate_01_clean.wav) | [02](sfx/arcade_last_usher/tape_pickup_candidate_02_clean.wav) | [03](sfx/arcade_last_usher/tape_pickup_candidate_03_clean.wav) | 0,250 s |
| Corazón | [01](sfx/arcade_last_usher/heart_pickup_candidate_01_clean.wav) | [02](sfx/arcade_last_usher/heart_pickup_candidate_02_clean.wav) | [03](sfx/arcade_last_usher/heart_pickup_candidate_03_clean.wav) | 0,500 s |

Los originales permanecen en `audio_source/raw/` y los intermedios en `audio_source/generated/`. Se descartó un primer intento de disparo por quedar casi mudo al procesarlo; el 01 presentado procede de una nueva generación. La órbita 01 se copió a producción con +8 dB por resultar demasiado floja. El tema procedural anterior sigue disponible mediante `use_legacy_music` y el sonido de recogida anterior se conserva para el imán.

Mezcla inicial en el bus `Machines`: música −25 dB, disparo −17 dB, órbita reforzada −11 dB, cinta −3 dB y corazón −10 dB. El disparo suena una vez por ráfaga; la órbita, en impacto, con un mínimo de 0,15 s entre disparos de audio. Las cintas recogen sonido como máximo cada 0,07 s para evitar que una atracción masiva sature la mezcla. La cinta recogible se dibuja ahora a 8×7 píxeles lógicos; el icono del HUD conserva su tamaño anterior.
