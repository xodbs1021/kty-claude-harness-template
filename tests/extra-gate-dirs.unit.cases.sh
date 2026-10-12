#!/usr/bin/env bash
# extra-gate-dirs.unit.cases.sh — 슬롯 모듈 함수 · 기록 형식 · 키 판독 상태의 케이스.
#
# 실행 파일이 아니라 extra-gate-dirs.test.sh 가 source 하는 조각이다. 러너·도우미는
# 거기 있다: new_dir · run_module · run_common · report · contains · is_root · US ·
# MODULE · TMPROOT · OUT · ERR · RC · FIXTURE_FAIL.
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

# 러너를 거치지 않으면 도우미가 없어 전 케이스가 조용히 무판정이 된다 — fail-closed.
if [[ -z "${MODULE-}" ]]; then
  echo "✗ 단독 실행용이 아닙니다. ./tests/extra-gate-dirs.test.sh 를 실행하세요" >&2
  exit 1
fi

# 모듈의 공개 계약 이름(계획 2절 — 쓰기 record_*, 읽기 read_*).
UNIT_PUBLIC_FNS='validate_extra_gate_dir expand_home_path in_extra_gate_dir
is_slot_entry is_design_shaped sibling_workspace_of sibling_repo_of
home_path_tokens record_review_pending record_review_dirs read_review_verdict
read_review_dirs'

# --- u: set -u 안전 · 쓰기 계약 -------------------------------------------

u01() { # 모듈 함수 전부를 인자 없이·빈 슬롯으로 부른다 — 사망·누설 0, 경계 rc.
        # 빈 슬롯 in_extra_gate_dir → 1(cc4), `_workspace_` → 1(cc6).
  local name='u01 set -u 빈 환경 — 함수 전부 생존, 빈 슬롯·빈 이름 rc 1' why=''
  run_module '
for fn in $PUBLIC; do declare -F "$fn" >/dev/null || echo "MISSING $fn"; done
for fn in $(declare -F | awk "{ print \$3 }"); do "$fn" >/dev/null; done
in_extra_gate_dir /x; echo "in=$?"
sibling_repo_of /p/_workspace_; echo "sib=$?"
is_slot_entry /x /r; echo "slot=$?"
expand_home_path "~/x" >/dev/null; echo "exp=$?"
validate_extra_gate_dir "~/x"; echo "val=$? $EXTRA_GATE_PROBLEM"
echo "tok=[$(home_path_tokens "cat ~/x")]"
record_review_pending /v; echo "pend=$?"
record_review_dirs /v /d; echo "dirs=$?"
read_review_verdict /r >/dev/null
case $? in 0|3|4) echo "verdict=verdict-rc" ;; *) echo "verdict=fail" ;; esac
read_review_dirs >/dev/null || echo "rdirs=fail"
shopt -q nocasematch && echo LEAK
echo ALIVE' PUBLIC="$UNIT_PUBLIC_FNS"
  local want
  if [[ "$RC" -eq 90 ]]; then why='모듈 적재 실패'
  elif [[ "$RC" -ne 0 ]]; then why="rc=$RC — 셸이 죽었다: [$ERR]"
  elif [[ -n "$ERR" ]]; then why="stderr 가 비어 있지 않다: [$ERR]"
  elif ! contains "$OUT" 'ALIVE'; then why='끝까지 돌지 못했다'
  elif contains "$OUT" 'MISSING'; then
    why="공개 계약 이름이 없다: $(printf '%s\n' "$OUT" | grep MISSING | tr '\n' ' ')"
  elif contains "$OUT" 'LEAK'; then why='셸 옵션(nocasematch)이 새어 나왔다'
  fi
  for want in 'in=1' 'sib=1' 'slot=1' 'exp=1' 'val=1 tilde' 'tok=[]' \
              'pend=1' 'dirs=1' 'verdict=fail' 'rdirs=fail'; do
    [[ -n "$why" ]] && break
    contains "$OUT" "$want" || why="기대 [$want] 없음: $(printf '%s' "$OUT" \
      | tr '\n' ' ')"
  done
  report "$name" "$why"
}

u02() { # 쓰기 계약 — 갱신 표시 `값␟!`, 자리 `값␟/d…`, 빈 집합 `값␟-`(맨 값 금지),
        # 0x1F 는 rc 2·무기록, 쓰기 실패는 rc 1.
  local name='u02 쓰기 계약 — 바이트·rc 0/1/2·빈 집합 표지' why='' fix raw want
  fix="$(new_dir u02)" || { FIXTURE_FAIL='임시 디렉토리'; report "$name" ''; return; }
  mkdir "$fix/adir"
  run_module '
REVIEW_DIRS_FILE="$FIX/rec"
record_review_pending /s/T/a.go; echo "p=$?"
record_review_dirs /s/T/a.go /s/T/_workspace /s/_workspace_T; echo "d=$?"
record_review_dirs /s/x.go; echo "e=$?"
record_review_pending "/s/a${US}b"; echo "u1=$?"
record_review_dirs "/s/a${US}b"; echo "u2=$?"
record_review_dirs /s/b.go "/d${US}x"; echo "u3=$?"
REVIEW_DIRS_FILE="$FIX/adir"
record_review_pending /s/y.go; echo "f1=$?"
record_review_dirs /s/y.go /d; echo "f2=$?"' FIX="$fix"
  want="/s/T/a.go${US}!"$'\n'
  want="$want/s/T/a.go${US}/s/T/_workspace${US}/s/_workspace_T"$'\n'
  want="$want/s/x.go${US}-"$'\n'
  raw="$(cat "$fix/rec" 2>/dev/null; printf X)"
  raw="${raw%X}"
  if [[ "$RC" -eq 90 ]]; then why='모듈 적재 실패'
  elif [[ "$RC" -ne 0 || -n "$ERR" ]]; then why="rc=$RC stderr=[$ERR]"
  elif [[ "$raw" != "$want" ]]; then
    why="기록 바이트가 다르다: [$(printf '%s' "$raw" | od -c | head -5 | tr -s ' ')]"
  fi
  local w
  for w in p=0 d=0 e=0 u1=2 u2=2 u3=2 f1=1 f2=1; do
    [[ -n "$why" ]] && break
    contains "$OUT" "$w" \
      || why="rc 기대 [$w]: $(printf '%s' "$OUT" | tr '\n' ' ')"
  done
  report "$name" "$why"
}

# --- x: HOME 참조 범위 (정적) ---------------------------------------------

x01() { # 홈 참조(`$HOME`·`${HOME`)는 expand_home_path 의 머리 주석+본문에만 있고,
        # 그 본문이 `${HOME:-}` 로 직접 읽는다 — 홈 읽기가 다른 함수·훅으로 옮겨
        # 가면 적색. 본문의 case 패턴 글자(`'$HOME'`)만 남는 이동도 잡는다(변이 M3a).
  local name='x01 정적: HOME 참조는 expand_home_path 머리 주석+본문에만' why='' r
  DID_RUN=1
  [[ -f "$MODULE" ]] || { report "$name" '모듈 파일이 없다'; return; }
  r="$(LC_ALL=C awk '
/[$][{]?HOME/ { hit[++n] = NR }
/^#/ { if (!inc) bs = NR; inc = 1; next }
{ was = inc; inc = 0 }
index($0, "expand_home_path() {") == 1 {
  def = NR; hs = was ? bs : NR; body = 1
}
body && index($0, "${HOME:-}") { reads = 1 }
body && /^}/ { he = NR; body = 0 }
END {
  if (!def || !he) { print "nodef"; exit }
  for (i = 1; i <= n; i++) if (hit[i] < hs || hit[i] > he) out = out " " hit[i]
  if (out != "") print "outside" out
  else if (!reads) print "noread"
  else print "ok"
}' "$MODULE")"
  case "$r" in
    ok) ;;
    nodef) why='expand_home_path 정의를 찾지 못했다' ;;
    noread) why='expand_home_path 본문이 ${HOME:-} 로 읽지 않는다(옮겨 갔다)' ;;
    *) why="범위 밖 홈 참조 줄:${r#outside}" ;;
  esac
  report "$name" "$why"
}

# --- z2: 기록 판독의 보수 판정 --------------------------------------------
# 고정틀: 세션 루트 R(비git) · 슬롯 S · 저장소 자리 T · 값 V = T/a.go(플래그에 있다).
# 리뷰는 T/_workspace(d1)와 R/_workspace 양쪽에 **플래그보다 새 것**을 둔다 — 그래서
# 관대한 판독(빈 집합·자리로 해석)은 해제(rc 0)가 되고, 보수 판독만 missing-record 다.
# 대조(정상 꼴 → 해제)를 같은 고정틀에서 먼저 확인해야 "늘 막는 구현"이 통과하지 않는다.
Z2_FIX=''

# z2_fixture — 위 고정틀을 만들고 Z2_FIX 에 담는다. 실패하면 FIXTURE_FAIL.
z2_fixture() {
  local f
  f="$(new_dir z2)" || { FIXTURE_FAIL='임시 디렉토리'; return 1; }
  mkdir -p "$f/root/_workspace" "$f/slot/T/_workspace" "$f/slot/_workspace_T" \
    || { FIXTURE_FAIL='고정틀 폴더'; return 1; }
  printf '%s\n' "$f/slot/T/a.go" > "$f/flag"
  touch -t 202001010000 "$f/flag" || { FIXTURE_FAIL='touch -t'; return 1; }
  printf 'review\n' > "$f/slot/T/_workspace/03_codex_review.md"
  printf 'review\n' > "$f/root/_workspace/03_codex_review.md"
  Z2_FIX="$f"
}

#######################################
# 틀로 기록 파일을 쓰고 read_review_verdict 를 부른다. 틀의 `@V` 는 값, `@D` 는 자리
# d1, `|` 는 US 로 바뀐다. 바이트는 틀 그대로다 — 끝 개행 유무가 시험 축이라 명령
# 치환(끝 개행을 지운다)을 거치지 않고 파일에 바로 쓴다.
# Globals:
#   Z2_FIX, US (읽음) · OUT, ERR, RC (run_module 이 씀)
# Arguments:
#   $1 — 틀
#######################################
z2_verdict() {
  local t="$1"
  t="${t//@V/$Z2_FIX/slot/T/a.go}"
  t="${t//@D/$Z2_FIX/slot/T/_workspace}"
  printf '%s' "${t//|/$US}" > "$Z2_FIX/rec"
  run_module '
DUALREVIEW_FLAG="$FIX/flag"; REVIEW_DIRS_FILE="$FIX/rec"
EXTRA_GATE_DIR="$FIX/slot"
read_review_verdict "$FIX/root"; echo "rc=$?"' FIX="$Z2_FIX"
}

# flat <문자열> — 사유 문구에 싣도록 개행을 공백으로.
flat() { printf '%s' "$1" | tr '\n' ' '; }

# z2_expect <released|missing> <설명> — 직전 z2_verdict 결과를 판정해 사유를 낸다.
z2_expect() {
  local v="$Z2_FIX/slot/T/a.go" first
  first="$(printf '%s\n' "$OUT" | head -n 1)"
  if [[ "$RC" -eq 90 ]]; then printf '모듈 적재 실패'; return; fi
  if [[ "$RC" -ne 0 || -n "$ERR" ]]; then
    printf '%s: 셸 rc=%s stderr=[%s]' "$2" "$RC" "$ERR"; return
  fi
  case "$1" in
    released)
      contains "$OUT" 'rc=0' \
        || printf '%s: 해제(rc 0) 기대 — [%s]' "$2" "$(flat "$OUT")" ;;
    missing)
      if ! contains "$OUT" 'rc=3'; then
        printf '%s: 미충족(rc 3) 기대 — [%s]' "$2" "$(flat "$OUT")"
      elif ! contains "$first" 'missing-record'; then
        printf '%s: 첫 줄에 missing-record 없음 — [%s]' "$2" "$first"
      elif ! printf '%s\n' "$OUT" | grep -qxF -- "M $v"; then
        printf '%s: 값 나열(M 줄) 없음' "$2"
      fi ;;
  esac
}

z2a() { # Z2 — 잘린 ③ 이 맨 `값` 으로 남으면 빈 집합이 아니라 missing-record.
  local name='z2a 맨 값 줄 → missing-record(빈 집합으로 읽지 않는다)' why=''
  z2_fixture || { report "$name" ''; return; }
  z2_verdict '@V|@D
'
  why="$(z2_expect released '대조(정상 자리 줄)')"
  if [[ -z "$why" ]]; then
    z2_verdict '@V|@D
@V
'
    why="$(z2_expect missing '맨 값이 마지막 줄')"
  fi
  report "$name" "$why"
}

z2b() { # Z2 — 개행 없는 마지막 레코드(덧붙이기 중 잘림)는 모르는 꼴 → missing-record.
  local name='z2b 개행 없는 끝 레코드 V␟/d1␟/d → missing-record' why=''
  z2_fixture || { report "$name" ''; return; }
  z2_verdict '@V|!
@V|@D|/d
'
  why="$(z2_expect released '대조(같은 줄 + 개행)')"
  if [[ -z "$why" ]]; then
    z2_verdict '@V|!
@V|@D|/d'
    why="$(z2_expect missing '개행 없는 끝 레코드')"
  fi
  report "$name" "$why"
}

z2c() { # Z2 — 꼬리가 `-`·`!`·자리 셋 중 하나가 아니면 모르는 꼴 → missing-record.
  local name='z2c 모르는 꼴(혼합·빈 필드·상대 필드) → missing-record' why='' t
  z2_fixture || { report "$name" ''; return; }
  z2_verdict '@V|@D
'
  why="$(z2_expect released '대조(정상 자리 줄)')"
  for t in '@V|@D|!' '@V|-|@D' '@V||@D' '@V|@D|' '@V|' '@V|slot/T/_workspace' \
           '@V|!|@D'; do
    [[ -n "$why" ]] && break
    z2_verdict "$t"$'\n'
    why="$(z2_expect missing "꼬리 [$t]")"
  done
  report "$name" "$why"
}

# --- z4: 키 판독 상태의 자리 구분 (_common.sh) ----------------------------
# 판독기는 파일이 일반 파일이 아니면 rc 3(부재)을 낸다. 슬롯 래퍼는 "정말 없음"과
# "비정상 자리"를 가른다 — 정상 파일의 부재는 ABSENT(3) 그대로여야 기존 바이트가 산다.

# z4_project — harness/ 폴더까지 만든 프로젝트 경로. 실패하면 빈 값.
z4_project() {
  local p
  p="$(new_dir z4)" || return 1
  mkdir -p "$p/.claude/harness" || return 1
  printf '%s\n' "$p"
}

# z4_state <프로젝트> — 그 프로젝트에서 extra_gate_key_state 의 rc 를 OUT 에 "rc=N" 으로.
z4_state() {
  run_common "$1" 'extra_gate_key_state; echo "rc=$?"'
}

# z4_expect <기대 rc> <설명> — 직전 z4_state 결과 판정.
z4_expect() {
  if [[ "$RC" -eq 90 ]]; then printf '_common.sh 적재 실패'; return; fi
  if [[ "$RC" -ne 0 || -n "$ERR" ]]; then
    printf '%s: 셸 rc=%s stderr=[%s]' "$2" "$RC" "$ERR"; return
  fi
  [[ "$OUT" == "rc=$1" ]] || printf '%s: [%s] (기대 rc=%s)' "$2" "$OUT" "$1"
}

z4a() { # Z4 — harness.env 자리가 디렉터리면 UNTRUSTED. 대조: 파일 없음·키 없음은 ABSENT.
  local name='z4a harness.env 가 디렉터리 → UNTRUSTED (부재 대조는 ABSENT)' why='' p
  p="$(z4_project)" || { FIXTURE_FAIL='프로젝트'; report "$name" ''; return; }
  z4_state "$p"
  why="$(z4_expect 3 '대조(파일 없음)')"
  if [[ -z "$why" ]]; then
    printf 'HARNESS_TYPECHECK_CMD=""\n' > "$p/.claude/harness/harness.env"
    z4_state "$p"
    why="$(z4_expect 3 '대조(정상 파일·키 없음)')"
  fi
  if [[ -z "$why" ]]; then
    rm -f "$p/.claude/harness/harness.env"
    mkdir "$p/.claude/harness/harness.env"
    z4_state "$p"
    why="$(z4_expect 1 '디렉터리')"
  fi
  report "$name" "$why"
}

z4b() { # Z4 — .claude/harness 를 탐색할 수 없으면 UNTRUSTED. 권한 주입이라 root 는 실패 보고.
  local name='z4b .claude/harness 탐색 불가 → UNTRUSTED' why='' p
  DID_RUN=1
  if is_root; then
    report "$name" 'root 로 실행하면 이 픽스처가 성립하지 않는다 (비-root 로 돌려라)'
    return
  fi
  p="$(z4_project)" || { FIXTURE_FAIL='프로젝트'; report "$name" ''; return; }
  printf 'HARNESS_TYPECHECK_CMD=""\n' > "$p/.claude/harness/harness.env"
  chmod 600 "$p/.claude/harness" \
    || { FIXTURE_FAIL='chmod'; report "$name" ''; return; }
  z4_state "$p"
  why="$(z4_expect 1 '탐색 불가 폴더')"
  chmod 700 "$p/.claude/harness"
  if [[ -z "$why" ]]; then
    z4_state "$p"
    why="$(z4_expect 3 '대조(권한 복구 뒤 정상 파일·키 없음)')"
  fi
  report "$name" "$why"
}

z4c() { # Z4 — 끊긴 심링크는 "존재하지만 일반 파일이 아님" → UNTRUSTED.
        # 대조: 일반 파일을 가리키는 심링크는 정상(ABSENT).
  local name='z4c 끊긴 심링크 harness.env → UNTRUSTED (정상 링크 대조)' why='' p
  p="$(z4_project)" || { FIXTURE_FAIL='프로젝트'; report "$name" ''; return; }
  printf 'HARNESS_TYPECHECK_CMD=""\n' > "$p/real.env"
  ln -s "$p/real.env" "$p/.claude/harness/harness.env"
  z4_state "$p"
  why="$(z4_expect 3 '대조(일반 파일 링크)')"
  if [[ -z "$why" ]]; then
    rm -f "$p/.claude/harness/harness.env"
    ln -s "$p/nowhere.env" "$p/.claude/harness/harness.env"
    z4_state "$p"
    why="$(z4_expect 1 '끊긴 심링크')"
  fi
  report "$name" "$why"
}
