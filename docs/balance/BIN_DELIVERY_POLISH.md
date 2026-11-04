# Papelera, entrega y saldo acumulado — 03-11-2026

## Resultado

Se preparan durante la carga los materiales normales/resaltados de la papelera y los modelos de entrega de las ocho definiciones de basura. Un pequeño SubViewport dibuja esos materiales antes de la primera interacción para adelantar la compilación de sus pipelines. El enfoque solo cambia referencias ya preparadas; la entrega reutiliza un pool de cuatro instancias por tipo, sin cargar recursos ni crear meshes en cada pulso.

La preparación sigue el patrón de calentamiento que ya usa `CinemaMovieController`. En la captura de validación a 1280×720, Forward+ / Vulkan / Intel Arc 130V, el primer enfoque del ejemplo tardó 0,016 ms y el primer fotograma visible 16,597 ms, con los ocho tipos preparados. Es una medición del ejemplo tras la preparación, no una garantía contra todos los tirones del sistema operativo o controlador.

## Cadencia

Todas las entregas son seis veces más lentas que antes. Se conserva la relación con Manos ágiles y el parámetro editable `base_deposit_interval`, ahora 0,60 s.

| Manos ágiles | Segundos por objeto |
| --- | ---: |
| Base | 0,60 |
| I | 0,48 |
| II | 0,40 |
| III | 0,32 |
| IV | 0,256 |
| V | 0,20 |

La espera se conserva entre soltar y volver a pulsar E. Un fotograma tardío no provoca varios lanzamientos simultáneos para recuperar tiempo. Soltar, apartar la mirada, alejarse o abrir un menú sigue deteniendo la entrega. Los sacos sellados conservan su entrega completa aprobada anteriormente.

## Modelo y animación

Cada pulso toma el ID real del contador por tipo de la bolsa. Se reproduce su propio GLB, con la escala y corrección de orientación de la misma definición que se utiliza al recogerlo: una botella sigue siendo una botella y una entrada sigue siendo una entrada. La botella libera dos unidades de bolsa y paga dos céntimos base en un único lanzamiento.

La trayectoria, de 0,55 s, sale de la parte inferior derecha de la vista del jugador y hace un arco hasta la abertura de la papelera. El punto final se ha subido a 1,25 m sobre la base de la papelera para coincidir con su boca; antes quedaba a 0,56 m. Los modelos se centran en el pivote de vuelo para que los distintos pivotes de suelo no lancen las botellas por encima de la cámara. Giran suavemente y se reducen al final al entrar. El pulso de papel/plástico aprobado suena a su llegada. Los GLB y materiales originales se conservan.

Las bolsas anteriores a la versión 14 no almacenaban tipos individuales. Sus unidades compatibles conservan su valor, pero no se inventa una figura de papel para datos de tipo desconocido. Las recogidas del sistema actual guardan y reproducen los ocho tipos correctamente.

## Acumulado de monedas

Durante la entrega, una fila con importe y moneda encima del lado derecho del contador acumula todas las piezas. El contador deja espacio para esa fila y mantiene los accesos del diario y habilidades separados.

Al parar, se espera un segundo. El importe vuela entonces al contador durante 0,46 s y se añade al saldo visible al llegar, con el sonido de recompensa y el pulso de moneda existentes. Reanudar antes de ese segundo continúa el acumulado y reinicia la espera. Si empieza una nueva entrega durante el vuelo del importe anterior, permanece como un acumulado separado.

Los céntimos reales se acreditan por pieza y se guardan de forma segura; el retraso pertenece a la presentación del HUD. El cálculo del saldo visible descuenta tanto el importe acumulado como las recompensas en vuelo, y nunca vuelve a sumar dinero real al terminar un tween. Así no hay pérdida al salir ni duplicación por animaciones concurrentes. Las demás recompensas conservan su animación habitual.

## Rechazo de recogida

`RejectAudio` baja de −16 a −28 dB, una reducción de 12 dB, aproximadamente un cuarto de la amplitud anterior. Se conservan el timbre y el límite que evita repeticiones continuas.

## Validación

- `bin_delivery_polish_smoke.gd`: seis cadencias, volumen, ocho modelos exactos y escalas, arco, valor de los grandes, retraso, interrupción/reanudación, ingreso al finalizar la animación, lote nuevo durante un vuelo anterior, liberación del pool y protección frente a pulsaciones rápidas de E.
- `incremental_update_smoke.gd`: entrega con E real, cancelación, bolsa por tipo, pagos únicos, guardado y migración.
- `objective_continue_smoke.gd`: regresión de notificaciones y menú al continuar.
- `bin_delivery_visual.tscn -- --capture`: bolsa mezclada con prueba gráfica de botella y papel, acumulado, vuelo del dinero y saldo final. Ejemplo: 5,00 → +0,05 pendiente → 5,05 en cartera, liberando cinco unidades por dos botellas y un papel.
- Godot MCP: ejecución y captura de la escena segura de inspección; cero errores/advertencias en el editor conectado. Las capturas del arco y la secuencia de pago se obtuvieron con la ejecución gráfica automatizada del mismo proyecto.

Evidencia conservada en `docs/balance/evidence/bin_delivery_*`. Todas las pruebas utilizan guardados aislados bajo `.godot/`; no editan manualmente la partida del usuario.
