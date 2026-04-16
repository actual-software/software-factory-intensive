#!/usr/bin/env bash
# import.sh — convert tracker issues to beads. Skip-safe, idempotent.
#
# Probes for sibling tracker skills, invokes their `list-issues` verb,
# and for each issue either creates a new bead or updates the existing
# mapped bead. Writes the mapping manifest to
# .actual/planner/tracker-sync.json.
#
# Exit code is always 0 on non-catastrophic failure — the formula
# must not fail because a tracker is missing or misconfigured.
set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
manifest_dir=".actual/planner"
manifest_file="$manifest_dir/tracker-sync.json"
mkdir -p "$manifest_dir"

# Bootstrap an empty manifest if missing.
if [ ! -f "$manifest_file" ]; then
    echo '{"updated_at":"","mappings":{}}' > "$manifest_file"
fi

log() { echo "[tracker-to-beads] $*"; }

# Probe for sibling trackers.
probe_output=$("$script_dir/probe.sh")
if [ "$probe_output" = "none" ]; then
    log "no tracker skill detected — skipping import"
    # Record the no-op run in the manifest.
    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '.updated_at = $ts | .mappings = (.mappings // {})' \
        "$manifest_file" > "$manifest_file.tmp" && mv "$manifest_file.tmp" "$manifest_file"
    exit 0
fi

# For each discovered tracker, run its list-issues verb.
total_created=0
total_updated=0
total_skipped=0

while read -r name path; do
    [ -z "$name" ] && continue
    log "probing $name ($path)"

    # Minimum contract: `<path>/scripts/list-issues.sh` or
    # `<path>/scripts/list-issues` must exist and print JSON to stdout.
    list_cmd=""
    for candidate in \
        "$path/scripts/list-issues.sh" \
        "$path/scripts/list-issues" \
        "$path/list-issues.sh"; do
        if [ -x "$candidate" ]; then
            list_cmd="$candidate"
            break
        fi
    done
    if [ -z "$list_cmd" ]; then
        log "  $name: no list-issues script found — skipping"
        continue
    fi

    # Capture output. If the command fails or prints invalid JSON,
    # warn and continue to the next tracker.
    raw_output=$("$list_cmd" 2>/dev/null || true)
    if [ -z "$raw_output" ]; then
        log "  $name: list-issues produced no output — skipping"
        continue
    fi
    if ! echo "$raw_output" | jq -e 'type == "array"' >/dev/null 2>&1; then
        log "  $name: list-issues did not emit a JSON array — skipping"
        continue
    fi

    # Iterate issues.
    issue_count=$(echo "$raw_output" | jq 'length')
    log "  $name: $issue_count issues"

    for i in $(seq 0 $((issue_count - 1))); do
        issue_json=$(echo "$raw_output" | jq -c ".[$i]")
        issue_id=$(echo "$issue_json" | jq -r '.id')
        issue_title=$(echo "$issue_json" | jq -r '.title')
        issue_url=$(echo "$issue_json" | jq -r '.url // ""')
        issue_body=$(echo "$issue_json" | jq -r '.body // ""')
        issue_labels=$(echo "$issue_json" | jq -r '.labels // [] | .[]' 2>/dev/null || true)

        mapping_key="$name:$issue_id"
        existing=$(jq -r --arg k "$mapping_key" '.mappings[$k] // empty' "$manifest_file")

        notes_body="$issue_body"
        if [ -n "$issue_url" ]; then
            notes_body="$notes_body

---
source: $issue_url"
        fi

        if [ -n "$existing" ]; then
            # Update the existing bead.
            if bd update "$existing" --title "$issue_title" --notes "$notes_body" >/dev/null 2>&1; then
                total_updated=$((total_updated + 1))
            else
                log "  $name: failed to update $existing — skipping"
                total_skipped=$((total_skipped + 1))
            fi
        else
            # Create a new bead.
            label_args=("--label" "needs-plan" "--label" "source:$name" "--label" "tracker-key:$issue_id")
            while IFS= read -r lbl; do
                [ -z "$lbl" ] && continue
                label_args+=("--label" "$lbl")
            done <<< "$issue_labels"

            new_id=$(bd create \
                --title "$issue_title" \
                "${label_args[@]}" \
                --notes "$notes_body" \
                --json 2>/dev/null | jq -r '.id // empty')

            if [ -n "$new_id" ]; then
                jq --arg k "$mapping_key" --arg v "$new_id" \
                    '.mappings[$k] = $v' \
                    "$manifest_file" > "$manifest_file.tmp" && mv "$manifest_file.tmp" "$manifest_file"
                total_created=$((total_created + 1))
            else
                log "  $name: failed to create bead for $issue_id — skipping"
                total_skipped=$((total_skipped + 1))
            fi
        fi
    done
done <<< "$probe_output"

# Stamp manifest with timestamp.
jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '.updated_at = $ts' \
    "$manifest_file" > "$manifest_file.tmp" && mv "$manifest_file.tmp" "$manifest_file"

log "done: $total_created created, $total_updated updated, $total_skipped skipped"
exit 0
