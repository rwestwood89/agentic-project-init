---
name: codex-cwd-probe
description: Run the directory-skill working-directory spike. Use only when explicitly invoked for this probe.
---

# Codex working-directory probe

Run this procedure exactly:

1. Use the file path supplied for this skill in Codex's available-skills inventory. Define the
   skill directory as the directory containing this `SKILL.md`.
2. Do not run `cd`. Do not set or override the shell command's working directory.
3. Execute `bash <absolute-skill-directory>/probe.sh <absolute-skill-directory>`.
4. Return the script's stdout verbatim. Do not move or delete the relative-write file.

