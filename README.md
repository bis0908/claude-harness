# claude-harness — 전역 에이전트 팀 하네스

PHP→Next.js 포팅 프로젝트(`reviewnavi`)에서 검증된 에이전트 팀 하네스를, **어느 프로젝트에서든 재사용할 수 있는 스택 무관 골격**으로 추출한 저장소다. 검증·학습·추적·조율 역할을 담당하는 에이전트 팀과 그들이 사용하는 스킬, 그리고 팀 전체를 엮는 오케스트레이터를 제공한다.

## 무엇이 들어 있나

```
claude-harness/
├── .claude-plugin/          플러그인 매니페스트 (플러그인 설치 시 사용)
│   ├── plugin.json          플러그인 메타데이터 (name: onemanshow)
│   └── marketplace.json     단일 레포 마켓플레이스 (name: claude-harness)
├── agents/                  골격 에이전트 9종 (스택 무관, 자동 탐색 대상)
│   ├── bug-fixer.md         단발성 버그 진단·수정
│   ├── compound-learner.md  재발 방지 학습 누적·정리
│   ├── design-reviewer.md   시각 스펙·접근성 검수
│   ├── evaluator.md         요구사항 충족 검증 (스펙↔구현 대조)
│   ├── milestone-tracker.md 마일스톤 체크리스트 추적
│   ├── plan-auditor.md      계획 문서 간 정합성 감사
│   ├── qa-guard.md          코드 품질·보안·컨벤션 검증
│   ├── refactor-specialist.md 동작 보존 리팩토링
│   └── tdd-agent.md         실패 테스트(Red) 선작성
├── skills/                  골격 스킬 10종 (각 에이전트의 실행 절차)
│   ├── orchestrate/         ★ 오케스트레이터 — 팀 전체를 조율하는 중앙 스킬
│   ├── bugfix/  compound/  design-review/  evaluate/
│   ├── milestone-track/  plan-audit/  qa/  refactor/  tdd/
├── examples/
│   └── nextjs-mysql/        스택 특화 구현 에이전트·스킬 (참조용 템플릿, 설치 안 함)
│       ├── agents/          data-layer / page-builder / legacy-reader
│       └── skills/          mysql2-raw-sql / nextjs-front-build / php-legacy-decode
├── docs/
│   └── generalization-notes.md  일반화 규칙 (이 골격을 어떻게 추출했나)
├── install.ps1 / install.sh     ~/.claude 전역 복사 설치 스크립트 (플러그인 설치의 대안)
└── README.md
```

### 골격 vs 구현 에이전트

이 골격은 **"누가 언제 무엇을 검증·조율·학습하는가"**를 담는다. 실제로 코드를 작성하는 **구현 에이전트**(프론트·백엔드/DB·API)와 **레거시 분석 에이전트**는 스택마다 다르므로 골격에 포함하지 않는다. 프로젝트에 맞는 구현 에이전트는 두 가지로 마련한다.

1. `examples/nextjs-mysql/`을 복사·변형 (Next.js + MySQL 스택일 때)
2. `harness` 메타 스킬로 새로 생성 (다른 스택일 때)

오케스트레이터는 "프론트 구현 에이전트 / 백엔드 구현 에이전트 / 레거시 분석 에이전트"라는 역할명으로 이들을 호출한다.

## 설치

방식 A(플러그인)와 방식 B(전역 복사 스크립트)는 **상호배타 대안**이다. 둘 다 적용하면 같은 에이전트·스킬이 두 벌(플러그인 네임스페이스 + 전역 bare 이름) 로드되어 충돌하므로, **한 가지만** 사용하라.

### 방식 A — 플러그인 설치 (권장)

이 레포는 자기 자신을 단일 마켓플레이스로 노출한다(`.claude-plugin/`). 새 Claude Code 세션에서 두 명령으로 설치한다.

```text
/plugin marketplace add bis0908/claude-harness
/plugin install onemanshow@claude-harness
```

설치 후 골격 에이전트·스킬은 `onemanshow:` 네임스페이스로 로드된다. 진입은 `/onemanshow:orchestrate <작업>` 으로 한다(스킬 설명의 트리거 문구로 자동 진입도 가능). 플러그인은 `/plugin` UI에서 프로젝트별로 켜고 끌 수 있다.

> **로컬 검증.** 배포 전 `claude plugin validate .` 또는 `claude --plugin-dir .` 로 로드를 확인하라.

### 방식 B — 전역 복사 스크립트 (대안)

전역 설치하면 **모든 프로젝트**에서 골격 에이전트·스킬이 bare 이름으로 자동 로드된다(켜고 끄는 토글 없음).

```powershell
# Windows (PowerShell)
git clone https://github.com/bis0908/claude-harness.git claude-harness
cd claude-harness
./install.ps1            # 복사 설치 (기본)
./install.ps1 -Symlink   # 심볼릭 링크 설치 (repo 갱신이 즉시 반영, 개발자 모드/관리자 필요)
```

```bash
# macOS / Linux
git clone https://github.com/bis0908/claude-harness.git claude-harness
cd claude-harness
./install.sh             # 복사 설치 (기본)
./install.sh --symlink   # 심볼릭 링크 설치
```

설치 후 `~/.claude/agents/`와 `~/.claude/skills/`에 골격이 배치된다. 새 Claude Code 세션에서 `/orchestrate <작업>` 으로 진입한다.

> **전역 로드 주의.** 전역 설치된 스킬·에이전트는 모든 프로젝트에서 항상 활성화된다. 특정 프로젝트에서만 쓰려면 전역 대신 그 프로젝트의 `.claude/`로 복사하라.

> **외부 스킬 의존.** orchestrate 는 커밋 단계에서 외부 `commit` 스킬(`Skill(commit)`)을 가정한다. 이 스킬은 하네스에 포함돼 있지 않으므로, 없는 환경에서는 해당 단계가 해소되지 않는다 — 사용자 전역에 `commit` 스킬을 두거나, 그 단계를 수동 `git commit` 으로 대체하라.

## 새 프로젝트에 적용하는 법

1. **골격 설치** — 위 설치 스크립트 (1회).
2. **구현 에이전트 추가 + 역할 바인딩 선언** — `examples/nextjs-mysql/`을 프로젝트 `.claude/`에 복사하거나, `harness` 메타 스킬로 스택에 맞는 구현 에이전트를 생성. 그리고 오케스트레이터가 호출하는 3개 역할(프론트 구현 / 백엔드 구현 / 레거시 분석 에이전트)이 **실제 어떤 에이전트 이름인지**를 프로젝트 `CLAUDE.md`에 1줄 매핑으로 선언한다. examples를 그대로 쓰면 기본 바인딩(page-builder / data-layer / legacy-reader)이 적용된다. (상세는 `skills/orchestrate/SKILL.md` 상단 "역할 → 실제 에이전트 이름 바인딩" 참조.)
3. **컨벤션 정의** — 프로젝트 `CLAUDE.md`에 언어·라이브러리·컴포넌트 컨벤션을 적는다. qa-guard가 이를 읽어 검증한다.
4. **(선택) 작업 인프라** — 마일스톤을 쓰면 `docs/progress/`·`docs/02-roadmap/`을, 재발 방지 학습을 쓰면 `docs/compound/`를 둔다. 없어도 골격은 graceful-skip 하거나 첫 사용 시 생성한다.

## 외부 경로 컨벤션 (없으면 graceful-skip)

골격은 아래 경로를 작업 산출물의 기본 컨벤션으로 사용하되, 없는 프로젝트에서 깨지지 않는다. 상세는 `docs/generalization-notes.md` 참조.

| 경로 | 용도 | 부재 시 |
|------|------|---------|
| `_workspace/` | 에이전트 간 중간 산출물 | 첫 사용 시 생성 |
| `docs/progress/milestone-status.md` | 마일스톤 체크리스트 | 로드맵 있으면 생성, 없으면 최소 골격 |
| `docs/compound/{카테고리}/` | 재발 방지 학습 | 첫 학습 시 생성 |
| `docs/02-roadmap/*` | 로드맵·티켓 | 있으면 참조, 없으면 "근거 부재" 명시 |

## 라이선스

원본 하네스 패턴은 `harness` 플러그인(Apache-2.0)에서 파생했다.
