#!/usr/bin/env bash
# codex 호출 규율 훅 (2026-08-01 kty 지시)
# 모든 `codex exec` 호출은 모델 gpt-5.6-sol + effort high 고정.
# 오케스트레이터가 "작업이 작다/비용" 이유로 임의 하향한 사고의 재발을 기계로 차단한다.
# 변경이 필요하면 이 훅과 하네스 SKILL.md를 함께 고친다 — 사용자 승인 필수.
set -u
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception: print("")' 2>/dev/null)

# 실제 호출 형태(codex exec --플래그)만 트리거 — 커밋 메시지·문서 속 "codex exec" 문자열 오탐 방지
if ! printf '%s' "$cmd" | grep -qE 'codex[[:space:]]+exec[[:space:]]+--'; then
  exit 0
fi

if ! printf '%s' "$cmd" | grep -q 'model_reasoning_effort="high"'; then
  echo '[Hook 차단] codex exec 는 -c model_reasoning_effort="high" 필수 — kty 고정 지시, 임의 하향 금지. 낮춰야 할 사유가 있으면 사용자에게 먼저 승인받을 것.' >&2
  exit 2
fi
if ! printf '%s' "$cmd" | grep -qE '(^|[[:space:]])-m[[:space:]]+gpt-5\.6-sol' ; then
  echo '[Hook 차단] codex exec 는 -m gpt-5.6-sol 필수 — kty 고정 지시. 모델 교체는 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.' >&2
  exit 2
fi
exit 0
