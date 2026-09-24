# 2026-09-24 — codex 듀얼 리뷰 고정 모델 교체 `gpt-5.6-sol` → `gpt-6-sol` (완료)

## 결정 (kty 지시 「codex 리뷰모델 5.6 sol 에서 6 sol로 바꿔」)

듀얼 리뷰 규칙(`docs/decisions/2026-08-01-dual-review-rule.md`)의 고정 모델을 `gpt-6-sol` 로 올린다. **effort `high` 고정과 임의 하향 금지는 그대로다.** CLI 에 "최신 자동 추종" 기제가 없어 세대가 바뀔 때마다 사용자 지시로 이 줄을 갱신한다는 2026-08-01 규정의 첫 적용이다.

## 바뀐 자리 (같은 날 동시 갱신 — 훅과 SKILL.md 가 갈리면 가드가 정상 호출을 차단한다)

- `template/.claude/hooks/guard-codex-invocation.sh` — `MODEL_TOKEN` 정규식·차단 메시지·머리 주석
- `template/.claude/hooks/guard-codex-mcp.sh` — `model`·config 기본값 검사 문자열·주석
- `template/.claude/skills/harness-orchestrator/SKILL.md` — 듀얼 리뷰 명령 줄 + 「모델 하드코딩」 항목(CLI 버전 조건 명기)
- `install.sh` · `README.md` · `docs/usage.md` — 안내 문구
- 프로젝트 적용본: pokeclip-mono 워크트리·메인 체크아웃 `.claude`(이중 사본), 사용자 `~/.codex/config.toml` 기본 `model`

## 검증 (2026-09-24 KST)

1. 1차 스모크 실패 — `codex-cli 0.144.5`: `Model metadata for gpt-6-sol not found` + 서버 400 `not supported when using Codex with a ChatGPT account`. 로컬 모델 캐시(`~/.codex/models_cache.json`, `client_version 0.155.0` 이 씀)에는 `gpt-6-astra`·`gpt-6-sol`·`gpt-6-luna` 가 있었다 — 즉 **모델은 있고 CLI 가 낡은 것**이었다(캐시 형식 불일치 `missing field base_instructions` 도 같은 원인).
2. `npm install -g @openai/codex@latest` → 0.156.1.
3. 2차 스모크 통과 — `codex exec --sandbox read-only -m gpt-6-sol -c model_reasoning_effort="high" "한 단어로만 답하라: ok" < /dev/null` → `ok`, rc=0, 3,276 tokens.

## 절차 규범 (다음 세대 교체 때)

① 사용자 지시 → ② **CLI 버전이 그 모델을 아는지 먼저 확인**(`~/.codex/models_cache.json` slug 목록·`npm view @openai/codex version`) → ③ 훅 2·SKILL.md·템플릿·config 동시 sed → ④ 스모크 1회 성공 확인, 실패면 즉시 원복. 훅만 바꾸고 스모크를 빼면 이후 모든 codex 리뷰가 조용히 실패한다.

## 옛 기록은 그대로

`2026-08-01-dual-review-rule.md`·`2026-08-11-codex-mcp-guard-dualreview-hardening.md` 의 `gpt-5.6-sol` 문자열은 당시 결정의 원문이므로 고치지 않는다 — 현행 값은 이 파일과 SKILL.md 가 말한다.
