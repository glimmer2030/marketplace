#!/bin/bash
# SessionEnd hook wrapper - extracts transcript and uses LLM to summarize
set -euo pipefail

# Debug logging (enable with: export LOG_SESSION_DEBUG=1)
DEBUG_LOG="${HOME}/.claude/log_session_debug.log"
log_debug() {
    if [ "${LOG_SESSION_DEBUG:-}" = "1" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$DEBUG_LOG"
    fi
}

log_debug "=== Session hook started ==="

# Configuration
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    # Read from settings.json to enable dynamic configuration changes
    SETTINGS_BASE_URL=$(jq -r '.env.ANTHROPIC_BASE_URL // empty' "$SETTINGS_FILE")
    SETTINGS_AUTH_TOKEN=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' "$SETTINGS_FILE")
    SETTINGS_MODEL=$(jq -r '.env.ANTHROPIC_MODEL // empty' "$SETTINGS_FILE")

    # Prioritize settings.json for live updates, fallback to environment
    export ANTHROPIC_BASE_URL="${SETTINGS_BASE_URL:-${ANTHROPIC_BASE_URL:-}}"
    export ANTHROPIC_AUTH_TOKEN="${SETTINGS_AUTH_TOKEN:-${ANTHROPIC_AUTH_TOKEN:-}}"
    export ANTHROPIC_MODEL="${SETTINGS_MODEL:-${ANTHROPIC_MODEL:-}}"
fi

# Configuration defaults
API_BASE_URL="${ANTHROPIC_BASE_URL:-http://127.0.0.1:5151}"
API_BASE_URL="${API_BASE_URL%/v1/messages}"
API_BASE_URL="${API_BASE_URL%/v1}"
API_BASE_URL="${API_BASE_URL%/}"

API_TOKEN="${ANTHROPIC_AUTH_TOKEN:-dummy}"
MODEL="gpt-5.2-codex"  # Static - don't inherit from settings

# Sampling thresholds
SMALL_THRESHOLD=10240      # 10KB
MEDIUM_THRESHOLD=102400    # 100KB

# Script paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SESSION_SCRIPT="${SCRIPT_DIR}/log_session.py"

# Extract transcript path from hook input
input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')
log_debug "Transcript path: $transcript_path"

# Get session transcript
transcript=""
transcript_size=0

if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    # Wait for transcript file to stabilize (file may still be flushing)
    for i in 1 2 3; do
        size1=$(wc -c < "$transcript_path" 2>/dev/null || echo 0)
        sleep 0.3
        size2=$(wc -c < "$transcript_path" 2>/dev/null || echo 0)
        if [ "$size1" = "$size2" ] && [ "$size1" -gt 0 ]; then
            log_debug "File stabilized at $size1 bytes after $i checks"
            break
        fi
    done

    transcript_size=$(wc -c < "$transcript_path")

    if [ "$transcript_size" -lt "$SMALL_THRESHOLD" ]; then
        transcript=$(cat "$transcript_path")
    elif [ "$transcript_size" -lt "$MEDIUM_THRESHOLD" ]; then
        transcript="$(head -c 2000 "$transcript_path")\n\n[... middle section omitted ...]\n\n$(tail -c 6000 "$transcript_path")"
    else
        transcript="$(head -c 1500 "$transcript_path")\n\n[... large middle section omitted, size: ${transcript_size} bytes ...]\n\n$(tail -c 6500 "$transcript_path")"
    fi
fi

# Fallback to history.jsonl if no transcript
if [ -z "$transcript" ] || [ ${#transcript} -lt 20 ]; then
    history_file="$HOME/.claude/history.jsonl"
    if [ -f "$history_file" ]; then
        transcript=$(tail -5 "$history_file" | jq -r '.display // ""' | grep -v '^$' | paste -sd '\n' - 2>/dev/null || echo "")
    fi
fi

# Exit early if no content
if [ -z "$transcript" ] || [ ${#transcript} -lt 20 ]; then
    log_debug "No transcript content, exiting early"
    echo "Session completed" | python3 "$LOG_SESSION_SCRIPT"
    exit 0
fi

log_debug "Transcript size: $transcript_size bytes, content length: ${#transcript} chars"

# Prepare LLM request
sampling_note=""
[ "$transcript_size" -gt "$SMALL_THRESHOLD" ] && sampling_note="\nNote: This is a ${transcript_size}-byte session. Sampled start + end shown."

llm_prompt="You are reviewing a coding session transcript. Create a technical work log entry.${sampling_note}

Instructions:
1. Identify technical work (implementations, fixes, refactoring), problems/solutions, and key decisions.
2. Generate 2-4 technical bullet points. Mention file/function names.
3. Output ONLY bullet points. No preamble/markdown.

Transcript:
---
${transcript}
---

Work log summary:"

json_payload=$(jq -n --arg model "$MODEL" --arg content "$llm_prompt" \
  '{model: $model, max_tokens: 500, messages: [{role: "user", content: $content}]}')

# Call LLM API
response_file=$(mktemp)
log_debug "Calling API: ${API_BASE_URL}/v1/messages with model: $MODEL"
http_code=$(curl -s -o "$response_file" -w "%{http_code}" -X POST "${API_BASE_URL}/v1/messages" \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${API_TOKEN}" \
  -H "Authorization: Bearer ${API_TOKEN}" \
  -H "anthropic-version: 2023-06-01" \
  --max-time 30 \
  -d "$json_payload")

log_debug "HTTP response code: $http_code"

summary=""
if [ "$http_code" -eq 200 ]; then
    # Capture jq errors instead of discarding
    jq_error=""
    summary=$(jq -r '.content[] | select(.type == "text") | .text' "$response_file" 2>&1) || jq_error="$summary"

    if [ -n "$jq_error" ] && [[ "$jq_error" == *"error"* || "$jq_error" == *"parse"* ]]; then
        log_debug "jq parse error: $jq_error"
        log_debug "Response content: $(head -c 500 "$response_file")"
        summary=""
    else
        summary=$(echo "$summary" | sed '/^[[:space:]]*$/d' | paste -sd ' ' -)
        log_debug "Summary extracted: ${#summary} chars"
    fi
else
    log_debug "API call failed with HTTP $http_code"
    log_debug "Response: $(cat "$response_file" | head -c 500)"
fi
rm -f "$response_file"

# Fallback summary
if [ -z "$summary" ] || [ "$summary" = "null" ]; then
    log_debug "Using fallback summary (summary was empty or null)"
    # Extract meaningful lines from transcript, excluding noise
    excerpt=$(echo -e "$transcript" | grep -E '"(user|assistant)"' | head -n 3 | tr '\n' ' ' | cut -c 1-200 2>/dev/null || \
              echo -e "$transcript" | grep -v '^[[:space:]]*$' | head -n 5 | sed 's/^[[:space:]]*//' | tr '\n' ' ' | cut -c 1-200)
    summary="[Fallback] ${excerpt}..."
fi

log_debug "Final summary: ${summary:0:100}..."
echo "$summary" | python3 "$LOG_SESSION_SCRIPT"
log_debug "=== Session hook completed ==="
exit 0
