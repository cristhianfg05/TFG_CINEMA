# Biblia de arte

## Intención

El cine debe verse low-poly, barato, gracioso y ligeramente incómodo: formas claras, proporciones algo exageradas, superficies gastadas y suciedad legible sin caer en realismo desagradable.

## Reglas iniciales

- Trabajar en metros; 1 unidad de Godot equivale a 1 metro.
- Construir arquitectura mediante un kit modular en Blender/Godot.
- Usar Meshy solo para NPC, maquinaria, herramientas y props distintivos.
- Mantener siluetas legibles y materiales simples; evitar microdetalle que no afecte al juego.
- Favorecer paletas apagadas con uno o dos colores de acento por zona.
- Mantener una escala coherente: personaje aproximado de 1,8 m y puertas de unos 2 m.
- No usar mallas visuales complejas como colisión.
- No producir arte definitivo antes de validar la vertical slice.

## Pipeline mínimo de un asset

Concepto → generado/modelado → limpio en Blender → exportado a GLB → importado en escena contenedora → probado → aprobado o rechazado.

Los presupuestos de polígonos y las reglas finales se confirmarán en la FASE 4 con mediciones del profiler.

## Convenciones confirmadas en FASE 4

- Personajes en metros, con los pies sobre el origen y altura visual aproximada de 1,8 m.
- Frente del personaje hacia `-Y` en Blender. Godot 4.7 lo importa mirando a `+Z`; la escena contenedora gira el visual 180° para acordar `-Z` como frente jugable.
- LOD0 de NPC limitado a 15.000 triángulos y a un material siempre que no se degrade la lectura.
- GLB de producción en `assets/characters/production/`; fuente editable en `source_assets/blender/characters/`.
- Cada GLB se usa mediante una escena contenedora con colisión primitiva independiente.
- Los GLB generados se conservan sin rig hasta validar una estructura de huesos común.
