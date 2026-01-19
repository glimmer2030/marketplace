#!/bin/bash
# SessionEnd hook wrapper - extracts transcript and uses LLM to summarize
set -euo pipefail

# Configuration
API_BASE_URL="${ANTHROPIC_BASE_URL:-http://localhost:4141}"
API_TOKEN="${ANTHROPIC_AUTH_TOKEN:-dummy}"
MODEL="${ANTHROPIC_MODEL:-gemini-3-pro-preview}"

# Smart sampling thresholds
SMALL_THRESHOLD=10240      # 10KB - send full transcript
MEDIUM_THRESHOLD=102400    # 100KB - smart sampling
MAX_SAMPLED_SIZE=8000      # Max chars to send to LLM after sampling

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_SESSION_SCRIPT="${SCRIPT_DIR}/log_session.py"

# Read hook input from stdin
input=$(cat)

# Extract transcript path from hook input
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

# Try to get session transcript
transcript=""
transcript_size=0

# Source 1: Transcript file (if provided and exists)
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    transcript_size=$(wc -c < "$transcript_path")

    if [ "$transcript_size" -lt "$SMALL_THRESHOLD" ]; then
        # Small session: use full transcript
        transcript=$(cat "$transcript_path")
    elif [ "$transcript_size" -lt "$MEDIUM_THRESHOLD" ]; then
        # Medium session: use start + end
        start=$(head -c 2000 "$transcript_path")
        end=$(tail -c 6000 "$transcript_path")
        transcript="${start}

[... middle section omitted ...]

${end}"
    else
        # Large session: use start + end only
        start=$(head -c 1500 "$transcript_path")
        end=$(tail -c 6500 "$transcript_path")
        transcript="${start}

[... large middle section omitted, session size: ${transcript_size} bytes ...]

${end}"
    fi
fi

# Source 2: If no transcript, try history.jsonl
if [ -z "$transcript" ] || [ ${#transcript} -lt 20 ]; then
    history_file="$HOME/.claude/history.jsonl"
    if [ -f "$history_file" ]; then
        # Get last 5 entries and format them
        transcript=$(tail -5 "$history_file" | jq -r '.display // ""' | grep -v '^$' | paste -sd '\n' - 2>/dev/null || echo "")
    fi
fi

# If still no content, use fallback
if [ -z "$transcript" ] || [ ${#transcript} -lt 20 ]; then
    echo "Session completed" | python3 "$LOG_SESSION_SCRIPT"
    exit 0
fi

# Prepare prompt for LLM (with context about sampling)
sampling_note=""
if [ "$transcript_size" -gt "$SMALL_THRESHOLD" ]; then
    sampling_note="
Note: This is a ${transcript_size}-byte session. You're seeing sampled key sections (start + end)."
fi

llm_prompt="You are reviewing a coding session transcript. Create a technical work log entry.${sampling_note}

Instructions:
1. Analyze the conversation to identify:
   - Specific technical work completed (implementations, bug fixes, refactoring)
   - Problems encountered and their solutions
   - Key decisions or discoveries
   - File/function names if relevant

2. Generate a concise summary (2-4 bullet points, each 1-2 lines)
   - Be specific and technical
   - Mention concrete details (file names, function names, technical concepts)
   - Avoid generic statements
   - If exploratory: note what was explored and key findings

3. Output ONLY the bullet points, no preamble, no markdown formatting.

Transcript:
---
${transcript}
---

Work log summary:"

# Call local LLM API
summary=$(curl -s -X POST "${API_BASE_URL}/v1/messages" \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${API_TOKEN}" \
  -H "anthropic-version: 2023-06-01" \
  --max-time 25 \
  -d @- <<EOF | jq -r '.content[0].text // "Session completed"'
{
  "model": "${MODEL}",
  "max_tokens": 500,
  "messages": [
    {
      "role": "user",
      "content": $(echo "$llm_prompt" | jq -Rs .)
    }
  ]
}
EOF
)

# Check if LLM call succeeded
if [ -z "$summary" ] || [ "$summary" = "null" ]; then
    # Fallback: use raw transcript excerpt
    summary=$(echo "$transcript" | head -c 300)
fi

# Pass summary to Python script via stdin
echo "$summary" | python3 "$LOG_SESSION_SCRIPT"

# Exit successfully
exit 0
