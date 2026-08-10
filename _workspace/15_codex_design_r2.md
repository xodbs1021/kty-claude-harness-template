보류입니다. 라운드 1의 원래 실패 시나리오는 상당수 보강됐지만, 새 상태 전이들이 공유 차단 예산·결정 게이트·push 게이트와 충돌합니다. 파일은 변경하지 않았습니다.

## 라운드 1 지적 처리 판정

| # | 심각도·대상 절 | 처리 판정 | 시나리오·근거 |
|---|---|---|---|
| 1 | HIGH · §4-3·§7 자동 해제 | **원지적은 닫힘, 새 결함으로 이동** | 플래그 해제 후 빈 감사 차단은 재평가+케이스 18로 잡았습니다. 그러나 재평가 판정식이 정의되지 않아 push 미완과 결정 판독 실패를 삼킬 수 있습니다. |
| 2 | HIGH · §4-3·§6 결정 경고 전달 | **차단 경로만 닫힘, 성공 경로로 이동** | 불량 표명 차단에는 `emit_decision_note`와 케이스 16이 추가됐습니다. 정상 표명 후 플래그 해제→`exit 0`에서는 같은 경고가 출력된다는 계약이 없습니다. |
| 3 | HIGH · §4-3·§7 경로·플래그 판독 | **부분 폐쇄** | 상대경로의 `$PROJECT_DIR` 기준 해석, 절대경로, 읽기 실패는 반영됐습니다. 그러나 0바이트 플래그와 빈·손상 행의 fail-closed 규칙은 여전히 없습니다. |
| 4 | HIGH · §4-3·§7 다중 파일 지문 | **원지적은 닫힘, 공유 예산 결함으로 이동** | `r:<정렬된 불량 경로 목록>`으로 회수 게이트의 부분 진전은 보입니다. 하지만 이를 공유 `flags_fp`에 넣어 다른 게이트의 예산까지 리셋합니다. |
| 5 | MEDIUM · §4-3·§8 삭제 우회 공시 | **닫힘** | 듀얼리뷰가 삭제를 잡는다는 거짓 근거를 제거하고 기계적으로 막지 못하는 한계로 정확히 공시했습니다. |
| 6 | MEDIUM · §4-3 codex 재귀 | **재귀는 닫힘, 반대 방향 결함 발생** | 검수의 검수 루프는 막지만 `codex`가 들어간 정상 설계서까지 3개 플래그에서 제외됩니다. |
| 7 | MEDIUM · §3 층 경계 기준 | **닫힘** | 공급자 중립 계약·사용자 층 바인딩·상위 구현 교체 시 하네스 무수정의 3조건으로 바로잡았고 도구도 예시로 한정했습니다. |
| 8 | MEDIUM · §6·§7 테스트 독립성 | **부분 폐쇄** | 실제 `mark-needs-audit` arming, 상대·절대경로, 판독 실패, 부분 진전, codex 제외 등이 추가됐습니다. 다만 새 결합 결함과 혼합 경로·손상 플래그는 잡지 못합니다. |
| 9 | LOW · §6 운영 문서 | **닫힘** | README·usage·CI·플래그 정본·훅 주석까지 구현 목록에 포함됐습니다. |

통합 기록의 “전건 v2 반영” 주장은 문서 반영 여부로는 맞지만, 실질 폐쇄로는 과합니다. 특히 [통합 기록의 HIGH 처리 주장](/Users/kty/Downloads/kty-claude-harness-template/_workspace/14_design_review_integrated.md:27)은 아래 상태기계 충돌을 포함하지 않습니다.

## 새로 생겼거나 남은 결함

- **HIGH · §4-3 차단 지문·§7 케이스 14 — `r:` 목록이 다른 게이트의 벽돌 방지 예산을 무력화합니다.**

  시나리오: 결정 게이트가 계속 같은 자백 때문에 차단 중인데, 에이전트가 불량 회수 파일 집합을 하나씩 바꾸거나 두 불량 경로의 순서를 바꿈 → 공유 `flags_fp`가 변함 → `gate_budget("decision")`도 매번 진전으로 오인하여 카운터를 0으로 리셋 → MAX_BLOCKS 탈출이 영원히 오지 않습니다.

  현재 기계는 모든 게이트가 공유하는 `flags_fp`로 지문을 만들고 게이트별 `gate_budget`에 그대로 사용합니다. [현재 공유 지문](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:82), [리셋 로직](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:92), [v2의 전역 `flags_fp` 편입](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-retrieval-policy.md:147). `r:` 상세값은 `retrieval` 게이트 지문에만 결합하거나 게이트별 지문을 분리해야 합니다.

- **HIGH · §4-3 자동 해제·§7 케이스 16·18 — 정상 해제 후 `exit 0`가 결정 게이트 판독 실패를 조용히 삼킵니다.**

  시나리오: retrieval 플래그만 존재하고 표명은 정상 → 결정 스캐너가 transcript 판독 불가로 `decision_note` 설정 → retrieval 검사 불량 0건 → 플래그 해제 → 남은 플래그 없음으로 `exit 0` → 경고가 어느 메시지에도 실리지 않습니다.

  이는 판독 불가가 “소리를 내야 한다”는 [ADR-0012 계약](/Users/kty/Downloads/kty-claude-harness-template/docs/decisions/2026-08-10-decision-gate.md:66)을 다시 깨뜨립니다. 케이스 16은 불량 표명으로 3.4가 차단하는 경우만 잡고, 케이스 18은 판독 성공만 전제합니다. [자동 해제 계약](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-retrieval-policy.md:142), [현재 경고 함수](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:114).

- **HIGH · §4-3 자동 해제 재평가·§7 케이스 18 — `exit 0` 판정식이 없어 push 게이트를 우회할 수 있습니다.**

  시나리오: 정상 retrieval 플래그와 미push 커밋만 존재 → 플래그 자동 해제 → 구현자가 “다른 플래그 전무”를 “남은 할 일 없음”으로 구현 → `exit 0` → 뒤의 `stop:push` 차단에 도달하지 않습니다.

  push는 플래그가 아니라 앞에서 계산된 `push_unsent` 상태이므로 반드시 기존 조기 종료 조건 전체를 재사용해야 합니다. [현재 조기 종료 판정](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:60), [push 차단 위치](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:327). v2의 “남은 할 일”은 판정식을 열거하지 않고 케이스 18도 push 공존을 시험하지 않습니다.

- **HIGH · §4-3 `retrieval_gate_active`·§7 케이스 13 — fail-closed가 0바이트·손상 플래그를 포함하지 않습니다.**

  시나리오: 플래그 기록 도중 중단되어 `.needs-retrieval`이 0바이트가 됨 → `retrieval_gate_active()`의 “비어있지 않음” 조건이 거짓 → 조기 종료 → 검사 대상이 있었는지조차 확인하지 않고 통과합니다. 또는 손상 행이 존재하지 않는 상대경로로 읽히면 “파일 소실”로 분류되어 자동 해제됩니다.

  [활성 조건](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-retrieval-policy.md:130)은 [fail-closed 항목](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-retrieval-policy.md:140)보다 먼저 0바이트 플래그를 제외합니다. 라운드 1이 요구한 빈·손상 행 계약은 아직 닫히지 않았습니다.

- **HIGH · §4-3 codex 제외·§7 케이스 20 — 검수 재귀 방지가 정상 설계서의 무게이트 우회를 만듭니다.**

  시나리오: Codex 연동 자체를 설계하는 정상 주산출물 `_workspace/00_design_codex-integration.md` 저장 → 이름에 `codex`가 있다는 이유로 retrieval·dualreview·knowledge 플래그가 모두 서지 않음 → 조용히 종료됩니다. 구현이 전체 경로를 검사하면 `/work/codex-project/_workspace/00_design.md`도 같은 오탐입니다.

  기존 계약은 리뷰 산출물이 `_workspace/*codex*.md`라고만 할 뿐 `codex` 포함 파일을 전부 리뷰 산출물로 예약하지 않습니다. [기존 명명 계약](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/skills/harness-orchestrator/SKILL.md:67), [새 제외 계약](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-retrieval-policy.md:123). 검수 결과가 `00_design*`·`01_plan*` 접두어를 사용하지 못하게 하는 명명 계약이 더 안전합니다.

- **MEDIUM · §4-3 `decision_armed` — 소실 전용 플래그가 정리되기 전에 결정 게이트를 오발동시킵니다.**

  시나리오: 산출물은 이미 삭제됐고 stale retrieval 플래그만 남음 → 현재 턴의 일반 설명에 결정 표지 어휘가 있음 → `decision_armed`가 먼저 서서 결정 게이트가 차단 → 뒤의 3.4가 “소실만 남음”을 확인하고 플래그를 해제할 기회가 없습니다.

  순서가 결정 3.2 → retrieval 3.4인데, arming은 정리 전 `retrieval_gate_active`만 봅니다. [순서와 arming 계약](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-retrieval-policy.md:133), [추가 조건](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-retrieval-policy.md:153). 케이스 8과 17은 각각 중립 transcript와 정상 플래그만 검사해 이 결합을 놓칩니다.

- **MEDIUM · §4-3 활성 판정 — “knowledge와 같은 결합 판정”이 현재 구현과 일치하지 않습니다.**

  현재 `knowledge_gate_active()`는 플래그+설정 스위치만 결합하고 `stop:knowledge` 비활성은 게이트 호출부에서 별도로 검사합니다. [현재 함수](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/_common.sh:260), [호출부](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:301). 반면 새 retrieval 함수는 개별 훅 비활성까지 포함합니다. 이 차이 때문에 자동 해제 재평가에서 `.needs-knowledge`와 `.needs-retrieval`의 “활성” 의미가 달라집니다. 공통 `work_pending()` 판정과 게이트별 effective-active 정의가 필요합니다.

## 테스트 계획 판정

21개 케이스와 13개 변이는 라운드 1의 직접 회귀에는 전반적으로 좋아졌습니다. 특히 케이스 11~19는 경로·부분 진전·경고 전달·실제 arming을 독립적으로 고정합니다.

다만 수정된 전체 계약을 붙들지는 못합니다. 최소한 다음 축이 빠졌습니다.

- 정상 자동 해제 + 결정 스캔 판독 불가 + 다른 게이트 없음
- 정상 자동 해제 + `push_unsent`
- 0바이트 플래그, 빈 행, 손상 행, 마지막 개행 없는 행
- decision/typecheck 차단 중 `r:` 집합 변경·재정렬이 예산을 리셋하지 않음
- 상대경로와 외부 절대경로가 한 플래그에 함께 있는 경우
- 소실 항목만 남은 stale retrieval 플래그 + 결정 표지 발화
- 정상 주산출물 이름에 `codex`가 포함된 경우와 프로젝트 디렉터리명에 `codex`가 포함된 경우
- retrieval 해제 후 disabled dualreview/knowledge/explain 플래그가 공존할 때 초기·재평가 판정의 일관성
- `r:` 목록의 정렬 제거 및 다른 게이트 지문에 전파하는 변이

따라서 케이스 수와 변이 수는 고정됐지만, 새 상태기계의 결합면은 아직 고정되지 않았습니다.

판정: 보류
