#!/usr/bin/env bash
# extra-gate-dirs.rootchar.cases.sh — 세션 루트 경로에 개행(가운데·끝)이나 US 가 있을 때
# Stop 3.5 · 발행 가드 ② 가 루트를 쪼개거나 다른 폴더로 읽지 않는 케이스(C5 r1 H-1)와,
# 그 막음의 키 출구가 harness.env 를 정상으로 읽을 수 있을 때만 푸는가(종결 r1, v28).
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 release·life·settle 케이스 파일에 있다:
#   run_stop · run_pub · dr_flag · rec · expect_dr_released · expect_dr_slot_block ·
#   expect_dr_loop_block · env_slot · new_dir · report · contains · flat · COMMON · MODULE ·
#   STOP_HOOK · PUB_HOOK · ENV_NO_KEY · TOK_DR_KEYLINE · TOK_DR_ENVOK · US ·
#   RC · ERR · FIXTURE_FAIL
#
# 고정틀: <F>/B/R<꼴> 이 세션 루트다. 꼴은 셋 — 가운데 개행(R␊X) · 끝 개행(R␊) · US(R␟X).
# 미끼: <F>/B/R(루트를 개행·US 에서 자르면 나오는 이름)과 그 _workspace 에 최근 *codex*.md 를
# 둔다. 미끼로 풀리면 루트를 쪼갠 것이다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

TOK_DR_ROOTBAD='세션 루트 경로에 개행이나 제어문자(US)가 있어'   # root-unusable 문구 조각
ROOTCHAR_KINDS='mid end us'
RC_ROOT=''   # rootchar_fixture 가 만든 세션 루트
RC_BASE=''   # 그 고정틀 폴더(<F>)

#######################################
# 세션 루트 이름에 특수 문자가 든 프로젝트와 미끼를 만든다. 리뷰는 두지 않는다.
# Globals:
#   COMMON, MODULE, STOP_HOOK, PUB_HOOK, US (읽음) · RC_ROOT, RC_BASE, FIXTURE_FAIL (씀)
# Arguments:
#   $1 — mid|end|us, $2 — harness.env 내용
#######################################
rootchar_fixture() {
  local f r
  RC_ROOT=''; RC_BASE=''
  f="$(new_dir rootchar)" || { FIXTURE_FAIL='임시 디렉토리'; return 1; }
  case "$1" in
    mid) r="$f/B/R"$'\n'"X" ;;
    end) r="$f/B/R"$'\n' ;;
    us) r="$f/B/R${US}X" ;;
  esac
  mkdir -p "$r/.claude/hooks" "$r/.claude/harness" "$r/_workspace" "$f/B/R/_workspace" \
    "$f/slot/T/_workspace" \
    && cp "$COMMON" "$MODULE" "$STOP_HOOK" "$PUB_HOOK" "$r/.claude/hooks/" \
    && printf '%s' "$2" > "$r/.claude/harness/harness.env" \
    && printf 'd\n' > "$f/B/R/03_codex_review.md" \
    && printf 'd\n' > "$f/B/R/_workspace/03_codex_review.md" \
    || { FIXTURE_FAIL="특수 문자 루트($1)"; return 1; }
  RC_ROOT="$r"; RC_BASE="$f"
}

# root_review <루트> — 진짜 세션 루트 _workspace 에 지금 시각의 리뷰.
root_review() { printf 'r\n' > "$1/_workspace/03_codex_review.md"; }

q01() { # 키 부재 · 발행 ② — 루트 리뷰가 있으면 통과, 미끼뿐이면 막는다(187398c 와 같다 — I2).
  local name='q01 키 부재 · 발행 ② · 루트에 개행·US → 루트 리뷰로만 통과' why='' k
  for k in $ROOTCHAR_KINDS; do
    rootchar_fixture "$k" "$ENV_NO_KEY" || { report "$name" ''; return; }
    run_pub "$RC_ROOT"
    [[ "$RC" -eq 2 ]] || { why="[$k 미끼만] rc=$RC (기대 2 — 미끼로 통과)"; break; }
    root_review "$RC_ROOT"
    run_pub "$RC_ROOT"
    [[ "$RC" -eq 0 ]] || { why="[$k 루트 리뷰] rc=$RC (기대 0)"; break; }
  done
  report "$name" "$why"
}

q02() { # 슬롯 모드 · 발행 ② — 루트는 따로 보고(쪼개지 않음), 기록 자리는 그대로 본다.
  local name='q02 슬롯 모드 · 발행 ② · 루트에 개행·US → 루트·기록 자리만' why='' k
  for k in $ROOTCHAR_KINDS; do
    rootchar_fixture "$k" '' || { report "$name" ''; return; }
    env_slot "$RC_BASE/slot" > "$RC_ROOT/.claude/harness/harness.env"
    rec "$RC_ROOT" "$RC_BASE/slot/T/src/a.go" "$RC_BASE/slot/T/_workspace" \
      || { report "$name" ''; return; }
    run_pub "$RC_ROOT"
    [[ "$RC" -eq 2 ]] || { why="[$k 미끼만] rc=$RC (기대 2)"; break; }
    root_review "$RC_ROOT"
    run_pub "$RC_ROOT"
    [[ "$RC" -eq 0 ]] || { why="[$k 루트 리뷰] rc=$RC (기대 0)"; break; }
    rm -f "$RC_ROOT/_workspace/03_codex_review.md"
    printf 'r\n' > "$RC_BASE/slot/T/_workspace/03_codex_review.md"
    run_pub "$RC_ROOT"
    [[ "$RC" -eq 0 ]] || { why="[$k 기록 자리 리뷰] rc=$RC (기대 0)"; break; }
  done
  report "$name" "$why"
}

q03() { # 키 부재 · Stop 3.5 — 기존 루프 그대로: 루트 리뷰로 풀리고 미끼로는 안 풀린다(I2).
  local name='q03 키 부재 · Stop · 루트에 개행·US → 기존 루프(루트 리뷰로만 해제)' why='' k
  for k in $ROOTCHAR_KINDS; do
    rootchar_fixture "$k" "$ENV_NO_KEY" && dr_flag "$RC_ROOT" 'src/a.go' \
      || { report "$name" ''; return; }
    run_stop "$RC_ROOT"
    why="$(expect_dr_loop_block "$RC_ROOT")"
    [[ -n "$why" ]] && { why="[$k 미끼만] $why"; break; }
    root_review "$RC_ROOT"
    run_stop "$RC_ROOT"
    why="$(expect_dr_released "$RC_ROOT")"
    [[ -n "$why" ]] && { why="[$k 루트 리뷰] $why"; break; }
  done
  report "$name" "$why"
}

q04() { # 슬롯 VALUE · Stop 3.5 — 루트 경로가 목록 구분자(개행·US)를 품으면 판정할 수 없다.
        # 미끼로도, 진짜 루트 리뷰로도 풀지 않고 사유를 내며 막는다(조용한 축소 금지).
  local name='q04 VALUE · Stop · 루트에 개행·US → root-unusable 로 막음(미끼·루트 리뷰 모두)'
  local why='' k
  for k in $ROOTCHAR_KINDS; do
    rootchar_fixture "$k" '' || { report "$name" ''; return; }
    env_slot "$RC_BASE/slot" > "$RC_ROOT/.claude/harness/harness.env"
    dr_flag "$RC_ROOT" 'src/a.go' || { report "$name" ''; return; }
    run_stop "$RC_ROOT"
    why="$(expect_dr_slot_block "$RC_ROOT" "$TOK_DR_ROOTBAD")"
    [[ -n "$why" ]] && { why="[$k 미끼만] $why"; break; }
    root_review "$RC_ROOT"
    run_stop "$RC_ROOT"
    why="$(expect_dr_slot_block "$RC_ROOT" "$TOK_DR_ROOTBAD")"
    [[ -n "$why" ]] && { why="[$k 루트 리뷰] $why"; break; }
  done
  report "$name" "$why"
}

v28() { # root-unusable 의 키 출구(키 줄 삭제 · 빈 값)는 harness.env 를 정상으로 읽을 수
        # 있을 때만 푼다 — 다른 키가 손상됐으면(UNTRUSTED) 기록 파일이 있는 한 기록으로
        # 판정해 그대로 막는다. 안내가 그 한정어를 싣고, 한정어가 사실이며(키 줄을 지우고
        # 루트 리뷰를 둬도 막음), 다른 키를 고치면 풀린다.
  local name='v28 root-unusable · 다른 키 손상 → 키 줄 삭제로 안 풀림 · 한정어 · 고치면 해제'
  local why='' env bad
  bad='HARNESS_KNOWLEDGE_GATE="x'$'\n'   # 따옴표가 닫히지 않은 다른 키
  rootchar_fixture mid '' || { report "$name" ''; return; }
  env="$RC_ROOT/.claude/harness/harness.env"
  env_slot "$RC_BASE/slot" > "$env" && dr_flag "$RC_ROOT" 'src/a.go' \
    && rec "$RC_ROOT" 'src/a.go' '-' \
    || { FIXTURE_FAIL="${FIXTURE_FAIL:-고정틀}"; report "$name" ''; return; }
  run_stop "$RC_ROOT"
  why="$(expect_dr_slot_block "$RC_ROOT" "$TOK_DR_ROOTBAD" "$TOK_DR_KEYLINE" \
    "$TOK_DR_ENVOK")"
  if [[ -z "$why" ]]; then
    printf '%s%s' "$ENV_NO_KEY" "$bad" > "$env" && root_review "$RC_ROOT" \
      || { FIXTURE_FAIL='harness.env'; report "$name" ''; return; }
    run_stop "$RC_ROOT"
    why="$(expect_dr_slot_block "$RC_ROOT" "$TOK_DR_ROOTBAD")"
    [[ -n "$why" ]] && why="[키 줄 삭제 · 다른 키 손상] $why"
  fi
  if [[ -z "$why" ]]; then
    printf '%s' "$ENV_NO_KEY" > "$env" \
      || { FIXTURE_FAIL='harness.env'; report "$name" ''; return; }
    run_stop "$RC_ROOT"
    why="$(expect_dr_released "$RC_ROOT")"
    [[ -n "$why" ]] && why="[다른 키를 고친 뒤] $why"
  fi
  report "$name" "$why"
}
