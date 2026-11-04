<#
Generates the approval-only candidates for the remaining Priority 1 audio
families. Existing candidates are deliberately preserved, so interrupted runs
can resume safely.
#>

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$python = "C:\Users\crist\.codex\tools\stable-audio-3\optimized\tflite\.venv\Scripts\python.exe"
$generator = Join-Path $projectRoot "tools\audio\generate_audio.py"

$families = @(
    @{ Name = "trash_pickup"; Folder = "trash"; BaseSeed = 1100; Prompt = "soft pickup of light mixed cinema litter: paper cup, popcorn crumbs and aluminum can, friendly stylized low-poly game sound effect, dry close recording, no music, no voices, no harsh highs" },
    @{ Name = "bag_full"; Folder = "bags"; BaseSeed = 1200; Prompt = "gentle full trash bag feedback: soft fabric tension and rubbery puff, short friendly stylized low-poly game sound effect, readable but not alarming, dry close recording, no music, no voices, no harsh highs" },
    @{ Name = "bag_seal"; Folder = "bags"; BaseSeed = 1300; Prompt = "closing and knotting a small trash bag: soft plastic rustle and fabric cinch, satisfying friendly stylized low-poly game sound effect, dry close recording, no music, no voices, no harsh highs" },
    @{ Name = "bag_throw"; Folder = "bags"; BaseSeed = 1400; Prompt = "small sealed trash bag tossed through the air: soft plastic and cloth whoosh, light friendly stylized low-poly game movement sound effect, dry close recording, no impact, no music, no voices, no harsh highs" },
    @{ Name = "bin_delivery"; Folder = "trash"; BaseSeed = 1500; Prompt = "delivering a small tied trash bag into a cinema bin: soft plastic and padded bin thump, satisfying friendly stylized low-poly game sound effect, dry close recording, no music, no voices, no harsh highs" },
    @{ Name = "coin_reward"; Folder = "rewards"; BaseSeed = 1600; Prompt = "small coin reward sparkle with a soft warm chime, cheerful restrained stylized low-poly game sound effect, short and readable, no music, no voices, no harsh highs" }
)

foreach ($family in $families) {
    for ($variant = 1; $variant -le 5; $variant++) {
        $output = Join-Path $projectRoot ("audio_source\raw\sfx\{0}\{1}_{2:D2}.wav" -f $family.Folder, $family.Name, $variant)
        if (Test-Path -LiteralPath $output) {
            continue
        }

        & $python $generator sfx --seconds 2 --seed ($family.BaseSeed + $variant) --prompt $family.Prompt --output $output
        if ($LASTEXITCODE -ne 0) {
            throw "Stable Audio generation failed for $($family.Name) variant $variant."
        }
    }
}
