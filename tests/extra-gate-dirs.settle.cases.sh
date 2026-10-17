#!/usr/bin/env bash
# extra-gate-dirs.settle.cases.sh — 푸는 쪽(Stop 3.5 · 발행 가드 ②)의 이연 처분
# 케이스: 미충족 나열 비용 · 발행 ② 기록 읽기 실패 알림 · 막음 안내 문구(루트
# 경로 문자 · 슬롯 값 검증 실패 · 세션 루트 자리뿐인 막음 · 자리 목록 없는 막음 ·
# 기록 줄 길이 초과 · 큰 본문의 기록 없는 값 나열) · 막음 · 발행 안내가 실제 해제
# 조건과 맞는가(출구 · "위 사유" · 슬롯 문구 · 나열 실패 · 발행 ① ② 의 리뷰 자리) ·
# 종결 전 처분(Bash 스윕의 git 판독 실패 알림 · 평가 실패의 원인별 출구 ·
# root-unusable 의 키 출구 · 중복 제거 실패 나열 · 기록 불가 값의 알림 우선).
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice·judge·capture·release·life·rootchar·sweep 케이스 파일에 있다:
#   stop_fixture · run_stop · run_pub · dr_flag · rec · review_at · review_now
#   expect_dr_released · expect_dr_slot_block · expect_dr_loop_block · env_slot
#   env_untrusted · rootchar_fixture · root_review · new_mna_project
#   commit_repo · set_env · edit_new · new_file · make_window · run_mna
#   expect_flags · record_lines_of · run_common_bounded · new_dir · report
#   contains · flat · MODULE · STOP_HOOK · C3_F · C3_R · C3_S · C3_T · RC_ROOT
#   RC_BASE · MNA_PROJ · TOK_DR_* · TOK_PUB_NOTE · TOK_RECORD_* · ENV_NO_KEY
#   GOLDEN_PARTIAL · T_FLAG · US · OUT · ERR · RC
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

# 막음 안내의 문구 조각(Stop 상수와 대조).
TOK_DR_ASKUSER='사용자에게 알려 판단을 받아라'
TOK_DR_DELKEY='슬롯 키를 지워라'
TOK_DR_UNTRUSTED='harness.env 를 믿고 읽을 수 없'
TOK_DR_BADVALUE='슬롯 값을 쓸 수 없'
TOK_DR_ABOVE="위 '리뷰를 기다리는 자리'"
TOK_DR_MERGE='[cc]/[cx] 태그로 통합'
TOK_DR_TOOLONG='1023바이트를 넘으면 기록할 수 없어'
TOK_DR_NOEXIT_LONG='다시 저장해도 · 저장소를 옮겨도 이번 막음은 풀리지 않는다'
TOK_DR_OLD_MOVE='저장소를 더 짧은 경로로 옮기거나'   # 이번 막음을 풀지 못하는 출구
TOK_DR_PROXY='알림이 나왔으면'                      # 값별이 아닌 대리 조건
TOK_DR_SLOTCLAUSE='슬롯 항목은 세션 루트 _workspace 의 리뷰로 풀리지 않는다'
TOK_DR_ABOVE_REASON='위 사유'
TOK_DR_LISTFAIL='목록을 만들지 못했다'
TOK_DR_NOEXIT_UNREC='다시 저장해도 · 파일 이름을 바꿔도 이번 막음은 풀리지 않는다'
TOK_DR_OLD_RENAME='파일 이름을 바꾸거나'           # 이번 막음을 풀지 못하는 출구
TOK_PUB_PERITEM='항목마다 그 리뷰 자리'
TOK_PUB_SLOTWHERE='또는 슬롯 리뷰 자리의 *codex*.md'
TOK_DR_PLACES='설계 산출물은 그 폴더 하나'   # 기록 줄 구성(자리 수는 항목 꼴마다)
TOK_DR_KIND='일반 파일이 아니거나'           # record-unusable 의 실제 사유(종류 · 권한)
TOK_DR_OLD_PERM='세션 폴더 권한을 고친 뒤'   # 폴더 · FIFO 에는 맞지 않는 옛 출구
TOK_PUB_RECORDED='리뷰 자리가 기록된 슬롯 항목은'
TOK_PUB_OLD_ALL='나열하고, 슬롯 항목은'      # 기록 없는 항목까지 아우르던 옛 문구
TOK_RECORD_GIT='게이트는 섰고 그 값은 턴 종료에서 막힌다'   # 슬롯 git 판독 실패 알림
TOK_GIT_OUTSIDE='앵커 밖 파일에는 게이트가 서지 않았으니'    # 이 값에는 맞지 않는 옛 문구
TOK_DR_GITCHK='그 저장소의 git 판독'         # missing-record 의 확인 대상(쓰기만 아님)
# 187398c 의 발행 ① 2단계 줄(골든 — 키가 없을 때의 기존 바이트).
TOK_PUB_OLD_STEP2='  2. 결과를 _workspace/*codex*.md 로 저장한다 (듀얼리뷰 게이트가 자동 해제된다).'
TOK_DR_MLIST='현재 리뷰 자리 기록이 없는 값:'
TOK_DR_EVALENV='리뷰 자리 판정이 실패했다(환경 장애'   # 판정기를 돌리지 못한 환경 장애
TOK_DR_EVALMOD='리뷰 자리 판정이 실패했다(모듈 오류)'  # 모듈이 망가진 평가 실패
TOK_DR_SYNC='(sync)하라'                               # 다시 설치 출구
TOK_DR_KEYLINE='키 줄을 지우거나 값을 비울지'          # root-unusable 의 키 출구(사용자 판단)
TOK_DR_ENVOK='harness.env 를 정상으로 읽을 수 있을 때만'   # 그 키 출구의 한정어
TOK_DR_OLD_KEYOFF='슬롯 키를 끌지'   # 값만 틀리게 바꾸는 것(그대로 막힘)과 갈리지 않는 옛 문구
# 큰 본문 나열 케이스의 항목 수 — 값마다 300바이트 남짓이라 본문이 파이프 버퍼
# (64 KB)의 몇 배다.
V08_ITEMS=1000
# 미충족 나열 비용 케이스의 항목 수와 시간 상한(초). 항목 수에 이차로 늘던
# 판정은 이 수에서 상한을 크게 넘긴다(macOS bash 3.2 에서 수 분).
V01_ITEMS=10000
V01_LIMIT=20

v01() { # 미충족 항목이 많아도 판정 비용은 항목 수에 선형이다 — 이차면 긴 세션의
        # Stop 이 상한(180 s)에 닿아 훅이 취소된다. 나열은 중복 없이 다 나온다.
  local name="v01 미충족 ${V01_ITEMS} → ${V01_LIMIT} s 안 · M 전부 · W 중복 제거"
  local why='' f r s outf m w
  f="$(new_dir v01)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  r="$f/R"; s="$f/S"; outf="$f/verdict.out"
  mkdir -p "$r/.claude" "$s" \
    || { FIXTURE_FAIL='골격'; report "$name" ''; return; }
  # 홀수 항목은 끝줄이 갱신 표시(M), 짝수 항목은 같은 자리 둘(W 는 둘로 모인다).
  awk -v n="$V01_ITEMS" -v s="$s" 'BEGIN {
      for (i = 1; i <= n; i++) printf "%s/T/src/f%05d.go\n", s, i }' \
    > "$r/.claude/.needs-dualreview" \
    && awk -v us="$US" -v s="$s" '{
        if (NR % 2) print $0 us "!"
        else print $0 us s "/T/_workspace" us s "/_workspace_T" }' \
      "$r/.claude/.needs-dualreview" > "$r/.claude/.review-dirs" \
    || { FIXTURE_FAIL='플래그 · 기록'; report "$name" ''; return; }
  run_common_bounded "$V01_LIMIT" '
. "$MOD" || exit 91
EXTRA_GATE_DIR="$SLOT"
read_review_verdict "$ROOT" > "$OUTF"
echo "rc=$?"' CLAUDE_PROJECT_DIR="$r" MOD="$MODULE" SLOT="$s" ROOT="$r" \
    OUTF="$outf"
  m="$(grep -c '^M ' "$outf" 2>/dev/null)"
  w="$(grep '^W ' "$outf" 2>/dev/null | sort | uniq -c | awk '{print $1}' \
    | tr '\n' ' ')"
  if [[ "$RC" -eq 124 ]]; then why="${V01_LIMIT} s 안에 끝나지 않았다"
  elif [[ "$(flat "$OUT")" != 'rc=3' ]]; then
    why="판정 rc [$(flat "$OUT")] (기대 rc=3) [$ERR]"
  elif [[ "$(head -n 1 "$outf")" != 'missing-record' ]]; then
    why="사유 줄 [$(head -n 1 "$outf")]"
  elif [[ "$m" != "$((V01_ITEMS / 2))" ]]; then why="M 줄 ${m}개"
  elif [[ "$(grep '^M ' "$outf" | sort -u | wc -l | tr -d ' ')" != "$m" ]]; then
    why='M 줄이 겹쳤다'
  elif [[ "$w" != '1 1 ' ]]; then why="W 줄 개수 [$w] (기대 자리 둘이 한 번씩)"
  fi
  report "$name" "$why"
}

v02() { # 발행 ② 가 기록을 읽지 못한 채 세션 루트 리뷰로 통과하면, 슬롯 자리를 보지
        # 못했다는 사유를 알린다(통과는 그대로). 기록을 읽은 통과는 조용하다.
  local name='v02 발행 ② 기록 못 읽음 + 루트 리뷰 → 통과 · 사유 알림' why=''
  stop_fixture || { report "$name" ''; return; }
  rec "$C3_R" "$C3_T/src/v2.go" "$C3_T/_workspace" \
    && review_now "$C3_R/_workspace" \
    && mv "$C3_R/.claude/hooks/_extra_gate_dirs.sh" "$C3_F/module.away" \
    || { report "$name" ''; return; }
  run_pub "$C3_R"
  if [[ "$RC" -ne 0 ]]; then why="rc=$RC (기대 0) [$(flat "$ERR" | head -c 200)]"
  elif ! python3 -c 'import json, sys
d = json.loads(sys.argv[1])
sys.exit(0 if isinstance(d.get("systemMessage"), str) else 1)' "$OUT" \
      2>/dev/null; then why="알림 JSON 한 줄이 아니다 [$OUT]"
  elif ! contains "$OUT" "$TOK_PUB_NOTE"; then why="사유 없음 [$OUT]"
  fi
  if [[ -z "$why" ]]; then
    mv "$C3_F/module.away" "$C3_R/.claude/hooks/_extra_gate_dirs.sh" \
      || { FIXTURE_FAIL='모듈 복구'; report "$name" ''; return; }
    run_pub "$C3_R"
    [[ "$RC" -eq 0 && -z "$OUT" ]] \
      || why="[기록 읽음] rc=$RC 출력 [$OUT] (기대 rc 0 · 무출력)"
  fi
  report "$name" "$why"
}

v03() { # 세션 루트 경로 문자로 판정할 수 없을 때(root-unusable) 슬롯 키 삭제를
        # 에이전트에게 직접 시키지 않는다 — 관할을 끄는 것은 사용자가 정한다. 기다리는
        # 자리 목록이 없으니 "위 자리에 저장" 안내도 내지 않는다.
  local name='v03 root-unusable → 사용자 판단 경유 · 키 삭제 지시 없음 · 위 자리 없음'
  local why=''
  rootchar_fixture mid '' || { report "$name" ''; return; }
  env_slot "$RC_BASE/slot" > "$RC_ROOT/.claude/harness/harness.env"
  dr_flag "$RC_ROOT" 'src/a.go' || { report "$name" ''; return; }
  run_stop "$RC_ROOT"
  why="$(expect_dr_slot_block "$RC_ROOT" "$TOK_DR_ROOTBAD" "$TOK_DR_ASKUSER")"
  if [[ -z "$why" ]]; then
    if contains "$ERR" "$TOK_DR_DELKEY"; then why='슬롯 키 삭제를 직접 지시한다'
    elif contains "$ERR" "$TOK_DR_ABOVE"; then why='자리 목록 없이 위 자리 안내'
    fi
  fi
  report "$name" "$why"
}

v04() { # 슬롯 폴더를 모르는 까닭은 둘이다 — harness.env 를 믿을 수 없음(UNTRUSTED) ·
        # 키 값이 검증에 실패(VALUE, 없는 폴더). dir-unknown 문구가 그 까닭을 맞게 댄다.
  local name='v04 dir-unknown 문구 — 값 검증 실패 · 판독 불가를 가른다' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v4.go"
  set_env "$C3_R" "$(env_slot "$C3_F/no-such-slot")"
  dr_flag "$C3_R" "$v" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_DIRUNK" "$TOK_DR_BADVALUE")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_UNTRUSTED" \
    && why='값 검증 실패를 판독 불가로 안내한다'
  [[ -n "$why" ]] && why="[VALUE 불량] $why"
  if [[ -z "$why" ]]; then
    set_env "$C3_R" "$(env_untrusted "$C3_S")"
    rec "$C3_R" "$C3_T/src/old.go" "$C3_T/_workspace" \
      || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_DIRUNK" "$TOK_DR_UNTRUSTED")"
    [[ -n "$why" ]] && why="[UNTRUSTED] $why"
  fi
  report "$name" "$why"
}

v05() { # 슬롯 판정으로 남은 미충족이 세션 루트 자리뿐이면 기존 막음 문구가 사실이다
        # — 슬롯 문구 없이 세션 루트 _workspace 와 [cc]/[cx] 통합을 안내한다.
  local name='v05 VALUE · 루트 항목만 남음 → 기존 막음 문구([cc]/[cx] 통합)' why=''
  stop_fixture || { report "$name" ''; return; }
  dr_flag "$C3_R" 'src/v5.go' || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_loop_block "$C3_R")"
  [[ -z "$why" ]] && ! contains "$ERR" "$TOK_DR_MERGE" && why='통합 지시 없음'
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[루트 리뷰] $why"
  fi
  report "$name" "$why"
}

v06() { # 기다리는 자리 목록이 없는 막음(missing-record 뿐)은 "위 자리에 저장" 을
        # 안내하지 않는다. 목록이 있으면 그 자리 저장과 [cc]/[cx] 통합을 안내한다.
  local name='v06 자리 목록 없음 → 위 자리 안내 없음 · 있음 → 위 자리 + 통합' why=''
  local v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v6.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" '!' || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_ABOVE" && why='목록 없이 위 자리 안내'
  [[ -n "$why" ]] && why="[목록 없음] $why"
  if [[ -z "$why" ]]; then
    rec "$C3_R" "$v" "$C3_T/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "  - $C3_T/_workspace" "$TOK_DR_ABOVE" \
      "$TOK_DR_MERGE")"
    [[ -n "$why" ]] && why="[목록 있음] $why"
  fi
  report "$name" "$why"
}

#######################################
# 기록 줄이 1023바이트를 넘는 슬롯 저장소(slot/<a×200>/<b×200>/T)를 커밋하고 Stop ·
# 완료 게이트 훅이 깔린 프로젝트를 만든 뒤 그 저장소의 새 파일을 한 번 편집한다.
# Globals:
#   STOP_HOOK (읽음) · LP_S, LP_T, LP_V, LP_EDIT_OUT(첫 편집의 훅 출력), MNA_PROJ,
#   FIXTURE_FAIL (씀)
# Arguments:
#   $1 — 고정틀 이름
# Returns:
#   0 · 1 고정틀 실패(FIXTURE_FAIL)
#######################################
long_path_project() {
  local f a b
  f="$(new_dir "$1")" || { FIXTURE_FAIL='임시 디렉토리'; return 1; }
  a="$(printf '%200s' '' | tr ' ' a)"; b="$(printf '%200s' '' | tr ' ' b)"
  LP_S="$f/slot"; LP_T="$LP_S/$a/$b/T"; LP_V="$LP_T/src/v7.go"
  mkdir -p "$LP_T/src" && printf 'k\n' > "$LP_T/src/k.go" \
    && commit_repo "$LP_T" \
    && new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$LP_S\""$'\n' \
    && cp "$STOP_HOOK" "$MNA_PROJ/.claude/hooks/" \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-고정틀}"; return 1; }
  edit_new "$MNA_PROJ" "$LP_V" || return 1
  LP_EDIT_OUT="$OUT"
  if [[ "$(record_lines_of "$MNA_PROJ" "$LP_V")" != '!' ]]; then
    FIXTURE_FAIL='끝줄이 갱신 표시가 아니다'
    return 1
  fi
}

v07() { # 기록 줄이 1023바이트를 넘어 현재 기록을 못 쓴 값(영구)은 다시 저장해도
        # 기록되지 않는다 — Stop 이 "다시 저장하면 기록된다" 로만 안내하면 회복되지 않는
        # 길로 보낸다. 그 값의 조건(기록 줄 길이)과 사용자 판단 출구를 함께 안내하고,
        # 이번 막음을 풀지 못하는 출구(저장소 이동)나 값별이 아닌 대리 조건(저장 때
        # 알림)에 기대지 않는다.
  local name='v07 기록 줄 1023B 초과 값 → 다시 저장 · 이동으로 안 풀림 · 사용자 판단'
  local why=''
  long_path_project v07 || { report "$name" ''; return; }
  run_stop "$MNA_PROJ"
  why="$(expect_dr_slot_block "$MNA_PROJ" "$TOK_DR_MISSING" "$TOK_DR_TOOLONG" \
    "$TOK_DR_NOEXIT_LONG" "$TOK_DR_ASKUSER" "$TOK_DR_PLACES" "  - $LP_V")"
  if [[ -z "$why" ]]; then
    if contains "$ERR" "$TOK_DR_OLD_MOVE"; then why='저장소 이동을 출구로 안내한다'
    elif contains "$ERR" "$TOK_DR_PROXY"; then why='저장 때 알림에 기댄 조건'
    fi
  fi
  report "$name" "$why"
}

v08() { # 기록 없는 값(M) 나열은 본문이 파이프 버퍼보다 커도 빠지지 않는다 — 판정을
        # `printf | grep -q` 로 하면 grep 이 첫 일치에서 닫아 printf 가 SIGPIPE 로
        # 죽고(pipefail) 절이 조용히 사라진다. 막음 · 사유는 그대로다.
  local name="v08 끝줄 갱신 표시 ${V08_ITEMS}개(큰 본문) → 기록 없는 값 절 · 끝 값까지"
  local why='' a b d last n
  stop_fixture || { report "$name" ''; return; }
  a="$(printf '%100s' '' | tr ' ' a)"; b="$(printf '%100s' '' | tr ' ' b)"
  d="$C3_T/src/$a/$b"
  awk -v n="$V08_ITEMS" -v d="$d" 'BEGIN {
      for (i = 1; i <= n; i++) printf "%s/f%05d.go\n", d, i }' \
    > "$C3_R/.claude/.needs-dualreview" \
    && awk -v us="$US" '{ print $0 us "!" }' "$C3_R/.claude/.needs-dualreview" \
      > "$C3_R/.claude/.review-dirs" \
    && touch -t "$T_FLAG" "$C3_R/.claude/.needs-dualreview" \
    || { FIXTURE_FAIL='플래그 · 기록'; report "$name" ''; return; }
  last="$(printf '%s/f%05d.go' "$d" "$V08_ITEMS")"
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING")"
  if [[ -z "$why" ]]; then
    n="$(printf '%s\n' "$ERR" | grep -cxF -- "  - $last")"
    if ! contains "$ERR" "$TOK_DR_MLIST"; then why='기록 없는 값 절이 빠졌다'
    elif [[ "$n" != 2 ]]; then why="끝 값 나열 ${n}번(기대 2 — 대상 · 기록 없는 값)"
    fi
  fi
  report "$name" "$why"
}

v09() { # 저장소를 더 짧은 경로로 옮겨 다시 저장하고 모든 자리에 리뷰를 둬도 옛 값은
        # 같은 값의 새 기록 줄이 없어 missing-record 로 남는다 — 이번 막음의 출구가
        # 아니다(저장 때 알림 · Stop 안내가 모두 그렇게 말해야 한다).
  local name='v09 1023B 초과 값 → 저장소를 옮겨 다시 저장 · 세 자리 리뷰 → 여전히 막음'
  local why='' t2 v2
  long_path_project v09 || { report "$name" ''; return; }
  t2="$LP_S/T2"; v2="$t2/src/v7.go"
  if ! contains "$LP_EDIT_OUT" "$TOK_RECORD_NOEXIT"; then
    why="[저장 알림] 이번 막음이 풀리지 않는다는 안내 없음 [$LP_EDIT_OUT]"
  elif contains "$LP_EDIT_OUT" "$TOK_RECORD_OLDEXIT"; then
    why='[저장 알림] 이번 막음을 풀지 못하는 출구(이름 · 위치 바꾸기)를 안내한다'
  fi
  [[ -n "$why" ]] && { report "$name" "$why"; return; }
  mv "$LP_T" "$t2" || { FIXTURE_FAIL='저장소 이동'; report "$name" ''; return; }
  run_mna "$MNA_PROJ" edit "$v2"
  contains "$OUT" "$TOK_RECORD_PERM" && why='[옮긴 뒤 저장] 영구 알림이 또 나왔다'
  review_at "$t2/_workspace" && review_at "$LP_S/_workspace_T2" \
    && review_at "$MNA_PROJ/_workspace" || { report "$name" ''; return; }
  run_stop "$MNA_PROJ"
  [[ -z "$why" ]] && why="$(expect_dr_slot_block "$MNA_PROJ" "$TOK_DR_MISSING" \
    "$TOK_DR_NOEXIT_LONG" "  - $LP_V")"
  report "$name" "$why"
}

v10() { # 슬롯 값 검증 실패(dir-unknown)로 기록 없는 절대 항목이 세션 루트 규칙이 되면
        # 세션 루트 리뷰로 풀린다 — 막음 안내가 "슬롯 항목은 세션 루트 리뷰로 풀리지
        # 않는다" · "위 사유를 해결하고" 라고 하면 사실이 아니다(dir-unknown 은 판정
        # 방식을 알리는 사유라 풀기 조건이 아니다).
  local name='v10 dir-unknown · 루트 자리뿐 → 슬롯 문구 · 위 사유 없음 · 루트 리뷰로 해제'
  local why=''
  stop_fixture || { report "$name" ''; return; }
  set_env "$C3_R" "$(env_slot "$C3_F/no-such-slot")"
  dr_flag "$C3_R" "$C3_T/src/v10.go" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_DIRUNK" "$TOK_DR_ABOVE" \
    "  - $C3_R/_workspace")"
  if [[ -z "$why" ]]; then
    if contains "$ERR" "$TOK_DR_SLOTCLAUSE"; then why='슬롯 문구가 나왔다'
    elif contains "$ERR" "$TOK_DR_ABOVE_REASON"; then why='위 사유 안내가 나왔다'
    fi
  fi
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[루트 리뷰] $why"
  fi
  report "$name" "$why"
}

v11() { # 나열의 중복 제거가 실패해도(awk 심) 자리 목록은 중복 제거 없이 그대로 나온다
        # — 목록이 비면 저장할 자리도, "위 사유를 먼저 해결하면" 이 가리킬 사유도 없다.
        # 두 값이 같은 자리를 기다리게 해, 그 자리가 두 번 나오면 중복 제거 없는 목록이다.
        # 막음은 그대로이고, 나열된 자리에 리뷰를 두면(awk 가 여전히 실패해도) 풀린다.
  local name='v11 중복 제거 awk 실패 → 중복 제거 없는 목록 · 위 사유 없음 · 그 자리 리뷰로 해제'
  local why='' v w shim real n
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v11.go"; w="$C3_T/src/v11b.go"
  real="$(command -v awk)"
  shim="$(new_dir awkshim)" \
    && printf '#!/bin/sh\n[ "$1" = %s ] && exit 2\nexec %s "$@"\n' \
      "'!seen[\$0]++'" "$real" > "$shim/awk" && chmod +x "$shim/awk" \
    && dr_flag "$C3_R" "$v" "$w" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && rec "$C3_R" "$w" "$C3_T/_workspace" \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-awk 심}"; report "$name" ''; return; }
  local -x PATH="$shim:$PATH"
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_ABOVE")"
  if [[ -z "$why" ]]; then
    n="$(printf '%s\n' "$ERR" | grep -cxF -- "  - $C3_T/_workspace")"
    if [[ "$n" != 2 ]]; then why="자리 나열 ${n}번(기대 2 — 중복 제거 없는 목록)"
    elif contains "$ERR" "$TOK_DR_ABOVE_REASON"; then why='위 사유 안내가 나왔다'
    elif contains "$ERR" "$TOK_DR_LISTFAIL"; then why='목록을 버리고 나열 실패로 안내한다'
    fi
  fi
  if [[ -z "$why" ]]; then
    review_at "$C3_T/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[나열된 자리 리뷰] $why"
  fi
  report "$name" "$why"
}

v12() { # 기다리는 자리만 있고 사유가 없는 막음은 "위 사유를 해결하고" 가 가리킬 것이
        # 없다 — 그 자리에 저장하면 풀린다고만 안내한다.
  local name='v12 슬롯 자리만 · 사유 없음 → 위 사유 없음 · 슬롯 문구 있음' why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v12.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_ABOVE" "$TOK_DR_SLOTCLAUSE" \
    "  - $C3_T/_workspace")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_ABOVE_REASON" \
    && why='위 사유 안내가 나왔다'
  report "$name" "$why"
}

v13() { # 경로에 US 가 든 값(unrecordable)은 파일 이름을 바꿔 새 경로를 저장해도 옛 값이
        # 남아 막음이 풀리지 않는다 — 이름 바꾸기를 출구로 안내하지 않는다.
  local name='v13 unrecordable → 이름을 바꿔 저장 · 자리 리뷰 → 여전히 막음 · 출구 문구'
  local why='' v v2
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/a${US}b.go"; v2="$C3_T/src/ab.go"
  edit_new "$C3_R" "$v" && mv "$v" "$v2" || { report "$name" ''; return; }
  run_mna "$C3_R" edit "$v2"
  review_at "$C3_T/_workspace" && review_at "$C3_S/_workspace_T" \
    && review_at "$C3_R/_workspace" || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_UNREC" "$TOK_DR_NOEXIT_UNREC")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_OLD_RENAME" \
    && why='이름 바꾸기를 출구로 안내한다'
  report "$name" "$why"
}

v14() { # 발행 ① (듀얼리뷰 미해소)의 저장 안내 — 슬롯 모드에서 "_workspace 또는 슬롯
        # 자리에 저장하면 자동 해제" 는 사실이 아니다(슬롯 항목은 그 자리에서만 풀린다).
        # 키가 없으면 기존 줄 바이트 그대로다. 기록 파일이 없어도 키에 값이 있으면(세션
        # 중에 키를 켬 · 첫 값이 기록 불가) Stop 이 슬롯 판정으로 막으니 기존 줄도 거짓이다.
        # harness.env 를 믿을 수 없고 기록 파일이 없으면 Stop 은 기존 루프라 기존 줄이 맞다.
  local name='v14 발행 ① 슬롯 모드 · 기록 없는 값 → 항목마다 그 자리 안내 · 키 부재 → 기존 줄'
  local why=''
  local v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v14.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    || { report "$name" ''; return; }
  run_pub "$C3_R"
  if [[ "$RC" -ne 2 ]]; then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_PUB_PERITEM"; then
    why="항목별 자리 안내 없음 [$(flat "$ERR" | head -c 200)]"
  elif contains "$ERR" "$TOK_PUB_SLOTWHERE 로 저장한다 (듀얼리뷰"; then
    why='또는 자리 저장으로 자동 해제라고 안내한다'
  fi
  if [[ -z "$why" ]]; then
    set_env "$C3_R" "$ENV_NO_KEY"
    run_pub "$C3_R"
    if ! printf '%s\n' "$ERR" | grep -qxF -- "$TOK_PUB_OLD_STEP2"; then
      why='[키 부재] 기존 2단계 줄이 아니다'
    elif contains "$ERR" "$TOK_PUB_PERITEM"; then why='[키 부재] 슬롯 안내가 섞였다'
    fi
  fi
  if [[ -z "$why" ]]; then
    set_env "$C3_R" "$(env_slot "$C3_S")"
    rm -f "$C3_R/.claude/.review-dirs"
    run_pub "$C3_R"
    if [[ "$RC" -ne 2 ]]; then why="[기록 없음 · 값] rc=$RC (기대 2)"
    elif printf '%s\n' "$ERR" | grep -qxF -- "$TOK_PUB_OLD_STEP2"; then
      why='[기록 없음 · 값] 세션 루트 저장으로 해제된다는 기존 줄'
    elif ! contains "$ERR" "$TOK_PUB_PERITEM"; then
      why='[기록 없음 · 값] 항목별 자리 안내 없음'
    fi
  fi
  # 기존 줄이 거짓인가 — 세션 루트 리뷰를 둬도 Stop 이 슬롯 판정으로 막는다.
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING")"
    [[ -n "$why" ]] && why="[기록 없음 · 값 · Stop] $why"
  fi
  if [[ -z "$why" ]]; then
    set_env "$C3_R" "$(env_untrusted "$C3_S")"
    run_pub "$C3_R"
    printf '%s\n' "$ERR" | grep -qxF -- "$TOK_PUB_OLD_STEP2" \
      || why='[기록 없음 · 믿을 수 없음] 기존 루프인데 기존 줄이 아니다'
  fi
  report "$name" "$why"
}

v15() { # 발행 ② 가 기록을 읽지 못하면(모듈 없음) 세션 루트만 본다 — 차단 안내가 "또는
        # 슬롯 리뷰 자리" 에 저장하라고 하면 그 자리 리뷰로는 통과하지 못한다. 기록을
        # 읽었어도 자리 목록이 비면(갱신 표시 · 빈 집합 줄뿐 — 슬롯 밖 앵커의 정상 편집)
        # 볼 슬롯 자리가 없으니 같다.
  local name='v15 발행 ② 기록 못 읽음 · 자리 목록 빔 → 안내는 세션 루트만 · 못 읽음만 사유'
  local why=''
  stop_fixture || { report "$name" ''; return; }
  rec "$C3_R" "$C3_T/src/v15a.go" '!' && rec "$C3_R" "$C3_T/src/v15b.go" '-' \
    || { report "$name" ''; return; }
  run_pub "$C3_R"
  if [[ "$RC" -ne 2 ]]; then why="[자리 목록 빔] rc=$RC (기대 2)"
  elif contains "$ERR" "$TOK_PUB_SLOTWHERE"; then
    why='[자리 목록 빔] 없는 슬롯 자리에 저장하라고 안내한다'
  elif contains "$ERR" "$TOK_PUB_NOTE"; then why='[자리 목록 빔] 못 읽음 사유가 나왔다'
  fi
  [[ -n "$why" ]] && { report "$name" "$why"; return; }
  rec "$C3_R" "$C3_T/src/v15.go" "$C3_T/_workspace" \
    && rm -f "$C3_R/.claude/hooks/_extra_gate_dirs.sh" \
    || { report "$name" ''; return; }
  run_pub "$C3_R"
  if [[ "$RC" -ne 2 ]]; then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_PUB_NOTE"; then why='사유 한 줄 없음'
  elif contains "$ERR" "$TOK_PUB_SLOTWHERE"; then
    why='읽지 못한 슬롯 자리에 저장하라고 안내한다'
  fi
  report "$name" "$why"
}

v16() { # 기록 파일 자리가 폴더(· FIFO · 끊긴 링크)면 권한을 고쳐도 풀리지 않는다 —
        # record-unusable 안내가 실제 사유(일반 파일 아님 · 권한)를 대고 그것을 고치게 한다.
  local name='v16 기록 자리가 폴더 → record-unusable 사유에 파일 종류 · 그 출구로 해제'
  local why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v16.go"
  dr_flag "$C3_R" "$v" && mkdir "$C3_R/.claude/.review-dirs" \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_UNUSABLE" "$TOK_DR_KIND")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_OLD_PERM" \
    && why='권한만 고치라고 안내한다'
  # 안내한 출구가 실제로 푸는지: 일반 파일이 되게 고치고(폴더를 치움) 다시 저장 → 자리 리뷰.
  if [[ -z "$why" ]]; then
    rmdir "$C3_R/.claude/.review-dirs" && : > "$v" \
      || { FIXTURE_FAIL='기록 자리 복구'; report "$name" ''; return; }
    run_mna "$C3_R" edit "$v"
    review_at "$C3_T/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[고친 뒤 다시 저장] $why"
  fi
  report "$name" "$why"
}

v17() { # 발행 ① 슬롯 모드 안내 — harness.env 를 믿을 수 없거나(UNTRUSTED) 값이 검증에
        # 실패하면 기록 없는 절대 항목은 세션 루트 리뷰로 풀린다. "슬롯 항목은 세션 루트
        # 리뷰로 풀리지 않는다" 는 리뷰 자리가 기록된 항목에만 맞다.
  local name='v17 발행 ① UNTRUSTED → 기록된 슬롯 항목만 세션 루트로 안 풀린다고 안내'
  local why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v17.go"
  set_env "$C3_R" "$(env_untrusted "$C3_S")"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$C3_T/src/old.go" "$C3_T/_workspace" \
    || { report "$name" ''; return; }
  run_pub "$C3_R"
  if [[ "$RC" -ne 2 ]]; then why="rc=$RC (기대 2)"
  elif ! contains "$ERR" "$TOK_PUB_RECORDED"; then
    why="기록된 항목으로 좁힌 안내 없음 [$(flat "$ERR" | head -c 200)]"
  elif contains "$ERR" "$TOK_PUB_OLD_ALL"; then why='모든 슬롯 항목이라고 안내한다'
  fi
  report "$name" "$why"
}

# v18_stop <로케일> <프로젝트> — 그 로케일로만 Stop 을 돌린다(판정 문자열 비교는 밖에서).
v18_stop() {
  local -x LC_ALL="$1"
  run_stop "$2"
}

v18() { # 막음 안내의 슬롯 자리 가르기는 로케일에 기대지 않는다 — UTF-8 로케일의 GNU
        # grep 은 잘못된 UTF-8 바이트가 든 자리 줄을 이진으로 보고 줄을 내지 않으며
        # "binary file matches" 를 stderr(막음 안내)에 섞는다. 자리 경로는 바이트열이다.
  local name='v18 자리 경로에 잘못된 UTF-8 · UTF-8 로케일 → 슬롯 문구 · 이진 경고 없음'
  local why='' v d loc
  loc="$(locale -a 2>/dev/null | grep -iE '^(c\.utf-?8|en_us\.utf-?8)$' \
    | head -n 1)"
  [[ -n "$loc" ]] || { FIXTURE_FAIL='UTF-8 로케일 없음'; report "$name" ''; return; }
  stop_fixture || { report "$name" ''; return; }
  d="$C3_S/T"$'\377'"x"
  v="$d/src/v18.go"
  dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$d/_workspace" \
    || { report "$name" ''; return; }
  v18_stop "$loc" "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_SLOTCLAUSE" "  - $d/_workspace")"
  if [[ -z "$why" ]] && printf '%s\n' "$ERR" | grep -qi 'binary file'; then
    why='이진 파일 경고가 안내에 섞였다'
  fi
  report "$name" "$why"
}

v19() { # 슬롯 안 ④ 앵커의 저장소를 git 이 돌려주지 못하면 리뷰 자리를 정하지 못해 현재
        # 기록을 쓰지 않는다 — 게이트는 섰고 턴 종료에서 막힌다. 저장 알림이 "앵커 밖
        # 파일에는 게이트가 서지 않았다" 로 끝나면 이 값의 막음을 숨기고, Stop 안내가
        # "세션 폴더 쓰기" 만 확인하라 하면 git 이 고쳐지기 전 다시 저장으로는 안 풀린다.
  local name='v19 슬롯 ④ 앵커 · git 판독 실패 → 알림 · Stop 이 git 을 짚음 · 그 출구로 해제'
  local why='' u v
  stop_fixture || { report "$name" ''; return; }
  u="$C3_S/U"
  mkdir -p "$u/.claude/hooks" \
    && printf 'gitdir: %s\n' "$C3_S/nowhere" > "$u/.git" \
    || { FIXTURE_FAIL='깨진 .git'; report "$name" ''; return; }
  v="$u/.claude/hooks/x.sh"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  if ! contains "$OUT" "$TOK_RECORD_GIT"; then
    why="[저장 알림] 막힘 · git 을 짚는 안내 없음 [$OUT]"
  elif contains "$OUT" "$TOK_GIT_OUTSIDE"; then
    why='[저장 알림] 앵커 밖 파일 문구로 이 값의 막음을 숨긴다'
  fi
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING" "$TOK_DR_GITCHK" \
      "  - $v")"
    [[ -n "$why" ]] && why="[Stop] $why"
  fi
  # 안내한 출구가 실제로 푸는지: git 이 저장소를 읽게 된 뒤 다시 저장 → 그 자리 리뷰로 해제.
  if [[ -z "$why" ]]; then
    rm -f "$u/.git" && git -C "$u" init -q \
      || { FIXTURE_FAIL='.git 복구'; report "$name" ''; return; }
    run_mna "$C3_R" edit "$v"
    review_at "$u/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[git 복구 뒤 다시 저장] $why"
  fi
  report "$name" "$why"
}

v20() { # 슬롯이 꺼진 동안의 missing-record 출구("harness.env 를 정상으로 읽을 수 있게 고친
        # 뒤")가 실제로 푼다 — harness.env 를 고치고 값을 다시 저장하면 그 자리 리뷰로
        # 풀린다.
  local name='v20 슬롯 꺼짐(판독 불가) missing-record → harness.env 고치고 다시 저장 → 해제'
  local why='' v
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v20.go"
  set_env "$C3_R" "$(env_untrusted "$C3_S")"
  : > "$v" && dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" '!' \
    || { report "$name" ''; return; }
  run_stop "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING" "$TOK_DR_FIXENV")"
  if [[ -z "$why" ]]; then
    set_env "$C3_R" "$(env_slot "$C3_S")"
    run_mna "$C3_R" edit "$v"
    review_at "$C3_T/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[harness.env 고친 뒤 다시 저장] $why"
  fi
  report "$name" "$why"
}

# --- 종결 전 처분: 알림 · 출구가 실제 사유 · 해제 조건과 맞는가 -------------------

# broken_git_repo <폴더> — git 이 읽지 못하는 저장소(.git 이 없는 곳을 가리킨다)와 그
# 안의 .claude/hooks 를 만든다. 그 앵커 파일은 ④ 로 게이트가 서지만 소속을 모른다.
broken_git_repo() {
  mkdir -p "$1/.claude/hooks" \
    && printf 'gitdir: %s\n' "$C3_S/nowhere" > "$1/.git" \
    || { FIXTURE_FAIL='깨진 .git'; return 1; }
}

v21() { # Bash 스윕에서도 슬롯 ④ 앵커의 git 판독 실패 알림은 그 사유로 나간다 — 스윕
        # 집계의 부분 기록 문구("일부는 게이트에 기록하지 못했다")로 접히면 게이트가
        # 섰다는 것과 턴 종료에서 막힌다는 것이 숨는다. 알림대로 막히고, 알림의
        # 출구(git 을 고친 뒤 다시 저장)가 실제로 푼다.
  local name='v21 Bash 스윕 · 슬롯 ④ git 판독 실패 → git 알림 · 막음 · 그 출구로 해제'
  local why='' u v
  stop_fixture || { report "$name" ''; return; }
  u="$C3_T/U"
  broken_git_repo "$u" \
    && find "$C3_F" -exec touch -t 201901010000 {} + && make_window "$C3_R" \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-창}"; report "$name" ''; return; }
  v="$u/.claude/hooks/x.sh"
  new_file "$v" || { report "$name" ''; return; }
  local MNA_CWD="$C3_T"
  run_mna "$C3_R" bash 'touch U/.claude/hooks/x.sh'
  if ! contains "$OUT" "$TOK_RECORD_GIT"; then
    why="[스윕 알림] 막힘 · git 을 짚는 안내 없음 [$OUT]"
  elif contains "$OUT" "$GOLDEN_PARTIAL"; then
    why='[스윕 알림] 부분 기록 문구로 접혔다'
  fi
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$v")"
  [[ -z "$why" && "$(record_lines_of "$C3_R" "$v")" != '!' ]] \
    && why="끝줄이 갱신 표시가 아니다 [$(flat "$(record_lines_of "$C3_R" "$v")")]"
  # 알림의 "턴 종료에서 막힌다" 가 사실인가 — 세션 루트 리뷰가 있어도 막는다.
  if [[ -z "$why" ]]; then
    review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_MISSING" "  - $v")"
    [[ -n "$why" ]] && why="[Stop] $why"
  fi
  # 알림의 출구: git 이 그 저장소를 읽게 된 뒤 다시 저장 → 그 자리 리뷰로 해제.
  if [[ -z "$why" ]]; then
    rm -f "$u/.git" && git -C "$u" init -q \
      || { FIXTURE_FAIL='.git 복구'; report "$name" ''; return; }
    run_mna "$C3_R" edit "$v"
    review_at "$u/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[git 복구 뒤 다시 저장] $why"
  fi
  report "$name" "$why"
}

# v22_stop_shim <심 폴더> <프로젝트> — 심을 PATH 앞에 둔 채로만 Stop 을 돌린다.
v22_stop_shim() {
  local -x PATH="$1:$PATH"
  run_stop "$2"
}

v22() { # 평가 실패의 출구는 원인마다 다르다. 판정기(awk)가 돌지 못한 환경 장애는 다시
        # 설치로 풀리지 않으니 sync 가 아니라 사용자 판단을 안내하고, 장애가 걷히면 같은
        # 리뷰로 풀린다. 모듈이 망가진 평가 실패(사망 주입)는 sync 를 안내하고, 모듈을
        # 되돌리면(sync 가 하는 일) 풀린다.
  local name='v22 평가 실패 — awk 실패 → 사용자 판단 · sync 아님 / 모듈 오류 → sync'
  local why='' v m shim real
  stop_fixture || { report "$name" ''; return; }
  v="$C3_T/src/v22.go"
  m="$C3_R/.claude/hooks/_extra_gate_dirs.sh"
  real="$(command -v awk)"
  shim="$(new_dir verdictawk)" \
    && printf '#!/bin/sh\n[ "$2" = mode=verdict ] && exit 2\nexec %s "$@"\n' \
      "$real" > "$shim/awk" && chmod +x "$shim/awk" \
    && dr_flag "$C3_R" "$v" && rec "$C3_R" "$v" "$C3_T/_workspace" \
    && review_at "$C3_T/_workspace" \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-awk 심}"; report "$name" ''; return; }
  v22_stop_shim "$shim" "$C3_R"
  why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_EVALENV" "$TOK_DR_ASKUSER")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_SYNC" \
    && why='환경 장애에 sync 를 안내한다'
  [[ -n "$why" ]] && why="[awk 실패] $why"
  if [[ -z "$why" ]]; then
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[장애가 걷힌 뒤] $why"
  fi
  if [[ -z "$why" ]]; then
    dr_flag "$C3_R" "$v" \
      && printf '%s\n' \
        'read_review_verdict() { : "$V22_UNSET_VARIABLE"; }' >> "$m" \
      || { FIXTURE_FAIL='사망 주입'; report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_EVALMOD" "$TOK_DR_SYNC")"
    [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_EVALENV" \
      && why='모듈 오류를 환경 장애로 안내한다'
    [[ -n "$why" ]] && why="[모듈 오류] $why"
  fi
  if [[ -z "$why" ]]; then
    cp "$MODULE" "$m" || { FIXTURE_FAIL='모듈 복구'; report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_released "$C3_R")"
    [[ -n "$why" ]] && why="[모듈을 되돌린 뒤] $why"
  fi
  report "$name" "$why"
}

v23() { # root-unusable 의 키 출구는 실제로 푸는 것만 말한다 — 키 줄을 지우거나 값을
        # 비우면(키 없음) 세션 루트 리뷰로 풀리고, 값만 틀리게 바꾸면(슬롯 꺼짐)
        # 그대로 막힌다. "슬롯 키를 끌지" 는 이 둘을 가르지 않았다.
  local name='v23 root-unusable → 키 줄 삭제 · 빈 값은 루트 리뷰로 해제 · 틀린 값은 막음'
  local why='' env
  rootchar_fixture mid '' || { report "$name" ''; return; }
  env="$RC_ROOT/.claude/harness/harness.env"
  env_slot "$RC_BASE/slot" > "$env" && dr_flag "$RC_ROOT" 'src/a.go' \
    || { report "$name" ''; return; }
  run_stop "$RC_ROOT"
  why="$(expect_dr_slot_block "$RC_ROOT" "$TOK_DR_ROOTBAD" "$TOK_DR_KEYLINE")"
  [[ -z "$why" ]] && contains "$ERR" "$TOK_DR_OLD_KEYOFF" \
    && why='값만 바꾸는 것과 가르지 않는 옛 문구'
  # 값만 틀리게 바꾸면 루트 리뷰가 있어도 그대로 막힌다.
  if [[ -z "$why" ]]; then
    root_review "$RC_ROOT"
    env_slot "$RC_BASE/no-such-slot" > "$env"
    run_stop "$RC_ROOT"
    why="$(expect_dr_slot_block "$RC_ROOT" "$TOK_DR_ROOTBAD")"
    [[ -n "$why" ]] && why="[틀린 값] $why"
  fi
  if [[ -z "$why" ]]; then
    printf 'HARNESS_EXTRA_GATE_DIRS=""\n' > "$env"
    run_stop "$RC_ROOT"
    why="$(expect_dr_released "$RC_ROOT")"
    [[ -n "$why" ]] && why="[빈 값] $why"
  fi
  if [[ -z "$why" ]]; then
    env_slot "$RC_BASE/slot" > "$env" && dr_flag "$RC_ROOT" 'src/a.go' \
      || { report "$name" ''; return; }
    run_stop "$RC_ROOT"
    why="$(expect_dr_slot_block "$RC_ROOT" "$TOK_DR_ROOTBAD")"
    if [[ -z "$why" ]]; then
      printf '%s' "$ENV_NO_KEY" > "$env"
      run_stop "$RC_ROOT"
      why="$(expect_dr_released "$RC_ROOT")"
    fi
    [[ -n "$why" ]] && why="[키 줄 삭제] $why"
  fi
  report "$name" "$why"
}

v24() { # 경로에 US 가 든 값이 git 이 읽지 못하는 슬롯 저장소의 ④ 앵커면 기록 불가(영구)가
        # 앞선다 — "git 이 회복된 뒤 다시 저장하면 기록된다" 를 함께 내면 두 알림이
        # 어긋난다. 영구 알림만 내고, 그것이 사실임(git 을 고쳐 다시 저장하고 모든
        # 자리에 리뷰를 둬도 막힘)을 확인한다.
  local name='v24 US 값 · 슬롯 ④ git 판독 실패 → 영구 알림만 · git 복구 · 다시 저장해도 막음'
  local why='' u v
  stop_fixture || { report "$name" ''; return; }
  u="$C3_S/U"
  broken_git_repo "$u" || { report "$name" ''; return; }
  v="$u/.claude/hooks/a${US}b.sh"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  if ! contains "$OUT" "$TOK_RECORD_PERM"; then
    why="[저장 알림] 영구 알림 없음 [$OUT]"
  elif contains "$OUT" "$TOK_RECORD_GIT"; then
    why='[저장 알림] git 회복 뒤 다시 저장하라는 알림이 함께 나왔다'
  fi
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$v")"
  if [[ -z "$why" ]]; then
    rm -f "$u/.git" && git -C "$u" init -q \
      || { FIXTURE_FAIL='.git 복구'; report "$name" ''; return; }
    run_mna "$C3_R" edit "$v"
    review_at "$u/_workspace" && review_at "$C3_S/_workspace_U" \
      && review_at "$C3_R/_workspace" || { report "$name" ''; return; }
    run_stop "$C3_R"
    why="$(expect_dr_slot_block "$C3_R" "$TOK_DR_UNREC" "$TOK_DR_NOEXIT_UNREC")"
    [[ -n "$why" ]] && why="[git 복구 뒤 다시 저장] $why"
  fi
  report "$name" "$why"
}
