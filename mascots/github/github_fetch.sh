#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# github_fetch.sh — contribution calendar for the Nyx GitHub mascot.
#
# Usage: github_fetch.sh <username> [force]
# Emits { "rows", "cols", "cells": [{ r, c, l }] } (l = 0..4 level).
#
# Caching: the parsed result is stored in
#   ${XDG_CACHE_HOME:-$HOME/.cache}/nyx/github/<user>.json
# and reused for GITHUB_CACHE_TTL seconds (default 1800). A cold fetch that
# fails falls back to the (stale) cache when present. Pass "force" (or set
# GITHUB_FORCE=1) to bypass the cache. Network/parse errors emit {"error":...}.
# ═══════════════════════════════════════════════════════════════════════════
set -u
user="${1:-xscriptor}"
force="${2:-${GITHUB_FORCE:-}}"
ttl="${GITHUB_CACHE_TTL:-1800}"

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/nyx/github"
mkdir -p "$cache_dir" 2>/dev/null || true
cache="$cache_dir/${user}.json"

# ── cache hit ──────────────────────────────────────────────────────────────
if [ -z "$force" ] && [ -s "$cache" ]; then
    mtime=$(stat -c %Y "$cache" 2>/dev/null || echo 0)
    if [ "$(( $(date +%s) - mtime ))" -lt "$ttl" ]; then
        cat "$cache"
        exit 0
    fi
fi

# ── fetch + parse ──────────────────────────────────────────────────────────
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

parse() {
    python3 - "$1" <<'PY'
import sys, re, json
h = open(sys.argv[1], encoding="utf-8", errors="replace").read()
cells = []
rows = cols = 0
for m in re.finditer(r"<td\b[^>]*>", h):
    t = m.group(0)
    lv = re.search(r'data-level="(\d+)"', t)
    ix = re.search(r"contribution-day-component-(\d+)-(\d+)", t)
    if lv and ix:
        r, c, l = int(ix.group(1)), int(ix.group(2)), int(lv.group(1))
        cells.append({"r": r, "c": c, "l": l})
        rows = max(rows, r + 1)
        cols = max(cols, c + 1)
print(json.dumps({"rows": rows, "cols": cols, "cells": cells})
      if cells else json.dumps({"error": "empty"}))
PY
}

if curl -fsSL --max-time 15 "https://github.com/users/${user}/contributions" -o "$tmp" 2>/dev/null; then
    out="$(parse "$tmp")"
    case "$out" in
        *'"error"'*)
            [ -s "$cache" ] && cat "$cache" || printf '%s\n' "$out" ;;
        *)
            tmpc="$cache.$$"
            if printf '%s\n' "$out" > "$tmpc" 2>/dev/null; then mv -f "$tmpc" "$cache"; fi
            printf '%s\n' "$out" ;;
    esac
else
    [ -s "$cache" ] && cat "$cache" || printf '%s\n' '{"error":"network"}'
fi
