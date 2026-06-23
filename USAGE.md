# 사용 가이드

설치는 [INSTALL.md](INSTALL.md) 참고.

---

## 1. 공통 시작 순서

### Claude Desktop 사용자
```
1. 서버 jar 기동 (둘 중 택일):
   a. Stata 실행 → mcp_connect  (드론 + 서버 jar 같이 띄움 — 권장)
   b. 터미널: java -jar ~/Documents/StataMCP/stata-mcp-server.jar
2. Claude Desktop 실행
3. 코워크 모드 토글 ON  ← .dxt 의 MCP 도구는 코워크 sandbox 내부
```
> `.dxt` 가 jar 를 자동 띄우지 않음 — 서버는 사용자/Stata 가 띄우고, `.dxt` 는 그 서버에 mcp-remote 로 붙는 wrapper.

### Claude Code / Cursor 사용자 (Desktop 미사용 시)
```
1. MCP 서버 기동 (한 번)
   java -jar ~/Documents/StataMCP/stata-mcp-server.jar
2. Stata 실행 → mcp_connect
3. Claude Code / Cursor 실행 — 등록된 Streamable HTTP URL 로 자동 연결
```

`mcp_connect` 출력 예:
```
[Drone] Stata-MCP-Drone launching on port 8001...
[Drone] Ready for commands on port 8001 (bridge=8080)
```

이후 클라이언트에서 Stata 명령을 요청하거나, Stata 에서 `llm push` 로 결과를 클라이언트로 전송.

### 제어판 (GUI) — 명령 대신 버튼으로

Stata 에서 `mcp` (= `db mcp`) 를 치면 제어판 다이얼로그가 뜹니다 — 연결/재시작/종료, 서버 상태 확인, 라이선스·지침 편집을 버튼으로.

```stata
mcp          // 제어판 다이얼로그
mcp_set      // 설정 메뉴 (클릭 링크): 라이선스 입력 / 지침 초기화·빈버전·삭제 / 메뉴 등록
```

메뉴바에 상시 등록 (1회):

```stata
mcp_menu, install   // User ▸ Stata-MCP ▸ Control Panel... — 다음 실행부터 자동
```

> 라이선스 키 입력/교체도 제어판의 **Edit license / properties** 버튼 또는 `mcp_set` 에서 가능합니다.

**전체 제거**:

```stata
mcp_uninstall              // 미리보기 (삭제 안 함) — 대상 목록 + confirm 링크
mcp_uninstall, confirm     // ado/dlg/jar + 메뉴 등록 삭제 (라이선스/지침 보존)
mcp_uninstall, confirm all // 라이선스 키/지침 데이터까지 삭제
```

---

## 2. 명령 / Push 사용

### 2-1. 명령 요청

채팅창에 자연어로 Stata 작업 요청:

```
auto 데이터셋 불러와서 price를 mpg와 weight로 회귀해줘
```

Claude가 다음 흐름으로 동작:
1. `executeStata` tool 호출 → `sysuse auto, clear` / `regress price mpg weight` 등 실행
2. Stata 결과(output, r()/e(), 그래프) 받아 채팅에 표시
3. 그래프 명령이면 응답에 `graphDrawn: true` 포함 — 이미지가 필요할 때 Claude 가 `exportGraph` 호출 → `c(pwd)/g_yyyyMMddHHmm_xxxx.png` 생성, `graphPath`(절대경로)·`graphFilename` 응답 (cowork 패널이 작업폴더 모니터링 시 자동 표시)
4. 후속 질문/지시 가능 (예: "잔차 그래프도 그려줘")

### 2-2. Stata GUI에서 push (양방향)

Stata GUI에서 직접 분석 후 결과를 Claude로 전송:

```stata
sysuse auto, clear
regress price mpg weight
llm push                        // r()/e() push (큐에 add + 즉시 알림)
llm push > regress price mpg weight    // > 뒤의 명령 실행 + 직전 명령 결과화면 + r()/e() push
llm push, clear                 // 큐 비우고 새로 push (잔재 정리)
```

- 매 `llm push` 마다 서버 큐에 add + Streamable HTTP standby SSE stream 으로 클라이언트에 즉시 알림 (`notifications/claude/channel`)
- Claude 가 알림 받을 때마다 `getPushResults()` 호출 → 큐에서 한 개씩 가져감
- 빠른 연속 push 도 race 없이 큐에 누적 (Claude 처리 중 새 push 도착해도 안전)
- 서버는 `experimental.claude/channel` capability 를 advertise — 별도 채널 서버 불필요

**Claude Code 자동 알림 표시**:
```bash
claude --dangerously-load-development-channels server:StataMCP
```
- 이 플래그가 있어야 Claude Code 가 `notifications/claude/channel` 을 채널 UI 로 라우팅
- 플래그 없이도 transport 는 정상 — `getPushResults` tool 명시 호출하면 큐 본문 가져옴
- 매 세션 지정 부담스러우면 alias:
  ```bash
  alias statamcp="claude --dangerously-load-development-channels server:StataMCP"
  ```

> 클라이언트가 MCP `notification` 처리 안 하는 경우(구버전 Claude Desktop 등) 에는 자동 주입이 안 보임. "push 결과 봐줘" 로 명시 호출하면 `getPushResults` 가 실행되어 큐 결과를 가져옴.

### 2-3. 그래프/저장 파일

| 종류 | 어디로 |
|---|---|
| 그래프 | `<c(pwd)>/g_yyyyMMddHHmm_xxxx.png` (`exportGraph` 호출 시에만 생성 — 자동 export 없음, 분 timestamp + 4자리 hex random) |
| 저장 파일 (`save`/`export` 등) | 사용자가 Stata에서 지정한 그 경로 (서버/드론 무관) |
| 서버 시스템 로그 | `<jar 옆>/server-logs/stata-mcp-server_<ts>.log` |

### 2-4. Claude 지침 파일 (선택)

Claude에게 분석 맥락/룰을 지시하고 싶을 때. **설정 안 해도 MCP 작동**.

#### 처음 받기

```stata
mcp_edit_instructions, init           // 간결한 기본 예시 다운로드 → 자동으로 편집기 열림
mcp_edit_instructions, init full      // 상세 예시
mcp_edit_instructions, init force     // 기존 파일 덮어쓰기
```

GitHub release 에서 예시를 jar 옆 (`<PLUS>/jar/stata_mcp_instructions.md`) 으로 다운로드한 뒤 OS 기본 에디터로 자동 open.

#### 이후 편집

```stata
mcp_edit_instructions                 // 기본 에디터로 다시 열기
```

#### 파일 위치 (참고)

`net install` 로 설치한 경우 jar 와 같은 디렉토리:
```
<c(sysdir_plus)>/jar/stata_mcp_instructions.md
```

위치 직접 알 필요 없음 — `mcp_edit_instructions` 가 `findfile` 로 잡아서 열어줌.

#### 동작

- Claude가 `getInstructions` MCP tool을 호출하면 파일 내용 반환
- 파일 없으면 **설정 경로 안내 메시지** 반환 (MCP 기본 기능에 영향 없음)
- 파일 수정 시 서버 재기동 불필요 — 다음 `getInstructions` 호출부터 반영
- `adoupdate stata-mcp` 해도 이 파일은 net install 패키지에 포함 안 됨 → **사용자 편집 안전**

### 2-5. 종료

#### 드론만 정지 (Stata는 유지)

```stata
mcp_connect, shutdown
```

#### MCP 서버 정지

- 트레이 메뉴 (Exit Server), 또는
- `curl -X POST http://127.0.0.1:8080/api/shutdown`

> bridge 는 Java 서버를 detached 로 spawn 하므로, Claude Desktop 종료 ≠ 서버 종료. 명시적 트레이/curl 종료 필요.

#### 완전 정리

- 트레이에서 서버 종료
- Stata 종료 → 드론 자동 종료 (JVM이 Stata 프로세스 내)

---

## 3. pwd 변경 감지

Stata에서 `cd /다른/경로` 로 작업폴더를 옮기면 다음 `executeStata` 응답에 `pwdChange` 필드가 포함됩니다:

```json
{
  "pwdChange": {
    "from": "/Users/me/proj-A",
    "to": "/Users/me/proj-B"
  },
  ...
}
```

Claude는 이 신호를 보고 사용자에게 마운트로 되돌릴지 질문하거나 새 폴더 유지 안내. 인스트럭션 파일에 처리 룰을 적어두면 자동 응대.

---

## 4. 포트 변경

`stata_mcp.properties`에서 `BRIDGE_PORT` 또는 `DRONE_PORT` 변경 시, `mcp_connect` 호출할 때 맞춰 지정:

```stata
mcp_connect, bridgeport(8090)                    // bridge만 변경
mcp_connect, bridgeport(8090) droneport(9001)   // 둘 다 변경
```

Claude Code 등록 명령도 같이 갱신 (포트 변경 시):
```bash
claude mcp remove StataMCP -s user
claude mcp add -s user --transport http StataMCP http://127.0.0.1:8090/mcp
```

---

## 5. 푸시 알림 흐름 (Streamable HTTP)

Stata `llm push` 결과가 클라이언트에 자동 도달하는 경로:

```
Stata GUI (llm push)
    ↓ drone javacall
StataDrone :8001
    ↓ HTTP POST /push
Spring Boot :8080 /push
    ├─→ pushQueue 에 add (FIFO)
    └─→ mcpTransportProvider.notifyClients("notifications/claude/channel", ...)
              ↓
        Streamable HTTP standby SSE stream (GET /mcp)
              ↓
        Claude Code / Desktop / Cursor 세션
              ↓ (capability experimental.claude/channel 매칭 시 채널 UI 표시)
        클라이언트가 getPushResults tool 호출 → 큐에서 본문 fetch
```

별도 채널 서버 / Node bridge 불필요 — 단일 Streamable HTTP transport 가 양방향 모두 처리.

### 첫 실행 시 MCP 서버 승인

Claude Code 가 새 MCP 서버를 처음 사용할 때 **승인 프롬프트** 표시:
- `Trust this MCP server?` / `Approve` 계열 다이얼로그
- **Approve / Y 선택** 필수 — dismiss 하면 tool 호출 불가
- 한 번 승인 후 `~/.claude.json` 에 저장되어 재등록/초기화 전까지 자동

### 지침 파일 조작 (Read/Write tool)

Claude Code 는 `Read`/`Write` tool 로 `<c(sysdir_plus)>/jar/stata_mcp_instructions.md` 를 직접 조작 가능 (경로는 Stata 에서 `display "`c(sysdir_plus)'jar/stata_mcp_instructions.md"` 또는 `mcp_edit_instructions` 출력 메시지로 확인):

```
"지침 파일 만들어줘" → Claude가 Write tool로 자동 작성
"지침 업데이트해서 반영해" → Claude가 편집 후 getInstructions 재호출
```

---

## 6. 문제 해결

### 라이선스 키 문제

증상: `mcp_connect` 시 드론이 시작되지 않고 아래 같은 메시지가 출력됨.

```
[Drone] 라이선스가 YYYY-MM-DD 에 만료되었습니다. 연장 문의: ...
[Drone] 드론을 시작하지 않고 MCP 서버도 종료합니다. 키 입력: mcp_edit_license → 저장 후 mcp_connect, reset
```

| 메시지 | 원인 / 조치 |
|---|---|
| 라이선스 키가 없습니다 | `mcp_edit_license` 로 properties 를 열어 발급받은 키를 `LICENSE_KEY=""` 사이에 붙여넣기 |
| 라이선스 키가 유효하지 않습니다 | 키 복사가 잘렸거나 변조됨 — 받은 키 전체를 다시 붙여넣기 |
| 라이선스가 만료되었습니다 | 새 키 발급 문의 후 교체 |
| 인터넷 연결이 필요합니다 | 검증에 네트워크 시간이 필요 (오프라인 72시간 초과). 연결 후 `mcp_connect, reset` |
| 키 형식이 새 버전입니다 | `net install stata-mcp, ... replace` 로 업데이트 |

키 교체 후에는 `mcp_connect, reset` 만으로 적용됨 (Stata 재시작 불필요). 만료 7일 전부터 `mcp_connect` 시 남은 일수가 표시됨.

### 드론/서버 연결 확인

```
curl http://localhost:8001/status    # 드론 (Stata 내부)
curl http://localhost:8080/status    # MCP 서버
curl http://localhost:8080/api/drone-status    # 서버 기준 드론 상태
```

- 드론은 서버 없이도 기동 가능 (포트 충돌만 없으면). 응답 없으면 Stata에서 `mcp_connect` 호출 확인.
- 서버 미동작 시: Claude Desktop 실행 (bridge 가 자동 spawn) 또는 `java -jar ~/Documents/StataMCP/stata-mcp-server.jar` 수동.

### MCP 핸드셰이크 직접 확인

```bash
curl -X POST http://127.0.0.1:8080/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"curl","version":"0"}}}'
```
응답에 `protocolVersion`, `Mcp-Session-Id` 헤더, `experimental.claude/channel` capability 가 포함되면 정상.

### 포트 충돌

```bash
# macOS/Linux
lsof -i :8080
lsof -i :8001

# Windows
netstat -ano | findstr :8080
```

다른 프로세스가 포트를 쓰면 `stata_mcp.properties`에서 포트 변경 + `mcp_connect, bridgeport(...)`로 맞춰주기.

### 서버 시스템 로그

```bash
# 위치: <jar 옆>/server-logs/stata-mcp-server_<ts>.log
ls ~/Documents/StataMCP/server-logs/
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

### Bridge 로그 (Claude Desktop)

```bash
# macOS / Linux
tail -f /tmp/stata-mcp-bridge.log

# Windows (PowerShell)
Get-Content $env:TEMP\stata-mcp-bridge.log -Wait
```

### Claude Code 등록 / 채널 알림 관련

**서버 등록 갱신**:
```bash
claude mcp remove StataMCP -s user
claude mcp add -s user --transport http StataMCP http://127.0.0.1:8080/mcp
claude mcp list
```

**push 알림이 안 뜸**:
- 서버 기동 확인 (`curl http://127.0.0.1:8080/status`)
- 핸드셰이크 응답에 `experimental.claude/channel` capability 가 있는지 확인 (위 "MCP 핸드셰이크 직접 확인" 참고)
- Claude Code / Desktop 이 Streamable HTTP MCP transport 지원 버전인지 확인
- `getPushResults` tool 명시 호출로 큐 본문은 항상 가져올 수 있음 (알림이 안 와도 폴링 가능)
