# Estado y preparación de MCP

## Estado tras la fase 1

No se ha instalado ni registrado ningún MCP en esta fase. Esta decisión evita introducir dependencias o cambios en addons mientras se crea la infraestructura documental.

Comprobaciones realizadas:

- Blender instalado: 5.2.2 LTS.
- Node disponible: 24.19.0.
- `uv`, `uvx` y `npm` no están disponibles en PATH.
- No se detectó un ejecutable de Godot en PATH o en el registro de instalaciones, aunque `project.godot` declara Godot 4.7.
- El proyecto no contiene actualmente un directorio `addons/`.

## Fase 2 prevista

La instalación se hará exclusivamente a partir de las instrucciones vigentes de los repositorios upstream:

- Blender MCP: `ahujasid/mcp-for-blender`.
- Godot MCP: `mkdevkit/godot-mcp`.

Antes de instalar, la fase 2 verificará versiones, compatibilidad y los requisitos faltantes. Si hay una incompatibilidad, se detendrá antes de realizar una instalación parcial o destructiva.

## Configuración de Codex prevista

Los servidores se documentarán y registrarán con los nombres:

- `blender`: proceso STDIO `uvx mcp-for-blender`, con `BLENDER_MCP_SAFE_MODE=1`.
- `godot`: comando y argumentos determinados por el README upstream validado en la fase 2.

La configuración personal de Codex vive fuera del repositorio, normalmente en `~/.codex/config.toml`. No se guardarán secretos en el repositorio. Tras instalar se documentarán las entradas añadidas, el puerto, la activación/desactivación, la comprobación de conexión y la desinstalación.

## Pasos manuales pendientes

Los pasos exactos de Blender —habilitar addon y arrancar servidor— y los de Godot —activar plugin y ejecutar prueba— se añadirán tras validar las instrucciones upstream y la compatibilidad local en la fase 2.
