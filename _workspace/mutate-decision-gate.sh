#!/usr/bin/env bash
# 변이 주입 하네스 — tests/decision-gate.test.sh 가 **실제로 무엇을 붙드는지** 잰다.
#
# "44건 통과"는 아무것도 증명하지 않는다. 방어를 하나씩 지우고 그 케이스가 빨개지는지
# 봐야 한다. 형제 하네스(mutate-harness-env.sh)와 같은 계약을 쓴다:
#   · 대상 파일에 미커밋 변경이 있으면 **거부**한다 (restore 가 그것을 지운다)
#   · 동시 실행을 락으로 막는다 (돌리는 중 커밋하면 변이가 커밋된다 — 실제로 당했다)
#   · 치환이 **정확히 1회** 매치할 때만 진행한다 (앵커가 밀리면 빈 변이 = 거짓 초록)
#   · 복원 뒤 **해시를 대조**한다 (git status 는 stat 캐시 때문에 못 믿는다)
#
# 이 게이트는 위양성도 치명적이라 **양방향으로** 잰다:
#   A·C·D 방어를 지우면 → 막아야 할 것을 놓친다 (위음성 검출)
#   B    좁히는 장치를 지우면 → 막으면 안 될 것을 막는다 (위양성 검출)
#
# CI 에 넣지 않는다. 검수·감사 때 손으로 돌리는 계측 도구다.
# 사용법: ./_workspace/mutate-decision-gate.sh

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

COMMON='template/.claude/hooks/_common.sh'
STOP='template/.claude/hooks/verify-before-stop.sh'
TESTS='./tests/decision-gate.test.sh'

for f in "$COMMON" "$STOP"; do
  if ! git diff --quiet -- "$f" || ! git diff --cached --quiet -- "$f"; then
    echo "✗ $f 에 미커밋 변경이 있습니다." >&2
    echo "  이 하네스는 HEAD 로 restore 하므로 그 변경을 **지웁니다**. 먼저 커밋한 뒤 다시 재세요." >&2
    exit 1
  fi
done

LOCK="$(git rev-parse --git-dir)/mutate-decision-gate.lock"
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

measure() {   # $1=이름 $2=파일 — 변이가 주입된 상태에서 재고 복원한다
  local out rc nfail
  out="$($TESTS 2>&1)"; rc=$?
  nfail="$(printf '%s\n' "$out" | grep -c '^  ✗')"
  restore_and_verify "$2"
  if [ "$rc" -ne 0 ] && [ "$nfail" -gt 0 ]; then
    caught=$((caught + 1))
    # cut -c 를 쓰지 않는다: BSD cut 은 **바이트**로 잘라 한글 중간을 끊고, 그러면 이 로그가
    # 유효한 UTF-8 이 아니게 되어 grep 이 바이너리로 취급하고 조용히 0건을 낸다(실측 적발).
    printf '  ✓ %-44s 적색 %2s건 · %s\n' "$1" "$nfail" \
      "$(printf '%s\n' "$out" | grep '^  ✗' | sed 's/^  ✗ //; s/ —.*//' | tr '\n' '/')"
  else
    missed=$((missed + 1))
    printf '  ✗ %-44s **초록** — 이 방어를 지켜주는 케이스가 없다\n' "$1"
  fi
}

run_mutation() {   # $1=이름 $2=파일 $3=찾을것 $4=바꿀것
  total=$((total + 1))
  if ! mutate "$2" "$3" "$4"; then
    printf '  ! %-44s 변이 주입 실패 (앵커 불일치)\n' "$1"
    restore_and_verify "$2"
    missed=$((missed + 1))
    return
  fi
  measure "$1" "$2"
}

echo '기준선 (변이 없음)'
if ! $TESTS >/dev/null 2>&1; then
  echo '✗ 기준선이 이미 빨간불입니다. 변이 측정 이전에 고쳐야 합니다.' >&2
  $TESTS 2>&1 | grep '^  ✗'
  exit 1
fi
echo '  ✓ 전건 초록'
echo
echo '── A. 판정의 핵심을 지운다 (지우면 위음성 = 자백이 통과한다) ────────'

run_mutation '게이트 자체를 무력화한다' "$STOP" \
  '  decision_hits="$(decision_scan "$transcript_path")"; decision_rc=$?' \
  '  decision_hits=""; decision_rc=1'

run_mutation '질문 0회 조건을 지운다 (질문해도 안 풀린다)' "$COMMON" \
  'if asked > 0:
    raise SystemExit(1)' \
  '# (변이) 질문 판정 삭제'

run_mutation '표지 판정을 지운다 (아무 문장이나 걸린다)' "$COMMON" \
  '            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):' \
  '            if not core:'

run_mutation '걸린 문장을 메시지에 안 싣는다' "$STOP" \
  "      printf '%s\\n' \"\$decision_hits\" | sed 's/^/  - /'" \
  '      :'

run_mutation '예산 호출을 지운다 (영원히 막힌다)' "$STOP" \
  '    gate_budget "decision"' \
  '    # (변이) gate_budget 호출 삭제'

run_mutation '탈출구 판정을 지운다 (꺼도 안 꺼진다)' "$STOP" \
  'if ! hook_disabled "stop:decision"; then' \
  'if true; then'

echo
echo '── B. 좁히는 장치를 지운다 (지우면 위양성 = 정상 발화가 막힌다) ─────'

run_mutation '인라인 코드 제외를 지운다' "$COMMON" \
  '        line = QUOTED.sub(" ", INLINE.sub(" ", line))' \
  '        line = QUOTED.sub(" ", line)'

run_mutation '따옴표 인용 제외를 지운다' "$COMMON" \
  '        line = QUOTED.sub(" ", INLINE.sub(" ", line))' \
  '        line = INLINE.sub(" ", line)'

run_mutation '인용줄 제외를 지운다' "$COMMON" \
  '        if BLOCKQUOTE.match(line):
            continue' \
  '        pass'

run_mutation '코드펜스 제외를 지운다' "$COMMON" \
  '    return "\n".join(p for i, p in enumerate(s.split("```")) if i % 2 == 0)' \
  '    return s'

run_mutation '질문 신호 제외를 지운다' "$COMMON" \
  '            if QUESTION.search(whole):
                continue' \
  '            pass'

run_mutation '서술형 종결 요구를 지운다' "$COMMON" \
  '            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):' \
  '            if not core or not MARKER.search(core):'

run_mutation 'thinking 블록까지 스캔한다' "$COMMON" \
  '        elif b.get("type") == "text":
            t = b.get("text")
            if isinstance(t, str):
                texts.append(t)' \
  '        elif b.get("type") in ("text", "thinking"):
            t = b.get("text") or b.get("thinking")
            if isinstance(t, str):
                texts.append(t)'

run_mutation '서브에이전트 발화까지 스캔한다' "$COMMON" \
  '    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):' \
  '    if not isinstance(e, dict) or e.get("type") != "assistant":'

# 자기참조 폭발을 막는 핵심 장치다 — 이게 없으면 이 패턴이 적힌 파일을 쓰는 것만으로 막힌다.
run_mutation '도구 입력까지 스캔한다 (자기참조 폭발)' "$COMMON" \
  '        if b.get("type") == "tool_use":
            if b.get("name") == "AskUserQuestion":
                asked += 1' \
  '        if b.get("type") == "tool_use":
            if b.get("name") == "AskUserQuestion":
                asked += 1
            else:
                for _v in (b.get("input") or {}).values():
                    if isinstance(_v, str):
                        texts.append(_v)'

echo
echo '── C. 턴 경계를 흐린다 ─────────────────────────────────────────────'

run_mutation '마지막이 아니라 첫 프롬프트를 경계로 삼는다' "$COMMON" \
  '    if isinstance(e, dict) and is_user_prompt(e):
        start = i' \
  '    if isinstance(e, dict) and is_user_prompt(e) and start < 0:
        start = i'

# 두 판정을 **따로** 잰다. 실제 기록은 두 표식을 함께 갖고 있어서 한쪽만 지우면 다른 쪽이
# 가려 준다 — 표식이 하나뿐인 픽스처(d25d·d25e)가 있어야 각각이 일하는지 보인다.
run_mutation '상단 toolUseResult 판정을 지운다' "$COMMON" \
  '    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
        return False' \
  '    pass'

run_mutation 'tool_result 블록 판정을 지운다' "$COMMON" \
  '    content = msg.get("content")
    if isinstance(content, list):
        for b in content:
            if isinstance(b, dict) and b.get("type") == "tool_result":
                return False
    return True' \
  '    return True'

echo
echo '── D. fail-open 이 조용해지게 만든다 ───────────────────────────────'
# 판독 불가를 **통과시키는 것 자체는 설계**다. 문제는 그때 소리를 안 내는 것 —
# 그러면 게이트가 죽은 것을 아무도 모르고, 그게 이 저장소가 부르는 조용한 실패다.

run_mutation '판독 불가를 통과로 위장한다 (사유 소실)' "$COMMON" \
  'def fail(reason):
    sys.stdout.write(reason + "\n")
    raise SystemExit(2)' \
  'def fail(reason):
    raise SystemExit(1)'

run_mutation '판독 불가 사유를 안 실어 보낸다' "$STOP" \
  '    decision_note="결정 게이트 생략 ($decision_hits)"' \
  '    decision_note=""'

run_mutation '판독 불가 사유를 안 출력한다' "$STOP" \
  '  if [ -n "$decision_note" ]; then
    echo
    echo "참고: $decision_note"
    echo "      → 이 턴에 사용자에게 물었어야 할 결정이 없었는지 스스로 확인하세요."
  fi' \
  '  :'

run_mutation '기록을 못 읽어도 조용히 넘어간다' "$COMMON" \
  "  [ -r \"\$path\" ] || { printf '%s\\n' \"대화 기록을 읽을 수 없습니다: \$path\"; return 2; }" \
  '  [ -r "$path" ] || return 1'

run_mutation '턴 시작점을 못 찾으면 전체를 훑는다' "$COMMON" \
  '    fail("이 턴의 시작점(사용자 프롬프트)을 찾지 못했습니다 (형식이 바뀌었을 수 있습니다)")' \
  '    start = -1'

echo
echo '── E. 순서 계약 — 게이트를 뒤로 옮긴다 ─────────────────────────────'
# 지우는 것과 옮기는 것은 다른 측정이다. 지우면 "게이트 없음"을 재고, 옮겨야
# "순서가 틀림"을 잰다. 질문의 답이 코드를 바꿀 수 있으므로 앞이어야 한다.
total=$((total + 1))
if python3 - "$STOP" <<'PY'
import io, sys
path = sys.argv[1]
s = io.open(path, encoding='utf-8').read()
head, mid, after = '# (3.2) **결정 게이트**', '# (3.5) 듀얼 리뷰', '# (6) 타입체크는 통과했지만'
for tok in (head, mid, after):
    if s.count(tok) != 1:
        sys.stderr.write('  ! 이동 앵커 매치 수 이상: %r=%d\n' % (tok, s.count(tok)))
        sys.exit(1)
start, end = s.index(head), s.index(mid)
block = s[start:end]
s = s[:start] + s[end:]
io.open(path, 'w', encoding='utf-8').write(s.replace(after, block + after))
PY
then
  measure '게이트를 감사 직전으로 옮긴다' "$STOP"
else
  printf '  ! %-44s 변이 주입 실패 (앵커 불일치)\n' '게이트를 감사 직전으로 옮긴다'
  restore_and_verify "$STOP"
  missed=$((missed + 1))
fi

echo
echo "— 변이 ${total}건 중 ${caught}건 적색 / ${missed}건 초록(미방어)"
[ "$missed" -eq 0 ] || exit 1
