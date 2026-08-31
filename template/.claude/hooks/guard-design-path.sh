#!/usr/bin/env bash
# PreToolUse(Skill · Write|Edit|MultiEdit): 설계·계획 산출물은 harness-orchestrator 경로로만 낳는다.
# (도메인-무관 재사용 템플릿)
#
# 왜 필요한가 (실사고 2026-08-31):
#   오케스트레이터가 harness-orchestrator 를 태우지 않고 설계서를 **직접** 썼다. 그러면
#   프로필의 "지식 진입점" 절이 통째로 적용되지 않는다 — 그 절의 `[읽는 이]` 는
#   clarifier·architect·planner·plan-reviewer 이고, 선행 결정 회수 프로토콜의 정본은
#   harness-orchestrator SKILL.md 의 dispatch 계약이기 때문이다. 규약이 **에이전트에게
#   dispatch 될 때** 걸리도록 설계돼 있어서, 오케스트레이터가 직접 쓰면 아무것도 안 걸린다.
#   실제 결과: 설계서 3판이 **낡은 정본** 위에 섰고(그 사이 팀 계약 PR 이 머지되고 지식
#   저장소가 편집됐다), 듀얼 리뷰 두 라운드가 그것을 다시 발견하는 데 소모됐다.
#
#   기존 게이트는 있었으나 **트리거를 비껴갔다**: mark-needs-audit.sh 는
#   `*/_workspace/[0-9][0-9]_design*.md` 앵커로 머리 표명 게이트(.needs-retrieval)를 세우는데,
#   산출물이 지식 저장소에 비영문 이름으로 떨어져 **위치 축(_workspace 밖)과 언어 축**
#   양쪽에서 빗나갔다. 같은 훅 주석이 **번호 축** 우회를 이미 기록해 뒀다(2026-08-17) —
#   같은 부류의 세 번째 구멍이다. 이름 글롭을 계속 넓히는 대신 축을 바꾼다:
#   이 훅은 파일이 어떻게 생겼나가 아니라 **어떻게 낳았나**를 본다.
#
# 무엇을 하나:
#   1) Skill 호출이 harness-orchestrator 면 이 세션에 도장을 찍는다.
#   2) 설계·계획 산출물을 쓰려는데 도장이 없으면 **막는다**.
#
# 왜 세션에 묶나: guard-harness-drift.sh 가 기록한 실측 — 세션에 안 묶인 고정 경로 플래그는
#   지우는 주체가 없어 **영구 통과**가 된다. 파일에 session_id 를 넣고 값을 대조한다.
#   세션이 바뀌면 옛 도장은 자동으로 무효다(안전한 실패 방향).
#
# 상태 파일: $STATE_DIR/.harness-path — 한 줄·필드 1개·세션 식별자 문자열. 날짜 형식 없음.
#
# 무엇을 안 막나: 리뷰 판정문·raw 이관·색인·입력서·의뢰문. 그것들은 설계 산출물이 아니라
#   설계를 **둘러싼** 문서이고, 막으면 리뷰 회수 자체가 불가능해진다.
#
# 알려진 한계(정직 고지): 이름 규약을 벗어난 새 명명은 못 잡는다. **과속방지턱이지 방벽이
#   아니다** — 우회 경로가 있다는 것을 알고 만들었다. 막혔다는 사실이 안전을 보증하지 않는다.
#
# 셸 이식성: macOS 기본 bash 3.2. ${var,,}·mapfile·연관배열 금지.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

HOOK_ID="pre:write:design-path"
hook_disabled "$HOOK_ID" && exit 0

payload="$(cat)"
tool="$(printf '%s' "$payload" | json_get tool_name)"
session="$(printf '%s' "$payload" | json_get session_id)"
STAMP="$STATE_DIR/.harness-path"

# --- 1) 도장: harness-orchestrator 가 태워졌다 -----------------------------
if [ "$tool" = "Skill" ]; then
  skill="$(printf '%s' "$payload" | json_get tool_input.skill)"
  case "$skill" in
    *harness-orchestrator*)
      # 세션 식별자가 없으면(구버전·비대화형) 도장을 찍지 않는다 — 찍으면 그 값이
      # 다음 세션에서 우연히 일치할 수 있고, 그게 영구 통과 구멍이다.
      if [ -n "$session" ]; then
        printf '%s\n' "$session" > "$STAMP" 2>/dev/null || true
      fi
      ;;
  esac
  exit 0
fi

# --- 2) 게이트: 설계·계획 산출물인가 ---------------------------------------
raw="$(printf '%s' "$payload" | json_get tool_input.file_path; printf 'X')"
raw="${raw%X}"
file_path="${raw%$'\n'}"
[ -z "$file_path" ] && exit 0

lower="$(printf '%s' "$file_path" | tr '[:upper:]' '[:lower:]')"
base="$(basename "$lower")"

# 면제가 먼저다. 설계를 둘러싼 문서는 설계 산출물이 아니다.
case "$base" in
  *리뷰*|*review*|*판정*|*verdict*|*의뢰*|*prompt*) exit 0 ;;
  *raw*|*실측*|*스파이크*|*spike*)                   exit 0 ;;
  *색인*|index.md|*_index.md|readme*|*.jsonl)        exit 0 ;;
  *입력서*|*clarifier*|*qa.md)                       exit 0 ;;
  *progress*|*log.md)                                exit 0 ;;
esac

# 설계·계획 산출물 판정 — 이름 축(한/영) 전부. 위치는 보지 않는다(어디에 쓰든 같다).
is_design=0
case "$base" in
  *설계서*|*설계안*|*설계_*|*_설계*)   is_design=1 ;;
  *계획서*|*계획안*|*계획_*|*_계획*)   is_design=1 ;;
  [0-9][0-9]_design*.md|*_design_*.md|*_design.md|design_*.md) is_design=1 ;;
  [0-9][0-9]_plan*.md|*_plan_*.md|*_plan.md|plan_*.md)         is_design=1 ;;
esac
[ "$is_design" -eq 0 ] && exit 0

# 도장 대조.
stamped=""
[ -f "$STAMP" ] && stamped="$(cat "$STAMP" 2>/dev/null)"
if [ -n "$session" ] && [ "$stamped" = "$session" ]; then
  exit 0
fi

cat >&2 <<'MSG'
[설계 경로 강제] 설계·계획 산출물을 harness-orchestrator 경로 밖에서 쓰려 했습니다.
MSG
printf '\n  대상: %s\n\n' "$file_path" >&2
cat >&2 <<'MSG'
이 게이트가 있는 이유: 오케스트레이터가 직접 설계서를 쓰면 프로필의 **지식 진입점 절이
적용되지 않습니다** — 그 절의 [읽는 이]는 clarifier·architect·planner·plan-reviewer 이고,
선행 결정 회수 프로토콜의 정본은 harness-orchestrator SKILL.md 의 dispatch 계약입니다.
그것을 건너뛰면 설계가 **낡은 정본** 위에 서고, 듀얼 리뷰가 그걸 다시 발견하는 데
라운드를 씁니다.

할 일:
  1) Skill 도구로 harness-orchestrator 를 호출하고, 그 파이프라인이
     architect 에게 dispatch 하게 하십시오(착수 전 회수 3단계가 거기 붙어 있습니다).
  2) 산출물은 _workspace/NN_design_*.md · NN_plan_*.md 로 먼저 낳으십시오 —
     그래야 머리 표명 게이트(.needs-retrieval)가 함께 걸립니다.
     지식 저장소 이관은 그 게이트를 통과한 뒤입니다.

끄는 것은 사용자만 정합니다 — 막혔으면 우회하지 말고 사용자에게 보고하십시오.
MSG
exit 2
