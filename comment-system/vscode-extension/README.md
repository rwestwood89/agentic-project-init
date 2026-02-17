# File-Native Comments VSCode Extension

Pre-built VSCode extension for inline comment display.

## Install

```bash
code --install-extension file-native-comments-0.1.0.vsix
```

Or from the repo root:
```bash
./scripts/setup-comments.sh --vscode
```

## Features

- Gutter icons on lines with comment threads
- Inline decorations showing comment previews
- Status indicators (open/resolved/wontfix)
- Click to view full thread details

## Building from Source

The extension source lives in the [agentic-mbse-comment-system](https://github.com/yourorg/agentic-mbse-comment-system) repository under `vscode-extension/`.

To build:

```bash
cd vscode-extension/file-native-comments
npm install
npx vsce package
```

This produces a `.vsix` file you can install with `code --install-extension`.

## Requirements

- VSCode 1.85.0 or later
- The `comment` CLI must be installed and available in PATH
