#!/usr/bin/env bash
# 변이 주입 하네스 — tests/harness-env-read.test.sh 가 **실제로 무엇을 붙드는지** 잰다.
#
# "57건 통과"는 아무것도 증명하지 않는다. 방어를 하나씩 지우고 그 케이스가 빨개지는지
# 봐야 한다. 그리고 변이 주입 자신에게도 위음성이 있다 — 복원이 조용히 실패하면 이전
# 변이가 남은 채 다음 측정이 전부 거짓이 된다. 그래서 매 복원 뒤 **해시를 대조**한다
# (git status 는 stat 캐시 때문에 못 믿는다).
#
# CI 에 넣지 않는다. 검수·감사 때 손으로 돌리는 계측 도구다.
# 사용법: ./_workspace/mutate-harness-env.sh

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

COMMON='template/.claude/hooks/_common.sh'
STOP='template/.claude/hooks/verify-before-stop.sh'
TESTS='./tests/harness-env-read.test.sh'

# 이 하네스는 HEAD 를 정본으로 삼아 restore 한다. 그래서 **대상 파일에 미커밋 변경이
# 있으면 그것을 지워버린다** — 실제로 한 번 당했다(측정하려다 방금 쓴 수정을 날렸다).
# staged·워킹트리 양쪽을 다 본다. "먼저 커밋하고 재라"가 계약이다.
for f in "$COMMON" "$STOP"; do
  if ! git diff --quiet -- "$f" || ! git diff --cached --quiet -- "$f"; then
    echo "✗ $f 에 미커밋 변경이 있습니다." >&2
    echo "  이 하네스는 HEAD 로 restore 하므로 그 변경을 **지웁니다**. 먼저 커밋한 뒤 다시 재세요." >&2
    exit 1
  fi
done

restore_and_verify() {   # $1 = 파일
  git restore --source=HEAD --worktree -- "$1" || { echo "✗ restore 실패: $1" >&2; exit 1; }
  local have want
  have="$(git hash-object "$1")"
  want="$(git rev-parse "HEAD:$1")"
  if [ "$have" != "$want" ]; then
    echo "✗ 복원 검증 실패: $1 ($have ≠ $want) — 이후 측정은 전부 거짓입니다" >&2
    exit 1
  fi
}

# mutate <파일> <찾을 문자열> <바꿀 문자열> — 정확히 1번 매치할 때만 바꾼다.
# 앵커가 안 맞으면 **빈 변이**가 되어 "테스트가 잡았다"는 거짓 초록이 난다.
mutate() {
  python3 - "$1" "$2" "$3" <<'PY'
import sys, io
path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
s = io.open(path, encoding='utf-8').read()
if s.count(old) != 1:
    sys.stderr.write("  ! 변이 앵커가 %d 번 매치 (1 이어야 함): %r\n" % (s.count(old), old[:70]))
    sys.exit(1)
io.open(path, 'w', encoding='utf-8').write(s.replace(old, new))
PY
}

total=0; caught=0; missed=0

run_mutation() {   # $1=이름 $2=파일 $3=찾을것 $4=바꿀것
  total=$((total + 1))
  if ! mutate "$2" "$3" "$4"; then
    printf '  ! %-50s 변이 주입 실패 (앵커 불일치)\n' "$1"
    restore_and_verify "$2"
    missed=$((missed + 1))
    return
  fi
  local out rc nfail
  out="$($TESTS 2>&1)"; rc=$?
  nfail="$(printf '%s\n' "$out" | grep -c '^  ✗')"
  restore_and_verify "$2"
  if [ "$rc" -ne 0 ] && [ "$nfail" -gt 0 ]; then
    caught=$((caught + 1))
    printf '  ✓ %-50s 적색 %2s건 · %s\n' "$1" "$nfail" \
      "$(printf '%s\n' "$out" | grep '^  ✗' | sed 's/^  ✗ //; s/ —.*//' | tr '\n' '/' | cut -c1-80)"
  else
    missed=$((missed + 1))
    printf '  ✗ %-50s **초록** — 이 방어를 지켜주는 케이스가 없다\n' "$1"
  fi
}

echo '기준선 (변이 없음)'
if ! $TESTS >/dev/null 2>&1; then
  echo '✗ 기준선이 이미 빨간불입니다. 변이 측정 이전에 고쳐야 합니다.' >&2
  $TESTS 2>&1 | grep '^  ✗'
  exit 1
fi
echo '  ✓ 전건 초록'
echo
echo '변이 주입 — 방어를 하나씩 지운다'

run_mutation 'BOM 제거를 지운다' "$COMMON" \
  '  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)' \
  '  # (변이) BOM 제거 삭제'

run_mutation 'CR 제거를 지운다' "$COMMON" \
  '  sub(/\r$/, "", line)' \
  '  # (변이) CR 제거 삭제'

run_mutation '값 앞 공백 절단을 지운다' "$COMMON" \
  '  v = ltrim(v)' \
  '  # (변이) 값 앞 공백 절단 삭제'

run_mutation '인용 없는 값의 후행 공백 절단을 지운다' "$COMMON" \
  '  return rtrim(out)' \
  '  return out'

run_mutation '히어독 탐지 호출을 지운다' "$COMMON" \
  '  scan_heredoc(line)' \
  '  # (변이) scan_heredoc 호출 삭제'

run_mutation '안 닫힌 히어독 거부를 지운다' "$COMMON" \
  '  if (INHD) exit 1' \
  '  # (변이) 안 닫힌 히어독 거부 삭제'

run_mutation '선언 2개 거부를 푼다' "$COMMON" \
  '  if (N != 1) exit 1' \
  '  if (N < 1) exit 1'

run_mutation '문법 밖(BAD) 거부를 지운다' "$COMMON" \
  '  if (BAD) exit 1' \
  '  # (변이) BAD 거부 삭제'

run_mutation '따옴표 뒤 후행 주석 허용을 잡음 취급한다' "$COMMON" \
  '    if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음' \
  '    if (tail != "") { BAD = 1; return "" }'

run_mutation '인용 없는 값의 후행 주석 절단을 지운다' "$COMMON" \
  '    if (c == "#") {
      p = substr(v, i - 1, 1)
      if (p == " " || p == "\t") break
    }' \
  '    # (변이) 인용 없는 값의 후행 주석 절단 삭제'

run_mutation '히어독 <<- 의 탭 종결어 처리를 지운다' "$COMMON" \
  '    if (HDASH) sub(/^\t+/, "", t)' \
  '    # (변이) <<- 탭 처리 삭제'

run_mutation '히어독 탐지의 따옴표 상태 추적을 지운다' "$COMMON" \
  '    if (q != "") { if (c == q) q = ""; i++; continue }
    if (c == "\"" || c == SQ) { q = c; i++; continue }' \
  '    # (변이) 따옴표 상태 추적 삭제'

run_mutation '읽기 실패 경고를 지운다' "$COMMON" \
  "    printf '[하네스] harness.env 를 읽지 못했습니다 — 미설정으로 봅니다: %s\\n' \"\$file\" >&2" \
  '    :'

run_mutation 'Stop 훅의 rc 구별을 지운다' "$STOP" \
  'if [ "$typecheck_rc" -ne 0 ]; then
  typecheck_note="타입체크 생략 (harness.env 의 HARNESS_TYPECHECK_CMD 를 읽지 못함 — 미설정이거나, 선언이 2개 이상이거나, 지원 문법 밖입니다)"
elif [ -z "$TYPECHECK_CMD" ]; then
  typecheck_note="타입체크 생략 (HARNESS_TYPECHECK_CMD 가 빈 값으로 설정됨)"' \
  'if [ -z "$TYPECHECK_CMD" ]; then
  typecheck_note="타입체크 생략 (미설정)"'

# 가장 강한 변이: 파서를 이 커밋 **이전**(원문 grep + 양끝 따옴표만 벗기기)으로 되돌린다.
# "고치기 전이라면 통과했을 입력"임을 실증하는 자리다.
echo
echo '통째 되돌리기 — 고치기 전 파서라면 무엇이 빨개지나'
total=$((total + 1))
if git show 'HEAD^:template/.claude/hooks/_common.sh' > "$COMMON" 2>/dev/null; then
  out="$($TESTS 2>&1)"; rc=$?
  nfail="$(printf '%s\n' "$out" | grep -c '^  ✗')"
  restore_and_verify "$COMMON"
  if [ "$rc" -ne 0 ]; then
    caught=$((caught + 1))
    printf '  ✓ HEAD^ 의 파서로 되돌린다 — 적색 %s건\n' "$nfail"
    printf '%s\n' "$out" | grep '^  ✗' | sed 's/^  ✗ /      · /; s/ —.*//'
  else
    missed=$((missed + 1))
    echo '  ✗ HEAD^ 의 파서로 되돌린다 — **초록**. 테스트가 이 커밋의 가치를 안 붙든다'
  fi
else
  restore_and_verify "$COMMON"
  echo '  ! HEAD^ 를 읽지 못했습니다'
  missed=$((missed + 1))
fi

echo
echo "— 변이 ${total}건 중 ${caught}건 적색 / ${missed}건 초록(미방어)"
[ "$missed" -eq 0 ] || exit 1
