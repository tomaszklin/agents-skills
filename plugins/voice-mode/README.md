# Voice mode

Talk to your coding agent from your phone while you are away from your computer. When a prompt comes
from your phone, the agent keeps its reply short and easy to listen to: no tables, no code blocks, no
file paths. It also expects dictation errors and does not open dialogs that nobody can hear.

Works in Claude Code and Codex.

The plugin only changes how the agent replies. To send prompts from your phone you need a separate
tool that reaches your session, for example [Orca](https://github.com/stablyai/orca) on mobile. To
hear replies, use a phone app that reads them aloud, such as
[Orca Voice](https://github.com/tomaszklin/orca-voice), or the optional [ntfy push](#read-replies-aloud-through-ntfy).

## Install

In Claude Code:

```
/plugin marketplace add tomaszklin/agents-skills
/plugin install voice-mode@tomaszklin-skills
```

Restart Claude Code after installing.

In your terminal, for Codex:

```
codex plugin marketplace add tomaszklin/agents-skills
codex plugin add voice-mode@tomaszklin-skills
```

Then start Codex, run `/hooks` and trust the three voice-mode hooks. Codex skips them until you do.

## Requirements

- [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
  (`pwsh`), on every system. The Windows PowerShell 5.1 that comes with Windows is not enough.
- Windows works out of the box and is the only tested system.
- macOS uses the built-in `ioreg` tool. This is not tested yet.
- Linux needs `xprintidle`, which works on X11 only. This is not tested yet. Without it, use the
  `always` option.

## How it knows you are on your phone

Typing at the keyboard resets the system idle timer, and a prompt sent from a phone does not. If the
computer has been idle for at least 60 seconds when a prompt arrives, the turn counts as remote.

## Commands

In Claude Code the command is `/voice-mode:mode`, and in Codex it is `$voice-mode:mode`. Put one of
these options after it:

- `on`: use the speech rules only when you write from your phone. This is the default.
- `off`: never use them.
- `always`: use them all the time, also at your desk.
- `status`: show the current state and where the settings file is.
- `push <topic>`: also send replies to your phone through this ntfy topic.
- `push off`: stop sending replies.
- `test`: send a test message to your phone.

Codex may ask for your approval to change a setting, because the settings file is outside your
project.

## Languages

The plugin is written in English and works with any language. The agent replies in the language you
write in.

The only fixed texts are the few short phrases used for the ntfy push, such as "Skipping a table."
To translate them, edit `phrases` in the settings file:

```json
{
  "phrases": {
    "code": "Pomijam fragment kodu.",
    "table": "Pomijam tabelę.",
    "link": "link",
    "rest": "Reszta odpowiedzi jest w terminalu.",
    "approval": "Agent czeka na Twoją zgodę w projekcie {project}.",
    "test": "Test trybu głosowego. Jeśli to słyszysz, wszystko działa."
  }
}
```

## Read replies aloud through ntfy

This part is optional. Skip it if your phone app already reads replies.

1. Install the [ntfy](https://ntfy.sh) app on your phone and subscribe to a long random topic.
2. Install an app that reads notifications aloud.
3. Use the `push <topic>` option, then the `test` option.

Replies then go to your phone when you write from it, and also when you started a task at your desk
and the computer has been idle for 10 minutes. You also hear when the agent waits for your approval.

**Privacy:** the text of each reply goes through the ntfy server, and anyone who knows the topic can
read it. Use a long random topic. If your replies are sensitive, run your own ntfy server and put
its address in `server` in the settings file.

## Settings

Settings are in `.voice-mode/config.json` in your home folder, and Claude Code and Codex share them.
To keep them somewhere else, set the `VOICE_MODE_DIR` environment variable.

- `mode`: `auto`, `on` or `off`. Set this one with the options above.
- `remoteIdleSeconds`: how long the computer must be idle for a prompt to count as remote.
- `awayMinutes`: how long the computer must be idle for replies to go to your phone when the
  prompt was not remote.
- `maxChars`: the longest message sent through ntfy.
- `server`, `topic`: the ntfy server and topic.
- `phrases`: the fixed texts described in [Languages](#languages).

## Troubleshooting

Problems go to `voice.log` next to the settings file. A hook error on every prompt usually means
that `pwsh` is not installed. In Codex, if nothing happens at all, check `/hooks`.
