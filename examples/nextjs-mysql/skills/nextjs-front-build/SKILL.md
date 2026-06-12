---
name: nextjs-front-build
description: reviewnavi Next.js App Router 프론트엔드 구현 스킬. JavaScript only, 컴포넌트 위치 규칙, shadcn 화이트리스트, Server Component 패턴을 강제한다. page-builder 에이전트가 사용한다.
---

## 재발 방지 학습 (작업 전 필독)

이 영역의 과거 실수·버그 사례는 `docs/compound/frontend/README.md` 인덱스에 유형별로 정리돼 있다. 작업 시작 전 그 README를 읽고, 각 유형 파일 **첫 줄 load-when 술어**를 확인하여 현재 작업이 해당하는 사례 파일만 로드하라(전부 읽지 말 것). 사례를 이 SKILL.md에 누적하지 않는 이유는 스킬 로딩 컨텍스트를 상수 크기로 유지하기 위함이다 — compound-learner가 `docs/compound/`에만 기록한다(load-when 술어·인덱스 형식 규범은 `compound` 스킬의 `### Phase 2: docs/compound 작성` 참조).

## 파일 단위 구현 규칙

오케스트레이터가 TaskCreate로 등록한 파일 목록과 태스크 ID를 받아 순서대로 구현한다.

### 구현 전 입력 잠금

파일을 수정하기 전에 작업 봉투를 점검한다.

| 항목 | 기준 |
|---|---|
| 목표 | 사용자에게 제공할 화면 또는 흐름이 1문장으로 명확해야 한다 |
| 범위 | 구현 대상 파일 목록과 task_id가 있어야 한다 |
| 제외 | 제거 대상 기능과 이번 호출에서 하지 않을 작업이 명시되어야 한다 |
| 참조 | 티켓, 레거시 분석, 디자인가이드.html 중 필요한 문서가 있어야 한다 |
| 완료 기준 | 라우트 접근, 주요 UI 렌더링, 연결 검증 기준이 있어야 한다 |

위 항목 중 하나라도 비어 있으면 구현을 시작하지 않고 `확인 필요`로 반환한다. 추측으로 파일을 만들지 않는다.

### 분할 구현 기준

한 번에 처리할 파일이 6개를 초과하면 의존성이 있는 묶음으로 나눈다.

| 묶음 | 기준 |
|---|---|
| 공통 컴포넌트 | 여러 페이지가 공유하는 UI |
| 전용 컴포넌트 | 특정 route group 내부에서만 쓰는 UI |
| 페이지 | `page.js`, `layout.js`, route-level 조립 |
| 스타일 | 해당 컴포넌트와 1:1로 연결되는 CSS Module |

묶음 사이 의존성이 불명확하면 공통 컴포넌트 → 전용 컴포넌트 → 페이지 → 스타일 보정 순서로 처리한다.

**각 파일 완료 시 즉시 수행**:
1. `TaskUpdate(task_id, status: "completed")` 호출 — 누락하면 오케스트레이터가 재호출한다
2. 연결 검증:
   - Client 컴포넌트: `import` 지점 1개 이상 grep 확인
   - API 엔드포인트: `route.js` 존재 + 호출하는 `fetch` URL grep 확인
   - `page.js`: Next.js 라우터 자동 연결 — 파일 존재만 확인
3. 다음 파일로 이동

**전체 완료 후 점검** (TaskUpdate 모두 호출한 뒤):
- 조건부 렌더링 컴포넌트: 동일 컴포넌트 사용처 전체에 동일 props가 전달되는가 grep 확인
- `'use client'` 누락: `useState`/`useEffect`/`onClick` 사용 파일 전수 확인
- 분기 조건 양방향: `{조건 && ...}`와 `{!조건 && ...}` 블록 양쪽 존재 여부

---

## 하드 제약 (위반 시 즉시 중단)

- `.ts`, `.tsx`, `tsconfig.json` 생성 금지 → `.js`, `.jsx`만 사용
- `jsconfig.json`으로 경로 별칭 설정
- 타입 힌트는 JSDoc으로 작성

## 레이아웃 필수 구조

### (front)/layout.js — sticky footer 패턴

`(front)/layout.js`는 반드시 아래 구조를 갖춰야 한다:

```jsx
// ✅ 필수: flex 컬럼 래퍼 + main에 flex:1
import styles from "./layout.module.css";  // wrap + main 클래스 정의

return (
  <div className={styles.wrap}>    {/* display:flex; flex-direction:column; min-height:100dvh */}
    <Header />
    <main className={styles.main}>{children}</main>  {/* flex:1 */}
    <Footer />
    <BottomNav />
  </div>
);
```

이유: 콘텐츠가 적은 페이지(공지사항 목록 등)에서 Footer가 viewport 위로 올라오는 현상을 방지한다.

## 디렉터리 구조

```
app/
├── (front)/
│   ├── layout.js          헤더·풋터 공통 레이아웃 (sticky footer 패턴 필수)
│   ├── _components/       프론트 전용 컴포넌트
│   ├── campaigns/
│   ├── my/
│   ├── login/
│   ├── register/
│   ├── events/
│   ├── notices/
│   └── contact/
├── (admin)/
│   ├── layout.js          사이드바·어드민 셸
│   └── _components/       어드민 전용 컴포넌트
├── (vip)/
│   ├── layout.js
│   └── _components/
└── _components/           루트 공유 (shadcn 래퍼, 레이아웃 primitives)

components/                프로젝트 전역 디자인 시스템 (M2 산출물)
```

**컴포넌트 위치 결정 기준**:
1. 한 Route Group만 쓰면 → 해당 `_components/`
2. 두 그룹 이상 쓰면 → `components/` (루트 전역)
3. 섹션 간 직접 import 금지 (front ↔ admin 교차 금지)

## shadcn 화이트리스트

허용: `Button`, `Input`, `Select`, `Dialog`, `Sheet`, `Tabs`, `Toast`, `Card`, `Badge`, `Pagination`, `Table`, `Form`

이 목록 외 shadcn 컴포넌트 추가 전 오케스트레이터 승인 필요.

## 컴포넌트 패턴

### Server Component + Client Island

```jsx
// 목록 페이지 기본 구조
// app/(front)/campaigns/page.js
export default async function CampaignsPage({ searchParams }) {
  // DB 조회는 Server Component에서
  const campaigns = await getCampaigns(searchParams);
  return (
    <div>
      <CampaignFilter />          {/* 'use client' — 인터랙션 */}
      <CampaignList items={campaigns} />  {/* Server Component */}
    </div>
  );
}
```

### Form (Server Action)

```jsx
// PHP POST → useActionState + Server Action으로 대체
'use client';
import { useActionState } from 'react';
import { submitApply } from './actions.js';

export function ApplyForm({ campaignId }) {
  const [state, action] = useActionState(submitApply, null);
  return <form action={action}>...</form>;
}
```

### Suspense Boundary

```jsx
import { Suspense } from 'react';
import { CampaignSkeleton } from './_components/CampaignSkeleton.js';

<Suspense fallback={<CampaignSkeleton />}>
  <CampaignDetail id={id} />
</Suspense>
```

## 제거 대상 (구현 금지)

- 지하철역 필터 (`api_metro.php` 대응 기능 포함)
- 주차 가능 여부 아이콘
- 주말 운영 여부 아이콘
- 잡다한 필터·아이콘 (히든 체험, 검색, 카테고리·지역 필터는 유지)

## 파라미터 검증 패턴

```jsx
export default async function CampaignPage({ params }) {
  const { slug } = params;
  if (!slug || typeof slug !== 'string') return notFound();
  // 이후 로직
}
```

## 완료 보고 형식

구현 완료 시 오케스트레이터에 아래 형식으로 보고한다.
이 형식 그대로 반환해야 오케스트레이터가 파일 목록을 design-reviewer·milestone-tracker에 전달할 수 있다.

```
완료 항목:
  - app/(front)/campaigns/page.js
  - app/(front)/campaigns/_components/CampaignCard.js
미완료 항목:
  - 없음
확인 필요:
  - 없음
다음 단계:
  - design-reviewer 검증
마일스톤: M{N}
단계: phase-3-impl
에이전트: page-builder
```
