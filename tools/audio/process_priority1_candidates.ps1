<# Converts the Priority 1 approval candidates to Godot-ready WAV files. #>

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$python = "C:\Users\crist\.codex\tools\stable-audio-3\optimized\tflite\.venv\Scripts\python.exe"
$processor = Join-Path $projectRoot "tools\audio\process_audio.py"

$families = @(
    @{ Name = "trash_pickup"; Folder = "trash" },
    @{ Name = "bag_full"; Folder = "bags" },
    @{ Name = "bag_seal"; Folder = "bags" },
    @{ Name = "bag_throw"; Folder = "bags" },
    @{ Name = "bin_delivery"; Folder = "trash" },
    @{ Name = "coin_reward"; Folder = "rewards" }
)

foreach ($family in $families) {
    for ($variant = 1; $variant -le 5; $variant++) {
        $name = "{0}_{1:D2}.wav" -f $family.Name, $variant
        $source = Join-Path $projectRoot ("audio_source\raw\sfx\{0}\{1}" -f $family.Folder, $name)
        $output = Join-Path $projectRoot ("assets\audio\sfx\{0}\{1}" -f $family.Folder, $name)
        if (-not (Test-Path -LiteralPath $source)) {
            throw "Missing raw candidate: $source"
        }
        if (Test-Path -LiteralPath $output) {
            continue
        }
        & $python $processor $source $output
        if ($LASTEXITCODE -ne 0) {
            throw "Audio processing failed for $source."
        }
    }
}
