# 2026-10-01 — codex 듀얼 리뷰 고정 모델 `gpt-5.6-sol` → `gpt-6.1-sol` (완료)

## 결정 (kty 지시 「codex 리뷰 6.1 sol 로 바꿔줘」)

듀얼 리뷰 규칙의 고정 모델을 `gpt-6.1-sol` 로 올린다. effort `xhigh` 고정과 임의 하향
금지는 그대로다. 이 파일이 `2026-09-28-codex-model-gpt-5-6-sol.md` 의 모델
값(`gpt-5.6-sol`)을 대체한다. 사유는 지시에 없었다 — 모델 교체는 kty 지시로만 한다.

## 바뀐 자리 (같은 날 동시 갱신 — 훅과 SKILL.md 가 갈리면 가드가 정상 호출을 차단한다)

- `template/.claude/hooks/guard-codex-invocation.sh` — `MODEL_TOKEN` 정규식
  (`gpt-6\.1-sol` — 점 이스케이프) · 차단 메시지 · 머리 주석(이력 한 줄 추가)
- `template/.claude/hooks/guard-codex-mcp.sh` — `model` · `config.model` 검사
  문자열 · 주석 · 차단 메시지
- `template/.claude/skills/harness-orchestrator/SKILL.md` — 듀얼 리뷰 명령 줄 +
  「모델 하드코딩」 항목
- `install.sh` — config.toml 스캐폴드 · 검사식 · 경고 문구
- `docs/usage.md` — 안내 문구(README.md 에는 모델 문자열이 없다)
- 프로젝트 적용본: pokeclip-mono 메인 체크아웃과 현행 워크트리 넷의 `.claude`,
  사용자 `~/.codex/config.toml` 최상위 `model`
- 손대지 않은 것: 전역 `~/.claude/hooks/guard-codex-mcp.sh` · pokeclip-mono 옛
  워크트리 둘

## 검증 (2026-10-01 KST)

1. CLI 가 모델을 아는지 — codex-cli 0.156.1 은 `gpt-6.1-sol` 메타데이터를 몰랐고
   (「Model metadata for `gpt-6.1-sol` not found」), 서버가 400 「The 'gpt-6.1-sol'
   model is not supported when using Codex with a ChatGPT account」를 냈다.
   npm 으로 0.159.3 으로 올린 뒤 같은 호출이 통과했다 — **`gpt-6.1-sol` 은
   codex-cli 0.159.3 이상이 필요하다.**
2. 가드 시험 행렬(합성 입력 → 종료 코드) — Bash 가드 10건(근사 모델
   `gpt-6x1-sol` · 옛 모델 둘 · effort high · `-m` 없음 · 연쇄 차단 포함) ·
   MCP 가드 4건(최상위 `model` · `config.model` · 생략). 고친 뒤 14건 모두
   통과(pokeclip-mono 메인 체크아웃 사본으로).
3. 스모크 — `codex exec --sandbox read-only -m gpt-6.1-sol -c
   model_reasoning_effort="xhigh" "…" < /dev/null` → rc 0 · 기록 머리
   `model: gpt-6.1-sol` · `reasoning effort: xhigh` · 4,380 tokens · 답
   「준비됨 GPT-6」.

## 옛 기록은 그대로

`2026-09-25-codex-model-gpt-6-sol.md` · `2026-09-27-codex-effort-xhigh.md` ·
`2026-09-28-codex-model-gpt-5-6-sol.md` 본문은 그날의 사실 기록이므로 고치지
않는다 — 현행 값은 이 파일과 SKILL.md 가 말한다.
