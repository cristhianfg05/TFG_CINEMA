# Presupuestos iniciales de assets

Estos presupuestos son guías iniciales para assets nuevos. No son límites universales ni autorizan optimizar o sustituir assets legacy.

| Categoría | Guía inicial de triángulos |
| --- | ---: |
| Basura procedural muy frecuente | 50–500 |
| Basura o prop pequeño | 100–800 |
| Prop medio | 500–2.500 |
| Prop grande | 1.500–6.000 |
| Hero prop justificado | hasta ~10.000 |
| NPC | objetivo aproximado de 10.000–20.000 |

Evita un asset de 8.000 triángulos para basura que pueda aparecer cientos de veces. El coste real depende de repetición, materiales, sombras, distancia y visibilidad, no solo de la malla.

## Materiales y texturas

- Priorizar pocos materiales por asset y reutilización razonable.
- Elegir la resolución de textura por distancia de cámara y área visible; no usar resoluciones grandes por defecto.
- Para props pequeños o repetidos, preferir color por vértice, materiales compartidos o texturas compactas cuando mantengan la lectura.
- Documentar siempre cantidad de materiales, texturas y resolución durante una auditoría.

## Física, sombras e instancing

- Preferir colliders simples; no generar mesh colliders complejos de forma automática.
- Limitar sombras en objetos pequeños, repetidos o que no aporten lectura visual.
- Considerar instancing o MultiMesh para assets muy repetidos, después de medir la escena relevante.
- Aplicar LOD solo cuando la escala, repetición y distancia al jugador compensen su complejidad.
