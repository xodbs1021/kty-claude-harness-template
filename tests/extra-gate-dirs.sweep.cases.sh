#!/usr/bin/env bash
# extra-gate-dirs.sweep.cases.sh — Bash 스윕을 슬롯 저장소·트랙 작업 공간으로 넓힌 케이스.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice·judge 케이스 파일에 있다:
#   slot_fixture · commit_repo · commit_more · make_window · set_env · places
#   run_mna(MNA_CWD · MNA_FAIL · MNA_NOHOME) · expect_flags · expect_record
#   record_lines_of · expect_silent · flat · new_dir · report · contains
#   C3_F · C3_R · C3_S · C3_T · ENV_NO_KEY · GOLDEN_PARTIAL · US
#   TOK_RECORD_FAIL · TOK_RECORD_PERM · OUT · RC · ERR · DID_RUN · FIXTURE_FAIL
#
# 고정틀: 슬롯 S 안에 저장소 T(커밋됨)와 형제 작업 공간 S/_workspace_T. 세션 루트 R 은
# git 밖이다. 창을 만들기 전에 고정틀 파일을 모두 창보다 오래되게 돌려 놓는다 — 그래서
# 스윕 대상은 그 뒤 시험이 만든 파일뿐이고 판정이 결정적이다(sleep 없음).
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

TOK_ROOT_CAP='일부 저장소·작업 공간만 훑었을 수 있다'   # MSG_SWEEP_ROOT_CAP

# sweep_fixture [슬롯 값] — slot_fixture 뒤 고정틀 전체를 오래되게 돌리고 창을 하나 만든다.
sweep_fixture() {
  slot_fixture "$@" || return 1
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; return 1; }
}

# new_file <경로> — 부모를 만들고 내용 한 줄짜리 파일을 쓴다(창보다 새 파일).
new_file() {
  mkdir -p "${1%/*}" && printf 'x\n' > "$1" \
    || { FIXTURE_FAIL="파일 $1"; return 1; }
}

# expect_record_count <프로젝트> <값> <줄 수> — 그 값의 기록 줄이 정확히 그 수인가(중복 판정).
expect_record_count() {
  local tails n=0
  tails="$(record_lines_of "$1" "$2")"
  [[ -n "$tails" ]] && n=$(($(printf '%s\n' "$tails" | wc -l)))
  [[ "$n" -eq "$3" ]] || printf '기록 줄 %s개 (기대 %s — 중복 판정?)' "$n" "$3"
}

# T 자리 꼬리(저장소 T 의 _workspace 와 형제 작업 공간).
t_places() { places "$C3_T/_workspace" "$C3_S/_workspace_T"; }

# --- s: 슬롯 저장소 코드 · 설계물 -------------------------------------------

s01() { # 코드 · 절대경로 토큰 → 4종(기존 토큰 뿌리 — 회귀 고정).
  local name='s01 슬롯 코드 · 절대경로 명령 → 4종 + T 자리' why='' v
  sweep_fixture || { report "$name" ''; return; }
  v="$C3_T/src/n1.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash "printf x > $v"
  why="$(expect_flags "$C3_R" 4 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" "$(t_places)")"
  report "$name" "$why"
}

s02() { # 코드 · 홈 토큰(~/) → 4종. 홈 토큰은 슬롯 저장소만 뿌리로 더한다.
  local name='s02 슬롯 코드 · ~/ 명령 → 4종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local -x HOME="$C3_F"
  v="$C3_T/src/n2.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > ~/slot/T/src/n2.go'
  why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

s03() { # 코드 · cwd 상대경로 → 4종. 세션 루트가 git 밖이면 기존 cwd 뿌리(같은 저장소의
        # 다른 체크아웃)가 못 잡는다 — cwd 의 슬롯 저장소를 뿌리로(cc M1).
  local name='s03 슬롯 코드 · cwd=T 상대경로 → 4종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_T"
  v="$C3_T/src/n3.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > src/n3.go'
  why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

s04() { # 설계 · 절대경로 토큰 → 3종(작업 공간 뿌리 — git 밖).
  local name='s04 슬롯 설계 · 절대경로 → 3종 + 그 폴더' why='' v
  sweep_fixture || { report "$name" ''; return; }
  v="$C3_S/_workspace_T/00_design.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash "cat > $v"
  why="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" "$C3_S/_workspace_T")"
  report "$name" "$why"
}

s05() { # 설계 · 홈 토큰 → 3종.
  local name='s05 슬롯 설계 · ~/ → 3종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local -x HOME="$C3_F"
  v="$C3_S/_workspace_T/01_plan.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat > ~/slot/_workspace_T/01_plan.md'
  why="$(expect_flags "$C3_R" 3 "$v")"
  report "$name" "$why"
}

s06() { # 설계 · cwd = 작업 공간 → 3종.
  local name='s06 슬롯 설계 · cwd=_workspace_T → 3종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_S/_workspace_T"
  v="$C3_S/_workspace_T/02_design.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat > 02_design.md'
  why="$(expect_flags "$C3_R" 3 "$v")"
  report "$name" "$why"
}

s07() { # 슬롯 루트를 cwd 로 둔 상대경로는 못 잡는다(공시 — 슬롯 전체 스윕 금지, I4).
  local name='s07 cwd=슬롯 루트 상대경로 → 0 (공시 고정)' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_S"
  v="$C3_T/src/n7.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > T/src/n7.go'
  why="$(expect_flags "$C3_R" 0 "$v")"
  report "$name" "$why"
}

s08() { # 키가 없으면 홈 토큰은 뿌리가 아니다(I2 — 187398c 와 같은 판정).
  local name='s08 키 부재 · ~/ 명령 → 0 · 무출력' why='' v
  sweep_fixture || { report "$name" ''; return; }
  set_env "$C3_R" "$ENV_NO_KEY"
  local -x HOME="$C3_F"
  v="$C3_T/src/n8.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > ~/slot/T/src/n8.go'
  why="$(expect_silent '키 부재')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 0 "$v")"
  report "$name" "$why"
}

s09() { # 삭제 · cwd 상대경로 → git 이 아는 삭제를 4종으로.
  local name='s09 슬롯 저장소 삭제 · cwd=T → 4종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_T"
  v="$C3_T/src/a.go"
  rm -f "$v"
  run_mna "$C3_R" bash 'rm src/a.go'
  why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

#######################################
# s10 의 awk 심: 홈 토큰 추출 프로그램일 때만 실패하고 나머지는 진짜 awk 로 넘긴다.
# Arguments:
#   $1 — 심 폴더
#######################################
write_awk_shim() {
  local real
  real="$(command -v awk)" || return 1
  cat > "$1/awk" <<EOF
#!/bin/sh
case "\$*" in *'[~\$][-A-Za-z0-9_./~@+{}]*'*) exit 1 ;; esac
exec "$real" "\$@"
EOF
  chmod +x "$1/awk"
}

s10() { # 뿌리를 다 훑지 못하면 알린다 — 명령문 경로가 상한(저장소 3개)을 넘을 때,
        # 그리고 홈 토큰 추출이 실패할 때(C1 계약: rc 2 를 빈 성공으로 받지 않는다).
  local name='s10 뿌리 상한 초과 · 홈 토큰 추출 실패 → 알림' why='' i cmd='' shim
  slot_fixture || { report "$name" ''; return; }
  for i in 1 2 3 4; do
    mkdir -p "$C3_S/R$i/src" && printf 'x\n' > "$C3_S/R$i/src/k.go" \
      && commit_repo "$C3_S/R$i" || { report "$name" ''; return; }
  done
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  for i in 1 2 3 4; do
    new_file "$C3_S/R$i/src/n.go" || { report "$name" ''; return; }
    cmd="$cmd printf x > $C3_S/R$i/src/n.go;"
  done
  run_mna "$C3_R" bash "$cmd"
  contains "$OUT" "$TOK_ROOT_CAP" || why="상한 초과 알림 없음 [$OUT]"
  if [[ -z "$why" ]]; then
    shim="$(new_dir awkshim)" && write_awk_shim "$shim" \
      || { FIXTURE_FAIL='awk 심'; report "$name" ''; return; }
    make_window "$C3_R" || { FIXTURE_FAIL='창'; report "$name" ''; return; }
    local -x HOME="$C3_F"
    local -x PATH="$shim:$PATH"
    new_file "$C3_T/src/n10.go" || { report "$name" ''; return; }
    run_mna "$C3_R" bash 'printf x > ~/slot/T/src/n10.go'
    contains "$OUT" "$TOK_ROOT_CAP" || why="홈 토큰 추출 실패 알림 없음 [$OUT]"
  fi
  report "$name" "$why"
}

s11() { # 실패 이벤트(PostToolUseFailure) 페이로드도 같은 스윕이다.
  local name='s11 실패 이벤트 · cwd=T → 4종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_T" MNA_FAIL=1
  v="$C3_T/src/n11.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > src/n11.go; false'
  why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

s12() { # 창이 없으면(PreToolUse 미등록) 스윕하지 않는다 — 슬롯이 켜져도 같다(회귀 고정).
  local name='s12 창 없음 · cwd=T → 0 · 무출력' why='' v
  slot_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_T"
  v="$C3_T/src/n12.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > src/n12.go'
  why="$(expect_silent '창 없음')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 0 "$v")"
  report "$name" "$why"
}

# --- f: 작업 공간 뿌리 ----------------------------------------------------

f01() { # T 가 무시하는 `_workspace_trk/` 의 설계물 — cwd 가 그 폴더여도(작업 공간 뿌리),
        # cwd=T 상대경로여도(저장소 뿌리의 설계 선판정 — check-ignore 앞) 3종이다.
  local name='f01 무시된 T/_workspace_trk 설계 · cwd 두 갈래 → 3종' why='' v
  slot_fixture || { report "$name" ''; return; }
  printf '_workspace_trk/\n' > "$C3_T/.gitignore" && commit_more "$C3_T" \
    && mkdir -p "$C3_T/_workspace_trk" || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  local MNA_CWD="$C3_T/_workspace_trk"
  v="$C3_T/_workspace_trk/00_design.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat > 00_design.md'
  why="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" "$C3_T/_workspace_trk")"
  if [[ -z "$why" ]]; then
    make_window "$C3_R" || { FIXTURE_FAIL='창'; report "$name" ''; return; }
    MNA_CWD="$C3_T"
    v="$C3_T/_workspace_trk/01_plan.md"
    new_file "$v" || { report "$name" ''; return; }
    run_mna "$C3_R" bash 'cat > _workspace_trk/01_plan.md'
    why="$(expect_flags "$C3_R" 3 "$v")"
    [[ -n "$why" ]] && why="[cwd=T 선판정] $why"
  fi
  report "$name" "$why"
}

f02() { # 바깥 저장소 O 가 감싼 슬롯의 작업 공간 뿌리는 설계 모양만 본다 — O 의 status·
        # 앵커·무시 판정을 돌리지 않는다(cc8). O 는 슬롯 밖이라 저장소 뿌리도 아니다.
  local name='f02 바깥 저장소 안 작업 공간 → 설계만 3종, 그 밖 0' why='' f o w d
  f="$(new_dir f02)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  o="$f/outer"
  w="$o/slot/_workspace_x"
  mkdir -p "$w" "$o/.claude/hooks" && printf 'k\n' > "$o/keep.txt" \
    && printf 'z\n' > "$o/.claude/hooks/z.sh" && commit_repo "$o" \
    || { report "$name" ''; return; }
  new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$o/slot\""$'\n' \
    || { report "$name" ''; return; }
  find "$f" -exec touch -t 201901010000 {} + && make_window "$MNA_PROJ" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  d="$w/00_design.md"
  new_file "$d" && new_file "$w/.claude/hooks/y.sh" && new_file "$w/notes.txt" \
    && rm -f "$o/keep.txt" "$o/.claude/hooks/z.sh" \
    || { report "$name" ''; return; }
  local MNA_CWD="$w"
  run_mna "$MNA_PROJ" bash 'cat > 00_design.md; rm ../../keep.txt'
  why="$(expect_flags "$MNA_PROJ" 3 "$d")"
  if [[ -z "$why" ]] && cat "$MNA_PROJ"/.claude/.needs-* 2>/dev/null \
      | grep -v -xF -- "$d" | grep -q .; then
    why="설계물 밖 판정이 섰다 [$(cat "$MNA_PROJ"/.claude/.needs-* | sort -u \
      | tr '\n' ' ')]"
  fi
  report "$name" "$why"
}

f03() { # 같은 파일이 작업 공간 뿌리(T/_workspace)와 저장소 뿌리(T)에 다 걸려도 한 번만
        # 판정한다 — 기록이 두 줄(갱신 표시 · 현재 기록)뿐이다.
  local name='f03 작업 공간·저장소 뿌리 중복 → 한 번만 판정(기록 2줄)' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_T/_workspace"
  v="$C3_T/_workspace/00_design.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat > 00_design.md'
  why="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$why" ]] && why="$(expect_record_count "$C3_R" "$v" 2)"
  report "$name" "$why"
}

f04() { # T 스윕이 prune 하는 node_modules 아래 작업 공간도 cwd 가 가리키면 뿌리다(git
        # 최상위 조건 없음 — X2).
  local name='f04 T/node_modules/_workspace_nm 설계 · cwd=그 폴더 → 3종' why='' v
  slot_fixture || { report "$name" ''; return; }
  mkdir -p "$C3_T/node_modules/_workspace_nm" || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  local MNA_CWD="$C3_T/node_modules/_workspace_nm"
  v="$C3_T/node_modules/_workspace_nm/00_design.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat > 00_design.md'
  why="$(expect_flags "$C3_R" 3 "$v")"
  report "$name" "$why"
}

f05() { # 작업 공간 뿌리는 물리화한 뒤 쓴다(cc5). cwd 가 작업 공간을 가리키는 심링크면
        # 물리화해야 find 가 그 안을 훑는다(find 는 시작점 심링크를 따라가지 않는다). 쌍 뿌리
        # (S/_workspace_T)와 겹쳐도 한 번만 판정한다. 슬롯 안 심링크가 슬롯 밖 작업 공간을
        # 가리키면 뿌리가 아니다(I4 — 다른 트랙을 훑지 않는다).
  local name='f05 심링크 작업 공간 cwd → 물리화 · 중복 없음 · 슬롯 밖 링크는 0' why=''
  local v o
  slot_fixture || { report "$name" ''; return; }
  o="$C3_F/other/_workspace"
  ln -s "$C3_S/_workspace_T" "$C3_S/_workspace_alias" && mkdir -p "$o" \
    && ln -s "$o" "$C3_S/_workspace_q" \
    || { FIXTURE_FAIL='심링크'; report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  local MNA_CWD="$C3_S/_workspace_alias"
  v="$C3_S/_workspace_T/03_plan.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat > 03_plan.md'
  why="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$why" ]] && why="$(expect_record_count "$C3_R" "$v" 2)"
  if [[ -z "$why" ]]; then
    make_window "$C3_R" || { FIXTURE_FAIL='창'; report "$name" ''; return; }
    MNA_CWD="$C3_S/_workspace_q"
    new_file "$o/00_design.md" || { report "$name" ''; return; }
    run_mna "$C3_R" bash 'cat > 00_design.md'
    why="$(expect_flags "$C3_R" 0 "$o/00_design.md")"
    [[ -n "$why" ]] && why="[슬롯 밖을 가리키는 링크] $why"
  fi
  report "$name" "$why"
}

# --- 쌍 뿌리 · 기록 실패 · HOME 미설정 --------------------------------------

s_pair1() { # cwd=저장소 T 에서 형제 작업 공간 `../_workspace_T/` 에 쓴 설계물 → 3종(X5).
  local name='s-pair1 cwd=T · ../_workspace_T/02_plan.md → 3종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_T"
  v="$C3_S/_workspace_T/02_plan.md"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat > ../_workspace_T/02_plan.md'
  why="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" "$C3_S/_workspace_T")"
  report "$name" "$why"
}

s_pair2() { # cwd=작업 공간 `_workspace_T` 에서 형제 저장소 `../T/` 를 고침 → 4종(X5).
  local name='s-pair2 cwd=_workspace_T · ../T/src/a.go 수정 → 4종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD="$C3_S/_workspace_T"
  v="$C3_T/src/a.go"
  printf 'y\n' >> "$v"
  run_mna "$C3_R" bash "sed -i.bak s/a/b/ ../T/src/a.go"
  why="$(expect_flags "$C3_R" 4 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" "$(t_places)")"
  report "$name" "$why"
}

s_nonpair() { # 쌍이 아닌 형제 clone 을 상대경로로 고치면 못 잡는다(공시 고정 — cc2).
  local name='s-nonpair cwd=T · ../B/x.go(쌍 아님) → 0 (공시 고정)' why='' b v
  slot_fixture || { report "$name" ''; return; }
  b="$C3_S/B"
  mkdir -p "$b" && printf 'k\n' > "$b/keep.txt" && commit_repo "$b" \
    || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  local MNA_CWD="$C3_T"
  v="$b/x.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > ../B/x.go'
  why="$(expect_flags "$C3_R" 0 "$v")"
  report "$name" "$why"
}

s_rec() { # Bash 경로의 기록 실패는 스윕 부분 기록 문구(MSG_SWEEP_PARTIAL)로 접지 않고
          # RECORD_MSG 로 낸다. 한 스윕 안에 회복 가능·영구가 섞이면 둘 다 싣는다(sec C3
          # LOW-5 — 영구가 회복 가능을 덮어 안내가 사라지지 않게).
  local name='s-rec Bash 기록 실패 → 기록 실패 문구(회복 가능·영구 둘 다), 부분 문구 아님'
  local why='' v
  sweep_fixture || { report "$name" ''; return; }
  rm -f "$C3_R/.claude/.review-dirs" && mkdir "$C3_R/.claude/.review-dirs" \
    || { FIXTURE_FAIL='기록 파일 치환'; report "$name" ''; return; }
  local MNA_CWD="$C3_T"
  v="$C3_T/src/r1.go"
  new_file "$v" && new_file "$C3_T/src/r${US}2.go" \
    || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'printf x > src/r1.go; printf x > src/r2.go'
  if ! contains "$OUT" "$TOK_RECORD_FAIL"; then why="회복 가능 문구 없음 [$OUT]"
  elif ! contains "$OUT" "$TOK_RECORD_PERM"; then why="영구 문구 없음 [$OUT]"
  elif contains "$OUT" "$GOLDEN_PARTIAL"; then why="부분 기록 문구로 접혔다 [$OUT]"
  fi
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

h_unset() { # set -u + HOME 미설정 + 홈 토큰 명령 → 셸이 살아 창을 소비하고 stderr 0(cc5).
  local name='h-unset set -u · HOME 미설정 · ~/ 명령 → 생존 · 창 소비 · stderr 0' why=''
  sweep_fixture || { report "$name" ''; return; }
  local MNA_NOHOME=1 MNA_CWD="$C3_T"
  run_mna "$C3_R" bash 'cat ~/x > ~/slot/T/src/h.go'
  if [[ "$RC" -ne 0 ]]; then why="rc=$RC (셸이 죽었다) stderr=[$ERR]"
  elif [[ -n "$ERR" ]]; then why="stderr=[$ERR]"
  elif ls "$C3_R/.claude/.bash-windows/" 2>/dev/null | grep -q .; then
    why='창을 소비하지 않았다'
  fi
  report "$name" "$why"
}
