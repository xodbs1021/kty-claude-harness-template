# 독립 설계 검수 — 라운드 2 (델타)

당신은 이 저장소의 설계 검수자다. **파일 생성·삭제 없이 정적 독해로 판정하고, 반드시 마지막에 판정 줄을 내라.**

라운드 1(`_workspace/13_codex_design_review.md` — 당신의 이전 지적)에 대해 설계서가 v2 로 개정됐다.

## 대상
- `_workspace/00_design-retrieval-policy.md` (v2 — 개정 전문)
- `_workspace/14_design_review_integrated.md` (항목별 처리 기록 — [cc] plan-reviewer 의 독립 지적과 그 처리도 여기 있다)

## 판정할 것
1. 라운드 1 의 당신 지적(HIGH 4·MEDIUM 4·LOW 1)이 각각 실제로 닫혔는가, 옮겨졌는가, 말로만 닫혔는가
2. **수정이 새로 만든 결함**이 있는가 (특히: 자동 해제 후 재평가 exit 0 경로, 지문 r:목록, retrieval_gate_active 결합 판정, codex 이름 제외, decision_armed 추가 — 이 수정들이 기존 게이트 기계와 새로 충돌하는 지점)
3. 테스트 계획(7절 케이스 21개·변이 13개)이 수정된 계약을 붙드는가

기준 문서는 라운드 1과 동일 (ADR-0006·0009·0010·0012, verify-before-stop.sh, mark-needs-audit.sh, SKILL.md, 프로필 9절).

## 출력 형식
- 지적마다: 심각도 + 대상 절 + 시나리오. 라운드 1 항목의 처리 판정은 표로.
- 마지막 줄 반드시: `판정: 통과` 또는 `판정: 보류` (CRITICAL/HIGH 1건 이상이면 보류)
