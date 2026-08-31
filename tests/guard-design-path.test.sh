#!/usr/bin/env bash
# guard-design-path.sh 동작 검증. 임시 프로젝트를 만들어 훅을 직접 호출한다.
# 계약: rc=0 통과 / rc=2 차단. 케이스는 rc 만이 아니라 **차단 사유 문구**까지 잰다.
#
# [cx M-3] 반영: 초판의 die 는 명령 치환 서브셸만 종료해 픽스처 실패가 PASS 로 위장했다.
#   이 판은 mkproj 호출마다 부모에서 `|| exit 99` 를 걸고, 오류는 stderr 로, 임시 루트를
#   trap 으로 정리하며, 기대 케이스 수를 상수로 강제한다.
# [cx H-4]·[cx M-1]·[cx H-3]·[cx H-2] 재현 케이스를 회귀로 고정한다 — 2026-08-31 리뷰에서
#   실측 재현된 그 이름들 그대로다.
#
# 사용법: ./tests/guard-design-path.test.sh   (전건 통과 시 종료 코드 0)
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/../template/.claude/hooks/guard-design-path.sh"

EXPECTED_CASES=46   # check/expect_* 호출 수. 어긋나면 케이스가 조용히 증발한 것이다.
count=0
fail=0
say() { printf '%s\n' "$*"; }
die() { printf 'FAIL(픽스처): %s\n' "$*" >&2; exit 99; }

[ -f "$HOOK" ] || die "훅이 없습니다: $HOOK"

TMPROOT="$(mktemp -d)" || die "mktemp 불가"
trap 'rm -rf "$TMPROOT"' EXIT

HOOK_ERR=""
RC=0
run_hook() {  # $1=프로젝트경로 $2=payload → RC, HOOK_ERR
  HOOK_ERR="$(printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" ECC_DISABLED_HOOKS="${DISABLE:-}" bash "$HOOK" 2>&1 >/dev/null)"
  RC=$?
}

mkproj() {  # 새 임시 프로젝트. stdout = 경로. 오류는 stderr(호출부가 || exit 99).
  local d
  d="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { printf 'mktemp 불가\n' >&2; return 1; }
  mkdir -p "$d/.claude" "$d/_workspace" || { printf 'mkdir 불가: %s\n' "$d" >&2; return 1; }
  printf '%s\n' "$d"
}

check() {  # $1=케이스명 $2=기대rc [$3=stderr 필수 문구]
  count=$((count+1))
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
expect_stamp() {  # $1=케이스명 $2=프로젝트 $3=세션 $4=있어야(1)/없어야(0)
  count=$((count+1))
  local f n
  n="$(printf '%s' "$3" | cksum | cut -d' ' -f1)"
  f="$2/.claude/.harness-path.$n"
  if [ "$4" -eq 1 ]; then
    if [ "$(cat "$f" 2>/dev/null)" = "$3" ]; then say "PASS: $1"; else say "FAIL: $1 (도장 없음/불일치)"; fail=1; fi
  else
    if [ -f "$f" ]; then say "FAIL: $1 (도장이 찍혔다)"; fail=1; else say "PASS: $1"; fi
  fi
}

W() { printf '{"tool_name":"Write","session_id":"%s","tool_input":{"file_path":"%s"}}' "$1" "$2"; }
S() { printf '{"tool_name":"Skill","session_id":"%s","tool_input":{"skill":"%s"}}' "$1" "$2"; }

BLOCK="설계 경로 강제"

# ── 1) 도장 없음 → 설계 산출물 차단 ────────────────────────────────────────
P="$(mkproj)" || exit 99
run_hook "$P" "$(W SESS-A /vault/Projects/X/specs/10_설계서_r1.md)";  check "비영문 이름·지식저장소 경로 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-A "$P/_workspace/00_design.md")";             check "영문 앵커 이름 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-A /repo/_workspace/01_plan_media.md)";        check "계획 산출물 → 차단" 2 "$BLOCK"

# [cx H-4] 회귀 — 초판에서 면제가 설계 판정을 선점해 전부 통과했던 이름들.
run_hook "$P" "$(W SESS-A /vault/10_설계서_리뷰반영본.md)";           check "[cx H-4] 설계서+리뷰 토큰 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-A /vault/설계서_입력서반영.md)";              check "[cx H-4] 설계서+입력서 토큰 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-A /repo/_workspace/00_design_progress.md)";   check "[cx H-4] design+progress → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-A /repo/design_changelog.md)";                check "[cx H-4] design+log → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-A /repo/draw_design.md)";                     check "[cx H-4] draw 안의 raw → 차단" 2 "$BLOCK"

# ── 2) 설계 패턴 밖 → 통과 (면제 목록 없이 패턴 정밀도로) ──────────────────
run_hook "$P" "$(W SESS-A /vault/21_codex_review_r1_판정.md)";        check "리뷰 판정문 → 통과" 0
run_hook "$P" "$(W SESS-A /vault/raw/실측_S3PUT지연.md)";             check "raw 실측 → 통과" 0
run_hook "$P" "$(W SESS-A /vault/specs/POK-1/_색인.md)";              check "색인 → 통과" 0
run_hook "$P" "$(W SESS-A /vault/specs/POK-1/00_설계입력서.md)";      check "설계입력서(입력 문서) → 통과" 0
run_hook "$P" "$(W SESS-A /repo/media/internal/upload/worker.go)";    check "일반 코드 파일 → 통과" 0
run_hook "$P" "$(W SESS-A /ws/10_codex_plan_review.md)";              check "리뷰 명명 계약(NN_출처_plan_review) → 통과" 0

# [cx M-1] 회귀 — 초판에서 확장자 경계가 없어 차단됐던 정상 파일들.
run_hook "$P" "$(W SESS-A /repo/src/설계_도구.py)";                   check "[cx M-1] 한글+비md 소스 → 통과" 0
run_hook "$P" "$(W SESS-A /repo/data/분기_계획.csv)";                 check "[cx M-1] 한글+csv 데이터 → 통과" 0
run_hook "$P" "$(W SESS-A /repo/docs/12_designer.md)";                check "[cx M-1] designer(토큰 경계) → 통과" 0

# ── 3) 도장 찍기 (PostToolUse Skill) ───────────────────────────────────────
run_hook "$P" "$(S SESS-A readable-writing)";                         check "무관 스킬 → 통과" 0
expect_stamp "무관 스킬은 도장을 안 찍는다" "$P" "SESS-A" 0

# [cx H-2] 회귀 — 부분 문자열 매치가 찍던 도장.
run_hook "$P" "$(S SESS-A not-harness-orchestrator-invalid)";         check "[cx H-2] 유사 이름 스킬 → 통과" 0
expect_stamp "[cx H-2] 유사 이름은 도장을 안 찍는다" "$P" "SESS-A" 0

run_hook "$P" "$(S SESS-A harness-orchestrator)";                     check "정확 이름 → 통과" 0
expect_stamp "정확 이름은 도장을 찍는다(session_id 기록)" "$P" "SESS-A" 1

P4="$(mkproj)" || exit 99
run_hook "$P4" "$(S SESS-D myplugin:harness-orchestrator)";           check "[cx r3 M-1] 플러그인 접두 → 통과(무해)" 0
expect_stamp "[cx r3 M-1] 플러그인 접두는 도장을 안 찍는다(임의 네임스페이스 불신)" "$P4" "SESS-D" 0

# ── 4) 도장 이후 ───────────────────────────────────────────────────────────
run_hook "$P" "$(W SESS-A /vault/specs/12_설계서_r3.md)";             check "도장 있음·같은 세션 → 통과" 0
run_hook "$P" "$(W SESS-B /vault/specs/12_설계서_r3.md)";             check "도장 있음·다른 세션 → 차단" 2 "$BLOCK"

# [cx M-2] 병렬 세션 — B 가 도장을 찍어도 A 의 도장이 살아 있다(세션별 파일).
run_hook "$P" "$(S SESS-B harness-orchestrator)";                     check "두 번째 세션도 도장 → 통과" 0
run_hook "$P" "$(W SESS-A /vault/specs/13_설계서_r4.md)";             check "[cx M-2] 병렬 세션이 서로 무효화하지 않는다" 0

# ── 5) fail-closed ([cx H-3] 회귀 — 초판은 전부 rc=0 이었다) ───────────────
run_hook "$P" 'not-json{{{';                                          check "[cx H-3] malformed JSON → 차단" 2 "파싱·타입 검증에 실패"
run_hook "$P" '{"tool_name":"Write","session_id":"S","tool_input":{}}'; check "[cx H-3] 경로 필드 부재 → 차단" 2 "경로를 읽지 못했습니다"

# ── 5b) [cx r2 H-1] 이름 경계 회귀 — 재검에서 통과가 재현됐던 이름들 ───────
run_hook "$P" "$(W SESS-Z /ws/00_plan-media.md)";                     check "[cx r2 H-1] 하이픈 경계(plan-)·무도장 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-Z /ws/00_design-reference-gate.md)";          check "[cx r2 H-1] 하이픈 경계(design-)·무도장 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-Z /ws/design.md)";                            check "[cx r2 H-1] 정확 이름 design.md·무도장 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-Z /ws/plan.md)";                              check "[cx r2 H-1] 정확 이름 plan.md·무도장 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-Z /ws/00_designdoc.md)";                      check "[cx r2 H-1] 경계 문자 없음(designdoc) → 통과(공시된 결정)" 0

# [cx r2 M-2] 비문자열 경로 — json_get 문자열화가 통과시켰던 형태.
run_hook "$P" '{"tool_name":"Write","session_id":"S","tool_input":{"file_path":[]}}'
check "[cx r2 M-2] file_path 배열 → 차단" 2 "타입 검증"
run_hook "$P" '{"tool_name":"Write","session_id":"S","tool_input":{"file_path":false}}'
check "[cx r2 M-2] file_path 불리언 → 차단" 2 "타입 검증"

# [cc r3 H-1] 후행형 하이픈 경계 — auth-design.md 가 통과하던 구멍.
run_hook "$P" "$(W SESS-Z /ws/auth-design.md)";                       check "[cc r3 H-1] 후행 하이픈(–design.md)·무도장 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-Z /ws/media-plan.md)";                        check "[cc r3 H-1] 후행 하이픈(–plan.md)·무도장 → 차단" 2 "$BLOCK"
run_hook "$P" "$(W SESS-Z /ws/skin-redesign.md)";                     check "[cc r3 H-1] 경계 없는 redesign → 통과" 0

# ── 6) 탈출구·경계 ─────────────────────────────────────────────────────────
P2="$(mkproj)" || exit 99
DISABLE="pre:write:design-path" run_hook "$P2" "$(W SESS-C /vault/10_설계서.md)"
check "훅 id 로 개별 비활성 → 통과" 0

P3="$(mkproj)" || exit 99
run_hook "$P3" '{"tool_name":"Skill","session_id":"","tool_input":{"skill":"harness-orchestrator"}}'
check "[cx r3 N-1] 빈 session_id Skill → 통과(rc 검사)" 0
count=$((count+1))
if ls "$P3/.claude/".harness-path.* >/dev/null 2>&1; then
  say "FAIL: session_id 없이 도장이 찍혔다"; fail=1
else
  say "PASS: session_id 없으면 도장을 안 찍는다"
fi

# NotebookEdit 경로 필드([cx H-1] 부분 보완).
run_hook "$P2" '{"tool_name":"NotebookEdit","session_id":"SESS-C","tool_input":{"notebook_path":"/vault/10_설계서.ipynb"}}'
check "NotebookEdit(notebook_path)·비설계 확장자 → 통과" 0
run_hook "$P2" '{"tool_name":"NotebookEdit","session_id":"SESS-C","tool_input":{"notebook_path":"/vault/10_설계서_노트.md"}}'
check "NotebookEdit·설계 이름 md → 차단" 2 "$BLOCK"

# ── 마감 ───────────────────────────────────────────────────────────────────
if [ "$count" -ne "$EXPECTED_CASES" ]; then
  say "FAIL: 케이스 수 불일치 — 기대 $EXPECTED_CASES, 실행 $count (케이스 증발)"; fail=1
fi
if [ "$fail" -eq 0 ]; then say "전건 통과 ($count 케이스)"; exit 0; fi
say "실패 있음"; exit 1
