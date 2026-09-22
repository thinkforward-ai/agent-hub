#!/usr/bin/env bash

set -eu

ARCHIVE_URL="${AGENT_HUB_ARCHIVE_URL:-https://github.com/thinkforward-ai/agent-hub/archive/refs/heads/main.tar.gz}"
AGENT_HUB_HOME="${AGENT_HUB_HOME:-$HOME/.agent-hub}"
FACTORY_HOME="${FACTORY_HOME:-$HOME/.factory}"
FACTORY_SKILLS="$FACTORY_HOME/skills"
FACTORY_AGENTS="$FACTORY_HOME/AGENTS.md"
DEVIN_CONFIG_HOME="${DEVIN_CONFIG_HOME:-$HOME/.config/devin}"
DEVIN_SKILLS_HOME="$DEVIN_CONFIG_HOME/skills"
DEVIN_AGENTS="$DEVIN_CONFIG_HOME/AGENTS.md"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_SKILLS="$CLAUDE_HOME/skills"
CLAUDE_INSTRUCTIONS="$CLAUDE_HOME/CLAUDE.md"
BACKUP_EXISTING=false

usage() {
  cat <<'EOF'
Usage: install.sh [--backup-existing]

Install Agent Hub from a clean public snapshot and link Factory, Devin, and Claude Code skills and global instructions to it.

Options:
  --backup-existing  Move a conflicting skills or AGENTS.md path to a timestamped backup.
  -h, --help         Show this help.

Environment:
  AGENT_HUB_HOME         Central installation directory (default: ~/.agent-hub)
  FACTORY_HOME           Factory configuration directory (default: ~/.factory)
  DEVIN_CONFIG_HOME      Devin configuration directory (default: ~/.config/devin)
  CLAUDE_CONFIG_DIR      Claude Code configuration directory (default: ~/.claude)
  AGENT_HUB_ARCHIVE_URL  Snapshot URL (default: public main branch archive)
EOF
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --backup-existing)
      BACKUP_EXISTING=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
  shift
done

for command in curl tar find; do
  command -v "$command" >/dev/null 2>&1 || fail "required command not found: $command"
done

if command -v sha256sum >/dev/null 2>&1; then
  hash_file() {
    sha256sum "$1" | cut -c1-16
  }
elif command -v shasum >/dev/null 2>&1; then
  hash_file() {
    shasum -a 256 "$1" | cut -c1-16
  }
else
  fail "required command not found: sha256sum or shasum"
fi

case "$AGENT_HUB_HOME" in
  /*) ;;
  *) fail "AGENT_HUB_HOME must be an absolute path" ;;
esac

case "$FACTORY_HOME" in
  /*) ;;
  *) fail "FACTORY_HOME must be an absolute path" ;;
esac

case "$DEVIN_CONFIG_HOME" in
  /*) ;;
  *) fail "DEVIN_CONFIG_HOME must be an absolute path" ;;
esac

case "$CLAUDE_HOME" in
  /*) ;;
  *) fail "CLAUDE_CONFIG_DIR must be an absolute path" ;;
esac

expected_skills_target="$AGENT_HUB_HOME/current/skills"
expected_agents_target="$AGENT_HUB_HOME/current/AGENTS.md"

check_link_conflict() {
  local target_path="$1"
  local expected_target="$2"
  local resource_name="$3"

  if [ -L "$target_path" ]; then
    current_target="$(readlink "$target_path")"
    if [ "$current_target" != "$expected_target" ] && [ "$BACKUP_EXISTING" != true ]; then
      fail "$resource_name points to $current_target; rerun with --backup-existing to preserve and replace it"
    fi
  elif [ -e "$target_path" ] && [ "$BACKUP_EXISTING" != true ]; then
    fail "$resource_name already exists; rerun with --backup-existing to preserve and replace it"
  fi
}

check_link_conflict "$FACTORY_SKILLS" "$expected_skills_target" "Factory skills"
check_link_conflict "$DEVIN_SKILLS_HOME" "$expected_skills_target" "Devin skills"
check_link_conflict "$FACTORY_AGENTS" "$expected_agents_target" "Factory AGENTS.md"
check_link_conflict "$DEVIN_AGENTS" "$expected_agents_target" "Devin AGENTS.md"
check_link_conflict "$CLAUDE_SKILLS" "$expected_skills_target" "Claude Code skills"
check_link_conflict "$CLAUDE_INSTRUCTIONS" "$expected_agents_target" "Claude Code CLAUDE.md"

if [ -e "$AGENT_HUB_HOME" ] && [ ! -d "$AGENT_HUB_HOME" ]; then
  fail "$AGENT_HUB_HOME exists and is not a directory"
fi

if [ -d "$AGENT_HUB_HOME" ] && [ ! -f "$AGENT_HUB_HOME/.managed-by-agent-hub" ]; then
  for entry in "$AGENT_HUB_HOME"/* "$AGENT_HUB_HOME"/.[!.]* "$AGENT_HUB_HOME"/..?*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    [ "$(basename "$entry")" = ".env" ] || fail "$AGENT_HUB_HOME contains unmanaged content: $entry"
  done
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

archive="$tmp_dir/agent-hub.tar.gz"
extracted="$tmp_dir/snapshot"
mkdir -p "$extracted"

printf 'Downloading Agent Hub snapshot...\n'
curl --fail --location --silent --show-error "$ARCHIVE_URL" --output "$archive"
tar -xzf "$archive" --strip-components=1 --directory "$extracted"

[ -d "$extracted/skills" ] || fail "snapshot does not contain a skills directory"
[ -n "$(find "$extracted/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print -quit)" ] ||
  fail "snapshot does not contain any skills"
[ -f "$extracted/AGENTS.md" ] || fail "snapshot does not contain AGENTS.md"

release_id="$(hash_file "$archive")"
release_dir="$AGENT_HUB_HOME/releases/$release_id"
old_release=""

if [ -L "$AGENT_HUB_HOME/current" ]; then
  old_release="$(readlink "$AGENT_HUB_HOME/current")"
elif [ -e "$AGENT_HUB_HOME/current" ]; then
  fail "$AGENT_HUB_HOME/current exists and is not a managed symlink"
fi

mkdir -p "$AGENT_HUB_HOME/releases"
printf 'managed by https://github.com/thinkforward-ai/agent-hub\n' >"$AGENT_HUB_HOME/.managed-by-agent-hub"

if [ ! -d "$release_dir" ]; then
  mv "$extracted" "$release_dir"
fi

ln -sfn "releases/$release_id" "$AGENT_HUB_HOME/current"

create_symlink() {
  local target_path="$1"
  local expected_target="$2"
  local parent_dir="$3"
  local resource_name="$4"

  mkdir -p "$parent_dir"
  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    current_target=""
    if [ -L "$target_path" ]; then
      current_target="$(readlink "$target_path")"
    fi

    if [ "$current_target" != "$expected_target" ]; then
      timestamp="$(date -u +%Y%m%d-%H%M%S)"
      backup="$target_path.backup.$timestamp"
      while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="$backup.$RANDOM"
      done
      mv "$target_path" "$backup"
      printf 'Preserved existing %s at %s\n' "$resource_name" "$backup"
    fi
  fi

  if [ ! -L "$target_path" ]; then
    ln -s "$expected_target" "$target_path"
  fi
}

create_symlink "$FACTORY_SKILLS" "$expected_skills_target" "$FACTORY_HOME" "Factory skills"
create_symlink "$DEVIN_SKILLS_HOME" "$expected_skills_target" "$DEVIN_CONFIG_HOME" "Devin skills"
create_symlink "$FACTORY_AGENTS" "$expected_agents_target" "$FACTORY_HOME" "Factory AGENTS.md"
create_symlink "$DEVIN_AGENTS" "$expected_agents_target" "$DEVIN_CONFIG_HOME" "Devin AGENTS.md"
create_symlink "$CLAUDE_SKILLS" "$expected_skills_target" "$CLAUDE_HOME" "Claude Code skills"
create_symlink "$CLAUDE_INSTRUCTIONS" "$expected_agents_target" "$CLAUDE_HOME" "Claude Code CLAUDE.md"

old_release_id="${old_release#releases/}"
if [ "$old_release" = "releases/$old_release_id" ] &&
  [ "${#old_release_id}" -eq 16 ]; then
  case "$old_release_id" in
    *[!0-9a-f]*) ;;
    "$release_id") ;;
    *) rm -rf "$AGENT_HUB_HOME/releases/$old_release_id" ;;
  esac
fi

printf 'Agent Hub installed at %s\n' "$AGENT_HUB_HOME/current"
printf 'Factory skills linked at %s\n' "$FACTORY_SKILLS"
printf 'Devin skills linked at %s\n' "$DEVIN_SKILLS_HOME"
printf 'Factory AGENTS.md linked at %s\n' "$FACTORY_AGENTS"
printf 'Devin AGENTS.md linked at %s\n' "$DEVIN_AGENTS"
printf 'Claude Code skills linked at %s\n' "$CLAUDE_SKILLS"
printf 'Claude Code CLAUDE.md linked at %s\n' "$CLAUDE_INSTRUCTIONS"
