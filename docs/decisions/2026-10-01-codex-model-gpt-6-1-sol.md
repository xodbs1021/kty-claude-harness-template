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
- `README.md`(43 · 93 · 132행 — 둘째 커밋 `e35e60b`) · `docs/usage.md` — 안내 문구
- 프로젝트 적용본: pokeclip-mono 메인 체크아웃과 현행 워크트리 넷의 `.claude`,
  사용자 `~/.codex/config.toml` 최상위 `model`
- 손대지 않은 것: 전역 `~/.claude/hooks/guard-codex-mcp.sh`(09-05 판 — 옛 모델만
  통과시키지만 codex 0.159.3 에는 MCP 서버 하위 명령이 없어 그 경로가 쓰이지
  않는다 · 머지 뒤 `install.sh` 1c 단계가 템플릿 판으로 덮는다) · pokeclip-mono
  옛 워크트리 둘(effort 가 high 인 옛 판 — 값만 바꿀 자리가 아니다)

## 검증 (2026-10-01 KST)

1. CLI 가 모델을 아는지 — codex-cli 0.156.1 은 `gpt-6.1-sol` 메타데이터를 몰랐고
   (「Model metadata for `gpt-6.1-sol` not found」), 서버가 400 「The 'gpt-6.1-sol'
   model is not supported when using Codex with a ChatGPT account」를 냈다.
   npm 으로 0.159.3 으로 올린 뒤 같은 호출이 통과했다 — **`gpt-6.1-sol` 은
   codex-cli 0.159.3 에서 통과했다**(0.156.1 은 거부 · 그 사이 판은 시험하지
   않아 최소 지원 판은 미확인).
2. 가드 시험 행렬(합성 입력 → 종료 코드) — Bash 가드 10건(근사 모델
   `gpt-6x1-sol` · 옛 모델 둘 · effort high · `-m` 없음 · 연쇄 차단 포함) ·
   MCP 가드 4건(최상위 `model` · `config.model` · 생략). 고친 뒤 14건 모두
   통과(pokeclip-mono 메인 체크아웃 사본으로).
3. 스모크 — `codex exec --sandbox read-only -m gpt-6.1-sol -c
   model_reasoning_effort="xhigh" "…" < /dev/null` → rc 0 · 기록 머리
   `model: gpt-6.1-sol` · `reasoning effort: xhigh` · 4,380 tokens · 답
   「준비됨 GPT-6」.
4. 배선 확인 — 살아 있는 PreToolUse 훅이 옛 값 호출을 「-m gpt-6.1-sol 필수」
   문구로 막고 새 값 호출은 통과시켰다(cc 검수자 실측 · `false &&` 로 실행은
   막음).

## 검수 (2026-10-01)

- cx(`gpt-6.1-sol` · xhigh · 78,222 tokens — 이 모델의 첫 실전 검수): 통과 ·
  설계 C/H/M/L 0/0/0/1 · 문서 0/0/2/0. MED 둘(이 문서의 README 누락 ·
  SKILL.md 70행의 현행 CLI 판 안내)을 다음 커밋에 반영 · LOW(셸 수정 줄
  네 곳의 80자 초과 — 기존 줄과 같은 길이의 값 치환) 기록. 합성 시험 22건
  독립 재현 · 훅 둘 × 적용본 다섯 `cmp` 10건 rc 0.
- cc(ecc:code-reviewer · opus · 217,540 tokens): 원 대상(1f39d92 · e35e60b)
  기준 보류 — 문서 HIGH 1(SKILL.md 70행이 0.156.1 을 검증 판으로 안내하고
  0.159.3 조건을 누락 — 8e2d9f8 이 고쳤음을 cc 가 확인) · MED 2(README 주장 —
  8e2d9f8 해소 · 70행의 09-28 잔재) · LOW 3(전역 MCP 가드 사유 · 「배선 확인」
  항목 · CLAUDE.md 행의 어림 시각). HEAD 기준 C/H 0. 합성 시험 33건 × 사본
  둘 = 66회 통과 · 훅 둘 sha256 여섯 사본 동일. 남은 MED · LOW 는 넷째
  커밋에 반영(70행 이력 정리 · 이 문서 21 · 40행 · CLAUDE.md 행의 시각 삭제).

## 옛 기록은 그대로

`2026-09-25-codex-model-gpt-6-sol.md` · `2026-09-27-codex-effort-xhigh.md` ·
`2026-09-28-codex-model-gpt-5-6-sol.md` 본문은 그날의 사실 기록이므로 고치지
않는다 — 현행 값은 이 파일과 SKILL.md 가 말한다.
