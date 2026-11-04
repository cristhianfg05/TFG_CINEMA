# Sala 2 — Bajo las luces

La Sala 2 se construye desde `Room02Blockout` en la escena principal. Conserva
la lógica espacial y los materiales de la Sala 1: entrada trasera, acceso a una
plataforma elevada, cuatro pasillos que descienden hacia la pantalla y butacas
escalonadas. La pantalla mira hacia `-Z`; los asientos miran hacia `+Z`.

## Huella y circulación

- La sala ocupa `x = 7,5…34,7`, `z = 25…57` y llega hasta `y = 7`.
  Su pared izquierda coincide con la jamba izquierda de la persiana existente:
  no crece hacia el futuro vestíbulo. La sala del manager permanece al otro
  lado del pasillo existente, fuera de esta huella.
- De izquierda a derecha: pared, pasillo lateral de 1,2 m, seis asientos,
  pasillo de 1,5 m, seis asientos, pasillo de 1,5 m, seis asientos, pasillo
  lateral de 1,2 m y pared. Las separaciones entre asientos alternan parejas.
- Hay nueve filas de 18 butacas (162 en total). El desnivel entre filas es
  0,14625 m, para llegar a 1,17 m en la plataforma trasera, como en Sala 1.
  Cada pasillo tiene tres escalones de acceso y una rampa de colisión continua.
  Se alternan las tres variantes ya existentes de butaca: aproximadamente
  60 % estándar, 20 % plegada y 20 % rota. Las plegadas no tienen superficie
  ficticia de cojín.

## Acabado romántico

La pantalla está vacía. Dos altavoces de cine de pie, a escala 3,2 frente a la
escala 5,4 de Sala 1, la flanquean y miran 45° hacia las butacas. Solo las
paredes laterales llevan rejillas, luces, altavoces pequeños y lazos. Los muros
frontal y trasero quedan libres de esos accesorios. El muro trasero añade seis
columnas verticales y divide el revestimiento rojo en cinco paños del mismo
ancho para mantener uniforme la textura.

Nueve corazones cuelgan algo más bajos sobre las butacas en posiciones
escalonadas. Conservan ligeros giros en X y rotan lentamente en Y. Hay 82
grupos de pétalos de mayor tamaño: 32 entre los pasillos, 20 dispersos delante
de la pantalla y 30 tras las butacas. Las dos zonas abiertas usan una
distribución irregular reproducible con separación mínima entre grupos.
Los lazos quedan centrados en la moldura horizontal (2,55 m).
La alfombra propia de la sala utiliza tonos ciruela, rombos y pequeños motivos
de corazón; se repite en suelo, gradas y escaleras sin tocar la de Sala 1.
La mesa y sus pétalos se han retirado.
El cartel existente, ahora más grande y apoyado en el suelo del pasillo de
entrada, queda a la izquierda de la estantería de patatas al mirar hacia la
Sala 2, sin tapar la persiana. Su superficie vacía `Room02EntryPosterDisplay`
puede recibir la futura imagen de la película.

## Basura y estado

La sala registra 420 residuos de una moneda y 60 de dos monedas: 480 objetos y
540 monedas en total. Se reparten entre cojines, debajo de butacas, espacios
entre filas, pasillos y suelo delantero y trasero; los de dos monedas quedan
sobre superficies transitables.
Los identificadores estables `room_02:small:…` y `room_02:large:…` permiten
persistir los objetos recogidos. Las superficies de butacas y gradas incluyen
colisión para que los residuos se apoyen sin atravesarlas.

`Room02Zone` mantiene el identificador `room_02`. La persiana y el desbloqueo
del acceso continúan a cargo del sistema existente. La prueba
`tests/room_02_smoke.gd` comprueba la huella, distribución, escalonado,
decoración y cantidades; la sala también se revisó en primera persona en Godot.
