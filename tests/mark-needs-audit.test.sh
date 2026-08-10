#!/usr/bin/env bash
# mark-needs-audit.test.sh — mark-needs-audit.sh 의 경로 → 판정 계약 회귀 테스트.
#
# 이 파일은 **진입점**이다: 환경 전제 검사, 픽스처 조립, 실행·판정 헬퍼, 러너.
# 판정 계약 표(케이스 정의 + CASES + EXPECTED_CASES)는 mark-needs-audit.cases.sh 에 있다.
# 한 파일에 두면 800줄을 넘어 표를 계획서와 대조하기 어려워지므로 갈랐다.
#
# 건수는 여기 적지 않는다 — 케이스를 추가할 때마다 낡는다.
# 기계 정본은 케이스 파일의 EXPECTED_CASES 이고 러너가 그 값을 강제한다.
#
# 왜 있나 (2026-08-04 실사고): 하네스 템플릿을 고치는 작업은 늘 PROJECT_DIR 밖의 별도
# 클론에서 일어나는데, 훅이 거기서 통째로 스킵돼 완료 게이트가 하나도 안 섰다. 게이트가
# 프로젝트는 지키면서 정작 하네스 자체 개발만 못 지킨 것이다. 범위 판정은 **조용히**
# 틀리는 종류의 버그라(플래그가 안 서도 아무 에러가 없다) 기계가 붙들어야 한다.
#
# 무엇을 붙드나: check_case 가 매 케이스에서 넷을 본다 — 판정(게이트/듀얼/스킵), 플래그에
# 적히는 **값**(안=상대경로, 밖=절대경로), 종료 코드 0(PostToolUse 는 절대 차단하지 않는다),
# 그리고 stderr 공백 + stdout(기록 실패·경로 개행일 때만 systemMessage JSON 1줄).
#
# 왜 set -e 가 없나: 비영 rc 와 실패 경로를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
#
# 이 파일 자신도 못 믿는다. 러너는 네 가지를 스스로 검사한다:
#   1) CASES 목록의 개수·중복  2) 실행 수 vs 기대 수  (케이스가 조용히 빠지거나 두 번 도는 것)
#   3) pass+fail == ran        (판정을 건너뛰거나 두 번 하는 것)
#   4) DID_RUN 센티널          (직전 케이스의 결과를 재판정하는 것)
#
# 환경 전제 (전부 fail-closed — 조용히 통과시키지 않는다): python3 부재 → 즉시 exit 1
# (json_get 이 조용히 빈 값을 내면 전 케이스가 "스킵"으로 보여 러너 전체가 위음성이 된다).
# git 부재 → 즉시 exit 1(저장소 귀속 판정 행이 전부 무의미해진다).
# root 로 실행 → 권한 픽스처(케이스 40)가 성립하지 않는다. 그 케이스만 fixture_broken.
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
#
# 사용법: ./tests/mark-needs-audit.test.sh   (전건 통과 시 종료 코드 0)

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOK="$REPO_ROOT/template/.claude/hooks/mark-needs-audit.sh"
COMMON="$REPO_ROOT/template/.claude/hooks/_common.sh"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (훅의 json_get 의존)" >&2; exit 1; }
command -v git     >/dev/null 2>&1 || { echo "✗ git 이 필요합니다 (저장소 귀속 판정 픽스처)" >&2; exit 1; }
[ -f "$HOOK" ]   || { echo "✗ 훅을 찾지 못했습니다: $HOOK" >&2; exit 1; }
[ -f "$COMMON" ] || { echo "✗ _common.sh 를 찾지 못했습니다: $COMMON" >&2; exit 1; }

# mktemp 실패를 확인하지 않으면 TMPROOT 가 빈 문자열이 되고, 이후 경로 조립이
# 전부 "/..." 즉 **파일시스템 루트**를 가리킨다.
TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
  exit 1
fi
# 픽스처 기본계약 1: 모든 픽스처 경로는 물리 경로다. macOS mktemp -d 는 /var/folders/...
# (→ /private/var/... 심링크)를 돌려주므로, 정규화하지 않으면 정상 행이 전부 의도치 않은
# 심링크 축이 된다. 심링크는 케이스 11·12 전용 헬퍼(new_symlinked_project)와 케이스 67·68
# 에서만 **의도적으로** 도입한다 — 67·68 은 프로젝트 **안**에서 밖을 가리키는 링크라
# 모양이 달라 헬퍼를 공유하지 않고 각 케이스 안에서 만든다.
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
# chmod 는 케이스 40 이 .claude 를 읽기전용으로 만들기 때문에 필요하다.
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

# --- 문구 조각 ------------------------------------------------------------
# 훅 문구가 다듬어져도 계약이 살아 있으면 계속 맞는 최소 조각.
TOK_WRITE_FAIL='게이트 플래그를 기록하지 못했다'
TOK_NEWLINE='편집 경로에 개행이 있어'
TOK_GIT_UNAVAILABLE='git 이 저장소 정보를 돌려주지 못해'

FLAG_NAMES='.needs-audit .needs-explain .needs-knowledge .needs-dualreview'

# --- 픽스처 조립 ----------------------------------------------------------

# new_dir <접두사> — TMPROOT 아래 픽스처 디렉토리를 만들고 **물리 경로**를 낸다.
new_dir() {
  local d
  d="$(mktemp -d "$TMPROOT/$1.XXXXXX")" || exit 1
  if [ -z "$d" ] || [ ! -d "$d" ]; then
    echo "✗ 케이스용 임시 디렉토리를 만들지 못했습니다" >&2
    exit 1
  fi
  ( CDPATH='' cd -- "$d" && pwd -P )
}

# new_project — 가짜 프로젝트. 훅과 _common.sh 를 **둘 다** 설치한다
# (훅이 dirname "$BASH_SOURCE"/_common.sh 를 source 하므로 하나만 두면 못 돈다).
new_project() {
  local p
  p="$(new_dir proj)"
  mkdir -p "$p/.claude/hooks"
  cp "$HOOK"   "$p/.claude/hooks/mark-needs-audit.sh"
  cp "$COMMON" "$p/.claude/hooks/_common.sh"
  printf '%s\n' "$p"
}

# make_harness_repo <디렉토리> — 하네스 정본 저장소 구조를 만들고 **실커밋**한다.
# --allow-empty 를 쓰지 않는다: git 은 빈 디렉토리를 추적하지 않으므로 template/.claude/ 아래에
# 실파일이 없으면 worktree(케이스 26)에서 정본 마커가 거짓이 된다 — 올바른 구현인데도 빨개진다.
make_harness_repo() {
  local r="$1"
  mkdir -p "$r/template/.claude/agents" "$r/template/.claude/skills" \
           "$r/template/.claude/hooks"  "$r/template/.claude/harness" \
           "$r/scripts" "$r/docs" "$r/_workspace" "$r/global-agents"
  printf '# common\n'        > "$r/template/.claude/hooks/_common.sh"
  printf '{}\n'              > "$r/template/.claude/settings.json"
  printf '# plan-reviewer\n' > "$r/template/.claude/agents/plan-reviewer.md"
  git -C "$r" init -q
  git -C "$r" add -A
  git -C "$r" -c user.email=t@t -c user.name=t commit -q -m init
}

# new_harness_repo — 프로젝트 골격 + 하네스 정본 구조. CLAUDE_PROJECT_DIR 자신이
# 정본인 케이스 50 이 이 결과를 PROJ 로 쓰기 때문에 훅 설치본도 함께 들고 있어야 한다.
new_harness_repo() {
  local r
  r="$(new_project)"
  make_harness_repo "$r"
  printf '%s\n' "$r"
}

# new_symlinked_project — 심링크 축(케이스 11·12) 전용. RED 전제 2개:
#   ① file_path 는 **물리**($REPO/app/...), CLAUDE_PROJECT_DIR 은 **심링크**($REPO/link).
#      반대로 주면 접두사가 그냥 맞아떨어져 두 행이 비차별 행으로 죽는다.
#   ② $REPO 가 **git 저장소**여야 기반 커밋 판이 밖 분기로 새어 오기록이 드러난다.
new_symlinked_project() {
  local repo
  repo="$(new_dir symrepo)"
  git -C "$repo" init -q
  mkdir -p "$repo/app/.claude/hooks"
  cp "$HOOK"   "$repo/app/.claude/hooks/mark-needs-audit.sh"
  cp "$COMMON" "$repo/app/.claude/hooks/_common.sh"
  ln -s "$repo/app" "$repo/link"
  printf '%s\n' "$repo"
}

# mkfile <경로> — 픽스처 기본계약 2: 대상 파일의 **부모 디렉토리를 만들고** 빈 파일을 만든다.
# 예외는 셋뿐이고 전부 그 케이스 주석에 예외임을 적었다: 케이스 51(부모 디렉토리를 일부러
# 만들지 않는다)·케이스 69·70(편집 경로가 디렉토리라 파일이 없다 — mkdir 만 한다).
#
# dirname 을 쓰지 않는 이유(실측): 명령 치환은 후행 개행을 지우므로 `sr⏎` 디렉토리가 조용히
# `sr` 로 바뀌어 케이스 57 의 파일 생성이 실패했다 — 이 러너가 붙들려는 결함 유형(값이 조용히
# 변조된다)에 러너 자신이 물린 것이다. ${1%/*} 파라미터 확장은 개행을 보존한다.
#
# 실패하면 FIXTURE_FAIL 센티널을 세운다. check_case 가 이걸 먼저 보고 빨갛게 만들므로
# "픽스처가 안 만들어졌는데 판정만 우연히 맞아 초록"이 되지 않는다(fail-closed).
# 중괄호가 필요하다: 리다이렉트 **열기** 실패는 셸이 보고하는데, 명령 뒤에 붙인
# 2>/dev/null 은 그 시점에 아직 적용되지 않아 러너 자신의 stderr 가 샌다(케이스 40 과 같은 함정).
mkfile() {
  local dir="${1%/*}"
  [ "$dir" = "$1" ] && dir='.'   # 슬래시 없는 상대 경로
  [ -z "$dir" ]     && dir='/'   # 루트 바로 아래
  if ! mkdir -p -- "$dir" 2>/dev/null; then
    FIXTURE_FAIL="부모 디렉토리를 만들지 못했다: $dir"
    return 1
  fi
  if ! { : > "$1"; } 2>/dev/null; then
    FIXTURE_FAIL="파일을 만들지 못했다: $1"
    return 1
  fi
}

payload_json() {
  python3 -c 'import json, sys
print(json.dumps({"tool_input": {"file_path": sys.argv[1]}}))' "$1"
}

# --- 실행·판정 헬퍼 -------------------------------------------------------

OUT=''
ERR=''
RC=0
STATE=''
DID_RUN=0   # 이번 케이스에서 훅(또는 정적 검사)을 실제로 돌렸는가 — 센티널
FIXTURE_FAIL=''   # 이번 케이스의 픽스처 조립이 실패했는가 — 사유(빈 문자열이면 정상)

# 플래그가 하나도 없는 빈 디렉토리. 훅을 돌리지 않는 케이스(정적 검사·픽스처 실패)가
# STATE 로 쓴다 — 직전 케이스의 플래그를 재판정하지 않게 하기 위함이다.
EMPTY_STATE="$(new_dir emptystate)"

# run_hook_raw <proj> <payload> [env 인자...]
# 앰비언트 탈출구를 **소거**하고 부른다. 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off /
# ECC_DISABLED_HOOKS 를 export 한 셸에서 도는 워크플로라, 소거하지 않으면 게이트·듀얼 행이
# 전부 무판정으로 떨어져 러너가 통째로 위음성이 된다. 케이스 43·44 만 **의도적으로** 다시
# 주입한다(env 는 -u 를 먼저 처리하고 그 뒤 할당을 적용하므로 재주입이 이긴다 — 실측 확인).
# GIT_* 소거는 러너를 git 훅 안에서 돌렸을 때 귀속 판정이 오염되는 것을 막는다.
run_hook_raw() {
  local proj="$1" payload="$2"
  shift 2
  OUT=''; ERR=''; RC=999; DID_RUN=1
  STATE="$proj/.claude"
  local errf="$TMPROOT/stderr.$$"
  OUT="$(printf '%s' "$payload" \
        | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
              -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
              ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
              bash "$proj/.claude/hooks/mark-needs-audit.sh" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

# run_hook <proj> <file_path> [env 인자...]
run_hook() {
  local proj="$1" fp="$2"
  shift 2
  run_hook_raw "$proj" "$(payload_json "$fp")" ${@+"$@"}
}

# run_static_check <설명> <grep -E 패턴> — 훅 **본문**에 대한 정적 계약 검사 전용 진입점.
# 훅을 호출하지 않는 케이스이지만 DID_RUN 센티널은 살아 있어야 한다. check_case 안에서
# 센티널을 세우는 우회를 하면 나머지 전 행의 센티널이 통째로 무력화되므로 **진입점 쪽**에서 세운다.
# 검사 대상은 저장소의 정본 훅이다(픽스처 사본이 아니다) — 그래야 되돌림 실측에서 함께 뒤집힌다.
run_static_check() {
  OUT=''; ERR=''; RC=0; DID_RUN=1
  STATE="$EMPTY_STATE"
  local hits
  hits="$(grep -nE "$2" "$HOOK")"
  if [ -n "$hits" ]; then
    OUT="정적 계약 위반 — $1
$hits"
    RC=1
  fi
}

# 픽스처를 이 환경에서 만들 수 없을 때. 조용히 넘어가지 않고 실패로 남긴다.
fixture_broken() {
  OUT="픽스처 구성 실패: $1"
  ERR=''
  RC=-1
  STATE="$EMPTY_STATE"
  DID_RUN=1
}

ran=0
pass=0
fail=0

# flag_bytes <플래그이름> — 플래그 파일 내용을 **바이트 그대로** FLAG_BYTES 에 담는다.
# stdout 으로 돌려주지 않는 이유: 호출자의 명령 치환이 후행 개행을 지워버려 "값 한 줄"과
# "두 줄이었는데 덮어써진 것"·"개행이 섞여 들어간 것"이 구분되지 않는다. 센티널 X 를
# 붙여 받고 도로 떼면 바이트가 보존된다. 파일이 없으면 빈 문자열.
FLAG_BYTES=''
flag_bytes() {
  local raw
  raw="$(cat "$STATE/$1" 2>/dev/null; printf 'X')"
  FLAG_BYTES="${raw%X}"
}

# verdict_mismatch <gate|dual|none> <값> — 어긋난 사유를 내고, 맞으면 아무것도 안 낸다.
# <값>은 **줄 목록**이다 — 여러 줄이면 줄 수와 기록 **순서**까지 계약이 된다(케이스 58).
# 기대 바이트열은 각 줄 뒤에 개행 하나씩: record_flag 가 printf '%s\n' 로 덧붙이므로.
# gate      = 4종 전부가 그 바이트열
# designdoc = .needs-dualreview + .needs-knowledge (설계·계획 산출물)
# knowledge = .needs-knowledge 만 (결정 문서 — 코드가 아니라 게이트 4종은 과하다)
# none      = 4종 전부 부재·공백
verdict_mismatch() {
  local kind="$1" value="$2" f want
  for f in $FLAG_NAMES; do
    want=''
    case "$kind" in
      gate) want="$value"$'\n' ;;
      designdoc)
        case "$f" in
          .needs-dualreview|.needs-knowledge) want="$value"$'\n' ;;
        esac ;;
      knowledge) [ "$f" = '.needs-knowledge' ] && want="$value"$'\n' ;;
      none) want='' ;;
      *)    printf '알 수 없는 기대 판정: %s' "$kind"; return 0 ;;
    esac
    flag_bytes "$f"
    if [ "$FLAG_BYTES" != "$want" ]; then
      printf '%s 내용 [%s] (기대 [%s])' "$f" "$FLAG_BYTES" "$want"
      return 0
    fi
  done
}

# stdout_mismatch [토큰] — 토큰이 없으면 stdout 공백을, 있으면 **유효 JSON + systemMessage
# 키 + 토큰 포함**을 요구한다. JSON 유효성을 기계로 보는 이유: 훅이 이스케이프를 틀리면
# 사용자에게 아무것도 안 보이는데 문자열 포함 검사만으로는 그 실패가 통째로 통과한다.
stdout_mismatch() {
  local token="${1-}"
  if [ -z "$token" ]; then
    [ -n "$OUT" ] && printf 'stdout 이 비어 있지 않다: [%s]' "$OUT"
    return 0
  fi
  if ! printf '%s' "$OUT" | python3 -c 'import json, sys
d = json.loads(sys.stdin.read())
sys.exit(0 if isinstance(d, dict) and isinstance(d.get("systemMessage"), str) else 1)' 2>/dev/null; then
    printf 'stdout 이 systemMessage 를 가진 유효 JSON 이 아니다: [%s]' "$OUT"
    return 0
  fi
  case "$OUT" in
    *"$token"*) ;;
    *) printf 'stdout 에 기대 문구가 없다: %s' "$token" ;;
  esac
}

# check_case <이름> <기대rc> <gate|dual|none> <기대값> [기대 stdout 토큰]
# ran 은 여기서 세지 않는다 — 디스패처가 센다. 그래야 "한 케이스가 두 번 판정하고
# 다른 하나가 판정을 건너뜀"을 pass+fail ≠ ran 으로 잡을 수 있다.
check_case() {
  local name="$1" want_rc="$2" kind="$3" value="${4-}" token="${5-}" why=''

  if [ -n "$FIXTURE_FAIL" ]; then
    why="픽스처 구성 실패: $FIXTURE_FAIL"
  elif [ "$DID_RUN" -ne 1 ]; then
    why='훅을 실행하지 않았다 (run_hook 누락 — 직전 케이스 결과를 재판정할 뻔했다)'
  elif [ "$RC" -ne "$want_rc" ]; then
    why="종료 코드 $RC (기대 $want_rc)"
  elif [ -n "$ERR" ]; then
    why="stderr 가 비어 있지 않다: [$ERR]"
  else
    why="$(verdict_mismatch "$kind" "$value")"
    [ -z "$why" ] && why="$(stdout_mismatch "$token")"
  fi

  if [ -z "$why" ]; then
    pass=$((pass + 1))
    printf '  ✓ %s\n' "$name"
  else
    fail=$((fail + 1))
    printf '  ✗ %s — %s\n' "$name" "$why"
    [ -n "$OUT" ] && printf '%s\n' "$OUT" | sed 's/^/      | /'
  fi
}

# --- 케이스 --------------------------------------------------------------
# 판정 계약 표는 옆 파일에 있다. 헬퍼가 전부 정의된 **뒤에** 읽어야 한다
# (케이스 파일이 TOK_* 부재를 fail-closed 로 검사한다).
# 존재 검사를 앞에 둔다: 없으면 set -u 덕에 CASES unbound 로 **우연히** 죽을 뿐이라
# 사유가 드러나지 않는다. 커밋에서 빠뜨리기 쉬운 파일이므로(추가 당시 미추적) 명시적으로 막는다.
CASES_FILE="$TEST_DIR/mark-needs-audit.cases.sh"
[ -f "$CASES_FILE" ] || {
  echo "✗ 케이스 파일을 찾지 못했습니다: $CASES_FILE (판정 계약 표 — 커밋에 포함됐는지 확인)" >&2
  exit 1
}
# shellcheck source=mark-needs-audit.cases.sh
. "$CASES_FILE"

# --- 러너 ----------------------------------------------------------------

# 목록 자체의 중복·누락을 먼저 본다. 실행 수만 세면 "하나 중복 + 하나 누락"이
# 상쇄돼 그대로 초록이 된다 — 목록을 직접 봐야 그 조합이 잡힌다.
case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 중복됐거나 빠졌습니다" >&2
  exit 1
fi

echo "mark-needs-audit — 경로 판정 계약"
for c in $CASES; do
  ran=$((ran + 1))
  DID_RUN=0
  FIXTURE_FAIL=''
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
