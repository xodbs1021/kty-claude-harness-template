#!/usr/bin/env bash
# stylecheck-gate.test.sh — 스타일 검사 게이트(stop:stylecheck, ADR-0023) 회귀 방어.
#
#   "Google 스타일 가이드의 기계 판정 조항을 어긴 턴은 끝낼 수 없다.
#    그 게이트는 타입체크와 **다른 슬롯**을 쓰므로 한쪽을 덮어써도 다른 쪽이 산다."
#
# 지키려는 실패 방향:
#   위음성 1 — HARNESS_TYPECHECK_CMD 를 갈아치우면 스타일 게이트가 조용히 사라진다.
#              (초판이 정확히 이랬다. 슬롯 분리의 존재 이유라 여기서 못 박는다)
#   위음성 2 — 키를 모르는 **기존 설치본**에서 게이트가 조용히 꺼진다.
#              (HARNESS_KNOWLEDGE_GATE 와 같은 원리 — 표명이 없으면 켜짐)
#   위양성  — 끄겠다고 표명한 프로젝트(빈 값)를 계속 막는다. 탈출구가 없으면 게이트가
#             아니라 벽돌이다.
#
# **판정 규칙의 사본을 두지 않는다.** 훅 자신을 돌려 출력으로 잰다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. mapfile·연관배열·${var,,} 금지.

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
SRC="$REPO_ROOT/template/.claude"

command -v gofmt >/dev/null 2>&1 || { echo "stylecheck-gate: (건너뜀 — gofmt 없음)"; exit 0; }
for f in verify-before-stop.sh _common.sh; do
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

# make_project <env 본문> — gofmt 위반이 있는 Go 모듈 + 하네스를 갖춘 프로젝트를 만든다.
make_project() {
  local p="$TMPROOT/p$ran"
  mkdir -p "$p/svc" "$p/.claude/hooks" "$p/.claude/harness" "$p/.claude/skills"
  git -C "$p" init -q 2>/dev/null
  cp "$SRC"/hooks/*.sh "$p/.claude/hooks/"
  cp -R "$SRC/skills/google-styleguide" "$p/.claude/skills/"
  printf 'module example.com/svc\n\ngo 1.22\n' > "$p/svc/go.mod"
  printf 'package svc\n\nfunc  Bad( ) int {\nreturn 1\n}\n' > "$p/svc/bad.go"
  printf '%s\n' "$1" > "$p/.claude/harness/harness.env"
  # 게이트가 돌려면 "할 일 있음"이어야 한다 — 읽기 전용 턴은 조기 종료한다.
  printf 'svc/bad.go\n' > "$p/.claude/.needs-audit"
  printf '%s' "$p"
}

# 문구만 보면 메시지를 낸 뒤 rc=0/1 로 fail-open 해도 통과한다 — 차단 게이트의 계약은
# rc=2 다(codex r1 MEDIUM). 그래서 호출부가 `OUT="$(run_stop …)"; RC=$?` 로 **명령 치환의
# 종료 코드**를 받는다. 함수 안에서 변수에 담으면 서브셸에 갇혀 부모가 못 본다.
run_stop() {
  printf '{"stop_hook_active":false,"transcript_path":""}' \
    | CLAUDE_PROJECT_DIR="$1" bash "$1/.claude/hooks/verify-before-stop.sh" 2>&1
}

echo "stylecheck-gate:"

# 1) 전용 키가 설정돼 있고 위반이 있으면 막는다.
P="$(make_project 'HARNESS_TYPECHECK_CMD=""
HARNESS_STYLECHECK_CMD="bash .claude/skills/google-styleguide/scripts/check-style.sh"')"
OUT="$(run_stop "$P")"; RC=$?
if ! contains "$OUT" "스타일 검사 실패"; then report "위반 → 완료 차단" "차단 메시지 없음"
elif [ "$RC" -ne 2 ]; then report "위반 → 완료 차단" "메시지는 냈지만 rc=$RC (기대 2 — fail-open)"
else report "위반 → 완료 차단" ""; fi

# 2) **슬롯 분리의 핵심**: 타입체크를 프로젝트 명령으로 갈아치워도 스타일은 산다.
P="$(make_project 'HARNESS_TYPECHECK_CMD="true"
HARNESS_STYLECHECK_CMD="bash .claude/skills/google-styleguide/scripts/check-style.sh"')"
OUT="$(run_stop "$P")"
if contains "$OUT" "스타일 검사 실패"; then report "타입체크를 덮어써도 스타일 게이트 생존" ""
else report "타입체크를 덮어써도 스타일 게이트 생존" "스타일 게이트가 사라짐"; fi

# 3) 키가 아예 없는 기존 설치본 — 번들 검사기로 축퇴해 여전히 막는다.
P="$(make_project 'HARNESS_TYPECHECK_CMD=""')"
OUT="$(run_stop "$P")"
if contains "$OUT" "스타일 검사 실패"; then report "키 부재 → 번들 검사기로 켜짐" ""
else report "키 부재 → 번들 검사기로 켜짐" "조용히 꺼짐"; fi

# 4) 빈 값은 명시적 끄기 — 막지 않는다.
P="$(make_project 'HARNESS_TYPECHECK_CMD=""
HARNESS_STYLECHECK_CMD=""')"
OUT="$(run_stop "$P")"
if contains "$OUT" "스타일 검사 실패"; then report "빈 값 → 꺼짐" "껐는데도 막음"
else report "빈 값 → 꺼짐" ""; fi

# 5) 위반이 없으면 스타일로는 막지 않는다.
P="$(make_project 'HARNESS_TYPECHECK_CMD=""
HARNESS_STYLECHECK_CMD="bash .claude/skills/google-styleguide/scripts/check-style.sh"')"
(cd "$P/svc" && gofmt -w . 2>/dev/null)
OUT="$(run_stop "$P")"
if contains "$OUT" "스타일 검사 실패"; then report "위반 없음 → 통과" "깨끗한데 막음"
else report "위반 없음 → 통과" ""; fi

printf '  %d개 중 %d개 통과\n' "$ran" "$pass"
[ "$fail" -eq 0 ]
