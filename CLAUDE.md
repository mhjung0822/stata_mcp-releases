# stata_mcp-releases — Claude 작업 지침

## 출력 언어

- **항상 한국어로 출력한다.**

## 문서 소유권 (중요)

- **이 repo 가 사용자 문서의 단일 원본**: README.md / INSTALL.md / USAGE.md. 직접 작성·수정한다.
- 기술/개발 문서 (아키텍처, CHANGELOG, 빌드)는 **stata_mcp_java repo** 소관 — 여기 두지 않는다.
- main repo 의 docs sync CI 는 폐기됨 (2026-06-11) — 자동 덮어쓰기 없음. 이 repo 문서를 main 측 내용으로 교체하지 말 것.

## 작업 방식

- 편집/커밋/푸시는 사용자가 명시 지시할 때만. main 직접 푸시 = 즉시 공개 반영임을 유의.
- jar / ado 갱신은 stata_mcp_java 쪽 빌드 산출물을 복사해 오는 방식 (이 repo 에서 빌드하지 않음).
