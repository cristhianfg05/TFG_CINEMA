# Sistema de figuras coleccionables

## Arquitectura

- `CollectibleCatalog` es la fuente de datos. Cada figura tiene un ID estable, número, título, ubicación interna, descripción, escena visual y ajustes de previsualización.
- `CollectiblePickup` es una escena física genérica que solo expone `collectible_id`. Carga el modelo indicado por el catálogo y reutiliza el contrato de interacción `E` del jugador.
- `GameplayManager` continúa siendo el único propietario del progreso. La versión 4 del guardado común añade IDs de figuras encontradas, IDs de figuras vistas y la última figura seleccionada, manteniendo compatibilidad con versiones 1–3.
- `UpgradeMenu` continúa siendo el único listener de Tab. Documentos y figuras publican el mismo evento genérico de descubrimiento con tipo, ID, textos y sección de destino.
- `CollectiblesView` vive dentro del menú existente. Genera diez huecos desde índices, crea vistas 3D únicamente para figuras encontradas y detiene sus `SubViewport` fuera de la sección.

## Contenido actual

Las diez figuras tienen identidad, texto y modelo GLB definitivo en `assets/models/source/collectibles/1.glb` … `10.glb`. El menú conserva los huecos desconocidos hasta descubrirlas; los cuatro carteles de recreativa siguen ocupando los números 11–14.

| Nº | Figura | Situación física |
| --- | --- | --- |
| 1 | Capitán Órbita | Sala 1, detrás del altavoz frontal izquierdo |
| 2 | Amelia del Andén | Sala 2, pasillo delantero bajo los corazones |
| 3 | El Hombre del Paraguas | Sala 2, cortina lateral de la pantalla |
| 4 | Palomito | Vestíbulo, zona prevista para el puesto de palomitas |
| 5 | Reina Refresco | Vestíbulo, zona prevista para la taquilla |
| 6 | El Devorapalomitas | Sala 4 (Miedo), zona de decoración junto a las calaveras |
| 7 | El Acomodador sin Rostro | Sala 4 (Miedo), junto a la última fila |
| 8 | Detective Mecha Corta | Sala 3 (Acción), altavoz frontal |
| 9 | Paloma Dinamita | Sala 3 (Acción), suelo del lateral delantero |
| 10 | La Dama de la Linterna | **Pendiente:** Antigua Sala Palace y su vitrina dañada no existen todavía. No hay pickup en el mapa. |

La tabla original del diseño llamaba Sala 3 a Miedo y Sala 4 a Acción. Se sigue la temática del mapa actual, confirmada por el usuario: Miedo es la Sala 4 y Acción la Sala 3.

Los puestos de palomitas, la taquilla y la barandilla aún no están construidos. Las figuras 4, 5 y 9 descansan en el suelo de sus zonas previstas; habrá que revisar sus coordenadas cuando lleguen esos elementos. No se ha añadido decoración nueva como parte de esta integración.

Cada pickup tumba su GLB a −90° en X, calcula el apoyo a partir del AABB importado, mantiene escala 1:1 y no flota, gira ni emite luz. La figura 5 mide 0,15 m en el archivo recibido, bastante menos que las demás (~1 m): se ha respetado ese tamaño en el mundo. Solo la previsualización de Tab amplía el modelo para poder verlo. El modelo provisional de Capitán Órbita no se referencia ya, pero se conserva como legacy.

La recogida sigue el flujo existente: `GameplayManager` guarda el ID, el HUD reproduce el piano de objetivo aprobado, el menú muestra el aviso y `RecordingDirector` activa las grabaciones 09 al encontrar una figura y 10 al reunir cinco. La grabación 17 requiere las diez y, por tanto, espera la Sala Palace.

## Exportación

El proyecto usa `all_resources`; el catálogo referencia directamente los diez GLB. Antes de una entrega pública deberá repetirse una exportación PCK con estos modelos nuevos.

## Añadir una figura futura

1. Crear una escena exclusivamente visual, sin `Area3D`, colisión ni script de recogida.
2. Añadir una definición a `resources/collectibles/collectible_catalog.gd` con `id`, `number`, `title`, `location`, `description`, `model_scene`, `preview_scale`, `preview_offset` y `preview_rotation`.
3. Instanciar `scenes/gameplay/collectible_pickup.tscn` en la zona correspondiente y asignar su `collectible_id` al ID estable de la definición.
4. No crear tarjetas manuales: la cuadrícula, la ficha, el indicador nuevo y el guardado se generan desde esos datos.

Para añadir la figura 10 cuando exista la Sala Palace basta instanciar `collectible_pickup.tscn` con `collectible_id = "dama_de_la_linterna"` en su vitrina dañada. El catálogo y el guardado ya están preparados.

## Archivos creados

- `resources/collectibles/collectible_catalog.gd`
- `scenes/collectibles/capitan_orbita_model.tscn`
- `scripts/collectible_pickup.gd`
- `scenes/gameplay/collectible_pickup.tscn`
- `scripts/collectibles_view.gd`
- `tests/collectible_system_smoke.gd`
- `docs/COLLECTIBLE_SYSTEM.md`
- Los `.uid` asociados que genera Godot para los scripts nuevos.

## Archivos modificados

- `scripts/gameplay_manager.gd`: datos en memoria, recogida, estados encontrada/vista, señales y guardado v4.
- `scripts/upgrade_menu.gd`: sección Coleccionables, deep-link y notificación genérica compartida.
- `scenes/main/main.tscn`: única instancia de `capitan_orbita`.
- `tests/document_system_smoke.gd`: aserciones actualizadas para la notificación genérica.
- `docs/DOCUMENT_SYSTEM.md`: convivencia y guardado compartido documentados.
- `docs/TEST_LOG.md`: resultado de verificación.
