#!/usr/bin/env bash
# publish-issue-receipt.sh — 외부 발행 리뷰 영수증 **발급기**. (ADR-0018)
#
# 사용법:
#   .claude/scripts/publish-issue-receipt.sh \
#       --payload <발행 호출 payload JSON 파일> \
#       --tier <1|2> \
#       --review <리뷰 산출물 경로(프로젝트 상대 또는 절대)>
#
# payload 파일은 훅이 받는 것과 **같은 모양**이어야 한다: {"tool_name":…,"tool_input":{…}}.
# 실제로 보낼 인자 그대로여야 한다 — 한 글자라도 다르면 digest 가 갈려 게이트가 막는다.
# 그게 이 게이트의 요점이다(리뷰한 내용과 발행할 내용이 같음을 기계가 확인한다).
#
# **게이트와 같은 함수(publish_digest)를 쓴다.** 여기서 따로 해시를 만들면 두 손이 다른
# 계산을 하게 되고, 그 순간 이 방식의 근거(정규화 표준 대신 단일 구현)가 무너진다.
#
# 발급 전에 세 가지를 미리 본다 — 나중에 게이트에서만 걸리면 사용자는 "영수증이 있는데
# 왜 막히나"를 겪는다:
#   ① 등재 도구인가 · 등급이 min_tier 이상인가
#   ② 리뷰 산출물에 3튜플(tool·digest·tier)이 한 줄로 있는가
#   ③ 같은 digest 의 미소비 영수증이 이미 있는가(있으면 거부 — 두 개가 되면 게이트가
#      "어느 것을 소비할지 모른다"로 통째로 잠긴다)
#
# 셸 이식성: macOS 기본 bash 는 3.2 다.

set -uo pipefail
# shellcheck source=../hooks/_common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/_common.sh"

die() { printf '✗ %s\n' "$1" >&2; exit 1; }

payload_file=''
tier=''
review=''
while [ $# -gt 0 ]; do
  case "$1" in
    --payload) payload_file="${2-}"; shift 2 ;;
    --tier)    tier="${2-}";         shift 2 ;;
    --review)  review="${2-}";       shift 2 ;;
    *) die "모르는 인자: $1 (사용법은 이 스크립트 첫머리 주석)" ;;
  esac
done
[ -n "$payload_file" ] || die '--payload 가 필요합니다'
[ -n "$tier" ]         || die '--tier 가 필요합니다 (1 또는 2)'
[ -n "$review" ]       || die '--review 가 필요합니다 (리뷰 산출물 경로)'
case "$tier" in 1|2) ;; *) die "--tier 는 1 또는 2 여야 합니다: $tier" ;; esac
[ -r "$payload_file" ] || die "payload 파일을 읽을 수 없습니다: $payload_file"

tool_name="$(publish_tool_name < "$payload_file")" \
  || die "payload 에서 도구 이름을 판독하지 못했습니다 (최상위 tool_name 이 정확히 하나여야 합니다)"

row="$(publish_registry_lookup "$tool_name")"
case $? in
  0) ;;
  3) die "이 도구는 발행 대상 목록에 없습니다 — 영수증이 필요 없습니다: $tool_name" ;;
  *) die "발행 대상 목록을 읽지 못했습니다: $row" ;;
esac
min_tier="$(printf '%s' "$row" | cut -f1)"
artifact_field="$(printf '%s' "$row" | cut -f3)"
[ "$tier" -ge "$min_tier" ] || die "이 도구는 최소 tier$min_tier 을 요구합니다 (요청: tier$tier)"

digest="$(publish_digest "$artifact_field" < "$payload_file")" \
  || die "digest 를 계산하지 못했습니다: $digest"

case "$review" in
  /*) review_path="$review" ;;
  *)  review_path="$PROJECT_DIR/$review" ;;
esac
[ -r "$review_path" ] || die "리뷰 산출물을 읽을 수 없습니다: $review_path"
tool_re="$(printf '%s' "$tool_name" | sed 's/\./\\./g')"
# 게이트와 같은 계약: **정확히 1회**. 여러 등급을 함께 적어 두고 낮은 쪽으로 발급받는
# 우회를 발급 시점에 막는다 — 게이트에서만 걸리면 "영수증이 있는데 왜 막히나"가 된다.
tuple_n="$(grep -cE "^발행-리뷰: tool=$tool_re digest=$digest tier=$tier\$" "$review_path" 2>/dev/null | tr -d ' ')"
[ -n "$tuple_n" ] || tuple_n=0
if [ "$tuple_n" != '1' ]; then
  printf '✗ 리뷰 산출물의 3튜플이 정확히 한 줄이 아닙니다(찾은 줄 %s개).\n' "$tuple_n" >&2
  printf '  다음 줄을 리뷰 산출물에 그대로 넣으세요:\n' >&2
  printf '  발행-리뷰: tool=%s digest=%s tier=%s\n' "$tool_name" "$digest" "$tier" >&2
  exit 1
fi

mkdir -p "$RECEIPTS_ACTIVE" "$RECEIPTS_USED" "$RECEIPTS_APPROVAL_ACTIVE" \
         "$RECEIPTS_APPROVAL_USED" "$RECEIPTS_QUARANTINE" 2>/dev/null \
  || die "영수증 디렉터리를 만들지 못했습니다: $RECEIPTS_DIR"

# **같은 digest 발급은 한 번에 하나만.** 아래 "이미 있나" 검사와 파일 생성 사이에 다른
# 발급이 끼어들면 nonce 가 달라 둘 다 성공하고, active 가 2개가 된 순간부터 게이트는
# 통째로 잠긴다(어느 것을 소비할지 알 수 없으므로 — 검수 실측). mkdir 은 원자적이다.
mkdir -p "$RECEIPTS_DIR/locks" 2>/dev/null
ISSUE_LOCK="$RECEIPTS_DIR/locks/$digest"
if ! mkdir "$ISSUE_LOCK" 2>/dev/null; then
  die "같은 digest 의 발급이 이미 진행 중입니다: $digest
    (그 프로세스가 죽었다면: rmdir '$ISSUE_LOCK')"
fi
trap 'rmdir "$ISSUE_LOCK" 2>/dev/null' EXIT

for f in "$RECEIPTS_ACTIVE/$digest".*; do
  [ -e "$f" ] || continue
  die "같은 digest 의 미소비 영수증이 이미 있습니다: $(basename "$f")
    두 개가 되면 게이트가 '어느 것을 소비할지 모른다'로 잠깁니다. 그 영수증을 쓰거나,
    잘못된 것이면 $RECEIPTS_QUARANTINE/ 로 옮기고 다시 발급하세요."
done

for f in "$RECEIPTS_USED/$digest".*; do
  [ -e "$f" ] || continue
  printf 'ℹ 이 digest 는 이미 한 번 소비됐습니다 — 재발행이라 **kty 재승인**이 필요합니다.\n' >&2
  printf '  승인: .claude/scripts/publish-approve.sh %s\n' "$digest" >&2
  break
done

ident="$(publish_serializer_identity)" || die 'python3 정체성을 읽지 못했습니다'
nonce="$(date -u +%Y%m%dT%H%M%S)-$(python3 -c 'import secrets; print(secrets.token_hex(4))' 2>/dev/null)"
# 앞뒤 하이픈도 막는다 — 파일명이 되는 값이라 옵션처럼 보이는 이름이 만들어지면 곤란하다.
case "$nonce" in
  *[!A-Za-z0-9-]* | '' | *--* | -* | *-) die "nonce 를 만들지 못했습니다: $nonce" ;;
esac

# 파일 생성은 **배타 모드**다(open "x") — 같은 이름이 이미 있으면 발급 자체가 실패한다.
# nonce 가 이름에 들어가므로 충돌은 곧 재사용 시도이고, 조용히 덮어쓰면 그 시도가 사라진다.
python3 -c '
import json, sys
path, tool, digest, tier, review, nonce, ident, issued = sys.argv[1:9]
rec = {"schema_version": 1, "tool_name": tool, "digest": digest, "tier": int(tier),
       "review_artifact": review, "nonce": nonce, "serializer_identity": ident,
       "issued_at": issued}
with open(path, "x") as fh:
    json.dump(rec, fh, ensure_ascii=False)
    fh.write("\n")
' "$RECEIPTS_ACTIVE/$digest.$nonce" "$tool_name" "$digest" "$tier" "$review" "$nonce" \
  "$ident" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  || die "영수증을 쓰지 못했습니다: $RECEIPTS_ACTIVE/$digest.$nonce"

printf '✓ 영수증 발급: %s\n' "active/$digest.$nonce"
printf '  도구: %s / 등급: tier%s / 리뷰: %s\n' "$tool_name" "$tier" "$review"
[ "$tier" = '2' ] && printf '  tier2 는 kty 승인이 추가로 필요합니다: .claude/scripts/publish-approve.sh %s\n' "$digest"
exit 0
