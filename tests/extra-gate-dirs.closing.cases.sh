#!/usr/bin/env bash
# extra-gate-dirs.closing.cases.sh — PR① 종결 라운드 r2 · r3 처분 케이스: 없는 사용자의
# `~사용자` · 비ASCII 홈 토큰 · 홈 토큰 경로의 같은 뿌리 중복 계수 · 상대 cwd · 알림
# 표식 쓰기 EFBIG · nocasematch 복원 · 기록 줄 길이 경계(r2, k32–k39) · 홈 토큰의 `:`
# 경계 · 사용자 조회 실패(r3, k40–k43).
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice·judge·sweep·bound·capture 케이스 파일에 있다:
#   slot_fixture · sweep_fixture · commit_repo · make_window · new_file
#   new_mna_project · run_mna(MNA_CWD · MNA_ENV · MNA_FSIZE0) · run_mna_bounded
#   run_module · expect_flags · json_message_ok · new_dir · report · contains
#   flat · C3_F · C3_R · C3_S · C3_T · MNA_PROJ · MNA_OUT_FILE · TOK_NOTICE
#   TOK_ROOT_CAP
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

k32() { # 셸은 없는 사용자의 `~사용자` 를 펼치지 않는다 — 글자 그대로 남은 경로는 cwd
        # 스윕이 덮는다. 따옴표 안 · 히어독 · 버전 범위의 `~단어` 는 부분 알림을 내지 않는다.
  local name='k32 없는 사용자의 ~단어(따옴표 안 · 히어독 · 버전) → 부분 알림 없음'
  local why='' c
  run_module '
home_path_tokens "git commit -m \"perf: ~2x faster\""; echo "q=$?"
home_path_tokens "npm pkg set a.b=~4.17.21 a=~4.17.21"; echo "v=$?"' HOME=/h
  if [[ "$RC" -ne 0 ]]; then why="모듈 셸 rc=$RC [$ERR]"
  elif [[ "$(flat "$OUT")" != 'q=0 v=0' ]]; then why="모듈 판독 [$(flat "$OUT")]"
  fi
  if [[ -z "$why" ]]; then
    sweep_fixture || { report "$name" ''; return; }
    for c in 'git commit -m "perf: ~2x faster"' 'echo "약 (~5 ms)"' \
        $'cat > n.md <<\'EOF\'\n~~~\n~~취소선~~ 본문\n~~~\nEOF' \
        'echo "prefix ~version"' 'npm pkg set a.b=~4.17.21' \
        'cat ~nouser-k32/a'; do
      make_window "$C3_R" || { FIXTURE_FAIL='창'; report "$name" ''; return; }
      run_mna "$C3_R" bash "$c"
      if contains "$OUT" "$TOK_ROOT_CAP"; then
        why="[$(flat "$c")] 거짓 부분 알림"
        break
      fi
    done
  fi
  report "$name" "$why"
}

k33() { # 있는 사용자의 `~사용자` 는 셸이 그 홈으로 펼친다 — 훅은 그 홈을 모르니 알린다.
        # `~+` · `~-` 도 셸이 cwd · 이전 cwd 로 펼치는 자리라 알린다.
  local name='k33 있는 사용자의 ~root · ~+ · ~- → 모듈 rc 3 · 부분 알림' why=''
  run_module '
home_path_tokens "cat ~root/a"; echo "r=$?"
home_path_tokens "cat ~+/a"; echo "p=$?"
home_path_tokens "cd ~-"; echo "m=$?"' HOME=/h
  if [[ "$RC" -ne 0 ]]; then why="모듈 셸 rc=$RC [$ERR]"
  elif [[ "$(flat "$OUT")" != 'r=3 p=3 m=3' ]]; then
    why="모듈 판독 [$(flat "$OUT")]"
  fi
  if [[ -z "$why" ]]; then
    sweep_fixture || { report "$name" ''; return; }
    run_mna "$C3_R" bash 'printf x > ~root/k33.txt'
    contains "$OUT" "$TOK_ROOT_CAP" || why="부분 알림 없음 [$OUT]"
  fi
  report "$name" "$why"
}

k34() { # 홈 토큰은 비ASCII 경로도 끝까지 읽는다 — `~/slot/트랙/U/src/n.go` 가 홈의 `slot/`
        # 에서 끊기면 그 저장소를 훑지 못한다.
  local name='k34 비ASCII 홈 토큰 경로 → 끝까지 추출 · 그 저장소 4종' why='' u v
  run_module '
home_path_tokens "cat ~/work/트랙/T/src/a.go"' HOME=/h
  if [[ "$RC" -ne 0 ]]; then why="모듈 셸 rc=$RC [$ERR]"
  elif [[ "$(flat "$OUT")" != '/h/work/트랙/T/src/a.go' ]]; then
    why="모듈 판독 [$(flat "$OUT")]"
  fi
  if [[ -z "$why" ]]; then
    slot_fixture || { report "$name" ''; return; }
    u="$C3_S/트랙/U"; v="$u/src/n.go"
    mkdir -p "$u/src" && printf 'k\n' > "$u/src/k.go" && commit_repo "$u" \
      || { report "$name" ''; return; }
    find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
      || { FIXTURE_FAIL='창'; report "$name" ''; return; }
    new_file "$v" || { report "$name" ''; return; }
    local MNA_ENV="HOME=$C3_F"
    run_mna "$C3_R" bash 'printf x > ~/slot/트랙/U/src/n.go'
    why="$(expect_flags "$C3_R" 4 "$v")"
  fi
  report "$name" "$why"
}

k35() { # 홈 토큰 경로도 같은 저장소를 가리키는 토큰 여럿을 뿌리 하나로 센다 — 공유 상한을
        # 먹어 설계물이 무기록이 되거나 상한 알림이 잘못 나면 안 된다(k09 의 홈 토큰 판).
  local name='k35 같은 저장소 홈 토큰 3개 + 작업 공간 설계물 → 기록 · 상한 알림 없음'
  local why='' d
  slot_fixture || { report "$name" ''; return; }
  mkdir -p "$C3_S/_workspace_b" || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  d="$C3_S/_workspace_b/02_design.md"
  new_file "$d" || { report "$name" ''; return; }
  local MNA_ENV="HOME=$C3_F"
  run_mna "$C3_R" bash 'cat ~/slot/T/src/a.go ~/slot/T/src/b.go \
~/slot/T/src/c.go > ~/slot/_workspace_b/02_design.md'
  why="$(expect_flags "$C3_R" 3 "$d")"
  [[ -z "$why" ]] && contains "$OUT" "$TOK_ROOT_CAP" && why="상한 알림 오발 [$OUT]"
  report "$name" "$why"
}

k36() { # 훅 입력의 cwd 가 상대경로(`.`)여도 작업 공간 조상 걸음이 끝난다 — 줄지 않는
        # 문자열을 걸으면 훅이 상한까지 돈다.
  local name='k36 상대 cwd . → 훅이 끝남' why=''
  sweep_fixture || { report "$name" ''; return; }
  local MNA_CWD='.'
  run_mna_bounded 10 "$C3_R" 'ls' bash
  if [[ "$RC" -eq 124 ]]; then why='끝나지 않았다(조상 걸음 무한 반복)'
  elif [[ "$RC" -ne 0 ]]; then why="rc=$RC"
  fi
  report "$name" "$why"
}

k37() { # 알림 표식 쓰기가 EFBIG(ulimit -f 0)로 실패해도 그 줄이 stdout 으로 새지 않는다 —
        # 훅 stdout 은 JSON 한 줄이다(플래그는 이미 있어 그 쓰기는 없다).
  local name='k37 알림 표식 쓰기 EFBIG → stdout JSON 한 줄' why='' p f
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"
  : > "$p/src/a.ts" || { FIXTURE_FAIL='파일'; report "$name" ''; return; }
  for f in audit explain knowledge dualreview; do
    printf 'src/a.ts\n' > "$p/.claude/.needs-$f" \
      || { FIXTURE_FAIL='플래그'; report "$name" ''; return; }
  done
  local MNA_FSIZE0=1
  run_mna "$p" edit "$p/src/a.ts"
  if ! json_message_ok "$MNA_OUT_FILE"; then
    why="JSON 한 줄이 아니다 [$(flat "$OUT")]"
  elif ! contains "$OUT" "$TOK_NOTICE"; then why="알림 없음 [$OUT]"
  fi
  report "$name" "$why"
}

k38() { # 작업 공간 조상 걸음의 대소문자 무시(nocasematch)는 걸음 뒤에 되돌린다 — 새면 뒤의
        # 분류가 대소문자를 무시해 `.CLAUDE/` 를 `.claude/` 처럼 건너뛴다(Edit 판정과 갈린다).
  local name='k38 슬롯 저장소 .CLAUDE/x.go Bash 쓰기 → Edit 와 같은 4종' why='' v
  sweep_fixture || { report "$name" ''; return; }
  v="$C3_T/.CLAUDE/x.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash "printf x > $v"
  why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

k39() { # 기록 줄 상한은 정확히 1023바이트다 — 1023B 줄은 쓰고 1024B 줄은 쓰지 않는다(개행
        # 포함 1024B 가 한 번의 write 로 나가는 최대).
  local name='k39 기록 줄 1023B → 씀 · 1024B → rc 2 · 쓰지 않음' why='' f
  f="$(new_dir k39)" && : > "$f/rec" \
    || { FIXTURE_FAIL='기록 파일'; report "$name" ''; return; }
  run_module '
REVIEW_DIRS_FILE="$FIX/rec"
a="$(printf "%1023s" "" | tr " " a)"; b="$(printf "%1024s" "" | tr " " b)"
append_review_record "$a"; echo "r1023=$?"
append_review_record "$b"; echo "r1024=$?"
echo "bytes=$(wc -c < "$FIX/rec" | tr -d " ")"' FIX="$f"
  if [[ "$RC" -ne 0 ]]; then why="모듈 셸 rc=$RC [$ERR]"
  elif [[ "$(flat "$OUT")" != 'r1023=0 r1024=2 bytes=1024' ]]; then
    why="판독 [$(flat "$OUT")] (기대 r1023=0 r1024=2 bytes=1024)"
  fi
  report "$name" "$why"
}

# --- 종결 r3 — 홈 토큰의 `:` 경계 · 사용자 조회 실패 -------------------------------

#######################################
# 홈 토큰 명령 하나로 슬롯 저장소의 새 파일이 4종인지 본다(세션 루트 cwd · HOME=고정틀).
# Globals:
#   C3_F, C3_R, C3_T (읽음 — sweep_fixture 가 만든 고정틀)
# Arguments:
#   $1 — 케이스 이름, $2 — 명령(`~/slot` · `$HOME/slot` 이 슬롯을 가리킨다)
#######################################
expect_home_colon_4() {
  local name="$1" cmd="$2" why='' v
  sweep_fixture || { report "$name" ''; return; }
  v="$C3_T/src/n.go"
  new_file "$v" || { report "$name" ''; return; }
  local MNA_ENV="HOME=$C3_F"
  run_mna "$C3_R" bash "$cmd"
  why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

k40() { # `:` 는 홈 토큰을 끊는다 — `-v ~/slot/T:/w` 가 `…/T:/w` 한 토큰이 되면 없는
        # 경로라 조상 걸음이 슬롯까지 올라가 저장소 T 를 놓친다(무기록 · 무알림).
  expect_home_colon_4 'k40 docker -v ~/slot/T:/w → T 4종' \
    'docker run --rm -v ~/slot/T:/w img gofmt -w /w'
}

k41() { # `$HOME` 꼴도 같다.
  expect_home_colon_4 'k41 docker -v $HOME/slot/T:/w → T 4종' \
    'docker run --rm -v $HOME/slot/T:/w img gofmt -w /w'
}

k42() { # `~/a:~/b` — `:` 뒤의 `~` 는 단어 머리다. 둘째 저장소 U 도 훑어야 한다.
  local name='k42 X=~/slot/T/src:~/slot/U/src → T · U 4종' why='' u vt vu
  sweep_fixture || { report "$name" ''; return; }
  u="$C3_S/U"
  mkdir -p "$u/src" && printf 'k\n' > "$u/src/k.go" && commit_repo "$u" \
    || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  vt="$C3_T/src/n.go"; vu="$u/src/n.go"
  new_file "$vt" && new_file "$vu" || { report "$name" ''; return; }
  local MNA_ENV="HOME=$C3_F"
  run_mna "$C3_R" bash 'X=~/slot/T/src:~/slot/U/src make gen'
  why="$(expect_flags "$C3_R" 4 "$vt")"
  [[ -n "$why" ]] && why="[T] $why"
  if [[ -z "$why" ]]; then
    why="$(expect_flags "$C3_R" 4 "$vu")"
    [[ -n "$why" ]] && why="[U] $why"
  fi
  report "$name" "$why"
}

k43() { # 사용자 조회를 못 하면(python3 실패) 있다고 본다 — 알리는 쪽이다. 없음으로 보면
        # 있는 사용자의 홈이 조용히 빠진다.
  local name='k43 사용자 조회 실패(python3 심) → rc 3' why='' shim
  shim="$(new_dir pyshim)" && printf '#!/bin/sh\nexit 1\n' > "$shim/python3" \
    && chmod +x "$shim/python3" \
    || { FIXTURE_FAIL='python3 심'; report "$name" ''; return; }
  run_module '
PATH="$SHIM:$PATH"
home_path_tokens "cat ~nouser-k43/a"; echo "r=$?"' HOME=/h SHIM="$shim"
  if [[ "$RC" -ne 0 ]]; then why="모듈 셸 rc=$RC [$ERR]"
  elif [[ "$(flat "$OUT")" != 'r=3' ]]; then why="모듈 판독 [$(flat "$OUT")]"
  fi
  report "$name" "$why"
}
