# CinemaCleaner — Fase A: auditoría y propuesta incremental

Fecha: 3 de noviembre de 2026. Estado: propuesta para revisión, sin modificar economía, catálogo, mecánicas, escenas ni partidas del juego.

Decisiones confirmadas por el usuario: normal **0,01**, grande **0,02**, multiplicadores de reciclaje **×2/×3/×4/×5**; entrada y vestíbulo comparten una zona con **1.500 objetos**. Sala final reservada hasta construirla. Boti y pinza descartados.

## Resultado recomendado

La propuesta suma exactamente **8.000 objetos y 87,49 monedas base**. Hoy están construidas ocho zonas de limpieza con **2.763 objetos y 2.955 monedas antiguas base**. La nueva versión de esas mismas zonas tendría **6.270 objetos y 68,59 monedas base**; quedan reservados los **1.730 objetos / 18,90 monedas** de la sala final.

Recomiendo una escoba de **1,50**, aspiradora de **12,00**, bolsa inicial de **20 unidades** con progresión hasta **180**, y conservar los multiplicadores enteros existentes. Las 53 compras propuestas —herramientas y todos los niveles, sin Boti— cuestan **265,70**. Una ruta calculada genera **354,51**, consume el **74,95 %** y deja **88,81**. No significa que siempre se ganen 354,51: el momento de comprar reciclaje cambia el ingreso.

El objetivo temporal es **130–165 minutos de limpieza y progreso con todo el cine construido**, sujeto a calibración jugable. El modelo de tareas suma 106,5 minutos y añade 25–55 minutos para tienda, recogidas dispersas, aprendizaje y vuelta al 100 %. No incluye las partidas opcionales de las recreativas ni ver películas completas. No es una medición de una escoba todavía inexistente; utilizar un margen de aproximadamente ±25 % sobre las tareas modeladas.

Las tablas completas, todos los niveles, porcentajes, salas, tiempos comparables y cada compra simulada están en [INCREMENTAL_PHASE_A_TABLES.md](INCREMENTAL_PHASE_A_TABLES.md). Los datos de cada nivel también están en [incremental_mejoras_niveles.csv](incremental_mejoras_niveles.csv). El cálculo es reproducible mediante `tools/balance/incremental_phase_a.py`.

## Auditoría del funcionamiento actual

Fuentes principales: `resources/upgrades/upgrade_catalog.gd`, `resources/trash/*.tres`, `scripts/gameplay_manager.gd`, `player_controller.gd`, `trash_item.gd`, `trash_bin.gd`, `sealed_bag.gd`, `tool_shop_panel.gd`, `upgrade_menu.gd`, `gameplay_hud.gd`, los cuatro generadores de zonas y las pruebas de densidad existentes. No se han leído ni cambiado partidas personales.

| Sistema | Comportamiento comprobado en código | Implicación |
| --- | --- | --- |
| Economía | `coins` entero; basura recompensa 1 o 2 al entregar; reciclaje multiplica el valor pendiente | Los enteros ya sirven; hay que versionar su unidad a céntimos y actualizar presentación |
| Basuras normales | Entrada, servilleta, vaso, lata, pajita y palomitas: tamaño 1 y valor 1 | Conservar categorías; pequeño no equivale siempre a ligero |
| Basuras grandes | Botella y cubo: tamaño 2 y valor 2 | Una botella es un objeto, consume dos unidades y entrega dos céntimos base |
| Bolsa | 10 inicial; mejoras 15/20/30/45/60 | Inadecuada para 8.000 piezas; la bolsa actual solo guarda volumen y valor agregado |
| Recogida manual | Un clic nuevo por acción, 0,75 s inicial, animación de llegada 0,32 s; reserva capacidad durante el vuelo | Los objetos no caben dos veces por concurrencia; repetir clic 8.000 veces seguiría siendo tedioso |
| Mejoras manuales | Intervalos 0,60/0,50/0,40/0,32/0,25 s; múltiple 2/3/4/5; alcance 1,5→2,6 m | Techo ideal 1,33 objetos/s inicial y 20/s al máximo, solo con objetivos juntos y capacidad disponible |
| Recogida múltiple | Busca en todo el grupo, filtra sala y distancia ≤1,15 m al primario, ordena y comprueba visión | La escoba puede mejorar ocupación del grupo de cinco, sin recoger automáticamente |
| Aspiradora | Compra 650; alcance 1,5 m desde cámara, cono dot≥0,58 (~55°); captura ≤0,82 m al jugador; tirón 19 m/s², velocidad objetivo limitada a ~4,4 m/s | No existe un caudal fijo en objetos/s. Candidatos simultáneos pueden llenar la bolsa muy deprisa |
| Compatibilidad aspiradora | No hay filtro de categoría en `_attract_with_vacuum` | El texto dice ligera, pero actualmente intenta atraer también botellas/cubos; decidir y probar filtro explícito |
| Batería | 8 s, consume 1 s/s; recarga 1 s/s solo al soltar; máximos 40 s y recarga 4 s/s | Ciclo continuo teórico 50 % inicial y 80 % con recarga máxima; aumentar batería alarga sesiones, no cambia por sí solo ese porcentaje |
| Geometría aspiradora | Distancia calculada desde cámara; candidatos bajo asientos evitan ciertas pruebas de visión | Alcance inicial puede resultar justo para basura del suelo estando de pie; validar origen de consulta en boquilla y colisiones antes de cobrar más alcance |
| Movimiento | Andar 4,5 m/s, agachado 1,5; sprint bloqueado inicialmente; 5,2/5,8/6,4/7/7,5 m/s | Tiempo de viaje depende de puertas, butacas y posición de papelera; no basta distancia en línea recta |
| Entrega | `trash_bin.interact()` llama a `empty_bag()`: vacía todo y paga de golpe | Falta controlador de pulsación mantenida y desglose por tipo |
| Sacos | Guardan unidades/valor/sala; absorción paga de golpe y usa primera papelera del grupo en varios caminos | Deben entrar en el mismo circuito de entrega o permitirían eludir el nuevo ritmo; no retirar la función de cerrar/lanzar |
| Boti | Catálogo, tres ramas, compra, exposición 3D y variables; no aparece un controlador autónomo de limpieza en los scripts revisados | No prometer rendimiento medido de Boti. Retirar contratos de tienda y guardado, conservar recursos compartidos |
| Otras máquinas | Recreativas dan carteles/objetivos, sin cobro de monedas en su entrada; expendedoras son decoración | No inventar tasas ni ingresos para financiarlas |
| Objetos perdidos | Reloj: +25 al devolver, −5 al destruir; la penalización puede dejar saldo negativo | Referencia nueva +0,25/−0,05; separada del presupuesto de basura y nunca necesaria para progresar |
| Guardado | Versión 13, JSON completo, IDs de retirados de zonas nuevas, semilla, herramientas, bolsa agregada y sacos | No guarda transformaciones de cada basura movida. Se guarda tras cada retirada con ID |
| Sala1 y guardado | `_spawn_trash()` no asigna `world_item_id`, no omite retirados y reinicia `remaining_trash`; el JSON tampoco guarda ese contador | Riesgo crítico existente: Sala1 puede regenerarse al cargar y permitir volver a cobrar. No es un comportamiento válido para financiar el balance |
| Porcentajes | Progreso por número de objetos, no valor; redondea con `roundi` | Un 100 visual puede llegar al 99,5 % real; el mazo debe exigir restantes=0, no porcentaje redondeado |

### Coste actual y capacidad de compra

Las ramas actuales suman **38.405** monedas antiguas; aspiradora 650 y Boti 1.600 elevan el total a **40.655**. Quitando Boti y sus ramas quedan **25.555**. Una única limpieza del contenido construido solo podría generar **14.775** incluso regalando ×5 desde la primera pieza, antes de descontar mejoras de reciclaje. Por tanto, no alcanza para comprar todo mediante una pasada normal; el fallo de regeneración de Sala1 no se cuenta como ingreso repetible legítimo. La nueva propuesta corrige esa diferencia sin convertir todas las compras en obligatorias.

El CSV distingue precio actual, referencia matemática /100 y recomendación. Cada fila contiene nivel, beneficio y justificación. Esa referencia /100 no se aplica automáticamente al catálogo.

## Distribución, tamaños y orden de desbloqueo

| Zona física | ID de guardado actual | Superficie bruta comprobada | Objetos nuevos | Densidad bruta |
| --- | --- | --- | --- | --- |
| Sala 1 | room_01 | 22×30 = 660 m² | 650 | 0,98/m² |
| Ala derecha, primera | left_corridor | 23×10 = 230 m² | 280 | 1,22/m² |
| Despacho | manager_office | 7×10 = 70 m² | 40 | 0,57/m² |
| Sala 2 Romance | room_02 | 27,2×32 = 870,4 m² | 1.100 | 1,26/m² |
| Sala 3 Acción | room_03 | 27,25×32 = 872 m² | 1.050 | 1,20/m² |
| Entrada y vestíbulo | lobby | 7,1×40 = 284 m² | 1.500 | 5,28/m² |
| Ala izquierda, segunda | right_corridor | 18,4×10 = 184 m² | 200 | 1,09/m² |
| Sala 4 Miedo | room_04 | 18×54 = 972 m² | 1.450 | 1,49/m² |
| Sala final | Aún sin interior | Sin superficie auditable | 1.730 reservados | Sin calcular |

Son superficies de suelo bruto, no área libre descontando mobiliario. El vestíbulo es el punto delicado: 1.500 objetos en su planta estrecha requieren grupos pequeños junto a paredes/puestos y un recorrido central despejado; no una dispersión uniforme. La densidad propuesta de las salas no produce por sí sola montones: recomiendo aproximadamente 65 % en grupos de 6–18 piezas con dispersión irregular y 35 % sueltos. Reservar anchos útiles de circulación y utilizar exclusiones geométricas, sin tocar estructura de salas.

Respetar nombres visuales y conservar los IDs invertidos de los pasillos: renombrarlos en guardados rompería progresión y recogidas existentes. Distribución de la tabla original: ala derecha 255/25 y ala izquierda 185/15, siguiendo sus nombres visibles, no sus IDs.

Orden comprobado: Sala1 al 95 visual abre primera ala y despacho; Sala1+ala+despacho al 95 abren Salas2/3; esas cinco áreas al 95 abren vestíbulo; lobby al 95 abre segunda ala/Sala4. Todo lo construido realmente limpio al 100 habilita mazo y muro final. **Las puertas no cuestan monedas**. En esta fase no se generan basuras al otro lado del muro.

## Precios y progresión recomendados

| Compra nueva o herramienta | Precio actual | Referencia /100 | Propuesto | % ingreso de ruta | Beneficio y momento |
| --- | --- | --- | --- | --- | --- |
| Aspiradora | 650 | 6,50 | **12,00** | 3,38 % | Salto a recogida continua; compra objetivo a mitad de Sala2. Evita que la escoba recién comprada pierda su ventana inicial |
| Boti | 1.600 | 16,00 | Retirar | — | Reemplazar puesto/exposición por escoba y migrar inversión |
| Escoba | No existe | — | **1,50** | 0,42 % | Incluye velocidad1 y ancho1; al llegar al despacho |
| Velocidad escoba 1→2 | No existe | — | **1,25** | 0,35 % | Ciclo completo 1,20→0,85 s; aproximadamente 41 % más barridos por minuto |
| Velocidad escoba 2→3 | No existe | — | **3,00** | 0,85 % | Ciclo 0,85→0,55 s; aproximadamente 55 % más barridos por minuto |
| Ancho escoba 1→2 | No existe | — | **1,50** | 0,42 % | Ancho 0,75→1,15 m; ~53 % más superficie a igual profundidad |
| Ancho escoba 2→3 | No existe | — | **3,50** | 0,99 % | Ancho 1,15→1,60 m; ~39 % más superficie |

Solo hay esas dos ramas de escoba y dos compras por rama: **compra + cuatro mejoras = 10,75**. No hay batería, capacidad, recogida ni mejora adicional de entrega para la escoba.

Barrido propuesto: profundidad frontal 1,10 m constante, contacto a 0,9 m del jugador, desplazamiento máximo 0,65 m por barrido sin mejora. Ventana visible de movimiento 0,45/0,34/0,25 s dentro de los ciclos 1,20/0,85/0,55 s. Área alcanza aproximadamente 0,825/1,265/1,760 m²; el número real de objetos afectados depende de cada montón. No prometer una ganancia constante de objetos por barrido.

La bolsa de 10 obligaría a **877 descargas mínimas sumando las zonas**; incluso al máximo actual de 60 son **151**. Con capacidades de referencia progresivas del estudio son **90**, aproximadamente. Son mínimos por volumen, no viajes exactos: en una partida se cambia capacidad a mitad de sala y los objetos grandes pueden forzar una descarga parcial. La bolsa recomendada es **20→30→50→80→120→180**. En Sala1 se puede obtener el primer nivel tras la primera entrega y el segundo muy pronto.

| Zona terminada | Compras que debería permitir la ruta propuesta |
| --- | --- |
| Sala1 | Bolsa2, manos2, múltiple1, alcance1, sprint1 y reciclaje×2 |
| Primera ala + despacho | Escoba, velocidad2/ancho2 y bolsa3 |
| Sala2 | Aspiradora, reciclaje×3, alcance/batería aspiradora1, manos3, alcance manual2 y primer saco |
| Sala3 | Reciclaje×4, bolsa4, múltiple2, batería2, recarga1, ambas ramas escoba máximas, sprint2 y ojo1 |
| Vestíbulo | Reciclaje×5, bolsa5, alcance aspiradora2, batería3, recarga2, múltiple3, manos4, alcance manual3, ojo2, sacos2 y sprint3 |
| Sala4 | Máximos manuales/sprint/ojo; alcance aspiradora3 y recarga3; sacos opcionales |
| Sala final futura | Niveles finales opcionales de aspiradora/sacos. Se disfrutan durante esa sala, no después del último objeto |

La simulación paga escoba al entrar en despacho, tras 930 retiradas anteriores; aspiradora alrededor de **1.326 objetos depositados acumulados**, ~356 de Sala2; ×2 a 465, ×3 a 1.690, ×4 a 2.311 y ×5 a 3.134. Son resultados de una ruta priorizada y una mezcla uniforme de grandes. La tienda física exige desplazamientos; el jugador cobra al descargar, no al retirar del suelo, y suele comprar tras completar una bolsa: redondear esos hitos hasta aproximadamente una bolsa más y admitir variación por tipos/orden. Ni los conteos ni las salas de compra son bloqueos nuevos. Un jugador que ahorre todo podría comprar antes al llegar al despacho.

### Reciclaje y riesgo de quedarse sin dinero

Recomendación: **3,00 / 8,00 / 14,00 / 18,00**, para ×2/×3/×4/×5. Cada nivel añade exactamente un valor base adicional por objeto; no duplica el multiplicador anterior. Se amortiza tras depositar respectivamente **3,00 / 8,00 / 14,00 / 18,00 de valor base futuro**. En normales son 300/800/1.400/1.800 piezas; con la mezcla completa, aproximadamente 275/732/1.281/1.646 objetos.

En la ruta calculada cada compra se produce con suficiente basura futura para devolver su precio. El último nivel se compra al entrar al lobby, quedando más de 50 monedas base por recoger. Si solo quedara Sala final, ese nivel costaría 18,00 y devolvería 18,90 extra: retorno demasiado justo; la tienda debe mostrar que es opcional y conviene comprarlo antes. Si quedan menos de 18,00 de valor base, ya no se amortiza. No introducir una obligación de comprar todas las mejoras.

Sin reciclaje se obtienen 87,49 y no se compra todo el catálogo de 265,70; eso es una elección de progreso, **no un bloqueo**, porque mano/bolsa y puertas funcionan sin compra. Recomiendo una pista temprana hacia reciclaje, sin cobro de apertura ni herramientas obligatorias. No presupuestar el reloj ni premios de recreativas como dinero necesario. Mostrar advertencia contextual de fondos bajos es opcional; no bloquear compras por diseño en esta fase.

El remanente de 88,81 (~25 % de ingreso de la ruta) permite errores y compras en otro orden. Los niveles finales de aspiradora son lujos útiles, no requisitos: alcance4 cuesta 30,00, batería4 22,00 y recarga4 20,00. Esa reserva de precio mantiene decisiones al final en vez de agotar el árbol al abrir el vestíbulo. No tienen retorno monetario propio, sino ahorro de tiempo; medir aceptación en playtest. Los sacos10→20 y el último ojo pueden resultar innecesarios: dejarlos opcionales y no inventarles utilidad obligatoria ni aumentar sus prestaciones.

## Eficiencia de herramientas y tiempo

El modelo por zona utiliza `T = objetos / tasa efectiva + objetos × 0,10 s + ceil(volumen / capacidad) × viaje + búsqueda`. Las tasas de ruta son 1,15/1,5/1,5/2,5/3,4/3,6/3,6/3,5/4 objetos/s. Viaje y búsqueda están explícitos en el calculador. La comparación de herramientas del anexo usa la misma capacidad y viaje para las tres: 2,4 manual, 3,2 escoba+manual y 4 aspiradora+manual. Son hipótesis que deberán medirse tras el prototipo; ningún tiempo de escoba se presenta como hecho existente.

Solo entregar 8.000 objetos a 0,10 s consume **13 min 20 s**, independientemente del multiplicador. Un grande es un único pulso de 0,10 s, libera dos unidades y concede dos céntimos base; no dos pulsos de un céntimo. A 180 unidades caben entre 90 y 180 objetos: bolsa completa tarda entre 9 y 18 s; con la mezcla general ~16,5 s. Probar ese máximo: puede resultar largo, pero no añadir una mejora de velocidad de entrega sin evidencia.

Para evitar miles de clics propongo en FaseB **recogida manual mantenida**, repitiendo a la cadencia actual mejorada, además del clic unitario. La escoba solo mueve; su mejora de eficiencia depende de múltiples objetos por acción. Sin recogida mantenida, las 8.000 piezas exigirían hasta 8.000 pulsaciones o un mínimo ideal de 1.600 acciones de cinco objetivos, más barridos, viajes y fallos. Ese cambio de comodidad es necesario para defender el objetivo temporal.

| Herramienta | Ventaja propia propuesta | Límite que mantiene a las demás útiles |
| --- | --- | --- |
| Mano | Objetos grandes, selección precisa, sin batería | Requiere apuntar; múltiple aprovecha grupos en radio actual 1,15 m |
| Escoba + mano | Papeles/pajitas/palomitas: agrupa en superficies abiertas; sin batería | No cobra, no guarda en bolsa, no mueve vasos/latas/botellas/cubos por defecto; después hay que recoger |
| Aspiradora + mano | Normales dispersos, alcance y rincones bajo butacas; recogida continua | Batería, cono y paredes; grandes se recogen a mano. Mantener succión contra asientos sin atravesar muros |

La restricción de grandes en aspiradora sería un ajuste explícito respecto al código actual, pendiente de aprobación del balance. No debe hacerse silenciosamente. Con el reparto cíclico actual, las cuatro familias ligeras representan aproximadamente dos tercios de las normales (~60 % del total); comprobar mezcla real al generar densidad. El cálculo no supone que la escoba reúna el 100 % del cine.

Manos: mejoras de cadencia dan ganancias ideales de 25/20/25/25/28 % respecto al nivel anterior; múltiple mejora ocupación de 1→2→3→4→5, no garantiza recoger siempre ese número. Bolsa reduce viajes de forma no lineal. Alcance de aspiración aumenta área potencial aproximadamente con radio², pero no concede caudal fijo. Recarga 1/1,5/2/3/4 produce ciclos ideales 50/60/66,7/75/80 %; batería 8→40 prolonga el tramo activo cinco veces, útil al cubrir filas largas.

## Arquitectura recomendada para Fase B

Conservar `GameplayManager`, catálogo de mejoras, contratos de sala y definiciones de basura. Añadir un registro compacto de basura con ID estable, definición, zona, transformación de origen y transformación modificada; un índice espacial por sala/celdas de ~2 m. Resolver mano, escoba, aspiradora y revelado sobre ese índice. Dejar de consultar todo el grupo y ordenar miles de nodos en cada tick.

Representar basura quieta con **MultiMesh por fragmento visible de sala, malla/material y tipo**, no un MultiMesh gigante que impida ocultación. Los GLB pueden tener varias superficies y nodos: conservar sus transformaciones relativas al extraer mallas, agrupar por cada combinación y no modificar las fuentes legacy. Índice estable de objeto distinto del slot visual; una retirada puede compactar slots actualizando mapa inverso. Un barrido actualiza únicamente transformaciones afectadas y cambia de celda al cruzar el límite. Los fragmentos acotan el AABB y evitan dibujar todo el cine por una sola pieza visible.

Para interacción, utilizar consulta del registro y pocos proxies cercanos reutilizables cuando hagan falta raycasts. Evitar un RigidBody y Area3D por pieza. Mano conserva vuelo visual mediante un pool; el registro pasa de disponible→reservado→bolsa sin carreras. Escoba usa desplazamiento cinemático controlado con barrido de forma simple contra paredes, puertas y muebles, luego proyección sobre soporte real de suelo/escalón/asiento; limitar o subdividir movimiento para no cruzar esquinas ni caer debajo de rampas. No iniciar 1.000 tweens ni físicas simultáneas.

Presupuesto inicial orientativo: registro lógico para 8.000; máximo ~128 proxies/interacciones activas; las piezas en movimiento de un barrido se procesan por lote local. Intentar mantener ≤1.500 piezas visibles próximas y ≤80 llamadas de dibujo adicionales de basura, dependiendo de superficies. Objetivo de coste adicional CPU ≤2 ms y GPU ≤2 ms en las vistas representativas a 1080p, dentro de 16,67 ms totales para 60 FPS; son criterios de aceptación propuestos, no resultados. Reutilizar materiales, no duplicar dos materiales de resaltado por cada pieza. Sin sombras en migajas cuando no aporten lectura.

`docs/pipeline/ASSET_BUDGETS.md` recomienda 50–500 triángulos para basura muy frecuente: 8.000 piezas a 500 serían cuatro millones antes de contar el cine si se dibujara todo. Hay que auditar mallas/superficies reales antes de garantizar rendimiento; no optimizar ni sustituir GLB legacy automáticamente. El tamaño exacto del registro se medirá con arrays compactos; no extrapolar memoria desde diccionarios ideales.

Hoy ya existe congelación por distancia: escaneo global cada 0,45 s, simula hasta 30 m y oculta hasta 24 m (lobby tiene su propio límite de 18 m). **Congelar no elimina nodos/colliders**, y un radio de 30 m puede cubrir casi toda una sala. `trash_item.gd` instancia modelo, collider y área por pieza; también copia materiales de resaltado. Guardar JSON completo tras cada pieza implica escrituras crecientes. No basta subir las constantes de cantidad.

La captura histórica `.godot/cinema_expansion_profile.json` registra 2.763 basuras y 26.112 nodos, con 1.192 draw calls en lobby y valores de física de ~29–30 ms en Salas3/4; también indica ~60 FPS, por lo que esos monitores no deben tomarse como un presupuesto consistente ni una medición nueva. El log de 300 piezas es de otra carga y tampoco representa el estado nuevo. FaseB necesita una medición reproducible antes/después en idéntica escena, controlador, resolución y recorrido. Aquí se propone arquitectura, sin afirmar una mejora de rendimiento ya conseguida.

## Bolsa, entrega, HUD y persistencia

Bolsa nueva: cantidades por definición (`ticket`, `bucket`, etc.), volumen derivado y valor base en céntimos. Mantener el valor base independiente del multiplicador; cada pulso retira **un objeto de un tipo**, libera `size_units` y acredita `reward_cents × recycle_multiplier`. Una botella no se divide en dos papeles. La entrega debe compartir una única operación transaccional entre bolsa y sacos, con guardia de sesión y de objeto; no dejar dos rutas que premien el mismo contenido.

Empezar entrega al mantener E delante de una papelera válida, primer pulso inmediato y siguientes cada 0,10 s configurable. Soltar, apartarse, cambiar de objetivo, pausar, sentarse, cinemática o bolsa vacía cancela de inmediato. Revalidar alcance/visibilidad y contenido por pulso. Un click aislado entrega uno. No recuperar tiempo pausado en una ráfaga de 200 objetos; limitar el trabajo acumulado por frame.

Los sacos deben conservar desglose por tipo al cerrarse. Lanzar/acercar un saco no debe pagar automáticamente: la absorción puede colocarlo en una cola de contenido pendiente junto a la papelera, que se entrega manteniendo E. Se conserva la manipulación de sacos y su mejora de cantidad; el dinero sigue entrando al depositar cada pieza. Este ajuste de los sacos forma parte de la nueva entrega y necesita probar su sensación, no eliminarse como efecto lateral.

HUD: formateador monetario único con división y módulo enteros, siempre `0,01`, `1,50`, `12,00`, incluso en tooltip, mensajes de fondos, recompensas y reloj. El contador puede aumentar por pulso, pero la animación de moneda actual dura 0,46 s y procesa una cola secuencial: a 10 entregas/s acumularía retraso. Agrupar vuelos/pulsos de HUD cada 0,2–0,3 s sin retrasar saldo real; no ejecutar un vuelo y choque de monedas de medio segundo por cada papel. Reutilizar una animación de papelera en actividad, evitando colas de tweens de 0,40 s por pulso. Para audio, limitar voces solapadas y variar suavemente el candidato aprobado.

Guardado nuevo: versión económica y versión de layout explícitas, cantidades por tipo de bolsa/saco, IDs retirados y cambios de posición únicamente de objetos movidos. Identificador estable por zona/tipo/índice y semilla; cambiar recuentos o distribución no debe alterar la definición asociada a IDs previos. Guardar tras compras/depósitos/cambios de herramienta y consolidar recogidas/movimientos con guardado diferido y flush al salir/pausar. Un snapshot coherente incluye inventario, saldo y retiradas juntos; escritura atómica con temporal y respaldo. Ante cierre brusco puede perderse como máximo el último intervalo no confirmado, nunca conservar simultáneamente basura y premio de transacciones distintas.

### Migración de partidas

1. Conservar saldo y valores enteros existentes interpretándolos como céntimos nuevos: 1.000 antiguas→10,00. No multiplicar por 100. Versionar para que ocurra una sola vez. Conservar todos los niveles comprados y capacidades al menos equivalentes.
2. Boti comprado: conceder escoba nivel1 en ambos atributos y devolver la inversión antigua de Boti y sus niveles **menos los 150 céntimos del precio nuevo de escoba**. Boti básico: crédito14,50 + escoba; Boti máximo: crédito149,50 + escoba. Si hay mejoras huérfanas sin propiedad, devolver su inversión sin conceder una compra inexistente. No compensar ni retirar recursos compartidos por nombre de carpeta. Marca de migración impide reembolsos repetidos. Las partidas avanzadas recibirán una devolución grande y no tendrán el ritmo de una partida nueva; no ocultarlo mediante un recorte arbitrario.
3. La bolsa/sacos antiguos solo contienen volumen y valor agregado. Como valor y tamaño coinciden, **no se puede reconstruir el número de botellas ni los tipos** a partir de esos datos. Conservarlo como lote legacy de crédito pendiente de entregar, con capacidad y valor exactos, y convertir a la estructura nueva cuando se vacíe. No inventar tipos ni pagar al cargar. La presentación puede indicar «contenido de partida anterior». La garantía de una pieza/grande por pulso se aplica a objetos del inventario nuevo; el lote antiguo necesita esta excepción documentada.
4. Mantener IDs existentes y añadir versión de distribución. No volver a cerrar puertas ya abiertas. Para zonas con IDs, migrar una sola vez a proporción de limpieza equivalente, conservando los retirados originales; el nuevo conjunto de IDs auto-retirados debe ser determinista y no conceder moneda duplicada. **Sala1 es una excepción no recuperable con exactitud**: la versión13 no conserva sus piezas ni su porcentaje. Si existe `room_completed`, sabemos que se llegó al umbral de salida, no que se limpió al 100. Propuesta de compatibilidad: conservar puerta abierta y acreditar una sola vez el 95 % de limpieza en el nuevo registro de Sala1, sin monedas nuevas; si el muro final ya estaba abierto, conservar su estado avanzado. Si no hay flag, no inventar un porcentaje anterior: mantener saldo/bolsa/mejoras y documentar la regeneración inevitable de esa sala en la conversión. Respaldar antes de migrar y probar idempotencia. El balance del informe es para partida nueva, no una garantía de mismo saldo en todas las partidas veteranas.

## Archivos previstos y orden de implementación

| Bloque | Archivos existentes a tocar en FaseB | Extensión prevista |
| --- | --- | --- |
| Catálogo y presentación | `resources/upgrades/upgrade_catalog.gd`, `resources/trash/trash_definition.gd`, `.tres` de basura y reloj, `tool_shop_panel.gd`, `upgrade_menu.gd`, `tool_display.gd` | Céntimos, precios aprobados, sustituir categoría/puesto Boti por escoba, iconos/modelo |
| Bolsa/economía/guardados | `scripts/gameplay_manager.gd`, `scripts/sealed_bag.gd` | Cantidades, transacciones, migraciones, nuevos registros y adaptador de compatibilidad |
| Interacción | `scripts/player_controller.gd`, `scripts/trash_bin.gd`, `scripts/trash_item.gd` | Pulsación mantenida, cancelación, proxies/vuelos, barrido y colisiones |
| Densidad | `gameplay_manager.gd`, `left_wing_blockout.gd`, `room_02_blockout.gd`, `cinema_new_auditorium.gd`, `cinema_expansion_blockout.gd` | Mismos espacios; reparto estable por soportes/exclusiones; final reservado |
| HUD y audio | `scripts/gameplay_hud.gd`, escenas de jugador/papelera y audio nuevo aprobado | Dos decimales, entrega progresiva y estado de escoba |
| Nuevos componentes acotados | Registro e índice espacial, renderer por fragmentos, controlador de escoba y entrega | Mantener contratos del manager mediante adaptadores; no reconstruir el juego |
| Validación existente | pruebas de densidad/layout, bolsas, herramientas, guardados y perfilado | Adaptar a IDs/registros y probar invariantes monetarios/cancelación/colisiones |

Primero prototipo de registro y una zona con la densidad nueva; después recogida/entrega y persistencia; luego escoba y sus cuatro mejoras; finalmente economía/UI y distribución de todas las zonas construidas. Perfilar antes de propagar a todo el cine. El prop de escoba se hará con Blender MCP y las guías de assets cuando se autorice FaseB; en FaseA no hace falta modelarlo.

Pruebas de aceptación: 100 normales sin mejora→1,00; grande→2×normal en cualquier multiplicador; no dinero al recoger/barrer; soltar E detiene ese frame; reanudar no duplica; capacidad correcta durante vuelos; una transacción por objeto; pausa no produce catch-up; sacos no permiten cobro instantáneo alternativo; guardar/cargar conserva retirados y barridos; migración idempotente; 100 real exige cero restantes; grandes y papel bajo asientos accesibles; cero cruces de pared; ausencia de Boti/pinza en UI activa; perfil de CPU/GPU/física/memoria/draw calls con 6.270 y luego 8.000 registros.

## Audio adicional pedido durante la auditoría

Tres candidatos nuevos de papel cayendo sobre plástico, generados con Stable Audio **sm-sfx / same-s**, semillas 5311/5312/5313. Brutos en `audio_source/raw/sfx/bin_paper_plastic_soft_0X.wav`; procesados de audición en `audio_source/generated/sfx/bin_paper_plastic_soft_0X.wav`.

Cada candidato final dura 0,22 s, PCM16 estéreo 44,1 kHz, pico aproximadamente −16 dBFS, ataque/salida suavizados y recorte de agudos. Se han procesado con el pipeline, recortado a un contacto breve y validado; inspección espectral, no aprobación auditiva definitiva. A 10 Hz habrá solapamiento: reproducir con volumen bajo y pool limitado al integrarlo. Quedan pendientes de elección y no sustituyen ningún audio de juego.
