# Fase 1 — Sala principal

## Alcance ejecutado

- Sustitución del bloque de 20 × 30 × 6 m por la sala 1 de 18 × 24 × 7 m.
- Pantalla de 12 × 5 m y escenario oscuro; la primera fila queda a más de 4 m de la pantalla.
- Dos bloques simétricos de 40 butacas (8 filas × 5 por bloque), importando `ButacaEstandar.glb` y usando colisiones de caja independientes.
- Pasillo central de 1,5 m y laterales de 1,2 m, definidos desde las aristas de colisión de las butacas.
- Filas escalonadas 0,25 m, rodapiés y pilares carbón, paneles granates, molduras crema y moqueta granate oscura.
- Cortinas granates, altavoces negros, rejillas, luces de pared, salida doble y vestíbulo acústico en L con los GLB de `assets/models/source/room_1`.
- Luces de escalón mediante emisión; no se han añadido luces dinámicas por fila.

## Materiales compartidos

Los ocho `StandardMaterial3D` de `resources/materials/cinema_*.tres` son compartidos por todos los módulos primitvos. No se crean materiales por pared, peldaño ni butaca.

## Verificación

`tests/phase_1_smoke.gd` comprueba dimensiones, 80 butacas importadas, geometría, cámara, movimiento, agacharse, reaparición y salto. También se ejecutó el smoke de fase 2 para comprobar que el bucle actual de limpieza sigue cargando.

## Ajuste posterior de sala

- Se retiraron los dos espectadores y el personaje del manager; la mesa permanece como prop interactivo para el trabajo posterior.
- Las butacas se giraron hacia la pantalla y aumentaron a escala 1,1. Sus colisiones conservan los anchos de pasillo especificados.
- Los escalones pasan a formarse con losas apiladas de 0,25 m: cada frente de escalón mide 0,25 m, sin muros acumulados entre filas.
- Se retiró el plano de película provisional que introducía líneas negras sobre la pantalla.
- Las rejillas se fijaron a las paredes laterales, con una rotación de 90 grados.

## Segunda revisión visual

- Las butacas suben a escala 1,32 y mantienen cinco plazas por bloque. La separación de colisiones entre filas es 1,12 m; permite el paso del personaje sin estrechar los pasillos laterales.
- La fila inicial conserva más de 4 m hasta la pantalla, y las ocho filas llegan hasta la circulación trasera.
- Se eliminaron la tarima, las cortinas y los marcos negros delante de la pantalla. Solo quedan dos columnas, una a cada lado, fuera de los 12 m de proyección.
- Los altavoces frontales se escalan a 1,8 y se colocan a ambos lados de la pantalla. Los altavoces y lámparas laterales rotan 90° y se elevan.
- El cubo se trasladó junto a la puerta de salida, sin bloquear su hueco; la mesa y el cajón de objetos perdidos están dentro del volumen jugable, detrás de los bloques de butacas.
- El controlador incorpora subida de peldaños de hasta 0,32 m. El smoke recorre en subida el pasillo central, con sus siete escalones de 0,25 m, sin salto.

## Tercera revisión visual

- La sala se amplía a 22 × 30 × 7 m y reserva aproximadamente 5 m de servicio/circulación detrás del graderío.
- El graderío pasa a 120 butacas: 10 filas, dos bloques de 6, escala 1,55 y separación horizontal de 1,36 m para que visualmente compartan los apoyabrazos.
- Los pasillos central y laterales son rampas físicas de pendiente suave. Se eliminó el desplazamiento vertical instantáneo del controlador; desde la zona trasera se representan dos únicos escalones con una colisión inclinada continua.
- La moqueta utiliza una textura SVG repetible de cuadrados granates y rojos con distintas tonalidades.
- Las luces emisivas marcan ambos bordes del pasillo central, los pasillos laterales y los frentes de cada cambio de nivel.
- La pantalla queda rodeada por cuatro vigas carbón, todas fuera del área de proyección.
- Cada paño lateral contiene una rejilla alta, un altavoz centrado debajo y dos luminarias verticales a sus lados; los elementos están orientados hacia el interior.

## Cuarta revisión visual

- La moqueta provisional se reemplaza por la imagen suministrada y se comparte en suelo, graderío y rampas. La segunda imagen suministrada se aplica a todos los paneles granates.
- La separación longitudinal entre filas aumenta 0,15 m.
- El desnivel del graderío sube de 0,72 a 1,17 m y cada fila aumenta 0,13 m. El acceso trasero muestra tres escalones macizos apoyados en el suelo.
- La colisión continúa siendo una pendiente suave bajo las rampas y escalones, sin teletransporte vertical del jugador.
- El pasillo central crece a 2 m y toca los graderíos; los laterales crecen a 1,9 m y llegan hasta las paredes.
- Los altavoces laterales giran 180° para mirar hacia la sala. Las luminarias se reducen, adelgazan y giran 90° en Z para quedar verticales.

## Quinta revisión visual

- Las paredes frontal y trasera se dividen en módulos de 4,4–4,7 m, equivalentes a los laterales, para conservar la orientación y densidad de las líneas verticales de la textura.
- Cada sección lateral recibe una única luz cálida tenue para sus dos luminarias. Son doce `OmniLight3D` sin sombras, con energía 0,32 y alcance 4,2 m.
- Los altavoces de pantalla aumentan de escala 2,1 a 3 y giran 35° hacia el graderío y el pasillo central.

## Sexta revisión visual

- Las cajas de colisión completas de las butacas se sustituyen por `ConcavePolygonShape3D` generadas desde las mallas importadas. Las formas se almacenan en caché y se reutilizan en las 120 instancias.
- Cada cambio de nivel usa una franja emisiva que atraviesa todo el ancho de los pasillos central y laterales; las tres franjas traseras también cubren el escalón completo.
- Las caras traseras de ambos graderíos se revisten con muros carbón macizos y una viga horizontal superior.
- Los cuatro cantos entre graderío, rampa central y rampas laterales reciben un revestimiento carbón escalonado hasta el suelo.

## Séptima revisión visual

- La moqueta usa proyección triplanar en coordenadas globales. El dibujo mantiene la misma escala y continuidad en el suelo plano, rampas, graderíos y escalones, sin estirarse con las dimensiones de cada caja.
- Los remates carbón laterales se separan de la moqueta y quedan ligeramente por debajo de su cota para eliminar superficies coplanares y parpadeos. El revestimiento continúa por los tres escalones de acceso trasero.
- Las franjas emisivas del suelo se reducen a 1,8 cm de alto y 5,5 cm de fondo, empotradas 6 mm sobre la cota de cada suelo o peldaño.
- Los pilares de la pared trasera coinciden con las juntas reales de sus paneles de 4,7 m; el marco de la salida completa las dos divisiones restantes.

## Octava revisión visual y física

- Los dos altavoces frontales duplican su escala, de 3 a 6, y conservan su giro de 35° hacia el graderío y el pasillo central.
- Cada canto lateral escalonado incorpora una viga carbón de remate equivalente a la viga horizontal de la pared trasera; los remates continúan por los tres peldaños de acceso.
- Las veinte piezas de basura pasan a ser cuerpos rígidos ligeros, con gravedad, amortiguación alta, rebote mínimo y colisión física con sala y jugador. Las piezas laterales se recolocan en los pasillos de la sala ampliada.
- La altura de aparición sigue la pendiente del graderío y añade 22 cm de caída inicial, evitando que la basura nazca bajo el suelo.
- La esfera de apuntado se mantiene independiente. Tras aceptar la recogida, el objeto vuela y se encoge hacia el jugador durante 0,32 s; bolsa, recompensa y porcentaje solo se actualizan al finalizar.

## Novena revisión visual y física

- Las franjas emisivas de los tres pasillos interpolan su altura sobre la pendiente y rotan con el ángulo exacto de la rampa; ya no descansan sobre las cotas horizontales de los graderíos.
- Los remates carbón incorporan dos bordes exteriores nuevos junto a las paredes laterales. Sus faldones cubren la cara vertical completa y las luces se centran en el hueco libre entre remates, sin intersecciones.
- El contacto del jugador aplica a la basura un impulso horizontal pequeño en el punto real del choque. Las masas varían según el objeto y la velocidad lineal y angular está limitada, permitiendo que recipientes y piezas alargadas vuelquen o rueden sin bloquear el paso ni salir disparados.

## Décima revisión visual y física

- Los altavoces frontales avanzan 1,55 m hacia el graderío. Su colisión deja aproximadamente 0,88 m de paso detrás hasta la pared de la pantalla.
- Solo las rampas y los tres peldaños laterales reducen su anchura, de 1,90 a 1,60 m. Sus extremos exteriores permanecen en `X = ±11 m`, pegados a la pared; remates y luces se recolocan con el nuevo borde interior.
- La basura mantiene colisión con la arquitectura, pero usa excepciones de colisión con el jugador para no bloquearlo. Un área baja de 0,50 m detecta el roce y aplica impulsos mayores; la menor amortiguación y los nuevos límites permiten más desplazamiento y rodadura de forma controlada.

## Undécima revisión visual

- Se revierte únicamente el estrechamiento de las escaleras y rampas laterales: recuperan sus 1,90 m originales, continúan pegadas a las paredes y vuelven a alinear remates, franjas luminosas y basura lateral con ese ancho.

## Duodécima revisión visual

- Los altavoces frontales regresan a `Z = -13,35`, junto a la pantalla, y reducen ligeramente su escala de 6 a 5,4. Sus colisiones se reducen en la misma proporción y conservan el giro de 35° hacia el graderío.

## Decimotercera revisión física

- El resaltado de la basura importada deja de dibujar una capa alfa coplanar. Ahora duplica el material original y añade una emisión cálida tenue, conservando textura y color sin ghosting.
- Las colisiones físicas se extienden 1,2 cm por debajo de las mallas para mantener una separación visual segura respecto al suelo cuando los objetos se inclinan o ruedan.
- El empuje del jugador se reduce y cada objeto acepta un solo impulso cada 0,18 s. La basura se aparta sin colisión bloqueante, pero deja de recibir fuerza continuamente y de parecer arrastrada por el jugador.

## Decimocuarta revisión: economía y progresión

- La mesa del manager y el cajón de objetos perdidos se retiran de Sala 1. El cubo junto a la salida usa `assets/models/source/general/Papelera.glb`; la mesa y el cajón se reservarán para el futuro despacho.
- Sala 1 tiene ahora 400 residuos: 380 de 1 unidad/1 moneda y 20 de 2 unidades/2 monedas, para un máximo base de 420 monedas; el reloj perdido sigue valiendo 25 y no ocupa bolsa.
- La distribución usa una semilla procedural persistente: 60 piezas sobre butacas, 100 bajo su borde frontal accesible, 108 entre filas y 132 en suelo abierto, incluida la explanada trasera. Vasos, latas, botellas y cubos alternan poses, incluidas variantes tumbadas.
- Los colliders se derivan del volumen real importado y una guarda periódica rescata cualquier cuerpo que atraviese la rampa por un fallo puntual de física, manteniendo alcanzable el 100 %.
- Capacidad, tamaños, recompensas, costes, niveles, límites de sacos y multiplicadores monetarios pasan a enteros. La salida se abre al 95 % de limpieza sin exigir compras.
- `upgrade_catalog.gd` centraliza las 14 ramas activas y las compras de Aspiradora/Boti. El guardado conserva monedas, niveles, propiedad/equipamiento de herramientas, sacos y progreso.
- `UpgradeMenu` se abre con Tab, pausa el juego, libera el ratón y genera sus ramas desde el catálogo. Incluye cinco pestañas, detalle de efectos y requisitos, compra por niveles, bloqueos de herramienta, animación y 15 pictogramas SVG reutilizables con dos cursores propios.
- `ToolShopPanel` gestiona Aspiradora y Boti. Sus tarjetas distinguen bloqueada, disponible, comprada y equipada; Boti se conserva como propiedad futura, fuera del equipo manual.
- Sacos cerrados se desbloquean por mejora: con la bolsa llena, B crea un saco físico persistente, almacena unidades/valor/sala/estado, impide recoger basura mientras se transporta y se entrega al cubo en una sola operación.

## Fuera de alcance actual

- No se construyen todavía el despacho ni las restantes salas y pasillos del mapa general.
- La Aspiradora cuenta con compra, equipo, absorción física, batería, recarga, alcance y feedback audiovisual. La colocación y navegación de Boti continúa como placeholder para una fase posterior.

## Decimoquinta revisión de interacción

- `UpgradeMenu` reconoce tanto la acción configurada como una pulsación física directa de Tab; la asignación deja de exigir un `physical_keycode` especial.
- El alcance configurado conserva los valores del árbol, pero el raycast suma 0,75 m de margen vertical para llegar cómodamente desde la cámara a los objetos del suelo. El alcance efectivo inicial es 2,25 m.
- La papelera queda pegada al muro de salida y con su abertura orientada hacia la pantalla.
- El cooldown de recogida sigue rechazando interacciones anticipadas, pero ya no muestra mensajes ni prompts de espera.
