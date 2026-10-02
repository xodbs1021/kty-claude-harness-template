#!/usr/bin/env bash
# worktree-project-dir.test.sh — 워크트리 세션의 **고정 프로젝트 루트** 회귀 방어.
#
#   "세션의 루트는 그 세션의 첫 훅 호출(cwd 가 있는 것) 때 한 번 정해 세션 상태 폴더의
#    .root 에 고정한다. 이후 cwd 가 바뀌어도 무시한다. 그 세션의 모든 훅은 그 루트 하나로
#    판정하고, 다른 체크아웃의 파일을 고치면 그 파일은 그 세션 루트의 의무로 잡힌다."
#    (kty 결정 2026-10-02)
#
# 왜 필요한가 (2026-10-01 실측): 데스크톱 앱은 워크트리 세션에도 CLAUDE_PROJECT_DIR 로
# **메인 체크아웃**을 넘긴다. 워크트리는 메인 아래 .claude/worktrees/<이름>/ 에 있어서
# 워크트리 파일이 `.claude/worktrees/…` 로 잡혀 분류에서 통째로 빠졌다 — 워크트리 세션의
# 코드 편집에 게이트가 하나도 서지 않았다. Stop 의 push·리뷰 산출물 탐색도 메인을 봤다.
#
# 고정틀은 실물과 같은 배치다: 실제 git 저장소(메인, 브랜치 main) + `git worktree add` 로
# 만든 링크된 워크트리를 <메인>/.claude/worktrees/w/ (브랜치 wt)에 둔다. 원격은 bare 저장소.
# 훅은 메인의 .claude/hooks/ 에서 CLAUDE_PROJECT_DIR=<메인> 으로 부른다(settings.json 과 같다).
#
# **판정 규칙의 사본을 두지 않는다.** 훅을 돌려 파일 위치·rc·메시지로 잰다. 세션 폴더 이름
# 규칙(SHA-256 앞 32자)만은 위치를 단언하려고 다시 계산한다(session-state-isolation 과 같다).
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. mapfile·연관배열·${var,,} 금지.

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOKS="$REPO_ROOT/template/.claude/hooks"
readonly HOOK_FILES='_common.sh verify-before-stop.sh mark-needs-audit.sh mark-bash-window.sh
guard-publish-review.sh guard-master-commit.sh guard-harness-drift.sh guard-design-path.sh
check-harness-env.sh'

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (payload 픽스처 의존)" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "✗ git 이 필요합니다 (워크트리 고정틀)" >&2; exit 1; }
for f in $HOOK_FILES; do
  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
done

TMPROOT="$(mktemp -d)" || exit 1
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'rm -rf "$TMPROOT"' EXIT

ran=0; pass=0; fail=0
RC=999; ERR=''; OUT=''
M=''; W=''   # 현재 고정틀의 메인 체크아웃 · 워크트리 (물리 경로)

readonly SID_W='33333333-cccc-4ccc-8ccc-cccccccccccc'   # 워크트리에서 시작하는 세션
readonly SID_M='44444444-dddd-4ddd-8ddd-dddddddddddd'   # 메인에서 시작하는 세션
CUR_SID="$SID_W"   # 훅 입력에 실을 session_id. 빈 값이면 키 자체를 뺀다(옛 클라이언트).
readonly TOK_BLOCK='[완료 차단]'
readonly TOK_DUAL='codex 듀얼 리뷰 미수행'
readonly TOK_PUSH='커밋이 원격에 없습니다'

report() {
  ran=$((ran + 1))
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}

contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

# g <디렉토리> <git 인자>... — 신원·환경을 고정한 git. 시험 머신의 전역 설정을 타지 않는다.
g() {
  local d="$1"; shift
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
    git -C "$d" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@"
}

# sdir — 메인 체크아웃 아래 지금 세션(CUR_SID)의 상태 폴더. 세션이 없으면 공유 폴더.
sdir() {
  if [ -z "$CUR_SID" ]; then printf '%s/.claude' "$M"; return 0; fi
  printf '%s/.claude/.sessions/%s' "$M" \
    "$(printf '%s' "$CUR_SID" | python3 -c 'import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest()[:32])')"
}
audit_flag() { printf '%s/.needs-audit' "$(sdir)"; }
root_file()  { printf '%s/.root' "$(sdir)"; }
first_flag() { head -n 1 "$(audit_flag)" 2>/dev/null; }
all_flags()  { tr '\n' ' ' < "$(audit_flag)" 2>/dev/null; }

# new_fixture [부모 디렉토리] — 메인(main) + 워크트리(wt) + bare 원격. 둘 다 원격과 동기화된
# 상태로 시작한다. .claude/·_workspace/ 는 추적하지 않는다 — 워크트리에는 harness.env 가 없다.
new_fixture() {
  local base parent="${1:-$TMPROOT}"
  mkdir -p "$parent" || return 1
  base="$(mktemp -d "$parent/fx.XXXXXX")" || return 1
  CUR_SID="$SID_W"
  M="$base/main"; W="$M/.claude/worktrees/w"
  g "$base" init -q --bare origin.git || return 1
  mkdir -p "$M" || return 1
  g "$M" init -q -b main || return 1
  mkdir -p "$M/src" "$M/.claude/hooks" "$M/.claude/harness" "$M/_workspace" || return 1
  printf 'x\n' > "$M/src/a.ts"
  printf '.claude/\n_workspace/\n' > "$M/.gitignore"
  g "$M" add -A && g "$M" commit -q -m init || return 1
  g "$M" remote add origin "$base/origin.git" && g "$M" push -q -u origin main 2>/dev/null || return 1
  g "$M" worktree add -q -b wt "$W" 2>/dev/null || return 1
  g "$W" push -q -u origin wt 2>/dev/null || return 1
  mkdir -p "$W/_workspace" || return 1
  for f in $HOOK_FILES; do cp "$HOOKS/$f" "$M/.claude/hooks/" || return 1; done
  write_env "$M" ''
}

# write_env <체크아웃> <타입체크 명령> — 타입체크 외 게이트는 끈 harness.env.
write_env() {
  mkdir -p "$1/.claude/harness" || return 1
  printf "HARNESS_TYPECHECK_CMD='%s'\nHARNESS_STYLECHECK_CMD=\"\"\nHARNESS_KNOWLEDGE_GATE=\"\"\n" "$2" \
    > "$1/.claude/harness/harness.env"
}

# payload <키=값>... — JSON 한 줄. 점 경로 키는 중첩으로. CUR_SID 가 있으면 session_id 로 싣는다.
payload() {
  python3 - "$CUR_SID" "$@" <<'PY'
import json, sys
d = {"session_id": sys.argv[1]} if sys.argv[1] else {}
for kv in sys.argv[2:]:
    k, v = kv.split("=", 1)
    cur = d
    parts = k.split(".")
    for p in parts[:-1]:
        cur = cur.setdefault(p, {})
    cur[parts[-1]] = False if v == "__false__" else v
print(json.dumps(d))
PY
}

# run_hook <훅파일> <payload JSON> — 메인의 설치본을 CLAUDE_PROJECT_DIR=<메인> 으로.
run_hook() {
  local errf="$TMPROOT/err.$$" outf="$TMPROOT/out.$$"
  RC=999; ERR=''; OUT=''
  # HOOK_ENV(선택) — 훅에만 얹을 환경 대입들. 값에 공백이 없다는 전제로 단어 분리한다.
  # shellcheck disable=SC2086
  ( cd "$TMPROOT" && printf '%s' "$2" | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
      CLAUDE_PROJECT_DIR="$M" ${HOOK_ENV:-} bash "$M/.claude/hooks/$1" >"$outf" 2>"$errf" )
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"; OUT="$(cat "$outf" 2>/dev/null)"
  rm -f "$errf" "$outf"
}

# call <훅파일> <cwd|""> <키=값>... — cwd 가 빈 값이면 키 자체를 뺀다. 경로에 공백이 있어도 된다.
call() {
  local hook="$1" cwd="$2"
  shift 2
  [ -n "$cwd" ] && set -- "$@" "cwd=$cwd"
  run_hook "$hook" "$(payload "$@")"
}

edit()     { call mark-needs-audit.sh "$1" tool_name=Edit "tool_input.file_path=$2"; }
stop()     { call verify-before-stop.sh "$1" stop_hook_active=__false__; }
publish()  { call guard-publish-review.sh "$1" tool_name=mcp__x__addCommentToJiraIssue tool_input.body=x; }
window()   { call mark-bash-window.sh "$1" tool_name=Bash tool_input.command=x; }
bashpost() { call mark-needs-audit.sh "$1" tool_name=Bash "tool_input.command=$2"; }
bashpre()  { call "$1" "$2" tool_name=Bash "tool_input.command=$3"; }

# --- 기본: 워크트리 세션의 루트는 워크트리 --------------------------------

w01() {
  local name='w01 워크트리 세션의 src 편집 → 세션 폴더에 src/a.ts (루트 W 기준 상대), .root = W' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W" "$W/src/a.ts"
  if   ! grep -qxF 'src/a.ts' "$(audit_flag)" 2>/dev/null; then why="세션 폴더에 src/a.ts 없음 (rc=$RC $(first_flag))"
  elif [ "$(cat "$(root_file)" 2>/dev/null)" != "$W" ];   then why=".root 가 W 가 아니다: $(cat "$(root_file)" 2>/dev/null)"
  elif [ -e "$W/.claude/.sessions" ];                      then why='세션 폴더가 워크트리 아래에 생겼다 — 상태는 메인에 남아야 한다'
  fi
  report "$name" "$why"
}

w02() {
  local name='w02 그 세션의 Stop 은 게이트로 막힌다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W" "$W/src/a.ts"
  stop "$W"
  if   [ "$RC" -ne 2 ];                then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_BLOCK"; then why="게이트 미도달: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

w03() {
  local name='w03 push 미완 판정은 세션 루트의 브랜치 — W 세션은 wt, M 세션은 main' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf 'y\n' > "$W/src/a.ts"
  g "$W" commit -q -am wip || { report "$name" '전제 실패 — 커밋'; return 0; }
  stop "$W"
  if   [ "$RC" -ne 2 ];                 then why="워크트리 세션 rc=$RC (기대 2 — wt 가 원격보다 앞섬)"
  elif ! contains "$ERR" "$TOK_PUSH";   then why="push 게이트가 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! contains "$ERR" 'origin wt';   then why='안내의 브랜치가 wt 가 아니다'
  else
    CUR_SID="$SID_M"
    stop "$M"
    [ "$RC" -eq 0 ] || why="메인 세션 rc=$RC (기대 0 — main 은 원격과 같다)"
  fi
  report "$name" "$why"
}

w04() {
  local name='w04 워크트리 _workspace 의 *codex*.md 가 듀얼리뷰 게이트를 푼다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W" "$W/src/a.ts"
  [ -s "$(sdir)/.needs-dualreview" ] || { report "$name" '전제 실패 — 듀얼리뷰 플래그가 안 섰다'; return 0; }
  sleep 1
  printf 'review\n' > "$W/_workspace/01_codex_review.md"
  stop "$W"
  if   contains "$ERR" "$TOK_DUAL";          then why='듀얼리뷰 게이트가 안 풀렸다'
  elif [ -e "$(sdir)/.needs-dualreview" ];   then why='듀얼리뷰 플래그가 남았다'
  fi
  report "$name" "$why"
}

w05() {
  local name='w05 메인 _workspace 의 *codex*.md 로는 워크트리 세션의 게이트가 안 풀린다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W" "$W/src/a.ts"
  sleep 1
  printf 'review\n' > "$M/_workspace/01_codex_review.md"
  stop "$W"
  if   [ "$RC" -ne 2 ];               then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_DUAL"; then why="듀얼리뷰 게이트가 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

w06() {
  local name='w06 발행 가드는 워크트리 _workspace 의 산출물을 본다 (메인 것은 안 본다)' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf 'review\n' > "$W/_workspace/01_codex_review.md"
  publish "$W"
  if [ "$RC" -ne 0 ]; then
    why="워크트리 산출물로 rc=$RC (기대 0): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  else
    rm -f "$W/_workspace/01_codex_review.md"
    printf 'review\n' > "$M/_workspace/01_codex_review.md"
    publish "$W"
    if   [ "$RC" -ne 2 ];          then why="메인 산출물만 있을 때 rc=$RC (기대 2)"
    elif ! contains "$ERR" '최근'; then why="사유가 ②가 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
    fi
  fi
  report "$name" "$why"
}

w07() {
  local name='w07 harness.env 는 워크트리 것이 우선 — 타입체크도 워크트리에서 돈다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  write_env "$M" 'echo MAINENV $(pwd -P); exit 1'
  write_env "$W" 'echo WTENV $(pwd -P); exit 1'
  edit "$W" "$W/src/a.ts"
  stop "$W"
  if   [ "$RC" -ne 2 ];                    then why="rc=$RC (기대 2)"
  elif contains "$ERR" 'MAINENV';          then why='메인 harness.env 를 읽었다'
  elif ! contains "$ERR" "WTENV $W";       then why="워크트리 env·워크트리 cwd 가 아니다: $(printf '%s' "$ERR" | grep ENV | head -1 | head -c 120)"
  fi
  report "$name" "$why"
}

w08() {
  local name='w08 워크트리에 harness.env 가 없으면 메인 것 — 실행 위치는 워크트리' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  write_env "$M" 'echo MAINENV $(pwd -P); exit 1'
  edit "$W" "$W/src/a.ts"
  stop "$W"
  if   [ "$RC" -ne 2 ];                  then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "MAINENV $W";   then why="메인 env·워크트리 cwd 가 아니다: $(printf '%s' "$ERR" | grep ENV | head -1 | head -c 120)"
  fi
  report "$name" "$why"
}

# --- 하위 호환과 판정 실패 ------------------------------------------------

w09() {
  local name='w09 session_id 없음 → 원래 루트(M) · .root 를 쓰지 않는다 — W 파일은 절대경로 의무' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  CUR_SID=''
  edit "$W" "$W/src/a.ts"
  if   ! grep -qxF "$W/src/a.ts" "$(audit_flag)" 2>/dev/null; then why="공유 폴더에 $W/src/a.ts 없음 (rc=$RC $(first_flag))"
  elif [ -e "$M/.claude/.root" ];                             then why='세션 번호가 없는데 공유 폴더에 .root 를 썼다'
  fi
  report "$name" "$why"
}

w10() {
  local name='w10 M 세션 — 메인 편집은 src/a.ts, 워크트리 파일 편집은 그 세션의 의무(절대경로)' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  CUR_SID="$SID_M"
  edit "$M" "$M/src/a.ts"
  if ! grep -qxF 'src/a.ts' "$(audit_flag)" 2>/dev/null; then
    why="메인 편집 플래그가 없다 (rc=$RC $(first_flag))"
  else
    edit "$M" "$W/src/a.ts"
    grep -qxF "$W/src/a.ts" "$(audit_flag)" 2>/dev/null \
      || why="워크트리 파일이 의무로 안 잡혔다: $(all_flags)"
  fi
  report "$name" "$why"
}

w11() {
  local name='w11 cwd=다른 저장소의 링크된 워크트리 → 루트는 메인 그대로' why='' o
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  # 다른 저장소도 **링크된 워크트리**여야 "같은 저장소인가" 판정만 따로 잰다 — 메인 체크아웃이면
  # 링크 판정이 먼저 걸러 버려 같은 저장소 판정을 지운 변이가 초록으로 남는다.
  o="$TMPROOT/other.$RANDOM"
  mkdir -p "$o/r" && g "$o/r" init -q -b main && g "$o/r" commit -q --allow-empty -m init \
    && g "$o/r" worktree add -q -b ow "$o/w" 2>/dev/null || { report "$name" '픽스처 실패 — 다른 저장소'; return 0; }
  edit "$o/w" "$M/src/a.ts"
  if   ! grep -qxF 'src/a.ts' "$(audit_flag)" 2>/dev/null; then why="메인 편집이 src/a.ts 로 안 적혔다: $(first_flag)"
  elif [ "$(cat "$(root_file)" 2>/dev/null)" != "$M" ];  then why=".root 가 M 이 아니다: $(cat "$(root_file)" 2>/dev/null)"
  fi
  report "$name" "$why"
}

w12() {
  local name='w12 cwd 가 워크트리의 하위 폴더여도 워크트리가 루트' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W/src" "$W/src/a.ts"
  grep -qxF 'src/a.ts' "$(audit_flag)" 2>/dev/null || why="세션 폴더에 src/a.ts 없음 (rc=$RC $(first_flag))"
  report "$name" "$why"
}

w13() {
  local name='w13 Bash 스윕 — 워크트리에서 Bash 로 쓴 파일도 게이트' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  sleep 1
  printf 'y\n' > "$W/src/b.ts"
  bashpost "$W" 'printf y > src/b.ts'
  grep -qxF 'src/b.ts' "$(audit_flag)" 2>/dev/null \
    || why="세션 폴더에 src/b.ts 없음 (rc=$RC $(first_flag))"
  report "$name" "$why"
}

w14() {
  local name='w14 기본 브랜치 커밋 가드는 세션 루트의 브랜치를 본다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  bashpre guard-master-commit.sh "$W" 'git commit -m x'
  if [ "$RC" -ne 0 ]; then
    why="워크트리(wt) 커밋이 막혔다 rc=$RC"
  else
    CUR_SID="$SID_M"
    bashpre guard-master-commit.sh "$M" 'git commit -m x'
    [ "$RC" -eq 2 ] || why="메인(main) 커밋이 안 막혔다 rc=$RC"
  fi
  report "$name" "$why"
}

w15() {
  local name='w15 하네스 드리프트 가드는 워크트리 세션에서 워크트리를 대조한다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  # 워크트리에는 .claude/harness 가 없다(추적 안 함) — 대조 불가로 막혀야 한다.
  bashpre guard-harness-drift.sh "$W" 'ls'
  if [ "$RC" -ne 2 ]; then
    why="워크트리 세션 rc=$RC (기대 2 — 워크트리 하네스 부재)"
  else
    CUR_SID=''
    bashpre guard-harness-drift.sh "" 'ls'
    [ "$RC" -eq 0 ] || why="cwd 없는 입력 rc=$RC (기대 0 — 지금 동작)"
  fi
  report "$name" "$why"
}

w16() {
  local name='w16 설계 경로 가드 — 워크트리 .claude/skills 는 정의 디렉토리라 면제' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  mkdir -p "$W/.claude/skills/x"
  call guard-design-path.sh "$W" tool_name=Write "tool_input.file_path=$W/.claude/skills/x/design.md" tool_input.content=x
  [ "$RC" -eq 0 ] || why="rc=$RC (기대 0): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  report "$name" "$why"
}

w17() {
  local name='w17 harness.env 편집 검증 — 상대경로는 워크트리 기준' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  write_env "$W" ''
  printf 'HARNESS_TYPECHECK_CMD=a\nHARNESS_TYPECHECK_CMD=b\n' >> "$W/.claude/harness/harness.env"
  call check-harness-env.sh "$W" tool_name=Edit tool_input.file_path=.claude/harness/harness.env
  contains "$OUT" 'HARNESS_TYPECHECK_CMD' || why="워크트리 env 의 중복 선언을 못 봤다: $(printf '%s' "$OUT" | head -c 90)"
  report "$name" "$why"
}

w18() {
  local name='w18 워크트리 설계 산출물의 머리 표명 검사는 워크트리 파일을 연다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf '머리 표명 없음\n' > "$W/_workspace/01_design.md"
  edit "$W" "$W/_workspace/01_design.md"
  stop "$W"
  if   [ "$RC" -ne 2 ];                then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" '머리 표명';   then why="머리 표명 게이트가 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

w19() {
  local name='w19 프로젝트가 워크트리이고 cwd 가 메인 체크아웃이면 루트를 바꾸지 않는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  # 링크된 워크트리로만 옮긴다(지시 계약). 메인 체크아웃은 git-dir 이 common-dir 과 같다.
  mkdir -p "$W/.claude/hooks" && cp "$M/.claude/hooks/"*.sh "$W/.claude/hooks/" \
    || { report "$name" '픽스처 실패 — 워크트리 설치본'; return 0; }
  local m_save="$M"
  M="$W"   # run_hook·sdir 이 워크트리를 프로젝트로 쓰게 한다
  edit "$m_save" "$W/src/a.ts"
  grep -qxF 'src/a.ts' "$(audit_flag)" 2>/dev/null || why="루트가 워크트리가 아니다: $(first_flag)"
  M="$m_save"
  report "$name" "$why"
}

# --- 루트 고정 (kty 결정 2026-10-02) --------------------------------------
# 첫 호출이 W 면 이후 cwd 가 M 이어도 그 세션의 루트는 W 다.

w20() {
  local name='w20 고정 — W 에서 만든 설계 산출물의 머리 표명을 cwd=M 의 Stop 도 W 에서 검사한다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf '머리 표명 없음\n' > "$W/_workspace/01_design.md"
  edit "$W" "$W/_workspace/01_design.md"
  stop "$M"
  if   [ "$RC" -ne 2 ];              then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" '머리 표명'; then why="머리 표명 게이트가 아니다(소실로 건너뜀): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

w21() {
  local name='w21 고정 — W 의 *codex*.md 가 푼다 (Stop 의 cwd 는 M)' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W" "$W/src/a.ts"
  sleep 1
  printf 'review\n' > "$W/_workspace/01_codex_review.md"
  stop "$M"
  if   contains "$ERR" "$TOK_DUAL";          then why='W 의 리뷰 산출물로 듀얼리뷰가 안 풀렸다'
  elif [ -e "$(sdir)/.needs-dualreview" ];   then why='듀얼리뷰 플래그가 남았다'
  fi
  report "$name" "$why"
}

w22() {
  local name='w22 고정 — M 의 *codex*.md 는 W 세션의 의무를 풀지 못한다 (Stop 의 cwd 는 M)' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W" "$W/src/a.ts"
  sleep 1
  printf 'review\n' > "$M/_workspace/01_codex_review.md"
  stop "$M"
  if   [ "$RC" -ne 2 ];               then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_DUAL"; then why="다른 체크아웃의 산출물로 풀렸다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

w23() {
  local name='w23 고정 — 타입체크는 W 에서 W 의 env 로 돈다 (Stop 의 cwd 는 M)' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  write_env "$M" 'echo MAINENV $(pwd -P); exit 1'
  write_env "$W" 'echo WTENV $(pwd -P); exit 1'
  edit "$W" "$W/src/a.ts"
  stop "$M"
  if   [ "$RC" -ne 2 ];              then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "WTENV $W"; then why="W 에서 돌지 않았다: $(printf '%s' "$ERR" | grep ENV | head -1 | head -c 120)"
  fi
  report "$name" "$why"
}

w24() {
  local name='w24 고정 — push 미완은 W 의 브랜치로 잰다 (Stop 의 cwd 는 M)' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf 'y\n' > "$W/src/a.ts"
  g "$W" commit -q -am wip || { report "$name" '전제 실패 — 커밋'; return 0; }
  window "$W"   # 첫 호출 — 루트를 W 로 고정한다(편집 의무는 세우지 않는다)
  stop "$M"
  if   ! contains "$ERR" "$TOK_PUSH"; then why="push 게이트가 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! contains "$ERR" 'origin wt'; then why='안내의 브랜치가 wt 가 아니다'
  fi
  report "$name" "$why"
}

w25() {
  local name='w25 고정 — W 세션이 cwd=M 에서 고친 메인 파일은 절대경로, W 파일은 W 상대경로' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W" "$W/src/a.ts"
  edit "$M" "$M/src/b.ts"
  edit "$M" "$W/src/c.ts"
  if   ! grep -qxF "$M/src/b.ts" "$(audit_flag)" 2>/dev/null; then why="메인 파일이 절대경로로 안 잡혔다: $(all_flags)"
  elif ! grep -qxF 'src/c.ts' "$(audit_flag)" 2>/dev/null;     then why="cwd=M 의 W 편집이 W 상대경로가 아니다: $(all_flags)"
  elif [ "$(cat "$(root_file)" 2>/dev/null)" != "$W" ];       then why=".root 가 바뀌었다: $(cat "$(root_file)")"
  fi
  report "$name" "$why"
}

w26() {
  local name='w26 W 세션 — 메인 파일 편집 → 그 세션의 게이트, Stop 이 막힌다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "$W" "$M/src/a.ts"
  if ! grep -qxF "$M/src/a.ts" "$(audit_flag)" 2>/dev/null; then
    why="플래그에 $M/src/a.ts 없음 (rc=$RC $(first_flag))"
  else
    stop "$W"
    [ "$RC" -eq 2 ] || why="Stop rc=$RC (기대 2)"
  fi
  report "$name" "$why"
}

w27() {
  local name='w27 W 세션의 Bash 가 메인 파일을 절대경로로 쓰면 스윕이 그 세션 의무로 잡는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  sleep 1
  printf 'y\n' > "$M/src/c.ts"
  bashpost "$W" "printf y > $M/src/c.ts"
  grep -qxF "$M/src/c.ts" "$(audit_flag)" 2>/dev/null \
    || why="플래그에 $M/src/c.ts 없음 (rc=$RC $(first_flag))"
  report "$name" "$why"
}

w28() {
  local name='w28 Bash 가 W 에서 시작해 cd 로 떠나도(Post cwd=M) 루트 W 의 변경을 스윕한다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  sleep 1
  printf 'y\n' > "$W/src/b.ts"
  bashpost "$M" 'printf y > src/b.ts; cd ../../..'
  grep -qxF 'src/b.ts' "$(audit_flag)" 2>/dev/null \
    || why="플래그에 src/b.ts 없음 (rc=$RC $(first_flag))"
  report "$name" "$why"
}

w29() {
  local name='w29 W 세션의 Bash 가 상대 cd 로 메인 파일을 쓰면(Post cwd=M) 그 파일도 잡는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  sleep 1
  printf 'y\n' > "$M/src/d.ts"
  bashpost "$M" 'cd ../../.. && printf y > src/d.ts'
  grep -qxF "$M/src/d.ts" "$(audit_flag)" 2>/dev/null \
    || why="플래그에 $M/src/d.ts 없음 (rc=$RC $(all_flags))"
  report "$name" "$why"
}

w30() {
  local name='w30 첫 호출에 cwd 가 없으면 고정하지 않는다 — 다음 cwd 있는 호출이 정한다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  edit "" "$M/src/a.ts"
  if [ -e "$(root_file)" ]; then
    why="cwd 없는 호출이 .root 를 썼다: $(cat "$(root_file)")"
  else
    edit "$W" "$W/src/b.ts"
    grep -qxF 'src/b.ts' "$(audit_flag)" 2>/dev/null || why="다음 호출이 W 로 고정하지 않았다: $(all_flags)"
  fi
  report "$name" "$why"
}

w31() {
  local name='w31 .root 가 사라진 폴더를 가리키면 원래 루트로 판정한다 — 편집 기록 · push 게이트' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  mkdir -p "$(sdir)" && printf '%s\n' "$TMPROOT/gone" > "$(root_file)"
  printf 'y\n' > "$M/src/a.ts"
  g "$M" commit -q -am wip || { report "$name" '전제 실패 — 커밋'; return 0; }
  stop "$W"
  if   ! contains "$ERR" "$TOK_PUSH";   then why="원래 루트(main)의 push 게이트가 사라졌다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! contains "$ERR" 'origin main'; then why='안내의 브랜치가 main 이 아니다'
  else
    edit "$W" "$W/src/a.ts"
    grep -qxF "$W/src/a.ts" "$(audit_flag)" 2>/dev/null || why="원래 루트 기준 절대경로가 아니다 (rc=$RC $(first_flag))"
  fi
  report "$name" "$why"
}

# --- 상속 환경으로 기록을 건너뛸 수 없다 ([cc·cx] r2) ----------------------

w32() {
  local name='w32 상속된 HARNESS_SWEEP_* 가 있어도 훅은 실제 입력을 읽어 기록한다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  HOOK_ENV="HARNESS_SWEEP_ROOT=$M HARNESS_SWEEP_FILE=$M/README HARNESS_SWEEP_STATE=$TMPROOT/fake HARNESS_SWEEP_SID=x" \
    edit "$W" "$W/src/a.ts"
  if   ! grep -qxF 'src/a.ts' "$(audit_flag)" 2>/dev/null; then why="실제 입력이 기록되지 않았다 (rc=$RC $(first_flag))"
  elif [ -e "$TMPROOT/fake" ];                             then why='상속 환경 변수가 가리킨 폴더에 기록했다'
  fi
  report "$name" "$why"
}

# --- 커밋 가드의 교차 대상 -----------------------------------------------

w33() {
  local name='w33 커밋 가드 — W 세션의 git -C <메인> commit · cd <메인> && git commit 을 막는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  bashpre guard-master-commit.sh "$W" "git -C $M commit -m x"
  if [ "$RC" -ne 2 ]; then why="git -C <메인> commit rc=$RC (기대 2)"; report "$name" "$why"; return 0; fi
  bashpre guard-master-commit.sh "$W" "cd $M && git commit -m x"
  if [ "$RC" -ne 2 ]; then why="cd <메인> && git commit rc=$RC (기대 2)"; report "$name" "$why"; return 0; fi
  bashpre guard-master-commit.sh "$W" "cd ../../.. && git commit -m x"
  if [ "$RC" -ne 2 ]; then why="cd <상대경로=메인> && git commit rc=$RC (기대 2)"; report "$name" "$why"; return 0; fi
  bashpre guard-master-commit.sh "$W" "git -C $W commit -m x"
  [ "$RC" -eq 0 ] || why="git -C <워크트리> commit 이 막혔다 rc=$RC"
  report "$name" "$why"
}

# --- 스타일 검사기 위치 ---------------------------------------------------

# style_fixture [부모] — 메인에만 번들 검사기, 워크트리에만 gofmt 위반. 메인에도 위반을 하나 둬서
# 검사 대상이 워크트리인지(메인이 아닌지) 가린다.
style_fixture() {
  new_fixture "${1:-}" || return 1
  mkdir -p "$M/.claude/skills" "$W/svc" "$M/mainsvc" || return 1
  cp -R "$REPO_ROOT/template/.claude/skills/google-styleguide" "$M/.claude/skills/" || return 1
  printf 'module example.com/svc\n\ngo 1.22\n' > "$W/svc/go.mod"
  printf 'package svc\n\nfunc  Bad( ) int {\nreturn 1\n}\n' > "$W/svc/wt_bad.go"
  printf 'module example.com/m\n\ngo 1.22\n' > "$M/mainsvc/go.mod"
  printf 'package m\n\nfunc  Bad( ) int {\nreturn 1\n}\n' > "$M/mainsvc/main_bad.go"
}

readonly ENV_STYLE_CMD='HARNESS_TYPECHECK_CMD=""\nHARNESS_STYLECHECK_CMD="bash .claude/skills/google-styleguide/scripts/check-style.sh"\nHARNESS_KNOWLEDGE_GATE=""\n'
readonly ENV_STYLE_ABSENT='HARNESS_TYPECHECK_CMD=""\nHARNESS_KNOWLEDGE_GATE=""\n'

# style_case <이름> <harness.env 본문(printf %b)> [부모] — 워크트리 위반으로 막히고 메인은 안 본다.
style_case() {
  local name="$1" why=''
  command -v gofmt >/dev/null 2>&1 || { report "$name (건너뜀 — gofmt 없음)" ''; return 0; }
  style_fixture "${3:-}" || { report "$name" '픽스처 실패'; return 0; }
  printf '%b' "$2" > "$M/.claude/harness/harness.env"
  edit "$W" "$W/svc/wt_bad.go"
  stop "$W"
  if   [ "$RC" -ne 2 ];                      then why="rc=$RC (기대 2): $(printf '%s' "$ERR" | grep -m1 '스타일\|차단' | head -c 120)"
  elif ! contains "$ERR" '스타일 검사 실패'; then why="스타일 게이트가 아니다: $(printf '%s' "$ERR" | grep -m1 '스타일\|차단' | head -c 120)"
  elif contains "$ERR" 'main_bad.go';        then why='워크트리가 아니라 메인을 검사했다'
  fi
  report "$name" "$why"
}

w34() { style_case 'w34 메인 env 폴백 + 기본 스타일 명령 → 워크트리 위반으로 막는다' "$ENV_STYLE_CMD"; }
w35() { style_case 'w35 키 부재(번들 검사기 축퇴) — 메인에만 있는 검사기로 워크트리를 검사한다' "$ENV_STYLE_ABSENT"; }
w36() {
  style_case 'w36 경로에 공백 — 기본 스타일 명령의 메인 검사기 폴백이 작동한다' "$ENV_STYLE_CMD" "$TMPROOT/sp ace"
  style_case 'w36b 경로에 공백 — 키 부재의 메인 검사기 폴백이 작동한다' "$ENV_STYLE_ABSENT" "$TMPROOT/sp ace2"
}

# --- git 판정 견고화 -----------------------------------------------------

w37() {
  local name='w37 상속된 GIT_COMMON_DIR 이 다른 저장소의 워크트리를 같은 저장소로 위장하지 못한다' why='' o
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  o="$TMPROOT/other.$RANDOM"
  mkdir -p "$o/r" && g "$o/r" init -q -b main && g "$o/r" commit -q --allow-empty -m init \
    && g "$o/r" worktree add -q -b ow "$o/w" 2>/dev/null || { report "$name" '픽스처 실패 — 다른 저장소'; return 0; }
  mkdir -p "$o/w/src" && printf 'x\n' > "$o/w/src/x.ts"
  HOOK_ENV="GIT_COMMON_DIR=$M/.git" edit "$o/w" "$o/w/src/x.ts"
  [ -e "$(audit_flag)" ] && why="다른 저장소 편집에 플래그가 섰다: $(first_flag)"
  report "$name" "$why"
}

w38() {
  local name='w38 --git-dir 조회가 실패하면 링크 판정 실패 — 원래 루트(메인)로 물러선다' why='' shim real
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  shim="$TMPROOT/shim.$RANDOM"; real="$(command -v git)"
  mkdir -p "$shim" || { report "$name" '픽스처 실패 — shim'; return 0; }
  # --git-dir 조회만 빈 출력·실패로 만든다. 나머지는 진짜 git 이다.
  printf '#!/bin/sh\nfor a in "$@"; do [ "$a" = --git-dir ] && exit 1; done\nexec "%s" "$@"\n' "$real" > "$shim/git"
  chmod +x "$shim/git"
  HOOK_ENV="PATH=$shim:$PATH" edit "$W" "$W/src/a.ts"
  if   grep -qxF 'src/a.ts' "$(audit_flag)" 2>/dev/null; then why='판정 실패인데 워크트리로 묶였다'
  elif [ "$(cat "$(root_file)" 2>/dev/null)" != "$M" ];  then why=".root 가 M 이 아니다: $(cat "$(root_file)" 2>/dev/null)"
  fi
  report "$name" "$why"
}

# --- 스윕 성능 -----------------------------------------------------------

w39() {
  local name='w39 스윕 150파일 — 전부 기록, 서브프로세스가 파일 수에 비례해 늘지 않는다(git ≤ 2/파일, python3 ≤ 20)' why='' i t0 t1 n shim ng np
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  # 시간은 기계 부하에 흔들린다([cc] r1 — 부하 시 16s). 결정적 지표로 잰다: PATH 앞에 둔 셔임이
  # git·python3 호출을 센다. 옛 재호출 설계는 파일마다 python3 를 여러 번 불렀다.
  shim="$TMPROOT/count.$RANDOM"
  mkdir -p "$shim" || { report "$name" '픽스처 실패 — 셔임'; return 0; }
  for t in git python3; do
    printf '#!/bin/sh\necho x >> "%s/%s.log"\nexec "%s" "$@"\n' "$shim" "$t" "$(command -v "$t")" > "$shim/$t"
    chmod +x "$shim/$t"
  done
  window "$W"
  sleep 1
  i=0
  while [ "$i" -lt 150 ]; do printf 'y\n' > "$W/src/f$i.ts"; i=$((i + 1)); done
  t0="$(date +%s)"
  HOOK_ENV="PATH=$shim:$PATH" bashpost "$W" 'gen'
  t1="$(date +%s)"
  n="$(grep -c '^src/f' "$(audit_flag)" 2>/dev/null)"
  ng="$(wc -l < "$shim/git.log" 2>/dev/null | tr -d ' ')"
  np="$(wc -l < "$shim/python3.log" 2>/dev/null | tr -d ' ')"
  if   [ "${n:-0}" -ne 150 ];     then why="기록 ${n:-0}/150"
  elif [ "${ng:-0}" -gt 300 ];    then why="git 호출 ${ng}회 (상한 300)"
  elif [ "${np:-0}" -gt 20 ];     then why="python3 호출 ${np}회 (상한 20)"
  fi
  report "$name ($((t1 - t0))s · git ${ng:-?} · python3 ${np:-?})" "$why"
}

# --- 드리프트 가드 (harness.env 제외 — kty 확정 2026-10-02) ----------------

w40() {
  local name='w40 드리프트 가드 — harness.env 는 대조 밖, 다른 하네스 파일 차이·사본 부재는 막는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf 'profile\n' > "$M/.claude/harness/project-profile.md"
  bashpre guard-harness-drift.sh "$W" 'ls'
  if [ "$RC" -ne 2 ] || ! contains "$ERR" '하네스 사본이 없'; then
    why="사본 부재 rc=$RC 메시지: $(printf '%s' "$ERR" | head -1 | head -c 90)"; report "$name" "$why"; return 0
  fi
  mkdir -p "$W/.claude" && cp -R "$M/.claude/harness" "$W/.claude/"
  write_env "$W" 'true'
  bashpre guard-harness-drift.sh "$W" 'ls'
  if [ "$RC" -ne 0 ]; then
    why="env 만 다른데 막혔다 rc=$RC: $(printf '%s' "$ERR" | head -1 | head -c 90)"; report "$name" "$why"; return 0
  fi
  printf 'stale\n' > "$W/.claude/harness/project-profile.md"
  bashpre guard-harness-drift.sh "$W" 'ls'
  if [ "$RC" -ne 2 ] || ! contains "$ERR" '하네스 사본이 메인과 다릅'; then
    why="프로필 차이 rc=$RC 메시지: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

# --- 리뷰 1라운드 반영 ([cc·cx] r1) -----------------------------------------

w41() {
  local name='w41 커밋 가드 — W 에 고정된 세션이 cwd=M(main) 에서 맨 git commit 을 하면 막는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  bashpre guard-master-commit.sh "$M" 'git commit -m x'
  [ "$RC" -eq 2 ] || why="rc=$RC (기대 2 — 실제 실행 위치 M 은 main)"
  report "$name" "$why"
}

w42() {
  local name='w42 스윕 — W 세션의 rm <메인 파일>(삭제된 경로) 도 그 세션 의무로 잡는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  sleep 1
  rm -f "$M/src/a.ts"
  bashpost "$W" "rm $M/src/a.ts"
  grep -qxF "$M/src/a.ts" "$(audit_flag)" 2>/dev/null || why="플래그에 $M/src/a.ts 없음 (rc=$RC $(all_flags))"
  report "$name" "$why"
}

w43() {
  local name='w43 스윕 — W 세션의 git -C <메인> 명령(디렉터리 토큰) 이 바꾼 파일을 잡는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  sleep 1
  printf 'y\n' > "$M/src/e.ts"
  bashpost "$W" "git -C $M apply x.diff"
  grep -qxF "$M/src/e.ts" "$(audit_flag)" 2>/dev/null || why="플래그에 $M/src/e.ts 없음 (rc=$RC $(all_flags))"
  report "$name" "$why"
}

w44() {
  local name='w44 빈 .root 가 있으면 cwd 와 무관하게 원래 루트로 일관 판정한다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  mkdir -p "$(sdir)" && : > "$(root_file)"
  edit "$W" "$W/src/a.ts"
  edit "$M" "$W/src/b.ts"
  if   ! grep -qxF "$W/src/a.ts" "$(audit_flag)" 2>/dev/null; then why="cwd=W 호출이 원래 루트가 아니다: $(all_flags)"
  elif ! grep -qxF "$W/src/b.ts" "$(audit_flag)" 2>/dev/null; then why="cwd=M 호출이 원래 루트가 아니다: $(all_flags)"
  fi
  report "$name" "$why"
}

w45() {
  local name='w45 .root 기록 실패(상태 폴더 쓰기 불가) → 방금 판정한 W 가 아니라 원래 루트(M)' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  mkdir -p "$(sdir)" && chmod 555 "$(sdir)"
  bashpre guard-master-commit.sh "$W" 'git commit -m x'
  chmod 755 "$(sdir)"
  if   [ -e "$(root_file)" ]; then why='쓰기 불가 폴더에 .root 가 생겼다(전제 붕괴)'
  elif [ "$RC" -ne 2 ];       then why="rc=$RC (기대 2 — 원래 루트 M 은 main)"
  fi
  report "$name" "$why"
}

w46() {
  local name='w46 상대 편집 경로는 입력 cwd 로 절대화한다 — W 세션이 cwd=M 에서 src/a.ts 편집' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  edit "$M" 'src/a.ts'
  grep -qxF "$M/src/a.ts" "$(audit_flag)" 2>/dev/null || why="M 파일 절대경로가 아니다: $(all_flags)"
  report "$name" "$why"
}

w47() {
  local name='w47 harness.env 편집 검증 — 상대경로는 입력 cwd(M) 기준' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  write_env "$W" ''
  printf 'HARNESS_TYPECHECK_CMD=a\nHARNESS_TYPECHECK_CMD=b\n' >> "$M/.claude/harness/harness.env"
  window "$W"
  call check-harness-env.sh "$M" tool_name=Edit tool_input.file_path=.claude/harness/harness.env
  contains "$OUT" 'HARNESS_TYPECHECK_CMD' || why="cwd(M) 의 env 를 보지 않았다: $(printf '%s' "$OUT" | head -c 90)"
  report "$name" "$why"
}

w48() {
  local name='w48 드리프트 가드 — .claude/worktrees 밖의 같은 저장소 워크트리도 대조한다' why='' x
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  x="$(dirname "$M")/wt-out"
  g "$M" worktree add -q -b wo "$x" 2>/dev/null || { report "$name" '픽스처 실패 — 워크트리'; return 0; }
  printf 'profile\n' > "$M/.claude/harness/project-profile.md"
  bashpre guard-harness-drift.sh "$x" 'ls'
  if [ "$RC" -ne 2 ] || ! contains "$ERR" '하네스 사본이 없'; then
    why="사본 부재 rc=$RC: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

w49() {
  local name='w49 상속된 GIT_DIR·GIT_WORK_TREE 가 고정 루트의 push 판정을 바꾸지 못한다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf 'y\n' > "$W/src/a.ts"
  g "$W" commit -q -am wip || { report "$name" '전제 실패 — 커밋'; return 0; }
  window "$W"
  HOOK_ENV="GIT_DIR=$M/.git GIT_WORK_TREE=$M" stop "$W"
  if   ! contains "$ERR" "$TOK_PUSH"; then why="push 게이트가 사라졌다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! contains "$ERR" 'origin wt'; then why='안내의 브랜치가 wt 가 아니다'
  fi
  report "$name" "$why"
}

w50() {
  local name='w50 스타일 폴백 — 따옴표 친 상대경로 명령은 손대지 않는다' why=''
  command -v gofmt >/dev/null 2>&1 || { report "$name (건너뜀 — gofmt 없음)" ''; return 0; }
  style_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf '%s\n' 'HARNESS_TYPECHECK_CMD=""' \
    "HARNESS_STYLECHECK_CMD='bash \".claude/skills/google-styleguide/scripts/check-style.sh\"'" \
    'HARNESS_KNOWLEDGE_GATE=""' > "$M/.claude/harness/harness.env"
  # 듀얼리뷰는 산출물로 풀고 변경 설명 플래그는 지운다 — 스타일 생략 사유는 감사 게이트에 실린다.
  edit "$W" "$W/svc/wt_bad.go"
  sleep 1
  printf 'review\n' > "$W/_workspace/01_codex_review.md"
  rm -f "$(sdir)/.needs-explain"
  stop "$W"
  contains "$ERR" 'rc=127): bash ".claude/skills/google-styleguide/scripts/check-style.sh"' \
    || why="명령이 바뀌었다: $(printf '%s' "$ERR" | grep -m1 '스타일\|차단' | head -c 160)"
  report "$name" "$why"
}

w51() {
  local name='w51 스타일 폴백 — 절대경로 명령은 그대로 실행돼 워크트리 위반으로 막는다' why=''
  command -v gofmt >/dev/null 2>&1 || { report "$name (건너뜀 — gofmt 없음)" ''; return 0; }
  style_fixture || { report "$name" '픽스처 실패'; return 0; }
  printf 'HARNESS_TYPECHECK_CMD=""\nHARNESS_STYLECHECK_CMD="bash %s/.claude/skills/google-styleguide/scripts/check-style.sh"\nHARNESS_KNOWLEDGE_GATE=""\n' "$M" \
    > "$M/.claude/harness/harness.env"
  edit "$W" "$W/svc/wt_bad.go"
  stop "$W"
  if   ! contains "$ERR" '스타일 검사 실패'; then why="스타일 게이트가 아니다: $(printf '%s' "$ERR" | grep -m1 '스타일\|차단' | head -c 120)"
  elif contains "$ERR" 'main_bad.go';        then why='워크트리가 아니라 메인을 검사했다'
  fi
  report "$name" "$why"
}

# par_edit <cwd> <파일> — 병렬 실행용. run_hook 의 임시 파일을 쓰지 않는다.
par_edit() {
  payload tool_name=Edit "tool_input.file_path=$2" "cwd=$1" \
    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$M" \
        bash "$M/.claude/hooks/mark-needs-audit.sh" >/dev/null 2>&1
}

w52() {
  local name='w52 서로 다른 cwd 의 첫 호출이 병렬로 경쟁해도 .root 는 하나, 두 훅이 같은 루트로 기록' why='' k r p q
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  k=0
  while [ "$k" -lt 8 ] && [ -z "$why" ]; do
    CUR_SID="55555555-eeee-4eee-8eee-00000000000$k"
    par_edit "$W" "$W/src/p.ts" & par_edit "$M" "$W/src/q.ts" & wait
    r="$(cat "$(root_file)" 2>/dev/null)"
    if grep -qxF 'src/p.ts' "$(audit_flag)" 2>/dev/null; then p=W; else p=M; fi
    if grep -qxF 'src/q.ts' "$(audit_flag)" 2>/dev/null; then q=W; else q=M; fi
    if   [ "$(wc -l < "$(root_file)" | tr -d ' ')" != 1 ]; then why="회차 $k: .root 가 한 줄이 아니다"
    elif [ "$p" != "$q" ];                                 then why="회차 $k: 두 훅의 루트가 갈렸다 (p=$p q=$q)"
    elif { [ "$p" = W ] && [ "$r" != "$W" ]; } || { [ "$p" = M ] && [ "$r" != "$M" ]; }; then why="회차 $k: 기록($p)과 .root($r) 불일치"
    fi
    k=$((k + 1))
  done
  report "$name" "$why"
}

w53() {
  local name='w53 스윕 — W 세션의 rm -rf <메인 폴더> 로 지워진 추적 파일도 그 세션 의무로 잡는다' why=''
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  window "$W"
  sleep 1
  rm -rf "$M/src"
  bashpost "$W" "rm -rf $M/src"
  grep -qxF "$M/src/a.ts" "$(audit_flag)" 2>/dev/null || why="플래그에 $M/src/a.ts 없음 (rc=$RC $(all_flags))"
  report "$name" "$why"
}

# other_repo — 고정틀과 **다른 저장소**(브랜치 main, 커밋 1개)를 만들어 경로를 stdout 에.
# main 직접 커밋이 그쪽 규약인 저장소를 흉내 낸다.
other_repo() {
  local o
  o="$(mktemp -d "$TMPROOT/other.XXXXXX")" || return 1
  g "$o" init -q -b main && printf 'n\n' > "$o/note.md" && g "$o" add -A \
    && g "$o" commit -q -m init || return 1
  printf '%s' "$o"
}

w54() {
  local name='w54 커밋 가드는 이 저장소만 본다 — 다른 저장소(main)를 -C · cd · cwd 로 겨눈 커밋은 통과' why='' o
  new_fixture || { report "$name" '픽스처 실패'; return 0; }
  o="$(other_repo)" || { report "$name" '다른 저장소 픽스처 실패'; return 0; }
  window "$W"
  bashpre guard-master-commit.sh "$W" "git -C $o commit -m x"
  if [ "$RC" -ne 0 ]; then why="git -C <다른 저장소> commit rc=$RC (기대 0)"; report "$name" "$why"; return 0; fi
  bashpre guard-master-commit.sh "$W" "cd $o && git commit -m x"
  if [ "$RC" -ne 0 ]; then why="cd <다른 저장소> && git commit rc=$RC (기대 0)"; report "$name" "$why"; return 0; fi
  bashpre guard-master-commit.sh "$o" 'git commit -m x'
  if [ "$RC" -ne 0 ]; then why="cwd=<다른 저장소> 맨 git commit rc=$RC (기대 0)"; report "$name" "$why"; return 0; fi
  bashpre guard-master-commit.sh "$W" "git -C $o commit -m x && git -C $M commit -m y"
  if [ "$RC" -ne 2 ]; then why="다른 저장소 + 메인을 함께 겨눈 명령 rc=$RC (기대 2)"; report "$name" "$why"; return 0; fi
  bashpre guard-master-commit.sh "$o" "git -C $M commit -m x"
  [ "$RC" -eq 2 ] || why="cwd=<다른 저장소> 에서 git -C <메인> commit rc=$RC (기대 2)"
  report "$name" "$why"
}

echo "worktree-project-dir:"
w01; w02; w03; w04; w05; w06; w07; w08; w09; w10; w11; w12; w13; w14; w15; w16; w17; w18; w19
w20; w21; w22; w23; w24; w25; w26; w27; w28; w29; w30; w31; w32; w33; w34; w35; w36; w37; w38
w39; w40; w41; w42; w43; w44; w45; w46; w47; w48; w49; w50; w51; w52; w53; w54
echo "— $pass/$ran 통과"
[ "$fail" -eq 0 ]
