---
name: cinema-blender-prop
description: Crea y prepara un prop 3D nuevo, no orgánico, para CinemaCleaner mediante Blender MCP y el pipeline de assets nuevo.
---

# Props nuevos en Blender

Usa esta Skill para cualquier prop 3D nuevo y no orgánico. No la uses para editar o sustituir assets legacy.

1. Lee `docs/pipeline/STYLE_BIBLE.md` y `docs/pipeline/ASSET_BUDGETS.md`.
2. Define dimensiones, presupuesto de triángulos y uso esperado antes de modelar.
3. Inspecciona referencias y assets cercanos sin modificarlos.
4. Crea el prop mediante Blender MCP; usa primitivas, modificadores o modelado procedural cuando ayuden.
5. Revisa la silueta, aplica transforms, limpia la geometría y valida los triángulos y materiales.
6. Define el pivote de forma intencionada.
7. Guarda la fuente `.blend` bajo la categoría apropiada de `art_source/blender/`.
8. Exporta el GLB a la categoría correspondiente de `assets/pipeline/`.
9. Sigue `cinema-asset-to-godot` antes de considerarlo terminado.

No uses generación 3D externa automáticamente. Si Blender MCP no está disponible, detente y explica qué falta.
