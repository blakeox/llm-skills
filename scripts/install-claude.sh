#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="$REPO_DIR/skills/manifest.txt"
CLAUDE_DIR="${HOME}/.claude"

echo "LLM Skills — Claude Code installer"
echo "Bundle version: $(cat "$REPO_DIR/VERSION")"
echo

# --- Step 1: Install skills via symlinks ---

SKILLS_TARGET="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_TARGET"

while IFS= read -r skill || [[ -n "$skill" ]]; do
  [[ -z "$skill" ]] && continue
  SOURCE="$REPO_DIR/skills/$skill"
  TARGET="$SKILLS_TARGET/$skill"

  if [[ ! -d "$SOURCE" ]]; then
    echo "WARNING: Missing source $SOURCE — skipping" >&2
    continue
  fi

  if [[ -L "$TARGET" ]]; then
    rm "$TARGET"
  elif [[ -d "$TARGET" ]]; then
    echo "EXISTS (not symlink): $skill — skipping"
    continue
  fi

  ln -s "$SOURCE" "$TARGET"
  echo "Linked skill: $skill"
done < "$MANIFEST"

echo

# --- Step 2: Install agents ---

AGENTS_SOURCE="$REPO_DIR/claude/agents"
AGENTS_TARGET="$CLAUDE_DIR/agents"
mkdir -p "$AGENTS_TARGET"

for agent_file in "$AGENTS_SOURCE"/*.md; do
  name="$(basename "$agent_file")"
  cp "$agent_file" "$AGENTS_TARGET/$name"
  echo "Installed agent: $name"
done

echo

# --- Step 3: Install rules ---

RULES_DIR="$CLAUDE_DIR/rules"
mkdir -p "$RULES_DIR"

for rule_file in "$REPO_DIR"/claude/rules/*.md; do
  name="$(basename "$rule_file")"
  cp "$rule_file" "$RULES_DIR/$name"
  echo "Installed rule: $name"
done

echo

# --- Step 4: Install hooks ---

HOOKS_SOURCE="$REPO_DIR/claude/hooks"
HOOKS_DIR="$CLAUDE_DIR/hooks"
mkdir -p "$HOOKS_DIR"

if [[ -d "$HOOKS_SOURCE" ]]; then
  for hook_file in "$HOOKS_SOURCE"/*.sh; do
    name="$(basename "$hook_file")"
    cp "$hook_file" "$HOOKS_DIR/$name"
    chmod +x "$HOOKS_DIR/$name"
    echo "Installed hook: $name"
  done
fi

echo

# --- Step 5: Create settings.json if missing ---

SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [[ ! -f "$SETTINGS_FILE" ]]; then
  cp "$REPO_DIR/claude/settings.json.example" "$SETTINGS_FILE"
  echo "Created settings.json from template (agent teams enabled)"
else
  # Check if agent teams env var is set
  if ! grep -q "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" "$SETTINGS_FILE" 2>/dev/null; then
    echo "NOTE: Agent teams not enabled in your settings.json."
    echo "  Add this to your settings.json under \"env\":"
    echo "    \"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\": \"1\""
  else
    echo "settings.json exists (not overwritten)"
  fi
fi

echo

# --- Step 6: Create CLAUDE.md if missing ---

CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
if [[ ! -f "$CLAUDE_MD" ]]; then
  cp "$REPO_DIR/claude/CLAUDE.md.example" "$CLAUDE_MD"
  echo "Created ~/.claude/CLAUDE.md from template"
else
  echo "CLAUDE.md exists (not overwritten)"
fi

echo
echo "Install complete."
echo "  Skills:   symlinked to $SKILLS_TARGET/"
echo "  Agents:   copied to $AGENTS_TARGET/"
echo "  Rules:    copied to $RULES_DIR/"
echo "  Hooks:    copied to $HOOKS_DIR/"
echo "  Settings: $SETTINGS_FILE"
echo "  CLAUDE.md: $CLAUDE_MD"
echo
echo "Start a new Claude Code session to pick up the changes."
