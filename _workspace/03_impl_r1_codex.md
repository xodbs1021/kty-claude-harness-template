Reading additional input from stdin...
2026-08-10T02:05:38.580560Z ERROR codex_models_manager::cache: failed to load models cache: missing field `supports_reasoning_summaries` at line 93 column 5
OpenAI Codex v0.144.5
--------
workdir: /Users/kty/Downloads/kty-claude-harness-template
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019fe96b-1d0e-76a2-b484-150e17305a3b
--------
user
확정 커밋 33158e2 하나를 독립 검수한다. diff 는 _workspace/03_impl_r1.diff.

**제약: 파일 생성·삭제·수정 금지. mktemp·rm·mkdir 금지.** 정적 독해와 부작용 없는 셸 표현식 평가만. **반드시 마지막에 '판정: 통과' 또는 '판정: 보류' 줄을 내라.**

## 맥락

Stop 훅이 harness.env(사용자 소유 셸 파일)를 `source` 해서 설정값을 읽고 있었다. 그러면 그 파일 내용이 훅의 제어 흐름을 가져간다 — exit 1 이면 훅이 죽어 게이트 4종이 소멸하고, exit 0 이면 조용히 소멸한다(흔적 0). 서브셸·리다이렉트로 막아도 return·printf 재정의로 새 경로가 계속 나왔다.

이 커밋은 **실행을 버리고 원문 grep 판독**으로 바꿨다. _common.sh 에 harness_env_value() 신설, verify-before-stop.sh 가 그것을 쓴다.

판독 모델: 선행 공백 없는 최상위 대입만 선언으로 센다 / 선언이 정확히 1개일 때만 값을 믿고 2개 이상이면 빈 값(미설정) / 감싼 따옴표 한 겹만 벗긴다.

오케스트레이터 실측: 정상=[pnpm tsc --noEmit] · exit 1 포함=[pnpm tsc] · exit 0 포함=[pnpm tsc] · 들여쓴 위장 선언=[진짜] · 선언 2개=[]

## 중점적으로 봐라

1. **판독을 우회하는 경로가 남았는가.** 특히: 히어독 안의 그 키 / 주석 안 / 여러 줄 값 / `KEY=값 # 주석` 의 후행 주석 / 값에 개행이 들어간 경우 / `export` 변형 / CRLF 줄끝 / BOM / 키 이름이 다른 키의 접두사인 경우(HARNESS_TYPECHECK_CMD 와 HARNESS_TYPECHECK_CMD_EXTRA)
2. **grep 정규식에 $key 를 그대로 끼워 넣는다.** 호출부가 상수만 넘기지만, 메타문자가 들어오면 어떻게 되는가. 방어가 필요한가
3. **rc 처리.** grep 의 rc 2 이상(파일 읽기 실패 등)을 무매치와 같이 삼킨다 — 이게 fail-open 인가 fail-safe 인가. 이 훅의 위협 모델에서 어느 쪽이 옳은가
4. **local 사용.** _common.sh 는 bash 전제인가 POSIX sh 전제인가. 다른 훅들이 어떻게 부르는지 보고 판단해라
5. **회귀.** TYPECHECK_CMD 를 쓰던 기존 동작(빈 값이면 생략, timeout 실행)이 그대로인가. source 를 없애면서 **다른 변수도 같이 사라졌는가** — harness.env 의 다른 키를 쓰던 곳이 있는지 저장소 전체를 확인해라
6. **회귀 테스트가 없다.** 이 커밋에 테스트가 0건이다. 어떤 케이스가 반드시 있어야 하는가

지적은 [CRITICAL]/[HIGH]/[MEDIUM]/[LOW] + 파일:줄 + 구체적 실패 시나리오. 추측이면 추측이라고 적어라. **지적이 없으면 없다고 해라.**
codex
요청하신 제약을 그대로 지켜, 파일을 건드리지 않고 커밋·제공 diff·호출 경로·셸 전제를 정적으로 대조하겠습니다. 우선 작업 트리 상태와 관련 파일 전체를 읽은 뒤, 안전한 문자열/셸 표현식만 별도로 검산하겠습니다.
exec
/bin/zsh -lc 'pwd && git status --short && git show --stat --oneline --decorate --no-renames 33158e2 && git diff --no-ext-diff --unified=80 33158e2''^ 33158e2 -- && sed -n '"'1,260p' _workspace/03_impl_r1.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
/Users/kty/Downloads/kty-claude-harness-template
?? _workspace/
33158e2 (HEAD -> refactor/knowledge-store-layer) fix: harness.env 를 실행하지 않고 원문으로 읽는다
 template/.claude/hooks/_common.sh            | 37 ++++++++++++++++++++++++++++
 template/.claude/hooks/verify-before-stop.sh |  9 +++----
 2 files changed, 41 insertions(+), 5 deletions(-)
diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
index d052cd3..aa96a4d 100644
--- a/template/.claude/hooks/_common.sh
+++ b/template/.claude/hooks/_common.sh
@@ -1,51 +1,88 @@
 #!/usr/bin/env bash
 # 하네스 훅 공용 모듈. 각 훅 스크립트가 source 한다. (도메인-무관 재사용 템플릿)
 #
 # set -e 를 쓰지 않는다: 훅이 예기치 않게 죽으면 세션이 막히거나(Stop)
 # 멀쩡한 명령이 차단된다(PreToolUse). 모든 종료는 명시적으로 한다.
 
 PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
 STATE_DIR="$PROJECT_DIR/.claude"
 AUDIT_FLAG="$STATE_DIR/.needs-audit"
 EXPLAIN_FLAG="$STATE_DIR/.needs-explain"
 VAULT_FLAG="$STATE_DIR/.needs-vault"
 DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
 BLOCK_COUNT="$STATE_DIR/.stop-block-count"
 BLOCK_FP="$STATE_DIR/.stop-block-fp"    # 마지막 차단 지문(게이트|플래그 상태) — 진전 인지 리셋용
 
 # Stop 훅이 "같은 지점에서 진전 없이" 최대 몇 번까지 막을 수 있는가. 소진되면 통과시킨다
 # (세션 벽돌 방지). 차단 지문이 바뀌면(=게이트를 하나 지웠으면) 카운터는 리셋되므로,
 # 게이트 개수가 늘어도 이 상수를 올릴 필요가 없다.
 MAX_BLOCKS=3
 
 # 탈출구.
 #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
 #   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
 hook_disabled() {
   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
     return 0
   fi
   case ",${ECC_DISABLED_HOOKS:-}," in
     *",$1,"*) return 0 ;;
   esac
   return 1
 }
 
+# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
+#
+# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
+# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
+# 전부 실측된 것들이다:
+#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
+#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
+#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
+#   printf 재정의 → 진단 출력 자체를 위조
+# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
+# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
+# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
+#
+# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
+# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
+# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 **빈 값을 돌려준다**
+# (호출부가 "미설정"으로 안전하게 처리하도록).
+#
+# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **확장되지 않는다.** 실행하지 않는 대가다.
+# 확장이 필요하면 그 자리에 최종 문자열을 적어야 한다.
+harness_env_value() {
+  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
+  [ -f "$file" ] || { printf '%s' ''; return 0; }
+  # 선행 공백 없는 `KEY=` 또는 `export KEY=` 만. grep rc 는 삼킨다(무매치·오류 모두 미설정).
+  lines="$(grep -E "^(export[[:space:]]+)?${key}=" "$file" 2>/dev/null)" || lines=''
+  [ -n "$lines" ] || { printf '%s' ''; return 0; }
+  n="$(printf '%s\n' "$lines" | wc -l | tr -d ' ')"
+  [ "$n" = "1" ] || { printf '%s' ''; return 0; }
+  val="${lines#*=}"
+  # 감싼 따옴표 한 겹만 벗긴다(양쪽이 짝일 때만).
+  case "$val" in
+    \"*\") val="${val#\"}"; val="${val%\"}" ;;
+    \'*\') val="${val#\'}"; val="${val%\'}" ;;
+  esac
+  printf '%s' "$val"
+}
+
 # stdin 의 JSON 에서 점 경로로 값 하나를 뽑는다. 없거나 파싱 실패면 빈 문자열.
 # 훅 입력이 깨져도 절대 죽지 않는다 — 죽으면 오탐 차단이 된다.
 json_get() {
   python3 -c '
 import json, sys
 try:
     data = json.load(sys.stdin)
 except Exception:
     sys.exit(0)
 for key in sys.argv[1].split("."):
     if not isinstance(data, dict):
         sys.exit(0)
     data = data.get(key)
     if data is None:
         sys.exit(0)
 print(data)
 ' "$1" 2>/dev/null
 }
diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
index 93c23e2..cbb4bf3 100644
--- a/template/.claude/hooks/verify-before-stop.sh
+++ b/template/.claude/hooks/verify-before-stop.sh
@@ -1,165 +1,164 @@
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
+#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
+#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
+#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
 typecheck_note=""
-if [ -f "$STATE_DIR/harness/harness.env" ]; then
-  # shellcheck disable=SC1091
-  . "$STATE_DIR/harness/harness.env" 2>/dev/null
-fi
-TYPECHECK_CMD="${HARNESS_TYPECHECK_CMD:-}"
+TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"
 
 if [ -z "$TYPECHECK_CMD" ]; then
   typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"
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
commit 33158e2c4cb95b2063e6ebb07cdb68ebad32597e
Author: 김태윤 <xodbs9810@gmail.com>
Date:   Mon Aug 10 11:04:33 2026 +0900

    fix: harness.env 를 실행하지 않고 원문으로 읽는다
    
    harness.env 는 **사용자 소유 셸 파일**인데 Stop 훅이 그걸 source 해서 값을 읽었다.
    그러면 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가
    나온다. 실측된 것들:
    
      exit 1        훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
      exit 0        훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
      서브셸+return 호출 셸로 정상 복귀해 판정을 통과
      printf 재정의 진단 출력 자체를 위조
    
    서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. 실행하지 않으면 이 부류가
    **원리적으로** 소멸한다 — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는
    것이고, 그게 정확히 의도적으로 값을 바꾸는 방법이다.
    
    _common.sh 에 harness_env_value() 신설. 판독 모델:
    - 선행 공백 없는 최상위 대입만 선언으로 센다(조건문·함수 본문 안은 실행 여부를
      원문만으로 알 수 없다)
    - 선언이 2개 이상이면 어느 것이 이기는지 모르므로 빈 값을 돌려준다(미설정 취급)
    - 감싼 따옴표 한 겹만 벗긴다
    
    대가(공시): 값 안의 $VAR·$(...) 가 확장되지 않는다. 확장이 필요하면 최종 문자열을
    그 자리에 적어야 한다.
    
    실측: 정상=[pnpm tsc --noEmit] · exit 1 포함=[pnpm tsc] · exit 0 포함=[pnpm tsc] ·
    들여쓴 위장 선언=[진짜](최상위만 셈) · 선언 2개=[](미설정)

diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
index d052cd3..aa96a4d 100644
--- a/template/.claude/hooks/_common.sh
+++ b/template/.claude/hooks/_common.sh
@@ -31,6 +31,43 @@ hook_disabled() {
   return 1
 }
 
+# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
+#
+# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
+# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
+# 전부 실측된 것들이다:
+#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
+#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
+#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
+#   printf 재정의 → 진단 출력 자체를 위조
+# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
+# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
+# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
+#
+# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
+# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
+# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 **빈 값을 돌려준다**
+# (호출부가 "미설정"으로 안전하게 처리하도록).
+#
+# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **확장되지 않는다.** 실행하지 않는 대가다.
+# 확장이 필요하면 그 자리에 최종 문자열을 적어야 한다.
+harness_env_value() {
+  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
+  [ -f "$file" ] || { printf '%s' ''; return 0; }
+  # 선행 공백 없는 `KEY=` 또는 `export KEY=` 만. grep rc 는 삼킨다(무매치·오류 모두 미설정).
+  lines="$(grep -E "^(export[[:space:]]+)?${key}=" "$file" 2>/dev/null)" || lines=''
+  [ -n "$lines" ] || { printf '%s' ''; return 0; }
+  n="$(printf '%s\n' "$lines" | wc -l | tr -d ' ')"
+  [ "$n" = "1" ] || { printf '%s' ''; return 0; }
+  val="${lines#*=}"
+  # 감싼 따옴표 한 겹만 벗긴다(양쪽이 짝일 때만).
+  case "$val" in
+    \"*\") val="${val#\"}"; val="${val%\"}" ;;
+    \'*\') val="${val#\'}"; val="${val%\'}" ;;
+  esac
+  printf '%s' "$val"
+}
+
 # stdin 의 JSON 에서 점 경로로 값 하나를 뽑는다. 없거나 파싱 실패면 빈 문자열.
 # 훅 입력이 깨져도 절대 죽지 않는다 — 죽으면 오탐 차단이 된다.
 json_get() {
diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
index 93c23e2..cbb4bf3 100644
--- a/template/.claude/hooks/verify-before-stop.sh
+++ b/template/.claude/hooks/verify-before-stop.sh
@@ -77,12 +77,11 @@ bump_and_block() {
 # (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
 #     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
 #     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
+#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
+#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
+#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
 typecheck_note=""
-if [ -f "$STATE_DIR/harness/harness.env" ]; then
-  # shellcheck disable=SC1091
-  . "$STATE_DIR/harness/harness.env" 2>/dev/null
-fi
-TYPECHECK_CMD="${HARNESS_TYPECHECK_CMD:-}"
+TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"
 
 if [ -z "$TYPECHECK_CMD" ]; then
   typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"

codex
현재 변경 자체는 두 파일뿐입니다. 이제 저장소 전역에서 `harness.env`의 생산자·소비자와 `_common.sh` 호출 셸을 추적하고, 제시된 경계 사례가 실제 파서 결과와 게이트 의미에 어떤 영향을 주는지 구분하겠습니다.
exec
/bin/zsh -lc "rg -n --hidden --glob '"'!**/.git/**'"' 'harness\\.env|HARNESS_[A-Za-z0-9_]+|_common\\.sh|verify-before-stop' . && find template/.claude/hooks -maxdepth 1 -type f -print -exec sh -c 'printf \"%s: \" \""'$1"; head -n 1 "$1"'"' _ {} \\; && rg -n --hidden --glob '"'!**/.git/**'"' '("'^|[''^A-Za-z_])(sh|bash|zsh)[[:space:]]+[''^'"\\n]*(hooks|verify-before-stop|_common)|source[[:space:]].*_common|\\.[[:space:]].*_common' ." in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
./examples/chat-system.profile.md:34:- **타입체크:** `.claude/harness/harness.env` 참조 — 이 프로젝트는 `HARNESS_TYPECHECK_CMD="pnpm typecheck"` (정본은 env 파일, 여기는 안내만)
./README.md:51:| **슬롯** (프로젝트 소유, 절대 안 덮음) | `project-profile.md`(도메인 전부: 스택·검증·불변식·경계면·운영·vcs·예시) · `harness.env`(타입체크 명령) | 사용자 |
./README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
./README.md:163:│           ├── harness.env.template            # 타입체크 명령 슬롯
./README.md:181:- `HARNESS_TYPECHECK_CMD`가 프로필 §3과 harness.env 두 곳에 기입됨 — SSOT 위반. harness.env를 기계 정본으로, §3은 참조 표기로 정리.
./_workspace/03_impl_r1.diff:5:    fix: harness.env 를 실행하지 않고 원문으로 읽는다
./_workspace/03_impl_r1.diff:7:    harness.env 는 **사용자 소유 셸 파일**인데 Stop 훅이 그걸 source 해서 값을 읽었다.
./_workspace/03_impl_r1.diff:20:    _common.sh 에 harness_env_value() 신설. 판독 모델:
./_workspace/03_impl_r1.diff:32:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1.diff:34:--- a/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1.diff:35:+++ b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1.diff:40:+# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
./_workspace/03_impl_r1.diff:42:+# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
./_workspace/03_impl_r1.diff:61:+  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
./_workspace/03_impl_r1.diff:80:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1.diff:82:--- a/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1.diff:83:+++ b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1.diff:85: # (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
./_workspace/03_impl_r1.diff:86: #     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
./_workspace/03_impl_r1.diff:92:-if [ -f "$STATE_DIR/harness/harness.env" ]; then
./_workspace/03_impl_r1.diff:94:-  . "$STATE_DIR/harness/harness.env" 2>/dev/null
./_workspace/03_impl_r1.diff:96:-TYPECHECK_CMD="${HARNESS_TYPECHECK_CMD:-}"
./_workspace/03_impl_r1.diff:97:+TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"
./_workspace/03_impl_r1.diff:100:   typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"
./install.sh:8:#   슬롯(project-profile.md · harness.env)      → 없을 때만 스캐폴드, 절대 안 덮음
./install.sh:64:if [ ! -f "$DST/harness/harness.env" ]; then
./install.sh:65:  cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
./install.sh:66:  echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
./install.sh:68:  echo "   슬롯 보존    harness/harness.env          (기존 유지)"
./install.sh:131:echo "   2. $DST/harness/harness.env 의 HARNESS_TYPECHECK_CMD 채우기"
./sync.sh:85:echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)은 그대로입니다."
./_workspace/03_impl_r1_codex.md:21:Stop 훅이 harness.env(사용자 소유 셸 파일)를 `source` 해서 설정값을 읽고 있었다. 그러면 그 파일 내용이 훅의 제어 흐름을 가져간다 — exit 1 이면 훅이 죽어 게이트 4종이 소멸하고, exit 0 이면 조용히 소멸한다(흔적 0). 서브셸·리다이렉트로 막아도 return·printf 재정의로 새 경로가 계속 나왔다.
./_workspace/03_impl_r1_codex.md:23:이 커밋은 **실행을 버리고 원문 grep 판독**으로 바꿨다. _common.sh 에 harness_env_value() 신설, verify-before-stop.sh 가 그것을 쓴다.
./_workspace/03_impl_r1_codex.md:31:1. **판독을 우회하는 경로가 남았는가.** 특히: 히어독 안의 그 키 / 주석 안 / 여러 줄 값 / `KEY=값 # 주석` 의 후행 주석 / 값에 개행이 들어간 경우 / `export` 변형 / CRLF 줄끝 / BOM / 키 이름이 다른 키의 접두사인 경우(HARNESS_TYPECHECK_CMD 와 HARNESS_TYPECHECK_CMD_EXTRA)
./_workspace/03_impl_r1_codex.md:34:4. **local 사용.** _common.sh 는 bash 전제인가 POSIX sh 전제인가. 다른 훅들이 어떻게 부르는지 보고 판단해라
./_workspace/03_impl_r1_codex.md:35:5. **회귀.** TYPECHECK_CMD 를 쓰던 기존 동작(빈 값이면 생략, timeout 실행)이 그대로인가. source 를 없애면서 **다른 변수도 같이 사라졌는가** — harness.env 의 다른 키를 쓰던 곳이 있는지 저장소 전체를 확인해라
./_workspace/03_impl_r1_codex.md:46:33158e2 (HEAD -> refactor/knowledge-store-layer) fix: harness.env 를 실행하지 않고 원문으로 읽는다
./_workspace/03_impl_r1_codex.md:47: template/.claude/hooks/_common.sh            | 37 ++++++++++++++++++++++++++++
./_workspace/03_impl_r1_codex.md:48: template/.claude/hooks/verify-before-stop.sh |  9 +++----
./_workspace/03_impl_r1_codex.md:50:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1_codex.md:52:--- a/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1_codex.md:53:+++ b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1_codex.md:76: #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/03_impl_r1_codex.md:79:   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/03_impl_r1_codex.md:88:+# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
./_workspace/03_impl_r1_codex.md:90:+# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
./_workspace/03_impl_r1_codex.md:109:+  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
./_workspace/03_impl_r1_codex.md:143:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:145:--- a/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:146:+++ b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:159: # shellcheck source=_common.sh
./_workspace/03_impl_r1_codex.md:160: . "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
./_workspace/03_impl_r1_codex.md:224: # (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
./_workspace/03_impl_r1_codex.md:225: #     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
./_workspace/03_impl_r1_codex.md:231:-if [ -f "$STATE_DIR/harness/harness.env" ]; then
./_workspace/03_impl_r1_codex.md:233:-  . "$STATE_DIR/harness/harness.env" 2>/dev/null
./_workspace/03_impl_r1_codex.md:235:-TYPECHECK_CMD="${HARNESS_TYPECHECK_CMD:-}"
./_workspace/03_impl_r1_codex.md:236:+TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"
./_workspace/03_impl_r1_codex.md:239:   typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"
./_workspace/03_impl_r1_codex.md:271:       echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/03_impl_r1_codex.md:295:     echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/03_impl_r1_codex.md:321:    fix: harness.env 를 실행하지 않고 원문으로 읽는다
./_workspace/03_impl_r1_codex.md:323:    harness.env 는 **사용자 소유 셸 파일**인데 Stop 훅이 그걸 source 해서 값을 읽었다.
./_workspace/03_impl_r1_codex.md:336:    _common.sh 에 harness_env_value() 신설. 판독 모델:
./_workspace/03_impl_r1_codex.md:348:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1_codex.md:350:--- a/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1_codex.md:351:+++ b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1_codex.md:356:+# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
./_workspace/03_impl_r1_codex.md:358:+# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
./_workspace/03_impl_r1_codex.md:377:+  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
./_workspace/03_impl_r1_codex.md:396:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:398:--- a/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:399:+++ b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:401: # (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
./_workspace/03_impl_r1_codex.md:402: #     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
./_workspace/03_impl_r1_codex.md:408:-if [ -f "$STATE_DIR/harness/harness.env" ]; then
./_workspace/03_impl_r1_codex.md:410:-  . "$STATE_DIR/harness/harness.env" 2>/dev/null
./_workspace/03_impl_r1_codex.md:412:-TYPECHECK_CMD="${HARNESS_TYPECHECK_CMD:-}"
./_workspace/03_impl_r1_codex.md:413:+TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"
./_workspace/03_impl_r1_codex.md:416:   typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"
./_workspace/03_impl_r1_codex.md:419:현재 변경 자체는 두 파일뿐입니다. 이제 저장소 전역에서 `harness.env`의 생산자·소비자와 `_common.sh` 호출 셸을 추적하고, 제시된 경계 사례가 실제 파서 결과와 게이트 의미에 어떤 영향을 주는지 구분하겠습니다.
./tests/mark-needs-audit.cases.sh:392:case_43() { # 탈출구 HARNESS_HOOKS=off. run_hook 이 기본으로 소거하므로 여기서만 재주입한다.
./tests/mark-needs-audit.cases.sh:396:  run_hook "$p" "$p/src/app.ts" HARNESS_HOOKS=off
./tests/mark-needs-audit.cases.sh:397:  check_case '43 HARNESS_HOOKS=off → 무변화' 0 none ''
./tests/mark-needs-audit.test.sh:41:COMMON="$REPO_ROOT/template/.claude/hooks/_common.sh"
./tests/mark-needs-audit.test.sh:46:[ -f "$COMMON" ] || { echo "✗ _common.sh 를 찾지 못했습니다: $COMMON" >&2; exit 1; }
./tests/mark-needs-audit.test.sh:85:# new_project — 가짜 프로젝트. 훅과 _common.sh 를 **둘 다** 설치한다
./tests/mark-needs-audit.test.sh:86:# (훅이 dirname "$BASH_SOURCE"/_common.sh 를 source 하므로 하나만 두면 못 돈다).
./tests/mark-needs-audit.test.sh:92:  cp "$COMMON" "$p/.claude/hooks/_common.sh"
./tests/mark-needs-audit.test.sh:104:  printf '# common\n'        > "$r/template/.claude/hooks/_common.sh"
./tests/mark-needs-audit.test.sh:131:  cp "$COMMON" "$repo/app/.claude/hooks/_common.sh"
./tests/mark-needs-audit.test.sh:181:# 앰비언트 탈출구를 **소거**하고 부른다. 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off /
./tests/mark-needs-audit.test.sh:193:        | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
./docs/usage.md:28:2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략).
./docs/usage.md:37:| **슬롯 (프로젝트 소유)** | `harness/project-profile.md` · `harness/harness.env` | 사용자 — sync가 절대 안 덮음 |
./docs/usage.md:64:| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → codex 듀얼리뷰 → change-explainer → 볼트(second brain) 반영 → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
./docs/usage.md:66:**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:vault`(볼트 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./docs/usage.md:87:- **타입체크가 이상하게 실패** → `harness.env`의 명령을 셸에서 직접 실행해 확인. 도구 부재(rc=127)·타임아웃은 차단 안 하고 생략 처리된다.
./template/CLAUDE.md.snippet:11:**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 완료·설명 게이트 플래그 / Stop 시 타입체크(프로필 §3)+change-explainer+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:30:| `template/.claude/hooks/verify-before-stop.sh` | `.needs-vault` |
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:31:| `template/.claude/hooks/_common.sh` | `.needs-vault` |
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:54:**슬롯은 이미 있는 관용구를 쓴다.** `harness.env`의 `HARNESS_TYPECHECK_CMD=""`가 *"비우면 Stop 훅이 타입체크를 생략한다"* 인 것과 같은 모양으로:
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:59:HARNESS_KNOWLEDGE_GATE=""
./template/.claude/settings.json:37:            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/verify-before-stop.sh\"",
./docs/decisions/2026-08-06-gate-scope-by-file-identity.md:60:**C. 정본 마커에 `template/.claude/hooks/_common.sh` 존재까지 AND 조건**
./template/.claude/harness/project-profile.template.md:41:`[읽는 이: developer · ecc:code-reviewer · completion-auditor · pr-author · verify-before-stop 훅]`
./template/.claude/harness/project-profile.template.md:43:> **타입체크 명령의 기계 정본은 `.claude/harness/harness.env`의 `HARNESS_TYPECHECK_CMD`다** — Stop 훅은 그 파일만 읽는다.
./template/.claude/harness/project-profile.template.md:46:- **타입체크:** `.claude/harness/harness.env` 참조 (여기 다시 적지 않는다)
./template/.claude/harness/harness.env.template:1:# harness.env — verify-before-stop.sh 가 source 하는 기계 판독 설정.
./template/.claude/harness/harness.env.template:2:# install.sh 가 이 템플릿을 프로젝트의 .claude/harness/harness.env 로 복사하고,
./template/.claude/harness/harness.env.template:9:#   HARNESS_TYPECHECK_CMD="pnpm typecheck"
./template/.claude/harness/harness.env.template:10:#   HARNESS_TYPECHECK_CMD="pnpm tsc --noEmit"
./template/.claude/harness/harness.env.template:11:#   HARNESS_TYPECHECK_CMD="npm run typecheck"
./template/.claude/harness/harness.env.template:12:#   HARNESS_TYPECHECK_CMD="cargo check"
./template/.claude/harness/harness.env.template:13:#   HARNESS_TYPECHECK_CMD="go build ./..."
./template/.claude/harness/harness.env.template:14:#   HARNESS_TYPECHECK_CMD="mypy ."
./template/.claude/harness/harness.env.template:15:HARNESS_TYPECHECK_CMD=""
./template/.claude/skills/harness-orchestrator/SKILL.md:33:| developer | §2 · §3 검증 · §4 · §5 | principles.md · 계획서 경로 · harness.env(타입체크 정본) |
./template/.claude/skills/harness-orchestrator/SKILL.md:34:| ecc:code-reviewer (검수) | §3 · §4 · §5 | principles.md · harness.env · dispatch 계약(아래) |
./template/.claude/skills/harness-orchestrator/SKILL.md:39:| completion-auditor | §3 · §6 | 완료 주장 목록 · harness.env |
./template/.claude/skills/harness-orchestrator/SKILL.md:133:**이 게이트는 산문이 아니라 훅으로 강제된다** (`.claude/settings.json`). 코드/설정을 편집하면 `.claude/.needs-audit`·`.needs-explain`·`.needs-vault` 플래그가 서고, Stop 훅이 타입체크(§3, `harness.env`) + 설명 + **볼트 반영** + 감사 없이는 턴 종료를 막는다(rc=2). 감사자가 검증을 통과시킨 **뒤에만** `rm -f .claude/.needs-audit` — 감사 없이 플래그만 지우는 것은 게이트 무력화다. 같은 지점에서 진전 없이 3회 차단되면 벽돌 방지 통과되며(게이트를 지울 때마다 카운터 리셋), 그때는 완료 주장을 신뢰하지 말 것.
./template/.claude/hooks/_common.sh:22:#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./template/.claude/hooks/_common.sh:25:  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./template/.claude/hooks/_common.sh:34:# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
./template/.claude/hooks/_common.sh:36:# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
./template/.claude/hooks/_common.sh:55:  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
./template/.claude/hooks/mark-needs-audit.sh:34:# shellcheck source=_common.sh
./template/.claude/hooks/mark-needs-audit.sh:35:. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
./template/.claude/hooks/verify-before-stop.sh:12:# shellcheck source=_common.sh
./template/.claude/hooks/verify-before-stop.sh:13:. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
./template/.claude/hooks/verify-before-stop.sh:77:# (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
./template/.claude/hooks/verify-before-stop.sh:78:#     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
./template/.claude/hooks/verify-before-stop.sh:84:TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"
./template/.claude/hooks/verify-before-stop.sh:87:  typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"
./template/.claude/hooks/verify-before-stop.sh:119:      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./template/.claude/hooks/verify-before-stop.sh:143:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./template/.claude/hooks/verify-before-stop.sh:165:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./template/.claude/hooks/verify-before-stop.sh:190:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:vault"
./template/.claude/hooks/verify-before-stop.sh:212:  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./template/.claude/hooks/guard-master-commit.sh:15:# shellcheck source=_common.sh
./template/.claude/hooks/guard-master-commit.sh:16:. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
./template/.claude/hooks/guard-master-commit.sh:60:  echo "  HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
template/.claude/hooks/verify-before-stop.sh
template/.claude/hooks/verify-before-stop.sh: #!/usr/bin/env bash
template/.claude/hooks/guard-codex-invocation.sh
template/.claude/hooks/guard-codex-invocation.sh: #!/usr/bin/env bash
template/.claude/hooks/mark-needs-audit.sh
template/.claude/hooks/mark-needs-audit.sh: #!/usr/bin/env bash
template/.claude/hooks/guard-master-commit.sh
template/.claude/hooks/guard-master-commit.sh: #!/usr/bin/env bash
template/.claude/hooks/_common.sh
template/.claude/hooks/_common.sh: #!/usr/bin/env bash
./_workspace/03_impl_r1.diff:32:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1.diff:80:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:23:이 커밋은 **실행을 버리고 원문 grep 판독**으로 바꿨다. _common.sh 에 harness_env_value() 신설, verify-before-stop.sh 가 그것을 쓴다.
./_workspace/03_impl_r1_codex.md:34:4. **local 사용.** _common.sh 는 bash 전제인가 POSIX sh 전제인가. 다른 훅들이 어떻게 부르는지 보고 판단해라
./_workspace/03_impl_r1_codex.md:50:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1_codex.md:143:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:160: . "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
./_workspace/03_impl_r1_codex.md:348:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
./_workspace/03_impl_r1_codex.md:396:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
./_workspace/03_impl_r1_codex.md:419:현재 변경 자체는 두 파일뿐입니다. 이제 저장소 전역에서 `harness.env`의 생산자·소비자와 `_common.sh` 호출 셸을 추적하고, 제시된 경계 사례가 실제 파서 결과와 게이트 의미에 어떤 영향을 주는지 구분하겠습니다.
./docs/decisions/2026-08-06-gate-scope-by-file-identity.md:60:**C. 정본 마커에 `template/.claude/hooks/_common.sh` 존재까지 AND 조건**
./template/.claude/hooks/guard-master-commit.sh:16:. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
./template/.claude/hooks/mark-needs-audit.sh:35:. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
./template/.claude/hooks/verify-before-stop.sh:13:. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
./template/.claude/settings.json:9:            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-master-commit.sh\"",
./template/.claude/settings.json:14:            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-codex-invocation.sh\"",
./template/.claude/settings.json:26:            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/mark-needs-audit.sh\"",
./template/.claude/settings.json:37:            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/verify-before-stop.sh\"",
./tests/mark-needs-audit.cases.sh:634:  check_case '64 모노레포 하위 .claude/hooks/x.sh → 게이트 4종(기존 동작, 범위 밖)' 0 gate 'packages/app/.claude/hooks/x.sh'
./tests/mark-needs-audit.test.sh:85:# new_project — 가짜 프로젝트. 훅과 _common.sh 를 **둘 다** 설치한다
./tests/mark-needs-audit.test.sh:196:              bash "$proj/.claude/hooks/mark-needs-audit.sh" 2>"$errf")"
./install.sh:42:cp "$SRC/hooks/"*.sh "$DST/hooks/"

exec
/bin/zsh -lc "nl -ba template/.claude/hooks/_common.sh | sed -n '1,130p'; nl -ba template/.claude/hooks/verify-before-stop.sh | sed -n '1,260p'; nl -ba template/.claude/harness/harness.env.template; nl -ba template/.claude/settings.json; git ls-tree -r --name-only 33158e2 | rg '("'^|/)(test|tests|spec|specs)(/|'"\\.|"'$)|'"\\.bats"'$'"' && git show 33158e2"'^:template/.claude/hooks/verify-before-stop.sh | nl -ba | sed -n '"'70,130p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# 하네스 훅 공용 모듈. 각 훅 스크립트가 source 한다. (도메인-무관 재사용 템플릿)
     3	#
     4	# set -e 를 쓰지 않는다: 훅이 예기치 않게 죽으면 세션이 막히거나(Stop)
     5	# 멀쩡한 명령이 차단된다(PreToolUse). 모든 종료는 명시적으로 한다.
     6	
     7	PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
     8	STATE_DIR="$PROJECT_DIR/.claude"
     9	AUDIT_FLAG="$STATE_DIR/.needs-audit"
    10	EXPLAIN_FLAG="$STATE_DIR/.needs-explain"
    11	VAULT_FLAG="$STATE_DIR/.needs-vault"
    12	DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
    13	BLOCK_COUNT="$STATE_DIR/.stop-block-count"
    14	BLOCK_FP="$STATE_DIR/.stop-block-fp"    # 마지막 차단 지문(게이트|플래그 상태) — 진전 인지 리셋용
    15	
    16	# Stop 훅이 "같은 지점에서 진전 없이" 최대 몇 번까지 막을 수 있는가. 소진되면 통과시킨다
    17	# (세션 벽돌 방지). 차단 지문이 바뀌면(=게이트를 하나 지웠으면) 카운터는 리셋되므로,
    18	# 게이트 개수가 늘어도 이 상수를 올릴 필요가 없다.
    19	MAX_BLOCKS=3
    20	
    21	# 탈출구.
    22	#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
    23	#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
    24	hook_disabled() {
    25	  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
    26	    return 0
    27	  fi
    28	  case ",${ECC_DISABLED_HOOKS:-}," in
    29	    *",$1,"*) return 0 ;;
    30	  esac
    31	  return 1
    32	}
    33	
    34	# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
    35	#
    36	# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
    37	# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
    38	# 전부 실측된 것들이다:
    39	#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
    40	#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
    41	#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
    42	#   printf 재정의 → 진단 출력 자체를 위조
    43	# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
    44	# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
    45	# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
    46	#
    47	# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
    48	# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
    49	# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 **빈 값을 돌려준다**
    50	# (호출부가 "미설정"으로 안전하게 처리하도록).
    51	#
    52	# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **확장되지 않는다.** 실행하지 않는 대가다.
    53	# 확장이 필요하면 그 자리에 최종 문자열을 적어야 한다.
    54	harness_env_value() {
    55	  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
    56	  [ -f "$file" ] || { printf '%s' ''; return 0; }
    57	  # 선행 공백 없는 `KEY=` 또는 `export KEY=` 만. grep rc 는 삼킨다(무매치·오류 모두 미설정).
    58	  lines="$(grep -E "^(export[[:space:]]+)?${key}=" "$file" 2>/dev/null)" || lines=''
    59	  [ -n "$lines" ] || { printf '%s' ''; return 0; }
    60	  n="$(printf '%s\n' "$lines" | wc -l | tr -d ' ')"
    61	  [ "$n" = "1" ] || { printf '%s' ''; return 0; }
    62	  val="${lines#*=}"
    63	  # 감싼 따옴표 한 겹만 벗긴다(양쪽이 짝일 때만).
    64	  case "$val" in
    65	    \"*\") val="${val#\"}"; val="${val%\"}" ;;
    66	    \'*\') val="${val#\'}"; val="${val%\'}" ;;
    67	  esac
    68	  printf '%s' "$val"
    69	}
    70	
    71	# stdin 의 JSON 에서 점 경로로 값 하나를 뽑는다. 없거나 파싱 실패면 빈 문자열.
    72	# 훅 입력이 깨져도 절대 죽지 않는다 — 죽으면 오탐 차단이 된다.
    73	json_get() {
    74	  python3 -c '
    75	import json, sys
    76	try:
    77	    data = json.load(sys.stdin)
    78	except Exception:
    79	    sys.exit(0)
    80	for key in sys.argv[1].split("."):
    81	    if not isinstance(data, dict):
    82	        sys.exit(0)
    83	    data = data.get(key)
    84	    if data is None:
    85	        sys.exit(0)
    86	print(data)
    87	' "$1" 2>/dev/null
    88	}
     1	#!/usr/bin/env bash
     2	# Stop: 코드를 건드린 턴은 (1) 타입체크 통과 (2) change-explainer 실행
     3	#       (3) completion-auditor 실행 없이는 끝낼 수 없다.
     4	#
     5	# 무한루프 가드: "같은 지점에서 진전 없이" MAX_BLOCKS(3)회까지만 막는다.
     6	# 게이트를 하나 지울 때마다(차단 지문 변화) 카운터가 리셋되므로 순차 처리로는
     7	# 소진되지 않는다. 소진되면 플래그를 지우고 통과시키되 사용자에게 큰 경고를
     8	# 띄운다. 세션이 벽돌이 되는 것보다 낫다. 지문 파일을 못 쓰면 리셋 없는 구식
     9	# 누적으로, 카운터 파일도 못 쓰면 stop_hook_active 로 폴백한다.
    10	
    11	set -uo pipefail
    12	# shellcheck source=_common.sh
    13	. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
    14	
    15	HOOK_ID="stop:verify"
    16	hook_disabled "$HOOK_ID" && exit 0
    17	
    18	payload="$(cat)"
    19	stop_active="$(printf '%s' "$payload" | json_get stop_hook_active)"
    20	
    21	# (1) 코드 변경이 없는 턴 → 검사 전부 생략. 읽기 전용 질문에 타입체크를 돌리지 않는다.
    22	#     두 게이트 플래그(감사·설명)가 모두 비어야 "할 일 없음"이다.
    23	if [ ! -s "$AUDIT_FLAG" ] && [ ! -s "$EXPLAIN_FLAG" ] && [ ! -s "$VAULT_FLAG" ] && [ ! -s "$DUALREVIEW_FLAG" ]; then
    24	  rm -f "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
    25	  exit 0
    26	fi
    27	
    28	# (2) 카운터 확인 — 벽돌 방지, 진전 인지 리셋 (2026-08-03 [cx] 지적 반영)
    29	# 카운터의 목적은 "갇힘 감지"이지 노력 예산이 아니다. 게이트가 4종으로 늘며 공유 카운터
    30	# 3회로는 게이트를 순서대로 성실히 처리해도 마지막 감사 게이트 전에 소진되는 역설이 있었다.
    31	# → 차단 지문(어느 게이트에서, 어떤 플래그 상태로 막혔나)이 지난 차단과 다르면 = 진전이면
    32	#   카운터를 리셋한다. 같은 지문으로 MAX_BLOCKS회 = 진짜 갇힘일 때만 경고와 통과.
    33	count=0
    34	if [ -f "$BLOCK_COUNT" ]; then
    35	  count="$(tr -dc '0-9' < "$BLOCK_COUNT" 2>/dev/null)"
    36	fi
    37	[ -z "$count" ] && count=0
    38	prev_fp="$(cat "$BLOCK_FP" 2>/dev/null)"
    39	# 지문 = 서 있는 플래그의 집합(내용 아님). 내용을 넣으면 갇힌 채 새 파일만 편집해도
    40	# 리셋되고(무한 차단), cksum 충돌로 실제 진전이 리셋 안 될 수도 있다([cx] 지적).
    41	flags_fp=""
    42	[ -s "$AUDIT_FLAG" ]      && flags_fp="${flags_fp}a"
    43	[ -s "$EXPLAIN_FLAG" ]    && flags_fp="${flags_fp}e"
    44	[ -s "$VAULT_FLAG" ]      && flags_fp="${flags_fp}v"
    45	[ -s "$DUALREVIEW_FLAG" ] && flags_fp="${flags_fp}d"
    46	new_fp=""
    47	
    48	gate_budget() {  # $1 = 게이트 식별자. 각 차단 지점이 메시지 출력 전에 호출한다.
    49	  new_fp="$1|$flags_fp"
    50	  # 지문을 기록할 수 있을 때만 리셋한다 — 지문 파일을 못 쓰는 환경에서 리셋하면
    51	  # prev_fp가 영원히 비어 매번 1/3로 무한 차단된다([cx] 지적). 그 경우 리셋 없는
    52	  # 구식 누적으로 동작해 3회 후 통과가 보장된다.
    53	  if printf '%s\n' "$new_fp" > "$BLOCK_FP" 2>/dev/null; then
    54	    if [ "$new_fp" != "$prev_fp" ]; then
    55	      count=0   # 지난 차단과 다른 게이트/플래그 집합 = 진전 — 예산 리셋
    56	    fi
    57	  fi
    58	  if [ "$count" -ge "$MAX_BLOCKS" ]; then
    59	    changed="$(cat "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$VAULT_FLAG" "$DUALREVIEW_FLAG" 2>/dev/null | tr -d '"\\' | sort -u | tr '\n' ' ')"
    60	    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$VAULT_FLAG" "$DUALREVIEW_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
    61	    printf '{"systemMessage":"[완료 게이트] 같은 지점(%s)에서 %s회 차단 후에도 진전이 없어 세션 벽돌 방지를 위해 통과시킵니다. 이 턴의 완료 주장(및 변경 설명)을 신뢰하지 마세요. 미처리 변경: %s"}\n' \
    62	      "$1" "$MAX_BLOCKS" "$changed"
    63	    exit 0
    64	  fi
    65	}
    66	
    67	bump_and_block() {
    68	  if ! printf '%s\n' "$((count + 1))" > "$BLOCK_COUNT" 2>/dev/null; then
    69	    # 카운터를 못 쓰면 무한루프 위험 → 표준 가드로 폴백
    70	    case "$stop_active" in
    71	      [Tt]rue) exit 0 ;;
    72	    esac
    73	  fi
    74	  exit 2
    75	}
    76	
    77	# (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
    78	#     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
    79	#     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
    80	#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
    81	#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
    82	#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
    83	typecheck_note=""
    84	TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"
    85	
    86	if [ -z "$TYPECHECK_CMD" ]; then
    87	  typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"
    88	else
    89	  timeout_bin=""
    90	  if command -v timeout >/dev/null 2>&1; then
    91	    timeout_bin="timeout"
    92	  elif command -v gtimeout >/dev/null 2>&1; then
    93	    timeout_bin="gtimeout"
    94	  fi
    95	  # macOS 기본에는 timeout 이 없다. 그 경우 settings.json 의 "timeout": 120 이 최종 안전망.
    96	
    97	  if [ -n "$timeout_bin" ]; then
    98	    tc_out="$(cd "$PROJECT_DIR" && "$timeout_bin" 90 sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
    99	  else
   100	    tc_out="$(cd "$PROJECT_DIR" && sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   101	  fi
   102	
   103	  if [ "$tc_rc" -eq 124 ] || [ "$tc_rc" -eq 137 ]; then
   104	    # 타임아웃은 "타입 오류"가 아니라 "모름". 차단하지 않고 감사자에게 넘긴다.
   105	    typecheck_note="타입체크 타임아웃 → 생략 (감사자가 재확인할 것)"
   106	  elif [ "$tc_rc" -eq 127 ]; then
   107	    # 명령/도구 없음(rc=127)은 "타입 오류"가 아니다. 오탐 차단 방지 위해 생략.
   108	    typecheck_note="타입체크 생략 (명령 실행 불가 rc=127): $TYPECHECK_CMD"
   109	  elif [ "$tc_rc" -ne 0 ]; then
   110	    gate_budget "typecheck"
   111	    {
   112	      echo "[완료 차단] 타입체크 실패 — 지금은 '완료'가 아닙니다."
   113	      echo
   114	      echo "명령: $TYPECHECK_CMD"
   115	      echo
   116	      printf '%s\n' "$tc_out" | head -n 15
   117	      echo
   118	      echo "고친 뒤 다시 종료하세요.  (차단 $((count + 1))/${MAX_BLOCKS})"
   119	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   120	    } >&2
   121	    bump_and_block
   122	  fi
   123	fi
   124	
   125	# (3.5) 듀얼 리뷰(codex) 게이트 (2026-08-03 kty — "리뷰가 필요한 모든 단계를 codex와 같이"의 기계화).
   126	#      설계·계획 산출물이 저장되거나 코드가 바뀐 턴은 codex 독립 리뷰 없이 끝낼 수 없다.
   127	#      Claude 단독 리뷰가 놓친 CRITICAL을 codex가 잡은 실사고(2026-08-03 POK-30)의 재발 방지.
   128	if [ -s "$DUALREVIEW_FLAG" ] && ! hook_disabled "stop:dualreview"; then
   129	  gate_budget "dualreview"
   130	  {
   131	    echo "[완료 차단] codex 듀얼 리뷰 미수행 — Claude 단독 리뷰로는 끝낼 수 없습니다."
   132	    echo
   133	    echo "이 턴의 듀얼 리뷰 대상:"
   134	    sed 's/^/  - /' "$DUALREVIEW_FLAG" 2>/dev/null
   135	    echo
   136	    echo "해야 할 일:"
   137	    echo "  1. 대상 산출물/diff를 codex로 독립 리뷰시킨다 (모델·effort는 guard-codex-invocation 규정 — 임의 하향 금지)."
   138	    echo "  2. 결과를 _workspace/ 에 *codex*.md 로 저장하고 지적을 [cc]/[cx] 태그로 통합한다."
   139	    echo "  3. 그 뒤에만:  rm -f .claude/.needs-dualreview"
   140	    echo "     codex 미설치·호출 실패면 사용자 보고에 '듀얼 리뷰 생략(codex 실패)'을 명시한 뒤에 지운다."
   141	    echo "     리뷰 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   142	    echo
   143	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
   144	  } >&2
   145	  bump_and_block
   146	fi
   147	
   148	# (4) change-explainer 게이트 (Phase 5) — 감사자보다 먼저 강제한다.
   149	#     코드가 바뀐 턴은 변경 설명 없이 끝낼 수 없다. change-explainer 가 실제로
   150	#     사용자용 설명을 낸 뒤에만 .needs-explain 을 지운다.
   151	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
   152	if [ -s "$EXPLAIN_FLAG" ] && ! hook_disabled "stop:explain"; then
   153	  gate_budget "explain"
   154	  {
   155	    echo "[완료 차단] change-explainer 미실행 — 변경 설명 없이 끝낼 수 없습니다."
   156	    echo
   157	    echo "이 턴에서 바뀐 코드/설정:"
   158	    sed 's/^/  - /' "$EXPLAIN_FLAG" 2>/dev/null
   159	    echo
   160	    echo "해야 할 일:"
   161	    echo "  1. change-explainer 에이전트로 실제 diff 기반 사용자용 변경 설명을 낸다."
   162	    echo "  2. 설명을 낸 뒤에만:  rm -f .claude/.needs-explain"
   163	    echo "     설명 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   164	    echo
   165	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
   166	  } >&2
   167	  bump_and_block
   168	fi
   169	
   170	# (5) 볼트(second brain) 반영 게이트 — 감사보다 먼저 강제한다 (감사자가 반영 결과를 검증하도록).
   171	#     결정·설계·개발작업이 나온 턴은 볼트 Projects/<name>/ 4종 세트 반영 없이 끝낼 수 없다.
   172	#     (2026-08-02 kty — 산문 Auto-Save 규칙이 세션 내내 0회 이행된 실사고의 기계화)
   173	if [ -s "$VAULT_FLAG" ] && ! hook_disabled "stop:vault"; then
   174	  gate_budget "vault"
   175	  {
   176	    echo "[완료 차단] 볼트(second brain) 반영 미확인 — 지식 반영 없이 끝낼 수 없습니다."
   177	    echo
   178	    echo "이 턴에서 바뀐 코드/설정:"
   179	    sed 's/^/  - /' "$VAULT_FLAG" 2>/dev/null
   180	    echo
   181	    echo "해야 할 일:"
   182	    echo "  1. 볼트 _CLAUDE.md 를 **전문** 읽는다 (부분 독해 금지 — head -N 사고 전례 있음)."
   183	    echo "  2. 이번 턴에 결정·설계·개발작업이 있으면 볼트 Projects/<name>/ 4종 세트"
   184	    echo "     (discussion-log + decisions/ADR + architecture + index)로 반영·커밋하고 해시를 확보한다."
   185	    echo "     raw 산출물(설계 전문 등)은 specs/ 에 보존한다 — raw와 요약 둘 다다."
   186	    echo "  3. 반영할 지식이 없으면(순수 버그픽스·기계적 수정) 불요 사유를 _workspace/progress.md 에 기록한다."
   187	    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-vault"
   188	    echo "     completion-auditor 가 커밋 해시·파일 실존(또는 불요 사유의 타당성)을 검증한다."
   189	    echo
   190	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:vault"
   191	  } >&2
   192	  bump_and_block
   193	fi
   194	
   195	# (6) 타입체크는 통과했지만 감사자가 아직 안 돌았다.
   196	gate_budget "audit"
   197	{
   198	  echo "[완료 차단] completion-auditor 미실행 — '완료'라고 말할 수 없습니다."
   199	  echo
   200	  echo "이 턴에서 바뀐 코드/설정:"
   201	  sed 's/^/  - /' "$AUDIT_FLAG" 2>/dev/null
   202	  if [ -n "$typecheck_note" ]; then
   203	    echo
   204	    echo "참고: $typecheck_note"
   205	  fi
   206	  echo
   207	  echo "해야 할 일:"
   208	  echo "  1. completion-auditor 에이전트로 완료 주장을 1차 증거로 검증한다."
   209	  echo "  2. 검증을 통과했을 때만:  rm -f .claude/.needs-audit"
   210	  echo "     감사 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   211	  echo
   212	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   213	} >&2
   214	bump_and_block
     1	# harness.env — verify-before-stop.sh 가 source 하는 기계 판독 설정.
     2	# install.sh 가 이 템플릿을 프로젝트의 .claude/harness/harness.env 로 복사하고,
     3	# 프로필 §3(검증 명령)에서 값을 채운다. 사람이 직접 채워도 된다.
     4	#
     5	# 규칙: 셸에서 바로 도는 한 줄 명령. 비우면 Stop 훅이 타입체크를 생략한다
     6	#       (타입 없는 언어나 타입체크가 없는 프로젝트).
     7	
     8	# 타입체크 명령 (Stop 훅이 완료 게이트에서 실행). 예:
     9	#   HARNESS_TYPECHECK_CMD="pnpm typecheck"
    10	#   HARNESS_TYPECHECK_CMD="pnpm tsc --noEmit"
    11	#   HARNESS_TYPECHECK_CMD="npm run typecheck"
    12	#   HARNESS_TYPECHECK_CMD="cargo check"
    13	#   HARNESS_TYPECHECK_CMD="go build ./..."
    14	#   HARNESS_TYPECHECK_CMD="mypy ."
    15	HARNESS_TYPECHECK_CMD=""
     1	{
     2	  "hooks": {
     3	    "PreToolUse": [
     4	      {
     5	        "matcher": "Bash",
     6	        "hooks": [
     7	          {
     8	            "type": "command",
     9	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-master-commit.sh\"",
    10	            "timeout": 15
    11	          },
    12	          {
    13	            "type": "command",
    14	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-codex-invocation.sh\"",
    15	            "timeout": 15
    16	          }
    17	        ]
    18	      }
    19	    ],
    20	    "PostToolUse": [
    21	      {
    22	        "matcher": "Edit|Write|MultiEdit",
    23	        "hooks": [
    24	          {
    25	            "type": "command",
    26	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/mark-needs-audit.sh\"",
    27	            "timeout": 15
    28	          }
    29	        ]
    30	      }
    31	    ],
    32	    "Stop": [
    33	      {
    34	        "hooks": [
    35	          {
    36	            "type": "command",
    37	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/verify-before-stop.sh\"",
    38	            "timeout": 120
    39	          }
    40	        ]
    41	      }
    42	    ]
    43	  }
    44	}tests/check-rule-copies.test.sh
tests/mark-needs-audit.cases.sh
tests/mark-needs-audit.test.sh
    70	    case "$stop_active" in
    71	      [Tt]rue) exit 0 ;;
    72	    esac
    73	  fi
    74	  exit 2
    75	}
    76	
    77	# (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
    78	#     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
    79	#     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
    80	typecheck_note=""
    81	if [ -f "$STATE_DIR/harness/harness.env" ]; then
    82	  # shellcheck disable=SC1091
    83	  . "$STATE_DIR/harness/harness.env" 2>/dev/null
    84	fi
    85	TYPECHECK_CMD="${HARNESS_TYPECHECK_CMD:-}"
    86	
    87	if [ -z "$TYPECHECK_CMD" ]; then
    88	  typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"
    89	else
    90	  timeout_bin=""
    91	  if command -v timeout >/dev/null 2>&1; then
    92	    timeout_bin="timeout"
    93	  elif command -v gtimeout >/dev/null 2>&1; then
    94	    timeout_bin="gtimeout"
    95	  fi
    96	  # macOS 기본에는 timeout 이 없다. 그 경우 settings.json 의 "timeout": 120 이 최종 안전망.
    97	
    98	  if [ -n "$timeout_bin" ]; then
    99	    tc_out="$(cd "$PROJECT_DIR" && "$timeout_bin" 90 sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   100	  else
   101	    tc_out="$(cd "$PROJECT_DIR" && sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   102	  fi
   103	
   104	  if [ "$tc_rc" -eq 124 ] || [ "$tc_rc" -eq 137 ]; then
   105	    # 타임아웃은 "타입 오류"가 아니라 "모름". 차단하지 않고 감사자에게 넘긴다.
   106	    typecheck_note="타입체크 타임아웃 → 생략 (감사자가 재확인할 것)"
   107	  elif [ "$tc_rc" -eq 127 ]; then
   108	    # 명령/도구 없음(rc=127)은 "타입 오류"가 아니다. 오탐 차단 방지 위해 생략.
   109	    typecheck_note="타입체크 생략 (명령 실행 불가 rc=127): $TYPECHECK_CMD"
   110	  elif [ "$tc_rc" -ne 0 ]; then
   111	    gate_budget "typecheck"
   112	    {
   113	      echo "[완료 차단] 타입체크 실패 — 지금은 '완료'가 아닙니다."
   114	      echo
   115	      echo "명령: $TYPECHECK_CMD"
   116	      echo
   117	      printf '%s\n' "$tc_out" | head -n 15
   118	      echo
   119	      echo "고친 뒤 다시 종료하세요.  (차단 $((count + 1))/${MAX_BLOCKS})"
   120	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   121	    } >&2
   122	    bump_and_block
   123	  fi
   124	fi
   125	
   126	# (3.5) 듀얼 리뷰(codex) 게이트 (2026-08-03 kty — "리뷰가 필요한 모든 단계를 codex와 같이"의 기계화).
   127	#      설계·계획 산출물이 저장되거나 코드가 바뀐 턴은 codex 독립 리뷰 없이 끝낼 수 없다.
   128	#      Claude 단독 리뷰가 놓친 CRITICAL을 codex가 잡은 실사고(2026-08-03 POK-30)의 재발 방지.
   129	if [ -s "$DUALREVIEW_FLAG" ] && ! hook_disabled "stop:dualreview"; then
   130	  gate_budget "dualreview"

codex
호출 전제는 명확합니다. 설치 설정은 세 훅을 모두 `bash`로 실행하고 각 스크립트도 bash shebang/Bash 전용 `BASH_SOURCE`를 이미 사용하므로 `local`은 새 이식성 회귀가 아닙니다. 반면 파서는 “셸 한 줄 대입”의 일부 문법과 물리적 행 기반 판독 사이에 차이가 있어 그 영향을 검산 중입니다.
exec
/bin/zsh -lc 'bash -n template/.claude/hooks/_common.sh template/.claude/hooks/verify-before-stop.sh; git diff --check 33158e2''^ 33158e2; if command -v shellcheck >/dev/null 2>&1; then shellcheck template/.claude/hooks/_common.sh template/.claude/hooks/verify-before-stop.sh; else echo '"'shellcheck: unavailable'; fi; printf '%s\\n' '--- heredoc/comment/prefix/export matches ---'; printf '%s\\n' 'cat <<EOF' 'HARNESS_TYPECHECK_CMD=true' 'EOF' '# HARNESS_TYPECHECK_CMD=false' 'HARNESS_TYPECHECK_CMD_EXTRA=false' 'export  HARNESS_TYPECHECK_CMD=printf-ok' | grep -nE '"'^(export[[:space:]]+)?HARNESS_TYPECHECK_CMD='"' || :; printf '%s\\n' '--- trailing-comment/CRLF captured bytes ---'; printf '%s\\n' 'HARNESS_TYPECHECK_CMD=\"pnpm tsc\" # note' | grep -E '"'^(export[[:space:]]+)?HARNESS_TYPECHECK_CMD='"' | od -An -tx1c; printf 'HARNESS_TYPECHECK_CMD=\"pnpm tsc\"\\r\\n' | grep -E '"'^(export[[:space:]]+)?HARNESS_TYPECHECK_CMD='"' | od -An -tx1c; printf '%s\\n' '--- multiline match count/content ---'; printf '%s\\n' 'HARNESS_TYPECHECK_CMD=\"pnpm \\' 'tsc\"' | grep -nE '"'^(export[[:space:]]+)?HARNESS_TYPECHECK_CMD='"' || :; printf '%s\\n' '--- metachar key broadens regex ---'; printf '%s\\n' 'HARNESS_TYPECHECK_CMD=x' 'HARNESSXTYPECHECK_CMD=y' | grep -nE '"'^(export[[:space:]]+)?HARNESS.TYPECHECK_CMD='"' || :" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
shellcheck: unavailable
--- heredoc/comment/prefix/export matches ---
2:HARNESS_TYPECHECK_CMD=true
6:export  HARNESS_TYPECHECK_CMD=printf-ok
--- trailing-comment/CRLF captured bytes ---
           48  41  52  4e  45  53  53  5f  54  59  50  45  43  48  45  43
           H   A   R   N   E   S   S   _   T   Y   P   E   C   H   E   C
           4b  5f  43  4d  44  3d  22  70  6e  70  6d  20  74  73  63  22
           K   _   C   M   D   =   "   p   n   p   m       t   s   c   "
           20  23  20  6e  6f  74  65  0a                                
               #       n   o   t   e  \n                                

           48  41  52  4e  45  53  53  5f  54  59  50  45  43  48  45  43
           H   A   R   N   E   S   S   _   T   Y   P   E   C   H   E   C
           4b  5f  43  4d  44  3d  22  70  6e  70  6d  20  74  73  63  22
           K   _   C   M   D   =   "   p   n   p   m       t   s   c   "
           0d  0a                                                        
          \r  \n                                                        

--- multiline match count/content ---
1:HARNESS_TYPECHECK_CMD="pnpm \
--- metachar key broadens regex ---
1:HARNESS_TYPECHECK_CMD=x
2:HARNESSXTYPECHECK_CMD=y

exec
/bin/zsh -lc "bash -c 'printf \"hook shell=%s parent=%s\\n\" \""'$$" "$PPID"; out="$(cd . && sh -c '"'\\''printf \"typecheck shell=%s parent=%s\\\\n\" \""'$$" "$PPID"'"'\\'')\"; printf \"%s\\n\" \""'$out"'"' && dash -c 'printf \"dash wrapper=%s parent=%s\\n\" \""'$$" "$PPID"'"' 2>/dev/null || :" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
hook shell=16245 parent=16244
typecheck shell=16247 parent=16246
dash wrapper=16248 parent=16244

codex
검산 결과, 접두사 키와 `#`로 시작하는 일반 주석은 매치되지 않고 `export` 뒤의 여러 공백/탭은 정상 매치됩니다. 다만 히어독 본문은 실제 선언이 아닌데도 매치되고, 유효한 `KEY="..." # 주석`은 따옴표를 벗기지 못해 `rc=127` 생략 경로로 빠질 수 있습니다. 이 둘은 판정에 반영할 실질 회귀입니다.
exec
/bin/zsh -lc "bash -c 'HARNESS_TYPECHECK_CMD=\"printf ok\" # note
printf \"source-value=<%s> output=<\" \""'$HARNESS_TYPECHECK_CMD"; sh -c "$HARNESS_TYPECHECK_CMD"; printf "> rc=%s'"\\n\" \""'$?"'"'; bash -c 'val='\\''\"printf ok\" # note'\\''; case \""'$val" in '"\\\"*\\\") val=\""'${val#'"\\\"}\"; val=\""'${val%'"\\\"}\" ;; \\'\\''*\\'\\'') val=\""'${val#'"\\'}\"; val=\""'${val%'"\\'}\" ;; esac; printf \"parser-value=<%s> output=<\" \""'$val"; sh -c "$val" 2>/dev/null; rc=$?; printf "> rc=%s'"\\n\" \""'$rc"'"'; git patch-id --stable < _workspace/03_impl_r1.diff; git show --pretty=format: 33158e2 | git patch-id --stable; git status --short" in /Users/kty/Downloads/kty-claude-harness-template
 exited 1 in 0ms:
zsh:2: unmatched "

exec
/bin/zsh -lc "bash -c 'HARNESS_TYPECHECK_CMD=\"printf ok\" # note
printf \"source-value=<%s> output=<\" \""'$HARNESS_TYPECHECK_CMD"
sh -c "$HARNESS_TYPECHECK_CMD"
printf "> rc=%s'"\\n\" \""'$?"'"'
bash -c 'sh -c '\\''\"printf ok\" # note'\\'' 2>/dev/null
rc="'$?
printf "raw-parser output rc=%s'"\\n\" \""'$rc"'"'
git patch-id --stable < _workspace/03_impl_r1.diff
git show --pretty=format: 33158e2 | git patch-id --stable
git status --short" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
source-value=<printf ok> output=<ok> rc=0
raw-parser output rc=127
81492fc2500dd2f5134ca0a34f181574df0975c3 33158e2c4cb95b2063e6ebb07cdb68ebad32597e
81492fc2500dd2f5134ca0a34f181574df0975c3 0000000000000000000000000000000000000000
?? _workspace/

codex
검수 결과 CRITICAL/HIGH는 없지만, 타입체크 판독 회귀 때문에 보류가 필요합니다.

- [MEDIUM] `template/.claude/hooks/_common.sh:58` — 물리적 행 `grep`은 최상위 선언과 히어독·여러 줄 문자열 본문을 구별하지 못합니다. 예를 들어 실제 선언이 `HARNESS_TYPECHECK_CMD="false"`인데 뒤쪽 히어독 본문에 `HARNESS_TYPECHECK_CMD=true`가 있으면 2개 선언으로 오인해 빈 값을 반환하고 타입체크를 생략합니다. “최상위 대입만 센다”는 판독 모델과 불일치합니다.

- [MEDIUM] `template/.claude/hooks/_common.sh:64` — 유효한 셸 대입의 후행 공백·주석을 처리하지 못합니다. `HARNESS_TYPECHECK_CMD="printf ok" # note`는 기존에는 `printf ok`였지만, 새 코드는 전체를 `"printf ok" # note`로 반환합니다. 이후 `sh -c`가 `printf ok` 전체를 명령 이름으로 해석해 rc=127이 되고 `verify-before-stop.sh:106`에서 타입체크를 조용히 생략합니다. 직접 표현식 평가에서도 기존 rc=0, 새 판독값 rc=127을 확인했습니다.

- [LOW] `template/.claude/harness/harness.env.template:1` — 아직 “source 하는 설정”이라고 안내합니다. 사용자는 일반 셸 문법인 후행 주석, `export -x`, 여러 줄 값, 이스케이프를 쓸 수 있다고 오해하지만 새 판독기는 제한된 독자 문법입니다. 지원 문법과 CRLF/BOM 정책까지 문서화해야 합니다.

- [MEDIUM] `template/.claude/hooks/_common.sh:54` — 보안 목적의 새 파서와 Stop 훅에 회귀 테스트가 없습니다. 위 두 실패가 현재 그대로 검출되지 않습니다.

경계 사례 판단:

- 일반 주석행과 `HARNESS_TYPECHECK_CMD_EXTRA`는 매치되지 않습니다.
- `export KEY=`, 여러 공백 및 탭 변형은 매치됩니다. `export -x`, `declare`, `readonly`는 지원하지 않습니다.
- 여러 줄 값은 첫 물리 행만 읽으므로 정상 지원되지 않습니다.
- CRLF는 `\r`이 값에 남고, BOM이 첫 키 앞에 있으면 무매치입니다.
- `$key`의 ERE 메타문자는 실제로 정규식을 확장하지만 현재 호출은 고정된 유효 셸 식별자뿐이어서 현행 취약 경로는 아닙니다. 공용 API로 확장할 계획이면 식별자 검증이 적절합니다.
- grep rc≥2 처리는 타입체크 관점에서는 fail-open, 훅 가용성 관점에서는 fail-safe입니다. 파일이 사용자 소유이고 빈 값 자체가 공식 생략 수단이며 나머지 4개 게이트는 계속 실행되므로 현 위협 모델에는 fail-open이 타당합니다. 다만 “미설정”과 “읽기 실패”는 구별해 경고하는 편이 좋습니다.
- `local`은 문제없습니다. 모든 소비 훅은 bash shebang이며 `settings.json`도 명시적으로 bash로 실행합니다.
- 정상 한 줄 값의 빈 값 생략과 timeout 실행 흐름은 유지됩니다. 저장소 전체에서 다른 실제 `harness.env` 키 소비자는 발견되지 않았습니다.
- 제공 diff의 patch-id는 커밋 `33158e2`와 일치했고 `bash -n`, `git diff --check`는 통과했습니다.

반드시 필요한 테스트는 정상 quoted/unquoted 값, `export` 공백·탭, 0/1/2개 선언, 들여쓰기, 접두사 키, 일반·후행 주석, 히어독, 여러 줄 값, 따옴표·백슬래시, literal `$`, CRLF/BOM, 읽기 오류, 그리고 `exit 0/1`·`return`·`printf` 재정의가 나머지 게이트를 종료시키지 않는 통합 사례입니다.

판정: 보류
tokens used
57,538
검수 결과 CRITICAL/HIGH는 없지만, 타입체크 판독 회귀 때문에 보류가 필요합니다.

- [MEDIUM] `template/.claude/hooks/_common.sh:58` — 물리적 행 `grep`은 최상위 선언과 히어독·여러 줄 문자열 본문을 구별하지 못합니다. 예를 들어 실제 선언이 `HARNESS_TYPECHECK_CMD="false"`인데 뒤쪽 히어독 본문에 `HARNESS_TYPECHECK_CMD=true`가 있으면 2개 선언으로 오인해 빈 값을 반환하고 타입체크를 생략합니다. “최상위 대입만 센다”는 판독 모델과 불일치합니다.

- [MEDIUM] `template/.claude/hooks/_common.sh:64` — 유효한 셸 대입의 후행 공백·주석을 처리하지 못합니다. `HARNESS_TYPECHECK_CMD="printf ok" # note`는 기존에는 `printf ok`였지만, 새 코드는 전체를 `"printf ok" # note`로 반환합니다. 이후 `sh -c`가 `printf ok` 전체를 명령 이름으로 해석해 rc=127이 되고 `verify-before-stop.sh:106`에서 타입체크를 조용히 생략합니다. 직접 표현식 평가에서도 기존 rc=0, 새 판독값 rc=127을 확인했습니다.

- [LOW] `template/.claude/harness/harness.env.template:1` — 아직 “source 하는 설정”이라고 안내합니다. 사용자는 일반 셸 문법인 후행 주석, `export -x`, 여러 줄 값, 이스케이프를 쓸 수 있다고 오해하지만 새 판독기는 제한된 독자 문법입니다. 지원 문법과 CRLF/BOM 정책까지 문서화해야 합니다.

- [MEDIUM] `template/.claude/hooks/_common.sh:54` — 보안 목적의 새 파서와 Stop 훅에 회귀 테스트가 없습니다. 위 두 실패가 현재 그대로 검출되지 않습니다.

경계 사례 판단:

- 일반 주석행과 `HARNESS_TYPECHECK_CMD_EXTRA`는 매치되지 않습니다.
- `export KEY=`, 여러 공백 및 탭 변형은 매치됩니다. `export -x`, `declare`, `readonly`는 지원하지 않습니다.
- 여러 줄 값은 첫 물리 행만 읽으므로 정상 지원되지 않습니다.
- CRLF는 `\r`이 값에 남고, BOM이 첫 키 앞에 있으면 무매치입니다.
- `$key`의 ERE 메타문자는 실제로 정규식을 확장하지만 현재 호출은 고정된 유효 셸 식별자뿐이어서 현행 취약 경로는 아닙니다. 공용 API로 확장할 계획이면 식별자 검증이 적절합니다.
- grep rc≥2 처리는 타입체크 관점에서는 fail-open, 훅 가용성 관점에서는 fail-safe입니다. 파일이 사용자 소유이고 빈 값 자체가 공식 생략 수단이며 나머지 4개 게이트는 계속 실행되므로 현 위협 모델에는 fail-open이 타당합니다. 다만 “미설정”과 “읽기 실패”는 구별해 경고하는 편이 좋습니다.
- `local`은 문제없습니다. 모든 소비 훅은 bash shebang이며 `settings.json`도 명시적으로 bash로 실행합니다.
- 정상 한 줄 값의 빈 값 생략과 timeout 실행 흐름은 유지됩니다. 저장소 전체에서 다른 실제 `harness.env` 키 소비자는 발견되지 않았습니다.
- 제공 diff의 patch-id는 커밋 `33158e2`와 일치했고 `bash -n`, `git diff --check`는 통과했습니다.

반드시 필요한 테스트는 정상 quoted/unquoted 값, `export` 공백·탭, 0/1/2개 선언, 들여쓰기, 접두사 키, 일반·후행 주석, 히어독, 여러 줄 값, 따옴표·백슬래시, literal `$`, CRLF/BOM, 읽기 오류, 그리고 `exit 0/1`·`return`·`printf` 재정의가 나머지 게이트를 종료시키지 않는 통합 사례입니다.

판정: 보류
