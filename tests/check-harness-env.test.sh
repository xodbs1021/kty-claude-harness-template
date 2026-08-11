#!/usr/bin/env bash
# check-harness-env.test.sh — harness.env 편집 검증 훅(post:edit:harness-env, ADR-0016) 회귀 방어.
#
#   "harness.env 를 편집한 직후, 값을 믿을 수 없는 알려진 키가 있으면 그 자리에서
#    systemMessage 로 알린다. 부재(안 쓰는 키)와 정상 판독은 침묵한다."
#
# 실패 방향이 둘이다:
#   위음성 — 문법 실수를 침묵으로 넘긴다. 이 훅이 존재하는 이유의 반대(조용한 검사 생략)
#   위양성 — 안 쓰는 키·무관 파일에 경고를 낸다. 경고가 소음이 되면 진짜 경고도 무시된다.
#            판독기 rc=1/rc=3 구분(_common.sh 반환 계약)이 정확히 이 축을 지킨다
#
# **판정 규칙의 사본을 두지 않는다.** 훅 자신을 돌려 stdout(systemMessage)으로 잰다.
# 훅은 항상 exit 0 이므로 rc 로는 아무것도 판정하지 않는다 — stdout 의 존재·내용이 전부다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. mapfile·연관배열·${var,,} 금지.

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
HOOKS="$REPO_ROOT/template/.claude/hooks"

command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (payload 픽스처 의존)" >&2; exit 1; }
for f in check-harness-env.sh _common.sh; do
  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
done

TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT

ran=0; pass=0; fail=0
RC=999; OUT=''; ERR=''; DID_RUN=0

TOK_WARN='harness.env 판독 경고'
TOK_SKIP='조용히 생략'

report() {
  ran=$((ran + 1))
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}
contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }

# new_project [env내용|__NOFILE__] — 훅·공용 모듈이 설치된 독립 프로젝트.
new_project() {
  local p
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
  mkdir -p "$p/.claude/hooks" "$p/.claude/harness" || return 1
  cp "$HOOKS/_common.sh" "$HOOKS/check-harness-env.sh" "$p/.claude/hooks/" || return 1
  case "${1-}" in
    __NOFILE__) ;;
    *) printf '%s' "${1-}" > "$p/.claude/harness/harness.env" || return 1 ;;
  esac
  printf '%s\n' "$p"
}

# run_hook <프로젝트> <편집경로> [env 인자...] — PostToolUse payload 를 만들어 훅을 돌린다.
run_hook() {
  local p="$1" fp="$2"
  shift 2
  local outf="$TMPROOT/out.$$" errf="$TMPROOT/err.$$" payf="$TMPROOT/pay.$$"
  RC=999; OUT=''; ERR=''; DID_RUN=1
  python3 -c '
import json, sys
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    fh.write(json.dumps({"tool_input": {"file_path": sys.argv[1]}}))' "$fp" "$payf"
  ( cd "$TMPROOT" && env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$p" \
      bash "$p/.claude/hooks/check-harness-env.sh" <"$payf" >"$outf" 2>"$errf" )
  RC=$?
  rm -f "$payf"
  OUT="$(cat "$outf" 2>/dev/null)"
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$outf" "$errf"
}

# silent_case <이름> <env내용|__NOFILE__> [편집경로덮어씀] — 경고가 없어야 하는 케이스.
# rc=0 과 stdout 공백까지 요구한다(PostToolUse 는 절대 실패하면 안 된다).
silent_case() {
  local name="$1" body="$2" fp="${3-}" why='' p
  p="$(new_project "$body")" || { report "$name" '픽스처 실패'; return 0; }
  [ -n "$fp" ] || fp="$p/.claude/harness/harness.env"
  run_hook "$p" "$fp"
  if [ "$DID_RUN" -ne 1 ];        then why='훅 미실행'
  elif [ "$RC" -ne 0 ];           then why="rc=$RC (기대 0)"
  elif [ -n "$OUT" ];             then why="위양성 — 경고가 나왔다: $(printf '%s' "$OUT" | head -c 120)"
  fi
  report "$name" "$why"
}

# warn_case <이름> <env내용> <나열되어야 할 키> <나열되면 안 되는 키|''>
warn_case() {
  local name="$1" body="$2" want_key="$3" forbid_key="${4-}" why='' p
  p="$(new_project "$body")" || { report "$name" '픽스처 실패'; return 0; }
  run_hook "$p" "$p/.claude/harness/harness.env"
  if [ "$DID_RUN" -ne 1 ];              then why='훅 미실행'
  elif [ "$RC" -ne 0 ];                 then why="rc=$RC (기대 0 — PostToolUse 는 실패하면 안 된다)"
  elif ! contains "$OUT" "$TOK_WARN";   then why="경고가 없다: [$(printf '%s' "$OUT" | head -c 120)]"
  elif ! contains "$OUT" "$TOK_SKIP";   then why='결과(검사 생략) 안내가 없다'
  elif ! contains "$OUT" "$want_key";   then why="불량 키($want_key)가 나열되지 않았다"
  elif [ -n "$forbid_key" ] && contains "$OUT" "$forbid_key"; then why="정상 키($forbid_key)가 불량으로 나열됐다"
  fi
  report "$name" "$why"
}

# --- 케이스 --------------------------------------------------------------

c01() { # 두 키 다 유효 → 침묵.
  silent_case 'c01 정상 파일(두 키 유효) → 침묵' \
    'HARNESS_TYPECHECK_CMD="pnpm typecheck"'$'\n''HARNESS_KNOWLEDGE_GATE="on"'$'\n'
}

c02() { # 등호 뒤 공백 = 지원 문법 밖 → 그 키만 경고. 이 훅의 존재 이유가 되는 케이스다.
  warn_case 'c02 문법 밖(등호 뒤 공백) → 해당 키 경고' \
    'HARNESS_TYPECHECK_CMD= "pnpm typecheck"'$'\n''HARNESS_KNOWLEDGE_GATE="on"'$'\n' \
    'HARNESS_TYPECHECK_CMD' 'HARNESS_KNOWLEDGE_GATE'
}

c03() { # 중복 선언 → 경고.
  warn_case 'c03 중복 선언 → 경고' \
    'HARNESS_KNOWLEDGE_GATE="on"'$'\n''HARNESS_KNOWLEDGE_GATE=""'$'\n' \
    'HARNESS_KNOWLEDGE_GATE' 'HARNESS_TYPECHECK_CMD'
}

c04() { # 키가 하나도 없는 파일 → 침묵. **부재(rc=3)/못 믿음(rc=1) 구분의 케이스화** —
        # 구분이 없으면 키를 안 쓰는 모든 프로젝트의 편집마다 경고가 떠 소음이 된다.
  silent_case 'c04 키 없음(부재) → 침묵 (rc=3 구분)' '# 설정 없음'$'\n'
}

c05() { # 리터럴 빈 값은 정상 판독(rc=0)이다 — 스위치 끄기의 정상 형태.
  silent_case 'c05 리터럴 빈 값 → 침묵' 'HARNESS_KNOWLEDGE_GATE=""'$'\n'
}

c06() { # 무관 파일 편집은 대상이 아니다 — 동명이라도 .claude/harness/ 앵커 밖이면 침묵.
  local name='c06 무관 파일·앵커 밖 동명 파일 → 침묵' why='' p
  p="$(new_project 'HARNESS_TYPECHECK_CMD= "x"'$'\n')" || { report "$name" '픽스처 실패'; return 0; }
  run_hook "$p" "$p/src/app.ts"
  if [ -n "$OUT" ]; then why='무관 파일에 경고가 나왔다'
  else
    mkdir -p "$p/other" && printf 'HARNESS_TYPECHECK_CMD= "x"\n' > "$p/other/harness.env"
    run_hook "$p" "$p/other/harness.env"
    [ -z "$OUT" ] || why='앵커 밖 동명 파일에 경고가 나왔다'
  fi
  report "$name" "$why"
}

c07() { # 상대경로 편집도 $PROJECT_DIR 기준으로 그 파일을 판정한다.
  local name='c07 상대경로 harness.env → 경고' why='' p
  p="$(new_project 'HARNESS_TYPECHECK_CMD= "x"'$'\n')" || { report "$name" '픽스처 실패'; return 0; }
  run_hook "$p" ".claude/harness/harness.env"
  if ! contains "$OUT" "$TOK_WARN"; then why="경고가 없다 (상대경로가 cwd 기준으로 열렸을 가능성): [$(printf '%s' "$OUT" | head -c 80)]"
  elif ! contains "$OUT" 'HARNESS_TYPECHECK_CMD'; then why='불량 키가 나열되지 않았다'
  fi
  report "$name" "$why"
}

c08() { # 닫히지 않은 따옴표는 파일 전체를 못 믿는다 → 경고(두 키 다 걸린다).
  warn_case 'c08 닫히지 않은 따옴표 → 경고' \
    'HARNESS_TYPECHECK_CMD="pnpm'$'\n' \
    'HARNESS_TYPECHECK_CMD' ''
}

c09() { # 읽기 실패도 "못 믿음"이다 — 침묵하면 조용한 검사 생략과 같은 부류.
  local name='c09 읽기 실패 → 경고' why='' p
  p="$(new_project 'HARNESS_KNOWLEDGE_GATE="on"'$'\n')" || { report "$name" '픽스처 실패'; return 0; }
  if [ "$(id -u)" -eq 0 ]; then
    # root 는 -r 가 항상 참이라 읽기 실패를 재현할 수 없다(CI 컨테이너 대비) — 스킵이
    # 아니라 사유를 밝히고 통과 처리한다(다른 스위트의 root 예외와 같은 관례).
    report "$name (root — 재현 불가, 건너뜀 명시)" ''
    return 0
  fi
  chmod 000 "$p/.claude/harness/harness.env"
  run_hook "$p" "$p/.claude/harness/harness.env"
  chmod 644 "$p/.claude/harness/harness.env" 2>/dev/null
  contains "$OUT" "$TOK_WARN" || why="경고가 없다: [$(printf '%s' "$OUT" | head -c 80)]"
  report "$name" "$why"
}

c10() { # 개행이 든 경로는 판정하지 않는다 — mark-needs-audit 가 알리는 자리다.
  local name='c10 개행 경로 → 침묵' why='' p
  p="$(new_project 'HARNESS_TYPECHECK_CMD= "x"'$'\n')" || { report "$name" '픽스처 실패'; return 0; }
  run_hook "$p" ".claude/harness/harness.env"$'\n'"x"
  [ -z "$OUT" ] || why='개행 경로에 경고가 나왔다'
  report "$name" "$why"
}

c11() { # 훅 비활성 탈출구.
  local name='c11 ECC_DISABLED_HOOKS 비활성 → 침묵' why='' p
  p="$(new_project 'HARNESS_TYPECHECK_CMD= "x"'$'\n')" || { report "$name" '픽스처 실패'; return 0; }
  run_hook "$p" "$p/.claude/harness/harness.env" ECC_DISABLED_HOOKS=post:edit:harness-env
  [ -z "$OUT" ] || why='비활성인데 경고가 나왔다'
  report "$name" "$why"
}

c12() { # 파일이 없으면(삭제·실패한 쓰기) 부재다 — 경고하면 위양성. 파일 없음을 rc=3 이
        # 아니라 rc=1 로 접는 회귀(e02)가 여기서 빨개진다.
  silent_case 'c12 파일 없음(부재) → 침묵' '__NOFILE__'
}

c13() { # `.` 경유 표기도 같은 파일이다 — 물리화 전에 문자열 앵커로 판정하면 잘못된 값이
        # 무경고 통과한다(구현 검수 [cx] HIGH 의 케이스화. e08 이 여기서 빨개진다).
  local name='c13 점 경유 경로(harness/./harness.env) → 경고' why='' p
  p="$(new_project 'HARNESS_TYPECHECK_CMD= "x"'$'\n')" || { report "$name" '픽스처 실패'; return 0; }
  run_hook "$p" "$p/.claude/harness/./harness.env"
  if ! contains "$OUT" "$TOK_WARN"; then why="경고가 없다 (점 경유 표기가 앵커를 피했다): [$(printf '%s' "$OUT" | head -c 80)]"
  fi
  report "$name" "$why"
}

c14() { # 훅 파일만으로는 안 돈다 — settings.json 배선이 실물에 있어야 한다(정적 대조,
        # r21 리터럴 드리프트 검사와 같은 부류. e09 가 여기서 빨개진다).
  local name='c14 settings.json 배선 실존' why=''
  grep -qF 'check-harness-env.sh' "$REPO_ROOT/template/.claude/settings.json" \
    || why='settings.json 에 check-harness-env 배선이 없다'
  report "$name" "$why"
}

# --- 실행 -----------------------------------------------------------------
# EXPECTED_CASES 는 상수다. 파생값이면 케이스를 지워도 초록이다.
EXPECTED_CASES=14
CASES='c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12 c13 c14'

echo "check-harness-env.test.sh — harness.env 편집 검증 훅(post:edit:harness-env) 회귀"
case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ 케이스 목록이 계약과 다릅니다: 총 $case_total / 고유 $case_uniq / 기대 $EXPECTED_CASES" >&2
  exit 1
fi
for c in $CASES; do "$c"; done
if [ "$ran" -ne "$EXPECTED_CASES" ]; then
  echo "✗ 실행 수($ran)가 기대($EXPECTED_CASES)와 다릅니다 — 케이스가 조용히 빠졌습니다" >&2
  exit 1
fi
echo "— $pass/$ran 통과"
[ "$fail" -eq 0 ]
