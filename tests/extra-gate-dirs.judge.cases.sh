#!/usr/bin/env bash
# extra-gate-dirs.judge.cases.sh — 슬롯 저장소·설계물 판정(⑤′)과 리뷰 자리 기록 케이스.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기와 notice 케이스 파일에 있다: new_dir · report · contains · flat · US ·
# new_mna_project · set_env · make_window · run_mna · expect_silent · MNA_PROJ ·
# MNA_OUT_FILE · json_message_ok · TMPROOT · OUT · ERR · RC · DID_RUN ·
# FIXTURE_FAIL.
#
# 기록 단언은 r3 형식이다: 그 값의 끝 두 줄 = `값␟!`(갱신 표시), `값␟꼬리`(현재 기록).
# 꼬리는 `-`(빈 집합) 또는 US 로 이은 리뷰 자리다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${MNA_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

TOK_WRITE_FAIL_MNA='게이트 플래그를 기록하지 못했다'   # 기존 MSG_WRITE_FAIL
TOK_RECORD_FAIL='리뷰 자리 기록에 실패했다'            # RECORD_MSG 회복 가능
TOK_RECORD_PERM='기록할 수 없는 제어문자'              # RECORD_MSG 영구

C3_F=''   # 고정틀 바깥 폴더
C3_R=''   # 세션 루트(비git, 훅·모듈 설치)
C3_S=''   # 슬롯
C3_T=''   # 슬롯 안 저장소

#######################################
# 슬롯 판정 고정틀을 만든다: 세션 루트 R · 슬롯 S · S 안 저장소 T(src/a.go ·
# README.md · docs/decisions/x.md 커밋) · T/_workspace · 형제 S/_workspace_T.
# harness.env 는 슬롯을 켠다(인자가 없으면 S).
# Globals:
#   C3_F, C3_R, C3_S, C3_T, FIXTURE_FAIL (씀)
# Arguments:
#   $1 — harness.env 의 슬롯 값(선택)
# Returns:
#   0 · 1 픽스처 실패
#######################################
slot_fixture() {
  local f t
  C3_F=''; C3_R=''; C3_S=''; C3_T=''
  f="$(new_dir slot)" || { FIXTURE_FAIL='임시 디렉토리'; return 1; }
  t="$f/slot/T"
  mkdir -p "$t/src" "$t/_workspace" "$t/docs/decisions" "$f/slot/_workspace_T" \
    || { FIXTURE_FAIL='슬롯 골격'; return 1; }
  printf 'package a\n' > "$t/src/a.go"
  printf '# r\n' > "$t/README.md"
  printf 'd\n' > "$t/docs/decisions/x.md"
  commit_repo "$t" || return 1
  new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"${1:-$f/slot}\""$'\n' || return 1
  C3_F="$f"; C3_R="$MNA_PROJ"; C3_S="$f/slot"; C3_T="$t"
}

# commit_repo <폴더> — 그 폴더를 git 저장소로 만들고 전부 커밋한다.
commit_repo() {
  git -C "$1" init -q && git -C "$1" add -A \
    && git -C "$1" -c user.email=t@t -c user.name=t commit -q -m init \
    || { FIXTURE_FAIL="git 저장소 $1"; return 1; }
}

# edit_new <프로젝트> <파일> — 파일을 만들고(부모 포함) 그 Edit 를 훅에 넣는다.
edit_new() {
  mkdir -p "${2%/*}" && : > "$2" || { FIXTURE_FAIL="파일 $2"; return 1; }
  run_mna "$1" edit "$2"
}

# places <자리>... — 꼬리 문자열(US 로 이음).
places() {
  local out="$1"
  shift
  while (($# > 0)); do out="$out$US$1"; shift; done
  printf '%s' "$out"
}

#######################################
# 플래그 묶음이 기대와 같은지 본다. 4 = 감사·설명·지식·듀얼(회수 없음), 3 = 듀얼·
# 지식·회수, k = 지식만, 0 = 어디에도 없음.
# Arguments:
#   $1 — 프로젝트, $2 — 4|3|k|0, $3 — 값
# Outputs:
#   어긋나면 사유
#######################################
expect_flags() {
  local p="$1" kind="$2" v="$3" f want have
  for f in audit explain knowledge dualreview retrieval; do
    case "$kind:$f" in
      4:retrieval | 3:audit | 3:explain | k:audit | k:explain | k:dualreview \
        | k:retrieval | 0:*) want=0 ;;
      *) want=1 ;;
    esac
    have=0
    grep -qxF -- "$v" "$p/.claude/.needs-$f" 2>/dev/null && have=1
    if [[ "$have" -ne "$want" ]]; then
      printf '.needs-%s 에 값이 %s (기대 %s)' "$f" "$have" "$want"
      return
    fi
  done
}

# record_lines_of <프로젝트> <값> — 기록 파일에서 그 값의 줄들(꼬리만, 줄당 하나).
record_lines_of() {
  local line
  [[ -f "$1/.claude/.review-dirs" ]] || return 0
  while IFS= read -r line; do
    [[ "$line" == "$2$US"* ]] && printf '%s\n' "${line#"$2$US"}"
  done < "$1/.claude/.review-dirs"
}

# expect_record <프로젝트> <값> <꼬리> — 그 값의 끝 두 줄이 `값␟!`, `값␟꼬리` 인가.
expect_record() {
  local tails last prev
  tails="$(record_lines_of "$1" "$2")"
  last="${tails##*$'\n'}"
  prev="${tails%$'\n'*}"
  prev="${prev##*$'\n'}"
  if [[ "$tails" != *$'\n'* ]]; then
    printf '기록 줄이 둘 미만 [%s]' "$(flat "$tails")"
  elif [[ "$prev" != '!' || "$last" != "$3" ]]; then
    printf '끝 두 줄 [%s] [%s] (기대 [!] [%s])' "$(flat "$prev")" "$(flat "$last")" \
      "$(flat "$3")"
  fi
}

# expect_no_record <프로젝트> <값> — 그 값의 기록 줄이 없는가.
expect_no_record() {
  local tails
  tails="$(record_lines_of "$1" "$2")"
  [[ -z "$tails" ]] || printf '기록 줄이 있다 [%s]' "$(flat "$tails")"
}

# --- e: 판정 · 기록 ---------------------------------------------------------

e01() { # 슬롯 저장소 코드 → 4종 + 결속 기록(`값␟!` → 플래그 → `값␟T 자리`).
        # 덧붙여 결속의 실패 쪽: 듀얼리뷰 플래그 쓰기 실패면 현재 기록을 쓰지 않는다
        # (마지막 줄 = 갱신 표시) · 0x1F 경로는 영구 문구 · 기록 파일 쓰기 실패는
        # 회복 가능 문구(RECORD_MSG — 판정 알림과 따로).
  local name='e01 슬롯 저장소 코드 → 4종 + 결속 기록(실패 문구 포함)' why='' r t s v
  slot_fixture || { report "$name" ''; return; }
  r="$C3_R"; t="$C3_T"; s="$C3_S"
  run_mna "$r" edit "$t/src/a.go"
  why="$(expect_silent '정상')"
  [[ -z "$why" ]] && why="$(expect_flags "$r" 4 "$t/src/a.go")"
  [[ -z "$why" ]] && why="$(expect_record "$r" "$t/src/a.go" \
    "$(places "$t/_workspace" "$s/_workspace_T")")"
  if [[ -z "$why" ]]; then   # 듀얼리뷰 플래그를 못 쓰면 현재 기록도 쓰지 않는다
    rm -f "$r/.claude/.needs-dualreview" && mkdir "$r/.claude/.needs-dualreview"
    edit_new "$r" "$t/src/b.go"
    contains "$OUT" "$TOK_WRITE_FAIL_MNA" || why="플래그 쓰기 실패 알림 없음 [$OUT]"
    v="$(record_lines_of "$r" "$t/src/b.go")"
    [[ -z "$why" && "$v" != '!' ]] \
      && why="플래그 실패인데 현재 기록이 섰다 [$(flat "$v")]"
    rmdir "$r/.claude/.needs-dualreview"
  fi
  if [[ -z "$why" ]]; then   # 0x1F 가 든 경로 → 영구 문구, 기록 줄 없음
    v="$t/src/c${US}d.go"
    edit_new "$r" "$v"
    if ! json_message_ok "$MNA_OUT_FILE" || ! contains "$OUT" "$TOK_RECORD_PERM"
    then why="0x1F 경로에 영구 문구 없음 [$OUT]"
    fi
    [[ -z "$why" ]] && why="$(expect_flags "$r" 4 "$v")"
    [[ -z "$why" ]] && why="$(expect_no_record "$r" "$v")"
  fi
  if [[ -z "$why" ]]; then   # 기록 파일 쓰기 실패 → 회복 가능 문구, 게이트는 선다
    rm -f "$r/.claude/.review-dirs" && mkdir "$r/.claude/.review-dirs"
    edit_new "$r" "$t/src/e.go"
    if ! json_message_ok "$MNA_OUT_FILE" || ! contains "$OUT" "$TOK_RECORD_FAIL"
    then why="기록 실패 문구 없음 [$OUT]"
    fi
    [[ -z "$why" ]] && why="$(expect_flags "$r" 4 "$t/src/e.go")"
  fi
  report "$name" "$why"
}

e02() { # 슬롯 값이 `~/` 로 시작해도(따옴표 안 ~ 를 펼친다) 같다.
  local name='e02 슬롯 값 ~/ → 4종 + T 자리 기록' why=''
  slot_fixture '~/slot' || { report "$name" ''; return; }
  local -x HOME="$C3_F"   # 훅이 ~ 를 이 고정틀로 펼친다(함수가 끝나면 원래 값)
  run_mna "$C3_R" edit "$C3_T/src/a.go"
  why="$(expect_silent '~/ 값')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$C3_T/src/a.go")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$C3_T/src/a.go" \
    "$(places "$C3_T/_workspace" "$C3_S/_workspace_T")")"
  report "$name" "$why"
}

e05() { # 슬롯 값이 심링크 · 편집 경로가 심링크 경유여도 값과 자리는 물리 경로다.
  local name='e05 심링크 슬롯 값 · 심링크 경유 편집 → 물리 경로 4종 + 기록' why=''
  slot_fixture || { report "$name" ''; return; }
  ln -s "$C3_S" "$C3_F/slotlink" \
    || { FIXTURE_FAIL='심링크'; report "$name" ''; return; }
  set_env "$C3_R" "HARNESS_EXTRA_GATE_DIRS=\"$C3_F/slotlink\""$'\n'
  run_mna "$C3_R" edit "$C3_F/slotlink/T/src/a.go"
  why="$(expect_silent '심링크')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$C3_T/src/a.go")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$C3_T/src/a.go" \
    "$(places "$C3_T/_workspace" "$C3_S/_workspace_T")")"
  report "$name" "$why"
}

e06() { # 슬롯 안 git 밖 스크립트 → 게이트 없음(설계 모양만 예외 — D3), 기록 없음.
  local name='e06 슬롯 안 git 밖 스크립트 → 0' why='' v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_S/scripts/x.sh"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_silent 'git 밖')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 0 "$v")"
  [[ -z "$why" ]] && why="$(expect_no_record "$C3_R" "$v")"
  report "$name" "$why"
}

e07() { # 슬롯 안 `_workspace_x/00_design.md` → 3종 + 그 폴더 자리.
  local name='e07 슬롯 _workspace_x/00_design.md → 3종 + 그 폴더 기록' why='' v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_S/_workspace_x/00_design.md"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_silent '설계')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" "$C3_S/_workspace_x")"
  report "$name" "$why"
}

e08() { # 슬롯 저장소의 `T/_workspace/00_design.md`(기존 글롭) → 자리 = T/_workspace 하나.
  local name='e08 T/_workspace/00_design.md → 3종 + 자리 T/_workspace 하나' why='' v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_T/_workspace/00_design.md"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_silent '설계')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" "$C3_T/_workspace")"
  report "$name" "$why"
}

e09() { # 슬롯 저장소의 `.claude/hooks/x.sh` 는 ④(앵커)가 먼저 판정한다 → 4종.
        # ⑤′ 가 먼저면 classify 가 `.claude/*` 를 빼서 조용히 사라진다(ADR-0007).
  local name='e09 슬롯 저장소 .claude/hooks/x.sh → ④ 4종' why='' v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_T/.claude/hooks/x.sh"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_silent '앵커')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$v")"
  report "$name" "$why"
}

e10() { # 슬롯 저장소에도 classify 가 그대로 — README 는 0, 결정 문서는 지식만(기록 없음).
  local name='e10 슬롯 README → 0 · docs/decisions → 지식만, 기록 없음' why=''
  slot_fixture || { report "$name" ''; return; }
  run_mna "$C3_R" edit "$C3_T/README.md"
  why="$(expect_silent 'README')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 0 "$C3_T/README.md")"
  if [[ -z "$why" ]]; then
    run_mna "$C3_R" edit "$C3_T/docs/decisions/x.md"
    why="$(expect_silent '결정 문서')"
    [[ -z "$why" ]] \
      && why="$(expect_flags "$C3_R" k "$C3_T/docs/decisions/x.md")"
  fi
  [[ -z "$why" ]] && why="$(expect_no_record "$C3_R" "$C3_T/README.md")"
  [[ -z "$why" ]] \
    && why="$(expect_no_record "$C3_R" "$C3_T/docs/decisions/x.md")"
  report "$name" "$why"
}

e11() { # 슬롯이 바깥 저장소 O 안에 있고 파일의 최상위가 O(슬롯 밖) → ⑤′ 아님 → 0.
  local name='e11 바깥 저장소가 슬롯을 감쌈 → 0' why='' f o v
  f="$(new_dir e11)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  o="$f/outer"
  mkdir -p "$o/slot" && printf 'x\n' > "$o/keep.txt" && commit_repo "$o" \
    || { report "$name" ''; return; }
  new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$o/slot\""$'\n' \
    || { report "$name" ''; return; }
  v="$o/slot/x.go"
  edit_new "$MNA_PROJ" "$v" || { report "$name" ''; return; }
  why="$(expect_silent '바깥 저장소')"
  [[ -z "$why" ]] && why="$(expect_flags "$MNA_PROJ" 0 "$v")"
  [[ -z "$why" ]] && why="$(expect_no_record "$MNA_PROJ" "$v")"
  report "$name" "$why"
}

e12() { # 슬롯이 세션 루트를 감싸도 루트 안 판정은 그대로다(상대 값 · 기록 없음 ·
        # 루트 안 `_workspace_foo/` 설계 모양은 예전처럼 대상 아님).
  local name='e12 슬롯 ⊇ 세션 루트 → 루트 안 판정 불변' why='' r
  new_mna_project 1 '' || { report "$name" ''; return; }
  r="$MNA_PROJ"
  set_env "$r" "HARNESS_EXTRA_GATE_DIRS=\"${r%/*}\""$'\n'
  edit_new "$r" "$r/src/a.go" || { report "$name" ''; return; }
  why="$(expect_silent '루트 코드')"
  [[ -z "$why" ]] && why="$(expect_flags "$r" 4 src/a.go)"
  if [[ -z "$why" ]]; then
    edit_new "$r" "$r/_workspace_foo/00_design.md" \
      || { report "$name" ''; return; }
    why="$(expect_silent '루트 _workspace_foo 설계')"
    if [[ -z "$why" ]] && grep -qF -- '_workspace_foo' "$r"/.claude/.needs-* \
      2>/dev/null; then
      why='루트 안 _workspace_foo 설계 모양이 새로 플래그됐다'
    fi
  fi
  [[ -z "$why" && -e "$r/.claude/.review-dirs" ]] && why='루트 안 판정이 기록을 남겼다'
  report "$name" "$why"
}

e13() { # 슬롯 안 하네스 정본 저장소 H 는 ③ 이 판정하고 자리는 H 기준이다.
  local name='e13 슬롯 안 하네스 정본 → ③ 4종 + H 자리' why='' h v
  slot_fixture || { report "$name" ''; return; }
  h="$C3_S/H"
  mkdir -p "$h/template/.claude/hooks" \
    && printf 'x\n' > "$h/template/.claude/hooks/x.sh" \
    && commit_repo "$h" || { report "$name" ''; return; }
  v="$h/template/.claude/hooks/x.sh"
  run_mna "$C3_R" edit "$v"
  why="$(expect_silent '정본')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" \
    "$(places "$h/_workspace" "$C3_S/_workspace_H")")"
  report "$name" "$why"
}

e14() { # 슬롯 안 git 밖 `_workspace_prev/00_design.md` → 3종 + 그 폴더 자리(D3 의도).
  local name='e14 슬롯 _workspace_prev/00_design.md → 3종 + 그 폴더 기록' why='' v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_S/_workspace_prev/00_design.md"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_silent '설계')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" "$C3_S/_workspace_prev")"
  report "$name" "$why"
}

e15() { # 슬롯 안 git 밖 앵커(.claude/hooks) → ④ 4종, 자리는 빈 집합 `-`(Y4).
  local name='e15 슬롯 git 밖 .claude/hooks → 4종 + 빈 집합 -' why='' v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_S/x/.claude/hooks/y.sh"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_silent '앵커')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" '-')"
  report "$name" "$why"
}

e17() { # 슬롯 저장소의 ④ 앵커도 VERDICT_REPO(= T)를 유지해 T 자리에 기록한다(Y4).
  local name='e17 슬롯 저장소 .claude/hooks/x.sh → T 자리 기록' why='' v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_T/.claude/hooks/x.sh"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_silent '앵커')"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" \
    "$(places "$C3_T/_workspace" "$C3_S/_workspace_T")")"
  report "$name" "$why"
}

e18() { # 슬롯 안 git 밖 `.claude/agents/x.md`(④, VERDICT_REPO 빈 값) → `값␟-`.
  local name='e18 슬롯 git 밖 .claude/agents/z.md → 4종 + 빈 집합 -' why='' v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_S/y/.claude/agents/z.md"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_silent '앵커')"
  [[ -z "$why" ]] && why="$(expect_flags "$C3_R" 4 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" '-')"
  report "$name" "$why"
}

e19() { # 슬롯 저장소의 폴더째 삭제(절대경로 명령 — cc M2) → 지워진 추적 파일이 4종.
        # 그 파일의 폴더가 없어 git 을 그 자리에서 부를 수 없다 — ⑤′ 는 남아 있는 가장
        # 가까운 조상으로 최상위를 찾는다(cc1, other_checkout 과 같은 관용구).
  local name='e19 슬롯 저장소 rm -rf T/src(절대경로) → T/src/a.go 4종 + 기록' why=''
  slot_fixture || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + \
    && make_window "$C3_R" && rm -rf "$C3_T/src" \
    || { FIXTURE_FAIL='창·삭제'; report "$name" ''; return; }
  run_mna "$C3_R" bash "rm -rf $C3_T/src"
  why="$(expect_flags "$C3_R" 4 "$C3_T/src/a.go")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$C3_T/src/a.go" \
    "$(places "$C3_T/_workspace" "$C3_S/_workspace_T")")"
  report "$name" "$why"
}

r08() { # 같은 세션의 병렬 Edit 두 개가 동시에 기록해도 두 값의 기록이 모두 남는다
        # (덧붙이기 — 대체 쓰기면 한쪽이 사라진다).
  local name='r08 병렬 Edit 두 값 → 두 값의 결속 기록 모두 유지' why='' i pids=''
  local pay tail
  slot_fixture || { report "$name" ''; return; }
  DID_RUN=1
  for i in 1 2; do
    : > "$C3_T/src/p$i.go"
    pay="$TMPROOT/r08.$i.$$"
    python3 -c 'import json, sys
body = {"tool_input": {"file_path": sys.argv[1]}}
open(sys.argv[2], "w").write(json.dumps(body))' \
      "$C3_T/src/p$i.go" "$pay"
    (env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$C3_R" \
      "$BASH" "$C3_R/.claude/hooks/mark-needs-audit.sh" \
      <"$pay" >/dev/null 2>&1) &
    pids="$pids $!"
  done
  for i in $pids; do wait "$i" || why="병렬 훅 rc 비0"; done
  rm -f "$TMPROOT/r08.1.$$" "$TMPROOT/r08.2.$$"
  tail="$(places "$C3_T/_workspace" "$C3_S/_workspace_T")"
  for i in 1 2; do
    [[ -n "$why" ]] && break
    why="$(expect_flags "$C3_R" 4 "$C3_T/src/p$i.go")"
    [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$C3_T/src/p$i.go" "$tail")"
    [[ -n "$why" ]] && why="[p$i] $why"
  done
  report "$name" "$why"
}

# --- 수정 커밋(C3 r1 HIGH): 막아야 할 때 조용히 풀리는 경로 ------------------

TOK_GIT_UNAVAILABLE='git 이 저장소 정보를 돌려주지 못해'   # 기존 MSG_GIT_UNAVAILABLE

# commit_more <저장소> — 새로 만든 파일까지 커밋한다.
commit_more() {
  git -C "$1" add -A \
    && git -C "$1" -c user.email=t@t -c user.name=t commit -q -m more \
    || { FIXTURE_FAIL="추가 커밋 $1"; return 1; }
}

# last_tail_of <프로젝트> <값> — 그 값의 마지막 기록 꼬리.
last_tail_of() {
  local tails
  tails="$(record_lines_of "$1" "$2")"
  printf '%s' "${tails##*$'\n'}"
}

# expect_places_ef <프로젝트> <값> <자리>... — 마지막 기록 꼬리의 자리들이 순서대로 그
# 폴더들과 같은 폴더(-ef)인가. 표기(대소문자·NFC/NFD)가 디스크와 달라도 같은 폴더면 맞다.
expect_places_ef() {
  local p="$1" v="$2" rest d
  shift 2
  rest="$(last_tail_of "$p" "$v")"
  [[ "$rest" != '!' && "$rest" != '-' && -n "$rest" ]] \
    || { printf '마지막 꼬리가 자리가 아니다 [%s]' "$rest"; return; }
  rest="$rest$US"
  for d in "$@"; do
    [[ "${rest%%"$US"*}" -ef "$d" ]] \
      || { printf '자리 [%s] 가 [%s] 와 다른 폴더' "${rest%%"$US"*}" "$d"; return; }
    rest="${rest#*"$US"}"
  done
  [[ -z "$rest" ]] || printf '남는 자리 [%s]' "$(flat "$rest")"
}

e20() { # H-A — 슬롯 저장소의 ④ 앵커 폴더를 통째로 지워도(절대경로 명령) 그 앵커의
        # 리뷰 자리는 T 다. 폴더가 없어 그 자리에서 git 을 못 불러도 남은 조상으로
        # 최상위를 찾는다(⑤′ 와 같은 규칙) — 빈 집합(세션 루트 규칙)으로 새면 안 된다.
  local name='e20 슬롯 저장소 .claude/hooks 폴더째 삭제 → ④ 4종 + T 자리' why='' v
  slot_fixture || { report "$name" ''; return; }
  mkdir -p "$C3_T/.claude/hooks" && printf 'x\n' > "$C3_T/.claude/hooks/x.sh" \
    && commit_more "$C3_T" || { report "$name" ''; return; }
  find "$C3_F" -exec touch -t 201901010000 {} + \
    && make_window "$C3_R" && rm -r "$C3_T/.claude/hooks" \
    || { FIXTURE_FAIL='창·삭제'; report "$name" ''; return; }
  v="$C3_T/.claude/hooks/x.sh"
  run_mna "$C3_R" bash "rm -r $C3_T/.claude/hooks"
  why="$(expect_flags "$C3_R" 4 "$v")"
  [[ -z "$why" ]] && why="$(expect_record "$C3_R" "$v" \
    "$(places "$C3_T/_workspace" "$C3_S/_workspace_T")")"
  report "$name" "$why"
}

e21() { # H-A 부류 — 슬롯 안 ④ 앵커의 저장소를 git 이 돌려주지 못하면(.git 은 있는데
        # 판독 실패) 소속을 모른다. 빈 집합으로 쓰지 않고 갱신 표시를 마지막 줄로 남겨
        # 막으며, git 판독 실패를 알린다.
  local name='e21 슬롯 ④ 앵커 · git 판독 실패 → 현재 기록 생략 + 알림' why='' u v
  slot_fixture || { report "$name" ''; return; }
  u="$C3_S/U"
  mkdir -p "$u/.claude/hooks" \
    && printf 'gitdir: %s\n' "$C3_S/nowhere" > "$u/.git" \
    || { FIXTURE_FAIL='깨진 .git'; report "$name" ''; return; }
  v="$u/.claude/hooks/x.sh"
  edit_new "$C3_R" "$v" || { report "$name" ''; return; }
  why="$(expect_flags "$C3_R" 4 "$v")"
  if [[ -z "$why" ]] && ! contains "$OUT" "$TOK_GIT_UNAVAILABLE"; then
    why="git 판독 실패 알림 없음 [$OUT]"
  fi
  [[ -z "$why" && "$(record_lines_of "$C3_R" "$v")" != '!' ]] \
    && why="소속을 모르는데 현재 기록을 썼다 [$(flat "$(record_lines_of "$C3_R" "$v")")]"
  report "$name" "$why"
}

e22() { # H-B — 기존 값 재편집에서 듀얼리뷰 플래그 갱신(touch)이 실패하면 결속은 그것을
        # 성공으로 보지 않는다. 갱신 표시를 마지막 줄로 남기고 회복 가능 문구를 낸다.
        # 주입: PATH 의 touch 심(실패) — 환경 변수 시험 모드 없이(cc7).
  local name='e22 재편집 · 플래그 갱신 실패 → 갱신 표시 남김 + 기록 실패 문구' why=''
  local shim v
  slot_fixture || { report "$name" ''; return; }
  v="$C3_T/src/a.go"
  run_mna "$C3_R" edit "$v"
  why="$(expect_record "$C3_R" "$v" \
    "$(places "$C3_T/_workspace" "$C3_S/_workspace_T")")"
  if [[ -z "$why" ]]; then
    shim="$(new_dir shim)" && printf '#!/bin/sh\nexit 1\n' > "$shim/touch" \
      && chmod +x "$shim/touch" \
      || { FIXTURE_FAIL='touch 심'; report "$name" ''; return; }
    local -x PATH="$shim:$PATH"
    run_mna "$C3_R" edit "$v"
    if ! contains "$OUT" "$TOK_RECORD_FAIL"; then why="기록 실패 문구 없음 [$OUT]"
    elif [[ "$(last_tail_of "$C3_R" "$v")" != '!' ]]; then
      why="플래그 갱신 실패인데 현재 기록을 썼다 [$(flat "$(last_tail_of "$C3_R" "$v")")]"
    fi
  fi
  report "$name" "$why"
}

#######################################
# 표기만 다른 슬롯 고정틀: 디스크 이름은 $2, harness.env 값은 $3 이름. 안에 저장소 T
# (src/a.go 커밋)와 T/_workspace · 형제 _workspace_T 를 둔다.
# Globals:
#   C3_F, C3_R, C3_S(디스크 이름 경로), C3_T, FIXTURE_FAIL (씀)
# Arguments:
#   $1 — 접두사, $2 — 디스크 이름, $3 — 값에 쓸 이름
#######################################
variant_fixture() {
  local f
  f="$(new_dir "$1")" || { FIXTURE_FAIL='임시 디렉토리'; return 1; }
  mkdir -p "$f/$2/T/src" "$f/$2/T/_workspace" "$f/$2/_workspace_T" \
    || { FIXTURE_FAIL='슬롯 골격'; return 1; }
  printf 'package a\n' > "$f/$2/T/src/a.go"
  commit_repo "$f/$2/T" || return 1
  new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$f/$3\""$'\n' || return 1
  C3_F="$f"; C3_R="$MNA_PROJ"; C3_S="$f/$2"; C3_T="$f/$2/T"
}

#######################################
# 표기 변형 케이스의 본문. 볼륨이 그 표기 차이를 같은 폴더로 보면(-ef) 디스크 표기 경로와
# 값 표기 경로의 편집 모두 4종 + T 자리, 값 표기 _workspace_x 설계물 3종이어야 한다.
# 볼륨이 구분하면(ubuntu ext4) 값의 폴더가 없으므로 슬롯을 쓸 수 없다는 알림(missing)이
# 맞다 — 이 경우는 수정의 판별력이 없고 계약만 확인한다(주석에 밝힌다).
# 서브셸 없이 부른다(실행 센티널 DID_RUN 이 살아야 한다). 사유는 VARIANT_WHY 에 담는다.
# Globals:
#   C3_R, C3_S, C3_T (읽음) · VARIANT_WHY (씀)
# Arguments:
#   $1 — 값 표기의 슬롯 경로
#######################################
variant_expect() {
  local typed="$1" v w=''
  VARIANT_WHY=''
  if [[ ! "$typed" -ef "$C3_S" ]]; then
    edit_new "$C3_R" "$C3_T/src/b.go" || return
    VARIANT_WHY="$(expect_notice missing '표기를 구분하는 볼륨 — 값의 폴더 없음')"
    return
  fi
  for v in "$C3_T/src/a.go" "$typed/T/src/b.go"; do
    edit_new "$C3_R" "$v" || return
    w="$(expect_silent "[$v]")"
    [[ -z "$w" ]] && w="$(expect_flags "$C3_R" 4 "$v")"
    [[ -z "$w" ]] && w="$(expect_places_ef "$C3_R" "$v" \
      "$C3_T/_workspace" "$C3_S/_workspace_T")"
    [[ -n "$w" ]] && { VARIANT_WHY="[$v] $w"; return; }
  done
  v="$typed/_workspace_x/00_design.md"
  edit_new "$C3_R" "$v" || return
  w="$(expect_flags "$C3_R" 3 "$v")"
  [[ -z "$w" ]] && w="$(expect_places_ef "$C3_R" "$v" "$C3_S/_workspace_x")"
  [[ -n "$w" ]] && { VARIANT_WHY="[설계] $w"; return; }
  # ⑤′ 의 상대경로도 표기와 무관해야 한다 — 저장소 기준 `.claude/*` 는 classify 가 뺀다.
  v="$typed/T/.claude/notes.txt"
  edit_new "$C3_R" "$v" || return
  w="$(expect_flags "$C3_R" 0 "$v")"
  [[ -n "$w" ]] && VARIANT_WHY="[저장소 기준 .claude/*] $w"
}
VARIANT_WHY=''

e23() { # H-C — 슬롯 값의 대소문자가 디스크와 달라도(대소문자 무시 볼륨) 같은 폴더다.
        # 문자열 접두로 비교하면 git 최상위(디스크 표기)가 "밖"이 되어 ⑤′·설계 OR 이
        # 알림 없이 꺼진다. 세션 루트 제외도 같은 판정이어야 한다(모듈 단위로 확인).
        # 판별력: macOS 기본 APFS 에서만. 대소문자를 구분하는 볼륨은 계약만 확인한다.
  local name='e23 슬롯 값 대소문자가 디스크와 다름 → 같은 폴더(대소문자 무시 볼륨)'
  local why=''
  variant_fixture e23 Slot slot || { report "$name" ''; return; }
  variant_expect "$C3_F/slot"
  why="$VARIANT_WHY"
  if [[ -z "$why" && "$C3_F/slot" -ef "$C3_S" ]]; then
    mkdir -p "$C3_S/root/x"
    run_module '
EXTRA_GATE_DIR="$FIX/Slot"
is_slot_entry "$FIX/Slot/root/x/a.go" "$FIX/slot/root"; echo "rootx=$?"
is_slot_entry "$FIX/slot/T/a.go" "$FIX/Slot/root"; echo "slotin=$?"' FIX="$C3_F"
    [[ "$(flat "$OUT")" == 'rootx=1 slotin=0' ]] \
      || why="표기가 다른 세션 루트 제외 [$(flat "$OUT")] (기대 rootx=1 slotin=0)"
  fi
  report "$name" "$why"
}

e24() { # H-C — 슬롯 값이 NFC 한글인데 디스크 이름이 NFD 여도(정규화 무시 볼륨) 같은
        # 폴더다. git 최상위는 디스크 표기(NFD)로 온다.
        # 판별력: macOS APFS 에서만. 정규화를 구분하는 볼륨은 계약만 확인한다.
  local name='e24 슬롯 값 NFC · 디스크 NFD → 같은 폴더(정규화 무시 볼륨)' why=''
  local nfc nfd
  nfc="$(python3 -c 'import unicodedata as u; print(u.normalize("NFC", "트랙"))')"
  nfd="$(python3 -c 'import unicodedata as u; print(u.normalize("NFD", "트랙"))')"
  [[ -n "$nfc" && "$nfc" != "$nfd" ]] \
    || { DID_RUN=1; FIXTURE_FAIL='NFC/NFD 문자열'; report "$name" ''; return; }
  variant_fixture e24 "$nfd" "$nfc" || { report "$name" ''; return; }
  variant_expect "$C3_F/$nfc"
  why="$VARIANT_WHY"
  report "$name" "$why"
}
