#!/usr/bin/env bash
# extra-gate-dirs.bound.cases.sh — 슬롯 Bash 스윕의 경계: 시간 예산 · 뿌리 상한 · 개행
# 경로 · 슬롯 경계 · 순회 입력 유실(C4 r1 HIGH 4건).
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice·judge·sweep 케이스 파일에 있다:
#   slot_fixture · sweep_fixture · commit_repo · make_window · set_env · new_file
#   new_mna_project · run_mna(MNA_CWD · MNA_ENV · MNA_FSIZE0) · expect_flags
#   expect_silent · new_dir · report · contains
#   C3_F · C3_R · C3_S · C3_T · MNA_PROJ · ENV_NO_KEY · GOLDEN_TRUNCATED
#   GOLDEN_PARTIAL · TOK_ROOT_CAP · OUT · RC · FIXTURE_FAIL
#
# 고정틀은 sweep 케이스와 같다(슬롯 S · 저장소 T · 형제 작업 공간 S/_workspace_T ·
# git 밖 세션 루트 R · 창보다 오래된 고정틀). 시간 예산은 SECONDS 를 환경으로 넘겨
# 주입한다 — bash 는 환경의 SECONDS 를 시작값으로 쓴다(sleep 없음).
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

BOUND_LATE='SECONDS=1000'   # 시작부터 시간 예산을 넘긴 훅 셸
TOK_TIME_CUT='시간 예산을 다 써서'   # 시간 예산 절단 문구(MSG_SWEEP_TIME_CUT)

# window_left <프로젝트> — Bash 창이 남아 있는가(소비되지 않았나).
window_left() { ls "$1/.claude/.bash-windows/" 2>/dev/null | grep -q .; }

# expect_budget_cut <프로젝트> <값> — 시간 절단 알림 · 창 소비 · 그 값의 판정 없음.
expect_budget_cut() {
  if ! contains "$OUT" "$TOK_TIME_CUT"; then printf '시간 절단 알림 없음 [%s]' "$OUT"
  elif window_left "$1"; then printf '창을 소비하지 않았다'
  else expect_flags "$1" 0 "$2"
  fi
}

# expect_kept_partial <프로젝트> — rc 0 · 뿌리 부분 알림 · 창 보존(다음 Bash 가 다시 훑음).
expect_kept_partial() {
  if [[ "$RC" -ne 0 ]]; then printf 'rc=%s' "$RC"
  elif ! contains "$OUT" "$TOK_ROOT_CAP"; then printf '부분 알림 없음 [%s]' "$OUT"
  elif ! window_left "$1"; then printf '창을 소비했다(다음 Bash 가 못 잡는다)'
  fi
}

#######################################
# 스윕 입력을 흉내 내다 생산자(프로세스 치환 서브셸)를 끊는 find·git 심을 쓴다. 끊긴
# 입력은 끝 표지가 없다 — 리다이렉트 실패(입력 0줄)와 같은 판정 경로를 밟는다.
# Arguments:
#   $1 — 심 폴더, $2 — find-repo | find-ws | git-status
#######################################
write_cut_shim() {
  local real
  case "$2" in
    git-status)
      real="$(command -v git)" || return 1
      printf '#!/bin/sh\ncase " $* " in\n  *" status "*) kill -9 "$PPID" ;;\nesac\n' \
        > "$1/git"
      printf 'exec "%s" "$@"\n' "$real" >> "$1/git"
      chmod +x "$1/git" ;;
    find-repo | find-ws)
      real="$(command -v find)" || return 1
      printf '#!/bin/sh\ncase " $* " in\n' > "$1/find"
      if [[ "$2" == find-ws ]]; then
        printf '  *" -maxdepth "*) kill -9 "$PPID" ;;\n' >> "$1/find"
      else
        printf '  *" -maxdepth "*) ;;\n  *) kill -9 "$PPID" ;;\n' >> "$1/find"
      fi
      printf 'esac\nexec "%s" "$@"\n' "$real" >> "$1/find"
      chmod +x "$1/find" ;;
  esac
}

# --- b: 시간 예산 · 뿌리 상한 (H-1) ------------------------------------------

b01() { # 시간 예산을 넘기면 판정을 멈추고 절단 알림을 내고 창을 소비한다. 그러지 않으면
        # 30 s 상한(I8)에서 훅이 취소돼 알림도 창 소비도 없이 다음 Bash 마다 같은 창을
        # 다시 돈다. 저장소 뿌리의 새 파일 · git 이 아는 삭제 두 갈래.
  local name='b01 시간 예산 초과 · 저장소 뿌리(새 파일·삭제) → 절단 알림 · 창 소비'
  local why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_T" MNA_ENV="$BOUND_LATE"
  v="$C3_T/src/b1.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > src/b1.go'
  why="$(expect_budget_cut "$C3_R" "$v")"
  if [[ -z "$why" ]]; then
    rm -f "$v" "$C3_T/src/a.go" && make_window "$C3_R" \
      || { FIXTURE_FAIL='삭제·창'; report "$name" ''; return; }
    run_mna "$C3_R" bash 'rm src/a.go'
    why="$(expect_budget_cut "$C3_R" "$C3_T/src/a.go")"
    [[ -n "$why" ]] && why="[삭제] $why"
  fi
  report "$name" "$why"
}

b02() { # 작업 공간 뿌리 루프도 같은 예산을 본다.
  local name='b02 시간 예산 초과 · 작업 공간 뿌리 → 절단 알림 · 창 소비' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_S/_workspace_T" MNA_ENV="$BOUND_LATE"
  v="$C3_S/_workspace_T/00_design.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat > 00_design.md'
  why="$(expect_budget_cut "$C3_R" "$v")"
  report "$name" "$why"
}

b03() { # 키가 없으면 시간 예산이 없다 — 187398c 와 같은 판정·출력(I2).
  local name='b03 키 부재 · 예산 넘긴 셸 → 예전처럼 4종 · 무출력' why=''
  sweep_fixture || { report "$name" ''; return; }
  set_env "$C3_R" "$ENV_NO_KEY"
  local MNA_ENV="$BOUND_LATE"
  new_file "$C3_R/src/b3.go" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > src/b3.go'
  why="$(expect_silent '키 부재')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 src/b3.go)"
  report "$name" "$why"
}

b04() { # 명령문 토큰의 뿌리는 절대경로·홈 토큰이 상한 3 을 함께 쓴다(r2 D4ⓑ). 절대
        # 저장소 둘 + 홈 저장소 둘이면 넷째는 뿌리가 아니고 알린다.
  local name='b04 절대 2 + 홈 2 저장소 → 넷째 뿌리 아님 · 상한 알림' why='' i cmd=''
  slot_fixture || { report "$name" ''; return; }
  for i in 1 2 3 4; do
    mkdir -p "$C3_S/R$i/src" && printf 'k\n' > "$C3_S/R$i/src/k.go" \
      && commit_repo "$C3_S/R$i" || { report "$name" ''; return; }
  done
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  for i in 1 2 3 4; do
    new_file "$C3_S/R$i/src/n.go" || { report "$name" ''; return; }
  done
  local -x HOME="$C3_F"
  cmd="printf x > $C3_S/R1/src/n.go; printf x > $C3_S/R2/src/n.go;"
  cmd="$cmd printf x > ~/slot/R3/src/n.go; printf x > ~/slot/R4/src/n.go"
  run_mna "$C3_R" bash "$cmd"
  contains "$OUT" "$TOK_ROOT_CAP" || why="상한 알림 없음 [$OUT]"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$C3_S/R3/src/n.go")"
  if [[ -z "$why" ]]; then
    why="$(expect_flags "$C3_R" 0 "$C3_S/R4/src/n.go")"
    [[ -n "$why" ]] && why="[넷째 저장소 R4] $why"
  fi
  report "$name" "$why"
}

b05() { # 작업 공간 토큰도 같은 상한을 쓴다 — 넷째 작업 공간은 뿌리가 아니고 알린다.
  local name='b05 작업 공간 토큰 4개 → 넷째 뿌리 아님 · 상한 알림' why='' x cmd=''
  slot_fixture || { report "$name" ''; return; }
  for x in A B C D; do
    mkdir -p "$C3_S/_workspace_$x" || { report "$name" ''; return; }
  done
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  for x in A B C D; do
    new_file "$C3_S/_workspace_$x/00_design.md" || { report "$name" ''; return; }
    cmd="$cmd cat > $C3_S/_workspace_$x/00_design.md;"
  done
  run_mna "$C3_R" bash "$cmd"
  contains "$OUT" "$TOK_ROOT_CAP" || why="상한 알림 없음 [$OUT]"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 3 "$C3_S/_workspace_C/00_design.md")"
  if [[ -z "$why" ]]; then
    why="$(expect_flags "$C3_R" 0 "$C3_S/_workspace_D/00_design.md")"
    [[ -n "$why" ]] && why="[넷째 작업 공간 D] $why"
  fi
  report "$name" "$why"
}

# --- l: 경로 개행 (H-2) ------------------------------------------------------

l01() { # 작업 공간 링크가 끝이 개행인 폴더를 가리킨다. 명령 치환이 그 개행을 지우면
        # 이름이 같은 다른 트랙 폴더(_workspace_U)를 훑는다 — 뿌리에서 빼고 알린다.
  local name='l01 작업 공간 링크 → 끝 개행 폴더 · 다른 트랙 안 훑음 · 알림' why='' u
  slot_fixture || { report "$name" ''; return; }
  u="$C3_S/_workspace_U"
  mkdir -p "$u" "$u"$'\n' && ln -s "$u"$'\n' "$C3_S/_workspace_A" \
    || { FIXTURE_FAIL='개행 폴더·링크'; report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  new_file "$u/02_plan.md" && new_file "$u"$'\n'"/02_design.md" \
    || { report "$name" ''; return; }
  local MNA_CWD="$C3_S/_workspace_A"
  run_mna "$C3_R" bash 'cat > 02_design.md'
  contains "$OUT" "$TOK_ROOT_CAP" || why="알림 없음 [$OUT]"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 0 "$u/02_plan.md")"
  report "$name" "$why"
}

l02() { # cwd 에 개행이 있다 — 가운데(S/Q<LF>R: LF 줄 목록이 S/Q 로 쪼개짐)와 끝
        # (진입부 명령 치환이 지워 이름이 같은 다른 폴더가 됨). 둘 다 cwd 를 뿌리 근원에서
        # 빼고 알린다. 다른 트랙(S/Q · S/_workspace_V)의 새 파일은 판정되지 않는다.
  local name='l02 cwd 개행(가운데·끝) → 다른 트랙 안 훑음 · 알림' why='' qr v
  slot_fixture || { report "$name" ''; return; }
  qr="$C3_S/Q"$'\n'"R"
  mkdir -p "$qr/src" "$C3_S/Q/src" "$C3_S/_workspace_V" "$C3_S/_workspace_V"$'\n' \
    && printf 'k\n' > "$qr/src/k.go" && printf 'k\n' > "$C3_S/Q/src/k.go" \
    && commit_repo "$qr" && commit_repo "$C3_S/Q" \
    || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  new_file "$C3_S/Q/src/q.go" && new_file "$qr/src/x.go" \
    || { report "$name" ''; return; }
  local MNA_CWD="$qr"
  run_mna "$C3_R" bash 'printf x > src/x.go'
  contains "$OUT" "$TOK_ROOT_CAP" || why="[가운데] 알림 없음 [$OUT]"
  if [[ -z "$why" ]]; then
    why="$(expect_flags "$C3_R" 0 "$C3_S/Q/src/q.go")"
    [[ -n "$why" ]] && why="[가운데 — S/Q] $why"
  fi
  if [[ -z "$why" ]]; then
    make_window "$C3_R" || { FIXTURE_FAIL='창'; report "$name" ''; return; }
    v="$C3_S/_workspace_V/01_plan.md"
    new_file "$v" && new_file "$C3_S/_workspace_V"$'\n'"/01_design.md" \
      || { report "$name" ''; return; }
    MNA_CWD="$C3_S/_workspace_V"$'\n'
    run_mna "$C3_R" bash 'cat > 01_design.md'
    contains "$OUT" "$TOK_ROOT_CAP" || why="[끝] 알림 없음 [$OUT]"
    if [[ -z "$why" ]]; then
      why="$(expect_flags "$C3_R" 0 "$v")"
      [[ -n "$why" ]] && why="[끝 — _workspace_V] $why"
    fi
  fi
  report "$name" "$why"
}

l03() { # 명령문 절대경로가 링크를 지나 가운데 개행 저장소(S/Q<LF>R)를 가리킨다. 그 git
        # 최상위를 줄 목록에 넣으면 S/Q 로 쪼개져 다른 트랙을 훑는다 — 빼고 알린다.
  local name='l03 절대경로 → 링크 → 개행 저장소 · S/Q 안 훑음 · 알림' why='' qr
  slot_fixture || { report "$name" ''; return; }
  qr="$C3_S/Q"$'\n'"R"
  mkdir -p "$qr/src" "$C3_S/Q/src" && printf 'k\n' > "$qr/src/k.go" \
    && printf 'k\n' > "$C3_S/Q/src/k.go" && commit_repo "$qr" \
    && commit_repo "$C3_S/Q" && ln -s "$qr" "$C3_S/lnk" \
    || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  new_file "$C3_S/Q/src/q.go" && new_file "$qr/src/x.go" \
    || { report "$name" ''; return; }
  run_mna "$C3_R" bash "printf x > $C3_S/lnk/src/x.go"
  contains "$OUT" "$TOK_ROOT_CAP" || why="알림 없음 [$OUT]"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 0 "$C3_S/Q/src/q.go")"
  report "$name" "$why"
}

# --- w: 슬롯 경계 (H-3) ------------------------------------------------------

w01() { # 슬롯 자신의 이름이 _workspace* 여도 작업 공간 뿌리는 슬롯 안쪽에서만 찾는다 —
        # 슬롯 자신이 뿌리가 되면 모든 트랙의 설계물이 이 세션 의무가 된다(I4).
  local name='w01 슬롯 이름 _workspace_trk · cwd=T/src → 다른 트랙·슬롯 바로 아래 0'
  local why='' f s t u v
  f="$(new_dir w01)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  s="$f/_workspace_trk"; t="$s/T"; u="$s/U"
  mkdir -p "$t/src" "$u/_workspace" "$s/_workspace_U" \
    && printf 'k\n' > "$t/src/a.go" && printf 'k\n' > "$u/k.go" \
    && commit_repo "$t" && commit_repo "$u" \
    && new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$s\""$'\n' \
    || { report "$name" ''; return; }
  find "$f" -exec touch -t 201901010000 {} + && make_window "$MNA_PROJ" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  new_file "$u/_workspace/03_plan.md" && new_file "$s/_workspace_U/02_design.md" \
    && new_file "$s/00_design.md" && new_file "$t/src/w1.go" \
    || { report "$name" ''; return; }
  local MNA_CWD="$t/src"
  run_mna "$MNA_PROJ" bash 'printf x > w1.go'
  why="$(expect_flags "$MNA_PROJ" 4 "$t/src/w1.go")"
  for v in "$u/_workspace/03_plan.md" "$s/_workspace_U/02_design.md" \
      "$s/00_design.md"; do
    [[ -z "$why" ]] || break
    why="$(expect_flags "$MNA_PROJ" 0 "$v")"
    [[ -n "$why" ]] && why="[${v#"$f"/}] $why"
  done
  report "$name" "$why"
}

w02() { # 슬롯 안 묶음 폴더(_workspace_b) 아래 트랙들 — cwd 의 가장 가까운 _workspace*
        # 조상이 묶음 폴더여도 그 바로 아래 설계물만 본다. 다른 트랙의 작업 공간은
        # 그 트랙의 작업 공간 뿌리일 때만 훑는다(I4).
  local name='w02 묶음 폴더 _workspace_b · cwd=b/T2/src → 다른 트랙 설계물 0' why='' b
  slot_fixture || { report "$name" ''; return; }
  b="$C3_S/_workspace_b"
  mkdir -p "$b/T2/src" "$b/U2/_workspace" && printf 'k\n' > "$b/T2/src/a.go" \
    && printf 'k\n' > "$b/U2/k.go" && commit_repo "$b/T2" && commit_repo "$b/U2" \
    || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  new_file "$b/U2/_workspace/03_plan.md" && new_file "$b/T2/src/w2.go" \
    || { report "$name" ''; return; }
  local MNA_CWD="$b/T2/src"
  run_mna "$C3_R" bash 'printf x > w2.go'
  why="$(expect_flags "$C3_R" 4 "$b/T2/src/w2.go")"
  if [[ -z "$why" ]]; then
    why="$(expect_flags "$C3_R" 0 "$b/U2/_workspace/03_plan.md")"
    [[ -n "$why" ]] && why="[다른 트랙 U2] $why"
  fi
  report "$name" "$why"
}

# --- d: 순회 입력 유실 (H-4) ---------------------------------------------------

d01() { # 뿌리 목록 순회가 임시 파일(히어독)에 기대면, 그 파일을 못 만들 때 0회 돌고 창만
        # 소비해 무기록·무알림이 된다(C1 H-A 부류). 주입: ulimit -f 0 — 플래그 쓰기도
        # 막히므로 고친 판은 기록 실패를 알린다. 옛 판은 아무것도 내지 않았다.
  local name='d01 임시 파일 불가(ulimit -f 0) · cwd=T → 무알림 아님' why=''
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_T" MNA_FSIZE0=1
  new_file "$C3_T/src/d1.go" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > src/d1.go'
  if [[ "$RC" -ne 0 ]]; then why="rc=$RC"
  elif ! contains "$OUT" "$GOLDEN_PARTIAL"; then why="기록 실패 알림 없음 [$OUT]"
  fi
  report "$name" "$why"
}

d02() { # find 입력이 끝 표지 없이 끊기면(생산자 사망 — 리다이렉트 실패와 같은 판정)
        # 뿌리를 다 못 훑은 것이다. 알리고 창을 남겨 다음 Bash 가 다시 훑게 한다.
        # 저장소 뿌리 find · 작업 공간 뿌리 find 두 갈래.
  local name='d02 find 입력 유실(저장소·작업 공간) → 부분 알림 · 창 보존' why='' shim
  sweep_fixture || { report "$name" ''; return; }
  shim="$(new_dir cutrepo)" && write_cut_shim "$shim" find-repo \
    || { FIXTURE_FAIL='find 심'; report "$name" ''; return; }
  new_file "$C3_T/src/d2.go" || { report "$name" ''; return; }
  (
    MNA_CWD="$C3_T"
    PATH="$shim:$PATH"
    run_mna "$C3_R" bash 'printf x > src/d2.go'
    printf '%s\n%s\n' "$RC" "$OUT" > "$TMPROOT/d02.out"
  )
  RC="$(head -n 1 "$TMPROOT/d02.out")"; OUT="$(tail -n +2 "$TMPROOT/d02.out")"
  DID_RUN=1
  why="$(expect_kept_partial "$C3_R")"
  [[ -n "$why" ]] && why="[저장소 find] $why"
  if [[ -z "$why" ]]; then
    rm -f "$C3_R"/.claude/.bash-windows/* && make_window "$C3_R" \
      && shim="$(new_dir cutws)" && write_cut_shim "$shim" find-ws \
      && new_file "$C3_S/_workspace_T/00_design.md" \
      || { FIXTURE_FAIL='창·심'; report "$name" ''; return; }
    (
      MNA_CWD="$C3_S/_workspace_T"
      PATH="$shim:$PATH"
      run_mna "$C3_R" bash 'cat > 00_design.md'
      printf '%s\n%s\n' "$RC" "$OUT" > "$TMPROOT/d02.out"
    )
    RC="$(head -n 1 "$TMPROOT/d02.out")"; OUT="$(tail -n +2 "$TMPROOT/d02.out")"
    why="$(expect_kept_partial "$C3_R")"
    [[ -n "$why" ]] && why="[작업 공간 find] $why"
  fi
  report "$name" "$why"
}

d03() { # git status 입력(창과 무관한 삭제 판정)이 끝 표지 없이 끊겨도 같다.
  local name='d03 git status 입력 유실 → 부분 알림 · 창 보존' why='' shim
  sweep_fixture || { report "$name" ''; return; }
  shim="$(new_dir cutgit)" && write_cut_shim "$shim" git-status \
    && rm -f "$C3_T/src/a.go" \
    || { FIXTURE_FAIL='git 심'; report "$name" ''; return; }
  (
    MNA_CWD="$C3_T"
    PATH="$shim:$PATH"
    run_mna "$C3_R" bash 'rm src/a.go'
    printf '%s\n%s\n' "$RC" "$OUT" > "$TMPROOT/d03.out"
  )
  RC="$(head -n 1 "$TMPROOT/d03.out")"; OUT="$(tail -n +2 "$TMPROOT/d03.out")"
  DID_RUN=1
  why="$(expect_kept_partial "$C3_R")"
  report "$name" "$why"
}
