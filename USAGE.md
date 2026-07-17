# 사용 가이드

설치는 [INSTALL.md](INSTALL.md) 참고.

---

## 1. 공통 시작 순서

```
1. Stata 실행 → mcp_connect (서버 + 드론 한 번에)
2. Claude Desktop 실행
3. 코워크 모드 토글 ON
```

이후 채팅에서 Stata 작업을 요청하거나, Stata 에서 `llm push` 로 결과를 Claude 로 보냅니다.

### 제어판 (GUI) — 명령 대신 버튼으로

Stata 에서 `mcp` (= `db mcp`) 를 치면 제어판 다이얼로그가 뜹니다 — 연결/재시작/종료, 서버 상태, 라이선스 편집, 도움말 DB 갱신, 제거를 버튼으로.

```stata
mcp          // 제어판 다이얼로그
mcp_setup    // 설정 메뉴 + 도움말 DB 다운로드 (라이선스/기동/제거 링크)
```

메뉴바에 상시 등록 (1회):

```stata
mcp_menu, install   // User ▸ Stata-MCP ▸ Control Panel... — 다음 실행부터 자동
```

> **등록했는데 다음 실행에서 메뉴가 안 보이면** — profile.do 가 다른 곳(예: Stata
> 설치 폴더)에 이미 있는 경우입니다. Stata 는 시작 시 처음 발견한 profile.do
> **하나만** 실행합니다. 그 파일을 열어 맨 아래에 다음 한 줄을 추가하세요:
>
> ```stata
> capture mcp_menu
> ```

> 라이선스 키 입력/교체도 제어판의 **Edit license / properties** 버튼 또는 `mcp_setup` 에서 가능합니다.

**전체 제거**:

```stata
mcp_uninstall              // 미리보기 (삭제 안 함) — 대상 목록 + confirm 링크
mcp_uninstall, confirm     // ado/dlg/jar + 메뉴 등록 삭제 (라이선스/지침 보존)
mcp_uninstall, confirm all // 라이선스 키/지침 데이터까지 삭제
```

> 제어판(`db mcp`)의 **Uninstall** 버튼으로도 미리보기(위 첫 줄)가 실행됩니다.

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

- `llm push` 하면 결과가 **저장소에 쌓이고** Claude 에 즉시 알림이 갑니다
- Claude 는 안 읽은 것부터 하나씩 가져옵니다 — 빠르게 여러 번 push 해도 순서대로 누적됩니다

#### push 저장소 — 읽어도 사라지지 않습니다

가져간 결과는 삭제되지 않고 **읽음 표시**만 됩니다. 세션 동안 전부 보관되어 자연어로 다시 부를 수 있습니다:

```
"아까 그 bootstrap 결과 다시 보여줘"        → 목차(history)에서 찾아 재조회
"robust 로 돌린 것들만 찾아줘"              → 명령·출력·메모를 키워드 검색
"3번 결과에 '최종 스펙' 메모 달아줘"          → note 부여 (검색 대상)
"지금까지 결과 전부 파일로 저장해"            → 작업폴더에 스냅샷 파일로 저장
"어제 저장한 파일 불러와"                    → 스냅샷 재적재 (이어서 작업)
```

- 결과는 세션 종료 후에도 자동 저장돼, 급히 꺼도 다음 세션에서 이어 볼 수 있습니다
- 서버가 잠시 꺼져 있어도 결과는 보관됐다가 다시 전달됩니다 (유실 없음)

> 알림이 자동으로 안 보이면 채팅에 **"push 결과 봐줘"** 라고 하면 가져옵니다.

### 2-3. 그래프/저장 파일

| 종류 | 어디로 |
|---|---|
| 그래프 | 현재 작업폴더에 `g_...png` (이미지가 필요할 때만 생성 — 자동 저장 안 함) |
| 저장 파일 (`save`/`export` 등) | 사용자가 Stata 에서 지정한 그 경로 |

### 2-4. 도움말 / 환경 조회

Claude 가 Stata 명령을 헷갈릴 때 스스로 확인하는 도구들 — 사용자가 직접 부를 일은 적지만, 자연어로도 활용할 수 있습니다:

```
"xtreg 옵션 뭐 있었지?"                → getHelp("xtreg") — 개요 slice (모델 목록 + 하강 키)
"xtreg fe 의 vce 옵션 자세히"           → getHelp("xtreg","fe.vce") — 그 옵션 상세만 (계단식 하강)
"su 가 무슨 명령이더라"                 → 약어 자동 해석 (su→summarize, Stata 규칙 그대로)
"클러스터 로버스트 관련 명령 찾아줘"      → 로컬 키워드 검색 → 관련 명령 후보 + 한줄설명
"Stata 환경/버전 알려줘"               → getStataEnv — 버전·에디션·경로·이론한계 32항목
```

- 도움말은 온톨로지 DB(노드 4,464개)에서 **필요한 slice 만 계단식 반환** — 기본 호출은 개요(수백 토큰), `selector` 로 모델(`fe`)/옵션그룹(`fe.se`)/옵션상세(`fe.vce`)/`examples`/`stored`/`post.predict` 등 하강. 잘못된 selector 는 그 명령의 유효 selector 목록을 돌려줌. 자세한 문법은 `/stata-help` 스킬 참고
- `mcp_setup` 다운로드 DB 라 **장기 명령이 도는 중에도 즉답**, 조회 시 인터넷 불필요
- SSC 등 커뮤니티 패키지 도움말도 조회 가능 (설치돼 있으면 — 풀네임으로)
- 도움말 DB 는 `mcp_setup, updatedb`(또는 제어판 [Update help DB])로 최신화 (Stata 본체 업데이트에 맞춰 배포측에서 재생성)

### 2-5. 슬래시 명령 스킬 (스킬 등록 시)

스킬([INSTALL.md](INSTALL.md) 4-2)을 등록하면 다음 슬래시 명령이 활성화됩니다.
자연어가 아닌 **명시적 슬래시 호출에만 응답**합니다 (`/stata-exec sysuse auto` 식).

| 명령 | 동작 |
|---|---|
| `/stata-setup` | Stata 환경·작업폴더 점검 + 마운트 경로 확인 + 세션 작업 지침 로드 |
| `/stata-exec <cmd>` | Stata 명령 직접 실행 |
| `/stata-async <cmd>` | 장기 명령 비동기 실행 (즉시 반환, 완료 결과는 `/stata-pull` 로) |
| `/stata-help <cmd> [selector]` | 명령 도움말 계단식 조회 — 개요→모델→옵션 상세 하강 (예: `/stata-help xtreg fe.vce`), 약어·키워드 검색 |
| `/stata-pull` | Stata GUI 에서 push 한 결과 가져오기 |
| `/stata-data-context` | 데이터 변경 후 컨텍스트 재동기화 (pwd·obs·변수) |
| `/stata-data-fullcontext` | 현재 데이터셋 전체 컨텍스트 요약 (codebook 수준) |
| `/stata-graph-get` | 현재 그래프 spec 조회 |
| `/stata-graph-export [name]` | 메모리의 그래프를 PNG 로 export (인자 없으면 현재 그래프) |
| `/stata-instruction` | 세션 작업 지침 로드 (출력형식·분석 규칙·선호; `/stata-setup` 이 자동 호출) — **별도 스킬 설치·사용자 편집용**, [INSTALL.md](INSTALL.md) 4장 |

> **패널 병합 절차 스킬** *(선택 설치)*: 위 슬래시 명령과 달리 자연어로 트리거됩니다. "웨이브 합쳐줘 / 패널 만들어줘 / long 으로 변환" 처럼 요청하면 stata-mcp 로 웨이브별 .dta 를 하나의 long 패널로 합치는 절차(rename→append→xtset·검증)를 안내합니다. 설치는 [INSTALL.md](INSTALL.md) 4장 (`stata-panel-merge.zip`).

### 2-6. 종료

#### 완전 종료 (서버 + 드론)

```stata
mcp_connect, shutdown        // 서버·드론 모두 정지 (제어판 [Shutdown] 버튼과 동일)
```

#### 자동 종료

Stata 를 종료하면 서버도 **~15초 내 자동 종료**됩니다 (드론이 사라지면 서버가 스스로 정지 — 워치독). 이전처럼 좀비 서버가 남지 않습니다.

> 서버만 따로 내리려면 `mcp_server, stop` 도 가능합니다.

---

## 3. 작업폴더(pwd) 변경 감지

Stata 에서 `cd` 로 작업폴더를 옮기면 Claude 가 자동으로 알아차려, 되돌릴지 새 폴더를 유지할지 안내합니다. 작업 지침(`stata-instruction`)에 처리 방식을 적어두면 매번 자동 응대합니다.

---

## 4. 문제 해결

### 첫 실행 시 MCP 서버 승인

새 MCP 서버를 처음 사용할 때 **승인 프롬프트**가 뜹니다 (`Trust this MCP server?` / `Approve` 계열). 승인해야 도구 호출이 되며, 한 번 승인하면 이후 자동입니다.

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

### 연결이 안 될 때

- Stata 에서 `mcp_connect` 을 다시 실행 (드론 재연결)
- 서버가 꺼져 있으면 `mcp_server` 로 다시 기동
- 제어판(`db mcp`)의 **Server status** 버튼으로 상태 확인

