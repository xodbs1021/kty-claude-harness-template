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
DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
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
#   ① 파일 첫머리 BOM 제거 → ② 각 줄 후행 CR 제거 → ③ 히어독 본문 배제 →
#   ④ 선언 판정 → ⑤ 값 앞 공백 절단 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 **밖** 후행 주석
#   → ⑧ 남은 후행 공백 절단
#
# ── 반환 계약 ──────────────────────────────────────────────────────────
#   rc=0 : 최상위 선언이 **정확히 1개**이고 값을 지원 문법으로 판독했다.
#          stdout = 판독된 값. **빈 문자열일 수 있다** — "리터럴로 비웠다"는 뜻이다.
#   rc=1 : 값을 믿을 수 없다 — 파일 없음 · 읽기 실패 · 선언 0개 · 선언 2개 이상 ·
#          지원 문법 밖. stdout = 빈 문자열.
#
# 왜 이 둘을 rc 로 가르나: 스위치형 슬롯은 "리터럴로 비웠다"(=끈다)와 "미설정"(=이전
# 동작 보존)이 **반대 방향**이다. 빈 문자열 하나로 뭉뚱그리면 키가 없는 기존 설치본이
# 업그레이드 순간 게이트가 꺼진 것과 구별되지 않는다.
#
# ── 지원 문법 (좁게 고정했다. 이 밖은 전부 rc=1) ───────────────────────
#   KEY=값  ·  export KEY=값   (export 뒤는 공백 또는 탭)
#   값: "겹따옴표"  ·  '홑따옴표'  ·  인용 없는 평문
#   따옴표 뒤에는 공백과 `# 주석` 만 올 수 있다
#   인용 없는 값은 **공백에 이어지는 `#`** 부터가 주석이다 (`a#b` 의 `#` 은 값의 일부)
#   값 자리가 `#` 로 시작하면 값은 비어 있는 것으로 본다
# ── 지원하지 않는 것 (조용히 절반만 읽지 않고 rc=1 로 떨어진다) ────────
#   백슬래시 이스케이프 · 한 줄에 인용 조각 여러 개(`"a"b`) · 여러 줄 값 ·
#   닫히지 않은 따옴표
#
# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 rc=1 이다.
#
# 히어독: `<<WORD`·`<<-WORD`·`<<'WORD'` 을 **따옴표 상태를 보며** 찾아 본문을 건너뛴다
# (`"a << b"` 는 히어독이 아니다). 탐지가 어느 쪽으로 틀려도 결과는 rc=1 로 수렴한다 —
# 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다. EOF 까지 안 닫히면
# 탐지가 빗나간 것이므로 역시 rc=1. 한 줄에 히어독이 둘이면 첫 개만 본다.
#
# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **판독 시점에 확장되지 않는다** — 원문 그대로
# 값이 된다. 다만 그 값은 결국 `sh -c` 로 넘어가므로 **실행 시점에는 확장된다**
# (실측: `HARNESS_TYPECHECK_CMD='printf $HOME'` → 실행하면 홈 경로가 찍힌다).
# 즉 "확장되지 않는다"가 아니라 "**나중에** 확장된다"이다. 확장이 곤란한 자리라면
# 그 자리에 최종 문자열을 적어야 한다.
harness_env_value() {
  local file="$STATE_DIR/harness/harness.env" key="$1" val rc
  [ -f "$file" ] || { printf '%s' ''; return 1; }
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
function scan_heredoc(s,   n, i, j, c, q, t, dash) {
  n = length(s); i = 1; q = ""
  while (i <= n) {
    c = substr(s, i, 1)
    if (q != "") { if (c == q) q = ""; i++; continue }
    if (c == "\"" || c == SQ) { q = c; i++; continue }
    if (c == "#" && (i == 1 || substr(s, i - 1, 1) == " " || substr(s, i - 1, 1) == "\t")) return
    if (c == "<" && substr(s, i + 1, 1) == "<") {
      if (substr(s, i + 2, 1) == "<") { i += 3; continue }        # <<< 는 히어스트링
      j = i + 2; dash = 0
      if (substr(s, j, 1) == "-") { dash = 1; j++ }
      while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
      t = ""; c = substr(s, j, 1)
      if (c == "\"" || c == SQ) {                                  # <<"EOF" · <<EOF
        j++
        while (j <= n && substr(s, j, 1) != c) { t = t substr(s, j, 1); j++ }
      } else {
        while (j <= n) {
          c = substr(s, j, 1)
          if (c ~ /[A-Za-z0-9_.\/-]/) { t = t c; j++ } else break
        }
      }
      if (t != "") { INHD = 1; HTERM = t; HDASH = dash }
      return
    }
    i++
  }
}

# 지원 문법대로 값을 판독한다. 문법 밖이면 BAD 를 세운다(빈 값으로 위장하지 않는다).
function parse_value(v,   q, rest, e, out, tail, i, c, p) {
  # 여기서는 **앞** 공백만 턴다. 뒤 공백은 갈래마다 다른 자리에서 털린다 —
  # 인용 값은 닫는 따옴표 뒤(tail)에서, 인용 없는 값은 반환 직전 rtrim(out) 에서.
  # 여기서 한 번 더 rtrim 하면 어느 변이로도 죽지 않는 죽은 줄이 된다(변이 측정으로 확인).
  v = ltrim(v)
  if (v == "") return ""
  q = substr(v, 1, 1)
  if (q == "\"" || q == SQ) {
    rest = substr(v, 2)
    e = index(rest, q)
    if (e == 0) { BAD = 1; return "" }                             # 닫히지 않은 따옴표
    out = substr(rest, 1, e - 1)
    tail = ltrim(substr(rest, e + 1))
    if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음
    return out
  }
  if (q == "#") return ""                                          # 값 자리가 통째로 주석
  out = ""
  for (i = 1; i <= length(v); i++) {
    c = substr(v, i, 1)
    if (c == "#") {
      p = substr(v, i - 1, 1)
      if (p == " " || p == "\t") break
    }
    out = out c
  }
  return rtrim(out)
}

BEGIN {
  SQ = sprintf("%c", 39)
  N = 0; FOUND = ""; INHD = 0; HTERM = ""; HDASH = 0; BAD = 0
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

  # 선언 판정이 히어독 시작 판정보다 **먼저**다: `KEY=v <<EOF` 의 대입은 실제로 발효한다.
  if (line ~ RX) {
    N++
    if (N == 1) FOUND = substr(line, index(line, "=") + 1)
  }
  scan_heredoc(line)
}
END {
  if (INHD) exit 1          # 히어독이 EOF 까지 안 닫혔다 = 탐지가 빗나갔다
  if (N != 1) exit 1
  v = parse_value(FOUND)
  if (BAD) exit 1
  printf "%s", v
  exit 0
}
' "$file" 2>/dev/null)"
  rc=$?
  [ "$rc" -eq 0 ] || { printf '%s' ''; return 1; }
  printf '%s' "$val"
  return 0
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
