# 2026-09-27 — codex 듀얼 리뷰 고정 effort 교체 `high` → `xhigh` (완료)

## 결정 (kty 지시 「xhigh로 올리고 진행해」)

듀얼 리뷰 규칙의 고정 effort 를 `xhigh` 로 올린다. 모델 `gpt-6-sol` 고정과 임의 하향 금지는 그대로이고, 이제 `high` 도 하향이다. `2026-09-25-codex-model-gpt-6-sol.md` 의 「effort `high` 고정과 임의 하향 금지는 그대로다」 문장 가운데 effort 값은 이 파일이 대체한다.

## 계기

pokeclip-mono POK-195 세션에서 kty 가 「cx effort x-high 로 설정된거맞아?」라고 물었다. 확인하니 사용자 `~/.codex/config.toml` 은 `model_reasoning_effort = "xhigh"` 인데, 듀얼 리뷰 명령 줄이 `-c model_reasoning_effort="high"` 를 넘겨 매 리뷰가 high 로 돌고 있었다(그 세션 codex 기록 10건의 머리가 모두 `reasoning effort: high`). 규칙과 사용자 기본값이 어긋나 있었다.

## 바뀐 자리 (같은 날 동시 갱신 — 훅과 SKILL.md 가 갈리면 가드가 정상 호출을 차단한다)

- `template/.claude/hooks/guard-codex-invocation.sh` — `EFFORT_TOKEN` 정규식(xhigh 만) · 차단 메시지 · 주석
- `template/.claude/hooks/guard-codex-mcp.sh` — 허용 판정 `!= "xhigh"`(키 생략은 config 기본값이라 통과) · 차단 메시지 · 주석
- `template/.claude/skills/harness-orchestrator/SKILL.md` — 듀얼 리뷰 명령 줄 + 「effort 하드코딩」 항목
- `install.sh` — config.toml 검사식(xhigh 만) · 경고 문구
- `README.md` · `docs/usage.md` — 안내 문구
- 프로젝트 적용본: pokeclip-mono 메인 체크아웃과 현행 워크트리 셋의 `.claude`. 사용자 `~/.codex/config.toml` 은 이미 xhigh 라 그대로다.

## 검증 (2026-09-27 KST)

1. 가드 시험 행렬(합성 입력 → 종료 코드) — Bash 가드 10건 · MCP 가드 6건. 고치기 전 판에서는 effort 관련 5건이 실패하고, 고친 뒤에는 16건이 모두 통과한다(템플릿 판 포함).
2. 배선 확인 — 실제 Bash 호출 `codex exec … -c model_reasoning_effort="high" …` 가 새 차단 메시지로 막힌다.
3. 스모크 — `codex exec --sandbox read-only -m gpt-6-sol -c model_reasoning_effort="xhigh" "Reply with just OK." < /dev/null` → `OK`, rc=0, 기록 머리 `reasoning effort: xhigh`, 3,161 tokens.

## 알려진 비용

xhigh 는 호출당 토큰과 시간이 high 보다 많다. SKILL.md 「소모 절감」 문장의 416k–460k 토큰 실측은 high 기준이다. 사용 한도로 codex 가 실패하면 기존 대체 조항(듀얼 리뷰 생략 명시)을 따르고, high 로 내려 재시도하는 것은 하향이라 사용자 승인이 필요하다.

## 옛 기록은 그대로

`2026-08-01-dual-review-rule.md` · `2026-08-11-codex-mcp-guard-dualreview-hardening.md` · `2026-09-25-codex-model-gpt-6-sol.md` 의 `high` 문자열은 당시 결정의 원문이므로 고치지 않는다 — 현행 값은 이 파일과 SKILL.md 가 말한다.
