#!/usr/bin/env bash
# rule:core 판정 블록의 정본(principles.md)과 사본이 어긋나지 않는지 대조한다.
# 일치 = exit 0 / 불일치·마커 누락 = exit 1 (어긋난 부분을 diff로 출력)
#
# 층 구분: 이것은 **설치본(프로젝트)용** 검사기다 — Stop 게이트 3.1b(rulecopy)가 매 턴
# 실행한다. 템플릿 repo 소스 레벨에는 별도의 강화 검사기(repo 루트 scripts/ + CI)가
# 있다 — 소스는 CI가, 설치본은 Stop 게이트가 지킨다.
set -euo pipefail
cd "$(dirname "$0")/../.."

CANON=".claude/harness/principles.md"
COPIES=(".claude/agents/plan-reviewer.md")

# 마커 문자열은 조립한다 — 소스 레벨 스캐너가 template/ 하위에서 이 토큰의 연속
# 바이트열을 가진 파일을 "미등록 사본"으로 잡는다. 이 파일은 사본이 아니라 검사기이므로
# 자신이 그 바이트열을 담지 않아야 한다(루트 검사기의 MARK_TOKEN 조립과 같은 기법).
MS='<!-- rule:core'':start -->'
ME='<!-- rule:core'':end -->'

extract() { sed -n "/$MS/,/$ME/p" "$1"; }

# 마커 무결성: 시작·종료 각 정확히 1개, 시작이 종료보다 앞 — 아니면 추출 자체를 믿을 수 없다
check_markers() {
  local f="$1" s_cnt e_cnt s_line e_line
  s_cnt=$(grep -cF "$MS" "$f" || true)
  e_cnt=$(grep -cF "$ME" "$f" || true)
  if [ "$s_cnt" -ne 1 ] || [ "$e_cnt" -ne 1 ]; then
    echo "[오류] $f: rule:core 마커는 시작·종료 각 1개여야 한다 (start=$s_cnt, end=$e_cnt)." >&2
    return 1
  fi
  s_line=$(grep -nF "$MS" "$f" | cut -d: -f1)
  e_line=$(grep -nF "$ME" "$f" | cut -d: -f1)
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
