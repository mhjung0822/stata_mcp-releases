# 설치 가이드

설치는 4단계입니다: **① Stata 측 설치 → ② 라이선스 → ③ 서버 기동 → ④ Claude 등록 (확장 + 스킬)**.
주 사용 환경은 **Claude Desktop 코워크**입니다.

> ⚠️ **코워크가 활성화되지 않은 환경 주의** — 4-1 확장 프로그램은 코워크 전용입니다.
> 채팅으로 쓰려면 [부록 — 채팅에서 쓰기](#부록--채팅에서-쓰기)의 설정 파일 등록을 하세요.
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

---

## 부록 — 채팅에서 쓰기

> 스킬(4-2)은 채팅에서도 사용할 수 있습니다. 다만 이 스킬들은 StataMCP 도구를
> 호출하는 스킬이라, 채팅에서 쓰려면 아래 **설정 파일 등록(MCP 연결)이 먼저**
> 되어 있어야 동작합니다.

### 방법 A — Claude Code 에 맡기기 (Windows 권장)

설정 파일 경로·JSON 병합이 번거로우면 **Claude Code** 를 열고 아래를 그대로 붙여넣으세요:

> **먼저 준비물 — Git for Windows.** Claude Desktop 앱에서 **로컬 세션(Claude Code)** 을 열려면 필요합니다.
> [git-scm.com/downloads/win](https://git-scm.com/downloads/win) 에서 받아 **전부 기본값으로 "다음"만 눌러** 설치하세요.
> (설치에 관리자 권한이 필요할 수 있음 — 막히면 IT 부서에 "Git for Windows 설치" 요청)

```
https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/AGENT_INSTALL.md
이 문서 읽고 Stata MCP 설치해줘.
```

Claude Code 가 처리: 설정 파일 위치 찾기·생성·**기존 내용 보존 병합**, `mcpServers` 등록, 사내망이면 인증서 옵션 추가, Node/Java 확인, 서버 상태 검증.
사용자가 직접: Stata 안에서 명령 붙여넣기 (Claude Code 가 알려줌 — Stata 는 외부에서 못 조작).

### 방법 B — 직접 등록

**① 설정 파일(`claude_desktop_config.json`) 열기** — **반드시 Claude 메뉴로**

Claude Desktop → **Settings(설정)** → **Developer(개발자)** 탭 → **Edit Config** 버튼
→ 파일탐색기가 열리며 `claude_desktop_config.json` 이 보임 → 텍스트 에디터로 열기 (파일이 없으면 이 폴더에 새로 만들기 — 메모장 저장 시 파일형식 "모든 파일")

> ⚠️ **폴더를 직접 찾아가지 마세요.** 설정 파일 위치는 PC 마다 다릅니다. 직접 찾아가면 **파일이 없어서 새로 만들게 되는데, 그건 앱이 읽지 않는 파일입니다** — 저장은 되는데 아무 일도 안 일어납니다. 이 버튼은 항상 맞는 파일을 열어줍니다.

**② 내용 붙여넣기** — 파일이 비었으면 통째로, 이미 내용이 있으면 `mcpServers` 항목만 병합

Windows:

```json
{
  "mcpServers": {
    "StataMCP": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "mcp-remote", "http://127.0.0.1:8080/mcp"]
    }
  }
}
```

Mac:

```json
{
  "mcpServers": {
    "StataMCP": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://127.0.0.1:8080/mcp"]
    }
  }
}
```

**③ 사내망/보안 PC — 인증서 오류(`UNABLE_TO_VERIFY_LEAF_SIGNATURE`) 시**

회사·기관 PC 는 보안 설정 때문에 필요한 파일을 못 받아올 수 있습니다. 로그에 `unable to verify the first certificate` 가 뜨면 `env` 를 추가:

```json
{
  "mcpServers": {
    "StataMCP": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "mcp-remote", "http://127.0.0.1:8080/mcp"],
      "env": { "NODE_OPTIONS": "--use-system-ca" }
    }
  }
}
```

**Node 22 이상**이 필요합니다. 그래도 안 되면:
- **회사 인증서 파일 지정**: `"env": { "NODE_EXTRA_CA_CERTS": "C:\\경로\\회사인증서.pem" }` (IT 부서에서 받은 파일)
- **빠른 우회(보안↓·비권장)**: cmd 에서 `npm config set strict-ssl false`

**④ 저장 후 Claude Desktop 완전 재시작** — 창만 닫지 말고 완전히 종료(Windows: 트레이 아이콘 우클릭 → Quit / Mac: ⌘Q) 후 다시 실행. 그리고 Stata 에서 `mcp_connect` 로 서버가 떠 있어야 도구가 동작합니다.
