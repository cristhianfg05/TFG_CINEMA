# Sistema de documentos

## Arquitectura

- `DocumentCatalog` carga y valida, por orden de nombre, los TXT de `res://assets/notes/`. El nombre de archivo sin extensión es el ID estable. La línea 1 es el título; la línea 2 es metadata interna de colocación y nunca se muestra; la línea 3 es el subtítulo visible que indica dónde se encontró; el cuerpo comienza en la línea 4.
- `GameplayManager` conserva el único guardado del juego. Los documentos siguen guardando sus IDs encontrados, sus IDs leídos y la última selección; la versión 4 del mismo archivo añade las figuras sin serializar el texto de los documentos.
- `DocumentPickup` reutiliza la interacción `E`, el enfoque y el raycast del jugador. No usa la bolsa, la limpieza ni las recompensas.
- `UpgradeMenu` sigue siendo el único controlador de Tab. Habilidades mantiene su comportamiento no pausado; Documentos y Coleccionables comparten el mismo bloqueo por pausa, ratón visible y procesamiento permanente. Escape y Tab cierran ambas secciones.
- La notificación superior es ahora un componente genérico de descubrimientos: recibe tipo, ID, textos y sección de destino. Los documentos mantienen su deep-link al TXT concreto sin listeners adicionales de Tab.

## Contenido actual

- Total contractual mostrado: 12.
- TXT presentes: 2.
- Definiciones válidas: 2 (`Doc1` y `Doc2`), ordenadas por nombre de archivo.
- El jugador comienza delante de la butaca interior izquierda de la primera fila, fuera del pasillo central.
- `Doc1` indica `Primera fila sala 1, enfrente del jugador al comenzar` y está delante de esa nueva posición inicial, a ras del suelo.
- `Doc2` indica `Última fila de Sala 1` y está colocado en la última fila de Tutorial.

## Exportación

Los dos presets incluyen explícitamente `assets/notes/*.txt`. La comprobación con un PCK real confirmó que contiene `Doc1.txt`, `Doc2.txt`, el cargador, la escena física y el icono; el PCK ejecutado volvió a cargar las dos definiciones válidas. La detección del BOM compara su código Unicode para no perder el primer carácter de los títulos en una compilación release.

## Archivos

### Creados

- `resources/documents/document_catalog.gd`: lectura, normalización y validación dirigida por datos.
- `scripts/document_pickup.gd`: interacción física reutilizable y retirada permanente.
- `scenes/gameplay/document_pickup.tscn`: hoja provisional con malla y área de interacción.
- `resources/materials/document_paper.tres`: material crema mate compartido.
- `assets/ui/icons/document.svg`: icono común de navegación y filas.
- `assets/ui/icons/document.svg.import`, `resources/documents/document_catalog.gd.uid` y `scripts/document_pickup.gd.uid`: metadatos de importación/UID generados por Godot para los recursos nuevos.
- `tests/document_system_smoke.gd`: cobertura de carga, UI, entrada, persistencia, scroll y aislamiento de gameplay.
- `docs/DOCUMENT_SYSTEM.md`: este documento.

### Modificados

- `scripts/gameplay_manager.gd`: catálogo, estados encontrado/leído, señales y guardado compartido v4 compatible con v1/v2/v3.
- `scripts/upgrade_menu.gd`: sección Documentos, misterio/revelado, lector, notificación genérica y apertura dirigida.
- `scenes/main/main.tscn`: instancias inequívocas de `Doc1` y `Doc2` en Sala 1.
- `export_presets.cfg`: inclusión explícita de TXT en ambos presets.
- `docs/TEST_LOG.md`: registro de verificación.

## Verificación automatizada

`DOCUMENT_SYSTEM_SMOKE_OK`, `PHASE_1_SMOKE_OK`, `PHASE_2_SMOKE_OK`, `PHASE_3_SMOKE_OK`, `LATEST_POLISH_SMOKE_OK` y `GAME_INTRO_SMOKE_OK`. Las pruebas se ejecutan con datos de usuario aislados para no alterar la partida real.
