---
name: mode
description: "Voice mode: short, spoken-style replies without tables or code when you write from your phone (on | off | always | status | push <topic> | push off | test)"
argument-hint: "on | off | always | status | push <topic> | push off | test"
disable-model-invocation: true
allowed-tools: PowerShell, Bash(pwsh:*)
---

Run exactly this command (Bash tool, or the PowerShell tool if you have no Bash tool), passing the
user's argument as is (empty when none was given):

`pwsh -NoProfile -File "${CLAUDE_PLUGIN_ROOT}/scripts/voice-mode.ps1" "${CLAUDE_PLUGIN_DATA}" $ARGUMENTS`

Then reply with one sentence that repeats what the script printed, in the language of the
conversation. Do nothing else: no other tools, no explanations, no follow-up questions.
