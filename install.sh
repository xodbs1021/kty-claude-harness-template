#!/usr/bin/env bash
# install.sh — 하네스 템플릿을 프로젝트에 인스턴스화한다.
#
# 사용법: ./install.sh <프로젝트-경로> [프로젝트-이름]
#
# 동작 원칙:
#   글루(에이전트·오케스트레이터·훅·제0원칙)  → 복사·덮어씀 (재실행 = 글루 갱신)
#   슬롯(project-profile.md · harness.env)      → 없을 때만 스캐폴드, 절대 안 덮음
#   settings.json                               → 병합 (기존 훅 보존, 백업 생성)
#   CLAUDE.md                                    → 하네스 포인터 append (이미 있으면 생략)
#
# 전역 의존(참조, 복사 안 함): ECC 룰(~/.claude/rules/ecc/) · superpowers · claude-mem 플러그인.

set -euo pipefail

TPL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$TPL_ROOT/template/.claude"

PROJECT_ARG="${1:?사용법: install.sh <프로젝트-경로> [프로젝트-이름]}"
PROJECT="$(cd "$PROJECT_ARG" && pwd)"
NAME="${2:-$(basename "$PROJECT")}"
DST="$PROJECT/.claude"
TODAY="$(date +%Y-%m-%d)"

echo "== 하네스 설치: $NAME"
echo "   템플릿: $TPL_ROOT"
echo "   대상:   $DST"

# ── 1) 글루 복사 (덮어씀) ─────────────────────────────────────────────
mkdir -p "$DST/agents" "$DST/skills" "$DST/hooks" "$DST/harness"
cp "$SRC/agents/"*.md "$DST/agents/"
mkdir -p "$DST/skills/harness-orchestrator"
cp "$SRC/skills/harness-orchestrator/SKILL.md" "$DST/skills/harness-orchestrator/"
cp "$SRC/hooks/"*.sh "$DST/hooks/"
chmod +x "$DST/hooks/"*.sh
cp "$SRC/harness/principles.md" "$DST/harness/"
echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 오케스트레이터 · 훅 4 · 제0원칙"

# ── 2) 슬롯 스캐폴드 (없을 때만 — 도메인은 사용자가 채운다) ──────────
if [ ! -f "$DST/harness/project-profile.md" ]; then
  sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
    > "$DST/harness/project-profile.md"
  echo "   슬롯 생성 ✓  harness/project-profile.md   ← §1~§8 채우세요"
else
  echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
fi
if [ ! -f "$DST/harness/harness.env" ]; then
  cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
  echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
else
  echo "   슬롯 보존    harness/harness.env          (기존 유지)"
fi

# ── 3) settings.json 병합 (기존 훅 보존) ────────────────────────────
if [ -f "$DST/settings.json" ]; then
  cp "$DST/settings.json" "$DST/settings.json.bak-$TODAY"
  echo "   settings 백업 → settings.json.bak-$TODAY"
fi
python3 - "$DST/settings.json" "$SRC/settings.json" <<'PYEOF'
import json, os, sys
dst_path, src_path = sys.argv[1], sys.argv[2]
with open(src_path) as f:
    ours = json.load(f)
cur = {}
if os.path.exists(dst_path):
    with open(dst_path) as f:
        cur = json.load(f)
hooks = cur.setdefault("hooks", {})
added = 0
for event, entries in ours.get("hooks", {}).items():
    lst = hooks.setdefault(event, [])
    existing_cmds = {
        h.get("command")
        for entry in lst
        for h in entry.get("hooks", [])
    }
    for entry in entries:
        cmds = [h.get("command") for h in entry.get("hooks", [])]
        if any(c in existing_cmds for c in cmds):
            continue  # 이미 배선됨 (멱등)
        lst.append(entry)
        added += 1
with open(dst_path, "w") as f:
    json.dump(cur, f, ensure_ascii=False, indent=2)
    f.write("\n")
print(f"   settings.json ✓  훅 배선 {added}건 추가 (기존 훅 보존)")
PYEOF

# ── 4) CLAUDE.md 하네스 포인터 ───────────────────────────────────────
if [ -f "$PROJECT/CLAUDE.md" ] && grep -q "harness-orchestrator" "$PROJECT/CLAUDE.md"; then
  echo "   CLAUDE.md    포인터 이미 있음 (생략)"
else
  { [ -f "$PROJECT/CLAUDE.md" ] && [ -s "$PROJECT/CLAUDE.md" ] && echo ""; \
    sed -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{YYYY-MM-DD}}/$TODAY/g" \
        -e "s/{{한 줄 목표}}/($NAME 프로필 §1 참조)/g" \
        "$TPL_ROOT/template/CLAUDE.md.snippet"; } >> "$PROJECT/CLAUDE.md"
  echo "   CLAUDE.md ✓  하네스 포인터 append"
fi

echo ""
echo "== 완료. 다음 단계:"
echo "   1. $DST/harness/project-profile.md 의 §1~§8 채우기 (도메인 슬롯)"
echo "   2. $DST/harness/harness.env 의 HARNESS_TYPECHECK_CMD 채우기"
echo "   3. 새 Claude Code 세션 시작 (훅은 세션 시작 시 스냅샷 — 이번 세션엔 발화 안 함)"
echo "   4. 개발 요청 → harness-orchestrator 스킬이 파이프라인 실행"
