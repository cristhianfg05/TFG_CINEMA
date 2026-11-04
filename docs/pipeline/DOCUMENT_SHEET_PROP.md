# Documento 3D para recogida

El pickup de documentos usa un folio low-poly hecho en Blender MCP: hoja levemente ondulada, esquina doblada, líneas impresas y sello rojo. Se buscó que se leyera como papel desde la cámara del jugador sin añadir textura ni microdetalle. El rectángulo legacy de `document_pickup.tscn` sigue disponible, oculto, como fallback reversible.

| Paso | Resultado |
| --- | --- |
| Fuente Blender | `art_source/blender/props/document_sheet.blend`, escena `CinemaCleaner_DocumentSheet` |
| Exportación | `assets/pipeline/props/document_sheet.glb` |
| Escala / pivote | 0,40 × 0,54 m; pivote en el centro, cerca del suelo |
| Geometría | 2 mallas, 299 triángulos, 5 materiales, sin imágenes de textura |
| Colisión | Se conserva el `BoxShape3D` simple del pickup; el GLB no genera colisión |
| Interacción | El resaltado se aplica a ambas mallas importadas y se restaura al perder el foco |

Auditoría con `tools/blender/audit_glb.py`: escala unitaria, sin rotaciones de objeto, sin caras degeneradas. La malla del cuerpo está cerrada; la tinta y el pliegue son superficies abiertas intencionadamente. Godot importó el GLB y la escena de recogida sin errores. La prueba `tests/document_sheet_smoke.gd` comprueba importación, fallback, resaltado, recogida y sonido. `tests/document_sheet_visual_capture.gd` capturó el documento en su ubicación real: `screenshots/document_sheet/01_room_view.png` y `02_detail.png`.

Presupuesto: 299 triángulos están dentro del rango para un prop sencillo. Se reutiliza la misma escena para los documentos; no se añadieron texturas ni dependencias externas.
