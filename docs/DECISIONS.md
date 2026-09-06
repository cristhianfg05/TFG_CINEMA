# Registro de decisiones

| ID | Fecha | Decisión | Motivo | Estado |
|---|---|---|---|---|
| D-001 | 2026-09-06 | Godot 4.7 Standard y GDScript para Windows | Reducir dependencias y mantener el stack del plan | Aceptada |
| D-002 | 2026-09-06 | Objetivo 1920×1080 a 60 FPS | Objetivo de escritorio común y medible | Aceptada por el usuario |
| D-003 | 2026-09-06 | Controles WASD, ratón, Espacio, Mayús, Ctrl, E y Escape | Convención de primera persona en PC | Aceptada por el usuario |
| D-004 | 2026-09-06 | Hardware mínimo provisional: 4 núcleos, 8 GB RAM y GPU dedicada de 4 GB | Base conservadora para pruebas tempranas | Aceptada provisionalmente; pendiente de medición real |
| D-005 | 2026-09-06 | Guardar fuentes aprobadas en `source_assets/`; originales pesados y descartes en `source_assets/local_originals/`, fuera de Git | Evitar inflar el repositorio sin sacar Blender de la carpeta de trabajo | Aceptada provisionalmente |
| D-006 | 2026-09-06 | Usar Forward+ desde la creación del proyecto | Es la decisión bloqueada del plan y la opción indicada para un juego 3D de escritorio | Aceptada |
| D-007 | 2026-09-06 | Controlador provisional de 1,8 m, cámara a 1,65 m, 4,5 m/s al caminar y 7 m/s al correr | Valores iniciales coherentes con primera persona | Aceptada por el usuario tras probar FASE 1 |
| D-008 | 2026-09-06 | Bolsa basada en volumen con capacidad inicial 10; la recompensa queda pendiente hasta vaciar | Evita superar capacidad y duplicar monedas mediante descargas repetidas | Aceptada por el usuario tras probar FASE 2 |
| D-009 | 2026-09-06 | Atenuar los tonos provisionales, bajar sus frecuencias y reducir su amplitud | La prueba manual detectó que el audio inicial era demasiado alto y estridente | Aceptada por el usuario |

## Política de originales pesados

`source_assets/local_originals/` está ignorado por Git. Debe copiarse periódicamente a una unidad o nube de respaldo; Git no protege ese contenido. Solo los `.blend`, `.glb` u otros assets aprobados y optimizados pasan a rutas versionadas y Git LFS.
