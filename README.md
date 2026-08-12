# Stata MCP — Stata × Claude

> English: [README.en.md](README.en.md)

Stata와 Claude를 MCP(Model Context Protocol)로 연결하는 도구의 **공개 배포 저장소**입니다. 주 사용 환경은 **Claude Desktop 코워크**입니다. 소스 코드는 비공개이며, 이 저장소는 빌드된 배포 파일과 사용자 문서만 제공합니다.

설치는 4단계입니다: **① Stata 측 설치 → ② 라이선스 → ③ 서버 기동 → ④ Claude 등록 (확장 + 스킬)**.

> 4-1 확장 프로그램 하나로 **코워크와 채팅 모두** 동작합니다. 확장이 도구 목록에
> 보이지 않는 환경에서만 [INSTALL_CHAT.md](INSTALL_CHAT.md)의 수동 등록을 사용하세요.
> (스킬 등록 4-2 는 공통)

설치 후 사용법·문제 해결은 [USAGE.md](USAGE.md) 참고.

---

## 1. 사전 요구 사항

| 항목 | 버전 |
|------|------|
| Java | 별도 설치 불필요 — Stata 에 내장된 Java 를 사용합니다 (Stata 17 은 내장 Java 가 구버전이라 [JDK 17+](https://www.oracle.com/java/technologies/javase/jdk17-archive-downloads.html) 설치 필요) |
| Stata | 17 이상 (19 권장) |
| Claude Desktop | 최신 — [다운로드](https://claude.ai/download) |
| Node.js | 불필요 — 확장(mcpb) 설치 기준. 설정 파일 수동 등록 시에만 필요 ([INSTALL_CHAT.md](INSTALL_CHAT.md)) |

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

> 업데이트를 적용하려면 **Stata 를 재시작**한 뒤 `mcp_connect` 로 다시 연결하세요.

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

> ⚠️ **`java.lang.UnsupportedClassVersionError` 가 붉게 출력되며 드론이 시작되지 않으면** — Stata 내장 Java 가 구버전인 경우입니다. Stata 에서 `update all` 로 최신 업데이트 후 **Stata 재시작** → `mcp_connect` 재실행. 상세는 [USAGE.md](USAGE.md) 문제 해결 참고.

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
>
> **현재 상태 확인** — cmd 에서:
>
> ```
> systeminfo | findstr Hyper
> ```
>
> - `하이퍼바이저가 검색되었습니다` 한 줄 → 준비 완료 (가상화 문제 아님)
> - `펌웨어에 가상화 사용: 아니요` → BIOS 에서 VT-x/SVM 을 켜야 합니다
> - 모두 `예` 인데 위 한 줄이 아니면 → 재부팅이 아직 안 된 상태입니다

### 4-1. 확장 프로그램 설치 (MCP 연결)

1. 자신의 OS 에 맞는 파일 **하나만** 다운로드:
   - Mac: [`stata-mcp-mac.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-mac.mcpb)
   - Windows: [`stata-mcp-win.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-win.mcpb)
2. Claude Desktop → **설정 → 확장 프로그램** → **파일로 설치** → 받은 `.mcpb` 선택
3. Claude Desktop 재시작

> 3장에서 서버(`mcp_connect`)를 먼저 띄워 두어야 도구가 동작합니다. 업데이트는 새 `.mcpb` 파일로 같은 화면에서 다시 설치.

### 4-2. 스킬 등록 (슬래시 명령)

1. [`stata-skills-all.zip` 다운로드](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-skills-all.zip)
2. 받은 zip 의 **압축을 풀면** 스킬별 zip 11개가 나옵니다
3. Claude Desktop → **설정 → 스킬** → 업로드 → 압축 푼 **스킬별 zip** 들을 업로드 (묶음 zip 을 그대로 올리지 마세요)
4. 한 번 올리면 같은 계정의 모든 기기에 자동 적용됩니다

포함 스킬:

- **슬래시 명령 9종** — `/stata-exec` `/stata-async` `/stata-pull` `/stata-help` `/stata-setup` `/stata-graph-get` `/stata-graph-export` `/stata-data-context` `/stata-data-fullcontext`
- **stata-instruction** (편집해서 쓰는 항목) — 출력형식·분석 규칙·선호를 세션에 적용. 설치 후 옵션에서 내용 편집 (또는 Claude 에게 수정 요청)
- **stata-panel-merge** — 웨이브(차수)별 .dta 를 long 패널로 합치는 표준 절차. "웨이브 합쳐줘 / 패널 만들어줘" 같은 자연어로 트리거

---

## 5. 다음 단계

[USAGE.md](USAGE.md) — 시작 순서, 제어판, push 알림, 도움말 조회, 문제 해결.


---

## 라이선스

Copyright (c) 2026 mhjung0822.
