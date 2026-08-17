너는 독립 설계 검수자다. 파일 생성·삭제·수정 없이 **정적 독해로만** 판정하고, 출력 맨 위에 반드시 판정 줄을 내라: `판정: 통과` 또는 `판정: 보류` (CRITICAL 또는 HIGH 1건이면 보류).

## 검수 대상
- `_workspace/00_design-reference-gate.md` — 레퍼런스 조사 게이트 설계서 (ADR-0015 대상)

## 판단 기준으로 함께 읽을 것 (전문)
- `docs/decisions/2026-08-10-knowledge-retrieval-policy-decided.md` (ADR-0013 — 이 설계가 복제·확장하는 패턴의 정본)
- `docs/decisions/2026-08-10-decision-gate.md` (ADR-0012 — ⑤·⑥ 판정 프레임)
- `template/.claude/hooks/verify-before-stop.sh` (특히 3.4 게이트와 work_pending·gate_budget·compute_flags_fp)
- `template/.claude/hooks/_common.sh` (retrieval_pending·플래그 정의)
- `template/.claude/hooks/mark-needs-audit.sh` (설계 산출물 분기)
- `tests/retrieval-attestation.test.sh` (기존 27케이스 — 설계가 "단언 불변·픽스처만 갱신"을 주장한다)
- `_workspace/mutate-retrieval-gate.sh` (기존 변이 18종 — 설계가 "앵커 영향 없음"을 주장한다)
- `template/.claude/skills/harness-orchestrator/SKILL.md` · `template/.claude/harness/project-profile.template.md` 9절 (산문 계약 자리)

## 검수 항목
1. **내부 모순·거짓 공시** — 설계서의 주장 중 위 파일들의 실물과 어긋나는 것. 특히 "기존 27케이스 단언 불변", "변이 18종 앵커 영향 없음", "mark-needs-audit 로직 불변", "FLAG_NAMES 불변" 주장을 실물 대조로 반증 시도하라.
2. **상태기계 결합면** — 둘째 줄 검사 추가가 자동 해제·재평가·공유 지문·예산 키·조기 종료·decision_armed 와 상호작용하며 생기는 결함 시나리오. 직전 두 세션의 차단급이 전부 이 축이었다.
3. **형식 문법의 구멍** — ③-1 문법 정의로 통과하지만 의도(불요에도 사유 강제·닫힌 문법)를 깨는 입력, 또는 정상 의도인데 불량 판정되는 입력. bash 3.2 파라미터 확장으로 이 문법을 구현할 때의 함정(내부 괄호·공백·CR·개행 없는 마지막 줄·멀티바이트).
4. **표명 자리 이동의 파급** — 회수 블록을 셋째 줄로 옮기는 것이 건드리는 계약 자리의 누락(설계 ⑦-3 표가 전수인지). ADR-0013 ⑴ 문구와의 정합 처리 방식.
5. **조사 실행 배선(⑥-1)의 정합** — 오케스트레이터/작성자/검수 역할 분담에 구멍이 있는가. "레퍼런스 조사 필요" 반환 루프의 비종결 위험.
6. **테스트·변이 계획(⑦)의 공백** — 설계가 약속한 방어 중 케이스·변이로 잡히지 않는 것. 신규 케이스가 기존 케이스와 간섭하는 경로.
7. **공시(8절)의 완전성** — 실제로 못 막는데 공시에서 빠진 것.

## 출력 형식
판정 줄 다음에, 지적마다:
- 심각도: CRITICAL / HIGH / MEDIUM / LOW
- 근거 파일:라인
- 시나리오: 어떤 입력·상태 → 어떤 잘못된 결과
한국어로 써라. 확인 못 한 항목은 지어내지 말고 "미확인"으로 표기하라.
