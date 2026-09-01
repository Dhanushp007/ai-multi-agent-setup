#!/bin/sh
# Applies configs from this Setup repo to a target project.
#
# Usage:
#   ./apply.sh --target /path/to/project [--stack node|python|dotnet] [--dry-run] [--backup]
#
# Requires: jq (https://stedolan.github.io/jq/)

set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=""
STACK="*"
DRY_RUN=0
BACKUP=0

# ── Argument parsing ──────────────────────────────────────────────────────────

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)   TARGET="$2";  shift 2 ;;
    --stack)    STACK="$2";   shift 2 ;;
    --dry-run)  DRY_RUN=1;    shift   ;;
    --backup)   BACKUP=1;     shift   ;;
    *) printf "Unknown argument: %s\n" "$1" >&2; exit 1 ;;
  esac
done

# ── Pre-flight ────────────────────────────────────────────────────────────────

if [ -z "$TARGET" ]; then
  printf "Error: --target is required\n" >&2; exit 1
fi
if [ ! -d "$TARGET" ]; then
  printf "Error: Target path does not exist: %s\n" "$TARGET" >&2; exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  printf "Error: jq is required. Install with: brew install jq / apt install jq\n" >&2; exit 1
fi

APPLIED=0; WARNINGS=0

printf "\n"
[ "$DRY_RUN" -eq 1 ] && printf "  [DRY RUN] No changes will be made.\n\n"
printf "  Target : %s\n" "$TARGET"
printf "  Stack  : %s\n\n" "$STACK"

MANIFEST="$REPO_ROOT/scripts/manifest.json"

# ── JSONC comment stripper (strips // ... lines before passing to jq) ─────────

strip_jsonc() {
  sed 's|[[:space:]]*/\/.*$||g' "$1"
}

# ── Deep merge two JSON files into destination ────────────────────────────────
# Uses jq recursive merge: nested objects are merged, scalars from $2 win.

merge_json() {
  src_file="$1"
  dst_file="$2"
  tmp="${dst_file}.tmp"
  stripped_src=$(strip_jsonc "$src_file" | jq '.')
  stripped_dst=$(strip_jsonc "$dst_file" | jq '.')
  printf '%s\n%s' "$stripped_dst" "$stripped_src" \
    | jq -s 'reduce .[1:[]| to_entries[] as $e (.[0]; .[$e.key] = if (.[($e.key)] | type) == "object" and ($e.value | type) == "object" then .[($e.key)] * $e.value else $e.value end)' \
    > "$tmp" && mv "$tmp" "$dst_file"
}

# ── Apply one manifest entry ──────────────────────────────────────────────────

apply_entry() {
  source_rel="$1"
  dest_rel="$2"
  mode="$3"
  stacks="$4"

  # Stack filter
  if [ "$stacks" != "*" ]; then
    [ "$STACK" = "*" ] && return 0
    printf "%s" "$stacks" | grep -qw "$STACK" || return 0
  fi

  src="$REPO_ROOT/$source_rel"
  dst="$TARGET/$dest_rel"

  if [ ! -e "$src" ]; then
    printf "  ⚠  Missing source, skipping : %s\n" "$source_rel"
    WARNINGS=$((WARNINGS + 1)); return 0
  fi

  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$dst")"
  fi

  case "$mode" in
    copy)
      if [ "$DRY_RUN" -eq 1 ]; then
        printf "  →  copy    %s  →  %s\n" "$source_rel" "$dest_rel"
      else
        [ "$BACKUP" -eq 1 ] && [ -e "$dst" ] && cp -r "$dst" "${dst}.bak"
        cp -r "$src" "$dst"
        printf "  ✔  Copied    %s  →  %s\n" "$source_rel" "$dest_rel"
      fi
      APPLIED=$((APPLIED + 1))
      ;;

    symlink)
      if [ ! -d "$TARGET/.git" ]; then
        printf "  ⚠  Not a git repo — skipping hook symlink: %s\n" "$dest_rel"
        WARNINGS=$((WARNINGS + 1)); return 0
      fi
      if [ "$DRY_RUN" -eq 1 ]; then
        printf "  →  symlink %s  →  %s\n" "$source_rel" "$dest_rel"
      else
        [ -e "$dst" ] && rm -rf "$dst"
        ln -sf "$src" "$dst"
        printf "  ✔  Symlinked %s  →  %s\n" "$source_rel" "$dest_rel"
      fi
      APPLIED=$((APPLIED + 1))
      ;;

    merge)
      if [ "$DRY_RUN" -eq 1 ]; then
        printf "  →  merge   %s  →  %s\n" "$source_rel" "$dest_rel"
        APPLIED=$((APPLIED + 1)); return 0
      fi
      if [ -f "$dst" ]; then
        [ "$BACKUP" -eq 1 ] && cp "$dst" "${dst}.bak"
        if merge_json "$src" "$dst" 2>/dev/null; then
          printf "  ✔  Merged    %s  →  %s\n" "$source_rel" "$dest_rel"
        else
          printf "  ⚠  Merge failed (%s) — copying instead\n" "$dest_rel"
          cp "$src" "$dst"
          WARNINGS=$((WARNINGS + 1))
        fi
      else
        cp "$src" "$dst"
        printf "  ✔  Copied    %s  →  %s\n" "$source_rel" "$dest_rel"
      fi
      APPLIED=$((APPLIED + 1))
      ;;
  esac
}

# ── Main loop ─────────────────────────────────────────────────────────────────

count=$(strip_jsonc "$MANIFEST" | jq '.entries | length')
i=0
while [ "$i" -lt "$count" ]; do
  src_rel=$(strip_jsonc "$MANIFEST"  | jq -r ".entries[$i].source")
  dst_rel=$(strip_jsonc "$MANIFEST"  | jq -r ".entries[$i].destination")
  mode=$(strip_jsonc "$MANIFEST"     | jq -r ".entries[$i].mode")
  stacks=$(strip_jsonc "$MANIFEST"   | jq -r ".entries[$i].stacks | if type == \"array\" then join(\" \") else . end")
  apply_entry "$src_rel" "$dst_rel" "$mode" "$stacks"
  i=$((i + 1))
done

# ── Summary ───────────────────────────────────────────────────────────────────

printf "\n  ─────────────────────────────────────────\n"
if [ "$DRY_RUN" -eq 1 ]; then
  printf "  Dry run: %d entries would be applied.\n\n" "$APPLIED"
else
  printf "  Applied: %d   Warnings: %d\n\n" "$APPLIED" "$WARNINGS"
fi
