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

Para cada fallo futuro anotar pasos de reproducción, resultado esperado, resultado obtenido y severidad.
