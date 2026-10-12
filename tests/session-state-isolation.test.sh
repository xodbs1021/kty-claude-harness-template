#!/usr/bin/env bash
# session-state-isolation.test.sh — 게이트 상태의 **세션 격리** 회귀 방어.
#
#   "한 프로젝트를 여러 세션이 동시에 쓰면, 각 세션의 게이트 상태(.needs-* 플래그 ·
#    Bash 창 · Stop 차단 카운터)는 그 세션의 것만 보인다."
#
# 왜 필요한가 (2026-10-01 실사고): 데스크톱 앱은 워크트리 세션에도 CLAUDE_PROJECT_DIR 로
# **메인 체크아웃**을 넘긴다. 상태 폴더가 $CLAUDE_PROJECT_DIR/.claude 하나뿐이라 모든 세션이
# 같은 플래그를 썼고, 한 세션의 Stop 이 다른 세션의 산출물 9건으로 세 번 막혔다. 같은 날 첫
# 읽기 전용 Bash 가 다른 세션의 창을 소비해 체크아웃 파일 197개를 듀얼리뷰 대상으로 적었다.
#
# 격리 키 = 훅 입력의 session_id. 서브에이전트의 도구 호출도 부모와 같은 session_id 를 싣는다
# (서브에이전트 기록의 sessionId 가 부모 세션과 같음을 실측 — 2026-10-01). 그래서 세션별로
# 나눠도 서브에이전트가 만든 변경을 부모의 Stop 이 본다.
# session_id 가 없는 입력은 옛 공유 경로를 쓴다 — 기존 시험 12종과 옛 클라이언트의 하위 호환.
#
# **판정 규칙의 사본을 두지 않는다.** 훅 자신을 돌려 파일 위치·rc·메시지로 잰다.
# 단 하나, 세션 폴더 이름의 규칙(SHA-256 앞 32자)만은 시험이 다시 계산한다 — 위치를 단언하려면
# 경로를 알아야 하기 때문이다. 규칙이 바뀌면 이 시험도 함께 바뀌어야 한다(의도된 결합).
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. mapfile·연관배열·${var,,} 금지.

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOKS="$REPO_ROOT/template/.claude/hooks"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (payload 픽스처 의존)" >&2; exit 1; }
for f in verify-before-stop.sh mark-needs-audit.sh mark-bash-window.sh guard-publish-review.sh _common.sh; do
  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
done

TMPROOT="$(mktemp -d)" || exit 1
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'rm -rf "$TMPROOT"' EXIT

ran=0; pass=0; fail=0
RC=999; ERR=''; OUT=''

TOK_AUDIT='completion-auditor 미실행'
TOK_BLOCK='[완료 차단]'   # 어느 게이트든 — 편집은 듀얼리뷰 게이트를 감사보다 먼저 세운다

SID_A='11111111-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
SID_B='22222222-bbbb-4bbb-8bbb-bbbbbbbbbbbb'

report() {
  ran=$((ran + 1))
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}

contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

# sdir <프로젝트> <session_id> — 그 세션의 상태 폴더(규칙: .claude/.sessions/<SHA-256 앞 32자>).
sdir() { printf '%s/.claude/.sessions/%s' "$1" "$(printf '%s' "$2" | python3 -c 'import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest()[:32])')"; }

# new_project — 훅 설치본 + 타입체크·지식게이트를 리터럴로 비운 harness.env.
# git 저장소가 아니다 — push 게이트가 끼지 않게 하려는 것이다(이 파일은 격리만 잰다).
new_project() {   # $1 = 지식게이트 값(생략하면 꺼짐)
  local p
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
  mkdir -p "$p/.claude/hooks" "$p/.claude/harness" "$p/src" "$p/_workspace" || return 1
  cp "$HOOKS/_common.sh" "$HOOKS/verify-before-stop.sh" "$HOOKS/mark-needs-audit.sh" \
     "$HOOKS/mark-bash-window.sh" "$HOOKS/guard-publish-review.sh" "$p/.claude/hooks/" || return 1
  printf 'HARNESS_TYPECHECK_CMD=""\nHARNESS_STYLECHECK_CMD=""\nHARNESS_KNOWLEDGE_GATE="%s"\n' "${1-}" \
    > "$p/.claude/harness/harness.env" || return 1
  printf 'x\n' > "$p/src/app.ts"
  printf '%s\n' "$p"
}

# payload <session_id|""> <키=값>... — JSON 한 줄. 점 경로 키는 중첩으로 만든다.
payload() {
  python3 - "$@" <<'PY'
import json, sys
sid = sys.argv[1]
d = {}
if sid:
    d["session_id"] = sid
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

# run_hook <프로젝트> <훅파일> <payload JSON>
run_hook() {
  local p="$1" hook="$2" pay="$3"
  local errf="$TMPROOT/err.$$" outf="$TMPROOT/out.$$"
  RC=999; ERR=''; OUT=''
  ( cd "$TMPROOT" && printf '%s' "$pay" | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
      CLAUDE_PROJECT_DIR="$p" bash "$p/.claude/hooks/$hook" >"$outf" 2>"$errf" )
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"; OUT="$(cat "$outf" 2>/dev/null)"
  rm -f "$errf" "$outf"
}

edit()  { run_hook "$1" mark-needs-audit.sh "$(payload "$2" tool_name=Edit "tool_input.file_path=$3")"; }
stop()  { run_hook "$1" verify-before-stop.sh "$(payload "$2" stop_hook_active=__false__)"; }
window(){ run_hook "$1" mark-bash-window.sh "$(payload "$2" tool_name=Bash tool_input.command=x)"; }
publish(){ run_hook "$1" guard-publish-review.sh "$(payload "$2" tool_name=mcp__x__addCommentToJiraIssue tool_input.body=x)"; }
bashpost(){ run_hook "$1" mark-needs-audit.sh "$(payload "$2" tool_name=Bash "tool_input.command=$3")"; }

# --- 케이스 --------------------------------------------------------------

s01() {
  local name='s01 세션 A 편집 → A 폴더에만 기록 (공유 경로·B 폴더는 비어 있음)' why='' p
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$SID_A" "$p/src/app.ts"
  if   [ ! -s "$(sdir "$p" "$SID_A")/.needs-audit" ]; then why="A 폴더에 .needs-audit 없음 (rc=$RC $(printf '%s' "$OUT$ERR" | head -c 80))"
  elif [ -e "$p/.claude/.needs-audit" ];              then why='공유 경로에 기록됐다 — 격리 안 됨'
  elif [ -e "$(sdir "$p" "$SID_B")" ];                then why='B 폴더가 생겼다'
  fi
  report "$name" "$why"
}

s02() {
  local name='s02 session_id 없는 입력 → 옛 공유 경로 (하위 호환)' why='' p
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "" "$p/src/app.ts"
  if   [ ! -s "$p/.claude/.needs-audit" ]; then why="공유 경로에 .needs-audit 없음 (rc=$RC)"
  elif [ -d "$p/.claude/.sessions" ];      then why='세션 폴더가 생겼다'
  fi
  report "$name" "$why"
}

s03() {
  local name='s03 세션 B 의 Stop 은 A 의 플래그에 막히지 않는다' why='' p
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$SID_A" "$p/src/app.ts"
  [ -s "$(sdir "$p" "$SID_A")/.needs-audit" ] || { report "$name" '전제 실패 — A 플래그가 안 섰다'; return 0; }
  stop "$p" "$SID_B"
  if   [ "$RC" -ne 0 ];               then why="rc=$RC (기대 0): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif contains "$ERR" "$TOK_BLOCK"; then why='A 의 게이트가 B 를 막았다'
  fi
  report "$name" "$why"
}

s04() {
  local name='s04 세션 A 의 Stop 은 자기 플래그로 막힌다 (게이트 생존)' why='' p
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$SID_A" "$p/src/app.ts"
  stop "$p" "$SID_A"
  if   [ "$RC" -ne 2 ];                then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_BLOCK"; then why="게이트 미도달: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

s05() {
  local name='s05 옛 공유 플래그는 세션 A 의 Stop 을 막지 않는다 (kty: 남기고 읽지 않음)' why='' p
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  printf 'src/app.ts\n' > "$p/.claude/.needs-audit"
  stop "$p" "$SID_A"
  if   [ "$RC" -ne 0 ];                  then why="rc=$RC (기대 0): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif [ ! -s "$p/.claude/.needs-audit" ]; then why='옛 공유 플래그를 지웠다 (보존이 결정)'
  fi
  report "$name" "$why"
}

s06() {
  local name='s06 Bash 스윕 — 자기 세션의 창만 쓰고 기록도 자기 폴더' why='' p wb
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  window "$p" "$SID_B"            # B 의 창이 먼저(더 오래) 생긴다
  sleep 1
  window "$p" "$SID_A"
  sleep 1
  printf 'y\n' > "$p/src/new.ts"  # A 의 명령이 쓴 파일
  bashpost "$p" "$SID_A" "printf y > src/new.ts"
  wb="$(sdir "$p" "$SID_B")/.bash-windows"
  if   ! grep -qx 'src/new.ts' "$(sdir "$p" "$SID_A")/.needs-audit" 2>/dev/null; then why="A 폴더에 src/new.ts 없음 (rc=$RC)"
  elif [ -e "$p/.claude/.needs-audit" ];                                        then why='공유 경로에 기록됐다'
  elif [ -z "$(ls "$wb" 2>/dev/null)" ];                                        then why='A 의 스윕이 B 의 창을 소비했다'
  elif [ -e "$(sdir "$p" "$SID_B")/.needs-audit" ];                              then why='B 폴더에 기록됐다'
  fi
  report "$name" "$why"
}

s07() {
  local name='s07 차단 카운터는 세션별 + 지우라는 안내에 실제 경로' why='' p a
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$SID_A" "$p/src/app.ts"
  stop "$p" "$SID_A"
  a="$(sdir "$p" "$SID_A")"
  if   [ ! -s "$a/.stop-block-count" ];        then why='A 폴더에 차단 카운터 없음'
  elif [ -e "$p/.claude/.stop-block-count" ];  then why='공유 카운터가 생겼다'
  elif ! contains "$ERR" "$a/.needs-";         then why="안내에 A 의 실제 경로가 없다: $(printf '%s' "$ERR" | grep 'rm -f' | head -1 | head -c 120)"
  fi
  report "$name" "$why"
}

s08() {
  local name='s08 설계 산출물 편집 → 머리 표명 플래그도 A 폴더 (공유 경로 아님)' why='' p
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  printf '사전 결정 회수: 없음(시험)\n' > "$p/_workspace/00_design.md"
  edit "$p" "$SID_A" "$p/_workspace/00_design.md"
  if   [ ! -s "$(sdir "$p" "$SID_A")/.needs-retrieval" ]; then why="A 폴더에 .needs-retrieval 없음 (rc=$RC)"
  elif [ -e "$p/.claude/.needs-retrieval" ];             then why='공유 경로에 기록됐다'
  fi
  report "$name" "$why"
}

s09() {
  local name='s09 지식 게이트를 켠 환경 — B 의 Stop 은 A 의 지식 플래그에 막히지 않는다' why='' p
  p="$(new_project on)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$SID_A" "$p/src/app.ts"
  [ -s "$(sdir "$p" "$SID_A")/.needs-knowledge" ] || { report "$name" '전제 실패 — A 지식 플래그가 안 섰다'; return 0; }
  stop "$p" "$SID_B"
  if   [ "$RC" -ne 0 ];               then why="rc=$RC (기대 0): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif contains "$ERR" "$TOK_BLOCK"; then why='A 의 게이트가 B 를 막았다'
  fi
  report "$name" "$why"
}

s10() {
  local name='s10 A·B 가 번갈아 막혀도 A 의 차단 카운터는 B 때문에 리셋되지 않는다' why='' p a c
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$SID_A" "$p/src/app.ts"
  edit "$p" "$SID_B" "$p/src/app.ts"
  stop "$p" "$SID_A"; stop "$p" "$SID_B"; stop "$p" "$SID_A"
  a="$(sdir "$p" "$SID_A")"
  c="$(tr -dc '0-9' < "$a/.stop-block-count" 2>/dev/null)"
  if   [ "${c:-0}" -ne 2 ];                 then why="A 카운터=${c:-없음} (기대 2 — B 의 지문이 A 를 리셋했다)"
  elif [ ! -s "$a/.stop-block-fp" ];        then why='A 폴더에 차단 지문 없음'
  elif [ -e "$p/.claude/.stop-block-fp" ];  then why='공유 지문 파일이 생겼다'
  fi
  report "$name" "$why"
}

s11() {
  local name='s11 발행 가드 — A 의 듀얼 리뷰 플래그는 A 만 막는다' why='' p ea
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$SID_A" "$p/src/app.ts"
  [ -s "$(sdir "$p" "$SID_A")/.needs-dualreview" ] || { report "$name" '전제 실패 — A 듀얼 플래그가 안 섰다'; return 0; }
  publish "$p" "$SID_A"; ea="$ERR"
  if   [ "$RC" -ne 2 ];                then why="A rc=$RC (기대 2)"
  elif ! contains "$ea" '듀얼 리뷰 전'; then why="A 의 사유가 리뷰 앞지르기가 아니다: $(printf '%s' "$ea" | head -1 | head -c 90)"
  else
    publish "$p" "$SID_B"
    # B 는 자기 리뷰 산출물이 없으니 막혀야 한다 — 다만 사유는 ②(최근 산출물 부재)여야 한다.
    # 문구 부재만 보면 "세션 입력이면 ②를 건너뛰는" 변이가 B 를 통과시켜도 초록이 난다([cx] r1).
    if   contains "$ERR" '듀얼 리뷰 전'; then why='A 의 플래그가 B 의 발행을 막았다'
    elif [ "$RC" -ne 2 ];                then why="B rc=$RC (기대 2 — 리뷰 산출물 없음)"
    elif ! contains "$ERR" '최근';       then why="B 의 사유가 ②가 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
    fi
  fi
  report "$name" "$why"
}

s12() {
  local name='s12 A 가 일을 다 마치고 끝나도 B 의 플래그·카운터·지문은 그대로' why='' p b bc bf
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$SID_A" "$p/src/app.ts"
  edit "$p" "$SID_B" "$p/src/app.ts"
  stop "$p" "$SID_B"                                    # B 의 카운터·지문이 선다
  b="$(sdir "$p" "$SID_B")"
  bc="$(cat "$b/.stop-block-count" 2>/dev/null)"; bf="$(cat "$b/.stop-block-fp" 2>/dev/null)"
  rm -f "$(sdir "$p" "$SID_A")"/.needs-*               # A 가 게이트를 다 처리했다
  stop "$p" "$SID_A"                                    # A 는 조기 종료 경로(카운터 정리)를 탄다
  if   [ "$RC" -ne 0 ];                                       then why="A rc=$RC (기대 0)"
  elif [ ! -s "$b/.needs-audit" ];                            then why='A 의 종료가 B 의 플래그를 지웠다'
  elif [ "$(cat "$b/.stop-block-count" 2>/dev/null)" != "$bc" ] || [ -z "$bc" ]; then why='A 의 종료가 B 의 카운터를 지웠다·바꿨다'
  elif [ "$(cat "$b/.stop-block-fp" 2>/dev/null)" != "$bf" ] || [ -z "$bf" ];    then why='A 의 종료가 B 의 지문을 지웠다·바꿨다'
  fi
  report "$name" "$why"
}

s13() {
  local name='s13 cksum 이 충돌하는 실제 UUID 두 개 → 서로 다른 폴더 ([cx] r1 #3)' why='' p
  local C1='6ded9ae6-c65f-4417-ab38-4dd763d1a7a4' C2='b91b66ff-a4ee-4048-996a-ebadfe195461'
  [ "$(printf '%s' "$C1" | cksum)" = "$(printf '%s' "$C2" | cksum)" ] || { report "$name" '전제 실패 — 두 값의 cksum 이 다르다'; return 0; }
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "$C1" "$p/src/app.ts"
  if   [ ! -s "$(sdir "$p" "$C1")/.needs-audit" ]; then why='C1 폴더에 플래그 없음'
  elif [ -e "$(sdir "$p" "$C2")/.needs-audit" ];   then why='C2 폴더에도 플래그가 보인다 — 키 충돌'
  fi
  report "$name" "$why"
}

s14() {
  local name='s14 session_id 없는 Stop 의 안내 문구는 옛 바이트 그대로 ([cx] r1 #4)' why='' p
  p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  edit "$p" "" "$p/src/app.ts"
  stop "$p" ""
  if   [ "$RC" -ne 2 ];                                   then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" 'rm -f .claude/.needs-dualreview'; then why="옛 문구가 아니다: $(printf '%s' "$ERR" | grep 'rm -f' | head -1 | head -c 120)"
  fi
  report "$name" "$why"
}

echo "session-state-isolation:"
s01; s02; s03; s04; s05; s06; s07; s08; s09; s10; s11; s12; s13; s14
echo "— $pass/$ran 통과"
[ "$fail" -eq 0 ]
