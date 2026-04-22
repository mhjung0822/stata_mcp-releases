# 설치 가이드

설치 후 사용법은 [USAGE.md](USAGE.md) 참고.

---

## 1. 사전 요구 사항

| 항목 | 버전 |
|------|------|
| Java | 17 이상 |
| Node.js | 18 이상 |
| Stata | 17 이상 (19 권장) |
| Claude Desktop | 최신 버전 |

---

## 2. 배포 파일 목록

다운로드: <https://github.com/mhjung0822/stata_mcp-releases/releases> 의 최신 버전에서 8개 파일을 받습니다.

| 파일 | 설명 |
|------|------|
| `stata-mcp-server.jar` | MCP 서버 (Spring Boot, 포트 8080) |
| `mcp-bridge-v18.js` | Claude Desktop 연동 브릿지 (Node.js, stdio↔SSE) |
| `stata_channel_server.js` | **Claude Code 전용 채널 서버** (Node.js, stdio, push 이벤트 세션 주입) |
| `stata-drone.jar` | Stata 내부 실행 드론 (포트 8001) |
| `mcp_connect.ado` | Stata 드론 연결 명령어 |
| `llm.ado` | Stata push 명령어 (`llm push > cmd`) |
| `stata_mcp_instructions_example_compact.md` | Claude 지침 예시 (간결) |
| `stata_mcp_instructions_example_full.md` | Claude 지침 예시 (상세) |

> `stata_mcp.properties`는 동봉되지 않습니다 — 첫 서버 기동 시 jar 옆에 자동 생성됩니다 (아래 3. 참고).

---

## 3. 서버 설치 폴더

**세 파일**을 같은 폴더에 배치:
- `stata-mcp-server.jar`
- `mcp-bridge-v18.js`
- `stata_channel_server.js` (Claude Code 안 쓰면 생략 가능, 같이 둬도 무해)

### 권장 위치

**macOS**:
```
~/Documents/StataMCP/
├── stata-mcp-server.jar
├── mcp-bridge-v18.js
└── stata_channel_server.js
```

**Windows**:
```
C:\Users\YOUR_NAME\Documents\StataMCP\
├── stata-mcp-server.jar
├── mcp-bridge-v18.js
└── stata_channel_server.js
```

> jar와 브릿지는 **반드시 같은 폴더** — 브릿지(`mcp-bridge-v18.js`)가 옆 폴더의 jar를 찾음.

### stata_mcp.properties (자동 생성)

서버 첫 기동 시 jar 옆에 다음 내용으로 **자동 생성**됩니다:

```properties
# Stata MCP 환경 설정 (자동 생성)
stata.mcp.base-dir="<jar가 있는 폴더 절대경로>"
BRIDGE_PORT="8080"
DRONE_PORT="8001"
```

- `base-dir` 하위에 `server-logs/`는 서버 기동 시, `logs/`/`graphs/`/`flow_log/`는 첫 명령 실행 시 자동 생성됩니다.

#### base-dir / 포트를 미리 정하고 싶다면 (선택)

서버 기동 전에 jar 옆에 `stata_mcp.properties` 파일을 직접 만들어 원하는 값을 넣어두면 자동 생성 대신 그 값이 사용됩니다.

```properties
# macOS 예시:
stata.mcp.base-dir="/Users/YOUR_NAME/Documents/StataMCP"

# Windows 예시:
stata.mcp.base-dir="C:/Users/YOUR_NAME/Documents/StataMCP"

BRIDGE_PORT="8080"
DRONE_PORT="8001"
```

- 빈 값으로 둔 키만 자동 fallback 됩니다 (예: `stata.mcp.base-dir=""` 두면 jarDir 자동 채움).

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

## 5. Claude Desktop 설정

### macOS

`~/Library/Application Support/Claude/claude_desktop_config.json` 파일을 열고:

```json
{
  "mcpServers": {
    "stata_mcp": {
      "command": "/usr/local/bin/node",
      "args": [
        "/Users/YOUR_NAME/Documents/StataMCP/mcp-bridge-v18.js",
        "http://127.0.0.1:8080/mcp/sse"
      ]
    }
  }
}
```

### Windows

`%APPDATA%\Claude\claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "stata_mcp": {
      "command": "C:\\Program Files\\nodejs\\node.exe",
      "args": [
        "C:\\Users\\YOUR_NAME\\Documents\\StataMCP\\mcp-bridge-v18.js",
        "http://127.0.0.1:8080/mcp/sse"
      ]
    }
  }
}
```

### Node.js 경로 확인

```bash
# macOS / Linux
which node

# Windows (PowerShell)
Get-Command node
```

### 설정 파일 없을 때 생성

```bash
# macOS
mkdir -p ~/Library/Application\ Support/Claude

# Windows (PowerShell)
mkdir $env:APPDATA\Claude
```

> 설정 후 Claude Desktop **재시작** 필수.

---

## 6. Claude Code 설정 (선택)

터미널에서 Claude Code로 Stata MCP를 쓰고, **Stata GUI의 `llm push` 결과를 세션에 실시간 주입**받고 싶다면 추가 설정.

Claude Desktop 대신 / 외에 Claude Code도 사용하는 경우만 필요.

### 요구 사항

| 항목 | 조건 |
|---|---|
| Claude Code 버전 | v2.1.80 이상 |
| 인증 | claude.ai 로그인 (API key 인증 불가) |
| Node.js | v18+ (`fetch` 내장 필요) |

### 두 MCP 서버 등록

역할이 다른 **두 서버**를 user scope로 등록:

**① Tool 서버** (`executeStata`, `getPushResults` 등 조회·실행):
```bash
claude mcp add -s user stata_mcp_java -- node \
  <서버 설치 폴더>/mcp-bridge-v18.js \
  http://127.0.0.1:8080/mcp/sse
```

**② 채널 서버** (Stata push 이벤트를 세션에 자동 주입):
```bash
claude mcp add -s user stata_channel -- node \
  <서버 설치 폴더>/stata_channel_server.js
```

경로 예시 (macOS):
```bash
claude mcp add -s user stata_mcp_java -- node \
  ~/Documents/StataMCP/mcp-bridge-v18.js \
  http://127.0.0.1:8080/mcp/sse

claude mcp add -s user stata_channel -- node \
  ~/Documents/StataMCP/stata_channel_server.js
```

등록 확인:
```bash
claude mcp list
```
→ `stata_mcp_java`, `stata_channel` 둘 다 `✓ Connected` 로 나와야 OK.
(서버가 기동 중이어야 Connected 확인됨)

> Claude Code 실행 방법, 채널 사용 플로우 등은 [USAGE.md → 5. Claude Code 채널 사용](USAGE.md#5-claude-code-채널-사용) 참고.

---

## 7. 경로 구조 요약

설치 후:

```
<서버 설치 폴더>/                          ← 사용자 선택
├── stata-mcp-server.jar
├── mcp-bridge-v18.js
├── stata_channel_server.js               ← Claude Code 채널 (선택)
└── stata_mcp.properties                  ← 첫 기동 시 자동 생성

<Stata PERSONAL ado>/                     ← Stata adopath 자동 인식
├── stata-drone.jar
├── mcp_connect.ado
└── llm.ado

<base-dir>/                                ← properties에서 지정
├── logs/                                 ← 분석 명령 이력 (서버가 append)
│   └── <sessionTs>.log
├── graphs/                               ← 그래프 PNG + sidecar JSON
│   ├── <sessionTs>_g<N>.png
│   └── <sessionTs>_g<N>.json
├── flow_log/                             ← Command Flow JSONL (대시보드 복원용)
│   └── <sessionTs>.jsonl
├── server-logs/                          ← Spring Boot 시스템 로그
│   └── stata-mcp-server_<ts>.log
└── stata_mcp_instructions.md             ← (선택) Claude 지침 파일
```

> `sessionTs = YYYYMMDD_HHMM` — 서버 기동 시점. 서버 재기동 시 새 세션 파일 시작.
> 저장 파일(`save`/`export` 등)은 사용자가 Stata에서 지정한 경로 그대로 저장 — 서버/드론이 이동하지 않음.

---

## 8. 다음 단계

설치가 끝났으면 [USAGE.md](USAGE.md)에서 시작 순서·대시보드·문제 해결을 확인하세요.
