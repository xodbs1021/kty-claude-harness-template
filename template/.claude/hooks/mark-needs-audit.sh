#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): 편집된 파일이 완료 게이트 대상이면 플래그를 세운다.
#
# 이 플래그는 completion-auditor 가 검증을 통과시킨 뒤에만 지워진다.
# Stop 훅이 플래그를 보고 턴 종료를 막는다 → 감사자 호출이 강제된다.
# 커밋 여부와 무관하게 동작하므로 "커밋해서 트리가 clean 해졌으니 통과" 같은 구멍이 없다.
#
# 검사 범위:
#   프로젝트 안       — _workspace/·.claude/·순수 *.md|*.markdown(대소문자 무관) 를 뺀 전부
#   밖 + 하네스 정본  — 저장소(루트에 template/.claude/) **전체**를 프로젝트와 같은 규칙으로
#   밖 + 그 외        — .claude/ 앵커에 걸린 하네스 파일만 (git 저장소일 필요 없음)
#   설계·계획 산출물  — 위치·git 무관하게 _workspace/[0-9][0-9]_design*.md·[0-9][0-9]_plan*.md 는
#                       듀얼리뷰+지식+**머리 표명 2종**(ADR-0013·0015 — 머리 두 줄
#                       형식(회수·레퍼런스 조사)을 Stop 이 검사)
#   결정 문서        — docs/decisions/*.md 는 문서 제외의 예외로 지식만
#
# 왜 이렇게 넓나 (2026-08-04 실사고): 하네스 자신을 고치는 작업은 **늘** 별도 클론에서
# 일어나는데 훅이 프로젝트 밖을 통째로 스킵해, 게이트가 프로젝트는 지키면서 정작 하네스
# 자체 개발만 못 지켰다.
# 왜 위치가 아니라 경로 모양인가: 예전엔 홈 디렉터리를 통째로 예외 처리했는데, 그 규칙이
# 남의 닷파일 저장소를 오탐하면서(vimrc) 정작 홈에 설치된 하네스 파일은 놓쳤다. 위치는
# 게이트 대상 여부와 상관이 없다 — 하네스 동작을 정의하는 파일인지가 상관있다.
# 홈 디렉터리 예외는 삭제됐다. 되살리지 마라 (회귀 테스트가 정적으로 막는다).
#
# 기록값: 프로젝트 안은 상대경로, 밖은 **절대경로**. 밖 편집을 상대경로로 적으면
#         프로젝트 쪽 동명 파일과 구분되지 않는다.
#
# PostToolUse 는 절대 차단하지 않는다(도구는 이미 실행됨). 항상 exit 0.
# 차단할 수 없으므로, 기록에 **실패**했거나 경로 때문에 기록을 **포기**했을 때는
# stdout 의 systemMessage 로 알린다 — 조용히 게이트가 사라지는 것보다 낫다.
#
# 이 판정 계약의 기계 정본은 tests/mark-needs-audit.cases.sh 이고
# tests/mark-needs-audit.test.sh 가 그것을 돌린다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

HOOK_ID="post:edit:needs-audit"
hook_disabled "$HOOK_ID" && exit 0

# 메시지 상수. " 와 \ 와 제어문자를 쓰지 않는다 — 그래서 이스케이프 로직이 필요 없다.
# 경로를 넣지 않는 것도 같은 이유다: 기록 실패 상황에서 사용자에게 필요한 정보는
# "게이트가 안 섰다"는 사실이고, 경로를 끼우는 순간 이스케이프 기계장치가 딸려온다.
MSG_WRITE_FAIL="완료 게이트 플래그를 기록하지 못했다(.claude 쓰기 실패). 게이트가 서지 않았으니 완료 판정 전에 수동으로 확인하라."
MSG_NEWLINE="편집 경로에 개행이 있어 게이트 플래그를 기록하지 않았다. 줄 단위 플래그 파일이 오염되기 때문이다. 수동으로 확인하라."
MSG_GIT_UNAVAILABLE="git 이 저장소 정보를 돌려주지 못해(소유권 거부·권한·손상) 하네스 정본 여부를 판정하지 못했다. 앵커 밖 파일에는 게이트가 서지 않았으니 수동으로 확인하라."
MSG_SWEEP_TRUNCATED="이 명령이 바꾼 파일이 너무 많아 일부만 게이트에 기록했다. 나머지에는 게이트가 서지 않았으니 수동으로 확인하라."
MSG_SWEEP_PARTIAL="이 명령이 바꾼 파일 중 일부는 게이트에 기록하지 못했다(경로에 개행이 있거나 기록에 실패). 그 파일들은 수동으로 확인하라."

# --- 계약 함수 ------------------------------------------------------------

# emit_message <메시지> — {"systemMessage":"..."} 를 stdout 에 한 줄로.
# JSON 을 만드는 **유일 지점**이다. 여기 말고 다른 곳에서 stdout 에 쓰면 안 된다.
emit_message() {
  printf '{"systemMessage":"%s"}\n' "$1"
}

# physical_dir <디렉토리> — 심링크·`..`·`.` 를 푼 물리 절대경로를 stdout 에.
# 실패하면 **원본을 그대로 내고** rc=1. 호출자는 스킵하지 않는다 — 정규화에 실패했다고
# 게이트를 지우면 조용한 위음성이 되므로, 덜 정확한 경로로라도 판정을 잇는 쪽을 택한다.
#
# **cd 는 반드시 -P 여야 한다** — pwd -P 만으로는 부족하다. 논리 cd(기본값)는 `심링크/..` 를
# 심링크를 따라가기 **전에** 문자로 상쇄하므로 커널이 실제로 여는 곳과 다른 답을 낸다
# (실측: `cd -- /var/..` → `/`, `cd -P -- /var/..` → `/private`). 그 차이만큼 프로젝트
# **밖** 파일이 프로젝트 **안** 상대경로로 기록돼, 게이트는 서는데 감사자가 엉뚱한 파일을
# 본다(케이스 67). 반대 방향으로는 밖 하네스 파일의 게이트가 통째로 사라진다(케이스 68).
# physical_path 는 형제 검사기였던 check-rule-copies(PR #13 검증, 2026-08-17 단일 정본화로 폐지)와 같은 방식이다.
physical_dir() {
  local out
  out="$(CDPATH='' cd -P -- "$1" 2>/dev/null && pwd -P)"
  if [ -z "$out" ]; then
    printf '%s\n' "$1"
    return 1
  fi
  printf '%s\n' "$out"
}

# physical_path <파일경로> — 편집 경로를 물리화한다. 실패하면 **원본 경로를 그대로 내고** rc=1.
#
# 마지막 성분이 **이름이면 보존**한다 — 파일 자신이 심링크여도 편집 대상의 이름으로
# 기록해야 하고, 애초에 파일에는 cd 할 수 없다. 파일이 아직 없을 수도 있다(케이스 51).
#
# **단 `.`·`..` 는 이름이 아니라 디렉토리 이동이라 반드시 푼다.** 보존할 이름이 없으므로
# 위 예외의 근거가 성립하지 않는다. 안 풀면 dirname 만 물리화된 `…/src/..` 가 그대로 나와
# 프로젝트 접두사에 문자열상 걸리고, 플래그에 디렉토리 표기가 박힌다(케이스 69·70).
# 형제 검사기가 PR #13 에서 같은 이름의 같은 버그를 이 방식으로 고쳤다 — 접근을 맞춘다.
physical_path() {
  local dir base
  base="$(basename -- "$1")"
  # cd 는 반드시 명령 치환 안에서 — 함수 본문에서 그냥 cd 하면 호출부의 cwd 가 바뀐다.
  case "$base" in
    . | ..) physical_dir "$1"; return ;;
  esac
  dir="$(physical_dir "$(dirname -- "$1")")" || { printf '%s\n' "$1"; return 1; }
  # pwd -P 가 "/" 를 낼 때만 "//base" 가 된다 (루트 바로 아래 경로).
  if [ "$dir" = '/' ]; then dir=''; fi
  printf '%s/%s\n' "$dir" "$base"
}

# project_rel <절대경로> — $proj 아래면 프로젝트 기준 상대경로를 stdout·rc=0, 아니면 rc=1.
# 접두사에 **슬래시를 반드시 포함**한다. 빠뜨리면 형제 디렉토리(<proj>-backup/…)를
# 프로젝트 안으로 오인한다. "$proj" 를 인용하는 것은 경로 안의 글롭 문자 때문이다.
project_rel() {
  case "$1" in
    "$proj"/*) printf '%s\n' "${1#"$proj"/}" ;;
    *) return 1 ;;
  esac
}

# git_toplevel <절대경로> — 그 파일이 속한 git 저장소 루트를 물리 경로로. 없으면 rc=1.
# GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE 을 소거한다: 훅이 git 훅 안에서 돌면 이 변수들이
# 엉뚱한 저장소를 가리켜 귀속이 통째로 바뀐다.
# 경로에 /.git/ 가 있으면 그 앞을 기준으로 삼는다: git 은 .git 안에서 --show-toplevel 에
# 실패하므로(실측 rc=128), 그대로 물으면 .git/hooks/* 편집이 판정 불가로 새어나간다.
git_toplevel() {
  local dir top
  case "$1" in
    */.git/*) dir="${1%%/.git/*}" ;;
    */.git)   dir="${1%/.git}" ;;
    *)        dir="$(dirname -- "$1")" ;;
  esac
  top="$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
         git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"
  [ -n "$top" ] || return 1
  physical_dir "$top"
}

# has_git_ancestor <절대경로> — 조상 디렉토리에 .git 이 있는가. git 을 쓰지 않는다.
# git_toplevel 이 빈 값을 돌려준 이유가 "저장소가 아님"인지 "git 이 거부함"인지를 가르는
# 데 쓴다. rev-parse 는 둘 다 rc=128 로 돌려주므로 stderr 내용으로 가르는 것은 취약하다.
has_git_ancestor() {
  local d
  d="$(dirname -- "$1")"
  while [ "$d" != '/' ] && [ "$d" != '.' ]; do
    [ -e "$d/.git" ] && return 0
    d="$(dirname -- "$d")"
  done
  return 1
}

# is_harness_canonical <저장소루트> — 하네스 정본 저장소인가.
# 마커는 이 한 조건뿐이다. 조건을 더 얹으면 재배치 포크에서 위음성이 넓어지는데,
# 위음성은 조용하고 오탐은 탈출구(ECC_DISABLED_HOOKS)가 있다 — 그래서 단순한 쪽을 택했다.
is_harness_canonical() {
  [ -d "$1/template/.claude" ]
}

# harness_anchor <선행 슬래시가 있는 경로> — 하네스 동작을 정의하는 자리인가.
# 앵커 목록을 정의하는 **유일 지점**이다.
harness_anchor() {
  case "$1" in
    */.claude/agents/*|*/.claude/skills/*|*/.claude/hooks/*|*/.claude/harness/*|*/.claude/settings.json)
      return 0 ;;
  esac
  return 1
}

# classify <기준 상대경로> <기준 디렉토리> — gate · knowledge · skip 을 stdout 에.
# 프로젝트 안(4a)과 밖-하네스정본(4b)이 **같은 규칙**을 쓰도록 공유한다.
#
# 순서가 계약이다:
#   1) .claude/*·_workspace/* 제외가 앵커보다 **먼저**. 그래야 하네스 정본 저장소가
#      자기 자신에 설치해 둔 소비 사본(.claude/hooks/*)이 빠지고 정본(template/.claude/*)만
#      발화한다. 설치본은 정본을 고쳐 sync 하는 게 규약이라 제자리 편집은 일시적이다.
#   2) 앵커가 *.md 제외보다 먼저. 에이전트·스킬·원칙 정의는 전부 .md 인데 일괄 제외하면
#      하네스 저장소에서 가장 흔한 변경에 플래그가 하나도 안 선다.
#   3) global-agents/*.md 는 **정본 스코프에서만** 예외의 예외를 연다. install/sync 가
#      배포하는 전역 에이전트 정본이기 때문이며, 남의 프로젝트로 새면 오탐이 된다.
classify() {
  local rel="$1" base="$2" lower
  case "$rel" in
    _workspace/*|.claude/*) printf 'skip\n'; return 0 ;;
  esac
  if harness_anchor "/$rel"; then
    printf 'gate\n'; return 0
  fi
  case "$rel" in
    global-agents/*.md)
      if is_harness_canonical "$base"; then printf 'gate\n'; return 0; fi ;;
  esac
  # 확장자 판정은 소문자화해서 본다 — README.MD 가 코드로 취급되면 안 된다.
  lower="$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')"
  # 결정 문서는 문서 제외의 **예외**다. 하네스가 스스로 "결정은 여기 이 이름으로 쓴다"고
  # 규정한 경로(결정 기록 절)라 **하네스가 아는 산출물**이고, 그 자리가 편집됐다는 것은
  # 곧 결정이 나왔다는 뜻이다. 코드가 아니므로 게이트 4종은 과하다 — 지식 게이트만 세운다.
  #
  # 공시된 한계: 결정 문서를 이 경로 **밖**에 두면 게이트가 서지 않는다. 하네스가 아는
  # 경로만 알 수 있기 때문이고, 프로젝트마다 다른 위치를 알아내려면 다시 상위 층 구현을
  # 알아야 한다. 이 공백은 회수 정책 ADR 로 넘긴다.
  case "$lower" in
    docs/decisions/*.md|docs/decisions/*.markdown) printf 'knowledge\n'; return 0 ;;
  esac
  case "$lower" in
    *.md|*.markdown) printf 'skip\n'; return 0 ;;
  esac
  printf 'gate\n'
}

# record_flag <플래그파일> <값> — 이미 있으면 그냥 두고, 없으면 한 줄 덧붙인다. 실패하면 rc=1.
# grep 의 -- 는 필수다: 값이 - 로 시작하면(예: 파일명 --version) grep 이 그것을 옵션으로
# 해석해 rc=0(=이미 있음)을 돌려주고, BSD grep 은 -q 아래서도 버전 문자열을 stdout 에 뱉는다.
# append 를 중괄호로 감싸는 것도 필수다: 리다이렉트 **열기** 실패는 셸이 보고하는데,
# printf 뒤에 붙인 2>/dev/null 은 그 시점에 아직 적용되지 않아 stderr 가 샌다(실측).
record_flag() {
  mkdir -p "$STATE_DIR" 2>/dev/null
  if grep -qxF -- "$2" "$1" 2>/dev/null; then
    # [cx] 같은 경로 재편집도 플래그 mtime 을 갱신해야 한다 — 안 하면 이전 리뷰
    # 산출물이 플래그보다 "새로워서" 미리뷰 편집이 자동 해제된다(stale review 우회).
    touch "$1" 2>/dev/null
    return 0
  fi
  { printf '%s\n' "$2" >> "$1"; } 2>/dev/null || return 1
  return 0
}

# --- Bash 스윕 -------------------------------------------------------------
#
# **왜 필요한가 (2026-09-05 실사고):** 이 훅은 Edit|Write|MultiEdit 에만 걸려 있어서
# `cat > 파일`·`sed -i`·`python3` 로 쓴 파일은 게이트를 통째로 지나쳤다. 하네스 정본
# (template/.claude/*)을 Bash 로 고친 세션 전체가 무게이트로 끝났다 — 게이트가 있다고
# 믿는 쪽이 없는 것보다 나쁘다.
#
# **명령을 파싱하지 않는다.** 무엇을 썼는지 명령줄에서 알아내려는 시도는 히어독·리다이렉트·
# 스크립트 호출마다 새는 구멍을 만든다. 대신 **결과를 본다**: PreToolUse 가 찍어 둔 시각
# 표식보다 새로 바뀐 파일을 찾는다. 명령이 어떻게 썼든 파일 mtime 은 거짓말하지 않는다.
#
# **판정은 재호출로 위임한다.** 찾은 파일마다 이 스크립트를 file_path 페이로드로 다시
# 부른다. classify 의 사본을 만들지 않으려는 것이다 — 사본을 두는 순간 두 판정이
# 어긋나는 날이 온다(이 저장소가 반복해서 배운 것).
WINDOW_DIR="$STATE_DIR/.bash-windows"
BASH_WINDOW=""         # 이번 스윕이 쓸 창. sweep_bash_writes 가 고른다.
SWEEP_MAX=200          # 병적인 명령(대량 생성)에서 재호출이 폭주하지 않게
SWEEP_MAX_ROOTS=3      # 프로젝트 밖 뿌리 탐색의 상한

# find 의 prune 목록. **성능을 위한 것만 남긴다.**
# 예전엔 dist·build·target·vendor 도 잘라냈는데, 그것들이 **git 에 추적 중**이면
# Edit 경로의 classify 는 게이트 대상으로 보는데 스윕만 통째로 건너뛰었다 —
# "판정은 재호출로 단일화한다"는 이 스윕의 전제와 어긋난다(codex r1 HIGH).
# 무엇이 산출물인지는 아래 git check-ignore 가 판정한다. 여기서 다시 정하지 않는다.
SWEEP_PRUNE='-name .git -o -name node_modules -o -name .venv -o -name __pycache__'

# sweep_find <뿌리> — 표식 이후 바뀐 파일을 **NUL 구분**으로.
# 개행이 든 파일명을 줄 단위로 읽으면 **두 개의 가짜 경로**로 쪼개져, 엉뚱한 경로가
# 플래그에 박히고 정작 그 파일은 무게이트가 된다([cc] r1 지적). find 의 -print0 과
# read -d '' 조합이 그 부류를 통째로 없앤다.
sweep_find() {
  # SWEEP_PRUNE 은 find 의 인자 목록이라 의도적으로 인용하지 않는다.
  # shellcheck disable=SC2086
  find "$1" \( $SWEEP_PRUNE \) -prune -o -type f -newer "$BASH_WINDOW" -print0 2>/dev/null
}

# payload_for_path <절대경로> — 재호출용 JSON 한 줄.
#
# **문자열로 조립하지 않는다.** printf '…"%s"…' 로 끼우면 파일명의 `"` 나 `\` 가 JSON 을
# 깨고, json_get 은 파싱 실패를 빈 출력으로 삼키므로 재호출된 훅이 그 파일을 **조용히
# 통과시킨다.** 실측: `say"hi".go`·`back\slash.go` 가 플래그에 안 잡혔다([cc] r1 CRITICAL).
# json.dumps 가 이스케이프의 유일 정본이다 — 우리가 규칙을 다시 쓰지 않는다.
payload_for_path() {
  python3 -c 'import json,sys; print(json.dumps({"tool_input":{"file_path":sys.argv[1]}}))' "$1" 2>/dev/null
}

# sweep_roots <명령문자열> — 스캔할 저장소 뿌리를 한 줄에 하나씩.
# 프로젝트는 언제나 포함한다. 하네스 정본은 **다른 클론**에서 고쳐지는 일이 잦으므로
# (이 파일 머리 주석의 2026-08-04 실사고), 명령문에 등장한 절대경로의 git 루트도 훑는다.
# 이건 명령 해석이 아니라 **탐색 범위 힌트**다 — 틀려도 프로젝트 스캔은 그대로 돈다.
sweep_roots() {
  local cmd="$1" tok root n=0
  printf '%s\n' "$proj"
  for tok in $(printf '%s' "$cmd" | grep -o '/[A-Za-z0-9_./~@+-]\{2,\}' 2>/dev/null | sort -u); do
    [ -e "$tok" ] || continue
    root="$(git_toplevel "$tok")" || continue
    [ -n "$root" ] || continue
    [ "$root" = "$proj" ] && continue
    printf '%s\n' "$root"
    n=$((n + 1))
    [ "$n" -ge "$SWEEP_MAX_ROOTS" ] && break
  done
}

# sweep_bash_writes <명령문자열> — 표식 이후 바뀐 파일을 찾아 자기 자신에게 넘긴다.
sweep_bash_writes() {
  local cmd="$1" self root f n=0 seen="" truncated=0 child_msg=0 child_out st

  # **가장 오래된 창을 소비한다.** 병렬 Bash 에서 창이 여럿일 수 있는데, 짝을 정확히
  # 맞출 방법이 없으므로 **가장 넓은 창**을 쓴다 — 남의 호출이 쓴 파일까지 잡는 과탐은
  # 싸고, 놓치는 누락은 비싸다(codex r1 CRITICAL).
  #
  # **소비한 창은 반드시 지운다(아래 consume).** 안 지우면 창이 쌓여 매번 세션 맨 처음
  # 창을 쓰게 되고, 감사자가 플래그를 지워도 다음 Bash 가 같은 파일을 다시 세워
  # **게이트가 영원히 안 닫힌다 — 세션이 벽돌이 된다.** r1 수정이 만든 2차 결함이라
  # 여기 못 박는다([cc] r2).
  #
  # ls -tr 은 **mtime 오름차순**이다(-t 가 mtime, -r 이 역순). 창 파일명은 우리가 짓고
  # 공백·개행이 없으므로 ls 출력을 줄 단위로 읽어도 안전하다.
  BASH_WINDOW="$(ls -tr "$WINDOW_DIR" 2>/dev/null | head -n 1)"
  [ -n "$BASH_WINDOW" ] || return 0     # 창이 없으면(PreToolUse 미등록) 스윕하지 않는다
  BASH_WINDOW="$WINDOW_DIR/$BASH_WINDOW"
  [ -f "$BASH_WINDOW" ] || return 0
  self="${BASH_SOURCE[0]}"

  while IFS= read -r root; do
    [ -n "$root" ] || continue
    # 구분자로 문자열 집합을 만들면 경로에 그 구분자가 들어갔을 때 접두 충돌한다
    # (codex r1 MEDIUM). 개행은 git 루트 경로에 못 들어가므로 안전한 구분자다.
    case "$seen" in *"$root"$'\n'*) continue ;; esac
    seen="$seen$root"$'\n'

    # 목록을 **한 번만** 만든다. 예전엔 무시 목록용과 본 루프용으로 find 를 두 번 돌렸는데,
    # 그 사이에 생긴 파일이 무시 목록에 없는 채로 본 루프에 잡혔다([cc] r1 지적).
    # 무시 여부는 파일마다 git 에 직접 묻는다 — 목록을 문자열로 들고 다니면 개행·NUL 이
    # 든 파일명에서 다시 깨진다. 대상이 보통 몇 개라 비용보다 정확성을 택했다.
    while IFS= read -r -d '' f; do
      [ -n "$f" ] || continue
      git -C "$root" check-ignore -q -- "$f" 2>/dev/null && continue
      n=$((n + 1))
      if [ "$n" -gt "$SWEEP_MAX" ]; then truncated=1; break 2; fi
      # 자식이 낸 systemMessage 를 **버리지 않는다.** 개행이 든 경로처럼 자식이 "기록을
      # 포기했다"고 알리는 경우가 있는데, >/dev/null 로 삼키면 이 훅의 fail-loud 계약이
      # 스윕 경로에서만 사라진다. 자식 JSON 을 그대로 흘리면 stdout 에 여러 줄이 나가므로
      # (PostToolUse 는 한 줄 계약) **있었다는 사실만** 모아 아래에서 한 번 알린다.
      child_out="$(payload_for_path "$f" | bash "$self" 2>/dev/null)"
      [ -n "$child_out" ] && child_msg=1
    done < <(sweep_find "$root")

    # **삭제는 find 로 못 본다** — `-type f` 는 없는 파일을 찾을 수 없다(codex r1 CRITICAL).
    # `rm src/auth.go` 가 게이트를 그대로 통과하던 구멍이다. git 이 아는 삭제만 잡는다:
    # 추적되지 않던 파일의 삭제는 어차피 아무도 모른다.
    # 시간 창을 못 걸므로 **이전에 생긴 미커밋 삭제도 잡힌다** — 과탐이지만, 미커밋 삭제가
    # 남아 있다는 것 자체가 감사가 필요한 상태라 그대로 둔다.
    #
    # **-z 가 필수다.** 기본 porcelain 은 특수문자 경로를 따옴표로 감싸고 이스케이프한다.
    # 실측: `src/say"hi".go` → `"src/say\"hi\".go"`, 한글 경로 → `"src/\355\225\234…"`.
    # 그대로 쓰면 **존재하지 않는 경로**가 플래그에 박히고 실제 파일은 무게이트다 —
    # 한국어 파일명을 쓰는 저장소에서는 상시 조건이다(codex r2 지적, [cc] 실측).
    # -z 는 인용 없이 NUL 로 끊어 준다. 레코드 = 상태 2글자 + 공백 + 경로.
    while IFS= read -r -d '' st; do
      case "$st" in
        ' D '*|'D  '*|'AD '*|'MD '*) ;;
        *) continue ;;
      esac
      f="${st:3}"
      [ -n "$f" ] || continue
      n=$((n + 1))
      if [ "$n" -gt "$SWEEP_MAX" ]; then truncated=1; break 2; fi
      child_out="$(payload_for_path "$root/$f" | bash "$self" 2>/dev/null)"
      [ -n "$child_out" ] && child_msg=1
    done < <(git -C "$root" status --porcelain -z 2>/dev/null)
  done <<EOF
$(sweep_roots "$cmd")
EOF

  # 창을 소비했으니 지운다. 이 줄이 없으면 위 주석의 벽돌 상태가 된다.
  rm -f "$BASH_WINDOW" 2>/dev/null

  # 조용히 끊으면 사용자는 게이트가 다 섰다고 믿는데 실제로는 아니다 — 이 훅이 위음성을
  # 대하는 방식(fail-loud)과 어긋난다. 메시지는 **한 줄만** 낸다(PostToolUse 계약).
  if [ "$truncated" -eq 1 ]; then
    emit_message "$MSG_SWEEP_TRUNCATED"
  elif [ "$child_msg" -eq 1 ]; then
    emit_message "$MSG_SWEEP_PARTIAL"
  fi
  return 0
}

# --- 판정 -----------------------------------------------------------------

payload="$(cat)"
# json_get 결과를 **센티널로** 받는다. 명령 치환은 후행 개행을 전부 지우므로 그냥 받으면
# 경로 끝의 개행이 아래 가드에 닿기도 전에 사라지고, 경고 없이 **다른 파일** 경로가
# 기록된다("src/app.ts" + LF → "src/app.ts"). X 를 붙여 받고 도로 뗀 뒤, json_get 자신이
# print() 로 붙인 개행 **하나만** 지운다 — 그러면 원본의 후행 개행이 살아남는다.
raw="$(printf '%s' "$payload" | json_get tool_input.file_path; printf 'X')"
raw="${raw%X}"
file_path="${raw%$'\n'}"

# proj 는 두 갈래가 다 쓴다(스윕의 기본 뿌리 · 아래 상대경로 해석). 분기 전에 구한다.
proj="$(physical_dir "$PROJECT_DIR")"

# file_path 가 없으면 Bash 다. 명령이 무엇을 썼는지는 **결과로** 알아낸다(위 스윕 주석).
if [ -z "$file_path" ]; then
  cmd_raw="$(printf '%s' "$payload" | json_get tool_input.command; printf 'X')"
  cmd_raw="${cmd_raw%X}"
  [ -n "${cmd_raw%$'\n'}" ] || exit 0
  sweep_bash_writes "${cmd_raw%$'\n'}"
  exit 0
fi

# 개행 가드는 **정규화보다 먼저**여야 한다. 디렉토리 컴포넌트가 개행으로 끝나면
# (…/sr<LF>/app.ts) physical_path 의 pwd -P 출력을 받는 명령 치환이 그 개행을 먹어
# 경로가 …/sr/app.ts 로 조용히 바뀐다 — 없는 파일이 게이트에 박히고 정작 편집한
# 파일은 무게이트가 된다. 플래그 파일은 줄 단위라 개행이 든 경로는 애초에 못 적는다.
case "$file_path" in
  *$'\n'*) emit_message "$MSG_NEWLINE"; exit 0 ;;
esac

# 양쪽을 물리 경로로 맞춘 뒤에 비교한다. git 은 실제 경로를 돌려주는데 편집 경로는
# 심링크를 지나올 수 있고(macOS /var → /private/var), .. 로 되돌아올 수도 있다.
# 정규화 없이 자르면 접두사가 안 맞아 프로젝트 안 편집이 통째로 "밖"으로 샌다.
# PROJECT_DIR 은 디렉토리라 통째로 물리화한다(심링크 PROJECT_DIR — 케이스 11·12).
# 편집 경로는 파일이라 마지막 성분 이름을 보존하는 physical_path 를 쓴다 — 두 계약이
# 다르므로 함수도 둘이다. (proj 는 Bash 스윕도 쓰므로 분기 **전에** 구해 뒀다.)
case "$file_path" in
  /*) ;;
  *) file_path="$proj/$file_path" ;;
esac
abs="$(physical_path "$file_path")"

# 설계·계획 산출물은 위치·git 여부와 무관하게 듀얼리뷰 게이트만 세운다.
# **정규화 뒤**에 판정해야 한다: 상대경로 입력에는 선행 슬래시가 없어 아래 글롭에
# 걸리지 않고, .. 가 섞인 경로는 기록값이 .claude/../_workspace/… 로 남는다.
# 매칭만 소문자화하고 기록은 원본 대소문자로 한다.
lower_abs="$(printf '%s' "$abs" | tr '[:upper:]' '[:lower:]')"
# 설계·계획 산출물은 듀얼리뷰 **와 지식·머리 표명 게이트**를 세운다. 코드가 아니므로
# 타입체크·변경설명·감사는 과하지만, 설계가 나온 턴을 지식 저장소 반영 없이 끝내면
# "왜 그렇게 정했나"가 그 자리에서 사라진다 — 결정을 만든 근거가 정확히 이 파일들이다.
# 회수 플래그(ADR-0013·0015)는 머리 두 줄(`사전 결정 회수:`·`레퍼런스 조사:`) 표명을
# Stop 이 검사하고 지키면 스스로 지운다. 이름에 codex 가 든다고 빼는 식의 **이름 제외는 두지 않는다** —
# 관측되지 않은 재귀를 막으려고 실재하는 위음성(codex 를 다루는 정상 설계서의 무게이트)을
# 만들게 된다. 리뷰 산출물과의 재귀는 명명 계약(리뷰 산출물은 NN_design·NN_plan 앵커
# 금지 — 오케스트레이터 스킬)이 막는다.
# [0-9][0-9]_ 앵커(2026-08-17 감사): 조사 산출물이 00_·01_ 번호를 선점하면 계획서가 02_plan_… 이
# 되어 01_plan* 만 보던 글롭을 조용히 우회한다(POK-79 실측 — 게이트 미발동). 숫자 두 자리
# 바로 뒤에 _design/_plan 을 요구하므로 NN_codex_plan_review 류 리뷰 파일(출처 토큰이 번호
# 뒤에 옴)은 걸리지 않는다. 0?_ 로 쓰면 안 된다 — 글롭 ? 는 숫자가 아니라 **아무 문자
# 한 개**라 0a_plan 이 오탐되고 10_plan 이 위음성으로 샌다([cx] 2026-08-17, 케이스 78·79).
case "$lower_abs" in
  */_workspace/[0-9][0-9]_design*.md|*/_workspace/[0-9][0-9]_plan*.md)
    dual_value="$(project_rel "$abs")" || dual_value="$abs"
    dw=0
    record_flag "$DUALREVIEW_FLAG" "$dual_value" || dw=1
    record_flag "$KNOWLEDGE_FLAG"  "$dual_value" || dw=1
    record_flag "$RETRIEVAL_FLAG"  "$dual_value" || dw=1
    [ "$dw" -eq 1 ] && emit_message "$MSG_WRITE_FAIL"
    exit 0 ;;
esac

if rel="$(project_rel "$abs")"; then
  value="$rel"
  verdict="$(classify "$rel" "$proj")"
else
  # 프로젝트 밖. 기록값은 절대경로다.
  value="$abs"
  root="$(git_toplevel "$abs")" || root=''
  if [ -n "$root" ] && is_harness_canonical "$root"; then
    case "$abs" in
      "$root"/*) rel="${abs#"$root"/}" ;;
      *) rel="$abs" ;;
    esac
    verdict="$(classify "$rel" "$root")"
  elif harness_anchor "$abs"; then
    # 앵커 판정에 git 을 요구하지 않는다 — 홈에 설치된 .claude/agents/*.md 는
    # 그 디렉토리가 git 저장소가 아니어도 하네스 동작을 정의한다.
    verdict='gate'
  else
    verdict='skip'
    # git 이 빈 값을 돌려줬는데 조상에 .git 이 있으면, 저장소가 아닌 게 아니라 git 이
    # 거부한 것이다(safe.directory 소유권 거부·권한·손상). 그대로 두면 정본 저장소
    # 전체가 앵커 밖 파일에 대해 무게이트 + 무신호로 조용히 감시 축소된다.
    # 판정은 바꾸지 않는다(추측으로 게이트를 세우면 남의 저장소를 오탐한다) — 알리기만
    # 한다. physical_path 가 fail-loud 인데 여기만 fail-silent 이던 비대칭을 없앤다.
    [ -z "$root" ] && has_git_ancestor "$abs" && emit_message "$MSG_GIT_UNAVAILABLE"
  fi
fi

# 결정 문서는 지식 게이트 하나만. 코드가 아니므로 타입체크·변경설명·감사는 과하다.
if [ "$verdict" = 'knowledge' ]; then
  record_flag "$KNOWLEDGE_FLAG" "$value" || emit_message "$MSG_WRITE_FAIL"
  exit 0
fi

[ "$verdict" = 'gate' ] || exit 0

# 완료 게이트 4종을 동시에 세운다:
#   .needs-audit      → completion-auditor 강제 (Phase 6)
#   .needs-explain    → change-explainer 강제 (Phase 5)
#   .needs-knowledge  → 지식 저장소 반영 또는 불요 사유 기록 강제 (2026-08-02 kty —
#                       산문 규칙이 기억에만 의존해 세션 내내 0회 이행된 실사고의 재발 방지)
#   .needs-dualreview → codex 듀얼 리뷰 강제 (2026-08-03 kty)
# 각 게이트는 해당 작업이 실제로 끝난 뒤에만 수동으로 지워진다. Stop 훅이 넷 다 본다.
#
# 지식 게이트가 꺼져 있어도 여기서는 **기록한다.** 켜짐/꺼짐 판정은 harness.env 를 한 번
# 더 읽는 일인데 이 훅은 편집마다 돌고 Stop 훅은 턴에 한 번 돈다 — 판정은 Stop 쪽
# 한 곳(knowledge_gate_active)으로 모았다. 꺼져 있으면 이 파일은 아무 효력이 없다.
write_failed=0
for flag in "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG"; do
  record_flag "$flag" "$value" || write_failed=1
done
# 넷이 다 실패해도 메시지는 한 줄만 낸다.
[ "$write_failed" -eq 1 ] && emit_message "$MSG_WRITE_FAIL"
exit 0
