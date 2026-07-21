# 설치 가이드

> English: [INSTALL.en.md](INSTALL.en.md)

설치는 4단계입니다: **① Stata 측 설치 → ② 라이선스 → ③ 서버 기동 → ④ Claude 등록 (확장 + 스킬)**.
주 사용 환경은 **Claude Desktop 코워크**입니다.

> ⚠️ **코워크가 활성화되지 않은 환경 주의** — 4-1 확장 프로그램은 코워크 전용입니다.
> 채팅으로 쓰려면 [INSTALL_CHAT.md](INSTALL_CHAT.md)의 설정 파일 등록을 하세요.
> (스킬 등록 4-2 는 공통)

배포 파일 목록은 [README.md](README.md), 설치 후 사용법·문제 해결은 [USAGE.md](USAGE.md) 참고.

---

## 1. 사전 요구 사항

| 항목 | 버전 |
|------|------|
| Java | 17 이상 — [Oracle JDK 17 다운로드](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) |
| Stata | 17 이상 (19 권장) |
| Claude Desktop | 최신 — [다운로드](https://claude.ai/download) |
| Node.js | v20 이상 — [nodejs.org 다운로드](https://nodejs.org/) |

---

## 2. Stata 측 설치

Stata 에서 한 줄:

```stata
net install stata-mcp, ///
    from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") ///
    replace
```

jar 2종 + ado/dlg 가 자동 다운로드됩니다. 이어서 **`mcp_setup`** 으로 도움말 DB 를 받고 제어판 메뉴를 등록합니다 (설치 후 1회):

```stata
mcp_setup            // 도움말 DB(~32MB) 다운로드 + User 메뉴 등록
```

> 도움말 DB 는 용량이 커서 net install 번들 대신 `mcp_setup` 이 온디맨드로 받습니다 (패키지 경량화). 인터넷 연결 필요.

업데이트는:

```stata
adoupdate stata-mcp, update
mcp_setup, updatedb   // 도움말 DB 도 최신으로 (제어판 [Update help DB] 버튼과 동일)
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
mcp_connect          // MCP 서버 + 드론 기동 (한 번에)
```

> Stata 를 종료하면 서버도 자동으로 함께 종료됩니다. 명령 대신 GUI 제어판(`db mcp`)으로도 켤 수 있습니다 — [USAGE.md](USAGE.md) 참고.

---

## 4. Claude 등록 (코워크)

> **Windows 에서 코워크가 활성화되지 않으면** — "가상 머신 플랫폼" Windows 기능이
> 필요합니다. **관리자 PowerShell** 에서 아래 입력 후 엔터, 그리고 **재부팅**:
>
> ```powershell
> Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
> ```
>
> 재부팅 후 Claude Desktop 에서 코워크를 켜세요. 그래도 안 되면 BIOS 에서
> 하드웨어 가상화(Intel VT-x / AMD SVM)가 꺼져 있는 경우입니다 — 작업 관리자 →
> 성능 → CPU 의 "가상화" 항목으로 확인할 수 있습니다.

### 4-1. 확장 프로그램 설치 (MCP 연결)

1. 자신의 OS 에 맞는 파일 **하나만** 다운로드:
   - Mac: [`stata-mcp-mac.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-mac.mcpb)
   - Windows: [`stata-mcp-win.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-win.mcpb)
2. Claude Desktop → **설정 → 확장 프로그램** → **파일로 설치** → 받은 `.mcpb` 선택
3. Claude Desktop 재시작

> 3장에서 서버(`mcp_connect`)를 먼저 띄워 두어야 도구가 동작합니다. 업데이트는 새 `.mcpb` 파일로 같은 화면에서 다시 설치.

### 4-2. 스킬 등록 (슬래시 명령)

1. [`stata-skills-all.zip` 다운로드](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-skills-all.zip)
2. Claude Desktop → **설정 → 스킬** → 업로드 → 받은 zip 선택
3. 한 번 올리면 같은 계정의 모든 기기에 자동 적용됩니다

포함 스킬:

- **슬래시 명령 9종** — `/stata-exec` `/stata-async` `/stata-pull` `/stata-help` `/stata-setup` `/stata-graph-get` `/stata-graph-export` `/stata-data-context` `/stata-data-fullcontext`
- **stata-instruction** (편집해서 쓰는 항목) — 출력형식·분석 규칙·선호를 세션에 적용. 설치 후 옵션에서 내용 편집 (또는 Claude 에게 수정 요청)
- **stata-panel-merge** — 웨이브(차수)별 .dta 를 long 패널로 합치는 표준 절차. "웨이브 합쳐줘 / 패널 만들어줘" 같은 자연어로 트리거

---

## 5. 다음 단계

[USAGE.md](USAGE.md) — 시작 순서, 제어판, push 알림, 도움말 조회, 문제 해결.
