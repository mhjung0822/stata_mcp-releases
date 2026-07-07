# 사용 가이드

설치는 [INSTALL.md](INSTALL.md) 참고.

---

## 1. 공통 시작 순서

### Claude Desktop 사용자
```
1. 서버 jar 기동 (둘 중 택일):
   a. Stata 실행 → mcp_server + mcp_connect  (권장)
   b. 터미널: java -jar <PLUS>/jar/stata-mcp-server.jar
2. Claude Desktop 실행
3. 코워크 모드 토글 ON  ← 플러그인의 MCP 도구는 코워크 sandbox 내부
```
> 플러그인이 jar 를 자동 띄우지 않음 — 서버는 사용자/Stata 가 띄우고, 플러그인의 mcp-remote 가 그 서버(:8080)에 붙는다.

### Claude Code / Cursor 사용자 (Desktop 미사용 시)
```
1. Stata 실행 → mcp_server  (서버 jar detached 기동)
2. mcp_connect  (드론 시작)
3. Claude Code / Cursor 실행 — 등록된 Streamable HTTP URL 로 자동 연결
```

`mcp_connect` 출력 예:
```
[Drone] Stata-MCP-Drone launching on port 8001...
[Drone] Ready for commands on port 8001 (bridge=8080)
```

이후 클라이언트에서 Stata 명령을 요청하거나, Stata 에서 `llm push` 로 결과를 클라이언트로 전송.

### 제어판 (GUI) — 명령 대신 버튼으로

Stata 에서 `mcp` (= `db mcp`) 를 치면 제어판 다이얼로그가 뜹니다 — 연결/재시작/종료, 서버 상태 확인, 라이선스 편집을 버튼으로.

```stata
mcp          // 제어판 다이얼로그
mcp_set      // 설정 메뉴 (클릭 링크): 라이선스 입력 / 메뉴 등록 / 제거
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

응답에는 `rc` (Stata 반환코드, 0=성공) 가 포함되어 Claude 가 성공/실패를 즉시 판별하고, 문법 오류 시 `getHelp` 로 스스로 확인 후 재시도합니다.

### 2-1b. 장기 실행 명령 (async) — 돌려놓고 계속 대화

bootstrap/simulate/mi impute 같은 오래 걸리는 명령은 Claude 가 `executeStataAsync` 로 던집니다:

```
30만 번 bootstrap 돌려줘 → (즉시) "실행 시작했습니다. 도는 동안 다른 작업 하셔도 됩니다"
   ... 그동안 자유롭게 대화 (모형 질문, 문서 작성, 다음 분석 설계) ...
완료 → 결과 전문이 push 로 도착 (알림) → "결과 보여줘" → 표·해석
```

- 실행 중 다른 Stata 명령은 즉시 `busy` 응답 (기다리며 채팅이 끊기지 않음)
- 완료 결과(출력 전문 + `rc` + 소요시간)는 push 저장소에 배달 — `getPushResults` 로 회수
- r()/e() 저장 결과는 일반 실행과 동일하게 보존 (`getMacro("e(b)")` 등으로 조회)
- 한 번에 하나만 실행 (Stata 엔진이 단일이라서)

### 2-2. Stata GUI에서 push (양방향)

Stata GUI에서 직접 분석 후 결과를 Claude로 전송:

```stata
sysuse auto, clear
regress price mpg weight
llm push                                 // r()/e() push (저장소에 add + 즉시 알림)
llm push > regress price mpg weight      // > 뒤의 명령 실행 + 결과화면 + r()/e() push
llm push, note(발표용 본검정) > regress price mpg weight, robust
                                         // 자연어 메모 첨부 — 나중에 찾기 쉬움
llm push, clear                          // 안 읽은 항목 비우고 새로 push (잔재 정리)
```

- 매 `llm push` 마다 서버 **push 저장소**에 add + Streamable HTTP standby SSE stream 으로 클라이언트에 즉시 알림 (`notifications/claude/channel`)
- Claude 가 알림 받을 때마다 `getPushResults` 호출 → 안 읽은 것부터 한 개씩 가져감
- 빠른 연속 push 도 race 없이 누적 (Claude 처리 중 새 push 도착해도 안전)
- 서버는 `experimental.claude/channel` capability 를 advertise — 별도 채널 서버 불필요

#### push 저장소 — 읽어도 사라지지 않습니다

가져간 결과는 삭제되지 않고 **읽음 표시**만 됩니다. 세션 동안 전부 보관되어 자연어로 다시 부를 수 있습니다:

```
"아까 그 bootstrap 결과 다시 보여줘"        → 목차(history)에서 찾아 재조회
"robust 로 돌린 것들만 찾아줘"              → 명령·출력·메모를 키워드 검색
"3번 결과에 '최종 스펙' 메모 달아줘"          → note 부여 (검색 대상)
"지금까지 결과 전부 파일로 저장해"            → c(pwd) 에 push_all_*.json 스냅샷
"어제 저장한 파일 불러와"                    → 스냅샷 재적재 (이어서 작업)
```

- 서버 정상 종료 시 잔여 결과를 `push_autosave_*.json` 으로 자동 저장 — 급히 꺼도 다음 세션에서 load 로 복구
- 서버가 잠시 죽어 있어도 드론이 결과를 보관했다가 재전송 (배달 보장)

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

### 2-4. 도움말 / 환경 조회

Claude 가 Stata 명령을 헷갈릴 때 스스로 확인하는 도구들 — 사용자가 직접 부를 일은 적지만, 자연어로도 활용할 수 있습니다:

```
"xtreg 옵션 뭐 있었지?"                → getHelp("xtreg") — 개요 slice (모델 목록 + 하강 키)
"xtreg fe 의 vce 옵션 자세히"           → getHelp("xtreg","fe.vce") — 그 옵션 상세만 (계단식 하강)
"su 가 무슨 명령이더라"                 → 약어 자동 해석 (su→summarize, Stata 규칙 그대로)
"클러스터 로버스트 관련 명령 찾아줘"      → 로컬 키워드 검색 → 관련 명령 후보 + 한줄설명
"Stata 환경/버전 알려줘"               → getStataEnv — 버전·에디션·경로·이론한계 32항목
```

- **v0.12.0**: 도움말이 온톨로지 DB(노드 4,464개)에서 **필요한 slice 만 계단식 반환** — 기본 호출은 개요(수백 토큰), `selector` 로 모델(`fe`)/옵션그룹(`fe.se`)/옵션상세(`fe.vce`)/`examples`/`stored`/`post.predict` 등 하강. 잘못된 selector 는 그 명령의 유효 selector 목록을 돌려줌. 자세한 문법은 `/stata-help` 스킬 참고
- 설치 동봉 DB 라 **장기 명령이 도는 중에도 즉답**, 인터넷 불필요
- SSC 등 커뮤니티 패키지 도움말도 조회 가능 (설치돼 있으면 — 풀네임으로)
- 도움말 DB 는 패키지 업데이트로 최신 유지 (Stata 본체 업데이트에 맞춰 배포측에서 재생성)

> **v0.11.0 변경 (마이그레이션)**: `getScalar`/`getMatrix` 툴이 `getMacro` 하나로 통합됐습니다.
> 이름만 주면 local/global/스칼라/행렬을 한 번에 찾아 있는 것을 전부 반환합니다 —
> `getMacro("b")`, `getMacro("e(r2)")`, `getMacro("e(V)")` 식. 스킬/노트 등에서 구 툴명을
> 참조하고 있었다면 갱신하세요.

### 2-5. 슬래시 명령 스킬 (플러그인 설치 시)

플러그인([INSTALL.md](INSTALL.md) 5장)을 설치하면 다음 슬래시 명령이 활성화됩니다.
자연어가 아닌 **명시적 슬래시 호출에만 응답**합니다 (`/stata-exec sysuse auto` 식).

| 명령 | 동작 |
|---|---|
| `/stata-setup` | Stata 환경·작업폴더 점검 + 마운트 경로 확인 + 세션 출력규약 로드 |
| `/stata-exec <cmd>` | Stata 명령 직접 실행 |
| `/stata-async <cmd>` | 장기 명령 비동기 실행 (즉시 반환, 완료 결과는 `/stata-pull` 로) |
| `/stata-help <cmd> [selector]` | 명령 도움말 계단식 조회 — 개요→모델→옵션 상세 하강 (예: `/stata-help xtreg fe.vce`), 약어·키워드 검색 |
| `/stata-pull` | Stata GUI 에서 push 한 결과 가져오기 |
| `/stata-data-context` | 데이터 변경 후 컨텍스트 재동기화 (pwd·obs·변수) |
| `/stata-data-fullcontext` | 현재 데이터셋 전체 컨텍스트 요약 (codebook 수준) |
| `/stata-graph-get` | 현재 그래프 spec 조회 |
| `/stata-graph-export [name]` | 메모리의 그래프를 PNG 로 export (인자 없으면 현재 그래프) |
| `/stata-instruction` | 세션 출력형식 규약 로드 (`/stata-setup` 이 자동 호출) |

### 2-6. 종료

#### 드론만 정지 (Stata는 유지)

```stata
mcp_connect, shutdown
```

#### MCP 서버 정지

```stata
mcp_server, stop
```

또는 `curl -X POST http://127.0.0.1:8080/api/shutdown`

> 서버는 detached 프로세스라 Stata/Claude 를 꺼도 살아 있습니다 — 명시적으로 정지해야 합니다.

#### 완전 정리

- `mcp_server, stop` 으로 서버 종료
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

Claude는 이 신호를 보고 사용자에게 마운트로 되돌릴지 질문하거나 새 폴더 유지 안내. CLAUDE.md/스킬에 처리 룰을 적어두면 자동 응대.

---

## 4. 포트 변경

`stata_mcp.properties`에서 `BRIDGE_PORT` 또는 `DRONE_PORT` 변경 시, `mcp_connect` 호출할 때 맞춰 지정:

```stata
mcp_connect, bridgeport(8090)                    // bridge만 변경
mcp_connect, bridgeport(8090) droneport(9001)   // 둘 다 변경
```

> Claude Desktop/코워크 플러그인은 8080 고정입니다 — 포트를 바꾸면 플러그인 대신 수동 등록이 필요하니 Desktop 사용자는 기본 포트 유지를 권장합니다.

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
    ├─→ push 저장소에 add (id/read/note 부여 — pull 은 읽음 표시, 삭제 아님)
    └─→ mcpTransportProvider.notifyClients("notifications/claude/channel", ...)
              ↓
        Streamable HTTP standby SSE stream (GET /mcp)
              ↓
        Claude Code / Desktop / Cursor 세션
              ↓ (capability experimental.claude/channel 매칭 시 채널 UI 표시)
        클라이언트가 getPushResults tool 호출 → 안 읽은 것부터 본문 fetch
```

별도 채널 서버 / Node bridge 불필요 — 단일 Streamable HTTP transport 가 양방향 모두 처리.

### 첫 실행 시 MCP 서버 승인

Claude Code 가 새 MCP 서버를 처음 사용할 때 **승인 프롬프트** 표시:
- `Trust this MCP server?` / `Approve` 계열 다이얼로그
- **Approve / Y 선택** 필수 — dismiss 하면 tool 호출 불가
- 한 번 승인 후 `~/.claude.json` 에 저장되어 재등록/초기화 전까지 자동

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
- 서버 미동작 시: Stata 에서 `mcp_server` (또는 `java -jar <PLUS>/jar/stata-mcp-server.jar` 수동).

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
# 위치: <jar 옆>/server-logs/stata-mcp-server_<ts>.log  (net install 이면 <PLUS>/jar/)
ls "$(echo ~/Library/Application\ Support/Stata/ado/plus/jar/server-logs/)"
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
