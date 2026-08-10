#!/usr/bin/env bash
# harness-env-read.test.sh — harness.env **원문 판독**의 회귀 테스트.
#
# 왜 있나 (2026-08-07 실사고): `harness.env` 를 source 하던 것을 원문 판독으로 바꿔
# 임의 코드 실행 부류를 없앴는데, **셸이 대신 해주던 파싱을 물려받으면서** 새 fail-open
# 6종이 생겼다. 후행 주석 · 후행 공백 · CRLF 의 `\r` · 파일 앞 BOM · 히어독 본문의 같은 키.
# 앞 넷은 값에 쓰레기가 섞여 `sh -c` 가 rc=127 을 내고, 훅이 그걸 "도구가 없구나"로 읽어
# **타입체크 게이트가 흔적 없이 사라진다.** 넷 중 둘(후행 공백·CR)은 눈에 보이지도 않는다.
#
# 무엇을 붙드나 — 두 층이다:
#   [파서]   harness_env_value 의 반환 계약. rc(0=판독됨 / 1=믿을 수 없음)와 **값의 바이트**.
#            rc 를 값과 함께 재는 이유: "리터럴로 비웠다"와 "미설정"은 스위치형 슬롯에서
#            **반대 방향**이라 빈 문자열 하나로 뭉뚱그리면 그 구별이 사라진다.
#   [통합]   verify-before-stop.sh 를 **실제로 돌려** ① 적대적 harness.env(exit 0/1·return·
#            printf 재정의)가 나머지 게이트를 죽이지 못하는지 ② 후행 주석·CRLF·BOM 이 붙은
#            명령이 **정말 실행되는지** 를 본다.
#
# 통합 케이스가 rc 만 보지 않는 이유: 타입체크를 건너뛰어도 뒤의 감사 게이트가 어차피
# rc=2 로 막는다. 그래서 **어느 게이트가 막았는지의 문구**까지 재야 판별력이 생긴다.
# rc 만 보면 파서를 통째로 되돌려도 전건 초록이다.
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
#
# 이 파일 자신도 못 믿는다. 러너는 넷을 스스로 검사한다:
#   1) CASES 목록의 개수·중복  2) 실행 수 vs 기대 수  3) pass+fail == ran  4) DID_RUN 센티널
#
# 환경 전제 (전부 fail-closed): python3 부재 → exit 1 (통합 케이스의 json_get 의존).
# root 실행 → 읽기 권한 픽스처가 성립하지 않는다(root 는 -r 가 항상 참). 그 케이스만 실패.
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
#
# 사용법: ./tests/harness-env-read.test.sh   (전건 통과 시 종료 코드 0)

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
COMMON="$REPO_ROOT/template/.claude/hooks/_common.sh"
STOP_HOOK="$REPO_ROOT/template/.claude/hooks/verify-before-stop.sh"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (Stop 훅의 json_get 의존)" >&2; exit 1; }
[ -f "$COMMON" ]    || { echo "✗ _common.sh 를 찾지 못했습니다: $COMMON" >&2; exit 1; }
[ -f "$STOP_HOOK" ] || { echo "✗ verify-before-stop.sh 를 찾지 못했습니다: $STOP_HOOK" >&2; exit 1; }

# mktemp 실패를 확인하지 않으면 TMPROOT 가 빈 문자열이 되고 이후 경로가 전부
# 파일시스템 **루트**를 가리킨다.
TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
  exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
# chmod 는 읽기 권한 케이스가 harness.env 를 000 으로 만들기 때문에 필요하다.
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

KEY='HARNESS_TYPECHECK_CMD'

# 훅 문구가 다듬어져도 계약이 살아 있으면 계속 맞는 최소 조각.
TOK_TC_FAIL='타입체크 실패'
TOK_AUDIT='completion-auditor 미실행'
TOK_READ_FAIL='읽지 못했습니다'   # _common.sh 가 stderr 로 내는 읽기 실패 경고
TOK_UNREADABLE='읽지 못함'        # Stop 훅이 사용자에게 내는 생략 사유
TOK_EMPTY_SET='빈 값으로 설정됨'
TOK_KNOWLEDGE='지식 저장소 반영 미확인'
GKEY='HARNESS_KNOWLEDGE_GATE'

# --- 픽스처 --------------------------------------------------------------

# new_project <harness.env 내용|__NOFILE__> — 훅 2개를 설치한 가짜 프로젝트를 만들고
# 그 경로를 낸다. 내용은 **바이트 그대로** 쓴다(printf '%s' — 이스케이프 재해석 없음).
# 호출부가 $'...' 로 CR·탭·BOM 을 정확히 지정한다. %b 를 쓰면 이 테스트가 붙들려는
# 바로 그 축(보이지 않는 바이트)이 러너 안에서 조용히 변조된다.
new_project() {
  local body="$1" p
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { FIXTURE_FAIL='임시 디렉토리 생성 실패'; return 1; }
  p="$(CDPATH='' cd -- "$p" && pwd -P)"
  if ! mkdir -p "$p/.claude/hooks" "$p/.claude/harness" 2>/dev/null; then
    FIXTURE_FAIL="프로젝트 골격을 만들지 못했다: $p"; return 1
  fi
  cp "$COMMON"    "$p/.claude/hooks/_common.sh"            || { FIXTURE_FAIL='_common.sh 복사 실패'; return 1; }
  cp "$STOP_HOOK" "$p/.claude/hooks/verify-before-stop.sh" || { FIXTURE_FAIL='Stop 훅 복사 실패'; return 1; }
  if [ "$body" != '__NOFILE__' ]; then
    if ! { printf '%s' "$body" > "$p/.claude/harness/harness.env"; } 2>/dev/null; then
      FIXTURE_FAIL='harness.env 를 쓰지 못했다'; return 1
    fi
  fi
  printf '%s\n' "$p"
}

# --- 실행 헬퍼 -----------------------------------------------------------

VAL=''; VRC=999; VERR=''
HRC=999; HOUT=''; HERR=''
DID_RUN=0        # 이번 케이스에서 실제로 돌렸는가 — 직전 케이스 결과 재판정 방지 센티널
FIXTURE_FAIL=''

# read_value <proj> — harness_env_value 를 부르고 VAL(바이트 보존)·VRC·VERR 을 채운다.
# 센티널 X 를 붙여 받는 이유: 명령 치환이 후행 개행·공백을 지우면 "값이 그렇게 끝났다"와
# "치환이 먹었다"가 구분되지 않는다. 이 테스트가 붙들려는 결함이 정확히 그 부류다.
# 앰비언트 탈출구를 소거한다 — 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off 를
# export 한 셸에서 돌기 때문이다. 소거하지 않으면 통합 행이 통째로 무판정이 된다.
read_value() {
  local proj="$1" raw errf="$TMPROOT/verr.$$"
  VAL=''; VRC=999; VERR=''; DID_RUN=1
  raw="$(env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
         bash -c '
           . "$0/.claude/hooks/_common.sh"
           harness_env_value "$1"; rc=$?
           printf X
           exit $rc
         ' "$proj" "$KEY" 2>"$errf")"
  VRC=$?
  VAL="${raw%X}"
  VERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

# run_stop_hook <proj> [env 인자...] — 감사 플래그 **하나만** 세우고 Stop 훅을 돌린다.
# 하나만 세우는 것이 계약이다: 넷 다 세우면 앞선 게이트(듀얼리뷰·설명)가 먼저 막아
# 타입체크 축이 문구로도 안 보인다.
run_stop_hook() {
  local proj="$1" errf="$TMPROOT/herr.$$"
  shift
  HRC=999; HOUT=''; HERR=''; DID_RUN=1
  printf 'gate-target.ts\n' > "$proj/.claude/.needs-audit"
  _invoke_stop_hook "$proj" "$errf" ${@+"$@"}
}

# run_knowledge_probe <proj> — **지식 플래그 하나만** 세우고 Stop 훅을 돌린다.
# 게이트가 켜졌으면 지식 게이트 문구로 rc=2, 꺼졌으면 할 일이 없어 rc=0 이다.
#
# 이 프로브는 harness.env 의 키 개수와 값을 **직접 해석하지 않는다.** 판독 규칙의 사본을
# 테스트에 두면 그 사본이 언젠가 원본과 어긋나고, 그때 테스트는 **틀린 기준으로 초록**을
# 낸다. 훅 자신을 돌려 차단되는지만 본다.
run_knowledge_probe() {
  local proj="$1" errf="$TMPROOT/kerr.$$"
  shift
  HRC=999; HOUT=''; HERR=''; DID_RUN=1
  printf 'gate-target.ts\n' > "$proj/.claude/.needs-knowledge"
  _invoke_stop_hook "$proj" "$errf" ${@+"$@"}
}

_invoke_stop_hook() {
  local proj="$1" errf="$2"
  shift 2
  HOUT="$(printf '{"stop_hook_active": false}' \
          | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
                bash "$proj/.claude/hooks/verify-before-stop.sh" 2>"$errf")"
  HRC=$?
  HERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

# --- 판정 헬퍼 -----------------------------------------------------------

ran=0; pass=0; fail=0

report() {
  local name="$1" why="$2"
  if [ -z "$why" ]; then
    pass=$((pass + 1)); printf '  ✓ %s\n' "$name"
  else
    fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$name" "$why"
  fi
}

# pcase <이름> <기대rc> <기대값> <harness.env 내용> [기대 stderr 조각]
# 기대값은 **바이트 그대로** 비교한다.
pcase() {
  local name="$1" want_rc="$2" want_val="$3" body="$4" want_err="${5-}" proj why=''
  if ! proj="$(new_project "$body")"; then
    report "$name" "픽스처 구성 실패: $FIXTURE_FAIL"; return 0
  fi
  read_value "$proj"
  if [ "$DID_RUN" -ne 1 ]; then
    why='판독을 실행하지 않았다 (직전 케이스 결과를 재판정할 뻔했다)'
  elif [ "$VRC" -ne "$want_rc" ]; then
    why="rc=$VRC (기대 $want_rc), 값=[$VAL]"
  elif [ "$VAL" != "$want_val" ]; then
    why="값=[$VAL] (기대 [$want_val])"
  elif [ -z "$want_err" ] && [ -n "$VERR" ]; then
    why="stderr 가 비어 있지 않다: [$VERR]"
  elif [ -n "$want_err" ]; then
    case "$VERR" in
      *"$want_err"*) ;;
      *) why="stderr 에 기대 문구가 없다: $want_err (실제 [$VERR])" ;;
    esac
  fi
  report "$name" "$why"
}

# gcase <이름> <on|off> <harness.env 내용> — 지식 게이트가 켜졌는지 훅으로 잰다.
#   on  → rc=2 이고 지식 게이트 문구가 나온다
#   off → rc=0 이고 stderr 가 비어 있다 (할 일이 없어 조기 종료)
gcase() {
  local name="$1" want="$2" body="$3" proj why=''
  if ! proj="$(new_project "$body")"; then
    report "$name" "픽스처 구성 실패: $FIXTURE_FAIL"; return 0
  fi
  run_knowledge_probe "$proj"
  if [ "$DID_RUN" -ne 1 ]; then
    why='훅을 실행하지 않았다'
  elif [ "$want" = 'on' ]; then
    if [ "$HRC" -ne 2 ]; then
      why="게이트가 켜져야 하는데 rc=$HRC (기대 2) / stderr=[$(printf '%s' "$HERR" | head -c 200)]"
    else
      case "$HERR" in
        *"$TOK_KNOWLEDGE"*) ;;
        *) why="지식 게이트가 아닌 다른 이유로 막았다: [$(printf '%s' "$HERR" | head -c 200)]" ;;
      esac
    fi
  else
    if [ "$HRC" -ne 0 ]; then
      why="게이트가 꺼져야 하는데 rc=$HRC / stderr=[$(printf '%s' "$HERR" | head -c 200)]"
    elif [ -n "$HERR" ]; then
      why="꺼진 게이트가 stderr 를 냈다: [$(printf '%s' "$HERR" | head -c 200)]"
    fi
  fi
  report "$name" "$why"
}

# hcase <이름> <기대rc> <있어야 할 문구> <있으면 안 되는 문구|-> <내용> [env 인자...]
hcase() {
  local name="$1" want_rc="$2" want="$3" forbid="$4" body="$5" proj why=''
  shift 5
  if ! proj="$(new_project "$body")"; then
    report "$name" "픽스처 구성 실패: $FIXTURE_FAIL"; return 0
  fi
  run_stop_hook "$proj" ${@+"$@"}
  if [ "$DID_RUN" -ne 1 ]; then
    why='훅을 실행하지 않았다'
  elif [ "$HRC" -ne "$want_rc" ]; then
    why="종료 코드 $HRC (기대 $want_rc) / stderr=[$(printf '%s' "$HERR" | head -c 200)]"
  else
    case "$HERR" in
      *"$want"*) ;;
      *) why="stderr 에 기대 문구가 없다: $want (실제 [$(printf '%s' "$HERR" | head -c 300)])" ;;
    esac
    if [ -z "$why" ] && [ "$forbid" != '-' ]; then
      case "$HERR" in
        *"$forbid"*) why="stderr 에 있으면 안 되는 문구가 있다: $forbid" ;;
      esac
    fi
  fi
  report "$name" "$why"
}

# --- 파서 케이스 ---------------------------------------------------------
# 기대 rc: 0 = 선언 1개를 지원 문법으로 판독함 / 1 = 값을 믿을 수 없음

p01() { pcase '정상 — 겹따옴표'                       0 'printf ok' "$KEY=\"printf ok\""$'\n'; }
p02() { pcase '정상 — 홑따옴표'                       0 'printf ok' "$KEY='printf ok'"$'\n'; }
p03() { pcase '정상 — 인용 없는 한 단어'              0 'mypy'      "$KEY=mypy"$'\n'; }
p04() { pcase '인용 없는 여러 단어'                   0 'pnpm tsc --noEmit' "$KEY=pnpm tsc --noEmit"$'\n'; }
p05() { pcase 'export + 공백'                         0 'printf ok' "export $KEY=\"printf ok\""$'\n'; }
p06() { pcase 'export + 탭'                           0 'printf ok' "export"$'\t'"$KEY=\"printf ok\""$'\n'; }
p07() { pcase '선언 0개 — 키가 없다'                  1 ''          '# 아무 키도 없다'$'\n'; }
p08() { pcase '선언 2개 — 어느 게 이기는지 모른다'    1 ''          "$KEY=\"a\""$'\n'"$KEY=\"b\""$'\n'; }
p09() { pcase '들여쓴 위장(공백)은 선언이 아니다'     0 'printf ok' "  $KEY=\"evil\""$'\n'"$KEY=\"printf ok\""$'\n'; }
p10() { pcase '들여쓴 위장(탭)만 있으면 미설정'       1 ''          $'\t'"$KEY=\"evil\""$'\n'; }
p11() { pcase '접두사가 같은 다른 키는 안 센다'       0 'printf ok' "${KEY}_EXTRA=\"x\""$'\n'"$KEY=\"printf ok\""$'\n'; }
p12() { pcase '접두사 키만 있으면 미설정'             1 ''          "${KEY}_EXTRA=\"x\""$'\n'; }
p13() { pcase '주석 처리된 선언은 안 센다'            1 ''          "# $KEY=\"x\""$'\n'; }
p14() { pcase '후행 주석 — 겹따옴표'                  0 'printf ok' "$KEY=\"printf ok\" # note"$'\n'; }
p15() { pcase '후행 주석 — 홑따옴표'                  0 'printf ok' "$KEY='printf ok' # note"$'\n'; }
p16() { pcase '후행 주석 — 인용 없음'                 0 'mypy'      "$KEY=mypy # note"$'\n'; }
p17() { pcase '값 안의 # 은 주석이 아니다'            0 'a#b'       "$KEY=a#b"$'\n'; }
p18() { pcase '값 자리가 통째로 주석'                 0 ''          "$KEY= # note"$'\n'; }
p19() { pcase '후행 공백 (눈에 안 보인다)'            0 'printf ok' "$KEY=\"printf ok\"   "$'\n'; }
p20() { pcase '후행 탭'                               0 'printf ok' "$KEY=\"printf ok\""$'\t\n'; }
p21() { pcase 'CRLF 줄끝'                             0 'printf ok' "$KEY=\"printf ok\""$'\r\n'; }
p22() { pcase 'CRLF + 후행 주석'                      0 'printf ok' "$KEY=\"printf ok\" # note"$'\r\n'; }
p23() { pcase '파일 앞 BOM + 첫 줄이 선언'            0 'printf ok' $'\357\273\277'"$KEY=\"printf ok\""$'\n'; }
p24() { pcase '파일 앞 BOM + 둘째 줄이 선언'          0 'printf ok' $'\357\273\277''# 주석'$'\n'"$KEY=\"printf ok\""$'\n'; }
p25() { pcase '히어독 본문의 키는 선언이 아니다'      0 'printf ok' 'cat <<EOF'$'\n'"$KEY=\"evil\""$'\n''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
p26() { pcase '히어독 본문에만 있으면 미설정'         1 ''          'cat <<EOF'$'\n'"$KEY=\"\""$'\n''EOF'$'\n'; }
p27() { pcase '히어독 <<- 는 탭 들여쓴 종결어'        0 'printf ok' 'cat <<-EOF'$'\n'"$KEY=\"evil\""$'\n\t''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
p28() { pcase "히어독 <<'EOF' 인용 종결어"            0 'printf ok' "cat <<'EOF'"$'\n'"$KEY=\"evil\""$'\n''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
p29() { pcase '히어독이 EOF 까지 안 닫히면 미설정'    1 ''          "$KEY=\"printf ok\""$'\n''cat <<EOF'$'\n''본문'$'\n'; }
p30() { pcase '따옴표 안의 << 는 히어독이 아니다'     0 'echo a << b' "$KEY=\"echo a << b\""$'\n'; }
p31() { pcase '<<< 히어스트링은 히어독이 아니다'      0 'printf ok' 'cat <<<x'$'\n'"$KEY=\"printf ok\""$'\n'; }
p32() { pcase '여러 줄 값은 지원하지 않는다'          1 ''          "$KEY=\"pnpm \\"$'\n''tsc"'$'\n'; }
p33() { pcase '백슬래시 이스케이프는 지원하지 않는다' 1 ''          "$KEY=\"a \\\" b\""$'\n'; }
p34() { pcase '닫히지 않은 따옴표'                    1 ''          "$KEY=\"printf ok"$'\n'; }
p35() { pcase '따옴표 뒤 잡음'                        1 ''          "$KEY=\"printf\" ok"$'\n'; }
p36() { pcase '리터럴 빈 값 "" — 미설정과 다르다'     0 ''          "$KEY=\"\""$'\n'; }
p37() { pcase "리터럴 빈 값 ''"                       0 ''          "$KEY=''"$'\n'; }
p38() { pcase '리터럴 빈 값 — 등호 뒤가 없다'         0 ''          "$KEY="$'\n'; }
p39() { pcase '값에 등호가 들어 있다'                 0 'a=b'       "$KEY=a=b"$'\n'; }
p40() { pcase '따옴표 안의 공백은 보존한다'           0 '  '        "$KEY=\"  \""$'\n'; }
p41() { pcase '$VAR 는 판독 시점에 확장되지 않는다'   0 'printf $HOME' "$KEY='printf \$HOME'"$'\n'; }
p42() { pcase 'harness.env 파일이 없다'               1 ''          '__NOFILE__'; }
p43() { pcase '빈 파일'                               1 ''          ''; }
# 값의 앞·뒤 공백은 **서로 다른 자리**에서 털린다. 각각 따로 붙든다 —
# 한쪽만 재면 다른 쪽을 지워도 초록이다(변이 측정에서 실제로 그랬다).
p45() { pcase '등호 뒤 선행 공백 + 겹따옴표'          0 'printf ok' "$KEY=  \"printf ok\""$'\n'; }
p46() { pcase '인용 없는 값의 후행 공백'              0 'mypy'      "$KEY=mypy   "$'\n'; }
p47() { pcase '인용 없는 값의 후행 탭'                0 'mypy'      "$KEY=mypy"$'\t\n'; }

# 읽기 실패는 "미설정"과 판정은 같되(rc=1) **소리를 낸다**. root 는 -r 가 항상 참이라
# 이 픽스처가 성립하지 않는다 — 조용히 넘기지 않고 실패로 남긴다(skip 은 커버리지가
# 사라진 것을 초록으로 위장한다).
p44() {
  local name='읽기 실패 — rc=1 이면서 경고를 낸다' proj why=''
  DID_RUN=1
  if [ "$(id -u)" = '0' ]; then
    report "$name" 'root 로 실행하면 이 픽스처가 성립하지 않는다 (비-root 로 돌려라)'
    return 0
  fi
  if ! proj="$(new_project "$KEY=\"printf ok\""$'\n')"; then
    report "$name" "픽스처 구성 실패: $FIXTURE_FAIL"; return 0
  fi
  if ! chmod 000 "$proj/.claude/harness/harness.env" 2>/dev/null; then
    report "$name" '픽스처 구성 실패: chmod 000 실패'; return 0
  fi
  read_value "$proj"
  if [ "$VRC" -ne 1 ]; then
    why="rc=$VRC (기대 1)"
  elif [ -n "$VAL" ]; then
    why="값=[$VAL] (기대 빈 문자열)"
  else
    case "$VERR" in
      *"$TOK_READ_FAIL"*) ;;
      *) why="읽기 실패를 알리지 않았다 (stderr=[$VERR])" ;;
    esac
  fi
  report "$name" "$why"
}

# --- 통합 케이스 — Stop 훅을 실제로 돌린다 -------------------------------
# 감사 플래그 하나만 서 있으므로 정상 경로의 차단 문구는 항상 TOK_AUDIT 이다.
# 타입체크가 실제로 돌아 실패하면 TOK_TC_FAIL 이 대신 나온다 — 그 둘을 가르는 것이
# 판별력의 전부다(rc 는 어느 쪽이든 2라 아무것도 증명하지 못한다).

# 적대적 harness.env: source 했다면 훅이 그 자리에서 죽거나 조용히 끝났을 입력들.
i01() { hcase 'exit 1 이 있어도 게이트가 산다'  2 "$TOK_AUDIT" '-' \
        'exit 1'$'\n'"$KEY=\"true\""$'\n'; }
i02() { hcase 'exit 0 이 있어도 게이트가 산다'  2 "$TOK_AUDIT" '-' \
        'exit 0'$'\n'"$KEY=\"true\""$'\n'; }
i03() { hcase 'return 이 있어도 게이트가 산다'  2 "$TOK_AUDIT" '-' \
        'return 0'$'\n'"$KEY=\"true\""$'\n'; }
i04() { hcase 'printf 재정의가 진단을 위조하지 못한다' 2 "$TOK_AUDIT" '위조됨' \
        "printf() { builtin printf '위조됨'; }"$'\n'"$KEY=\"true\""$'\n'; }

# 회귀의 실제 귀결: 값이 온전해야 명령이 **실행**된다.
# 파서를 되돌리면 값이 ["false" # note] 가 되어 rc=127 → 타입체크 생략 → 감사 게이트가
# 대신 막는다. rc 는 그대로 2 이므로 **문구로만** 갈린다.
i05() { hcase '후행 주석이 붙은 실패 명령이 실제로 실행된다' 2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
        "$KEY=\"false\" # note"$'\n'; }
i06() { hcase '후행 주석이 붙은 성공 명령은 통과시킨다'      2 "$TOK_AUDIT" "$TOK_TC_FAIL" \
        "$KEY=\"true\" # note"$'\n'; }
i07() { hcase '후행 공백이 붙은 실패 명령이 실제로 실행된다' 2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
        "$KEY=\"false\"   "$'\n'; }
i08() { hcase 'CRLF 줄끝의 실패 명령이 실제로 실행된다'      2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
        "$KEY=\"false\""$'\r\n'; }
i09() { hcase 'BOM 이 있어도 실패 명령이 실제로 실행된다'    2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
        $'\357\273\277'"$KEY=\"false\""$'\n'; }
i10() { hcase '히어독 본문의 키는 명령으로 쓰이지 않는다'    2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
        'cat <<EOF'$'\n'"$KEY=\"true\""$'\n''EOF'$'\n'"$KEY=\"false\""$'\n'; }

# 값은 판독 시점이 아니라 **실행 시점**에 확장된다 — _common.sh 주석의 안내와 짝이다.
# 마커를 넣고 돌리면 test 가 실패해야 한다. 확장이 안 일어나면 rc=0 으로 통과해버린다.
i11() { hcase '값은 실행 시점에 환경변수로 확장된다' 2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
        "$KEY='test -z \"\$HARNESS_TEST_MARKER\"'"$'\n' HARNESS_TEST_MARKER=x; }

# 생략의 두 사유를 사용자에게 **구별해** 알린다.
i12() { hcase '리터럴 빈 값은 "빈 값으로 설정됨" 으로 알린다' 2 "$TOK_EMPTY_SET" "$TOK_TC_FAIL" \
        "$KEY=\"\""$'\n'; }
i13() { hcase '선언 2개는 "읽지 못함" 으로 알린다'            2 "$TOK_UNREADABLE" "$TOK_TC_FAIL" \
        "$KEY=\"false\""$'\n'"$KEY=\"false\""$'\n'; }

# --- 지식 게이트 케이스 — ADR-0008 의 "기본 켜짐" 계약 ------------------
# 이 게이트가 **꺼지는 방향으로 틀리는 것**이 최악이다. 사용자는 지식이 쌓인다고 믿는데
# 그 턴부터 아무것도 안 남고, 아무 에러도 안 난다. 그래서 표명이 없거나 모호하면 켠다.

g01() { gcase '키가 아예 없으면 켜짐 (기존 설치본 동작 보존)' on \
        "$KEY=\"true\""$'\n'; }
g02() { gcase '"on" 이면 켜짐'                    on  "$GKEY=\"on\""$'\n'; }
g03() { gcase '리터럴로 비우면 꺼짐 — 유일한 끄는 법' off "$GKEY=\"\""$'\n'; }
g04() { gcase '"off" 라고 적어도 켜짐 (비어 있지 않다)' on "$GKEY=\"off\""$'\n'; }
g05() { gcase '선언이 2개면 켜짐 (어느 게 이기는지 모른다)' on \
        "$GKEY=\"\""$'\n'"$GKEY=\"\""$'\n'; }
g06() { gcase '히어독 본문의 빈 값으로는 못 끈다'  on \
        'cat <<EOF'$'\n'"$GKEY=\"\""$'\n''EOF'$'\n'; }
g07() { gcase '들여쓴 위장으로는 못 끈다'          on  "  $GKEY=\"\""$'\n'; }
g08() { gcase '주석 처리된 선언으로는 못 끈다'      on  "# $GKEY=\"\""$'\n'; }
g09() { gcase 'harness.env 가 없으면 켜짐'         on  '__NOFILE__'; }
g10() { gcase 'CRLF 로 비워도 꺼진다'              off "$GKEY=\"\""$'\r\n'; }

# --- 러너 ----------------------------------------------------------------

CASES='
p01 p02 p03 p04 p05 p06 p07 p08 p09 p10
p11 p12 p13 p14 p15 p16 p17 p18 p19 p20
p21 p22 p23 p24 p25 p26 p27 p28 p29 p30
p31 p32 p33 p34 p35 p36 p37 p38 p39 p40
p41 p42 p43 p44 p45 p46 p47
i01 i02 i03 i04 i05 i06 i07 i08 i09 i10
i11 i12 i13
g01 g02 g03 g04 g05 g06 g07 g08 g09 g10
'
EXPECTED_CASES=70

# 목록 자체의 중복·누락을 먼저 본다. 실행 수만 세면 "하나 중복 + 하나 누락"이 상쇄돼
# 그대로 초록이 된다 — 목록을 직접 봐야 그 조합이 잡힌다.
case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 중복됐거나 빠졌습니다" >&2
  exit 1
fi

echo "harness.env 원문 판독 — 반환 계약 + 게이트 통합"
for c in $CASES; do
  ran=$((ran + 1))
  DID_RUN=0
  FIXTURE_FAIL=''
  "$c"
done

if [ "$ran" -ne "$EXPECTED_CASES" ]; then
  echo "✗ 실행 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 조용히 빠졌습니다" >&2
  exit 1
fi
if [ $((pass + fail)) -ne "$ran" ]; then
  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건 — 중복 판정했거나 판정을 건너뛰었습니다" >&2
  exit 1
fi

echo "— ${pass}/${ran} 통과"
[ "$fail" -eq 0 ] || exit 1
