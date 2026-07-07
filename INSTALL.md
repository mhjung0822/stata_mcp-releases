# 설치 가이드

설치는 4단계입니다: **① Stata 측 설치 → ② 라이선스 → ③ 서버 기동 → ④ Claude 등록 (플러그인 = MCP+스킬)**.
주 사용 환경은 **Claude Desktop (채팅·코워크)** 입니다 — Claude Code / Cursor 도 동일 서버에 연결됩니다.
배포 파일 목록은 [README.md](README.md), 설치 후 사용법·문제 해결은 [USAGE.md](USAGE.md) 참고.

---

## 1. 사전 요구 사항

| 항목 | 버전 |
|------|------|
| Java | 17 이상 — [Oracle JDK 17 다운로드](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) |
| Stata | 17 이상 (19 권장) |
| Claude Desktop / Claude Code / Cursor | 최신 |
| Node.js | v20+ — Claude Desktop/코워크 만 필요 (플러그인의 `mcp-remote` 가 stdio↔HTTP 변환) |

> Claude Code / Cursor 는 Streamable HTTP 직접 지원이라 Node 불필요.

---

## 2. Stata 측 설치

Stata 에서 한 줄:

```stata
net install stata-mcp, ///
    from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") ///
    replace
```

jar 2종 + 도움말 DB + ado/dlg 전부가 자동 다운로드됩니다. 업데이트는:

```stata
adoupdate stata-mcp, update
```

> ⚠️ URL 끝에 `/` 를 붙이면 "is not a Stata download site" 에러 — 슬래시 없이 위 형태 그대로.

### 라이선스 키 (필수)

키가 있어야 동작합니다 (발급 문의: mhjung0822@gmail.com). 설치 후 Stata 에서:

```stata
mcp_edit_license          // jar 옆 stata_mcp.properties 를 에디터로 열어줌
```

열린 파일의 `LICENSE_KEY=""` 따옴표 사이에 키를 붙여넣고 저장 → `mcp_connect, reset` 으로 즉시 적용 (Stata 재시작 불필요).

- 키가 없거나 만료되면 드론·서버가 기동하지 않고 Results 창에 사유가 출력됩니다
- 검증에 인터넷 연결 필요 (오프라인은 72시간까지 허용)

> 포트를 바꾸려면 (기본 8080/8001) jar 옆 `stata_mcp.properties` 의 `BRIDGE_PORT`/`DRONE_PORT` 수정 — 파일은 첫 기동 시 자동 생성.

---

## 3. 서버 기동

```stata
mcp_server           // MCP 서버 jar detached spawn (Stata 종료해도 생존)
mcp_connect          // 드론 시작
```

확인:

```bash
curl http://127.0.0.1:8080/status
# {"bridge":"running"}
```

> 명령 대신 GUI 제어판(`mcp` = `db mcp`)·메뉴 등록(`mcp_menu, install`)도 있습니다 — [USAGE.md](USAGE.md) 참고.

---

## 4. Claude 등록 (MCP 연결 + 슬래시 명령 스킬)

서버는 단일 Streamable HTTP 엔드포인트 `http://127.0.0.1:8080/mcp` 를 제공합니다.

### Claude Desktop / 코워크 (주 사용 환경) — 플러그인 zip

플러그인 하나에 **MCP 연결 + 슬래시 명령 스킬**이 들어 있습니다.

1. [`stata-mcp-plugin.zip` 다운로드](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-plugin.zip)
2. Claude Desktop → **Customize → Personal plugins → Upload plugin** → 받은 zip 선택
3. Claude Desktop (코워크면 코워크) 재시작

> 설치 시 `StataMCP` MCP 서버가 자동 등록됩니다 (`npx mcp-remote` → :8080). Node 20+ 필요. 3장의 서버 jar 가 떠 있어야 도구 호출이 됩니다. 업데이트는 새 zip 을 같은 화면에서 다시 Upload.

**출력 지침 스킬 (선택 — 편집해서 쓰는 항목)**: Stata 결과 제시 형식(코드블록·해석 정도·그래프 표기 등)을 취향대로 고쳐 쓰려면 `stata-instruction` 을 **별도 스킬**로 설치합니다 (플러그인과 분리 → 플러그인 업데이트해도 편집분 안 덮임).

1. [`stata-instruction.zip` 다운로드](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-instruction.zip)
2. Claude Desktop → **Customize → Skills → Upload** → 받은 zip 선택
3. 옵션에서 내용 편집 (또는 Claude 에게 수정 요청) — `/stata-setup` 이 설치돼 있으면 자동 로드, 없으면 기본 형식으로 동작

### Claude Code / Cursor

**MCP 등록** (HTTP 직접):

```bash
# Claude Code
claude mcp add -s user --transport http StataMCP http://127.0.0.1:8080/mcp
claude mcp list        # StataMCP ✓ Connected
```

Cursor 는 `~/.cursor/mcp.json` (또는 워크스페이스 `.cursor/mcp.json`):

```json
{ "mcpServers": { "StataMCP": { "url": "http://127.0.0.1:8080/mcp" } } }
```

**슬래시 명령 스킬**: 위 플러그인 zip (Customize → Personal plugins → Upload) 에 MCP 와 함께 들어 있습니다 — Code 도 Claude Desktop 플러그인 UI 를 공유하면 동일하게 설치됩니다. (Cursor 는 MCP 만 지원, 스킬 없음)

---

## 5. 다음 단계

[USAGE.md](USAGE.md) — 시작 순서, 제어판, push 알림, 도움말 조회, 문제 해결.
