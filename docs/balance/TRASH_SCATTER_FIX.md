# Distribución de basura y CSV — 03-11-2026

## Error de importación

Godot trataba `incremental_mejoras_niveles.csv` como traducciones. La cabecera `Equivalente /100 (monedas nuevas)` generaba una ruta de salida con una barra de directorio inexistente. No era un fallo del saldo ni de las traducciones del juego.

`docs/balance/.gdignore` excluye los documentos de análisis del importador y de los recursos del juego. Se conserva el CSV original y se retiran exclusivamente su `.csv.import` y las traducciones generadas accidentalmente. Una pasada de importación y el escaneo del editor no vuelven a generar esos archivos. La pasada del editor CLI emitió un error independiente `Safe save failed` de su configuración en el entorno de automatización; las pruebas del juego y la inspección del editor conectado no reproducen ese error.

## Distribución y apoyo inicial

- Se usan todas las anclas de cada zona, barajadas con semilla estable. Pequeñas variaciones circulares de posición y separación evitan filas y cuadrículas perfectas; se favorecen huecos sin superposición.
- Se eliminan las pirámides de 18 piezas y la elevación por radios de cajas envolventes, que podía producir apoyos falsos y piezas suspendidas.
- Muchas latas, botellas y vasos se colocan de lado. El resto conserva su orientación lógica y todos reciben una rotación horizontal distinta.
- La huella se apoya sobre la superficie real antes de hacerse visible. Se comprueban sus esquinas, pendientes, bordes de cojines, escalones y mobiliario. No hace falta una simulación global de miles de cuerpos para resolver el suelo inicial.
- Crear un proxy al acercarse solo habilita interacción. No se encola gravedad automática al entrar en rango. La escoba, aspiradora y retirada de un apoyo sí conservan la física local.
- Una velocidad momentáneamente baja durante un vuelo ya no permite congelar una pieza en el aire: para retirarla de la simulación debe dormir o tener apoyo real bajo ella.
- Se mantienen 6.270 piezas en las zonas construidas, sus valores, IDs y objetivos; la sala final sigue reservada.

Revisión de distribución 2: al continuar una partida con las pilas anteriores se recoloca únicamente la basura restante. No se modifica el saldo ni se devuelve basura recogida. Los nuevos desplazamientos se guardan; una pieza que se guardó en el aire se apoya durante la carga, antes de mostrarse. La generación consume también los huecos de IDs retirados para no rebarajar el resto al continuar.

## Modelos

Auditoría del GLB usado por cada definición: botella 106 triángulos, cubo 162, lata 160, vaso 108, servilleta 162, palomitas 158, pajita 108, entrada 108. Un material por modelo. Son adecuados al presupuesto de basura frecuente (50–500 triángulos); no se crean ni sustituyen modelos para corregir este problema de colocación.

## Validación

Godot 4.7.2, Forward+, Vulkan, Intel Arc 130V. Captura por Godot MCP y revisión visual de las vistas de salas, vestíbulo y despacho mediante la escena segura `tests/incremental_playtest.tscn`. El árbol runtime respondió tras terminar la carga; el primer intento durante el arranque agotó el tiempo de espera. Editor MCP: cero errores y advertencias en la revisión.

Pruebas:

- `incremental_density_safety.gd`: cantidades, apoyo, esquinas orientadas, zonas traseras y aproximación a una sala sin activar cuerpos ni desplazar las piezas.
- `incremental_update_smoke.gd`: entrega, compra, pago único, guardado, retirada de IDs, estabilidad del resto de posiciones al continuar y migración de las pilas antiguas conservando progreso.
- `incremental_pile_physics_smoke.gd`: apoyo al recuperar una posición guardada en el aire, prohibición de congelar una pieza en el ápice de un vuelo, caída al retirar un soporte, barrido detenido por pared y aspiración de basura grande.

Perfil gráfico de seis vistas a 1280×720, después del calentamiento y sin otras pruebas simultáneas: alrededor de 60 FPS y 0,31–0,82 ms/tick de CPU del registro de basura en reposo, sin cuerpos de basura activos por la mera proximidad. Estos tiempos excluyen el paso interno del motor físico y no garantizan ese rendimiento en todos los equipos o durante una aspiración intensa.

Evidencia visual y métricas conservadas en `docs/balance/evidence/scatter_*`; las capturas regenerables también están en `.godot/incremental_*.png`. Las pruebas usan guardados aislados y no editan manualmente la partida del usuario.

## Contacto durante el barrido — 04-11-2026

La prueba de ocho categorías de basura reprodujo penetraciones de hasta 53,5 mm en suelo y 22,4 mm en rampa. La protección del antiguo `TrashItem` no se aplicaba a los cuerpos temporales de `DenseTrashRegistry`; la tolerancia de contacto podía dejar las mallas delgadas dentro de la superficie.

Los cuerpos móviles utilizan una copia del collider con 25 mm de holgura por lado y margen de forma de 4 mm. Las formas de interacción y las posiciones de la distribución inicial permanecen intactas. Antes de guardar y dibujar cada cuerpo activo se contrastan sus ocho esquinas orientadas con superficies reales de capas 1/4, excluyendo al jugador. La altura anterior de cada esquina permite detectar una caída o rotación que cruce el suelo. Se corrige hacia arriba solo si hace falta, conservando la velocidad tangencial y la fuerza de escoba de 4,4 m/s; no se congelan piezas en el aire ni se hacen rayos desde encima de la sala que puedan arrastrarlas a través de una butaca.

`tests/swept_trash_floor_smoke.gd` comprueba los ocho tipos en plano, rampa y escalón de subida/bajada. La misma prueba tras el cambio mantiene al menos 4 mm de separación de las mallas respecto al suelo; también comprueba desplazamiento y ausencia de pago/recogida. Pasan además `incremental_pile_physics_smoke.gd` (caída al retirar un apoyo, aire, pared y aspiradora), `incremental_update_smoke.gd` (recogida, entrega y guardado) e `incremental_density_safety.gd` (apoyo inicial y proximidad sin despertar física).

La protección se limita a los 48 cuerpos activos. Perfil headless local, escena completa de 6.270 piezas, forzando 48 cuerpos móviles durante 120 ticks: CPU media del registro completo de 1,93 ms/tick. Es una medición del script, no incluye el paso interno del motor ni equivale a una garantía de FPS. Inspección en Godot MCP tras un barrido: cero errores/advertencias.
