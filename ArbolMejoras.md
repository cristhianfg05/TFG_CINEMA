# Árbol de mejoras y economía v1

## Reglas generales

- Todas las monedas, precios, capacidades, tamaños y cantidades son números enteros.
- Cada rama comienza de manera independiente.
- Un nivel solo requiere el nivel anterior de su misma rama.
- Las ramas de herramientas permanecen bloqueadas hasta comprar la herramienta.
- Los valores indicados sustituyen al valor anterior; no se suman.
- Los precios son provisionales, pero deben centralizarse para poder rebalancearlos.
- La capacidad de los sacos cerrados coincide con la capacidad actual de la bolsa del jugador.
- La basura normal ocupa 1 unidad y vale 1 moneda.
- Botellas, cubos de palomitas y objetos voluminosos ocupan 2 unidades y valen 2 monedas.
- El objeto perdido de la primera versión vale 25 monedas y no consume capacidad de basura.

# Tienda de herramientas del manager

| Herramienta        | Precio |
| ------------------ | -----: |
| Pinza extensible   |    200 |
| Aspiradora de mano |    650 |
| Boti               |  1.600 |

La mesa del manager solo vende estas tres herramientas.

# Pestaña: Limpieza

## Manos ágiles

Estado inicial: cooldown de 0,75 segundos.

| Nivel | Precio | Cooldown |
| ----: | -----: | -------: |
|     I |     15 |   0,60 s |
|    II |     40 |   0,50 s |
|   III |     90 |   0,40 s |
|    IV |    180 |   0,32 s |
|     V |    350 |   0,25 s |

## Bolsa reforzada

Estado inicial: 10 unidades.

| Nivel | Precio | Capacidad |
| ----: | -----: | --------: |
|     I |     20 |        15 |
|    II |     55 |        20 |
|   III |    130 |        30 |
|    IV |    280 |        45 |
|     V |    550 |        60 |

Esta capacidad también determina cuántas unidades contiene un saco cerrado creado con la bolsa llena.

## Sacos cerrados

Estado inicial: habilidad bloqueada.

| Nivel | Precio | Sacos activos máximos |
| ----: | -----: | --------------------: |
|     I |     60 |                     1 |
|    II |    170 |                     3 |
|   III |    380 |                     5 |
|    IV |    800 |                    10 |
|     V |  1.600 |                    20 |

Un saco contiene la capacidad actual completa de la bolsa. No existe una segunda capacidad independiente para el saco.

Ejemplo:

- Bolsa con capacidad 15 → saco de 15 unidades.
- Bolsa con capacidad 30 → saco de 30 unidades.
- Bolsa con capacidad 60 → saco de 60 unidades.

Se activa desde el primer hueco de habilidades del HUD mediante la tecla `1`.

## Sprint

Estado inicial: sprint bloqueado y velocidad de caminar de 4,5 m/s.

| Nivel | Precio | Velocidad de sprint | Duración | Recarga completa |
| ----: | -----: | ------------------: | -------: | ---------------: |
|     I |     40 |             5,2 m/s |      3 s |              7 s |
|    II |    100 |             5,8 m/s |      4 s |              6 s |
|   III |    220 |             6,4 m/s |      5 s |              5 s |
|    IV |    450 |             7,0 m/s |    6,5 s |              4 s |
|     V |    900 |             7,5 m/s |      8 s |              3 s |

El primer nivel debe sentirse deliberadamente modesto. La resistencia gastada persiste al soltar Sprint y se recupera progresivamente; cada nivel reduce el tiempo de recarga completa. El nivel V equivale a un sprint normal y útil.

## Recogida múltiple

Estado inicial: un objeto por interacción.

La recogida múltiple solo afecta a objetos válidos simultáneamente dentro del área de selección alrededor del puntero. No debe recoger objetos detrás de paredes, butacas o fuera de la línea de visión.

| Nivel | Precio | Objetos máximos |
| ----: | -----: | --------------: |
|     I |     80 |               2 |
|    II |    190 |               3 |
|   III |    420 |               4 |
|    IV |    850 |               5 |

Si hay menos objetos válidos, recoge únicamente los existentes. El consumo de capacidad sigue calculándose individualmente.

## Alcance manual

Estado inicial: 1,5 m.

| Nivel | Precio | Alcance |
| ----: | -----: | ------: |
|     I |     25 |  1,75 m |
|    II |     70 |   2,0 m |
|   III |    160 |   2,3 m |
|    IV |    350 |   2,6 m |

## Valor de reciclaje

Estado inicial: multiplicador ×1.

| Nivel | Precio | Multiplicador |
| ----: | -----: | ------------: |
|     I |    200 |            ×2 |
|    II |    600 |            ×3 |
|   III |  1.400 |            ×4 |
|    IV |  3.000 |            ×5 |

La fórmula será:

`monedas = valor_base_entero × multiplicador_entero`

No se admiten multiplicadores decimales.

## El ojo que todo lo ve

Estado inicial: habilidad bloqueada. Al activarla, toda la basura de la sala se resalta temporalmente, incluso detrás de obstáculos.

| Nivel | Precio | Duración | Cooldown |
| ----: | -----: | -------: | -------: |
|     I |    120 |      5 s |    3 min |
|    II |    300 |      8 s |    2 min |
|   III |    700 |     12 s |    1 min |

Se activa desde el segundo hueco de habilidades del HUD mediante la tecla `2`. El cooldown comienza al usarla y continúa entre sesiones para impedir reinicios deliberados de la partida.

# Pestaña: Pinza

Requisito de pestaña: haber comprado la pinza por 200 monedas.

Valores iniciales de la pinza:

- Alcance: 2,5 m.
- Cooldown: 0,80 s.
- Recogida: 1 objeto.

## Alcance de pinza

| Nivel | Precio | Alcance |
| ----: | -----: | ------: |
|     I |    100 |   3,0 m |
|    II |    240 |   3,5 m |
|   III |    520 |  4,25 m |
|    IV |  1.000 |   5,0 m |

## Velocidad de pinza

| Nivel | Precio | Cooldown |
| ----: | -----: | -------: |
|     I |     90 |   0,65 s |
|    II |    220 |   0,50 s |
|   III |    480 |   0,38 s |
|    IV |    950 |   0,28 s |

## Recogida múltiple de pinza

| Nivel | Precio | Objetos máximos |
| ----: | -----: | --------------: |
|     I |    160 |               2 |
|    II |    380 |               3 |
|   III |    800 |               4 |
|    IV |  1.600 |               5 |

La pinza no recoge objetos voluminosos si esa restricción ya forma parte del diseño de la herramienta.

# Pestaña: Aspiradora

Requisito de pestaña: haber comprado la aspiradora por 650 monedas.

Valores iniciales:

- Alcance: 1,5 m.
- Batería: 8 segundos de uso continuo.
- Recarga: velocidad ×1.
- Solo recoge basura pequeña compatible.
- No recoge botellas, cubos, bandejas ni objetos perdidos.
- La batería se recarga automáticamente mientras no se utiliza.

## Alcance de aspiración

| Nivel | Precio | Alcance |
| ----: | -----: | ------: |
|     I |    220 |   2,0 m |
|    II |    500 |   2,5 m |
|   III |  1.050 |  3,25 m |
|    IV |  2.000 |   4,0 m |

## Batería

| Nivel | Precio | Uso continuo |
| ----: | -----: | -----------: |
|     I |    180 |         12 s |
|    II |    420 |         18 s |
|   III |    900 |         26 s |
|    IV |  1.800 |         40 s |

## Velocidad de recarga

| Nivel | Precio | Multiplicador de recarga |
| ----: | -----: | -----------------------: |
|     I |    160 |                     ×1,5 |
|    II |    380 |                       ×2 |
|   III |    800 |                       ×3 |
|    IV |  1.600 |                       ×4 |

La batería y el progreso interno pueden usar float, pero el precio siempre será entero.

# Pestaña: Boti

Requisito de pestaña: haber comprado Boti por 1.600 monedas.

Valores iniciales:

- Capacidad: 50 unidades.
- Descanso después de descargar: 10 segundos.
- Velocidad de viaje: 2,0 m/s.
- Solo circula por pasillos principales.
- No entra entre las filas de butacas.

## Capacidad máxima

| Nivel | Precio | Capacidad |
| ----: | -----: | --------: |
|     I |    300 |        75 |
|    II |    650 |       100 |
|   III |  1.300 |       150 |
|    IV |  2.600 |       250 |

## Tiempo de descanso

| Nivel | Precio | Descanso |
| ----: | -----: | -------: |
|     I |    260 |      8 s |
|    II |    600 |      6 s |
|   III |  1.250 |      4 s |
|    IV |  2.500 |      2 s |

## Velocidad de viaje

| Nivel | Precio | Velocidad |
| ----: | -----: | --------: |
|     I |    220 |  2,75 m/s |
|    II |    520 |   3,5 m/s |
|   III |  1.100 |   4,5 m/s |
|    IV |  2.200 |   6,0 m/s |

Cuando Boti se llena:

1. Calcula el cubo accesible más cercano mediante navegación.
2. Viaja hasta el cubo.
3. Descarga todas sus unidades.
4. Aplica el tiempo de descanso.
5. Busca el punto de pasillo accesible más próximo al jugador.
6. Regresa y continúa siguiéndolo.

# Diseño visual de UpgradeMenu

## Estructura

- Panel a pantalla completa.
- Fondo negro semitransparente.
- Marco granate oscuro con piezas gris carbón.
- Detalles crema y luces amarillas.
- Monedas actuales siempre visibles arriba a la derecha.
- Pestañas superiores.
- Árbol en la zona central.
- Información del nodo seleccionado a la derecha.
- Leyenda de controles en la zona inferior.

## Distribución de ramas

Cada rama aparece en su propia fila:

`Icono de rama → Nivel I → Nivel II → Nivel III → Nivel IV → Nivel V`

No existen conexiones entre filas distintas.

Las pestañas de herramientas muestran inicialmente una silueta, un candado y el mensaje:

“Compra esta herramienta en la mesa del manager”.

## Iconos reutilizables

Generar un SVG sencillo para cada rama:

- Sprint: zapatilla con líneas de velocidad.
- Manos ágiles: cursor con destello.
- Bolsa reforzada: saco con cierre.
- Recogida múltiple: puntero rodeado de cinco objetos.
- Alcance manual: círculo de alcance.
- Sacos cerrados: bolsa anudada.
- El ojo que todo lo ve: ojo dorado que revela basura.
- Valor de reciclaje: moneda con flecha ascendente.
- Pinza: cabezal de pinza.
- Aspiradora: turbina.
- Batería: batería rectangular.
- Boti: cara simplificada del robot.
- Capacidad de Boti: contenedor.
- Descanso de Boti: reloj.
- Velocidad de Boti: rueda con líneas de movimiento.

Reutilizar el mismo icono en todos los niveles de una rama y cambiar únicamente el número romano.

## Cursor

Cursor normal:

- Flecha crema.
- Borde granate oscuro.
- Pequeño destello amarillo.
- Fondo transparente.
- Tamaño de 32 × 32.

Cursor pulsable:

- Pequeña pinza cerrada.
- Misma paleta.
- Silueta muy clara.
- Fondo transparente.

# Estudio económico inicial

La primera sala contiene:

- 50 basuras de valor 1.
- 10 basuras de valor 2.
- Un objeto perdido de 25 monedas.
- Total disponible: 95 monedas.

Compras razonables después de la primera sala:

- Manos ágiles I: 15.
- Bolsa reforzada I: 20.
- Sprint I: 40.
- Alcance manual I: 25.
- Sacos cerrados I: 60.

El jugador no puede comprarlo todo y debe escoger una primera especialización.

La pinza cuesta 200 y está pensada para comprarse después de avanzar a la segunda sala.

La aspiradora cuesta 650 y está pensada para mitad del juego.

Boti cuesta 1.600 y está pensado como automatización avanzada.

El multiplicador de valor resulta caro porque aumenta permanentemente todos los ingresos futuros.

Todos los precios deben almacenarse de forma centralizada y revisarse después de probar:

- Tiempo medio para limpiar cada zona.
- Monedas obtenidas por zona.
- Número de viajes al cubo.
- Orden habitual de compra.
- Porcentaje de mejoras que el jugador puede adquirir antes de la sala final.
