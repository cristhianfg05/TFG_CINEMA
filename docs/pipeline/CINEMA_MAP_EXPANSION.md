# Mapa corregido: vestíbulo y Salas 3–4

## Nombres y coordenadas

`room_01` = Aventura; `room_02` = Romance; `room_03` = Acción; `room_04` = Miedo. `room_05` sigue reservado para «La última sesión» y no usa una de las cuatro palancas. Los IDs de guardado no cambian. Las Salas 1 y 2 conservan su huella; sus marcos interiores, apliques y pasillos se han ajustado.

Por compatibilidad con partidas guardadas, el **pasillo derecho original** conserva internamente el ID `left_corridor`, y el **pasillo izquierdo nuevo** conserva `right_corridor`. Los nombres visibles del HUD ya dicen «derecha» e «izquierda» respectivamente. No se migran los IDs de basura ni las banderas de desbloqueo.

| Área | Huella aproximada en mundo (X, Z) | Estado |
| --- | --- | --- |
| Sala 1 | X −11…11, Z −15…15 | Existente, sin mover |
| Pasillo derecho (original) | X −12…11, Z 15…25 | Sala 2 y Sala 3 al norte, Sala 1 al sur, manager en su extremo derecho y puerta al vestíbulo en el izquierdo |
| Manager | X −19…−12, Z 15…25 | Ensanchado hasta el fondo del pasillo derecho; suelo y pared cierran el antiguo hueco de caída |
| Sala 2 | X 7.5…34.7, Z 25…57 | Existente, sin mover |
| Sala 3 Acción | X −23…4.25, Z 25…57 | Los pasillos exteriores tocan las paredes; queda una separación de 3.25 m con Sala 2, cerrada hacia el pasillo |
| Vestíbulo | X 11.4…18.5, Z −15…25 | Su pared junto a Sala 1 está en X 11.8, sin invadir el muro de esa sala |
| Pasillo izquierdo (nuevo) | X 18.5…36.9, Z 15…25 | Trasladado 1.5 m junto con Sala 4 para conservar sus conexiones |
| Sala 4 Miedo | X 18.9…36.9, Z −39…15 | Sala larga y rectangular al sur del pasillo izquierdo |
| Sala Final | Más allá de X 36.9 | Solo espacio reservado; al extremo opuesto del manager, sin interior |

El muro de ladrillo existente está en X 36.9, Z 17…23. Es el mismo GLB hecho en Blender MCP: 888 triángulos, cinco materiales de ladrillo/mortero, pivote al centro inferior, collider Box independiente. No es rompible todavía. Los paños de enlucido sobre el ladrillo y sus alas laterales llegan ahora a 7 m, como las otras paredes; no se ha sustituido el modelo.

El plano se lee en espejo respecto a X de Godot: el manager queda en el extremo derecho de la imagen y el muro de la Sala Final en el izquierdo. Las líneas rojas se han traducido en aperturas y persianas: Sala 2 y Sala 3 en el lado norte del pasillo derecho, Sala 1 al sur, manager en el extremo, puertas enfrentadas a Z 18.5 a ambos lados del vestíbulo, Sala 4 al sur del pasillo izquierdo y acceso principal al sur del vestíbulo. Las paredes de secciones vecinas pueden dejar una pequeña holgura para evitar clipping.

## Progresión

La persiana de 3 m entre pasillo derecho y vestíbulo usa `RollerShutterDoor` y se abre una sola vez cuando **cada** una de estas zonas llega al 95 %: Sala 1, pasillo derecho, despacho, Sala 2 y Sala 3. Se comprueba que haya basura registrada antes de permitir el desbloqueo. El estado permanece en el guardado (versión 10; lectura de versiones 1–9 conservada).

Al abrirse aparece el objetivo «Limpia el vestíbulo». A partir de 95 % de limpieza del vestíbulo, se abre la segunda persiana de 3 m hacia el pasillo izquierdo y aparece «Limpia la Sala 4». El acceso principal sur del vestíbulo es solo una persiana cerrada: su exterior y lógica de apertura no pertenecen a esta fase. El muro de la Sala Final sigue cerrado sin maza ni lógica de rotura.

Las dos persianas de progresión reproducen el nuevo efecto metálico espacial `lobby_shutter_open_01.wav` al empezar a abrir. El vestíbulo hereda la música ambiental global, sin bucle exclusivo.

## Construcción y sistemas reutilizados

- El vestíbulo usa paneles, molduras, suelo, techo e iluminación de la familia del pasillo. No se instancian aún taquilla, mesas ni otra decoración; se conserva la papelera y la basura jugable. La pared occidental se ha apartado de Sala 1: el muro queda a X 11.8 y el suelo empieza en X 11.4, con un pequeño umbral que mantiene transitable la persiana. Las persianas y el acceso principal tienen marcos oscuros visuales.
- Sala 3 Acción replica los tres bloques de seis butacas y nueve filas de Sala 2 (162 asientos). Se ha estrechado 3 m por lado sin mover las filas: los bordes de los pasillos exteriores llegan a la cara interior de los muros. Pantalla, altavoces grandes, paredes y zona de sala se recalculan con la nueva anchura; el tramo libre entre esta sala y la 2 se cierra hacia el pasillo. Su entrada tiene ahora marco negro en ambas caras. Ocho estrellas colgantes reutilizan `Estrella_ColgadaDecoracionAccion.glb` de `assets/models/source/room_3/`; su suelo de acción tiene una textura vectorial discreta. No invade el despacho.
- Sala 4 Miedo tiene 18 filas, 8 butacas por fila en bloques 4+4, dos laterales y un pasillo central, y cinco escalones de acceso. La cámara del jugador alcanza 80 m para mostrar la pantalla desde fuera de la entrada. Usa suelos pizarra/vino, doce murciélagos colgantes, cuatro telarañas en las esquinas superiores de las paredes delantera y trasera, dos cortinas rotas sobre la pantalla y cuatro calaveras repartidas entre el fondo y el exterior de la entrada. Reutiliza los GLB de miedo de `assets/models/source/room_4/`, incluido `CartelCasa_DecoracionMiedo.glb` junto al lado izquierdo de la puerta; el SVG provisional anterior queda sin uso para una posible reversión. El póster de la película está más cerca de la puerta y las calaveras usan una escala mayor. La puerta tiene marco negro también por dentro.
- Cada tramo lateral de las cuatro salas muestra rejilla, altavoz pequeño y dos apliques horizontales. La luz puntual sale ahora de cada aplique (alcance 3 m, sin sombras), no del centro del altavoz. Sala 3 conserva sus altavoces grandes a escala 4.2 y las cuatro escaleras de acceso de 1.20/1.50/1.50/1.20 m; Sala 2 amplía sus pasillos y escalones a 1.42/1.78/1.78/1.42 m para cerrar la separación visual con las butacas. Salas 1 y 2 también tienen marco negro interior alineado con su primera columna de pared trasera. Las texturas vectoriales nuevas `room_03_action_carpet.svg` y `room_04_fear_carpet.svg` se aplican al suelo, gradas y rampas de sus salas, con un material triplanar por sala.
- La cámara principal alcanza 80 m: 55 m cortaba la pantalla de la larga Sala 4 al mirarla desde su entrada. La visibilidad de la basura del vestíbulo sigue limitada a 18 m del jugador; las instancias, colisiones, IDs y recuentos de limpieza permanecen intactos.
- Ambas salas reutilizan `CinemaMovieController`, `CinemaRoomAudioController`, `CinemaSeatSystem`, las cuatro palancas actuales, la pantalla genérica y las butacas estándar/plegadas/rotas. Solo las no plegadas son interactuables. Las ranuras de música propia siguen vacías hasta contar con audio aprobado; la interferencia usa el bucle existente. Los vídeos de Salas 3/4 pueden añadirse después a `assets/movies/room_3/` y `assets/movies/room_4/`.
- La proyección aplica un desenfoque más acusado (13 muestras, radio 6.5 px, mezcla 0.96). Cuando existen clips, un SubViewport diminuto compila el shader al arrancar y se libera antes del juego: así la primera palanca no paga el coste de compilación durante el primer fotograma. Se conserva el inicio normal de la película y el guardado existente.
- Al levantarse de una butaca, el jugador y la cámara avanzan suavemente durante 0.62 s; la colisión y el control se recuperan al terminar. La salida prioriza el punto seguro desde el que se seleccionó esa butaca, para conservar la misma fila. Si se ocupa, las alternativas comprobadas por física están delante o en el pasillo de esa fila, no detrás hacia la fila contigua. Sala 4 convierte su pasillo a coordenadas globales, como las butacas. Es el movimiento inverso del sentarse, no un teletransporte.
- El aviso de objetivo completado reutiliza la estética HUD y el sello existente. Nombre y descripción aparecen junto a su hueco, y el sello cae mediante tween. Reproduce el piano candidato 02, elegido por el usuario. Al revelarse un objetivo nuevo, aparece el mismo contenedor con entrada suave, sin sello y con el piano interrogativo candidato 03, también elegido por el usuario; durante el aviso, Tab abre directamente la pestaña de objetivos. Ambos sonidos usan el bus `UI`.

## Basura y limpieza

Recuento actual de objetos y monedas base (sin multiplicadores):

| Zona visible | Pequeña (1 moneda) | Grande (2 monedas) | Objetos | Monedas |
| --- | ---: | ---: | ---: | ---: |
| Sala 1 | 380 | 20 | 400 | 420 |
| Pasillo derecho (ID `left_corridor`) | 105 | 15 | 120 | 135 |
| Despacho manager | 16 | 2 | 18 | 20 |
| Sala 2 romántica | 420 | 60 | 480 | 540 |
| Entrada, taquillas, vestíbulo y palomitas (ID `lobby`) | 520 | 35 | 555 | 590 |
| Sala 3 Acción | 410 | 30 | 440 | 470 |
| Pasillo izquierdo (ID `right_corridor`) | 80 | 10 | 90 | 100 |
| Sala 4 Miedo | 640 | 20 | 660 | 680 |
| Sala final secreta (reservada, sin instanciar) | 820 | 20 | 840 | 860 |

Entrada y vestíbulo comparten la única zona física `lobby`: 555 objetos, ligeramente por encima de los 510 previstos para el vestíbulo, **sin sumar** las dos filas originales. La sala final sigue siendo un muro, por lo que sus 840 objetos son solo una reserva para cuando se construya y no afectan al progreso ni a la física actual. Hay 2763 objetos jugables y 2955 monedas base en el mapa construido.

Los IDs persistentes existentes se mantienen. La basura se distribuye en cojines, bajo butacas, entre filas, pasillos y suelo delantero/trasero; las posiciones de acceso evitan el hueco bajo las rampas. Para este volumen, los objetos lejanos de otra zona se congelan y se ocultan; se reactivan a 14 m de otra zona o hasta 30 m dentro de la zona actual, antes de entrar en el radio visible. La aspiradora y la recogida mantienen intactas sus distancias cortas. Los callbacks de enfriamiento de empuje solo se ejecutan durante un empuje activo.

## Validación

- `tests/cinema_expansion_smoke.gd`: verifica progresión 94/95 %, objetivos, palancas 3/4, altavoces, pantallas, 162/144 asientos, pasos libres, escalones, marcos interiores, decoración y materiales por tema, distancia de cámara, cierre del hueco hacia la Sala 3, muro final, separación del vestíbulo respecto a Sala 1 y transición de levantarse.
- `tests/trash_density_smoke.gd`: comprueba los recuentos y monedas de las ocho zonas construidas, la basura de la parte trasera y que ninguna pieza trasera de Salas 3/4 se coloque bajo las rampas de entrada. `tests/trash_layout_smoke.gd` comprueba además enterramiento y accesibilidad en Sala 1.
- Regresiones ejecutadas: `room_02_smoke`, `left_wing_smoke`, `movie_system_preparation_smoke`, `cinema_room_audio_smoke`, `roller_shutter_smoke`.
- `tests/cinema_map_relayout_capture.gd`: capturas del vestíbulo, los dos pasillos, accesos y salas, detalle de las juntas Sala 2/vestíbulo y Sala 3/pasillo, escaleras y lateral de Sala 3, fondo del manager, proyección desenfocada reproduciéndose y cenital orientada como el plano del usuario, en `docs/pipeline/screenshots/cinema_map_layout_v2/`. Usa una partida de prueba separada. Las capturas previas de la distribución descartada permanecen separadas.
- `tests/room_03_04_visual_capture.gd`: trece capturas de la nueva distribución visual en `docs/pipeline/screenshots/room_03_action_room_04_fear/`, incluyendo la pantalla de Sala 4 desde la entrada con cámara a 80 m, decoraciones, marcos por dentro, pasillos laterales y muro final. Conserva las capturas antiguas.
- `tests/lever_activation_profile.gd`: en ventana OpenGL, la primera palanca de Sala 1 pasó de un primer fotograma de 605 ms a ~90 ms tras el precalentamiento; la activación síncrona y el guardado ya estaban por debajo de 25 ms. La película se reproduce después de activar la palanca.
- `tests/cinema_expansion_profile.gd`: ventana oculta, OpenGL, 1280×720, Intel Arc 130V; cámara a 80 m, 588 butacas y 1212 objetos de basura. La pasada posterior a este cambio obtuvo 60 FPS sintéticos en las tres vistas (vestíbulo, Sala 3 y Sala 4), con 1185/284/355 draw calls respectivamente. El vestíbulo había variado entre ~30 y ~53 FPS en pasadas anteriores, por lo que sigue requiriendo playtest manual antes de afirmar un presupuesto estable. OpenGL puede emitir avisos de liberación de texturas al cerrar la prueba; no aparecen durante el test headless.
- Tras el pulido de Sala 3, una pasada repetida del mismo perfil obtuvo 547 draw calls y 60 FPS en Sala 3 (antes 531 y 60 FPS); +109 nodos en el mapa completo, ~4.000 primitivas visibles más desde esa sala y ~0.5 MiB de memoria estática más. Una primera pasada aislada bajó a 35 FPS en Sala 3, pero la repetición volvió a 60: se mantiene la advertencia de variabilidad y la necesidad de playtest manual, sin atribuirla a las luces nuevas sin evidencia.
- Con la densidad actual de 2763 objetos, el mismo perfil a 1280×720 y OpenGL midió **60 FPS sintéticos** en vestíbulo, Sala 3 y Sala 4 después del streaming de basura (2133/746/861 draw calls; física ~9.8/10.9/11.4 ms). Antes de ese control, la misma densidad caía a ~12–19 FPS. La cifra sigue requiriendo una pasada manual en el equipo objetivo y con películas activas.

Queda pendiente una revisión manual completa del recorrido en primera persona. El catálogo de documentos ya avisa de que solo hay 2 de las 12 definiciones previstas; es anterior a esta ampliación.
