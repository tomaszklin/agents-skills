# Voice mode

Talk to Claude Code from your phone while you are away from your computer. When a prompt comes from
your phone, Claude keeps its reply short and easy to listen to: no tables, no code blocks, no file
paths. It also expects dictation errors and does not open dialogs that nobody can hear.

The plugin only changes how Claude replies. To send prompts from your phone you need a separate
tool that reaches your session, for example [Orca](https://github.com/stablyai/orca) on mobile. To
hear replies, use a phone app that reads them aloud, such as
[Orca Voice](https://github.com/tomaszklin/orca-voice), or the optional [ntfy push](#read-replies-aloud-through-ntfy).

## Install

```
/plugin marketplace add tomaszklin/agents-skills
/plugin install voice-mode@tomaszklin-skills
```

Restart Claude Code after installing.

## Requirements

- [PowerShell 7](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
  (`pwsh`), on every system. The Windows PowerShell 5.1 that comes with Windows is not enough.
- Windows works out of the box and is the only tested system.
- macOS uses the built-in `ioreg` tool. This is not tested yet.
- Linux needs `xprintidle`, which works on X11 only. This is not tested yet. Without it, use
  `/voice-mode:mode always`.

## How it knows you are on your phone

Typing at the keyboard resets the system idle timer, and a prompt sent from a phone does not. If the
computer has been idle for at least 60 seconds when a prompt arrives, the turn counts as remote.

## Commands

- `/voice-mode:mode on`: use the speech rules only when you write from your phone. This is the
  default.
- `/voice-mode:mode off`: never use them.
- `/voice-mode:mode always`: use them all the time, also at your desk.
- `/voice-mode:mode status`: show the current state and where the settings file is.
- `/voice-mode:mode push <topic>`: also send replies to your phone through this ntfy topic.
- `/voice-mode:mode push off`: stop sending replies.
- `/voice-mode:mode test`: send a test message to your phone.

## Languages

The plugin is written in English and works with any language. Claude replies in the language you
write in.

The only fixed texts are the few short phrases used for the ntfy push, such as "Skipping a table."
To translate them, run `/voice-mode:mode status` to find the settings file, and edit `phrases`:

```json
{
  "phrases": {
    "code": "Pomijam fragment kodu.",
    "table": "Pomijam tabelę.",
    "link": "link",
    "rest": "Reszta odpowiedzi jest w terminalu.",
    "approval": "Claude czeka na Twoją zgodę w projekcie {project}.",
    "test": "Test trybu głosowego. Jeśli to słyszysz, wszystko działa."
  }
}
```

## Read replies aloud through ntfy

This part is optional. Skip it if your phone app already reads replies.

1. Install the [ntfy](https://ntfy.sh) app on your phone and subscribe to a long random topic.
2. Install an app that reads notifications aloud.
3. Run `/voice-mode:mode push <topic>`, then `/voice-mode:mode test`.

Replies then go to your phone when you write from it, and also when you started a task at your desk
and the computer has been idle for 10 minutes. You also hear when Claude waits for your approval.

**Privacy:** the text of each reply goes through the ntfy server, and anyone who knows the topic can
read it. Use a long random topic. If your replies are sensitive, run your own ntfy server and put
its address in `server` in the settings file.

## Settings

- `mode`: `auto`, `on` or `off`. Set this one with the commands above.
- `remoteIdleSeconds`: how long the computer must be idle for a prompt to count as remote.
- `awayMinutes`: how long the computer must be idle for replies to go to your phone when the
  prompt was not remote.
- `maxChars`: the longest message sent through ntfy.
- `server`, `topic`: the ntfy server and topic.
- `phrases`: the fixed texts described in [Languages](#languages).

## Troubleshooting

Problems go to `voice.log` next to the settings file. A hook error on every prompt usually means
that `pwsh` is not installed.
