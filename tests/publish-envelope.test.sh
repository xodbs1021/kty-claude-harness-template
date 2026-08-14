#!/usr/bin/env bash
# publish-envelope.test.sh — canonical envelope(digest) 계약의 **함수 층** 회귀 테스트.
#
# 겨누는 것: _common.sh 의 publish_digest 하나다. 게이트 훅(guard-publish-receipt.sh)의
# 판정은 옆 러너(publish-receipt-gate.test.sh)가 본다 — 층을 갈라 두는 이유는 digest 가
# **발급기와 게이트가 공유하는 유일한 계약**이기 때문이다. 두 손이 같은 함수를 쓴다는
# 전제가 깨지면 영수증은 전부 무효가 되는데, 그 실패는 게이트 층에서는 "무영수증 deny"와
# 구별되지 않는다(ADR-0018 2절 불변식 (i)).
#
# 무엇을 붙드나:
#   결정론 · 키 순서 무관 · 도구명 결합 · 값 변조 민감 · 비ASCII/개행 · Artifact 재해시 ·
#   그리고 **거부해야 할 입력**(파싱 실패 · 중복 키 · 비정수 수 · Artifact 부재).
#   거부 축이 절반인 이유: 이 함수의 위험한 실패는 "틀린 digest"가 아니라 **빈 문자열을
#   digest 인 척 돌려주는 것**이다. 그러면 모든 호출이 같은 값으로 수렴해 영수증이
#   아무 payload 에나 들어맞는다.
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
#
# 이 파일 자신도 못 믿는다. 러너는 넷을 스스로 검사한다:
#   1) CASES 목록의 개수·중복  2) 실행 수 vs EXPECTED_CASES  3) pass+fail == ran
#   4) DID_RUN 센티널(직전 케이스 결과의 재판정)
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
#
# 사용법: ./tests/publish-envelope.test.sh   (전건 통과 시 종료 코드 0)

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
COMMON="$REPO_ROOT/template/.claude/hooks/_common.sh"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (publish_digest 의 직렬화기)" >&2; exit 1; }
[ -f "$COMMON" ] || { echo "✗ _common.sh 를 찾지 못했습니다: $COMMON" >&2; exit 1; }

TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
  exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

# _common.sh 는 PROJECT_DIR 을 CLAUDE_PROJECT_DIR 에서 잡는다. 함수 층 테스트라
# 상태 디렉토리를 쓸 일은 없지만, 실제 프로젝트를 가리킨 채 돌면 그쪽 .claude/ 를
# 건드릴 여지가 생긴다 — 임시 디렉토리로 고정한다.
export CLAUDE_PROJECT_DIR="$TMPROOT/proj"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude"
# shellcheck source=../template/.claude/hooks/_common.sh
. "$COMMON"

# **함수가 아예 없으면 거부 축 케이스가 통째로 위양성이 된다** — rc=127(command not found)
# 은 "거부했다"와 구별되지 않아 e07~e10 이 초록으로 보인다. 존재를 먼저 못 박는다.
for _fn in publish_digest publish_serializer_identity; do
  [ "$(type -t "$_fn" 2>/dev/null)" = 'function' ] \
    || { echo "✗ _common.sh 에 $_fn 함수가 없습니다 — 거부 축 케이스가 위양성이 됩니다" >&2; exit 1; }
done

# --- 헬퍼 ----------------------------------------------------------------

# digest_of <artifact_field> <payload 문자열> — RC·OUT 에 결과를 담는다.
# stdout 을 명령 치환으로 받으면 후행 개행이 지워지는데, publish_digest 는 개행을 붙이지
# 않으므로 그대로 받아도 안전하다. 그래도 rc 를 **먼저** 잡아 둔다.
RC=0
OUT=''
ERR=''
DID_RUN=0
digest_of() {
  local field="$1" payload="$2" errf="$TMPROOT/err.$$"
  DID_RUN=1
  OUT="$(printf '%s' "$payload" | publish_digest "$field" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

ran=0
pass=0
fail=0

# ok <이름> <사유(빈 문자열이면 통과)>
ok() {
  if [ "$DID_RUN" -ne 1 ]; then
    fail=$((fail + 1))
    printf '  ✗ %s — publish_digest 를 실행하지 않았다 (직전 케이스 결과를 재판정할 뻔했다)\n' "$1"
    return 0
  fi
  if [ -z "$2" ]; then
    pass=$((pass + 1))
    printf '  ✓ %s\n' "$1"
  else
    fail=$((fail + 1))
    printf '  ✗ %s — %s\n' "$1" "$2"
  fi
}

# is_hex64 <문자열> — 64자리 소문자 16진수인가.
is_hex64() {
  case "$1" in
    *[!0-9a-f]* | '') return 1 ;;
  esac
  [ "${#1}" -eq 64 ]
}

PAY_A='{"tool_name":"synthetic__publish__createIssue","tool_input":{"summary":"a","project":"P"}}'
# 같은 내용, 최상위 키 순서와 tool_input 키 순서만 다르다.
PAY_A_REORDERED='{"tool_input":{"project":"P","summary":"a"},"tool_name":"synthetic__publish__createIssue"}'

# --- 케이스 --------------------------------------------------------------

case_e01() { # 결정론 — 같은 입력은 언제나 같은 digest. 이게 깨지면 발급 직후 검증이 실패한다.
  local first second why=''
  digest_of - "$PAY_A"; first="$OUT"
  [ "$RC" -eq 0 ] || why="1회차 rc=$RC (stderr: $ERR)"
  [ -z "$why" ] && { is_hex64 "$first" || why="digest 가 64자리 16진수가 아니다: [$first]"; }
  digest_of - "$PAY_A"; second="$OUT"
  [ -z "$why" ] && [ "$first" != "$second" ] && why="두 번 계산한 값이 다르다: [$first] vs [$second]"
  ok 'e01 결정론 — 같은 payload 는 같은 digest' "$why"
}

case_e02() { # 키 순서 무관 — canonical 직렬화(sort_keys)의 핵심. 순서가 바뀌면 같은 호출이
             # 다른 digest 를 내고, 정상 발행이 무영수증 deny 로 보인다.
  local a b why=''
  digest_of - "$PAY_A"; a="$OUT"
  digest_of - "$PAY_A_REORDERED"; b="$OUT"
  [ "$RC" -eq 0 ] || why="rc=$RC (stderr: $ERR)"
  [ -z "$why" ] && [ "$a" != "$b" ] && why="키 순서만 다른데 digest 가 다르다: [$a] vs [$b]"
  ok 'e02 키 순서만 다른 payload → 같은 digest' "$why"
}

case_e03() { # 도구명 결합 — 같은 입력 모양의 **다른 도구**에 영수증을 재사용할 수 없어야 한다.
  local a b why=''
  digest_of - "$PAY_A"; a="$OUT"
  digest_of - '{"tool_name":"synthetic__publish__editIssue","tool_input":{"summary":"a","project":"P"}}'; b="$OUT"
  [ "$RC" -eq 0 ] || why="rc=$RC (stderr: $ERR)"
  [ -z "$why" ] && [ "$a" = "$b" ] && why="도구명이 다른데 digest 가 같다: [$a]"
  ok 'e03 같은 tool_input·다른 tool_name → 다른 digest' "$why"
}

case_e04() { # 값 변조 민감 — 리뷰한 내용과 다른 내용을 발행하는 것이 이 게이트가 겨누는 실패다.
  local a b why=''
  digest_of - "$PAY_A"; a="$OUT"
  digest_of - '{"tool_name":"synthetic__publish__createIssue","tool_input":{"summary":"b","project":"P"}}'; b="$OUT"
  [ "$RC" -eq 0 ] || why="rc=$RC (stderr: $ERR)"
  [ -z "$why" ] && [ "$a" = "$b" ] && why="값이 다른데 digest 가 같다: [$a]"
  ok 'e04 tool_input 값 변조 → 다른 digest' "$why"
}

case_e05() { # 비ASCII·개행 왕복 — ensure_ascii=True 로 이스케이프해도 값이 보존돼야 하고,
             # 한 글자만 달라도 갈려야 한다. 한국어 본문이 실제 발행 payload 의 기본형이다.
  local a b why=''
  digest_of - '{"tool_name":"synthetic__publish__addComment","tool_input":{"body":"첫 줄\n둘째 줄 — 정정"}}'; a="$OUT"
  [ "$RC" -eq 0 ] || why="rc=$RC (stderr: $ERR)"
  [ -z "$why" ] && { is_hex64 "$a" || why="digest 가 64자리 16진수가 아니다: [$a]"; }
  digest_of - '{"tool_name":"synthetic__publish__addComment","tool_input":{"body":"첫 줄\n둘째 줄 — 정정!"}}'; b="$OUT"
  [ -z "$why" ] && [ "$a" = "$b" ] && why="비ASCII 본문이 한 글자 다른데 digest 가 같다: [$a]"
  ok 'e05 비ASCII·개행 본문 → 안정적이고 변조에 민감' "$why"
}

case_e06() { # Artifact 재해시 — 파일 **내용**이 digest 에 들어간다. 경로만 같고 내용이 바뀌면
             # 다른 digest 여야 한다(TOCTOU 는 이 재해시 시점까지만 보장 — ADR-0018 공시).
  local f a b why=''
  f="$TMPROOT/artifact-e06.bin"
  printf 'v1' > "$f"
  digest_of path '{"tool_name":"synthetic__publish__artifact","tool_input":{"path":"'"$f"'"}}'; a="$OUT"
  [ "$RC" -eq 0 ] || why="rc=$RC (stderr: $ERR)"
  printf 'v2' > "$f"
  digest_of path '{"tool_name":"synthetic__publish__artifact","tool_input":{"path":"'"$f"'"}}'; b="$OUT"
  [ -z "$why" ] && [ "$a" = "$b" ] && why="파일 내용이 바뀌었는데 digest 가 같다: [$a]"
  ok 'e06 Artifact 파일 내용 변경 → 다른 digest (재해시)' "$why"
}

case_e07() { # Artifact 부재 — 조용히 빈 해시로 접으면 파일 없는 발행이 통과한다. rc≠0 이어야 한다.
  local why=''
  digest_of path '{"tool_name":"synthetic__publish__artifact","tool_input":{"path":"'"$TMPROOT"'/없는파일.bin"}}'
  [ "$RC" -eq 0 ] && why="파일이 없는데 rc=0 이고 digest 를 냈다: [$OUT]"
  [ -z "$why" ] && is_hex64 "$OUT" && why="실패했는데 stdout 이 digest 형식이다: [$OUT]"
  ok 'e07 Artifact 파일 부재 → rc≠0' "$why"
}

case_e08() { # JSON 파싱 실패 — fail-closed. json_get 의 "빈 문자열 관용"을 물려받으면 안 된다.
  local why=''
  digest_of - '{"tool_name":"synthetic__publish__createIssue",'
  [ "$RC" -eq 0 ] && why="깨진 JSON 인데 rc=0 이다: [$OUT]"
  [ -z "$why" ] && is_hex64 "$OUT" && why="실패했는데 stdout 이 digest 형식이다: [$OUT]"
  ok 'e08 깨진 JSON → rc≠0' "$why"
}

case_e09() { # 중복 키 — JCS 면제의 전제 (ii). 파서가 마지막 값을 이기게 두면 훅과 발행 API 가
             # **다른 값**을 볼 수 있고, 그때 영수증은 리뷰하지 않은 내용을 통과시킨다.
  local why=''
  digest_of - '{"tool_name":"synthetic__publish__createIssue","tool_input":{"summary":"a","summary":"b"}}'
  [ "$RC" -eq 0 ] && why="중복 키인데 rc=0 이다: [$OUT]"
  [ -z "$why" ] && is_hex64 "$OUT" && why="실패했는데 stdout 이 digest 형식이다: [$OUT]"
  ok 'e09 tool_input 중복 키 → rc≠0' "$why"
}

case_e10() { # 비정수 수 — float·NaN·Infinity 는 직렬화기마다 표기가 갈린다(RFC 8785 실패원).
             # 두 값 다 거부해야 한다. 실제 발행 payload 에 float 이 실재하면 그 도구는
             # 등록 보류 또는 필드 문자열 정규화로 간다(ADR-0018 2절).
  local why=''
  digest_of - '{"tool_name":"synthetic__publish__createIssue","tool_input":{"estimate":1.5}}'
  [ "$RC" -eq 0 ] && why="float 인데 rc=0 이다: [$OUT]"
  if [ -z "$why" ]; then
    digest_of - '{"tool_name":"synthetic__publish__createIssue","tool_input":{"estimate":NaN}}'
    [ "$RC" -eq 0 ] && why="NaN 인데 rc=0 이다: [$OUT]"
  fi
  ok 'e10 비정수 수(float·NaN) → rc≠0' "$why"
}

# --- 계약 표의 크기 -------------------------------------------------------
EXPECTED_CASES=10

CASES='case_e01 case_e02 case_e03 case_e04 case_e05
       case_e06 case_e07 case_e08 case_e09 case_e10'

# --- 러너 ----------------------------------------------------------------

case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 중복됐거나 빠졌습니다" >&2
  exit 1
fi

echo "publish envelope — canonical digest 계약"
for c in $CASES; do
  ran=$((ran + 1))
  DID_RUN=0
  "$c"
done

if [ "$ran" -ne "$EXPECTED_CASES" ]; then
  echo "✗ 실행 케이스 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 조용히 빠졌습니다" >&2
  exit 1
fi
if [ $((pass + fail)) -ne "$ran" ]; then
  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건 — 케이스가 중복 판정했거나 판정을 건너뛰었습니다" >&2
  exit 1
fi

echo "— ${pass}/${ran} 통과"
[ "$fail" -eq 0 ] || exit 1
