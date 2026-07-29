#!/usr/bin/env bash
# install.sh — install salesagent-review-bot as Claude Code constructs.
#
# Zero-footprint model (Konstantin's): the agents, the review-queue skill, and the
# rules (charter + detectors + corpus) install into ~/.claude/; the drivers install
# onto your PATH. Nothing is written into any repo you review.
#
#   ./install.sh            # symlink (Unix/macOS) or copy (Windows/Git-Bash) into ~
#   ./install.sh --copy     # force copy instead of symlink
#   ./install.sh --uninstall
#
# On Windows, symlinks need Developer Mode or admin; this script auto-falls back to
# copying there (re-run after edits, or enable symlinks). See docs/merge-design.md.
set -euo pipefail

BOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
BIN_DIR="${BOT_BIN_DIR:-$HOME/.local/bin}"

MODE="link"
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) MODE="copy" ;; esac   # symlinks are fragile on Windows
for a in "$@"; do
  case "$a" in
    --copy) MODE="copy" ;;
    --uninstall) MODE="uninstall" ;;
    *) echo "unknown arg: $a" >&2; exit 2 ;;
  esac
done

# src -> dst pairs (dst under $CLAUDE_DIR unless it's a bin script)
place() {  # place <src-abs> <dst-abs>
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  if [ "$MODE" = "link" ]; then ln -sfn "$src" "$dst"; else cp -R "$src" "$dst"; fi
}

do_install() {
  echo "Installing salesagent-review-bot ($MODE) from $BOT_DIR"
  # agents: one link/copy per agent file (skip the README)
  mkdir -p "$CLAUDE_DIR/agents"
  for f in "$BOT_DIR"/claude/agents/*.md; do
    [ "$(basename "$f")" = "README.md" ] && continue
    place "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
  done
  # skill (whole dir so references/ resolve)
  place "$BOT_DIR/claude/skills/review-queue" "$CLAUDE_DIR/skills/review-queue"
  # rules: charter + detectors + corpus
  place "$BOT_DIR/claude/rules/charter"    "$CLAUDE_DIR/rules/review-bot/charter"
  place "$BOT_DIR/claude/rules/detectors"  "$CLAUDE_DIR/rules/review-bot/detectors"
  place "$BOT_DIR/claude/rules/corpus"     "$CLAUDE_DIR/rules/review-bot/corpus"
  # drivers onto PATH
  mkdir -p "$BIN_DIR"
  for f in "$BOT_DIR"/bin/*; do
    [ "$(basename "$f")" = "README.md" ] && continue
    place "$f" "$BIN_DIR/$(basename "$f")"
    chmod +x "$BIN_DIR/$(basename "$f")" 2>/dev/null || true
  done
  echo "  agents  -> $CLAUDE_DIR/agents/"
  echo "  skill   -> $CLAUDE_DIR/skills/review-queue/"
  echo "  rules   -> $CLAUDE_DIR/rules/review-bot/"
  echo "  drivers -> $BIN_DIR/"
  case ":$PATH:" in *":$BIN_DIR:"*) ;; *) echo "  NOTE: add $BIN_DIR to your PATH." ;; esac
  echo "Done. In Claude Code, run /review-queue from a salesagent checkout."
}

do_uninstall() {
  echo "Uninstalling salesagent-review-bot from $CLAUDE_DIR and $BIN_DIR"
  for f in "$BOT_DIR"/claude/agents/*.md; do rm -f "$CLAUDE_DIR/agents/$(basename "$f")"; done
  rm -rf "$CLAUDE_DIR/skills/review-queue" "$CLAUDE_DIR/rules/review-bot"
  for f in "$BOT_DIR"/bin/*; do [ "$(basename "$f")" = "README.md" ] && continue; rm -f "$BIN_DIR/$(basename "$f")"; done
  echo "Done."
}

if [ "$MODE" = "uninstall" ]; then do_uninstall; else do_install; fi
