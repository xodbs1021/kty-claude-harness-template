# ADR-0027: 리뷰 횟수는 커밋마다 듀얼 1회, PR 전체는 Phase 4 에서만 듀얼 3회

**Date**: 2026-11-04
**Status**: accepted — [ADR-0025](2026-09-29-review-unit-per-pr.md) 의 결정 3 과
그에 딸린 규칙 둘을 supersede 한다
**Deciders**: 김태윤(지시·확정), Claude(문서 정합화)

> 레퍼런스 조사: 불요(사용자가 리뷰 횟수를 명시했고, 이 결정은 그 횟수에 활성
> 문서를 맞추는 정합화다. 리뷰 단위의 선례 조사는 ADR-0025 가 이미 했다.)

---

## Context

GitHub main(`ab26641`) 의 `harness-orchestrator` SKILL.md 는 한 PR 의 리뷰를 세
자리에서 돌렸다.

1.  커밋마다 Claude+Codex 듀얼 1라운드(ADR-0025 결정 2).
1.  PR 직전, Phase 3 끝의 종결 라운드 — PR 전체 차분을 입력으로 무지적 3회,
    상한 5회(ADR-0025 결정 3).
1.  Phase 4 PR 점검 — "종결 기준·라운드 규약"의 묶음 소절 "Phase 3 (코드
    검수)·Phase 4 (PR 점검) — 현행 유지"가 여기에도 무지적 3라운드를 걸었다.

2와 3은 같은 PR 전체 차분을 본다. 그래서 한 PR 이 PR 전체로만 최소 여섯
라운드를 듀얼로 돌았고, 이것이 실제 병목이었다. ADR-0025 는 Phase 4 점검의 종결
규약을 "그대로인 것"으로 두었기 때문에 이 중복을 다루지 않았다.

kty 가 새 정책을 명시했다(2026-11-04, 요지): 커밋마다 Claude+Codex 듀얼 리뷰 1회,
PR 전체는 Claude+Codex 듀얼 리뷰 3회. 이 지시는 옛 SKILL.md 문구보다 우선한다.

## Decision

**PR 전체 리뷰는 Phase 4 한 자리에서만 돈다.** Phase 3 끝의 PR 전체 종결 라운드는
없앤다. 나머지 규칙은 그대로 둔다.

1.  **Phase 3(코드 검수)은 커밋 단위다.** 커밋마다 cc·cx 동시 1라운드를 돌고,
    양측 동시에 설계·문서 CRITICAL/HIGH 0 이면 닫는다. 커밋이 하나뿐인 PR 도
    같다.
    *   CRITICAL/HIGH 수정은 기존 수정분 확인 패스로 확인한다(cc·cx 동시 · 수정분
        한정). 두 번째 확인에도 남으면 사용자에게 회부한다.
    *   MEDIUM/LOW 는 커밋을 막지 않는다. 지적마다 귀속(누가 처분하나)과 처분
        예정을 적어 PR 단계로 이연한다.
    *   Phase 3 에는 무지적 계수, 라운드 상한 5회, PR 전체 추가 3회가 없다.
    *   싱글턴 CRITICAL/HIGH 교차 검증은 그대로 생략할 수 없다.
1.  **Phase 4(PR 점검)만 PR 전체로 무지적 3라운드를 돈다.**
    *   입력은 넷이고 cc(pr-reviewer)·cx 가 같은 입력을 받는다. 기준 브랜치를
        동기화한 뒤의 PR 전체 차분, 현재 계획서, 차분 밖 운영 문서 목록, 이연
        목록.
    *   무지적 라운드는 같은 라운드에서 양측 동시에 CRITICAL/HIGH 0 이다. 종결은
        무지적 3회(연속 불요)와 축 체크리스트 전부 커버다.
    *   전면 라운드 상한은 5회이고, 넘으면 kty 에게 회부한다.
    *   마지막 무지적 라운드의 MEDIUM/LOW 수정은 cc·cx 동시 확인 패스 1회로만
        확인한다.
1.  **여러 커밋 PR 은 커밋별 기록을 추가 리뷰 없이 잇는다.** 모든 커밋이 닫히면
    오케스트레이터가 커밋별 기록(`phase3-review-c<N>-r<M>.md`) 목록과 이연 목록을
    `phase3-review.md` 한 파일에 잇는다. 이 파일이 Phase 3 최종 판정이고,
    pr-author 의 입력이자 pr-reviewer 의 대조 기준이다.

**그대로인 것:** 듀얼 리뷰 구성(모델·effort 고정, 임의 하향 금지, 가드 훅),
보안 검수, 싱글턴 교차 검증의 범위(Phase 2 = CRITICAL · Phase 3 = CRITICAL/HIGH ·
Phase 4 = 비대상), 라운드 보고, 변경 설명, 완료 감사, Phase 2 의 종결 조건,
ADR-0025 결정 1·2(계획서는 커밋마다 고치지 않는다 · 커밋별 듀얼 1라운드).

**바뀐 자리:** `template/.claude/skills/harness-orchestrator/SKILL.md` 의 "종결
기준·라운드 규약"(머리 문단 · Phase 3 소절 · Phase 4 소절 · 적용 단위 · 라운드
보고), Phase 2 끝 문단, Phase 3 · Phase 4 절, "싱글턴 지적 교차 검증" (9) C, 주입
표, 데이터 전달. `template/.claude/agents/pr-author.md` 입력,
`template/.claude/agents/pr-reviewer.md` 의 8번 항목과 입력. 회귀 검사
`tests/review-policy.test.sh` 를 CI 에 등록했다.

## Alternatives Considered

**A. 현상 유지 — Phase 3 끝 3회와 Phase 4 3회를 둘 다 돈다**

*   Pros: PR 전체를 보는 라운드가 가장 많다.
*   Cons: 같은 입력을 두 단계가 거듭 본다. 실제 병목이었다.
*   Why not: kty 가 정한 횟수(PR 전체 3회)와 다르다.

**B. Phase 4 의 3회를 없애고 Phase 3 끝 종결 라운드를 남긴다**

*   Pros: 싱글턴 교차 검증이 PR 전체 라운드에도 그대로 걸린다(Phase 3 범위).
*   Cons: PR 본문·브랜치 위생을 보는 pr-reviewer 가 PR 전체 라운드에서 빠진다.
    PR 이 열리기 전에 PR 전체를 리뷰하므로 PR 본문은 리뷰 대상 밖에 남는다.
*   Why not: kty 의 지시는 Phase 3 쪽 PR 전체 3회만 없애는 것이다.

**C. Phase 3 종결 라운드를 1회로 줄여 남긴다**

*   Pros: 커밋 사이 맞물림을 PR 열기 전에 한 번 더 본다.
*   Cons: PR 전체 리뷰가 4회가 된다.
*   Why not: kty 가 정한 횟수와 다르다.

## Consequences

**Positive**

*   PR 전체 차분을 보는 듀얼 라운드가 최소 6회에서 최소 3회로 준다.
*   리뷰 횟수의 정본이 한 소절씩으로 갈린다. Phase 3 은 커밋 단위, Phase 4 는
    PR 전체다. 회귀 검사가 옛 묶음 규칙의 재삽입을 막는다.
*   여러 커밋 PR 에서 pr-reviewer 가 커밋별 기록의 싱글턴 처리를 대조한다.
    ADR-0025 Negative 의 "커밋별 라운드의 싱글턴 처리는 사후에 대조하는 주체가
    없다"가 닫힌다.

**Negative (못 막는 것은 못 막는다고 쓴다 — ADR-0011)**

*   **PR 전체 라운드의 싱글턴 CRITICAL/HIGH 는 교차 검증 대상이 아니다.**
    Phase 4 는 기존 범위대로 비대상이다. 그래서 그 지적은 반대 진영이 반박해
    보지 않고 수정으로만 닫힌다. 단독 기각은 듀얼 리뷰 규칙대로 여전히 못 한다.
    위양성이 수정 비용으로 남을 수 있다.
*   **커밋 사이의 맞물림 결함은 PR 이 열린 뒤에 드러난다.** 그때는 수정 커밋을
    얹는다.
*   **Phase 4 의 입력이 크다.** ADR-0025 "결정 3 의 근거"가 적은 큰 입력의 약점이
    그대로 Phase 4 로 옮겨 온다.
*   **전부 산문 계약이다.** 종료 훅은 여전히 codex 산출물의 실존만 본다. 회귀
    검사는 문구의 부류를 볼 뿐, 오케스트레이터가 실제로 몇 번 돌았는지는 보지
    않는다.
*   **Phase 4 의 수정 커밋에는 커밋별 1라운드를 따로 걸지 않는다.** 그 수정은
    다음 Phase 4 라운드나 확인 패스가 본다.

## 관련

*   [ADR-0025](2026-09-29-review-unit-per-pr.md) — 적용 단위. 결정 1·2 는 그대로
    서고, 결정 3(Phase 3 끝 종결 라운드)과 딸린 규칙 둘(커밋 하나 PR 의 겸함 ·
    pr-author 입력은 종결 라운드 산출물뿐)을 이 결정이 대체한다. 본문은
    2026-09-29 결정 원문으로 두고 상태 줄로만 구별했다.
*   [ADR-0020](2026-08-01-dual-review-rule.md) — 듀얼 리뷰 규칙과 종결 규약의
    정본. 후속 이력에 이 결정을 한 항으로 더했다. 2026-09-04 항의 "Phase 3 ·
    Phase 4 의 무지적 3라운드는 현행 그대로"는 당시 원문이라 고치지 않았다.
*   [ADR-0019](2026-08-15-singleton-finding-adversarial-verification.md) —
    싱글턴 교차 검증. 범위는 바꾸지 않았다. 위 Negative 첫 항이 그 결과다.
*   [ADR-0011](2026-08-10-self-discipline-gates.md) — 한계 공시 의무. 위
    Negative 가 그 이행이다.
