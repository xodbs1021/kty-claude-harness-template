#!/usr/bin/env bash
# PreToolUse(Bash): 워크트리의 .claude/harness/ 가 본 저장소와 어긋나면 Bash 실행을 막는다.
#
# 왜 필요한가: 하네스 프로필은 planner·architect·reviewer 가 "이 프로젝트의 사실"로 읽는
# 정본이다. 워크트리 사본이 낡으면 **계획·설계가 처음부터 틀린 전제 위에 짜인다** —
# 코드가 아니라 판단이 오염되므로 PR 게이트로는 못 잡는다.
#
# 실사고(2026-08-21): 본 저장소 프로필은 "계약 정본 = 팀 위키"로 이미 고쳐져 있었는데
# 워크트리 사본만 "계약 정본 = architecture repo"(폐기된 위치)로 남아 있었다. 그 사본을
# 읽은 설계가 **폐기된 위치를 kty 회부의 권고안으로 올렸다** — 2026-07-31 이관 때 원본을
# 안 지워 3번이 계약9를 못 찾았던 그 사고를 문서로 재현할 뻔했다.
#
# 왜 차단인가: 경고면 그 턴에 묻힌다. 어긋난 프로필로 짠 계획을 되돌리는 비용이
# 동기화 한 줄보다 훨씬 크다.
#
# **캐시하지 않는다.** 초판은 "세션당 1회" 플래그를 뒀다가 두 결함을 동시에 만들었다 —
# ① 플래그를 diff 보다 먼저 써서 한 번 막힌 뒤 재시도하면 그냥 통과했고(게이트 무력화)
# ② 플래그가 세션에 묶이지 않은 고정 경로라 지우는 주체가 없어 영구 통과가 됐다(실측:
# 워크트리에 남은 0바이트 플래그 탓에 그 세션의 Bash 가 한 번도 검사받지 않았다).
# 대상은 파일 3개·28KB 이고 실측 diff 가 17ms 다. 캐시의 이득보다 그 두 구멍이 비싸다.
#
# **복구 명령은 통과시킨다(데드락 방지).** 모든 Bash 를 막으면 안내한 복구 명령조차
# 못 돌린다 — 특히 하네스가 아직 없는 새 워크트리는 부트스트랩 자체가 불가능해진다.
# 그래서 대상이 .claude/harness 인 조회·동기화 명령만 좁게 허용한다. 허용 판정은
# **명령 문자열이 harness 를 가리키는지**만 보고, 그 밖의 명령은 그대로 막는다.
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

HOOK_ID="pre:bash:harness-drift"
hook_disabled "$HOOK_ID" && exit 0

payload="$(cat)"
cmd="$(printf '%s' "$payload" | json_get tool_input.command)"

# 경로를 물리 경로로 정규화한다. _common.sh 는 CLAUDE_PROJECT_DIR 를 그대로 쓰므로
# 심볼릭 링크·후행 슬래시·`..` 가 섞이면 아래 패턴 판정이 빗나간다.
REAL_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd -P)"
if [ -z "$REAL_DIR" ]; then
  # 조용히 통과하지 않는다 — 대조를 못 한 것이지 문제가 없는 것이 아니다.
  echo "[하네스 드리프트] 작업 경로를 해석하지 못했습니다: $PROJECT_DIR" >&2
  exit 2
fi

# 워크트리에서만 의미가 있다. 본 저장소에서 일할 땐 대조 대상이 자기 자신이다.
case "$REAL_DIR" in
  */.claude/worktrees/*) : ;;
  *) exit 0 ;;
esac

MAIN_ROOT="${REAL_DIR%%/.claude/worktrees/*}"
MAIN_HARNESS="$MAIN_ROOT/.claude/harness"
WT_HARNESS="$REAL_DIR/.claude/harness"

# 하네스를 다루는 명령은 막지 않는다 — 이게 없으면 차단이 곧 데드락이다.
case "$cmd" in
  *".claude/harness"*|*"/harness"*) exit 0 ;;
esac

# 양쪽 중 하나라도 없으면 대조 자체가 성립하지 않는다. 어느 쪽이 없든 **차단**한다 —
# 초판은 본 저장소 부재를 통과시켰는데, 그것도 "방향 미확정 드리프트"이고 그 상태로
# 워크트리의 낡은 프로필이 그대로 읽힌다(codex 지적).
#
# ⚠ **이 분기가 중첩 경로를 막아 준다고 믿으면 안 된다(2026-08-21 감사 반증).**
# settings.json 의 등록 명령은 `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<이름>.sh"` 라서,
# 그 변수가 워크트리 루트가 아닌 하위 폴더를 가리키면 **스크립트 파일을 못 찾아 exit 127**
# 로 죽는다 — 차단(2)이 아니라 그냥 실행 실패다. 이건 이 훅만의 문제가 아니라 등록된
# 아홉 훅 전부의 공통 노출이다(실측: guard-master-commit·guard-hook-disable 도 127).
# 즉 "CLAUDE_PROJECT_DIR = 워크트리 루트"는 하네스 전체의 **전제**이고, 깨지면 하네스가
# 통째로 조용히 사라진다. 이 분기는 스크립트가 실행되기만 했다면 잡아 주는 안전망일 뿐
# 그 전제를 대신 보증하지 못한다. 최초 감사 보고는 스크립트를 직접 실행해 exit 2 를 보고
# "중첩 경로 차단됨"이라 주장했는데, 등록 경로로는 성립하지 않는 주장이었다.
if [ ! -d "$MAIN_HARNESS" ] || [ ! -d "$WT_HARNESS" ]; then
  {
    echo "[하네스 드리프트] 대조할 하네스가 한쪽에 없습니다."
    [ -d "$MAIN_HARNESS" ] || echo "  없음(본 저장소): $MAIN_HARNESS"
    [ -d "$WT_HARNESS" ]   || echo "  없음(워크트리):  $WT_HARNESS"
    echo
    echo "CLAUDE_PROJECT_DIR 가 워크트리 루트가 아닌 하위 폴더를 가리키거나,"
    echo "하네스가 아직 복사되지 않은 상태입니다. 대조를 못 했으므로 통과시키지 않습니다."
    echo
    echo "있는 쪽에서 없는 쪽으로 복사하십시오(하네스를 다루는 명령은 이 훅이 막지 않습니다)."
    echo "  cp -R \"$MAIN_HARNESS\" \"$REAL_DIR/.claude/\""
    echo
    echo "끄려면: ECC_DISABLED_HOOKS=$HOOK_ID"
  } >&2
  exit 2
fi

# diff 종료 상태: 0=같음 · 1=다름 · 2이상=오류(권한·I/O). 초판은 `|| true` 로 셋을 뭉개
# 오류를 "같음"으로 삼켰다. 오류는 "대조 못 했다"이지 "문제 없다"가 아니다.
DRIFT="$(diff -rq "$MAIN_HARNESS" "$WT_HARNESS" 2>&1)"
RC=$?

[ "$RC" -eq 0 ] && exit 0

if [ "$RC" -ge 2 ]; then
  {
    echo "[하네스 드리프트] 대조에 실패했습니다(diff 종료 상태 $RC)."
    echo
    echo "$DRIFT"
    echo
    echo "대조를 못 했으므로 통과시키지 않습니다 — 권한·경로를 확인하십시오."
    echo "끄려면: ECC_DISABLED_HOOKS=$HOOK_ID"
  } >&2
  exit 2
fi

{
  echo "[하네스 드리프트] 워크트리의 .claude/harness/ 가 본 저장소와 다릅니다."
  echo
  echo "$DRIFT"
  echo
  echo "이 파일들은 planner·architect·reviewer 가 '이 프로젝트의 사실'로 읽는 정본입니다."
  echo "낡은 사본을 읽으면 계획·설계가 처음부터 틀린 전제 위에 짜이고, 그건 PR 게이트로"
  echo "잡히지 않습니다(2026-08-21 실사고: 폐기된 계약 위치가 kty 회부의 권고안으로 올라갔습니다)."
  echo
  echo "1) 어느 쪽이 정본인지 먼저 보십시오. 이 검사는 방향을 판별하지 않습니다 —"
  echo "   '다르다'만 압니다. 보통은 본 저장소가 정본입니다."
  echo "     diff -u \"$MAIN_HARNESS/<파일>\" \"$WT_HARNESS/<파일>\""
  echo
  echo "2) 본 저장소가 맞으면 워크트리를 맞춥니다."
  echo "   ※ 덮어쓰기만 하면 워크트리에만 있는 잔재 파일이 남습니다. 지우고 다시 넣으십시오."
  echo "     rm -rf \"$WT_HARNESS\" && cp -R \"$MAIN_HARNESS\" \"$REAL_DIR/.claude/\""
  echo
  echo "3) 워크트리 쪽이 의도된 최신이면 본 저장소에 먼저 반영한 뒤 진행하십시오."
  echo
  echo "위 명령들은 하네스를 다루므로 이 훅이 막지 않습니다. 캐시도 없어 동기화하면 바로 통과합니다."
  echo "끄려면: ECC_DISABLED_HOOKS=$HOOK_ID"
} >&2
exit 2
