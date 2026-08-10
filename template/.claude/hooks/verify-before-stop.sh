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
# 대화 기록 경로. 결정 게이트(3.2)가 이 턴의 발화를 읽는 데 쓴다. 비어 있거나 못 읽으면
# 그 게이트만 생략되고 **사유가 마지막 게이트 메시지에 실린다** — 조용히 사라지지 않는
# 것이 이 fail-open 의 조건이다(decision_scan 주석 참조).
transcript_path="$(printf '%s' "$payload" | json_get transcript_path)"

# (0) push 미완 **탐지** — 조기 종료보다 **먼저** 해야 한다.
#     플래그를 다 처리해 지운 뒤가 바로 위험한 시점인데(29커밋을 잃은 그 상태),
#     아래 조기 종료가 먼저 걸리면 push 게이트는 영영 안 돈다(검수 [치명] 지적).
#     탐지만 여기서 하고 차단은 예산·지문 기계가 준비된 뒤에 한다.
push_unsent=""
push_branch=""
if ! hook_disabled "stop:push" && git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  push_branch="$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)"
  if [ -n "$push_branch" ] && git -C "$PROJECT_DIR" remote get-url origin >/dev/null 2>&1; then
    if git -C "$PROJECT_DIR" rev-parse --verify -q "refs/remotes/origin/$push_branch" >/dev/null 2>&1; then
      # rc 를 따로 본다. 실패를 "ahead 0" 으로 읽으면 게이트가 조용히 사라진다([cx] 지적).
      if push_n="$(git -C "$PROJECT_DIR" rev-list --count "refs/remotes/origin/$push_branch..HEAD" 2>/dev/null)"; then
        [ -n "$push_n" ] && [ "$push_n" != "0" ] && push_unsent="원격보다 ${push_n}개 앞서 있습니다"
      else
        push_unsent="원격과의 차이를 셀 수 없습니다(저장소 상태 이상) — 직접 확인하세요"
      fi
    elif git -C "$PROJECT_DIR" rev-parse --verify -q HEAD >/dev/null 2>&1; then
      # ref 가 없다. 다만 **HEAD 가 이미 다른 원격 브랜치에 있으면** 새 커밋이 없는
      # 갓 만든 브랜치이므로 요구하지 않는다 — 안 그러면 브랜치를 파자마자 막힌다.
      # 파이프 안 서브셸에서 exit 로 신호하면 그 rc 가 밖으로 안 나온다 — 실제로 그렇게
      # 짰다가 조건이 항상 거짓이 됐다. 서브셸 없는 for 루프로 판정한다(ref 이름에는
      # 공백이 못 들어가므로 단어 분리가 안전하다).
      head_on_remote=0
      for _r in $(git -C "$PROJECT_DIR" for-each-ref --format='%(refname)' refs/remotes 2>/dev/null); do
        if git -C "$PROJECT_DIR" merge-base --is-ancestor HEAD "$_r" 2>/dev/null; then
          head_on_remote=1; break
        fi
      done
      if [ "$head_on_remote" -eq 0 ]; then
        push_unsent="이 브랜치의 원격 추적 ref 가 없습니다 (한 번도 push 되지 않았거나, refspec 이 좁혀져 보이지 않습니다)"
      fi
    fi
  fi
fi

# (1) 코드 변경이 없는 턴 → 검사 전부 생략. 읽기 전용 질문에 타입체크를 돌리지 않는다.
#     두 게이트 플래그(감사·설명)가 모두 비어야 "할 일 없음"이다.
#     지식 플래그는 **게이트가 켜져 있을 때만** 할 일로 센다 — 껐는데 예전에 남은
#     플래그 파일이 읽기 전용 턴의 조기 종료를 막으면 안 된다.
if [ -z "$push_unsent" ] && [ ! -s "$AUDIT_FLAG" ] && [ ! -s "$EXPLAIN_FLAG" ] && ! knowledge_gate_active && [ ! -s "$DUALREVIEW_FLAG" ]; then
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
knowledge_gate_active     && flags_fp="${flags_fp}k"
[ -s "$DUALREVIEW_FLAG" ] && flags_fp="${flags_fp}d"
# push 는 "몇 개 남았나"가 곧 진전이다. 지문에 안 넣으면 한 커밋씩 올리는 실제 진전이
# 같은 지문으로 세어져 예산이 소진되고, 그때 감사 플래그까지 함께 지워진다([cx] 지적).
[ -n "$push_unsent" ] && flags_fp="${flags_fp}p:${push_branch}:${push_unsent}"
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
    changed="$(cat "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" 2>/dev/null | tr -d '"\\' | sort -u | tr '\n' ' ')"
    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
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

# (3.2) **결정 게이트** — "물어봤어야 할 것을 혼자 정했나".
#      나머지 게이트가 전부 **산출물**을 볼 때 이것만 **에이전트 자신의 행동**을 본다.
#      판정 규칙·좁히는 장치 셋·fail-open 사유는 _common.sh 의 decision_scan 주석이 정본이다.
#
#      **다른 게이트보다 앞에 둔다.** 질문의 답이 코드를 바꿀 수 있으므로, 리뷰·설명·감사에
#      노력을 쓰기 전에 묻는 편이 싸다. (push 탐지와 달리 순서가 정확성을 바꾸지는 않는다 —
#      대화 기록은 이미 다 쓰였고 게이트 순서가 그 내용을 바꾸지 않기 때문이다.)
decision_note=""
if ! hook_disabled "stop:decision"; then
  decision_hits="$(decision_scan "$transcript_path")"; decision_rc=$?
  if [ "$decision_rc" -eq 2 ]; then
    # **이 게이트의 유일한 fail-open.** 통과시키되 사유를 (6) 의 메시지에 실어 보낸다.
    # 대화 기록 형식은 하네스 소유가 아니라, 여기서 차단하면 그 세션 안에 고칠 방법이 없다.
    decision_note="결정 게이트 생략 ($decision_hits)"
  elif [ "$decision_rc" -eq 0 ]; then
    gate_budget "decision"
    {
      echo "[완료 차단] 혼자 정한 것이 있는데 이 턴에 사용자에게 한 번도 묻지 않았습니다."
      echo
      echo "걸린 문장:"
      printf '%s\n' "$decision_hits" | sed 's/^/  - /'
      echo
      echo "이 게이트가 겨누는 것:"
      echo "  게이트가 막을 때는 따르면서, 게이트가 없는 자리에서는 혼자 정하고 보고서에"
      echo "  한 줄 적는 부류입니다. 그 '한 줄'은 도구 호출이 아니라 문장이라 승인창이"
      echo "  안 뜨고, 그래서 이 저장소가 겪은 실패 대부분이 이 축에서 났습니다."
      echo
      echo "해야 할 일:"
      echo "  1. 위 문장들이 정말 **사용자가 정할 일**이었는지 본다."
      echo "     '범위 밖'·'별도로'·'그대로 뒀'는 대개 선택지를 줬어야 하는 자리입니다."
      echo "  2. AskUserQuestion 으로 **실제로 묻는다.** 보고서에 적는 것은 묻는 것이 아닙니다."
      echo "  3. 질문을 한 번이라도 하면 이 게이트는 풀립니다."
      echo
      echo "위양성이라면(그 어휘를 설명·인용한 것이지 결정이 아니라면):"
      echo "  - 백틱이나 따옴표로 감싸면 스캔에서 빠집니다 — 인용은 결정이 아니니까요."
      echo "  - 그래도 걸리면 사용자에게 위양성임을 알리고 지시를 받으세요."
      echo
      echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:decision"
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

# (5) 지식 저장소 반영 게이트 — 감사보다 먼저 강제한다 (감사자가 반영 결과를 검증하도록).
#     (2026-08-02 kty — 산문 규칙이 세션 내내 0회 이행된 실사고의 기계화)
#
#     **이 훅이 아는 것은 계약 하나뿐이다**: "지식 저장소가 설정돼 있으면, 결정·설계가
#     나온 턴은 반영 없이 끝낼 수 없다." 저장소가 어디인지·어떤 구조인지·무엇을 어느
#     파일에 나눠 담는지는 **상위 층의 구현**이고 이 파일은 모른다. 알게 되면 그 저장소를
#     안 쓰는 환경에서 하네스가 없는 구조를 요구하게 된다(제0원칙 4 — 구체가 아닌 계약).
#     어디에 어떻게 저장했는지의 검증은 그 저장소 자신의 규약이 한다.
if knowledge_gate_active && ! hook_disabled "stop:knowledge"; then
  gate_budget "knowledge"
  {
    echo "[완료 차단] 지식 저장소 반영 미확인 — 이 턴의 결정·설계를 남기지 않고 끝낼 수 없습니다."
    echo
    echo "이 턴에서 바뀐 코드/설정:"
    sed 's/^/  - /' "$KNOWLEDGE_FLAG" 2>/dev/null
    echo
    echo "해야 할 일:"
    echo "  1. 이 머신의 지식 저장소가 **어디이고 어떤 형식인지는 사용자 층 설정**(전역"
    echo "     CLAUDE.md 등)이 답한다. 그 규약을 **전문** 읽는다 — 부분 독해 금지."
    echo "  2. 이번 턴에 결정·설계·개발작업이 있으면 그 규약대로 반영하고, 반영됐다는"
    echo "     확인 가능한 증거(커밋 해시·파일 경로 등)를 확보한다."
    echo "     판단을 만든 **근거(raw)** 도 규약이 정한 자리에 함께 남긴다 — 요약만 남기면"
    echo "     \"왜 그렇게 정했나\"가 복원 불가능해진다."
    echo "  3. 반영할 지식이 없으면(순수 버그픽스·기계적 수정) 불요 사유를 _workspace/progress.md 에 기록한다."
    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-knowledge"
    echo "     completion-auditor 가 그 증거(또는 불요 사유의 타당성)를 검증한다."
    echo "  5. 지식 저장소를 아예 쓰지 않는 환경이면 harness.env 의 HARNESS_KNOWLEDGE_GATE 를 비운다."
    echo
    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:knowledge"
  } >&2
  bump_and_block
fi

# (5.5) **커밋했는데 원격에 없다** — 이 저장소가 커밋 29개를 잃은 바로 그 상태다.
#      그때는 "아직 PR 전이니까"라며 라운드 6개를 미뤘고, 임시 폴더째 사라졌다.
#      탐지는 (0) 에서 이미 했다 — 조기 종료보다 앞이어야 하기 때문이다.
if [ -n "$push_unsent" ]; then
  gate_budget "push"
  {
    echo "[완료 차단] 커밋이 원격에 없습니다 — $push_unsent"
    echo
    echo "이 저장소는 이 상태로 **커밋 29개를 잃은 적이 있습니다.** 그때도 코드는"
    echo "다 짜여 있었고, \"아직 PR 전이니까\"라며 push 를 미뤘습니다."
    echo
    echo "해야 할 일:"
    echo "  git push -u origin $push_branch"
    echo "  그리고 실제로 올라갔는지 확인하세요:"
    echo "  git rev-list --left-right --count HEAD...origin/$push_branch   → 0 0"
    echo
    echo "  원격에는 있는데 위 명령이 실패한다면 refspec 이 좁혀진 것입니다:"
    echo "  git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git fetch origin"
    echo "  push 여부가 로컬에서 안 보이는 것 자체가 위험합니다 — 29개를 잃을 때 그랬습니다."
    echo
    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:push"
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
  # 결정 게이트가 대화 기록을 못 읽었으면 **여기서 소리를 낸다.** 그 게이트만 조용히
  # 사라지면 "물어봤나"를 아무도 안 보게 되고, 그게 정확히 이 게이트를 만든 이유다.
  if [ -n "$decision_note" ]; then
    echo
    echo "참고: $decision_note"
    echo "      → 이 턴에 사용자에게 물었어야 할 결정이 없었는지 스스로 확인하세요."
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
