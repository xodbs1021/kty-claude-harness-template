#!/usr/bin/env bash
# mutate-retrieval-gate.sh — 머리 표명 게이트(stop:retrieval, ADR-0013 회수 1줄 +
# ADR-0015 레퍼런스 조사 2줄) 방어의 **변이 측정**.
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

# 락 — 형제 변이 하네스(decision-gate·harness-env)와 같은 관례. 겹쳐 돌리면 주입된
# 변이가 서로의 복원을 밟고, **측정 중인 트리를 배포하는 사고**(실제로 겪음)의 탐지
# 근거이기도 하다 — install/sync 의 배포 가드가 이 락의 존재로 "측정 중"을 판정한다.
LOCK="$(git rev-parse --git-dir)/mutate-retrieval-gate.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "✗ 이미 다른 변이 측정이 돌고 있습니다: $LOCK" >&2
  echo "  (그 프로세스가 죽었다면: rmdir '$LOCK')" >&2
  exit 1
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

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

echo "머리 표명 게이트 변이 측정"

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
  '      echo "이 게이트는 형식만 봅니다. 진짜 읽었는지·조사했는지는 검수(plan-reviewer·codex)가 봅니다."
      emit_decision_note' \
  '      echo "이 게이트는 형식만 봅니다. 진짜 읽었는지·조사했는지는 검수(plan-reviewer·codex)가 봅니다."'

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
start = src.index('# (3.4) **머리 표명 게이트**')
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

# --- ADR-0015: 둘째 줄(레퍼런스 표명) 방어 (m19~m35) -----------------------

# 19. 둘째 줄 검사 통째 무력화 — if 체인 머리에 항상 참인 no-op 가지를 끼운다
mutate 'm19 둘째 줄 검사 통째 제거' "$VSTOP" \
  '    if [ "$ref_missing" -eq 1 ]; then' \
  '    if : ; then :
    elif [ "$ref_missing" -eq 1 ]; then'

# 20. 접두어만 검사로 느슨화 — 접두어 매치 즉시 통과 (사유 강제가 산문으로 밀린다)
mutate 'm20 접두어만 검사로 느슨화' "$VSTOP" \
  '        "레퍼런스 조사:"*)
          ref_body="${rline2#레퍼런스 조사:}"' \
  '        "레퍼런스 조사:"*)
          :
          ;;
        "__never__")
          ref_body="${rline2#레퍼런스 조사:}"'

# 21. 괄호 내용 검사 제거 (빈 괄호 허용 — 불요/실패 사유 강제 소멸)
mutate 'm21 괄호 내용 검사 제거' "$VSTOP" \
  "                    if [ -z \"\$(printf '%s' \"\$ref_inner\" | LC_ALL=C tr -d '[:space:]')\" ]; then" \
  '                    if false; then'

# 22. 둘째 줄 CR 스트립 제거
mutate 'm22 둘째 줄 CR 스트립 제거' "$VSTOP" \
  "      rline2=\"\${rline2%\$'\\r'}\"" \
  '      :'

# 23. `불요` 변형 제거
mutate 'm23 불요 변형 제거' "$VSTOP" \
  '              조사함|불요|실패)' \
  '              조사함|실패)'

# 24. 닫는 괄호 뒤 잡음 허용 (accept 팔을 전부 매치로 — 아래 bad 팔이 죽는다)
mutate 'm24 꼬리 잡음 허용' "$VSTOP" \
  '                  *\))' \
  '                  *)'

# 25. 둘째 줄 불량(접두어 사유)을 목록에 추가하지 않음 — 판정만 하고 버림
mutate 'm25 둘째 줄 불량 목록 누락' "$VSTOP" \
  "          retrieval_bad_paths=\"\${retrieval_bad_paths}\${entry}#2
\"
          retrieval_bad_msgs=\"\${retrieval_bad_msgs}\${entry} — 둘째 줄이 '레퍼런스 조사:' 로 시작하지 않음
\"" \
  '          :'

# 26. 무개행 마지막 줄 보정 가지 제거 — 개행 없는 정상 둘째 줄이 누락으로 오판된다
mutate 'm26 무개행 보정 elif 가지 제거' "$VSTOP" \
  '      elif [ -n "$rline2" ]; then
        :                   # 개행 없는 마지막 줄 — 값이 있으므로 누락이 아니다
      else' \
  '      else'

# 27. 변형 정확 일치를 접두 일치로 — `조사함부족(x)` 이 통과한다
mutate 'm27 변형 꼬리 허용' "$VSTOP" \
  '              조사함|불요|실패)' \
  '              조사함*|불요*|실패*)'

# 28. 예산 키의 검사 종류 태그 제거 — 파일 내 부분 진전이 리셋을 못 만든다
mutate 'm28 예산 키 검사 태그 제거' "$VSTOP" \
  "    retrieval_bad_sorted=\"\$(printf '%s' \"\$retrieval_bad_paths\" | sort -u | tr '\\n' ' ')\" \\" \
  "    retrieval_bad_sorted=\"\$(printf '%s' \"\$retrieval_bad_paths\" | sed 's/#[12]\$//' | sort -u | tr '\\n' ' ')\" \\"

# 29. `실패` 변형 제거 (제3 변형)
mutate 'm29 실패 변형 제거' "$VSTOP" \
  '              조사함|불요|실패)' \
  '              조사함|불요)'

# 30. `조사함` 변형 제거 (변형 3종 제거 변이의 대칭 완성)
mutate 'm30 조사함 변형 제거' "$VSTOP" \
  '              조사함|불요|실패)' \
  '              불요|실패)'

# 31. 내부 괄호 거부 — 내용 안 `)` 를 잡음으로 오인하는 구현 재현 (r40 방어)
mutate 'm31 내부 괄호 거부' "$VSTOP" \
  '                case "$ref_body" in
                  *\))' \
  '                case "$ref_body" in
                  *\)*\))
                    retrieval_bad_paths="${retrieval_bad_paths}${entry}#2
"
                    ;;
                  *\))'

# 32. 변형 뒤 공백 불허 — `조사함 (x)` 가 불량이 된다 (r43 방어)
mutate 'm32 변형 뒤 공백 불허' "$VSTOP" \
  '              *'"'"' '"'"')  ref_head="${ref_head% }" ;;' \
  '              *'"'"' '"'"')  break ;;'

# 33. SP 에서 탭 제거 — 접두어 뒤 탭이 불량이 된다 (r47 방어)
mutate 'm33 SP 탭 제거' "$VSTOP" \
  "              '	'*)  ref_body=\"\${ref_body#	}\" ;;" \
  "              '	'*)  break ;;"

# 34. 닫는 괄호 뒤 공백 불허 (r49 방어)
mutate 'm34 괄호 뒤 공백 불허' "$VSTOP" \
  '              *'"'"' '"'"')  ref_body="${ref_body% }" ;;' \
  '              *'"'"' '"'"')  break ;;'

# 35. 첫 줄 "빈 줄" 분기 제거 — r50(격리 픽스처)·r04(사유 단언)가 잡는다
mutate 'm35 첫 줄 빈 줄 분기 제거' "$VSTOP" \
  '      "")
        retrieval_bad_paths="${retrieval_bad_paths}${entry}#1
"
        retrieval_bad_msgs="${retrieval_bad_msgs}${entry} — 파일이 비었거나 첫 줄이 빈 줄
"
        ;;' \
  '      "")
        ;;'

echo
echo "총 $total 건 — 적색 $red · 초록 $green"
[ "$green" -eq 0 ] && [ "$red" -eq "$total" ]
