# Lista de prueba manual — FASE 3

Esta es la primera vertical slice. Debe jugarse desde cero sin la tecla de reinicio de depuración y, después, entregarse a 2–3 personas sin explicarles el funcionamiento.

## Inicio y controles

1. Ejecuta el proyecto con F5.
2. Pulsa `Nueva partida` para borrar cualquier progreso anterior.
3. Apunta hasta ver el resaltado de la basura y usa clic derecho para recogerla; `E` interactúa y guarda el reloj, clic izquierdo lo destruye y `Esc` abre la pausa.

## Recorrido obligatorio

- [ ] El menú permite iniciar una partida nueva.
- [ ] La esfera invisible amplía la zona de apuntado y permite seleccionar basura pequeña con facilidad.
- [ ] Pasar por encima de la basura no la recoge: sigue siendo obligatorio apuntar y usar clic derecho.
- [ ] Los dos espectadores hacen un idle muy suave y la pantalla muestra una imagen provisional.
- [ ] El reloj dorado se distingue claramente de la basura y tiene brillo pulsante.
- [ ] Al pulsar `E` sobre el reloj, no entra en la bolsa: queda en mano y puede entregarse en el cajón azul por 8 monedas.
- [ ] El primer objeto se recoge inmediatamente, pero sin mejora no se puede recoger un segundo hasta pasado aproximadamente un segundo.
- [ ] `Manos ágiles I`, por 10 monedas, reduce la espera entre dos recogidas a unos 0,35 segundos.
- [ ] `Bolsa reforzada I` cuesta 20 monedas y aumenta la capacidad de 10 a 20.
- [ ] La puerta continúa cerrada si falta alcanzar 95 % de limpieza o comprar una mejora.
- [ ] La puerta se abre al alcanzar al menos 95 % y comprar las dos mejoras.
- [ ] `Esc` pausa realmente el juego; `Continuar` reanuda y `Volver al menú` funciona.
- [ ] Tras volver al menú, `Continuar` conserva monedas, mejoras, resultado del reloj y sala completada.

## Prueba de error sin bloqueo

1. Vuelve al menú y pulsa `Nueva partida`.
2. Enfoca el reloj y usa clic izquierdo en lugar de `E`.

- [ ] Aparece una explicación clara y se descuentan 5 monedas.
- [ ] Aun con la penalización se pueden comprar las dos mejoras y abrir la puerta.

## Puerta de decisión con testers

Registra para cada persona:

- Tiempo total; objetivo aproximado: 10–15 minutos.
- Dónde se atasca sin recibir ayuda.
- Qué entendió.
- Qué le aburrió.
- Qué acción repetiría.

No debe aprobarse la fase si alguien queda bloqueado por destruir el reloj, no entiende cómo recoger/vaciar, o el bucle básico no resulta suficientemente satisfactorio.
