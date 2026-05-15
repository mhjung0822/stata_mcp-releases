# Stata MCP 지시사항

## 원칙
- 확인되지 않은 정보는 추측 금지. 새 정보가 필요하면 도구 호출 (이미 조회한 값은 재사용), 실패 시 "확인 불가" 명시

## 세션 시작
- `getStataPwd()` 로 현재 pwd 확인
- 시스템 프롬프트에 마운트 폴더가 있고 Stata pwd 와 다르면 AskUserQuestion 사용자확인
  - question : "stata 작업 경로를 cowork 경로로 변경할까요?"
  - options: ["네", "아니오"]
  - "네" 선택시 : executeStata("cd \"<마운트경로>\"") 실행 → 결과만 알림 (추가 질문 없이)
  - "아니오" → 현재 pwd 유지
- `getVariables()` 로 변수 정보 파악

## 실행 형식
- Stata 명령 실행 전 실행할 명령을 stata 코드블록으로 표시. 예:

  ```stata
  summarize price
  ```

- 실행 결과도 코드블록으로 전체 출력 (임의 생략 금지)

## 그래프
- 응답에 `graphPath` 가 있으면 다음 마크다운으로 표시:
   [<graphFilename>](computer://<graphPath>)
- 인라인 이미지는 띄우지 않음 (Preview 버튼으로 확인)
- 그래프 분석이 필요할 때 AskUserQuestion 으로 사용자 확인:
  - question: "그래프를 Claude 가 인지하고 분석하도록 할까요? (vision 토큰 사용)"
  - options: ["네", "아니오"]
  - "네" 선택 시: `getGraphImage(path: graphPath, maxDim: 800)` 호출
- `getGraphImage` 도구가 비활성이면 사용자에게 알리고 분석 보류

## 작업 도중 pwd 변경
- executeStata 응답에 `pwdChange` 가 있으면 사용자가 작업폴더를 옮긴 것. `pwdChange.to` 가 마운트 폴더와 다르면 사용자에게 마운트로 되돌릴지 질문

## 범주형 변수
- 추정 명령(reg, xtreg, logit 등)의 범주형 설명변수에는 `i.` prefix (value label 있거나 사용자가 범주형으로 정의한 경우)

## 사용자 인터랙션
- 데이터 구조 변경(order/rename/drop/generate/replace/merge/use/reshape 등) 후: AskUserQuestion 으로 "컨텍스트 업데이트" / "나중에" 선택
  - "컨텍스트 업데이트" 선택 시: `getVariables()`, `getObsCount()` 재호출
- 다음 단계가 여러 가지일 때: AskUserQuestion 으로 선택지 제공 (단순 질문보다 선택지 유도)
