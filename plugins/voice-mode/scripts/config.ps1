# Settings shared by voice.ps1 and voice-mode.ps1. They live in one folder in the home directory, so
# Claude Code and Codex use the same settings, and hooks and the skill always find them.

$VoiceDataDir = if ($env:VOICE_MODE_DIR) { $env:VOICE_MODE_DIR } else { Join-Path $HOME '.voice-mode' }

function Read-VoiceConfig {
    $config = [ordered]@{
        mode              = 'auto'
        remoteIdleSeconds = 60
        awayMinutes       = 10
        maxChars          = 3000
        server            = 'https://ntfy.sh'
        topic             = ''
        phrases           = [ordered]@{
            code     = 'Skipping a code block.'
            table    = 'Skipping a table.'
            link     = 'link'
            rest     = 'The rest of the reply is in the terminal.'
            approval = 'Your agent needs your approval in project {project}.'
            test     = 'Voice mode test. If you can hear this, everything works.'
        }
    }
    $path = Join-Path $VoiceDataDir 'config.json'
    if (Test-Path -LiteralPath $path) {
        $saved = Get-Content -LiteralPath $path -Raw -Encoding utf8 | ConvertFrom-Json -AsHashtable
        foreach ($key in $saved.Keys) {
            if ($key -eq 'phrases') {
                foreach ($phrase in $saved.phrases.Keys) { $config.phrases[$phrase] = $saved.phrases[$phrase] }
            } else {
                $config[$key] = $saved[$key]
            }
        }
    }
    $config
}

function Write-VoiceConfig($Config) {
    $null = New-Item -ItemType Directory -Force $VoiceDataDir
    $Config | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $VoiceDataDir 'config.json') -Encoding utf8NoBOM
}
