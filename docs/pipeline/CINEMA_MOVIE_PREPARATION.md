# Películas, carteles, butacas y objetivos

## Estado de las salas

Hay **cinco** IDs de sala registrados. Las Salas 1–4 forman la progresión de películas normales y el objetivo de reactivación sigue siendo `X/4`. La Sala 5 se reserva para el final diferente; no se añade por ahora una quinta palanca, un cartel ordinario ni un reproductor genérico. Solo las Salas 1 y 2 tienen geometría y pantalla física actualmente. Los controladores de Salas 3 y 4 están listos para conectarse a las futuras pantallas.

La Sala 1 dispone de tres originales MP4 de 8 segundos. Se han convertido sin audio y sin tocar los originales a `assets/pipeline/movies/room_1/Movie_1.ogv` … `Movie_3.ogv`. Su `CinemaMovieController` está configurado con `clip_count = 3` y reproduce 1→2→3→1 continuamente cuando la palanca se activa tras limpiar al 100 %. Cuando se entregue `Movie4.mp4`, convertir a `Movie_4.ogv` y cambiar el recuento a 4. Sala 2 permanece preparada, sin clips todavía; no reproduce material de prueba. El audio cinematográfico sigue saliendo de los altavoces 3D del juego, no de los MP4.

`CinemaMovieController` usa la posición real y longitud de cada clip para verificar un ciclo completo e ininterrumpido mientras el jugador está sentado. No reinicia la película al entrar, salir o sentarse. Las imágenes se proyectan en un `SubViewport` con el shader `cinema_movie_screen.gdshader`: desde esta ampliación el filtro de desenfoque es deliberadamente fuerte (`softness = 0.72`, radio 4.5 píxeles, nueve muestras) y conserva la corrección de aspecto.

Los JPEG originales de `assets/movies/room_1/` a `room_5/` se conservan. Las entradas existentes de Salas 1 y 2 exhiben su cartel mediante `CinemaPosterMaterial`, que aplica grano, manchas de borde y papel ligeramente envejecido en Godot sin alterar los títulos. Salas 3 y 4 pueden usar el mismo material cuando tengan entrada; Sala 5 queda excluida por diseño.

## Butacas

Las butacas plegadas/cerradas no tienen `CinemaSeatInteractable`: quedan 225 butacas utilizables entre Salas 1 y 2. Se desbloquean solo tras limpieza completa **y** activación de la película, y solo se pueden seleccionar desde el lado delantero que mira a la pantalla. La interacción inicia una transición de 0,62 s: el cuerpo avanza hacia el cojín mientras cámara, altura y orientación se acomodan suavemente. Durante la transición no es posible levantarse accidentalmente; después, `[E] Levantarse` usa la búsqueda existente de una salida segura. La cámara se puede girar estando sentado.

## Objetivos y persistencia

Al salir por primera vez de Sala 1 tras su progresión aparecen `¿Tienen consolas?`, `Reactiva las películas X/4` y `Limpia la Sala 2` en el menú actual. El contador mide solo las cuatro salas de película estándar activadas, no la Sala 5 final. Una sala activada añade `¿De qué será esta película?`, que solo se completa al ver un ciclo entero sentado. Los estados de activación y visionado se guardan; la Sala 5 ya tiene ID válido para su futura implementación especial.

## Validación

- `movie_system_preparation_smoke.gd`: bloqueo por limpieza/activación, exclusión de plegadas, acceso frontal, transición al sentarse, orientación, objetivos y persistencia. Pasa con los tres clips reales de Sala 1.
- `room_1_uploaded_video_smoke.gd`: reproduce los tres OGG reales en orden y loop, lee un ciclo de ~24 segundos y completa el visionado una sola vez. Pasa.
- `movie_playback_fixture_smoke.gd`: prueba previa con clips sintéticos descartables para Salas 1 y 2 simultáneas y secuencia de cuatro clips; esa fixture ya no está presente. La simultaneidad con vídeos definitivos de Sala 2 sigue pendiente de recibirlos.
- Se inspeccionaron capturas del render Vulkan real: los dos carteles encajan en sus marcos, el vídeo de Sala 1 ocupa la pantalla y la cámara sentada no atraviesa la butaca. La primera fila izquierda queda muy cerca del altavoz (elemento existente). Las capturas de diagnóstico están en `.godot/movie_visual_capture/`; el script temporal de captura se retiró tras usarse. Su cierre offscreen emitió avisos de texturas pendientes de liberar, sin errores en las pruebas headless ni en el editor MCP.
- El editor conservaba una referencia antigua a `tools/audio/cleanup_arcade_audio_tmp.gd` (archivo ajeno a estos cambios), y el catálogo de documentos avisa de 2/12 definiciones existentes.
