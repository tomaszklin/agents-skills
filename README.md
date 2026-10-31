# Agents skills

Skills for coding agents by Tomasz Klin. Each one is a separate plugin, the skills are not related
to each other, and you install only the ones you want. For now they work with Claude Code.

## Install

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

## Plugins

- [voice-mode](plugins/voice-mode/README.md): short, spoken-style replies when you write to Claude
  Code from your phone.

## Adding a plugin

1. Create `plugins/<name>/` with `.claude-plugin/plugin.json`, a `README.md` and the plugin files.
2. Add an entry to `.claude-plugin/marketplace.json`.
3. Run `claude plugin validate .` and `claude plugin validate plugins/<name>`.
4. Raise `version` in the plugin's `plugin.json` on every release. Users get an update only when
   the version changes.

## License

[MIT](LICENSE)
