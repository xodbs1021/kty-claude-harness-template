#!/usr/bin/env bash
# guard-design-path.sh 동작 검증. 임시 프로젝트를 만들어 훅을 직접 호출한다.
# 계약: rc=0 통과 / rc=2 차단. 케이스는 rc 만이 아니라 **차단 사유 문구**까지 잰다 —
# 우연한 rc=2(픽스처 실패·크래시)가 차단으로 위장하는 "스치는 통과"를 막는다.
# 픽스처 생성 실패는 그 자리에서 exit 99 — 읽기 전용 환경에서 PASS 를 찍지 않는다.
#
# 이 게이트가 지키는 것: 설계·계획 산출물은 harness-orchestrator 를 태운 세션에서만 쓸 수 있다.
# 회귀 위험이 큰 두 축을 특히 본다 —
#   1) 언어·위치 축: 비영문 이름(설계서)·지식 저장소 경로도 잡히는가 (실사고 2026-08-31)
#   2) 세션 축: 옛 도장이 다음 세션을 통과시키지 않는가 (영구 통과 구멍)
#
# 사용법: ./tests/guard-design-path.test.sh   (전건 통과 시 종료 코드 0)
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/../template/.claude/hooks/guard-design-path.sh"

fail=0
say() { printf '%s\n' "$*"; }
die() { say "FAIL(픽스처): $*"; exit 99; }

[ -f "$HOOK" ] || die "훅이 없습니다: $HOOK"

HOOK_ERR=""
RC=0
run_hook() {  # $1=프로젝트경로 $2=payload → rc 를 RC 에, stderr 를 HOOK_ERR 에
  HOOK_ERR="$(printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" ECC_DISABLED_HOOKS="${DISABLE:-}" bash "$HOOK" 2>&1 >/dev/null)"
  RC=$?
}

mkproj() {  # 새 임시 프로젝트. stdout = 경로. 실패는 die.
  d="$(mktemp -d)" || die "mktemp 불가"
  mkdir -p "$d/.claude" "$d/_workspace" || die "mkdir 불가: $d"
  printf '%s\n' "$d"
}

check() {  # $1=케이스명 $2=기대rc [$3=stderr 필수 문구]
  if [ "$2" -ne "$RC" ]; then
    say "FAIL: $1 (기대 rc=$2, 실제 rc=$RC, stderr: ${HOOK_ERR})"; fail=1; return
  fi
  if [ "$#" -ge 3 ]; then
    case "$HOOK_ERR" in
      *"$3"*) ;;
      *) say "FAIL: $1 (사유 문구 '$3' 부재 — stderr: ${HOOK_ERR})"; fail=1; return ;;
    esac
  fi
  say "PASS: $1"
}

W() {  # Write payload: $1=session $2=file_path
  printf '{"tool_name":"Write","session_id":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2"
}
S() {  # Skill payload: $1=session $2=skill
  printf '{"tool_name":"Skill","session_id":"%s","tool_input":{"skill":"%s"}}' "$1" "$2"
}

BLOCK_MSG="설계 경로 강제"

# --- 1) 도장 없음 → 설계 산출물은 막힌다 -----------------------------------
P="$(mkproj)"
run_hook "$P" "$(W SESS-A /vault/Projects/X/specs/10_설계서_r1.md)"
check "도장없음·비영문 이름·지식저장소 경로 → 차단" 2 "$BLOCK_MSG"

run_hook "$P" "$(W SESS-A "$P/_workspace/00_design.md")"
check "도장없음·영문 앵커 이름 → 차단" 2 "$BLOCK_MSG"

run_hook "$P" "$(W SESS-A /repo/_workspace/01_plan_media.md)"
check "도장없음·계획 산출물 → 차단" 2 "$BLOCK_MSG"

# --- 2) 면제 대상은 통과한다 (막으면 리뷰 회수가 불가능해진다) -------------
run_hook "$P" "$(W SESS-A /vault/21_codex_review_r1_판정.md)"
check "리뷰 판정문 → 통과" 0

run_hook "$P" "$(W SESS-A /vault/raw/실측_S3PUT지연.md)"
check "raw 실측 → 통과" 0

run_hook "$P" "$(W SESS-A /vault/specs/POK-1/_색인.md)"
check "색인 → 통과" 0

run_hook "$P" "$(W SESS-A /vault/specs/POK-1/00_설계입력서.md)"
check "입력서(설계의 입력이지 산출이 아님) → 통과" 0

run_hook "$P" "$(W SESS-A /repo/media/internal/upload/worker.go)"
check "일반 코드 파일 → 통과" 0

# --- 3) 도장 찍기 -----------------------------------------------------------
run_hook "$P" "$(S SESS-A readable-writing)"
check "무관 스킬 → 통과" 0
if [ -f "$P/.claude/.harness-path" ]; then
  say "FAIL: 무관 스킬이 도장을 찍었다"; fail=1
else
  say "PASS: 무관 스킬은 도장을 안 찍는다"
fi

run_hook "$P" "$(S SESS-A harness-orchestrator)"
check "harness-orchestrator 호출 → 통과" 0
if [ "$(cat "$P/.claude/.harness-path" 2>/dev/null)" = "SESS-A" ]; then
  say "PASS: 도장에 session_id 가 기록된다"
else
  say "FAIL: 도장 내용이 session_id 가 아니다"; fail=1
fi

# --- 4) 도장 이후 -----------------------------------------------------------
run_hook "$P" "$(W SESS-A /vault/specs/12_설계서_r3.md)"
check "도장 있음·같은 세션 → 통과" 0

run_hook "$P" "$(W SESS-B /vault/specs/12_설계서_r3.md)"
check "도장 있음·다른 세션 → 차단(영구 통과 구멍 없음)" 2 "$BLOCK_MSG"

# --- 5) 탈출구는 동작한다 ---------------------------------------------------
P2="$(mkproj)"
DISABLE="pre:write:design-path" run_hook "$P2" "$(W SESS-C /vault/10_설계서.md)"
check "훅 id 로 개별 비활성 → 통과" 0

# --- 6) session_id 가 없으면 도장을 찍지 않는다 (우연 일치 구멍 방지) ------
P3="$(mkproj)"
printf '{"tool_name":"Skill","session_id":"","tool_input":{"skill":"harness-orchestrator"}}' \
  | CLAUDE_PROJECT_DIR="$P3" bash "$HOOK" >/dev/null 2>&1
if [ -f "$P3/.claude/.harness-path" ]; then
  say "FAIL: session_id 없이 도장이 찍혔다"; fail=1
else
  say "PASS: session_id 없으면 도장을 안 찍는다"
fi

rm -rf "$P" "$P2" "$P3"
if [ "$fail" -eq 0 ]; then say "전건 통과"; exit 0; fi
say "실패 있음"; exit 1
