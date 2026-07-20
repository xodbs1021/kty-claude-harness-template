# ADR-0002: 전역 에이전트 층(global-agents/) — 정본은 템플릿 repo, 배포는 ~/.claude/agents/

**Date**: 2026-07-20
**Status**: accepted
**Deciders**: 김태윤(3층 배치·reporter 기각 결정), Claude(조사·구현)

## Context

리서치 워크플로우용 에이전트 2종(research-collector 수집 · research-evaluator 독립 평가)을 추가하려는데, 기존 하네스의 두 배치 방식이 모두 안 맞았다:

1. **템플릿 글루**는 `install.sh <프로젝트>`로 프로젝트 안(`.claude/agents/`)에만 설치된다. 그러나 리서치는 특정 프로젝트가 아니라 **아무 세션에서나** 쓰인다 — 프로젝트마다 설치하는 것은 용도와 어긋난다.
2. **전역 디렉토리**(`~/.claude/agents/`)에 직접 쓰면 모든 세션에서 보이지만, 그 디렉토리는 **버전 관리가 안 된다** — 이력·리뷰·sync 전파가 불가능하다.

부수 결정 두 가지도 함께 확정됐다: 하네스 자체에 대한 ADR을 어디에 둘 것인가(이 문서의 위치 문제), 그리고 보고(reporter) 에이전트를 만들 것인가.

## Decision

**3층 배치:** 정본 = 템플릿 repo `global-agents/`(git 버전 관리) → `install.sh`/`sync.sh`가 `~/.claude/agents/`로 복사 배포(글루 원칙: 덮어씀, 디렉토리 없으면 무동작) → 소비 = 모든 세션의 Agent 도구.

ECC 패턴(외부 repo가 정본 → 사용자가 전역 설치)의 **역방향 적용**이다: 우리 repo가 정본이 되어 우리 전역 디렉토리로 배포한다. 전역 디렉토리는 버전 관리가 안 되므로 정본은 반드시 repo가 가진다.

**ADR 위치 원칙(이 문서부터 적용):** 프로젝트 도메인 결정 → 그 프로젝트 `docs/decisions/`, 하네스 자체 결정 → 템플릿 repo `docs/decisions/`. ADR-0001(메모리 3계층)도 주제가 하네스 자체이므로 chat 프로젝트에서 이 repo로 이관했다(번호 연속성 유지).

**reporter 에이전트는 만들지 않는다:** evaluator를 분리한 가치는 **독립성**(자기 수집물에 관대해지는 것 방지)이지만, 보고서의 가치는 반대로 **사용자의 결정 맥락**(환경·우선순위)을 아는 것이고 그 맥락은 메인 세션 대화에 있다. 보고서는 메인 세션이 규격(결론 먼저 · 비교표 · 상세 · 반대 근거 병기 · 신뢰도 태그)대로 작성한다 — 형식=규격, 작성자=메인 세션.

## Alternatives Considered

### 1. 프로젝트 글루로 배치 (기존 template/.claude/agents/)
- **Pros**: 기존 install/sync 인프라 그대로
- **Cons**: 리서치는 프로젝트 무관 — 쓰려면 아무 프로젝트나 열고 설치해야 함
- **Why not**: 용도(아무 세션)와 배치(프로젝트 안)가 어긋난다

### 2. ~/.claude/agents/에 직접 작성 (정본=전역 디렉토리)
- **Pros**: 배포 단계 자체가 없음
- **Cons**: 버전 관리·이력·리뷰 불가, 기기 간 동기화 불가, 실수로 덮으면 복구 불가
- **Why not**: 정본은 repo가 가진다 — 하네스 운영 모델의 기본 전제

### 3. 별도 전역 에이전트 repo 신설
- **Pros**: 관심사 분리가 명시적
- **Cons**: repo 하나 더 관리, install/sync 인프라 재발명
- **Why not**: 템플릿 repo가 이미 "에이전트 정본 + 배포 스크립트"를 갖고 있다(YAGNI)

### 4. (부수) 보고 전담 reporter 에이전트 신설
- **Pros**: 파이프라인 대칭성(수집→평가→보고)
- **Cons**: 서브에이전트는 사용자의 결정 맥락(환경·우선순위·대화 이력)이 없는 컨텍스트에서 보고서를 쓰게 됨
- **Why not**: 분리의 근거가 정반대다 — evaluator는 맥락 없음이 장점(독립성), reporter는 맥락 없음이 치명상

## Consequences

### Positive
- 전역 에이전트도 git 이력·리뷰·sync 전파를 얻는다 — 개선이 커밋으로 축적
- 새 기기 온보딩 = repo clone + install 1회
- 리서치 결과물의 신뢰 구조(수집/평가 분리 + 메인 세션 보고)가 에이전트 정의로 고정

### Negative
- install/sync가 프로젝트 밖(`~/.claude/`)을 건드리게 됨 — 부작용 범위 확대. 완화: echo로 배포 사실 명시, 디렉토리 없으면 무동작
- `~/.claude/agents/`의 타 출처 에이전트(ECC 설치본 67종)와 이름 충돌 위험. 완화: `research-*` 접두 네임스페이스, 추가 시 기존 이름 전수 확인
- 전역 배포는 install/sync 실행 시점에만 갱신 — repo 커밋과 전역 실물이 어긋난 채로 세션이 뜰 수 있다(sync 습관 필요)

## 구현

템플릿 repo: `global-agents/{research-collector,research-evaluator}.md` + install.sh 1b 스텝 + sync.sh 미리보기. 에이전트 설계: 기존 설치 스킬 참조(ecc:deep-research·literature-review·scholar-evaluation·pubmed + obsidian 키리스 스크립트) — 생태계 전수 조사(VoltAgent 10-research-analysis, skills.sh 1K+ 후보 5종 정독) 결과 "generate-verify 분리 + 스코어카드 + 메타데이터 강제"를 가진 등가물이 없어 얇은 자체 정의로 확정(최유력 199-biotechnologies deep-research 8.9K는 라이선스 부재로 기각, DOI 실존 확인 아이디어만 evaluator에 반영).
