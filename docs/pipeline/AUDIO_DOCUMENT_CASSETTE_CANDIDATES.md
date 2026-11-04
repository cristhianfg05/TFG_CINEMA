# Documento y arranque de grabación

Estado: **folio 02 aprobado, solo su primera mitad, e integrado**; **grabadora 02 aprobada e integrada** en la primera grabación narrativa. Las variantes nuevas de folio 01 y 03 se descartaron y retiraron de `audio_source/raw/` y `audio_source/generated/`. Los seis candidatos iniciales (`document_pickup_candidate_01..03` y `cassette_record_start_candidate_01..03`) ya estaban descartados.

| Familia | WAV aprobado | Duración final | Uso |
| --- | --- | --- | --- |
| Coger un folio | `assets/audio/sfx/documents/document_pickup_sheet_02_first_half.wav` | 0,588 s | `GameplayManager.collect_document()`, al recoger cualquier documento; bus `Player`, -10 dB. |
| Grabadora iniciándose | `assets/audio/sfx/cassette/cassette_recorder_start_02.wav` | 1,099 s | `GameIntro`: inicio y cierre de la grabación 01 en partida nueva; bus `UI`, -12 dB. |

El audio de producción del folio procede de los primeros 0,664 s de `document_sheet_pickup_review_02.wav`. Se aplicó un fade de salida de 25 ms; el procesado de silencios de borde dejó 0,588 s útiles. La fuente editada se conserva en `audio_source/raw/sfx/documents/document_sheet_pickup_02_first_half.wav`. La toma completa y el preview 02 se conservan como fuente y referencia. El archivo de producción es WAV PCM16 estéreo a 44,1 kHz y pasó `tools/audio/validate_audio.py`.

El reproductor del folio vive en `GameplayManager`, no en el pickup: así el sonido no se corta cuando desaparece el documento. El rectángulo legacy permanece oculto como fallback visual y el nuevo modelo se describe en [DOCUMENT_SHEET_PROP.md](DOCUMENT_SHEET_PROP.md).

Origen de los candidatos: Stable Audio 3 Small-SFX local (`sm-sfx` + `same-s`). Los tres folios de esta ronda se generaron con semillas 74101, 74102 y 74103. Las tomas anteriores de *papel desarrugándose* permanecen únicamente como historial y no se usan en el juego.
