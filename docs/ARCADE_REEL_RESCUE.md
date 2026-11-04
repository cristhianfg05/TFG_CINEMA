# Recreativa derecha — Rescata el carrete

La recreativa del pasillo derecho usa `scripts/arcade_machine.gd` para integrarse
con el raycast existente y abre `scripts/arcade_reel_rescue.gd`, un `CanvasLayer`
modal a pantalla completa. El mundo se pausa, el HUD se oculta y ambos estados se
restauran al salir con Escape. La entrada y salida se representan con un breve
cierre/apertura de pantalla de recreativa. El menú incluye `CÓMO JUGAR`, con
las reglas y controles antes de comenzar la partida.

La interfaz se dibuja en una resolución lógica de 320×180, escalada por entero,
y usa un alfabeto bitmap propio para evitar el suavizado de la fuente del HUD
principal. Los cuatro carteles coleccionables usan las imágenes originales de
`assets/movies/room_1` a `room_4`.

## Partida renovada

El juego conserva el nombre y la música/SFX aprobados, pero ahora se presenta
como una cabina pixel-art de principios de los noventa. La cinta avanza por tres
carriles y la avería solo puede repararse cuando alcanza la franja dorada.
`A/D` o izquierda/derecha cambia de carril, `E`/espacio repara y mantener `S`
ralentiza la cinta mientras queda energía de foco. Una pulsación prematura o
una avería perdida cuesta una vida. Cada quinto carrete es cian: da dos
fotogramas, más foco y una vida al recogerlo, pero puede dejarse pasar sin
penalización. Las reparaciones seguidas aumentan el combo y devuelven una vida
cada tres aciertos. Hay cuatro actos con velocidad creciente; el cambio de
acto detiene brevemente la cinta para no tapar una ventana de reparación.

Normal dura 2:30, exige 36 fotogramas y empieza con 8 vidas. Difícil dura 3:00,
exige 50 fotogramas y empieza con 7 vidas. Ambas suman 5:30 si se ganan a la
primera; los reintentos amplían naturalmente esa duración. Sobrevivir sin
alcanzar la cuota no da el cartel.
El HUD solo muestra el total recuperado, sin indicar la cuota de victoria.
La velocidad de la cinta ahora va de 41 a 48,5 px/s en Normal y de 50 a
60,5 px/s en Difícil; los intervalos de aparición disminuyen por acto de
2,15 a 1,79 s y de 1,85 a 1,46 s, respectivamente.

## Recompensas persistentes

- `arcade_reel_rescue_normal_poster` — hueco 11, Sala 1, dificultad Normal.
- `arcade_reel_rescue_hard_poster` — hueco 12, Sala 2, dificultad Difícil.
- `arcade_second_game_normal_poster` — hueco 13, El último acomodador (Normal).
- `arcade_second_game_hard_poster` — hueco 14, El último acomodador (Difícil).

Los cuatro muestran su cartel original, cómo se obtienen y una breve sinopsis
en `resources/collectibles/collectible_catalog.gd`. Los IDs, números y datos de
guardado se mantienen. La implementación de la segunda recreativa se documenta
en `docs/ARCADE_LAST_USHER.md`.

## Objetivos de las dos recreativas

Un sensor en cada mueble comprueba que su centro aparece en la cámara y que un raycast no encuentra una pared delante. Al ver la primera recreativa aparece «¿Tienen consolas?»; solo se completa al ganar `Rescata el carrete` en Difícil, que otorga `arcade_reel_rescue_hard_poster`. Ganar en Normal no lo completa. Al ver la segunda aparece «¡¿Otra consola más?!»; solo se completa al ganar `El último acomodador` en Difícil y recibir `arcade_second_game_hard_poster`. El descubrimiento de ambas se guarda por separado.

`tests/arcade_smoke.gd` valida revelación, controles básicos, cuota, victoria
Normal/Difícil. `tests/arcade_gameplay_simulation.gd` simula
partidas completas con diferentes índices de acierto para comprobar duración y
balance; `tests/arcade_visual_capture.gd` captura menú, instrucciones y partida.
`tests/arcade_visibility_smoke.gd` comprueba el encuadre real de ambas máquinas.

La máquina del pasillo izquierdo reutiliza `ArcadeMachine` y comparte el gestor
de guardado y coleccionables, sin alterar la lógica de esta primera partida.
