# Stata MCP Java — Releases

> English: [README.en.md](README.en.md)

Stata와 Claude를 MCP(Model Context Protocol)로 연결하는 도구의 **공개 배포 저장소**입니다. 주 사용 환경은 **Claude Desktop 코워크**입니다. 소스 코드는 비공개이며, 이 저장소는 빌드된 배포 파일과 사용자 문서만 제공합니다.

## 다운로드

**Stata 측** — Stata 에서 한 줄 (PERSONAL ado 에 자동 설치):

```stata
net install stata-mcp, from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") replace
```

> 설치 후 Stata 에서 **`mcp_setup`** 실행 — 도움말 DB 다운로드 + 메뉴 등록 ([INSTALL.md](INSTALL.md) 2장).

**Claude Desktop 코워크** — 파일 2개:

- **MCP 연결** *(필수)*: OS 에 맞는 것 **하나만** — [`stata-mcp-mac.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-mac.mcpb) / [`stata-mcp-win.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-win.mcpb) → **설정 → 확장 프로그램 → 파일로 설치**
- **스킬 11종** *(권장)*: [`stata-skills-all.zip`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-skills-all.zip) → **압축 해제 후** 내부 스킬 zip 들을 **설정 → 스킬 → 업로드** (한 번 올리면 같은 계정 모든 기기에 적용)

> 코워크가 없는 환경(채팅)은 [INSTALL_CHAT.md](INSTALL_CHAT.md) 참고.

| 파일 | 설명 |
|---|---|
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, Streamable HTTP, 포트 8080) — **Stata PERSONAL ado 에 배치** |
| `stata-mcp-mac.mcpb` / `stata-mcp-win.mcpb` | **Claude Desktop 확장 프로그램** — 채팅·코워크 MCP 연결. 동봉 프록시를 Stata 내장 Java 로 실행 (Node·시스템 Java 불필요). OS 에 맞는 것 하나만 설치 (설정 → 확장 프로그램 → 파일로 설치) |
| `stata-skills-all.zip` | **스킬 11종 일괄** — 슬래시 명령 9종 + 작업 지침(stata-instruction, 편집 가능) + 패널 병합(stata-panel-merge). 압축 해제 후 내부 zip 을 설정 → 스킬 → 업로드. 개별 파일은 `claude-plugins/skill-zips/` |
| `stata-skills-all-en.zip` | **스킬 11종 영어판** — 위와 동일 구성의 영어 버전. 스킬 이름이 같으므로 계정당 한 언어팩만 설치. 개별 파일은 `claude-plugins/skill-zips-en/` |
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

## 가이드

- [INSTALL.md](INSTALL.md) — 설치 가이드 (net install → 라이선스 → 서버 기동 → 클라이언트 등록)
- [USAGE.md](USAGE.md) — 사용 가이드 (시작 순서, 사용법, 문제 해결)

## 사전 요구 사항

| 항목 | 버전 |
|---|---|
| Java | 별도 설치 불필요 — Stata 내장 Java 사용 (Stata 17 만 [JDK 17+](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) 필요) |
| Node.js | 불필요 — 설정 파일 수동 등록([INSTALL_CHAT.md](INSTALL_CHAT.md)) 시에만 |
| Stata | 17 이상 (19 권장) |
| Claude Desktop | 최신 버전 — [다운로드](https://claude.ai/download) |

## 라이선스

Copyright (c) 2026 mhjung0822.
