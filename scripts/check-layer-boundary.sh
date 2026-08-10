#!/usr/bin/env bash
# check-layer-boundary.sh — 하네스 글루에 **상위 층 구현**이 새면 종료 코드 1.
#
# 층은 셋이고, 각자 따로 설치돼도 돌아가야 한다는 것이 요구다.
#
#   상위 ┃ 지식 저장소   구현체. 하네스를 모른다
#   접착 ┃ 사용자 층     전역 CLAUDE.md — 어느 저장소를 쓰는지는 여기서만 안다
#   하위 ┃ 하네스        계약만 소유. "설정돼 있으면 반영 없이 끝낼 수 없다"
#
# 소유권이 **하위**에 있는 게 핵심이다. 반대로 두면 인터페이스를 알기 위해 상위가
# 있어야 해서 단독 작동이 깨진다. 그런데 완료를 강제하는 기계가 하네스뿐이라, 갈 곳이
# 없는 상위 층 지식이 자꾸 글루로 흘러든다 — 실제로 13곳까지 샜었다.
#
# **이 경계는 grep 으로 판정 가능하다.** 조회 라우팅 같은 "행동"과 달리 "글루에 상위 층
# 구현이 적혀 있나"는 기계가 100% 답한다. 그래서 산문 규칙으로 두지 않는다 —
# 산문 규칙은 어겨지고, 어겨져도 아무것도 안 깨져서 아무도 모른다.
#
# 이 검사는 README 가 선언한 **"도메인 누출 0"을 처음으로 기계가 지키게 한다.**
# 특정 저장소에 한정되지 않는다 — 어떤 상위 층 구현이든 같은 이유로 막힌다.
#
# ── 위양성 쪽으로 기운다 ─────────────────────────────────────────────
# 관용구 패턴은 무관한 조합에도 걸릴 수 있다. 그 대가를 받아들인다 — 누출이 조용히
# 통과하는 것보다 사람이 한 번 보고 문구를 고치는 편이 싸다. 걸렸는데 정당한 표현 같으면
# **패턴을 좁히지 말고 그 문구를 계약 수준으로 다시 써라.** 그게 이 검사의 목적이다.
#
# 사용법: ./scripts/check-layer-boundary.sh
# 회귀 테스트: ./tests/check-layer-boundary.test.sh (CI에서 이 검사보다 **먼저** 돈다)

set -euo pipefail

# CDPATH='' — CDPATH 가 설정된 셸에서 상대 경로로 부르면 cd 가 이동 경로를 stdout 에
# 찍어 ROOT 가 두 줄이 된다(절대 경로 호출로는 재현 안 됨). 형제 검사기와 같은 처리.
ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# 스캔 범위는 **배포물 전부**다. 범위를 넓히면 문서·ADR·테스트의 정당한 인용이 죄다
# 위양성이 되므로 배포되지 않는 것은 넣지 않는다 — 이 저장소의 ADR 은 무엇이 새어
# 있었는지 기록해야 하므로 그 표현을 반드시 담는다.
#
# **배포 경로가 둘이라는 것이 함정이었다.** install.sh 는 `template/.claude/` 를 프로젝트로
# 복사하고, 그와 별도로 `global-agents/*.md` 를 `~/.claude/agents/` 로 배포한다. 범위를
# template/ 하나로 잡았더니 global-agents/ 에 실제 누출이 있는데도 CI 가 초록이었다
# (codex 검수에서 적발). 배포되는 것은 전부 본다.
DEFAULT_ROOTS="$ROOT/template
$ROOT/global-agents"
# 회귀 테스트가 픽스처 트리를 겨누려고 이 값을 덮는다. 그 외에는 덮지 마라.
SCAN_ROOTS="${HARNESS_LAYER_SCAN_ROOT:-$DEFAULT_ROOTS}"

# 범위 중 **하나라도** 없으면 거부한다. 하나가 조용히 빠지면 그만큼 감시가 사라진다.
while IFS= read -r r; do
  [ -n "$r" ] || continue
  if [ ! -d "$r" ]; then
    echo "✗ 스캔 범위가 디렉토리가 아닙니다: $r" >&2
    exit 1
  fi
done <<EOF
$SCAN_ROOTS
EOF

WORK="$(mktemp -d)"
if [ -z "$WORK" ] || [ ! -d "$WORK" ]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2
  exit 1
fi
trap 'rm -rf "$WORK"' EXIT

# ── 금지 표현 ─────────────────────────────────────────────────────────
# 한 줄에 `ERE 패턴<TAB>왜 상위 층인가`. 메시지가 있어야 걸린 사람이 무엇을 계약 수준으로
# 다시 써야 하는지 안다. "금지됐다"만 알려주는 검사는 우회당한다.
# 히어독을 **인용**한다(<<'PATTERNS'): 패턴 안의 $ · 백슬래시가 셸에 먹히면 안 된다.
PATTERNS_FILE="$WORK/patterns"
cat > "$PATTERNS_FILE" <<'PATTERNS'
second[ -]brain	특정 지식 저장소의 이름. 하네스는 저장소가 무엇인지 몰라야 한다
[Oo]bsidian	특정 도구 이름. 저장소를 바꾸면 이 문구가 거짓이 된다
볼트	특정 지식 저장소의 이름
_CLAUDE\.md	상위 층 저장소 안의 파일 이름. 그 파일이 없는 환경에서는 지킬 수 없는 요구가 된다
4종 세트	상위 층이 지식을 어느 파일로 나눠 담는지의 구조. 하네스가 알 필요 없다
discussion-log	상위 층 저장소의 파일 이름
Projects/<name>	상위 층 저장소의 폴더 구조
needs-vault	구현체 이름이 붙은 플래그. 계약 이름(.needs-knowledge)을 써라
PATTERNS

# ── 사전 조건: 스캔할 수 없는 대상이 있으면 결과 전체를 믿을 수 없다 ──
# 형제 검사기(check-rule-copies.sh)의 ①②③ 과 같은 층위다. 심링크가 있으면 grep -r 은
# 건너뛰는데 install.sh 의 cp 는 실체를 배포한다 — 검사되지 않은 파일이 배포되는 창이
# 열린다. NUL 보유 파일은 토큰 바이트열이 원리적으로 안 보인다(UTF-16 도 같은 층위).
#
# find -print0 을 **파일로 받는다.** 명령 치환으로 받으면 셸이 NUL 을 버려 루프가 한 번도
# 안 돌고, 검사기는 "위반 0건"으로 초록불을 낸다.
FILES="$WORK/files"
: > "$FILES"
while IFS= read -r r; do
  [ -n "$r" ] || continue
  find "$r" -print0 >> "$FILES"
done <<EOF
$SCAN_ROOTS
EOF

bad_pre=0
while IFS= read -r -d '' p; do
  if [ -L "$p" ]; then
    echo "✗ 심링크가 스캔 범위 안에 있습니다: ${p#"$ROOT"/}" >&2
    bad_pre=1
    continue
  fi
  [ -f "$p" ] || continue
  if ! LC_ALL=C tr -d '\000' < "$p" | cmp -s - "$p"; then
    echo "✗ NUL 바이트를 가진 파일이 있어 내용을 믿을 수 없습니다: ${p#"$ROOT"/}" >&2
    bad_pre=1
  fi
done < "$FILES"

if [ "$bad_pre" -ne 0 ]; then
  echo "" >&2
  echo "스캔할 수 없는 대상이 트리에 있으면 그 트리에 대한 스캔 결과 전체를 믿을 수 없습니다." >&2
  echo "제거한 뒤 다시 돌리세요." >&2
  exit 1
fi

# ── 스캔 ─────────────────────────────────────────────────────────────
# hits 를 파이프·서브셸 안에서 올리면 증가분이 부모로 안 돌아온다(서브셸 변수 누수).
# 그래서 출력은 모아 두고 개수는 파일로 센다.
REPORT="$WORK/report"
: > "$REPORT"
scanned=0

while IFS= read -r -d '' f; do
  [ -f "$f" ] || continue
  scanned=$((scanned + 1))
  rel="${f#"$ROOT"/}"
  while IFS="$(printf '\t')" read -r pat why; do
    [ -n "$pat" ] || continue
    # grep rc: 0=매치 1=무매치 **2 이상=오류**. `|| true` 로 뭉뚱그리면 읽기 실패까지
    # 삼켜 스캔이 통째로 실패해도 조용히 초록이 된다.
    set +e
    out="$(grep -nE -- "$pat" "$f")"
    rc=$?
    set -e
    if [ "$rc" -ge 2 ]; then
      echo "✗ 스캔 실패(rc=$rc): $rel  패턴 [$pat]" >&2
      exit 1
    fi
    if [ "$rc" -eq 0 ]; then
      printf '%s\n' "$out" | sed "s|^|  $rel:|" >> "$REPORT"
      printf '      ↑ %s\n' "$why" >> "$REPORT"
    fi
  done < "$PATTERNS_FILE"
done < "$FILES"

# 스캔 대상이 0개면 "0건 위반"을 찍고 통과한다 — 공허한 초록이다.
# 배포물이 하나도 없을 리 없으므로 그건 범위 설정이 틀린 것이다.
if [ "$scanned" -eq 0 ]; then
  echo "✗ 스캔한 파일이 0개입니다 (범위 설정을 확인하세요):" >&2
  printf '%s\n' "$SCAN_ROOTS" | sed 's/^/    /' >&2
  exit 1
fi

if [ -s "$REPORT" ]; then
  cat "$REPORT" >&2
  echo "" >&2
  echo "✗ 하네스 글루에 상위 층 구현이 샜습니다." >&2
  echo "  계약만 남기고 구현은 사용자 층으로 옮기세요 — 하네스는 지식 저장소가" >&2
  echo "  어디이고 어떤 구조인지 몰라야 그 저장소 없이도 돌아갑니다." >&2
  exit 1
fi

echo "✓ 층 경계 유지 — 배포물 ${scanned}개에 상위 층 구현 0건"
