#!/usr/bin/env bash
# PreToolUse(Bash): "이 Bash 명령이 시작한 시각" 표식을 찍는다.
#
# mark-needs-audit 의 Bash 스윕이 이 표식보다 **새로 바뀐 파일**을 찾아 게이트를 세운다.
# 표식이 없으면 스윕은 아무것도 하지 않는다 — 그래서 이 훅이 등록되지 않은 설치본에서는
# Bash 스윕이 통째로 잠들고, 기존(Edit|Write) 동작만 남는다. 조용히 오작동하는 대신
# 조용히 예전 동작으로 돌아가는 쪽을 골랐다.
#
# **왜 PreToolUse 인가:** PostToolUse 에서 이전 스윕 시각을 재활용하면 창이
# [이전 명령 끝 ~ 지금] 이 되어, 그 사이 사람이 편집기로 고친 파일까지 이 명령이 쓴 것으로
# 잡힌다. 명령 **직전**에 찍으면 창이 정확히 명령 실행 구간이다.
#
# PreToolUse 지만 **절대 차단하지 않는다.** 표식을 못 찍어도 도구는 돌아야 한다 —
# 표식 실패의 대가는 그 한 번의 스윕이 없는 것이고, 차단의 대가는 세션이 멈추는 것이다.
# stdout 에 아무것도 쓰지 않는다(PreToolUse 의 stdout 은 도구 동작을 바꿀 수 있다).
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

HOOK_ID="pre:bash:window"
hook_disabled "$HOOK_ID" && exit 0

# 페이로드를 읽어 버린다 — 읽지 않으면 파이프가 막힐 수 있다.
cat >/dev/null 2>&1

mkdir -p "$STATE_DIR" 2>/dev/null
: > "$STATE_DIR/.bash-window" 2>/dev/null || true

exit 0
