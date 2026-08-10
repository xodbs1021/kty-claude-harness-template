#!/usr/bin/env bash
# self-discipline-gates.test.sh — 에이전트가 자기 규율을 우회하는 것을 막는 두 게이트.
#
#   guard-hook-disable  — 게이트를 끄는 환경변수 대입을 차단한다
#   stop:push           — 커밋했는데 원격에 없으면 턴을 못 끝낸다
#
# 둘 다 **조용한 실패**를 막는 장치라 위음성이 유일한 치명 결함이다. 통과시키는 순간
# 규율은 다시 산문으로 돌아가고, 산문은 어겨져도 아무것도 안 깨진다.
#
# guard-hook-disable 에는 **환경변수 탈출구가 없다.** 그 사실 자체를 케이스로 붙든다 —
# 탈출구가 생기면 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다.
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
# 셸 이식성: macOS 기본 bash 는 3.2 다.

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOKS="$REPO_ROOT/template/.claude/hooks"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (json_get 의존)" >&2; exit 1; }
command -v git     >/dev/null 2>&1 || { echo "✗ git 이 필요합니다 (push 게이트 픽스처)" >&2; exit 1; }
for f in guard-hook-disable.sh verify-before-stop.sh _common.sh; do
  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
done

TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'rm -rf "$TMPROOT"' EXIT

ran=0; pass=0; fail=0
RC=999; ERR=''; DID_RUN=0

report() {
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}

# --- guard-hook-disable ---------------------------------------------------

run_guard() {   # $1=명령문자열  [env 인자...]
  local cmd="$1" errf="$TMPROOT/gerr.$$"
  shift
  RC=999; ERR=''; DID_RUN=1
  python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd" \
    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$TMPROOT" \
          bash "$HOOKS/guard-hook-disable.sh" >/dev/null 2>"$errf"
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

gcase() {   # $1=이름 $2=명령 $3=기대rc [env 인자...]
  local name="$1" cmd="$2" want="$3" why=''
  shift 3
  run_guard "$cmd" ${@+"$@"}
  if [ "$DID_RUN" -ne 1 ]; then why='훅을 실행하지 않았다'
  elif [ "$RC" -ne "$want" ]; then why="rc=$RC (기대 $want) / $(printf '%s' "$ERR" | head -c 120)"
  elif [ "$want" -eq 2 ]; then
    case "$ERR" in
      *'사용자에게 물으세요'*) ;;
      *) why="차단은 했으나 '물어라'를 안 냈다: $(printf '%s' "$ERR" | head -c 120)" ;;
    esac
  elif [ -n "$ERR" ]; then why="통과인데 stderr 가 있다: $(printf '%s' "$ERR" | head -c 120)"
  fi
  report "$name" "$why"
}

g01() { gcase '전체 비활성 대입을 막는다'         'HARNESS_HOOKS=off claude'                 2; }
g02() { gcase '개별 비활성 대입을 막는다'         'ECC_DISABLED_HOOKS=stop:knowledge x'      2; }
g03() { gcase 'GateGuard 끄기를 막는다'           'ECC_GATEGUARD=off ./run.sh'               2; }
g04() { gcase 'export 형태도 막는다'              'export HARNESS_HOOKS=off'                 2; }
# **읽기는 정상 작업이다.** 값 확인·문서 검색까지 막으면 위양성으로 죽는다.
g05() { gcase '값을 읽는 것은 막지 않는다'        'echo "$HARNESS_HOOKS"'                    0; }
g06() { gcase '이름만 언급하는 것은 막지 않는다'  'grep -n ECC_DISABLED_HOOKS docs/usage.md' 0; }
g07() { gcase '접두사가 다른 변수는 막지 않는다'  'MY_ECC_GATEGUARD=1 ./x.sh'                0; }
# **이 훅에는 탈출구가 없다.** 있으면 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있다.
g08() { gcase '탈출구로 이 훅 자신을 끌 수 없다'   'HARNESS_HOOKS=off claude'                2 HARNESS_HOOKS=off; }
g09() { gcase '개별 비활성으로도 이 훅을 못 끈다'  'ECC_GATEGUARD=off x'                     2 ECC_DISABLED_HOOKS=pre:bash:hook-disable; }

# --- stop:push ------------------------------------------------------------

new_repo() {   # $1 = yes | no | noremote
  local pushed="$1" p
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
  p="$(CDPATH='' cd -- "$p" && pwd -P)"
  mkdir -p "$p/.claude/hooks" "$p/.claude/harness"
  cp "$HOOKS/_common.sh" "$HOOKS/verify-before-stop.sh" "$p/.claude/hooks/"
  git -C "$p" init -q -b work 2>/dev/null || { git -C "$p" init -q; git -C "$p" checkout -q -b work; }
  printf 'x\n' > "$p/f.txt"
  git -C "$p" add -A
  git -C "$p" -c user.email=t@t -c user.name=t commit -q -m c1
  if [ "$pushed" != 'noremote' ]; then
    git init -q --bare "$p.git"
    git -C "$p" remote add origin "$p.git"
    [ "$pushed" = 'yes' ] && git -C "$p" push -q -u origin work
  fi
  printf 'gate-target.ts\n' > "$p/.claude/.needs-audit"
  printf '%s\n' "$p"
}

run_stop() {   # $1=proj
  local proj="$1" errf="$TMPROOT/serr.$$"
  RC=999; ERR=''; DID_RUN=1
  printf '{"stop_hook_active": false}' \
    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
          bash "$proj/.claude/hooks/verify-before-stop.sh" >/dev/null 2>"$errf"
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

pcase() {   # $1=이름 $2=yes|no|noremote $3=있어야 할 문구 $4=있으면 안 되는 문구|-
  local name="$1" kind="$2" want="$3" forbid="$4" p why=''
  if ! p="$(new_repo "$kind")"; then report "$name" '픽스처 실패'; return 0; fi
  run_stop "$p"
  if [ "$RC" -ne 2 ]; then
    why="rc=$RC (기대 2 — 감사 플래그가 서 있으므로 어느 게이트든 막아야 한다)"
  else
    case "$ERR" in *"$want"*) ;; *) why="기대 문구 없음: $want / 실제 [$(printf '%s' "$ERR" | head -c 140)]" ;; esac
    if [ -z "$why" ] && [ "$forbid" != '-' ]; then
      case "$ERR" in *"$forbid"*) why="있으면 안 되는 문구: $forbid" ;; esac
    fi
  fi
  report "$name" "$why"
}

# 미push 면 push 게이트가 감사 게이트보다 **먼저** 막아야 한다 — 커밋이 사라지는 것이
# 감사 누락보다 비싸다.
p01() { pcase '미push 커밋이 있으면 막는다'              no       '커밋이 원격에 없습니다'     'completion-auditor 미실행'; }
p02() { pcase '원격 추적 ref 가 없으면 사유를 밝힌다'    no       '원격 추적 ref 가 없습니다'  '-'; }
p03() { pcase 'push 됐으면 push 게이트는 통과한다'       yes      'completion-auditor 미실행'  '커밋이 원격에 없습니다'; }
# origin 이 없는 저장소에서 push 를 요구하면 세션이 벽돌이 된다.
p04() { pcase 'origin 이 없으면 push 를 요구하지 않는다'  noremote 'completion-auditor 미실행'  '커밋이 원격에 없습니다'; }

# --- 러너 ----------------------------------------------------------------

CASES='g01 g02 g03 g04 g05 g06 g07 g08 g09 p01 p02 p03 p04'
EXPECTED_CASES=13

case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
  exit 1
fi

echo "자기 규율 게이트 — 무력화 차단 + push 미완 차단"
for c in $CASES; do ran=$((ran + 1)); DID_RUN=0; "$c"; done

if [ "$ran" -ne "$EXPECTED_CASES" ]; then echo "✗ 실행 ${ran}건 ≠ ${EXPECTED_CASES}건" >&2; exit 1; fi
if [ $((pass + fail)) -ne "$ran" ]; then echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1; fi

echo "— ${pass}/${ran} 통과"
[ "$fail" -eq 0 ] || exit 1
