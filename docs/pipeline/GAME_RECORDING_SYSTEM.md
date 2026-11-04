# Grabaciones narrativas: primera integración

La grabación 01 se inicia una sola vez al comenzar **Nueva partida**, en el mismo momento en que aparece «E para levantarte». `GameplayManager.loaded_save` indica si se cargó un guardado válido; en «Continuar» la grabación no se reproduce. El control de la primera secuencia está en `scripts/game_intro.gd`, sin modificar el sonido opcional `intro_audio_stream` preexistente.

Secuencia: `cassette_recorder_start_02.wav` → cuatro frases escritas a 45 ms por carácter con `dialogue_soft_typing_03_loop.wav` → cada frase completa permanece 1 s sin tecleo → el mismo casete al terminar. Ambos reproductores usan el bus `UI`; el WAV de tecleo se duplica en memoria para activar su loop sin alterar el archivo aprobado. Si el jugador se levanta mientras se escribe, el cuadro permanece hasta acabar la grabación. Al pausar el juego, tiempo y sonidos de la grabación se suspenden y el cuadro se oculta para no tapar el menú.

El cuadro `RecordingPanel` está dentro de `RecordingCanvas`. Durante la pantalla de «E para levantarte», su capa 51 queda por delante de los párpados negros de `IntroOverlay` (capa 50), para que el texto se vea. Al levantarse baja a capa 9, detrás del HUD (capas 10 y 11). Mientras la grabación está activa, `GameplayHUD.set_recording_layout_active()` eleva en 0,34 s la estamina, las tarjetas de herramientas (incluida aspiradora), la batería y el aviso contextual. La zona central inferior se ordena entonces de arriba abajo: estamina, inventario con batería, grabación. Al terminar el casete final, esos controles regresan con la misma transición a sus posiciones habituales de la parte baja. El modelo 3D de aspiradora en primera persona no se mueve. La caja queda al fondo (margen de 16 px), mide 700 × 138 px en el canvas de 1920 × 1080 y conserva el fondo negro con alfa 0,78 y texto amarillo de 26 px comprobado en dos líneas. El título/narrador sale del catálogo de grabaciones. No captura ratón ni entradas.

## Archivo y grabaciones 02–17

La quinta pestaña de Tab es **Grabaciones**, junto a Documentos, con icono propio de casete en el mismo estilo. Solo lista grabaciones descubiertas y muestra su transcripción y narrador; nunca indica un total ni enseña las entradas desconocidas. `resources/recordings/recording_catalog.gd` conserva los textos corregidos. `GameplayManager` guarda por separado las cintas descubiertas y escuchadas (save v11, compatible con v10); `scripts/recording_director.gd` detecta los eventos y encola cada reproducción para que no se solape con otra. Se reutilizan la caja, el casete, el tecleo y el movimiento del HUD de la grabación 01.

| Grabación | Activación |
| --- | --- |
| 02 | Sala 1 completada al 95 % y salida desbloqueada. |
| 03 | Primera entrada en el despacho del manager. |
| 04 | Cerrar el documento 5 después de leerlo. |
| 05 | Primera entrada en la sala 2 romántica. |
| 06 | Cerrar el documento 4 después de leerlo. |
| 07 | Entrar por primera vez en el vestíbulo. |
| 08 | Acercarse a la entrada principal del cine desde el vestíbulo. |
| 09 | Encontrar cualquier figura del Palace (no un cartel). |
| 10 | Encontrar 5 de las 10 figuras (los carteles no cuentan). |
| 11 | Primera entrada en la sala 4 de miedo. |
| 12 | Primera entrada en la sala 3 de acción. |
| 13 | Cerrar el documento médico 9 después de leerlo. |
| 14 | Alcanzar el 100 % en todas las zonas actuales salvo la sala final. |
| 16 | Cerrar el documento 11 después de leerlo. |
| 17 | Encontrar las 10 figuras, sin contar carteles. |

Las grabaciones 15 y 18 quedan **pendientes de texto y evento**: no se crean entradas vacías. «Manager» sigue apareciendo en la caja y el archivo hasta reproducir la 13; desde esa misma cinta, la 13 y las posteriores muestran «Mateo». Las grabaciones anteriores conservan «Manager».

Los textos de los documentos 4, 5, 9 y 11 existen en `assets/notes/`, y sus eventos ya están conectados, pero ahora mismo en el mapa solo están colocados los documentos 1 y 2. Esos cuatro eventos no se pueden alcanzar jugando hasta que se coloquen sus pickups. De las diez figuras solo está implementada la primera, por lo que las grabaciones 10 y 17 esperan las restantes. La 14 no entrega aún la maza: ese objeto y la sala final pertenecen a una fase futura.

Validación: `tests/recording_intro_smoke.gd` comprueba orden, bucle, silencio entre líneas, segundo de permanencia, capas, geometría vertical, subida/bajada intermedias y finales del HUD y exclusión de «Continuar». `tests/recording_intro_visual_capture.gd` captura la pantalla de E en `.godot/recording_intro_e_prompt_capture.png`, confirma que hay texto amarillo visible allí y verifica la superposición real del HUD sobre la caja. También genera `.godot/recording_intro_visual_capture.png` con grabación activa y `.godot/recording_intro_hud_restored_capture.png` tras terminarla, sin tocar el guardado del usuario.

`tests/recording_archive_smoke.gd` comprueba pestaña sin contador, disparadores disponibles, cierre de documentos, exclusión de carteles, cola, persistencia y revelación de Mateo. `tests/recording_archive_visual_capture.gd` genera `.godot/recording_archive_visual.png` con un guardado temporal aislado para revisar la disposición del menú; los avisos de RIDs al salir de esa captura son del cierre del render de Godot y no aparecen en las pruebas headless.
