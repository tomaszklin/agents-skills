---
name: mode
description: "Voice mode: short, spoken-style replies without tables or code when you write from your phone (on | off | always | status | push <topic> | push off | test)"
argument-hint: "on | off | always | status | push <topic> | push off | test"
disable-model-invocation: true
allowed-tools: PowerShell, Bash(pwsh:*)
---

The plugin folder is two levels above the folder of this SKILL.md. Run exactly this command with
your shell tool, putting in the option the user gave as is (nothing when they gave none):

`pwsh -NoProfile -File "<plugin folder>/scripts/voice-mode.ps1" <option>`

Then reply with one sentence that repeats what the script printed, in the language of the
conversation. Do nothing else: no other tools, no explanations, no follow-up questions.
