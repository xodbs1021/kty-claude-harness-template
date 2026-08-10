#!/usr/bin/env bash
# mutate-retrieval-gate.sh — 회수 표명 게이트(stop:retrieval) 방어의 **변이 측정**.
#
# 방어를 하나씩 지우거나 뒤집고, tests/retrieval-attestation.test.sh 가 빨개지는지 잰다.
# 케이스 수·통과 수는 아무것도 증명하지 않는다 — 변이가 유일하게 믿을 만한 지표다.
#
# 계약 (위음성 카탈로그 23번 — 변이 하네스 자신의 거짓말 방지):
#   · 대상 파일에 미커밋 변경이 있으면 **거부**한다 (복원이 작업물을 지운다)
#   · 치환 앵커는 **정확히 1회** 매치해야 진행한다 — 빗나가면 빈 변이(거짓 초록)가 된다
#   · 복원 직후 git hash-object ↔ rev-parse HEAD:<경로> 를 대조한다
#
# 공시된 측정 공백:
#   · 3.4 exit 0 경로의 decision_note 방출 제거 — 현행 발동 규칙에서 도달 불가라
#     **원리적으로 초록**이다 (테스트 파일 헤더 공시와 짝. ADR-0012 "모르는 rc" 공백과 같은 부류)

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

VSTOP="template/.claude/hooks/verify-before-stop.sh"
MARK="template/.claude/hooks/mark-needs-audit.sh"
COMMON="template/.claude/hooks/_common.sh"
TEST="./tests/retrieval-attestation.test.sh"

for f in "$VSTOP" "$MARK" "$COMMON"; do
  if ! git diff --quiet -- "$f" || ! git diff --cached --quiet -- "$f"; then
    echo "✗ 대상에 미커밋 변경이 있습니다: $f — 먼저 커밋하고 재세요 (복원이 작업물을 지웁니다)" >&2
    exit 1
  fi
done

# **기준선 확인이 먼저다.** 변이 전 테스트가 이미 빨간 상태면 모든 변이가 "적색"으로
# 집계돼 하네스가 성공을 위장한다 — 적색의 원인이 방어인지 무관한 회귀인지 구별이 안 된다
# (구현 검수 [cx] 지적).
if ! "$TEST" >/dev/null 2>&1; then
  echo "✗ 기준선 실패 — 변이 없이도 테스트가 빨갛습니다. 먼저 초록으로 만들고 재세요" >&2
  exit 1
fi

total=0; red=0; green=0

restore() {   # $1 = 파일
  git restore --source=HEAD --worktree -- "$1" || { echo "✗ 복원 실패: $1" >&2; exit 1; }
  local w h
  w="$(git hash-object "$1")"; h="$(git rev-parse "HEAD:$1")"
  [ "$w" = "$h" ] || { echo "✗ 복원 검증 실패: $1 ($w != $h)" >&2; exit 1; }
}

# mutate <이름> <파일> <앵커(문자열)> <대체(문자열)>
# 앵커가 정확히 1회 매치하지 않으면 그 항목을 실패로 세운다(fail-closed).
mutate() {
  local name="$1" file="$2" anchor="$3" repl="$4" n
  total=$((total + 1))
  n="$(python3 - "$file" "$anchor" <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
print(src.count(sys.argv[2]))
PY
)"
  if [ "$n" != "1" ]; then
    echo "  ✗ [$name] 앵커 매치 ${n}회 (기대 1) — 빈 변이 방지로 실패 처리" >&2
    return 1
  fi
  python3 - "$file" "$anchor" "$repl" <<'PY'
import sys
p, a, r = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(p, encoding='utf-8').read()
open(p, 'w', encoding='utf-8').write(src.replace(a, r, 1))
PY
  if "$TEST" >/dev/null 2>&1; then
    green=$((green + 1))
    echo "  🟢 [$name] 살아남음 — 이 방어를 지키는 케이스가 없다"
  else
    red=$((red + 1))
    echo "  🔴 [$name] 적색 (방어 확인)"
  fi
  restore "$file"
}

echo "회수 표명 게이트 변이 측정"

# 1. 첫 줄 검사를 느슨하게: 접두어 매치를 무엇이든 통과로
mutate 'm01 첫 줄 패턴을 항상 매치로' "$VSTOP" \
  '      "사전 결정 회수:"*)' \
  '      *)'

# 2. 자동 해제 제거
mutate 'm02 자동 해제 제거' "$VSTOP" \
  '    rm -f "$RETRIEVAL_FLAG" 2>/dev/null' \
  '    :'

# 3. 해제 후 재평가 제거 (허위 감사 차단 재현)
mutate 'm03 재평가 exit 0 제거' "$VSTOP" \
  '    if ! work_pending; then
      # 이 턴의 할 일이 이것뿐이었다' \
  '    if false; then
      # 이 턴의 할 일이 이것뿐이었다'

# 4. 재평가식(work_pending)에서 push 항 제거
mutate 'm04 work_pending 에서 push 제거' "$VSTOP" \
  '  [ -n "$push_unsent" ] && return 0' \
  '  :'

# 5. 패턴 접두어를 `사전` 으로 느슨화
mutate 'm05 패턴을 사전 만으로 느슨화' "$VSTOP" \
  '      "사전 결정 회수:"*)' \
  '      "사전"*)'

# 6. mark-needs-audit 의 회수 기록 제거
mutate 'm06 회수 플래그 기록 제거' "$MARK" \
  '    record_flag "$RETRIEVAL_FLAG"  "$dual_value" || dw=1' \
  '    :'

# 7. 조기 종료·재평가 술어에서 retrieval 제거
mutate 'm07 work_pending 에서 retrieval 제거' "$VSTOP" \
  '  retrieval_pending && return 0' \
  '  :'

# 8. 예산 키에서 불량 목록 제거 (진전이 리셋을 못 만든다)
mutate 'm08 예산 키의 불량 목록 제거' "$VSTOP" \
  '    gate_budget "retrieval:${retrieval_bad_sorted}"' \
  '    gate_budget "retrieval"'

# 9. 불량 목록을 공유 지문으로 전파 (다른 게이트 예산 오염)
mutate 'm09 불량 목록을 flags_fp 로 전파' "$VSTOP" \
  'retrieval_pending         && flags_fp="${flags_fp}r"' \
  'retrieval_pending         && flags_fp="${flags_fp}r$(sort -u "$RETRIEVAL_FLAG" 2>/dev/null | tr "\n" " ")"'

# 10. 회수 차단 메시지에서 emit_decision_note 제거
mutate 'm10 회수 차단의 decision_note 제거' "$VSTOP" \
  '      echo "이 게이트는 형식만 봅니다. 진짜 읽었는지는 검수(plan-reviewer·codex)가 봅니다."
      emit_decision_note' \
  '      echo "이 게이트는 형식만 봅니다. 진짜 읽었는지는 검수(plan-reviewer·codex)가 봅니다."'

# 11. 경로 해석을 cwd 기준으로 되돌림
mutate 'm11 상대경로를 cwd 기준으로' "$VSTOP" \
  '      *)  rfile="$PROJECT_DIR/$entry" ;;' \
  '      *)  rfile="$entry" ;;'

# 12. 예산 소진 정리 rm 목록에서 회수 플래그 제거
mutate 'm12 소진 정리 rm 에서 회수 제거' "$VSTOP" \
  '    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" "$RETRIEVAL_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null' \
  '    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null'

# 13. 소진 정리 changed 나열에서 회수 플래그 제거
mutate 'm13 소진 changed 에서 회수 제거' "$VSTOP" \
  '"$DUALREVIEW_FLAG" "$RETRIEVAL_FLAG" 2>/dev/null | tr -d' \
  '"$DUALREVIEW_FLAG" 2>/dev/null | tr -d'

# 14. BOM·CR 스트립 제거
mutate 'm14 BOM·CR 스트립 제거' "$VSTOP" \
    "    rline=\"\${rline#\$'\\xEF\\xBB\\xBF'}\"
    rline=\"\${rline%\$'\\r'}\"" \
    '    :'

# 15. 게이트를 듀얼리뷰(3.5) 뒤로 옮기기 — 지우는 변이가 아니라 **옮기는 변이**다.
#     (지우면 "게이트 없음"을 재는 것이지 "순서가 틀림"을 재는 것이 아니다 — ADR-0012 규약)
total=$((total + 1))
if python3 - "$VSTOP" <<'PY'
import sys
p = sys.argv[1]
src = open(p, encoding='utf-8').read()
start = src.index('# (3.4) **회수 표명 게이트**')
end = src.index('# (3.5) 듀얼 리뷰(codex) 게이트')
block = src[start:end]
rest = src[:start] + src[end:]
anchor = "# (4) change-explainer 게이트"
i = rest.index(anchor)
open(p, 'w', encoding='utf-8').write(rest[:i] + block + rest[i:])
PY
then
  if "$TEST" >/dev/null 2>&1; then
    green=$((green + 1)); echo "  🟢 [m15 게이트를 3.5 뒤로 이동] 살아남음"
  else
    red=$((red + 1)); echo "  🔴 [m15 게이트를 3.5 뒤로 이동] 적색 (순서 계약 확인)"
  fi
  restore "$VSTOP"
else
  echo "  ✗ [m15] 블록 이동 실패 — 실패 처리" >&2
fi

# 16. retrieval_pending 에서 hook_disabled 접기 제거 (게이트 끈 환경의 갇힘 재현)
mutate 'm16 retrieval_pending 의 비활성 접기 제거' "$COMMON" \
  '  ! hook_disabled "stop:retrieval"' \
  '  true'

# 17. 자동 해제 후 지문 재계산 제거 (stale 지문 → 하위 게이트 카운터 거짓 리셋 재현)
mutate 'm17 해제 후 compute_flags_fp 재호출 제거' "$VSTOP" \
  '    # 지문을 다시 계산한다 — 진입 시 스냅숏에는 방금 지운 "r" 비트가 남아 있어, 이 턴의
    # 하위 게이트가 stale 지문으로 예산을 매기고 다음 턴에 거짓 리셋이 난다([cc] HIGH).
    compute_flags_fp' \
  '    :'

# 18. read 관용구 되돌림 (개행 없는 마지막 줄이 조용히 스킵되는 결함 재현)
mutate 'm18 read 의 || [ -n ] 제거' "$VSTOP" \
  '  while IFS= read -r entry || [ -n "$entry" ]; do' \
  '  while IFS= read -r entry; do'

echo
echo "총 $total 건 — 적색 $red · 초록 $green"
[ "$green" -eq 0 ] && [ "$red" -eq "$total" ]
