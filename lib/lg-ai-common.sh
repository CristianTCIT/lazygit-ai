#!/usr/bin/env bash
# Shared helpers for lg-ai-* scripts.
# All provider-specific logic lives here: scripts only call `ai_generate`.

LG_AI_PROVIDER="${LG_AI_PROVIDER:-claude}"
LG_AI_MODEL="${LG_AI_MODEL:-}"
LG_AI_CMD="${LG_AI_CMD:-}"
MAX_DIFF_CHARS="${LG_AI_MAX_DIFF:-60000}"

pause() { read -r -p "Press enter to continue..." _; }

# Human readable name of the backend in use, for progress messages.
ai_label() {
  if [[ -n "$LG_AI_CMD" ]]; then
    echo "$LG_AI_CMD"
  else
    echo "${LG_AI_PROVIDER}${LG_AI_MODEL:+ ($LG_AI_MODEL)}"
  fi
}

# Read the prompt from stdin and print the model's answer to stdout.
ai_generate() {
  local prompt
  prompt="$(cat)"

  if [[ -n "$LG_AI_CMD" ]]; then
    # Custom command: receives the prompt on stdin, prints the answer on stdout.
    printf '%s' "$prompt" | bash -c "$LG_AI_CMD"
    return
  fi

  case "$LG_AI_PROVIDER" in
    claude)
      printf '%s' "$prompt" | claude -p \
        --model "${LG_AI_MODEL:-haiku}" \
        --tools "" \
        --strict-mcp-config \
        --setting-sources "" \
        --no-session-persistence
      ;;
    gemini)
      gemini ${LG_AI_MODEL:+-m "$LG_AI_MODEL"} \
        --output-format text \
        -p "$prompt"
      ;;
    codex)
      local out
      out="$(mktemp -t lg-ai-codex)"
      printf '%s' "$prompt" | codex exec \
        ${LG_AI_MODEL:+-m "$LG_AI_MODEL"} \
        --sandbox read-only \
        --skip-git-repo-check \
        --output-last-message "$out" \
        - >/dev/null
      cat "$out"
      rm -f "$out"
      ;;
    opencode)
      opencode run ${LG_AI_MODEL:+-m "$LG_AI_MODEL"} "$prompt"
      ;;
    *)
      echo "Unknown LG_AI_PROVIDER '$LG_AI_PROVIDER'. Use claude, gemini, codex, opencode or set LG_AI_CMD." >&2
      return 1
      ;;
  esac
}

# Drop wrapping code fences that some models add despite the instructions.
strip_fences() {
  sed -e '1{/^```/d;}' -e '${/^```$/d;}'
}
