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

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# extract <파일> <출력파일> — 마커 사이 본문을 파일로 뽑는다.
# 마커가 **정확히 한 쌍**이 아니면 종료 코드 1.
#
# 왜 개수를 세나 (codex 리뷰 지적): "닫힌 적이 있으면 통과"로 두면, 사본에 블록을 두 개
# 두고 사이에 다른 내용을 끼웠을 때 두 블록만 이어붙여 비교하고 중간을 무시한 채
# 통과한다. 어긋난 사본을 통과시키는 위음성이라 이 검사기의 존재 이유가 사라진다.
#
# 왜 변수가 아니라 파일에 담나 (codex 리뷰 지적): 명령 치환 `$(...)`은 후행 개행을 전부
# 먹는다. 사본 끝에 빈 줄을 넣으면 내용이 다른데도 같다고 판정된다. 파일로 받아
# cmp 로 바이트 단위 비교한다.
#
# index() 부분 일치라서 마커 줄에 설명을 덧붙여도 계속 잡힌다.
extract() {
  awk -v s="$MARK_START" -v e="$MARK_END" '
    index($0, s) { starts++; inblock = 1; next }
    index($0, e) { ends++;   inblock = 0; next }
    inblock      { print }
    END          { exit((starts == 1 && ends == 1) ? 0 : 1) }
  ' "$1" > "$2"
}

rel() { echo "${1#"$ROOT"/}"; }

canon_f="$WORK/canon"
if ! extract "$CANON" "$canon_f"; then
  echo "✗ 정본의 rule:core 마커가 없거나 정확히 한 쌍이 아님: $(rel "$CANON")" >&2
  exit 1
fi

if [ ! -s "$canon_f" ]; then
  echo "✗ 정본의 rule:core 블록이 비어 있음: $(rel "$CANON")" >&2
  exit 1
fi

fail=0
i=0
for copy_file in "${COPIES[@]}"; do
  i=$((i + 1))
  copy_f="$WORK/copy.$i"
  if ! extract "$copy_file" "$copy_f"; then
    echo "✗ 사본의 rule:core 마커가 없거나 정확히 한 쌍이 아님: $(rel "$copy_file")" >&2
    fail=1
    continue
  fi

  if ! cmp -s "$canon_f" "$copy_f"; then
    echo "✗ 정본과 어긋남: $(rel "$copy_file")" >&2
    diff "$canon_f" "$copy_f" | sed 's/^/    /' >&2 || true
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
