# 설치 가이드

설치 후 사용법은 [USAGE.md](USAGE.md) 참고.

---

## 1. 사전 요구 사항

| 항목 | 버전 |
|------|------|
| Java | 17 이상 — [Oracle JDK 17 다운로드](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) |
| Stata | 17 이상 (19 권장) |
| Claude Desktop / Claude Code / Cursor | 최신 (Claude Code/Cursor 는 Streamable HTTP MCP transport native 지원) |
| Node.js | v20+ — [Node.js 다운로드](https://nodejs.org/) (Claude Desktop 에서 `.dxt` 사용 시 필요 — `mcp-remote` 가 stdio↔HTTP 변환) |

> Claude Code / Cursor 는 Streamable HTTP 직접 지원이므로 Node 불필요. Claude Desktop 은 stdio MCP transport 만 지원하므로 `mcp-remote` 경유 (`.dxt` 안 manifest 가 `npx mcp-remote` 호출).

---

## 2. 배포 파일 목록

다운로드: <https://github.com/mhjung0822/stata_mcp-releases/releases> 의 최신 버전.

| 파일 | 설명 |
|------|------|
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, Streamable HTTP transport, 포트 8080) — **Cursor / Claude Code 사용자가 standalone 으로 사용**. Claude Desktop 만 쓰면 `.dxt` 안에 같이 번들돼 있어 별도 다운로드 불필요 |
| `stata-mcp.dxt` | **Claude Desktop 설치 wrapper + 서버 jar 번들** — `mcp-remote` 로 stdio↔HTTP 자동 등록 |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `mcp_connect.ado` | Stata 드론 연결 명령어 (서버 jar 도 자동 spawn 가능 — 본인 환경에 맞춰 수정) |
| `mcp_find_server.ado` | `.dxt` 안에 번들된 서버 jar 경로 탐지 (Claude Extensions dir 검색) — `mcp_connect` 에서 호출 가능 |
| `llm.ado` | Stata push 명령어 (`llm push [, r e keep clear] [> cmd]`) |
| `graph_meta_put.ado` | 그래프 메타정보 추출/저장 명령어 |
| `mcp_load_serset.ado` | Stata serset 데이터 로드 헬퍼 |
| `stata_mcp_instructions.md` | Claude 기본 지침 (간결) |
| `stata_mcp_instructions_example_full.md` | Claude 지침 예시 (상세) — 대안 |

> `stata_mcp.properties` 는 동봉되지 않습니다 — 첫 서버 기동 시 jar 옆에 자동 생성됩니다 (3장 참고).

---

## 3. 서버 jar 배치

사용 환경에 따라 두 경로:

### 3-A. Claude Desktop 사용자 → 별도 배치 불필요

`.dxt` 안에 `stata-mcp-server.jar` 가 같이 번들돼 있습니다. 6장 ([클라이언트 등록](#6-클라이언트-등록)) 에서 `.dxt` 설치 시 자동으로 Claude Extensions 디렉토리에 풀려, Stata 의 `mcp_find_server` 가 그 위치에서 jar 를 찾아 띄웁니다.

별도 폴더 배치 / properties 파일 / 지침 파일 관리는 **3-B** 의 절차를 따르거나, jar 가 풀린 위치를 직접 확인 (`mcp_find_server` 호출 결과 참고) 후 그 옆에 작성.

### 3-B. Cursor / Claude Code 사용자 → jar 수동 배치

`stata-mcp-server.jar` 를 사용자 선택 폴더에 배치.

#### 권장 위치

**macOS**:
```
~/Documents/StataMCP/
└── stata-mcp-server.jar
```

**Windows**:
```
C:\Users\YOUR_NAME\Documents\StataMCP\
└── stata-mcp-server.jar
```

#### stata_mcp.properties (자동 생성)

서버 첫 기동 시 jar 옆에 다음 내용으로 **자동 생성**됩니다:

```properties
# Stata MCP 환경 설정 (자동 생성)
BRIDGE_PORT="8080"
DRONE_PORT="8001"
```

##### 포트 변경 (선택)

서버 기동 전에 jar 옆에 `stata_mcp.properties` 파일을 직접 만들어 원하는 값을 넣어두면 자동 생성 대신 그 값이 사용됩니다.

```properties
BRIDGE_PORT="8090"
DRONE_PORT="9001"
```

#### Claude 지침 파일 (선택)

분석 룰을 Claude 에게 적용하고 싶으면 jar 옆에 `stata_mcp_instructions.md` 배치 (release 의 동명 파일 복사):

```
~/Documents/StataMCP/
├── stata-mcp-server.jar
└── stata_mcp_instructions.md         ← (선택) release 에서 복사 또는 직접 작성
```

`stata_mcp_instructions.md` (기본, 간결) 또는 `stata_mcp_instructions_example_full.md` (상세) 내용을 시작점으로 사용.

---

## 4. Stata ado 폴더 (드론)

Stata 에서 PERSONAL 경로 확인:

```stata
adopath
```

**macOS (보통)**: `~/Documents/Stata/ado/personal/`
**Windows (보통)**: `%USERPROFILE%\ado\personal\` 또는 `%USERPROFILE%\Documents\Stata\ado\personal\`

이 경로에 **여섯 파일** 복사:

```
<PERSONAL>/
├── stata-drone.jar
├── mcp_connect.ado
├── mcp_find_server.ado            ← .dxt 안 jar 경로 탐지 헬퍼
├── llm.ado
├── graph_meta_put.ado
└── mcp_load_serset.ado
```

---

## 5. 서버 기동

서버 jar 가 떠 있어야 클라이언트가 MCP 연결 가능. 두 가지 패턴:

### A. Stata 안에서 자동 기동 (권장)

`mcp_connect` 가 드론과 서버 jar 를 같이 spawn 하도록 설정해두면 Stata 작업 시작 시 한 번에 인프라 셋업.

```stata
mcp_connect
```

기본 배포본은 드론만 띄움. 서버 jar 도 같이 띄우려면 본인 환경의 `mcp_connect.ado` 에 다음 패턴 추가:

```stata
* .dxt 안 번들된 jar 경로 탐지
mcp_find_server
local jar = r(path)

* 서버 spawn (detached, OS 별 분기)
if "`c(os)'" == "MacOSX" {
    shell java -jar "`jar'" >/dev/null 2>&1 &
}
else if "`c(os)'" == "Windows" {
    winexec java -jar "`jar'"
}
```

> `mcp_find_server` 는 `.dxt` 설치를 전제 — Cursor / Claude Code 만 쓰는 사용자는 3-B 의 standalone jar 경로를 직접 사용 (`local jar "~/Documents/StataMCP/stata-mcp-server.jar"`).

### B. 사용자가 별도 터미널에서 수동 기동

```bash
java -jar ~/Documents/StataMCP/stata-mcp-server.jar
```

터미널 창을 열어둔 동안 백그라운드 유지. 또는 `nohup` / `screen` / `launchd` 같은 데몬 도구로 백그라운드화.

### 기동 확인

```bash
curl http://127.0.0.1:8080/status
# {"bridge":"running"}
```

---

## 6. 클라이언트 등록

서버는 **단일 Streamable HTTP 엔드포인트** `http://127.0.0.1:8080/mcp` 를 제공합니다.

### Claude Desktop — `.dxt` (권장)

1. Releases 페이지에서 `stata-mcp.dxt` 다운로드
2. 파일 더블클릭 → Claude Desktop 이 설치 다이얼로그 표시 → 승인
   - 또는: Settings → Extensions → **Install from file** → `stata-mcp.dxt` 선택
3. Claude Desktop **재시작**

설치 시 자동 처리되는 항목:
- `claude_desktop_config.json` 의 MCP 서버 항목 자동 등록 — `npx mcp-remote http://127.0.0.1:8080/mcp` 호출하는 stdio wrapper
- 첫 기동 시 `mcp-remote` npm 패키지 자동 fetch (인터넷 필요)

> **사전 조건**: 시스템에 Node 20+ 가 깔려 있어야 합니다 (`npx` / `mcp-remote` 가 Node 20 의 `File` 글로벌 요구). 또한 서버 jar 가 8080 에서 동작 중이어야 합니다.

> **`.dxt` 가 직접 jar 를 띄우진 않습니다** — Claude Desktop 시작 전에 5장 절차로 jar 가 떠 있어야 도구 호출 가능.

### Claude Code (CLI) — 직접 연결

```bash
claude mcp add -s user --transport http StataMCP http://127.0.0.1:8080/mcp
```

확인:
```bash
claude mcp list
# StataMCP   ✓ Connected
```

### Cursor

`~/.cursor/mcp.json` (또는 워크스페이스 `.cursor/mcp.json`):
```json
{
  "mcpServers": {
    "StataMCP": {
      "url": "http://127.0.0.1:8080/mcp"
    }
  }
}
```

### Push 알람

서버는 `experimental.claude/channel` capability 를 advertise — Stata 에서 `llm push` 실행 시 모든 활성 MCP 세션의 Streamable HTTP standby SSE stream 으로 즉시 알림 (`notifications/claude/channel`) 이 전달됩니다. 별도 채널 서버 등록 불필요.

**Claude Code 에서 채널 알림을 사용자 화면에 자동 표시받으려면** 다음 플래그로 실행:
```bash
claude --dangerously-load-development-channels server:StataMCP
```
- `server:` 뒤는 `claude mcp add` 로 등록한 이름 (`StataMCP`)
- Research preview 기능이라 `dangerously` 접두사 필수
- alias 로 간소화 가능:
  ```bash
  # ~/.zshrc 또는 ~/.bashrc
  alias statamcp="claude --dangerously-load-development-channels server:StataMCP"
  ```
- 플래그 없이 실행하면 자동 알림 UI 표시는 안 되지만 `getPushResults` tool 호출로 큐 본문 fetch 는 정상 동작.

---

## 7. 경로 구조 요약

설치 후 전체 구조:

```
<Claude Extensions dir>/local.dxt.mhjung0822.stata-mcp/   ← .dxt 설치 시 Claude Desktop 이 자동 관리
├── manifest.json                                          ← mcp-remote 호출 config
└── server/
    ├── stata-mcp-server.jar                               ← Desktop 사용자의 jar (mcp_find_server 가 탐지)
    ├── stata_mcp.properties                               ← 첫 기동 시 자동 생성 (포트만)
    └── server-logs/stata-mcp-server_<ts>.log              ← Spring Boot 시스템 로그 (자동 생성)

<서버 설치 폴더>/                          ← 3-B 경로 — Cursor/Code 사용자만 (예: ~/Documents/StataMCP/)
├── stata-mcp-server.jar
├── stata_mcp.properties
├── stata_mcp_instructions.md             ← (선택) Claude 지침 파일
└── server-logs/

<Stata PERSONAL ado>/                     ← Stata adopath 자동 인식
├── stata-drone.jar
├── mcp_connect.ado
├── mcp_find_server.ado
├── llm.ado
├── graph_meta_put.ado
└── mcp_load_serset.ado

<사용자 작업폴더 c(pwd)>/                  ← Stata 에서 cd 한 위치
└── g_yyyyMMddHHmm_xxxx.png               ← 그래프 (드론이 직접 export)
```

> Desktop 경로 (3-A) 사용 시 `stata_mcp.properties` 와 `server-logs/` 가 Claude Extensions 디렉토리 내부에 생성됩니다 (사용자 writable). `.dxt` 재설치/업데이트 시 이 파일들 보존 여부는 Claude Desktop 동작에 따라 다름 — 영구 보관 필요한 설정은 3-B 의 별도 폴더 사용 권장.

> 저장 파일 (`save`/`export` 등) 은 사용자가 Stata 에서 지정한 경로 그대로 — 서버/드론이 이동하지 않음.

---

## 8. (선택) 코워크 슬래시 명령 스킬 등록

> ⚠️ **사전 조건**: 스킬은 MCP 도구를 호출하므로 **Claude Desktop 코워크 모드가 켜져 있어야** 동작합니다.

`skill-bundles/` 의 6개 zip 을 등록하면 다음 슬래시 명령이 활성화됩니다:

| 명령 | 동작 |
|---|---|
| `/stata-setup` | 현재 Stata 작업폴더 + 데이터셋 상태 점검 |
| `/stata-exec <cmd>` | Stata 명령 직접 실행 |
| `/stata-pull` | Stata GUI 에서 push 한 결과 가져오기 |
| `/stata-data-fullcontext` | 현재 데이터셋 전체 컨텍스트 요약 |
| `/stata-graph-get` | 현재 그래프 spec 조회 |
| `/stata-instruction` | 현재 로드된 분석 지침 (`stata_mcp_instructions.md`) 조회 |

### 8-A. Claude Desktop / claude.ai 웹

claude.ai → **Settings → Customize → Skills** 에서 [skill-bundles/](skill-bundles) 의 6개 zip 을 하나씩 업로드. 로그인 같으면 Claude Desktop 에도 자동 반영.

### 8-B. Claude Code

6개 zip 을 받아 각각 `~/.claude/skills/` 에 압축 해제:

```bash
mkdir -p ~/.claude/skills
for z in skill-bundles/*.zip; do
  unzip -o "$z" -d ~/.claude/skills/
done
```

압축 해제 후 `~/.claude/skills/<skill-name>/SKILL.md` 구조가 자동 인식됨.

> **주의**: `/stata-setup`, `/stata-exec` 등은 자연어가 아닌 **명시적 슬래시 호출에만 응답**. 즉 "Stata 명령 실행해줘" 가 아니라 `/stata-exec sysuse auto` 처럼 호출해야 함.

---

## 9. 다음 단계

설치가 끝났으면 [USAGE.md](USAGE.md) 에서 시작 순서·문제 해결을 확인하세요.
