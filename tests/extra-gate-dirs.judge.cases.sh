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
