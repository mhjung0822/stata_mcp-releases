#!/usr/bin/env node
// stata-mcp 런처 — OS 무관 stdio 브릿지.
// Windows 는 bare `npx` 가 셸 없이 spawn 안 됨(claude-code #58510: spawn ENOENT)
//   → `cmd /c npx` 로 감쌈. mac/linux 는 `npx` 직접.
// node 는 양쪽 다 확실히 spawn 되므로(.exe, 배치 아님) 플러그인 하나로 OS 무관.
const { spawn } = require('child_process');

const url = process.argv[2] || 'http://127.0.0.1:8080/mcp';
const isWin = process.platform === 'win32';

const child = isWin
  ? spawn('cmd', ['/c', 'npx', '-y', 'mcp-remote', url], { stdio: 'inherit' })
  : spawn('npx', ['-y', 'mcp-remote', url], { stdio: 'inherit' });

child.on('exit', (code) => process.exit(code == null ? 1 : code));
child.on('error', (err) => { console.error('[stata-mcp launcher]', err.message); process.exit(1); });
process.on('SIGTERM', () => child.kill('SIGTERM'));
process.on('SIGINT',  () => child.kill('SIGINT'));
