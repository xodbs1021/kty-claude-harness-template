# 독립 코드 검수 요청 — 지식 회수 정책 구현 (ADR-0013)

당신은 이 저장소의 코드 검수자다. **파일 생성·삭제 없이 정적 독해로 판정하고, 반드시 마지막에 판정 줄을 내라.**

## 대상 (구현 커밋 985d6fd..HEAD — `git diff 8a814a0..HEAD` 로 전체 확인 가능)
- `template/.claude/hooks/_common.sh` — `RETRIEVAL_FLAG`·`retrieval_pending()`
- `template/.claude/hooks/mark-needs-audit.sh` — 회수 플래그 기록
- `template/.claude/hooks/verify-before-stop.sh` — `work_pending()`·게이트 3.4(경로 해석·BOM/CR·fail-closed·자동 해제+재평가·게이트별 예산 키)
- `template/.claude/skills/harness-orchestrator/SKILL.md`·`template/.claude/harness/project-profile.template.md`·`template/.claude/agents/{clarifier,plan-reviewer,developer,pr-reviewer}.md`
- `tests/retrieval-attestation.test.sh`(25케이스)·`tests/mark-needs-audit.{test,cases}.sh`(75케이스)·`_workspace/mutate-retrieval-gate.sh`(16변이 전건 적색)
- `docs/decisions/2026-08-10-knowledge-retrieval-policy-decided.md`(ADR-0013)·README·docs/usage.md

## 판단 기준
- 확정 설계: `_workspace/00_design-retrieval-policy.md` (v3 — 듀얼 검수 2라운드 반영본). **구현이 설계와 다르면 지적하라.**
- 층 계약: ADR-0006 (하네스는 진입점 너머를 모른다)
- 게이트 계약: ADR-0012 ②(경고 전파)·④(순서)
- 셸: macOS bash 3.2 호환(mapfile·연관배열·${var,,} 금지) · `set -uo pipefail` 아래 안전성 · 위음성 카탈로그 부류(조용한 통과 경로)

## 검수 관점
1. **위음성** — 표명 없는 산출물이 조용히 통과하는 경로가 남았는가 (인용 상태·경로·인코딩·플래그 상태의 엣지)
2. **상태 오염** — 3.4 가 기존 게이트 기계(조기 종료·차단 지문·예산 소진·결정 게이트·push)를 깨는 경로
3. **셸 정확성** — bash 3.2·`set -u`·IFS·글롭·인용·`read` 의 함정. 특히 `IFS= read -r rline < "$f"` 의 개행 없는 파일, `${rline#$'\xEF\xBB\xBF'}` 이식성, `sort -u | tr` 파이프
4. **테스트 품질** — 케이스가 rc 단독 판정을 피했는가, 픽스처가 결함을 가리는 부류(판정 순서·데이터 중복·새 방어가 옛 방어 가림)가 남았는가
5. **문서 정합** — ADR-0013·README ⑭·usage.md 의 주장이 구현 사실과 일치하는가 (거짓 공시가 최우선 지적 대상이다)

## 출력 형식
- 지적마다: 심각도(CRITICAL/HIGH/MEDIUM/LOW) + 파일:라인 + "어떤 입력 → 어떤 잘못된 결과" 시나리오
- 마지막 줄 반드시: `판정: 통과` 또는 `판정: 보류` (CRITICAL/HIGH 1건 이상이면 보류)
