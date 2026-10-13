#!/usr/bin/env bash
# extra-gate-dirs.settle.cases.sh — 푸는 쪽(Stop 3.5 · 발행 가드 ②)의 이연 처분
# 케이스: 미충족 나열 비용 · 발행 ② 기록 읽기 실패 알림 · 막음 안내 문구(루트
# 경로 문자 · 슬롯 값 검증 실패 · 세션 루트 자리뿐인 막음 · 자리 목록 없는 막음 ·
# 기록 줄 길이 초과).
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice·judge·capture·release·life·rootchar 케이스 파일에 있다:
#   stop_fixture · run_stop · run_pub · dr_flag · rec · review_at · review_now
#   expect_dr_released · expect_dr_slot_block · expect_dr_loop_block · env_slot
#   env_untrusted · rootchar_fixture · new_mna_project · commit_repo · set_env
#   edit_new · record_lines_of · run_common_bounded · new_dir · report · contains
#   flat · MODULE · STOP_HOOK · C3_F · C3_R · C3_S · C3_T · RC_ROOT · RC_BASE
#   MNA_PROJ · TOK_DR_* · TOK_PUB_NOTE · ENV_NO_KEY · US · OUT · ERR · RC
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
TOK_DR_TOOLONG='1023바이트를 넘는 값이라 다시 저장해도 풀리지 않는다'
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
  mkdir -p "$r/.claude" "$s" || { FIXTURE_FAIL='골격'; report "$name" ''; return; }
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

v07() { # 기록 줄이 1023바이트를 넘어 현재 기록을 못 쓴 값(영구)은 다시 저장해도
        # 기록되지 않는다 — Stop 이 "다시 저장하면 기록된다" 로만 안내하면 회복되지 않는
        # 길로 보낸다. 다시 저장으로 풀리지 않는 경우와 그 출구를 함께 안내한다.
  local name='v07 기록 줄 1023B 초과 값 → 다시 저장으로 안 풀림 안내' why=''
  local f s t v a b
  f="$(new_dir v07)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  a="$(printf '%200s' '' | tr ' ' a)"; b="$(printf '%200s' '' | tr ' ' b)"
  s="$f/slot"; t="$s/$a/$b/T"; v="$t/src/v7.go"
  mkdir -p "$t/src" && printf 'k\n' > "$t/src/k.go" && commit_repo "$t" \
    && new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$s\""$'\n' \
    && cp "$STOP_HOOK" "$MNA_PROJ/.claude/hooks/" \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-고정틀}"; report "$name" ''; return; }
  edit_new "$MNA_PROJ" "$v" || { report "$name" ''; return; }
  if [[ "$(record_lines_of "$MNA_PROJ" "$v")" != '!' ]]; then
    FIXTURE_FAIL='끝줄이 갱신 표시가 아니다'
    report "$name" ''
    return
  fi
  run_stop "$MNA_PROJ"
  why="$(expect_dr_slot_block "$MNA_PROJ" "$TOK_DR_MISSING" "$TOK_DR_TOOLONG" \
    "  - $v")"
  report "$name" "$why"
}
