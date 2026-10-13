# lazygit-ai

Generate commit messages and pull requests with an AI CLI right from [lazygit](https://github.com/jesseduffield/lazygit). It defaults to [Claude Code](https://docs.claude.com/en/docs/claude-code), but works with Gemini CLI, Codex, opencode, or **any command that reads a prompt from stdin**.

You review and edit everything in your editor before anything gets committed or pushed.

| Panel | Key | Script | What it does |
|---|---|---|---|
| Files | `Ctrl+A` | `lg-ai-commit` | Writes a [Conventional Commits](https://www.conventionalcommits.org) message from your **staged** diff and opens it in your editor |
| Local branches | `Ctrl+A` | `lg-ai-pr` | Writes a PR title and body from the branch's commits and diff, opens it in your editor, then pushes and runs `gh pr create` |

## Requirements

- [lazygit](https://github.com/jesseduffield/lazygit)
- `bash` and `git`
- [GitHub CLI](https://cli.github.com) (`gh`), logged in (only needed for `lg-ai-pr`)
- One AI CLI, logged in:

| Provider | `LG_AI_PROVIDER` | CLI |
|---|---|---|
| Claude Code (default) | `claude` | [`claude`](https://docs.claude.com/en/docs/claude-code) |
| Gemini CLI | `gemini` | [`gemini`](https://github.com/google-gemini/gemini-cli) |
| OpenAI Codex | `codex` | [`codex`](https://github.com/openai/codex) |
| opencode | `opencode` | [`opencode`](https://opencode.ai) |
| Anything else | — | Set `LG_AI_CMD` (see [Custom command](#custom-command)) |

## Installation

```bash
git clone https://github.com/CristianTCIT/lazygit-ai.git
cd lazygit-ai
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
3. The AI writes the message and your editor opens with it.
4. Edit it if needed, then save and close to commit. If you close the editor with an empty message, the commit is aborted.

### Pull request

1. Check out your feature branch.
2. In the **Local branches** panel, press `Ctrl+A`.
3. The AI writes the title (first line) and the body (Summary / Changes / Testing). Your editor opens with it.
4. Save and close, then confirm with `y`.
5. The script pushes the branch (setting the upstream if needed) and creates the PR.

The base branch defaults to the repo's default branch. You can override it by running the script manually:

```bash
lg-ai-pr develop
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `LG_AI_PROVIDER` | `claude` | Built-in provider: `claude`, `gemini`, `codex`, `opencode` |
| `LG_AI_MODEL` | provider default (`haiku` for Claude) | Model passed to the provider's `-m` / `--model` flag |
| `LG_AI_CMD` | — | Custom command. Overrides `LG_AI_PROVIDER` |
| `LG_AI_MAX_DIFF` | `60000` | Max characters of diff sent to the AI |

Examples in your `~/.zshrc` or `~/.bashrc`:

```bash
# Claude with a bigger model
export LG_AI_MODEL=sonnet

# Gemini CLI
export LG_AI_PROVIDER=gemini
export LG_AI_MODEL=gemini-2.5-flash

# opencode (model format is provider/model)
export LG_AI_PROVIDER=opencode
export LG_AI_MODEL=anthropic/claude-haiku-4-5
```

### Custom command

`LG_AI_CMD` lets you plug in any tool. The command gets the prompt on **stdin** and has to print the answer on **stdout**:

```bash
# Local model with Ollama
export LG_AI_CMD="ollama run llama3.1"

# Simon Willison's llm
export LG_AI_CMD="llm -m gpt-4o-mini"
```

## How it works

```
bin/lg-ai-commit ─┐
                  ├─► lib/lg-ai-common.sh ─► ai_generate ─► claude | gemini | codex | opencode | $LG_AI_CMD
bin/lg-ai-pr ─────┘
```

Both scripts collect context with `git`, build a prompt and pipe it into `ai_generate`. That function is the **only** place that knows about providers. Adding a new one means adding one `case` branch in [`lib/lg-ai-common.sh`](lib/lg-ai-common.sh).

How each built-in provider is called:

| Provider | Invocation | Notes |
|---|---|---|
| `claude` | `claude -p --tools "" --strict-mcp-config --setting-sources "" --no-session-persistence` | No tools, MCP servers, hooks or settings. Runs aren't saved to your session history. Fast and predictable |
| `gemini` | `gemini -p "<prompt>" --output-format text` | Headless mode |
| `codex` | `codex exec --sandbox read-only --skip-git-repo-check --output-last-message <file> -` | Only the final message is kept |
| `opencode` | `opencode run "<prompt>"` | |

If a model wraps its answer in a code fence anyway, the fence is stripped before you see it.

**`lg-ai-commit`** sends the staged diff, the diff stat and the last 5 commits (so the AI can match your repo's style). It then runs `git commit -e -F <message>`, so the message always goes through your editor.

**`lg-ai-pr`** fetches the base branch and sends the commit list plus the diff against `origin/<base>`. It opens the result in the editor git uses (`git var GIT_EDITOR`) and splits it into title and body. After you confirm, it pushes and calls `gh pr create`.

Large diffs are truncated to `LG_AI_MAX_DIFF` characters to keep requests fast and cheap.

## Privacy

Your diffs are sent to whichever provider you configure. Don't use this on repositories you aren't allowed to share with a third-party AI provider. If that's a concern, use a local model through `LG_AI_CMD` (for example with Ollama).

## License

[MIT](LICENSE)
