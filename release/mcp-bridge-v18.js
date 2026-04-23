const http = require('http');
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const isWin = process.platform === 'win32';

/**
 * Node.js v18 compatible MCP SSE-to-STDIO bridge.
 * - PID 파일로 서버를 추적 → 어느 브릿지든 항상 올바른 프로세스 종료
 * - SIGTERM 후 미응답 시 SIGKILL로 강제 종료
 * - stdin 종료 감지로 Claude Desktop 종료 확실히 처리
 */

const SSE_URL = process.argv[2];
if (!SSE_URL) {
    console.error("Usage: node bridge.js <sse-url>");
    process.exit(1);
}

const JAR_PATH  = path.join(__dirname, 'stata-mcp-server.jar');
const TMP       = os.tmpdir();
const PID_FILE  = path.join(TMP, 'stata-mcp-server.pid');
const LOG_FILE  = path.join(TMP, 'stata-mcp-bridge.log');
const LOCK_FILE = path.join(TMP, 'stata-mcp-bridge.lock');

function log(msg) {
    const line = `[${new Date().toISOString()}] [PID:${process.pid}] ${msg}\n`;
    console.error(line.trim());
    try { fs.appendFileSync(LOG_FILE, line); } catch (_) {}
}

// ─── PID 파일 관리 ────────────────────────────────────────────────────────────

function savePid(pid) {
    fs.writeFileSync(PID_FILE, String(pid));
}

function readPid() {
    try { return parseInt(fs.readFileSync(PID_FILE, 'utf8').trim(), 10); } catch (_) { return null; }
}

function clearPid() {
    try { fs.unlinkSync(PID_FILE); } catch (_) {}
}

function isPidAlive(pid) {
    try { process.kill(pid, 0); return true; } catch (_) { return false; }
}

// ─── 서버 종료 ────────────────────────────────────────────────────────────────

function sleepSync(ms) {
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function killServer() {
    const pid = readPid();
    if (!pid) {
        log('[Bridge] No PID file → nothing to kill.');
        return;
    }
    if (!isPidAlive(pid)) {
        log(`[Bridge] PID ${pid} already dead.`);
        clearPid();
        return;
    }

    if (isWin) {
        log(`[Bridge] Killing server PID ${pid} (taskkill)...`);
        try { execSync(`taskkill /F /PID ${pid}`); } catch (_) {}
    } else {
        log(`[Bridge] Sending SIGTERM to server PID ${pid}...`);
        try { process.kill(pid, 'SIGTERM'); } catch (_) {}

        const deadline = Date.now() + 5000;
        while (isPidAlive(pid) && Date.now() < deadline) {
            sleepSync(200);
        }
        if (isPidAlive(pid)) {
            log(`[Bridge] SIGTERM ignored → sending SIGKILL to PID ${pid}`);
            try { process.kill(pid, 'SIGKILL'); } catch (_) {}
        }
    }

    log(`[Bridge] Server PID ${pid} terminated.`);
    clearPid();
}

// ─── 서버 상태 확인 ──────────────────────────────────────────────────────────

function isServerRunning(url) {
    return new Promise((resolve) => {
        const parsed = new URL(url);
        const req = http.get({
            hostname: parsed.hostname,
            port: parsed.port || 80,
            path: '/status',
            timeout: 1500
        }, (res) => {
            res.resume();
            resolve(res.statusCode < 500);
        });
        req.on('error', () => resolve(false));
        req.on('timeout', () => { req.destroy(); resolve(false); });
    });
}

function waitForServer(url, retries = 30, intervalMs = 1000) {
    return new Promise((resolve, reject) => {
        let attempts = 0;
        const check = () => {
            isServerRunning(url).then((running) => {
                if (running) return resolve();
                if (++attempts >= retries) return reject(new Error('Server did not start in time'));
                setTimeout(check, intervalMs);
            });
        };
        check();
    });
}

// ─── 서버 시작 ────────────────────────────────────────────────────────────────

async function ensureServer() {
    // 이미 실행 중이면 그냥 연결
    if (await isServerRunning(SSE_URL)) {
        log('[Bridge] Server already running. Connecting...');
        return;
    }

    // PID 파일이 있지만 프로세스가 죽어있으면 정리
    const stale = readPid();
    if (stale && !isPidAlive(stale)) {
        log(`[Bridge] Stale PID ${stale} found → clearing.`);
        clearPid();
    }

    // lock 파일로 중복 시작 방지 (다른 브릿지가 이미 시작 중일 수 있음)
    if (fs.existsSync(LOCK_FILE)) {
        const lockPid = parseInt(fs.readFileSync(LOCK_FILE, 'utf8').trim(), 10);
        // lock을 쥔 브릿지가 살아있을 때만 기다림
        if (lockPid && isPidAlive(lockPid)) {
            log(`[Bridge] Another bridge (PID:${lockPid}) is starting the server. Waiting...`);
            try {
                await waitForServer(SSE_URL);
                log('[Bridge] Server is ready (started by another bridge).');
                return;
            } catch (_) {
                // 기다렸는데도 안 뜨면 lock 파일 무시하고 직접 시작
                log('[Bridge] Wait timeout — lock holder may have died. Taking over...');
            }
        } else {
            log(`[Bridge] Stale lock file (PID:${lockPid} dead) → clearing.`);
        }
        try { fs.unlinkSync(LOCK_FILE); } catch (_) {}
    }

    // 이 브릿지가 서버 시작을 담당
    fs.writeFileSync(LOCK_FILE, String(process.pid));
    try {
        log(`[Bridge] Starting server: ${JAR_PATH}`);
        const proc = spawn('java', ['-jar', JAR_PATH], {
            detached: false,
            stdio: ['ignore', 'pipe', 'pipe']
        });
        proc.stdout.on('data', (d) => console.error(`[Server] ${d.toString().trim()}`));
        proc.stderr.on('data', (d) => console.error(`[Server] ${d.toString().trim()}`));
        proc.on('exit', (code) => {
            log(`[Bridge] Server process exited (code ${code})`);
            clearPid();
        });

        savePid(proc.pid);
        log(`[Bridge] Server started (PID: ${proc.pid}). Waiting for ready...`);

        await waitForServer(SSE_URL);
        log('[Bridge] Server is ready.');
    } finally {
        try { fs.unlinkSync(LOCK_FILE); } catch (_) {}
    }
}

// ─── 종료 처리 ────────────────────────────────────────────────────────────────

let shutdownCalled = false;

function shutdown(reason) {
    if (shutdownCalled) return;
    shutdownCalled = true;
    log(`[Bridge] Shutdown triggered (${reason}) → killing server...`);
    killServer();
    log('[Bridge] Shutdown complete.');
}

process.on('exit',   ()      => shutdown('exit'));
process.on('SIGINT', ()      => { shutdown('SIGINT');  process.exit(0); });
process.on('SIGTERM',()      => { shutdown('SIGTERM'); process.exit(0); });

// Claude Desktop이 stdin을 닫을 때 (가장 흔한 종료 경로)
process.stdin.on('end',  () => { log('[Bridge] stdin closed.'); shutdown('stdin-end'); process.exit(0); });
process.stdin.on('close',() => { log('[Bridge] stdin closed.'); shutdown('stdin-close'); process.exit(0); });

// ─── MCP 브릿지 ──────────────────────────────────────────────────────────────

let sessionId = null;
let endpoint  = null;
const pendingMessages = [];

function postMessage(line) {
    const url = new URL(endpoint, SSE_URL);
    const req = http.request({
        hostname: url.hostname,
        port: url.port,
        path: url.pathname + url.search,
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(line) }
    }, (res) => { res.on('data', () => {}); });
    req.on('error', (err) => console.error(`[Bridge] POST Error: ${err.message}`));
    req.write(line);
    req.end();
}

function connect() {
    const req = http.get(SSE_URL, (res) => {
        let buffer = '';
        res.on('data', (chunk) => {
            buffer += chunk.toString();
            const lines = buffer.split('\n');
            buffer = lines.pop();
            for (const line of lines) {
                if (line.startsWith('data:')) {
                    const data = line.slice(5).trim();
                    if (data.startsWith('/mcp/messages')) {
                        endpoint  = data;
                        sessionId = new URLSearchParams(data.split('?')[1]).get('sessionId');
                        console.error(`[Bridge] Connected. Session: ${sessionId}`);
                        if (pendingMessages.length > 0) {
                            console.error(`[Bridge] Flushing ${pendingMessages.length} buffered message(s)`);
                            pendingMessages.forEach(msg => postMessage(msg));
                            pendingMessages.length = 0;
                        }
                    } else {
                        let msg = data;
                        try {
                            const parsed = JSON.parse(data);
                            if (parsed?.result?.protocolVersion) {
                                parsed.result.protocolVersion = '2025-11-25';
                                msg = JSON.stringify(parsed);
                            }
                        } catch (_) {}
                        process.stdout.write(msg + '\n');
                    }
                }
            }
        });
        res.on('end', () => {
            console.error('[Bridge] SSE connection closed. Reconnecting...');
            setTimeout(connect, 1000);
        });
    });
    req.on('error', (err) => {
        console.error(`[Bridge] SSE Error: ${err.message}`);
        setTimeout(connect, 2000);
    });
}

process.stdin.on('data', (chunk) => {
    stdinBuffer += chunk.toString();
    const lines = stdinBuffer.split('\n');
    stdinBuffer = lines.pop();
    for (const line of lines) {
        if (!line.trim()) continue;
        if (!endpoint) { pendingMessages.push(line); continue; }
        postMessage(line);
    }
});
let stdinBuffer = '';

// ─── 시작 ─────────────────────────────────────────────────────────────────────

log(`[Bridge] ===== Bridge started =====`);
ensureServer().then(() => connect()).catch((e) => {
    log(`[Bridge] Fatal: ${e.message}`);
    process.exit(1);
});
