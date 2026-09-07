# Informe de assets — FASE 4

Fecha de auditoría: 2026-09-07. Herramientas: Blender 5.2.1 LTS y Godot 4.7.

## Resultado de los cuatro personajes disponibles

| Asset | Altura | Triángulos | Materiales | Texturas | Transformaciones | Origen |
|---|---:|---:|---:|---|---|---|
| Encargado | 1,80 m | 14.974 | 1 | Base color, metallic/roughness y normal 2K incrustadas | Aplicadas | Pies |
| Hombre corpulento | 1,80 m | 14.975 | 1 | Base color, metallic/roughness y normal 2K incrustadas | Aplicadas | Pies |
| Empleado de palomitas | 1,90 m | 14.969 | 1 | Base color, metallic/roughness y normal 2K incrustadas | Aplicadas | Pies |
| Chico joven | 1,80 m | 14.975 | 1 | Base color, metallic/roughness y normal 2K incrustadas | Aplicadas | Pies |

Los cuatro GLB son una única malla sin vértices sueltos. La generación conserva numerosos bordes abiertos, por lo que no se han soldado automáticamente: hacerlo podría unir ropa, ojos y boca o dañar UV. Se eliminaron caras degeneradas, se recalcularon normales y se aplicó una reducción mínima solo a los modelos que superaban el presupuesto.

## Integración

- Cada GLB tiene una escena contenedora propia con colisión cápsula independiente.
- La escena contenedora absorbe el giro de 180° necesario para que el frente jugable sea `-Z`.
- `scenes/characters/manager.tscn` sustituye al placeholder sin cambiar el contrato de interacción ni la lógica de mejoras.
- `scenes/art/phase_4_character_showcase.tscn` presenta juntos los cuatro modelos para revisión visual.
- Los otros tres personajes no sustituyen todavía a espectadores sentados: no tienen rig ni animaciones y hacerlo introduciría T-poses en la sala jugable.
- Los scripts de `tools/blender/` permiten repetir auditoría, limpieza, exportación y previews sin ajustes manuales por asset.

## Perfil de la muestra

La galería de cuatro personajes se comprobó en Forward+ sobre una RTX 2060: 10 draw calls, 10 objetos renderizados, 104.834 primitivas contando pases de sombras y 53,7 MB de memoria estática. La ventana oculta usada por la prueba queda limitada por el compositor de Windows, por lo que su cifra de FPS no se considera una medición jugable; la fluidez final debe confirmarse en la prueba manual de la sala.

## Pendiente para cerrar la fase

- Incorporar un quinto asset diferente y hacerlo pasar por el mismo pipeline.
- Confirmar plan de Meshy, licencia aplicable, prompt y coste de cada generación.
- Probar Smart Rig y acordar nombres/estructura de huesos antes de generar animaciones.
- Aprobación visual del usuario y medición sostenida del profiler en la sala inicial.
- Solo entonces crear la etiqueta `phase-4-art-pipeline`.
