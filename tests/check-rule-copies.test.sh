#!/usr/bin/env bash
# check-rule-copies.test.sh — scripts/check-rule-copies.sh 회귀 테스트.
# 건수는 여기 적지 않는다 — 케이스를 추가할 때마다 낡는다. 실제로 여기 적혀 있던 숫자가
# 여러 번 뒤처졌다(숫자를 나열하면 그 나열이 또 낡으므로 적지 않는다).
# 기계 정본은 아래 EXPECTED_CASES 이고 러너가 그 값을 강제한다.
#
# 왜 있나: 이 검사기의 유일한 치명 결함은 **위음성**(어긋난 사본을 통과시킴)이다.
# 위음성은 조용해서 사람 눈으로는 영영 안 보인다 — 그래서 기계가 붙들어야 한다.
#
# 어떻게 격리하나: 케이스마다 mktemp -d 로 **가짜 저장소**를 만들고 실제 스크립트를
# 그 안에 복사해 돌린다. 검사기의 ROOT 가 BASH_SOURCE 기반이라, 스크립트에 테스트
# 전용 환경변수 구멍을 뚫지 않고도 픽스처 저장소를 통째로 갈아끼울 수 있다.
# COPIES 경로가 하드코딩이므로 픽스처도 **같은 상대 경로**를 쓴다.
#
# 왜 set -e 가 없나: 비영 종료를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
#
# 이 파일 자신도 못 믿는다. 러너는 세 가지를 스스로 검사한다:
#   1) CASES 목록의 개수·중복        (케이스가 조용히 빠지거나 두 번 도는 것)
#   2) 실행 수 vs 판정 수             (판정을 건너뛰거나 두 번 하는 것)
#   3) 케이스마다 run_check 실제 호출 (직전 케이스의 결과를 재판정하는 것)
#
# 환경 전제: 케이스 23·25·26 은 "읽을 수 없는 파일"을 픽스처로 쓴다. root 로 실행하면
# chmod 000 이어도 읽히므로 픽스처가 성립하지 않는다 — 그때는 조용히 통과시키지 않고
# 픽스처 구성 실패로 **빨갛게** 만든다(fail-closed).
#
# 사용법: ./tests/check-rule-copies.test.sh   (전건 통과 시 종료 코드 0)

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd)"
SUT="$REPO_ROOT/scripts/check-rule-copies.sh"

# mktemp 실패를 확인하지 않으면 TMPROOT 가 빈 문자열이 되고, 이후 경로 조립이
# 전부 "/..." 즉 **파일시스템 루트**를 가리킨다(root 로 도는 CI에서 실제로 쓴다).
TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
  exit 1
fi
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

# --- 마커 문자열 ----------------------------------------------------------
# 토큰에서 전체 줄을 조립한다 — 검사기와 같은 구조라, 마커 문법이 바뀌면 양쪽이
# 한 곳씩만 바뀐다.
TOK_START='rule:core:start'
TOK_END='rule:core:end'
M_START="<!-- $TOK_START -->"
M_END="<!-- $TOK_END -->"

# --- 픽스처 조립 ----------------------------------------------------------

canon_body() {
  printf '1. 적정 단위로 나눈다.\n'
  printf '2. 이름=계약.\n'
  printf '3. 계약에 의존.\n'
}

normal_block() {
  printf '%s\n' "$M_START"
  canon_body
  printf '%s\n' "$M_END"
}

# write_canon/write_copy/write_extra — 블록을 stdin 으로 받아 파일을 만든다.
# 마커 **밖**의 문맥별 설명은 파일마다 다르다 (동기화 대상이 아니라는 계약).

write_canon() {
  {
    printf '# 제0원칙\n\n머리말은 동기화 대상이 아니다.\n\n'
    cat
    printf '\n꼬리말도 동기화 대상이 아니다.\n'
  } > "$1/template/.claude/harness/principles.md"
}

write_copy() {
  {
    printf '# plan-reviewer\n\n이 파일만의 문맥 설명.\n\n'
    cat
    printf '\n마커 뒤로 본문이 계속된다.\n'
  } > "$1/template/.claude/agents/plan-reviewer.md"
}

# write_copy_raw — stdin 을 사본 파일에 **그대로** 쓴다(머리말·꼬리말 없음).
# 블록이 EOF 로 끝나는 픽스처를 만들 때 쓴다. write_copy 의 꼬리말이 붙으면 열린
# 블록이 그 꼬리말까지 빨아들여, 증명하려던 것과 다른 이유로 실패한다.
write_copy_raw() {
  cat > "$1/template/.claude/agents/plan-reviewer.md"
}

# write_extra <저장소> <파일명> [<template/ 하위 디렉토리>]
# 세 번째 인자를 받는 이유: 픽스처가 전부 `.claude/agents/` 안에만 있으면 SCAN_ROOT 를
# 그 디렉토리로 좁히는 회귀가 **세 게이트를 동시에 무력화하는데도** 전건 초록이 된다
# (실측). 범위 계약을 고정하려면 agents/ 밖에 놓인 픽스처가 최소 하나 필요하다.
write_extra() {
  local dir="${3-.claude/agents}"
  {
    printf '# %s\n\n' "$2"
    cat
    printf '\n뒤 본문.\n'
  } > "$1/template/$dir/$2"
}

new_repo() {
  local repo
  repo="$(mktemp -d "$TMPROOT/case.XXXXXX")" || exit 1
  if [ -z "$repo" ] || [ ! -d "$repo" ]; then
    echo "✗ 케이스용 임시 저장소를 만들지 못했습니다" >&2
    exit 1
  fi
  mkdir -p "$repo/scripts" "$repo/template/.claude/harness" "$repo/template/.claude/agents"
  cp "$SUT" "$repo/scripts/check-rule-copies.sh"
  chmod +x "$repo/scripts/check-rule-copies.sh"
  normal_block | write_canon "$repo"
  normal_block | write_copy "$repo"
  printf '%s\n' "$repo"
}

copy_path()  { printf '%s\n' "$1/template/.claude/agents/plan-reviewer.md"; }
canon_path() { printf '%s\n' "$1/template/.claude/harness/principles.md"; }

# make_unreadable — 0=성공, 1=이 환경에선 못 만든다(root 는 권한을 무시한다).
make_unreadable() {
  chmod 000 "$1" 2>/dev/null
  [ -r "$1" ] && return 1
  return 0
}

# --- 픽스처: 검사기 사본의 COPIES 배열 조작 --------------------------------
# COPIES 경로가 하드코딩이라, 배열 **자체**에 관한 계약(등록 경로가 스캔 범위 안이어야
# 한다 / 비면 안 된다)은 픽스처 저장소 안 스크립트 사본을 고쳐야만 만들 수 있다.
# 다른 케이스는 전부 스크립트를 그대로 복사해 쓴다 — 여기만 예외다.
SUT_COPY_ENTRY='  "$ROOT/template/.claude/agents/plan-reviewer.md"'

# replace_sut_copies_entry <저장소> <새 항목 줄 (빈 문자열이면 항목 삭제)>
# 0=성공, 1=앵커 줄을 정확히 하나 찾지 못함(스크립트가 바뀌었다 → 픽스처 구성 실패).
replace_sut_copies_entry() {
  local sut="$1/scripts/check-rule-copies.sh" new="$2" n
  n="$(grep -cF -- "$SUT_COPY_ENTRY" "$sut")"
  [ "$n" -eq 1 ] || return 1
  awk -v old="$SUT_COPY_ENTRY" -v new="$new" '
    $0 == old { if (new != "") print new; next }
    { print }
  ' "$sut" > "$sut.new" || return 1
  mv "$sut.new" "$sut" && chmod +x "$sut"
}

# --- 픽스처: physical_path 강제 실패 ---------------------------------------
# physical_path 가 실패하는 길은 두 갈래다 — cd 실패와 pwd -P(getcwd) 실패. 앞의 것은
# 그 경로의 파일도 열 수 없으므로 "존재하는데 정규화만 실패"가 성립하지 않는다. 뒤의 것은
# 성립하지만, macOS·Linux 의 getcwd 는 상위 디렉토리 읽기 권한을 보지 않는 시스템 콜이라
# **이 환경에서는 권한으로 재현할 수 없다**(POSIX 는 EACCES 를 허용하므로 계약은 필요하다).
# 그래서 함수를 강제로 실패시켜 **분기 계약**만 고정한다: 존재하면 거부 / 없으면 넘김.
PPFAIL_TOKEN='ppfail'
PPFAIL_ANCHOR='  local dir base'

# force_physical_path_failure <저장소> — 경로에 PPFAIL_TOKEN 이 들어 있으면
# physical_path 가 1을 반환하도록 픽스처 저장소의 검사기 사본을 고친다.
# 0=성공, 1=앵커 줄을 정확히 하나 찾지 못함(검사기가 바뀌었다 → 픽스처 구성 실패).
force_physical_path_failure() {
  local sut="$1/scripts/check-rule-copies.sh" n
  n="$(grep -cF -- "$PPFAIL_ANCHOR" "$sut")"
  [ "$n" -eq 1 ] || return 1
  awk -v anchor="$PPFAIL_ANCHOR" -v tok="$PPFAIL_TOKEN" '
    { print }
    $0 == anchor { print "  case \"$1\" in *" tok "*) return 1 ;; esac" }
  ' "$sut" > "$sut.new" || return 1
  mv "$sut.new" "$sut" && chmod +x "$sut"
}

# --- 실행·판정 헬퍼 -------------------------------------------------------

OUT=''
RC=0
DID_RUN=0   # 이번 케이스에서 검사기를 실제로 돌렸는가 (F-5 센티널)

run_check() {
  OUT=''
  RC=999
  DID_RUN=1
  OUT="$( (cd -- "$1" && bash "$1/scripts/check-rule-copies.sh") 2>&1 )"
  RC=$?
}

# 상대 경로 + CDPATH — 결함 5 재현 조건. 절대 경로로 부르면 cd 피연산자가 / 로
# 시작해 CDPATH 를 타지 않아 버그가 재현되지 않는다.
run_check_via_relative_path() {
  OUT=''
  RC=999
  DID_RUN=1
  OUT="$( (cd -- "$1" && CDPATH=. bash scripts/check-rule-copies.sh) 2>&1 )"
  RC=$?
}

# 픽스처를 이 환경에서 만들 수 없을 때. 조용히 넘어가지 않고 실패로 남긴다.
fixture_broken() {
  OUT="픽스처 구성 실패: $1"
  RC=-1
  DID_RUN=1
}

ran=0
pass=0
fail=0

# check_case <이름> <기대rc> [필수문구] [금지문구]
# 필수문구·금지문구 둘 다 개행으로 구분해 여러 개를 줄 수 있다.
# ran 은 여기서 세지 않는다 — 디스패처가 센다. 그래야 "한 케이스가 두 번 판정하고
# 다른 하나가 판정을 건너뜀"을 pass+fail ≠ ran 으로 잡을 수 있다.
check_case() {
  local name="$1" want_rc="$2" must="${3-}" mustnot="${4-}" why='' m

  if [ "$DID_RUN" -ne 1 ]; then
    why='검사기를 실행하지 않았다 (run_check 누락 — 직전 케이스 결과를 재판정할 뻔했다)'
  elif [ "$RC" -ne "$want_rc" ]; then
    why="종료 코드 $RC (기대 $want_rc)"
  else
    while IFS= read -r m; do
      [ -n "$m" ] || continue
      if ! printf '%s' "$OUT" | grep -qF -- "$m"; then why="필수 문구 없음: $m"; break; fi
    done <<EOF
$must
EOF
    while [ -z "$why" ] && IFS= read -r m; do
      [ -n "$m" ] || continue
      if printf '%s' "$OUT" | grep -qF -- "$m"; then why="금지 문구 나옴: $m"; fi
    done <<EOF
$mustnot
EOF
  fi

  if [ -z "$why" ]; then
    pass=$((pass + 1))
    printf '  ✓ %s\n' "$name"
  else
    fail=$((fail + 1))
    printf '  ✗ %s — %s\n' "$name" "$why"
    printf '%s\n' "$OUT" | sed 's/^/      | /'
  fi
}

# 문구 조각 — 검사기 문구가 다듬어져도 계약이 살아 있으면 계속 맞는 최소 조각.
MSG_COPY_MARK='사본의 rule:core 마커'
MSG_CANON_MARK='정본의 rule:core 마커'
MSG_DRIFT='정본과 어긋남'
MSG_CANON_EMPTY='블록이 비어 있음'
MSG_COPY_MISSING='사본 파일이 없음'
MSG_CANON_MISSING='정본 파일이 없음'
MSG_COPY_UNREADABLE='사본 파일을 읽을 수 없음'
MSG_CANON_UNREADABLE='정본 파일을 읽을 수 없음'
MSG_UNREGISTERED='COPIES 배열에 등록'
MSG_SYMLINK='심링크는 허용하지 않습니다'
MSG_BINARY='NUL 바이트를 포함한 파일은 허용하지 않습니다'
MSG_SYNC_TRAILER='그대로 복사하십시오'
MSG_SCAN_GREP_FAIL='미등록 스캔 실패'
MSG_SCAN_FIND_FAIL='심링크 스캔 실패'
MSG_REG_SCOPE='등록 경로가 스캔 범위 밖'
MSG_COPIES_EMPTY='COPIES 배열이 비어 있음'
MSG_REG_NEWLINE='등록 경로에 개행'
MSG_REG_UNRESOLVED='등록 경로의 물리 경로를 구할 수 없음'

# --- 케이스 --------------------------------------------------------------
# 번호는 고정이다. 새 케이스는 뒤에 붙인다 (리뷰 대조가 깨지므로 재배열 금지).

case_01() { # 전이 5·6·9·12
            # 행 1(BEFORE + start → 마커 소비)은 여기 없다. 소비를 그만두고 출력해도
            # 정본·사본 양쪽에 같은 마커 줄이 똑같이 들어가 cmp 가 여전히 일치한다 —
            # 실측상 행 1을 혼자 잡는 것은 케이스 14뿐이다.
  local repo; repo="$(new_repo)"
  run_check "$repo"
  check_case '01 정본·사본 정상 — 통과해야 한다' 0
}

case_02() { # 전이 2 — 수정 전 코드가 통과시키던 진짜 위음성.
            # 마커가 역순으로 1개씩이라 개수 세기(starts==1 && ends==1)를 만족하고,
            # 추출 본문도 정본과 같아 cmp 까지 통과했다. 블록 밖 오염 문장과 역순
            # 마커가 통째로 무시된다. 닫는 end 없이 EOF 로 끝나야 재현된다.
            # 다만 이 픽스처는 전이 2를 **격리하지 못한다**(전이 11이 백스톱) —
            # 격리는 케이스 22가 맡는다. 둘은 대체재가 아니라 역할 분담이다.
  local repo; repo="$(new_repo)"
  {
    printf '# plan-reviewer\n\n이 파일만의 문맥 설명.\n\n'
    printf '%s\n' "$M_END"
    printf '오염 문장 — 블록 밖에 끼어 있다.\n'
    printf '%s\n' "$M_START"
    canon_body
  } | write_copy_raw "$repo"
  run_check "$repo"
  check_case '02 사본: 끝 마커가 먼저 오고 블록이 안 닫힘' 1 "$MSG_COPY_MARK"
}

case_03() { # 전이 8 — AFTER 의 stray end
  local repo; repo="$(new_repo)"
  { normal_block; printf '%s\n' "$M_END"; } | write_copy "$repo"
  run_check "$repo"
  check_case '03 사본: 정상 블록 뒤에 끝 마커 한 줄 더' 1 "$MSG_COPY_MARK"
}

case_04() { # 전이 4 — 블록 안 중첩 start
  local repo; repo="$(new_repo)"
  {
    printf '%s\n' "$M_START"
    printf '앞부분.\n'
    printf '%s\n' "$M_START"
    canon_body
    printf '%s\n' "$M_END"
  } | write_copy "$repo"
  run_check "$repo"
  check_case '04 사본: 블록 안에 시작 마커가 한 번 더' 1 "$MSG_COPY_MARK"
}

case_05() { # 전이 7 — 정상 2쌍. 현행이 이미 막던 방어이므로 수정 전에도 GREEN.
  local repo; repo="$(new_repo)"
  {
    normal_block
    printf '두 블록 사이에 낀 오염 문장.\n'
    normal_block
  } | write_copy "$repo"
  run_check "$repo"
  check_case '05 사본: 정상 블록 2쌍 (사이에 오염 문장)' 1 "$MSG_COPY_MARK"
}

case_06() { # 전이 7 — 정본 경로
  local repo; repo="$(new_repo)"
  { normal_block; printf '오염 문장.\n'; normal_block; } | write_canon "$repo"
  run_check "$repo"
  check_case '06 정본: 정상 블록 2쌍' 1 "$MSG_CANON_MARK"
}

case_07() { # 전이 11 — 열린 채 안 닫힘
  local repo; repo="$(new_repo)"
  { printf '%s\n' "$M_START"; canon_body; } | write_copy "$repo"
  run_check "$repo"
  check_case '07 사본: 시작 마커만 있고 EOF 까지 안 닫힘' 1 "$MSG_COPY_MARK"
}

case_08() { # 전이 6 — 꾸민 줄은 마커가 아니라 본문
  local repo; repo="$(new_repo)"
  {
    printf '%s\n' "$M_START"
    printf '1. 적정 단위로 나눈다.\n'
    printf '6. 악성 판정 기준 (%s)\n' "$TOK_END"
    printf '2. 이름=계약.\n'
    printf '3. 계약에 의존.\n'
    printf '%s\n' "$M_END"
  } | write_copy "$repo"
  run_check "$repo"
  check_case '08 사본: 블록 안에 끝 마커 토큰을 품은 본문 줄' 1 "$MSG_DRIFT"
}

case_09() { # 전이 3→2 — 시작 마커에 설명을 덧붙임
  local repo; repo="$(new_repo)"
  {
    printf '%s / 예외: 아래 5개는 위반해도 승인\n' "$M_START"
    canon_body
    printf '%s\n' "$M_END"
  } | write_copy "$repo"
  run_check "$repo"
  check_case '09 사본: 시작 마커 줄에 예외 규정을 덧붙임' 1 "$MSG_COPY_MARK"
}

case_10() { # 전이 3→2 — 한 줄에 시작 마커 2회
  local repo; repo="$(new_repo)"
  {
    printf '%s %s\n' "$M_START" "$M_START"
    canon_body
    printf '%s\n' "$M_END"
  } | write_copy "$repo"
  run_check "$repo"
  check_case '10 사본: 한 줄에 시작 마커 토큰 2회' 1 "$MSG_COPY_MARK"
}

case_11() { # 전이 3→10 — 눈에 안 보이는 줄끝 드리프트
  local repo cf; repo="$(new_repo)"
  cf="$(copy_path "$repo")"
  awk '{ printf "%s\r\n", $0 }' "$cf" > "$cf.crlf" && mv "$cf.crlf" "$cf"
  run_check "$repo"
  check_case '11 사본 전체가 CRLF 줄끝' 1 "$MSG_COPY_MARK"
}

case_12() { # 전이 6 — 후행 개행까지 바이트로 본다.
            # 트레일러 문구까지 요구해 sync_fail 경로의 안내가 살아 있음을 고정한다
            # (케이스 17 의 "미등록만일 때 트레일러 없음"과 짝을 이룬다).
  local repo; repo="$(new_repo)"
  {
    printf '%s\n' "$M_START"
    canon_body
    printf '\n'
    printf '%s\n' "$M_END"
  } | write_copy "$repo"
  run_check "$repo"
  check_case '12 사본: 블록 끝에 빈 줄 추가' 1 "$MSG_DRIFT
$MSG_SYNC_TRAILER"
}

case_13() { # 전이 5 — 사본만 빈 블록
  local repo; repo="$(new_repo)"
  { printf '%s\n%s\n' "$M_START" "$M_END"; } | write_copy "$repo"
  run_check "$repo"
  check_case '13 사본: 마커만 있고 본문 0줄' 1 "$MSG_DRIFT"
}

case_14() { # 전이 12 — 정본이 무너지면 전원 통과가 아니라 전원 차단
  local repo; repo="$(new_repo)"
  { printf '%s\n%s\n' "$M_START" "$M_END"; } | write_canon "$repo"
  run_check "$repo"
  check_case '14 정본: 마커만 있고 본문 0줄' 1 "$MSG_CANON_EMPTY"
}

case_15() { # 전이 10 — 마커 쌍 0개
  local repo; repo="$(new_repo)"
  canon_body | write_canon "$repo"
  run_check "$repo"
  check_case '15 정본: rule:core 마커가 아예 없음' 1 "$MSG_CANON_MARK"
}

case_16() { # 결함 7 — awk 원시 오류가 사용자에게 새면 안 된다.
            # "읽을 수 없음(권한)"도 금지한다: 부재 검사 뒤의 `continue` 를 지우면
            # 없는 파일에 대해 부재와 권한 오류가 **동시에** 나와, 결함 7이 없애려던
            # 거짓 원인 보고가 그대로 되살아난다(그 회귀만으로는 rc 가 1 그대로라
            # 종료 코드로는 안 잡힌다).
  local repo; repo="$(new_repo)"
  rm -f "$(copy_path "$repo")"
  run_check "$repo"
  check_case '16 COPIES 에 적힌 사본 파일이 없음' 1 "$MSG_COPY_MISSING" "awk
$MSG_COPY_UNREADABLE"
}

case_17() { # 결함 4 — 내용이 같아도 등록 안 했으면 막는다.
            # 미등록만 걸렸을 때 "정본 블록을 복사하십시오"는 거짓 안내다.
  local repo; repo="$(new_repo)"
  normal_block | write_extra "$repo" 'pr-reviewer.md'
  run_check "$repo"
  check_case '17 미등록 파일이 순수 마커로 판정 기준을 보유' 1 "$MSG_UNREGISTERED" "$MSG_SYNC_TRAILER"
}

case_18() { # C-3 — 전체 줄 발견이었으면 놓친다
  local repo; repo="$(new_repo)"
  {
    printf '<!-- %s (판정자용 사본) -->\n' "$TOK_START"
    canon_body
    printf '<!-- %s (판정자용 사본) -->\n' "$TOK_END"
  } | write_extra "$repo" 'pr-reviewer.md'
  run_check "$repo"
  check_case '18 미등록 파일이 마커를 꾸며 토큰만 남김' 1 "$MSG_UNREGISTERED"
}

case_19() { # "둘 중 하나라도" 계약 고정
  local repo; repo="$(new_repo)"
  { canon_body; printf '%s\n' "$M_END"; } | write_extra "$repo" 'pr-reviewer.md'
  run_check "$repo"
  check_case '19 미등록 파일이 끝 마커만 보유' 1 "$MSG_UNREGISTERED"
}

case_20() { # C-4 — grep 은 심링크를 안 따라가고 install.sh 는 실체를 배포한다
  local repo cf; repo="$(new_repo)"
  cf="$(copy_path "$repo")"
  rm -f "$cf"
  ln -s "$(canon_path "$repo")" "$cf"
  run_check "$repo"
  check_case '20 template/ 아래에 심링크 1개' 1 "$MSG_SYMLINK"
}

case_21() { # 결함 5 — CDPATH 오염
  local repo; repo="$(new_repo)"
  run_check_via_relative_path "$repo"
  check_case '21 상대 경로 + CDPATH=. 로 실행' 0
}

case_22() { # 전이 2 **격리**. 케이스 2와 달리 블록이 정상적으로 닫힌다 —
            # 그래서 전이 2 하나만 무력화해도 이 케이스가 혼자 빨개진다.
            # (케이스 2는 전이 11이 백스톱으로 받아줘서 격리가 안 된다.)
  local repo; repo="$(new_repo)"
  {
    printf '%s\n' "$M_END"
    printf '오염 문장 — 블록 밖에 끼어 있다.\n'
    normal_block
  } | write_copy "$repo"
  run_check "$repo"
  check_case '22 사본: 블록 앞 stray end + 정상 블록 (전이 2 격리)' 1 "$MSG_COPY_MARK"
}

case_23() { # D-a — 미등록 스캔의 grep rc>=2 를 조용히 삼키면 스캔이 무력해진다
  local repo victim; repo="$(new_repo)"
  victim="$repo/template/.claude/agents/pr-reviewer.md"
  printf '평범해 보이는 파일.\n' > "$victim"
  if make_unreadable "$victim"; then
    run_check "$repo"
  else
    fixture_broken 'chmod 000 후에도 읽힌다 (root 로 실행 중?)'
  fi
  check_case '23 미등록 스캔 중 읽기 불가 파일 (grep rc>=2)' 1 "$MSG_SCAN_GREP_FAIL"
}

case_24() { # D-j — 정본 부재. 케이스 16과 대칭.
  local repo; repo="$(new_repo)"
  rm -f "$(canon_path "$repo")"
  run_check "$repo"
  check_case '24 정본 파일이 없음' 1 "$MSG_CANON_MISSING" 'awk'
}

case_25() { # F-8 — 존재하지만 읽을 수 없는 정본. 마커 모양 문제로 오진하면 안 된다.
  local repo; repo="$(new_repo)"
  if make_unreadable "$(canon_path "$repo")"; then
    run_check "$repo"
  else
    fixture_broken 'chmod 000 후에도 읽힌다 (root 로 실행 중?)'
  fi
  check_case '25 정본을 읽을 수 없음 (권한)' 1 "$MSG_CANON_UNREADABLE" 'awk'
}

case_26() { # F-8 — 사본 쪽 같은 경로
  local repo; repo="$(new_repo)"
  if make_unreadable "$(copy_path "$repo")"; then
    run_check "$repo"
  else
    fixture_broken 'chmod 000 후에도 읽힌다 (root 로 실행 중?)'
  fi
  check_case '26 사본을 읽을 수 없음 (권한)' 1 "$MSG_COPY_UNREADABLE" 'awk'
}

case_27() { # D-c — find 가 비영으로 끝나면 안내 없이 죽지 말고 진단을 남긴다
  local repo; repo="$(new_repo)"
  rm -rf "$repo/template"
  run_check "$repo"
  check_case '27 스캔 대상 디렉토리 자체가 없음 (find rc!=0)' 1 "$MSG_SCAN_FIND_FAIL"
}

case_28() { # B-5 — 심링크 게이트가 **가장 먼저** 돌아야 한다.
            # 정본까지 없으므로, 게이트가 뒤로 밀리면 정본 오류로 먼저 죽어
            # 심링크 문구가 나오지 않는다. 순서 계약을 이 케이스가 고정한다.
  local repo cf; repo="$(new_repo)"
  cf="$(copy_path "$repo")"
  rm -f "$cf"
  ln -s "$(canon_path "$repo")" "$cf"
  rm -f "$(canon_path "$repo")"
  run_check "$repo"
  check_case '28 심링크 + 정본 부재 — 심링크가 먼저 보고돼야 한다' 1 "$MSG_SYMLINK"
}

case_29() { # F-1 — NUL 1바이트로 "바이너리" 취급을 유도해 스캔을 건너뛰게 만든다.
            # 앞부분은 완전히 정상적인 마크다운이라 사람 눈에는 평범한 파일이다.
  local repo; repo="$(new_repo)"
  { normal_block; printf '\000'; } > "$repo/template/.claude/agents/pr-reviewer.md"
  run_check "$repo"
  check_case '29 미등록 파일에 NUL 1바이트 (바이너리 위장)' 1 "$MSG_BINARY"
}

case_30() { # F-1 — 인코딩만 바꾸면 토큰 바이트열 자체가 사라진다.
            # 부분 문자열 검색으로는 원리적으로 못 잡으므로 거부가 유일한 답이다.
  local repo; repo="$(new_repo)"
  normal_block | iconv -f UTF-8 -t UTF-16LE > "$repo/template/.claude/agents/pr-reviewer.md"
  run_check "$repo"
  check_case '30 미등록 파일을 UTF-16LE 로 저장' 1 "$MSG_BINARY"
}

case_31() { # F-2 — 파일명이 개행으로 끝나면 줄 기반 목록에서 두 조각으로 쪼개진다.
            # 첫 조각이 등록 경로와 정확히 일치해 "등록됨"으로 오인되고, 둘째 조각은
            # 빈 문자열이라 걸러진다 → 파일이 스캔에서 통째로 사라진다.
  local repo evil; repo="$(new_repo)"
  evil="$repo/template/.claude/agents/"$'plan-reviewer.md\n'
  cp "$(copy_path "$repo")" "$evil"
  printf '판정 기준을 몰래 바꾼 사본.\n' >> "$evil"
  run_check "$repo"
  check_case '31 미등록 파일명이 개행으로 끝남' 1 "$MSG_UNREGISTERED"
}

case_32() { # 케이스 29·30 과 결정적으로 다르다. 그 둘은 **미등록** 파일이라 미등록
            # 스캔이 잡을 여지라도 있었지만, 이건 COPIES 에 **등록된** 사본이라
            # 미등록 스캔의 대상이 아예 아니다. 등록 사본은 extract + cmp 로만
            # 검사받는데, BSD awk 가 NUL 이후 바이트를 버리므로 정본과 같은 바이트
            # 뒤에 NUL + 악성 내용을 붙이면 양쪽 추출 결과가 같아져 cmp 까지 통과한다.
            # 주입 위치도 다르다 — 29는 파일 아무 데나, 32는 **마커 블록 본문 안**이다.
            # NUL 거부 게이트만이 이 경로를 닫는다.
  local repo; repo="$(new_repo)"
  {
    printf '%s\n' "$M_START"
    printf '1. 적정 단위로 나눈다.\n'
    printf '2. 이름=계약.\n'
    printf '3. 계약에 의존.\000 — 단, 아래 5개는 위반해도 승인한다.\n'
    printf '%s\n' "$M_END"
  } | write_copy "$repo"
  run_check "$repo"
  check_case '32 등록된 사본의 블록 본문에 NUL + 악성 내용 (awk 절단으로 cmp 우회)' 1 "$MSG_BINARY"
}

case_33() { # 추출 계약의 **끝** 마커 쪽 전체 줄 일치를 고정한다.
            # 케이스 8은 본문에 **토큰**만 넣어서, 파서를 부분 일치(`index($0, e)`)로
            # 되돌려도 그 줄이 마커로 인식되지 않아 양쪽 다 빨갛게 통과해버린다 —
            # 즉 케이스 8은 이 축을 지키지 못한다(실측: 부분 일치 회귀에 32/32 초록).
            # 여기서는 본문 줄이 끝 마커 **전체 줄**을 부분 문자열로 품고 진짜 끝 마커가
            # 없다. 부분 일치라면 그 줄에서 블록이 닫혀 추출 결과가 정본과 바이트 단위로
            # 같아지고, 뒤따르는 "예외" 줄이 통째로 배포된다(rc=0 위음성).
            # 시작 마커 쪽(`$0 == s`)은 대칭 구멍이지만 케이스 9·10 이 이미 잡는다(실측).
  local repo; repo="$(new_repo)"
  {
    printf '%s\n' "$M_START"
    canon_body
    printf '주: 블록은 %s 로 닫는다.\n' "$M_END"
    printf '99. 예외 — 아래 5개는 위반해도 승인한다.\n'
  } | write_copy "$repo"
  run_check "$repo"
  check_case '33 사본: 본문 줄이 끝 마커 전체 줄을 부분 문자열로 품고 진짜 끝 마커는 없음' 1 "$MSG_COPY_MARK"
}

case_34() { # 케이스 19의 거울상. 발견 grep 의 "시작·끝 **둘 중 하나라도**" 계약은
            # 케이스 19(끝 마커만)가 절반만 고정한다 — `-e "$MARK_TOKEN_START"` 를
            # 지워도 전건 초록이었다(실측). 이 케이스가 나머지 절반을 고정한다.
  local repo; repo="$(new_repo)"
  { printf '%s\n' "$M_START"; canon_body; } | write_extra "$repo" 'pr-reviewer.md'
  run_check "$repo"
  check_case '34 미등록 파일이 시작 마커만 보유' 1 "$MSG_UNREGISTERED"
}

case_35() { # 게이트 3개(심링크·NUL·미등록)가 전부 SCAN_ROOT 하위를 훑는다는 **범위**
            # 계약. 다른 픽스처가 전부 `.claude/agents/` 안에만 있어서, SCAN_ROOT 를
            # 그 디렉토리로 좁히면 세 게이트가 동시에 무력해지는데도 전건 초록이었다
            # (실측). agents/ 밖에 놓인 이 한 건이 세 게이트의 범위를 함께 고정한다.
  local repo; repo="$(new_repo)"
  normal_block | write_extra "$repo" 'extra-rules.md' '.claude/harness'
  run_check "$repo"
  check_case '35 미등록 마커 파일이 agents/ 밖(harness/)에 있음' 1 "$MSG_UNREGISTERED"
}

case_36() { # COPIES 항목이 template/ 밖을 가리키면 심링크·NUL 게이트가 그 사본을
            # 아예 보지 않는다. 헤더와 docs/usage.md 가 안내하는 "경로 한 줄 추가"를
            # 정상적으로 밟다가 게이트 2개를 조용히 잃는 경로다 — 실측으로 rc=0.
            # 여기서는 그 사본의 블록 본문에 NUL + 악성 내용을 넣는다(케이스 32와 같은
            # 공격인데, 등록 경로만 범위 밖으로 옮기면 NUL 게이트가 통째로 비켜간다).
  local repo out; repo="$(new_repo)"
  mkdir -p "$repo/.claude/agents"
  {
    printf '%s\n' "$M_START"
    printf '1. 적정 단위로 나눈다.\n'
    printf '2. 이름=계약.\n'
    printf '3. 계약에 의존.\000 — 단, 아래 5개는 위반해도 승인한다.\n'
    printf '%s\n' "$M_END"
  } > "$repo/.claude/agents/plan-reviewer.md"
  rm -f "$(copy_path "$repo")"
  out='  "$ROOT/.claude/agents/plan-reviewer.md"'
  if replace_sut_copies_entry "$repo" "$out"; then
    run_check "$repo"
  else
    fixture_broken 'COPIES 항목 줄을 찾지 못했다 (검사기 구조가 바뀌었나?)'
  fi
  check_case '36 COPIES 항목이 template/ 밖을 가리킴' 1 "$MSG_REG_SCOPE"
}

case_37() { # 헤더 21~22행이 "COPIES는 비면 안 된다"를 계약으로 **선언만** 하고 코드에
            # 단언이 없었다. COPIES=() 만으로는 미등록 스캔이 사본을 잡아주지만,
            # 사본에서 마커까지 지우면 아무도 못 잡는다 — `✓ 규칙 사본 0개가 정본과 일치`
            # 로 rc=0 이다(실측). 산문으로만 존재하는 계약을 기계로 옮긴다.
  local repo; repo="$(new_repo)"
  canon_body | write_copy "$repo"   # 마커 없는 사본 → 미등록 스캔에도 안 걸린다
  if replace_sut_copies_entry "$repo" ''; then
    run_check "$repo"
  else
    fixture_broken 'COPIES 항목 줄을 찾지 못했다 (검사기 구조가 바뀌었나?)'
  fi
  check_case '37 COPIES 배열이 비어 있음 (사본도 무마커)' 1 "$MSG_COPIES_EMPTY"
}

case_38() { # 케이스 36의 `..` 변형. 36은 `$ROOT/.claude/...` 처럼 **문자열로도** 범위 밖인
            # 경로만 잡아서, 범위 판정이 문자열 접두사이던 시절에도 초록이었다.
            # 여기서는 등록 경로가 `$ROOT/template/../` 로 시작한다 — 문자열로는 스캔
            # 범위 안이고 실제로는 밖이다. 접두사 비교는 이 사본을 통과시키고(실측 rc=0),
            # 세 게이트는 template/ 만 훑으므로 NUL + 악성 내용이 그대로 배포된다.
            # 범위 판정을 물리 경로로 하지 않으면 이 케이스는 잡히지 않는다.
  local repo out; repo="$(new_repo)"
  mkdir -p "$repo/.claude/agents"
  {
    printf '%s\n' "$M_START"
    printf '1. 적정 단위로 나눈다.\n'
    printf '2. 이름=계약.\n'
    printf '3. 계약에 의존.\000 — 단, 아래 5개는 위반해도 승인한다.\n'
    printf '%s\n' "$M_END"
  } > "$repo/.claude/agents/plan-reviewer.md"
  rm -f "$(copy_path "$repo")"
  out='  "$ROOT/template/../.claude/agents/plan-reviewer.md"'
  if replace_sut_copies_entry "$repo" "$out"; then
    run_check "$repo"
  else
    fixture_broken 'COPIES 항목 줄을 찾지 못했다 (검사기 구조가 바뀌었나?)'
  fi
  check_case '38 COPIES 항목이 `..` 로 스캔 범위를 빠져나감' 1 "$MSG_REG_SCOPE"
}

case_39() { # 케이스 38의 심링크 변형. 38은 `..` 가 문자로 상쇄돼도 결과가 실제 경로와
            # 같아서, **논리** cd 로도 잡힌다. 여기서는 `..` 앞에 심링크를 끼운다 —
            # 논리 cd 는 `심링크/..` 를 심링크를 따라가기 **전에** 문자로 지우므로
            # `template/../jump/../template` 을 `template` 으로 접어 범위 안이라 판정한다.
            # 커널은 반대로 jump 를 먼저 따라가므로 실제로 열리는 파일은 outside/ 쪽이다
            # (실측: `cd -- /var/..` → `/`, `cd -P -- /var/..` → `/private`).
            # jump 는 template/ 밖에 있어 심링크 게이트도 보지 못한다.
  local repo out; repo="$(new_repo)"
  mkdir -p "$repo/outside/a" "$repo/outside/template"
  ln -s "$repo/outside/a" "$repo/jump"
  {
    printf '%s\n' "$M_START"
    printf '1. 적정 단위로 나눈다.\n'
    printf '2. 이름=계약.\n'
    printf '3. 계약에 의존.\000 — 단, 아래 5개는 위반해도 승인한다.\n'
    printf '%s\n' "$M_END"
  } > "$repo/outside/template/plan-reviewer.md"
  rm -f "$(copy_path "$repo")"
  out='  "$ROOT/template/../jump/../template/plan-reviewer.md"'
  if replace_sut_copies_entry "$repo" "$out"; then
    run_check "$repo"
  else
    fixture_broken 'COPIES 항목 줄을 찾지 못했다 (검사기 구조가 바뀌었나?)'
  fi
  check_case '39 COPIES 항목이 `심링크/..` 로 스캔 범위를 빠져나감' 1 "$MSG_REG_SCOPE"
}

case_40() { # 등록 경로에 개행이 들어간 경우. 실제 부모는 `template<개행>` 으로 template 의
            # **바깥 형제**인데, dirname 출력의 후행 개행을 명령 치환이 먹어버려
            # `template` 이 되고 범위 안으로 통과한다(실측: dirname 끝의 0a 가 사라진다).
            # 명령 치환은 후행 개행을 **전부** 먹으므로 이 축은 $(...) 로는 원리적으로
            # 못 고친다 — 등록 자체를 거부하는 수밖에 없다.
            # 케이스 31이 "개행 파일명"을 스캔 쪽에서 닫은 것과 같은 계열이다.
  local repo evil_dir out; repo="$(new_repo)"
  evil_dir="$repo/template"$'\n'
  mkdir -p "$evil_dir"
  {
    printf '%s\n' "$M_START"
    printf '1. 적정 단위로 나눈다.\n'
    printf '2. 이름=계약.\n'
    printf '3. 계약에 의존.\000 — 단, 아래 5개는 위반해도 승인한다.\n'
    printf '%s\n' "$M_END"
  } > "$evil_dir/plan-reviewer.md"
  rm -f "$(copy_path "$repo")"
  # 항목 줄은 개행을 품은 채 두 줄로 쓰인다 — 큰따옴표 안의 진짜 개행이라 문법은 유효하다.
  # `\n` 인 채로 넘기는 이유: BSD awk 는 -v 값에 **진짜 개행**이 들어오면 거부한다
  # ("newline in string" — 실측). POSIX 가 요구하는 -v 의 이스케이프 처리에 맡긴다.
  # 변환이 안 된 채 지나가면 픽스처가 증명하려던 것과 달라지므로, 두 줄로 쪼개졌는지
  # 직접 확인하고 아니면 픽스처 구성 실패로 빨갛게 만든다.
  out='  "$ROOT/template\n/plan-reviewer.md"'
  if replace_sut_copies_entry "$repo" "$out" &&
     grep -qxF -- '  "$ROOT/template' "$repo/scripts/check-rule-copies.sh"; then
    run_check "$repo"
  else
    fixture_broken 'COPIES 항목 줄을 개행 포함 두 줄로 바꾸지 못했다 (awk -v 이스케이프?)'
  fi
  check_case '40 COPIES 항목에 개행이 들어 있음' 1 "$MSG_REG_NEWLINE"
}

case_41() { # physical_path 실패를 `|| continue` 로 넘기면 범위 검사만 조용히 사라지고
            # 파일 비교는 정상 진행된다 — 범위 밖 사본이 게이트를 하나도 안 거치고
            # rc=0 이 될 수 있다. 실패했으면 "범위를 확인할 수 없다"는 뜻이므로
            # 파일이 존재하는 한 fail-closed 여야 한다.
            # 픽스처는 함수를 강제 실패시킨다(위 force_physical_path_failure 주석 참고).
  local repo out; repo="$(new_repo)"
  normal_block | write_extra "$repo" "$PPFAIL_TOKEN-plan-reviewer.md"
  rm -f "$(copy_path "$repo")"
  out="  \"\$ROOT/template/.claude/agents/$PPFAIL_TOKEN-plan-reviewer.md\""
  if replace_sut_copies_entry "$repo" "$out" && force_physical_path_failure "$repo"; then
    run_check "$repo"
  else
    fixture_broken 'COPIES 항목 줄이나 physical_path 앵커를 찾지 못했다 (검사기 구조가 바뀌었나?)'
  fi
  check_case '41 등록 경로의 물리 경로를 못 구하는데 파일은 존재함' 1 "$MSG_REG_UNRESOLVED"
}

# --- 러너 ----------------------------------------------------------------

EXPECTED_CASES=41

CASES='case_01 case_02 case_03 case_04 case_05 case_06 case_07
       case_08 case_09 case_10 case_11 case_12 case_13 case_14
       case_15 case_16 case_17 case_18 case_19 case_20 case_21
       case_22 case_23 case_24 case_25 case_26 case_27 case_28
       case_29 case_30 case_31 case_32 case_33 case_34 case_35
       case_36 case_37 case_38 case_39 case_40 case_41'

# 목록 자체의 중복·누락을 먼저 본다. 실행 수만 세면 "하나 중복 + 하나 누락"이
# 상쇄돼 그대로 초록이 된다 — 목록을 직접 봐야 그 조합이 잡힌다.
case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 중복됐거나 빠졌습니다" >&2
  exit 1
fi

echo "check-rule-copies 회귀 테스트"
for c in $CASES; do
  ran=$((ran + 1))
  DID_RUN=0
  "$c"
done

if [ "$ran" -ne "$EXPECTED_CASES" ]; then
  echo "✗ 실행 케이스 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 조용히 빠졌습니다" >&2
  exit 1
fi

if [ $((pass + fail)) -ne "$ran" ]; then
  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건 — 케이스가 중복 판정했거나 판정을 건너뛰었습니다" >&2
  exit 1
fi

echo "— ${pass}/${ran} 통과"
[ "$fail" -eq 0 ] || exit 1
