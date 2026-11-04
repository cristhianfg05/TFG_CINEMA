# Pipeline de assets nuevos

## Alcance

Este pipeline se aplica solo a contenido creado a partir de ahora.

- `source_assets/`, `assets/` fuera de `assets/pipeline/`, sus GLB, importaciones, escenas y referencias existentes son legacy.
- No se mueve, renombra, regenera, sustituye ni optimiza contenido legacy durante la adopción del pipeline.
- Las fuentes nuevas viven en `art_source/`, fuera del escaneo de recursos de Godot mediante `.gdignore`.
- Los entregables nuevos para Godot viven en `assets/pipeline/`, separados por categoría.

## Flujo obligatorio

1. Consultar Style Bible y Asset Budgets.
2. Definir propósito, dimensiones, categoría, repetición esperada y presupuesto.
3. Inspeccionar referencias cercanas sin modificarlas.
4. Modelar o limpiar en Blender; los props simples se hacen primero con Blender MCP cuando esté disponible.
5. Revisar silueta, geometría, transforms, materiales, escala y pivote.
6. Guardar la fuente editable en `art_source/blender/<categoría>/`.
7. Exportar GLB a `assets/pipeline/<categoría>/`.
8. Importar en Godot sin tocar rutas legacy; crear escena contenedora y collider simple cuando corresponda.
9. Validar en una escena de prueba segura: importación, escala, orientación, aspecto, errores y rendimiento.
10. Registrar el resultado mediante la Skill de auditoría y resumir incidencias.

## Assets externos

La generación 3D externa se reserva para objetos orgánicos o complejos. Nunca entra directamente en producción: debe pasar por Blender, cumplir este pipeline y conservar su fuente editable antes de integrarse.

## Criterios de salida

Un asset nuevo solo está listo cuando el modelo, materiales, pivote, escala, GLB, importación de Godot, collider, escena de prueba e impacto de rendimiento han sido revisados.
