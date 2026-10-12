# 2026-09-28 — codex 듀얼 리뷰 고정 모델 되돌림 `gpt-6-sol` → `gpt-5.6-sol` (완료)

## 결정 (kty 지시 「코덱스 5.6 솔 effort x-high로 바꿔줘 다시」)

듀얼 리뷰 규칙의 고정 모델을 `gpt-5.6-sol` 로 되돌린다. effort `xhigh` 고정과 임의 하향 금지는 그대로다. 이 파일이 대체하는 것은 셋이다.

- `2026-09-25-codex-model-gpt-6-sol.md` 의 모델 값(`gpt-6-sol`).
- `2026-09-27-codex-effort-xhigh.md` 의 「모델 `gpt-6-sol` 고정 … 그대로」 구절. 그 기록의 시험 · 스모크는 `gpt-6-sol` 로 돌린 것이다.
- `2026-08-01-dual-review-rule.md` 3항의 「새 세대 모델이 나오면 그 줄을 갱신한다」. 교체 계기는 세대 출시가 아니라 kty 지시다(SKILL.md 70행의 같은 문장도 뺐다).

되돌린 사유는 지시에 없었다. 6세대(`gpt-6-sol`)를 거쳐 kty 가 `gpt-5.6-sol` 을 골랐다 — 모델 교체는 kty 지시로만 한다.

## 바뀐 자리 (같은 날 동시 갱신 — 훅과 SKILL.md 가 갈리면 가드가 정상 호출을 차단한다)

- `template/.claude/hooks/guard-codex-invocation.sh` — `MODEL_TOKEN` 정규식(`gpt-5\.6-sol` — 점 이스케이프) · 차단 메시지 · 머리 주석
- `template/.claude/hooks/guard-codex-mcp.sh` — `model` · `config.model` 검사 문자열 · 주석 · 차단 메시지
- `template/.claude/skills/harness-orchestrator/SKILL.md` — 듀얼 리뷰 명령 줄 + 「모델 하드코딩」 항목
- `install.sh` — config.toml 스캐폴드 · 검사식 · 경고 문구
- `README.md` · `docs/usage.md` — 안내 문구
- 프로젝트 적용본: pokeclip-mono 메인 체크아웃과 현행 워크트리 셋의 `.claude`, 사용자 `~/.codex/config.toml` 최상위 `model`(전역 기본값이라 다른 프로젝트의 대화형 codex 도 이 모델을 쓴다).
- 손대지 않은 것: 전역 `~/.claude/hooks/guard-codex-mcp.sh`(모델은 원래 `gpt-5.6-sol` 판이고 effort 는 high/xhigh 를 받는다 — `install.sh` 1c 가 체크아웃된 템플릿 판으로 덮는다) · pokeclip-mono 옛 워크트리 둘(모델은 같아졌고 effort 가 high 다).

## 검증 (2026-09-28 KST)

1. CLI 가 모델을 아는지 — `~/.codex/models_cache.json` 에 `gpt-5.6-sol` 이 있고 xhigh 를 지원한다(검증 판 codex-cli 0.156.1).
2. 가드 시험 행렬(합성 입력 → 종료 코드) — Bash 가드 11건(근사 모델 `gpt-5x6-sol` 차단 포함) · MCP 가드 10건(최상위 `model` 과 `config.model` 두 경로 — 통과 · 옛 모델 차단 · 근사 모델 차단). 고치기 전 판에서는 모델 관련 8건이 실패하고, 고친 뒤에는 21건이 모두 통과한다(로컬 사본 넷 + 템플릿). `config.model` 세 건은 검수 지적으로 더했다.
3. 배선 확인 — 실제 Bash 호출 `codex exec … -m gpt-6-sol …` 가 차단 메시지(「-m gpt-5.6-sol 필수」)로 막힌다.
4. 스모크 — `codex exec --sandbox read-only -m gpt-5.6-sol -c model_reasoning_effort="xhigh" "Reply with just OK." < /dev/null` → `OK`, rc=0, 3,363 tokens. 이 모델의 기본 추론 수준은 low 라서, 통과는 기록 머리의 `model: gpt-5.6-sol` · `reasoning effort: xhigh` 두 줄로 판정했다.

## 옛 기록은 그대로

`2026-09-25-codex-model-gpt-6-sol.md` · `2026-09-27-codex-effort-xhigh.md` 본문은 그날의 사실 기록이므로 고치지 않는다 — 현행 값은 이 파일과 SKILL.md 가 말한다.
