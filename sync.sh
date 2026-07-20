#!/usr/bin/env bash
# sync.sh — 템플릿 최신본을 받아 프로젝트의 글루만 갱신한다. 슬롯은 절대 안 건드린다.
#
# 사용법: ./sync.sh <프로젝트-경로> [--no-pull]
#   --no-pull : 원격에서 안 당기고 로컬 정본만으로 갱신
#
# 원리: install.sh 가 멱등(글루=덮어씀, 슬롯=보존)이므로, pull 후 재실행이 곧 sync다.
# 적용 전에 무엇이 바뀌는지 diff 요약을 먼저 보여준다.

set -euo pipefail

TPL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$TPL_ROOT/template/.claude"

PROJECT_ARG="${1:?사용법: sync.sh <프로젝트-경로> [--no-pull]}"
PROJECT="$(cd "$PROJECT_ARG" && pwd)"
DST="$PROJECT/.claude"

# ── 1) 정본 갱신 ─────────────────────────────────────────────────────
if [ "${2:-}" != "--no-pull" ] && git -C "$TPL_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  if git -C "$TPL_ROOT" pull --ff-only 2>/dev/null; then
    echo "== 템플릿 정본 pull 완료"
  else
    echo "== pull 실패(원격 없음/오프라인/충돌) — 로컬 정본으로 진행"
  fi
fi

# ── 2) 글루 diff 미리보기 (슬롯은 비교 대상에서 제외) ───────────────
echo "== 갱신될 글루 diff:"
changed=0
preview() {  # preview <원본> <대상>
  if [ ! -f "$2" ]; then
    echo "   [신규] ${2#"$DST"/}"
    changed=$((changed + 1))
  elif ! diff -q "$1" "$2" >/dev/null 2>&1; then
    echo "   [변경] ${2#"$DST"/}"
    changed=$((changed + 1))
  fi
}
for f in "$SRC/agents/"*.md; do preview "$f" "$DST/agents/$(basename "$f")"; done
preview "$SRC/skills/harness-orchestrator/SKILL.md" "$DST/skills/harness-orchestrator/SKILL.md"
for f in "$SRC/hooks/"*.sh; do preview "$f" "$DST/hooks/$(basename "$f")"; done
preview "$SRC/harness/principles.md" "$DST/harness/principles.md"
for f in "$TPL_ROOT/global-agents/"*.md; do [ -f "$f" ] && preview "$f" "$HOME/.claude/agents/$(basename "$f")"; done

if [ "$changed" -eq 0 ]; then
  echo "   (변경 없음 — 이미 최신)"
  exit 0
fi

# ── 3) 적용 (install.sh 멱등 재실행 — 슬롯·CLAUDE.md·settings는 보존/생략됨) ──
echo ""
"$TPL_ROOT/install.sh" "$PROJECT"
echo ""
echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)은 그대로입니다."
