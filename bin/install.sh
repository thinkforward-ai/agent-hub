#!/usr/bin/env bash
set -eo pipefail

ARCHIVE_URL="https://github.com/thinkforward-ai/agent-hub/archive/refs/heads/main.tar.gz"
AGENT_HUB_HOME="${AGENT_HUB_HOME:-$HOME/.agent-hub}"
FACTORY_HOME="${FACTORY_HOME:-$HOME/.factory}"
DEVIN_CONFIG_HOME="${DEVIN_CONFIG_HOME:-$HOME/.config/devin}"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MARKER="$AGENT_HUB_HOME/.layout-v2"

usage() {
  printf '%s\n' 'Usage: install.sh [--backup-existing]' \
    'Set up Agent Hub once, or migrate a legacy installation to the shared skill layout.' \
    'Conflicting skill paths are backed up automatically. --backup-existing is accepted for compatibility.'
}

fail() { printf 'Error: %s\n' "$*" >&2; exit 1; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --backup-existing) ;;
    -h | --help) usage; exit 0 ;;
    *) fail "unknown argument: $1" ;;
  esac
  shift
done

for path in "$AGENT_HUB_HOME" "$FACTORY_HOME" "$DEVIN_CONFIG_HOME" "$CLAUDE_HOME"; do
  case "$path" in /*) ;; *) fail "configuration paths must be absolute: $path" ;; esac
done
for command in curl tar find cp mktemp gzip; do
  command -v "$command" >/dev/null 2>&1 || fail "required command not found: $command"
done
if command -v sha256sum >/dev/null 2>&1; then
  hash_file() { sha256sum "$1" | cut -c1-16; }
elif command -v shasum >/dev/null 2>&1; then
  hash_file() { shasum -a 256 "$1" | cut -c1-16; }
else
  fail "required command not found: sha256sum or shasum"
fi

if [ -f "$MARKER" ]; then
  [ -d "$AGENT_HUB_HOME/skills" ] && [ -L "$AGENT_HUB_HOME/current" ] ||
    fail "managed layout is incomplete; no changes made"
  printf 'Agent Hub is already set up at %s; use manage-skills for changes.\n' "$AGENT_HUB_HOME"
  exit 0
fi
[ ! -e "$AGENT_HUB_HOME" ] || [ -d "$AGENT_HUB_HOME" ] ||
  fail "$AGENT_HUB_HOME is not a directory"
if [ -d "$AGENT_HUB_HOME" ] && [ ! -f "$AGENT_HUB_HOME/.managed-by-agent-hub" ]; then
  for entry in "$AGENT_HUB_HOME"/* "$AGENT_HUB_HOME"/.[!.]* "$AGENT_HUB_HOME"/..?*; do
    [ -e "$entry" ] || [ -L "$entry" ] || continue
    [ "$(basename "$entry")" = ".env" ] ||
      fail "$AGENT_HUB_HOME contains unmanaged content: $entry"
  done
fi

current="$AGENT_HUB_HOME/current"
old_release=""
if [ -L "$current" ]; then
  old_target="$(readlink "$current")"
  case "$old_target" in
    releases/[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f])
      old_release="$AGENT_HUB_HOME/$old_target"
      [ -d "$old_release" ] && [ ! -L "$old_release" ] ||
        fail "legacy release is missing or unsafe"
      ;;
    *) fail "current points to an unknown release; no changes made" ;;
  esac
elif [ -e "$current" ]; then
  fail "current is not a managed link; no changes made"
fi

skill_paths=("$FACTORY_HOME/skills" "$DEVIN_CONFIG_HOME/skills" "$CLAUDE_HOME/skills")
instruction_paths=("$FACTORY_HOME/AGENTS.md" "$DEVIN_CONFIG_HOME/AGENTS.md" "$CLAUDE_HOME/CLAUDE.md")
for path in "${instruction_paths[@]}"; do
  if [ -e "$path" ] || [ -L "$path" ]; then
    [ -L "$path" ] && [ "$(readlink "$path")" = "$AGENT_HUB_HOME/current/AGENTS.md" ] ||
      fail "unmanaged instructions at $path; no changes made"
  fi
done

tmp="$(mktemp -d)"
held=()
original=()
created=()
release=""
release_created=false
shared_created=false
committed=false
rollback() {
  if [ "$committed" != true ]; then
    for path in "${created[@]}"; do
      [ ! -e "$path" ] && [ ! -L "$path" ] || rm "$path"
    done
    if [ "$shared_created" = true ]; then rm -rf "$AGENT_HUB_HOME/skills"; fi
    for ((i=${#held[@]}-1; i>=0; i--)); do
      [ ! -e "${held[i]}" ] && [ ! -L "${held[i]}" ] ||
        mv "${held[i]}" "${original[i]}"
    done
    if [ "$release_created" = true ]; then rm -rf "$release"; fi
  fi
  rm -rf "$tmp"
}
trap rollback EXIT

archive="$tmp/agent-hub.tar.gz"
mkdir -p "$tmp/snapshot" "$tmp/held" "$tmp/backup"
curl --fail --location --silent --show-error "$ARCHIVE_URL" --output "$archive"
tar -tzf "$archive" | while IFS= read -r member; do
  case "$member" in /*|../*|*/../*|*/..) fail "unsafe archive path" ;; esac
done
tar -tvzf "$archive" >"$tmp/archive-listing"
if grep -q '^[lh]' "$tmp/archive-listing"; then
  fail "snapshot contains links"
fi
tar -xzf "$archive" --strip-components=1 --directory "$tmp/snapshot"
snapshot="$tmp/snapshot"
[ -f "$snapshot/AGENTS.md" ] && [ -f "$snapshot/sources.json" ] &&
  [ -f "$snapshot/skills/manage-skills/SKILL.md" ] ||
  fail "snapshot lacks Agent Hub instructions, sources, or manager skill"
[ -z "$(find "$snapshot/skills" -type l -print -quit)" ] ||
  fail "core skills contain links"
for skill in "$snapshot/skills"/*; do
  [ -d "$skill" ] && [ -f "$skill/SKILL.md" ] ||
    fail "invalid core skill: $skill"
done
release="$AGENT_HUB_HOME/releases/v2-$(hash_file "$archive")"
[ ! -e "$release" ] && [ ! -L "$release" ] ||
  fail "release already exists without a completed installation"
mkdir -p "$AGENT_HUB_HOME"
if [ ! -e "$AGENT_HUB_HOME/.managed-by-agent-hub" ]; then
  printf 'managed by https://github.com/thinkforward-ai/agent-hub\n' >"$AGENT_HUB_HOME/.managed-by-agent-hub"
fi

needs_backup=false
[ -z "$old_release" ] || needs_backup=true
for path in "${skill_paths[@]}" "$AGENT_HUB_HOME/skills"; do
  if [ -e "$path" ] || [ -L "$path" ]; then needs_backup=true; fi
done
if [ "$needs_backup" = true ]; then
  mkdir -p "$tmp/backup/paths"
  if [ -n "$old_release" ]; then
    cp -a "$old_release" "$tmp/backup/legacy-release"
    cp -a "$current" "$tmp/backup/current"
  fi
  for ((i=0; i<${#skill_paths[@]}; i++)); do
    path="${skill_paths[i]}"
    if [ -e "$path" ] || [ -L "$path" ]; then
      cp -a "$path" "$tmp/backup/paths/$i"
      printf '%s\n' "$path" >"$tmp/backup/paths/$i.path"
    fi
  done
  if [ -e "$AGENT_HUB_HOME/skills" ] || [ -L "$AGENT_HUB_HOME/skills" ]; then
    cp -a "$AGENT_HUB_HOME/skills" "$tmp/backup/shared-skills"
  fi
  mkdir -p "$AGENT_HUB_HOME/backups"
  backup="$AGENT_HUB_HOME/backups/version-$(date -u +%Y%m%d-%H%M%S)-$(basename "$tmp").tar.gz"
  [ ! -e "$backup" ] || fail "backup path already exists: $backup"
  tar -czf "$backup" -C "$tmp/backup" .
  gzip -t "$backup"
  tar -tzf "$backup" >/dev/null
  printf 'Verified old skills backup: %s\n' "$backup"
fi

mkdir -p "$AGENT_HUB_HOME/releases"
mv "$snapshot/skills" "$tmp/core-skills"
ln -s "$AGENT_HUB_HOME/skills" "$snapshot/skills"
mv "$snapshot" "$release"
release_created=true

hold_path() {
  local path="$1" index="${#held[@]}"
  if [ -e "$path" ] || [ -L "$path" ]; then
    mv "$path" "$tmp/held/$index"
    original+=("$path")
    held+=("$tmp/held/$index")
  fi
}
hold_path "$AGENT_HUB_HOME/skills"
mv "$tmp/core-skills" "$AGENT_HUB_HOME/skills"
shared_created=true

for path in "${skill_paths[@]}"; do
  mkdir -p "$(dirname "$path")"
  hold_path "$path"
  ln -s "$AGENT_HUB_HOME/skills" "$path"
  created+=("$path")
done
hold_path "$current"
ln -s "releases/$(basename "$release")" "$current"
created+=("$current")
for path in "${instruction_paths[@]}"; do
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then
    mkdir -p "$(dirname "$path")"
    ln -s "$AGENT_HUB_HOME/current/AGENTS.md" "$path"
    created+=("$path")
  fi
done
if [ ! -e "$AGENT_HUB_HOME/sources.json" ] && [ ! -L "$AGENT_HUB_HOME/sources.json" ]; then
  cp "$release/sources.json" "$AGENT_HUB_HOME/sources.json"
  created+=("$AGENT_HUB_HOME/sources.json")
fi
for path in "${skill_paths[@]}"; do
  [ -f "$path/manage-skills/SKILL.md" ] || fail "manager skill not visible at $path"
done
[ -f "$current/AGENTS.md" ] || fail "instructions not visible"
printf 'managed shared skills layout\n' >"$tmp/layout-marker"
mv "$tmp/layout-marker" "$MARKER"
committed=true

# Prune only archives recorded by this installer, after verification succeeds.
if [ "$needs_backup" = true ]; then
  printf '%s\n' "$(basename "$backup")" >>"$AGENT_HUB_HOME/backups/managed.list"
fi
if [ -f "$AGENT_HUB_HOME/backups/managed.list" ]; then
  count=0
  while IFS= read -r name; do
    case "$name" in version-*.tar.gz) ;; *) continue ;; esac
    [ -f "$AGENT_HUB_HOME/backups/$name" ] || continue
    count=$((count+1))
  done <"$AGENT_HUB_HOME/backups/managed.list"
  if [ "$count" -gt 2 ]; then
    oldest="$(head -n 1 "$AGENT_HUB_HOME/backups/managed.list")"
    case "$oldest" in version-*.tar.gz)
      rm -f "$AGENT_HUB_HOME/backups/$oldest"
      sed '1d' "$AGENT_HUB_HOME/backups/managed.list" >"$tmp/backups.list"
      mv "$tmp/backups.list" "$AGENT_HUB_HOME/backups/managed.list"
      ;;
    esac
  fi
fi
if [ -n "$old_release" ]; then rm -rf "$old_release"; fi
printf 'Agent Hub skills installed at %s\n' "$AGENT_HUB_HOME/skills"
printf 'Sources available at %s\n' "$AGENT_HUB_HOME/sources.json"
if [ -n "$old_release" ]; then
  printf 'Legacy skills are no longer active. Recover them from the backup above if needed.\n'
fi
