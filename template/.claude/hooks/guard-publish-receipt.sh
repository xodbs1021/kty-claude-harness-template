#!/usr/bin/env bash
# PreToolUse(mcp__.*): 외부 발행 도구 호출에 **리뷰 영수증**을 요구한다. (ADR-0018)
#
# ── 이것은 위조 방지 장치가 아니다 ──────────────────────────────────────
# 영수증·승인·면제 흔적을 만드는 손과 감시받는 손이 **같은 에이전트**다. 작정하고 자기
# 영수증을 발급하는 것은 이 훅이 원리적으로 막을 수 없고, 막는 척하지도 않는다.
# 이 훅이 구조적으로 막는 것은 실사고의 원인 유형인 **누락**이다 — 리뷰를 건너뛰고 그냥
# 발행하는 경로. 진정성 검증은 completion-auditor 의 사후 감사가 담당한다(감사자 규약).
#
# ── 판정 순서가 계약이다 ────────────────────────────────────────────────
# 순서를 바꾸면 결과가 "조금" 다른 게 아니라 반대가 된다. 각 단계 옆 괄호는 그 자리를
# 옮겼을 때 실제로 생기는 결함이다.
#   1  탈출구
#   2  최소 파싱: 최상위 tool_name 1개          (엄격히 보면 발행 무관 도구가 다 막힌다)
#   3  registry 로드 → 미등재면 통과            (부재·형식 오류는 deny — 모르면 막는다)
#   4  엄격 파싱(등재 도구만)                   (2단에서 하면 폭발 반경이 MCP 전체다)
#   5  digest 계산 (Artifact 는 파일 재해시)
#   6  [비판정] 면제 — **플래그 먼저, 로그 나중** (뒤집으면 실패한 시도가 흔적 없이 증발)
#   7  replay 판정(used 존재 여부만)
#   8  active/<digest>.* 탐색 (2개+ deny · 0건이면 드리프트 진단 후 deny)
#   9  영수증 스키마·파일명·정체성 대조
#   10 min_tier 대조                             (여기까지 와야 tier 가 확정된다)
#   11 리뷰 산출물 3튜플 대조
#   12 승인 필요 판정(= tier2 또는 replay)과 선택 (파일명 사전순 단일 총순서)
#   13 감사 선기록(WAL) — 직전에 used 재검사     (후기록이면 실패 시 영수증만 소진된다)
#   14 승인 claim (ln→rm)
#   15 영수증 claim (ln→rm) + used 사본 재대조
#   16 통과 기록
#
# 광역 매처(mcp__.*)로 배선된다. 그래서 **registry 한 파일의 오류가 MCP 도구 전체를
# 멈춘다** — 폭발 반경을 알고 고른 값이다(모르는 상태의 통과 = 게이트 소멸). 잔존 위험
# 전체 목록은 ADR-0018 에 있다.
#
# 탈출구는 표준이다: HARNESS_HOOKS=off · ECC_DISABLED_HOOKS=publish:receipt (기본 켜짐).
#
# 이 판정 계약의 기계 정본은 tests/publish-receipt-gate.cases.sh 이고
# tests/publish-receipt-gate.test.sh 가 그것을 돌린다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

HOOK_ID='publish:receipt'
hook_disabled "$HOOK_ID" && exit 0

DIGEST=''      # 진단 문구에 싣는다. 아직 계산 전이면 빈 문자열이다.
NEED_TIER=''   # 요구 등급(알게 된 시점부터)

# deny <사유> [추가 안내] — 차단 메시지를 stderr 로 내고 rc=2 로 끝낸다.
# 공통 꼬리(digest·요구 등급·발급/승인 절차)를 붙이는 **유일 지점**이다 — 막힌 사람이
# 다음에 뭘 해야 하는지 모르는 상태를 만들지 않는다.
# sanitize <문자열> — 제어문자를 걷어내고 길이를 자른다.
# **차단 메시지에는 payload·영수증에서 온 문자열이 섞인다.** 무가공으로 내보내면 ESC 와
# 개행으로 가짜 하네스 줄을 만들어 사용자를 속일 수 있다(검수 실측). 진단을 포기하지 않고
# 위조만 없애는 지점이 여기다 — 값을 안 보여주면 막힌 사람이 원인을 못 찾는다.
sanitize() {
  local s
  s="$(printf '%s' "$1" | LC_ALL=C tr -d '[:cntrl:]')"
  printf '%s' "${s:0:400}"
}

deny() {
  printf '[Hook 차단] %s\n' "$(sanitize "$1")" >&2
  [ -n "${2-}" ] && printf '  %s\n' "$(sanitize "$2")" >&2
  [ -n "$DIGEST" ] && printf '  digest=%s\n' "$DIGEST" >&2
  [ -n "$NEED_TIER" ] && printf '  요구 등급: tier%s\n' "$NEED_TIER" >&2
  printf '  발급: .claude/scripts/publish-issue-receipt.sh --payload <payload.json> --tier <1|2> --review <리뷰 산출물 경로>\n' >&2
  printf '  승인(kty 전용 터미널): .claude/scripts/publish-approve.sh <digest>\n' >&2
  exit 2
}

# count_prefixed <디렉터리> <접두어> — `<디렉터리>/<접두어>.*` 에 맞는 실재 파일 수.
#
# **인자를 인용한 채로 글로브한다.** 예전엔 패턴 문자열 하나를 받아 `for f in $1` 로 풀었는데,
# 그러면 경로에 공백이 있는 순간 워드 스플리팅으로 열거가 0건이 된다 — 그리고 0건은 이
# 훅에서 "재발행이 아니다"라는 뜻이라, **경로에 공백이 있는 프로젝트에서는 재승인 요구가
# 통째로 사라졌다**(검수 실측). 변수 부분만 인용하고 `.*` 만 밖에 두면 둘 다 지켜진다.
count_prefixed() {
  local n=0 f
  for f in "$1/$2".*; do
    [ -e "$f" ] && n=$((n + 1))
  done
  printf '%s' "$n"
}

# dir_state <디렉터리> — rc=0 열거 가능 / rc=3 없음(=0건과 같다) / rc=1 **못 읽는다**
# 3 을 따로 두는 이유: "아직 아무것도 없다"와 "읽을 수 없다"는 반대 방향이다. 뭉뚱그리면
# 권한 오류 하나로 재발행 차단이 조용히 사라진다(fail-open).
dir_state() {
  [ -e "$1" ] || return 3
  [ -d "$1" ] || return 1
  { [ -r "$1" ] && [ -x "$1" ]; } || return 1
  return 0
}

# used_count <digest> — used/ 에서 그 digest 의 소비 기록 수. 못 읽으면 막는다.
used_count() {
  local st
  dir_state "$RECEIPTS_USED"; st=$?
  [ "$st" -eq 1 ] && deny "영수증 상태를 읽지 못했습니다 — 재발행 여부를 판정할 수 없어 막습니다." \
                          "경로: $RECEIPTS_USED (권한을 확인하세요)"
  [ "$st" -eq 3 ] && { printf '0'; return 0; }
  count_prefixed "$RECEIPTS_USED" "$1"
}

# field_value <점 경로> — stdin payload 의 tool_input 안에서 문자열 값 하나. 없으면 rc=1.
field_value() {
  python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
except Exception:
    raise SystemExit(1)
cur = data.get("tool_input") if isinstance(data, dict) else None
for part in sys.argv[1].split("."):
    if not isinstance(cur, dict) or part not in cur:
        raise SystemExit(1)
    cur = cur[part]
if not isinstance(cur, str):
    raise SystemExit(1)
sys.stdout.write(cur)
' "$1" 2>/dev/null
}

# 입력을 상한까지만 읽는다. 상한이 없으면 거대 입력 하나로 훅을 세울 수 있고,
# 멈춘 훅은 차단도 통과도 아니다. 넘치면 조용히 자르지 않고 **막는다**(자르면 다른
# payload 가 되어 "영수증 없음"이라는 엉뚱한 사유로 끝난다).
payload="$(head -c "$((PUBLISH_MAX_PAYLOAD_BYTES + 1))")"
if [ "${#payload}" -gt "$PUBLISH_MAX_PAYLOAD_BYTES" ]; then
  deny "호출 입력이 너무 큽니다 — 상한을 넘는 입력은 판정하지 않습니다." \
       "상한: $PUBLISH_MAX_PAYLOAD_BYTES 바이트"
fi

# ── 2) 최소 파싱 ────────────────────────────────────────────────────────
tool_name="$(printf '%s' "$payload" | publish_tool_name)"
if [ $? -ne 0 ]; then
  deny "호출의 도구 이름을 판독하지 못했습니다 — 발행 대상인지 판정할 수 없어 막습니다." \
       "최상위 tool_name 이 정확히 하나여야 합니다."
fi
# 판독기 밖에서 **형태를 한 번 더 본다.** 인터프리터 시작 잡음이 stdout 으로 나오는 환경
# (깨진 .pth 등)에서는 리다이렉션으로 값을 지킬 수 없다 — 그 잡음이 섞인 이름은 목록에
# 없으니 "미등재 → 통과"가 되어 **환경 문제만으로 게이트가 사라진다**(검수 실측).
# 공시된 대가: 허용 문자 밖의 이름을 쓰는 도구는 등록할 수도 없지만 여기서 **막힌다**.
# 등록 가능한 이름의 문자집합과 같은 기준이라 판정이 갈리지 않는 쪽을 골랐다.
case "$tool_name" in
  *[!A-Za-z0-9_.-]* | '')
    deny "호출의 도구 이름을 판독하지 못했습니다(허용 문자 밖) — 판정할 수 없어 막습니다." \
         "판독값: $tool_name" ;;
esac

# ── 3) registry 로드 ────────────────────────────────────────────────────
row="$(publish_registry_lookup "$tool_name")"
reg_rc=$?
if [ "$reg_rc" -eq 3 ]; then
  exit 0                       # 미등재 = 이 게이트의 대상이 아니다
fi
if [ "$reg_rc" -ne 0 ]; then
  # digest 도 등급도 아직 없는 시점이라 공통 꼬리 대신 전용 문구를 쓴다.
  printf '[Hook 차단] 발행 대상 목록을 읽지 못했습니다 — 어떤 도구가 게이트 대상인지 모르는 상태의 통과는 게이트 소멸이라 막습니다.\n' >&2
  printf '  목록: %s\n' "$PUBLISH_REGISTRY" >&2
  printf '  사유: %s\n' "$row" >&2
  printf '  급하면 표준 탈출구: ECC_DISABLED_HOOKS=%s (또는 HARNESS_HOOKS=off) — docs/usage.md 5절 표기\n' "$HOOK_ID" >&2
  exit 2
fi
min_tier="$(printf '%s' "$row" | cut -f1)"
waivable="$(printf '%s' "$row" | cut -f2)"
artifact_field="$(printf '%s' "$row" | cut -f3)"
body_field="$(printf '%s' "$row" | cut -f4)"
NEED_TIER="$min_tier"

# ── 4·5) 엄격 파싱 + digest ─────────────────────────────────────────────
digest="$(printf '%s' "$payload" | publish_digest "$artifact_field")"
if [ $? -ne 0 ]; then
  deny "호출 입력을 엄격하게 읽지 못했습니다 — 리뷰한 내용과 실제 발행 내용이 갈릴 수 있어 막습니다." \
       "사유: $digest"
fi
DIGEST="$digest"

# ── 6) [비판정] 면제 — 판정이 아니라 흔적 남기기다 ──────────────────────
# 순서가 계약: **플래그 먼저, 로그 나중.** 로그가 실패하면 로그에는 아무것도 안 남고
# 플래그만 남는데, 그 플래그가 "면제를 시도했다"는 유일한 흔적이다(감사자 계약 ⑥).
if [ "$waivable" = 'yes' ]; then
  body="$(printf '%s' "$payload" | field_value "$body_field")"
  case "$body" in
    '[비판정]'*)
      record_flag "$AUDIT_FLAG" "waived/$digest" \
        || deny "면제 흔적(감사 플래그)을 기록하지 못했습니다 — 흔적 없는 면제는 허용하지 않습니다."
      mkdir -p "$RECEIPTS_DIR" 2>/dev/null
      if ! { printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$tool_name" "$digest" \
             >> "$RECEIPTS_WAIVED_LOG"; } 2>/dev/null; then
        deny "면제 기록(waived.log)을 남기지 못했습니다 — 흔적 없는 면제는 허용하지 않습니다." \
             "감사 플래그에는 시도 흔적이 남았습니다: waived/$digest"
      fi
      exit 0 ;;
  esac
fi

# ── 7) replay 판정 (여기서는 **판정만** 한다 — 승인 요구의 확정은 12) 이후) ──
replay=0
[ "$(used_count "$digest")" -gt 0 ] && replay=1

# ── 8) active 탐색 ──────────────────────────────────────────────────────
receipt=''
n_active=0
dir_state "$RECEIPTS_ACTIVE"
if [ $? -eq 1 ]; then
  deny "영수증 상태를 읽지 못했습니다 — 영수증 유무를 판정할 수 없어 막습니다." \
       "경로: $RECEIPTS_ACTIVE (권한을 확인하세요)"
fi
for f in "$RECEIPTS_ACTIVE/$digest".*; do
  [ -e "$f" ] || continue
  n_active=$((n_active + 1))
  receipt="$f"
done
if [ "$n_active" -gt 1 ]; then
  deny "같은 digest 의 영수증이 2개 이상입니다 — 어느 것을 소비할지 알 수 없어 막습니다." \
       "하나만 남기고 나머지는 $RECEIPTS_QUARANTINE/ 로 옮기세요."
fi

cur_ident="$(publish_serializer_identity)"
if [ -z "$cur_ident" ]; then
  deny "이 환경의 직렬화기 정체성을 읽지 못했습니다 (python3 부재?) — 영수증을 대조할 수 없어 막습니다."
fi

if [ "$n_active" -eq 0 ]; then
  # 드리프트 진단: 정체성이 다른 영수증이 남아 있으면 원인이 "리뷰를 안 했다"가 아니라
  # "직렬화가 갈렸다"일 수 있다. 일반 무영수증 문구로 접으면 원인을 영영 못 찾는다.
  for f in "$RECEIPTS_ACTIVE"/*; do
    [ -f "$f" ] || continue
    other="$(publish_receipt_fields "$f")" || continue
    other_ident="$(printf '%s' "$other" | cut -f6)"
    if [ "$other_ident" != "$cur_ident" ]; then
      deny "직렬화 드리프트 의심 — 이 환경과 다른 직렬화기로 발급된 영수증이 남아 있습니다." \
           "현재=[$cur_ident] 영수증=[$other_ident]. 영구 무효가 아니라 **현 환경에서 소비 불가**입니다. 발급 환경을 되돌리거나, 리뷰는 그대로 두고 발급만 다시 하세요(digest 는 리뷰 내용에 묶여 있어 리뷰 재실행은 불요)."
    fi
  done
  deny "이 호출에 대한 영수증이 없습니다 — 리뷰 없이 발행할 수 없습니다."
fi

# ── 9) 영수증 스키마·파일명·정체성 ──────────────────────────────────────
# 심링크는 받지 않는다. 소비는 하드링크(ln)인데, 심링크에 하드링크를 걸면 **링크 자체**가
# 복제돼 검증한 내용과 소비한 실체가 갈릴 수 있다.
if [ -L "$receipt" ]; then
  deny "영수증이 심볼릭 링크입니다 — 검증한 내용과 소비할 실체가 갈릴 수 있어 막습니다." \
       "경로: $receipt"
fi
fields="$(publish_receipt_fields "$receipt")"
if [ $? -ne 0 ]; then
  deny "영수증 형식이 계약과 다릅니다 — 판독할 수 없어 막습니다." "사유: $fields"
fi
r_tool="$(printf '%s' "$fields" | cut -f1)"
r_digest="$(printf '%s' "$fields" | cut -f2)"
r_tier="$(printf '%s' "$fields" | cut -f3)"
r_review="$(printf '%s' "$fields" | cut -f4)"
r_nonce="$(printf '%s' "$fields" | cut -f5)"
r_ident="$(printf '%s' "$fields" | cut -f6)"
base="$(basename "$receipt")"

# 내용 ↔ 파일명 ↔ 현재 요청이 **전부** 맞아야 한다. 하나라도 어긋나면 검증한 내용과
# 소비할 파일이 다른 것을 가리킬 수 있다. claim 대상은 아래에서 검증된 이 경로다.
if [ "$base" != "$r_digest.$r_nonce" ] || [ "$r_digest" != "$digest" ]; then
  deny "영수증 형식 — 내용과 파일명이 어긋납니다(digest·nonce)." "파일=[$base] 내용=[$r_digest.$r_nonce]"
fi
if [ "$r_tool" != "$tool_name" ]; then
  deny "영수증 형식 — 영수증의 도구가 이 호출과 다릅니다." "영수증=[$r_tool] 호출=[$tool_name]"
fi
if [ "$r_ident" != "$cur_ident" ]; then
  deny "직렬화 드리프트 의심 — 영수증을 만든 환경과 지금 환경의 직렬화기가 다릅니다." \
       "현재=[$cur_ident] 영수증=[$r_ident]. 영구 무효가 아니라 **현 환경에서 소비 불가**입니다. 발급 환경을 되돌리거나, 리뷰는 그대로 두고 발급만 다시 하세요."
fi

# ── 10) min_tier 대조 ───────────────────────────────────────────────────
if [ "$r_tier" -lt "$min_tier" ]; then
  deny "영수증 등급이 이 도구의 요구 등급보다 낮습니다." "영수증=tier$r_tier"
fi
NEED_TIER="$r_tier"

# ── 11) 리뷰 산출물 3튜플 ───────────────────────────────────────────────
case "$r_review" in
  /*) review_path="$r_review" ;;
  *)  review_path="$PROJECT_DIR/$r_review" ;;
esac
if [ ! -r "$review_path" ]; then
  deny "리뷰 산출물을 읽을 수 없습니다 — 리뷰의 증거가 없습니다." "경로: $review_path"
fi
# 정규식 한 벌로 도구·digest·등급을 **한 번에** 본다. 셋을 따로 보면 서로 다른 줄의
# 조각이 조합돼 통과할 수 있다. 도구명의 `.` 만 이스케이프한다(등재 이름은 [A-Za-z0-9_.-]).
tool_re="$(printf '%s' "$tool_name" | sed 's/\./\\./g')"
# **정확히 1회**여야 한다. 존재만 보면 리뷰 하나에 여러 등급을 함께 적어 두고 낮은 쪽
# 영수증으로 통과할 수 있다(검수 실측) — 그러면 등급이 리뷰어의 판정이 아니라 선택지가 된다.
tuple_n="$(grep -cE "^발행-리뷰: tool=$tool_re digest=$digest tier=$r_tier\$" "$review_path" 2>/dev/null | tr -d ' ')"
[ -n "$tuple_n" ] || tuple_n=0
if [ "$tuple_n" != '1' ]; then
  deny "리뷰 산출물의 3튜플이 정확히 한 줄이 아닙니다(찾은 줄 ${tuple_n}개)." \
       "필요한 줄: 발행-리뷰: tool=$tool_name digest=$digest tier=$r_tier"
fi

# ── 12) 승인 필요 판정과 선택 ───────────────────────────────────────────
# 승인 요구는 **영수증 등급**과 replay 가 정한다. registry 의 min_tier 는 하한일 뿐이라,
# 리뷰어가 tier2 로 판정한 발행을 도구 분류가 되돌리지 못한다.
approval_required=0
[ "$r_tier" -eq 2 ] && approval_required=1
[ "$replay" -eq 1 ] && approval_required=1

approval_file=''
if [ "$approval_required" -eq 1 ]; then
  # 선택은 **파일명 사전순 단일 총순서**다 — 비결정적으로 고르면 어느 승인이 소비됐는지
  # 감사자가 재현할 수 없다. 판독 불가한 승인 파일은 승인이 아니므로 세지 않는다.
  dir_state "$RECEIPTS_APPROVAL_ACTIVE"
  if [ $? -eq 1 ]; then
    deny "승인 상태를 읽지 못했습니다 — 승인 유무를 판정할 수 없어 막습니다." \
         "경로: $RECEIPTS_APPROVAL_ACTIVE (권한을 확인하세요)"
  fi
  # `$(ls)` 를 쓰지 않는다 — 워드 스플리팅이 이름을 쪼개고, 그러면 있는 승인이 없어 보인다.
  # 후보 이름은 판독기가 문자집합을 강제한 nonce 이고 **파일명과 같아야** 하므로,
  # 공백·개행이 든 이름은 애초에 후보가 되지 않는다(그래서 줄 단위 정렬이 안전하다).
  cands=''
  for af in "$RECEIPTS_APPROVAL_ACTIVE"/*; do
    [ -f "$af" ] || continue
    [ -L "$af" ] && continue
    ap="$(publish_approval_fields "$af")" || continue
    [ "$(printf '%s' "$ap" | cut -f1)" = "$digest" ] || continue
    an="$(basename "$af")"
    # 내용의 nonce 와 파일명이 다르면 선택 순서(파일명)와 소비 대상(내용)이 갈린다.
    [ "$(printf '%s' "$ap" | cut -f2)" = "$an" ] || continue
    cands="$cands$an
"
  done
  an="$(printf '%s' "$cands" | LC_ALL=C sort | head -1)"
  [ -n "$an" ] && approval_file="$RECEIPTS_APPROVAL_ACTIVE/$an"
  if [ -z "$approval_file" ]; then
    if [ "$replay" -eq 1 ]; then
      deny "이 digest 는 이미 소비됐습니다 — 재발행에는 kty 승인이 필요합니다(재발행 = 재승인)." \
           "발행이 실패했다는 주장만으로는 다시 보낼 수 없습니다. 사용자에게 승인을 요청하세요."
    fi
    deny "tier2 발행에는 kty 승인이 필요한데 일치하는 승인이 없습니다."
  fi
fi

# ── 13) 감사 선기록(WAL) ────────────────────────────────────────────────
# [계약순서] WAL-RECHECK
# 승인을 고른 사이에 다른 프로세스가 같은 digest 를 소비했을 수 있다. 그러면 이 호출은
# 재발행이 되는데, 이미 고른 승인은 "최초 발행"에 대한 것이라 그대로 쓸 수 없다.
# 재진입하지 않고 deny 한다 — 승인 절차를 안내하는 쪽이 상태 기계를 단순하게 유지한다.
if [ "$replay" -eq 0 ] && [ "$(used_count "$digest")" -gt 0 ]; then
  deny "판정 도중 같은 digest 가 다른 경로로 소비됐습니다 — 이 호출은 재발행이 되어 막습니다." \
       "재발행에는 새 kty 승인이 필요합니다."
fi
# [계약순서] WAL-WRITE
# **소비보다 먼저 적는다.** 후기록으로 옮기면 기록이 실패했을 때 영수증만 소진되고,
# 감사자에게는 발행이 없었던 것으로 보인다(감사자 계약 ⑤ — intent 만 있고 used 가 없으면
# "미소비 시도"로 읽는다).
intent="publish-intent/$base"
[ -n "$approval_file" ] && intent="$intent approval/$(basename "$approval_file")"
record_flag "$AUDIT_FLAG" "$intent" \
  || deny "감사 선기록에 실패했습니다 — 기록 없는 소비는 허용하지 않습니다(영수증은 그대로 남습니다)."

# ── 14) 승인 claim ──────────────────────────────────────────────────────
approval_consumed=0
if [ -n "$approval_file" ]; then
  an="$(basename "$approval_file")"
  mkdir -p "$RECEIPTS_APPROVAL_USED" 2>/dev/null
  if ! ln "$approval_file" "$RECEIPTS_APPROVAL_USED/$an" 2>/dev/null; then
    deny "kty 승인을 소비하지 못했습니다(다른 호출이 먼저 가져갔을 수 있습니다)." "승인: $an"
  fi
  # 영수증 쪽과 **대칭**이다: ln 은 됐는데 rm 이 실패하면 승인이 양쪽에 남고, 그 잔존본이
  # 다음 승인까지 EEXIST 로 봉쇄한다(검수 실측). 조용히 넘기면 사용자는 승인을 다시 만들 수
  # 없는 이유를 영영 못 찾는다.
  if ! rm -f "$approval_file" 2>/dev/null || [ -e "$approval_file" ]; then
    record_flag "$AUDIT_FLAG" "wedged-approval/$an"
    deny "승인 소비가 중단된 흔적이 있습니다(approval-used 와 approval-active 에 같은 이름이 함께 있습니다)." \
         "수동 복구: mv '$approval_file' '$RECEIPTS_QUARANTINE/' 후 다시 승인하세요. 발행은 실행되지 않았습니다."
  fi
  approval_consumed=1
fi

# 승인이 이미 소모된 뒤의 실패에는 반드시 이 안내가 붙어야 한다 — 안 붙이면 사용자는
# 승인이 살아 있다고 믿고 다시 시도해 또 막힌다.
reapprove_note=''
[ "$approval_consumed" -eq 1 ] && reapprove_note='이 시도에서 kty 승인이 이미 소모됐습니다 — 다시 하려면 재승인이 필요합니다. '

# ── 15) 영수증 claim ────────────────────────────────────────────────────
used_target="$RECEIPTS_USED/$base"
if [ -e "$used_target" ]; then
  # used 와 active 에 같은 이름이 동시에 있다 = 이전 소비가 rm 직전에 끊긴 자국(wedged).
  # 재claim 은 EEXIST 이고 발급기도 같은 digest 재발급을 거부하므로 자동 복구가 없다.
  record_flag "$AUDIT_FLAG" "wedged/$base"
  deny "영수증 소비가 중단된 흔적이 있습니다(used 와 active 에 같은 이름이 함께 있습니다)." \
       "${reapprove_note}수동 복구: mv '$receipt' '$RECEIPTS_QUARANTINE/' 후 다시 발급하세요."
fi
mkdir -p "$RECEIPTS_USED" 2>/dev/null
# [계약순서] CLAIM
# ln 은 대상이 있으면 EEXIST 로 실패한다 — 그 실패가 동시 호출에서 **정확히 하나만**
# 통과시키는 근거다. mv -n 은 쓰지 않는다: 실패해도 rc=0 을 내는 구현이 있어 경합
# 판정이 조용히 무너진다.
if ! ln "$receipt" "$used_target" 2>/dev/null; then
  deny "영수증을 소비하지 못했습니다(다른 호출이 먼저 가져갔거나 쓰기가 막혔습니다)." \
       "${reapprove_note}영수증: $base"
fi
if ! rm -f "$receipt" 2>/dev/null || [ -e "$receipt" ]; then
  record_flag "$AUDIT_FLAG" "wedged/$base"
  deny "영수증 소비가 중단된 흔적이 있습니다(used 로 옮겼지만 active 잔존본을 지우지 못했습니다)." \
       "${reapprove_note}수동 복구: mv '$receipt' '$RECEIPTS_QUARANTINE/'"
fi
# [계약순서] CLAIM-REPARSE
# 소비한 사본을 한 번 더 읽어 digest·등급·정체성을 재대조한다. 정상 경로에서는 같은
# 내용이지만, 그 전제가 깨진 상태로 발행이 나가는 것보다 한 번 더 보는 쪽이 싸다.
recheck="$(publish_receipt_fields "$used_target")"
if [ $? -ne 0 ] \
   || [ "$(printf '%s' "$recheck" | cut -f2)" != "$digest" ] \
   || [ "$(printf '%s' "$recheck" | cut -f3)" != "$r_tier" ] \
   || [ "$(printf '%s' "$recheck" | cut -f6)" != "$cur_ident" ]; then
  record_flag "$AUDIT_FLAG" "mismatch/$base"
  deny "소비한 영수증 사본이 검증한 내용과 다릅니다 — 발행을 막습니다." \
       "${reapprove_note}대상: $used_target"
fi

# ── 16) 통과 ────────────────────────────────────────────────────────────
# 기록값은 **안정 경로** used/<digest>.<nonce> 다. 감사자가 이 경로로 파일을 찾는다.
if ! record_flag "$AUDIT_FLAG" "used/$base"; then
  # 이미 소비됐으므로 막지 않는다(막으면 발행은 못 하고 영수증만 사라진다).
  # 대신 조용히 넘어가지 않는다 — 선기록(intent)은 남아 있으므로 감사자가 대조할 수 있다.
  printf '[하네스] 발행 영수증 소비 기록을 남기지 못했습니다: used/%s (감사 선기록으로 대조하세요)\n' "$base" >&2
fi
exit 0
