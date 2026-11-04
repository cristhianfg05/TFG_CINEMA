# Informe de assets — FASE 4

Actualizado: 2026-09-08. Blender 5.2.1 LTS y Godot 4.7. Estado: candidata para feedback manual; fase abierta, sin etiqueta de cierre.

## Integrado en la partida

| Asset | Fuente editable | GLB de producción | Triángulos | Materiales |
|---|---|---|---:|---:|
| Manager con rig piloto | `source_assets/blender/characters/rigged/npc_manager_rig_v002.blend` | `assets/characters/production/npc_manager_rigged.glb` | 14.974 | 1 |
| Cubo de palomitas vacío | `source_assets/blender/props/trash_popcorn_bucket.blend` | `assets/models/trash/production/trash_popcorn_bucket.glb` | 384 | 1 |
| Vaso abierto | `source_assets/blender/props/trash_paper_cup.blend` | `assets/models/trash/production/trash_paper_cup.glb` | 384 | 1 |
| Lata | `source_assets/blender/props/trash_drink_can.blend` | `assets/models/trash/production/trash_drink_can.glb` | 524 | 1 |

El cubo tiene 22 cm de altura, 20 cm de diámetro superior y 14 cm de base. El vaso mide 14 cm de alto, 9 cm arriba y 6 cm en la base. La lata mide 12 cm de alto y 6,6 cm de diámetro. Son medidas propuestas y confirmadas por el usuario, no cotas extraídas de las referencias.

El usuario aprobó colores y medidas del cubo y autorizó continuar con vaso y lata en la misma dirección sin nuevas paradas de aprobación. Cada modelo se creó individualmente, se conservó su borrador `.blend`, se renderizó y revisó antes de exportar.

Se sustituyen siete instancias dentro de las veinte basuras existentes: dos cubos, tres vasos y dos latas. Se mantienen recompensas, volumen lógico, cooldown y clic derecho. Las colisiones físicas son cilindros de tamaño real; el área de apuntado mantiene un mínimo de 0,24 m para facilitar seleccionar los objetos pequeños. El resaltado se aplica mediante una capa de material y conserva los colores originales.

La basura utiliza colores por vértice, sin texturas externas. Los materiales de los contenedores activan explícitamente esa opción en Godot: el material importado no la estaba activando. Los tres `.blend` tienen UV y superficie cerrada; los bordes separados del GLB corresponden a discontinuidades de normales/UV/color. Una soldadura de posiciones sobre una copia de auditoría deja cero bordes abiertos. No se ha soldado ni alterado el GLB por ese motivo. La abertura de la lata está representada mediante un inserto oscuro cerrado; no es un agujero pasante.

## Rig piloto del manager

- El original `npc_manager.blend`, el GLB estático y los originales Meshy se conservan.
- Rig creado por script propio en Blender, no mediante Auto Rig de Meshy; el usuario autorizó realizarlo localmente.
- 23 huesos con nombres compatibles con `SkeletonProfileHumanoid`; `resources/characters/manager_bone_map.tres` registra la correspondencia.
- T-pose conservada como referencia. El clip `Manager_HeadIdle` coloca los brazos relajados y mueve únicamente cuello y cabeza durante un bucle de 6 segundos.
- Pesos normalizados, máximo dos influencias por vértice. La asignación utiliza referencias anatómicas específicas de este manager y no debe aplicarse automáticamente a otros NPC.
- En cinco muestras del ciclo: cambio máximo de longitud de arista respecto a la postura relajada 2,93 %, desplazamiento de pies 0 m, separación máxima de vértices coincidentes inferior a 0,001 mm.
- Un material, tres texturas PBR 2048 × 2048, escala aplicada y pies en el origen. El contenedor mantiene el frente jugable hacia -Z y la colisión simple independiente.
- La tienda continúa usando `scripts/manager_npc.gd`, sin cambios en su lógica. La animación se controla por `scripts/manager_idle.gd` y hereda la pausa del árbol.

### Límites y deuda técnica

El manager conserva 6.888 bordes topológicamente abiertos del modelo importado. Tras soldar posiciones coincidentes en una copia de auditoría quedan 863 bordes abiertos; por tanto, no todos se explican por las costuras de exportación. No se han cerrado indiscriminadamente ojos, boca, ropa o separaciones de la malla.

Los dedos están ligados rígidamente a cada mano; no hay rig facial ni de dedos. El BoneMap valida nombres y correspondencia, pero no demuestra todavía retargeting de animaciones externas, deformaciones amplias de extremidades ni compatibilidad final entre todos los NPC. Los pesos y el movimiento leve necesitan aprobación visual humana.

Blender crea una malla auxiliar para mostrar ciertos huesos al reimportar un GLB. `audit_glb.py` la excluye de los presupuestos: no forma parte del GLB de juego.

## Resto de personajes

Los otros tres personajes solo aparecen en la galería técnica `scenes/art/phase_4_character_showcase.tscn`, sin rig nuevo y sin sustituir espectadores:

| Personaje | Altura | Triángulos | Materiales |
|---|---:|---:|---:|
| Hombre corpulento | 1,80 m | 14.975 | 1 |
| Empleado de palomitas | 1,90 m | 14.969 | 1 |
| Chico joven | 1,80 m | 14.975 | 1 |

La galería de props es `scenes/art/phase_4_props_showcase.tscn`. No se ha construido arquitectura ni contenido de FASE 5.

## Validación automática y rendimiento

- Smoke de FASES 1, 2, 3 y 4 superados secuencialmente con APPDATA aislado; el guardado personal del usuario no se utiliza.
- FASE 4 verifica dimensiones, materiales, colisiones, siete sustituciones, apuntado, resaltado, 23 huesos, BoneMap, autoplay, movimiento de cabeza, inmovilidad de pies y continuidad del ciclo.
- Reimportación explícita de los cuatro GLB mediante `EditorFileSystem.reimport_files`; SHA-256 de once escenas/scripts/recursos sin cambios y smoke posterior superado.
- Revisados renders de Blender y de Godot: tres props, sala jugable y manager detrás de su mesa.

Perfil automático Forward+, RTX 2060, 1920 × 1080, con dos segundos de calentamiento y cinco de muestreo por vista:

| Vista estática | FPS observados | GPU media | CPU render media | Draw calls | Memoria estática |
|---|---:|---:|---:|---:|---:|
| Sala desde el inicio | 236,1 | 0,95 ms | 1,83 ms | 227 | 63,5 MB |
| Manager y mesa | 417,9 | 0,96 ms | 0,58 ms | 23 | 62,8 MB |

Son mediciones breves de vistas estáticas con ventana oculta/fuera de pantalla y VSync desactivado. El compositor puede cambiar el ritmo; no acreditan rendimiento sostenido mientras se juega ni cumplimiento en el hardware mínimo. Queda pendiente el playtest humano.

Los procesos de Godot emiten en este entorno aislado un error de acceso al almacén de certificados raíz; no hubo fallos de las aserciones en los smoke finales. La herramienta temporal de reimportación emitió avisos de recursos/RID al cerrar el editor tras recargar escenas; no aparecen en los smoke normales. Blender también avisó del acceso denegado a su caché de extensiones local. Ninguno de esos avisos se ha presentado como una prueba superada sin incidencias.

## Build para feedback

La candidata actual es `builds/CinemaCleaner_0.4.0-playtest.2_Windows_x86_64/CinemaCleaner.exe`, junto con su `.pck`. Se conservan la build de FASE 3 y la `.1` de FASE 4. El usuario ha confirmado que las mecánicas funcionan, pero notificó vibración/ghosting aparente en la cabeza del manager al desplazarse lateralmente. La `.2` incorpora la corrección descrita abajo; su percepción visual necesita nueva prueba manual.

EXE verificado al arrancar el menú con Vulkan y en modo headless; ambos terminan con código 0. Smoke 1–3 y prueba de movimiento superados sobre el PCK usando el ejecutable del motor. ZIP `.2` de 46.130.157 bytes con EXE/PCK comparados por SHA-256. El arranque técnico exige redirigir stdout/stderr en este entorno; sin redirección también falló la build anterior `.1` (detalle en `TEST_LOG.md`).

El preset de FASE 4 excluye fuentes de autoría, referencias conceptuales, tests, galerías y los otros tres NPC de producción. Exporta los recursos de gameplay, incluidos los cargados desde scripts.

### Corrección de estabilidad visual, 2026-09-08

El diagnóstico en Godot encontró un único mesh con skin, sin material overlay, TAA desactivado, escalado bilineal y ningún antialiasing. La animación importada mantiene pasos pequeños: máximo 0,0157° entre muestras de cabeza a 240 Hz durante un ciclo completo. No se ha modificado el rig ni sus fuentes.

La cámara original avanzaba a 60 Hz: a 144 FPS repitió posición en 35/60 fotogramas y dio pasos de 7,5 cm al caminar, tanto con el idle activo como detenido. Se interpola ahora la posición del ojo entre las dos últimas muestras físicas y se conserva el giro inmediato del ratón. La cámara usa coordenadas globales; el raycast permanece sincronizado con el ojo físico, con reinicio de ambas muestras al reaparecer. Esta interpolación de posición introduce como máximo un paso físico de retraso visual (16,7 ms a 60 Hz), sin añadir retraso al giro. No cambia velocidades, colisiones, compras ni valores de basura.

Se activa MSAA 4× para reducir aliasing en pelo, gafas y siluetas. Es una técnica espacial; TAA continúa desactivado. Referencias técnicas: [cámara e interpolación](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/advanced_physics_interpolation.html) y [antialiasing 3D](https://docs.godotengine.org/en/stable/tutorials/3d/3d_antialiasing.html) de Godot.

La regresión `tests/phase_4_motion.gd` mide 0/60 posiciones repetidas y pasos de 3,125 cm a 144 FPS, con idle activo y detenido. Comprueba además giro inmediato, raycast contra la mesa real y reaparición sin arrastre. Smoke 1–4 superados. Perfil estático con MSAA en RTX 2060/1080p: GPU media 1,48 ms en sala y 1,50 ms ante el manager, frente a 0,95/0,96 ms de la medición anterior sin AA. Son sesiones breves fuera de pantalla; los FPS del compositor no son una comparación fiable de rendimiento jugable.

Estas pruebas confirman la eliminación de los saltos medidos y la reducción de bordes dentados en capturas. La correspondencia con todo el efecto que percibía el usuario sigue pendiente de confirmación manual; no se declara aprobado el rig ni cerrada FASE 4.

## Pendiente para cerrar FASE 4

- Mecánicas confirmadas por el usuario; falta aprobación visual final de los assets y repetir el desplazamiento lateral ante el manager con `.2`.
- Aprobación del aspecto del manager y de cuello, cabeza, manos, pies y postura en movimiento.
- Validación jugable sostenida y aceptación o corrección de los límites geométricos del piloto.
- Completar prompts, créditos/costes y comprobantes Meshy; la cuenta de pago ya está confirmada. Registrar también la procedencia original de las imágenes conceptuales aportadas.
- Evaluar el criterio completo de cinco assets y una muestra representativa del estilo una vez aprobados los resultados; disponer de siete assets importados no equivale a tenerlos todos aprobados.
- Solo después de aprobación de cierre, crear `phase-4-art-pipeline`. No se ha creado.
