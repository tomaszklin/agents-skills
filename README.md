# Agents skills

Skills for coding agents by Tomasz Klin. Each one is a separate plugin, the skills are not related
to each other, and you install only the ones you want.

## Install in Claude Code

Add this marketplace once:

```
/plugin marketplace add tomaszklin/agents-skills
```

Then install any plugin from the list:

```
/plugin install voice-mode@tomaszklin-skills
```

Restart Claude Code after installing. Updates are off by default for third-party marketplaces. To
turn them on, open `/plugin`, go to **Marketplaces** and choose **Enable auto-update**.

## Install in Codex

Run these in your terminal:

```
codex plugin marketplace add tomaszklin/agents-skills
codex plugin add voice-mode@tomaszklin-skills
```

To update, run `codex plugin marketplace upgrade`. If a plugin has hooks, Codex skips them until you
review and trust them with `/hooks`.

## Plugins

- [voice-mode](plugins/voice-mode/README.md): short, spoken-style replies when you write to your
  coding agent from your phone. Works in Claude Code and Codex.

## Adding a plugin

1. Create `plugins/<name>/` with `.claude-plugin/plugin.json`, a `README.md` and the plugin files.
   Add `.codex-plugin/plugin.json` too if the plugin needs its own settings for Codex.
2. Add an entry to `.claude-plugin/marketplace.json`. Codex reads the same file.
3. Run `claude plugin validate .` and `claude plugin validate plugins/<name>`.
4. Raise `version` in every `plugin.json` of the plugin on each release. Users get an update only
   when the version changes.

## License

[MIT](LICENSE)
