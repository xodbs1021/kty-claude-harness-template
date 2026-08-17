Reading additional input from stdin...
2026-08-10T03:47:16.904121Z ERROR codex_models_manager::cache: failed to load models cache: missing field `supports_reasoning_summaries` at line 93 column 5
OpenAI Codex v0.144.5
--------
workdir: /Users/kty/Downloads/kty-claude-harness-template
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019fe9c8-2afb-7b51-aa48-056d9193a187
--------
user
# 코드 검수 — 하네스 층 경계 이행 (ADR-0006/0008/0009/0010)

`_workspace/04_review.diff` 가 이번 변경 전체다(origin/main 5ce8597 → HEAD).

## 반드시 지킬 것
- **파일을 만들거나 지우지 마라.** `mktemp`·`rm`·`>` 리다이렉트 금지. 샌드박스가 거부해
  판정 없이 끝난 전례가 있다. **정적 독해로만** 판정하고 **반드시 판정 줄을 내라.**
- 마지막 줄에 정확히 이 형식: `판정: 통과` 또는 `판정: 보류`
- 지적은 `[등급] 파일:줄 — 무엇이 언제 어떻게 틀리는가` 형식. 등급은 CRITICAL/HIGH/MEDIUM/LOW.
  재현 조건(입력·상태)을 반드시 쓰고, 추측이면 추측이라고 밝혀라.

## 무엇을 바꿨나
1. `template/.claude/hooks/_common.sh` — `harness_env_value()` 를 awk 판독기로 재작성.
   `harness.env` 를 실행하지 않고 원문으로 읽는다. 반환 계약: rc=0 = 선언 1개를 지원
   문법으로 판독(값은 빈 문자열일 수 있다) / rc=1 = 값을 믿을 수 없음(파일 없음·읽기
   실패·선언 0개·2개 이상·문법 밖). `harness_knowledge_gate_on()`·`knowledge_gate_active()` 신설.
2. `verify-before-stop.sh` — 플래그 `.needs-vault` → `.needs-knowledge`, 게이트 메시지에서
   상위 층 구현 제거, 타입체크 생략 사유를 rc 로 구별.
3. `mark-needs-audit.sh` — `classify()` 에 `knowledge` 판정 추가(`docs/decisions/*.md`),
   설계·계획 산출물이 듀얼리뷰 + 지식 게이트를 함께 세움.
4. `install.sh` — 훅 교체를 파일 단위 cp 에서 **디렉터리 rename 스왑 2회**로. 신호 핸들러
   INT/TERM/QUIT/HUP, 핸들러 진입 직후 `set +e`, 백업은 `mktemp -d`, 중첩이 계약.
   훅 디렉터리가 심링크면 스왑을 포기하고 파일 복사로 물러서며 알린다.
5. `sync.sh` — 키 없는 설치본에 `HARNESS_KNOWLEDGE_GATE="on"` 을 **append 만** 한다.
6. `scripts/check-layer-boundary.sh` 신설 + CI.
7. 테스트 4종 신설·확장, ADR 3건 신설 + 1건 accepted 전이.

## 특히 봐 달라
- **awk 판독기의 위음성.** 지원 문법 밖인데 rc=0 을 내는 입력이 있나? 히어독 탐지가
  실제 셸과 갈리는 지점은? `LC_ALL=C` 와 BOM 3바이트 절단이 mawk/gawk/BSD awk 에서
  다르게 도나? awk 가 없는 환경은?
- **게이트가 꺼지는 방향의 실패.** 어떤 입력이 `harness_knowledge_gate_on` 을 rc=1(꺼짐)로
  만들 수 있나. 설계상 "리터럴로 빈 값" 하나뿐이어야 한다.
- **rename 스왑의 남은 창.** 신호 핸들러 자신이 죽으면? `hooks_swapped` 플래그와 실제
  파일시스템 상태가 어긋나는 순서가 있나? `trap - ` 시점은 옳은가?
- **sync.sh 의 append.** 원자적이지 않다고 공시했는데, 그 실패가 정말 안전한 방향인가?
  `grep -qE '^HARNESS_KNOWLEDGE_GATE='` 검증이 append 실패를 잡는가?
- **테스트의 위음성.** 통과만 하고 아무것도 안 잡는 케이스가 있나? 픽스처가 겨누는 결함을
  가려버리는 곳은? `install-hook-swap.test.sh` 의 mv shim 이 rc 를 삼키는 곳은 없나?
- **계약 위반.** "슬롯은 프로젝트 소유, 절대 안 덮음" 을 어디선가 어기나?
  사용자 파일을 지울 수 있는 경로가 있나?
- 문서가 **검증된 범위보다 강하게** 약속하는 곳(거짓 공시)이 있나?
codex
요청하신 범위만 정적 검수하겠습니다. 우선 저장소 지침과 `04_review.diff`를 읽고, 이후 awk 계약·게이트 fail-open·rename 스왑·sync append·테스트 위음성·문서 공시를 실제 줄 번호에 맞춰 교차검증하겠습니다. 파일 생성·삭제나 테스트 실행은 하지 않겠습니다.
exec
/bin/zsh -lc "pwd && rg --files -g 'AGENTS.md' -g '_workspace/04_review.diff' -g 'template/.claude/hooks/**' -g 'install.sh' -g 'sync.sh' -g 'scripts/check-layer-boundary.sh' -g '*test.sh' -g 'docs/decisions/*.md'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
/Users/kty/Downloads/kty-claude-harness-template
scripts/check-layer-boundary.sh
_workspace/04_review.diff
sync.sh
docs/decisions/2026-07-20-global-agents-layer.md
docs/decisions/2026-08-05-marker-contract-split.md
docs/decisions/2026-08-06-profile-canon-upstream.md
docs/decisions/2026-08-06-knowledge-gate-default-on.md
docs/decisions/2026-08-05-commit-split-rationale.md
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md
docs/decisions/2026-08-06-knowledge-retrieval-policy.md
docs/decisions/2026-08-05-reject-unscannable-targets.md
docs/decisions/2026-08-06-gate-scope-by-file-identity.md
docs/decisions/2026-07-18-memory-tiers-and-adr-process.md
tests/mark-needs-audit.test.sh
tests/check-rule-copies.test.sh
tests/check-layer-boundary.test.sh
tests/install-hook-swap.test.sh
tests/harness-env-read.test.sh
install.sh

exec
/bin/zsh -lc "wc -l _workspace/04_review.diff && sed -n '1,260p' _workspace/04_review.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
    3950 _workspace/04_review.diff
diff --git a/.github/workflows/check-rules.yml b/.github/workflows/check-rules.yml
index ddabdb1..c219e47 100644
--- a/.github/workflows/check-rules.yml
+++ b/.github/workflows/check-rules.yml
@@ -24,5 +24,19 @@ jobs:
         run: ./tests/check-rule-copies.test.sh
       - name: 완료 게이트 검사 범위 회귀 테스트
         run: ./tests/mark-needs-audit.test.sh
+      # harness.env 를 실행하지 않고 원문으로 읽는 파서의 회귀 방어.
+      # 여기가 조용히 틀리면 값에 쓰레기가 섞여 rc=127 이 되고 타입체크 게이트가 사라진다.
+      - name: harness.env 원문 판독 회귀 테스트
+        run: ./tests/harness-env-read.test.sh
+      - name: 층 경계 검사기 회귀 테스트
+        run: ./tests/check-layer-boundary.test.sh
+      # 훅 교체 도중 중단되면 구판으로 되돌아가는가. 이 축의 실패는 "설치 성공"이라는
+      # 거짓 보고로 나오므로 rc 만이 아니라 파일 상태·잔류물·문구까지 잰다.
+      - name: 훅 교체 원자성 회귀 테스트
+        run: ./tests/install-hook-swap.test.sh
       - name: 규칙 사본 동기화 검사
         run: ./scripts/check-rule-copies.sh
+      # 층 경계 검사는 사본 대조 **뒤**다. 앞선 단계가 세운 신뢰 전제(범위·심링크·NUL)를
+      # 그대로 이어받는다 — 적힌 결합이다.
+      - name: 층 경계 검사 (글루에 상위 층 구현이 샜나)
+        run: ./scripts/check-layer-boundary.sh
diff --git a/_workspace/03_impl_r1.diff b/_workspace/03_impl_r1.diff
new file mode 100644
index 0000000..92203fc
--- /dev/null
+++ b/_workspace/03_impl_r1.diff
@@ -0,0 +1,100 @@
+commit 33158e2c4cb95b2063e6ebb07cdb68ebad32597e
+Author: 김태윤 <xodbs9810@gmail.com>
+Date:   Mon Aug 10 11:04:33 2026 +0900
+
+    fix: harness.env 를 실행하지 않고 원문으로 읽는다
+    
+    harness.env 는 **사용자 소유 셸 파일**인데 Stop 훅이 그걸 source 해서 값을 읽었다.
+    그러면 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가
+    나온다. 실측된 것들:
+    
+      exit 1        훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
+      exit 0        훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
+      서브셸+return 호출 셸로 정상 복귀해 판정을 통과
+      printf 재정의 진단 출력 자체를 위조
+    
+    서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. 실행하지 않으면 이 부류가
+    **원리적으로** 소멸한다 — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는
+    것이고, 그게 정확히 의도적으로 값을 바꾸는 방법이다.
+    
+    _common.sh 에 harness_env_value() 신설. 판독 모델:
+    - 선행 공백 없는 최상위 대입만 선언으로 센다(조건문·함수 본문 안은 실행 여부를
+      원문만으로 알 수 없다)
+    - 선언이 2개 이상이면 어느 것이 이기는지 모르므로 빈 값을 돌려준다(미설정 취급)
+    - 감싼 따옴표 한 겹만 벗긴다
+    
+    대가(공시): 값 안의 $VAR·$(...) 가 확장되지 않는다. 확장이 필요하면 최종 문자열을
+    그 자리에 적어야 한다.
+    
+    실측: 정상=[pnpm tsc --noEmit] · exit 1 포함=[pnpm tsc] · exit 0 포함=[pnpm tsc] ·
+    들여쓴 위장 선언=[진짜](최상위만 셈) · 선언 2개=[](미설정)
+
+diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
+index d052cd3..aa96a4d 100644
+--- a/template/.claude/hooks/_common.sh
++++ b/template/.claude/hooks/_common.sh
+@@ -31,6 +31,43 @@ hook_disabled() {
+   return 1
+ }
+ 
++# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
++#
++# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
++# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
++# 전부 실측된 것들이다:
++#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
++#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
++#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
++#   printf 재정의 → 진단 출력 자체를 위조
++# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
++# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
++# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
++#
++# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
++# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
++# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 **빈 값을 돌려준다**
++# (호출부가 "미설정"으로 안전하게 처리하도록).
++#
++# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **확장되지 않는다.** 실행하지 않는 대가다.
++# 확장이 필요하면 그 자리에 최종 문자열을 적어야 한다.
++harness_env_value() {
++  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
++  [ -f "$file" ] || { printf '%s' ''; return 0; }
++  # 선행 공백 없는 `KEY=` 또는 `export KEY=` 만. grep rc 는 삼킨다(무매치·오류 모두 미설정).
++  lines="$(grep -E "^(export[[:space:]]+)?${key}=" "$file" 2>/dev/null)" || lines=''
++  [ -n "$lines" ] || { printf '%s' ''; return 0; }
++  n="$(printf '%s\n' "$lines" | wc -l | tr -d ' ')"
++  [ "$n" = "1" ] || { printf '%s' ''; return 0; }
++  val="${lines#*=}"
++  # 감싼 따옴표 한 겹만 벗긴다(양쪽이 짝일 때만).
++  case "$val" in
++    \"*\") val="${val#\"}"; val="${val%\"}" ;;
++    \'*\') val="${val#\'}"; val="${val%\'}" ;;
++  esac
++  printf '%s' "$val"
++}
++
+ # stdin 의 JSON 에서 점 경로로 값 하나를 뽑는다. 없거나 파싱 실패면 빈 문자열.
+ # 훅 입력이 깨져도 절대 죽지 않는다 — 죽으면 오탐 차단이 된다.
+ json_get() {
+diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
+index 93c23e2..cbb4bf3 100644
+--- a/template/.claude/hooks/verify-before-stop.sh
++++ b/template/.claude/hooks/verify-before-stop.sh
+@@ -77,12 +77,11 @@ bump_and_block() {
+ # (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
+ #     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
+ #     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
++#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
++#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
++#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
+ typecheck_note=""
+-if [ -f "$STATE_DIR/harness/harness.env" ]; then
+-  # shellcheck disable=SC1091
+-  . "$STATE_DIR/harness/harness.env" 2>/dev/null
+-fi
+-TYPECHECK_CMD="${HARNESS_TYPECHECK_CMD:-}"
++TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"
+ 
+ if [ -z "$TYPECHECK_CMD" ]; then
+   typecheck_note="타입체크 생략 (harness.env 에 HARNESS_TYPECHECK_CMD 미설정)"
diff --git a/_workspace/03_impl_r1_codex.md b/_workspace/03_impl_r1_codex.md
new file mode 100644
index 0000000..977c081
--- /dev/null
+++ b/_workspace/03_impl_r1_codex.md
@@ -0,0 +1,1141 @@
+Reading additional input from stdin...
+2026-08-10T02:05:38.580560Z ERROR codex_models_manager::cache: failed to load models cache: missing field `supports_reasoning_summaries` at line 93 column 5
+OpenAI Codex v0.144.5
+--------
+workdir: /Users/kty/Downloads/kty-claude-harness-template
+model: gpt-5.6-sol
+provider: openai
+approval: never
+sandbox: read-only
+reasoning effort: high
+reasoning summaries: none
+session id: 019fe96b-1d0e-76a2-b484-150e17305a3b
+--------
+user
+확정 커밋 33158e2 하나를 독립 검수한다. diff 는 _workspace/03_impl_r1.diff.
+
+**제약: 파일 생성·삭제·수정 금지. mktemp·rm·mkdir 금지.** 정적 독해와 부작용 없는 셸 표현식 평가만. **반드시 마지막에 '판정: 통과' 또는 '판정: 보류' 줄을 내라.**
+
+## 맥락
+
+Stop 훅이 harness.env(사용자 소유 셸 파일)를 `source` 해서 설정값을 읽고 있었다. 그러면 그 파일 내용이 훅의 제어 흐름을 가져간다 — exit 1 이면 훅이 죽어 게이트 4종이 소멸하고, exit 0 이면 조용히 소멸한다(흔적 0). 서브셸·리다이렉트로 막아도 return·printf 재정의로 새 경로가 계속 나왔다.
+
+이 커밋은 **실행을 버리고 원문 grep 판독**으로 바꿨다. _common.sh 에 harness_env_value() 신설, verify-before-stop.sh 가 그것을 쓴다.
+
+판독 모델: 선행 공백 없는 최상위 대입만 선언으로 센다 / 선언이 정확히 1개일 때만 값을 믿고 2개 이상이면 빈 값(미설정) / 감싼 따옴표 한 겹만 벗긴다.
+
+오케스트레이터 실측: 정상=[pnpm tsc --noEmit] · exit 1 포함=[pnpm tsc] · exit 0 포함=[pnpm tsc] · 들여쓴 위장 선언=[진짜] · 선언 2개=[]
+
+## 중점적으로 봐라
+
+1. **판독을 우회하는 경로가 남았는가.** 특히: 히어독 안의 그 키 / 주석 안 / 여러 줄 값 / `KEY=값 # 주석` 의 후행 주석 / 값에 개행이 들어간 경우 / `export` 변형 / CRLF 줄끝 / BOM / 키 이름이 다른 키의 접두사인 경우(HARNESS_TYPECHECK_CMD 와 HARNESS_TYPECHECK_CMD_EXTRA)
+2. **grep 정규식에 $key 를 그대로 끼워 넣는다.** 호출부가 상수만 넘기지만, 메타문자가 들어오면 어떻게 되는가. 방어가 필요한가
+3. **rc 처리.** grep 의 rc 2 이상(파일 읽기 실패 등)을 무매치와 같이 삼킨다 — 이게 fail-open 인가 fail-safe 인가. 이 훅의 위협 모델에서 어느 쪽이 옳은가
+4. **local 사용.** _common.sh 는 bash 전제인가 POSIX sh 전제인가. 다른 훅들이 어떻게 부르는지 보고 판단해라
+5. **회귀.** TYPECHECK_CMD 를 쓰던 기존 동작(빈 값이면 생략, timeout 실행)이 그대로인가. source 를 없애면서 **다른 변수도 같이 사라졌는가** — harness.env 의 다른 키를 쓰던 곳이 있는지 저장소 전체를 확인해라
+6. **회귀 테스트가 없다.** 이 커밋에 테스트가 0건이다. 어떤 케이스가 반드시 있어야 하는가
+
+지적은 [CRITICAL]/[HIGH]/[MEDIUM]/[LOW] + 파일:줄 + 구체적 실패 시나리오. 추측이면 추측이라고 적어라. **지적이 없으면 없다고 해라.**
+codex
+요청하신 제약을 그대로 지켜, 파일을 건드리지 않고 커밋·제공 diff·호출 경로·셸 전제를 정적으로 대조하겠습니다. 우선 작업 트리 상태와 관련 파일 전체를 읽은 뒤, 안전한 문자열/셸 표현식만 별도로 검산하겠습니다.
+exec
+/bin/zsh -lc 'pwd && git status --short && git show --stat --oneline --decorate --no-renames 33158e2 && git diff --no-ext-diff --unified=80 33158e2''^ 33158e2 -- && sed -n '"'1,260p' _workspace/03_impl_r1.diff" in /Users/kty/Downloads/kty-claude-harness-template
+ succeeded in 0ms:
+/Users/kty/Downloads/kty-claude-harness-template
+?? _workspace/
+33158e2 (HEAD -> refactor/knowledge-store-layer) fix: harness.env 를 실행하지 않고 원문으로 읽는다
+ template/.claude/hooks/_common.sh            | 37 ++++++++++++++++++++++++++++
+ template/.claude/hooks/verify-before-stop.sh |  9 +++----
+ 2 files changed, 41 insertions(+), 5 deletions(-)
+diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
+index d052cd3..aa96a4d 100644
+--- a/template/.claude/hooks/_common.sh
++++ b/template/.claude/hooks/_common.sh
+@@ -1,51 +1,88 @@
+ #!/usr/bin/env bash
+ # 하네스 훅 공용 모듈. 각 훅 스크립트가 source 한다. (도메인-무관 재사용 템플릿)
+ #
+ # set -e 를 쓰지 않는다: 훅이 예기치 않게 죽으면 세션이 막히거나(Stop)
+ # 멀쩡한 명령이 차단된다(PreToolUse). 모든 종료는 명시적으로 한다.
+ 
+ PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
+ STATE_DIR="$PROJECT_DIR/.claude"
+ AUDIT_FLAG="$STATE_DIR/.needs-audit"
+ EXPLAIN_FLAG="$STATE_DIR/.needs-explain"
+ VAULT_FLAG="$STATE_DIR/.needs-vault"
+ DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
+ BLOCK_COUNT="$STATE_DIR/.stop-block-count"
+ BLOCK_FP="$STATE_DIR/.stop-block-fp"    # 마지막 차단 지문(게이트|플래그 상태) — 진전 인지 리셋용
+ 
+ # Stop 훅이 "같은 지점에서 진전 없이" 최대 몇 번까지 막을 수 있는가. 소진되면 통과시킨다
+ # (세션 벽돌 방지). 차단 지문이 바뀌면(=게이트를 하나 지웠으면) 카운터는 리셋되므로,
+ # 게이트 개수가 늘어도 이 상수를 올릴 필요가 없다.
+ MAX_BLOCKS=3
+ 
+ # 탈출구.
+ #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
+ #   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
+ hook_disabled() {
+   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
+     return 0
+   fi
+   case ",${ECC_DISABLED_HOOKS:-}," in
+     *",$1,"*) return 0 ;;
+   esac
+   return 1
+ }
+ 
++# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
++#
++# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
++# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
++# 전부 실측된 것들이다:
++#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
++#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
++#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
++#   printf 재정의 → 진단 출력 자체를 위조
++# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
++# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
++# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
++#
++# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
++# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
++# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 **빈 값을 돌려준다**
++# (호출부가 "미설정"으로 안전하게 처리하도록).
++#
++# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **확장되지 않는다.** 실행하지 않는 대가다.
++# 확장이 필요하면 그 자리에 최종 문자열을 적어야 한다.
++harness_env_value() {
++  local file="$STATE_DIR/harness/harness.env" key="$1" lines n val
++  [ -f "$file" ] || { printf '%s' ''; return 0; }
++  # 선행 공백 없는 `KEY=` 또는 `export KEY=` 만. grep rc 는 삼킨다(무매치·오류 모두 미설정).
++  lines="$(grep -E "^(export[[:space:]]+)?${key}=" "$file" 2>/dev/null)" || lines=''
++  [ -n "$lines" ] || { printf '%s' ''; return 0; }
++  n="$(printf '%s\n' "$lines" | wc -l | tr -d ' ')"
++  [ "$n" = "1" ] || { printf '%s' ''; return 0; }
++  val="${lines#*=}"
++  # 감싼 따옴표 한 겹만 벗긴다(양쪽이 짝일 때만).
++  case "$val" in
++    \"*\") val="${val#\"}"; val="${val%\"}" ;;
++    \'*\') val="${val#\'}"; val="${val%\'}" ;;
++  esac
++  printf '%s' "$val"
++}
++

exec
/bin/zsh -lc "rg -n '"'^diff --git '"' _workspace/04_review.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
1:diff --git a/.github/workflows/check-rules.yml b/.github/workflows/check-rules.yml
25:diff --git a/_workspace/03_impl_r1.diff b/_workspace/03_impl_r1.diff
131:diff --git a/_workspace/03_impl_r1_codex.md b/_workspace/03_impl_r1_codex.md
1278:diff --git a/_workspace/mutate-harness-env.sh b/_workspace/mutate-harness-env.sh
1483:diff --git a/_workspace/mutation-harness-env-2026-08-10.txt b/_workspace/mutation-harness-env-2026-08-10.txt
1545:diff --git a/_workspace/progress.md b/_workspace/progress.md
1645:diff --git a/docs/decisions/2026-08-05-knowledge-store-layer-boundary.md b/docs/decisions/2026-08-05-knowledge-store-layer-boundary.md
1683:diff --git a/docs/decisions/2026-08-06-knowledge-gate-default-on.md b/docs/decisions/2026-08-06-knowledge-gate-default-on.md
1810:diff --git a/docs/decisions/2026-08-06-knowledge-retrieval-policy.md b/docs/decisions/2026-08-06-knowledge-retrieval-policy.md
1886:diff --git a/docs/decisions/2026-08-06-profile-canon-upstream.md b/docs/decisions/2026-08-06-profile-canon-upstream.md
1965:diff --git a/docs/usage.md b/docs/usage.md
2005:diff --git a/install.sh b/install.sh
2104:diff --git a/scripts/check-layer-boundary.sh b/scripts/check-layer-boundary.sh
2256:diff --git a/sync.sh b/sync.sh
2308:diff --git a/template/.claude/harness/harness.env.template b/template/.claude/harness/harness.env.template
2375:diff --git a/template/.claude/harness/project-profile.template.md b/template/.claude/harness/project-profile.template.md
2409:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
2630:diff --git a/template/.claude/hooks/mark-needs-audit.sh b/template/.claude/hooks/mark-needs-audit.sh
2709:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
2821:diff --git a/template/.claude/skills/harness-orchestrator/SKILL.md b/template/.claude/skills/harness-orchestrator/SKILL.md
2875:diff --git a/template/CLAUDE.md.snippet b/template/CLAUDE.md.snippet
2890:diff --git a/tests/check-layer-boundary.test.sh b/tests/check-layer-boundary.test.sh
3100:diff --git a/tests/harness-env-read.test.sh b/tests/harness-env-read.test.sh
3537:diff --git a/tests/install-hook-swap.test.sh b/tests/install-hook-swap.test.sh
3778:diff --git a/tests/mark-needs-audit.cases.sh b/tests/mark-needs-audit.cases.sh
3913:diff --git a/tests/mark-needs-audit.test.sh b/tests/mark-needs-audit.test.sh

exec
/bin/zsh -lc "nl -ba template/.claude/hooks/_common.sh | sed -n '1,260p'
nl -ba template/.claude/hooks/verify-before-stop.sh | sed -n '1,280p'
nl -ba template/.claude/hooks/mark-needs-audit.sh | sed -n '1,260p'" in /Users/kty/Downloads/kty-claude-harness-template
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
    11	# 지식 저장소 반영 게이트. 이름은 **계약 수준**이다 — 예전 이름은 특정 구현체를 가리켰고,
    12	# 그래서 그 구현체를 안 쓰는 환경에서 하네스가 없는 구조를 요구하게 됐다.
    13	KNOWLEDGE_FLAG="$STATE_DIR/.needs-knowledge"
    14	DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
    15	BLOCK_COUNT="$STATE_DIR/.stop-block-count"
    16	BLOCK_FP="$STATE_DIR/.stop-block-fp"    # 마지막 차단 지문(게이트|플래그 상태) — 진전 인지 리셋용
    17	
    18	# Stop 훅이 "같은 지점에서 진전 없이" 최대 몇 번까지 막을 수 있는가. 소진되면 통과시킨다
    19	# (세션 벽돌 방지). 차단 지문이 바뀌면(=게이트를 하나 지웠으면) 카운터는 리셋되므로,
    20	# 게이트 개수가 늘어도 이 상수를 올릴 필요가 없다.
    21	MAX_BLOCKS=3
    22	
    23	# 탈출구.
    24	#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
    25	#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
    26	hook_disabled() {
    27	  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
    28	    return 0
    29	  fi
    30	  case ",${ECC_DISABLED_HOOKS:-}," in
    31	    *",$1,"*) return 0 ;;
    32	  esac
    33	  return 1
    34	}
    35	
    36	# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
    37	#
    38	# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
    39	# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
    40	# 전부 실측된 것들이다:
    41	#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
    42	#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
    43	#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
    44	#   printf 재정의 → 진단 출력 자체를 위조
    45	# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
    46	# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
    47	# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
    48	#
    49	# **대신 셸이 해주던 파싱을 이 함수가 물려받는다.** 그 파싱을 반쯤 하면 fail-open 을
    50	# 없애려다 다른 fail-open 을 만든다 — 실측된 회귀 6종이 전부 여기서 나왔다.
    51	# 후행 주석 · 후행 공백 · CRLF 의 `\r` 이 값에 섞여 들어가면 그 값을 받은 `sh -c` 가
    52	# rc=127 을 내고, 호출부는 그걸 "도구가 없구나"로 읽어 **검사를 조용히 생략한다.**
    53	# 파일 앞 BOM 은 첫 줄의 키를 통째로 무매치로 만들고, 히어독 본문의 같은 키는 선언으로
    54	# 세어진다. 셋 다 눈에 보이지 않는다.
    55	#
    56	# 그래서 **순서가 계약이다**:
    57	#   ① 파일 첫머리 BOM 제거 → ② 각 줄 후행 CR 제거 → ③ 히어독 본문 배제 →
    58	#   ④ 선언 판정 → ⑤ 값 앞 공백 절단 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 **밖** 후행 주석
    59	#   → ⑧ 남은 후행 공백 절단
    60	#
    61	# ── 반환 계약 ──────────────────────────────────────────────────────────
    62	#   rc=0 : 최상위 선언이 **정확히 1개**이고 값을 지원 문법으로 판독했다.
    63	#          stdout = 판독된 값. **빈 문자열일 수 있다** — "리터럴로 비웠다"는 뜻이다.
    64	#   rc=1 : 값을 믿을 수 없다 — 파일 없음 · 읽기 실패 · 선언 0개 · 선언 2개 이상 ·
    65	#          지원 문법 밖. stdout = 빈 문자열.
    66	#
    67	# 왜 이 둘을 rc 로 가르나: 스위치형 슬롯은 "리터럴로 비웠다"(=끈다)와 "미설정"(=이전
    68	# 동작 보존)이 **반대 방향**이다. 빈 문자열 하나로 뭉뚱그리면 키가 없는 기존 설치본이
    69	# 업그레이드 순간 게이트가 꺼진 것과 구별되지 않는다.
    70	#
    71	# ── 지원 문법 (좁게 고정했다. 이 밖은 전부 rc=1) ───────────────────────
    72	#   KEY=값  ·  export KEY=값   (export 뒤는 공백 또는 탭)
    73	#   값: "겹따옴표"  ·  '홑따옴표'  ·  인용 없는 평문
    74	#   따옴표 뒤에는 공백과 `# 주석` 만 올 수 있다
    75	#   인용 없는 값은 **공백에 이어지는 `#`** 부터가 주석이다 (`a#b` 의 `#` 은 값의 일부)
    76	#   값 자리가 `#` 로 시작하면 값은 비어 있는 것으로 본다
    77	# ── 지원하지 않는 것 (조용히 절반만 읽지 않고 rc=1 로 떨어진다) ────────
    78	#   백슬래시 이스케이프 · 한 줄에 인용 조각 여러 개(`"a"b`) · 여러 줄 값 ·
    79	#   닫히지 않은 따옴표
    80	#
    81	# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
    82	# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
    83	# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 rc=1 이다.
    84	#
    85	# 히어독: `<<WORD`·`<<-WORD`·`<<'WORD'` 을 **따옴표 상태를 보며** 찾아 본문을 건너뛴다
    86	# (`"a << b"` 는 히어독이 아니다). 탐지가 어느 쪽으로 틀려도 결과는 rc=1 로 수렴한다 —
    87	# 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다. EOF 까지 안 닫히면
    88	# 탐지가 빗나간 것이므로 역시 rc=1. 한 줄에 히어독이 둘이면 첫 개만 본다.
    89	#
    90	# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **판독 시점에 확장되지 않는다** — 원문 그대로
    91	# 값이 된다. 다만 그 값은 결국 `sh -c` 로 넘어가므로 **실행 시점에는 확장된다**
    92	# (실측: `HARNESS_TYPECHECK_CMD='printf $HOME'` → 실행하면 홈 경로가 찍힌다).
    93	# 즉 "확장되지 않는다"가 아니라 "**나중에** 확장된다"이다. 확장이 곤란한 자리라면
    94	# 그 자리에 최종 문자열을 적어야 한다.
    95	harness_env_value() {
    96	  local file="$STATE_DIR/harness/harness.env" key="$1" val rc
    97	  [ -f "$file" ] || { printf '%s' ''; return 1; }
    98	  if [ ! -r "$file" ]; then
    99	    # "미설정"과 "읽기 실패"는 다르다. 판정은 같게(rc=1) 가되 실패는 소리를 낸다.
   100	    printf '[하네스] harness.env 를 읽지 못했습니다 — 미설정으로 봅니다: %s\n' "$file" >&2
   101	    printf '%s' ''
   102	    return 1
   103	  fi
   104	  # LC_ALL=C 여야 substr 이 바이트 단위로 동작해 BOM 3바이트를 정확히 떼어낸다.
   105	  val="$(LC_ALL=C awk -v key="$key" -v bom="$(printf '\357\273\277')" '
   106	function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
   107	function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
   108	
   109	# 히어독 시작을 찾는다. 따옴표 안의 `<<` 와 주석 뒤의 `<<` 는 히어독이 아니다.
   110	function scan_heredoc(s,   n, i, j, c, q, t, dash) {
   111	  n = length(s); i = 1; q = ""
   112	  while (i <= n) {
   113	    c = substr(s, i, 1)
   114	    if (q != "") { if (c == q) q = ""; i++; continue }
   115	    if (c == "\"" || c == SQ) { q = c; i++; continue }
   116	    if (c == "#" && (i == 1 || substr(s, i - 1, 1) == " " || substr(s, i - 1, 1) == "\t")) return
   117	    if (c == "<" && substr(s, i + 1, 1) == "<") {
   118	      if (substr(s, i + 2, 1) == "<") { i += 3; continue }        # <<< 는 히어스트링
   119	      j = i + 2; dash = 0
   120	      if (substr(s, j, 1) == "-") { dash = 1; j++ }
   121	      while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
   122	      t = ""; c = substr(s, j, 1)
   123	      if (c == "\"" || c == SQ) {                                  # <<"EOF" · <<EOF
   124	        j++
   125	        while (j <= n && substr(s, j, 1) != c) { t = t substr(s, j, 1); j++ }
   126	      } else {
   127	        while (j <= n) {
   128	          c = substr(s, j, 1)
   129	          if (c ~ /[A-Za-z0-9_.\/-]/) { t = t c; j++ } else break
   130	        }
   131	      }
   132	      if (t != "") { INHD = 1; HTERM = t; HDASH = dash }
   133	      return
   134	    }
   135	    i++
   136	  }
   137	}
   138	
   139	# 지원 문법대로 값을 판독한다. 문법 밖이면 BAD 를 세운다(빈 값으로 위장하지 않는다).
   140	function parse_value(v,   q, rest, e, out, tail, i, c, p) {
   141	  # 여기서는 **앞** 공백만 턴다. 뒤 공백은 갈래마다 다른 자리에서 털린다 —
   142	  # 인용 값은 닫는 따옴표 뒤(tail)에서, 인용 없는 값은 반환 직전 rtrim(out) 에서.
   143	  # 여기서 한 번 더 rtrim 하면 어느 변이로도 죽지 않는 죽은 줄이 된다(변이 측정으로 확인).
   144	  v = ltrim(v)
   145	  if (v == "") return ""
   146	  q = substr(v, 1, 1)
   147	  if (q == "\"" || q == SQ) {
   148	    rest = substr(v, 2)
   149	    e = index(rest, q)
   150	    if (e == 0) { BAD = 1; return "" }                             # 닫히지 않은 따옴표
   151	    out = substr(rest, 1, e - 1)
   152	    tail = ltrim(substr(rest, e + 1))
   153	    if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음
   154	    return out
   155	  }
   156	  if (q == "#") return ""                                          # 값 자리가 통째로 주석
   157	  out = ""
   158	  for (i = 1; i <= length(v); i++) {
   159	    c = substr(v, i, 1)
   160	    if (c == "#") {
   161	      p = substr(v, i - 1, 1)
   162	      if (p == " " || p == "\t") break
   163	    }
   164	    out = out c
   165	  }
   166	  return rtrim(out)
   167	}
   168	
   169	BEGIN {
   170	  SQ = sprintf("%c", 39)
   171	  N = 0; FOUND = ""; INHD = 0; HTERM = ""; HDASH = 0; BAD = 0
   172	  RX = "^(export[ \t]+)?" key "="
   173	}
   174	{
   175	  line = $0
   176	  sub(/\r$/, "", line)
   177	  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
   178	
   179	  if (INHD) {
   180	    t = line
   181	    if (HDASH) sub(/^\t+/, "", t)
   182	    if (t == HTERM) { INHD = 0; HTERM = "" }
   183	    next
   184	  }
   185	
   186	  # 선언 판정이 히어독 시작 판정보다 **먼저**다: `KEY=v <<EOF` 의 대입은 실제로 발효한다.
   187	  if (line ~ RX) {
   188	    N++
   189	    if (N == 1) FOUND = substr(line, index(line, "=") + 1)
   190	  }
   191	  scan_heredoc(line)
   192	}
   193	END {
   194	  if (INHD) exit 1          # 히어독이 EOF 까지 안 닫혔다 = 탐지가 빗나갔다
   195	  if (N != 1) exit 1
   196	  v = parse_value(FOUND)
   197	  if (BAD) exit 1
   198	  printf "%s", v
   199	  exit 0
   200	}
   201	' "$file" 2>/dev/null)"
   202	  rc=$?
   203	  [ "$rc" -eq 0 ] || { printf '%s' ''; return 1; }
   204	  printf '%s' "$val"
   205	  return 0
   206	}
   207	
   208	# 지식 반영 게이트가 켜져 있는가 (rc=0 켜짐 / rc=1 꺼짐).
   209	#
   210	# 하네스가 소유하는 것은 **계약 하나**뿐이다 — "지식 저장소가 설정돼 있으면, 결정·설계가
   211	# 나온 턴은 반영 없이 끝낼 수 없다." 어디에 어떤 구조로 반영하는지는 이 층이 모른다.
   212	# 그래서 필요한 것도 1비트뿐이고, 그 1비트를 얻으려고 파일을 실행하지 않는다.
   213	#
   214	# **기본이 켜짐인 것이 이 함수의 핵심이다.** 기존 설치본에는 이 키가 아예 없는데,
   215	# 없을 때 "꺼짐"으로 읽으면 하네스를 갱신하는 순간 게이트가 **조용히 꺼진다** — 사용자는
   216	# 지식이 쌓인다고 믿는데 그 턴부터 아무것도 안 남는다. 표명이 없으면 이전 동작을 보존한다.
   217	# 선언이 2개 이상이거나 문법 밖일 때도 같은 이유로 켠다(rc=1 → 켜짐).
   218	#
   219	# 끄는 방법은 **값을 리터럴로 비우는 것 하나뿐**이다: HARNESS_KNOWLEDGE_GATE=""
   220	# `="off"` 는 켜진 것으로 읽힌다 — 비어 있지 않기 때문이다. harness.env 주석에 명시돼 있다.
   221	harness_knowledge_gate_on() {
   222	  local v
   223	  v="$(harness_env_value HARNESS_KNOWLEDGE_GATE)" || return 0   # 값을 못 믿으면 켠다
   224	  [ -n "$v" ]                                                   # 리터럴로 비었을 때만 꺼짐
   225	}
   226	
   227	# 지식 게이트가 이번 턴에 **발효 중인가** — 플래그가 섰고 게이트도 켜져 있는가.
   228	# 판정을 이 한 곳에 모은다. 두 군데서 따로 물으면 "게이트를 껐는데 남아 있던 플래그가
   229	# 읽기 전용 턴의 조기 종료를 막는" 종류의 어긋남이 생긴다.
   230	knowledge_gate_active() {
   231	  [ -s "$KNOWLEDGE_FLAG" ] || return 1
   232	  harness_knowledge_gate_on
   233	}
   234	
   235	# stdin 의 JSON 에서 점 경로로 값 하나를 뽑는다. 없거나 파싱 실패면 빈 문자열.
   236	# 훅 입력이 깨져도 절대 죽지 않는다 — 죽으면 오탐 차단이 된다.
   237	json_get() {
   238	  python3 -c '
   239	import json, sys
   240	try:
   241	    data = json.load(sys.stdin)
   242	except Exception:
   243	    sys.exit(0)
   244	for key in sys.argv[1].split("."):
   245	    if not isinstance(data, dict):
   246	        sys.exit(0)
   247	    data = data.get(key)
   248	    if data is None:
   249	        sys.exit(0)
   250	print(data)
   251	' "$1" 2>/dev/null
   252	}
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
    23	#     지식 플래그는 **게이트가 켜져 있을 때만** 할 일로 센다 — 껐는데 예전에 남은
    24	#     플래그 파일이 읽기 전용 턴의 조기 종료를 막으면 안 된다.
    25	if [ ! -s "$AUDIT_FLAG" ] && [ ! -s "$EXPLAIN_FLAG" ] && ! knowledge_gate_active && [ ! -s "$DUALREVIEW_FLAG" ]; then
    26	  rm -f "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
    27	  exit 0
    28	fi
    29	
    30	# (2) 카운터 확인 — 벽돌 방지, 진전 인지 리셋 (2026-08-03 [cx] 지적 반영)
    31	# 카운터의 목적은 "갇힘 감지"이지 노력 예산이 아니다. 게이트가 4종으로 늘며 공유 카운터
    32	# 3회로는 게이트를 순서대로 성실히 처리해도 마지막 감사 게이트 전에 소진되는 역설이 있었다.
    33	# → 차단 지문(어느 게이트에서, 어떤 플래그 상태로 막혔나)이 지난 차단과 다르면 = 진전이면
    34	#   카운터를 리셋한다. 같은 지문으로 MAX_BLOCKS회 = 진짜 갇힘일 때만 경고와 통과.
    35	count=0
    36	if [ -f "$BLOCK_COUNT" ]; then
    37	  count="$(tr -dc '0-9' < "$BLOCK_COUNT" 2>/dev/null)"
    38	fi
    39	[ -z "$count" ] && count=0
    40	prev_fp="$(cat "$BLOCK_FP" 2>/dev/null)"
    41	# 지문 = 서 있는 플래그의 집합(내용 아님). 내용을 넣으면 갇힌 채 새 파일만 편집해도
    42	# 리셋되고(무한 차단), cksum 충돌로 실제 진전이 리셋 안 될 수도 있다([cx] 지적).
    43	flags_fp=""
    44	[ -s "$AUDIT_FLAG" ]      && flags_fp="${flags_fp}a"
    45	[ -s "$EXPLAIN_FLAG" ]    && flags_fp="${flags_fp}e"
    46	knowledge_gate_active     && flags_fp="${flags_fp}k"
    47	[ -s "$DUALREVIEW_FLAG" ] && flags_fp="${flags_fp}d"
    48	new_fp=""
    49	
    50	gate_budget() {  # $1 = 게이트 식별자. 각 차단 지점이 메시지 출력 전에 호출한다.
    51	  new_fp="$1|$flags_fp"
    52	  # 지문을 기록할 수 있을 때만 리셋한다 — 지문 파일을 못 쓰는 환경에서 리셋하면
    53	  # prev_fp가 영원히 비어 매번 1/3로 무한 차단된다([cx] 지적). 그 경우 리셋 없는
    54	  # 구식 누적으로 동작해 3회 후 통과가 보장된다.
    55	  if printf '%s\n' "$new_fp" > "$BLOCK_FP" 2>/dev/null; then
    56	    if [ "$new_fp" != "$prev_fp" ]; then
    57	      count=0   # 지난 차단과 다른 게이트/플래그 집합 = 진전 — 예산 리셋
    58	    fi
    59	  fi
    60	  if [ "$count" -ge "$MAX_BLOCKS" ]; then
    61	    changed="$(cat "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" 2>/dev/null | tr -d '"\\' | sort -u | tr '\n' ' ')"
    62	    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
    63	    printf '{"systemMessage":"[완료 게이트] 같은 지점(%s)에서 %s회 차단 후에도 진전이 없어 세션 벽돌 방지를 위해 통과시킵니다. 이 턴의 완료 주장(및 변경 설명)을 신뢰하지 마세요. 미처리 변경: %s"}\n' \
    64	      "$1" "$MAX_BLOCKS" "$changed"
    65	    exit 0
    66	  fi
    67	}
    68	
    69	bump_and_block() {
    70	  if ! printf '%s\n' "$((count + 1))" > "$BLOCK_COUNT" 2>/dev/null; then
    71	    # 카운터를 못 쓰면 무한루프 위험 → 표준 가드로 폴백
    72	    case "$stop_active" in
    73	      [Tt]rue) exit 0 ;;
    74	    esac
    75	  fi
    76	  exit 2
    77	}
    78	
    79	# (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
    80	#     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
    81	#     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
    82	#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
    83	#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
    84	#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
    85	typecheck_note=""
    86	#     rc 를 함께 받는다. "리터럴로 비웠다"(rc=0 + 빈 값 = 의도한 생략)와 "값을 믿을 수
    87	#     없다"(rc=1 = 미설정·선언 2개 이상·지원 문법 밖·읽기 실패)는 둘 다 생략으로 가지만
    88	#     사용자에게 **다른 정보**다. 후자는 고칠 수 있는 실수라 그렇게 적어야 한다.
    89	TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"; typecheck_rc=$?
    90	
    91	if [ "$typecheck_rc" -ne 0 ]; then
    92	  typecheck_note="타입체크 생략 (harness.env 의 HARNESS_TYPECHECK_CMD 를 읽지 못함 — 미설정이거나, 선언이 2개 이상이거나, 지원 문법 밖입니다)"
    93	elif [ -z "$TYPECHECK_CMD" ]; then
    94	  typecheck_note="타입체크 생략 (HARNESS_TYPECHECK_CMD 가 빈 값으로 설정됨)"
    95	else
    96	  timeout_bin=""
    97	  if command -v timeout >/dev/null 2>&1; then
    98	    timeout_bin="timeout"
    99	  elif command -v gtimeout >/dev/null 2>&1; then
   100	    timeout_bin="gtimeout"
   101	  fi
   102	  # macOS 기본에는 timeout 이 없다. 그 경우 settings.json 의 "timeout": 120 이 최종 안전망.
   103	
   104	  if [ -n "$timeout_bin" ]; then
   105	    tc_out="$(cd "$PROJECT_DIR" && "$timeout_bin" 90 sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   106	  else
   107	    tc_out="$(cd "$PROJECT_DIR" && sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   108	  fi
   109	
   110	  if [ "$tc_rc" -eq 124 ] || [ "$tc_rc" -eq 137 ]; then
   111	    # 타임아웃은 "타입 오류"가 아니라 "모름". 차단하지 않고 감사자에게 넘긴다.
   112	    typecheck_note="타입체크 타임아웃 → 생략 (감사자가 재확인할 것)"
   113	  elif [ "$tc_rc" -eq 127 ]; then
   114	    # 명령/도구 없음(rc=127)은 "타입 오류"가 아니다. 오탐 차단 방지 위해 생략.
   115	    typecheck_note="타입체크 생략 (명령 실행 불가 rc=127): $TYPECHECK_CMD"
   116	  elif [ "$tc_rc" -ne 0 ]; then
   117	    gate_budget "typecheck"
   118	    {
   119	      echo "[완료 차단] 타입체크 실패 — 지금은 '완료'가 아닙니다."
   120	      echo
   121	      echo "명령: $TYPECHECK_CMD"
   122	      echo
   123	      printf '%s\n' "$tc_out" | head -n 15
   124	      echo
   125	      echo "고친 뒤 다시 종료하세요.  (차단 $((count + 1))/${MAX_BLOCKS})"
   126	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   127	    } >&2
   128	    bump_and_block
   129	  fi
   130	fi
   131	
   132	# (3.5) 듀얼 리뷰(codex) 게이트 (2026-08-03 kty — "리뷰가 필요한 모든 단계를 codex와 같이"의 기계화).
   133	#      설계·계획 산출물이 저장되거나 코드가 바뀐 턴은 codex 독립 리뷰 없이 끝낼 수 없다.
   134	#      Claude 단독 리뷰가 놓친 CRITICAL을 codex가 잡은 실사고(2026-08-03 POK-30)의 재발 방지.
   135	if [ -s "$DUALREVIEW_FLAG" ] && ! hook_disabled "stop:dualreview"; then
   136	  gate_budget "dualreview"
   137	  {
   138	    echo "[완료 차단] codex 듀얼 리뷰 미수행 — Claude 단독 리뷰로는 끝낼 수 없습니다."
   139	    echo
   140	    echo "이 턴의 듀얼 리뷰 대상:"
   141	    sed 's/^/  - /' "$DUALREVIEW_FLAG" 2>/dev/null
   142	    echo
   143	    echo "해야 할 일:"
   144	    echo "  1. 대상 산출물/diff를 codex로 독립 리뷰시킨다 (모델·effort는 guard-codex-invocation 규정 — 임의 하향 금지)."
   145	    echo "  2. 결과를 _workspace/ 에 *codex*.md 로 저장하고 지적을 [cc]/[cx] 태그로 통합한다."
   146	    echo "  3. 그 뒤에만:  rm -f .claude/.needs-dualreview"
   147	    echo "     codex 미설치·호출 실패면 사용자 보고에 '듀얼 리뷰 생략(codex 실패)'을 명시한 뒤에 지운다."
   148	    echo "     리뷰 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   149	    echo
   150	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
   151	  } >&2
   152	  bump_and_block
   153	fi
   154	
   155	# (4) change-explainer 게이트 (Phase 5) — 감사자보다 먼저 강제한다.
   156	#     코드가 바뀐 턴은 변경 설명 없이 끝낼 수 없다. change-explainer 가 실제로
   157	#     사용자용 설명을 낸 뒤에만 .needs-explain 을 지운다.
   158	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
   159	if [ -s "$EXPLAIN_FLAG" ] && ! hook_disabled "stop:explain"; then
   160	  gate_budget "explain"
   161	  {
   162	    echo "[완료 차단] change-explainer 미실행 — 변경 설명 없이 끝낼 수 없습니다."
   163	    echo
   164	    echo "이 턴에서 바뀐 코드/설정:"
   165	    sed 's/^/  - /' "$EXPLAIN_FLAG" 2>/dev/null
   166	    echo
   167	    echo "해야 할 일:"
   168	    echo "  1. change-explainer 에이전트로 실제 diff 기반 사용자용 변경 설명을 낸다."
   169	    echo "  2. 설명을 낸 뒤에만:  rm -f .claude/.needs-explain"
   170	    echo "     설명 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   171	    echo
   172	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
   173	  } >&2
   174	  bump_and_block
   175	fi
   176	
   177	# (5) 지식 저장소 반영 게이트 — 감사보다 먼저 강제한다 (감사자가 반영 결과를 검증하도록).
   178	#     (2026-08-02 kty — 산문 규칙이 세션 내내 0회 이행된 실사고의 기계화)
   179	#
   180	#     **이 훅이 아는 것은 계약 하나뿐이다**: "지식 저장소가 설정돼 있으면, 결정·설계가
   181	#     나온 턴은 반영 없이 끝낼 수 없다." 저장소가 어디인지·어떤 구조인지·무엇을 4종
   182	#     세트라 부르는지는 **상위 층의 구현**이고 이 파일은 모른다. 알게 되면 그 저장소를
   183	#     안 쓰는 환경에서 하네스가 없는 구조를 요구하게 된다(제0원칙 4 — 구체가 아닌 계약).
   184	#     어디에 어떻게 저장했는지의 검증은 그 저장소 자신의 규약이 한다.
   185	if knowledge_gate_active && ! hook_disabled "stop:knowledge"; then
   186	  gate_budget "knowledge"
   187	  {
   188	    echo "[완료 차단] 지식 저장소 반영 미확인 — 이 턴의 결정·설계를 남기지 않고 끝낼 수 없습니다."
   189	    echo
   190	    echo "이 턴에서 바뀐 코드/설정:"
   191	    sed 's/^/  - /' "$KNOWLEDGE_FLAG" 2>/dev/null
   192	    echo
   193	    echo "해야 할 일:"
   194	    echo "  1. 이 머신의 지식 저장소가 **어디이고 어떤 형식인지는 사용자 층 설정**(전역"
   195	    echo "     CLAUDE.md 등)이 답한다. 그 규약을 **전문** 읽는다 — 부분 독해 금지."
   196	    echo "  2. 이번 턴에 결정·설계·개발작업이 있으면 그 규약대로 반영하고, 반영됐다는"
   197	    echo "     확인 가능한 증거(커밋 해시·파일 경로 등)를 확보한다."
   198	    echo "     판단을 만든 **근거(raw)** 도 규약이 정한 자리에 함께 남긴다 — 요약만 남기면"
   199	    echo "     \"왜 그렇게 정했나\"가 복원 불가능해진다."
   200	    echo "  3. 반영할 지식이 없으면(순수 버그픽스·기계적 수정) 불요 사유를 _workspace/progress.md 에 기록한다."
   201	    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-knowledge"
   202	    echo "     completion-auditor 가 그 증거(또는 불요 사유의 타당성)를 검증한다."
   203	    echo "  5. 지식 저장소를 아예 쓰지 않는 환경이면 harness.env 의 HARNESS_KNOWLEDGE_GATE 를 비운다."
   204	    echo
   205	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:knowledge"
   206	  } >&2
   207	  bump_and_block
   208	fi
   209	
   210	# (6) 타입체크는 통과했지만 감사자가 아직 안 돌았다.
   211	gate_budget "audit"
   212	{
   213	  echo "[완료 차단] completion-auditor 미실행 — '완료'라고 말할 수 없습니다."
   214	  echo
   215	  echo "이 턴에서 바뀐 코드/설정:"
   216	  sed 's/^/  - /' "$AUDIT_FLAG" 2>/dev/null
   217	  if [ -n "$typecheck_note" ]; then
   218	    echo
   219	    echo "참고: $typecheck_note"
   220	  fi
   221	  echo
   222	  echo "해야 할 일:"
   223	  echo "  1. completion-auditor 에이전트로 완료 주장을 1차 증거로 검증한다."
   224	  echo "  2. 검증을 통과했을 때만:  rm -f .claude/.needs-audit"
   225	  echo "     감사 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   226	  echo
   227	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   228	} >&2
   229	bump_and_block
     1	#!/usr/bin/env bash
     2	# PostToolUse(Edit|Write|MultiEdit): 편집된 파일이 완료 게이트 대상이면 플래그를 세운다.
     3	#
     4	# 이 플래그는 completion-auditor 가 검증을 통과시킨 뒤에만 지워진다.
     5	# Stop 훅이 플래그를 보고 턴 종료를 막는다 → 감사자 호출이 강제된다.
     6	# 커밋 여부와 무관하게 동작하므로 "커밋해서 트리가 clean 해졌으니 통과" 같은 구멍이 없다.
     7	#
     8	# 검사 범위:
     9	#   프로젝트 안       — _workspace/·.claude/·순수 *.md|*.markdown(대소문자 무관) 를 뺀 전부
    10	#   밖 + 하네스 정본  — 저장소(루트에 template/.claude/) **전체**를 프로젝트와 같은 규칙으로
    11	#   밖 + 그 외        — .claude/ 앵커에 걸린 하네스 파일만 (git 저장소일 필요 없음)
    12	#   설계·계획 산출물  — 위치·git 무관하게 _workspace/00_design*.md·01_plan*.md 는 듀얼리뷰만
    13	#
    14	# 왜 이렇게 넓나 (2026-08-04 실사고): 하네스 자신을 고치는 작업은 **늘** 별도 클론에서
    15	# 일어나는데 훅이 프로젝트 밖을 통째로 스킵해, 게이트가 프로젝트는 지키면서 정작 하네스
    16	# 자체 개발만 못 지켰다.
    17	# 왜 위치가 아니라 경로 모양인가: 예전엔 홈 디렉터리를 통째로 예외 처리했는데, 그 규칙이
    18	# 남의 닷파일 저장소를 오탐하면서(vimrc) 정작 홈에 설치된 하네스 파일은 놓쳤다. 위치는
    19	# 게이트 대상 여부와 상관이 없다 — 하네스 동작을 정의하는 파일인지가 상관있다.
    20	# 홈 디렉터리 예외는 삭제됐다. 되살리지 마라 (회귀 테스트가 정적으로 막는다).
    21	#
    22	# 기록값: 프로젝트 안은 상대경로, 밖은 **절대경로**. 밖 편집을 상대경로로 적으면
    23	#         프로젝트 쪽 동명 파일과 구분되지 않는다.
    24	#
    25	# PostToolUse 는 절대 차단하지 않는다(도구는 이미 실행됨). 항상 exit 0.
    26	# 차단할 수 없으므로, 기록에 **실패**했거나 경로 때문에 기록을 **포기**했을 때는
    27	# stdout 의 systemMessage 로 알린다 — 조용히 게이트가 사라지는 것보다 낫다.
    28	#
    29	# 이 판정 계약의 기계 정본은 tests/mark-needs-audit.cases.sh 이고
    30	# tests/mark-needs-audit.test.sh 가 그것을 돌린다.
    31	# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
    32	
    33	set -uo pipefail
    34	# shellcheck source=_common.sh
    35	. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
    36	
    37	HOOK_ID="post:edit:needs-audit"
    38	hook_disabled "$HOOK_ID" && exit 0
    39	
    40	# 메시지 상수. " 와 \ 와 제어문자를 쓰지 않는다 — 그래서 이스케이프 로직이 필요 없다.
    41	# 경로를 넣지 않는 것도 같은 이유다: 기록 실패 상황에서 사용자에게 필요한 정보는
    42	# "게이트가 안 섰다"는 사실이고, 경로를 끼우는 순간 이스케이프 기계장치가 딸려온다.
    43	MSG_WRITE_FAIL="완료 게이트 플래그를 기록하지 못했다(.claude 쓰기 실패). 게이트가 서지 않았으니 완료 판정 전에 수동으로 확인하라."
    44	MSG_NEWLINE="편집 경로에 개행이 있어 게이트 플래그를 기록하지 않았다. 줄 단위 플래그 파일이 오염되기 때문이다. 수동으로 확인하라."
    45	MSG_GIT_UNAVAILABLE="git 이 저장소 정보를 돌려주지 못해(소유권 거부·권한·손상) 하네스 정본 여부를 판정하지 못했다. 앵커 밖 파일에는 게이트가 서지 않았으니 수동으로 확인하라."
    46	
    47	# --- 계약 함수 ------------------------------------------------------------
    48	
    49	# emit_message <메시지> — {"systemMessage":"..."} 를 stdout 에 한 줄로.
    50	# JSON 을 만드는 **유일 지점**이다. 여기 말고 다른 곳에서 stdout 에 쓰면 안 된다.
    51	emit_message() {
    52	  printf '{"systemMessage":"%s"}\n' "$1"
    53	}
    54	
    55	# physical_dir <디렉토리> — 심링크·`..`·`.` 를 푼 물리 절대경로를 stdout 에.
    56	# 실패하면 **원본을 그대로 내고** rc=1. 호출자는 스킵하지 않는다 — 정규화에 실패했다고
    57	# 게이트를 지우면 조용한 위음성이 되므로, 덜 정확한 경로로라도 판정을 잇는 쪽을 택한다.
    58	#
    59	# **cd 는 반드시 -P 여야 한다** — pwd -P 만으로는 부족하다. 논리 cd(기본값)는 `심링크/..` 를
    60	# 심링크를 따라가기 **전에** 문자로 상쇄하므로 커널이 실제로 여는 곳과 다른 답을 낸다
    61	# (실측: `cd -- /var/..` → `/`, `cd -P -- /var/..` → `/private`). 그 차이만큼 프로젝트
    62	# **밖** 파일이 프로젝트 **안** 상대경로로 기록돼, 게이트는 서는데 감사자가 엉뚱한 파일을
    63	# 본다(케이스 67). 반대 방향으로는 밖 하네스 파일의 게이트가 통째로 사라진다(케이스 68).
    64	# 형제 검사기 scripts/check-rule-copies.sh 의 physical_path 와 같은 방식이다(PR #13).
    65	physical_dir() {
    66	  local out
    67	  out="$(CDPATH='' cd -P -- "$1" 2>/dev/null && pwd -P)"
    68	  if [ -z "$out" ]; then
    69	    printf '%s\n' "$1"
    70	    return 1
    71	  fi
    72	  printf '%s\n' "$out"
    73	}
    74	
    75	# physical_path <파일경로> — 편집 경로를 물리화한다. 실패하면 **원본 경로를 그대로 내고** rc=1.
    76	#
    77	# 마지막 성분이 **이름이면 보존**한다 — 파일 자신이 심링크여도 편집 대상의 이름으로
    78	# 기록해야 하고, 애초에 파일에는 cd 할 수 없다. 파일이 아직 없을 수도 있다(케이스 51).
    79	#
    80	# **단 `.`·`..` 는 이름이 아니라 디렉토리 이동이라 반드시 푼다.** 보존할 이름이 없으므로
    81	# 위 예외의 근거가 성립하지 않는다. 안 풀면 dirname 만 물리화된 `…/src/..` 가 그대로 나와
    82	# 프로젝트 접두사에 문자열상 걸리고, 플래그에 디렉토리 표기가 박힌다(케이스 69·70).
    83	# 형제 검사기가 PR #13 에서 같은 이름의 같은 버그를 이 방식으로 고쳤다 — 접근을 맞춘다.
    84	physical_path() {
    85	  local dir base
    86	  base="$(basename -- "$1")"
    87	  # cd 는 반드시 명령 치환 안에서 — 함수 본문에서 그냥 cd 하면 호출부의 cwd 가 바뀐다.
    88	  case "$base" in
    89	    . | ..) physical_dir "$1"; return ;;
    90	  esac
    91	  dir="$(physical_dir "$(dirname -- "$1")")" || { printf '%s\n' "$1"; return 1; }
    92	  # pwd -P 가 "/" 를 낼 때만 "//base" 가 된다 (루트 바로 아래 경로).
    93	  if [ "$dir" = '/' ]; then dir=''; fi
    94	  printf '%s/%s\n' "$dir" "$base"
    95	}
    96	
    97	# project_rel <절대경로> — $proj 아래면 프로젝트 기준 상대경로를 stdout·rc=0, 아니면 rc=1.
    98	# 접두사에 **슬래시를 반드시 포함**한다. 빠뜨리면 형제 디렉토리(<proj>-backup/…)를
    99	# 프로젝트 안으로 오인한다. "$proj" 를 인용하는 것은 경로 안의 글롭 문자 때문이다.
   100	project_rel() {
   101	  case "$1" in
   102	    "$proj"/*) printf '%s\n' "${1#"$proj"/}" ;;
   103	    *) return 1 ;;
   104	  esac
   105	}
   106	
   107	# git_toplevel <절대경로> — 그 파일이 속한 git 저장소 루트를 물리 경로로. 없으면 rc=1.
   108	# GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE 을 소거한다: 훅이 git 훅 안에서 돌면 이 변수들이
   109	# 엉뚱한 저장소를 가리켜 귀속이 통째로 바뀐다.
   110	# 경로에 /.git/ 가 있으면 그 앞을 기준으로 삼는다: git 은 .git 안에서 --show-toplevel 에
   111	# 실패하므로(실측 rc=128), 그대로 물으면 .git/hooks/* 편집이 판정 불가로 새어나간다.
   112	git_toplevel() {
   113	  local dir top
   114	  case "$1" in
   115	    */.git/*) dir="${1%%/.git/*}" ;;
   116	    */.git)   dir="${1%/.git}" ;;
   117	    *)        dir="$(dirname -- "$1")" ;;
   118	  esac
   119	  top="$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
   120	         git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"
   121	  [ -n "$top" ] || return 1
   122	  physical_dir "$top"
   123	}
   124	
   125	# has_git_ancestor <절대경로> — 조상 디렉토리에 .git 이 있는가. git 을 쓰지 않는다.
   126	# git_toplevel 이 빈 값을 돌려준 이유가 "저장소가 아님"인지 "git 이 거부함"인지를 가르는
   127	# 데 쓴다. rev-parse 는 둘 다 rc=128 로 돌려주므로 stderr 내용으로 가르는 것은 취약하다.
   128	has_git_ancestor() {
   129	  local d
   130	  d="$(dirname -- "$1")"
   131	  while [ "$d" != '/' ] && [ "$d" != '.' ]; do
   132	    [ -e "$d/.git" ] && return 0
   133	    d="$(dirname -- "$d")"
   134	  done
   135	  return 1
   136	}
   137	
   138	# is_harness_canonical <저장소루트> — 하네스 정본 저장소인가.
   139	# 마커는 이 한 조건뿐이다. 조건을 더 얹으면 재배치 포크에서 위음성이 넓어지는데,
   140	# 위음성은 조용하고 오탐은 탈출구(ECC_DISABLED_HOOKS)가 있다 — 그래서 단순한 쪽을 택했다.
   141	is_harness_canonical() {
   142	  [ -d "$1/template/.claude" ]
   143	}
   144	
   145	# harness_anchor <선행 슬래시가 있는 경로> — 하네스 동작을 정의하는 자리인가.
   146	# 앵커 목록을 정의하는 **유일 지점**이다.
   147	harness_anchor() {
   148	  case "$1" in
   149	    */.claude/agents/*|*/.claude/skills/*|*/.claude/hooks/*|*/.claude/harness/*|*/.claude/settings.json)
   150	      return 0 ;;
   151	  esac
   152	  return 1
   153	}
   154	
   155	# classify <기준 상대경로> <기준 디렉토리> — gate · knowledge · skip 을 stdout 에.
   156	# 프로젝트 안(4a)과 밖-하네스정본(4b)이 **같은 규칙**을 쓰도록 공유한다.
   157	#
   158	# 순서가 계약이다:
   159	#   1) .claude/*·_workspace/* 제외가 앵커보다 **먼저**. 그래야 하네스 정본 저장소가
   160	#      자기 자신에 설치해 둔 소비 사본(.claude/hooks/*)이 빠지고 정본(template/.claude/*)만
   161	#      발화한다. 설치본은 정본을 고쳐 sync 하는 게 규약이라 제자리 편집은 일시적이다.
   162	#   2) 앵커가 *.md 제외보다 먼저. 에이전트·스킬·원칙 정의는 전부 .md 인데 일괄 제외하면
   163	#      하네스 저장소에서 가장 흔한 변경에 플래그가 하나도 안 선다.
   164	#   3) global-agents/*.md 는 **정본 스코프에서만** 예외의 예외를 연다. install/sync 가
   165	#      배포하는 전역 에이전트 정본이기 때문이며, 남의 프로젝트로 새면 오탐이 된다.
   166	classify() {
   167	  local rel="$1" base="$2" lower
   168	  case "$rel" in
   169	    _workspace/*|.claude/*) printf 'skip\n'; return 0 ;;
   170	  esac
   171	  if harness_anchor "/$rel"; then
   172	    printf 'gate\n'; return 0
   173	  fi
   174	  case "$rel" in
   175	    global-agents/*.md)
   176	      if is_harness_canonical "$base"; then printf 'gate\n'; return 0; fi ;;
   177	  esac
   178	  # 확장자 판정은 소문자화해서 본다 — README.MD 가 코드로 취급되면 안 된다.
   179	  lower="$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')"
   180	  # 결정 문서는 문서 제외의 **예외**다. 하네스가 스스로 "결정은 여기 이 이름으로 쓴다"고
   181	  # 규정한 경로(결정 기록 절)라 **하네스가 아는 산출물**이고, 그 자리가 편집됐다는 것은
   182	  # 곧 결정이 나왔다는 뜻이다. 코드가 아니므로 게이트 4종은 과하다 — 지식 게이트만 세운다.
   183	  #
   184	  # 공시된 한계: 결정 문서를 이 경로 **밖**에 두면 게이트가 서지 않는다. 하네스가 아는
   185	  # 경로만 알 수 있기 때문이고, 프로젝트마다 다른 위치를 알아내려면 다시 상위 층 구현을
   186	  # 알아야 한다. 이 공백은 회수 정책 ADR 로 넘긴다.
   187	  case "$lower" in
   188	    docs/decisions/*.md|docs/decisions/*.markdown) printf 'knowledge\n'; return 0 ;;
   189	  esac
   190	  case "$lower" in
   191	    *.md|*.markdown) printf 'skip\n'; return 0 ;;
   192	  esac
   193	  printf 'gate\n'
   194	}
   195	
   196	# record_flag <플래그파일> <값> — 이미 있으면 그냥 두고, 없으면 한 줄 덧붙인다. 실패하면 rc=1.
   197	# grep 의 -- 는 필수다: 값이 - 로 시작하면(예: 파일명 --version) grep 이 그것을 옵션으로
   198	# 해석해 rc=0(=이미 있음)을 돌려주고, BSD grep 은 -q 아래서도 버전 문자열을 stdout 에 뱉는다.
   199	# append 를 중괄호로 감싸는 것도 필수다: 리다이렉트 **열기** 실패는 셸이 보고하는데,
   200	# printf 뒤에 붙인 2>/dev/null 은 그 시점에 아직 적용되지 않아 stderr 가 샌다(실측).
   201	record_flag() {
   202	  mkdir -p "$STATE_DIR" 2>/dev/null
   203	  if grep -qxF -- "$2" "$1" 2>/dev/null; then
   204	    return 0
   205	  fi
   206	  { printf '%s\n' "$2" >> "$1"; } 2>/dev/null || return 1
   207	  return 0
   208	}
   209	
   210	# --- 판정 -----------------------------------------------------------------
   211	
   212	payload="$(cat)"
   213	# json_get 결과를 **센티널로** 받는다. 명령 치환은 후행 개행을 전부 지우므로 그냥 받으면
   214	# 경로 끝의 개행이 아래 가드에 닿기도 전에 사라지고, 경고 없이 **다른 파일** 경로가
   215	# 기록된다("src/app.ts" + LF → "src/app.ts"). X 를 붙여 받고 도로 뗀 뒤, json_get 자신이
   216	# print() 로 붙인 개행 **하나만** 지운다 — 그러면 원본의 후행 개행이 살아남는다.
   217	raw="$(printf '%s' "$payload" | json_get tool_input.file_path; printf 'X')"
   218	raw="${raw%X}"
   219	file_path="${raw%$'\n'}"
   220	[ -z "$file_path" ] && exit 0
   221	
   222	# 개행 가드는 **정규화보다 먼저**여야 한다. 디렉토리 컴포넌트가 개행으로 끝나면
   223	# (…/sr<LF>/app.ts) physical_path 의 pwd -P 출력을 받는 명령 치환이 그 개행을 먹어
   224	# 경로가 …/sr/app.ts 로 조용히 바뀐다 — 없는 파일이 게이트에 박히고 정작 편집한
   225	# 파일은 무게이트가 된다. 플래그 파일은 줄 단위라 개행이 든 경로는 애초에 못 적는다.
   226	case "$file_path" in
   227	  *$'\n'*) emit_message "$MSG_NEWLINE"; exit 0 ;;
   228	esac
   229	
   230	# 양쪽을 물리 경로로 맞춘 뒤에 비교한다. git 은 실제 경로를 돌려주는데 편집 경로는
   231	# 심링크를 지나올 수 있고(macOS /var → /private/var), .. 로 되돌아올 수도 있다.
   232	# 정규화 없이 자르면 접두사가 안 맞아 프로젝트 안 편집이 통째로 "밖"으로 샌다.
   233	# PROJECT_DIR 은 디렉토리라 통째로 물리화한다(심링크 PROJECT_DIR — 케이스 11·12).
   234	# 편집 경로는 파일이라 마지막 성분 이름을 보존하는 physical_path 를 쓴다 — 두 계약이
   235	# 다르므로 함수도 둘이다.
   236	proj="$(physical_dir "$PROJECT_DIR")"
   237	case "$file_path" in
   238	  /*) ;;
   239	  *) file_path="$proj/$file_path" ;;
   240	esac
   241	abs="$(physical_path "$file_path")"
   242	
   243	# 설계·계획 산출물은 위치·git 여부와 무관하게 듀얼리뷰 게이트만 세운다.
   244	# **정규화 뒤**에 판정해야 한다: 상대경로 입력에는 선행 슬래시가 없어 아래 글롭에
   245	# 걸리지 않고, .. 가 섞인 경로는 기록값이 .claude/../_workspace/… 로 남는다.
   246	# 매칭만 소문자화하고 기록은 원본 대소문자로 한다.
   247	lower_abs="$(printf '%s' "$abs" | tr '[:upper:]' '[:lower:]')"
   248	# 설계·계획 산출물은 듀얼리뷰 **와 지식 게이트**를 세운다. 코드가 아니므로 타입체크·
   249	# 변경설명·감사는 과하지만, 설계가 나온 턴을 지식 저장소 반영 없이 끝내면 "왜 그렇게
   250	# 정했나"가 그 자리에서 사라진다 — 결정을 만든 근거가 정확히 이 파일들이다.
   251	case "$lower_abs" in
   252	  */_workspace/00_design*.md|*/_workspace/01_plan*.md)
   253	    dual_value="$(project_rel "$abs")" || dual_value="$abs"
   254	    dw=0
   255	    record_flag "$DUALREVIEW_FLAG" "$dual_value" || dw=1
   256	    record_flag "$KNOWLEDGE_FLAG"  "$dual_value" || dw=1
   257	    [ "$dw" -eq 1 ] && emit_message "$MSG_WRITE_FAIL"
   258	    exit 0 ;;
   259	esac
   260	

exec
/bin/zsh -lc "nl -ba template/.claude/hooks/verify-before-stop.sh | sed -n '75,235p'
nl -ba template/.claude/hooks/mark-needs-audit.sh | sed -n '240,380p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
    75	  fi
    76	  exit 2
    77	}
    78	
    79	# (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
    80	#     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
    81	#     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
    82	#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
    83	#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
    84	#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
    85	typecheck_note=""
    86	#     rc 를 함께 받는다. "리터럴로 비웠다"(rc=0 + 빈 값 = 의도한 생략)와 "값을 믿을 수
    87	#     없다"(rc=1 = 미설정·선언 2개 이상·지원 문법 밖·읽기 실패)는 둘 다 생략으로 가지만
    88	#     사용자에게 **다른 정보**다. 후자는 고칠 수 있는 실수라 그렇게 적어야 한다.
    89	TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"; typecheck_rc=$?
    90	
    91	if [ "$typecheck_rc" -ne 0 ]; then
    92	  typecheck_note="타입체크 생략 (harness.env 의 HARNESS_TYPECHECK_CMD 를 읽지 못함 — 미설정이거나, 선언이 2개 이상이거나, 지원 문법 밖입니다)"
    93	elif [ -z "$TYPECHECK_CMD" ]; then
    94	  typecheck_note="타입체크 생략 (HARNESS_TYPECHECK_CMD 가 빈 값으로 설정됨)"
    95	else
    96	  timeout_bin=""
    97	  if command -v timeout >/dev/null 2>&1; then
    98	    timeout_bin="timeout"
    99	  elif command -v gtimeout >/dev/null 2>&1; then
   100	    timeout_bin="gtimeout"
   101	  fi
   102	  # macOS 기본에는 timeout 이 없다. 그 경우 settings.json 의 "timeout": 120 이 최종 안전망.
   103	
   104	  if [ -n "$timeout_bin" ]; then
   105	    tc_out="$(cd "$PROJECT_DIR" && "$timeout_bin" 90 sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   106	  else
   107	    tc_out="$(cd "$PROJECT_DIR" && sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   108	  fi
   109	
   110	  if [ "$tc_rc" -eq 124 ] || [ "$tc_rc" -eq 137 ]; then
   111	    # 타임아웃은 "타입 오류"가 아니라 "모름". 차단하지 않고 감사자에게 넘긴다.
   112	    typecheck_note="타입체크 타임아웃 → 생략 (감사자가 재확인할 것)"
   113	  elif [ "$tc_rc" -eq 127 ]; then
   114	    # 명령/도구 없음(rc=127)은 "타입 오류"가 아니다. 오탐 차단 방지 위해 생략.
   115	    typecheck_note="타입체크 생략 (명령 실행 불가 rc=127): $TYPECHECK_CMD"
   116	  elif [ "$tc_rc" -ne 0 ]; then
   117	    gate_budget "typecheck"
   118	    {
   119	      echo "[완료 차단] 타입체크 실패 — 지금은 '완료'가 아닙니다."
   120	      echo
   121	      echo "명령: $TYPECHECK_CMD"
   122	      echo
   123	      printf '%s\n' "$tc_out" | head -n 15
   124	      echo
   125	      echo "고친 뒤 다시 종료하세요.  (차단 $((count + 1))/${MAX_BLOCKS})"
   126	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   127	    } >&2
   128	    bump_and_block
   129	  fi
   130	fi
   131	
   132	# (3.5) 듀얼 리뷰(codex) 게이트 (2026-08-03 kty — "리뷰가 필요한 모든 단계를 codex와 같이"의 기계화).
   133	#      설계·계획 산출물이 저장되거나 코드가 바뀐 턴은 codex 독립 리뷰 없이 끝낼 수 없다.
   134	#      Claude 단독 리뷰가 놓친 CRITICAL을 codex가 잡은 실사고(2026-08-03 POK-30)의 재발 방지.
   135	if [ -s "$DUALREVIEW_FLAG" ] && ! hook_disabled "stop:dualreview"; then
   136	  gate_budget "dualreview"
   137	  {
   138	    echo "[완료 차단] codex 듀얼 리뷰 미수행 — Claude 단독 리뷰로는 끝낼 수 없습니다."
   139	    echo
   140	    echo "이 턴의 듀얼 리뷰 대상:"
   141	    sed 's/^/  - /' "$DUALREVIEW_FLAG" 2>/dev/null
   142	    echo
   143	    echo "해야 할 일:"
   144	    echo "  1. 대상 산출물/diff를 codex로 독립 리뷰시킨다 (모델·effort는 guard-codex-invocation 규정 — 임의 하향 금지)."
   145	    echo "  2. 결과를 _workspace/ 에 *codex*.md 로 저장하고 지적을 [cc]/[cx] 태그로 통합한다."
   146	    echo "  3. 그 뒤에만:  rm -f .claude/.needs-dualreview"
   147	    echo "     codex 미설치·호출 실패면 사용자 보고에 '듀얼 리뷰 생략(codex 실패)'을 명시한 뒤에 지운다."
   148	    echo "     리뷰 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   149	    echo
   150	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
   151	  } >&2
   152	  bump_and_block
   153	fi
   154	
   155	# (4) change-explainer 게이트 (Phase 5) — 감사자보다 먼저 강제한다.
   156	#     코드가 바뀐 턴은 변경 설명 없이 끝낼 수 없다. change-explainer 가 실제로
   157	#     사용자용 설명을 낸 뒤에만 .needs-explain 을 지운다.
   158	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
   159	if [ -s "$EXPLAIN_FLAG" ] && ! hook_disabled "stop:explain"; then
   160	  gate_budget "explain"
   161	  {
   162	    echo "[완료 차단] change-explainer 미실행 — 변경 설명 없이 끝낼 수 없습니다."
   163	    echo
   164	    echo "이 턴에서 바뀐 코드/설정:"
   165	    sed 's/^/  - /' "$EXPLAIN_FLAG" 2>/dev/null
   166	    echo
   167	    echo "해야 할 일:"
   168	    echo "  1. change-explainer 에이전트로 실제 diff 기반 사용자용 변경 설명을 낸다."
   169	    echo "  2. 설명을 낸 뒤에만:  rm -f .claude/.needs-explain"
   170	    echo "     설명 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   171	    echo
   172	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
   173	  } >&2
   174	  bump_and_block
   175	fi
   176	
   177	# (5) 지식 저장소 반영 게이트 — 감사보다 먼저 강제한다 (감사자가 반영 결과를 검증하도록).
   178	#     (2026-08-02 kty — 산문 규칙이 세션 내내 0회 이행된 실사고의 기계화)
   179	#
   180	#     **이 훅이 아는 것은 계약 하나뿐이다**: "지식 저장소가 설정돼 있으면, 결정·설계가
   181	#     나온 턴은 반영 없이 끝낼 수 없다." 저장소가 어디인지·어떤 구조인지·무엇을 4종
   182	#     세트라 부르는지는 **상위 층의 구현**이고 이 파일은 모른다. 알게 되면 그 저장소를
   183	#     안 쓰는 환경에서 하네스가 없는 구조를 요구하게 된다(제0원칙 4 — 구체가 아닌 계약).
   184	#     어디에 어떻게 저장했는지의 검증은 그 저장소 자신의 규약이 한다.
   185	if knowledge_gate_active && ! hook_disabled "stop:knowledge"; then
   186	  gate_budget "knowledge"
   187	  {
   188	    echo "[완료 차단] 지식 저장소 반영 미확인 — 이 턴의 결정·설계를 남기지 않고 끝낼 수 없습니다."
   189	    echo
   190	    echo "이 턴에서 바뀐 코드/설정:"
   191	    sed 's/^/  - /' "$KNOWLEDGE_FLAG" 2>/dev/null
   192	    echo
   193	    echo "해야 할 일:"
   194	    echo "  1. 이 머신의 지식 저장소가 **어디이고 어떤 형식인지는 사용자 층 설정**(전역"
   195	    echo "     CLAUDE.md 등)이 답한다. 그 규약을 **전문** 읽는다 — 부분 독해 금지."
   196	    echo "  2. 이번 턴에 결정·설계·개발작업이 있으면 그 규약대로 반영하고, 반영됐다는"
   197	    echo "     확인 가능한 증거(커밋 해시·파일 경로 등)를 확보한다."
   198	    echo "     판단을 만든 **근거(raw)** 도 규약이 정한 자리에 함께 남긴다 — 요약만 남기면"
   199	    echo "     \"왜 그렇게 정했나\"가 복원 불가능해진다."
   200	    echo "  3. 반영할 지식이 없으면(순수 버그픽스·기계적 수정) 불요 사유를 _workspace/progress.md 에 기록한다."
   201	    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-knowledge"
   202	    echo "     completion-auditor 가 그 증거(또는 불요 사유의 타당성)를 검증한다."
   203	    echo "  5. 지식 저장소를 아예 쓰지 않는 환경이면 harness.env 의 HARNESS_KNOWLEDGE_GATE 를 비운다."
   204	    echo
   205	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:knowledge"
   206	  } >&2
   207	  bump_and_block
   208	fi
   209	
   210	# (6) 타입체크는 통과했지만 감사자가 아직 안 돌았다.
   211	gate_budget "audit"
   212	{
   213	  echo "[완료 차단] completion-auditor 미실행 — '완료'라고 말할 수 없습니다."
   214	  echo
   215	  echo "이 턴에서 바뀐 코드/설정:"
   216	  sed 's/^/  - /' "$AUDIT_FLAG" 2>/dev/null
   217	  if [ -n "$typecheck_note" ]; then
   218	    echo
   219	    echo "참고: $typecheck_note"
   220	  fi
   221	  echo
   222	  echo "해야 할 일:"
   223	  echo "  1. completion-auditor 에이전트로 완료 주장을 1차 증거로 검증한다."
   224	  echo "  2. 검증을 통과했을 때만:  rm -f .claude/.needs-audit"
   225	  echo "     감사 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   226	  echo
   227	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   228	} >&2
   229	bump_and_block
   240	esac
   241	abs="$(physical_path "$file_path")"
   242	
   243	# 설계·계획 산출물은 위치·git 여부와 무관하게 듀얼리뷰 게이트만 세운다.
   244	# **정규화 뒤**에 판정해야 한다: 상대경로 입력에는 선행 슬래시가 없어 아래 글롭에
   245	# 걸리지 않고, .. 가 섞인 경로는 기록값이 .claude/../_workspace/… 로 남는다.
   246	# 매칭만 소문자화하고 기록은 원본 대소문자로 한다.
   247	lower_abs="$(printf '%s' "$abs" | tr '[:upper:]' '[:lower:]')"
   248	# 설계·계획 산출물은 듀얼리뷰 **와 지식 게이트**를 세운다. 코드가 아니므로 타입체크·
   249	# 변경설명·감사는 과하지만, 설계가 나온 턴을 지식 저장소 반영 없이 끝내면 "왜 그렇게
   250	# 정했나"가 그 자리에서 사라진다 — 결정을 만든 근거가 정확히 이 파일들이다.
   251	case "$lower_abs" in
   252	  */_workspace/00_design*.md|*/_workspace/01_plan*.md)
   253	    dual_value="$(project_rel "$abs")" || dual_value="$abs"
   254	    dw=0
   255	    record_flag "$DUALREVIEW_FLAG" "$dual_value" || dw=1
   256	    record_flag "$KNOWLEDGE_FLAG"  "$dual_value" || dw=1
   257	    [ "$dw" -eq 1 ] && emit_message "$MSG_WRITE_FAIL"
   258	    exit 0 ;;
   259	esac
   260	
   261	if rel="$(project_rel "$abs")"; then
   262	  value="$rel"
   263	  verdict="$(classify "$rel" "$proj")"
   264	else
   265	  # 프로젝트 밖. 기록값은 절대경로다.
   266	  value="$abs"
   267	  root="$(git_toplevel "$abs")" || root=''
   268	  if [ -n "$root" ] && is_harness_canonical "$root"; then
   269	    case "$abs" in
   270	      "$root"/*) rel="${abs#"$root"/}" ;;
   271	      *) rel="$abs" ;;
   272	    esac
   273	    verdict="$(classify "$rel" "$root")"
   274	  elif harness_anchor "$abs"; then
   275	    # 앵커 판정에 git 을 요구하지 않는다 — 홈에 설치된 .claude/agents/*.md 는
   276	    # 그 디렉토리가 git 저장소가 아니어도 하네스 동작을 정의한다.
   277	    verdict='gate'
   278	  else
   279	    verdict='skip'
   280	    # git 이 빈 값을 돌려줬는데 조상에 .git 이 있으면, 저장소가 아닌 게 아니라 git 이
   281	    # 거부한 것이다(safe.directory 소유권 거부·권한·손상). 그대로 두면 정본 저장소
   282	    # 전체가 앵커 밖 파일에 대해 무게이트 + 무신호로 조용히 감시 축소된다.
   283	    # 판정은 바꾸지 않는다(추측으로 게이트를 세우면 남의 저장소를 오탐한다) — 알리기만
   284	    # 한다. physical_path 가 fail-loud 인데 여기만 fail-silent 이던 비대칭을 없앤다.
   285	    [ -z "$root" ] && has_git_ancestor "$abs" && emit_message "$MSG_GIT_UNAVAILABLE"
   286	  fi
   287	fi
   288	
   289	# 결정 문서는 지식 게이트 하나만. 코드가 아니므로 타입체크·변경설명·감사는 과하다.
   290	if [ "$verdict" = 'knowledge' ]; then
   291	  record_flag "$KNOWLEDGE_FLAG" "$value" || emit_message "$MSG_WRITE_FAIL"
   292	  exit 0
   293	fi
   294	
   295	[ "$verdict" = 'gate' ] || exit 0
   296	
   297	# 완료 게이트 4종을 동시에 세운다:
   298	#   .needs-audit      → completion-auditor 강제 (Phase 6)
   299	#   .needs-explain    → change-explainer 강제 (Phase 5)
   300	#   .needs-knowledge  → 지식 저장소 반영 또는 불요 사유 기록 강제 (2026-08-02 kty —
   301	#                       산문 규칙이 기억에만 의존해 세션 내내 0회 이행된 실사고의 재발 방지)
   302	#   .needs-dualreview → codex 듀얼 리뷰 강제 (2026-08-03 kty)
   303	# 각 게이트는 해당 작업이 실제로 끝난 뒤에만 수동으로 지워진다. Stop 훅이 넷 다 본다.
   304	#
   305	# 지식 게이트가 꺼져 있어도 여기서는 **기록한다.** 켜짐/꺼짐 판정은 harness.env 를 한 번
   306	# 더 읽는 일인데 이 훅은 편집마다 돌고 Stop 훅은 턴에 한 번 돈다 — 판정은 Stop 쪽
   307	# 한 곳(knowledge_gate_active)으로 모았다. 꺼져 있으면 이 파일은 아무 효력이 없다.
   308	write_failed=0
   309	for flag in "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG"; do
   310	  record_flag "$flag" "$value" || write_failed=1
   311	done
   312	# 넷이 다 실패해도 메시지는 한 줄만 낸다.
   313	[ "$write_failed" -eq 1 ] && emit_message "$MSG_WRITE_FAIL"
   314	exit 0

codex
핵심 훅을 읽었습니다. 현재 가장 민감한 부분은 “파서가 실제 셸 문법을 흉내 내는가”보다, 지원 문법 밖을 확실히 rc=1로 모으는지와 그 rc를 게이트가 기본-on으로 해석하는지입니다. 이제 설치 스왑의 상태 전이와 테스트가 그 전이를 실제로 검증하는지 대조하겠습니다.
exec
/bin/zsh -lc "nl -ba install.sh | sed -n '1,340p'
nl -ba sync.sh | sed -n '1,300p'
nl -ba scripts/check-layer-boundary.sh | sed -n '1,320p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# install.sh — 하네스 템플릿을 프로젝트에 인스턴스화한다.
     3	#
     4	# 사용법: ./install.sh <프로젝트-경로> [프로젝트-이름]
     5	#
     6	# 동작 원칙:
     7	#   글루(에이전트·오케스트레이터·훅·제0원칙)  → 복사·덮어씀 (재실행 = 글루 갱신)
     8	#   슬롯(project-profile.md · harness.env)      → 없을 때만 스캐폴드, 절대 안 덮음
     9	#   settings.json                               → 병합 (기존 훅 보존, 백업 생성)
    10	#   CLAUDE.md                                    → 하네스 포인터 append (이미 있으면 생략)
    11	#
    12	# 전역 의존(참조, 복사 안 함): ECC 룰(~/.claude/rules/ecc/) · superpowers · claude-mem 플러그인.
    13	
    14	set -euo pipefail
    15	
    16	TPL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    17	SRC="$TPL_ROOT/template/.claude"
    18	
    19	PROJECT_ARG="${1:?사용법: install.sh <프로젝트-경로> [프로젝트-이름]}"
    20	PROJECT="$(cd "$PROJECT_ARG" && pwd)"
    21	NAME="${2:-$(basename "$PROJECT")}"
    22	DST="$PROJECT/.claude"
    23	TODAY="$(date +%Y-%m-%d)"
    24	STAMP="$(date +%Y%m%d-%H%M%S)"   # 백업용 — 같은 날 재설치해도 안 덮이게
    25	
    26	echo "== 하네스 설치: $NAME"
    27	echo "   템플릿: $TPL_ROOT"
    28	echo "   대상:   $DST"
    29	
    30	# ── 1) 글루 복사 (덮어씀) ─────────────────────────────────────────────
    31	mkdir -p "$DST/agents" "$DST/skills" "$DST/hooks" "$DST/harness"
    32	cp "$SRC/agents/"*.md "$DST/agents/"
    33	# 스킬은 디렉토리째 전부 복사한다(references/·scripts/ 포함) — 특정 스킬명·특정 파일만
    34	# 복사하는 하드코딩은 readable-writing 미배포 버그(2026-08-03 점검)를 낳았다
    35	skill_count=0
    36	for skill_dir in "$SRC/skills/"*/; do
    37	  skill_name="$(basename "$skill_dir")"
    38	  mkdir -p "$DST/skills/$skill_name"
    39	  cp -R "$skill_dir"/. "$DST/skills/$skill_name/"
    40	  skill_count=$((skill_count + 1))
    41	done
    42	# ── 1a) 훅 교체는 파일 단위가 아니라 **디렉터리 rename 스왑** ────────
    43	#
    44	# 훅을 하나씩 덮으면 신·구가 섞인 중간 상태가 **반드시** 존재한다. 순서를 바꿔도 못
    45	# 막는다 — 훅들이 _common.sh 를 공유하므로 어느 쪽을 먼저 바꾸든 창이 열린다. 그 창에서
    46	# Claude 세션이 훅을 부르면 새 훅이 옛 _common.sh 를(또는 그 반대를) 읽는다.
    47	#
    48	# 그래서 스테이징 디렉터리를 만들고 **rename 2회**로 바꾼다. 혼합 상태가 원리적으로
    49	# 불가능해진다. 대신 두 rename 사이에 훅이 **없는** 창이 생기는데, 그건 잘못된 훅이
    50	# 도는 것보다 낫다(없으면 게이트가 안 설 뿐, 틀린 판정을 내지 않는다).
    51	#
    52	# 파생 계약 셋 — 전부 앞선 검수에서 **직전 수정이 만든 결함**으로 드러난 것들이다:
    53	#   1. 신호 핸들러는 복구 후 **실제로 종료**해야 한다. 반환만 하면 후속 명령이 계속 돌아
    54	#      mv 가 기존 디렉터리 **안으로** 중첩되고, 그러고도 "설치 성공"을 보고한다.
    55	#      그리고 그 exit 에 도달하려면 핸들러 진입 직후 `set +e` 가 필요하다 — 진단 echo
    56	#      하나가 실패해도(stderr 가 닫힌 채 실행 등) set -e 가 exit 전에 죽인다.
    57	#   2. 백업 이름은 `mktemp -d` 로 유일성을 보장한다. `$$` 는 PID 재사용으로 선점될 수 있고,
    58	#      선점되면 훅이 hooks/hooks/*.sh 로 깨지는데 메시지는 "되돌렸습니다"라고 말한다.
    59	#   3. 자리를 비우려고 `rmdir` 을 먼저 하지 않는다 — 그 사이가 TOCTOU 창이다.
    60	#      중첩을 **의도된 계약**으로 명시하면(mv "$DST/hooks" "$backup/hooks") 창이 없어진다.
    61	#
    62	# 남는 창(공시): 복구 **자체**가 다시 중단되면(SIGKILL·전원 차단) 훅 디렉터리가 없는
    63	# 상태로 남는다. install.sh 재실행이 복구하지만 그 재실행도 중단되면 같은 상태가
    64	# 반복된다. 이 창은 닫히지 않았다 — 닫으려면 이 스크립트 밖의 장치가 필요하다.
    65	if [ -L "$DST/hooks" ]; then
    66	  # 사용자가 훅 디렉터리를 심볼릭 링크로 두었다. rename 스왑은 그 링크를 **일반
    67	  # 디렉터리로 갈아치운다** — 사용자의 배치를 하네스가 마음대로 바꾸는 것이라 하지 않는다.
    68	  # 파일 단위 복사로 물러서고, 원자성을 못 지킨다는 사실을 **알린다**(조용히 물러서지 않는다).
    69	  echo "   ⚠ .claude/hooks 가 심볼릭 링크입니다 — 링크를 보존하려고 파일 단위로 복사합니다." >&2
    70	  echo "     교체 도중 신·구가 섞이는 창이 열립니다. 설치 중에는 Claude 세션을 띄우지 마세요." >&2
    71	  cp "$SRC/hooks/"*.sh "$DST/hooks/"
    72	  chmod +x "$DST/hooks/"*.sh
    73	else
    74	  hooks_stage="$(mktemp -d "$DST/.hooks-stage.XXXXXX")"
    75	  hooks_backup="$(mktemp -d "$DST/.hooks-old.XXXXXX")"
    76	  hooks_swapped=0     # 0=아직 안 옮김  1=옛것을 치웠고 새것은 아직 안 들어옴
    77	  cp "$SRC/hooks/"*.sh "$hooks_stage/"
    78	  chmod +x "$hooks_stage/"*.sh
    79	
    80	  on_swap_signal() {   # $1=신호 이름  $2=종료 코드
    81	    set +e             # 보고는 최선 노력, **종료 코드가 계약**이다
    82	    if [ "$hooks_swapped" -eq 1 ] && [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
    83	      mv "$hooks_backup/hooks" "$DST/hooks"
    84	      echo "[$1] 훅 교체 도중 중단 — 구판으로 되돌렸습니다." >&2
    85	    else
    86	      echo "[$1] 중단되었습니다 (훅 교체는 시작 전이거나 이미 끝났습니다)." >&2
    87	    fi
    88	    rm -rf "$hooks_stage" "$hooks_backup"
    89	    exit "$2"
    90	  }
    91	  # QUIT·HUP 도 잡는다: bash 는 trap 이 없으면 QUIT 를 **무시하고 rc=0 을 낸다** —
    92	  # 중단됐는데 "성공"으로 보고되는 최악의 조합이다(실측).
    93	  trap 'on_swap_signal INT  130' INT
    94	  trap 'on_swap_signal TERM 143' TERM
    95	  trap 'on_swap_signal QUIT 131' QUIT
    96	  trap 'on_swap_signal HUP  129' HUP
    97	
    98	  if [ -d "$DST/hooks" ]; then
    99	    mv "$DST/hooks" "$hooks_backup/hooks"   # 중첩은 사고가 아니라 계약이다
   100	    hooks_swapped=1
   101	  fi
   102	  if ! mv "$hooks_stage" "$DST/hooks"; then
   103	    # rename2 실패. **성공으로 오진단하지 않는다** — 되돌리고 실패로 끝낸다.
   104	    if [ "$hooks_swapped" -eq 1 ] && [ -d "$hooks_backup/hooks" ]; then
   105	      mv "$hooks_backup/hooks" "$DST/hooks" && echo "   구판 훅으로 되돌렸습니다." >&2
   106	    fi
   107	    rm -rf "$hooks_stage" "$hooks_backup"
   108	    echo "✗ 훅 디렉터리를 교체하지 못했습니다: $DST/hooks" >&2
   109	    exit 1
   110	  fi
   111	  hooks_swapped=0
   112	  trap - INT TERM QUIT HUP     # 여기부터는 되돌릴 것이 없다
   113	  rm -rf "$hooks_backup"
   114	fi
   115	hook_count="$(ls "$DST/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
   116	
   117	cp "$SRC/harness/principles.md" "$DST/harness/"
   118	echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 $hook_count · 제0원칙"
   119	
   120	# ── 1b) 전역 에이전트 배포 (~/.claude/agents/ — 프로젝트 무관 글루, 덮어씀) ──
   121	# 정본은 이 repo의 global-agents/ (전역 디렉토리는 버전 관리가 안 되므로 — ADR-0002)
   122	GLOBAL_SRC="$TPL_ROOT/global-agents"
   123	if [ -d "$GLOBAL_SRC" ] && ls "$GLOBAL_SRC"/*.md >/dev/null 2>&1; then
   124	  mkdir -p "$HOME/.claude/agents"
   125	  cp "$GLOBAL_SRC"/*.md "$HOME/.claude/agents/"
   126	  echo "   전역 에이전트 ✓  $(ls "$GLOBAL_SRC"/*.md | wc -l | tr -d ' ')종 → ~/.claude/agents/"
   127	fi
   128	
   129	# ── 2) 슬롯 스캐폴드 (없을 때만 — 도메인은 사용자가 채운다) ──────────
   130	if [ ! -f "$DST/harness/project-profile.md" ]; then
   131	  sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
   132	    > "$DST/harness/project-profile.md"
   133	  echo "   슬롯 생성 ✓  harness/project-profile.md   ← §1~§8 채우세요"
   134	else
   135	  echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
   136	fi
   137	if [ ! -f "$DST/harness/harness.env" ]; then
   138	  cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
   139	  echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
   140	  echo "                                                 (HARNESS_KNOWLEDGE_GATE 는 기본 켜짐)"
   141	else
   142	  echo "   슬롯 보존    harness/harness.env          (기존 유지)"
   143	fi
   144	
   145	# ── 3) settings.json 병합 (기존 훅 보존) ────────────────────────────
   146	if [ -f "$DST/settings.json" ]; then
   147	  cp "$DST/settings.json" "$DST/settings.json.bak-$STAMP"
   148	  echo "   settings 백업 → settings.json.bak-$STAMP"
   149	fi
   150	python3 - "$DST/settings.json" "$SRC/settings.json" <<'PYEOF'
   151	import json, os, sys
   152	dst_path, src_path = sys.argv[1], sys.argv[2]
   153	with open(src_path) as f:
   154	    ours = json.load(f)
   155	cur = {}
   156	if os.path.exists(dst_path):
   157	    with open(dst_path) as f:
   158	        cur = json.load(f)
   159	hooks = cur.setdefault("hooks", {})
   160	added = 0
   161	for event, entries in ours.get("hooks", {}).items():
   162	    lst = hooks.setdefault(event, [])
   163	    existing_cmds = {
   164	        (entry.get("matcher"), h.get("command"))
   165	        for entry in lst
   166	        for h in entry.get("hooks", [])
   167	    }
   168	    for entry in entries:
   169	        # (matcher, command) 단위 병합 — "항목에 하나라도 있으면 전체 스킵"은 같은 항목에 묶인
   170	        # 새 훅(guard-codex-invocation)이 기존 설치본에 영영 배선되지 않는 버그였고(2026-08-03),
   171	        # command만 보면 엉뚱한 matcher에 붙은 훅을 "배선됨"으로 오인한다([cx] 지적).
   172	        missing = [h for h in entry.get("hooks", [])
   173	                   if (entry.get("matcher"), h.get("command")) not in existing_cmds]
   174	        if not missing:
   175	            continue  # 전부 배선됨 (멱등)
   176	        target = next((e for e in lst if e.get("matcher") == entry.get("matcher")), None)
   177	        if target is not None:
   178	            target.setdefault("hooks", []).extend(missing)
   179	        else:
   180	            new_entry = {k: v for k, v in entry.items() if k != "hooks"}
   181	            new_entry["hooks"] = missing
   182	            lst.append(new_entry)
   183	        added += len(missing)
   184	        existing_cmds.update((entry.get("matcher"), h.get("command")) for h in missing)
   185	with open(dst_path, "w") as f:
   186	    json.dump(cur, f, ensure_ascii=False, indent=2)
   187	    f.write("\n")
   188	print(f"   settings.json ✓  훅 배선 {added}건 추가 (기존 훅 보존)")
   189	PYEOF
   190	
   191	# ── 4) CLAUDE.md 하네스 포인터 ───────────────────────────────────────
   192	if [ -f "$PROJECT/CLAUDE.md" ] && grep -q "harness-orchestrator" "$PROJECT/CLAUDE.md"; then
   193	  echo "   CLAUDE.md    포인터 이미 있음 (생략)"
   194	else
   195	  { [ -f "$PROJECT/CLAUDE.md" ] && [ -s "$PROJECT/CLAUDE.md" ] && echo ""; \
   196	    sed -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{YYYY-MM-DD}}/$TODAY/g" \
   197	        -e "s/{{한 줄 목표}}/($NAME 프로필 §1 참조)/g" \
   198	        "$TPL_ROOT/template/CLAUDE.md.snippet"; } >> "$PROJECT/CLAUDE.md"
   199	  echo "   CLAUDE.md ✓  하네스 포인터 append"
   200	fi
   201	
   202	echo ""
   203	echo "== 완료. 다음 단계:"
   204	echo "   1. $DST/harness/project-profile.md 의 §1~§8 채우기 (도메인 슬롯)"
   205	echo "   2. $DST/harness/harness.env 의 HARNESS_TYPECHECK_CMD 채우기"
   206	echo "   3. 새 Claude Code 세션 시작 (훅은 세션 시작 시 스냅샷 — 이번 세션엔 발화 안 함)"
   207	echo "   4. 개발 요청 → harness-orchestrator 스킬이 파이프라인 실행"
     1	#!/usr/bin/env bash
     2	# sync.sh — 템플릿 최신본을 받아 프로젝트의 글루만 갱신한다. 슬롯은 절대 안 건드린다.
     3	#
     4	# 사용법: ./sync.sh <프로젝트-경로> [--no-pull]
     5	#   --no-pull : 원격에서 안 당기고 로컬 정본만으로 갱신
     6	#
     7	# 원리: install.sh 가 멱등(글루=덮어씀, 슬롯=보존)이므로, pull 후 재실행이 곧 sync다.
     8	# 적용 전에 무엇이 바뀌는지 diff 요약을 먼저 보여준다.
     9	
    10	set -euo pipefail
    11	
    12	TPL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    13	SRC="$TPL_ROOT/template/.claude"
    14	
    15	PROJECT_ARG="${1:?사용법: sync.sh <프로젝트-경로> [--no-pull]}"
    16	PROJECT="$(cd "$PROJECT_ARG" && pwd)"
    17	DST="$PROJECT/.claude"
    18	
    19	# ── 1) 정본 갱신 ─────────────────────────────────────────────────────
    20	if [ "${2:-}" != "--no-pull" ] && git -C "$TPL_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    21	  if git -C "$TPL_ROOT" pull --ff-only 2>/dev/null; then
    22	    echo "== 템플릿 정본 pull 완료"
    23	  else
    24	    echo "== pull 실패(원격 없음/오프라인/충돌) — 로컬 정본으로 진행"
    25	  fi
    26	fi
    27	
    28	# ── 2) 글루 diff 미리보기 (슬롯은 비교 대상에서 제외) ───────────────
    29	echo "== 갱신될 글루 diff:"
    30	changed=0
    31	preview() {  # preview <원본> <대상>
    32	  if [ ! -f "$2" ]; then
    33	    echo "   [신규] ${2#"$DST"/}"
    34	    changed=$((changed + 1))
    35	  elif ! diff -q "$1" "$2" >/dev/null 2>&1; then
    36	    echo "   [변경] ${2#"$DST"/}"
    37	    changed=$((changed + 1))
    38	  fi
    39	}
    40	for f in "$SRC/agents/"*.md; do preview "$f" "$DST/agents/$(basename "$f")"; done
    41	for d in "$SRC/skills/"*/; do
    42	  while IFS= read -r f; do preview "$f" "$DST/skills/$(basename "$d")/${f#"$d"}"; done < <(find "$d" -type f)
    43	done
    44	for f in "$SRC/hooks/"*.sh; do preview "$f" "$DST/hooks/$(basename "$f")"; done
    45	preview "$SRC/harness/principles.md" "$DST/harness/principles.md"
    46	for f in "$TPL_ROOT/global-agents/"*.md; do [ -f "$f" ] && preview "$f" "$HOME/.claude/agents/$(basename "$f")"; done
    47	
    48	# settings.json 훅 배선 확인 — 파일 diff만 보면 "글루는 같은데 배선만 누락"(신규 훅이
    49	# 기존 항목에 묶여 스킵된 경우)을 놓쳐 install이 아예 안 돌았다(2026-08-03 점검).
    50	if [ -f "$DST/settings.json" ]; then
    51	  # 텍스트 grep이 아니라 JSON 파싱으로 비교한다 — 파일 속 명령은 \" 이스케이프돼 있어
    52	  # 문자열 비교는 전부 누락으로 오탐한다(구현 중 테스트에서 확인).
    53	  while IFS= read -r cmd; do
    54	    [ -z "$cmd" ] && continue
    55	    echo "   [배선 누락] settings.json ← $cmd"
    56	    changed=$((changed + 1))
    57	  done < <(python3 -c '
    58	import json, sys
    59	with open(sys.argv[1]) as f: ours = json.load(f)
    60	with open(sys.argv[2]) as f: cur = json.load(f)
    61	# (event, matcher, command) 단위 비교 — command만 보면 엉뚱한 이벤트/매처에 붙은
    62	# 훅을 "배선됨"으로 오인해 조기 종료한다([cx] 지적).
    63	have = {(ev, e.get("matcher"), h.get("command"))
    64	        for ev, entries in cur.get("hooks", {}).items()
    65	        for e in entries for h in e.get("hooks", [])}
    66	for ev, entries in ours.get("hooks", {}).items():
    67	    for e in entries:
    68	        for h in e.get("hooks", []):
    69	            if (ev, e.get("matcher"), h.get("command")) not in have:
    70	                print(ev + ": " + h.get("command", ""))' "$SRC/settings.json" "$DST/settings.json")
    71	else
    72	  echo "   [신규] settings.json 배선"
    73	  changed=$((changed + 1))
    74	fi
    75	
    76	# 기존 설치본의 harness.env 에는 나중에 생긴 슬롯 키가 없다. **있는 값은 안 건드리되
    77	# 없는 키는 알려준다** — 키가 없어도 기본값(켜짐)으로 동작하지만, 파일에 한 줄도 없으면
    78	# 사용자는 그런 스위치가 있다는 것 자체를 모른다.
    79	add_gate_key=0
    80	if [ -f "$DST/harness/harness.env" ] \
    81	   && ! grep -qE '^(export[[:space:]]+)?HARNESS_KNOWLEDGE_GATE=' "$DST/harness/harness.env" 2>/dev/null; then
    82	  echo "   [슬롯 키 추가] harness/harness.env ← HARNESS_KNOWLEDGE_GATE (기본 켜짐, 기존 값 보존)"
    83	  add_gate_key=1
    84	  changed=$((changed + 1))
    85	fi
    86	
    87	if [ "$changed" -eq 0 ]; then
    88	  echo "   (변경 없음 — 이미 최신)"
    89	  exit 0
    90	fi
    91	
    92	# ── 3) 적용 (install.sh 멱등 재실행 — 슬롯·CLAUDE.md·settings는 보존/생략됨) ──
    93	echo ""
    94	"$TPL_ROOT/install.sh" "$PROJECT"
    95	
    96	# 슬롯 키 덧붙이기 — install.sh **뒤**다. install 이 harness.env 를 새로 만들었다면
    97	# 템플릿에 이미 키가 들어 있어 여기 올 일이 없다(위 판정은 install 이전 상태를 봤다).
    98	#
    99	# **덧붙이기만 한다.** 임시 파일에 쓰고 rename 하는 "원자적 쓰기"를 쓰지 않는 것은
   100	# 의도적이다 — 그 방식은 검수에서 두 가지 계약 위반을 냈다. 임시 파일 글롭이 사용자의
   101	# 백업 파일까지 지웠고, 기존 harness.env 가 심볼릭 링크면 일반 파일로 갈아치웠다.
   102	# 슬롯은 프로젝트 소유이고 하네스는 그것을 **절대 덮지 않는다**가 더 강한 계약이다.
   103	#
   104	# 대가: append 는 원자적이지 않다. 중간에 끊기면 줄이 잘릴 수 있다. 다만 그 방향은
   105	# 안전하다 — 판독이 실패하면 게이트는 **켜진다**(기본값 보존). 그래서 덧붙인 뒤
   106	# 실제로 읽히는지 확인하고, 안 읽히면 조용히 넘어가지 않고 알린다.
   107	if [ "$add_gate_key" -eq 1 ]; then
   108	  envf="$DST/harness/harness.env"
   109	  if { printf '\n# 지식 반영 게이트 (하네스가 나중에 추가한 슬롯). 끄려면 값을 비운다 —\n# "off" 라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다. 이 줄이 없어도 켜짐이다.\nHARNESS_KNOWLEDGE_GATE="on"\n' >> "$envf"; } 2>/dev/null \
   110	     && grep -qE '^HARNESS_KNOWLEDGE_GATE=' "$envf" 2>/dev/null; then
   111	    echo "   슬롯 키 추가 ✓  harness/harness.env  HARNESS_KNOWLEDGE_GATE=\"on\""
   112	  else
   113	    echo "   ⚠ harness/harness.env 에 HARNESS_KNOWLEDGE_GATE 를 추가하지 못했습니다(권한·디스크)." >&2
   114	    echo "     동작은 그대로입니다(키가 없으면 켜짐). 손으로 넣으려면 위 한 줄을 추가하세요." >&2
   115	  fi
   116	fi
   117	
   118	echo ""
   119	echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)의 **값**은 그대로입니다."
     1	#!/usr/bin/env bash
     2	# check-layer-boundary.sh — 하네스 글루에 **상위 층 구현**이 새면 종료 코드 1.
     3	#
     4	# 층은 셋이고, 각자 따로 설치돼도 돌아가야 한다는 것이 요구다.
     5	#
     6	#   상위 ┃ 지식 저장소   구현체. 하네스를 모른다
     7	#   접착 ┃ 사용자 층     전역 CLAUDE.md — 어느 저장소를 쓰는지는 여기서만 안다
     8	#   하위 ┃ 하네스        계약만 소유. "설정돼 있으면 반영 없이 끝낼 수 없다"
     9	#
    10	# 소유권이 **하위**에 있는 게 핵심이다. 반대로 두면 인터페이스를 알기 위해 상위가
    11	# 있어야 해서 단독 작동이 깨진다. 그런데 완료를 강제하는 기계가 하네스뿐이라, 갈 곳이
    12	# 없는 상위 층 지식이 자꾸 글루로 흘러든다 — 실제로 13곳까지 샜었다.
    13	#
    14	# **이 경계는 grep 으로 판정 가능하다.** 조회 라우팅 같은 "행동"과 달리 "글루에 상위 층
    15	# 구현이 적혀 있나"는 기계가 100% 답한다. 그래서 산문 규칙으로 두지 않는다 —
    16	# 산문 규칙은 어겨지고, 어겨져도 아무것도 안 깨져서 아무도 모른다.
    17	#
    18	# 이 검사는 README 가 선언한 **"도메인 누출 0"을 처음으로 기계가 지키게 한다.**
    19	# 특정 저장소에 한정되지 않는다 — 어떤 상위 층 구현이든 같은 이유로 막힌다.
    20	#
    21	# ── 위양성 쪽으로 기운다 ─────────────────────────────────────────────
    22	# 관용구 패턴은 무관한 조합에도 걸릴 수 있다. 그 대가를 받아들인다 — 누출이 조용히
    23	# 통과하는 것보다 사람이 한 번 보고 문구를 고치는 편이 싸다. 걸렸는데 정당한 표현 같으면
    24	# **패턴을 좁히지 말고 그 문구를 계약 수준으로 다시 써라.** 그게 이 검사의 목적이다.
    25	#
    26	# 사용법: ./scripts/check-layer-boundary.sh
    27	# 회귀 테스트: ./tests/check-layer-boundary.test.sh (CI에서 이 검사보다 **먼저** 돈다)
    28	
    29	set -euo pipefail
    30	
    31	# CDPATH='' — CDPATH 가 설정된 셸에서 상대 경로로 부르면 cd 가 이동 경로를 stdout 에
    32	# 찍어 ROOT 가 두 줄이 된다(절대 경로 호출로는 재현 안 됨). 형제 검사기와 같은 처리.
    33	ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
    34	
    35	# 스캔 범위는 배포물뿐이다. install.sh/sync.sh 가 복사하는 것은 template/.claude/ 이고,
    36	# 범위를 넓히면 문서·ADR·테스트의 **정당한 인용**이 죄다 위양성이 된다 — 이 저장소의
    37	# ADR 은 무엇이 새어 있었는지 기록해야 하므로 그 표현을 반드시 담는다.
    38	# 회귀 테스트가 픽스처 트리를 겨누려고 이 값을 덮는다. 그 외에는 덮지 마라.
    39	SCAN_ROOT="${HARNESS_LAYER_SCAN_ROOT:-$ROOT/template}"
    40	
    41	if [ ! -d "$SCAN_ROOT" ]; then
    42	  echo "✗ 스캔 범위가 디렉토리가 아닙니다: $SCAN_ROOT" >&2
    43	  exit 1
    44	fi
    45	
    46	WORK="$(mktemp -d)"
    47	if [ -z "$WORK" ] || [ ! -d "$WORK" ]; then
    48	  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2
    49	  exit 1
    50	fi
    51	trap 'rm -rf "$WORK"' EXIT
    52	
    53	# ── 금지 표현 ─────────────────────────────────────────────────────────
    54	# 한 줄에 `ERE 패턴<TAB>왜 상위 층인가`. 메시지가 있어야 걸린 사람이 무엇을 계약 수준으로
    55	# 다시 써야 하는지 안다. "금지됐다"만 알려주는 검사는 우회당한다.
    56	# 히어독을 **인용**한다(<<'PATTERNS'): 패턴 안의 $ · 백슬래시가 셸에 먹히면 안 된다.
    57	PATTERNS_FILE="$WORK/patterns"
    58	cat > "$PATTERNS_FILE" <<'PATTERNS'
    59	second[ -]brain	특정 지식 저장소의 이름. 하네스는 저장소가 무엇인지 몰라야 한다
    60	[Oo]bsidian	특정 도구 이름. 저장소를 바꾸면 이 문구가 거짓이 된다
    61	볼트	특정 지식 저장소의 이름
    62	_CLAUDE\.md	상위 층 저장소 안의 파일 이름. 그 파일이 없는 환경에서는 지킬 수 없는 요구가 된다
    63	4종 세트	상위 층이 지식을 어느 파일로 나눠 담는지의 구조. 하네스가 알 필요 없다
    64	discussion-log	상위 층 저장소의 파일 이름
    65	Projects/<name>	상위 층 저장소의 폴더 구조
    66	needs-vault	구현체 이름이 붙은 플래그. 계약 이름(.needs-knowledge)을 써라
    67	PATTERNS
    68	
    69	# ── 사전 조건: 스캔할 수 없는 대상이 있으면 결과 전체를 믿을 수 없다 ──
    70	# 형제 검사기(check-rule-copies.sh)의 ①②③ 과 같은 층위다. 심링크가 있으면 grep -r 은
    71	# 건너뛰는데 install.sh 의 cp 는 실체를 배포한다 — 검사되지 않은 파일이 배포되는 창이
    72	# 열린다. NUL 보유 파일은 토큰 바이트열이 원리적으로 안 보인다(UTF-16 도 같은 층위).
    73	#
    74	# find -print0 을 **파일로 받는다.** 명령 치환으로 받으면 셸이 NUL 을 버려 루프가 한 번도
    75	# 안 돌고, 검사기는 "위반 0건"으로 초록불을 낸다.
    76	FILES="$WORK/files"
    77	find "$SCAN_ROOT" -print0 > "$FILES"
    78	
    79	bad_pre=0
    80	while IFS= read -r -d '' p; do
    81	  if [ -L "$p" ]; then
    82	    echo "✗ 심링크가 스캔 범위 안에 있습니다: ${p#"$SCAN_ROOT"/}" >&2
    83	    bad_pre=1
    84	    continue
    85	  fi
    86	  [ -f "$p" ] || continue
    87	  if ! LC_ALL=C tr -d '\000' < "$p" | cmp -s - "$p"; then
    88	    echo "✗ NUL 바이트를 가진 파일이 있어 내용을 믿을 수 없습니다: ${p#"$SCAN_ROOT"/}" >&2
    89	    bad_pre=1
    90	  fi
    91	done < "$FILES"
    92	
    93	if [ "$bad_pre" -ne 0 ]; then
    94	  echo "" >&2
    95	  echo "스캔할 수 없는 대상이 트리에 있으면 그 트리에 대한 스캔 결과 전체를 믿을 수 없습니다." >&2
    96	  echo "제거한 뒤 다시 돌리세요." >&2
    97	  exit 1
    98	fi
    99	
   100	# ── 스캔 ─────────────────────────────────────────────────────────────
   101	# hits 를 파이프·서브셸 안에서 올리면 증가분이 부모로 안 돌아온다(서브셸 변수 누수).
   102	# 그래서 출력은 모아 두고 개수는 파일로 센다.
   103	REPORT="$WORK/report"
   104	: > "$REPORT"
   105	scanned=0
   106	
   107	while IFS= read -r -d '' f; do
   108	  [ -f "$f" ] || continue
   109	  scanned=$((scanned + 1))
   110	  rel="${f#"$SCAN_ROOT"/}"
   111	  while IFS="$(printf '\t')" read -r pat why; do
   112	    [ -n "$pat" ] || continue
   113	    # grep rc: 0=매치 1=무매치 **2 이상=오류**. `|| true` 로 뭉뚱그리면 읽기 실패까지
   114	    # 삼켜 스캔이 통째로 실패해도 조용히 초록이 된다.
   115	    set +e
   116	    out="$(grep -nE -- "$pat" "$f")"
   117	    rc=$?
   118	    set -e
   119	    if [ "$rc" -ge 2 ]; then
   120	      echo "✗ 스캔 실패(rc=$rc): $rel  패턴 [$pat]" >&2
   121	      exit 1
   122	    fi
   123	    if [ "$rc" -eq 0 ]; then
   124	      printf '%s\n' "$out" | sed "s|^|  $rel:|" >> "$REPORT"
   125	      printf '      ↑ %s\n' "$why" >> "$REPORT"
   126	    fi
   127	  done < "$PATTERNS_FILE"
   128	done < "$FILES"
   129	
   130	# 스캔 대상이 0개면 "0건 위반"을 찍고 통과한다 — 공허한 초록이다.
   131	# 배포물이 하나도 없을 리 없으므로 그건 범위 설정이 틀린 것이다.
   132	if [ "$scanned" -eq 0 ]; then
   133	  echo "✗ 스캔한 파일이 0개입니다: $SCAN_ROOT (범위 설정을 확인하세요)" >&2
   134	  exit 1
   135	fi
   136	
   137	if [ -s "$REPORT" ]; then
   138	  cat "$REPORT" >&2
   139	  echo "" >&2
   140	  echo "✗ 하네스 글루에 상위 층 구현이 샜습니다." >&2
   141	  echo "  계약만 남기고 구현은 사용자 층으로 옮기세요 — 하네스는 지식 저장소가" >&2
   142	  echo "  어디이고 어떤 구조인지 몰라야 그 저장소 없이도 돌아갑니다." >&2
   143	  exit 1
   144	fi
   145	
   146	echo "✓ 층 경계 유지 — 배포물 ${scanned}개에 상위 층 구현 0건"

2026-08-10T03:47:55.211559Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "nl -ba tests/harness-env-read.test.sh | sed -n '1,520p'
nl -ba tests/install-hook-swap.test.sh | sed -n '1,380p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# harness-env-read.test.sh — harness.env **원문 판독**의 회귀 테스트.
     3	#
     4	# 왜 있나 (2026-08-07 실사고): `harness.env` 를 source 하던 것을 원문 판독으로 바꿔
     5	# 임의 코드 실행 부류를 없앴는데, **셸이 대신 해주던 파싱을 물려받으면서** 새 fail-open
     6	# 6종이 생겼다. 후행 주석 · 후행 공백 · CRLF 의 `\r` · 파일 앞 BOM · 히어독 본문의 같은 키.
     7	# 앞 넷은 값에 쓰레기가 섞여 `sh -c` 가 rc=127 을 내고, 훅이 그걸 "도구가 없구나"로 읽어
     8	# **타입체크 게이트가 흔적 없이 사라진다.** 넷 중 둘(후행 공백·CR)은 눈에 보이지도 않는다.
     9	#
    10	# 무엇을 붙드나 — 두 층이다:
    11	#   [파서]   harness_env_value 의 반환 계약. rc(0=판독됨 / 1=믿을 수 없음)와 **값의 바이트**.
    12	#            rc 를 값과 함께 재는 이유: "리터럴로 비웠다"와 "미설정"은 스위치형 슬롯에서
    13	#            **반대 방향**이라 빈 문자열 하나로 뭉뚱그리면 그 구별이 사라진다.
    14	#   [통합]   verify-before-stop.sh 를 **실제로 돌려** ① 적대적 harness.env(exit 0/1·return·
    15	#            printf 재정의)가 나머지 게이트를 죽이지 못하는지 ② 후행 주석·CRLF·BOM 이 붙은
    16	#            명령이 **정말 실행되는지** 를 본다.
    17	#
    18	# 통합 케이스가 rc 만 보지 않는 이유: 타입체크를 건너뛰어도 뒤의 감사 게이트가 어차피
    19	# rc=2 로 막는다. 그래서 **어느 게이트가 막았는지의 문구**까지 재야 판별력이 생긴다.
    20	# rc 만 보면 파서를 통째로 되돌려도 전건 초록이다.
    21	#
    22	# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
    23	#
    24	# 이 파일 자신도 못 믿는다. 러너는 넷을 스스로 검사한다:
    25	#   1) CASES 목록의 개수·중복  2) 실행 수 vs 기대 수  3) pass+fail == ran  4) DID_RUN 센티널
    26	#
    27	# 환경 전제 (전부 fail-closed): python3 부재 → exit 1 (통합 케이스의 json_get 의존).
    28	# root 실행 → 읽기 권한 픽스처가 성립하지 않는다(root 는 -r 가 항상 참). 그 케이스만 실패.
    29	#
    30	# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
    31	#
    32	# 사용법: ./tests/harness-env-read.test.sh   (전건 통과 시 종료 코드 0)
    33	
    34	set -uo pipefail
    35	
    36	TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    37	REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
    38	COMMON="$REPO_ROOT/template/.claude/hooks/_common.sh"
    39	STOP_HOOK="$REPO_ROOT/template/.claude/hooks/verify-before-stop.sh"
    40	
    41	command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (Stop 훅의 json_get 의존)" >&2; exit 1; }
    42	[ -f "$COMMON" ]    || { echo "✗ _common.sh 를 찾지 못했습니다: $COMMON" >&2; exit 1; }
    43	[ -f "$STOP_HOOK" ] || { echo "✗ verify-before-stop.sh 를 찾지 못했습니다: $STOP_HOOK" >&2; exit 1; }
    44	
    45	# mktemp 실패를 확인하지 않으면 TMPROOT 가 빈 문자열이 되고 이후 경로가 전부
    46	# 파일시스템 **루트**를 가리킨다.
    47	TMPROOT="$(mktemp -d)" || exit 1
    48	if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
    49	  echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
    50	  exit 1
    51	fi
    52	TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
    53	# chmod 는 읽기 권한 케이스가 harness.env 를 000 으로 만들기 때문에 필요하다.
    54	trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT
    55	
    56	KEY='HARNESS_TYPECHECK_CMD'
    57	
    58	# 훅 문구가 다듬어져도 계약이 살아 있으면 계속 맞는 최소 조각.
    59	TOK_TC_FAIL='타입체크 실패'
    60	TOK_AUDIT='completion-auditor 미실행'
    61	TOK_READ_FAIL='읽지 못했습니다'   # _common.sh 가 stderr 로 내는 읽기 실패 경고
    62	TOK_UNREADABLE='읽지 못함'        # Stop 훅이 사용자에게 내는 생략 사유
    63	TOK_EMPTY_SET='빈 값으로 설정됨'
    64	TOK_KNOWLEDGE='지식 저장소 반영 미확인'
    65	GKEY='HARNESS_KNOWLEDGE_GATE'
    66	
    67	# --- 픽스처 --------------------------------------------------------------
    68	
    69	# new_project <harness.env 내용|__NOFILE__> — 훅 2개를 설치한 가짜 프로젝트를 만들고
    70	# 그 경로를 낸다. 내용은 **바이트 그대로** 쓴다(printf '%s' — 이스케이프 재해석 없음).
    71	# 호출부가 $'...' 로 CR·탭·BOM 을 정확히 지정한다. %b 를 쓰면 이 테스트가 붙들려는
    72	# 바로 그 축(보이지 않는 바이트)이 러너 안에서 조용히 변조된다.
    73	new_project() {
    74	  local body="$1" p
    75	  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || { FIXTURE_FAIL='임시 디렉토리 생성 실패'; return 1; }
    76	  p="$(CDPATH='' cd -- "$p" && pwd -P)"
    77	  if ! mkdir -p "$p/.claude/hooks" "$p/.claude/harness" 2>/dev/null; then
    78	    FIXTURE_FAIL="프로젝트 골격을 만들지 못했다: $p"; return 1
    79	  fi
    80	  cp "$COMMON"    "$p/.claude/hooks/_common.sh"            || { FIXTURE_FAIL='_common.sh 복사 실패'; return 1; }
    81	  cp "$STOP_HOOK" "$p/.claude/hooks/verify-before-stop.sh" || { FIXTURE_FAIL='Stop 훅 복사 실패'; return 1; }
    82	  if [ "$body" != '__NOFILE__' ]; then
    83	    if ! { printf '%s' "$body" > "$p/.claude/harness/harness.env"; } 2>/dev/null; then
    84	      FIXTURE_FAIL='harness.env 를 쓰지 못했다'; return 1
    85	    fi
    86	  fi
    87	  printf '%s\n' "$p"
    88	}
    89	
    90	# --- 실행 헬퍼 -----------------------------------------------------------
    91	
    92	VAL=''; VRC=999; VERR=''
    93	HRC=999; HOUT=''; HERR=''
    94	DID_RUN=0        # 이번 케이스에서 실제로 돌렸는가 — 직전 케이스 결과 재판정 방지 센티널
    95	FIXTURE_FAIL=''
    96	
    97	# read_value <proj> — harness_env_value 를 부르고 VAL(바이트 보존)·VRC·VERR 을 채운다.
    98	# 센티널 X 를 붙여 받는 이유: 명령 치환이 후행 개행·공백을 지우면 "값이 그렇게 끝났다"와
    99	# "치환이 먹었다"가 구분되지 않는다. 이 테스트가 붙들려는 결함이 정확히 그 부류다.
   100	# 앰비언트 탈출구를 소거한다 — 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off 를
   101	# export 한 셸에서 돌기 때문이다. 소거하지 않으면 통합 행이 통째로 무판정이 된다.
   102	read_value() {
   103	  local proj="$1" raw errf="$TMPROOT/verr.$$"
   104	  VAL=''; VRC=999; VERR=''; DID_RUN=1
   105	  raw="$(env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
   106	         bash -c '
   107	           . "$0/.claude/hooks/_common.sh"
   108	           harness_env_value "$1"; rc=$?
   109	           printf X
   110	           exit $rc
   111	         ' "$proj" "$KEY" 2>"$errf")"
   112	  VRC=$?
   113	  VAL="${raw%X}"
   114	  VERR="$(cat "$errf" 2>/dev/null)"
   115	  rm -f "$errf"
   116	}
   117	
   118	# run_stop_hook <proj> [env 인자...] — 감사 플래그 **하나만** 세우고 Stop 훅을 돌린다.
   119	# 하나만 세우는 것이 계약이다: 넷 다 세우면 앞선 게이트(듀얼리뷰·설명)가 먼저 막아
   120	# 타입체크 축이 문구로도 안 보인다.
   121	run_stop_hook() {
   122	  local proj="$1" errf="$TMPROOT/herr.$$"
   123	  shift
   124	  HRC=999; HOUT=''; HERR=''; DID_RUN=1
   125	  printf 'gate-target.ts\n' > "$proj/.claude/.needs-audit"
   126	  _invoke_stop_hook "$proj" "$errf" ${@+"$@"}
   127	}
   128	
   129	# run_knowledge_probe <proj> — **지식 플래그 하나만** 세우고 Stop 훅을 돌린다.
   130	# 게이트가 켜졌으면 지식 게이트 문구로 rc=2, 꺼졌으면 할 일이 없어 rc=0 이다.
   131	#
   132	# 이 프로브는 harness.env 의 키 개수와 값을 **직접 해석하지 않는다.** 판독 규칙의 사본을
   133	# 테스트에 두면 그 사본이 언젠가 원본과 어긋나고, 그때 테스트는 **틀린 기준으로 초록**을
   134	# 낸다. 훅 자신을 돌려 차단되는지만 본다.
   135	run_knowledge_probe() {
   136	  local proj="$1" errf="$TMPROOT/kerr.$$"
   137	  shift
   138	  HRC=999; HOUT=''; HERR=''; DID_RUN=1
   139	  printf 'gate-target.ts\n' > "$proj/.claude/.needs-knowledge"
   140	  _invoke_stop_hook "$proj" "$errf" ${@+"$@"}
   141	}
   142	
   143	_invoke_stop_hook() {
   144	  local proj="$1" errf="$2"
   145	  shift 2
   146	  HOUT="$(printf '{"stop_hook_active": false}' \
   147	          | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
   148	                bash "$proj/.claude/hooks/verify-before-stop.sh" 2>"$errf")"
   149	  HRC=$?
   150	  HERR="$(cat "$errf" 2>/dev/null)"
   151	  rm -f "$errf"
   152	}
   153	
   154	# --- 판정 헬퍼 -----------------------------------------------------------
   155	
   156	ran=0; pass=0; fail=0
   157	
   158	report() {
   159	  local name="$1" why="$2"
   160	  if [ -z "$why" ]; then
   161	    pass=$((pass + 1)); printf '  ✓ %s\n' "$name"
   162	  else
   163	    fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$name" "$why"
   164	  fi
   165	}
   166	
   167	# pcase <이름> <기대rc> <기대값> <harness.env 내용> [기대 stderr 조각]
   168	# 기대값은 **바이트 그대로** 비교한다.
   169	pcase() {
   170	  local name="$1" want_rc="$2" want_val="$3" body="$4" want_err="${5-}" proj why=''
   171	  if ! proj="$(new_project "$body")"; then
   172	    report "$name" "픽스처 구성 실패: $FIXTURE_FAIL"; return 0
   173	  fi
   174	  read_value "$proj"
   175	  if [ "$DID_RUN" -ne 1 ]; then
   176	    why='판독을 실행하지 않았다 (직전 케이스 결과를 재판정할 뻔했다)'
   177	  elif [ "$VRC" -ne "$want_rc" ]; then
   178	    why="rc=$VRC (기대 $want_rc), 값=[$VAL]"
   179	  elif [ "$VAL" != "$want_val" ]; then
   180	    why="값=[$VAL] (기대 [$want_val])"
   181	  elif [ -z "$want_err" ] && [ -n "$VERR" ]; then
   182	    why="stderr 가 비어 있지 않다: [$VERR]"
   183	  elif [ -n "$want_err" ]; then
   184	    case "$VERR" in
   185	      *"$want_err"*) ;;
   186	      *) why="stderr 에 기대 문구가 없다: $want_err (실제 [$VERR])" ;;
   187	    esac
   188	  fi
   189	  report "$name" "$why"
   190	}
   191	
   192	# gcase <이름> <on|off> <harness.env 내용> — 지식 게이트가 켜졌는지 훅으로 잰다.
   193	#   on  → rc=2 이고 지식 게이트 문구가 나온다
   194	#   off → rc=0 이고 stderr 가 비어 있다 (할 일이 없어 조기 종료)
   195	gcase() {
   196	  local name="$1" want="$2" body="$3" proj why=''
   197	  if ! proj="$(new_project "$body")"; then
   198	    report "$name" "픽스처 구성 실패: $FIXTURE_FAIL"; return 0
   199	  fi
   200	  run_knowledge_probe "$proj"
   201	  if [ "$DID_RUN" -ne 1 ]; then
   202	    why='훅을 실행하지 않았다'
   203	  elif [ "$want" = 'on' ]; then
   204	    if [ "$HRC" -ne 2 ]; then
   205	      why="게이트가 켜져야 하는데 rc=$HRC (기대 2) / stderr=[$(printf '%s' "$HERR" | head -c 200)]"
   206	    else
   207	      case "$HERR" in
   208	        *"$TOK_KNOWLEDGE"*) ;;
   209	        *) why="지식 게이트가 아닌 다른 이유로 막았다: [$(printf '%s' "$HERR" | head -c 200)]" ;;
   210	      esac
   211	    fi
   212	  else
   213	    if [ "$HRC" -ne 0 ]; then
   214	      why="게이트가 꺼져야 하는데 rc=$HRC / stderr=[$(printf '%s' "$HERR" | head -c 200)]"
   215	    elif [ -n "$HERR" ]; then
   216	      why="꺼진 게이트가 stderr 를 냈다: [$(printf '%s' "$HERR" | head -c 200)]"
   217	    fi
   218	  fi
   219	  report "$name" "$why"
   220	}
   221	
   222	# hcase <이름> <기대rc> <있어야 할 문구> <있으면 안 되는 문구|-> <내용> [env 인자...]
   223	hcase() {
   224	  local name="$1" want_rc="$2" want="$3" forbid="$4" body="$5" proj why=''
   225	  shift 5
   226	  if ! proj="$(new_project "$body")"; then
   227	    report "$name" "픽스처 구성 실패: $FIXTURE_FAIL"; return 0
   228	  fi
   229	  run_stop_hook "$proj" ${@+"$@"}
   230	  if [ "$DID_RUN" -ne 1 ]; then
   231	    why='훅을 실행하지 않았다'
   232	  elif [ "$HRC" -ne "$want_rc" ]; then
   233	    why="종료 코드 $HRC (기대 $want_rc) / stderr=[$(printf '%s' "$HERR" | head -c 200)]"
   234	  else
   235	    case "$HERR" in
   236	      *"$want"*) ;;
   237	      *) why="stderr 에 기대 문구가 없다: $want (실제 [$(printf '%s' "$HERR" | head -c 300)])" ;;
   238	    esac
   239	    if [ -z "$why" ] && [ "$forbid" != '-' ]; then
   240	      case "$HERR" in
   241	        *"$forbid"*) why="stderr 에 있으면 안 되는 문구가 있다: $forbid" ;;
   242	      esac
   243	    fi
   244	  fi
   245	  report "$name" "$why"
   246	}
   247	
   248	# --- 파서 케이스 ---------------------------------------------------------
   249	# 기대 rc: 0 = 선언 1개를 지원 문법으로 판독함 / 1 = 값을 믿을 수 없음
   250	
   251	p01() { pcase '정상 — 겹따옴표'                       0 'printf ok' "$KEY=\"printf ok\""$'\n'; }
   252	p02() { pcase '정상 — 홑따옴표'                       0 'printf ok' "$KEY='printf ok'"$'\n'; }
   253	p03() { pcase '정상 — 인용 없는 한 단어'              0 'mypy'      "$KEY=mypy"$'\n'; }
   254	p04() { pcase '인용 없는 여러 단어'                   0 'pnpm tsc --noEmit' "$KEY=pnpm tsc --noEmit"$'\n'; }
   255	p05() { pcase 'export + 공백'                         0 'printf ok' "export $KEY=\"printf ok\""$'\n'; }
   256	p06() { pcase 'export + 탭'                           0 'printf ok' "export"$'\t'"$KEY=\"printf ok\""$'\n'; }
   257	p07() { pcase '선언 0개 — 키가 없다'                  1 ''          '# 아무 키도 없다'$'\n'; }
   258	p08() { pcase '선언 2개 — 어느 게 이기는지 모른다'    1 ''          "$KEY=\"a\""$'\n'"$KEY=\"b\""$'\n'; }
   259	p09() { pcase '들여쓴 위장(공백)은 선언이 아니다'     0 'printf ok' "  $KEY=\"evil\""$'\n'"$KEY=\"printf ok\""$'\n'; }
   260	p10() { pcase '들여쓴 위장(탭)만 있으면 미설정'       1 ''          $'\t'"$KEY=\"evil\""$'\n'; }
   261	p11() { pcase '접두사가 같은 다른 키는 안 센다'       0 'printf ok' "${KEY}_EXTRA=\"x\""$'\n'"$KEY=\"printf ok\""$'\n'; }
   262	p12() { pcase '접두사 키만 있으면 미설정'             1 ''          "${KEY}_EXTRA=\"x\""$'\n'; }
   263	p13() { pcase '주석 처리된 선언은 안 센다'            1 ''          "# $KEY=\"x\""$'\n'; }
   264	p14() { pcase '후행 주석 — 겹따옴표'                  0 'printf ok' "$KEY=\"printf ok\" # note"$'\n'; }
   265	p15() { pcase '후행 주석 — 홑따옴표'                  0 'printf ok' "$KEY='printf ok' # note"$'\n'; }
   266	p16() { pcase '후행 주석 — 인용 없음'                 0 'mypy'      "$KEY=mypy # note"$'\n'; }
   267	p17() { pcase '값 안의 # 은 주석이 아니다'            0 'a#b'       "$KEY=a#b"$'\n'; }
   268	p18() { pcase '값 자리가 통째로 주석'                 0 ''          "$KEY= # note"$'\n'; }
   269	p19() { pcase '후행 공백 (눈에 안 보인다)'            0 'printf ok' "$KEY=\"printf ok\"   "$'\n'; }
   270	p20() { pcase '후행 탭'                               0 'printf ok' "$KEY=\"printf ok\""$'\t\n'; }
   271	p21() { pcase 'CRLF 줄끝'                             0 'printf ok' "$KEY=\"printf ok\""$'\r\n'; }
   272	p22() { pcase 'CRLF + 후행 주석'                      0 'printf ok' "$KEY=\"printf ok\" # note"$'\r\n'; }
   273	p23() { pcase '파일 앞 BOM + 첫 줄이 선언'            0 'printf ok' $'\357\273\277'"$KEY=\"printf ok\""$'\n'; }
   274	p24() { pcase '파일 앞 BOM + 둘째 줄이 선언'          0 'printf ok' $'\357\273\277''# 주석'$'\n'"$KEY=\"printf ok\""$'\n'; }
   275	p25() { pcase '히어독 본문의 키는 선언이 아니다'      0 'printf ok' 'cat <<EOF'$'\n'"$KEY=\"evil\""$'\n''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
   276	p26() { pcase '히어독 본문에만 있으면 미설정'         1 ''          'cat <<EOF'$'\n'"$KEY=\"\""$'\n''EOF'$'\n'; }
   277	p27() { pcase '히어독 <<- 는 탭 들여쓴 종결어'        0 'printf ok' 'cat <<-EOF'$'\n'"$KEY=\"evil\""$'\n\t''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
   278	p28() { pcase "히어독 <<'EOF' 인용 종결어"            0 'printf ok' "cat <<'EOF'"$'\n'"$KEY=\"evil\""$'\n''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
   279	p29() { pcase '히어독이 EOF 까지 안 닫히면 미설정'    1 ''          "$KEY=\"printf ok\""$'\n''cat <<EOF'$'\n''본문'$'\n'; }
   280	p30() { pcase '따옴표 안의 << 는 히어독이 아니다'     0 'echo a << b' "$KEY=\"echo a << b\""$'\n'; }
   281	p31() { pcase '<<< 히어스트링은 히어독이 아니다'      0 'printf ok' 'cat <<<x'$'\n'"$KEY=\"printf ok\""$'\n'; }
   282	p32() { pcase '여러 줄 값은 지원하지 않는다'          1 ''          "$KEY=\"pnpm \\"$'\n''tsc"'$'\n'; }
   283	p33() { pcase '백슬래시 이스케이프는 지원하지 않는다' 1 ''          "$KEY=\"a \\\" b\""$'\n'; }
   284	p34() { pcase '닫히지 않은 따옴표'                    1 ''          "$KEY=\"printf ok"$'\n'; }
   285	p35() { pcase '따옴표 뒤 잡음'                        1 ''          "$KEY=\"printf\" ok"$'\n'; }
   286	p36() { pcase '리터럴 빈 값 "" — 미설정과 다르다'     0 ''          "$KEY=\"\""$'\n'; }
   287	p37() { pcase "리터럴 빈 값 ''"                       0 ''          "$KEY=''"$'\n'; }
   288	p38() { pcase '리터럴 빈 값 — 등호 뒤가 없다'         0 ''          "$KEY="$'\n'; }
   289	p39() { pcase '값에 등호가 들어 있다'                 0 'a=b'       "$KEY=a=b"$'\n'; }
   290	p40() { pcase '따옴표 안의 공백은 보존한다'           0 '  '        "$KEY=\"  \""$'\n'; }
   291	p41() { pcase '$VAR 는 판독 시점에 확장되지 않는다'   0 'printf $HOME' "$KEY='printf \$HOME'"$'\n'; }
   292	p42() { pcase 'harness.env 파일이 없다'               1 ''          '__NOFILE__'; }
   293	p43() { pcase '빈 파일'                               1 ''          ''; }
   294	# 값의 앞·뒤 공백은 **서로 다른 자리**에서 털린다. 각각 따로 붙든다 —
   295	# 한쪽만 재면 다른 쪽을 지워도 초록이다(변이 측정에서 실제로 그랬다).
   296	p45() { pcase '등호 뒤 선행 공백 + 겹따옴표'          0 'printf ok' "$KEY=  \"printf ok\""$'\n'; }
   297	p46() { pcase '인용 없는 값의 후행 공백'              0 'mypy'      "$KEY=mypy   "$'\n'; }
   298	p47() { pcase '인용 없는 값의 후행 탭'                0 'mypy'      "$KEY=mypy"$'\t\n'; }
   299	
   300	# 읽기 실패는 "미설정"과 판정은 같되(rc=1) **소리를 낸다**. root 는 -r 가 항상 참이라
   301	# 이 픽스처가 성립하지 않는다 — 조용히 넘기지 않고 실패로 남긴다(skip 은 커버리지가
   302	# 사라진 것을 초록으로 위장한다).
   303	p44() {
   304	  local name='읽기 실패 — rc=1 이면서 경고를 낸다' proj why=''
   305	  DID_RUN=1
   306	  if [ "$(id -u)" = '0' ]; then
   307	    report "$name" 'root 로 실행하면 이 픽스처가 성립하지 않는다 (비-root 로 돌려라)'
   308	    return 0
   309	  fi
   310	  if ! proj="$(new_project "$KEY=\"printf ok\""$'\n')"; then
   311	    report "$name" "픽스처 구성 실패: $FIXTURE_FAIL"; return 0
   312	  fi
   313	  if ! chmod 000 "$proj/.claude/harness/harness.env" 2>/dev/null; then
   314	    report "$name" '픽스처 구성 실패: chmod 000 실패'; return 0
   315	  fi
   316	  read_value "$proj"
   317	  if [ "$VRC" -ne 1 ]; then
   318	    why="rc=$VRC (기대 1)"
   319	  elif [ -n "$VAL" ]; then
   320	    why="값=[$VAL] (기대 빈 문자열)"
   321	  else
   322	    case "$VERR" in
   323	      *"$TOK_READ_FAIL"*) ;;
   324	      *) why="읽기 실패를 알리지 않았다 (stderr=[$VERR])" ;;
   325	    esac
   326	  fi
   327	  report "$name" "$why"
   328	}
   329	
   330	# --- 통합 케이스 — Stop 훅을 실제로 돌린다 -------------------------------
   331	# 감사 플래그 하나만 서 있으므로 정상 경로의 차단 문구는 항상 TOK_AUDIT 이다.
   332	# 타입체크가 실제로 돌아 실패하면 TOK_TC_FAIL 이 대신 나온다 — 그 둘을 가르는 것이
   333	# 판별력의 전부다(rc 는 어느 쪽이든 2라 아무것도 증명하지 못한다).
   334	
   335	# 적대적 harness.env: source 했다면 훅이 그 자리에서 죽거나 조용히 끝났을 입력들.
   336	i01() { hcase 'exit 1 이 있어도 게이트가 산다'  2 "$TOK_AUDIT" '-' \
   337	        'exit 1'$'\n'"$KEY=\"true\""$'\n'; }
   338	i02() { hcase 'exit 0 이 있어도 게이트가 산다'  2 "$TOK_AUDIT" '-' \
   339	        'exit 0'$'\n'"$KEY=\"true\""$'\n'; }
   340	i03() { hcase 'return 이 있어도 게이트가 산다'  2 "$TOK_AUDIT" '-' \
   341	        'return 0'$'\n'"$KEY=\"true\""$'\n'; }
   342	i04() { hcase 'printf 재정의가 진단을 위조하지 못한다' 2 "$TOK_AUDIT" '위조됨' \
   343	        "printf() { builtin printf '위조됨'; }"$'\n'"$KEY=\"true\""$'\n'; }
   344	
   345	# 회귀의 실제 귀결: 값이 온전해야 명령이 **실행**된다.
   346	# 파서를 되돌리면 값이 ["false" # note] 가 되어 rc=127 → 타입체크 생략 → 감사 게이트가
   347	# 대신 막는다. rc 는 그대로 2 이므로 **문구로만** 갈린다.
   348	i05() { hcase '후행 주석이 붙은 실패 명령이 실제로 실행된다' 2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
   349	        "$KEY=\"false\" # note"$'\n'; }
   350	i06() { hcase '후행 주석이 붙은 성공 명령은 통과시킨다'      2 "$TOK_AUDIT" "$TOK_TC_FAIL" \
   351	        "$KEY=\"true\" # note"$'\n'; }
   352	i07() { hcase '후행 공백이 붙은 실패 명령이 실제로 실행된다' 2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
   353	        "$KEY=\"false\"   "$'\n'; }
   354	i08() { hcase 'CRLF 줄끝의 실패 명령이 실제로 실행된다'      2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
   355	        "$KEY=\"false\""$'\r\n'; }
   356	i09() { hcase 'BOM 이 있어도 실패 명령이 실제로 실행된다'    2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
   357	        $'\357\273\277'"$KEY=\"false\""$'\n'; }
   358	i10() { hcase '히어독 본문의 키는 명령으로 쓰이지 않는다'    2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
   359	        'cat <<EOF'$'\n'"$KEY=\"true\""$'\n''EOF'$'\n'"$KEY=\"false\""$'\n'; }
   360	
   361	# 값은 판독 시점이 아니라 **실행 시점**에 확장된다 — _common.sh 주석의 안내와 짝이다.
   362	# 마커를 넣고 돌리면 test 가 실패해야 한다. 확장이 안 일어나면 rc=0 으로 통과해버린다.
   363	i11() { hcase '값은 실행 시점에 환경변수로 확장된다' 2 "$TOK_TC_FAIL" "$TOK_AUDIT" \
   364	        "$KEY='test -z \"\$HARNESS_TEST_MARKER\"'"$'\n' HARNESS_TEST_MARKER=x; }
   365	
   366	# 생략의 두 사유를 사용자에게 **구별해** 알린다.
   367	i12() { hcase '리터럴 빈 값은 "빈 값으로 설정됨" 으로 알린다' 2 "$TOK_EMPTY_SET" "$TOK_TC_FAIL" \
   368	        "$KEY=\"\""$'\n'; }
   369	i13() { hcase '선언 2개는 "읽지 못함" 으로 알린다'            2 "$TOK_UNREADABLE" "$TOK_TC_FAIL" \
   370	        "$KEY=\"false\""$'\n'"$KEY=\"false\""$'\n'; }
   371	
   372	# --- 지식 게이트 케이스 — ADR-0008 의 "기본 켜짐" 계약 ------------------
   373	# 이 게이트가 **꺼지는 방향으로 틀리는 것**이 최악이다. 사용자는 지식이 쌓인다고 믿는데
   374	# 그 턴부터 아무것도 안 남고, 아무 에러도 안 난다. 그래서 표명이 없거나 모호하면 켠다.
   375	
   376	g01() { gcase '키가 아예 없으면 켜짐 (기존 설치본 동작 보존)' on \
   377	        "$KEY=\"true\""$'\n'; }
   378	g02() { gcase '"on" 이면 켜짐'                    on  "$GKEY=\"on\""$'\n'; }
   379	g03() { gcase '리터럴로 비우면 꺼짐 — 유일한 끄는 법' off "$GKEY=\"\""$'\n'; }
   380	g04() { gcase '"off" 라고 적어도 켜짐 (비어 있지 않다)' on "$GKEY=\"off\""$'\n'; }
   381	g05() { gcase '선언이 2개면 켜짐 (어느 게 이기는지 모른다)' on \
   382	        "$GKEY=\"\""$'\n'"$GKEY=\"\""$'\n'; }
   383	g06() { gcase '히어독 본문의 빈 값으로는 못 끈다'  on \
   384	        'cat <<EOF'$'\n'"$GKEY=\"\""$'\n''EOF'$'\n'; }
   385	g07() { gcase '들여쓴 위장으로는 못 끈다'          on  "  $GKEY=\"\""$'\n'; }
   386	g08() { gcase '주석 처리된 선언으로는 못 끈다'      on  "# $GKEY=\"\""$'\n'; }
   387	g09() { gcase 'harness.env 가 없으면 켜짐'         on  '__NOFILE__'; }
   388	g10() { gcase 'CRLF 로 비워도 꺼진다'              off "$GKEY=\"\""$'\r\n'; }
   389	
   390	# --- 러너 ----------------------------------------------------------------
   391	
   392	CASES='
   393	p01 p02 p03 p04 p05 p06 p07 p08 p09 p10
   394	p11 p12 p13 p14 p15 p16 p17 p18 p19 p20
   395	p21 p22 p23 p24 p25 p26 p27 p28 p29 p30
   396	p31 p32 p33 p34 p35 p36 p37 p38 p39 p40
   397	p41 p42 p43 p44 p45 p46 p47
   398	i01 i02 i03 i04 i05 i06 i07 i08 i09 i10
   399	i11 i12 i13
   400	g01 g02 g03 g04 g05 g06 g07 g08 g09 g10
   401	'
   402	EXPECTED_CASES=70
   403	
   404	# 목록 자체의 중복·누락을 먼저 본다. 실행 수만 세면 "하나 중복 + 하나 누락"이 상쇄돼
   405	# 그대로 초록이 된다 — 목록을 직접 봐야 그 조합이 잡힌다.
   406	case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
   407	case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
   408	if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
   409	  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 중복됐거나 빠졌습니다" >&2
   410	  exit 1
   411	fi
   412	
   413	echo "harness.env 원문 판독 — 반환 계약 + 게이트 통합"
   414	for c in $CASES; do
   415	  ran=$((ran + 1))
   416	  DID_RUN=0
   417	  FIXTURE_FAIL=''
   418	  "$c"
   419	done
   420	
   421	if [ "$ran" -ne "$EXPECTED_CASES" ]; then
   422	  echo "✗ 실행 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 조용히 빠졌습니다" >&2
   423	  exit 1
   424	fi
   425	if [ $((pass + fail)) -ne "$ran" ]; then
   426	  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건 — 중복 판정했거나 판정을 건너뛰었습니다" >&2
   427	  exit 1
   428	fi
   429	
   430	echo "— ${pass}/${ran} 통과"
   431	[ "$fail" -eq 0 ] || exit 1
     1	#!/usr/bin/env bash
     2	# install-hook-swap.test.sh — 훅 디렉터리 rename 스왑의 회귀 테스트.
     3	#
     4	# 이 축의 실패는 **거짓 성공**으로 나온다. 앞선 검수에서 실제로 그랬다 — mv 가 기존
     5	# 디렉터리 **안으로** 중첩되어 훅이 hooks/hooks/*.sh 로 깨졌는데 스크립트는 "설치 성공"을
     6	# 찍었고, 신호로 죽었는데 rc=0 이 나왔다. 그래서 여기서는 rc 만 보지 않는다.
     7	#
     8	# **rc 단독 판정은 약하다.** 신호 종료 코드는 128+신호번호라는 관례값이라, 핸들러가 제대로
     9	# 돌아 exit 143 한 것과 핸들러가 아예 없어 커널 기본 처리로 죽은 것이 같은 143 을 낸다.
    10	# 그래서 케이스마다 **부수 효과**를 함께 잰다: 훅이 제자리에 있나 · 중첩(hooks/hooks)이
    11	# 생겼나 · 임시 디렉터리가 남았나 · 진단 문구가 나왔나.
    12	#
    13	# 중단 주입은 타이밍이 아니라 **shim** 으로 한다. PATH 앞에 놓은 mv 가 호출 횟수를 세다가
    14	# 두 번째(스테이징 → 제자리)에서 부모에게 신호를 보낸다 — 그러면 "옛것은 치웠고 새것은
    15	# 아직 안 들어온" 그 창에서 정확히 멈춘다. shim 은 실제 mv 의 rc 를 **절대 삼키지 않는다**
    16	# (rc 를 버리는 shim 은 픽스처의 실패를 조용히 성공으로 바꾼다 — 실측된 함정이다).
    17	#
    18	# 그리고 **주입이 실제로 걸렸는지를 판정에 넣는다.** 빗나가면 설치가 그냥 완주해 기대값이
    19	# 우연히 충족되고, 케이스는 아무것도 안 잰 채 통과 도장을 찍는다.
    20	#
    21	# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
    22	# 사용법: ./tests/install-hook-swap.test.sh
    23	
    24	set -uo pipefail
    25	
    26	TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    27	REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
    28	INSTALL="$REPO_ROOT/install.sh"
    29	
    30	[ -f "$INSTALL" ] || { echo "✗ install.sh 를 찾지 못했습니다" >&2; exit 1; }
    31	
    32	TMPROOT="$(mktemp -d)" || exit 1
    33	if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
    34	  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
    35	fi
    36	TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
    37	trap 'rm -rf "$TMPROOT"' EXIT
    38	
    39	REAL_MV="$(command -v mv)"
    40	[ -n "$REAL_MV" ] || { echo "✗ mv 를 찾지 못했습니다" >&2; exit 1; }
    41	
    42	ran=0; pass=0; fail=0
    43	RC=999; OUT=''; DID_RUN=0
    44	
    45	report() {
    46	  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
    47	  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
    48	}
    49	
    50	# new_project — 하네스가 이미 한 번 설치된 프로젝트. 구판임을 알아볼 수 있게 표식을
    51	# 넣는다 — "복원됐나"를 판정하려면 구판이 식별 가능해야 한다.
    52	new_project() {
    53	  local p
    54	  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
    55	  p="$(CDPATH='' cd -- "$p" && pwd -P)"
    56	  "$INSTALL" "$p" >/dev/null 2>&1 || return 1
    57	  printf 'OLD\n' > "$p/.claude/hooks/.old-marker"
    58	  printf '%s\n' "$p"
    59	}
    60	
    61	# make_mv_shim <디렉터리> <몇 번째 호출에서> <신호이름|FAIL>
    62	make_mv_shim() {
    63	  local dir="$1" nth="$2" action="$3"
    64	  mkdir -p "$dir" || return 1
    65	  cat > "$dir/mv" <<SHIM
    66	#!/usr/bin/env bash
    67	n_file="$dir/.count"
    68	n=\$(cat "\$n_file" 2>/dev/null || echo 0)
    69	n=\$((n + 1))
    70	printf '%s\n' "\$n" > "\$n_file"
    71	if [ "\$n" -eq $nth ]; then
    72	  printf 'HIT\n' > "$dir/.hit"
    73	  if [ "$action" = FAIL ]; then
    74	    exit 1
    75	  fi
    76	  kill -$action \$PPID 2>/dev/null
    77	  sleep 5          # 신호가 처리될 시간. 핸들러가 exit 하므로 여기까지 오지 않는다
    78	  exit 1
    79	fi
    80	exec "$REAL_MV" "\$@"     # **실제 rc 를 그대로 돌려준다** — 삼키면 픽스처가 결함을 가린다
    81	SHIM
    82	  chmod +x "$dir/mv"
    83	}
    84	
    85	run_install() {   # $1=프로젝트  [$2=shim 디렉터리]
    86	  RC=999; OUT=''; DID_RUN=1
    87	  if [ -n "${2-}" ]; then
    88	    OUT="$(PATH="$2:$PATH" "$INSTALL" "$1" 2>&1)"
    89	  else
    90	    OUT="$("$INSTALL" "$1" 2>&1)"
    91	  fi
    92	  RC=$?
    93	}
    94	
    95	# leftovers <프로젝트> — 스테이징·백업 임시 디렉터리가 남았나
    96	leftovers() {
    97	  ls -a "$1/.claude" 2>/dev/null | grep -cE '^\.hooks-(stage|old)\.'
    98	}
    99	
   100	# --- 케이스 --------------------------------------------------------------
   101	
   102	c01() {
   103	  local name='정상 설치 — 제자리·잔류물 0·중첩 없음·구판 잔재 없음' p why=''
   104	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   105	  run_install "$p"
   106	  if [ "$RC" -ne 0 ]; then why="rc=$RC"
   107	  elif [ ! -f "$p/.claude/hooks/_common.sh" ]; then why='_common.sh 이 제자리에 없다'
   108	  elif [ -e "$p/.claude/hooks/hooks" ]; then why='중첩(hooks/hooks)이 생겼다'
   109	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   110	  elif [ -f "$p/.claude/hooks/.old-marker" ]; then why='구판 잔재가 남았다 (교체가 아니라 덮어쓰기다)'
   111	  fi
   112	  report "$name" "$why"
   113	}
   114	
   115	# 중단 주입 — 두 rename 사이에서 멈춘다.
   116	interrupt_case() {   # $1=이름 $2=신호 $3=기대rc
   117	  local name="$1" sig="$2" want_rc="$3" p shim why=''
   118	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   119	  shim="$TMPROOT/shim.$sig.$$"
   120	  if ! make_mv_shim "$shim" 2 "$sig"; then report "$name" '픽스처 실패: shim'; return 0; fi
   121	  run_install "$p" "$shim"
   122	  if [ ! -f "$shim/.hit" ]; then
   123	    why='주입이 빗나갔다 (mv 가 2번째로 불리지 않았다 — 설치가 그냥 완주했다)'
   124	  elif [ "$RC" -ne "$want_rc" ]; then
   125	    why="rc=$RC (기대 $want_rc)"
   126	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then
   127	    why='구판으로 되돌리지 못했다 (훅 디렉터리가 사라졌다)'
   128	  elif [ -e "$p/.claude/hooks/hooks" ]; then
   129	    why='중첩(hooks/hooks)이 생겼다'
   130	  elif [ "$(leftovers "$p")" != '0' ]; then
   131	    why='임시 디렉터리가 남았다'
   132	  else
   133	    case "$OUT" in
   134	      *'되돌렸습니다'*) ;;
   135	      *) why="복구를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
   136	    esac
   137	  fi
   138	  report "$name" "$why"
   139	}
   140	
   141	c02() { interrupt_case '교체 도중 INT  — 구판 복원 + rc=130' INT  130; }
   142	c03() { interrupt_case '교체 도중 TERM — 구판 복원 + rc=143' TERM 143; }
   143	# QUIT·HUP 이 따로 중요한 이유: trap 이 없으면 bash 가 QUIT 를 **무시하고 rc=0** 을 낸다 —
   144	# 중단됐는데 "설치 성공"으로 보고되는 최악의 조합이다(실측).
   145	c04() { interrupt_case '교체 도중 QUIT — 구판 복원 + rc=131' QUIT 131; }
   146	c05() { interrupt_case '교체 도중 HUP  — 구판 복원 + rc=129' HUP  129; }
   147	
   148	c06() {
   149	  local name='rename2 실패 — 성공으로 오진단하지 않고 구판 복원' p shim why=''
   150	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   151	  shim="$TMPROOT/shim.fail.$$"
   152	  if ! make_mv_shim "$shim" 2 FAIL; then report "$name" '픽스처 실패: shim'; return 0; fi
   153	  run_install "$p" "$shim"
   154	  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
   155	  elif [ "$RC" -eq 0 ]; then why='실패했는데 rc=0 (성공으로 오진단)'
   156	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
   157	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   158	  else
   159	    case "$OUT" in
   160	      *'교체하지 못했습니다'*) ;;
   161	      *) why="실패를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
   162	    esac
   163	  fi
   164	  report "$name" "$why"
   165	}
   166	
   167	c07() {
   168	  local name='훅 디렉터리가 심링크면 링크를 보존하고 알린다' p why=''
   169	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   170	  "$REAL_MV" "$p/.claude/hooks" "$p/real-hooks" || { report "$name" '픽스처 실패: mv'; return 0; }
   171	  ln -s "$p/real-hooks" "$p/.claude/hooks" || { report "$name" '픽스처 실패: ln'; return 0; }
   172	  run_install "$p"
   173	  if [ "$RC" -ne 0 ]; then why="rc=$RC"
   174	  elif [ ! -L "$p/.claude/hooks" ]; then why='심링크를 일반 디렉터리로 갈아치웠다 (사용자 배치 파괴)'
   175	  elif [ ! -f "$p/real-hooks/_common.sh" ]; then why='링크 대상에 훅이 복사되지 않았다'
   176	  else
   177	    case "$OUT" in
   178	      *'심볼릭 링크'*) ;;
   179	      *) why='원자성을 못 지킨다는 사실을 알리지 않았다 (조용히 물러섰다)' ;;
   180	    esac
   181	  fi
   182	  report "$name" "$why"
   183	}
   184	
   185	# 핸들러 진입 직후의 `set +e` 를 지키는 유일한 케이스.
   186	#
   187	# 왜 따로 필요한가: 다른 중단 케이스는 진단 echo 가 **성공**하므로 set +e 가 있든 없든
   188	# exit 에 도달한다. 그래서 그 줄을 지워도 전건 초록이다 — 실제로 앞선 세션에서 그 한 줄을
   189	# 지워도 스위트 19/19 가 그대로였다. 버그는 **stderr 가 닫힌 상태에서만** 재현되는데
   190	# 테스트 하네스가 출력을 2>&1 로 합칠 뿐 닫지 않았기 때문이다.
   191	#
   192	# 여기서는 stderr 를 **닫고**(2>&-) 돌린다. echo 가 실패하고, set -e 가 살아 있으면
   193	# 핸들러가 exit 143 에 도달하지 못하고 rc=1 로 끝난다 — 신호로 죽은 건지 실패한 건지
   194	# 구별이 사라지는 그 상태다.
   195	#
   196	# 한계(공시): stderr 가 닫혔으므로 진단 문구는 잴 수 없다. 종료 코드와 파일 상태만 본다.
   197	c08() {
   198	  local name='stderr 가 닫힌 채 TERM — 진단은 못 내도 종료 코드 계약은 지킨다' p shim why=''
   199	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   200	  shim="$TMPROOT/shim.noerr.$$"
   201	  if ! make_mv_shim "$shim" 2 TERM; then report "$name" '픽스처 실패: shim'; return 0; fi
   202	  DID_RUN=1
   203	  PATH="$shim:$PATH" "$INSTALL" "$p" >/dev/null 2>&-
   204	  RC=$?
   205	  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
   206	  elif [ "$RC" -ne 143 ]; then why="rc=$RC (기대 143 — set +e 가 없으면 1 이 된다)"
   207	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
   208	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   209	  fi
   210	  report "$name" "$why"
   211	}
   212	
   213	# --- 러너 ----------------------------------------------------------------
   214	
   215	CASES='c01 c02 c03 c04 c05 c06 c07 c08'
   216	EXPECTED_CASES=8
   217	
   218	case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
   219	case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
   220	if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
   221	  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
   222	  exit 1
   223	fi
   224	
   225	echo "훅 교체 원자성 — rename 스왑 + 중단 복구"
   226	for c in $CASES; do
   227	  ran=$((ran + 1)); DID_RUN=0
   228	  "$c"
   229	done
   230	
   231	if [ "$ran" -ne "$EXPECTED_CASES" ]; then echo "✗ 실행 ${ran}건 ≠ ${EXPECTED_CASES}건" >&2; exit 1; fi
   232	if [ $((pass + fail)) -ne "$ran" ]; then echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1; fi
   233	
   234	echo "— ${pass}/${ran} 통과"
   235	[ "$fail" -eq 0 ] || exit 1

2026-08-10T03:50:07.927925Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "nl -ba tests/check-layer-boundary.test.sh | sed -n '1,360p'
nl -ba tests/mark-needs-audit.cases.sh | sed -n '1,260p'
nl -ba tests/mark-needs-audit.test.sh | sed -n '1,260p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
     1	#!/usr/bin/env bash
     2	# check-layer-boundary.test.sh — 층 경계 검사기의 회귀 테스트.
     3	#
     4	# 이 검사기의 유일한 치명 결함은 **위음성**이다. 누출을 통과시키는 순간 층 경계는
     5	# 다시 산문으로 돌아가고, 산문 규칙은 어겨져도 아무것도 안 깨져서 아무도 모른다.
     6	# 그래서 케이스마다 "그 패턴 **하나만**" 심은 픽스처를 쓴다 — 한 패턴을 목록에서
     7	# 지웠을 때 **그 케이스만** 빨개져야 방어를 지키는 것이다. 다른 케이스가 대신
     8	# 빨개지는 것은 그 방어를 지키는 게 아니다.
     9	#
    10	# 사전 조건(심링크·NUL·빈 범위)도 케이스로 붙든다. "스캔할 수 없는 대상이 트리에
    11	# 있으면 결과 전체를 믿을 수 없다"는 계약이고, 그 계약이 사라지면 검사되지 않은
    12	# 파일이 배포되는 창이 조용히 열린다.
    13	#
    14	# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
    15	# 셸 이식성: macOS 기본 bash 는 3.2 다.
    16	#
    17	# 사용법: ./tests/check-layer-boundary.test.sh
    18	
    19	set -uo pipefail
    20	
    21	TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    22	REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
    23	CHECKER="$REPO_ROOT/scripts/check-layer-boundary.sh"
    24	
    25	[ -f "$CHECKER" ] || { echo "✗ 검사기를 찾지 못했습니다: $CHECKER" >&2; exit 1; }
    26	
    27	TMPROOT="$(mktemp -d)" || exit 1
    28	if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
    29	  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2
    30	  exit 1
    31	fi
    32	TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
    33	trap 'rm -rf "$TMPROOT"' EXIT
    34	
    35	ran=0; pass=0; fail=0
    36	OUT=''; RC=999; DID_RUN=0; FIXTURE_FAIL=''
    37	
    38	report() {
    39	  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
    40	  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
    41	}
    42	
    43	# new_tree — 깨끗한 배포물 트리(위반 0건)를 만들고 경로를 낸다.
    44	# 정상 문구를 일부러 담는다: 계약 표현("지식 저장소")은 통과해야 하고, 통과하지
    45	# 못하면 이 검사기는 쓸 수가 없다.
    46	new_tree() {
    47	  local d
    48	  d="$(mktemp -d "$TMPROOT/tree.XXXXXX")" || { FIXTURE_FAIL='mktemp 실패'; return 1; }
    49	  mkdir -p "$d/.claude/hooks" "$d/.claude/skills/x" || { FIXTURE_FAIL='골격 실패'; return 1; }
    50	  printf '%s\n' '# 지식 저장소 반영 게이트. 저장소가 어디인지는 사용자 층이 답한다.' \
    51	    > "$d/.claude/hooks/verify.sh"
    52	  printf '%s\n' '완료 게이트 4종을 세운다. .needs-knowledge 는 계약 이름이다.' \
    53	    > "$d/.claude/skills/x/SKILL.md"
    54	  printf '%s\n' 'HARNESS_KNOWLEDGE_GATE="on"' > "$d/.claude/harness.env"
    55	  printf '%s\n' "$d"
    56	}
    57	
    58	run_checker() {   # $1 = 스캔 범위
    59	  OUT=''; RC=999; DID_RUN=1
    60	  OUT="$(HARNESS_LAYER_SCAN_ROOT="$1" "$CHECKER" 2>&1)"
    61	  RC=$?
    62	}
    63	
    64	# leak_case <이름> <심을 문구> <보고에 나와야 할 조각>
    65	# 깨끗한 트리에 그 문구 **하나만** 심는다.
    66	leak_case() {
    67	  local name="$1" text="$2" token="$3" d why=''
    68	  if ! d="$(new_tree)"; then report "$name" "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
    69	  printf '%s\n' "$text" > "$d/.claude/hooks/leaky.sh"
    70	  run_checker "$d"
    71	  if [ "$DID_RUN" -ne 1 ]; then
    72	    why='검사기를 실행하지 않았다'
    73	  elif [ "$RC" -eq 0 ]; then
    74	    why='누출을 통과시켰다 (rc=0)'
    75	  elif [ "$RC" -ne 1 ]; then
    76	    why="rc=$RC (기대 1) / $(printf '%s' "$OUT" | head -c 200)"
    77	  else
    78	    case "$OUT" in
    79	      *"$token"*) ;;
    80	      *) why="보고에 [$token] 이 없다: $(printf '%s' "$OUT" | head -c 200)" ;;
    81	    esac
    82	    if [ -z "$why" ]; then
    83	      case "$OUT" in
    84	        *'leaky.sh'*) ;;
    85	        *) why="어느 파일인지 보고하지 않았다: $(printf '%s' "$OUT" | head -c 200)" ;;
    86	      esac
    87	    fi
    88	  fi
    89	  report "$name" "$why"
    90	}
    91	
    92	# --- 케이스 --------------------------------------------------------------
    93	
    94	c01() {
    95	  local d why=''
    96	  if ! d="$(new_tree)"; then report '깨끗한 트리는 통과한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
    97	  run_checker "$d"
    98	  if [ "$RC" -ne 0 ]; then why="rc=$RC (기대 0) / $OUT"; fi
    99	  report '깨끗한 트리는 통과한다 (계약 표현은 위양성이 아니다)' "$why"
   100	}
   101	
   102	c02() { leak_case '저장소 이름 — second brain'     'second brain 에 반영한다'       'second'; }
   103	c03() { leak_case '도구 이름 — Obsidian'            'Obsidian 을 연다'               'Obsidian'; }
   104	c04() { leak_case '저장소 이름 — 볼트'               '이 저장소에 반영한다 볼트'      '볼트'; }
   105	c05() { leak_case '상위 층 파일 — _CLAUDE.md'        '_CLAUDE.md 를 전문 읽는다'      '_CLAUDE'; }
   106	c06() { leak_case '상위 층 구조 — 4종 세트'          '4종 세트로 반영한다'            '4종 세트'; }
   107	c07() { leak_case '상위 층 파일 — discussion-log'    'discussion-log 에 적는다'       'discussion-log'; }
   108	c08() { leak_case '상위 층 폴더 — Projects/<name>'   'Projects/<name>/ 아래에 둔다'   'Projects'; }
   109	c09() { leak_case '구현체 이름 플래그 — needs-vault' 'rm -f .claude/.needs-vault'     'needs-vault'; }
   110	
   111	# 첫 건에서 멈추면 한 번 고칠 때마다 다시 돌려야 하고, 남은 누출이 몇 개인지 모른다.
   112	c10() {
   113	  local d why=''
   114	  if ! d="$(new_tree)"; then report '위반이 여러 파일이면 전부 보고한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
   115	  printf '%s\n' '볼트에 반영' > "$d/.claude/hooks/a.sh"
   116	  printf '%s\n' '_CLAUDE.md 읽기' > "$d/.claude/hooks/b.sh"
   117	  run_checker "$d"
   118	  if [ "$RC" -ne 1 ]; then
   119	    why="rc=$RC (기대 1)"
   120	  else
   121	    case "$OUT" in *'a.sh'*) ;; *) why='a.sh 를 보고하지 않았다' ;; esac
   122	    if [ -z "$why" ]; then
   123	      case "$OUT" in *'b.sh'*) ;; *) why='b.sh 를 보고하지 않았다 (첫 건에서 멈췄다)' ;; esac
   124	    fi
   125	  fi
   126	  report '위반이 여러 파일이면 전부 보고한다' "$why"
   127	}
   128	
   129	# 사전 조건 — 스캔할 수 없는 대상이 있으면 결과 전체를 믿을 수 없다.
   130	c11() {
   131	  local d why=''
   132	  if ! d="$(new_tree)"; then report '심링크가 있으면 거부한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
   133	  if ! ln -s "$d/.claude/hooks/verify.sh" "$d/.claude/hooks/link.sh" 2>/dev/null; then
   134	    report '심링크가 있으면 거부한다' '픽스처 실패: ln -s'; return 0
   135	  fi
   136	  run_checker "$d"
   137	  if [ "$RC" -eq 0 ]; then why='심링크가 있는데 통과시켰다'
   138	  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
   139	  else
   140	    case "$OUT" in *'심링크'*) ;; *) why="사유가 심링크가 아니다: $(printf '%s' "$OUT" | head -c 160)" ;; esac
   141	  fi
   142	  report '심링크가 있으면 거부한다' "$why"
   143	}
   144	
   145	c12() {
   146	  local d why=''
   147	  if ! d="$(new_tree)"; then report 'NUL 보유 파일이 있으면 거부한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
   148	  printf 'A\000B\n' > "$d/.claude/hooks/nul.sh"
   149	  run_checker "$d"
   150	  if [ "$RC" -eq 0 ]; then why='NUL 파일이 있는데 통과시켰다'
   151	  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
   152	  else
   153	    case "$OUT" in *'NUL'*) ;; *) why="사유가 NUL 이 아니다: $(printf '%s' "$OUT" | head -c 160)" ;; esac
   154	  fi
   155	  report 'NUL 보유 파일이 있으면 거부한다' "$why"
   156	}
   157	
   158	# 빈 목록 = 공허한 초록. 0개를 스캔하고 "위반 0건"을 찍으면 아무것도 증명하지 않는다.
   159	c13() {
   160	  local d why=''
   161	  if ! d="$(mktemp -d "$TMPROOT/empty.XXXXXX")"; then
   162	    report '스캔 대상이 0개면 거부한다' '픽스처 실패'; return 0
   163	  fi
   164	  run_checker "$d"
   165	  if [ "$RC" -eq 0 ]; then why='파일이 하나도 없는데 초록불을 냈다'
   166	  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
   167	  fi
   168	  report '스캔 대상이 0개면 거부한다 (공허한 초록 방지)' "$why"
   169	}
   170	
   171	c14() {
   172	  local why=''
   173	  run_checker "$TMPROOT/그런디렉토리없음"
   174	  if [ "$RC" -eq 0 ]; then why='없는 범위인데 통과시켰다'; fi
   175	  report '스캔 범위가 없으면 거부한다' "$why"
   176	}
   177	
   178	# --- 러너 ----------------------------------------------------------------
   179	
   180	CASES='c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12 c13 c14'
   181	EXPECTED_CASES=14
   182	
   183	case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
   184	case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
   185	if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
   186	  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
   187	  exit 1
   188	fi
   189	
   190	echo "층 경계 검사기 — 누출 적발 + 사전 조건"
   191	for c in $CASES; do
   192	  ran=$((ran + 1)); DID_RUN=0; FIXTURE_FAIL=''
   193	  "$c"
   194	done
   195	
   196	if [ "$ran" -ne "$EXPECTED_CASES" ]; then
   197	  echo "✗ 실행 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건" >&2; exit 1
   198	fi
   199	if [ $((pass + fail)) -ne "$ran" ]; then
   200	  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1
   201	fi
   202	
   203	echo "— ${pass}/${ran} 통과"
   204	[ "$fail" -eq 0 ] || exit 1
     1	#!/usr/bin/env bash
     2	# mark-needs-audit.cases.sh — 경로 → 판정 **계약 표**. 이 파일이 계약의 기계 정본이다.
     3	#
     4	# 실행 파일이 아니라 mark-needs-audit.test.sh 가 source 하는 조각이다. 러너·픽스처·assert
     5	# 헬퍼는 전부 거기 있고, 여기에는 계약 표만 둔다 — 한 파일에 다 넣으면 800줄을 넘어
     6	# 표를 계획서와 대조하기가 어려워진다.
     7	#
     8	# 여기서 쓰는 것(정의는 러너 쪽): new_project · new_harness_repo · new_symlinked_project ·
     9	# new_dir · mkfile · run_hook · run_hook_raw · run_static_check · fixture_broken ·
    10	# check_case · TOK_* · EMPTY_STATE
    11	#
    12	# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
    13	
    14	# 러너를 거치지 않고 직접 돌리면 헬퍼가 하나도 없어 전 케이스가 조용히 무판정이 된다.
    15	# 조용한 위음성을 막으려고 fail-closed 로 세운다.
    16	if [ -z "${TOK_NEWLINE-}" ]; then
    17	  echo "✗ 이 파일은 단독 실행용이 아닙니다. ./tests/mark-needs-audit.test.sh 를 실행하세요" >&2
    18	  exit 1
    19	fi
    20	
    21	# --- 케이스 --------------------------------------------------------------
    22	# 번호는 고정이다. 새 케이스는 **뒤에만** 붙인다 (리뷰 대조가 깨지므로 재배열 금지).
    23	# 각 케이스 주석에 그 행이 지키는 축과 같은 축을 지키는 다른 행을 적는다. "비차별" 표시는
    24	# 기존 두 판 어느 쪽에서도 빨개지지 않는 행 — 결함 증명은 못 해도 새 계약을 고정한다.
    25	# === A. 프로젝트 안 =======================================================
    26	
    27	case_01() { # 기준선 — 프로젝트 안 코드는 게이트 4종, 값은 상대경로.
    28	  local p; p="$(new_project)"
    29	  mkfile "$p/src/app.ts"
    30	  run_hook "$p" "$p/src/app.ts"
    31	  check_case '01 프로젝트 안 소스 → 게이트 4종(상대경로)' 0 gate 'src/app.ts'
    32	}
    33	
    34	case_02() { # 순수 문서 제외.
    35	  local p; p="$(new_project)"
    36	  mkfile "$p/README.md"
    37	  run_hook "$p" "$p/README.md"
    38	  check_case '02 프로젝트 안 README.md → 스킵' 0 none ''
    39	}
    40	
    41	case_03() { # D3-5 대소문자 무관. 5단계 *.md 축의 대문자 쪽.
    42	            # 같은 대소문자 축의 3단계(듀얼) 쪽은 케이스 55 가 잡는다.
    43	  local p; p="$(new_project)"
    44	  mkfile "$p/README.MD"
    45	  run_hook "$p" "$p/README.MD"
    46	  check_case '03 프로젝트 안 README.MD(대문자) → 스킵' 0 none ''
    47	}
    48	
    49	case_04() { # _workspace/ 는 스크래치 — 설계·계획 파일명이 아니면 아무 플래그도 안 선다.
    50	  local p; p="$(new_project)"
    51	  mkfile "$p/_workspace/notes.md"
    52	  run_hook "$p" "$p/_workspace/notes.md"
    53	  check_case '04 프로젝트 안 _workspace/notes.md → 스킵' 0 none ''
    54	}
    55	
    56	case_05() { # D2 설계 산출물 — 듀얼리뷰+지식. 기록값은 프로젝트 상대경로.
    57	  local p; p="$(new_project)"
    58	  mkfile "$p/_workspace/00_design.md"
    59	  run_hook "$p" "$p/_workspace/00_design.md"
    60	  check_case '05 프로젝트 안 설계 문서 → 듀얼리뷰+지식(상대경로)' 0 designdoc '_workspace/00_design.md'
    61	}
    62	
    63	case_06() { # D2 계획 산출물 — 01_plan 축.
    64	  local p; p="$(new_project)"
    65	  mkfile "$p/_workspace/01_plan.v2.md"
    66	  run_hook "$p" "$p/_workspace/01_plan.v2.md"
    67	  check_case '06 프로젝트 안 계획 문서 → 듀얼리뷰+지식(상대경로)' 0 designdoc '_workspace/01_plan.v2.md'
    68	}
    69	
    70	case_07() { # 순서계약 (나) — .claude/* 제외가 하네스 앵커보다 **먼저**.
    71	            # 먼저가 아니면 프로젝트에 설치된 소비 사본이 게이트를 세운다.
    72	            # 같은 축: 케이스 24(정본 저장소가 자기 자신에 설치한 사본).
    73	  local p; p="$(new_project)"
    74	  mkfile "$p/.claude/settings.json"
    75	  run_hook "$p" "$p/.claude/settings.json"
    76	  check_case '07 설치된 글루 .claude/settings.json → 스킵' 0 none ''
    77	}
    78	
    79	case_08() { # 비블로킹 1 — 글롭 과대. 프로젝트 안의 평범한 src/agents/ 는 하네스가 아니다.
    80	  local p; p="$(new_project)"
    81	  mkfile "$p/src/agents/README.md"
    82	  run_hook "$p" "$p/src/agents/README.md"
    83	  check_case '08 프로젝트 안 src/agents/README.md → 스킵(오탐 금지)' 0 none ''
    84	}
    85	
    86	case_09() { # 비블로킹 1 — node_modules 안의 skills/*.md 도 하네스가 아니다.
    87	  local p; p="$(new_project)"
    88	  mkfile "$p/node_modules/p/skills/a.md"
    89	  run_hook "$p" "$p/node_modules/p/skills/a.md"
    90	  check_case '09 node_modules/*/skills/a.md → 스킵(오탐 금지)' 0 none ''
    91	}
    92	
    93	case_10() { # B2 정규화 — .. 로 .claude/ 를 빠져나온 경로. 정규화가 없으면 .claude/* 스킵에 먹힌다.
    94	            # 같은 축: 케이스 11·12(심링크)·47(듀얼 쪽 .. 복귀). 픽스처 의존: mkfile 의
    95	            # mkdir -p "$p/.claude/../src" 가 .. 앞 컴포넌트 .claude 를 실제로 만든다(실측 확인).
    96	  local p; p="$(new_project)"
    97	  mkfile "$p/.claude/../src/b.ts"
    98	  run_hook "$p" "$p/.claude/../src/b.ts"
    99	  check_case '10 .claude/../src/b.ts → 게이트 4종(정규화 후 src/b.ts)' 0 gate 'src/b.ts'
   100	}
   101	
   102	case_11() { # B2 심링크 — PROJECT_DIR 이 심링크, 편집 경로는 물리.
   103	            # 정규화가 없으면 접두사가 안 맞아 "밖"으로 새고, 새는 방향에 따라
   104	            # 오기록(app/.claude/settings.json)이나 무기록이 된다.
   105	  local repo; repo="$(new_symlinked_project)"
   106	  mkfile "$repo/app/.claude/settings.json"
   107	  run_hook "$repo/link" "$repo/app/.claude/settings.json"
   108	  check_case '11 심링크 PROJECT_DIR + 설치 글루 → 스킵' 0 none ''
   109	}
   110	
   111	case_12() { # B2 심링크 — 값 축. 기록값이 app/src/app.ts 로 새면 안 된다.
   112	  local repo; repo="$(new_symlinked_project)"
   113	  mkfile "$repo/app/src/app.ts"
   114	  run_hook "$repo/link" "$repo/app/src/app.ts"
   115	  check_case '12 심링크 PROJECT_DIR + 소스 → 게이트 4종(src/app.ts)' 0 gate 'src/app.ts'
   116	}
   117	
   118	case_13() { # 상대경로 입력의 절대화. 같은 축의 듀얼 쪽은 케이스 46.
   119	            # 비차별 — 고정하는 계약은 "상대 입력도 프로젝트 기준으로 판정한다".
   120	  local p; p="$(new_project)"
   121	  mkfile "$p/src/app.ts"
   122	  run_hook "$p" 'src/app.ts'
   123	  check_case '13 상대경로 입력 src/app.ts → 게이트 4종' 0 gate 'src/app.ts'
   124	}
   125	
   126	case_14() { # 중복 제거. 같은 파일을 두 번 편집해도 플래그는 한 줄이어야 한다.
   127	            # 비차별 — 고정하는 계약은 grep -qxF 중복 제거.
   128	  local p; p="$(new_project)"
   129	  mkfile "$p/src/app.ts"
   130	  run_hook "$p" "$p/src/app.ts"
   131	  run_hook "$p" "$p/src/app.ts"
   132	  check_case '14 같은 파일 2회 편집 → 플래그는 각 1줄' 0 gate 'src/app.ts'
   133	}
   134	
   135	case_15() { # .md 예외의 예외 — 하네스 앵커 아래 *.md 는 동작을 정의하므로 코드다.
   136	            # 프로젝트 안에서 정본을 들고 있는 형태(하네스 저장소를 PROJECT_DIR 로 연 경우).
   137	  local p; p="$(new_project)"
   138	  mkfile "$p/template/.claude/agents/x.md"
   139	  run_hook "$p" "$p/template/.claude/agents/x.md"
   140	  check_case '15 template/.claude/agents/x.md → 게이트 4종' 0 gate 'template/.claude/agents/x.md'
   141	}
   142	
   143	# === B. 프로젝트 밖 — 하네스 정본 저장소 ==================================
   144	# D1′: 루트에 template/.claude/ 가 있으면 그 저장소 **전체**를 프로젝트처럼 검사한다.
   145	# 기록값은 절대경로(B4) — 프로젝트 쪽 동명 파일과 섞이지 않게.
   146	case_16() { # D1′ 본체 — 정본 저장소의 최상위 코드. B4 절대경로.
   147	            # 같은 축: 케이스 26(worktree)·27(중첩 클론)·48(global-agents).
   148	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   149	  mkfile "$hr/scripts/check.sh"
   150	  run_hook "$p" "$hr/scripts/check.sh"
   151	  check_case '16 밖+정본 저장소 scripts/check.sh → 게이트 4종(절대경로)' 0 gate "$hr/scripts/check.sh"
   152	}
   153	
   154	case_17() { # 앵커 agents — 정본의 에이전트 정의.
   155	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   156	  mkfile "$hr/template/.claude/agents/plan-reviewer.md"
   157	  run_hook "$p" "$hr/template/.claude/agents/plan-reviewer.md"
   158	  check_case '17 밖+정본 template/.claude/agents/*.md → 게이트 4종(절대경로)' 0 gate "$hr/template/.claude/agents/plan-reviewer.md"
   159	}
   160	
   161	case_18() { # 앵커 skills.
   162	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   163	  mkfile "$hr/template/.claude/skills/foo/SKILL.md"
   164	  run_hook "$p" "$hr/template/.claude/skills/foo/SKILL.md"
   165	  check_case '18 밖+정본 template/.claude/skills/**/SKILL.md → 게이트 4종' 0 gate "$hr/template/.claude/skills/foo/SKILL.md"
   166	}
   167	
   168	case_19() { # 앵커 harness — 제0원칙 정본.
   169	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   170	  mkfile "$hr/template/.claude/harness/principles.md"
   171	  run_hook "$p" "$hr/template/.claude/harness/principles.md"
   172	  check_case '19 밖+정본 template/.claude/harness/*.md → 게이트 4종' 0 gate "$hr/template/.claude/harness/principles.md"
   173	}
   174	
   175	case_20() { # 앵커 settings.json — 확장자가 없는 앵커.
   176	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   177	  mkfile "$hr/template/.claude/settings.json"
   178	  run_hook "$p" "$hr/template/.claude/settings.json"
   179	  check_case '20 밖+정본 template/.claude/settings.json → 게이트 4종' 0 gate "$hr/template/.claude/settings.json"
   180	}
   181	
   182	case_21() { # 정본 저장소라도 순수 문서는 스킵 — 검사 범위가 무제한이 아님을 고정.
   183	            # 비차별 — 5단계 *.md 스킵을 건드리는 변이는 케이스 02 에서 먼저 죽는다.
   184	            # 이 행만의 몫은 "그 규칙이 4b-정본 스코프에도 그대로 적용된다"는 것뿐이다.
   185	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   186	  mkfile "$hr/docs/usage.md"
   187	  run_hook "$p" "$hr/docs/usage.md"
   188	  check_case '21 밖+정본 docs/usage.md → 스킵' 0 none ''
   189	}
   190	
   191	case_22() { # 정본 저장소의 _workspace/ 도 스크래치다.
   192	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   193	  mkfile "$hr/_workspace/scratch.md"
   194	  run_hook "$p" "$hr/_workspace/scratch.md"
   195	  check_case '22 밖+정본 _workspace/scratch.md → 스킵' 0 none ''
   196	}
   197	
   198	case_23() { # B1 본체 — 밖 설계 문서에도 듀얼리뷰 게이트가 선다. 같은 축: 케이스 34·35.
   199	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   200	  mkfile "$hr/_workspace/00_design.md"
   201	  run_hook "$p" "$hr/_workspace/00_design.md"
   202	  check_case '23 밖+정본 _workspace/00_design.md → 듀얼리뷰+지식(절대경로)' 0 designdoc "$hr/_workspace/00_design.md"
   203	}
   204	
   205	case_24() { # 순서계약 (나) — 정본 저장소가 **자기 자신에 설치한** 소비 사본은 스킵.
   206	            # 정본(template/.claude/...)만 발화해야 한다. 같은 축: 케이스 07.
   207	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   208	  mkfile "$hr/.claude/hooks/x.sh"
   209	  run_hook "$p" "$hr/.claude/hooks/x.sh"
   210	  check_case '24 밖+정본의 자기 설치 사본 .claude/hooks/x.sh → 스킵' 0 none ''
   211	}
   212	
   213	case_25() { # D3-3 — .git/ 아래 편집은 **상위 저장소**로 귀속시킨다. 그러지 않으면 git 이 .git
   214	            # 안에서 --show-toplevel 에 실패해(실측 rc=128) 판정 불가로 조용히 새어나간다.
   215	            # 같은 축의 음성 쪽은 케이스 36.
   216	  local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   217	  mkfile "$hr/.git/hooks/pre-commit"
   218	  run_hook "$p" "$hr/.git/hooks/pre-commit"
   219	  check_case '25 밖+정본 .git/hooks/pre-commit → 게이트 4종(상위 저장소 귀속)' 0 gate "$hr/.git/hooks/pre-commit"
   220	}
   221	
   222	case_26() { # D1′ — worktree 도 정본이다. 마커(template/.claude/)가 커밋 트리에 실제로
   223	            # 담겨야 성립하므로 make_harness_repo 가 실파일을 커밋한다(--allow-empty 금지).
   224	  local p hr wtp wt; p="$(new_project)"; hr="$(new_harness_repo)"
   225	  wtp="$(new_dir wt)"
   226	  wt="$wtp/tree"
   227	  git -C "$hr" worktree add --detach "$wt" >/dev/null 2>&1
   228	  if [ ! -d "$wt/template/.claude" ]; then
   229	    fixture_broken 'worktree 에 template/.claude 가 없다 (실커밋이 비었나?)'
   230	  else
   231	    mkfile "$wt/scripts/check.sh"
   232	    run_hook "$p" "$wt/scripts/check.sh"
   233	  fi
   234	  check_case '26 밖+정본 worktree scripts/check.sh → 게이트 4종(절대경로)' 0 gate "$wt/scripts/check.sh"
   235	}
   236	
   237	case_27() { # D1′ — 남의 저장소 안에 중첩된 하네스 클론. 귀속은 **가장 안쪽** 저장소다.
   238	            # 픽스처는 중첩 git init 으로 만든다(서브모듈 대체) — 훅은 --show-toplevel 만
   239	            # 보므로 판정이 동일하고, protocol.file.allow 차단으로 CI 가 흔들리지 않는다.
   240	  local p other; p="$(new_project)"; other="$(new_dir other)"
   241	  git -C "$other" init -q
   242	  mkdir -p "$other/vendor/harness"
   243	  make_harness_repo "$other/vendor/harness"
   244	  mkfile "$other/vendor/harness/scripts/check.sh"
   245	  run_hook "$p" "$other/vendor/harness/scripts/check.sh"
   246	  check_case '27 밖+중첩 하네스 클론 scripts/check.sh → 게이트 4종' 0 gate "$other/vendor/harness/scripts/check.sh"
   247	}
   248	
   249	# === C. 프로젝트 밖 — 하네스 정본 아님 ====================================
   250	
   251	case_28() { # B3 순방향 — 남의 git 저장소의 평범한 파일에는 게이트를 세우지 않는다.
   252	  local p other; p="$(new_project)"; other="$(new_dir other)"
   253	  git -C "$other" init -q
   254	  mkfile "$other/vimrc"
   255	  run_hook "$p" "$other/vimrc"
   256	  check_case '28 밖+비정본 저장소 vimrc → 스킵' 0 none ''
   257	}
   258	
   259	case_29() { # D1 — 비정본 저장소라도 .claude/ 앵커에 걸린 하네스 파일은 발화한다.
   260	  local p other; p="$(new_project)"; other="$(new_dir other)"
     1	#!/usr/bin/env bash
     2	# mark-needs-audit.test.sh — mark-needs-audit.sh 의 경로 → 판정 계약 회귀 테스트.
     3	#
     4	# 이 파일은 **진입점**이다: 환경 전제 검사, 픽스처 조립, 실행·판정 헬퍼, 러너.
     5	# 판정 계약 표(케이스 정의 + CASES + EXPECTED_CASES)는 mark-needs-audit.cases.sh 에 있다.
     6	# 한 파일에 두면 800줄을 넘어 표를 계획서와 대조하기 어려워지므로 갈랐다.
     7	#
     8	# 건수는 여기 적지 않는다 — 케이스를 추가할 때마다 낡는다.
     9	# 기계 정본은 케이스 파일의 EXPECTED_CASES 이고 러너가 그 값을 강제한다.
    10	#
    11	# 왜 있나 (2026-08-04 실사고): 하네스 템플릿을 고치는 작업은 늘 PROJECT_DIR 밖의 별도
    12	# 클론에서 일어나는데, 훅이 거기서 통째로 스킵돼 완료 게이트가 하나도 안 섰다. 게이트가
    13	# 프로젝트는 지키면서 정작 하네스 자체 개발만 못 지킨 것이다. 범위 판정은 **조용히**
    14	# 틀리는 종류의 버그라(플래그가 안 서도 아무 에러가 없다) 기계가 붙들어야 한다.
    15	#
    16	# 무엇을 붙드나: check_case 가 매 케이스에서 넷을 본다 — 판정(게이트/듀얼/스킵), 플래그에
    17	# 적히는 **값**(안=상대경로, 밖=절대경로), 종료 코드 0(PostToolUse 는 절대 차단하지 않는다),
    18	# 그리고 stderr 공백 + stdout(기록 실패·경로 개행일 때만 systemMessage JSON 1줄).
    19	#
    20	# 왜 set -e 가 없나: 비영 rc 와 실패 경로를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
    21	#
    22	# 이 파일 자신도 못 믿는다. 러너는 네 가지를 스스로 검사한다:
    23	#   1) CASES 목록의 개수·중복  2) 실행 수 vs 기대 수  (케이스가 조용히 빠지거나 두 번 도는 것)
    24	#   3) pass+fail == ran        (판정을 건너뛰거나 두 번 하는 것)
    25	#   4) DID_RUN 센티널          (직전 케이스의 결과를 재판정하는 것)
    26	#
    27	# 환경 전제 (전부 fail-closed — 조용히 통과시키지 않는다): python3 부재 → 즉시 exit 1
    28	# (json_get 이 조용히 빈 값을 내면 전 케이스가 "스킵"으로 보여 러너 전체가 위음성이 된다).
    29	# git 부재 → 즉시 exit 1(저장소 귀속 판정 행이 전부 무의미해진다).
    30	# root 로 실행 → 권한 픽스처(케이스 40)가 성립하지 않는다. 그 케이스만 fixture_broken.
    31	#
    32	# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.
    33	#
    34	# 사용법: ./tests/mark-needs-audit.test.sh   (전건 통과 시 종료 코드 0)
    35	
    36	set -uo pipefail
    37	
    38	TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    39	REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
    40	HOOK="$REPO_ROOT/template/.claude/hooks/mark-needs-audit.sh"
    41	COMMON="$REPO_ROOT/template/.claude/hooks/_common.sh"
    42	
    43	command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (훅의 json_get 의존)" >&2; exit 1; }
    44	command -v git     >/dev/null 2>&1 || { echo "✗ git 이 필요합니다 (저장소 귀속 판정 픽스처)" >&2; exit 1; }
    45	[ -f "$HOOK" ]   || { echo "✗ 훅을 찾지 못했습니다: $HOOK" >&2; exit 1; }
    46	[ -f "$COMMON" ] || { echo "✗ _common.sh 를 찾지 못했습니다: $COMMON" >&2; exit 1; }
    47	
    48	# mktemp 실패를 확인하지 않으면 TMPROOT 가 빈 문자열이 되고, 이후 경로 조립이
    49	# 전부 "/..." 즉 **파일시스템 루트**를 가리킨다.
    50	TMPROOT="$(mktemp -d)" || exit 1
    51	if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
    52	  echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
    53	  exit 1
    54	fi
    55	# 픽스처 기본계약 1: 모든 픽스처 경로는 물리 경로다. macOS mktemp -d 는 /var/folders/...
    56	# (→ /private/var/... 심링크)를 돌려주므로, 정규화하지 않으면 정상 행이 전부 의도치 않은
    57	# 심링크 축이 된다. 심링크는 케이스 11·12 전용 헬퍼(new_symlinked_project)와 케이스 67·68
    58	# 에서만 **의도적으로** 도입한다 — 67·68 은 프로젝트 **안**에서 밖을 가리키는 링크라
    59	# 모양이 달라 헬퍼를 공유하지 않고 각 케이스 안에서 만든다.
    60	TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
    61	# chmod 는 케이스 40 이 .claude 를 읽기전용으로 만들기 때문에 필요하다.
    62	trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT
    63	
    64	# --- 문구 조각 ------------------------------------------------------------
    65	# 훅 문구가 다듬어져도 계약이 살아 있으면 계속 맞는 최소 조각.
    66	TOK_WRITE_FAIL='게이트 플래그를 기록하지 못했다'
    67	TOK_NEWLINE='편집 경로에 개행이 있어'
    68	TOK_GIT_UNAVAILABLE='git 이 저장소 정보를 돌려주지 못해'
    69	
    70	FLAG_NAMES='.needs-audit .needs-explain .needs-knowledge .needs-dualreview'
    71	
    72	# --- 픽스처 조립 ----------------------------------------------------------
    73	
    74	# new_dir <접두사> — TMPROOT 아래 픽스처 디렉토리를 만들고 **물리 경로**를 낸다.
    75	new_dir() {
    76	  local d
    77	  d="$(mktemp -d "$TMPROOT/$1.XXXXXX")" || exit 1
    78	  if [ -z "$d" ] || [ ! -d "$d" ]; then
    79	    echo "✗ 케이스용 임시 디렉토리를 만들지 못했습니다" >&2
    80	    exit 1
    81	  fi
    82	  ( CDPATH='' cd -- "$d" && pwd -P )
    83	}
    84	
    85	# new_project — 가짜 프로젝트. 훅과 _common.sh 를 **둘 다** 설치한다
    86	# (훅이 dirname "$BASH_SOURCE"/_common.sh 를 source 하므로 하나만 두면 못 돈다).
    87	new_project() {
    88	  local p
    89	  p="$(new_dir proj)"
    90	  mkdir -p "$p/.claude/hooks"
    91	  cp "$HOOK"   "$p/.claude/hooks/mark-needs-audit.sh"
    92	  cp "$COMMON" "$p/.claude/hooks/_common.sh"
    93	  printf '%s\n' "$p"
    94	}
    95	
    96	# make_harness_repo <디렉토리> — 하네스 정본 저장소 구조를 만들고 **실커밋**한다.
    97	# --allow-empty 를 쓰지 않는다: git 은 빈 디렉토리를 추적하지 않으므로 template/.claude/ 아래에
    98	# 실파일이 없으면 worktree(케이스 26)에서 정본 마커가 거짓이 된다 — 올바른 구현인데도 빨개진다.
    99	make_harness_repo() {
   100	  local r="$1"
   101	  mkdir -p "$r/template/.claude/agents" "$r/template/.claude/skills" \
   102	           "$r/template/.claude/hooks"  "$r/template/.claude/harness" \
   103	           "$r/scripts" "$r/docs" "$r/_workspace" "$r/global-agents"
   104	  printf '# common\n'        > "$r/template/.claude/hooks/_common.sh"
   105	  printf '{}\n'              > "$r/template/.claude/settings.json"
   106	  printf '# plan-reviewer\n' > "$r/template/.claude/agents/plan-reviewer.md"
   107	  git -C "$r" init -q
   108	  git -C "$r" add -A
   109	  git -C "$r" -c user.email=t@t -c user.name=t commit -q -m init
   110	}
   111	
   112	# new_harness_repo — 프로젝트 골격 + 하네스 정본 구조. CLAUDE_PROJECT_DIR 자신이
   113	# 정본인 케이스 50 이 이 결과를 PROJ 로 쓰기 때문에 훅 설치본도 함께 들고 있어야 한다.
   114	new_harness_repo() {
   115	  local r
   116	  r="$(new_project)"
   117	  make_harness_repo "$r"
   118	  printf '%s\n' "$r"
   119	}
   120	
   121	# new_symlinked_project — 심링크 축(케이스 11·12) 전용. RED 전제 2개:
   122	#   ① file_path 는 **물리**($REPO/app/...), CLAUDE_PROJECT_DIR 은 **심링크**($REPO/link).
   123	#      반대로 주면 접두사가 그냥 맞아떨어져 두 행이 비차별 행으로 죽는다.
   124	#   ② $REPO 가 **git 저장소**여야 기반 커밋 판이 밖 분기로 새어 오기록이 드러난다.
   125	new_symlinked_project() {
   126	  local repo
   127	  repo="$(new_dir symrepo)"
   128	  git -C "$repo" init -q
   129	  mkdir -p "$repo/app/.claude/hooks"
   130	  cp "$HOOK"   "$repo/app/.claude/hooks/mark-needs-audit.sh"
   131	  cp "$COMMON" "$repo/app/.claude/hooks/_common.sh"
   132	  ln -s "$repo/app" "$repo/link"
   133	  printf '%s\n' "$repo"
   134	}
   135	
   136	# mkfile <경로> — 픽스처 기본계약 2: 대상 파일의 **부모 디렉토리를 만들고** 빈 파일을 만든다.
   137	# 예외는 셋뿐이고 전부 그 케이스 주석에 예외임을 적었다: 케이스 51(부모 디렉토리를 일부러
   138	# 만들지 않는다)·케이스 69·70(편집 경로가 디렉토리라 파일이 없다 — mkdir 만 한다).
   139	#
   140	# dirname 을 쓰지 않는 이유(실측): 명령 치환은 후행 개행을 지우므로 `sr⏎` 디렉토리가 조용히
   141	# `sr` 로 바뀌어 케이스 57 의 파일 생성이 실패했다 — 이 러너가 붙들려는 결함 유형(값이 조용히
   142	# 변조된다)에 러너 자신이 물린 것이다. ${1%/*} 파라미터 확장은 개행을 보존한다.
   143	#
   144	# 실패하면 FIXTURE_FAIL 센티널을 세운다. check_case 가 이걸 먼저 보고 빨갛게 만들므로
   145	# "픽스처가 안 만들어졌는데 판정만 우연히 맞아 초록"이 되지 않는다(fail-closed).
   146	# 중괄호가 필요하다: 리다이렉트 **열기** 실패는 셸이 보고하는데, 명령 뒤에 붙인
   147	# 2>/dev/null 은 그 시점에 아직 적용되지 않아 러너 자신의 stderr 가 샌다(케이스 40 과 같은 함정).
   148	mkfile() {
   149	  local dir="${1%/*}"
   150	  [ "$dir" = "$1" ] && dir='.'   # 슬래시 없는 상대 경로
   151	  [ -z "$dir" ]     && dir='/'   # 루트 바로 아래
   152	  if ! mkdir -p -- "$dir" 2>/dev/null; then
   153	    FIXTURE_FAIL="부모 디렉토리를 만들지 못했다: $dir"
   154	    return 1
   155	  fi
   156	  if ! { : > "$1"; } 2>/dev/null; then
   157	    FIXTURE_FAIL="파일을 만들지 못했다: $1"
   158	    return 1
   159	  fi
   160	}
   161	
   162	payload_json() {
   163	  python3 -c 'import json, sys
   164	print(json.dumps({"tool_input": {"file_path": sys.argv[1]}}))' "$1"
   165	}
   166	
   167	# --- 실행·판정 헬퍼 -------------------------------------------------------
   168	
   169	OUT=''
   170	ERR=''
   171	RC=0
   172	STATE=''
   173	DID_RUN=0   # 이번 케이스에서 훅(또는 정적 검사)을 실제로 돌렸는가 — 센티널
   174	FIXTURE_FAIL=''   # 이번 케이스의 픽스처 조립이 실패했는가 — 사유(빈 문자열이면 정상)
   175	
   176	# 플래그가 하나도 없는 빈 디렉토리. 훅을 돌리지 않는 케이스(정적 검사·픽스처 실패)가
   177	# STATE 로 쓴다 — 직전 케이스의 플래그를 재판정하지 않게 하기 위함이다.
   178	EMPTY_STATE="$(new_dir emptystate)"
   179	
   180	# run_hook_raw <proj> <payload> [env 인자...]
   181	# 앰비언트 탈출구를 **소거**하고 부른다. 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off /
   182	# ECC_DISABLED_HOOKS 를 export 한 셸에서 도는 워크플로라, 소거하지 않으면 게이트·듀얼 행이
   183	# 전부 무판정으로 떨어져 러너가 통째로 위음성이 된다. 케이스 43·44 만 **의도적으로** 다시
   184	# 주입한다(env 는 -u 를 먼저 처리하고 그 뒤 할당을 적용하므로 재주입이 이긴다 — 실측 확인).
   185	# GIT_* 소거는 러너를 git 훅 안에서 돌렸을 때 귀속 판정이 오염되는 것을 막는다.
   186	run_hook_raw() {
   187	  local proj="$1" payload="$2"
   188	  shift 2
   189	  OUT=''; ERR=''; RC=999; DID_RUN=1
   190	  STATE="$proj/.claude"
   191	  local errf="$TMPROOT/stderr.$$"
   192	  OUT="$(printf '%s' "$payload" \
   193	        | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
   194	              -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
   195	              ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
   196	              bash "$proj/.claude/hooks/mark-needs-audit.sh" 2>"$errf")"
   197	  RC=$?
   198	  ERR="$(cat "$errf" 2>/dev/null)"
   199	  rm -f "$errf"
   200	}
   201	
   202	# run_hook <proj> <file_path> [env 인자...]
   203	run_hook() {
   204	  local proj="$1" fp="$2"
   205	  shift 2
   206	  run_hook_raw "$proj" "$(payload_json "$fp")" ${@+"$@"}
   207	}
   208	
   209	# run_static_check <설명> <grep -E 패턴> — 훅 **본문**에 대한 정적 계약 검사 전용 진입점.
   210	# 훅을 호출하지 않는 케이스이지만 DID_RUN 센티널은 살아 있어야 한다. check_case 안에서
   211	# 센티널을 세우는 우회를 하면 나머지 전 행의 센티널이 통째로 무력화되므로 **진입점 쪽**에서 세운다.
   212	# 검사 대상은 저장소의 정본 훅이다(픽스처 사본이 아니다) — 그래야 되돌림 실측에서 함께 뒤집힌다.
   213	run_static_check() {
   214	  OUT=''; ERR=''; RC=0; DID_RUN=1
   215	  STATE="$EMPTY_STATE"
   216	  local hits
   217	  hits="$(grep -nE "$2" "$HOOK")"
   218	  if [ -n "$hits" ]; then
   219	    OUT="정적 계약 위반 — $1
   220	$hits"
   221	    RC=1
   222	  fi
   223	}
   224	
   225	# 픽스처를 이 환경에서 만들 수 없을 때. 조용히 넘어가지 않고 실패로 남긴다.
   226	fixture_broken() {
   227	  OUT="픽스처 구성 실패: $1"
   228	  ERR=''
   229	  RC=-1
   230	  STATE="$EMPTY_STATE"
   231	  DID_RUN=1
   232	}
   233	
   234	ran=0
   235	pass=0
   236	fail=0
   237	
   238	# flag_bytes <플래그이름> — 플래그 파일 내용을 **바이트 그대로** FLAG_BYTES 에 담는다.
   239	# stdout 으로 돌려주지 않는 이유: 호출자의 명령 치환이 후행 개행을 지워버려 "값 한 줄"과
   240	# "두 줄이었는데 덮어써진 것"·"개행이 섞여 들어간 것"이 구분되지 않는다. 센티널 X 를
   241	# 붙여 받고 도로 떼면 바이트가 보존된다. 파일이 없으면 빈 문자열.
   242	FLAG_BYTES=''
   243	flag_bytes() {
   244	  local raw
   245	  raw="$(cat "$STATE/$1" 2>/dev/null; printf 'X')"
   246	  FLAG_BYTES="${raw%X}"
   247	}
   248	
   249	# verdict_mismatch <gate|dual|none> <값> — 어긋난 사유를 내고, 맞으면 아무것도 안 낸다.
   250	# <값>은 **줄 목록**이다 — 여러 줄이면 줄 수와 기록 **순서**까지 계약이 된다(케이스 58).
   251	# 기대 바이트열은 각 줄 뒤에 개행 하나씩: record_flag 가 printf '%s\n' 로 덧붙이므로.
   252	# gate      = 4종 전부가 그 바이트열
   253	# designdoc = .needs-dualreview + .needs-knowledge (설계·계획 산출물)
   254	# knowledge = .needs-knowledge 만 (결정 문서 — 코드가 아니라 게이트 4종은 과하다)
   255	# none      = 4종 전부 부재·공백
   256	verdict_mismatch() {
   257	  local kind="$1" value="$2" f want
   258	  for f in $FLAG_NAMES; do
   259	    want=''
   260	    case "$kind" in

2026-08-10T03:50:55.492694Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "nl -ba docs/decisions/2026-08-05-knowledge-store-layer-boundary.md | sed -n '1,280p'
nl -ba docs/decisions/2026-08-06-knowledge-gate-default-on.md | sed -n '1,320p'
nl -ba docs/decisions/2026-08-06-knowledge-retrieval-policy.md | sed -n '1,260p'
nl -ba docs/decisions/2026-08-06-profile-canon-upstream.md | sed -n '1,260p'
nl -ba docs/usage.md | sed -n '1,260p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
     1	# ADR-0006: 지식 저장소는 상위 층이다 — 하네스는 계약만 알고 구현을 모른다
     2	
     3	**Date**: 2026-08-05
     4	**Status**: accepted (이행 완료 2026-08-10 — 아래 "이행 결과")
     5	**Deciders**: 김태윤(계층 정의·요구 확정), Claude(위반 실측·설계)
     6	
     7	---
     8	
     9	## Context
    10	
    11	kty의 시스템은 두 덩어리다.
    12	
    13	| | 무엇 | 성격 |
    14	|---|---|---|
    15	| **second brain / llm wiki** (볼트) | kty의 **모든** 지식을 담는 곳 | **상위.** 하네스가 없어도 존재한다 |
    16	| **harness** (이 저장소) | 프로젝트를 잘 수행하려고 만든 도구 | **하위.** 상위를 참조할 수 있다 |
    17	
    18	kty가 못박은 요구: **각자 따로 설치돼도 문제없이 돌아가야 한다.**
    19	
    20	### 지금은 그 요구가 깨져 있다
    21	
    22	2026-08-02 "볼트 반영 산문 규칙이 세션 내내 0회 이행" 실사고 뒤, 이 저장소의 교훈("산문으로만 존재하는 절차는 훅·게이트로 승격하라")에 따라 볼트 반영을 완료 게이트로 올렸다. 그런데 **완료를 강제하는 기계가 하네스뿐**이라, 갈 곳이 없어 볼트 지식이 글루 층으로 들어갔다.
    23	
    24	실측 — `template/` 아래 볼트 고유 표현 **10건 / 4파일**:
    25	
    26	| 파일 | 무엇이 새어 있나 |
    27	|---|---|
    28	| `template/.claude/skills/harness-orchestrator/SKILL.md` | `Projects/<name>/` 4종 세트, `_CLAUDE.md`, `specs/`, `second brain` |
    29	| `template/.claude/hooks/mark-needs-audit.sh` | `.needs-vault` |
    30	| `template/.claude/hooks/verify-before-stop.sh` | `.needs-vault` |
    31	| `template/.claude/hooks/_common.sh` | `.needs-vault` |
    32	
    33	`README.md`가 이 저장소를 *"제네릭 에이전트 8 (**도메인 누출 0**)"* 이라 설명하고, 탄생 이유를 *"도메인 지식이 에이전트 5+곳에 산재 → 단일 프로필 슬롯"* 이라 적었다. **자기 원칙 위반이다.** 그리고 제0원칙 4번(**구체가 아닌 계약에 의존** — DIP)에도 걸린다.
    34	
    35	**의존은 한 방향뿐이다.** 볼트 코드가 하네스를 읽거나 존재를 전제하는 곳은 0건이다(`_CLAUDE.md`·`sync_adr.py`의 "하네스 운영 등" 3건은 결정 분류 **예시**). 하네스를 지워도 볼트는 정상 작동한다. 반대는 지금 깨진다 — 볼트 없이 설치하면 게이트가 존재하지 않는 구조를 요구한다.
    36	
    37	## Decision
    38	
    39	**계약은 하네스가 소유하고, 볼트는 그 계약의 구현체 중 하나이며, 둘을 잇는 설정은 사용자 층에 둔다.**
    40	
    41	```
    42	① 계약 (하네스 소유)
    43	   "지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다"
    44	   볼트를 언급하지 않는다. 경로도 구조도 모른다.
    45	
    46	② 구현체 (볼트 소유)
    47	   Projects/<name>/ 4종 세트 · _CLAUDE.md · specs/ · 인덱스 등재
    48	   하네스를 모른다.
    49	
    50	③ 접착 (사용자 층 — 전역 CLAUDE.md)
    51	   "이 머신의 지식 저장소는 볼트다" + 그 형식 안내
    52	```
    53	
    54	**슬롯은 이미 있는 관용구를 쓴다.** `harness.env`의 `HARNESS_TYPECHECK_CMD=""`가 *"비우면 Stop 훅이 타입체크를 생략한다"* 인 것과 같은 모양으로:
    55	
    56	```bash
    57	# 지식 반영 게이트. 비우면 생략한다(지식 저장소를 안 쓰는 환경).
    58	# 어디에·어떤 구조로 반영하는지는 이 파일이 모른다 — 사용자 전역 설정이 답한다.
    59	HARNESS_KNOWLEDGE_GATE=""
    60	```
    61	
    62	**훅은 경로를 알 필요조차 없다.** 하는 일이 "플래그가 섰는데 안 지워졌으면 종료 차단"이라 켜짐/꺼짐 하나면 된다. *어디에 어떻게 저장했는지의 검증은 볼트 자기 훅(4종 세트 pre-commit)이 이미 한다.*
    63	
    64	플래그 이름도 계약 수준으로 올린다: `.needs-vault` → `.needs-knowledge`.
    65	
    66	## Alternatives Considered
    67	
    68	### A. 볼트가 인터페이스를 소유하고 하네스가 구현체
    69	- **Pros**: 상위 층이 규격을 정한다는 직관에 맞음
    70	- **Cons**: 인터페이스를 알려면 볼트가 있어야 한다 → **볼트를 지우면 하네스가 자기가 뭘 호출할지 모른다.** kty의 "각자 단독 작동" 요구와 정면 충돌. 지금 상태가 정확히 이것
    71	- **Why not**: 요구를 못 지킨다
    72	
    73	### B. `install.sh` 가 볼트 설치 여부를 **탐지**
    74	- **Pros**: 사용자가 설정을 안 해도 됨
    75	- **Cons**: 탐지하려면 경로·구조를 알아야 한다 → **걷어내려는 결합을 다시 도입한다.** 볼트를 다른 경로에 뒀거나 나중에 설치하면 틀린다
    76	- **Why not**: 확인(detect)이 아니라 설정(configure)이어야 층이 유지된다. 대화형으로 **묻는** 것은 허용(사용자에게 위임이라 하네스가 볼트를 알게 되지 않음), 단 비대화형 설치를 깨뜨리므로 선택지일 뿐
    77	
    78	### C. `project-profile.md` 에 §10 "지식 저장소" 슬롯 신설
    79	- **Cons**: 프로필은 **프로젝트별**인데 지식 저장소는 **사용자별**이다. 프로젝트마다 같은 값을 적으면 언젠가 어긋난다
    80	- **Why not**: 중복이 드리프트를 만든다. 실제로 이 저장소는 문서 숫자 하나가 일곱 번 낡는 걸 겪었다(PR #10)
    81	
    82	### D. 아무것도 안 하고 산문으로 둔다
    83	- **Why not**: 2026-08-02 실사고가 정확히 그래서 났다
    84	
    85	## Consequences
    86	
    87	### Positive
    88	- **도메인 누출 0 회복** — 하네스가 다시 도메인-무관 글루가 된다
    89	- **교체 가능** — 볼트를 Notion 등으로 바꿔도 하네스는 안 고친다(제0원칙 3)
    90	- **양쪽 단독 설치 정상** — 볼트 없으면 게이트 no-op, 하네스 없어도 볼트 그대로
    91	- 새 메커니즘 0개 — 기존 슬롯 관용구 재사용
    92	
    93	### Negative
    94	- 사용자가 한 줄을 켜야 게이트가 산다. 안 켜면 조용히 안 돈다 — `install.sh` 안내 문구로 완화
    95	- 기존 설치본은 `sync.sh` 후 슬롯을 채워야 한다(슬롯은 보존되므로 자동으로 안 켜짐)
    96	
    97	## 기계적 장치 — 산문으로 두지 않는다
    98	
    99	이 경계는 **grep으로 판정 가능하다.** 조회 라우팅 같은 "행동"과 달리 "글루에 상위 층 구현이 있나"는 기계가 100% 답한다.
   100	
   101	`scripts/check-layer-boundary.sh` (신설 예정):
   102	- `template/` 아래에서 상위 층 고유 표현을 찾으면 `exit 1`
   103	- 금지 목록: 볼트 경로 · `second brain` · `_CLAUDE.md` · `4종 세트` · `Projects/<name>/` · `needs-vault`
   104	- CI(`check-rules.yml`)에 스텝 추가
   105	- 메시지: "하네스 글루에 상위 층 구현이 샜다 — 계약만 남기고 구현은 사용자 층으로"
   106	
   107	이 검사는 볼트에 한정되지 않는다. **`README.md`가 선언한 "도메인 누출 0"을 처음으로 기계가 지키게 된다.**
   108	
   109	## 이행 결과 (2026-08-10)
   110	
   111	`refactor/knowledge-store-layer` 에서 이행했다.
   112	
   113	- **누출 정리**: `template/` 아래 상위 층 표현 **13건/4파일 → 0건**. 훅 3개(`_common.sh`·`mark-needs-audit.sh`·`verify-before-stop.sh`)와 오케스트레이터 스킬에서 구현을 걷어내고 계약 문장만 남겼다
   114	- **플래그 개명**: `.needs-vault` → `.needs-knowledge`
   115	- **슬롯 신설**: `harness.env` 의 `HARNESS_KNOWLEDGE_GATE`. 판독 규칙과 기본값은 [ADR-0008](2026-08-06-knowledge-gate-default-on.md) 로 갈라졌다 — 이 ADR의 *"슬롯을 비우면 생략"* 관용구를 **일부 supersede** 한다. 기존 설치본에 키가 없으므로 "없음 = 꺼짐"이면 업그레이드가 게이트를 조용히 끈다. 그래서 **없으면 켜짐**이다
   116	- **접착 층 안내**: `CLAUDE.md.snippet` 에 "지식 저장소 연결은 전역 `CLAUDE.md` 가 답한다"를 명시
   117	- **기계 강제**: `scripts/check-layer-boundary.sh` + CI 스텝. 회귀 테스트 14건이 그 검사기를 지킨다
   118	- **조회 방향**: 이행 중에 프로필 정본 위치 문제가 갈라져 나와 [ADR-0009](2026-08-06-profile-canon-upstream.md) 가 됐고, 회수 **정책**은 미설계로 [ADR-0010](2026-08-06-knowledge-retrieval-policy.md) 에 못박았다
   119	
   120	**"금지 목록"의 실제 구현은 설계와 조금 다르다.** 여기서는 목록만 적었는데, 구현은 각 패턴에 **왜 상위 층인가**를 붙였다 — "금지됐다"만 알려주는 검사는 걸린 사람이 무엇을 계약 수준으로 다시 써야 하는지 몰라 우회당한다.
   121	
   122	**설계 당시의 우려 하나는 빗나갔다.** *"정리 완료 후에 검사기를 켜라(지금 켜면 즉시 빨간불)"* 이라고 적었는데, 실제로는 검사기를 먼저 만들고 그것으로 누출을 **찾아가며** 정리하는 편이 빨랐다. 13건은 손으로 세었을 때보다 3건 많았다.
   123	
   124	## 관련
   125	- [ADR-0001](2026-07-18-memory-tiers-and-adr-process.md) — 메모리 3계층
   126	- [ADR-0002](2026-07-20-global-agents-layer.md) — 전역 에이전트 층(정본이 repo인 이유)
   127	- 볼트: `Projects/harness-template/index.md`
     1	# ADR-0008: 지식 게이트는 기본 켜짐 — 표명이 없으면 이전 동작을 보존한다
     2	
     3	**Date**: 2026-08-06 (구현·정정 2026-08-10)
     4	**Status**: accepted
     5	**Deciders**: 김태윤(요구 확정), Claude(설계·실측)
     6	
     7	---
     8	
     9	## Context
    10	
    11	[ADR-0006](2026-08-05-knowledge-store-layer-boundary.md)이 지식 반영 게이트를 껐다 켤 수 있게 만들라고 했다. **스위치를 어디에 두고 어떻게 읽을지**가 이 ADR이다.
    12	
    13	두 질문이 걸려 있다.
    14	
    15	### 질문 1 — 1비트를 얻으려고 사용자 소유 셸 파일을 실행해도 되나
    16	
    17	슬롯은 `harness.env` 다. 확장자와 문법이 셸이니 처음 설계는 그 파일을 **`source` 해서** 값을 읽었다. 그런데 막을 때마다 새 탈출 경로가 나왔다. 전부 실측이다:
    18	
    19	| 파일에 넣은 것 | 결과 |
    20	|---|---|
    21	| `exit 1` | 훅이 rc=1 로 죽는다 → 완료 게이트 4종이 통째로 소멸 |
    22	| `exit 0` | 훅이 조용히 rc=0 → 게이트 소멸 + **흔적 0** |
    23	| 서브셸로 감싸자 `return` | 호출 셸로 정상 복귀해 판정을 통과 |
    24	| 리다이렉트로 막자 `printf` 재정의 | 진단 출력 자체를 위조 |
    25	
    26	이건 악의를 가정한 위협 모델이 아니다. 사용자가 실수로 `exit` 한 줄을 남기거나 다른 도구가 그 파일에 무언가를 덧붙이기만 해도 **게이트가 흔적 없이 사라진다.**
    27	
    28	### 질문 2 — 키가 없을 때 어느 쪽으로 읽어야 하나
    29	
    30	기존 설치본의 `harness.env` 에는 이 키가 **아예 없다.** 없을 때를 "꺼짐"으로 읽으면 하네스를 갱신하는 순간 게이트가 조용히 꺼진다.
    31	
    32	## Decision
    33	
    34	**① 게이트 값은 실행하지 않는다. 원문으로 읽는다.**
    35	
    36	1비트에 임의 코드 실행의 위험을 질 이유가 없다. 실행하지 않으면 위 부류가 **원리적으로** 소멸한다 — 판독 결과를 바꾸는 유일한 방법이 "그 키를 다르게 쓰는 것"이 되고, 그게 정확히 의도적으로 값을 바꾸는 방법이다.
    37	
    38	**② 판독 모델: 선행 공백 없는 최상위 선언이 정확히 1개일 때만 그 값을 믿는다.**
    39	
    40	조건문·함수 본문 안의 대입은 실행돼야 발효하는데 이 파일은 실행되지 않으므로, 원문만으로는 발효 여부를 알 수 없다. 선언이 2개 이상이면 어느 것이 이기는지도 알 수 없다.
    41	
    42	**③ 끄는 방법은 값을 리터럴로 비우는 것 하나뿐. 그 외는 전부 켜짐.**
    43	
    44	키가 없어도 · 선언이 2개여도 · 지원 문법 밖이어도 **켠다.** 업그레이드가 게이트를 조용히 끄는 것이 이 설계에서 가장 나쁜 결과이기 때문이다. 사용자는 지식이 쌓인다고 믿는데 그 턴부터 아무것도 안 남고, 아무 에러도 안 난다.
    45	
    46	`sync.sh` 는 키가 없는 설치본에 `HARNESS_KNOWLEDGE_GATE="on"` 을 **덧붙이기만** 한다 — 동작은 어차피 같지만, 파일에 한 줄도 없으면 사용자가 그런 스위치가 있다는 것 자체를 모른다.
    47	
    48	**④ 실행을 버리면 셸 파서 의무를 물려받는다 (2026-08-10 정정).**
    49	
    50	원래 설계는 여기까지였고, 그것이 부족했다. `source` 를 버린 뒤 파싱을 절반만 해서 **fail-open 을 없애려다 다른 fail-open 6종**을 만들었다. 값에 쓰레기가 섞여 `sh -c` 가 rc=127 을 내고, 호출부가 그걸 "도구가 없구나"로 읽어 검사를 조용히 생략한다:
    51	
    52	| 입력 | 실행했다면 | 절반만 판독하면 |
    53	|---|---|---|
    54	| `KEY="cmd" # 메모` | `cmd` | `"cmd" # 메모` 전체 → rc=127 |
    55	| `KEY="cmd"` + 후행 공백 | `cmd` | `"cmd"   ` → rc=127 · **눈에 안 보인다** |
    56	| CRLF 줄끝 | `cmd` | `"cmd"\r` → rc=127 · **눈에 안 보인다** |
    57	| 파일 앞 BOM | 무해 | 첫 키가 **무매치** → 미설정 |
    58	| 히어독 본문의 같은 키 | 선언 아님 | **선언으로 셈** → "2개" 판정 |
    59	
    60	그래서 판독 순서를 계약으로 고정한다:
    61	
    62	```
    63	① BOM 제거 → ② CR 제거 → ③ 히어독 본문 배제 → ④ 선언 판정
    64	→ ⑤ 값 앞 공백 절단 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 밖 후행 주석 → ⑧ 남은 후행 공백 절단
    65	```
    66	
    67	그리고 **지원 문법을 좁게 고정하고 문서에 적는다.** 사용자는 "셸 파일이니 셸 문법이 다 되겠지"라고 가정하기 때문이다. 문법 밖은 조용히 절반만 읽지 않고 전부 "값을 믿을 수 없음"으로 떨어진다.
    68	
    69	**⑤ "리터럴로 비웠다"와 "값을 믿을 수 없다"를 반환 코드로 가른다.**
    70	
    71	스위치형 슬롯에서 이 둘은 **반대 방향**이다(전자는 끄고, 후자는 켠다). 빈 문자열 하나로 뭉뚱그리면 사용자가 일부러 끈 것과 키가 없는 기존 설치본이 구별되지 않는다.
    72	
    73	## Alternatives Considered
    74	
    75	### A. `source` 하되 서브셸·리다이렉트로 가둔다
    76	- **Pros**: 셸 문법을 공짜로 얻는다. 파서를 직접 쓰지 않아도 된다
    77	- **Cons**: 막을 때마다 새 탈출 경로가 나왔다(위 표). 서브셸로 막으니 `return`, 리다이렉트로 막으니 `printf` 재정의
    78	- **Why not**: 창을 좁히는 접근이라 끝이 없다. **부류를 없애야** 멈춘다
    79	
    80	### B. 값을 JSON·INI 등 비실행 형식으로 바꾼다
    81	- **Pros**: 파싱 계약이 명확하고 셸 파서 의무를 안 물려받는다
    82	- **Cons**: 기존 설치본의 `harness.env` 를 전부 마이그레이션해야 하는데, 슬롯은 프로젝트 소유라 하네스가 덮을 수 없어 강제할 수단이 없다
    83	- **Why not**: 이행 비용이 얻는 것보다 크다. 지원 문법을 좁혀 문서화하는 것으로 같은 안전성에 도달한다
    84	
    85	### C. 키가 없으면 꺼짐 (관용구 일관성)
    86	- **Pros**: `HARNESS_TYPECHECK_CMD` 의 "비우면 생략" 과 모양이 같다
    87	- **Cons**: 기존 설치본에는 키가 없다 → **업그레이드가 게이트를 조용히 끈다**
    88	- **Why not**: 관용구 일관성보다 동작 보존이 무겁다. 조용히 꺼지는 게이트는 없는 것만 못하다
    89	
    90	### D. `="off"` 도 꺼짐으로 인정한다
    91	- **Pros**: 직관적이다. `off` 라고 적으면 꺼지리라 기대하는 것이 자연스럽다
    92	- **Cons**: "리터럴로 비었을 때만 끈다"는 단일 규칙이 깨지고, 그 다음엔 `false`·`0`·`no`·`OFF` 를 어디까지 인정할지가 끝없이 이어진다. 인정 목록에서 빠진 표기를 쓰면 **사용자는 껐다고 믿는데 켜져 있다**
    93	- **Why not**: 규칙을 하나로 유지하고, 대신 그 직관 충돌을 **세 곳에 명시**한다(`harness.env` 주석 · `docs/usage.md` · 오케스트레이터 스킬)
    94	
    95	## Consequences
    96	
    97	### Positive
    98	- 임의 코드 실행 부류가 원리적으로 소멸
    99	- 업그레이드가 게이트를 조용히 끄는 경로가 없다
   100	- 실패 방향이 전부 "켜짐" 쪽이다 — 판독이 어떻게 틀려도 게이트는 살아 있다
   101	
   102	### Negative
   103	- **셸 파서 의무를 물려받았다.** 지원 문법이 좁고, 그 사실을 사용자가 알아야 한다
   104	- `="off"` 가 켜짐으로 읽히는 것은 직관에 반한다. 문서로만 완화된다
   105	- 히어독 탐지는 근사다. 한 줄에 히어독이 둘이면 첫 개만 본다
   106	
   107	### 실패 방향이 왜 안전한가
   108	히어독 탐지가 어느 쪽으로 틀려도 결과는 "값을 믿을 수 없음"으로 수렴한다 — 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다. 둘 다 게이트는 **켜짐**이다.
   109	
   110	## 기계적 장치
   111	
   112	`tests/harness-env-read.test.sh` 가 판독 계약(반환 코드 + 값의 바이트)과 게이트 계약을 붙든다.
   113	
   114	게이트 케이스는 `harness.env` 의 키 개수와 값을 **직접 해석하지 않는다.** 지식 플래그 하나만 세우고 **훅 자신을 돌려** 차단되는지를 본다 — 판독 규칙의 사본을 테스트에 두면 그 사본이 언젠가 원본과 어긋나고, 그때 테스트는 **틀린 기준으로 초록**을 낸다.
   115	
   116	통합 케이스는 종료 코드만 보지 않는다. 타입체크를 건너뛰어도 뒤의 감사 게이트가 어차피 rc=2 로 막으므로, **어느 게이트가 막았는지의 문구**까지 재야 판별력이 생긴다.
   117	
   118	## 관련
   119	- [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md) — 층 경계(이 스위치가 필요한 이유)
   120	- [ADR-0009](2026-08-06-profile-canon-upstream.md) — 프로필 정본과 조회 배선
   121	- [ADR-0010](2026-08-06-knowledge-retrieval-policy.md) — 회수 정책은 아직 없다
     1	# ADR-0010: 지식 회수 정책 — 배관은 깔렸고 정책은 아직 없다
     2	
     3	**Date**: 2026-08-06 (기록 2026-08-10)
     4	**Status**: **proposed** — 이건 "아직 안 정했다"를 못박는 ADR이다
     5	**Deciders**: 김태윤(공백 지적), Claude(범위 정리)
     6	
     7	---
     8	
     9	## Context
    10	
    11	[ADR-0009](2026-08-06-profile-canon-upstream.md)가 **조회 방향을 배선**했다 — 프로필 9절 "지식 진입점" 슬롯, `ecc:architect`·`ecc:planner` 주입, 산출물 첫 줄의 `사전 결정 회수:`.
    12	
    13	그것은 **배관**이다. 물이 **어디서 어디로 얼마나** 흐르는지는 정하지 않았다.
    14	
    15	kty 가 이 공백을 직접 물었다 — *"harness 가 꺼내올 때 어떤 기준을 가지고, 어떤 상황에서 어떤 로직을 발동해서 꺼내올 것인가에 대한 설계는 한 거야?"* 답은 **안 했다** 였다.
    16	
    17	**이 ADR을 쓰는 이유는 배선의 존재가 정책의 존재처럼 보이기 때문이다.** 프로필에 슬롯이 있고 에이전트가 `사전 결정 회수:` 를 찍고 있으면 다음 사람은 회수가 설계된 기능이라고 믿는다. 실제로는 "경로 하나 주고 알아서 읽어라"가 전부다. **거짓 공시는 남은 결함보다 나쁘다.**
    18	
    19	## Decision
    20	
    21	**정책을 정하지 않는다. 대신 공백을 명시적으로 못박고 후속으로 넘긴다.**
    22	
    23	지금 확정하는 것은 셋뿐이다:
    24	
    25	1. **배관은 유지한다.** 진입점 슬롯 · 두 에이전트 주입 · `사전 결정 회수:` 표명. 정책이 정해지면 그 위에 얹는다
    26	2. **하네스는 진입점 너머를 모른다는 계약을 유지한다.** 회수 정책을 정할 때도 이 선을 넘지 않는다 — 넘는 순간 [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md)이 무효가 된다
    27	3. **회수 품질을 하네스가 보장하지 않는다고 공시한다.** 진입점 너머의 라우팅 품질에 전적으로 달렸다
    28	
    29	### 확인된 공백 4개 (후속 설계의 입력)
    30	
    31	1. **트리거가 좁다.** 착수 전 1회, `ecc:architect`·`ecc:planner` 둘뿐이다. `developer`·검수자는 회수 단계가 없는데, "이 부분 전에 어떻게 정했더라"가 나오는 순간은 실제로 구현 중이 더 잦다
    32	2. **선택 기준이 전무하다.** 진입점 하나를 주고 "알아서 읽어라". 결정이 100건이면 무엇을 읽을지는 전적으로 저쪽 라우팅에 달렸고, 하네스는 아무 보장도 안 한다
    33	3. **표명과 실행이 분리돼 있다.** `사전 결정 회수:` 는 형식만 검증되니 읽었다고 적고 안 읽어도 통과한다. 이걸 강제로 올리려면 하네스가 그 경로의 내용 구조를 알아야 하는데 그건 층 위반이다 — **이 긴장이 후속 설계의 핵심 난점이다**
    34	4. **`claude-mem` 과의 분업이 미정이다.** 회수 경로가 둘인데 언제 무엇을 쓰는지 규정이 없다. 하나는 압축된 세션 히스토리, 하나는 큐레이션된 결정 기록이라 성격이 다른데 그 차이가 어디에도 안 적혀 있다
    35	
    36	### 이 ADR이 **정하지 않은** 것
    37	
    38	- 회수 트리거를 어디까지 넓힐지
    39	- 여러 결정 중 무엇을 읽을지의 선택 기준을 하네스가 가질지, 끝까지 상위 층에 맡길지
    40	- 표명을 강제로 올릴 방법이 층을 지키면서 가능한지
    41	
    42	## Alternatives Considered
    43	
    44	### A. 지금 정책까지 설계한다
    45	- **Pros**: 배선과 정책이 함께 온다. 반쯤 된 기능이 남지 않는다
    46	- **Cons**: 공백 2번(선택 기준)은 **저쪽 라우팅의 품질을 관측한 뒤에야** 답할 수 있다. 지금 정하면 관측 없이 정하는 것이고, 그렇게 정한 기준은 곧 어긋난다
    47	- **Why not**: 근거 없이 정한 정책이 정책 없음보다 나쁘다 — 있으면 사람들이 믿는다
    48	
    49	### B. 배선을 걷어내고 정책이 정해질 때까지 미룬다
    50	- **Pros**: "반쯤 된 기능"이 없어진다
    51	- **Cons**: 회수 방향이 **0** 으로 돌아간다. 지금 배선만으로도 착수 전 1회 회수는 실제로 일어난다
    52	- **Why not**: 불완전한 회수가 회수 없음보다 낫다. 다만 그 불완전함을 숨기지 않는 것이 조건이다
    53	
    54	### C. 아무것도 기록하지 않는다
    55	- **Why not**: 그러면 다음 사람이 배선을 보고 정책이 있다고 믿는다. 이 ADR의 존재 이유가 정확히 그것을 막는 것이다
    56	
    57	## Consequences
    58	
    59	### Positive
    60	- "설계됐다"와 "배선만 됐다"가 구별된다
    61	- 후속 설계의 입력(공백 4개)이 흩어지지 않고 한 곳에 있다
    62	
    63	### Negative
    64	- 회수는 당분간 **품질 보장 없이** 돈다
    65	- `사전 결정 회수:` 줄을 보고 회수가 검증된다고 오해할 여지가 남는다 — 그래서 그 줄을 내는 모든 자리(프로필 9절 · 오케스트레이터 스킬 · ADR-0009)에 "표명이지 강제가 아니다"를 함께 적었다
    66	
    67	## 관련
    68	- [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md) — 층 경계(넘지 말아야 할 선)
    69	- [ADR-0008](2026-08-06-knowledge-gate-default-on.md) — 반영(쓰기) 쪽 게이트
    70	- [ADR-0009](2026-08-06-profile-canon-upstream.md) — 이 ADR이 가리키는 배관
     1	# ADR-0009: 프로필 정본은 상위 층에, 배포본은 프로젝트에 — 그리고 조회 방향을 배선한다
     2	
     3	**Date**: 2026-08-06 (구현 2026-08-10)
     4	**Status**: accepted
     5	**Deciders**: 김태윤(요구 확정), Claude(실측·설계)
     6	
     7	---
     8	
     9	## Context
    10	
    11	`project-profile.md` 는 이 하네스에서 **도메인 지식이 사는 단 하나의 파일**이다 — 스택 · 검증 명령 · 아키텍처 불변식 · 경계면 · 운영 모델. 오케스트레이터가 dispatch 마다 해당 절 전문을 프롬프트에 동봉한다. 이 파일이 낡거나 사라지면 파이프라인 전체가 도메인을 잃고, 에이전트들은 아무 근거 없이 그럴듯한 답을 만들기 시작한다.
    12	
    13	**그런데 실측 결과 어디에도 백업되지 않았다.** 배포본은 `<프로젝트>/.claude/harness/` 에 있는데 그 디렉터리는 `.git/info/exclude` 로 무시돼 이력이 0이고, `~/.claude/` 도 git 저장소가 아니다. 단일 장애점이 이력 없이 놓여 있었다.
    14	
    15	그리고 두 번째 문제가 있다. **프로필은 지금까지 쓰기 전용이었다.** 착수 전에 "이 프로젝트에서 전에 뭘 정했나"를 회수하는 단계가 없다. 그래서 같은 결정을 매번 다시 내리고, 그 재결정이 또 저장된다. 지식은 쌓이는데 아무도 읽지 않는 상태다.
    16	
    17	## Decision
    18	
    19	**① 정본은 상위 층(지식 저장소)이 갖고, 프로젝트의 것은 배포본이다.**
    20	
    21	하네스는 배포본이 놓일 **자리만** 제공한다 — `install.sh` 가 슬롯으로 스캐폴드하고 `sync.sh` 는 절대 덮지 않는다. 정본을 어디에 어떤 이름으로 두는지는 **하네스의 관심사가 아니다.** [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md)의 층 계약 그대로이고, [ADR-0002](2026-07-20-global-agents-layer.md)가 전역 에이전트에 대해 같은 패턴을 이미 풀었다.
    22	
    23	**② 조회 방향을 배선한다 — 프로필 9절 "지식 진입점".**
    24	
    25	값은 **경로 하나**다. 하네스는 그 너머의 구조를 모른다 — 분류·형식·무엇을 어느 파일에 나눠 담는지는 그쪽 규약이 정한다. 그 값만 `ecc:architect`·`ecc:planner` 에 주입한다.
    26	
    27	두 에이전트는 착수 **전**에 그 경로를 읽고, 산출물 **첫 줄**에 `사전 결정 회수: <읽은 경로>` 를 낸다. 읽을 것이 없었으면 `사전 결정 회수: 없음(<사유>)`.
    28	
    29	**③ 그 줄은 강제가 아니라 표명이다 — 그렇게 적는다.**
    30	
    31	존재·형식만 검증된다. 진짜 읽었는지는 기계가 못 본다. 그럼에도 두는 이유는, 표명조차 없으면 회수 단계가 있었는지 **사후에도** 알 수 없기 때문이다. 이 한계를 문서·스킬 양쪽에 적어 둔다 — 검증된 것보다 강하게 공시하면 다음 사람이 그걸 믿고 설계한다.
    32	
    33	## Alternatives Considered
    34	
    35	### A. 정본을 프로젝트 `.claude/harness/` 에 두고 그걸 git 에 추적시킨다
    36	- **Pros**: 이동이 없다. 백업 문제만 푼다
    37	- **Cons**: `.claude/` 를 추적하면 세션 상태 파일·플래그·캐시가 함께 딸려온다. 걸러내는 ignore 규칙을 프로젝트마다 유지해야 하고, 어긋나면 조용히 커밋된다
    38	- **Why not**: 백업은 얻지만 층은 그대로 깨져 있다 — 도메인 지식의 정본이 여전히 하위 층에 산다
    39	
    40	### B. 하네스가 정본 위치를 탐지한다
    41	- **Pros**: 사용자가 설정을 안 해도 된다
    42	- **Cons**: 탐지하려면 상위 층의 경로·구조를 알아야 한다 → **걷어내려는 결합을 다시 도입한다**
    43	- **Why not**: 확인(detect)이 아니라 설정(configure)이어야 층이 유지된다
    44	
    45	### C. 회수를 모든 에이전트에 건다
    46	- **Pros**: 회수 누락이 줄어든다
    47	- **Cons**: `developer`·검수자는 이미 설계서·계획서를 입력으로 받는다. 같은 지식을 층마다 다시 읽으면 토큰만 쓰고 판단은 안 바뀐다
    48	- **Why not**: 지금은 **착수 전 1회**로 좁힌다. 이 좁힘이 옳은지는 [ADR-0010](2026-08-06-knowledge-retrieval-policy.md)의 열린 질문이다
    49	
    50	### D. `사전 결정 회수:` 를 내용까지 검증한다
    51	- **Pros**: 표명이 아니라 강제가 된다
    52	- **Cons**: "읽었는가"를 기계가 확인하려면 하네스가 그 경로의 **내용 구조**를 알아야 한다 → 다시 층 위반
    53	- **Why not**: 층을 지키는 대가로 표명에 머문다. 그 사실을 숨기지 않는 것이 대안이다
    54	
    55	## Consequences
    56	
    57	### Positive
    58	- 도메인 지식의 정본이 이력 있는 곳에 산다
    59	- 지식이 처음으로 **읽히는** 방향을 얻는다
    60	- 하네스가 아는 것은 여전히 경로 하나뿐 — 층 계약이 유지된다
    61	
    62	### Negative
    63	- **기존 설치본에서는 조회 축이 수동이다.** 프로필 9절 슬롯은 사용자 산문이라 `sync.sh` 가 자동으로 넣지 않는다(슬롯은 절대 안 덮는다는 계약이 더 무겁다). 신규 설치는 `install.sh` 가 스캐폴드한다
    64	- 진입점이 비어 있으면 회수 단계는 조용히 생략된다 — 그 경우 `사전 결정 회수: 없음(<사유>)` 만 남는다
    65	- **회수의 품질은 전적으로 그 진입점 너머의 라우팅에 달렸다.** 하네스는 아무 보장도 하지 않는다
    66	
    67	### 절 번호가 바뀐다
    68	새 9절이 들어가면서 기존 "참고 — 전역 의존" 이 10절이 됐다. 절 번호는 오케스트레이터 dispatch 표가 참조하는 **계약**이라 함께 고쳤다.
    69	
    70	## 관련
    71	- [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md) — 층 경계
    72	- [ADR-0008](2026-08-06-knowledge-gate-default-on.md) — 게이트 판독
    73	- [ADR-0010](2026-08-06-knowledge-retrieval-policy.md) — 배관은 깔렸고 정책은 아직 없다
     1	# 사용법 — 하네스 템플릿
     2	
     3	## 0. 전제 (전역 1회 설치, 템플릿은 참조만)
     4	
     5	| 의존 | 위치 | 없으면 |
     6	|---|---|---|
     7	| ECC 룰 | `~/.claude/rules/ecc/` | 코딩/테스트 표준 미적용 (하네스는 동작) |
     8	| **ECC 에이전트** (planner·architect·code-reviewer·security-reviewer·pr-test-analyzer) | ECC 플러그인(`ecc:` 접두) 또는 `~/.claude/agents/` 전역 설치본 | 설계·계획·검수·보안검수 4역할 dispatch 실패 → 오케스트레이터가 직접 대체 수행하며 "ECC 미설치" 명시 |
     9	| superpowers 플러그인 | 플러그인 매니저 | 에이전트의 방법론 스킬 호출 실패 → 해당 단계 품질 저하 |
    10	| claude-mem 플러그인 | 플러그인 매니저 | 착수 전 과거 기억 검색(recall) 생략됨 |
    11	| find-skills 스킬 | `~/.claude/skills/find-skills` (`npx skills add vercel-labs/skills --skill find-skills`) | 진화 시 "만들기 전에 생태계 검색" 생략 → 바로 자체 제작으로 감 |
    12	| codex CLI (선택) | `npm i -g @openai/codex` + `codex login`(사용자 직접) + `claude mcp add --scope user codex -- codex mcp-server` | 모든 검증 게이트(계획검증·검수·PR점검)의 듀얼 리뷰(cc/cx) 생략 — Claude 단독으로 진행하되 보고에 "듀얼 리뷰 생략" 명시 |
    13	| `gh` CLI | PATH | PR 단계(Phase 4) 불가 |
    14	
    15	## 1. 설치 (프로젝트당 1회)
    16	
    17	```bash
    18	cd ~/.claude/harness-template
    19	./install.sh /path/to/project [프로젝트이름]
    20	```
    21	
    22	install이 하는 일: 글루 복사(자체 에이전트 8·스킬 2(harness-orchestrator·readable-writing)·훅 4·제0원칙) + 슬롯 스캐폴드(없을 때만) + settings.json 병합(기존 훅 보존·명령 단위 추가·백업) + CLAUDE.md 포인터 append.
    23	
    24	설계·계획·검수·보안검수 4역할은 자체 에이전트가 아니라 **ECC 참조**(`ecc:architect`·`ecc:planner`·`ecc:code-reviewer`·`ecc:security-reviewer`)다 — 하네스 계약(판정 형식·태그·프로필 준수)은 오케스트레이터의 dispatch 계약이 프롬프트로 주입한다. 이 중 2종은 **조건부**로만 돈다: `ecc:architect`(구조적 변경 — 새 모듈/레이어·경계/데이터모델 변경·3개+ 모듈 영향 — 일 때 Phase 2 전단, plan-reviewer가 설계·계획 2-pass 검증), `ecc:security-reviewer`(보안 민감 변경 — 인증/입력/DB/파일시스템/외부API/암호화/결제/시크릿 — 일 때 Phase 3에서 검수와 병렬, CRITICAL=병합 차단). 추가로 테스트가 핵심 방어선인 변경에는 ECC의 `pr-test-analyzer`를 참조 dispatch(`[tq]` 태그) — 템플릿 소유 에이전트가 아니라 전역 ECC 재사용.
    25	
    26	**설치 후 반드시 2개 슬롯 채우기:**
    27	1. `.claude/harness/project-profile.md` — §1~§8 (도메인 전부: 스택·검증 명령·불변식·경계면·운영·vcs·예시). 작성 예시는 이 repo의 `examples/chat-system.profile.md`.
    28	2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략) · `HARNESS_KNOWLEDGE_GATE` (지식 저장소 반영 게이트. **기본 켜짐**이고, 끄는 방법은 **값을 비우는 것 하나뿐**이다 — `"off"`라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다).
    29	
    30	**`harness.env` 는 실행되지 않는다.** 확장자와 문법은 셸이지만 훅은 이 파일을 source 하지 않고 줄을 읽어 값만 뽑는다 — 1비트를 얻으려고 사용자 소유 셸 파일에 훅의 제어 흐름을 넘길 이유가 없기 때문이다(`exit 0` 한 줄로 완료 게이트 4종이 흔적 없이 사라진 실측이 있다). 대신 지원 문법이 좁다: **한 키는 정확히 한 번만**, 선언은 줄 **맨 앞**에서 시작, 값에 공백이 있으면 따옴표, 후행 주석은 따옴표 뒤에만. 어기면 그 키는 **미설정**으로 떨어지고 해당 검사가 생략된다(생략 사유는 완료 게이트 메시지에 적힌다). 전체 규칙은 `harness.env` 파일 첫머리에 있다.
    31	
    32	**주의: 훅은 세션 시작 시 스냅샷된다** → 설치한 세션에는 발화하지 않고 **다음 세션부터** 적용.
    33	
    34	## 2. 무엇이 재사용이고 무엇이 슬롯인가
    35	
    36	| 층 | 파일 | 갱신 주체 |
    37	|---|---|---|
    38	| **글루 (재사용)** | `agents/*.md` · `skills/*/`(harness-orchestrator·readable-writing) · `hooks/*.sh` · `harness/principles.md` | `sync.sh` (템플릿 개선 시) |
    39	| **슬롯 (프로젝트 소유)** | `harness/project-profile.md` · `harness/harness.env` | 사용자 — sync가 절대 안 덮음 |
    40	| **참조 (전역)** | ECC 룰 · superpowers 스킬 · claude-mem | 각 시스템 업데이트 시 자동 최신 |
    41	
    42	## 3. 일상 사용
    43	
    44	- **개발 요청** ("~만들어줘/고쳐줘/추가해줘") → `harness-orchestrator` 스킬이 자동 트리거되어 파이프라인 실행: 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사. 머지는 항상 사용자 승인 후.
    45	- **부분 재실행** — "검수만 다시", "PR만 다시" → 해당 단계만 돈다.
    46	- **설계 질문** ("왜 이렇게 짰어") → `architecture-guide` 에이전트 직접 호출 (파이프라인 밖).
    47	- **변경 질문** ("이번에 뭐 바뀌었어") → `change-explainer` 직접 호출.
    48	
    49	## 4. 템플릿 갱신 (sync)
    50	
    51	```bash
    52	cd ~/.claude/harness-template
    53	./sync.sh /path/to/project            # git pull + diff 미리보기 + 글루만 갱신
    54	./sync.sh /path/to/project --no-pull  # 로컬 정본만으로
    55	```
    56	
    57	이미 설치된 프로젝트는 sync 전까지 설치 시점 스냅샷 유지(조용한 기본값). 새 설치는 항상 그 시점 최신 글루.
    58	
    59	## 5. 강제 훅 게이트 (이 하네스의 무기)
    60	
    61	| 훅 | 시점 | 강제 내용 |
    62	|---|---|---|
    63	| guard-master-commit | Bash 실행 전 | master/main 직접 `git commit` 차단 |
    64	| guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
    65	| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (설계·계획 산출물은 듀얼리뷰 플래그만, 코드는 4종 전부). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
    66	| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → codex 듀얼리뷰 → change-explainer → **지식 저장소 반영** → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
    67	
    68	**지식 저장소 게이트가 아는 것은 계약 하나뿐이다** — "지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다." **어디에 어떤 구조로 반영하는지는 하네스가 모른다.** 그건 사용자 층 설정(전역 `CLAUDE.md` 등)이 답하고, 하네스에는 켜짐/꺼짐 1비트만 있다. 그래서 지식 저장소를 바꿔도 하네스는 고치지 않고, 아예 안 쓰는 프로젝트에서도 그대로 돈다.
    69	
    70	**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
    71	
    72	### 완료 게이트 검사 범위 (mark-needs-audit)
    73	
    74	판정 **순서가 곧 계약**이다: 개행 가드 → 물리 경로 정규화 → 듀얼리뷰 판정 → 범위 판정 → 분류 → 기록.
    75	
    76	- **프로젝트 안** — `_workspace/`·`.claude/`·문서 `*.md`·`*.markdown`(대소문자 무관)는 제외. 나머지는 게이트 4종.
    77	  단 **문서 제외에는 예외가 둘** 있다(동작을 정의하는 마크다운이라 코드로 취급한다):
    78	  `.claude/` 에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`), 그리고
    79	  **프로젝트 자신이 하네스 정본일 때의 `global-agents/*.md`**. 둘 다 `*.md` 제외보다 **먼저** 판정된다.
    80	- **프로젝트 밖 + 하네스 정본 저장소**(루트에 `template/.claude/` 존재) — 저장소 **전체**를 **프로젝트와 같은 규칙으로** 검사한다. `scripts/`·`install.sh`·`global-agents/*.md` 포함(전부 하네스 동작을 정의한다). "같은 규칙"이므로 위의 제외도 **그대로** 적용된다 — 정본 저장소 안이라도 `_workspace/`·`.claude/`·순수 문서는 게이트가 서지 않는다. 지금 읽고 있는 이 파일(`docs/usage.md`)이 그 예다.
    81	- **프로젝트 밖 + 그 외** — `.claude/`에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`)만. **git 저장소가 아니어도** 발화한다.
    82	- **설계·계획 산출물**(`_workspace/00_design*.md`·`01_plan*.md`) — 위치·git 여부와 무관하게 듀얼리뷰 플래그만 세운다.
    83	- **밖 편집은 절대경로로 기록**한다. 상대경로로 적으면 프로젝트와 외부 저장소가 `README.md` 같은 흔한 경로를 공유할 때 감사자가 프로젝트 쪽 동명 파일을 보고 통과시킨다.
    84	- 플래그를 못 쓰거나 경로에 개행이 있으면 **차단하지 않고** `systemMessage`로 알린다(PostToolUse는 항상 exit 0). git 호출이 실패했는데 조상에 `.git`이 있으면 그 사실도 알린다 — 정본 저장소가 조용히 앵커 전용으로 강등되는 것을 사람이 알 수 있게.
    85	
    86	계약의 **기계 정본**은 `tests/mark-needs-audit.cases.sh`의 판정 표이고, 케이스 수는 같은 파일의 `EXPECTED_CASES`가 강제한다. CI가 PR마다 돌린다.
    87	
    88	## 6. 트러블슈팅
    89	
    90	- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 지식 저장소 반영(`.needs-knowledge`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
    91	- **타입체크가 이상하게 실패** → `harness.env`의 명령을 셸에서 직접 실행해 확인. 도구 부재(rc=127)·타임아웃은 차단 안 하고 생략 처리된다.
    92	- **superpowers 스킬 호출 실패** → 플러그인 설치/이름 확인: `test-driven-development`·`writing-plans`·`brainstorming`·`requesting-code-review`·`verification-before-completion`·`systematic-debugging`.
    93	- **에이전트가 도메인을 무시** → 프로필 §가 비어 있지 않은지 확인. 오케스트레이터는 빈 §를 "검증 생략"으로 정직 보고한다.
    94	
    95	## 7. 하네스 진화
    96	
    97	에이전트/스킬 수정·추가는 이 repo(정본)에서 하고 커밋 → 각 프로젝트에 `sync.sh`. 구조 변경이 크면 `harness` 메타 스킬(운영/유지보수 워크플로우)을 사용. 변경 이력은 각 프로젝트 CLAUDE.md의 변경 이력 표에 기록.
    98	
    99	### 제0원칙 판정 기준을 고칠 때
   100	
   101	판정 기준(`principles.md`의 `rule:core` 블록)은 판정자 에이전트가 **자기 정의 안에 사본으로** 들고 있다. 참조만 두면 에이전트가 그 파일을 읽는다는 보장이 없어서다. 그래서 고치는 순서가 정해져 있다.
   102	
   103	1. 정본 `template/.claude/harness/principles.md`의 `rule:core` 블록을 고친다.
   104	2. 사본(`template/.claude/agents/plan-reviewer.md` 점검 항목 7)에 **그대로 복사**한다.
   105	3. 검사한다.
   106	
   107	```bash
   108	./scripts/check-rule-copies.sh
   109	```
   110	
   111	어긋나면 종료 코드 1과 함께 diff가 나오고, CI(`.github/workflows/check-rules.yml`)가 PR을 막는다. 마커 **밖**의 문맥별 설명은 동기화 대상이 아니니 파일마다 자유롭게 써도 된다 — 판정 기준만 동기화한다. 다만 마커 줄 자체는 앞뒤 공백·설명 없이 정확히 한 줄(`<!-- rule:core:start -->` / `<!-- rule:core:end -->`, CRLF 줄끝 불가)이어야 한다. 꾸미면 마커로 인정되지 않는다 — 마커를 꾸며 판정 기준을 바꿔치기하는 길을 막기 위해서다. 같은 이유로 `template/` 아래에는 심링크와 NUL 바이트를 포함한 파일(바이너리·UTF-16 등)을 둘 수 없다 — 검사기가 내용을 확인할 수 없어 낡은 사본이 조용히 배포되는 경로가 열리기 때문이다.
   112	
   113	판정자를 새로 추가해 사본이 늘면 `scripts/check-rule-copies.sh`의 `COPIES` 배열에 경로 한 줄을 추가해야 한다 — `template/` 안에 마커를 둔 채 등록하지 않으면 검사기가 종료 코드 1로 막는다. 그 경로는 반드시 `template/` **아래**여야 한다: 심링크·NUL·미등록 게이트가 전부 `template/`만 훑기 때문에, 밖을 가리키면 등록만 되고 정작 검사는 안 되는 사본이 생긴다(검사기가 이것도 종료 코드 1로 막는다). `..`나 심링크를 거쳐 밖으로 나가는 표기도 물리 경로로 풀어 같이 막는다. 경로에 개행이 들어간 파일은 아예 등록할 수 없다 — 개행은 경로 계산 과정에서 잘려 나가 바깥 파일을 안쪽으로 오인시키므로, 범위 판정 자체가 성립하지 않는다. 반대로 `COPIES`를 통째로 비워 둘 수도 없다 — 대조할 사본이 0개면 검사기가 지키는 것이 아무것도 없는데도 초록으로 보이므로, 빈 배열도 종료 코드 1로 막는다.

2026-08-10T03:51:03.881578Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "nl -ba template/.claude/harness/harness.env.template | sed -n '1,260p'
nl -ba template/.claude/harness/project-profile.template.md | sed -n '1,300p'
nl -ba template/.claude/skills/harness-orchestrator/SKILL.md | sed -n '1,360p'
nl -ba template/CLAUDE.md.snippet | sed -n '1,180p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
     1	# harness.env — 하네스 훅이 **실행하지 않고 원문으로 읽는** 기계 판독 설정.
     2	# install.sh 가 이 템플릿을 프로젝트의 .claude/harness/harness.env 로 복사하고,
     3	# 프로필 3절(검증 명령)에서 값을 채운다. 사람이 직접 채워도 된다.
     4	#
     5	# ── 이 파일은 실행되지 않는다 ─────────────────────────────────────────
     6	# 확장자와 문법은 셸이지만 훅은 이 파일을 source 하지 않는다. 값을 얻으려고 실행하면
     7	# 파일 내용이 훅의 제어 흐름을 가져가고, 막을 때마다 새 탈출 경로가 나온다(`exit 0`
     8	# 한 줄로 완료 게이트 전체가 흔적 없이 사라진 실측이 있다). 그래서 훅은 **줄을 읽어
     9	# 값만 뽑는다.** 대신 셸이 해주던 파싱이 없으므로 아래 문법을 지켜야 한다.
    10	#
    11	# ── 지켜야 할 것 ──────────────────────────────────────────────────────
    12	#   · 한 키는 **정확히 한 번만** 선언한다. 두 번 있으면 어느 게 이기는지 원문으로
    13	#     알 수 없어 훅이 "미설정"으로 처리한다(= 그 검사가 생략된다).
    14	#   · 선언 줄은 **행 맨 앞**에서 시작한다. 앞에 공백·탭이 있으면 선언으로 세지 않는다
    15	#     (`if` 문이나 함수 안의 대입은 실행돼야 발효하는데 이 파일은 실행되지 않는다).
    16	#   · 값에 공백이 있으면 따옴표로 감싼다.  `KEY="pnpm tsc --noEmit"`
    17	#   · 후행 주석은 **따옴표 뒤에만** 안전하게 붙는다.  `KEY="pnpm tsc" # 메모`
    18	#     인용하지 않은 값에서는 **공백 다음의 `#`** 부터가 주석이다(`a#b` 의 `#` 은 값).
    19	#
    20	# ── 지원하지 않는 것 (쓰면 그 키는 "미설정"이 된다) ────────────────────
    21	#   · 백슬래시 이스케이프(`"a \" b"`) · 여러 줄로 이어 쓰기 · 닫히지 않은 따옴표
    22	#   · 한 줄에 인용 조각 여러 개(`"a"b`)
    23	#
    24	# ── 눈에 안 보이는 함정 ───────────────────────────────────────────────
    25	#   · **줄끝은 LF 로 저장한다.** Windows 편집기의 CRLF 는 예전에 값 뒤에 `\r` 을
    26	#     남겨 검사를 통째로 생략시켰다. 지금은 훅이 걷어내지만 안 넣는 편이 낫다.
    27	#   · **파일 앞 BOM 을 넣지 않는다.** 마찬가지로 훅이 걷어내지만 원인 파악이 어렵다.
    28	#   · 값 안의 `$VAR` 는 이 파일을 읽을 때가 아니라 **명령을 실행할 때** 확장된다.
    29	#     `KEY='printf $HOME'` 은 실행 시점의 홈 경로를 찍는다.
    30	#
    31	# 값을 바꾼 뒤에는 셸에서 그 명령을 직접 한 번 돌려보라. 이 파일이 잘못돼도 훅은
    32	# 조용히 생략할 뿐 에러를 내지 않는다 — 생략 사유는 완료 게이트 메시지에 적힌다.
    33	
    34	# 타입체크 명령 (Stop 훅이 완료 게이트에서 실행). 예:
    35	#   HARNESS_TYPECHECK_CMD="pnpm typecheck"
    36	#   HARNESS_TYPECHECK_CMD="pnpm tsc --noEmit"
    37	#   HARNESS_TYPECHECK_CMD="npm run typecheck"
    38	#   HARNESS_TYPECHECK_CMD="cargo check"
    39	#   HARNESS_TYPECHECK_CMD="go build ./..."
    40	#   HARNESS_TYPECHECK_CMD="mypy ."
    41	# 비우면 타입체크를 생략한다(타입 없는 언어나 타입체크가 없는 프로젝트).
    42	HARNESS_TYPECHECK_CMD=""
    43	
    44	# 지식 반영 게이트. 결정·설계가 나온 턴을 "지식 저장소에 반영했는가" 확인 없이는
    45	# 끝내지 못하게 한다.
    46	#
    47	# **하네스는 그 저장소가 어디인지 모른다.** 여기 있는 것은 켜짐/꺼짐 1비트뿐이고,
    48	# 어디에 어떤 구조로 반영하는지는 사용자 층 설정(전역 CLAUDE.md 등)이 답한다.
    49	# 저장소를 바꿔도 하네스는 고치지 않는다.
    50	#
    51	# **끄려면 값을 비운다 — 그 방법 하나뿐이다.**
    52	#   HARNESS_KNOWLEDGE_GATE=""      → 꺼짐
    53	#   HARNESS_KNOWLEDGE_GATE="on"    → 켜짐
    54	#   HARNESS_KNOWLEDGE_GATE="off"   → **켜짐** (비어 있지 않으므로. 흔한 착각이다)
    55	#
    56	# 이 줄이 아예 없어도 **켜짐**이다. 기존 설치본에는 이 키가 없는데, 없을 때 꺼짐으로
    57	# 읽으면 하네스를 갱신하는 순간 게이트가 조용히 꺼진다 — 사용자는 지식이 쌓인다고
    58	# 믿는데 그 턴부터 아무것도 안 남는다. 표명이 없으면 이전 동작을 보존한다.
    59	HARNESS_KNOWLEDGE_GATE="on"
     1	# 프로젝트 프로필 — {{PROJECT_NAME}}
     2	
     3	> **이 파일은 하네스의 유일한 도메인 슬롯이다.**
     4	> 제네릭 에이전트·오케스트레이터는 도메인 지식을 자기 안에 담지 않는다. 대신 런타임에
     5	> 이 파일을 읽어 "이 프로젝트가 무엇이고, 무엇을 지켜야 하며, 어떻게 검증하는가"를 배운다.
     6	> 새 프로젝트 온보딩 = **이 파일만 채우기.** 에이전트 정의는 손대지 않는다.
     7	>
     8	> 작성 규칙:
     9	> - 각 섹션 머리의 `[읽는 이]`는 이 섹션을 참조하는 에이전트다. 비우면 그 에이전트는 "해당 없음"으로 처리한다.
    10	> - 모르는 항목은 지우지 말고 `(해당 없음)` 또는 `(미정)`으로 둔다 — 빈칸과 "없음"은 다르다.
    11	> - 사실만 적는다. 코드에서 확인되지 않는 희망사항을 불변식에 넣지 않는다.
    12	> - 이 파일은 **하중지지 사실**(항상 로드)이다. 세션 서사·탐색 히스토리는 여기가 아니라 claude-mem으로 간다.
    13	
    14	---
    15	
    16	## 1. 정체성 (identity)
    17	`[읽는 이: 전 에이전트 · 오케스트레이터 제목 · developer/orchestrator description]`
    18	
    19	- **한 줄 정의:** {{한 문장으로 이 시스템이 무엇인지}}
    20	- **도메인:** {{예: 실시간 채팅 수집·분석 / 이커머스 / 사내 대시보드}}
    21	- **주 사용자 & 기술 숙련도:** {{예: 본인(코딩 경험 적음) — 전문용어 풀어 설명 / 개발팀}}
    22	- **1차 언어(사용자 대면 보고):** {{예: 한국어 — change-explainer·clarifier가 이 언어로 보고}}
    23	
    24	---
    25	
    26	## 2. 기술 스택 (stack)
    27	`[읽는 이: developer · planner · reviewer · plan-reviewer]`
    28	
    29	- **언어:** {{예: TypeScript}}
    30	- **프레임워크/런타임:** {{예: Fastify · socket.io · React 19 · Vite · Node}}
    31	- **패키지 매니저:** {{예: pnpm}}
    32	- **핵심 디렉토리 맵** — 어디에 무엇이 있나(계획·검수 시 영향 범위 판단 기준):
    33	  - {{예: `src/server/` — 수집·집계 서버}}
    34	  - {{예: `src/client/` — React 대시보드}}
    35	  - {{예: `src/shared/` — 서버·클라 공유 타입}}
    36	  - {{예: `tests/` — Vitest}}
    37	
    38	---
    39	
    40	## 3. 검증 명령 (verify)
    41	`[읽는 이: developer · ecc:code-reviewer · completion-auditor · pr-author · verify-before-stop 훅]`
    42	
    43	> **타입체크 명령의 기계 정본은 `.claude/harness/harness.env`의 `HARNESS_TYPECHECK_CMD`다** — Stop 훅은 그 파일만 읽는다.
    44	> 여기 §3에 명령을 다시 적지 마라(이중 기입 = 드리프트). 나머지 항목(테스트·빌드·린트·관찰)은 이 섹션이 정본.
    45	
    46	- **타입체크:** `.claude/harness/harness.env` 참조 (여기 다시 적지 않는다)
    47	- **테스트:** {{예: `pnpm test`  (프레임워크: Vitest)}}
    48	- **빌드:** {{예: `pnpm build`}}
    49	- **린트/포맷(선택):** {{예: `pnpm lint` / `pnpm format`}}
    50	- **브라우저·런타임 관찰 필요?** {{예: 예 — 대시보드 변경은 preview 도구로 실제 렌더 확인까지}}
    51	
    52	---
    53	
    54	## 4. 아키텍처 불변식 (invariants)
    55	`[읽는 이: planner · plan-reviewer · developer · reviewer · architecture-guide]`
    56	
    57	> 이 프로젝트에서 **어기면 버그**인 규칙들. 형식: `규칙 — 왜(안 지키면 뭐가 터지나)`.
    58	> 여기 적힌 것이 ecc:code-reviewer의 "실패 시나리오" 사고와 architecture-guide 설명의 근거가 된다.
    59	> 프로젝트 고유 규칙만. 언어 일반 관용구(불변성·작은 함수 등)는 ECC 룰이 이미 커버하므로 중복 금지.
    60	
    61	- {{규칙}} — {{왜}}
    62	- {{규칙}} — {{왜}}
    63	- _(예시) 실시간 경로 vs 내구성 경로 분리 — 인메모리는 동기 즉시 갱신, 디스크 쓰기는 백그라운드 큐. 실시간 경로에 `await 파일쓰기`를 넣으면 폭주 시 화면이 멈춘다._
    64	- _(예시) 증분 집계 — 매 주기 전체 재계산 금지. 데이터가 쌓일수록 느려지는 시한폭탄._
    65	
    66	---
    67	
    68	## 5. 경계면 맵 (boundaries)
    69	`[읽는 이: planner · plan-reviewer · reviewer]`
    70	
    71	> 데이터 shape이 계층을 넘나드는 지점. 이 프로젝트 버그의 대부분이 여기서 난다.
    72	> ecc:code-reviewer의 핵심은 "존재 확인"이 아니라 **이 경계 양쪽을 동시에 열어 shape을 교차 비교**하는 것.
    73	> 형식: `경계: A ↔ B — 공유 계약/타입 위치`.
    74	
    75	- {{경계: A ↔ B}} — 공유 계약: {{위치}}
    76	- _(예시) 서버 API 응답 ↔ socket.io payload ↔ React 훅 — 공유 타입: `src/shared/types.ts`_
    77	
    78	---
    79	
    80	## 6. 배포·운영 모델 (ops)
    81	`[읽는 이: completion-auditor · change-explainer]`
    82	
    83	> **"머지 = 사용자 화면 반영"이 아닐 수 있는 지점.** completion-auditor가 "운영 반영까지" 감사하려면 필요.
    84	> 이 섹션이 비면 감사자는 코드 완료(머지·테스트)까지만 검증하고 운영 반영은 확인하지 않는다.
    85	
    86	- **운영 서버 실행:** {{예: `node dist-server/index.js`, 포트 4010}}
    87	- **서빙 대상(무엇을 서빙하나):** {{예: `dist/`·`dist-server/` 빌드본 — 소스가 아니라 빌드 산출물}}
    88	- **소스→운영 반영 절차:** {{예: `pnpm build` + 서버 재시작}}
    89	- **"반영됨" 확인법:** {{예: `ls -lt dist/assets/` 빌드 시각이 머지 시각보다 최신인지}}
    90	
    91	---
    92	
    93	## 7. 버전관리 정책 (vcs)
    94	`[읽는 이: pr-author · pr-reviewer]`
    95	
    96	> 아래는 하네스 **기본값**. 프로젝트가 다르면 해당 줄만 덮어쓴다.
    97	
    98	- **기본 브랜치:** {{master | main}}
    99	- **브랜치 전략:** 기능마다 기본 브랜치에서 새 브랜치 → PR → **squash merge**. 스택 PR 금지(앞 PR 머지 시 base 삭제로 뒤 PR이 닫히는 사고).
   100	- **한 PR = 한 논리적 변경** — squash 후 커밋 하나 `revert`로 롤백.
   101	- **커밋/PR 제목:** Conventional Commits (`feat:`·`fix:`·`refactor:`·`docs:`·`test:`·`chore:`·`perf:`).
   102	- **머지 주체:** 사용자 승인 후에만.
   103	- **프로젝트 예외:** {{없으면 "없음"}}
   104	
   105	---
   106	
   107	## 8. 도메인 예시 (examples)
   108	`[읽는 이: clarifier · 오케스트레이터 테스트 시나리오]`
   109	
   110	> clarifier가 "무엇이 모호한지" 감을 잡게 하는 **실제 요청 예시** 1~2개.
   111	> 이상적으로: 표면상 명확해 보이지만 실은 결정이 숨어 있는 요청.
   112	
   113	- _(예시) "이미지도 되게 해줘" → 어느 provider? 호버/클릭 둘 다? 저장까지? — 범위가 숨어 있음._
   114	- {{이 프로젝트의 대표적 "애매한 요청" 예시}}
   115	
   116	---
   117	
   118	## 9. 지식 진입점 (knowledge entry)
   119	`[읽는 이: ecc:architect · ecc:planner — 착수 **전**에 이 경로를 읽는다]`
   120	
   121	> 이 프로젝트에 관해 **전에 무엇을 정했는지** 를 찾아 들어가는 단 하나의 경로.
   122	> 하네스는 그 너머의 구조를 모른다 — 경로 하나만 알고, 분류·형식은 그쪽 규약이 정한다.
   123	>
   124	> **왜 필요한가:** 지금까지 지식은 쓰기 전용이었다. 착수 전에 회수하는 단계가 없어
   125	> 같은 결정을 매번 다시 내리고, 그 재결정이 또 저장됐다. 이 슬롯이 반대 방향을 연다.
   126	
   127	- **진입점:** {{지식 저장소에서 이 프로젝트로 들어가는 경로 — 인덱스·목차 파일 하나}}
   128	- 비워두면 회수 단계를 생략한다(회수할 지식이 아직 없는 새 프로젝트).
   129	
   130	`ecc:architect`·`ecc:planner` 는 착수 전 이 경로를 읽고, 산출물 **첫 줄**에
   131	`사전 결정 회수: <읽은 경로>` 를 낸다. 읽을 것이 없었으면 `사전 결정 회수: 없음(<사유>)`.
   132	
   133	**이 줄은 존재·형식만 검증된다.** 진짜 읽었는지는 기계가 못 본다 — 강제가 아니라 표명이다.
   134	그 한계를 알고도 두는 이유는, 표명조차 없으면 회수 단계가 있었는지 **사후에도** 알 수 없기
   135	때문이다.
   136	
   137	---
   138	
   139	## 10. 참고 — 전역 의존 (이 프로젝트가 기대는 참조 시스템)
   140	`[정보용: 사람이 읽는 메모. 에이전트는 각자 필요한 참조를 직접 호출]`
   141	
   142	- **ECC 룰:** `~/.claude/rules/ecc/` — 언어 일반 코딩/테스트/보안 표준(항상 로드).
   143	- **superpowers 스킬(참조, 복사 아님):** developer→`test-driven-development`·`receiving-code-review`, completion-auditor→`verification-before-completion`, clarifier→`brainstorming`, 디버깅→`systematic-debugging`. (계획·검수는 ECC 참조 에이전트 — `writing-plans`·`requesting-code-review`의 요지는 오케스트레이터 dispatch 계약이 대신 강제.)
   144	- **claude-mem:** 세션 히스토리 자동 캡처 + 검색. ecc:planner·clarifier가 착수 전 "전에 이거 풀었나" 검색.
   145	- **파일 메모리:** 하중지지 사실(핵심 규칙·확정 결정·로드맵)은 `~/.claude/projects/<proj>/memory/`(항상 로드). 이 프로필도 하중지지 사실이다.
     1	---
     2	name: harness-orchestrator
     3	description: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. "개발해줘", "기능 추가", "고쳐줘", "만들어줘", "구현해줘", "계획 세워줘", "검수해줘", "점검해줘", "PR 올려줘/만들어줘", "다시 해줘", "재실행", "보완", "수정해줘", "이전 결과 기반으로" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).
     4	---
     5	
     6	# 하네스 오케스트레이터 (도메인-무관)
     7	
     8	전문 에이전트들을 파이프라인 + 3중 생성-검증 루프(계획·개발·PR)로 조율해, 사용자의 개발 요청을 계획부터 PR·설명·완료감사까지 완결한다. 도메인 지식은 이 스킬에 없다 — 전부 `.claude/harness/project-profile.md`(프로필)에서 온다.
     9	
    10	**실행 모드: 에이전트 팀.** 개발↔검수, PR작성↔PR점검 사이의 피드백 루프가 있어 팀 통신이 유리하다. 모든 Agent 호출에 `model: "opus"`를 명시한다.
    11	
    12	**스킬 통제권:** 전역 using-superpowers의 "응답 전 스킬 먼저" 선점은 이 하네스에서 비활성(CLAUDE.md 지시). 어떤 superpowers 스킬을 언제 쓰는지는 각 에이전트 정의와 이 오케스트레이터가 결정한다.
    13	
    14	## Phase 0: 컨텍스트 확인 + 도메인 로드
    15	
    16	1. **실행 모드 판별 + RAM 재개:**
    17	   - `_workspace/progress.md`가 있으면 **가장 먼저 읽는다** — 진행 중 작업의 현재 상태(완료 단계·다음 단계·미해결 결정). 세션이 바뀌었어도 여기서 이어받는다. 없고 새 작업이면 생성한다.
    18	   - `_workspace/` 존재 + 부분 수정 요청("검수만 다시", "PR만") → **부분 재실행** (해당 에이전트만, 아래 해당 Phase로 점프)
    19	   - `_workspace/` 존재 + 새 입력 → **새 실행** (기존을 `_workspace_prev/`로 이동)
    20	   - `_workspace/` 미존재 → **초기 실행**
    21	2. **프로필·원칙 로드(오케스트레이터가 직접 1회 Read):** `.claude/harness/project-profile.md` + `.claude/harness/principles.md`. 이후 각 에이전트 dispatch 시 아래 주입 규칙대로 **해당 섹션 전문을 Task 프롬프트에 동봉**한다 — 에이전트가 "읽으러 갈지"를 선택에 맡기지 않는다.
    22	3. **정본 드리프트 확인(초기 실행 시 1회):** 이 스킬·훅이 템플릿 정본(kty-claude-harness-template)과 다르면 — 특히 "듀얼 리뷰 규칙" 절이나 `guard-codex-invocation.sh`가 없으면 — 작업 전에 `sync.sh <프로젝트>`부터 실행한다. 근거: 2026-08-03 POK-30에서 sync 누락으로 구버전 스킬(Phase 3만 codex)을 따라 설계 단계 듀얼 리뷰가 생략된 실사고.
    23	4. **과거 기억 검색(초기 실행 시 1회):** `claude-mem:mem-search` 스킬을 호출해 "전에 이 문제/유사 요청을 풀었나"를 검색(search→timeline→get_observations 3층 워크플로우). 관련 결과가 있으면 clarifier·ecc:planner 프롬프트에 요약 동봉. (claude-mem은 2세션째부터 자동 주입도 하므로, 명시 검색은 착수 시 1회면 충분.) 검색 결과에 하중지지 사실(확정 결정·규칙)이 있으면 파일 메모리로 승격을 제안한다.
    24	
    25	### 프로필 주입 규칙 (에이전트 → 동봉 섹션)
    26	
    27	| 에이전트 | 주입할 프로필 섹션 | 추가 동봉 |
    28	|---|---|---|
    29	| clarifier | §1 정체성 · §8 도메인 예시 | mem-search 결과 |
    30	| ecc:architect (설계) | §2 · §4 · §5 · **9절 지식 진입점** | principles.md · mem-search 결과 · dispatch 계약(아래) |
    31	| ecc:planner (계획) | §2 스택 · §4 불변식 · §5 경계면 · §7 vcs · **9절 지식 진입점** | principles.md · mem-search 결과 · (구조적이면) 설계서 경로 · dispatch 계약(아래) |
    32	| plan-reviewer | §4 · §5 · §7 | principles.md |
    33	| developer | §2 · §3 검증 · §4 · §5 | principles.md · 계획서 경로 · harness.env(타입체크 정본) |
    34	| ecc:code-reviewer (검수) | §3 · §4 · §5 | principles.md · harness.env · dispatch 계약(아래) |
    35	| ecc:security-reviewer (보안) | §4 · §5 | 변경 파일 목록 · dispatch 계약(아래) |
    36	| pr-author | §3 (테스트 플랜용) · §7 | — |
    37	| pr-reviewer | §5 · §7 | — |
    38	| change-explainer | §1 (언어·톤) · §6 운영 | PR URL |
    39	| completion-auditor | §3 · §6 | 완료 주장 목록 · harness.env |
    40	
    41	### 외부(ECC) 참조 에이전트 dispatch 계약
    42	
    43	설계·계획·검수·보안검수 4역할은 자체 에이전트가 아니라 **ECC 전역 에이전트를 참조 호출**한다(2026-07-20 교체 — 만들기 전에 찾는다, `[tq]`와 같은 레이어 원칙). ECC 정의에는 하네스 계약이 없으므로, dispatch할 때마다 아래 계약을 **Task 프롬프트에 명시**한다. ECC 플러그인이 없는 환경이면 동명 전역 에이전트(`~/.claude/agents/`)로 대체하고, 그것도 없으면 해당 역할을 오케스트레이터가 직접 수행하되 보고에 "ECC 미설치 — 대체 수행"을 명시한다(조용한 성공 위장 금지).
    44	
    45	**공통 계약(4종 모두 프롬프트에 포함):** ① 한국어로 출력 ② 주입된 프로필·principles.md(제0원칙)를 판단 기준으로 사용 ③ 산출물은 응답 본문으로 반환 — `_workspace/` 파일 저장은 오케스트레이터가 수행 ④ 확인 못 한 항목은 지어내지 말고 "미확인"으로 표기.
    46	
    47	| 에이전트 | 역할 | dispatch 시 프롬프트로 요구할 것 |
    48	|---|---|---|
    49	| `ecc:architect` | 설계서 (구조적 변경만) | 출력 **첫 줄**: `사전 결정 회수: <읽은 경로>` (프로필 9절의 진입점을 착수 **전**에 읽는다. 비었거나 읽을 것이 없으면 `사전 결정 회수: 없음(<사유>)`). 이어서 — 출력 형식: 설계 목표 / 모듈 경계(공개 인터페이스 시그니처 수준) / 데이터 흐름 / 패턴 선택과 대안(결정·대안·트레이드오프 필수 — 대안 없는 설계서는 검증 불가) / 기존 구조 영향(파일:라인 근거) / 마이그레이션 순서 힌트. 구조적이지 않다고 판명되면 억지 설계 말고 "planner 직행 권고" 반환 → 오케스트레이터가 `_workspace/00_design.md` 저장 |
    50	| `ecc:planner` | 구현 계획서 | 출력 **첫 줄**: `사전 결정 회수: <읽은 경로>` (프로필 9절의 진입점을 착수 **전**에 읽는다. 비었거나 읽을 것이 없으면 `사전 결정 회수: 없음(<사유>)`). 이어서 — 출력 형식: 목표 / 영향 범위(파일:라인) / 모듈 경계(제0원칙 — '실제로 바뀔 축'만) / 단계(PR 단위, 단계마다 검증 방법·리스크) / 리스크·롤백 / 테스트 계획. 요구가 실은 모호하면 강행 말고 "clarifier 회부 필요" 반환 → 오케스트레이터가 `_workspace/01_plan.md` 저장 |
    51	| `ecc:code-reviewer` | 코드 검수 | ① 판정 줄 필수: `판정: 통과/보류` — CRITICAL 1건이면 보류 ② 지적마다 심각도(CRITICAL/HIGH/MEDIUM/LOW) + "어떤 입력 → 어떤 잘못된 결과" 시나리오 ③ 지적마다 카테고리 태그 `[경계면] [불변식] [제0원칙] [품질] [테스트] [성능] [접근성]`…(진화 신호 축적용) ④ §3 타입체크·테스트 명령을 직접 실행해 확인(보고만 믿지 않기) ⑤ developer 출력의 `방법론: superpowers:test-driven-development 따름` 줄 확인 — 없으면 미준수 지적 ⑥ §5 경계면은 양쪽 코드를 동시에 열어 shape 교차 비교 ⑦ 수정하지 않기 — 관찰·판정만 |
    52	| `ecc:security-reviewer` | 보안 검수 (트리거 시만) | ① 판정 줄 필수: `판정: 통과/차단` — CRITICAL 1건이면 차단 ② **수정 금지** — 발견·판정만(Edit/Write 도구가 있어도 사용하지 않게 명시) ③ 지적마다 "어떤 입력 → 어떤 경로 → 무슨 피해" 시나리오(입력→도달 경로를 실제 코드로 특정) ④ 시크릿이 이미 커밋됐으면 로테이션 필요 명시(히스토리 제거만으론 불안전) ⑤ 확신 없는 항목은 "미확인 — 검증 방법"으로 분류, 통과로 밀지 않기 |
    53	
    54	## 듀얼 리뷰 규칙 — 모든 검증 게이트 공통 (2026-08-01 사용자 확정)
    55	
    56	**모든 리뷰 게이트는 Claude + Codex 듀얼로 돈다** — plan-reviewer의 설계/계획 각 pass(Phase 2), ecc:code-reviewer 검수(Phase 3), pr-reviewer 점검(Phase 4) 전부. Claude 리뷰어 dispatch와 **병렬로** Codex를 호출한다:
    57	
    58	```bash
    59	codex exec --sandbox read-only -m gpt-5.6-sol -c model_reasoning_effort="high" "<리뷰 프롬프트: 대상 파일 경로·판정 기준·출력 형식(판정 줄+심각도+시나리오)>"
    60	```
    61	
    62	- **모델 `gpt-5.6-sol` 하드코딩** (2026-08-01 기준 최신 세대 — CLI에 "최신 자동 추종" 메커니즘이 없음을 확인 후 사용자 지시로 고정). 새 세대 모델 출시 시 이 줄 갱신. **effort `high` 하드코딩**(사용자 지시).
    63	- **임의 하향 절대 금지 (2026-08-01 재확정):** "확인이 작다/비용" 등 어떤 사유로도 오케스트레이터가 모델·effort를 스스로 낮출 수 없다 — 실사고 있음. 낮출 필요가 보이면 실행 전에 사용자 승인. **`.claude/hooks/guard-codex-invocation.sh`(PreToolUse)가 위반 호출을 기계적으로 차단한다** — 훅 우회·삭제는 규율 위반.
    64	- 통합 시 모든 지적에 출처 태그: **`[cc]`**(Claude 리뷰어) / **`[cx]`**(Codex) / **`[cc·cx]`**(둘 다 = 신뢰도 높음, 우선 처리). 심각도 규칙은 출처 무관 동일(CRITICAL/HIGH = 차단, 어느 쪽이 잡았든).
    65	- 판정 충돌 시(한쪽 승인·한쪽 보류): **보류가 이긴다.** 단 보류 사유가 사실 오인이면 오케스트레이터가 근거를 명시하고 기각 가능(기각 사유는 산출물에 기록).
    66	- codex 미설치·미인증·호출 실패면 해당 게이트를 Claude 단독으로 진행하되 보고에 "듀얼 리뷰 생략(codex 실패)"을 명시 — 조용한 성공 위장 금지.
    67	- **기계 강제 (2026-08-03 kty — 산문 규정만으로는 sync 누락 시 무력해진 실사고의 재발 방지):** `_workspace/00_design*.md`·`01_plan*.md` 저장과 모든 코드 편집은 `mark-needs-audit.sh` 훅이 `.claude/.needs-dualreview` 플래그를 세우고, Stop 훅(`stop:dualreview`)이 codex 리뷰 산출물(`_workspace/*codex*.md`) 저장·`[cc]`/`[cx]` 통합 없이는 턴 종료를 차단한다. 리뷰 없이 플래그만 지우는 것은 게이트 무력화다.
    68	
    69	## 사용자 보고 블록 규칙 (2026-08-01 사용자 확정)
    70	
    71	**사용자에게 내는 모든 보고·산출물 안내(Phase 전환 보고, 설계/계획 제시, 검수 결과, PR 안내, 완료 보고)는 맨 위에 이 블록을 붙인다:**
    72	
    73	```
    74	📌 읽어야 할 것 (3줄 이내): <이번 보고에서 사용자가 책임지는 핵심만>
    75	🔀 결정 필요 (N건): <사용자만 답할 수 있는 것. 없으면 "없음">
    76	📦 나머지는 아카이브: <어디에 저장돼 있고, 언제 다시 보면 되는지 한 줄>
    77	```
    78	
    79	- 근거: 이해 부채(comprehension debt) 대응 — 사용자는 전체가 아니라 ①결정 ②검증 증거 ③한계만 읽는다. 상세는 `_workspace/`가 보존하고, 문제가 생겼을 때 역추적한다.
    80	- 본문은 readable-writing 스킬(용어 즉석 괄호 풀이 포함)을 따른다.
    81	
    82	## Phase 1: 명료화 게이트 (clarifier)
    83	
    84	**항상 먼저** `clarifier`로 요청의 모호점·비가역 작업·숨은 가정을 점검한다.
    85	- 판정 "확인 필요" → 정리된 질문을 **AskUserQuestion으로 사용자에게 직접** 묻는다(clarifier는 질문을 만들 뿐, 실제 묻기는 오케스트레이터가). 답을 받고 진행.
    86	- 판정 "명확" → Phase 2로.
    87	
    88	> 이 게이트가 이 하네스의 1번 가치다. "확실하지 않으면 추측 말고 물어본다"를 파이프라인이 강제한다.
    89	
    90	## Phase 2: 설계·계획↔검증 루프 (ecc:architect → ecc:planner ⇄ plan-reviewer)
    91	
    92	**구조적 변경 판별(오케스트레이터):** 새 모듈/레이어 신설 · 기존 경계나 데이터모델 변경 · 3개 이상 모듈 영향 중 하나라도 해당하면 "구조적".
    93	
    94	**구조적 변경이면 (2-pass):**
    95	1. `ecc:architect`를 dispatch 계약대로 호출해 설계서를 받는다 — 모듈 경계·계약·패턴·대안 트레이드오프. 오케스트레이터가 `_workspace/00_design.md`에 저장.
    96	   **첫 줄에 `사전 결정 회수:` 가 있는지 확인한다** — 없으면 회수 단계를 건너뛴 것이므로 되돌린다. 이 줄은 존재·형식만 검증된다(진짜 읽었는지는 기계가 못 본다 — 강제가 아니라 표명이다).
    97	2. `plan-reviewer` **1차 pass(설계만)**: 제0원칙·계약 명시성·불변식 충돌·과설계를 검증. 보류면 ecc:architect로 루프.
    98	3. `ecc:planner`가 설계서를 입력으로 구현 계획서를 작성. 오케스트레이터가 `_workspace/01_plan.md`에 저장.
    99	4. `plan-reviewer` **2차 pass(계획+정합성)**: 기존 점검 전체 + 설계↔계획 정합성. 보류면 ecc:planner로 루프.
   100	
   101	**비구조적이면 (기존 흐름):**
   102	1. `ecc:planner`로 구현 계획서를 만든다. 영향 범위·모듈 경계(제0원칙)·PR 단위 단계·리스크·테스트 계획. 오케스트레이터가 `_workspace/01_plan.md`에 저장.
   103	2. `plan-reviewer`가 완결성·영향범위 정확성·PR 단위·리스크 누락·테스트 구체성·아키텍처 정합(§4)·제0원칙을 검증.
   104	3. 보류(차단)면 ecc:planner로 되돌려 수정 → 재검증. **승인까지 루프.**
   105	
   106	> 계획에도 generate-verify를 두는 이유: 결함은 늦게 잡을수록 비싸다. 가장 싼 지점(구조적이면 설계 직후)에서 결함을 잡는다. plan-reviewer는 pass마다 새 컨텍스트로 단일 임무만 받으므로 혼란이 없다.
   107	
   108	## Phase 3: 개발↔검수 루프 (developer ⇄ ecc:code-reviewer)
   109	
   110	1. `developer`가 계획대로 구현, 프로필 §3 타입체크+테스트를 통과시킴. 출력 마지막에 `방법론: superpowers:test-driven-development 따름` 줄이 **있는지 확인** — 없으면 미준수로 되돌린다.
   111	2. `ecc:code-reviewer`가(dispatch 계약대로 — 판정 줄·심각도·시나리오·카테고리 태그) 경계면 정합성(§5)·실패 시나리오·불변식 위반(§4)·제0원칙·테스트를 검수.
   112	3. **보안 트리거 판별:** 변경이 인증/인가·사용자 입력·DB 쿼리·파일시스템·외부 API·암호화·결제·시크릿에 닿으면 `ecc:security-reviewer`를 검수와 **병렬** dispatch. CRITICAL = 병합 차단.
   113	4. **듀얼 리뷰:** 같은 diff를 위 "듀얼 리뷰 규칙"대로 Codex에 병렬 리뷰시킨다 (모델·태그·차단 규칙은 공통 규칙 참조).
   114	5. **테스트 품질 리뷰 (조건부):** 새 기능·버그수정처럼 테스트가 핵심 방어선인 변경이거나 검수가 테스트 품질에 의문을 표하면, `ecc:pr-test-analyzer` 에이전트를 병렬 dispatch — 행동 커버리지 관점("이 테스트가 진짜 버그를 잡는가", assert 없는 테스트·mock 범벅·커버리지 숫자 놀음 적발). 지적은 **`[tq]`** 태그로 통합. 신규 에이전트를 만들지 않고 ECC 참조를 쓰는 이유: 만들기 전에 찾는다(레이어 원칙).
   115	6. 보류(CRITICAL/HIGH — cc·cx·ecc:security-reviewer·tq 어느 쪽이든)면 developer로 되돌려 수정 → 재검수. **통과까지 루프.**
   116	7. §3이 런타임/브라우저 관찰을 요구하면 실제 동작 확인까지.
   117	
   118	개발 중 새 모호점이 나오면 clarifier로 에스컬레이션.
   119	
   120	## Phase 4: PR 작성↔점검 루프 (pr-author ⇄ pr-reviewer)
   121	
   122	1. `pr-author`가 §7 정책대로 브랜치→PR 생성 (기본 브랜치에서 새 브랜치, 한 PR=한 변경, Conventional Commits).
   123	2. `pr-reviewer`가 base·파일범위·완결성·정합성·롤백성 점검.
   124	3. 변경요청이면 되돌려 수정 → 재점검. 승인까지 루프.
   125	
   126	## Phase 5: 변경 설명 (change-explainer)
   127	
   128	`change-explainer`가 실제 diff 기반으로 사용자용 설명(§1의 언어)을 만든다. **설명을 사용자에게 낸 뒤에만** `rm -f .claude/.needs-explain`.
   129	
   130	## Phase 6: 완료 감사 게이트 (completion-auditor)
   131	
   132	사용자에게 "완료"라고 보고하기 **직전**, `completion-auditor`가 모든 완료 주장을 1차 증거로 재검증한다 — 파일 실존·커밋 존재(push≠커밋)·PR 상태·테스트 실제 실행·실제 동작 관찰·**운영 반영 여부(§6)**. 반증이 하나라도 나오면 "완료"라 말하지 않고, 무엇이 실제로 됐고 안 됐는지 정확히 보고한 뒤 해당 주체로 되돌린다.
   133	
   134	**이 게이트는 산문이 아니라 훅으로 강제된다** (`.claude/settings.json`). 코드/설정을 편집하면 `.claude/.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` 플래그가 서고, Stop 훅이 타입체크(3절, `harness.env`) + 듀얼 리뷰 + 설명 + **지식 저장소 반영** + 감사 없이는 턴 종료를 막는다(rc=2). 감사자가 검증을 통과시킨 **뒤에만** `rm -f .claude/.needs-audit` — 감사 없이 플래그만 지우는 것은 게이트 무력화다. 같은 지점에서 진전 없이 3회 차단되면 벽돌 방지 통과되며(게이트를 지울 때마다 카운터 리셋), 그때는 완료 주장을 신뢰하지 말 것.
   135	
   136	**지식 저장소 반영 게이트 (2026-08-02 kty 확정 — 실사고 재발 방지):** 결정·설계·개발작업이 나온 턴은 종료 전에 지식 저장소에 반영한다.
   137	
   138	이 하네스는 **그 저장소가 어디이고 어떤 구조인지 모른다.** 아는 것은 계약 하나뿐이다 — *"지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다."* 저장소의 위치·형식·무엇을 어느 파일에 나눠 담는지는 **사용자 층 설정(전역 `CLAUDE.md` 등)이 정본**이다. 그래야 그 저장소를 쓰지 않는 프로젝트에서도 이 하네스가 그대로 돈다(제0원칙 4 — 구체가 아닌 계약에 의존).
   139	
   140	절차: ① 사용자 층이 가리키는 규약을 **전문** 읽는다(부분 독해 금지 — `head -N` 사고 전례) ② 그 규약대로 반영하고 **확인 가능한 증거**(커밋 해시·파일 경로)를 확보한다. 결론만이 아니라 그 판단을 만든 **근거(raw)** 도 규약이 정한 자리에 함께 남긴다 — 요약만 남기면 "왜 그렇게 정했나"가 복원 불가능해진다 ③ `rm -f .claude/.needs-knowledge`.
   141	
   142	반영할 지식이 없으면(순수 버그픽스·기계적 수정) 불요 사유를 `_workspace/progress.md`에 기록한다. **completion-auditor 검증 항목에 포함**: 그 증거를 1차 증거로 확인하고, 불요 판정이면 사유의 타당성을 심사한다.
   143	
   144	게이트는 **기본 켜짐**이다. 지식 저장소를 쓰지 않는 환경이면 `harness.env`의 `HARNESS_KNOWLEDGE_GATE`를 **비워서** 끈다 (`"off"`라고 적으면 켜진 것으로 읽힌다 — 값이 비어 있지 않기 때문이다).
   145	
   146	## Phase 7: 머지 (사용자 승인)
   147	
   148	**머지는 사용자 승인 후에만.** 승인 시 `gh pr merge --squash --delete-branch`. 머지 후 로컬 기본 브랜치 갱신 + §3 검증 재확인. §6에 배포 절차가 있으면 "머지 ≠ 운영 반영"을 사용자에게 명시.
   149	
   150	## 데이터 전달
   151	
   152	- **태스크 기반**(TaskCreate): 진행상황·의존관계.
   153	- **파일 기반**(`_workspace/{phase}_{agent}_{artifact}`): 계획서·검수 결과 등 산출물. 최종물만 사용자 경로/PR로, 중간 파일은 보존.
   154	- **진행 기록 = RAM**(`_workspace/progress.md`): **Phase 전환마다 갱신** — 완료 단계 / 다음 단계 / 미해결 결정. 파일 메모리(캐시)에는 진행 로그를 절대 쓰지 않는다 — 캐시는 규칙·확정 결정 전용. Phase 7 완료 시 `_workspace_prev/`로 아카이브(RAM 해제) — 이력은 claude-mem(SSD)·git이 이미 보존한다.
   155	- **메시지 기반**(SendMessage): 루프 중 피드백.
   156	- **프롬프트 주입**(위 주입 규칙): 프로필 섹션·원칙·기억 검색 결과.
   157	
   158	## 에러 핸들링
   159	
   160	- 에이전트 1회 재시도 후 재실패 시, 결과 없이 진행하되 보고서에 누락 명시.
   161	- 상충 데이터는 삭제하지 말고 출처 병기.
   162	- 파괴적 작업(force push, 브랜치 삭제, 데이터 덮어쓰기)은 실행 전 대상·롤백법 명시하고 필요 시 사용자 확인.
   163	- 프로필이 없거나 §가 비어 있으면: 해당 검증은 "확인 불가"로 명시하고 진행하되, 완료 보고에 "프로필 §N 미작성 — 해당 검증 생략됨"을 남긴다. 지어내지 않는다.
   164	
   165	## 진화 신호 감지 (전문 검수자 추가 판단)
   166	
   167	"성능/접근성 검수자가 필요한가"를 사람의 기억이나 감에 맡기지 않는다. 신호는 하네스가 쌓고, 판단은 임계치가 한다:
   168	
   169	1. **신호 축적**: ecc:code-reviewer dispatch 계약이 지적마다 카테고리 태그(`[성능]` `[접근성]` `[국제화]` 등)를 요구한다. 모든 검수 결과는 claude-mem이 자동 캡처하므로 세션이 끝나도 남는다.
   170	2. **집계·판단**: Phase 6 완료 후, 이번 실행에서 **전문 검수자가 없는 카테고리의 HIGH+ 지적**이 나왔다면 `claude-mem:mem-search`로 같은 카테고리 과거 지적을 검색한다(예: `search(query="reviewer 성능 HIGH")`). **누적 3회 이상**이면 사용자에게 제안한다: "[성능] HIGH 지적이 3회 누적됨 — performance-reviewer를 security-reviewer와 같은 조건부 틀로 추가할까요?"
   171	3. **채택 시 — 만들기 전에 먼저 찾는다**: 자체 제작 전에 `find-skills` 스킬로 스킬 생태계에 기존 해법이 있는지 검색한다(`npx skills find <역량>` — 설치 수 1K+·출처 신뢰도 검증 포함). 쓸만한 것이 있으면 전역 설치(`-g`, 참조 레이어 편입)를 사용자에게 제안하고 끝낸다. 없으면 템플릿 repo(정본)에 에이전트를 추가·커밋하고 각 프로젝트에 sync. 어느 쪽이든 CLAUDE.md 변경 이력에 기록.
   172	
   173	> 이 규칙 덕에 "언제 에이전트를 추가하나"가 세션 기억과 무관해진다 — 어느 세션의 오케스트레이터든 같은 검색으로 같은 누적치를 복원한다.
   174	
   175	## 결정 기록 (ADR — 결정 시점에 구조화 기록)
   176	
   177	**왜 결정 시점인가:** claude-mem(SSD)은 전량 기록이지만 **압축본**이라 추론의 결(기각 사유·트레이드오프)이 손실되고, 사후 추출은 토큰 비용이 크다. 결정이 확정된 **그 자리에서** ADR을 쓴다.
   178	
   179	**트리거 (하나라도 해당하면 작성 — 소소한 수정·자명한 선택은 제외, YAGNI):**
   180	- 대안을 기각하고 방향을 확정했다 (아키텍처·라이브러리·패턴·프로세스)
   181	- 대화에서만 확정되고 diff에 드러나지 않는 결정이다
   182	- 사용자가 "이거 기록해 두자 / ADR"이라 말했다
   183	
   184	**형식** (`ecc:architecture-decision-records`의 Nygard 형식 — 상세는 스킬 호출로 로드):
   185	파일 `docs/decisions/YYYY-MM-DD-<슬러그>.md`, 제목 `# ADR-NNNN: <결정>`(NNNN=디렉토리 일련번호). 필수 섹션: **Context**(무슨 문제) / **Decision**(무엇으로 확정) / **Alternatives Considered**(대안별 Pros·Cons·Why not) / **Consequences**(Positive·Negative).
   186	
   187	**작성 주체:**
   188	- 파이프라인 안에서 확정된 결정 → `pr-author`가 **같은 PR에** ADR 포함
   189	- 파이프라인 밖 대화에서 확정된 결정 → 그 자리에서 메인 세션이 작성, docs-only PR로 제출
   190	
   191	> progress.md(RAM, 휘발·아카이브)와 다르다: ADR은 **영구 큐레이션** — "왜 이렇게 결정했나"의 원료가 git에 쌓인다(블로그·면접용 사고 과정 포트폴리오).
   192	
   193	## 테스트 시나리오
   194	
   195	**정상 흐름**: 사용자가 기능 요청(프로필 §8의 예시 유형) → clarifier(범위·대상 확인 질문) → ecc:planner 계획 + plan-reviewer 승인 → developer 구현(TDD, `방법론:` 줄) + ecc:code-reviewer 검수 통과 → pr-author PR + pr-reviewer 승인 → change-explainer 설명 → completion-auditor 검증 → 플래그 정리 → 사용자 승인 후 머지.
   196	
   197	**에러 흐름**: ecc:code-reviewer가 §5 경계면 shape 불일치 CRITICAL 발견 → developer로 되돌림 → 수정 + 회귀 테스트 → 재검수 통과 → 이후 정상 진행. (또는: Stop 훅이 타입체크 실패로 종료 차단 → developer가 수정 후 재시도.)
   198	
   199	## 파이프라인 밖: 상시 자문 에이전트
   200	
   201	`architecture-guide`는 개발 흐름에 속하지 않는다. 사용자가 "이거 왜 이렇게 짰냐 / 남이 물으면 뭐라 답하지"처럼 **구조의 설계 의도**를 물을 때 직접 호출한다(프로젝트 아키텍처·하네스 둘 다). `change-explainer`(특정 PR의 변화)와 구분: 이쪽은 서 있는 구조의 근거. 코드 변경이 없으므로 이 파이프라인을 타지 않는다.
   202	
   203	## 후속 작업
   204	
   205	"다시/재실행/보완/수정/이전 결과 기반" 요청은 Phase 0에서 `_workspace/` 확인 후 해당 에이전트만 부분 재실행한다. 각 에이전트는 이전 산출물이 있으면 읽고 델타만 반영한다. "검수만 다시" → Phase 3의 ecc:code-reviewer만, "PR만 다시" → Phase 4만 — 단 그 결과가 앞 단계 산출물과 모순되면 해당 앞 단계로 되돌린다.
     1	## 하네스: {{PROJECT_NAME}}
     2	
     3	**목표:** {{한 줄 목표}}
     4	
     5	**제0원칙 (다른 모든 것에 우선):** 모든 개발은 `.claude/harness/principles.md`를 최우선으로 지킨다 — 코드는 사람을 위한 것, 이름=계약, 구현=교체 가능한 부품, 과설계 금지(YAGNI).
     6	
     7	**트리거:** 코드 변경을 수반하는 작업 요청 시 `harness-orchestrator` 스킬을 사용하라. 단순 질문·설명·조회는 직접 응답 가능.
     8	
     9	**도메인 슬롯:** 이 프로젝트의 스택·아키텍처 불변식·경계면·운영 모델·검증 명령은 `.claude/harness/project-profile.md`에 있다.
    10	
    11	**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 게이트 플래그 4종 / Stop 시 타입체크(프로필 3절)+codex 듀얼리뷰+change-explainer+지식 저장소 반영+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
    12	
    13	**지식 저장소 연결은 사용자 층에 있다:** 하네스가 아는 것은 계약 하나뿐이다 — *"지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다."* **어디에 어떤 구조로 반영하는지는 하네스가 모르고, 알아서도 안 된다.** 그 답은 **전역 `CLAUDE.md`(사용자 층)** 이 갖는다 — 거기에 없으면 이 게이트는 무엇을 하라는 건지 알 수 없는 요구가 된다. 지식 저장소를 쓰지 않는 환경이면 `.claude/harness/harness.env` 의 `HARNESS_KNOWLEDGE_GATE` 를 **비워서** 끈다(기본 켜짐, `"off"` 는 켜진 것으로 읽힌다).
    14	
    15	**using-superpowers 전역 선점 비활성:** 이 하네스는 `harness-orchestrator`가 스킬 순서를 통제한다. "응답 전 스킬 먼저"(using-superpowers) 전역 강제가 오케스트레이터 파이프라인을 가로채지 않게 한다. 각 에이전트는 자기 정의에 명시된 superpowers 스킬만 참조 호출한다.
    16	
    17	**변경 이력:**
    18	| 날짜 | 변경 내용 | 대상 | 사유 |
    19	|------|----------|------|------|
    20	| {{YYYY-MM-DD}} | 하네스 템플릿 인스턴스화 | 전체 | - |

2026-08-10T03:51:15.398478Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc 'git status --short && git diff --stat 5ce8597..HEAD && git diff --name-status 5ce8597..HEAD' in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
?? _workspace/04_codex_review.md
?? _workspace/04_review.diff
 .github/workflows/check-rules.yml                  |   14 +
 _workspace/03_impl_r1.diff                         |  100 ++
 _workspace/03_impl_r1_codex.md                     | 1141 ++++++++++++++++++++
 _workspace/04_codex_prompt.md                      |   42 +
 _workspace/mutate-harness-env.sh                   |  199 ++++
 _workspace/mutation-harness-env-2026-08-10.txt     |   56 +
 _workspace/progress.md                             |   81 ++
 .../2026-08-05-knowledge-store-layer-boundary.md   |   19 +-
 .../2026-08-06-knowledge-gate-default-on.md        |  121 +++
 .../2026-08-06-knowledge-retrieval-policy.md       |   70 ++
 .../decisions/2026-08-06-profile-canon-upstream.md |   73 ++
 docs/usage.md                                      |   14 +-
 install.sh                                         |   80 +-
 scripts/check-layer-boundary.sh                    |  146 +++
 sync.sh                                            |   36 +-
 template/.claude/harness/harness.env.template      |   52 +-
 .../.claude/harness/project-profile.template.md    |   23 +-
 template/.claude/hooks/_common.sh                  |  203 +++-
 template/.claude/hooks/mark-needs-audit.sh         |   36 +-
 template/.claude/hooks/verify-before-stop.sh       |   64 +-
 .../.claude/skills/harness-orchestrator/SKILL.md   |   21 +-
 template/CLAUDE.md.snippet                         |    4 +-
 tests/check-layer-boundary.test.sh                 |  204 ++++
 tests/harness-env-read.test.sh                     |  431 ++++++++
 tests/install-hook-swap.test.sh                    |  235 ++++
 tests/mark-needs-audit.cases.sh                    |   52 +-
 tests/mark-needs-audit.test.sh                     |   14 +-
 27 files changed, 3458 insertions(+), 73 deletions(-)
M	.github/workflows/check-rules.yml
A	_workspace/03_impl_r1.diff
A	_workspace/03_impl_r1_codex.md
A	_workspace/04_codex_prompt.md
A	_workspace/mutate-harness-env.sh
A	_workspace/mutation-harness-env-2026-08-10.txt
A	_workspace/progress.md
M	docs/decisions/2026-08-05-knowledge-store-layer-boundary.md
A	docs/decisions/2026-08-06-knowledge-gate-default-on.md
A	docs/decisions/2026-08-06-knowledge-retrieval-policy.md
A	docs/decisions/2026-08-06-profile-canon-upstream.md
M	docs/usage.md
M	install.sh
A	scripts/check-layer-boundary.sh
M	sync.sh
M	template/.claude/harness/harness.env.template
M	template/.claude/harness/project-profile.template.md
M	template/.claude/hooks/_common.sh
M	template/.claude/hooks/mark-needs-audit.sh
M	template/.claude/hooks/verify-before-stop.sh
M	template/.claude/skills/harness-orchestrator/SKILL.md
M	template/CLAUDE.md.snippet
A	tests/check-layer-boundary.test.sh
A	tests/harness-env-read.test.sh
A	tests/install-hook-swap.test.sh
M	tests/mark-needs-audit.cases.sh
M	tests/mark-needs-audit.test.sh

2026-08-10T03:51:50.067974Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "git show 5ce8597:install.sh | nl -ba | sed -n '25,90p'
git show 5ce8597:sync.sh | nl -ba | sed -n '65,135p'
git diff --unified=50 5ce8597..HEAD -- install.sh sync.sh template/.claude/hooks/_common.sh | sed -n '1,700p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
    25	
    26	echo "== 하네스 설치: $NAME"
    27	echo "   템플릿: $TPL_ROOT"
    28	echo "   대상:   $DST"
    29	
    30	# ── 1) 글루 복사 (덮어씀) ─────────────────────────────────────────────
    31	mkdir -p "$DST/agents" "$DST/skills" "$DST/hooks" "$DST/harness"
    32	cp "$SRC/agents/"*.md "$DST/agents/"
    33	# 스킬은 디렉토리째 전부 복사한다(references/·scripts/ 포함) — 특정 스킬명·특정 파일만
    34	# 복사하는 하드코딩은 readable-writing 미배포 버그(2026-08-03 점검)를 낳았다
    35	skill_count=0
    36	for skill_dir in "$SRC/skills/"*/; do
    37	  skill_name="$(basename "$skill_dir")"
    38	  mkdir -p "$DST/skills/$skill_name"
    39	  cp -R "$skill_dir"/. "$DST/skills/$skill_name/"
    40	  skill_count=$((skill_count + 1))
    41	done
    42	cp "$SRC/hooks/"*.sh "$DST/hooks/"
    43	chmod +x "$DST/hooks/"*.sh
    44	cp "$SRC/harness/principles.md" "$DST/harness/"
    45	echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 4 · 제0원칙"
    46	
    47	# ── 1b) 전역 에이전트 배포 (~/.claude/agents/ — 프로젝트 무관 글루, 덮어씀) ──
    48	# 정본은 이 repo의 global-agents/ (전역 디렉토리는 버전 관리가 안 되므로 — ADR-0002)
    49	GLOBAL_SRC="$TPL_ROOT/global-agents"
    50	if [ -d "$GLOBAL_SRC" ] && ls "$GLOBAL_SRC"/*.md >/dev/null 2>&1; then
    51	  mkdir -p "$HOME/.claude/agents"
    52	  cp "$GLOBAL_SRC"/*.md "$HOME/.claude/agents/"
    53	  echo "   전역 에이전트 ✓  $(ls "$GLOBAL_SRC"/*.md | wc -l | tr -d ' ')종 → ~/.claude/agents/"
    54	fi
    55	
    56	# ── 2) 슬롯 스캐폴드 (없을 때만 — 도메인은 사용자가 채운다) ──────────
    57	if [ ! -f "$DST/harness/project-profile.md" ]; then
    58	  sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
    59	    > "$DST/harness/project-profile.md"
    60	  echo "   슬롯 생성 ✓  harness/project-profile.md   ← §1~§8 채우세요"
    61	else
    62	  echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
    63	fi
    64	if [ ! -f "$DST/harness/harness.env" ]; then
    65	  cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
    66	  echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
    67	else
    68	  echo "   슬롯 보존    harness/harness.env          (기존 유지)"
    69	fi
    70	
    71	# ── 3) settings.json 병합 (기존 훅 보존) ────────────────────────────
    72	if [ -f "$DST/settings.json" ]; then
    73	  cp "$DST/settings.json" "$DST/settings.json.bak-$STAMP"
    74	  echo "   settings 백업 → settings.json.bak-$STAMP"
    75	fi
    76	python3 - "$DST/settings.json" "$SRC/settings.json" <<'PYEOF'
    77	import json, os, sys
    78	dst_path, src_path = sys.argv[1], sys.argv[2]
    79	with open(src_path) as f:
    80	    ours = json.load(f)
    81	cur = {}
    82	if os.path.exists(dst_path):
    83	    with open(dst_path) as f:
    84	        cur = json.load(f)
    85	hooks = cur.setdefault("hooks", {})
    86	added = 0
    87	for event, entries in ours.get("hooks", {}).items():
    88	    lst = hooks.setdefault(event, [])
    89	    existing_cmds = {
    90	        (entry.get("matcher"), h.get("command"))
    65	        for e in entries for h in e.get("hooks", [])}
    66	for ev, entries in ours.get("hooks", {}).items():
    67	    for e in entries:
    68	        for h in e.get("hooks", []):
    69	            if (ev, e.get("matcher"), h.get("command")) not in have:
    70	                print(ev + ": " + h.get("command", ""))' "$SRC/settings.json" "$DST/settings.json")
    71	else
    72	  echo "   [신규] settings.json 배선"
    73	  changed=$((changed + 1))
    74	fi
    75	
    76	if [ "$changed" -eq 0 ]; then
    77	  echo "   (변경 없음 — 이미 최신)"
    78	  exit 0
    79	fi
    80	
    81	# ── 3) 적용 (install.sh 멱등 재실행 — 슬롯·CLAUDE.md·settings는 보존/생략됨) ──
    82	echo ""
    83	"$TPL_ROOT/install.sh" "$PROJECT"
    84	echo ""
    85	echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)은 그대로입니다."
diff --git a/install.sh b/install.sh
index 0684588..122ec3f 100755
--- a/install.sh
+++ b/install.sh
@@ -1,116 +1,190 @@
 #!/usr/bin/env bash
 # install.sh — 하네스 템플릿을 프로젝트에 인스턴스화한다.
 #
 # 사용법: ./install.sh <프로젝트-경로> [프로젝트-이름]
 #
 # 동작 원칙:
 #   글루(에이전트·오케스트레이터·훅·제0원칙)  → 복사·덮어씀 (재실행 = 글루 갱신)
 #   슬롯(project-profile.md · harness.env)      → 없을 때만 스캐폴드, 절대 안 덮음
 #   settings.json                               → 병합 (기존 훅 보존, 백업 생성)
 #   CLAUDE.md                                    → 하네스 포인터 append (이미 있으면 생략)
 #
 # 전역 의존(참조, 복사 안 함): ECC 룰(~/.claude/rules/ecc/) · superpowers · claude-mem 플러그인.
 
 set -euo pipefail
 
 TPL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 SRC="$TPL_ROOT/template/.claude"
 
 PROJECT_ARG="${1:?사용법: install.sh <프로젝트-경로> [프로젝트-이름]}"
 PROJECT="$(cd "$PROJECT_ARG" && pwd)"
 NAME="${2:-$(basename "$PROJECT")}"
 DST="$PROJECT/.claude"
 TODAY="$(date +%Y-%m-%d)"
 STAMP="$(date +%Y%m%d-%H%M%S)"   # 백업용 — 같은 날 재설치해도 안 덮이게
 
 echo "== 하네스 설치: $NAME"
 echo "   템플릿: $TPL_ROOT"
 echo "   대상:   $DST"
 
 # ── 1) 글루 복사 (덮어씀) ─────────────────────────────────────────────
 mkdir -p "$DST/agents" "$DST/skills" "$DST/hooks" "$DST/harness"
 cp "$SRC/agents/"*.md "$DST/agents/"
 # 스킬은 디렉토리째 전부 복사한다(references/·scripts/ 포함) — 특정 스킬명·특정 파일만
 # 복사하는 하드코딩은 readable-writing 미배포 버그(2026-08-03 점검)를 낳았다
 skill_count=0
 for skill_dir in "$SRC/skills/"*/; do
   skill_name="$(basename "$skill_dir")"
   mkdir -p "$DST/skills/$skill_name"
   cp -R "$skill_dir"/. "$DST/skills/$skill_name/"
   skill_count=$((skill_count + 1))
 done
-cp "$SRC/hooks/"*.sh "$DST/hooks/"
-chmod +x "$DST/hooks/"*.sh
+# ── 1a) 훅 교체는 파일 단위가 아니라 **디렉터리 rename 스왑** ────────
+#
+# 훅을 하나씩 덮으면 신·구가 섞인 중간 상태가 **반드시** 존재한다. 순서를 바꿔도 못
+# 막는다 — 훅들이 _common.sh 를 공유하므로 어느 쪽을 먼저 바꾸든 창이 열린다. 그 창에서
+# Claude 세션이 훅을 부르면 새 훅이 옛 _common.sh 를(또는 그 반대를) 읽는다.
+#
+# 그래서 스테이징 디렉터리를 만들고 **rename 2회**로 바꾼다. 혼합 상태가 원리적으로
+# 불가능해진다. 대신 두 rename 사이에 훅이 **없는** 창이 생기는데, 그건 잘못된 훅이
+# 도는 것보다 낫다(없으면 게이트가 안 설 뿐, 틀린 판정을 내지 않는다).
+#
+# 파생 계약 셋 — 전부 앞선 검수에서 **직전 수정이 만든 결함**으로 드러난 것들이다:
+#   1. 신호 핸들러는 복구 후 **실제로 종료**해야 한다. 반환만 하면 후속 명령이 계속 돌아
+#      mv 가 기존 디렉터리 **안으로** 중첩되고, 그러고도 "설치 성공"을 보고한다.
+#      그리고 그 exit 에 도달하려면 핸들러 진입 직후 `set +e` 가 필요하다 — 진단 echo
+#      하나가 실패해도(stderr 가 닫힌 채 실행 등) set -e 가 exit 전에 죽인다.
+#   2. 백업 이름은 `mktemp -d` 로 유일성을 보장한다. `$$` 는 PID 재사용으로 선점될 수 있고,
+#      선점되면 훅이 hooks/hooks/*.sh 로 깨지는데 메시지는 "되돌렸습니다"라고 말한다.
+#   3. 자리를 비우려고 `rmdir` 을 먼저 하지 않는다 — 그 사이가 TOCTOU 창이다.
+#      중첩을 **의도된 계약**으로 명시하면(mv "$DST/hooks" "$backup/hooks") 창이 없어진다.
+#
+# 남는 창(공시): 복구 **자체**가 다시 중단되면(SIGKILL·전원 차단) 훅 디렉터리가 없는
+# 상태로 남는다. install.sh 재실행이 복구하지만 그 재실행도 중단되면 같은 상태가
+# 반복된다. 이 창은 닫히지 않았다 — 닫으려면 이 스크립트 밖의 장치가 필요하다.
+if [ -L "$DST/hooks" ]; then
+  # 사용자가 훅 디렉터리를 심볼릭 링크로 두었다. rename 스왑은 그 링크를 **일반
+  # 디렉터리로 갈아치운다** — 사용자의 배치를 하네스가 마음대로 바꾸는 것이라 하지 않는다.
+  # 파일 단위 복사로 물러서고, 원자성을 못 지킨다는 사실을 **알린다**(조용히 물러서지 않는다).
+  echo "   ⚠ .claude/hooks 가 심볼릭 링크입니다 — 링크를 보존하려고 파일 단위로 복사합니다." >&2
+  echo "     교체 도중 신·구가 섞이는 창이 열립니다. 설치 중에는 Claude 세션을 띄우지 마세요." >&2
+  cp "$SRC/hooks/"*.sh "$DST/hooks/"
+  chmod +x "$DST/hooks/"*.sh
+else
+  hooks_stage="$(mktemp -d "$DST/.hooks-stage.XXXXXX")"
+  hooks_backup="$(mktemp -d "$DST/.hooks-old.XXXXXX")"
+  hooks_swapped=0     # 0=아직 안 옮김  1=옛것을 치웠고 새것은 아직 안 들어옴
+  cp "$SRC/hooks/"*.sh "$hooks_stage/"
+  chmod +x "$hooks_stage/"*.sh
+
+  on_swap_signal() {   # $1=신호 이름  $2=종료 코드
+    set +e             # 보고는 최선 노력, **종료 코드가 계약**이다
+    if [ "$hooks_swapped" -eq 1 ] && [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
+      mv "$hooks_backup/hooks" "$DST/hooks"
+      echo "[$1] 훅 교체 도중 중단 — 구판으로 되돌렸습니다." >&2
+    else
+      echo "[$1] 중단되었습니다 (훅 교체는 시작 전이거나 이미 끝났습니다)." >&2
+    fi
+    rm -rf "$hooks_stage" "$hooks_backup"
+    exit "$2"
+  }
+  # QUIT·HUP 도 잡는다: bash 는 trap 이 없으면 QUIT 를 **무시하고 rc=0 을 낸다** —
+  # 중단됐는데 "성공"으로 보고되는 최악의 조합이다(실측).
+  trap 'on_swap_signal INT  130' INT
+  trap 'on_swap_signal TERM 143' TERM
+  trap 'on_swap_signal QUIT 131' QUIT
+  trap 'on_swap_signal HUP  129' HUP
+
+  if [ -d "$DST/hooks" ]; then
+    mv "$DST/hooks" "$hooks_backup/hooks"   # 중첩은 사고가 아니라 계약이다
+    hooks_swapped=1
+  fi
+  if ! mv "$hooks_stage" "$DST/hooks"; then
+    # rename2 실패. **성공으로 오진단하지 않는다** — 되돌리고 실패로 끝낸다.
+    if [ "$hooks_swapped" -eq 1 ] && [ -d "$hooks_backup/hooks" ]; then
+      mv "$hooks_backup/hooks" "$DST/hooks" && echo "   구판 훅으로 되돌렸습니다." >&2
+    fi
+    rm -rf "$hooks_stage" "$hooks_backup"
+    echo "✗ 훅 디렉터리를 교체하지 못했습니다: $DST/hooks" >&2
+    exit 1
+  fi
+  hooks_swapped=0
+  trap - INT TERM QUIT HUP     # 여기부터는 되돌릴 것이 없다
+  rm -rf "$hooks_backup"
+fi
+hook_count="$(ls "$DST/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
+
 cp "$SRC/harness/principles.md" "$DST/harness/"
-echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 4 · 제0원칙"
+echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 $hook_count · 제0원칙"
 
 # ── 1b) 전역 에이전트 배포 (~/.claude/agents/ — 프로젝트 무관 글루, 덮어씀) ──
 # 정본은 이 repo의 global-agents/ (전역 디렉토리는 버전 관리가 안 되므로 — ADR-0002)
 GLOBAL_SRC="$TPL_ROOT/global-agents"
 if [ -d "$GLOBAL_SRC" ] && ls "$GLOBAL_SRC"/*.md >/dev/null 2>&1; then
   mkdir -p "$HOME/.claude/agents"
   cp "$GLOBAL_SRC"/*.md "$HOME/.claude/agents/"
   echo "   전역 에이전트 ✓  $(ls "$GLOBAL_SRC"/*.md | wc -l | tr -d ' ')종 → ~/.claude/agents/"
 fi
 
 # ── 2) 슬롯 스캐폴드 (없을 때만 — 도메인은 사용자가 채운다) ──────────
 if [ ! -f "$DST/harness/project-profile.md" ]; then
   sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
     > "$DST/harness/project-profile.md"
   echo "   슬롯 생성 ✓  harness/project-profile.md   ← §1~§8 채우세요"
 else
   echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
 fi
 if [ ! -f "$DST/harness/harness.env" ]; then
   cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
   echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
+  echo "                                                 (HARNESS_KNOWLEDGE_GATE 는 기본 켜짐)"
 else
   echo "   슬롯 보존    harness/harness.env          (기존 유지)"
 fi
 
 # ── 3) settings.json 병합 (기존 훅 보존) ────────────────────────────
 if [ -f "$DST/settings.json" ]; then
   cp "$DST/settings.json" "$DST/settings.json.bak-$STAMP"
   echo "   settings 백업 → settings.json.bak-$STAMP"
 fi
 python3 - "$DST/settings.json" "$SRC/settings.json" <<'PYEOF'
 import json, os, sys
 dst_path, src_path = sys.argv[1], sys.argv[2]
 with open(src_path) as f:
     ours = json.load(f)
 cur = {}
 if os.path.exists(dst_path):
     with open(dst_path) as f:
         cur = json.load(f)
 hooks = cur.setdefault("hooks", {})
 added = 0
 for event, entries in ours.get("hooks", {}).items():
     lst = hooks.setdefault(event, [])
     existing_cmds = {
         (entry.get("matcher"), h.get("command"))
         for entry in lst
         for h in entry.get("hooks", [])
     }
     for entry in entries:
         # (matcher, command) 단위 병합 — "항목에 하나라도 있으면 전체 스킵"은 같은 항목에 묶인
         # 새 훅(guard-codex-invocation)이 기존 설치본에 영영 배선되지 않는 버그였고(2026-08-03),
         # command만 보면 엉뚱한 matcher에 붙은 훅을 "배선됨"으로 오인한다([cx] 지적).
         missing = [h for h in entry.get("hooks", [])
                    if (entry.get("matcher"), h.get("command")) not in existing_cmds]
         if not missing:
             continue  # 전부 배선됨 (멱등)
         target = next((e for e in lst if e.get("matcher") == entry.get("matcher")), None)
         if target is not None:
             target.setdefault("hooks", []).extend(missing)
         else:
             new_entry = {k: v for k, v in entry.items() if k != "hooks"}
             new_entry["hooks"] = missing
             lst.append(new_entry)
         added += len(missing)
         existing_cmds.update((entry.get("matcher"), h.get("command")) for h in missing)
 with open(dst_path, "w") as f:
     json.dump(cur, f, ensure_ascii=False, indent=2)
     f.write("\n")
 print(f"   settings.json ✓  훅 배선 {added}건 추가 (기존 훅 보존)")
 PYEOF
 
diff --git a/sync.sh b/sync.sh
index fc55158..898f1dd 100755
--- a/sync.sh
+++ b/sync.sh
@@ -26,60 +26,94 @@ if [ "${2:-}" != "--no-pull" ] && git -C "$TPL_ROOT" rev-parse --git-dir >/dev/n
 fi
 
 # ── 2) 글루 diff 미리보기 (슬롯은 비교 대상에서 제외) ───────────────
 echo "== 갱신될 글루 diff:"
 changed=0
 preview() {  # preview <원본> <대상>
   if [ ! -f "$2" ]; then
     echo "   [신규] ${2#"$DST"/}"
     changed=$((changed + 1))
   elif ! diff -q "$1" "$2" >/dev/null 2>&1; then
     echo "   [변경] ${2#"$DST"/}"
     changed=$((changed + 1))
   fi
 }
 for f in "$SRC/agents/"*.md; do preview "$f" "$DST/agents/$(basename "$f")"; done
 for d in "$SRC/skills/"*/; do
   while IFS= read -r f; do preview "$f" "$DST/skills/$(basename "$d")/${f#"$d"}"; done < <(find "$d" -type f)
 done
 for f in "$SRC/hooks/"*.sh; do preview "$f" "$DST/hooks/$(basename "$f")"; done
 preview "$SRC/harness/principles.md" "$DST/harness/principles.md"
 for f in "$TPL_ROOT/global-agents/"*.md; do [ -f "$f" ] && preview "$f" "$HOME/.claude/agents/$(basename "$f")"; done
 
 # settings.json 훅 배선 확인 — 파일 diff만 보면 "글루는 같은데 배선만 누락"(신규 훅이
 # 기존 항목에 묶여 스킵된 경우)을 놓쳐 install이 아예 안 돌았다(2026-08-03 점검).
 if [ -f "$DST/settings.json" ]; then
   # 텍스트 grep이 아니라 JSON 파싱으로 비교한다 — 파일 속 명령은 \" 이스케이프돼 있어
   # 문자열 비교는 전부 누락으로 오탐한다(구현 중 테스트에서 확인).
   while IFS= read -r cmd; do
     [ -z "$cmd" ] && continue
     echo "   [배선 누락] settings.json ← $cmd"
     changed=$((changed + 1))
   done < <(python3 -c '
 import json, sys
 with open(sys.argv[1]) as f: ours = json.load(f)
 with open(sys.argv[2]) as f: cur = json.load(f)
 # (event, matcher, command) 단위 비교 — command만 보면 엉뚱한 이벤트/매처에 붙은
 # 훅을 "배선됨"으로 오인해 조기 종료한다([cx] 지적).
 have = {(ev, e.get("matcher"), h.get("command"))
         for ev, entries in cur.get("hooks", {}).items()
         for e in entries for h in e.get("hooks", [])}
 for ev, entries in ours.get("hooks", {}).items():
     for e in entries:
         for h in e.get("hooks", []):
             if (ev, e.get("matcher"), h.get("command")) not in have:
                 print(ev + ": " + h.get("command", ""))' "$SRC/settings.json" "$DST/settings.json")
 else
   echo "   [신규] settings.json 배선"
   changed=$((changed + 1))
 fi
 
+# 기존 설치본의 harness.env 에는 나중에 생긴 슬롯 키가 없다. **있는 값은 안 건드리되
+# 없는 키는 알려준다** — 키가 없어도 기본값(켜짐)으로 동작하지만, 파일에 한 줄도 없으면
+# 사용자는 그런 스위치가 있다는 것 자체를 모른다.
+add_gate_key=0
+if [ -f "$DST/harness/harness.env" ] \
+   && ! grep -qE '^(export[[:space:]]+)?HARNESS_KNOWLEDGE_GATE=' "$DST/harness/harness.env" 2>/dev/null; then
+  echo "   [슬롯 키 추가] harness/harness.env ← HARNESS_KNOWLEDGE_GATE (기본 켜짐, 기존 값 보존)"
+  add_gate_key=1
+  changed=$((changed + 1))
+fi
+
 if [ "$changed" -eq 0 ]; then
   echo "   (변경 없음 — 이미 최신)"
   exit 0
 fi
 
 # ── 3) 적용 (install.sh 멱등 재실행 — 슬롯·CLAUDE.md·settings는 보존/생략됨) ──
 echo ""
 "$TPL_ROOT/install.sh" "$PROJECT"
+
+# 슬롯 키 덧붙이기 — install.sh **뒤**다. install 이 harness.env 를 새로 만들었다면
+# 템플릿에 이미 키가 들어 있어 여기 올 일이 없다(위 판정은 install 이전 상태를 봤다).
+#
+# **덧붙이기만 한다.** 임시 파일에 쓰고 rename 하는 "원자적 쓰기"를 쓰지 않는 것은
+# 의도적이다 — 그 방식은 검수에서 두 가지 계약 위반을 냈다. 임시 파일 글롭이 사용자의
+# 백업 파일까지 지웠고, 기존 harness.env 가 심볼릭 링크면 일반 파일로 갈아치웠다.
+# 슬롯은 프로젝트 소유이고 하네스는 그것을 **절대 덮지 않는다**가 더 강한 계약이다.
+#
+# 대가: append 는 원자적이지 않다. 중간에 끊기면 줄이 잘릴 수 있다. 다만 그 방향은
+# 안전하다 — 판독이 실패하면 게이트는 **켜진다**(기본값 보존). 그래서 덧붙인 뒤
+# 실제로 읽히는지 확인하고, 안 읽히면 조용히 넘어가지 않고 알린다.
+if [ "$add_gate_key" -eq 1 ]; then
+  envf="$DST/harness/harness.env"
+  if { printf '\n# 지식 반영 게이트 (하네스가 나중에 추가한 슬롯). 끄려면 값을 비운다 —\n# "off" 라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다. 이 줄이 없어도 켜짐이다.\nHARNESS_KNOWLEDGE_GATE="on"\n' >> "$envf"; } 2>/dev/null \
+     && grep -qE '^HARNESS_KNOWLEDGE_GATE=' "$envf" 2>/dev/null; then
+    echo "   슬롯 키 추가 ✓  harness/harness.env  HARNESS_KNOWLEDGE_GATE=\"on\""
+  else
+    echo "   ⚠ harness/harness.env 에 HARNESS_KNOWLEDGE_GATE 를 추가하지 못했습니다(권한·디스크)." >&2
+    echo "     동작은 그대로입니다(키가 없으면 켜짐). 손으로 넣으려면 위 한 줄을 추가하세요." >&2
+  fi
+fi
+
 echo ""
-echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)은 그대로입니다."
+echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)의 **값**은 그대로입니다."
diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
index d052cd3..997b8e0 100644
--- a/template/.claude/hooks/_common.sh
+++ b/template/.claude/hooks/_common.sh
@@ -1,51 +1,252 @@
 #!/usr/bin/env bash
 # 하네스 훅 공용 모듈. 각 훅 스크립트가 source 한다. (도메인-무관 재사용 템플릿)
 #
 # set -e 를 쓰지 않는다: 훅이 예기치 않게 죽으면 세션이 막히거나(Stop)
 # 멀쩡한 명령이 차단된다(PreToolUse). 모든 종료는 명시적으로 한다.
 
 PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
 STATE_DIR="$PROJECT_DIR/.claude"
 AUDIT_FLAG="$STATE_DIR/.needs-audit"
 EXPLAIN_FLAG="$STATE_DIR/.needs-explain"
-VAULT_FLAG="$STATE_DIR/.needs-vault"
+# 지식 저장소 반영 게이트. 이름은 **계약 수준**이다 — 예전 이름은 특정 구현체를 가리켰고,
+# 그래서 그 구현체를 안 쓰는 환경에서 하네스가 없는 구조를 요구하게 됐다.
+KNOWLEDGE_FLAG="$STATE_DIR/.needs-knowledge"
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
+# **대신 셸이 해주던 파싱을 이 함수가 물려받는다.** 그 파싱을 반쯤 하면 fail-open 을
+# 없애려다 다른 fail-open 을 만든다 — 실측된 회귀 6종이 전부 여기서 나왔다.
+# 후행 주석 · 후행 공백 · CRLF 의 `\r` 이 값에 섞여 들어가면 그 값을 받은 `sh -c` 가
+# rc=127 을 내고, 호출부는 그걸 "도구가 없구나"로 읽어 **검사를 조용히 생략한다.**
+# 파일 앞 BOM 은 첫 줄의 키를 통째로 무매치로 만들고, 히어독 본문의 같은 키는 선언으로
+# 세어진다. 셋 다 눈에 보이지 않는다.
+#
+# 그래서 **순서가 계약이다**:
+#   ① 파일 첫머리 BOM 제거 → ② 각 줄 후행 CR 제거 → ③ 히어독 본문 배제 →
+#   ④ 선언 판정 → ⑤ 값 앞 공백 절단 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 **밖** 후행 주석
+#   → ⑧ 남은 후행 공백 절단
+#
+# ── 반환 계약 ──────────────────────────────────────────────────────────
+#   rc=0 : 최상위 선언이 **정확히 1개**이고 값을 지원 문법으로 판독했다.
+#          stdout = 판독된 값. **빈 문자열일 수 있다** — "리터럴로 비웠다"는 뜻이다.
+#   rc=1 : 값을 믿을 수 없다 — 파일 없음 · 읽기 실패 · 선언 0개 · 선언 2개 이상 ·
+#          지원 문법 밖. stdout = 빈 문자열.
+#
+# 왜 이 둘을 rc 로 가르나: 스위치형 슬롯은 "리터럴로 비웠다"(=끈다)와 "미설정"(=이전
+# 동작 보존)이 **반대 방향**이다. 빈 문자열 하나로 뭉뚱그리면 키가 없는 기존 설치본이
+# 업그레이드 순간 게이트가 꺼진 것과 구별되지 않는다.
+#
+# ── 지원 문법 (좁게 고정했다. 이 밖은 전부 rc=1) ───────────────────────
+#   KEY=값  ·  export KEY=값   (export 뒤는 공백 또는 탭)
+#   값: "겹따옴표"  ·  '홑따옴표'  ·  인용 없는 평문
+#   따옴표 뒤에는 공백과 `# 주석` 만 올 수 있다
+#   인용 없는 값은 **공백에 이어지는 `#`** 부터가 주석이다 (`a#b` 의 `#` 은 값의 일부)
+#   값 자리가 `#` 로 시작하면 값은 비어 있는 것으로 본다
+# ── 지원하지 않는 것 (조용히 절반만 읽지 않고 rc=1 로 떨어진다) ────────
+#   백슬래시 이스케이프 · 한 줄에 인용 조각 여러 개(`"a"b`) · 여러 줄 값 ·
+#   닫히지 않은 따옴표
+#
+# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
+# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
+# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 rc=1 이다.
+#
+# 히어독: `<<WORD`·`<<-WORD`·`<<'WORD'` 을 **따옴표 상태를 보며** 찾아 본문을 건너뛴다
+# (`"a << b"` 는 히어독이 아니다). 탐지가 어느 쪽으로 틀려도 결과는 rc=1 로 수렴한다 —
+# 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다. EOF 까지 안 닫히면
+# 탐지가 빗나간 것이므로 역시 rc=1. 한 줄에 히어독이 둘이면 첫 개만 본다.
+#
+# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **판독 시점에 확장되지 않는다** — 원문 그대로
+# 값이 된다. 다만 그 값은 결국 `sh -c` 로 넘어가므로 **실행 시점에는 확장된다**
+# (실측: `HARNESS_TYPECHECK_CMD='printf $HOME'` → 실행하면 홈 경로가 찍힌다).
+# 즉 "확장되지 않는다"가 아니라 "**나중에** 확장된다"이다. 확장이 곤란한 자리라면
+# 그 자리에 최종 문자열을 적어야 한다.
+harness_env_value() {
+  local file="$STATE_DIR/harness/harness.env" key="$1" val rc
+  [ -f "$file" ] || { printf '%s' ''; return 1; }
+  if [ ! -r "$file" ]; then
+    # "미설정"과 "읽기 실패"는 다르다. 판정은 같게(rc=1) 가되 실패는 소리를 낸다.
+    printf '[하네스] harness.env 를 읽지 못했습니다 — 미설정으로 봅니다: %s\n' "$file" >&2
+    printf '%s' ''
+    return 1
+  fi
+  # LC_ALL=C 여야 substr 이 바이트 단위로 동작해 BOM 3바이트를 정확히 떼어낸다.
+  val="$(LC_ALL=C awk -v key="$key" -v bom="$(printf '\357\273\277')" '
+function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
+function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
+
+# 히어독 시작을 찾는다. 따옴표 안의 `<<` 와 주석 뒤의 `<<` 는 히어독이 아니다.
+function scan_heredoc(s,   n, i, j, c, q, t, dash) {
+  n = length(s); i = 1; q = ""
+  while (i <= n) {
+    c = substr(s, i, 1)
+    if (q != "") { if (c == q) q = ""; i++; continue }
+    if (c == "\"" || c == SQ) { q = c; i++; continue }
+    if (c == "#" && (i == 1 || substr(s, i - 1, 1) == " " || substr(s, i - 1, 1) == "\t")) return
+    if (c == "<" && substr(s, i + 1, 1) == "<") {
+      if (substr(s, i + 2, 1) == "<") { i += 3; continue }        # <<< 는 히어스트링
+      j = i + 2; dash = 0
+      if (substr(s, j, 1) == "-") { dash = 1; j++ }
+      while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
+      t = ""; c = substr(s, j, 1)
+      if (c == "\"" || c == SQ) {                                  # <<"EOF" · <<EOF
+        j++
+        while (j <= n && substr(s, j, 1) != c) { t = t substr(s, j, 1); j++ }
+      } else {
+        while (j <= n) {
+          c = substr(s, j, 1)
+          if (c ~ /[A-Za-z0-9_.\/-]/) { t = t c; j++ } else break
+        }
+      }
+      if (t != "") { INHD = 1; HTERM = t; HDASH = dash }
+      return
+    }
+    i++
+  }
+}
+
+# 지원 문법대로 값을 판독한다. 문법 밖이면 BAD 를 세운다(빈 값으로 위장하지 않는다).
+function parse_value(v,   q, rest, e, out, tail, i, c, p) {
+  # 여기서는 **앞** 공백만 턴다. 뒤 공백은 갈래마다 다른 자리에서 털린다 —
+  # 인용 값은 닫는 따옴표 뒤(tail)에서, 인용 없는 값은 반환 직전 rtrim(out) 에서.
+  # 여기서 한 번 더 rtrim 하면 어느 변이로도 죽지 않는 죽은 줄이 된다(변이 측정으로 확인).
+  v = ltrim(v)
+  if (v == "") return ""
+  q = substr(v, 1, 1)
+  if (q == "\"" || q == SQ) {
+    rest = substr(v, 2)
+    e = index(rest, q)
+    if (e == 0) { BAD = 1; return "" }                             # 닫히지 않은 따옴표
+    out = substr(rest, 1, e - 1)
+    tail = ltrim(substr(rest, e + 1))
+    if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음
+    return out
+  }
+  if (q == "#") return ""                                          # 값 자리가 통째로 주석
+  out = ""
+  for (i = 1; i <= length(v); i++) {
+    c = substr(v, i, 1)
+    if (c == "#") {
+      p = substr(v, i - 1, 1)
+      if (p == " " || p == "\t") break
+    }
+    out = out c
+  }
+  return rtrim(out)
+}
+
+BEGIN {
+  SQ = sprintf("%c", 39)
+  N = 0; FOUND = ""; INHD = 0; HTERM = ""; HDASH = 0; BAD = 0
+  RX = "^(export[ \t]+)?" key "="
+}
+{
+  line = $0
+  sub(/\r$/, "", line)
+  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
+
+  if (INHD) {
+    t = line
+    if (HDASH) sub(/^\t+/, "", t)
+    if (t == HTERM) { INHD = 0; HTERM = "" }
+    next
+  }
+
+  # 선언 판정이 히어독 시작 판정보다 **먼저**다: `KEY=v <<EOF` 의 대입은 실제로 발효한다.
+  if (line ~ RX) {
+    N++
+    if (N == 1) FOUND = substr(line, index(line, "=") + 1)
+  }
+  scan_heredoc(line)
+}
+END {
+  if (INHD) exit 1          # 히어독이 EOF 까지 안 닫혔다 = 탐지가 빗나갔다
+  if (N != 1) exit 1
+  v = parse_value(FOUND)
+  if (BAD) exit 1
+  printf "%s", v
+  exit 0
+}
+' "$file" 2>/dev/null)"
+  rc=$?
+  [ "$rc" -eq 0 ] || { printf '%s' ''; return 1; }
+  printf '%s' "$val"
+  return 0
+}
+
+# 지식 반영 게이트가 켜져 있는가 (rc=0 켜짐 / rc=1 꺼짐).
+#
+# 하네스가 소유하는 것은 **계약 하나**뿐이다 — "지식 저장소가 설정돼 있으면, 결정·설계가
+# 나온 턴은 반영 없이 끝낼 수 없다." 어디에 어떤 구조로 반영하는지는 이 층이 모른다.
+# 그래서 필요한 것도 1비트뿐이고, 그 1비트를 얻으려고 파일을 실행하지 않는다.
+#
+# **기본이 켜짐인 것이 이 함수의 핵심이다.** 기존 설치본에는 이 키가 아예 없는데,
+# 없을 때 "꺼짐"으로 읽으면 하네스를 갱신하는 순간 게이트가 **조용히 꺼진다** — 사용자는
+# 지식이 쌓인다고 믿는데 그 턴부터 아무것도 안 남는다. 표명이 없으면 이전 동작을 보존한다.
+# 선언이 2개 이상이거나 문법 밖일 때도 같은 이유로 켠다(rc=1 → 켜짐).
+#
+# 끄는 방법은 **값을 리터럴로 비우는 것 하나뿐**이다: HARNESS_KNOWLEDGE_GATE=""
+# `="off"` 는 켜진 것으로 읽힌다 — 비어 있지 않기 때문이다. harness.env 주석에 명시돼 있다.
+harness_knowledge_gate_on() {
+  local v
+  v="$(harness_env_value HARNESS_KNOWLEDGE_GATE)" || return 0   # 값을 못 믿으면 켠다
+  [ -n "$v" ]                                                   # 리터럴로 비었을 때만 꺼짐
+}
+
+# 지식 게이트가 이번 턴에 **발효 중인가** — 플래그가 섰고 게이트도 켜져 있는가.
+# 판정을 이 한 곳에 모은다. 두 군데서 따로 물으면 "게이트를 껐는데 남아 있던 플래그가
+# 읽기 전용 턴의 조기 종료를 막는" 종류의 어긋남이 생긴다.
+knowledge_gate_active() {
+  [ -s "$KNOWLEDGE_FLAG" ] || return 1
+  harness_knowledge_gate_on
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

2026-08-10T03:51:56.030353Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "git diff --unified=30 5ce8597..HEAD -- template/.claude/hooks/mark-needs-audit.sh tests/mark-needs-audit.cases.sh tests/mark-needs-audit.test.sh docs/usage.md | sed -n '1,900p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
diff --git a/docs/usage.md b/docs/usage.md
index 62a102a..7864cbe 100644
--- a/docs/usage.md
+++ b/docs/usage.md
@@ -1,109 +1,113 @@
 # 사용법 — 하네스 템플릿
 
 ## 0. 전제 (전역 1회 설치, 템플릿은 참조만)
 
 | 의존 | 위치 | 없으면 |
 |---|---|---|
 | ECC 룰 | `~/.claude/rules/ecc/` | 코딩/테스트 표준 미적용 (하네스는 동작) |
 | **ECC 에이전트** (planner·architect·code-reviewer·security-reviewer·pr-test-analyzer) | ECC 플러그인(`ecc:` 접두) 또는 `~/.claude/agents/` 전역 설치본 | 설계·계획·검수·보안검수 4역할 dispatch 실패 → 오케스트레이터가 직접 대체 수행하며 "ECC 미설치" 명시 |
 | superpowers 플러그인 | 플러그인 매니저 | 에이전트의 방법론 스킬 호출 실패 → 해당 단계 품질 저하 |
 | claude-mem 플러그인 | 플러그인 매니저 | 착수 전 과거 기억 검색(recall) 생략됨 |
 | find-skills 스킬 | `~/.claude/skills/find-skills` (`npx skills add vercel-labs/skills --skill find-skills`) | 진화 시 "만들기 전에 생태계 검색" 생략 → 바로 자체 제작으로 감 |
 | codex CLI (선택) | `npm i -g @openai/codex` + `codex login`(사용자 직접) + `claude mcp add --scope user codex -- codex mcp-server` | 모든 검증 게이트(계획검증·검수·PR점검)의 듀얼 리뷰(cc/cx) 생략 — Claude 단독으로 진행하되 보고에 "듀얼 리뷰 생략" 명시 |
 | `gh` CLI | PATH | PR 단계(Phase 4) 불가 |
 
 ## 1. 설치 (프로젝트당 1회)
 
 ```bash
 cd ~/.claude/harness-template
 ./install.sh /path/to/project [프로젝트이름]
 ```
 
 install이 하는 일: 글루 복사(자체 에이전트 8·스킬 2(harness-orchestrator·readable-writing)·훅 4·제0원칙) + 슬롯 스캐폴드(없을 때만) + settings.json 병합(기존 훅 보존·명령 단위 추가·백업) + CLAUDE.md 포인터 append.
 
 설계·계획·검수·보안검수 4역할은 자체 에이전트가 아니라 **ECC 참조**(`ecc:architect`·`ecc:planner`·`ecc:code-reviewer`·`ecc:security-reviewer`)다 — 하네스 계약(판정 형식·태그·프로필 준수)은 오케스트레이터의 dispatch 계약이 프롬프트로 주입한다. 이 중 2종은 **조건부**로만 돈다: `ecc:architect`(구조적 변경 — 새 모듈/레이어·경계/데이터모델 변경·3개+ 모듈 영향 — 일 때 Phase 2 전단, plan-reviewer가 설계·계획 2-pass 검증), `ecc:security-reviewer`(보안 민감 변경 — 인증/입력/DB/파일시스템/외부API/암호화/결제/시크릿 — 일 때 Phase 3에서 검수와 병렬, CRITICAL=병합 차단). 추가로 테스트가 핵심 방어선인 변경에는 ECC의 `pr-test-analyzer`를 참조 dispatch(`[tq]` 태그) — 템플릿 소유 에이전트가 아니라 전역 ECC 재사용.
 
 **설치 후 반드시 2개 슬롯 채우기:**
 1. `.claude/harness/project-profile.md` — §1~§8 (도메인 전부: 스택·검증 명령·불변식·경계면·운영·vcs·예시). 작성 예시는 이 repo의 `examples/chat-system.profile.md`.
-2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략).
+2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략) · `HARNESS_KNOWLEDGE_GATE` (지식 저장소 반영 게이트. **기본 켜짐**이고, 끄는 방법은 **값을 비우는 것 하나뿐**이다 — `"off"`라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다).
+
+**`harness.env` 는 실행되지 않는다.** 확장자와 문법은 셸이지만 훅은 이 파일을 source 하지 않고 줄을 읽어 값만 뽑는다 — 1비트를 얻으려고 사용자 소유 셸 파일에 훅의 제어 흐름을 넘길 이유가 없기 때문이다(`exit 0` 한 줄로 완료 게이트 4종이 흔적 없이 사라진 실측이 있다). 대신 지원 문법이 좁다: **한 키는 정확히 한 번만**, 선언은 줄 **맨 앞**에서 시작, 값에 공백이 있으면 따옴표, 후행 주석은 따옴표 뒤에만. 어기면 그 키는 **미설정**으로 떨어지고 해당 검사가 생략된다(생략 사유는 완료 게이트 메시지에 적힌다). 전체 규칙은 `harness.env` 파일 첫머리에 있다.
 
 **주의: 훅은 세션 시작 시 스냅샷된다** → 설치한 세션에는 발화하지 않고 **다음 세션부터** 적용.
 
 ## 2. 무엇이 재사용이고 무엇이 슬롯인가
 
 | 층 | 파일 | 갱신 주체 |
 |---|---|---|
 | **글루 (재사용)** | `agents/*.md` · `skills/*/`(harness-orchestrator·readable-writing) · `hooks/*.sh` · `harness/principles.md` | `sync.sh` (템플릿 개선 시) |
 | **슬롯 (프로젝트 소유)** | `harness/project-profile.md` · `harness/harness.env` | 사용자 — sync가 절대 안 덮음 |
 | **참조 (전역)** | ECC 룰 · superpowers 스킬 · claude-mem | 각 시스템 업데이트 시 자동 최신 |
 
 ## 3. 일상 사용
 
 - **개발 요청** ("~만들어줘/고쳐줘/추가해줘") → `harness-orchestrator` 스킬이 자동 트리거되어 파이프라인 실행: 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사. 머지는 항상 사용자 승인 후.
 - **부분 재실행** — "검수만 다시", "PR만 다시" → 해당 단계만 돈다.
 - **설계 질문** ("왜 이렇게 짰어") → `architecture-guide` 에이전트 직접 호출 (파이프라인 밖).
 - **변경 질문** ("이번에 뭐 바뀌었어") → `change-explainer` 직접 호출.
 
 ## 4. 템플릿 갱신 (sync)
 
 ```bash
 cd ~/.claude/harness-template
 ./sync.sh /path/to/project            # git pull + diff 미리보기 + 글루만 갱신
 ./sync.sh /path/to/project --no-pull  # 로컬 정본만으로
 ```
 
 이미 설치된 프로젝트는 sync 전까지 설치 시점 스냅샷 유지(조용한 기본값). 새 설치는 항상 그 시점 최신 글루.
 
 ## 5. 강제 훅 게이트 (이 하네스의 무기)
 
 | 훅 | 시점 | 강제 내용 |
 |---|---|---|
 | guard-master-commit | Bash 실행 전 | master/main 직접 `git commit` 차단 |
 | guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
-| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview` (설계·계획 산출물은 듀얼리뷰 플래그만, 코드는 4종 전부). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
-| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → codex 듀얼리뷰 → change-explainer → 볼트(second brain) 반영 → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
+| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (설계·계획 산출물은 듀얼리뷰 플래그만, 코드는 4종 전부). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
+| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → codex 듀얼리뷰 → change-explainer → **지식 저장소 반영** → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
+
+**지식 저장소 게이트가 아는 것은 계약 하나뿐이다** — "지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다." **어디에 어떤 구조로 반영하는지는 하네스가 모른다.** 그건 사용자 층 설정(전역 `CLAUDE.md` 등)이 답하고, 하네스에는 켜짐/꺼짐 1비트만 있다. 그래서 지식 저장소를 바꿔도 하네스는 고치지 않고, 아예 안 쓰는 프로젝트에서도 그대로 돈다.
 
-**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:vault`(볼트 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
+**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
 
 ### 완료 게이트 검사 범위 (mark-needs-audit)
 
 판정 **순서가 곧 계약**이다: 개행 가드 → 물리 경로 정규화 → 듀얼리뷰 판정 → 범위 판정 → 분류 → 기록.
 
 - **프로젝트 안** — `_workspace/`·`.claude/`·문서 `*.md`·`*.markdown`(대소문자 무관)는 제외. 나머지는 게이트 4종.
   단 **문서 제외에는 예외가 둘** 있다(동작을 정의하는 마크다운이라 코드로 취급한다):
   `.claude/` 에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`), 그리고
   **프로젝트 자신이 하네스 정본일 때의 `global-agents/*.md`**. 둘 다 `*.md` 제외보다 **먼저** 판정된다.
 - **프로젝트 밖 + 하네스 정본 저장소**(루트에 `template/.claude/` 존재) — 저장소 **전체**를 **프로젝트와 같은 규칙으로** 검사한다. `scripts/`·`install.sh`·`global-agents/*.md` 포함(전부 하네스 동작을 정의한다). "같은 규칙"이므로 위의 제외도 **그대로** 적용된다 — 정본 저장소 안이라도 `_workspace/`·`.claude/`·순수 문서는 게이트가 서지 않는다. 지금 읽고 있는 이 파일(`docs/usage.md`)이 그 예다.
 - **프로젝트 밖 + 그 외** — `.claude/`에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`)만. **git 저장소가 아니어도** 발화한다.
 - **설계·계획 산출물**(`_workspace/00_design*.md`·`01_plan*.md`) — 위치·git 여부와 무관하게 듀얼리뷰 플래그만 세운다.
 - **밖 편집은 절대경로로 기록**한다. 상대경로로 적으면 프로젝트와 외부 저장소가 `README.md` 같은 흔한 경로를 공유할 때 감사자가 프로젝트 쪽 동명 파일을 보고 통과시킨다.
 - 플래그를 못 쓰거나 경로에 개행이 있으면 **차단하지 않고** `systemMessage`로 알린다(PostToolUse는 항상 exit 0). git 호출이 실패했는데 조상에 `.git`이 있으면 그 사실도 알린다 — 정본 저장소가 조용히 앵커 전용으로 강등되는 것을 사람이 알 수 있게.
 
 계약의 **기계 정본**은 `tests/mark-needs-audit.cases.sh`의 판정 표이고, 케이스 수는 같은 파일의 `EXPECTED_CASES`가 강제한다. CI가 PR마다 돌린다.
 
 ## 6. 트러블슈팅
 
-- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 볼트 반영(`.needs-vault`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
+- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 지식 저장소 반영(`.needs-knowledge`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
 - **타입체크가 이상하게 실패** → `harness.env`의 명령을 셸에서 직접 실행해 확인. 도구 부재(rc=127)·타임아웃은 차단 안 하고 생략 처리된다.
 - **superpowers 스킬 호출 실패** → 플러그인 설치/이름 확인: `test-driven-development`·`writing-plans`·`brainstorming`·`requesting-code-review`·`verification-before-completion`·`systematic-debugging`.
 - **에이전트가 도메인을 무시** → 프로필 §가 비어 있지 않은지 확인. 오케스트레이터는 빈 §를 "검증 생략"으로 정직 보고한다.
 
 ## 7. 하네스 진화
 
 에이전트/스킬 수정·추가는 이 repo(정본)에서 하고 커밋 → 각 프로젝트에 `sync.sh`. 구조 변경이 크면 `harness` 메타 스킬(운영/유지보수 워크플로우)을 사용. 변경 이력은 각 프로젝트 CLAUDE.md의 변경 이력 표에 기록.
 
 ### 제0원칙 판정 기준을 고칠 때
 
 판정 기준(`principles.md`의 `rule:core` 블록)은 판정자 에이전트가 **자기 정의 안에 사본으로** 들고 있다. 참조만 두면 에이전트가 그 파일을 읽는다는 보장이 없어서다. 그래서 고치는 순서가 정해져 있다.
 
 1. 정본 `template/.claude/harness/principles.md`의 `rule:core` 블록을 고친다.
 2. 사본(`template/.claude/agents/plan-reviewer.md` 점검 항목 7)에 **그대로 복사**한다.
 3. 검사한다.
 
 ```bash
 ./scripts/check-rule-copies.sh
 ```
 
 어긋나면 종료 코드 1과 함께 diff가 나오고, CI(`.github/workflows/check-rules.yml`)가 PR을 막는다. 마커 **밖**의 문맥별 설명은 동기화 대상이 아니니 파일마다 자유롭게 써도 된다 — 판정 기준만 동기화한다. 다만 마커 줄 자체는 앞뒤 공백·설명 없이 정확히 한 줄(`<!-- rule:core:start -->` / `<!-- rule:core:end -->`, CRLF 줄끝 불가)이어야 한다. 꾸미면 마커로 인정되지 않는다 — 마커를 꾸며 판정 기준을 바꿔치기하는 길을 막기 위해서다. 같은 이유로 `template/` 아래에는 심링크와 NUL 바이트를 포함한 파일(바이너리·UTF-16 등)을 둘 수 없다 — 검사기가 내용을 확인할 수 없어 낡은 사본이 조용히 배포되는 경로가 열리기 때문이다.
 
 판정자를 새로 추가해 사본이 늘면 `scripts/check-rule-copies.sh`의 `COPIES` 배열에 경로 한 줄을 추가해야 한다 — `template/` 안에 마커를 둔 채 등록하지 않으면 검사기가 종료 코드 1로 막는다. 그 경로는 반드시 `template/` **아래**여야 한다: 심링크·NUL·미등록 게이트가 전부 `template/`만 훑기 때문에, 밖을 가리키면 등록만 되고 정작 검사는 안 되는 사본이 생긴다(검사기가 이것도 종료 코드 1로 막는다). `..`나 심링크를 거쳐 밖으로 나가는 표기도 물리 경로로 풀어 같이 막는다. 경로에 개행이 들어간 파일은 아예 등록할 수 없다 — 개행은 경로 계산 과정에서 잘려 나가 바깥 파일을 안쪽으로 오인시키므로, 범위 판정 자체가 성립하지 않는다. 반대로 `COPIES`를 통째로 비워 둘 수도 없다 — 대조할 사본이 0개면 검사기가 지키는 것이 아무것도 없는데도 초록으로 보이므로, 빈 배열도 종료 코드 1로 막는다.
diff --git a/template/.claude/hooks/mark-needs-audit.sh b/template/.claude/hooks/mark-needs-audit.sh
index 083bcd0..abe36b8 100644
--- a/template/.claude/hooks/mark-needs-audit.sh
+++ b/template/.claude/hooks/mark-needs-audit.sh
@@ -125,164 +125,190 @@ git_toplevel() {
 # has_git_ancestor <절대경로> — 조상 디렉토리에 .git 이 있는가. git 을 쓰지 않는다.
 # git_toplevel 이 빈 값을 돌려준 이유가 "저장소가 아님"인지 "git 이 거부함"인지를 가르는
 # 데 쓴다. rev-parse 는 둘 다 rc=128 로 돌려주므로 stderr 내용으로 가르는 것은 취약하다.
 has_git_ancestor() {
   local d
   d="$(dirname -- "$1")"
   while [ "$d" != '/' ] && [ "$d" != '.' ]; do
     [ -e "$d/.git" ] && return 0
     d="$(dirname -- "$d")"
   done
   return 1
 }
 
 # is_harness_canonical <저장소루트> — 하네스 정본 저장소인가.
 # 마커는 이 한 조건뿐이다. 조건을 더 얹으면 재배치 포크에서 위음성이 넓어지는데,
 # 위음성은 조용하고 오탐은 탈출구(ECC_DISABLED_HOOKS)가 있다 — 그래서 단순한 쪽을 택했다.
 is_harness_canonical() {
   [ -d "$1/template/.claude" ]
 }
 
 # harness_anchor <선행 슬래시가 있는 경로> — 하네스 동작을 정의하는 자리인가.
 # 앵커 목록을 정의하는 **유일 지점**이다.
 harness_anchor() {
   case "$1" in
     */.claude/agents/*|*/.claude/skills/*|*/.claude/hooks/*|*/.claude/harness/*|*/.claude/settings.json)
       return 0 ;;
   esac
   return 1
 }
 
-# classify <기준 상대경로> <기준 디렉토리> — gate 또는 skip 을 stdout 에.
+# classify <기준 상대경로> <기준 디렉토리> — gate · knowledge · skip 을 stdout 에.
 # 프로젝트 안(4a)과 밖-하네스정본(4b)이 **같은 규칙**을 쓰도록 공유한다.
 #
 # 순서가 계약이다:
 #   1) .claude/*·_workspace/* 제외가 앵커보다 **먼저**. 그래야 하네스 정본 저장소가
 #      자기 자신에 설치해 둔 소비 사본(.claude/hooks/*)이 빠지고 정본(template/.claude/*)만
 #      발화한다. 설치본은 정본을 고쳐 sync 하는 게 규약이라 제자리 편집은 일시적이다.
 #   2) 앵커가 *.md 제외보다 먼저. 에이전트·스킬·원칙 정의는 전부 .md 인데 일괄 제외하면
 #      하네스 저장소에서 가장 흔한 변경에 플래그가 하나도 안 선다.
 #   3) global-agents/*.md 는 **정본 스코프에서만** 예외의 예외를 연다. install/sync 가
 #      배포하는 전역 에이전트 정본이기 때문이며, 남의 프로젝트로 새면 오탐이 된다.
 classify() {
   local rel="$1" base="$2" lower
   case "$rel" in
     _workspace/*|.claude/*) printf 'skip\n'; return 0 ;;
   esac
   if harness_anchor "/$rel"; then
     printf 'gate\n'; return 0
   fi
   case "$rel" in
     global-agents/*.md)
       if is_harness_canonical "$base"; then printf 'gate\n'; return 0; fi ;;
   esac
   # 확장자 판정은 소문자화해서 본다 — README.MD 가 코드로 취급되면 안 된다.
   lower="$(printf '%s' "$rel" | tr '[:upper:]' '[:lower:]')"
+  # 결정 문서는 문서 제외의 **예외**다. 하네스가 스스로 "결정은 여기 이 이름으로 쓴다"고
+  # 규정한 경로(결정 기록 절)라 **하네스가 아는 산출물**이고, 그 자리가 편집됐다는 것은
+  # 곧 결정이 나왔다는 뜻이다. 코드가 아니므로 게이트 4종은 과하다 — 지식 게이트만 세운다.
+  #
+  # 공시된 한계: 결정 문서를 이 경로 **밖**에 두면 게이트가 서지 않는다. 하네스가 아는
+  # 경로만 알 수 있기 때문이고, 프로젝트마다 다른 위치를 알아내려면 다시 상위 층 구현을
+  # 알아야 한다. 이 공백은 회수 정책 ADR 로 넘긴다.
+  case "$lower" in
+    docs/decisions/*.md|docs/decisions/*.markdown) printf 'knowledge\n'; return 0 ;;
+  esac
   case "$lower" in
     *.md|*.markdown) printf 'skip\n'; return 0 ;;
   esac
   printf 'gate\n'
 }
 
 # record_flag <플래그파일> <값> — 이미 있으면 그냥 두고, 없으면 한 줄 덧붙인다. 실패하면 rc=1.
 # grep 의 -- 는 필수다: 값이 - 로 시작하면(예: 파일명 --version) grep 이 그것을 옵션으로
 # 해석해 rc=0(=이미 있음)을 돌려주고, BSD grep 은 -q 아래서도 버전 문자열을 stdout 에 뱉는다.
 # append 를 중괄호로 감싸는 것도 필수다: 리다이렉트 **열기** 실패는 셸이 보고하는데,
 # printf 뒤에 붙인 2>/dev/null 은 그 시점에 아직 적용되지 않아 stderr 가 샌다(실측).
 record_flag() {
   mkdir -p "$STATE_DIR" 2>/dev/null
   if grep -qxF -- "$2" "$1" 2>/dev/null; then
     return 0
   fi
   { printf '%s\n' "$2" >> "$1"; } 2>/dev/null || return 1
   return 0
 }
 
 # --- 판정 -----------------------------------------------------------------
 
 payload="$(cat)"
 # json_get 결과를 **센티널로** 받는다. 명령 치환은 후행 개행을 전부 지우므로 그냥 받으면
 # 경로 끝의 개행이 아래 가드에 닿기도 전에 사라지고, 경고 없이 **다른 파일** 경로가
 # 기록된다("src/app.ts" + LF → "src/app.ts"). X 를 붙여 받고 도로 뗀 뒤, json_get 자신이
 # print() 로 붙인 개행 **하나만** 지운다 — 그러면 원본의 후행 개행이 살아남는다.
 raw="$(printf '%s' "$payload" | json_get tool_input.file_path; printf 'X')"
 raw="${raw%X}"
 file_path="${raw%$'\n'}"
 [ -z "$file_path" ] && exit 0
 
 # 개행 가드는 **정규화보다 먼저**여야 한다. 디렉토리 컴포넌트가 개행으로 끝나면
 # (…/sr<LF>/app.ts) physical_path 의 pwd -P 출력을 받는 명령 치환이 그 개행을 먹어
 # 경로가 …/sr/app.ts 로 조용히 바뀐다 — 없는 파일이 게이트에 박히고 정작 편집한
 # 파일은 무게이트가 된다. 플래그 파일은 줄 단위라 개행이 든 경로는 애초에 못 적는다.
 case "$file_path" in
   *$'\n'*) emit_message "$MSG_NEWLINE"; exit 0 ;;
 esac
 
 # 양쪽을 물리 경로로 맞춘 뒤에 비교한다. git 은 실제 경로를 돌려주는데 편집 경로는
 # 심링크를 지나올 수 있고(macOS /var → /private/var), .. 로 되돌아올 수도 있다.
 # 정규화 없이 자르면 접두사가 안 맞아 프로젝트 안 편집이 통째로 "밖"으로 샌다.
 # PROJECT_DIR 은 디렉토리라 통째로 물리화한다(심링크 PROJECT_DIR — 케이스 11·12).
 # 편집 경로는 파일이라 마지막 성분 이름을 보존하는 physical_path 를 쓴다 — 두 계약이
 # 다르므로 함수도 둘이다.
 proj="$(physical_dir "$PROJECT_DIR")"
 case "$file_path" in
   /*) ;;
   *) file_path="$proj/$file_path" ;;
 esac
 abs="$(physical_path "$file_path")"
 
 # 설계·계획 산출물은 위치·git 여부와 무관하게 듀얼리뷰 게이트만 세운다.
 # **정규화 뒤**에 판정해야 한다: 상대경로 입력에는 선행 슬래시가 없어 아래 글롭에
 # 걸리지 않고, .. 가 섞인 경로는 기록값이 .claude/../_workspace/… 로 남는다.
 # 매칭만 소문자화하고 기록은 원본 대소문자로 한다.
 lower_abs="$(printf '%s' "$abs" | tr '[:upper:]' '[:lower:]')"
+# 설계·계획 산출물은 듀얼리뷰 **와 지식 게이트**를 세운다. 코드가 아니므로 타입체크·
+# 변경설명·감사는 과하지만, 설계가 나온 턴을 지식 저장소 반영 없이 끝내면 "왜 그렇게
+# 정했나"가 그 자리에서 사라진다 — 결정을 만든 근거가 정확히 이 파일들이다.
 case "$lower_abs" in
   */_workspace/00_design*.md|*/_workspace/01_plan*.md)
     dual_value="$(project_rel "$abs")" || dual_value="$abs"
-    record_flag "$DUALREVIEW_FLAG" "$dual_value" || emit_message "$MSG_WRITE_FAIL"
+    dw=0
+    record_flag "$DUALREVIEW_FLAG" "$dual_value" || dw=1
+    record_flag "$KNOWLEDGE_FLAG"  "$dual_value" || dw=1
+    [ "$dw" -eq 1 ] && emit_message "$MSG_WRITE_FAIL"
     exit 0 ;;
 esac
 
 if rel="$(project_rel "$abs")"; then
   value="$rel"
   verdict="$(classify "$rel" "$proj")"
 else
   # 프로젝트 밖. 기록값은 절대경로다.
   value="$abs"
   root="$(git_toplevel "$abs")" || root=''
   if [ -n "$root" ] && is_harness_canonical "$root"; then
     case "$abs" in
       "$root"/*) rel="${abs#"$root"/}" ;;
       *) rel="$abs" ;;
     esac
     verdict="$(classify "$rel" "$root")"
   elif harness_anchor "$abs"; then
     # 앵커 판정에 git 을 요구하지 않는다 — 홈에 설치된 .claude/agents/*.md 는
     # 그 디렉토리가 git 저장소가 아니어도 하네스 동작을 정의한다.
     verdict='gate'
   else
     verdict='skip'
     # git 이 빈 값을 돌려줬는데 조상에 .git 이 있으면, 저장소가 아닌 게 아니라 git 이
     # 거부한 것이다(safe.directory 소유권 거부·권한·손상). 그대로 두면 정본 저장소
     # 전체가 앵커 밖 파일에 대해 무게이트 + 무신호로 조용히 감시 축소된다.
     # 판정은 바꾸지 않는다(추측으로 게이트를 세우면 남의 저장소를 오탐한다) — 알리기만
     # 한다. physical_path 가 fail-loud 인데 여기만 fail-silent 이던 비대칭을 없앤다.
     [ -z "$root" ] && has_git_ancestor "$abs" && emit_message "$MSG_GIT_UNAVAILABLE"
   fi
 fi
 
+# 결정 문서는 지식 게이트 하나만. 코드가 아니므로 타입체크·변경설명·감사는 과하다.
+if [ "$verdict" = 'knowledge' ]; then
+  record_flag "$KNOWLEDGE_FLAG" "$value" || emit_message "$MSG_WRITE_FAIL"
+  exit 0
+fi
+
 [ "$verdict" = 'gate' ] || exit 0
 
 # 완료 게이트 4종을 동시에 세운다:
 #   .needs-audit      → completion-auditor 강제 (Phase 6)
 #   .needs-explain    → change-explainer 강제 (Phase 5)
-#   .needs-vault      → 볼트(second brain) 반영 또는 불요 사유 기록 강제 (2026-08-02 kty —
-#                       세션 내내 볼트 Auto-Save 가 기억에만 의존해 0회 이행된 실사고의 재발 방지)
+#   .needs-knowledge  → 지식 저장소 반영 또는 불요 사유 기록 강제 (2026-08-02 kty —
+#                       산문 규칙이 기억에만 의존해 세션 내내 0회 이행된 실사고의 재발 방지)
 #   .needs-dualreview → codex 듀얼 리뷰 강제 (2026-08-03 kty)
 # 각 게이트는 해당 작업이 실제로 끝난 뒤에만 수동으로 지워진다. Stop 훅이 넷 다 본다.
+#
+# 지식 게이트가 꺼져 있어도 여기서는 **기록한다.** 켜짐/꺼짐 판정은 harness.env 를 한 번
+# 더 읽는 일인데 이 훅은 편집마다 돌고 Stop 훅은 턴에 한 번 돈다 — 판정은 Stop 쪽
+# 한 곳(knowledge_gate_active)으로 모았다. 꺼져 있으면 이 파일은 아무 효력이 없다.
 write_failed=0
-for flag in "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$VAULT_FLAG" "$DUALREVIEW_FLAG"; do
+for flag in "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG"; do
   record_flag "$flag" "$value" || write_failed=1
 done
 # 넷이 다 실패해도 메시지는 한 줄만 낸다.
 [ "$write_failed" -eq 1 ] && emit_message "$MSG_WRITE_FAIL"
 exit 0
diff --git a/tests/mark-needs-audit.cases.sh b/tests/mark-needs-audit.cases.sh
index 85db753..73ac931 100644
--- a/tests/mark-needs-audit.cases.sh
+++ b/tests/mark-needs-audit.cases.sh
@@ -26,72 +26,72 @@ fi
 
 case_01() { # 기준선 — 프로젝트 안 코드는 게이트 4종, 값은 상대경로.
   local p; p="$(new_project)"
   mkfile "$p/src/app.ts"
   run_hook "$p" "$p/src/app.ts"
   check_case '01 프로젝트 안 소스 → 게이트 4종(상대경로)' 0 gate 'src/app.ts'
 }
 
 case_02() { # 순수 문서 제외.
   local p; p="$(new_project)"
   mkfile "$p/README.md"
   run_hook "$p" "$p/README.md"
   check_case '02 프로젝트 안 README.md → 스킵' 0 none ''
 }
 
 case_03() { # D3-5 대소문자 무관. 5단계 *.md 축의 대문자 쪽.
             # 같은 대소문자 축의 3단계(듀얼) 쪽은 케이스 55 가 잡는다.
   local p; p="$(new_project)"
   mkfile "$p/README.MD"
   run_hook "$p" "$p/README.MD"
   check_case '03 프로젝트 안 README.MD(대문자) → 스킵' 0 none ''
 }
 
 case_04() { # _workspace/ 는 스크래치 — 설계·계획 파일명이 아니면 아무 플래그도 안 선다.
   local p; p="$(new_project)"
   mkfile "$p/_workspace/notes.md"
   run_hook "$p" "$p/_workspace/notes.md"
   check_case '04 프로젝트 안 _workspace/notes.md → 스킵' 0 none ''
 }
 
-case_05() { # D2 설계 산출물 — 듀얼리뷰만. 기록값은 프로젝트 상대경로.
+case_05() { # D2 설계 산출물 — 듀얼리뷰+지식. 기록값은 프로젝트 상대경로.
   local p; p="$(new_project)"
   mkfile "$p/_workspace/00_design.md"
   run_hook "$p" "$p/_workspace/00_design.md"
-  check_case '05 프로젝트 안 설계 문서 → 듀얼리뷰만(상대경로)' 0 dual '_workspace/00_design.md'
+  check_case '05 프로젝트 안 설계 문서 → 듀얼리뷰+지식(상대경로)' 0 designdoc '_workspace/00_design.md'
 }
 
 case_06() { # D2 계획 산출물 — 01_plan 축.
   local p; p="$(new_project)"
   mkfile "$p/_workspace/01_plan.v2.md"
   run_hook "$p" "$p/_workspace/01_plan.v2.md"
-  check_case '06 프로젝트 안 계획 문서 → 듀얼리뷰만(상대경로)' 0 dual '_workspace/01_plan.v2.md'
+  check_case '06 프로젝트 안 계획 문서 → 듀얼리뷰+지식(상대경로)' 0 designdoc '_workspace/01_plan.v2.md'
 }
 
 case_07() { # 순서계약 (나) — .claude/* 제외가 하네스 앵커보다 **먼저**.
             # 먼저가 아니면 프로젝트에 설치된 소비 사본이 게이트를 세운다.
             # 같은 축: 케이스 24(정본 저장소가 자기 자신에 설치한 사본).
   local p; p="$(new_project)"
   mkfile "$p/.claude/settings.json"
   run_hook "$p" "$p/.claude/settings.json"
   check_case '07 설치된 글루 .claude/settings.json → 스킵' 0 none ''
 }
 
 case_08() { # 비블로킹 1 — 글롭 과대. 프로젝트 안의 평범한 src/agents/ 는 하네스가 아니다.
   local p; p="$(new_project)"
   mkfile "$p/src/agents/README.md"
   run_hook "$p" "$p/src/agents/README.md"
   check_case '08 프로젝트 안 src/agents/README.md → 스킵(오탐 금지)' 0 none ''
 }
 
 case_09() { # 비블로킹 1 — node_modules 안의 skills/*.md 도 하네스가 아니다.
   local p; p="$(new_project)"
   mkfile "$p/node_modules/p/skills/a.md"
   run_hook "$p" "$p/node_modules/p/skills/a.md"
   check_case '09 node_modules/*/skills/a.md → 스킵(오탐 금지)' 0 none ''
 }
 
 case_10() { # B2 정규화 — .. 로 .claude/ 를 빠져나온 경로. 정규화가 없으면 .claude/* 스킵에 먹힌다.
             # 같은 축: 케이스 11·12(심링크)·47(듀얼 쪽 .. 복귀). 픽스처 의존: mkfile 의
             # mkdir -p "$p/.claude/../src" 가 .. 앞 컴포넌트 .claude 를 실제로 만든다(실측 확인).
   local p; p="$(new_project)"
   mkfile "$p/.claude/../src/b.ts"
@@ -172,61 +172,61 @@ case_19() { # 앵커 harness — 제0원칙 정본.
   check_case '19 밖+정본 template/.claude/harness/*.md → 게이트 4종' 0 gate "$hr/template/.claude/harness/principles.md"
 }
 
 case_20() { # 앵커 settings.json — 확장자가 없는 앵커.
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkfile "$hr/template/.claude/settings.json"
   run_hook "$p" "$hr/template/.claude/settings.json"
   check_case '20 밖+정본 template/.claude/settings.json → 게이트 4종' 0 gate "$hr/template/.claude/settings.json"
 }
 
 case_21() { # 정본 저장소라도 순수 문서는 스킵 — 검사 범위가 무제한이 아님을 고정.
             # 비차별 — 5단계 *.md 스킵을 건드리는 변이는 케이스 02 에서 먼저 죽는다.
             # 이 행만의 몫은 "그 규칙이 4b-정본 스코프에도 그대로 적용된다"는 것뿐이다.
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkfile "$hr/docs/usage.md"
   run_hook "$p" "$hr/docs/usage.md"
   check_case '21 밖+정본 docs/usage.md → 스킵' 0 none ''
 }
 
 case_22() { # 정본 저장소의 _workspace/ 도 스크래치다.
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkfile "$hr/_workspace/scratch.md"
   run_hook "$p" "$hr/_workspace/scratch.md"
   check_case '22 밖+정본 _workspace/scratch.md → 스킵' 0 none ''
 }
 
 case_23() { # B1 본체 — 밖 설계 문서에도 듀얼리뷰 게이트가 선다. 같은 축: 케이스 34·35.
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkfile "$hr/_workspace/00_design.md"
   run_hook "$p" "$hr/_workspace/00_design.md"
-  check_case '23 밖+정본 _workspace/00_design.md → 듀얼리뷰만(절대경로)' 0 dual "$hr/_workspace/00_design.md"
+  check_case '23 밖+정본 _workspace/00_design.md → 듀얼리뷰+지식(절대경로)' 0 designdoc "$hr/_workspace/00_design.md"
 }
 
 case_24() { # 순서계약 (나) — 정본 저장소가 **자기 자신에 설치한** 소비 사본은 스킵.
             # 정본(template/.claude/...)만 발화해야 한다. 같은 축: 케이스 07.
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkfile "$hr/.claude/hooks/x.sh"
   run_hook "$p" "$hr/.claude/hooks/x.sh"
   check_case '24 밖+정본의 자기 설치 사본 .claude/hooks/x.sh → 스킵' 0 none ''
 }
 
 case_25() { # D3-3 — .git/ 아래 편집은 **상위 저장소**로 귀속시킨다. 그러지 않으면 git 이 .git
             # 안에서 --show-toplevel 에 실패해(실측 rc=128) 판정 불가로 조용히 새어나간다.
             # 같은 축의 음성 쪽은 케이스 36.
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkfile "$hr/.git/hooks/pre-commit"
   run_hook "$p" "$hr/.git/hooks/pre-commit"
   check_case '25 밖+정본 .git/hooks/pre-commit → 게이트 4종(상위 저장소 귀속)' 0 gate "$hr/.git/hooks/pre-commit"
 }
 
 case_26() { # D1′ — worktree 도 정본이다. 마커(template/.claude/)가 커밋 트리에 실제로
             # 담겨야 성립하므로 make_harness_repo 가 실파일을 커밋한다(--allow-empty 금지).
   local p hr wtp wt; p="$(new_project)"; hr="$(new_harness_repo)"
   wtp="$(new_dir wt)"
   wt="$wtp/tree"
   git -C "$hr" worktree add --detach "$wt" >/dev/null 2>&1
   if [ ! -d "$wt/template/.claude" ]; then
     fixture_broken 'worktree 에 template/.claude 가 없다 (실커밋이 비었나?)'
   else
     mkfile "$wt/scripts/check.sh"
     run_hook "$p" "$wt/scripts/check.sh"
@@ -278,68 +278,68 @@ case_31() { # D1 B3 역방향 — HOME 예외를 삭제했으므로 홈 아래 
   mkfile "$home/.claude/harness/principles.md"
   git -C "$home/.claude" init -q
   run_hook "$p" "$home/.claude/harness/principles.md" "HOME=$home"
   check_case '31 HOME 아래 .claude/harness/principles.md → 게이트 4종' 0 gate "$home/.claude/harness/principles.md"
 }
 
 case_32() { # D1 B3 순방향 — 홈 아래라도 하네스가 아니면 발화하지 않는다.
             # 케이스 31 과 짝. 둘이 같이 "홈이라서"가 아니라 "하네스라서" 발화함을 고정한다.
   local p home; p="$(new_project)"; home="$(new_dir home)"
   mkfile "$home/dotfiles/vimrc"
   git -C "$home/dotfiles" init -q
   run_hook "$p" "$home/dotfiles/vimrc" "HOME=$home"
   check_case '32 HOME 아래 dotfiles/vimrc → 스킵' 0 none ''
 }
 
 case_33() { # 저장소 밖 순수 임시 파일 — 발화하지 않는다.
             # 비차별 — 고정하는 계약은 "앵커도 정본도 아니면 밖은 건드리지 않는다".
             # 케이스 28·32 와 같은 축이고, 이 행만의 차별점은 git 저장소조차 아니라는 것.
             # 그래서 4b-else 를 겨냥한 변이는 여기 오기 전에 28·32 에서 죽는다.
   local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
   mkfile "$nogit/plain/file.ts"
   run_hook "$p" "$nogit/plain/file.ts"
   check_case '33 밖+git 아님 plain/file.ts → 스킵' 0 none ''
 }
 
 case_34() { # D2 본체 — **이 세션 형태**. _workspace/ 가 어느 git 저장소에도 속하지 않아도
             # 설계 문서 듀얼리뷰 게이트는 서야 한다. 같은 축: 케이스 23·35.
   local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
   mkfile "$nogit/_workspace/00_design.md"
   run_hook "$p" "$nogit/_workspace/00_design.md"
-  check_case '34 밖+git 아님 _workspace/00_design.md → 듀얼리뷰만(절대경로)' 0 dual "$nogit/_workspace/00_design.md"
+  check_case '34 밖+git 아님 _workspace/00_design.md → 듀얼리뷰+지식(절대경로)' 0 designdoc "$nogit/_workspace/00_design.md"
 }
 
 case_35() { # D2 — 01_plan 축.
   local p nogit; p="$(new_project)"; nogit="$(new_dir nogit)"
   mkfile "$nogit/_workspace/01_plan.md"
   run_hook "$p" "$nogit/_workspace/01_plan.md"
-  check_case '35 밖+git 아님 _workspace/01_plan.md → 듀얼리뷰만(절대경로)' 0 dual "$nogit/_workspace/01_plan.md"
+  check_case '35 밖+git 아님 _workspace/01_plan.md → 듀얼리뷰+지식(절대경로)' 0 designdoc "$nogit/_workspace/01_plan.md"
 }
 
 case_36() { # D3-3 의 음성 쪽 — .git/ 귀속이 "무조건 발화"가 되면 안 된다.
             # 상위 저장소가 하네스가 아니면 스킵. 케이스 25 와 짝.
   local p other; p="$(new_project)"; other="$(new_dir other)"
   git -C "$other" init -q
   mkfile "$other/.git/hooks/pre-commit"
   run_hook "$p" "$other/.git/hooks/pre-commit"
   check_case '36 밖+비정본 .git/hooks/pre-commit → 스킵' 0 none ''
 }
 
 case_37() { # 귀속은 **가장 안쪽** 저장소. 정본 안에 박힌 남의 저장소는 정본이 아니다.
             # 케이스 27(안쪽이 정본)과 대칭.
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkdir -p "$hr/vendor/inner"
   git -C "$hr/vendor/inner" init -q
   mkfile "$hr/vendor/inner/x.sh"
   run_hook "$p" "$hr/vendor/inner/x.sh"
   check_case '37 정본 안의 중첩 비정본 저장소 x.sh → 스킵' 0 none ''
 }
 
 # === D. 환경·실패 경로 (모든 행 rc=0 — PostToolUse 는 절대 차단하지 않는다) ===
 case_38() { # 비블로킹 2 — GIT_DIR/GIT_WORK_TREE 오염 소거.
             # 오염이 살아 있으면 귀속 저장소가 $other 로 바뀌어 조용히 스킵된다.
   local p hr other; p="$(new_project)"; hr="$(new_harness_repo)"; other="$(new_dir other)"
   git -C "$other" init -q
   mkfile "$hr/scripts/check.sh"
   run_hook "$p" "$hr/scripts/check.sh" "GIT_DIR=$other/.git" "GIT_WORK_TREE=$other"
   check_case '38 GIT_DIR/GIT_WORK_TREE 오염 하 정본 편집 → 게이트 4종' 0 gate "$hr/scripts/check.sh"
 }
@@ -401,70 +401,70 @@ case_44() { # 탈출구 ECC_DISABLED_HOOKS — 훅 id 단위.
             # 비차별 — 고정하는 계약은 id 별 비활성이 이 훅에 걸린다는 것.
   local p; p="$(new_project)"
   mkfile "$p/src/app.ts"
   run_hook "$p" "$p/src/app.ts" ECC_DISABLED_HOOKS=post:edit:needs-audit
   check_case '44 ECC_DISABLED_HOOKS=post:edit:needs-audit → 무변화' 0 none ''
 }
 
 case_45() { # 개행 축의 기준선 — basename 안의 **중간** 개행. 확장자를 .ts 로 두는 이유:
             # 가드가 없으면 게이트가 서는 경로여야 "플래그가 2줄로 쪼개져 오염된다"가 드러난다.
             # 이 행은 순서계약 (라)를 **못** 붙든다(실측 정정): basename 안의 개행은 명령
             # 치환·정규화를 통과해 살아남으므로 가드를 정규화 뒤로 옮겨도 여전히 잡힌다.
             # (라)를 실제로 붙드는 것은 케이스 57(디렉토리 컴포넌트 개행)이고,
             # 값 획득 시점의 개행 소실은 케이스 56(후행 개행)이 붙든다.
   local p fp; p="$(new_project)"
   fp="$p/src/we
 ird.ts"
   mkfile "$fp"
   run_hook "$p" "$fp"
   check_case '45 경로 중간에 개행 → 무기록 + systemMessage 1줄' 0 none '' "$TOK_NEWLINE"
 }
 
 # === E. 2차 검증에서 추가된 행 ============================================
 
 case_46() { # 순서계약 (가) — 듀얼 판정은 정규화 **뒤**.
             # 상대 입력에는 선행 / 가 없어 */_workspace/... 글롭에 안 걸린다.
             # 정규화를 지우면 이 행이 스킵으로 무너진다. 같은 축의 값 쪽: 케이스 47.
             # 비차별 — 고정하는 계약은 "듀얼 판정 전에 절대화한다".
   local p; p="$(new_project)"
   mkfile "$p/_workspace/01_plan.md"
   run_hook "$p" '_workspace/01_plan.md'
-  check_case '46 상대경로 입력 _workspace/01_plan.md → 듀얼리뷰만' 0 dual '_workspace/01_plan.md'
+  check_case '46 상대경로 입력 _workspace/01_plan.md → 듀얼리뷰+지식' 0 designdoc '_workspace/01_plan.md'
 }
 
 case_47() { # 순서계약 (가) — 기록값 축. 듀얼 판정을 정규화 앞으로 되돌리면 판정은 살아도
             # 기록값이 .claude/../_workspace/00_design.md 가 되어 여기서 잡힌다. 픽스처 의존:
             # mkdir -p "$p/.claude/../_workspace" 가 .. 앞 컴포넌트 .claude 를 만든다(실측 확인).
   local p; p="$(new_project)"
   mkfile "$p/.claude/../_workspace/00_design.md"
   run_hook "$p" "$p/.claude/../_workspace/00_design.md"
-  check_case '47 .claude/../_workspace/00_design.md → 듀얼리뷰만(정규화된 값)' 0 dual '_workspace/00_design.md'
+  check_case '47 .claude/../_workspace/00_design.md → 듀얼리뷰+지식(정규화된 값)' 0 designdoc '_workspace/00_design.md'
 }
 
 case_48() { # H1 — global-agents/ 는 전역 에이전트 **정본**이고 install/sync 가 배포한다.
             # 정본 저장소 스코프 안에서만 .md 예외의 예외를 연다. 경계는 케이스 49 가 고정.
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkfile "$hr/global-agents/research-collector.md"
   run_hook "$p" "$hr/global-agents/research-collector.md"
   check_case '48 밖+정본 global-agents/*.md → 게이트 4종(절대경로)' 0 gate "$hr/global-agents/research-collector.md"
 }
 
 case_49() { # H1 경계 — 정본이 아닌 프로젝트의 global-agents/ 는 그냥 문서다. 이 행이 없으면
             # 예외가 남의 프로젝트로 샌다. 비차별 — 계약은 "예외는 정본 스코프 한정".
   local p; p="$(new_project)"
   mkfile "$p/global-agents/x.md"
   run_hook "$p" "$p/global-agents/x.md"
   check_case '49 비정본 프로젝트의 global-agents/x.md → 스킵' 0 none ''
 }
 
 case_50() { # H1 — CLAUDE_PROJECT_DIR 자신이 정본인 경우. 프로젝트 안 경로(4a)와 밖-정본
             # 경로(4b)의 스코프가 **같은 규칙**인지 고정한다. 안 경로이므로 기록값은 상대경로.
   local pc; pc="$(new_harness_repo)"
   mkfile "$pc/global-agents/x.md"
   run_hook "$pc" "$pc/global-agents/x.md"
   check_case '50 PROJECT_DIR 자신이 정본 + global-agents/x.md → 게이트 4종(상대경로)' 0 gate 'global-agents/x.md'
 }
 
 case_51() { # M1 — physical_path 실패는 fail-loud. 스킵하지 않고 원본 경로로 판정을 잇는다.
             # **픽스처 기본계약 2의 유일한 예외**: 부모 디렉토리를 일부러 만들지 않는다.
             # 소음도 없다(stdout 공백). 비차별 — 계약은 "정규화 실패 시 조용히 스킵 금지".
   local p; p="$(new_project)"
@@ -474,61 +474,61 @@ case_51() { # M1 — physical_path 실패는 fail-loud. 스킵하지 않고 원
 
 case_52() { # M5 — 접두사 판정에 슬래시가 빠지면 형제 디렉토리를 프로젝트 안으로 오인해
             # 기록값이 -backup/src/a.ts 가 된다. 비차별 — 계약은 "접두사는 <proj>/ 로 본다".
   local p; p="$(new_project)"
   mkfile "${p}-backup/src/a.ts"
   run_hook "$p" "${p}-backup/src/a.ts"
   check_case '52 형제 디렉토리 <proj>-backup/src/a.ts → 스킵' 0 none ''
 }
 
 case_53() { # M6 — 값이 - 로 시작하면 grep 이 옵션으로 해석한다.
             # -- 가 없으면 grep -qxF --version 이 되어 rc=0(=이미 있음)로 미기록이 되고,
             # BSD grep 은 -q 아래서도 버전 문자열을 stdout 에 뱉는다(실측). 두 축에서 잡힌다.
   local p; p="$(new_project)"
   mkfile "$p/--version"
   run_hook "$p" "$p/--version"
   check_case '53 파일명이 --version → 게이트 4종, stdout 공백' 0 gate '--version'
 }
 
 case_54() { # H2 — HOME 재도입 금지를 정적으로 고정한다. 런타임 쪽은 케이스 39. 변수 **참조**만
             # 금지한다: 산문 주석의 HOME 은 허용해야 홈 예외 삭제 사유를 주석으로 쓸 수 있다.
   run_static_check '훅 본문이 HOME 변수를 참조한다 (홈 예외는 삭제됐다)' '\$\{?HOME'
   check_case '54 정적: 훅이 HOME 변수를 참조하지 않는다' 0 none ''
 }
 
 case_55() { # 3단계 대소문자 축 — 듀얼 매칭은 소문자화해 비교하되 **기록은 원본 대소문자**로.
             # 소문자화를 빼도 05·06·23·34·35·46·47 이 전부 통과해 계약이 무방비가 된다.
             # 5단계 쪽 대소문자 축은 케이스 03 이 잡는다.
   local p; p="$(new_project)"
   mkfile "$p/_workspace/00_Design.md"
   run_hook "$p" "$p/_workspace/00_Design.md"
-  check_case '55 _workspace/00_Design.md(대문자) → 듀얼리뷰만(원본 대소문자로 기록)' 0 dual '_workspace/00_Design.md'
+  check_case '55 _workspace/00_Design.md(대문자) → 듀얼리뷰+지식(원본 대소문자로 기록)' 0 designdoc '_workspace/00_Design.md'
 }
 
 # === F. 3중 검수에서 추가된 행 ============================================
 # 전부 "변이가 살아남았다"는 실측에서 나왔다 — 즉 이 행들이 없으면 해당 계약을
 # 지우거나 완화해도 나머지 전 행이 초록이다.
 
 case_56() { # 개행 축 — **후행** 개행. json_get 은 print() 로 내고 훅은 그 결과를 받는데,
             # 명령 치환은 후행 개행을 **전부** 지운다. 그래서 가드에 닿기도 전에 값이
             # src/app.ts 로 조용히 변조돼 **다른 파일**이 게이트에 박힌다. 훅이 센티널로
             # 받아 원본 개행을 보존해야만 초록이 된다. 같은 축: 케이스 45·57.
   local p; p="$(new_project)"
   mkfile "$p/src/app.ts"
   run_hook "$p" "$p/src/app.ts
 "
   check_case '56 경로 끝에 개행 → 무기록 + systemMessage 1줄' 0 none '' "$TOK_NEWLINE"
 }
 
 case_57() { # 순서계약 (라)를 **실제로** 붙드는 행 — 디렉토리 컴포넌트가 개행으로 끝난다.
             # 가드를 정규화 뒤로 옮기면 pwd -P 출력의 후행 개행이 명령 치환에 먹혀 abs 가
             # $PROJ/sr/app.ts 로 조용히 바뀐다 → 존재하지 않는 파일이 게이트에 박히고
             # 정작 편집한 파일은 무게이트. 케이스 45 는 이 변이를 못 잡는다(그 주석 참조).
   local p fp; p="$(new_project)"
   fp="$p/sr
 /app.ts"
   mkfile "$fp"
   run_hook "$p" "$fp"
   check_case '57 디렉토리 컴포넌트 끝 개행 → 무기록 + systemMessage 1줄' 0 none '' "$TOK_NEWLINE"
 }
 
 case_58() { # 플래그 **누적**과 grep -qxF 의 -x 를 한 행으로 붙든다. 값 두 개를 부분 문자열
@@ -623,61 +623,61 @@ case_64() { # **기존 동작의 명문화 — 이번 변경이 만든 게 아
             # 필수인데, 그 패턴이 프로젝트 안 깊은 곳의 .claude/ 도 같이 잡는다.
             # 반면 classify 의 .claude/* 제외는 rel **선두**에만 걸린다.
             # → 최상위 .claude/ 는 스킵(케이스 07), 모노레포 하위 .claude/ 는 발화.
             #
             # 이번 작업의 범위는 검사 범위 재작성이었고, 이 비대칭은 **바꾸지 않기로** 했다.
             # 고치는 것(하위 .claude/ 도 스킵)은 범위 밖 동작 변경이라 별건이다.
             # 이 행은 "봤고 안 건드렸다"는 기록이다 — 없으면 다음 사람이 이 비대칭을
             # 의도인지 사고인지 구분할 수 없다. 피해 방향은 오탐이고 탈출구가 있다.
   local p; p="$(new_project)"
   mkfile "$p/packages/app/.claude/hooks/x.sh"
   run_hook "$p" "$p/packages/app/.claude/hooks/x.sh"
   check_case '64 모노레포 하위 .claude/hooks/x.sh → 게이트 4종(기존 동작, 범위 밖)' 0 gate 'packages/app/.claude/hooks/x.sh'
 }
 
 case_65() { # 확장자 축의 .markdown 쪽. *.md|*.markdown 을 *.md 로 좁혀도 나머지 전 행이
             # 초록이었다 — README.markdown 오탐을 아무도 안 잡는다. 대소문자 축은 케이스 03.
             # 비차별(a·b 양판 GREEN) — 두 구판도 *.markdown 을 스킵했다.
   local p; p="$(new_project)"
   mkfile "$p/README.markdown"
   run_hook "$p" "$p/README.markdown"
   check_case '65 프로젝트 안 README.markdown → 스킵' 0 none ''
 }
 
 case_66() { # 듀얼 글롭의 접미사 축 — 00_design* 쪽. 케이스 06 이 01_plan.v2.md 로 01 축만
             # 덮고 있어, 00_design*.md 를 00_design.md 로 좁혀도 안 죽었다. 좁히면 이 행이
             # 듀얼이 아니라 _workspace/* 스킵으로 무너진다.
             # 비차별(a·b 양판 GREEN) — 두 구판도 00_design* 글롭을 갖고 있었다.
   local p; p="$(new_project)"
   mkfile "$p/_workspace/00_design.v2.md"
   run_hook "$p" "$p/_workspace/00_design.v2.md"
-  check_case '66 프로젝트 안 _workspace/00_design.v2.md → 듀얼리뷰만' 0 dual '_workspace/00_design.v2.md'
+  check_case '66 프로젝트 안 _workspace/00_design.v2.md → 듀얼리뷰+지식' 0 designdoc '_workspace/00_design.v2.md'
 }
 
 # === G. PR 점검(C1)에서 추가된 행 — 물리 경로 정규화 축 ====================
 # 전부 physical_path 를 겨냥한다. 케이스 10·11·12 는 이 축을 **부분만** 덮고 있었다:
 #   10 — `..` 가 있지만 심링크가 없다 → 논리 cd 로도 답이 같다
 #   11·12 — 심링크가 있지만 `..` 가 없다 → 논리 cd 로도 답이 같다
 # 논리 cd 와 물리 cd 가 갈리는 지점은 **둘이 겹칠 때**뿐이다: 논리 cd 는 `심링크/..` 를
 # 심링크를 따라가기 **전에** 문자로 상쇄하므로 커널이 실제로 여는 곳과 다른 답을 낸다
 # (실측: `cd -- /var/..` → `/`, `cd -P -- /var/..` → `/private`).
 # 마지막 성분이 `.`·`..` 인 축(69·70)은 형제 검사기 scripts/check-rule-copies.sh 가
 # PR #13 에서 이미 고친 같은 이름의 버그다 — 두 함수가 같은 방식이어야 한다.
 #
 # 픽스처 기본계약 1의 예외: 이 두 행(67·68)은 심링크를 **의도적으로** 만든다.
 
 case_67() { # `심링크/..` 로 프로젝트를 빠져나간 편집 — 밖 파일이 **안 상대경로로 기록**되면 안 된다.
             # 링크가 프로젝트 밖을 가리키므로 물리 해석은 $outside/secret.ts(=밖)이고,
             # 논리 해석은 $p/secret.ts(=안)다. `-P` 가 빠지면 후자가 되어 게이트는 서지만
             # **존재하지도 않는 프로젝트 안 파일** secret.ts 가 박힌다 — 감사자가 엉뚱한
             # 파일을 보고 통과시키는 조용한 위양성. 에러도 stderr 도 없다.
             # 값 축(밖인데 무게이트가 되는 반대 방향)은 케이스 68.
   local p outside; p="$(new_project)"; outside="$(new_dir outside)"
   mkdir -p "$outside/target"
   mkfile "$outside/secret.ts"
   ln -s "$outside/target" "$p/link"
   run_hook "$p" "$p/link/../secret.ts"
   check_case '67 프로젝트 밖을 가리키는 심링크/.. 편집 → 스킵(안 상대경로로 오기록 금지)' 0 none ''
 }
 
 case_68() { # 케이스 67 의 반대 방향 — 물리 해석이 밖 **하네스 앵커**를 가리킨다.
             # 논리 해석은 $p/agents/x.md 로 접혀 프로젝트 안의 평범한 문서(5단계 *.md)가
@@ -693,43 +693,71 @@ case_68() { # 케이스 67 의 반대 방향 — 물리 해석이 밖 **하네
   ln -s "$nogit/.claude/agents" "$p/link"
   run_hook "$p" "$p/link/../agents/x.md"
   check_case '68 심링크/.. 로 밖 하네스 앵커 → 게이트 4종(절대경로)' 0 gate "$nogit/.claude/agents/x.md"
 }
 
 case_69() { # 마지막 성분이 `..` — 호출부가 dirname/basename 으로 쪼개 넘기면 `..` 는
             # basename 쪽으로 가고 basename 은 물리화되지 않아 **안 풀린 채** 남는다.
             # 그러면 프로젝트 루트 자신을 가리키는 경로가 상대경로 `src/..` 로 접두사에
             # 걸려 게이트가 서고, 플래그에 디렉토리 표기가 박힌다. 정규화하면 $p 자신이라
             # 접두사(<proj>/)에 안 걸려 밖으로 떨어지고, 앵커도 정본도 아니므로 스킵이다.
             # **픽스처 기본계약 2의 예외**: 편집 경로가 디렉토리라 파일을 만들지 않는다.
             # mkdir 이 실패해도 조용히 초록이 되지 않는다 — cd 가 실패하면 원본이 그대로
             # 나와 `src/..` 게이트가 서므로 이 행이 빨개진다(fail-closed).
             # `.` 쪽 거울상은 케이스 70.
   local p; p="$(new_project)"
   mkdir -p "$p/src"
   run_hook "$p" "$p/src/.."
   check_case '69 마지막 성분이 .. → 스킵(정규화하면 프로젝트 루트 자신)' 0 none ''
 }
 
 case_70() { # 케이스 69 의 `.` 쪽 거울상 — 판정이 아니라 **기록값**에서 갈린다.
             # `.` 는 경로를 옮기지 않으므로 안/밖은 그대로지만, 안 풀리면 플래그에
             # `src/.` 가 박혀 같은 디렉토리의 다른 표기와 중복 제거되지 않는다.
             # 69 를 `..` 만 풀어서 고치면 이 행이 혼자 빨개진다(PR #13 케이스 43 과 같은 구조).
   local p; p="$(new_project)"
   mkdir -p "$p/src"
   run_hook "$p" "$p/src/."
   check_case '70 마지막 성분이 . → 게이트 4종(정규화된 값 src)' 0 gate 'src'
 }
 
+case_71() { # 결정 문서는 문서 제외의 **예외** — 지식 게이트 하나만.
+            # 하네스가 스스로 "결정은 이 경로에 이 이름으로 쓴다"고 규정했으므로
+            # 하네스가 아는 산출물이고, 그 자리가 편집됐다는 것은 결정이 나왔다는 뜻이다.
+            # 코드가 아니므로 타입체크·변경설명·감사는 과하다.
+  local p; p="$(new_project)"
+  mkfile "$p/docs/decisions/2026-08-10-something.md"
+  run_hook "$p" "$p/docs/decisions/2026-08-10-something.md"
+  check_case '71 결정 문서 → 지식 게이트만' 0 knowledge 'docs/decisions/2026-08-10-something.md'
+}
+
+case_72() { # 대문자 확장자도 결정 문서다 — 확장자 판정은 소문자화해서 본다.
+            # 이 행이 없으면 `.MD` 로 저장한 결정 문서가 게이트 없이 새어나간다.
+            # 기록은 **원본 대소문자**로 한다(매칭만 소문자화).
+  local p; p="$(new_project)"
+  mkfile "$p/docs/decisions/2026-08-10-upper.MD"
+  run_hook "$p" "$p/docs/decisions/2026-08-10-upper.MD"
+  check_case '72 결정 문서(대문자 확장자) → 지식 게이트만(원본 대소문자로 기록)' 0 knowledge 'docs/decisions/2026-08-10-upper.MD'
+}
+
+case_73() { # **음성 행** — 결정 경로 밖의 문서는 여전히 스킵이다.
+            # 이 행이 없으면 예외를 `docs/*.md` 로 넓혀도 초록이라, 문서 전체가 지식
+            # 게이트를 세우는 오탐이 조용히 들어온다. 지금 읽고 있는 usage.md 가 그 예다.
+  local p; p="$(new_project)"
+  mkfile "$p/docs/usage.md"
+  run_hook "$p" "$p/docs/usage.md"
+  check_case '73 결정 경로 밖의 문서는 스킵 (예외가 문서 전체로 새지 않는다)' 0 none ''
+}
+
 # --- 계약 표의 크기 -------------------------------------------------------
 # 러너가 이 두 값으로 "케이스가 조용히 빠지거나 두 번 도는 것"을 잡는다.
 # 건수는 여기 말고 어디에도 숫자로 적지 않는다 — 케이스를 추가할 때마다 낡는다.
 
-EXPECTED_CASES=70
+EXPECTED_CASES=73
 
 CASES='case_01 case_02 case_03 case_04 case_05 case_06 case_07 case_08 case_09 case_10 case_11
        case_12 case_13 case_14 case_15 case_16 case_17 case_18 case_19 case_20 case_21 case_22
        case_23 case_24 case_25 case_26 case_27 case_28 case_29 case_30 case_31 case_32 case_33
        case_34 case_35 case_36 case_37 case_38 case_39 case_40 case_41 case_42 case_43 case_44
        case_45 case_46 case_47 case_48 case_49 case_50 case_51 case_52 case_53 case_54 case_55
        case_56 case_57 case_58 case_59 case_60 case_61 case_62 case_63 case_64 case_65 case_66
-       case_67 case_68 case_69 case_70'
+       case_67 case_68 case_69 case_70 case_71 case_72 case_73'
diff --git a/tests/mark-needs-audit.test.sh b/tests/mark-needs-audit.test.sh
index 330a98b..23e88e3 100755
--- a/tests/mark-needs-audit.test.sh
+++ b/tests/mark-needs-audit.test.sh
@@ -40,61 +40,61 @@ REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
 HOOK="$REPO_ROOT/template/.claude/hooks/mark-needs-audit.sh"
 COMMON="$REPO_ROOT/template/.claude/hooks/_common.sh"
 
 command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (훅의 json_get 의존)" >&2; exit 1; }
 command -v git     >/dev/null 2>&1 || { echo "✗ git 이 필요합니다 (저장소 귀속 판정 픽스처)" >&2; exit 1; }
 [ -f "$HOOK" ]   || { echo "✗ 훅을 찾지 못했습니다: $HOOK" >&2; exit 1; }
 [ -f "$COMMON" ] || { echo "✗ _common.sh 를 찾지 못했습니다: $COMMON" >&2; exit 1; }
 
 # mktemp 실패를 확인하지 않으면 TMPROOT 가 빈 문자열이 되고, 이후 경로 조립이
 # 전부 "/..." 즉 **파일시스템 루트**를 가리킨다.
 TMPROOT="$(mktemp -d)" || exit 1
 if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
   echo "✗ 임시 디렉토리를 만들지 못했습니다 (TMPDIR 쓰기 권한 확인)" >&2
   exit 1
 fi
 # 픽스처 기본계약 1: 모든 픽스처 경로는 물리 경로다. macOS mktemp -d 는 /var/folders/...
 # (→ /private/var/... 심링크)를 돌려주므로, 정규화하지 않으면 정상 행이 전부 의도치 않은
 # 심링크 축이 된다. 심링크는 케이스 11·12 전용 헬퍼(new_symlinked_project)와 케이스 67·68
 # 에서만 **의도적으로** 도입한다 — 67·68 은 프로젝트 **안**에서 밖을 가리키는 링크라
 # 모양이 달라 헬퍼를 공유하지 않고 각 케이스 안에서 만든다.
 TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
 # chmod 는 케이스 40 이 .claude 를 읽기전용으로 만들기 때문에 필요하다.
 trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT
 
 # --- 문구 조각 ------------------------------------------------------------
 # 훅 문구가 다듬어져도 계약이 살아 있으면 계속 맞는 최소 조각.
 TOK_WRITE_FAIL='게이트 플래그를 기록하지 못했다'
 TOK_NEWLINE='편집 경로에 개행이 있어'
 TOK_GIT_UNAVAILABLE='git 이 저장소 정보를 돌려주지 못해'
 
-FLAG_NAMES='.needs-audit .needs-explain .needs-vault .needs-dualreview'
+FLAG_NAMES='.needs-audit .needs-explain .needs-knowledge .needs-dualreview'
 
 # --- 픽스처 조립 ----------------------------------------------------------
 
 # new_dir <접두사> — TMPROOT 아래 픽스처 디렉토리를 만들고 **물리 경로**를 낸다.
 new_dir() {
   local d
   d="$(mktemp -d "$TMPROOT/$1.XXXXXX")" || exit 1
   if [ -z "$d" ] || [ ! -d "$d" ]; then
     echo "✗ 케이스용 임시 디렉토리를 만들지 못했습니다" >&2
     exit 1
   fi
   ( CDPATH='' cd -- "$d" && pwd -P )
 }
 
 # new_project — 가짜 프로젝트. 훅과 _common.sh 를 **둘 다** 설치한다
 # (훅이 dirname "$BASH_SOURCE"/_common.sh 를 source 하므로 하나만 두면 못 돈다).
 new_project() {
   local p
   p="$(new_dir proj)"
   mkdir -p "$p/.claude/hooks"
   cp "$HOOK"   "$p/.claude/hooks/mark-needs-audit.sh"
   cp "$COMMON" "$p/.claude/hooks/_common.sh"
   printf '%s\n' "$p"
 }
 
 # make_harness_repo <디렉토리> — 하네스 정본 저장소 구조를 만들고 **실커밋**한다.
 # --allow-empty 를 쓰지 않는다: git 은 빈 디렉토리를 추적하지 않으므로 template/.claude/ 아래에
 # 실파일이 없으면 worktree(케이스 26)에서 정본 마커가 거짓이 된다 — 올바른 구현인데도 빨개진다.
 make_harness_repo() {
   local r="$1"
@@ -222,69 +222,75 @@ $hits"
   fi
 }
 
 # 픽스처를 이 환경에서 만들 수 없을 때. 조용히 넘어가지 않고 실패로 남긴다.
 fixture_broken() {
   OUT="픽스처 구성 실패: $1"
   ERR=''
   RC=-1
   STATE="$EMPTY_STATE"
   DID_RUN=1
 }
 
 ran=0
 pass=0
 fail=0
 
 # flag_bytes <플래그이름> — 플래그 파일 내용을 **바이트 그대로** FLAG_BYTES 에 담는다.
 # stdout 으로 돌려주지 않는 이유: 호출자의 명령 치환이 후행 개행을 지워버려 "값 한 줄"과
 # "두 줄이었는데 덮어써진 것"·"개행이 섞여 들어간 것"이 구분되지 않는다. 센티널 X 를
 # 붙여 받고 도로 떼면 바이트가 보존된다. 파일이 없으면 빈 문자열.
 FLAG_BYTES=''
 flag_bytes() {

2026-08-10T03:52:01.162567Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "rg -n 'needs-vault|VAULT_FLAG|stop:vault|듀얼리뷰만|dualreview only|HARNESS_KNOWLEDGE_GATE|knowledge' template docs install.sh sync.sh scripts tests .github/workflows/check-rules.yml | sed -n '1,520p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
sync.sh:81:   && ! grep -qE '^(export[[:space:]]+)?HARNESS_KNOWLEDGE_GATE=' "$DST/harness/harness.env" 2>/dev/null; then
sync.sh:82:  echo "   [슬롯 키 추가] harness/harness.env ← HARNESS_KNOWLEDGE_GATE (기본 켜짐, 기존 값 보존)"
sync.sh:109:  if { printf '\n# 지식 반영 게이트 (하네스가 나중에 추가한 슬롯). 끄려면 값을 비운다 —\n# "off" 라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다. 이 줄이 없어도 켜짐이다.\nHARNESS_KNOWLEDGE_GATE="on"\n' >> "$envf"; } 2>/dev/null \
sync.sh:110:     && grep -qE '^HARNESS_KNOWLEDGE_GATE=' "$envf" 2>/dev/null; then
sync.sh:111:    echo "   슬롯 키 추가 ✓  harness/harness.env  HARNESS_KNOWLEDGE_GATE=\"on\""
sync.sh:113:    echo "   ⚠ harness/harness.env 에 HARNESS_KNOWLEDGE_GATE 를 추가하지 못했습니다(권한·디스크)." >&2
tests/mark-needs-audit.test.sh:70:FLAG_NAMES='.needs-audit .needs-explain .needs-knowledge .needs-dualreview'
tests/mark-needs-audit.test.sh:253:# designdoc = .needs-dualreview + .needs-knowledge (설계·계획 산출물)
tests/mark-needs-audit.test.sh:254:# knowledge = .needs-knowledge 만 (결정 문서 — 코드가 아니라 게이트 4종은 과하다)
tests/mark-needs-audit.test.sh:264:          .needs-dualreview|.needs-knowledge) want="$value"$'\n' ;;
tests/mark-needs-audit.test.sh:266:      knowledge) [ "$f" = '.needs-knowledge' ] && want="$value"$'\n' ;;
template/CLAUDE.md.snippet:13:**지식 저장소 연결은 사용자 층에 있다:** 하네스가 아는 것은 계약 하나뿐이다 — *"지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다."* **어디에 어떤 구조로 반영하는지는 하네스가 모르고, 알아서도 안 된다.** 그 답은 **전역 `CLAUDE.md`(사용자 층)** 이 갖는다 — 거기에 없으면 이 게이트는 무엇을 하라는 건지 알 수 없는 요구가 된다. 지식 저장소를 쓰지 않는 환경이면 `.claude/harness/harness.env` 의 `HARNESS_KNOWLEDGE_GATE` 를 **비워서** 끈다(기본 켜짐, `"off"` 는 켜진 것으로 읽힌다).
install.sh:140:  echo "                                                 (HARNESS_KNOWLEDGE_GATE 는 기본 켜짐)"
scripts/check-layer-boundary.sh:66:needs-vault	구현체 이름이 붙은 플래그. 계약 이름(.needs-knowledge)을 써라
docs/decisions/2026-08-06-knowledge-retrieval-policy.md:26:2. **하네스는 진입점 너머를 모른다는 계약을 유지한다.** 회수 정책을 정할 때도 이 선을 넘지 않는다 — 넘는 순간 [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md)이 무효가 된다
docs/decisions/2026-08-06-knowledge-retrieval-policy.md:68:- [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md) — 층 경계(넘지 말아야 할 선)
docs/decisions/2026-08-06-knowledge-retrieval-policy.md:69:- [ADR-0008](2026-08-06-knowledge-gate-default-on.md) — 반영(쓰기) 쪽 게이트
tests/check-layer-boundary.test.sh:52:  printf '%s\n' '완료 게이트 4종을 세운다. .needs-knowledge 는 계약 이름이다.' \
tests/check-layer-boundary.test.sh:54:  printf '%s\n' 'HARNESS_KNOWLEDGE_GATE="on"' > "$d/.claude/harness.env"
tests/check-layer-boundary.test.sh:109:c09() { leak_case '구현체 이름 플래그 — needs-vault' 'rm -f .claude/.needs-vault'     'needs-vault'; }
docs/decisions/2026-08-06-profile-canon-upstream.md:21:하네스는 배포본이 놓일 **자리만** 제공한다 — `install.sh` 가 슬롯으로 스캐폴드하고 `sync.sh` 는 절대 덮지 않는다. 정본을 어디에 어떤 이름으로 두는지는 **하네스의 관심사가 아니다.** [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md)의 층 계약 그대로이고, [ADR-0002](2026-07-20-global-agents-layer.md)가 전역 에이전트에 대해 같은 패턴을 이미 풀었다.
docs/decisions/2026-08-06-profile-canon-upstream.md:48:- **Why not**: 지금은 **착수 전 1회**로 좁힌다. 이 좁힘이 옳은지는 [ADR-0010](2026-08-06-knowledge-retrieval-policy.md)의 열린 질문이다
docs/decisions/2026-08-06-profile-canon-upstream.md:71:- [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md) — 층 경계
docs/decisions/2026-08-06-profile-canon-upstream.md:72:- [ADR-0008](2026-08-06-knowledge-gate-default-on.md) — 게이트 판독
docs/decisions/2026-08-06-profile-canon-upstream.md:73:- [ADR-0010](2026-08-06-knowledge-retrieval-policy.md) — 배관은 깔렸고 정책은 아직 없다
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:29:| `template/.claude/hooks/mark-needs-audit.sh` | `.needs-vault` |
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:30:| `template/.claude/hooks/verify-before-stop.sh` | `.needs-vault` |
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:31:| `template/.claude/hooks/_common.sh` | `.needs-vault` |
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:59:HARNESS_KNOWLEDGE_GATE=""
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:64:플래그 이름도 계약 수준으로 올린다: `.needs-vault` → `.needs-knowledge`.
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:103:- 금지 목록: 볼트 경로 · `second brain` · `_CLAUDE.md` · `4종 세트` · `Projects/<name>/` · `needs-vault`
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:111:`refactor/knowledge-store-layer` 에서 이행했다.
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:114:- **플래그 개명**: `.needs-vault` → `.needs-knowledge`
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:115:- **슬롯 신설**: `harness.env` 의 `HARNESS_KNOWLEDGE_GATE`. 판독 규칙과 기본값은 [ADR-0008](2026-08-06-knowledge-gate-default-on.md) 로 갈라졌다 — 이 ADR의 *"슬롯을 비우면 생략"* 관용구를 **일부 supersede** 한다. 기존 설치본에 키가 없으므로 "없음 = 꺼짐"이면 업그레이드가 게이트를 조용히 끈다. 그래서 **없으면 켜짐**이다
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:118:- **조회 방향**: 이행 중에 프로필 정본 위치 문제가 갈라져 나와 [ADR-0009](2026-08-06-profile-canon-upstream.md) 가 됐고, 회수 **정책**은 미설계로 [ADR-0010](2026-08-06-knowledge-retrieval-policy.md) 에 못박았다
docs/decisions/2026-08-06-knowledge-gate-default-on.md:11:[ADR-0006](2026-08-05-knowledge-store-layer-boundary.md)이 지식 반영 게이트를 껐다 켤 수 있게 만들라고 했다. **스위치를 어디에 두고 어떻게 읽을지**가 이 ADR이다.
docs/decisions/2026-08-06-knowledge-gate-default-on.md:46:`sync.sh` 는 키가 없는 설치본에 `HARNESS_KNOWLEDGE_GATE="on"` 을 **덧붙이기만** 한다 — 동작은 어차피 같지만, 파일에 한 줄도 없으면 사용자가 그런 스위치가 있다는 것 자체를 모른다.
docs/decisions/2026-08-06-knowledge-gate-default-on.md:119:- [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md) — 층 경계(이 스위치가 필요한 이유)
docs/decisions/2026-08-06-knowledge-gate-default-on.md:121:- [ADR-0010](2026-08-06-knowledge-retrieval-policy.md) — 회수 정책은 아직 없다
tests/harness-env-read.test.sh:65:GKEY='HARNESS_KNOWLEDGE_GATE'
tests/harness-env-read.test.sh:129:# run_knowledge_probe <proj> — **지식 플래그 하나만** 세우고 Stop 훅을 돌린다.
tests/harness-env-read.test.sh:135:run_knowledge_probe() {
tests/harness-env-read.test.sh:139:  printf 'gate-target.ts\n' > "$proj/.claude/.needs-knowledge"
tests/harness-env-read.test.sh:200:  run_knowledge_probe "$proj"
docs/decisions/2026-08-06-gate-scope-by-file-identity.md:9:완료 게이트(`.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)를 세우는
docs/usage.md:28:2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략) · `HARNESS_KNOWLEDGE_GATE` (지식 저장소 반영 게이트. **기본 켜짐**이고, 끄는 방법은 **값을 비우는 것 하나뿐**이다 — `"off"`라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다).
docs/usage.md:65:| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (설계·계획 산출물은 듀얼리뷰 플래그만, 코드는 4종 전부). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
docs/usage.md:70:**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
docs/usage.md:90:- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 지식 저장소 반영(`.needs-knowledge`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
tests/mark-needs-audit.cases.sh:730:  check_case '71 결정 문서 → 지식 게이트만' 0 knowledge 'docs/decisions/2026-08-10-something.md'
tests/mark-needs-audit.cases.sh:739:  check_case '72 결정 문서(대문자 확장자) → 지식 게이트만(원본 대소문자로 기록)' 0 knowledge 'docs/decisions/2026-08-10-upper.MD'

2026-08-10T03:52:07.204371Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "nl -ba docs/decisions/2026-08-06-gate-scope-by-file-identity.md | sed -n '1,180p'
rg -n '\\.needs-vault|VAULT_FLAG|stop:vault' --glob '"'!_workspace/**'"' ." in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
     1	# ADR-0007: 완료 게이트 검사 범위는 위치가 아니라 파일 정체성으로 정한다
     2	
     3	Status: accepted
     4	Date: 2026-08-06
     5	관련: PR #14, ADR-0005(커밋 분할 근거)
     6	
     7	## Context
     8	
     9	완료 게이트(`.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)를 세우는
    10	`mark-needs-audit.sh` 는 **"편집한 파일이 `PROJECT_DIR` 안인가"** 로만 판정했다. 밖이면 통째로 스킵했다.
    11	
    12	그런데 하네스 자신을 고치는 작업은 **항상 `PROJECT_DIR` 밖 별도 클론**에서 일어난다.
    13	2026-08-04 실사고: 하네스 템플릿을 고치는 턴에 게이트가 하나도 서지 않아 검증 없이 끝났다.
    14	게이트가 프로젝트는 지키면서 정작 게이트 자신을 만드는 작업만 못 지켰다.
    15	
    16	이 부류는 **조용히 틀린다** — 플래그가 안 서도 에러가 없다. 그래서 규칙을 산문으로만 두면
    17	언제 무너졌는지도 알 수 없다.
    18	
    19	첫 시도(`38b36f6`, 미머지)는 "밖이라도 git 저장소 안이면 그 저장소 기준으로 검사"를 도입했으나
    20	차단급 결함 4건이 남았다. 그중 하나는 **설계·계획 산출물 판정이 경로 정규화보다 먼저 돌아**
    21	고치려던 그 지점이 그대로 남은 것이었다.
    22	
    23	## Decision
    24	
    25	**판정 기준을 "어디 있나"에서 "무슨 파일인가"로 옮긴다.**
    26	
    27	| 입력 | 판정 |
    28	|---|---|
    29	| `PROJECT_DIR` 안 | 기존대로. 최상위 `_workspace/`·`.claude/` 와 순수 문서 제외 |
    30	| 밖 + **하네스 정본 저장소**(루트에 `template/.claude/`) | 저장소 전체를 **프로젝트와 같은 규칙으로** 검사 |
    31	| 밖 + 그 외 | `.claude/` 에 앵커된 하네스 경로만. **git 저장소가 아니어도 발화** |
    32	| `_workspace/00_design*.md`·`01_plan*.md` | 위치·git 여부 무관하게 듀얼리뷰 플래그만 |
    33	
    34	부수 결정 셋:
    35	
    36	1. **판정 순서가 곧 계약이다.** 개행 가드 → 물리 경로 정규화 → 듀얼리뷰 판정 → 범위 판정 → 분류 → 기록.
    37	   순서를 뒤집으면 조용히 판정이 바뀌므로, 각 순서를 지키는 테스트 행을 따로 둔다.
    38	2. **밖 편집은 절대경로로 기록한다.** 상대경로면 프로젝트와 외부 저장소가 `README.md` 같은 흔한 경로를
    39	   공유할 때 감사자가 프로젝트 쪽 동명 파일을 보고 통과시킨다.
    40	3. **조용한 실패를 없앤다.** 정규화 실패는 스킵하지 않고 원본 경로로 판정을 잇는다(fail-loud).
    41	   플래그 쓰기 실패·경로 개행·git 거부는 **차단하지 않고**(PostToolUse 계약) `systemMessage` 로 알린다.
    42	
    43	**계약의 정본은 산문이 아니라 `tests/mark-needs-audit.cases.sh` 의 판정 표**다. 케이스 수는 같은 파일의
    44	`EXPECTED_CASES` 가 강제하고 CI 가 PR 마다 돌린다. 문서에는 개수를 적지 않는다.
    45	
    46	## Alternatives Considered
    47	
    48	**A. `$HOME` 접두사 예외 유지 (첫 시도의 방식)**
    49	- Pros: 명세 문구에 가장 가까움. 변경 폭 작음
    50	- Cons: 양방향으로 틀린다. `~/dotfiles` 는 안 걸러지고, `~/.claude` 가 git 저장소인 셋업에서는
    51	  그 아래 하네스 클론이 조용히 스킵된다. **위치 기준 자체가 원인**이라 예외를 더해도 새 예외가 필요해진다
    52	- Why not: 채택안은 예외 규칙 없이 같은 결과를 낸다
    53	
    54	**B. 밖에서도 제외 목록 방식으로 코드 전반 게이트**
    55	- Pros: 하네스 파일을 놓칠 일이 없다
    56	- Cons: 남의 저장소를 잠깐 고쳐도 게이트 4종이 선다. 오탐이 많아 탈출구를 상시로 쓰게 되고,
    57	  그러면 게이트 자체가 무력화된다
    58	- Why not: 오탐 비용이 위음성 방지 이득을 넘는다
    59	
    60	**C. 정본 마커에 `template/.claude/hooks/_common.sh` 존재까지 AND 조건**
    61	- Pros: 오탐 표면이 준다
    62	- Cons: **위음성을 넓힌다.** 그 파일이 없는 하네스 포크에서 이전 판에는 서던 게이트가 사라진다.
    63	  "비용 0"이라 판단했으나 codex 검수가 반증했다
    64	- Why not: 오탐(과하게 섬)보다 위음성(조용히 안 섬)이 나쁘다는 이 게이트의 기본 방향과 충돌
    65	
    66	**D. 설계·계획 문서 판정을 git 저장소 안일 때만**
    67	- Pros: 명세 문구 그대로
    68	- Cons: **실측으로 반증됨** — 이 작업의 `_workspace/` 자체가 어느 git 저장소에도 속하지 않는다(rc=128).
    69	  그대로 두면 "설계만 한 턴은 게이트 0개"인 원 실사고가 그대로 남는다
    70	- Why not: 고치려던 사고를 못 고친다
    71	
    72	## Consequences
    73	
    74	**Positive**
    75	- 하네스 저장소·홈 설치본을 고치는 작업이 프로젝트 작업과 같은 무게를 갖는다.
    76	  "하네스는 툴이니까 가볍게"가 기계적으로 불가능해졌다
    77	- 판정 규칙이 표로 고정돼 CI 가 강제한다. 되돌림 실측과 변이 주입으로 테스트가 실제로 결함을 잡는 것을 확인했다
    78	- 예외 규칙(`$HOME`)이 사라져 규칙이 한 층 얕아졌다
    79	
    80	**Negative**
    81	- **정본 마커 오탐** — 루트에 `template/.claude/` 를 둔 제3 저장소를 하네스로 오인할 수 있다.
    82	  피해 방향이 "과하게 섬"이고 탈출구(`ECC_DISABLED_HOOKS=post:edit:needs-audit`)가 있어 감수한다
    83	- **반대 방향 위음성** — `template/.claude/` 를 두지 않는 재배치 포크는 정본으로 인식되지 않는다.
    84	  그런 포크는 현재 없고, 마커를 단순하게 유지해 예측 가능성을 택했다
    85	- **하네스 작업 턴이 길어진다.** 게이트 4개를 다 밟아야 끝난다. 버그가 아니라 의도다
    86	- 모노레포 하위 패키지가 자기 `.claude/` 를 가지면 게이트가 선다. **이번 변경이 만든 게 아니라
    87	  구판에도 있던 동작**이며, 고치는 것은 범위 밖이라 케이스로 기록만 했다
    88	
    89	**과정에서 배운 것 (다음 사람용)**
    90	- **"겹치는 파일 0개"는 리베이스 생략의 근거가 못 된다.** 이 PR 도중 `main` 이 앞서 갔는데(#13)
    91	  파일이 안 겹친다는 이유로 리베이스를 생략했다. 그 결과 **#13 이 형제 함수에서 방금 고친 버그**
    92	  (논리 `cd` 가 `심링크/..` 를 오판)를 새 함수가 그대로 들고 들어왔다. 텍스트 충돌이 아니라 의미 충돌이었다.
    93	  → 직전 커밋들이 **무엇을 고쳤는지**를 파일 목록이 아니라 내용으로 확인해야 한다
    94	- **검증 절차 자체가 작업물을 지울 수 있다.** 되돌림 실측에 `git checkout -- <파일>` 을 쓰면
    95	  인덱스의 구판이 복원돼 새 구현이 사라진다. `cp` 백업/복원만 쓴다
    96	- **`2>/dev/null` 은 리다이렉트 *열기* 실패를 못 막는다.** 셸이 그 전에 보고한다. 복합명령으로 감싸야 한다
    97	- **명령 치환은 후행 개행을 먹는다.** 그래서 경로 끝 개행은 가드가 보기도 전에 사라진다. 센티널 캡처가 필요하다
./README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
./README.md:93:대안: "세션 끝나면 second brain 볼트에 정리해라" 산문 규칙. → 세션 내내 0회 이행된 실사고. 코드·설정이 바뀐 턴은 볼트 `Projects/<name>/` 4종 세트(discussion-log·decisions/ADR·architecture·index) 반영 또는 불요 사유 기록 없이 종료 불가(`.needs-vault` + Stop 훅 `stop:vault`). completion-auditor가 볼트 커밋 해시·파일 실존을 1차 증거로 검증한다 — 코드가 끝나도 지식이 볼트에 없으면 완료가 아니다.
./README.md:135:| 볼트(second brain) 반영 산문 규칙이 세션 내내 0회 이행 (2026-08-02) | `.needs-vault` 플래그 + Stop 볼트 게이트 — 지식 반영도 완료 조건으로 승격 |
./docs/decisions/2026-08-06-gate-scope-by-file-identity.md:9:완료 게이트(`.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)를 세우는
./tests/check-layer-boundary.test.sh:109:c09() { leak_case '구현체 이름 플래그 — needs-vault' 'rm -f .claude/.needs-vault'     'needs-vault'; }
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:29:| `template/.claude/hooks/mark-needs-audit.sh` | `.needs-vault` |
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:30:| `template/.claude/hooks/verify-before-stop.sh` | `.needs-vault` |
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:31:| `template/.claude/hooks/_common.sh` | `.needs-vault` |
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:64:플래그 이름도 계약 수준으로 올린다: `.needs-vault` → `.needs-knowledge`.
./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:114:- **플래그 개명**: `.needs-vault` → `.needs-knowledge`

2026-08-10T03:52:15.986891Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "rg -n '04_codex_prompt|04_review\\.diff|04_codex_review' _workspace/04_review.diff || true
git log --oneline --decorate --max-count=12 5ce8597..HEAD" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
d71f147 (HEAD -> refactor/knowledge-store-layer, origin/refactor/knowledge-store-layer) docs: 이행 경과와 변이 측정 결과를 기록한다
95a6f37 docs: 이행이 끝났는데 결정 문서는 아직 "구현 대기"라고 말한다
fe6f58b feat: 지식이 쓰기 전용이었다 — 회수 방향을 연다
d3c536e fix: 훅을 하나씩 덮으면 신·구가 섞인 중간 상태가 반드시 생긴다
2101cde feat: 층 경계를 산문이 아니라 기계가 지킨다
188ea42 refactor: 하네스가 지식 저장소의 구현을 알고 있었다
9e45545 wip: 층 경계 이행 — 커밋 전 변이 측정용 스냅샷
10bf56b docs: 사용자가 받는 정본이 아직 "source 하는 설정"이라고 안내한다
f4fc862 test: 변이로 재보니 방어 하나가 죽은 줄이었다
73aeeed fix: 원문 판독이 셸에게서 물려받은 파싱을 끝까지 한다
daaa745 docs: 완료 감사가 찾은 미보고 결함 4건을 기록한다
b005dab docs: 재작업 경과와 라운드 1 검수 결과를 기록한다

codex
설치·동기화 경로에서 차단급 후보가 확인됐습니다. 특히 기존 훅 디렉터리의 “템플릿에 없는 파일”이 정상 재설치만으로 백업과 함께 사라지고, 첫 rename 직후 신호가 들어오면 파일시스템은 이동됐지만 `hooks_swapped=0`인 상태가 생깁니다. 남은 검토는 기존 플래그 마이그레이션과 공시·테스트가 이 실패들을 숨기는지 확인하는 쪽입니다.
exec
/bin/zsh -lc "rg --files global-agents template/.claude/hooks | sort
nl -ba README.md | sed -n '45,110p'
nl -ba README.md | sed -n '125,145p'
git diff --check 5ce8597..HEAD" in /Users/kty/Downloads/kty-claude-harness-template
 exited 2 in 0ms:
global-agents/research-collector.md
global-agents/research-evaluator.md
template/.claude/hooks/_common.sh
template/.claude/hooks/guard-codex-invocation.sh
template/.claude/hooks/guard-master-commit.sh
template/.claude/hooks/mark-needs-audit.sh
template/.claude/hooks/verify-before-stop.sh
    45	
    46	| 층 | 무엇 | 갱신 주체 |
    47	|---|---|---|
    48	| **참조** (복사 안 함, 전역 1회 설치) | ECC 룰(코딩/테스트/보안 표준) · superpowers(방법론 스킬) · claude-mem(세션 기억 자동 캡처+검색) · find-skills(스킬 생태계 검색 — 진화 시 "만들기 전에 찾는다") | 각 시스템이 업데이트되면 모든 프로젝트에서 즉시 최신 |
    49	| **글루** (이 repo 소유, install 시 복사) | 자체 에이전트 8 · 스킬 2(harness-orchestrator·readable-writing) · 강제 훅 4(커밋 가드·codex 규율 가드·게이트 플래그·Stop 게이트) · 제0원칙 (설계·계획·검수·보안검수 4역할은 ECC 에이전트 **참조** — dispatch 계약으로 호출 · 테스트품질 ecc:pr-test-analyzer는 조건부 `[tq]` 참조) | 이 repo에서 개선 → `sync.sh`로 프로젝트에 전파 |
    50	| **전역 글루** (이 repo `global-agents/` 소유, install/sync 시 `~/.claude/agents/`로 배포) | 프로젝트 무관 전역 에이전트 — research-collector(수집 [rc]) · research-evaluator(독립 평가 [re]). 정본이 repo인 이유: 전역 디렉토리는 버전 관리가 안 된다 ([ADR-0002](docs/decisions/2026-07-20-global-agents-layer.md)) | 이 repo에서 개선 → install/sync가 전역 갱신 |
    51	| **슬롯** (프로젝트 소유, 절대 안 덮음) | `project-profile.md`(도메인 전부: 스택·검증·불변식·경계면·운영·vcs·예시) · `harness.env`(타입체크 명령) | 사용자 |
    52	
    53	새 프로젝트 온보딩 = 슬롯 한 파일 채우기. 에이전트·훅은 손대지 않는다.
    54	
    55	## 3. 왜 이런 구성인가 — 핵심 설계 결정
    56	
    57	각 결정을 "결정 / 대안 / 왜"로 기록한다. (architecture-guide가 설명할 때의 근거 원장이기도 하다.)
    58	
    59	**① 파이프라인 + 3중 generate-verify 루프 (계획·개발·PR)**
    60	대안: 유능한 에이전트 하나가 다 하기. → 결함은 늦게 잡을수록 비싸다. 계획 결함을 개발 후에 발견하면 코드·검수·PR 전부 재작업. 각 산출물마다 생성자와 다른 검증자를 붙여 가장 싼 지점에서 잡는다. 역할 분리는 컨텍스트 오염도 막는다.
    61	
    62	**② 강제력은 훅이 소유한다 — 이 하네스의 무기**
    63	대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
    64	
    65	**③ 단일 프로필 슬롯 + 런타임 주입**
    66	대안 1: 도메인을 각 에이전트에 인라인(원본 방식) → 같은 사실이 5+개 파일에 중복, 바뀌면 드리프트. 대안 2: 에이전트에게 "프로필을 읽어라" 지시만 → 안 읽으면 도메인이 컨텍스트에 아예 없음. → 채택: 도메인은 프로필 한 파일(디스크의 단일 원천), 오케스트레이터가 dispatch마다 해당 §전문을 프롬프트에 동봉(런타임 인라인). **에이전트의 순종에 안 맡긴다.** 읽을지 선택할 기회 자체를 없앴고, 그래도 어기면 같은 프로필을 근거로 한 reviewer가 잡는다.
    67	
    68	**④ 제0원칙은 developer가 아니라 하네스가 소유**
    69	"코드는 사람을 위한 것 — 이름=계약, 구현=교체 가능한 부품, 과함도 배신(YAGNI)". 대안: developer 정의에만 넣기. → 모듈 경계는 **계획에서 정해지고 리뷰에서 강제**되므로 developer만 알면 샌다. planner(설계 반영)·plan-reviewer(검증)·developer(구현)·reviewer(적발)·architecture-guide(설명)가 같은 파일(`harness/principles.md`)을 공유한다.
    70	
    71	**⑤ ECC·superpowers·claude-mem은 참조, 복사 금지**
    72	대안: 좋은 부분을 템플릿에 복사해 자기완결. → 복사본은 그 순간부터 낡는다(버전 드리프트). 참조는 원본이 업데이트되면 공짜로 최신. superpowers 스킬은 서브에이전트의 `Skill` 도구로 런타임 로드(복사 0), ECC 룰은 세션 상주라 인용만, claude-mem recall은 `claude-mem:mem-search` 스킬 호출로 위임. 전역 `using-superpowers`의 "응답 전 스킬 먼저" 선점만 CLAUDE.md 지시로 꺼서 오케스트레이터가 순서 통제권을 유지한다.
    73	
    74	**⑥ per-agent 스킬 붕괴**
    75	원본은 에이전트마다 방법론 스킬이 짝(11개). 해부해 보니 내용물 = 에이전트 정의와 중복(~50%) + 도메인 사실(~40%, →프로필) + 트리거 문구(~10%, →오케스트레이터 description). 남는 알맹이가 없어 통째로 흡수했다. 단독 요청("검수만 다시")은 오케스트레이터 Phase 0의 부분 재실행이 커버.
    76	
    77	**⑦ 조건부 전문가 패턴 (ecc:architect · ecc:security-reviewer)**
    78	대안: 모든 변경에 설계·보안 검토. → 자잘한 수정에 매번 설계서를 만들면 과설계 공장이고, 모든 diff에 보안 검수는 소음이다. 오케스트레이터가 **트리거 기준**(구조적: 새 모듈/경계·데이터모델 변경/3+모듈 영향 · 보안: 인증/입력/DB/파일시스템/외부API/암호화/결제/시크릿)으로 판별해 해당할 때만 투입. plan-reviewer는 2-pass(1차 설계만, 2차 계획+정합성) — 호출마다 새 컨텍스트에 단일 임무라 혼란이 없고, 설계↔계획 정합성을 보는 주체가 유지된다.
    79	
    80	**⑧ 하이브리드 메모리**
    81	하중지지 사실(규칙·확정 결정·로드맵·프로필)은 파일 메모리(항상 로드), 긴 꼬리(세션 서사)는 claude-mem 자동 캡처+필요 시 검색. 전부 파일이면 비대, 전부 claude-mem이면 매 세션 재검색 위험. 승격 규칙: 검색에서 하중지지 사실이 나오면 파일로 승격.
    82	
    83	**⑨ 역할 등가는 참조로, 계약은 dispatch로 (2026-07-20)**
    84	설계(architect)·계획(planner)·검수(code-reviewer)·보안(security-reviewer) 4역할은 ECC에 역할 등가 에이전트가 이미 있어 자체 정의를 삭제하고 참조로 교체했다. 대안: 자체판 유지(계약이 정의에 내장돼 편함). → "만들기 전에 찾는다"를 자기 자신에게도 적용 — 역할 전문성은 ECC가 유지보수하고, 하네스 고유 계약(판정 형식·카테고리 태그·프로필 준수·수정 금지)은 오케스트레이터의 **dispatch 계약**이 프롬프트 주입으로 강제한다(③의 런타임 주입과 같은 원리). 생태계에 등가가 없는 게이트·감사류 5종(clarifier·plan-reviewer·pr-author 포함 8종)만 자체 소유로 남긴다 — 이것이 이 하네스의 차별점이다.
    85	
    86	**⑩ 전역 에이전트 층 — 정본=repo, 배포=~/.claude/agents/ (2026-07-20)**
    87	리서치 수집/평가처럼 프로젝트 무관 에이전트는 프로젝트 글루로도, 전역 직접 작성으로도 안 맞는다(전자는 용도 불일치, 후자는 버전 관리 불가). `global-agents/`를 정본으로 install/sync가 전역 배포한다. reporter 에이전트는 기각 — evaluator 분리의 가치는 독립성이지만 보고서의 가치는 사용자 맥락이고 그것은 메인 세션에 있다. 상세: [ADR-0002](docs/decisions/2026-07-20-global-agents-layer.md).
    88	
    89	**⑪ 모든 검증 게이트는 이종(異種) 듀얼 — Claude + Codex (2026-08-01 사용자 확정)**
    90	대안: Claude 리뷰어 단독. → 같은 모델은 생성자와 맹점을 공유한다 — 실제로 Claude 단독 검수가 놓친 CRITICAL을 codex가 적발했다(2026-08-03 POK-30). 계획검증·검수·PR점검 전 게이트에 codex를 병렬 투입하고 `[cc]`/`[cx]`/`[cc·cx]` 태그로 통합, 판정 충돌 시 보류 우선. 모델(`gpt-5.6-sol`)·effort(`high`)는 하드코딩 — "작업이 작다/비용" 사유의 임의 하향 실사고(2026-08-01)를 `guard-codex-invocation.sh`(PreToolUse)가 명령 위치의 `codex exec` 호출을 기계 차단한다(커밋 메시지·문서 속 문자열은 오탐 제외). 규정 자체도 기계화했다: 설계·계획 산출물 저장과 코드 편집이 `.needs-dualreview`를 세우고, Stop 훅이 이 플래그가 서 있는 한 종료를 막는다 — 플래그는 codex 리뷰 산출물(`_workspace/*codex*.md`) 저장·`[cc]`/`[cx]` 통합 후에만 지우는 규율이다(훅은 플래그만 보므로 산출물 실존 검증은 감사자 몫) — sync 누락으로 구버전 스킬이 듀얼 리뷰를 조용히 생략한 실사고(2026-08-03)의 재발 방지. 같은 사고에서 오케스트레이터 Phase 0의 정본 드리프트 확인(스킬·훅이 정본과 다르면 작업 전 sync 먼저)도 나왔다.
    91	
    92	**⑫ 지식 반영도 완료 조건 — 볼트 게이트 (2026-08-02 사용자 확정)**
    93	대안: "세션 끝나면 second brain 볼트에 정리해라" 산문 규칙. → 세션 내내 0회 이행된 실사고. 코드·설정이 바뀐 턴은 볼트 `Projects/<name>/` 4종 세트(discussion-log·decisions/ADR·architecture·index) 반영 또는 불요 사유 기록 없이 종료 불가(`.needs-vault` + Stop 훅 `stop:vault`). completion-auditor가 볼트 커밋 해시·파일 실존을 1차 증거로 검증한다 — 코드가 끝나도 지식이 볼트에 없으면 완료가 아니다.
    94	
    95	## 4. 에이전트 — 자체 8 + ECC 참조 5
    96	
    97	**자체 에이전트 8** (이 repo 소유 — 하네스 계약이 정의에 내장):
    98	
    99	| 에이전트 | 역할 한 줄 | 투입 |
   100	|---|---|---|
   101	| clarifier | 모호점·비가역 결정을 질문으로 — "추측 말고 물어본다"의 강제 | 항상 (맨 앞) |
   102	| plan-reviewer | 설계·계획 검증 (2-pass) — 가장 싼 지점의 결함 사냥 | 항상 |
   103	| developer | TDD 구현, 프로필 불변식 준수 | 항상 |
   104	| pr-author | 브랜치→PR (기본 브랜치 커밋 금지·squash 전제) | 항상 |
   105	| pr-reviewer | PR 단위 위생·완결성·롤백성 | 항상 |
   106	| change-explainer | diff 기반 사용자용 설명 (프로필 §1 언어·수준) | 항상 (훅 강제) |
   107	| completion-auditor | 완료 주장을 1차 증거로 감사 (운영 반영까지) | 항상 (훅 강제) |
   108	| architecture-guide | 설계 의도·대안·트레이드오프 설명 | 파이프라인 밖 |
   109	
   110	**ECC 참조 에이전트 5** (2026-07-20 교체 — 역할 등가가 이미 생태계에 있으면 자체 제작 대신 참조. 하네스 계약은 오케스트레이터의 dispatch 계약이 프롬프트로 주입):
   125	
   126	| 실사고 | 낳은 설계 |
   127	|---|---|
   128	| "됐다"는데 실제론 안 됨 (커밋 없이 push 보고, 테스트 안 돌리고 통과 주장) | completion-auditor + Stop 훅 감사 게이트 — 주장을 믿지 않고 1차 증거로 |
   129	| 스택 PR의 base 삭제로 뒤 PR이 통째로 닫힘 | 스택 PR 금지, 기능마다 기본 브랜치에서 새 브랜치 + PreToolUse 커밋 가드 |
   130	| 머지됐는데 사용자는 옛 빌드 화면을 보며 "그대로"라고 항의 (2026-07-12) | 프로필 §6 운영 모델 + 감사자의 "머지 ≠ 운영 반영" 판정 의무 |
   131	| 변경 설명 단계를 오케스트레이터가 임의 생략 (2026-07-13) | `.needs-explain` 플래그 + Stop 훅 설명 게이트 — 산문이던 절차를 훅으로 |
   132	| 도메인 지식이 에이전트 5+곳에 산재, 재사용 불가 | 단일 프로필 슬롯 + 런타임 주입 — **이 템플릿의 탄생 이유** |
   133	| 신생 repo에서 커밋 가드가 우연히 통과 (Stage 6a에서 발견) | unborn HEAD 처리 명문화 — 우연을 의도로 (a9cad82) |
   134	| codex 리뷰를 "작업이 작다/비용"이라며 모델·effort 임의 하향 (2026-08-01) | 듀얼 리뷰 규칙에 모델·effort 하드코딩 + guard-codex-invocation 훅 — 미달 호출을 PreToolUse에서 차단 (환경변수 탈출구 없음) |
   135	| 볼트(second brain) 반영 산문 규칙이 세션 내내 0회 이행 (2026-08-02) | `.needs-vault` 플래그 + Stop 볼트 게이트 — 지식 반영도 완료 조건으로 승격 |
   136	| sync 누락 → 구버전 스킬이 설계 듀얼 리뷰를 조용히 생략, Claude 단독이 놓친 CRITICAL을 codex가 뒤늦게 적발 (2026-08-03 POK-30) | `.needs-dualreview` 기계 게이트 + Stop 차단 + Phase 0 정본 드리프트 확인 (다르면 작업 전 sync 먼저) |
   137	| 검사기 자신이 어긋난 사본을 통과시킴 — 마커를 꾸미거나 블록을 2개 두면 무사통과 (2026-08-04 실측) | 전체 줄 3상태 파서 + 미등록 사본 스캔 + NUL 바이트 거부 게이트(UTF-16·NUL 위장으로 스캔을 통째로 비켜가던 경로) + 회귀 테스트 (건수의 정본은 테스트 파일의 `EXPECTED_CASES`) |
   138	
   139	교훈의 패턴: **산문으로만 존재하는 절차는 언젠가 생략된다. 반복 실패는 훅·게이트·프로필로 승격하라.** (단, 선제 방어는 하지 않는다 — 실제로 겪은 뒤에 강제를 추가한다. YAGNI는 프로세스에도 적용된다.)
   140	
   141	## 6. 디렉토리 구조
   142	
   143	```
   144	~/.claude/harness-template/
   145	├── README.md                                  # 이 문서 (구성 + 왜)
_workspace/03_impl_r1.diff:6: trailing whitespace.
+    
_workspace/03_impl_r1.diff:10: trailing whitespace.
+    
_workspace/03_impl_r1.diff:15: trailing whitespace.
+    
_workspace/03_impl_r1.diff:19: trailing whitespace.
+    
_workspace/03_impl_r1.diff:25: trailing whitespace.
+    
_workspace/03_impl_r1.diff:28: trailing whitespace.
+    
_workspace/03_impl_r1.diff:39: trailing whitespace.
+ 
_workspace/03_impl_r1.diff:98: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:60: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:69: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:74: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:87: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:157: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:161: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:164: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:167: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:174: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:194: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:213: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:223: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:237: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:248: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:254: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:276: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:299: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:322: trailing whitespace.
+    
_workspace/03_impl_r1_codex.md:326: trailing whitespace.
+    
_workspace/03_impl_r1_codex.md:331: trailing whitespace.
+    
_workspace/03_impl_r1_codex.md:335: trailing whitespace.
+    
_workspace/03_impl_r1_codex.md:341: trailing whitespace.
+    
_workspace/03_impl_r1_codex.md:344: trailing whitespace.
+    
_workspace/03_impl_r1_codex.md:355: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:414: trailing whitespace.
+ 
_workspace/03_impl_r1_codex.md:606: trailing whitespace.
+     6	
_workspace/03_impl_r1_codex.md:615: trailing whitespace.
+    15	
_workspace/03_impl_r1_codex.md:620: trailing whitespace.
+    20	
_workspace/03_impl_r1_codex.md:633: trailing whitespace.
+    33	
_workspace/03_impl_r1_codex.md:670: trailing whitespace.
+    70	
_workspace/03_impl_r1_codex.md:698: trailing whitespace.
+    10	
_workspace/03_impl_r1_codex.md:702: trailing whitespace.
+    14	
_workspace/03_impl_r1_codex.md:705: trailing whitespace.
+    17	
_workspace/03_impl_r1_codex.md:708: trailing whitespace.
+    20	
_workspace/03_impl_r1_codex.md:715: trailing whitespace.
+    27	
_workspace/03_impl_r1_codex.md:735: trailing whitespace.
+    47	
_workspace/03_impl_r1_codex.md:754: trailing whitespace.
+    66	
_workspace/03_impl_r1_codex.md:764: trailing whitespace.
+    76	
_workspace/03_impl_r1_codex.md:773: trailing whitespace.
+    85	
_workspace/03_impl_r1_codex.md:784: trailing whitespace.
+    96	
_workspace/03_impl_r1_codex.md:790: trailing whitespace.
+   102	
_workspace/03_impl_r1_codex.md:812: trailing whitespace.
+   124	
_workspace/03_impl_r1_codex.md:835: trailing whitespace.
+   147	
_workspace/03_impl_r1_codex.md:857: trailing whitespace.
+   169	
_workspace/03_impl_r1_codex.md:882: trailing whitespace.
+   194	
_workspace/03_impl_r1_codex.md:909: trailing whitespace.
+     7	
_workspace/03_impl_r1_codex.md:970: trailing whitespace.
+    76	
_workspace/03_impl_r1_codex.md:980: trailing whitespace.
+    86	
_workspace/03_impl_r1_codex.md:991: trailing whitespace.
+    97	
_workspace/03_impl_r1_codex.md:997: trailing whitespace.
+   103	
_workspace/03_impl_r1_codex.md:1019: trailing whitespace.
+   125	
_workspace/03_impl_r1_codex.md:1040: trailing whitespace.
+           20  23  20  6e  6f  74  65  0a                                
_workspace/03_impl_r1_codex.md:1041: trailing whitespace.
+               #       n   o   t   e  \n                                
_workspace/03_impl_r1_codex.md:1047: trailing whitespace.
+           0d  0a                                                        
_workspace/03_impl_r1_codex.md:1048: trailing whitespace.
+          \r  \n                                                        
_workspace/mutation-harness-env-2026-08-10.txt:5: trailing whitespace.
+  ✓ BOM 제거를 지운다                            적색  2건 · 파일 앞 BOM + 첫 줄이 선언/BOM 이 있어도 실패 명령이 실제로 
_workspace/mutation-harness-env-2026-08-10.txt:9: trailing whitespace.
+  ✓ 히어독 탐지 호출을 지운다               적색  6건 · 히어독 본문의 키는 선언이 아니다/히어독 본문에만 있으면 
_workspace/mutation-harness-env-2026-08-10.txt:13: trailing whitespace.
+  ✓ 따옴표 뒤 후행 주석 허용을 잡음 취급한다 적색  4건 · 후행 주석/후행 주석/CRLF + 후행 주석/후행 주석이 붙은 실패 

2026-08-10T03:54:31.169029Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "rg -n -i 'second[ -]brain|obsidian|볼트|_CLAUDE\\.md|4종 세트|discussion-log|Projects/<name>|needs-vault' global-agents || true
nl -ba docs/decisions/2026-08-06-knowledge-gate-default-on.md | sed -n '30,120p'
nl -ba template/.claude/hooks/_common.sh | sed -n '104,230p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
global-agents/research-collector.md:24:3. **arXiv·Semantic Scholar·OpenAlex·CrossRef 공개 API** — WebFetch/curl 직접 호출(키 불요). obsidian-second-brain 플러그인이 설치돼 있으면 그 키리스 수집 스크립트(`uv run --directory <플러그인 skill root> -m scripts.research.research "<주제>" --free [--academic]`)가 이 소스들을 한 번에 JSON으로 준다 — vault 저장 단계는 수행하지 말고 JSON만 소비한다.
    30	기존 설치본의 `harness.env` 에는 이 키가 **아예 없다.** 없을 때를 "꺼짐"으로 읽으면 하네스를 갱신하는 순간 게이트가 조용히 꺼진다.
    31	
    32	## Decision
    33	
    34	**① 게이트 값은 실행하지 않는다. 원문으로 읽는다.**
    35	
    36	1비트에 임의 코드 실행의 위험을 질 이유가 없다. 실행하지 않으면 위 부류가 **원리적으로** 소멸한다 — 판독 결과를 바꾸는 유일한 방법이 "그 키를 다르게 쓰는 것"이 되고, 그게 정확히 의도적으로 값을 바꾸는 방법이다.
    37	
    38	**② 판독 모델: 선행 공백 없는 최상위 선언이 정확히 1개일 때만 그 값을 믿는다.**
    39	
    40	조건문·함수 본문 안의 대입은 실행돼야 발효하는데 이 파일은 실행되지 않으므로, 원문만으로는 발효 여부를 알 수 없다. 선언이 2개 이상이면 어느 것이 이기는지도 알 수 없다.
    41	
    42	**③ 끄는 방법은 값을 리터럴로 비우는 것 하나뿐. 그 외는 전부 켜짐.**
    43	
    44	키가 없어도 · 선언이 2개여도 · 지원 문법 밖이어도 **켠다.** 업그레이드가 게이트를 조용히 끄는 것이 이 설계에서 가장 나쁜 결과이기 때문이다. 사용자는 지식이 쌓인다고 믿는데 그 턴부터 아무것도 안 남고, 아무 에러도 안 난다.
    45	
    46	`sync.sh` 는 키가 없는 설치본에 `HARNESS_KNOWLEDGE_GATE="on"` 을 **덧붙이기만** 한다 — 동작은 어차피 같지만, 파일에 한 줄도 없으면 사용자가 그런 스위치가 있다는 것 자체를 모른다.
    47	
    48	**④ 실행을 버리면 셸 파서 의무를 물려받는다 (2026-08-10 정정).**
    49	
    50	원래 설계는 여기까지였고, 그것이 부족했다. `source` 를 버린 뒤 파싱을 절반만 해서 **fail-open 을 없애려다 다른 fail-open 6종**을 만들었다. 값에 쓰레기가 섞여 `sh -c` 가 rc=127 을 내고, 호출부가 그걸 "도구가 없구나"로 읽어 검사를 조용히 생략한다:
    51	
    52	| 입력 | 실행했다면 | 절반만 판독하면 |
    53	|---|---|---|
    54	| `KEY="cmd" # 메모` | `cmd` | `"cmd" # 메모` 전체 → rc=127 |
    55	| `KEY="cmd"` + 후행 공백 | `cmd` | `"cmd"   ` → rc=127 · **눈에 안 보인다** |
    56	| CRLF 줄끝 | `cmd` | `"cmd"\r` → rc=127 · **눈에 안 보인다** |
    57	| 파일 앞 BOM | 무해 | 첫 키가 **무매치** → 미설정 |
    58	| 히어독 본문의 같은 키 | 선언 아님 | **선언으로 셈** → "2개" 판정 |
    59	
    60	그래서 판독 순서를 계약으로 고정한다:
    61	
    62	```
    63	① BOM 제거 → ② CR 제거 → ③ 히어독 본문 배제 → ④ 선언 판정
    64	→ ⑤ 값 앞 공백 절단 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 밖 후행 주석 → ⑧ 남은 후행 공백 절단
    65	```
    66	
    67	그리고 **지원 문법을 좁게 고정하고 문서에 적는다.** 사용자는 "셸 파일이니 셸 문법이 다 되겠지"라고 가정하기 때문이다. 문법 밖은 조용히 절반만 읽지 않고 전부 "값을 믿을 수 없음"으로 떨어진다.
    68	
    69	**⑤ "리터럴로 비웠다"와 "값을 믿을 수 없다"를 반환 코드로 가른다.**
    70	
    71	스위치형 슬롯에서 이 둘은 **반대 방향**이다(전자는 끄고, 후자는 켠다). 빈 문자열 하나로 뭉뚱그리면 사용자가 일부러 끈 것과 키가 없는 기존 설치본이 구별되지 않는다.
    72	
    73	## Alternatives Considered
    74	
    75	### A. `source` 하되 서브셸·리다이렉트로 가둔다
    76	- **Pros**: 셸 문법을 공짜로 얻는다. 파서를 직접 쓰지 않아도 된다
    77	- **Cons**: 막을 때마다 새 탈출 경로가 나왔다(위 표). 서브셸로 막으니 `return`, 리다이렉트로 막으니 `printf` 재정의
    78	- **Why not**: 창을 좁히는 접근이라 끝이 없다. **부류를 없애야** 멈춘다
    79	
    80	### B. 값을 JSON·INI 등 비실행 형식으로 바꾼다
    81	- **Pros**: 파싱 계약이 명확하고 셸 파서 의무를 안 물려받는다
    82	- **Cons**: 기존 설치본의 `harness.env` 를 전부 마이그레이션해야 하는데, 슬롯은 프로젝트 소유라 하네스가 덮을 수 없어 강제할 수단이 없다
    83	- **Why not**: 이행 비용이 얻는 것보다 크다. 지원 문법을 좁혀 문서화하는 것으로 같은 안전성에 도달한다
    84	
    85	### C. 키가 없으면 꺼짐 (관용구 일관성)
    86	- **Pros**: `HARNESS_TYPECHECK_CMD` 의 "비우면 생략" 과 모양이 같다
    87	- **Cons**: 기존 설치본에는 키가 없다 → **업그레이드가 게이트를 조용히 끈다**
    88	- **Why not**: 관용구 일관성보다 동작 보존이 무겁다. 조용히 꺼지는 게이트는 없는 것만 못하다
    89	
    90	### D. `="off"` 도 꺼짐으로 인정한다
    91	- **Pros**: 직관적이다. `off` 라고 적으면 꺼지리라 기대하는 것이 자연스럽다
    92	- **Cons**: "리터럴로 비었을 때만 끈다"는 단일 규칙이 깨지고, 그 다음엔 `false`·`0`·`no`·`OFF` 를 어디까지 인정할지가 끝없이 이어진다. 인정 목록에서 빠진 표기를 쓰면 **사용자는 껐다고 믿는데 켜져 있다**
    93	- **Why not**: 규칙을 하나로 유지하고, 대신 그 직관 충돌을 **세 곳에 명시**한다(`harness.env` 주석 · `docs/usage.md` · 오케스트레이터 스킬)
    94	
    95	## Consequences
    96	
    97	### Positive
    98	- 임의 코드 실행 부류가 원리적으로 소멸
    99	- 업그레이드가 게이트를 조용히 끄는 경로가 없다
   100	- 실패 방향이 전부 "켜짐" 쪽이다 — 판독이 어떻게 틀려도 게이트는 살아 있다
   101	
   102	### Negative
   103	- **셸 파서 의무를 물려받았다.** 지원 문법이 좁고, 그 사실을 사용자가 알아야 한다
   104	- `="off"` 가 켜짐으로 읽히는 것은 직관에 반한다. 문서로만 완화된다
   105	- 히어독 탐지는 근사다. 한 줄에 히어독이 둘이면 첫 개만 본다
   106	
   107	### 실패 방향이 왜 안전한가
   108	히어독 탐지가 어느 쪽으로 틀려도 결과는 "값을 믿을 수 없음"으로 수렴한다 — 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다. 둘 다 게이트는 **켜짐**이다.
   109	
   110	## 기계적 장치
   111	
   112	`tests/harness-env-read.test.sh` 가 판독 계약(반환 코드 + 값의 바이트)과 게이트 계약을 붙든다.
   113	
   114	게이트 케이스는 `harness.env` 의 키 개수와 값을 **직접 해석하지 않는다.** 지식 플래그 하나만 세우고 **훅 자신을 돌려** 차단되는지를 본다 — 판독 규칙의 사본을 테스트에 두면 그 사본이 언젠가 원본과 어긋나고, 그때 테스트는 **틀린 기준으로 초록**을 낸다.
   115	
   116	통합 케이스는 종료 코드만 보지 않는다. 타입체크를 건너뛰어도 뒤의 감사 게이트가 어차피 rc=2 로 막으므로, **어느 게이트가 막았는지의 문구**까지 재야 판별력이 생긴다.
   117	
   118	## 관련
   119	- [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md) — 층 경계(이 스위치가 필요한 이유)
   120	- [ADR-0009](2026-08-06-profile-canon-upstream.md) — 프로필 정본과 조회 배선
   104	  # LC_ALL=C 여야 substr 이 바이트 단위로 동작해 BOM 3바이트를 정확히 떼어낸다.
   105	  val="$(LC_ALL=C awk -v key="$key" -v bom="$(printf '\357\273\277')" '
   106	function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
   107	function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
   108	
   109	# 히어독 시작을 찾는다. 따옴표 안의 `<<` 와 주석 뒤의 `<<` 는 히어독이 아니다.
   110	function scan_heredoc(s,   n, i, j, c, q, t, dash) {
   111	  n = length(s); i = 1; q = ""
   112	  while (i <= n) {
   113	    c = substr(s, i, 1)
   114	    if (q != "") { if (c == q) q = ""; i++; continue }
   115	    if (c == "\"" || c == SQ) { q = c; i++; continue }
   116	    if (c == "#" && (i == 1 || substr(s, i - 1, 1) == " " || substr(s, i - 1, 1) == "\t")) return
   117	    if (c == "<" && substr(s, i + 1, 1) == "<") {
   118	      if (substr(s, i + 2, 1) == "<") { i += 3; continue }        # <<< 는 히어스트링
   119	      j = i + 2; dash = 0
   120	      if (substr(s, j, 1) == "-") { dash = 1; j++ }
   121	      while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
   122	      t = ""; c = substr(s, j, 1)
   123	      if (c == "\"" || c == SQ) {                                  # <<"EOF" · <<EOF
   124	        j++
   125	        while (j <= n && substr(s, j, 1) != c) { t = t substr(s, j, 1); j++ }
   126	      } else {
   127	        while (j <= n) {
   128	          c = substr(s, j, 1)
   129	          if (c ~ /[A-Za-z0-9_.\/-]/) { t = t c; j++ } else break
   130	        }
   131	      }
   132	      if (t != "") { INHD = 1; HTERM = t; HDASH = dash }
   133	      return
   134	    }
   135	    i++
   136	  }
   137	}
   138	
   139	# 지원 문법대로 값을 판독한다. 문법 밖이면 BAD 를 세운다(빈 값으로 위장하지 않는다).
   140	function parse_value(v,   q, rest, e, out, tail, i, c, p) {
   141	  # 여기서는 **앞** 공백만 턴다. 뒤 공백은 갈래마다 다른 자리에서 털린다 —
   142	  # 인용 값은 닫는 따옴표 뒤(tail)에서, 인용 없는 값은 반환 직전 rtrim(out) 에서.
   143	  # 여기서 한 번 더 rtrim 하면 어느 변이로도 죽지 않는 죽은 줄이 된다(변이 측정으로 확인).
   144	  v = ltrim(v)
   145	  if (v == "") return ""
   146	  q = substr(v, 1, 1)
   147	  if (q == "\"" || q == SQ) {
   148	    rest = substr(v, 2)
   149	    e = index(rest, q)
   150	    if (e == 0) { BAD = 1; return "" }                             # 닫히지 않은 따옴표
   151	    out = substr(rest, 1, e - 1)
   152	    tail = ltrim(substr(rest, e + 1))
   153	    if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음
   154	    return out
   155	  }
   156	  if (q == "#") return ""                                          # 값 자리가 통째로 주석
   157	  out = ""
   158	  for (i = 1; i <= length(v); i++) {
   159	    c = substr(v, i, 1)
   160	    if (c == "#") {
   161	      p = substr(v, i - 1, 1)
   162	      if (p == " " || p == "\t") break
   163	    }
   164	    out = out c
   165	  }
   166	  return rtrim(out)
   167	}
   168	
   169	BEGIN {
   170	  SQ = sprintf("%c", 39)
   171	  N = 0; FOUND = ""; INHD = 0; HTERM = ""; HDASH = 0; BAD = 0
   172	  RX = "^(export[ \t]+)?" key "="
   173	}
   174	{
   175	  line = $0
   176	  sub(/\r$/, "", line)
   177	  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
   178	
   179	  if (INHD) {
   180	    t = line
   181	    if (HDASH) sub(/^\t+/, "", t)
   182	    if (t == HTERM) { INHD = 0; HTERM = "" }
   183	    next
   184	  }
   185	
   186	  # 선언 판정이 히어독 시작 판정보다 **먼저**다: `KEY=v <<EOF` 의 대입은 실제로 발효한다.
   187	  if (line ~ RX) {
   188	    N++
   189	    if (N == 1) FOUND = substr(line, index(line, "=") + 1)
   190	  }
   191	  scan_heredoc(line)
   192	}
   193	END {
   194	  if (INHD) exit 1          # 히어독이 EOF 까지 안 닫혔다 = 탐지가 빗나갔다
   195	  if (N != 1) exit 1
   196	  v = parse_value(FOUND)
   197	  if (BAD) exit 1
   198	  printf "%s", v
   199	  exit 0
   200	}
   201	' "$file" 2>/dev/null)"
   202	  rc=$?
   203	  [ "$rc" -eq 0 ] || { printf '%s' ''; return 1; }
   204	  printf '%s' "$val"
   205	  return 0
   206	}
   207	
   208	# 지식 반영 게이트가 켜져 있는가 (rc=0 켜짐 / rc=1 꺼짐).
   209	#
   210	# 하네스가 소유하는 것은 **계약 하나**뿐이다 — "지식 저장소가 설정돼 있으면, 결정·설계가
   211	# 나온 턴은 반영 없이 끝낼 수 없다." 어디에 어떤 구조로 반영하는지는 이 층이 모른다.
   212	# 그래서 필요한 것도 1비트뿐이고, 그 1비트를 얻으려고 파일을 실행하지 않는다.
   213	#
   214	# **기본이 켜짐인 것이 이 함수의 핵심이다.** 기존 설치본에는 이 키가 아예 없는데,
   215	# 없을 때 "꺼짐"으로 읽으면 하네스를 갱신하는 순간 게이트가 **조용히 꺼진다** — 사용자는
   216	# 지식이 쌓인다고 믿는데 그 턴부터 아무것도 안 남는다. 표명이 없으면 이전 동작을 보존한다.
   217	# 선언이 2개 이상이거나 문법 밖일 때도 같은 이유로 켠다(rc=1 → 켜짐).
   218	#
   219	# 끄는 방법은 **값을 리터럴로 비우는 것 하나뿐**이다: HARNESS_KNOWLEDGE_GATE=""
   220	# `="off"` 는 켜진 것으로 읽힌다 — 비어 있지 않기 때문이다. harness.env 주석에 명시돼 있다.
   221	harness_knowledge_gate_on() {
   222	  local v
   223	  v="$(harness_env_value HARNESS_KNOWLEDGE_GATE)" || return 0   # 값을 못 믿으면 켠다
   224	  [ -n "$v" ]                                                   # 리터럴로 비었을 때만 꺼짐
   225	}
   226	
   227	# 지식 게이트가 이번 턴에 **발효 중인가** — 플래그가 섰고 게이트도 켜져 있는가.
   228	# 판정을 이 한 곳에 모은다. 두 군데서 따로 물으면 "게이트를 껐는데 남아 있던 플래그가
   229	# 읽기 전용 턴의 조기 종료를 막는" 종류의 어긋남이 생긴다.
   230	knowledge_gate_active() {

2026-08-10T03:54:47.535494Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
codex
정적 검수 결과, 차단급 결함이 있습니다. 테스트는 실행하지 않았습니다.

[HIGH] template/.claude/hooks/_common.sh:129 — `cat <<\EOF`처럼 백슬래시로 인용한 유효한 히어독은 delimiter가 빈 값으로 탐지되어 본문을 건너뛰지 않는다. 본문에 `HARNESS_KNOWLEDGE_GATE=""` 하나만 있으면 선언으로 세어 rc=0·빈 값을 반환하고 지식 게이트가 꺼진다. 한 줄에 히어독이 둘인 경우에도 두 번째 본문의 선언이 같은 방식으로 통과한다. 테스트는 단순 `<<EOF`만 다뤄 이 위음성을 놓친다.

[HIGH] template/.claude/hooks/_common.sh:187 — “행 맨 앞”을 “최상위”로 간주하지만 셸 문법상 둘은 다르다. `if false; then` 다음 행에 들여쓰기 없이 `HARNESS_KNOWLEDGE_GATE=""`를 쓰거나, 여러 줄 인용 문자열 안에 같은 행을 넣으면 실제 선언이 아닌데도 유일한 선언으로 판독되어 게이트가 꺼진다. 테스트의 위장 선언은 들여쓴 경우만 다룬다.

[HIGH] template/.claude/hooks/_common.sh:152 — `HARNESS_KNOWLEDGE_GATE=""#on`은 지원 문법상 따옴표와 주석 사이 공백이 없어 rc=1이어야 하고, 셸로 해석해도 값은 비어 있지 않은 `#on`이다. 그러나 `ltrim()` 후 `#`만 확인해 rc=0·빈 값으로 받아 게이트를 끈다. `HARNESS_KNOWLEDGE_GATE=#on`도 line 156에서 빈 값으로 오인한다.

[HIGH] template/.claude/hooks/_common.sh:13 — 기존 설치본에 미처리 `.needs-vault`만 남은 상태에서 sync하면 새 훅은 `.needs-knowledge`만 확인하고 기존 플래그를 마이그레이션하지 않는다. 다른 플래그가 없다면 `verify-before-stop.sh:25`가 즉시 rc=0으로 끝나 기존 지식 반영 의무가 조용히 소멸한다.

[HIGH] install.sh:99 — 정상 재설치에서도 기존 `hooks` 디렉터리 전체를 백업으로 옮기고, 템플릿의 `*.sh`만 담긴 새 디렉터리를 설치한 뒤 line 113에서 백업을 삭제한다. 따라서 `.claude/hooks/custom.sh`, 보조 파일, 하위 디렉터리처럼 템플릿에 없는 사용자 파일이 영구 삭제된다. `tests/install-hook-swap.test.sh:110`은 오히려 `.old-marker` 삭제를 성공 조건으로 삼아 이 회귀를 가린다.

[HIGH] install.sh:99 — 첫 `mv`가 완료됐지만 line 100의 `hooks_swapped=1` 실행 전에 INT/TERM/HUP/QUIT가 전달되면, Bash는 외부 명령 종료 뒤 대기 중인 trap을 먼저 실행한다. 실제 파일시스템에는 구판이 백업으로 이동했지만 플래그는 0이므로 핸들러가 복원하지 않고 line 88에서 백업을 삭제해 훅 디렉터리가 사라진다. 테스트 shim은 두 번째 `mv` 직전만 신호를 넣어 이 창을 검사하지 않는다.

[HIGH] install.sh:83 — 신호 복구 `mv`의 성공 여부를 확인하지 않고 “되돌렸습니다”를 출력한 뒤 백업을 삭제한다. 복구 중 대상 디렉터리가 생기거나 권한 문제로 `mv`가 실패하면 구판이 삭제되고 훅은 없거나 중첩된 상태가 된다. 두 번째 rename 실패 경로(line 104–107)도 복구 실패 뒤 백업을 삭제하며, 테스트는 세 번째 `mv`가 성공하는 경우만 검증한다.

[HIGH] sync.sh:109 — append가 디스크 부족·신호로 `HARNESS_KNOWLEDGE_GATE=`까지만 기록되면 파서는 이를 rc=0·리터럴 빈 값으로 판독해 게이트를 끈다. `printf`가 실패하면 검증 grep은 실행되지 않지만 잘린 줄은 남고, 경고는 “키가 없으면 켜짐이라 동작은 그대로”라고 잘못 안내한다. `printf`가 성공으로 끝난 경우에도 line 110의 grep은 값·유일성·파서 결과를 확인하지 않는다.

[HIGH] scripts/check-layer-boundary.sh:39 — 배포물 스캔 범위를 `template/`로만 고정했지만 `install.sh:123-126`은 `global-agents/`도 전역 글루로 배포한다. 현재 `global-agents/research-collector.md:24`에 검사기가 금지하는 `obsidian-second-brain`과 vault 구현이 이미 들어 있어, 실제 누출이 있는 HEAD에서도 CI는 통과한다. 테스트는 매번 `HARNESS_LAYER_SCAN_ROOT`를 임시 단일 트리로 덮어 기본 배포 범위 누락을 잡지 못한다.

[MEDIUM] docs/usage.md:65 — 설계·계획 산출물은 “듀얼리뷰 플래그만” 세운다고 공시하지만 구현은 `mark-needs-audit.sh:255-256`에서 듀얼리뷰와 지식 플래그를 함께 세운다. `_workspace/00_design.md` 편집 후 문서대로 듀얼리뷰만 처리하면 예상하지 못한 지식 게이트에 다시 차단된다. 같은 오기는 line 82와 ADR-0007 line 32에도 남아 있다.

[MEDIUM] README.md:63 — 현재 동작 설명이 여전히 `.needs-vault`, `stop:vault`, 볼트 고유 구현을 사용한다. 사용자가 이 문서대로 `ECC_DISABLED_HOOKS=stop:vault`를 설정하면 새 `stop:knowledge` 게이트는 꺼지지 않으며, ADR-0006의 “구현 누출 0” 공시와도 충돌한다.

그 밖에는 `LC_ALL=C`에서 BOM 3바이트를 자르는 방식 자체는 mawk/gawk/BSD awk 사이에서 구체적인 차이를 찾지 못했습니다. `awk`가 없으면 명령 치환 rc가 비영으로 전달되어 지식 게이트는 켜지는 안전한 방향이고, 정규식 키도 현재 호출부가 상수 두 개만 전달하므로 메타문자 주입 경로는 없습니다. `trap -` 위치와 mv shim의 비주입 경로에서 실제 `mv` rc를 보존하는 부분도 문제를 찾지 못했습니다.

판정: 보류
tokens used
188,269
정적 검수 결과, 차단급 결함이 있습니다. 테스트는 실행하지 않았습니다.

[HIGH] template/.claude/hooks/_common.sh:129 — `cat <<\EOF`처럼 백슬래시로 인용한 유효한 히어독은 delimiter가 빈 값으로 탐지되어 본문을 건너뛰지 않는다. 본문에 `HARNESS_KNOWLEDGE_GATE=""` 하나만 있으면 선언으로 세어 rc=0·빈 값을 반환하고 지식 게이트가 꺼진다. 한 줄에 히어독이 둘인 경우에도 두 번째 본문의 선언이 같은 방식으로 통과한다. 테스트는 단순 `<<EOF`만 다뤄 이 위음성을 놓친다.

[HIGH] template/.claude/hooks/_common.sh:187 — “행 맨 앞”을 “최상위”로 간주하지만 셸 문법상 둘은 다르다. `if false; then` 다음 행에 들여쓰기 없이 `HARNESS_KNOWLEDGE_GATE=""`를 쓰거나, 여러 줄 인용 문자열 안에 같은 행을 넣으면 실제 선언이 아닌데도 유일한 선언으로 판독되어 게이트가 꺼진다. 테스트의 위장 선언은 들여쓴 경우만 다룬다.

[HIGH] template/.claude/hooks/_common.sh:152 — `HARNESS_KNOWLEDGE_GATE=""#on`은 지원 문법상 따옴표와 주석 사이 공백이 없어 rc=1이어야 하고, 셸로 해석해도 값은 비어 있지 않은 `#on`이다. 그러나 `ltrim()` 후 `#`만 확인해 rc=0·빈 값으로 받아 게이트를 끈다. `HARNESS_KNOWLEDGE_GATE=#on`도 line 156에서 빈 값으로 오인한다.

[HIGH] template/.claude/hooks/_common.sh:13 — 기존 설치본에 미처리 `.needs-vault`만 남은 상태에서 sync하면 새 훅은 `.needs-knowledge`만 확인하고 기존 플래그를 마이그레이션하지 않는다. 다른 플래그가 없다면 `verify-before-stop.sh:25`가 즉시 rc=0으로 끝나 기존 지식 반영 의무가 조용히 소멸한다.

[HIGH] install.sh:99 — 정상 재설치에서도 기존 `hooks` 디렉터리 전체를 백업으로 옮기고, 템플릿의 `*.sh`만 담긴 새 디렉터리를 설치한 뒤 line 113에서 백업을 삭제한다. 따라서 `.claude/hooks/custom.sh`, 보조 파일, 하위 디렉터리처럼 템플릿에 없는 사용자 파일이 영구 삭제된다. `tests/install-hook-swap.test.sh:110`은 오히려 `.old-marker` 삭제를 성공 조건으로 삼아 이 회귀를 가린다.

[HIGH] install.sh:99 — 첫 `mv`가 완료됐지만 line 100의 `hooks_swapped=1` 실행 전에 INT/TERM/HUP/QUIT가 전달되면, Bash는 외부 명령 종료 뒤 대기 중인 trap을 먼저 실행한다. 실제 파일시스템에는 구판이 백업으로 이동했지만 플래그는 0이므로 핸들러가 복원하지 않고 line 88에서 백업을 삭제해 훅 디렉터리가 사라진다. 테스트 shim은 두 번째 `mv` 직전만 신호를 넣어 이 창을 검사하지 않는다.

[HIGH] install.sh:83 — 신호 복구 `mv`의 성공 여부를 확인하지 않고 “되돌렸습니다”를 출력한 뒤 백업을 삭제한다. 복구 중 대상 디렉터리가 생기거나 권한 문제로 `mv`가 실패하면 구판이 삭제되고 훅은 없거나 중첩된 상태가 된다. 두 번째 rename 실패 경로(line 104–107)도 복구 실패 뒤 백업을 삭제하며, 테스트는 세 번째 `mv`가 성공하는 경우만 검증한다.

[HIGH] sync.sh:109 — append가 디스크 부족·신호로 `HARNESS_KNOWLEDGE_GATE=`까지만 기록되면 파서는 이를 rc=0·리터럴 빈 값으로 판독해 게이트를 끈다. `printf`가 실패하면 검증 grep은 실행되지 않지만 잘린 줄은 남고, 경고는 “키가 없으면 켜짐이라 동작은 그대로”라고 잘못 안내한다. `printf`가 성공으로 끝난 경우에도 line 110의 grep은 값·유일성·파서 결과를 확인하지 않는다.

[HIGH] scripts/check-layer-boundary.sh:39 — 배포물 스캔 범위를 `template/`로만 고정했지만 `install.sh:123-126`은 `global-agents/`도 전역 글루로 배포한다. 현재 `global-agents/research-collector.md:24`에 검사기가 금지하는 `obsidian-second-brain`과 vault 구현이 이미 들어 있어, 실제 누출이 있는 HEAD에서도 CI는 통과한다. 테스트는 매번 `HARNESS_LAYER_SCAN_ROOT`를 임시 단일 트리로 덮어 기본 배포 범위 누락을 잡지 못한다.

[MEDIUM] docs/usage.md:65 — 설계·계획 산출물은 “듀얼리뷰 플래그만” 세운다고 공시하지만 구현은 `mark-needs-audit.sh:255-256`에서 듀얼리뷰와 지식 플래그를 함께 세운다. `_workspace/00_design.md` 편집 후 문서대로 듀얼리뷰만 처리하면 예상하지 못한 지식 게이트에 다시 차단된다. 같은 오기는 line 82와 ADR-0007 line 32에도 남아 있다.

[MEDIUM] README.md:63 — 현재 동작 설명이 여전히 `.needs-vault`, `stop:vault`, 볼트 고유 구현을 사용한다. 사용자가 이 문서대로 `ECC_DISABLED_HOOKS=stop:vault`를 설정하면 새 `stop:knowledge` 게이트는 꺼지지 않으며, ADR-0006의 “구현 누출 0” 공시와도 충돌한다.

그 밖에는 `LC_ALL=C`에서 BOM 3바이트를 자르는 방식 자체는 mawk/gawk/BSD awk 사이에서 구체적인 차이를 찾지 못했습니다. `awk`가 없으면 명령 치환 rc가 비영으로 전달되어 지식 게이트는 켜지는 안전한 방향이고, 정규식 키도 현재 호출부가 상수 두 개만 전달하므로 메타문자 주입 경로는 없습니다. `trap -` 위치와 mv shim의 비주입 경로에서 실제 `mv` rc를 보존하는 부분도 문제를 찾지 못했습니다.

판정: 보류
