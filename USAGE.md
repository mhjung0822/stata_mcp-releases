# 사용 가이드

설치는 [INSTALL.md](INSTALL.md) 참고.

---

## 1. 공통 시작 순서

드론은 서버 없이도 기동 가능 (경로 무지 구조). 다만 실제 사용은 서버+Claude가 있어야 의미 있음.

```
1. Claude Desktop 또는 Claude Code 실행
   → 브릿지가 stata-mcp-server.jar 자동 기동 (포트 8080)
2. Stata 실행
3. Stata에서:
```

```stata
mcp_connect
```

출력 예:
```
[Drone] Stata-MCP-Drone launching on port 8001...
[Drone] Ready for commands on port 8001 (bridge=8080)
```

이후 클라이언트(Desktop 또는 Code)에서 Stata 명령을 요청하거나, Stata에서 `llm push`로 결과를 클라이언트로 전송.

---

## 2. Claude Desktop 사용

### 2-1. 명령 요청

채팅창에 자연어로 Stata 작업 요청:

```
auto 데이터셋 불러와서 price를 mpg와 weight로 회귀해줘
```

Claude가 다음 흐름으로 동작:
1. `executeStata` tool 호출 → `sysuse auto, clear` / `regress price mpg weight` 등 실행
2. Stata 결과(output, r()/e(), 그래프) 받아 채팅에 표시
3. 그래프는 채팅에 inline 이미지로 표시 (`![](http://127.0.0.1:8080/api/files/raw?path=graphs/...)`)
4. 후속 질문/지시 가능 (예: "잔차 그래프도 그려줘")

### 2-2. Stata GUI에서 push (양방향)

Stata GUI에서 직접 분석 후 결과를 Claude로 전송:

```stata
sysuse auto, clear
regress price mpg weight
llm push                        // 직전 명령 결과 + r()/e() push
llm push > predict yhat         // > 뒤의 명령 실행 + push
```

- 다음 Claude 메시지에서 Claude가 `getPushResults` tool로 결과 fetch
- Claude Desktop UI에는 push 알림이 자동 표시되지 않음 — Claude에게 "push 결과 봐줘" 요청하거나 Claude가 자체 판단으로 fetch

> Claude Desktop은 MCP `notification` 미지원이라 push 이벤트 자동 주입 불가. 자동 주입을 원하면 [Claude Code 채널 사용](#5-claude-code-채널-사용) 참고.

### 2-3. 그래프/저장 파일

| 종류 | 어디로 |
|---|---|
| 그래프 | `<base-dir>/graphs/<sessionTs>_g<N>.png` (서버가 자동 저장, Claude 채팅에 inline 표시) |
| 저장 파일 (`save`/`export` 등) | 사용자가 Stata에서 지정한 그 경로 (서버/드론 무관) |
| 분석 명령 이력 | `<base-dir>/logs/<sessionTs>.log` (세션별 누적) |

### 2-4. Claude 지침 파일 (선택)

Claude에게 분석 맥락/룰을 지시하고 싶을 때. **설정 안 해도 MCP 작동**.

#### 파일 위치

```
<base-dir>/stata_mcp_instructions.md
```

#### 작성 방법

한국어 Markdown으로 자유롭게 작성. 양식이 막막하면 release 폴더의 두 예시 파일을 참고하세요:

- `stata_mcp_instructions_example_compact.md` — 간결 (5섹션, ~450 토큰)
- `stata_mcp_instructions_example_full.md` — 상세 (12섹션, ~1500 토큰)

내용을 그대로 옮기거나 본인 환경/룰에 맞게 편집해서 `<base-dir>/stata_mcp_instructions.md` 로 저장하면 됩니다.

#### 동작

- Claude가 `getInstructions` MCP tool을 호출하면 파일 내용 반환
- 파일 없으면 **설정 경로 안내 메시지** 반환 (MCP 기본 기능에 영향 없음)
- 파일 수정 시 서버 재기동 불필요 — 다음 `getInstructions` 호출부터 반영

### 2-5. 종료

#### 드론만 정지 (Stata는 유지)

```stata
mcp_connect, shutdown
```

#### MCP 서버 정지

- 대시보드 우하단 ⏻ 버튼 클릭, 또는
- Claude Desktop 종료 (브릿지가 서버 자동 정리)

#### 완전 정리

- Claude Desktop 종료 → 서버 자동 종료
- Stata 종료 → 드론 자동 종료 (JVM이 Stata 프로세스 내)

---

## 3. 대시보드

브라우저에서 `http://localhost:8080/` 접속:
- **Command Flow** — 명령 실행 흐름 (SSE로 실시간 갱신, 페이지 새로고침 시 `flow_log/` 기반 복원)
- **Variables** — 현재 데이터셋 변수 트리 (값 라벨 포함)
- **Data** — 관측치 미리보기 (Refresh 버튼으로 로드)
- **File Explorer** — `baseDir` 하위 파일 탐색 (이미지 클릭 시 우측 패널 프리뷰)
- **Monitor** — push 결과 + 세션 로그

상태 표시기 (Bridge ● / Drone ●)는 SSE 이벤트로 자동 갱신, 옆 🔄 버튼으로 수동 새로고침.

---

## 4. 포트 변경

`stata_mcp.properties`에서 `BRIDGE_PORT` 또는 `DRONE_PORT` 변경 시, `mcp_connect` 호출할 때 맞춰 지정:

```stata
mcp_connect, bridgeport(8090)                    // bridge만 변경
mcp_connect, bridgeport(8090) droneport(9001)   // 둘 다 변경
```

Claude Desktop config의 `http://127.0.0.1:8080/mcp/sse`도 같은 포트로 갱신 필요.

---

## 5. Claude Code 채널 사용

Claude Desktop 대신 / 외에 Claude Code도 사용하면, **Stata GUI의 `llm push` 결과를 세션에 실시간 주입**받을 수 있음. 등록은 [INSTALL.md → 6. Claude Code 설정](INSTALL.md#6-claude-code-설정-선택) 참고.

### 5-1. Claude Code 실행

채널 이벤트를 받으려면 반드시 `--dangerously-load-development-channels` 플래그 사용:

```bash
claude --dangerously-load-development-channels server:stata_channel
```

- `server:` 뒤는 채널 서버 등록 이름 (`stata_channel`)
- Research preview 기능이라 "dangerously" 접두사 필수
- 매 세션마다 지정 — alias로 간소화 가능:
  ```bash
  # ~/.zshrc 또는 ~/.bashrc
  alias statamcp="claude --dangerously-load-development-channels server:stata_channel"
  ```

### 5-2. 사용 플로우

1. Claude Desktop이 MCP 서버 기동한 상태(port 8080) — 또는 수동 `java -jar stata-mcp-server.jar`
2. Stata에서 `mcp_connect` — 드론 기동
3. Claude Code 실행 (위 플래그)
4. Stata GUI에서 분석 후 push:
   ```stata
   sysuse auto, clear
   regress price mpg weight
   llm push
   ```
5. Claude Code 세션에 **즉시** 다음과 같은 채널 블록 주입:
   ```
   <channel source="stata_mcp_java_channel" source="stata">
   [Stata push] cmd=regress price mpg weight | at=2026-04-23T05:30:00
   </channel>
   ```
6. Claude가 이벤트 인식 — 사용자 타이핑 없이 자동 반응
7. 상세 결과 필요 시 Claude가 `getPushResults` tool 호출해 fetch

### 5-3. 구조 요약

```
Stata GUI (llm push)
    ↓ HTTP POST
Spring Boot :8080 /push
    ├─→ pushStore 저장
    └─→ SSE /api/events
              ↓
     stata_channel_server.js (stdio)
              ↓ notifications/claude/channel
         Claude Code 세션 ← <channel> 블록 주입

Claude Code → stata_mcp_java (브릿지/SSE) → Spring Boot /mcp
        ↓
     Tool 호출 (getPushResults, getStataPwd, executeStata 등)
```

### 5-4. 첫 실행 시 MCP 서버 승인

Claude Code가 새 MCP 서버를 처음 spawn하면 **승인 프롬프트** 표시:
- `Trust this MCP server?` / `Approve` 계열 다이얼로그
- **Approve / Y 선택** 필수 — dismiss하면 tool 호출 불가
- 한 번 승인 후 `~/.claude.json`에 저장되어 재등록/초기화 전까지 자동

### 5-5. 지침 파일 조작 (Read/Write tool)

Claude Code는 `Read`/`Write` tool로 [2-4. Claude 지침 파일](#2-4-claude-지침-파일-선택) 경로(`<base-dir>/stata_mcp_instructions.md`)를 직접 조작 가능:

```
"지침 파일 만들어줘" → Claude가 Write tool로 자동 작성
"지침 업데이트해서 반영해" → Claude가 편집 후 getInstructions 재호출
```

---

## 6. 문제 해결

### 드론/서버 연결 확인

```
curl http://localhost:8001/status    # 드론 (Stata 내부)
curl http://localhost:8080/status    # MCP 서버
curl http://localhost:8080/api/drone-status    # 서버 기준 드론 상태
```

- 드론은 서버 없이도 기동 가능 (경로 무지). 응답 없으면 Stata에서 `mcp_connect` 호출 확인.
- 서버 미동작 시: Claude Desktop 실행(브릿지가 자동 기동) 또는 `java -jar stata-mcp-server.jar` 수동 기동.

### 포트 충돌

```bash
# macOS/Linux
lsof -i :8080
lsof -i :8001

# Windows
netstat -ano | findstr :8080
```

다른 프로세스가 포트를 쓰면 `stata_mcp.properties`에서 포트 변경 + `mcp_connect, bridgeport(...)`로 맞춰주기.

### 브릿지 로그

```bash
# macOS/Linux
tail -f /tmp/stata-mcp-bridge.log

# Windows (PowerShell)
Get-Content $env:TEMP\stata-mcp-bridge.log -Wait
```

### 드론 파일 확인

```stata
* ado 경로에 있는지
ls "`c(sysdir_personal)'stata-drone.jar"
```

### 수동으로 서버 시작 (디버깅)

```bash
java -jar /path/to/stata-mcp-server.jar
```

### 경로/포트 확인

대시보드 브라우저에서:
- `http://localhost:8080/api/config` — 현재 baseDir, logsDir 등
- `http://localhost:8080/api/drone-status` — 드론 연결 상태

### Claude Code 채널 관련

**`stata_channel` 연결 실패**:
- `node <경로>/stata_channel_server.js` 수동 실행해 에러 확인
- 경로 오타 / Node.js v18 미만 / 파일 권한 문제 대부분

**채널 메시지가 안 뜸**:
- Claude Code 버전 2.1.80+ 확인
- `--dangerously-load-development-channels` 플래그 포함 확인
- `claude.ai 로그인` 인증 (API key 불가)
- 서버 기동 (port 8080) 확인
