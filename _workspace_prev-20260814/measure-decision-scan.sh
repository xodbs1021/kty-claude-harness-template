#!/usr/bin/env bash
# 결정 게이트의 **비용과 위양성률**을 실기록으로 잰다.
#
# ADR-0012 가 공시한 수치(기록 크기 분포 · 스캔 시간/RSS · 실기록 발동 건수)의 재현
# 산출물이다. 저자 로컬 관측만 있고 재현 수단이 없으면 다음 검수가 그 숫자를 확인할 수
# 없다 — 특히 RSS 는 **전 프로젝트 매 턴에 걸리는 배포 영향**이라 근거가 남을 값을 한다.
#
# 읽기 전용이다. 대화 기록을 읽기만 하고 아무것도 쓰지 않는다.
# CI 에 넣지 않는다(기록은 사람마다 다르다). 검수·감사 때 손으로 돌린다.
#
# 사용법: ./_workspace/measure-decision-scan.sh [기록 디렉터리]
#         기본값 ~/.claude/projects

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
ROOT="${1:-$HOME/.claude/projects}"
COMMON='template/.claude/hooks/_common.sh'

[ -d "$ROOT" ] || { echo "✗ 기록 디렉터리가 없습니다: $ROOT" >&2; exit 1; }
[ -f "$COMMON" ] || { echo "✗ $COMMON 을 찾지 못했습니다" >&2; exit 1; }

# 측정 대상이 변이 상태면 숫자가 통째로 거짓이 된다 — 실제로 당한 사고다.
if ! git diff --quiet -- "$COMMON" || ! git diff --cached --quiet -- "$COMMON"; then
  echo "✗ $COMMON 에 미커밋 변경이 있습니다 — 변이 측정 중일 수 있습니다." >&2
  echo "  그 상태로 재면 숫자가 거짓이 됩니다. 커밋하거나 복원한 뒤 다시 재세요." >&2
  exit 1
fi

echo "== 1. 기록 크기 분포 =="
python3 - "$ROOT" <<'PY'
import glob, os, sys, statistics
fs = glob.glob(os.path.join(sys.argv[1], "*", "*.jsonl"))
if not fs:
    print("  (기록 없음)"); raise SystemExit(0)
sz = sorted(os.path.getsize(f) for f in fs)
mb = lambda b: b / 1024 / 1024
print("  기록 %d개 · 중앙값 %.1f MB · p90 %.1f MB · 최대 %.1f MB"
      % (len(sz), mb(statistics.median(sz)), mb(sz[int(len(sz) * 0.9)]), mb(sz[-1])))
PY

echo
echo "== 2. 스캔 비용 (가장 큰 기록 3개) =="
# /usr/bin/time -l 은 BSD 전용이다. 없으면 시간만 잰다 — 조용히 건너뛰지 않는다.
have_time_l=0
/usr/bin/time -l true >/dev/null 2>&1 && have_time_l=1
[ "$have_time_l" -eq 1 ] || echo "  (주의: /usr/bin/time -l 이 없어 RSS 는 못 잽니다 — 시간만)"
# shellcheck disable=SC2012
ls -S "$ROOT"/*/*.jsonl 2>/dev/null | head -3 | while IFS= read -r f; do
  mb="$(python3 -c 'import os,sys;print("%.1f"%(os.path.getsize(sys.argv[1])/1048576))' "$f")"
  if [ "$have_time_l" -eq 1 ]; then
    out="$(/usr/bin/time -l bash -c ". $COMMON; decision_scan '$f' >/dev/null" 2>&1)"
    real="$(printf '%s' "$out" | awk '/real/{print $1}')"
    rss="$(printf '%s' "$out" | awk '/maximum resident/{printf "%.0f", $1/1048576}')"
    printf '  %6s MB → %ss · RSS %s MB\n' "$mb" "$real" "$rss"
  else
    s="$(date +%s)"; bash -c ". $COMMON; decision_scan '$f' >/dev/null"; e="$(date +%s)"
    printf '  %6s MB → 약 %s초\n' "$mb" "$((e - s))"
  fi
done

echo
echo "== 3. 실기록 발동률 (위양성 관측) =="
echo "   rc=0 차단 · rc=2 판독불가 · rc=3 통과"
total=0; blocked=0; unread=0
for f in "$ROOT"/*/*.jsonl; do
  [ -f "$f" ] || continue
  total=$((total + 1))
  hits="$(bash -c ". $COMMON; decision_scan '$f'" 2>/dev/null)"; rc=$?
  case "$rc" in
    0) blocked=$((blocked + 1))
       printf '  [차단] %s\n' "$(basename "$f")"
       printf '%s\n' "$hits" | sed 's/^/         · /' | head -4 ;;
    2) unread=$((unread + 1)) ;;
  esac
done
echo
echo "  기록 ${total}개 중 차단 ${blocked}건 · 판독불가 ${unread}건"
echo
echo "위 [차단] 문장을 눈으로 보고 **결정 통보가 아닌 것**을 세면 그것이 위양성률이다."
echo "ADR-0012 ①-1 이 공시한 대로 이 게이트는 탐지기가 아니라 과속방지턱이므로,"
echo "위양성이 0 이 되는 것을 목표로 삼지 않는다 — 추세가 나빠지는지만 본다."
