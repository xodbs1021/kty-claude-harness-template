#!/usr/bin/env bash
# Stop: 코드를 건드린 턴은 (1) 타입체크 통과 (2) change-explainer 실행
#       (3) completion-auditor 실행 없이는 끝낼 수 없다.
#
# 무한루프 가드: "같은 지점에서 진전 없이" MAX_BLOCKS(3)회까지만 막는다.
# 게이트를 하나 지울 때마다(차단 지문 변화) 카운터가 리셋되므로 순차 처리로는
# 소진되지 않는다. 소진되면 플래그를 지우고 통과시키되 사용자에게 큰 경고를
# 띄운다. 세션이 벽돌이 되는 것보다 낫다. 지문 파일을 못 쓰면 리셋 없는 구식
# 누적으로, 카운터 파일도 못 쓰면 stop_hook_active 로 폴백한다.

set -uo pipefail
# shellcheck source=_common.sh
. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"

HOOK_ID="stop:verify"
hook_disabled "$HOOK_ID" && exit 0

payload="$(cat)"
stop_active="$(printf '%s' "$payload" | json_get stop_hook_active)"

# (1) 코드 변경이 없는 턴 → 검사 전부 생략. 읽기 전용 질문에 타입체크를 돌리지 않는다.
#     두 게이트 플래그(감사·설명)가 모두 비어야 "할 일 없음"이다.
if [ ! -s "$AUDIT_FLAG" ] && [ ! -s "$EXPLAIN_FLAG" ] && [ ! -s "$VAULT_FLAG" ] && [ ! -s "$DUALREVIEW_FLAG" ]; then
  rm -f "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
  exit 0
fi

# (2) 카운터 확인 — 벽돌 방지, 진전 인지 리셋 (2026-08-03 [cx] 지적 반영)
# 카운터의 목적은 "갇힘 감지"이지 노력 예산이 아니다. 게이트가 4종으로 늘며 공유 카운터
# 3회로는 게이트를 순서대로 성실히 처리해도 마지막 감사 게이트 전에 소진되는 역설이 있었다.
# → 차단 지문(어느 게이트에서, 어떤 플래그 상태로 막혔나)이 지난 차단과 다르면 = 진전이면
#   카운터를 리셋한다. 같은 지문으로 MAX_BLOCKS회 = 진짜 갇힘일 때만 경고와 통과.
count=0
if [ -f "$BLOCK_COUNT" ]; then
  count="$(tr -dc '0-9' < "$BLOCK_COUNT" 2>/dev/null)"
fi
[ -z "$count" ] && count=0
prev_fp="$(cat "$BLOCK_FP" 2>/dev/null)"
# 지문 = 서 있는 플래그의 집합(내용 아님). 내용을 넣으면 갇힌 채 새 파일만 편집해도
# 리셋되고(무한 차단), cksum 충돌로 실제 진전이 리셋 안 될 수도 있다([cx] 지적).
flags_fp=""
[ -s "$AUDIT_FLAG" ]      && flags_fp="${flags_fp}a"
[ -s "$EXPLAIN_FLAG" ]    && flags_fp="${flags_fp}e"
[ -s "$VAULT_FLAG" ]      && flags_fp="${flags_fp}v"
[ -s "$DUALREVIEW_FLAG" ] && flags_fp="${flags_fp}d"
new_fp=""

gate_budget() {  # $1 = 게이트 식별자. 각 차단 지점이 메시지 출력 전에 호출한다.
  new_fp="$1|$flags_fp"
  # 지문을 기록할 수 있을 때만 리셋한다 — 지문 파일을 못 쓰는 환경에서 리셋하면
  # prev_fp가 영원히 비어 매번 1/3로 무한 차단된다([cx] 지적). 그 경우 리셋 없는
  # 구식 누적으로 동작해 3회 후 통과가 보장된다.
  if printf '%s\n' "$new_fp" > "$BLOCK_FP" 2>/dev/null; then
    if [ "$new_fp" != "$prev_fp" ]; then
      count=0   # 지난 차단과 다른 게이트/플래그 집합 = 진전 — 예산 리셋
    fi
  fi
  if [ "$count" -ge "$MAX_BLOCKS" ]; then
    changed="$(cat "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$VAULT_FLAG" "$DUALREVIEW_FLAG" 2>/dev/null | tr -d '"\\' | sort -u | tr '\n' ' ')"
    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$VAULT_FLAG" "$DUALREVIEW_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
    printf '{"systemMessage":"[완료 게이트] 같은 지점(%s)에서 %s회 차단 후에도 진전이 없어 세션 벽돌 방지를 위해 통과시킵니다. 이 턴의 완료 주장(및 변경 설명)을 신뢰하지 마세요. 미처리 변경: %s"}\n' \
      "$1" "$MAX_BLOCKS" "$changed"
    exit 0
  fi
}

bump_and_block() {
  if ! printf '%s\n' "$((count + 1))" > "$BLOCK_COUNT" 2>/dev/null; then
    # 카운터를 못 쓰면 무한루프 위험 → 표준 가드로 폴백
    case "$stop_active" in
      [Tt]rue) exit 0 ;;
    esac
  fi
  exit 2
}

# (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
#     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
#     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
typecheck_note=""
#     rc 를 함께 받는다. "리터럴로 비웠다"(rc=0 + 빈 값 = 의도한 생략)와 "값을 믿을 수
#     없다"(rc=1 = 미설정·선언 2개 이상·지원 문법 밖·읽기 실패)는 둘 다 생략으로 가지만
#     사용자에게 **다른 정보**다. 후자는 고칠 수 있는 실수라 그렇게 적어야 한다.
TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"; typecheck_rc=$?

if [ "$typecheck_rc" -ne 0 ]; then
  typecheck_note="타입체크 생략 (harness.env 의 HARNESS_TYPECHECK_CMD 를 읽지 못함 — 미설정이거나, 선언이 2개 이상이거나, 지원 문법 밖입니다)"
elif [ -z "$TYPECHECK_CMD" ]; then
  typecheck_note="타입체크 생략 (HARNESS_TYPECHECK_CMD 가 빈 값으로 설정됨)"
else
  timeout_bin=""
  if command -v timeout >/dev/null 2>&1; then
    timeout_bin="timeout"
  elif command -v gtimeout >/dev/null 2>&1; then
    timeout_bin="gtimeout"
  fi
  # macOS 기본에는 timeout 이 없다. 그 경우 settings.json 의 "timeout": 120 이 최종 안전망.

  if [ -n "$timeout_bin" ]; then
    tc_out="$(cd "$PROJECT_DIR" && "$timeout_bin" 90 sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
  else
    tc_out="$(cd "$PROJECT_DIR" && sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
  fi

  if [ "$tc_rc" -eq 124 ] || [ "$tc_rc" -eq 137 ]; then
    # 타임아웃은 "타입 오류"가 아니라 "모름". 차단하지 않고 감사자에게 넘긴다.
    typecheck_note="타입체크 타임아웃 → 생략 (감사자가 재확인할 것)"
  elif [ "$tc_rc" -eq 127 ]; then
    # 명령/도구 없음(rc=127)은 "타입 오류"가 아니다. 오탐 차단 방지 위해 생략.
    typecheck_note="타입체크 생략 (명령 실행 불가 rc=127): $TYPECHECK_CMD"
  elif [ "$tc_rc" -ne 0 ]; then
    gate_budget "typecheck"
    {
      echo "[완료 차단] 타입체크 실패 — 지금은 '완료'가 아닙니다."
      echo
      echo "명령: $TYPECHECK_CMD"
      echo
      printf '%s\n' "$tc_out" | head -n 15
      echo
      echo "고친 뒤 다시 종료하세요.  (차단 $((count + 1))/${MAX_BLOCKS})"
      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
    } >&2
    bump_and_block
  fi
fi

# (3.5) 듀얼 리뷰(codex) 게이트 (2026-08-03 kty — "리뷰가 필요한 모든 단계를 codex와 같이"의 기계화).
#      설계·계획 산출물이 저장되거나 코드가 바뀐 턴은 codex 독립 리뷰 없이 끝낼 수 없다.
#      Claude 단독 리뷰가 놓친 CRITICAL을 codex가 잡은 실사고(2026-08-03 POK-30)의 재발 방지.
if [ -s "$DUALREVIEW_FLAG" ] && ! hook_disabled "stop:dualreview"; then
  gate_budget "dualreview"
  {
    echo "[완료 차단] codex 듀얼 리뷰 미수행 — Claude 단독 리뷰로는 끝낼 수 없습니다."
    echo
    echo "이 턴의 듀얼 리뷰 대상:"
    sed 's/^/  - /' "$DUALREVIEW_FLAG" 2>/dev/null
    echo
    echo "해야 할 일:"
    echo "  1. 대상 산출물/diff를 codex로 독립 리뷰시킨다 (모델·effort는 guard-codex-invocation 규정 — 임의 하향 금지)."
    echo "  2. 결과를 _workspace/ 에 *codex*.md 로 저장하고 지적을 [cc]/[cx] 태그로 통합한다."
    echo "  3. 그 뒤에만:  rm -f .claude/.needs-dualreview"
    echo "     codex 미설치·호출 실패면 사용자 보고에 '듀얼 리뷰 생략(codex 실패)'을 명시한 뒤에 지운다."
    echo "     리뷰 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
    echo
    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
  } >&2
  bump_and_block
fi

# (4) change-explainer 게이트 (Phase 5) — 감사자보다 먼저 강제한다.
#     코드가 바뀐 턴은 변경 설명 없이 끝낼 수 없다. change-explainer 가 실제로
#     사용자용 설명을 낸 뒤에만 .needs-explain 을 지운다.
#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
if [ -s "$EXPLAIN_FLAG" ] && ! hook_disabled "stop:explain"; then
  gate_budget "explain"
  {
    echo "[완료 차단] change-explainer 미실행 — 변경 설명 없이 끝낼 수 없습니다."
    echo
    echo "이 턴에서 바뀐 코드/설정:"
    sed 's/^/  - /' "$EXPLAIN_FLAG" 2>/dev/null
    echo
    echo "해야 할 일:"
    echo "  1. change-explainer 에이전트로 실제 diff 기반 사용자용 변경 설명을 낸다."
    echo "  2. 설명을 낸 뒤에만:  rm -f .claude/.needs-explain"
    echo "     설명 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
    echo
    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
  } >&2
  bump_and_block
fi

# (5) 볼트(second brain) 반영 게이트 — 감사보다 먼저 강제한다 (감사자가 반영 결과를 검증하도록).
#     결정·설계·개발작업이 나온 턴은 볼트 Projects/<name>/ 4종 세트 반영 없이 끝낼 수 없다.
#     (2026-08-02 kty — 산문 Auto-Save 규칙이 세션 내내 0회 이행된 실사고의 기계화)
if [ -s "$VAULT_FLAG" ] && ! hook_disabled "stop:vault"; then
  gate_budget "vault"
  {
    echo "[완료 차단] 볼트(second brain) 반영 미확인 — 지식 반영 없이 끝낼 수 없습니다."
    echo
    echo "이 턴에서 바뀐 코드/설정:"
    sed 's/^/  - /' "$VAULT_FLAG" 2>/dev/null
    echo
    echo "해야 할 일:"
    echo "  1. 볼트 _CLAUDE.md 를 **전문** 읽는다 (부분 독해 금지 — head -N 사고 전례 있음)."
    echo "  2. 이번 턴에 결정·설계·개발작업이 있으면 볼트 Projects/<name>/ 4종 세트"
    echo "     (discussion-log + decisions/ADR + architecture + index)로 반영·커밋하고 해시를 확보한다."
    echo "     raw 산출물(설계 전문 등)은 specs/ 에 보존한다 — raw와 요약 둘 다다."
    echo "  3. 반영할 지식이 없으면(순수 버그픽스·기계적 수정) 불요 사유를 _workspace/progress.md 에 기록한다."
    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-vault"
    echo "     completion-auditor 가 커밋 해시·파일 실존(또는 불요 사유의 타당성)을 검증한다."
    echo
    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:vault"
  } >&2
  bump_and_block
fi

# (6) 타입체크는 통과했지만 감사자가 아직 안 돌았다.
gate_budget "audit"
{
  echo "[완료 차단] completion-auditor 미실행 — '완료'라고 말할 수 없습니다."
  echo
  echo "이 턴에서 바뀐 코드/설정:"
  sed 's/^/  - /' "$AUDIT_FLAG" 2>/dev/null
  if [ -n "$typecheck_note" ]; then
    echo
    echo "참고: $typecheck_note"
  fi
  echo
  echo "해야 할 일:"
  echo "  1. completion-auditor 에이전트로 완료 주장을 1차 증거로 검증한다."
  echo "  2. 검증을 통과했을 때만:  rm -f .claude/.needs-audit"
  echo "     감사 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
  echo
  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
} >&2
bump_and_block
