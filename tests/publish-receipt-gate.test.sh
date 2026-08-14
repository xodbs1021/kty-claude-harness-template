#!/usr/bin/env bash
# publish-receipt-gate.test.sh — 외부 발행 게이트(guard-publish-receipt.sh)의 판정 계약 러너.
#
# 이 파일은 **진입점**이다: 환경 전제 검사, 픽스처 조립, 실행·판정 헬퍼, 러너.
# 판정 계약 표는 publish-receipt-gate.cases.sh(머리 + p01~p35 + CASES·EXPECTED_CASES)와
# publish-receipt-gate.cases-2.sh(p36~p66) 두 조각에 있다. 한 파일에 두면 1000줄을 넘어
# 표를 계획서와 대조하기 어려워지므로 갈랐다(mark-needs-audit.{test,cases}.sh 와 같은 구조).
# **크기의 정본은 앞조각의 EXPECTED_CASES 하나뿐이고, 러너가 그 값을 강제한다.**
#
# **판정 순서가 곧 계약이다.** 이 게이트에서 순서를 틀리면 결과가 "조금 다른" 게 아니라
# 반대가 된다 — 예를 들어 엄격 파싱이 등재 판정보다 앞서면 발행과 무관한 MCP 도구의
# 정상 호출이 전부 막히고, 면제 로그가 플래그보다 앞서면 로그만 남고 흔적이 사라진다.
# 그래서 케이스의 상당수가 "무엇을 막나"가 아니라 "**어느 순서로 보나**"를 붙든다.
#
# 무엇을 재나: 종료 코드(0 통과 / 2 차단) · stderr 의 사유 문구 · 그리고 **파일시스템
# 상태**다. 마지막이 핵심이다 — 이 게이트의 위험한 실패는 "막았다/통과시켰다"가 아니라
# 영수증·승인이 소비됐는데 발행은 안 된(또는 그 반대) 어긋난 상태로 끝나는 것이다.
#
# 왜 set -e 가 없나: 비영 rc 와 실패 경로를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
#
# 이 파일 자신도 못 믿는다. 러너는 넷을 스스로 검사한다:
#   1) CASES 목록의 개수·중복  2) 실행 수 vs EXPECTED_CASES  3) pass+fail == ran
#   4) DID_RUN 센티널(직전 케이스 결과의 재판정)
#
# 환경 전제(전부 fail-closed): python3 부재 → exit 1(digest·스키마 판독이 통째로 무의미).
# root 실행 → 권한 픽스처가 성립하지 않는다(해당 케이스만 fixture_broken).
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
#
# 사용법: ./tests/publish-receipt-gate.test.sh   (전건 통과 시 종료 코드 0)

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOK="$REPO_ROOT/template/.claude/hooks/guard-publish-receipt.sh"
COMMON="$REPO_ROOT/template/.claude/hooks/_common.sh"
ISSUER="$REPO_ROOT/template/.claude/scripts/publish-issue-receipt.sh"
APPROVER="$REPO_ROOT/template/.claude/scripts/publish-approve.sh"
SETTINGS="$REPO_ROOT/template/.claude/settings.json"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (digest·스키마 판독)" >&2; exit 1; }
[ -f "$HOOK" ]     || { echo "✗ 훅을 찾지 못했습니다: $HOOK" >&2; exit 1; }
[ -f "$COMMON" ]   || { echo "✗ _common.sh 를 찾지 못했습니다: $COMMON" >&2; exit 1; }
[ -f "$ISSUER" ]   || { echo "✗ 발급기를 찾지 못했습니다: $ISSUER" >&2; exit 1; }
[ -f "$APPROVER" ] || { echo "✗ 승인 스크립트를 찾지 못했습니다: $APPROVER" >&2; exit 1; }

TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
  exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

IS_ROOT=0
[ "$(id -u 2>/dev/null)" = '0' ] && IS_ROOT=1

# --- 문구 조각 ------------------------------------------------------------
# 훅 문구가 다듬어져도 계약이 살아 있으면 계속 맞는 최소 조각.
TOK_BLOCK='[Hook 차단]'
TOK_NO_RECEIPT='영수증이 없습니다'
TOK_DUP_ACTIVE='영수증이 2개 이상'
TOK_DRIFT='직렬화 드리프트 의심'
TOK_SCHEMA='영수증 형식'
TOK_MIN_TIER='요구 등급'
TOK_TUPLE='리뷰 산출물'
TOK_APPROVAL='kty 승인'
TOK_REGISTRY='발행 대상 목록'
TOK_TOOLNAME='도구 이름을 판독'
TOK_PAYLOAD='호출 입력'
TOK_WAL='감사 선기록'
TOK_WAIVE='면제 기록'
TOK_WEDGED='소비가 중단된 흔적'
TOK_REAPPROVE='재승인'
TOK_CLAIM='영수증을 소비하지'
TOK_ESCAPE='publish:receipt'

# 합성 도구들. **실제 MCP 도구명을 쓰지 않는다** — 실물 payload fixture 는 실세션에서만
# 캡처되고 이 환경에 없다. 게이트가 지키는 것은 도구의 정체가 아니라 계약이므로,
# 계약은 합성 이름으로 온전히 검증된다(등록 절차는 publish-registry.txt 주석).
T_CREATE='synthetic__publish__createIssue'
T_COMMENT='synthetic__publish__addComment'
T_TRANSITION='synthetic__publish__transitionIssue'
T_ARTIFACT='synthetic__publish__uploadArtifact'
T_UNKNOWN='synthetic__other__listIssues'

REGISTRY_BODY="$T_CREATE	1	no	-	-
$T_COMMENT	1	yes	-	body
$T_TRANSITION	2	no	-	-
$T_ARTIFACT	1	no	path	-"

# --- 픽스처 조립 ----------------------------------------------------------

new_dir() {
  local d
  d="$(mktemp -d "$TMPROOT/$1.XXXXXX")" || exit 1
  if [ -z "$d" ] || [ ! -d "$d" ]; then
    echo "✗ 케이스용 임시 디렉토리를 만들지 못했습니다" >&2
    exit 1
  fi
  ( CDPATH='' cd -- "$d" && pwd -P )
}

# new_project — 훅·_common.sh·발급기·승인기·registry·receipts 골격을 갖춘 가짜 프로젝트.
new_project() {
  local p
  p="$(new_dir proj)"
  mkdir -p "$p/.claude/hooks" "$p/.claude/harness" "$p/.claude/scripts" \
           "$p/_workspace/.receipts/active" "$p/_workspace/.receipts/used" \
           "$p/_workspace/.receipts/approval-active" "$p/_workspace/.receipts/approval-used" \
           "$p/_workspace/.receipts/quarantine"
  cp "$HOOK"     "$p/.claude/hooks/guard-publish-receipt.sh"
  cp "$COMMON"   "$p/.claude/hooks/_common.sh"
  cp "$ISSUER"   "$p/.claude/scripts/publish-issue-receipt.sh"
  cp "$APPROVER" "$p/.claude/scripts/publish-approve.sh"
  printf '%s\n' "$REGISTRY_BODY" > "$p/.claude/harness/publish-registry.txt"
  printf '%s\n' "$p"
}

# payload <도구명> <tool_input JSON> — 훅 stdin 모양.
payload() {
  printf '{"tool_name":"%s","tool_input":%s}' "$1" "$2"
}

# digest_of <proj> <payload> [artifact_field] — 게이트와 **같은 함수**로 기대 digest 를 만든다.
# 같은 함수를 쓰는 것이 tautology 가 아닌 이유: digest 자체의 정확성은 publish-envelope
# 러너(e01~e10)가 따로 붙든다. 여기서 필요한 것은 "그 digest 로 만든 영수증이 통과하는가"다.
DIGEST=''
digest_of() {
  DIGEST="$(printf '%s' "$2" | env CLAUDE_PROJECT_DIR="$1" \
    bash -c '. "$0/.claude/hooks/_common.sh"; publish_digest "$1"' "$1" "${3:--}")"
}

# identity_of <proj> — 이 환경의 직렬화기 정체성.
identity_of() {
  env CLAUDE_PROJECT_DIR="$1" \
    bash -c '. "$0/.claude/hooks/_common.sh"; publish_serializer_identity' "$1"
}

# write_receipt <proj> <digest> <tier> <review 경로> <nonce> [도구명] [정체성] [추가 python 조작]
# **발급기를 거치지 않고 손으로 쓴다** — Bash 로 만든 영수증도 게이트가 똑같이 취급하는지
# (그리고 소비 시 감사 플래그가 서는지)가 계약이기 때문이다.
write_receipt() {
  local p="$1" d="$2" tier="$3" review="$4" nonce="$5"
  local tool="${6:-$T_CREATE}" ident="${7:-}" tweak="${8:-}"
  [ -n "$ident" ] || ident="$(identity_of "$p")"
  python3 -c '
import json, sys
p, d, tier, review, nonce, tool, ident, tweak = sys.argv[1:9]
rec = {"schema_version": 1, "tool_name": tool, "digest": d, "tier": int(tier),
       "review_artifact": review, "nonce": nonce, "serializer_identity": ident,
       "issued_at": "2026-08-14T00:00:00Z"}
if tweak:
    exec(tweak)
with open(p + "/_workspace/.receipts/active/" + d + "." + nonce, "w") as fh:
    json.dump(rec, fh, ensure_ascii=False)
' "$p" "$d" "$tier" "$review" "$nonce" "$tool" "$ident" "$tweak"
}

# make_review <proj> <상대경로> <도구명> <digest> <tier> — 3튜플을 담은 리뷰 산출물.
# 형식은 harness-orchestrator SKILL.md 의 발행 리뷰 규약과 같아야 한다.
make_review() {
  local p="$1" rel="$2"
  mkdir -p "$(dirname "$p/$rel")"
  {
    printf '# 발행 리뷰\n\n'
    printf '발행-리뷰: tool=%s digest=%s tier=%s\n' "$3" "$4" "$5"
    printf '\n본문은 사람이 읽는다.\n'
  } > "$p/$rel"
}

# write_approval <proj> <digest> <nonce>
write_approval() {
  python3 -c '
import json, sys
p, d, nonce = sys.argv[1:4]
with open(p + "/_workspace/.receipts/approval-active/" + nonce, "w") as fh:
    json.dump({"digest": d, "nonce": nonce, "issued_at": "2026-08-14T00:00:00Z"}, fh)
' "$1" "$2" "$3"
}

# --- 실행·판정 헬퍼 -------------------------------------------------------

OUT=''
ERR=''
RC=0
PROJ=''
WHY=''
DID_RUN=0
FIXTURE_FAIL=''

# run_gate <proj> <payload> [env 인자...] — 앰비언트 탈출구를 소거하고 훅을 부른다.
# 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off 를 export 한 셸에서 도는 워크플로라,
# 소거하지 않으면 차단 행이 전부 무판정으로 떨어져 러너가 통째로 위양성이 된다.
run_gate() {
  local proj="$1" pay="$2"
  shift 2
  OUT=''; ERR=''; RC=999; DID_RUN=1; PROJ="$proj"
  local errf="$TMPROOT/stderr.$$"
  OUT="$(printf '%s' "$pay" \
        | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
              ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
              bash "$proj/.claude/hooks/guard-publish-receipt.sh" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

# run_script <proj> <스크립트> [인자...] — 발급기·승인기 실행(같은 캡처 계약).
run_script() {
  local proj="$1" script="$2"
  shift 2
  OUT=''; ERR=''; RC=999; DID_RUN=1; PROJ="$proj"
  local errf="$TMPROOT/stderr.$$"
  OUT="$(env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
         bash "$proj/.claude/scripts/$script" ${@+"$@"} 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

# run_static <설명> <판정 스크립트> — 훅을 부르지 않는 정적 계약 검사 전용 진입점.
# DID_RUN 센티널은 **진입점 쪽**에서 세운다(케이스 안에서 세우면 나머지 전 행의
# 센티널이 통째로 무력화된다). 판정 스크립트는 어긋난 사유를 stdout 에 낸다.
run_static() {
  OUT=''; ERR=''; RC=0; DID_RUN=1; PROJ=''
  WHY="$(eval "$2")"
}

fixture_broken() {
  OUT=''; ERR=''; RC=-1; DID_RUN=1; PROJ=''
  FIXTURE_FAIL="$1"
}

ran=0
pass=0
fail=0

# 판정 헬퍼 — 전부 "이미 어긋난 사유가 있으면 아무것도 하지 않는다"로 시작한다.
# 첫 사유만 보고하면 원인이 가장 가까운 것 하나로 좁혀진다.
want_rc() {
  [ -z "$WHY" ] || return 0
  [ "$RC" -eq "$1" ] || WHY="종료 코드 $RC (기대 $1) — stderr: [$ERR]"
}
want_err() {
  [ -z "$WHY" ] || return 0
  case "$ERR" in
    *"$1"*) ;;
    *) WHY="stderr 에 기대 문구가 없다: [$1] — 실제: [$ERR]" ;;
  esac
}
want_no_err() {
  [ -z "$WHY" ] || return 0
  [ -n "$ERR" ] && WHY="stderr 가 비어 있지 않다: [$ERR]"
  return 0
}
want_file() {
  [ -z "$WHY" ] || return 0
  [ -e "$1" ] || WHY="있어야 할 파일이 없다: $1"
}
want_no_file() {
  [ -z "$WHY" ] || return 0
  [ -e "$1" ] && WHY="없어야 할 파일이 있다: $1"
  return 0
}
# want_count <디렉터리> <기대 개수> — 디렉터리 안 항목 수(숨김 제외).
want_count() {
  [ -z "$WHY" ] || return 0
  local n
  n="$(ls "$1" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$n" = "$2" ] || WHY="$1 항목 수 $n (기대 $2)"
}
# want_flag <값> — .needs-audit 에 그 줄이 있는가.
want_flag() {
  [ -z "$WHY" ] || return 0
  grep -qxF -- "$1" "$PROJ/.claude/.needs-audit" 2>/dev/null \
    || WHY="감사 플래그에 줄이 없다: [$1] — 실제: [$(cat "$PROJ/.claude/.needs-audit" 2>/dev/null)]"
}
want_no_flag_file() {
  [ -z "$WHY" ] || return 0
  [ -e "$PROJ/.claude/.needs-audit" ] \
    && WHY="감사 플래그가 서면 안 된다: [$(cat "$PROJ/.claude/.needs-audit" 2>/dev/null)]"
  return 0
}
# want_grep <파일> <문자열>
want_grep() {
  [ -z "$WHY" ] || return 0
  grep -qF -- "$2" "$1" 2>/dev/null || WHY="$1 에 [$2] 가 없다"
}

# ok <이름> — WHY 로 판정한다.
ok() {
  local why="$WHY"
  if [ -n "$FIXTURE_FAIL" ]; then
    why="픽스처 구성 실패: $FIXTURE_FAIL"
  elif [ "$DID_RUN" -ne 1 ]; then
    why='훅을 실행하지 않았다 (run_gate 누락 — 직전 케이스 결과를 재판정할 뻔했다)'
  fi
  if [ -z "$why" ]; then
    pass=$((pass + 1))
    printf '  ✓ %s\n' "$1"
  else
    fail=$((fail + 1))
    printf '  ✗ %s — %s\n' "$1" "$why"
  fi
}

# --- 케이스 --------------------------------------------------------------
# 판정 계약 표는 옆 파일에 있다. 헬퍼가 전부 정의된 **뒤에** 읽어야 한다
# (케이스 파일이 TOK_* 부재를 fail-closed 로 검사한다).
CASES_FILE="$TEST_DIR/publish-receipt-gate.cases.sh"
[ -f "$CASES_FILE" ] || {
  echo "✗ 케이스 파일을 찾지 못했습니다: $CASES_FILE (판정 계약 표 — 커밋에 포함됐는지 확인)" >&2
  exit 1
}
CASES_FILE2="$TEST_DIR/publish-receipt-gate.cases-2.sh"
[ -f "$CASES_FILE2" ] || {
  echo "✗ 케이스 파일 뒷조각을 찾지 못했습니다: $CASES_FILE2" >&2
  exit 1
}
# shellcheck source=publish-receipt-gate.cases.sh
. "$CASES_FILE"
# shellcheck source=publish-receipt-gate.cases-2.sh
. "$CASES_FILE2"

# --- 러너 ----------------------------------------------------------------

case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 중복됐거나 빠졌습니다" >&2
  exit 1
fi

echo "publish receipt gate — 판정 순서 계약"
for c in $CASES; do
  ran=$((ran + 1))
  DID_RUN=0
  FIXTURE_FAIL=''
  WHY=''
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
