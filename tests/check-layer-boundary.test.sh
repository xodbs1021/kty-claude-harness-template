#!/usr/bin/env bash
# check-layer-boundary.test.sh — 층 경계 검사기의 회귀 테스트.
#
# 이 검사기의 유일한 치명 결함은 **위음성**이다. 누출을 통과시키는 순간 층 경계는
# 다시 산문으로 돌아가고, 산문 규칙은 어겨져도 아무것도 안 깨져서 아무도 모른다.
# 그래서 케이스마다 "그 패턴 **하나만**" 심은 픽스처를 쓴다 — 한 패턴을 목록에서
# 지웠을 때 **그 케이스만** 빨개져야 방어를 지키는 것이다. 다른 케이스가 대신
# 빨개지는 것은 그 방어를 지키는 게 아니다.
#
# 사전 조건(심링크·NUL·빈 범위)도 케이스로 붙든다. "스캔할 수 없는 대상이 트리에
# 있으면 결과 전체를 믿을 수 없다"는 계약이고, 그 계약이 사라지면 검사되지 않은
# 파일이 배포되는 창이 조용히 열린다.
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
# 셸 이식성: macOS 기본 bash 는 3.2 다.
#
# 사용법: ./tests/check-layer-boundary.test.sh

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
CHECKER="$REPO_ROOT/scripts/check-layer-boundary.sh"

[ -f "$CHECKER" ] || { echo "✗ 검사기를 찾지 못했습니다: $CHECKER" >&2; exit 1; }

TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2
  exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'rm -rf "$TMPROOT"' EXIT

ran=0; pass=0; fail=0
OUT=''; RC=999; DID_RUN=0; FIXTURE_FAIL=''

report() {
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}

# new_tree — 깨끗한 배포물 트리(위반 0건)를 만들고 경로를 낸다.
# 정상 문구를 일부러 담는다: 계약 표현("지식 저장소")은 통과해야 하고, 통과하지
# 못하면 이 검사기는 쓸 수가 없다.
new_tree() {
  local d
  d="$(mktemp -d "$TMPROOT/tree.XXXXXX")" || { FIXTURE_FAIL='mktemp 실패'; return 1; }
  mkdir -p "$d/.claude/hooks" "$d/.claude/skills/x" || { FIXTURE_FAIL='골격 실패'; return 1; }
  printf '%s\n' '# 지식 저장소 반영 게이트. 저장소가 어디인지는 사용자 층이 답한다.' \
    > "$d/.claude/hooks/verify.sh"
  printf '%s\n' '완료 게이트 4종을 세운다. .needs-knowledge 는 계약 이름이다.' \
    > "$d/.claude/skills/x/SKILL.md"
  printf '%s\n' 'HARNESS_KNOWLEDGE_GATE="on"' > "$d/.claude/harness.env"
  printf '%s\n' "$d"
}

run_checker() {   # $1 = 스캔 범위
  OUT=''; RC=999; DID_RUN=1
  OUT="$(HARNESS_LAYER_SCAN_ROOT="$1" "$CHECKER" 2>&1)"
  RC=$?
}

# leak_case <이름> <심을 문구> <보고에 나와야 할 조각>
# 깨끗한 트리에 그 문구 **하나만** 심는다.
leak_case() {
  local name="$1" text="$2" token="$3" d why=''
  if ! d="$(new_tree)"; then report "$name" "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
  printf '%s\n' "$text" > "$d/.claude/hooks/leaky.sh"
  run_checker "$d"
  if [ "$DID_RUN" -ne 1 ]; then
    why='검사기를 실행하지 않았다'
  elif [ "$RC" -eq 0 ]; then
    why='누출을 통과시켰다 (rc=0)'
  elif [ "$RC" -ne 1 ]; then
    why="rc=$RC (기대 1) / $(printf '%s' "$OUT" | head -c 200)"
  else
    case "$OUT" in
      *"$token"*) ;;
      *) why="보고에 [$token] 이 없다: $(printf '%s' "$OUT" | head -c 200)" ;;
    esac
    if [ -z "$why" ]; then
      case "$OUT" in
        *'leaky.sh'*) ;;
        *) why="어느 파일인지 보고하지 않았다: $(printf '%s' "$OUT" | head -c 200)" ;;
      esac
    fi
  fi
  report "$name" "$why"
}

# --- 케이스 --------------------------------------------------------------

c01() {
  local d why=''
  if ! d="$(new_tree)"; then report '깨끗한 트리는 통과한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
  run_checker "$d"
  if [ "$RC" -ne 0 ]; then why="rc=$RC (기대 0) / $OUT"; fi
  report '깨끗한 트리는 통과한다 (계약 표현은 위양성이 아니다)' "$why"
}

c02() { leak_case '저장소 이름 — second brain'     'second brain 에 반영한다'       'second'; }
c03() { leak_case '도구 이름 — Obsidian'            'Obsidian 을 연다'               'Obsidian'; }
c04() { leak_case '저장소 이름 — 볼트'               '이 저장소에 반영한다 볼트'      '볼트'; }
c05() { leak_case '상위 층 파일 — _CLAUDE.md'        '_CLAUDE.md 를 전문 읽는다'      '_CLAUDE'; }
c06() { leak_case '상위 층 구조 — 4종 세트'          '4종 세트로 반영한다'            '4종 세트'; }
c07() { leak_case '상위 층 파일 — discussion-log'    'discussion-log 에 적는다'       'discussion-log'; }
c08() { leak_case '상위 층 폴더 — Projects/<name>'   'Projects/<name>/ 아래에 둔다'   'Projects'; }
c09() { leak_case '구현체 이름 플래그 — needs-vault' 'rm -f .claude/.needs-vault'     'needs-vault'; }

# 첫 건에서 멈추면 한 번 고칠 때마다 다시 돌려야 하고, 남은 누출이 몇 개인지 모른다.
c10() {
  local d why=''
  if ! d="$(new_tree)"; then report '위반이 여러 파일이면 전부 보고한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
  printf '%s\n' '볼트에 반영' > "$d/.claude/hooks/a.sh"
  printf '%s\n' '_CLAUDE.md 읽기' > "$d/.claude/hooks/b.sh"
  run_checker "$d"
  if [ "$RC" -ne 1 ]; then
    why="rc=$RC (기대 1)"
  else
    case "$OUT" in *'a.sh'*) ;; *) why='a.sh 를 보고하지 않았다' ;; esac
    if [ -z "$why" ]; then
      case "$OUT" in *'b.sh'*) ;; *) why='b.sh 를 보고하지 않았다 (첫 건에서 멈췄다)' ;; esac
    fi
  fi
  report '위반이 여러 파일이면 전부 보고한다' "$why"
}

# 사전 조건 — 스캔할 수 없는 대상이 있으면 결과 전체를 믿을 수 없다.
c11() {
  local d why=''
  if ! d="$(new_tree)"; then report '심링크가 있으면 거부한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
  if ! ln -s "$d/.claude/hooks/verify.sh" "$d/.claude/hooks/link.sh" 2>/dev/null; then
    report '심링크가 있으면 거부한다' '픽스처 실패: ln -s'; return 0
  fi
  run_checker "$d"
  if [ "$RC" -eq 0 ]; then why='심링크가 있는데 통과시켰다'
  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
  else
    case "$OUT" in *'심링크'*) ;; *) why="사유가 심링크가 아니다: $(printf '%s' "$OUT" | head -c 160)" ;; esac
  fi
  report '심링크가 있으면 거부한다' "$why"
}

c12() {
  local d why=''
  if ! d="$(new_tree)"; then report 'NUL 보유 파일이 있으면 거부한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
  printf 'A\000B\n' > "$d/.claude/hooks/nul.sh"
  run_checker "$d"
  if [ "$RC" -eq 0 ]; then why='NUL 파일이 있는데 통과시켰다'
  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
  else
    case "$OUT" in *'NUL'*) ;; *) why="사유가 NUL 이 아니다: $(printf '%s' "$OUT" | head -c 160)" ;; esac
  fi
  report 'NUL 보유 파일이 있으면 거부한다' "$why"
}

# 빈 목록 = 공허한 초록. 0개를 스캔하고 "위반 0건"을 찍으면 아무것도 증명하지 않는다.
c13() {
  local d why=''
  if ! d="$(mktemp -d "$TMPROOT/empty.XXXXXX")"; then
    report '스캔 대상이 0개면 거부한다' '픽스처 실패'; return 0
  fi
  run_checker "$d"
  if [ "$RC" -eq 0 ]; then why='파일이 하나도 없는데 초록불을 냈다'
  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
  fi
  report '스캔 대상이 0개면 거부한다 (공허한 초록 방지)' "$why"
}

c14() {
  local why=''
  run_checker "$TMPROOT/그런디렉토리없음"
  if [ "$RC" -eq 0 ]; then why='없는 범위인데 통과시켰다'; fi
  report '스캔 범위가 없으면 거부한다' "$why"
}

# --- 러너 ----------------------------------------------------------------

CASES='c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12 c13 c14'
EXPECTED_CASES=14

case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
  exit 1
fi

echo "층 경계 검사기 — 누출 적발 + 사전 조건"
for c in $CASES; do
  ran=$((ran + 1)); DID_RUN=0; FIXTURE_FAIL=''
  "$c"
done

if [ "$ran" -ne "$EXPECTED_CASES" ]; then
  echo "✗ 실행 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건" >&2; exit 1
fi
if [ $((pass + fail)) -ne "$ran" ]; then
  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1
fi

echo "— ${pass}/${ran} 통과"
[ "$fail" -eq 0 ] || exit 1
