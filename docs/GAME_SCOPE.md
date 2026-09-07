# Alcance de Cinema Cleaner

## Decisiones bloqueadas

- Motor: Godot 4.7 estable, edición Standard.
- Lenguaje: GDScript.
- Plataforma inicial: Windows PC.
- Cámara: primera persona.
- Renderizador: Forward+.
- Resolución objetivo: 1920 × 1080 a 60 FPS.
- Duración final objetivo: 2–3 horas.
- Primera versión validable: una sala de 10–15 minutos.
- Dirección visual: low-poly feo, gracioso y ligeramente incómodo.
- NPC ambientales con posiciones y animaciones prefijadas, sin IA social compleja.
- NPC finales: Meshy T2, hasta 15.000 triángulos en LOD0.
- Escenarios: kit modular construido en Blender/Godot; Meshy no genera salas completas.
- Control de versiones: Git y Git LFS desde la fase 0.

## Plataforma mínima provisional

- Windows 10/11 de 64 bits.
- CPU de 4 núcleos equivalente a Intel Core i5-4590 o AMD Ryzen 3 1200.
- 8 GB de RAM.
- GPU dedicada compatible con Vulkan 1.0, equivalente a GTX 1050 Ti o RX 560, con 4 GB de VRAM.
- 4 GB de almacenamiento libre durante el MVP; el valor se revisará con builds reales.
- Teclado y ratón.

El hardware mínimo es una hipótesis de trabajo, no una promesa. Se validará mediante mediciones en una build exportada y en un segundo equipo.

## Controles iniciales

| Acción | Entrada |
|---|---|
| Avanzar / retroceder / izquierda / derecha | W / S / A / D |
| Saltar | Espacio |
| Correr | Mayús izquierda |
| Agacharse | Ctrl izquierda |
| Interactuar | E |
| Recoger basura | Botón derecho del ratón |
| Herramienta principal | Botón izquierdo del ratón |
| Pausa | Escape |

## Fuera del MVP

- Multijugador, mundo abierto y clientes con navegación libre.
- Conversaciones ramificadas y sistemas reales de venta.
- Películas largas, generación procedural de habitaciones e inventario con cuadrícula.
- Personalización completa del protagonista y versiones para consola o móvil.

## Estado

- FASE 0 — Preparación y control del alcance: completada el 2026-09-06.
- FASE 1 — Controlador y sala inicial en bloques: completada y aprobada el 2026-09-06.
- FASE 2 — Núcleo de limpieza: completada y aprobada el 2026-09-06.
- FASE 3 — Primera vertical slice: completada y aprobada el 2026-09-07.
- FASE 4 — Pipeline artístico definitivo: en curso; cuatro personajes han llegado a importación y falta un quinto asset, rig y aprobación final.
- No autorizado todavía: contenido de FASE 5 o posteriores.
