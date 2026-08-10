#!/usr/bin/env bash
# decision-gate.test.sh — Stop 훅의 **결정 게이트**(stop:decision) 회귀 방어.
#
#   "코드/결정이 바뀐 턴에 결정 표지 어휘가 있는데 AskUserQuestion 이 0회면 막는다"
#
# 이 게이트만 **에이전트 자신의 행동**을 본다(나머지 넷은 산출물을 본다). 그래서 실패
# 방향이 둘 다 비싸다:
#   위음성 — 혼자 정하고 한 줄 적는 것이 그대로 통과한다. 이 저장소가 반복해서 겪은 부류다
#   위양성 — 질문이 소음이 되고, 소음이 되면 진짜 질문도 무시된다. 게이트가 자기를 죽인다
# 그래서 **양쪽을 다 케이스로 붙든다.** 위양성 케이스가 이 파일의 절반인 이유다 —
# 나중에 누가 패턴을 넓히면 그 케이스들이 빨개져서 대가를 눈에 보이게 한다.
#
# **판정 규칙의 사본을 두지 않는다.** 어떤 어휘가 표지인지·무엇이 서술형인지를 여기서
# 다시 정의하면 그 사본이 언젠가 원본과 어긋나고, 그때 테스트는 틀린 기준으로 초록을 낸다.
# 대신 훅 **자신을 돌려** 차단 여부와 메시지로 잰다.
#
# **rc 만으로 판정하지 않는다.** 결정 게이트가 통과해도 뒤의 감사 게이트가 rc=2 를 내므로
# rc 는 두 경우에 **같다.** 어느 게이트가 말했는지는 메시지로만 갈린다(위음성 카탈로그 17번:
# 관례 코드에 도달하는 경로가 여럿이면 rc 일치가 의도한 경로를 뜻하지 않는다).
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. mapfile·연관배열·${var,,} 금지.

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOKS="$REPO_ROOT/template/.claude/hooks"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (스캐너·픽스처 의존)" >&2; exit 1; }
for f in verify-before-stop.sh _common.sh; do
  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
done

TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
# chmod 000 픽스처가 있으므로 되돌린 뒤 지운다 — 안 그러면 정리가 실패한다.
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

ran=0; pass=0; fail=0
RC=999; ERR=''; OUT=''; DID_RUN=0
PROJ_N=0

# 판정 토큰. 훅 메시지의 **고유 문구**를 쓴다 — 어느 게이트가 말했는지는 이걸로만 갈린다.
TOK_DECISION='혼자 정한 것이 있는데'
TOK_NOTE='결정 게이트 생략'
TOK_AUDIT='completion-auditor 미실행'
TOK_BRICK='세션 벽돌 방지'

report() {
  ran=$((ran + 1))
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}

contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

# --- 픽스처 --------------------------------------------------------------

# new_project <지식게이트값> — 케이스마다 독립 프로젝트. 경로를 stdout 에.
# 지식게이트값: 리터럴로 비면 꺼짐, 그 외 문자열이면 켜짐.
# 타입체크는 항상 리터럴로 비운다 — 이 파일이 재는 것은 결정 게이트뿐이고, 타입체크가
# 먼저 막으면 그 케이스는 결정 게이트에 **도달조차 못 한 채** 기대값이 우연히 맞는다.
new_project() {
  PROJ_N=$((PROJ_N + 1))
  local p="$TMPROOT/proj$PROJ_N"
  mkdir -p "$p/.claude/hooks" "$p/.claude/harness" || return 1
  cp "$HOOKS/_common.sh" "$HOOKS/verify-before-stop.sh" "$p/.claude/hooks/" || return 1
  printf 'HARNESS_TYPECHECK_CMD=""\nHARNESS_KNOWLEDGE_GATE="%s"\n' "$1" \
    > "$p/.claude/harness/harness.env" || return 1
  printf '%s\n' "$p"
}

# mk_transcript <출력경로> <항목...> — 대화 기록 JSONL 을 만든다.
# 항목 문법:  text:<문장> · side:<문장>(서브에이전트) · think:<문장> · ask ·
#             tool:<내용>(도구 입력) · prompt(새 사용자 프롬프트=턴 경계) · toolresult:<내용>
# 첫 줄은 항상 사용자 프롬프트다 — 그게 없는 경우는 판독 불가 케이스에서 따로 만든다.
mk_transcript() {
  python3 - "$@" <<'PY'
import json, sys

out = sys.argv[1]


def prompt():
    return {"type": "user", "isSidechain": False,
            "message": {"role": "user", "content": "작업해줘"}}


rows = [prompt()]
for spec in sys.argv[2:]:
    kind, _, val = spec.partition(":")
    if kind == "prompt":
        rows.append(prompt())
        continue
    if kind == "toolresult":
        rows.append({"type": "user", "isSidechain": False,
                     "toolUseResult": {"stdout": val},
                     "message": {"role": "user",
                                 "content": [{"type": "tool_result", "content": val}]}})
        continue
    # 실제 기록에서는 두 표식이 **항상 함께** 온다(실측 69/69). 그래서 둘 다 보는 판정은
    # 서로를 가려, 한쪽을 지워도 아무 케이스가 안 빨개진다 — 변이 측정에서 실제로 드러났다.
    # 각각을 **독립적으로** 지키려면 표식이 하나뿐인 기록이 필요하다. 형식이 바뀌어 한쪽만
    # 남는 날, 남은 한쪽이 실제로 일하는지를 재는 것이 이 두 항목이다.
    if kind == "toolresult_top":       # 상단 toolUseResult 만 (content 는 평문)
        rows.append({"type": "user", "isSidechain": False,
                     "toolUseResult": {"stdout": val},
                     "message": {"role": "user", "content": val}})
        continue
    if kind == "toolresult_blk":       # tool_result 블록만 (상단 키 없음)
        rows.append({"type": "user", "isSidechain": False,
                     "message": {"role": "user",
                                 "content": [{"type": "tool_result", "content": val}]}})
        continue
    side = False
    if kind == "side":
        side, kind = True, "text"
    if kind == "text":
        block = {"type": "text", "text": val}
    elif kind == "think":
        block = {"type": "thinking", "thinking": val}
    elif kind == "ask":
        block = {"type": "tool_use", "name": "AskUserQuestion", "input": {}}
    elif kind == "tool":
        block = {"type": "tool_use", "name": "Write", "input": {"content": val}}
    else:
        raise SystemExit("알 수 없는 항목: " + spec)
    rows.append({"type": "assistant", "isSidechain": side,
                 "message": {"content": [block]}})

with open(out, "w", encoding="utf-8") as fh:
    for row in rows:
        fh.write(json.dumps(row, ensure_ascii=False) + "\n")
PY
}

# run_stop <프로젝트> <transcript경로|빈문자열> [env 인자...]
# 빈 문자열이면 payload 에서 transcript_path 키를 **아예 뺀다**(키 부재 케이스).
run_stop() {
  local p="$1" tp="$2"
  shift 2
  local errf="$TMPROOT/err.$$" outf="$TMPROOT/out.$$" payf="$TMPROOT/pay.$$"
  RC=999; ERR=''; OUT=''; DID_RUN=1
  # payload 를 **파일로** 넘긴다. 파이프로 주면 훅이 stdin 을 읽기 전에 종료하는 경로
  # (탈출구로 꺼진 경우 등)에서 생산자 python 이 SIGPIPE 를 맞아 BrokenPipeError 를
  # 출력에 흘린다 — 진짜 실패와 구별이 안 되는 잡음이다.
  python3 -c '
import json, sys
d = {"stop_hook_active": False}
if sys.argv[1]:
    d["transcript_path"] = sys.argv[1]
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    fh.write(json.dumps(d))' "$tp" "$payf"
  env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$p" \
      bash "$p/.claude/hooks/verify-before-stop.sh" <"$payf" >"$outf" 2>"$errf"
  RC=$?
  rm -f "$payf"
  ERR="$(cat "$errf" 2>/dev/null)"
  OUT="$(cat "$outf" 2>/dev/null)"
  rm -f "$errf" "$outf"
}

# setup_flags <프로젝트> <플래그 이름...>  (audit|explain|knowledge|dualreview)
setup_flags() {
  local p="$1"; shift
  rm -f "$p/.claude/.needs-audit" "$p/.claude/.needs-explain" \
        "$p/.claude/.needs-knowledge" "$p/.claude/.needs-dualreview" \
        "$p/.claude/.stop-block-count" "$p/.claude/.stop-block-fp" 2>/dev/null
  local f
  for f in "$@"; do printf 'src/changed.ts\n' > "$p/.claude/.needs-$f"; done
}

# --- 공통 케이스 형태 -----------------------------------------------------
#
# blocked = 결정 게이트가 **막아야** 한다
# silent  = 결정 게이트는 **아무 말도 하지 않아야** 한다 (뒤 게이트가 막는 것은 정상)
#
# silent 판정에 rc=0 을 쓰지 않는 이유: 플래그가 서 있으면 감사 게이트가 반드시 rc=2 를
# 낸다. 그래서 결정 게이트의 침묵만 요구하고, 동시에 **감사 게이트가 실제로 말했는지**를
# 함께 요구한다 — 안 그러면 훅이 앞에서 죽어 아무것도 안 재고도 통과한다(15번 부류).

blocked_case() {   # $1=이름 $2=기대문장조각("" 이면 생략) $3..=기록 항목
  local name="$1" want_hit="$2" why=''
  shift 2
  local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
  local tp="$p/transcript.jsonl"
  mk_transcript "$tp" "$@" || { report "$name" '픽스처 실패: 기록 생성'; return 0; }
  [ -s "$tp" ] || { report "$name" '픽스처 실패: 기록이 비어 있다'; return 0; }
  setup_flags "$p" audit
  run_stop "$p" "$tp"
  if [ "$DID_RUN" -ne 1 ];                then why='훅을 실행하지 않았다'
  elif [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2) / $(printf '%s' "$ERR" | head -c 100)"
  elif ! contains "$ERR" "$TOK_DECISION"; then why="결정 게이트가 아닌 것이 막았다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif [ -n "$want_hit" ] && ! contains "$ERR" "$want_hit"; then
    why="걸린 문장이 메시지에 없다 (기대 조각: $want_hit)"
  fi
  report "$name" "$why"
}

silent_case() {   # $1=이름 $2..=기록 항목
  local name="$1" why=''
  shift
  local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
  local tp="$p/transcript.jsonl"
  mk_transcript "$tp" "$@" || { report "$name" '픽스처 실패: 기록 생성'; return 0; }
  [ -s "$tp" ] || { report "$name" '픽스처 실패: 기록이 비어 있다'; return 0; }
  setup_flags "$p" audit
  run_stop "$p" "$tp"
  if [ "$DID_RUN" -ne 1 ];              then why='훅을 실행하지 않았다'
  elif contains "$ERR" "$TOK_DECISION"; then why='위양성 — 결정 게이트가 막았다'
  elif [ "$RC" -ne 2 ];                 then why="rc=$RC (기대 2 — 감사 게이트가 막아야 한다)"
  elif ! contains "$ERR" "$TOK_AUDIT";  then why="감사 게이트에 도달하지 못했다 = 아무것도 안 쟀다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  elif contains "$ERR" "$TOK_NOTE";     then why='판독 불가로 빠졌다 — 스캔이 실제로 돌지 않았다'
  fi
  report "$name" "$why"
}

# ── 1. 막아야 하는 것 ─────────────────────────────────────────────────
# 문장 형태는 전부 지난 세션에서 실제로 쓴 것이다(ADR-0011 Context 절).
d01() { blocked_case '표지 + 서술형 + 질문 0회 를 막는다' '범위 밖' \
          'text:이건 이번 PR 범위 밖이라 그대로 뒀습니다.'; }
d02() { blocked_case '제 판단으로 형태를 막는다' '제 판단으로' \
          'text:제 판단으로 끄지 않고 그대로 진행했습니다.'; }
d03() { blocked_case '공시 형태를 막는다' '공시' \
          'text:남은 것은 공시하고 넘어갑니다.'; }
d04() { blocked_case '트레이드오프 단정을 막는다' '트레이드오프' \
          'text:이건 버그가 아니라 의도된 트레이드오프다.'; }
d05() { blocked_case '수용된 한계 형태를 막는다' '수용된 한계' \
          'text:이 좁은 창은 수용된 한계로 남겼음.'; }
d06() { blocked_case '가정하고 형태를 막는다' '가정하고' \
          'text:기본값이 켜짐이라고 가정하고 구현했습니다.'; }
d07() { blocked_case '안 했습니다 형태를 막는다' '안 했습니다' \
          'text:그 부분은 시간이 없어 안 했습니다.'; }
# **걸린 문장을 메시지에 싣는 것이 계약이다.** 안 실으면 무엇을 물어야 할지 알 수 없어
# 에이전트가 "일단 아무거나 물어서 풀자"로 간다 — 게이트가 의식(儀式)이 되는 경로다.
d08() { blocked_case '걸린 문장 여러 개를 함께 싣는다' '별도로' \
          'text:이건 범위 밖이라 뺐습니다.' 'text:나머지는 별도로 처리했습니다.'; }
d09() { blocked_case '표지가 마지막 발화에만 있어도 막는다' '그대로 뒀' \
          'text:작업을 시작합니다.' 'text:충돌 나는 부분은 그대로 뒀습니다.'; }

# ── 2. 위양성 — 막으면 안 되는 것 ─────────────────────────────────────
# 이 절이 파일의 절반인 이유: 어휘만 보면 이 게이트를 **유지보수하는 작업 자체가** 매번
# 걸린다(훅·테스트·결정 문서가 그 어휘를 데이터로 품는다). 그러면 사람이 게이트를 끄고,
# 꺼진 게이트는 없는 게이트다. 패턴을 넓히려는 다음 사람은 여기서 대가를 본다.
d10() { silent_case '질문을 한 번 했으면 풀린다' \
          'text:이건 범위 밖이라 그대로 뒀습니다.' 'ask'; }
d11() { silent_case '질문이 표지보다 앞에 와도 풀린다' \
          'ask' 'text:여쭌 대로 범위 밖으로 뒀습니다.'; }
d12() { silent_case '백틱으로 인용한 어휘는 결정이 아니다' \
          'text:결정 표지 어휘는 `범위 밖` 과 `그대로 뒀` 이다.'; }
d13() { silent_case '따옴표로 인용한 어휘는 결정이 아니다' \
          'text:사용자가 "범위 밖"이라고 하셨으므로 그렇게 했습니다.'; }
d14() { silent_case '인용줄로 시작하는 줄은 스캔하지 않는다' \
          'text:> 이건 범위 밖이라 그대로 뒀습니다.'; }
d15() { silent_case '코드펜스 안은 스캔하지 않는다' \
          'text:예시:
```
이건 범위 밖이라 그대로 뒀습니다.
```
위가 걸리는 형태다.'; }
# 펜스가 안 닫힌 채 기록이 잘렸으면 **남은 전부를 코드로 친다.** 반대로 두면 잘린 기록의
# 코드 블록이 산문으로 새어 위양성이 터진다.
d16() { silent_case '닫히지 않은 코드펜스 뒤는 전부 코드로 친다' \
          'text:예시:
```
이건 범위 밖이라 그대로 뒀습니다.'; }
d17() { silent_case '질문형 문장은 표지로 세지 않는다' \
          'text:이건 범위 밖으로 둘까요?'; }
d18() { silent_case '선택을 요청하는 문장도 세지 않는다' \
          'text:범위 밖으로 뺄지 어느 쪽이 좋은지 말씀해 주세요.'; }
# **묻겠다는 말이 서술형으로 끝나는 경우가 질문 신호 판정의 진짜 시험대다.** d17·d18 은
# 종결이 "…까요/…세요"라 서술형 요구에서 이미 걸러져 질문 판정에 도달조차 하지 않는다 —
# 그래서 질문 판정을 지워도 아무것도 안 빨개졌다(변이 측정에서 드러났다).
d18b() { silent_case '묻겠다는 말이 서술형으로 끝나도 세지 않는다' \
          'text:이게 범위 밖인지 여쭙겠습니다.'; }
d18c() { silent_case '물어보겠다는 말도 세지 않는다' \
          'text:이걸 별도로 뺄지 사용자에게 물어보겠습니다.'; }
d19() { silent_case 'thinking 블록은 스캔하지 않는다' \
          'think:이건 범위 밖이라 그대로 뒀습니다.'; }
d20() { silent_case '서브에이전트 발화는 스캔하지 않는다' \
          'side:이건 범위 밖이라 그대로 뒀습니다.'; }
# **도구 입력을 안 보는 것이 자기참조 폭발을 막는 장치다.** 이 패턴이 적힌 파일을
# Write/Edit 로 쓰는 것 자체는 결정이 아니다.
d21() { silent_case '도구 입력(파일 내용)은 스캔하지 않는다' \
          'tool:이건 범위 밖이라 그대로 뒀습니다.'; }
d22() { silent_case '서술형이 아니면(명사 종결) 세지 않는다' \
          'text:- 범위 밖'; }
d23() { silent_case '표지가 없으면 아무리 길어도 안 잡는다' \
          'text:구현을 마쳤고 테스트 12건이 전부 통과했습니다.'; }
# 턴 경계. 지난 턴의 자백까지 세면 이미 해소된 것으로 영원히 막힌다.
d24() { silent_case '지난 턴의 문장은 보지 않는다' \
          'text:이건 범위 밖이라 그대로 뒀습니다.' 'prompt' 'text:이번에는 전부 처리했습니다.'; }
# 도구 결과는 사용자 발화가 아니다. 이걸 턴 경계로 세면 창이 도구 호출 하나로 좁아져
# 게이트가 사실상 사라진다. 두 방향으로 잰다 — 놓치지 않는가(d25b)와 오탐하지 않는가(d25).
d25() { silent_case '도구 결과 뒤라도 표지가 없으면 안 막는다' \
          'text:작업을 시작합니다.' 'toolresult:ok' 'text:테스트가 전부 통과했습니다.'; }
d25b() { blocked_case '도구 결과 뒤의 자백도 같은 턴으로 본다' '범위 밖' \
          'text:작업을 시작합니다.' 'toolresult:ok' 'text:나머지는 범위 밖이라 뒀습니다.'; }
# **자백이 도구 결과보다 앞에 있는 경우가 판정의 진짜 시험대다.** 도구 결과를 턴 경계로
# 오인하면 그 앞의 발화가 통째로 창 밖으로 밀려 사라지는데, d25b 는 자백이 뒤에 있어서
# 그 오인을 못 잡는다(경계가 밀려도 뒤 문장은 여전히 창 안이다).
d25c() { blocked_case '도구 결과 앞의 자백도 놓치지 않는다' '범위 밖' \
          'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult:ok' 'text:작업을 마쳤습니다.'; }
# 표식이 하나뿐인 도구 결과. 두 판정(상단 키 / 블록)을 **각각** 지킨다 — 실제 기록은 둘 다
# 갖고 있어서 서로를 가리고, 그러면 한쪽을 지워도 아무 케이스가 안 빨개진다.
d25d() { blocked_case '상단 키만 있는 도구 결과도 턴 경계가 아니다' '범위 밖' \
          'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult_top:ok' 'text:작업을 마쳤습니다.'; }
d25e() { blocked_case '블록만 있는 도구 결과도 턴 경계가 아니다' '범위 밖' \
          'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult_blk:ok' 'text:작업을 마쳤습니다.'; }

# ── 3. 발동 조건 — 어느 플래그에서 도나 ──────────────────────────────
# 사용자 확정(2026-08-10): 코드뿐 아니라 **결정 문서·설계 산출물** 턴에서도 돈다.
# 표지 어휘가 가장 자주 나오는 자리가 결정 문서를 쓰는 턴이기 때문이다.
flag_case() {   # $1=이름 $2=지식게이트값 $3=플래그(none 가능) $4=기대(block|exit0)
  local name="$1" kg="$2" flag="$3" want="$4" why=''
  local p; p="$(new_project "$kg")" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
  local tp="$p/transcript.jsonl"
  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.' || { report "$name" '픽스처 실패'; return 0; }
  if [ "$flag" = 'none' ]; then setup_flags "$p"; else setup_flags "$p" "$flag"; fi
  run_stop "$p" "$tp"
  case "$want" in
    block)
      if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2)"
      elif ! contains "$ERR" "$TOK_DECISION"; then why="결정 게이트가 아닌 것이 막았다: $(printf '%s' "$ERR" | head -1 | head -c 80)"
      fi ;;
    exit0)
      if   [ "$RC" -ne 0 ];                 then why="rc=$RC (기대 0 — 할 일이 없으면 조기 종료)"
      elif contains "$ERR" "$TOK_DECISION"; then why='할 일이 없는 턴인데 결정 게이트가 막았다'
      fi ;;
    *) why="알 수 없는 기대값: $want" ;;
  esac
  report "$name" "$why"
}
d26() { flag_case '코드 변경 턴에서 돈다'        ''   audit      block; }
d27() { flag_case '설계 산출물 턴에서 돈다'      ''   dualreview block; }
d28() { flag_case '결정 문서 턴에서 돈다'        'on' knowledge  block; }
d29() { flag_case '변경설명 턴에서 돈다'         ''   explain    block; }
# **아무것도 안 바꾼 턴은 막지 않는다.** 순수 질의응답에서 어휘를 썼다고 막으면 게이트가
# 대화를 방해한다(사용자 확정: "항상 검사" 보기 기각).
d30() { flag_case '플래그가 하나도 없으면 돌지 않는다' '' none exit0; }
# 공시된 한계를 케이스로 붙든다: 지식 게이트를 끈 환경에서 **결정 문서만** 고친 턴은
# 조기 종료에 걸려 결정 게이트까지 못 간다. 조기 종료를 고치면 "게이트를 껐는데 남은
# 플래그가 읽기 전용 턴을 막는" 알려진 버그가 되살아난다. 기본값이 켜짐이라 기본 구성에서는
# d28 처럼 정상 발동한다. **이 한계가 바뀌면 이 케이스가 빨개져서 알려준다.**
d30b() { flag_case '지식 게이트를 끄면 결정 문서 턴은 조기 종료된다(공시된 한계)' '' knowledge exit0; }

# ── 4. fail-open — 판독 불가는 **통과 + 경고**다 ─────────────────────
# 대화 기록 형식은 하네스가 소유하지 않는다. 형식이 바뀌었다고 차단하면 그 세션 안에
# 고칠 방법이 없어 **세션이 통째로 벽돌이 된다.** 이 게이트의 유일한 fail-open 지점이고,
# 조건은 **경고를 삼키지 않는 것**이다 — 조용히 통과하면 게이트가 죽은 걸 아무도 모른다.
openq_case() {   # $1=이름 $2=기록준비함수
  local name="$1" prep="$2" why=''
  local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
  local tp; tp="$("$prep" "$p")"
  setup_flags "$p" audit
  run_stop "$p" "$tp"
  if   [ "$DID_RUN" -ne 1 ];            then why='훅을 실행하지 않았다'
  elif contains "$ERR" "$TOK_DECISION"; then why='판독 불가인데 차단했다 (세션이 벽돌이 된다)'
  elif [ "$RC" -ne 2 ];                 then why="rc=$RC (기대 2 — 감사 게이트가 막아야 한다)"
  elif ! contains "$ERR" "$TOK_NOTE";   then why='경고를 삼켰다 — 게이트가 조용히 죽은 것을 아무도 모른다'
  fi
  report "$name" "$why"
}
prep_nokey()   { printf '%s\n' ''; }
prep_missing() { printf '%s\n' "$1/does-not-exist.jsonl"; }
prep_garbage() { local f="$1/garbage.jsonl"; printf 'not json at all\n{{{\n' > "$f"; printf '%s\n' "$f"; }
# 사용자 프롬프트가 없는 기록 = 턴 경계를 못 찾은 것. 전체를 훑으면 지난 턴까지 걸리므로
# 판독 불가로 떨어뜨린다. 표지를 일부러 넣어 "그래도 안 막는가"를 잰다.
prep_noprompt() {
  local f="$1/noprompt.jsonl"
  python3 -c '
import json, sys
with open(sys.argv[1], "w", encoding="utf-8") as fh:
    fh.write(json.dumps({"type": "assistant", "isSidechain": False, "message": {"content": [
        {"type": "text", "text": "이건 범위 밖이라 그대로 뒀습니다."}]}}, ensure_ascii=False) + "\n")
' "$f"
  printf '%s\n' "$f"
}
prep_unreadable() { local f="$1/unreadable.jsonl"; printf '{}\n' > "$f"; chmod 000 "$f" 2>/dev/null; printf '%s\n' "$f"; }
d31() { openq_case 'transcript_path 키가 없으면 통과 + 경고' prep_nokey; }
d32() { openq_case '기록 파일이 없으면 통과 + 경고'          prep_missing; }
d33() { openq_case '전부 깨진 JSON 이면 통과 + 경고'         prep_garbage; }
d34() { openq_case '턴 시작점을 못 찾으면 통과 + 경고'       prep_noprompt; }
d35() {
  # root 로 도는 CI 에서는 chmod 000 이 읽기를 막지 못한다 — 그 환경에서 이 케이스는
  # 아무것도 재지 못하므로 **조용히 통과시키지 않고** 픽스처 무효로 빨갛게 만든다.
  # 조용한 skip 은 커버리지가 사라진 것을 초록으로 위장한다.
  if [ "$(id -u)" = '0' ]; then
    report '읽기 실패하면 통과 + 경고' 'root 라 chmod 000 이 읽기를 막지 못한다 — 이 환경에서는 측정 불가'
    return 0
  fi
  openq_case '읽기 실패하면 통과 + 경고' prep_unreadable
}

# ── 5. 탈출구 (사용자 확정: 형제 Stop 게이트와 동일하게 제공) ────────
# 이 게이트는 위양성이 **구조적으로** 난다 — 자기 어휘를 문서·설명에서 다뤄야 하기
# 때문이다. 그래서 사용자가 즉시 뺄 수 있어야 한다. 끄는 대입 자체는 guard-hook-disable
# 이 한 번 세운다(과속방지턱이지 방벽은 아니다).
escape_case() {   # $1=이름 $2..=env 인자
  local name="$1" why=''
  shift
  local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
  local tp="$p/transcript.jsonl"
  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.' || { report "$name" '픽스처 실패'; return 0; }
  setup_flags "$p" audit
  run_stop "$p" "$tp" "$@"
  if   [ "$DID_RUN" -ne 1 ];            then why='훅을 실행하지 않았다'
  elif contains "$ERR" "$TOK_DECISION"; then why='껐는데도 결정 게이트가 막았다'
  fi
  report "$name" "$why"
}
d36() { escape_case '개별 비활성으로 끌 수 있다' ECC_DISABLED_HOOKS=stop:decision; }
d37() { escape_case '전체 비활성으로도 꺼진다'   HARNESS_HOOKS=off; }
d38() {
  # **다른 게이트 이름으로는 안 꺼진다.** 접두사·부분 일치로 꺼지면 하나를 끌 때 옆의
  # 게이트가 같이 사라지고 아무도 모른다.
  local name='다른 게이트 이름으로는 안 꺼진다' why=''
  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
  local tp="$p/transcript.jsonl"
  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
  setup_flags "$p" audit
  run_stop "$p" "$tp" ECC_DISABLED_HOOKS=stop:explain
  contains "$ERR" "$TOK_DECISION" || why='다른 게이트를 껐는데 결정 게이트까지 꺼졌다'
  report "$name" "$why"
}

# ── 6. 벽돌 방지 — 같은 지점 MAX_BLOCKS 회면 통과시킨다 ──────────────
# 질문 한 번이면 풀리지만, 어떤 이유로도 못 푸는 상황에서 세션이 영영 안 끝나면 안 된다.
d39() {
  local name='같은 지점에서 MAX_BLOCKS 회 뒤에는 통과시킨다 (벽돌 방지)' why=''
  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
  local tp="$p/transcript.jsonl"
  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
  setup_flags "$p" audit
  local i seen_block=0
  for i in 1 2 3; do
    run_stop "$p" "$tp"
    if [ "$RC" -eq 2 ] && contains "$ERR" "$TOK_DECISION"; then seen_block=$((seen_block + 1)); fi
  done
  run_stop "$p" "$tp"
  if   [ "$seen_block" -ne 3 ];        then why="3회 연속 차단이 아니었다 (실제 ${seen_block}회)"
  elif [ "$RC" -ne 0 ];                then why="소진 후 rc=$RC (기대 0)"
  elif ! contains "$OUT" "$TOK_BRICK"; then why="소진 통과인데 경고가 없다: $(printf '%s' "$OUT" | head -c 100)"
  fi
  report "$name" "$why"
}
d40() {
  # **진전하면 예산이 리셋된다.** 질문해서 결정 게이트를 푼 뒤 감사 게이트로 넘어가는 것은
  # 진전이므로, 앞서 쓴 차단 횟수가 뒤 게이트의 예산을 갉아먹으면 안 된다.
  local name='질문해서 풀면 뒤 게이트의 예산이 리셋된다' why=''
  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
  local blocked="$p/blocked.jsonl" asked="$p/asked.jsonl"
  mk_transcript "$blocked" 'text:이건 범위 밖이라 그대로 뒀습니다.'
  mk_transcript "$asked"   'text:이건 범위 밖이라 그대로 뒀습니다.' 'ask'
  setup_flags "$p" audit
  local i
  for i in 1 2 3; do run_stop "$p" "$blocked"; done
  run_stop "$p" "$asked"
  if   [ "$RC" -ne 2 ];                then why="rc=$RC (기대 2 — 감사 게이트가 살아 있어야 한다)"
  elif ! contains "$ERR" "$TOK_AUDIT"; then why="감사 게이트가 예산 소진으로 사라졌다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

# ── 7. 순서 계약 — 결정 게이트가 다른 게이트보다 앞이다 ──────────────
# 질문의 답이 코드를 바꿀 수 있으므로 리뷰·설명·감사에 노력을 쓰기 전에 물어야 한다.
d41() {
  local name='듀얼리뷰·설명·감사보다 먼저 말한다' why=''
  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
  local tp="$p/transcript.jsonl"
  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
  setup_flags "$p" audit explain dualreview
  run_stop "$p" "$tp"
  if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_DECISION"; then why="다른 게이트가 먼저 말했다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
  fi
  report "$name" "$why"
}

# --- 실행 ----------------------------------------------------------------
# 목록을 **명시적으로** 센다. 실행 수만 세면 중복 1건 + 누락 1건이 상쇄돼 초록이 된다.
CASES='d01 d02 d03 d04 d05 d06 d07 d08 d09
d10 d11 d12 d13 d14 d15 d16 d17 d18 d18b d18c d19 d20 d21 d22 d23 d24
d25 d25b d25c d25d d25e
d26 d27 d28 d29 d30 d30b
d31 d32 d33 d34 d35
d36 d37 d38
d39 d40 d41'

echo "결정 게이트 회귀 테스트"
expected=0
for c in $CASES; do expected=$((expected + 1)); done
dupes="$(printf '%s\n' $CASES | sort | uniq -d)"
if [ -n "$dupes" ]; then
  echo "✗ 케이스 목록에 중복이 있습니다: $dupes" >&2; exit 1
fi
for c in $CASES; do
  if ! type "$c" >/dev/null 2>&1; then echo "✗ 케이스 함수가 없습니다: $c" >&2; exit 1; fi
  "$c"
done

echo
if [ "$ran" -ne "$expected" ]; then
  echo "✗ 실행된 케이스 수가 목록과 다릅니다: $ran (기대 $expected)" >&2
  exit 1
fi
printf '%s개 중 %s개 통과, %s개 실패\n' "$ran" "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
echo "✓ 결정 게이트 회귀 방어 유지"
