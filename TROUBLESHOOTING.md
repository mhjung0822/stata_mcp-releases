# 기타 환경 이슈

자주 겪지는 않지만 특정 환경에서 나타나는 문제들입니다. 일반적인 사용 문제는 [USAGE.md](USAGE.md)의 "문제 해결" 참고.

---

## Windows 에서 코워크 자체가 활성화되지 않을 때

최신 Claude Desktop 은 대부분의 PC 에서 별도 설정 없이 코워크가 동작합니다.
**코워크 자체가 켜지지 않는 일부 환경**에서만 아래를 확인하세요.

**현재 상태 확인** — cmd 에서:

```
systeminfo | findstr Hyper
```

- `하이퍼바이저가 검색되었습니다` 한 줄 → 가상화 문제 아님 (다른 원인)
- `펌웨어에 가상화 사용: 아니요` → BIOS 에서 하드웨어 가상화를 켜야 합니다 (아래)
- 모두 `예` 인데 위 한 줄이 없으면 → "가상 머신 플랫폼" 활성화 후 재부팅 필요 (아래)

**가상 머신 플랫폼 켜기** — 관리자 PowerShell 에서 실행 후 **재부팅**:

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
```

**BIOS 하드웨어 가상화** — 위를 해도 안 되면 BIOS 에서 가상화(Intel VT-x / AMD SVM)가
꺼져 있는 경우입니다. 작업 관리자 → 성능 → CPU 의 "가상화" 항목이 "사용 안 함"이면
부팅 시 BIOS 에 진입해 해당 항목을 켜세요 (제조사별 진입 키 상이 — 보통 F2/Del).

## 코워크에서 Stata 커넥터가 안 보일 때

1. **Stata 쪽 서버가 떠 있는지 먼저** — Stata 에서 `mcp_connect` 실행 후 다시 시도
2. 로그인 직후에는 커넥터가 몇 분간 안 보일 수 있습니다 — 잠시 후 새 세션으로 재시도
3. 그래도 안 보이면 Claude Desktop 을 완전히 종료(트레이 → Quit) 후 재실행
