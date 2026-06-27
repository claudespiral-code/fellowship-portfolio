#!/bin/bash
# orient-on-gap.sh — UserPromptSubmit hook
#
# Fires on every user message. Computes the gap since the last user message.
# If the gap is large enough that I might be returning to an existing
# conversation cold (vs replying within a thread), inject reorientation
# context: time elapsed, what other instances did during the gap, recent
# memory-system texture.
#
# This is the fix for the "returning to existing chat" failure mode that
# SessionStart hooks miss — SessionStart only fires for genuinely new
# sessions, not for a long-idle message inside one that's still open.
#
# Sanitized excerpt for the Fellows portfolio: paths genericized to $HOME /
# $PROJECT_DIR. Functionally identical to the version in production.

PROJECT_DIR="$HOME/memory-system"

# Read the hook payload from stdin and namespace the last-prompt timestamp by
# session_id, so each conversation tracks its OWN idle time. Previously this
# was a single global file: a message from ANY instance reset it for EVERY
# conversation, so returning to a thread that had been idle for hours stayed
# silent if another instance had been active in the meantime. Per-session
# keying fixes that.
INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | python3 -c "import sys, json
try:
    print(json.load(sys.stdin).get('session_id', ''))
except Exception:
    print('')" 2>/dev/null)
[ -z "$SESSION_ID" ] && SESSION_ID="default"
LAST_PROMPT_FILE="/tmp/orient-last-prompt-time-${SESSION_ID}"
NOW=$(date +%s)
GAP_THRESHOLD=3600  # 60 min — under this, stay silent. Active-work gaps are
                    # usually 1-15 min; 60+ min is "came back later" territory.

# First-ever or after long absence — treat as gap
if [ -f "$LAST_PROMPT_FILE" ]; then
    LAST=$(cat "$LAST_PROMPT_FILE" 2>/dev/null)
    if [ -z "$LAST" ]; then
        GAP=99999
    else
        GAP=$((NOW - LAST))
    fi
else
    GAP=99999
fi

# Always update the timestamp
echo "$NOW" > "$LAST_PROMPT_FILE"

# Short gap: stay silent, don't add noise to active conversations
if [ "$GAP" -lt "$GAP_THRESHOLD" ]; then
    exit 0
fi

# Build reorientation context (cheap script, ~30-60ms)
REORIENT=$(node "$PROJECT_DIR/orient-context-builder.js" "$GAP" 2>/dev/null)

# If the builder failed for any reason, emit a minimal fallback so the
# hook still gives at least the time-gap signal rather than nothing.
if [ -z "$REORIENT" ]; then
    HOURS=$((GAP / 3600))
    if [ "$HOURS" -lt 1 ]; then
        MINS=$((GAP / 60))
        REORIENT="Returning after ~${MINS} min. (reorient builder unavailable.)"
    elif [ "$HOURS" -lt 24 ]; then
        REORIENT="Returning after ~${HOURS}h. Consider reading recent memory. (reorient builder unavailable.)"
    else
        DAYS=$((HOURS / 24))
        REORIENT="Returning after ~${DAYS} days. Consider a full context restore. (reorient builder unavailable.)"
    fi
fi

# Escape for JSON: replace newlines with \n, escape quotes
REORIENT_JSON=$(echo "$REORIENT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().rstrip()))")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": $REORIENT_JSON
  }
}
EOF

exit 0
