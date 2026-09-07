# Registro de pruebas

| Fecha | Versión | Entorno | Prueba | Resultado | Incidencias |
|---|---|---|---|---|---|
| 2026-09-06 | FASE 0 | Godot 4.7 estable, Windows | Importación y validación del proyecto en modo headless | Superada; código de salida 0 | Sin errores del proyecto |
| 2026-09-06 | FASE 0 | Godot 4.7 estable, Windows | Ejecución de `main.tscn` en ventana | Superada; código de salida 0 | Sin errores del proyecto |
| 2026-09-06 | FASE 0 | RTX 2060, Vulkan | Inicialización de Forward+ | Superada; Godot selecciona la GPU dedicada | — |
| 2026-09-06 | FASE 0 | Git 2.49 + Git LFS 3.6.1 | Inicialización y filtros LFS | Superada | — |
| 2026-09-06 | FASE 0 | Clon temporal local | Clonar el repositorio etiquetado y ejecutar `main.tscn` | Superada | Se forzó copia normal por una limitación de enlaces físicos de Windows |
| 2026-09-06 | FASE 1 candidata | Godot 4.7 headless | Cargar escenas, 10 acciones, cámara, raycast, 60 butacas y geometría | Superada (`PHASE_1_SMOKE_OK`) | — |
| 2026-09-06 | FASE 1 candidata | Godot 4.7 headless | Movimiento, cambio de altura al agacharse, salto y reaparición | Superada (`PHASE_1_SMOKE_OK`) | La comodidad requiere prueba humana |
| 2026-09-06 | FASE 1 candidata | Forward+, RTX 2060 | Renderizar 60 fotogramas a 1920×1080 | Superada | Media: CPU 0,56 ms; GPU 8,07 ms por fotograma; falta prueba jugable sostenida |
| 2026-09-06 | FASE 1 | Prueba manual del usuario | Recorrido, controles, escala y funcionamiento general | Aprobada por el usuario | — |
| 2026-09-06 | FASE 2 candidata | Godot 4.7 headless | Recoger 20 objetos, limitar volumen, vaciar, cobrar y llegar al 100 % | Superada (`PHASE_2_SMOKE_OK`) | Salida sin errores ni objetos filtrados |
| 2026-09-06 | FASE 2 candidata | Godot 4.7 headless | Impedir monedas duplicadas y validar prompts de objeto, bolsa llena y contenedor | Superada (`PHASE_2_SMOKE_OK`) | — |
| 2026-09-06 | FASE 2 candidata | Forward+, 1920×1080 | Render visual de sala, primitivas, punto de mira y HUD | Superada | Falta prueba jugable de 5–10 minutos |
| 2026-09-06 | FASE 2 candidata | Prueba manual del usuario | Movimiento de cámara con ratón tras añadir el HUD | Falló; corregido, pendiente de repetir | El HUD interceptaba los eventos de ratón; sus controles ahora usan `MOUSE_FILTER_IGNORE` |
| 2026-09-06 | FASE 2 | Prueba manual del usuario | Bucle completo, cámara, capacidad, monedas y porcentaje | Aprobada por el usuario | Se solicitó bajar y suavizar el audio provisional antes de etiquetar |
| 2026-09-06 | FASE 2 | Godot 4.7 | Ajuste de tonos provisionales | Corregido | Frecuencias, amplitud y volumen reducidos |
| 2026-09-06 | FASE 3 candidata | Godot 4.7 headless | Separación basura/reloj, entrega, destrucción y penalización | Superada (`PHASE_3_SMOKE_OK`) | Destruir el reloj aún deja monedas suficientes para terminar |
| 2026-09-06 | FASE 3 candidata | Godot 4.7 headless | Comprar ambas mejoras, aplicar efectos y abrir salida al cumplir requisitos | Superada (`PHASE_3_SMOKE_OK`) | Capacidad 20 y recuperación de recogida reducida verificadas |
| 2026-09-06 | FASE 3 candidata | Godot 4.7 headless | Autoguardado y restauración de mejoras, reloj y sala completada | Superada (`PHASE_3_SMOKE_OK`) | Formato provisional versión 1 |
| 2026-09-06 | FASE 3 candidata | Forward+, RTX 2060, 1920×1080 | Render frontal y trasero de pantalla, espectadores y zona de servicios | Superada | Placeholders legibles; falta validar ritmo y comprensión con jugadores |
| 2026-09-06 | FASE 3 candidata | Godot 4.7 headless | Esfera de apuntado ampliada y recogida exclusivamente mediante `E` | Superada (`PHASE_3_SMOKE_OK`) | Caminar sobre la basura no la recoge; el raycast resuelve la esfera hacia su objeto |
| 2026-09-06 | FASE 3 candidata | Godot 4.7 headless | Cooldown entre recogidas base/mejorado | Superada (`PHASE_3_SMOKE_OK`) | Primera recogida inmediata; siguiente tras 1,00 s o 0,35 s con `Manos ágiles I` |
| 2026-09-06 | FASE 3 candidata | Windows x86_64 release | Exportar y ejecutar `0.3.0-playtest.1` fuera del editor | Superada; código de salida 0 | ZIP extraído y sus tres archivos verificados mediante SHA-256 |
| 2026-09-07 | FASE 3 candidata | Godot 4.7 headless | Separar recogida con clic derecho e interacción con `E` | Superada (`PHASE_3_SMOKE_OK`) | El reloj y las estaciones conservan sus acciones deliberadas |
| 2026-09-07 | FASE 3 | Windows x86_64 release | Exportar, ejecutar y verificar `0.3.0-playtest.2` | Superada; código de salida 0 | Los assets de entrada de FASE 4 quedaron excluidos; ZIP validado mediante SHA-256 |
| 2026-09-07 | FASE 3 | Aprobación del usuario | Vertical slice y control definitivo de recogida | Aprobada | Clic derecho para basura; `E` para interacciones contextuales |
| 2026-09-07 | FASE 4 candidata | Blender 5.2.1 LTS | Auditar, limpiar y exportar cuatro personajes | Superada | Todos quedan entre 14.969 y 14.975 triángulos, 1 material, escala aplicada y pies en el origen; rig pendiente |
| 2026-09-07 | FASE 4 candidata | Godot 4.7 headless | Cargar cuatro GLB, contenedores, colisiones y manager funcional | Superada (`PHASE_4_SMOKE_OK`) | Los espectadores reales no entran todavía en la sala por carecer de rig |
| 2026-09-07 | FASE 4 candidata | Godot 4.7 | Regenerar y reimportar el GLB del manager sin cambiar referencias | Superada | Escenas y script conservaron SHA-256; smoke posterior superado |
| 2026-09-07 | FASE 4 candidata | Forward+, RTX 2060 | Renderizar la galería de cuatro NPC con texturas | Superada | 10 draw calls y 104.834 primitivas con sombras; FPS de ventana oculta no representativo |
| 2026-09-07 | FASE 4 candidata | Godot 4.7 headless | Regresión de FASE 1, FASE 2 y FASE 3 | Superada | `PHASE_1_SMOKE_OK`, `PHASE_2_SMOKE_OK` y `PHASE_3_SMOKE_OK` |

Para cada fallo futuro anotar pasos de reproducción, resultado esperado, resultado obtenido y severidad.
