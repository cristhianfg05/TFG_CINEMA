# Compra de mejoras — candidatos «pirim»

03-11-2026. Estado: **03 aprobado e integrado al comprar mejoras**. Los candidatos 01 y 02 quedan sin uso.

| Candidato | Preview | Duración | Semilla |
| --- | --- | ---: | ---: |
| 01 | `audio_source/generated/sfx/upgrade_levelup_pirim_candidate_01.wav` | 0,400 s | 31103 |
| 02 | `audio_source/generated/sfx/upgrade_levelup_pirim_candidate_02.wav` | 0,453 s | 31104 |
| 03 | `audio_source/generated/sfx/upgrade_levelup_pirim_candidate_03.wav` | 0,392 s | 31105 |

Generación local con Stable Audio 3 Small-SFX / same-s, CPU, fuentes de 4 s, CFG 3 y 16 pasos. Guía positiva: arpegios ascendentes suaves, notas redondeadas de sintetizador/teclado y confirmación musical de mejora. Guía negativa: ruido, estática, interferencia, distorsión, siseo, crujidos, voz, batería y sonido áspero. Fuentes finales: `audio_source/raw/sfx/upgrade_levelup_pirim_v3_0X.wav`.

Se descartaron para selección las primeras tomas de 1,5 s (`upgrade_levelup_pirim_0X` y `v2_01`) por exceso de ruido e insuficiente estructura tonal. Se conservan como historial, no se usan en el juego ni son los previews presentados.

Procesado con `process_audio.py` a −24 LUFS, selección del comienzo del motivo y compresión temporal ×2 sin cambiar la altura musical, paso alto a 100 Hz, paso bajo a 5.200 Hz y fades de 5/80 ms. Los tres previews se igualaron a −26 dBFS RMS, con picos de −15,76 / −15,15 / −16,23 dBFS, para comparar el carácter sin diferencias grandes de volumen. Todos pasan `validate_audio.py`: PCM16 estéreo 44,1 kHz, menos de medio segundo, sin clipping ni silencio total. Inspección espectral de las notas; la elección auditiva corresponde al usuario.

Metadatos en `audio_source/generated/sfx/upgrade_levelup_pirim_candidates.json`. Se añadió el argumento opcional `--steps` al wrapper de generación, manteniendo sus ocho pasos predeterminados para otros trabajos.

Integración: copia idéntica del 03 en `assets/audio/sfx/ui/upgrade_levelup_03.wav`, validada por formato y SHA-256. `GameplayManager/UpgradePurchaseAudio` reproduce el sonido una vez al terminar una compra válida de cualquier rama, en el bus UI a −6 dB. Usa un AudioStreamRandomizer con el único candidato elegido y variaciones leves de pitch (1,015) y volumen (0,25 dB). El reproductor funciona también durante la pausa del menú y admite dos voces para compras sucesivas. Los intentos rechazados, los niveles al máximo, la carga de la partida y la compra de herramientas no disparan este sonido. Los sonidos de navegación de menús y de las recreativas se conservan.

Validación: prueba gráfica aislada de compra con el árbol pausado (`UPGRADE_PURCHASE_AUDIO_OK`), sin reproducción al cargar ni ante saldo insuficiente o rama al máximo. Regresión `incremental_update_smoke.gd` superada. Editor Godot MCP: cero errores y advertencias tras la recarga.
