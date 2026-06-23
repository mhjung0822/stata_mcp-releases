# Stata MCP Java — Releases

Stata와 Claude(Desktop / Code)를 MCP(Model Context Protocol)로 연결하는 도구의 **공개 배포 저장소**입니다. 소스 코드는 비공개이며, 이 저장소는 빌드된 배포 파일과 사용자 문서만 제공합니다.

## 다운로드

> **Stata 측 빠른 설치** (권장): Stata 에서 한 줄 — `net install stata-mcp, from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") replace`
>
> **Claude 측 (Desktop / claude.ai / Code)**: [`claude.zip` (latest)](../../releases/tag/claude-latest) 다운로드 → 압축 풀고 `.dxt` / 스킬 등록.

| 파일 | 설명 |
|---|---|
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, Streamable HTTP, 포트 8080) — **Stata PERSONAL ado 에 배치** |
| `stata-mcp.dxt` | **Claude Desktop 설치 wrapper** (~1 KB) — `mcp-remote` 로 stdio↔HTTP 자동 등록 (서버 jar 별도 설치) |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `mcp_connect.ado` | Stata 드론 연결 명령어 |
| `mcp_server.ado` | MCP 서버 jar 기동/종료/상태 명령 (`mcp_server` / `, status` / `, stop`) — adopath 에서 jar 탐지 |
| `llm.ado` | Stata push 명령어 (`llm push > cmd`) |
| `graph_meta_put.ado` | 그래프 메타정보 추출/저장 명령어 |
| `mcp_load_serset.ado` | Stata serset 데이터 로드 헬퍼 |
| `mcp.dlg` / `mcp.ado` / `mcp_set.ado` / `mcp_menu.ado` | Stata 제어판 GUI (`db mcp`) + 설정 메뉴 (`mcp_set`) + User 메뉴 등록 (`mcp_menu, install`) |
| `stata_mcp_instructions.md` | Claude 기본 지침 (간결, ~450 토큰) |
| `stata_mcp_instructions_example_full.md` | Claude 지침 예시 (상세, ~1500 토큰) — 대안 |

> Claude Desktop 사용자는 Node 20+ 필요 (`.dxt` 가 `npx mcp-remote` 호출). Claude Code / Cursor 는 Streamable HTTP 직접 지원이라 Node 불필요.

## 가이드

- [INSTALL.md](INSTALL.md) — 설치 가이드 (다운로드 → 설정 → MCP 등록 → 스킬 등록)
- [USAGE.md](USAGE.md) — 사용 가이드 (시작 순서, Claude Desktop / Claude Code 사용법, 문제 해결)
- [release/claude/](release/claude) — Claude 측 다운로드 자산: `stata-mcp.dxt` (Desktop) + `cowork-skills/` (슬래시 명령 스킬 7종 — `/stata-setup`, `/stata-exec`, `/stata-pull`, `/stata-data-fullcontext`, `/stata-graph-get`, `/stata-graph-export`, `/stata-instruction`). 등록 방법은 INSTALL.md 7장 참고
- **한 번에 받기**: [`claude.zip` (latest)](../../releases/tag/claude-latest) — `release/claude/` 전체를 zip 으로 (자동 빌드)

## 사전 요구 사항

| 항목 | 버전 |
|---|---|
| Java | 17 이상 — [Oracle JDK 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) |
| Node.js | 18 이상 — [nodejs.org](https://nodejs.org/) |
| Stata | 17 이상 (19 권장) |
| Claude Desktop 또는 Claude Code | 최신 버전 |

## 라이선스

Copyright (c) 2024 mhjung0822.
