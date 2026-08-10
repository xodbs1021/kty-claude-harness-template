너는 독립 설계 검수자다(라운드 2 — 델타 검수). 파일 생성·삭제·수정 없이 **정적 독해로만** 판정하고, 출력 맨 위에 반드시 판정 줄을 내라: `판정: 통과` 또는 `판정: 보류` (CRITICAL 또는 HIGH 1건이면 보류).

## 검수 대상
- `_workspace/00_design-reference-gate.md` — 설계서 **v2** (라운드 1 지적 반영판)

## 라운드 1 원문 (반영 여부 대조용)
- `_workspace/23_codex_design_review.md` (codex 라운드 1 — HIGH 3·MEDIUM 6)
- `_workspace/24_design_review_integrated.md` (통합 — plan-reviewer HIGH 6·MEDIUM 6·LOW 4 포함)

## 판단 기준 실물
- `template/.claude/hooks/verify-before-stop.sh` · `template/.claude/hooks/_common.sh` · `template/.claude/hooks/mark-needs-audit.sh`
- `tests/retrieval-attestation.test.sh` · `_workspace/mutate-retrieval-gate.sh`
- `template/.claude/skills/harness-orchestrator/SKILL.md` · `template/.claude/harness/project-profile.template.md` · `template/.claude/agents/plan-reviewer.md`
- `docs/decisions/2026-08-10-knowledge-retrieval-policy-decided.md` (ADR-0013) · `docs/decisions/2026-08-10-decision-gate.md` (ADR-0012)

## 검수 항목
1. **라운드 1 차단급(HIGH) 전건이 v2 에서 실제로 닫혔는가** — 통합 기록의 반영 절 번호를 실물 v2 텍스트와 대조. 형식적으로만 닫힌 것(문구는 넣었지만 계약이 여전히 성립 안 하는 것)을 찾아라.
2. **v2 신규 결정의 새 결함** — 특히: 예산 키 태그 `#1/#2` 가 기존 예산·지문 기계(r14·r24 계약)와 어긋나는 경로 / `실패` 변형 추가가 만드는 새 구멍 / 헤드라인·TOK_RET 교체가 기존 케이스 단언과 충돌하는 경로 / mk_doc 시그니처 확장이 기존 27케이스 중 어느 것의 의미를 바꾸는 경로.
3. **⑦ 테스트·변이 계획의 잔여 공백** — 신규 케이스 r28~r45 와 변이 m19~m29 의 대응이 어긋난 곳, 방어인데 측정이 없는 곳.
4. **⑦-3 전수표의 잔여 누락.**
5. 그 밖의 CRITICAL/HIGH 신규 발견.

## 출력 형식
판정 줄 다음에: 라운드 1 항목별 닫힘 확인(닫힘/미흡 + 근거), 이어서 신규 지적(심각도 + 근거 파일:라인 + 시나리오). 한국어. 확인 못 한 항목은 "미확인".
