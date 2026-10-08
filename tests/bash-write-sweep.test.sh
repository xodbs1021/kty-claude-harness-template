#!/usr/bin/env bash
# bash-write-sweep.test.sh — Bash 로 쓴 파일의 완료 게이트(ADR-0024) 회귀 방어.
#
#   "파일을 무엇으로 썼든 게이트는 선다. Edit/Write 로 썼든 `cat >`·`sed -i`·python3 로
#    썼든 같다."
#
# 왜 있나 (2026-09-05 실사고): mark-needs-audit 이 Edit|Write|MultiEdit 에만 걸려 있어서
# Bash 로 하네스 정본을 고친 세션 전체가 무게이트로 끝났다. 게이트가 있다고 믿는 쪽이
# 없는 것보다 나쁘다.
#
# 지키려는 실패 방향:
#   위음성 — Bash 로 쓴 소스가 플래그 없이 지나간다 (구멍 그 자체)
#   위양성 1 — 아무것도 안 쓴 명령(ls·grep)이 플래그를 세운다 → 읽기 전용 턴이 막힌다
#   위양성 2 — 빌드 산출물(git 무시 대상)이 플래그를 세운다 → `make build` 한 번에
#              수백 개가 박힌다
#
# **판정 규칙의 사본을 두지 않는다.** 훅 자신을 돌려 플래그 파일 내용으로 잰다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. mapfile·연관배열·${var,,} 금지.

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
SRC="$REPO_ROOT/template/.claude"

command -v git >/dev/null 2>&1 || { echo "bash-write-sweep: (건너뜀 — git 없음)"; exit 0; }
for f in mark-needs-audit.sh mark-bash-window.sh _common.sh; do
  [ -f "$SRC/hooks/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
done

TMPROOT="$(mktemp -d)" || exit 1
[ -d "$TMPROOT" ] || { echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1; }
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

ran=0; pass=0; fail=0
report() {
  ran=$((ran + 1))
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}
contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

make_project() {
  local p="$TMPROOT/p$ran"
  mkdir -p "$p/src" "$p/.claude/hooks"
  git -C "$p" init -q 2>/dev/null
  cp "$SRC"/hooks/*.sh "$p/.claude/hooks/"
  printf '%s' "$p"
}

window() { printf '{"tool_input":{"command":"x"}}' | CLAUDE_PROJECT_DIR="$1" bash "$1/.claude/hooks/mark-bash-window.sh"; }
sweep()  { printf '{"tool_input":{"command":"%s"}}' "$2" | CLAUDE_PROJECT_DIR="$1" bash "$1/.claude/hooks/mark-needs-audit.sh"; }
flags()  { tr '\n' ' ' < "$1/.claude/.needs-audit" 2>/dev/null; }

echo "bash-write-sweep:"

# 1) Bash 로 쓴 소스는 플래그가 선다 — 구멍 그 자체.
P="$(make_project)"
window "$P"; sleep 1
printf 'package main\n' > "$P/src/app.go"
sweep "$P" "printf ... > src/app.go"
if contains " $(flags "$P")" " src/app.go "; then report "Bash 로 쓴 소스 → 게이트" ""
else report "Bash 로 쓴 소스 → 게이트" "플래그 없음: [$(flags "$P")]"; fi

# 2) 아무것도 안 쓴 명령은 플래그를 세우지 않는다.
P="$(make_project)"
printf 'package main\n' > "$P/src/old.go"
window "$P"; sleep 1
sweep "$P" "ls -la"
if [ -s "$P/.claude/.needs-audit" ]; then report "읽기 전용 명령 → 무플래그" "플래그가 섬: [$(flags "$P")]"
else report "읽기 전용 명령 → 무플래그" ""; fi

# 3) git 이 무시하는 산출물은 제외하고, 같은 명령이 만든 소스는 잡는다.
P="$(make_project)"
printf 'out/\n' > "$P/.gitignore"; mkdir -p "$P/out"
window "$P"; sleep 1
printf 'package main\n' > "$P/out/bundle.go"
printf 'package main\n' > "$P/src/real.go"
sweep "$P" "make build"
F=" $(flags "$P") "
if contains "$F" " out/bundle.go "; then report "빌드 산출물 제외" "무시 대상이 플래그에 박힘"
elif ! contains "$F" " src/real.go "; then report "빌드 산출물 제외" "정작 소스를 놓침: [$F]"
else report "빌드 산출물 제외" ""; fi

# 4) 표식이 없으면(이 훅이 등록 안 된 설치본) 스윕은 잠든다 — 예전 동작으로 축퇴.
P="$(make_project)"
printf 'package main\n' > "$P/src/app.go"
sweep "$P" "printf ... > src/app.go"
if [ -s "$P/.claude/.needs-audit" ]; then report "표식 없음 → 스윕 비활성" "표식 없이 스윕이 돔"
else report "표식 없음 → 스윕 비활성" ""; fi

# 5) **JSON 이스케이프**: 따옴표·백슬래시가 든 파일명도 잡는다.
#    초판은 printf 로 JSON 을 조립해서 이런 파일명이 파싱 실패 → 빈 file_path →
#    조용한 통과가 됐다(실측 CRITICAL). json.dumps 로 고쳤고, 여기서 못 박는다.
P="$(make_project)"
window "$P"; sleep 1
printf 'package main\n' > "$P/src/plain.go"
printf 'package main\n' > "$P/src/say\"hi\".go"
printf 'package main\n' > "$P/src/back\\slash.go"
sweep "$P" "generate"
F="$(flags "$P")"
miss=""
for want in 'src/plain.go' 'src/say"hi".go' 'src/back\slash.go'; do
  contains " $F " " $want " || miss="$miss $want"
done
if [ -z "$miss" ]; then report "따옴표·백슬래시 파일명도 게이트" ""
else report "따옴표·백슬래시 파일명도 게이트" "놓침:$miss (실제: [$F])"; fi

# 6) 개행이 든 경로는 기록하지 않되 **소리를 낸다** — 조용한 위음성 금지.
P="$(make_project)"
window "$P"; sleep 1
printf 'package main\n' > "$P/src/ok.go"
printf 'package main\n' > "$P/src/new
line.go"
OUT="$(sweep "$P" "generate")"
if contains "$OUT" "systemMessage"; then report "개행 경로 → 경고를 낸다" ""
else report "개행 경로 → 경고를 낸다" "조용히 넘어감"; fi

# 7) **삭제된 추적 파일도 잡는다.** find -type f 로는 원리적으로 못 본다 —
#    `rm src/auth.go` 가 게이트를 그대로 통과하던 구멍(codex r1 CRITICAL).
P="$(make_project)"
printf 'package main\n' > "$P/src/auth.go"
git -C "$P" add -A >/dev/null 2>&1
git -C "$P" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
window "$P"; sleep 1
rm -f "$P/src/auth.go"
sweep "$P" "rm src/auth.go"
if contains " $(flags "$P")" " src/auth.go "; then report "삭제된 추적 파일 → 게이트" ""
else report "삭제된 추적 파일 → 게이트" "플래그 없음: [$(flags "$P")]"; fi

# 8) **병렬 창 경합**: 창이 둘일 때 먼저 쓴 파일이 사라지지 않는다.
#    표식이 하나뿐이던 초판은 B의 Pre 가 A의 창을 덮어 A의 변경을 통째로 잃었다.
P="$(make_project)"
window "$P"; sleep 1              # A 의 창
printf 'package main\n' > "$P/src/a.go"
window "$P"; sleep 1              # B 의 창 (A 가 아직 Post 를 안 돌린 상태)
printf 'package main\n' > "$P/src/b.go"
sweep "$P" "A 의 PostToolUse"
F=" $(flags "$P") "
if contains "$F" " src/a.go "; then report "병렬 창 — 먼저 쓴 파일 보존" ""
else report "병렬 창 — 먼저 쓴 파일 보존" "A 의 파일이 사라짐: [$F]"; fi

# 9) **감사 후 재플래그 금지 (벽돌 방지).** 창을 소비하고 지우지 않으면 매번 세션 맨 처음
#    창을 써서, 감사자가 플래그를 지워도 다음 Bash 가 같은 파일을 다시 세운다 →
#    게이트가 영원히 안 닫힌다([cc] r2 CRITICAL).
P="$(make_project)"
window "$P"; sleep 1
printf 'package main\n' > "$P/src/one.go"
sweep "$P" "1차"
rm -f "$P/.claude/.needs-audit"            # 감사자가 통과시킨 상황
window "$P"; sleep 1
sweep "$P" "2차 — 아무것도 안 씀"
if [ -s "$P/.claude/.needs-audit" ]; then report "감사 후 재플래그 없음" "옛 파일이 다시 섬: [$(flags "$P")]"
else report "감사 후 재플래그 없음" ""; fi

# 10) **한글·특수문자 경로의 삭제**도 잡는다. git status 는 -z 없이는 이런 경로를
#     따옴표+8진 이스케이프로 내서 존재하지 않는 경로가 박힌다(codex r2).
P="$(make_project)"
printf 'package main\n' > "$P/src/한글.go"
git -C "$P" add -A >/dev/null 2>&1
git -C "$P" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1
window "$P"; sleep 1
rm -f "$P/src/한글.go"
sweep "$P" "rm"
if contains " $(flags "$P")" " src/한글.go "; then report "한글 경로 삭제 → 게이트" ""
else report "한글 경로 삭제 → 게이트" "플래그: [$(flags "$P")]"; fi

# 11) 기존 경로(Edit/Write 페이로드)는 그대로 동작한다 — 회귀 방어.
P="$(make_project)"
printf '{"tool_input":{"file_path":"%s/src/direct.go"}}' "$P" \
  | CLAUDE_PROJECT_DIR="$P" bash "$P/.claude/hooks/mark-needs-audit.sh" >/dev/null 2>&1
if contains " $(flags "$P")" " src/direct.go "; then report "Edit/Write 경로 불변" ""
else report "Edit/Write 경로 불변" "플래그 없음: [$(flags "$P")]"; fi

# 12) **실패한 Bash 도 창을 소비하는 배선**이 settings.json 에 있다.
#     Claude Code 가 도구 실패로 처리한 Bash(예: `false` — 2026-10-08 실측)에는 PostToolUse
#     가 아니라 PostToolUseFailure 가 발화한다. PostToolUse 에만 걸려 있으면 그 호출의 창이
#     남고, 그 옛 창이 기준이 되어 리뷰가 끝난 파일이 Bash 마다 다시 플래그에 오른다
#     (실세션 미소비 창 약 110개).
#     판정은 **엄격하게** 한다 — matcher 가 Bash 이고, type 이 command 이고, 명령이 실제 실행
#     명령과 글자 그대로 같아야 한다. 부분 문자열로 보면 `echo mark-needs-audit.sh` 같은 가짜
#     등록도 통과한다(r1 [cx] L). 판정기 자신이 가짜를 거르는지도 픽스처로 함께 잰다.
SWEEP_CMD='bash "$CLAUDE_PROJECT_DIR/.claude/hooks/mark-needs-audit.sh"'
failure_wired() {   # <settings.json> — 등록돼 있으면 yes
  python3 - "$1" "$SWEEP_CMD" <<'PY' 2>/dev/null
import json, sys
hooks = json.load(open(sys.argv[1])).get("hooks", {})
for entry in hooks.get("PostToolUseFailure", []):
    if entry.get("matcher") != "Bash":
        continue
    for h in entry.get("hooks", []):
        if h.get("type") == "command" and h.get("command") == sys.argv[2]:
            print("yes")
            sys.exit(0)
PY
}
fake_settings() {   # <경로> <type> <command> — PostToolUseFailure/Bash 등록 하나짜리 픽스처
  python3 - "$1" "$2" "$3" <<'PY'
import json, sys
hook = {"type": sys.argv[2], "command": sys.argv[3]}
json.dump({"hooks": {"PostToolUseFailure": [{"matcher": "Bash", "hooks": [hook]}]}},
          open(sys.argv[1], "w"))
PY
}
if [ "$(failure_wired "$SRC/settings.json")" = "yes" ]; then
  report "실패 Bash 배선(PostToolUseFailure·Bash)" ""
else report "실패 Bash 배선(PostToolUseFailure·Bash)" "settings.json 에 등록 없음"; fi

miss=""
fake_settings "$TMPROOT/fake-echo.json" command 'echo mark-needs-audit.sh'
[ -z "$(failure_wired "$TMPROOT/fake-echo.json")" ] || miss="$miss echo-명령"
fake_settings "$TMPROOT/fake-type.json" prompt "$SWEEP_CMD"
[ -z "$(failure_wired "$TMPROOT/fake-type.json")" ] || miss="$miss type≠command"
if [ -z "$miss" ]; then report "배선 판정기 — 가짜 등록을 거른다" ""
else report "배선 판정기 — 가짜 등록을 거른다" "통과시킨 가짜:$miss"; fi

# 13–15 는 **실제 실패 입력의 모양**으로 부른다 — session_id · cwd 가 실리고(세션 폴더로
# 바인딩), tool_response 대신 error 가 있고, is_interrupt 가 참·거짓 둘 다 온다.
# 이 시험들은 Claude Code 가 이벤트를 발화하는지를 재현하지 않는다(그건 12 의 배선 몫).
# 훅이 그 입력을 받았을 때 성공 경로와 같은 판정 · 창 소비를 하는지를 잰다.
SID='33333333-cccc-4ccc-8ccc-cccccccccccc'
sdir() {   # <프로젝트> — 세션 상태 폴더(.claude/.sessions/<SHA-256 앞 32자>)
  printf '%s/.claude/.sessions/%s' "$1" "$(printf '%s' "$SID" \
    | python3 -c 'import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest()[:32])')"
}
window_s() {
  printf '{"session_id":"%s","cwd":"%s","tool_name":"Bash","tool_input":{"command":"x"}}' \
    "$SID" "$1" | CLAUDE_PROJECT_DIR="$1" bash "$1/.claude/hooks/mark-bash-window.sh"
}
sweep_ok_s() {   # <프로젝트> <명령> — 성공 페이로드(PostToolUse)
  printf '{"hook_event_name":"PostToolUse","session_id":"%s","cwd":"%s","tool_name":"Bash","tool_input":{"command":"%s"},"tool_response":{"stdout":""}}' \
    "$SID" "$1" "$2" | CLAUDE_PROJECT_DIR="$1" bash "$1/.claude/hooks/mark-needs-audit.sh"
}
sweep_failed() {   # <프로젝트> <명령> <is_interrupt> — 실패 페이로드(PostToolUseFailure)
  printf '{"hook_event_name":"PostToolUseFailure","session_id":"%s","cwd":"%s","tool_name":"Bash","tool_input":{"command":"%s"},"error":"Exit code 1","is_interrupt":%s}' \
    "$SID" "$1" "$2" "$3" | CLAUDE_PROJECT_DIR="$1" bash "$1/.claude/hooks/mark-needs-audit.sh"
}
sflags()  { tr '\n' ' ' < "$(sdir "$1")/.needs-audit" 2>/dev/null; }
windows() { find "$(sdir "$1")/.bash-windows" -type f 2>/dev/null | wc -l | tr -d ' '; }

# 13) 실패 페이로드도 가장 오래된 창을 소비하고 성공 페이로드와 같은 판정을 낸다.
#     is_interrupt 는 참·거짓 둘 다 같은 경로여야 한다.
for intr in false true; do
  name="실패 페이로드(is_interrupt=$intr) → 게이트·창 소비"
  P="$(make_project)"
  window_s "$P"; sleep 1
  printf 'package main\n' > "$P/src/failed.go"
  before="$(windows "$P")"
  sweep_failed "$P" "generate; false" "$intr"
  after="$(windows "$P")"
  F=" $(sflags "$P") "
  if ! contains "$F" " src/failed.go "; then report "$name" "세션 플래그 없음: [$F]"
  elif [ -s "$P/.claude/.needs-audit" ]; then report "$name" "세션 밖 공유 플래그에 기록됨"
  elif [ "$before" -ne 1 ] || [ "$after" -ne 0 ]; then
    report "$name" "창 미소비: 전 $before · 후 $after"
  else report "$name" ""; fi
done

# 14) 실패 호출 뒤에도 감사 후 재플래그가 없다 — 9 의 실패판.
P="$(make_project)"
window_s "$P"; sleep 1
printf 'package main\n' > "$P/src/one.go"
sweep_failed "$P" "1차 — 실패" false
rm -f "$(sdir "$P")/.needs-audit"           # 감사자가 통과시킨 상황
window_s "$P"; sleep 1
sweep_ok_s "$P" "2차 — 아무것도 안 씀"
if [ -s "$(sdir "$P")/.needs-audit" ]; then
  report "실패 뒤 감사 후 재플래그 없음" "옛 파일이 다시 섬: [$(sflags "$P")]"
else report "실패 뒤 감사 후 재플래그 없음" ""; fi

# 15) **이 결함이 실제로 만든 증상**: 듀얼리뷰 플래그 mtime 이 리뷰 산출물보다 새로워지지
#     않는다. Stop 훅은 플래그보다 새로운 _workspace/*codex*.md 가 있으면 플래그를 스스로
#     지운다(ADR-0017). 실패 호출의 창이 남으면 다음 Bash 가 그 옛 창으로 스윕해 같은 파일을
#     다시 기록하고, record_flag 의 touch 로 플래그가 산출물보다 새로워져 자동 해제가 안 됐다.
#     여기서는 실패 경로가 창을 소비해 누수 창이 없을 때 그 증상이 없음을 잰다.
name="실패 뒤 듀얼리뷰 플래그가 리뷰 산출물보다 새로워지지 않음"
P="$(make_project)"
window_s "$P"; sleep 1
printf 'package main\n' > "$P/src/one.go"
sweep_failed "$P" "generate; false" false     # 쓰고 실패한 호출
DR="$(sdir "$P")/.needs-dualreview"
REVIEW="$P/_workspace/82_codex_review.md"
mkdir -p "$P/_workspace"; sleep 1
printf 'review\n' > "$REVIEW"                 # 플래그보다 새로운 리뷰 산출물
window_s "$P"; sleep 1
sweep_ok_s "$P" "ls"                          # 아무것도 안 쓴 다음 Bash
if [ ! -s "$DR" ]; then report "$name" "실패 호출이 플래그를 세우지 않음"
elif [ "$REVIEW" -nt "$DR" ]; then report "$name" ""
else report "$name" "플래그가 산출물보다 새로움(자동 해제 불가)"; fi

printf '  %d개 중 %d개 통과\n' "$ran" "$pass"
[ "$fail" -eq 0 ]
