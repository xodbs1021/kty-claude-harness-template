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
# ── 1a) 훅 교체는 파일 단위가 아니라 **디렉터리 rename 스왑** ────────
#
# 훅을 하나씩 덮으면 신·구가 섞인 중간 상태가 **반드시** 존재한다. 순서를 바꿔도 못
# 막는다 — 훅들이 _common.sh 를 공유하므로 어느 쪽을 먼저 바꾸든 창이 열린다. 그 창에서
# Claude 세션이 훅을 부르면 새 훅이 옛 _common.sh 를(또는 그 반대를) 읽는다.
#
# 그래서 스테이징 디렉터리를 만들고 **rename 2회**로 바꾼다. 혼합 상태가 원리적으로
# 불가능해진다. 대신 두 rename 사이에 훅이 **없는** 창이 생기는데, 그건 잘못된 훅이
# 도는 것보다 낫다(없으면 게이트가 안 설 뿐, 틀린 판정을 내지 않는다).
#
# 파생 계약 셋 — 전부 앞선 검수에서 **직전 수정이 만든 결함**으로 드러난 것들이다:
#   1. 신호 핸들러는 복구 후 **실제로 종료**해야 한다. 반환만 하면 후속 명령이 계속 돌아
#      mv 가 기존 디렉터리 **안으로** 중첩되고, 그러고도 "설치 성공"을 보고한다.
#      그리고 그 exit 에 도달하려면 핸들러 진입 직후 `set +e` 가 필요하다 — 진단 echo
#      하나가 실패해도(stderr 가 닫힌 채 실행 등) set -e 가 exit 전에 죽인다.
#   2. 백업 이름은 `mktemp -d` 로 유일성을 보장한다. `$$` 는 PID 재사용으로 선점될 수 있고,
#      선점되면 훅이 hooks/hooks/*.sh 로 깨지는데 메시지는 "되돌렸습니다"라고 말한다.
#   3. 자리를 비우려고 `rmdir` 을 먼저 하지 않는다 — 그 사이가 TOCTOU 창이다.
#      중첩을 **의도된 계약**으로 명시하면(mv "$DST/hooks" "$backup/hooks") 창이 없어진다.
#
# 남는 창(공시): 복구 **자체**가 다시 중단되면(SIGKILL·전원 차단) 훅 디렉터리가 없는
# 상태로 남는다. install.sh 재실행이 복구하지만 그 재실행도 중단되면 같은 상태가
# 반복된다. 이 창은 닫히지 않았다 — 닫으려면 이 스크립트 밖의 장치가 필요하다.
if [ -L "$DST/hooks" ]; then
  # 사용자가 훅 디렉터리를 심볼릭 링크로 두었다. rename 스왑은 그 링크를 **일반
  # 디렉터리로 갈아치운다** — 사용자의 배치를 하네스가 마음대로 바꾸는 것이라 하지 않는다.
  # 파일 단위 복사로 물러서고, 원자성을 못 지킨다는 사실을 **알린다**(조용히 물러서지 않는다).
  echo "   ⚠ .claude/hooks 가 심볼릭 링크입니다 — 링크를 보존하려고 파일 단위로 복사합니다." >&2
  echo "     교체 도중 신·구가 섞이는 창이 열립니다. 설치 중에는 Claude 세션을 띄우지 마세요." >&2
  cp "$SRC/hooks/"*.sh "$DST/hooks/"
  chmod +x "$DST/hooks/"*.sh
else
  hooks_stage="$(mktemp -d "$DST/.hooks-stage.XXXXXX")"
  hooks_backup="$(mktemp -d "$DST/.hooks-old.XXXXXX")"
  hooks_swapped=0     # 0=아직 안 옮김  1=옛것을 치웠고 새것은 아직 안 들어옴
  cp "$SRC/hooks/"*.sh "$hooks_stage/"
  chmod +x "$hooks_stage/"*.sh

  on_swap_signal() {   # $1=신호 이름  $2=종료 코드
    set +e             # 보고는 최선 노력, **종료 코드가 계약**이다
    if [ "$hooks_swapped" -eq 1 ] && [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
      mv "$hooks_backup/hooks" "$DST/hooks"
      echo "[$1] 훅 교체 도중 중단 — 구판으로 되돌렸습니다." >&2
    else
      echo "[$1] 중단되었습니다 (훅 교체는 시작 전이거나 이미 끝났습니다)." >&2
    fi
    rm -rf "$hooks_stage" "$hooks_backup"
    exit "$2"
  }
  # QUIT·HUP 도 잡는다: bash 는 trap 이 없으면 QUIT 를 **무시하고 rc=0 을 낸다** —
  # 중단됐는데 "성공"으로 보고되는 최악의 조합이다(실측).
  trap 'on_swap_signal INT  130' INT
  trap 'on_swap_signal TERM 143' TERM
  trap 'on_swap_signal QUIT 131' QUIT
  trap 'on_swap_signal HUP  129' HUP

  if [ -d "$DST/hooks" ]; then
    mv "$DST/hooks" "$hooks_backup/hooks"   # 중첩은 사고가 아니라 계약이다
    hooks_swapped=1
  fi
  if ! mv "$hooks_stage" "$DST/hooks"; then
    # rename2 실패. **성공으로 오진단하지 않는다** — 되돌리고 실패로 끝낸다.
    if [ "$hooks_swapped" -eq 1 ] && [ -d "$hooks_backup/hooks" ]; then
      mv "$hooks_backup/hooks" "$DST/hooks" && echo "   구판 훅으로 되돌렸습니다." >&2
    fi
    rm -rf "$hooks_stage" "$hooks_backup"
    echo "✗ 훅 디렉터리를 교체하지 못했습니다: $DST/hooks" >&2
    exit 1
  fi
  hooks_swapped=0
  trap - INT TERM QUIT HUP     # 여기부터는 되돌릴 것이 없다
  rm -rf "$hooks_backup"
fi
hook_count="$(ls "$DST/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')"

cp "$SRC/harness/principles.md" "$DST/harness/"
echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 $hook_count · 제0원칙"

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
  echo "                                                 (HARNESS_KNOWLEDGE_GATE 는 기본 켜짐)"
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
