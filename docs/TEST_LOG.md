# Registro de pruebas

| Fecha | Versión | Entorno | Prueba | Resultado | Incidencias |
|---|---|---|---|---|---|
| 2026-09-06 | FASE 0 | Godot 4.7 estable, Windows | Importación y validación del proyecto en modo headless | Superada; código de salida 0 | Sin errores del proyecto |
| 2026-09-06 | FASE 0 | Godot 4.7 estable, Windows | Ejecución de `main.tscn` en ventana | Superada; código de salida 0 | Sin errores del proyecto |
| 2026-09-06 | FASE 0 | RTX 2060, Vulkan | Inicialización de Forward+ | Superada; Godot selecciona la GPU dedicada | — |
| 2026-09-06 | FASE 0 | Git 2.49 + Git LFS 3.6.1 | Inicialización y filtros LFS | Superada | — |
| 2026-09-06 | FASE 0 | Clon temporal local | Clonar el repositorio etiquetado y ejecutar `main.tscn` | Superada | Se forzó copia normal por una limitación de enlaces físicos de Windows |

Para cada fallo futuro anotar pasos de reproducción, resultado esperado, resultado obtenido y severidad.
