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

# 기존 설치본의 harness.env 에는 나중에 생긴 슬롯 키가 없다. **있는 값은 안 건드리되
# 없는 키는 알려준다** — 키가 없어도 기본값(켜짐)으로 동작하지만, 파일에 한 줄도 없으면
# 사용자는 그런 스위치가 있다는 것 자체를 모른다.
add_gate_key=0
if [ -f "$DST/harness/harness.env" ] \
   && ! grep -qE '^(export[[:space:]]+)?HARNESS_KNOWLEDGE_GATE=' "$DST/harness/harness.env" 2>/dev/null; then
  echo "   [슬롯 키 추가] harness/harness.env ← HARNESS_KNOWLEDGE_GATE (기본 켜짐, 기존 값 보존)"
  add_gate_key=1
  changed=$((changed + 1))
fi

if [ "$changed" -eq 0 ]; then
  echo "   (변경 없음 — 이미 최신)"
  exit 0
fi

# ── 3) 적용 (install.sh 멱등 재실행 — 슬롯·CLAUDE.md·settings는 보존/생략됨) ──
echo ""
"$TPL_ROOT/install.sh" "$PROJECT"

# 슬롯 키 덧붙이기 — install.sh **뒤**다. install 이 harness.env 를 새로 만들었다면
# 템플릿에 이미 키가 들어 있어 여기 올 일이 없다(위 판정은 install 이전 상태를 봤다).
#
# **덧붙이기만 한다.** 임시 파일에 쓰고 rename 하는 "원자적 쓰기"를 쓰지 않는 것은
# 의도적이다 — 그 방식은 검수에서 두 가지 계약 위반을 냈다. 임시 파일 글롭이 사용자의
# 백업 파일까지 지웠고, 기존 harness.env 가 심볼릭 링크면 일반 파일로 갈아치웠다.
# 슬롯은 프로젝트 소유이고 하네스는 그것을 **절대 덮지 않는다**가 더 강한 계약이다.
#
# 대가: append 는 원자적이지 않다. 중간에 끊기면 줄이 잘릴 수 있다. 다만 그 방향은
# 안전하다 — 판독이 실패하면 게이트는 **켜진다**(기본값 보존). 그래서 덧붙인 뒤
# 실제로 읽히는지 확인하고, 안 읽히면 조용히 넘어가지 않고 알린다.
if [ "$add_gate_key" -eq 1 ]; then
  envf="$DST/harness/harness.env"
  # 검증은 **완성된 줄 전체**를 요구한다. `^HARNESS_KNOWLEDGE_GATE=` 로만 보면
  # append 가 등호 직후에서 잘려 `HARNESS_KNOWLEDGE_GATE=` 만 남은 경우까지 통과시키는데,
  # 그 잘린 줄은 파서에게 **완벽히 유효한 "리터럴 빈 값"** 이라 게이트를 끈다.
  # 즉 "실패 방향은 안전하다"가 이 한 지점에서만 성립하지 않아서, 여기서 막는다.
  if { printf '\n# 지식 반영 게이트 (하네스가 나중에 추가한 슬롯). 끄려면 값을 비운다 —\n# "off" 라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다. 이 줄이 없어도 켜짐이다.\nHARNESS_KNOWLEDGE_GATE="on"\n' >> "$envf"; } 2>/dev/null \
     && grep -qxF 'HARNESS_KNOWLEDGE_GATE="on"' "$envf" 2>/dev/null; then
    echo "   슬롯 키 추가 ✓  harness/harness.env  HARNESS_KNOWLEDGE_GATE=\"on\""
  else
    echo "   ⚠ harness/harness.env 에 HARNESS_KNOWLEDGE_GATE 를 온전히 추가하지 못했습니다." >&2
    echo "     **파일 끝에 잘린 줄이 남았을 수 있습니다.** 그 상태로 두면 지식 게이트가" >&2
    echo "     꺼진 것으로 읽힐 수 있으니 파일 끝을 직접 확인하고, 다음 한 줄로 고치세요:" >&2
    echo '       HARNESS_KNOWLEDGE_GATE="on"' >&2
  fi
fi

echo ""
echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)의 **값**은 그대로입니다."
