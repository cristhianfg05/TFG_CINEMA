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
| D-010 | 2026-09-06 | Separar el reloj de la basura: `E` lo guarda y el clic izquierdo lo destruye con una penalización de 5 monedas | Hace visible la decisión, enseña destinos distintos y mantiene posible terminar aunque el jugador se equivoque | Candidata de FASE 3, pendiente de prueba manual |
| D-011 | 2026-09-06 | Costes provisionales: 10 monedas para `Manos ágiles I` y 20 para `Bolsa reforzada I`; la salida exige 95 % y ambas | La economía normal entrega al menos 37 monedas, o 32 tras destruir el reloj, evitando un bloqueo | Candidata de FASE 3, pendiente de prueba manual |
| D-012 | 2026-09-06 | El autoguardado de la vertical slice conserva monedas, mejoras, resultado del reloj y sala completada | Cumple la fase sin anticipar el sistema completo y migrable previsto para FASE 10 | Candidata de FASE 3, pendiente de prueba manual |
| D-013 | 2026-09-06 | La basura normal se recoge automáticamente al atravesar un área esférica proporcional a cada objeto; el reloj conserva interacción deliberada | Mejora la comodidad y elimina la necesidad de apuntar a objetos pequeños sin romper la decisión sobre objetos valiosos | Solicitada por el usuario durante FASE 3 |
| D-014 | 2026-09-06 | La recogida base tarda 1,00 s y `Manos ágiles I` la reduce a 0,18 s | La diferencia anterior de 0,45 s a 0,15 s apenas se percibía | Solicitada por el usuario durante FASE 3 |

## Política de originales pesados

`source_assets/local_originals/` está ignorado por Git. Debe copiarse periódicamente a una unidad o nube de respaldo; Git no protege ese contenido. Solo los `.blend`, `.glb` u otros assets aprobados y optimizados pasan a rutas versionadas y Git LFS.
