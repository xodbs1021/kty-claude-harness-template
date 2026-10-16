#!/usr/bin/env bash
# extra-gate-dirs.cause.cases.sh — 원인을 확정할 수 없거나 나중에야 드러나는 실패의
# 안내 케이스: 평가 서브셸의 신호 종료(Stop 은 rc 만 본다) · 현재 기록 줄만 1023바이트를
# 넘는 값의 git 판독 실패(자리를 몰라 그때는 알 수 없다) · 발행 ② 기록 판독 실패의 원인
# 목록. 안내가 원인을 단정하지 않고, 말한 출구가 실제로 푸는가를 본다.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice·judge·release·life·settle 케이스 파일에 있다:
#   stop_fixture · run_stop · run_pub · dr_flag · rec · review_at · review_now
#   expect_dr_released · expect_dr_slot_block · new_mna_project · edit_new · run_mna
#   new_dir · report · contains · flat · MODULE · STOP_HOOK · MNA_PROJ · C3_R · C3_T
#   TOK_DR_MISSING · TOK_DR_NOEXIT_LONG · TOK_DR_ASKUSER · TOK_DR_SYNC ·
#   TOK_DR_EVALMOD · TOK_RECORD_GIT · TOK_RECORD_PERM · TOK_PUB_NOTE · OUT · ERR · RC
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

# 안내 문구 조각(훅 상수와 대조).
TOK_DR_EVALSIG='리뷰 자리 판정이 신호로 끝났다(rc '   # 평가 서브셸의 신호 종료
TOK_DR_ENV_NOSYNC='환경 원인이면 다시 설치해도 풀리지 않는다'
TOK_RECORD_GIT_LONG='기록 줄(값과 리뷰 자리 경로들)이 1023바이트를 넘으면'
TOK_PUB_NOTE_ENV='기록 판독기 awk 의 환경 장애'

v25() { # 평가 서브셸이 신호로 죽으면(rc 128 이상 — 실사례: bash 3.2 에서 파일 크기
        # 한도 아래 히어독 임시 파일 쓰기의 SIGXFSZ, rc 153) 모듈은 rc 를 내지 못하고
        # Stop 은 원인을 모른다. 모듈 오류로 단정해 sync 를 확정 출구로 내면 자원 한도
        # 같은 환경 원인에는 풀리지 않는 길이다 — rc 를 싣고 두 갈래를 가르며 사용자
        # 판단을 안내한다. 막음은 그대로이고, 모듈 탓이면 모듈을 되돌려(sync 가 하는
        # 일) 같은 리뷰로 풀린다. 주입은 결정적으로 한다 — 판정 함수 심이 자기
        # 프로세스를 SIGKILL 로 끝낸다(SIGXFSZ 는 물려받은 무시 상태에서는 죽이지 않고,
        # bash 5.1 이상은 작은 히어독을 파이프로 만들어 한도에 닿지 않는다).
  local name='v25 평가 신호 종료(rc 137) → sync 단정 없음 · 사용자 판단 / 되돌리면 해제'
  local why='' v m
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v25.go"
  m="$C3_R/.claude/hooks/_extra_gate_dirs.sh"
  # exec 가 평가 서브셸을 sh 로 바꾸므로 sh 의 $$ 가 그 서브셸이다(bash 3.2 에는
  # BASHPID 가 없다).
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && review_at "$C3_T/_workspace" \
    && printf '%s\n' \
      "judge_review_rows() { exec sh -c 'kill -KILL \$\$'; }" >> "$m" \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-신호 주입}"; report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "${TOK_DR_EVALSIG}137" \
    "$TOK_DR_ENV_NOSYNC" "$TOK_DR_ASKUSER")"
  if [[ -z "$why" ]]; then
    if contains "$ERR" "$TOK_DR_SYNC"; then
      why='sync 를 확정 출구로 안내한다'
    elif contains "$ERR" "$TOK_DR_EVALMOD"; then
      why='원인을 모르는 신호 종료를 모듈 오류로 단정한다'
    fi
  fi
  [[ -n "$why" ]] && why="[신호 종료] $why"
  if [[ -z "$why" ]]; then
    cp "$MODULE" "$m" || { FIXTURE_FAIL='모듈 복구'; report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[모듈을 되돌린 뒤] $why"
  fi
  report "$name" "$why"
}

v26() { # 슬롯 ④ 앵커 저장소의 git 판독 실패 알림은 "다시 저장하면 기록된다" 를
        # 무조건 말하면 안 된다 — 갱신 표시는 1023바이트 안이고 현재 기록 줄(값과 두
        # 자리)만 넘는 값은 git 이 실패한 때 자리를 몰라 알아챌 수 없고, git 을 고쳐
        # 다시 저장하면 그때 영구 알림이 나간다(2단계). 알림이 그 한정어를 싣고, 한정어가
        # 사실이다 — 고쳐 다시 저장하면 영구 알림이 나가고 모든 자리 리뷰로도 막힌다.
  local name='v26 기록 줄만 1023B 초과 · ④ git 판독 실패 → 한정어 · 고친 뒤 영구 · 막음'
  local why='' f a b s u v
  f="$(new_dir v26)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  a="$(printf '%200s' '' | tr ' ' a)"; b="$(printf '%200s' '' | tr ' ' b)"
  s="$f/slot"; u="$s/$a/$b/U"; v="$u/.claude/hooks/x.sh"
  mkdir -p "$u/.claude/hooks" \
    && printf 'gitdir: %s\n' "$f/nowhere" > "$u/.git" \
    && new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$s\""$'\n' \
    && cp "$STOP_HOOK" "$MNA_PROJ/.claude/hooks/" \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-고정틀}"; report "$name" ''; return; }
  edit_new "$MNA_PROJ" "$v" || { report "$name" ''; return; }
  if ! contains "$OUT" "$TOK_RECORD_GIT"; then
    why="[저장 알림] git 판독 실패 알림 없음 [$OUT]"
  elif ! contains "$OUT" "$TOK_RECORD_GIT_LONG"; then
    why='[저장 알림] 기록 줄 1023바이트 한정어 없음'
  elif contains "$OUT" "$TOK_RECORD_PERM"; then
    why='[저장 알림] 자리를 모르는 때 영구 알림이 나왔다'
  fi
  # 한정어가 사실인가: git 을 고쳐 다시 저장하면 영구 알림 → 모든 자리 리뷰로도 막음.
  if [[ -z "$why" ]]; then
    rm -f "$u/.git" && git -C "$u" init -q \
      || { FIXTURE_FAIL='.git 복구'; report "$name" ''; return; }
    run_mna "$MNA_PROJ" edit "$v"
    contains "$OUT" "$TOK_RECORD_PERM" \
      || why="[git 복구 뒤 다시 저장] 영구 알림 없음 [$OUT]"
  fi
  if [[ -z "$why" ]]; then
    review_at "$u/_workspace" && review_at "$s/$a/$b/_workspace_U" \
      && review_at "$MNA_PROJ/_workspace" || { report "$name" ''; return; }
    run_stop "$MNA_PROJ"
    why="$(expect_dr_slot_block "$MNA_PROJ" "$TOK_DR_MISSING" \
      "$TOK_DR_NOEXIT_LONG" "  - $v")"
    [[ -n "$why" ]] && why="[모든 자리 리뷰] $why"
  fi
  report "$name" "$why"
}

# v27_pub_shim <심 폴더> <프로젝트> — 심을 PATH 앞에 둔 채로만 발행 가드를 돌린다.
v27_pub_shim() {
  local -x PATH="$1:$PATH"
  run_pub "$2"
}

v27() { # 발행 ② 가 기록 판독기(awk)의 환경 장애로 기록을 읽지 못하고 세션 루트
        # 리뷰로 통과하면, 통과 알림의 원인 목록이 그 원인을 싣는다 — "(모듈·기록
        # 파일)" 만이면 원인이 아닌 곳을 고치러 보낸다(Stop 평가 실패의 원인 가름과
        # 같은 목록). 출구는 말하지 않는 알림이라 문구만 본다.
  local name='v27 발행 ② 판독기 awk 실패 + 루트 리뷰 → 통과 · 알림 원인에 환경 장애'
  local why='' shim real
  stop_fixture || { report "$name" ''; return; }
  real="$(command -v awk)"
  shim="$(new_dir dirsawk)" \
    && printf '#!/bin/sh\n[ "$2" = mode=dirs ] && exit 2\nexec %s "$@"\n' \
      "$real" > "$shim/awk" && chmod +x "$shim/awk" \
    && rec "$C3_R" "$C3_T/src/v27.go" "$C3_T/_workspace" \
    && review_now "$C3_R/_workspace" \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-awk 심}"; report "$name" ''; return; }
  v27_pub_shim "$shim" "$C3_R"
  if [[ "$RC" -ne 0 ]]; then
    why="rc=$RC (기대 0) [$(flat "$ERR" | head -c 200)]"
  elif ! contains "$OUT" "$TOK_PUB_NOTE"; then
    why="통과 알림 없음 [$OUT]"
  elif ! contains "$OUT" "$TOK_PUB_NOTE_ENV"; then
    why="원인 목록에 환경 장애 없음 [$OUT]"
  fi
  report "$name" "$why"
}
