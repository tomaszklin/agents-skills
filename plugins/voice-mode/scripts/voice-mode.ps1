# Switches voice mode (short replies without tables when a prompt comes from the phone).
# Usage: voice-mode.ps1 <data dir> [on|off|always|status|push <topic>|push off|test]
# Called by the /voice-mode:mode command.
#   on           - rules only when you write from the phone; "auto" in config.json
#   off          - never; normal replies with tables
#   always       - always, also at the desk; "on" in config.json
#   status       - (default) only shows the state
#   push <topic> - also sends replies to the phone through this ntfy topic
#   push off     - stops sending replies to the phone
#   test         - sends a test message to the phone
param(
    [Parameter(Mandatory)][string]$DataDir,
    [string]$Action = 'status',
    [string]$Value = ''
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

. (Join-Path $PSScriptRoot 'config.ps1')

$config = Read-VoiceConfig $DataDir
$changed = $true

switch ($Action.Trim().ToLowerInvariant()) {
    { $_ -in 'on', 'auto' } { $config.mode = 'auto' }
    'off' { $config.mode = 'off' }
    'always' { $config.mode = 'on' }
    'push' {
        if (-not $Value) { Write-Output 'Give an ntfy topic: /voice-mode:mode push <topic>, or push off to stop.'; exit 0 }
        $config.topic = if ($Value -eq 'off') { '' } else { $Value }
    }
    'test' {
        if (-not $config.topic) { Write-Output 'No ntfy topic set. First run /voice-mode:mode push <topic>.'; exit 0 }
        & (Join-Path $PSScriptRoot 'voice.ps1') test $DataDir
        exit 0
    }
    { $_ -in '', 'status' } { $changed = $false }
    default { Write-Output "Unknown option: $Action. Use on, off, always, status, push <topic>, push off or test."; exit 0 }
}

if ($changed) { Write-VoiceConfig $DataDir $config }

$description = switch ($config.mode) {
    'auto' { 'on: short replies without tables when you write from your phone (computer idle for a minute)' }
    'off' { 'off: always normal replies, with tables' }
    'on' { 'always on: short replies without tables, also at the desk' }
    default { "unknown ($($config.mode))" }
}
$push = if ($config.topic) { 'Replies also go to your phone through ntfy.' } else { 'Replies are not sent to your phone.' }
$prefix = if ($changed) { 'Saved. ' } else { '' }
Write-Output "${prefix}Voice mode is $description. $push Settings: $(Join-Path $DataDir 'config.json'). Changes apply from your next message."
