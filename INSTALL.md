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

이 repo 의 `release/` 폴더 자산. 사용자가 직접 다운로드할 일은 두 가지:

- **Stata 측**: 3장 의 `net install` 한 줄로 자동 다운로드 (수동 작업 없음)
- **Claude 측**: [`claude.zip` (claude-latest Release)](https://github.com/mhjung0822/stata_mcp-releases/releases/tag/claude-latest) 한 번 다운로드 → `.dxt` + 스킬 zip 6종

| 파일 | 설명 |
|------|------|
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, Streamable HTTP transport, 포트 8080) — **Stata PERSONAL ado 에 배치** (드론과 같은 곳) |
| `stata-mcp.dxt` | **Claude Desktop 설치 wrapper** (~1 KB) — `mcp-remote` 로 stdio↔HTTP 자동 등록 (서버 jar 별도 설치 필요) |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `mcp_connect.ado` | Stata 드론 연결 명령어 |
| `mcp_server.ado` | MCP 서버 jar 기동/종료/상태 (`mcp_server` / `, status` / `, stop`) — adopath 에서 jar 탐지 후 detached spawn |
| `mcp_edit_instructions.ado` | Claude 지침 파일 편집 (`mcp_edit_instructions` / `, init` / `, init full` / `, init force`) |
| `llm.ado` | Stata push 명령어 (`llm push [, r e keep clear] [> cmd]`) |
| `graph_meta_put.ado` | 그래프 메타정보 추출/저장 명령어 |
| `mcp_load_serset.ado` | Stata serset 데이터 로드 헬퍼 |
| `stata_mcp_instructions.md` | Claude 기본 지침 (간결) |
| `stata_mcp_instructions_example_full.md` | Claude 지침 예시 (상세) — 대안 |

> `stata_mcp.properties` 는 동봉되지 않습니다 — 첫 서버 기동 시 jar 옆에 자동 생성됩니다 (3장 참고).

---

## 3. Stata PERSONAL ado 설치 (서버 jar + 드론 + ado)

### 3-A. 권장 — `net install` (Stata 자동 설치)

Stata 에서 한 줄 실행:

```stata
net install stata-mcp, ///
    from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") ///
    replace
```

Stata 가 `stata.toc` + `stata-mcp.pkg` 매니페스트를 읽어 8개 파일 (서버 jar, 드론, ado 6종) 을 PERSONAL ado 에 자동 다운로드.

> 지침 파일 (`stata_mcp_instructions.md`) 은 이 패키지에 안 들어감 — 사용자가 직접 편집할 파일이라 `adoupdate` 시 덮어쓰기 방지. 받아서 시작하려면 `mcp_edit_instructions, init` (간결) 또는 `mcp_edit_instructions, init full` (상세).

#### 단계별 설치 (대안)

설치 전 패키지 내용을 미리 확인하고 싶으면:
```stata
net from "https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release"
net describe stata-mcp
net install stata-mcp, replace
```

#### 업데이트

```stata
adoupdate stata-mcp, update
```

> Stata `adopath` 가 PERSONAL 을 자동 인식 — `mcp_server` 가 `findfile` 로 jar 를 찾아 detached spawn.

> ⚠️ URL 끝에 `/` 붙이면 Stata 가 "is not a Stata download site" 에러 — 슬래시 없이 정확히 위 형태로.

### 3-B. 수동 복사 (대안)

PERSONAL 경로 확인:

```stata
adopath
```

**macOS (보통)**: `~/Documents/Stata/ado/personal/`
**Windows (보통)**: `%USERPROFILE%\ado\personal\` 또는 `%USERPROFILE%\Documents\Stata\ado\personal\`

이 경로에 **여덟 파일** 복사:

```
<PERSONAL>/
├── stata-mcp-server.jar           ← MCP 서버 jar
├── stata-drone.jar                ← Stata 내부 드론
├── mcp_connect.ado                ← 드론 + 서버 시작 명령
├── mcp_server.ado                 ← 서버 jar 기동/종료/상태 명령
├── mcp_edit_instructions.ado      ← 지침 파일 편집 (init/full/force)
├── llm.ado                        ← push 명령
├── graph_meta_put.ado             ← 그래프 메타정보
└── mcp_load_serset.ado            ← serset 로드 헬퍼
```

지침 파일 (`stata_mcp_instructions.md`) 은 동봉 안 함 — 첫 사용 시 `mcp_edit_instructions, init` 으로 release 에서 다운로드.

### stata_mcp.properties (자동 생성)

서버 첫 기동 시 jar 옆 (= PERSONAL ado) 에 다음 내용으로 **자동 생성**됩니다:

```properties
# Stata MCP 환경 설정 (자동 생성)
BRIDGE_PORT=8080
DRONE_PORT=8001
```

#### 포트 변경 (선택)

서버 기동 전에 jar 옆에 `stata_mcp.properties` 파일을 직접 만들어 원하는 값을 넣어두면 자동 생성 대신 그 값이 사용됩니다.

```properties
BRIDGE_PORT=8090
DRONE_PORT=9001
```

### 라이선스 키 (필수)

이 도구는 라이선스 키가 있어야 동작합니다. 키는 발급 문의 (mhjung0822@gmail.com) 로 받을 수 있고, 만료일이 포함된 한 줄 문자열입니다.

설치 후 Stata 에서:

```stata
mcp_edit_license          // jar 옆 stata_mcp.properties 를 에디터로 열어줌
```

열린 파일의 `LICENSE_KEY=""` 따옴표 사이에 받은 키를 붙여넣고 저장:

```properties
LICENSE_KEY="eyJ2IjoxLCJleHAiOiIyMDI2LTA3LTEwIn0.hHCZ...JFKCQ"
```

저장 후 `mcp_connect, reset` 으로 즉시 적용됩니다 (Stata 재시작 불필요).

- 키가 없거나 만료되면 드론이 시작되지 않고 서버도 종료됩니다. Stata Results 창에 사유와 함께 안내가 출력됩니다.
- 만료 7일 전부터 `mcp_connect` 시 남은 일수를 알려줍니다.
- 키 갱신 = 새 키를 같은 방법으로 교체.
- 검증에 인터넷 연결이 필요합니다 (오프라인은 72시간까지 허용).

### Claude 지침 파일 (선택)

분석 룰을 Claude 에게 적용하고 싶으면 jar 옆 (= PERSONAL ado) 에 `stata_mcp_instructions.md` 배치 (release 의 동명 파일 복사):

```
<PERSONAL>/
├── stata-mcp-server.jar
└── stata_mcp_instructions.md       ← (선택) release 에서 복사 또는 직접 작성
```

`stata_mcp_instructions.md` (기본, 간결) 또는 `stata_mcp_instructions_example_full.md` (상세) 내용을 시작점으로 사용.

---

## 4. 서버 기동

서버 jar 가 떠 있어야 클라이언트가 MCP 연결 가능.

### A. Stata 안에서 (권장)

```stata
mcp_server           // detached background spawn
mcp_connect          // 드론 시작
```

`mcp_server` 가 adopath 에서 `stata-mcp-server.jar` 찾아 detached 로 띄움 — Stata 세션 종료해도 서버 생존.

### 기타 명령

```stata
mcp_server, status    // GET /status — 응답 보면 떠있음
mcp_server, stop      // 서버 프로세스 종료
```

### B. 사용자가 별도 터미널에서 수동 기동 (대안)

```bash
java -jar "$(stata -e 'di r(fn)' ...)"   # 또는 PERSONAL ado 경로 직접
```

또는 `nohup` / `screen` / `launchd` 같은 데몬 도구로 백그라운드화.

### 기동 확인 (외부 셸)

```bash
curl http://127.0.0.1:8080/status
# {"bridge":"running"}
```

---

## 5. 클라이언트 등록

서버는 **단일 Streamable HTTP 엔드포인트** `http://127.0.0.1:8080/mcp` 를 제공합니다.

### Claude Desktop — `.dxt` (권장)

1. [`claude.zip` (claude-latest Release)](../../releases/tag/claude-latest) 다운로드 → 압축 풀면 `stata-mcp.dxt` 포함
2. 파일 더블클릭 → Claude Desktop 이 설치 다이얼로그 표시 → 승인
   - 또는: Settings → Extensions → **Install from file** → `stata-mcp.dxt` 선택
3. Claude Desktop **재시작**

설치 시 자동 처리되는 항목:
- `claude_desktop_config.json` 의 MCP 서버 항목 자동 등록 — `npx mcp-remote http://127.0.0.1:8080/mcp` 호출하는 stdio wrapper
- 첫 기동 시 `mcp-remote` npm 패키지 자동 fetch (인터넷 필요)

> **사전 조건**: 시스템에 Node 20+ 가 깔려 있어야 합니다 (`npx` / `mcp-remote` 가 Node 20 의 `File` 글로벌 요구). 또한 서버 jar 가 8080 에서 동작 중이어야 합니다.

> **`.dxt` 가 직접 jar 를 띄우진 않습니다** — Claude Desktop 시작 전에 4장 절차로 jar 가 떠 있어야 도구 호출 가능.

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

## 6. 경로 구조 요약

`net install` 은 파일을 `c(sysdir_plus)` 의 서브폴더로 분산 배치 — `.jar` 확장자는 `jar/`, `.ado` 는 파일명 첫 글자 폴더 (`m/`, `l/`, `g/`).

```
<PLUS = c(sysdir_plus)>/                  ← adopath 자동 인식
├── jar/                                  ← .jar 확장자 전용 (net install 컨벤션)
│   ├── stata-mcp-server.jar              ← MCP 서버 jar
│   ├── stata-drone.jar                   ← Stata 내부 드론
│   ├── stata_mcp.properties              ← 첫 서버 기동 시 자동 생성 (포트)
│   ├── stata_mcp_instructions.md         ← (선택) `mcp_edit_instructions, init` 으로 받음
│   └── server-logs/stata-mcp-server_<ts>.log  ← Spring Boot 로그 (자동)
├── m/
│   ├── mcp_connect.ado
│   ├── mcp_server.ado
│   ├── mcp_edit_instructions.ado
│   └── mcp_load_serset.ado
├── l/
│   └── llm.ado
└── g/
    └── graph_meta_put.ado

<Claude Extensions dir>/local.dxt.mhjung0822.stata-mcp/   ← Desktop — .dxt 설치 시 자동 관리
├── manifest.json                                          ← mcp-remote 호출 config
└── server/launcher.js                                     ← placeholder (실행 X)

<사용자 작업폴더 c(pwd)>/                  ← Stata 에서 cd 한 위치
└── g_yyyyMMddHHmm_xxxx.png               ← 그래프 (드론이 직접 export)
```

> 경로 직접 찾기 부담스러우면 `mcp_edit_instructions` 가 OS 기본 에디터로 지침 파일 열어줌 — 위치 신경 안 써도 됨.

> 저장 파일 (`save`/`export` 등) 은 사용자가 Stata 에서 지정한 경로 그대로 — 서버/드론이 이동하지 않음.

---

## 7. (선택) 코워크 슬래시 명령 스킬 등록

> ⚠️ **사전 조건**: 스킬은 MCP 도구를 호출하므로 **Claude Desktop 코워크 모드가 켜져 있어야** 동작합니다.

`release/claude/cowork-skills/` 의 6개 zip 을 등록하면 다음 슬래시 명령이 활성화됩니다:

> 📦 **한 번에 받기**: [`claude.zip` (latest)](../../releases/tag/claude-latest) — `release/claude/` 전체 (`.dxt` + 스킬 6종) 를 자동 빌드된 zip 으로.

| 명령 | 동작 |
|---|---|
| `/stata-setup` | 현재 Stata 작업폴더 + 데이터셋 상태 점검 |
| `/stata-exec <cmd>` | Stata 명령 직접 실행 |
| `/stata-pull` | Stata GUI 에서 push 한 결과 가져오기 |
| `/stata-data-fullcontext` | 현재 데이터셋 전체 컨텍스트 요약 |
| `/stata-graph-get` | 현재 그래프 spec 조회 |
| `/stata-instruction` | 현재 로드된 분석 지침 (`stata_mcp_instructions.md`) 조회 |

### 8-A. Claude Desktop / claude.ai 웹

claude.ai → **Settings → Customize → Skills** 에서 [release/claude/cowork-skills/](release/claude/cowork-skills) 의 6개 zip 을 하나씩 업로드. 로그인 같으면 Claude Desktop 에도 자동 반영.

### 8-B. Claude Code

6개 zip 을 받아 각각 `~/.claude/skills/` 에 압축 해제:

```bash
mkdir -p ~/.claude/skills
for z in release/claude/cowork-skills/*.zip; do
  unzip -o "$z" -d ~/.claude/skills/
done
```

압축 해제 후 `~/.claude/skills/<skill-name>/SKILL.md` 구조가 자동 인식됨.

> **주의**: `/stata-setup`, `/stata-exec` 등은 자연어가 아닌 **명시적 슬래시 호출에만 응답**. 즉 "Stata 명령 실행해줘" 가 아니라 `/stata-exec sysuse auto` 처럼 호출해야 함.

---

## 8. 다음 단계

설치가 끝났으면 [USAGE.md](USAGE.md) 에서 시작 순서·문제 해결을 확인하세요.
