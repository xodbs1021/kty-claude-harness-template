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
STAMP="$(date +%Y%m%d-%H%M%S)"   # 백업용 — 같은 날 재설치해도 안 덮이게

echo "== 하네스 설치: $NAME"
echo "   템플릿: $TPL_ROOT"
echo "   대상:   $DST"

# ── 1) 글루 복사 (덮어씀) ─────────────────────────────────────────────
mkdir -p "$DST/agents" "$DST/skills" "$DST/hooks" "$DST/harness"
cp "$SRC/agents/"*.md "$DST/agents/"
# 스킬은 디렉토리째 전부 복사한다(references/·scripts/ 포함) — 특정 스킬명·특정 파일만
# 복사하는 하드코딩은 readable-writing 미배포 버그(2026-08-03 점검)를 낳았다
skill_count=0
for skill_dir in "$SRC/skills/"*/; do
  skill_name="$(basename "$skill_dir")"
  mkdir -p "$DST/skills/$skill_name"
  cp -R "$skill_dir"/. "$DST/skills/$skill_name/"
  skill_count=$((skill_count + 1))
done
cp "$SRC/hooks/"*.sh "$DST/hooks/"
chmod +x "$DST/hooks/"*.sh
cp "$SRC/harness/principles.md" "$DST/harness/"
echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 4 · 제0원칙"

# ── 1b) 전역 에이전트 배포 (~/.claude/agents/ — 프로젝트 무관 글루, 덮어씀) ──
# 정본은 이 repo의 global-agents/ (전역 디렉토리는 버전 관리가 안 되므로 — ADR-0002)
GLOBAL_SRC="$TPL_ROOT/global-agents"
if [ -d "$GLOBAL_SRC" ] && ls "$GLOBAL_SRC"/*.md >/dev/null 2>&1; then
  mkdir -p "$HOME/.claude/agents"
  cp "$GLOBAL_SRC"/*.md "$HOME/.claude/agents/"
  echo "   전역 에이전트 ✓  $(ls "$GLOBAL_SRC"/*.md | wc -l | tr -d ' ')종 → ~/.claude/agents/"
fi

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
  cp "$DST/settings.json" "$DST/settings.json.bak-$STAMP"
  echo "   settings 백업 → settings.json.bak-$STAMP"
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
        (entry.get("matcher"), h.get("command"))
        for entry in lst
        for h in entry.get("hooks", [])
    }
    for entry in entries:
        # (matcher, command) 단위 병합 — "항목에 하나라도 있으면 전체 스킵"은 같은 항목에 묶인
        # 새 훅(guard-codex-invocation)이 기존 설치본에 영영 배선되지 않는 버그였고(2026-08-03),
        # command만 보면 엉뚱한 matcher에 붙은 훅을 "배선됨"으로 오인한다([cx] 지적).
        missing = [h for h in entry.get("hooks", [])
                   if (entry.get("matcher"), h.get("command")) not in existing_cmds]
        if not missing:
            continue  # 전부 배선됨 (멱등)
        target = next((e for e in lst if e.get("matcher") == entry.get("matcher")), None)
        if target is not None:
            target.setdefault("hooks", []).extend(missing)
        else:
            new_entry = {k: v for k, v in entry.items() if k != "hooks"}
            new_entry["hooks"] = missing
            lst.append(new_entry)
        added += len(missing)
        existing_cmds.update((entry.get("matcher"), h.get("command")) for h in missing)
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
