---
name: cinema-performance-budget
description: Evalúa el presupuesto de rendimiento de una escena de CinemaCleaner que incorpora muchos assets, luces o elementos físicos.
---

# Presupuesto de rendimiento de escena

Usa esta Skill cuando una escena vaya a incorporar muchos elementos o cuando exista duda sobre su coste.

Considera triángulos visibles, nodos y objetos, draw calls, materiales, sombras, luces, colliders, física, distancia al jugador y LOD. Evalúa MultiMesh o instancing cuando haya repetición suficiente para justificarlo.

Relaciona la recomendación con `docs/pipeline/ASSET_BUDGETS.md`. Las cifras son guías iniciales, no permisos para modificar u optimizar assets legacy.
