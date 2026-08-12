# 채팅에서 쓰기

코워크 없이 **Claude Desktop 채팅**으로 연결하는 방법입니다.
Stata 측 설치·라이선스·서버 기동([INSTALL.md](INSTALL.md) 1~3장)은 먼저 마쳐야 합니다.

> **먼저 확인** — [INSTALL.md](INSTALL.md) 4-1 의 확장 프로그램(mcpb)을 설치했다면
> 채팅에서도 대부분 그대로 동작합니다 (Node 등 추가 설치 불필요). 확장이 도구
> 목록에 안 보이는 환경에서만 아래의 수동 등록을 사용하세요. 아래 방식은
> Node 22 이상이 필요합니다.

> 스킬([INSTALL.md](INSTALL.md) 4-2)은 채팅에서도 사용할 수 있습니다. 다만 이 스킬들은
> StataMCP 도구를 호출하는 스킬이라, 채팅에서 쓰려면 아래 **설정 파일 등록(MCP 연결)이
> 먼저** 되어 있어야 동작합니다.

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

---

## Claude Code 에서 쓰기 (선택)

위의 등록은 Claude Desktop(채팅·코워크)용입니다. **터미널의 Claude Code 에서도 Stata 를 쓰려면 별도 등록이 필요합니다** — 터미널에서 한 줄 (Mac·Windows 동일, Node 불필요):

```
claude mcp add --transport http StataMCP http://127.0.0.1:8080/mcp --scope user
```

`claude mcp list` 로 확인 — Stata 에서 `mcp_connect` 로 서버가 떠 있으면 `✓ Connected` 로 표시됩니다. (`--scope user` 를 빼면 실행한 폴더에서만 보입니다)

> 위 "방법 A"에서 Claude Code 를 설치 도구로 쓰는 것과는 별개입니다 — 방법 A 는 채팅용 설정 파일을 만들어 주는 것이고, 이 절은 Claude Code 자신에게 등록하는 것입니다.
