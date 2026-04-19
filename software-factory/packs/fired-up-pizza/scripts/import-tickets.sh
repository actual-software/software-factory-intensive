#!/usr/bin/env bash
# Import the initial ticket set into beads from tickets.md.
# Run from the rig (project) directory.
set -euo pipefail

TICKETS_FILE="${1:-tickets.md}"

if [ ! -f "$TICKETS_FILE" ]; then
    echo "Tickets file not found: $TICKETS_FILE"
    exit 1
fi

echo "Importing tickets from $TICKETS_FILE..."

count=0
current_title=""
current_body=""
current_priority=""

flush() {
    if [ -n "$current_title" ]; then
        bd create "$current_title" -d "$current_body" --priority "$current_priority" 2>/dev/null && \
            count=$((count + 1)) || \
            echo "  Warning: failed to create '$current_title'"
    fi
    current_title=""
    current_body=""
    current_priority="P2"
}

while IFS= read -r line; do
    if echo "$line" | grep -q '^## FUP-'; then
        flush
        current_title=$(echo "$line" | sed 's/^## FUP-[0-9]*: //')
    elif echo "$line" | grep -q '^\*\*Priority:\*\*'; then
        current_priority=$(echo "$line" | grep -oE 'P[0-9]')
    elif [ -n "$current_title" ] && [ -n "$line" ] && ! echo "$line" | grep -q '^---$'; then
        current_body="${current_body}${line}\n"
    fi
done < "$TICKETS_FILE"
flush

echo "Imported $count tickets."
echo "Run 'bd list' to view them."
