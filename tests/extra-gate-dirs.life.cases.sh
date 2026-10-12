#!/usr/bin/env bash
# extra-gate-dirs.life.cases.sh — 리뷰 자리 기록의 수명(소속이 바뀔 때 · 결속 순서 · 기록
# 파일 장애)과 발행 가드 ② 의 슬롯 자리 케이스.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice·judge·release 케이스 파일에 있다:
#   stop_fixture · run_stop · dr_flag · rec · review_at · expect_dr_released ·
#   expect_dr_slot_block · env_slot · commit_repo · set_env · edit_new · run_mna ·
#   new_dir · report · contains · is_root · C3_F · C3_R · C3_S · C3_T · TOK_DR_*
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

# 187398c 의 발행 가드 ② 차단 첫 줄(골든 — 기록이 없을 때의 기존 바이트).
TOK_PUB_OLD='[발행 차단] 최근 180분 안의 codex 리뷰 산출물(_workspace/*codex*.md)이 없습니다'
TOK_PUB_SLOT='슬롯 리뷰 자리'                    # 모드일 때만 붙는 문구 조각
TOK_PUB_NOTE='슬롯 리뷰 자리 기록을 읽지 못해'    # 기록을 못 읽었을 때의 사유 한 줄

#######################################
# 발행 가드를 돌린다(발행 도구 이름 · 세션 번호 없음).
# Globals:
#   TMPROOT, BASH (읽음) · ERR, RC, DID_RUN (씀)
# Arguments:
#   $1 — 프로젝트
#######################################
run_pub() {
  local p="$1" errf="$TMPROOT/perr.$$"
  ERR=''; RC=999; DID_RUN=1
  printf '{"tool_name":"mcp__wiki__publish"}' | (cd "$p" && env -u HARNESS_HOOKS \
    -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$p" \
    "$BASH" "$p/.claude/hooks/guard-publish-review.sh" >/dev/null 2>"$errf")
  RC=$?
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$errf"
}

# review_now <폴더> — 지금 시각의 *codex*.md(발행 창 안).
review_now() {
  mkdir -p "$1" && printf 'r\n' > "$1/03_codex_review.md" \
    || { FIXTURE_FAIL="리뷰 $1"; return 1; }
}

# --- x: 수명 · 결속 -----------------------------------------------------------

x1a() { # T/u 파일 편집(T 자리) → git init T/u → 재편집 → 마지막 줄 = U 자리.
        # T 자리 리뷰로 안 풀리고 U 자리 리뷰로 풀린다.
  local name='x1a 소속 변경 뒤 재편집 → T 자리 리뷰 안 풀림 · U 자리로 풀림' why=''
  local u v
  stop_fixture || { report "$name" ''; return; }
  u="$C3_T/u"; v="$u/src/a.go"
  edit_new "$C3_R" "$v" && review_at "$C3_T/_workspace" && commit_repo "$u" \
    || { report "$name" ''; return; }
  run_mna "$C3_R" edit "$v"
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

x1b() { # 슬롯을 S → S2 로 바꿔 값이 슬롯 밖이 된 뒤 재편집 → 빈 집합 줄 → 세션 루트
        # 리뷰로 풀리고 옛 T 자리 리뷰로는 안 풀린다(④ 앵커 — 슬롯 밖에서도 게이트).
  local name='x1b 슬롯 밖이 된 뒤 재편집 → 빈 집합 줄 · 루트 리뷰로만 풀림' why='' a
  stop_fixture || { report "$name" ''; return; }
  a="$C3_T/.claude/hooks/x.sh"
  mkdir -p "$C3_F/slot2" && edit_new "$C3_R" "$a" \
    || { report "$name" ''; return; }
  set_env "$C3_R" "$(env_slot "$C3_F/slot2")"
  run_mna "$C3_R" edit "$a"
  review_at "$C3_T/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$C3_R/_workspace")"
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[루트 리뷰] $why"
  fi
  report "$name" "$why"
}

x1c() { # 소속이 바뀌어도 재편집이 없으면 옛 줄 자리로 풀린다(계약 고정).
  local name='x1c 소속 변경 뒤 재편집 없음 → 옛 T 자리로 풀림' why='' u
  stop_fixture || { report "$name" ''; return; }
  u="$C3_T/u"
  edit_new "$C3_R" "$u/src/a.go" && commit_repo "$u" && review_at "$C3_T/_workspace" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_released "$C3_R")"
  report "$name" "$why"
}

x1d() { # ④ 앵커가 슬롯 범위 변경으로 슬롯 저장소 항목이 됨 → 재편집 → T 자리로만.
  local name='x1d 슬롯 밖 앵커가 슬롯 안이 된 뒤 재편집 → T 자리로만' why='' a
  stop_fixture || { report "$name" ''; return; }
  a="$C3_T/.claude/hooks/x.sh"
  mkdir -p "$C3_F/slot2" || { report "$name" ''; return; }
  set_env "$C3_R" "$(env_slot "$C3_F/slot2")"
  edit_new "$C3_R" "$a" || { report "$name" ''; return; }
  set_env "$C3_R" "$(env_slot "$C3_S")"
  run_mna "$C3_R" edit "$a"
  review_at "$C3_R/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$C3_T/_workspace")"
  if [[ -z "$why" ]]; then
    review_at "$C3_T/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[T 자리 리뷰] $why"
  fi
  report "$name" "$why"
}

#######################################
# x1e 의 touch 심(cc7). 첫 호출에서 진짜 touch 를 한 뒤 기록 파일을 옆으로 비키고 같은
# 이름의 폴더를 만들어, 그 판정의 ③(현재 기록 덧붙이기)을 실패시킨다. 경로는 심 본문에
# 박는다(환경 변수 0). 두 번째 호출부터는 진짜 touch 다.
# Arguments:
#   $1 — 심 폴더, $2 — 기록 파일
#######################################
write_touch_shim() {
  local real
  real="$(command -v touch)" || return 1
  {
    printf '#!/bin/sh\n'
    printf 'if [ ! -e "%s/fired" ]; then\n' "$1"
    printf '  "%s" "$@"; rc=$?\n' "$real"
    printf '  : > "%s/fired"\n' "$1"
    printf '  mv "%s" "%s.aside" && mkdir "%s"\n' "$2" "$2" "$2"
    printf '  exit "$rc"\n'
    printf 'fi\n'
    printf 'exec "%s" "$@"\n' "$real"
  } > "$1/touch" && chmod +x "$1/touch"
}

x1e() { # x1a 의 재편집 때 ③ 만 실패 → 마지막 줄 = 갱신 표시 → T 자리 리뷰로 안 풀리고
        # missing-record. 쓰기를 고친 뒤 다시 저장하면 U 자리로만 풀린다(Y1).
  local name='x1e ③ 만 실패(touch 심) → 갱신 표시 끝줄 · 막음 · 재저장 뒤 U 자리로만'
  local why='' u v shim r
  stop_fixture || { report "$name" ''; return; }
  u="$C3_T/u"; v="$u/src/a.go"; r="$C3_R/.claude/.review-dirs"
  edit_new "$C3_R" "$v" && review_at "$C3_T/_workspace" && commit_repo "$u" \
    && shim="$(new_dir touchshim)" && write_touch_shim "$shim" "$r" \
    || { FIXTURE_FAIL='touch 심'; report "$name" ''; return; }
  (
    PATH="$shim:$PATH"
    run_mna "$C3_R" edit "$v"
  )
  [[ -e "$shim/fired" && -d "$r" ]] \
    || { FIXTURE_FAIL='심이 ③ 을 막지 못했다'; report "$name" ''; return; }
  rmdir "$r" && mv "$r.aside" "$r" || { FIXTURE_FAIL='기록 복원'; report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING" "  - $v")"
  if [[ -z "$why" ]]; then
    run_mna "$C3_R" edit "$v"
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$u/_workspace")"
    [[ -n "$why" ]] && why="[재저장 · T 리뷰만] $why"
  fi
  if [[ -z "$why" ]]; then
    review_at "$u/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[U 자리 리뷰] $why"
  fi
  report "$name" "$why"
}

x1f() { # 기록 파일 자리가 폴더면(파일 종류 장애) record-unusable 로 막는다.
  local name='x1f 기록 파일 → 폴더 → record-unusable 막음' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/x1f.go"
  dr_flag "$C3_R" "$v" && mkdir "$C3_R/.claude/.review-dirs" \
    && review_at "$C3_R/_workspace" && review_at "$C3_T/_workspace" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_UNUSABLE")"
  report "$name" "$why"
}

x1g() { # 병렬 두 판정이 섞인 기록 — ①①③③ 이면 마지막 현재 기록이 정상으로 쓰이고,
        # ①③① (한쪽 사망)이면 끝줄이 갱신 표시라 막는다(안전 쪽).
  local name='x1g 섞인 기록 ①①③③ → 마지막 자리 · ①③① → 막음' why=''
  local v d1 d2
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/x1g.go" d1="$C3_T/_workspace" d2="$C3_S/_workspace_T"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" '!' && rec "$C3_R" "$v" '!' \
    && rec "$C3_R" "$v" "$d1" && rec "$C3_R" "$v" "$d2" && review_at "$d1" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$d2")"
  if [[ -z "$why" ]]; then
    review_at "$d2" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[①①③③ 마지막 자리] $why"
  fi
  if [[ -z "$why" ]]; then
    rm -f "$C3_R/.claude/.review-dirs" && dr_flag "$C3_R" "$v" \
      && rec "$C3_R" "$v" '!' && rec "$C3_R" "$v" "$d1" && rec "$C3_R" "$v" '!' \
      || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING")"
    [[ -n "$why" ]] && why="[①③①] $why"
  fi
  report "$name" "$why"
}

x1h() { # 기록 파일의 쓰기 권한만 빼면 record-unusable 로 막는다(결과를 바꾸는 것은 -w).
        # 권한 제거로만 주입할 수 있어 root 에서는 실패로 보고한다(p44 정책).
  local name='x1h 기록 파일 쓰기 권한만 제거 → record-unusable 막음' why=''
  local v r
  if is_root; then
    DID_RUN=1; FIXTURE_FAIL='root 는 권한 검사를 건너뛴다 — 비root 로 돌려야 판정된다'
    report "$name" ''
    return
  fi
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/x1h.go"
  r="$C3_R/.claude/.review-dirs"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && review_at "$C3_T/_workspace" && chmod a-w "$r" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_UNUSABLE")"
  chmod u+w "$r"
  report "$name" "$why"
}

# --- p: 발행 가드 ② -------------------------------------------------------------

p01() { # 기록이 있고 슬롯이 켜졌으면 ② 는 세션 루트와 기록된 리뷰 자리를 함께 본다.
  local name='p01 기록된 자리의 최근 리뷰만 → 발행 통과(세션 루트 리뷰 없음)' why=''
  stop_fixture || { report "$name" ''; return; }
  rec "$C3_R" "$C3_T/src/p1.go" "$C3_T/_workspace" && review_now "$C3_T/_workspace" \
    || { report "$name" ''; return; }
  run_pub "$C3_R"
  [[ "$RC" -eq 0 ]] || why="rc=$RC (기대 0) [$(flat "$ERR" | head -c 200)]"
  report "$name" "$why"
}

p02() { # 기록이 없으면 기존 바이트(세션 루트만 · 슬롯 문구 없음).
  local name='p02 기록 없음 → 기존 ② (차단 첫 줄 골든 · 루트 리뷰로 통과)' why=''
  stop_fixture || { report "$name" ''; return; }
  review_now "$C3_T/_workspace" || { report "$name" ''; return; }
  run_pub "$C3_R"
  if [[ "$RC" -ne 2 ]]; then why="rc=$RC (기대 2)"
  elif [[ "${ERR%%$'\n'*}" != "$TOK_PUB_OLD"* ]]; then
    why="첫 줄이 기존 ② 가 아니다 [${ERR%%$'\n'*}]"
  elif contains "$ERR" "$TOK_PUB_SLOT"; then why='슬롯 문구가 섞였다'
  fi
  if [[ -z "$why" ]]; then
    review_now "$C3_R/_workspace" || { report "$name" ''; return; }
    run_pub "$C3_R"
    [[ "$RC" -eq 0 ]] || why="[루트 리뷰] rc=$RC"
  fi
  report "$name" "$why"
}

p03() { # 기록이 있는데 모듈이 없으면 세션 루트만 보고(거부 쪽) 사유 한 줄을 낸다.
  local name='p03 기록 + 모듈 없음 → 세션 루트만 · 사유 한 줄' why=''
  stop_fixture || { report "$name" ''; return; }
  rec "$C3_R" "$C3_T/src/p3.go" "$C3_T/_workspace" && review_now "$C3_T/_workspace" \
    && rm -f "$C3_R/.claude/hooks/_extra_gate_dirs.sh" || { report "$name" ''; return; }
  run_pub "$C3_R"
  if [[ "$RC" -ne 2 ]]; then why="rc=$RC (기대 2 — 자리 리뷰로 새면 안 된다)"
  elif ! contains "$ERR" "$TOK_PUB_NOTE"; then why="사유 한 줄 없음 [$(flat "$ERR" | head -c 200)]"
  fi
  if [[ -z "$why" ]]; then
    review_now "$C3_R/_workspace" || { report "$name" ''; return; }
    run_pub "$C3_R"
    [[ "$RC" -eq 0 ]] || why="[루트 리뷰] rc=$RC"
  fi
  report "$name" "$why"
}
