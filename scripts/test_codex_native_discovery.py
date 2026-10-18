#!/usr/bin/env python3
"""Optional Codex CLI smoke test: native agent and skill discovery in a trusted project.

The local mock endpoint rejects the request after capturing tool definitions. No real
model API is contacted and no agent is spawned. Requires the Codex CLI on PATH.
"""
import http.server
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading

def main():
    if not shutil.which("codex"):
        raise SystemExit("This optional smoke test requires the Codex CLI on PATH.")
    root = Path(__file__).resolve().parent.parent
    with tempfile.TemporaryDirectory(prefix='bl011-discovery-') as temp:
        base = Path(temp)
        project = base / 'project'
        project.mkdir()
        subprocess.run(["git", "init", "-q", str(project)], check=True)
        home = base / 'home'
        home.mkdir()
        (home / ".codex").mkdir()
        (home / ".codex/config.toml").write_text(f'[projects.{json.dumps(str(project))}]\ntrust_level = "trusted"\n')
        env = dict(os.environ, HOME=str(home), CODEX_HOME=str(home / '.codex'), BL011_FAKE_API_KEY='local-fixture')
        subprocess.run(['python3', str(root / 'scripts/lib/codex-install.py'), '--source', str(root), '--project', str(project)], env=env, check=True, capture_output=True)
        requests = []
        class Handler(http.server.BaseHTTPRequestHandler):
            def do_POST(self):
                requests.append(json.loads(self.rfile.read(int(self.headers.get('Content-Length', 0)))))
                self.send_response(400)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"error":{"message":"End of local discovery probe","type":"invalid_request_error"}}')
            def log_message(self, *args):
                pass
        server = http.server.HTTPServer(('127.0.0.1', 0), Handler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        args = [shutil.which('codex'), 'exec', '--skip-git-repo-check', '--cd', str(project),
                '-c', 'model_provider="fixture"', '-c', 'model="fixture"',
                '-c', 'model_providers.fixture.name="Fixture"',
                '-c', f'model_providers.fixture.base_url="http://127.0.0.1:{server.server_port}/v1"',
                '-c', 'model_providers.fixture.wire_api="responses"',
                '-c', 'model_providers.fixture.env_key="BL011_FAKE_API_KEY"',
                'Inspect the project.']
        try:
            result = subprocess.run(args, env=env, cwd=project, capture_output=True, text=True, timeout=25)
            print('requests captured:', len(requests))
            if requests:
                tools = requests[0].get('tools', [])
                agent_tools = [t for t in tools if 'spawn_agent' in json.dumps(t)]
                print('spawn tool includes example-agent:', 'example-agent' in json.dumps(agent_tools))
                print('project skills discovered:', '/my-ask-me/SKILL.md' in json.dumps(requests[0]))
                assert 'example-agent' in json.dumps(agent_tools), 'Native agent not exposed in spawn tool'
                assert '/my-ask-me/SKILL.md' in json.dumps(requests[0]), 'Project skills not discovered'
            else:
                print(result.stderr[-2000:])
                raise SystemExit('No local model request captured')
        finally:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    main()
