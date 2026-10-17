#!/usr/bin/env bash
# extra-gate-dirs.release.cases.sh — 듀얼리뷰 해제(Stop 3.5)가 슬롯 리뷰 자리를 보는 케이스.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice·judge·sweep 케이스 파일에 있다:
#   slot_fixture · commit_repo · set_env · edit_new · new_file · run_mna · new_dir
#   report · contains · is_root · C3_F · C3_R · C3_S · C3_T · ENV_NO_KEY · US
#   OUT · ERR · RC · DID_RUN · FIXTURE_FAIL
#
# 고정틀: 슬롯 S 안에 저장소 T(커밋됨)와 형제 작업 공간 S/_workspace_T. 세션 루트 R 은
# git 밖이고 Stop·발행 훅이 설치돼 있다. 시각은 `touch -t` 로 정한다(sleep 없음):
#   직접 쓴 플래그 2020-01-01 · 새 리뷰 2030-01-01(훅이 쓴 플래그 = 지금보다도 새다) ·
#   오래된 리뷰 2019-01-01.
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

STOP_HOOK="$HOOKS/verify-before-stop.sh"
PUB_HOOK="$HOOKS/guard-publish-review.sh"
T_FLAG=202001010000    # 직접 쓰는 듀얼리뷰 플래그의 시각
T_FRESH=203001010000   # 플래그보다 새 리뷰
T_OLD=201901010000     # 플래그보다 오래된 리뷰

# 187398c 의 3.5 차단 첫 줄(골든 — 키가 없을 때의 기존 루프 바이트).
TOK_DR_LOOP='[완료 차단] codex 듀얼 리뷰 미수행 — Claude 단독 리뷰로는 끝낼 수 없습니다.'
# 슬롯 판정 차단 문구 조각(Stop 상수와 대조).
TOK_DR_SLOT='슬롯 리뷰 자리 기록으로 판정했습니다'
TOK_DR_MISSING='현재 리뷰 자리 기록이 없다'
TOK_DR_RESAVE='그 파일을 다시 저장하면 기록된다'
TOK_DR_FIXCONF='슬롯 설정을 고친 뒤'   # 슬롯 값 검증 실패(invalid)의 출구
TOK_DR_FIXENV='harness.env 를 정상으로 읽을 수 있게 고친 뒤'   # 믿을 수 없음(untrusted)의 출구
# 믿을 수 없음의 원인 괄호 — 정본 extra_problem_text untrusted(_common.sh)와 같다.
TOK_DR_CAUSE_ENV='(손상·읽기 불가·중복 선언·문법 밖·파일 종류)'
# 꺼짐 출구가 다시 저장하라는 대상 — harness.env 가 아니라 위에 나열한 값의 파일이다.
TOK_DR_RESAVE_VAL="위 '현재 리뷰 자리 기록이 없는 값' 의 파일을 다시 저장하라"
TOK_DR_UNREC='리뷰 자리를 기록할 수 없는 값이다'
TOK_DR_UNUSABLE='리뷰 자리 기록 파일을 쓰거나 읽을 수 없다'
TOK_DR_MODULE='모듈을 읽지 못해 리뷰 자리를 판정할 수 없다'
TOK_DR_EVALFAIL='리뷰 자리 판정이 실패했다'
TOK_DR_DIRUNK='슬롯 폴더를 알 수 없어'

# stop_fixture [슬롯 값] — slot_fixture 에 Stop·발행 훅을 더한다.
stop_fixture() {
  slot_fixture "$@" || return 1
  cp "$STOP_HOOK" "$PUB_HOOK" "$C3_R/.claude/hooks/" \
    || { FIXTURE_FAIL='Stop·발행 훅 복사'; return 1; }
}

#######################################
# Stop 을 실제로 돌린다. 입력은 빈 JSON(세션 번호·대화 기록 없음)이고, 차단 예산이 앞
# 실행에 소진되지 않게 카운터를 먼저 지운다.
# Globals:
#   TMPROOT, BASH, STOP_PDIR(케이스가 local 로 바꾸는 CLAUDE_PROJECT_DIR) (읽음) ·
#   OUT, ERR, RC, DID_RUN (씀)
# Arguments:
#   $1 — 프로젝트(물리 경로)
#######################################
STOP_PDIR=''
run_stop() {
  local p="$1" outf="$TMPROOT/sout.$$" errf="$TMPROOT/serr.$$"
  OUT=''; ERR=''; RC=999; DID_RUN=1
  rm -f "$p/.claude/.stop-block-count" "$p/.claude/.stop-block-fp"
  printf '{}' | (cd "$p" && env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
    CLAUDE_PROJECT_DIR="${STOP_PDIR:-$p}" "$BASH" "$p/.claude/hooks/verify-before-stop.sh" \
    >"$outf" 2>"$errf")
  RC=$?
  OUT="$(cat "$outf" 2>/dev/null)"
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$outf" "$errf"
}

# dr_flag <프로젝트> <값>... — 듀얼리뷰 플래그를 그 값들로 쓰고 2020년으로 돌린다.
dr_flag() {
  local p="$1"
  shift
  printf '%s\n' "$@" > "$p/.claude/.needs-dualreview" \
    && touch -t "$T_FLAG" "$p/.claude/.needs-dualreview" \
    || { FIXTURE_FAIL='듀얼리뷰 플래그'; return 1; }
}

# rec <프로젝트> <값> <꼬리 필드>... — 기록 줄 하나를 덧붙인다(필드는 US 로 잇는다).
rec() {
  local p="$1" line="$2"
  shift 2
  while (($# > 0)); do line="$line$US$1"; shift; done
  printf '%s\n' "$line" >> "$p/.claude/.review-dirs" \
    || { FIXTURE_FAIL='기록 줄'; return 1; }
}

# review_at <폴더> [시각] — 그 폴더에 비지 않은 *codex*.md 하나(기본: 플래그보다 새 시각).
review_at() {
  mkdir -p "$1" && printf 'r\n' > "$1/03_codex_review.md" \
    && touch -t "${2:-$T_FRESH}" "$1/03_codex_review.md" \
    || { FIXTURE_FAIL="리뷰 $1"; return 1; }
}

# expect_dr_released <프로젝트> — 듀얼리뷰 플래그가 풀렸고 3.5 차단 문구가 없다.
expect_dr_released() {
  if [[ -e "$1/.claude/.needs-dualreview" ]]; then
    printf '듀얼리뷰가 풀리지 않았다 rc=%s [%s]' "$RC" "$(flat "$ERR" | head -c 300)"
  elif contains "$ERR" "$TOK_DR_SLOT" || contains "$ERR" "$TOK_DR_LOOP"; then
    printf '3.5 차단 문구가 있다'
  fi
}

# expect_dr_slot_block <프로젝트> [문구 조각]... — 슬롯 판정으로 막았고 조각이 다 있다.
expect_dr_slot_block() {
  local p="$1" t
  shift
  if [[ "$RC" -ne 2 ]]; then printf 'rc=%s (기대 2) [%s]' "$RC" "$(flat "$ERR" | head -c 200)"
    return
  fi
  [[ -s "$p/.claude/.needs-dualreview" ]] || { printf '플래그가 지워졌다'; return; }
  contains "$ERR" "$TOK_DR_SLOT" \
    || { printf '슬롯 차단 문구 없음 [%s]' "$(flat "$ERR" | head -c 200)"; return; }
  for t in "$@"; do
    contains "$ERR" "$t" || { printf '문구 없음 [%s]' "$t"; return; }
  done
}

# expect_dr_loop_block <프로젝트> — 기존 루프 차단(골든 첫 줄, 슬롯 문구 없음).
expect_dr_loop_block() {
  if [[ "$RC" -ne 2 ]]; then printf 'rc=%s (기대 2)' "$RC"
  elif [[ "${ERR%%$'\n'*}" != "$TOK_DR_LOOP" ]]; then
    printf '첫 줄이 기존 루프가 아니다 [%s]' "${ERR%%$'\n'*}"
  elif contains "$ERR" "$TOK_DR_SLOT"; then printf '슬롯 문구가 섞였다'
  fi
}

# 키 상태를 바꾸는 harness.env 내용.
env_slot() { printf 'HARNESS_EXTRA_GATE_DIRS="%s"\n' "$1"; }
env_untrusted() { printf 'HARNESS_EXTRA_GATE_DIRS="%s"\nHARNESS_EXTRA_GATE_DIRS="%s"\n' "$1" "$1"; }

# --- c: 자리 대응 -----------------------------------------------------------

c01() { # 자리 대응은 정확하다 — T 의 리뷰로 T 안의 독립 저장소 U(T/u) 항목이 풀리지 않는다.
  local name='c01 T 리뷰로 T/u(독립 저장소) 항목 안 풀림 · U 자리 리뷰로 풀림' why='' u
  stop_fixture || { report "$name" ''; return; }
  u="$C3_T/u"
  mkdir -p "$u/src" && printf 'k\n' > "$u/src/k.go" && commit_repo "$u" \
    || { report "$name" ''; return; }
  edit_new "$C3_R" "$C3_T/src/c1.go" && edit_new "$C3_R" "$u/src/c1.go" \
    && review_at "$C3_T/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$u/_workspace")"
  if [[ -z "$why" ]]; then
    review_at "$u/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[U 자리 리뷰] $why"
  fi
  report "$name" "$why"
}

c02() { # 이름이 비슷한 형제(guard · guard2)의 자리는 서로 무관하다.
  local name='c02 guard 항목 · guard2 자리 리뷰 → 안 풀림 · guard 자리로 풀림' why='' g
  stop_fixture || { report "$name" ''; return; }
  for g in guard guard2; do
    mkdir -p "$C3_S/$g/src" "$C3_S/_workspace_$g" \
      && printf 'k\n' > "$C3_S/$g/src/k.go" && commit_repo "$C3_S/$g" \
      || { report "$name" ''; return; }
  done
  edit_new "$C3_R" "$C3_S/guard/src/c2.go" && review_at "$C3_S/_workspace_guard2" \
    && review_at "$C3_S/guard2/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R")"
  if [[ -z "$why" ]]; then
    review_at "$C3_S/_workspace_guard" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[guard 자리 리뷰] $why"
  fi
  report "$name" "$why"
}

c03() { # T/_workspace 설계물과 T 코드는 각자 자리다 — 설계물은 그 폴더에서만 풀린다.
  local name='c03 설계물(T/_workspace) · 코드(T) 각자 자리' why=''
  stop_fixture || { report "$name" ''; return; }
  edit_new "$C3_R" "$C3_T/_workspace/00_design.md" \
    && edit_new "$C3_R" "$C3_T/src/c3.go" \
    && rm -f "$C3_R/.claude/.needs-retrieval" \
    && review_at "$C3_S/_workspace_T" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$C3_T/_workspace")"
  if [[ -z "$why" ]]; then
    review_at "$C3_T/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[T/_workspace 리뷰] $why"
  fi
  report "$name" "$why"
}

# --- t: 해제 기본 -------------------------------------------------------------

t01() { # 자리 하나 · 그 자리 리뷰 → 해제.
  local name='t01 단일 자리 리뷰 → 해제' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/t1.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" '!' && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && review_at "$C3_T/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_released "$C3_R")"
  report "$name" "$why"
}

t02() { # 두 항목 · 두 자리 중 한 자리만 리뷰 → 막음, 남은 자리를 나열.
  local name='t02 두 자리 중 한 자리만 리뷰 → 막음 · 남은 자리 나열' why=''
  local v1 v2
  stop_fixture || { report "$name" ''; return; }
  v1="$C3_T/src/t2a.go" v2="$C3_S/_workspace_x/00_design.md"
  dr_flag "$C3_R" "$v1" "$v2" && rec "$C3_R" "$v1" "$C3_T/_workspace" \
    && rec "$C3_R" "$v2" "$C3_S/_workspace_x" && review_at "$C3_T/_workspace" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$C3_S/_workspace_x")"
  report "$name" "$why"
}

t03() { # 세션 루트 _workspace 의 리뷰는 슬롯 항목을 풀지 않는다.
  local name='t03 세션 루트 리뷰 → 슬롯 항목 안 풀림' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/t3.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && review_at "$C3_R/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$C3_T/_workspace")"
  report "$name" "$why"
}

t04() { # 플래그가 세션 루트 항목뿐이면 기록이 있어도 세션 루트 리뷰로 푼다.
  local name='t04 루트 항목만 + 기록 있음 → 세션 루트 리뷰로 해제' why=''
  stop_fixture || { report "$name" ''; return; }
  dr_flag "$C3_R" 'src/t4.go' && rec "$C3_R" "$C3_T/src/old.go" "$C3_T/_workspace" \
    && review_at "$C3_R/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_released "$C3_R")"
  report "$name" "$why"
}

t07() { # 키가 없으면(ABSENT) 기존 루프 원문 — 차단 바이트의 첫 줄이 187398c 와 같고
        # 슬롯 문구가 없다. 세션 루트 리뷰로 풀린다(I2).
  local name='t07 키 부재 · 기록 없음 → 기존 루프(차단 첫 줄 골든 · 루트 리뷰로 해제)'
  local why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/t7.go"
  set_env "$C3_R" "$ENV_NO_KEY"
  dr_flag "$C3_R" "$v" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_loop_block "$C3_R")"
  [[ -z "$why" ]] && ! contains "$ERR" "  - $v" && why='대상 나열 없음'
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
  fi
  report "$name" "$why"
}

t08() { # 이름이 *codex*.md 가 아니면(`_cx_`) 리뷰가 아니다.
  local name='t08 자리에 03_cx_review.md 뿐 → 안 풀림' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/t8.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && mkdir -p "$C3_T/_workspace" && printf 'r\n' > "$C3_T/_workspace/03_cx_review.md" \
    && touch -t "$T_FRESH" "$C3_T/_workspace/03_cx_review.md" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R")"
  report "$name" "$why"
}

t09() { # 플래그보다 오래된 리뷰는 풀지 않는다.
  local name='t09 자리 리뷰가 플래그보다 오래됨 → 안 풀림' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/t9.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && review_at "$C3_T/_workspace" "$T_OLD" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R")"
  report "$name" "$why"
}

# --- r: 기록 · 평가 ------------------------------------------------------------

r01_absent() { # 키 VALUE · 기록 파일 없음 · 슬롯 항목 → missing-record 로 막는다. 세션
               # 루트의 새 리뷰로 새지 않는다(Y2 — 없는 기록 = 0줄).
  local name='r01-absent VALUE · 기록 없음 · 슬롯 항목 → missing-record 막음' why=''
  local v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/r1.go"
  dr_flag "$C3_R" "$v" && review_at "$C3_R/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING" "$TOK_DR_RESAVE" "$v")"
  report "$name" "$why"
}

r01_empty() { # 기록 파일이 0바이트여도 같다(조인이 플래그 줄을 기록으로 읽지 않는다).
  local name='r01-empty VALUE · 0바이트 기록 · 슬롯 항목 → missing-record 막음' why=''
  local v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/r1e.go"
  dr_flag "$C3_R" "$v" && : > "$C3_R/.claude/.review-dirs" \
    && review_at "$C3_R/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING")"
  report "$name" "$why"
}

r01b() { # 값에 US(0x1F)가 있으면 기록할 수 없는 값이다 — missing-record 와 다른 문구.
  local name='r01b 값에 US → unrecordable 문구(missing-record 아님)' why=''
  local v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/a${US}b.go"
  dr_flag "$C3_R" "$v" && review_at "$C3_R/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_UNREC")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_MISSING" && why='missing-record 문구가 섞였다'
  report "$name" "$why"
}

r02() { # 기록 파일이 있는데 모듈이 없으면 막는다(module) — 평가할 수 없을 때의 증거는
        # 기록 파일의 존재다(Y3).
  local name='r02 기록 있음 + 모듈 없음 → module 막음' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/r2.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && review_at "$C3_T/_workspace" && review_at "$C3_R/_workspace" \
    && rm -f "$C3_R/.claude/hooks/_extra_gate_dirs.sh" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MODULE")"
  report "$name" "$why"
}

r02e() { # 0바이트 기록도 증거다 — 모듈이 없으면 막는다(세션 루트 리뷰로 새지 않는다).
  local name='r02e 0바이트 기록 + 모듈 없음 → module 막음' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/r2e.go"
  dr_flag "$C3_R" "$v" && : > "$C3_R/.claude/.review-dirs" \
    && review_at "$C3_R/_workspace" \
    && rm -f "$C3_R/.claude/hooks/_extra_gate_dirs.sh" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MODULE")"
  report "$name" "$why"
}

r03() { # 기록된 값의 파일이 세션 중 사라져도 기록 자리로만 푼다.
  local name='r03 값 파일 삭제됨 · 루트 리뷰 → 안 풀림 · 기록 자리로 풀림' why=''
  local v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/gone.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_S/_workspace_T" \
    && review_at "$C3_R/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R")"
  if [[ -z "$why" ]]; then
    review_at "$C3_S/_workspace_T" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[기록 자리 리뷰] $why"
  fi
  report "$name" "$why"
}

r04() { # 기록이 있어도 키가 없으면 기존 루프다(기록을 소비하지 않는다 — 공시 10).
  local name='r04 기록 있음 + 키 부재 → 기존 루프(차단 골든 · 루트 리뷰로 해제)'
  local why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/r4.go"
  set_env "$C3_R" "$ENV_NO_KEY"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_loop_block "$C3_R")"
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[루트 리뷰] $why"
  fi
  report "$name" "$why"
}

r05() { # UNTRUSTED 이고 기록 파일이 없으면 기존 루프다(기존 바이트).
  local name='r05 UNTRUSTED · 기록 없음 → 기존 루프(차단 골든 · 루트 리뷰로 해제)'
  local why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/r5.go"
  set_env "$C3_R" "$(env_untrusted "$C3_S")"
  dr_flag "$C3_R" "$v" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_loop_block "$C3_R")"
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[루트 리뷰] $why"
  fi
  report "$name" "$why"
}

r06() { # 평가가 죽어도(set -u 사망 주입) 본 셸은 살아 3.5 에서 막고(eval-fail) 플래그를
        # 지우지 않는다. 주입을 거두고 자리 리뷰를 두면 다음 Stop 이 3.5 를 풀고 뒤
        # 게이트(4)에서 막는다 — 뒤 게이트가 보존된다.
  local name='r06 평가 사망 → eval-fail 막음 · 플래그 보존 · 복구 뒤 (4)에서 막음' why=''
  local m f
  stop_fixture || { report "$name" ''; return; }
  m="$C3_R/.claude/hooks/_extra_gate_dirs.sh"
  edit_new "$C3_R" "$C3_T/src/r6.go" || { report "$name" ''; return; }
  printf '%s\n' 'read_review_verdict() { : "$R06_UNSET_VARIABLE"; }' >> "$m" \
    && review_at "$C3_T/_workspace" || { FIXTURE_FAIL='사망 주입'; report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_EVALFAIL")"
  for f in audit explain knowledge; do
    [[ -z "$why" && ! -s "$C3_R/.claude/.needs-$f" ]] && why=".needs-$f 가 지워졌다"
  done
  if [[ -z "$why" ]]; then
    cp "$MODULE" "$m" || { FIXTURE_FAIL='모듈 복구'; report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -z "$why" ]] && ! contains "$ERR" 'change-explainer 미실행' \
      && why="뒤 게이트(4)가 막지 않았다 rc=$RC"
    [[ -n "$why" ]] && why="[복구 뒤] $why"
  fi
  report "$name" "$why"
}

r07() { # 기록 파일(옛 값만)이 있고 현재 플래그는 세션 루트 항목뿐이어도, 모듈이 없으면
        # 막는다 — 존재 기준(Y3, 공시 11).
  local name='r07 옛 기록 + 루트 항목만 + 모듈 없음 → module 막음' why=''
  stop_fixture || { report "$name" ''; return; }
  dr_flag "$C3_R" 'src/r7.go' && rec "$C3_R" "$C3_T/src/old.go" "$C3_T/_workspace" \
    && review_at "$C3_R/_workspace" \
    && rm -f "$C3_R/.claude/hooks/_extra_gate_dirs.sh" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MODULE")"
  report "$name" "$why"
}

r07b() { # 기록 파일이 없고 모듈도 없으면 기존 루프다(판정자도 기록하지 못했다 — 공시).
  local name='r07b 기록 없음 + 모듈 없음 → 기존 루프(루트 리뷰로 해제)' why=''
  local v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/r7b.go"
  dr_flag "$C3_R" "$v" && review_at "$C3_R/_workspace" \
    && rm -f "$C3_R/.claude/hooks/_extra_gate_dirs.sh" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_released "$C3_R")"
  report "$name" "$why"
}

r09() { # UNTRUSTED + 기록(끝줄 갱신 표시) — 그 값을 M 으로 나열하고 출구를 "harness.env 를
        # 정상으로 읽을 수 있게 고친 뒤"로 바꾼다. 기록 없는 절대 항목은 슬롯을 몰라
        # dir-unknown(세션 루트 규칙).
  local name='r09 UNTRUSTED · 끝줄 갱신 표시 → M 값 나열 · 판독 불가 출구 · dir-unknown'
  local why=''
  local v1 v2
  stop_fixture || { report "$name" ''; return; }
  v1="$C3_T/src/r9a.go" v2="$C3_T/src/r9b.go"
  set_env "$C3_R" "$(env_untrusted "$C3_S")"
  dr_flag "$C3_R" "$v1" "$v2" && rec "$C3_R" "$v1" "$C3_T/_workspace" \
    && rec "$C3_R" "$v1" '!' && review_at "$C3_R/_workspace" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING" "$TOK_DR_FIXENV" \
    "$TOK_DR_CAUSE_ENV" "$TOK_DR_RESAVE_VAL" "$TOK_DR_DIRUNK" "  - $v1")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_RESAVE" && why='슬롯 켜짐 출구 문구가 나왔다'
  report "$name" "$why"
}

r10() { # 슬롯이 꺼진 missing-record 의 출구는 꺼진 까닭마다 사실이다 — 값 검증 실패면
        # 슬롯 설정을, 다른 키가 손상돼 harness.env 를 믿을 수 없으면(슬롯 키는 정상) 그
        # 파일을 정상으로 읽을 수 있게 고치라고 하고, 둘 다 위에 나열한 값의 파일을 다시
        # 저장하라고 한다. 어느 까닭이든 고치고 그 값을 다시 저장하면 그 자리 리뷰로
        # 풀린다(종결 r2 #1 · r3 #3 · #5).
  local name='r10 슬롯 꺼짐 missing-record → 값 불량 · 다른 키 손상의 출구를 가르고 각각 풀린다'
  local why='' v w bad
  bad='HARNESS_KNOWLEDGE_GATE="x'$'\n'   # 따옴표가 닫히지 않은 다른 키
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/r10.go" w="$C3_T/src/r10b.go"
  set_env "$C3_R" "$(env_slot "$C3_F/no-such-slot")"
  : > "$v" && dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" '!' \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING" "$TOK_DR_FIXCONF" \
    "$TOK_DR_RESAVE_VAL")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_FIXENV" && why='판독 불가 출구가 나왔다'
  [[ -n "$why" ]] && why="[값 검증 실패] $why"
  if [[ -z "$why" ]]; then
    set_env "$C3_R" "$(env_slot "$C3_S")"
    run_mna "$C3_R" edit "$v"
    review_at "$C3_T/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[슬롯 설정 고친 뒤 다시 저장] $why"
  fi
  if [[ -z "$why" ]]; then
    set_env "$C3_R" "$(env_slot "$C3_S")"$'\n'"$bad"
    : > "$w" && dr_flag "$C3_R" "$w" && rec "$C3_R" "$w" '!' \
      || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING" "$TOK_DR_FIXENV" \
      "$TOK_DR_CAUSE_ENV" "$TOK_DR_RESAVE_VAL")"
    [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_FIXCONF" && why='슬롯 설정 출구가 나왔다'
    [[ -n "$why" ]] && why="[다른 키 손상] $why"
  fi
  if [[ -z "$why" ]]; then
    set_env "$C3_R" "$(env_slot "$C3_S")"
    run_mna "$C3_R" edit "$w"
    review_at "$C3_T/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[다른 키 고친 뒤 다시 저장] $why"
  fi
  report "$name" "$why"
}

e12w() { # 심링크 세션 루트(PROJECT_DIR 는 논리 표기) + 물리적으로 루트 안인 절대 항목(중첩
         # 워크트리 — 키를 켜기 전에 플래그, 기록 없음). Stop 은 물리 루트로 소속을 보므로
         # missing-record 가 아니라 세션 루트 리뷰로 풀린다.
  local name='e12w 심링크 세션 루트 · 루트 안 절대 항목 → 세션 루트 리뷰로 해제' why=''
  local f s r
  f="$(new_dir e12w)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  s="$f/slot"; r="$s/R"
  mkdir -p "$r/.claude/hooks" "$r/.claude/harness" \
    && cp "$COMMON" "$MODULE" "$STOP_HOOK" "$r/.claude/hooks/" \
    && env_slot "$s" > "$r/.claude/harness/harness.env" && ln -s "$r" "$f/link" \
    && dr_flag "$r" "$r/.claude/worktrees/w/src/a.go" && review_at "$r/_workspace" \
    || { FIXTURE_FAIL='심링크 세션 루트'; report "$name" ''; return; }
  local STOP_PDIR="$f/link"
  run_stop "$r"
  why="$(expect_dr_released "$r")"
  report "$name" "$why"
}
