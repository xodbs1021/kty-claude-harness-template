#!/usr/bin/env bash
# mutate-publish-gate.sh — 외부 발행 게이트(ADR-0018) 방어의 **변이 측정**.
#
# 방어를 하나씩 지우거나 뒤집고, tests/publish-receipt-gate.test.sh 가 빨개지는지 잰다.
# 케이스 수·통과 수는 아무것도 증명하지 않는다 — 변이가 유일하게 믿을 만한 지표다.
# 변이 ↔ 적색 케이스 대응표는 tests/publish-receipt-gate.cases.sh 머리에 있다.
#
# 계약 (형제 하네스와 동일 — 변이 하네스 자신의 거짓말 방지):
#   · 대상 파일에 미커밋 변경이 있으면 **거부**한다 (복원이 작업물을 지운다)
#   · 치환 앵커는 **정확히 1회** 매치해야 진행한다 — 빗나가면 빈 변이(거짓 초록)가 된다
#   · 복원 직후 git hash-object ↔ rev-parse HEAD:<경로> 를 대조한다
#   · 기준선(변이 없이 초록)을 먼저 확인한다 — 이미 빨간 트리에서는 전 변이가 "적색"으로
#     집계돼 하네스가 성공을 위장한다
#   · **구현을 바꾸면 그 코드를 겨누는 앵커를 전수 확인한다.** 앵커가 빗나가면 그 방어는
#     재지 못한 채 "측정했다"가 된다 — 실제로 두 번 겪었다(판정 함수를 갈아치웠을 때,
#     Artifact 검사를 경로 기반에서 fd 기반으로 바꿨을 때). 그래서 이 하네스는 **프리플라이트**
#     를 먼저 돈다: 변이를 하나도 적용하지 않고 앵커가 전부 정확히 1회 매치하는지만 보고,
#     하나라도 어긋나면 측정을 시작하지 않는다. 실행 중 검사(빈 변이 방지)도 그대로 남지만,
#     그건 **한 시간짜리 측정이 끝난 뒤에** 알려준다 — 사전 검사가 훨씬 싸다.
#
# 공시된 측정 공백:
#   · p26·p51 은 **정적** 케이스다(다른 프로세스의 끼어듦·하드링크 사본 조작을 러너 안에서
#     재현할 수 없다). 그래서 m25·m26 은 "그 자리에 검사가 있는가"만 겨눈다 — 검사가 남아
#     있는 채로 **틀리게** 구현되는 변이는 이 하네스가 못 잡는다.
#   · 자가 발급(에이전트가 스스로 영수증을 만드는 것)에 대한 변이는 없다. 설계 0절대로
#     그것은 사전 차단 대상이 아니다 — 겨누지 않는 것을 재는 척하지 않는다.
#   · **등가 변이 하나를 뺐다**: "판독기 rc 검사만 삭제"는 이제 관측 가능한 동작을 바꾸지
#     않는다 — 바로 뒤의 도구 이름 **형태 검사**가 같은 판정을 내기 때문이다(검수 회차에서
#     추가된 이중 방어). 살아남는 변이로 세면 방어가 없는 것처럼 보이므로 목록에서 뺐고,
#     형태 검사 자체를 지우는 변이(m33)가 그 자리를 대신 잰다.

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

HOOK="template/.claude/hooks/guard-publish-receipt.sh"
COMMON="template/.claude/hooks/_common.sh"
ISSUER="template/.claude/scripts/publish-issue-receipt.sh"
TEST="./tests/publish-receipt-gate.test.sh"

for f in "$HOOK" "$COMMON" "$ISSUER"; do
  if ! git diff --quiet -- "$f" || ! git diff --cached --quiet -- "$f"; then
    echo "✗ 대상에 미커밋 변경이 있습니다: $f — 먼저 커밋하고 재세요 (복원이 작업물을 지웁니다)" >&2
    exit 1
  fi
done

# 락 — 형제 변이 하네스와 같은 관례. 겹쳐 돌리면 주입된 변이가 서로의 복원을 밟고,
# **측정 중인 트리를 배포하는 사고**의 탐지 근거이기도 하다(install/sync 배포 가드).
LOCK="$(git rev-parse --git-dir)/mutate-publish-gate.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "✗ 이미 다른 변이 측정이 돌고 있습니다: $LOCK" >&2
  echo "  (그 프로세스가 죽었다면: rmdir '$LOCK')" >&2
  exit 1
fi
# **중단돼도 주입된 변이를 남기지 않는다.** 락만 지우고 끝나면 변이본이 트리에 남고,
# 그 트리를 배포하면 정확히 이 저장소가 겪은 사고(측정 중 트리 배포)가 재현된다.
# 복원은 최선 노력이다 — 실패하면 소리를 낸다(조용히 남기지 않는다).
cleanup() {
  local f
  for f in "$HOOK" "$COMMON" "$ISSUER"; do
    git restore --source=HEAD --worktree -- "$f" 2>/dev/null \
      || echo "✗ 복원 실패 — 변이본이 남았을 수 있습니다: $f" >&2
  done
  rmdir "$LOCK" 2>/dev/null
}
trap cleanup EXIT

if ! "$TEST" >/dev/null 2>&1; then
  echo "✗ 기준선 실패 — 변이 없이도 테스트가 빨갛습니다. 먼저 초록으로 만들고 재세요" >&2
  exit 1
fi

total=0; red=0; green=0

restore() {
  git restore --source=HEAD --worktree -- "$1" || { echo "✗ 복원 실패: $1" >&2; exit 1; }
  local w h
  w="$(git hash-object "$1")"; h="$(git rev-parse "HEAD:$1")"
  [ "$w" = "$h" ] || { echo "✗ 복원 검증 실패: $1 ($w != $h)" >&2; exit 1; }
}

# mutate <이름> <파일> <앵커> <대체>
# MODE=preflight 면 **앵커만 세고 아무것도 바꾸지 않는다.** MODE=measure 면 실제로 변이한다.
mutate() {
  local name="$1" file="$2" anchor="$3" repl="$4" n
  total=$((total + 1))
  n="$(python3 - "$file" "$anchor" <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
print(src.count(sys.argv[2]))
PY
)"
  if [ "$MODE" = 'preflight' ]; then
    if [ "$n" != "1" ]; then
      pre_bad=$((pre_bad + 1))
      echo "  ✗ [$name] 앵커 매치 ${n}회 (기대 1) — 대상: $file" >&2
    fi
    return 0
  fi
  if [ "$n" != "1" ]; then
    green=$((green + 1))
    echo "  ✗ [$name] 앵커 매치 ${n}회 (기대 1) — 빈 변이 방지로 실패 처리" >&2
    return 0
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

# 변이 목록. 프리플라이트와 본 측정이 **같은 목록**을 두 번 돈다 — 목록이 하나여야
# "사전 검사는 통과했는데 측정에서 빠진" 종류의 어긋남이 생기지 않는다.
mutations() {
  mutate 'm01 탈출구 검사 삭제' "$HOOK" \
  'hook_disabled "$HOOK_ID" && exit 0' \
  ':'

mutate 'm02 최상위 tool_name 중복 허용' "$COMMON" \
  'if len(names) != 1:' \
  'if len(names) < 1:'

mutate 'm04 registry 부재를 통과로' "$HOOK" \
  'if [ "$reg_rc" -ne 0 ]; then' \
  'if false; then'

mutate 'm05 registry 중복 행 허용' "$COMMON" \
  'if name in rows:' \
  'if False:'

mutate 'm06 registry 칸 수 검사를 채워넣기로' "$COMMON" \
  '    if len(cols) != 5:
        die("registry line %d: want 5 tab-separated columns, got %d" % (no, len(cols)))' \
  '    cols = (cols + ["1", "no", "-", "-"])[:5]'

mutate 'm07 미등재 도구도 등재로 취급(순서 역전)' "$HOOK" \
  'if [ "$reg_rc" -eq 3 ]; then
  exit 0                       # 미등재 = 이 게이트의 대상이 아니다
fi' \
  'if [ "$reg_rc" -eq 3 ]; then
  row="$(printf '"'"'1\tno\t-\t-'"'"')"; reg_rc=0
fi'

mutate 'm08 엄격 파싱 → 관대 파싱' "$COMMON" \
  '    data = json.loads(raw, object_pairs_hook=no_dup,
                      parse_float=reject_number, parse_constant=reject_number)' \
  '    data = json.loads(raw)'

mutate 'm09 digest 실패를 통과로' "$HOOK" \
  'digest="$(printf '"'"'%s'"'"' "$payload" | publish_digest "$artifact_field")"
if [ $? -ne 0 ]; then' \
  'digest="$(printf '"'"'%s'"'"' "$payload" | publish_digest "$artifact_field")"
if false; then'

mutate 'm10 Artifact 재해시 결과 무시' "$COMMON" \
  '        art = h.hexdigest()' \
  '        art = ""'

mutate 'm11 면제 플래그 선기록 삭제(로그가 먼저가 된다)' "$HOOK" \
  '      record_flag "$AUDIT_FLAG" "waived/$digest" \
        || deny "면제 흔적(감사 플래그)을 기록하지 못했습니다 — 흔적 없는 면제는 허용하지 않습니다."
      mkdir -p "$RECEIPTS_DIR" 2>/dev/null' \
  '      mkdir -p "$RECEIPTS_DIR" 2>/dev/null'

mutate 'm12 면제를 waivable 무시하고 허용' "$HOOK" \
  'if [ "$waivable" = '"'"'yes'"'"' ]; then
  body="$(printf '"'"'%s'"'"' "$payload" | field_value "$body_field")"' \
  'if true; then
  body="$(printf '"'"'%s'"'"' "$payload" | field_value body)"'

mutate 'm13 면제 프리픽스를 부분 일치로' "$HOOK" \
  "    '[비판정]'*)" \
  "    *'[비판정]'*)"

mutate 'm14 replay 검사 삭제' "$HOOK" \
  '[ "$USED_N" -gt 0 ] && replay=1' \
  ':'

mutate 'm15 active 2개를 하나로 골라 통과' "$HOOK" \
  'if [ "$n_active" -gt 1 ]; then' \
  'if false; then'

mutate 'm16 드리프트 진단 삭제' "$HOOK" \
  '    if [ "$other_ident" != "$cur_ident" ]; then' \
  '    if false; then'

mutate 'm17 정체성 대조 삭제' "$HOOK" \
  'if [ "$r_ident" != "$cur_ident" ]; then' \
  'if false; then'

mutate 'm18 영수증 미지 필드 허용' "$COMMON" \
  'extra = [k for k in rec if k not in WANT]
if extra:
    die("receipt has unknown fields: " + ",".join(sorted(extra)))' \
  'extra = []
if extra:
    die("receipt has unknown fields: " + ",".join(sorted(extra)))'

mutate 'm19 tier 타입 검사 완화(bool 통과)' "$COMMON" \
  'if type(tier) is not int or tier not in (1, 2):' \
  'if tier not in (1, 2):'

mutate 'm20 min_tier 대조 삭제' "$HOOK" \
  'if [ "$r_tier" -lt "$min_tier" ]; then' \
  'if false; then'

mutate 'm21 3튜플 대조 삭제' "$HOOK" \
  'tuple_n="$(grep -cE "^발행-리뷰: tool=$tool_re digest=$digest tier=$r_tier\$" "$review_path" 2>/dev/null | tr -d '"'"' '"'"')"' \
  'tuple_n=1'

mutate 'm22 approval_required 에서 replay 항 제거' "$HOOK" \
  '[ "$replay" -eq 1 ] && approval_required=1' \
  ':'

mutate 'm23 승인 선택 순서를 뒤집기(결정성 파괴)' "$HOOK" \
  '  an="$(printf '"'"'%s'"'"' "$cands" | LC_ALL=C sort | head -1)"' \
  '  an="$(printf '"'"'%s'"'"' "$cands" | LC_ALL=C sort -r | head -1)"'

mutate 'm24 감사 선기록 실패를 무시(사실상 후기록)' "$HOOK" \
  'record_flag "$AUDIT_FLAG" "$intent" \
  || deny "감사 선기록에 실패했습니다 — 기록 없는 소비는 허용하지 않습니다(영수증은 그대로 남습니다)."' \
  'record_flag "$AUDIT_FLAG" "$intent" || :'

mutate 'm25 WAL 직전 used 재검사 삭제' "$HOOK" \
  '# [계약순서] WAL-RECHECK' \
  '# 재검사 삭제됨'

mutate 'm26 claim 후 used 사본 재대조 삭제' "$HOOK" \
  '# [계약순서] CLAIM-REPARSE' \
  '# 재대조 삭제됨'

mutate 'm27 wedged 판정 삭제' "$HOOK" \
  'if [ -e "$used_target" ]; then' \
  'if false; then'

mutate 'm28 영수증 내용↔파일명 대조 삭제' "$HOOK" \
  'if [ "$base" != "$r_digest.$r_nonce" ] || [ "$r_digest" != "$digest" ]; then' \
  'if false; then'

mutate 'm29 영수증 도구명 대조 삭제' "$HOOK" \
  'if [ "$r_tool" != "$tool_name" ]; then' \
  'if false; then'

# ── 검수 1차 회차(2026-08-15)에서 추가된 방어 ───────────────────────────

mutate 'm30 비인용 글로브 재도입(공백 경로 붕괴)' "$HOOK" \
  '  for f in "$1/$2".*; do' \
  '  for f in $1/$2.*; do'

mutate 'm31 차단 메시지 정화 제거' "$HOOK" \
  '  [ -n "${2-}" ] && printf '"'"'  %s\n'"'"' "$(sanitize "$2")" >&2' \
  '  [ -n "${2-}" ] && printf '"'"'  %s\n'"'"' "$2" >&2'

mutate 'm32 3튜플 count 검사를 존재 검사로' "$HOOK" \
  'if [ "$tuple_n" != '"'"'1'"'"' ]; then' \
  'if [ "$tuple_n" = '"'"'0'"'"' ]; then'

mutate 'm33 도구 이름 형태 검증 제거' "$HOOK" \
  'case "$tool_name" in
  *[!A-Za-z0-9_.-]* | '"'"''"'"')' \
  'case "$tool_name" in
  '"'"''"'"')'

mutate 'm34 판독기 진단을 stdout 으로 합치기(2>&1 재도입)' "$COMMON" \
  "' \"\$PUBLISH_MAX_PAYLOAD_BYTES\" 2>/dev/null" \
  "' \"\$PUBLISH_MAX_PAYLOAD_BYTES\" 2>&1"

mutate 'm35 Artifact 일반 파일 검사 제거' "$COMMON" \
  '    if not stat.S_ISREG(fst.st_mode):' \
  '    if False:'

mutate 'm36 Artifact 크기 상한 무력화' "$COMMON" \
  'art_cap = int(sys.argv[3])' \
  'art_cap = 1 << 60'

mutate 'm37 payload 상한 검사 제거(훅 층)' "$HOOK" \
  'if [ "${payload_bytes:-0}" -gt "$PUBLISH_MAX_PAYLOAD_BYTES" ]; then' \
  'if false; then'

mutate 'm38 승인 rm 실패 무시(대칭 파괴)' "$HOOK" \
  '  if ! rm -f "$approval_file" 2>/dev/null || [ -e "$approval_file" ]; then' \
  '  if false; then'

mutate 'm39 발급 락 제거(동시 발급 허용)' "$ISSUER" \
  'if ! mkdir "$ISSUE_LOCK" 2>/dev/null; then' \
  'if false; then'

mutate 'm40 영수증 심링크 거부 제거' "$HOOK" \
  'if [ -L "$receipt" ]; then' \
  'if false; then'

mutate 'm41 판독 불가를 "없음"으로 접기(dir_state)' "$HOOK" \
  '  { [ -r "$1" ] && [ -x "$1" ]; } || return 1' \
  '  { [ -r "$1" ] && [ -x "$1" ]; } || return 3'

mutate 'm42 nonce 경계 하이픈 허용' "$COMMON" \
  'if not re.match(r"\A[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?\Z", rec["nonce"]):' \
  'if not re.match(r"\A[A-Za-z0-9-]+\Z", rec["nonce"]):'

mutate 'm43 영수증 문자집합 검사 제거' "$COMMON" \
  'for k, pat in CHARSET.items():' \
  'for k, pat in []:'

mutate 'm44 승인 파일명↔nonce 대조 제거' "$HOOK" \
  '    [ "$(printf '"'"'%s'"'"' "$ap" | cut -f2)" = "$an" ] || continue' \
  '    :'

# ── 재검수 2차(2026-08-15)에서 닫은 것 ──────────────────────────────────

# **차단을 서브셸에서 하면 차단이 아니다.** 명령 치환 안의 exit 2 는 서브셸만 죽이고,
# 부모는 빈 문자열을 받아 그대로 다음 줄로 간다 — 차단 메시지는 찍히는데 rc=0 이다.
# p82 가 7단의 문구를 좁게 재기 때문에, 13단이 대신 막아도 이 변이는 적색이 된다.
mutate 'm45 used 판정을 서브셸로 되돌리기' "$HOOK" \
  'used_scan "$digest"
if [ "$USED_RC" -eq 1 ]; then
  deny "영수증 상태를 읽지 못했습니다 — 재발행 여부를 판정할 수 없어 막습니다." \
       "경로: $RECEIPTS_USED (권한을 확인하세요)"
fi
[ "$USED_N" -gt 0 ] && replay=1' \
  '[ "$( used_scan "$digest"; [ "$USED_RC" -eq 1 ] && deny "영수증 상태를 읽지 못했습니다 — 재발행 여부를 판정할 수 없어 막습니다." "경로: $RECEIPTS_USED"; printf '"'"'%s'"'"' "$USED_N" )" -gt 0 ] && replay=1'

mutate 'm46 artifact 선개방을 경로 개방으로 되돌리기' "$COMMON" \
  '        fd = os.open(cur, os.O_RDONLY | os.O_NONBLOCK)' \
  '        fd = os.open(cur, os.O_RDONLY)'

mutate 'm47 정화에서 유니코드 서식문자 범주를 좁히기' "$HOOK" \
  'DROP = ("Cc", "Cf", "Cs", "Co", "Cn", "Zl", "Zp")' \
  'DROP = ("Cc",)'
}

# ── 프리플라이트 — 변이를 하나도 적용하지 않고 앵커만 본다 ──────────────
MODE=preflight
pre_bad=0
mutations
if [ "$pre_bad" -ne 0 ]; then
  echo "✗ 프리플라이트 실패 — 앵커 ${pre_bad}개가 현행 코드와 어긋납니다." >&2
  echo "  구현을 바꿨다면 그 코드를 겨누는 변이도 함께 고쳐야 합니다(안 고치면 그 방어는 측정되지 않습니다)." >&2
  exit 1
fi
echo "프리플라이트 ✓ 앵커 ${total}개 전부 정확히 1회 매치"

# ── 본 측정 ─────────────────────────────────────────────────────────────
MODE=measure
total=0
echo "외부 발행 게이트 변이 측정"
mutations

echo ""
echo "— 변이 $total 종: 적색 $red · 살아남음 $green"
[ "$green" -eq 0 ] || exit 1
