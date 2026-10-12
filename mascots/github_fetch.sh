#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# github_fetch.sh — contribution calendar for the Nyx GitHub mascot.
#
# Usage: github_fetch.sh <username>
# Emits { "rows", "cols", "cells": [{ r, c, l }] } (l = 0..4 level).
# Public contributions page; no token. Network/parse errors emit {"error":...}.
# ═══════════════════════════════════════════════════════════════════════════
set -u
user="${1:-xscriptor}"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

curl -fsSL --max-time 15 "https://github.com/users/${user}/contributions" -o "$tmp" 2>/dev/null \
    || { echo '{"error":"network"}'; exit 0; }

python3 - "$tmp" <<'PY'
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
if not cells:
    print(json.dumps({"error": "empty"}))
else:
    print(json.dumps({"rows": rows, "cols": cols, "cells": cells}))
PY
