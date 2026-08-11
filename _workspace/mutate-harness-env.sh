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

# **동시 실행 금지.** 이 하네스는 대상 파일을 일시적으로 변형한다. 두 개가 겹쳐 돌거나
# 도는 도중에 누가 `git add -A` 를 하면 **주입된 변이가 그대로 커밋된다** — 실제로 당했다
# (감사 에이전트가 돌리는 중에 커밋해서 `if (BAD) exit 1` 삭제본이 커밋됐다).
# 락 디렉터리는 mkdir 의 원자성을 쓴다. trap 으로 반드시 걷어낸다.
LOCK="$(git rev-parse --git-dir)/mutate-harness-env.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "✗ 이미 다른 변이 측정이 돌고 있습니다: $LOCK" >&2
  echo "  겹쳐 돌리면 주입된 변이가 커밋될 수 있습니다. 끝난 뒤 다시 재세요." >&2
  echo "  (그 프로세스가 죽었다면: rmdir '$LOCK')" >&2
  exit 1
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

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
    # cut -c 를 쓰지 않는다: BSD cut 은 **바이트**로 잘라 한글 중간을 끊고, 그러면 이 로그가
    # 유효한 UTF-8 이 아니게 되어 grep 이 바이너리로 취급하고 **조용히 0건**을 낸다.
    # 계측 도구의 출력을 계측할 수 없게 만드는 위음성이라 절단 자체를 없앤다(실측 적발).
    printf '  ✓ %-50s 적색 %2s건 · %s\n' "$1" "$nfail" \
      "$(printf '%s\n' "$out" | grep '^  ✗' | sed 's/^  ✗ //; s/ —.*//' | tr '\n' '/')"
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

run_mutation '등호 뒤 선행 공백 거부를 지운다' "$COMMON" \
  '  if (substr(v, 1, 1) == " " || substr(v, 1, 1) == "\t") { BAD = 1; return "" }' \
  '  # (변이) 선행 공백 거부 삭제'

run_mutation '인용 없는 값의 후행 공백 절단을 지운다' "$COMMON" \
  '  return rtrim(out)' \
  '  return out'

run_mutation '줄 스캔(히어독+인용 추적) 호출을 지운다' "$COMMON" \
  '  scan_line(line)' \
  '  # (변이) scan_line 호출 삭제'

run_mutation '줄을 넘는 인용 추적을 지운다 (선언 판정 가드)' "$COMMON" \
  '  if (OPENQ == "") {' \
  '  if (1) {'

run_mutation '안 닫힌 인용 거부를 지운다' "$COMMON" \
  '  if (OPENQ != "") exit 1   # 인용이 EOF 까지 안 닫혔다 = 파일을 못 믿는다' \
  '  # (변이) 안 닫힌 인용 거부 삭제'

run_mutation '닫는 따옴표 뒤 공백 요구를 지운다' "$COMMON" \
  '      if (substr(tail, 1, 1) != " " && substr(tail, 1, 1) != "\t") { BAD = 1; return "" }' \
  '      :'

run_mutation '안 닫힌 히어독 거부를 지운다' "$COMMON" \
  '  if (INHD) exit 1' \
  '  # (변이) 안 닫힌 히어독 거부 삭제'

run_mutation '선언 2개 거부를 푼다' "$COMMON" \
  '  if (N > 1) exit 1' \
  '  # (변이) 선언 2개 거부 삭제'

run_mutation '문법 밖(BAD) 거부를 지운다' "$COMMON" \
  '  if (BAD) exit 1' \
  '  # (변이) BAD 거부 삭제'

run_mutation '따옴표 뒤 후행 주석 허용을 잡음 취급한다' "$COMMON" \
  '    if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음' \
  '    if (tail != "") { BAD = 1; return "" }'

run_mutation '인용 없는 값의 후행 주석 절단을 지운다' "$COMMON" \
  '    if (c == "#" && i > 1) {
      p = substr(v, i - 1, 1)
      if (p == " " || p == "\t") break
    }' \
  '    # (변이) 인용 없는 값의 후행 주석 절단 삭제'

run_mutation '히어독 <<- 의 탭 종결어 처리를 지운다' "$COMMON" \
  '    if (HDASH) sub(/^\t+/, "", t)' \
  '    # (변이) <<- 탭 처리 삭제'

run_mutation '종결어의 인용 조각 이어붙이기를 지운다' "$COMMON" \
  '        if (c == "\"" || c == SQ) {
          q2 = c; j++
          while (j <= n && substr(s, j, 1) != q2) { t = t substr(s, j, 1); j++ }
          j++
          continue
        }' \
  '        # (변이) 종결어 인용 조각 처리 삭제'

run_mutation '읽기 실패 경고를 지운다' "$COMMON" \
  "    printf '[하네스] harness.env 를 읽지 못했습니다 — 미설정으로 봅니다: %s\\n' \"\$file\" >&2" \
  '    :'

run_mutation '지식 게이트 기본값을 꺼짐으로 뒤집는다' "$COMMON" \
  '  v="$(harness_env_value HARNESS_KNOWLEDGE_GATE)" || return 0   # 값을 못 믿으면 켠다' \
  '  v="$(harness_env_value HARNESS_KNOWLEDGE_GATE)" || return 1'

run_mutation '지식 게이트를 항상 켜짐으로 못박는다' "$COMMON" \
  '  [ -n "$v" ]                                                   # 리터럴로 비었을 때만 꺼짐' \
  '  return 0'

# (재조준 2026-08-11: 조기 종료가 work_pending() 으로 개편된 뒤 앵커가 죽은 채 방치돼
# 있었다 — main 에서도 빈 변이였다. 술어 본문의 지식 항을 뒤집는 것으로 같은 것을 잰다.)
run_mutation '조기 종료가 게이트 꺼짐을 무시하게 만든다' "$STOP" \
  '  knowledge_gate_active && return 0' \
  '  [ -s "$KNOWLEDGE_FLAG" ] && return 0'

run_mutation 'Stop 훅의 rc 구별을 지운다' "$STOP" \
  'if [ "$typecheck_rc" -eq 3 ]; then
  typecheck_note="타입체크 생략 (HARNESS_TYPECHECK_CMD 미설정)"
elif [ "$typecheck_rc" -ne 0 ]; then
  typecheck_note="타입체크 생략 (harness.env 의 HARNESS_TYPECHECK_CMD 값을 믿을 수 없음 — 선언이 2개 이상이거나, 지원 문법 밖이거나, 읽기 실패입니다. 고칠 수 있는 실수입니다)"
elif [ -z "$TYPECHECK_CMD" ]; then' \
  'if [ -z "$TYPECHECK_CMD" ]; then'

# 가장 강한 변이: 파서를 **회귀가 살아 있던 구판**(원문 grep + 양끝 따옴표만 벗기기)으로
# 되돌린다. "고치기 전이라면 통과했을 입력"임을 실증하는 자리다.
#
# HEAD^ 를 쓰지 않는다 — 커밋을 하나 더 쌓는 순간 앵커가 밀려 "이미 고쳐진 파서"를
# 되돌리게 되고, 그러면 **초록이 나는데 그게 정상인지 결함인지 구별할 수 없다**(실제로 겪었다).
# 그래서 기준선을 고정하고, 가져온 내용이 진짜 구판인지 마커로 확인한 뒤에만 잰다.
BASELINE='daaa745'                 # 회귀 6종이 살아 있던 마지막 커밋
BASELINE_MARK='case "$val" in'     # 구판에만 있는 양끝-따옴표 벗기기
echo
echo "통째 되돌리기 — 고치기 전 파서($BASELINE)라면 무엇이 빨개지나"
total=$((total + 1))
if ! git show "$BASELINE:template/.claude/hooks/_common.sh" 2>/dev/null | grep -qF "$BASELINE_MARK"; then
  echo "  ! 기준선 $BASELINE 에서 구판 마커를 찾지 못했습니다 — 앵커가 밀렸습니다. 측정 무효." >&2
  missed=$((missed + 1))
elif git show "$BASELINE:template/.claude/hooks/_common.sh" > "$COMMON" 2>/dev/null; then
  out="$($TESTS 2>&1)"; rc=$?
  nfail="$(printf '%s\n' "$out" | grep -c '^  ✗')"
  restore_and_verify "$COMMON"
  if [ "$rc" -ne 0 ]; then
    caught=$((caught + 1))
    printf '  ✓ 구판 파서로 되돌린다 — 적색 %s건\n' "$nfail"
    printf '%s\n' "$out" | grep '^  ✗' | sed 's/^  ✗ /      · /; s/ —.*//'
  else
    missed=$((missed + 1))
    echo '  ✗ 구판 파서로 되돌린다 — **초록**. 테스트가 이 커밋의 가치를 안 붙든다'
  fi
else
  restore_and_verify "$COMMON"
  echo "  ! $BASELINE 을 읽지 못했습니다"
  missed=$((missed + 1))
fi

echo
echo "— 변이 ${total}건 중 ${caught}건 적색 / ${missed}건 초록(미방어)"
[ "$missed" -eq 0 ] || exit 1
