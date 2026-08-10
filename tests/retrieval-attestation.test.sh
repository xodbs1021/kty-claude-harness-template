#!/usr/bin/env bash
# retrieval-attestation.test.sh — Stop 훅의 **회수 표명 게이트**(stop:retrieval, ADR-0013) 회귀 방어.
#
#   "설계·계획 산출물(00_design*·01_plan*)이 저장된 턴은, 그 첫 줄이
#    `사전 결정 회수:` 표명 형식을 지키기 전엔 끝낼 수 없다. 지키면 게이트가 스스로 풀린다."
#
# 이 게이트는 **형식만** 본다 — 진짜 읽었는지는 기계가 못 본다(ADR-0013 ④).
# 실패 방향이 게이트마다 다르다:
#   위음성 — 표명 없는 산출물이 조용히 통과한다. 이 게이트가 존재하는 이유의 반대
#   상태 오염 — 자동 해제·재평가·지문이 기존 게이트 기계(조기 종료·예산·결정 게이트)를
#              깨는 것. 설계 검수 2라운드의 차단급 전부가 이 축이었다 — 그래서 이 파일의
#              절반이 "다른 게이트가 멀쩡한가"를 잰다
#
# **판정 규칙의 사본을 두지 않는다.** 훅 자신을 돌려 차단 여부·메시지·플래그 상태로 잰다.
# **rc 만으로 판정하지 않는다.** 회수 게이트가 통과해도 뒤의 감사 게이트가 같은 rc=2 를
# 내므로, 어느 게이트가 말했는지는 메시지로만 갈린다. 통과 기대 케이스는 후속 게이트가
# **실제로 말했는지**까지 요구한다 — 안 하면 훅이 앞에서 죽어도 초록이 난다.
#
# **공시된 측정 공백:** 3.4 의 exit 0 경로에 있는 decision_note 방출은 현행 발동 규칙
# 아래서 도달 불가다 — decision_note 가 서려면 4종 플래그 중 하나가 서야 하는데, 그 플래그가
# work_pending 을 참으로 유지해 exit 0 에 못 간다. 방출 코드는 발동 규칙이 바뀌는 날을 위한
# 방어로 남겼고, 그 제거 변이는 원리적으로 초록이다(ADR-0012 의 "모르는 rc" 공백과 같은 부류).
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. mapfile·연관배열·${var,,} 금지.

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOKS="$REPO_ROOT/template/.claude/hooks"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (payload 픽스처 의존)" >&2; exit 1; }
for f in verify-before-stop.sh mark-needs-audit.sh _common.sh; do
  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
done

TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
# chmod 000 픽스처(r13)가 있으므로 되돌린 뒤 지운다.
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

ran=0; pass=0; fail=0
RC=999; ERR=''; OUT=''; DID_RUN=0

# 판정 토큰 — 각 게이트 메시지의 고유 문구. 어느 게이트가 말했는지는 이걸로만 갈린다.
TOK_RET='회수 표명이 없습니다'
TOK_RET_FLAGFAIL='회수 표명 검사 불가'
TOK_AUDIT='completion-auditor 미실행'
TOK_PUSH='커밋이 원격에 없습니다'
TOK_KNOW='지식 저장소 반영 미확인'
TOK_DUAL='codex 듀얼 리뷰 미수행'
TOK_DECISION='혼자 정한 것이 있는데'
TOK_NOTE='결정 게이트 생략'
TOK_BRICK='세션 벽돌 방지'

report() {
  ran=$((ran + 1))
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}

contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

# --- 픽스처 --------------------------------------------------------------

# new_project — 케이스마다 독립 프로젝트(mktemp — 명령 치환 카운터는 서브셸에 갇힌다).
# 타입체크·지식게이트는 리터럴로 비운다: 이 파일이 재는 것은 회수 게이트와 그 결합뿐이고,
# 앞 게이트가 먼저 막으면 케이스가 회수 게이트에 도달조차 못 한 채 기대값이 우연히 맞는다.
# 지식 게이트를 켤 케이스(r23)만 인자로 켠다.
new_project() {   # $1 = 지식게이트 값(비우면 꺼짐)
  local p
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
  mkdir -p "$p/.claude/hooks" "$p/.claude/harness" "$p/_workspace" || return 1
  cp "$HOOKS/_common.sh" "$HOOKS/verify-before-stop.sh" "$HOOKS/mark-needs-audit.sh" "$p/.claude/hooks/" || return 1
  printf 'HARNESS_TYPECHECK_CMD=""\nHARNESS_KNOWLEDGE_GATE="%s"\n' "${1-}" \
    > "$p/.claude/harness/harness.env" || return 1
  printf '%s\n' "$p"
}

# mk_tx <경로> <neutral|marker> — 최소 대화 기록. 결정 게이트(3.2)가 이 파일을 읽는다.
#   neutral = 표지 어휘 없는 발화 (결정 게이트 침묵)
#   marker  = 표지 어휘 + 서술형 (결정 게이트가 무장돼 있으면 차단)
mk_tx() {
  local tp="$1" kind="$2"
  printf '%s\n' '{"type":"user","isSidechain":false,"message":{"role":"user","content":"작업해줘"}}' > "$tp" || return 1
  case "$kind" in
    neutral) printf '%s\n' '{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"확인했습니다."}]}}' >> "$tp" ;;
    marker)  printf '%s\n' '{"type":"assistant","isSidechain":false,"message":{"content":[{"type":"text","text":"이건 범위 밖이라 그대로 뒀습니다."}]}}' >> "$tp" ;;
  esac
}

# run_stop <프로젝트> <transcript경로|""> [env 인자...]
run_stop() {
  local p="$1" tp="$2"
  shift 2
  local errf="$TMPROOT/err.$$" outf="$TMPROOT/out.$$" payf="$TMPROOT/pay.$$"
  RC=999; ERR=''; OUT=''; DID_RUN=1
  python3 -c '
import json, sys
d = {"stop_hook_active": False}
if sys.argv[1]:
    d["transcript_path"] = sys.argv[1]
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    fh.write(json.dumps(d))' "$tp" "$payf"
  # cwd 를 프로젝트가 아닌 곳(TMPROOT)으로 둔다 — 상대경로 항목을 cwd 기준으로 여는
  # 구현이면 여기서 전부 "소실"이 되어 r11 이 빨개진다. 이 디렉토리 선택이 곧 픽스처다.
  ( cd "$TMPROOT" && env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$p" \
      bash "$p/.claude/hooks/verify-before-stop.sh" <"$payf" >"$outf" 2>"$errf" )
  RC=$?
  rm -f "$payf"
  ERR="$(cat "$errf" 2>/dev/null)"
  OUT="$(cat "$outf" 2>/dev/null)"
  rm -f "$errf" "$outf"
}

# set_flag <프로젝트> <이름> <값...> — 플래그에 줄들을 기록한다.
set_flag() {
  local p="$1" name="$2"; shift 2
  : > "$p/.claude/.needs-$name"
  local v
  for v in "$@"; do printf '%s\n' "$v" >> "$p/.claude/.needs-$name"; done
}

# mk_doc <경로> <첫줄|"EMPTY"> — 산출물 파일을 만든다.
mk_doc() {
  local f="$1" first="$2"
  case "$first" in
    EMPTY) : > "$f" ;;
    *) printf '%s\n본문.\n' "$first" > "$f" ;;
  esac
}

GOOD_FIRST='사전 결정 회수: docs/decisions/'
flag_gone() { [ ! -e "$1/.claude/.needs-retrieval" ]; }

# --- 케이스 --------------------------------------------------------------
# 번호는 설계서 7절의 목록과 1:1 이다. 새 케이스는 뒤에만 붙인다.

r01() { # 정상 첫 줄 → 회수 침묵 + 자동 해제 + 감사 게이트 도달.
  local name='r01 정상 첫 줄 → 통과 + 플래그 자동 해제' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" "$GOOD_FIRST"
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if [ "$DID_RUN" -ne 1 ];             then why='훅 미실행'
  elif contains "$ERR" "$TOK_RET";     then why='위양성 — 회수 게이트가 막았다'
  elif [ "$RC" -ne 2 ];                then why="rc=$RC (기대 2 — 감사 게이트)"
  elif ! contains "$ERR" "$TOK_AUDIT"; then why="감사 게이트 미도달 = 아무것도 안 쟀다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! flag_gone "$p";               then why='플래그가 자동 해제되지 않았다'
  fi
  report "$name" "$why"
}

r02() { # `없음(사유)` 형식도 정상 표명이다.
  local name='r02 없음(사유) 형식 → 통과' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '사전 결정 회수: 없음(진입점 미설정 — 새 프로젝트)'
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if [ "$DID_RUN" -ne 1 ];             then why='훅 미실행'
  elif contains "$ERR" "$TOK_RET";     then why='위양성 — 회수 게이트가 막았다'
  elif ! contains "$ERR" "$TOK_AUDIT"; then why='감사 게이트 미도달'
  elif ! flag_gone "$p";               then why='플래그 미해제'
  fi
  report "$name" "$why"
}

r03() { # 표명 없음 → 차단. 첫 줄이 `사전` 으로 시작하지만 완전한 접두어는 아니다 —
        # 패턴을 `사전` 따위로 느슨하게 만드는 변이가 이 행에서 빨개진다.
  local name='r03 첫 줄에 표명 없음 → 차단 + 파일명' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '사전 결정 회수 없이 작성했다.'
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if [ "$DID_RUN" -ne 1 ];                       then why='훅 미실행'
  elif [ "$RC" -ne 2 ];                          then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_RET";             then why="회수 게이트가 막지 않았다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! contains "$ERR" '_workspace/00_design.md'; then why='불량 파일명이 메시지에 없다'
  elif contains "$ERR" "$TOK_AUDIT";             then why='차단인데 감사 게이트까지 흘러갔다'
  elif flag_gone "$p";                           then why='불량인데 플래그가 해제됐다'
  fi
  report "$name" "$why"
}

r04() { # 빈 파일 → 차단.
  local name='r04 빈 파일 → 차단' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" EMPTY
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" "$TOK_RET"; then why='차단하지 않았다'
  elif ! contains "$ERR" '비었';   then why='사유(빈 파일)가 메시지에 없다'
  fi
  report "$name" "$why"
}

r05() { # 접두어만 있고 내용이 없다 → 차단.
  local name='r05 접두어 뒤 내용 없음 → 차단' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '사전 결정 회수:   '
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" "$TOK_RET";      then why='차단하지 않았다'
  elif ! contains "$ERR" '내용이 없음'; then why='사유(내용 없음)가 메시지에 없다'
  fi
  report "$name" "$why"
}

r06() { # 01_plan* 도 같은 계약이다.
  local name='r06 01_plan 산출물도 대상 → 차단' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/01_plan.md" '계획: 이렇게 한다.'
  set_flag "$p" retrieval '_workspace/01_plan.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" "$TOK_RET"; then why='차단하지 않았다'
  elif ! contains "$ERR" '_workspace/01_plan.md'; then why='파일명이 없다'
  fi
  report "$name" "$why"
}

r07() { # 여러 파일 중 하나만 불량 → 차단하되 불량만 지목. 그리고 **듀얼리뷰 플래그가
        # 함께 서 있어도 회수 게이트가 먼저 말한다** — 게이트를 3.5 뒤로 옮기는 변이가
        # 여기서 빨개진다(순서는 계약이다 — ADR-0013 Stop 실행 순서).
  local name='r07 다중 파일 부분 불량 → 불량만 지목 + 3.5 보다 앞' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" "$GOOD_FIRST"
  mk_doc "$p/_workspace/01_plan.md" '표명 없는 계획이다.'
  set_flag "$p" retrieval '_workspace/00_design.md' '_workspace/01_plan.md'
  set_flag "$p" dualreview '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" "$TOK_RET";                    then why="회수 게이트가 먼저 막지 않았다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif contains "$ERR" "$TOK_DUAL";                   then why='듀얼리뷰 게이트가 먼저/함께 말했다 (순서 위반)'
  elif ! contains "$ERR" '_workspace/01_plan.md';     then why='불량 파일명이 없다'
  elif contains "$ERR" "00_design.md — ";             then why='정상 파일이 불량으로 지목됐다'
  fi
  report "$name" "$why"
}

r08() { # 플래그 항목의 파일이 사라졌다 → 그 항목은 건너뛰고 해제한다(공시된 한계).
        # 이 동작이 바뀌면(차단으로) 아카이브 턴이 벽돌이 된다 — 계약의 케이스화.
  local name='r08 소실 항목 → 스킵 + 해제' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  set_flag "$p" retrieval '_workspace/00_design.md'   # 파일은 만들지 않는다
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if contains "$ERR" "$TOK_RET";       then why='소실 항목을 차단했다'
  elif ! contains "$ERR" "$TOK_AUDIT"; then why='감사 게이트 미도달'
  elif ! flag_gone "$p";               then why='플래그가 해제되지 않았다 (갇힘 경로)'
  fi
  report "$name" "$why"
}

r09() { # 게이트를 끄면 검사도 갇힘도 없다 — 같은 상태에서 **다음 턴**(다른 플래그가
        # 다 지워진 읽기 전용 턴)도 조기 종료로 통과해야 한다. retrieval_pending 이
        # 훅 비활성을 접지 않으면 남은 플래그가 조기 종료를 막아 빈 감사 차단이 난다.
  local name='r09 stop:retrieval 비활성 → 검사 생략 + 다음 턴 조기 종료' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '표명 없는 설계다.'
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl" ECC_DISABLED_HOOKS=stop:retrieval
  if contains "$ERR" "$TOK_RET"; then why='비활성인데 회수 게이트가 말했다'
  elif ! contains "$ERR" "$TOK_AUDIT"; then why='감사 게이트 미도달'
  else
    rm -f "$p/.claude/.needs-audit"     # 다음 턴: 감사까지 끝난 읽기 전용 턴
    run_stop "$p" "$p/tx.jsonl" ECC_DISABLED_HOOKS=stop:retrieval
    if [ "$RC" -ne 0 ]; then why="다음 턴 rc=$RC (기대 0 — 남은 회수 플래그가 조기 종료를 막았다): $(printf '%s' "$ERR" | head -1 | head -c 90)"
    fi
  fi
  report "$name" "$why"
}

r10() { # 발동 조건은 플래그다 — 파일만 있고 플래그가 없으면 검사하지 않는다.
  local name='r10 플래그 없음 → 발동 안 함' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '표명 없는 설계다.'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if contains "$ERR" "$TOK_RET"; then why='플래그 없이 발동했다'
  elif ! contains "$ERR" "$TOK_AUDIT"; then why='감사 게이트 미도달'
  fi
  report "$name" "$why"
}

r11() { # 상대경로 항목은 $PROJECT_DIR 기준으로 열린다. run_stop 이 cwd 를 TMPROOT 로
        # 두므로, cwd 기준으로 여는 구현이면 파일이 "소실"로 오인돼 이 차단이 사라진다.
  local name='r11 상대경로 항목 — 다른 cwd 에서도 판정' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '표명 없는 설계다.'
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" "$TOK_RET"; then why="차단하지 않았다 (상대경로가 cwd 기준으로 열렸을 가능성): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

r12() { # 절대경로 항목(프로젝트 밖) + 상대·절대 혼재. 밖 파일이 불량이면 차단.
  local name='r12 절대경로·혼재 항목 판정' why=''
  local p out; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  out="$(mktemp -d "$TMPROOT/outside.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  mkdir -p "$out/_workspace"
  mk_doc "$p/_workspace/00_design.md" "$GOOD_FIRST"
  mk_doc "$out/_workspace/01_plan.md" '표명 없는 밖 계획이다.'
  set_flag "$p" retrieval '_workspace/00_design.md' "$out/_workspace/01_plan.md"
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" "$TOK_RET";              then why='차단하지 않았다'
  elif ! contains "$ERR" "$out/_workspace/01_plan.md"; then why='밖 불량 파일명이 없다'
  fi
  report "$name" "$why"
}

r13() { # fail-closed 두 축: ① 플래그 파일 자체를 읽을 수 없다 → 차단(사유 포함)
        #                   ② 대상 파일이 있는데 읽을 수 없다 → 불량으로 차단
  local name='r13 읽기 실패는 통과가 아니다 (플래그·대상)' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" "$GOOD_FIRST"
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  chmod 000 "$p/.claude/.needs-retrieval"
  run_stop "$p" "$p/tx.jsonl"
  chmod 644 "$p/.claude/.needs-retrieval" 2>/dev/null
  if ! contains "$ERR" "$TOK_RET_FLAGFAIL"; then
    why="플래그 읽기 실패를 차단하지 않았다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  else
    local p2; p2="$(new_project)" || { report "$name" '픽스처 실패(2)'; return 0; }
    mk_doc "$p2/_workspace/00_design.md" "$GOOD_FIRST"
    chmod 000 "$p2/_workspace/00_design.md"
    set_flag "$p2" retrieval '_workspace/00_design.md'
    set_flag "$p2" audit 'src/x.ts'
    mk_tx "$p2/tx.jsonl" neutral
    run_stop "$p2" "$p2/tx.jsonl"
    chmod 644 "$p2/_workspace/00_design.md" 2>/dev/null
    if ! contains "$ERR" "$TOK_RET"; then why='대상 읽기 실패를 차단하지 않았다'
    elif ! contains "$ERR" '읽을 수 없음'; then why='사유(읽기 실패)가 없다'
    fi
  fi
  report "$name" "$why"
}

r14() { # 불량 집합이 줄어드는 실제 진전은 이 게이트의 예산 카운터를 리셋한다.
        # 예산 키에서 목록을 빼는 변이가 여기서 빨개진다(2회째가 2/3 로 나온다).
  local name='r14 불량을 하나 고치면 카운터 리셋 (1/3 유지)' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '표명 없음 A.'
  mk_doc "$p/_workspace/01_plan.md" '표명 없음 B.'
  set_flag "$p" retrieval '_workspace/00_design.md' '_workspace/01_plan.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" '차단 1/'; then why="1회차가 1/N 이 아니다: $(printf '%s' "$ERR" | tail -1 | head -c 60)"
  else
    mk_doc "$p/_workspace/00_design.md" "$GOOD_FIRST"    # A 를 고쳤다 = 진전
    run_stop "$p" "$p/tx.jsonl"
    if ! contains "$ERR" "$TOK_RET";    then why='2회차에 차단하지 않았다'
    elif ! contains "$ERR" '차단 1/';   then why="진전인데 카운터가 리셋되지 않았다: $(printf '%s' "$ERR" | tail -1 | head -c 60)"
    fi
  fi
  report "$name" "$why"
}

r15() { # 예산 소진 시 회수 플래그도 정리 목록에 있다 — rm 과 changed 나열 양쪽.
        # changed 단언은 **불량 집합에 없는 소실 항목**으로 잰다: 불량 경로는 예산 소진
        # 메시지의 게이트 식별자("같은 지점(retrieval:...)")에도 실려서, changed 나열에서
        # 회수 플래그를 빼도 같은 파일명이 다른 경로로 출력돼 변이가 가려진다(실측 —
        # "데이터 중복이 방어를 가린다" 부류. m13 이 이 단언으로만 빨개진다).
  local name='r15 예산 소진 정리에 회수 플래그 포함' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '표명 없음.'
  set_flag "$p" retrieval '_workspace/00_design.md' '_workspace/01_plan_gone.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"; run_stop "$p" "$p/tx.jsonl"; run_stop "$p" "$p/tx.jsonl"
  run_stop "$p" "$p/tx.jsonl"   # 4회째 — 같은 상태이므로 예산 소진
  if [ "$RC" -ne 0 ];                        then why="소진 턴 rc=$RC (기대 0)"
  elif ! contains "$OUT" "$TOK_BRICK";       then why='벽돌 방지 메시지가 없다'
  elif ! contains "$OUT" '01_plan_gone.md';  then why='changed 나열에 회수 플래그 항목이 없다 (소실 항목은 게이트 식별자에 없다)'
  elif ! flag_gone "$p";                     then why='소진 정리에서 회수 플래그가 안 지워졌다'
  fi
  report "$name" "$why"
}

r16() { # 결정 게이트 판독 불가 사유는 회수 차단 메시지에도 실린다 (ADR-0012 ②).
        # transcript 를 아예 주지 않아 판독 불가를 만든다. 발동 조건은 audit 플래그.
  local name='r16 판독 불가 사유가 회수 차단에 실린다' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '표명 없음.'
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  run_stop "$p" ""
  if ! contains "$ERR" "$TOK_RET";  then why='회수 게이트가 막지 않았다'
  elif ! contains "$ERR" "$TOK_NOTE"; then why='판독 불가 사유가 안 실렸다'
  fi
  report "$name" "$why"
}

r17() { # retrieval 플래그는 decision_armed 에 **들어가지 않는다** — 소실 항목만 남은
        # stale 플래그 + 결정 표지 발화에서 결정 게이트가 오발동하면 3.4 의 해제 기회가
        # 오지 않는다(설계 검수 [cc] r2 H). 기대: 결정 침묵 + 해제 + exit 0.
  local name='r17 stale 플래그가 결정 게이트를 무장시키지 않는다' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  set_flag "$p" retrieval '_workspace/00_design.md'   # 파일 없음 = stale
  mk_tx "$p/tx.jsonl" marker
  run_stop "$p" "$p/tx.jsonl"
  if contains "$ERR" "$TOK_DECISION"; then why='결정 게이트가 오발동했다'
  elif [ "$RC" -ne 0 ];               then why="rc=$RC (기대 0): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! flag_gone "$p";              then why='stale 플래그가 해제되지 않았다'
  fi
  report "$name" "$why"
}

r18() { # 정상 표명 + 다른 할 일 전무 → exit 0. 재평가가 없으면 맨 아래 감사 게이트가
        # 빈 목록으로 허위 차단한다(설계 검수 [cx] r2).
  local name='r18 정상 + 할 일 전무 → exit 0 (허위 감사 차단 없음)' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" "$GOOD_FIRST"
  set_flag "$p" retrieval '_workspace/00_design.md'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if [ "$RC" -ne 0 ];       then why="rc=$RC (기대 0): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! flag_gone "$p";    then why='플래그 미해제'
  elif contains "$ERR" '완료 차단'; then why='어떤 게이트가 차단했다'
  fi
  report "$name" "$why"
}

r19() { # arming 은 수기 플래그가 아니라 **mark-needs-audit 실제 실행**으로도 잰다 —
        # 기록 제거 변이가 수기 픽스처에 가려지지 않게. Stop 까지 이어 돌려 차단 확인.
  local name='r19 mark-needs-audit 실행 → 회수 플래그 → 차단' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '표명 없음.'
  printf '{"tool_input":{"file_path":"%s"}}' "$p/_workspace/00_design.md" | \
    CLAUDE_PROJECT_DIR="$p" bash "$p/.claude/hooks/mark-needs-audit.sh" >/dev/null 2>&1
  if [ ! -s "$p/.claude/.needs-retrieval" ]; then
    why='mark-needs-audit 가 회수 플래그를 기록하지 않았다'
  else
    set_flag "$p" audit 'src/x.ts'   # 감사 도달 확인용
    mk_tx "$p/tx.jsonl" neutral
    run_stop "$p" "$p/tx.jsonl"
    contains "$ERR" "$TOK_RET" || why='기록된 플래그로 차단되지 않았다'
  fi
  report "$name" "$why"
}

r20() { # 이름·경로에 codex 가 들어도 산출물이면 검사 대상이다 — mark-needs-audit 쪽
        # 계약(케이스 74·75)의 Stop 쪽 절반: 그 플래그로 실제 차단까지 간다.
  local name='r20 codex 이름 산출물도 검사된다' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design-codex-gate.md" '표명 없음.'
  set_flag "$p" retrieval '_workspace/00_design-codex-gate.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  contains "$ERR" "$TOK_RET" || why='codex 이름이라는 이유로 검사에서 빠졌다'
  report "$name" "$why"
}

r21() { # 표명 리터럴 드리프트 — 같은 문자열이 세 정본 자리에 있어야 한다.
        # 대상 목록은 상수다(파생하면 파일이 빠져도 초록이 된다).
  local name='r21 표명 문자열이 훅·스킬·프로필에서 동일' why=''
  local lit='사전 결정 회수:' f
  for f in \
    "$HOOKS/verify-before-stop.sh" \
    "$REPO_ROOT/template/.claude/skills/harness-orchestrator/SKILL.md" \
    "$REPO_ROOT/template/.claude/harness/project-profile.template.md"; do
    grep -qF "$lit" "$f" || { why="리터럴이 없다: $f"; break; }
  done
  report "$name" "$why"
}

r22() { # 정상 해제 + push 미완 → push 게이트가 막는다. 재평가식이 플래그만 세면
        # 자동 해제가 push 를 삼킨다(설계 검수 [cc·cx] r2 B — 커밋 29개를 잃은 상태의 재개방).
  local name='r22 정상 해제 + push 미완 → push 차단' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  ( cd "$p" && git init -q . && git checkout -q -b main 2>/dev/null; \
    git -C "$p" config user.email t@t && git -C "$p" config user.name t \
    && git -C "$p" add -A >/dev/null 2>&1 && git -C "$p" commit -qm base \
    && git -C "$p" remote add origin "$p" \
    && git -C "$p" update-ref refs/remotes/origin/main HEAD \
    && printf 'x\n' > "$p/x.txt" && git -C "$p" add x.txt && git -C "$p" commit -qm ahead ) >/dev/null 2>&1 \
    || { report "$name" '픽스처 실패: git'; return 0; }
  mk_doc "$p/_workspace/00_design.md" "$GOOD_FIRST"
  set_flag "$p" retrieval '_workspace/00_design.md'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" "$TOK_PUSH"; then why="push 게이트 미도달 (rc=$RC): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! flag_gone "$p";            then why='회수 플래그는 해제됐어야 한다'
  fi
  report "$name" "$why"
}

r23() { # 정상 해제 + 지식 게이트 켜짐 → 지식 게이트로 계속 흘러간다 (재평가가 과하게
        # exit 0 하지 않는다). 켜진 지식 게이트가 work_pending 을 참으로 유지한다.
  local name='r23 정상 해제 + 지식 플래그 → 지식 게이트 도달' why=''
  local p; p="$(new_project on)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" "$GOOD_FIRST"
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" knowledge '_workspace/00_design.md'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if contains "$ERR" "$TOK_RET";      then why='위양성 — 회수 게이트가 막았다'
  elif ! contains "$ERR" "$TOK_KNOW"; then why="지식 게이트 미도달 (rc=$RC): $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! flag_gone "$p";              then why='회수 플래그 미해제'
  fi
  report "$name" "$why"
}

r24() { # 회수 불량 목록은 **다른 게이트의 예산을 건드리지 않는다.** 결정 게이트에 갇힌 채
        # 불량 집합만 바뀌어도 결정 게이트의 카운터는 이어져야 한다(공유 지문 불변식 —
        # 목록을 flags_fp 로 전파하는 변이가 여기서 빨개진다).
  local name='r24 불량 집합 변화가 결정 게이트 예산을 리셋하지 않는다' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  mk_doc "$p/_workspace/00_design.md" '표명 없음 A.'
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" marker      # 결정 게이트(3.2)가 3.4 보다 먼저 막는다
  run_stop "$p" "$p/tx.jsonl"
  if ! contains "$ERR" "$TOK_DECISION"; then why="결정 게이트가 먼저 막지 않았다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif ! contains "$ERR" '차단 1/';     then why='1회차가 1/N 이 아니다'
  else
    mk_doc "$p/_workspace/01_plan.md" '표명 없음 B.'   # 불량 집합만 바꾼다
    printf '_workspace/01_plan.md\n' >> "$p/.claude/.needs-retrieval"
    run_stop "$p" "$p/tx.jsonl"
    if ! contains "$ERR" "$TOK_DECISION"; then why='2회차에 결정 게이트가 안 막았다'
    elif ! contains "$ERR" '차단 2/';     then why="결정 게이트 카운터가 리셋됐다 (집합 변화가 전파됨): $(printf '%s' "$ERR" | tail -1 | head -c 60)"
    fi
  fi
  report "$name" "$why"
}

r25() { # 첫 줄의 BOM·CR 은 걷어낸 뒤 판정한다 — 눈에 안 보이는 바이트가 정상 표명을
        # 불량으로 뒤집으면 안 된다(harness_env_value 가 데인 같은 부류).
  local name='r25 BOM·CRLF 첫 줄 → 정상 판정' why=''
  local p; p="$(new_project)" || { report "$name" '픽스처 실패'; return 0; }
  printf '\357\273\277사전 결정 회수: docs/decisions/\r\n본문.\n' > "$p/_workspace/00_design.md"
  set_flag "$p" retrieval '_workspace/00_design.md'
  set_flag "$p" audit 'src/x.ts'
  mk_tx "$p/tx.jsonl" neutral
  run_stop "$p" "$p/tx.jsonl"
  if contains "$ERR" "$TOK_RET";       then why='BOM/CR 때문에 정상 표명이 차단됐다'
  elif ! contains "$ERR" "$TOK_AUDIT"; then why='감사 게이트 미도달'
  elif ! flag_gone "$p";               then why='플래그 미해제'
  fi
  report "$name" "$why"
}

# --- 실행 -----------------------------------------------------------------
# EXPECTED_CASES 는 상수다. 파생값이면 케이스를 지워도 초록이다.
EXPECTED_CASES=25
CASES='r01 r02 r03 r04 r05 r06 r07 r08 r09 r10 r11 r12 r13 r14 r15 r16 r17 r18 r19 r20 r21 r22 r23 r24 r25'

echo "retrieval-attestation.test.sh — 회수 표명 게이트(stop:retrieval) 회귀"
case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ 케이스 목록이 계약과 다릅니다: 총 $case_total / 고유 $case_uniq / 기대 $EXPECTED_CASES" >&2
  exit 1
fi
for c in $CASES; do "$c"; done
if [ "$ran" -ne "$EXPECTED_CASES" ]; then
  echo "✗ 실행 수($ran)가 기대($EXPECTED_CASES)와 다릅니다 — 케이스가 조용히 빠졌습니다" >&2
  exit 1
fi
echo "— $pass/$ran 통과"
[ "$fail" -eq 0 ]
