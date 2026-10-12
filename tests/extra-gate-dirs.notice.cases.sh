#!/usr/bin/env bash
# extra-gate-dirs.notice.cases.sh — 완료 게이트 훅(mark-needs-audit)의 슬롯 알림과
# 단일 출구(finish_hook) 케이스. 키가 없을 때의 출력 바이트(I2)가 이 파일의 핵심이다.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기 있다: new_dir · report · contains · flat · is_root · json_message_ok ·
# COMMON · MODULE · HOOKS · TMPROOT · OUT · ERR · RC · DID_RUN · FIXTURE_FAIL.
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [[ -z "${HOOKS-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

MNA_HOOK="$HOOKS/mark-needs-audit.sh"
TOK_NOTICE='추가 관할 폴더 슬롯'   # 알림 머리 조각(MSG_EXTRA_HEAD)

# 187398c 의 mark-needs-audit.sh 67-71행 상수 바이트(골든). 훅 상수를 읽지 않고 여기
# 박아 둔다 — 훅 쪽 상수가 표류해도 같이 움직이지 않아야 골든이다.
GOLDEN_NEWLINE='편집 경로에 개행이 있어 게이트 플래그를 기록하지 않았다. 줄 단위 플래그 파일이 오염되기 때문이다. 수동으로 확인하라.'
GOLDEN_TRUNCATED='이 명령이 바꾼 파일이 너무 많아 일부만 게이트에 기록했다. 나머지에는 게이트가 서지 않았으니 수동으로 확인하라.'
GOLDEN_PARTIAL='이 명령이 바꾼 파일 중 일부는 게이트에 기록하지 못했다(경로에 개행이 있거나 기록에 실패). 그 파일들은 수동으로 확인하라.'

MNA_PROJ=''       # 직전 new_mna_project 가 만든 프로젝트
ENV_NO_KEY='HARNESS_TYPECHECK_CMD=""'$'\n'   # 정상 판독 · 슬롯 키 부재
MNA_OUT_FILE=''   # 직전 run_mna 의 stdout 파일(바이트 비교용)
# run_mna 가 payload·환경에 더 싣는 것(케이스가 `local` 로 잠깐 바꾼다 — 기본은 없음).
MNA_CWD=''        # 비어 있지 않으면 payload 의 cwd
MNA_FAIL=0        # 1 이면 PostToolUseFailure 모양(error 필드)
MNA_NOHOME=0      # 1 이면 HOME 을 지우고 훅을 돌린다

#######################################
# 완료 게이트 훅이 설치된 프로젝트를 만들어 MNA_PROJ 에 담는다(src/ 포함).
# Globals:
#   COMMON, MNA_HOOK, MODULE (읽음) · MNA_PROJ, FIXTURE_FAIL (씀)
# Arguments:
#   $1 — 1 이면 슬롯 모듈도 설치, $2 — harness.env 내용 · __NOFILE__ · __DIR__
# Returns:
#   0 · 1 픽스처 실패
#######################################
new_mna_project() {
  local p
  MNA_PROJ=''
  p="$(new_dir mna)" || { FIXTURE_FAIL='임시 디렉토리'; return 1; }
  mkdir -p "$p/.claude/hooks" "$p/.claude/harness" "$p/src" \
    || { FIXTURE_FAIL='프로젝트 골격'; return 1; }
  cp "$COMMON" "$MNA_HOOK" "$p/.claude/hooks/" \
    || { FIXTURE_FAIL='훅 복사'; return 1; }
  if [[ "$1" == 1 ]]; then
    cp "$MODULE" "$p/.claude/hooks/" || { FIXTURE_FAIL='모듈 복사'; return 1; }
  fi
  case "$2" in
    __NOFILE__) ;;
    __DIR__) mkdir "$p/.claude/harness/harness.env" ;;
    *) printf '%s' "$2" > "$p/.claude/harness/harness.env" ;;
  esac
  MNA_PROJ="$p"
}

# set_env <프로젝트> <내용> — harness.env 를 그 내용으로 바꾼다.
set_env() { printf '%s' "$2" > "$1/.claude/harness/harness.env"; }

# make_window <프로젝트> — 오래된 Bash 창 하나. 고정틀이 이미 만든 파일은 창보다 더
# 오래되게 돌려 놓는다 — 그래야 스윕 대상이 그 뒤 시험이 만든 파일뿐이라 판정 순서가
# 결정적이다(sleep 없이).
make_window() {
  find "$1" -exec touch -t 201901010000 {} + \
    && mkdir -p "$1/.claude/.bash-windows" \
    && : > "$1/.claude/.bash-windows/w.$RANDOM" \
    && touch -t 202001010000 "$1/.claude/.bash-windows"/w.*
}

#######################################
# 훅을 실제로 돌린다. payload 는 python 이 JSON 으로 만든다(개행·따옴표 경로 안전).
# Globals:
#   TMPROOT, BASH (읽음) · OUT, ERR, RC, DID_RUN, MNA_OUT_FILE (씀)
# Arguments:
#   $1 — 프로젝트, $2 — edit|bash, $3 — 편집 경로 또는 명령,
#   $4 — closed 면 stdout 을 닫고 돌린다(출력 실패 주입).
#   MNA_CWD · MNA_FAIL · MNA_NOHOME 전역도 읽는다(위 선언 주석).
#######################################
run_mna() {
  local p="$1" kind="$2" arg="$3" mode="${4:-}" payf errf unset_home=''
  payf="$TMPROOT/mpay.$$"
  errf="$TMPROOT/merr.$$"
  OUT=''; ERR=''; RC=999; DID_RUN=1
  MNA_OUT_FILE="$TMPROOT/mout.$RANDOM.$$"
  python3 -c 'import json, sys
key = "file_path" if sys.argv[1] == "edit" else "command"
body = {"tool_input": {key: sys.argv[2]}}
if sys.argv[4]:
    body["cwd"] = sys.argv[4]
if sys.argv[5] == "1":
    body["hook_event_name"] = "PostToolUseFailure"
    body["error"] = "Exit code 1"
with open(sys.argv[3], "w", encoding="utf-8") as fh:
    fh.write(json.dumps(body))' \
    "$kind" "$arg" "$payf" "$MNA_CWD" "$MNA_FAIL"
  [[ "$MNA_NOHOME" == 1 ]] && unset_home='-u HOME'
  if [[ "$mode" == closed ]]; then
    (cd "$p" && env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS $unset_home \
      CLAUDE_PROJECT_DIR="$p" "$BASH" "$p/.claude/hooks/mark-needs-audit.sh" \
      <"$payf" >&- 2>"$errf")
    RC=$?
    : > "$MNA_OUT_FILE"
  else
    (cd "$p" && env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS $unset_home \
      CLAUDE_PROJECT_DIR="$p" "$BASH" "$p/.claude/hooks/mark-needs-audit.sh" \
      <"$payf" >"$MNA_OUT_FILE" 2>"$errf")
    RC=$?
  fi
  OUT="$(cat "$MNA_OUT_FILE" 2>/dev/null)"
  ERR="$(cat "$errf" 2>/dev/null)"
  rm -f "$payf" "$errf"
}

# problem_text_of <코드> — _common.sh 정본의 사유 문구(알림이 그대로 싣는지 대조용).
problem_text_of() {
  env -i PATH="$PATH" CLAUDE_PROJECT_DIR="$TMPROOT" "$BASH" -c \
    '. "$0" && extra_problem_text "$1"' "$COMMON" "$1"
}

# expect_silent <설명> — 직전 실행이 rc 0 · stderr 0 · stdout 0바이트인가.
expect_silent() {
  if [[ "$RC" -ne 0 ]]; then printf '%s: rc=%s' "$1" "$RC"
  elif [[ -n "$ERR" ]]; then printf '%s: stderr=[%s]' "$1" "$ERR"
  elif [[ -s "$MNA_OUT_FILE" ]]; then printf '%s: 출력이 있다 [%s]' "$1" "$OUT"
  fi
}

# expect_notice <코드> <설명> — 직전 실행이 그 사유의 알림 JSON 한 줄을 냈는가.
expect_notice() {
  local text
  text="$(problem_text_of "$1")"
  if [[ "$RC" -ne 0 ]]; then printf '%s: rc=%s' "$2" "$RC"
  elif [[ -n "$ERR" ]]; then printf '%s: stderr=[%s]' "$2" "$ERR"
  elif [[ -z "$text" ]]; then printf '%s: 사유 코드 %s 의 문구가 없다' "$2" "$1"
  elif ! json_message_ok "$MNA_OUT_FILE"; then
    printf '%s: JSON 한 줄이 아니다 [%s]' "$2" "$OUT"
  elif ! contains "$OUT" "$TOK_NOTICE"; then
    printf '%s: 알림 머리 없음 [%s]' "$2" "$OUT"
  elif ! contains "$OUT" "$text"; then
    printf '%s: 사유 문구(%s)가 그대로 실리지 않았다 [%s]' "$2" "$1" "$OUT"
  fi
}

# expect_flag <프로젝트> <값> — .needs-audit 가 그 값 한 줄인가(판정 불변 확인).
expect_flag() {
  local got
  got="$(cat "$1/.claude/.needs-audit" 2>/dev/null; printf x)"
  [[ "$got" == "$2"$'\n'x ]] \
    || printf '.needs-audit [%s] (기대 [%s])' "${got%x}" "$2"
}

# --- a: 키 판독 상태별 출력 (I2 · G4) --------------------------------------

a01() { # harness.env 없음 → 무출력, 판정 그대로.
  local name='a01 harness.env 없음 → 무출력·판정 불변' why='' p
  new_mna_project 1 __NOFILE__ || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_silent '파일 없음')"
  [[ -z "$why" ]] && why="$(expect_flag "$p" src/a.ts)"
  report "$name" "$why"
}

# poison_module <프로젝트> — 적재되면 표시 파일을 남기는 모듈로 바꾼다(미적재 관측).
poison_module() {
  printf ': > "${CLAUDE_PROJECT_DIR}/module-loaded"\n' \
    > "$1/.claude/hooks/_extra_gate_dirs.sh"
}

a02() { # 정상 파일 · 키 부재 → 무출력, 모듈을 적재하지 않는다(ABSENT 비용 = 판독 1회).
  local name='a02 키 부재 → 무출력·모듈 미적재' why='' p
  new_mna_project 1 "$ENV_NO_KEY" || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"; poison_module "$p"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_silent '키 부재')"
  [[ -z "$why" && -e "$p/module-loaded" ]] && why='ABSENT 인데 모듈을 적재했다'
  [[ -z "$why" ]] && why="$(expect_flag "$p" src/a.ts)"
  report "$name" "$why"
}

a03() { # 키 = 빈 값 → 부재와 같다(무출력·모듈 미적재).
  local name='a03 키 빈 값 → 무출력·모듈 미적재' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS=""'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"; poison_module "$p"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_silent '키 빈 값')"
  [[ -z "$why" && -e "$p/module-loaded" ]] && why='빈 값인데 모듈을 적재했다'
  report "$name" "$why"
}

a04() { # 키는 빈 값이어도 파일을 못 믿으면(다른 키의 닫히지 않은 따옴표) 알린다(kty A).
  local name='a04 키 빈 값 + 파일 판독 불가 → 알림 untrusted' why='' p
  new_mna_project 1 \
    'HARNESS_EXTRA_GATE_DIRS=""'$'\n''HARNESS_TYPECHECK_CMD="pnpm'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice untrusted '닫히지 않은 따옴표')"
  [[ -z "$why" ]] && why="$(expect_flag "$p" src/a.ts)"
  report "$name" "$why"
}

a05() { # 읽기 불가 → 알림, stderr 0(판독기 경고는 막는다). 권한 주입이라 root 는 실패 보고.
  local name='a05 harness.env 읽기 불가 → 알림 untrusted · stderr 0' why='' p
  DID_RUN=1
  if is_root; then
    report "$name" 'root 로 실행하면 이 픽스처가 성립하지 않는다 (비-root 로 돌려라)'
    return
  fi
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="/x"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  chmod 000 "$p/.claude/harness/harness.env"
  run_mna "$p" edit "$p/src/a.ts"
  chmod 644 "$p/.claude/harness/harness.env"
  why="$(expect_notice untrusted '읽기 불가')"
  report "$name" "$why"
}

a06() { # 키 값은 정상인데 모듈이 없다 → 알림 module, stderr 0.
  local name='a06 키 있음 · 모듈 없음 → 알림 module' why='' p
  new_mna_project 0 '' || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  set_env "$p" "HARNESS_EXTRA_GATE_DIRS=\"$p/src\""$'\n'
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice module '모듈 없음')"
  report "$name" "$why"
}

a07() { # Z4 — harness.env 자리가 디렉터리면 "키 없음"이 아니라 알림 untrusted.
  local name='a07 harness.env 가 디렉터리 → 알림 untrusted (Z4)' why='' p
  new_mna_project 1 __DIR__ || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice untrusted '디렉터리')"
  report "$name" "$why"
}

# --- g: 키 부재일 때 187398c 와 바이트 동일 (I2 — 회귀 고정) ---------------

# expect_golden <메시지> <설명> — 직전 stdout 이 {"systemMessage":"<메시지>"}+LF 바이트인가.
expect_golden() {
  local want="$TMPROOT/golden.$$"
  printf '{"systemMessage":"%s"}\n' "$1" > "$want"
  if [[ "$RC" -ne 0 || -n "$ERR" ]]; then
    printf '%s: rc=%s stderr=[%s]' "$2" "$RC" "$ERR"
  elif ! cmp -s "$want" "$MNA_OUT_FILE"; then
    printf '%s: 바이트가 다르다 [%s]' "$2" "$OUT"
  fi
  rm -f "$want"
}

g01() { # 키 부재 + Edit 개행 경로 → MSG_NEWLINE 골든 바이트.
  local name='g01 키 부재 · Edit 개행 경로 → 187398c 바이트' why='' p
  new_mna_project 1 "$ENV_NO_KEY" || { report "$name" ''; return; }
  p="$MNA_PROJ"
  run_mna "$p" edit "$p/src/new"$'\n'"line.ts"
  why="$(expect_golden "$GOLDEN_NEWLINE" 'MSG_NEWLINE')"
  report "$name" "$why"
}

g02() { # 키 부재 + Bash 스윕 개행 파일 → MSG_SWEEP_PARTIAL 골든. 파일 하나의 판정 알림
        # (JUDGE_MSG)이 스윕 최종 메시지에 섞이면 바이트가 달라진다(X3). 스윕 대상은
        # 개행 파일 하나뿐이라 그 판정 알림이 마지막에 남는다(변이 판별이 결정적이다).
  local name='g02 키 부재 · 스윕 개행 파일 → 187398c 바이트' why='' p
  new_mna_project 1 "$ENV_NO_KEY" || { report "$name" ''; return; }
  p="$MNA_PROJ"
  make_window "$p" || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  : > "$p/src/new"$'\n'"line.go"
  run_mna "$p" bash 'generate'
  why="$(expect_golden "$GOLDEN_PARTIAL" 'MSG_SWEEP_PARTIAL')"
  report "$name" "$why"
}

g03() { # 키 부재 + 스윕 상한(200) 초과 → MSG_SWEEP_TRUNCATED 골든.
  local name='g03 키 부재 · 스윕 상한 초과 → 187398c 바이트' why='' p i
  new_mna_project 1 "$ENV_NO_KEY" || { report "$name" ''; return; }
  p="$MNA_PROJ"
  make_window "$p" || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  for ((i = 0; i < 205; i++)); do : > "$p/src/note_$i.md"; done
  run_mna "$p" bash 'generate'
  why="$(expect_golden "$GOLDEN_TRUNCATED" 'MSG_SWEEP_TRUNCATED')"
  report "$name" "$why"
}

# --- n: 알림의 횟수 · 표식 · 출구 ------------------------------------------

n01() { # 같은 사유는 세션당 한 번만 알린다. 판정은 그대로다.
  local name='n01 같은 사유 → 첫 호출만 알림' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice colon '첫 호출')"
  if [[ -z "$why" ]]; then
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_silent '둘째 호출')"
  fi
  [[ -z "$why" ]] && why="$(expect_flag "$p" src/a.ts)"
  report "$name" "$why"
}

n02() { # 사유가 바뀌면 다시 알린다.
  local name='n02 사유가 바뀜 → 다시 알림' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice colon '처음 사유')"
  if [[ -z "$why" ]]; then
    set_env "$p" 'HARNESS_EXTRA_GATE_DIRS="rel/x"'$'\n'
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_notice relative '바뀐 사유')"
  fi
  if [[ -z "$why" ]]; then
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_silent '바뀐 사유의 둘째 호출')"
  fi
  report "$name" "$why"
}

n03() { # 정상화되면 표식을 지운다 — 다시 같은 사유로 망가지면 다시 알린다.
  local name='n03 정상화 → 표식 삭제 → 같은 사유 재발 시 다시 알림' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice colon '불량')"
  if [[ -z "$why" ]]; then
    set_env "$p" "HARNESS_EXTRA_GATE_DIRS=\"$p/src\""$'\n'
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_silent '정상화')"
  fi
  if [[ -z "$why" ]]; then
    set_env "$p" 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n'
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_notice colon '재발')"
  fi
  report "$name" "$why"
}

n04() { # 판정 0건인 Bash(창은 있다)도, 빈 명령도 알림이 나간다 — 알림은 판정과 무관한
        # 출구다(빈 명령 출구까지 finish_hook 을 지나는지 함께 잰다).
  local name='n04 판정 0건 Bash · 빈 명령 → 알림' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"
  make_window "$p" || { FIXTURE_FAIL='창'; report "$name" ''; return; }
  run_mna "$p" bash 'ls -la'
  why="$(expect_notice colon '판정 0건')"
  [[ -z "$why" && -s "$p/.claude/.needs-audit" ]] && why='읽기 전용 명령이 플래그를 세웠다'
  if [[ -z "$why" ]]; then
    new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
      || { report "$name" ''; return; }
    run_mna "$MNA_PROJ" bash ''
    why="$(expect_notice colon '빈 명령')"
  fi
  report "$name" "$why"
}

n05() { # 사유 8종(untrusted·module·colon·tilde·relative·missing·newline·root) 모두
        # JSON 한 줄이고, _common.sh 문구를 그대로 싣고, 경로(고정틀·원문 값)가 없다.
  local name='n05 사유 8종 — JSON 한 줄 · 정본 문구 · 경로 0' why='' fix p spec code
  local mod body bad
  fix="$(new_dir n05)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  mkdir -p "$fix/nl"$'\n' && ln -s "$fix/nl"$'\n' "$fix/link" \
    || { FIXTURE_FAIL='개행 이름 폴더'; report "$name" ''; return; }
  for spec in "untrusted|1|HARNESS_TYPECHECK_CMD=\"pnpm" \
              "module|0|HARNESS_EXTRA_GATE_DIRS=\"$fix\"" \
              "colon|1|HARNESS_EXTRA_GATE_DIRS=\"$fix:$fix\"" \
              "tilde|1|HARNESS_EXTRA_GATE_DIRS=\"~nobody-x/q\"" \
              "relative|1|HARNESS_EXTRA_GATE_DIRS=\"relx/q\"" \
              "missing|1|HARNESS_EXTRA_GATE_DIRS=\"$fix/nope\"" \
              "newline|1|HARNESS_EXTRA_GATE_DIRS=\"$fix/link\"" \
              "root|1|HARNESS_EXTRA_GATE_DIRS=\"/\""; do
    code="${spec%%|*}"; mod="${spec#*|}"; body="${mod#*|}"; mod="${mod%%|*}"
    new_mna_project "$mod" "$body"$'\n' || { report "$name" ''; return; }
    p="$MNA_PROJ"; : > "$p/src/a.ts"
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_notice "$code" "[$code]")"
    if [[ -z "$why" ]] && contains "$OUT" "$TMPROOT"; then
      why="[$code] 메시지에 경로가 실렸다 [$OUT]"
    fi
    for bad in relx nobody-x; do
      [[ -z "$why" ]] && contains "$OUT" "$bad" \
        && why="[$code] 원문 값이 실렸다 [$OUT]"
    done
    [[ -n "$why" ]] && break
  done
  report "$name" "$why"
}

n06() { # 단일 출구 — 창 없는 Bash 가 첫 호출이어도 알림이 그 호출에서 나가고, 다음
        # Edit 은 중복 알림이 없다. 표식은 출력이 성공한 뒤에만 쓴다: stdout 이 닫힌
        # 호출은 표식을 남기지 않아 다음 호출이 알린다.
  local name='n06 창 없는 첫 Bash 알림 · 출력 실패 호출은 표식 없음' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" bash 'ls'
  why="$(expect_notice colon '창 없는 Bash')"
  if [[ -z "$why" ]]; then
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_silent '다음 Edit')"
  fi
  if [[ -z "$why" ]]; then
    new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
      || { report "$name" ''; return; }
    p="$MNA_PROJ"; : > "$p/src/a.ts"
    run_mna "$p" edit "$p/src/a.ts" closed
    if [[ "$RC" -ne 0 ]]; then why="stdout 닫힌 호출 rc=$RC"
    else
      why="$(expect_flag "$p" src/a.ts)"
      run_mna "$p" edit "$p/src/a.ts"
      [[ -z "$why" ]] && why="$(expect_notice colon '출력 실패 다음 호출')"
    fi
  fi
  report "$name" "$why"
}

n07() { # 키를 지우면(ABSENT) 옛 표식을 지운다 — 같은 사유로 다시 망가지면 다시 알린다.
  local name='n07 키 삭제 → 같은 사유 재불량 시 다시 알림' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice colon '불량')"
  if [[ -z "$why" ]]; then
    set_env "$p" 'HARNESS_TYPECHECK_CMD=""'$'\n'
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_silent '키 삭제')"
  fi
  if [[ -z "$why" ]]; then
    set_env "$p" 'HARNESS_EXTRA_GATE_DIRS="a:b"'$'\n'
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_notice colon '재불량')"
  fi
  report "$name" "$why"
}

# --- e: 값 불량의 사유 (완료 게이트 훅 경로) --------------------------------

e03() { # `:` → colon 알림. 판정은 그대로다.
  local name='e03 값에 : → 알림 colon · 판정 불변' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="/a:/b"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice colon ':')"
  [[ -z "$why" ]] && why="$(expect_flag "$p" src/a.ts)"
  report "$name" "$why"
}

e04() { # 상대 · `~사용자` · 없는 폴더 → 각 사유 알림.
  local name='e04 상대 · ~사용자 · 없는 폴더 → 각 사유 알림' why='' p spec
  for spec in 'relative|rel/x' 'tilde|~bob/x' \
              'missing|/nonexistent-extra-gate/x'; do
    new_mna_project 1 "HARNESS_EXTRA_GATE_DIRS=\"${spec#*|}\""$'\n' \
      || { report "$name" ''; return; }
    p="$MNA_PROJ"; : > "$p/src/a.ts"
    run_mna "$p" edit "$p/src/a.ts"
    why="$(expect_notice "${spec%%|*}" "[${spec#*|}]")"
    [[ -n "$why" ]] && break
  done
  report "$name" "$why"
}

e16() { # `/` → root 알림(모든 저장소 관할은 수요가 없고 성분 경계 식에 특수 처리가 든다).
  local name='e16 값 / → 알림 root' why='' p
  new_mna_project 1 'HARNESS_EXTRA_GATE_DIRS="/"'$'\n' \
    || { report "$name" ''; return; }
  p="$MNA_PROJ"; : > "$p/src/a.ts"
  run_mna "$p" edit "$p/src/a.ts"
  why="$(expect_notice root '/')"
  report "$name" "$why"
}
