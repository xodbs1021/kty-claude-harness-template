#!/usr/bin/env bash
# 하네스 훅 공용 모듈. 각 훅 스크립트가 source 한다. (도메인-무관 재사용 템플릿)
#
# set -e 를 쓰지 않는다: 훅이 예기치 않게 죽으면 세션이 막히거나(Stop)
# 멀쩡한 명령이 차단된다(PreToolUse). 모든 종료는 명시적으로 한다.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
STATE_DIR="$PROJECT_DIR/.claude"
AUDIT_FLAG="$STATE_DIR/.needs-audit"
EXPLAIN_FLAG="$STATE_DIR/.needs-explain"
VAULT_FLAG="$STATE_DIR/.needs-vault"
DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
BLOCK_COUNT="$STATE_DIR/.stop-block-count"
BLOCK_FP="$STATE_DIR/.stop-block-fp"    # 마지막 차단 지문(게이트|플래그 상태) — 진전 인지 리셋용

# Stop 훅이 "같은 지점에서 진전 없이" 최대 몇 번까지 막을 수 있는가. 소진되면 통과시킨다
# (세션 벽돌 방지). 차단 지문이 바뀌면(=게이트를 하나 지웠으면) 카운터는 리셋되므로,
# 게이트 개수가 늘어도 이 상수를 올릴 필요가 없다.
MAX_BLOCKS=3

# 탈출구.
#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
hook_disabled() {
  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
    return 0
  fi
  case ",${ECC_DISABLED_HOOKS:-}," in
    *",$1,"*) return 0 ;;
  esac
  return 1
}

# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
#
# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
# 전부 실측된 것들이다:
#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
#   printf 재정의 → 진단 출력 자체를 위조
# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
#
# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 **빈 값을 돌려준다**
# (호출부가 "미설정"으로 안전하게 처리하도록).
#
# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **확장되지 않는다.** 실행하지 않는 대가다.
# 확장이 필요하면 그 자리에 최종 문자열을 적어야 한다.
harness_env_value() {
  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
  [ -f "$file" ] || { printf '%s' ''; return 0; }
  # 선행 공백 없는 `KEY=` 또는 `export KEY=` 만. grep rc 는 삼킨다(무매치·오류 모두 미설정).
  lines="$(grep -E "^(export[[:space:]]+)?${key}=" "$file" 2>/dev/null)" || lines=''
  [ -n "$lines" ] || { printf '%s' ''; return 0; }
  n="$(printf '%s\n' "$lines" | wc -l | tr -d ' ')"
  [ "$n" = "1" ] || { printf '%s' ''; return 0; }
  val="${lines#*=}"
  # 감싼 따옴표 한 겹만 벗긴다(양쪽이 짝일 때만).
  case "$val" in
    \"*\") val="${val#\"}"; val="${val%\"}" ;;
    \'*\') val="${val#\'}"; val="${val%\'}" ;;
  esac
  printf '%s' "$val"
}

# stdin 의 JSON 에서 점 경로로 값 하나를 뽑는다. 없거나 파싱 실패면 빈 문자열.
# 훅 입력이 깨져도 절대 죽지 않는다 — 죽으면 오탐 차단이 된다.
json_get() {
  python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for key in sys.argv[1].split("."):
    if not isinstance(data, dict):
        sys.exit(0)
    data = data.get(key)
    if data is None:
        sys.exit(0)
print(data)
' "$1" 2>/dev/null
}
