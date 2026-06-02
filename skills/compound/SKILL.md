---
name: compound
description: 버그 수정, evaluator gap, QA 반복 실패, 디자인 검수 반복 실패 후 학습을 체계화하고, compound-curate 트랙으로 누적분을 무손실 정리(_superseded 격리·원칙 승격)하는 스킬. ce-compound 패턴을 적용. compound-learner 에이전트가 사용하며, bug-fix, eval-gap, qa-repeat, design-repeat 학습 트리거 및 compound-curate 정리 트리거로 실행한다.
---

## 목적

같은 실수가 반복되지 않도록 매 수정 후 예방 패턴을 `docs/compound/{카테고리}/` 에 유형별로 기록한다.
`docs/compound/` 디렉토리가 없으면 첫 학습 시 생성한다.
자가개선 경로: `bug-fixer/evaluator/qa-guard/design-reviewer` → `compound-learner` → `docs/compound/` 갱신 → 다음 작업 시 오케스트레이터 푸시 + SKILL.md 포인터 풀로 해당 사례 로딩.

**SKILL.md 직접 수정 금지.** 과거에는 대상 SKILL.md 의 "자주 발견되는 gap 패턴" 섹션에 누적했으나, 스킬 로딩 컨텍스트 무한 증가 문제로 폐기됐다. 출력은 `docs/compound/` 에만 쓴다. 배경·소비 메커니즘은 `docs/compound/README.md` 참조.

## 추적 트랙

### 버그 트랙 (`bug-fix` 트리거)

bug-fixer 반환 메시지에서 추출:

| 항목 | 추출 방법 |
|------|---------|
| 증상 | "원인:" 바로 위 맥락 |
| 진단 계층 | HTML/CSS/JS/API/DB 중 어느 계층 |
| 수정 파일 | "수정 완료:" 아래 파일 목록 |
| 카테고리 | 이 계층 버그를 예방할 에이전트의 카테고리 (아래 매핑표) |

### 지식 트랙 (`eval-gap` 트리거)

`_workspace/eval_*.md`에서 추출:

| 항목 | 추출 방법 |
|------|---------|
| gap 유형 | "✗ 누락" 또는 "△ 부분" 항목 분류 |
| 카테고리 | 아래 매핑표 참조 |
| 예방 규칙 | gap이 반복되지 않으려면 추가할 규칙 |

### QA 반복 트랙 (`qa-repeat` 트리거)

`_workspace/qa_*.md`에서 추출:

| 항목 | 추출 방법 |
|------|---------|
| 반복 실패 항목 | "실패 항목", "조치 필요", "✗" 항목 중 2회 연속 동일한 파일:라인 또는 규칙 ID |
| 실패 유형 | 보안, 컨벤션, 테스트, 구조적 일관성 중 어느 영역 |
| 카테고리 | 아래 매핑표 참조 |
| 예방 규칙 | 구현 또는 QA 측에 추가할 사전 차단 규칙 |

### 디자인 반복 트랙 (`design-repeat` 트리거)

`_workspace/design_review_*.md`에서 추출:

| 항목 | 추출 방법 |
|------|---------|
| 반복 FAIL 항목 | C-01~C-11 체크리스트 ID 또는 동일 파일:라인 FAIL |
| 실패 유형 | 토큰, hover/focus, 반응형, 접근성, 구조 위임 중 어느 영역 |
| 카테고리 | 아래 매핑표 참조 |
| 예방 규칙 | 구현 또는 디자인 검수 측에 추가할 사전 차단 규칙 |

### 정리 트랙 (`compound-curate` 트리거)

학습이 아니라 **누적분 정리**다. 매핑표를 쓰지 않는다(대상 파일이 이미 카테고리에 있다). 입력: curate-needed 플래그의 대상 `{유형}.md` 목록(온디맨드 시 카테고리 전 유형 파일).

목적: 무손실로 로드 구간(원칙+활성 상단)을 상수에 수렴시킨다. 바이트 감소가 목표가 아니다. SKILL.md 무수정.

**2단계 절차:**

a. **분석**: 대상 `{유형}.md` 를 읽어 ① 중복/근접중복 사례 군집화, ② 한 사례가 다른 사례를 일반화·포괄하는 관계(supersede 관계)를 식별한다.

b. **curate-write (무손실)**:
   - 통합 가능한 규칙을 파일 상단 `## 원칙 (승격)` 섹션에 1~N줄로 승격한다(섹션 없으면 신설). 첫 줄 `> load-when:` 술어는 보존한다.
   - 피지그/중복 구 사례 본문은 **삭제하지 않고** 파일 하단 `## _superseded (로드 불필요)` 섹션으로 이동하고, 각 항목 끝에 `→ 승격 원칙: {요지}` 포인터 1줄을 부착한다.
   - 원칙으로 흡수되지 않은 활성 사례는 `## 활성 사례` 섹션에 잔존시킨다.
   - 카테고리 `README.md` 인덱스 행을 재동기화: "다루는 사례"는 활성+원칙 기준으로 타이트닝, grep 키워드는 합집합 보존(검색 누락 방지).

c. **검증 (무손실 assertion)**: 사례 본문 총량 보존 — `(활성 사례 수 + _superseded 사례 수) == 정리 전 사례 수`. 1건이라도 소실되면 미완료로 보고하고 종료한다(원복 가능 상태 유지).

**불변식**: 어떤 사례 본문도 삭제하지 않는다. SKILL.md 는 어떤 경우에도 열거나 수정하지 않는다.

## Gap 유형 → docs/compound 카테고리 매핑표

학습 결과는 그것을 **소비할 에이전트의 카테고리** 디렉토리에 기록한다.

| gap / 버그 유형 | 카테고리 디렉토리 | 보완 트랙 |
|---|---|---|
| 프론트 조건부 분기·폼 바인딩·라우팅·UI 토큰·렌더링 버그 | `docs/compound/frontend/` | bug-fix, qa-repeat, design-repeat |
| SQL 오류·placeholder·status 필터·페이지네이션·JOIN·컬럼 흐름 | `docs/compound/data-layer/` | bug-fix, eval-gap, qa-repeat |
| 원본 스펙 섹션·플로우·실데이터 연결 누락, 제거/초과 판정 | `docs/compound/evaluation/` | eval-gap |
| QA 검증 절차·선재결함 분리·스모크 누락 | `docs/compound/qa/` | qa-repeat |
| CSS 토큰·hover/focus·반응형·접근성·브랜드 컬러 | `docs/compound/design/` | design-repeat |
| 레거시 소스 분석 추출 누락(섹션 인벤토리·URL 혼용·리다이렉트 래퍼·동반 스키마) | `docs/compound/legacy/` | eval-gap |
| 버그 진단 방법론(계층 진단·실DB 데이터 분기·원본 충실 예외) | `docs/compound/bugfix/` | bug-fix |
| 테스트 계약 고정 오류(placeholder 계약·mock 누락) | `docs/compound/tdd/` | qa-repeat |
| 하네스/오케스트레이터 메타 결함(게이팅 화이트리스트·라우팅 휴리스틱·권한 경계 등 하네스 운영 결정 사항) | `docs/compound/harness/` | bug-fix (메타 확장) |

매핑표에 없는 유형은 가장 가까운 카테고리를 선택하되, 두 카테고리에 동등하게 걸치면 "매핑 모호 — 수동 검토 필요"를 반환하고 종료한다. 원인 자체를 판별할 수 없으면 "매핑 불가 — 수동 검토 필요"를 반환한다.

**권한 경계 — 신 카테고리 신설은 compound-learner 권한 밖.** 매핑표에 없는 새 카테고리가 필요한 사례(예: 하네스 메타 결함)는 오케스트레이터(메인)가 직접 `docs/compound/{새카테고리}/` 디렉토리·README.md·유형 파일을 신설하고, 본 매핑표에 1행을 직접 추가한다. compound-learner에 작업 봉투로 "권한 부여" 우회 위임 금지 — 권한 경계가 모호해지고 단순 파일 생성 작업에 별도 Agent 컨텍스트 비용이 발생한다. compound-learner는 기존 매핑된 카테고리에 사례를 적재하는 작업만 수행한다.

## 2단계 실행

### Phase 1: 분석

1. 보고서 읽기: bug-fixer 반환 메시지 전문, `_workspace/eval_*.md`, `_workspace/qa_*.md`, `_workspace/design_review_*.md` 중 트리거에 맞는 입력을 읽는다.
2. 카테고리 식별: 위 매핑표에서 gap/버그 유형 대조 → `docs/compound/{카테고리}/` 확정.
3. 해당 카테고리 `README.md` 인덱스를 읽어, 추가할 사례가 **기존 유형 파일에 속하는지** 새 유형이 필요한지 판단한다.

### Phase 2: docs/compound 작성 (2-write 원자 단위)

1. **유형 파일 본문 append**:
   - 기존 유형에 속하면 `docs/compound/{카테고리}/{유형}.md` 끝에 사례 1건 추가. 파일 첫 줄 `> load-when:` 술어가 새 사례를 포괄하지 못하면 술어를 확장한다.
   - 새 유형이면 `docs/compound/{카테고리}/{새유형}.md` 를 생성하고 **첫 줄에 `> load-when: <술어 한 줄>`** 을 기재한 뒤 사례를 작성한다(레이아웃 규약은 `docs/compound/README.md` "유형 파일 레이아웃 규약" 참조).
2. **카테고리 README 인덱스 갱신**:
   - 새 유형 파일을 만들었으면 `docs/compound/{카테고리}/README.md` 표에 1행 추가.
   - 기존 유형에 추가했으면 해당 행의 "다루는 사례"·grep 키워드가 새 사례를 포괄하도록 갱신(필요 시).
3. **검증**: 두 파일이 모두 갱신됐는지 확인. 하나만 갱신되면 미완료로 보고.

SKILL.md 파일은 어떤 경우에도 열거나 수정하지 않는다.

## 사례 본문 형식

`docs/compound/README.md`의 "사례 본문 표준 형식"을 따른다.

```
- **{유형 제목} ({M{N} 또는 버그 식별자} 사례)**: {무엇을 놓쳤는가/증상} — {어떻게 예방/판정하는가}. grep 키워드: `키워드1`, `키워드2`.
```

- 학습 4트랙은 기존 사례를 삭제·재구성하지 않고 항목만 추가한다(append-only). `compound-curate` 만 _superseded 격리/원칙 승격을 수행하되 본문은 무손실로 보존한다.
- 본문은 요약하지 말고 재발 방지에 필요한 절차를 그대로 기술한다.
- grep 키워드는 다음 에이전트가 인덱스에서 찾을 수 있도록 구체적으로 작성한다.

## 반환 형식

```markdown
완료 항목:
- docs/compound/{카테고리}/{유형}.md (사례 N건 추가)
- docs/compound/{카테고리}/README.md (인덱스 갱신)

미완료 항목:
- <없음 또는 매핑 불가/모호 항목>

확인 필요:
- <없음 또는 수동 검토 필요 항목>

다음 단계:
- milestone-tracker 갱신 또는 사용자 확인

트랙: <bug-fix | eval-gap | qa-repeat | design-repeat>
카테고리: docs/compound/{카테고리}/
사례 추가: {N}건
에이전트: compound-learner
```

**`compound-curate` 트랙 반환 형식:**

```markdown
완료 항목:
- docs/compound/{카테고리}/{유형}.md (N→M 활성 사례, 승격 원칙 K줄, _superseded (N-M)건 격리)
- docs/compound/{카테고리}/README.md (인덱스 재동기화)

미완료 항목:
- <없음 또는 무손실 검증 FAIL 항목>

확인 필요:
- <없음 또는 수동 검토 필요 항목>

다음 단계:
- 없음 (Phase 5 드레인은 milestone-tracker ✅ 이후이므로 후속 호출 없음) 또는 사용자 확인(온디맨드)

트랙: compound-curate
카테고리: docs/compound/{카테고리}/
무손실 검증: (활성 M + _superseded (N-M)) == 정리 전 N  [PASS/FAIL]
에이전트: compound-learner
```
