# 저빈도 입력 분기 처리 경로

> **언제 읽는가**: Phase 0 "입력 유형 분기" 표에서 입력이 **compound 정리/정돈 요청** 또는 **계획 정합성 검증 요청**으로 판별돼 해당 경로로 이탈할 때만 읽는다. 두 경로 모두 마일스톤 파이프라인(Phase 1~5)에 진입하지 않는 저빈도 비파이프라인 진입이므로, 평상시 파이프라인 진행에는 로드하지 않는다. (버그 경로·재개 프롬프트 경로는 본문에 유지 — 빈출이거나 컨텍스트 감시 루프와 결합돼 있음.)

## compound-curate 온디맨드 처리 경로

1. 오케스트레이터 파이프라인(Phase 1~5)을 실행하지 않는다.
2. `Agent(compound-learner, 트랙: compound-curate, 대상: 요청에 명시된 카테고리/유형 목록 — 없으면 전 카테고리)` 를 직접 호출한다. Phase 5 드레인과 달리 사용자 응답이 필요하므로 `run_in_background` 없이 동기 호출한다.
3. 반환된 정리 결과(각 `{유형}.md` N→M 활성, 승격 원칙 K줄, 무손실 검증 PASS/FAIL)를 사용자에게 요약 보고하고 종료한다.

> 이유: 누적분 정리는 마일스톤 파이프라인과 무관한 유지보수 작업이다. evaluator `approved` 와 무관하게 발동하며, _superseded 격리/원칙 승격은 compound-learner의 `compound-curate` 트랙만 수행한다(무손실 불변식 — `compound` 스킬 `### 정리 트랙` 절 참조).

## 계획 정합성 검증 요청 시 처리 경로

1. 오케스트레이터 파이프라인(Phase 1~5)을 실행하지 않는다.
2. `Agent(plan-auditor)` 를 직접 호출한다 — 감사 대상 마일스톤 번호(또는 "전체")와, 관련 정본 경로(체크리스트·작업 로그·근거 audit 보고서)를 전달한다. 사용자 응답이 필요하므로 `run_in_background` 없이 동기 호출한다.
3. plan-auditor 반환 보고서(`_workspace/plan_audit_*.md`)의 결함 목록과 3등급 분류(결함 아님 / 문서 수정 / 재판단 필요)를 사용자에게 요약 보고한다.
4. 사용자가 정본 수정을 승인하면 `Agent(milestone-tracker)` 에 구체적 수정 지시를 위임한다. plan-auditor 는 정본을 직접 수정하지 않는다 — `milestone-status.md` 는 milestone-tracker 단일 관할이다.
5. 다음 스텝 제안과 함께 재개 프롬프트를 동반 출력하고 종료한다.

> 이유: 계획 정합성 감사는 마일스톤 파이프라인과 무관한 진단 작업이다. 코드↔스펙 검증(evaluator)이나 체크리스트 갱신(milestone-tracker)과 달리, 계획 문서들끼리의 수평 정합성(drift·staleness·중복·분류 오류·진술 오류)을 본다. 정본 수정은 milestone-tracker에 위임하여 단일 관할을 유지한다(DRY).
