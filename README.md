# lazygit-claude

Generate commit messages and pull requests with [Claude Code](https://docs.claude.com/en/docs/claude-code) right from [lazygit](https://github.com/jesseduffield/lazygit). You review and edit everything in your editor before anything gets committed or pushed.

| Panel | Key | Script | What it does |
|---|---|---|---|
| Files | `Ctrl+A` | `lg-ai-commit` | Writes a [Conventional Commits](https://www.conventionalcommits.org) message from your **staged** diff and opens it in your editor |
| Local branches | `Ctrl+A` | `lg-ai-pr` | Writes a PR title and body from the branch's commits and diff, opens it in your editor, then pushes and runs `gh pr create` |

## Requirements

- [lazygit](https://github.com/jesseduffield/lazygit)
- [Claude Code CLI](https://docs.claude.com/en/docs/claude-code) (`claude`), logged in
- [GitHub CLI](https://cli.github.com) (`gh`), logged in (only needed for `lg-ai-pr`)
- `bash` and `git`

## Installation

```bash
git clone https://github.com/CristianTCIT/lazygit-claude.git
cd lazygit-claude
./install.sh
```

`install.sh` symlinks the scripts from `bin/` into `~/.local/bin`, so a `git pull` is enough to update them later. If you want a different directory, set `INSTALL_DIR`:

```bash
INSTALL_DIR=/usr/local/bin ./install.sh
```

Then copy the `customCommands` entries from [`config.example.yml`](config.example.yml) into your lazygit config:

- macOS: `~/Library/Application Support/lazygit/config.yml`
- Linux: `~/.config/lazygit/config.yml`

If you already have a `customCommands` section, add the two entries to it. Don't create a second section.

## Usage

### Commit message

1. Stage your changes in lazygit.
2. In the **Files** panel, press `Ctrl+A`.
3. Claude writes the message and your editor opens with it.
4. Edit it if needed, then save and close to commit. If you close the editor with an empty message, the commit is aborted.

### Pull request

1. Check out your feature branch.
2. In the **Local branches** panel, press `Ctrl+A`.
3. Claude writes the title (first line) and the body (Summary / Changes / Testing). Your editor opens with it.
4. Save and close, then confirm with `y`.
5. The script pushes the branch (setting the upstream if needed) and creates the PR.

The base branch defaults to the repo's default branch. You can override it by running the script manually:

```bash
lg-ai-pr develop
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `LG_AI_MODEL` | `haiku` | Claude model to use (`haiku`, `sonnet`, `opus`) |
| `LG_AI_MAX_DIFF` | `60000` | Max characters of diff sent to Claude |

Example in your `~/.zshrc` or `~/.bashrc`:

```bash
export LG_AI_MODEL=sonnet
```

## How it works

Both scripts collect context with `git` and pipe a prompt into Claude Code in non-interactive mode:

```bash
claude -p \
  --model "$MODEL" \
  --tools "" \
  --strict-mcp-config \
  --setting-sources "" \
  --no-session-persistence
```

- `--tools ""`: Claude only writes text. It can't read files or run commands.
- `--strict-mcp-config` and `--setting-sources ""`: skip your MCP servers, hooks and settings, which keeps it fast and predictable.
- `--no-session-persistence`: these one-off runs don't fill up your session history.

**`lg-ai-commit`** sends the staged diff, the diff stat and the last 5 commits (so Claude can match your repo's style). It then runs `git commit -e -F <message>`, so the message always goes through your editor.

**`lg-ai-pr`** fetches the base branch and sends the commit list plus the diff against `origin/<base>`. It opens the result in the editor git uses (`git var GIT_EDITOR`) and splits it into title and body. After you confirm, it pushes and calls `gh pr create`.

Large diffs are truncated to `LG_AI_MAX_DIFF` characters to keep requests fast and cheap.

## Privacy

Your diffs are sent to Anthropic through the Claude Code CLI. Don't use this on repositories you aren't allowed to share with a third-party AI provider.

## License

[MIT](LICENSE)
