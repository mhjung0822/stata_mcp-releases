# 설치 가이드

설치 후 사용법은 [USAGE.md](USAGE.md) 참고.

---

## 1. 사전 요구 사항

| 항목 | 버전 |
|------|------|
| Java | 17 이상 |
| Stata | 17 이상 (19 권장) |
| Claude Desktop / Claude Code / Cursor | 최신 (Claude Code/Cursor 는 Streamable HTTP MCP transport native 지원) |
| Node.js | v18+ (Claude Desktop 사용 시에만 필요 — bridge 가 stdio↔HTTP 변환) |

> Claude Code / Cursor 는 Streamable HTTP 직접 지원이므로 Node 불필요. Claude Desktop 은 stdio MCP transport 만 지원하므로 zero-dep bridge (`mcp-bridge-v18.js`) 경유.

---

## 2. 배포 파일 목록

다운로드: <https://github.com/mhjung0822/stata_mcp-releases/releases> 의 최신 버전.

| 파일 | 설명 |
|------|------|
| `stata-mcp.dxt` | **Claude Desktop 원클릭 설치 번들** — MCP 서버 jar + stdio 브릿지 내장 |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `mcp_connect.ado` | Stata 드론 연결 명령어 |
| `llm.ado` | Stata push 명령어 (`llm push [, r e keep clear] [> cmd]`) |
| `stata_mcp_instructions.md` | Claude 기본 지침 (간결) — `.dxt` 에 동일 사본 번들 |
| `stata_mcp_instructions_example_full.md` | Claude 지침 예시 (상세) — 대안 |

> **Cursor / Claude Code 사용자**: `stata-mcp.dxt` 는 zip 컨테이너입니다. 압축 해제하면 `server/stata-mcp-server.jar` (서버) + `server/mcp-bridge-v18.js` (브릿지, Desktop 전용이라 Cursor/Code 에는 불필요) 가 들어 있습니다. 추출한 jar 를 수동 설치 절차(아래 3-B)에 사용하세요.

> `stata_mcp.properties`는 동봉되지 않습니다 — 첫 서버 기동 시 jar 옆에 자동 생성됩니다 (아래 3. 참고).

---

## 3. 서버 설치

사용 환경에 따라 두 경로 중 택일:

- **3-A. Claude Desktop 코워크 모드 중심 사용자** → `.dxt` 원클릭 설치
- **3-B. Claude Desktop 일반 채팅 / Cursor / Claude Code / 고급 사용자** → 수동 설치 (전역 MCP 등록)

---

### 3-A. Claude Desktop — `.dxt` 원클릭 설치 (코워크 모드 사용자)

> ⚠️ **`.dxt` 는 코워크 모드 전용**: `.dxt` 로 설치하면 MCP 도구가 Claude Desktop **코워크 모드 토글이 켜진 채팅에서만** 호출됩니다 (extension 이 코워크 sandbox 내부에 풀리는 것으로 추정). 일반 채팅에서도 도구를 쓰려면 3-B 수동 설치를 사용하세요. 사용 시작 순서는 [USAGE.md](USAGE.md) 1장 참고.

1. Releases 페이지에서 `stata-mcp.dxt` 다운로드
2. 파일 더블클릭 → Claude Desktop 이 설치 다이얼로그 표시 → 승인
   - 또는: Claude Desktop → Settings → Extensions → **Install from file** → `stata-mcp.dxt` 선택
3. Claude Desktop **재시작** (MCP 서버 등록 반영)

설치 완료 시 자동 처리되는 항목:
- `stata-mcp-server.jar` + `mcp-bridge-v18.js` 가 Claude Extensions 내부 디렉토리에 배치
- **기본 `stata_mcp_instructions.md` (compact 예시) 가 jar 옆에 같이 배치** → jar 가 첫 기동 시 자동 인식
- `claude_desktop_config.json` 의 MCP 서버 항목 자동 등록
- bridge 가 첫 호출 시 jar 를 detached 로 spawn

> **지침 커스터마이즈가 필요한 사용자**: `.dxt` 에 포함된 기본 지침은 [`stata_mcp_instructions.md`](release/stata_mcp_instructions.md) 의 사본입니다. extension 디렉토리가 격리되어 있어 안에서 직접 수정하면 .dxt 재설치/업데이트 시 덮어쓰입니다. 본인 룰을 적용하려면 (1) 3-B 수동 설치로 전환하거나, (2) Claude Desktop 의 프로젝트 지식 / Custom Instructions 기능을 추가로 사용하세요.

이후 [4. Stata ado 폴더](#4-stata-ado-폴더-드론) 로 진행하세요.

---

### 3-B. 수동 설치 (Cursor / Claude Code / 고급 사용자)

#### 3-B-1. jar 확보

`stata-mcp.dxt` 는 zip 컨테이너입니다. 확장자를 `.zip` 으로 바꾸거나 `unzip` 으로 풀면 `server/` 안에 두 파일이 나옵니다:

```bash
unzip stata-mcp.dxt -d stata-mcp-extracted
# stata-mcp-extracted/server/stata-mcp-server.jar
# stata-mcp-extracted/server/mcp-bridge-v18.js  (Claude Desktop 전용 — Cursor/Code 는 미사용)
```

#### 3-B-2. 권장 위치에 배치

**macOS**:
```
~/Documents/StataMCP/
├── stata-mcp-server.jar
└── mcp-bridge-v18.js          ← Claude Desktop 도 같이 쓰려면 함께 둠
```

**Windows**:
```
C:\Users\YOUR_NAME\Documents\StataMCP\
├── stata-mcp-server.jar
└── mcp-bridge-v18.js
```

> bridge 사용 시 jar 와 **반드시 같은 폴더** — bridge 가 옆 폴더의 jar 를 자동 spawn. Cursor/Claude Code 만 쓰면 bridge 생략 가능.

#### 3-B-3. stata_mcp.properties (자동 생성)

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

#### 3-B-4. Claude 지침 파일 (선택)

분석 룰을 Claude 에게 적용하고 싶으면 jar 옆에 `stata_mcp_instructions.md` 작성:

```
~/Documents/StataMCP/
├── stata-mcp-server.jar
└── stata_mcp_instructions.md         ← (선택) 사용자가 작성
```

`stata_mcp_instructions.md` (기본, 간결) 또는 `stata_mcp_instructions_example_full.md` (상세) 내용을 복사해 시작점으로 사용.

---

## 4. Stata ado 폴더 (드론)

Stata에서 PERSONAL 경로 확인:

```stata
adopath
```

**macOS (보통)**: `~/Documents/Stata/ado/personal/`
**Windows (보통)**: `%USERPROFILE%\ado\personal\` 또는 `%USERPROFILE%\Documents\Stata\ado\personal\`

이 경로에 **세 파일** 복사:

```
<PERSONAL>/
├── stata-drone.jar
├── mcp_connect.ado
└── llm.ado
```

---

## 5. 서버 기동

### Claude Desktop 사용자 (3-A `.dxt` 설치 경로)
서버를 별도로 띄울 필요 없음 — `.dxt` 에 포함된 bridge 가 Claude Desktop 시작 시 jar 를 자동 spawn (detached, Claude 종료해도 서버 생존).

### Claude Code / Cursor 사용자 (3-B 수동 설치 경로)
한 번 수동 기동:
```bash
java -jar ~/Documents/StataMCP/stata-mcp-server.jar
```
트레이 아이콘으로 떠서 종료 전까지 백그라운드 유지.

또는 Claude Desktop 도 같이 쓰면 Desktop 의 bridge 가 띄워둔 서버를 그냥 공유.

기동 확인:
```bash
curl http://127.0.0.1:8080/status
# {"bridge":"running"}
```

---

## 6. 클라이언트 등록

서버는 **단일 Streamable HTTP 엔드포인트** `http://127.0.0.1:8080/mcp` 를 제공합니다.

### Claude Code (CLI) — 직접 연결

```bash
claude mcp add -s user --transport http StataMCP http://127.0.0.1:8080/mcp
```

확인:
```bash
claude mcp list
# StataMCP   ✓ Connected
```

### Claude Desktop

#### 권장: `.dxt` 사용 (3-A 경로)

`stata-mcp.dxt` 를 설치하면 Claude Desktop 이 `claude_desktop_config.json` 의 MCP 항목을 **자동으로 등록**합니다. 별도 JSON 편집 불필요.

#### 수동 등록 (3-B 경로 — jar/bridge 직접 배치한 경우)

Claude Desktop 의 Custom Connectors UI 는 HTTPS 만 허용하므로, stdio MCP server 로 등록 (bridge 가 stdio↔Streamable HTTP 변환).

`~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) 또는
`%APPDATA%\Claude\claude_desktop_config.json` (Windows):

```json
{
  "mcpServers": {
    "StataMCP": {
      "command": "/usr/local/bin/node",
      "args": [
        "/Users/YOUR_NAME/Documents/StataMCP/mcp-bridge-v18.js",
        "http://127.0.0.1:8080/mcp"
      ]
    }
  }
}
```

- `command` 는 Node 절대경로 (Claude Desktop 이 PATH 를 못 찾으니 절대경로 권장)
  - macOS/Linux: `which node` 결과 사용
  - Windows: `(Get-Command node).Source` 결과 사용
- bridge 가 jar 를 detached 로 spawn — 사용자가 서버 별도 띄울 필요 없음
- 설정 후 Claude Desktop **재시작** 필수

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

### 3-A. `.dxt` 설치 경로 (Claude Desktop)

```
<Claude Extensions dir>/stata-mcp/        ← Claude Desktop 이 자동 관리 (사용자 직접 접근 비추천)
├── manifest.json
└── server/
    ├── stata-mcp-server.jar
    ├── mcp-bridge-v18.js
    └── stata_mcp_instructions.md         ← 기본 지침 (compact 예시 사본)

<Stata PERSONAL ado>/                     ← Stata adopath 자동 인식
├── stata-drone.jar
├── mcp_connect.ado
└── llm.ado

<사용자 작업폴더 c(pwd)>/                  ← Stata에서 cd 한 위치
└── g_yyyyMMddHHmm_xxxx.png               ← 그래프 (드론이 직접 export)
```

### 3-B. 수동 설치 경로 (Cursor / Claude Code / 고급 사용자)

```
<서버 설치 폴더>/                          ← 사용자 선택 (예: ~/Documents/StataMCP/)
├── stata-mcp-server.jar
├── mcp-bridge-v18.js                     ← Claude Desktop 도 같이 쓸 때만 필요
├── stata_mcp.properties                  ← 첫 기동 시 자동 생성 (포트만)
├── stata_mcp_instructions.md             ← Claude 지침 파일 (release/ 에서 복사하거나 직접 작성)
├── stata_mcp_instructions_example_full.md ← (참고) 상세 버전 대안
└── server-logs/stata-mcp-server_<ts>.log ← Spring Boot 시스템 로그 (자동 생성)

<Stata PERSONAL ado>/                     ← Stata adopath 자동 인식
├── stata-drone.jar
├── mcp_connect.ado
└── llm.ado

<사용자 작업폴더 c(pwd)>/                  ← Stata에서 cd 한 위치
└── g_yyyyMMddHHmm_xxxx.png               ← 그래프 (드론이 직접 export)
```

> 저장 파일(`save`/`export` 등)은 사용자가 Stata에서 지정한 경로 그대로 — 서버/드론이 이동하지 않음.

---

## 8. (선택) 코워크 슬래시 명령 스킬 등록

> ⚠️ **사전 조건**: 스킬은 `.dxt` 의 MCP 도구를 호출하므로 **Claude Desktop 코워크 모드가 켜져 있어야** 동작합니다 (3-A 박스 참고).

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

claude.ai → **Settings → Customize → Skills** 에서 [skill-bundles/](skill-bundles) 의 5개 zip 을 하나씩 업로드. 로그인 같으면 Claude Desktop 에도 자동 반영.

### 8-B. Claude Code

5개 zip 을 받아 각각 `~/.claude/skills/` 에 압축 해제:

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

설치가 끝났으면 [USAGE.md](USAGE.md)에서 시작 순서·문제 해결을 확인하세요.
