# Stata MCP Java — Releases

Stata와 Claude(Desktop / Code)를 MCP(Model Context Protocol)로 연결하는 도구의 **공개 배포 저장소**입니다. 소스 코드는 비공개이며, 이 저장소는 빌드된 배포 파일과 사용자 문서만 제공합니다.

## 다운로드

[**Releases 페이지**](../../releases) 에서 최신 버전의 8개 파일을 받으세요.

| 파일 | 설명 |
|---|---|
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, 포트 8080) |
| `mcp-bridge-v18.js` | Claude Desktop 연동 브릿지 (Node.js, stdio↔SSE) |
| `stata_channel_server.js` | Claude Code 전용 채널 서버 (Node.js, stdio) |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `mcp_connect.ado` | Stata 드론 연결 명령어 |
| `llm.ado` | Stata push 명령어 (`llm push > cmd`) |
| `stata_mcp_instructions_example_compact.md` | Claude 지침 예시 (간결, ~450 토큰) |
| `stata_mcp_instructions_example_full.md` | Claude 지침 예시 (상세, ~1500 토큰) |

## 가이드

- [INSTALL.md](INSTALL.md) — 설치 가이드 (다운로드 → 설정 → MCP 등록)
- [USAGE.md](USAGE.md) — 사용 가이드 (시작 순서, Claude Desktop / Claude Code 사용법, 문제 해결)

## 변경 이력

각 [Release 페이지](../../releases) 본문에 해당 버전 변경 내역이 포함되어 있습니다.

## 사전 요구 사항

| 항목 | 버전 |
|---|---|
| Java | 17 이상 |
| Node.js | 18 이상 |
| Stata | 17 이상 (19 권장) |
| Claude Desktop 또는 Claude Code | 최신 버전 |

## 라이선스

Copyright (c) 2024 mhjung0822.
