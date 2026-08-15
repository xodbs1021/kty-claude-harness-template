# ADR-0017: codex 강제를 MCP 경로까지 — 가드 신설 + 듀얼리뷰 게이트 실검사화

날짜: 2026-08-11 / 상태: 확정 / 관련: ADR-0020(듀얼 리뷰), 전면 감사 2026-08-11 *(정정 2026-08-15 — ADR-0020: 기존 ADR-0004는 마커 계약 분리라 듀얼 리뷰와 무관한 오인용이었다)*

## Context
전면 감사 + codex 독립 검증에서 두 결함이 확정됐다.
1. `guard-codex-invocation.sh`는 matcher "Bash" 전용 — `mcp__codex__codex` MCP 호출은
   모델·effort·sandbox 검사를 통째로 우회했다(실호출로 실증).
2. `stop:dualreview` 게이트는 플래그 파일 존재만 검사 — 산출물 없이 `rm` 한 줄로
   통과됐고, "산출물 없이는 차단한다"는 SKILL.md 서술은 구현과 불일치했다.

## Decision
- **`guard-codex-mcp.sh` 신설** (PreToolUse matcher `mcp__codex__codex`):
  model은 생략 또는 gpt-5.6-sol만, `config.model_reasoning_effort`는 생략/high/xhigh만,
  sandbox `danger-full-access` 차단. **config 중첩 override**(`config.model`,
  `config.sandbox_mode`)도 동일 계약([cx] 지적 통합).
- **듀얼리뷰 게이트 실검사화**: 플래그보다 mtime이 새로운 `_workspace/*codex*.md`가
  있으면 게이트가 스스로 플래그를 지우고 통과 — 지울 플래그를 에이전트 손에 주지 않는다.
  `record_flag`는 기존 항목 재기록에도 touch(재편집이 stale 리뷰로 해제되는 우회 차단,
  [cx]). rm 실패(플래그 잔존) 시 해제 경로 진입 금지([cx]).

## Alternatives Considered
- 비JSON 입력 fail-closed: 형제 훅 철학(정직한 드리프트 방지, fail-open)과 일치시켜 기각.
- 산출물 내용 파싱: 빈 껍데기 우회는 남는다(기록된 한계) — 내용 검증은 completion-auditor 몫.
- generation marker: mtime touch로 충분, 과설계로 보류.

## Consequences
- MCP·Bash 두 경로가 같은 계약을 받는다. `mcp__codex__codex-reply`(기존 스레드 지속),
  `base-instructions` 교체는 미커버 — 기록된 한계.
- 게이트 통과가 "리뷰 산출물 실존"과 결합된다. 벽돌 방지(MAX_BLOCKS)는 불변.

관련: 근거 실측은 second-brain `Projects/harness-template/specs/2026-08-11-codex게이트-보수-실측.md`
