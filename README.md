# Stata MCP Java — Releases

Stata와 Claude를 MCP(Model Context Protocol)로 연결하는 도구의 **공개 배포 저장소**입니다. 주 사용 환경은 **Claude Desktop (채팅·코워크)** 이며 Claude Code / Cursor 도 지원합니다. 소스 코드는 비공개이며, 이 저장소는 빌드된 배포 파일과 사용자 문서만 제공합니다.

## 다운로드

> **Stata 측 빠른 설치** (권장): Stata 에서 한 줄 — `net install stata-mcp, from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") replace`
>
> **Claude Desktop**: [`stata-mcp.dxt` 다운로드](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release/claude_dxt/stata-mcp.dxt) → 더블클릭으로 MCP 등록, 스킬은 플러그인 설치 (아래 가이드). Claude Code / Cursor 는 INSTALL.md 4장.

| 파일 | 설명 |
|---|---|
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, Streamable HTTP, 포트 8080) — **Stata PERSONAL ado 에 배치** |
| `stata-mcp.dxt` | **Claude Desktop 설치 wrapper** (~1 KB) — `mcp-remote` 로 stdio↔HTTP 자동 등록 (서버 jar 별도 설치) |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `help_index_v2.json` / `help_nodes_v2.jsonl` | **도움말 DB v2** (v0.12.0) — `getHelp(command, selector)` 가 온톨로지 노드 4,464개에서 필요한 slice 만 계단식 반환 (xtreg 통짜 ~14,000토큰 → 기본 425토큰) |
| `stata_cmd_index.json` / `stata_help_corpus.jsonl` | 도움말 DB v1 — 약어·프리픽스 해석 + v2 미설치 시 폴백 |
| `mcp_connect.ado` | Stata 드론 연결 명령어 |
| `mcp_server.ado` | MCP 서버 jar 기동/종료/상태 명령 (`mcp_server` / `, status` / `, stop`) — adopath 에서 jar 탐지 |
| `llm.ado` | Stata push 명령어 (`llm push [, note(메모)] > cmd`) |
| `graph_meta_put.ado` | 그래프 메타정보 추출/저장 명령어 |
| `mcp_load_serset.ado` | Stata serset 데이터 로드 헬퍼 |
| `mcp.dlg` / `mcp.ado` / `mcp_set.ado` / `mcp_menu.ado` | Stata 제어판 GUI (`db mcp`) + 설정 메뉴 (`mcp_set`) + User 메뉴 등록 (`mcp_menu, install`) |
| `mcp_uninstall.ado` | 전체 제거 (`mcp_uninstall` 미리보기 → `, confirm`) |

> Claude Desktop 사용자는 Node 20+ 필요 (`.dxt` 가 `npx mcp-remote` 호출). Claude Code / Cursor 는 Streamable HTTP 직접 지원이라 Node 불필요.

## 가이드

- [INSTALL.md](INSTALL.md) — 설치 가이드 (net install → 라이선스 → 서버 기동 → 클라이언트 등록)
- [USAGE.md](USAGE.md) — 사용 가이드 (시작 순서, Claude Desktop / Claude Code 사용법, 문제 해결)
- **슬래시 명령 스킬** (`/stata-exec`, `/stata-help`, `/stata-pull` 등 — 전체 목록·용법은 [USAGE.md](USAGE.md)) — **플러그인으로 한 번에 설치·업데이트** (권장):
  - **Claude Desktop**: 설정 → Plugins → 추가 → 마켓플레이스 추가 → 저장소에서 추가 → `mhjung0822/stata_mcp-releases` → `stata-mcp` 설치
  - **Claude Code (CLI)**:
    ```bash
    claude plugin marketplace add mhjung0822/stata_mcp-releases
    claude plugin install stata-mcp@stata-mcp-releases
    ```
- [release/claude_dxt/](release/claude_dxt) — `stata-mcp.dxt` (Claude Desktop MCP wrapper)

## 사전 요구 사항

| 항목 | 버전 |
|---|---|
| Java | 17 이상 — [Oracle JDK 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) |
| Node.js | 20 이상 — [nodejs.org](https://nodejs.org/) (Claude Desktop 의 `.dxt` 사용 시에만) |
| Stata | 17 이상 (19 권장) |
| Claude Desktop / Claude Code / Cursor | 최신 버전 |

## 라이선스

Copyright (c) 2026 mhjung0822.
