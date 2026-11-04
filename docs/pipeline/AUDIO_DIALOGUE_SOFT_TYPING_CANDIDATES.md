# Diálogo ficticio como tecleo suave

Estado: **variante 03 aprobada e integrada** para el texto de grabaciones. Las variantes 01 y 02 no se usan. Deben sugerir que alguien habla mediante teclas rápidas, con tacto de máquina de escribir amortiguada, sin voz, campanilla ni retorno de carro.

| Variante | Dirección solicitada al modelo | Semilla | Preview en bucle | Duración |
| --- | --- | ---: | --- | ---: |
| 01 | Máquina de escribir pequeña con teclas amortiguadas y ritmo irregular | 75601 | `audio_source/generated/sfx/dialogue/dialogue_soft_typing_loop_review_01.wav` | 6,266 s |
| 02 | Teclado mecánico compacto, golpes secos pero redondos y rápidos | 75602 | `audio_source/generated/sfx/dialogue/dialogue_soft_typing_loop_review_02.wav` | 4,200 s |
| 03 | Mini máquina de escribir caricaturesca en grupos rápidos | 75603 | `audio_source/generated/sfx/dialogue/dialogue_soft_typing_loop_review_03.wav` | 6,121 s |

Generados localmente con Stable Audio 3 Small-SFX (`sm-sfx` + `same-s`) a 7 s por toma. Fuentes: `audio_source/raw/sfx/dialogue/dialogue_soft_typing_candidate_0X.wav`. `tools/audio/process_audio.py` preparó los intermedios a -22 LUFS; los previews usan una unión circular de 300 ms y quedaron en `audio_source/generated/sfx/dialogue/`. En 02 se retiró la cola casi silenciosa a partir de 4,5 s antes de cerrar el loop. Los tres pasan `tools/audio/validate_audio.py`: WAV PCM16 estéreo a 44,1 kHz, sin silencio total ni clipping. Diferencia última/primera muestra: 152, 37 y 81/32767. La variante 03 seleccionada se copió sin modificar a `assets/audio/sfx/dialogue/dialogue_soft_typing_03_loop.wav`, se revalidó (6,121 s, pico 27572/32767) y conserva su preview y fuentes como reversión. La usa `GameIntro` en el bus `UI` solo durante la aparición de letras; queda en silencio durante la lectura de cada frase.
