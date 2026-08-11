#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): harness.env 편집 직후, 알려진 키를 **실제 판독기로**
# 읽어 "문법 밖이라 미설정으로 취급될" 키를 그 자리에서 알린다 (ADR-0016).
#
# 왜 필요한가: harness.env 는 실행되지 않고 좁은 문법으로 판독된다(_common.sh 주석).
# 그 대가로 문법을 조금만 틀리면 값이 **조용히 미설정 취급**되고 해당 검사가 생략된다 —
# 원인(편집 실수)과 발각(턴 종료 게이트 메시지) 사이가 멀수록 비싼, 조용한 실패 부류다.
# 이 훅이 그 거리를 0 으로 줄인다.
#
# 판정은 harness_env_value 하나뿐이다 — **규칙의 사본을 만들지 않는다.** 훅이 문법을
# 다시 해석하는 순간 두 규칙이 어긋나는 날이 온다. 그래서 판독기의 반환 계약(rc=1
# 못 믿음 / rc=3 부재)을 소비만 한다: 부재는 안 쓰는 키의 정상 상태라 침묵하고,
# "못 믿음"만 경고한다. 이 구분이 없으면 키를 안 쓰는 프로젝트의 모든 편집에 경고가
# 떠서 경고가 소음이 된다.
#
# 알려진 키 목록은 여기가 유일 지점이다. 목록에 없는 키(오타 HARNESS_TYPECHEK_CMD 등)는
# **못 잡는다** — 잡으려면 파일의 선언을 직접 파싱해야 하는데 그게 규칙의 사본이다(공시).
#
# PostToolUse 는 절대 차단하지 않는다(도구는 이미 실행됨). 항상 exit 0.
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

HOOK_ID="post:edit:harness-env"
hook_disabled "$HOOK_ID" && exit 0

KNOWN_KEYS="HARNESS_TYPECHECK_CMD HARNESS_KNOWLEDGE_GATE"

payload="$(cat)"
# 명령 치환의 후행 개행 흡수를 센티널로 막는다 — mark-needs-audit 와 같은 관용구.
raw="$(printf '%s' "$payload" | json_get tool_input.file_path; printf 'X')"
raw="${raw%X}"
file_path="${raw%$'\n'}"
[ -z "$file_path" ] && exit 0

# 개행이 든 경로는 판정하지 않는다 — mark-needs-audit 가 이미 systemMessage 로 알린다.
case "$file_path" in
  *$'\n'*) exit 0 ;;
esac

# 이 훅의 대상은 하네스가 규정한 자리의 harness.env 뿐이다. 다른 이름·다른 자리는
# 하네스 설정이 아니다(동명 파일 오탐 방지 — .claude/harness/ 앵커까지 요구).
case "$file_path" in
  */.claude/harness/harness.env|.claude/harness/harness.env) ;;
  *) exit 0 ;;
esac

case "$file_path" in
  /*) envfile="$file_path" ;;
  *)  envfile="$PROJECT_DIR/$file_path" ;;
esac

bad_keys=""
for key in $KNOWN_KEYS; do
  # 판독기의 stderr(읽기 실패 경고)는 버린다 — 이 훅이 자기 메시지로 대신 알린다.
  harness_env_value "$key" "$envfile" >/dev/null 2>&1
  case "$?" in
    0|3) ;;                              # 판독됨 / 부재(안 쓰는 키) — 정상, 침묵
    *)   bad_keys="${bad_keys}${key} " ;;  # 못 믿음 — 경고 대상
  esac
done
[ -z "$bad_keys" ] && exit 0

# 키 이름은 [A-Z_] 뿐이라 JSON 이스케이프가 필요 없다. 경로는 넣지 않는다 —
# 넣는 순간 이스케이프 기계장치가 딸려온다(mark-needs-audit 의 메시지 계약과 동일).
printf '{"systemMessage":"harness.env 판독 경고: %s— 이 키는 값을 믿을 수 없어 미설정으로 취급되고, 해당 검사가 조용히 생략됩니다. 원인은 중복 선언·지원 문법 밖·닫히지 않은 따옴표·읽기 실패 중 하나입니다. 파일 첫머리의 문법 규칙을 확인하세요."}\n' "$bad_keys"
exit 0
