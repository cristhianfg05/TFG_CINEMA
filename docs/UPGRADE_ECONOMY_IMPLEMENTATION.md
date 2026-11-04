# Implementación: economía y árbol de mejoras v1

Fuente funcional: `ArbolMejoras.md`.

## Resultado

- Sala 1 mantiene su arquitectura actual y contiene 280 residuos procedurales: 240 de 1 unidad/moneda y 40 de 2 unidades/monedas, para 320 monedas base posibles.
- La semilla del reparto se conserva en el guardado. Hay residuos sobre butacas, bajo su borde accesible, entre filas y en pasillos; los recipientes pueden aparecer tumbados y una guarda física impide que terminen bajo el suelo.
- La economía de monedas, costes, capacidades, tamaños, cantidades, niveles, límites y multiplicadores usa enteros.
- El reloj perdido vale 25 monedas y se conserva en un inventario independiente de la basura.
- La mesa y el cajón de objetos perdidos ya no están en Sala 1. El cubo junto a la salida usa el GLB de `source/general/Papelera.glb`.
- El catálogo activo contiene 14 ramas y dos compras: Aspiradora y Boti. La pestaña general se llama `Limpieza`: comienza por Manos ágiles, Bolsa reforzada y Sacos cerrados, incorpora Sprint y elimina la rama provisional de correr agachado.
- `El ojo que todo lo ve` es una habilidad activa de tres niveles. Revela únicamente la basura perteneciente a la sala actual y actualiza el conjunto revelado cuando el jugador cambia de sala.
- `UpgradeMenu` se abre y se cierra con Tab sin pausar el juego, respeta otros modales y compra niveles independientes.
- `UpgradeMenu` incluye una sección de Objetivos dirigida por el progreso existente: limpieza de Sala 1, documentos y figuras. Los dos últimos objetivos permanecen ocultos hasta descubrir el primer elemento de su tipo.
- `ToolShopPanel` compra Aspiradora y Boti en la mesa del despacho. Solo Mano/Aspiradora forman parte del equipo manual; Boti queda comprado para su futura colocación física.
- La habilidad Sacos cerrados crea y guarda bolsas físicas visibles: `E` breve las suelta, `E` mantenida las lanza y la papelera las absorbe por proximidad antes de acreditar su valor entero.
- Los sacos libres o llevados se entregan cuando su collider entra en una esfera de 1 m centrada en la abertura de la papelera, independientemente del ángulo de llegada.
- Sprint usa una reserva persistente representada por una barra central dorada sobre fondo rojo oscuro. Se oculta al estar llena y sus niveles reducen la recarga completa de 7 a 3 segundos.
- El HUD usa los iconos aportados para capacidad de basura, objetos perdidos, Mano y Aspiradora; los dos contadores de inventario son tarjetas independientes del mismo tamaño.
- La capacidad de basura se representa como una máscara vertical dentro del icono: la versión dorada se revela al llenarse, el máximo permanece dentro y el volumen actual se muestra al lado. Se conserva el pulso de recogida.
- Debajo del dinero aparecen el acceso visual al diario con su tecla Tab y las habilidades activas adquiridas. Sacos cerrados usa la tecla `1` y muestra su cantidad; El ojo que todo lo ve usa `2` y muestra su cooldown persistente.
- Tab dispone de detección física de respaldo, y la recogida añade 0,75 m de margen al raycast para compensar la altura de la cámara sin rebalancear los valores del árbol.
- El guardado v5 conserva progreso, niveles, herramientas, sacos, documentos, figuras y cooldowns de habilidades activas. Las versiones anteriores continúan migrando mediante el cargador existente.

## Archivos creados

- `resources/upgrades/upgrade_catalog.gd`
- `scenes/gameplay/sealed_bag.tscn`
- `scenes/ui/upgrade_menu.tscn`
- `scenes/ui/tool_shop_panel.tscn`
- `scripts/sealed_bag.gd`
- `scripts/upgrade_menu.gd`
- `scripts/tool_shop_panel.gd`
- `assets/ui/icons/upgrades/battery.svg`
- `assets/ui/icons/upgrades/boti.svg`
- `assets/ui/icons/upgrades/boti_capacity.svg`
- `assets/ui/icons/upgrades/boti_rest.svg`
- `assets/ui/icons/upgrades/boti_speed.svg`
- `assets/ui/icons/journal.svg`
- `assets/ui/icons/popcorn_stamp.svg`
- `assets/ui/icons/upgrades/manual_reach.svg`
- `assets/ui/icons/upgrades/multi_pickup.svg`
- `assets/ui/icons/upgrades/quick_hands.svg`
- `assets/ui/icons/upgrades/recycle_value.svg`
- `assets/ui/icons/upgrades/reinforced_bag.svg`
- `assets/ui/icons/upgrades/sealed_bags.svg`
- `assets/ui/icons/upgrades/sprint.svg`
- `assets/ui/icons/upgrades/vacuum.svg`
- `assets/models/source/general/pointers/reticle_default.png`
- `assets/models/source/general/pointers/reticle_bag_full.png`
- `assets/models/source/general/pointers/cursor_default.png`
- `assets/models/source/general/pointers/cursor_menu_clickable.png`
- `docs/UPGRADE_ECONOMY_IMPLEMENTATION.md`

Godot genera los `.import` y `.uid` correspondientes a estos recursos al detectarlos.

## Archivos modificados

- `project.godot`
- `resources/lost_items/cheap_watch.tres`
- `resources/trash/trash_definition.gd`
- `resources/trash/bottle.tres`
- `resources/trash/bucket.tres`
- `resources/trash/can.tres`
- `resources/trash/cup.tres`
- `resources/trash/napkin.tres`
- `resources/trash/popcorn.tres`
- `resources/trash/straw.tres`
- `resources/trash/ticket.tres`
- `scenes/gameplay/gameplay_manager.tscn`
- `scenes/gameplay/trash_bin.tscn`
- `scenes/main/main.tscn`
- `scripts/gameplay_hud.gd`
- `scripts/gameplay_manager.gd`
- `scripts/lost_found_box.gd`
- `scripts/manager_npc.gd`
- `scripts/pause_menu.gd`
- `scripts/player_controller.gd`
- `scripts/trash_bin.gd`
- `scripts/trash_item.gd`
- `tests/phase_1_smoke.gd`
- `tests/phase_2_smoke.gd`
- `tests/phase_3_smoke.gd`
- `tests/phase_4_smoke.gd`
- `tests/phase_4_motion.gd`
- `tests/active_abilities_smoke.gd`
- `docs/PHASE_1_ROOM_REPORT.md`
- `docs/TEST_LOG.md`

## Archivos retirados

- `resources/upgrades/quick_hands_1.tres`
- `resources/upgrades/reinforced_bag_1.tres`
- `resources/upgrades/upgrade_definition.gd`

Eran la tienda provisional de dos mejoras. No tenían referencias tras activar el catálogo v1.

## Placeholders deliberados

Aspiradora y Boti tienen precio, propiedad persistente, modelos y ramas desbloqueables. La Aspiradora ya dispone de absorción física continua, batería, recarga y alcance mejorables. La navegación restringida y el ciclo de descarga/descanso/regreso de Boti se implementarán en una fase posterior.

## Verificación automática

- `PHASE_1_SMOKE_OK`
- `PHASE_2_SMOKE_OK`
- `PHASE_3_SMOKE_OK`
- `PHASE_4_SMOKE_OK`
- `PHASE_4_MOTION_OK`
- `ACTIVE_ABILITIES_SMOKE_OK`

Las pruebas cubren carga de escenas, colisiones principales, reparto y valor de basura, enteros, compras con y sin fondos, pestañas bloqueadas, Tab, exclusión modal, sacos visibles, soltar/lanzar con `E`, absorción, guardado y salida al 95 %.
