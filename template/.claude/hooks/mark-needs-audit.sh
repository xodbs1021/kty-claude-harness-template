#!/usr/bin/env bash
# PostToolUse(Edit|Write): 코드/설정 파일이 바뀌면 감사 플래그를 세운다.
#
# 이 플래그는 completion-auditor 가 검증을 통과시킨 뒤에만 지워진다.
# Stop 훅이 플래그를 보고 턴 종료를 막는다 → 감사자 호출이 강제된다.
#
# 검사 범위: 프로젝트 안 + 프로젝트 밖이라도 **다른 git 저장소 안**이면 그 저장소 기준으로
#            검사한다 (하네스 자신을 고치는 작업은 늘 별도 클론에서 일어나기 때문).
# 제외: git 저장소 밖(순수 임시 파일), $HOME·$HOME/.claude(전역 설정),
#       _workspace/(스크래치), .claude/(설치된 글루), 문서용 *.md
# 예외의 예외: agents/·skills/·harness/ 아래 *.md 는 **동작을 정의**하므로 코드로 취급한다.
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

# PROJECT_DIR 밖 편집 (2026-08-04 실사고 — 이 게이트의 유일한 실제 우회로였다).
# 예전엔 통째로 스킵했는데, 하네스 자신을 고치는 작업은 **늘** 별도 클론에서 일어난다.
# 즉 게이트가 정작 하네스 자체 개발만 못 지켰다. 다른 git 저장소 안의 파일이면 그
# 저장소 루트 기준으로 경로를 다시 잡아 검사를 잇고, 저장소 밖(순수 임시 파일)만 스킵한다.
case "$rel" in
  /*)
    # 양쪽을 물리 경로(pwd -P)로 맞춘 뒤에 자른다. git 은 실제 경로를 돌려주는데
    # 편집 경로는 심링크를 지나올 수 있어(macOS /var → /private/var, 홈 심링크),
    # 정규화 없이 자르면 접두사가 안 맞아 전부 "판정 불가"로 새어나간다(테스트로 확인).
    file_dir="$(cd "$(dirname "$file_path")" 2>/dev/null && pwd -P)"
    [ -z "$file_dir" ] && exit 0
    outside_root="$(git -C "$file_dir" rev-parse --show-toplevel 2>/dev/null)"
    [ -z "$outside_root" ] && exit 0
    outside_root="$(cd "$outside_root" 2>/dev/null && pwd -P)"
    [ -z "$outside_root" ] && exit 0
    # 전역 설정·닷파일 저장소는 프로젝트 작업이 아니다 — 여기까지 게이트를 걸면
    # settings.json 한 줄 고칠 때마다 완료 감사가 강제돼 훅이 자기 발등을 찍는다.
    home_p="$(cd "$HOME" 2>/dev/null && pwd -P)"
    case "$outside_root" in
      "$home_p"|"$home_p/.claude") exit 0 ;;
    esac
    rel="${file_dir}/$(basename "$file_path")"
    rel="${rel#"$outside_root"/}"
    case "$rel" in /*) exit 0 ;; esac   # 그래도 못 자르면 판정 불가 → 스킵
    ;;
esac

case "$rel" in
  _workspace/*|.claude/*) exit 0 ;;
esac

# 마크다운: 문서는 스킵하되 **동작을 정의하는 마크다운은 코드로 취급**한다
# (2026-08-04 실사고). 에이전트·스킬·원칙 정의는 전부 .md라, 일괄 제외하면 하네스
# 저장소에서 가장 흔한 변경(에이전트 정의 수정)에 플래그가 하나도 안 선다.
# 위 .claude/* 스킵이 먼저라, 프로젝트에 **설치된** 글루는 지금처럼 제외된다
# (설치본은 정본을 고쳐 sync 하는 게 규약이라 제자리 편집은 일시적이다).
case "$rel" in
  agents/*.md|*/agents/*.md) ;;       # 동작 정의 → 코드와 동일 취급
  skills/*.md|*/skills/*.md) ;;
  harness/*.md|*/harness/*.md) ;;
  *.md|*.markdown)        exit 0 ;;   # 순수 문서 → 스킵
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
