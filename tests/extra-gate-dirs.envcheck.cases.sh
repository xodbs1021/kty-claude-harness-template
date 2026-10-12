#!/usr/bin/env bash
# extra-gate-dirs.envcheck.cases.sh — harness.env 편집 검증 훅(check-harness-env)의
# 슬롯 키 케이스.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기 있다: new_dir · report · contains · json_message_ok · COMMON · MODULE ·
# ENV_HOOK · TMPROOT · OUT · ERR · RC · DID_RUN · FIXTURE_FAIL.
#
# 훅은 항상 exit 0 이라 rc 로는 판정하지 않는다 — stdout 의 존재·바이트·내용이 전부다.
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${ENV_HOOK-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

TOK_ENV_WARN='harness.env 판독 경고'       # 판독 불가 키 나열(기존 문구)
TOK_SLOT_NOTE='관할 폴더 키는'             # 셋째 종류 안내(키 이름 없음)
TOK_SLOT_WARN='추가 관할 폴더 경고'        # 값은 읽혔지만 쓸 수 없는 슬롯
TOK_MODULE='모듈을 읽지 못했다'            # extra_problem_text module

# 187398c 의 check-harness-env.sh 91행이 HARNESS_TYPECHECK_CMD 하나를 나열할 때의
# stdout 바이트(끝 개행 포함은 비교 쪽이 붙인다). 키가 없거나 정상이면 이 바이트여야
# 한다(I2 — kty A).
GOLDEN_TC_BAD='{"systemMessage":"harness.env 판독 경고: HARNESS_TYPECHECK_CMD — 이 키의 값을 믿을 수 없습니다(중복 선언·지원 문법 밖·닫히지 않은 따옴표·읽기 실패 중 하나). 판독기는 이런 값을 미설정으로 취급합니다 — 검사 명령 키는 검사가 조용히 생략되고, 게이트 스위치 키는 안전측인 켜짐으로 동작합니다. 파일 첫머리의 문법 규칙을 확인하세요."}'

ENV_OUT_FILE=''   # 직전 run_env_hook 의 stdout 파일(바이트 비교용)
ENV_PROJ=''       # 직전 new_env_project 가 만든 프로젝트

#######################################
# 편집 검증 훅이 설치된 프로젝트를 만들어 ENV_PROJ 에 담는다. 명령 치환으로 받지
# 않는다 — 서브셸에서 세운 FIXTURE_FAIL 은 호출자에게 닿지 않는다.
# Globals:
#   COMMON, ENV_HOOK, MODULE (읽음) · ENV_PROJ, FIXTURE_FAIL (씀)
# Arguments:
#   $1 — 1 이면 슬롯 모듈도 설치, $2 — harness.env 내용(바이트 그대로)
# Returns:
#   0 · 1 픽스처 실패
#######################################
new_env_project() {
  local p
  ENV_PROJ=''
  p="$(new_dir envproj)" || { FIXTURE_FAIL='임시 디렉토리'; return 1; }
  mkdir -p "$p/.claude/hooks" "$p/.claude/harness" \
    || { FIXTURE_FAIL='프로젝트 골격'; return 1; }
  cp "$COMMON" "$ENV_HOOK" "$p/.claude/hooks/" \
    || { FIXTURE_FAIL='훅 복사'; return 1; }
  if [[ "$1" == 1 ]]; then
    cp "$MODULE" "$p/.claude/hooks/" 2>/dev/null \
      || { FIXTURE_FAIL='슬롯 모듈 복사(모듈이 없다)'; return 1; }
  fi
  printf '%s' "$2" > "$p/.claude/harness/harness.env"
  ENV_PROJ="$p"
}

#######################################
# 그 프로젝트의 harness.env 편집 payload 로 훅을 돌린다. 앰비언트 탈출구는 지운다.
# Globals:
#   TMPROOT, BASH (읽음) · OUT, ERR, RC, DID_RUN, ENV_OUT_FILE (씀)
# Arguments:
#   $1 — 프로젝트, $2... — 추가 환경 할당(NAME=값)
#######################################
run_env_hook() {
  local p="$1" payf="$TMPROOT/pay.$$" errf="$TMPROOT/err.$$"
  shift
  OUT=''; ERR=''; RC=999; DID_RUN=1
  ENV_OUT_FILE="$TMPROOT/out.$RANDOM.$$"
  python3 -c 'import json, sys
with open(sys.argv[2], "w", encoding="utf-8") as fh:
    fh.write(json.dumps({"tool_input": {"file_path": sys.argv[1]}}))' \
    "$p/.claude/harness/harness.env" "$payf"
  (cd "$TMPROOT" && env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} \
    CLAUDE_PROJECT_DIR="$p" "$BASH" "$p/.claude/hooks/check-harness-env.sh" \
    <"$payf" >"$ENV_OUT_FILE" 2>"$errf")
  RC=$?
  OUT="$(cat "$ENV_OUT_FILE" 2>/dev/null)"
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$payf" "$errf"
}

# env_hook_broken — 훅이 실패했거나 stderr 를 냈으면 사유를 낸다(PostToolUse 계약).
env_hook_broken() {
  if [[ "$RC" -ne 0 ]]; then printf 'rc=%s (기대 0)' "$RC"
  elif [[ -n "$ERR" ]]; then printf 'stderr 가 비어 있지 않다: [%s]' "$ERR"
  fi
}

# count_of <문자열> <조각> — 조각이 몇 번 나오는가.
count_of() {
  local s="$1" n=0
  while contains "$s" "$2"; do s="${s#*"$2"}"; n=$((n + 1)); done
  printf '%s' "$n"
}

h01() { # 새 키 rc=1(문법 밖) → 다른 키처럼 나열 + 셋째 안내. 안내에는 키 이름이 없다
        # — 나열된 키만 키 이름이어야 "정상 키가 나열됐다" 단언이 성립한다(c02·c03).
  local name='h01 새 키 판독 불가 → 나열 + 셋째 안내(키 이름 없음)' why='' p
  new_env_project 1 'HARNESS_EXTRA_GATE_DIRS= "/x"'$'\n' \
    || { report "$name" ''; return; }
  p="$ENV_PROJ"
  run_env_hook "$p"
  why="$(env_hook_broken)"
  if [[ -n "$why" ]]; then :
  elif ! json_message_ok "$ENV_OUT_FILE"; then why="JSON 한 줄이 아니다: [$OUT]"
  elif ! contains "$OUT" "$TOK_ENV_WARN"; then why="판독 경고가 없다: [$OUT]"
  elif ! contains "$OUT" 'HARNESS_EXTRA_GATE_DIRS'; then why='새 키가 나열되지 않았다'
  elif ! contains "$OUT" "$TOK_SLOT_NOTE"; then why='셋째 안내(관할 폴더 키)가 없다'
  elif [[ "$(count_of "$OUT" 'HARNESS_')" -ne 1 ]]; then
    why="키 이름이 나열 밖에도 있다: [$OUT]"
  fi
  if [[ -z "$why" ]]; then  # 다른 키와 함께 불량이어도 둘 다 나열된다
    new_env_project 1 \
      'HARNESS_TYPECHECK_CMD= "x"'$'\n''HARNESS_EXTRA_GATE_DIRS= "/x"'$'\n' \
      || { report "$name" ''; return; }
    p="$ENV_PROJ"
    run_env_hook "$p"
    if ! contains "$OUT" 'HARNESS_TYPECHECK_CMD' \
       || [[ "$(count_of "$OUT" 'HARNESS_')" -ne 2 ]] \
       || ! contains "$OUT" "$TOK_SLOT_NOTE"; then
      why="두 키 불량에서 나열·안내가 어긋났다: [$OUT]"
    fi
  fi
  report "$name" "$why"
}

h02() { # 값은 읽혔지만 쓸 수 없다 → 사유별 문구. 판독 경고(나열)와는 다른 줄이다.
  local name='h02 값 불량(: · 상대 · 없는 폴더 · / · ~사용자 · 없는 ~/) → 사유' why=''
  local fix p pair val tok
  fix="$(new_dir h02)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  for pair in "a:b@: 가 있다" "rel/x@절대경로가 아니다" \
              "$fix/nope@없거나 들어갈 수 없다" "/@/ 는 관할 폴더로" \
              "~bob/x@펼칠 수 없다" "~/nope@없거나 들어갈 수 없다"; do
    val="${pair%@*}"
    tok="${pair##*@}"
    new_env_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$val\""$'\n' \
      || { report "$name" ''; return; }
    p="$ENV_PROJ"
    run_env_hook "$p" HOME="$fix"
    why="$(env_hook_broken)"
    if [[ -n "$why" ]]; then why="[$val] $why"
    elif ! json_message_ok "$ENV_OUT_FILE"; then
      why="[$val] JSON 한 줄이 아니다: [$OUT]"
    elif ! contains "$OUT" "$TOK_SLOT_WARN"; then why="[$val] 슬롯 경고가 없다: [$OUT]"
    elif ! contains "$OUT" "$tok"; then why="[$val] 사유 문구 [$tok] 없음: [$OUT]"
    elif contains "$OUT" "$TOK_ENV_WARN"; then why="[$val] 판독 경고로 잘못 나열됐다"
    fi
    [[ -n "$why" ]] && break
  done
  report "$name" "$why"
}

h03() { # 정상 값(절대 · ~/ · 심링크 폴더) → 침묵.
  local name='h03 정상 값(절대 · ~/ · 심링크) → 침묵' why='' fix p val
  fix="$(new_dir h03)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  mkdir -p "$fix/slot" && ln -s "$fix/slot" "$fix/link" \
    || { FIXTURE_FAIL='슬롯 폴더'; report "$name" ''; return; }
  for val in "$fix/slot" '~/slot' "$fix/link"; do
    new_env_project 1 "HARNESS_EXTRA_GATE_DIRS=\"$val\""$'\n' \
      || { report "$name" ''; return; }
    p="$ENV_PROJ"
    run_env_hook "$p" HOME="$fix"
    why="$(env_hook_broken)"
    [[ -z "$why" && -n "$OUT" ]] && why="위양성 — 출력이 있다: [$OUT]"
    if [[ -n "$why" ]]; then why="[$val] $why"; break; fi
  done
  report "$name" "$why"
}

h04() { # 다른 키만 불량 → 187398c 와 바이트 동일. 새 키가 없을 때와 정상일 때 둘 다.
  local name='h04 다른 키만 불량 → 기존 바이트(새 키 부재·정상 둘 다)' why='' fix p
  local body golden="$TMPROOT/golden.$$"
  fix="$(new_dir h04)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  mkdir -p "$fix/slot"
  printf '%s\n' "$GOLDEN_TC_BAD" > "$golden"
  local slot_line="HARNESS_EXTRA_GATE_DIRS=\"$fix/slot\""$'\n'
  for body in 'HARNESS_TYPECHECK_CMD= "x"'$'\n' \
              'HARNESS_TYPECHECK_CMD= "x"'$'\n'"$slot_line"; do
    new_env_project 1 "$body" || { report "$name" ''; return; }
    p="$ENV_PROJ"
    run_env_hook "$p"
    why="$(env_hook_broken)"
    if [[ -z "$why" ]] && ! cmp -s "$golden" "$ENV_OUT_FILE"; then
      why="바이트가 다르다: [$OUT]"
    fi
    if [[ -n "$why" ]]; then
      contains "$body" EXTRA && why="(새 키 정상) $why" || why="(새 키 부재) $why"
      break
    fi
  done
  rm -f "$golden"
  report "$name" "$why"
}

h05() { # 모듈 없음 + 새 키 값 → module 문구. 문구는 _common.sh 에 있어야 나간다(cx).
  local name='h05 모듈 없음 + 새 키 → module 문구(_common.sh 에서)' why='' p
  new_env_project 0 'HARNESS_EXTRA_GATE_DIRS="rel/x"'$'\n' \
    || { report "$name" ''; return; }
  p="$ENV_PROJ"
  run_env_hook "$p"
  why="$(env_hook_broken)"
  if [[ -n "$why" ]]; then :
  elif ! json_message_ok "$ENV_OUT_FILE"; then why="JSON 한 줄이 아니다: [$OUT]"
  elif ! contains "$OUT" "$TOK_SLOT_WARN"; then why="슬롯 경고가 없다: [$OUT]"
  elif ! contains "$OUT" "$TOK_MODULE"; then why="module 문구가 없다: [$OUT]"
  fi
  report "$name" "$why"
}
