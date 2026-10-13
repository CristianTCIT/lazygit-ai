#!/usr/bin/env bash
# Symlink the scripts into a directory on your PATH (default: ~/.local/bin).
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$INSTALL_DIR"

for script in "$REPO_DIR"/bin/*; do
  name="$(basename "$script")"
  chmod +x "$script"
  ln -sf "$script" "$INSTALL_DIR/$name"
  echo "Linked $name -> $INSTALL_DIR/$name"
done

deps=(git gh lazygit)
[[ -z "${LG_AI_CMD:-}" ]] && deps+=("${LG_AI_PROVIDER:-claude}")

for dep in "${deps[@]}"; do
  command -v "$dep" >/dev/null 2>&1 || echo "Warning: '$dep' not found in PATH."
done

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo "Warning: $INSTALL_DIR is not in your PATH." ;;
esac

echo "Done. Now add the entries from config.example.yml to your lazygit config."
