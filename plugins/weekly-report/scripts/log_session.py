#!/usr/bin/env python3
"""
Auto-log session summary to ~/.work-log.md
Can be called by SessionEnd hook or manually via /summary command
"""

import os
import sys
from datetime import datetime
from pathlib import Path

# Configuration
LOG_FILE = Path.home() / ".work-log.md"

def get_project_name():
    """Get current project name from working directory."""
    cwd = os.getcwd()
    # Get the directory name (project name)
    project = Path(cwd).name
    return project

def read_session_context():
    """
    Try to read session context from environment or stdin.
    Claude Code may pass session info through environment variables or stdin.
    """
    # Check if session info is passed via environment
    session_info = os.environ.get('CLAUDE_SESSION_SUMMARY', '')

    # If not, try to read from stdin (some hooks may pipe data)
    if not session_info and not sys.stdin.isatty():
        try:
            # Read all content from stdin (no arbitrary limit)
            # The wrapper script already handles transcript size limiting
            session_info = sys.stdin.read()
        except:
            pass

    return session_info

def extract_key_activities(session_info):
    """
    Extract key activities from session info.
    Simple heuristic: look for action verbs and important keywords.
    """
    if not session_info:
        return "Session completed (no details available)"

    # Simple extraction: take first few lines or sentences
    lines = session_info.split('\n')
    # Filter out empty lines and take first 3 meaningful lines
    meaningful_lines = [line.strip() for line in lines if line.strip()][:3]

    if meaningful_lines:
        return ' | '.join(meaningful_lines)
    else:
        return "Session completed"

def append_to_log(project, summary):
    """Append session log to work-log.md"""
    now = datetime.now()
    date_str = now.strftime('%Y-%m-%d')
    day_name = now.strftime('%A')
    time_str = now.strftime('%H:%M')

    # Read existing log
    if LOG_FILE.exists():
        with open(LOG_FILE, 'r', encoding='utf-8') as f:
            content = f.read()
    else:
        # Create new log file with header
        content = f"# Work Log {now.year}\n\n"

    # Check if today's date header exists
    date_header = f"## {date_str} ({day_name})"

    if date_header not in content:
        # Add new date section
        content += f"\n{date_header}\n"

    # Append new session entry
    entry = f"### [{project}] {time_str}\n- {summary}\n\n"
    content += entry

    # Write back
    with open(LOG_FILE, 'w', encoding='utf-8') as f:
        f.write(content)

    return True

def main():
    """Main function to log session."""
    try:
        # Get project name
        project = get_project_name()

        # Read session context (if available)
        session_info = read_session_context()

        # Extract key activities
        summary = extract_key_activities(session_info)

        # Append to log
        append_to_log(project, summary)

        # Success message (will be shown if hook output is displayed)
        print(f"✓ Logged session to ~/.work-log.md")

        return 0

    except Exception as e:
        # Log error but don't fail (hooks should be non-intrusive)
        error_log = Path.home() / ".claude" / "log_session_error.log"
        with open(error_log, 'a') as f:
            f.write(f"{datetime.now()}: {str(e)}\n")
        return 1

if __name__ == "__main__":
    sys.exit(main())
