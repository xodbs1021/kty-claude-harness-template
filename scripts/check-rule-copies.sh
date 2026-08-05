#!/usr/bin/env bash
# check-rule-copies.sh — 규칙 정본과 사본이 어긋나면 종료 코드 1.
#
# 왜 사본이 존재하나: 판정자 에이전트는 자기 정의 텍스트가 곧 컨텍스트다.
# "principles.md 참조"만 적어두면 그 파일을 읽는다는 보장이 없으므로, 판정 기준은
# 에이전트 정의 안에 물리적으로 들어 있어야 한다. 그래서 사본을 없애는 대신 감시한다.
#
# 무엇을 감시하나: `rule:core` 마커로 감싼 블록만. 마커 밖의 문맥별 설명은 자유다
# (판정 기준 = 동기화, 설명 = 자유).
#
# 이 검사기의 유일한 치명 결함은 **위음성**(어긋난 사본을 통과시킴)이다. 통과시키는
# 순간 "사본이 낡아도 아무것도 안 깨진다"는 조용한 실패가 그대로 되살아난다.
# 그래서 애매한 지점은 전부 fail-closed(막고 사람이 확인)로 기운다.
#
# 계약 — `template/` 안에서 `rule:core` 토큰을 가진 파일은 CANON이거나 COPIES 등록이다.
# 등록하지 않으면 종료 코드 1로 막는다. 수기 목록은 언젠가 현실보다 낡는데
# (install.sh:33~34 의 흉터 참고), 낡은 순간 낡은 사본이 그대로 배포되기 때문이다.
#
# 사용법: ./scripts/check-rule-copies.sh
# 회귀 테스트: ./tests/check-rule-copies.test.sh (CI에서 이 검사보다 **먼저** 돈다)
# 사본 추가: COPIES 배열에 파일 경로를 한 줄 추가한다. COPIES는 비면 안 된다
#            (사본이 0개면 감시할 대상이 없다는 뜻이라 검사기 자체가 무의미해진다).

set -euo pipefail

# CDPATH='' — CDPATH가 설정된 셸에서 이 스크립트를 **상대 경로로** 부르면 cd가
# 이동한 경로를 stdout에 찍어 ROOT가 두 줄이 된다(절대 경로 호출로는 재현 안 됨).
ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

CANON="$ROOT/template/.claude/harness/principles.md"
COPIES=(
  "$ROOT/template/.claude/agents/plan-reviewer.md"
)

# 마커 상수는 두 계약으로 나뉜다. 전체 줄 상수를 토큰에서 조립하는 이유는,
# 마커 문법이 바뀌어도 고칠 곳이 여전히 한 곳이고 두 계약이 같은 토큰을 공유한다는
# 사실이 코드에 드러나기 때문이다.
#
#   추출(extract)  — 전체 줄 완전 일치. 앞뒤 공백·설명·CRLF는 전부 마커가 아니다.
#                    엄격해야 "마커를 꾸며 판정 기준을 바꿔치기"가 막힌다.
#   발견(스캔)     — 토큰 부분 검색. 넓게 찾아 **등록을 강제**하고, 등록된 것만
#                    위 엄격 계약으로 대조한다. 좁게 찾으면 "미등록 + 마커 변형"
#                    조합이 검사 전체를 우회한다.
MARK_TOKEN_START='rule:core:start'
MARK_TOKEN_END='rule:core:end'
MARK_START_LINE="<!-- $MARK_TOKEN_START -->"
MARK_END_LINE="<!-- $MARK_TOKEN_END -->"

# 스캔 범위는 $ROOT/template 하위만. 배포되는 건 template/ 뿐이고, 범위를 넓히면
# 문서·테스트·작업 노트의 정당한 인용이 죄다 위양성이 된다.
SCAN_ROOT="$ROOT/template"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# extract <파일> <출력파일> — 마커 사이 본문을 파일로 뽑는다.
# 마커가 **정확히 한 쌍**이 아니면 종료 코드 1. 출력 파일은 종료 코드 0일 때만
# 소비한다(오류 시 부분 출력이 남을 수 있다).
#
# 왜 개수가 아니라 3상태 기계인가: "닫힌 적이 있으면 통과"로 두면, 사본에 블록을 두 개
# 두고 사이에 다른 내용을 끼웠을 때 두 블록만 이어붙여 비교하고 중간을 무시한 채
# 통과한다. 개수 세기(starts==1 && ends==1)는 그 위음성을 막았지만, 마커의 **순서**는
# 못 봤다. 상태 기계는 개수와 순서를 동시에 본다 — 그래서 BEFORE의 end(블록 밖 stray),
# IN의 start(중첩), AFTER의 모든 마커(두 번째 쌍)가 전부 즉시 오류다.
# AFTER의 마커를 오류로 두는 것이 곧 개수 세기가 하던 방어를 잃지 않고 옮긴 것이다.
#
# 왜 변수가 아니라 파일에 담나: 명령 치환 `$(...)`은 후행 개행을 전부 먹는다.
# 사본 끝에 빈 줄을 넣으면 내용이 다른데도 같다고 판정된다. 파일로 받아
# cmp 로 바이트 단위 비교한다. 다만 그것만으로는 부족하다 — BSD awk 는 NUL 이후
# 바이트를 버리므로, NUL 거부 게이트가 없으면 cmp 는 소실된 내용을 아예 못 본다
# (등록된 사본의 블록 안에 "정본과 같은 바이트 + NUL + 악성 내용"을 넣는 경로).
extract() {
  awk -v s="$MARK_START_LINE" -v e="$MARK_END_LINE" '
    BEGIN { state = "BEFORE"; bad = 0 }
    $0 == s { if (state != "BEFORE") { bad = 1; exit } state = "IN";    next }
    $0 == e { if (state != "IN")     { bad = 1; exit } state = "AFTER"; next }
    state == "IN" { print }
    END { exit ((bad == 0 && state == "AFTER") ? 0 : 1) }
  ' "$1" > "$2"
}

rel() { echo "${1#"$ROOT"/}"; }

# physical_path <경로> — `..`·`.`·심링크를 푼 물리 경로를 출력한다. 상위 디렉토리로
# cd 할 수 없으면 아무것도 출력하지 않고 1을 반환한다.
#
# 왜 필요한가: 범위 판정을 문자열 접두사로 하면 `$SCAN_ROOT/../밖/사본.md` 가 통과한다.
# 문자열로는 "$SCAN_ROOT/" 로 시작하지만 실제 경로는 template/ 밖이라, 세 게이트가
# 그 사본을 아예 보지 않는다(실측 rc=0 — 위음성).
#
# 왜 이 방식인가: macOS 에 realpath 가 없고 BSD readlink 에는 -f 가 없다. bash 3.2 +
# BSD 도구에서 이식 가능한 방법은 ROOT 계산이 이미 쓰는 `cd + pwd` 관용구뿐이다
# (여기서는 심링크까지 풀어야 하므로 -P).
#
# **마지막 구성요소는 풀지 않는다** — 파일 자신이 심링크여도 이름을 그대로 둔다.
# 풀어버리면 template/ 안의 심링크가 범위 판정에서 바깥 실체로 바뀌어, 심링크 게이트가
# 보고해야 할 것을 범위 오류로 가로채고 진단이 원인에서 멀어진다.
#
# **cd 도 -P 여야 한다** — pwd -P 만으로는 부족하다. 논리 cd(기본값)는 `심링크/..` 를
# 심링크를 따라가기 **전에** 문자로 상쇄하므로, 커널이 실제로 여는 곳과 다른 답을 낸다
# (실측: `cd -- /var/..` → `/`, `cd -P -- /var/..` → `/private`). 그 차이만큼
# `template/../심링크/../template` 같은 경로가 범위 안으로 접혀 통과한다(케이스 39).
physical_path() {
  local dir base
  dir="$(CDPATH='' cd -P -- "$(dirname -- "$1")" 2>/dev/null && pwd -P)" || return 1
  base="$(basename -- "$1")"
  # pwd -P 가 "/" 를 낼 때만 "//base" 가 된다 (루트 바로 아래 경로).
  if [ "$dir" = "/" ]; then dir=''; fi
  printf '%s/%s\n' "$dir" "$base"
}

# find_symlinks_under_template — template/ 아래 심링크 경로를 한 줄씩 출력한다.
# 판정도 메시지도 하지 않는다(그건 호출부의 몫).
#
# 아래 두 스캔 함수와 같은 `-print0` + `read -d ''` 방식이다. 이번 검사기가 배운 것이
# "줄 기반 파일 목록은 뚫린다"인데(개행으로 끝나는 파일명), 세 스캔 중 하나만 줄 기반으로
# 남겨두면 그 교훈이 반쪽이 된다. 여기서는 위음성까지 가지는 않지만, 개행을 품은 심링크
# 이름이 진단 출력에서 두 줄로 쪼개져 "경로를 한 줄씩 출력한다"는 이 계약이 거짓이 된다.
find_symlinks_under_template() {
  local list="$WORK/symscan.paths"
  local rc=0
  find "$SCAN_ROOT" -type l -print0 > "$list" || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "✗ 심링크 스캔 실패(find rc=$rc): $(rel "$SCAN_ROOT")" >&2
    return 1
  fi

  local f
  while IFS= read -r -d '' f; do
    printf '%s\n' "$f"
  done < "$list"
  return 0
}

# find_binary_files_under_template — template/ 아래에서 NUL 바이트를 가진 파일 경로를
# 한 줄씩 출력한다. 판정도 메시지도 하지 않는다(호출부의 몫).
#
# 왜 필요한가: 토큰 부분 검색은 **바이트열**을 찾는다. 같은 마커라도 UTF-16 으로
# 저장하면 `rule:core:start` 바이트열 자체가 존재하지 않아 원리적으로 못 잡는다
# (`-a`를 줘도 마찬가지다 — 실측 확인). 인코딩마다 패턴을 늘리는 건 끝이 없으므로,
# 스캔할 수 없는 파일은 **거부**한다. template/ 는 배포되는 텍스트 트리이고 현재
# 20개 파일 전부 NUL 0바이트다. 심링크 거부와 같은 층위의 사전 조건이다.
find_binary_files_under_template() {
  local list="$WORK/binscan.paths"
  local rc=0
  find "$SCAN_ROOT" -type f -print0 > "$list" || rc=$?
  # 이 분기는 지금 구조에서 도달 불가다(제거해도 전건 초록) — 테스트가 부실해서가 아니라
  # 세 스캔이 같은 트리를 같은 방식으로 find 하므로, 여기가 실패하는 조건이면 앞선 심링크
  # 스캔이 먼저 실패해 케이스 27이 잡는다. 실질 백스톱이므로 지우지 않는다.
  if [ "$rc" -ne 0 ]; then
    echo "✗ 바이너리 스캔 실패(find rc=$rc): $(rel "$SCAN_ROOT")" >&2
    return 1
  fi

  local f
  while IFS= read -r -d '' f; do
    # 읽기 불가는 뒤의 전용 검사가 진단한다 — 여기서 원인을 뒤섞지 않는다.
    [ -r "$f" ] || continue
    if ! LC_ALL=C tr -d '\000' < "$f" | cmp -s - "$f"; then
      printf '%s\n' "$f"
    fi
  done < "$list"
  return 0
}

# find_unregistered_marker_files — template/ 아래에서 CANON에도 COPIES에도 없는데
# rule:core 토큰을 가진 파일 경로를 한 줄씩 출력한다. 시작·끝 **둘 중 하나라도**
# 가지면 잡는다(반쪽 사본 발견).
#
# 왜 `grep -rl` 한 방이 아니라 find + 파일별 grep 인가 — 줄 기반 파일 목록이 두 군데서
# 뚫렸다. 둘 다 실측으로 통과(exit 0)를 확인한 위음성이다:
#   1) `-I`(바이너리 건너뛰기)를 쓰면 **NUL 1바이트**만 섞거나 UTF-16 으로 저장한
#      파일이 스캔에서 통째로 사라진다. 앞부분은 멀쩡한 마크다운이라 눈에 안 띈다.
#      **이 경로를 실제로 닫는 것은 앞의 NUL 거부 게이트이고 `-a`는 보조다** — 실측:
#      게이트를 제거하면 `-a`가 있어도 케이스 29·30·32 가 전부 빨개지고, 반대로 `-a`를
#      지우거나 `-I`로 되돌려도 게이트가 앞에서 거부해 그 파일에 도달조차 못 하므로
#      전건 초록이다. 즉 `-a`의 초록은 방어의 증거가 아니다 — 나중에 게이트를 지우려는
#      사람이 `-a`를 근거로 안심하면 안 된다.
#   2) 파일명이 **개행으로 끝나면** `grep -l` 출력이 두 조각으로 쪼개지고, 첫 조각이
#      등록 경로와 정확히 일치해 "등록됨"으로 오인된다. `find -print0` + `read -d ''`는
#      경로를 NUL 로 끊으므로 그 오인이 성립하지 않는다.
#
# grep rc: 0=매치, 1=무매치, 2 이상=읽기 실패. rc≥2를 삼키면 스캔이 조용히 통과하는데,
# 그 조용한 통과가 이 검사기가 없애려는 바로 그 실패다. find 의 rc 도 같은 이유로 본다.
#
# bash 3.2에는 연관배열·mapfile이 없다 → while read + 선형 비교.
find_unregistered_marker_files() {
  local list="$WORK/scan.paths"
  local rc=0
  find "$SCAN_ROOT" -type f -print0 > "$list" || rc=$?
  # 바이너리 스캔 쪽과 같은 이유로 도달 불가하지만 남긴다 — 심링크 스캔이 먼저 실패해
  # 케이스 27이 잡으므로 실질 백스톱이다. (아래 grep rc 분기는 도달 가능 — 케이스 23)
  if [ "$rc" -ne 0 ]; then
    echo "✗ 미등록 스캔 실패(find rc=$rc): $(rel "$SCAN_ROOT")" >&2
    return 1
  fi

  local f grc known k
  while IFS= read -r -d '' f; do
    grc=0
    grep -qFa -e "$MARK_TOKEN_START" -e "$MARK_TOKEN_END" -- "$f" || grc=$?
    if [ "$grc" -gt 1 ]; then
      echo "✗ 미등록 스캔 실패(grep rc=$grc): $(rel "$f")" >&2
      return 1
    fi
    [ "$grc" -eq 0 ] || continue

    known=0
    for k in "$CANON" ${COPIES[@]+"${COPIES[@]}"}; do
      if [ "$f" = "$k" ]; then known=1; break; fi
    done
    # AND-리스트가 아니라 if 로 쓰는 이유: `[ ] && echo` 는 조건이 거짓일 때 상태 1을
    # 반환해 set -e 와의 상호작용이 셸에 따라 갈린다.
    if [ "$known" -eq 0 ]; then printf '%s\n' "$f"; fi
  done < "$list"
  return 0
}

# 등록 목록 자체에 대한 단언은 **모든 게이트보다 먼저**. 게이트 3개(심링크·NUL·미등록)는
# 전부 $SCAN_ROOT 하위만 훑으므로, 등록 목록이 그 전제를 깨면 게이트가 무엇을 통과시켰는지
# 알 수 없다. 게이트가 기대는 전제는 게이트보다 앞에서 못 박는다.

# COPIES 가 비면 감시 대상이 0개다 — 헤더 21~22행이 계약으로 선언해 온 것을 여기서 기계로
# 옮긴다. 산문으로만 있으면 지켜지지 않는다: COPIES=() 로 두고 사본에서 마커까지 지우면
# 미등록 스캔에도 안 걸려 `✓ 규칙 사본 0개가 정본과 일치` 로 통과했다(실측 rc=0).
if [ "${#COPIES[@]}" -eq 0 ]; then
  echo "✗ COPIES 배열이 비어 있음: scripts/check-rule-copies.sh" >&2
  echo "   사본이 0개면 감시할 대상이 없다는 뜻이라 이 검사기가 통째로 무의미해집니다 — 사본을 지웠다면 검사기도 함께 지우십시오." >&2
  exit 1
fi

# 개행이 든 등록 경로는 **범위를 판정하기 전에** 거부한다. physical_path 는 dirname 출력을
# 명령 치환으로 받는데, 명령 치환은 후행 개행을 **전부** 먹는다 — `$SCAN_ROOT<개행>/사본.md`
# 는 실제 부모가 `template<개행>`(template 의 바깥 형제)인데도 dirname 의 개행과 명령 치환이
# 붙이는 개행이 함께 잘려 `template` 으로 보이고, 범위 안으로 통과한다(실측 rc=0).
# $(...) 를 쓰는 한 이 축은 원리적으로 못 고치므로 등록 자체를 막는다. 케이스 31이 개행
# 파일명을 스캔 쪽에서 닫은 것과 같은 계열의 처리다.
#
# 개행 자신을 $(...) 로 만들면 그 개행이 또 잘린다 — 그래서 $'\n' 로 쓴다.
NEWLINE=$'\n'
for reg_path in "$CANON" "${COPIES[@]}"; do
  case "$reg_path" in
    *"$NEWLINE"*)
      echo "✗ 등록 경로에 개행이 들어 있음: $(rel "$reg_path")" >&2
      echo "   후행 개행은 명령 치환에서 잘려 나가 바깥 형제 디렉토리를 스캔 범위 안으로 오인시킵니다 — 범위 판정이 성립하지 않습니다." >&2
      echo "   scripts/check-rule-copies.sh 의 CANON·COPIES 에서 개행 없는 경로를 쓰십시오." >&2
      exit 1
      ;;
  esac
done

# 등록 경로는 전부 $SCAN_ROOT 하위여야 한다. 밖을 가리키면 심링크·NUL 게이트가 그 사본을
# 아예 보지 않아, 헤더와 docs/usage.md 가 안내하는 "COPIES 에 경로 한 줄 추가"를 정상적으로
# 밟다가 게이트 2개를 조용히 잃는다(실측: 범위 밖 사본의 블록에 NUL+악성 내용을 넣어도 rc=0).
#
# 비교는 **물리 경로끼리** 한다. 문자열 접두사로 보면 `$SCAN_ROOT/../밖/사본.md` 가
# "$SCAN_ROOT/ 로 시작한다"는 이유로 통과한다 — 위 위음성이 `..` 한 번으로 되살아난다.
# 기준선인 SCAN_ROOT 도 같은 방식으로 푼다: ROOT 는 논리 경로(pwd)라 심링크가 남는데
# (macOS 의 /var → /private/var), 한쪽만 풀면 정상 등록까지 전부 범위 밖이 된다.
scope_fail=0
if ! scan_root_phys="$(physical_path "$SCAN_ROOT")"; then
  # $SCAN_ROOT 의 상위는 방금 cd 로 확인한 ROOT 라 도달 불가에 가깝다. 그래도 남긴다 —
  # 기준선을 못 구한 채로 진행하면 모든 경로가 통과하는 fail-open 이 된다.
  echo "✗ 스캔 범위의 물리 경로를 구할 수 없음: $(rel "$SCAN_ROOT")" >&2
  exit 1
fi
for reg_path in "$CANON" "${COPIES[@]}"; do
  # 정규화 실패를 통째로 넘기면(옛 `|| continue`) 범위 검사만 조용히 사라지고 파일 비교는
  # 정상 진행된다 — 범위 밖 사본이 게이트를 하나도 안 거친 채 rc=0 이 될 수 있다.
  # 실패 원인이 cd 뿐이라면 그 파일은 열 수도 없어 뒤의 존재 검사가 막아주지만,
  # pwd -P(getcwd) 실패는 다르다: POSIX 는 상위를 읽을 수 없을 때 EACCES 를 허용하는데
  # 그때도 파일 자신은 멀쩡히 열린다. 그래서 **존재 여부로 갈라** fail-closed 를 만든다.
  #   존재함   → 거부. 범위를 확인할 수 없는 등록을 통과시키지 않는다.
  #   없음     → 넘김. 뒤의 "파일 없음" 진단이 진짜 원인이다. template/ 가 통째로 없을 때
  #              (케이스 27) 범위 오류가 스캔 실패 진단을 가로채지 않게 하는 것도 이 갈래다.
  # -e 에 -L 을 더하는 이유: 끊어진 심링크는 -e 가 거짓인데 그 자리에 무언가는 놓여 있다.
  if ! reg_phys="$(physical_path "$reg_path")"; then
    if [ -e "$reg_path" ] || [ -L "$reg_path" ]; then
      echo "✗ 등록 경로의 물리 경로를 구할 수 없음: $(rel "$reg_path")" >&2
      echo "   파일은 존재하는데 범위 안인지 확인할 수 없습니다 — 확인 못 한 등록은 통과시키지 않습니다." >&2
      echo "   상위 디렉토리의 권한과 심링크를 확인하십시오." >&2
      exit 1
    fi
    continue
  fi
  case "$reg_phys" in
    "$scan_root_phys"/*) ;;
    *)
      echo "✗ 등록 경로가 스캔 범위 밖: $(rel "$reg_path")" >&2
      scope_fail=1
      ;;
  esac
done
if [ "$scope_fail" -ne 0 ]; then
  echo "   심링크·NUL·미등록 게이트는 $(rel "$SCAN_ROOT")/ 하위만 훑습니다 — 밖의 파일은 검사되지 않은 채 등록만 된 상태가 됩니다." >&2
  echo "   scripts/check-rule-copies.sh 의 CANON·COPIES 항목을 $(rel "$SCAN_ROOT")/ 아래로 옮기십시오." >&2
  exit 1
fi

# 심링크 거부는 **모든 스캔보다 먼저**. 재귀 grep은 심링크를 따라가지 않는데
# install.sh 는 실체를 풀어 배포한다 — 심링크가 하나라도 있으면 이후 grep 결과 자체를
# 믿을 수 없다. 사본 하나의 문제가 아니라 검사 신뢰성의 사전 조건이라 즉시 종료한다.
if ! syms="$(find_symlinks_under_template)"; then
  exit 1
fi
if [ -n "$syms" ]; then
  echo "✗ template/ 아래 심링크는 허용하지 않습니다:" >&2
  printf '%s\n' "$syms" | while IFS= read -r p; do echo "    $(rel "$p")" >&2; done
  echo "   재귀 grep은 심링크를 따라가지 않는데 install.sh는 실체를 풀어 배포합니다 — 검사되지 않은 파일이 배포됩니다." >&2
  exit 1
fi

# 바이너리 거부도 같은 사전 조건이다 — 스캔할 수 없는 파일이 트리에 있으면
# 그 트리에 대한 스캔 결과 전체를 믿을 수 없다.
if ! bins="$(find_binary_files_under_template)"; then
  exit 1
fi
if [ -n "$bins" ]; then
  echo "✗ template/ 아래에 NUL 바이트를 포함한 파일은 허용하지 않습니다:" >&2
  printf '%s\n' "$bins" | while IFS= read -r p; do echo "    $(rel "$p")" >&2; done
  echo "   토큰 검색은 바이트열을 찾으므로 UTF-16 같은 인코딩 안의 마커를 못 봅니다 — 검사되지 않은 판정 기준이 배포됩니다." >&2
  exit 1
fi

canon_f="$WORK/canon"
if [ ! -f "$CANON" ]; then
  echo "✗ 정본 파일이 없음: $(rel "$CANON")" >&2
  echo "   파일이 옮겨졌으면 scripts/check-rule-copies.sh 의 CANON 경로를 고치십시오." >&2
  exit 1
fi

# 존재만 보면 부족하다. 존재하되 읽을 수 없으면 awk 원시 오류가 사용자에게 새고,
# 게다가 "마커 모양이 잘못됐다"고 **거짓 원인**을 보고한다.
if [ ! -r "$CANON" ]; then
  echo "✗ 정본 파일을 읽을 수 없음(권한): $(rel "$CANON")" >&2
  echo "   파일 권한을 확인하십시오 — 읽지 못하면 마커 검사 자체가 성립하지 않습니다." >&2
  exit 1
fi

if ! extract "$CANON" "$canon_f"; then
  echo "✗ 정본의 rule:core 마커 쌍이 정확히 하나가 아님: $(rel "$CANON")" >&2
  echo "   마커 줄은 앞뒤 공백·설명 없이 정확히 한 줄이어야 합니다 (CRLF 줄끝 불가)." >&2
  exit 1
fi

if [ ! -s "$canon_f" ]; then
  echo "✗ 정본의 rule:core 블록이 비어 있음: $(rel "$CANON")" >&2
  exit 1
fi

# 사본 불일치(sync_fail)와 미등록(reg_fail)을 따로 센다 — 미등록만 걸렸는데
# "정본의 블록을 사본에 복사하십시오"라고 안내하면 거짓 안내가 된다.
sync_fail=0
reg_fail=0
i=0
for copy_file in ${COPIES[@]+"${COPIES[@]}"}; do
  i=$((i + 1))
  copy_f="$WORK/copy.$i"

  if [ ! -f "$copy_file" ]; then
    echo "✗ COPIES에 등록된 사본 파일이 없음: $(rel "$copy_file")" >&2
    echo "   파일이 옮겨졌으면 scripts/check-rule-copies.sh 의 COPIES 배열을 고치십시오." >&2
    sync_fail=1
    continue
  fi

  if [ ! -r "$copy_file" ]; then
    echo "✗ COPIES에 등록된 사본 파일을 읽을 수 없음(권한): $(rel "$copy_file")" >&2
    echo "   파일 권한을 확인하십시오 — 읽지 못하면 마커 검사 자체가 성립하지 않습니다." >&2
    sync_fail=1
    continue
  fi

  if ! extract "$copy_file" "$copy_f"; then
    echo "✗ 사본의 rule:core 마커 쌍이 정확히 하나가 아님: $(rel "$copy_file")" >&2
    echo "   마커 줄은 앞뒤 공백·설명 없이 정확히 한 줄이어야 합니다 (CRLF 줄끝 불가)." >&2
    sync_fail=1
    continue
  fi

  if ! cmp -s "$canon_f" "$copy_f"; then
    echo "✗ 정본과 어긋남: $(rel "$copy_file")" >&2
    diff "$canon_f" "$copy_f" | sed 's/^/    /' >&2 || true
    sync_fail=1
  fi
done

if ! unreg="$(find_unregistered_marker_files)"; then
  exit 1
fi
if [ -n "$unreg" ]; then
  echo "✗ COPIES에도 정본에도 없는데 rule:core 마커를 가진 파일:" >&2
  printf '%s\n' "$unreg" | while IFS= read -r p; do echo "    $(rel "$p")" >&2; done
  echo "   scripts/check-rule-copies.sh 의 COPIES 배열에 등록하십시오 — 등록하지 않으면 낡은 사본이 그대로 배포됩니다." >&2
  reg_fail=1
fi

if [ "$sync_fail" -ne 0 ]; then
  echo "" >&2
  echo "정본 $(rel "$CANON") 의 rule:core 블록을 사본에 그대로 복사하십시오." >&2
  echo "(< 는 정본, > 는 사본)" >&2
fi

if [ "$sync_fail" -ne 0 ] || [ "$reg_fail" -ne 0 ]; then
  exit 1
fi

echo "✓ 규칙 사본 ${#COPIES[@]}개가 정본과 일치"
