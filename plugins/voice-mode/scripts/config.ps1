# Settings shared by voice.ps1 and voice-mode.ps1. They live in the plugin data directory, because
# the plugin folder itself is replaced on every update.

function Read-VoiceConfig([string]$DataDir) {
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
            approval = 'Claude needs your approval in project {project}.'
            test     = 'Voice mode test. If you can hear this, everything works.'
        }
    }
    $path = Join-Path $DataDir 'config.json'
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

function Write-VoiceConfig([string]$DataDir, $Config) {
    $null = New-Item -ItemType Directory -Force $DataDir
    $Config | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $DataDir 'config.json') -Encoding utf8NoBOM
}
