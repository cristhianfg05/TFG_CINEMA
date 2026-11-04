---
name: cinema-asset-to-godot
description: Valida e incorpora un asset GLB nuevo del pipeline en Godot sin modificar ni sustituir assets legacy.
---

# De GLB a Godot

Usa esta Skill tras exportar un GLB nuevo a `assets/pipeline/`.

1. Valida el GLB, escala, orientación, pivote y materiales antes de importarlo.
2. Importa el asset sin modificar rutas ni importaciones legacy.
3. Crea una escena contenedora `.tscn` solo cuando corresponda al estándar existente.
4. Añade un collider simple; no uses automáticamente un mesh collider complejo.
5. Aplica categorías o grupos únicamente si el proyecto ya tiene un estándar para ello.
6. Ejecuta una escena de prueba segura, revisa errores y captura una imagen con Godot MCP cuando esté disponible.
7. Entrega un resumen de archivos nuevos, validaciones, incidencias y rendimiento esperado.
