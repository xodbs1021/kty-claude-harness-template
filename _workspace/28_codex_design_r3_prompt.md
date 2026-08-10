너는 독립 설계 검수자다(라운드 3 — 수렴 확인 델타). 파일 생성·삭제·수정 없이 정적 독해로만 판정하고, 출력 맨 위에 판정 줄: `판정: 통과` 또는 `판정: 보류` (CRITICAL/HIGH 1건이면 보류).

## 검수 대상
- `_workspace/00_design-reference-gate.md` — 설계서 **v3**

## 델타 범위 (이번 라운드는 이것만 본다)
라운드 2 지적의 닫힘 여부만 판정한다. 원문:
- `_workspace/26_codex_design_r2.md` (codex r2 — HIGH 2·MEDIUM 3)
- `_workspace/27_design_r2_integrated.md` (통합 — plan-reviewer r2 HIGH 1·MEDIUM 6·LOW 5 포함)

확인 항목:
1. [cc] H1 — ③-2 의 rc 소비 분기 구조가 실제로 m26/r41 을 살리는가 (bash 3.2 의미론으로 검증)
2. [cx] H(실패 빈 사유) — 단일 경로 계약 + r46 이 우회를 닫는가
3. [cx] H(재시도 전이) — ⑥-1 항목 5 의 전이·상한·승격이 비종결을 닫는가
4. r2 MEDIUM·LOW 각각의 반영 절이 v3 실물에 있는가 (형식적 닫힘 적발)
5. **v3 델타가 새로 만든 차단급(CRITICAL/HIGH)이 있는가** — 이것 외 새 MEDIUM/LOW 는 기록만 하고 판정에 반영하지 않는다(수렴 라운드)

## 출력
판정 줄 → 항목별 닫힘/미흡 표 → (있으면) 신규 차단급. 한국어. 미확인은 "미확인".
