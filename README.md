# Stata MCP — Stata × Claude

> English: [README.en.md](README.en.md)

Stata와 Claude를 MCP(Model Context Protocol)로 연결하는 도구의 **공개 배포 저장소**입니다. 주 사용 환경은 **Claude Desktop(채팅, 코워크)**입니다. 소스 코드는 비공개이며, 이 저장소는 빌드된 배포 파일과 사용자 문서만 제공합니다.

설치는 4단계입니다: **① Stata 측 설치 → ② 라이선스 → ③ 서버 기동 → ④ Claude 등록 (확장 + 스킬)**.

설치 후 사용법·문제 해결은 [USAGE.md](USAGE.md) 참고.

---

## 1. 사전 요구 사항

| 항목 | 버전 |
|------|------|
| Stata | 17 이상 (19 권장) |
| Claude Desktop | 최신 — [다운로드](https://claude.ai/download) |

---

## 2. Stata 측 설치

Stata 에서 한 줄:

```stata
net install stata-mcp, from("https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/release") replace
```

jar 2종 + ado/dlg 가 자동 다운로드됩니다. 설치는 이게 전부입니다 — 도움말 DB(~32MB)는 다음 장의 `mcp_connect` 가 처음 연결할 때 받을지 물어봅니다 (y 권장, 인터넷 연결 필요).

업데이트는:

```stata
adoupdate stata-mcp, update
mcp_setup, updatedb
```

- `mcp_setup, updatedb` — 도움말 DB 도 최신으로 (제어판 [Update help DB] 버튼과 동일)

> 업데이트를 적용하려면 **Stata 를 재시작**한 뒤 `mcp_connect` 로 다시 연결하세요.

### 라이선스 키 (필수)

키가 있어야 동작합니다 (발급 문의: mhjung0822@gmail.com). **따로 입력하는 단계는 없습니다** — 다음 장의 `mcp_connect` 가 키가 없으면 물어보므로, 그때 발급받은 키를 붙여넣으면 됩니다.

나중에 키를 교체할 때는 `mcp_set_license` (프롬프트에 붙여넣기) 또는 제어판(`db mcp`)의 **License** 칸 + **Save** → `mcp_connect, reset` 으로 즉시 적용 (Stata 재시작 불필요). 만료된 경우에는 연결 시 출력되는 **[ 라이선스 키 입력 ]** 을 클릭해 붙여넣으면 자동으로 재연결됩니다.

- 키가 없거나 만료되면 드론·서버가 기동하지 않고 Results 창에 사유가 출력됩니다
- 검증에 인터넷 연결 필요 (오프라인은 72시간까지 허용)

> 포트를 바꾸려면 (기본 8080/8001) jar 옆 `stata_mcp.properties` 의 `BRIDGE_PORT`/`DRONE_PORT` 수정 — 파일은 첫 기동 시 자동 생성.

---

## 3. 서버 기동

```stata
mcp_connect
```

MCP 서버와 드론이 한 번에 기동됩니다. 첫 실행이면 라이선스 키와 도움말 DB 다운로드를 차례로 물어봅니다 — 안내를 따라 입력하면 끝.

> Stata 를 종료하면 서버도 자동으로 함께 종료됩니다. 명령 대신 GUI 제어판(`db mcp`)으로도 켤 수 있습니다 — [USAGE.md](USAGE.md) 참고.

> ⚠️ **`java.lang.UnsupportedClassVersionError` 가 붉게 출력되며 드론이 시작되지 않으면** — Stata 내장 Java 가 구버전인 경우입니다. Stata 에서 `update all` 로 최신 업데이트 후 **Stata 재시작** → `mcp_connect` 재실행. 상세는 [USAGE.md](USAGE.md) 문제 해결 참고.

---

## 4. Claude 등록 (코워크)

> Windows 에서 코워크 자체가 켜지지 않는 등 환경 문제는 [TROUBLESHOOTING.md](TROUBLESHOOTING.md) 참고.

### 4-1. 확장 프로그램 설치 (MCP 연결)

1. 자신의 OS 에 맞는 파일 **하나만** 다운로드:
   - Mac: [`stata-mcp-mac.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-mac.mcpb)
   - Windows: [`stata-mcp-win-native.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-win-native.mcpb)
     - 설치가 안 되거나 도구가 나타나지 않으면 [`stata-mcp-win.mcpb`](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-mcp-win.mcpb) 를 대신 설치하세요. 두 개를 동시에 설치하지는 마세요.
2. Claude Desktop → **설정 → 확장 프로그램** → **파일로 설치** → 받은 `.mcpb` 선택
3. Claude Desktop 재시작

> 3장에서 서버(`mcp_connect`)를 먼저 띄워 두어야 도구가 동작합니다. 업데이트는 새 `.mcpb` 파일로 같은 화면에서 다시 설치.

### 4-2. 스킬 등록 (슬래시 명령)

1. [`stata-skills-all.zip` 다운로드](https://raw.githubusercontent.com/mhjung0822/stata_mcp-releases/main/claude-plugins/stata-skills-all.zip)
2. 받은 zip 의 **압축을 풀면** 스킬별 zip 11개가 나옵니다
3. Claude Desktop → **설정 → 스킬** → 업로드 → 압축 푼 **스킬별 zip** 들을 업로드 (묶음 zip 을 그대로 올리지 마세요)
4. 한 번 올리면 같은 계정의 모든 기기에 자동 적용됩니다

스킬 구성과 사용법은 [USAGE.md](USAGE.md) 참고.

---

## 5. 연결 테스트

Stata 와 Claude Desktop 을 모두 **완전 종료**한 상태에서 시작합니다 — Claude 는
창만 닫으면 백그라운드에 남으므로, Windows 는 트레이 아이콘 우클릭 → **Quit**,
Mac 은 **⌘Q** 로 종료하세요. 이후 순서대로:

```
1. Stata 실행 → mcp_connect
2. Claude Desktop 실행
```

이후 새 대화(또는 코워크 세션)에서:

```
Stata 버전 알려줘
```

버전·에디션(예: StataNow/MP 19.5)이 답으로 오면 설치 완료입니다.

안 되면 순서대로 확인하세요:

1. Stata 결과창 — `mcp_connect` 출력에 `License OK` 가 있는지 (없으면 2장 라이선스)
2. Claude 도구 목록 — Stata MCP 확장이 보이는지 (안 보이면 Claude Desktop 완전 종료 후 재실행)

사용법 전반은 [USAGE.md](USAGE.md) 참고 — 시작 순서, 제어판, push 알림, 도움말 조회, 문제 해결. 드문 환경 이슈는 [TROUBLESHOOTING.md](TROUBLESHOOTING.md).


---

## 라이선스

Copyright (c) 2026 mhjung0822.
