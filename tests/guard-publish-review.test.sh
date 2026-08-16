#!/usr/bin/env bash
# guard-publish-review.sh 동작 검증. 임시 프로젝트를 만들어 훅을 직접 호출한다.
# 계약: rc=0 통과 / rc=2 차단. 케이스는 rc 만이 아니라 **차단 사유 문구**까지 잰다 —
# 우연한 rc=2(픽스처 실패·크래시)가 차단으로 위장하는 "스치는 통과"를 막는다([cx] r1).
# 픽스처 생성 실패는 그 자리에서 exit 99 — 읽기 전용 환경에서 PASS 를 찍지 않는다.
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$HERE/../template/.claude/hooks/guard-publish-review.sh"

fail=0
say() { printf '%s\n' "$*"; }
die() { say "FAIL(픽스처): $*"; exit 99; }

HOOK_ERR=""
run_hook() {  # $1=프로젝트경로 $2=payload → rc 반환, stderr 는 HOOK_ERR 에
  HOOK_ERR="$(printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" ECC_DISABLED_HOOKS="${DISABLE:-}" bash "$HOOK" 2>&1 >/dev/null)"
}

mkproj() {  # 새 임시 프로젝트. stdout = 경로. 실패는 die.
  local d
  d="$(mktemp -d)" || die "mktemp 불가"
  mkdir -p "$d/.claude/harness" "$d/_workspace" || die "mkdir 불가: $d"
  printf '%s\n' "$d"
}
fresh() { printf 'r' > "$1/_workspace/03_codex_review.md" || die "산출물 쓰기 불가"; }
aged()  { fresh "$1"; touch -t 202001010000 "$1/_workspace/03_codex_review.md" || die "touch 불가"; }

check() {  # $1=케이스명 $2=기대rc $3=실제rc [$4=stderr 필수 문구]
  if [ "$2" -ne "$3" ]; then
    say "FAIL: $1 (기대 rc=$2, 실제 rc=$3, stderr: ${HOOK_ERR})"; fail=1; return
  fi
  if [ "$#" -ge 4 ]; then
    case "$HOOK_ERR" in
      *"$4"*) ;;
      *) say "FAIL: $1 (사유 문구 '$4' 부재 — stderr: ${HOOK_ERR})"; fail=1; return ;;
    esac
  fi
  say "PASS: $1"
}

PAYLOAD_JIRA='{"tool_name":"mcp__x__addCommentToJiraIssue","tool_input":{"body":"판정"}}'
PAYLOAD_ART_LIST='{"tool_name":"Artifact","tool_input":{"action":"list"}}'
PAYLOAD_ART_PUB='{"tool_name":"Artifact","tool_input":{"file_path":"/tmp/a.html"}}'

# 1) 탈출구 — 개별 비활성이면 즉시 통과
P="$(mkproj)" || exit 99
DISABLE="pre:publish:review" run_hook "$P" "$PAYLOAD_JIRA"; check "탈출구(ECC_DISABLED_HOOKS)" 0 $?
DISABLE=""

# 2) 리뷰 산출물 0건 → 차단 (사유 = 최근 산출물 부재)
P="$(mkproj)" || exit 99
run_hook "$P" "$PAYLOAD_JIRA"; check "리뷰 산출물 없음 → 차단" 2 $? "최근"

# 3) 신선한 리뷰 산출물 → 통과
P="$(mkproj)" || exit 99; fresh "$P"
run_hook "$P" "$PAYLOAD_JIRA"; check "신선한 codex 산출물 → 통과" 0 $?

# 4) 오래된 리뷰 산출물(2020년) → 차단
P="$(mkproj)" || exit 99; aged "$P"
run_hook "$P" "$PAYLOAD_JIRA"; check "낡은 codex 산출물 → 차단" 2 $? "최근"

# 5) 듀얼리뷰 플래그 미해소면 신선한 산출물이 있어도 차단 — ①이 ②보다 먼저, 사유도 ①의 것
P="$(mkproj)" || exit 99; fresh "$P"
printf 'x\n' > "$P/.claude/.needs-dualreview" || die "플래그 쓰기 불가"
run_hook "$P" "$PAYLOAD_JIRA"; check "플래그 미해소 → 차단(사유=리뷰 앞지르기)" 2 $? "듀얼 리뷰 전"

# 6) Artifact 조회(action:list)는 리뷰 없이도 통과 — 조회는 발행이 아니다
P="$(mkproj)" || exit 99
run_hook "$P" "$PAYLOAD_ART_LIST"; check "Artifact list → 통과" 0 $?

# 7) Artifact 발행(action 없음)은 발행으로 취급 — 리뷰 없으면 차단
P="$(mkproj)" || exit 99
run_hook "$P" "$PAYLOAD_ART_PUB"; check "Artifact 발행 → 차단(리뷰 없음)" 2 $? "최근"

# 8) harness.env 창 확대가 실제로 읽힌다 — 2020년 산출물도 거대 창이면 통과
P="$(mkproj)" || exit 99; aged "$P"
printf 'HARNESS_PUBLISH_REVIEW_WINDOW_MIN="99999999"\n' > "$P/.claude/harness/harness.env" || die "env 쓰기 불가"
run_hook "$P" "$PAYLOAD_JIRA"; check "harness.env 창 override → 통과" 0 $?

# 9) 창 값이 rc=0 인데 비숫자면 기본값 180분 — 낡은 산출물은 여전히 차단
P="$(mkproj)" || exit 99; aged "$P"
printf 'HARNESS_PUBLISH_REVIEW_WINDOW_MIN="abc"\n' > "$P/.claude/harness/harness.env" || die "env 쓰기 불가"
run_hook "$P" "$PAYLOAD_JIRA"; check "비숫자 창 값 → 기본값으로 차단" 2 $? "최근"

# 10) 공백이 든 프로젝트 경로에서도 판정 동일 (#25 검수의 비인용 글로브 fail-open 재발 방지)
B="$(mktemp -d)" || { say "FAIL(픽스처): mktemp 불가"; exit 99; }
P="$B/with space"
mkdir -p "$P/.claude/harness" "$P/_workspace" || die "mkdir 불가"
fresh "$P"
run_hook "$P" "$PAYLOAD_JIRA"; check "공백 경로 + 신선한 산출물 → 통과" 0 $?

# 11) 창 값 중복 선언(rc=1, 판독 불가)은 기본값 완화가 아니라 차단 — [cx] r1 HIGH
P="$(mkproj)" || exit 99; fresh "$P"
printf 'HARNESS_PUBLISH_REVIEW_WINDOW_MIN="5"\nHARNESS_PUBLISH_REVIEW_WINDOW_MIN="180"\n' > "$P/.claude/harness/harness.env" || die "env 쓰기 불가"
run_hook "$P" "$PAYLOAD_JIRA"; check "창 값 중복 선언 → 차단(믿을 수 없음)" 2 $? "믿을 수 없습니다"

# 12) 미래 mtime(2030년) 산출물은 "최근"이 아니다 — 차단 ([cx] r1 MEDIUM)
P="$(mkproj)" || exit 99; fresh "$P"
touch -t 203001010000 "$P/_workspace/03_codex_review.md" || die "touch 불가"
run_hook "$P" "$PAYLOAD_JIRA"; check "미래 mtime → 차단" 2 $? "최근"

# 13) 창 값 "08"(선행 0)이 8진수 산술로 죽지 않는다 — 신선한 산출물이면 통과 ([cx] r1 HIGH)
P="$(mkproj)" || exit 99; fresh "$P"
printf 'HARNESS_PUBLISH_REVIEW_WINDOW_MIN="08"\n' > "$P/.claude/harness/harness.env" || die "env 쓰기 불가"
run_hook "$P" "$PAYLOAD_JIRA"; check "창 값 08 → 크래시 없이 통과" 0 $?

exit "$fail"
