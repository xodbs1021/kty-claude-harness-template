# 독립 설계 검수 요청 — 지식 회수 정책

당신은 이 저장소(kty-claude-harness-template)의 설계 검수자다. **파일 생성·삭제 없이 정적 독해로 판정하고, 반드시 마지막에 판정 줄을 내라.**

## 대상
- `_workspace/00_design-retrieval-policy.md` — 검수 대상 설계서

## 판단 기준으로 먼저 읽을 것
- `docs/decisions/2026-08-06-knowledge-retrieval-policy.md` (ADR-0010 — 이 설계가 닫으려는 공백 4개)
- `docs/decisions/2026-08-05-knowledge-store-layer-boundary.md` (ADR-0006 — 층 경계: 하네스는 진입점 너머를 모른다)
- `docs/decisions/2026-08-06-profile-canon-upstream.md` (ADR-0009 — 기존 배관과 기각된 대안 C·D)
- `docs/decisions/2026-08-10-decision-gate.md` (ADR-0012 — 특히 ⑤·⑥절: 무엇을 기계로 강제하고 무엇을 단순하게 두는가)
- `template/.claude/hooks/verify-before-stop.sh` · `template/.claude/hooks/mark-needs-audit.sh` (설계가 얹힐 기존 훅)
- `template/.claude/skills/harness-orchestrator/SKILL.md` (설계가 바꿀 dispatch 계약)
- `template/.claude/harness/project-profile.template.md` 9절

## 검수 관점
1. **층 경계 위반** — 설계의 어느 부분이라도 하네스가 상위 층(지식 저장소)의 구현·배치를 알게 만드는가? "공개 포맷 의존은 위반 아님 / 사유화된 배치 의존이 위반"이라는 기준 자체가 타당한가?
2. **게이트 설계 결함** — 신설 `stop:retrieval` 게이트(플래그 arming·자동 해제·fail-closed·파일 소실 스킵·순서 3.4)에 조용한 실패(위음성)나 세션 벽돌 경로가 있는가? 기존 게이트 기계(조기 종료 조건·차단 지문 flags_fp·예산 소진 정리 목록)와의 상호작용에서 빠진 곳이 있는가?
3. **자기참조·순환** — 회수 표명을 요구하는 게이트가 이 하네스 자체 개발 흐름에서 스스로 걸려 무력화되거나 소음이 되는 경로가 있는가?
4. **과설계·임의성** — ADR-0012 ⑤·⑥절 기준으로, 기계화하지 말아야 할 것을 기계화했거나 임의의 숫자·목록을 지어낸 부분이 있는가?
5. **테스트 계획의 공백** — 7절 케이스·변이 목록이 설계의 계약을 실제로 붙드는가? "케이스가 통과해도 방어가 안 지켜지는" 부류(판정 순서 가림·데이터 중복 가림·새 방어가 옛 방어 가림)가 예상되는 지점은?
6. **정합성** — 설계가 인용한 선행 결정(ADR-0006·0009·0010·0012)과 실제로 모순되는 부분이 있는가?

## 출력 형식
- 지적마다: 심각도(CRITICAL/HIGH/MEDIUM/LOW) + 대상 절 + "어떤 상황 → 어떤 잘못된 결과" 시나리오
- 마지막 줄 반드시: `판정: 통과` 또는 `판정: 보류`  (CRITICAL 또는 HIGH 1건 이상이면 보류)
