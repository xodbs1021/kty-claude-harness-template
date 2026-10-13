#!/usr/bin/env bash
# extra-gate-dirs.capture.cases.sh — 의무를 잡는 쪽(C1-C4)의 이연 처분 케이스: 기록 줄 길이 ·
# 쌍 뿌리의 삭제 판정 · 같은 뿌리 중복 계수 · 뿌리 중복 제거의 접미 충돌 · 홈 토큰 축소 알림 ·
# 끝 개행 저장소 · 편집 검증 훅 침묵 · 알림 표식(FIFO · 세션 격리) · 메시지 동시 출력.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 envcheck·notice·judge·sweep 케이스 파일에 있다:
#   slot_fixture · sweep_fixture · commit_repo · make_window · set_env · new_file · edit_new
#   new_mna_project · run_mna(MNA_CWD · MNA_SID) · run_env_hook · new_env_project
#   expect_flags · expect_record · record_lines_of · places · new_dir · report · contains · flat
#   C3_F · C3_R · C3_S · C3_T · MNA_PROJ · ENV_PROJ · TOK_NOTICE · TOK_ROOT_CAP ·
#   TOK_RECORD_FAIL · TOK_RECORD_PERM · TOK_SLOT_WARN · GOLDEN_NEWLINE · US
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

TOK_WRITE_FAIL='완료 게이트 플래그를 기록하지 못했다'   # MSG_WRITE_FAIL

#######################################
# 완료 게이트 훅을 시간 상한 안에서 돌린다(끝나지 않는 대기도 적색으로 남긴다). 상한을
# 넘기면 강제로 끝내고 RC=124.
# Globals:
#   TMPROOT, BASH (읽음) · OUT, ERR, RC, DID_RUN (씀)
# Arguments:
#   $1 — 상한(초), $2 — 프로젝트, $3 — 편집 경로
#######################################
run_mna_bounded() {
  local secs="$1" p="$2" payf="$TMPROOT/bpay.$$" outf="$TMPROOT/bout.$$"
  local errf="$TMPROOT/berr.$$" pid ticks=0
  OUT=''; ERR=''; RC=999; DID_RUN=1
  python3 -c 'import json, sys
open(sys.argv[2], "w", encoding="utf-8").write(json.dumps({"tool_input": {"file_path": sys.argv[1]}}))' \
    "$3" "$payf"
  (cd "$p" && exec env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$p" \
    "$BASH" "$p/.claude/hooks/mark-needs-audit.sh" <"$payf" >"$outf" 2>"$errf") &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if ((ticks >= secs * 10)); then
      pkill -9 -P "$pid" 2>/dev/null
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
  rm -f "$payf" "$outf" "$errf"
}

# --- 편집 검증 · 알림 ------------------------------------------------------------

k01() { # `.claude/harness` 가 일반 파일이면 그 아래 harness.env 는 읽을 수 없는 자리다 —
        # 래퍼는 UNTRUSTED 인데 편집 검증 훅이 침묵하면 안 된다(슬롯이 꺼진다고 알린다).
  local name='k01 .claude/harness 가 일반 파일 · harness.env 편집 → 슬롯 경고' why=''
  new_env_project 1 'HARNESS_TYPECHECK_CMD=""'$'\n' || { report "$name" ''; return; }
  rm -f "$ENV_PROJ/.claude/harness/harness.env" && rmdir "$ENV_PROJ/.claude/harness" \
    && printf 'x\n' > "$ENV_PROJ/.claude/harness" \
    || { FIXTURE_FAIL='harness 를 파일로'; report "$name" ''; return; }
  run_env_hook "$ENV_PROJ"
  why="$(env_hook_broken)"
  [[ -z "$why" ]] && ! contains "$OUT" "$TOK_SLOT_WARN" && why="경고 없음 [$OUT]"
  report "$name" "$why"
}

k02() { # 알림 표식 자리가 FIFO 면 읽지도 쓰지도 않는다 — 시간 제한 없는 대기가 생긴다.
        # 표식은 일반 파일만 쓴다(아니면 매번 알린다 — 크게 실패하는 쪽).
  local name='k02 알림 표식이 FIFO → 대기 없이 끝남 · 알림' why=''
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="/nonexistent-k02"'$'\n' \
    && mkfifo "$MNA_PROJ/.claude/.extra-gate-notice" \
    || { FIXTURE_FAIL='FIFO 표식'; report "$name" ''; return; }
  run_mna_bounded 10 "$MNA_PROJ" "$MNA_PROJ/src/k2.go"
  if [[ "$RC" -eq 124 ]]; then why='끝나지 않았다(표식 FIFO 대기)'
  elif [[ "$RC" -ne 0 ]]; then why="rc=$RC"
  elif ! contains "$OUT" "$TOK_NOTICE"; then why="알림 없음 [$OUT]"
  fi
  report "$name" "$why"
}

k03() { # 슬롯 알림과 분기 메시지(개행 경로)가 같은 호출에 나면 둘 다 한 줄에 싣는다.
  local name='k03 슬롯 알림 + 개행 경로 메시지 → 한 줄에 둘 다' why=''
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="/nonexistent-k03"'$'\n' \
    || { report "$name" ''; return; }
  run_mna "$MNA_PROJ" edit "$MNA_PROJ/src/a"$'\n'"b.go"
  if ! contains "$OUT" "$TOK_NOTICE"; then why="알림 없음 [$OUT]"
  elif ! contains "$OUT" "$GOLDEN_NEWLINE"; then why="분기 메시지 없음 [$OUT]"
  elif [[ "$OUT" == *$'\n'* ]]; then why='두 줄이다'
  fi
  report "$name" "$why"
}

k04() { # 알림 표식은 세션마다 따로다 — 한 세션이 알렸다고 다른 세션이 못 받으면 안 된다.
  local name='k04 알림 표식 세션 격리 → 세션 A·B 각각 첫 호출에 알림' why=''
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="/nonexistent-k04"'$'\n' \
    || { report "$name" ''; return; }
  local MNA_SID='k04-session-a'
  run_mna "$MNA_PROJ" edit "$MNA_PROJ/src/k4.go"
  contains "$OUT" "$TOK_NOTICE" || why="[A 첫 호출] 알림 없음"
  if [[ -z "$why" ]]; then
    run_mna "$MNA_PROJ" edit "$MNA_PROJ/src/k4.go"
    [[ -z "$OUT" ]] || why="[A 둘째 호출] 출력이 있다 [$OUT]"
  fi
  if [[ -z "$why" ]]; then
    MNA_SID='k04-session-b'
    run_mna "$MNA_PROJ" edit "$MNA_PROJ/src/k4.go"
    contains "$OUT" "$TOK_NOTICE" || why="[B 첫 호출] 알림 없음 — 표식이 세션을 넘었다"
  fi
  report "$name" "$why"
}

# --- 기록 ----------------------------------------------------------------------

k05() { # 기록 줄은 1023바이트를 넘으면 쓰지 않는다 — bash 3.2 의 printf 는 1024바이트 단위로
        # 나눠 써서 병렬 덧붙이기가 섞이면 다른 저장소 자리로 풀린다. 쓰지 않으면 마지막
        # 줄이 갱신 표시로 남아 막히고(막는 쪽), 영구 문구로 알린다.
  local name='k05 현재 기록 줄 > 1023B → 쓰지 않음 · 갱신 표시 끝줄 · 영구 문구' why=''
  local f s t v a b tails
  f="$(new_dir k05)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  a="$(printf '%200s' '' | tr ' ' a)"; b="$(printf '%200s' '' | tr ' ' b)"
  s="$f/slot"; t="$s/$a/$b/T"; v="$t/src/k5.go"
  mkdir -p "$t/src" && printf 'k\n' > "$t/src/k.go" && commit_repo "$t" \
    && new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$s\""$'\n' \
    || { report "$name" ''; return; }
  edit_new "$MNA_PROJ" "$v" || { report "$name" ''; return; }
  tails="$(record_lines_of "$MNA_PROJ" "$v")"
  if [[ "$tails" != '!' ]]; then why="기록 꼬리 [$(flat "$tails" | head -c 120)] (기대 ! 하나)"
  elif ! contains "$OUT" "$TOK_RECORD_PERM"; then why="영구 문구 없음 [$OUT]"
  fi
  [[ -z "$why" ]] && why="$(expect_flags "$MNA_PROJ" 4 "$v")"
  report "$name" "$why"
}

k06() { # 분기 메시지(플래그 쓰기 실패)와 기록 실패 문구가 같은 호출에 나면 둘 다 싣는다.
  local name='k06 플래그 쓰기 실패 + 기록 실패 → 한 줄에 두 문구' why=''
  slot_fixture || { report "$name" ''; return; }
  mkdir "$C3_R/.claude/.needs-audit" "$C3_R/.claude/.review-dirs" \
    || { FIXTURE_FAIL='쓰기 실패 주입'; report "$name" ''; return; }
  edit_new "$C3_R" "$C3_T/src/k6.go" || { report "$name" ''; return; }
  if ! contains "$OUT" "$TOK_WRITE_FAIL"; then why="플래그 쓰기 실패 문구 없음 [$OUT]"
  elif ! contains "$OUT" "$TOK_RECORD_FAIL"; then why="기록 실패 문구 없음 [$OUT]"
  fi
  report "$name" "$why"
}

k07() { # ① 다른 체크아웃(세션 루트 저장소의 워크트리)이 슬롯 안이면 그 체크아웃 기준
        # 자리다 — 그 _workspace 와 형제 _workspace_<이름>.
  local name='k07 ① 슬롯 안 워크트리 편집 → 그 체크아웃 자리' why='' f s r w v
  f="$(new_dir k07)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  s="$f/slot"; r="$f/R"; w="$s/W"; v="$w/src/k7.go"
  mkdir -p "$r/.claude/hooks" "$r/.claude/harness" "$r/src" "$s" \
    && cp "$COMMON" "$MNA_HOOK" "$MODULE" "$r/.claude/hooks/" \
    && printf 'HARNESS_EXTRA_GATE_DIRS="%s"\n' "$s" > "$r/.claude/harness/harness.env" \
    && printf '.claude/\n' > "$r/.gitignore" && printf 'k\n' > "$r/src/k.go" \
    && commit_repo "$r" && git -C "$r" worktree add -q "$w" 2>/dev/null \
    || { FIXTURE_FAIL='세션 루트 저장소 · 워크트리'; report "$name" ''; return; }
  edit_new "$r" "$v" || { report "$name" ''; return; }
  why="$(expect_flags "$r" 4 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$r" "$v" "$(places "$w/_workspace" "$s/_workspace_W")")"
  report "$name" "$why"
}

# --- 스윕 ----------------------------------------------------------------------

k08() { # 쌍 추론으로만 얻은 저장소 뿌리는 창 기반 find 만 한다 — 창과 무관한 git status
        # 삭제 판정에 다른 트랙의 미커밋 삭제를 이 세션 의무로 올리지 않는다.
  local name='k08 읽기 명령 · 쌍으로만 얻은 U → 창 밖 미커밋 삭제 판정 안 함' why='' u
  slot_fixture || { report "$name" ''; return; }
  u="$C3_S/U"
  mkdir -p "$u/src" "$C3_S/_workspace_U" && printf 'k\n' > "$u/src/del.go" \
    && printf 'k\n' > "$u/src/keep.go" && commit_repo "$u" \
    && printf 'd\n' > "$C3_S/_workspace_U/02_design.md" && rm -f "$u/src/del.go" \
    || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  local -x HOME="$C3_F"
  run_mna "$C3_R" bash 'cat ~/slot/_workspace_U/02_design.md'
  why="$(expect_flags "$C3_R" 0 "$u/src/del.go")"
  report "$name" "$why"
}

k09() { # 같은 저장소를 가리키는 토큰 여럿은 뿌리 하나로 센다 — 공유 상한을 먹어 설계물이
        # 무기록이 되거나 상한 알림이 잘못 나면 안 된다.
  local name='k09 같은 저장소 토큰 3개 + 작업 공간 설계물 → 기록 · 상한 알림 없음' why='' d
  slot_fixture || { report "$name" ''; return; }
  mkdir -p "$C3_S/_workspace_b" || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  d="$C3_S/_workspace_b/02_design.md"
  new_file "$d" || { report "$name" ''; return; }
  run_mna "$C3_R" bash "cat $C3_T/src/a.go $C3_T/src/b.go $C3_T/src/c.go > $d"
  why="$(expect_flags "$C3_R" 3 "$d")"
  [[ -z "$why" ]] && contains "$OUT" "$TOK_ROOT_CAP" && why="상한 알림 오발 [$OUT]"
  report "$name" "$why"
}

k10() { # 홈 토큰을 펼칠 수 없으면(`~사용자` · HOME 없음) 그 뿌리를 못 훑은 것이다 — 알린다.
  local name='k10 펼칠 수 없는 홈 토큰(~사용자) → 부분 알림' why=''
  sweep_fixture || { report "$name" ''; return; }
  run_mna "$C3_R" bash 'cat ~nouser-capture-k10/a.txt'
  contains "$OUT" "$TOK_ROOT_CAP" || why="부분 알림 없음 [$OUT]"
  report "$name" "$why"
}

k11() { # 뿌리 중복 제거는 줄 단위 정확 일치다 — 앞 뿌리의 접미가 뒤 뿌리와 같아도(A = …/z<T>)
        # 뒤 뿌리 T 를 건너뛰지 않는다.
  local name='k11 앞 뿌리가 T 를 접미로 가짐 → T 를 건너뛰지 않음' why='' a v
  sweep_fixture || { report "$name" ''; return; }
  a="$C3_S/z$C3_T"
  mkdir -p "$a/src" && printf 'k\n' > "$a/src/k.go" && commit_repo "$a" \
    || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  local MNA_CWD="$C3_T"
  v="$C3_T/src/k11.go"
  new_file "$v" || { report "$name" ''; return; }
  run_mna "$C3_R" bash "cat $a/src/k.go; printf x > src/k11.go"
  why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

k12() { # 명령문 절대경로가 링크를 지나 끝이 개행인 저장소(S/Q<LF>)를 가리킨다. 최상위를
        # 센티널 없이 받으면 이름이 같은 다른 트랙 S/Q 를 훑는다 — 빼고 알린다.
  local name='k12 절대경로 → 링크 → 끝 개행 저장소 · S/Q 안 훑음 · 알림' why='' q
  slot_fixture || { report "$name" ''; return; }
  q="$C3_S/Q"$'\n'
  mkdir -p "$q/src" "$C3_S/Q/src" && printf 'k\n' > "$q/src/k.go" \
    && printf 'k\n' > "$C3_S/Q/src/k.go" && commit_repo "$q" \
    && commit_repo "$C3_S/Q" && ln -s "$q" "$C3_S/lnk" \
    || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  new_file "$C3_S/Q/src/q.go" && new_file "$q/src/x.go" \
    || { report "$name" ''; return; }
  run_mna "$C3_R" bash "printf x > $C3_S/lnk/src/x.go"
  contains "$OUT" "$TOK_ROOT_CAP" || why="알림 없음 [$OUT]"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 0 "$C3_S/Q/src/q.go")"
  report "$name" "$why"
}
