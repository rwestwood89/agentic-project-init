#!/usr/bin/env python3
"""
Parse a Claude Code transcript JSONL and extract a condensed summary.

Usage:
    ./parse-transcript.py <transcript.jsonl> [--max-chars=50000]

Outputs a condensed markdown summary to stdout, suitable for LLM consumption.
"""

import json
import sys
import argparse
from pathlib import Path


def truncate(text: str, max_len: int = 1000) -> str:
    """Truncate text with ellipsis."""
    if len(text) <= max_len:
        return text
    return text[:max_len] + "... [truncated]"


def extract_text_content(content) -> str:
    """Extract text from various content formats."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    parts.append(item.get("text", ""))
                elif item.get("type") == "tool_use":
                    tool_name = item.get("name", "unknown")
                    parts.append(f"[Tool: {tool_name}]")
                elif item.get("type") == "tool_result":
                    parts.append("[Tool result]")
            elif isinstance(item, str):
                parts.append(item)
        return "\n".join(parts)
    if isinstance(content, dict):
        if content.get("type") == "text":
            return content.get("text", "")
        return str(content)
    return str(content) if content else ""


def parse_transcript(filepath: str, max_total_chars: int = 50000) -> dict:
    """Parse transcript and return structured summary."""

    messages = []
    user_messages = []
    assistant_messages = []
    tool_uses = set()

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue

            entry_type = entry.get("type")

            if entry_type == "user":
                content = entry.get("message", {})
                if isinstance(content, dict):
                    text = extract_text_content(content.get("content", ""))
                else:
                    text = extract_text_content(content)
                if text.strip():
                    user_messages.append(text.strip())
                    messages.append(("user", text.strip()))

            elif entry_type == "assistant":
                msg = entry.get("message", {})
                content = msg.get("content", [])
                text = extract_text_content(content)

                # Track tool uses
                if isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and item.get("type") == "tool_use":
                            tool_uses.add(item.get("name", "unknown"))

                if text.strip():
                    assistant_messages.append(text.strip())
                    messages.append(("assistant", text.strip()))

    # Build condensed output
    result = {
        "total_messages": len(messages),
        "user_message_count": len(user_messages),
        "assistant_message_count": len(assistant_messages),
        "tools_used": sorted(tool_uses),
        "first_message": user_messages[0] if user_messages else "",
        "last_user_message": user_messages[-1] if user_messages else "",
        "conversation": []
    }

    # Sample conversation: first 5, last 5, and some middle
    chars_used = 0
    char_per_message = max_total_chars // min(len(messages), 20) if messages else 1000

    indices_to_include = set()

    # Always include first 5 and last 5
    for i in range(min(5, len(messages))):
        indices_to_include.add(i)
    for i in range(max(0, len(messages) - 5), len(messages)):
        indices_to_include.add(i)

    # Sample some from middle if there are many messages
    if len(messages) > 15:
        step = len(messages) // 10
        for i in range(5, len(messages) - 5, step):
            indices_to_include.add(i)

    for i in sorted(indices_to_include):
        if i >= len(messages):
            continue
        role, text = messages[i]
        truncated = truncate(text, char_per_message)
        chars_used += len(truncated)
        if chars_used > max_total_chars:
            result["conversation"].append({
                "index": i,
                "role": role,
                "content": "[... truncated due to size limit ...]"
            })
            break
        result["conversation"].append({
            "index": i,
            "role": role,
            "content": truncated
        })

    return result


def format_markdown(data: dict) -> str:
    """Format parsed data as markdown."""
    lines = [
        "# Transcript Summary",
        "",
        f"**Total exchanges:** {data['total_messages']} messages ({data['user_message_count']} user, {data['assistant_message_count']} assistant)",
        f"**Tools used:** {', '.join(data['tools_used']) if data['tools_used'] else 'None'}",
        "",
        "## First User Message",
        "",
        f"> {truncate(data['first_message'], 500)}",
        "",
        "## Last User Message",
        "",
        f"> {truncate(data['last_user_message'], 500)}",
        "",
        "## Conversation Sample",
        "",
    ]

    prev_index = -1
    for msg in data["conversation"]:
        if prev_index >= 0 and msg["index"] > prev_index + 1:
            lines.append(f"*... [{msg['index'] - prev_index - 1} messages omitted] ...*")
            lines.append("")

        role_label = "**User:**" if msg["role"] == "user" else "**Assistant:**"
        lines.append(f"### Message {msg['index'] + 1} — {msg['role'].title()}")
        lines.append("")
        lines.append(msg["content"])
        lines.append("")
        prev_index = msg["index"]

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Parse Claude Code transcript")
    parser.add_argument("transcript", help="Path to transcript JSONL file")
    parser.add_argument("--max-chars", type=int, default=50000,
                        help="Maximum characters in output (default: 50000)")
    parser.add_argument("--json", action="store_true",
                        help="Output as JSON instead of markdown")
    args = parser.parse_args()

    filepath = Path(args.transcript).expanduser()
    if not filepath.exists():
        print(f"Error: File not found: {filepath}", file=sys.stderr)
        sys.exit(1)

    data = parse_transcript(str(filepath), args.max_chars)

    if args.json:
        print(json.dumps(data, indent=2))
    else:
        print(format_markdown(data))


if __name__ == "__main__":
    main()
