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

# 5) 기존 경로(Edit/Write 페이로드)는 그대로 동작한다 — 회귀 방어.
P="$(make_project)"
printf '{"tool_input":{"file_path":"%s/src/direct.go"}}' "$P" \
  | CLAUDE_PROJECT_DIR="$P" bash "$P/.claude/hooks/mark-needs-audit.sh" >/dev/null 2>&1
if contains " $(flags "$P")" " src/direct.go "; then report "Edit/Write 경로 불변" ""
else report "Edit/Write 경로 불변" "플래그 없음: [$(flags "$P")]"; fi

printf '  %d개 중 %d개 통과\n' "$ran" "$pass"
[ "$fail" -eq 0 ]
