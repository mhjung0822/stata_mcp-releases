# Stata MCP Java — Releases

Stata와 Claude를 MCP(Model Context Protocol)로 연결하는 도구의 **공개 배포 저장소**입니다. 주 사용 환경은 **Claude Desktop (채팅·코워크)** 이며 Claude Code / Cursor 도 지원합니다. 소스 코드는 비공개이며, 이 저장소는 빌드된 배포 파일과 사용자 문서만 제공합니다.

## 다운로드

**Stata 측** — Stata 에서 한 줄 (PERSONAL ado 에 자동 설치):

```stata
net install stata-mcp, from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") replace
```

> 설치 후 Stata 에서 **`mcp_setup`** 실행 — 도움말 DB 다운로드 + 메뉴 등록 ([INSTALL.md](INSTALL.md) 2장).

**Claude Desktop / 코워크** — zip 다운로드 후 업로드:

- **Stata MCP & 스킬 등록** *(필수)*: **Mac/Linux** [`stata-mcp-plugin.zip`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-plugin.zip) · **Windows** [`stata-mcp-plugin-win.zip`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-plugin-win.zip) → **Customize** → **Personal plugins → Upload plugin**
- **Stata MCP 작업 지침 스킬 등록** *(선택)*: [`stata-instruction.zip`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-instruction.zip) → **Customize** → **Skills → Upload**
- **패널 병합 절차 스킬 등록** *(선택)*: [`stata-panel-merge.zip`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-panel-merge.zip) → **Customize** → **Skills → Upload**

> Claude Code / Cursor 설치는 [INSTALL.md](INSTALL.md) 4장 참고.

| 파일 | 설명 |
|---|---|
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, Streamable HTTP, 포트 8080) — **Stata PERSONAL ado 에 배치** |
| `stata-mcp-plugin.zip` | **Claude Desktop 플러그인 (Mac/Linux)** — MCP 연결(`npx mcp-remote`→:8080) + 슬래시 명령 스킬(9종). Customize → Personal plugins → Upload |
| `stata-mcp-plugin-win.zip` | **Claude Desktop 플러그인 (Windows)** — 위와 동일하나 MCP 를 `cmd /c npx` 로 실행 (Windows 는 셸 래핑 필요). Windows 사용자는 이 zip 설치 |
| `stata-instruction.zip` | **작업 지침 스킬** (선택) — 출력형식·분석 규칙·선호. 사용자 편집용이라 플러그인과 분리 배포. Customize → Skills → Upload |
| `stata-panel-merge.zip` | **패널 병합 절차 스킬** (선택) — 웨이브(차수)별 .dta 를 stata-mcp 로 하나의 long 패널로 합치는 표준 절차. "패널 만들어줘" 등 자연어로 트리거. Customize → Skills → Upload |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `help_index_v2.json` / `help_nodes_v2.jsonl` | **도움말 DB** — Claude 가 Stata 명령 도움말을 필요한 부분만 빠르게 조회. `mcp_setup` 이 온디맨드 다운로드 (net install 번들 아님) |
| `stata_cmd_index.json` / `stata_help_corpus.jsonl` | 도움말 DB (보조) — 동일하게 `mcp_setup` 다운로드 |
| `mcp_connect.ado` | Stata 드론 연결 명령어 |
| `mcp_server.ado` | MCP 서버 jar 기동/종료/상태 명령 (`mcp_server` / `, status` / `, stop`) — adopath 에서 jar 탐지 |
| `llm.ado` | Stata push 명령어 (`llm push [, note(메모)] > cmd`) |
| `graph_meta_put.ado` | 그래프 메타정보 추출/저장 명령어 |
| `mcp_load_serset.ado` | Stata serset 데이터 로드 헬퍼 |
| `mcp.dlg` / `mcp.ado` / `mcp_setup.ado` / `mcp_menu.ado` | Stata 제어판 GUI (`db mcp`) + 설정·도움말DB 다운로드 (`mcp_setup`) + User 메뉴 등록 (`mcp_menu, install`) |
| `mcp_uninstall.ado` | 전체 제거 (`mcp_uninstall` 미리보기 → `, confirm`) |

> Claude Desktop 사용자는 Node 20+ 필요 (플러그인이 `npx mcp-remote` 호출). Claude Code / Cursor 는 Streamable HTTP 직접 지원이라 Node 불필요.

## 가이드

- [INSTALL.md](INSTALL.md) — 설치 가이드 (net install → 라이선스 → 서버 기동 → 클라이언트 등록)
- [USAGE.md](USAGE.md) — 사용 가이드 (시작 순서, Claude Desktop / Claude Code 사용법, 문제 해결)

## 사전 요구 사항

| 항목 | 버전 |
|---|---|
| Java | 17 이상 — [Oracle JDK 17](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) |
| Node.js | 20 이상 — [nodejs.org](https://nodejs.org/) (Claude Desktop 플러그인의 mcp-remote 용) |
| Stata | 17 이상 (19 권장) |
| Claude Desktop / Claude Code / Cursor | 최신 버전 — [Claude Desktop 다운로드](https://claude.ai/download) |

## 라이선스

Copyright (c) 2026 mhjung0822.
