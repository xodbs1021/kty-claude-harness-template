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
TOK_WEDGED_APPROVAL='승인 소비가 중단된 흔적'
TOK_SYMLINK='심볼릭 링크'
TOK_TOOBIG='너무 큽니다'
# **문구를 좁게 잡는다.** used/ 판정 실패는 두 곳에서 막을 수 있는데(7단 replay 판정과
# 13단 소비 직전 재확인), 둘을 같은 조각으로 재면 앞 단이 죽어도 뒤 단이 대신 막아
# "앞 단이 사라진 것"을 못 본다 — 2차 검수의 CRITICAL 이 정확히 그 형태였다.
TOK_STATE='재발행 여부를 판정할 수 없어'
TOK_REGISTRY_PATH='목록:'
# 아래 둘은 판독기(_common.sh)의 사유 문구다. 같은 "영수증 형식" 차단 안에서 **어느 검사가
# 걸었는지**를 가르기 위해 조각을 따로 둔다 — 안 가르면 문자집합 검사를 지워도 도구명
# 불일치 검사가 같은 문구로 막아 변이가 살아남는다.
TOK_CHARSET='outside the allowed set'
TOK_NONCE_BAD='nonce has unsupported'

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

# new_project [디렉터리 접두어] — 훅·_common.sh·발급기·승인기·registry·receipts 골격을
# 갖춘 가짜 프로젝트. 접두어를 주면 그 이름으로 만든다 — **공백이 든 경로**를 만들기
# 위해서다(비인용 글로브·워드 스플리팅 결함은 공백 없는 경로에서 전부 초록으로 보인다).
new_project() {
  local p
  p="$(new_dir "${1:-proj}")"
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

# run_gate_limited <초> <proj> <payload> [env 인자...] — **감시 시간이 붙은** 실행.
# 훅이 끝나지 않는 결함(FIFO·무한 스트림 재해시)을 겨누는 케이스 전용이다. 보통의
# run_gate 로 그런 케이스를 돌리면 러너 자신이 영원히 멈춰 CI 가 타임아웃으로만 죽는다 —
# 무엇이 잘못됐는지 아무도 모른 채. 시간이 넘으면 RC=-9 로 표시해 그 자체를 실패로 만든다.
run_gate_limited() {
  local secs="$1" proj="$2" pay="$3"
  shift 3
  OUT=''; ERR=''; RC=999; DID_RUN=1; PROJ="$proj"
  local errf="$TMPROOT/lerr.$$" outf="$TMPROOT/lout.$$" rcf="$TMPROOT/lrc.$$"
  rm -f "$rcf" "$outf" "$errf"
  ( printf '%s' "$pay" \
      | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
            bash "$proj/.claude/hooks/guard-publish-receipt.sh" >"$outf" 2>"$errf"
    echo $? > "$rcf" ) &
  local pid=$! i=0
  while [ "$i" -lt $((secs * 10)) ]; do
    kill -0 "$pid" 2>/dev/null || break
    sleep 0.1
    i=$((i + 1))
  done
  if kill -0 "$pid" 2>/dev/null; then
    pkill -9 -P "$pid" 2>/dev/null
    kill -9 "$pid" 2>/dev/null
    wait "$pid" 2>/dev/null
    RC=-9
    OUT=''
    ERR='(감시 시간 초과 — 훅이 끝나지 않았다)'
    return 0
  fi
  wait "$pid" 2>/dev/null
  RC="$(cat "$rcf" 2>/dev/null)"
  [ -n "$RC" ] || RC=999
  OUT="$(cat "$outf" 2>/dev/null)"
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$outf" "$errf" "$rcf"
}

# make_noisy_python <디렉터리> <stdout|stderr> — python 시작 시 잡음을 내는 환경을 만든다.
# 검수자가 실측한 재현(깨진 .pth 가 인터프리터 시작마다 오류를 뱉는 환경)을 sitecustomize
# 로 똑같이 재현한다 — site 모듈이 시작 시 자동 import 하므로 `python3 -c` 에도 걸린다.
# 반환: PYTHONPATH 에 넣을 디렉터리 경로.
make_noisy_python() {
  local d="$1" where="$2"
  mkdir -p "$d"
  if [ "$where" = 'stdout' ]; then
    printf 'import sys\nsys.stdout.write("junk-from-broken-pth\\n")\n' > "$d/sitecustomize.py"
  else
    printf 'import sys\nsys.stderr.write("Error processing line 1 of broken.pth:\\n")\n' > "$d/sitecustomize.py"
  fi
  printf '%s\n' "$d"
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
# want_no_esc — 차단 메시지에 **ESC 바이트가 없어야 한다**. 있으면 payload 유래 문자열이
# 무가공으로 나간 것이고, 그 순간 터미널 제어열로 하네스 문구를 위조할 수 있다.
want_no_esc() {
  [ -z "$WHY" ] || return 0
  if printf '%s' "$ERR" | LC_ALL=C grep -q "$(printf '\033')"; then
    WHY='차단 메시지에 ESC 제어문자가 그대로 실렸다 (문구 위조 가능)'
  fi
  return 0
}

# want_one_block_line — `[Hook 차단]` 으로 시작하는 줄이 정확히 하나여야 한다.
# 개행이 든 값이 무가공으로 나가면 공격자가 가짜 하네스 줄을 한 줄 더 만들 수 있다.
want_one_block_line() {
  [ -z "$WHY" ] || return 0
  local n
  n="$(printf '%s\n' "$ERR" | grep -c '^\[Hook ' 2>/dev/null | tr -d ' ')"
  [ "$n" = '1' ] || WHY="[Hook …] 로 시작하는 줄이 ${n}개다 (기대 1 — 줄 위조 가능)"
}

# want_no_uniformat — 차단 메시지에 **유니코드 서식문자**가 없어야 한다.
# ASCII 제어문자만 걷어내면 U+2028(줄 구분자)·U+202E(RLO)가 남아 렌더러에서 줄이 갈리거나
# 글자 순서가 뒤집힌다 — 제어문자를 지운 것과 같은 효과가 다른 부호점으로 되살아난다.
want_no_uniformat() {
  [ -z "$WHY" ] || return 0
  local ch
  for ch in "$(printf '\342\200\250')" "$(printf '\342\200\256')"; do
    if printf '%s' "$ERR" | LC_ALL=C grep -qF "$ch"; then
      WHY='차단 메시지에 유니코드 서식문자(U+2028/U+202E)가 그대로 실렸다'
      return 0
    fi
  done
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
