#!/usr/bin/env bash
# mark-needs-audit.cases.sh — 경로 → 판정 **계약 표**. 이 파일이 계약의 기계 정본이다.
#
# 실행 파일이 아니라 mark-needs-audit.test.sh 가 source 하는 조각이다. 러너·픽스처·assert
# 헬퍼는 전부 거기 있고, 여기에는 계약 표만 둔다 — 한 파일에 다 넣으면 800줄을 넘어
# 표를 계획서와 대조하기가 어려워진다.
#
# 여기서 쓰는 것(정의는 러너 쪽): new_project · new_harness_repo · new_symlinked_project ·
# new_dir · mkfile · run_hook · run_hook_raw · run_static_check · fixture_broken ·
# check_case · TOK_* · EMPTY_STATE
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

# 러너를 거치지 않고 직접 돌리면 헬퍼가 하나도 없어 전 케이스가 조용히 무판정이 된다.
# 조용한 위음성을 막으려고 fail-closed 로 세운다.
if [ -z "${TOK_NEWLINE-}" ]; then
  echo "✗ 이 파일은 단독 실행용이 아닙니다. ./tests/mark-needs-audit.test.sh 를 실행하세요" >&2
  exit 1
fi

# --- 케이스 --------------------------------------------------------------
# 번호는 고정이다. 새 케이스는 **뒤에만** 붙인다 (리뷰 대조가 깨지므로 재배열 금지).
# 각 케이스 주석에 그 행이 지키는 축과 같은 축을 지키는 다른 행을 적는다. "비차별" 표시는
# 기존 두 판 어느 쪽에서도 빨개지지 않는 행 — 결함 증명은 못 해도 새 계약을 고정한다.
# === A. 프로젝트 안 =======================================================

case_01() { # 기준선 — 프로젝트 안 코드는 게이트 4종, 값은 상대경로.
  local p; p="$(new_project)"
  mkfile "$p/src/app.ts"
  run_hook "$p" "$p/src/app.ts"
  check_case '01 프로젝트 안 소스 → 게이트 4종(상대경로)' 0 gate 'src/app.ts'
}

case_02() { # 순수 문서 제외.
  local p; p="$(new_project)"
  mkfile "$p/README.md"
  run_hook "$p" "$p/README.md"
  check_case '02 프로젝트 안 README.md → 스킵' 0 none ''
}

case_03() { # D3-5 대소문자 무관. 5단계 *.md 축의 대문자 쪽.
            # 같은 대소문자 축의 3단계(듀얼) 쪽은 케이스 55 가 잡는다.
  local p; p="$(new_project)"
  mkfile "$p/README.MD"
  run_hook "$p" "$p/README.MD"
  check_case '03 프로젝트 안 README.MD(대문자) → 스킵' 0 none ''
}

case_04() { # _workspace/ 는 스크래치 — 설계·계획 파일명이 아니면 아무 플래그도 안 선다.
  local p; p="$(new_project)"
  mkfile "$p/_workspace/notes.md"
  run_hook "$p" "$p/_workspace/notes.md"
  check_case '04 프로젝트 안 _workspace/notes.md → 스킵' 0 none ''
}

case_05() { # D2 설계 산출물 — 듀얼리뷰만. 기록값은 프로젝트 상대경로.
  local p; p="$(new_project)"
  mkfile "$p/_workspace/00_design.md"
  run_hook "$p" "$p/_workspace/00_design.md"
  check_case '05 프로젝트 안 설계 문서 → 듀얼리뷰만(상대경로)' 0 dual '_workspace/00_design.md'
}

case_06() { # D2 계획 산출물 — 01_plan 축.
  local p; p="$(new_project)"
  mkfile "$p/_workspace/01_plan.v2.md"
  run_hook "$p" "$p/_workspace/01_plan.v2.md"
  check_case '06 프로젝트 안 계획 문서 → 듀얼리뷰만(상대경로)' 0 dual '_workspace/01_plan.v2.md'
}

case_07() { # 순서계약 (나) — .claude/* 제외가 하네스 앵커보다 **먼저**.
            # 먼저가 아니면 프로젝트에 설치된 소비 사본이 게이트를 세운다.
            # 같은 축: 케이스 24(정본 저장소가 자기 자신에 설치한 사본).
  local p; p="$(new_project)"
  mkfile "$p/.claude/settings.json"
  run_hook "$p" "$p/.claude/settings.json"
  check_case '07 설치된 글루 .claude/settings.json → 스킵' 0 none ''
}

case_08() { # 비블로킹 1 — 글롭 과대. 프로젝트 안의 평범한 src/agents/ 는 하네스가 아니다.
  local p; p="$(new_project)"
  mkfile "$p/src/agents/README.md"
  run_hook "$p" "$p/src/agents/README.md"
  check_case '08 프로젝트 안 src/agents/README.md → 스킵(오탐 금지)' 0 none ''
}

case_09() { # 비블로킹 1 — node_modules 안의 skills/*.md 도 하네스가 아니다.
  local p; p="$(new_project)"
  mkfile "$p/node_modules/p/skills/a.md"
  run_hook "$p" "$p/node_modules/p/skills/a.md"
  check_case '09 node_modules/*/skills/a.md → 스킵(오탐 금지)' 0 none ''
}

case_10() { # B2 정규화 — .. 로 .claude/ 를 빠져나온 경로. 정규화가 없으면 .claude/* 스킵에 먹힌다.
            # 같은 축: 케이스 11·12(심링크)·47(듀얼 쪽 .. 복귀). 픽스처 의존: mkfile 의
            # mkdir -p "$p/.claude/../src" 가 .. 앞 컴포넌트 .claude 를 실제로 만든다(실측 확인).
  local p; p="$(new_project)"
  mkfile "$p/.claude/../src/b.ts"
  run_hook "$p" "$p/.claude/../src/b.ts"
  check_case '10 .claude/../src/b.ts → 게이트 4종(정규화 후 src/b.ts)' 0 gate 'src/b.ts'
}

case_11() { # B2 심링크 — PROJECT_DIR 이 심링크, 편집 경로는 물리.
            # 정규화가 없으면 접두사가 안 맞아 "밖"으로 새고, 새는 방향에 따라
            # 오기록(app/.claude/settings.json)이나 무기록이 된다.
  local repo; repo="$(new_symlinked_project)"
  mkfile "$repo/app/.claude/settings.json"
  run_hook "$repo/link" "$repo/app/.claude/settings.json"
  check_case '11 심링크 PROJECT_DIR + 설치 글루 → 스킵' 0 none ''
}

case_12() { # B2 심링크 — 값 축. 기록값이 app/src/app.ts 로 새면 안 된다.
  local repo; repo="$(new_symlinked_project)"
  mkfile "$repo/app/src/app.ts"
  run_hook "$repo/link" "$repo/app/src/app.ts"
  check_case '12 심링크 PROJECT_DIR + 소스 → 게이트 4종(src/app.ts)' 0 gate 'src/app.ts'
}

case_13() { # 상대경로 입력의 절대화. 같은 축의 듀얼 쪽은 케이스 46.
            # 비차별 — 고정하는 계약은 "상대 입력도 프로젝트 기준으로 판정한다".
  local p; p="$(new_project)"
  mkfile "$p/src/app.ts"
  run_hook "$p" 'src/app.ts'
  check_case '13 상대경로 입력 src/app.ts → 게이트 4종' 0 gate 'src/app.ts'
}

case_14() { # 중복 제거. 같은 파일을 두 번 편집해도 플래그는 한 줄이어야 한다.
            # 비차별 — 고정하는 계약은 grep -qxF 중복 제거.
  local p; p="$(new_project)"
  mkfile "$p/src/app.ts"
  run_hook "$p" "$p/src/app.ts"
  run_hook "$p" "$p/src/app.ts"
  check_case '14 같은 파일 2회 편집 → 플래그는 각 1줄' 0 gate 'src/app.ts'
}

case_15() { # .md 예외의 예외 — 하네스 앵커 아래 *.md 는 동작을 정의하므로 코드다.
            # 프로젝트 안에서 정본을 들고 있는 형태(하네스 저장소를 PROJECT_DIR 로 연 경우).
  local p; p="$(new_project)"
  mkfile "$p/template/.claude/agents/x.md"
  run_hook "$p" "$p/template/.claude/agents/x.md"
  check_case '15 template/.claude/agents/x.md → 게이트 4종' 0 gate 'template/.claude/agents/x.md'
}

# === B. 프로젝트 밖 — 하네스 정본 저장소 ==================================
# D1′: 루트에 template/.claude/ 가 있으면 그 저장소 **전체**를 프로젝트처럼 검사한다.
# 기록값은 절대경로(B4) — 프로젝트 쪽 동명 파일과 섞이지 않게.
case_16() { # D1′ 본체 — 정본 저장소의 최상위 코드. B4 절대경로.
            # 같은 축: 케이스 26(worktree)·27(중첩 클론)·48(global-agents).
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/scripts/check.sh"
  run_hook "$p" "$hr/scripts/check.sh"
  check_case '16 밖+정본 저장소 scripts/check.sh → 게이트 4종(절대경로)' 0 gate "$hr/scripts/check.sh"
}

case_17() { # 앵커 agents — 정본의 에이전트 정의.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/template/.claude/agents/plan-reviewer.md"
  run_hook "$p" "$hr/template/.claude/agents/plan-reviewer.md"
  check_case '17 밖+정본 template/.claude/agents/*.md → 게이트 4종(절대경로)' 0 gate "$hr/template/.claude/agents/plan-reviewer.md"
}

case_18() { # 앵커 skills.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/template/.claude/skills/foo/SKILL.md"
  run_hook "$p" "$hr/template/.claude/skills/foo/SKILL.md"
  check_case '18 밖+정본 template/.claude/skills/**/SKILL.md → 게이트 4종' 0 gate "$hr/template/.claude/skills/foo/SKILL.md"
}

case_19() { # 앵커 harness — 제0원칙 정본.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/template/.claude/harness/principles.md"
  run_hook "$p" "$hr/template/.claude/harness/principles.md"
  check_case '19 밖+정본 template/.claude/harness/*.md → 게이트 4종' 0 gate "$hr/template/.claude/harness/principles.md"
}

case_20() { # 앵커 settings.json — 확장자가 없는 앵커.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/template/.claude/settings.json"
  run_hook "$p" "$hr/template/.claude/settings.json"
  check_case '20 밖+정본 template/.claude/settings.json → 게이트 4종' 0 gate "$hr/template/.claude/settings.json"
}

case_21() { # 정본 저장소라도 순수 문서는 스킵 — 검사 범위가 무제한이 아님을 고정.
            # 비차별 — 5단계 *.md 스킵을 건드리는 변이는 케이스 02 에서 먼저 죽는다.
            # 이 행만의 몫은 "그 규칙이 4b-정본 스코프에도 그대로 적용된다"는 것뿐이다.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/docs/usage.md"
  run_hook "$p" "$hr/docs/usage.md"
  check_case '21 밖+정본 docs/usage.md → 스킵' 0 none ''
}

case_22() { # 정본 저장소의 _workspace/ 도 스크래치다.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/_workspace/scratch.md"
  run_hook "$p" "$hr/_workspace/scratch.md"
  check_case '22 밖+정본 _workspace/scratch.md → 스킵' 0 none ''
}

case_23() { # B1 본체 — 밖 설계 문서에도 듀얼리뷰 게이트가 선다. 같은 축: 케이스 34·35.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/_workspace/00_design.md"
  run_hook "$p" "$hr/_workspace/00_design.md"
  check_case '23 밖+정본 _workspace/00_design.md → 듀얼리뷰만(절대경로)' 0 dual "$hr/_workspace/00_design.md"
}

case_24() { # 순서계약 (나) — 정본 저장소가 **자기 자신에 설치한** 소비 사본은 스킵.
            # 정본(template/.claude/...)만 발화해야 한다. 같은 축: 케이스 07.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/.claude/hooks/x.sh"
  run_hook "$p" "$hr/.claude/hooks/x.sh"
  check_case '24 밖+정본의 자기 설치 사본 .claude/hooks/x.sh → 스킵' 0 none ''
}

case_25() { # D3-3 — .git/ 아래 편집은 **상위 저장소**로 귀속시킨다. 그러지 않으면 git 이 .git
            # 안에서 --show-toplevel 에 실패해(실측 rc=128) 판정 불가로 조용히 새어나간다.
            # 같은 축의 음성 쪽은 케이스 36.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/.git/hooks/pre-commit"
  run_hook "$p" "$hr/.git/hooks/pre-commit"
  check_case '25 밖+정본 .git/hooks/pre-commit → 게이트 4종(상위 저장소 귀속)' 0 gate "$hr/.git/hooks/pre-commit"
}

case_26() { # D1′ — worktree 도 정본이다. 마커(template/.claude/)가 커밋 트리에 실제로
            # 담겨야 성립하므로 make_harness_repo 가 실파일을 커밋한다(--allow-empty 금지).
  local p hr wtp wt; p="$(new_project)"; hr="$(new_harness_repo)"
  wtp="$(new_dir wt)"
  wt="$wtp/tree"
  git -C "$hr" worktree add --detach "$wt" >/dev/null 2>&1
  if [ ! -d "$wt/template/.claude" ]; then
    fixture_broken 'worktree 에 template/.claude 가 없다 (실커밋이 비었나?)'
  else
    mkfile "$wt/scripts/check.sh"
    run_hook "$p" "$wt/scripts/check.sh"
  fi
  check_case '26 밖+정본 worktree scripts/check.sh → 게이트 4종(절대경로)' 0 gate "$wt/scripts/check.sh"
}

case_27() { # D1′ — 남의 저장소 안에 중첩된 하네스 클론. 귀속은 **가장 안쪽** 저장소다.
            # 픽스처는 중첩 git init 으로 만든다(서브모듈 대체) — 훅은 --show-toplevel 만
            # 보므로 판정이 동일하고, protocol.file.allow 차단으로 CI 가 흔들리지 않는다.
  local p other; p="$(new_project)"; other="$(new_dir other)"
  git -C "$other" init -q
  mkdir -p "$other/vendor/harness"
  make_harness_repo "$other/vendor/harness"
  mkfile "$other/vendor/harness/scripts/check.sh"
  run_hook "$p" "$other/vendor/harness/scripts/check.sh"
  check_case '27 밖+중첩 하네스 클론 scripts/check.sh → 게이트 4종' 0 gate "$other/vendor/harness/scripts/check.sh"
}

# === C. 프로젝트 밖 — 하네스 정본 아님 ====================================

case_28() { # B3 순방향 — 남의 git 저장소의 평범한 파일에는 게이트를 세우지 않는다.
  local p other; p="$(new_project)"; other="$(new_dir other)"
  git -C "$other" init -q
  mkfile "$other/vimrc"
  run_hook "$p" "$other/vimrc"
  check_case '28 밖+비정본 저장소 vimrc → 스킵' 0 none ''
}

case_29() { # D1 — 비정본 저장소라도 .claude/ 앵커에 걸린 하네스 파일은 발화한다.
  local p other; p="$(new_project)"; other="$(new_dir other)"
  git -C "$other" init -q
  mkfile "$other/.claude/agents/x.md"
  run_hook "$p" "$other/.claude/agents/x.md"
  check_case '29 밖+비정본 .claude/agents/x.md → 게이트 4종(절대경로)' 0 gate "$other/.claude/agents/x.md"
}

case_30() { # 순서계약 (다) — 앵커 판정에 git 을 요구하지 않는다.
            # ~/.claude/agents/x.md 는 홈이 git 저장소가 아니어도 발화해야 한다.
  local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
  mkfile "$nogit/.claude/agents/x.md"
  run_hook "$p" "$nogit/.claude/agents/x.md"
  check_case '30 밖+git 아님 .claude/agents/x.md → 게이트 4종(절대경로)' 0 gate "$nogit/.claude/agents/x.md"
}

case_31() { # D1 B3 역방향 — HOME 예외를 삭제했으므로 홈 아래 하네스 파일도 발화한다.
            # HOME 을 픽스처로 주입해 "실제 홈"에 의존하지 않게 한다.
  local p home; p="$(new_project)"; home="$(new_dir home)"
  mkfile "$home/.claude/harness/principles.md"
  git -C "$home/.claude" init -q
  run_hook "$p" "$home/.claude/harness/principles.md" "HOME=$home"
  check_case '31 HOME 아래 .claude/harness/principles.md → 게이트 4종' 0 gate "$home/.claude/harness/principles.md"
}

case_32() { # D1 B3 순방향 — 홈 아래라도 하네스가 아니면 발화하지 않는다.
            # 케이스 31 과 짝. 둘이 같이 "홈이라서"가 아니라 "하네스라서" 발화함을 고정한다.
  local p home; p="$(new_project)"; home="$(new_dir home)"
  mkfile "$home/dotfiles/vimrc"
  git -C "$home/dotfiles" init -q
  run_hook "$p" "$home/dotfiles/vimrc" "HOME=$home"
  check_case '32 HOME 아래 dotfiles/vimrc → 스킵' 0 none ''
}

case_33() { # 저장소 밖 순수 임시 파일 — 발화하지 않는다.
            # 비차별 — 고정하는 계약은 "앵커도 정본도 아니면 밖은 건드리지 않는다".
            # 케이스 28·32 와 같은 축이고, 이 행만의 차별점은 git 저장소조차 아니라는 것.
            # 그래서 4b-else 를 겨냥한 변이는 여기 오기 전에 28·32 에서 죽는다.
  local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
  mkfile "$nogit/plain/file.ts"
  run_hook "$p" "$nogit/plain/file.ts"
  check_case '33 밖+git 아님 plain/file.ts → 스킵' 0 none ''
}

case_34() { # D2 본체 — **이 세션 형태**. _workspace/ 가 어느 git 저장소에도 속하지 않아도
            # 설계 문서 듀얼리뷰 게이트는 서야 한다. 같은 축: 케이스 23·35.
  local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
  mkfile "$nogit/_workspace/00_design.md"
  run_hook "$p" "$nogit/_workspace/00_design.md"
  check_case '34 밖+git 아님 _workspace/00_design.md → 듀얼리뷰만(절대경로)' 0 dual "$nogit/_workspace/00_design.md"
}

case_35() { # D2 — 01_plan 축.
  local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
  mkfile "$nogit/_workspace/01_plan.md"
  run_hook "$p" "$nogit/_workspace/01_plan.md"
  check_case '35 밖+git 아님 _workspace/01_plan.md → 듀얼리뷰만(절대경로)' 0 dual "$nogit/_workspace/01_plan.md"
}

case_36() { # D3-3 의 음성 쪽 — .git/ 귀속이 "무조건 발화"가 되면 안 된다.
            # 상위 저장소가 하네스가 아니면 스킵. 케이스 25 와 짝.
  local p other; p="$(new_project)"; other="$(new_dir other)"
  git -C "$other" init -q
  mkfile "$other/.git/hooks/pre-commit"
  run_hook "$p" "$other/.git/hooks/pre-commit"
  check_case '36 밖+비정본 .git/hooks/pre-commit → 스킵' 0 none ''
}

case_37() { # 귀속은 **가장 안쪽** 저장소. 정본 안에 박힌 남의 저장소는 정본이 아니다.
            # 케이스 27(안쪽이 정본)과 대칭.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkdir -p "$hr/vendor/inner"
  git -C "$hr/vendor/inner" init -q
  mkfile "$hr/vendor/inner/x.sh"
  run_hook "$p" "$hr/vendor/inner/x.sh"
  check_case '37 정본 안의 중첩 비정본 저장소 x.sh → 스킵' 0 none ''
}

# === D. 환경·실패 경로 (모든 행 rc=0 — PostToolUse 는 절대 차단하지 않는다) ===
case_38() { # 비블로킹 2 — GIT_DIR/GIT_WORK_TREE 오염 소거.
            # 오염이 살아 있으면 귀속 저장소가 $other 로 바뀌어 조용히 스킵된다.
  local p hr other; p="$(new_project)"; hr="$(new_harness_repo)"; other="$(new_dir other)"
  git -C "$other" init -q
  mkfile "$hr/scripts/check.sh"
  run_hook "$p" "$hr/scripts/check.sh" "GIT_DIR=$other/.git" "GIT_WORK_TREE=$other"
  check_case '38 GIT_DIR/GIT_WORK_TREE 오염 하 정본 편집 → 게이트 4종' 0 gate "$hr/scripts/check.sh"
}

case_39() { # 비블로킹 4 — HOME 미설정에서도 정상 동작 + stderr 공백. 구판이 여기서 빨간 이유는
            # HOME 참조 때문이 아니다(거기 닿기 전에 끝난다) — rev-parse 실패로 스킵해
            # 플래그가 안 서기 때문이다(실측). 같은 축의 정적 쪽: 케이스 54.
  local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
  mkfile "$nogit/.claude/agents/x.md"
  run_hook "$p" "$nogit/.claude/agents/x.md" -u HOME
  check_case '39 HOME 미설정 + 밖 하네스 파일 → 게이트 4종, stderr 공백' 0 gate "$nogit/.claude/agents/x.md"
}

case_40() { # 비블로킹 6 — 플래그 쓰기 실패를 묵살하지 않는다.
            # 차단(exit 2)은 PostToolUse 계약상 불가하므로 systemMessage 로 알린다.
            # root 로 돌면 chmod 500 이 무력하므로 조용히 통과시키지 않고 빨갛게 만든다.
  local p; p="$(new_project)"
  mkfile "$p/src/app.ts"
  chmod 500 "$p/.claude"
  # 중괄호가 필요하다: 리다이렉트 **열기** 실패는 셸이 보고하는데, 명령 뒤에 붙인
  # 2>/dev/null 은 그 시점에 아직 적용되지 않아 러너 자신의 stderr 가 샌다(실측).
  if { : > "$p/.claude/.probe"; } 2>/dev/null; then
    rm -f "$p/.claude/.probe"
    chmod u+rwX "$p/.claude"
    fixture_broken 'chmod 500 후에도 .claude 에 쓸 수 있다 (root 로 실행 중?)'
  else
    run_hook "$p" "$p/src/app.ts"
    chmod u+rwX "$p/.claude"
  fi
  check_case '40 .claude 쓰기 불가 → 무기록 + systemMessage 1줄' 0 none '' "$TOK_WRITE_FAIL"
}

case_41() { # 깨진 입력 무해 — file_path 키가 없다.
            # 비차별 — 고정하는 계약은 "입력이 비면 rc=0 + stderr 공백 + 무기록"이다.
            # 조기종료 [ -z "$file_path" ] && exit 0 **자체**는 이 행이 못 붙든다:
            # 그 줄을 지워도 빈 경로가 아래 분기를 무해하게 통과해 등가 변이가 된다(실측).
  local p; p="$(new_project)"
  run_hook_raw "$p" '{"tool_input":{}}'
  check_case '41 payload 에 file_path 없음 → 무변화' 0 none ''
}

case_42() { # 깨진 입력 무해 — JSON 이 아니다. json_get 이 죽어도 훅은 조용해야 한다.
            # 비차별 — 고정하는 계약은 stderr 공백 + rc 0. 케이스 41 과 마찬가지로
            # 조기종료 줄 자체는 못 붙든다(등가 변이).
  local p; p="$(new_project)"
  run_hook_raw "$p" 'not json at all'
  check_case '42 payload 가 JSON 이 아님 → 무변화' 0 none ''
}

case_43() { # 탈출구 HARNESS_HOOKS=off. run_hook 이 기본으로 소거하므로 여기서만 재주입한다.
            # 비차별 — 고정하는 계약은 "탈출구가 실제로 먹힌다".
  local p; p="$(new_project)"
  mkfile "$p/src/app.ts"
  run_hook "$p" "$p/src/app.ts" HARNESS_HOOKS=off
  check_case '43 HARNESS_HOOKS=off → 무변화' 0 none ''
}

case_44() { # 탈출구 ECC_DISABLED_HOOKS — 훅 id 단위.
            # 비차별 — 고정하는 계약은 id 별 비활성이 이 훅에 걸린다는 것.
  local p; p="$(new_project)"
  mkfile "$p/src/app.ts"
  run_hook "$p" "$p/src/app.ts" ECC_DISABLED_HOOKS=post:edit:needs-audit
  check_case '44 ECC_DISABLED_HOOKS=post:edit:needs-audit → 무변화' 0 none ''
}

case_45() { # 개행 축의 기준선 — basename 안의 **중간** 개행. 확장자를 .ts 로 두는 이유:
            # 가드가 없으면 게이트가 서는 경로여야 "플래그가 2줄로 쪼개져 오염된다"가 드러난다.
            # 이 행은 순서계약 (라)를 **못** 붙든다(실측 정정): basename 안의 개행은 명령
            # 치환·정규화를 통과해 살아남으므로 가드를 정규화 뒤로 옮겨도 여전히 잡힌다.
            # (라)를 실제로 붙드는 것은 케이스 57(디렉토리 컴포넌트 개행)이고,
            # 값 획득 시점의 개행 소실은 케이스 56(후행 개행)이 붙든다.
  local p fp; p="$(new_project)"
  fp="$p/src/we
ird.ts"
  mkfile "$fp"
  run_hook "$p" "$fp"
  check_case '45 경로 중간에 개행 → 무기록 + systemMessage 1줄' 0 none '' "$TOK_NEWLINE"
}

# === E. 2차 검증에서 추가된 행 ============================================

case_46() { # 순서계약 (가) — 듀얼 판정은 정규화 **뒤**.
            # 상대 입력에는 선행 / 가 없어 */_workspace/... 글롭에 안 걸린다.
            # 정규화를 지우면 이 행이 스킵으로 무너진다. 같은 축의 값 쪽: 케이스 47.
            # 비차별 — 고정하는 계약은 "듀얼 판정 전에 절대화한다".
  local p; p="$(new_project)"
  mkfile "$p/_workspace/01_plan.md"
  run_hook "$p" '_workspace/01_plan.md'
  check_case '46 상대경로 입력 _workspace/01_plan.md → 듀얼리뷰만' 0 dual '_workspace/01_plan.md'
}

case_47() { # 순서계약 (가) — 기록값 축. 듀얼 판정을 정규화 앞으로 되돌리면 판정은 살아도
            # 기록값이 .claude/../_workspace/00_design.md 가 되어 여기서 잡힌다. 픽스처 의존:
            # mkdir -p "$p/.claude/../_workspace" 가 .. 앞 컴포넌트 .claude 를 만든다(실측 확인).
  local p; p="$(new_project)"
  mkfile "$p/.claude/../_workspace/00_design.md"
  run_hook "$p" "$p/.claude/../_workspace/00_design.md"
  check_case '47 .claude/../_workspace/00_design.md → 듀얼리뷰만(정규화된 값)' 0 dual '_workspace/00_design.md'
}

case_48() { # H1 — global-agents/ 는 전역 에이전트 **정본**이고 install/sync 가 배포한다.
            # 정본 저장소 스코프 안에서만 .md 예외의 예외를 연다. 경계는 케이스 49 가 고정.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/global-agents/research-collector.md"
  run_hook "$p" "$hr/global-agents/research-collector.md"
  check_case '48 밖+정본 global-agents/*.md → 게이트 4종(절대경로)' 0 gate "$hr/global-agents/research-collector.md"
}

case_49() { # H1 경계 — 정본이 아닌 프로젝트의 global-agents/ 는 그냥 문서다. 이 행이 없으면
            # 예외가 남의 프로젝트로 샌다. 비차별 — 계약은 "예외는 정본 스코프 한정".
  local p; p="$(new_project)"
  mkfile "$p/global-agents/x.md"
  run_hook "$p" "$p/global-agents/x.md"
  check_case '49 비정본 프로젝트의 global-agents/x.md → 스킵' 0 none ''
}

case_50() { # H1 — CLAUDE_PROJECT_DIR 자신이 정본인 경우. 프로젝트 안 경로(4a)와 밖-정본
            # 경로(4b)의 스코프가 **같은 규칙**인지 고정한다. 안 경로이므로 기록값은 상대경로.
  local pc; pc="$(new_harness_repo)"
  mkfile "$pc/global-agents/x.md"
  run_hook "$pc" "$pc/global-agents/x.md"
  check_case '50 PROJECT_DIR 자신이 정본 + global-agents/x.md → 게이트 4종(상대경로)' 0 gate 'global-agents/x.md'
}

case_51() { # M1 — physical_path 실패는 fail-loud. 스킵하지 않고 원본 경로로 판정을 잇는다.
            # **픽스처 기본계약 2의 유일한 예외**: 부모 디렉토리를 일부러 만들지 않는다.
            # 소음도 없다(stdout 공백). 비차별 — 계약은 "정규화 실패 시 조용히 스킵 금지".
  local p; p="$(new_project)"
  run_hook "$p" "$p/nonexistent-dir/app.ts"
  check_case '51 부모 디렉토리 없음 → 게이트 4종(원본 경로), stdout 공백' 0 gate 'nonexistent-dir/app.ts'
}

case_52() { # M5 — 접두사 판정에 슬래시가 빠지면 형제 디렉토리를 프로젝트 안으로 오인해
            # 기록값이 -backup/src/a.ts 가 된다. 비차별 — 계약은 "접두사는 <proj>/ 로 본다".
  local p; p="$(new_project)"
  mkfile "${p}-backup/src/a.ts"
  run_hook "$p" "${p}-backup/src/a.ts"
  check_case '52 형제 디렉토리 <proj>-backup/src/a.ts → 스킵' 0 none ''
}

case_53() { # M6 — 값이 - 로 시작하면 grep 이 옵션으로 해석한다.
            # -- 가 없으면 grep -qxF --version 이 되어 rc=0(=이미 있음)로 미기록이 되고,
            # BSD grep 은 -q 아래서도 버전 문자열을 stdout 에 뱉는다(실측). 두 축에서 잡힌다.
  local p; p="$(new_project)"
  mkfile "$p/--version"
  run_hook "$p" "$p/--version"
  check_case '53 파일명이 --version → 게이트 4종, stdout 공백' 0 gate '--version'
}

case_54() { # H2 — HOME 재도입 금지를 정적으로 고정한다. 런타임 쪽은 케이스 39. 변수 **참조**만
            # 금지한다: 산문 주석의 HOME 은 허용해야 홈 예외 삭제 사유를 주석으로 쓸 수 있다.
  run_static_check '훅 본문이 HOME 변수를 참조한다 (홈 예외는 삭제됐다)' '\$\{?HOME'
  check_case '54 정적: 훅이 HOME 변수를 참조하지 않는다' 0 none ''
}

case_55() { # 3단계 대소문자 축 — 듀얼 매칭은 소문자화해 비교하되 **기록은 원본 대소문자**로.
            # 소문자화를 빼도 05·06·23·34·35·46·47 이 전부 통과해 계약이 무방비가 된다.
            # 5단계 쪽 대소문자 축은 케이스 03 이 잡는다.
  local p; p="$(new_project)"
  mkfile "$p/_workspace/00_Design.md"
  run_hook "$p" "$p/_workspace/00_Design.md"
  check_case '55 _workspace/00_Design.md(대문자) → 듀얼리뷰만(원본 대소문자로 기록)' 0 dual '_workspace/00_Design.md'
}

# === F. 3중 검수에서 추가된 행 ============================================
# 전부 "변이가 살아남았다"는 실측에서 나왔다 — 즉 이 행들이 없으면 해당 계약을
# 지우거나 완화해도 나머지 전 행이 초록이다.

case_56() { # 개행 축 — **후행** 개행. json_get 은 print() 로 내고 훅은 그 결과를 받는데,
            # 명령 치환은 후행 개행을 **전부** 지운다. 그래서 가드에 닿기도 전에 값이
            # src/app.ts 로 조용히 변조돼 **다른 파일**이 게이트에 박힌다. 훅이 센티널로
            # 받아 원본 개행을 보존해야만 초록이 된다. 같은 축: 케이스 45·57.
  local p; p="$(new_project)"
  mkfile "$p/src/app.ts"
  run_hook "$p" "$p/src/app.ts
"
  check_case '56 경로 끝에 개행 → 무기록 + systemMessage 1줄' 0 none '' "$TOK_NEWLINE"
}

case_57() { # 순서계약 (라)를 **실제로** 붙드는 행 — 디렉토리 컴포넌트가 개행으로 끝난다.
            # 가드를 정규화 뒤로 옮기면 pwd -P 출력의 후행 개행이 명령 치환에 먹혀 abs 가
            # $PROJ/sr/app.ts 로 조용히 바뀐다 → 존재하지 않는 파일이 게이트에 박히고
            # 정작 편집한 파일은 무게이트. 케이스 45 는 이 변이를 못 잡는다(그 주석 참조).
  local p fp; p="$(new_project)"
  fp="$p/sr
/app.ts"
  mkfile "$fp"
  run_hook "$p" "$fp"
  check_case '57 디렉토리 컴포넌트 끝 개행 → 무기록 + systemMessage 1줄' 0 none '' "$TOK_NEWLINE"
}

case_58() { # 플래그 **누적**과 grep -qxF 의 -x 를 한 행으로 붙든다. 값 두 개를 부분 문자열
            # 관계로 잡았다(app.ts ⊂ src/lib/app.ts). 긴 쪽을 먼저 넣는 순서가 계약이다:
            #   record_flag 의 >> 를 > 로 → 둘째가 첫째를 덮어 1줄
            #   grep -qxF 에서 -x 를 빼면 → 둘째가 부분 일치로 "이미 있음" 오판, 1줄
            # 둘 다 에러도 stderr 도 없이 조용하다 — 이 훅이 막으려는 결함 유형 그 자체다.
            # 케이스 14(같은 값 2회)는 중복 제거에 걸려 두 번째 쓰기 자체가 안 일어나므로
            # 누적을 못 붙든다. -- 축은 케이스 53.
            # 비차별(a·b 양판 GREEN) — 두 구판도 >> 와 -x 는 갖고 있었다. 이 행이
            # 고정하는 것은 그 둘이 앞으로도 유지된다는 계약이다.
  local p; p="$(new_project)"
  mkfile "$p/src/lib/app.ts"
  mkfile "$p/app.ts"
  run_hook "$p" "$p/src/lib/app.ts"
  run_hook "$p" "$p/app.ts"
  check_case '58 서로 다른 두 파일 편집 → 각 플래그에 2줄(순서까지)' 0 gate 'src/lib/app.ts
app.ts'
}

case_59() { # 앵커 hooks — 앵커 목록에서 */.claude/hooks/* 만 지워도 나머지 전 행이 초록이다.
            # 정본의 template/.claude/hooks/*.md 는 앵커가 빠지면 5단계 *.md 로 스킵된다.
            # 놓치던 시나리오: 하네스 훅을 별도 클론에서 고치는데 게이트가 안 서는 것 —
            # 2026-08-04 원 사고와 같은 계열이다. 다른 깊이의 같은 앵커는 케이스 64.
  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
  mkfile "$hr/template/.claude/hooks/x.md"
  run_hook "$p" "$hr/template/.claude/hooks/x.md"
  check_case '59 밖+정본 template/.claude/hooks/x.md → 게이트 4종(절대경로)' 0 gate "$hr/template/.claude/hooks/x.md"
}

case_60() { # 앵커 settings.json — 이 앵커도 지워도 나머지 전 행이 초록이었다. git 저장소가
            # **아닌** 곳에 두어야 잡힌다: 케이스 20 은 정본 스코프라 앵커가 없어도 기본값
            # (확장자가 .md 가 아님)으로 게이트가 서서 못 잡는다. 앵커가 빠지면 4b-else 로
            # 떨어져 스킵된다. 놓치던 시나리오: 남의 프로젝트 .claude/settings.json 편집.
  local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
  mkfile "$nogit/.claude/settings.json"
  run_hook "$p" "$nogit/.claude/settings.json"
  check_case '60 밖+git 아님 .claude/settings.json → 게이트 4종(절대경로)' 0 gate "$nogit/.claude/settings.json"
}

case_61() { # 정본 마커의 음성 짝 — 마커는 template/.claude/ 이지 template/ 이 아니다.
            # [ -d "$1/template" ] 로 완화해도 나머지 전 행이 초록이었다. 완화하면 루트에
            # template/ 을 둔 평범한 스캐폴딩·웹 저장소가 **통째로** 게이트 대상이 된다.
            # 계획 3.3 이 감수한 오탐은 "template/ 밑에 .claude/ 를 둔" 경우까지였다.
            # 양성 쪽: 케이스 16·26·27.
  local p tpl; p="$(new_project)"; tpl="$(new_dir tplrepo)"
  git -C "$tpl" init -q
  mkfile "$tpl/template/index.html"
  mkfile "$tpl/scripts/x.sh"
  run_hook "$p" "$tpl/scripts/x.sh"
  check_case '61 밖+template/ 만 있고 template/.claude/ 없음 → 스킵' 0 none ''
}

case_62() { # git 호출 실패를 조용히 넘기지 않는다. rev-parse 가 빈 값을 돌려줬는데 조상에
            # .git 이 있으면 "저장소가 아님"이 아니라 "git 이 거부함"이다(safe.directory
            # dubious-ownership·권한·손상). 그대로 두면 정본 저장소 전체가 앵커 밖 파일에
            # 대해 무게이트 + **무신호**가 된다. 판정은 기존대로 앵커 전용을 유지하고
            # stdout 으로만 알린다 — PostToolUse 는 차단할 수 없다. physical_path 가
            # fail-loud 인데(케이스 51) 여기만 fail-silent 인 비대칭을 없앤다.
            # dubious-ownership 은 다른 uid 가 필요하므로 등가 경로(.git 접근 불가)로 만든다.
            # root 로 돌면 chmod 000 이 무력하므로 조용히 통과시키지 않고 빨갛게 만든다.
  local p gr; p="$(new_project)"; gr="$(new_dir gitbroken)"
  git -C "$gr" init -q
  mkfile "$gr/scripts/x.sh"
  chmod 000 "$gr/.git"
  if git -C "$gr/scripts" rev-parse --show-toplevel >/dev/null 2>&1; then
    chmod u+rwX "$gr/.git"
    fixture_broken '.git 를 읽기 불가로 만들어도 rev-parse 가 성공한다 (root 로 실행 중?)'
  else
    run_hook "$p" "$gr/scripts/x.sh"
    chmod u+rwX "$gr/.git"
  fi
  check_case '62 조상 .git 접근 불가 → 스킵 + systemMessage 1줄' 0 none '' "$TOK_GIT_UNAVAILABLE"
}

case_63() { # _workspace/* 스킵이 장식이 아님을 고정한다. 그 줄을 통째로 지워도 나머지 전
            # 행이 초록이었다 — 케이스 04·22 가 둘 다 .md 라 5단계 *.md 스킵이 먼저 먹기
            # 때문이다. 놓치던 시나리오: _workspace/codex-planreview.log·_workspace/tmp.sh
            # 같은 스크래치에 게이트 4종이 서고, 지우려면 감사자를 돌려야 한다.
            # 비차별(a·b 양판 GREEN) — 두 구판도 _workspace/* 를 스킵했다.
  local p; p="$(new_project)"
  mkfile "$p/_workspace/scratch.sh"
  run_hook "$p" "$p/_workspace/scratch.sh"
  check_case '63 프로젝트 안 _workspace/scratch.sh → 스킵' 0 none ''
}

case_64() { # **의도된 오탐**의 명문화. classify 의 .claude/* 제외는 rel 선두에만 걸리는데
            # harness_anchor 는 */.claude/hooks/* 로 모든 깊이에 걸린다 → 최상위 .claude/ 는
            # 스킵(케이스 07)인데 모노레포 하위 .claude/ 는 발화한다. 피해 방향이 오탐이고
            # 탈출구(ECC_DISABLED_HOOKS)가 있어 감수한다. 이 행이 없으면 다음 사람이 이
            # 비대칭을 의도인지 사고인지 구분할 수 없다.
            # 비차별(a·b 양판 GREEN) — 이 오탐은 두 구판에도 있었다. 새로 만든 게 아니라
            # 유지하기로 **결정**한 것임을 남긴다.
  local p; p="$(new_project)"
  mkfile "$p/packages/app/.claude/hooks/x.sh"
  run_hook "$p" "$p/packages/app/.claude/hooks/x.sh"
  check_case '64 모노레포 하위 .claude/hooks/x.sh → 게이트 4종(의도된 오탐)' 0 gate 'packages/app/.claude/hooks/x.sh'
}

case_65() { # 확장자 축의 .markdown 쪽. *.md|*.markdown 을 *.md 로 좁혀도 나머지 전 행이
            # 초록이었다 — README.markdown 오탐을 아무도 안 잡는다. 대소문자 축은 케이스 03.
            # 비차별(a·b 양판 GREEN) — 두 구판도 *.markdown 을 스킵했다.
  local p; p="$(new_project)"
  mkfile "$p/README.markdown"
  run_hook "$p" "$p/README.markdown"
  check_case '65 프로젝트 안 README.markdown → 스킵' 0 none ''
}

case_66() { # 듀얼 글롭의 접미사 축 — 00_design* 쪽. 케이스 06 이 01_plan.v2.md 로 01 축만
            # 덮고 있어, 00_design*.md 를 00_design.md 로 좁혀도 안 죽었다. 좁히면 이 행이
            # 듀얼이 아니라 _workspace/* 스킵으로 무너진다.
            # 비차별(a·b 양판 GREEN) — 두 구판도 00_design* 글롭을 갖고 있었다.
  local p; p="$(new_project)"
  mkfile "$p/_workspace/00_design.v2.md"
  run_hook "$p" "$p/_workspace/00_design.v2.md"
  check_case '66 프로젝트 안 _workspace/00_design.v2.md → 듀얼리뷰만' 0 dual '_workspace/00_design.v2.md'
}

# === G. PR 점검(C1)에서 추가된 행 — 물리 경로 정규화 축 ====================
# 전부 physical_path 를 겨냥한다. 케이스 10·11·12 는 이 축을 **부분만** 덮고 있었다:
#   10 — `..` 가 있지만 심링크가 없다 → 논리 cd 로도 답이 같다
#   11·12 — 심링크가 있지만 `..` 가 없다 → 논리 cd 로도 답이 같다
# 논리 cd 와 물리 cd 가 갈리는 지점은 **둘이 겹칠 때**뿐이다: 논리 cd 는 `심링크/..` 를
# 심링크를 따라가기 **전에** 문자로 상쇄하므로 커널이 실제로 여는 곳과 다른 답을 낸다
# (실측: `cd -- /var/..` → `/`, `cd -P -- /var/..` → `/private`).
# 마지막 성분이 `.`·`..` 인 축(69·70)은 형제 검사기 scripts/check-rule-copies.sh 가
# PR #13 에서 이미 고친 같은 이름의 버그다 — 두 함수가 같은 방식이어야 한다.
#
# 픽스처 기본계약 1의 예외: 이 두 행(67·68)은 심링크를 **의도적으로** 만든다.

case_67() { # `심링크/..` 로 프로젝트를 빠져나간 편집 — 밖 파일이 **안 상대경로로 기록**되면 안 된다.
            # 링크가 프로젝트 밖을 가리키므로 물리 해석은 $outside/secret.ts(=밖)이고,
            # 논리 해석은 $p/secret.ts(=안)다. `-P` 가 빠지면 후자가 되어 게이트는 서지만
            # **존재하지도 않는 프로젝트 안 파일** secret.ts 가 박힌다 — 감사자가 엉뚱한
            # 파일을 보고 통과시키는 조용한 위양성. 에러도 stderr 도 없다.
            # 값 축(밖인데 무게이트가 되는 반대 방향)은 케이스 68.
  local p outside; p="$(new_project)"; outside="$(new_dir outside)"
  mkdir -p "$outside/target"
  mkfile "$outside/secret.ts"
  ln -s "$outside/target" "$p/link"
  run_hook "$p" "$p/link/../secret.ts"
  check_case '67 프로젝트 밖을 가리키는 심링크/.. 편집 → 스킵(안 상대경로로 오기록 금지)' 0 none ''
}

case_68() { # 케이스 67 의 반대 방향 — 물리 해석이 밖 **하네스 앵커**를 가리킨다.
            # 논리 해석은 $p/agents/x.md 로 접혀 프로젝트 안의 평범한 문서(5단계 *.md)가
            # 되어 **스킵**된다 → 하네스 파일 편집에 게이트가 통째로 사라진다(위음성).
            # 67 이 오기록을, 이 행이 무기록을 붙든다. 기록값이 절대경로인 것도 함께 고정.
            #
            # 디코이 $p/agents/ 가 **필수**다(실측). 논리 cd 는 정규화한 경로가 존재하지
            # 않으면 **원본 문자열로 재시도**하는데, 그러면 심링크를 따라가 물리 cd 와 같은
            # 답이 나와 이 행이 비차별로 죽는다. 디코이를 지우면 구판에서도 초록이 된다.
  local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
  mkfile "$nogit/.claude/agents/x.md"
  mkfile "$p/agents/x.md"
  ln -s "$nogit/.claude/agents" "$p/link"
  run_hook "$p" "$p/link/../agents/x.md"
  check_case '68 심링크/.. 로 밖 하네스 앵커 → 게이트 4종(절대경로)' 0 gate "$nogit/.claude/agents/x.md"
}

case_69() { # 마지막 성분이 `..` — 호출부가 dirname/basename 으로 쪼개 넘기면 `..` 는
            # basename 쪽으로 가고 basename 은 물리화되지 않아 **안 풀린 채** 남는다.
            # 그러면 프로젝트 루트 자신을 가리키는 경로가 상대경로 `src/..` 로 접두사에
            # 걸려 게이트가 서고, 플래그에 디렉토리 표기가 박힌다. 정규화하면 $p 자신이라
            # 접두사(<proj>/)에 안 걸려 밖으로 떨어지고, 앵커도 정본도 아니므로 스킵이다.
            # **픽스처 기본계약 2의 예외**: 편집 경로가 디렉토리라 파일을 만들지 않는다.
            # mkdir 이 실패해도 조용히 초록이 되지 않는다 — cd 가 실패하면 원본이 그대로
            # 나와 `src/..` 게이트가 서므로 이 행이 빨개진다(fail-closed).
            # `.` 쪽 거울상은 케이스 70.
  local p; p="$(new_project)"
  mkdir -p "$p/src"
  run_hook "$p" "$p/src/.."
  check_case '69 마지막 성분이 .. → 스킵(정규화하면 프로젝트 루트 자신)' 0 none ''
}

case_70() { # 케이스 69 의 `.` 쪽 거울상 — 판정이 아니라 **기록값**에서 갈린다.
            # `.` 는 경로를 옮기지 않으므로 안/밖은 그대로지만, 안 풀리면 플래그에
            # `src/.` 가 박혀 같은 디렉토리의 다른 표기와 중복 제거되지 않는다.
            # 69 를 `..` 만 풀어서 고치면 이 행이 혼자 빨개진다(PR #13 케이스 43 과 같은 구조).
  local p; p="$(new_project)"
  mkdir -p "$p/src"
  run_hook "$p" "$p/src/."
  check_case '70 마지막 성분이 . → 게이트 4종(정규화된 값 src)' 0 gate 'src'
}

# --- 계약 표의 크기 -------------------------------------------------------
# 러너가 이 두 값으로 "케이스가 조용히 빠지거나 두 번 도는 것"을 잡는다.
# 건수는 여기 말고 어디에도 숫자로 적지 않는다 — 케이스를 추가할 때마다 낡는다.

EXPECTED_CASES=70

CASES='case_01 case_02 case_03 case_04 case_05 case_06 case_07 case_08 case_09 case_10 case_11
       case_12 case_13 case_14 case_15 case_16 case_17 case_18 case_19 case_20 case_21 case_22
       case_23 case_24 case_25 case_26 case_27 case_28 case_29 case_30 case_31 case_32 case_33
       case_34 case_35 case_36 case_37 case_38 case_39 case_40 case_41 case_42 case_43 case_44
       case_45 case_46 case_47 case_48 case_49 case_50 case_51 case_52 case_53 case_54 case_55
       case_56 case_57 case_58 case_59 case_60 case_61 case_62 case_63 case_64 case_65 case_66
       case_67 case_68 case_69 case_70'
