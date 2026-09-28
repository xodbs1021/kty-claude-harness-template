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

# --allow-dirty 는 위치와 무관하게 받는다(sync.sh 가 끝에 붙여 넘긴다).
ALLOW_DIRTY=0
_args=()
for _a in "$@"; do
  case "$_a" in
    --allow-dirty) ALLOW_DIRTY=1 ;;
    *) _args+=("$_a") ;;
  esac
done
set -- ${_args[@]+"${_args[@]}"}

PROJECT_ARG="${1:?사용법: install.sh <프로젝트-경로> [프로젝트-이름] [--allow-dirty]}"
PROJECT="$(cd "$PROJECT_ARG" && pwd)"
NAME="${2:-$(basename "$PROJECT")}"
DST="$PROJECT/.claude"
TODAY="$(date +%Y-%m-%d)"
STAMP="$(date +%Y%m%d-%H%M%S)"   # 백업용 — 같은 날 재설치해도 안 덮이게

echo "== 하네스 설치: $NAME"
echo "   템플릿: $TPL_ROOT"
echo "   대상:   $DST"

# ── 0) 배포 안전 가드 — 대상(DST)을 건드리기 전에 정본부터 본다 ──────
# 측정 중(변이 락) 배포는 무조건 거부, dirty 정본은 --allow-dirty 옵트인.
# 근거·실사고·판정 불가의 방향은 scripts/deploy-guard.sh 정본 주석.
if [ -f "$TPL_ROOT/scripts/deploy-guard.sh" ]; then
  # shellcheck source=scripts/deploy-guard.sh
  . "$TPL_ROOT/scripts/deploy-guard.sh"
  deploy_guard "$TPL_ROOT" "$ALLOW_DIRTY" || exit 1
else
  # 부분 복사본 등으로 가드가 없으면 — 조용히 생략하지 않는다. 검사가 사라진 것을
  # 아무도 모르는 상태가 이 저장소가 부르는 조용한 실패다.
  echo "   ⚠ 배포 가드를 찾지 못했습니다($TPL_ROOT/scripts/deploy-guard.sh) — 락·dirty 검사 없이 진행합니다." >&2 || true
fi

# 개명 전 플래그 이행 — **배포되지 않는 이 스크립트가 맡는다.**
# 기존 설치본에 미처리 지식 플래그가 옛 이름으로 남아 있을 수 있는데, 새 훅은 새 이름만
# 보므로 그대로 두면 밀린 반영 의무가 **조용히 사라진다**(하네스를 갱신했을 뿐인데).
# 훅 쪽에서 옛 이름을 알게 하면 배포되는 글루가 구현체 이름을 다시 품어 층 경계 검사가
# 막는다 — 그래서 이행은 여기에 있다. 새 이름이 이미 있으면 **덮지 않고 이어붙인다.**
legacy_flag="$DST/.needs-$(printf 'vault')"
if [ -f "$legacy_flag" ]; then
  if [ -s "$legacy_flag" ]; then
    if cat "$legacy_flag" >> "$DST/.needs-knowledge" 2>/dev/null; then
      rm -f "$legacy_flag"
      echo "   플래그 이행 ✓  미처리 지식 반영 항목을 새 이름으로 옮겼습니다"
    else
      echo "   ⚠ 미처리 지식 반영 플래그를 새 이름으로 옮기지 못했습니다: $legacy_flag" >&2
      echo "     손으로 옮기지 않으면 그 항목의 반영 의무가 사라집니다." >&2
    fi
  else
    rm -f "$legacy_flag"
  fi
fi

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
  # **디렉터리를 통째로 바꾸므로 기존 내용물을 먼저 스테이징으로 옮겨 심는다.**
  # 이게 없으면 템플릿에 없는 사용자 파일(custom.sh·보조 파일·하위 디렉터리)이
  # 재설치마다 영구 삭제된다 — 파일 단위 cp 였던 구 구현에는 없던 회귀다.
  # 슬롯이 아니어도 사용자가 그 디렉터리에 둔 것을 하네스가 지울 권한은 없다.
  if [ -d "$DST/hooks" ]; then
    if ! cp -R "$DST/hooks/." "$hooks_stage/"; then
      rm -rf "$hooks_stage" "$hooks_backup"
      echo "✗ 기존 훅 디렉터리를 스테이징으로 복사하지 못했습니다 — 사용자 파일을 잃지 않으려고 중단합니다." >&2
      exit 1
    fi
  fi
  # 템플릿이 덮을 자리에 **심링크가 보존돼 있으면 먼저 치운다.** 안 그러면 cp 가 그 링크를
  # 따라가 링크 대상(디렉터리 밖 사용자 파일)을 덮어쓴다 — 보존하려다 파괴하는 셈이다.
  # 지우는 것은 스테이징의 링크뿐이고, 링크 대상 파일에는 손대지 않는다.
  for _t in "$SRC/hooks/"*.sh; do
    _b="$(basename "$_t")"
    [ -L "$hooks_stage/$_b" ] && rm -f "$hooks_stage/$_b"
  done
  cp "$SRC/hooks/"*.sh "$hooks_stage/"     # 템플릿 훅만 덮어쓴다
  chmod +x "$hooks_stage/"*.sh

  on_swap_signal() {   # $1=신호 이름  $2=종료 코드
    set +e             # 보고는 최선 노력, **종료 코드가 계약**이다
    # 플래그가 아니라 **파일시스템 실제 상태**로 판정한다. 첫 mv 가 끝났는데 플래그를
    # 세우기 전에 신호가 오는 창이 있고(bash 는 외부 명령 종료 뒤 대기 중인 trap 을
    # 먼저 실행한다), 플래그를 믿으면 그 창에서 복원하지 않고 백업까지 지운다.
    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
      if mv "$hooks_backup/hooks" "$DST/hooks"; then
        echo "[$1] 훅 교체 도중 중단 — 구판으로 되돌렸습니다." >&2
        rm -rf "$hooks_stage" "$hooks_backup"
      else
        # 복구가 실패했다. **백업을 지우지 않는다** — 그것이 유일한 사본이다.
        echo "[$1] 훅 교체 도중 중단됐고 **복구도 실패했습니다**." >&2
        echo "     구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
        echo "     손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
        rm -rf "$hooks_stage"
      fi
    else
      echo "[$1] 중단되었습니다 (훅 교체는 시작 전이거나 이미 끝났습니다)." >&2
      rm -rf "$hooks_stage" "$hooks_backup"
    fi
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
  fi
  if ! mv "$hooks_stage" "$DST/hooks"; then
    # rename2 실패. **성공으로 오진단하지 않는다** — 되돌리고 실패로 끝낸다.
    # 복구 mv 의 rc 를 확인한다. 실패했는데 "되돌렸습니다"를 찍고 백업을 지우면
    # 유일한 사본이 사라진다.
    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
      if mv "$hooks_backup/hooks" "$DST/hooks"; then
        echo "   구판 훅으로 되돌렸습니다." >&2
        rm -rf "$hooks_backup"
      else
        echo "   **복구도 실패했습니다.** 구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
        echo "   손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
      fi
    else
      rm -rf "$hooks_backup"
    fi
    rm -rf "$hooks_stage"
    echo "✗ 훅 디렉터리를 교체하지 못했습니다: $DST/hooks" >&2
    exit 1
  fi
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

# ── 1c) 전역 codex MCP 가드 (~/.claude/ — 프로젝트 밖 호출까지 커버, ADR-0017) ──
# 프로젝트 훅은 그 디렉토리 안에서만 발화한다. 전역 배선이 없으면 다른 폴더에서의
# mcp__codex__codex 호출이 모델·effort 계약을 통째로 우회한다(2026-08-11 감사 실증).
# 경로는 설치 시점의 $HOME 을 **리터럴 절대경로**로 굳힌다 — 훅 실행 환경에서 $HOME 이
# 비면 rc=127 fail-open 되는 결함의 재발 방지([cx] 2026-08-11). 기기를 옮기면
# install.sh 재실행이 새 기기 경로로 다시 굳힌다(멱등 + stale 경로 교정).
if [ -f "$SRC/hooks/guard-codex-mcp.sh" ]; then
  mkdir -p "$HOME/.claude/hooks"
  cp "$SRC/hooks/guard-codex-mcp.sh" "$HOME/.claude/hooks/guard-codex-mcp.sh"
  chmod +x "$HOME/.claude/hooks/guard-codex-mcp.sh"
  GLOBAL_SETTINGS="$HOME/.claude/settings.json"
  if [ -f "$GLOBAL_SETTINGS" ]; then
    cp "$GLOBAL_SETTINGS" "$GLOBAL_SETTINGS.bak-$STAMP"
  fi
  python3 - "$GLOBAL_SETTINGS" "$HOME/.claude/hooks/guard-codex-mcp.sh" <<'PYEOF'
import json, os, sys, tempfile
dst_path, script_path = sys.argv[1], sys.argv[2]
cmd = f'/bin/bash "{script_path}"'
# 소유권 판별은 부분 문자열이 아니라 **정확한 명령 꼴**로 — "guard-codex-mcp.sh" 를 품은
# 사용자 wrapper(env·인자 추가본)를 우리 것으로 오인해 교체하면 사용자 훅 파괴다([cx]).
def is_ours(h):
    c = h.get("command", "") if isinstance(h, dict) else ""
    return c.startswith('/bin/bash "') and c.endswith('/.claude/hooks/guard-codex-mcp.sh"')
try:
    cur = {}
    if os.path.exists(dst_path):
        with open(dst_path) as f:
            cur = json.load(f)
    # 타입을 **파일 변경 전에** 전부 검증한다 — 도중 예외는 부분 설치를 남긴다([cx]).
    if not isinstance(cur, dict): raise TypeError("settings 루트가 객체가 아님")
    hooks_map = cur.setdefault("hooks", {})
    if not isinstance(hooks_map, dict): raise TypeError("hooks 가 객체가 아님")
    lst = hooks_map.setdefault("PreToolUse", [])
    if not isinstance(lst, list): raise TypeError("hooks.PreToolUse 가 배열이 아님")
    # 같은 matcher 가 여러 항목이어도 전부 조사한다([cx] — 첫 항목만 보면 중복 배선).
    entries = [e for e in lst if isinstance(e, dict) and e.get("matcher") == "mcp__codex__codex"]
    ours = [h for e in entries for h in e.get("hooks", []) if is_ours(h)]
    if not entries:
        lst.append({"matcher": "mcp__codex__codex",
                    "hooks": [{"type": "command", "command": cmd, "timeout": 15}]})
        msg = "   전역 codex 가드 ✓  ~/.claude/settings.json 배선 추가"
    elif not ours:
        entries[0].setdefault("hooks", []).append(
            {"type": "command", "command": cmd, "timeout": 15})
        msg = "   전역 codex 가드 ✓  기존 matcher 에 훅 추가"
    elif any(h.get("command") != cmd for h in ours):
        for h in ours: h["command"] = cmd
        msg = "   전역 codex 가드 ✓  경로를 현 기기로 갱신"
    else:
        msg = "   전역 codex 가드    이미 배선됨 (멱등)"
    # 원자 교체 — live 파일 truncate 중 중단되면 전역 설정 전체가 깨진다([cx]).
    d = os.path.dirname(dst_path) or "."
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".settings.")
    with os.fdopen(fd, "w") as f:
        json.dump(cur, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, dst_path)
    print(msg)
except Exception as e:
    print(f"   ⚠ 전역 settings 병합 실패({e}) — 파일을 변경하지 않았습니다. 수동 배선 필요.",
          file=sys.stderr)
PYEOF
fi

# ── 1d) codex CLI 기본값 (~/.codex/config.toml — 가드의 "생략 = 안전" 전제) ──
# 가드 두 개(Bash·MCP)는 "model/effort 생략이면 config.toml 기본값이라 통과"로 판정한다.
# 이 파일이 없는 새 기기에서는 생략 호출이 codex 자체 기본 모델로 빠져나간다 — 전제 붕괴.
# 없으면 스캐폴드, 있는데 모델이 다르면 경고만(사용자 파일은 덮지 않는다 — 슬롯 원칙).
# 경고 출력 실패(stderr 닫힘 등)가 OR-리스트 끝에서 set -e 로 설치를 죽이지 않게([cx]).
warn() { printf '%s\n' "$1" >&2 || :; }
CODEX_CFG="$HOME/.codex/config.toml"
if [ ! -f "$CODEX_CFG" ]; then
  mkdir -p "$HOME/.codex"
  printf 'model = "gpt-5.6-sol"\nmodel_reasoning_effort = "xhigh"\n' > "$CODEX_CFG"
  echo "   codex 기본값 ✓  ~/.codex/config.toml 스캐폴드 (gpt-5.6-sol / xhigh)"
else
  # grep 은 TOML 을 모른다 — [profiles.*] 하위 model 오인·따옴표 변형 오탐([cx]).
  # tomllib 로 최상위 model + effort 둘 다 본다(effort 미검사도 [cx] 지적).
  codex_cfg_state="$(python3 - "$CODEX_CFG" <<'PYEOF'
import sys, tomllib
try:
    with open(sys.argv[1], "rb") as f:
        cfg = tomllib.load(f)
except Exception:
    print("parse-error"); sys.exit(0)
model_ok = cfg.get("model") == "gpt-5.6-sol"
effort_ok = cfg.get("model_reasoning_effort") == "xhigh"
print("ok" if model_ok and effort_ok else
      "model" if not model_ok else "effort")
PYEOF
)" || codex_cfg_state="parse-error"
  case "$codex_cfg_state" in
    ok)     echo "   codex 기본값    ~/.codex/config.toml 확인됨 (기존 유지)" ;;
    model)  warn "   ⚠ ~/.codex/config.toml 최상위 model 이 gpt-5.6-sol 이 아님 — 가드의 '생략 = 안전' 전제가 깨집니다(사용자 파일이라 안 덮음)." ;;
    effort) warn "   ⚠ ~/.codex/config.toml 의 model_reasoning_effort 가 xhigh 가 아님(또는 없음) — 생략 호출이 규정보다 약하게 돕니다(사용자 파일이라 안 덮음)." ;;
    *)      warn "   ⚠ ~/.codex/config.toml 파싱 실패 — 내용을 직접 확인하세요(사용자 파일이라 안 덮음)." ;;
  esac
fi

# ── 1e) 전역 의존 존재 점검 (경고만 — 설치는 사용자 몫) ─────────────
# SKILL.md 에 폴백은 있지만, 없다는 사실은 설치 시점에 아는 것이 가장 싸다.
[ -d "$HOME/.claude/rules/ecc" ] \
  || warn "   ⚠ ECC 룰(~/.claude/rules/ecc/) 없음 — 에이전트들이 참조하는 코딩 규칙이 비어 돕니다."
ls "$HOME/.claude/plugins/cache/"*/superpowers/* >/dev/null 2>&1 \
  || warn "   ⚠ superpowers 플러그인 미설치 — TDD·디버깅 방법론 스킬 폴백으로 동작합니다."
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  grep -qiE 'vault|볼트|second.?brain|지식' "$HOME/.claude/CLAUDE.md" \
    || warn "   ⚠ 전역 CLAUDE.md 에 지식 저장소 규약이 안 보입니다 — knowledge 게이트가 목적지를 모릅니다(harness.env 로 끌 수 있음)."
else
  warn "   ⚠ 전역 CLAUDE.md 없음 — knowledge 게이트가 목적지를 모릅니다(harness.env 로 끌 수 있음)."
fi

# ── 2) 슬롯 스캐폴드 (없을 때만 — 도메인은 사용자가 채운다) ──────────
if [ ! -f "$DST/harness/project-profile.md" ]; then
  sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
    > "$DST/harness/project-profile.md"
  echo "   슬롯 생성 ✓  harness/project-profile.md   ← 1~9절 채우세요"
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
        -e "s/{{한 줄 목표}}/($NAME 프로필 1절 참조)/g" \
        "$TPL_ROOT/template/CLAUDE.md.snippet"; } >> "$PROJECT/CLAUDE.md"
  echo "   CLAUDE.md ✓  하네스 포인터 append"
fi

echo ""
echo "== 완료. 다음 단계:"
echo "   1. $DST/harness/project-profile.md 의 1~9절 채우기 (도메인 슬롯 + 지식 진입점)"
echo "   2. $DST/harness/harness.env 의 HARNESS_TYPECHECK_CMD 채우기"
echo "   3. 새 Claude Code 세션 시작 (훅은 세션 시작 시 스냅샷 — 이번 세션엔 발화 안 함)"
echo "   4. 개발 요청 → harness-orchestrator 스킬이 파이프라인 실행"
