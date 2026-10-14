#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
# mascots_scan.sh — discovery for the mascot island/notch integration.
#
# Emits a single JSON object: { "mascots": [ ... ], "things": [ ... ] }.
#
#   mascots  one manifest per species, under the provider (plugin) and user
#            species dirs. A species is either a per-species folder with a
#            manifest.json
#            (its `entry`/`popover` resolve relative to that folder) or a flat
#            *.json file. `_base` is set to the manifest's directory.
#   things   one *.json descriptor per notch card, under the provider (plugin)
#            and user notch dirs: { id, label, icon, thumb?, exec?, enabled? }.
#
# The user dirs are scanned first and win on id collisions, so a user file
# overrides or extends the shipped defaults. Every entry gets "_base" (its
# directory) so the caller can resolve relative QML entries.
#
# Env (all optional): MASCOTS_SHIPPED, MASCOTS_USER, THINGS_SHIPPED,
# THINGS_USER. The *_SHIPPED vars hold colon-separated dir lists in precedence
# order (user dirs are always scanned first by the caller).
# ═══════════════════════════════════════════════════════════════════════════

set -u

if ! command -v jq >/dev/null 2>&1; then
    printf '%s\n' '{"mascots":[],"things":[]}'
    exit 0
fi

# Normalize a JSON manifest file to one object with a "_base" dir. A file may
# hold a single object or an array of them.
manifest() {
    local file="$1" base="$2"
    jq -c --arg base "$base" '
        if type == "array" then
            .[] | (if type == "object" then . + { _base: $base } else empty end)
        elif type == "object" then . + { _base: $base }
        else empty end' "$file" 2>/dev/null || true
}

scan_dir() {
    local dir="$1"
    [ -n "$dir" ] && [ -d "$dir" ] || return 0
    local f
    # Flat *.json manifests (legacy / user drop-in files).
    for f in "$dir"/*.json; do
        [ -f "$f" ] || continue
        manifest "$f" "$dir"
    done
    # Per-species folders: <dir>/<id>/manifest.json (entry/popover relative to
    # the folder). Only manifest.json is read, so stray JSON in a species folder
    # is ignored.
    for f in "$dir"/*/manifest.json; do
        [ -f "$f" ] || continue
        manifest "$f" "$(dirname "$f")"
    done
}

dedupe() {
    jq -s 'reduce .[] as $x ([]; if any(.[]; .id == $x.id) then . else . + [$x] end) // []'
}

# Colon-separated dir list, in order.
scan_list() {
    local list="$1" d
    [ -n "$list" ] || return 0
    local IFS=':'
    for d in $list; do
        scan_dir "$d"
    done
}

mascots=$(
    { scan_dir "${MASCOTS_USER:-}"; scan_list "${MASCOTS_SHIPPED:-}"; } | dedupe
)
things=$(
    { scan_dir "${THINGS_USER:-}"; scan_list "${THINGS_SHIPPED:-}"; } | dedupe
)

jq -nc --argjson m "${mascots:-[]}" --argjson t "${things:-[]}" \
    '{ mascots: $m, things: $t }'
