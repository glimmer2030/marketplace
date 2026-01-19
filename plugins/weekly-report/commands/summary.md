---
name: summary
description: Manually generate current session work summary and log to ~/.work-log.md
---

# Summary Command

Generate a technical work summary for the current session and save it to `~/.work-log.md`.

## Purpose

This command allows users to manually save work summaries during long sessions. It complements automatic session logging by letting you checkpoint important work at any time.

## Core Logic

1. **Analyze** the entire conversation history in this session
2. **Generate** a concise technical summary (2-4 bullet points)
3. **Save** to `~/.work-log.md` by calling `log_session.py` via stdin
4. **Confirm** to user that summary was saved

## Summary Generation Rules

Analyze the complete conversation history and extract:

- **Concrete technical work completed**: implementations, bug fixes, refactoring, configuration changes
- **Problems encountered and solutions**: error messages, debugging steps, resolutions
- **Key decisions or discoveries**: architectural choices, technical insights, important findings
- **Specific references**: file paths, function names, command outputs, technical terms

### Format Requirements

- 2-4 bullet points (use `•` character)
- Each bullet: 1-2 lines maximum
- Be specific and technical - include file names, function names, error messages
- Avoid generic statements like "discussed options" or "made improvements"
- Use technical terminology accurately
- Separate multiple points within a bullet using ` | ` (space-pipe-space)

### Example Good Summaries

```
• Fixed authentication bug in auth.js:45 where JWT token validation was missing expiry check, preventing session timeout | Added unit tests to cover edge cases
• Implemented /summary skill for manual work log generation, reusing existing log_session.py infrastructure via stdin piping
• Debugged 500 error in API endpoint /api/users - root cause was unhandled null user.profile field in serialization | Added null checks in UserSerializer.serialize()
```

### Example Bad Summaries (Avoid These)

```
• Worked on authentication system (too vague)
• Fixed some bugs (no specifics)
• Discussed implementation approaches (no concrete work)
• Made improvements to the codebase (meaningless)
```

## Execution Steps

1. **Generate the summary** by analyzing the full conversation history above
2. **Find the log_session.py script** - it should be in the plugin's scripts directory:
   - Look for: `~/.claude/plugins/cache/*/weekly-report/*/scripts/log_session.py`
   - Or use glob to find: `ls ~/.claude/plugins/cache/*/weekly-report/*/scripts/log_session.py`
3. **Call log_session.py** via bash, piping summary through stdin:
   ```bash
   echo "<generated_summary>" | python3 <path_to_log_session.py>
   ```
4. **Confirm to user**: "✓ Work summary saved to ~/.work-log.md"

## Important Notes

- **Use the ENTIRE conversation context** - you have access to everything the user said and you responded, don't just look at recent messages
- **Be honest** - if the session was exploratory with no concrete work, say so:
  - Example: `• Explored codebase structure to understand authentication flow | Identified that auth logic is split between middleware/auth.js and routes/users.js | No implementations made`
- **The log_session.py script handles**:
  - Project name detection (from current working directory)
  - Timestamp generation
  - Markdown formatting
  - File I/O to ~/.work-log.md
- **You only need to**:
  - Generate the bullet-point summary text
  - Pipe it to the Python script
  - Confirm success

## Edge Cases

- **Session with no technical work**: Still log it, describe what was discussed
  - Example: `• Discussed approaches for implementing dark mode feature | No code written yet`
- **Pure Q&A session**: Log the questions and key insights
  - Example: `• Answered questions about React useEffect cleanup functions and memory leak prevention | Explained closure behavior in event handlers`
- **Multiple unrelated tasks**: Group by topic or list chronologically
  - Example: `• Fixed CSS alignment bug in header.css:23 | Updated deployment script to include health check endpoint | Reviewed PR #456 for database migration changes`

## When to Use

User will explicitly invoke `/summary` when they want to:
- Save progress on a long-running session before it gets too large
- Checkpoint work before switching to a different task
- Manually log important work

You should never proactively suggest using this command - wait for explicit user invocation.
