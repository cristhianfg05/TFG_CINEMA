# CinemaCleaner — actualización incremental implementada

Fecha: 03-11-2026. Implementación de las decisiones aprobadas después de Fase A. La propuesta de Fase A se conserva como histórico; los valores activos y las nuevas tablas están en [INCREMENTAL_PHASE_B_TABLES.md](INCREMENTAL_PHASE_B_TABLES.md).

## Comportamiento jugable

- Economía interna en céntimos enteros: normal 1, grande 2; presentación 0,01 / 0,02. Reciclaje ×2/×3/×4/×5, sin cambiar categorías de los modelos existentes.
- Bolsa inicial de 25 unidades; mejoras 40/65/100/150/220. Guarda un contador por tipo de basura, no objetos físicos dentro de la bolsa. Una botella ocupa dos unidades, sale como un objeto en un pulso y paga dos céntimos base.
- Recoger no paga. Mantener E mirando una papelera entrega pieza a pieza; soltar, apartar la mirada, alejarse, cambiar herramienta o abrir un menú cancela. La capacidad baja con cada objeto. El HUD acumula el importe con su moneda encima del contador; un segundo después de parar vuela al contador y se incorpora al saldo visible al llegar. Cada arco hacia la papelera usa el GLB de su tipo de basura, con escala y orientación propias.
- Cadencia inicial de entrega 0,60 s configurable mediante `base_deposit_interval`. Manos ágiles reduce también la entrega: 0,48 / 0,40 / 0,32 / 0,256 / 0,20 s. Todas las cadencias son seis veces más lentas que la versión anterior. El primer nivel desbloquea mantener clic para recoger al ritmo permitido; esperar el cooldown deja de producir rechazo.
- Los sacos sellados conservan la opción B aprobada: se absorben y pagan completos al llegar a una papelera válida. Se comprueban todas las papeleras, con arco de entrada y línea libre, y cada saco solo puede pagarse una vez.
- La mano y la aspiradora recogen todas las categorías. La escoba mueve todas, nunca mete basura en la bolsa ni genera dinero. Solo Q recorre mano → escoba → aspiradora entre las herramientas disponibles; selecciona el rombo intermedio del HUD.
- Escoba por 1,50 en el despacho. Solo dos ramas, cada una con dos compras: intervalo 1,20 → 0,85 → 0,55 s; ancho 0,75 → 1,15 → 1,60 m. Usa el modelo nuevo, icono dorado, vista en primera persona, barrido horizontal y sonido suave.
- Boti no aparece en herramientas, tienda, inventario ni ramas activas. Sus assets y sus precios históricos permanecen exclusivamente para preservar recursos legacy y calcular la migración. No se reintroduce la pinza.
- Objetos perdidos en espera, sin rediseño. No se utiliza su recompensa para financiar el cálculo económico.

## Densidad y física

`dense_trash_registry.gd` mantiene datos estables, índice espacial de celdas de 2 m y MultiMesh por sala/tipo/bloque de 8 m. Reutiliza los modelos actuales y sus materiales en copias compartidas de runtime; no cambia los GLB originales.

Hay **6.270 objetos reales** en las ocho zonas construidas. Los **1.730 de la sala final** siguen reservados y no afectan a objetivos ni ingresos actuales. Los identificadores de guardado de los dos pasillos mantienen sus nombres históricos invertidos.

Corrección posterior: se ha sustituido la distribución de pilas por basura esparcida, usando todas las anclas de suelo, filas, butacas y zonas traseras con posición y orientación variables. Latas, botellas y vasos pueden aparecer tumbados. No se añaden alturas por superponer las cajas envolventes de otras piezas. Cada pieza nace apoyada sobre una superficie real, con orientación adaptada a la pendiente, comprobación de su huella y rechazo de esquinas dentro de paredes, mobiliario o escalones. Los modelos actuales se conservan: entre 106 y 162 triángulos y un material cada uno.

Solo hay hasta **256 proxies de interacción cercanos** y **48 RigidBody3D activos de basura**. El jugador atraviesa la basura. Aproximarse o mirar una pieza no activa gravedad: la colocación inicial ya está resuelta. Barrer, aspirar o retirar un apoyo sí despierta la física local; los cuerpos colisionan con suelo, rampas, obstáculos y otras piezas. Al descansar, la pieza vuelve a su representación estática y conserva posición y rotación. Los objetos guardados en mitad de un vuelo se apoyan antes de mostrarse al cargar.

La escoba comprueba una línea libre y aplica impulso a piezas dentro de su banda frontal. La aspiradora atrae también botellas y cubos. Ninguna de las dos atraviesa deliberadamente colisiones estructurales. La visibilidad por lotes usa su AABB actualizado para conservar piezas que se hayan barrido fuera del bloque de origen.

Ajuste de escoba (2026-11-04): postura más vertical, cabezal bajo y mango inclinado hacia el personaje. El barrido de 0,46 s prepara ligeramente hacia dentro, empuja 0,60 m hacia fuera en la vista de primera persona y recupera suavemente; sustituye el arco lateral. La velocidad inicial de empuje pasa de 2,4 a 4,4 m/s en todos los niveles (+83 %); se mantienen la anchura y cadencia de las mejoras, las colisiones y el presupuesto de 48 cuerpos activos.

## Objetivos, porcentajes y progreso

Los porcentajes se redondean a dos decimales, con coma en la interfaz. Mientras quede basura, el máximo visual es 99,99 %. Las puertas y la maza usan contadores exactos, separados del redondeo visual.

Se pagan objetivos automáticamente una sola vez, sin multiplicador de reciclaje:

| Objetivo | Monedas |
| --- | ---: |
| Salida de Sala 1 al 95 % | 0,50 |
| Sala 2 al 100 % | 1,00 |
| Sala 3 al 100 % | 1,00 |
| Sala 4 al 100 % | 1,50 |
| Vestíbulo al 95 % | 1,00 |
| Reactivar las cuatro películas | 1,00 |
| Ver un rato cada película, cuatro objetivos | 0,25 cada uno |
| Primera recreativa en Difícil | 1,00 |
| Segunda recreativa en Difícil | 1,50 |
| Todos los documentos | 1,00 |
| Todos los coleccionables, incluidos carteles | 1,50 |
| **Total posible** | **12,00** |

La cadena de puertas sigue siendo: Sala 1 al 95 % → ala derecha y despacho; ambos al 95 % → Salas 2 y 3; ambas al 95 % → vestíbulo; vestíbulo al 95 % → ala izquierda y Sala 4. La maza exige el 100 % exacto de todas las zonas construidas, sin la sala final. Ninguna compra es un requisito de apertura.

## Guardado y migración

Versión 14, revisión de distribución 2. Guarda el contenido por tipo, saldo en céntimos, IDs retirados, posiciones/rotaciones desplazadas, recompensas reclamadas y marcadores de migración. La Sala 1 ya no reaparece llena al continuar. Al cargar una distribución antigua se descartan únicamente las posiciones de pilas de las piezas restantes, conservando IDs recogidos, bolsa, dinero y progresión. La revisión nueva conserva los desplazamientos y no rebaraja las piezas restantes al recoger otra. Escritura compacta a archivo temporal y renombrado al terminar; los cambios frecuentes se agrupan en intervalos de 0,75 s, con flush al parar la entrega y salir.

Antes de convertir una partida antigua se conserva una copia `*.pre_incremental.bak`, sin sobrescribir una copia previa. Los números de saldo y el valor pendiente se conservan uno a uno como céntimos; no se divide otra vez entre cien. Las bolsas antiguas sin contador por tipo usan unidades compatibles hasta vaciarse. La inversión conocida en Boti y sus niveles se devuelve según el catálogo histórico; si estaba comprado, se entrega la escoba y se descuenta su precio de 150 céntimos del reembolso.

Los objetivos ya cumplidos se marcan cobrados sin pago retroactivo. Los IDs antiguos se conservan; al aumentar densidad se traslada aproximadamente la proporción de limpieza de cada sala, sin pagar la diferencia. El guardado antiguo de Sala 1 solo garantiza el hito del 95 % cuando no almacenaba IDs individuales; no se puede reconstruir una colocación retirada que aquel formato nunca registró. Abrir el muro final previamente conserva las áreas como limpias. Esta conversión no se repite al cargar una partida ya migrada.

No se han editado manualmente partidas personales. Todas las pruebas usan archivos aislados bajo `.godot/`.

## Escoba y audio nuevos

Fuente Blender: `art_source/blender/props/cinema_broom.blend`. GLB: `assets/pipeline/props/cinema_broom.glb`. Creada con Blender MCP e inspeccionada allí y en Godot. Aproximadamente 1,43 m de alto, 0,47 m de ancho y 0,15 m de fondo; pivote en el centro del apoyo sobre el suelo, transforms aplicados. 396 triángulos, 236 vértices de fuente / 780 exportados por UV y normales, un mesh y un material; GLB de 942.512 bytes. Revisión 2026-11-04: petróleo y granate más oscuros, crema envejecida, roces de pintura en bordes, arañazos discontinuos y suciedad irregular, tomando la aspiradora como referencia sin modificarla. Atlas albedo 1024² generado en Blender por `tools/blender/weather_broom.py`, guardado en `art_source/textures/props/cinema_broom_wear_albedo.png`, empaquetado en el .blend e integrado en el GLB. Cuatro texeles de margen para el filtrado. Una superficie por ejemplar (antes cinco); una textura RGBA8 con mipmaps supone aproximadamente 5,33 MiB sin compresión. Collider de interacción simple; no collider de malla. Un ejemplar en el despacho y otro en el viewport de primera persona. Exportar solo selección y escena activa: el archivo fuente conserva otra escena de referencia que no debe incluirse en el GLB.

Entrega: elección aprobada `bin_paper_plastic_soft_02.wav`, pulso de 0,22 s, PCM16 estéreo 44,1 kHz, pico ~−16 dBFS, bus Trash, reproducción a −13 dB, pitch leve ±2,5 %, variación de volumen 0,6 dB y polifonía limitada a tres. Se conserva la familia previa de entrega de sacos.

Barrido: `broom_soft_sweep_01.wav`, Stable Audio Small-SFX local, seed 5401. Fuente en `audio_source/raw/sfx/`, procesado en `audio_source/generated/sfx/` y copia de juego en `assets/audio/sfx/tools/`. Recorte de 0,42 s, filtro a 6.500 Hz, fades 10/110 ms y −3 dB de procesado; PCM16 estéreo 44,1 kHz, pico ~−25 dBFS. Bus Tools, volumen de reproducción −10 dB y AudioStreamRandomizer con variación leve de pitch/volumen. Se integra una muestra piloto para comprobar el barrido, sin generar una biblioteca adicional no solicitada. Validación de formato, clipping y espectrograma; la mezcla audible de la escoba queda abierta al ajuste del usuario. La elección explícita de un único pulso de papel prevalece sobre la recomendación general de varias variantes de la Audio Bible.

## Pruebas y evidencia

Godot 4.7.2. Pruebas automatizadas con el proyecto real y guardados aislados:

- `tests/incremental_update_smoke.gd`: 6.270 objetos / 68,59 base, bolsa, E mantenida y cancelación, valor de grandes, compras de escoba y límite de sus ramas, rechazo silencioso de cooldown, segundo contenedor con saco sellado, pagos únicos, retirada animada, posiciones al continuar y migración idempotente de Boti con copia previa.
- `tests/incremental_pile_physics_smoke.gd`: retirada del soporte, caída real sin cruzar el suelo, barrido de cubo grande detenido por pared, succión de un grande y ausencia de recogida/pago por barrer.
- `tests/incremental_density_safety.gd`: cantidades por categoría y zona, ocho zonas construidas, basura trasera en Salas 1/2, apoyo en pendientes y comprobación de las ocho esquinas orientadas de cada modelo contra geometría sólida. Verifica también que acercarse a una sala no active una caída de las piezas iniciales.
- Regresiones `tests/objective_continue_smoke.gd` y `tests/hammer_progression_smoke.gd`: no se repiten notificaciones al continuar, tamaño del aviso, cadena de persianas y bloqueo de maza hasta el 100 %.
- `tests/incremental_playtest.tscn`: escena segura para jugar con las herramientas; `-- --capture` obtiene vistas de sala, despacho, tienda y ramas de escoba. Capturas inspeccionadas. Godot MCP recargó el proyecto y no mostró errores ni advertencias de editor.

Los antiguos `trash_density_smoke.gd`, `trash_layout_smoke.gd` y `vacuum_smoke.gd` describen el sistema histórico de 400/2.763 nodos RigidBody y sus antiguos valores; sus expectativas quedan sustituidas para esta arquitectura por las tres pruebas incrementales anteriores. No se presenta una ejecución de toda la batería histórica como validación de este cambio.

Medición gráfica más reciente: Forward+, Vulkan, Intel Arc 130V 8 GB, ventana 1280×720. Después de 90 ticks de calentamiento se miden 90 frames por vista. Salas 1/2, vestíbulo y despacho: **52,9–58,7 FPS medidos por reloj**, mediana de frame **16,62–16,68 ms**, p95 **19,16–23,03 ms**, **189–443 draw calls**. CPU del registro de basura: **0,41–1,24 ms/tick**; este dato excluye el paso interno del motor físico y el resto del juego. Nodos totales en esas vistas: **10.320–10.762**, proxies ≤256, cuerpos de basura ≤48. No equivale a una prueba en todos los equipos ni garantiza 60 FPS con las cuatro películas activas. El perfil histórico de 26.112 nodos usaba otra densidad/controlador: no se calcula un porcentaje de mejora de FPS entre esos perfiles.

La captura libera sus texturas estáticas de cursor antes de cerrar RenderingServer; así el cierre automatizado no produce las fugas de texturas que aparecieron en las primeras capturas. No se modificó el sistema de cursores del juego para realizar esa limpieza de prueba.

Las tablas reproducibles están en `tools/balance/incremental_phase_b.py`; 53 compras cuestan 265,70. Una ruta ordinaria selecciona 44/53 compras (83 %), mientras que la de reinversión temprana permite las 53 con el cine completo. La duración completa sigue siendo una estimación de diseño pendiente de una partida larga; no se ha fingido un playtest de dos horas.
