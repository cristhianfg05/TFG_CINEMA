# Películas y carteles por sala

Los archivos originales subidos por el equipo permanecen aquí sin modificaciones. Actualmente `room_1/` contiene `Movie1.mp4`, `Movie2.mp4`, `Movie3.mp4` (H.264, 1280×720, 24 fps, 8 s cada uno) y `Movie_Cartel.jpeg`. `room_2/` a `room_5/` contienen sus respectivos `Movie_Cartel.jpeg`.

Godot reproduce Ogg Theora. Las copias de ejecución de Sala 1 están en `assets/pipeline/movies/room_1/Movie_1.ogv` a `Movie_3.ogv`, sin audio embebido. El controlador de Sala 1 está configurado temporalmente para **3 clips**. Cuando llegue el cuarto, se convierte a `Movie_4.ogv` en la misma carpeta y se cambia `clip_count` a 4 en `scenes/main/main.tscn`.

Las películas ordinarias de Salas 2–4 están preparadas para cuatro clips `Movie_1.ogv` … `Movie_4.ogv`; cuando lleguen originales MP4 se crearán sus copias de ejecución en `assets/pipeline/movies/room_N/` y se actualizará `movie_folder`. Sala 5 es el final especial: su cartel original se conserva, pero **no** se instala como cartel ordinario de entrada ni se le asigna aún película o palanca estándar.

Los carteles de Salas 1 y 2 se muestran en sus entradas con el shader reversible `shaders/cinema_aged_poster.gdshader`, que añade desgaste y suciedad muy sutiles sin editar sus JPEG. El mismo material está listo para Salas 3 y 4 cuando se construyan sus entradas.
