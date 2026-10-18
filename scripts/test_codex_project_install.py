#!/usr/bin/env python3
"""End-to-end project/global Codex installation lifecycle in isolated fixtures."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
ENGINE = ROOT / 'scripts/lib/codex-install.py'


def snapshot(root):
    return {str(p.relative_to(root)): (('link', os.readlink(p)) if p.is_symlink()
            else ('file', p.read_bytes()) if p.is_file() else ('dir',))
            for p in root.rglob('*')}


class CodexInstallTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='codex-install-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.home = self.base / 'home'
        self.project = self.base / 'project with spaces'
        self.source = self.base / 'source'
        self.home.mkdir()
        self.project.mkdir()
        shutil.copytree(ROOT / 'dist/codex', self.source / 'dist/codex')
        shutil.copytree(ROOT / 'project-pack', self.source / 'project-pack')
        shutil.copytree(ROOT / 'claude-pack', self.source / 'claude-pack')
        self.env = dict(os.environ, HOME=str(self.home))
        self.dist = self.source / 'dist/codex'

    def command(self, args, success=True, **kwargs):
        result = subprocess.run([str(a) for a in args], cwd=self.project, env=self.env,
                                text=True, capture_output=True, **kwargs)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def install(self, *args, success=True):
        return self.command(['python3', ENGINE, '--source', self.source,
                             '--project', self.project, *args], success=success)

    def init(self, *args, success=True):
        return self.command(['bash', ROOT / 'scripts/init-project.sh', '--source', self.source,
                             '--include-codex', *args], success=success)

    def uninstall(self, *args, success=True):
        return self.command(['bash', ROOT / 'scripts/uninstall-project.sh', '--force', *args], success=success)

    def test_fresh_combined_and_no_global_writes(self):
        before = snapshot(self.home)
        self.init('--include-claude')
        self.assertEqual(snapshot(self.home), before)
        for path in (self.dist / 'skills').rglob('*'):
            if path.is_file():
                target = self.project / '.agents/skills' / path.relative_to(self.dist / 'skills')
                self.assertTrue(target.is_file(), str(target))
                self.assertFalse(target.is_symlink())
        for path in (self.dist / 'agents').iterdir():
            self.assertEqual(path.read_bytes(), (self.project / '.codex/agents' / path.name).read_bytes())
        self.assertFalse((self.project / '.codex/config.toml').exists())
        import tomllib
        role = tomllib.loads((self.project / '.codex/agents/example-agent.toml').read_text())
        self.assertTrue(all(role.get(key) for key in ['name', 'description', 'developer_instructions']))
        self.assertTrue((self.project / '.claude/.agentic-pack-vendored').is_file())
        self.assertIn('codex rules begin', (self.project / 'AGENTS.md').read_text())
        for directory in ['.agents', '.codex']:
            for path in (self.project / directory).rglob('*'):
                if path.is_file():
                    self.assertNotIn('__AGENTIC_CODEX_', path.read_text())

    def test_upgrade_retirement_and_owner_preservation(self):
        rules = self.project / 'AGENTS.md'
        rules.write_bytes(b'Owner instructions\r\n')
        config = self.project / '.codex/config.toml'
        config.parent.mkdir()
        config.write_text('# Owner config\nmodel = "owner-choice"\n')
        fixture = self.dist / 'skills/fixture'
        fixture.mkdir()
        (fixture / 'SKILL.md').write_text('Generated from fixture\n')
        (fixture / 'nested').mkdir()
        (fixture / 'nested/data').write_text('old data')
        script = self.dist / 'scripts/fixture.sh'
        script.write_text('#!/bin/bash\necho old\n')
        role = self.dist / 'agents/fixture.toml'
        role.write_text('name = "fixture"\n# Generated from fixture\n')
        self.init()
        script.write_text('#!/bin/bash\necho new\n')
        rules.write_bytes(rules.read_bytes() + b'Owner footer\r\n')
        (self.project / '.agents/skills/fixture/nested/stale').write_text('stale')
        (fixture / 'nested/data').write_text('new data')
        self.init()
        self.assertEqual((self.project / '.agents/skills/fixture/nested/data').read_text(), 'new data')
        self.assertIn('echo new', (self.project / '.codex/scripts/fixture.sh').read_text())
        script.unlink()
        role.unlink()
        self.assertFalse((self.project / '.agents/skills/fixture/nested/stale').exists())
        shutil.rmtree(fixture)
        before = snapshot(self.project)
        out = self.init('--dry-run').stdout
        self.assertIn('fixture', out)
        self.assertEqual(snapshot(self.project), before)
        self.init()
        self.assertFalse((self.project / '.agents/skills/fixture').exists())
        self.assertFalse((self.project / '.codex/scripts/fixture.sh').exists())
        self.assertFalse((self.project / '.codex/agents/fixture.toml').exists())
        self.assertEqual(rules.read_text().count('codex rules begin'), 1)
        self.assertTrue(rules.read_bytes().startswith(b'Owner instructions\r\n'))
        self.assertTrue(rules.read_bytes().endswith(b'Owner footer\r\n'))
        self.assertEqual(config.read_text(), '# Owner config\nmodel = "owner-choice"\n')

    def test_collisions_and_force_keep_owner_skills(self):
        skill = self.project / '.agents/skills/my-spec'
        skill.mkdir(parents=True)
        (skill / 'SKILL.md').write_text('Owner skill\n')
        (skill / 'keep').write_text('Owner data\n')
        self.init('--force')
        self.assertEqual((skill / 'SKILL.md').read_text(), 'Owner skill\n')
        inventory = json.loads((self.project / '.codex/.agentic-pack-vendored').read_text())
        self.assertNotIn('.agents/skills/my-spec', inventory['entries'])
        self.uninstall()
        self.assertEqual((skill / 'keep').read_text(), 'Owner data\n')

    def test_uninstall_without_project_state(self):
        (self.project / 'AGENTS.md').write_text('Owner rules\n')
        self.init('--no-track')
        (self.project / 'AGENTS.md').write_text((self.project / 'AGENTS.md').read_text() + 'Owner footer\n')
        user = self.project / '.codex/scripts/owner.sh'
        user.write_text('Owner script\n')
        empty = self.project / '.codex/owner-empty'
        empty.mkdir()
        shutil.rmtree(self.project / '.project')
        before = snapshot(self.project)
        self.uninstall('--dry-run')
        self.assertEqual(snapshot(self.project), before)
        self.uninstall()
        self.assertEqual((self.project / 'AGENTS.md').read_text(), 'Owner rules\nOwner footer\n')
        self.assertEqual(user.read_text(), 'Owner script\n')
        self.assertTrue(empty.is_dir())
        self.assertFalse((self.project / '.codex/.agentic-pack-vendored').exists())
        self.assertFalse((self.project / '.agents/skills/my-spec').exists())

    def test_symlink_destinations_preserve_external_files(self):
        external = self.base / 'external'
        external.mkdir()
        for name in ['AGENTS.md', 'config.toml']:
            (external / name).write_text('Owner source\n')
        (self.project / 'AGENTS.md').symlink_to(external / 'AGENTS.md')
        (self.project / '.agents').symlink_to(external, target_is_directory=True)
        (self.project / '.codex').mkdir()
        (self.project / '.codex/config.toml').symlink_to(external / 'config.toml')
        before = snapshot(external)
        self.init()
        self.uninstall()
        self.assertEqual(snapshot(external), before)
        self.assertTrue((self.project / 'AGENTS.md').is_symlink())
        # A redirected .codex cannot safely host the inventory: fail before init.
        other = self.base / 'other'
        other.mkdir()
        (other / '.codex').symlink_to(external, target_is_directory=True)
        result = subprocess.run(['python3', str(ENGINE), '--source', str(self.source), '--project', str(other)],
                                env=self.env, capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(snapshot(external), before)

    def test_dry_run_and_invalid_input_write_nothing(self):
        before = snapshot(self.project)
        self.init('--dry-run')
        self.assertEqual(snapshot(self.project), before)
        (self.project / 'AGENTS.md').write_text('<!-- agentic-project-init codex rules begin -->\nmissing end\n')
        before = snapshot(self.project)
        self.init(success=False)
        self.assertEqual(snapshot(self.project), before)
        (self.project / 'AGENTS.md').unlink()
        shutil.rmtree(self.dist)
        self.init(success=False)
        self.assertEqual(snapshot(self.project), {})

    def test_move_and_execute_without_source_or_global_install(self):
        self.init()
        moved = self.base / 'moved project'
        self.project.rename(moved)
        self.project = moved
        shutil.rmtree(self.source)
        skill = self.project / '.agents/skills/my-orchestrate/SKILL.md'
        relative = re.search(r'([.]+/[^\s`]+/orchestrate-stage-codex.sh)', skill.read_text()).group(1)
        helper = (skill.parent / relative).resolve()
        self.assertEqual(helper, self.project / '.codex/scripts/orchestrate-stage-codex.sh')
        fakebin = self.base / 'bin'
        fakebin.mkdir()
        fake = fakebin / 'codex'
        fake.write_text('''#!/usr/bin/env python3
import json, pathlib, sys
args = sys.argv
pathlib.Path(args[args.index('--output-last-message') + 1]).write_text('stage complete')
print(json.dumps({'type': 'thread.started', 'thread_id': 'fixture-session'}))
print(json.dumps({'type': 'turn.completed'}))
''')
        fake.chmod(0o755)
        self.env['PATH'] = str(fakebin) + os.pathsep + self.env['PATH']
        result = self.command(['bash', helper, 'run', 'status', '--cd', self.project,
                               '--log-dir', self.base / 'logs', '--timeout', '5'], input='inspect project\n')
        self.assertIn('stage complete', result.stdout)
        self.assertFalse((self.home / '.codex').exists())
        self.assertFalse((self.home / '.agents').exists())
        self.uninstall()

    def test_replaced_managed_assets_become_owner_owned(self):
        self.init()
        skill = self.project / '.agents/skills/my-spec'
        (skill / 'SKILL.md').write_text('Owner replacement\n')
        helper = self.project / '.codex/scripts/orchestrate-stage-codex.sh'
        helper.write_text('Owner replacement helper\n')
        self.init()
        self.uninstall()
        self.assertEqual((skill / 'SKILL.md').read_text(), 'Owner replacement\n')
        self.assertEqual(helper.read_text(), 'Owner replacement helper\n')

    def test_override_and_global_install_warnings(self):
        (self.home / '.codex').mkdir()
        (self.home / '.codex/.agentic-pack-codex-source').write_text('global source\n')
        (self.project / 'AGENTS.override.md').write_text('Owner override\n')
        output = self.init().stdout
        self.assertIn('duplicate skills', output)
        self.assertIn('shadows', output)

    def test_global_legacy_cleanup_and_source_symlink_migration(self):
        codex = self.home / '.codex'
        codex.mkdir()
        (codex / 'AGENTS.md').symlink_to(self.dist / 'AGENTS.md')
        skills = self.home / '.agents/skills/retired'
        skills.mkdir(parents=True)
        (skills / 'SKILL.md').write_text('Generated from legacy fixture\n')
        owner = skills.parent / 'owner'
        owner.mkdir()
        (owner / 'SKILL.md').write_text('Owner skill\n')
        fixture = self.dist / 'skills/retired-current'
        fixture.mkdir()
        (fixture / 'SKILL.md').write_text('Generated from current fixture\n')
        self.command(['python3', ENGINE, '--source', self.source])
        shutil.rmtree(fixture)
        self.command(['python3', ENGINE, '--source', self.source, '--dry-run'])
        self.assertTrue((skills.parent / 'retired-current').exists())
        self.command(['python3', ENGINE, '--source', self.source, '--copy'])
        self.assertFalse((skills.parent / 'retired-current').exists())
        self.assertFalse(skills.exists())
        self.assertTrue(owner.exists())
        self.assertFalse((codex / 'AGENTS.md').is_symlink())
        self.assertNotIn('__AGENTIC_CODEX_', (codex / 'AGENTS.md').read_text())
        self.assertIn(str(codex / 'scripts'), (self.home / '.agents/skills/my-audit/SKILL.md').read_text())


if __name__ == '__main__':
    unittest.main()
