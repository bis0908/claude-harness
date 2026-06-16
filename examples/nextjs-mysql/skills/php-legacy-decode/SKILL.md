---
name: php-legacy-decode
description: 원본 PHP 레거시 코드를 체계적으로 분석하는 스킬. PHP 파일에서 라우팅 구조, SQL 패턴, 세션 키, 외부 연동, 비즈니스 로직을 추출하고 Next.js 매핑 초안을 작성한다. legacy-reader 에이전트가 사용한다.
---

## 재발 방지 학습 (작업 전 필독)

이 영역의 과거 분석 추출 누락 사례는 `docs/compound/legacy/README.md` 인덱스에 유형별로 정리돼 있다. 작업 시작 전 그 README를 읽고, 각 유형 파일 **첫 줄 load-when 술어**를 확인하여 현재 분석이 해당하는 사례 파일만 로드하라(전부 읽지 말 것). 사례를 이 SKILL.md에 누적하지 않는 이유는 스킬 로딩 컨텍스트를 상수 크기로 유지하기 위함이다 — compound-learner가 `docs/compound/`에만 기록한다(load-when 술어·인덱스 형식 규범은 `compound` 스킬의 `### Phase 2: docs/compound 작성` 참조).

## 분석 진입점

원본 PHP 코드베이스의 주요 파일부터 파악한다.

| 파일 | 역할 |
|---|---|
| `__common.php` | 전역 부트스트랩 — 세션, DB, 모바일 감지 |
| `__db.php` | mysqli 커넥션 (자격증명 하드코딩 → 환경변수 이관 필요) |
| `header.php` / `footer.php` | 레이아웃 인클루드 |
| `api/*.php` | AJAX 백엔드 핸들러 |
| `func/*.php` | 서버 액션·유틸 |
| `kakaomessage/` | 카카오 알림톡·네이버 비즈톡 발송 |

## 분석 항목별 추출 방법

### 1. 라우팅 구조

- PHP 파일명 = 엔드포인트 (예: `campaign_detail.php?campaign_no=N`)
- GET 파라미터 → Next.js 동적 라우트 또는 searchParams로 매핑
- `include` / `require`로 연결된 파일 체인을 추적한다

**매핑 표 형식**:
```
PHP: campaign_detail.php?campaign_no=N
Next.js: /campaigns/[slug]
메서드: GET
파라미터: campaign_no → slug (M6 슬러그 규칙 적용)
```

### 2. SQL 패턴

- 문자열 보간 SQL (`"SELECT ... WHERE id=$id"`) → "SQL injection 취약, placeholder 변환 필요"로 표시
- `?` placeholder 사용 SQL → 그대로 추출하여 Repository 함수 초안 작성
- `__` prefix 테이블만 대상으로 하고 `alza` 등 제외 테이블은 명시

**추출 형식**:
```sql
-- 원본 (campaign_detail.php:45)
-- 상태: placeholder 변환 필요
SELECT * FROM __campaign WHERE campaign_no = $campaign_no
```

### 3. $_SESSION 키 목록

세션 키는 Auth.js 세션 스키마 설계에 직접 영향을 준다.

추출 대상: `$_SESSION['{key}']` 패턴 전수 수집
```
blogger_no     → user.id
blogger_id     → user.email
blogger_nickname → user.name
```

### 4. 외부 연동

- 카카오 OAuth: 클라이언트 ID/시크릿 → "환경변수 이관 필요"로만 표시
- 네이버 OAuth: 동일
- 카카오 알림톡: `kakaomessage/` 하위 코드 구조 파악
- 구글 AdSense: 코드 위치만 기록

### 5. 비즈니스 로직 분류

| 분류 | 처리 방식 |
|---|---|
| 단순 CRUD | lib/db/*.js Repository 함수로 직역 |
| 상태 전이 로직 | lib/services/*.js Service로 추출 |
| 제거 결정 기능 | "제거 필요 — 이유" 명시 |
| 불명확한 규칙 | "확인 필요 — {질문}" 명시 |

**제거 대상 자동 식별**: 지하철, 주차, 주말, metro, subway, parking, weekend 키워드 포함 로직

### 6. 페이지 섹션 인벤토리

**화면에 표시되는 콘텐츠 섹션**을 페이지별로 열거한다. evaluator가 Next.js 구현과 1:1로 대조하는 기준이 된다.

PHP에서 섹션을 렌더링하는 패턴:
- HTML 블록: `<div id="...">`, `<section class="...">` 직접 마크업
- JS 렌더링 함수: `make_Carousel()`, `make_Requied()`, `make_Provide()` 등 DOM 빌드 함수
- PHP include: `require_once('./partials/campaign_info.php')` 등

각 패턴에서 사용자에게 보이는 **섹션 이름**, **렌더링 방법(함수명/파일)**, **표시 조건**을 추출한다.

**추출 형식**:
```
## 페이지 섹션 인벤토리

### campaign_detail.php (→ /campaigns/[no])
| 섹션 | PHP 렌더링 | 표시 조건 | 포팅 필요 |
|------|-----------|----------|----------|
| 이미지 캐러셀 | make_Carousel() | 항상 | ✓ |
| 필수사항 | make_Requied() | 항상 | ✓ |
| 제공내역 | make_Provide() | 항상 | ✓ |
| 스케줄 안내 | make_Progress() / make_Progress_delivery() | 항상 | ✓ |
| 진행안내 | make_Procedure() | 항상 | ✓ |
| 예약안내 | make_Reservation() | menu != "배송" | ✓ |
| 위치 지도 | load_map() | menu != "배송" | ✗ (지도 라이브러리 미채택) |
| 신청현황 바 | make_ApplyStatus() | 항상 | ✓ |
| 신청 버튼 | make_Button() | 항상 | ✓ |
```

포팅 불필요 섹션(제거 결정)은 `✗` + 이유를 명시한다.

### 7. Datatable 컬럼/액션 인벤토리

페이지 섹션 인벤토리의 한 섹션이 **동적 테이블**(jQuery DataTables, 자체 그리드, AJAX로 행을 채우는 모든 표)인 경우 컬럼·셀 단위 추출을 추가로 수행한다. 페이지 섹션 인벤토리만으로는 행 내부에 숨은 액션(수정/삭제/상세/복사/엑셀/링크)이 전부 잡히지 않기 때문이다.

**추출 대상 식별 단서**: `aoColumns`, `columnDefs`, `fnRender`, `mRender`, `render: function`, `dataTable(`, `DataTable(`, AJAX 응답을 `tbody`에 `append`/`html`로 주입하는 패턴, `<td>` 안의 `<a href>`/`<button onclick>`/`<input type="button">`.

각 동적 테이블마다 아래 표를 작성한다.

**컬럼 인벤토리**:
```
### {페이지}.{테이블 식별자} (예: admin/store_list.php#stores_table)

데이터 소스: AJAX URL 또는 SQL 출처 (예: admin/data/store_list_data.php)
행 식별자: PRIMARY KEY 컬럼 (예: store_no)

| # | 컬럼 헤더 | 데이터 컬럼 | render 패턴 | 셀 내부 액션 | 포팅 필요 |
|---|----------|-----------|------------|------------|----------|
| 0 | 번호 | store_no | plain | - | ✓ |
| 1 | 가게이름 | store_name | `${store_name}<font color="orange">(${store_tel})</font><br>${store_addr}` | - | ✓ |
| 2 | 상태 | store_status | 코드 → 라벨 변환 (`getStatusLabel`) | - | ✓ |
| 3 | 액션 | - | 버튼 묶음 (아래 액션 표) | 수정 / 삭제 / 상세 / 복사 | ✓ |
```

**셀 내부 액션 표** (액션이 있는 컬럼마다 1개씩):
```
#### {페이지}.{테이블}.{컬럼} 액션

| 액션명 | 트리거 | 타깃 URL / 함수 | 파라미터 | 호출 API | 권한 조건 | 포팅 필요 |
|--------|-------|----------------|---------|---------|----------|----------|
| 수정 | `<a href>` | store_edit.php?store_no=N | store_no | - (페이지 이동) | admin | ✓ |
| 삭제 | `<button onclick>` | deleteStore(N) | store_no | POST api/store_delete.php | admin | ✓ |
| 상세 | `<a href>` | store_view.php?store_no=N | store_no | - | admin | ✓ |
| 복사 | `<button onclick>` | copyStore(N) | store_no | POST api/store_copy.php | admin | ✗ (제거 결정 — M22 회의록) |
```

**추출 절차**:
1. 페이지 PHP 파일 또는 부속 JS 파일에서 `dataTable(`/`DataTable(` 초기화 블록을 찾는다 (없으면 AJAX `append`/`html` 패턴으로 대체 검색).
2. `aoColumns` 또는 `columnDefs` 배열을 순서대로 컬럼 인벤토리 표 행으로 옮긴다 — 헤더, 데이터 컬럼, `render`/`fnRender`/`mRender` 함수 본문(축약 가능, 핵심 분기만)을 기록한다.
3. render 함수 본문에서 `<a href>`, `<button onclick>`, `<input type="button">`, `location.href=`, `window.open(`, `$.ajax(`, `fetch(` 호출을 전수 추출하여 액션 표 행으로 옮긴다.
4. 각 액션의 타깃이 페이지 이동인지 API 호출인지 구분한다. API 호출이면 엔드포인트와 HTTP 메서드, 페이로드 키를 기록한다.
5. 권한 조건(`$_SESSION['admin_grade'] == 'master'` 같은 가드)이 액션 분기에 있는지 확인하고 표에 적는다.
6. 형제 페이지가 동일 테이블을 사용하면 render 함수 본문을 라인 단위로 대조한다 (`cross-page-consistency.md` 학습 참조).

**누락 방지 체크**: 추출 후 페이지를 다시 훑어 아래 항목이 인벤토리에 모두 잡혔는지 확인한다.
- 행 호버 시 나타나는 액션, 체크박스 일괄 액션, 페이지 상단 "엑셀 다운로드"·"추가" 같은 테이블 외부 액션
- 셀 값 자체가 링크인 경우(가게이름 클릭 시 상세로 이동 등) — 액션 컬럼이 아니어도 액션
- 조건부 노출 액션 (`if (status === 'pending') 승인 버튼 표시`)

## 산출물 형식

`_workspace/01_legacy_{feature}.md` 파일에 아래 섹션 순서로 작성한다.

```markdown
# {feature} 레거시 분석

## 분석 대상 파일
- 파일명: 역할

## Next.js 라우트 매핑
| PHP | Next.js | 비고 |

## 페이지 섹션 인벤토리
| 페이지 | 섹션 | PHP 렌더링 | 표시 조건 | 포팅 필요 |
|--------|------|-----------|----------|----------|
| /campaigns/[no] | 이미지 캐러셀 | make_Carousel() | 항상 | ✓ |
| /campaigns/[no] | 필수사항 | make_Requied() | 항상 | ✓ |
...

## Datatable 컬럼/액션 인벤토리
(동적 테이블이 있는 페이지에만 작성. 없으면 "해당 없음")

### {페이지}.{테이블 식별자}
데이터 소스: {AJAX URL 또는 SQL}
행 식별자: {PK}

| # | 컬럼 헤더 | 데이터 컬럼 | render 패턴 | 셀 내부 액션 | 포팅 필요 |

#### {페이지}.{테이블}.{컬럼} 액션
| 액션명 | 트리거 | 타깃 URL / 함수 | 파라미터 | 호출 API | 권한 조건 | 포팅 필요 |

## SQL 패턴
(추출된 쿼리 + 상태 표시)

## $_SESSION 키
| 키 | Auth.js 매핑 |

## 외부 연동
(연동명, 위치, 처리 방침)

## 제거 기능
(기능명, PHP 파일:라인)

## 유지 기능
(기능명, Next.js 구현 방향)

## 확인 필요
(질문 목록)
```

## 반환 형식

```markdown
완료 항목:
- _workspace/01_legacy_{feature}.md

미완료 항목:
- <없음 또는 분석 불가 파일>

확인 필요:
- <없음 또는 불명확한 비즈니스 규칙>

다음 단계:
- page-builder / data-layer / tdd-agent 투입 가능

분석 완료: <PHP 파일 또는 기능명>
산출물 경로: _workspace/01_legacy_{feature}.md
에이전트: legacy-reader
```

## 주의사항

- 하드코딩된 자격증명 값은 기록하지 않는다. 위치만 표시한다.
- PHP include 체인이 5단계 이상이면 체인을 명시하고 분석 범위를 오케스트레이터와 협의한다.
- 동일 SQL이 여러 파일에 중복된 경우 대표 파일 하나만 기록하고 "N개 파일에 중복"으로 표시한다.
