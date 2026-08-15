#!/usr/bin/env bash
# rule:core 판정 블록의 정본(principles.md)과 사본이 어긋나지 않는지 대조한다.
# 일치 = exit 0 / 불일치·마커 누락 = exit 1 (어긋난 부분을 diff로 출력)
set -euo pipefail
cd "$(dirname "$0")/../.."

CANON=".claude/harness/principles.md"
COPIES=(".claude/agents/plan-reviewer.md")

extract() { sed -n '/<!-- rule:core:start -->/,/<!-- rule:core:end -->/p' "$1"; }

# 마커 무결성: 시작·종료 각 정확히 1개, 시작이 종료보다 앞 — 아니면 추출 자체를 믿을 수 없다
check_markers() {
  local f="$1" s_cnt e_cnt s_line e_line
  s_cnt=$(grep -cF '<!-- rule:core:start -->' "$f" || true)
  e_cnt=$(grep -cF '<!-- rule:core:end -->' "$f" || true)
  if [ "$s_cnt" -ne 1 ] || [ "$e_cnt" -ne 1 ]; then
    echo "[오류] $f: rule:core 마커는 시작·종료 각 1개여야 한다 (start=$s_cnt, end=$e_cnt)." >&2
    return 1
  fi
  s_line=$(grep -nF '<!-- rule:core:start -->' "$f" | cut -d: -f1)
  e_line=$(grep -nF '<!-- rule:core:end -->' "$f" | cut -d: -f1)
  if [ "$s_line" -ge "$e_line" ]; then
    echo "[오류] $f: 시작 마커(${s_line}행)가 종료 마커(${e_line}행)보다 뒤에 있다." >&2
    return 1
  fi
}

check_markers "$CANON" || exit 1
canon_block="$(extract "$CANON")"

status=0
for copy in "${COPIES[@]}"; do
  if ! check_markers "$copy"; then
    status=1
    continue
  fi
  copy_block="$(extract "$copy")"
  if ! diff <(printf '%s\n' "$canon_block") <(printf '%s\n' "$copy_block"); then
    echo "[불일치] $copy 가 정본($CANON)의 rule:core 블록과 다르다. (위 diff: < 정본 / > 사본)" >&2
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  echo "rule:core 사본 일치 — 정본: $CANON, 사본 ${#COPIES[@]}개"
fi
exit "$status"
