param(
    [string]$Godot = 'godot',
    [string]$Python = 'python'
)
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).ProviderPath
$version='pec2-v0.1.0'
$output=Join-Path $taskRoot ('builds/'+$version)
$archive=Join-Path $taskRoot ('builds/'+$version+'-windows-x86_64.zip')
$profile=Join-Path $taskRoot '.godot/pec2_export_appdata'
$templates=Join-Path $profile 'Godot/export_templates/4.7.2.stable'
$previousAppData=$env:APPDATA
$previousTemp=$env:TEMP
$previousTmp=$env:TMP
$previousDirectory=Get-Location
try {
    Set-Location -LiteralPath $taskRoot
    $engineVersion=(& $Godot --version | Out-String).Trim()
    if ($engineVersion -notlike '4.7.2.stable*') { throw 'Esta entrega requiere Godot 4.7.2 Standard.' }
    if (-not (Test-Path -LiteralPath (Join-Path $templates 'download_manifest.json'))) {
        & $Python tools/build/download_windows_templates.py --output $templates
        if ($LASTEXITCODE -ne 0) { throw 'No se pudieron descargar las plantillas oficiales.' }
    }
    $templateManifest=Get-Content -Raw (Join-Path $templates 'download_manifest.json') | ConvertFrom-Json
    foreach ($entry in $templateManifest.files) {
        $hash=(Get-FileHash -LiteralPath (Join-Path $templates $entry.name) -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $entry.sha256) { throw ('Plantilla alterada: '+$entry.name) }
    }
    New-Item -ItemType Directory -Force -Path $output | Out-Null
    $temporary=Join-Path $taskRoot '.godot/pec2_export_tmp'
    New-Item -ItemType Directory -Force -Path $temporary | Out-Null
    $env:APPDATA=$profile
    $env:TEMP=$temporary
    $env:TMP=$temporary
    & $Godot --headless --path $taskRoot --export-release 'Windows x86_64 PEC2' (Join-Path $output 'CinemaCleaner.exe') > .godot/pec2-export.stdout 2> .godot/pec2-export.stderr
    if ($LASTEXITCODE -ne 0) { Get-Content .godot/pec2-export.stderr -Tail 35; throw 'Ha fallado la exportación.' }
    $errors=@(Get-Content .godot/pec2-export.stderr | Where-Object { $_ -match '^(ERROR|SCRIPT ERROR):' })
    if ($errors.Count -gt 0) { $errors; throw 'Godot ha registrado errores de exportación.' }
    foreach ($required in @('CinemaCleaner.exe','CinemaCleaner.pck')) {
        if (-not (Test-Path -LiteralPath (Join-Path $output $required))) { throw ('Falta '+$required) }
    }
    $commit=(& git -c ('safe.directory='+$taskRoot.Replace('\','/')) rev-parse HEAD).Trim()
    $instructions=@"
CinemaCleaner: La última sesión — PEC 2
Versión: $version

Extrae el ZIP completo y abre CinemaCleaner.exe en Windows de 64 bits.
Mantén CinemaCleaner.pck en la misma carpeta. No necesitas instalar Godot.

WASD: moverse. Ratón: mirar. Clic derecho: recoger.
Clic izquierdo: escoba/aspiradora. E: interactuar y entregar basura.
Q: cambiar herramienta. Tab: diario. Esc: pausa.

Nueva partida reinicia el progreso. Continuar carga el autoguardado.
Guardado: %APPDATA%\Godot\app_userdata\Cinema Cleaner\cinema_cleaner_save.json

Commit: $commit
Motor integrado: $engineVersion
"@
    $utf8=[System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText((Join-Path $output 'LEEME.txt'),$instructions,$utf8)
    $manifest=[ordered]@{version=$version;commit=$commit;engine=$engineVersion;platform='Windows x86_64';files=@()}
    foreach ($filename in @('CinemaCleaner.exe','CinemaCleaner.pck','LEEME.txt')) {
        $file=Get-Item -LiteralPath (Join-Path $output $filename)
        $manifest.files+=@{name=$filename;size=$file.Length;sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
    }
    [System.IO.File]::WriteAllText((Join-Path $output 'build-info.json'),($manifest|ConvertTo-Json -Depth 4),$utf8)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    if (Test-Path -LiteralPath $archive) { throw 'El ZIP ya existe; conserva la descarga anterior antes de generar otra.' }
    $zip=[System.IO.Compression.ZipFile]::Open($archive,[System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($filename in @('CinemaCleaner.exe','CinemaCleaner.pck','LEEME.txt','build-info.json')) {
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(Join-Path $output $filename),$filename,[System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally { $zip.Dispose() }
    $zipHash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    [System.IO.File]::WriteAllText(($archive+'.sha256'),$zipHash+'  '+[System.IO.Path]::GetFileName($archive)+"`n",$utf8)
    Get-Item -LiteralPath $archive | Select-Object Name,Length
    Write-Output ('SHA256='+$zipHash)
} finally {
    $env:APPDATA=$previousAppData
    $env:TEMP=$previousTemp
    $env:TMP=$previousTmp
    Set-Location -LiteralPath $previousDirectory
}
