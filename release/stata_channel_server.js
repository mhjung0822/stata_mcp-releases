#!/usr/bin/env node
/**
 * Stata MCP Channel Server (Claude Code 전용)
 *
 * 역할:
 *   - Claude Code가 stdio로 직접 spawn
 *   - capabilities.experimental['claude/channel']: {} 선언
 *   - Spring Boot /api/events SSE 구독 → push-received 이벤트 수신
 *   - /api/push-data 에서 실제 내용 fetch → Claude Code 세션에 stdio MCP notification 주입
 *
 * 환경변수:
 *   STATA_MCP_SERVER (기본: http://127.0.0.1:8080)
 *
 * 의존성: 없음 (Node.js v18+ 내장 fetch + http 만 사용)
 */

'use strict';

const http = require('http');

const SERVER_URL = process.env.STATA_MCP_SERVER || 'http://127.0.0.1:8080';

// ── stdio 송수신 ────────────────────────────────────────────
function send(obj) {
    process.stdout.write(JSON.stringify(obj) + '\n');
}

function sendNotification(method, params) {
    send({ jsonrpc: '2.0', method, params });
}

function sendResult(id, result) {
    send({ jsonrpc: '2.0', id, result });
}

// ── 라인 단위 stdin 파싱 ───────────────────────────────────
let stdinBuffer = '';
process.stdin.on('data', (chunk) => {
    stdinBuffer += chunk.toString();
    let idx;
    while ((idx = stdinBuffer.indexOf('\n')) >= 0) {
        const line = stdinBuffer.slice(0, idx);
        stdinBuffer = stdinBuffer.slice(idx + 1);
        if (!line.trim()) continue;
        try {
            handle(JSON.parse(line));
        } catch (e) {
            process.stderr.write('[ChannelServer] parse error: ' + e.message + '\n');
        }
    }
});

process.stdin.on('end', () => process.exit(0));

// ── MCP 요청 처리 ──────────────────────────────────────────
function handle(msg) {
    if (msg.method === 'initialize') {
        sendResult(msg.id, {
            protocolVersion: '2024-11-05',
            capabilities: {
                experimental: { 'claude/channel': {} },
            },
            serverInfo: { name: 'stata_mcp_java_channel', version: '1.0.0' },
            instructions:
                'Stata GUI 에서 `llm push` 실행 시 이벤트가 <channel source="stata_mcp_java_channel"> 로 자동 전달됩니다. ' +
                '상세 결과가 필요하면 stata_mcp_java MCP 서버의 getPushResults 툴을 호출하세요.',
        });
    } else if (msg.method === 'notifications/initialized') {
        subscribeSSE();
    } else if (msg.method === 'tools/list') {
        sendResult(msg.id, { tools: [] });
    } else if (msg.method === 'prompts/list') {
        sendResult(msg.id, { prompts: [] });
    } else if (msg.method === 'resources/list') {
        sendResult(msg.id, { resources: [] });
    } else if (msg.method === 'ping') {
        sendResult(msg.id, {});
    } else if (msg.id !== undefined) {
        // 알 수 없는 요청은 빈 결과 반환
        sendResult(msg.id, {});
    }
}

// ── SSE 구독 ────────────────────────────────────────────────
function subscribeSSE() {
    const url = new URL('/api/events', SERVER_URL);
    const req = http.request({
        host: url.hostname,
        port: url.port || 80,
        path: url.pathname,
        method: 'GET',
        headers: { 'Accept': 'text/event-stream' },
    }, (res) => {
        if (res.statusCode !== 200) {
            process.stderr.write('[ChannelServer] SSE status ' + res.statusCode + ', retry in 3s\n');
            setTimeout(subscribeSSE, 3000);
            return;
        }
        let buf = '';
        let currentEvent = null;
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
            buf += chunk;
            let idx;
            while ((idx = buf.indexOf('\n')) >= 0) {
                const line = buf.slice(0, idx).replace(/\r$/, '');
                buf = buf.slice(idx + 1);
                if (line.startsWith('event:')) {
                    currentEvent = line.slice(6).trim();
                } else if (line.startsWith('data:')) {
                    onEvent(currentEvent, line.slice(5).trim());
                } else if (line === '') {
                    currentEvent = null;
                }
            }
        });
        res.on('end', () => {
            process.stderr.write('[ChannelServer] SSE closed, reconnect in 2s\n');
            setTimeout(subscribeSSE, 2000);
        });
        res.on('error', () => setTimeout(subscribeSSE, 2000));
    });
    req.on('error', (e) => {
        process.stderr.write('[ChannelServer] SSE connect error: ' + e.message + ', retry in 3s\n');
        setTimeout(subscribeSSE, 3000);
    });
    req.end();
}

async function onEvent(event, dataStr) {
    if (event !== 'push-received') return;
    try {
        const resp = await fetch(SERVER_URL + '/api/push-data');
        if (!resp.ok) return;
        const push = await resp.json();
        if (!push || push.status === 'empty') return;
        sendNotification('notifications/claude/channel', {
            content: summarize(push),
            meta: { source: 'stata' },
        });
    } catch (e) {
        process.stderr.write('[ChannelServer] push fetch failed: ' + e.message + '\n');
    }
}

function summarize(push) {
    const cmd = push.cmd || push.command || '(unknown)';
    const ts = push.timestamp || '';
    return `[Stata push] cmd=${cmd} | at=${ts}`;
}

process.stderr.write('[ChannelServer] started, server=' + SERVER_URL + '\n');
