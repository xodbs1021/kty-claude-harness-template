#!/usr/bin/env bash
# PostToolUse(Edit|Write): 코드/설정 파일이 바뀌면 감사 플래그를 세운다.
#
# 이 플래그는 completion-auditor 가 검증을 통과시킨 뒤에만 지워진다.
# Stop 훅이 플래그를 보고 턴 종료를 막는다 → 감사자 호출이 강제된다.
#
# 제외: 프로젝트 밖(절대경로 잔존), _workspace/(스크래치), .claude/(하네스 자체), **/*.md(문서)
# 커밋 여부와 무관하게 동작하므로, "커밋해서 트리가 clean해졌으니 통과"
# 같은 구멍이 없다.
#
# PostToolUse 는 절대 차단하지 않는다(도구는 이미 실행됨). 항상 exit 0.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

HOOK_ID="post:edit:needs-audit"
hook_disabled "$HOOK_ID" && exit 0

payload="$(cat)"
file_path="$(printf '%s' "$payload" | json_get tool_input.file_path)"
[ -z "$file_path" ] && exit 0

rel="${file_path#"$PROJECT_DIR"/}"

# 듀얼 리뷰 게이트 (2026-08-03 kty — "리뷰가 필요한 모든 단계를 codex와 같이"의 기계화):
# 설계·계획 산출물이 저장되면 codex 듀얼 리뷰 플래그를 세운다. 코드 편집은 아래 공통
# 루프에서 같은 플래그를 세운다. Stop 훅이 codex 리뷰 산출물 없이는 턴 종료를 막는다.
case "$rel" in
  _workspace/00_design*.md|_workspace/01_plan*.md)
    mkdir -p "$STATE_DIR" 2>/dev/null
    if ! grep -qxF "$rel" "$DUALREVIEW_FLAG" 2>/dev/null; then
      printf '%s\n' "$rel" >> "$DUALREVIEW_FLAG" 2>/dev/null
    fi
    exit 0 ;;
esac

case "$rel" in
  /*)                     exit 0 ;;   # prefix strip 실패 = PROJECT_DIR 밖 → 스킵
  _workspace/*|.claude/*) exit 0 ;;
  *.md|*.markdown)        exit 0 ;;
esac

mkdir -p "$STATE_DIR" 2>/dev/null
# 세 완료 게이트를 동시에 세운다:
#   .needs-audit   → completion-auditor 강제 (Phase 6)
#   .needs-explain → change-explainer 강제 (Phase 5)
#   .needs-vault   → 볼트(second brain) 반영 또는 불요 사유 기록 강제 (2026-08-02 kty —
#                    세션 내내 볼트 Auto-Save가 기억에만 의존해 0회 이행된 실사고의 재발 방지)
# 각 게이트는 해당 작업이 실제로 끝난 뒤에만 수동으로 지워진다. Stop 훅이 셋 다 본다.
for flag in "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$VAULT_FLAG" "$DUALREVIEW_FLAG"; do
  if ! grep -qxF "$rel" "$flag" 2>/dev/null; then
    printf '%s\n' "$rel" >> "$flag" 2>/dev/null
  fi
done
exit 0
