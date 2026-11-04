# Sala 2 — candidatos de música de fondo

Tres propuestas originales, generadas con Stable Audio 3
`sm-music` / `same-s` (CPU). La referencia de piano romántico se usó solo para
orientar el carácter; los prompts piden expresamente no reproducir melodías
existentes. El usuario eligió la 03 para la sala 2; la música de la sala 1
permanece intacta. Las propuestas 01 y 02 siguen como candidatos sin integrar.

| Candidato | Intención | Semilla |
| --- | --- | ---: |
| `music_room2_candidate_01` | Piano solo íntimo, arpegios fluidos y pulso suave de 6/8. | 2201 |
| `music_room2_candidate_02` | Piano romántico con respuestas ocasionales tipo celesta. | 2202 |
| `music_room2_candidate_03` | Piano expresivo con una capa de cuerdas muy tenue. | 2203 |

Originales: `audio_source/raw/music/`. Versiones para escuchar:
`audio_source/generated/music/`. Cada versión dura 30,000 s y se ha procesado
a WAV PCM16 estéreo a 44,1 kHz, con objetivo de -18 LUFS, techo de -1,5 dBTP y
fades mínimos. Las tres pasan `validate_audio.py`: sin silencio total ni clipping.

Los últimos segundos de la 03 original caen casi al silencio. Para la versión
de juego se conservaron sus primeros 20 s musicales y se cruzaron 2 s del final
con 2 s del principio, resultando un loop de 18 s en
`assets/audio/music/music_room2_03.wav`. Conservamos la candidata original
intacta. El WAV de juego pasa `validate_audio.py` (PCM16 estéreo, 44,1 kHz,
18,000 s, sin clipping). Su unión de loop tiene una discontinuidad de 434
unidades PCM16, comparable a los cambios normales entre muestras del archivo.

`Room2Music` emite desde los dos altavoces grandes de la sala 2, en el bus
`Music`, con el mismo comportamiento espacial de la sala 1: empieza tras la
introducción, permanece activo al salir y se atenúa con la distancia.
`game_intro_smoke.gd` y `room_02_smoke.gd` pasan. Queda escuchar el loop y la
mezcla dentro del juego para ajustar el volumen a gusto del usuario.
