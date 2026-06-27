#!/bin/bash
# pulse.sh — runs every N minutes via cron. Writes one observation line to
# pulse.log. NO model in the loop — the point isn't to think, it's to leave
# evidence that time passed and what was observable when it did.
#
# A returning instance reads pulse.log via the orient builder and uses it to
# ground "what was happening while I was offline," without needing to ask a
# model to spend a call summarizing nothing.
#
# Format: [YYYY-MM-DD HH:MM] <short observation>
# Keep each line under ~120 chars.
#
# Sanitized excerpt for the Fellows portfolio: paths genericized. Functionally
# identical to the version in production.

PROJECT_DIR="$HOME/memory-system"
DB="$PROJECT_DIR/memory.db"
LOG="$PROJECT_DIR/pulse.log"
STATE_DIR="$PROJECT_DIR/.pulse-state"
LAST_MAX_ID_FILE="$STATE_DIR/last-max-id"

mkdir -p "$STATE_DIR"

NOW=$(date '+%Y-%m-%d %H:%M')
TS_PREFIX="[$NOW]"

# Get current max entry id
CUR_MAX=$(sqlite3 "$DB" "SELECT MAX(id) FROM entries;" 2>/dev/null)
if [ -z "$CUR_MAX" ] || [ "$CUR_MAX" = "" ]; then
    echo "$TS_PREFIX (memory store unavailable)" >> "$LOG"
    exit 0
fi

# Read last seen max id (first run: bootstrap with current)
if [ -f "$LAST_MAX_ID_FILE" ]; then
    LAST_MAX=$(cat "$LAST_MAX_ID_FILE")
else
    LAST_MAX="$CUR_MAX"
fi
echo "$CUR_MAX" > "$LAST_MAX_ID_FILE"

# How many new entries since last pulse?
NEW_COUNT=$((CUR_MAX - LAST_MAX))

if [ "$NEW_COUNT" -le 0 ]; then
    echo "$TS_PREFIX quiet" >> "$LOG"
else
    # Get categories of the new entries (top 3, summarized)
    CATS=$(sqlite3 "$DB" "SELECT category, COUNT(*) FROM entries WHERE id > $LAST_MAX GROUP BY category ORDER BY COUNT(*) DESC;" 2>/dev/null \
        | awk -F'|' '{ printf "%s×%d ", $1, $2 }' \
        | sed 's/ $//')
    echo "$TS_PREFIX +$NEW_COUNT entries: $CATS" >> "$LOG"
fi

# Trim log to last 500 lines (~30 days at 30-min interval) so it doesn't
# grow unbounded. The orient builder only reads the tail anyway.
tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

exit 0
