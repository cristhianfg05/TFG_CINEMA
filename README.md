# CinemaCleaner: La última sesión

Proyecto de TFG: juego de limpieza en primera persona desarrollado con Godot y GDScript para Windows. Estética low-poly, cuatro salas construidas y una sala final pendiente de completar.

## Requisitos

- **Godot 4.7.2 Standard**, edición de 64 bits. Es la versión con la que se valida el proyecto; no necesita .NET.
- **Git y Git LFS**, para descargar los modelos, texturas, vídeos y sonidos del repositorio.
- El proyecto utiliza el renderizador **Forward+**.

Blender, los modelos locales de audio y las conexiones MCP son herramientas de producción. No hace falta instalarlas ni conectar sus servicios para abrir el juego: Godot utiliza los assets ya exportados. El directorio `addons/` forma parte del proyecto y debe conservarse.

## Descargar los assets

Clona este repositorio y abre una terminal en su carpeta raíz, donde está `project.godot`. Después ejecuta:

```powershell
git lfs install
git lfs pull
```

La carpeta `.godot/` contiene cachés locales y se genera automáticamente. Los originales pesados de `source_assets/local_originals/` no se versionan y no son necesarios para jugar.

## Abrir el proyecto en Godot

Desde la raíz del repositorio:

```powershell
godot -e
```

El comando equivalente, indicando expresamente la carpeta, es:

```powershell
godot --editor --path .
```

Para disponer del comando `godot` en Windows, puedes guardar el ejecutable de Godot como `godot.exe` en una carpeta fija y añadir esa carpeta al `PATH` de usuario. Abre una terminal nueva y comprueba que `godot --version` muestra `4.7.2.stable`. Si ya tienes un lanzador `godot.cmd`, sirve igualmente.

También puedes abrirlo sin configurar el `PATH`:

- Desde el **Project Manager** de Godot, pulsa **Importar** y selecciona el archivo `project.godot` de este repositorio.
- Desde PowerShell, ejecuta el editor con su ruta completa, sustituyendo la ruta del ejemplo por la de tu instalación:

```powershell
& 'C:\ruta\a\Godot_v4.7.2-stable_win64.exe' --editor --path .
```

Espera a que termine la primera importación de assets. Pulsa **F5** para ejecutar el proyecto completo: la escena principal es `scenes/main/main_menu.tscn`. **Nueva partida** reinicia el progreso y **Continuar** carga el autoguardado. F6 ejecuta únicamente la escena que tengas abierta en el editor.

Para ejecutar el juego directamente desde la terminal:

```powershell
godot --path .
```

Si Windows no reconoce `godot`, revisa el `PATH` o utiliza la ruta completa. Si faltan modelos, sonidos o vídeos después de clonar, comprueba que Git LFS está instalado y repite `git lfs pull` antes de reimportar el proyecto.

## Pruebas

Las pruebas recientes del sistema incremental usan guardados propios. Para aislar además los datos de Godot, ejecuta desde la raíz este bloque de PowerShell; al terminar restaura `APPDATA`:

```powershell
$previousAppData = $env:APPDATA
try {
    $env:APPDATA = Join-Path (Get-Location) '.godot/readme_test_appdata'
    godot --headless --path . --script tests/incremental_update_smoke.gd
    if ($LASTEXITCODE -ne 0) {
        throw 'Ha fallado la prueba del sistema incremental.'
    }
} finally {
    $env:APPDATA = $previousAppData
}
```

Las pruebas de renderizado necesitan una ventana y no deben ejecutarse con `--headless`. Los tests históricos de las primeras fases describen versiones anteriores del juego; no todos representan su comportamiento actual.

## Documentación

- [Sistemas incrementales, economía y herramientas](docs/balance/INCREMENTAL_PHASE_B_IMPLEMENTATION.md).
- [Distribución de salas](docs/pipeline/CINEMA_MAP_EXPANSION.md).
- [Sistema de grabaciones](docs/pipeline/GAME_RECORDING_SYSTEM.md).
- [Pipeline de assets](docs/pipeline/ASSET_PIPELINE.md).
- [Pipeline de audio](docs/pipeline/AUDIO_PIPELINE.md) y [criterios de generación y mezcla](docs/pipeline/AUDIO_BIBLE.md).
- [Registro de pruebas](docs/TEST_LOG.md).

Los informes de Fase 4 y las referencias a builds `0.4.0-playtest.*` documentan pilotos anteriores. Las builds exportadas son locales y no se incluyen en el repositorio; no son necesarias para abrir `project.godot` en el editor.
