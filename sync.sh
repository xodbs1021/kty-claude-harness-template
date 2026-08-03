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
for d in "$SRC/skills/"*/; do
  while IFS= read -r f; do preview "$f" "$DST/skills/$(basename "$d")/${f#"$d"}"; done < <(find "$d" -type f)
done
for f in "$SRC/hooks/"*.sh; do preview "$f" "$DST/hooks/$(basename "$f")"; done
preview "$SRC/harness/principles.md" "$DST/harness/principles.md"
for f in "$TPL_ROOT/global-agents/"*.md; do [ -f "$f" ] && preview "$f" "$HOME/.claude/agents/$(basename "$f")"; done

# settings.json 훅 배선 확인 — 파일 diff만 보면 "글루는 같은데 배선만 누락"(신규 훅이
# 기존 항목에 묶여 스킵된 경우)을 놓쳐 install이 아예 안 돌았다(2026-08-03 점검).
if [ -f "$DST/settings.json" ]; then
  # 텍스트 grep이 아니라 JSON 파싱으로 비교한다 — 파일 속 명령은 \" 이스케이프돼 있어
  # 문자열 비교는 전부 누락으로 오탐한다(구현 중 테스트에서 확인).
  while IFS= read -r cmd; do
    [ -z "$cmd" ] && continue
    echo "   [배선 누락] settings.json ← $cmd"
    changed=$((changed + 1))
  done < <(python3 -c '
import json, sys
with open(sys.argv[1]) as f: ours = json.load(f)
with open(sys.argv[2]) as f: cur = json.load(f)
# (event, matcher, command) 단위 비교 — command만 보면 엉뚱한 이벤트/매처에 붙은
# 훅을 "배선됨"으로 오인해 조기 종료한다([cx] 지적).
have = {(ev, e.get("matcher"), h.get("command"))
        for ev, entries in cur.get("hooks", {}).items()
        for e in entries for h in e.get("hooks", [])}
for ev, entries in ours.get("hooks", {}).items():
    for e in entries:
        for h in e.get("hooks", []):
            if (ev, e.get("matcher"), h.get("command")) not in have:
                print(ev + ": " + h.get("command", ""))' "$SRC/settings.json" "$DST/settings.json")
else
  echo "   [신규] settings.json 배선"
  changed=$((changed + 1))
fi

if [ "$changed" -eq 0 ]; then
  echo "   (변경 없음 — 이미 최신)"
  exit 0
fi

# ── 3) 적용 (install.sh 멱등 재실행 — 슬롯·CLAUDE.md·settings는 보존/생략됨) ──
echo ""
"$TPL_ROOT/install.sh" "$PROJECT"
echo ""
echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)은 그대로입니다."
