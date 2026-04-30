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
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, Streamable HTTP transport, 포트 8080) |
| `mcp-bridge-v18.js` | **Claude Desktop 전용** stdio↔Streamable HTTP bridge (Node 18+ 빌트인만, npm install 불필요). Java 서버 lazy auto-spawn 도 담당. Claude Code/Cursor 는 불필요 |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `mcp_connect.ado` | Stata 드론 연결 명령어 |
| `llm.ado` | Stata push 명령어 (`llm push [, r e keep clear] [> cmd]`) |
| `stata_mcp_instructions_example_compact.md` | Claude 지침 예시 (간결) |
| `stata_mcp_instructions_example_full.md` | Claude 지침 예시 (상세) |

> `stata_mcp.properties`는 동봉되지 않습니다 — 첫 서버 기동 시 jar 옆에 자동 생성됩니다 (아래 3. 참고).

---

## 3. 서버 설치 폴더

**두 파일**을 같은 폴더에 배치:
- `stata-mcp-server.jar`
- `mcp-bridge-v18.js` (Claude Desktop 사용 시 필수, 아니면 생략 가능)

### 권장 위치

**macOS**:
```
~/Documents/StataMCP/
├── stata-mcp-server.jar
└── mcp-bridge-v18.js
```

**Windows**:
```
C:\Users\YOUR_NAME\Documents\StataMCP\
├── stata-mcp-server.jar
└── mcp-bridge-v18.js
```

> bridge 와 jar 는 **반드시 같은 폴더** — bridge 가 옆 폴더의 jar 를 자동 spawn.

### stata_mcp.properties (자동 생성)

서버 첫 기동 시 jar 옆에 다음 내용으로 **자동 생성**됩니다:

```properties
# Stata MCP 환경 설정 (자동 생성)
BRIDGE_PORT="8080"
DRONE_PORT="8001"
```

#### 포트 변경 (선택)

서버 기동 전에 jar 옆에 `stata_mcp.properties` 파일을 직접 만들어 원하는 값을 넣어두면 자동 생성 대신 그 값이 사용됩니다.

```properties
BRIDGE_PORT="8090"
DRONE_PORT="9001"
```

### Claude 지침 파일 (선택)

분석 룰을 Claude 에게 적용하고 싶으면 jar 옆에 `stata_mcp_instructions.md` 작성:

```
~/Documents/StataMCP/
├── stata-mcp-server.jar
└── stata_mcp_instructions.md         ← (선택) 사용자가 작성
```

`stata_mcp_instructions_example_compact.md` 또는 `stata_mcp_instructions_example_full.md` 내용을 복사해 시작점으로 사용.

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

### Claude Desktop 사용자
서버를 별도로 띄울 필요 없음 — Claude Desktop 시작 시 bridge 가 자동으로 jar spawn (detached, Claude 종료해도 서버 생존).

### Claude Code / Cursor 사용자
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

### Claude Desktop — bridge 경유

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

설치 후:

```
<서버 설치 폴더>/                          ← 사용자 선택 (예: ~/Documents/StataMCP/)
├── stata-mcp-server.jar
├── mcp-bridge-v18.js                     ← Claude Desktop 사용 시 필수
├── stata_mcp.properties                  ← 첫 기동 시 자동 생성 (포트만)
├── stata_mcp_instructions.md             ← (선택) Claude 지침 파일
├── stata_mcp_instructions_example_compact.md
├── stata_mcp_instructions_example_full.md
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

## 8. 다음 단계

설치가 끝났으면 [USAGE.md](USAGE.md)에서 시작 순서·문제 해결을 확인하세요.
