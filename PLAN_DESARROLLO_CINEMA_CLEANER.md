# Plan de desarrollo por fases — Cinema Cleaner

> Documento operativo para llevar el juego desde una carpeta vacía hasta una versión completa y exportable. Cada fase termina con una versión ejecutable. No comenzar la fase siguiente hasta cumplir su criterio de salida.

## 0. Decisiones bloqueadas del proyecto

[Cierto] Cambiar motor, lenguaje, escala, sistema de inventario o pipeline artístico a mitad del desarrollo multiplicaría el trabajo. Estas decisiones se mantienen salvo que una prueba técnica demuestre que son inviables.

- [ ] Motor: Godot 4, versión estable.
- [ ] Lenguaje: GDScript.
- [ ] Plataforma inicial: Windows PC.
- [ ] Cámara: primera persona.
- [ ] Renderizador: Forward+.
- [ ] Objetivo: 1920 × 1080 y 60 FPS en el equipo mínimo elegido.
- [ ] Duración objetivo final: 2–3 horas.
- [ ] Primera versión validable: una única sala de 10–15 minutos.
- [ ] Dirección visual: low-poly feo, gracioso y ligeramente incómodo.
- [ ] NPC: ambientales, con posiciones y animaciones prefijadas; sin IA social compleja.
- [ ] NPC finales: Meshy T2, hasta 15.000 triángulos en LOD0.
- [ ] Escenarios: kit modular construido en Blender/Godot; no generar habitaciones completas con Meshy.
- [ ] Control de versiones: Git desde el primer día.

### No se desarrollará durante el MVP

- Multijugador.
- Mundo abierto.
- Clientes con navegación libre.
- Conversaciones ramificadas.
- Sistema real de venta de entradas o comida.
- Películas largas.
- Generación procedural de habitaciones.
- Personalización completa del protagonista.
- Inventario complejo con cuadrícula.
- Versiones para consola o móvil.

## 1. Quién hace cada cosa

| Responsable | Trabajo principal |
|---|---|
| **TÚ** | Instalar herramientas, tomar decisiones de diseño, probar cada build, aprobar/rechazar assets, operar Meshy y guardar comprobantes/licencias. |
| **CODEX** | Crear y modificar el proyecto, escenas, scripts, recursos, herramientas de importación, documentación, pruebas, configuración de Godot y automatizaciones locales. |
| **MESHY** | Crear NPC, maquinaria, herramientas y props distintivos. No construir paredes, suelos ni salas completas. |
| **BLENDER** | Limpiar modelos, corregir escala, orientación, pivotes, materiales, UV, mallas, rig, animaciones, colisiones simples y exportación GLB. Puede hacerlo el usuario guiado por Codex o Codex mediante scripts. |
| **GODOT** | Montaje de niveles, lógica jugable, UI, iluminación, audio, vídeo, animación, guardado y exportación. |
| **RUNWAY u otra herramienta de vídeo** | Solo al final: producir bucles originales de 5–10 segundos para las pantallas. |
| **ELEVENLABS u otra herramienta de audio** | Solo al final: efectos, ambientes y voces breves cuando no exista una fuente propia/licenciada mejor. |

## 2. Qué descargar

### Instalar antes de comenzar

[Cierto] Para el inicio solo hacen falta Godot, Blender, Git y un editor. Meshy funciona en el navegador.

1. **Godot estable para Windows x86_64 — versión Standard, no .NET**  
   https://godotengine.org/download/windows/
   - Descargar el ejecutable estable de Godot 4.
   - Descargar también los `Export Templates` de la misma versión.
   - Extraer Godot en una carpeta estable, por ejemplo `C:\Tools\Godot`.
   - No utilizar builds beta, RC o nightly.

2. **Blender 4.5 LTS o la LTS activa**  
   https://www.blender.org/download/lts/
   - Utilizar una versión LTS durante todo el proyecto.
   - No actualizar Blender en mitad de una fase.

3. **Git para Windows**  
   https://git-scm.com/download/win
   - Mantener las opciones predeterminadas salvo el editor, que puede ser VS Code.

4. **Git LFS**  
   https://git-lfs.com/
   - Tras instalarlo, ejecutar una vez: `git lfs install`.
   - Se usará para `.blend`, `.glb`, `.fbx`, `.wav`, `.ogg` y `.ogv`.

5. **Visual Studio Code**  
   https://code.visualstudio.com/download
   - Instalar la extensión `Godot Tools`.
   - Configurar VS Code como editor externo desde Godot cuando se cree el proyecto.

6. **Cuenta de Meshy**  
   https://www.meshy.ai/
   - No necesita instalación.
   - Durante las pruebas: Smart Topology, Meshy T2 y 15.000 triángulos para NPC.

### Instalar cuando llegue la fase audiovisual

7. **FFmpeg**  
   https://ffmpeg.org/download.html
   - En Windows, utilizar uno de los builds enlazados desde la página oficial.
   - Se usará para normalizar audio y convertir vídeos a formatos compatibles.

8. **Audacity, opcional**  
   https://www.audacityteam.org/download/
   - Solo si hace falta recortar, limpiar o equilibrar sonidos manualmente.

### No instalar todavía

- Plugins de Godot no imprescindibles.
- Paquetes enormes de assets.
- Herramientas de navegación o comportamiento de multitudes.
- Sistemas de diálogo.
- Software de captura/tráiler hasta que exista una beta.

## 3. Estructura inicial del proyecto

```text
CinemaCleaner/
├── project.godot
├── docs/
│   ├── GAME_SCOPE.md
│   ├── ART_BIBLE.md
│   ├── ASSET_MANIFEST.md
│   ├── DECISIONS.md
│   ├── TEST_LOG.md
│   └── LICENSES.md
├── scenes/
│   ├── player/
│   ├── gameplay/
│   ├── characters/
│   ├── rooms/
│   ├── ui/
│   └── main/
├── scripts/
├── resources/
│   ├── trash/
│   ├── upgrades/
│   └── tools/
├── assets/
│   ├── models/
│   ├── materials/
│   ├── textures/
│   ├── audio/
│   ├── video/
│   └── fonts/
├── source_assets/
│   ├── blender/
│   ├── meshy_exports/
│   └── concept_art/
└── builds/
```

[Cierto] Los modelos de millones de polígonos y generaciones descartadas no deben entrar en Git. Se guardan aparte como fuente o respaldo. Al repositorio solo entra el asset aprobado y optimizado.

## FASE 0 — Preparación y control del alcance

**Objetivo:** poder abrir el proyecto, ejecutarlo y trabajar sin perder archivos.

### TÚ

- [ ] Instalar las herramientas de la sección anterior.
- [ ] Crear una carpeta `CinemaCleaner`.
- [ ] Crear un repositorio privado en GitHub o equivalente.
- [ ] Decidir dónde se guardarán los originales pesados de Meshy y Blender.
- [ ] Confirmar resolución, controles y hardware mínimo aproximado.

### CODEX

- [ ] Crear el proyecto Godot.
- [ ] Crear la estructura de carpetas.
- [ ] Preparar `.gitignore` ignorando `.godot/`, builds y temporales.
- [ ] Configurar Git LFS para archivos 3D, audio y vídeo.
- [ ] Crear los documentos de alcance, arte, assets, decisiones, pruebas y licencias.
- [ ] Configurar la ventana, renderizador y mapa inicial de inputs.
- [ ] Crear una escena `main.tscn` vacía que se ejecute sin errores.

### Criterio de salida

- [ ] El repositorio se puede clonar y abrir.
- [ ] Godot ejecuta una ventana vacía sin errores.
- [ ] Existe un primer commit etiquetado como `phase-0`.

## FASE 1 — Controlador y sala inicial en bloques

**Objetivo:** recorrer una sala provisional a escala real.

### CODEX / GODOT

- [ ] Crear `Player` basado en `CharacterBody3D`.
- [ ] Añadir cámara en primera persona.
- [ ] Implementar caminar, mirar con ratón, sprint, agacharse y salto básico.
- [ ] Añadir colisión y gravedad.
- [ ] Crear acciones: avanzar, retroceder, izquierda, derecha, saltar, sprint, agacharse, interactuar, herramienta principal y pausa.
- [ ] Implementar un `RayCast3D` central para interacciones futuras.
- [ ] Crear un punto de reaparición si el jugador sale del mapa.
- [ ] Construir con cubos la sala 1: suelo, paredes, techo, pantalla, puerta, dos bloques de butacas y pasillos.
- [ ] Comprobar escala: jugador ≈ 1,8 m, puertas ≈ 2 m, filas transitables.
- [ ] Añadir luz provisional y un material por color.

### TÚ

- [ ] Caminar cinco minutos por la sala.
- [ ] Comprobar que el movimiento no marea.
- [ ] Confirmar que se puede pasar entre butacas y agacharse debajo.
- [ ] Ajustar sensibilidad, velocidad y altura con Codex.

### Criterio de salida

- [ ] Se puede entrar, caminar, correr, saltar y agacharse sin atravesar geometría.
- [ ] La escala parece coherente.
- [ ] La sala se mantiene por encima del objetivo de FPS.
- [ ] Build etiquetada como `phase-1-walkable`.

## FASE 2 — Núcleo de limpieza

**Objetivo:** crear el primer bucle jugable: recoger → llenar bolsa → descargar → cobrar.

### CODEX / GODOT

- [ ] Crear un recurso de datos `TrashDefinition` con identificador, nombre, categoría, volumen, recompensa, destino y modelo.
- [ ] Crear una escena reutilizable `TrashItem`.
- [ ] Implementar enfoque mediante raycast y resaltado sencillo.
- [ ] Mostrar `E — Recoger` únicamente cuando exista un objeto válido.
- [ ] Recoger un objeto por interacción, no al tocarlo.
- [ ] Crear inventario de bolsa basado en volumen, capacidad inicial 10.
- [ ] Impedir recoger basura cuando la bolsa esté llena.
- [ ] Crear un contenedor de basura.
- [ ] Vaciar la bolsa en el contenedor y conceder monedas.
- [ ] Crear UI mínima: punto de mira, prompt, capacidad, monedas y porcentaje de limpieza.
- [ ] Calcular el porcentaje usando objetos válidos restantes, no mediante inspección visual.
- [ ] Añadir 20 objetos provisionales hechos con primitivas: entrada, servilleta, vaso, botella, lata, pajita, palomitas y cubo.
- [ ] Añadir sonidos provisionales libres o simples para recoger y vaciar.
- [ ] Añadir una tecla de reinicio solo para depuración.

### TÚ

- [ ] Jugar el bucle durante 10 minutos.
- [ ] Anotar si recoger es lento, automático, confuso o repetitivo.
- [ ] Probar intencionadamente bolsa llena, objeto inaccesible y vaciado repetido.

### Criterio de salida

- [ ] Todos los objetos pueden recogerse.
- [ ] La bolsa nunca supera su capacidad.
- [ ] Las monedas no se duplican.
- [ ] El porcentaje llega correctamente al 100 %.
- [ ] Existe una build jugable de 5–10 minutos: `phase-2-core-loop`.

## FASE 3 — Primera vertical slice

**Objetivo:** demostrar en una sola sala que existe progresión, decisión y cierre.

### CODEX / GODOT

- [ ] Añadir el reloj barato como primer objeto perdido.
- [ ] Crear un buzón/cajón provisional de objetos perdidos.
- [ ] Separar basura normal y objetos valiosos.
- [ ] Penalizar moderadamente si el reloj se destruye y mostrar el aprendizaje.
- [ ] Añadir brillo posterior a objetos potencialmente valiosos.
- [ ] Crear un sistema de mejoras basado en recursos de datos.
- [ ] Implementar `Manos ágiles I`.
- [ ] Implementar `Bolsa reforzada I` con capacidad 20.
- [ ] Añadir el manager provisional o el modelo aprobado.
- [ ] Abrir la puerta al alcanzar 95 % de limpieza y comprar las dos mejoras.
- [ ] Crear tutorial contextual sin cuadros de texto largos.
- [ ] Añadir dos espectadores estáticos o con una animación idle sencilla.
- [ ] Añadir una pantalla con imagen estática o animación provisional; todavía no generar la película final.
- [ ] Guardar automáticamente monedas, mejoras y sala completada.
- [ ] Añadir menú de pausa y botón para volver al menú.

### TÚ

- [ ] Jugar desde cero sin usar herramientas de depuración.
- [ ] Dar la build a 2–3 personas sin explicarles cómo jugar.
- [ ] Registrar dónde se atascan y cuánto tardan.
- [ ] Preguntar únicamente: qué entendieron, qué les aburrió y qué acción repetirían.

### Puerta de decisión obligatoria

[Cierto] No se producen el vestíbulo, las otras salas ni las películas hasta superar esta prueba.

- [ ] Un jugador nuevo entiende cómo recoger y vaciar sin explicación externa.
- [ ] La sesión dura aproximadamente 10–15 minutos.
- [ ] Nadie queda bloqueado por haber destruido el reloj.
- [ ] El acto de recoger y descargar resulta suficientemente satisfactorio.
- [ ] Build etiquetada como `phase-3-vertical-slice`.

Si la prueba falla, repetir esta fase cambiando interacción, densidad de basura, capacidad, recompensas, sonido y ritmo. No añadir más contenido para ocultar un bucle débil.

## FASE 4 — Pipeline artístico definitivo

**Objetivo:** reemplazar placeholders sin convertir cada importación en trabajo manual impredecible.

### TÚ + MESHY

- [ ] Aprobar una imagen de referencia por asset antes de generar 3D.
- [ ] Generar cada NPC por separado, frontal, T-pose y fondo limpio.
- [ ] Usar Meshy Smart Topology T2.
- [ ] Usar 15.000 triángulos para todos los NPC principales.
- [ ] Generar herramientas y maquinaria distintiva de forma individual.
- [ ] Descargar GLB con textura y conservar el archivo original.
- [ ] Registrar prompt, herramienta, fecha, coste y licencia en `LICENSES.md`.
- [ ] Marcar cada asset como `concepto`, `generado`, `limpio`, `importado`, `aprobado` o `rechazado`.

### BLENDER

- [ ] Trabajar en metros.
- [ ] Eliminar geometría flotante y caras interiores innecesarias.
- [ ] Comprobar que no existan millones de caras en el modelo final.
- [ ] Aplicar rotación y escala.
- [ ] Colocar el origen correctamente: pies para personajes; base o agarre para objetos.
- [ ] Orientar frente hacia el eje acordado con Godot.
- [ ] Revisar normales y sombreado facetado.
- [ ] Reducir materiales: uno por NPC, dos como máximo.
- [ ] Revisar UV y textura.
- [ ] Crear colisiones simples aparte; nunca utilizar la malla visual compleja como colisión.
- [ ] Probar Meshy Smart Rig en los NPC.
- [ ] Confirmar nombres y estructura de huesos antes de producir animaciones para todos.
- [ ] Exportar GLB y conservar el `.blend` fuente.

### Presupuestos de referencia

| Tipo | Presupuesto final recomendado |
|---|---:|
| NPC cercano LOD0 | 15.000 triángulos |
| NPC LOD1, solo si resulta necesario | 8.000–10.000 |
| Herramienta en primera persona | 5.000–12.000 |
| Carrito/CineSweep | 8.000–20.000 |
| Maquinaria grande | 8.000–25.000 |
| Decoración mediana | 1.000–6.000 |
| Basura pequeña | 20–800 |
| Objeto valioso | 300–3.000 |

### CODEX / GODOT

- [ ] Crear una escena contenedora por modelo importado.
- [ ] Normalizar escala, materiales, sombras y colisiones sin modificar directamente el archivo importado.
- [ ] Sustituir assets sin cambiar la lógica de juego.
- [ ] Verificar el profiler tras cada grupo de importaciones.

### Criterio de salida

- [ ] Cinco assets diferentes recorren el pipeline completo sin errores.
- [ ] Reimportar un GLB no rompe escenas ni scripts.
- [ ] La sala inicial tiene una muestra representativa del estilo final.
- [ ] Build etiquetada como `phase-4-art-pipeline`.

## FASE 5 — Ala izquierda completa

**Objetivo:** convertir la vertical slice en un primer capítulo de 30–45 minutos.

### BLENDER / GODOT

- [ ] Crear kit modular: pared, esquina, suelo, techo, marco, puerta, escalón, barandilla, tarima, pantalla y butaca.
- [ ] Construir sala 1, vestíbulo acústico, pasillo izquierdo, sala 2 y despacho del manager.
- [ ] Crear cuarto de servicio y contenedor de basura.
- [ ] Diferenciar sala 1 y sala 2 mediante geometría, iluminación, disposición y color.

### CODEX

- [ ] Crear carga y activación por zonas.
- [ ] Añadir progreso independiente por sala/pasillo.
- [ ] Añadir despacho con tienda, objetos perdidos y exposición de coleccionables.
- [ ] Implementar dos o tres mejoras adicionales.
- [ ] Introducir basura bajo butacas y objetos voluminosos.
- [ ] Desbloquear la pinza extensible al final de esta sección.
- [ ] Añadir checkpoints y recuperación ante cierre inesperado.

### TÚ

- [ ] Medir el tiempo de ida y vuelta entre sala, contenedor y manager.
- [ ] Confirmar que ninguna ruta repetida resulte castigadora.
- [ ] Probar la sección completa sin comandos de depuración.

### Criterio de salida

- [ ] Las dos salas y el pasillo pueden completarse en cualquier sesión nueva.
- [ ] Los objetos perdidos nunca entran accidentalmente en la bolsa.
- [ ] Todas las compras persisten tras reiniciar.
- [ ] Build etiquetada como `phase-5-left-wing`.

## FASE 6 — NPC ambientales y vestíbulo

**Objetivo:** conseguir que el cine parezca vivo sin desarrollar una simulación de multitudes.

### MESHY / BLENDER

- [ ] Preparar los siete modelos base: adulto delgado, adulta, corpulento, adolescente chico, adolescente chica, empleado de palomitas y empleado de taquilla.
- [ ] Preparar variantes mediante color, cabello, accesorios sencillos y escala entre 0,92 y 1,08.
- [ ] Mantener un esqueleto compatible siempre que sea posible.
- [ ] Crear/probar animaciones: sentado, comer, beber, móvil, dormir, cambiar postura, esperar de pie y avanzar un paso.

### CODEX / GODOT

- [ ] Crear componente NPC ambiental.
- [ ] Utilizar posiciones fijas; no navegación libre.
- [ ] Pausar animación y ocultar NPC de zonas inactivas.
- [ ] Construir el vestíbulo en tres sectores: entrada, descanso y palomitas.
- [ ] Añadir taquillas, cola lateral, mostrador, dos empleados, máquinas y papeleras.
- [ ] Implementar cola por puntos prefijados.
- [ ] Añadir segundo contenedor de basura.
- [ ] Añadir atajo de empleados entre vestíbulo y zona del manager.
- [ ] Introducir el carrito de limpieza como herramienta desbloqueable.
- [ ] Limitar materiales, luces y sombras de los NPC.

### Criterio de salida

- [ ] Entre 12 y 20 NPC pueden estar visibles sin romper el objetivo de FPS.
- [ ] La cola nunca bloquea la ruta del carrito.
- [ ] No se calculan animaciones de salas cerradas.
- [ ] El vestíbulo tiene una tarea jugable propia y no es solo decoración.
- [ ] Build etiquetada como `phase-6-lobby-alpha`.

## FASE 7 — Ala derecha y herramientas avanzadas

**Objetivo:** completar las cuatro salas y diversificar la limpieza.

### CODEX / GODOT

- [ ] Construir sala 3 de terror: oscura, asimétrica y con basura escondida.
- [ ] Implementar linterna.
- [ ] Construir sala 4 de acción: grande, escalonada y con pasillo central.
- [ ] Implementar la aspiradora de mano en primera persona, sin tubo ni animación compleja de brazos.
- [ ] Definir qué objetos aspira y cuáles ignora.
- [ ] Añadir depósito/batería solo si mejoran realmente el bucle; no por obligación temática.
- [ ] Completar comportamiento de la pinza extensible.
- [ ] Completar carrito: basura, cajón de objetos perdidos y descarga.
- [ ] Añadir objetos elevados, basura voluminosa y nuevos valores/recompensas.
- [ ] Permitir elegir qué sala derecha completar primero.

### TÚ

- [ ] Verificar que cada herramienta resuelve un problema distinto.
- [ ] Eliminar cualquier herramienta que solo sea una versión más rápida de pulsar `E`.
- [ ] Probar la economía desde una partida nueva sin conceder monedas manualmente.

### Criterio de salida

- [ ] Las cuatro salas, dos pasillos, manager y vestíbulo son completables.
- [ ] Ninguna mejora física es obligatoria para terminar la historia.
- [ ] No hay softlocks por comprar mejoras en un orden distinto.
- [ ] Build etiquetada como `phase-7-base-game`.

## FASE 8 — Sala antigua y final real

**Objetivo:** añadir el giro final y una conclusión que combine todo lo aprendido.

### MESHY / BLENDER

- [ ] Crear 6–8 objetos narrativos: proyector antiguo, cámara, bobina, baúl, máscara/atrezzo, altavoz, uniforme/maniquí y pieza distintiva adicional.
- [ ] Crear el robot CineSweep como modelo separado y animable.
- [ ] Crear versiones envejecidas de butacas y elementos del kit modular.

### CODEX / GODOT

- [ ] Crear falso final y resumen de jornada.
- [ ] Ocultar la sala antigua del mapa hasta su revelación.
- [ ] Implementar apagado de luces, proyección sobre pared y apertura del acceso oculto.
- [ ] Crear la sala antigua combinando basura con objetos históricos valiosos.
- [ ] Implementar CineSweep: limpiar basura pequeña, separar objetos sospechosos y marcar restos.
- [ ] Crear reparación del proyector mediante piezas obtenidas anteriormente.
- [ ] Integrar créditos reales en la proyección final.
- [ ] Desbloquear selección de capítulo o modo libre después de completar el juego.

### Criterio de salida

- [ ] El falso final no impide continuar.
- [ ] El acceso oculto no aparece antes de tiempo.
- [ ] La sala final utiliza todas las herramientas relevantes.
- [ ] Existe un final, créditos y regreso al menú.
- [ ] Build etiquetada como `phase-8-content-complete`.

## FASE 9 — Vídeo, sonido e iluminación final

**Objetivo:** sustituir placeholders audiovisuales sin comprometer rendimiento ni licencias.

### TÚ + HERRAMIENTAS EXTERNAS

- [ ] Crear cinco conceptos originales de película.
- [ ] Generar primero una imagen estática y aprobarla.
- [ ] Generar después 2–3 intentos de vídeo por película, no antes.
- [ ] Mantener bucles de 5–10 segundos.
- [ ] Guardar prompt, original, fecha, herramienta, licencia y versión editada.
- [ ] Crear o conseguir efectos y ambientes con licencia compatible.

### CODEX / FFMPEG / GODOT

- [ ] Convertir vídeo a 640 × 360, 24 FPS y formato admitido por la versión de Godot utilizada.
- [ ] Separar audio y vídeo cuando facilite el control espacial.
- [ ] Reproducir vídeo solo en la sala activa.
- [ ] Utilizar fotograma estático en salas lejanas.
- [ ] Añadir buses de audio: Master, Music, Ambience, SFX y Movie.
- [ ] Añadir sonidos de objetos, herramientas, puertas, pasos, máquinas, público y películas.
- [ ] Aplicar iluminación horneada o económica al escenario.
- [ ] Limitar luces dinámicas y sombras de NPC.

### Criterio de salida

- [ ] No se reproducen cinco vídeos simultáneamente.
- [ ] El volumen de ninguna película impide oír señales jugables.
- [ ] Todos los recursos externos están registrados en `LICENSES.md`.
- [ ] Build etiquetada como `phase-9-audiovisual-beta`.

## FASE 10 — Guardado, opciones y accesibilidad básica

**Objetivo:** hacer que la experiencia sea recuperable y configurable.

### CODEX / GODOT

- [ ] Implementar menú principal: Nueva partida, Continuar, Opciones, Créditos y Salir.
- [ ] Guardar: monedas, mejoras, objetos valiosos, coleccionables, limpieza, puertas, herramientas y capítulo.
- [ ] Añadir versión al formato de guardado para futuras migraciones.
- [ ] Guardar de forma atómica para evitar archivos corruptos.
- [ ] Añadir volumen por buses.
- [ ] Añadir sensibilidad del ratón, inversión vertical opcional y FOV razonable.
- [ ] Añadir pantalla completa/ventana, resolución y límite de FPS.
- [ ] Permitir reasignar controles esenciales.
- [ ] Añadir subtítulos a mensajes hablados o megafonía.
- [ ] Añadir confirmación antes de sobrescribir una partida.
- [ ] Probar partida nueva, continuar, cierre forzado y guardado antiguo.

### Criterio de salida

- [ ] El progreso sobrevive a cerrar y volver a abrir el juego.
- [ ] Un guardado corrupto no destruye silenciosamente la única copia válida.
- [ ] Todas las opciones principales funcionan en una build exportada.
- [ ] Build etiquetada como `phase-10-feature-complete`.

## FASE 11 — Optimización y QA

**Objetivo:** estabilizar el juego antes de añadir cualquier extra.

### Orden obligatorio de optimización

[Cierto] No se reducirán primero los NPC de 15.000 triángulos. El orden será:

1. Desactivar salas y NPC invisibles.
2. Reducir sombras dinámicas y luces que afectan a muchos objetos.
3. Reducir materiales y draw calls.
4. Comprimir o reducir texturas excesivas.
5. Pausar esqueletos y animaciones lejanas.
6. Añadir LOD si el profiler demuestra que la geometría es el problema.
7. Reducir polígonos solo como último paso informado por mediciones.

### CODEX

- [ ] Crear escena de estrés con 25 NPC de 15k animados.
- [ ] Medir FPS, tiempo de CPU/GPU, draw calls, memoria y picos.
- [ ] Añadir logs de errores útiles en builds de prueba.
- [ ] Crear checklist de cada sala, herramienta, mejora y tipo de objeto.
- [ ] Detectar objetos inaccesibles y porcentajes imposibles de completar.
- [ ] Revisar colisiones, audio, guardado, pausas y transiciones.
- [ ] Exportar builds numeradas, nunca sobrescribir la única build estable.

### TÚ

- [ ] Probar una partida completa desde cero.
- [ ] Probar con teclado/ratón diferentes y otra resolución.
- [ ] Probar en al menos un segundo ordenador, preferiblemente inferior.
- [ ] Conseguir 3–5 testers externos.
- [ ] Registrar cada fallo con pasos, resultado esperado, resultado obtenido y severidad.
- [ ] Congelar nuevas funcionalidades durante la corrección de beta.

### Criterio de salida

- [ ] La historia completa puede terminarse desde una partida nueva.
- [ ] No existen fallos bloqueantes conocidos.
- [ ] Se cumple el objetivo de rendimiento en el equipo mínimo.
- [ ] Guardado y carga sobreviven a varias sesiones.
- [ ] Build etiquetada como `release-candidate-1`.

## FASE 12 — Entrega del TFG y publicación

### CODEX + TÚ

- [ ] Exportar build Windows x86_64 con icono y nombre definitivos.
- [ ] Crear una carpeta limpia que contenga únicamente la distribución.
- [ ] Ejecutarla en un ordenador sin el editor de Godot.
- [ ] Generar capturas representativas sin interfaz de depuración.
- [ ] Preparar vídeo corto o tráiler solo si aporta valor a la presentación.
- [ ] Preparar página privada/pública en itch.io si se desea distribuir.
- [ ] Revisar licencias de modelos, texturas, fuentes, sonidos y vídeos.
- [ ] Archivar código fuente, `.blend`, documentación y build final.
- [ ] Conservar evidencias: versiones, pruebas, decisiones, métricas y capturas.
- [ ] Redactar memoria: problema, objetivos, diseño, arquitectura, implementación, pipeline artístico, pruebas, resultados y trabajo futuro.
- [ ] Cumplir los requisitos vigentes de la UOC sobre declaración de herramientas utilizadas.

### Criterio de salida

- [ ] El tutor puede descargar, abrir y jugar sin instalar Godot.
- [ ] La memoria describe el desarrollo real y coincide con la build entregada.
- [ ] Existe una copia de seguridad final fuera del ordenador principal.
- [ ] Versión etiquetada como `v1.0.0-tfg`.

## 4. Regla para trabajar con futuros workers

Copiar este bloque al comenzar cada nueva sesión:

```text
Estamos desarrollando Cinema Cleaner en Godot 4 con GDScript para Windows.
Lee el plan de desarrollo y trabaja únicamente en la fase que te indique.
No cambies motor, lenguaje, estructura o alcance sin justificar primero el impacto.
No modifiques archivos ajenos a la fase activa.
Antes de implementar, inspecciona el estado real del repositorio y enumera lo que ya existe.
Usa placeholders cuando una mecánica pueda validarse sin arte final.
No generes assets definitivos antes de superar el criterio de salida de su fase.
Al terminar, entrega:
1. Archivos creados o modificados.
2. Funcionalidad implementada.
3. Pruebas realizadas y resultado.
4. Riesgos o deuda técnica introducida.
5. Pasos manuales que debo ejecutar en Godot, Blender o Meshy.
6. Confirmación de si se cumple el criterio de salida.
Detente al finalizar la fase y espera mi aprobación.
```

## 5. Próximos pasos inmediatos

[Cierto] El siguiente trabajo no es generar más personajes ni maquinaria. Es validar el controlador y el núcleo de limpieza con primitivas.

1. [ ] Descargar Godot Standard y sus Export Templates.
2. [ ] Descargar Blender LTS.
3. [ ] Instalar Git, Git LFS y VS Code.
4. [ ] Crear la carpeta y el repositorio privado.
5. [ ] Entregar este documento al siguiente worker.
6. [ ] Pedirle que realice únicamente la **FASE 0**.
7. [ ] Probar el resultado y aprobarlo antes de comenzar la **FASE 1**.

