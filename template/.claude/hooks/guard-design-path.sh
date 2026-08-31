#!/usr/bin/env bash
# PostToolUse(Skill) · PreToolUse(Write|Edit|MultiEdit|NotebookEdit):
# 설계·계획 산출물은 harness-orchestrator 경로로만 낳는다. (도메인-무관 재사용 템플릿)
#
# 왜 필요한가 (실사고 2026-08-31):
#   오케스트레이터가 harness-orchestrator 를 태우지 않고 설계서를 **직접** 썼다. 그러면
#   프로필의 "지식 진입점" 절이 통째로 적용되지 않는다 — 그 절의 `[읽는 이]` 는
#   clarifier·architect·planner·plan-reviewer 이고, 선행 결정 회수 프로토콜의 정본은
#   harness-orchestrator SKILL.md 의 dispatch 계약이기 때문이다. 결과: 설계서 3판이
#   **낡은 정본** 위에 섰고, 듀얼 리뷰 두 라운드가 그것을 다시 발견하는 데 소모됐다.
#
# 판정 축 (2026-08-31 듀얼 리뷰 [cx] 반영으로 재작성):
#   초판은 "면제 목록 먼저, 설계 판정 나중"의 배타 구조였다 — 면제 부분문자열이 하나만
#   섞여도 설계 판정을 아예 안 해서 `10_설계서_리뷰반영본.md` 가 통과했다([cx H-4] 실측 5/5).
#   재작성판은 **면제 목록 자체를 없앴다**: 설계 패턴을 문서 유형 토큰(설계서·계획서 등)과
#   앵커드 영문 패턴으로 좁혀서, 리뷰 판정문·raw·색인·입력서가 **애초에 설계 패턴에 안 걸린다**.
#   상위 층 어휘(색인·입력서 등)를 하네스가 아는 문제([cx M-5])도 같이 사라진다.
#
# 무엇을 하나:
#   1) PostToolUse(Skill): harness-orchestrator 가 **성공적으로 실행되면** 세션에 도장.
#      (초판은 PreToolUse 라 존재하지 않는 스킬 호출도 도장을 찍었다 — [cx H-2])
#   2) PreToolUse(쓰기 도구): 설계·계획 산출물인데 이 세션의 도장이 없으면 차단(rc=2).
#
# 상태 파일: $STATE_DIR/.harness-path.<cksum(session)> — 세션별 파일. 내용은 세션 식별자
#   한 줄. 병렬 세션이 서로의 도장을 덮지 않는다([cx M-2]). 임시 파일 → mv 원자 쓰기.
#   세션이 끝나도 파일은 남지만(수십 바이트) 값 대조 때문에 다른 세션을 통과시키지 못한다.
#
# 실패 방향: **잠기는 쪽으로 실패한다**([cx H-3]). 공용 모듈 로드 실패·JSON 파싱 실패·
#   경로 필드 부재는 쓰기 게이트에서 rc=2 다. 이웃 guard-publish-review.sh 와 같은 방향.
#
# 알려진 한계(정직 고지 — [cx H-1]·[cx M-6]):
#   - Bash/PowerShell 리다이렉트·mv·cp, 파일 쓰기 MCP 도구는 이 훅의 매처 밖이다.
#   - **직접 슬래시 호출(`/harness-orchestrator`)은 Skill 도구를 우회해 도장이 안 찍힌다**
#     ([cx r2 M-1]) — 그 세션에서 설계 쓰기가 막히면 Skill 도구 경유로 다시 태워야 한다.
#   - 도장 파일은 모델이 쓸 수 있는 경로라 위조 가능하다.
#   - 도장이 증명하는 것은 "Skill 도구가 harness-orchestrator 지시문을 로드했다"까지다 —
#     파이프라인 완주를 증명하지 않는다([cx r2 M-3]).
#   - 설계 패턴 밖의 새 명명(예: `10_아키텍처안.md`·`설계.md`)은 못 잡는다.
#   - 범용 `-plan.md`/`-design.md` 문서(`migration-plan.md` 등)는 차단된다(위 공시 결정) —
#     하네스 정의 디렉터리 밖에서 그 이름을 쓰려면 도장이 필요하다.
#   **과속방지턱이지 방벽이 아니다.** 막혔다는 사실이 안전을 보증하지 않는다.
#
# 셸 이식성: macOS 기본 bash 3.2. ${var,,}·mapfile·연관배열 금지.

set -uo pipefail

# 공용 모듈 로드 실패 = 차단. 조용히 통과하면 게이트 전체가 무단 소멸한다([cx H-3]).
if ! . "$(dirname "${BASH_SOURCE[0]}")/_common.sh" 2>/dev/null; then
  echo "[설계 경로 강제] 공용 모듈(_common.sh)을 로드하지 못했습니다 — 안전하게 차단합니다." >&2
  exit 2
fi

HOOK_ID="pre:write:design-path"
hook_disabled "$HOOK_ID" && exit 0

payload="$(cat)"

# JSON 유효성을 먼저 못박는다. json_get 은 파싱 실패를 빈 문자열로 접는데,
# 그 빈 값이 "쓰기 도구가 아님"과 구분되지 않아 fail-open 이 됐다([cx H-3]).
# 타입까지 검증한다([cx r2 M-2]) — json_get 은 배열·불리언도 문자열화해 통과시켰다.
if ! printf '%s' "$payload" | python3 -c '
import json, sys
d = json.load(sys.stdin)
if not isinstance(d, dict): sys.exit(1)
for k in ("tool_name", "session_id"):
    if k in d and not isinstance(d[k], str): sys.exit(1)
ti = d.get("tool_input")
if ti is not None:
    if not isinstance(ti, dict): sys.exit(1)
    for k in ("file_path", "notebook_path", "skill"):
        if k in ti and not isinstance(ti[k], str): sys.exit(1)
' 2>/dev/null; then
  echo "[설계 경로 강제] 훅 입력 JSON 파싱·타입 검증에 실패했습니다 — 안전하게 차단합니다." >&2
  exit 2
fi

tool="$(printf '%s' "$payload" | json_get tool_name)"
session="$(printf '%s' "$payload" | json_get session_id)"

stamp_path() {  # $1=session → 세션별 도장 경로. cksum 은 POSIX·bash3.2 안전.
  printf '%s/.harness-path.%s' "$STATE_DIR" "$(printf '%s' "$1" | cksum | cut -d' ' -f1)"
}

# --- 1) 도장: harness-orchestrator 실행 완료 (PostToolUse 에 배선) --------------
if [ "$tool" = "Skill" ]; then
  skill="$(printf '%s' "$payload" | json_get tool_input.skill)"
  # 정확 일치만. 부분 문자열 매치는 "not-harness-orchestrator-x" 도 도장을 찍었다([cx H-2]).
  # 플러그인 접두(<plugin>:harness-orchestrator)는 **불허** — 임의 플러그인이 같은 이름의
  # 스킬을 제공하면 도장을 받는 신뢰 구멍이 된다([cx r3 M-1]). 이 스킬은 프로젝트 소유다.
  case "$skill" in
    harness-orchestrator)
      if [ -n "$session" ]; then
        STAMP="$(stamp_path "$session")"
        tmp="$STAMP.tmp.$$"
        if mkdir -p "$STATE_DIR" 2>/dev/null \
           && printf '%s\n' "$session" > "$tmp" 2>/dev/null \
           && mv "$tmp" "$STAMP" 2>/dev/null; then
          :
        else
          # PostToolUse 라 차단은 못 한다. 침묵은 다음 쓰기에서 엉뚱한 사유의 차단이 되므로
          # 경고를 남긴다([cx M-2]).
          rm -f "$tmp" 2>/dev/null
          echo "[설계 경로 강제] 도장 기록 실패($STAMP) — 이 세션의 설계 쓰기가 차단될 수 있습니다." >&2
        fi
      fi
      ;;
  esac
  exit 0
fi

# --- 2) 게이트: 설계·계획 산출물인가 -------------------------------------------
raw="$(printf '%s' "$payload" | json_get tool_input.file_path; printf 'X')"
raw="${raw%X}"
file_path="${raw%$'\n'}"
if [ -z "$file_path" ]; then
  # NotebookEdit 는 notebook_path 를 쓴다([cx H-1]).
  raw="$(printf '%s' "$payload" | json_get tool_input.notebook_path; printf 'X')"
  raw="${raw%X}"
  file_path="${raw%$'\n'}"
fi
if [ -z "$file_path" ]; then
  # 유효한 JSON 인데 경로 필드가 없다 — 이 매처(쓰기 도구)에선 있어야 정상이다.
  # 새 도구 스키마·비문자열 경로가 조용히 새는 것을 막는다([cx H-3]).
  echo "[설계 경로 강제] 쓰기 도구 호출에서 파일 경로를 읽지 못했습니다 — 안전하게 차단합니다." >&2
  exit 2
fi

# 유니코드 정규화(NFC) — macOS 는 파일명을 NFD(자모 분해형)로 돌려주기도 해서, NFC 로
# 저장된 아래 한글 글롭이 같은 이름을 놓친다(cc r4 [H-2]: NFD 설계서가 rc=0 실측).
# python3 존재는 위 타입 검증이 이미 보증한다(없으면 그 단계에서 rc=2).
file_path="$(printf '%s' "$file_path" | python3 -c 'import sys,unicodedata; sys.stdout.write(unicodedata.normalize("NFC", sys.stdin.read()))')"

lower="$(printf '%s' "$file_path" | tr '[:upper:]' '[:lower:]')"
base="$(basename "$lower")"

# 하네스 정의 경로는 산출물이 아니다 — **구조(디렉터리 계약) 기반 면제**라 r1 의 이름
# 부분문자열 면제([cx H-4] 로 제거된 그것)와 다르다. 실제 오탐 실증: 에이전트 정의
# `plan-reviewer.md`(cc r4 [H-1]) · 명령 정의 `gan-design.md`·`multi-plan.md`(cx r4 [M-1]).
case "$lower" in
  */.claude/agents/*.md|*/.claude/commands/*.md|*/.claude/skills/*|*/commands/*.md) exit 0 ;;
esac

# 일반 문서 이름과의 충돌은 **공시된 결정**이다: `migration-plan.md`·`test-plan.md` 같은
# 범용 이름은 `media-plan.md`(산출물) 과 이름만으로 구분할 수 없어 **차단 쪽으로 기운다**
# (cc r3 [H-1] 요구와 cc r4 [H-1] 오탐 지적의 절충 — 게이트의 목적상 위양성이 위음성보다 싸다).
# 설계·계획 산출물 판정. 면제 목록은 없다(이름 축) — 패턴을 좁혀서 리뷰·raw·색인·입력서가
# 애초에 안 걸리게 한다([cx H-4]·[cx M-5]).
#   한글: 문서 유형 토큰(…서·…안) + .md 강제([cx M-1] — 확장자 없으면 소스·데이터를 막았다).
#         `설계입력서`(입력 문서)는 `설계서` 연속 토큰이 아니라 안 걸린다.
#   영문: 번호 앵커·선행형·**후행형 전부 경계 문자(_ 또는 -) 필수** + 정확 이름(design.md·plan.md) —
#         후행형 하이픈 누락으로 `auth-design.md` 가 통과하던 구멍은 cc r3 [H-1] 이 잡았다.
#         `00_plan-media.md`·`00_design-reference-gate.md` 가 실계약이다([cx r2 H-1]).
#         `12_designer.md`·`00_designdoc.md` 는 경계 문자가 없어 비적중(공시된 결정 —
#         mark-needs-audit 의 느슨한 글롭과 다르며, 그쪽 계약 정렬은 후속 판단).
#         느슨한 중간 패턴(*_design_*)은 리뷰 명명 계약(NN_<출처>_plan_review)과 충돌해 뺐다.
is_design=0
case "$base" in
  *설계서*.md|*설계안*.md|*계획서*.md|*계획안*.md)              is_design=1 ;;
  [0-9][0-9]_design.md|[0-9][0-9]_design[_-]*.md)               is_design=1 ;;
  [0-9][0-9]_plan.md|[0-9][0-9]_plan[_-]*.md)                   is_design=1 ;;
  design.md|plan.md)                                            is_design=1 ;;
  design[_-]*.md|*[_-]design.md|plan[_-]*.md|*[_-]plan.md)      is_design=1 ;;
esac
[ "$is_design" -eq 0 ] && exit 0

# 도장 대조 — 이 세션의 도장만 유효하다.
stamped=""
if [ -n "$session" ]; then
  STAMP="$(stamp_path "$session")"
  [ -f "$STAMP" ] && stamped="$(cat "$STAMP" 2>/dev/null)"
fi
if [ -n "$session" ] && [ "$stamped" = "$session" ]; then
  exit 0
fi

cat >&2 <<'MSG'
[설계 경로 강제] 설계·계획 산출물을 harness-orchestrator 경로 밖에서 쓰려 했습니다.
MSG
printf '\n  대상: %s\n\n' "$file_path" >&2
cat >&2 <<'MSG'
이 게이트가 있는 이유: 오케스트레이터가 직접 설계서를 쓰면 프로필의 **지식 진입점 절이
적용되지 않습니다** — 그 절의 [읽는 이]는 clarifier·architect·planner·plan-reviewer 이고,
선행 결정 회수 프로토콜의 정본은 harness-orchestrator SKILL.md 의 dispatch 계약입니다.
그것을 건너뛰면 설계가 **낡은 정본** 위에 서고, 듀얼 리뷰가 그걸 다시 발견하는 데
라운드를 씁니다 (2026-08-31 실사고).

할 일:
  1) Skill 도구로 harness-orchestrator 를 호출하고, 그 파이프라인이
     architect 에게 dispatch 하게 하십시오(착수 전 회수 3단계가 거기 붙어 있습니다).
  2) 산출물은 _workspace/NN_design_*.md · NN_plan_*.md 로 먼저 낳으십시오 —
     그래야 머리 표명 게이트(.needs-retrieval)가 함께 걸립니다.
     지식 저장소 이관은 그 게이트를 통과한 뒤입니다.

끄는 것은 사용자만 정합니다 — 막혔으면 우회하지 말고 사용자에게 보고하십시오.
MSG
exit 2
