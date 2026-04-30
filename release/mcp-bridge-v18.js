const http = require('http');
const { spawn, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

const isWin = process.platform === 'win32';

/**
 * Node.js v18 compatible MCP Streamable HTTP ↔ STDIO bridge.
 *
 * 목적: Claude Desktop (stdio MCP transport 만 지원) 에서 Streamable HTTP 서버에 붙기.
 *      Claude Code / Cursor 등 Streamable HTTP native 클라이언트는 이 bridge 불필요 — 직접 URL 등록.
 *
 * 동작:
 * - stdin 의 JSON-RPC 라인 → POST <url> (Mcp-Session-Id 헤더 자동 부착)
 * - GET <url>  long-lived SSE stream → 서버 능동 push (notifications/*) → stdout
 * - POST 응답이 text/event-stream 이면 SSE 스트림 파싱 후 stdout 으로 흘림
 *               application/json 이면 그대로 stdout
 * - initialize 응답 헤더의 Mcp-Session-Id 캡처해 이후 요청에 사용
 *
 * 서버 lifecycle:
 * - Java 서버는 detached 독립 프로세스 → bridge 종료 시에도 서버 생존
 * - bridge 재시작 시 살아있는 서버 재사용 (PID 파일로 추적)
 * - stdin 종료 감지로 Claude Desktop 종료 처리
 *
 * Zero-dep: Node v18 내장 http/fs/child_process/os/path 만 사용. npm install 불필요.
 */

const MCP_URL = process.argv[2];
if (!MCP_URL) {
    console.error("Usage: node mcp-bridge-v18.js <streamable-http-url>");
    console.error("Example: node mcp-bridge-v18.js http://127.0.0.1:8080/mcp");
    process.exit(1);
}

const PARSED_URL = new URL(MCP_URL);
const HOST = PARSED_URL.hostname;
const PORT = parseInt(PARSED_URL.port || '80', 10);
const MCP_PATH = PARSED_URL.pathname + PARSED_URL.search;
const STATUS_URL = `${PARSED_URL.protocol}//${PARSED_URL.host}/status`;

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

function savePid(pid)   { fs.writeFileSync(PID_FILE, String(pid)); }
function readPid()      { try { return parseInt(fs.readFileSync(PID_FILE, 'utf8').trim(), 10); } catch (_) { return null; } }
function clearPid()     { try { fs.unlinkSync(PID_FILE); } catch (_) {} }
function isPidAlive(p)  { try { process.kill(p, 0); return true; } catch (_) { return false; } }

// ─── 서버 종료 (현재 정책상 자동 호출 안 함 — detached 유지) ──────────────────

function sleepSync(ms) {
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
}

function killServer() {
    const pid = readPid();
    if (!pid) { log('[Bridge] No PID file → nothing to kill.'); return; }
    if (!isPidAlive(pid)) { log(`[Bridge] PID ${pid} already dead.`); clearPid(); return; }

    if (isWin) {
        log(`[Bridge] Killing server PID ${pid} (taskkill)...`);
        try { execSync(`taskkill /F /PID ${pid}`); } catch (_) {}
    } else {
        log(`[Bridge] Sending SIGTERM to server PID ${pid}...`);
        try { process.kill(pid, 'SIGTERM'); } catch (_) {}
        const deadline = Date.now() + 5000;
        while (isPidAlive(pid) && Date.now() < deadline) sleepSync(200);
        if (isPidAlive(pid)) {
            log(`[Bridge] SIGTERM ignored → SIGKILL`);
            try { process.kill(pid, 'SIGKILL'); } catch (_) {}
        }
    }
    log(`[Bridge] Server PID ${pid} terminated.`);
    clearPid();
}

// ─── 서버 상태 / 부팅 대기 ──────────────────────────────────────────────────

function isServerRunning() {
    return new Promise((resolve) => {
        const u = new URL(STATUS_URL);
        const req = http.get({
            hostname: u.hostname,
            port: u.port || 80,
            path: '/status',
            timeout: 1500
        }, (res) => { res.resume(); resolve(res.statusCode < 500); });
        req.on('error',   () => resolve(false));
        req.on('timeout', () => { req.destroy(); resolve(false); });
    });
}

function waitForServer(retries = 30, intervalMs = 1000) {
    return new Promise((resolve, reject) => {
        let attempts = 0;
        const check = () => {
            isServerRunning().then((running) => {
                if (running) return resolve();
                if (++attempts >= retries) return reject(new Error('Server did not start in time'));
                setTimeout(check, intervalMs);
            });
        };
        check();
    });
}

// ─── 서버 시작 (detached) ───────────────────────────────────────────────────

async function ensureServer() {
    if (await isServerRunning()) {
        log('[Bridge] Server already running. Connecting...');
        return;
    }

    const stale = readPid();
    if (stale && !isPidAlive(stale)) {
        log(`[Bridge] Stale PID ${stale} found → clearing.`);
        clearPid();
    }

    if (fs.existsSync(LOCK_FILE)) {
        const lockPid = parseInt(fs.readFileSync(LOCK_FILE, 'utf8').trim(), 10);
        if (lockPid && isPidAlive(lockPid)) {
            log(`[Bridge] Another bridge (PID:${lockPid}) is starting the server. Waiting...`);
            try {
                await waitForServer();
                log('[Bridge] Server is ready (started by another bridge).');
                return;
            } catch (_) {
                log('[Bridge] Wait timeout — taking over...');
            }
        } else {
            log(`[Bridge] Stale lock (PID:${lockPid} dead) → clearing.`);
        }
        try { fs.unlinkSync(LOCK_FILE); } catch (_) {}
    }

    fs.writeFileSync(LOCK_FILE, String(process.pid));
    try {
        log(`[Bridge] Starting server: ${JAR_PATH}`);
        const logFd = fs.openSync(LOG_FILE, 'a');
        const proc = spawn('java', ['-jar', JAR_PATH], {
            detached: true,
            stdio: ['ignore', logFd, logFd]
        });
        proc.unref();
        fs.closeSync(logFd);
        savePid(proc.pid);
        log(`[Bridge] Server started (PID: ${proc.pid}, detached). Waiting for ready...`);

        await waitForServer();
        log('[Bridge] Server is ready.');
    } finally {
        try { fs.unlinkSync(LOCK_FILE); } catch (_) {}
    }
}

// ─── 종료 처리 ───────────────────────────────────────────────────────────────

let shutdownCalled = false;
function shutdown(reason) {
    if (shutdownCalled) return;
    shutdownCalled = true;
    log(`[Bridge] Shutdown (${reason}) → bridge exiting, server kept alive.`);
    if (sessionId) {
        try {
            const req = http.request({
                hostname: HOST, port: PORT, path: MCP_PATH,
                method: 'DELETE',
                headers: { 'Mcp-Session-Id': sessionId },
                timeout: 500
            }, (res) => res.resume());
            req.on('error', () => {});
            req.end();
        } catch (_) {}
    }
}

process.on('exit',    ()  => shutdown('exit'));
process.on('SIGINT',  ()  => { shutdown('SIGINT');  process.exit(0); });
process.on('SIGTERM', ()  => { shutdown('SIGTERM'); process.exit(0); });

process.stdin.on('end',   () => { log('[Bridge] stdin end.');   shutdown('stdin-end');   process.exit(0); });
process.stdin.on('close', () => { log('[Bridge] stdin close.'); shutdown('stdin-close'); process.exit(0); });

// ─── Streamable HTTP 양방향 ──────────────────────────────────────────────────

let sessionId = null;
const protocolVersion = '2025-03-26';

function makeSseLineParser(onData) {
    let buf = '';
    let dataLines = [];
    return (chunk) => {
        buf += chunk.toString('utf8');
        let idx;
        while ((idx = buf.indexOf('\n')) >= 0) {
            const line = buf.slice(0, idx).replace(/\r$/, '');
            buf = buf.slice(idx + 1);
            if (line === '') {
                if (dataLines.length > 0) {
                    onData(dataLines.join('\n'));
                    dataLines = [];
                }
            } else if (line.startsWith('data:')) {
                dataLines.push(line.slice(5).replace(/^ /, ''));
            }
        }
    };
}

function emitToStdout(jsonStr) {
    if (!jsonStr) return;
    try {
        JSON.parse(jsonStr);
        process.stdout.write(jsonStr + '\n');
    } catch (e) {
        log(`[Bridge] Drop malformed message from server: ${e.message}`);
    }
}

function postMessage(line) {
    const isInit = (() => {
        try { return JSON.parse(line)?.method === 'initialize'; }
        catch (_) { return false; }
    })();

    const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/event-stream',
        'Content-Length': Buffer.byteLength(line)
    };
    if (sessionId) headers['Mcp-Session-Id'] = sessionId;

    const req = http.request({
        hostname: HOST, port: PORT, path: MCP_PATH,
        method: 'POST', headers
    }, (res) => {
        if (isInit && res.headers['mcp-session-id']) {
            sessionId = res.headers['mcp-session-id'];
            log(`[Bridge] Session: ${sessionId}`);
            openStandbyStream();
        }

        const ct = (res.headers['content-type'] || '').toLowerCase();
        if (res.statusCode === 202) { res.resume(); return; }
        if (ct.includes('text/event-stream')) {
            const parse = makeSseLineParser(emitToStdout);
            res.on('data', parse);
            res.on('end',  () => {});
        } else if (ct.includes('application/json')) {
            let body = '';
            res.setEncoding('utf8');
            res.on('data', (c) => body += c);
            res.on('end',  () => emitToStdout(body.trim()));
        } else {
            res.resume();
            log(`[Bridge] Unexpected POST response: ${res.statusCode} ${ct}`);
        }
    });
    req.on('error', (err) => log(`[Bridge] POST error: ${err.message}`));
    req.write(line);
    req.end();
}

let standbyReq = null;
function openStandbyStream() {
    if (!sessionId) return;
    if (standbyReq) return;

    const headers = {
        'Accept': 'text/event-stream',
        'Mcp-Session-Id': sessionId,
        'MCP-Protocol-Version': protocolVersion
    };
    const req = http.request({
        hostname: HOST, port: PORT, path: MCP_PATH,
        method: 'GET', headers
    }, (res) => {
        if (res.statusCode === 405) {
            log('[Bridge] Server does not support GET stream (405).');
            res.resume();
            standbyReq = null;
            return;
        }
        if (res.statusCode !== 200) {
            log(`[Bridge] Standby stream status ${res.statusCode}`);
            res.resume();
            standbyReq = null;
            setTimeout(openStandbyStream, 2000);
            return;
        }
        const parse = makeSseLineParser(emitToStdout);
        res.on('data', parse);
        res.on('end',  () => {
            log('[Bridge] Standby stream closed → reconnecting in 1s');
            standbyReq = null;
            setTimeout(openStandbyStream, 1000);
        });
        res.on('error', () => {
            standbyReq = null;
            setTimeout(openStandbyStream, 2000);
        });
    });
    req.on('error', (err) => {
        log(`[Bridge] Standby stream error: ${err.message}`);
        standbyReq = null;
        setTimeout(openStandbyStream, 2000);
    });
    req.end();
    standbyReq = req;
}

// ─── stdin 라인 파서 ─────────────────────────────────────────────────────────

let stdinBuffer = '';
process.stdin.on('data', (chunk) => {
    stdinBuffer += chunk.toString();
    const lines = stdinBuffer.split('\n');
    stdinBuffer = lines.pop();
    for (const line of lines) {
        const t = line.trim();
        if (!t) continue;
        postMessage(t);
    }
});

// ─── 시작 ─────────────────────────────────────────────────────────────────────

log(`[Bridge] ===== Bridge started → ${MCP_URL} =====`);
ensureServer().catch((e) => {
    log(`[Bridge] Fatal: ${e.message}`);
    process.exit(1);
});
