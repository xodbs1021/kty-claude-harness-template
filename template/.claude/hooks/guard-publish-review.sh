#!/usr/bin/env bash
# PreToolUse(발행 도구 matcher): 외부 발행 앞에 "최근 듀얼 리뷰 실존"을 요구한다. (ADR-0022)
#
# ── 무엇의 축소판인가 ───────────────────────────────────────────────────
# ADR-0018 리뷰 영수증 게이트(PR #25, 기각)의 축소 재작업이다. 실사고(2026-08-14 —
# 스파이크 판정 4건이 듀얼 리뷰 없이 Jira 코멘트·위키로 발행, 사후 리뷰에서 4건 전부
# 변경요청)의 원인 유형은 "깜빡 누락"이었고, 누락을 잡는 데 digest·nonce·영수증 발급
# 기계는 과했다(kty 판정 2026-08-16: "문제의식은 옳았고 답의 크기가 틀렸다").
#
# ── 검증하는 것 (전부 기계 판정) ────────────────────────────────────────
#   ① 미해소 듀얼리뷰 플래그(.needs-dualreview)가 서 있으면 deny — 리뷰 앞지르기 금지
#   ② 최근 WINDOW분(기본 180, harness.env HARNESS_PUBLISH_REVIEW_WINDOW_MIN) 안에
#      생성/갱신된 _workspace/*codex*.md 가 하나도 없으면 deny — 리뷰 없는 발행 금지
#
# ── 검증하지 않는 것 (공시 — 없는 방어를 있다고 믿게 하지 않는다) ───────
#   · 리뷰한 내용과 발행하는 내용의 일치(digest 계열) — #25 기각과 함께 범위 밖.
#     리뷰 A 직후의 무관한 발행 B 는 통과한다. 시간창은 휴리스틱이다.
#   · 위조 — 영수증 방식도 같은 손 문제로 못 막던 것. 진정성은 감사자 몫.
#   · 등재 밖 도구·프로젝트 밖 디렉터리에서의 발행 — matcher 가 곧 등록부다(아래).
#
# ── 등록부 = settings.json 의 matcher ──────────────────────────────────
# 무엇을 막을지는 별도 registry 파일이 아니라 settings.json 의 matcher 정규식이 정한다.
# 파일 하나 줄이고, "등재했는데 이름이 틀려 조용히 무력화"(#25가 등재를 0건으로 출하한
# 이유)를 배선 층 하나로 좁힌다. 티켓 발부·전이(createJiraIssue·transitionJiraIssue)는
# kty 지시(2026-08-16 "티켓 발부 정도는 리뷰 없이 OK")로 의도적으로 매칭하지 않는다.
#
# fail 방향: 판정 불가는 deny(막는 쪽). PreToolUse 라 폭발 반경은 matcher 가 고른
# 발행 도구뿐이고, 훅 전체 비활성 탈출구가 있다.
# 셸 이식성: macOS 기본 bash 3.2. stat 은 BSD(-f %m) → GNU(-c %Y) 순으로 시도.

set -uo pipefail
# 소싱 실패 = 판정 불가 = 차단. 안 지키면 부분 설치·파일 유실에서 rc=127 로 죽는데,
# PreToolUse 는 rc=2 만 차단이라 그 죽음이 조용한 통과가 된다([cx] r1 HIGH 실측).
# shellcheck source=_common.sh
if ! . "$(dirname "${BASH_SOURCE[0]}")/_common.sh"; then
  echo "[발행 차단] 공용 모듈(_common.sh)을 읽지 못했습니다 — 판정 불가는 통과가 아니라 차단입니다. 설치 상태를 확인하세요." >&2
  exit 2
fi

HOOK_ID="pre:publish:review"
hook_disabled "$HOOK_ID" && exit 0

payload="$(cat)"
bind_session_state "$(printf '%s' "$payload" | json_get session_id)"
bind_project_dir "$(printf '%s' "$payload" | json_get cwd)"

# Artifact 도구는 조회(action:"list")가 있다 — 조회는 발행이 아니므로 통과.
# action 판독 불가(페이로드 손상·python3 부재)면 발행으로 취급한다(fail-closed).
tool="$(printf '%s' "$payload" | json_get tool_name)"
case "$tool" in
  *Artifact*)
    action="$(printf '%s' "$payload" | json_get tool_input.action)"
    [ "$action" = "list" ] && exit 0
    ;;
esac

deny() {  # $1 = 첫 줄 사유, $2 = 해야 할 일(여러 줄 허용)
  {
    echo "[발행 차단] $1"
    echo
    printf '%s\n' "$2"
    echo
    echo "이 훅이 보는 것: ① .needs-dualreview 미해소 여부 ② 최근 리뷰 산출물(_workspace/*codex*.md) 실존."
    echo "내용 일치·위조는 검증하지 않는다(훅 머리 공시) — 그 판단은 리뷰·감사가 한다."
    echo "탈출구(사용자 전용 — 셸에서 직접 export해야 하며, 에이전트가 대입을 시도하면 guard-hook-disable에 차단됨): HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
  } >&2
  exit 2
}

# ① 리뷰 앞지르기 금지 — 이 턴의 변경이 아직 듀얼 리뷰 전인데 밖으로 내보낼 수 없다.
if [ -s "$DUALREVIEW_FLAG" ]; then
  deny "이 턴의 변경이 아직 codex 듀얼 리뷰 전입니다 — 리뷰를 앞질러 발행할 수 없습니다." \
"해야 할 일:
  1. 대상 변경/산출물을 codex 듀얼 리뷰한다 (모델·effort 는 guard-codex-invocation 규정).
  2. 결과를 _workspace/*codex*.md 로 저장한다 (듀얼리뷰 게이트가 자동 해제된다).
  3. 그 다음 발행을 다시 시도한다."
fi

# ② 최근 리뷰 실존 — WINDOW분 안의 codex 리뷰 산출물이 하나는 있어야 한다.
# rc 를 갈라 받는다(_common.sh 반환 계약): rc=3(키 부재)·rc=0(판독됨)은 정상 경로,
# rc=1(중복 선언·문법 밖·읽기 실패)은 "값을 믿을 수 없음"이라 기본값으로 완화하지 않고
# 차단한다 — 5분 창을 쓰던 파일이 중복 선언 하나로 조용히 180분이 되면 안 된다([cx] r1 HIGH).
WINDOW_MIN="$(harness_env_value HARNESS_PUBLISH_REVIEW_WINDOW_MIN)"; wrc=$?
if [ "$wrc" -eq 1 ]; then
  deny "harness.env 의 HARNESS_PUBLISH_REVIEW_WINDOW_MIN 값을 믿을 수 없습니다(중복 선언·지원 문법 밖·읽기 실패) — 판정 불가는 차단입니다." \
"harness.env 에서 그 키를 한 줄 선언으로 고치거나 지우세요(지우면 기본 180분). 고칠 수 있는 실수입니다."
fi
case "$WINDOW_MIN" in ''|*[!0-9]*) WINDOW_MIN=180 ;; esac
# 10진 강제: "08" 같은 선행 0 값이 8진수 산술로 죽으면 rc=1 이 되고, PreToolUse 는
# rc=2 만 차단이라 그 죽음이 통과가 된다([cx] r1 HIGH 실측 — value too great for base).
WINDOW_MIN=$((10#$WINDOW_MIN))

now="$(date +%s)" || now=""
case "$now" in ''|*[!0-9]*)
  deny "현재 시각을 얻지 못해 리뷰 최신성을 판정할 수 없습니다(date 실패)." \
"환경을 확인한 뒤 다시 시도하세요. 판정 불가는 통과가 아니라 차단입니다(fail-closed)."
  ;;
esac
now=$((10#$now))

recent=""
for f in "$PROJECT_DIR/_workspace"/*codex*.md; do
  [ -f "$f" ] || continue
  m="$(stat -f %m "$f" 2>/dev/null)" || m=""
  [ -n "$m" ] || { m="$(stat -c %Y "$f" 2>/dev/null)" || m=""; }
  case "$m" in ''|*[!0-9]*) continue ;; esac
  m=$((10#$m))
  age=$(( now - m ))
  # 미래 mtime(시계 어긋난 머신에서 복사된 파일 등)은 "최근"으로 치지 않는다 —
  # 음수 나이를 통과시키면 그 시각까지 창이 사실상 무한이 된다([cx] r1 MEDIUM).
  [ "$age" -ge 0 ] || continue
  if [ "$age" -le $(( WINDOW_MIN * 60 )) ]; then
    recent="$f"
    break
  fi
done

if [ -z "$recent" ]; then
  deny "최근 ${WINDOW_MIN}분 안의 codex 리뷰 산출물(_workspace/*codex*.md)이 없습니다 — 리뷰 없이 발행할 수 없습니다. (2026-08-14 실사고: 판정 4건이 리뷰 없이 Jira·위키로 나갔고 4건 전부 사후 변경요청)" \
"해야 할 일:
  1. 발행하려는 내용(판정·결론·문서)을 codex 듀얼 리뷰한다.
  2. 결과를 _workspace/*codex*.md 로 저장한다.
  3. 발행을 다시 시도한다 — 저장 직후면 이 게이트는 통과한다.
  창 조정(사용자): harness.env 의 HARNESS_PUBLISH_REVIEW_WINDOW_MIN=<분> (기본 180)."
fi

exit 0
