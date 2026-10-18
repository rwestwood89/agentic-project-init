#!/usr/bin/env python3
"""Shared Codex pack ownership, rendering, upgrade, and uninstall operations."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile

BEGIN = '<!-- agentic-project-init codex rules begin -->'
END = '<!-- agentic-project-init codex rules end -->'
MARKER = '.agentic-pack-vendored'


def generated(path):
    return path.is_file() and b'Generated from' in b'\n'.join(path.read_bytes().splitlines()[:20])


class Installer:
    def __init__(self, args):
        self.args = args
        self.project = args.project is not None
        self.root = Path(args.project).absolute() if self.project else Path.home()
        self.codex = self.root / '.codex'
        self.skills = self.root / '.agents/skills'
        self.instructions = self.root / 'AGENTS.md' if self.project else self.codex / 'AGENTS.md'
        self.marker = self.codex / (MARKER if self.project else '.agentic-pack-codex-inventory')
        self.dist = Path(args.source).resolve() / 'dist/codex'
        self._hashes = {}
        self.previous = self.read_inventory()
        self.owned = {}
        self.counts = dict(installed=0, skipped=0, removed=0)

    def safe(self, path):
        """Never follow destination links, including links in ancestors."""
        for part in [path, *path.parents]:
            if part == self.root:
                break
            if part.is_symlink() or (part != path and part.exists() and not part.is_dir()):
                return False
        return not (path.exists() and path.is_dir())

    def read_inventory(self):
        if not self.safe(self.marker) or not self.marker.is_file():
            return {}
        try:
            data = json.loads(self.marker.read_text())
            if data.get('version') != 1:
                raise ValueError('unsupported inventory version')
            entries = data['entries']
            if not isinstance(entries, dict) or not isinstance(data.get('hashes', {}), dict):
                raise ValueError('invalid inventory structure')
            self._hashes = data.get('hashes', {})
            for rel, kind in entries.items():
                path = Path(rel)
                if path.is_absolute() or '..' in path.parts or kind not in ('skill', 'file', 'rules'):
                    raise ValueError('invalid inventory entry')
                if not (rel.startswith('.agents/skills/') or rel.startswith('.codex/agents/')
                        or rel.startswith('.codex/scripts/') or rel in ('AGENTS.md', '.codex/AGENTS.md')):
                    raise ValueError('invalid inventory destination')
            return entries
        except (ValueError, KeyError, TypeError) as exc:
            raise SystemExit(f'Invalid Codex install inventory {self.marker}: {exc}') from exc

    def report(self, action, path, detail=''):
        self.counts[action] += 1
        verb = dict(installed='install', skipped='skip', removed='remove')[action]
        label = f'[DRY RUN] Would {verb}' if self.args.dry_run else action
        print(f'{label}: {path}{": " + detail if detail else ""}')

    def write(self, path, content, mode=None):
        if self.args.dry_run:
            return
        if mode is None:
            mode = path.stat().st_mode & 0o777 if path.is_file() and not path.is_symlink() else 0o644
        path.parent.mkdir(parents=True, exist_ok=True)
        # Atomic replacement does not follow an existing destination symlink.
        fd, temporary = tempfile.mkstemp(dir=path.parent)
        try:
            with os.fdopen(fd, 'wb') as stream:
                stream.write(content)
            os.chmod(temporary, mode)
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)

    def render(self, source, destination):
        content = source.read_bytes()
        if b'__AGENTIC_CODEX_' not in content:
            return content
        # Paths in skill prose are relative to that installed skill's directory,
        # including references in nested supporting documents.
        base = destination.parent
        if destination.is_relative_to(self.skills):
            base = self.skills / destination.relative_to(self.skills).parts[0]
        scripts = os.path.relpath(self.codex / 'scripts', base) if self.project else str(self.codex / 'scripts')
        skills = os.path.relpath(self.skills, base) if self.project else str(self.skills)
        content = content.replace(b'__AGENTIC_CODEX_SCRIPTS__', scripts.encode()).replace(
            b'__AGENTIC_CODEX_SKILLS__', skills.encode())
        if self.project and destination.is_relative_to(self.skills):
            guidance = ("\n\nPack paths in this document are relative to the installed skill directory "
                        "(the directory containing its SKILL.md), not the shell working directory. "
                        "Resolve that directory from the skill path in the skill catalog, then resolve "
                        "pack paths to absolute paths before reading, executing, or passing them to "
                        "subagents. Quote resolved shell paths. Keep the project working directory; "
                        "pass it explicitly with --cd when running the orchestration helper.\n")
            # Keep YAML frontmatter intact and put path context before executable examples.
            text = content.decode()
            if text.startswith('---\n') and '\n---\n' in text[4:]:
                end = text.index('\n---\n', 4) + 5
                text = text[:end] + guidance + text[end:]
            else:
                text = guidance.lstrip('\n') + text
            content = text.encode()
        return content

    def key(self, path):
        return str(path.relative_to(self.root))

    def was_owned_file(self, path):
        if generated(path):
            return True
        # Unmarked helper scripts are owned only while their installed bytes match
        # the inventory. An owner's replacement is never silently removed.
        record = self.previous.get(self.key(path))
        if record == 'file':
            hashes = self._hashes
            return path.is_file() and hashes.get(self.key(path)) == hashlib.sha256(path.read_bytes()).hexdigest()
        return False

    def file(self, source, target, bundle=False):
        if not self.safe(target):
            # Retain compatibility with global source symlinks, never project links.
            if (not self.project and target.is_symlink() and target.resolve() == source.resolve()
                    and self.safe(target.parent / "_probe")):
                pass
            else:
                self.report('skipped', target, 'symlink, redirected parent, or directory')
                return False
        if not bundle and target.exists() and not target.is_symlink() and not self.was_owned_file(target) and not self.args.force:
            self.report('skipped', target, 'owner-authored file')
            return False
        content = self.render(source, target)
        link = not self.project and not self.args.copy and content == source.read_bytes() and not bundle
        if link and target.is_symlink() and target.resolve() == source.resolve():
            self.report('skipped', target, 'already current')
            return True
        if (not link and target.is_file() and not target.is_symlink()
                and target.read_bytes() == content
                and target.stat().st_mode & 0o777 == source.stat().st_mode & 0o777):
            self.report('skipped', target, 'already current')
            return True
        if link:
            if not self.args.dry_run:
                target.parent.mkdir(parents=True, exist_ok=True)
                if target.is_symlink() or target.exists():
                    target.unlink()
                target.symlink_to(source)
        else:
            self.write(target, content, source.stat().st_mode & 0o777)
        self.report('installed', target)
        return True

    def skill(self, source, target):
        entry = target / 'SKILL.md'
        if not self.safe(entry) or (target.exists() and not generated(entry) and not self.args.force):
            self.report('skipped', target, 'owner-authored or redirected skill directory')
            return
        self.owned[self.key(target)] = 'skill'
        for file in sorted(source.rglob('*')):
            if file.is_file():
                self.file(file, target / file.relative_to(source), bundle=True)
        if target.is_dir():
            for file in sorted(target.rglob('*'), reverse=True):
                if (file.is_file() or file.is_symlink()) and not (source / file.relative_to(target)).is_file():
                    if self.safe(file):
                        self.remove_file(file)
            self.prune(target)

    def block(self, source=None):
        target = self.instructions
        legacy_link = (not self.project and target.is_symlink()
                       and target.resolve() == (self.dist / 'AGENTS.md').resolve()
                       and self.safe(target.parent / '_probe'))
        if not self.safe(target) and not legacy_link:
            self.report('skipped', target, 'symlink, redirected parent, or directory')
            return
        old = target.read_bytes().decode() if target.exists() else ''
        lines = old.splitlines(keepends=True)
        starts = [i for i, line in enumerate(lines) if line.rstrip('\r\n') == BEGIN]
        ends = [i for i, line in enumerate(lines) if line.rstrip('\r\n') == END]
        if (starts or ends) and (len(starts) != 1 or len(ends) != 1 or starts[0] >= ends[0]):
            raise SystemExit(f'Malformed or duplicate managed rules markers: {target}')
        replacement = ''
        if source:
            body = self.render(source, target).decode()
            replacement = BEGIN + '\n' + body.rstrip('\n') + '\n' + END + '\n'
        if starts:
            updated = ''.join(lines[:starts[0]]) + replacement + ''.join(lines[ends[0] + 1:])
        elif source:
            # Migrate a former globally generated whole-file installation.
            if not self.project and generated(target):
                updated = replacement
            else:
                updated = old + ('\n' if old and not old.endswith('\n') else '') + replacement
        else:
            return
        if updated != old:
            if updated:
                self.write(target, updated.encode())
                self.report('installed' if source else 'removed', target, 'managed rules block')
            else:
                self.remove_file(target)
        if source:
            self.owned[self.key(target)] = 'rules'

    def remove_file(self, path):
        self.report('removed', path)
        if not self.args.dry_run:
            path.unlink(missing_ok=True)

    def prune(self, root):
        if self.args.dry_run or not root.is_dir() or root.is_symlink():
            return
        for path in sorted(root.rglob('*'), reverse=True):
            if path.is_dir() and not path.is_symlink():
                try:
                    path.rmdir()
                except OSError:
                    pass
        try:
            root.rmdir()
        except OSError:
            pass

    def retire(self, entries):
        for rel, kind in sorted(entries.items()):
            path = self.root / rel
            if kind == 'rules':
                self.block()
            elif kind == 'skill':
                if self.safe(path / 'SKILL.md') and generated(path / 'SKILL.md'):
                    # Do not traverse symlinked directories or delete their referents.
                    for child in sorted(path.rglob('*'), reverse=True):
                        if child.is_symlink():
                            if self.safe(child.parent / '_probe'):
                                self.remove_file(child)
                        elif child.is_file() and self.safe(child):
                            self.remove_file(child)
                    self.prune(path)
                else:
                    self.report('skipped', path, 'retired skill is owner-authored or redirected')
            elif self.safe(path) and self.was_owned_file(path):
                self.remove_file(path)
            elif (not self.project and path.is_symlink() and path.resolve().is_relative_to(self.dist)
                  and self.safe(path.parent / '_probe')):
                self.remove_file(path)
            elif path.exists() or path.is_symlink():
                self.report('skipped', path, 'retired file is owner-authored or redirected')

    def validate_rules(self):
        # Validate markers before installing any assets.
        if self.safe(self.instructions) and self.instructions.is_file():
            old = self.instructions.read_bytes().decode()
            if BEGIN in old or END in old:
                lines = old.splitlines()
                if lines.count(BEGIN) != 1 or lines.count(END) != 1 or lines.index(BEGIN) >= lines.index(END):
                    raise SystemExit(f'Malformed or duplicate managed rules markers: {self.instructions}')

    def run(self):
        if not self.safe(self.marker):
            raise SystemExit(f'Unsafe Codex inventory destination: {self.marker}')
        self.validate_rules()
        if self.args.uninstall:
            self.retire(self.previous)
            if self.marker.exists():
                self.remove_file(self.marker)
            if not self.args.dry_run:
                for path in [self.skills, self.root / '.agents', self.codex / 'agents',
                             self.codex / 'scripts', self.codex]:
                    if path.is_dir() and not path.is_symlink():
                        try:
                            path.rmdir()
                        except OSError:
                            pass
            return
        if not (self.dist / 'AGENTS.md').is_file():
            raise SystemExit(f'Missing Codex distribution rules: {self.dist / "AGENTS.md"}; run scripts/build-codex-pack.sh first.')
        for required in ['skills', 'agents', 'scripts']:
            if not (self.dist / required).is_dir():
                raise SystemExit(f'Missing Codex distribution: {self.dist / required}; run scripts/build-codex-pack.sh first.')
        if self.project:
            if (Path.home() / '.codex/.agentic-pack-codex-source').exists():
                print('Warning: a global Codex pack is also installed; duplicate skills can appear.')
            if (self.root / 'AGENTS.override.md').exists():
                print('Warning: AGENTS.override.md shadows the managed AGENTS.md rules.')
        else:
            print('Global instructions and user-level skills')
        for source in sorted((self.dist / 'skills').iterdir()):
            if source.is_dir():
                self.skill(source, self.skills / source.name)
        for directory in ['agents', 'scripts']:
            for source in sorted((self.dist / directory).iterdir()):
                if source.is_file():
                    target = self.codex / directory / source.name
                    if self.file(source, target):
                        self.owned[self.key(target)] = 'file'
        self.block(self.dist / 'AGENTS.md')
        retired = {key: kind for key, kind in self.previous.items() if key not in self.owned
                   and not (kind == 'skill' and (self.dist / 'skills' / Path(key).name).exists())
                   and not (kind == 'file' and (self.dist / Path(key).relative_to('.codex')).exists())
                   and kind != 'rules'}
        # BL-010: also adopt cleanup of old generated skills predating inventories.
        if self.skills.is_dir():
            for path in self.skills.iterdir():
                if not (self.dist / 'skills' / path.name).exists() and self.safe(path / 'SKILL.md') and generated(path / 'SKILL.md'):
                    retired[self.key(path)] = 'skill'
        self.retire(retired)
        hashes = {rel: hashlib.sha256((self.root / rel).read_bytes()).hexdigest()
                  for rel, kind in self.owned.items() if kind == 'file' and (self.root / rel).is_file()}
        self.write(self.marker, (json.dumps(dict(version=1, entries=self.owned, hashes=hashes), indent=2) + '\n').encode())
        self.report('installed', self.marker, 'ownership inventory')
        if not self.project:
            self.write(self.codex / '.agentic-pack-codex-source', (str(self.dist.parent.parent) + '\n').encode())
            from datetime import datetime, timezone
            self.write(self.codex / '.agentic-pack-codex-installed-at', (datetime.now(timezone.utc).isoformat() + '\n').encode())
        print('Summary: ' + ', '.join(f'{count} {kind}' for kind, count in self.counts.items()))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True)
    parser.add_argument('--project')
    parser.add_argument('--copy', action='store_true')
    parser.add_argument('--force', action='store_true')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--uninstall', action='store_true')
    Installer(parser.parse_args()).run()


if __name__ == '__main__':
    main()
