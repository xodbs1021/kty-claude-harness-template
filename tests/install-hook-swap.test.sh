#!/usr/bin/env bash
# install-hook-swap.test.sh — 훅 디렉터리 rename 스왑의 회귀 테스트.
#
# 이 축의 실패는 **거짓 성공**으로 나온다. 앞선 검수에서 실제로 그랬다 — mv 가 기존
# 디렉터리 **안으로** 중첩되어 훅이 hooks/hooks/*.sh 로 깨졌는데 스크립트는 "설치 성공"을
# 찍었고, 신호로 죽었는데 rc=0 이 나왔다. 그래서 여기서는 rc 만 보지 않는다.
#
# **rc 단독 판정은 약하다.** 신호 종료 코드는 128+신호번호라는 관례값이라, 핸들러가 제대로
# 돌아 exit 143 한 것과 핸들러가 아예 없어 커널 기본 처리로 죽은 것이 같은 143 을 낸다.
# 그래서 케이스마다 **부수 효과**를 함께 잰다: 훅이 제자리에 있나 · 중첩(hooks/hooks)이
# 생겼나 · 임시 디렉터리가 남았나 · 진단 문구가 나왔나.
#
# 중단 주입은 타이밍이 아니라 **shim** 으로 한다. PATH 앞에 놓은 mv 가 호출 횟수를 세다가
# 두 번째(스테이징 → 제자리)에서 부모에게 신호를 보낸다 — 그러면 "옛것은 치웠고 새것은
# 아직 안 들어온" 그 창에서 정확히 멈춘다. shim 은 실제 mv 의 rc 를 **절대 삼키지 않는다**
# (rc 를 버리는 shim 은 픽스처의 실패를 조용히 성공으로 바꾼다 — 실측된 함정이다).
#
# 그리고 **주입이 실제로 걸렸는지를 판정에 넣는다.** 빗나가면 설치가 그냥 완주해 기대값이
# 우연히 충족되고, 케이스는 아무것도 안 잰 채 통과 도장을 찍는다.
#
# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
# 사용법: ./tests/install-hook-swap.test.sh

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
INSTALL="$REPO_ROOT/install.sh"

[ -f "$INSTALL" ] || { echo "✗ install.sh 를 찾지 못했습니다" >&2; exit 1; }

TMPROOT="$(mktemp -d)" || exit 1
if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
fi
TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
trap 'rm -rf "$TMPROOT"' EXIT

REAL_MV="$(command -v mv)"
[ -n "$REAL_MV" ] || { echo "✗ mv 를 찾지 못했습니다" >&2; exit 1; }

ran=0; pass=0; fail=0
RC=999; OUT=''; DID_RUN=0

report() {
  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
}

# new_project — 하네스가 이미 한 번 설치된 프로젝트. 구판임을 알아볼 수 있게 표식을
# 넣는다 — "복원됐나"를 판정하려면 구판이 식별 가능해야 한다.
new_project() {
  local p
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
  p="$(CDPATH='' cd -- "$p" && pwd -P)"
  "$INSTALL" "$p" --allow-dirty >/dev/null 2>&1 || return 1
  # 구판 식별 표식 — "복원됐나"를 판정하려면 구판이 식별 가능해야 한다.
  printf 'OLD\n' > "$p/.claude/hooks/.old-marker"
  # **사용자 파일** — 템플릿에 없는 것. 디렉터리를 통째로 바꾸는 설계에서 이게 사라지면
  # 데이터 파괴다. 구 구현(파일 단위 cp)에는 없던 회귀이므로 케이스로 붙든다.
  printf 'user\n' > "$p/.claude/hooks/custom.sh"
  mkdir -p "$p/.claude/hooks/lib" && printf 'lib\n' > "$p/.claude/hooks/lib/helper.sh"
  printf '%s\n' "$p"
}

# make_mv_shim <디렉터리> <몇 번째 호출에서> <신호이름|FAIL>
make_mv_shim() {
  local dir="$1" nth="$2" action="$3"
  mkdir -p "$dir" || return 1
  cat > "$dir/mv" <<SHIM
#!/usr/bin/env bash
n_file="$dir/.count"
n=\$(cat "\$n_file" 2>/dev/null || echo 0)
n=\$((n + 1))
printf '%s\n' "\$n" > "\$n_file"
if [ "\$n" -eq $nth ]; then
  printf 'HIT\n' > "$dir/.hit"
  if [ "$action" = FAIL ]; then
    exit 1
  fi
  kill -$action \$PPID 2>/dev/null
  sleep 5          # 신호가 처리될 시간. 핸들러가 exit 하므로 여기까지 오지 않는다
  exit 1
fi
exec "$REAL_MV" "\$@"     # **실제 rc 를 그대로 돌려준다** — 삼키면 픽스처가 결함을 가린다
SHIM
  chmod +x "$dir/mv"
}

run_install() {   # $1=프로젝트  [$2=shim 디렉터리]
  RC=999; OUT=''; DID_RUN=1
  # --allow-dirty: 이 스위트는 훅 교체 원자성을 재는 곳이고, 배포 가드(락·dirty)는
  # c10~c13 이 **자기 픽스처 저장소**로 따로 잰다. 여기서 실저장소의 dirty 여부에
  # 케이스가 좌우되면 개발 중(트리 dirty)에는 스위트 전체가 빨개진다.
  if [ -n "${2-}" ]; then
    OUT="$(PATH="$2:$PATH" "$INSTALL" "$1" --allow-dirty 2>&1)"
  else
    OUT="$("$INSTALL" "$1" --allow-dirty 2>&1)"
  fi
  RC=$?
}

# new_tpl — 배포 가드 케이스 전용의 **독립 정본 픽스처**(자기 git 저장소).
# 실저장소에 락을 만들거나 dirty 를 강요하면 테스트가 개발 트리를 오염시킨다.
new_tpl() {   # $1 이 no-git 이면 git 저장소를 만들지 않는다(비-git 정본 케이스용)
  local t
  t="$(mktemp -d "$TMPROOT/tpl.XXXXXX")" || return 1
  t="$(CDPATH='' cd -- "$t" && pwd -P)"
  cp -R "$REPO_ROOT/template" "$t/template" || return 1
  mkdir -p "$t/scripts"
  cp "$REPO_ROOT/install.sh" "$t/install.sh" || return 1
  cp "$REPO_ROOT/sync.sh" "$t/sync.sh" || return 1
  cp "$REPO_ROOT/scripts/deploy-guard.sh" "$t/scripts/deploy-guard.sh" || return 1
  if [ "${1-}" != 'no-git' ]; then
    git -C "$t" init -q && git -C "$t" config user.email t@t && git -C "$t" config user.name t \
      && git -C "$t" add -A >/dev/null && git -C "$t" commit -qm base || return 1
  fi
  printf '%s\n' "$t"
}

# empty_dir <경로> — 디렉터리가 비어 있는가 (거부 케이스의 "대상 무변경" 단언).
# .claude/hooks 존재만 보면 가드가 legacy 플래그 이행 뒤로 밀려 대상을 일부 건드려도
# 통과한다([cx] MEDIUM) — 대상 전체가 손대지지 않았음을 잰다.
empty_dir() { [ -z "$(ls -A "$1" 2>/dev/null)" ]; }

# run_tpl_install <tpl> <프로젝트> [추가 인자...] — 픽스처 정본의 install.sh 를 돌린다.
run_tpl_install() {
  local t="$1" p="$2"; shift 2
  RC=999; OUT=''; DID_RUN=1
  OUT="$("$t/install.sh" "$p" ${@+"$@"} 2>&1)"
  RC=$?
}

# leftovers <프로젝트> — 스테이징·백업 임시 디렉터리가 남았나
leftovers() {
  ls -a "$1/.claude" 2>/dev/null | grep -cE '^\.hooks-(stage|old)\.'
}

# --- 케이스 --------------------------------------------------------------

c01() {
  local name='정상 설치 — 템플릿 훅은 갱신, 사용자 파일은 보존' p why=''
  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
  # 템플릿 소유 파일을 오염시켜 둔다. 재설치가 이걸 덮어써야 "갱신"이다.
  printf 'STALE\n' > "$p/.claude/hooks/_common.sh"
  run_install "$p"
  if [ "$RC" -ne 0 ]; then why="rc=$RC"
  elif grep -q '^STALE$' "$p/.claude/hooks/_common.sh" 2>/dev/null; then
    why='템플릿 훅이 갱신되지 않았다'
  elif [ ! -f "$p/.claude/hooks/custom.sh" ]; then
    why='**사용자 파일 custom.sh 가 삭제됐다** (디렉터리 교체가 데이터를 파괴한다)'
  elif [ ! -f "$p/.claude/hooks/lib/helper.sh" ]; then
    why='**사용자 하위 디렉터리 lib/ 가 삭제됐다**'
  elif [ -e "$p/.claude/hooks/hooks" ]; then why='중첩(hooks/hooks)이 생겼다'
  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
  fi
  report "$name" "$why"
}

# 중단 주입 — 두 rename 사이에서 멈춘다.
interrupt_case() {   # $1=이름 $2=신호 $3=기대rc
  local name="$1" sig="$2" want_rc="$3" p shim why=''
  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
  shim="$TMPROOT/shim.$sig.$$"
  if ! make_mv_shim "$shim" 2 "$sig"; then report "$name" '픽스처 실패: shim'; return 0; fi
  run_install "$p" "$shim"
  if [ ! -f "$shim/.hit" ]; then
    why='주입이 빗나갔다 (mv 가 2번째로 불리지 않았다 — 설치가 그냥 완주했다)'
  elif [ "$RC" -ne "$want_rc" ]; then
    why="rc=$RC (기대 $want_rc)"
  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then
    why='구판으로 되돌리지 못했다 (훅 디렉터리가 사라졌다)'
  elif [ -e "$p/.claude/hooks/hooks" ]; then
    why='중첩(hooks/hooks)이 생겼다'
  elif [ "$(leftovers "$p")" != '0' ]; then
    why='임시 디렉터리가 남았다'
  else
    case "$OUT" in
      *'되돌렸습니다'*) ;;
      *) why="복구를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
    esac
  fi
  report "$name" "$why"
}

c02() { interrupt_case '교체 도중 INT  — 구판 복원 + rc=130' INT  130; }
c03() { interrupt_case '교체 도중 TERM — 구판 복원 + rc=143' TERM 143; }
# QUIT·HUP 이 따로 중요한 이유: trap 이 없으면 bash 가 QUIT 를 **무시하고 rc=0** 을 낸다 —
# 중단됐는데 "설치 성공"으로 보고되는 최악의 조합이다(실측).
c04() { interrupt_case '교체 도중 QUIT — 구판 복원 + rc=131' QUIT 131; }
c05() { interrupt_case '교체 도중 HUP  — 구판 복원 + rc=129' HUP  129; }

c06() {
  local name='rename2 실패 — 성공으로 오진단하지 않고 구판 복원' p shim why=''
  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
  shim="$TMPROOT/shim.fail.$$"
  if ! make_mv_shim "$shim" 2 FAIL; then report "$name" '픽스처 실패: shim'; return 0; fi
  run_install "$p" "$shim"
  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
  elif [ "$RC" -eq 0 ]; then why='실패했는데 rc=0 (성공으로 오진단)'
  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
  else
    case "$OUT" in
      *'교체하지 못했습니다'*) ;;
      *) why="실패를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
    esac
  fi
  report "$name" "$why"
}

c07() {
  local name='훅 디렉터리가 심링크면 링크를 보존하고 알린다' p why=''
  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
  "$REAL_MV" "$p/.claude/hooks" "$p/real-hooks" || { report "$name" '픽스처 실패: mv'; return 0; }
  ln -s "$p/real-hooks" "$p/.claude/hooks" || { report "$name" '픽스처 실패: ln'; return 0; }
  run_install "$p"
  if [ "$RC" -ne 0 ]; then why="rc=$RC"
  elif [ ! -L "$p/.claude/hooks" ]; then why='심링크를 일반 디렉터리로 갈아치웠다 (사용자 배치 파괴)'
  elif [ ! -f "$p/real-hooks/_common.sh" ]; then why='링크 대상에 훅이 복사되지 않았다'
  else
    case "$OUT" in
      *'심볼릭 링크'*) ;;
      *) why='원자성을 못 지킨다는 사실을 알리지 않았다 (조용히 물러섰다)' ;;
    esac
  fi
  report "$name" "$why"
}

# 라운드 2 [HIGH] — 사용자 파일을 보존하려다 **외부 파일을 파괴**하던 자리.
# 기존 훅 디렉터리에 템플릿 파일 이름과 같은 **심링크**가 있으면, cp -R 이 그 링크를
# 스테이징에 보존하고 그 다음 템플릿 cp 가 링크를 따라가 **대상 파일을 덮어쓴다.**
c09() {
  local name='템플릿 이름과 겹치는 심링크가 링크 대상을 덮어쓰지 않는다' p why=''
  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
  printf 'OUTSIDE\n' > "$p/outside.txt"
  rm -f "$p/.claude/hooks/_common.sh"
  ln -s "$p/outside.txt" "$p/.claude/hooks/_common.sh" || { report "$name" '픽스처 실패: ln'; return 0; }
  run_install "$p"
  if [ "$RC" -ne 0 ]; then why="rc=$RC"
  elif ! grep -q '^OUTSIDE$' "$p/outside.txt" 2>/dev/null; then
    why='**링크 대상(디렉터리 밖 사용자 파일)이 덮어써졌다**'
  elif [ ! -s "$p/.claude/hooks/_common.sh" ] || [ -L "$p/.claude/hooks/_common.sh" ]; then
    why='템플릿 훅이 제자리에 실파일로 설치되지 않았다'
  fi
  report "$name" "$why"
}

# 핸들러 진입 직후의 `set +e` 를 지키는 유일한 케이스.
#
# 왜 따로 필요한가: 다른 중단 케이스는 진단 echo 가 **성공**하므로 set +e 가 있든 없든
# exit 에 도달한다. 그래서 그 줄을 지워도 전건 초록이다 — 실제로 앞선 세션에서 그 한 줄을
# 지워도 스위트 19/19 가 그대로였다. 버그는 **stderr 가 닫힌 상태에서만** 재현되는데
# 테스트 하네스가 출력을 2>&1 로 합칠 뿐 닫지 않았기 때문이다.
#
# 여기서는 stderr 를 **닫고**(2>&-) 돌린다. echo 가 실패하고, set -e 가 살아 있으면
# 핸들러가 exit 143 에 도달하지 못하고 rc=1 로 끝난다 — 신호로 죽은 건지 실패한 건지
# 구별이 사라지는 그 상태다.
#
# 한계(공시): stderr 가 닫혔으므로 진단 문구는 잴 수 없다. 종료 코드와 파일 상태만 본다.
c08() {
  local name='stderr 가 닫힌 채 TERM — 진단은 못 내도 종료 코드 계약은 지킨다' p shim why=''
  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
  shim="$TMPROOT/shim.noerr.$$"
  if ! make_mv_shim "$shim" 2 TERM; then report "$name" '픽스처 실패: shim'; return 0; fi
  DID_RUN=1
  PATH="$shim:$PATH" "$INSTALL" "$p" --allow-dirty >/dev/null 2>&-
  RC=$?
  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
  elif [ "$RC" -ne 143 ]; then why="rc=$RC (기대 143 — set +e 가 없으면 1 이 된다)"
  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
  fi
  report "$name" "$why"
}

# --- 러너 ----------------------------------------------------------------

# --- 배포 안전 가드 (C안 — 변이 락 무조건 거부 · dirty 는 --allow-dirty 옵트인) ----
# rc 만 보지 않는다: 거부 케이스는 **대상이 안 만들어졌는지**(부수 효과 부재)와
# 사유 문구까지 요구한다 — 가드가 늦게 서서 반쯤 배포한 뒤 거부해도 rc 는 같다.

c10() {
  local name='c10 변이 락 → 거부 + 대상 무변경' t p why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  mkdir "$t/.git/mutate-decision-gate.lock" || { report "$name" '픽스처 실패: lock'; return 0; }
  run_tpl_install "$t" "$p"
  if [ "$RC" -eq 0 ];                          then why='락이 있는데 설치가 성공했다'
  elif ! printf '%s' "$OUT" | grep -q '변이 측정이 진행 중'; then why="거부 사유가 없다: $(printf '%s' "$OUT" | tail -2 | head -1 | head -c 80)"
  elif ! empty_dir "$p";                       then why='거부인데 대상이 변경됐다 (가드가 너무 늦다)'
  fi
  report "$name" "$why"
}

c11() {
  local name='c11 dirty 정본 → 거부 + --allow-dirty 안내' t p why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  printf 'dirty\n' >> "$t/template/.claude/hooks/_common.sh"
  run_tpl_install "$t" "$p"
  if [ "$RC" -eq 0 ];                          then why='dirty 인데 설치가 성공했다'
  elif ! printf '%s' "$OUT" | grep -q '미커밋 변경'; then why='거부 사유가 없다'
  elif ! printf '%s' "$OUT" | grep -q -- '--allow-dirty'; then why='옵트인 안내가 없다 (막힌 사람이 우회를 발명한다)'
  elif ! empty_dir "$p";                       then why='거부인데 대상이 변경됐다'
  fi
  report "$name" "$why"
}

c12() {
  local name='c12 dirty + --allow-dirty → 설치 진행 (정상 개발 흐름)' t p why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  printf '# dirty-marker\n' >> "$t/template/.claude/hooks/_common.sh"
  run_tpl_install "$t" "$p" --allow-dirty
  if [ "$RC" -ne 0 ];                          then why="옵트인인데 거부됐다 rc=$RC: $(printf '%s' "$OUT" | tail -2 | head -1 | head -c 80)"
  elif [ ! -f "$p/.claude/hooks/_common.sh" ]; then why='설치가 완주하지 않았다'
  elif ! grep -q 'dirty-marker' "$p/.claude/hooks/_common.sh"; then
    why='dirty 상태(수정본)가 배포되지 않았다 — 시험 설치의 목적 자체가 안 됐다'
  fi
  report "$name" "$why"
}

c13() {
  local name='c13 락 + --allow-dirty → 그래도 거부 (락에는 옵트인 없음)' t p why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  mkdir "$t/.git/mutate-retrieval-gate.lock" || { report "$name" '픽스처 실패: lock'; return 0; }
  run_tpl_install "$t" "$p" --allow-dirty
  if [ "$RC" -eq 0 ];             then why='--allow-dirty 가 락 거부까지 뚫었다'
  elif [ -e "$p/.claude/hooks" ]; then why='거부인데 훅이 배포됐다'
  fi
  report "$name" "$why"
}

c14() { # **기본 경로** — 깨끗한 git 정본에서 옵션 없이 설치가 성공한다. 이 케이스가
        # 없으면 "가드가 클린 트리까지 막는" 회귀를 어떤 케이스도 못 본다([cx] 지적 —
        # 나머지 전부가 --allow-dirty 이거나 거부 기대라서).
  local name='c14 클린 정본 + 옵션 없음 → 설치 성공 (기본 경로)' t p why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  run_tpl_install "$t" "$p"
  if [ "$RC" -ne 0 ];                          then why="클린 트리인데 거부됐다 rc=$RC: $(printf '%s' "$OUT" | tail -2 | head -1 | head -c 80)"
  elif [ ! -f "$p/.claude/hooks/_common.sh" ]; then why='설치가 완주하지 않았다'
  fi
  report "$name" "$why"
}

c15() { # sync 의 --allow-dirty **전달** — 내부 install 호출로 그대로 넘어가야 한다.
        # 전달을 지우면 sync 쪽 가드는 통과하고 install 쪽 가드가 막아 이 케이스가 빨개진다.
  local name='c15 sync dirty + --allow-dirty → 전달되어 완주' t p why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  printf '# dirty\n' >> "$t/template/.claude/hooks/_common.sh"
  RC=999; OUT=''; DID_RUN=1
  OUT="$("$t/sync.sh" "$p" --no-pull --allow-dirty 2>&1)"; RC=$?
  if [ "$RC" -ne 0 ];                          then why="옵트인이 전달되지 않았다 rc=$RC: $(printf '%s' "$OUT" | tail -2 | head -1 | head -c 80)"
  elif [ ! -f "$p/.claude/hooks/_common.sh" ]; then why='sync 가 완주하지 않았다'
  fi
  report "$name" "$why"
}

c16() { # sync 의 가드는 **pull·미리보기보다 앞**이다. 자기 가드를 지워도 내부 install 이
        # 어차피 거부하므로 rc 로는 구별이 안 된다 — "pull·미리보기의 흔적이 없는가"로 잰다.
        # --no-pull 을 **쓰지 않는다**: 쓰면 pull 경로가 비활성이라 "가드가 pull 보다 앞"
        # 계약을 아무것도 안 잰다([cx] r2 지적). 픽스처에 원격이 없으므로 pull 이 실제로
        # 돌면 "pull 완료/실패" 중 하나가 반드시 찍힌다 — 그 부재가 곧 조기 가드의 증거다.
  local name='c16 sync + 락 → pull·미리보기 전에 거부 (조기 가드)' t p why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  mkdir "$t/.git/mutate-harness-env.lock" || { report "$name" '픽스처 실패: lock'; return 0; }
  RC=999; OUT=''; DID_RUN=1
  OUT="$("$t/sync.sh" "$p" 2>&1)"; RC=$?
  if [ "$RC" -eq 0 ];                          then why='락인데 sync 가 성공했다'
  elif ! printf '%s' "$OUT" | grep -q '변이 측정이 진행 중'; then why='거부 사유가 없다'
  elif printf '%s' "$OUT" | grep -q 'pull'; then why='가드가 pull 뒤에 섰다 (조기 가드 계약 위반)'
  elif printf '%s' "$OUT" | grep -q '갱신될 글루 diff'; then why='가드가 미리보기 뒤에 섰다'
  fi
  report "$name" "$why"
}

c17() { # 비-git 정본 — 검사할 것이 없으니 생략하되 **소리를 낸다**(조용한 생략 금지).
  local name='c17 비-git 정본 → 경고 내고 설치 진행' t p why=''
  if ! t="$(new_tpl no-git)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  run_tpl_install "$t" "$p"
  if [ "$RC" -ne 0 ];                          then why="비-git 인데 거부됐다 rc=$RC"
  elif [ ! -f "$p/.claude/hooks/_common.sh" ]; then why='설치가 완주하지 않았다'
  elif ! printf '%s' "$OUT" | grep -q '배포 가드 생략'; then why='생략이 조용했다 (경고 문구 없음)'
  fi
  report "$name" "$why"
}

c18() { # 가드 파일 부재(부분 복사본) — 역시 진행하되 경고. 경고 문구까지 요구해야
        # "가드 소멸이 조용히 지나가는" 회귀를 잡는다.
  local name='c18 가드 파일 부재 → 경고 내고 설치 진행' t p why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  rm "$t/scripts/deploy-guard.sh"
  run_tpl_install "$t" "$p"
  if [ "$RC" -ne 0 ];                          then why="가드 부재인데 거부됐다 rc=$RC"
  elif [ ! -f "$p/.claude/hooks/_common.sh" ]; then why='설치가 완주하지 않았다'
  elif ! printf '%s' "$OUT" | grep -q '배포 가드를 찾지 못했습니다'; then why='가드 소멸이 조용했다'
  fi
  report "$name" "$why"
}

c19() { # 오염된 GIT_DIR/GIT_WORK_TREE 아래서도 가드는 **정본을** 검사한다. 소거가
        # 없으면 -C 가 무시돼 깨끗한 남의 저장소를 보고 락을 통과시킨다([cx] HIGH 회귀).
        # 공시: git status 가 "성공한 rev-parse 뒤에만 실패"하는 상태는 이식성 있게
        # 재현할 방법을 못 찾아 케이스가 없다 — fail-closed 방향은 코드 계약으로만 남는다.
  local name='c19 오염된 GIT_DIR 아래서도 정본의 락을 본다' t p other why=''
  if ! t="$(new_tpl)"; then report "$name" '픽스처 실패: tpl'; return 0; fi
  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  other="$(mktemp -d "$TMPROOT/other.XXXXXX")" || { report "$name" '픽스처 실패'; return 0; }
  ( cd "$other" && git init -q . && git config user.email t@t && git config user.name t \
    && printf 'x\n' > x && git add x && git commit -qm base ) >/dev/null 2>&1 \
    || { report "$name" '픽스처 실패: other repo'; return 0; }
  mkdir "$t/.git/mutate-decision-gate.lock" || { report "$name" '픽스처 실패: lock'; return 0; }
  RC=999; OUT=''; DID_RUN=1
  OUT="$(GIT_DIR="$other/.git" GIT_WORK_TREE="$other" "$t/install.sh" "$p" 2>&1)"; RC=$?
  if [ "$RC" -eq 0 ]; then why='오염된 환경에서 락을 못 보고 통과했다'
  elif ! printf '%s' "$OUT" | grep -q '변이 측정이 진행 중'; then why="거부 사유가 없다: $(printf '%s' "$OUT" | tail -2 | head -1 | head -c 80)"
  fi
  report "$name" "$why"
}

CASES='c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12 c13 c14 c15 c16 c17 c18 c19'
EXPECTED_CASES=19

case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
  exit 1
fi

echo "훅 교체 원자성 — rename 스왑 + 중단 복구"
for c in $CASES; do
  ran=$((ran + 1)); DID_RUN=0
  "$c"
done

if [ "$ran" -ne "$EXPECTED_CASES" ]; then echo "✗ 실행 ${ran}건 ≠ ${EXPECTED_CASES}건" >&2; exit 1; fi
if [ $((pass + fail)) -ne "$ran" ]; then echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1; fi

echo "— ${pass}/${ran} 통과"
[ "$fail" -eq 0 ] || exit 1
