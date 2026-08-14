#!/usr/bin/env bash
# publish-approve.sh — 고위험(tier2) 발행과 재발행에 대한 **kty 승인** 발급. (ADR-0018)
#
# 사용법:  .claude/scripts/publish-approve.sh <digest>
#
# ── 이 스크립트는 사용자(kty)가 **자기 터미널에서** 실행한다 ────────────
# 에이전트가 이것을 실행하는 것은 규약 위반이다. 훅은 그것을 사전에 구별할 수 없고
# (같은 사용자로 도는 같은 명령이다), 구별할 수 있는 척하지도 않는다 — 자가 승인은
# completion-auditor 의 사후 감사 대상이다. 환경변수 방식(HARNESS_PUBLISH_APPROVE)은
# **폐기됐다**: 소비할 수가 없어 한 번 켜면 세션 내내 살아 있었다.
#
# 승인은 digest 하나에 묶인 **1회용**이다. 같은 발행을 다시 하려면 새 승인이 필요하다 —
# 훅이 소비 시점에 approval-active 에서 approval-used 로 원자 이동시키기 때문이다.
#
# 셸 이식성: macOS 기본 bash 는 3.2 다.

set -uo pipefail
# shellcheck source=../hooks/_common.sh
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../hooks" && pwd)/_common.sh"

die() { printf '✗ %s\n' "$1" >&2; exit 1; }

digest="${1-}"
[ -n "$digest" ] || die '사용법: publish-approve.sh <digest>  (digest 는 게이트 차단 메시지에 있습니다)'
case "$digest" in
  *[!0-9a-f]* | '') die "digest 는 64자리 소문자 16진수여야 합니다: $digest" ;;
esac
[ "${#digest}" -eq 64 ] || die "digest 는 64자리여야 합니다(현재 ${#digest}자리): $digest"

mkdir -p "$RECEIPTS_APPROVAL_ACTIVE" "$RECEIPTS_APPROVAL_USED" 2>/dev/null \
  || die "승인 디렉터리를 만들지 못했습니다: $RECEIPTS_APPROVAL_ACTIVE"

nonce="$(date -u +%Y%m%dT%H%M%S)-$(python3 -c 'import secrets; print(secrets.token_hex(4))' 2>/dev/null)"
case "$nonce" in
  *[!A-Za-z0-9-]* | '') die "nonce 를 만들지 못했습니다: $nonce" ;;
esac

# 배타 모드 생성 — 같은 nonce 가 이미 있으면 실패한다(재사용 시도를 덮어쓰지 않는다).
python3 -c '
import json, sys
path, digest, nonce, issued = sys.argv[1:5]
with open(path, "x") as fh:
    json.dump({"digest": digest, "nonce": nonce, "issued_at": issued}, fh)
    fh.write("\n")
' "$RECEIPTS_APPROVAL_ACTIVE/$nonce" "$digest" "$nonce" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  || die "승인 파일을 쓰지 못했습니다: $RECEIPTS_APPROVAL_ACTIVE/$nonce"

printf '✓ 승인 발급: approval-active/%s\n' "$nonce"
printf '  digest: %s\n' "$digest"
printf '  이 승인은 **1회용**입니다. 같은 발행을 다시 하려면 다시 승인해야 합니다.\n'
exit 0
