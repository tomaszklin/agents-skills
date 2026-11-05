# Voice mode for coding agents: spoken-style replies when you write from your phone.
#
# Called by Claude Code and Codex hooks (event JSON on stdin):
#   voice.ps1 prompt   UserPromptSubmit - marks the turn as remote and adds the speech rules for the agent
#   voice.ps1 stop     Stop             - sends the reply to the phone through ntfy (if a topic is set)
#   voice.ps1 notify   Notification (Claude Code) or PermissionRequest (Codex) - says the agent waits for approval
# Called by voice-mode.ps1:
#   voice.ps1 test     sends a test message whatever the mode
#
# A turn is "remote" when the prompt arrives while the computer is idle: typing at the keyboard
# resets the system idle timer, and a prompt sent from a phone does not.
param(
    [Parameter(Mandatory)][ValidateSet('prompt', 'stop', 'notify', 'test')][string]$Event
)

$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

. (Join-Path $PSScriptRoot 'config.ps1')

$LogPath = Join-Path $VoiceDataDir 'voice.log'
$StateDir = Join-Path $VoiceDataDir 'state'

function Write-Log([string]$Line) {
    try {
        if ((Test-Path $LogPath) -and (Get-Item $LogPath).Length -gt 200KB) { Remove-Item $LogPath }
        Add-Content -Path $LogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Event] $Line" -Encoding utf8
    } catch {}
}

function Get-IdleSeconds {
    if ($IsMacOS) {
        $match = ioreg -c IOHIDSystem | Select-String '"HIDIdleTime" = (\d+)' | Select-Object -First 1
        if ($match) { return [double]$match.Matches[0].Groups[1].Value / 1e9 }
        return 0
    }
    if ($IsLinux) {
        # xprintidle needs X11. Without it no turn counts as remote, so the "always" option is the way.
        if (Get-Command xprintidle -ErrorAction SilentlyContinue) { return [double](xprintidle) / 1000 }
        Write-Log 'xprintidle not found, cannot tell if the computer is idle'
        return 0
    }
    if (-not ('VoiceHook.IdleTime' -as [type])) {
        # Compiling takes about a second, so it happens once and the DLL stays with the settings.
        $dll = Join-Path $VoiceDataDir 'IdleTime.dll'
        if (-not (Test-Path $dll)) {
            Add-Type -OutputAssembly $dll -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace VoiceHook {
    public static class IdleTime {
        [StructLayout(LayoutKind.Sequential)]
        struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }
        [DllImport("user32.dll")]
        static extern bool GetLastInputInfo(ref LASTINPUTINFO info);
        public static double Seconds() {
            var info = new LASTINPUTINFO();
            info.cbSize = (uint)Marshal.SizeOf(info);
            if (!GetLastInputInfo(ref info)) return 0;
            return unchecked((uint)Environment.TickCount - info.dwTime) / 1000.0;
        }
    }
}
'@
        }
        Add-Type -Path $dll
    }
    [VoiceHook.IdleTime]::Seconds()
}

function Get-RemoteFlagPath($Payload) {
    $id = ([string]$Payload.session_id) -replace '[^\w-]', '_'
    Join-Path $StateDir "$id.remote"
}

function Test-ShouldSpeak($Payload) {
    switch ($Config.mode) {
        'on' { return $true }
        'off' { return $false }
    }
    if (Test-Path (Get-RemoteFlagPath $Payload)) { return $true }
    # The task was started at the desk, and the user has left since then.
    (Get-IdleSeconds) -ge ($Config.awayMinutes * 60)
}

function Get-LastAssistantText($Payload) {
    if ($Payload.last_assistant_message) { return [string]$Payload.last_assistant_message }
    $path = [string]$Payload.transcript_path
    if (-not $path -or -not (Test-Path -LiteralPath $path)) { return '' }
    $lines = @(Get-Content -LiteralPath $path -Tail 400 -Encoding utf8)
    for ($i = $lines.Count - 1; $i -ge 0; $i--) {
        try { $entry = $lines[$i] | ConvertFrom-Json } catch { continue }
        if ($entry.type -ne 'assistant') { continue }
        $texts = @($entry.message.content | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text })
        if ($texts.Count) { return ($texts -join "`n") }
    }
    ''
}

function ConvertTo-SpeechText([string]$Text, [int]$MaxChars) {
    $phrases = $Config.phrases
    $t = $Text -replace "`r", ''
    # Code and tables read aloud are noise, so only a note that they were there stays.
    $t = $t -replace '(?ms)^[ \t]*```.*?^[ \t]*```[^\n]*$', "`n$($phrases.code)`n"
    $t = $t -replace '(?m)(^[ \t]*\|.*\|[ \t]*(\n|$))+', "$($phrases.table)`n"
    $t = $t -replace '\[([^\]]+)\]\([^)]+\)', '$1'
    $t = $t -replace 'https?://\S+', $phrases.link
    # `training/current-plan.md:12` -> "current plan"; other inline code only loses the backticks.
    $t = $t -replace '`([^`\n]+)`', {
        $c = $_.Groups[1].Value
        if ($c -match '[\\/]') {
            $c = ($c -split '[\\/]')[-1] -replace ':\d+$', '' -replace '\.\w{1,5}$', '' -replace '[-_]', ' '
        }
        $c
    }
    $t = $t -replace '(?m)^[ \t]{0,3}#{1,6}[ \t]*', ''
    $t = $t -replace '(?m)^[ \t]*(?:[-*+]|\d+[.)])[ \t]+', ''
    $t = $t -replace '(?m)^[ \t]*>[ \t]?', ''
    $t = $t -replace '\*\*|__|~~', ''
    $t = $t -replace '(?<![\w*])\*(?!\s)([^*\n]+?)\*(?!\w)', '$1'
    $t = $t -replace '\s*[→⇒➜]\s*', ', '
    $t = $t -replace '[\p{Cs}\p{So}️‍]', ''

    # Every line becomes a sentence, so the synthesizer pauses where the list items used to be.
    $sentences = foreach ($line in $t -split "`n") {
        $l = ($line -replace '\s+', ' ').Trim()
        if (-not $l) { continue }
        if ($l -notmatch '[.!?:;,…。！？]$') { $l += '.' }
        $l
    }
    $t = $sentences -join ' '

    if ($t.Length -gt $MaxChars) {
        $cut = $t.Substring(0, $MaxChars)
        $end = $cut.LastIndexOfAny([char[]]'.!?。！？')
        if ($end -gt $MaxChars / 2) { $cut = $cut.Substring(0, $end + 1) }
        $t = "$cut $($phrases.rest)"
    }
    $t
}

function Send-Ntfy([string]$Title, [string]$Message) {
    # Plain ASCII in the request body (\uXXXX), so accented letters do not depend on the console encoding.
    $body = [ordered]@{ topic = $Config.topic; title = $Title; message = $Message } |
        ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
    Invoke-RestMethod -Uri $Config.server -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 8 | Out-Null
}

function Get-ProjectName($Payload) {
    $cwd = [string]$Payload.cwd
    if ($cwd) { Split-Path $cwd -Leaf } else { 'Agent' }
}

$SpeechRules = @'
Voice mode: this message came from a phone and the user is away from the computer (for example out running). Your final reply will be read aloud by a speech synthesizer.
Rules for this reply:
- Reply in the language the user writes in.
- Keep it short, ideally up to 5-6 sentences, in spoken language. Put the most important thing first.
- No tables, code blocks, headings, emoji or file paths. If something like that is needed, save it to files and only say what it covers.
- Give important links (for example sources and documents from research) normally, as a markdown link with a short label, like [WHO report 2025](url). The synthesizer reads only the label, so do not leave links out because of reading aloud.
- Write e-mail addresses, phone numbers and similar normally (shop@example.com), not spelled out as words: the user also reads the reply on screen, and the phone reader says them aloud.
- Do not use question dialogs or tools such as AskUserQuestion: nobody will hear them. If you need a decision, ask one specific question at the end of your reply.
- The message was dictated, so it may contain speech recognition errors (for example "cloud" instead of "Claude"). Read it charitably, and ask only when it is genuinely ambiguous.
'@

try {
    $null = New-Item -ItemType Directory -Force $VoiceDataDir
    $Config = Read-VoiceConfig

    if ($Event -eq 'test') {
        Send-Ntfy 'Voice mode' $Config.phrases.test
        Write-Log 'test sent'
        Write-Output 'Test message sent to your phone.'
        exit 0
    }

    $Payload = [Console]::In.ReadToEnd() | ConvertFrom-Json

    switch ($Event) {
        'prompt' {
            $null = New-Item -ItemType Directory -Force $StateDir
            Get-ChildItem $StateDir -Filter '*.remote' |
                Where-Object LastWriteTime -lt (Get-Date).AddDays(-2) | Remove-Item -ErrorAction SilentlyContinue
            $flag = Get-RemoteFlagPath $Payload
            $remote = switch ($Config.mode) {
                'on' { $true }
                'off' { $false }
                default { (Get-IdleSeconds) -ge $Config.remoteIdleSeconds }
            }
            if ($remote) {
                $null = New-Item -ItemType File -Force $flag
                @{ hookSpecificOutput = @{ hookEventName = 'UserPromptSubmit'; additionalContext = $SpeechRules } } |
                    ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
            } else {
                Remove-Item $flag -ErrorAction SilentlyContinue
            }
        }
        'stop' {
            # No topic: the phone app reads replies itself, or nothing reads them at all.
            if (-not $Config.topic) { exit 0 }
            if (-not (Test-ShouldSpeak $Payload)) { exit 0 }
            $text = Get-LastAssistantText $Payload
            if (-not $text.Trim()) { Write-Log 'empty reply, nothing to send'; exit 0 }
            $speech = ConvertTo-SpeechText $text $Config.maxChars
            $project = Get-ProjectName $Payload
            Send-Ntfy $project $speech
            Write-Log "reply sent ($project, $($speech.Length) characters)"
        }
        'notify' {
            if (-not $Config.topic) { exit 0 }
            if (-not (Test-ShouldSpeak $Payload)) { exit 0 }
            $project = Get-ProjectName $Payload
            Send-Ntfy $project $Config.phrases.approval.Replace('{project}', $project)
            Write-Log "approval request sent ($project)"
        }
    }
} catch {
    # A hook must never stop the agent, so an error only goes to the log.
    Write-Log "error: $($_.Exception.Message)"
    if ($Event -eq 'test') { Write-Output "Sending failed: $($_.Exception.Message)" }
}
exit 0
