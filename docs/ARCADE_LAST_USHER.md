# Segunda recreativa — El último acomodador

La máquina del pasillo izquierdo conserva modelo, posición, interacción,
descubrimiento, pausa modal y nombre. `main.tscn` ahora conecta el mueble a
`scripts/arcade_last_usher_survivor.gd`. El prototipo anterior por casillas,
`scripts/arcade_last_usher.gd`, permanece intacto para reversión; no se usa en
la partida. Los carteles y las claves de guardado de Normal y Difícil no cambian.

## Bucle de juego

Es un juego de supervivencia arcade de 1992 en un mapa abierto y desplazable,
sin casillas, obstáculos ni turnos. La cámara mantiene al personaje en el centro;
el suelo se desplaza y los enemigos aparecen fuera del encuadre. Dispara
automáticamente al enemigo cercano y recoge cintas de película que suben el
nivel. Cada barra de cinta completada pausa la acción y ofrece una mejora de
tres ramas; terminar un acto solo inicia el siguiente. En el último acto llega
el Rey de la Pantalla, con vida visible y una salva radial precedida por un
anillo rojo de aviso. Ganar requiere derrotarlo, no llegar a una salida.

- `WASD` o flechas: desplazamiento continuo, diagonales normalizadas, sin bordes de arena.
- Disparo automático: apunta al enemigo más próximo dentro de 150 píxeles.
- `Espacio`: dash breve con invulnerabilidad y recarga, tras desbloquearlo.
- Cintas: experiencia y puntuación; palomitas: vida; imán: atrae cintas próximas.
- Disparo (5 pasos): cadencia, daño, doble tiro, cuatro tiros y proyectiles
  evolucionados de mayor tamaño, todavía finos.
- Orbital (5 pasos): una, dos y tres bobinas; daño y órbita evolucionada de cuatro
  bobinas. El daño por contacto nunca supera el de una bala y tiene recarga.
- Supervivencia (3 pasos): vida máxima, velocidad y desbloqueo del dash.
Al completar una rama, su carta deja de aparecer. Las cartas restantes se
recolocan en el centro y la navegación salta las ramas completas; si todas
están completas, llenar otra cinta no interrumpe la partida.

Las sombras ordinarias, los acomodadores patrulla y los carretes velocistas
tienen sprites y velocidades distinguibles. El jugador siempre es más rápido
en línea recta; la presión procede de la cantidad, del posicionamiento y de
los disparos del jefe, no de bloqueos en un laberinto. Los golpes conceden
1,5 s de invulnerabilidad en Normal y 1,25 s en Difícil. En el acto 3 y 4 hay
apagones visuales intermitentes que no impiden ver los sprites.

Las oleadas se regulan por intervalo y población objetivo: de 0,72 a 0,40 s
entre apariciones por acto en Normal, acelerándose un 16 % durante cada acto;
Difícil reduce el intervalo un 16 %. El objetivo visible de población va de
14 a 41 enemigos en Normal y añade cinco en Difícil. Si la población cae por
debajo de la mitad, aparecen de dos en dos. Los enemigos muy lejanos se reciclan.
Es una adaptación a la escala de esta recreativa de la progresión temporal usada
en juegos del género, no un valor exacto de *Vampire Survivors*. El disparo ahora
es una línea fina y un punto de luz; al impactar produce un breve retroceso,
destello de color y número de daño. Se eliminaron los halos blancos.
Además, los enemigos nuevos ganan +1 punto de vida cada 80 s de partida
(máximo +3) y la velocidad crece gradualmente hasta un +15 %. El jefe suma
4 puntos de vida por cada tramo alcanzado; su barra usa su vida máxima real.
El daño de contacto y la invulnerabilidad tras recibirlo permanecen intactos.

Los actos duran 70/75/80/100 s en Normal y 75/80/85/110 s en Difícil. El jefe
entra a los 45 s del cuarto acto, por lo que una partida ganadora ronda cinco
minutos, según el combate final. Difícil añade enemigos, acelera sus llegadas
y movimiento, endurece sus vidas en actos avanzados y aumenta la vida y el
número/velocidad de proyectiles del jefe. La dificultad fina aún necesita la
prueba manual del jugador.

La música 8-bit se sigue sintetizando en memoria. Se reutilizan los tres SFX
arcade ya aprobados para selección, recogida/ataque y daño. La tipografía
bitmap es la misma que usa la primera recreativa. Las cartas de mejora muestran
iconos específicos, progreso por marcas y próxima mejora. La cinta se dibuja
como tira perforada y las bobinas orbitales como discos, tanto en el HUD como
en el escenario. El manual también usa
iconos pixelados dibujados en código. El sprite del protagonista respira en
reposo, rebota suavemente al caminar y se estira con estela durante el dash.

## Sprites nuevos

Cinco sprites transparentes originales se generaron con la herramienta
integrada de imágenes, sin usar ni sobrescribir assets legacy. Fuentes de alta
resolución: `art_source/arcade_last_usher_survivor/`. Versiones de juego de
22–44 px: `assets/pipeline/arcade_last_usher_survivor/`. El script
`tools/build_usher_survivor_sprites.gd` rehace las versiones compactas con
interpolación Lanczos; Godot las dibuja con filtro nearest. El acomodador, tres
tipos de enemigo y el jefe tienen siluetas y colores separados. Proyectiles,
recogibles y bobinas se dibujan en código porque son formas de 2–6 px.

## Progresión y pruebas

Normal concede `arcade_second_game_normal_poster` (hueco 13); Difícil concede
`arcade_second_game_hard_poster` (hueco 14), que completa «¡¿Otra consola
más?!». `tests/arcade_last_usher_smoke.gd` comprueba integración con la
máquina, desplazamiento, mejoras por cinta, disparos múltiples, dash bloqueado
y desbloqueado, jefe, guardado y objetivo.
`tests/arcade_last_usher_balance.gd` cubre 512 posiciones de aparición,
aparición fuera de cámara, velocidades, duración, desbloqueo orbital y estrés de 50 s
simulados en ambos modos. `tests/arcade_last_usher_visual_capture.gd` captura
menú, manual, partida, variantes de enemigo, impacto, mejora, jefe y finales.
