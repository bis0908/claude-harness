---
name: mysql2-raw-sql
description: reviewnavi Next.js 포팅의 DB 접근 레이어 구현 스킬. mysql2/promise raw SQL, Repository 패턴, ? placeholder 강제, 식별자 화이트리스트를 적용한다. data-layer 에이전트가 사용한다.
---

## 재발 방지 학습 (작업 전 필독)

이 영역의 과거 실수·gap 사례는 `docs/compound/data-layer/README.md` 인덱스에 유형별로 정리돼 있다. 작업 시작 전 그 README를 읽고, 각 유형 파일 **첫 줄 load-when 술어**를 확인하여 현재 작업이 해당하는 사례 파일만 로드하라(전부 읽지 말 것). 사례를 이 SKILL.md에 누적하지 않는 이유는 스킬 로딩 컨텍스트를 상수 크기로 유지하기 위함이다 — compound-learner가 `docs/compound/`에만 기록한다(`docs/compound/README.md` 참조).

## 파일 단위 구현 규칙

오케스트레이터가 TaskCreate로 등록한 파일 목록과 태스크 ID를 받아 의존 순서대로 구현한다 (`lib/db` → `lib/services` → `app/api`).

### 구현 전 입력 잠금

파일을 수정하기 전에 작업 봉투를 점검한다.

| 항목 | 기준 |
|---|---|
| 목표 | 어떤 데이터 흐름을 완성할지 1문장으로 명확해야 한다 |
| 범위 | 구현 대상 `lib/db`, `lib/services`, `app/api` 파일과 task_id가 있어야 한다 |
| 제외 | 운영 DB 접근 금지, 범위 외 테이블 접근 금지, 티켓 외 기능 추가 금지가 명시되어야 한다 |
| 참조 | 티켓, 레거시 SQL 분석이 있어야 한다. TDD 적용 마일스톤이면 테스트 파일 목록도 있어야 한다 |
| 완료 기준 | 통과해야 할 테스트, API 응답 구조, 보안 조건이 있어야 한다 |

위 항목 중 하나라도 비어 있으면 구현을 시작하지 않고 `확인 필요`로 반환한다. 단, M10처럼 코드가 아니라 결정 문서만 산출하는 data-layer 작업과 오케스트레이터가 TDD 제외로 명시한 작업은 테스트 파일 목록 없이 진행할 수 있다. DB 스키마나 status 의미를 추측하지 않는다.

### 분할 구현 기준

한 번에 처리할 파일이 5개를 초과하면 레이어별로 나눈다.

| 묶음 | 기준 |
|---|---|
| DB 쿼리 | `lib/db/*.js` 또는 `src/queries/*.js` |
| 서비스 | `lib/services/*.js` |
| API Route | `app/api/**/route.js` |
| 테스트 보정 | tdd-agent가 작성한 실패 테스트를 Green으로 만드는 최소 수정 |

레이어 간 계약이 불명확하면 DB 쿼리 함수 시그니처를 먼저 고정한 뒤 서비스와 API를 작성한다.

**각 파일 완료 시 즉시 수행**:
1. `TaskUpdate(task_id, status: "completed")` 호출 — 누락하면 오케스트레이터가 재호출한다
2. 인터페이스 검증:
   - `lib/db/*.js`: export 함수명·파라미터가 services 레이어에서 필요한 것과 일치하는지 확인
   - `lib/services/*.js`: route에서 import할 함수가 전부 export됐는지 grep 확인
   - `app/api/.../route.js`: HTTP 메서드별 핸들러 export + services 호출 경로 확인
3. **절대 다음으로 넘어가지 않을 조건**: `?` placeholder 없는 SQL이 파일에 존재하는 상태

**전체 완료 후 점검** (TaskUpdate 모두 호출한 뒤):
- INSERT 경로와 PATCH 경로의 컬럼 목록이 동일한가 (INSERT-only 누락 패턴)
- DELETE 전 외래키 참조 검사 로직이 있는가
- `validateCampaignPayload` 호출이 POST와 PATCH 양쪽에 있는가
- 동적 SQL의 화이트리스트 검증 코드 존재 여부 grep 재확인

---

## 하드 제약 (위반 시 즉시 중단)

- Prisma, Drizzle, Sequelize, TypeORM 등 ORM 사용 금지
- 모든 SQL은 `mysql2/promise`로 raw SQL 직접 작성
- 동적 파라미터: 반드시 `?` placeholder 사용
- 동적 식별자: 반드시 화이트리스트 방식으로만 허용
- 운영 DB 변경 금지 (dev DB만 사용)

## 커넥션 풀

`lib/db.js` 싱글턴 풀만 사용한다. 새 커넥션 풀 생성 금지.

```js
// lib/db.js (기준 구조)
import mysql from 'mysql2/promise';

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

export async function query(sql, params) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

export async function transaction(fn) {
  const conn = await pool.getConnection();
  await conn.beginTransaction();
  try {
    const result = await fn(conn);
    await conn.commit();
    return result;
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}
```

## 레이어 분리 원칙

```
lib/db/*.js       쿼리 함수만 — 비즈니스 로직 없음
lib/services/*.js 비즈니스 규칙 — 직접 SQL 금지, db/* 호출만
app/api/**        AJAX 필요 기능만 Route Handler로 노출
```

### Repository 패턴 (lib/db/campaign.js 예시)

```js
import { query } from '../db.js';

/** @param {{ page: number, limit: number, category?: string }} params */
export async function getCampaigns({ page = 1, limit = 20, category } = {}) {
  // LIMIT/OFFSET 은 mysql2 prepared statement(query=pool.execute) 로 placeholder
  // 바인딩이 불가하다(ER_WRONG_ARGUMENTS). 정수 캐스팅 후 리터럴로 삽입하고
  // queryRaw(pool.query, text protocol) 를 사용한다. 동적 값은 여전히 ? 바인딩.
  const safeLimit = Math.max(1, Math.floor(Number(limit) || 20));
  const safePage = Math.max(1, Math.floor(Number(page) || 1));
  const safeOffset = (safePage - 1) * safeLimit;
  const params = [];
  let sql = `
    SELECT campaign_id, title, reward_type, status
    FROM __campaign
    WHERE status = 'active'
  `;
  if (category) {
    sql += ' AND category = ?';
    params.push(category);
  }
  sql += ` ORDER BY created_at DESC LIMIT ${safeLimit} OFFSET ${safeOffset}`;
  return queryRaw(sql, params);
}
```

### 식별자 화이트리스트 패턴

```js
const ALLOWED_SORT_COLUMNS = ['created_at', 'reward_point', 'title'];

export async function getCampaignsSorted(sortBy) {
  if (!ALLOWED_SORT_COLUMNS.includes(sortBy)) {
    sortBy = 'created_at'; // 기본값으로 폴백
  }
  return query(`SELECT * FROM __campaign ORDER BY ${sortBy} DESC`, []);
}
```

### Service 패턴 (lib/services/campaign-service.js 예시)

```js
import { getCampaignById } from '../db/campaign.js';
import { getUserApplicationCount } from '../db/progress.js';

export async function checkApplyEligibility(campaignId, userId) {
  const campaign = await getCampaignById(campaignId);
  if (!campaign) return { eligible: false, reason: 'NOT_FOUND' };
  if (campaign.status !== 'active') return { eligible: false, reason: 'INACTIVE' };

  const count = await getUserApplicationCount(userId, campaignId);
  if (count > 0) return { eligible: false, reason: 'ALREADY_APPLIED' };

  return { eligible: true };
}
```

## 트랜잭션 사용 기준

여러 테이블에 걸친 상태 변경은 반드시 트랜잭션으로 처리한다.

```js
import { transaction } from '../db.js';

export async function applyToCampaign(campaignId, userId) {
  return transaction(async (conn) => {
    const [rows] = await conn.execute(
      'SELECT status FROM __campaign WHERE campaign_id = ? FOR UPDATE',
      [campaignId]
    );
    if (rows[0].status !== 'active') throw new Error('INACTIVE');

    await conn.execute(
      'INSERT INTO __progress (campaign_id, user_id, status) VALUES (?, ?, 1)',
      [campaignId, userId]
    );
  });
}
```

## 테이블 범위

- `__` prefix: reviewnavi 메인 테이블 (포팅 대상)
- `mail_` prefix: 발송기 테이블 (M12에서 처리)
- `alza` 등 기타: 이번 포팅 범위 외 — 접근 금지

## 완료 보고 형식

이 형식 그대로 반환해야 오케스트레이터가 파일 목록을 qa-guard·evaluator·milestone-tracker에 전달할 수 있다.

```
완료 항목:
  - lib/db/campaign.js
  - lib/services/campaign-service.js
  - app/api/campaigns/route.js
미완료 항목:
  - 없음
확인 필요:
  - 없음
다음 단계:
  - qa-guard 검증
마일스톤: M{N}
단계: phase-3-impl
에이전트: data-layer
API 목록:
  - GET /api/campaigns — { data: Campaign[] }
  - GET /api/campaigns/[no] — { data: Campaign | null }
  (page-builder에 전달 필요한 엔드포인트만 기재, 없으면 생략)
```
