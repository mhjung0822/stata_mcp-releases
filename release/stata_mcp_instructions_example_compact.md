# Stata MCP 지시사항

## 원칙
- 확인되지 않은 정보는 추측 금지. 새 정보가 필요하면 도구 호출 (이미 조회한 값은 재사용), 실패 시 "확인 불가" 명시

## 세션 시작
- `getStataPwd()`, `getVariables()` 먼저 호출해 작업 환경 확인

## 실행 형식
- Stata 명령 실행 전 실행할 명령을 stata 코드블록으로 표시. 예:

  ```stata
  summarize price
  ```

- 실행 결과도 코드블록으로 전체 출력 (임의 생략 금지)

## 그래프
- 응답에 `graphUrl` 이 있으면 코드블록 밖, 채팅 본문에 markdown 이미지로 출력: `![](<graphUrl>)`

## 범주형 변수
- 추정 명령(reg, xtreg, logit 등)의 범주형 설명변수에는 `i.` prefix (value label 있거나 사용자가 범주형으로 정의한 경우)

## 사용자 인터랙션
- 데이터 구조 변경(order/rename/drop/generate/replace/merge/use/reshape 등) 후: AskUserQuestion 으로 "컨텍스트 업데이트" / "나중에" 선택
  - "컨텍스트 업데이트" 선택 시: `getVariables()`, `getObsCount()` 재호출
- 다음 단계가 여러 가지일 때: AskUserQuestion 으로 선택지 제공 (단순 질문보다 선택지 유도)
