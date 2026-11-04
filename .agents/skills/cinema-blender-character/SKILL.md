---
name: cinema-blender-character
description: Prepara personajes o criaturas 3D nuevos para CinemaCleaner mediante Blender, con control de rig, pesos, animaciones y exportación a Godot.
---

# Personajes y criaturas nuevos

Usa esta Skill solo para personajes o criaturas nuevos. No alteres personajes existentes automáticamente.

- Lee la biblia de estilo y los presupuestos antes de empezar.
- Reutiliza esqueletos cuando sea posible y evita rigs distintos sin una razón técnica.
- Conserva T-pose o A-pose cuando el personaje vaya a riggearse.
- Separa la exploración conceptual de un modelo apto para producción.
- Si parte de una generación externa, límpialo en Blender antes de integrarlo.
- Revisa weight painting, transforms, pivote, escala y animaciones antes de exportar.
- Guarda fuentes en `art_source/blender/characters/` y exporta entregables a `assets/pipeline/characters/`.
- Continúa con `cinema-asset-to-godot` y no declares el asset finalizado hasta validar su importación y animaciones en Godot.
