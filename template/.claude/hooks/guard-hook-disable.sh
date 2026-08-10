#!/usr/bin/env bash
# PreToolUse(Bash): **에이전트가 게이트를 스스로 끄는 것**을 차단한다.
#
# 왜: 이 하네스의 모든 게이트에는 탈출구가 있다(HARNESS_HOOKS=off · ECC_DISABLED_HOOKS ·
# ECC_GATEGUARD). 탈출구는 **사용자를 위한 것**이지 막힌 에이전트를 위한 것이 아니다.
# 그런데 지금까지 그 구분은 산문으로만 존재했다 — "제 판단으로 끄지 않겠습니다"라고
# 말하는 것 말고는 아무것도 막지 않았다. 이 저장소가 반복해서 배운 것이 정확히
# **산문 규칙은 어겨지고, 어겨져도 조용하다**는 것이다.
#
# 게이트가 성가실 때 끄고 싶어지는 순간이 바로 게이트가 일하는 순간이다. 그 순간의
# 판단을 에이전트에게 맡기면 게이트는 있으나 마나다.
#
# **읽는 것은 막지 않는다.** 값을 확인하거나(`echo "$HARNESS_HOOKS"`) 문서에 적는 것은
# 정상 작업이다. 막는 것은 **대입**뿐이다.
#
# 탈출구: 이 훅에는 환경변수 탈출구가 **없다.** 있으면 그 탈출구로 이 훅을 끄고
# 나머지를 전부 끌 수 있어 존재 이유가 사라진다. guard-codex-invocation 과 같은 처리다.
# 사용자가 정말 끄려면 셸에서 직접 export 하고 세션을 새로 띄우거나 settings.json 에서
# 이 훅 배선을 지운다 — 둘 다 사람이 하는 행위다.
#
# 셸 이식성: macOS 기본 bash 는 3.2 다.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

payload="$(cat)"
cmd="$(printf '%s' "$payload" | json_get tool_input.command)"
[ -z "$cmd" ] && exit 0

# 감시 대상 = 게이트를 끄는 스위치들.
# 값까지 보지 않는다 — `ECC_DISABLED_HOOKS=stop:knowledge` 처럼 **하나만** 끄는 것도
# 에이전트가 정할 일이 아니다. 무엇을 끌지는 사용자가 정한다.
#
# `이름=` 형태의 **대입**만 잡는다. 앞 문자가 영숫자·밑줄·`$` 가 아니어야 하므로
# `$ECC_DISABLED_HOOKS` 같은 참조나 `MY_ECC_GATEGUARD=` 같은 다른 이름은 안 걸린다.
matched="$(printf '%s' "$cmd" \
  | grep -oE '(^|[^A-Za-z0-9_$])(HARNESS_HOOKS|ECC_DISABLED_HOOKS|ECC_GATEGUARD)=' \
  | grep -oE '(HARNESS_HOOKS|ECC_DISABLED_HOOKS|ECC_GATEGUARD)' \
  | sort -u | tr '\n' ' ')"
[ -z "$matched" ] && exit 0

{
  echo "[차단] 게이트를 끄려 하고 있습니다: ${matched% }"
  echo
  echo "이 탈출구는 **사용자를 위한 것**이지 막힌 에이전트를 위한 것이 아닙니다."
  echo "게이트가 성가신 순간이 게이트가 일하는 순간입니다."
  echo
  echo "해야 할 일: 끄지 말고 **사용자에게 물으세요.**"
  echo "  - 무엇이 막혔는지"
  echo "  - 왜 그 게이트를 끄는 것이 옳다고 보는지"
  echo "  - 끄지 않고 갈 수 있는 길은 없는지"
  echo
  echo "사용자가 끄기로 하면 사용자가 직접 셸에서 export 하거나 settings.json 배선을"
  echo "지웁니다. 이 훅에는 환경변수 탈출구가 없습니다 — 있으면 그것으로 나머지를 전부"
  echo "끌 수 있어 존재 이유가 사라집니다."
} >&2
exit 2
