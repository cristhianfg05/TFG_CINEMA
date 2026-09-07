# Cinema Cleaner

Proyecto de TFG: juego de limpieza en primera persona desarrollado con Godot 4 y GDScript para Windows.

## Abrir el proyecto

1. Instala Godot 4.7 Standard (no .NET).
2. Clona el repositorio con Git LFS instalado.
3. Ejecuta `git lfs pull`.
4. Importa la carpeta desde el Project Manager de Godot o ejecuta `godot --editor --path .`.
5. Pulsa F5 para abrir el menú principal. `Nueva partida` borra el progreso anterior y `Continuar` carga el autoguardado.

La fase activa y sus límites están documentados en `docs/GAME_SCOPE.md`. No se debe iniciar una fase posterior antes de cumplir el criterio de salida de la actual.

Durante la FASE 4, la galería técnica de personajes puede abrirse desde `scenes/art/phase_4_character_showcase.tscn`. La partida normal ya usa el modelo importado del manager; los demás esperan a disponer de rig y animaciones compatibles.
