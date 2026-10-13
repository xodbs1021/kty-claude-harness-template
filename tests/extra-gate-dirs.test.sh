#!/usr/bin/env bash
# extra-gate-dirs.test.sh — 추가 관할 폴더 슬롯(HARNESS_EXTRA_GATE_DIRS, ADR-0026)
# 회귀 테스트.
#
# 이 파일은 진입점이다: 환경 전제, 고정틀, 실행·판정 도우미, 러너, 케이스 목록.
# 케이스 정의는 축별 파일에 있다 — 한 파일이면 800줄을 넘는다(mark-needs-audit 선례).
#   extra-gate-dirs.unit.cases.sh      모듈 함수 · 기록 형식 · 키 판독 상태
#   extra-gate-dirs.envcheck.cases.sh  harness.env 편집 검증 훅(check-harness-env)
#   extra-gate-dirs.notice.cases.sh    완료 게이트 훅의 알림·단일 출구·키 부재 바이트
#   extra-gate-dirs.judge.cases.sh     슬롯 저장소·설계물 판정(⑤′)과 리뷰 자리 기록
#   extra-gate-dirs.sweep.cases.sh     Bash 스윕의 슬롯 저장소·작업 공간 뿌리
#   extra-gate-dirs.bound.cases.sh     그 스윕의 경계(시간 예산·뿌리 상한·개행 경로·
#                                      슬롯 경계·순회 입력 유실)
#   extra-gate-dirs.capture.cases.sh   잡는 쪽 이연 처분(기록 줄 길이·쌍 뿌리 삭제 판정·
#                                      중복 계수·접미 충돌·홈 토큰 알림·표식·동시 출력)
#
# 무엇을 붙드나:
#   · 슬롯 모듈의 계약 — set -u 생존, 기록 쓰기 형식, 기록 읽기의 보수 판정
#     (모르는 꼴은 missing-record 로 막는다)
#   · 키 판독 상태 — 정상 파일의 부재는 ABSENT(기존 바이트), 비정상 자리는 UNTRUSTED
#   · 편집 검증 훅 — 키가 없거나 정상이면 기존 바이트 그대로, 불량이면 사유를 알린다
#
# 단위 시험은 **정본 모듈**을 서브셸에서 source 해서 부른다(사본 없음). 훅 시험은 훅을
# 실제로 돌려 stdout·stderr 를 잰다.
#
# 권한 제거로만 주입할 수 있는 케이스는 root 에서 **실패로 보고**한다 — root 는 권한
# 검사를 건너뛰어 픽스처가 성립하지 않고, skip 은 커버리지 소실을 초록으로 위장한다
# (harness-env-read.test.sh p44 선례). CI 는 비root 다.
#
# 이 파일 자신도 못 믿는다. 러너는 넷을 스스로 검사한다:
#   1) 케이스 목록의 개수·중복  2) 실행 수 vs 기대 수  3) pass+fail == ran
#   4) DID_RUN 센티널(직전 케이스의 결과를 재판정하지 않게)
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
#
# 사용법: ./tests/extra-gate-dirs.test.sh   (전건 통과 시 종료 코드 0)

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOKS="$REPO_ROOT/template/.claude/hooks"
COMMON="$HOOKS/_common.sh"
MODULE="$HOOKS/_extra_gate_dirs.sh"
ENV_HOOK="$HOOKS/check-harness-env.sh"
US=$'\037'   # 기록 형식의 필드 구분자(모듈 머리 주석이 정본)

# 모듈은 여기서 확인하지 않는다 — 없으면 케이스마다 "모듈 적재 실패"로 적색이 된다.
command -v python3 >/dev/null 2>&1 \
  || { echo "✗ python3 이 필요합니다 (훅의 json_get 의존)" >&2; exit 1; }
command -v git >/dev/null 2>&1 \
  || { echo "✗ git 이 필요합니다 (슬롯 저장소 판정 고정틀)" >&2; exit 1; }
for f in "$COMMON" "$ENV_HOOK" "$HOOKS/mark-needs-audit.sh"; do
  [[ -f "$f" ]] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
done

# mktemp 실패를 확인하지 않으면 TMPROOT 가 빈 문자열이 되고 이후 경로가 전부
# 파일시스템 루트를 가리킨다. 물리 경로로 맞춘다(macOS /var → /private/var).
TMPROOT="$(mktemp -d)" || exit 1
if [[ -z "$TMPROOT" || ! -d "$TMPROOT" ]]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
  exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
# chmod 는 권한 케이스(z4b)가 폴더를 000 으로 만들기 때문에 필요하다.
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

# --- 판정 도우미 ----------------------------------------------------------

ran=0
pass=0
fail=0
OUT=''
ERR=''
RC=999
DID_RUN=0        # 이번 케이스에서 무언가를 실제로 돌렸는가 — 센티널
FIXTURE_FAIL=''  # 이번 케이스의 픽스처 조립 실패 사유(빈 값이면 정상)

#######################################
# 케이스 하나의 판정을 남긴다. 픽스처 실패·미실행은 사유보다 먼저 적색이다.
# Globals:
#   pass, fail (씀) · FIXTURE_FAIL, DID_RUN (읽음)
# Arguments:
#   $1 — 케이스 이름, $2 — 실패 사유(빈 값이면 통과)
# Outputs:
#   판정 한 줄(stdout)
#######################################
report() {
  local name="$1" why="$2"
  if [[ -n "$FIXTURE_FAIL" ]]; then
    why="픽스처 구성 실패: $FIXTURE_FAIL"
  elif [[ "$DID_RUN" -ne 1 ]]; then
    why='아무것도 실행하지 않았다 (직전 케이스 결과를 재판정할 뻔했다)'
  fi
  if [[ -z "$why" ]]; then
    pass=$((pass + 1))
    printf '  ✓ %s\n' "$name"
  else
    fail=$((fail + 1))
    printf '  ✗ %s — %s\n' "$name" "$why"
  fi
}

contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

# new_dir <접두사> — TMPROOT 아래 새 디렉토리의 물리 경로.
new_dir() {
  local d
  d="$(mktemp -d "$TMPROOT/$1.XXXXXX")" || return 1
  (CDPATH='' cd -- "$d" && pwd -P)
}

#######################################
# 정본 모듈을 source 한 `set -u` 빈 환경 셸에서 스니펫을 돌린다. 환경은 env -i 로
# 비우고 PATH·US 와 인자로 준 할당만 넘긴다(HOME 도 없다).
# Globals:
#   MODULE, US, BASH (읽음) · OUT, ERR, RC, DID_RUN (씀)
# Arguments:
#   $1 — 스니펫, $2... — 환경 할당(NAME=값)
# Returns:
#   0. 모듈 적재가 실패하면 RC=90
#######################################
run_module() {
  local snippet="$1" errf="$TMPROOT/err.$$"
  shift
  OUT=''; ERR=''; RC=999; DID_RUN=1
  OUT="$(env -i PATH="$PATH" US="$US" ${@+"$@"} "$BASH" -c \
    'set -u; . "$0" || exit 90
'"$snippet" "$MODULE" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

#######################################
# _common.sh 를 source 한 `set -u` 셸에서 스니펫을 돌린다(훅과 같은 진입 조건).
# Globals:
#   COMMON, BASH (읽음) · OUT, ERR, RC, DID_RUN (씀)
# Arguments:
#   $1 — CLAUDE_PROJECT_DIR, $2 — 스니펫
#######################################
run_common() {
  local proj="$1" snippet="$2" errf="$TMPROOT/err.$$"
  OUT=''; ERR=''; RC=999; DID_RUN=1
  OUT="$(env -i PATH="$PATH" CLAUDE_PROJECT_DIR="$proj" "$BASH" -c \
    'set -u; . "$0" || exit 90
'"$snippet" "$COMMON" 2>"$errf")"
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

#######################################
# _common.sh 를 source 한 셸을 시간 상한 안에서 돌린다 — 끝나지 않는 결함(무한
# 루프)도 적색으로 남기기 위해서다. 상한을 넘기면 강제로 끝내고 RC=124.
# Globals:
#   COMMON, BASH, TMPROOT (읽음) · OUT, ERR, RC, DID_RUN (씀)
# Arguments:
#   $1 — 상한(초), $2 — 스니펫, $3... — 환경 할당(NAME=값)
#######################################
run_common_bounded() {
  local secs="$1" snippet="$2" outf="$TMPROOT/bout.$$" errf="$TMPROOT/berr.$$"
  local pid ticks=0
  shift 2
  OUT=''; ERR=''; RC=999; DID_RUN=1
  env -i PATH="$PATH" ${@+"$@"} "$BASH" -c 'set -u; . "$0" || exit 90
'"$snippet" "$COMMON" >"$outf" 2>"$errf" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if ((ticks >= secs * 10)); then
      kill -9 "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null
      RC=124
      break
    fi
    sleep 0.1
    ticks=$((ticks + 1))
  done
  if [[ "$RC" -ne 124 ]]; then
    wait "$pid"
    RC=$?
  fi
  OUT="$(cat "$outf" 2>/dev/null)"
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$outf" "$errf"
}

# is_root — 권한 제거 픽스처가 성립하지 않는 실행자인가.
is_root() { [[ "$(id -u)" == '0' ]]; }

# json_message_ok <파일> — 내용이 systemMessage 문자열을 가진 JSON 한 줄인가.
json_message_ok() {
  python3 -c 'import json, sys
lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
d = json.loads(lines[0]) if len(lines) == 1 else None
sys.exit(0 if isinstance(d, dict) and isinstance(d.get("systemMessage"), str)
         else 1)' "$1" 2>/dev/null
}

# --- 케이스 ---------------------------------------------------------------
# 케이스 파일은 도우미가 전부 정의된 **뒤에** 읽는다. 없으면 이유를 밝히고 멈춘다
# (커밋에서 빠뜨리기 쉬운 파일이다).
for cases_file in extra-gate-dirs.unit.cases.sh \
                  extra-gate-dirs.envcheck.cases.sh \
                  extra-gate-dirs.notice.cases.sh \
                  extra-gate-dirs.judge.cases.sh \
                  extra-gate-dirs.sweep.cases.sh \
                  extra-gate-dirs.bound.cases.sh \
                  extra-gate-dirs.capture.cases.sh; do
  [[ -f "$TEST_DIR/$cases_file" ]] || {
    echo "✗ 케이스 파일을 찾지 못했습니다: $cases_file" >&2
    exit 1
  }
  # shellcheck source=/dev/null
  . "$TEST_DIR/$cases_file"
done

# --- 러너 -----------------------------------------------------------------
# EXPECTED_CASES 는 상수다. 파생값이면 케이스를 지워도 초록이다.
EXPECTED_CASES=122
CASES='
u01 u02 x01 z2a z2b z2c z4a z4b z4c
h01 h02 h03 h04 h05
u03 u04 u05 z4d z4e z4f h06
a01 a02 a03 a04 a05 a06 a07 g01 g02 g03
n01 n02 n03 n04 n05 n06 n07 e03 e04 e16
e01 e02 e05 e06 e07 e08 e09 e10 e11 e12 e13 e14 e15 e17 e18 e19 r08
e20 e21 e22 e23 e24 e25
s01 s02 s03 s04 s05 s06 s07 s08 s09 s10 s11 s12
f01 f02 f03 f04 f05 s_pair1 s_pair2 s_nonpair s_rec h_unset
b01 b02 b03 b04 b05 l01 l02 l03 w01 w02 d01 d02 d03
k01 k02 k03 k04 k05 k06 k07 k08 k09 k10 k11 k12 k13 k14 k15 k16 k17 k18 k19 k20 k21 k22 k23
'

# 목록 자체의 중복·누락을 먼저 본다. 실행 수만 세면 "하나 중복 + 하나 누락"이
# 상쇄돼 그대로 초록이 된다.
case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [[ "$case_total" -ne "$EXPECTED_CASES" \
      || "$case_uniq" -ne "$EXPECTED_CASES" ]]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대" \
    "${EXPECTED_CASES}건 — 케이스가 중복됐거나 빠졌습니다" >&2
  exit 1
fi

echo "extra-gate-dirs — 추가 관할 폴더 슬롯"
for c in $CASES; do
  ran=$((ran + 1))
  DID_RUN=0
  FIXTURE_FAIL=''
  "$c"
done

if [[ "$ran" -ne "$EXPECTED_CASES" ]]; then
  echo "✗ 실행 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 조용히 빠졌습니다" >&2
  exit 1
fi
if [[ $((pass + fail)) -ne "$ran" ]]; then
  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건 — 중복 판정했거나 건너뛰었습니다" >&2
  exit 1
fi

echo "— ${pass}/${ran} 통과"
[[ "$fail" -eq 0 ]] || exit 1
