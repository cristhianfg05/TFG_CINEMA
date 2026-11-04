# Pasillo izquierdo y despacho del manager

Implementación: 2026-09-14.

> Documento histórico de aquella fase. El pasillo descrito aquí se llama ahora **pasillo derecho**; `left_corridor` se conserva solo como ID de guardado. La planta vigente está en [CINEMA_MAP_EXPANSION.md](pipeline/CINEMA_MAP_EXPANSION.md).

## Zonas y alcance

- `room_01`: Sala 1 existente, sin reconstrucción. Conserva su única papelera y su desbloqueo al 95 %.
- `left_corridor`: pasillo izquierdo inicial. Registra 90 objetos fijos, 100 unidades y 100 monedas base.
- `manager_office`: despacho del manager. Registra 18 objetos fijos, 20 unidades y 20 monedas base.
- `room_02`: solo existe su acceso cerrado; la Sala 2 no está construida.

No se añadió ninguna papelera. `ManagerLostFoundBox` reutiliza `lost_found_box.tscn`, solo entrega objetos perdidos y no puede vaciar la bolsa.

## Recursos reutilizados

- Arquitectura: materiales compartidos `cinema_charcoal.tres`, `cinema_cream.tres`, `cinema_panel_wine.tres`, `cinema_stage.tres` y `cinema_step_light.tres`.
- Acabado del pasillo: materiales compartidos `corridor_aged_plaster.tres` y `corridor_worn_floor.tres`, con patrones SVG mate y repetibles creados dentro de Godot.
- Persiana: `roller_shutter_door.tscn`, sus tres materiales compartidos y `CinemaDoorCatalog`.
- Mesa: `assets/models/source/decoration/MesaCuadrada.glb`.
- Decoración del pasillo: `Taburete.glb`, `MaquinaRecreativa.glb`, `Sillón.glb` y `ExpositorPatatas.glb` del set suministrado.
- Zona de descanso: `MesaRedonda.glb` con cinco taburetes. La expendedora queda junto a la puerta de Tutorial y girada hacia el pasillo; la recreativa está rotada 180°.
- Pared de Sala 2: sillón y expositor de patatas separados de la persiana y orientados hacia el pasillo.
- Aspiradora: `assets/models/source/tools/aspiradora.glb`.
- Boti: `assets/models/source/tools/robotito.glb`.
- Basura: las ocho definiciones y `trash_item.tscn` existentes.
- Compra, economía, propiedad, equipamiento, mejoras y guardado: `GameplayManager`, `GameplayHUD`, `UpgradeMenu` y `ToolShopPanel` existentes.

## Persiana modular

`CinemaDoorCatalog.instantiate_for(access_id, narrow)` es la única fábrica:

- Ancha: `narrow = false`; hueco de 3,0 × 2,8 m.
- Estrecha: `narrow = true`; hueco de 1,6 × 2,5 m.

Cada puerta duplica una vez las mallas parametrizadas por función, no por lama. Sus catorce lamas comparten la misma `BoxMesh` y el mismo material. La apertura conserva el tamaño de las lamas, las eleva dentro del cajón y desactiva la colisión cuando existe altura de paso. `open_door()` y `close_door()` siguen expuestos.

La puerta del despacho reutiliza `room_completed`, que ya es persistente. La puerta de Sala 2 permanece cerrada y marcada como contenido futuro.

La persiana de Sala 2 está centrada en `x = 9`, directamente opuesta a la salida de Tutorial. El pasillo se amplió hasta `z = 25`; detrás de la persiana queda reservado un volumen de Sala 2 con las mismas dimensiones que Tutorial y sin construir todavía. El lado izquierdo continúa siendo desmontable para la futura conexión con el vestíbulo.

`Room01ReturnZone` restablece el ID `room_01` al regresar por la puerta. Esta transición reutiliza `PlayerController.room_changed`, por lo que actualiza el título/porcentaje del HUD y cambia inmediatamente la sala filtrada por «El ojo que todo lo ve».

## Herramientas

- ID físico estable de la aspiradora: `hand_vacuum`. Se normaliza al ID de inventario ya existente `vacuum`; no existe un segundo inventario ni una migración de guardado.
- ID estable de Boti: `boti`.
- Precios: 650 y 1600 monedas, descontados una sola vez por `GameplayManager.purchase_tool()`.

`ToolShopPanel` se generalizó como inspección individual: una copia visual sin colisión, navegación ni scripts se muestra en un `SubViewport`; Escape/Cancelar restauran pausa, ratón y control. Tab se consume mientras este modal está abierto y no crea otro listener.

La propiedad, herramienta equipada, pestañas y exposiciones de mesa se reconstruyen desde el guardado central (versión 7). Los residuos fijos guardan solo sus IDs estables y no reaparecen tras cargar.

## Estado funcional real

- Aspiradora: propiedad, compra, equipamiento y sus tres ramas están integrados. Mantener clic izquierdo consume batería, atrae mediante física únicamente la basura visible de la sala actual y recoge solo las unidades que caben. Con la bolsa llena conserva la atracción sin acreditar ni eliminar objetos. Incluye modelo lateral apuntando al centro, selector centrado, batería horizontal con rayo, viento animado y sonido provisional en bucle.
- Boti: propiedad, compra, pestaña y parámetros existentes están integrados. No ocupa una ranura de herramienta manual ni puede equiparse; su futura colocación en el suelo y la IA autónoma siguen siendo placeholders deliberados.
- Herramientas manuales: únicamente Mano y Aspiradora. La rueda del ratón alterna entre ambas cuando la aspiradora ya se ha comprado.

## Archivos

### Creados

- `scenes/rooms/left_wing_blockout.tscn`
- `scripts/left_wing_blockout.gd`
- `scripts/progression_shutter.gd`
- `scripts/room_zone.gd`
- `scripts/tool_display.gd`
- `tests/left_wing_smoke.gd`
- `assets/textures/corridor_aged_plaster.svg`
- `assets/textures/corridor_worn_tiles.svg`
- `resources/materials/corridor_aged_plaster.tres`
- `resources/materials/corridor_worn_floor.tres`
- Este documento.

### Modificados

- `scenes/main/main.tscn`
- `scripts/roller_shutter_door.gd`
- `resources/doors/cinema_door_catalog.gd`
- `scripts/gameplay_manager.gd`
- `scripts/trash_item.gd`
- `scripts/tool_shop_panel.gd`
- `scripts/gameplay_hud.gd`
- `resources/upgrades/upgrade_catalog.gd`
- `tests/phase_2_smoke.gd`
- `tests/trash_layout_smoke.gd`

## Verificación automatizada

`tests/left_wing_smoke.gd` valida recuentos 120/18, unidades 135/20, una sola papelera, variantes de puerta, posición opuesta de Sala 2, decoración permitida, retorno del ID de Tutorial, seguimiento de sala de «El ojo que todo lo ve», colisión al abrir, puerta futura cerrada, prompts, estados de monedas, descuentos exactos, compra única, ciclo Mano/Aspiradora, exclusión de Boti del equipo manual, pestañas, desaparición de exposiciones y persistencia de herramienta y basura fija.

`tests/phase_2_smoke.gd` y `tests/trash_layout_smoke.gd` verifican además que la asistencia ampliada de las piezas bajo butaca no cambia los recuentos, la física, la accesibilidad ni la recogida normal de Sala 1.

## Atajos provisionales de depuración

- `R`: reinicia también la basura fija del pasillo y del despacho.
- `Ctrl + Shift + F8`: concede 999.999 monedas, compra todas las herramientas, maximiza las mejoras, revela el contenido disponible, completa los objetivos actuales y retira toda la basura cargada de las tres zonas.

El segundo atajo es deliberadamente temporal y está centralizado en `GameplayManager` para retirarlo sin dejar listeners o managers adicionales.
