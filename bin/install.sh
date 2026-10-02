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

retire_ownership_marker() {
  local path="$AGENT_HUB_HOME/.managed-by-agent-hub"
  if [ -f "$path" ] && [ ! -L "$path" ] &&
    cmp -s "$path" <(printf 'managed by https://github.com/thinkforward-ai/agent-hub\n'); then
    rm "$path"
  fi
}

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
for command in curl tar find cp cmp mktemp gzip awk chmod; do
  command -v "$command" >/dev/null 2>&1 || fail "required command not found: $command"
done

if [ -f "$MARKER" ]; then
  [ -d "$AGENT_HUB_HOME/skills" ] ||
    fail "managed layout is incomplete; no changes made"
  current="$AGENT_HUB_HOME/current"
  if [ -f "$AGENT_HUB_HOME/AGENTS.md" ] && [ ! -e "$current" ] && [ ! -L "$current" ]; then
    retire_ownership_marker
    printf 'Agent Hub is already set up at %s; use the management skill for changes.\n' "$AGENT_HUB_HOME"
    exit 0
  fi
  [ ! -e "$AGENT_HUB_HOME/AGENTS.md" ] && [ ! -L "$AGENT_HUB_HOME/AGENTS.md" ] &&
    [ -L "$current" ] || fail "managed instructions are incomplete; no changes made"
  old_target="$(readlink "$current")"
  case "$old_target" in releases/v2-*) ;; *) fail "unknown managed release; no changes made" ;; esac
  old_id="${old_target#releases/v2-}"
  [ "${#old_id}" -eq 16 ] && [[ "$old_id" != *[!0-9a-f]* ]] ||
    fail "unknown managed release; no changes made"
  [ -d "$AGENT_HUB_HOME/releases" ] && [ ! -L "$AGENT_HUB_HOME/releases" ] ||
    fail "managed releases directory is unsafe; no changes made"
  old_release="$AGENT_HUB_HOME/$old_target"
  [ -d "$old_release" ] && [ ! -L "$old_release" ] &&
    [ -f "$old_release/AGENTS.md" ] &&
    [ -L "$old_release/skills" ] &&
    [ "$(readlink "$old_release/skills")" = "$AGENT_HUB_HOME/skills" ] ||
    fail "managed release is incomplete; no changes made"
  instruction_paths=("$FACTORY_HOME/AGENTS.md" "$DEVIN_CONFIG_HOME/AGENTS.md" "$CLAUDE_HOME/CLAUDE.md")
  for path in "${instruction_paths[@]}"; do
    [ -L "$path" ] && [ "$(readlink "$path")" = "$current/AGENTS.md" ] ||
      fail "unmanaged instructions at $path; no changes made"
  done
  tmp="$(mktemp -d)"
  migrated=false
  replaced=0
  old_current_held=false
  old_release_held=false
  rollback_managed() {
    if [ "$migrated" != true ]; then
      if [ "$old_release_held" = true ]; then mv "$tmp/old-release" "$old_release"; fi
      if [ "$old_current_held" = true ]; then mv "$tmp/current" "$current"; fi
      for ((i=replaced-1; i>=0; i--)); do
        rm -f "${instruction_paths[i]}"
        mv "$tmp/links/$i" "${instruction_paths[i]}"
      done
      rm -f "$AGENT_HUB_HOME/AGENTS.md"
    fi
    rm -rf "$tmp"
  }
  trap rollback_managed EXIT
  mkdir -p "$tmp/backup" "$tmp/links" "$AGENT_HUB_HOME/backups"
  cp -a "$old_release" "$tmp/backup/managed-release"
  cp -a "$current" "$tmp/backup/current"
  for ((i=0; i<${#instruction_paths[@]}; i++)); do
    cp -a "${instruction_paths[i]}" "$tmp/backup/instructions-$i"
  done
  backup="$AGENT_HUB_HOME/backups/version-$(date -u +%Y%m%d-%H%M%S)-$(basename "$tmp").tar.gz"
  tar -czf "$backup" -C "$tmp/backup" .
  gzip -t "$backup"
  tar -tzf "$backup" >/dev/null
  cp "$old_release/AGENTS.md" "$tmp/AGENTS.md"
  mv "$tmp/AGENTS.md" "$AGENT_HUB_HOME/AGENTS.md"
  for ((i=0; i<${#instruction_paths[@]}; i++)); do
    mv "${instruction_paths[i]}" "$tmp/links/$i"
    if ! ln -s "$AGENT_HUB_HOME/AGENTS.md" "${instruction_paths[i]}"; then
      mv "$tmp/links/$i" "${instruction_paths[i]}"
      fail "cannot link instructions at ${instruction_paths[i]}"
    fi
    replaced=$((replaced+1))
  done
  for path in "${instruction_paths[@]}"; do
    [ -f "$path" ] || fail "instructions not visible at $path"
  done
  mv "$current" "$tmp/current"
  old_current_held=true
  mv "$old_release" "$tmp/old-release"
  old_release_held=true
  migrated=true
  rmdir "$AGENT_HUB_HOME/releases" 2>/dev/null || true
  printf '%s\n' "$(basename "$backup")" >>"$AGENT_HUB_HOME/backups/managed.list"
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
  retire_ownership_marker
  printf 'Verified old release backup: %s\n' "$backup"
  printf 'Agent Hub instructions now live at %s/AGENTS.md\n' "$AGENT_HUB_HOME"
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
[ ! -e "$AGENT_HUB_HOME/AGENTS.md" ] && [ ! -L "$AGENT_HUB_HOME/AGENTS.md" ] ||
  fail "instructions already exist at $AGENT_HUB_HOME/AGENTS.md; no changes made"
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

mv "$snapshot/skills" "$tmp/core-skills"
for skill in "$tmp/core-skills"/*; do
  name="$(basename "$skill")"
  [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] ||
    fail "invalid core skill name: $name"
  grep -Fxq 'source: https://github.com/thinkforward-ai/agent-hub' "$skill/SKILL.md" ||
    fail "missing core skill source: $name"
  awk -v name="$name" -v installed="agent-hub-$name" '
    NR == 1 && $0 != "---" { exit 1 }
    $0 == "name: " name && !closed && !named {
      print "name: " installed
      named = 1
      next
    }
    NR > 1 && $0 == "---" && !closed {
      if (!named) exit 1
      print
      print ""
      print "Installed by Agent Hub as `" installed "` from `https://github.com/thinkforward-ai/agent-hub`. References to skills from this repository use the same `agent-hub-` prefix."
      closed = 1
      next
    }
    { print }
    END { if (!named || !closed) exit 1 }
  ' "$skill/SKILL.md" >"$tmp/prefixed-skill.md" ||
    fail "invalid core skill frontmatter: $name"
  mv "$tmp/prefixed-skill.md" "$skill/SKILL.md"
  chmod 755 "$skill"
  chmod 644 "$skill/SKILL.md"
  mv "$skill" "$tmp/core-skills/agent-hub-$name"
done

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
cp "$snapshot/AGENTS.md" "$AGENT_HUB_HOME/AGENTS.md"
created+=("$AGENT_HUB_HOME/AGENTS.md")

for path in "${skill_paths[@]}"; do
  mkdir -p "$(dirname "$path")"
  hold_path "$path"
  ln -s "$AGENT_HUB_HOME/skills" "$path"
  created+=("$path")
done
hold_path "$current"
for path in "${instruction_paths[@]}"; do
  mkdir -p "$(dirname "$path")"
  hold_path "$path"
  ln -s "$AGENT_HUB_HOME/AGENTS.md" "$path"
  created+=("$path")
done
if [ ! -e "$AGENT_HUB_HOME/sources.json" ] && [ ! -L "$AGENT_HUB_HOME/sources.json" ]; then
  cp "$snapshot/sources.json" "$AGENT_HUB_HOME/sources.json"
  created+=("$AGENT_HUB_HOME/sources.json")
fi
for path in "${skill_paths[@]}"; do
  [ -f "$path/agent-hub-manage-skills/SKILL.md" ] || fail "manager skill not visible at $path"
done
[ -f "$AGENT_HUB_HOME/AGENTS.md" ] || fail "instructions not visible"
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
if [ -n "$old_release" ]; then
  rm -rf "$old_release"
  rmdir "$AGENT_HUB_HOME/releases" 2>/dev/null || true
fi
retire_ownership_marker
printf 'Agent Hub skills installed at %s\n' "$AGENT_HUB_HOME/skills"
printf 'Sources available at %s\n' "$AGENT_HUB_HOME/sources.json"
if [ -n "$old_release" ]; then
  printf 'Legacy skills are no longer active. Recover them from the backup above if needed.\n'
fi
