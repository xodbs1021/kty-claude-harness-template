#!/usr/bin/env bash
# check-rule-copies.sh — 규칙 정본과 사본이 어긋나면 종료 코드 1.
#
# 왜 사본이 존재하나: 판정자 에이전트는 자기 정의 텍스트가 곧 컨텍스트다.
# "principles.md 참조"만 적어두면 그 파일을 읽는다는 보장이 없으므로, 판정 기준은
# 에이전트 정의 안에 물리적으로 들어 있어야 한다. 그래서 사본을 없애는 대신 감시한다.
#
# 무엇을 감시하나: `rule:core` 마커로 감싼 블록만. 마커 밖의 문맥별 설명은 자유다
# (판정 기준 = 동기화, 설명 = 자유).
#
# 사용법: ./scripts/check-rule-copies.sh
# 사본 추가: COPIES 배열에 파일 경로를 한 줄 추가한다.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

CANON="$ROOT/template/.claude/harness/principles.md"
COPIES=(
  "$ROOT/template/.claude/agents/plan-reviewer.md"
)

MARK_START='rule:core:start'
MARK_END='rule:core:end'

# extract <파일> — 마커 사이 본문만 출력. 여는·닫는 마커가 짝으로 없으면 종료 코드 1.
# index() 부분 일치라서 마커 줄에 설명을 덧붙여도 계속 잡힌다.
extract() {
  awk -v s="$MARK_START" -v e="$MARK_END" '
    index($0, s) { inblock = 1; next }
    index($0, e) { inblock = 0; closed = 1; next }
    inblock      { print }
    END          { exit(closed ? 0 : 1) }
  ' "$1"
}

rel() { echo "${1#"$ROOT"/}"; }

if ! canon="$(extract "$CANON")"; then
  echo "✗ 정본에 rule:core 마커가 없거나 짝이 안 맞음: $(rel "$CANON")" >&2
  exit 1
fi

if [ -z "$canon" ]; then
  echo "✗ 정본의 rule:core 블록이 비어 있음: $(rel "$CANON")" >&2
  exit 1
fi

fail=0
for copy_file in "${COPIES[@]}"; do
  if ! copy="$(extract "$copy_file")"; then
    echo "✗ 사본에 rule:core 마커가 없거나 짝이 안 맞음: $(rel "$copy_file")" >&2
    fail=1
    continue
  fi

  if [ "$copy" != "$canon" ]; then
    echo "✗ 정본과 어긋남: $(rel "$copy_file")" >&2
    diff <(printf '%s\n' "$canon") <(printf '%s\n' "$copy") | sed 's/^/    /' >&2 || true
    fail=1
  fi
done

if [ "$fail" -ne 0 ]; then
  echo "" >&2
  echo "정본 $(rel "$CANON") 의 rule:core 블록을 사본에 그대로 복사하십시오." >&2
  echo "(< 는 정본, > 는 사본)" >&2
  exit 1
fi

echo "✓ 규칙 사본 ${#COPIES[@]}개가 정본과 일치"
