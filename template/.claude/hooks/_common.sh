#!/usr/bin/env bash
# 하네스 훅 공용 모듈. 각 훅 스크립트가 source 한다. (도메인-무관 재사용 템플릿)
#
# set -e 를 쓰지 않는다: 훅이 예기치 않게 죽으면 세션이 막히거나(Stop)
# 멀쩡한 명령이 차단된다(PreToolUse). 모든 종료는 명시적으로 한다.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
STATE_DIR="$PROJECT_DIR/.claude"
AUDIT_FLAG="$STATE_DIR/.needs-audit"
EXPLAIN_FLAG="$STATE_DIR/.needs-explain"
# 지식 저장소 반영 게이트. 이름은 **계약 수준**이다 — 예전 이름은 특정 구현체를 가리켰고,
# 그래서 그 구현체를 안 쓰는 환경에서 하네스가 없는 구조를 요구하게 됐다.
KNOWLEDGE_FLAG="$STATE_DIR/.needs-knowledge"
# 개명 전 이름의 미처리 플래그는 **install.sh 가 갱신 시점에 새 이름으로 옮긴다.**
# 여기서 옛 이름을 알면 배포되는 글루가 구현체 이름을 다시 품게 되고, 층 경계 검사가
# (옳게) 막는다. 배포되지 않는 설치 스크립트가 이행을 맡는 것이 층에 맞다.
DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
# 머리 표명 게이트(ADR-0013·ADR-0015). 설계·계획 산출물(00_design*·01_plan*)이 저장되면
# 서고, 머리 두 줄이 표명 형식(1줄 `사전 결정 회수:` · 2줄 `레퍼런스 조사:
# 조사함(<대상·출처>)|불요(<사유>)|실패(<사유>)`)을 지키면 Stop 훅이 **자동으로** 지운다 —
# 지울 플래그를 에이전트 손에 주지 않는 것이 이 게이트의 형태다(결정 게이트와 같은 구조).
RETRIEVAL_FLAG="$STATE_DIR/.needs-retrieval"
BLOCK_COUNT="$STATE_DIR/.stop-block-count"
BLOCK_FP="$STATE_DIR/.stop-block-fp"    # 마지막 차단 지문(게이트|플래그 상태) — 진전 인지 리셋용

# Stop 훅이 "같은 지점에서 진전 없이" 최대 몇 번까지 막을 수 있는가. 소진되면 통과시킨다
# (세션 벽돌 방지). 차단 지문이 바뀌면(=게이트를 하나 지웠으면) 카운터는 리셋되므로,
# 게이트 개수가 늘어도 이 상수를 올릴 필요가 없다.
MAX_BLOCKS=3

# 탈출구.
#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
hook_disabled() {
  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
    return 0
  fi
  case ",${ECC_DISABLED_HOOKS:-}," in
    *",$1,"*) return 0 ;;
  esac
  return 1
}

# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
#
# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
# 전부 실측된 것들이다:
#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
#   printf 재정의 → 진단 출력 자체를 위조
# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
#
# **대신 셸이 해주던 파싱을 이 함수가 물려받는다.** 그 파싱을 반쯤 하면 fail-open 을
# 없애려다 다른 fail-open 을 만든다 — 실측된 회귀 6종이 전부 여기서 나왔다.
# 후행 주석 · 후행 공백 · CRLF 의 `\r` 이 값에 섞여 들어가면 그 값을 받은 `sh -c` 가
# rc=127 을 내고, 호출부는 그걸 "도구가 없구나"로 읽어 **검사를 조용히 생략한다.**
# 파일 앞 BOM 은 첫 줄의 키를 통째로 무매치로 만들고, 히어독 본문의 같은 키는 선언으로
# 세어진다. 셋 다 눈에 보이지 않는다.
#
# 그래서 **순서가 계약이다**:
#   ① 파일 첫머리 BOM 제거 → ② 각 줄 후행 CR 제거 → ③ **줄을 넘는 인용 상태** 추적 →
#   ④ 히어독 본문 배제 → ⑤ 선언 판정 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 **밖** 후행 주석
#   → ⑧ 남은 후행 공백 절단
#
# ── 반환 계약 ──────────────────────────────────────────────────────────
#   rc=0 : 최상위 선언이 **정확히 1개**이고 값을 지원 문법으로 판독했다.
#          stdout = 판독된 값. **빈 문자열일 수 있다** — "리터럴로 비웠다"는 뜻이다.
#   rc=1 : 값을 **믿을 수 없다** — 읽기 실패 · 선언 2개 이상 · 지원 문법 밖 ·
#          닫히지 않은 따옴표/히어독. stdout = 빈 문자열. **고칠 수 있는 실수**다.
#   rc=3 : 키가 **없다**(부재) — 파일 없음 · 최상위 선언 0개. stdout = 빈 문자열.
#          안 쓰는 키의 정상 상태다.
#
# 왜 셋으로 가르나: 스위치형 슬롯은 "리터럴로 비웠다"(=끈다)와 "미설정"(=이전 동작
# 보존)이 **반대 방향**이다(rc=0 빈 값 vs rc=3). 그리고 부재(rc=3)와 문법 밖(rc=1)을
# 하나로 뭉치면, 편집 검증 훅(check-harness-env)이 안 쓰는 키의 정상 설정에도 경고를
# 내게 된다 — 경고가 소음이 되면 진짜 경고도 무시된다(ADR-0016). 3 을 쓰는 이유는
# decision_scan 과 같다: awk 자체의 비정상 종료(rc=2 등)가 정상 부재로 위장되지 않게
# 정상 경로에 흔한 코드를 주지 않는다. **기존 호출부는 전부 "rc!=0 = 못 믿음/부재"로
# 처리하므로 1↔3 구분 추가는 동작을 바꾸지 않는다** — 구분을 소비하는 곳만 갈라 읽는다.
#
# ── 지원 문법 (좁게 고정했다. 이 밖은 전부 rc=1) ───────────────────────
#   KEY=값  ·  export KEY=값   (export 뒤는 공백 또는 탭)
#   값: "겹따옴표"  ·  '홑따옴표'  ·  인용 없는 평문
#   닫는 따옴표 뒤에는 **공백**과 `# 주석` 만 올 수 있다 (`""#on` 은 문법 밖 — 셸에서
#     그 값은 `#on` 이라 비어 있지 않은데, 주석으로 읽으면 게이트가 꺼지는 방향이다)
#   인용 없는 값은 **공백에 이어지는 `#`** 부터가 주석이다 (`a#b`·`#on` 은 값 그대로)
# ── 지원하지 않는 것 (조용히 절반만 읽지 않고 rc=1 로 떨어진다) ────────
#   등호 바로 뒤의 공백(`KEY= x`) · 백슬래시 이스케이프 · 한 줄에 인용 조각 여러 개 ·
#   여러 줄 값 · 닫히지 않은 따옴표
#
# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 rc=1 이다.
#
# **인용 상태는 줄을 넘어 이어진다.** 셸의 인용은 개행에서 끝나지 않으므로, 다른 키의
# 여러 줄 값 본문 안에 이 키가 나타나도 그건 선언이 아니다. 이걸 줄 단위로만 보면
# `NOTES='...(개행)KEY=(개행)...'` 이 유일한 선언으로 판독돼 게이트가 꺼진다(실측).
#
# 히어독: `<<WORD`·`<<-WORD`·`<<'WORD'`·`<<"WORD"`·`<<\WORD` 를 인용 상태를 보며 찾아
# 본문을 건너뛴다(`"a << b"` 는 히어독이 아니다). 탐지가 어느 쪽으로 틀려도 결과는 rc=1 로
# 수렴한다 — 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다.
# EOF 까지 히어독이나 인용이 안 닫히면 파일을 못 믿는 것이므로 역시 rc=1.
# 한 줄에 히어독이 둘이면 첫 개만 본다.
#
# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **판독 시점에 확장되지 않는다** — 원문 그대로
# 값이 된다. 다만 그 값은 결국 `sh -c` 로 넘어가므로 **실행 시점에는 확장된다**
# (실측: `HARNESS_TYPECHECK_CMD='printf $HOME'` → 실행하면 홈 경로가 찍힌다).
# 즉 "확장되지 않는다"가 아니라 "**나중에** 확장된다"이다. 확장이 곤란한 자리라면
# 그 자리에 최종 문자열을 적어야 한다.
# 둘째 인자(선택)로 판독할 파일을 지정할 수 있다 — 편집 검증 훅이 "방금 편집된 그 파일"을
# 읽어야 하기 때문이다(다른 프로젝트의 harness.env 편집도 그 파일 기준으로 판정).
# 생략하면 이 프로젝트의 정본 경로다.
harness_env_value() {
  local file="${2:-$STATE_DIR/harness/harness.env}" key="$1" val rc
  [ -f "$file" ] || { printf '%s' ''; return 3; }
  if [ ! -r "$file" ]; then
    # "미설정"과 "읽기 실패"는 다르다. 판정은 같게(rc=1) 가되 실패는 소리를 낸다.
    printf '[하네스] harness.env 를 읽지 못했습니다 — 미설정으로 봅니다: %s\n' "$file" >&2
    printf '%s' ''
    return 1
  fi
  # LC_ALL=C 여야 substr 이 바이트 단위로 동작해 BOM 3바이트를 정확히 떼어낸다.
  val="$(LC_ALL=C awk -v key="$key" -v bom="$(printf '\357\273\277')" '
function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
function rtrim(s) { sub(/[ \t]+$/, "", s); return s }

# 히어독 시작을 찾는다. 따옴표 안의 `<<` 와 주석 뒤의 `<<` 는 히어독이 아니다.
# 인용 상태 OPENQ 는 **줄을 넘어 이어진다.** 셸의 인용은 개행에서 끝나지 않기 때문이다 —
# 다른 키의 여러 줄 값 본문 안에 우리 키가 있으면 그건 선언이 아니다. 이걸 줄 단위로만
# 보면 다른 키의 여러 줄 값 안에 있는 우리 키가 유일한 선언으로 판독돼
# **게이트가 꺼진다**(실측). 그래서 이 함수는 줄마다 OPENQ 를 이어받아 갱신한다.
function scan_line(s,   n, i, j, c, t, dash, q2) {
  n = length(s); i = 1
  while (i <= n) {
    c = substr(s, i, 1)
    if (OPENQ != "") { if (c == OPENQ) OPENQ = ""; i++; continue }
    if (c == "\\") { i += 2; continue }                            # 백슬래시 이스케이프
    if (c == "\"" || c == SQ) { OPENQ = c; i++; continue }
    if (c == "#" && (i == 1 || substr(s, i - 1, 1) == " " || substr(s, i - 1, 1) == "\t")) return
    if (c == "<" && substr(s, i + 1, 1) == "<") {
      if (substr(s, i + 2, 1) == "<") { i += 3; continue }         # <<< 는 히어스트링
      j = i + 2; dash = 0
      if (substr(s, j, 1) == "-") { dash = 1; j++ }
      while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
      t = ""
      # 종결어는 인용을 **섞을 수 있다**: EOF · "EOF" · EO"F" · \\EOF · E\\OF 가 전부
      # 같은 종결어 EOF 다. 한 형태만 읽으면 나머지에서 본문을 안 건너뛰고, 그 안의 빈
      # 게이트 선언이 진짜 선언으로 판독돼 **게이트가 꺼진다**. 그래서 조각을 이어 붙인다.
      while (j <= n) {
        c = substr(s, j, 1)
        if (c == " " || c == "\t" || c == ";" || c == "&" || c == "|" || c == ">" || c == "<") break
        if (c == "\\") { j++; if (j <= n) { t = t substr(s, j, 1); j++ } ; continue }
        if (c == "\"" || c == SQ) {
          q2 = c; j++
          while (j <= n && substr(s, j, 1) != q2) { t = t substr(s, j, 1); j++ }
          j++
          continue
        }
        t = t c; j++
      }
      if (t != "") { INHD = 1; HTERM = t; HDASH = dash; return }
      i = j
      continue
    }
    i++
  }
}

# 지원 문법대로 값을 판독한다. 문법 밖이면 BAD 를 세운다(빈 값으로 위장하지 않는다).
function parse_value(v,   q, rest, e, out, tail, i, c, p) {
  if (v == "") return ""
  # **등호 바로 뒤의 공백은 지원하지 않는다(rc=1).** 셸은 `KEY= x` 를 "빈 값 대입 + 명령 x"
  # 로 읽는데, 관대하게 값으로 삼으면 셸과 반대 방향으로 갈리고, 빈 값으로 삼으면
  # `KEY=  "on"` 이 조용히 게이트를 끈다. 어느 쪽도 안전하지 않아 문법 밖으로 돌린다.
  if (substr(v, 1, 1) == " " || substr(v, 1, 1) == "\t") { BAD = 1; return "" }
  q = substr(v, 1, 1)
  if (q == "\"" || q == SQ) {
    rest = substr(v, 2)
    e = index(rest, q)
    if (e == 0) { BAD = 1; return "" }                             # 닫히지 않은 따옴표
    out = substr(rest, 1, e - 1)
    tail = substr(rest, e + 1)
    if (tail != "") {
      # 닫는 따옴표 **바로 뒤**에는 공백이 와야 한다. `KEY=""#on` 은 셸에서 값이 `#on`
      # (비어 있지 않다)인데, 여기서 `#` 을 주석으로 받으면 빈 값이 되어 **게이트가 꺼진다.**
      if (substr(tail, 1, 1) != " " && substr(tail, 1, 1) != "\t") { BAD = 1; return "" }
      tail = ltrim(tail)
      if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음
    }
    return out
  }
  # 인용 없는 값에서 `#` 은 **공백 뒤에서만** 주석을 연다. `KEY=#on` 의 값은 셸에서
  # `#on` 이다 — 여기서 빈 값으로 읽으면 그 역시 게이트를 끄는 방향이다.
  out = ""
  for (i = 1; i <= length(v); i++) {
    c = substr(v, i, 1)
    if (c == "#" && i > 1) {
      p = substr(v, i - 1, 1)
      if (p == " " || p == "\t") break
    }
    out = out c
  }
  return rtrim(out)
}

BEGIN {
  SQ = sprintf("%c", 39)
  N = 0; FOUND = ""; INHD = 0; HTERM = ""; HDASH = 0; BAD = 0; OPENQ = ""
  RX = "^(export[ \t]+)?" key "="
}
{
  line = $0
  sub(/\r$/, "", line)
  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)

  if (INHD) {
    t = line
    if (HDASH) sub(/^\t+/, "", t)
    if (t == HTERM) { INHD = 0; HTERM = "" }
    next
  }

  # **인용이 이전 줄에서 열린 채면 이 줄은 값의 본문이지 선언이 아니다.**
  # 이 검사가 없으면 다른 키의 여러 줄 값 안에 있는 우리 키가 유일한 선언으로 판독돼
  # 게이트가 꺼진다(실측). 판정 전에 물어야 한다.
  if (OPENQ == "") {
    # 선언 판정이 히어독 시작 판정보다 **먼저**다: `KEY=v <<EOF` 의 대입은 실제로 발효한다.
    if (line ~ RX) {
      N++
      if (N == 1) FOUND = substr(line, index(line, "=") + 1)
    }
  }
  scan_line(line)
}
END {
  if (INHD) exit 1          # 히어독이 EOF 까지 안 닫혔다 = 탐지가 빗나갔다
  if (OPENQ != "") exit 1   # 인용이 EOF 까지 안 닫혔다 = 파일을 못 믿는다
  if (N == 0) exit 3        # 부재 — 안 쓰는 키의 정상 상태 (반환 계약 rc=3)
  if (N > 1) exit 1
  v = parse_value(FOUND)
  if (BAD) exit 1
  printf "%s", v
  exit 0
}
' "$file" 2>/dev/null)"
  rc=$?
  case "$rc" in
    0) printf '%s' "$val"; return 0 ;;
    3) printf '%s' ''; return 3 ;;
    # 그 밖(1 = 못 믿음, awk 비정상 종료 2·126·127 포함)은 전부 "못 믿음"으로 접는다 —
    # fail-closed. 부재로 위장되면 편집 검증 훅이 진짜 실수를 침묵으로 놓친다.
    *) printf '%s' ''; return 1 ;;
  esac
}

# 지식 반영 게이트가 켜져 있는가 (rc=0 켜짐 / rc=1 꺼짐).
#
# 하네스가 소유하는 것은 **계약 하나**뿐이다 — "지식 저장소가 설정돼 있으면, 결정·설계가
# 나온 턴은 반영 없이 끝낼 수 없다." 어디에 어떤 구조로 반영하는지는 이 층이 모른다.
# 그래서 필요한 것도 1비트뿐이고, 그 1비트를 얻으려고 파일을 실행하지 않는다.
#
# **기본이 켜짐인 것이 이 함수의 핵심이다.** 기존 설치본에는 이 키가 아예 없는데,
# 없을 때 "꺼짐"으로 읽으면 하네스를 갱신하는 순간 게이트가 **조용히 꺼진다** — 사용자는
# 지식이 쌓인다고 믿는데 그 턴부터 아무것도 안 남는다. 표명이 없으면 이전 동작을 보존한다.
# 선언이 2개 이상이거나 문법 밖일 때도 같은 이유로 켠다(rc=1 → 켜짐).
#
# 끄는 방법은 **값을 리터럴로 비우는 것 하나뿐**이다: HARNESS_KNOWLEDGE_GATE=""
# `="off"` 는 켜진 것으로 읽힌다 — 비어 있지 않기 때문이다. harness.env 주석에 명시돼 있다.
harness_knowledge_gate_on() {
  local v
  v="$(harness_env_value HARNESS_KNOWLEDGE_GATE)" || return 0   # 값을 못 믿으면 켠다
  [ -n "$v" ]                                                   # 리터럴로 비었을 때만 꺼짐
}

# 지식 게이트가 이번 턴에 **발효 중인가** — 플래그가 섰고 게이트도 켜져 있는가.
# 판정을 이 한 곳에 모은다. 두 군데서 따로 물으면 "게이트를 껐는데 남아 있던 플래그가
# 읽기 전용 턴의 조기 종료를 막는" 종류의 어긋남이 생긴다.
knowledge_gate_active() {
  [ -s "$KNOWLEDGE_FLAG" ] || return 1
  harness_knowledge_gate_on
}

# 회수 표명 게이트에 **할 일이 남았는가** — 플래그가 섰고 훅도 살아 있는가.
#
# 이름을 *_gate_active 로 짓지 않았다. knowledge_gate_active 는 "플래그 + harness.env
# 스위치"이고 개별 훅 비활성(stop:knowledge)은 호출부가 따로 보는데, retrieval 은 env
# 스위치가 없어 끄는 방법이 ECC_DISABLED_HOOKS=stop:retrieval **하나뿐**이다. 그래서
# 비활성이 곧 "할 일 없음"이고 이 함수 하나에 접는다 — 안 접으면 게이트를 끈 환경에서
# 남은 플래그가 영영 안 지워진 채 읽기 전용 턴의 조기 종료를 막고, 그 소음이 예산을
# 소진시켜 다른 게이트 플래그까지 지워버린다(설계 검수 [cc] r2 H5 시나리오).
# 플래그 5종 중 이것만 이런 의미라는 사실은 docs/usage.md 에 공시돼 있다.
retrieval_pending() {
  [ -s "$RETRIEVAL_FLAG" ] || return 1
  ! hook_disabled "stop:retrieval"
}

# stdin 의 JSON 에서 점 경로로 값 하나를 뽑는다. 없거나 파싱 실패면 빈 문자열.
# 훅 입력이 깨져도 절대 죽지 않는다 — 죽으면 오탐 차단이 된다.
json_get() {
  python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for key in sys.argv[1].split("."):
    if not isinstance(data, dict):
        sys.exit(0)
    data = data.get(key)
    if data is None:
        sys.exit(0)
print(data)
' "$1" 2>/dev/null
}

# 이 턴의 대화 기록을 읽어 **"물어봤어야 할 것을 혼자 정했다"는 자백**을 찾는다.
#
# 왜 이런 게이트가 필요한가: 완료 게이트 넷(타입체크·듀얼리뷰·변경설명·지식반영)은 전부
# **산출물**을 본다. 에이전트 자신의 행동을 겨눈 것은 없었고, 그 비대칭이 실물로 드러났다 —
# 게이트가 막을 때는 세 번 다 따랐는데, 게이트가 없는 축에서는 전부 혼자 정하고 보고서에
# 한 줄 적었다. 그 "한 줄"은 **도구 호출이 아니라 문장**이라 어떤 PreToolUse 훅도 볼 수 없고
# 승인창도 안 뜬다(승인창은 *한 일*에만 뜬다). 그래서 Stop 이 대화 기록을 직접 읽는다.
#
# ── 판정 ─────────────────────────────────────────────────────────────
#   결정 표지 어휘를 담은 **서술형** 문장이 있는데  AND  이 턴에 AskUserQuestion 이 0회
#   → 차단. 질문을 한 번 하면 풀리므로 세션이 벽돌이 되지 않는다.
#
# 표지 어휘를 이렇게 고른 이유: 저 말들은 "물어봤어야 할 것을 혼자 정했다"를 **자백**할
# 때만 나온다. 자백은 있는데 질문이 0회면 그 자체가 위반이다.
#
# ── 좁히는 장치 셋 (위양성 억제) ─────────────────────────────────────
# 어휘만 보면 이 게이트를 **유지보수하는 작업 자체가 매번 걸린다** — 훅·테스트·결정 문서가
# 그 어휘를 데이터로 품기 때문이다. 그러면 사람이 게이트를 끄게 되고 그게 최악이다.
#   1) 구조적 제외 — 코드펜스 · 인라인 코드 · 인용줄(>) · 따옴표로 감싼 부분은 안 본다.
#      그래서 어휘를 **인용부호로 감싸 언급하는 것**은 안 걸린다(문서·설명의 정상 형태다).
#   2) 질문 신호 제외 — 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다.
#   3) 서술형 종결 요구 — "…했다/…습니다" 같은 단정으로 끝나야 "내가 그렇게 했다"이다.
# 대가는 위음성 증가다. 표현을 바꾸면 빠져나간다 — 겨누는 것이 적대적 회피가 아니라
# **무의식적 습관**이라 그래도 실효가 남는다. guard-hook-disable 과 같은 판단 구조다.
#
# **도구 입력은 보지 않는다(text 블록만 본다).** 그래서 이 패턴이 적힌 파일을 Write/Edit
# 로 쓰는 것은 안 걸린다 — 자기참조 폭발을 원천에서 없애는 장치다.
# thinking 블록도 안 본다: 거기서 선택지를 저울질하는 것은 결정 통보가 아니다.
# 서브에이전트 발화(isSidechain)도 뺀다: 서브에이전트는 사용자에게 물을 수 없다.
#
# ── 반환 계약 ─────────────────────────────────────────────────────────
#   rc=0 : 차단해야 한다. stdout = 걸린 문장들(줄당 하나)
#   rc=2 : **판독 불가.** stdout = 사유 한 줄
#   rc=3 : 차단 불필요 (표지 없음 · 또는 이 턴에 질문을 했음)
#   그 밖 : **예상 밖.** python3 부재(127) · 처리 못 한 예외(1) · 신호 종료 등
#
# "차단 불필요"에 1 이 아니라 **3** 을 쓰는 이유: python 이 처리 못 한 예외로 죽으면
# 그것도 1 이라, 1 을 정상 통과로 쓰면 **크래시가 조용한 통과로 위장된다.** 정상 경로에
# 흔한 코드를 주지 않으면 호출부가 "모르는 rc = 무언가 잘못됐다"로 갈라낼 수 있다.
# 호출부는 0·2·3 만 알고 나머지는 전부 판독 불가로 취급해야 한다.
#
# ── rc=2 가 이 게이트의 유일한 fail-open 지점이다 ────────────────────
# 대화 기록의 형식은 하네스가 소유하지 않는다 — 도구 제공자가 정하고 예고 없이 바뀐다.
# 형식이 바뀌었다고 차단하면 **세션이 통째로 벽돌이 되는데 그 세션 안에 고칠 방법이 없다**
# (기록을 고칠 수는 없으므로 어떤 행동으로도 게이트가 안 풀린다). 그래서 여기서만 통과로
# 간다. 나머지 판정은 전부 fail-closed 다.
# **조건은 경고를 삼키지 않는 것이다** — 호출부가 이 사유를 마지막 게이트 메시지에 싣는다.
# 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다.
decision_scan() {   # $1 = 대화 기록(JSONL) 경로
  local path="$1"
  [ -n "$path" ] || { printf '%s\n' '대화 기록 경로가 훅 입력에 없습니다'; return 2; }
  [ -r "$path" ] || { printf '%s\n' "대화 기록을 읽을 수 없습니다: $path"; return 2; }
  python3 - "$path" <<'PY'
import json, re, sys

# 결정 표지. 굴절 변형만 최소로 넓혔고 그 이상 넓히지 않는다 — 넓히면 위양성이 늘고,
# 위양성이 늘면 질문이 소음이 되고, 소음이 되면 진짜 질문도 무시된다.
MARKER = re.compile(
    "공시하|공시했|공시함"
    "|범위 ?밖"
    "|별도로"
    "|그대로 (?:뒀|두었|남겼|남겨)"
    "|(?:제|내) 판단으로"
    "|가정하(?:고|여|였|겠)|가정했"
    "|수용(?:된|한) 한계"
    "|트레이드오프"
    "|안 했(?:습니다|다|음)"
)
# 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다.
QUESTION = re.compile(
    "\\?|까요|나요|ㄹ까|을까|할까|여쭤|여쭈|여쭙|물어|어떠신|어느 쪽"
    "|골라|선택해|정해 ?주|알려 ?주|괜찮으신|의견"
)
# **"묻지 않았다"는 물음이 아니라 자백이다.** 이게 없으면 겨누는 문장 자체가 빠져나간다 —
# "사용자에게 물어보지 않고 제 판단으로 진행했습니다" 는 `물어` 때문에 질문으로 오인된다.
# 부정이 붙으면 위 QUESTION 제외를 적용하지 않는다.
NEG_ASK = re.compile(
    "물어 ?보지 ?않|물어 ?보지도|묻지 ?않|묻지도|여쭙지 ?않|여쭈지 ?않|여쭤 ?보지 ?않"
    "|확인(?:도)? ?하지 ?않|확인 ?없이|의견을 받지 ?않|물어 ?보는 대신|묻는 대신|묻지 못"
)
# 서술형 종결. "내가 그렇게 했다"는 단정만 잡는다.
DECLARATIVE = re.compile("(?:다|음|함|됨|임|옴)$")

# 이중 백틱 코드 span 이 먼저다 — 단일 규칙만 두면 ``a`b`` 의 안쪽이 산문으로 샌다.
INLINE     = re.compile("``[^`\n]*``|`[^`\n]*`")
QUOTED     = re.compile("\"[^\"\n]*\"|'[^'\n]*'|“[^”\n]*”"
                        "|‘[^’\n]*’|「[^」\n]*」"
                        "|『[^』\n]*』")
BLOCKQUOTE = re.compile("^\\s{0,3}>")
# **공시된 한계:** 약어(`e.g.` 등)는 뒤에 공백이 오므로 여전히 문장을 자른다. 그 조각에
# 표지와 서술형 종결이 갈리면 놓친다. 약어 목록을 들고 다니는 것은 또 하나의 추측이라
# 하지 않는다 — 좁은 창으로 공시한다.
# 마침표는 **뒤에 공백이나 줄끝이 올 때만** 문장 종결이다. 무조건 종결로 보면
# `README.md`·`_common.sh`·버전 번호가 한 문장을 쪼개, 표지와 서술형 종결이 서로 다른
# 조각으로 갈라져 **둘 다 만족하는 조각이 없어진다**(위음성).
SENT       = re.compile("([\n!?…。！？]+|\\.(?=\\s)|\\.$)")
LEAD       = re.compile("^[\\s*_>#\\-–—•·]+")
TRAIL      = re.compile("[\\s*_`~\\[\\](){}<>:;,·…\\-—–]+$")

MAX_HITS, MAX_LEN = 8, 140
# 아는 블록 타입. 이 밖이 나오면 그 발화를 볼 수 없다는 뜻이라 판독 불가로 떨어뜨린다.
KNOWN_BLOCKS = ("text", "thinking", "redacted_thinking", "tool_use", "tool_result", "image")


def fail(reason):
    sys.stdout.write(reason + "\n")
    raise SystemExit(2)


def drop_fences(s):
    # 짝수 조각만 코드 **밖**이다. 펜스가 안 닫혔으면 마지막 조각은 코드 안으로 친다 —
    # 스트리밍 중 잘린 기록에서 코드가 산문으로 새는 것을 막는다.
    # 백틱만 보면 `~~~` 펜스의 예문이 산문으로 검사된다(문서가 약속한 범위보다 좁다).
    for fence in ("```", "~~~"):
        s = "\n".join(p for i, p in enumerate(s.split(fence)) if i % 2 == 0)
    return s


def is_user_prompt(e):
    if e.get("type") != "user" or e.get("isSidechain"):
        return False
    if e.get("isMeta"):
        # **사람이 하지 않은 발화다.** 훅 피드백·자동 이어하기가 여기 온다.
        # 경계로 세면 이 훅이 낸 차단 메시지가 스스로 새 턴을 열어, 방금 막은 자백이
        # 다음 턴의 창 **밖**으로 밀려난다 — 게이트가 한 번 막고 스스로 물러난다.
        # 질문을 한 번도 안 했는데 rc=3(차단 불필요)으로 통과하고 경고조차 안 남는다.
        # 검수 CRITICAL 로 적발됐고 실기록에서 재현했다([cc] 2라운드).
        #
        # **구조 표시로 판정한다.** 메시지 문구("Stop hook feedback:")로 거르면 문구가
        # 바뀌는 날 아무도 모르게 이 결함으로 되돌아간다 — 이 저장소가 반복해서 데인 부류다.
        return False
    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
        return False
    msg = e.get("message")
    if not isinstance(msg, dict):
        return False
    content = msg.get("content")
    if isinstance(content, list):
        for b in content:
            if isinstance(b, dict) and b.get("type") == "tool_result":
                return False
    return True


try:
    with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as fh:
        raw = fh.read()
except Exception as exc:
    fail("대화 기록을 열지 못했습니다: %s" % exc.__class__.__name__)

lines = [ln for ln in raw.splitlines() if ln.strip()]
entries, broken = [], 0
for ln in lines:
    try:
        entries.append(json.loads(ln))
    except Exception:
        broken += 1
# **한 줄이라도 못 읽으면 판독 불가다.** 건너뛰면 그 줄이 하필 자백이 담긴 발화이거나
# 이 턴의 사용자 프롬프트일 때 조용히 새고, 후자는 경계가 **지난 턴으로 밀려** 위양성까지
# 낳는다. "전멸일 때만 실패"로 두면 부분 손상이라는 가장 흔한 경우를 정확히 놓친다.
if broken:
    fail("대화 기록 %d줄을 파싱하지 못했습니다 (형식이 바뀌었을 수 있습니다)" % broken)
if not entries:
    fail("대화 기록이 비어 있습니다")

start = -1
for i, e in enumerate(entries):
    if not isinstance(e, dict):
        # 유효한 JSON 이지만 dict 가 아닌 줄(`[]` 등). 건너뛰면 그 줄이 무엇이었는지
        # 모른 채 통과한다 — 형식 변화의 신호로 보고 소리를 낸다.
        fail("대화 기록에 dict 가 아닌 항목이 있습니다 (형식이 바뀌었을 수 있습니다)")
    if is_user_prompt(e):
        start = i
if start < 0:
    # 사용자 프롬프트가 없는 기록은 있을 수 없다 — 경계를 못 찾았다는 뜻이다.
    # 전체를 훑으면 지난 턴의 문장까지 걸려 위양성이 폭주하므로 판독 불가로 떨어뜨린다.
    fail("이 턴의 시작점(사용자 프롬프트)을 찾지 못했습니다 (형식이 바뀌었을 수 있습니다)")

asked, texts = 0, []
for e in entries[start + 1:]:
    if e.get("type") != "assistant" or e.get("isSidechain"):
        continue
    msg = e.get("message")
    if not isinstance(msg, dict):
        # truthy 비-dict 를 `or {}` 로 받으면 여기서 예외가 나고, 그 예외는 아래 "표지 없음"과
        # 구별되지 않는 종료 코드로 나간다 — 조용한 통과다. 형식 변화로 보고 소리를 낸다.
        fail("assistant 항목의 message 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
    content = msg.get("content")
    if isinstance(content, str):
        # 문자열 본문도 발화다. 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
        texts.append(content)
        continue
    if not isinstance(content, list):
        # 볼 수 없는 발화가 있다 = 사각지대다. 조용히 건너뛰면 게이트가 죽은 줄도 모른다.
        fail("assistant 항목의 content 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
    for b in content:
        if not isinstance(b, dict):
            # 블록이 dict 가 아니면 그 안의 발화를 볼 수 없다 = 사각지대다.
            # 실측: content 가 ["문장"] 형태면 조용히 버려져 rc=3 으로 통과했다.
            fail("assistant content 블록 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
        if b.get("type") == "tool_use":
            if b.get("name") == "AskUserQuestion":
                asked += 1
        elif b.get("type") == "text":
            t = b.get("text")
            if not isinstance(t, str):
                fail("text 블록의 text 필드가 문자열이 아닙니다 (형식이 바뀌었을 수 있습니다)")
            texts.append(t)
        elif b.get("type") not in KNOWN_BLOCKS:
            # **블록 타입 이름이 바뀌면 발화가 조용히 사라진다.** 컨테이너만 검사하고
            # 그 안의 타입을 안 보면 비대칭이다 — 형식 변경은 컨테이너보다 블록 쪽이
            # 더 흔하다. 실측: {"type":"output_text","text":"…제 판단으로 정했습니다."}
            # 가 rc=3(차단 불필요)으로 조용히 통과했다([cc] 2라운드).
            fail("모르는 assistant 블록 타입입니다: %r (형식이 바뀌었을 수 있습니다)"
                 % (b.get("type"),))

if asked > 0:
    raise SystemExit(3)

hits, seen = [], set()
for text in texts:
    for line in drop_fences(text).split("\n"):
        if BLOCKQUOTE.match(line):
            continue
        line = QUOTED.sub(" ", INLINE.sub(" ", line))
        chunks = SENT.split(line)
        for i in range(0, len(chunks), 2):
            body = chunks[i]
            whole = body + (chunks[i + 1] if i + 1 < len(chunks) else "")
            # 부정이 붙으면 물음이 아니라 자백이다 — "물어보지 않고 …했습니다".
            if QUESTION.search(whole) and not NEG_ASK.search(whole):
                continue
            core = TRAIL.sub("", LEAD.sub("", body).strip())
            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):
                continue
            if core in seen:
                continue
            seen.add(core)
            hits.append(core if len(core) <= MAX_LEN else core[:MAX_LEN] + "…")

if not hits:
    raise SystemExit(3)
for h in hits[:MAX_HITS]:
    sys.stdout.write(h + "\n")
if len(hits) > MAX_HITS:
    sys.stdout.write("... 그리고 %d개 더\n" % (len(hits) - MAX_HITS))
raise SystemExit(0)
PY
}
