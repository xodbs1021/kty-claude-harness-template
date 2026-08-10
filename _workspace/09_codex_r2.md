Reading additional input from stdin...
2026-08-10T08:15:22.996554Z ERROR codex_models_manager::cache: failed to load models cache: missing field `supports_reasoning_summaries` at line 93 column 5
OpenAI Codex v0.144.5
--------
workdir: /Users/kty/Downloads/kty-claude-harness-template
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019feabd-9ecd-7ca2-be55-34c053351a96
--------
user
# 결정 게이트 — 검수 2라운드 (델타)

**파일 생성·삭제 없이 정적 독해로만 판정하고, 마지막에 반드시 `판정: 통과` 또는
`판정: 보류` 줄을 내라.** 그 줄이 없으면 이 라운드는 미수행으로 센다.

1라운드에서 네가 낸 지적 9건을 전부 반영했다. **반영이 옳은지, 그리고 반영이 새 결함을
만들지 않았는지**를 본다.

## 델타
`_workspace/09_delta.diff` (기준 `238a979` → HEAD). 전체 맥락은 저장소 안:
- `template/.claude/hooks/_common.sh` 의 `decision_scan()`
- `template/.claude/hooks/verify-before-stop.sh` 의 `(3.2)` 절 · `emit_decision_note`
- `tests/decision-gate.test.sh` (59건) · `_workspace/mutate-decision-gate.sh` (35건 전건 적색)
- `docs/decisions/2026-08-10-decision-gate.md`

## 무엇을 어떻게 고쳤나

1. **rc 계약 재정의** — 0=차단, 2=판독 불가(사유 있음), 3=차단 불필요, **그 밖=판독 불가로 취급**.
   정상 통과에 1 을 주지 않는 것이 핵심이다(크래시도 1 이라 위장됐었다).
2. **부분 손상도 판독 불가** — 한 줄이라도 JSON 파싱 실패면 fail.
3. **형식 변화 감지** — `message` 가 비-dict, `content` 가 list/str 아님 → fail. `content` 가
   문자열이면 발화로 취급.
4. **경고를 다섯 게이트 전부에** — `emit_decision_note` 를 듀얼리뷰·설명·지식·push·감사에 호출.
5. **부정형 자백 예외** — `NEG_ASK` 가 걸리면 `QUESTION` 제외를 적용하지 않는다.
6. **발동을 플래그로 다시 물음** — `decision_armed`. push 미완만으로는 안 돈다.
7. **마침표는 뒤에 공백/줄끝일 때만 종결** · `~~~` 펜스 · 이중 백틱 지원.
8. **변이 하네스 트랩이 INT/TERM 에도 복원.**
9. **어휘는 안 좁힌다**(사용자 확정) — 대신 ADR·usage 에 "표본이고 영어는 커버리지 0"을 공시.

## 특히 봐 달라

- **위 고침이 만든 새 결함.** 1라운드 수정이 2라운드 결함을 낳는 것이 이 저장소의 알려진 패턴이다
- `decision_armed` 와 조기 종료·`flags_fp`·예산의 상호작용
- `emit_decision_note` 가 `set -uo pipefail` 아래에서 안전한가. 미설정 변수 참조 경로
- 파싱 엄격화가 **정상 기록을 판독 불가로 떨어뜨리지 않는가**(위양성 쪽) — 실제 기록은
  `queue-operation`·`attachment`·`last-prompt`·`custom-title` 같은 항목도 섞여 있다
- 문서(ADR·usage)가 **여전히 검증 범위보다 넓게** 약속하는 곳이 있나

## 형식
지적마다 `[등급] 파일:줄 — 무엇이/왜/어떻게`. 추측이면 `추정` 명시. 마지막 줄에 `판정: 통과|보류`.
codex
요청한 델타만 기준으로 정적 검수하겠습니다. 먼저 적용 지침과 전체 diff를 읽고, 이후 `decision_scan`·호출부·테스트/변이 하네스·문서 약속을 서로 대조하겠습니다. 파일 생성·수정·테스트 실행은 하지 않겠습니다.
exec
/bin/zsh -lc "pwd && rg --files -g 'AGENTS.md' -g '_workspace/09_delta.diff' -g 'template/.claude/hooks/_common.sh' -g 'template/.claude/hooks/verify-before-stop.sh' -g 'tests/decision-gate.test.sh' -g '_workspace/mutate-decision-gate.sh' -g 'docs/decisions/2026-08-10-decision-gate.md' -g '*usage*' -g 'README*'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
/Users/kty/Downloads/kty-claude-harness-template
_workspace/mutate-decision-gate.sh
_workspace/09_delta.diff
README.md
docs/decisions/2026-08-10-decision-gate.md
docs/usage.md
tests/decision-gate.test.sh

2026-08-10T08:15:36.626209Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "rg --hidden --files | rg '("'^|/)AGENTS'"\\.md"'$|template/'"\\.claude/hooks/(_common|verify-before-stop)\\.sh"'$|_workspace/09_delta'"\\.diff"'$|docs/(usage'"\\.md|decisions/2026-08-10-decision-gate\\.md)"'$|tests/decision-gate'"\\.test\\.sh"'$|_workspace/mutate-decision-gate'"\\.sh"'$'"'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
_workspace/mutate-decision-gate.sh
_workspace/09_delta.diff
docs/decisions/2026-08-10-decision-gate.md
docs/usage.md
tests/decision-gate.test.sh
template/.claude/hooks/_common.sh
template/.claude/hooks/verify-before-stop.sh

2026-08-10T08:15:41.702102Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "wc -l _workspace/09_delta.diff template/.claude/hooks/_common.sh template/.claude/hooks/verify-before-stop.sh tests/decision-gate.test.sh _workspace/mutate-decision-gate.sh docs/decisions/2026-08-10-decision-gate.md docs/usage.md && sed -n '1,260p' _workspace/09_delta.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
    5105 _workspace/09_delta.diff
     506 template/.claude/hooks/_common.sh
     370 template/.claude/hooks/verify-before-stop.sh
     613 tests/decision-gate.test.sh
     361 _workspace/mutate-decision-gate.sh
     170 docs/decisions/2026-08-10-decision-gate.md
     137 docs/usage.md
    7262 total
diff --git a/_workspace/08_codex_prompt.md b/_workspace/08_codex_prompt.md
new file mode 100644
index 0000000..edbd5cb
--- /dev/null
+++ b/_workspace/08_codex_prompt.md
@@ -0,0 +1,60 @@
+# 검수 대상: 결정 게이트 (kty-claude-harness-template, feat/decision-gate)
+
+너는 독립 코드 검수자다. **파일을 생성·삭제·수정하지 마라.** 샌드박스가 `mktemp`·`rm` 을
+거부하므로 시도하면 판정 없이 끝난다. **정적 독해만으로 판정하고, 반드시 마지막에
+`판정: 통과` 또는 `판정: 보류` 줄을 내라.** 그 줄이 없으면 이 라운드는 미수행으로 센다.
+
+## 무엇을 만들었나
+
+Stop 훅에 **결정 게이트**를 추가했다. 다른 완료 게이트 넷은 전부 *산출물*을 보는데
+(타입체크·듀얼리뷰·변경설명·지식반영), 이것만 **에이전트 자신의 행동**을 본다.
+
+    코드/결정 변경 플래그가 서 있고
+      AND 이 턴에 AskUserQuestion 도구 호출이 0회이고
+      AND 에이전트 발화에 "결정 표지 어휘"를 담은 서술형 문장이 있으면
+    -> 턴 종료 차단(rc=2) + 걸린 문장을 목록으로 출력
+
+겨누는 실패: 게이트가 막을 때는 따르면서, 게이트가 없는 자리에서는 혼자 정하고
+보고서에 한 줄 적는 것. 그 "한 줄"은 도구 호출이 아니라 문장이라 어떤 PreToolUse
+훅도 못 보고 승인창도 안 뜬다.
+
+## 읽을 파일 (전부 저장소 안)
+
+- `template/.claude/hooks/_common.sh` — `decision_scan()` (파일 끝). python3 스캐너
+- `template/.claude/hooks/verify-before-stop.sh` — 게이트 절 `(3.2)` + `transcript_path` 추출 + `(6)` 의 note 출력
+- `tests/decision-gate.test.sh` — 회귀 48건
+- `_workspace/mutate-decision-gate.sh` — 변이 24건 (전건 적색 측정 완료)
+- `docs/decisions/2026-08-10-decision-gate.md` — ADR-0012 (설계 근거·기각 대안·공시)
+- `_workspace/08_decision-gate.diff` — 전체 diff (main=dd6be57 기준)
+
+## 설계 의도 (이걸 반박해도 좋다 — 근거를 대라)
+
+1. **위양성이 여기서는 위음성만큼 비싸다.** 형제 검사기(`check-layer-boundary`,
+   `guard-hook-disable`)는 전부 위양성 쪽으로 기우는데 이것만 반대로 좁혔다. 이유:
+   위양성 비용이 "메시지 한 번"이 아니라 사용자에게 가는 불필요한 질문이고, 반복되면
+   질문이 소음이 되어 진짜 질문도 무시된다. 게다가 이 게이트의 훅·테스트·ADR 이 그
+   어휘를 데이터로 품어서, 어휘만 보면 게이트를 유지보수하는 작업 자체가 매번 걸린다.
+2. **좁히는 장치 넷**: 구조적 제외(코드펜스·인라인코드·인용줄·따옴표 안) · 질문 신호
+   제외 · 서술형 종결 요구 · 도구 입력 미스캔(발화 text 블록만). thinking·서브에이전트도 제외.
+3. **fail-open 을 하나 뒀다(rc=2 경로).** 대화 기록 형식은 하네스 소유가 아니라 예고
+   없이 바뀔 수 있고, 그때 차단하면 그 세션 안에 고칠 방법이 없어(기록을 고칠 수 없다)
+   세션이 통째로 벽돌이 된다. 조건은 사유를 마지막 게이트 메시지에 싣는 것.
+4. **탈출구를 뒀다**(`ECC_DISABLED_HOOKS=stop:decision`). `guard-hook-disable` 은 안 뒀는데
+   그건 "끄면 나머지를 전부 끌 수 있어서"이고, 이건 꺼도 나머지가 산다.
+5. **순서**: 타입체크 다음, 듀얼리뷰 앞. 질문의 답이 코드를 바꿀 수 있으므로 앞이다.
+
+## 특히 봐 달라
+
+- **위음성**: 자백이 통과하는 경로. 표지 어휘를 담은 정당한 자백인데 안 걸리는 형태
+- **위양성 폭증**: 정상 발화가 막히는 경로. 특히 정규식·문장 분할·구조적 제외의 경계
+- **fail-open 신설**: 의도한 rc=2 말고 **조용히 통과하는** 경로가 또 있나
+  (python 예외 · awk/셸 rc 삼킴 · 빈 출력 오독 · `$(...)` 의 후행 개행 · `set -uo pipefail` 상호작용)
+- **셸/파이썬 이식성**: macOS bash 3.2 · GNU/BSD 차이 · python3 버전 차이 · locale
+- **기존 게이트 회귀**: 이 절이 앞뒤 게이트(조기 종료·예산·지문·push 탐지)에 준 영향
+- **테스트가 실제로 무엇을 붙드나**: 통과를 위한 통과 케이스 · 기대값이 결함을 요구하는 것
+- ADR 이 검증 범위보다 **넓게 약속**하고 있지 않은가 (거짓 공시가 남은 결함보다 나쁘다)
+
+## 형식
+
+지적마다 `[등급] 파일:줄 — 무엇이/왜/어떻게`. 등급은 CRITICAL·HIGH·MEDIUM·LOW.
+근거 없는 추측은 `추정`이라고 명시해라. 마지막 줄에 반드시 `판정: 통과|보류`.
diff --git a/_workspace/08_codex_review.md b/_workspace/08_codex_review.md
new file mode 100644
index 0000000..792c221
--- /dev/null
+++ b/_workspace/08_codex_review.md
@@ -0,0 +1,3005 @@
+Reading additional input from stdin...
+2026-08-10T07:20:55.773534Z ERROR codex_models_manager::cache: failed to load models cache: missing field `supports_reasoning_summaries` at line 93 column 5
+OpenAI Codex v0.144.5
+--------
+workdir: /Users/kty/Downloads/kty-claude-harness-template
+model: gpt-5.6-sol
+provider: openai
+approval: never
+sandbox: read-only
+reasoning effort: high
+reasoning summaries: none
+session id: 019fea8b-c3f4-7253-b141-ee630dc7696a
+--------
+user
+# 검수 대상: 결정 게이트 (kty-claude-harness-template, feat/decision-gate)
+
+너는 독립 코드 검수자다. **파일을 생성·삭제·수정하지 마라.** 샌드박스가 `mktemp`·`rm` 을
+거부하므로 시도하면 판정 없이 끝난다. **정적 독해만으로 판정하고, 반드시 마지막에
+`판정: 통과` 또는 `판정: 보류` 줄을 내라.** 그 줄이 없으면 이 라운드는 미수행으로 센다.
+
+## 무엇을 만들었나
+
+Stop 훅에 **결정 게이트**를 추가했다. 다른 완료 게이트 넷은 전부 *산출물*을 보는데
+(타입체크·듀얼리뷰·변경설명·지식반영), 이것만 **에이전트 자신의 행동**을 본다.
+
+    코드/결정 변경 플래그가 서 있고
+      AND 이 턴에 AskUserQuestion 도구 호출이 0회이고
+      AND 에이전트 발화에 "결정 표지 어휘"를 담은 서술형 문장이 있으면
+    -> 턴 종료 차단(rc=2) + 걸린 문장을 목록으로 출력
+
+겨누는 실패: 게이트가 막을 때는 따르면서, 게이트가 없는 자리에서는 혼자 정하고
+보고서에 한 줄 적는 것. 그 "한 줄"은 도구 호출이 아니라 문장이라 어떤 PreToolUse
+훅도 못 보고 승인창도 안 뜬다.
+
+## 읽을 파일 (전부 저장소 안)
+
+- `template/.claude/hooks/_common.sh` — `decision_scan()` (파일 끝). python3 스캐너
+- `template/.claude/hooks/verify-before-stop.sh` — 게이트 절 `(3.2)` + `transcript_path` 추출 + `(6)` 의 note 출력
+- `tests/decision-gate.test.sh` — 회귀 48건
+- `_workspace/mutate-decision-gate.sh` — 변이 24건 (전건 적색 측정 완료)
+- `docs/decisions/2026-08-10-decision-gate.md` — ADR-0012 (설계 근거·기각 대안·공시)
+- `_workspace/08_decision-gate.diff` — 전체 diff (main=dd6be57 기준)
+
+## 설계 의도 (이걸 반박해도 좋다 — 근거를 대라)
+
+1. **위양성이 여기서는 위음성만큼 비싸다.** 형제 검사기(`check-layer-boundary`,
+   `guard-hook-disable`)는 전부 위양성 쪽으로 기우는데 이것만 반대로 좁혔다. 이유:
+   위양성 비용이 "메시지 한 번"이 아니라 사용자에게 가는 불필요한 질문이고, 반복되면
+   질문이 소음이 되어 진짜 질문도 무시된다. 게다가 이 게이트의 훅·테스트·ADR 이 그
+   어휘를 데이터로 품어서, 어휘만 보면 게이트를 유지보수하는 작업 자체가 매번 걸린다.
+2. **좁히는 장치 넷**: 구조적 제외(코드펜스·인라인코드·인용줄·따옴표 안) · 질문 신호
+   제외 · 서술형 종결 요구 · 도구 입력 미스캔(발화 text 블록만). thinking·서브에이전트도 제외.
+3. **fail-open 을 하나 뒀다(rc=2 경로).** 대화 기록 형식은 하네스 소유가 아니라 예고
+   없이 바뀔 수 있고, 그때 차단하면 그 세션 안에 고칠 방법이 없어(기록을 고칠 수 없다)
+   세션이 통째로 벽돌이 된다. 조건은 사유를 마지막 게이트 메시지에 싣는 것.
+4. **탈출구를 뒀다**(`ECC_DISABLED_HOOKS=stop:decision`). `guard-hook-disable` 은 안 뒀는데
+   그건 "끄면 나머지를 전부 끌 수 있어서"이고, 이건 꺼도 나머지가 산다.
+5. **순서**: 타입체크 다음, 듀얼리뷰 앞. 질문의 답이 코드를 바꿀 수 있으므로 앞이다.
+
+## 특히 봐 달라
+
+- **위음성**: 자백이 통과하는 경로. 표지 어휘를 담은 정당한 자백인데 안 걸리는 형태
+- **위양성 폭증**: 정상 발화가 막히는 경로. 특히 정규식·문장 분할·구조적 제외의 경계
+- **fail-open 신설**: 의도한 rc=2 말고 **조용히 통과하는** 경로가 또 있나
+  (python 예외 · awk/셸 rc 삼킴 · 빈 출력 오독 · `$(...)` 의 후행 개행 · `set -uo pipefail` 상호작용)
+- **셸/파이썬 이식성**: macOS bash 3.2 · GNU/BSD 차이 · python3 버전 차이 · locale
+- **기존 게이트 회귀**: 이 절이 앞뒤 게이트(조기 종료·예산·지문·push 탐지)에 준 영향
+- **테스트가 실제로 무엇을 붙드나**: 통과를 위한 통과 케이스 · 기대값이 결함을 요구하는 것
+- ADR 이 검증 범위보다 **넓게 약속**하고 있지 않은가 (거짓 공시가 남은 결함보다 나쁘다)
+
+## 형식
+
+지적마다 `[등급] 파일:줄 — 무엇이/왜/어떻게`. 등급은 CRITICAL·HIGH·MEDIUM·LOW.
+근거 없는 추측은 `추정`이라고 명시해라. 마지막 줄에 반드시 `판정: 통과|보류`.
+codex
+요청대로 어떤 파일도 변경하지 않고 정적 독해만 하겠습니다. 지정된 구현·테스트·변이·ADR·전체 diff를 서로 대조해, 특히 조용한 fail-open과 정당한 자백의 위음성을 우선 추적하겠습니다.
+exec
+/bin/zsh -lc "pwd && rg --files -g 'AGENTS.md' -g '"'!node_modules'"' -g '"'!vendor'"'" in /Users/kty/Downloads/kty-claude-harness-template
+ exited 1 in 0ms:
+/Users/kty/Downloads/kty-claude-harness-template
+
+exec
+/bin/zsh -lc 'nl -ba template/.claude/hooks/verify-before-stop.sh' in /Users/kty/Downloads/kty-claude-harness-template
+ succeeded in 0ms:
+     1	#!/usr/bin/env bash
+     2	# Stop: 코드를 건드린 턴은 (1) 타입체크 통과 (2) change-explainer 실행
+     3	#       (3) completion-auditor 실행 없이는 끝낼 수 없다.
+     4	#
+     5	# 무한루프 가드: "같은 지점에서 진전 없이" MAX_BLOCKS(3)회까지만 막는다.
+     6	# 게이트를 하나 지울 때마다(차단 지문 변화) 카운터가 리셋되므로 순차 처리로는
+     7	# 소진되지 않는다. 소진되면 플래그를 지우고 통과시키되 사용자에게 큰 경고를
+     8	# 띄운다. 세션이 벽돌이 되는 것보다 낫다. 지문 파일을 못 쓰면 리셋 없는 구식
+     9	# 누적으로, 카운터 파일도 못 쓰면 stop_hook_active 로 폴백한다.
+    10	
+    11	set -uo pipefail
+    12	# shellcheck source=_common.sh
+    13	. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
+    14	
+    15	HOOK_ID="stop:verify"
+    16	hook_disabled "$HOOK_ID" && exit 0
+    17	
+    18	payload="$(cat)"
+    19	stop_active="$(printf '%s' "$payload" | json_get stop_hook_active)"
+    20	# 대화 기록 경로. 결정 게이트(3.2)가 이 턴의 발화를 읽는 데 쓴다. 비어 있거나 못 읽으면
+    21	# 그 게이트만 생략되고 **사유가 마지막 게이트 메시지에 실린다** — 조용히 사라지지 않는
+    22	# 것이 이 fail-open 의 조건이다(decision_scan 주석 참조).
+    23	transcript_path="$(printf '%s' "$payload" | json_get transcript_path)"
+    24	
+    25	# (0) push 미완 **탐지** — 조기 종료보다 **먼저** 해야 한다.
+    26	#     플래그를 다 처리해 지운 뒤가 바로 위험한 시점인데(29커밋을 잃은 그 상태),
+    27	#     아래 조기 종료가 먼저 걸리면 push 게이트는 영영 안 돈다(검수 [치명] 지적).
+    28	#     탐지만 여기서 하고 차단은 예산·지문 기계가 준비된 뒤에 한다.
+    29	push_unsent=""
+    30	push_branch=""
+    31	if ! hook_disabled "stop:push" && git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
+    32	  push_branch="$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)"
+    33	  if [ -n "$push_branch" ] && git -C "$PROJECT_DIR" remote get-url origin >/dev/null 2>&1; then
+    34	    if git -C "$PROJECT_DIR" rev-parse --verify -q "refs/remotes/origin/$push_branch" >/dev/null 2>&1; then
+    35	      # rc 를 따로 본다. 실패를 "ahead 0" 으로 읽으면 게이트가 조용히 사라진다([cx] 지적).
+    36	      if push_n="$(git -C "$PROJECT_DIR" rev-list --count "refs/remotes/origin/$push_branch..HEAD" 2>/dev/null)"; then
+    37	        [ -n "$push_n" ] && [ "$push_n" != "0" ] && push_unsent="원격보다 ${push_n}개 앞서 있습니다"
+    38	      else
+    39	        push_unsent="원격과의 차이를 셀 수 없습니다(저장소 상태 이상) — 직접 확인하세요"
+    40	      fi
+    41	    elif git -C "$PROJECT_DIR" rev-parse --verify -q HEAD >/dev/null 2>&1; then
+    42	      # ref 가 없다. 다만 **HEAD 가 이미 다른 원격 브랜치에 있으면** 새 커밋이 없는
+    43	      # 갓 만든 브랜치이므로 요구하지 않는다 — 안 그러면 브랜치를 파자마자 막힌다.
+    44	      # 파이프 안 서브셸에서 exit 로 신호하면 그 rc 가 밖으로 안 나온다 — 실제로 그렇게
+    45	      # 짰다가 조건이 항상 거짓이 됐다. 서브셸 없는 for 루프로 판정한다(ref 이름에는
+    46	      # 공백이 못 들어가므로 단어 분리가 안전하다).
+    47	      head_on_remote=0
+    48	      for _r in $(git -C "$PROJECT_DIR" for-each-ref --format='%(refname)' refs/remotes 2>/dev/null); do
+    49	        if git -C "$PROJECT_DIR" merge-base --is-ancestor HEAD "$_r" 2>/dev/null; then
+    50	          head_on_remote=1; break
+    51	        fi
+    52	      done
+    53	      if [ "$head_on_remote" -eq 0 ]; then
+    54	        push_unsent="이 브랜치의 원격 추적 ref 가 없습니다 (한 번도 push 되지 않았거나, refspec 이 좁혀져 보이지 않습니다)"
+    55	      fi
+    56	    fi
+    57	  fi
+    58	fi
+    59	
+    60	# (1) 코드 변경이 없는 턴 → 검사 전부 생략. 읽기 전용 질문에 타입체크를 돌리지 않는다.
+    61	#     두 게이트 플래그(감사·설명)가 모두 비어야 "할 일 없음"이다.
+    62	#     지식 플래그는 **게이트가 켜져 있을 때만** 할 일로 센다 — 껐는데 예전에 남은
+    63	#     플래그 파일이 읽기 전용 턴의 조기 종료를 막으면 안 된다.
+    64	if [ -z "$push_unsent" ] && [ ! -s "$AUDIT_FLAG" ] && [ ! -s "$EXPLAIN_FLAG" ] && ! knowledge_gate_active && [ ! -s "$DUALREVIEW_FLAG" ]; then
+    65	  rm -f "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
+    66	  exit 0
+    67	fi
+    68	
+    69	# (2) 카운터 확인 — 벽돌 방지, 진전 인지 리셋 (2026-08-03 [cx] 지적 반영)
+    70	# 카운터의 목적은 "갇힘 감지"이지 노력 예산이 아니다. 게이트가 4종으로 늘며 공유 카운터
+    71	# 3회로는 게이트를 순서대로 성실히 처리해도 마지막 감사 게이트 전에 소진되는 역설이 있었다.
+    72	# → 차단 지문(어느 게이트에서, 어떤 플래그 상태로 막혔나)이 지난 차단과 다르면 = 진전이면
+    73	#   카운터를 리셋한다. 같은 지문으로 MAX_BLOCKS회 = 진짜 갇힘일 때만 경고와 통과.
+    74	count=0
+    75	if [ -f "$BLOCK_COUNT" ]; then
+    76	  count="$(tr -dc '0-9' < "$BLOCK_COUNT" 2>/dev/null)"
+    77	fi
+    78	[ -z "$count" ] && count=0
+    79	prev_fp="$(cat "$BLOCK_FP" 2>/dev/null)"
+    80	# 지문 = 서 있는 플래그의 집합(내용 아님). 내용을 넣으면 갇힌 채 새 파일만 편집해도
+    81	# 리셋되고(무한 차단), cksum 충돌로 실제 진전이 리셋 안 될 수도 있다([cx] 지적).
+    82	flags_fp=""
+    83	[ -s "$AUDIT_FLAG" ]      && flags_fp="${flags_fp}a"
+    84	[ -s "$EXPLAIN_FLAG" ]    && flags_fp="${flags_fp}e"
+    85	knowledge_gate_active     && flags_fp="${flags_fp}k"
+    86	[ -s "$DUALREVIEW_FLAG" ] && flags_fp="${flags_fp}d"
+    87	# push 는 "몇 개 남았나"가 곧 진전이다. 지문에 안 넣으면 한 커밋씩 올리는 실제 진전이
+    88	# 같은 지문으로 세어져 예산이 소진되고, 그때 감사 플래그까지 함께 지워진다([cx] 지적).
+    89	[ -n "$push_unsent" ] && flags_fp="${flags_fp}p:${push_branch}:${push_unsent}"
+    90	new_fp=""
+    91	
+    92	gate_budget() {  # $1 = 게이트 식별자. 각 차단 지점이 메시지 출력 전에 호출한다.
+    93	  new_fp="$1|$flags_fp"
+    94	  # 지문을 기록할 수 있을 때만 리셋한다 — 지문 파일을 못 쓰는 환경에서 리셋하면
+    95	  # prev_fp가 영원히 비어 매번 1/3로 무한 차단된다([cx] 지적). 그 경우 리셋 없는
+    96	  # 구식 누적으로 동작해 3회 후 통과가 보장된다.
+    97	  if printf '%s\n' "$new_fp" > "$BLOCK_FP" 2>/dev/null; then
+    98	    if [ "$new_fp" != "$prev_fp" ]; then
+    99	      count=0   # 지난 차단과 다른 게이트/플래그 집합 = 진전 — 예산 리셋
+   100	    fi
+   101	  fi
+   102	  if [ "$count" -ge "$MAX_BLOCKS" ]; then
+   103	    changed="$(cat "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" 2>/dev/null | tr -d '"\\' | sort -u | tr '\n' ' ')"
+   104	    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null

2026-08-10T08:15:46.556262Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "git diff --stat 238a979..HEAD && git diff --unified=80 238a979..HEAD -- template/.claude/hooks/_common.sh template/.claude/hooks/verify-before-stop.sh tests/decision-gate.test.sh _workspace/mutate-decision-gate.sh docs/decisions/2026-08-10-decision-gate.md docs/usage.md && rg -n '"'^'"\\+?\\[(CRITICAL|HIGH|MEDIUM|LOW|치명|높음|중간|낮음)\\]|"'^'"\\+?판정:' _workspace/09_delta.diff | tail -40" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
 _workspace/08_codex_prompt.md                |   60 +
 _workspace/08_codex_review.md                | 3005 ++++++++++++++++++++++++++
 _workspace/08_decision-gate.diff             | 1325 ++++++++++++
 _workspace/mutate-decision-gate.sh           |  114 +-
 docs/decisions/2026-08-10-decision-gate.md   |   50 +-
 docs/usage.md                                |    9 +-
 template/.claude/hooks/_common.sh            |   62 +-
 template/.claude/hooks/verify-before-stop.sh |   50 +-
 tests/decision-gate.test.sh                  |  118 +-
 9 files changed, 4737 insertions(+), 56 deletions(-)
diff --git a/_workspace/mutate-decision-gate.sh b/_workspace/mutate-decision-gate.sh
index 51e485c..312b76c 100755
--- a/_workspace/mutate-decision-gate.sh
+++ b/_workspace/mutate-decision-gate.sh
@@ -1,273 +1,361 @@
 #!/usr/bin/env bash
 # 변이 주입 하네스 — tests/decision-gate.test.sh 가 **실제로 무엇을 붙드는지** 잰다.
 #
 # "44건 통과"는 아무것도 증명하지 않는다. 방어를 하나씩 지우고 그 케이스가 빨개지는지
 # 봐야 한다. 형제 하네스(mutate-harness-env.sh)와 같은 계약을 쓴다:
 #   · 대상 파일에 미커밋 변경이 있으면 **거부**한다 (restore 가 그것을 지운다)
 #   · 동시 실행을 락으로 막는다 (돌리는 중 커밋하면 변이가 커밋된다 — 실제로 당했다)
 #   · 치환이 **정확히 1회** 매치할 때만 진행한다 (앵커가 밀리면 빈 변이 = 거짓 초록)
 #   · 복원 뒤 **해시를 대조**한다 (git status 는 stat 캐시 때문에 못 믿는다)
 #
 # 이 게이트는 위양성도 치명적이라 **양방향으로** 잰다:
 #   A·C·D 방어를 지우면 → 막아야 할 것을 놓친다 (위음성 검출)
 #   B    좁히는 장치를 지우면 → 막으면 안 될 것을 막는다 (위양성 검출)
 #
 # CI 에 넣지 않는다. 검수·감사 때 손으로 돌리는 계측 도구다.
 # 사용법: ./_workspace/mutate-decision-gate.sh
 
 set -uo pipefail
 cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
 
 COMMON='template/.claude/hooks/_common.sh'
 STOP='template/.claude/hooks/verify-before-stop.sh'
 TESTS='./tests/decision-gate.test.sh'
 
 for f in "$COMMON" "$STOP"; do
   if ! git diff --quiet -- "$f" || ! git diff --cached --quiet -- "$f"; then
     echo "✗ $f 에 미커밋 변경이 있습니다." >&2
     echo "  이 하네스는 HEAD 로 restore 하므로 그 변경을 **지웁니다**. 먼저 커밋한 뒤 다시 재세요." >&2
     exit 1
   fi
 done
 
 LOCK="$(git rev-parse --git-dir)/mutate-decision-gate.lock"
 if ! mkdir "$LOCK" 2>/dev/null; then
   echo "✗ 이미 다른 변이 측정이 돌고 있습니다: $LOCK" >&2
   echo "  겹쳐 돌리면 주입된 변이가 커밋될 수 있습니다. 끝난 뒤 다시 재세요." >&2
   echo "  (그 프로세스가 죽었다면: rmdir '$LOCK')" >&2
   exit 1
 fi
-trap 'rmdir "$LOCK" 2>/dev/null' EXIT
+# **락만 걷어내는 트랩은 부족하다.** 측정 도중 SIGINT 로 끊기면 주입된 변이가 작업
+# 트리에 그대로 남고, 이 저장소는 **측정 중인 트리를 커밋해 변이가 섞여 들어간 사고를
+# 이미 겪었다.** 다음 실행이 dirty 검사로 거부해 주긴 하지만, 그 사이에 커밋하면 늦는다.
+# 대상 파일에 미커밋 변경이 없음은 위에서 이미 확인했으므로 restore 는 안전하다.
+cleanup() {
+  git restore --source=HEAD --worktree -- "$COMMON" "$STOP" 2>/dev/null
+  rmdir "$LOCK" 2>/dev/null
+}
+trap cleanup EXIT INT TERM
 
 restore_and_verify() {   # $1 = 파일
   git restore --source=HEAD --worktree -- "$1" || { echo "✗ restore 실패: $1" >&2; exit 1; }
   local have want
   have="$(git hash-object "$1")"
   want="$(git rev-parse "HEAD:$1")"
   if [ "$have" != "$want" ]; then
     echo "✗ 복원 검증 실패: $1 ($have ≠ $want) — 이후 측정은 전부 거짓입니다" >&2
     exit 1
   fi
 }
 
 # mutate <파일> <찾을 문자열> <바꿀 문자열> — 정확히 1번 매치할 때만 바꾼다.
 mutate() {
   python3 - "$1" "$2" "$3" <<'PY'
 import sys, io
 path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
 s = io.open(path, encoding='utf-8').read()
 if s.count(old) != 1:
     sys.stderr.write("  ! 변이 앵커가 %d 번 매치 (1 이어야 함): %r\n" % (s.count(old), old[:70]))
     sys.exit(1)
 io.open(path, 'w', encoding='utf-8').write(s.replace(old, new))
 PY
 }
 
 total=0; caught=0; missed=0
 
 measure() {   # $1=이름 $2=파일 — 변이가 주입된 상태에서 재고 복원한다
   local out rc nfail
   out="$($TESTS 2>&1)"; rc=$?
   nfail="$(printf '%s\n' "$out" | grep -c '^  ✗')"
   restore_and_verify "$2"
   if [ "$rc" -ne 0 ] && [ "$nfail" -gt 0 ]; then
     caught=$((caught + 1))
     # cut -c 를 쓰지 않는다: BSD cut 은 **바이트**로 잘라 한글 중간을 끊고, 그러면 이 로그가
     # 유효한 UTF-8 이 아니게 되어 grep 이 바이너리로 취급하고 조용히 0건을 낸다(실측 적발).
     printf '  ✓ %-44s 적색 %2s건 · %s\n' "$1" "$nfail" \
       "$(printf '%s\n' "$out" | grep '^  ✗' | sed 's/^  ✗ //; s/ —.*//' | tr '\n' '/')"
   else
     missed=$((missed + 1))
     printf '  ✗ %-44s **초록** — 이 방어를 지켜주는 케이스가 없다\n' "$1"
   fi
 }
 
 run_mutation() {   # $1=이름 $2=파일 $3=찾을것 $4=바꿀것
   total=$((total + 1))
   if ! mutate "$2" "$3" "$4"; then
     printf '  ! %-44s 변이 주입 실패 (앵커 불일치)\n' "$1"
     restore_and_verify "$2"
     missed=$((missed + 1))
     return
   fi
   measure "$1" "$2"
 }
 
 echo '기준선 (변이 없음)'
 if ! $TESTS >/dev/null 2>&1; then
   echo '✗ 기준선이 이미 빨간불입니다. 변이 측정 이전에 고쳐야 합니다.' >&2
   $TESTS 2>&1 | grep '^  ✗'
   exit 1
 fi
 echo '  ✓ 전건 초록'
 echo
 echo '── A. 판정의 핵심을 지운다 (지우면 위음성 = 자백이 통과한다) ────────'
 
 run_mutation '게이트 자체를 무력화한다' "$STOP" \
   '  decision_hits="$(decision_scan "$transcript_path")"; decision_rc=$?' \
   '  decision_hits=""; decision_rc=1'
 
 run_mutation '질문 0회 조건을 지운다 (질문해도 안 풀린다)' "$COMMON" \
   'if asked > 0:
-    raise SystemExit(1)' \
+    raise SystemExit(3)' \
   '# (변이) 질문 판정 삭제'
 
 run_mutation '표지 판정을 지운다 (아무 문장이나 걸린다)' "$COMMON" \
   '            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):' \
   '            if not core:'
 
 run_mutation '걸린 문장을 메시지에 안 싣는다' "$STOP" \
   "      printf '%s\\n' \"\$decision_hits\" | sed 's/^/  - /'" \
   '      :'
 
 run_mutation '예산 호출을 지운다 (영원히 막힌다)' "$STOP" \
   '    gate_budget "decision"' \
   '    # (변이) gate_budget 호출 삭제'
 
 run_mutation '탈출구 판정을 지운다 (꺼도 안 꺼진다)' "$STOP" \
-  'if ! hook_disabled "stop:decision"; then' \
+  'if [ "$decision_armed" -eq 1 ] && ! hook_disabled "stop:decision"; then' \
   'if true; then'
 
 echo
 echo '── B. 좁히는 장치를 지운다 (지우면 위양성 = 정상 발화가 막힌다) ─────'
 
 run_mutation '인라인 코드 제외를 지운다' "$COMMON" \
   '        line = QUOTED.sub(" ", INLINE.sub(" ", line))' \
   '        line = QUOTED.sub(" ", line)'
 
 run_mutation '따옴표 인용 제외를 지운다' "$COMMON" \
   '        line = QUOTED.sub(" ", INLINE.sub(" ", line))' \
   '        line = INLINE.sub(" ", line)'
 
 run_mutation '인용줄 제외를 지운다' "$COMMON" \
   '        if BLOCKQUOTE.match(line):
             continue' \
   '        pass'
 
 run_mutation '코드펜스 제외를 지운다' "$COMMON" \
-  '    return "\n".join(p for i, p in enumerate(s.split("```")) if i % 2 == 0)' \
+  '    for fence in ("```", "~~~"):
+        s = "\n".join(p for i, p in enumerate(s.split(fence)) if i % 2 == 0)
+    return s' \
   '    return s'
 
 run_mutation '질문 신호 제외를 지운다' "$COMMON" \
-  '            if QUESTION.search(whole):
+  '            if QUESTION.search(whole) and not NEG_ASK.search(whole):
                 continue' \
   '            pass'
 
 run_mutation '서술형 종결 요구를 지운다' "$COMMON" \
   '            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):' \
   '            if not core or not MARKER.search(core):'
 
 run_mutation 'thinking 블록까지 스캔한다' "$COMMON" \
   '        elif b.get("type") == "text":
             t = b.get("text")
             if isinstance(t, str):
                 texts.append(t)' \
   '        elif b.get("type") in ("text", "thinking"):
             t = b.get("text") or b.get("thinking")
             if isinstance(t, str):
                 texts.append(t)'
 
 run_mutation '서브에이전트 발화까지 스캔한다' "$COMMON" \
   '    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):' \
   '    if not isinstance(e, dict) or e.get("type") != "assistant":'
 
 # 자기참조 폭발을 막는 핵심 장치다 — 이게 없으면 이 패턴이 적힌 파일을 쓰는 것만으로 막힌다.
 run_mutation '도구 입력까지 스캔한다 (자기참조 폭발)' "$COMMON" \
   '        if b.get("type") == "tool_use":
             if b.get("name") == "AskUserQuestion":
                 asked += 1' \
   '        if b.get("type") == "tool_use":
             if b.get("name") == "AskUserQuestion":
                 asked += 1
             else:
                 for _v in (b.get("input") or {}).values():
                     if isinstance(_v, str):
                         texts.append(_v)'
 
 echo
 echo '── C. 턴 경계를 흐린다 ─────────────────────────────────────────────'
 
 run_mutation '마지막이 아니라 첫 프롬프트를 경계로 삼는다' "$COMMON" \
   '    if isinstance(e, dict) and is_user_prompt(e):
         start = i' \
   '    if isinstance(e, dict) and is_user_prompt(e) and start < 0:
         start = i'
 
 # 두 판정을 **따로** 잰다. 실제 기록은 두 표식을 함께 갖고 있어서 한쪽만 지우면 다른 쪽이
 # 가려 준다 — 표식이 하나뿐인 픽스처(d25d·d25e)가 있어야 각각이 일하는지 보인다.
 run_mutation '상단 toolUseResult 판정을 지운다' "$COMMON" \
   '    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
         return False' \
   '    pass'
 
 run_mutation 'tool_result 블록 판정을 지운다' "$COMMON" \
   '    content = msg.get("content")
     if isinstance(content, list):
         for b in content:
             if isinstance(b, dict) and b.get("type") == "tool_result":
                 return False
     return True' \
   '    return True'
 
 echo
 echo '── D. fail-open 이 조용해지게 만든다 ───────────────────────────────'
 # 판독 불가를 **통과시키는 것 자체는 설계**다. 문제는 그때 소리를 안 내는 것 —
 # 그러면 게이트가 죽은 것을 아무도 모르고, 그게 이 저장소가 부르는 조용한 실패다.
 
 run_mutation '판독 불가를 통과로 위장한다 (사유 소실)' "$COMMON" \
   'def fail(reason):
     sys.stdout.write(reason + "\n")
     raise SystemExit(2)' \
   'def fail(reason):
-    raise SystemExit(1)'
+    raise SystemExit(3)'
 
 run_mutation '판독 불가 사유를 안 실어 보낸다' "$STOP" \
   '    decision_note="결정 게이트 생략 ($decision_hits)"' \
   '    decision_note=""'
 
 run_mutation '판독 불가 사유를 안 출력한다' "$STOP" \
-  '  if [ -n "$decision_note" ]; then
-    echo
-    echo "참고: $decision_note"
-    echo "      → 이 턴에 사용자에게 물었어야 할 결정이 없었는지 스스로 확인하세요."
-  fi' \
-  '  :'
+  $'\n  emit_decision_note\n' \
+  $'\n  :\n'
 
 run_mutation '기록을 못 읽어도 조용히 넘어간다' "$COMMON" \
   "  [ -r \"\$path\" ] || { printf '%s\\n' \"대화 기록을 읽을 수 없습니다: \$path\"; return 2; }" \
-  '  [ -r "$path" ] || return 1'
+  '  [ -r "$path" ] || return 3'
 
 run_mutation '턴 시작점을 못 찾으면 전체를 훑는다' "$COMMON" \
   '    fail("이 턴의 시작점(사용자 프롬프트)을 찾지 못했습니다 (형식이 바뀌었을 수 있습니다)")' \
   '    start = -1'
 
+echo
+echo '── F. 듀얼 검수 1라운드 반영분 ([cx] 지적) ─────────────────────────'
+
+run_mutation '"묻지 않았다" 예외를 지운다 (자백이 샌다)' "$COMMON" \
+  '            if QUESTION.search(whole) and not NEG_ASK.search(whole):' \
+  '            if QUESTION.search(whole):'
+
+run_mutation '마침표를 무조건 종결로 되돌린다' "$COMMON" \
+  'SENT       = re.compile("([\n!?…。！？]+|\\.(?=\\s)|\\.$)")' \
+  'SENT       = re.compile("([\n.!?…。！？]+)")'
+
+run_mutation '물결 펜스 지원을 지운다' "$COMMON" \
+  '    for fence in ("```", "~~~"):' \
+  '    for fence in ("```",):'
+
+run_mutation '이중 백틱 지원을 지운다' "$COMMON" \
+  'INLINE     = re.compile("``[^`\n]*``|`[^`\n]*`")' \
+  'INLINE     = re.compile("`[^`\n]*`")'
+
+run_mutation '문자열 content 를 건너뛴다 (발화가 사라진다)' "$COMMON" \
+  '    if isinstance(content, str):
+        # 문자열 본문도 발화다. 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
+        texts.append(content)
+        continue' \
+  '    if isinstance(content, str):
+        continue'
+
+run_mutation '부분 손상을 건너뛴다 (전멸일 때만 실패)' "$COMMON" \
+  'if broken:
+    fail("대화 기록 %d줄을 파싱하지 못했습니다 (형식이 바뀌었을 수 있습니다)" % broken)
+if not entries:
+    fail("대화 기록이 비어 있습니다")' \
+  'if lines and not entries:
+    fail("대화 기록을 한 줄도 파싱하지 못했습니다")'
+
+run_mutation 'message 형식 검사를 지운다' "$COMMON" \
+  '    msg = e.get("message")
+    if not isinstance(msg, dict):
+        # truthy 비-dict 를 `or {}` 로 받으면 여기서 예외가 나고, 그 예외는 아래 "표지 없음"과
+        # 구별되지 않는 종료 코드로 나간다 — 조용한 통과다. 형식 변화로 보고 소리를 낸다.
+        fail("assistant 항목의 message 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")' \
+  '    msg = e.get("message") or {}
+    if False:
+        pass'
+
+run_mutation 'content 형식 검사를 지운다' "$COMMON" \
+  '    if not isinstance(content, list):
+        # 볼 수 없는 발화가 있다 = 사각지대다. 조용히 건너뛰면 게이트가 죽은 줄도 모른다.
+        fail("assistant 항목의 content 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")' \
+  '    if not isinstance(content, list):
+        continue'
+
+# **예상 밖 rc 를 통과로 읽던 경로.** 정상 경로가 모르는 코드를 내게 만들면, 호출부의
+# catch-all 이 살아 있는 한 위양성 케이스들이 "판독 불가 경고"를 보고 빨개진다.
+# 그 catch-all 을 지우면 이 변이가 초록으로 남는다 — 그게 이 항목이 재는 것이다.
+run_mutation '정상 경로가 예상 밖 rc 를 낸다 (호출부 catch-all 검출)' "$COMMON" \
+  'if not hits:
+    raise SystemExit(3)' \
+  'if not hits:
+    raise SystemExit(9)'
+
+# **공시된 측정 공백:** 호출부의 `*)` catch-all 만 지우는 변이는 **원리적으로 초록**이다.
+# 정상 동작에서는 예상 밖 rc 가 나오지 않으므로 그 가지에 도달하는 입력이 없기 때문이다
+# (python3 를 없애면 json_get 이 먼저 죽어 transcript_path 가 비고, 그러면 rc=2 경로로
+# 빠져 catch-all 을 안 탄다). 그래서 바로 위 항목 — **정상 경로가 rc=9 를 내게 만드는
+# 변이** — 가 그 가지의 생존을 대신 증명한다: catch-all 이 살아 있으면 위양성 케이스들이
+# 판독 불가 경고를 보고 빨개지고, catch-all 을 지우면 그 변이가 초록으로 돌아선다.
+# 두 항목은 짝이다. 하나만 보고 판단하지 마라(위음성 카탈로그 17번).
+
+run_mutation '발동을 플래그가 아니라 조기 종료에 맡긴다' "$STOP" \
+  'if [ -s "$AUDIT_FLAG" ] || [ -s "$EXPLAIN_FLAG" ] || [ -s "$DUALREVIEW_FLAG" ] || knowledge_gate_active; then
+  decision_armed=1
+fi' \
+  'decision_armed=1'
+
+# 앞 게이트에서 사유를 빼면 d51 만 빨개져야 한다. 함수를 통째로 무력화하면 판독 불가
+# 케이스가 전부 빨개져서 "앞 게이트에도 실리는가"를 격리해 재지 못한다.
+run_mutation '앞 게이트(듀얼리뷰)에서 사유를 뺀다' "$STOP" \
+  '    emit_decision_note
+    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"' \
+  '    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"'
+
 echo
 echo '── E. 순서 계약 — 게이트를 뒤로 옮긴다 ─────────────────────────────'
 # 지우는 것과 옮기는 것은 다른 측정이다. 지우면 "게이트 없음"을 재고, 옮겨야
 # "순서가 틀림"을 잰다. 질문의 답이 코드를 바꿀 수 있으므로 앞이어야 한다.
 total=$((total + 1))
 if python3 - "$STOP" <<'PY'
 import io, sys
 path = sys.argv[1]
 s = io.open(path, encoding='utf-8').read()
 head, mid, after = '# (3.2) **결정 게이트**', '# (3.5) 듀얼 리뷰', '# (6) 타입체크는 통과했지만'
 for tok in (head, mid, after):
     if s.count(tok) != 1:
         sys.stderr.write('  ! 이동 앵커 매치 수 이상: %r=%d\n' % (tok, s.count(tok)))
         sys.exit(1)
 start, end = s.index(head), s.index(mid)
 block = s[start:end]
 s = s[:start] + s[end:]
 io.open(path, 'w', encoding='utf-8').write(s.replace(after, block + after))
 PY
 then
   measure '게이트를 감사 직전으로 옮긴다' "$STOP"
 else
   printf '  ! %-44s 변이 주입 실패 (앵커 불일치)\n' '게이트를 감사 직전으로 옮긴다'
   restore_and_verify "$STOP"
   missed=$((missed + 1))
 fi
 
 echo
 echo "— 변이 ${total}건 중 ${caught}건 적색 / ${missed}건 초록(미방어)"
 [ "$missed" -eq 0 ] || exit 1
diff --git a/docs/decisions/2026-08-10-decision-gate.md b/docs/decisions/2026-08-10-decision-gate.md
index c3d45c3..5774d41 100644
--- a/docs/decisions/2026-08-10-decision-gate.md
+++ b/docs/decisions/2026-08-10-decision-gate.md
@@ -1,134 +1,170 @@
 # ADR-0012: 게이트가 대화를 읽는다 — 자백은 있는데 질문이 없으면 막는다
 
 **Date**: 2026-08-10
 **Status**: accepted
 **Deciders**: 김태윤(요구·판단·확정 3건), Claude(설계·실측)
 
 ---
 
 ## Context
 
 [ADR-0011](2026-08-10-self-discipline-gates.md)이 게이트 둘을 에이전트 자신에게 겨눴고, **가장 큰 공백을 열어 둔 채 닫았다**:
 
 > **"혼자 정하고 보고서에 한 줄 적는" 부류는 아직 안 막혔다.** 그건 도구 호출이 아니라 문장이라 어떤 PreToolUse 훅도 못 본다.
 
 그 부류가 무엇인지는 실측으로 남아 있다. ADR-0006 이행 세션에서 Stop 훅이 세 번 막았고 세 번 다 따랐는데, 게이트가 없는 자리에서는 전부 혼자 정했다 — 기존 설정의 동작을 바꾸면서 묻지 않았고, 기록된 사용자 선호와 어긋난 상태를 발견하고 넘겼고, 다른 훅이 26번 막는 동안 선택지를 주지 않고 보고만 했다.
 
 **승인 모드는 이걸 대체하지 못한다.** 승인창은 *한 일*에만 뜬다. 안 한 일(질문)은 원리적으로 안 잡힌다. 같은 세션에서 다른 훅이 26번 승인을 요구했는데 혼자 결정하는 것은 **한 번도** 막지 못했다.
 
 ## Decision
 
 **Stop 훅이 이 턴의 대화 기록을 직접 읽어 판정한다.**
 
 ```
 코드/결정 변경 플래그가 서 있고
   AND 이 턴에 AskUserQuestion 이 0회이고
   AND 발화에 결정 표지 어휘를 담은 서술형 문장이 있으면
 → 턴 종료 차단 + 걸린 문장을 목록으로 출력
 ```
 
 **표지 어휘**(사용자가 지정): 공시하고 · 범위 밖 · 별도로 · 그대로 뒀 · 제 판단으로 · 가정하고 · 수용된 한계 · 트레이드오프 · 안 했습니다.
 
 이 조합이 강한 이유는 저 말들이 **"물어봤어야 할 것을 혼자 정했다"를 자백할 때만** 나온다는 것이다. 자백은 있는데 질문이 0회면 그 자체가 위반이다. 그리고 **질문 한 번이면 풀린다** — 세션이 벽돌이 되지 않는다.
 
 ### ① 위양성이 여기서는 위음성만큼 비싸다
 
 이 저장소의 다른 검사기들은 전부 위양성 쪽으로 기운다(`check-layer-boundary` · `guard-hook-disable`). *"위양성은 메시지 한 번이 비용이고 위음성은 방어가 꺼진 걸 아무도 모르는 것이 비용"* 이기 때문이다.
 
 **이 게이트는 그 계산이 다르다.** 위양성의 비용이 메시지 한 번이 아니라 **사용자에게 가는 불필요한 질문**이고, 그게 반복되면 질문이 소음이 되고, 소음이 되면 **진짜 질문도 무시된다.** 게이트가 스스로를 무력화하는 경로다.
 
 그리고 위양성의 가장 큰 원천이 **자기참조**다 — 이 게이트의 훅·테스트·이 ADR 이 전부 그 어휘를 데이터로 품는다. 어휘만 보면 **이 게이트를 유지보수하는 작업 자체가 매번 걸리고**, 그러면 사람이 게이트를 끈다. 꺼진 게이트는 없는 게이트다.
 
 그래서 좁히는 장치 셋을 둔다:
 
 1. **구조적 제외** — 코드펜스 · 인라인 코드 · 인용줄 · 따옴표로 감싼 부분은 안 본다. 어휘를 인용부호로 감싸 언급하는 것은 문서·설명의 정상 형태다
 2. **질문 신호 제외** — 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다
 3. **서술형 종결 요구** — 단정으로 끝나야 "내가 그렇게 했다"이다
 
 그리고 **도구 입력을 보지 않는다(발화 텍스트만 본다).** 이 패턴이 적힌 파일을 쓰는 것 자체는 결정이 아니므로 자기참조 폭발이 **원천에서** 없어진다. 사고 블록도 안 본다(저울질은 통보가 아니다). 서브에이전트 발화도 뺀다(서브에이전트는 사용자에게 물을 수 없다).
 
 **대가는 위음성 증가다.** 표현을 조금 바꾸면 빠져나간다. 그럼에도 값을 하는 이유는 겨누는 것이 적대적 회피가 아니라 **무의식적 습관**이기 때문이다 — `guard-hook-disable` 이 "막힌 에이전트의 직진 충동"을 겨눈 것과 같은 판단 구조다.
 
-### ② fail-open 은 한 곳뿐이고, 소리를 낸다
+### ①-1 어휘는 **표본**이지 분류법이 아니다 (2026-08-10 사용자 지적)
+
+저 9개는 원리에서 유도한 것이 아니라 **한 세션에서 LLM 이 실제로 쓴 문장을 관찰해 뽑은 것**이다. 사용자가 이 점을 짚었다 — *"어차피 내가 쓴 게 아니고 LLM 이 내가 말할 걸 정리해서 쓰는 것이라 그것에서 비롯한 문제가 또 발생할 것 같은데."*
+
+맞는 지적이고, 결론을 바꾼다. **목록을 좁히지 않는다.** 좁히는 규칙도 결국 같은 출처의 추측이라 추측 위에 추측을 쌓는 일이 된다. 검수가 "`별도로`·`트레이드오프` 는 단순 기술 서술에도 나온다"고 정당하게 지적했지만(→ Consequences 의 위양성 항목), 그 대응으로 어휘에 조건을 붙이는 것은 문제를 줄이는 게 아니라 **다른 자리로 옮기는 것**이다.
+
+대신 **주장을 사실에 맞춘다**:
+
+- 이것은 **관찰된 표현에 맞춘 과속방지턱**이지 "말하지 않은 결정"의 탐지기가 아니다
+- **영어 발화는 하나도 못 본다.** 표지가 전부 한국어다 — 커버리지 0인 축이 통째로 있다
+- 목록은 **새는 것을 실제로 본 뒤에만** 늘린다. 이 저장소가 게이트를 만드는 방식 그대로다(*"선제 방어는 하지 않는다 — 실제로 겪은 뒤에 강제를 추가한다"*)
+
+**어휘를 사용자 슬롯으로 빼지 않는다.** 언어·모델마다 다를 테니 그럴싸하지만, 실제로 새는 것을 보기 전에 설정을 늘리는 것은 같은 YAGNI 규칙에 걸린다. 새는 게 관측되면 그때 뺀다.
+
+### ② fail-open 은 판독 불가 하나이고, 소리를 낸다
 
 이 저장소의 원칙은 *"검사기의 유일한 치명 결함은 위음성"* 이고 애매하면 전부 fail-closed 다. **이 게이트에 예외를 하나 둔다.**
 
 대화 기록의 형식은 **하네스가 소유하지 않는다** — 도구 제공자가 정하고 예고 없이 바뀐다. 형식이 바뀌었다고 차단하면 **그 세션 안에 고칠 방법이 없다**: 기록을 고칠 수는 없으므로 어떤 행동으로도 게이트가 안 풀리고, 세션이 통째로 벽돌이 된다. 다른 게이트는 전부 "무언가를 하면 풀리는" 구조라 이 문제가 없다.
 
-**조건은 경고를 삼키지 않는 것이다.** 판독에 실패하면 사유가 마지막 게이트 메시지에 실린다. 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다. 그 침묵 자체를 변이 5건으로 붙들었다.
+**조건은 경고를 삼키지 않는 것이다.** 판독에 실패하면 사유가 **막는 게이트가 무엇이든 그 메시지에** 실린다. 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다.
+
+**초안은 이 약속을 지키지 못했고, 검수가 그것을 잡았다.** 처음에는 *"rc=2 가 유일한 fail-open"* 이라고 적었는데 사실이 아니었다 — 부분 손상·처리 못 한 예외·`python3` 부재가 전부 "표지 없음"과 **같은 종료 코드**로 나갔다. 고친 뒤의 계약은 이렇다:
+
+```
+0  차단     2  판독 불가(사유 있음)     3  차단 불필요     그 밖  → 판독 불가로 취급
+```
+
+정상 통과에 흔한 코드(1)를 **주지 않는 것**이 핵심이다. 그래야 크래시가 정상 통과로 위장되지 않는다. 그리고 사유는 **다섯 게이트 전부**에 싣는다 — 감사 게이트에만 실으면 앞 게이트가 먼저 막은 턴에 안 보이고, 그 플래그를 지운 다음 턴에는 조기 종료로 영영 사라진다.
 
 ### ③ 사용자 확정 3건 (2026-08-10)
 
 | 물은 것 | 확정 | 근거 |
 |---|---|---|
 | 탈출구를 둘까 | **둔다** (`ECC_DISABLED_HOOKS=stop:decision`) | 위양성이 구조적으로 나므로 사용자가 즉시 뺄 수 있어야 한다. 끄는 대입 자체는 `guard-hook-disable` 이 한 번 세운다 |
 | 어느 턴에서 도나 | **코드 + 결정 문서 + 설계 산출물** | 표지 어휘가 가장 자주 나오는 자리가 결정 문서를 쓰는 턴이다 |
 | 패턴을 얼마나 좁히나 | **좁힌 서술형 + 구조적 제외** | 자기참조 폭발을 막는 유일한 길 |
 
 **탈출구 유무가 `guard-hook-disable` 과 갈리는 이유**를 적어 둔다. 그쪽은 *"탈출구가 있으면 그것으로 나머지를 전부 끌 수 있어서"* 두지 않았다. 이쪽은 그렇지 않다 — 이 게이트를 꺼도 나머지 게이트는 그대로 살아 있고, 반대로 위양성으로 막혔을 때 사용자가 뺄 수단이 없으면 세 번 헛돌아야 한다. **비대칭이 다르면 답도 다르다.**
 
 ### ④ 순서 — 다른 게이트보다 앞이다
 
 질문의 답이 코드를 바꿀 수 있으므로 리뷰·설명·감사에 노력을 쓰기 전에 묻는 편이 싸다.
 
 `stop:push` 의 "탐지가 조기 종료보다 앞"과는 성격이 다르다. 그건 **정확성** 문제였다(뒤에 두면 게이트가 영영 안 돈다). 이건 **비용** 문제다 — 대화 기록은 이미 다 쓰였고 게이트 순서가 그 내용을 바꾸지 않는다. 그래도 계약으로 고정하고, 지우는 변이가 아니라 **옮기는 변이**로 잰다(지우면 "게이트 없음"을 재는 것이지 "순서가 틀림"을 재는 것이 아니다).
 
 ## Alternatives Considered
 
 ### A. 단순 어휘 목록, 위양성 쪽으로 기운다 (집안 표준)
 - **Pros**: 단순하다. 위음성이 거의 없다. 형제 검사기들과 판단이 일관된다
 - **Cons**: 자기참조가 폭발한다 — 이 게이트를 손대는 모든 작업, 이 ADR 을 쓰는 턴, 회수 정책 ADR 을 쓰는 턴이 전부 걸린다
 - **Why not**: 그 상태의 종착지는 **사람이 게이트를 끄는 것**이다. 다른 검사기는 CI 에서 한 번 걸리고 끝이지만 이건 대화마다 걸린다
 
 ### B. 산문 질문도 질문으로 센다
 - **Pros**: "이대로 갈까요?"로 끝나는 정직한 보고가 안 막힌다
 - **Cons**: 게이트가 물음표 하나로 뚫린다. 그리고 막으려는 것이 정확히 **"보고서에 한 줄 적고 넘어가기"** 인데, 그 한 줄 끝에 물음표를 붙이는 것은 같은 행동이다
 - **Why not**: 사용자가 도구 호출을 기준으로 못박았다 — *"보고서에 적는 것은 묻는 것이 아니다"*
 
 ### C. 탈출구를 두지 않는다 (`guard-hook-disable` 방식)
 - **Pros**: 막힌 에이전트가 못 끈다
 - **Cons**: 사용자도 못 끈다. 구조적 위양성이 나는 게이트에서 이건 비싸다
 - **Why not**: ③의 비대칭 논거. 이 게이트를 꺼도 나머지는 산다
 
 ### D. 플래그와 무관하게 항상 검사한다
 - **Pros**: 순수 질의응답에서 혼자 정하는 것도 잡는다
 - **Cons**: 아무것도 안 바꾼 턴까지 막아 대화를 방해한다
 - **Why not**: 사용자 기각
 
 ## Consequences
 
 ### Positive
 - **"혼자 정하고 한 줄 적는" 부류가 처음으로 기계에 걸린다.** ADR-0011 이 남긴 가장 큰 공백이 닫힌다
 - 걸린 문장이 메시지에 실리므로 **무엇을 물어야 하는지**가 화면에 뜬다. 안 실으면 "일단 아무거나 물어서 풀자"가 되어 게이트가 의식(儀式)이 된다
 - 질문 한 번이면 풀린다 — 비용이 낮아 게이트를 끌 동기가 약하다
 
 ### Negative
 - **위음성이 있다.** 표현을 바꾸면 빠져나간다. 좁힌 대가이고, 겨누는 것이 적대적 회피가 아니라 습관이라 감수한다
-- **위양성이 남는다.** 서술형으로 끝나면서 이 어휘를 쓰는 정당한 문장은 걸린다. 인용부호로 감싸면 빠지고, 그 안내를 차단 메시지에 넣었다
-- **fail-open 이 하나 있다.** 대화 기록 형식이 바뀌면 게이트가 사라진다 — 통과하되 사유를 마지막 메시지에 싣는다
-- 대화 기록 형식에 **의존이 하나 생겼다.** 하네스가 소유하지 않는 형식이고, 바뀌면 위 fail-open 으로 떨어진다
+- **영어 발화는 커버리지 0이다.** 표지가 전부 한국어다. 축 하나가 통째로 비어 있다
+- **위양성이 남는다.** 표지 어휘는 자백에만 나오지 않는다 — 검수가 실례를 댔다: *"기존 스캐너는 범위 밖 입력을 거부합니다"* · *"변이 테스트는 별도로 실행됩니다"* · *"이 트레이드오프는 ADR 에 설명되어 있습니다"*. 전부 결정 통보가 아닌데 걸린다. **고치지 않기로 했다**(①-1) — 인용부호나 백틱으로 감싸면 빠지고, 질문 한 번이면 풀린다
+- **판독 불가는 통과다.** 대화 기록 형식이 바뀌면 게이트가 사라진다 — 통과하되 사유를 다섯 게이트 메시지에 싣는다
+- 대화 기록 형식에 **의존이 하나 생겼다.** 하네스가 소유하지 않는 형식이고, 바뀌면 위 경로로 떨어진다
+- **Stop 훅이 매 턴 대화 기록 전체를 읽는다.** 긴 세션에서 비용이 는다(현재 실측 범위에서는 문제없음)
 
 ### 공시된 한계 — 지식 게이트를 끄면 결정 문서 턴이 빠진다
 `HARNESS_KNOWLEDGE_GATE` 를 리터럴로 비운 환경에서는 **결정 문서만** 고친 턴이 조기 종료에 걸려 결정 게이트까지 도달하지 못한다. 기본값이 켜짐이라 기본 구성에서는 정상 발동한다.
 
 **고치지 않는다(사용자 확정).** 조기 종료가 지식 플래그를 게이트 켜짐일 때만 세는 것은 *"게이트를 껐는데 예전에 남은 플래그가 읽기 전용 턴의 조기 종료를 막는"* 문제를 막으려고 넣은 것이다. 결정 게이트를 위해 그걸 되돌리면 알려진 버그 부류가 되살아난다. **한계 자체를 케이스(d30b)로 붙들었다** — 이 동작이 바뀌면 그 케이스가 빨개진다.
 
 ## 기계적 장치
 
-`tests/decision-gate.test.sh` **48건** + CI 스텝. 차단 9 · 위양성 19 · 발동조건 6 · 판독불가 5 · 탈출구 3 · 벽돌방지 2 · 순서 1 · 턴경계 3.
+`tests/decision-gate.test.sh` **59건** + CI 스텝. 차단 · 위양성 · 발동조건 · 판독불가 8 · 탈출구 3 · 벽돌방지 2 · 순서 1 · 턴경계 5.
 
 **rc 만으로 판정하지 않는다.** 결정 게이트가 통과해도 뒤의 감사 게이트가 같은 rc=2 를 내므로, 어느 게이트가 말했는지는 **메시지로만** 갈린다. 그리고 통과를 기대하는 케이스는 감사 게이트가 **실제로 말했는지**를 함께 요구한다 — 안 하면 훅이 앞에서 죽어도 초록이 난다.
 
-`_workspace/mutate-decision-gate.sh` **변이 24건 전건 적색.** 방어 제거(위음성) · 좁히는 장치 제거(위양성) · 턴 경계 흐리기 · fail-open 침묵화 · 게이트 이동.
+`_workspace/mutate-decision-gate.sh` **변이 35건 전건 적색.** 방어 제거(위음성) · 좁히는 장치 제거(위양성) · 턴 경계 흐리기 · fail-open 침묵화 · 게이트 이동 · 검수 반영분.
+
+**공시된 측정 공백:** 호출부의 "모르는 rc" 처리만 지우는 변이는 **원리적으로 초록**이다 — 정상 동작에서 그 가지에 도달하는 입력이 없다(`python3` 를 없애면 `json_get` 이 먼저 죽어 경로가 비고, 그러면 다른 가지로 빠진다). 대신 *정상 경로가 모르는 rc 를 내게 하는* 변이가 그 가지의 생존을 증명한다. 두 항목이 짝이고 하나만 보면 오판한다.
 
 ### 변이가 잡은 것 둘 — 통과 개수로는 안 보였다
 
 1. **질문 신호 판정이 죽어 있었다.** 위양성 케이스들의 종결이 "…까요/…세요"라 **서술형 요구에서 이미 걸러져 질문 판정에 도달조차 하지 않았다.** 판정 *순서*가 케이스를 무력화한 것이라 어휘를 아무리 늘려도 안 잡힌다. 서술형으로 끝나면서 묻는 문장을 케이스로 넣어 살렸다.
 2. **턴 경계의 두 판정이 서로를 가렸다.** 실제 기록은 상단 `toolUseResult` 와 `tool_result` 블록을 **항상 함께** 갖고 있다(실측 69/69). 그래서 한쪽을 지워도 다른 쪽이 막아 준다. 표식이 하나뿐인 픽스처를 만들어 각각을 독립적으로 지키게 했다.
 
 앞은 **판정 순서**가, 뒤는 **데이터의 중복**이 방어를 가린 사례다. 둘 다 "케이스가 통과한다"가 "그 방어가 지켜진다"를 뜻하지 않는 부류이고, 변이 없이는 원리적으로 안 보인다.
 
+3차로 같은 부류가 하나 더 나왔다 — 검수 반영으로 **모르는 rc 를 판독 불가로 취급**하게 만들자, 그 catch-all 이 *개별* 판독 불가 검사들을 가려버렸다(그 검사를 지워도 크래시가 catch-all 에 걸려 경고가 나왔다). 판독 불가 케이스가 **사유 조각까지** 요구하게 고쳐서 각각을 다시 격리했다. **새 방어가 옛 방어를 가리는 것**도 이 부류다.
+
+### 검수가 잡은 것 — 공시가 사실이 아니었다
+
+codex 독립 검수 1라운드(판정 보류, HIGH 5 · MEDIUM 3 · LOW 1)가 이 ADR 초안의 **핵심 주장 하나를 반증했다.** *"rc=2 가 유일한 fail-open"* 이 사실이 아니었고, 조용히 통과하는 경로가 넷 더 있었다(부분 손상 · 모르는 rc · truthy 비-dict `message` · 문자열 `content`). 게다가 경고 자체가 감사 게이트에만 실려 **앞 게이트가 먼저 막으면 사라졌다** — 경고를 삼키지 않는 것이 이 fail-open 의 유일한 조건인데 그게 안 지켜지고 있었다.
+
+가장 값진 지적은 **겨누는 문장 자체가 빠져나간 것**이었다: *"사용자에게 물어보지 않고 제 판단으로 진행했습니다"* 가 `물어` 때문에 질문으로 오인돼 통과했다. **부정이 붙으면 물음이 아니라 자백이다.**
+
+*거짓 공시는 남은 결함보다 나쁘다* 를 이 ADR 이 스스로 어겼고, 독립 컨텍스트가 그것을 잡았다.
+
 ## 관련
 - [ADR-0011](2026-08-10-self-discipline-gates.md) — 이 게이트를 후속으로 남긴 곳
 - [ADR-0008](2026-08-06-knowledge-gate-default-on.md) — 게이트 기본값과 판독 계약
 - [ADR-0007](2026-08-06-gate-scope-by-file-identity.md) — 어느 편집이 게이트 대상인가
diff --git a/docs/usage.md b/docs/usage.md
index 2ccfc88..b020935 100644
--- a/docs/usage.md
+++ b/docs/usage.md
@@ -2,129 +2,136 @@
 
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
 2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략) · `HARNESS_KNOWLEDGE_GATE` (지식 저장소 반영 게이트. **기본 켜짐**이고, 끄는 방법은 **값을 비우는 것 하나뿐**이다 — `"off"`라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다).
 
 **`harness.env` 는 실행되지 않는다.** 확장자와 문법은 셸이지만 훅은 이 파일을 source 하지 않고 줄을 읽어 값만 뽑는다 — 1비트를 얻으려고 사용자 소유 셸 파일에 훅의 제어 흐름을 넘길 이유가 없기 때문이다(`exit 0` 한 줄로 완료 게이트 4종이 흔적 없이 사라진 실측이 있다). 대신 지원 문법이 좁다: **한 키는 정확히 한 번만**, 선언은 줄 **맨 앞**에서 시작, 값에 공백이 있으면 따옴표, 후행 주석은 따옴표 뒤에만. 어기면 그 키는 **미설정**으로 떨어지고 해당 검사가 생략된다(생략 사유는 완료 게이트 메시지에 적힌다). 전체 규칙은 `harness.env` 파일 첫머리에 있다.
 
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
 | guard-hook-disable | Bash 실행 전 | 에이전트가 `HARNESS_HOOKS`·`ECC_DISABLED_HOOKS`·`ECC_GATEGUARD` 를 끄려 할 때 한 번 세운다. **과속방지턱이지 방벽이 아니다** — 아래 참조. 탈출구가 **없다** |
 | guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
 | mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (코드는 4종 전부 · 설계·계획 산출물은 듀얼리뷰+지식 · 결정 문서는 지식만). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
 | verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → **혼자 정하지 않았나** → codex 듀얼리뷰 → change-explainer → **지식 저장소 반영** → **push 미완** → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
 
 **지식 저장소 게이트가 아는 것은 계약 하나뿐이다** — "지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다." **어디에 어떤 구조로 반영하는지는 하네스가 모른다.** 그건 사용자 층 설정(전역 `CLAUDE.md` 등)이 답하고, 하네스에는 켜짐/꺼짐 1비트만 있다. 그래서 지식 저장소를 바꿔도 하네스는 고치지 않고, 아예 안 쓰는 프로젝트에서도 그대로 돈다.
 
 **탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:decision`(결정 게이트만) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) / `stop:push`(push 게이트만) 나열.
 **`guard-hook-disable` 은 과속방지턱이지 보안 경계가 아니다.** 판정이 정규식 하나라 셸을 해석하지 못한다 — `read`+`export`, 따옴표로 쪼갠 `env 'X''=off'`, 변수 조립, `eval`, 생성한 스크립트 실행은 전부 통과한다(실측). 그럼에도 값을 하는 이유는 막으려는 것이 적대적 공격자가 아니라 **막힌 에이전트의 직진 충동**이고, 그건 `HARNESS_HOOKS=off ...` 라는 직진형으로 나오기 때문이다. 제대로 막으려면 셸 파서가 필요한데, 반쯤 만든 셸 파서는 안 만든 것보다 나쁘다(막힌다고 믿게 하면서 안 막는다 — 이 저장소가 `harness.env` 판독기에서 겪은 늪).
 
 **그래서 위양성 쪽으로 기운다.** 실행 구문과 인용문을 구분하지 않아 `git grep 'HARNESS_HOOKS=off'` 같은 정당한 검색도 막힌다. 의도된 선택이다 — 따옴표 안을 건너뛰면 위양성은 사라지지만 `bash -c 'HARNESS_HOOKS=off ...'` 가 뚫린다. 둘은 문자열로 구별되지 않는 같은 모호성의 양면이고, 위양성은 메시지 한 번이 비용이지만 위음성은 **게이트가 꺼진 걸 아무도 모르는** 것이 비용이다. 차단 메시지가 위양성일 때의 대안(패턴 쪼개기·Write 도구 사용)을 함께 안내한다.
 
 **그리고 환경변수로 끌 수 없다.** 그 탈출구가 있으면 에이전트가 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다. 사용자가 정말 끄려면 셸에서 직접 `export` 하고 세션을 새로 띄우거나 `settings.json` 배선을 지운다 — 둘 다 사람이 하는 행위다.
 
 **결정 게이트가 있는 이유:** 나머지 게이트는 전부 **산출물**을 본다("코드가 검증됐나", "설명이 나왔나"). 그런데 실측된 실패의 대부분은 산출물이 아니라 **행동**이었다 — 게이트가 막을 때는 세 번 다 따랐으면서, 게이트가 없는 자리에서는 전부 혼자 정하고 보고서에 한 줄 적었다. 그 "한 줄"은 도구 호출이 아니라 문장이라 승인창도 안 뜬다. 그래서 이 게이트만 **대화 기록을 직접 읽는다**: 코드·결정이 바뀐 턴에 결정 표지 어휘를 담은 서술형 문장이 있는데 `AskUserQuestion` 이 0회면 막고, 걸린 문장을 목록으로 보여준다. **질문 한 번이면 풀린다.**
 
 **여기서는 위양성도 위음성만큼 비싸다.** 다른 검사기와 판단이 갈리는 유일한 자리다 — 위양성의 비용이 메시지 한 번이 아니라 사용자에게 가는 **불필요한 질문**이고, 그게 반복되면 질문이 소음이 되어 진짜 질문까지 무시된다. 게다가 이 게이트의 훅·테스트·ADR 이 그 어휘를 데이터로 품어서, 어휘만 보면 **게이트를 유지보수하는 작업 자체가 매번 걸린다.** 그래서 좁힌다: 코드펜스·인라인 코드·인용줄·따옴표 안은 안 보고, 같은 문장에 물음이 있으면 세지 않고, 서술형 단정으로 끝나야 센다. **도구 입력도 안 본다**(발화 텍스트만) — 그 어휘가 적힌 파일을 쓰는 것 자체는 결정이 아니다. 사고 블록과 서브에이전트 발화도 뺀다.
 
-*걸렸는데 결정이 아니라면* 백틱이나 따옴표로 감싸면 빠진다. 그래도 걸리면 사용자에게 알리고 지시를 받는다. **대가는 위음성이다** — 표현을 바꾸면 빠져나간다. 겨누는 것이 적대적 회피가 아니라 무의식적 습관이라 그래도 실효가 남는다.
+*걸렸는데 결정이 아니라면* 백틱이나 따옴표로 감싸면 빠진다. 그래도 걸리면 사용자에게 알리고 지시를 받는다.
+
+**이건 탐지기가 아니라 과속방지턱이다.** 표지 어휘는 원리에서 유도한 분류법이 아니라 **한 세션에서 실제로 쓰인 문장을 관찰해 뽑은 표본**이다. 그래서:
+
+- 표현을 조금 바꾸면 **빠져나간다**(위음성). 겨누는 것이 적대적 회피가 아니라 무의식적 습관이라 그래도 실효가 남는다
+- **영어 발화는 하나도 못 본다.** 표지가 전부 한국어다 — 축 하나가 통째로 비어 있다
+- 반대로 그 어휘는 자백에만 나오지도 않는다. `변이 테스트는 별도로 실행됩니다` 같은 **단순 기술 서술도 걸린다.** 어휘에 조건을 덧붙여 좁히지 **않기로 했다** — 그 조건도 같은 출처의 추측이라 문제를 없애는 게 아니라 옮기는 것이기 때문이다
+- 목록은 **새는 것을 실제로 본 뒤에만** 늘린다. 이 저장소가 게이트를 만드는 방식 그대로다
 
 **대화 기록을 못 읽으면 막지 않고 통과시킨다 — 이 하네스에서 유일한 fail-open 이다.** 기록 형식은 하네스가 소유하지 않아 예고 없이 바뀔 수 있는데, 그때 차단하면 **그 세션 안에 고칠 방법이 없어 통째로 벽돌이 된다**(기록을 고칠 수 없으므로 어떤 행동으로도 안 풀린다). 대신 사유가 마지막 게이트 메시지에 실린다 — 조용히 통과하면 게이트가 죽은 것을 아무도 모른다. **공시된 한계:** `HARNESS_KNOWLEDGE_GATE` 를 비운 환경에서는 결정 문서만 고친 턴이 조기 종료에 걸려 이 게이트까지 오지 않는다(기본값이 켜짐이라 기본 구성에서는 정상 발동). 자세한 근거는 [ADR-0012](decisions/2026-08-10-decision-gate.md).
 
 **push 게이트가 있는 이유:** 이 저장소는 커밋 29개를 잃은 적이 있다. 코드는 다 짜여 있었고 "아직 PR 전이니까"라며 push 를 미뤘다. 게이트는 **네트워크를 쓰지 않는다** — 로컬 remote-tracking ref 만 본다. 원격에 있는데도 ref 가 안 보이면(`remote.origin.fetch` 가 좁혀진 경우) 그 사실을 사유에 적는다. push 여부가 로컬에서 안 보이는 것 자체가 위험이기 때문이다. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
 
 ### 완료 게이트 검사 범위 (mark-needs-audit)
 
 판정 **순서가 곧 계약**이다: 개행 가드 → 물리 경로 정규화 → 듀얼리뷰 판정 → 범위 판정 → 분류 → 기록.
 
 - **프로젝트 안** — `_workspace/`·`.claude/`·문서 `*.md`·`*.markdown`(대소문자 무관)는 제외. 나머지는 게이트 4종.
   단 **문서 제외에는 예외가 둘** 있다(동작을 정의하는 마크다운이라 코드로 취급한다):
   `.claude/` 에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`), 그리고
   **프로젝트 자신이 하네스 정본일 때의 `global-agents/*.md`**. 둘 다 `*.md` 제외보다 **먼저** 판정된다.
 - **프로젝트 밖 + 하네스 정본 저장소**(루트에 `template/.claude/` 존재) — 저장소 **전체**를 **프로젝트와 같은 규칙으로** 검사한다. `scripts/`·`install.sh`·`global-agents/*.md` 포함(전부 하네스 동작을 정의한다). "같은 규칙"이므로 위의 제외도 **그대로** 적용된다 — 정본 저장소 안이라도 `_workspace/`·`.claude/`·순수 문서는 게이트가 서지 않는다. 지금 읽고 있는 이 파일(`docs/usage.md`)이 그 예다.
 - **프로젝트 밖 + 그 외** — `.claude/`에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`)만. **git 저장소가 아니어도** 발화한다.
 - **설계·계획 산출물**(`_workspace/00_design*.md`·`01_plan*.md`) — 위치·git 여부와 무관하게 **듀얼리뷰 + 지식** 플래그를 세운다. 설계가 나온 턴을 반영 없이 끝내면 "왜 그렇게 정했나"가 그 자리에서 사라지고, 그 근거가 정확히 이 파일들이다.
 - **결정 문서**(`docs/decisions/*.md`) — 문서 제외의 **예외**로 **지식** 플래그만 세운다. 코드가 아니므로 타입체크·변경설명·감사는 과하다. **공시된 한계:** 결정 문서를 이 경로 밖에 두면 게이트가 서지 않는다 — 하네스는 자기가 아는 경로만 알 수 있다.
 - **밖 편집은 절대경로로 기록**한다. 상대경로로 적으면 프로젝트와 외부 저장소가 `README.md` 같은 흔한 경로를 공유할 때 감사자가 프로젝트 쪽 동명 파일을 보고 통과시킨다.
 - 플래그를 못 쓰거나 경로에 개행이 있으면 **차단하지 않고** `systemMessage`로 알린다(PostToolUse는 항상 exit 0). git 호출이 실패했는데 조상에 `.git`이 있으면 그 사실도 알린다 — 정본 저장소가 조용히 앵커 전용으로 강등되는 것을 사람이 알 수 있게.
 
 계약의 **기계 정본**은 `tests/mark-needs-audit.cases.sh`의 판정 표이고, 케이스 수는 같은 파일의 `EXPECTED_CASES`가 강제한다. CI가 PR마다 돌린다.
 
 ## 6. 트러블슈팅
 
 - **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: 결정 게이트(`AskUserQuestion` 으로 실제로 묻는다 — 지울 플래그가 없다) → codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 지식 저장소 반영(`.needs-knowledge`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
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
diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
index 3e8cadd..dd86615 100644
--- a/template/.claude/hooks/_common.sh
+++ b/template/.claude/hooks/_common.sh
@@ -239,232 +239,268 @@ END {
 }
 
 # 지식 반영 게이트가 켜져 있는가 (rc=0 켜짐 / rc=1 꺼짐).
 #
 # 하네스가 소유하는 것은 **계약 하나**뿐이다 — "지식 저장소가 설정돼 있으면, 결정·설계가
 # 나온 턴은 반영 없이 끝낼 수 없다." 어디에 어떤 구조로 반영하는지는 이 층이 모른다.
 # 그래서 필요한 것도 1비트뿐이고, 그 1비트를 얻으려고 파일을 실행하지 않는다.
 #
 # **기본이 켜짐인 것이 이 함수의 핵심이다.** 기존 설치본에는 이 키가 아예 없는데,
 # 없을 때 "꺼짐"으로 읽으면 하네스를 갱신하는 순간 게이트가 **조용히 꺼진다** — 사용자는
 # 지식이 쌓인다고 믿는데 그 턴부터 아무것도 안 남는다. 표명이 없으면 이전 동작을 보존한다.
 # 선언이 2개 이상이거나 문법 밖일 때도 같은 이유로 켠다(rc=1 → 켜짐).
 #
 # 끄는 방법은 **값을 리터럴로 비우는 것 하나뿐**이다: HARNESS_KNOWLEDGE_GATE=""
 # `="off"` 는 켜진 것으로 읽힌다 — 비어 있지 않기 때문이다. harness.env 주석에 명시돼 있다.
 harness_knowledge_gate_on() {
   local v
   v="$(harness_env_value HARNESS_KNOWLEDGE_GATE)" || return 0   # 값을 못 믿으면 켠다
   [ -n "$v" ]                                                   # 리터럴로 비었을 때만 꺼짐
 }
 
 # 지식 게이트가 이번 턴에 **발효 중인가** — 플래그가 섰고 게이트도 켜져 있는가.
 # 판정을 이 한 곳에 모은다. 두 군데서 따로 물으면 "게이트를 껐는데 남아 있던 플래그가
 # 읽기 전용 턴의 조기 종료를 막는" 종류의 어긋남이 생긴다.
 knowledge_gate_active() {
   [ -s "$KNOWLEDGE_FLAG" ] || return 1
   harness_knowledge_gate_on
 }
 
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
 
 # 이 턴의 대화 기록을 읽어 **"물어봤어야 할 것을 혼자 정했다"는 자백**을 찾는다.
 #
 # 왜 이런 게이트가 필요한가: 완료 게이트 넷(타입체크·듀얼리뷰·변경설명·지식반영)은 전부
 # **산출물**을 본다. 에이전트 자신의 행동을 겨눈 것은 없었고, 그 비대칭이 실물로 드러났다 —
 # 게이트가 막을 때는 세 번 다 따랐는데, 게이트가 없는 축에서는 전부 혼자 정하고 보고서에
 # 한 줄 적었다. 그 "한 줄"은 **도구 호출이 아니라 문장**이라 어떤 PreToolUse 훅도 볼 수 없고
 # 승인창도 안 뜬다(승인창은 *한 일*에만 뜬다). 그래서 Stop 이 대화 기록을 직접 읽는다.
 #
 # ── 판정 ─────────────────────────────────────────────────────────────
 #   결정 표지 어휘를 담은 **서술형** 문장이 있는데  AND  이 턴에 AskUserQuestion 이 0회
 #   → 차단. 질문을 한 번 하면 풀리므로 세션이 벽돌이 되지 않는다.
 #
 # 표지 어휘를 이렇게 고른 이유: 저 말들은 "물어봤어야 할 것을 혼자 정했다"를 **자백**할
 # 때만 나온다. 자백은 있는데 질문이 0회면 그 자체가 위반이다.
 #
 # ── 좁히는 장치 셋 (위양성 억제) ─────────────────────────────────────
 # 어휘만 보면 이 게이트를 **유지보수하는 작업 자체가 매번 걸린다** — 훅·테스트·결정 문서가
 # 그 어휘를 데이터로 품기 때문이다. 그러면 사람이 게이트를 끄게 되고 그게 최악이다.
 #   1) 구조적 제외 — 코드펜스 · 인라인 코드 · 인용줄(>) · 따옴표로 감싼 부분은 안 본다.
 #      그래서 어휘를 **인용부호로 감싸 언급하는 것**은 안 걸린다(문서·설명의 정상 형태다).
 #   2) 질문 신호 제외 — 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다.
 #   3) 서술형 종결 요구 — "…했다/…습니다" 같은 단정으로 끝나야 "내가 그렇게 했다"이다.
 # 대가는 위음성 증가다. 표현을 바꾸면 빠져나간다 — 겨누는 것이 적대적 회피가 아니라
 # **무의식적 습관**이라 그래도 실효가 남는다. guard-hook-disable 과 같은 판단 구조다.
 #
 # **도구 입력은 보지 않는다(text 블록만 본다).** 그래서 이 패턴이 적힌 파일을 Write/Edit
 # 로 쓰는 것은 안 걸린다 — 자기참조 폭발을 원천에서 없애는 장치다.
 # thinking 블록도 안 본다: 거기서 선택지를 저울질하는 것은 결정 통보가 아니다.
 # 서브에이전트 발화(isSidechain)도 뺀다: 서브에이전트는 사용자에게 물을 수 없다.
 #
 # ── 반환 계약 ─────────────────────────────────────────────────────────
 #   rc=0 : 차단해야 한다. stdout = 걸린 문장들(줄당 하나)
-#   rc=1 : 차단 불필요 (표지 없음 · 또는 이 턴에 질문을 했음)
 #   rc=2 : **판독 불가.** stdout = 사유 한 줄
+#   rc=3 : 차단 불필요 (표지 없음 · 또는 이 턴에 질문을 했음)
+#   그 밖 : **예상 밖.** python3 부재(127) · 처리 못 한 예외(1) · 신호 종료 등
+#
+# "차단 불필요"에 1 이 아니라 **3** 을 쓰는 이유: python 이 처리 못 한 예외로 죽으면
+# 그것도 1 이라, 1 을 정상 통과로 쓰면 **크래시가 조용한 통과로 위장된다.** 정상 경로에
+# 흔한 코드를 주지 않으면 호출부가 "모르는 rc = 무언가 잘못됐다"로 갈라낼 수 있다.
+# 호출부는 0·2·3 만 알고 나머지는 전부 판독 불가로 취급해야 한다.
 #
 # ── rc=2 가 이 게이트의 유일한 fail-open 지점이다 ────────────────────
 # 대화 기록의 형식은 하네스가 소유하지 않는다 — 도구 제공자가 정하고 예고 없이 바뀐다.
 # 형식이 바뀌었다고 차단하면 **세션이 통째로 벽돌이 되는데 그 세션 안에 고칠 방법이 없다**
 # (기록을 고칠 수는 없으므로 어떤 행동으로도 게이트가 안 풀린다). 그래서 여기서만 통과로
 # 간다. 나머지 판정은 전부 fail-closed 다.
 # **조건은 경고를 삼키지 않는 것이다** — 호출부가 이 사유를 마지막 게이트 메시지에 싣는다.
 # 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다.
 decision_scan() {   # $1 = 대화 기록(JSONL) 경로
   local path="$1"
   [ -n "$path" ] || { printf '%s\n' '대화 기록 경로가 훅 입력에 없습니다'; return 2; }
   [ -r "$path" ] || { printf '%s\n' "대화 기록을 읽을 수 없습니다: $path"; return 2; }
   python3 - "$path" <<'PY'
 import json, re, sys
 
 # 결정 표지. 굴절 변형만 최소로 넓혔고 그 이상 넓히지 않는다 — 넓히면 위양성이 늘고,
 # 위양성이 늘면 질문이 소음이 되고, 소음이 되면 진짜 질문도 무시된다.
 MARKER = re.compile(
     "공시하|공시했|공시함"
     "|범위 ?밖"
     "|별도로"
     "|그대로 (?:뒀|두었|남겼|남겨)"
     "|(?:제|내) 판단으로"
     "|가정하(?:고|여|였|겠)|가정했"
     "|수용(?:된|한) 한계"
     "|트레이드오프"
     "|안 했(?:습니다|다|음)"
 )
 # 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다.
 QUESTION = re.compile(
     "\\?|까요|나요|ㄹ까|을까|할까|여쭤|여쭈|여쭙|물어|어떠신|어느 쪽"
     "|골라|선택해|정해 ?주|알려 ?주|괜찮으신|의견"
 )
+# **"묻지 않았다"는 물음이 아니라 자백이다.** 이게 없으면 겨누는 문장 자체가 빠져나간다 —
+# "사용자에게 물어보지 않고 제 판단으로 진행했습니다" 는 `물어` 때문에 질문으로 오인된다.
+# 부정이 붙으면 위 QUESTION 제외를 적용하지 않는다.
+NEG_ASK = re.compile(
+    "물어보지 ?않|물어보지도|묻지 ?않|묻지도|여쭙지 ?않|여쭈지 ?않|여쭤보지 ?않"
+    "|확인하지 ?않|확인 ?없이|의견을 받지 ?않|물어보는 대신|묻는 대신|묻지 못"
+)
 # 서술형 종결. "내가 그렇게 했다"는 단정만 잡는다.
 DECLARATIVE = re.compile("(?:다|음|함|됨|임|옴)$")
 
-INLINE     = re.compile("`[^`\n]*`")
+# 이중 백틱 코드 span 이 먼저다 — 단일 규칙만 두면 ``a`b`` 의 안쪽이 산문으로 샌다.
+INLINE     = re.compile("``[^`\n]*``|`[^`\n]*`")
 QUOTED     = re.compile("\"[^\"\n]*\"|'[^'\n]*'|“[^”\n]*”"
                         "|‘[^’\n]*’|「[^」\n]*」"
                         "|『[^』\n]*』")
 BLOCKQUOTE = re.compile("^\\s{0,3}>")
-SENT       = re.compile("([\n.!?…。！？]+)")
+# 마침표는 **뒤에 공백이나 줄끝이 올 때만** 문장 종결이다. 무조건 종결로 보면
+# `README.md`·`_common.sh`·버전 번호가 한 문장을 쪼개, 표지와 서술형 종결이 서로 다른
+# 조각으로 갈라져 **둘 다 만족하는 조각이 없어진다**(위음성).
+SENT       = re.compile("([\n!?…。！？]+|\\.(?=\\s)|\\.$)")
 LEAD       = re.compile("^[\\s*_>#\\-–—•·]+")
 TRAIL      = re.compile("[\\s*_`~\\[\\](){}<>:;,·…\\-—–]+$")
 
 MAX_HITS, MAX_LEN = 8, 140
 
 
 def fail(reason):
     sys.stdout.write(reason + "\n")
     raise SystemExit(2)
 
 
 def drop_fences(s):
     # 짝수 조각만 코드 **밖**이다. 펜스가 안 닫혔으면 마지막 조각은 코드 안으로 친다 —
     # 스트리밍 중 잘린 기록에서 코드가 산문으로 새는 것을 막는다.
-    return "\n".join(p for i, p in enumerate(s.split("```")) if i % 2 == 0)
+    # 백틱만 보면 `~~~` 펜스의 예문이 산문으로 검사된다(문서가 약속한 범위보다 좁다).
+    for fence in ("```", "~~~"):
+        s = "\n".join(p for i, p in enumerate(s.split(fence)) if i % 2 == 0)
+    return s
 
 
 def is_user_prompt(e):
     if e.get("type") != "user" or e.get("isSidechain"):
         return False
     if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
         return False
     msg = e.get("message")
     if not isinstance(msg, dict):
         return False
     content = msg.get("content")
     if isinstance(content, list):
         for b in content:
             if isinstance(b, dict) and b.get("type") == "tool_result":
                 return False
     return True
 
 
 try:
     with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as fh:
         raw = fh.read()
 except Exception as exc:
     fail("대화 기록을 열지 못했습니다: %s" % exc.__class__.__name__)
 
 lines = [ln for ln in raw.splitlines() if ln.strip()]
-entries = []
+entries, broken = [], 0
 for ln in lines:
     try:
         entries.append(json.loads(ln))
     except Exception:
-        pass                # 개별 줄 손상은 건너뛴다. 전멸이면 바로 아래에서 걸린다
-if lines and not entries:
-    fail("대화 기록을 한 줄도 파싱하지 못했습니다 (형식이 바뀌었을 수 있습니다)")
+        broken += 1
+# **한 줄이라도 못 읽으면 판독 불가다.** 건너뛰면 그 줄이 하필 자백이 담긴 발화이거나
+# 이 턴의 사용자 프롬프트일 때 조용히 새고, 후자는 경계가 **지난 턴으로 밀려** 위양성까지
+# 낳는다. "전멸일 때만 실패"로 두면 부분 손상이라는 가장 흔한 경우를 정확히 놓친다.
+if broken:
+    fail("대화 기록 %d줄을 파싱하지 못했습니다 (형식이 바뀌었을 수 있습니다)" % broken)
+if not entries:
+    fail("대화 기록이 비어 있습니다")
 
 start = -1
 for i, e in enumerate(entries):
     if isinstance(e, dict) and is_user_prompt(e):
         start = i
 if start < 0:
     # 사용자 프롬프트가 없는 기록은 있을 수 없다 — 경계를 못 찾았다는 뜻이다.
     # 전체를 훑으면 지난 턴의 문장까지 걸려 위양성이 폭주하므로 판독 불가로 떨어뜨린다.
     fail("이 턴의 시작점(사용자 프롬프트)을 찾지 못했습니다 (형식이 바뀌었을 수 있습니다)")
 
 asked, texts = 0, []
 for e in entries[start + 1:]:
     if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):
         continue
-    content = (e.get("message") or {}).get("content")
-    if not isinstance(content, list):
+    msg = e.get("message")
+    if not isinstance(msg, dict):
+        # truthy 비-dict 를 `or {}` 로 받으면 여기서 예외가 나고, 그 예외는 아래 "표지 없음"과
+        # 구별되지 않는 종료 코드로 나간다 — 조용한 통과다. 형식 변화로 보고 소리를 낸다.
+        fail("assistant 항목의 message 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
+    content = msg.get("content")
+    if isinstance(content, str):
+        # 문자열 본문도 발화다. 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
+        texts.append(content)
         continue
+    if not isinstance(content, list):
+        # 볼 수 없는 발화가 있다 = 사각지대다. 조용히 건너뛰면 게이트가 죽은 줄도 모른다.
+        fail("assistant 항목의 content 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
     for b in content:
         if not isinstance(b, dict):
             continue
         if b.get("type") == "tool_use":
             if b.get("name") == "AskUserQuestion":
                 asked += 1
         elif b.get("type") == "text":
             t = b.get("text")
             if isinstance(t, str):
                 texts.append(t)
 
 if asked > 0:
-    raise SystemExit(1)
+    raise SystemExit(3)
 
 hits, seen = [], set()
 for text in texts:
     for line in drop_fences(text).split("\n"):
         if BLOCKQUOTE.match(line):
             continue
         line = QUOTED.sub(" ", INLINE.sub(" ", line))
         chunks = SENT.split(line)
         for i in range(0, len(chunks), 2):
             body = chunks[i]
             whole = body + (chunks[i + 1] if i + 1 < len(chunks) else "")
-            if QUESTION.search(whole):
+            # 부정이 붙으면 물음이 아니라 자백이다 — "물어보지 않고 …했습니다".
+            if QUESTION.search(whole) and not NEG_ASK.search(whole):
                 continue
             core = TRAIL.sub("", LEAD.sub("", body).strip())
             if not core or not MARKER.search(core) or not DECLARATIVE.search(core):
                 continue
             if core in seen:
                 continue
             seen.add(core)
             hits.append(core if len(core) <= MAX_LEN else core[:MAX_LEN] + "…")
 
 if not hits:
-    raise SystemExit(1)
+    raise SystemExit(3)
 for h in hits[:MAX_HITS]:
     sys.stdout.write(h + "\n")
 if len(hits) > MAX_HITS:
     sys.stdout.write("... 그리고 %d개 더\n" % (len(hits) - MAX_HITS))
 raise SystemExit(0)
 PY
 }
diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
index 970bba3..4d6fc41 100644
--- a/template/.claude/hooks/verify-before-stop.sh
+++ b/template/.claude/hooks/verify-before-stop.sh
@@ -31,316 +31,340 @@ push_branch=""
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
 
+# 결정 게이트가 대화 기록을 못 읽었으면 **어느 게이트가 막든** 그 사유를 함께 낸다.
+# 감사 게이트에만 실으면, 앞 게이트가 먼저 막은 턴에는 안 보이고 그 플래그를 지운 다음
+# 턴에는 조기 종료로 **영영 사라진다**(검수 [cx] 지적). 조용히 사라지는 것이 이 게이트를
+# 만든 이유 그 자체라, 경고를 삼키지 않는 것이 fail-open 의 조건이다.
+emit_decision_note() {
+  [ -n "${decision_note:-}" ] || return 0
+  echo
+  echo "참고: $decision_note"
+  echo "      → 이 턴에 사용자에게 물었어야 할 결정이 없었는지 스스로 확인하세요."
+}
+
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
-if ! hook_disabled "stop:decision"; then
+# **발동 조건은 플래그다.** 조기 종료는 push 미완만으로도 풀리므로, 그것만 보고 스캔하면
+# 아무것도 안 바꾼 읽기 전용 턴까지 검사하게 된다 — "플래그와 무관하게 항상"은 사용자가
+# 기각한 보기다. 여기서 한 번 더 물어 발동 계약을 조기 종료와 분리한다.
+decision_armed=0
+if [ -s "$AUDIT_FLAG" ] || [ -s "$EXPLAIN_FLAG" ] || [ -s "$DUALREVIEW_FLAG" ] || knowledge_gate_active; then
+  decision_armed=1
+fi
+if [ "$decision_armed" -eq 1 ] && ! hook_disabled "stop:decision"; then
   decision_hits="$(decision_scan "$transcript_path")"; decision_rc=$?
-  if [ "$decision_rc" -eq 2 ]; then
-    # **이 게이트의 유일한 fail-open.** 통과시키되 사유를 (6) 의 메시지에 실어 보낸다.
-    # 대화 기록 형식은 하네스 소유가 아니라, 여기서 차단하면 그 세션 안에 고칠 방법이 없다.
-    decision_note="결정 게이트 생략 ($decision_hits)"
-  elif [ "$decision_rc" -eq 0 ]; then
+  case "$decision_rc" in
+    3) : ;;   # 표지 없음 · 또는 이 턴에 물었음
+    2)
+      # **이 게이트의 유일한 fail-open.** 통과시키되 사유를 게이트 메시지에 실어 보낸다.
+      # 대화 기록 형식은 하네스 소유가 아니라, 여기서 차단하면 그 세션 안에 고칠 방법이 없다.
+      decision_note="결정 게이트 생략 ($decision_hits)" ;;
+    0) ;;     # 아래에서 차단한다 (case 안에서 하면 들여쓰기가 깊어져 메시지가 안 읽힌다)
+    *)
+      # **모르는 rc 는 통과가 아니라 판독 불가다.** python3 부재(127)·처리 못 한 예외(1)·
+      # 신호 종료가 전부 여기로 온다. 이걸 통과로 읽으면 게이트가 조용히 사라진다.
+      decision_note="결정 게이트 생략 (스캐너가 예상 밖 상태로 끝남 rc=$decision_rc — python3 부재·예외·신호 종료일 수 있습니다)" ;;
+  esac
+  if [ "$decision_rc" -eq 0 ]; then
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
+    emit_decision_note
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
+    emit_decision_note
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
+    emit_decision_note
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
+    emit_decision_note
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
-  # 결정 게이트가 대화 기록을 못 읽었으면 **여기서 소리를 낸다.** 그 게이트만 조용히
-  # 사라지면 "물어봤나"를 아무도 안 보게 되고, 그게 정확히 이 게이트를 만든 이유다.
-  if [ -n "$decision_note" ]; then
-    echo
-    echo "참고: $decision_note"
-    echo "      → 이 턴에 사용자에게 물었어야 할 결정이 없었는지 스스로 확인하세요."
-  fi
+  emit_decision_note
   echo
   echo "해야 할 일:"
   echo "  1. completion-auditor 에이전트로 완료 주장을 1차 증거로 검증한다."
   echo "  2. 검증을 통과했을 때만:  rm -f .claude/.needs-audit"
   echo "     감사 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   echo
   echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
 } >&2
 bump_and_block
diff --git a/tests/decision-gate.test.sh b/tests/decision-gate.test.sh
index 773344f..90d297d 100755
--- a/tests/decision-gate.test.sh
+++ b/tests/decision-gate.test.sh
@@ -39,179 +39,197 @@ fi
 TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
 # chmod 000 픽스처가 있으므로 되돌린 뒤 지운다 — 안 그러면 정리가 실패한다.
 trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT
 
 ran=0; pass=0; fail=0
 RC=999; ERR=''; OUT=''; DID_RUN=0
 PROJ_N=0
 
 # 판정 토큰. 훅 메시지의 **고유 문구**를 쓴다 — 어느 게이트가 말했는지는 이걸로만 갈린다.
 TOK_DECISION='혼자 정한 것이 있는데'
 TOK_NOTE='결정 게이트 생략'
 TOK_AUDIT='completion-auditor 미실행'
 TOK_BRICK='세션 벽돌 방지'
 
 report() {
   ran=$((ran + 1))
   if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
   else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
 }
 
 contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
 
 # --- 픽스처 --------------------------------------------------------------
 
 # new_project <지식게이트값> — 케이스마다 독립 프로젝트. 경로를 stdout 에.
 # 지식게이트값: 리터럴로 비면 꺼짐, 그 외 문자열이면 켜짐.
 # 타입체크는 항상 리터럴로 비운다 — 이 파일이 재는 것은 결정 게이트뿐이고, 타입체크가
 # 먼저 막으면 그 케이스는 결정 게이트에 **도달조차 못 한 채** 기대값이 우연히 맞는다.
 new_project() {
   PROJ_N=$((PROJ_N + 1))
   local p="$TMPROOT/proj$PROJ_N"
   mkdir -p "$p/.claude/hooks" "$p/.claude/harness" || return 1
   cp "$HOOKS/_common.sh" "$HOOKS/verify-before-stop.sh" "$p/.claude/hooks/" || return 1
   printf 'HARNESS_TYPECHECK_CMD=""\nHARNESS_KNOWLEDGE_GATE="%s"\n' "$1" \
     > "$p/.claude/harness/harness.env" || return 1
   printf '%s\n' "$p"
 }
 
 # mk_transcript <출력경로> <항목...> — 대화 기록 JSONL 을 만든다.
 # 항목 문법:  text:<문장> · side:<문장>(서브에이전트) · think:<문장> · ask ·
 #             tool:<내용>(도구 입력) · prompt(새 사용자 프롬프트=턴 경계) · toolresult:<내용>
 # 첫 줄은 항상 사용자 프롬프트다 — 그게 없는 경우는 판독 불가 케이스에서 따로 만든다.
 mk_transcript() {
   python3 - "$@" <<'PY'
 import json, sys
 
 out = sys.argv[1]
 
 
 def prompt():
     return {"type": "user", "isSidechain": False,
             "message": {"role": "user", "content": "작업해줘"}}
 
 
 rows = [prompt()]
 for spec in sys.argv[2:]:
     kind, _, val = spec.partition(":")
     if kind == "prompt":
         rows.append(prompt())
         continue
     if kind == "toolresult":
         rows.append({"type": "user", "isSidechain": False,
                      "toolUseResult": {"stdout": val},
                      "message": {"role": "user",
                                  "content": [{"type": "tool_result", "content": val}]}})
         continue
     # 실제 기록에서는 두 표식이 **항상 함께** 온다(실측 69/69). 그래서 둘 다 보는 판정은
     # 서로를 가려, 한쪽을 지워도 아무 케이스가 안 빨개진다 — 변이 측정에서 실제로 드러났다.
     # 각각을 **독립적으로** 지키려면 표식이 하나뿐인 기록이 필요하다. 형식이 바뀌어 한쪽만
     # 남는 날, 남은 한쪽이 실제로 일하는지를 재는 것이 이 두 항목이다.
     if kind == "toolresult_top":       # 상단 toolUseResult 만 (content 는 평문)
         rows.append({"type": "user", "isSidechain": False,
                      "toolUseResult": {"stdout": val},
                      "message": {"role": "user", "content": val}})
         continue
     if kind == "toolresult_blk":       # tool_result 블록만 (상단 키 없음)
         rows.append({"type": "user", "isSidechain": False,
                      "message": {"role": "user",
                                  "content": [{"type": "tool_result", "content": val}]}})
         continue
+    # 형식이 어긋난 항목들. 전부 "판독 불가"로 떨어져야 하는 입력이다 —
+    # 조용히 건너뛰면 그 발화가 스캔에서 사라지고 게이트가 죽은 줄도 모른다.
+    if kind == "broken":               # JSON 이 아닌 줄
+        rows.append("\x00RAW\x00" + (val or "not json at all {{{"))
+        continue
+    if kind == "strtext":              # content 가 문자열인 assistant (형식 변형)
+        rows.append({"type": "assistant", "isSidechain": False,
+                     "message": {"content": val}})
+        continue
+    if kind == "badmsg":               # message 가 truthy 비-dict
+        rows.append({"type": "assistant", "isSidechain": False, "message": "문자열 메시지"})
+        continue
+    if kind == "badcontent":           # content 가 list 도 str 도 아님
+        rows.append({"type": "assistant", "isSidechain": False, "message": {"content": 42}})
+        continue
     side = False
     if kind == "side":
         side, kind = True, "text"
     if kind == "text":
         block = {"type": "text", "text": val}
     elif kind == "think":
         block = {"type": "thinking", "thinking": val}
     elif kind == "ask":
         block = {"type": "tool_use", "name": "AskUserQuestion", "input": {}}
     elif kind == "tool":
         block = {"type": "tool_use", "name": "Write", "input": {"content": val}}
     else:
         raise SystemExit("알 수 없는 항목: " + spec)
     rows.append({"type": "assistant", "isSidechain": side,
                  "message": {"content": [block]}})
 
 with open(out, "w", encoding="utf-8") as fh:
     for row in rows:
-        fh.write(json.dumps(row, ensure_ascii=False) + "\n")
+        if isinstance(row, str) and row.startswith("\x00RAW\x00"):
+            fh.write(row[5:] + "\n")     # 일부러 깨뜨린 줄은 그대로 쓴다
+        else:
+            fh.write(json.dumps(row, ensure_ascii=False) + "\n")
 PY
 }
 
 # run_stop <프로젝트> <transcript경로|빈문자열> [env 인자...]
 # 빈 문자열이면 payload 에서 transcript_path 키를 **아예 뺀다**(키 부재 케이스).
 run_stop() {
   local p="$1" tp="$2"
   shift 2
   local errf="$TMPROOT/err.$$" outf="$TMPROOT/out.$$" payf="$TMPROOT/pay.$$"
   RC=999; ERR=''; OUT=''; DID_RUN=1
   # payload 를 **파일로** 넘긴다. 파이프로 주면 훅이 stdin 을 읽기 전에 종료하는 경로
   # (탈출구로 꺼진 경우 등)에서 생산자 python 이 SIGPIPE 를 맞아 BrokenPipeError 를
   # 출력에 흘린다 — 진짜 실패와 구별이 안 되는 잡음이다.
   python3 -c '
 import json, sys
 d = {"stop_hook_active": False}
 if sys.argv[1]:
     d["transcript_path"] = sys.argv[1]
 with open(sys.argv[2], "w", encoding="utf-8") as fh:
     fh.write(json.dumps(d))' "$tp" "$payf"
   env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$p" \
       bash "$p/.claude/hooks/verify-before-stop.sh" <"$payf" >"$outf" 2>"$errf"
   RC=$?
   rm -f "$payf"
   ERR="$(cat "$errf" 2>/dev/null)"
   OUT="$(cat "$outf" 2>/dev/null)"
   rm -f "$errf" "$outf"
 }
 
 # setup_flags <프로젝트> <플래그 이름...>  (audit|explain|knowledge|dualreview)
 setup_flags() {
   local p="$1"; shift
   rm -f "$p/.claude/.needs-audit" "$p/.claude/.needs-explain" \
         "$p/.claude/.needs-knowledge" "$p/.claude/.needs-dualreview" \
         "$p/.claude/.stop-block-count" "$p/.claude/.stop-block-fp" 2>/dev/null
   local f
   for f in "$@"; do printf 'src/changed.ts\n' > "$p/.claude/.needs-$f"; done
 }
 
 # --- 공통 케이스 형태 -----------------------------------------------------
 #
 # blocked = 결정 게이트가 **막아야** 한다
 # silent  = 결정 게이트는 **아무 말도 하지 않아야** 한다 (뒤 게이트가 막는 것은 정상)
 #
 # silent 판정에 rc=0 을 쓰지 않는 이유: 플래그가 서 있으면 감사 게이트가 반드시 rc=2 를
 # 낸다. 그래서 결정 게이트의 침묵만 요구하고, 동시에 **감사 게이트가 실제로 말했는지**를
 # 함께 요구한다 — 안 그러면 훅이 앞에서 죽어 아무것도 안 재고도 통과한다(15번 부류).
 
 blocked_case() {   # $1=이름 $2=기대문장조각("" 이면 생략) $3..=기록 항목
   local name="$1" want_hit="$2" why=''
   shift 2
   local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   local tp="$p/transcript.jsonl"
   mk_transcript "$tp" "$@" || { report "$name" '픽스처 실패: 기록 생성'; return 0; }
   [ -s "$tp" ] || { report "$name" '픽스처 실패: 기록이 비어 있다'; return 0; }
   setup_flags "$p" audit
   run_stop "$p" "$tp"
   if [ "$DID_RUN" -ne 1 ];                then why='훅을 실행하지 않았다'
   elif [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2) / $(printf '%s' "$ERR" | head -c 100)"
   elif ! contains "$ERR" "$TOK_DECISION"; then why="결정 게이트가 아닌 것이 막았다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   elif [ -n "$want_hit" ] && ! contains "$ERR" "$want_hit"; then
     why="걸린 문장이 메시지에 없다 (기대 조각: $want_hit)"
   fi
   report "$name" "$why"
 }
 
 silent_case() {   # $1=이름 $2..=기록 항목
   local name="$1" why=''
   shift
   local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   local tp="$p/transcript.jsonl"
   mk_transcript "$tp" "$@" || { report "$name" '픽스처 실패: 기록 생성'; return 0; }
   [ -s "$tp" ] || { report "$name" '픽스처 실패: 기록이 비어 있다'; return 0; }
   setup_flags "$p" audit
   run_stop "$p" "$tp"
   if [ "$DID_RUN" -ne 1 ];              then why='훅을 실행하지 않았다'
   elif contains "$ERR" "$TOK_DECISION"; then why='위양성 — 결정 게이트가 막았다'
   elif [ "$RC" -ne 2 ];                 then why="rc=$RC (기대 2 — 감사 게이트가 막아야 한다)"
   elif ! contains "$ERR" "$TOK_AUDIT";  then why="감사 게이트에 도달하지 못했다 = 아무것도 안 쟀다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   elif contains "$ERR" "$TOK_NOTE";     then why='판독 불가로 빠졌다 — 스캔이 실제로 돌지 않았다'
@@ -275,239 +293,321 @@ d18() { silent_case '선택을 요청하는 문장도 세지 않는다' \
 # **묻겠다는 말이 서술형으로 끝나는 경우가 질문 신호 판정의 진짜 시험대다.** d17·d18 은
 # 종결이 "…까요/…세요"라 서술형 요구에서 이미 걸러져 질문 판정에 도달조차 하지 않는다 —
 # 그래서 질문 판정을 지워도 아무것도 안 빨개졌다(변이 측정에서 드러났다).
 d18b() { silent_case '묻겠다는 말이 서술형으로 끝나도 세지 않는다' \
           'text:이게 범위 밖인지 여쭙겠습니다.'; }
 d18c() { silent_case '물어보겠다는 말도 세지 않는다' \
           'text:이걸 별도로 뺄지 사용자에게 물어보겠습니다.'; }
 d19() { silent_case 'thinking 블록은 스캔하지 않는다' \
           'think:이건 범위 밖이라 그대로 뒀습니다.'; }
 d20() { silent_case '서브에이전트 발화는 스캔하지 않는다' \
           'side:이건 범위 밖이라 그대로 뒀습니다.'; }
 # **도구 입력을 안 보는 것이 자기참조 폭발을 막는 장치다.** 이 패턴이 적힌 파일을
 # Write/Edit 로 쓰는 것 자체는 결정이 아니다.
 d21() { silent_case '도구 입력(파일 내용)은 스캔하지 않는다' \
           'tool:이건 범위 밖이라 그대로 뒀습니다.'; }
 d22() { silent_case '서술형이 아니면(명사 종결) 세지 않는다' \
           'text:- 범위 밖'; }
 d23() { silent_case '표지가 없으면 아무리 길어도 안 잡는다' \
           'text:구현을 마쳤고 테스트 12건이 전부 통과했습니다.'; }
 # 턴 경계. 지난 턴의 자백까지 세면 이미 해소된 것으로 영원히 막힌다.
 d24() { silent_case '지난 턴의 문장은 보지 않는다' \
           'text:이건 범위 밖이라 그대로 뒀습니다.' 'prompt' 'text:이번에는 전부 처리했습니다.'; }
 # 도구 결과는 사용자 발화가 아니다. 이걸 턴 경계로 세면 창이 도구 호출 하나로 좁아져
 # 게이트가 사실상 사라진다. 두 방향으로 잰다 — 놓치지 않는가(d25b)와 오탐하지 않는가(d25).
 d25() { silent_case '도구 결과 뒤라도 표지가 없으면 안 막는다' \
           'text:작업을 시작합니다.' 'toolresult:ok' 'text:테스트가 전부 통과했습니다.'; }
 d25b() { blocked_case '도구 결과 뒤의 자백도 같은 턴으로 본다' '범위 밖' \
           'text:작업을 시작합니다.' 'toolresult:ok' 'text:나머지는 범위 밖이라 뒀습니다.'; }
 # **자백이 도구 결과보다 앞에 있는 경우가 판정의 진짜 시험대다.** 도구 결과를 턴 경계로
 # 오인하면 그 앞의 발화가 통째로 창 밖으로 밀려 사라지는데, d25b 는 자백이 뒤에 있어서
 # 그 오인을 못 잡는다(경계가 밀려도 뒤 문장은 여전히 창 안이다).
 d25c() { blocked_case '도구 결과 앞의 자백도 놓치지 않는다' '범위 밖' \
           'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult:ok' 'text:작업을 마쳤습니다.'; }
 # 표식이 하나뿐인 도구 결과. 두 판정(상단 키 / 블록)을 **각각** 지킨다 — 실제 기록은 둘 다
 # 갖고 있어서 서로를 가리고, 그러면 한쪽을 지워도 아무 케이스가 안 빨개진다.
 d25d() { blocked_case '상단 키만 있는 도구 결과도 턴 경계가 아니다' '범위 밖' \
           'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult_top:ok' 'text:작업을 마쳤습니다.'; }
 d25e() { blocked_case '블록만 있는 도구 결과도 턴 경계가 아니다' '범위 밖' \
           'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult_blk:ok' 'text:작업을 마쳤습니다.'; }
 
 # ── 3. 발동 조건 — 어느 플래그에서 도나 ──────────────────────────────
 # 사용자 확정(2026-08-10): 코드뿐 아니라 **결정 문서·설계 산출물** 턴에서도 돈다.
 # 표지 어휘가 가장 자주 나오는 자리가 결정 문서를 쓰는 턴이기 때문이다.
 flag_case() {   # $1=이름 $2=지식게이트값 $3=플래그(none 가능) $4=기대(block|exit0)
   local name="$1" kg="$2" flag="$3" want="$4" why=''
   local p; p="$(new_project "$kg")" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   local tp="$p/transcript.jsonl"
   mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.' || { report "$name" '픽스처 실패'; return 0; }
   if [ "$flag" = 'none' ]; then setup_flags "$p"; else setup_flags "$p" "$flag"; fi
   run_stop "$p" "$tp"
   case "$want" in
     block)
       if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2)"
       elif ! contains "$ERR" "$TOK_DECISION"; then why="결정 게이트가 아닌 것이 막았다: $(printf '%s' "$ERR" | head -1 | head -c 80)"
       fi ;;
     exit0)
       if   [ "$RC" -ne 0 ];                 then why="rc=$RC (기대 0 — 할 일이 없으면 조기 종료)"
       elif contains "$ERR" "$TOK_DECISION"; then why='할 일이 없는 턴인데 결정 게이트가 막았다'
       fi ;;
     *) why="알 수 없는 기대값: $want" ;;
   esac
   report "$name" "$why"
 }
 d26() { flag_case '코드 변경 턴에서 돈다'        ''   audit      block; }
 d27() { flag_case '설계 산출물 턴에서 돈다'      ''   dualreview block; }
 d28() { flag_case '결정 문서 턴에서 돈다'        'on' knowledge  block; }
 d29() { flag_case '변경설명 턴에서 돈다'         ''   explain    block; }
 # **아무것도 안 바꾼 턴은 막지 않는다.** 순수 질의응답에서 어휘를 썼다고 막으면 게이트가
 # 대화를 방해한다(사용자 확정: "항상 검사" 보기 기각).
 d30() { flag_case '플래그가 하나도 없으면 돌지 않는다' '' none exit0; }
 # 공시된 한계를 케이스로 붙든다: 지식 게이트를 끈 환경에서 **결정 문서만** 고친 턴은
 # 조기 종료에 걸려 결정 게이트까지 못 간다. 조기 종료를 고치면 "게이트를 껐는데 남은
 # 플래그가 읽기 전용 턴을 막는" 알려진 버그가 되살아난다. 기본값이 켜짐이라 기본 구성에서는
 # d28 처럼 정상 발동한다. **이 한계가 바뀌면 이 케이스가 빨개져서 알려준다.**
 d30b() { flag_case '지식 게이트를 끄면 결정 문서 턴은 조기 종료된다(공시된 한계)' '' knowledge exit0; }
 
 # ── 4. fail-open — 판독 불가는 **통과 + 경고**다 ─────────────────────
 # 대화 기록 형식은 하네스가 소유하지 않는다. 형식이 바뀌었다고 차단하면 그 세션 안에
 # 고칠 방법이 없어 **세션이 통째로 벽돌이 된다.** 이 게이트의 유일한 fail-open 지점이고,
 # 조건은 **경고를 삼키지 않는 것**이다 — 조용히 통과하면 게이트가 죽은 걸 아무도 모른다.
-openq_case() {   # $1=이름 $2=기록준비함수
-  local name="$1" prep="$2" why=''
+# openq_case <이름> <기록준비함수> [기대 사유 조각]
+#
+# **사유 조각까지 요구하는 것이 계약이다.** "경고가 나왔다"만 보면, 그 판독 불가를 알아본
+# 개별 검사를 지워도 파이썬이 크래시하면서 호출부의 catch-all 이 **대신** 경고를 내
+# 초록으로 남는다(변이 측정에서 실제로 드러났다). 어떤 사유로 멈췄는지까지 봐야 그 검사
+# 자신이 지켜진다 — 위음성 카탈로그 17번("rc 단독 판정은 약하다")의 메시지 판이다.
+openq_case() {
+  local name="$1" prep="$2" want_reason="${3:-}" why=''
   local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   local tp; tp="$("$prep" "$p")"
   setup_flags "$p" audit
   run_stop "$p" "$tp"
   if   [ "$DID_RUN" -ne 1 ];            then why='훅을 실행하지 않았다'
   elif contains "$ERR" "$TOK_DECISION"; then why='판독 불가인데 차단했다 (세션이 벽돌이 된다)'
   elif [ "$RC" -ne 2 ];                 then why="rc=$RC (기대 2 — 감사 게이트가 막아야 한다)"
   elif ! contains "$ERR" "$TOK_NOTE";   then why='경고를 삼켰다 — 게이트가 조용히 죽은 것을 아무도 모른다'
+  elif [ -n "$want_reason" ] && ! contains "$ERR" "$want_reason"; then
+    why="사유가 다르다 (기대 조각: $want_reason) — 그 판독 불가를 알아본 검사가 사라졌다"
   fi
   report "$name" "$why"
 }
 prep_nokey()   { printf '%s\n' ''; }
 prep_missing() { printf '%s\n' "$1/does-not-exist.jsonl"; }
 prep_garbage() { local f="$1/garbage.jsonl"; printf 'not json at all\n{{{\n' > "$f"; printf '%s\n' "$f"; }
 # 사용자 프롬프트가 없는 기록 = 턴 경계를 못 찾은 것. 전체를 훑으면 지난 턴까지 걸리므로
 # 판독 불가로 떨어뜨린다. 표지를 일부러 넣어 "그래도 안 막는가"를 잰다.
 prep_noprompt() {
   local f="$1/noprompt.jsonl"
   python3 -c '
 import json, sys
 with open(sys.argv[1], "w", encoding="utf-8") as fh:
     fh.write(json.dumps({"type": "assistant", "isSidechain": False, "message": {"content": [
         {"type": "text", "text": "이건 범위 밖이라 그대로 뒀습니다."}]}}, ensure_ascii=False) + "\n")
 ' "$f"
   printf '%s\n' "$f"
 }
 prep_unreadable() { local f="$1/unreadable.jsonl"; printf '{}\n' > "$f"; chmod 000 "$f" 2>/dev/null; printf '%s\n' "$f"; }
-d31() { openq_case 'transcript_path 키가 없으면 통과 + 경고' prep_nokey; }
-d32() { openq_case '기록 파일이 없으면 통과 + 경고'          prep_missing; }
-d33() { openq_case '전부 깨진 JSON 이면 통과 + 경고'         prep_garbage; }
-d34() { openq_case '턴 시작점을 못 찾으면 통과 + 경고'       prep_noprompt; }
+d31() { openq_case 'transcript_path 키가 없으면 통과 + 경고' prep_nokey '훅 입력에 없습니다'; }
+d32() { openq_case '기록 파일이 없으면 통과 + 경고'          prep_missing '읽을 수 없습니다'; }
+d33() { openq_case '전부 깨진 JSON 이면 통과 + 경고'         prep_garbage '파싱하지 못했습니다'; }
+d34() { openq_case '턴 시작점을 못 찾으면 통과 + 경고'       prep_noprompt '시작점'; }
 d35() {
   # root 로 도는 CI 에서는 chmod 000 이 읽기를 막지 못한다 — 그 환경에서 이 케이스는
   # 아무것도 재지 못하므로 **조용히 통과시키지 않고** 픽스처 무효로 빨갛게 만든다.
   # 조용한 skip 은 커버리지가 사라진 것을 초록으로 위장한다.
   if [ "$(id -u)" = '0' ]; then
     report '읽기 실패하면 통과 + 경고' 'root 라 chmod 000 이 읽기를 막지 못한다 — 이 환경에서는 측정 불가'
     return 0
   fi
-  openq_case '읽기 실패하면 통과 + 경고' prep_unreadable
+  openq_case '읽기 실패하면 통과 + 경고' prep_unreadable '읽을 수 없습니다'
 }
 
 # ── 5. 탈출구 (사용자 확정: 형제 Stop 게이트와 동일하게 제공) ────────
 # 이 게이트는 위양성이 **구조적으로** 난다 — 자기 어휘를 문서·설명에서 다뤄야 하기
 # 때문이다. 그래서 사용자가 즉시 뺄 수 있어야 한다. 끄는 대입 자체는 guard-hook-disable
 # 이 한 번 세운다(과속방지턱이지 방벽은 아니다).
 escape_case() {   # $1=이름 $2..=env 인자
   local name="$1" why=''
   shift
   local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   local tp="$p/transcript.jsonl"
   mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.' || { report "$name" '픽스처 실패'; return 0; }
   setup_flags "$p" audit
   run_stop "$p" "$tp" "$@"
   if   [ "$DID_RUN" -ne 1 ];            then why='훅을 실행하지 않았다'
   elif contains "$ERR" "$TOK_DECISION"; then why='껐는데도 결정 게이트가 막았다'
   fi
   report "$name" "$why"
 }
 d36() { escape_case '개별 비활성으로 끌 수 있다' ECC_DISABLED_HOOKS=stop:decision; }
 d37() { escape_case '전체 비활성으로도 꺼진다'   HARNESS_HOOKS=off; }
 d38() {
   # **다른 게이트 이름으로는 안 꺼진다.** 접두사·부분 일치로 꺼지면 하나를 끌 때 옆의
   # 게이트가 같이 사라지고 아무도 모른다.
   local name='다른 게이트 이름으로는 안 꺼진다' why=''
   local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   local tp="$p/transcript.jsonl"
   mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   setup_flags "$p" audit
   run_stop "$p" "$tp" ECC_DISABLED_HOOKS=stop:explain
   contains "$ERR" "$TOK_DECISION" || why='다른 게이트를 껐는데 결정 게이트까지 꺼졌다'
   report "$name" "$why"
 }
 
 # ── 6. 벽돌 방지 — 같은 지점 MAX_BLOCKS 회면 통과시킨다 ──────────────
 # 질문 한 번이면 풀리지만, 어떤 이유로도 못 푸는 상황에서 세션이 영영 안 끝나면 안 된다.
 d39() {
   local name='같은 지점에서 MAX_BLOCKS 회 뒤에는 통과시킨다 (벽돌 방지)' why=''
   local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   local tp="$p/transcript.jsonl"
   mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   setup_flags "$p" audit
   local i seen_block=0
   for i in 1 2 3; do
     run_stop "$p" "$tp"
     if [ "$RC" -eq 2 ] && contains "$ERR" "$TOK_DECISION"; then seen_block=$((seen_block + 1)); fi
   done
   run_stop "$p" "$tp"
   if   [ "$seen_block" -ne 3 ];        then why="3회 연속 차단이 아니었다 (실제 ${seen_block}회)"
   elif [ "$RC" -ne 0 ];                then why="소진 후 rc=$RC (기대 0)"
   elif ! contains "$OUT" "$TOK_BRICK"; then why="소진 통과인데 경고가 없다: $(printf '%s' "$OUT" | head -c 100)"
   fi
   report "$name" "$why"
 }
 d40() {
   # **진전하면 예산이 리셋된다.** 질문해서 결정 게이트를 푼 뒤 감사 게이트로 넘어가는 것은
   # 진전이므로, 앞서 쓴 차단 횟수가 뒤 게이트의 예산을 갉아먹으면 안 된다.
   local name='질문해서 풀면 뒤 게이트의 예산이 리셋된다' why=''
   local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   local blocked="$p/blocked.jsonl" asked="$p/asked.jsonl"
   mk_transcript "$blocked" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   mk_transcript "$asked"   'text:이건 범위 밖이라 그대로 뒀습니다.' 'ask'
   setup_flags "$p" audit
   local i
   for i in 1 2 3; do run_stop "$p" "$blocked"; done
   run_stop "$p" "$asked"
   if   [ "$RC" -ne 2 ];                then why="rc=$RC (기대 2 — 감사 게이트가 살아 있어야 한다)"
   elif ! contains "$ERR" "$TOK_AUDIT"; then why="감사 게이트가 예산 소진으로 사라졌다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   fi
   report "$name" "$why"
 }
 
 # ── 7. 순서 계약 — 결정 게이트가 다른 게이트보다 앞이다 ──────────────
 # 질문의 답이 코드를 바꿀 수 있으므로 리뷰·설명·감사에 노력을 쓰기 전에 물어야 한다.
 d41() {
   local name='듀얼리뷰·설명·감사보다 먼저 말한다' why=''
   local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   local tp="$p/transcript.jsonl"
   mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   setup_flags "$p" audit explain dualreview
   run_stop "$p" "$tp"
   if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2)"
   elif ! contains "$ERR" "$TOK_DECISION"; then why="다른 게이트가 먼저 말했다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   fi
   report "$name" "$why"
 }
 
+# ── 8. 듀얼 검수 1라운드 반영분 ([cx] 지적) ──────────────────────────
+# 고침의 실측과 회귀 방어는 다른 일이다. 고쳤으면 "이 줄을 지우면 무엇이 빨개지나"에
+# 답이 있어야 한다 — 아래가 그 답이다.
+
+# [cx] **"묻지 않았다"가 질문 신호에 걸려 제외됐다** — 겨누는 문장 자체가 빠져나갔다.
+d42() { blocked_case '"물어보지 않고 …했습니다" 를 막는다' '제 판단으로' \
+          'text:사용자에게 물어보지 않고 제 판단으로 진행했습니다.'; }
+d43() { blocked_case '"확인하지 않고 …했습니다" 를 막는다' '가정하여' \
+          'text:사용자 의견을 확인하지 않고 가정하여 구현했습니다.'; }
+# [cx] 마침표를 무조건 종결로 보면 파일명이 문장을 쪼개 **표지와 종결이 갈린다**.
+d44() { blocked_case '파일명 속 마침표가 문장을 쪼개지 않는다' '별도로' \
+          'text:나머지는 별도로 README.md 에 기록했습니다.'; }
+# [cx] 문서가 한정 없이 "코드펜스·인라인 코드는 안 본다"고 약속했는데 형태가 좁았다.
+d45() { silent_case '물결 펜스 안도 스캔하지 않는다' \
+          'text:예시:
+~~~
+이건 범위 밖이라 그대로 뒀습니다.
+~~~
+위가 걸리는 형태다.'; }
+d46() { silent_case '이중 백틱 코드 span 도 스캔하지 않는다' \
+          'text:표지 어휘는 ``범위 밖`` 이다.'; }
+# [cx] 문자열 content 를 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
+d47() { blocked_case 'content 가 문자열인 발화도 스캔한다' '범위 밖' \
+          'strtext:이건 범위 밖이라 그대로 뒀습니다.'; }
+# [cx] **일부** 손상이 "표지 없음"으로 조용히 통과하던 경로. 전멸만 잡으면 가장 흔한
+# 경우를 정확히 놓친다 — 깨진 줄이 하필 자백이거나 이 턴의 프롬프트일 수 있다.
+d48() { openq_case '일부 줄만 깨져도 통과 + 경고' prep_partial '1줄을 파싱하지 못했습니다'; }
+d49() { openq_case 'message 형식이 다르면 통과 + 경고' prep_badmsg 'message 형식이'; }
+d50() { openq_case 'content 형식이 다르면 통과 + 경고' prep_badcontent 'content 형식이'; }
+prep_partial() {
+  local f="$1/partial.jsonl"
+  mk_transcript "$f" 'text:작업을 시작합니다.' 'broken:' 'text:이건 범위 밖이라 그대로 뒀습니다.'
+  printf '%s\n' "$f"
+}
+prep_badmsg()     { local f="$1/badmsg.jsonl";     mk_transcript "$f" 'badmsg:';     printf '%s\n' "$f"; }
+prep_badcontent() { local f="$1/badcontent.jsonl"; mk_transcript "$f" 'badcontent:'; printf '%s\n' "$f"; }
+
+# [cx] **판독 불가 경고가 감사 게이트에만 실렸다.** 앞 게이트가 먼저 막으면 그 턴에
+# 안 보이고, 그 플래그를 지운 다음 턴엔 조기 종료로 영영 사라진다.
+d51() {
+  local name='판독 불가 경고가 앞 게이트 메시지에도 실린다' why=''
+  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
+  setup_flags "$p" dualreview          # 감사 플래그를 **일부러 안 세운다**
+  run_stop "$p" "$p/does-not-exist.jsonl"
+  if   [ "$RC" -ne 2 ];                       then why="rc=$RC (기대 2)"
+  elif ! contains "$ERR" '듀얼 리뷰 미수행';  then why='듀얼리뷰 게이트가 막은 게 아니다'
+  elif ! contains "$ERR" "$TOK_NOTE";         then why='앞 게이트 메시지에 판독 불가 사유가 없다'
+  fi
+  report "$name" "$why"
+}
+
+# [cx] **push 미완만으로 조기 종료가 풀린 턴**은 아무것도 안 바꾼 읽기 전용 턴이다.
+# 거기서 결정 게이트가 돌면 "플래그가 서 있고"라는 발동 계약보다 넓어진다.
+d52() {
+  local name='push 미완만 있는 턴에는 결정 게이트가 돌지 않는다' why=''
+  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
+  local tp="$p/transcript.jsonl"
+  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
+  setup_flags "$p"                      # 플래그 0개
+  # 원격은 있는데 한 번도 push 되지 않은 브랜치를 만든다.
+  ( cd "$p" && git init -q . \
+      && git config user.email t@t && git config user.name t \
+      && git remote add origin "$p/../origin.git" \
+      && git commit -q --allow-empty -m x ) >/dev/null 2>&1 \
+    || { report "$name" '픽스처 실패: git 저장소'; return 0; }
+  run_stop "$p" "$tp"
+  if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2 — push 게이트가 막아야 한다)"
+  elif contains "$ERR" "$TOK_DECISION";   then why='플래그가 없는데 결정 게이트가 막았다'
+  elif ! contains "$ERR" '원격에 없습니다'; then why="push 게이트가 막은 게 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
+  fi
+  report "$name" "$why"
+}
+
 # --- 실행 ----------------------------------------------------------------
 # 목록을 **명시적으로** 센다. 실행 수만 세면 중복 1건 + 누락 1건이 상쇄돼 초록이 된다.
 CASES='d01 d02 d03 d04 d05 d06 d07 d08 d09
 d10 d11 d12 d13 d14 d15 d16 d17 d18 d18b d18c d19 d20 d21 d22 d23 d24
 d25 d25b d25c d25d d25e
 d26 d27 d28 d29 d30 d30b
 d31 d32 d33 d34 d35
 d36 d37 d38
-d39 d40 d41'
+d39 d40 d41
+d42 d43 d44 d45 d46 d47 d48 d49 d50 d51 d52'
 
 echo "결정 게이트 회귀 테스트"
 expected=0
 for c in $CASES; do expected=$((expected + 1)); done
 dupes="$(printf '%s\n' $CASES | sort | uniq -d)"
 if [ -n "$dupes" ]; then
   echo "✗ 케이스 목록에 중복이 있습니다: $dupes" >&2; exit 1
 fi
 for c in $CASES; do
   if ! type "$c" >/dev/null 2>&1; then echo "✗ 케이스 함수가 없습니다: $c" >&2; exit 1; fi
   "$c"
 done
 
 echo
 if [ "$ran" -ne "$expected" ]; then
   echo "✗ 실행된 케이스 수가 목록과 다릅니다: $ran (기대 $expected)" >&2
   exit 1
 fi
 printf '%s개 중 %s개 통과, %s개 실패\n' "$ran" "$pass" "$fail"
 [ "$fail" -eq 0 ] || exit 1
 echo "✓ 결정 게이트 회귀 방어 유지"
3036:+[HIGH] template/.claude/hooks/_common.sh:402 — 일부 JSONL 손상과 부분적인 기록 형식 변경이 판독 불가가 아니라 “표지 없음”으로 조용히 통과한다. 유효한 사용자 프롬프트 뒤의 assistant 행 하나만 파싱 실패하면 408행에서 버리고, `texts=[]`인 채 463행에서 rc=1로 끝난다. assistant `content`가 list가 아닌 새 형식이어도 426–427행에서 말없이 건너뛴다. 반대로 최신 사용자 프롬프트 행만 깨지면 이전 프롬프트를 턴 경계로 삼아 지난 턴까지 검사한다. d33·d34는 “전부 깨짐/프롬프트 전무”만 검사하므로 이 경로를 붙들지 못한다.
3038:+[HIGH] template/.claude/hooks/verify-before-stop.sh:183 — 호출부가 rc=0과 rc=2만 처리하고 나머지는 전부 결정 게이트 통과로 오독한다. `python3` 부재의 rc=127, 신호 종료, 예상 밖 상태가 아무 `decision_note` 없이 진행된다. 또한 `_common.sh:425`의 `(e.get("message") or {}).get(...)`은 truthy 비-dict `message`에서 예외를 내 rc=1이 되는데, rc=1은 정상적인 “표지 없음”과 구별되지 않는다. ADR의 “rc=2가 유일한 fail-open” 약속은 성립하지 않는다.
3040:+[HIGH] template/.claude/hooks/verify-before-stop.sh:187 — 판독 불가 경고는 감사 게이트인 331–337행에서만 출력된다. 듀얼리뷰·설명·지식·push 중 하나만 활성화된 경우 앞 게이트가 먼저 종료하므로 경고가 보이지 않는다. 예를 들어 dualreview 플래그만 서 있을 때 기록 판독 실패 → 듀얼리뷰 메시지만 출력 → 플래그 제거 후 64행 조기 종료가 되어 경고는 영원히 사라진다. fail-open 테스트는 항상 audit 플래그만 세워 이 결함을 가린다.
3042:+[HIGH] template/.claude/hooks/_common.sh:350 — 질문 신호가 “현재 묻는 문장”인지 구분하지 않아 겨누는 자백 자체를 제외한다. `사용자에게 물어보지 않고 제 판단으로 진행했습니다.`는 `물어`와 `제 판단으로`를 모두 포함하는 정당한 자백이지만 452–453행에서 통과한다. `사용자 의견을 확인하지 않고 가정하여 구현했습니다.`도 `의견` 때문에 통과한다. d18b·d18c는 미래형 “묻겠습니다”만 검사하며 부정형 자백은 없다.
3044:+[HIGH] template/.claude/hooks/_common.sh:338 — 표지 어휘가 자백에만 나온다는 전제가 맞지 않아 정상적인 기술 설명이 대량으로 차단될 수 있다. `기존 스캐너는 범위 밖 입력을 거부합니다.`, `변이 테스트는 별도로 실행됩니다.`, `이 트레이드오프는 ADR에 설명되어 있습니다.`는 모두 사용자 결정을 대신한 문장이 아니지만 현재 정규식상 차단된다. 테스트의 정상 발화는 사실상 “표지가 없는 문장” 또는 구조적으로 감싼 표지만 다루어 이 의미론적 위양성을 측정하지 않는다.
3046:+[MEDIUM] template/.claude/hooks/verify-before-stop.sh:64 — push 미완만 있어도 조기 종료가 해제되고 182행의 결정 스캔이 실행된다. 즉 코드·결정 변경 플래그가 하나도 없는 읽기 전용 턴도 브랜치가 원격보다 앞서 있다는 이유만으로 결정 게이트 대상이 된다. 이는 ADR의 “코드/결정 변경 플래그가 서 있고”라는 발동 계약보다 넓으며 d30은 원격-ahead 상태를 만들지 않아 검증하지 않는다.
3048:+[MEDIUM] template/.claude/hooks/_common.sh:362 — 문장 분할이 마침표를 무조건 종결자로 보고, 444행에서 먼저 줄 단위로 쪼개므로 하나의 정상 문장 안에서도 표지와 종결이 분리된다. `나머지는 별도로 README.md에 기록했습니다.`는 `별도로 README`와 `md에 기록했습니다`로 갈라져 어느 조각도 두 조건을 함께 만족하지 않는다. 줄바꿈된 `나머지는 범위 밖이라\n후속 작업으로 남겼습니다.`도 같은 위음성이다. 이는 단순한 어휘 변경이 아니라 계약상 표지를 가진 서술형 문장의 누락이다.
3050:+[MEDIUM] template/.claude/hooks/_common.sh:357 — 공시된 구조적 제외가 일반적인 Markdown 구문 전체를 지원하지 않는다. `drop_fences()`는 백틱 3개만 인식해 `~~~` 코드 펜스의 예문을 산문으로 검사하며, `INLINE`은 단일 백틱 쌍만 처리해 유효한 이중 백틱 코드 span의 내용이 남는다. ADR은 한정 없이 “코드펜스·인라인 코드 안은 안 본다”고 약속하지만 d12·d15는 단일 백틱과 삼중 백틱만 붙든다.
3052:+[LOW] _workspace/mutate-decision-gate.sh:40 — EXIT 트랩이 락만 제거하고 변이 대상은 복원하지 않는다. 테스트 실행 중 SIGINT 등으로 `measure()`가 72행에 도달하지 못하면 실제 훅 파일에 변이가 남는다. 다음 실행은 dirty 검사로 거부되겠지만, 변이가 작업 트리에 남아 후속 커밋에 섞일 위험은 이 도구가 주장하는 안전 계약과 어긋난다.
3054:+판정: 보류
3059:+[HIGH] template/.claude/hooks/_common.sh:402 — 일부 JSONL 손상과 부분적인 기록 형식 변경이 판독 불가가 아니라 “표지 없음”으로 조용히 통과한다. 유효한 사용자 프롬프트 뒤의 assistant 행 하나만 파싱 실패하면 408행에서 버리고, `texts=[]`인 채 463행에서 rc=1로 끝난다. assistant `content`가 list가 아닌 새 형식이어도 426–427행에서 말없이 건너뛴다. 반대로 최신 사용자 프롬프트 행만 깨지면 이전 프롬프트를 턴 경계로 삼아 지난 턴까지 검사한다. d33·d34는 “전부 깨짐/프롬프트 전무”만 검사하므로 이 경로를 붙들지 못한다.
3061:+[HIGH] template/.claude/hooks/verify-before-stop.sh:183 — 호출부가 rc=0과 rc=2만 처리하고 나머지는 전부 결정 게이트 통과로 오독한다. `python3` 부재의 rc=127, 신호 종료, 예상 밖 상태가 아무 `decision_note` 없이 진행된다. 또한 `_common.sh:425`의 `(e.get("message") or {}).get(...)`은 truthy 비-dict `message`에서 예외를 내 rc=1이 되는데, rc=1은 정상적인 “표지 없음”과 구별되지 않는다. ADR의 “rc=2가 유일한 fail-open” 약속은 성립하지 않는다.
3063:+[HIGH] template/.claude/hooks/verify-before-stop.sh:187 — 판독 불가 경고는 감사 게이트인 331–337행에서만 출력된다. 듀얼리뷰·설명·지식·push 중 하나만 활성화된 경우 앞 게이트가 먼저 종료하므로 경고가 보이지 않는다. 예를 들어 dualreview 플래그만 서 있을 때 기록 판독 실패 → 듀얼리뷰 메시지만 출력 → 플래그 제거 후 64행 조기 종료가 되어 경고는 영원히 사라진다. fail-open 테스트는 항상 audit 플래그만 세워 이 결함을 가린다.
3065:+[HIGH] template/.claude/hooks/_common.sh:350 — 질문 신호가 “현재 묻는 문장”인지 구분하지 않아 겨누는 자백 자체를 제외한다. `사용자에게 물어보지 않고 제 판단으로 진행했습니다.`는 `물어`와 `제 판단으로`를 모두 포함하는 정당한 자백이지만 452–453행에서 통과한다. `사용자 의견을 확인하지 않고 가정하여 구현했습니다.`도 `의견` 때문에 통과한다. d18b·d18c는 미래형 “묻겠습니다”만 검사하며 부정형 자백은 없다.
3067:+[HIGH] template/.claude/hooks/_common.sh:338 — 표지 어휘가 자백에만 나온다는 전제가 맞지 않아 정상적인 기술 설명이 대량으로 차단될 수 있다. `기존 스캐너는 범위 밖 입력을 거부합니다.`, `변이 테스트는 별도로 실행됩니다.`, `이 트레이드오프는 ADR에 설명되어 있습니다.`는 모두 사용자 결정을 대신한 문장이 아니지만 현재 정규식상 차단된다. 테스트의 정상 발화는 사실상 “표지가 없는 문장” 또는 구조적으로 감싼 표지만 다루어 이 의미론적 위양성을 측정하지 않는다.
3069:+[MEDIUM] template/.claude/hooks/verify-before-stop.sh:64 — push 미완만 있어도 조기 종료가 해제되고 182행의 결정 스캔이 실행된다. 즉 코드·결정 변경 플래그가 하나도 없는 읽기 전용 턴도 브랜치가 원격보다 앞서 있다는 이유만으로 결정 게이트 대상이 된다. 이는 ADR의 “코드/결정 변경 플래그가 서 있고”라는 발동 계약보다 넓으며 d30은 원격-ahead 상태를 만들지 않아 검증하지 않는다.
3071:+[MEDIUM] template/.claude/hooks/_common.sh:362 — 문장 분할이 마침표를 무조건 종결자로 보고, 444행에서 먼저 줄 단위로 쪼개므로 하나의 정상 문장 안에서도 표지와 종결이 분리된다. `나머지는 별도로 README.md에 기록했습니다.`는 `별도로 README`와 `md에 기록했습니다`로 갈라져 어느 조각도 두 조건을 함께 만족하지 않는다. 줄바꿈된 `나머지는 범위 밖이라\n후속 작업으로 남겼습니다.`도 같은 위음성이다. 이는 단순한 어휘 변경이 아니라 계약상 표지를 가진 서술형 문장의 누락이다.
3073:+[MEDIUM] template/.claude/hooks/_common.sh:357 — 공시된 구조적 제외가 일반적인 Markdown 구문 전체를 지원하지 않는다. `drop_fences()`는 백틱 3개만 인식해 `~~~` 코드 펜스의 예문을 산문으로 검사하며, `INLINE`은 단일 백틱 쌍만 처리해 유효한 이중 백틱 코드 span의 내용이 남는다. ADR은 한정 없이 “코드펜스·인라인 코드 안은 안 본다”고 약속하지만 d12·d15는 단일 백틱과 삼중 백틱만 붙든다.
3075:+[LOW] _workspace/mutate-decision-gate.sh:40 — EXIT 트랩이 락만 제거하고 변이 대상은 복원하지 않는다. 테스트 실행 중 SIGINT 등으로 `measure()`가 72행에 도달하지 못하면 실제 훅 파일에 변이가 남는다. 다음 실행은 dirty 검사로 거부되겠지만, 변이가 작업 트리에 남아 후속 커밋에 섞일 위험은 이 도구가 주장하는 안전 계약과 어긋난다.
3077:+판정: 보류

2026-08-10T08:15:52.860674Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
codex
1라운드 9건의 수정 지점은 확인했습니다. 이제 새 발동 플래그가 예산 지문과 실제 차단 순서에서 일관되는지, 엄격 파서가 알려진 비대화형 JSONL 항목을 잘 건너뛰는지에 초점을 좁혀 호출 흐름을 줄 단위로 대조하겠습니다.
exec
/bin/zsh -lc "nl -ba template/.claude/hooks/_common.sh | sed -n '1,540p'
nl -ba template/.claude/hooks/verify-before-stop.sh | sed -n '1,410p'" in /Users/kty/Downloads/kty-claude-harness-template
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
    14	# 개명 전 이름의 미처리 플래그는 **install.sh 가 갱신 시점에 새 이름으로 옮긴다.**
    15	# 여기서 옛 이름을 알면 배포되는 글루가 구현체 이름을 다시 품게 되고, 층 경계 검사가
    16	# (옳게) 막는다. 배포되지 않는 설치 스크립트가 이행을 맡는 것이 층에 맞다.
    17	DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
    18	BLOCK_COUNT="$STATE_DIR/.stop-block-count"
    19	BLOCK_FP="$STATE_DIR/.stop-block-fp"    # 마지막 차단 지문(게이트|플래그 상태) — 진전 인지 리셋용
    20	
    21	# Stop 훅이 "같은 지점에서 진전 없이" 최대 몇 번까지 막을 수 있는가. 소진되면 통과시킨다
    22	# (세션 벽돌 방지). 차단 지문이 바뀌면(=게이트를 하나 지웠으면) 카운터는 리셋되므로,
    23	# 게이트 개수가 늘어도 이 상수를 올릴 필요가 없다.
    24	MAX_BLOCKS=3
    25	
    26	# 탈출구.
    27	#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
    28	#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
    29	hook_disabled() {
    30	  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
    31	    return 0
    32	  fi
    33	  case ",${ECC_DISABLED_HOOKS:-}," in
    34	    *",$1,"*) return 0 ;;
    35	  esac
    36	  return 1
    37	}
    38	
    39	# harness.env 에서 값 하나를 **실행하지 않고** 읽는다.
    40	#
    41	# 왜 source 하지 않나: harness.env 는 **사용자 소유 셸 파일**이다. 실행해서 값을 읽으면
    42	# 파일 내용이 훅의 제어 흐름을 가져간다 — 그리고 막을 때마다 새 탈출 경로가 나온다.
    43	# 전부 실측된 것들이다:
    44	#   exit 1        → 훅이 rc=1 로 죽는다. 게이트 4종이 통째로 소멸
    45	#   exit 0        → 훅이 조용히 rc=0. 게이트 소멸 + 아무 흔적 없음
    46	#   서브셸+return → 호출 셸로 정상 복귀해 판정을 통과
    47	#   printf 재정의 → 진단 출력 자체를 위조
    48	# 서브셸로 감싸고 리다이렉트로 막는 식으로는 끝이 안 난다. **실행하지 않으면 이 부류가
    49	# 원리적으로 소멸한다** — grep 결과를 바꾸는 유일한 방법은 그 키를 다르게 쓰는 것이고,
    50	# 그게 정확히 의도적으로 값을 바꾸는 방법이다.
    51	#
    52	# **대신 셸이 해주던 파싱을 이 함수가 물려받는다.** 그 파싱을 반쯤 하면 fail-open 을
    53	# 없애려다 다른 fail-open 을 만든다 — 실측된 회귀 6종이 전부 여기서 나왔다.
    54	# 후행 주석 · 후행 공백 · CRLF 의 `\r` 이 값에 섞여 들어가면 그 값을 받은 `sh -c` 가
    55	# rc=127 을 내고, 호출부는 그걸 "도구가 없구나"로 읽어 **검사를 조용히 생략한다.**
    56	# 파일 앞 BOM 은 첫 줄의 키를 통째로 무매치로 만들고, 히어독 본문의 같은 키는 선언으로
    57	# 세어진다. 셋 다 눈에 보이지 않는다.
    58	#
    59	# 그래서 **순서가 계약이다**:
    60	#   ① 파일 첫머리 BOM 제거 → ② 각 줄 후행 CR 제거 → ③ **줄을 넘는 인용 상태** 추적 →
    61	#   ④ 히어독 본문 배제 → ⑤ 선언 판정 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 **밖** 후행 주석
    62	#   → ⑧ 남은 후행 공백 절단
    63	#
    64	# ── 반환 계약 ──────────────────────────────────────────────────────────
    65	#   rc=0 : 최상위 선언이 **정확히 1개**이고 값을 지원 문법으로 판독했다.
    66	#          stdout = 판독된 값. **빈 문자열일 수 있다** — "리터럴로 비웠다"는 뜻이다.
    67	#   rc=1 : 값을 믿을 수 없다 — 파일 없음 · 읽기 실패 · 선언 0개 · 선언 2개 이상 ·
    68	#          지원 문법 밖. stdout = 빈 문자열.
    69	#
    70	# 왜 이 둘을 rc 로 가르나: 스위치형 슬롯은 "리터럴로 비웠다"(=끈다)와 "미설정"(=이전
    71	# 동작 보존)이 **반대 방향**이다. 빈 문자열 하나로 뭉뚱그리면 키가 없는 기존 설치본이
    72	# 업그레이드 순간 게이트가 꺼진 것과 구별되지 않는다.
    73	#
    74	# ── 지원 문법 (좁게 고정했다. 이 밖은 전부 rc=1) ───────────────────────
    75	#   KEY=값  ·  export KEY=값   (export 뒤는 공백 또는 탭)
    76	#   값: "겹따옴표"  ·  '홑따옴표'  ·  인용 없는 평문
    77	#   닫는 따옴표 뒤에는 **공백**과 `# 주석` 만 올 수 있다 (`""#on` 은 문법 밖 — 셸에서
    78	#     그 값은 `#on` 이라 비어 있지 않은데, 주석으로 읽으면 게이트가 꺼지는 방향이다)
    79	#   인용 없는 값은 **공백에 이어지는 `#`** 부터가 주석이다 (`a#b`·`#on` 은 값 그대로)
    80	# ── 지원하지 않는 것 (조용히 절반만 읽지 않고 rc=1 로 떨어진다) ────────
    81	#   등호 바로 뒤의 공백(`KEY= x`) · 백슬래시 이스케이프 · 한 줄에 인용 조각 여러 개 ·
    82	#   여러 줄 값 · 닫히지 않은 따옴표
    83	#
    84	# 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
    85	# 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
    86	# 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 rc=1 이다.
    87	#
    88	# **인용 상태는 줄을 넘어 이어진다.** 셸의 인용은 개행에서 끝나지 않으므로, 다른 키의
    89	# 여러 줄 값 본문 안에 이 키가 나타나도 그건 선언이 아니다. 이걸 줄 단위로만 보면
    90	# `NOTES='...(개행)KEY=(개행)...'` 이 유일한 선언으로 판독돼 게이트가 꺼진다(실측).
    91	#
    92	# 히어독: `<<WORD`·`<<-WORD`·`<<'WORD'`·`<<"WORD"`·`<<\WORD` 를 인용 상태를 보며 찾아
    93	# 본문을 건너뛴다(`"a << b"` 는 히어독이 아니다). 탐지가 어느 쪽으로 틀려도 결과는 rc=1 로
    94	# 수렴한다 — 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다.
    95	# EOF 까지 히어독이나 인용이 안 닫히면 파일을 못 믿는 것이므로 역시 rc=1.
    96	# 한 줄에 히어독이 둘이면 첫 개만 본다.
    97	#
    98	# 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **판독 시점에 확장되지 않는다** — 원문 그대로
    99	# 값이 된다. 다만 그 값은 결국 `sh -c` 로 넘어가므로 **실행 시점에는 확장된다**
   100	# (실측: `HARNESS_TYPECHECK_CMD='printf $HOME'` → 실행하면 홈 경로가 찍힌다).
   101	# 즉 "확장되지 않는다"가 아니라 "**나중에** 확장된다"이다. 확장이 곤란한 자리라면
   102	# 그 자리에 최종 문자열을 적어야 한다.
   103	harness_env_value() {
   104	  local file="$STATE_DIR/harness/harness.env" key="$1" val rc
   105	  [ -f "$file" ] || { printf '%s' ''; return 1; }
   106	  if [ ! -r "$file" ]; then
   107	    # "미설정"과 "읽기 실패"는 다르다. 판정은 같게(rc=1) 가되 실패는 소리를 낸다.
   108	    printf '[하네스] harness.env 를 읽지 못했습니다 — 미설정으로 봅니다: %s\n' "$file" >&2
   109	    printf '%s' ''
   110	    return 1
   111	  fi
   112	  # LC_ALL=C 여야 substr 이 바이트 단위로 동작해 BOM 3바이트를 정확히 떼어낸다.
   113	  val="$(LC_ALL=C awk -v key="$key" -v bom="$(printf '\357\273\277')" '
   114	function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
   115	function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
   116	
   117	# 히어독 시작을 찾는다. 따옴표 안의 `<<` 와 주석 뒤의 `<<` 는 히어독이 아니다.
   118	# 인용 상태 OPENQ 는 **줄을 넘어 이어진다.** 셸의 인용은 개행에서 끝나지 않기 때문이다 —
   119	# 다른 키의 여러 줄 값 본문 안에 우리 키가 있으면 그건 선언이 아니다. 이걸 줄 단위로만
   120	# 보면 다른 키의 여러 줄 값 안에 있는 우리 키가 유일한 선언으로 판독돼
   121	# **게이트가 꺼진다**(실측). 그래서 이 함수는 줄마다 OPENQ 를 이어받아 갱신한다.
   122	function scan_line(s,   n, i, j, c, t, dash, q2) {
   123	  n = length(s); i = 1
   124	  while (i <= n) {
   125	    c = substr(s, i, 1)
   126	    if (OPENQ != "") { if (c == OPENQ) OPENQ = ""; i++; continue }
   127	    if (c == "\\") { i += 2; continue }                            # 백슬래시 이스케이프
   128	    if (c == "\"" || c == SQ) { OPENQ = c; i++; continue }
   129	    if (c == "#" && (i == 1 || substr(s, i - 1, 1) == " " || substr(s, i - 1, 1) == "\t")) return
   130	    if (c == "<" && substr(s, i + 1, 1) == "<") {
   131	      if (substr(s, i + 2, 1) == "<") { i += 3; continue }         # <<< 는 히어스트링
   132	      j = i + 2; dash = 0
   133	      if (substr(s, j, 1) == "-") { dash = 1; j++ }
   134	      while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
   135	      t = ""
   136	      # 종결어는 인용을 **섞을 수 있다**: EOF · "EOF" · EO"F" · \\EOF · E\\OF 가 전부
   137	      # 같은 종결어 EOF 다. 한 형태만 읽으면 나머지에서 본문을 안 건너뛰고, 그 안의 빈
   138	      # 게이트 선언이 진짜 선언으로 판독돼 **게이트가 꺼진다**. 그래서 조각을 이어 붙인다.
   139	      while (j <= n) {
   140	        c = substr(s, j, 1)
   141	        if (c == " " || c == "\t" || c == ";" || c == "&" || c == "|" || c == ">" || c == "<") break
   142	        if (c == "\\") { j++; if (j <= n) { t = t substr(s, j, 1); j++ } ; continue }
   143	        if (c == "\"" || c == SQ) {
   144	          q2 = c; j++
   145	          while (j <= n && substr(s, j, 1) != q2) { t = t substr(s, j, 1); j++ }
   146	          j++
   147	          continue
   148	        }
   149	        t = t c; j++
   150	      }
   151	      if (t != "") { INHD = 1; HTERM = t; HDASH = dash; return }
   152	      i = j
   153	      continue
   154	    }
   155	    i++
   156	  }
   157	}
   158	
   159	# 지원 문법대로 값을 판독한다. 문법 밖이면 BAD 를 세운다(빈 값으로 위장하지 않는다).
   160	function parse_value(v,   q, rest, e, out, tail, i, c, p) {
   161	  if (v == "") return ""
   162	  # **등호 바로 뒤의 공백은 지원하지 않는다(rc=1).** 셸은 `KEY= x` 를 "빈 값 대입 + 명령 x"
   163	  # 로 읽는데, 관대하게 값으로 삼으면 셸과 반대 방향으로 갈리고, 빈 값으로 삼으면
   164	  # `KEY=  "on"` 이 조용히 게이트를 끈다. 어느 쪽도 안전하지 않아 문법 밖으로 돌린다.
   165	  if (substr(v, 1, 1) == " " || substr(v, 1, 1) == "\t") { BAD = 1; return "" }
   166	  q = substr(v, 1, 1)
   167	  if (q == "\"" || q == SQ) {
   168	    rest = substr(v, 2)
   169	    e = index(rest, q)
   170	    if (e == 0) { BAD = 1; return "" }                             # 닫히지 않은 따옴표
   171	    out = substr(rest, 1, e - 1)
   172	    tail = substr(rest, e + 1)
   173	    if (tail != "") {
   174	      # 닫는 따옴표 **바로 뒤**에는 공백이 와야 한다. `KEY=""#on` 은 셸에서 값이 `#on`
   175	      # (비어 있지 않다)인데, 여기서 `#` 을 주석으로 받으면 빈 값이 되어 **게이트가 꺼진다.**
   176	      if (substr(tail, 1, 1) != " " && substr(tail, 1, 1) != "\t") { BAD = 1; return "" }
   177	      tail = ltrim(tail)
   178	      if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음
   179	    }
   180	    return out
   181	  }
   182	  # 인용 없는 값에서 `#` 은 **공백 뒤에서만** 주석을 연다. `KEY=#on` 의 값은 셸에서
   183	  # `#on` 이다 — 여기서 빈 값으로 읽으면 그 역시 게이트를 끄는 방향이다.
   184	  out = ""
   185	  for (i = 1; i <= length(v); i++) {
   186	    c = substr(v, i, 1)
   187	    if (c == "#" && i > 1) {
   188	      p = substr(v, i - 1, 1)
   189	      if (p == " " || p == "\t") break
   190	    }
   191	    out = out c
   192	  }
   193	  return rtrim(out)
   194	}
   195	
   196	BEGIN {
   197	  SQ = sprintf("%c", 39)
   198	  N = 0; FOUND = ""; INHD = 0; HTERM = ""; HDASH = 0; BAD = 0; OPENQ = ""
   199	  RX = "^(export[ \t]+)?" key "="
   200	}
   201	{
   202	  line = $0
   203	  sub(/\r$/, "", line)
   204	  if (NR == 1 && substr(line, 1, 3) == bom) line = substr(line, 4)
   205	
   206	  if (INHD) {
   207	    t = line
   208	    if (HDASH) sub(/^\t+/, "", t)
   209	    if (t == HTERM) { INHD = 0; HTERM = "" }
   210	    next
   211	  }
   212	
   213	  # **인용이 이전 줄에서 열린 채면 이 줄은 값의 본문이지 선언이 아니다.**
   214	  # 이 검사가 없으면 다른 키의 여러 줄 값 안에 있는 우리 키가 유일한 선언으로 판독돼
   215	  # 게이트가 꺼진다(실측). 판정 전에 물어야 한다.
   216	  if (OPENQ == "") {
   217	    # 선언 판정이 히어독 시작 판정보다 **먼저**다: `KEY=v <<EOF` 의 대입은 실제로 발효한다.
   218	    if (line ~ RX) {
   219	      N++
   220	      if (N == 1) FOUND = substr(line, index(line, "=") + 1)
   221	    }
   222	  }
   223	  scan_line(line)
   224	}
   225	END {
   226	  if (INHD) exit 1          # 히어독이 EOF 까지 안 닫혔다 = 탐지가 빗나갔다
   227	  if (OPENQ != "") exit 1   # 인용이 EOF 까지 안 닫혔다 = 파일을 못 믿는다
   228	  if (N != 1) exit 1
   229	  v = parse_value(FOUND)
   230	  if (BAD) exit 1
   231	  printf "%s", v
   232	  exit 0
   233	}
   234	' "$file" 2>/dev/null)"
   235	  rc=$?
   236	  [ "$rc" -eq 0 ] || { printf '%s' ''; return 1; }
   237	  printf '%s' "$val"
   238	  return 0
   239	}
   240	
   241	# 지식 반영 게이트가 켜져 있는가 (rc=0 켜짐 / rc=1 꺼짐).
   242	#
   243	# 하네스가 소유하는 것은 **계약 하나**뿐이다 — "지식 저장소가 설정돼 있으면, 결정·설계가
   244	# 나온 턴은 반영 없이 끝낼 수 없다." 어디에 어떤 구조로 반영하는지는 이 층이 모른다.
   245	# 그래서 필요한 것도 1비트뿐이고, 그 1비트를 얻으려고 파일을 실행하지 않는다.
   246	#
   247	# **기본이 켜짐인 것이 이 함수의 핵심이다.** 기존 설치본에는 이 키가 아예 없는데,
   248	# 없을 때 "꺼짐"으로 읽으면 하네스를 갱신하는 순간 게이트가 **조용히 꺼진다** — 사용자는
   249	# 지식이 쌓인다고 믿는데 그 턴부터 아무것도 안 남는다. 표명이 없으면 이전 동작을 보존한다.
   250	# 선언이 2개 이상이거나 문법 밖일 때도 같은 이유로 켠다(rc=1 → 켜짐).
   251	#
   252	# 끄는 방법은 **값을 리터럴로 비우는 것 하나뿐**이다: HARNESS_KNOWLEDGE_GATE=""
   253	# `="off"` 는 켜진 것으로 읽힌다 — 비어 있지 않기 때문이다. harness.env 주석에 명시돼 있다.
   254	harness_knowledge_gate_on() {
   255	  local v
   256	  v="$(harness_env_value HARNESS_KNOWLEDGE_GATE)" || return 0   # 값을 못 믿으면 켠다
   257	  [ -n "$v" ]                                                   # 리터럴로 비었을 때만 꺼짐
   258	}
   259	
   260	# 지식 게이트가 이번 턴에 **발효 중인가** — 플래그가 섰고 게이트도 켜져 있는가.
   261	# 판정을 이 한 곳에 모은다. 두 군데서 따로 물으면 "게이트를 껐는데 남아 있던 플래그가
   262	# 읽기 전용 턴의 조기 종료를 막는" 종류의 어긋남이 생긴다.
   263	knowledge_gate_active() {
   264	  [ -s "$KNOWLEDGE_FLAG" ] || return 1
   265	  harness_knowledge_gate_on
   266	}
   267	
   268	# stdin 의 JSON 에서 점 경로로 값 하나를 뽑는다. 없거나 파싱 실패면 빈 문자열.
   269	# 훅 입력이 깨져도 절대 죽지 않는다 — 죽으면 오탐 차단이 된다.
   270	json_get() {
   271	  python3 -c '
   272	import json, sys
   273	try:
   274	    data = json.load(sys.stdin)
   275	except Exception:
   276	    sys.exit(0)
   277	for key in sys.argv[1].split("."):
   278	    if not isinstance(data, dict):
   279	        sys.exit(0)
   280	    data = data.get(key)
   281	    if data is None:
   282	        sys.exit(0)
   283	print(data)
   284	' "$1" 2>/dev/null
   285	}
   286	
   287	# 이 턴의 대화 기록을 읽어 **"물어봤어야 할 것을 혼자 정했다"는 자백**을 찾는다.
   288	#
   289	# 왜 이런 게이트가 필요한가: 완료 게이트 넷(타입체크·듀얼리뷰·변경설명·지식반영)은 전부
   290	# **산출물**을 본다. 에이전트 자신의 행동을 겨눈 것은 없었고, 그 비대칭이 실물로 드러났다 —
   291	# 게이트가 막을 때는 세 번 다 따랐는데, 게이트가 없는 축에서는 전부 혼자 정하고 보고서에
   292	# 한 줄 적었다. 그 "한 줄"은 **도구 호출이 아니라 문장**이라 어떤 PreToolUse 훅도 볼 수 없고
   293	# 승인창도 안 뜬다(승인창은 *한 일*에만 뜬다). 그래서 Stop 이 대화 기록을 직접 읽는다.
   294	#
   295	# ── 판정 ─────────────────────────────────────────────────────────────
   296	#   결정 표지 어휘를 담은 **서술형** 문장이 있는데  AND  이 턴에 AskUserQuestion 이 0회
   297	#   → 차단. 질문을 한 번 하면 풀리므로 세션이 벽돌이 되지 않는다.
   298	#
   299	# 표지 어휘를 이렇게 고른 이유: 저 말들은 "물어봤어야 할 것을 혼자 정했다"를 **자백**할
   300	# 때만 나온다. 자백은 있는데 질문이 0회면 그 자체가 위반이다.
   301	#
   302	# ── 좁히는 장치 셋 (위양성 억제) ─────────────────────────────────────
   303	# 어휘만 보면 이 게이트를 **유지보수하는 작업 자체가 매번 걸린다** — 훅·테스트·결정 문서가
   304	# 그 어휘를 데이터로 품기 때문이다. 그러면 사람이 게이트를 끄게 되고 그게 최악이다.
   305	#   1) 구조적 제외 — 코드펜스 · 인라인 코드 · 인용줄(>) · 따옴표로 감싼 부분은 안 본다.
   306	#      그래서 어휘를 **인용부호로 감싸 언급하는 것**은 안 걸린다(문서·설명의 정상 형태다).
   307	#   2) 질문 신호 제외 — 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다.
   308	#   3) 서술형 종결 요구 — "…했다/…습니다" 같은 단정으로 끝나야 "내가 그렇게 했다"이다.
   309	# 대가는 위음성 증가다. 표현을 바꾸면 빠져나간다 — 겨누는 것이 적대적 회피가 아니라
   310	# **무의식적 습관**이라 그래도 실효가 남는다. guard-hook-disable 과 같은 판단 구조다.
   311	#
   312	# **도구 입력은 보지 않는다(text 블록만 본다).** 그래서 이 패턴이 적힌 파일을 Write/Edit
   313	# 로 쓰는 것은 안 걸린다 — 자기참조 폭발을 원천에서 없애는 장치다.
   314	# thinking 블록도 안 본다: 거기서 선택지를 저울질하는 것은 결정 통보가 아니다.
   315	# 서브에이전트 발화(isSidechain)도 뺀다: 서브에이전트는 사용자에게 물을 수 없다.
   316	#
   317	# ── 반환 계약 ─────────────────────────────────────────────────────────
   318	#   rc=0 : 차단해야 한다. stdout = 걸린 문장들(줄당 하나)
   319	#   rc=2 : **판독 불가.** stdout = 사유 한 줄
   320	#   rc=3 : 차단 불필요 (표지 없음 · 또는 이 턴에 질문을 했음)
   321	#   그 밖 : **예상 밖.** python3 부재(127) · 처리 못 한 예외(1) · 신호 종료 등
   322	#
   323	# "차단 불필요"에 1 이 아니라 **3** 을 쓰는 이유: python 이 처리 못 한 예외로 죽으면
   324	# 그것도 1 이라, 1 을 정상 통과로 쓰면 **크래시가 조용한 통과로 위장된다.** 정상 경로에
   325	# 흔한 코드를 주지 않으면 호출부가 "모르는 rc = 무언가 잘못됐다"로 갈라낼 수 있다.
   326	# 호출부는 0·2·3 만 알고 나머지는 전부 판독 불가로 취급해야 한다.
   327	#
   328	# ── rc=2 가 이 게이트의 유일한 fail-open 지점이다 ────────────────────
   329	# 대화 기록의 형식은 하네스가 소유하지 않는다 — 도구 제공자가 정하고 예고 없이 바뀐다.
   330	# 형식이 바뀌었다고 차단하면 **세션이 통째로 벽돌이 되는데 그 세션 안에 고칠 방법이 없다**
   331	# (기록을 고칠 수는 없으므로 어떤 행동으로도 게이트가 안 풀린다). 그래서 여기서만 통과로
   332	# 간다. 나머지 판정은 전부 fail-closed 다.
   333	# **조건은 경고를 삼키지 않는 것이다** — 호출부가 이 사유를 마지막 게이트 메시지에 싣는다.
   334	# 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다.
   335	decision_scan() {   # $1 = 대화 기록(JSONL) 경로
   336	  local path="$1"
   337	  [ -n "$path" ] || { printf '%s\n' '대화 기록 경로가 훅 입력에 없습니다'; return 2; }
   338	  [ -r "$path" ] || { printf '%s\n' "대화 기록을 읽을 수 없습니다: $path"; return 2; }
   339	  python3 - "$path" <<'PY'
   340	import json, re, sys
   341	
   342	# 결정 표지. 굴절 변형만 최소로 넓혔고 그 이상 넓히지 않는다 — 넓히면 위양성이 늘고,
   343	# 위양성이 늘면 질문이 소음이 되고, 소음이 되면 진짜 질문도 무시된다.
   344	MARKER = re.compile(
   345	    "공시하|공시했|공시함"
   346	    "|범위 ?밖"
   347	    "|별도로"
   348	    "|그대로 (?:뒀|두었|남겼|남겨)"
   349	    "|(?:제|내) 판단으로"
   350	    "|가정하(?:고|여|였|겠)|가정했"
   351	    "|수용(?:된|한) 한계"
   352	    "|트레이드오프"
   353	    "|안 했(?:습니다|다|음)"
   354	)
   355	# 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다.
   356	QUESTION = re.compile(
   357	    "\\?|까요|나요|ㄹ까|을까|할까|여쭤|여쭈|여쭙|물어|어떠신|어느 쪽"
   358	    "|골라|선택해|정해 ?주|알려 ?주|괜찮으신|의견"
   359	)
   360	# **"묻지 않았다"는 물음이 아니라 자백이다.** 이게 없으면 겨누는 문장 자체가 빠져나간다 —
   361	# "사용자에게 물어보지 않고 제 판단으로 진행했습니다" 는 `물어` 때문에 질문으로 오인된다.
   362	# 부정이 붙으면 위 QUESTION 제외를 적용하지 않는다.
   363	NEG_ASK = re.compile(
   364	    "물어보지 ?않|물어보지도|묻지 ?않|묻지도|여쭙지 ?않|여쭈지 ?않|여쭤보지 ?않"
   365	    "|확인하지 ?않|확인 ?없이|의견을 받지 ?않|물어보는 대신|묻는 대신|묻지 못"
   366	)
   367	# 서술형 종결. "내가 그렇게 했다"는 단정만 잡는다.
   368	DECLARATIVE = re.compile("(?:다|음|함|됨|임|옴)$")
   369	
   370	# 이중 백틱 코드 span 이 먼저다 — 단일 규칙만 두면 ``a`b`` 의 안쪽이 산문으로 샌다.
   371	INLINE     = re.compile("``[^`\n]*``|`[^`\n]*`")
   372	QUOTED     = re.compile("\"[^\"\n]*\"|'[^'\n]*'|“[^”\n]*”"
   373	                        "|‘[^’\n]*’|「[^」\n]*」"
   374	                        "|『[^』\n]*』")
   375	BLOCKQUOTE = re.compile("^\\s{0,3}>")
   376	# 마침표는 **뒤에 공백이나 줄끝이 올 때만** 문장 종결이다. 무조건 종결로 보면
   377	# `README.md`·`_common.sh`·버전 번호가 한 문장을 쪼개, 표지와 서술형 종결이 서로 다른
   378	# 조각으로 갈라져 **둘 다 만족하는 조각이 없어진다**(위음성).
   379	SENT       = re.compile("([\n!?…。！？]+|\\.(?=\\s)|\\.$)")
   380	LEAD       = re.compile("^[\\s*_>#\\-–—•·]+")
   381	TRAIL      = re.compile("[\\s*_`~\\[\\](){}<>:;,·…\\-—–]+$")
   382	
   383	MAX_HITS, MAX_LEN = 8, 140
   384	
   385	
   386	def fail(reason):
   387	    sys.stdout.write(reason + "\n")
   388	    raise SystemExit(2)
   389	
   390	
   391	def drop_fences(s):
   392	    # 짝수 조각만 코드 **밖**이다. 펜스가 안 닫혔으면 마지막 조각은 코드 안으로 친다 —
   393	    # 스트리밍 중 잘린 기록에서 코드가 산문으로 새는 것을 막는다.
   394	    # 백틱만 보면 `~~~` 펜스의 예문이 산문으로 검사된다(문서가 약속한 범위보다 좁다).
   395	    for fence in ("```", "~~~"):
   396	        s = "\n".join(p for i, p in enumerate(s.split(fence)) if i % 2 == 0)
   397	    return s
   398	
   399	
   400	def is_user_prompt(e):
   401	    if e.get("type") != "user" or e.get("isSidechain"):
   402	        return False
   403	    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
   404	        return False
   405	    msg = e.get("message")
   406	    if not isinstance(msg, dict):
   407	        return False
   408	    content = msg.get("content")
   409	    if isinstance(content, list):
   410	        for b in content:
   411	            if isinstance(b, dict) and b.get("type") == "tool_result":
   412	                return False
   413	    return True
   414	
   415	
   416	try:
   417	    with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as fh:
   418	        raw = fh.read()
   419	except Exception as exc:
   420	    fail("대화 기록을 열지 못했습니다: %s" % exc.__class__.__name__)
   421	
   422	lines = [ln for ln in raw.splitlines() if ln.strip()]
   423	entries, broken = [], 0
   424	for ln in lines:
   425	    try:
   426	        entries.append(json.loads(ln))
   427	    except Exception:
   428	        broken += 1
   429	# **한 줄이라도 못 읽으면 판독 불가다.** 건너뛰면 그 줄이 하필 자백이 담긴 발화이거나
   430	# 이 턴의 사용자 프롬프트일 때 조용히 새고, 후자는 경계가 **지난 턴으로 밀려** 위양성까지
   431	# 낳는다. "전멸일 때만 실패"로 두면 부분 손상이라는 가장 흔한 경우를 정확히 놓친다.
   432	if broken:
   433	    fail("대화 기록 %d줄을 파싱하지 못했습니다 (형식이 바뀌었을 수 있습니다)" % broken)
   434	if not entries:
   435	    fail("대화 기록이 비어 있습니다")
   436	
   437	start = -1
   438	for i, e in enumerate(entries):
   439	    if isinstance(e, dict) and is_user_prompt(e):
   440	        start = i
   441	if start < 0:
   442	    # 사용자 프롬프트가 없는 기록은 있을 수 없다 — 경계를 못 찾았다는 뜻이다.
   443	    # 전체를 훑으면 지난 턴의 문장까지 걸려 위양성이 폭주하므로 판독 불가로 떨어뜨린다.
   444	    fail("이 턴의 시작점(사용자 프롬프트)을 찾지 못했습니다 (형식이 바뀌었을 수 있습니다)")
   445	
   446	asked, texts = 0, []
   447	for e in entries[start + 1:]:
   448	    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):
   449	        continue
   450	    msg = e.get("message")
   451	    if not isinstance(msg, dict):
   452	        # truthy 비-dict 를 `or {}` 로 받으면 여기서 예외가 나고, 그 예외는 아래 "표지 없음"과
   453	        # 구별되지 않는 종료 코드로 나간다 — 조용한 통과다. 형식 변화로 보고 소리를 낸다.
   454	        fail("assistant 항목의 message 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
   455	    content = msg.get("content")
   456	    if isinstance(content, str):
   457	        # 문자열 본문도 발화다. 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
   458	        texts.append(content)
   459	        continue
   460	    if not isinstance(content, list):
   461	        # 볼 수 없는 발화가 있다 = 사각지대다. 조용히 건너뛰면 게이트가 죽은 줄도 모른다.
   462	        fail("assistant 항목의 content 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
   463	    for b in content:
   464	        if not isinstance(b, dict):
   465	            continue
   466	        if b.get("type") == "tool_use":
   467	            if b.get("name") == "AskUserQuestion":
   468	                asked += 1
   469	        elif b.get("type") == "text":
   470	            t = b.get("text")
   471	            if isinstance(t, str):
   472	                texts.append(t)
   473	
   474	if asked > 0:
   475	    raise SystemExit(3)
   476	
   477	hits, seen = [], set()
   478	for text in texts:
   479	    for line in drop_fences(text).split("\n"):
   480	        if BLOCKQUOTE.match(line):
   481	            continue
   482	        line = QUOTED.sub(" ", INLINE.sub(" ", line))
   483	        chunks = SENT.split(line)
   484	        for i in range(0, len(chunks), 2):
   485	            body = chunks[i]
   486	            whole = body + (chunks[i + 1] if i + 1 < len(chunks) else "")
   487	            # 부정이 붙으면 물음이 아니라 자백이다 — "물어보지 않고 …했습니다".
   488	            if QUESTION.search(whole) and not NEG_ASK.search(whole):
   489	                continue
   490	            core = TRAIL.sub("", LEAD.sub("", body).strip())
   491	            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):
   492	                continue
   493	            if core in seen:
   494	                continue
   495	            seen.add(core)
   496	            hits.append(core if len(core) <= MAX_LEN else core[:MAX_LEN] + "…")
   497	
   498	if not hits:
   499	    raise SystemExit(3)
   500	for h in hits[:MAX_HITS]:
   501	    sys.stdout.write(h + "\n")
   502	if len(hits) > MAX_HITS:
   503	    sys.stdout.write("... 그리고 %d개 더\n" % (len(hits) - MAX_HITS))
   504	raise SystemExit(0)
   505	PY
   506	}
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
    20	# 대화 기록 경로. 결정 게이트(3.2)가 이 턴의 발화를 읽는 데 쓴다. 비어 있거나 못 읽으면
    21	# 그 게이트만 생략되고 **사유가 마지막 게이트 메시지에 실린다** — 조용히 사라지지 않는
    22	# 것이 이 fail-open 의 조건이다(decision_scan 주석 참조).
    23	transcript_path="$(printf '%s' "$payload" | json_get transcript_path)"
    24	
    25	# (0) push 미완 **탐지** — 조기 종료보다 **먼저** 해야 한다.
    26	#     플래그를 다 처리해 지운 뒤가 바로 위험한 시점인데(29커밋을 잃은 그 상태),
    27	#     아래 조기 종료가 먼저 걸리면 push 게이트는 영영 안 돈다(검수 [치명] 지적).
    28	#     탐지만 여기서 하고 차단은 예산·지문 기계가 준비된 뒤에 한다.
    29	push_unsent=""
    30	push_branch=""
    31	if ! hook_disabled "stop:push" && git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    32	  push_branch="$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)"
    33	  if [ -n "$push_branch" ] && git -C "$PROJECT_DIR" remote get-url origin >/dev/null 2>&1; then
    34	    if git -C "$PROJECT_DIR" rev-parse --verify -q "refs/remotes/origin/$push_branch" >/dev/null 2>&1; then
    35	      # rc 를 따로 본다. 실패를 "ahead 0" 으로 읽으면 게이트가 조용히 사라진다([cx] 지적).
    36	      if push_n="$(git -C "$PROJECT_DIR" rev-list --count "refs/remotes/origin/$push_branch..HEAD" 2>/dev/null)"; then
    37	        [ -n "$push_n" ] && [ "$push_n" != "0" ] && push_unsent="원격보다 ${push_n}개 앞서 있습니다"
    38	      else
    39	        push_unsent="원격과의 차이를 셀 수 없습니다(저장소 상태 이상) — 직접 확인하세요"
    40	      fi
    41	    elif git -C "$PROJECT_DIR" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    42	      # ref 가 없다. 다만 **HEAD 가 이미 다른 원격 브랜치에 있으면** 새 커밋이 없는
    43	      # 갓 만든 브랜치이므로 요구하지 않는다 — 안 그러면 브랜치를 파자마자 막힌다.
    44	      # 파이프 안 서브셸에서 exit 로 신호하면 그 rc 가 밖으로 안 나온다 — 실제로 그렇게
    45	      # 짰다가 조건이 항상 거짓이 됐다. 서브셸 없는 for 루프로 판정한다(ref 이름에는
    46	      # 공백이 못 들어가므로 단어 분리가 안전하다).
    47	      head_on_remote=0
    48	      for _r in $(git -C "$PROJECT_DIR" for-each-ref --format='%(refname)' refs/remotes 2>/dev/null); do
    49	        if git -C "$PROJECT_DIR" merge-base --is-ancestor HEAD "$_r" 2>/dev/null; then
    50	          head_on_remote=1; break
    51	        fi
    52	      done
    53	      if [ "$head_on_remote" -eq 0 ]; then
    54	        push_unsent="이 브랜치의 원격 추적 ref 가 없습니다 (한 번도 push 되지 않았거나, refspec 이 좁혀져 보이지 않습니다)"
    55	      fi
    56	    fi
    57	  fi
    58	fi
    59	
    60	# (1) 코드 변경이 없는 턴 → 검사 전부 생략. 읽기 전용 질문에 타입체크를 돌리지 않는다.
    61	#     두 게이트 플래그(감사·설명)가 모두 비어야 "할 일 없음"이다.
    62	#     지식 플래그는 **게이트가 켜져 있을 때만** 할 일로 센다 — 껐는데 예전에 남은
    63	#     플래그 파일이 읽기 전용 턴의 조기 종료를 막으면 안 된다.
    64	if [ -z "$push_unsent" ] && [ ! -s "$AUDIT_FLAG" ] && [ ! -s "$EXPLAIN_FLAG" ] && ! knowledge_gate_active && [ ! -s "$DUALREVIEW_FLAG" ]; then
    65	  rm -f "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
    66	  exit 0
    67	fi
    68	
    69	# (2) 카운터 확인 — 벽돌 방지, 진전 인지 리셋 (2026-08-03 [cx] 지적 반영)
    70	# 카운터의 목적은 "갇힘 감지"이지 노력 예산이 아니다. 게이트가 4종으로 늘며 공유 카운터
    71	# 3회로는 게이트를 순서대로 성실히 처리해도 마지막 감사 게이트 전에 소진되는 역설이 있었다.
    72	# → 차단 지문(어느 게이트에서, 어떤 플래그 상태로 막혔나)이 지난 차단과 다르면 = 진전이면
    73	#   카운터를 리셋한다. 같은 지문으로 MAX_BLOCKS회 = 진짜 갇힘일 때만 경고와 통과.
    74	count=0
    75	if [ -f "$BLOCK_COUNT" ]; then
    76	  count="$(tr -dc '0-9' < "$BLOCK_COUNT" 2>/dev/null)"
    77	fi
    78	[ -z "$count" ] && count=0
    79	prev_fp="$(cat "$BLOCK_FP" 2>/dev/null)"
    80	# 지문 = 서 있는 플래그의 집합(내용 아님). 내용을 넣으면 갇힌 채 새 파일만 편집해도
    81	# 리셋되고(무한 차단), cksum 충돌로 실제 진전이 리셋 안 될 수도 있다([cx] 지적).
    82	flags_fp=""
    83	[ -s "$AUDIT_FLAG" ]      && flags_fp="${flags_fp}a"
    84	[ -s "$EXPLAIN_FLAG" ]    && flags_fp="${flags_fp}e"
    85	knowledge_gate_active     && flags_fp="${flags_fp}k"
    86	[ -s "$DUALREVIEW_FLAG" ] && flags_fp="${flags_fp}d"
    87	# push 는 "몇 개 남았나"가 곧 진전이다. 지문에 안 넣으면 한 커밋씩 올리는 실제 진전이
    88	# 같은 지문으로 세어져 예산이 소진되고, 그때 감사 플래그까지 함께 지워진다([cx] 지적).
    89	[ -n "$push_unsent" ] && flags_fp="${flags_fp}p:${push_branch}:${push_unsent}"
    90	new_fp=""
    91	
    92	gate_budget() {  # $1 = 게이트 식별자. 각 차단 지점이 메시지 출력 전에 호출한다.
    93	  new_fp="$1|$flags_fp"
    94	  # 지문을 기록할 수 있을 때만 리셋한다 — 지문 파일을 못 쓰는 환경에서 리셋하면
    95	  # prev_fp가 영원히 비어 매번 1/3로 무한 차단된다([cx] 지적). 그 경우 리셋 없는
    96	  # 구식 누적으로 동작해 3회 후 통과가 보장된다.
    97	  if printf '%s\n' "$new_fp" > "$BLOCK_FP" 2>/dev/null; then
    98	    if [ "$new_fp" != "$prev_fp" ]; then
    99	      count=0   # 지난 차단과 다른 게이트/플래그 집합 = 진전 — 예산 리셋
   100	    fi
   101	  fi
   102	  if [ "$count" -ge "$MAX_BLOCKS" ]; then
   103	    changed="$(cat "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" 2>/dev/null | tr -d '"\\' | sort -u | tr '\n' ' ')"
   104	    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
   105	    printf '{"systemMessage":"[완료 게이트] 같은 지점(%s)에서 %s회 차단 후에도 진전이 없어 세션 벽돌 방지를 위해 통과시킵니다. 이 턴의 완료 주장(및 변경 설명)을 신뢰하지 마세요. 미처리 변경: %s"}\n' \
   106	      "$1" "$MAX_BLOCKS" "$changed"
   107	    exit 0
   108	  fi
   109	}
   110	
   111	# 결정 게이트가 대화 기록을 못 읽었으면 **어느 게이트가 막든** 그 사유를 함께 낸다.
   112	# 감사 게이트에만 실으면, 앞 게이트가 먼저 막은 턴에는 안 보이고 그 플래그를 지운 다음
   113	# 턴에는 조기 종료로 **영영 사라진다**(검수 [cx] 지적). 조용히 사라지는 것이 이 게이트를
   114	# 만든 이유 그 자체라, 경고를 삼키지 않는 것이 fail-open 의 조건이다.
   115	emit_decision_note() {
   116	  [ -n "${decision_note:-}" ] || return 0
   117	  echo
   118	  echo "참고: $decision_note"
   119	  echo "      → 이 턴에 사용자에게 물었어야 할 결정이 없었는지 스스로 확인하세요."
   120	}
   121	
   122	bump_and_block() {
   123	  if ! printf '%s\n' "$((count + 1))" > "$BLOCK_COUNT" 2>/dev/null; then
   124	    # 카운터를 못 쓰면 무한루프 위험 → 표준 가드로 폴백
   125	    case "$stop_active" in
   126	      [Tt]rue) exit 0 ;;
   127	    esac
   128	  fi
   129	  exit 2
   130	}
   131	
   132	# (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
   133	#     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
   134	#     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
   135	#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
   136	#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
   137	#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
   138	typecheck_note=""
   139	#     rc 를 함께 받는다. "리터럴로 비웠다"(rc=0 + 빈 값 = 의도한 생략)와 "값을 믿을 수
   140	#     없다"(rc=1 = 미설정·선언 2개 이상·지원 문법 밖·읽기 실패)는 둘 다 생략으로 가지만
   141	#     사용자에게 **다른 정보**다. 후자는 고칠 수 있는 실수라 그렇게 적어야 한다.
   142	TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"; typecheck_rc=$?
   143	
   144	if [ "$typecheck_rc" -ne 0 ]; then
   145	  typecheck_note="타입체크 생략 (harness.env 의 HARNESS_TYPECHECK_CMD 를 읽지 못함 — 미설정이거나, 선언이 2개 이상이거나, 지원 문법 밖입니다)"
   146	elif [ -z "$TYPECHECK_CMD" ]; then
   147	  typecheck_note="타입체크 생략 (HARNESS_TYPECHECK_CMD 가 빈 값으로 설정됨)"
   148	else
   149	  timeout_bin=""
   150	  if command -v timeout >/dev/null 2>&1; then
   151	    timeout_bin="timeout"
   152	  elif command -v gtimeout >/dev/null 2>&1; then
   153	    timeout_bin="gtimeout"
   154	  fi
   155	  # macOS 기본에는 timeout 이 없다. 그 경우 settings.json 의 "timeout": 120 이 최종 안전망.
   156	
   157	  if [ -n "$timeout_bin" ]; then
   158	    tc_out="$(cd "$PROJECT_DIR" && "$timeout_bin" 90 sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   159	  else
   160	    tc_out="$(cd "$PROJECT_DIR" && sh -c "$TYPECHECK_CMD" 2>&1)"; tc_rc=$?
   161	  fi
   162	
   163	  if [ "$tc_rc" -eq 124 ] || [ "$tc_rc" -eq 137 ]; then
   164	    # 타임아웃은 "타입 오류"가 아니라 "모름". 차단하지 않고 감사자에게 넘긴다.
   165	    typecheck_note="타입체크 타임아웃 → 생략 (감사자가 재확인할 것)"
   166	  elif [ "$tc_rc" -eq 127 ]; then
   167	    # 명령/도구 없음(rc=127)은 "타입 오류"가 아니다. 오탐 차단 방지 위해 생략.
   168	    typecheck_note="타입체크 생략 (명령 실행 불가 rc=127): $TYPECHECK_CMD"
   169	  elif [ "$tc_rc" -ne 0 ]; then
   170	    gate_budget "typecheck"
   171	    {
   172	      echo "[완료 차단] 타입체크 실패 — 지금은 '완료'가 아닙니다."
   173	      echo
   174	      echo "명령: $TYPECHECK_CMD"
   175	      echo
   176	      printf '%s\n' "$tc_out" | head -n 15
   177	      echo
   178	      echo "고친 뒤 다시 종료하세요.  (차단 $((count + 1))/${MAX_BLOCKS})"
   179	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   180	    } >&2
   181	    bump_and_block
   182	  fi
   183	fi
   184	
   185	# (3.2) **결정 게이트** — "물어봤어야 할 것을 혼자 정했나".
   186	#      나머지 게이트가 전부 **산출물**을 볼 때 이것만 **에이전트 자신의 행동**을 본다.
   187	#      판정 규칙·좁히는 장치 셋·fail-open 사유는 _common.sh 의 decision_scan 주석이 정본이다.
   188	#
   189	#      **다른 게이트보다 앞에 둔다.** 질문의 답이 코드를 바꿀 수 있으므로, 리뷰·설명·감사에
   190	#      노력을 쓰기 전에 묻는 편이 싸다. (push 탐지와 달리 순서가 정확성을 바꾸지는 않는다 —
   191	#      대화 기록은 이미 다 쓰였고 게이트 순서가 그 내용을 바꾸지 않기 때문이다.)
   192	decision_note=""
   193	# **발동 조건은 플래그다.** 조기 종료는 push 미완만으로도 풀리므로, 그것만 보고 스캔하면
   194	# 아무것도 안 바꾼 읽기 전용 턴까지 검사하게 된다 — "플래그와 무관하게 항상"은 사용자가
   195	# 기각한 보기다. 여기서 한 번 더 물어 발동 계약을 조기 종료와 분리한다.
   196	decision_armed=0
   197	if [ -s "$AUDIT_FLAG" ] || [ -s "$EXPLAIN_FLAG" ] || [ -s "$DUALREVIEW_FLAG" ] || knowledge_gate_active; then
   198	  decision_armed=1
   199	fi
   200	if [ "$decision_armed" -eq 1 ] && ! hook_disabled "stop:decision"; then
   201	  decision_hits="$(decision_scan "$transcript_path")"; decision_rc=$?
   202	  case "$decision_rc" in
   203	    3) : ;;   # 표지 없음 · 또는 이 턴에 물었음
   204	    2)
   205	      # **이 게이트의 유일한 fail-open.** 통과시키되 사유를 게이트 메시지에 실어 보낸다.
   206	      # 대화 기록 형식은 하네스 소유가 아니라, 여기서 차단하면 그 세션 안에 고칠 방법이 없다.
   207	      decision_note="결정 게이트 생략 ($decision_hits)" ;;
   208	    0) ;;     # 아래에서 차단한다 (case 안에서 하면 들여쓰기가 깊어져 메시지가 안 읽힌다)
   209	    *)
   210	      # **모르는 rc 는 통과가 아니라 판독 불가다.** python3 부재(127)·처리 못 한 예외(1)·
   211	      # 신호 종료가 전부 여기로 온다. 이걸 통과로 읽으면 게이트가 조용히 사라진다.
   212	      decision_note="결정 게이트 생략 (스캐너가 예상 밖 상태로 끝남 rc=$decision_rc — python3 부재·예외·신호 종료일 수 있습니다)" ;;
   213	  esac
   214	  if [ "$decision_rc" -eq 0 ]; then
   215	    gate_budget "decision"
   216	    {
   217	      echo "[완료 차단] 혼자 정한 것이 있는데 이 턴에 사용자에게 한 번도 묻지 않았습니다."
   218	      echo
   219	      echo "걸린 문장:"
   220	      printf '%s\n' "$decision_hits" | sed 's/^/  - /'
   221	      echo
   222	      echo "이 게이트가 겨누는 것:"
   223	      echo "  게이트가 막을 때는 따르면서, 게이트가 없는 자리에서는 혼자 정하고 보고서에"
   224	      echo "  한 줄 적는 부류입니다. 그 '한 줄'은 도구 호출이 아니라 문장이라 승인창이"
   225	      echo "  안 뜨고, 그래서 이 저장소가 겪은 실패 대부분이 이 축에서 났습니다."
   226	      echo
   227	      echo "해야 할 일:"
   228	      echo "  1. 위 문장들이 정말 **사용자가 정할 일**이었는지 본다."
   229	      echo "     '범위 밖'·'별도로'·'그대로 뒀'는 대개 선택지를 줬어야 하는 자리입니다."
   230	      echo "  2. AskUserQuestion 으로 **실제로 묻는다.** 보고서에 적는 것은 묻는 것이 아닙니다."
   231	      echo "  3. 질문을 한 번이라도 하면 이 게이트는 풀립니다."
   232	      echo
   233	      echo "위양성이라면(그 어휘를 설명·인용한 것이지 결정이 아니라면):"
   234	      echo "  - 백틱이나 따옴표로 감싸면 스캔에서 빠집니다 — 인용은 결정이 아니니까요."
   235	      echo "  - 그래도 걸리면 사용자에게 위양성임을 알리고 지시를 받으세요."
   236	      echo
   237	      echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:decision"
   238	    } >&2
   239	    bump_and_block
   240	  fi
   241	fi
   242	
   243	# (3.5) 듀얼 리뷰(codex) 게이트 (2026-08-03 kty — "리뷰가 필요한 모든 단계를 codex와 같이"의 기계화).
   244	#      설계·계획 산출물이 저장되거나 코드가 바뀐 턴은 codex 독립 리뷰 없이 끝낼 수 없다.
   245	#      Claude 단독 리뷰가 놓친 CRITICAL을 codex가 잡은 실사고(2026-08-03 POK-30)의 재발 방지.
   246	if [ -s "$DUALREVIEW_FLAG" ] && ! hook_disabled "stop:dualreview"; then
   247	  gate_budget "dualreview"
   248	  {
   249	    echo "[완료 차단] codex 듀얼 리뷰 미수행 — Claude 단독 리뷰로는 끝낼 수 없습니다."
   250	    echo
   251	    echo "이 턴의 듀얼 리뷰 대상:"
   252	    sed 's/^/  - /' "$DUALREVIEW_FLAG" 2>/dev/null
   253	    echo
   254	    echo "해야 할 일:"
   255	    echo "  1. 대상 산출물/diff를 codex로 독립 리뷰시킨다 (모델·effort는 guard-codex-invocation 규정 — 임의 하향 금지)."
   256	    echo "  2. 결과를 _workspace/ 에 *codex*.md 로 저장하고 지적을 [cc]/[cx] 태그로 통합한다."
   257	    echo "  3. 그 뒤에만:  rm -f .claude/.needs-dualreview"
   258	    echo "     codex 미설치·호출 실패면 사용자 보고에 '듀얼 리뷰 생략(codex 실패)'을 명시한 뒤에 지운다."
   259	    echo "     리뷰 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   260	    echo
   261	    emit_decision_note
   262	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
   263	  } >&2
   264	  bump_and_block
   265	fi
   266	
   267	# (4) change-explainer 게이트 (Phase 5) — 감사자보다 먼저 강제한다.
   268	#     코드가 바뀐 턴은 변경 설명 없이 끝낼 수 없다. change-explainer 가 실제로
   269	#     사용자용 설명을 낸 뒤에만 .needs-explain 을 지운다.
   270	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
   271	if [ -s "$EXPLAIN_FLAG" ] && ! hook_disabled "stop:explain"; then
   272	  gate_budget "explain"
   273	  {
   274	    echo "[완료 차단] change-explainer 미실행 — 변경 설명 없이 끝낼 수 없습니다."
   275	    echo
   276	    echo "이 턴에서 바뀐 코드/설정:"
   277	    sed 's/^/  - /' "$EXPLAIN_FLAG" 2>/dev/null
   278	    echo
   279	    echo "해야 할 일:"
   280	    echo "  1. change-explainer 에이전트로 실제 diff 기반 사용자용 변경 설명을 낸다."
   281	    echo "  2. 설명을 낸 뒤에만:  rm -f .claude/.needs-explain"
   282	    echo "     설명 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   283	    echo
   284	    emit_decision_note
   285	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
   286	  } >&2
   287	  bump_and_block
   288	fi
   289	
   290	# (5) 지식 저장소 반영 게이트 — 감사보다 먼저 강제한다 (감사자가 반영 결과를 검증하도록).
   291	#     (2026-08-02 kty — 산문 규칙이 세션 내내 0회 이행된 실사고의 기계화)
   292	#
   293	#     **이 훅이 아는 것은 계약 하나뿐이다**: "지식 저장소가 설정돼 있으면, 결정·설계가
   294	#     나온 턴은 반영 없이 끝낼 수 없다." 저장소가 어디인지·어떤 구조인지·무엇을 어느
   295	#     파일에 나눠 담는지는 **상위 층의 구현**이고 이 파일은 모른다. 알게 되면 그 저장소를
   296	#     안 쓰는 환경에서 하네스가 없는 구조를 요구하게 된다(제0원칙 4 — 구체가 아닌 계약).
   297	#     어디에 어떻게 저장했는지의 검증은 그 저장소 자신의 규약이 한다.
   298	if knowledge_gate_active && ! hook_disabled "stop:knowledge"; then
   299	  gate_budget "knowledge"
   300	  {
   301	    echo "[완료 차단] 지식 저장소 반영 미확인 — 이 턴의 결정·설계를 남기지 않고 끝낼 수 없습니다."
   302	    echo
   303	    echo "이 턴에서 바뀐 코드/설정:"
   304	    sed 's/^/  - /' "$KNOWLEDGE_FLAG" 2>/dev/null
   305	    echo
   306	    echo "해야 할 일:"
   307	    echo "  1. 이 머신의 지식 저장소가 **어디이고 어떤 형식인지는 사용자 층 설정**(전역"
   308	    echo "     CLAUDE.md 등)이 답한다. 그 규약을 **전문** 읽는다 — 부분 독해 금지."
   309	    echo "  2. 이번 턴에 결정·설계·개발작업이 있으면 그 규약대로 반영하고, 반영됐다는"
   310	    echo "     확인 가능한 증거(커밋 해시·파일 경로 등)를 확보한다."
   311	    echo "     판단을 만든 **근거(raw)** 도 규약이 정한 자리에 함께 남긴다 — 요약만 남기면"
   312	    echo "     \"왜 그렇게 정했나\"가 복원 불가능해진다."
   313	    echo "  3. 반영할 지식이 없으면(순수 버그픽스·기계적 수정) 불요 사유를 _workspace/progress.md 에 기록한다."
   314	    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-knowledge"
   315	    echo "     completion-auditor 가 그 증거(또는 불요 사유의 타당성)를 검증한다."
   316	    echo "  5. 지식 저장소를 아예 쓰지 않는 환경이면 harness.env 의 HARNESS_KNOWLEDGE_GATE 를 비운다."
   317	    echo
   318	    emit_decision_note
   319	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:knowledge"
   320	  } >&2
   321	  bump_and_block
   322	fi
   323	
   324	# (5.5) **커밋했는데 원격에 없다** — 이 저장소가 커밋 29개를 잃은 바로 그 상태다.
   325	#      그때는 "아직 PR 전이니까"라며 라운드 6개를 미뤘고, 임시 폴더째 사라졌다.
   326	#      탐지는 (0) 에서 이미 했다 — 조기 종료보다 앞이어야 하기 때문이다.
   327	if [ -n "$push_unsent" ]; then
   328	  gate_budget "push"
   329	  {
   330	    echo "[완료 차단] 커밋이 원격에 없습니다 — $push_unsent"
   331	    echo
   332	    echo "이 저장소는 이 상태로 **커밋 29개를 잃은 적이 있습니다.** 그때도 코드는"
   333	    echo "다 짜여 있었고, \"아직 PR 전이니까\"라며 push 를 미뤘습니다."
   334	    echo
   335	    echo "해야 할 일:"
   336	    echo "  git push -u origin $push_branch"
   337	    echo "  그리고 실제로 올라갔는지 확인하세요:"
   338	    echo "  git rev-list --left-right --count HEAD...origin/$push_branch   → 0 0"
   339	    echo
   340	    echo "  원격에는 있는데 위 명령이 실패한다면 refspec 이 좁혀진 것입니다:"
   341	    echo "  git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git fetch origin"
   342	    echo "  push 여부가 로컬에서 안 보이는 것 자체가 위험합니다 — 29개를 잃을 때 그랬습니다."
   343	    echo
   344	    emit_decision_note
   345	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:push"
   346	  } >&2
   347	  bump_and_block
   348	fi
   349	
   350	# (6) 타입체크는 통과했지만 감사자가 아직 안 돌았다.
   351	gate_budget "audit"
   352	{
   353	  echo "[완료 차단] completion-auditor 미실행 — '완료'라고 말할 수 없습니다."
   354	  echo
   355	  echo "이 턴에서 바뀐 코드/설정:"
   356	  sed 's/^/  - /' "$AUDIT_FLAG" 2>/dev/null
   357	  if [ -n "$typecheck_note" ]; then
   358	    echo
   359	    echo "참고: $typecheck_note"
   360	  fi
   361	  emit_decision_note
   362	  echo
   363	  echo "해야 할 일:"
   364	  echo "  1. completion-auditor 에이전트로 완료 주장을 1차 증거로 검증한다."
   365	  echo "  2. 검증을 통과했을 때만:  rm -f .claude/.needs-audit"
   366	  echo "     감사 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   367	  echo
   368	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   369	} >&2
   370	bump_and_block

2026-08-10T08:15:59.216628Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "nl -ba template/.claude/hooks/_common.sh | sed -n '287,520p'
nl -ba template/.claude/hooks/verify-before-stop.sh | sed -n '1,145p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
   287	# 이 턴의 대화 기록을 읽어 **"물어봤어야 할 것을 혼자 정했다"는 자백**을 찾는다.
   288	#
   289	# 왜 이런 게이트가 필요한가: 완료 게이트 넷(타입체크·듀얼리뷰·변경설명·지식반영)은 전부
   290	# **산출물**을 본다. 에이전트 자신의 행동을 겨눈 것은 없었고, 그 비대칭이 실물로 드러났다 —
   291	# 게이트가 막을 때는 세 번 다 따랐는데, 게이트가 없는 축에서는 전부 혼자 정하고 보고서에
   292	# 한 줄 적었다. 그 "한 줄"은 **도구 호출이 아니라 문장**이라 어떤 PreToolUse 훅도 볼 수 없고
   293	# 승인창도 안 뜬다(승인창은 *한 일*에만 뜬다). 그래서 Stop 이 대화 기록을 직접 읽는다.
   294	#
   295	# ── 판정 ─────────────────────────────────────────────────────────────
   296	#   결정 표지 어휘를 담은 **서술형** 문장이 있는데  AND  이 턴에 AskUserQuestion 이 0회
   297	#   → 차단. 질문을 한 번 하면 풀리므로 세션이 벽돌이 되지 않는다.
   298	#
   299	# 표지 어휘를 이렇게 고른 이유: 저 말들은 "물어봤어야 할 것을 혼자 정했다"를 **자백**할
   300	# 때만 나온다. 자백은 있는데 질문이 0회면 그 자체가 위반이다.
   301	#
   302	# ── 좁히는 장치 셋 (위양성 억제) ─────────────────────────────────────
   303	# 어휘만 보면 이 게이트를 **유지보수하는 작업 자체가 매번 걸린다** — 훅·테스트·결정 문서가
   304	# 그 어휘를 데이터로 품기 때문이다. 그러면 사람이 게이트를 끄게 되고 그게 최악이다.
   305	#   1) 구조적 제외 — 코드펜스 · 인라인 코드 · 인용줄(>) · 따옴표로 감싼 부분은 안 본다.
   306	#      그래서 어휘를 **인용부호로 감싸 언급하는 것**은 안 걸린다(문서·설명의 정상 형태다).
   307	#   2) 질문 신호 제외 — 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다.
   308	#   3) 서술형 종결 요구 — "…했다/…습니다" 같은 단정으로 끝나야 "내가 그렇게 했다"이다.
   309	# 대가는 위음성 증가다. 표현을 바꾸면 빠져나간다 — 겨누는 것이 적대적 회피가 아니라
   310	# **무의식적 습관**이라 그래도 실효가 남는다. guard-hook-disable 과 같은 판단 구조다.
   311	#
   312	# **도구 입력은 보지 않는다(text 블록만 본다).** 그래서 이 패턴이 적힌 파일을 Write/Edit
   313	# 로 쓰는 것은 안 걸린다 — 자기참조 폭발을 원천에서 없애는 장치다.
   314	# thinking 블록도 안 본다: 거기서 선택지를 저울질하는 것은 결정 통보가 아니다.
   315	# 서브에이전트 발화(isSidechain)도 뺀다: 서브에이전트는 사용자에게 물을 수 없다.
   316	#
   317	# ── 반환 계약 ─────────────────────────────────────────────────────────
   318	#   rc=0 : 차단해야 한다. stdout = 걸린 문장들(줄당 하나)
   319	#   rc=2 : **판독 불가.** stdout = 사유 한 줄
   320	#   rc=3 : 차단 불필요 (표지 없음 · 또는 이 턴에 질문을 했음)
   321	#   그 밖 : **예상 밖.** python3 부재(127) · 처리 못 한 예외(1) · 신호 종료 등
   322	#
   323	# "차단 불필요"에 1 이 아니라 **3** 을 쓰는 이유: python 이 처리 못 한 예외로 죽으면
   324	# 그것도 1 이라, 1 을 정상 통과로 쓰면 **크래시가 조용한 통과로 위장된다.** 정상 경로에
   325	# 흔한 코드를 주지 않으면 호출부가 "모르는 rc = 무언가 잘못됐다"로 갈라낼 수 있다.
   326	# 호출부는 0·2·3 만 알고 나머지는 전부 판독 불가로 취급해야 한다.
   327	#
   328	# ── rc=2 가 이 게이트의 유일한 fail-open 지점이다 ────────────────────
   329	# 대화 기록의 형식은 하네스가 소유하지 않는다 — 도구 제공자가 정하고 예고 없이 바뀐다.
   330	# 형식이 바뀌었다고 차단하면 **세션이 통째로 벽돌이 되는데 그 세션 안에 고칠 방법이 없다**
   331	# (기록을 고칠 수는 없으므로 어떤 행동으로도 게이트가 안 풀린다). 그래서 여기서만 통과로
   332	# 간다. 나머지 판정은 전부 fail-closed 다.
   333	# **조건은 경고를 삼키지 않는 것이다** — 호출부가 이 사유를 마지막 게이트 메시지에 싣는다.
   334	# 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다.
   335	decision_scan() {   # $1 = 대화 기록(JSONL) 경로
   336	  local path="$1"
   337	  [ -n "$path" ] || { printf '%s\n' '대화 기록 경로가 훅 입력에 없습니다'; return 2; }
   338	  [ -r "$path" ] || { printf '%s\n' "대화 기록을 읽을 수 없습니다: $path"; return 2; }
   339	  python3 - "$path" <<'PY'
   340	import json, re, sys
   341	
   342	# 결정 표지. 굴절 변형만 최소로 넓혔고 그 이상 넓히지 않는다 — 넓히면 위양성이 늘고,
   343	# 위양성이 늘면 질문이 소음이 되고, 소음이 되면 진짜 질문도 무시된다.
   344	MARKER = re.compile(
   345	    "공시하|공시했|공시함"
   346	    "|범위 ?밖"
   347	    "|별도로"
   348	    "|그대로 (?:뒀|두었|남겼|남겨)"
   349	    "|(?:제|내) 판단으로"
   350	    "|가정하(?:고|여|였|겠)|가정했"
   351	    "|수용(?:된|한) 한계"
   352	    "|트레이드오프"
   353	    "|안 했(?:습니다|다|음)"
   354	)
   355	# 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다.
   356	QUESTION = re.compile(
   357	    "\\?|까요|나요|ㄹ까|을까|할까|여쭤|여쭈|여쭙|물어|어떠신|어느 쪽"
   358	    "|골라|선택해|정해 ?주|알려 ?주|괜찮으신|의견"
   359	)
   360	# **"묻지 않았다"는 물음이 아니라 자백이다.** 이게 없으면 겨누는 문장 자체가 빠져나간다 —
   361	# "사용자에게 물어보지 않고 제 판단으로 진행했습니다" 는 `물어` 때문에 질문으로 오인된다.
   362	# 부정이 붙으면 위 QUESTION 제외를 적용하지 않는다.
   363	NEG_ASK = re.compile(
   364	    "물어보지 ?않|물어보지도|묻지 ?않|묻지도|여쭙지 ?않|여쭈지 ?않|여쭤보지 ?않"
   365	    "|확인하지 ?않|확인 ?없이|의견을 받지 ?않|물어보는 대신|묻는 대신|묻지 못"
   366	)
   367	# 서술형 종결. "내가 그렇게 했다"는 단정만 잡는다.
   368	DECLARATIVE = re.compile("(?:다|음|함|됨|임|옴)$")
   369	
   370	# 이중 백틱 코드 span 이 먼저다 — 단일 규칙만 두면 ``a`b`` 의 안쪽이 산문으로 샌다.
   371	INLINE     = re.compile("``[^`\n]*``|`[^`\n]*`")
   372	QUOTED     = re.compile("\"[^\"\n]*\"|'[^'\n]*'|“[^”\n]*”"
   373	                        "|‘[^’\n]*’|「[^」\n]*」"
   374	                        "|『[^』\n]*』")
   375	BLOCKQUOTE = re.compile("^\\s{0,3}>")
   376	# 마침표는 **뒤에 공백이나 줄끝이 올 때만** 문장 종결이다. 무조건 종결로 보면
   377	# `README.md`·`_common.sh`·버전 번호가 한 문장을 쪼개, 표지와 서술형 종결이 서로 다른
   378	# 조각으로 갈라져 **둘 다 만족하는 조각이 없어진다**(위음성).
   379	SENT       = re.compile("([\n!?…。！？]+|\\.(?=\\s)|\\.$)")
   380	LEAD       = re.compile("^[\\s*_>#\\-–—•·]+")
   381	TRAIL      = re.compile("[\\s*_`~\\[\\](){}<>:;,·…\\-—–]+$")
   382	
   383	MAX_HITS, MAX_LEN = 8, 140
   384	
   385	
   386	def fail(reason):
   387	    sys.stdout.write(reason + "\n")
   388	    raise SystemExit(2)
   389	
   390	
   391	def drop_fences(s):
   392	    # 짝수 조각만 코드 **밖**이다. 펜스가 안 닫혔으면 마지막 조각은 코드 안으로 친다 —
   393	    # 스트리밍 중 잘린 기록에서 코드가 산문으로 새는 것을 막는다.
   394	    # 백틱만 보면 `~~~` 펜스의 예문이 산문으로 검사된다(문서가 약속한 범위보다 좁다).
   395	    for fence in ("```", "~~~"):
   396	        s = "\n".join(p for i, p in enumerate(s.split(fence)) if i % 2 == 0)
   397	    return s
   398	
   399	
   400	def is_user_prompt(e):
   401	    if e.get("type") != "user" or e.get("isSidechain"):
   402	        return False
   403	    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
   404	        return False
   405	    msg = e.get("message")
   406	    if not isinstance(msg, dict):
   407	        return False
   408	    content = msg.get("content")
   409	    if isinstance(content, list):
   410	        for b in content:
   411	            if isinstance(b, dict) and b.get("type") == "tool_result":
   412	                return False
   413	    return True
   414	
   415	
   416	try:
   417	    with open(sys.argv[1], "r", encoding="utf-8", errors="replace") as fh:
   418	        raw = fh.read()
   419	except Exception as exc:
   420	    fail("대화 기록을 열지 못했습니다: %s" % exc.__class__.__name__)
   421	
   422	lines = [ln for ln in raw.splitlines() if ln.strip()]
   423	entries, broken = [], 0
   424	for ln in lines:
   425	    try:
   426	        entries.append(json.loads(ln))
   427	    except Exception:
   428	        broken += 1
   429	# **한 줄이라도 못 읽으면 판독 불가다.** 건너뛰면 그 줄이 하필 자백이 담긴 발화이거나
   430	# 이 턴의 사용자 프롬프트일 때 조용히 새고, 후자는 경계가 **지난 턴으로 밀려** 위양성까지
   431	# 낳는다. "전멸일 때만 실패"로 두면 부분 손상이라는 가장 흔한 경우를 정확히 놓친다.
   432	if broken:
   433	    fail("대화 기록 %d줄을 파싱하지 못했습니다 (형식이 바뀌었을 수 있습니다)" % broken)
   434	if not entries:
   435	    fail("대화 기록이 비어 있습니다")
   436	
   437	start = -1
   438	for i, e in enumerate(entries):
   439	    if isinstance(e, dict) and is_user_prompt(e):
   440	        start = i
   441	if start < 0:
   442	    # 사용자 프롬프트가 없는 기록은 있을 수 없다 — 경계를 못 찾았다는 뜻이다.
   443	    # 전체를 훑으면 지난 턴의 문장까지 걸려 위양성이 폭주하므로 판독 불가로 떨어뜨린다.
   444	    fail("이 턴의 시작점(사용자 프롬프트)을 찾지 못했습니다 (형식이 바뀌었을 수 있습니다)")
   445	
   446	asked, texts = 0, []
   447	for e in entries[start + 1:]:
   448	    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):
   449	        continue
   450	    msg = e.get("message")
   451	    if not isinstance(msg, dict):
   452	        # truthy 비-dict 를 `or {}` 로 받으면 여기서 예외가 나고, 그 예외는 아래 "표지 없음"과
   453	        # 구별되지 않는 종료 코드로 나간다 — 조용한 통과다. 형식 변화로 보고 소리를 낸다.
   454	        fail("assistant 항목의 message 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
   455	    content = msg.get("content")
   456	    if isinstance(content, str):
   457	        # 문자열 본문도 발화다. 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
   458	        texts.append(content)
   459	        continue
   460	    if not isinstance(content, list):
   461	        # 볼 수 없는 발화가 있다 = 사각지대다. 조용히 건너뛰면 게이트가 죽은 줄도 모른다.
   462	        fail("assistant 항목의 content 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")
   463	    for b in content:
   464	        if not isinstance(b, dict):
   465	            continue
   466	        if b.get("type") == "tool_use":
   467	            if b.get("name") == "AskUserQuestion":
   468	                asked += 1
   469	        elif b.get("type") == "text":
   470	            t = b.get("text")
   471	            if isinstance(t, str):
   472	                texts.append(t)
   473	
   474	if asked > 0:
   475	    raise SystemExit(3)
   476	
   477	hits, seen = [], set()
   478	for text in texts:
   479	    for line in drop_fences(text).split("\n"):
   480	        if BLOCKQUOTE.match(line):
   481	            continue
   482	        line = QUOTED.sub(" ", INLINE.sub(" ", line))
   483	        chunks = SENT.split(line)
   484	        for i in range(0, len(chunks), 2):
   485	            body = chunks[i]
   486	            whole = body + (chunks[i + 1] if i + 1 < len(chunks) else "")
   487	            # 부정이 붙으면 물음이 아니라 자백이다 — "물어보지 않고 …했습니다".
   488	            if QUESTION.search(whole) and not NEG_ASK.search(whole):
   489	                continue
   490	            core = TRAIL.sub("", LEAD.sub("", body).strip())
   491	            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):
   492	                continue
   493	            if core in seen:
   494	                continue
   495	            seen.add(core)
   496	            hits.append(core if len(core) <= MAX_LEN else core[:MAX_LEN] + "…")
   497	
   498	if not hits:
   499	    raise SystemExit(3)
   500	for h in hits[:MAX_HITS]:
   501	    sys.stdout.write(h + "\n")
   502	if len(hits) > MAX_HITS:
   503	    sys.stdout.write("... 그리고 %d개 더\n" % (len(hits) - MAX_HITS))
   504	raise SystemExit(0)
   505	PY
   506	}
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
    20	# 대화 기록 경로. 결정 게이트(3.2)가 이 턴의 발화를 읽는 데 쓴다. 비어 있거나 못 읽으면
    21	# 그 게이트만 생략되고 **사유가 마지막 게이트 메시지에 실린다** — 조용히 사라지지 않는
    22	# 것이 이 fail-open 의 조건이다(decision_scan 주석 참조).
    23	transcript_path="$(printf '%s' "$payload" | json_get transcript_path)"
    24	
    25	# (0) push 미완 **탐지** — 조기 종료보다 **먼저** 해야 한다.
    26	#     플래그를 다 처리해 지운 뒤가 바로 위험한 시점인데(29커밋을 잃은 그 상태),
    27	#     아래 조기 종료가 먼저 걸리면 push 게이트는 영영 안 돈다(검수 [치명] 지적).
    28	#     탐지만 여기서 하고 차단은 예산·지문 기계가 준비된 뒤에 한다.
    29	push_unsent=""
    30	push_branch=""
    31	if ! hook_disabled "stop:push" && git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    32	  push_branch="$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)"
    33	  if [ -n "$push_branch" ] && git -C "$PROJECT_DIR" remote get-url origin >/dev/null 2>&1; then
    34	    if git -C "$PROJECT_DIR" rev-parse --verify -q "refs/remotes/origin/$push_branch" >/dev/null 2>&1; then
    35	      # rc 를 따로 본다. 실패를 "ahead 0" 으로 읽으면 게이트가 조용히 사라진다([cx] 지적).
    36	      if push_n="$(git -C "$PROJECT_DIR" rev-list --count "refs/remotes/origin/$push_branch..HEAD" 2>/dev/null)"; then
    37	        [ -n "$push_n" ] && [ "$push_n" != "0" ] && push_unsent="원격보다 ${push_n}개 앞서 있습니다"
    38	      else
    39	        push_unsent="원격과의 차이를 셀 수 없습니다(저장소 상태 이상) — 직접 확인하세요"
    40	      fi
    41	    elif git -C "$PROJECT_DIR" rev-parse --verify -q HEAD >/dev/null 2>&1; then
    42	      # ref 가 없다. 다만 **HEAD 가 이미 다른 원격 브랜치에 있으면** 새 커밋이 없는
    43	      # 갓 만든 브랜치이므로 요구하지 않는다 — 안 그러면 브랜치를 파자마자 막힌다.
    44	      # 파이프 안 서브셸에서 exit 로 신호하면 그 rc 가 밖으로 안 나온다 — 실제로 그렇게
    45	      # 짰다가 조건이 항상 거짓이 됐다. 서브셸 없는 for 루프로 판정한다(ref 이름에는
    46	      # 공백이 못 들어가므로 단어 분리가 안전하다).
    47	      head_on_remote=0
    48	      for _r in $(git -C "$PROJECT_DIR" for-each-ref --format='%(refname)' refs/remotes 2>/dev/null); do
    49	        if git -C "$PROJECT_DIR" merge-base --is-ancestor HEAD "$_r" 2>/dev/null; then
    50	          head_on_remote=1; break
    51	        fi
    52	      done
    53	      if [ "$head_on_remote" -eq 0 ]; then
    54	        push_unsent="이 브랜치의 원격 추적 ref 가 없습니다 (한 번도 push 되지 않았거나, refspec 이 좁혀져 보이지 않습니다)"
    55	      fi
    56	    fi
    57	  fi
    58	fi
    59	
    60	# (1) 코드 변경이 없는 턴 → 검사 전부 생략. 읽기 전용 질문에 타입체크를 돌리지 않는다.
    61	#     두 게이트 플래그(감사·설명)가 모두 비어야 "할 일 없음"이다.
    62	#     지식 플래그는 **게이트가 켜져 있을 때만** 할 일로 센다 — 껐는데 예전에 남은
    63	#     플래그 파일이 읽기 전용 턴의 조기 종료를 막으면 안 된다.
    64	if [ -z "$push_unsent" ] && [ ! -s "$AUDIT_FLAG" ] && [ ! -s "$EXPLAIN_FLAG" ] && ! knowledge_gate_active && [ ! -s "$DUALREVIEW_FLAG" ]; then
    65	  rm -f "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
    66	  exit 0
    67	fi
    68	
    69	# (2) 카운터 확인 — 벽돌 방지, 진전 인지 리셋 (2026-08-03 [cx] 지적 반영)
    70	# 카운터의 목적은 "갇힘 감지"이지 노력 예산이 아니다. 게이트가 4종으로 늘며 공유 카운터
    71	# 3회로는 게이트를 순서대로 성실히 처리해도 마지막 감사 게이트 전에 소진되는 역설이 있었다.
    72	# → 차단 지문(어느 게이트에서, 어떤 플래그 상태로 막혔나)이 지난 차단과 다르면 = 진전이면
    73	#   카운터를 리셋한다. 같은 지문으로 MAX_BLOCKS회 = 진짜 갇힘일 때만 경고와 통과.
    74	count=0
    75	if [ -f "$BLOCK_COUNT" ]; then
    76	  count="$(tr -dc '0-9' < "$BLOCK_COUNT" 2>/dev/null)"
    77	fi
    78	[ -z "$count" ] && count=0
    79	prev_fp="$(cat "$BLOCK_FP" 2>/dev/null)"
    80	# 지문 = 서 있는 플래그의 집합(내용 아님). 내용을 넣으면 갇힌 채 새 파일만 편집해도
    81	# 리셋되고(무한 차단), cksum 충돌로 실제 진전이 리셋 안 될 수도 있다([cx] 지적).
    82	flags_fp=""
    83	[ -s "$AUDIT_FLAG" ]      && flags_fp="${flags_fp}a"
    84	[ -s "$EXPLAIN_FLAG" ]    && flags_fp="${flags_fp}e"
    85	knowledge_gate_active     && flags_fp="${flags_fp}k"
    86	[ -s "$DUALREVIEW_FLAG" ] && flags_fp="${flags_fp}d"
    87	# push 는 "몇 개 남았나"가 곧 진전이다. 지문에 안 넣으면 한 커밋씩 올리는 실제 진전이
    88	# 같은 지문으로 세어져 예산이 소진되고, 그때 감사 플래그까지 함께 지워진다([cx] 지적).
    89	[ -n "$push_unsent" ] && flags_fp="${flags_fp}p:${push_branch}:${push_unsent}"
    90	new_fp=""
    91	
    92	gate_budget() {  # $1 = 게이트 식별자. 각 차단 지점이 메시지 출력 전에 호출한다.
    93	  new_fp="$1|$flags_fp"
    94	  # 지문을 기록할 수 있을 때만 리셋한다 — 지문 파일을 못 쓰는 환경에서 리셋하면
    95	  # prev_fp가 영원히 비어 매번 1/3로 무한 차단된다([cx] 지적). 그 경우 리셋 없는
    96	  # 구식 누적으로 동작해 3회 후 통과가 보장된다.
    97	  if printf '%s\n' "$new_fp" > "$BLOCK_FP" 2>/dev/null; then
    98	    if [ "$new_fp" != "$prev_fp" ]; then
    99	      count=0   # 지난 차단과 다른 게이트/플래그 집합 = 진전 — 예산 리셋
   100	    fi
   101	  fi
   102	  if [ "$count" -ge "$MAX_BLOCKS" ]; then
   103	    changed="$(cat "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" 2>/dev/null | tr -d '"\\' | sort -u | tr '\n' ' ')"
   104	    rm -f "$AUDIT_FLAG" "$EXPLAIN_FLAG" "$KNOWLEDGE_FLAG" "$DUALREVIEW_FLAG" "$BLOCK_COUNT" "$BLOCK_FP" 2>/dev/null
   105	    printf '{"systemMessage":"[완료 게이트] 같은 지점(%s)에서 %s회 차단 후에도 진전이 없어 세션 벽돌 방지를 위해 통과시킵니다. 이 턴의 완료 주장(및 변경 설명)을 신뢰하지 마세요. 미처리 변경: %s"}\n' \
   106	      "$1" "$MAX_BLOCKS" "$changed"
   107	    exit 0
   108	  fi
   109	}
   110	
   111	# 결정 게이트가 대화 기록을 못 읽었으면 **어느 게이트가 막든** 그 사유를 함께 낸다.
   112	# 감사 게이트에만 실으면, 앞 게이트가 먼저 막은 턴에는 안 보이고 그 플래그를 지운 다음
   113	# 턴에는 조기 종료로 **영영 사라진다**(검수 [cx] 지적). 조용히 사라지는 것이 이 게이트를
   114	# 만든 이유 그 자체라, 경고를 삼키지 않는 것이 fail-open 의 조건이다.
   115	emit_decision_note() {
   116	  [ -n "${decision_note:-}" ] || return 0
   117	  echo
   118	  echo "참고: $decision_note"
   119	  echo "      → 이 턴에 사용자에게 물었어야 할 결정이 없었는지 스스로 확인하세요."
   120	}
   121	
   122	bump_and_block() {
   123	  if ! printf '%s\n' "$((count + 1))" > "$BLOCK_COUNT" 2>/dev/null; then
   124	    # 카운터를 못 쓰면 무한루프 위험 → 표준 가드로 폴백
   125	    case "$stop_active" in
   126	      [Tt]rue) exit 0 ;;
   127	    esac
   128	  fi
   129	  exit 2
   130	}
   131	
   132	# (3) 타입체크 — 결정론적 바닥. 명령은 프로필에서 파생된 harness.env 에서 읽는다.
   133	#     HARNESS_TYPECHECK_CMD 가 비어 있으면(타입 없는 언어/미설정) 생략한다.
   134	#     이렇게 하면 이 훅이 특정 스택(pnpm/tsc)에 묶이지 않는다 — 도메인-무관 재사용.
   135	#     **이 파일을 실행하지 않는다.** source 하면 사용자 소유 셸 파일이 훅의 제어 흐름을
   136	#     가져간다 — `exit 0` 한 줄이면 이 훅이 조용히 끝나 **게이트 4종이 통째로 사라지고**
   137	#     흔적도 안 남는다. 원문 판독으로 그 부류를 없앤다(harness_env_value 주석 참조).
   138	typecheck_note=""
   139	#     rc 를 함께 받는다. "리터럴로 비웠다"(rc=0 + 빈 값 = 의도한 생략)와 "값을 믿을 수
   140	#     없다"(rc=1 = 미설정·선언 2개 이상·지원 문법 밖·읽기 실패)는 둘 다 생략으로 가지만
   141	#     사용자에게 **다른 정보**다. 후자는 고칠 수 있는 실수라 그렇게 적어야 한다.
   142	TYPECHECK_CMD="$(harness_env_value HARNESS_TYPECHECK_CMD)"; typecheck_rc=$?
   143	
   144	if [ "$typecheck_rc" -ne 0 ]; then
   145	  typecheck_note="타입체크 생략 (harness.env 의 HARNESS_TYPECHECK_CMD 를 읽지 못함 — 미설정이거나, 선언이 2개 이상이거나, 지원 문법 밖입니다)"

2026-08-10T08:16:02.946485Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "rg -n 'queue-operation|attachment|last-prompt|custom-title|isSidechain|toolUseResult|\"type\"\\s*:\\s*\"assistant\"|\"content\"\\s*:\\s*null' --hidden --glob '"'!_workspace/09_delta.diff'"' --glob '"'!_workspace/08_codex_review.md'"' --glob '"'!_workspace/08_decision-gate.diff'"' . | head -300
nl -ba tests/decision-gate.test.sh | sed -n '1,700p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
./docs/decisions/2026-08-10-decision-gate.md:153:2. **턴 경계의 두 판정이 서로를 가렸다.** 실제 기록은 상단 `toolUseResult` 와 `tool_result` 블록을 **항상 함께** 갖고 있다(실측 69/69). 그래서 한쪽을 지워도 다른 쪽이 막아 준다. 표식이 하나뿐인 픽스처를 만들어 각각을 독립적으로 지키게 했다.
./template/.claude/hooks/_common.sh:315:# 서브에이전트 발화(isSidechain)도 뺀다: 서브에이전트는 사용자에게 물을 수 없다.
./template/.claude/hooks/_common.sh:401:    if e.get("type") != "user" or e.get("isSidechain"):
./template/.claude/hooks/_common.sh:403:    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
./template/.claude/hooks/_common.sh:448:    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):
./_workspace/09_codex_prompt.md:36:  `queue-operation`·`attachment`·`last-prompt`·`custom-title` 같은 항목도 섞여 있다
./_workspace/mutate-decision-gate.sh:181:  '    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):' \
./_workspace/mutate-decision-gate.sh:208:run_mutation '상단 toolUseResult 판정을 지운다' "$COMMON" \
./_workspace/mutate-decision-gate.sh:209:  '    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
./tests/decision-gate.test.sh:89:    return {"type": "user", "isSidechain": False,
./tests/decision-gate.test.sh:100:        rows.append({"type": "user", "isSidechain": False,
./tests/decision-gate.test.sh:101:                     "toolUseResult": {"stdout": val},
./tests/decision-gate.test.sh:109:    if kind == "toolresult_top":       # 상단 toolUseResult 만 (content 는 평문)
./tests/decision-gate.test.sh:110:        rows.append({"type": "user", "isSidechain": False,
./tests/decision-gate.test.sh:111:                     "toolUseResult": {"stdout": val},
./tests/decision-gate.test.sh:115:        rows.append({"type": "user", "isSidechain": False,
./tests/decision-gate.test.sh:125:        rows.append({"type": "assistant", "isSidechain": False,
./tests/decision-gate.test.sh:129:        rows.append({"type": "assistant", "isSidechain": False, "message": "문자열 메시지"})
./tests/decision-gate.test.sh:132:        rows.append({"type": "assistant", "isSidechain": False, "message": {"content": 42}})
./tests/decision-gate.test.sh:147:    rows.append({"type": "assistant", "isSidechain": side,
./tests/decision-gate.test.sh:404:    fh.write(json.dumps({"type": "assistant", "isSidechain": False, "message": {"content": [
./_workspace/09_codex_r2.md:50:  `queue-operation`·`attachment`·`last-prompt`·`custom-title` 같은 항목도 섞여 있다
./_workspace/09_codex_r2.md:557:   '    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):' \
./_workspace/09_codex_r2.md:584: run_mutation '상단 toolUseResult 판정을 지운다' "$COMMON" \
./_workspace/09_codex_r2.md:585:   '    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
./_workspace/09_codex_r2.md:910: 2. **턴 경계의 두 판정이 서로를 가렸다.** 실제 기록은 상단 `toolUseResult` 와 `tool_result` 블록을 **항상 함께** 갖고 있다(실측 69/69). 그래서 한쪽을 지워도 다른 쪽이 막아 준다. 표식이 하나뿐인 픽스처를 만들어 각각을 독립적으로 지키게 했다.
./_workspace/09_codex_r2.md:1151: # 서브에이전트 발화(isSidechain)도 뺀다: 서브에이전트는 사용자에게 물을 수 없다.
./_workspace/09_codex_r2.md:1241:     if e.get("type") != "user" or e.get("isSidechain"):
./_workspace/09_codex_r2.md:1243:     if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
./_workspace/09_codex_r2.md:1292:     if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):
./_workspace/09_codex_r2.md:1769:     return {"type": "user", "isSidechain": False,
./_workspace/09_codex_r2.md:1780:         rows.append({"type": "user", "isSidechain": False,
./_workspace/09_codex_r2.md:1781:                      "toolUseResult": {"stdout": val},
./_workspace/09_codex_r2.md:1789:     if kind == "toolresult_top":       # 상단 toolUseResult 만 (content 는 평문)
./_workspace/09_codex_r2.md:1790:         rows.append({"type": "user", "isSidechain": False,
./_workspace/09_codex_r2.md:1791:                      "toolUseResult": {"stdout": val},
./_workspace/09_codex_r2.md:1795:         rows.append({"type": "user", "isSidechain": False,
./_workspace/09_codex_r2.md:1805:+        rows.append({"type": "assistant", "isSidechain": False,
./_workspace/09_codex_r2.md:1809:+        rows.append({"type": "assistant", "isSidechain": False, "message": "문자열 메시지"})
./_workspace/09_codex_r2.md:1812:+        rows.append({"type": "assistant", "isSidechain": False, "message": {"content": 42}})
./_workspace/09_codex_r2.md:1827:     rows.append({"type": "assistant", "isSidechain": side,
./_workspace/09_codex_r2.md:2031:     fh.write(json.dumps({"type": "assistant", "isSidechain": False, "message": {"content": [
./_workspace/09_codex_r2.md:2589:   315	# 서브에이전트 발화(isSidechain)도 뺀다: 서브에이전트는 사용자에게 물을 수 없다.
./_workspace/09_codex_r2.md:2675:   401	    if e.get("type") != "user" or e.get("isSidechain"):
./_workspace/09_codex_r2.md:2677:   403	    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
./_workspace/09_codex_r2.md:2722:   448	    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):
./_workspace/09_codex_r2.md:3185:   315	# 서브에이전트 발화(isSidechain)도 뺀다: 서브에이전트는 사용자에게 물을 수 없다.
./_workspace/09_codex_r2.md:3271:   401	    if e.get("type") != "user" or e.get("isSidechain"):
./_workspace/09_codex_r2.md:3273:   403	    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
./_workspace/09_codex_r2.md:3318:   448	    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):
     1	#!/usr/bin/env bash
     2	# decision-gate.test.sh — Stop 훅의 **결정 게이트**(stop:decision) 회귀 방어.
     3	#
     4	#   "코드/결정이 바뀐 턴에 결정 표지 어휘가 있는데 AskUserQuestion 이 0회면 막는다"
     5	#
     6	# 이 게이트만 **에이전트 자신의 행동**을 본다(나머지 넷은 산출물을 본다). 그래서 실패
     7	# 방향이 둘 다 비싸다:
     8	#   위음성 — 혼자 정하고 한 줄 적는 것이 그대로 통과한다. 이 저장소가 반복해서 겪은 부류다
     9	#   위양성 — 질문이 소음이 되고, 소음이 되면 진짜 질문도 무시된다. 게이트가 자기를 죽인다
    10	# 그래서 **양쪽을 다 케이스로 붙든다.** 위양성 케이스가 이 파일의 절반인 이유다 —
    11	# 나중에 누가 패턴을 넓히면 그 케이스들이 빨개져서 대가를 눈에 보이게 한다.
    12	#
    13	# **판정 규칙의 사본을 두지 않는다.** 어떤 어휘가 표지인지·무엇이 서술형인지를 여기서
    14	# 다시 정의하면 그 사본이 언젠가 원본과 어긋나고, 그때 테스트는 틀린 기준으로 초록을 낸다.
    15	# 대신 훅 **자신을 돌려** 차단 여부와 메시지로 잰다.
    16	#
    17	# **rc 만으로 판정하지 않는다.** 결정 게이트가 통과해도 뒤의 감사 게이트가 rc=2 를 내므로
    18	# rc 는 두 경우에 **같다.** 어느 게이트가 말했는지는 메시지로만 갈린다(위음성 카탈로그 17번:
    19	# 관례 코드에 도달하는 경로가 여럿이면 rc 일치가 의도한 경로를 뜻하지 않는다).
    20	#
    21	# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
    22	# 셸 이식성: macOS 기본 bash 는 3.2 다. mapfile·연관배열·${var,,} 금지.
    23	
    24	set -uo pipefail
    25	
    26	TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    27	REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
    28	HOOKS="$REPO_ROOT/template/.claude/hooks"
    29	
    30	command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (스캐너·픽스처 의존)" >&2; exit 1; }
    31	for f in verify-before-stop.sh _common.sh; do
    32	  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
    33	done
    34	
    35	TMPROOT="$(mktemp -d)" || exit 1
    36	if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
    37	  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
    38	fi
    39	TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
    40	# chmod 000 픽스처가 있으므로 되돌린 뒤 지운다 — 안 그러면 정리가 실패한다.
    41	trap 'chmod -R u+rwX "$TMPROOT" 2>/dev/null; rm -rf "$TMPROOT"' EXIT
    42	
    43	ran=0; pass=0; fail=0
    44	RC=999; ERR=''; OUT=''; DID_RUN=0
    45	PROJ_N=0
    46	
    47	# 판정 토큰. 훅 메시지의 **고유 문구**를 쓴다 — 어느 게이트가 말했는지는 이걸로만 갈린다.
    48	TOK_DECISION='혼자 정한 것이 있는데'
    49	TOK_NOTE='결정 게이트 생략'
    50	TOK_AUDIT='completion-auditor 미실행'
    51	TOK_BRICK='세션 벽돌 방지'
    52	
    53	report() {
    54	  ran=$((ran + 1))
    55	  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
    56	  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
    57	}
    58	
    59	contains() { case "$1" in *"$2"*) return 0 ;; esac; return 1; }
    60	
    61	# --- 픽스처 --------------------------------------------------------------
    62	
    63	# new_project <지식게이트값> — 케이스마다 독립 프로젝트. 경로를 stdout 에.
    64	# 지식게이트값: 리터럴로 비면 꺼짐, 그 외 문자열이면 켜짐.
    65	# 타입체크는 항상 리터럴로 비운다 — 이 파일이 재는 것은 결정 게이트뿐이고, 타입체크가
    66	# 먼저 막으면 그 케이스는 결정 게이트에 **도달조차 못 한 채** 기대값이 우연히 맞는다.
    67	new_project() {
    68	  PROJ_N=$((PROJ_N + 1))
    69	  local p="$TMPROOT/proj$PROJ_N"
    70	  mkdir -p "$p/.claude/hooks" "$p/.claude/harness" || return 1
    71	  cp "$HOOKS/_common.sh" "$HOOKS/verify-before-stop.sh" "$p/.claude/hooks/" || return 1
    72	  printf 'HARNESS_TYPECHECK_CMD=""\nHARNESS_KNOWLEDGE_GATE="%s"\n' "$1" \
    73	    > "$p/.claude/harness/harness.env" || return 1
    74	  printf '%s\n' "$p"
    75	}
    76	
    77	# mk_transcript <출력경로> <항목...> — 대화 기록 JSONL 을 만든다.
    78	# 항목 문법:  text:<문장> · side:<문장>(서브에이전트) · think:<문장> · ask ·
    79	#             tool:<내용>(도구 입력) · prompt(새 사용자 프롬프트=턴 경계) · toolresult:<내용>
    80	# 첫 줄은 항상 사용자 프롬프트다 — 그게 없는 경우는 판독 불가 케이스에서 따로 만든다.
    81	mk_transcript() {
    82	  python3 - "$@" <<'PY'
    83	import json, sys
    84	
    85	out = sys.argv[1]
    86	
    87	
    88	def prompt():
    89	    return {"type": "user", "isSidechain": False,
    90	            "message": {"role": "user", "content": "작업해줘"}}
    91	
    92	
    93	rows = [prompt()]
    94	for spec in sys.argv[2:]:
    95	    kind, _, val = spec.partition(":")
    96	    if kind == "prompt":
    97	        rows.append(prompt())
    98	        continue
    99	    if kind == "toolresult":
   100	        rows.append({"type": "user", "isSidechain": False,
   101	                     "toolUseResult": {"stdout": val},
   102	                     "message": {"role": "user",
   103	                                 "content": [{"type": "tool_result", "content": val}]}})
   104	        continue
   105	    # 실제 기록에서는 두 표식이 **항상 함께** 온다(실측 69/69). 그래서 둘 다 보는 판정은
   106	    # 서로를 가려, 한쪽을 지워도 아무 케이스가 안 빨개진다 — 변이 측정에서 실제로 드러났다.
   107	    # 각각을 **독립적으로** 지키려면 표식이 하나뿐인 기록이 필요하다. 형식이 바뀌어 한쪽만
   108	    # 남는 날, 남은 한쪽이 실제로 일하는지를 재는 것이 이 두 항목이다.
   109	    if kind == "toolresult_top":       # 상단 toolUseResult 만 (content 는 평문)
   110	        rows.append({"type": "user", "isSidechain": False,
   111	                     "toolUseResult": {"stdout": val},
   112	                     "message": {"role": "user", "content": val}})
   113	        continue
   114	    if kind == "toolresult_blk":       # tool_result 블록만 (상단 키 없음)
   115	        rows.append({"type": "user", "isSidechain": False,
   116	                     "message": {"role": "user",
   117	                                 "content": [{"type": "tool_result", "content": val}]}})
   118	        continue
   119	    # 형식이 어긋난 항목들. 전부 "판독 불가"로 떨어져야 하는 입력이다 —
   120	    # 조용히 건너뛰면 그 발화가 스캔에서 사라지고 게이트가 죽은 줄도 모른다.
   121	    if kind == "broken":               # JSON 이 아닌 줄
   122	        rows.append("\x00RAW\x00" + (val or "not json at all {{{"))
   123	        continue
   124	    if kind == "strtext":              # content 가 문자열인 assistant (형식 변형)
   125	        rows.append({"type": "assistant", "isSidechain": False,
   126	                     "message": {"content": val}})
   127	        continue
   128	    if kind == "badmsg":               # message 가 truthy 비-dict
   129	        rows.append({"type": "assistant", "isSidechain": False, "message": "문자열 메시지"})
   130	        continue
   131	    if kind == "badcontent":           # content 가 list 도 str 도 아님
   132	        rows.append({"type": "assistant", "isSidechain": False, "message": {"content": 42}})
   133	        continue
   134	    side = False
   135	    if kind == "side":
   136	        side, kind = True, "text"
   137	    if kind == "text":
   138	        block = {"type": "text", "text": val}
   139	    elif kind == "think":
   140	        block = {"type": "thinking", "thinking": val}
   141	    elif kind == "ask":
   142	        block = {"type": "tool_use", "name": "AskUserQuestion", "input": {}}
   143	    elif kind == "tool":
   144	        block = {"type": "tool_use", "name": "Write", "input": {"content": val}}
   145	    else:
   146	        raise SystemExit("알 수 없는 항목: " + spec)
   147	    rows.append({"type": "assistant", "isSidechain": side,
   148	                 "message": {"content": [block]}})
   149	
   150	with open(out, "w", encoding="utf-8") as fh:
   151	    for row in rows:
   152	        if isinstance(row, str) and row.startswith("\x00RAW\x00"):
   153	            fh.write(row[5:] + "\n")     # 일부러 깨뜨린 줄은 그대로 쓴다
   154	        else:
   155	            fh.write(json.dumps(row, ensure_ascii=False) + "\n")
   156	PY
   157	}
   158	
   159	# run_stop <프로젝트> <transcript경로|빈문자열> [env 인자...]
   160	# 빈 문자열이면 payload 에서 transcript_path 키를 **아예 뺀다**(키 부재 케이스).
   161	run_stop() {
   162	  local p="$1" tp="$2"
   163	  shift 2
   164	  local errf="$TMPROOT/err.$$" outf="$TMPROOT/out.$$" payf="$TMPROOT/pay.$$"
   165	  RC=999; ERR=''; OUT=''; DID_RUN=1
   166	  # payload 를 **파일로** 넘긴다. 파이프로 주면 훅이 stdin 을 읽기 전에 종료하는 경로
   167	  # (탈출구로 꺼진 경우 등)에서 생산자 python 이 SIGPIPE 를 맞아 BrokenPipeError 를
   168	  # 출력에 흘린다 — 진짜 실패와 구별이 안 되는 잡음이다.
   169	  python3 -c '
   170	import json, sys
   171	d = {"stop_hook_active": False}
   172	if sys.argv[1]:
   173	    d["transcript_path"] = sys.argv[1]
   174	with open(sys.argv[2], "w", encoding="utf-8") as fh:
   175	    fh.write(json.dumps(d))' "$tp" "$payf"
   176	  env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$p" \
   177	      bash "$p/.claude/hooks/verify-before-stop.sh" <"$payf" >"$outf" 2>"$errf"
   178	  RC=$?
   179	  rm -f "$payf"
   180	  ERR="$(cat "$errf" 2>/dev/null)"
   181	  OUT="$(cat "$outf" 2>/dev/null)"
   182	  rm -f "$errf" "$outf"
   183	}
   184	
   185	# setup_flags <프로젝트> <플래그 이름...>  (audit|explain|knowledge|dualreview)
   186	setup_flags() {
   187	  local p="$1"; shift
   188	  rm -f "$p/.claude/.needs-audit" "$p/.claude/.needs-explain" \
   189	        "$p/.claude/.needs-knowledge" "$p/.claude/.needs-dualreview" \
   190	        "$p/.claude/.stop-block-count" "$p/.claude/.stop-block-fp" 2>/dev/null
   191	  local f
   192	  for f in "$@"; do printf 'src/changed.ts\n' > "$p/.claude/.needs-$f"; done
   193	}
   194	
   195	# --- 공통 케이스 형태 -----------------------------------------------------
   196	#
   197	# blocked = 결정 게이트가 **막아야** 한다
   198	# silent  = 결정 게이트는 **아무 말도 하지 않아야** 한다 (뒤 게이트가 막는 것은 정상)
   199	#
   200	# silent 판정에 rc=0 을 쓰지 않는 이유: 플래그가 서 있으면 감사 게이트가 반드시 rc=2 를
   201	# 낸다. 그래서 결정 게이트의 침묵만 요구하고, 동시에 **감사 게이트가 실제로 말했는지**를
   202	# 함께 요구한다 — 안 그러면 훅이 앞에서 죽어 아무것도 안 재고도 통과한다(15번 부류).
   203	
   204	blocked_case() {   # $1=이름 $2=기대문장조각("" 이면 생략) $3..=기록 항목
   205	  local name="$1" want_hit="$2" why=''
   206	  shift 2
   207	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   208	  local tp="$p/transcript.jsonl"
   209	  mk_transcript "$tp" "$@" || { report "$name" '픽스처 실패: 기록 생성'; return 0; }
   210	  [ -s "$tp" ] || { report "$name" '픽스처 실패: 기록이 비어 있다'; return 0; }
   211	  setup_flags "$p" audit
   212	  run_stop "$p" "$tp"
   213	  if [ "$DID_RUN" -ne 1 ];                then why='훅을 실행하지 않았다'
   214	  elif [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2) / $(printf '%s' "$ERR" | head -c 100)"
   215	  elif ! contains "$ERR" "$TOK_DECISION"; then why="결정 게이트가 아닌 것이 막았다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   216	  elif [ -n "$want_hit" ] && ! contains "$ERR" "$want_hit"; then
   217	    why="걸린 문장이 메시지에 없다 (기대 조각: $want_hit)"
   218	  fi
   219	  report "$name" "$why"
   220	}
   221	
   222	silent_case() {   # $1=이름 $2..=기록 항목
   223	  local name="$1" why=''
   224	  shift
   225	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   226	  local tp="$p/transcript.jsonl"
   227	  mk_transcript "$tp" "$@" || { report "$name" '픽스처 실패: 기록 생성'; return 0; }
   228	  [ -s "$tp" ] || { report "$name" '픽스처 실패: 기록이 비어 있다'; return 0; }
   229	  setup_flags "$p" audit
   230	  run_stop "$p" "$tp"
   231	  if [ "$DID_RUN" -ne 1 ];              then why='훅을 실행하지 않았다'
   232	  elif contains "$ERR" "$TOK_DECISION"; then why='위양성 — 결정 게이트가 막았다'
   233	  elif [ "$RC" -ne 2 ];                 then why="rc=$RC (기대 2 — 감사 게이트가 막아야 한다)"
   234	  elif ! contains "$ERR" "$TOK_AUDIT";  then why="감사 게이트에 도달하지 못했다 = 아무것도 안 쟀다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   235	  elif contains "$ERR" "$TOK_NOTE";     then why='판독 불가로 빠졌다 — 스캔이 실제로 돌지 않았다'
   236	  fi
   237	  report "$name" "$why"
   238	}
   239	
   240	# ── 1. 막아야 하는 것 ─────────────────────────────────────────────────
   241	# 문장 형태는 전부 지난 세션에서 실제로 쓴 것이다(ADR-0011 Context 절).
   242	d01() { blocked_case '표지 + 서술형 + 질문 0회 를 막는다' '범위 밖' \
   243	          'text:이건 이번 PR 범위 밖이라 그대로 뒀습니다.'; }
   244	d02() { blocked_case '제 판단으로 형태를 막는다' '제 판단으로' \
   245	          'text:제 판단으로 끄지 않고 그대로 진행했습니다.'; }
   246	d03() { blocked_case '공시 형태를 막는다' '공시' \
   247	          'text:남은 것은 공시하고 넘어갑니다.'; }
   248	d04() { blocked_case '트레이드오프 단정을 막는다' '트레이드오프' \
   249	          'text:이건 버그가 아니라 의도된 트레이드오프다.'; }
   250	d05() { blocked_case '수용된 한계 형태를 막는다' '수용된 한계' \
   251	          'text:이 좁은 창은 수용된 한계로 남겼음.'; }
   252	d06() { blocked_case '가정하고 형태를 막는다' '가정하고' \
   253	          'text:기본값이 켜짐이라고 가정하고 구현했습니다.'; }
   254	d07() { blocked_case '안 했습니다 형태를 막는다' '안 했습니다' \
   255	          'text:그 부분은 시간이 없어 안 했습니다.'; }
   256	# **걸린 문장을 메시지에 싣는 것이 계약이다.** 안 실으면 무엇을 물어야 할지 알 수 없어
   257	# 에이전트가 "일단 아무거나 물어서 풀자"로 간다 — 게이트가 의식(儀式)이 되는 경로다.
   258	d08() { blocked_case '걸린 문장 여러 개를 함께 싣는다' '별도로' \
   259	          'text:이건 범위 밖이라 뺐습니다.' 'text:나머지는 별도로 처리했습니다.'; }
   260	d09() { blocked_case '표지가 마지막 발화에만 있어도 막는다' '그대로 뒀' \
   261	          'text:작업을 시작합니다.' 'text:충돌 나는 부분은 그대로 뒀습니다.'; }
   262	
   263	# ── 2. 위양성 — 막으면 안 되는 것 ─────────────────────────────────────
   264	# 이 절이 파일의 절반인 이유: 어휘만 보면 이 게이트를 **유지보수하는 작업 자체가** 매번
   265	# 걸린다(훅·테스트·결정 문서가 그 어휘를 데이터로 품는다). 그러면 사람이 게이트를 끄고,
   266	# 꺼진 게이트는 없는 게이트다. 패턴을 넓히려는 다음 사람은 여기서 대가를 본다.
   267	d10() { silent_case '질문을 한 번 했으면 풀린다' \
   268	          'text:이건 범위 밖이라 그대로 뒀습니다.' 'ask'; }
   269	d11() { silent_case '질문이 표지보다 앞에 와도 풀린다' \
   270	          'ask' 'text:여쭌 대로 범위 밖으로 뒀습니다.'; }
   271	d12() { silent_case '백틱으로 인용한 어휘는 결정이 아니다' \
   272	          'text:결정 표지 어휘는 `범위 밖` 과 `그대로 뒀` 이다.'; }
   273	d13() { silent_case '따옴표로 인용한 어휘는 결정이 아니다' \
   274	          'text:사용자가 "범위 밖"이라고 하셨으므로 그렇게 했습니다.'; }
   275	d14() { silent_case '인용줄로 시작하는 줄은 스캔하지 않는다' \
   276	          'text:> 이건 범위 밖이라 그대로 뒀습니다.'; }
   277	d15() { silent_case '코드펜스 안은 스캔하지 않는다' \
   278	          'text:예시:
   279	```
   280	이건 범위 밖이라 그대로 뒀습니다.
   281	```
   282	위가 걸리는 형태다.'; }
   283	# 펜스가 안 닫힌 채 기록이 잘렸으면 **남은 전부를 코드로 친다.** 반대로 두면 잘린 기록의
   284	# 코드 블록이 산문으로 새어 위양성이 터진다.
   285	d16() { silent_case '닫히지 않은 코드펜스 뒤는 전부 코드로 친다' \
   286	          'text:예시:
   287	```
   288	이건 범위 밖이라 그대로 뒀습니다.'; }
   289	d17() { silent_case '질문형 문장은 표지로 세지 않는다' \
   290	          'text:이건 범위 밖으로 둘까요?'; }
   291	d18() { silent_case '선택을 요청하는 문장도 세지 않는다' \
   292	          'text:범위 밖으로 뺄지 어느 쪽이 좋은지 말씀해 주세요.'; }
   293	# **묻겠다는 말이 서술형으로 끝나는 경우가 질문 신호 판정의 진짜 시험대다.** d17·d18 은
   294	# 종결이 "…까요/…세요"라 서술형 요구에서 이미 걸러져 질문 판정에 도달조차 하지 않는다 —
   295	# 그래서 질문 판정을 지워도 아무것도 안 빨개졌다(변이 측정에서 드러났다).
   296	d18b() { silent_case '묻겠다는 말이 서술형으로 끝나도 세지 않는다' \
   297	          'text:이게 범위 밖인지 여쭙겠습니다.'; }
   298	d18c() { silent_case '물어보겠다는 말도 세지 않는다' \
   299	          'text:이걸 별도로 뺄지 사용자에게 물어보겠습니다.'; }
   300	d19() { silent_case 'thinking 블록은 스캔하지 않는다' \
   301	          'think:이건 범위 밖이라 그대로 뒀습니다.'; }
   302	d20() { silent_case '서브에이전트 발화는 스캔하지 않는다' \
   303	          'side:이건 범위 밖이라 그대로 뒀습니다.'; }
   304	# **도구 입력을 안 보는 것이 자기참조 폭발을 막는 장치다.** 이 패턴이 적힌 파일을
   305	# Write/Edit 로 쓰는 것 자체는 결정이 아니다.
   306	d21() { silent_case '도구 입력(파일 내용)은 스캔하지 않는다' \
   307	          'tool:이건 범위 밖이라 그대로 뒀습니다.'; }
   308	d22() { silent_case '서술형이 아니면(명사 종결) 세지 않는다' \
   309	          'text:- 범위 밖'; }
   310	d23() { silent_case '표지가 없으면 아무리 길어도 안 잡는다' \
   311	          'text:구현을 마쳤고 테스트 12건이 전부 통과했습니다.'; }
   312	# 턴 경계. 지난 턴의 자백까지 세면 이미 해소된 것으로 영원히 막힌다.
   313	d24() { silent_case '지난 턴의 문장은 보지 않는다' \
   314	          'text:이건 범위 밖이라 그대로 뒀습니다.' 'prompt' 'text:이번에는 전부 처리했습니다.'; }
   315	# 도구 결과는 사용자 발화가 아니다. 이걸 턴 경계로 세면 창이 도구 호출 하나로 좁아져
   316	# 게이트가 사실상 사라진다. 두 방향으로 잰다 — 놓치지 않는가(d25b)와 오탐하지 않는가(d25).
   317	d25() { silent_case '도구 결과 뒤라도 표지가 없으면 안 막는다' \
   318	          'text:작업을 시작합니다.' 'toolresult:ok' 'text:테스트가 전부 통과했습니다.'; }
   319	d25b() { blocked_case '도구 결과 뒤의 자백도 같은 턴으로 본다' '범위 밖' \
   320	          'text:작업을 시작합니다.' 'toolresult:ok' 'text:나머지는 범위 밖이라 뒀습니다.'; }
   321	# **자백이 도구 결과보다 앞에 있는 경우가 판정의 진짜 시험대다.** 도구 결과를 턴 경계로
   322	# 오인하면 그 앞의 발화가 통째로 창 밖으로 밀려 사라지는데, d25b 는 자백이 뒤에 있어서
   323	# 그 오인을 못 잡는다(경계가 밀려도 뒤 문장은 여전히 창 안이다).
   324	d25c() { blocked_case '도구 결과 앞의 자백도 놓치지 않는다' '범위 밖' \
   325	          'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult:ok' 'text:작업을 마쳤습니다.'; }
   326	# 표식이 하나뿐인 도구 결과. 두 판정(상단 키 / 블록)을 **각각** 지킨다 — 실제 기록은 둘 다
   327	# 갖고 있어서 서로를 가리고, 그러면 한쪽을 지워도 아무 케이스가 안 빨개진다.
   328	d25d() { blocked_case '상단 키만 있는 도구 결과도 턴 경계가 아니다' '범위 밖' \
   329	          'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult_top:ok' 'text:작업을 마쳤습니다.'; }
   330	d25e() { blocked_case '블록만 있는 도구 결과도 턴 경계가 아니다' '범위 밖' \
   331	          'text:나머지는 범위 밖이라 뒀습니다.' 'toolresult_blk:ok' 'text:작업을 마쳤습니다.'; }
   332	
   333	# ── 3. 발동 조건 — 어느 플래그에서 도나 ──────────────────────────────
   334	# 사용자 확정(2026-08-10): 코드뿐 아니라 **결정 문서·설계 산출물** 턴에서도 돈다.
   335	# 표지 어휘가 가장 자주 나오는 자리가 결정 문서를 쓰는 턴이기 때문이다.
   336	flag_case() {   # $1=이름 $2=지식게이트값 $3=플래그(none 가능) $4=기대(block|exit0)
   337	  local name="$1" kg="$2" flag="$3" want="$4" why=''
   338	  local p; p="$(new_project "$kg")" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   339	  local tp="$p/transcript.jsonl"
   340	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.' || { report "$name" '픽스처 실패'; return 0; }
   341	  if [ "$flag" = 'none' ]; then setup_flags "$p"; else setup_flags "$p" "$flag"; fi
   342	  run_stop "$p" "$tp"
   343	  case "$want" in
   344	    block)
   345	      if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2)"
   346	      elif ! contains "$ERR" "$TOK_DECISION"; then why="결정 게이트가 아닌 것이 막았다: $(printf '%s' "$ERR" | head -1 | head -c 80)"
   347	      fi ;;
   348	    exit0)
   349	      if   [ "$RC" -ne 0 ];                 then why="rc=$RC (기대 0 — 할 일이 없으면 조기 종료)"
   350	      elif contains "$ERR" "$TOK_DECISION"; then why='할 일이 없는 턴인데 결정 게이트가 막았다'
   351	      fi ;;
   352	    *) why="알 수 없는 기대값: $want" ;;
   353	  esac
   354	  report "$name" "$why"
   355	}
   356	d26() { flag_case '코드 변경 턴에서 돈다'        ''   audit      block; }
   357	d27() { flag_case '설계 산출물 턴에서 돈다'      ''   dualreview block; }
   358	d28() { flag_case '결정 문서 턴에서 돈다'        'on' knowledge  block; }
   359	d29() { flag_case '변경설명 턴에서 돈다'         ''   explain    block; }
   360	# **아무것도 안 바꾼 턴은 막지 않는다.** 순수 질의응답에서 어휘를 썼다고 막으면 게이트가
   361	# 대화를 방해한다(사용자 확정: "항상 검사" 보기 기각).
   362	d30() { flag_case '플래그가 하나도 없으면 돌지 않는다' '' none exit0; }
   363	# 공시된 한계를 케이스로 붙든다: 지식 게이트를 끈 환경에서 **결정 문서만** 고친 턴은
   364	# 조기 종료에 걸려 결정 게이트까지 못 간다. 조기 종료를 고치면 "게이트를 껐는데 남은
   365	# 플래그가 읽기 전용 턴을 막는" 알려진 버그가 되살아난다. 기본값이 켜짐이라 기본 구성에서는
   366	# d28 처럼 정상 발동한다. **이 한계가 바뀌면 이 케이스가 빨개져서 알려준다.**
   367	d30b() { flag_case '지식 게이트를 끄면 결정 문서 턴은 조기 종료된다(공시된 한계)' '' knowledge exit0; }
   368	
   369	# ── 4. fail-open — 판독 불가는 **통과 + 경고**다 ─────────────────────
   370	# 대화 기록 형식은 하네스가 소유하지 않는다. 형식이 바뀌었다고 차단하면 그 세션 안에
   371	# 고칠 방법이 없어 **세션이 통째로 벽돌이 된다.** 이 게이트의 유일한 fail-open 지점이고,
   372	# 조건은 **경고를 삼키지 않는 것**이다 — 조용히 통과하면 게이트가 죽은 걸 아무도 모른다.
   373	# openq_case <이름> <기록준비함수> [기대 사유 조각]
   374	#
   375	# **사유 조각까지 요구하는 것이 계약이다.** "경고가 나왔다"만 보면, 그 판독 불가를 알아본
   376	# 개별 검사를 지워도 파이썬이 크래시하면서 호출부의 catch-all 이 **대신** 경고를 내
   377	# 초록으로 남는다(변이 측정에서 실제로 드러났다). 어떤 사유로 멈췄는지까지 봐야 그 검사
   378	# 자신이 지켜진다 — 위음성 카탈로그 17번("rc 단독 판정은 약하다")의 메시지 판이다.
   379	openq_case() {
   380	  local name="$1" prep="$2" want_reason="${3:-}" why=''
   381	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   382	  local tp; tp="$("$prep" "$p")"
   383	  setup_flags "$p" audit
   384	  run_stop "$p" "$tp"
   385	  if   [ "$DID_RUN" -ne 1 ];            then why='훅을 실행하지 않았다'
   386	  elif contains "$ERR" "$TOK_DECISION"; then why='판독 불가인데 차단했다 (세션이 벽돌이 된다)'
   387	  elif [ "$RC" -ne 2 ];                 then why="rc=$RC (기대 2 — 감사 게이트가 막아야 한다)"
   388	  elif ! contains "$ERR" "$TOK_NOTE";   then why='경고를 삼켰다 — 게이트가 조용히 죽은 것을 아무도 모른다'
   389	  elif [ -n "$want_reason" ] && ! contains "$ERR" "$want_reason"; then
   390	    why="사유가 다르다 (기대 조각: $want_reason) — 그 판독 불가를 알아본 검사가 사라졌다"
   391	  fi
   392	  report "$name" "$why"
   393	}
   394	prep_nokey()   { printf '%s\n' ''; }
   395	prep_missing() { printf '%s\n' "$1/does-not-exist.jsonl"; }
   396	prep_garbage() { local f="$1/garbage.jsonl"; printf 'not json at all\n{{{\n' > "$f"; printf '%s\n' "$f"; }
   397	# 사용자 프롬프트가 없는 기록 = 턴 경계를 못 찾은 것. 전체를 훑으면 지난 턴까지 걸리므로
   398	# 판독 불가로 떨어뜨린다. 표지를 일부러 넣어 "그래도 안 막는가"를 잰다.
   399	prep_noprompt() {
   400	  local f="$1/noprompt.jsonl"
   401	  python3 -c '
   402	import json, sys
   403	with open(sys.argv[1], "w", encoding="utf-8") as fh:
   404	    fh.write(json.dumps({"type": "assistant", "isSidechain": False, "message": {"content": [
   405	        {"type": "text", "text": "이건 범위 밖이라 그대로 뒀습니다."}]}}, ensure_ascii=False) + "\n")
   406	' "$f"
   407	  printf '%s\n' "$f"
   408	}
   409	prep_unreadable() { local f="$1/unreadable.jsonl"; printf '{}\n' > "$f"; chmod 000 "$f" 2>/dev/null; printf '%s\n' "$f"; }
   410	d31() { openq_case 'transcript_path 키가 없으면 통과 + 경고' prep_nokey '훅 입력에 없습니다'; }
   411	d32() { openq_case '기록 파일이 없으면 통과 + 경고'          prep_missing '읽을 수 없습니다'; }
   412	d33() { openq_case '전부 깨진 JSON 이면 통과 + 경고'         prep_garbage '파싱하지 못했습니다'; }
   413	d34() { openq_case '턴 시작점을 못 찾으면 통과 + 경고'       prep_noprompt '시작점'; }
   414	d35() {
   415	  # root 로 도는 CI 에서는 chmod 000 이 읽기를 막지 못한다 — 그 환경에서 이 케이스는
   416	  # 아무것도 재지 못하므로 **조용히 통과시키지 않고** 픽스처 무효로 빨갛게 만든다.
   417	  # 조용한 skip 은 커버리지가 사라진 것을 초록으로 위장한다.
   418	  if [ "$(id -u)" = '0' ]; then
   419	    report '읽기 실패하면 통과 + 경고' 'root 라 chmod 000 이 읽기를 막지 못한다 — 이 환경에서는 측정 불가'
   420	    return 0
   421	  fi
   422	  openq_case '읽기 실패하면 통과 + 경고' prep_unreadable '읽을 수 없습니다'
   423	}
   424	
   425	# ── 5. 탈출구 (사용자 확정: 형제 Stop 게이트와 동일하게 제공) ────────
   426	# 이 게이트는 위양성이 **구조적으로** 난다 — 자기 어휘를 문서·설명에서 다뤄야 하기
   427	# 때문이다. 그래서 사용자가 즉시 뺄 수 있어야 한다. 끄는 대입 자체는 guard-hook-disable
   428	# 이 한 번 세운다(과속방지턱이지 방벽은 아니다).
   429	escape_case() {   # $1=이름 $2..=env 인자
   430	  local name="$1" why=''
   431	  shift
   432	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패: 프로젝트 생성'; return 0; }
   433	  local tp="$p/transcript.jsonl"
   434	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.' || { report "$name" '픽스처 실패'; return 0; }
   435	  setup_flags "$p" audit
   436	  run_stop "$p" "$tp" "$@"
   437	  if   [ "$DID_RUN" -ne 1 ];            then why='훅을 실행하지 않았다'
   438	  elif contains "$ERR" "$TOK_DECISION"; then why='껐는데도 결정 게이트가 막았다'
   439	  fi
   440	  report "$name" "$why"
   441	}
   442	d36() { escape_case '개별 비활성으로 끌 수 있다' ECC_DISABLED_HOOKS=stop:decision; }
   443	d37() { escape_case '전체 비활성으로도 꺼진다'   HARNESS_HOOKS=off; }
   444	d38() {
   445	  # **다른 게이트 이름으로는 안 꺼진다.** 접두사·부분 일치로 꺼지면 하나를 끌 때 옆의
   446	  # 게이트가 같이 사라지고 아무도 모른다.
   447	  local name='다른 게이트 이름으로는 안 꺼진다' why=''
   448	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   449	  local tp="$p/transcript.jsonl"
   450	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   451	  setup_flags "$p" audit
   452	  run_stop "$p" "$tp" ECC_DISABLED_HOOKS=stop:explain
   453	  contains "$ERR" "$TOK_DECISION" || why='다른 게이트를 껐는데 결정 게이트까지 꺼졌다'
   454	  report "$name" "$why"
   455	}
   456	
   457	# ── 6. 벽돌 방지 — 같은 지점 MAX_BLOCKS 회면 통과시킨다 ──────────────
   458	# 질문 한 번이면 풀리지만, 어떤 이유로도 못 푸는 상황에서 세션이 영영 안 끝나면 안 된다.
   459	d39() {
   460	  local name='같은 지점에서 MAX_BLOCKS 회 뒤에는 통과시킨다 (벽돌 방지)' why=''
   461	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   462	  local tp="$p/transcript.jsonl"
   463	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   464	  setup_flags "$p" audit
   465	  local i seen_block=0
   466	  for i in 1 2 3; do
   467	    run_stop "$p" "$tp"
   468	    if [ "$RC" -eq 2 ] && contains "$ERR" "$TOK_DECISION"; then seen_block=$((seen_block + 1)); fi
   469	  done
   470	  run_stop "$p" "$tp"
   471	  if   [ "$seen_block" -ne 3 ];        then why="3회 연속 차단이 아니었다 (실제 ${seen_block}회)"
   472	  elif [ "$RC" -ne 0 ];                then why="소진 후 rc=$RC (기대 0)"
   473	  elif ! contains "$OUT" "$TOK_BRICK"; then why="소진 통과인데 경고가 없다: $(printf '%s' "$OUT" | head -c 100)"
   474	  fi
   475	  report "$name" "$why"
   476	}
   477	d40() {
   478	  # **진전하면 예산이 리셋된다.** 질문해서 결정 게이트를 푼 뒤 감사 게이트로 넘어가는 것은
   479	  # 진전이므로, 앞서 쓴 차단 횟수가 뒤 게이트의 예산을 갉아먹으면 안 된다.
   480	  local name='질문해서 풀면 뒤 게이트의 예산이 리셋된다' why=''
   481	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   482	  local blocked="$p/blocked.jsonl" asked="$p/asked.jsonl"
   483	  mk_transcript "$blocked" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   484	  mk_transcript "$asked"   'text:이건 범위 밖이라 그대로 뒀습니다.' 'ask'
   485	  setup_flags "$p" audit
   486	  local i
   487	  for i in 1 2 3; do run_stop "$p" "$blocked"; done
   488	  run_stop "$p" "$asked"
   489	  if   [ "$RC" -ne 2 ];                then why="rc=$RC (기대 2 — 감사 게이트가 살아 있어야 한다)"
   490	  elif ! contains "$ERR" "$TOK_AUDIT"; then why="감사 게이트가 예산 소진으로 사라졌다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   491	  fi
   492	  report "$name" "$why"
   493	}
   494	
   495	# ── 7. 순서 계약 — 결정 게이트가 다른 게이트보다 앞이다 ──────────────
   496	# 질문의 답이 코드를 바꿀 수 있으므로 리뷰·설명·감사에 노력을 쓰기 전에 물어야 한다.
   497	d41() {
   498	  local name='듀얼리뷰·설명·감사보다 먼저 말한다' why=''
   499	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   500	  local tp="$p/transcript.jsonl"
   501	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   502	  setup_flags "$p" audit explain dualreview
   503	  run_stop "$p" "$tp"
   504	  if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2)"
   505	  elif ! contains "$ERR" "$TOK_DECISION"; then why="다른 게이트가 먼저 말했다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   506	  fi
   507	  report "$name" "$why"
   508	}
   509	
   510	# ── 8. 듀얼 검수 1라운드 반영분 ([cx] 지적) ──────────────────────────
   511	# 고침의 실측과 회귀 방어는 다른 일이다. 고쳤으면 "이 줄을 지우면 무엇이 빨개지나"에
   512	# 답이 있어야 한다 — 아래가 그 답이다.
   513	
   514	# [cx] **"묻지 않았다"가 질문 신호에 걸려 제외됐다** — 겨누는 문장 자체가 빠져나갔다.
   515	d42() { blocked_case '"물어보지 않고 …했습니다" 를 막는다' '제 판단으로' \
   516	          'text:사용자에게 물어보지 않고 제 판단으로 진행했습니다.'; }
   517	d43() { blocked_case '"확인하지 않고 …했습니다" 를 막는다' '가정하여' \
   518	          'text:사용자 의견을 확인하지 않고 가정하여 구현했습니다.'; }
   519	# [cx] 마침표를 무조건 종결로 보면 파일명이 문장을 쪼개 **표지와 종결이 갈린다**.
   520	d44() { blocked_case '파일명 속 마침표가 문장을 쪼개지 않는다' '별도로' \
   521	          'text:나머지는 별도로 README.md 에 기록했습니다.'; }
   522	# [cx] 문서가 한정 없이 "코드펜스·인라인 코드는 안 본다"고 약속했는데 형태가 좁았다.
   523	d45() { silent_case '물결 펜스 안도 스캔하지 않는다' \
   524	          'text:예시:
   525	~~~
   526	이건 범위 밖이라 그대로 뒀습니다.
   527	~~~
   528	위가 걸리는 형태다.'; }
   529	d46() { silent_case '이중 백틱 코드 span 도 스캔하지 않는다' \
   530	          'text:표지 어휘는 ``범위 밖`` 이다.'; }
   531	# [cx] 문자열 content 를 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
   532	d47() { blocked_case 'content 가 문자열인 발화도 스캔한다' '범위 밖' \
   533	          'strtext:이건 범위 밖이라 그대로 뒀습니다.'; }
   534	# [cx] **일부** 손상이 "표지 없음"으로 조용히 통과하던 경로. 전멸만 잡으면 가장 흔한
   535	# 경우를 정확히 놓친다 — 깨진 줄이 하필 자백이거나 이 턴의 프롬프트일 수 있다.
   536	d48() { openq_case '일부 줄만 깨져도 통과 + 경고' prep_partial '1줄을 파싱하지 못했습니다'; }
   537	d49() { openq_case 'message 형식이 다르면 통과 + 경고' prep_badmsg 'message 형식이'; }
   538	d50() { openq_case 'content 형식이 다르면 통과 + 경고' prep_badcontent 'content 형식이'; }
   539	prep_partial() {
   540	  local f="$1/partial.jsonl"
   541	  mk_transcript "$f" 'text:작업을 시작합니다.' 'broken:' 'text:이건 범위 밖이라 그대로 뒀습니다.'
   542	  printf '%s\n' "$f"
   543	}
   544	prep_badmsg()     { local f="$1/badmsg.jsonl";     mk_transcript "$f" 'badmsg:';     printf '%s\n' "$f"; }
   545	prep_badcontent() { local f="$1/badcontent.jsonl"; mk_transcript "$f" 'badcontent:'; printf '%s\n' "$f"; }
   546	
   547	# [cx] **판독 불가 경고가 감사 게이트에만 실렸다.** 앞 게이트가 먼저 막으면 그 턴에
   548	# 안 보이고, 그 플래그를 지운 다음 턴엔 조기 종료로 영영 사라진다.
   549	d51() {
   550	  local name='판독 불가 경고가 앞 게이트 메시지에도 실린다' why=''
   551	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   552	  setup_flags "$p" dualreview          # 감사 플래그를 **일부러 안 세운다**
   553	  run_stop "$p" "$p/does-not-exist.jsonl"
   554	  if   [ "$RC" -ne 2 ];                       then why="rc=$RC (기대 2)"
   555	  elif ! contains "$ERR" '듀얼 리뷰 미수행';  then why='듀얼리뷰 게이트가 막은 게 아니다'
   556	  elif ! contains "$ERR" "$TOK_NOTE";         then why='앞 게이트 메시지에 판독 불가 사유가 없다'
   557	  fi
   558	  report "$name" "$why"
   559	}
   560	
   561	# [cx] **push 미완만으로 조기 종료가 풀린 턴**은 아무것도 안 바꾼 읽기 전용 턴이다.
   562	# 거기서 결정 게이트가 돌면 "플래그가 서 있고"라는 발동 계약보다 넓어진다.
   563	d52() {
   564	  local name='push 미완만 있는 턴에는 결정 게이트가 돌지 않는다' why=''
   565	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   566	  local tp="$p/transcript.jsonl"
   567	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   568	  setup_flags "$p"                      # 플래그 0개
   569	  # 원격은 있는데 한 번도 push 되지 않은 브랜치를 만든다.
   570	  ( cd "$p" && git init -q . \
   571	      && git config user.email t@t && git config user.name t \
   572	      && git remote add origin "$p/../origin.git" \
   573	      && git commit -q --allow-empty -m x ) >/dev/null 2>&1 \
   574	    || { report "$name" '픽스처 실패: git 저장소'; return 0; }
   575	  run_stop "$p" "$tp"
   576	  if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2 — push 게이트가 막아야 한다)"
   577	  elif contains "$ERR" "$TOK_DECISION";   then why='플래그가 없는데 결정 게이트가 막았다'
   578	  elif ! contains "$ERR" '원격에 없습니다'; then why="push 게이트가 막은 게 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   579	  fi
   580	  report "$name" "$why"
   581	}
   582	
   583	# --- 실행 ----------------------------------------------------------------
   584	# 목록을 **명시적으로** 센다. 실행 수만 세면 중복 1건 + 누락 1건이 상쇄돼 초록이 된다.
   585	CASES='d01 d02 d03 d04 d05 d06 d07 d08 d09
   586	d10 d11 d12 d13 d14 d15 d16 d17 d18 d18b d18c d19 d20 d21 d22 d23 d24
   587	d25 d25b d25c d25d d25e
   588	d26 d27 d28 d29 d30 d30b
   589	d31 d32 d33 d34 d35
   590	d36 d37 d38
   591	d39 d40 d41
   592	d42 d43 d44 d45 d46 d47 d48 d49 d50 d51 d52'
   593	
   594	echo "결정 게이트 회귀 테스트"
   595	expected=0
   596	for c in $CASES; do expected=$((expected + 1)); done
   597	dupes="$(printf '%s\n' $CASES | sort | uniq -d)"
   598	if [ -n "$dupes" ]; then
   599	  echo "✗ 케이스 목록에 중복이 있습니다: $dupes" >&2; exit 1
   600	fi
   601	for c in $CASES; do
   602	  if ! type "$c" >/dev/null 2>&1; then echo "✗ 케이스 함수가 없습니다: $c" >&2; exit 1; fi
   603	  "$c"
   604	done
   605	
   606	echo
   607	if [ "$ran" -ne "$expected" ]; then
   608	  echo "✗ 실행된 케이스 수가 목록과 다릅니다: $ran (기대 $expected)" >&2
   609	  exit 1
   610	fi
   611	printf '%s개 중 %s개 통과, %s개 실패\n' "$ran" "$pass" "$fail"
   612	[ "$fail" -eq 0 ] || exit 1
   613	echo "✓ 결정 게이트 회귀 방어 유지"

2026-08-10T08:16:09.560050Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc 'tail -180 _workspace/09_codex_r2.md' in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
   436	  run_stop "$p" "$tp" "$@"
   437	  if   [ "$DID_RUN" -ne 1 ];            then why='훅을 실행하지 않았다'
   438	  elif contains "$ERR" "$TOK_DECISION"; then why='껐는데도 결정 게이트가 막았다'
   439	  fi
   440	  report "$name" "$why"
   441	}
   442	d36() { escape_case '개별 비활성으로 끌 수 있다' ECC_DISABLED_HOOKS=stop:decision; }
   443	d37() { escape_case '전체 비활성으로도 꺼진다'   HARNESS_HOOKS=off; }
   444	d38() {
   445	  # **다른 게이트 이름으로는 안 꺼진다.** 접두사·부분 일치로 꺼지면 하나를 끌 때 옆의
   446	  # 게이트가 같이 사라지고 아무도 모른다.
   447	  local name='다른 게이트 이름으로는 안 꺼진다' why=''
   448	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   449	  local tp="$p/transcript.jsonl"
   450	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   451	  setup_flags "$p" audit
   452	  run_stop "$p" "$tp" ECC_DISABLED_HOOKS=stop:explain
   453	  contains "$ERR" "$TOK_DECISION" || why='다른 게이트를 껐는데 결정 게이트까지 꺼졌다'
   454	  report "$name" "$why"
   455	}
   456	
   457	# ── 6. 벽돌 방지 — 같은 지점 MAX_BLOCKS 회면 통과시킨다 ──────────────
   458	# 질문 한 번이면 풀리지만, 어떤 이유로도 못 푸는 상황에서 세션이 영영 안 끝나면 안 된다.
   459	d39() {
   460	  local name='같은 지점에서 MAX_BLOCKS 회 뒤에는 통과시킨다 (벽돌 방지)' why=''
   461	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   462	  local tp="$p/transcript.jsonl"
   463	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   464	  setup_flags "$p" audit
   465	  local i seen_block=0
   466	  for i in 1 2 3; do
   467	    run_stop "$p" "$tp"
   468	    if [ "$RC" -eq 2 ] && contains "$ERR" "$TOK_DECISION"; then seen_block=$((seen_block + 1)); fi
   469	  done
   470	  run_stop "$p" "$tp"
   471	  if   [ "$seen_block" -ne 3 ];        then why="3회 연속 차단이 아니었다 (실제 ${seen_block}회)"
   472	  elif [ "$RC" -ne 0 ];                then why="소진 후 rc=$RC (기대 0)"
   473	  elif ! contains "$OUT" "$TOK_BRICK"; then why="소진 통과인데 경고가 없다: $(printf '%s' "$OUT" | head -c 100)"
   474	  fi
   475	  report "$name" "$why"
   476	}
   477	d40() {
   478	  # **진전하면 예산이 리셋된다.** 질문해서 결정 게이트를 푼 뒤 감사 게이트로 넘어가는 것은
   479	  # 진전이므로, 앞서 쓴 차단 횟수가 뒤 게이트의 예산을 갉아먹으면 안 된다.
   480	  local name='질문해서 풀면 뒤 게이트의 예산이 리셋된다' why=''
   481	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   482	  local blocked="$p/blocked.jsonl" asked="$p/asked.jsonl"
   483	  mk_transcript "$blocked" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   484	  mk_transcript "$asked"   'text:이건 범위 밖이라 그대로 뒀습니다.' 'ask'
   485	  setup_flags "$p" audit
   486	  local i
   487	  for i in 1 2 3; do run_stop "$p" "$blocked"; done
   488	  run_stop "$p" "$asked"
   489	  if   [ "$RC" -ne 2 ];                then why="rc=$RC (기대 2 — 감사 게이트가 살아 있어야 한다)"
   490	  elif ! contains "$ERR" "$TOK_AUDIT"; then why="감사 게이트가 예산 소진으로 사라졌다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   491	  fi
   492	  report "$name" "$why"
   493	}
   494	
   495	# ── 7. 순서 계약 — 결정 게이트가 다른 게이트보다 앞이다 ──────────────
   496	# 질문의 답이 코드를 바꿀 수 있으므로 리뷰·설명·감사에 노력을 쓰기 전에 물어야 한다.
   497	d41() {
   498	  local name='듀얼리뷰·설명·감사보다 먼저 말한다' why=''
   499	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   500	  local tp="$p/transcript.jsonl"
   501	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   502	  setup_flags "$p" audit explain dualreview
   503	  run_stop "$p" "$tp"
   504	  if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2)"
   505	  elif ! contains "$ERR" "$TOK_DECISION"; then why="다른 게이트가 먼저 말했다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   506	  fi
   507	  report "$name" "$why"
   508	}
   509	
   510	# ── 8. 듀얼 검수 1라운드 반영분 ([cx] 지적) ──────────────────────────
   511	# 고침의 실측과 회귀 방어는 다른 일이다. 고쳤으면 "이 줄을 지우면 무엇이 빨개지나"에
   512	# 답이 있어야 한다 — 아래가 그 답이다.
   513	
   514	# [cx] **"묻지 않았다"가 질문 신호에 걸려 제외됐다** — 겨누는 문장 자체가 빠져나갔다.
   515	d42() { blocked_case '"물어보지 않고 …했습니다" 를 막는다' '제 판단으로' \
   516	          'text:사용자에게 물어보지 않고 제 판단으로 진행했습니다.'; }
   517	d43() { blocked_case '"확인하지 않고 …했습니다" 를 막는다' '가정하여' \
   518	          'text:사용자 의견을 확인하지 않고 가정하여 구현했습니다.'; }
   519	# [cx] 마침표를 무조건 종결로 보면 파일명이 문장을 쪼개 **표지와 종결이 갈린다**.
   520	d44() { blocked_case '파일명 속 마침표가 문장을 쪼개지 않는다' '별도로' \
   521	          'text:나머지는 별도로 README.md 에 기록했습니다.'; }
   522	# [cx] 문서가 한정 없이 "코드펜스·인라인 코드는 안 본다"고 약속했는데 형태가 좁았다.
   523	d45() { silent_case '물결 펜스 안도 스캔하지 않는다' \
   524	          'text:예시:
   525	~~~
   526	이건 범위 밖이라 그대로 뒀습니다.
   527	~~~
   528	위가 걸리는 형태다.'; }
   529	d46() { silent_case '이중 백틱 코드 span 도 스캔하지 않는다' \
   530	          'text:표지 어휘는 ``범위 밖`` 이다.'; }
   531	# [cx] 문자열 content 를 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
   532	d47() { blocked_case 'content 가 문자열인 발화도 스캔한다' '범위 밖' \
   533	          'strtext:이건 범위 밖이라 그대로 뒀습니다.'; }
   534	# [cx] **일부** 손상이 "표지 없음"으로 조용히 통과하던 경로. 전멸만 잡으면 가장 흔한
   535	# 경우를 정확히 놓친다 — 깨진 줄이 하필 자백이거나 이 턴의 프롬프트일 수 있다.
   536	d48() { openq_case '일부 줄만 깨져도 통과 + 경고' prep_partial '1줄을 파싱하지 못했습니다'; }
   537	d49() { openq_case 'message 형식이 다르면 통과 + 경고' prep_badmsg 'message 형식이'; }
   538	d50() { openq_case 'content 형식이 다르면 통과 + 경고' prep_badcontent 'content 형식이'; }
   539	prep_partial() {
   540	  local f="$1/partial.jsonl"
   541	  mk_transcript "$f" 'text:작업을 시작합니다.' 'broken:' 'text:이건 범위 밖이라 그대로 뒀습니다.'
   542	  printf '%s\n' "$f"
   543	}
   544	prep_badmsg()     { local f="$1/badmsg.jsonl";     mk_transcript "$f" 'badmsg:';     printf '%s\n' "$f"; }
   545	prep_badcontent() { local f="$1/badcontent.jsonl"; mk_transcript "$f" 'badcontent:'; printf '%s\n' "$f"; }
   546	
   547	# [cx] **판독 불가 경고가 감사 게이트에만 실렸다.** 앞 게이트가 먼저 막으면 그 턴에
   548	# 안 보이고, 그 플래그를 지운 다음 턴엔 조기 종료로 영영 사라진다.
   549	d51() {
   550	  local name='판독 불가 경고가 앞 게이트 메시지에도 실린다' why=''
   551	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   552	  setup_flags "$p" dualreview          # 감사 플래그를 **일부러 안 세운다**
   553	  run_stop "$p" "$p/does-not-exist.jsonl"
   554	  if   [ "$RC" -ne 2 ];                       then why="rc=$RC (기대 2)"
   555	  elif ! contains "$ERR" '듀얼 리뷰 미수행';  then why='듀얼리뷰 게이트가 막은 게 아니다'
   556	  elif ! contains "$ERR" "$TOK_NOTE";         then why='앞 게이트 메시지에 판독 불가 사유가 없다'
   557	  fi
   558	  report "$name" "$why"
   559	}
   560	
   561	# [cx] **push 미완만으로 조기 종료가 풀린 턴**은 아무것도 안 바꾼 읽기 전용 턴이다.
   562	# 거기서 결정 게이트가 돌면 "플래그가 서 있고"라는 발동 계약보다 넓어진다.
   563	d52() {
   564	  local name='push 미완만 있는 턴에는 결정 게이트가 돌지 않는다' why=''
   565	  local p; p="$(new_project '')" || { report "$name" '픽스처 실패'; return 0; }
   566	  local tp="$p/transcript.jsonl"
   567	  mk_transcript "$tp" 'text:이건 범위 밖이라 그대로 뒀습니다.'
   568	  setup_flags "$p"                      # 플래그 0개
   569	  # 원격은 있는데 한 번도 push 되지 않은 브랜치를 만든다.
   570	  ( cd "$p" && git init -q . \
   571	      && git config user.email t@t && git config user.name t \
   572	      && git remote add origin "$p/../origin.git" \
   573	      && git commit -q --allow-empty -m x ) >/dev/null 2>&1 \
   574	    || { report "$name" '픽스처 실패: git 저장소'; return 0; }
   575	  run_stop "$p" "$tp"
   576	  if   [ "$RC" -ne 2 ];                   then why="rc=$RC (기대 2 — push 게이트가 막아야 한다)"
   577	  elif contains "$ERR" "$TOK_DECISION";   then why='플래그가 없는데 결정 게이트가 막았다'
   578	  elif ! contains "$ERR" '원격에 없습니다'; then why="push 게이트가 막은 게 아니다: $(printf '%s' "$ERR" | head -1 | head -c 90)"
   579	  fi
   580	  report "$name" "$why"
   581	}
   582	
   583	# --- 실행 ----------------------------------------------------------------
   584	# 목록을 **명시적으로** 센다. 실행 수만 세면 중복 1건 + 누락 1건이 상쇄돼 초록이 된다.
   585	CASES='d01 d02 d03 d04 d05 d06 d07 d08 d09
   586	d10 d11 d12 d13 d14 d15 d16 d17 d18 d18b d18c d19 d20 d21 d22 d23 d24
   587	d25 d25b d25c d25d d25e
   588	d26 d27 d28 d29 d30 d30b
   589	d31 d32 d33 d34 d35
   590	d36 d37 d38
   591	d39 d40 d41
   592	d42 d43 d44 d45 d46 d47 d48 d49 d50 d51 d52'
   593	
   594	echo "결정 게이트 회귀 테스트"
   595	expected=0
   596	for c in $CASES; do expected=$((expected + 1)); done
   597	dupes="$(printf '%s\n' $CASES | sort | uniq -d)"
   598	if [ -n "$dupes" ]; then
   599	  echo "✗ 케이스 목록에 중복이 있습니다: $dupes" >&2; exit 1
   600	fi
   601	for c in $CASES; do
   602	  if ! type "$c" >/dev/null 2>&1; then echo "✗ 케이스 함수가 없습니다: $c" >&2; exit 1; fi
   603	  "$c"
   604	done
   605	
   606	echo
   607	if [ "$ran" -ne "$expected" ]; then
   608	  echo "✗ 실행된 케이스 수가 목록과 다릅니다: $ran (기대 $expected)" >&2
   609	  exit 1
   610	fi
   611	printf '%s개 중 %s개 통과, %s개 실패\n' "$ran" "$pass" "$fail"
   612	[ "$fail" -eq 0 ] || exit 1
   613	echo "✓ 결정 게이트 회귀 방어 유지"

2026-08-10T08:16:09.560050Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5

2026-08-10T08:16:14.757750Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "nl -ba docs/decisions/2026-08-10-decision-gate.md
nl -ba docs/usage.md | sed -n '1,180p'
nl -ba _workspace/mutate-decision-gate.sh | sed -n '1,420p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
     1	# ADR-0012: 게이트가 대화를 읽는다 — 자백은 있는데 질문이 없으면 막는다
     2	
     3	**Date**: 2026-08-10
     4	**Status**: accepted
     5	**Deciders**: 김태윤(요구·판단·확정 3건), Claude(설계·실측)
     6	
     7	---
     8	
     9	## Context
    10	
    11	[ADR-0011](2026-08-10-self-discipline-gates.md)이 게이트 둘을 에이전트 자신에게 겨눴고, **가장 큰 공백을 열어 둔 채 닫았다**:
    12	
    13	> **"혼자 정하고 보고서에 한 줄 적는" 부류는 아직 안 막혔다.** 그건 도구 호출이 아니라 문장이라 어떤 PreToolUse 훅도 못 본다.
    14	
    15	그 부류가 무엇인지는 실측으로 남아 있다. ADR-0006 이행 세션에서 Stop 훅이 세 번 막았고 세 번 다 따랐는데, 게이트가 없는 자리에서는 전부 혼자 정했다 — 기존 설정의 동작을 바꾸면서 묻지 않았고, 기록된 사용자 선호와 어긋난 상태를 발견하고 넘겼고, 다른 훅이 26번 막는 동안 선택지를 주지 않고 보고만 했다.
    16	
    17	**승인 모드는 이걸 대체하지 못한다.** 승인창은 *한 일*에만 뜬다. 안 한 일(질문)은 원리적으로 안 잡힌다. 같은 세션에서 다른 훅이 26번 승인을 요구했는데 혼자 결정하는 것은 **한 번도** 막지 못했다.
    18	
    19	## Decision
    20	
    21	**Stop 훅이 이 턴의 대화 기록을 직접 읽어 판정한다.**
    22	
    23	```
    24	코드/결정 변경 플래그가 서 있고
    25	  AND 이 턴에 AskUserQuestion 이 0회이고
    26	  AND 발화에 결정 표지 어휘를 담은 서술형 문장이 있으면
    27	→ 턴 종료 차단 + 걸린 문장을 목록으로 출력
    28	```
    29	
    30	**표지 어휘**(사용자가 지정): 공시하고 · 범위 밖 · 별도로 · 그대로 뒀 · 제 판단으로 · 가정하고 · 수용된 한계 · 트레이드오프 · 안 했습니다.
    31	
    32	이 조합이 강한 이유는 저 말들이 **"물어봤어야 할 것을 혼자 정했다"를 자백할 때만** 나온다는 것이다. 자백은 있는데 질문이 0회면 그 자체가 위반이다. 그리고 **질문 한 번이면 풀린다** — 세션이 벽돌이 되지 않는다.
    33	
    34	### ① 위양성이 여기서는 위음성만큼 비싸다
    35	
    36	이 저장소의 다른 검사기들은 전부 위양성 쪽으로 기운다(`check-layer-boundary` · `guard-hook-disable`). *"위양성은 메시지 한 번이 비용이고 위음성은 방어가 꺼진 걸 아무도 모르는 것이 비용"* 이기 때문이다.
    37	
    38	**이 게이트는 그 계산이 다르다.** 위양성의 비용이 메시지 한 번이 아니라 **사용자에게 가는 불필요한 질문**이고, 그게 반복되면 질문이 소음이 되고, 소음이 되면 **진짜 질문도 무시된다.** 게이트가 스스로를 무력화하는 경로다.
    39	
    40	그리고 위양성의 가장 큰 원천이 **자기참조**다 — 이 게이트의 훅·테스트·이 ADR 이 전부 그 어휘를 데이터로 품는다. 어휘만 보면 **이 게이트를 유지보수하는 작업 자체가 매번 걸리고**, 그러면 사람이 게이트를 끈다. 꺼진 게이트는 없는 게이트다.
    41	
    42	그래서 좁히는 장치 셋을 둔다:
    43	
    44	1. **구조적 제외** — 코드펜스 · 인라인 코드 · 인용줄 · 따옴표로 감싼 부분은 안 본다. 어휘를 인용부호로 감싸 언급하는 것은 문서·설명의 정상 형태다
    45	2. **질문 신호 제외** — 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다
    46	3. **서술형 종결 요구** — 단정으로 끝나야 "내가 그렇게 했다"이다
    47	
    48	그리고 **도구 입력을 보지 않는다(발화 텍스트만 본다).** 이 패턴이 적힌 파일을 쓰는 것 자체는 결정이 아니므로 자기참조 폭발이 **원천에서** 없어진다. 사고 블록도 안 본다(저울질은 통보가 아니다). 서브에이전트 발화도 뺀다(서브에이전트는 사용자에게 물을 수 없다).
    49	
    50	**대가는 위음성 증가다.** 표현을 조금 바꾸면 빠져나간다. 그럼에도 값을 하는 이유는 겨누는 것이 적대적 회피가 아니라 **무의식적 습관**이기 때문이다 — `guard-hook-disable` 이 "막힌 에이전트의 직진 충동"을 겨눈 것과 같은 판단 구조다.
    51	
    52	### ①-1 어휘는 **표본**이지 분류법이 아니다 (2026-08-10 사용자 지적)
    53	
    54	저 9개는 원리에서 유도한 것이 아니라 **한 세션에서 LLM 이 실제로 쓴 문장을 관찰해 뽑은 것**이다. 사용자가 이 점을 짚었다 — *"어차피 내가 쓴 게 아니고 LLM 이 내가 말할 걸 정리해서 쓰는 것이라 그것에서 비롯한 문제가 또 발생할 것 같은데."*
    55	
    56	맞는 지적이고, 결론을 바꾼다. **목록을 좁히지 않는다.** 좁히는 규칙도 결국 같은 출처의 추측이라 추측 위에 추측을 쌓는 일이 된다. 검수가 "`별도로`·`트레이드오프` 는 단순 기술 서술에도 나온다"고 정당하게 지적했지만(→ Consequences 의 위양성 항목), 그 대응으로 어휘에 조건을 붙이는 것은 문제를 줄이는 게 아니라 **다른 자리로 옮기는 것**이다.
    57	
    58	대신 **주장을 사실에 맞춘다**:
    59	
    60	- 이것은 **관찰된 표현에 맞춘 과속방지턱**이지 "말하지 않은 결정"의 탐지기가 아니다
    61	- **영어 발화는 하나도 못 본다.** 표지가 전부 한국어다 — 커버리지 0인 축이 통째로 있다
    62	- 목록은 **새는 것을 실제로 본 뒤에만** 늘린다. 이 저장소가 게이트를 만드는 방식 그대로다(*"선제 방어는 하지 않는다 — 실제로 겪은 뒤에 강제를 추가한다"*)
    63	
    64	**어휘를 사용자 슬롯으로 빼지 않는다.** 언어·모델마다 다를 테니 그럴싸하지만, 실제로 새는 것을 보기 전에 설정을 늘리는 것은 같은 YAGNI 규칙에 걸린다. 새는 게 관측되면 그때 뺀다.
    65	
    66	### ② fail-open 은 판독 불가 하나이고, 소리를 낸다
    67	
    68	이 저장소의 원칙은 *"검사기의 유일한 치명 결함은 위음성"* 이고 애매하면 전부 fail-closed 다. **이 게이트에 예외를 하나 둔다.**
    69	
    70	대화 기록의 형식은 **하네스가 소유하지 않는다** — 도구 제공자가 정하고 예고 없이 바뀐다. 형식이 바뀌었다고 차단하면 **그 세션 안에 고칠 방법이 없다**: 기록을 고칠 수는 없으므로 어떤 행동으로도 게이트가 안 풀리고, 세션이 통째로 벽돌이 된다. 다른 게이트는 전부 "무언가를 하면 풀리는" 구조라 이 문제가 없다.
    71	
    72	**조건은 경고를 삼키지 않는 것이다.** 판독에 실패하면 사유가 **막는 게이트가 무엇이든 그 메시지에** 실린다. 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다.
    73	
    74	**초안은 이 약속을 지키지 못했고, 검수가 그것을 잡았다.** 처음에는 *"rc=2 가 유일한 fail-open"* 이라고 적었는데 사실이 아니었다 — 부분 손상·처리 못 한 예외·`python3` 부재가 전부 "표지 없음"과 **같은 종료 코드**로 나갔다. 고친 뒤의 계약은 이렇다:
    75	
    76	```
    77	0  차단     2  판독 불가(사유 있음)     3  차단 불필요     그 밖  → 판독 불가로 취급
    78	```
    79	
    80	정상 통과에 흔한 코드(1)를 **주지 않는 것**이 핵심이다. 그래야 크래시가 정상 통과로 위장되지 않는다. 그리고 사유는 **다섯 게이트 전부**에 싣는다 — 감사 게이트에만 실으면 앞 게이트가 먼저 막은 턴에 안 보이고, 그 플래그를 지운 다음 턴에는 조기 종료로 영영 사라진다.
    81	
    82	### ③ 사용자 확정 3건 (2026-08-10)
    83	
    84	| 물은 것 | 확정 | 근거 |
    85	|---|---|---|
    86	| 탈출구를 둘까 | **둔다** (`ECC_DISABLED_HOOKS=stop:decision`) | 위양성이 구조적으로 나므로 사용자가 즉시 뺄 수 있어야 한다. 끄는 대입 자체는 `guard-hook-disable` 이 한 번 세운다 |
    87	| 어느 턴에서 도나 | **코드 + 결정 문서 + 설계 산출물** | 표지 어휘가 가장 자주 나오는 자리가 결정 문서를 쓰는 턴이다 |
    88	| 패턴을 얼마나 좁히나 | **좁힌 서술형 + 구조적 제외** | 자기참조 폭발을 막는 유일한 길 |
    89	
    90	**탈출구 유무가 `guard-hook-disable` 과 갈리는 이유**를 적어 둔다. 그쪽은 *"탈출구가 있으면 그것으로 나머지를 전부 끌 수 있어서"* 두지 않았다. 이쪽은 그렇지 않다 — 이 게이트를 꺼도 나머지 게이트는 그대로 살아 있고, 반대로 위양성으로 막혔을 때 사용자가 뺄 수단이 없으면 세 번 헛돌아야 한다. **비대칭이 다르면 답도 다르다.**
    91	
    92	### ④ 순서 — 다른 게이트보다 앞이다
    93	
    94	질문의 답이 코드를 바꿀 수 있으므로 리뷰·설명·감사에 노력을 쓰기 전에 묻는 편이 싸다.
    95	
    96	`stop:push` 의 "탐지가 조기 종료보다 앞"과는 성격이 다르다. 그건 **정확성** 문제였다(뒤에 두면 게이트가 영영 안 돈다). 이건 **비용** 문제다 — 대화 기록은 이미 다 쓰였고 게이트 순서가 그 내용을 바꾸지 않는다. 그래도 계약으로 고정하고, 지우는 변이가 아니라 **옮기는 변이**로 잰다(지우면 "게이트 없음"을 재는 것이지 "순서가 틀림"을 재는 것이 아니다).
    97	
    98	## Alternatives Considered
    99	
   100	### A. 단순 어휘 목록, 위양성 쪽으로 기운다 (집안 표준)
   101	- **Pros**: 단순하다. 위음성이 거의 없다. 형제 검사기들과 판단이 일관된다
   102	- **Cons**: 자기참조가 폭발한다 — 이 게이트를 손대는 모든 작업, 이 ADR 을 쓰는 턴, 회수 정책 ADR 을 쓰는 턴이 전부 걸린다
   103	- **Why not**: 그 상태의 종착지는 **사람이 게이트를 끄는 것**이다. 다른 검사기는 CI 에서 한 번 걸리고 끝이지만 이건 대화마다 걸린다
   104	
   105	### B. 산문 질문도 질문으로 센다
   106	- **Pros**: "이대로 갈까요?"로 끝나는 정직한 보고가 안 막힌다
   107	- **Cons**: 게이트가 물음표 하나로 뚫린다. 그리고 막으려는 것이 정확히 **"보고서에 한 줄 적고 넘어가기"** 인데, 그 한 줄 끝에 물음표를 붙이는 것은 같은 행동이다
   108	- **Why not**: 사용자가 도구 호출을 기준으로 못박았다 — *"보고서에 적는 것은 묻는 것이 아니다"*
   109	
   110	### C. 탈출구를 두지 않는다 (`guard-hook-disable` 방식)
   111	- **Pros**: 막힌 에이전트가 못 끈다
   112	- **Cons**: 사용자도 못 끈다. 구조적 위양성이 나는 게이트에서 이건 비싸다
   113	- **Why not**: ③의 비대칭 논거. 이 게이트를 꺼도 나머지는 산다
   114	
   115	### D. 플래그와 무관하게 항상 검사한다
   116	- **Pros**: 순수 질의응답에서 혼자 정하는 것도 잡는다
   117	- **Cons**: 아무것도 안 바꾼 턴까지 막아 대화를 방해한다
   118	- **Why not**: 사용자 기각
   119	
   120	## Consequences
   121	
   122	### Positive
   123	- **"혼자 정하고 한 줄 적는" 부류가 처음으로 기계에 걸린다.** ADR-0011 이 남긴 가장 큰 공백이 닫힌다
   124	- 걸린 문장이 메시지에 실리므로 **무엇을 물어야 하는지**가 화면에 뜬다. 안 실으면 "일단 아무거나 물어서 풀자"가 되어 게이트가 의식(儀式)이 된다
   125	- 질문 한 번이면 풀린다 — 비용이 낮아 게이트를 끌 동기가 약하다
   126	
   127	### Negative
   128	- **위음성이 있다.** 표현을 바꾸면 빠져나간다. 좁힌 대가이고, 겨누는 것이 적대적 회피가 아니라 습관이라 감수한다
   129	- **영어 발화는 커버리지 0이다.** 표지가 전부 한국어다. 축 하나가 통째로 비어 있다
   130	- **위양성이 남는다.** 표지 어휘는 자백에만 나오지 않는다 — 검수가 실례를 댔다: *"기존 스캐너는 범위 밖 입력을 거부합니다"* · *"변이 테스트는 별도로 실행됩니다"* · *"이 트레이드오프는 ADR 에 설명되어 있습니다"*. 전부 결정 통보가 아닌데 걸린다. **고치지 않기로 했다**(①-1) — 인용부호나 백틱으로 감싸면 빠지고, 질문 한 번이면 풀린다
   131	- **판독 불가는 통과다.** 대화 기록 형식이 바뀌면 게이트가 사라진다 — 통과하되 사유를 다섯 게이트 메시지에 싣는다
   132	- 대화 기록 형식에 **의존이 하나 생겼다.** 하네스가 소유하지 않는 형식이고, 바뀌면 위 경로로 떨어진다
   133	- **Stop 훅이 매 턴 대화 기록 전체를 읽는다.** 긴 세션에서 비용이 는다(현재 실측 범위에서는 문제없음)
   134	
   135	### 공시된 한계 — 지식 게이트를 끄면 결정 문서 턴이 빠진다
   136	`HARNESS_KNOWLEDGE_GATE` 를 리터럴로 비운 환경에서는 **결정 문서만** 고친 턴이 조기 종료에 걸려 결정 게이트까지 도달하지 못한다. 기본값이 켜짐이라 기본 구성에서는 정상 발동한다.
   137	
   138	**고치지 않는다(사용자 확정).** 조기 종료가 지식 플래그를 게이트 켜짐일 때만 세는 것은 *"게이트를 껐는데 예전에 남은 플래그가 읽기 전용 턴의 조기 종료를 막는"* 문제를 막으려고 넣은 것이다. 결정 게이트를 위해 그걸 되돌리면 알려진 버그 부류가 되살아난다. **한계 자체를 케이스(d30b)로 붙들었다** — 이 동작이 바뀌면 그 케이스가 빨개진다.
   139	
   140	## 기계적 장치
   141	
   142	`tests/decision-gate.test.sh` **59건** + CI 스텝. 차단 · 위양성 · 발동조건 · 판독불가 8 · 탈출구 3 · 벽돌방지 2 · 순서 1 · 턴경계 5.
   143	
   144	**rc 만으로 판정하지 않는다.** 결정 게이트가 통과해도 뒤의 감사 게이트가 같은 rc=2 를 내므로, 어느 게이트가 말했는지는 **메시지로만** 갈린다. 그리고 통과를 기대하는 케이스는 감사 게이트가 **실제로 말했는지**를 함께 요구한다 — 안 하면 훅이 앞에서 죽어도 초록이 난다.
   145	
   146	`_workspace/mutate-decision-gate.sh` **변이 35건 전건 적색.** 방어 제거(위음성) · 좁히는 장치 제거(위양성) · 턴 경계 흐리기 · fail-open 침묵화 · 게이트 이동 · 검수 반영분.
   147	
   148	**공시된 측정 공백:** 호출부의 "모르는 rc" 처리만 지우는 변이는 **원리적으로 초록**이다 — 정상 동작에서 그 가지에 도달하는 입력이 없다(`python3` 를 없애면 `json_get` 이 먼저 죽어 경로가 비고, 그러면 다른 가지로 빠진다). 대신 *정상 경로가 모르는 rc 를 내게 하는* 변이가 그 가지의 생존을 증명한다. 두 항목이 짝이고 하나만 보면 오판한다.
   149	
   150	### 변이가 잡은 것 둘 — 통과 개수로는 안 보였다
   151	
   152	1. **질문 신호 판정이 죽어 있었다.** 위양성 케이스들의 종결이 "…까요/…세요"라 **서술형 요구에서 이미 걸러져 질문 판정에 도달조차 하지 않았다.** 판정 *순서*가 케이스를 무력화한 것이라 어휘를 아무리 늘려도 안 잡힌다. 서술형으로 끝나면서 묻는 문장을 케이스로 넣어 살렸다.
   153	2. **턴 경계의 두 판정이 서로를 가렸다.** 실제 기록은 상단 `toolUseResult` 와 `tool_result` 블록을 **항상 함께** 갖고 있다(실측 69/69). 그래서 한쪽을 지워도 다른 쪽이 막아 준다. 표식이 하나뿐인 픽스처를 만들어 각각을 독립적으로 지키게 했다.
   154	
   155	앞은 **판정 순서**가, 뒤는 **데이터의 중복**이 방어를 가린 사례다. 둘 다 "케이스가 통과한다"가 "그 방어가 지켜진다"를 뜻하지 않는 부류이고, 변이 없이는 원리적으로 안 보인다.
   156	
   157	3차로 같은 부류가 하나 더 나왔다 — 검수 반영으로 **모르는 rc 를 판독 불가로 취급**하게 만들자, 그 catch-all 이 *개별* 판독 불가 검사들을 가려버렸다(그 검사를 지워도 크래시가 catch-all 에 걸려 경고가 나왔다). 판독 불가 케이스가 **사유 조각까지** 요구하게 고쳐서 각각을 다시 격리했다. **새 방어가 옛 방어를 가리는 것**도 이 부류다.
   158	
   159	### 검수가 잡은 것 — 공시가 사실이 아니었다
   160	
   161	codex 독립 검수 1라운드(판정 보류, HIGH 5 · MEDIUM 3 · LOW 1)가 이 ADR 초안의 **핵심 주장 하나를 반증했다.** *"rc=2 가 유일한 fail-open"* 이 사실이 아니었고, 조용히 통과하는 경로가 넷 더 있었다(부분 손상 · 모르는 rc · truthy 비-dict `message` · 문자열 `content`). 게다가 경고 자체가 감사 게이트에만 실려 **앞 게이트가 먼저 막으면 사라졌다** — 경고를 삼키지 않는 것이 이 fail-open 의 유일한 조건인데 그게 안 지켜지고 있었다.
   162	
   163	가장 값진 지적은 **겨누는 문장 자체가 빠져나간 것**이었다: *"사용자에게 물어보지 않고 제 판단으로 진행했습니다"* 가 `물어` 때문에 질문으로 오인돼 통과했다. **부정이 붙으면 물음이 아니라 자백이다.**
   164	
   165	*거짓 공시는 남은 결함보다 나쁘다* 를 이 ADR 이 스스로 어겼고, 독립 컨텍스트가 그것을 잡았다.
   166	
   167	## 관련
   168	- [ADR-0011](2026-08-10-self-discipline-gates.md) — 이 게이트를 후속으로 남긴 곳
   169	- [ADR-0008](2026-08-06-knowledge-gate-default-on.md) — 게이트 기본값과 판독 계약
   170	- [ADR-0007](2026-08-06-gate-scope-by-file-identity.md) — 어느 편집이 게이트 대상인가
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
    64	| guard-hook-disable | Bash 실행 전 | 에이전트가 `HARNESS_HOOKS`·`ECC_DISABLED_HOOKS`·`ECC_GATEGUARD` 를 끄려 할 때 한 번 세운다. **과속방지턱이지 방벽이 아니다** — 아래 참조. 탈출구가 **없다** |
    65	| guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
    66	| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (코드는 4종 전부 · 설계·계획 산출물은 듀얼리뷰+지식 · 결정 문서는 지식만). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
    67	| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → **혼자 정하지 않았나** → codex 듀얼리뷰 → change-explainer → **지식 저장소 반영** → **push 미완** → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
    68	
    69	**지식 저장소 게이트가 아는 것은 계약 하나뿐이다** — "지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다." **어디에 어떤 구조로 반영하는지는 하네스가 모른다.** 그건 사용자 층 설정(전역 `CLAUDE.md` 등)이 답하고, 하네스에는 켜짐/꺼짐 1비트만 있다. 그래서 지식 저장소를 바꿔도 하네스는 고치지 않고, 아예 안 쓰는 프로젝트에서도 그대로 돈다.
    70	
    71	**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:decision`(결정 게이트만) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) / `stop:push`(push 게이트만) 나열.
    72	**`guard-hook-disable` 은 과속방지턱이지 보안 경계가 아니다.** 판정이 정규식 하나라 셸을 해석하지 못한다 — `read`+`export`, 따옴표로 쪼갠 `env 'X''=off'`, 변수 조립, `eval`, 생성한 스크립트 실행은 전부 통과한다(실측). 그럼에도 값을 하는 이유는 막으려는 것이 적대적 공격자가 아니라 **막힌 에이전트의 직진 충동**이고, 그건 `HARNESS_HOOKS=off ...` 라는 직진형으로 나오기 때문이다. 제대로 막으려면 셸 파서가 필요한데, 반쯤 만든 셸 파서는 안 만든 것보다 나쁘다(막힌다고 믿게 하면서 안 막는다 — 이 저장소가 `harness.env` 판독기에서 겪은 늪).
    73	
    74	**그래서 위양성 쪽으로 기운다.** 실행 구문과 인용문을 구분하지 않아 `git grep 'HARNESS_HOOKS=off'` 같은 정당한 검색도 막힌다. 의도된 선택이다 — 따옴표 안을 건너뛰면 위양성은 사라지지만 `bash -c 'HARNESS_HOOKS=off ...'` 가 뚫린다. 둘은 문자열로 구별되지 않는 같은 모호성의 양면이고, 위양성은 메시지 한 번이 비용이지만 위음성은 **게이트가 꺼진 걸 아무도 모르는** 것이 비용이다. 차단 메시지가 위양성일 때의 대안(패턴 쪼개기·Write 도구 사용)을 함께 안내한다.
    75	
    76	**그리고 환경변수로 끌 수 없다.** 그 탈출구가 있으면 에이전트가 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다. 사용자가 정말 끄려면 셸에서 직접 `export` 하고 세션을 새로 띄우거나 `settings.json` 배선을 지운다 — 둘 다 사람이 하는 행위다.
    77	
    78	**결정 게이트가 있는 이유:** 나머지 게이트는 전부 **산출물**을 본다("코드가 검증됐나", "설명이 나왔나"). 그런데 실측된 실패의 대부분은 산출물이 아니라 **행동**이었다 — 게이트가 막을 때는 세 번 다 따랐으면서, 게이트가 없는 자리에서는 전부 혼자 정하고 보고서에 한 줄 적었다. 그 "한 줄"은 도구 호출이 아니라 문장이라 승인창도 안 뜬다. 그래서 이 게이트만 **대화 기록을 직접 읽는다**: 코드·결정이 바뀐 턴에 결정 표지 어휘를 담은 서술형 문장이 있는데 `AskUserQuestion` 이 0회면 막고, 걸린 문장을 목록으로 보여준다. **질문 한 번이면 풀린다.**
    79	
    80	**여기서는 위양성도 위음성만큼 비싸다.** 다른 검사기와 판단이 갈리는 유일한 자리다 — 위양성의 비용이 메시지 한 번이 아니라 사용자에게 가는 **불필요한 질문**이고, 그게 반복되면 질문이 소음이 되어 진짜 질문까지 무시된다. 게다가 이 게이트의 훅·테스트·ADR 이 그 어휘를 데이터로 품어서, 어휘만 보면 **게이트를 유지보수하는 작업 자체가 매번 걸린다.** 그래서 좁힌다: 코드펜스·인라인 코드·인용줄·따옴표 안은 안 보고, 같은 문장에 물음이 있으면 세지 않고, 서술형 단정으로 끝나야 센다. **도구 입력도 안 본다**(발화 텍스트만) — 그 어휘가 적힌 파일을 쓰는 것 자체는 결정이 아니다. 사고 블록과 서브에이전트 발화도 뺀다.
    81	
    82	*걸렸는데 결정이 아니라면* 백틱이나 따옴표로 감싸면 빠진다. 그래도 걸리면 사용자에게 알리고 지시를 받는다.
    83	
    84	**이건 탐지기가 아니라 과속방지턱이다.** 표지 어휘는 원리에서 유도한 분류법이 아니라 **한 세션에서 실제로 쓰인 문장을 관찰해 뽑은 표본**이다. 그래서:
    85	
    86	- 표현을 조금 바꾸면 **빠져나간다**(위음성). 겨누는 것이 적대적 회피가 아니라 무의식적 습관이라 그래도 실효가 남는다
    87	- **영어 발화는 하나도 못 본다.** 표지가 전부 한국어다 — 축 하나가 통째로 비어 있다
    88	- 반대로 그 어휘는 자백에만 나오지도 않는다. `변이 테스트는 별도로 실행됩니다` 같은 **단순 기술 서술도 걸린다.** 어휘에 조건을 덧붙여 좁히지 **않기로 했다** — 그 조건도 같은 출처의 추측이라 문제를 없애는 게 아니라 옮기는 것이기 때문이다
    89	- 목록은 **새는 것을 실제로 본 뒤에만** 늘린다. 이 저장소가 게이트를 만드는 방식 그대로다
    90	
    91	**대화 기록을 못 읽으면 막지 않고 통과시킨다 — 이 하네스에서 유일한 fail-open 이다.** 기록 형식은 하네스가 소유하지 않아 예고 없이 바뀔 수 있는데, 그때 차단하면 **그 세션 안에 고칠 방법이 없어 통째로 벽돌이 된다**(기록을 고칠 수 없으므로 어떤 행동으로도 안 풀린다). 대신 사유가 마지막 게이트 메시지에 실린다 — 조용히 통과하면 게이트가 죽은 것을 아무도 모른다. **공시된 한계:** `HARNESS_KNOWLEDGE_GATE` 를 비운 환경에서는 결정 문서만 고친 턴이 조기 종료에 걸려 이 게이트까지 오지 않는다(기본값이 켜짐이라 기본 구성에서는 정상 발동). 자세한 근거는 [ADR-0012](decisions/2026-08-10-decision-gate.md).
    92	
    93	**push 게이트가 있는 이유:** 이 저장소는 커밋 29개를 잃은 적이 있다. 코드는 다 짜여 있었고 "아직 PR 전이니까"라며 push 를 미뤘다. 게이트는 **네트워크를 쓰지 않는다** — 로컬 remote-tracking ref 만 본다. 원격에 있는데도 ref 가 안 보이면(`remote.origin.fetch` 가 좁혀진 경우) 그 사실을 사유에 적는다. push 여부가 로컬에서 안 보이는 것 자체가 위험이기 때문이다. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
    94	
    95	### 완료 게이트 검사 범위 (mark-needs-audit)
    96	
    97	판정 **순서가 곧 계약**이다: 개행 가드 → 물리 경로 정규화 → 듀얼리뷰 판정 → 범위 판정 → 분류 → 기록.
    98	
    99	- **프로젝트 안** — `_workspace/`·`.claude/`·문서 `*.md`·`*.markdown`(대소문자 무관)는 제외. 나머지는 게이트 4종.
   100	  단 **문서 제외에는 예외가 둘** 있다(동작을 정의하는 마크다운이라 코드로 취급한다):
   101	  `.claude/` 에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`), 그리고
   102	  **프로젝트 자신이 하네스 정본일 때의 `global-agents/*.md`**. 둘 다 `*.md` 제외보다 **먼저** 판정된다.
   103	- **프로젝트 밖 + 하네스 정본 저장소**(루트에 `template/.claude/` 존재) — 저장소 **전체**를 **프로젝트와 같은 규칙으로** 검사한다. `scripts/`·`install.sh`·`global-agents/*.md` 포함(전부 하네스 동작을 정의한다). "같은 규칙"이므로 위의 제외도 **그대로** 적용된다 — 정본 저장소 안이라도 `_workspace/`·`.claude/`·순수 문서는 게이트가 서지 않는다. 지금 읽고 있는 이 파일(`docs/usage.md`)이 그 예다.
   104	- **프로젝트 밖 + 그 외** — `.claude/`에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`)만. **git 저장소가 아니어도** 발화한다.
   105	- **설계·계획 산출물**(`_workspace/00_design*.md`·`01_plan*.md`) — 위치·git 여부와 무관하게 **듀얼리뷰 + 지식** 플래그를 세운다. 설계가 나온 턴을 반영 없이 끝내면 "왜 그렇게 정했나"가 그 자리에서 사라지고, 그 근거가 정확히 이 파일들이다.
   106	- **결정 문서**(`docs/decisions/*.md`) — 문서 제외의 **예외**로 **지식** 플래그만 세운다. 코드가 아니므로 타입체크·변경설명·감사는 과하다. **공시된 한계:** 결정 문서를 이 경로 밖에 두면 게이트가 서지 않는다 — 하네스는 자기가 아는 경로만 알 수 있다.
   107	- **밖 편집은 절대경로로 기록**한다. 상대경로로 적으면 프로젝트와 외부 저장소가 `README.md` 같은 흔한 경로를 공유할 때 감사자가 프로젝트 쪽 동명 파일을 보고 통과시킨다.
   108	- 플래그를 못 쓰거나 경로에 개행이 있으면 **차단하지 않고** `systemMessage`로 알린다(PostToolUse는 항상 exit 0). git 호출이 실패했는데 조상에 `.git`이 있으면 그 사실도 알린다 — 정본 저장소가 조용히 앵커 전용으로 강등되는 것을 사람이 알 수 있게.
   109	
   110	계약의 **기계 정본**은 `tests/mark-needs-audit.cases.sh`의 판정 표이고, 케이스 수는 같은 파일의 `EXPECTED_CASES`가 강제한다. CI가 PR마다 돌린다.
   111	
   112	## 6. 트러블슈팅
   113	
   114	- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: 결정 게이트(`AskUserQuestion` 으로 실제로 묻는다 — 지울 플래그가 없다) → codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 지식 저장소 반영(`.needs-knowledge`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
   115	- **타입체크가 이상하게 실패** → `harness.env`의 명령을 셸에서 직접 실행해 확인. 도구 부재(rc=127)·타임아웃은 차단 안 하고 생략 처리된다.
   116	- **superpowers 스킬 호출 실패** → 플러그인 설치/이름 확인: `test-driven-development`·`writing-plans`·`brainstorming`·`requesting-code-review`·`verification-before-completion`·`systematic-debugging`.
   117	- **에이전트가 도메인을 무시** → 프로필 §가 비어 있지 않은지 확인. 오케스트레이터는 빈 §를 "검증 생략"으로 정직 보고한다.
   118	
   119	## 7. 하네스 진화
   120	
   121	에이전트/스킬 수정·추가는 이 repo(정본)에서 하고 커밋 → 각 프로젝트에 `sync.sh`. 구조 변경이 크면 `harness` 메타 스킬(운영/유지보수 워크플로우)을 사용. 변경 이력은 각 프로젝트 CLAUDE.md의 변경 이력 표에 기록.
   122	
   123	### 제0원칙 판정 기준을 고칠 때
   124	
   125	판정 기준(`principles.md`의 `rule:core` 블록)은 판정자 에이전트가 **자기 정의 안에 사본으로** 들고 있다. 참조만 두면 에이전트가 그 파일을 읽는다는 보장이 없어서다. 그래서 고치는 순서가 정해져 있다.
   126	
   127	1. 정본 `template/.claude/harness/principles.md`의 `rule:core` 블록을 고친다.
   128	2. 사본(`template/.claude/agents/plan-reviewer.md` 점검 항목 7)에 **그대로 복사**한다.
   129	3. 검사한다.
   130	
   131	```bash
   132	./scripts/check-rule-copies.sh
   133	```
   134	
   135	어긋나면 종료 코드 1과 함께 diff가 나오고, CI(`.github/workflows/check-rules.yml`)가 PR을 막는다. 마커 **밖**의 문맥별 설명은 동기화 대상이 아니니 파일마다 자유롭게 써도 된다 — 판정 기준만 동기화한다. 다만 마커 줄 자체는 앞뒤 공백·설명 없이 정확히 한 줄(`<!-- rule:core:start -->` / `<!-- rule:core:end -->`, CRLF 줄끝 불가)이어야 한다. 꾸미면 마커로 인정되지 않는다 — 마커를 꾸며 판정 기준을 바꿔치기하는 길을 막기 위해서다. 같은 이유로 `template/` 아래에는 심링크와 NUL 바이트를 포함한 파일(바이너리·UTF-16 등)을 둘 수 없다 — 검사기가 내용을 확인할 수 없어 낡은 사본이 조용히 배포되는 경로가 열리기 때문이다.
   136	
   137	판정자를 새로 추가해 사본이 늘면 `scripts/check-rule-copies.sh`의 `COPIES` 배열에 경로 한 줄을 추가해야 한다 — `template/` 안에 마커를 둔 채 등록하지 않으면 검사기가 종료 코드 1로 막는다. 그 경로는 반드시 `template/` **아래**여야 한다: 심링크·NUL·미등록 게이트가 전부 `template/`만 훑기 때문에, 밖을 가리키면 등록만 되고 정작 검사는 안 되는 사본이 생긴다(검사기가 이것도 종료 코드 1로 막는다). `..`나 심링크를 거쳐 밖으로 나가는 표기도 물리 경로로 풀어 같이 막는다. 경로에 개행이 들어간 파일은 아예 등록할 수 없다 — 개행은 경로 계산 과정에서 잘려 나가 바깥 파일을 안쪽으로 오인시키므로, 범위 판정 자체가 성립하지 않는다. 반대로 `COPIES`를 통째로 비워 둘 수도 없다 — 대조할 사본이 0개면 검사기가 지키는 것이 아무것도 없는데도 초록으로 보이므로, 빈 배열도 종료 코드 1로 막는다.
     1	#!/usr/bin/env bash
     2	# 변이 주입 하네스 — tests/decision-gate.test.sh 가 **실제로 무엇을 붙드는지** 잰다.
     3	#
     4	# "44건 통과"는 아무것도 증명하지 않는다. 방어를 하나씩 지우고 그 케이스가 빨개지는지
     5	# 봐야 한다. 형제 하네스(mutate-harness-env.sh)와 같은 계약을 쓴다:
     6	#   · 대상 파일에 미커밋 변경이 있으면 **거부**한다 (restore 가 그것을 지운다)
     7	#   · 동시 실행을 락으로 막는다 (돌리는 중 커밋하면 변이가 커밋된다 — 실제로 당했다)
     8	#   · 치환이 **정확히 1회** 매치할 때만 진행한다 (앵커가 밀리면 빈 변이 = 거짓 초록)
     9	#   · 복원 뒤 **해시를 대조**한다 (git status 는 stat 캐시 때문에 못 믿는다)
    10	#
    11	# 이 게이트는 위양성도 치명적이라 **양방향으로** 잰다:
    12	#   A·C·D 방어를 지우면 → 막아야 할 것을 놓친다 (위음성 검출)
    13	#   B    좁히는 장치를 지우면 → 막으면 안 될 것을 막는다 (위양성 검출)
    14	#
    15	# CI 에 넣지 않는다. 검수·감사 때 손으로 돌리는 계측 도구다.
    16	# 사용법: ./_workspace/mutate-decision-gate.sh
    17	
    18	set -uo pipefail
    19	cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
    20	
    21	COMMON='template/.claude/hooks/_common.sh'
    22	STOP='template/.claude/hooks/verify-before-stop.sh'
    23	TESTS='./tests/decision-gate.test.sh'
    24	
    25	for f in "$COMMON" "$STOP"; do
    26	  if ! git diff --quiet -- "$f" || ! git diff --cached --quiet -- "$f"; then
    27	    echo "✗ $f 에 미커밋 변경이 있습니다." >&2
    28	    echo "  이 하네스는 HEAD 로 restore 하므로 그 변경을 **지웁니다**. 먼저 커밋한 뒤 다시 재세요." >&2
    29	    exit 1
    30	  fi
    31	done
    32	
    33	LOCK="$(git rev-parse --git-dir)/mutate-decision-gate.lock"
    34	if ! mkdir "$LOCK" 2>/dev/null; then
    35	  echo "✗ 이미 다른 변이 측정이 돌고 있습니다: $LOCK" >&2
    36	  echo "  겹쳐 돌리면 주입된 변이가 커밋될 수 있습니다. 끝난 뒤 다시 재세요." >&2
    37	  echo "  (그 프로세스가 죽었다면: rmdir '$LOCK')" >&2
    38	  exit 1
    39	fi
    40	# **락만 걷어내는 트랩은 부족하다.** 측정 도중 SIGINT 로 끊기면 주입된 변이가 작업
    41	# 트리에 그대로 남고, 이 저장소는 **측정 중인 트리를 커밋해 변이가 섞여 들어간 사고를
    42	# 이미 겪었다.** 다음 실행이 dirty 검사로 거부해 주긴 하지만, 그 사이에 커밋하면 늦는다.
    43	# 대상 파일에 미커밋 변경이 없음은 위에서 이미 확인했으므로 restore 는 안전하다.
    44	cleanup() {
    45	  git restore --source=HEAD --worktree -- "$COMMON" "$STOP" 2>/dev/null
    46	  rmdir "$LOCK" 2>/dev/null
    47	}
    48	trap cleanup EXIT INT TERM
    49	
    50	restore_and_verify() {   # $1 = 파일
    51	  git restore --source=HEAD --worktree -- "$1" || { echo "✗ restore 실패: $1" >&2; exit 1; }
    52	  local have want
    53	  have="$(git hash-object "$1")"
    54	  want="$(git rev-parse "HEAD:$1")"
    55	  if [ "$have" != "$want" ]; then
    56	    echo "✗ 복원 검증 실패: $1 ($have ≠ $want) — 이후 측정은 전부 거짓입니다" >&2
    57	    exit 1
    58	  fi
    59	}
    60	
    61	# mutate <파일> <찾을 문자열> <바꿀 문자열> — 정확히 1번 매치할 때만 바꾼다.
    62	mutate() {
    63	  python3 - "$1" "$2" "$3" <<'PY'
    64	import sys, io
    65	path, old, new = sys.argv[1], sys.argv[2], sys.argv[3]
    66	s = io.open(path, encoding='utf-8').read()
    67	if s.count(old) != 1:
    68	    sys.stderr.write("  ! 변이 앵커가 %d 번 매치 (1 이어야 함): %r\n" % (s.count(old), old[:70]))
    69	    sys.exit(1)
    70	io.open(path, 'w', encoding='utf-8').write(s.replace(old, new))
    71	PY
    72	}
    73	
    74	total=0; caught=0; missed=0
    75	
    76	measure() {   # $1=이름 $2=파일 — 변이가 주입된 상태에서 재고 복원한다
    77	  local out rc nfail
    78	  out="$($TESTS 2>&1)"; rc=$?
    79	  nfail="$(printf '%s\n' "$out" | grep -c '^  ✗')"
    80	  restore_and_verify "$2"
    81	  if [ "$rc" -ne 0 ] && [ "$nfail" -gt 0 ]; then
    82	    caught=$((caught + 1))
    83	    # cut -c 를 쓰지 않는다: BSD cut 은 **바이트**로 잘라 한글 중간을 끊고, 그러면 이 로그가
    84	    # 유효한 UTF-8 이 아니게 되어 grep 이 바이너리로 취급하고 조용히 0건을 낸다(실측 적발).
    85	    printf '  ✓ %-44s 적색 %2s건 · %s\n' "$1" "$nfail" \
    86	      "$(printf '%s\n' "$out" | grep '^  ✗' | sed 's/^  ✗ //; s/ —.*//' | tr '\n' '/')"
    87	  else
    88	    missed=$((missed + 1))
    89	    printf '  ✗ %-44s **초록** — 이 방어를 지켜주는 케이스가 없다\n' "$1"
    90	  fi
    91	}
    92	
    93	run_mutation() {   # $1=이름 $2=파일 $3=찾을것 $4=바꿀것
    94	  total=$((total + 1))
    95	  if ! mutate "$2" "$3" "$4"; then
    96	    printf '  ! %-44s 변이 주입 실패 (앵커 불일치)\n' "$1"
    97	    restore_and_verify "$2"
    98	    missed=$((missed + 1))
    99	    return
   100	  fi
   101	  measure "$1" "$2"
   102	}
   103	
   104	echo '기준선 (변이 없음)'
   105	if ! $TESTS >/dev/null 2>&1; then
   106	  echo '✗ 기준선이 이미 빨간불입니다. 변이 측정 이전에 고쳐야 합니다.' >&2
   107	  $TESTS 2>&1 | grep '^  ✗'
   108	  exit 1
   109	fi
   110	echo '  ✓ 전건 초록'
   111	echo
   112	echo '── A. 판정의 핵심을 지운다 (지우면 위음성 = 자백이 통과한다) ────────'
   113	
   114	run_mutation '게이트 자체를 무력화한다' "$STOP" \
   115	  '  decision_hits="$(decision_scan "$transcript_path")"; decision_rc=$?' \
   116	  '  decision_hits=""; decision_rc=1'
   117	
   118	run_mutation '질문 0회 조건을 지운다 (질문해도 안 풀린다)' "$COMMON" \
   119	  'if asked > 0:
   120	    raise SystemExit(3)' \
   121	  '# (변이) 질문 판정 삭제'
   122	
   123	run_mutation '표지 판정을 지운다 (아무 문장이나 걸린다)' "$COMMON" \
   124	  '            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):' \
   125	  '            if not core:'
   126	
   127	run_mutation '걸린 문장을 메시지에 안 싣는다' "$STOP" \
   128	  "      printf '%s\\n' \"\$decision_hits\" | sed 's/^/  - /'" \
   129	  '      :'
   130	
   131	run_mutation '예산 호출을 지운다 (영원히 막힌다)' "$STOP" \
   132	  '    gate_budget "decision"' \
   133	  '    # (변이) gate_budget 호출 삭제'
   134	
   135	run_mutation '탈출구 판정을 지운다 (꺼도 안 꺼진다)' "$STOP" \
   136	  'if [ "$decision_armed" -eq 1 ] && ! hook_disabled "stop:decision"; then' \
   137	  'if true; then'
   138	
   139	echo
   140	echo '── B. 좁히는 장치를 지운다 (지우면 위양성 = 정상 발화가 막힌다) ─────'
   141	
   142	run_mutation '인라인 코드 제외를 지운다' "$COMMON" \
   143	  '        line = QUOTED.sub(" ", INLINE.sub(" ", line))' \
   144	  '        line = QUOTED.sub(" ", line)'
   145	
   146	run_mutation '따옴표 인용 제외를 지운다' "$COMMON" \
   147	  '        line = QUOTED.sub(" ", INLINE.sub(" ", line))' \
   148	  '        line = INLINE.sub(" ", line)'
   149	
   150	run_mutation '인용줄 제외를 지운다' "$COMMON" \
   151	  '        if BLOCKQUOTE.match(line):
   152	            continue' \
   153	  '        pass'
   154	
   155	run_mutation '코드펜스 제외를 지운다' "$COMMON" \
   156	  '    for fence in ("```", "~~~"):
   157	        s = "\n".join(p for i, p in enumerate(s.split(fence)) if i % 2 == 0)
   158	    return s' \
   159	  '    return s'
   160	
   161	run_mutation '질문 신호 제외를 지운다' "$COMMON" \
   162	  '            if QUESTION.search(whole) and not NEG_ASK.search(whole):
   163	                continue' \
   164	  '            pass'
   165	
   166	run_mutation '서술형 종결 요구를 지운다' "$COMMON" \
   167	  '            if not core or not MARKER.search(core) or not DECLARATIVE.search(core):' \
   168	  '            if not core or not MARKER.search(core):'
   169	
   170	run_mutation 'thinking 블록까지 스캔한다' "$COMMON" \
   171	  '        elif b.get("type") == "text":
   172	            t = b.get("text")
   173	            if isinstance(t, str):
   174	                texts.append(t)' \
   175	  '        elif b.get("type") in ("text", "thinking"):
   176	            t = b.get("text") or b.get("thinking")
   177	            if isinstance(t, str):
   178	                texts.append(t)'
   179	
   180	run_mutation '서브에이전트 발화까지 스캔한다' "$COMMON" \
   181	  '    if not isinstance(e, dict) or e.get("type") != "assistant" or e.get("isSidechain"):' \
   182	  '    if not isinstance(e, dict) or e.get("type") != "assistant":'
   183	
   184	# 자기참조 폭발을 막는 핵심 장치다 — 이게 없으면 이 패턴이 적힌 파일을 쓰는 것만으로 막힌다.
   185	run_mutation '도구 입력까지 스캔한다 (자기참조 폭발)' "$COMMON" \
   186	  '        if b.get("type") == "tool_use":
   187	            if b.get("name") == "AskUserQuestion":
   188	                asked += 1' \
   189	  '        if b.get("type") == "tool_use":
   190	            if b.get("name") == "AskUserQuestion":
   191	                asked += 1
   192	            else:
   193	                for _v in (b.get("input") or {}).values():
   194	                    if isinstance(_v, str):
   195	                        texts.append(_v)'
   196	
   197	echo
   198	echo '── C. 턴 경계를 흐린다 ─────────────────────────────────────────────'
   199	
   200	run_mutation '마지막이 아니라 첫 프롬프트를 경계로 삼는다' "$COMMON" \
   201	  '    if isinstance(e, dict) and is_user_prompt(e):
   202	        start = i' \
   203	  '    if isinstance(e, dict) and is_user_prompt(e) and start < 0:
   204	        start = i'
   205	
   206	# 두 판정을 **따로** 잰다. 실제 기록은 두 표식을 함께 갖고 있어서 한쪽만 지우면 다른 쪽이
   207	# 가려 준다 — 표식이 하나뿐인 픽스처(d25d·d25e)가 있어야 각각이 일하는지 보인다.
   208	run_mutation '상단 toolUseResult 판정을 지운다' "$COMMON" \
   209	  '    if "toolUseResult" in e:            # 도구 결과는 사용자 발화가 아니다
   210	        return False' \
   211	  '    pass'
   212	
   213	run_mutation 'tool_result 블록 판정을 지운다' "$COMMON" \
   214	  '    content = msg.get("content")
   215	    if isinstance(content, list):
   216	        for b in content:
   217	            if isinstance(b, dict) and b.get("type") == "tool_result":
   218	                return False
   219	    return True' \
   220	  '    return True'
   221	
   222	echo
   223	echo '── D. fail-open 이 조용해지게 만든다 ───────────────────────────────'
   224	# 판독 불가를 **통과시키는 것 자체는 설계**다. 문제는 그때 소리를 안 내는 것 —
   225	# 그러면 게이트가 죽은 것을 아무도 모르고, 그게 이 저장소가 부르는 조용한 실패다.
   226	
   227	run_mutation '판독 불가를 통과로 위장한다 (사유 소실)' "$COMMON" \
   228	  'def fail(reason):
   229	    sys.stdout.write(reason + "\n")
   230	    raise SystemExit(2)' \
   231	  'def fail(reason):
   232	    raise SystemExit(3)'
   233	
   234	run_mutation '판독 불가 사유를 안 실어 보낸다' "$STOP" \
   235	  '    decision_note="결정 게이트 생략 ($decision_hits)"' \
   236	  '    decision_note=""'
   237	
   238	run_mutation '판독 불가 사유를 안 출력한다' "$STOP" \
   239	  $'\n  emit_decision_note\n' \
   240	  $'\n  :\n'
   241	
   242	run_mutation '기록을 못 읽어도 조용히 넘어간다' "$COMMON" \
   243	  "  [ -r \"\$path\" ] || { printf '%s\\n' \"대화 기록을 읽을 수 없습니다: \$path\"; return 2; }" \
   244	  '  [ -r "$path" ] || return 3'
   245	
   246	run_mutation '턴 시작점을 못 찾으면 전체를 훑는다' "$COMMON" \
   247	  '    fail("이 턴의 시작점(사용자 프롬프트)을 찾지 못했습니다 (형식이 바뀌었을 수 있습니다)")' \
   248	  '    start = -1'
   249	
   250	echo
   251	echo '── F. 듀얼 검수 1라운드 반영분 ([cx] 지적) ─────────────────────────'
   252	
   253	run_mutation '"묻지 않았다" 예외를 지운다 (자백이 샌다)' "$COMMON" \
   254	  '            if QUESTION.search(whole) and not NEG_ASK.search(whole):' \
   255	  '            if QUESTION.search(whole):'
   256	
   257	run_mutation '마침표를 무조건 종결로 되돌린다' "$COMMON" \
   258	  'SENT       = re.compile("([\n!?…。！？]+|\\.(?=\\s)|\\.$)")' \
   259	  'SENT       = re.compile("([\n.!?…。！？]+)")'
   260	
   261	run_mutation '물결 펜스 지원을 지운다' "$COMMON" \
   262	  '    for fence in ("```", "~~~"):' \
   263	  '    for fence in ("```",):'
   264	
   265	run_mutation '이중 백틱 지원을 지운다' "$COMMON" \
   266	  'INLINE     = re.compile("``[^`\n]*``|`[^`\n]*`")' \
   267	  'INLINE     = re.compile("`[^`\n]*`")'
   268	
   269	run_mutation '문자열 content 를 건너뛴다 (발화가 사라진다)' "$COMMON" \
   270	  '    if isinstance(content, str):
   271	        # 문자열 본문도 발화다. 건너뛰면 그 발화가 스캔에서 통째로 사라진다.
   272	        texts.append(content)
   273	        continue' \
   274	  '    if isinstance(content, str):
   275	        continue'
   276	
   277	run_mutation '부분 손상을 건너뛴다 (전멸일 때만 실패)' "$COMMON" \
   278	  'if broken:
   279	    fail("대화 기록 %d줄을 파싱하지 못했습니다 (형식이 바뀌었을 수 있습니다)" % broken)
   280	if not entries:
   281	    fail("대화 기록이 비어 있습니다")' \
   282	  'if lines and not entries:
   283	    fail("대화 기록을 한 줄도 파싱하지 못했습니다")'
   284	
   285	run_mutation 'message 형식 검사를 지운다' "$COMMON" \
   286	  '    msg = e.get("message")
   287	    if not isinstance(msg, dict):
   288	        # truthy 비-dict 를 `or {}` 로 받으면 여기서 예외가 나고, 그 예외는 아래 "표지 없음"과
   289	        # 구별되지 않는 종료 코드로 나간다 — 조용한 통과다. 형식 변화로 보고 소리를 낸다.
   290	        fail("assistant 항목의 message 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")' \
   291	  '    msg = e.get("message") or {}
   292	    if False:
   293	        pass'
   294	
   295	run_mutation 'content 형식 검사를 지운다' "$COMMON" \
   296	  '    if not isinstance(content, list):
   297	        # 볼 수 없는 발화가 있다 = 사각지대다. 조용히 건너뛰면 게이트가 죽은 줄도 모른다.
   298	        fail("assistant 항목의 content 형식이 예상과 다릅니다 (형식이 바뀌었을 수 있습니다)")' \
   299	  '    if not isinstance(content, list):
   300	        continue'
   301	
   302	# **예상 밖 rc 를 통과로 읽던 경로.** 정상 경로가 모르는 코드를 내게 만들면, 호출부의
   303	# catch-all 이 살아 있는 한 위양성 케이스들이 "판독 불가 경고"를 보고 빨개진다.
   304	# 그 catch-all 을 지우면 이 변이가 초록으로 남는다 — 그게 이 항목이 재는 것이다.
   305	run_mutation '정상 경로가 예상 밖 rc 를 낸다 (호출부 catch-all 검출)' "$COMMON" \
   306	  'if not hits:
   307	    raise SystemExit(3)' \
   308	  'if not hits:
   309	    raise SystemExit(9)'
   310	
   311	# **공시된 측정 공백:** 호출부의 `*)` catch-all 만 지우는 변이는 **원리적으로 초록**이다.
   312	# 정상 동작에서는 예상 밖 rc 가 나오지 않으므로 그 가지에 도달하는 입력이 없기 때문이다
   313	# (python3 를 없애면 json_get 이 먼저 죽어 transcript_path 가 비고, 그러면 rc=2 경로로
   314	# 빠져 catch-all 을 안 탄다). 그래서 바로 위 항목 — **정상 경로가 rc=9 를 내게 만드는
   315	# 변이** — 가 그 가지의 생존을 대신 증명한다: catch-all 이 살아 있으면 위양성 케이스들이
   316	# 판독 불가 경고를 보고 빨개지고, catch-all 을 지우면 그 변이가 초록으로 돌아선다.
   317	# 두 항목은 짝이다. 하나만 보고 판단하지 마라(위음성 카탈로그 17번).
   318	
   319	run_mutation '발동을 플래그가 아니라 조기 종료에 맡긴다' "$STOP" \
   320	  'if [ -s "$AUDIT_FLAG" ] || [ -s "$EXPLAIN_FLAG" ] || [ -s "$DUALREVIEW_FLAG" ] || knowledge_gate_active; then
   321	  decision_armed=1
   322	fi' \
   323	  'decision_armed=1'
   324	
   325	# 앞 게이트에서 사유를 빼면 d51 만 빨개져야 한다. 함수를 통째로 무력화하면 판독 불가
   326	# 케이스가 전부 빨개져서 "앞 게이트에도 실리는가"를 격리해 재지 못한다.
   327	run_mutation '앞 게이트(듀얼리뷰)에서 사유를 뺀다' "$STOP" \
   328	  '    emit_decision_note
   329	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"' \
   330	  '    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"'
   331	
   332	echo
   333	echo '── E. 순서 계약 — 게이트를 뒤로 옮긴다 ─────────────────────────────'
   334	# 지우는 것과 옮기는 것은 다른 측정이다. 지우면 "게이트 없음"을 재고, 옮겨야
   335	# "순서가 틀림"을 잰다. 질문의 답이 코드를 바꿀 수 있으므로 앞이어야 한다.
   336	total=$((total + 1))
   337	if python3 - "$STOP" <<'PY'
   338	import io, sys
   339	path = sys.argv[1]
   340	s = io.open(path, encoding='utf-8').read()
   341	head, mid, after = '# (3.2) **결정 게이트**', '# (3.5) 듀얼 리뷰', '# (6) 타입체크는 통과했지만'
   342	for tok in (head, mid, after):
   343	    if s.count(tok) != 1:
   344	        sys.stderr.write('  ! 이동 앵커 매치 수 이상: %r=%d\n' % (tok, s.count(tok)))
   345	        sys.exit(1)
   346	start, end = s.index(head), s.index(mid)
   347	block = s[start:end]
   348	s = s[:start] + s[end:]
   349	io.open(path, 'w', encoding='utf-8').write(s.replace(after, block + after))
   350	PY
   351	then
   352	  measure '게이트를 감사 직전으로 옮긴다' "$STOP"
   353	else
   354	  printf '  ! %-44s 변이 주입 실패 (앵커 불일치)\n' '게이트를 감사 직전으로 옮긴다'
   355	  restore_and_verify "$STOP"
   356	  missed=$((missed + 1))
   357	fi
   358	
   359	echo
   360	echo "— 변이 ${total}건 중 ${caught}건 적색 / ${missed}건 초록(미방어)"
   361	[ "$missed" -eq 0 ] || exit 1

2026-08-10T08:16:19.329096Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "rg -n -C 8 '결정 게이트|대화 기록|영어|표지|코드펜스|인라인|판독 불가|AskUserQuestion|59건|35건' docs/usage.md README.md
rg -n 'emit_decision_note|gate_budget|decision_armed|decision_note' template/.claude/hooks/verify-before-stop.sh tests/decision-gate.test.sh _workspace/mutate-decision-gate.sh" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
docs/usage.md-63-| guard-master-commit | Bash 실행 전 | master/main 직접 `git commit` 차단 |
docs/usage.md-64-| guard-hook-disable | Bash 실행 전 | 에이전트가 `HARNESS_HOOKS`·`ECC_DISABLED_HOOKS`·`ECC_GATEGUARD` 를 끄려 할 때 한 번 세운다. **과속방지턱이지 방벽이 아니다** — 아래 참조. 탈출구가 **없다** |
docs/usage.md-65-| guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
docs/usage.md-66-| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (코드는 4종 전부 · 설계·계획 산출물은 듀얼리뷰+지식 · 결정 문서는 지식만). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
docs/usage.md-67-| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → **혼자 정하지 않았나** → codex 듀얼리뷰 → change-explainer → **지식 저장소 반영** → **push 미완** → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
docs/usage.md-68-
docs/usage.md-69-**지식 저장소 게이트가 아는 것은 계약 하나뿐이다** — "지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다." **어디에 어떤 구조로 반영하는지는 하네스가 모른다.** 그건 사용자 층 설정(전역 `CLAUDE.md` 등)이 답하고, 하네스에는 켜짐/꺼짐 1비트만 있다. 그래서 지식 저장소를 바꿔도 하네스는 고치지 않고, 아예 안 쓰는 프로젝트에서도 그대로 돈다.
docs/usage.md-70-
docs/usage.md:71:**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:decision`(결정 게이트만) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) / `stop:push`(push 게이트만) 나열.
docs/usage.md-72-**`guard-hook-disable` 은 과속방지턱이지 보안 경계가 아니다.** 판정이 정규식 하나라 셸을 해석하지 못한다 — `read`+`export`, 따옴표로 쪼갠 `env 'X''=off'`, 변수 조립, `eval`, 생성한 스크립트 실행은 전부 통과한다(실측). 그럼에도 값을 하는 이유는 막으려는 것이 적대적 공격자가 아니라 **막힌 에이전트의 직진 충동**이고, 그건 `HARNESS_HOOKS=off ...` 라는 직진형으로 나오기 때문이다. 제대로 막으려면 셸 파서가 필요한데, 반쯤 만든 셸 파서는 안 만든 것보다 나쁘다(막힌다고 믿게 하면서 안 막는다 — 이 저장소가 `harness.env` 판독기에서 겪은 늪).
docs/usage.md-73-
docs/usage.md-74-**그래서 위양성 쪽으로 기운다.** 실행 구문과 인용문을 구분하지 않아 `git grep 'HARNESS_HOOKS=off'` 같은 정당한 검색도 막힌다. 의도된 선택이다 — 따옴표 안을 건너뛰면 위양성은 사라지지만 `bash -c 'HARNESS_HOOKS=off ...'` 가 뚫린다. 둘은 문자열로 구별되지 않는 같은 모호성의 양면이고, 위양성은 메시지 한 번이 비용이지만 위음성은 **게이트가 꺼진 걸 아무도 모르는** 것이 비용이다. 차단 메시지가 위양성일 때의 대안(패턴 쪼개기·Write 도구 사용)을 함께 안내한다.
docs/usage.md-75-
docs/usage.md-76-**그리고 환경변수로 끌 수 없다.** 그 탈출구가 있으면 에이전트가 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다. 사용자가 정말 끄려면 셸에서 직접 `export` 하고 세션을 새로 띄우거나 `settings.json` 배선을 지운다 — 둘 다 사람이 하는 행위다.
docs/usage.md-77-
docs/usage.md:78:**결정 게이트가 있는 이유:** 나머지 게이트는 전부 **산출물**을 본다("코드가 검증됐나", "설명이 나왔나"). 그런데 실측된 실패의 대부분은 산출물이 아니라 **행동**이었다 — 게이트가 막을 때는 세 번 다 따랐으면서, 게이트가 없는 자리에서는 전부 혼자 정하고 보고서에 한 줄 적었다. 그 "한 줄"은 도구 호출이 아니라 문장이라 승인창도 안 뜬다. 그래서 이 게이트만 **대화 기록을 직접 읽는다**: 코드·결정이 바뀐 턴에 결정 표지 어휘를 담은 서술형 문장이 있는데 `AskUserQuestion` 이 0회면 막고, 걸린 문장을 목록으로 보여준다. **질문 한 번이면 풀린다.**
docs/usage.md-79-
docs/usage.md:80:**여기서는 위양성도 위음성만큼 비싸다.** 다른 검사기와 판단이 갈리는 유일한 자리다 — 위양성의 비용이 메시지 한 번이 아니라 사용자에게 가는 **불필요한 질문**이고, 그게 반복되면 질문이 소음이 되어 진짜 질문까지 무시된다. 게다가 이 게이트의 훅·테스트·ADR 이 그 어휘를 데이터로 품어서, 어휘만 보면 **게이트를 유지보수하는 작업 자체가 매번 걸린다.** 그래서 좁힌다: 코드펜스·인라인 코드·인용줄·따옴표 안은 안 보고, 같은 문장에 물음이 있으면 세지 않고, 서술형 단정으로 끝나야 센다. **도구 입력도 안 본다**(발화 텍스트만) — 그 어휘가 적힌 파일을 쓰는 것 자체는 결정이 아니다. 사고 블록과 서브에이전트 발화도 뺀다.
docs/usage.md-81-
docs/usage.md-82-*걸렸는데 결정이 아니라면* 백틱이나 따옴표로 감싸면 빠진다. 그래도 걸리면 사용자에게 알리고 지시를 받는다.
docs/usage.md-83-
docs/usage.md:84:**이건 탐지기가 아니라 과속방지턱이다.** 표지 어휘는 원리에서 유도한 분류법이 아니라 **한 세션에서 실제로 쓰인 문장을 관찰해 뽑은 표본**이다. 그래서:
docs/usage.md-85-
docs/usage.md-86-- 표현을 조금 바꾸면 **빠져나간다**(위음성). 겨누는 것이 적대적 회피가 아니라 무의식적 습관이라 그래도 실효가 남는다
docs/usage.md:87:- **영어 발화는 하나도 못 본다.** 표지가 전부 한국어다 — 축 하나가 통째로 비어 있다
docs/usage.md-88-- 반대로 그 어휘는 자백에만 나오지도 않는다. `변이 테스트는 별도로 실행됩니다` 같은 **단순 기술 서술도 걸린다.** 어휘에 조건을 덧붙여 좁히지 **않기로 했다** — 그 조건도 같은 출처의 추측이라 문제를 없애는 게 아니라 옮기는 것이기 때문이다
docs/usage.md-89-- 목록은 **새는 것을 실제로 본 뒤에만** 늘린다. 이 저장소가 게이트를 만드는 방식 그대로다
docs/usage.md-90-
docs/usage.md:91:**대화 기록을 못 읽으면 막지 않고 통과시킨다 — 이 하네스에서 유일한 fail-open 이다.** 기록 형식은 하네스가 소유하지 않아 예고 없이 바뀔 수 있는데, 그때 차단하면 **그 세션 안에 고칠 방법이 없어 통째로 벽돌이 된다**(기록을 고칠 수 없으므로 어떤 행동으로도 안 풀린다). 대신 사유가 마지막 게이트 메시지에 실린다 — 조용히 통과하면 게이트가 죽은 것을 아무도 모른다. **공시된 한계:** `HARNESS_KNOWLEDGE_GATE` 를 비운 환경에서는 결정 문서만 고친 턴이 조기 종료에 걸려 이 게이트까지 오지 않는다(기본값이 켜짐이라 기본 구성에서는 정상 발동). 자세한 근거는 [ADR-0012](decisions/2026-08-10-decision-gate.md).
docs/usage.md-92-
docs/usage.md-93-**push 게이트가 있는 이유:** 이 저장소는 커밋 29개를 잃은 적이 있다. 코드는 다 짜여 있었고 "아직 PR 전이니까"라며 push 를 미뤘다. 게이트는 **네트워크를 쓰지 않는다** — 로컬 remote-tracking ref 만 본다. 원격에 있는데도 ref 가 안 보이면(`remote.origin.fetch` 가 좁혀진 경우) 그 사실을 사유에 적는다. push 여부가 로컬에서 안 보이는 것 자체가 위험이기 때문이다. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
docs/usage.md-94-
docs/usage.md-95-### 완료 게이트 검사 범위 (mark-needs-audit)
docs/usage.md-96-
docs/usage.md-97-판정 **순서가 곧 계약**이다: 개행 가드 → 물리 경로 정규화 → 듀얼리뷰 판정 → 범위 판정 → 분류 → 기록.
docs/usage.md-98-
docs/usage.md-99-- **프로젝트 안** — `_workspace/`·`.claude/`·문서 `*.md`·`*.markdown`(대소문자 무관)는 제외. 나머지는 게이트 4종.
--
docs/usage.md-106-- **결정 문서**(`docs/decisions/*.md`) — 문서 제외의 **예외**로 **지식** 플래그만 세운다. 코드가 아니므로 타입체크·변경설명·감사는 과하다. **공시된 한계:** 결정 문서를 이 경로 밖에 두면 게이트가 서지 않는다 — 하네스는 자기가 아는 경로만 알 수 있다.
docs/usage.md-107-- **밖 편집은 절대경로로 기록**한다. 상대경로로 적으면 프로젝트와 외부 저장소가 `README.md` 같은 흔한 경로를 공유할 때 감사자가 프로젝트 쪽 동명 파일을 보고 통과시킨다.
docs/usage.md-108-- 플래그를 못 쓰거나 경로에 개행이 있으면 **차단하지 않고** `systemMessage`로 알린다(PostToolUse는 항상 exit 0). git 호출이 실패했는데 조상에 `.git`이 있으면 그 사실도 알린다 — 정본 저장소가 조용히 앵커 전용으로 강등되는 것을 사람이 알 수 있게.
docs/usage.md-109-
docs/usage.md-110-계약의 **기계 정본**은 `tests/mark-needs-audit.cases.sh`의 판정 표이고, 케이스 수는 같은 파일의 `EXPECTED_CASES`가 강제한다. CI가 PR마다 돌린다.
docs/usage.md-111-
docs/usage.md-112-## 6. 트러블슈팅
docs/usage.md-113-
docs/usage.md:114:- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: 결정 게이트(`AskUserQuestion` 으로 실제로 묻는다 — 지울 플래그가 없다) → codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 지식 저장소 반영(`.needs-knowledge`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
docs/usage.md-115-- **타입체크가 이상하게 실패** → `harness.env`의 명령을 셸에서 직접 실행해 확인. 도구 부재(rc=127)·타임아웃은 차단 안 하고 생략 처리된다.
docs/usage.md-116-- **superpowers 스킬 호출 실패** → 플러그인 설치/이름 확인: `test-driven-development`·`writing-plans`·`brainstorming`·`requesting-code-review`·`verification-before-completion`·`systematic-debugging`.
docs/usage.md-117-- **에이전트가 도메인을 무시** → 프로필 §가 비어 있지 않은지 확인. 오케스트레이터는 빈 §를 "검증 생략"으로 정직 보고한다.
docs/usage.md-118-
docs/usage.md-119-## 7. 하네스 진화
docs/usage.md-120-
docs/usage.md-121-에이전트/스킬 수정·추가는 이 repo(정본)에서 하고 커밋 → 각 프로젝트에 `sync.sh`. 구조 변경이 크면 `harness` 메타 스킬(운영/유지보수 워크플로우)을 사용. 변경 이력은 각 프로젝트 CLAUDE.md의 변경 이력 표에 기록.
docs/usage.md-122-
--
README.md-55-## 3. 왜 이런 구성인가 — 핵심 설계 결정
README.md-56-
README.md-57-각 결정을 "결정 / 대안 / 왜"로 기록한다. (architecture-guide가 설명할 때의 근거 원장이기도 하다.)
README.md-58-
README.md-59-**① 파이프라인 + 3중 generate-verify 루프 (계획·개발·PR)**
README.md-60-대안: 유능한 에이전트 하나가 다 하기. → 결함은 늦게 잡을수록 비싸다. 계획 결함을 개발 후에 발견하면 코드·검수·PR 전부 재작업. 각 산출물마다 생성자와 다른 검증자를 붙여 가장 싼 지점에서 잡는다. 역할 분리는 컨텍스트 오염도 막는다.
README.md-61-
README.md-62-**② 강제력은 훅이 소유한다 — 이 하네스의 무기**
README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview`)·`Stop`(타입체크→**혼자 정하지 않았나**→듀얼리뷰→설명→지식 저장소반영→push 미완→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. 그 중 **결정 게이트만 산출물이 아니라 에이전트의 행동을 본다**(⑬). superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
README.md-64-
README.md-65-**③ 단일 프로필 슬롯 + 런타임 주입**
README.md:66:대안 1: 도메인을 각 에이전트에 인라인(원본 방식) → 같은 사실이 5+개 파일에 중복, 바뀌면 드리프트. 대안 2: 에이전트에게 "프로필을 읽어라" 지시만 → 안 읽으면 도메인이 컨텍스트에 아예 없음. → 채택: 도메인은 프로필 한 파일(디스크의 단일 원천), 오케스트레이터가 dispatch마다 해당 §전문을 프롬프트에 동봉(런타임 인라인). **에이전트의 순종에 안 맡긴다.** 읽을지 선택할 기회 자체를 없앴고, 그래도 어기면 같은 프로필을 근거로 한 reviewer가 잡는다.
README.md-67-
README.md-68-**④ 제0원칙은 developer가 아니라 하네스가 소유**
README.md-69-"코드는 사람을 위한 것 — 이름=계약, 구현=교체 가능한 부품, 과함도 배신(YAGNI)". 대안: developer 정의에만 넣기. → 모듈 경계는 **계획에서 정해지고 리뷰에서 강제**되므로 developer만 알면 샌다. planner(설계 반영)·plan-reviewer(검증)·developer(구현)·reviewer(적발)·architecture-guide(설명)가 같은 파일(`harness/principles.md`)을 공유한다.
README.md-70-
README.md-71-**⑤ ECC·superpowers·claude-mem은 참조, 복사 금지**
README.md-72-대안: 좋은 부분을 템플릿에 복사해 자기완결. → 복사본은 그 순간부터 낡는다(버전 드리프트). 참조는 원본이 업데이트되면 공짜로 최신. superpowers 스킬은 서브에이전트의 `Skill` 도구로 런타임 로드(복사 0), ECC 룰은 세션 상주라 인용만, claude-mem recall은 `claude-mem:mem-search` 스킬 호출로 위임. 전역 `using-superpowers`의 "응답 전 스킬 먼저" 선점만 CLAUDE.md 지시로 꺼서 오케스트레이터가 순서 통제권을 유지한다.
README.md-73-
README.md-74-**⑥ per-agent 스킬 붕괴**
--
README.md-87-리서치 수집/평가처럼 프로젝트 무관 에이전트는 프로젝트 글루로도, 전역 직접 작성으로도 안 맞는다(전자는 용도 불일치, 후자는 버전 관리 불가). `global-agents/`를 정본으로 install/sync가 전역 배포한다. reporter 에이전트는 기각 — evaluator 분리의 가치는 독립성이지만 보고서의 가치는 사용자 맥락이고 그것은 메인 세션에 있다. 상세: [ADR-0002](docs/decisions/2026-07-20-global-agents-layer.md).
README.md-88-
README.md-89-**⑪ 모든 검증 게이트는 이종(異種) 듀얼 — Claude + Codex (2026-08-01 사용자 확정)**
README.md-90-대안: Claude 리뷰어 단독. → 같은 모델은 생성자와 맹점을 공유한다 — 실제로 Claude 단독 검수가 놓친 CRITICAL을 codex가 적발했다(2026-08-03 POK-30). 계획검증·검수·PR점검 전 게이트에 codex를 병렬 투입하고 `[cc]`/`[cx]`/`[cc·cx]` 태그로 통합, 판정 충돌 시 보류 우선. 모델(`gpt-5.6-sol`)·effort(`high`)는 하드코딩 — "작업이 작다/비용" 사유의 임의 하향 실사고(2026-08-01)를 `guard-codex-invocation.sh`(PreToolUse)가 명령 위치의 `codex exec` 호출을 기계 차단한다(커밋 메시지·문서 속 문자열은 오탐 제외). 규정 자체도 기계화했다: 설계·계획 산출물 저장과 코드 편집이 `.needs-dualreview`를 세우고, Stop 훅이 이 플래그가 서 있는 한 종료를 막는다 — 플래그는 codex 리뷰 산출물(`_workspace/*codex*.md`) 저장·`[cc]`/`[cx]` 통합 후에만 지우는 규율이다(훅은 플래그만 보므로 산출물 실존 검증은 감사자 몫) — sync 누락으로 구버전 스킬이 듀얼 리뷰를 조용히 생략한 실사고(2026-08-03)의 재발 방지. 같은 사고에서 오케스트레이터 Phase 0의 정본 드리프트 확인(스킬·훅이 정본과 다르면 작업 전 sync 먼저)도 나왔다.
README.md-91-
README.md-92-**⑫ 지식 반영도 완료 조건 — 지식 저장소 게이트 (2026-08-02 사용자 확정)**
README.md-93-대안: "세션 끝나면 어디에든 정리해라" 산문 규칙. → 세션 내내 0회 이행된 실사고. 코드·설정이 바뀐 턴은 **지식 저장소 반영** 또는 불요 사유 기록 없이 종료 불가(`.needs-knowledge` + Stop 훅 `stop:knowledge`). 하네스가 아는 것은 계약 하나뿐이다 — 저장소가 **어디이고 어떤 구조인지는 사용자 층 설정이 답한다**(ADR-0006). completion-auditor가 반영 증거(커밋 해시·파일 실존)를 1차 증거로 검증한다 — 코드가 끝나도 지식이 안 남았으면 완료가 아니다. 게이트는 기본 켜짐이고 `harness.env` 의 `HARNESS_KNOWLEDGE_GATE` 를 비워서만 끈다(ADR-0008).
README.md-94-
README.md:95:**⑬ 게이트 하나는 산출물이 아니라 에이전트를 본다 — 결정 게이트 (2026-08-10 사용자 확정)**
README.md:96:대안: 승인 모드에 맡긴다. → **승인창은 *한 일*에만 뜬다.** 안 한 일(묻지 않은 것·push 하지 않은 것)은 원리적으로 안 잡힌다 — 실측에서 다른 훅이 26번 승인을 요구하는 동안 혼자 결정하는 것은 **한 번도** 못 막았다. 완료 게이트 넷이 전부 산출물을 볼 때, 실패는 게이트가 없는 축(물어야 할 결정·push·기록된 선호)에서만 났다. 그래서 Stop 훅이 **이 턴의 대화 기록을 직접 읽어** 판정한다: 코드·결정이 바뀐 턴에 결정 표지 어휘를 담은 서술형 문장이 있는데 `AskUserQuestion` 이 0회면 차단하고 걸린 문장을 보여준다. 질문 한 번이면 풀린다. **여기서만 위양성이 위음성만큼 비싸다** — 불필요한 질문이 반복되면 소음이 되고, 소음이 되면 진짜 질문도 무시되며, 무엇보다 이 게이트의 훅·테스트·ADR 이 그 어휘를 데이터로 품어 **게이트를 유지보수하는 작업 자체가 걸린다.** 그래서 구조적 제외(코드펜스·인용·따옴표)와 서술형 종결 요구로 좁히고, **도구 입력은 아예 안 본다.** 그리고 대화 기록을 못 읽으면 **막지 않고 통과시킨다** — 이 하네스의 유일한 fail-open 이다(형식은 하네스 소유가 아니고, 차단하면 그 세션 안에 고칠 방법이 없다). 대신 사유를 마지막 게이트 메시지에 싣는다. 상세: [ADR-0012](docs/decisions/2026-08-10-decision-gate.md).
README.md-97-
README.md-98-## 4. 에이전트 — 자체 8 + ECC 참조 5
README.md-99-
README.md-100-**자체 에이전트 8** (이 repo 소유 — 하네스 계약이 정의에 내장):
README.md-101-
README.md-102-| 에이전트 | 역할 한 줄 | 투입 |
README.md-103-|---|---|---|
README.md-104-| clarifier | 모호점·비가역 결정을 질문으로 — "추측 말고 물어본다"의 강제 | 항상 (맨 앞) |
--
README.md-132-| 스택 PR의 base 삭제로 뒤 PR이 통째로 닫힘 | 스택 PR 금지, 기능마다 기본 브랜치에서 새 브랜치 + PreToolUse 커밋 가드 |
README.md-133-| 머지됐는데 사용자는 옛 빌드 화면을 보며 "그대로"라고 항의 (2026-07-12) | 프로필 §6 운영 모델 + 감사자의 "머지 ≠ 운영 반영" 판정 의무 |
README.md-134-| 변경 설명 단계를 오케스트레이터가 임의 생략 (2026-07-13) | `.needs-explain` 플래그 + Stop 훅 설명 게이트 — 산문이던 절차를 훅으로 |
README.md-135-| 도메인 지식이 에이전트 5+곳에 산재, 재사용 불가 | 단일 프로필 슬롯 + 런타임 주입 — **이 템플릿의 탄생 이유** |
README.md-136-| 신생 repo에서 커밋 가드가 우연히 통과 (Stage 6a에서 발견) | unborn HEAD 처리 명문화 — 우연을 의도로 (a9cad82) |
README.md-137-| codex 리뷰를 "작업이 작다/비용"이라며 모델·effort 임의 하향 (2026-08-01) | 듀얼 리뷰 규칙에 모델·effort 하드코딩 + guard-codex-invocation 훅 — 미달 호출을 PreToolUse에서 차단 (환경변수 탈출구 없음) |
README.md-138-| 지식 저장소 반영 산문 규칙이 세션 내내 0회 이행 (2026-08-02) | `.needs-knowledge` 플래그 + Stop 지식 저장소 게이트 — 지식 반영도 완료 조건으로 승격 |
README.md-139-| sync 누락 → 구버전 스킬이 설계 듀얼 리뷰를 조용히 생략, Claude 단독이 놓친 CRITICAL을 codex가 뒤늦게 적발 (2026-08-03 POK-30) | `.needs-dualreview` 기계 게이트 + Stop 차단 + Phase 0 정본 드리프트 확인 (다르면 작업 전 sync 먼저) |
README.md:140:| 게이트가 막을 때는 세 번 다 따랐는데, 게이트가 없는 축에서는 전부 혼자 정하고 보고서에 한 줄 적음 — 그 "한 줄"은 도구 호출이 아니라 문장이라 승인창도 안 뜬다 (2026-08-10 실측) | Stop 훅이 **대화 기록을 직접 읽는** 결정 게이트 — "자백은 있는데 질문이 0회"면 차단하고 걸린 문장을 보여준다. 게이트가 처음으로 산출물이 아니라 **행동**을 본다 ([ADR-0012](docs/decisions/2026-08-10-decision-gate.md)) |
README.md-141-| 검사기 자신이 어긋난 사본을 통과시킴 — 마커를 꾸미거나 블록을 2개 두면 무사통과 (2026-08-04 실측) | 전체 줄 3상태 파서 + 미등록 사본 스캔 + NUL 바이트 거부 게이트(UTF-16·NUL 위장으로 스캔을 통째로 비켜가던 경로) + 회귀 테스트 (건수의 정본은 테스트 파일의 `EXPECTED_CASES`) |
README.md-142-
README.md-143-교훈의 패턴: **산문으로만 존재하는 절차는 언젠가 생략된다. 반복 실패는 훅·게이트·프로필로 승격하라.** (단, 선제 방어는 하지 않는다 — 실제로 겪은 뒤에 강제를 추가한다. YAGNI는 프로세스에도 적용된다.)
README.md-144-
README.md-145-## 6. 디렉토리 구조
README.md-146-
README.md-147-```
README.md-148-~/.claude/harness-template/
_workspace/mutate-decision-gate.sh:132:  '    gate_budget "decision"' \
_workspace/mutate-decision-gate.sh:133:  '    # (변이) gate_budget 호출 삭제'
_workspace/mutate-decision-gate.sh:136:  'if [ "$decision_armed" -eq 1 ] && ! hook_disabled "stop:decision"; then' \
_workspace/mutate-decision-gate.sh:235:  '    decision_note="결정 게이트 생략 ($decision_hits)"' \
_workspace/mutate-decision-gate.sh:236:  '    decision_note=""'
_workspace/mutate-decision-gate.sh:239:  $'\n  emit_decision_note\n' \
_workspace/mutate-decision-gate.sh:321:  decision_armed=1
_workspace/mutate-decision-gate.sh:323:  'decision_armed=1'
_workspace/mutate-decision-gate.sh:328:  '    emit_decision_note
template/.claude/hooks/verify-before-stop.sh:92:gate_budget() {  # $1 = 게이트 식별자. 각 차단 지점이 메시지 출력 전에 호출한다.
template/.claude/hooks/verify-before-stop.sh:115:emit_decision_note() {
template/.claude/hooks/verify-before-stop.sh:116:  [ -n "${decision_note:-}" ] || return 0
template/.claude/hooks/verify-before-stop.sh:118:  echo "참고: $decision_note"
template/.claude/hooks/verify-before-stop.sh:170:    gate_budget "typecheck"
template/.claude/hooks/verify-before-stop.sh:192:decision_note=""
template/.claude/hooks/verify-before-stop.sh:196:decision_armed=0
template/.claude/hooks/verify-before-stop.sh:198:  decision_armed=1
template/.claude/hooks/verify-before-stop.sh:200:if [ "$decision_armed" -eq 1 ] && ! hook_disabled "stop:decision"; then
template/.claude/hooks/verify-before-stop.sh:207:      decision_note="결정 게이트 생략 ($decision_hits)" ;;
template/.claude/hooks/verify-before-stop.sh:212:      decision_note="결정 게이트 생략 (스캐너가 예상 밖 상태로 끝남 rc=$decision_rc — python3 부재·예외·신호 종료일 수 있습니다)" ;;
template/.claude/hooks/verify-before-stop.sh:215:    gate_budget "decision"
template/.claude/hooks/verify-before-stop.sh:247:  gate_budget "dualreview"
template/.claude/hooks/verify-before-stop.sh:261:    emit_decision_note
template/.claude/hooks/verify-before-stop.sh:272:  gate_budget "explain"
template/.claude/hooks/verify-before-stop.sh:284:    emit_decision_note
template/.claude/hooks/verify-before-stop.sh:299:  gate_budget "knowledge"
template/.claude/hooks/verify-before-stop.sh:318:    emit_decision_note
template/.claude/hooks/verify-before-stop.sh:328:  gate_budget "push"
template/.claude/hooks/verify-before-stop.sh:344:    emit_decision_note
template/.claude/hooks/verify-before-stop.sh:351:gate_budget "audit"
template/.claude/hooks/verify-before-stop.sh:361:  emit_decision_note

2026-08-10T08:17:16.491424Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
codex
현재까지 셸의 미설정 변수 경로는 `${decision_note:-}` 때문에 안전하고, push-only 발동 분리도 의도대로 보입니다. 다만 문서의 구조적 제외 약속과 실제 Markdown 처리 범위, 그리고 신호 트랩/예산 소진 경로에서 수정이 끝까지 유지되는지는 추가 확인이 필요합니다. 저장소 테스트를 실행하지 않고 실제 JSONL 형식 표본과 정적 대조만 하겠습니다.
exec
/bin/zsh -lc "rg --files /Users/kty/.claude/projects 2>/dev/null | rg '\\.jsonl"'$'"' | head -80
rg -l '\"type\":\"(queue-operation|attachment|last-prompt|custom-title)\"|\"type\": \"(queue-operation|attachment|last-prompt|custom-title)\"' /Users/kty/.claude/projects -g '*.jsonl' 2>/dev/null | head -30" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ab84b23f3991ca2ae.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a5cba032389c31bfc.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ab78c016f4bcc0471.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-afecf2f2dd17acd81.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a0d60126d7175891b.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a21b943ae1cfbcc9e.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ac49b42a24cfd5303.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a52f97fbe77cd839f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a35dd314eaff8e14c.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-aa9438c289007b50f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a04824dd33da1209d.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ae1718a170f039d83.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ab9dcd3e50e662b1f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a4775915200e87802.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a3d014da8357eaf89.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a17e2648f04ee9bb7.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a6160b595738bc153.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a870487cfcb8e42e0.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1/subagents/agent-a258301fce18bd612.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/69541816-ba99-427f-8dd9-3719d66a6367.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-----/758fae1a-b255-460d-a07f-44c2714a4202.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-----/8a4b3f6c-ac59-4fd2-bd9c-9f6aae0463ec.jsonl
/Users/kty/.claude/projects/-Users-kty-Documents-valut/6d1e1f31-2776-43cd-a9b0-2eb4ef15de8d.jsonl
/Users/kty/.claude/projects/-Users-kty-Documents-valut/23e14ccc-247a-445f-9623-8b6aa065798d.jsonl
/Users/kty/.claude/projects/-Users-kty-Documents-valut/f398f89b-38fe-4837-85ad-83c1c33e795c.jsonl
/Users/kty/.claude/projects/-Users-kty-Documents-valut/161a726b-3efd-4be8-aff4-3817c7253587.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-engine-input-data-format-8e3ee7/e5978a0f-36d7-4dba-a73e-1ce4a4ce1e0f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-vigilant-boyd-385f99/d1fca869-bc31-45f4-97af-a9b3d925f848.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-sharp-albattani-9db8c7/dbe9c2ae-cbac-43e5-9375-a36ad8e447e2.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-sharp-albattani-9db8c7/6f558013-f20d-4ee9-aefb-7e314b23dfcd.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-a6071ae06e30a8af1.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-af8cadf509a8ce137.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-a3d4264400b5b23d5.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/42984026-966c-4e9b-ae85-44067f5abcdb.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads/bfd86b67-2f59-497a-8230-c1cebd083773.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads/91d7f20e-0666-4cc5-9eb4-c20506c6b7bf.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads/a4df6269-ef9c-4275-9ff2-61041ea546c7.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/cbed9984-669d-4082-9f25-dbf386a3756a.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-usecase0-drawio-engine-resume-cb705b/3609e734-1a66-43bd-8da7-1f241f34c0d4.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-cloud-architecture-redesign-5e7080/b4f50d06-77cd-4152-bee7-9c30229b02a0.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pratice/c74d7c4b-fb9c-4fd5-9f3e-67e534c4e066.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-adoring-pasteur-1cab64/4495a13f-b5b4-494b-bf1d-59b8853a2f0e.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono/05b528e0-d68c-430f-bff0-29296ab7b847.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono/3486cf2f-967f-4b92-bd84-7c463a12fbd9.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-usecase0-drawio-engine-resume-cb705b/3609e734-1a66-43bd-8da7-1f241f34c0d4/subagents/agent-a9461b52b0c61f4b8.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-non-4-development-85f958/8b910f8b-e232-43e9-a847-c67de99e6678.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-non-4-development-85f958/0443b2d5-1d42-4670-88df-b7b2a4d496a1.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-non-4-development-85f958/d4e3b7ac-30be-4e5d-8289-7663f36bffb6.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-non-4-development-85f958/1da2d6fd-c6b2-4ed8-b48a-155ebd4ec180.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-cost-optimization-3018d5/f1e63a73-f87d-4686-8377-51e942dfc3ee.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-cost-optimization-3018d5/6cc870a0-e1ca-4364-9b13-6dee8838002b.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-cloud-architecture-understanding-f36a9d/9ddd950b-308b-46e9-a193-3fd239fb29ea/subagents/agent-af9eff758f484f65b.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-cloud-architecture-understanding-f36a9d/8f82c637-13c8-475e-8c5f-b36f0ee5ce7a.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-cloud-architecture-understanding-f36a9d/9ddd950b-308b-46e9-a193-3fd239fb29ea.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-ac27434546eeb7171.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-ae2065a40fbb05a31.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-a2ca25639b125675f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-adffef128c60bde2b.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-a1725366c5c66d0c3.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-a9567c790eed3f83d.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-abca5e822774e8bdb.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-af5c22f0466045b21.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-aaa41db2873596f87.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-a0e9cc656e28b2d8b.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-a616c5af8360a69d2.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-a03cbd51d7f4a30bf.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-acc3edff108109f04.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-a7ec2ca358baaf2d1.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-a76974f397ce04917.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-ad511443ba29f165a.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-mediamtx-hook-validation-d0a411/34654a1d-9fcd-482a-ac52-e2eb2f028f3b/subagents/agent-ad750259408992c02.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-mediamtx-hook-validation-d0a411/34654a1d-9fcd-482a-ac52-e2eb2f028f3b/subagents/agent-afddc69a814bff71f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-mediamtx-hook-validation-d0a411/34654a1d-9fcd-482a-ac52-e2eb2f028f3b/subagents/agent-a913c9bc1ea807bcc.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-mediamtx-hook-validation-d0a411/34654a1d-9fcd-482a-ac52-e2eb2f028f3b/subagents/agent-ab91deed68b17ea38.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-mediamtx-hook-validation-d0a411/34654a1d-9fcd-482a-ac52-e2eb2f028f3b/subagents/agent-a4d5963fe8bc6c2e9.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-mediamtx-hook-validation-d0a411/34654a1d-9fcd-482a-ac52-e2eb2f028f3b/subagents/agent-a6db951816e7d2700.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/69541816-ba99-427f-8dd9-3719d66a6367.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a17e2648f04ee9bb7.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-pok-36-tfdt-measurement-1dcdba/fa96e2d1-e5f5-4cd0-a291-1a8753153951.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a04824dd33da1209d.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a21b943ae1cfbcc9e.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-a6071ae06e30a8af1.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-compassionate-swanson-ea6761/59fe3773-78bd-4a22-af62-0c663f39c47e/subagents/agent-a26eb266a221901a2.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-af8cadf509a8ce137.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ab9dcd3e50e662b1f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-a3d4264400b5b23d5.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-compassionate-swanson-ea6761/59fe3773-78bd-4a22-af62-0c663f39c47e/subagents/agent-a52f4d9676112c006.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a52f97fbe77cd839f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-pok-36-tfdt-measurement-1dcdba/8b95614d-17aa-4849-bff6-0f83e6ffc8cd.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/42984026-966c-4e9b-ae85-44067f5abcdb.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-compassionate-swanson-ea6761/deedf8c4-5e7c-48c7-9232-c90c965b1347.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-usecase0-drawio-engine-resume-cb705b/3609e734-1a66-43bd-8da7-1f241f34c0d4.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-compassionate-swanson-ea6761/59fe3773-78bd-4a22-af62-0c663f39c47e.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-ac27434546eeb7171.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-cost-optimization-3018d5/f1e63a73-f87d-4686-8377-51e942dfc3ee.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-aa9438c289007b50f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-pok-36-tfdt-measurement-1dcdba/8b95614d-17aa-4849-bff6-0f83e6ffc8cd/subagents/agent-aaeffc7be1670b556.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-ae2065a40fbb05a31.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-cost-optimization-3018d5/6cc870a0-e1ca-4364-9b13-6dee8838002b.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-a9567c790eed3f83d.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-a2ca25639b125675f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-adffef128c60bde2b.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-compassionate-swanson-ea6761/deedf8c4-5e7c-48c7-9232-c90c965b1347/subagents/agent-a92f433bfa05a3d2a.jsonl

exec
/bin/zsh -lc "rg --files /Users/kty/.claude/projects 2>/dev/null | rg 'kty-claude-harness-template|harness-template' | rg '\\.jsonl"'$'"' | head -40
rg -n -m 2 '\"type\":\"(queue-operation|attachment|last-prompt|custom-title)\"|\"type\": \"(queue-operation|attachment|last-prompt|custom-title)\"' /Users/kty/.claude/projects -g '*.jsonl' 2>/dev/null | head -80" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ab84b23f3991ca2ae.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a5cba032389c31bfc.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ab78c016f4bcc0471.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-afecf2f2dd17acd81.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a0d60126d7175891b.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a21b943ae1cfbcc9e.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ac49b42a24cfd5303.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a52f97fbe77cd839f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a35dd314eaff8e14c.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-aa9438c289007b50f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a04824dd33da1209d.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ae1718a170f039d83.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ab9dcd3e50e662b1f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a4775915200e87802.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a3d014da8357eaf89.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a17e2648f04ee9bb7.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a6160b595738bc153.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a870487cfcb8e42e0.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1/subagents/agent-a258301fce18bd612.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/69541816-ba99-427f-8dd9-3719d66a6367.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-af4c296b77dcb20d0.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-accfc8a4a03b8820a.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-ad0aa3d5adcfadd2c.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-a1a5c1491c0b920d7.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-a554410eeed5ea963.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-a80cf8702afecd760.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-a850eef3e4b6daabd.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-a8bfb38fff543821f.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/dcf0ad9d-d6e2-4807-80cd-d59361d34500/subagents/agent-a3056d8e951a41562.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-aaf4e0bf1b391fd33.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-ac4df20a67df6a7f9.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-a24ce5d854e64e4df.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-a61f1272e72b6d837.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-aff1b13f6c163161c.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-a4ac0e6fcc1761bc0.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-a83b06d15d3fe645c.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-ab9684cf47688ea9c.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-kty-harness-template-check-98b259/3cbcecba-3163-4933-b45b-fd827a3c9cea/subagents/agent-a6eed098c081ce2f3.jsonl
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-08-04T06:55:18.173Z","sessionId":"0740a10e-595a-45e6-a7d7-6476b9eb66a1","content":"https://github.com/dietrichgebert/ponytail 이것에 대해 분석해줘"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-08-04T06:55:18.236Z","sessionId":"0740a10e-595a-45e6-a7d7-6476b9eb66a1"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a21b943ae1cfbcc9e.jsonl:7:{"parentUuid":"002a4f72-552d-4c3e-9e51-86362e2f5351","isSidechain":true,"agentId":"a21b943ae1cfbcc9e","attachment":{"type":"read_truncation_notice","banner":"[Truncated: PARTIAL view — /private/tmp/claude-501/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/scratchpad/harness-layer/_workspace/03_impl_r1.diff: showing lines 1-600 of 808 total (28606 tokens, cap 25000). Call Read with offset=601 limit=600 for the next page, or Grep to find a specific section. Do NOT answer from this page alone if the answer may be further in the file.]","toolUseID":"toolu_01Nr9q1gtw5Dwg46HtMpJCHv"},"type":"attachment","uuid":"f22dbcdd-d6b6-4f1f-83f7-f7e4d2355e44","timestamp":"2026-08-06T05:17:08.192Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/pokeclip-mono/.claude/worktrees/kty-harness-template-readme-3cf068","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab","version":"2.1.219","gitBranch":"claude/adr-0006-knowledge-store-layer-f1c932"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-aa9438c289007b50f.jsonl:13:{"parentUuid":"f5970c5f-ad96-4bd3-8aea-d761ae591d88","isSidechain":true,"agentId":"aa9438c289007b50f","attachment":{"type":"read_truncation_notice","banner":"[Truncated: PARTIAL view — /private/tmp/claude-501/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/scratchpad/harness-layer/_workspace/03_impl_r1.diff: showing lines 1-600 of 808 total (28606 tokens, cap 25000). Call Read with offset=601 limit=600 for the next page, or Grep to find a specific section. Do NOT answer from this page alone if the answer may be further in the file.]","toolUseID":"toolu_014hFR7Ny9wi1EQ3T25RtB7V"},"type":"attachment","uuid":"a0319c34-d1b3-46bf-93c9-a5d562ee0adf","timestamp":"2026-08-06T05:33:10.664Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/pokeclip-mono/.claude/worktrees/kty-harness-template-readme-3cf068","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab","version":"2.1.219","gitBranch":"claude/adr-0006-knowledge-store-layer-f1c932"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/69541816-ba99-427f-8dd9-3719d66a6367.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-08-03T03:00:35.243Z","sessionId":"69541816-ba99-427f-8dd9-3719d66a6367","content":"kty-harness-template repo가서 전체적으로 구조파악 및 점검한다음에 readme.md 업데이트해줘"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/69541816-ba99-427f-8dd9-3719d66a6367.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-08-03T03:00:35.301Z","sessionId":"69541816-ba99-427f-8dd9-3719d66a6367"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-a6071ae06e30a8af1.jsonl:2:{"parentUuid":"5ecc5bfd-0e93-4668-b35f-34191d31cbc5","isSidechain":true,"agentId":"a6071ae06e30a8af1","attachment":{"type":"deferred_tools_delta","addedNames":["CronCreate","CronDelete","CronList","DesignSync","EnterWorktree","ExitWorktree","ListMcpResourcesTool","Monitor","PushNotification","ReadMcpResourceDirTool","ReadMcpResourceTool","RemoteTrigger","SendMessage","TaskCreate","TaskGet","TaskList","TaskStop","TaskUpdate","WebFetch","WebSearch","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__copy_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__create_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__download_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_metadata","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_permissions","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__list_recent_files","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__read_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__search_files","mcp__Claude_Code_iOS_Simulator__build","mcp__ccd_directory__request_directory","mcp__ccd_session_mgmt__archive_session","mcp__ccd_session_mgmt__get_session","mcp__ccd_session_mgmt__list_events","mcp__ccd_session_mgmt__list_sessions","mcp__ccd_session_mgmt__search_session_transcripts","mcp__ccd_session_mgmt__send_message","mcp__ccd_session_mgmt__set_session_title","mcp__claude-in-chrome__browser_batch","mcp__claude-in-chrome__computer","mcp__claude-in-chrome__file_upload","mcp__claude-in-chrome__find","mcp__claude-in-chrome__form_input","mcp__claude-in-chrome__get_page_text","mcp__claude-in-chrome__gif_creator","mcp__claude-in-chrome__javascript_tool","mcp__claude-in-chrome__list_connected_browsers","mcp__claude-in-chrome__navigate","mcp__claude-in-chrome__read_console_messages","mcp__claude-in-chrome__read_network_requests","mcp__claude-in-chrome__read_page","mcp__claude-in-chrome__resize_window","mcp__claude-in-chrome__select_browser","mcp__claude-in-chrome__shortcuts_execute","mcp__claude-in-chrome__shortcuts_list","mcp__claude-in-chrome__switch_browser","mcp__claude-in-chrome__tabs_close_mcp","mcp__claude-in-chrome__tabs_context_mcp","mcp__claude-in-chrome__tabs_create_mcp","mcp__claude-in-chrome__upload_image","mcp__codex__codex","mcp__codex__codex-reply","mcp__github__add_comment_to_pending_review","mcp__github__add_issue_comment","mcp__github__add_reply_to_pull_request_comment","mcp__github__create_branch","mcp__github__create_or_update_file","mcp__github__create_pull_request","mcp__github__create_repository","mcp__github__delete_file","mcp__github__fork_repository","mcp__github__get_commit","mcp__github__get_file_contents","mcp__github__get_label","mcp__github__get_latest_release","mcp__github__get_me","mcp__github__get_release_by_tag","mcp__github__get_tag","mcp__github__get_team_members","mcp__github__get_teams","mcp__github__issue_read","mcp__github__issue_write","mcp__github__list_branches","mcp__github__list_commits","mcp__github__list_issue_fields","mcp__github__list_issue_types","mcp__github__list_issues","mcp__github__list_pull_requests","mcp__github__list_releases","mcp__github__list_repository_collaborators","mcp__github__list_tags","mcp__github__merge_pull_request","mcp__github__pull_request_read","mcp__github__pull_request_review_write","mcp__github__push_files","mcp__github__request_copilot_review","mcp__github__run_secret_scanning","mcp__github__search_code","mcp__github__search_commits","mcp__github__search_issues","mcp__github__search_pull_requests","mcp__github__search_repositories","mcp__github__search_users","mcp__github__sub_issue_write","mcp__github__update_pull_request","mcp__github__update_pull_request_branch","mcp__mcp-registry__list_connectors","mcp__mcp-registry__search_mcp_registry","mcp__mcp-registry__suggest_connectors","mcp__plugin_ecc_chrome-devtools__click","mcp__plugin_ecc_chrome-devtools__close_page","mcp__plugin_ecc_chrome-devtools__drag","mcp__plugin_ecc_chrome-devtools__emulate","mcp__plugin_ecc_chrome-devtools__evaluate_script","mcp__plugin_ecc_chrome-devtools__fill","mcp__plugin_ecc_chrome-devtools__fill_form","mcp__plugin_ecc_chrome-devtools__get_console_message","mcp__plugin_ecc_chrome-devtools__get_network_request","mcp__plugin_ecc_chrome-devtools__handle_dialog","mcp__plugin_ecc_chrome-devtools__hover","mcp__plugin_ecc_chrome-devtools__lighthouse_audit","mcp__plugin_ecc_chrome-devtools__list_console_messages","mcp__plugin_ecc_chrome-devtools__list_network_requests","mcp__plugin_ecc_chrome-devtools__list_pages","mcp__plugin_ecc_chrome-devtools__navigate_page","mcp__plugin_ecc_chrome-devtools__new_page","mcp__plugin_ecc_chrome-devtools__performance_analyze_insight","mcp__plugin_ecc_chrome-devtools__performance_start_trace","mcp__plugin_ecc_chrome-devtools__performance_stop_trace","mcp__plugin_ecc_chrome-devtools__press_key","mcp__plugin_ecc_chrome-devtools__resize_page","mcp__plugin_ecc_chrome-devtools__select_page","mcp__plugin_ecc_chrome-devtools__take_heapsnapshot","mcp__plugin_ecc_chrome-devtools__take_screenshot","mcp__plugin_ecc_chrome-devtools__take_snapshot","mcp__plugin_ecc_chrome-devtools__type_text","mcp__plugin_ecc_chrome-devtools__upload_file","mcp__plugin_ecc_chrome-devtools__wait_for","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_backlinks","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_capture","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_get_skill","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_list_skills","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_read_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_save_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_search","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_update_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_validate_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_vault_health","mcp__scheduled-tasks__create_scheduled_task","mcp__scheduled-tasks__delete_scheduled_task","mcp__scheduled-tasks__list_scheduled_tasks","mcp__scheduled-tasks__update_scheduled_task"],"addedLines":["CronCreate","CronDelete","CronList","DesignSync","EnterWorktree","ExitWorktree","ListMcpResourcesTool","Monitor","PushNotification","ReadMcpResourceDirTool","ReadMcpResourceTool","RemoteTrigger","SendMessage","TaskCreate","TaskGet","TaskList","TaskStop","TaskUpdate","WebFetch","WebSearch","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__copy_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__create_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__download_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_metadata","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_permissions","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__list_recent_files","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__read_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__search_files","mcp__Claude_Code_iOS_Simulator__build","mcp__ccd_directory__request_directory","mcp__ccd_session_mgmt__archive_session","mcp__ccd_session_mgmt__get_session","mcp__ccd_session_mgmt__list_events","mcp__ccd_session_mgmt__list_sessions","mcp__ccd_session_mgmt__search_session_transcripts","mcp__ccd_session_mgmt__send_message","mcp__ccd_session_mgmt__set_session_title","mcp__claude-in-chrome__browser_batch","mcp__claude-in-chrome__computer","mcp__claude-in-chrome__file_upload","mcp__claude-in-chrome__find","mcp__claude-in-chrome__form_input","mcp__claude-in-chrome__get_page_text","mcp__claude-in-chrome__gif_creator","mcp__claude-in-chrome__javascript_tool","mcp__claude-in-chrome__list_connected_browsers","mcp__claude-in-chrome__navigate","mcp__claude-in-chrome__read_console_messages","mcp__claude-in-chrome__read_network_requests","mcp__claude-in-chrome__read_page","mcp__claude-in-chrome__resize_window","mcp__claude-in-chrome__select_browser","mcp__claude-in-chrome__shortcuts_execute","mcp__claude-in-chrome__shortcuts_list","mcp__claude-in-chrome__switch_browser","mcp__claude-in-chrome__tabs_close_mcp","mcp__claude-in-chrome__tabs_context_mcp","mcp__claude-in-chrome__tabs_create_mcp","mcp__claude-in-chrome__upload_image","mcp__codex__codex","mcp__codex__codex-reply","mcp__github__add_comment_to_pending_review","mcp__github__add_issue_comment","mcp__github__add_reply_to_pull_request_comment","mcp__github__create_branch","mcp__github__create_or_update_file","mcp__github__create_pull_request","mcp__github__create_repository","mcp__github__delete_file","mcp__github__fork_repository","mcp__github__get_commit","mcp__github__get_file_contents","mcp__github__get_label","mcp__github__get_latest_release","mcp__github__get_me","mcp__github__get_release_by_tag","mcp__github__get_tag","mcp__github__get_team_members","mcp__github__get_teams","mcp__github__issue_read","mcp__github__issue_write","mcp__github__list_branches","mcp__github__list_commits","mcp__github__list_issue_fields","mcp__github__list_issue_types","mcp__github__list_issues","mcp__github__list_pull_requests","mcp__github__list_releases","mcp__github__list_repository_collaborators","mcp__github__list_tags","mcp__github__merge_pull_request","mcp__github__pull_request_read","mcp__github__pull_request_review_write","mcp__github__push_files","mcp__github__request_copilot_review","mcp__github__run_secret_scanning","mcp__github__search_code","mcp__github__search_commits","mcp__github__search_issues","mcp__github__search_pull_requests","mcp__github__search_repositories","mcp__github__search_users","mcp__github__sub_issue_write","mcp__github__update_pull_request","mcp__github__update_pull_request_branch","mcp__mcp-registry__list_connectors","mcp__mcp-registry__search_mcp_registry","mcp__mcp-registry__suggest_connectors","mcp__plugin_ecc_chrome-devtools__click","mcp__plugin_ecc_chrome-devtools__close_page","mcp__plugin_ecc_chrome-devtools__drag","mcp__plugin_ecc_chrome-devtools__emulate","mcp__plugin_ecc_chrome-devtools__evaluate_script","mcp__plugin_ecc_chrome-devtools__fill","mcp__plugin_ecc_chrome-devtools__fill_form","mcp__plugin_ecc_chrome-devtools__get_console_message","mcp__plugin_ecc_chrome-devtools__get_network_request","mcp__plugin_ecc_chrome-devtools__handle_dialog","mcp__plugin_ecc_chrome-devtools__hover","mcp__plugin_ecc_chrome-devtools__lighthouse_audit","mcp__plugin_ecc_chrome-devtools__list_console_messages","mcp__plugin_ecc_chrome-devtools__list_network_requests","mcp__plugin_ecc_chrome-devtools__list_pages","mcp__plugin_ecc_chrome-devtools__navigate_page","mcp__plugin_ecc_chrome-devtools__new_page","mcp__plugin_ecc_chrome-devtools__performance_analyze_insight","mcp__plugin_ecc_chrome-devtools__performance_start_trace","mcp__plugin_ecc_chrome-devtools__performance_stop_trace","mcp__plugin_ecc_chrome-devtools__press_key","mcp__plugin_ecc_chrome-devtools__resize_page","mcp__plugin_ecc_chrome-devtools__select_page","mcp__plugin_ecc_chrome-devtools__take_heapsnapshot","mcp__plugin_ecc_chrome-devtools__take_screenshot","mcp__plugin_ecc_chrome-devtools__take_snapshot","mcp__plugin_ecc_chrome-devtools__type_text","mcp__plugin_ecc_chrome-devtools__upload_file","mcp__plugin_ecc_chrome-devtools__wait_for","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_backlinks","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_capture","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_get_skill","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_list_skills","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_read_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_save_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_search","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_update_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_validate_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_vault_health","mcp__scheduled-tasks__create_scheduled_task","mcp__scheduled-tasks__delete_scheduled_task","mcp__scheduled-tasks__list_scheduled_tasks","mcp__scheduled-tasks__update_scheduled_task"],"removedNames":[],"readdedNames":[]},"type":"attachment","uuid":"159dcf67-2a16-45e1-8811-1f09725792a2","timestamp":"2026-07-22T23:43:11.776Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/pokeclip-obs-plugin-architecture-784960","sessionId":"edbe3e2c-711c-4f90-8f8c-b9a3f2c27994","version":"2.1.217","gitBranch":"claude/pokeclip-obs-plugin-architecture-784960","slug":"github-private-repo-atomic-dahl"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-a6071ae06e30a8af1.jsonl:3:{"parentUuid":"159dcf67-2a16-45e1-8811-1f09725792a2","isSidechain":true,"agentId":"a6071ae06e30a8af1","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.\n- plan-prd: Generate a lean, problem-first PRD and hand off to /plan for implementation planning.\n- pm2: Analyze a project and generate PM2 service commands for detected frontend, backend, or database services.\n- pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- project-init: Detect a project's stack and produce a dry-run ECC onboarding plan using the repository's install manifests and stack mappings.\n- projects: List known projects and their instinct statistics\n- promote: Promote project-scoped instincts to global scope\n- prp-commit: Quick commit with natural language file targeting — describe what to commit in plain English\n- prp-implement: Execute an implementation plan with rigorous validation loops\n- prp-plan: Create comprehensive feature implementation plan with codebase analysis and pattern extraction\n- prp-pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- prp-prd: Interactive PRD generator - problem-first, hypothesis-driven product spec with back-and-forth questioning\n- prune: Delete pending instincts older than 30 days that were never promoted\n- python-review: Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent.\n- quality-gate: Run the ECC formatter quality gate for a single file and report remediation steps.\n- react-build: Fix React build failures (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) incrementally — JSX/TSX compile errors, hydration mismatches, server/client component boundary failures, missing types. Invokes the react-build-resolver agent for minimal, surgical fixes.\n- react-review: Comprehensive React/JSX code review for hook correctness, render performance, server/client component boundaries, accessibility, and React-specific security. Invokes the react-reviewer agent (and typescript-reviewer alongside on TSX/JSX changes).\n- react-test: Enforce TDD workflow for React. Write React Testing Library tests first (behavior-focused, accessibility-first), then implement components. Detects Vitest or Jest and verifies coverage targets.\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- deep-research: Deep research harness — fan-out web searches, fetch sources, adversarially verify claims, synthesize a cited report. - When the user wants a deep, multi-source, fact-checked research report on any topic. BEFORE invoking, check if the question is specific enough to research directly — if underspecified (e.g., \"what car to buy\" without budget/use-case/region), ask 2-3 clarifying questions to narrow scope. Then pass the refined question as args, weaving the answers in.\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure: Enable or disable hookify rules interactively\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf\n- anthropic-skills:pptx\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":542,"isInitial":true,"names":["find-skills","harness-orchestrator","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","deep-research","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"8095adc2-b989-4a94-a01a-dd72541e2fdb","timestamp":"2026-07-22T23:43:11.777Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/pokeclip-obs-plugin-architecture-784960","sessionId":"edbe3e2c-711c-4f90-8f8c-b9a3f2c27994","version":"2.1.217","gitBranch":"claude/pokeclip-obs-plugin-architecture-784960","slug":"github-private-repo-atomic-dahl"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-af8cadf509a8ce137.jsonl:2:{"parentUuid":"b82625a9-c20d-4794-af93-0529a01cc643","isSidechain":true,"agentId":"af8cadf509a8ce137","attachment":{"type":"deferred_tools_delta","addedNames":["CronCreate","CronDelete","CronList","DesignSync","EnterWorktree","ExitWorktree","ListMcpResourcesTool","Monitor","PushNotification","ReadMcpResourceDirTool","ReadMcpResourceTool","RemoteTrigger","SendMessage","TaskCreate","TaskGet","TaskList","TaskStop","TaskUpdate","WebFetch","WebSearch","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__copy_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__create_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__download_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_metadata","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_permissions","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__list_recent_files","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__read_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__search_files","mcp__Claude_Code_iOS_Simulator__build","mcp__ccd_directory__request_directory","mcp__ccd_session_mgmt__archive_session","mcp__ccd_session_mgmt__get_session","mcp__ccd_session_mgmt__list_events","mcp__ccd_session_mgmt__list_sessions","mcp__ccd_session_mgmt__search_session_transcripts","mcp__ccd_session_mgmt__send_message","mcp__ccd_session_mgmt__set_session_title","mcp__claude-in-chrome__browser_batch","mcp__claude-in-chrome__computer","mcp__claude-in-chrome__file_upload","mcp__claude-in-chrome__find","mcp__claude-in-chrome__form_input","mcp__claude-in-chrome__get_page_text","mcp__claude-in-chrome__gif_creator","mcp__claude-in-chrome__javascript_tool","mcp__claude-in-chrome__list_connected_browsers","mcp__claude-in-chrome__navigate","mcp__claude-in-chrome__read_console_messages","mcp__claude-in-chrome__read_network_requests","mcp__claude-in-chrome__read_page","mcp__claude-in-chrome__resize_window","mcp__claude-in-chrome__select_browser","mcp__claude-in-chrome__shortcuts_execute","mcp__claude-in-chrome__shortcuts_list","mcp__claude-in-chrome__switch_browser","mcp__claude-in-chrome__tabs_close_mcp","mcp__claude-in-chrome__tabs_context_mcp","mcp__claude-in-chrome__tabs_create_mcp","mcp__claude-in-chrome__upload_image","mcp__codex__codex","mcp__codex__codex-reply","mcp__github__add_comment_to_pending_review","mcp__github__add_issue_comment","mcp__github__add_reply_to_pull_request_comment","mcp__github__create_branch","mcp__github__create_or_update_file","mcp__github__create_pull_request","mcp__github__create_repository","mcp__github__delete_file","mcp__github__fork_repository","mcp__github__get_commit","mcp__github__get_file_contents","mcp__github__get_label","mcp__github__get_latest_release","mcp__github__get_me","mcp__github__get_release_by_tag","mcp__github__get_tag","mcp__github__get_team_members","mcp__github__get_teams","mcp__github__issue_read","mcp__github__issue_write","mcp__github__list_branches","mcp__github__list_commits","mcp__github__list_issue_fields","mcp__github__list_issue_types","mcp__github__list_issues","mcp__github__list_pull_requests","mcp__github__list_releases","mcp__github__list_repository_collaborators","mcp__github__list_tags","mcp__github__merge_pull_request","mcp__github__pull_request_read","mcp__github__pull_request_review_write","mcp__github__push_files","mcp__github__request_copilot_review","mcp__github__run_secret_scanning","mcp__github__search_code","mcp__github__search_commits","mcp__github__search_issues","mcp__github__search_pull_requests","mcp__github__search_repositories","mcp__github__search_users","mcp__github__sub_issue_write","mcp__github__update_pull_request","mcp__github__update_pull_request_branch","mcp__mcp-registry__list_connectors","mcp__mcp-registry__search_mcp_registry","mcp__mcp-registry__suggest_connectors","mcp__plugin_ecc_chrome-devtools__click","mcp__plugin_ecc_chrome-devtools__close_page","mcp__plugin_ecc_chrome-devtools__drag","mcp__plugin_ecc_chrome-devtools__emulate","mcp__plugin_ecc_chrome-devtools__evaluate_script","mcp__plugin_ecc_chrome-devtools__fill","mcp__plugin_ecc_chrome-devtools__fill_form","mcp__plugin_ecc_chrome-devtools__get_console_message","mcp__plugin_ecc_chrome-devtools__get_network_request","mcp__plugin_ecc_chrome-devtools__handle_dialog","mcp__plugin_ecc_chrome-devtools__hover","mcp__plugin_ecc_chrome-devtools__lighthouse_audit","mcp__plugin_ecc_chrome-devtools__list_console_messages","mcp__plugin_ecc_chrome-devtools__list_network_requests","mcp__plugin_ecc_chrome-devtools__list_pages","mcp__plugin_ecc_chrome-devtools__navigate_page","mcp__plugin_ecc_chrome-devtools__new_page","mcp__plugin_ecc_chrome-devtools__performance_analyze_insight","mcp__plugin_ecc_chrome-devtools__performance_start_trace","mcp__plugin_ecc_chrome-devtools__performance_stop_trace","mcp__plugin_ecc_chrome-devtools__press_key","mcp__plugin_ecc_chrome-devtools__resize_page","mcp__plugin_ecc_chrome-devtools__select_page","mcp__plugin_ecc_chrome-devtools__take_heapsnapshot","mcp__plugin_ecc_chrome-devtools__take_screenshot","mcp__plugin_ecc_chrome-devtools__take_snapshot","mcp__plugin_ecc_chrome-devtools__type_text","mcp__plugin_ecc_chrome-devtools__upload_file","mcp__plugin_ecc_chrome-devtools__wait_for","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_backlinks","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_capture","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_get_skill","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_list_skills","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_read_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_save_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_search","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_update_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_validate_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_vault_health","mcp__scheduled-tasks__create_scheduled_task","mcp__scheduled-tasks__delete_scheduled_task","mcp__scheduled-tasks__list_scheduled_tasks","mcp__scheduled-tasks__update_scheduled_task"],"addedLines":["CronCreate","CronDelete","CronList","DesignSync","EnterWorktree","ExitWorktree","ListMcpResourcesTool","Monitor","PushNotification","ReadMcpResourceDirTool","ReadMcpResourceTool","RemoteTrigger","SendMessage","TaskCreate","TaskGet","TaskList","TaskStop","TaskUpdate","WebFetch","WebSearch","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__copy_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__create_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__download_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_metadata","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_permissions","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__list_recent_files","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__read_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__search_files","mcp__Claude_Code_iOS_Simulator__build","mcp__ccd_directory__request_directory","mcp__ccd_session_mgmt__archive_session","mcp__ccd_session_mgmt__get_session","mcp__ccd_session_mgmt__list_events","mcp__ccd_session_mgmt__list_sessions","mcp__ccd_session_mgmt__search_session_transcripts","mcp__ccd_session_mgmt__send_message","mcp__ccd_session_mgmt__set_session_title","mcp__claude-in-chrome__browser_batch","mcp__claude-in-chrome__computer","mcp__claude-in-chrome__file_upload","mcp__claude-in-chrome__find","mcp__claude-in-chrome__form_input","mcp__claude-in-chrome__get_page_text","mcp__claude-in-chrome__gif_creator","mcp__claude-in-chrome__javascript_tool","mcp__claude-in-chrome__list_connected_browsers","mcp__claude-in-chrome__navigate","mcp__claude-in-chrome__read_console_messages","mcp__claude-in-chrome__read_network_requests","mcp__claude-in-chrome__read_page","mcp__claude-in-chrome__resize_window","mcp__claude-in-chrome__select_browser","mcp__claude-in-chrome__shortcuts_execute","mcp__claude-in-chrome__shortcuts_list","mcp__claude-in-chrome__switch_browser","mcp__claude-in-chrome__tabs_close_mcp","mcp__claude-in-chrome__tabs_context_mcp","mcp__claude-in-chrome__tabs_create_mcp","mcp__claude-in-chrome__upload_image","mcp__codex__codex","mcp__codex__codex-reply","mcp__github__add_comment_to_pending_review","mcp__github__add_issue_comment","mcp__github__add_reply_to_pull_request_comment","mcp__github__create_branch","mcp__github__create_or_update_file","mcp__github__create_pull_request","mcp__github__create_repository","mcp__github__delete_file","mcp__github__fork_repository","mcp__github__get_commit","mcp__github__get_file_contents","mcp__github__get_label","mcp__github__get_latest_release","mcp__github__get_me","mcp__github__get_release_by_tag","mcp__github__get_tag","mcp__github__get_team_members","mcp__github__get_teams","mcp__github__issue_read","mcp__github__issue_write","mcp__github__list_branches","mcp__github__list_commits","mcp__github__list_issue_fields","mcp__github__list_issue_types","mcp__github__list_issues","mcp__github__list_pull_requests","mcp__github__list_releases","mcp__github__list_repository_collaborators","mcp__github__list_tags","mcp__github__merge_pull_request","mcp__github__pull_request_read","mcp__github__pull_request_review_write","mcp__github__push_files","mcp__github__request_copilot_review","mcp__github__run_secret_scanning","mcp__github__search_code","mcp__github__search_commits","mcp__github__search_issues","mcp__github__search_pull_requests","mcp__github__search_repositories","mcp__github__search_users","mcp__github__sub_issue_write","mcp__github__update_pull_request","mcp__github__update_pull_request_branch","mcp__mcp-registry__list_connectors","mcp__mcp-registry__search_mcp_registry","mcp__mcp-registry__suggest_connectors","mcp__plugin_ecc_chrome-devtools__click","mcp__plugin_ecc_chrome-devtools__close_page","mcp__plugin_ecc_chrome-devtools__drag","mcp__plugin_ecc_chrome-devtools__emulate","mcp__plugin_ecc_chrome-devtools__evaluate_script","mcp__plugin_ecc_chrome-devtools__fill","mcp__plugin_ecc_chrome-devtools__fill_form","mcp__plugin_ecc_chrome-devtools__get_console_message","mcp__plugin_ecc_chrome-devtools__get_network_request","mcp__plugin_ecc_chrome-devtools__handle_dialog","mcp__plugin_ecc_chrome-devtools__hover","mcp__plugin_ecc_chrome-devtools__lighthouse_audit","mcp__plugin_ecc_chrome-devtools__list_console_messages","mcp__plugin_ecc_chrome-devtools__list_network_requests","mcp__plugin_ecc_chrome-devtools__list_pages","mcp__plugin_ecc_chrome-devtools__navigate_page","mcp__plugin_ecc_chrome-devtools__new_page","mcp__plugin_ecc_chrome-devtools__performance_analyze_insight","mcp__plugin_ecc_chrome-devtools__performance_start_trace","mcp__plugin_ecc_chrome-devtools__performance_stop_trace","mcp__plugin_ecc_chrome-devtools__press_key","mcp__plugin_ecc_chrome-devtools__resize_page","mcp__plugin_ecc_chrome-devtools__select_page","mcp__plugin_ecc_chrome-devtools__take_heapsnapshot","mcp__plugin_ecc_chrome-devtools__take_screenshot","mcp__plugin_ecc_chrome-devtools__take_snapshot","mcp__plugin_ecc_chrome-devtools__type_text","mcp__plugin_ecc_chrome-devtools__upload_file","mcp__plugin_ecc_chrome-devtools__wait_for","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_backlinks","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_capture","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_get_skill","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_list_skills","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_read_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_save_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_search","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_update_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_validate_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_vault_health","mcp__scheduled-tasks__create_scheduled_task","mcp__scheduled-tasks__delete_scheduled_task","mcp__scheduled-tasks__list_scheduled_tasks","mcp__scheduled-tasks__update_scheduled_task"],"removedNames":[],"readdedNames":[]},"type":"attachment","uuid":"a0d92a7d-18ae-4f75-b3bd-c28900eee7f8","timestamp":"2026-07-23T00:13:38.466Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/pokeclip-obs-plugin-architecture-784960","sessionId":"edbe3e2c-711c-4f90-8f8c-b9a3f2c27994","version":"2.1.217","gitBranch":"claude/pokeclip-obs-plugin-architecture-784960","slug":"github-private-repo-atomic-dahl"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-af8cadf509a8ce137.jsonl:3:{"parentUuid":"a0d92a7d-18ae-4f75-b3bd-c28900eee7f8","isSidechain":true,"agentId":"af8cadf509a8ce137","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.\n- plan-prd: Generate a lean, problem-first PRD and hand off to /plan for implementation planning.\n- pm2: Analyze a project and generate PM2 service commands for detected frontend, backend, or database services.\n- pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- project-init: Detect a project's stack and produce a dry-run ECC onboarding plan using the repository's install manifests and stack mappings.\n- projects: List known projects and their instinct statistics\n- promote: Promote project-scoped instincts to global scope\n- prp-commit: Quick commit with natural language file targeting — describe what to commit in plain English\n- prp-implement: Execute an implementation plan with rigorous validation loops\n- prp-plan: Create comprehensive feature implementation plan with codebase analysis and pattern extraction\n- prp-pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- prp-prd: Interactive PRD generator - problem-first, hypothesis-driven product spec with back-and-forth questioning\n- prune: Delete pending instincts older than 30 days that were never promoted\n- python-review: Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent.\n- quality-gate: Run the ECC formatter quality gate for a single file and report remediation steps.\n- react-build: Fix React build failures (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) incrementally — JSX/TSX compile errors, hydration mismatches, server/client component boundary failures, missing types. Invokes the react-build-resolver agent for minimal, surgical fixes.\n- react-review: Comprehensive React/JSX code review for hook correctness, render performance, server/client component boundaries, accessibility, and React-specific security. Invokes the react-reviewer agent (and typescript-reviewer alongside on TSX/JSX changes).\n- react-test: Enforce TDD workflow for React. Write React Testing Library tests first (behavior-focused, accessibility-first), then implement components. Detects Vitest or Jest and verifies coverage targets.\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- deep-research: Deep research harness — fan-out web searches, fetch sources, adversarially verify claims, synthesize a cited report. - When the user wants a deep, multi-source, fact-checked research report on any topic. BEFORE invoking, check if the question is specific enough to research directly — if underspecified (e.g., \"what car to buy\" without budget/use-case/region), ask 2-3 clarifying questions to narrow scope. Then pass the refined question as args, weaving the answers in.\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure: Enable or disable hookify rules interactively\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf\n- anthropic-skills:pptx\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":542,"isInitial":true,"names":["find-skills","harness-orchestrator","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","deep-research","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"32c8995e-ef1d-47d7-a30c-c946c0c581e5","timestamp":"2026-07-23T00:13:38.470Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/pokeclip-obs-plugin-architecture-784960","sessionId":"edbe3e2c-711c-4f90-8f8c-b9a3f2c27994","version":"2.1.217","gitBranch":"claude/pokeclip-obs-plugin-architecture-784960","slug":"github-private-repo-atomic-dahl"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-a3d4264400b5b23d5.jsonl:2:{"parentUuid":"10636808-84e9-452a-a94f-4f7f97dd85be","isSidechain":true,"agentId":"a3d4264400b5b23d5","attachment":{"type":"deferred_tools_delta","addedNames":["CronCreate","CronDelete","CronList","DesignSync","EnterWorktree","ExitWorktree","ListMcpResourcesTool","Monitor","PushNotification","ReadMcpResourceDirTool","ReadMcpResourceTool","RemoteTrigger","SendMessage","TaskCreate","TaskGet","TaskList","TaskStop","TaskUpdate","WebFetch","WebSearch","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__copy_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__create_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__download_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_metadata","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_permissions","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__list_recent_files","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__read_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__search_files","mcp__Claude_Code_iOS_Simulator__build","mcp__ccd_directory__request_directory","mcp__ccd_session_mgmt__archive_session","mcp__ccd_session_mgmt__get_session","mcp__ccd_session_mgmt__list_events","mcp__ccd_session_mgmt__list_sessions","mcp__ccd_session_mgmt__search_session_transcripts","mcp__ccd_session_mgmt__send_message","mcp__ccd_session_mgmt__set_session_title","mcp__claude-in-chrome__browser_batch","mcp__claude-in-chrome__computer","mcp__claude-in-chrome__file_upload","mcp__claude-in-chrome__find","mcp__claude-in-chrome__form_input","mcp__claude-in-chrome__get_page_text","mcp__claude-in-chrome__gif_creator","mcp__claude-in-chrome__javascript_tool","mcp__claude-in-chrome__list_connected_browsers","mcp__claude-in-chrome__navigate","mcp__claude-in-chrome__read_console_messages","mcp__claude-in-chrome__read_network_requests","mcp__claude-in-chrome__read_page","mcp__claude-in-chrome__resize_window","mcp__claude-in-chrome__select_browser","mcp__claude-in-chrome__shortcuts_execute","mcp__claude-in-chrome__shortcuts_list","mcp__claude-in-chrome__switch_browser","mcp__claude-in-chrome__tabs_close_mcp","mcp__claude-in-chrome__tabs_context_mcp","mcp__claude-in-chrome__tabs_create_mcp","mcp__claude-in-chrome__upload_image","mcp__codex__codex","mcp__codex__codex-reply","mcp__github__add_comment_to_pending_review","mcp__github__add_issue_comment","mcp__github__add_reply_to_pull_request_comment","mcp__github__create_branch","mcp__github__create_or_update_file","mcp__github__create_pull_request","mcp__github__create_repository","mcp__github__delete_file","mcp__github__fork_repository","mcp__github__get_commit","mcp__github__get_file_contents","mcp__github__get_label","mcp__github__get_latest_release","mcp__github__get_me","mcp__github__get_release_by_tag","mcp__github__get_tag","mcp__github__get_team_members","mcp__github__get_teams","mcp__github__issue_read","mcp__github__issue_write","mcp__github__list_branches","mcp__github__list_commits","mcp__github__list_issue_fields","mcp__github__list_issue_types","mcp__github__list_issues","mcp__github__list_pull_requests","mcp__github__list_releases","mcp__github__list_repository_collaborators","mcp__github__list_tags","mcp__github__merge_pull_request","mcp__github__pull_request_read","mcp__github__pull_request_review_write","mcp__github__push_files","mcp__github__request_copilot_review","mcp__github__run_secret_scanning","mcp__github__search_code","mcp__github__search_commits","mcp__github__search_issues","mcp__github__search_pull_requests","mcp__github__search_repositories","mcp__github__search_users","mcp__github__sub_issue_write","mcp__github__update_pull_request","mcp__github__update_pull_request_branch","mcp__mcp-registry__list_connectors","mcp__mcp-registry__search_mcp_registry","mcp__mcp-registry__suggest_connectors","mcp__plugin_ecc_chrome-devtools__click","mcp__plugin_ecc_chrome-devtools__close_page","mcp__plugin_ecc_chrome-devtools__drag","mcp__plugin_ecc_chrome-devtools__emulate","mcp__plugin_ecc_chrome-devtools__evaluate_script","mcp__plugin_ecc_chrome-devtools__fill","mcp__plugin_ecc_chrome-devtools__fill_form","mcp__plugin_ecc_chrome-devtools__get_console_message","mcp__plugin_ecc_chrome-devtools__get_network_request","mcp__plugin_ecc_chrome-devtools__handle_dialog","mcp__plugin_ecc_chrome-devtools__hover","mcp__plugin_ecc_chrome-devtools__lighthouse_audit","mcp__plugin_ecc_chrome-devtools__list_console_messages","mcp__plugin_ecc_chrome-devtools__list_network_requests","mcp__plugin_ecc_chrome-devtools__list_pages","mcp__plugin_ecc_chrome-devtools__navigate_page","mcp__plugin_ecc_chrome-devtools__new_page","mcp__plugin_ecc_chrome-devtools__performance_analyze_insight","mcp__plugin_ecc_chrome-devtools__performance_start_trace","mcp__plugin_ecc_chrome-devtools__performance_stop_trace","mcp__plugin_ecc_chrome-devtools__press_key","mcp__plugin_ecc_chrome-devtools__resize_page","mcp__plugin_ecc_chrome-devtools__select_page","mcp__plugin_ecc_chrome-devtools__take_heapsnapshot","mcp__plugin_ecc_chrome-devtools__take_screenshot","mcp__plugin_ecc_chrome-devtools__take_snapshot","mcp__plugin_ecc_chrome-devtools__type_text","mcp__plugin_ecc_chrome-devtools__upload_file","mcp__plugin_ecc_chrome-devtools__wait_for","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_backlinks","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_capture","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_get_skill","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_list_skills","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_read_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_save_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_search","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_update_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_validate_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_vault_health","mcp__scheduled-tasks__create_scheduled_task","mcp__scheduled-tasks__delete_scheduled_task","mcp__scheduled-tasks__list_scheduled_tasks","mcp__scheduled-tasks__update_scheduled_task"],"addedLines":["CronCreate","CronDelete","CronList","DesignSync","EnterWorktree","ExitWorktree","ListMcpResourcesTool","Monitor","PushNotification","ReadMcpResourceDirTool","ReadMcpResourceTool","RemoteTrigger","SendMessage","TaskCreate","TaskGet","TaskList","TaskStop","TaskUpdate","WebFetch","WebSearch","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__copy_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__create_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__download_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_metadata","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_permissions","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__list_recent_files","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__read_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__search_files","mcp__Claude_Code_iOS_Simulator__build","mcp__ccd_directory__request_directory","mcp__ccd_session_mgmt__archive_session","mcp__ccd_session_mgmt__get_session","mcp__ccd_session_mgmt__list_events","mcp__ccd_session_mgmt__list_sessions","mcp__ccd_session_mgmt__search_session_transcripts","mcp__ccd_session_mgmt__send_message","mcp__ccd_session_mgmt__set_session_title","mcp__claude-in-chrome__browser_batch","mcp__claude-in-chrome__computer","mcp__claude-in-chrome__file_upload","mcp__claude-in-chrome__find","mcp__claude-in-chrome__form_input","mcp__claude-in-chrome__get_page_text","mcp__claude-in-chrome__gif_creator","mcp__claude-in-chrome__javascript_tool","mcp__claude-in-chrome__list_connected_browsers","mcp__claude-in-chrome__navigate","mcp__claude-in-chrome__read_console_messages","mcp__claude-in-chrome__read_network_requests","mcp__claude-in-chrome__read_page","mcp__claude-in-chrome__resize_window","mcp__claude-in-chrome__select_browser","mcp__claude-in-chrome__shortcuts_execute","mcp__claude-in-chrome__shortcuts_list","mcp__claude-in-chrome__switch_browser","mcp__claude-in-chrome__tabs_close_mcp","mcp__claude-in-chrome__tabs_context_mcp","mcp__claude-in-chrome__tabs_create_mcp","mcp__claude-in-chrome__upload_image","mcp__codex__codex","mcp__codex__codex-reply","mcp__github__add_comment_to_pending_review","mcp__github__add_issue_comment","mcp__github__add_reply_to_pull_request_comment","mcp__github__create_branch","mcp__github__create_or_update_file","mcp__github__create_pull_request","mcp__github__create_repository","mcp__github__delete_file","mcp__github__fork_repository","mcp__github__get_commit","mcp__github__get_file_contents","mcp__github__get_label","mcp__github__get_latest_release","mcp__github__get_me","mcp__github__get_release_by_tag","mcp__github__get_tag","mcp__github__get_team_members","mcp__github__get_teams","mcp__github__issue_read","mcp__github__issue_write","mcp__github__list_branches","mcp__github__list_commits","mcp__github__list_issue_fields","mcp__github__list_issue_types","mcp__github__list_issues","mcp__github__list_pull_requests","mcp__github__list_releases","mcp__github__list_repository_collaborators","mcp__github__list_tags","mcp__github__merge_pull_request","mcp__github__pull_request_read","mcp__github__pull_request_review_write","mcp__github__push_files","mcp__github__request_copilot_review","mcp__github__run_secret_scanning","mcp__github__search_code","mcp__github__search_commits","mcp__github__search_issues","mcp__github__search_pull_requests","mcp__github__search_repositories","mcp__github__search_users","mcp__github__sub_issue_write","mcp__github__update_pull_request","mcp__github__update_pull_request_branch","mcp__mcp-registry__list_connectors","mcp__mcp-registry__search_mcp_registry","mcp__mcp-registry__suggest_connectors","mcp__plugin_ecc_chrome-devtools__click","mcp__plugin_ecc_chrome-devtools__close_page","mcp__plugin_ecc_chrome-devtools__drag","mcp__plugin_ecc_chrome-devtools__emulate","mcp__plugin_ecc_chrome-devtools__evaluate_script","mcp__plugin_ecc_chrome-devtools__fill","mcp__plugin_ecc_chrome-devtools__fill_form","mcp__plugin_ecc_chrome-devtools__get_console_message","mcp__plugin_ecc_chrome-devtools__get_network_request","mcp__plugin_ecc_chrome-devtools__handle_dialog","mcp__plugin_ecc_chrome-devtools__hover","mcp__plugin_ecc_chrome-devtools__lighthouse_audit","mcp__plugin_ecc_chrome-devtools__list_console_messages","mcp__plugin_ecc_chrome-devtools__list_network_requests","mcp__plugin_ecc_chrome-devtools__list_pages","mcp__plugin_ecc_chrome-devtools__navigate_page","mcp__plugin_ecc_chrome-devtools__new_page","mcp__plugin_ecc_chrome-devtools__performance_analyze_insight","mcp__plugin_ecc_chrome-devtools__performance_start_trace","mcp__plugin_ecc_chrome-devtools__performance_stop_trace","mcp__plugin_ecc_chrome-devtools__press_key","mcp__plugin_ecc_chrome-devtools__resize_page","mcp__plugin_ecc_chrome-devtools__select_page","mcp__plugin_ecc_chrome-devtools__take_heapsnapshot","mcp__plugin_ecc_chrome-devtools__take_screenshot","mcp__plugin_ecc_chrome-devtools__take_snapshot","mcp__plugin_ecc_chrome-devtools__type_text","mcp__plugin_ecc_chrome-devtools__upload_file","mcp__plugin_ecc_chrome-devtools__wait_for","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_backlinks","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_capture","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_get_skill","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_list_skills","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_read_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_save_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_search","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_update_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_validate_note","mcp__plugin_obsidian-second-brain_obsidian-second-brain__obsidian_vault_health","mcp__scheduled-tasks__create_scheduled_task","mcp__scheduled-tasks__delete_scheduled_task","mcp__scheduled-tasks__list_scheduled_tasks","mcp__scheduled-tasks__update_scheduled_task"],"removedNames":[],"readdedNames":[]},"type":"attachment","uuid":"0cd05a51-c6d8-4846-9aed-d17a34e42afa","timestamp":"2026-07-22T23:43:27.602Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/pokeclip-obs-plugin-architecture-784960","sessionId":"edbe3e2c-711c-4f90-8f8c-b9a3f2c27994","version":"2.1.217","gitBranch":"claude/pokeclip-obs-plugin-architecture-784960","slug":"github-private-repo-atomic-dahl"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994/subagents/agent-a3d4264400b5b23d5.jsonl:3:{"parentUuid":"0cd05a51-c6d8-4846-9aed-d17a34e42afa","isSidechain":true,"agentId":"a3d4264400b5b23d5","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.\n- plan-prd: Generate a lean, problem-first PRD and hand off to /plan for implementation planning.\n- pm2: Analyze a project and generate PM2 service commands for detected frontend, backend, or database services.\n- pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- project-init: Detect a project's stack and produce a dry-run ECC onboarding plan using the repository's install manifests and stack mappings.\n- projects: List known projects and their instinct statistics\n- promote: Promote project-scoped instincts to global scope\n- prp-commit: Quick commit with natural language file targeting — describe what to commit in plain English\n- prp-implement: Execute an implementation plan with rigorous validation loops\n- prp-plan: Create comprehensive feature implementation plan with codebase analysis and pattern extraction\n- prp-pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- prp-prd: Interactive PRD generator - problem-first, hypothesis-driven product spec with back-and-forth questioning\n- prune: Delete pending instincts older than 30 days that were never promoted\n- python-review: Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent.\n- quality-gate: Run the ECC formatter quality gate for a single file and report remediation steps.\n- react-build: Fix React build failures (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) incrementally — JSX/TSX compile errors, hydration mismatches, server/client component boundary failures, missing types. Invokes the react-build-resolver agent for minimal, surgical fixes.\n- react-review: Comprehensive React/JSX code review for hook correctness, render performance, server/client component boundaries, accessibility, and React-specific security. Invokes the react-reviewer agent (and typescript-reviewer alongside on TSX/JSX changes).\n- react-test: Enforce TDD workflow for React. Write React Testing Library tests first (behavior-focused, accessibility-first), then implement components. Detects Vitest or Jest and verifies coverage targets.\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- deep-research: Deep research harness — fan-out web searches, fetch sources, adversarially verify claims, synthesize a cited report. - When the user wants a deep, multi-source, fact-checked research report on any topic. BEFORE invoking, check if the question is specific enough to research directly — if underspecified (e.g., \"what car to buy\" without budget/use-case/region), ask 2-3 clarifying questions to narrow scope. Then pass the refined question as args, weaving the answers in.\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure: Enable or disable hookify rules interactively\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf\n- anthropic-skills:pptx\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":542,"isInitial":true,"names":["find-skills","harness-orchestrator","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","deep-research","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"7438616c-4e95-49fa-83ca-cea59751b2ef","timestamp":"2026-07-22T23:43:27.604Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/pokeclip-obs-plugin-architecture-784960","sessionId":"edbe3e2c-711c-4f90-8f8c-b9a3f2c27994","version":"2.1.217","gitBranch":"claude/pokeclip-obs-plugin-architecture-784960","slug":"github-private-repo-atomic-dahl"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-22T23:40:52.918Z","sessionId":"edbe3e2c-711c-4f90-8f8c-b9a3f2c27994","content":"github에 private으로 repo하나 만들어 pokeclip-obs-plugin으로 pokeclip-architecture repo 확인해서 이 plugin이 뭘 해야하는지 확인하고, obs-multiplugin을 개조해서 해야할지 나한테 보고서 가져와"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/edbe3e2c-711c-4f90-8f8c-b9a3f2c27994.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-22T23:40:53.186Z","sessionId":"edbe3e2c-711c-4f90-8f8c-b9a3f2c27994"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a52f97fbe77cd839f.jsonl:2:{"parentUuid":"a7aa902e-ff49-4673-868f-bff8dd8a7ce4","isSidechain":true,"agentId":"a52f97fbe77cd839f","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- readable-writing: 사용자 대면 문서·설계서·PR 본문·주석을 쓸 때 반드시 사용. 가독성 원칙(인지 부하 최소화·용어 즉석 풀이·핵심 선행)을 적용해 \"처음 보는 사람도 한 번에 읽히는\" 글을 만든다. \"가독성 있게\", \"읽기 쉽게\", \"주석 자세히\", \"설명 달아줘\" 요청 시 트리거.\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan\n- plan-prd\n- pm2\n- pr\n- project-init\n- projects\n- promote\n- prp-commit\n- prp-implement\n- prp-plan\n- prp-pr\n- prp-prd\n- prune\n- python-review\n- quality-gate\n- react-build\n- react-review\n- react-test\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- plugin-dev:create-plugin: Guided end-to-end plugin creation workflow with component design, implementation, and validation\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find: Smart vault search - returns results with context, not just filenames\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save: Save everything worth keeping from this conversation to the vault\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- plugin-dev:agent-development\n- plugin-dev:command-development\n- plugin-dev:hook-development\n- plugin-dev:mcp-integration\n- plugin-dev:plugin-settings\n- plugin-dev:plugin-structure: This skill should be used when the user asks to \"create a plugin\", \"scaffold a plugin\", \"understand plugin structure\", \"organize plugin components\", \"set up plugin.json\", \"use ${CLAUDE_PLUGIN_ROOT}\", \"add commands/agents/skills/hooks\", \"configure auto-discovery\", or needs guidance on plugin directory layout, manifest configuration, component organization, file naming conventions, or Claude Code plugin architecture best practices.\n- plugin-dev:skill-development: This skill should be used when the user wants to \"create a skill\", \"add a skill to plugin\", \"write a new skill\", \"improve skill description\", \"organize skill content\", or needs guidance on skill structure, progressive disclosure, or skill development best practices for Claude Code plugins.\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf: Use this skill whenever the user wants to do anything with PDF files. This includes reading or extracting text/tables from PDFs, combining or merging multiple PDFs into one, splitting PDFs apart, rotating pages, adding watermarks, creating new PDFs, filling PDF forms, encrypting/decrypting PDFs, extracting images, and OCR on scanned PDFs to make them searchable. If the user mentions a .pdf file or asks to produce one, use this skill.\n- anthropic-skills:pptx: Use this skill any time a .pptx or .potx file is involved in any way — as input, output, or both. This includes: creating slide decks, pitch decks, or presentations; reading, parsing, or extracting text from any .pptx or .potx file (even if the extracted content will be used elsewhere, like in an email or summary); editing, modifying, or updating existing presentations; combining or splitting slide files; working with templates (.potx), layouts, speaker notes, or comments. Trigger whenever the user mentions \"deck,\" \"slides,\" \"presentation,\" or references a .pptx or .potx filename, regardless of what they plan to do with the content afterward. If a .pptx or .potx file needs to be opened, created, or touched, use this skill.\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":550,"isInitial":true,"names":["find-skills","harness-orchestrator","readable-writing","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","plugin-dev:create-plugin","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","plugin-dev:agent-development","plugin-dev:command-development","plugin-dev:hook-development","plugin-dev:mcp-integration","plugin-dev:plugin-settings","plugin-dev:plugin-structure","plugin-dev:skill-development","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"1869620a-acd8-45fe-897c-bf6feaa279b4","timestamp":"2026-08-06T04:55:35.043Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/pokeclip-mono/.claude/worktrees/kty-harness-template-readme-3cf068","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab","version":"2.1.219","gitBranch":"claude/adr-0006-knowledge-store-layer-f1c932"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a52f97fbe77cd839f.jsonl:11:{"parentUuid":"5d888fcf-5ff5-44ea-a9f2-f8d1779e9f70","isSidechain":true,"agentId":"a52f97fbe77cd839f","attachment":{"type":"read_truncation_notice","banner":"[Truncated: PARTIAL view — /private/tmp/claude-501/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/scratchpad/harness-layer/_workspace/00_design_v4.md: showing lines 1-601 of 1048 total (37031 tokens, cap 25000). Call Read with offset=602 limit=601 for the next page, or Grep to find a specific section. Do NOT answer from this page alone if the answer may be further in the file.]","toolUseID":"toolu_01CHapiNRTr5Qssyk72zgFUv"},"type":"attachment","uuid":"3650c091-cb73-47cf-a119-349ce27db63f","timestamp":"2026-08-06T04:55:54.103Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/pokeclip-mono/.claude/worktrees/kty-harness-template-readme-3cf068","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab","version":"2.1.219","gitBranch":"claude/adr-0006-knowledge-store-layer-f1c932"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/42984026-966c-4e9b-ae85-44067f5abcdb.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-31T00:13:24.379Z","sessionId":"42984026-966c-4e9b-ae85-44067f5abcdb","content":"second brain에서 pokeclip architecture 정보 꺼내와서 개발 준비해봦"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-pokeclip-obs-plugin-architecture-784960/42984026-966c-4e9b-ae85-44067f5abcdb.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-31T00:13:24.423Z","sessionId":"42984026-966c-4e9b-ae85-44067f5abcdb"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-usecase0-drawio-engine-resume-cb705b/3609e734-1a66-43bd-8da7-1f241f34c0d4.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-22T13:00:14.873Z","sessionId":"3609e734-1a66-43bd-8da7-1f241f34c0d4","content":"# Claude 재개 프롬프트 — 0번 Use Case draw.io 엔진 마무리\n\n이 작업은 새 구현이 아니라 **중단된 0번 Use Case draw.io 라우팅 엔진 개발의 정확한 재개**다. 처음부터 다시 만들거나 기존 WIP를 되돌리지 말고, 현재 RED 지점부터 TDD로 끝까지 마무리해.\n\n## 0. 작업 위치와 현재 체크포인트\n\n작업 경로:\n\n```text\n/Users/kty/Downloads/PokeClip-architecture\n```\n\n현재 브랜치와 공유 체크포인트:\n\n```text\nbranch: codex/usecase0-drawio-engine\ncheckpoint commit: 981bbd6 chore: checkpoint drawio routing engine\n```\n\n이 체크포인트 이후 작업 트리는 매우 dirty하다. 0번 엔진 WIP뿐 아니라 사용자가 만든 문서·다이어그램·2~5번 변경도 함께 존재한다. 다음 명령은 절대 사용하지 마.\n\n```text\ngit reset --hard\ngit checkout -- <path>\ngit clean\ngit stash\n```\n\n다른 파일을 원상복구하거나 정리하지 말고, 0번 관련 현재 변경 위에서 이어서 작업해.\n\n## 1. 시작 전에 반드시 읽을 파일\n\n다음 순서로 전부 읽어.\n\n1. `CLAUDE.md`\n2. `_workspace/progress.md` — 현재 실행 RAM의 정본\n3. `.claude/harness/principles.md`\n4. `.claude/harness/project-profile.md`\n5. `_workspace/02_routing_rules.md` — **v4-approved 공통 라우팅 규칙 정본**\n6. `_workspace/00_design.md`\n7. `_workspace/01_plan.md`\n8. `site/shared/usecase-semantic-contract.json`\n9. `site/shared/usecase-routing-profile.json`\n10. `site/test/usecase-candidate-domain.test.mjs`\n11. `site/test/usecase-v4-core-contract.test.mjs`\n12. `site/scripts/drawio-routing/routing-domain.mjs`\n13. `site/scripts/drawio-routing/routing-profile.mjs`\n14. `site/scripts/drawio-routing/routing-solver.mjs`\n15. `site/scripts/drawio-routing/usecase-router.mjs`\n16. `site/scripts/drawio-routing/usecase-generator.mjs`\n17. `site/scripts/drawio-routing/usecase-validation.mjs`\n18. `site/src/lib/drawio/useCaseManifestDiagnostics.ts`\n19. `site/src/lib/drawio/useCaseBrowserMeasurements.ts`\n20. `site/src/lib/drawio/drawioDiagnostics.ts`\n21. `site/src/components/drawio/DrawioLabViewer.tsx`\n\n하네스상 이 작업은 설계·계획 재작성 단계가 아니다. `_workspace/02_routing_rules.md`, `00_design.md`, `01_plan.md`는 이미 독립 승인됐다. 최소 명료화 게이트 후 **developer↔reviewer Phase 3**부터 재개해. 구현 중 승인된 규칙으로 설명할 수 없는 문제가 나오면 one-off 좌표를 추가하지 말고 설계 규칙 단계로 되돌아가 보고해.\n\n## 2. 보호 대상\n\n사용자 승인 전 공개 0번 원본을 교체하지 마.\n\n현재 보호 해시:\n\n```text\n0_Pokeclip_UseCase.html\n4ae1c3ad2c96fcf4443b6e09fd385d8269820d1afb3cd47991bea02730d8715e\n\n0_Pokeclip_UseCase.png\n8d9a4bdd332da29a494ce00b26a612d0bc6766a01583380ce936d3f292549662\n```\n\n개발·검수는 다음 lab 산출물에서 진행해.\n\n```text\nlabs/drawio/0_Pokeclip_UseCase.source.drawio\nlabs/drawio/0_Pokeclip_UseCase.drawio\nlabs/drawio/0_Pokeclip_UseCase.routing.json\nhttp://127.0.0.1:5173/labs/drawio/0\n```\n\n`0_Pokeclip_UseCase.html/.png`의 해시를 완료 승인 전 바꾸지 마. 1번 IA source/generated/manifest와 2~5번 다이어그램도 수정하지 마.\n\n## 3. 현재 확인된 실제 RED\n\n먼저 아래 명령으로 같은 상태를 재현해.\n\n```bash\ncd /Users/kty/Downloads/PokeClip-architecture/site\nnode --test test/usecase-candidate-domain.test.mjs\n```\n\n2026-07-22 현재 결과:\n\n```text\ntests 5\npass 1\nfail 4\n```\n\n현재 통과:\n\n- aligned obstacle-free pair에 direct candidate 생성\n\n현재 실패:\n\n1. every canonical semantic edge has genuinely multiple finite candidates\n2. canonical domain contains L, Z, outer patterns\n3. selecting a different candidate changes materialized geometry\n4. materializer contains no literal per-edge-id coordinate table\n\n첫 runtime 차단점:\n\n```text\nLAYOUT_DOMAIN_EXHAUSTED:edge-uc-template-to-uc-auto-upload:no-candidate\n```\n\n하드코딩 잔존:\n\n```text\nsite/scripts/drawio-routing/usecase-router.mjs\n- actorSpecs\n- featureSpecs\n- canonicalRawRoutes()\n- routeCandidatesForModel()\n- edge-id별 literal spine/lane/rail 좌표\n```\n\n실패 테스트를 삭제·skip·완화하거나 production 코드를 문자열 검사에서 숨기는 방식으로 통과시키지 마.\n\n## 4. 완료해야 할 구조적 결함\n\n현재 구현은 solver 파일이 존재하지만 아직 승인된 v4 finite-domain solver가 아니다. 테스트만 억지로 GREEN으로 만들지 말고 다음 구조를 모두 완성해.\n\n### 4.1 Candidate domain\n\n`routing-domain.mjs`가 각 semantic edge에 대해 profile에서 유도한 진짜 복수 후보를 만들어야 한다.\n\n필수 문법:\n\n```text\ndirect → L(HV/VH) → Z → compatible T bundle → outer gutter\n```\n\n필수 조건:\n\n- actor 3 + use case 38 = semantic vertex 41\n- semantic edge 26개 각각 exactly-one edge variable\n- 모든 canonical edge는 최소 2개의 실제로 다른 finite candidate를 가져야 함\n- candidate를 바꾸면 materialized physical geometry도 실제로 바뀌어야 함\n- 허용된 중앙 port pair, structural corridor, group gateway, outer gutter에서 후보를 생성\n- node/actor/group/label obstacle과 container border 규칙을 후보 생성 시부터 적용\n- `edge-uc-template-to-uc-auto-upload`만을 위한 좌표 예외 금지\n- 점프카드 관계는 빈 left 중앙 포트 직접 진입을 top 우회보다 먼저 평가\n- 편집자 관계는 복잡한 우회 전에 actor 위치를 주 lane 쪽으로 올린 직선·저-bend 후보를 평가\n\n현재 `rankAndCap()`의 아래 방식은 v4 위반이다.\n\n```js\nscored.slice(0, MAX_CANDIDATES)\n```\n\n후보가 많다는 이유로 정렬 후 앞 12개를 임의 절단하지 마. `_workspace/02_routing_rules.md`대로:\n\n- hard rejection 후\n- **전체 hard-conflict set과 resource-consumption signature가 동일한 후보끼리만** Pareto prune\n- score lower bound와 length가 모두 열등한 후보만 제거\n- 남은 non-dominated 후보가 profile cap 12개를 넘으면 결과를 자르지 말고 `DOMAIN_TOO_WIDE`로 fail-closed\n\nmodule 상수 `MAX_CANDIDATES`가 아니라 profile의 `finiteDomain.maxCandidatesPerVariable`을 정본으로 사용해.\n\n### 4.2 Layout variables와 expansion round\n\n현재 `variablesForRound()`는 actor+edge만 넣고 node/group/label/canvas를 실질적으로 선택하지 않으며, `actorCandidates()`도 canonical anchor 외 후보를 `hardValid=false`로 만들어 이동을 막고 있다. 이 상태로는 v4가 아니다.\n\n다음을 구현해.\n\n- port, actor, node, group, label, canvas 후보 catalogue가 실제 layout 선택에 반영\n- actor 이동 후보가 corridor/max displacement 안에서 실제 유효 후보가 됨\n- round는 nested union이고 `port → actor → node/group/label → canvas` 확장 순서를 지킴\n- round별 layout을 적용한 뒤 edge candidate domain을 다시 계산\n- `buildEdgeVariables()`를 모든 round 밖에서 한 번만 계산하지 않음\n- layout 조합이 4096을 넘으면 임의 절단 없이 `DOMAIN_TOO_WIDE`\n- `directDistance: 1` placeholder 제거, 실제 source/target 중앙 포트의 L1 distance 사용\n- source/target direct distance 0은 hard rejection\n- domainVersion은 profile/schema/round/canonical candidate IDs로 결정적 SHA-256\n\n### 4.3 Resource와 conflict model\n\npairwise 선분 충돌만 대충 검사하지 말고 v4의 n-ary resource 계약을 구현해.\n\n- port, gateway, trunk, arrowhead capacity\n- relation style/share/direction/arrow mode가 다른 atom 공유 금지\n- actor는 shared source prefix만, feature shared-single은 compatible target suffix만 공유\n- 분기 후 재합류 금지\n- 같은 actor/common terminal이라는 이유로 degree-4 X를 허용하지 않음\n- degree 4 이상 무조건 금지\n- T junction은 degree 3이며 정확히 두 collinear + 한 perpendicular\n- unrelated crossing, collinear overlap, parallel lane gap <16, segment <16 hard rejection\n- `mixed` physical atom 0\n- duplicate junction/physical edge ID fail-closed\n- candidate conflict/resource ID가 deterministic하고 manifest와 exact parity\n\n### 4.4 Solver\n\n현재 `routing-solver.mjs`의 단일 DFS와 `[bends,length]` 합계만으로 완료를 주장하지 마.\n\n`_workspace/02_routing_rules.md` 4.2와 6장을 그대로 구현해.\n\n- MRV variable ordering: domain size, interaction degree, variable kind, direct distance, code-point ID\n- deterministic candidate ordering: score lower bound + canonical key\n- pairwise+n-ary capacity를 부분해에서 prune\n- component 분리는 n-ary coupling과 공유 resource가 없다는 것이 증명된 경우만\n- component별 non-dominated score frontier 보존\n- frontier Cartesian merge의 exact 비교\n- component state / merge state 각각 250,000 상한\n- 상한 도달 시 부분 best 반환 금지, `SEARCH_INCOMPLETE`\n- 최대 round까지 비교하거나 exact lower-bound proof가 있을 때만 조기 종료\n- 해가 없으면 `LAYOUT_DOMAIN_EXHAUSTED`, 부분 XML/manifest 금지\n- max/total bend, physical bend, port penalty, exact detour ratio, displacement, canvas area까지 승인된 전체 score tuple 구현\n- float ratio 합산 금지. BigInt cross multiplication + gcd 약분\n- 최종 선택을 처음부터 재검증하고 exactly-one/resource/hard rejection 불일치 시 산출물 금지\n\n### 4.5 Materializer\n\n`usecase-router.mjs`는 solver selection만 소비해야 한다.\n\n- `actorSpecs`, `featureSpecs`, `canonicalRawRoutes`, literal edge-id coordinate table 삭제\n- `buildPhysicalUseCase()`의 compatibility hardcoded fallback 제거 또는 solver pipeline으로 교체\n- `materializePhysicalUseCase()`가 selected layout과 selected edge candidate만 materialize\n- 선택되지 않은 후보나 옛 좌표표를 fallback으로 사용하지 않음\n- semantic→physical ordered path를 edge별로 완전 보존\n- 연속 collinear atom compact\n- styleClass/shareClass/directionClass/arrowMode를 physical atom에 정확히 보존\n- shared-single arrow는 semantic edge마다 중복 arrowhead가 생기지 않게 함\n\n### 4.6 Independent validator와 browser diagnostics\n\n기존 검수가 놓쳤던 차단급 문제를 네 층에서 고정해.\n\n1. generation hard rejection\n2. 독립 static validator\n3. 실제 SVG browser diagnostics\n4. mutation test\n\n반드시 막아야 할 회귀:\n\n- `(960,810)` same-actor degree-4 X\n- actor solid와 feature dashed가 physical atom을 공유하는 mixed relation\n- duplicate junction metadata가 Set에 접혀 통과\n- mount 실패 뒤 이전 PASS diagnostics가 남는 stale PASS\n- actor label을 일반 node-inside로 오진\n- semantic vertex label이 click을 가로채 선택을 해제\n- group interior/border overlap/gateway 위반\n- label/edge, label/label 충돌과 font measurement 실패\n\nfont load 또는 actual bounds 측정 실패는 PASS가 아니라 FAIL이다. browser가 재계산할 수 없는 manifest-only 수치를 browser 측정값처럼 표시하지 마.\n\n## 5. TDD 구현 순서\n\n순서를 바꾸지 마.\n\n1. 현재 `usecase-candidate-domain.test.mjs` 1 PASS / 4 FAIL 재현\n2. `edge-uc-template-to-uc-auto-upload`를 일반 finite grammar로 후보 생성되게 수정\n3. 26개 edge 복수 후보 + L/Z/outer + materializer selection + hardcoded table 제거를 GREEN\n4. v4 11장에 대응하는 누락 RED/mutation tests 추가\n5. layout variables와 nested expansion round 구현\n6. pairwise+n-ary conflict/resource model 구현\n7. complete deterministic solver/frontier merge/score tuple 구현\n8. solver-only materializer 구현\n9. independent validator GREEN\n10. manifest-aware browser diagnostics와 stale lifecycle GREEN\n11. canonical source 생성 두 번이 byte-identical인지 검증\n12. 전체 test/typecheck/lint/build\n13. `/labs/drawio/0` 실제 브라우저 시각 검수\n\n각 단계에서 RED → 최소 구현 → GREEN → 리팩터 순서를 지켜. 마지막 보고에 다음 줄을 포함해.\n\n```text\n방법론: superpowers:test-driven-development 따름\n```\n\n## 6. 수정 범위\n\n주요 허용 범위:\n\n```text\nsite/shared/usecase-semantic-contract.json\nsite/shared/usecase-routing-profile.json\nsite/scripts/drawio-routing/routing-*.mjs\nsite/scripts/drawio-routing/usecase-*.mjs\nsite/scripts/route-drawio.mjs\nsite/test/usecase-*.test.mjs\nsite/test/drawio-diagnostics-lifecycle.test.mjs\nsite/src/pages/labs/DrawioUseCaseLabPage.tsx\nsite/src/components/drawio/DrawioLabViewer.tsx\nsite/src/lib/drawio/*\nlabs/drawio/0_Pokeclip_UseCase.source.drawio\nlabs/drawio/0_Pokeclip_UseCase.drawio\nlabs/drawio/0_Pokeclip_UseCase.routing.json\n_workspace/progress.md\n```\n\n공용 runtime 파일은 0번에 꼭 필요한 최소 변경만 하고 IA·2~5 회귀를 확인해.\n\n수정 금지:\n\n```text\n1_Pokeclip_IA.html/.png 및 IA source/generated/manifest\n2_Pokeclip_UserJourney.*\n3_Pokeclip_SA.*\n4_Pokeclip_SysA.*\n5_Pokeclip_CA.*\n9~12와 ADR의 아키텍처 내용\n_workspace/05_ca_redesign_spec.md\n_workspace/05_ca_claude_prompt.md\n```\n\n다른 사용자의 dirty 변경과 충돌하면 덮어쓰지 말고 현재 내용을 수용한 최소 patch를 작성해.\n\n## 7. 완료 기준\n\n의미 계약:\n\n```text\nactor 3\nuse case 38\nsemantic vertex 41\ntyped semantic edge 26\ndecoration 8\n```\n\n정적 geometry:\n\n```text\nendpoint max error <= 1px\nnon-central port 0\nnon-orthogonal 0\nnode/actor penetration 0\nnode clearance >= 12px\nunrelated crossing 0\noverlap 0\ndegree-4 X 0\nmixed atom 0\nduplicate junction/edge ID 0\ngroup interior penetration 0\ngroup-border overlap 0\ngateway violation 0\nparallel lane gap >= 16px\nmicro segment(<16px) 0\nlabel unavailable/outside/collision 0\ncrossing/overlap allowlist 없음\n```\n\n검색·manifest:\n\n```text\nsearchComplete=true\ntermination=OPTIMAL\n모든 edge exactly-one selection\ndomain/profile/schema/contract hashes 존재 및 browser parity\nmodel↔manifest semantic/physical exact set parity\n선택된 전체 score tuple과 canonical tie key 기록\nround별 explored/pruned/backtrack/termination 기록\n```\n\n인터랙션:\n\n- semantic node/edge만 클릭 대상\n- decoration 오진 0\n- 노드 선택 시 해당 전체 physical path와 arrowhead가 함께 강조\n- label은 semantic vertex에 대해서만 `pointer-events:none`\n- remount 실패 때 과거 PASS가 즉시 지워지고 FAIL로 전환\n\n## 8. 검증 명령\n\n최소 다음을 전부 실행해.\n\n```bash\ncd /Users/kty/Downloads/PokeClip-architecture/site\n\nnode --test test/usecase-candidate-domain.test.mjs\nnode --test test/usecase-v4-core-contract.test.mjs\nnpm run test:drawio\nnpm run drawio:route -- --check ../labs/drawio/0_Pokeclip_UseCase.source.drawio ../labs/drawio/0_Pokeclip_UseCase.drawio\nnpm run drawio:route -- --check ../labs/drawio/1_Pokeclip_IA.source.drawio ../labs/drawio/1_Pokeclip_IA.drawio\nnpx tsc -b\nnpm run lint\nnpm run build\ngit diff --check\n```\n\n실제 CLI 계약은 `--write|--check <source.drawio> <generated.drawio>`다. 변경 전에도 `site/scripts/route-drawio.mjs`를 읽어 이 계약이 유지되는지 확인하고, 없는 옵션을 지어내지 마.\n\n생성물 검사:\n\n- source/generated XML에 HTML, CDATA, XML comment 0\n- generated XML과 manifest 두 번 생성 시 byte-identical\n- 보호 대상 HTML/PNG SHA-256 불변\n\n브라우저 검수:\n\n```text\nhttp://127.0.0.1:5173/labs/drawio/0\n1440×900\n1920×1080\n```\n\n최소 확인:\n\n- 모든 화살표가 source/target 중앙 포트에 붙음\n- 점프카드 관계가 불필요하게 위로 우회하지 않음\n- 편집자 관계가 불필요한 다중 bend 대신 정렬된 저-bend 경로 사용\n- 선이 노드·그룹 제목·라벨을 침범하지 않음\n- 클릭 시 노드와 전체 연결선이 함께 lift\n- 진단 패널 수치와 실제 SVG 측정 parity\n\n## 9. 검수와 중지 조건\n\n구현 후 독립 code review를 수행해. 다음은 HIGH 이상 차단으로 취급해.\n\n- 테스트를 약화하거나 삭제해 GREEN\n- edge ID별 좌표표·예외가 다시 들어감\n- 임의 후보 slice/cap\n- solver가 부분 탐색인데 OPTIMAL 주장\n- static validator와 generator가 동일 내부 판정 코드를 공유해 독립성 상실\n- browser 실측 없이 manifest 값을 그대로 PASS 표시\n- 보호 대상 HTML/PNG 또는 1~5번 파일을 무단 교체\n\n검수에서 HIGH/CRITICAL이 나오면 수정→재검수 루프를 돌고, 모두 통과하기 전 완료라고 말하지 마.\n\n## 10. 완료 보고 형식\n\n다음 순서로 보고해.\n\n1. 최초 RED 재현 결과\n2. candidate domain / solver / materializer / validator / browser 각각의 변경 요약\n3. 수정 파일 목록\n4. semantic·geometry·search·manifest 최종 수치\n5. targeted test, full test, typecheck, lint, build 결과\n6. 1440×900 및 1920×1080 브라우저 검수 결과\n7. 보호 해시 재확인\n8. 독립 review 판정과 남은 제한\n\n이번 작업에서는 commit, push, PR, merge, Vercel deploy를 하지 마. 모든 검증이 끝난 로컬 WIP 상태에서 멈추고 사용자와 Codex가 검수할 수 있게 해.\n\n```text\n방법론: superpowers:test-driven-development 따름\n```"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-usecase0-drawio-engine-resume-cb705b/3609e734-1a66-43bd-8da7-1f241f34c0d4.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-22T13:00:14.973Z","sessionId":"3609e734-1a66-43bd-8da7-1f241f34c0d4"}
/Users/kty/.claude/projects/-Users-kty-Downloads-----/758fae1a-b255-460d-a07f-44c2714a4202.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-20T09:17:23.079Z","sessionId":"758fae1a-b255-460d-a07f-44c2714a4202","content":"이거 폴더 구조 확인하고 내 github에도 올라가 있거든? 이거 vercel mcp 연결해서 react로 반응성 있게 페이지 하나 구동하고 싶은데 pokeclip 0~5 html 쓸거고 기획서도 보게 할거야 여기는 기능명세서란 이름으로 되어 있나? 너가 확인하고 검사맡아 나한테"}
/Users/kty/.claude/projects/-Users-kty-Downloads-----/758fae1a-b255-460d-a07f-44c2714a4202.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-20T09:17:23.156Z","sessionId":"758fae1a-b255-460d-a07f-44c2714a4202"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-cost-optimization-3018d5/f1e63a73-f87d-4686-8377-51e942dfc3ee.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-13T05:38:20.841Z","sessionId":"f1e63a73-f87d-4686-8377-51e942dfc3ee","content":"프레임 캡처 잔여 유실(약 2%)을 0으로 만들어, 방송 구간을 선택하면 사진 장수가 \n\"초 단위 구간 길이와 정확히 일치(따라서 5초 윈도우 N개 선택 시 5의 배수)\"하도록 \n보장하는 작업을 chat-harness 파이프라인으로 진행해줘.\n\n## 배경 (운영 실측 근거)\n- 이 프로젝트는 CHZZK/SOOP 채팅 수집·분석 시스템. 방송 화면을 ffmpeg로 1초 1장 \n  캡처하고, 대시보드에서 구간을 드래그로 선택하면 그 구간의 프레임을 재생·집계한다.\n- 현재 ffmpeg 명령(src/server/frameCapture.ts의 buildFfmpegArgs/spawnCapture):\n  ...-re -i <hlsUrl> -vf fps=1,scale=-2:720 -q:v 5 -f image2 -strftime 1 <framesDir>/%s.jpg\n- 파일명이 \"저장 순간의 벽시계 초(%s)\"라, 라이브 HLS를 처리할 때 아주 가끔 두 프레임이 \n  같은 벽시계 초에 저장되며 하나가 덮어써진다 → 그 초가 빈다(유실).\n- 이미 PR #22에서 `-re`(입력 realtime 페이싱)를 넣어 유실을 50%→약 2%로 줄였다. \n  하지만 0은 아니다: 실측상 250초 구간(5초 윈도우 50개)에 244장(6장 누락, ~2.4%). \n  계획 검토 때 \"분당 0~1회 겹침 잔여\"로 예측됐던, 초-단위 파일명 스킴의 고유 한계.\n\n## 목표\n잔여 유실을 없애 벽시계 초당 정확히 1장을 보장한다. \n검증 기준: 임의의 N초 구간을 선택하면 프레임 수가 N(±0)이어야 하고, 5초 윈도우 \nK개 선택 시 5K장이 나와야 한다. 운영 스모크로 수 분간 무손실 확인.\n\n## 절대 제약\n- 파일명 스킴 `%s.jpg`(에폭 초)는 채팅↔프레임 매칭(src/shared/frameSeconds.ts, \n  nearestFrameSecond), 48시간 보존 sweep, 재생 API(/api/frames/:provider/:second), \n  프레임 시각 KST 캡션(FramePlayerPanel의 formatFrameTimestamp)의 키다. \n  → 스킴을 유지하는 방향을 우선하되, 만약 바꿔야 한다면 이 소비처 전부를 \n  한 PR에서 일관되게 갱신하고 회귀 테스트로 못 박아라(스킴 변경은 고위험).\n\n## 유력 방향 (planner가 조사·확정)\nffmpeg가 파일명을 벽시계에 맡기지 않게 하고, 서버(Node)에서 프레임을 받아 \n\"초당 정확히 1장\"을 보장하도록 재설계. 후보:\n  (a) image2pipe로 JPEG 스트림을 받아 Node에서 벽시계 초당 1장만 골라 %s.jpg로 저장\n      (같은 초 중복은 버리고, 빈 초는 직전 프레임 복제 또는 스킵 정책 결정)\n  (b) ffmpeg 출력 파일 감시 → 초 충돌 시 덮어쓰기 대신 보존/보정\n각 후보의 백프레셔·CPU·에러처리·재연결 상호작용·복잡도를 근거로 하나를 골라라.\n\"빈 초를 어떻게 채울지(직전 프레임 복제 vs 그냥 비움)\"는 사용자에게 확인할 것.\n\n## 참고 파일\n- src/server/frameCapture.ts (buildFfmpegArgs, spawnCapture, refreshIndex, STALL 워치독)\n- src/shared/frameSeconds.ts (매칭), src/server/routes/frames.ts (재생/보존)\n- src/client/components/dashboard/FramePlayerPanel.tsx (구간 요약 \"총 N장\" 표시)\n\n## 진행 방식\nchat-harness 파이프라인(clarifier→planner→plan-reviewer→developer→reviewer→\npr-author→pr-reviewer→change-explainer→completion-auditor)으로. \n\"빈 초 처리 정책\"과 \"파일명 스킴 유지 여부\"는 clarifier에서 사용자에게 확인. \n실프레임율은 운영 배포(빌드+재시작) 후 스모크로만 최종 검증 가능함을 명시."}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-cost-optimization-3018d5/f1e63a73-f87d-4686-8377-51e942dfc3ee.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-13T05:38:20.883Z","sessionId":"f1e63a73-f87d-4686-8377-51e942dfc3ee"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-cost-optimization-3018d5/6cc870a0-e1ca-4364-9b13-6dee8838002b.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-14T04:33:23.976Z","sessionId":"6cc870a0-e1ca-4364-9b13-6dee8838002b","content":"지금 현재 채팅  참여율 수식이 어떻게 계산되고 있는지 말해봐"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-cost-optimization-3018d5/6cc870a0-e1ca-4364-9b13-6dee8838002b.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-14T04:33:24.012Z","sessionId":"6cc870a0-e1ca-4364-9b13-6dee8838002b"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-3-development-f7d366/38c2eea8-cca3-485a-8eb2-28e7dfef37cd.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-31T02:59:09.447Z","sessionId":"38c2eea8-cca3-485a-8eb2-28e7dfef37cd","content":"우리 clip worker 가 무슨 역할을 개발해야하는거야?"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-3-development-f7d366/38c2eea8-cca3-485a-8eb2-28e7dfef37cd.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-31T02:59:09.488Z","sessionId":"38c2eea8-cca3-485a-8eb2-28e7dfef37cd"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/cbed9984-669d-4082-9f25-dbf386a3756a.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-23T06:01:52.580Z","sessionId":"cbed9984-669d-4082-9f25-dbf386a3756a","content":"_workspace/NEXT-TASK-labs-to-diagrams.md 읽고 labs를 diagrams로 승격 진행"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/cbed9984-669d-4082-9f25-dbf386a3756a.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-23T06:01:52.615Z","sessionId":"cbed9984-669d-4082-9f25-dbf386a3756a"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-ab9dcd3e50e662b1f.jsonl:6:{"parentUuid":"55be2249-0aa6-4fc8-8137-83338df2fa23","isSidechain":true,"agentId":"ab9dcd3e50e662b1f","attachment":{"type":"read_truncation_notice","banner":"[Truncated: PARTIAL view — /private/tmp/claude-501/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/scratchpad/harness-layer/_workspace/00_design_v2.md: showing lines 1-632 of 1008 total (33873 tokens, cap 25000). Call Read with offset=633 limit=632 for the next page, or Grep to find a specific section. Do NOT answer from this page alone if the answer may be further in the file.]","toolUseID":"toolu_01PvfqtudndM2qs3iAjDYEd5"},"type":"attachment","uuid":"a03e366d-8667-45d3-bd18-842b02453d9d","timestamp":"2026-08-06T02:16:14.806Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/pokeclip-mono/.claude/worktrees/kty-harness-template-readme-3cf068","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab","version":"2.1.219","gitBranch":"claude/adr-0006-knowledge-store-layer-f1c932"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a04824dd33da1209d.jsonl:5:{"parentUuid":"eb34c85f-d7a4-4d46-8cbd-2e170edcfaaf","isSidechain":true,"agentId":"a04824dd33da1209d","attachment":{"type":"read_truncation_notice","banner":"[Truncated: PARTIAL view — /private/tmp/claude-501/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/scratchpad/harness-layer/_workspace/00_design_v3.md: showing lines 1-623 of 1067 total (36389 tokens, cap 25000). Call Read with offset=624 limit=623 for the next page, or Grep to find a specific section. Do NOT answer from this page alone if the answer may be further in the file.]","toolUseID":"toolu_01SVzwUaXFamX4nFxF7jrb7A"},"type":"attachment","uuid":"762bed42-0fbd-469d-a624-79a02478bc96","timestamp":"2026-08-06T02:46:09.230Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/pokeclip-mono/.claude/worktrees/kty-harness-template-readme-3cf068","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab","version":"2.1.219","gitBranch":"claude/adr-0006-knowledge-store-layer-f1c932"}
/Users/kty/.claude/projects/-Users-kty-Documents-valut/6d1e1f31-2776-43cd-a9b0-2eb4ef15de8d.jsonl:1:{"type":"last-prompt","leafUuid":"f582d4d3-0c4d-437c-b104-15923aad5524","sessionId":"6d1e1f31-2776-43cd-a9b0-2eb4ef15de8d"}
/Users/kty/.claude/projects/-Users-kty-Documents-valut/6d1e1f31-2776-43cd-a9b0-2eb4ef15de8d.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"0fc64e3c-f1dc-4568-880f-5a7dad3905ee","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":471},"type":"attachment","uuid":"14c7d27d-f599-4caf-ba32-6cb6591501ff","timestamp":"2026-07-22T13:27:18.088Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty/Documents/valut","sessionId":"6d1e1f31-2776-43cd-a9b0-2eb4ef15de8d","version":"2.1.206","gitBranch":"main"}
/Users/kty/.claude/projects/-Users-kty-Downloads-----/8a4b3f6c-ac59-4fd2-bd9c-9f6aae0463ec.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-21T02:29:10.164Z","sessionId":"8a4b3f6c-ac59-4fd2-bd9c-9f6aae0463ec","content":"https://github.com/xodbs1021/kty-claude-harness-template 이거 적용해"}
/Users/kty/.claude/projects/-Users-kty-Downloads-----/8a4b3f6c-ac59-4fd2-bd9c-9f6aae0463ec.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-21T02:29:10.206Z","sessionId":"8a4b3f6c-ac59-4fd2-bd9c-9f6aae0463ec"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-3-development-f7d366/72170f3f-3a8f-4d89-98d5-26a4a76d17a5.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-27T13:46:11.554Z","sessionId":"72170f3f-3a8f-4d89-98d5-26a4a76d17a5","content":"hdmi 셀렉터 사야하는데 5:1이상이었으면 좋겠고 , 나는 4k 60 모니터 쓰긴하는데 ps5 pro ,mac mini연결해서 사용중임 자동전환기능 있어야하고 나중에 120hz 모니터 전환 가능성이 있기에 4k 120까지 지원되는 걸로 시장조사후에 제품 10개추천 후 장단점알려줘"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-3-development-f7d366/72170f3f-3a8f-4d89-98d5-26a4a76d17a5.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-27T13:46:11.580Z","sessionId":"72170f3f-3a8f-4d89-98d5-26a4a76d17a5"}
/Users/kty/.claude/projects/-Users-kty-Documents-valut/161a726b-3efd-4be8-aff4-3817c7253587.jsonl:1:{"type":"last-prompt","leafUuid":"f3e793b4-59ba-46de-802a-14abe5bbf473","sessionId":"161a726b-3efd-4be8-aff4-3817c7253587"}
/Users/kty/.claude/projects/-Users-kty-Documents-valut/161a726b-3efd-4be8-aff4-3817c7253587.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"3684a3c1-5735-432d-9648-8f0556863e3c","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":315},"type":"attachment","uuid":"ecc1743e-24c5-4421-bc46-a25f40f535cc","timestamp":"2026-07-24T00:28:54.909Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty/Documents/valut","sessionId":"161a726b-3efd-4be8-aff4-3817c7253587","version":"2.1.206","gitBranch":"main"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab/subagents/agent-a17e2648f04ee9bb7.jsonl:2:{"parentUuid":"b43076b0-5056-409e-8685-220544fc17c2","isSidechain":true,"agentId":"a17e2648f04ee9bb7","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- readable-writing: 사용자 대면 문서·설계서·PR 본문·주석을 쓸 때 반드시 사용. 가독성 원칙(인지 부하 최소화·용어 즉석 풀이·핵심 선행)을 적용해 \"처음 보는 사람도 한 번에 읽히는\" 글을 만든다. \"가독성 있게\", \"읽기 쉽게\", \"주석 자세히\", \"설명 달아줘\" 요청 시 트리거.\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan\n- plan-prd\n- pm2\n- pr\n- project-init\n- projects\n- promote\n- prp-commit\n- prp-implement\n- prp-plan\n- prp-pr\n- prp-prd\n- prune\n- python-review\n- quality-gate\n- react-build\n- react-review\n- react-test\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- plugin-dev:create-plugin: Guided end-to-end plugin creation workflow with component design, implementation, and validation\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find: Smart vault search - returns results with context, not just filenames\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save: Save everything worth keeping from this conversation to the vault\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- plugin-dev:agent-development\n- plugin-dev:command-development\n- plugin-dev:hook-development\n- plugin-dev:mcp-integration\n- plugin-dev:plugin-settings\n- plugin-dev:plugin-structure: This skill should be used when the user asks to \"create a plugin\", \"scaffold a plugin\", \"understand plugin structure\", \"organize plugin components\", \"set up plugin.json\", \"use ${CLAUDE_PLUGIN_ROOT}\", \"add commands/agents/skills/hooks\", \"configure auto-discovery\", or needs guidance on plugin directory layout, manifest configuration, component organization, file naming conventions, or Claude Code plugin architecture best practices.\n- plugin-dev:skill-development: This skill should be used when the user wants to \"create a skill\", \"add a skill to plugin\", \"write a new skill\", \"improve skill description\", \"organize skill content\", or needs guidance on skill structure, progressive disclosure, or skill development best practices for Claude Code plugins.\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf: Use this skill whenever the user wants to do anything with PDF files. This includes reading or extracting text/tables from PDFs, combining or merging multiple PDFs into one, splitting PDFs apart, rotating pages, adding watermarks, creating new PDFs, filling PDF forms, encrypting/decrypting PDFs, extracting images, and OCR on scanned PDFs to make them searchable. If the user mentions a .pdf file or asks to produce one, use this skill.\n- anthropic-skills:pptx: Use this skill any time a .pptx or .potx file is involved in any way — as input, output, or both. This includes: creating slide decks, pitch decks, or presentations; reading, parsing, or extracting text from any .pptx or .potx file (even if the extracted content will be used elsewhere, like in an email or summary); editing, modifying, or updating existing presentations; combining or splitting slide files; working with templates (.potx), layouts, speaker notes, or comments. Trigger whenever the user mentions \"deck,\" \"slides,\" \"presentation,\" or references a .pptx or .potx filename, regardless of what they plan to do with the content afterward. If a .pptx or .potx file needs to be opened, created, or touched, use this skill.\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":550,"isInitial":true,"names":["find-skills","harness-orchestrator","readable-writing","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","plugin-dev:create-plugin","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","plugin-dev:agent-development","plugin-dev:command-development","plugin-dev:hook-development","plugin-dev:mcp-integration","plugin-dev:plugin-settings","plugin-dev:plugin-structure","plugin-dev:skill-development","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"1565657b-0b2d-4cf7-9c54-c9e9a4e81816","timestamp":"2026-08-06T08:08:12.020Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/pokeclip-mono/.claude/worktrees/kty-harness-template-readme-3cf068","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab","version":"2.1.219","gitBranch":"claude/adr-0006-knowledge-store-layer-f1c932"}
/Users/kty/.claude/projects/-Users-kty-Documents-valut/23e14ccc-247a-445f-9623-8b6aa065798d.jsonl:1:{"type":"last-prompt","leafUuid":"d7f95581-2b71-4659-9c08-573eac253797","sessionId":"23e14ccc-247a-445f-9623-8b6aa065798d"}
/Users/kty/.claude/projects/-Users-kty-Documents-valut/23e14ccc-247a-445f-9623-8b6aa065798d.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"55a55cbe-bd2d-4591-86f4-ade2e5b36eba","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":545},"type":"attachment","uuid":"22e3a587-8115-48f2-ba48-ee10091782c1","timestamp":"2026-07-22T06:59:26.944Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty/Documents/valut","sessionId":"23e14ccc-247a-445f-9623-8b6aa065798d","version":"2.1.206","gitBranch":"main"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-vigilant-boyd-385f99/d1fca869-bc31-45f4-97af-a9b3d925f848.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-07T22:43:13.830Z","sessionId":"d1fca869-bc31-45f4-97af-a9b3d925f848","content":"src/server/index.ts가 1001줄이라 프로젝트 800줄 규칙을 넘어.\n동작은 그대로 두고(behavior-preserving) 라우트 그룹(analytics/providers/frames/auth)을\n별도 모듈로 분리해서 파일을 줄여줘. pnpm test랑 typecheck는 계속 통과해야 하고,\n하나의 PR로(master에서 새 브랜치→PR) 올려줘. 머지는 내 승인 후에"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-vigilant-boyd-385f99/d1fca869-bc31-45f4-97af-a9b3d925f848.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-07T22:43:13.853Z","sessionId":"d1fca869-bc31-45f4-97af-a9b3d925f848"}
/Users/kty/.claude/projects/-Users-kty-Downloads/bfd86b67-2f59-497a-8230-c1cebd083773.jsonl:1:{"type":"last-prompt","leafUuid":"d307a70e-f1d2-4dcb-9c9a-6f931290a5dc","sessionId":"bfd86b67-2f59-497a-8230-c1cebd083773"}
/Users/kty/.claude/projects/-Users-kty-Downloads/bfd86b67-2f59-497a-8230-c1cebd083773.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"975d7d4c-7741-4e3e-b976-f9c571db22b4","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":360},"type":"attachment","uuid":"215dee3e-492b-4dfc-b71d-12eb0111c7e9","timestamp":"2026-07-30T10:45:26.810Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty/Downloads","sessionId":"bfd86b67-2f59-497a-8230-c1cebd083773","version":"2.1.206","gitBranch":"HEAD"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-08-05T15:27:56.715Z","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab","content":"# kty-claude-harness-template — ADR-0006 이행 (지식 저장소 층 경계 정리)\n\n## 0. 착수 전 확인\n\n**전제는 이미 충족됐다** (2026-08-06 실측):\n\n- 작업 ②(PR #14)가 `main` `5ce8597` 로 머지됨. 브랜치 삭제됨\n- `sync.sh` 로 PokeClip 설치본 갱신 완료 — 훅 3개 정본↔설치본 해시 동일, 슬롯 보존 확인\n\n**따라서 이 세션은 게이트 대상이다.** PR #14가 \"하네스 정본 저장소를 고치면 게이트가 선다\"를 켰고,\n이 작업이 바로 그 대상이다. 훅은 세션 시작 시 스냅샷되므로 새 판이 적용된다.\n게이트 4종(듀얼리뷰·설명·볼트·감사)을 다 밟아야 턴이 끝난다 — 의도된 동작이니 우회하지 마라.\n\n착수 시 한 번만 확인:\n\n```bash\ngh pr list --repo xodbs1021/kty-claude-harness-template --state merged --limit 3\n```\n\n`#14` 가 보이면 진행.\n\n## 1. 저장소\n\n새로 클론한다. 정본 클론이 다른 세션에 점유돼 있을 수 있다.\n\n```bash\nS=\"$(pwd)/scratch\"; mkdir -p \"$S\"\ngit clone https://github.com/xodbs1021/kty-claude-harness-template.git \"$S/harness-layer\"\ncd \"$S/harness-layer\" && git checkout -b refactor/knowledge-store-layer origin/main\n```\n\n## 2. 먼저 읽을 것\n\n- `docs/decisions/2026-08-05-knowledge-store-layer-boundary.md` (ADR-0006) — **전문.** 설계는 확정됐다. 재논의 말고 이행만\n- `docs/decisions/2026-08-06-gate-scope-by-file-identity.md` (ADR-0007) — **직전 작업의 결정과 교훈.** 특히 \"과정에서 배운 것\" 절\n- `template/.claude/skills/harness-orchestrator/SKILL.md` — **133줄·135줄**, 166~182줄\n- `template/.claude/harness/harness.env.template`\n- 볼트 `/Users/kty/Documents/valut/Projects/harness-template/index.md` — 미해결 A가 이 작업\n\n## 3. 문제 (2026-08-06 실측)\n\n하네스가 볼트(second brain)의 **구체적 구조를 하드코딩**하고 있다. 볼트 없이 설치하면 게이트가\n존재하지 않는 구조를 요구한다. `README.md` 가 선언한 \"도메인 누출 0\" 과 제0원칙 4번(구체가 아닌\n계약에 의존) 양쪽 위반이다.\n\n```bash\ngit grep -nE \"valut|second brain|_CLAUDE\\.md|4종 세트|needs-vault|Projects/<name>\" -- template/\n```\n\n**10건 / 4파일** (PR #14 이후에도 동일):\n\n| 파일 | 건수 |\n|---|---|\n| `template/.claude/hooks/verify-before-stop.sh` | 6 |\n| `template/.claude/skills/harness-orchestrator/SKILL.md` | 2 |\n| `template/.claude/hooks/mark-needs-audit.sh` | 1 |\n| `template/.claude/hooks/_common.sh` | 1 |\n\n## 4. 확정된 설계 (ADR-0006)\n\n```\n① 계약 (하네스 소유)\n   \"지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다\"\n   볼트를 언급하지 않는다. 경로도 구조도 모른다.\n② 구현체 (볼트 소유) — 하네스를 모른다\n③ 접착 (사용자 층: 전역 ~/.claude/CLAUDE.md)\n```\n\n## 5. 작업 (순서 고정)\n\n### 5-1. `template/` 정리\n\n- 스킬 **135줄**(볼트 반영 게이트) → 계약 수준으로 재작성. 볼트 경로·폴더 구조·파일명 언급 금지\n- 스킬 **133줄**도 `.needs-vault` 와 \"볼트 반영\"을 직접 말한다 — 같이 처리\n- 스킬 135줄과 166~182줄이 **서로 다른 걸 지시한다**(볼트 vs repo). 2026-08-05 확정 —\n  **ADR 전문의 정본은 repo `docs/decisions/`, 볼트는 요약+링크+맥락.** 이걸로 통일.\n  (PR #14가 이 규약대로 ADR-0007을 repo에 남겼다 — 선례가 생겼다)\n- 훅 3개의 `.needs-vault` 처리는 5-3과 함께\n\n### 5-2. 슬롯 신설\n\n`template/.claude/harness/harness.env.template` 에 추가.\n**기존 `HARNESS_TYPECHECK_CMD=\"\"` 관용구를 그대로 따른다 — \"비우면 생략한다\".**\n\n```bash\nHARNESS_KNOWLEDGE_GATE=\"\"\n```\n\n훅은 경로도 구조도 알 필요 없다. 하는 일이 \"플래그가 섰는데 안 지워졌으면 종료 차단\" 이라\n켜짐/꺼짐 하나면 된다. 저장 형식 검증은 볼트 자기 훅이 이미 한다.\n`install.sh` 안내 문구에도 한 줄 추가.\n\n### 5-3. 플래그 개명 — **대상 실측 결과 9파일이다**\n\n`.needs-vault` → `.needs-knowledge`.\n\n```bash\ngit grep -cE \"needs-vault|NEEDS_VAULT|VAULT_FLAG\" -- .\n```\n\n| 파일 | 건수 | 처리 |\n|---|---|---|\n| `template/.claude/hooks/verify-before-stop.sh` | 7 | 개명 |\n| `template/.claude/hooks/mark-needs-audit.sh` | 2 | 개명 |\n| `template/.claude/hooks/_common.sh` | 1 | 개명 |\n| `template/.claude/skills/harness-orchestrator/SKILL.md` | 2 | 개명 |\n| `README.md` | 3 | 개명 |\n| `docs/usage.md` | 2 | 개명 |\n| **`tests/mark-needs-audit.test.sh`** | **1** | **개명** — PR #14 산출물. 빠뜨리면 전건 빨간불 |\n| `docs/decisions/2026-08-05-...boundary.md` | 5 | **판단 필요** — 과거 결정 기록이다. 개명하면 역사를 고친다 |\n| `docs/decisions/2026-08-06-...identity.md` | 1 | **판단 필요** — 위와 동일 |\n\n두 가지를 **결정하고 근거를 남겨라**:\n\n1. **ADR 문서의 옛 플래그 이름을 고칠 것인가.** 안 고치는 쪽을 권한다 — ADR은 그 시점의 결정\n   기록이다. 대신 ADR-0006에 \"이후 `.needs-knowledge` 로 개명됨\" 한 줄을 덧붙이는 방식이 정직하다\n2. **기존 설치본에 남은 구 플래그 파일 처리 방침**\n\n`settings.json` 은 이번 grep에 **안 잡혔다** — 배선이 다른 방식일 수 있으니 직접 확인해라.\n\n### 5-4. 기계 강제 — **5-1~5-3이 끝난 뒤에만**\n\n`scripts/check-layer-boundary.sh` 신설 + `.github/workflows/check-rules.yml` 에 스텝 추가.\n\n- `template/` 아래에서 상위 층 표현 발견 시 exit 1\n- 금지 목록: 볼트 경로 · `second brain` · `_CLAUDE.md` · `4종 세트` · `Projects/<name>/` · `needs-vault`\n- 회귀 테스트도 붙인다. 러너 계약 정본은 `tests/check-rule-copies.test.sh`\n  (`EXPECTED_CASES` 대조 + `CASES` 목록 중복·개수 검사 + `run_check` 센티널 + `mktemp` 가드 +\n  맨 끝 `[ \"$fail\" -eq 0 ] || exit 1`)\n- **CI 스텝 위치 주의**: `check-rules.yml` job 규약이 \"회귀 테스트가 먼저, 사본 대조가 뒤\"다\n\n**지금 켜면 10건으로 즉시 빨간불이다. 반드시 정리 후.**\n검사 범위를 `template/` 로 한정하면 `docs/decisions/` 의 역사 기록은 안 걸린다.\n\n### 5-5. ADR 갱신\n\n- `2026-08-05-knowledge-store-layer-boundary.md` 의 `Status: proposed` → `accepted`. 같은 PR에\n- 이 작업 자체의 결정(개명 방침·ADR 역사 처리·구 플래그 처리)이 판단을 요하면 **ADR-0008** 로\n  남겨라. 번호 0001–0007 사용 중\n\n## 6. 반드시 확인할 것\n\n**접착 층이 비지 않는지.** 스킬에서 \"어디에·어떤 구조로\"를 걷어내면 그 정보를 누가 갖나?\n전역 `~/.claude/CLAUDE.md` 볼트 절과 볼트 `_CLAUDE.md` Section 1을 **읽고 충분한지 판단**해라.\n부족하면 전역 `CLAUDE.md` 를 보강한다(사용자 층이라 파이프라인 밖).\n\n**기존 설치본 영향.** `sync.sh` 는 글루만 갱신하고 슬롯은 보존한다 → **새 슬롯\n`HARNESS_KNOWLEDGE_GATE` 가 자동으로 안 생긴다.** PokeClip 등에서 게이트를 계속 쓰려면\n슬롯을 손으로 채워야 한다 — 완료 보고에 명시해라.\n\n## 7. 규칙\n\n- `template/` 은 배포물이다 → **파이프라인 필수.** `ecc:architect` 로 이행 설계부터 —\n  스킬 재작성 방식·개명 범위·ADR 역사 처리·구 플래그 처리에 판단이 든다\n- 모든 검증 게이트는 Claude + codex 듀얼. codex는 `gpt-5.6-sol` + effort `high` **고정, 하향 금지**\n- 기본 브랜치 직접 커밋 금지, 새 브랜치, squash 전제. **머지는 사용자 승인 후**\n- 롤백 단위가 다른 변경을 커밋에 섞지 마라. 정리(5-1~5-3)와 검사기(5-4)는 축이 다르다\n- force-push는 **사용자 승인 먼저**\n- **검수 라운드 수를 착수 시점에 정해라.** 직전 작업이 열어둔 채로 가서 $560을 썼다.\n  예: \"차단급이 2라운드 연속 안 나오면 통과\" 같은 종료 조건을 먼저 합의해라\n\n## 8. 운영 함정 (직전 세션 실측)\n\n**codex 호출**: (a) git 저장소 **안**에서 실행 (b) `< /dev/null` 필수 — 없으면 stdin 대기로 무한 정지\n(c) `timeout` 은 macOS에 없다 (d) 출력은 파이프 말고 파일로\n\n**사용자에게 주는 셸 명령은 짧게.** 긴 한 줄에 특수문자·줄바꿈이 섞이면 셸이 조용히 멈춘다.\n직전 세션에서 커밋 명령이 **세 번 헛돌았다.** 커밋 메시지는 파일로 빼고 `-F` 로 넘겨라.\n\n**`git checkout -- <파일>` 은 인덱스에서 복원한다.** 인덱스에 구판이 staged 돼 있으면\n**새 구현이 사라진다.** 되돌림 실측은 `cp` 백업/복원만.\n\n**`2>/dev/null` 은 리다이렉트 *열기* 실패를 못 막는다.** 셸이 그 전에 보고한다.\n`{ ...; } 2>/dev/null` 로 감싸야 한다.\n\n**명령 치환은 후행 개행을 먹는다.** 경로 끝 개행은 가드가 보기 전에 사라진다.\n센티널(`printf 'X'` 후 `${v%X}`) 캡처가 필요하다.\n\n**\"겹치는 파일 0개\"는 리베이스 생략의 근거가 못 된다.** 직전 세션이 그 판단으로\n**main이 방금 고친 버그를 다시 들여왔다.** 직전 커밋들이 *무엇을 고쳤는지*를\n파일 목록이 아니라 내용으로 확인해라.\n\n**GNU 검증은 docker로**: `docker run --rm -v <repo>:/src:ro ubuntu:24.04`.\n단 **root로 돌면 `chmod 000` 픽스처가 실패한다**(의도된 fail-closed).\n`useradd` 후 `su` 로 비-root 실행해야 실제 CI 조건과 같다.\n\n**서브에이전트가 자주 죽는다**(API 오류·프로세스 종료). 직전 세션에서 **2회** 죽었다.\n완료 알림 없다고 살아 있다고 넘겨짚지 말고 `ps`/출력 파일 최종수정시각으로 확인.\n프롬프트는 짧게 쪼개라.\n\n**GateGuard 훅**이 파괴적 Bash·신규 파일 생성 등에 사실 제시를 요구한다. 제시해도 Bash 파괴적\n명령은 안 풀리니, 막히면 **사용자에게 명령을 주고 직접 실행하게 하는 게 빠르다.**\n\n**문서에 개수 같은 숫자를 박지 마라** — 기계 정본을 가리켜라.\n\n**검수자 보고를 그대로 믿지 마라** — 직전 세션에서 **네 번** 실측으로 뒤집혔다(그중 하나는\n검수자가 맞고 오케스트레이터의 라벨이 틀렸다). 반대로 검수자가 잡은 CRITICAL 중 실측으로\n확인된 것도 여럿이다. **양방향으로 검증해라.**\n\n**PR 본문도 검수 대상이다.** 직전 세션의 마지막 두 라운드는 차단이 전부 **본문 부정확**이었다.\n본문은 squash 커밋 메시지로 영구 기록된다.\n\n**롤백 검증은 `git apply --check` 말고 실제 `git revert`로.**\n\n## 9. 완료 조건\n\n```bash\ngit grep -E \"valut|second brain|_CLAUDE\\.md|4종 세트|needs-vault|Projects/<name>\" -- template/   # 0건\n./scripts/check-layer-boundary.sh                                                                # exit 0\n./tests/check-rule-copies.test.sh                                                                # 전건 통과\n./tests/mark-needs-audit.test.sh                                                                 # 전건 통과 (개명 반영 확인)\n./scripts/check-rule-copies.sh                                                                   # exit 0\ngh pr checks <PR>                                                                                # 초록\n```\n\n- ADR-0006 `Status: accepted`\n- 볼트 `Projects/harness-template/index.md` 미해결 A를 해소로 갱신\n- **볼트 반영 2건**: 이 작업 + **직전 작업 ②(PR #14)**. ②는 볼트 반영을 이 세션으로 **의도적\n  이월**했고 PR #14 본문에 그렇게 명시돼 있다. ADR-0007이 저장소 쪽 기록이니 볼트에는\n  요약+링크+맥락을 남기면 된다\n- 볼트 끊어진 링크 복구: `Projects/harness-template/decisions/ADR-004.md` 가 **untracked 인데\n  `index.md` 가 링크**하고 있다(PR #12 시기 누락). `git add -A && commit && push`"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/fc61a655-aafe-4647-8be0-6d58b1b786ab.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-08-05T15:27:56.755Z","sessionId":"fc61a655-aafe-4647-8be0-6d58b1b786ab"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-3-development-f7d366/cd1d02ee-1cb8-42a4-ad4e-fb2ff5259bbb.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-22T09:41:18.166Z","sessionId":"cd1d02ee-1cb8-42a4-ad4e-fb2ff5259bbb","content":"넌 3번 개발해"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-3-development-f7d366/cd1d02ee-1cb8-42a4-ad4e-fb2ff5259bbb.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-22T09:41:18.250Z","sessionId":"cd1d02ee-1cb8-42a4-ad4e-fb2ff5259bbb"}
/Users/kty/.claude/projects/-Users-kty-Documents-valut/f398f89b-38fe-4837-85ad-83c1c33e795c.jsonl:1:{"type":"last-prompt","leafUuid":"02360663-daf4-4eb6-bb7d-97f70e40a649","sessionId":"f398f89b-38fe-4837-85ad-83c1c33e795c"}
/Users/kty/.claude/projects/-Users-kty-Documents-valut/f398f89b-38fe-4837-85ad-83c1c33e795c.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"d2899528-8db1-4f97-a0f7-daca653dbde5","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":196},"type":"attachment","uuid":"52e81e06-4f88-4166-81f8-6a18c8800f60","timestamp":"2026-07-22T01:56:29.543Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty/Documents/valut","sessionId":"f398f89b-38fe-4837-85ad-83c1c33e795c","version":"2.1.187","gitBranch":"HEAD"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-pok-36-tfdt-measurement-1dcdba/fa96e2d1-e5f5-4cd0-a291-1a8753153951.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-08-03T02:55:37.845Z","sessionId":"fa96e2d1-e5f5-4cd0-a291-1a8753153951","content":"POK-36 실행해줘 — tfdt 실측 스파이크. 단, 실행 계획을 먼저 세워서 나(kty)한테 점검받고, 승인 후에만 실측을 시작할 것.\n\n## 과제\nJira POK-36: 녹화 fMP4 조각 안의 tfdt(각 조각의 시작 시각이 박히는 fMP4 내부 필드)가 사이드카의\n끊김 정밀 감지·훅 전환에 쓸 만큼 정확한지 실측. 완료 조건은 POK-36 티켓 원문이 정본 — 티켓을 먼저\n읽고 체크박스를 그대로 계획에 옮겨라. 배경: POK-29(사이드카 1단계)의 알려진 제약 L1~L5 중 tfdt로\n해소 가능한 항목(mono PR #12 본문이 정본)을 검토하는 후속이다.\n\n## 먼저 읽을 정본 (순서대로, 전문 읽기 — head -N 부분 독해 금지)\n1. 프로젝트 기억: MEMORY.md 자동 로드 — § 기호 금지(\"N절\"로) / codex는 gpt-5.6-sol + effort high 고정 / Jira는 스토리→티켓 계층(발부 시 위키 agile-flow-preset.md 원문 선독)\n2. Jira POK-36 원문(+상위 이슈) — 완료 조건의 정본\n3. mono PR #12 본문 — 알려진 제약 L1~L5 (tfdt가 뭘 해소해야 하는지의 근거)\n4. mono media/README.md + docs/dev-environment.md — 사이드카 구조·송출 명령·검증 절차\n5. 볼트 /Users/kty/Documents/valut/Projects/PokeClip/index.md(라우팅 맵) → specs/segment-indexer-설계확정판.md의 시각/끊김 관련 절 → 필요 시 specs/계약-세그먼트인덱스.md\n6. 볼트 _CLAUDE.md — 기록 규칙(4종 세트, raw+요약)\n\n## 환경 사실 (2026-08-03 실측 검증됨 — 재확인 후 사용)\n- mono main 39b255c 이상(PR #12 머지), 컨테이너 5종 기동 중(media=MediaMTX 1.19.3, segment-indexer, postgres, redis, media-stub). 시작 전 docker compose up -d --build 1회\n- 송출: 호스트 ffmpeg 8.1.2는 SRT 미포함 → linuxserver/ffmpeg 컨테이너(이미지 로컬 존재)로\n  docker run --rm --network pokeclip_default ... -f mpegts \"srt://media:8890?streamid=publish:$S\"\n  GOP 2초 고정(30fps -g 60), 스트림 ID는 spike식 고유값([A-Za-z0-9_-]{1,64})\n- 녹화 관찰: docker run --rm -v pokeclip_recordings:/r alpine sh -c 'stat -c \"%y %s %n\" /r/$S/*'\n  (BusyBox — ls --full-time 안 됨). 파일을 스크래치로 복사해 호스트에서 분석\n- tfdt 추출 도구는 계획에서 제안·확정할 것 — 호스트 ffprobe는 tfdt를 직접 안 보여주므로\n  mp4 박스 파싱(python 등) 방식을 검토하고, 파싱 결과는 반드시 교차 검증 1회\n- 기지 함정: 첫 세그먼트는 ffmpeg -re 버스트로 ~6초(seq 0 제외하고 분석) / stream_segments의\n  start는 파일명(벽시계), duration은 파일 내부 시간 — 조각 간 어긋남은 정상 상태에서도 -1~-22ms\n- infra/compose/mediamtx.yml 수정 절대 금지. 끊김 시나리오는 송출 중단→재송출(같은 스트림 ID)로 합성\n\n## 산출·기록 의무 (실행 승인 후)\n- 판정 결과: ① POK-36(또는 상위) 코멘트에 캡처 첨부 ② 티켓 완료 조건 충족 시 완료 전환\n  ③ 위키 status.md 해당 항목 갱신안은 내게 제시 → 승인 후에만 push\n  ④ 볼트 Projects/PokeClip에 4종 세트(specs raw 신규 + discussion-log + architecture + index, 같은 커밋,\n  auto-sync push) — 볼트는 승인 불요\n- 훅 전환 \"검토\"가 결론이면 결정이 아니라 검토 의견으로 기록하고, 결정은 내 승인 후\n- 보고는 \"읽어야 할 것 / 결정 필요 / 아카이브\" 3줄 블록 선행, 용어는 등장 자리에서 괄호 풀이\n\n지금 할 일: 위 정본을 읽고 실행 계획(단계·명령 초안·판정 기준·예상 소요·리스크)을 만들어 내게 점검받아라. 승인 전 실측 금지."}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-pok-36-tfdt-measurement-1dcdba/fa96e2d1-e5f5-4cd0-a291-1a8753153951.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-08-03T02:55:37.909Z","sessionId":"fa96e2d1-e5f5-4cd0-a291-1a8753153951"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-pok-36-tfdt-measurement-1dcdba/8b95614d-17aa-4849-bff6-0f83e6ffc8cd.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-08-04T08:24:04.498Z","sessionId":"8b95614d-17aa-4849-bff6-0f83e6ffc8cd","content":"kty-claude-harness-template 하네스 작업 이어서 진행. 이전 세션에서 듀얼 리뷰까지 받고 중단된 상태다.\n\n## 저장소\n- `xodbs1021/kty-claude-harness-template` (private). 새로 클론해서 작업.\n- 이 저장소는 하네스 템플릿 **정본**이다. 즉 작업 자체가 PROJECT_DIR 밖 클론에서 일어나므로, 현재 완료 게이트 훅이 발화하지 않는다(그게 아래 ②의 버그다). 파이프라인은 수동으로 지켜야 한다.\n\n## 현재 상태\n- **PR #10** OPEN (`feat/rule-sync-only`, 커밋 2개) — 제0원칙 판정 기준 정본↔사본 대조 + CI. 머지 가능 수준이나 **2번째 커밋 `357e24f`(위음성 수정)이 아직 리뷰를 안 받았다.**\n- **PR #9** CLOSED — 롤백 단위가 다른 두 변경이 섞여 있어 분리했다.\n- **`backup/gate-scope-v1`** 브랜치에 커밋 `38b36f6` 보존 — 완료 게이트 범위 수정인데 **차단급 결함 4건**이 있어 머지하지 않았다.\n\n## 할 일 ① — PR #10 마감 (먼저)\n커밋 `357e24f`에 Claude(`pr-reviewer`) + codex(`gpt-5.6-sol`, effort **high** 고정, 하향 금지) 듀얼 리뷰를 병렬로 돌린다. 통과하면 사용자 승인 후 머지.\n\n알려진 미해결(수용 여부 판단 필요):\n- `scripts/check-rule-copies.sh` 자체의 테스트 파일이 없다(탬퍼 5종은 수동 검증만 함).\n- `check-rule-copies.sh`의 `ROOT=` 계산이 `pwd -P`가 아니고 `cd` 인자가 상대경로라 `CDPATH` 오염 가능.\n- `.github/workflows/check-rules.yml`에 `permissions: contents: read` 없음.\n\n## 할 일 ② — 완료 게이트 범위 재작업\n`backup/gate-scope-v1`에서 새 브랜치를 따서 `template/.claude/hooks/mark-needs-audit.sh`를 재작성한다. 원래 의도는 \"하네스 자신을 고치는 작업(= 늘 PROJECT_DIR 밖 별도 클론)에도 완료 게이트가 서게 한다\"였는데, 아래가 틀렸다.\n\n**차단급 4건**\n- **B1.** `_workspace/00_design*.md|01_plan*.md` 듀얼리뷰 판정이 경로 재정규화보다 **먼저** 돈다. 프로젝트 밖에서는 `$rel`이 아직 절대경로라 매칭 실패하고, 재정규화 후엔 `_workspace/*` 일괄 스킵에 먹힌다 → **설계만 한 턴은 여전히 게이트 0개.** 고치려던 바로 그 지점이 안 고쳐졌다. 판정을 정규화 뒤로 옮길 것.\n- **B2.** `rel=\"${file_path#\"$PROJECT_DIR\"/}\"`에서 `PROJECT_DIR`을 `pwd -P`로 정규화하지 않는다. 심링크 경로면 strip이 실패해 \"밖\" 분기로 떨어지고, git 루트 기준 경로가 `app/.claude/...` 형태가 되어 **`.claude/`·`_workspace/` 제외가 통째로 무력화**된다(스크래치 편집마다 게이트 4종 발동). 양쪽 다 `pwd -P`로 정규화할 것.\n- **B3.** `$HOME` 예외가 toplevel 정확히 일치일 때만 적용돼 양방향으로 틀렸다. `~/dotfiles`는 걸리고(무관한 저장소가 게이트 발동), `~/.claude`가 git 저장소인 셋업에서는 그 아래 하네스 클론이 **조용히 스킵**된다.\n- **B4.** 플래그 파일에 외부 저장소 기준 **상대**경로가 저장소 표시 없이 들어간다. 프로젝트와 외부 저장소가 `README.md` 같은 흔한 경로를 공유하면 `completion-auditor`가 프로젝트 쪽 동명 파일을 보고 \"확인했다\"고 통과시킨다. 외부 편집은 절대경로로 기록할 것.\n\n**비블로킹(반영 권고)**\n- 글롭 `*/agents/*.md`·`*/skills/*.md`·`*/harness/*.md`가 과대 — `node_modules/x/skills/a.md`, `src/agents/README.md`도 걸린다. `.claude/`로 앵커할 것.\n- `git rev-parse` 호출이 상속된 `GIT_DIR`/`GIT_WORK_TREE`를 안 지운다 → 엉뚱한 저장소로 해석 가능.\n- `.git/hooks/pre-commit` 편집은 `rev-parse`가 실패해 스킵된다.\n- `set -u`에서 `HOME` 미설정 시 예외가 조용히 사라진다 → `${HOME:-}`.\n- `*.md|*.markdown` 대소문자 구분 — `README.MD`가 코드로 취급된다.\n- 플래그 쓰기 실패(권한 없음 등)가 전부 조용히 무시되고 `exit 0` — 게이트가 소리 없이 사라진다.\n\n**테스트** `tests/mark-needs-audit.test.sh` 확장:\n- 훅 종료 코드를 assert(헤더 계약이 \"PostToolUse는 항상 exit 0\"인데 미검증)\n- `.needs-audit`뿐 아니라 `.needs-explain`·`.needs-vault`·`.needs-dualreview` 4종 전부 검증\n- 케이스 추가: 심링크 PROJECT_DIR(B2), 외부 저장소의 설계·계획 문서(B1), `$HOME` 예외 3종, 중첩 저장소·submodule·worktree, 대문자 확장자, 외부 편집의 플래그 값이 절대경로인지(B4)\n- **필수: 수정 전 코드로 되돌려 돌렸을 때 실패하는지 확인**할 것(통과를 위한 통과 방지)\n\n**문서 동기화**\n- `docs/usage.md` 5절 표의 `mark-needs-audit` 행 — \"제외: `_workspace/` 기타·`.claude/`·`*.md`\"가 이 변경으로 두 군데 다 틀려진다.\n- `README.md` 6절 디렉토리 트리에 신규 `tests/` 누락.\n\n## 지켜야 할 규칙\n- 코드 변경은 `harness-orchestrator` 파이프라인을 거친다. 이전 세션에서 \"작아서\" 건너뛰었다가 정확히 그 결함이 나왔다.\n- 모든 검증 게이트는 Claude + codex 듀얼. codex는 `gpt-5.6-sol` + effort `high` 고정, 임의 하향 금지.\n- 기본 브랜치 직접 커밋 금지, 기능마다 새 브랜치, squash 전제. 머지는 사용자 승인 후.\n- 커밋을 묶을 때 롤백 단위가 다른 변경을 섞지 말 것(PR #9이 그래서 닫혔다)."}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-pok-36-tfdt-measurement-1dcdba/8b95614d-17aa-4849-bff6-0f83e6ffc8cd.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-08-04T08:24:04.534Z","sessionId":"8b95614d-17aa-4849-bff6-0f83e6ffc8cd"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-data-layout-restructure-2fb54d/d3af3b92-279c-4c44-b238-3ee8bebf2a5d.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-14T04:47:41.989Z","sessionId":"d3af3b92-279c-4c44-b238-3ee8bebf2a5d","content":"data-layout-restructure 메모리의 리팩터를 시작한다. PR1부터.\n목표: data 저장을 방송 단위 세션 디렉토리로 (chat/<provider>, frame/<provider>).\n\nPR1 = 방송 라이프사이클 + recorder 재작성:\n- broadcastId 발급, 연결(라이브만)과 녹화(저장) 분리\n- '녹화 시작/종료' 이벤트 신설, data/<broadcastId>/chat/<provider>/ 에 쓰기\n- 방송 종료 감지 후 grace 몇 분 뒤 자동 녹화 종료 (config 상수)\n착수 전 설계(방송 상태머신·broadcastId 규칙·grace 시간)를 먼저 제시하고 내 승인을 받아라.\n기존 data/chat-sessions/ 는 무시해도 된다. 한 PR=한 논리적 변경, master에서 브랜치, squash, 머지는 내 승인 후."}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-data-layout-restructure-2fb54d/d3af3b92-279c-4c44-b238-3ee8bebf2a5d.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-14T04:47:42.023Z","sessionId":"d3af3b92-279c-4c44-b238-3ee8bebf2a5d"}
/Users/kty/.claude/projects/-Users-kty-Downloads/91d7f20e-0666-4cc5-9eb4-c20506c6b7bf.jsonl:1:{"type":"last-prompt","leafUuid":"03de4d2a-7048-48f4-a646-846ccbb96801","sessionId":"91d7f20e-0666-4cc5-9eb4-c20506c6b7bf"}
/Users/kty/.claude/projects/-Users-kty-Downloads/91d7f20e-0666-4cc5-9eb4-c20506c6b7bf.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"c57a293a-0da2-4544-bade-1d7a81ded134","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":394},"type":"attachment","uuid":"492ea27a-1dec-4ef7-9bf3-9cc25a28d605","timestamp":"2026-07-30T12:04:42.020Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty/Downloads","sessionId":"91d7f20e-0666-4cc5-9eb4-c20506c6b7bf","version":"2.1.206","gitBranch":"HEAD"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/613cfb3d-5d59-4826-8578-78b68efd61fc/subagents/agent-ad511443ba29f165a.jsonl:2:{"parentUuid":"64e0068f-0305-498c-be1e-7ef51bcb725c","isSidechain":true,"agentId":"ad511443ba29f165a","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.\n- plan-prd: Generate a lean, problem-first PRD and hand off to /plan for implementation planning.\n- pm2: Analyze a project and generate PM2 service commands for detected frontend, backend, or database services.\n- pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- project-init: Detect a project's stack and produce a dry-run ECC onboarding plan using the repository's install manifests and stack mappings.\n- projects: List known projects and their instinct statistics\n- promote: Promote project-scoped instincts to global scope\n- prp-commit: Quick commit with natural language file targeting — describe what to commit in plain English\n- prp-implement: Execute an implementation plan with rigorous validation loops\n- prp-plan: Create comprehensive feature implementation plan with codebase analysis and pattern extraction\n- prp-pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- prp-prd: Interactive PRD generator - problem-first, hypothesis-driven product spec with back-and-forth questioning\n- prune: Delete pending instincts older than 30 days that were never promoted\n- python-review: Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent.\n- quality-gate: Run the ECC formatter quality gate for a single file and report remediation steps.\n- react-build: Fix React build failures (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) incrementally — JSX/TSX compile errors, hydration mismatches, server/client component boundary failures, missing types. Invokes the react-build-resolver agent for minimal, surgical fixes.\n- react-review: Comprehensive React/JSX code review for hook correctness, render performance, server/client component boundaries, accessibility, and React-specific security. Invokes the react-reviewer agent (and typescript-reviewer alongside on TSX/JSX changes).\n- react-test: Enforce TDD workflow for React. Write React Testing Library tests first (behavior-focused, accessibility-first), then implement components. Detects Vitest or Jest and verifies coverage targets.\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- deep-research: Deep research harness — fan-out web searches, fetch sources, adversarially verify claims, synthesize a cited report. - When the user wants a deep, multi-source, fact-checked research report on any topic. BEFORE invoking, check if the question is specific enough to research directly — if underspecified (e.g., \"what car to buy\" without budget/use-case/region), ask 2-3 clarifying questions to narrow scope. Then pass the refined question as args, weaving the answers in.\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure: Enable or disable hookify rules interactively\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf\n- anthropic-skills:pptx\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":542,"isInitial":true,"names":["find-skills","harness-orchestrator","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","deep-research","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"2821ef2a-46d1-4b22-9c65-79a90e827191","timestamp":"2026-07-22T14:21:52.360Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/second-brain-setup-2769bd","sessionId":"613cfb3d-5d59-4826-8578-78b68efd61fc","version":"2.1.217","gitBranch":"main","slug":"bright-tumbling-avalanche"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-pok-36-tfdt-measurement-1dcdba/8b95614d-17aa-4849-bff6-0f83e6ffc8cd/subagents/agent-aaeffc7be1670b556.jsonl:2:{"parentUuid":"432a5547-282b-4ede-b495-5214af58e87e","isSidechain":true,"agentId":"aaeffc7be1670b556","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- readable-writing: 사용자 대면 문서·설계서·PR 본문·주석을 쓸 때 반드시 사용. 가독성 원칙(인지 부하 최소화·용어 즉석 풀이·핵심 선행)을 적용해 \"처음 보는 사람도 한 번에 읽히는\" 글을 만든다. \"가독성 있게\", \"읽기 쉽게\", \"주석 자세히\", \"설명 달아줘\" 요청 시 트리거.\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan\n- plan-prd\n- pm2\n- pr\n- project-init\n- projects\n- promote\n- prp-commit\n- prp-implement\n- prp-plan\n- prp-pr\n- prp-prd\n- prune\n- python-review\n- quality-gate\n- react-build\n- react-review\n- react-test\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- plugin-dev:create-plugin: Guided end-to-end plugin creation workflow with component design, implementation, and validation\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find: Smart vault search - returns results with context, not just filenames\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save: Save everything worth keeping from this conversation to the vault\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- plugin-dev:agent-development\n- plugin-dev:command-development\n- plugin-dev:hook-development\n- plugin-dev:mcp-integration\n- plugin-dev:plugin-settings\n- plugin-dev:plugin-structure: This skill should be used when the user asks to \"create a plugin\", \"scaffold a plugin\", \"understand plugin structure\", \"organize plugin components\", \"set up plugin.json\", \"use ${CLAUDE_PLUGIN_ROOT}\", \"add commands/agents/skills/hooks\", \"configure auto-discovery\", or needs guidance on plugin directory layout, manifest configuration, component organization, file naming conventions, or Claude Code plugin architecture best practices.\n- plugin-dev:skill-development: This skill should be used when the user wants to \"create a skill\", \"add a skill to plugin\", \"write a new skill\", \"improve skill description\", \"organize skill content\", or needs guidance on skill structure, progressive disclosure, or skill development best practices for Claude Code plugins.\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf: Use this skill whenever the user wants to do anything with PDF files. This includes reading or extracting text/tables from PDFs, combining or merging multiple PDFs into one, splitting PDFs apart, rotating pages, adding watermarks, creating new PDFs, filling PDF forms, encrypting/decrypting PDFs, extracting images, and OCR on scanned PDFs to make them searchable. If the user mentions a .pdf file or asks to produce one, use this skill.\n- anthropic-skills:pptx: Use this skill any time a .pptx or .potx file is involved in any way — as input, output, or both. This includes: creating slide decks, pitch decks, or presentations; reading, parsing, or extracting text from any .pptx or .potx file (even if the extracted content will be used elsewhere, like in an email or summary); editing, modifying, or updating existing presentations; combining or splitting slide files; working with templates (.potx), layouts, speaker notes, or comments. Trigger whenever the user mentions \"deck,\" \"slides,\" \"presentation,\" or references a .pptx or .potx filename, regardless of what they plan to do with the content afterward. If a .pptx or .potx file needs to be opened, created, or touched, use this skill.\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":550,"isInitial":true,"names":["find-skills","harness-orchestrator","readable-writing","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","plugin-dev:create-plugin","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","plugin-dev:agent-development","plugin-dev:command-development","plugin-dev:hook-development","plugin-dev:mcp-integration","plugin-dev:plugin-settings","plugin-dev:plugin-structure","plugin-dev:skill-development","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"d0a193c5-e9b7-4f5b-9cd7-51a03049ade8","timestamp":"2026-08-04T08:38:06.013Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/pokeclip-mono/.claude/worktrees/pok-36-tfdt-measurement-1dcdba","sessionId":"8b95614d-17aa-4849-bff6-0f83e6ffc8cd","version":"2.1.219","gitBranch":"claude/harness-template-pr10-gate-fix-da3c4d"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-priceless-spence-f96ade/cbe0511d-74a0-4008-92ab-ebd721436130.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-14T15:36:22.874Z","sessionId":"cbe0511d-74a0-4008-92ab-ebd721436130","content":"모든 개발의 제 0원칙은 SOLID 법칙을 따라간다 기계가 아닌 사람이 이해할 수 있는 모듈 단위로 제작, 메서드 단위로 제작하는게 기본 전제임\n\ndata-layout-restructure 리팩터 PR2를 시작한다. (PR1은 #30로 squash 머지 완료 — master의 ac5f97d)\n\n목표: 프레임 캡처를 방송 단위 세션 디렉토리로 세션화한다.\n- 프레임 저장을 전역 경로(현재 data/chat-sessions/frames/{chzzk,soop}/)에서\n  data/<broadcastId>/frame/<provider>/ 로 옮긴다.\n- 캡처를 \"연결 중 상시\"에서 \"녹화 중에만\"으로 바꾼다 (PR1의 연결⊥녹화 분리를 프레임에도 적용).\n\nPR1이 이미 만들어 둔 것(그대로 활용):\n- recorder에 방송 라이프사이클(startRecording/stopRecording/isRecording, activeBroadcast, broadcastId).\n- 소켓 이벤트 recording:start / recording:stop, 자동종료 grace(3분, RECORD_GRACE_MS).\n- src/server/broadcast/BroadcastPaths (chat 경로 단일 진실원) — 여기에 frameDir(broadcastId, provider) 추가.\n- 저장 루트는 chatDataDir(./data/chat-sessions) 유지 → 실제 경로는 ./data/chat-sessions/<broadcastId>/frame/<provider>/.\n\n영향 코드(먼저 읽고 파악):\n- src/server/index.ts: FrameCaptureManager 2개를 고정 경로로 생성(≈47·54행), connect 시 primeCaptureAndWait로 캡처 선기동(상시). 여기서 캡처를 \"녹화 시작 시 방송 경로로 기동 / 녹화 종료 시 중단\"으로 옮긴다.\n- src/server/frameCapture.ts: framesDir가 생성자에 고정 → 방송별 경로 주입/재설정 가능하게 개조.\n- src/server/routes/frames.ts, frameIndexClient 등 프레임 read 경로는 PR3 범위(이번엔 seam만 유지, 깨지 않게).\n\n착수 전 설계를 먼저 제시하고 내 승인을 받아라. 특히 이 결정들을 선택지와 함께 물어라:\n1) 캡처를 connect→record로 옮길 때, \"연결만 한 상태\"에서 라이브 프리뷰용 캡처를 유지할지 아니면 캡처를 녹화에만 묶을지(메모리 결정 #5는 \"녹화 중에만 캡처\"). 그리고 기존 connect 시 캡처 readiness 게이팅(primeCaptureAndWait/waitUntilReady/\"이미지 준비 중...\")을 어떻게 처리할지.\n2) grace 3분 동안 캡처를 계속할지 녹화 종료 시점에 멈출지(채팅과 일관되게).\n3) FrameCaptureManager를 방송마다 재생성할지, framesDir를 start()에 주입할지(모듈 형태).\n4) 프레임 read API(routes/frames.ts)가 아직 전역 provider 기준이라, PR2에서 write만 방송범위로 바뀌면 read가 안 맞는 구간이 생김 — PR1의 sessionId seam처럼 PR2 green을 유지할 seam 방식.\n\n규칙(하네스): 코드 변경이니 chat-harness로. 한 PR=한 논리적 변경, master에서 새 브랜치, squash, 머지는 내 승인 후. 착수 전 설계 승인 게이트 먼저. data-layout-restructure 메모리에 확정 결정·4PR 계획 있으니 참조."}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-priceless-spence-f96ade/cbe0511d-74a0-4008-92ab-ebd721436130.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-14T15:36:22.920Z","sessionId":"cbe0511d-74a0-4008-92ab-ebd721436130"}
/Users/kty/.claude/projects/-Users-kty-Downloads/a4df6269-ef9c-4275-9ff2-61041ea546c7.jsonl:1:{"type":"last-prompt","leafUuid":"b5673bf3-85fe-4574-b9c3-ae3c065b15e1","sessionId":"a4df6269-ef9c-4275-9ff2-61041ea546c7"}
/Users/kty/.claude/projects/-Users-kty-Downloads/a4df6269-ef9c-4275-9ff2-61041ea546c7.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"c4e69bd4-ef10-42dc-aa6d-f4b1e6deab17","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":383},"type":"attachment","uuid":"fdeee54b-c793-4885-977c-52313f17fcd8","timestamp":"2026-07-26T16:24:35.873Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty/Downloads","sessionId":"a4df6269-ef9c-4275-9ff2-61041ea546c7","version":"2.1.206","gitBranch":"HEAD"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-ac27434546eeb7171.jsonl:2:{"parentUuid":"df615201-c0c6-4cce-9ab0-e1ca92ec0210","isSidechain":true,"agentId":"ac27434546eeb7171","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.\n- plan-prd: Generate a lean, problem-first PRD and hand off to /plan for implementation planning.\n- pm2: Analyze a project and generate PM2 service commands for detected frontend, backend, or database services.\n- pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- project-init: Detect a project's stack and produce a dry-run ECC onboarding plan using the repository's install manifests and stack mappings.\n- projects: List known projects and their instinct statistics\n- promote: Promote project-scoped instincts to global scope\n- prp-commit: Quick commit with natural language file targeting — describe what to commit in plain English\n- prp-implement: Execute an implementation plan with rigorous validation loops\n- prp-plan: Create comprehensive feature implementation plan with codebase analysis and pattern extraction\n- prp-pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- prp-prd: Interactive PRD generator - problem-first, hypothesis-driven product spec with back-and-forth questioning\n- prune: Delete pending instincts older than 30 days that were never promoted\n- python-review: Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent.\n- quality-gate: Run the ECC formatter quality gate for a single file and report remediation steps.\n- react-build: Fix React build failures (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) incrementally — JSX/TSX compile errors, hydration mismatches, server/client component boundary failures, missing types. Invokes the react-build-resolver agent for minimal, surgical fixes.\n- react-review: Comprehensive React/JSX code review for hook correctness, render performance, server/client component boundaries, accessibility, and React-specific security. Invokes the react-reviewer agent (and typescript-reviewer alongside on TSX/JSX changes).\n- react-test: Enforce TDD workflow for React. Write React Testing Library tests first (behavior-focused, accessibility-first), then implement components. Detects Vitest or Jest and verifies coverage targets.\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- deep-research: Deep research harness — fan-out web searches, fetch sources, adversarially verify claims, synthesize a cited report. - When the user wants a deep, multi-source, fact-checked research report on any topic. BEFORE invoking, check if the question is specific enough to research directly — if underspecified (e.g., \"what car to buy\" without budget/use-case/region), ask 2-3 clarifying questions to narrow scope. Then pass the refined question as args, weaving the answers in.\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure: Enable or disable hookify rules interactively\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf\n- anthropic-skills:pptx\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":542,"isInitial":true,"names":["find-skills","harness-orchestrator","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","deep-research","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"dafd2523-44cc-497e-8266-4dd60cc8f9e6","timestamp":"2026-07-23T02:38:16.730Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/backbone-router-pipeline-integration-4da024","sessionId":"feaf19fe-7914-46ab-afc1-f463a3047884","version":"2.1.217","gitBranch":"claude/backbone-router-pipeline-integration-4da024"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pratice/c74d7c4b-fb9c-4fd5-9f3e-67e534c4e066.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-17T03:50:09.764Z","sessionId":"c74d7c4b-fb9c-4fd5-9f3e-67e534c4e066","content":"ralph.sh+claude.me를 복사하라던대"}
/Users/kty/.claude/projects/-Users-kty-Downloads-pratice/c74d7c4b-fb9c-4fd5-9f3e-67e534c4e066.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-17T03:50:09.847Z","sessionId":"c74d7c4b-fb9c-4fd5-9f3e-67e534c4e066"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-second-brain-setup-2769bd/cbed9984-669d-4082-9f25-dbf386a3756a/subagents/agent-a0ef0305eebe1bf06.jsonl:2:{"parentUuid":"84a2128e-d867-4cbd-9017-f1bb738f6662","isSidechain":true,"agentId":"a0ef0305eebe1bf06","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.\n- plan-prd: Generate a lean, problem-first PRD and hand off to /plan for implementation planning.\n- pm2: Analyze a project and generate PM2 service commands for detected frontend, backend, or database services.\n- pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- project-init: Detect a project's stack and produce a dry-run ECC onboarding plan using the repository's install manifests and stack mappings.\n- projects: List known projects and their instinct statistics\n- promote: Promote project-scoped instincts to global scope\n- prp-commit: Quick commit with natural language file targeting — describe what to commit in plain English\n- prp-implement: Execute an implementation plan with rigorous validation loops\n- prp-plan: Create comprehensive feature implementation plan with codebase analysis and pattern extraction\n- prp-pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- prp-prd: Interactive PRD generator - problem-first, hypothesis-driven product spec with back-and-forth questioning\n- prune: Delete pending instincts older than 30 days that were never promoted\n- python-review: Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent.\n- quality-gate: Run the ECC formatter quality gate for a single file and report remediation steps.\n- react-build: Fix React build failures (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) incrementally — JSX/TSX compile errors, hydration mismatches, server/client component boundary failures, missing types. Invokes the react-build-resolver agent for minimal, surgical fixes.\n- react-review: Comprehensive React/JSX code review for hook correctness, render performance, server/client component boundaries, accessibility, and React-specific security. Invokes the react-reviewer agent (and typescript-reviewer alongside on TSX/JSX changes).\n- react-test: Enforce TDD workflow for React. Write React Testing Library tests first (behavior-focused, accessibility-first), then implement components. Detects Vitest or Jest and verifies coverage targets.\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- deep-research: Deep research harness — fan-out web searches, fetch sources, adversarially verify claims, synthesize a cited report. - When the user wants a deep, multi-source, fact-checked research report on any topic. BEFORE invoking, check if the question is specific enough to research directly — if underspecified (e.g., \"what car to buy\" without budget/use-case/region), ask 2-3 clarifying questions to narrow scope. Then pass the refined question as args, weaving the answers in.\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure: Enable or disable hookify rules interactively\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf\n- anthropic-skills:pptx\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":542,"isInitial":true,"names":["find-skills","harness-orchestrator","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","deep-research","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"298856c6-5f29-41c6-98e1-68fd4a0f64d3","timestamp":"2026-07-23T06:18:42.412Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/second-brain-setup-2769bd","sessionId":"cbed9984-669d-4082-9f25-dbf386a3756a","version":"2.1.217","gitBranch":"feat/promote-drawio-diagrams"}
/Users/kty/.claude/projects/-Users-kty/b303e8c9-d1da-4a33-ba7e-ba353b33a53b.jsonl:1:{"type":"last-prompt","leafUuid":"544f8035-540f-4b70-a2c1-f2e5c8658c63","sessionId":"b303e8c9-d1da-4a33-ba7e-ba353b33a53b"}
/Users/kty/.claude/projects/-Users-kty/b303e8c9-d1da-4a33-ba7e-ba353b33a53b.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"761a8576-5f02-4eb6-a47e-919ca3b5579a","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":377},"type":"attachment","uuid":"7140ba18-64ea-46b5-95ca-2aa805628e75","timestamp":"2026-08-04T13:40:37.597Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty","sessionId":"b303e8c9-d1da-4a33-ba7e-ba353b33a53b","version":"2.1.212","gitBranch":"HEAD"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-adoring-pasteur-1cab64/4495a13f-b5b4-494b-bf1d-59b8853a2f0e.jsonl:1:{"type":"queue-operation","operation":"enqueue","timestamp":"2026-07-11T02:02:18.962Z","sessionId":"4495a13f-b5b4-494b-bf1d-59b8853a2f0e"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-adoring-pasteur-1cab64/4495a13f-b5b4-494b-bf1d-59b8853a2f0e.jsonl:2:{"type":"queue-operation","operation":"dequeue","timestamp":"2026-07-11T02:02:19.010Z","sessionId":"4495a13f-b5b4-494b-bf1d-59b8853a2f0e"}
/Users/kty/.claude/projects/-Users-kty/912abc98-39d3-4b11-8440-393e464e699f.jsonl:1:{"type":"last-prompt","leafUuid":"3b95d8da-1cb5-4bfa-8d81-d87bf91a3a48","sessionId":"912abc98-39d3-4b11-8440-393e464e699f"}
/Users/kty/.claude/projects/-Users-kty/912abc98-39d3-4b11-8440-393e464e699f.jsonl:4:{"parentUuid":null,"isSidechain":false,"attachment":{"type":"hook_success","hookName":"SessionStart:startup","toolUseID":"9ef920a6-677e-4c85-b8d2-ec1132dec5e4","hookEvent":"SessionStart","content":"","stdout":"{\"hookSpecificOutput\": {\"hookEventName\": \"SessionStart\", \"additionalContext\": \"**Skill root** (obsidian-second-brain): `/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0`\\nIts bundled `scripts/`, `references/`, and `commands/` live under that path. To run a bundled script from any working directory, hand the root to uv, e.g. `uv run --directory \\\"/Users/kty/.claude/plugins/cache/obsidian-second-brain/obsidian-second-brain/0.14.0\\\" -m scripts.research.research \\\"<topic>\\\"`. Do not cd, and do not assume a cloned-repo location.\\n\"}}","stderr":"","exitCode":0,"command":"python3 \"${CLAUDE_PLUGIN_ROOT}/hooks/load_vault_context.py\"","durationMs":261},"type":"attachment","uuid":"18de31f2-c0f3-49d9-b994-0298ba9d837d","timestamp":"2026-07-19T04:15:10.930Z","userType":"external","entrypoint":"cli","cwd":"/Users/kty","sessionId":"912abc98-39d3-4b11-8440-393e464e699f","version":"2.1.187","gitBranch":"HEAD"}
/Users/kty/.claude/projects/-Users-kty-Downloads-PokeClip-architecture--claude-worktrees-backbone-router-pipeline-integration-4da024/feaf19fe-7914-46ab-afc1-f463a3047884/subagents/agent-ae2065a40fbb05a31.jsonl:2:{"parentUuid":"de0311d0-d773-4220-b23c-9d558a6937b8","isSidechain":true,"agentId":"ae2065a40fbb05a31","attachment":{"type":"skill_listing","content":"- find-skills: Helps users discover and install agent skills when they ask questions like \"how do I do X\", \"find a skill for X\", \"is there a skill that can...\", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.\n- harness-orchestrator: 이 프로젝트의 개발 작업 전체를 조율하는 오케스트레이터. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사 파이프라인을 에이전트 팀으로 실행한다. 기능 추가/수정/버그수정/리팩터링 등 코드 변경을 수반하는 모든 작업 요청 시 반드시 사용. \"개발해줘\", \"기능 추가\", \"고쳐줘\", \"만들어줘\", \"구현해줘\", \"계획 세워줘\", \"검수해줘\", \"점검해줘\", \"PR 올려줘/만들어줘\", \"다시 해줘\", \"재실행\", \"보완\", \"수정해줘\", \"이전 결과 기반으로\" 시 트리거. 단순 질문·설명·조회는 직접 응답 가능(변경 설명은 change-explainer, 설계 의도는 architecture-guide 직접 호출).\n- aside: Answer a quick side question without interrupting or losing context from the current task. Resume work automatically after answering.\n- build-fix: Detect the project build system and incrementally fix build/type errors with minimal safe changes.\n- checkpoint: Create, verify, or list workflow checkpoints after running verification checks.\n- code-review: Code review — local uncommitted changes or GitHub PR (pass PR number/URL for PR mode)\n- cost-report: Generate a local Claude Code cost report from the ECC cost-tracker metrics log.\n- cpp-build: Fix C++ build errors, CMake issues, and linker problems incrementally. Invokes the cpp-build-resolver agent for minimal, surgical fixes.\n- cpp-review: Comprehensive C++ code review for memory safety, modern C++ idioms, concurrency, and security. Invokes the cpp-reviewer agent.\n- cpp-test: Enforce TDD workflow for C++. Write GoogleTest tests first, then implement. Verify coverage with gcov/lcov.\n- ecc-guide: Navigate ECC's current agents, skills, commands, hooks, install profiles, and docs from the live repository surface.\n- epic-claim: Claim an epic issue, stamp coordination state, and sync local ownership.\n- epic-decompose: Break an epic into task children without creating task branches.\n- epic-publish: Publish a validated epic update back to the issue and local cache.\n- epic-review: Mark epic review requested, approved, or changes requested.\n- epic-sync: Sync epic issue bodies, labels, and local coordination snapshots from GitHub.\n- epic-unblock: Sweep blocked epic issues and reopen anything whose dependencies are closed.\n- epic-validate: Validate epic readiness, dependencies, and coordination policy.\n- evolve: Analyze instincts and suggest or generate evolved structures\n- fastapi-review: Review a FastAPI application for architecture, async correctness, dependency injection, Pydantic schemas, security, performance, and testability.\n- feature-dev: Guided feature development with codebase understanding and architecture focus\n- flutter-build: Fix Dart analyzer errors and Flutter build failures incrementally. Invokes the dart-build-resolver agent for minimal, surgical fixes.\n- flutter-review: Review Flutter/Dart code for idiomatic patterns, widget best practices, state management, performance, accessibility, and security. Invokes the flutter-reviewer agent.\n- flutter-test: Run Flutter/Dart tests, report failures, and incrementally fix test issues. Covers unit, widget, golden, and integration tests.\n- gan-build: Run a generator/evaluator build loop for implementation tasks with bounded iterations and scoring.\n- gan-design: Run a generator/evaluator design loop for frontend or visual work with bounded iterations and scoring.\n- go-build: Fix Go build errors, go vet warnings, and linter issues incrementally. Invokes the go-build-resolver agent for minimal, surgical fixes.\n- go-review: Comprehensive Go code review for idiomatic patterns, concurrency safety, error handling, and security. Invokes the go-reviewer agent.\n- go-test: Enforce TDD workflow for Go. Write table-driven tests first, then implement. Verify 80%+ coverage with go test -cover.\n- gradle-build: Fix Gradle build errors for Android and KMP projects\n- harness-audit: Run a deterministic repository harness audit and return a prioritized scorecard.\n- hookify: Create hooks to prevent unwanted behaviors from conversation analysis or explicit instructions\n- hookify-configure: Enable or disable hookify rules interactively\n- hookify-help: Get help with the hookify system\n- hookify-list: List all configured hookify rules\n- instinct-export: Export instincts from project/global scope to a file\n- instinct-import: Import instincts from file or URL into project/global scope\n- instinct-status: Show learned instincts (project + global) with confidence\n- jira: Retrieve a Jira ticket, analyze requirements, update status, or add comments. Uses the jira-integration skill and MCP or REST API.\n- kotlin-build: Fix Kotlin/Gradle build errors, compiler warnings, and dependency issues incrementally. Invokes the kotlin-build-resolver agent for minimal, surgical fixes.\n- kotlin-review: Comprehensive Kotlin code review for idiomatic patterns, null safety, coroutine safety, and security. Invokes the kotlin-reviewer agent.\n- kotlin-test: Enforce TDD workflow for Kotlin. Write Kotest tests first, then implement. Verify 80%+ coverage with Kover.\n- learn: Extract reusable patterns from the current session and save them as candidate skills or guidance.\n- learn-eval: Extract reusable patterns from the session, self-evaluate quality before saving, and determine the right save location (Global vs Project).\n- loop-start: Start a managed autonomous loop pattern with safety defaults and explicit stop conditions.\n- loop-status: Inspect active loop state, progress, failure signals, and recommended intervention.\n- marketing-campaign: Plan and execute a full marketing campaign. Accepts a product brief and returns positioning, landing page copy, email sequence, social posts, ad variants, video scripts, and a content calendar. Can also review existing copy for conversion quality.\n- model-route: Recommend the best model tier for the current task based on complexity, risk, and budget.\n- multi-backend: Run a backend-focused multi-model workflow for APIs, algorithms, data, and business logic.\n- multi-execute: Execute a multi-model implementation plan while preserving Claude as the only filesystem writer.\n- multi-frontend: Run a frontend-focused multi-model workflow for components, layouts, animation, and UI polish.\n- multi-plan: Create a multi-model implementation plan without modifying production code.\n- multi-workflow: Run a full multi-model development workflow with research, planning, execution, optimization, and review.\n- orch-add-feature: Orchestrate building a brand-new feature end to end — research, plan, TDD, review, gated commit. Wrapper that kicks off the orch-add-feature skill.\n- orch-build-mvp: Orchestrate bootstrapping a working MVP from a design/spec doc — ingest, slice, scaffold, TDD, review, gated commit (reuses the GAN harness). Wrapper for the orch-build-mvp skill.\n- orch-change-feature: Orchestrate altering an existing, working feature to new desired behavior — update tests to the new spec, change impl, review, gated commit. Wrapper for the orch-change-feature skill.\n- orch-fix-defect: Orchestrate fixing a bug — reproduce it as a failing regression test, fix to green, review, gated commit. Wrapper for the orch-fix-defect skill.\n- orch-refine-code: Orchestrate a behavior-preserving refactor — confirm tests green, restructure without changing behavior, keep green, review, gated commit. Wrapper for the orch-refine-code skill.\n- plan: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.\n- plan-prd: Generate a lean, problem-first PRD and hand off to /plan for implementation planning.\n- pm2: Analyze a project and generate PM2 service commands for detected frontend, backend, or database services.\n- pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- project-init: Detect a project's stack and produce a dry-run ECC onboarding plan using the repository's install manifests and stack mappings.\n- projects: List known projects and their instinct statistics\n- promote: Promote project-scoped instincts to global scope\n- prp-commit: Quick commit with natural language file targeting — describe what to commit in plain English\n- prp-implement: Execute an implementation plan with rigorous validation loops\n- prp-plan: Create comprehensive feature implementation plan with codebase analysis and pattern extraction\n- prp-pr: Create a GitHub PR from current branch with unpushed commits — discovers templates, analyzes changes, pushes\n- prp-prd: Interactive PRD generator - problem-first, hypothesis-driven product spec with back-and-forth questioning\n- prune: Delete pending instincts older than 30 days that were never promoted\n- python-review: Comprehensive Python code review for PEP 8 compliance, type hints, security, and Pythonic idioms. Invokes the python-reviewer agent.\n- quality-gate: Run the ECC formatter quality gate for a single file and report remediation steps.\n- react-build: Fix React build failures (Vite, webpack, Next.js, CRA, Parcel, esbuild, Bun) incrementally — JSX/TSX compile errors, hydration mismatches, server/client component boundary failures, missing types. Invokes the react-build-resolver agent for minimal, surgical fixes.\n- react-review: Comprehensive React/JSX code review for hook correctness, render performance, server/client component boundaries, accessibility, and React-specific security. Invokes the react-reviewer agent (and typescript-reviewer alongside on TSX/JSX changes).\n- react-test: Enforce TDD workflow for React. Write React Testing Library tests first (behavior-focused, accessibility-first), then implement components. Detects Vitest or Jest and verifies coverage targets.\n- refactor-clean\n- resume-session: Load the most recent session file from ~/.claude/session-data/ and resume work with full context from where the last session ended.\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session: Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.\n- security-scan\n- sessions: Manage Claude Code session history, aliases, and session metadata.\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- deep-research: Deep research harness — fan-out web searches, fetch sources, adversarially verify claims, synthesize a cited report. - When the user wants a deep, multi-source, fact-checked research report on any topic. BEFORE invoking, check if the question is specific enough to research directly — if underspecified (e.g., \"what car to buy\" without budget/use-case/region), ask 2-3 clarifying questions to narrow scope. Then pass the refined question as args, weaving the answers in.\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure: Enable or disable hookify rules interactively\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- obsidian-second-brain:create-command\n- obsidian-second-brain:idea-discovery\n- obsidian-second-brain:notebooklm\n- obsidian-second-brain:obsidian-architect\n- obsidian-second-brain:obsidian-board-hygiene\n- obsidian-second-brain:obsidian-board\n- obsidian-second-brain:obsidian-brainstorm\n- obsidian-second-brain:obsidian-calendar\n- obsidian-second-brain:obsidian-capture\n- obsidian-second-brain:obsidian-catchup\n- obsidian-second-brain:obsidian-challenge\n- obsidian-second-brain:obsidian-connect\n- obsidian-second-brain:obsidian-daily\n- obsidian-second-brain:obsidian-decide\n- obsidian-second-brain:obsidian-distill\n- obsidian-second-brain:obsidian-emerge\n- obsidian-second-brain:obsidian-export\n- obsidian-second-brain:obsidian-find\n- obsidian-second-brain:obsidian-graduate\n- obsidian-second-brain:obsidian-health\n- obsidian-second-brain:obsidian-ingest\n- obsidian-second-brain:obsidian-init: Scan your vault and generate a _CLAUDE.md operating manual, index.md catalog, and log.md pointer\n- obsidian-second-brain:obsidian-learn\n- obsidian-second-brain:obsidian-log\n- obsidian-second-brain:obsidian-panel\n- obsidian-second-brain:obsidian-person\n- obsidian-second-brain:obsidian-project\n- obsidian-second-brain:obsidian-projects\n- obsidian-second-brain:obsidian-recap\n- obsidian-second-brain:obsidian-reconcile\n- obsidian-second-brain:obsidian-recurring\n- obsidian-second-brain:obsidian-retrieval-eval\n- obsidian-second-brain:obsidian-review\n- obsidian-second-brain:obsidian-save\n- obsidian-second-brain:obsidian-synthesize\n- obsidian-second-brain:obsidian-task\n- obsidian-second-brain:obsidian-visualize\n- obsidian-second-brain:obsidian-world\n- obsidian-second-brain:podcast\n- obsidian-second-brain:research-deep\n- obsidian-second-brain:research\n- obsidian-second-brain:vault-deep-synthesis\n- obsidian-second-brain:x-pulse\n- obsidian-second-brain:x-read\n- obsidian-second-brain:youtube\n- skill-creator:skill-creator: Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, edit, or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review: Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technical rigor and verification, not performative agreement or blind implementation\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes\n- superpowers:test-driven-development: Use when implementing any feature or bugfix, before writing implementation code\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always\n- superpowers:writing-plans: Use when you have a spec or requirements for a multi-step task, before touching code\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-pipeline\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness: 하네스를 구성합니다. 전문 에이전트를 정의하며, 해당 에이전트가 사용할 스킬을 생성하는 메타 스킬. (1) '하네스 구성해줘', '하네스 구축해줘' 요청 시, (2) '하네스 설계', '하네스 엔지니어링' 요청 시, (3) 새로운 도메인/프로젝트에 대한 하네스 기반 자동화 체계를 구축할 때, (4) 하네스 구성을 재구성하거나 확장할 때, (5) '하네스 점검', '하네스 감사', '하네스 현황', '에이전트/스킬 동기화' 등 기존 하네스 운영/유지보수 요청 시 사용.\n- obsidian-second-brain:obsidian-second-brain\n- ralph-skills:prd\n- ralph-skills:ralph: Convert PRDs to prd.json format for the Ralph autonomous agent system. Use when you have an existing PRD and need to convert it to Ralph's JSON format. Triggers on: convert this prd, turn this into ralph format, create prd.json from this, ralph json.\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx: Use this skill whenever the user wants to create, read, edit, or manipulate Word documents (.docx files) or Word templates (.dotx files). Triggers include: any mention of 'Word doc', 'word document', '.docx', '.dotx', or requests to produce professional documents with formatting like tables of contents, headings, page numbers, or letterheads. Also use when extracting or reorganizing content from .docx or .dotx files, inserting or replacing images in documents, performing find-and-replace in Word files, working with tracked changes or comments, or converting content into a polished Word document. If the user asks for a 'report', 'memo', 'letter', 'template', or similar deliverable as a Word or .docx file, use this skill. Do NOT use for PDFs, spreadsheets, Google Docs, or general coding tasks unrelated to document generation.\n- anthropic-skills:morning\n- anthropic-skills:pdf\n- anthropic-skills:pptx\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork: Guided Cowork setup — install role-matched plugins, connect your tools, try a skill.\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact page can be granted — behavior static HTML cannot provide on its own, such as the page reading live or connected data, keeping state shared across viewers, or updating and republishing itself. Serves this user's live capability roster and the typed call definitions. Load it whenever the user asks for an artifact needing any such runtime behavior.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":542,"isInitial":true,"names":["find-skills","harness-orchestrator","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","deep-research","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","obsidian-second-brain:create-command","obsidian-second-brain:idea-discovery","obsidian-second-brain:notebooklm","obsidian-second-brain:obsidian-architect","obsidian-second-brain:obsidian-board-hygiene","obsidian-second-brain:obsidian-board","obsidian-second-brain:obsidian-brainstorm","obsidian-second-brain:obsidian-calendar","obsidian-second-brain:obsidian-capture","obsidian-second-brain:obsidian-catchup","obsidian-second-brain:obsidian-challenge","obsidian-second-brain:obsidian-connect","obsidian-second-brain:obsidian-daily","obsidian-second-brain:obsidian-decide","obsidian-second-brain:obsidian-distill","obsidian-second-brain:obsidian-emerge","obsidian-second-brain:obsidian-export","obsidian-second-brain:obsidian-find","obsidian-second-brain:obsidian-graduate","obsidian-second-brain:obsidian-health","obsidian-second-brain:obsidian-ingest","obsidian-second-brain:obsidian-init","obsidian-second-brain:obsidian-learn","obsidian-second-brain:obsidian-log","obsidian-second-brain:obsidian-panel","obsidian-second-brain:obsidian-person","obsidian-second-brain:obsidian-project","obsidian-second-brain:obsidian-projects","obsidian-second-brain:obsidian-recap","obsidian-second-brain:obsidian-reconcile","obsidian-second-brain:obsidian-recurring","obsidian-second-brain:obsidian-retrieval-eval","obsidian-second-brain:obsidian-review","obsidian-second-brain:obsidian-save","obsidian-second-brain:obsidian-synthesize","obsidian-second-brain:obsidian-task","obsidian-second-brain:obsidian-visualize","obsidian-second-brain:obsidian-world","obsidian-second-brain:podcast","obsidian-second-brain:research-deep","obsidian-second-brain:research","obsidian-second-brain:vault-deep-synthesis","obsidian-second-brain:x-pulse","obsidian-second-brain:x-read","obsidian-second-brain:youtube","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-pipeline","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","obsidian-second-brain:obsidian-second-brain","ralph-skills:prd","ralph-skills:ralph","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"3bb9d015-406e-4201-a832-77ac43e458ee","timestamp":"2026-07-23T00:35:38.325Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/PokeClip-architecture/.claude/worktrees/backbone-router-pipeline-integration-4da024","sessionId":"feaf19fe-7914-46ab-afc1-f463a3047884","version":"2.1.217","gitBranch":"claude/backbone-router-pipeline-integration-4da024"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-priceless-spence-f96ade/06afd324-52e8-4869-b7ab-02c01d1a26dd/subagents/agent-a360f4d379477c8ed.jsonl:2:{"parentUuid":"4181c970-fb53-4e98-a89e-08ecb9a1f94d","isSidechain":true,"agentId":"a360f4d379477c8ed","attachment":{"type":"deferred_tools_delta","addedNames":["CronCreate","CronDelete","CronList","DesignSync","EnterWorktree","ExitWorktree","Monitor","NotebookEdit","PushNotification","RemoteTrigger","SendMessage","TaskCreate","TaskGet","TaskList","TaskStop","TaskUpdate","WebFetch","WebSearch","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__copy_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__create_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__download_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_metadata","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_permissions","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__list_recent_files","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__read_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__search_files","mcp__ccd_directory__request_directory","mcp__ccd_session_mgmt__archive_session","mcp__ccd_session_mgmt__get_session","mcp__ccd_session_mgmt__list_events","mcp__ccd_session_mgmt__list_sessions","mcp__ccd_session_mgmt__search_session_transcripts","mcp__ccd_session_mgmt__send_message","mcp__ccd_session_mgmt__set_session_title","mcp__claude-in-chrome__browser_batch","mcp__claude-in-chrome__computer","mcp__claude-in-chrome__file_upload","mcp__claude-in-chrome__find","mcp__claude-in-chrome__form_input","mcp__claude-in-chrome__get_page_text","mcp__claude-in-chrome__gif_creator","mcp__claude-in-chrome__javascript_tool","mcp__claude-in-chrome__list_connected_browsers","mcp__claude-in-chrome__navigate","mcp__claude-in-chrome__read_console_messages","mcp__claude-in-chrome__read_network_requests","mcp__claude-in-chrome__read_page","mcp__claude-in-chrome__resize_window","mcp__claude-in-chrome__select_browser","mcp__claude-in-chrome__shortcuts_execute","mcp__claude-in-chrome__shortcuts_list","mcp__claude-in-chrome__switch_browser","mcp__claude-in-chrome__tabs_close_mcp","mcp__claude-in-chrome__tabs_context_mcp","mcp__claude-in-chrome__tabs_create_mcp","mcp__claude-in-chrome__upload_image","mcp__mcp-registry__list_connectors","mcp__mcp-registry__search_mcp_registry","mcp__mcp-registry__suggest_connectors","mcp__plugin_claude-mem_mcp-search____IMPORTANT","mcp__plugin_claude-mem_mcp-search__build_corpus","mcp__plugin_claude-mem_mcp-search__get_observations","mcp__plugin_claude-mem_mcp-search__list_corpora","mcp__plugin_claude-mem_mcp-search__observation_add","mcp__plugin_claude-mem_mcp-search__observation_context","mcp__plugin_claude-mem_mcp-search__observation_generation_status","mcp__plugin_claude-mem_mcp-search__observation_record_event","mcp__plugin_claude-mem_mcp-search__observation_search","mcp__plugin_claude-mem_mcp-search__prime_corpus","mcp__plugin_claude-mem_mcp-search__query_corpus","mcp__plugin_claude-mem_mcp-search__rebuild_corpus","mcp__plugin_claude-mem_mcp-search__reprime_corpus","mcp__plugin_claude-mem_mcp-search__search","mcp__plugin_claude-mem_mcp-search__session_start_context","mcp__plugin_claude-mem_mcp-search__smart_outline","mcp__plugin_claude-mem_mcp-search__smart_search","mcp__plugin_claude-mem_mcp-search__smart_unfold","mcp__plugin_claude-mem_mcp-search__timeline","mcp__plugin_ecc_chrome-devtools__click","mcp__plugin_ecc_chrome-devtools__close_page","mcp__plugin_ecc_chrome-devtools__drag","mcp__plugin_ecc_chrome-devtools__emulate","mcp__plugin_ecc_chrome-devtools__evaluate_script","mcp__plugin_ecc_chrome-devtools__fill","mcp__plugin_ecc_chrome-devtools__fill_form","mcp__plugin_ecc_chrome-devtools__get_console_message","mcp__plugin_ecc_chrome-devtools__get_network_request","mcp__plugin_ecc_chrome-devtools__handle_dialog","mcp__plugin_ecc_chrome-devtools__hover","mcp__plugin_ecc_chrome-devtools__lighthouse_audit","mcp__plugin_ecc_chrome-devtools__list_console_messages","mcp__plugin_ecc_chrome-devtools__list_network_requests","mcp__plugin_ecc_chrome-devtools__list_pages","mcp__plugin_ecc_chrome-devtools__navigate_page","mcp__plugin_ecc_chrome-devtools__new_page","mcp__plugin_ecc_chrome-devtools__performance_analyze_insight","mcp__plugin_ecc_chrome-devtools__performance_start_trace","mcp__plugin_ecc_chrome-devtools__performance_stop_trace","mcp__plugin_ecc_chrome-devtools__press_key","mcp__plugin_ecc_chrome-devtools__resize_page","mcp__plugin_ecc_chrome-devtools__select_page","mcp__plugin_ecc_chrome-devtools__take_heapsnapshot","mcp__plugin_ecc_chrome-devtools__take_screenshot","mcp__plugin_ecc_chrome-devtools__take_snapshot","mcp__plugin_ecc_chrome-devtools__type_text","mcp__plugin_ecc_chrome-devtools__upload_file","mcp__plugin_ecc_chrome-devtools__wait_for","mcp__scheduled-tasks__create_scheduled_task","mcp__scheduled-tasks__delete_scheduled_task","mcp__scheduled-tasks__list_scheduled_tasks","mcp__scheduled-tasks__update_scheduled_task"],"addedLines":["CronCreate","CronDelete","CronList","DesignSync","EnterWorktree","ExitWorktree","Monitor","NotebookEdit","PushNotification","RemoteTrigger","SendMessage","TaskCreate","TaskGet","TaskList","TaskStop","TaskUpdate","WebFetch","WebSearch","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__copy_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__create_file","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__download_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_metadata","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__get_file_permissions","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__list_recent_files","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__read_file_content","mcp__611101f9-6c99-4f7c-add9-20be6e8a4359__search_files","mcp__ccd_directory__request_directory","mcp__ccd_session_mgmt__archive_session","mcp__ccd_session_mgmt__get_session","mcp__ccd_session_mgmt__list_events","mcp__ccd_session_mgmt__list_sessions","mcp__ccd_session_mgmt__search_session_transcripts","mcp__ccd_session_mgmt__send_message","mcp__ccd_session_mgmt__set_session_title","mcp__claude-in-chrome__browser_batch","mcp__claude-in-chrome__computer","mcp__claude-in-chrome__file_upload","mcp__claude-in-chrome__find","mcp__claude-in-chrome__form_input","mcp__claude-in-chrome__get_page_text","mcp__claude-in-chrome__gif_creator","mcp__claude-in-chrome__javascript_tool","mcp__claude-in-chrome__list_connected_browsers","mcp__claude-in-chrome__navigate","mcp__claude-in-chrome__read_console_messages","mcp__claude-in-chrome__read_network_requests","mcp__claude-in-chrome__read_page","mcp__claude-in-chrome__resize_window","mcp__claude-in-chrome__select_browser","mcp__claude-in-chrome__shortcuts_execute","mcp__claude-in-chrome__shortcuts_list","mcp__claude-in-chrome__switch_browser","mcp__claude-in-chrome__tabs_close_mcp","mcp__claude-in-chrome__tabs_context_mcp","mcp__claude-in-chrome__tabs_create_mcp","mcp__claude-in-chrome__upload_image","mcp__mcp-registry__list_connectors","mcp__mcp-registry__search_mcp_registry","mcp__mcp-registry__suggest_connectors","mcp__plugin_claude-mem_mcp-search____IMPORTANT","mcp__plugin_claude-mem_mcp-search__build_corpus","mcp__plugin_claude-mem_mcp-search__get_observations","mcp__plugin_claude-mem_mcp-search__list_corpora","mcp__plugin_claude-mem_mcp-search__observation_add","mcp__plugin_claude-mem_mcp-search__observation_context","mcp__plugin_claude-mem_mcp-search__observation_generation_status","mcp__plugin_claude-mem_mcp-search__observation_record_event","mcp__plugin_claude-mem_mcp-search__observation_search","mcp__plugin_claude-mem_mcp-search__prime_corpus","mcp__plugin_claude-mem_mcp-search__query_corpus","mcp__plugin_claude-mem_mcp-search__rebuild_corpus","mcp__plugin_claude-mem_mcp-search__reprime_corpus","mcp__plugin_claude-mem_mcp-search__search","mcp__plugin_claude-mem_mcp-search__session_start_context","mcp__plugin_claude-mem_mcp-search__smart_outline","mcp__plugin_claude-mem_mcp-search__smart_search","mcp__plugin_claude-mem_mcp-search__smart_unfold","mcp__plugin_claude-mem_mcp-search__timeline","mcp__plugin_ecc_chrome-devtools__click","mcp__plugin_ecc_chrome-devtools__close_page","mcp__plugin_ecc_chrome-devtools__drag","mcp__plugin_ecc_chrome-devtools__emulate","mcp__plugin_ecc_chrome-devtools__evaluate_script","mcp__plugin_ecc_chrome-devtools__fill","mcp__plugin_ecc_chrome-devtools__fill_form","mcp__plugin_ecc_chrome-devtools__get_console_message","mcp__plugin_ecc_chrome-devtools__get_network_request","mcp__plugin_ecc_chrome-devtools__handle_dialog","mcp__plugin_ecc_chrome-devtools__hover","mcp__plugin_ecc_chrome-devtools__lighthouse_audit","mcp__plugin_ecc_chrome-devtools__list_console_messages","mcp__plugin_ecc_chrome-devtools__list_network_requests","mcp__plugin_ecc_chrome-devtools__list_pages","mcp__plugin_ecc_chrome-devtools__navigate_page","mcp__plugin_ecc_chrome-devtools__new_page","mcp__plugin_ecc_chrome-devtools__performance_analyze_insight","mcp__plugin_ecc_chrome-devtools__performance_start_trace","mcp__plugin_ecc_chrome-devtools__performance_stop_trace","mcp__plugin_ecc_chrome-devtools__press_key","mcp__plugin_ecc_chrome-devtools__resize_page","mcp__plugin_ecc_chrome-devtools__select_page","mcp__plugin_ecc_chrome-devtools__take_heapsnapshot","mcp__plugin_ecc_chrome-devtools__take_screenshot","mcp__plugin_ecc_chrome-devtools__take_snapshot","mcp__plugin_ecc_chrome-devtools__type_text","mcp__plugin_ecc_chrome-devtools__upload_file","mcp__plugin_ecc_chrome-devtools__wait_for","mcp__scheduled-tasks__create_scheduled_task","mcp__scheduled-tasks__delete_scheduled_task","mcp__scheduled-tasks__list_scheduled_tasks","mcp__scheduled-tasks__update_scheduled_task"],"removedNames":[],"readdedNames":[]},"type":"attachment","uuid":"77f18d87-d8c6-429a-b2d5-4dfce97d8451","timestamp":"2026-07-16T05:20:04.958Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/chat/.claude/worktrees/priceless-spence-f96ade","sessionId":"06afd324-52e8-4869-b7ab-02c01d1a26dd","version":"2.1.209","gitBranch":"claude/harness-template-generalize-e719c2"}
/Users/kty/.claude/projects/-Users-kty-Downloads-chat--claude-worktrees-priceless-spence-f96ade/06afd324-52e8-4869-b7ab-02c01d1a26dd/subagents/agent-a360f4d379477c8ed.jsonl:3:{"parentUuid":"77f18d87-d8c6-429a-b2d5-4dfce97d8451","isSidechain":true,"agentId":"a360f4d379477c8ed","attachment":{"type":"skill_listing","content":"- architecture-explanation\n- change-explanation\n- chat-harness\n- chat-system-development\n- chat-system-plan-review\n- chat-system-planning\n- chat-system-pr\n- chat-system-pr-review\n- chat-system-review\n- completion-audit\n- requirement-clarification\n- aside\n- build-fix\n- checkpoint\n- code-review\n- cost-report\n- cpp-build\n- cpp-review\n- cpp-test\n- ecc-guide\n- epic-claim\n- epic-decompose\n- epic-publish\n- epic-review\n- epic-sync\n- epic-unblock\n- epic-validate\n- evolve\n- fastapi-review\n- feature-dev\n- flutter-build\n- flutter-review\n- flutter-test\n- gan-build\n- gan-design\n- go-build\n- go-review\n- go-test\n- gradle-build\n- harness-audit\n- hookify\n- hookify-configure\n- hookify-help\n- hookify-list\n- instinct-export\n- instinct-import\n- instinct-status\n- jira\n- kotlin-build\n- kotlin-review\n- kotlin-test\n- learn\n- learn-eval\n- loop-start\n- loop-status\n- marketing-campaign\n- model-route\n- multi-backend\n- multi-execute\n- multi-frontend\n- multi-plan\n- multi-workflow\n- orch-add-feature\n- orch-build-mvp\n- orch-change-feature\n- orch-fix-defect\n- orch-refine-code\n- plan\n- plan-prd\n- pm2\n- pr\n- project-init\n- projects\n- promote\n- prp-commit\n- prp-implement\n- prp-plan\n- prp-pr\n- prp-prd\n- prune\n- python-review\n- quality-gate\n- react-build\n- react-review\n- react-test\n- refactor-clean\n- resume-session\n- review-pr\n- rust-build\n- rust-review\n- rust-test\n- santa-loop\n- save-session\n- security-scan\n- sessions\n- skill-create\n- skill-health\n- test-coverage\n- update-codemaps\n- update-docs\n- vue-review\n- ecc:aside\n- ecc:build-fix\n- ecc:checkpoint\n- ecc:code-review\n- ecc:cost-report\n- ecc:cpp-build\n- ecc:cpp-review\n- ecc:cpp-test\n- ecc:ecc-guide\n- ecc:epic-claim\n- ecc:epic-decompose\n- ecc:epic-publish\n- ecc:epic-review\n- ecc:epic-sync\n- ecc:epic-unblock\n- ecc:epic-validate\n- ecc:evolve\n- ecc:fastapi-review\n- ecc:feature-dev\n- ecc:flutter-build\n- ecc:flutter-review\n- ecc:flutter-test\n- ecc:gan-build\n- ecc:gan-design\n- ecc:go-build\n- ecc:go-review\n- ecc:go-test\n- ecc:gradle-build\n- ecc:harness-audit\n- ecc:hookify-configure\n- ecc:hookify-help\n- ecc:hookify-list\n- ecc:hookify\n- ecc:instinct-export\n- ecc:instinct-import\n- ecc:instinct-status\n- ecc:jira\n- ecc:kotlin-build\n- ecc:kotlin-review\n- ecc:kotlin-test\n- ecc:learn-eval\n- ecc:learn\n- ecc:loop-start\n- ecc:loop-status\n- ecc:marketing-campaign\n- ecc:model-route\n- ecc:multi-backend\n- ecc:multi-execute\n- ecc:multi-frontend\n- ecc:multi-plan\n- ecc:multi-workflow\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-refine-code\n- ecc:plan-prd\n- ecc:plan\n- ecc:pm2\n- ecc:pr\n- ecc:project-init\n- ecc:projects\n- ecc:promote\n- ecc:prp-commit\n- ecc:prp-implement\n- ecc:prp-plan\n- ecc:prp-pr\n- ecc:prp-prd\n- ecc:prune\n- ecc:python-review\n- ecc:quality-gate\n- ecc:react-build\n- ecc:react-review\n- ecc:react-test\n- ecc:refactor-clean\n- ecc:resume-session\n- ecc:review-pr\n- ecc:rust-build\n- ecc:rust-review\n- ecc:rust-test\n- ecc:santa-loop\n- ecc:save-session\n- ecc:security-scan\n- ecc:sessions\n- ecc:skill-create\n- ecc:skill-health\n- ecc:test-coverage\n- ecc:update-codemaps\n- ecc:update-docs\n- ecc:vue-review\n- skill-creator:skill-creator\n- superpowers:brainstorming\n- superpowers:dispatching-parallel-agents\n- superpowers:executing-plans\n- superpowers:finishing-a-development-branch\n- superpowers:receiving-code-review\n- superpowers:requesting-code-review\n- superpowers:subagent-driven-development\n- superpowers:systematic-debugging\n- superpowers:test-driven-development\n- superpowers:using-git-worktrees\n- superpowers:using-superpowers\n- superpowers:verification-before-completion\n- superpowers:writing-plans\n- superpowers:writing-skills\n- ecc:accessibility\n- ecc:agent-architecture-audit\n- ecc:agent-eval\n- ecc:agent-harness-construction\n- ecc:agent-introspection-debugging\n- ecc:agent-payment-x402\n- ecc:agent-self-evaluation\n- ecc:agent-sort\n- ecc:agentic-engineering\n- ecc:agentic-os\n- ecc:ai-first-engineering\n- ecc:ai-regression-testing\n- ecc:android-clean-architecture\n- ecc:angular-developer\n- ecc:api-connector-builder\n- ecc:api-design\n- ecc:architecture-decision-records\n- ecc:article-writing\n- ecc:automation-audit-ops\n- ecc:autonomous-agent-harness\n- ecc:autonomous-loops\n- ecc:backend-patterns\n- ecc:benchmark\n- ecc:benchmark-methodology\n- ecc:benchmark-optimization-loop\n- ecc:blender-motion-state-inspection\n- ecc:blueprint\n- ecc:brand-discovery\n- ecc:brand-voice\n- ecc:browser-qa\n- ecc:bun-runtime\n- ecc:canary-watch\n- ecc:carrier-relationship-management\n- ecc:cisco-ios-patterns\n- ecc:ck\n- ecc:claude-devfleet\n- ecc:click-path-audit\n- ecc:clickhouse-io\n- ecc:code-tour\n- ecc:codebase-onboarding\n- ecc:codehealth-mcp\n- ecc:coding-standards\n- ecc:competitive-platform-analysis\n- ecc:competitive-report-structure\n- ecc:compose-multiplatform-patterns\n- ecc:config-gc\n- ecc:configure-ecc\n- ecc:connections-optimizer\n- ecc:content-engine\n- ecc:content-hash-cache-pattern\n- ecc:context-budget\n- ecc:continuous-agent-loop\n- ecc:continuous-learning\n- ecc:continuous-learning-v2\n- ecc:cost-aware-llm-pipeline\n- ecc:cost-tracking\n- ecc:council\n- ecc:cpp-coding-standards\n- ecc:cpp-testing\n- ecc:crosspost\n- ecc:csharp-testing\n- ecc:customer-billing-ops\n- ecc:customs-trade-compliance\n- ecc:dart-flutter-patterns\n- ecc:dashboard-builder\n- ecc:data-scraper-agent\n- ecc:data-throughput-accelerator\n- ecc:database-migrations\n- ecc:deep-research\n- ecc:defi-amm-security\n- ecc:deployment-patterns\n- ecc:design-system\n- ecc:django-celery\n- ecc:django-patterns\n- ecc:django-security\n- ecc:django-tdd\n- ecc:django-verification\n- ecc:dmux-workflows\n- ecc:docker-patterns\n- ecc:documentation-lookup\n- ecc:dotnet-patterns\n- ecc:dynamic-workflow-mode\n- ecc:e2e-testing\n- ecc:ecc-guide\n- ecc:ecc-tools-cost-audit\n- ecc:email-ops\n- ecc:energy-procurement\n- ecc:enterprise-agent-ops\n- ecc:error-handling\n- ecc:eval-harness\n- ecc:evm-token-decimals\n- ecc:exa-search\n- ecc:fal-ai-media\n- ecc:fastapi-patterns\n- ecc:finance-billing-ops\n- ecc:flox-environments\n- ecc:flutter-dart-code-review\n- ecc:foundation-models-on-device\n- ecc:frontend-a11y\n- ecc:frontend-design-direction\n- ecc:frontend-patterns\n- ecc:frontend-slides\n- ecc:fsharp-testing\n- ecc:gan-style-harness\n- ecc:gateguard\n- ecc:generating-python-installer\n- ecc:git-workflow\n- ecc:github-ops\n- ecc:golang-patterns\n- ecc:golang-testing\n- ecc:google-workspace-ops\n- ecc:healthcare-cdss-patterns\n- ecc:healthcare-emr-patterns\n- ecc:healthcare-eval-harness\n- ecc:healthcare-phi-compliance\n- ecc:hermes-imports\n- ecc:hexagonal-architecture\n- ecc:hipaa-compliance\n- ecc:homelab-network-readiness\n- ecc:homelab-network-setup\n- ecc:homelab-pihole-dns\n- ecc:homelab-vlan-segmentation\n- ecc:homelab-wireguard-vpn\n- ecc:hookify-rules\n- ecc:inherit-legacy-style\n- ecc:intent-driven-development\n- ecc:inventory-demand-planning\n- ecc:investor-materials\n- ecc:investor-outreach\n- ecc:ios-icon-gen\n- ecc:iterative-retrieval\n- ecc:ito-basket-compare\n- ecc:ito-data-atlas-agent\n- ecc:ito-market-intelligence\n- ecc:ito-trade-planner\n- ecc:java-coding-standards\n- ecc:jira-integration\n- ecc:jpa-patterns\n- ecc:knowledge-ops\n- ecc:kotlin-coroutines-flows\n- ecc:kotlin-exposed-patterns\n- ecc:kotlin-ktor-patterns\n- ecc:kotlin-patterns\n- ecc:kotlin-testing\n- ecc:kubernetes-patterns\n- ecc:laravel-patterns\n- ecc:laravel-plugin-discovery\n- ecc:laravel-security\n- ecc:laravel-tdd\n- ecc:laravel-verification\n- ecc:latency-critical-systems\n- ecc:lead-intelligence\n- ecc:liquid-glass-design\n- ecc:llm-trading-agent-security\n- ecc:logistics-exception-management\n- ecc:make-interfaces-feel-better\n- ecc:manim-video\n- ecc:market-research\n- ecc:marketing-campaign\n- ecc:mcp-server-patterns\n- ecc:messages-ops\n- ecc:ml-adoption-playbook\n- ecc:mle-workflow\n- ecc:motion-advanced\n- ecc:motion-foundations\n- ecc:motion-patterns\n- ecc:motion-ui\n- ecc:mysql-patterns\n- ecc:nanoclaw-repl\n- ecc:nestjs-patterns\n- ecc:netmiko-ssh-automation\n- ecc:network-bgp-diagnostics\n- ecc:network-config-validation\n- ecc:network-interface-health\n- ecc:nextjs-turbopack\n- ecc:nodejs-keccak256\n- ecc:nutrient-document-processing\n- ecc:nuxt4-patterns\n- ecc:openclaw-persona-forge\n- ecc:opensource-pipeline\n- ecc:orch-add-feature\n- ecc:orch-build-mvp\n- ecc:orch-change-feature\n- ecc:orch-fix-defect\n- ecc:orch-pipeline\n- ecc:orch-refine-code\n- ecc:parallel-execution-optimizer\n- ecc:perl-patterns\n- ecc:perl-security\n- ecc:perl-testing\n- ecc:plan-orchestrate\n- ecc:plankton-code-quality\n- ecc:postgres-patterns\n- ecc:prediction-market-oracle-research\n- ecc:prediction-market-risk-review\n- ecc:prisma-patterns\n- ecc:product-capability\n- ecc:product-lens\n- ecc:production-audit\n- ecc:production-scheduling\n- ecc:project-flow-ops\n- ecc:prompt-optimizer\n- ecc:python-patterns\n- ecc:python-testing\n- ecc:pytorch-patterns\n- ecc:quality-nonconformance\n- ecc:quarkus-patterns\n- ecc:quarkus-security\n- ecc:quarkus-tdd\n- ecc:quarkus-verification\n- ecc:ralphinho-rfc-pipeline\n- ecc:react-patterns\n- ecc:react-performance\n- ecc:react-testing\n- ecc:recsys-pipeline-architect\n- ecc:recursive-decision-ledger\n- ecc:redis-patterns\n- ecc:regex-vs-llm-structured-text\n- ecc:remotion-video-creation\n- ecc:repo-scan\n- ecc:research-ops\n- ecc:returns-reverse-logistics\n- ecc:rules-distill\n- ecc:rust-patterns\n- ecc:rust-testing\n- ecc:safety-guard\n- ecc:santa-method\n- ecc:scientific-db-pubmed-database\n- ecc:scientific-db-uspto-database\n- ecc:scientific-pkg-gget\n- ecc:scientific-thinking-literature-review\n- ecc:scientific-thinking-scholar-evaluation\n- ecc:search-first\n- ecc:security-bounty-hunter\n- ecc:security-review\n- ecc:security-scan\n- ecc:seo\n- ecc:skill-comply\n- ecc:skill-scout\n- ecc:skill-stocktake\n- ecc:social-graph-ranker\n- ecc:social-publisher\n- ecc:springboot-patterns\n- ecc:springboot-security\n- ecc:springboot-tdd\n- ecc:springboot-verification\n- ecc:strategic-compact\n- ecc:swift-actor-persistence\n- ecc:swift-concurrency-6-2\n- ecc:swift-protocol-di-testing\n- ecc:swiftui-patterns\n- ecc:taste\n- ecc:tdd-workflow\n- ecc:team-agent-orchestration\n- ecc:team-builder\n- ecc:terminal-ops\n- ecc:tinystruct-patterns\n- ecc:token-budget-advisor\n- ecc:ui-demo\n- ecc:ui-to-vue\n- ecc:uncloud\n- ecc:unified-notifications-ops\n- ecc:verification-loop\n- ecc:video-editing\n- ecc:videodb\n- ecc:visa-doc-translate\n- ecc:vite-patterns\n- ecc:vue-patterns\n- ecc:windows-desktop-e2e\n- ecc:workspace-surface-audit\n- ecc:x-api\n- harness:harness\n- claude-mem:babysit\n- claude-mem:cloud-sync\n- claude-mem:design-is\n- claude-mem:do\n- claude-mem:how-it-works\n- claude-mem:knowledge-agent\n- claude-mem:learn-codebase\n- claude-mem:make-plan\n- claude-mem:mem-search\n- claude-mem:oh-my-issues\n- claude-mem:pathfinder\n- claude-mem:smart-explore\n- claude-mem:standup\n- claude-mem:timeline-report\n- claude-mem:version-bump\n- claude-mem:weekly-digests\n- claude-mem:what-the\n- claude-mem:wowerpoint\n- cowork-plugin-management:cowork-plugin-customizer\n- cowork-plugin-management:create-cowork-plugin\n- design:accessibility-review\n- design:design-critique\n- design:design-handoff\n- design:design-system\n- design:research-synthesis\n- design:user-research\n- design:ux-copy\n- anthropic-skills:consolidate-memory\n- anthropic-skills:docx\n- anthropic-skills:morning\n- anthropic-skills:pdf\n- anthropic-skills:pptx\n- anthropic-skills:schedule\n- anthropic-skills:setup-cowork\n- anthropic-skills:skill-creator\n- anthropic-skills:xlsx\n- dataviz: Use this skill whenever you are about to create ANY chart, graph, plot, dashboard, or data visualization, in ANY output medium — an HTML or React artifact, inline SVG, plotting code in any library (matplotlib, plotly, d3, Recharts, …), an image/PNG you will render and upload, or a chart shared into Slack. Read it BEFORE writing the first line of chart code, choosing chart colors, building a stat tile / meter / KPI row, or laying out a dashboard. Produces visualizations that read as one system — elegant, accessible, consistent in light and dark — using a brand-neutral placeholder palette you swap for your own. Teaches a design-system-agnostic method: a form heuristic, a color formula with a runnable validator, mark specs, and interaction rules. A validated default palette is documented in `references/palette.md` — swap that file's values for your brand's. Triggers on: \"chart\", \"graph\", \"plot\", \"data viz\", \"visualization\", \"dashboard\", \"analytics\", \"visualize data\", \"categorical colors\", \"sequential / diverging palette\", \"stat tile\", \"sparkline\", \"heatmap\", \"legend\", \"axis\", \"tooltip\", \"chart colors\", \"color by series\".\n- artifact-design: Design guidance and fundamentals for Artifacts.\n- artifact-capabilities: Runtime capabilities a published Artifact can declare — calling the user's claude.ai connectors (MCP) from the page, and future abilities. Load this BEFORE passing `capabilities` to the Artifact tool or writing any `window.claude.mcp` code.\n- update-config: Use this skill to configure the Claude Code harness via settings.json. Automated behaviors (\"from now on when X\", \"each time X\", \"whenever X\", \"before/after X\") require hooks configured in settings.json - the harness executes these, not Claude, so memory/preferences cannot fulfill them. Also use for: permissions (\"allow X\", \"add permission\", \"move permission to\"), env vars (\"set X=Y\"), hook troubleshooting, or any changes to settings.json/settings.local.json files. Examples: \"allow npm commands\", \"add bq permission to global settings\", \"move permission to user settings\", \"set DEBUG=true\", \"when claude stops show X\". For simple settings like theme/model, suggest the /config command.\n- keybindings-help: Use when the user wants to customize keyboard shortcuts, rebind keys, add chord bindings, or modify ~/.claude/keybindings.json. Examples: \"rebind ctrl+s\", \"add a chord shortcut\", \"change the submit key\", \"customize keybindings\".\n- verify: Verify that a code change actually does what it's supposed to by exercising it end-to-end and observing behavior — drive the affected flow, not just tests or typecheck. Run before committing nontrivial changes; bootstraps this repo's project verify skill if none exists yet. Don't invoke it on a diff that only touches tests, docs, or other code with no runtime surface to drive (a change to product source always has one) — there's nothing to observe.\n- simplify: Review the changed code for reuse, simplification, efficiency, and altitude cleanups, then apply the fixes. Quality only — it does not hunt for bugs; use /code-review for that.\n- fewer-permission-prompts: Scan your transcripts for common read-only Bash and MCP tool calls, then add a prioritized allowlist to project .claude/settings.json to reduce permission prompts.\n- loop: Run a prompt or slash command on a recurring interval (e.g. /loop 5m /foo). Omit the interval to let the model self-pace. - When the user wants to set up a recurring task, poll for status, or run something repeatedly on an interval (e.g. \"check the deploy every 5 minutes\", \"keep running /babysit-prs\"). Do NOT invoke for one-off tasks.\n- schedule: Create, update, list, or run scheduled cloud agents (routines) that execute on a cron schedule. - When the user wants to schedule a recurring cloud agent, set up automated tasks, create a cron job for Claude Code, or manage their scheduled agents/routines. Also use when the user wants a one-time scheduled run (\"run this once at 3pm\", \"remind me to check X tomorrow\").\n- claude-api: Reference for the Claude API / Anthropic SDK — model ids, pricing, params, streaming, tool use, MCP, agents, caching, token counting, model migration.\nTRIGGER — read BEFORE opening the target file; don't skip because it \"looks like a one-liner\" — whenever: the prompt names Claude/Anthropic in any form (Claude, Anthropic, Fable, Opus, Sonnet, Haiku, `anthropic`, `@anthropic-ai`, `claude-*`, `us.anthropic.*`, `[1m]`); the user asks about an LLM (pricing/model choice/limits/caching) — never answer from memory; OR the task is LLM-shaped with provider unstated (agent/MCP/tool-definition/multi-agent/RAG/LLM-judge/computer-use; generate/summarize/extract/classify/rewrite/converse over NL; debugging refusals/cutoffs/streaming/tool-calls/tokens).\nSKIP only when another provider is being worked on (overrides all triggers): OpenAI/GPT/Gemini/Llama/Mistral/Cohere/Ollama named in the query; OR `grep -rE 'openai|langchain_openai|google.generativeai|genai|mistralai|cohere|ollama'` over the project hits (run this grep FIRST if no provider named — don't Read the file).\n- run: Launch and drive this project's app to see a change working. Use when asked to run, start, or screenshot the app, or to confirm a change works in the real app (not just tests). First looks for a project skill that already covers launching the app; otherwise falls back to built-in patterns per project type (CLI, server, TUI, Electron, browser-driven, library).\n- init\n- review\n- security-review","skillCount":529,"isInitial":true,"names":["architecture-explanation","change-explanation","chat-harness","chat-system-development","chat-system-plan-review","chat-system-planning","chat-system-pr","chat-system-pr-review","chat-system-review","completion-audit","requirement-clarification","aside","build-fix","checkpoint","code-review","cost-report","cpp-build","cpp-review","cpp-test","ecc-guide","epic-claim","epic-decompose","epic-publish","epic-review","epic-sync","epic-unblock","epic-validate","evolve","fastapi-review","feature-dev","flutter-build","flutter-review","flutter-test","gan-build","gan-design","go-build","go-review","go-test","gradle-build","harness-audit","hookify","hookify-configure","hookify-help","hookify-list","instinct-export","instinct-import","instinct-status","jira","kotlin-build","kotlin-review","kotlin-test","learn","learn-eval","loop-start","loop-status","marketing-campaign","model-route","multi-backend","multi-execute","multi-frontend","multi-plan","multi-workflow","orch-add-feature","orch-build-mvp","orch-change-feature","orch-fix-defect","orch-refine-code","plan","plan-prd","pm2","pr","project-init","projects","promote","prp-commit","prp-implement","prp-plan","prp-pr","prp-prd","prune","python-review","quality-gate","react-build","react-review","react-test","refactor-clean","resume-session","review-pr","rust-build","rust-review","rust-test","santa-loop","save-session","security-scan","sessions","skill-create","skill-health","test-coverage","update-codemaps","update-docs","vue-review","ecc:aside","ecc:build-fix","ecc:checkpoint","ecc:code-review","ecc:cost-report","ecc:cpp-build","ecc:cpp-review","ecc:cpp-test","ecc:ecc-guide","ecc:epic-claim","ecc:epic-decompose","ecc:epic-publish","ecc:epic-review","ecc:epic-sync","ecc:epic-unblock","ecc:epic-validate","ecc:evolve","ecc:fastapi-review","ecc:feature-dev","ecc:flutter-build","ecc:flutter-review","ecc:flutter-test","ecc:gan-build","ecc:gan-design","ecc:go-build","ecc:go-review","ecc:go-test","ecc:gradle-build","ecc:harness-audit","ecc:hookify-configure","ecc:hookify-help","ecc:hookify-list","ecc:hookify","ecc:instinct-export","ecc:instinct-import","ecc:instinct-status","ecc:jira","ecc:kotlin-build","ecc:kotlin-review","ecc:kotlin-test","ecc:learn-eval","ecc:learn","ecc:loop-start","ecc:loop-status","ecc:marketing-campaign","ecc:model-route","ecc:multi-backend","ecc:multi-execute","ecc:multi-frontend","ecc:multi-plan","ecc:multi-workflow","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-refine-code","ecc:plan-prd","ecc:plan","ecc:pm2","ecc:pr","ecc:project-init","ecc:projects","ecc:promote","ecc:prp-commit","ecc:prp-implement","ecc:prp-plan","ecc:prp-pr","ecc:prp-prd","ecc:prune","ecc:python-review","ecc:quality-gate","ecc:react-build","ecc:react-review","ecc:react-test","ecc:refactor-clean","ecc:resume-session","ecc:review-pr","ecc:rust-build","ecc:rust-review","ecc:rust-test","ecc:santa-loop","ecc:save-session","ecc:security-scan","ecc:sessions","ecc:skill-create","ecc:skill-health","ecc:test-coverage","ecc:update-codemaps","ecc:update-docs","ecc:vue-review","skill-creator:skill-creator","superpowers:brainstorming","superpowers:dispatching-parallel-agents","superpowers:executing-plans","superpowers:finishing-a-development-branch","superpowers:receiving-code-review","superpowers:requesting-code-review","superpowers:subagent-driven-development","superpowers:systematic-debugging","superpowers:test-driven-development","superpowers:using-git-worktrees","superpowers:using-superpowers","superpowers:verification-before-completion","superpowers:writing-plans","superpowers:writing-skills","ecc:accessibility","ecc:agent-architecture-audit","ecc:agent-eval","ecc:agent-harness-construction","ecc:agent-introspection-debugging","ecc:agent-payment-x402","ecc:agent-self-evaluation","ecc:agent-sort","ecc:agentic-engineering","ecc:agentic-os","ecc:ai-first-engineering","ecc:ai-regression-testing","ecc:android-clean-architecture","ecc:angular-developer","ecc:api-connector-builder","ecc:api-design","ecc:architecture-decision-records","ecc:article-writing","ecc:automation-audit-ops","ecc:autonomous-agent-harness","ecc:autonomous-loops","ecc:backend-patterns","ecc:benchmark","ecc:benchmark-methodology","ecc:benchmark-optimization-loop","ecc:blender-motion-state-inspection","ecc:blueprint","ecc:brand-discovery","ecc:brand-voice","ecc:browser-qa","ecc:bun-runtime","ecc:canary-watch","ecc:carrier-relationship-management","ecc:cisco-ios-patterns","ecc:ck","ecc:claude-devfleet","ecc:click-path-audit","ecc:clickhouse-io","ecc:code-tour","ecc:codebase-onboarding","ecc:codehealth-mcp","ecc:coding-standards","ecc:competitive-platform-analysis","ecc:competitive-report-structure","ecc:compose-multiplatform-patterns","ecc:config-gc","ecc:configure-ecc","ecc:connections-optimizer","ecc:content-engine","ecc:content-hash-cache-pattern","ecc:context-budget","ecc:continuous-agent-loop","ecc:continuous-learning","ecc:continuous-learning-v2","ecc:cost-aware-llm-pipeline","ecc:cost-tracking","ecc:council","ecc:cpp-coding-standards","ecc:cpp-testing","ecc:crosspost","ecc:csharp-testing","ecc:customer-billing-ops","ecc:customs-trade-compliance","ecc:dart-flutter-patterns","ecc:dashboard-builder","ecc:data-scraper-agent","ecc:data-throughput-accelerator","ecc:database-migrations","ecc:deep-research","ecc:defi-amm-security","ecc:deployment-patterns","ecc:design-system","ecc:django-celery","ecc:django-patterns","ecc:django-security","ecc:django-tdd","ecc:django-verification","ecc:dmux-workflows","ecc:docker-patterns","ecc:documentation-lookup","ecc:dotnet-patterns","ecc:dynamic-workflow-mode","ecc:e2e-testing","ecc:ecc-guide","ecc:ecc-tools-cost-audit","ecc:email-ops","ecc:energy-procurement","ecc:enterprise-agent-ops","ecc:error-handling","ecc:eval-harness","ecc:evm-token-decimals","ecc:exa-search","ecc:fal-ai-media","ecc:fastapi-patterns","ecc:finance-billing-ops","ecc:flox-environments","ecc:flutter-dart-code-review","ecc:foundation-models-on-device","ecc:frontend-a11y","ecc:frontend-design-direction","ecc:frontend-patterns","ecc:frontend-slides","ecc:fsharp-testing","ecc:gan-style-harness","ecc:gateguard","ecc:generating-python-installer","ecc:git-workflow","ecc:github-ops","ecc:golang-patterns","ecc:golang-testing","ecc:google-workspace-ops","ecc:healthcare-cdss-patterns","ecc:healthcare-emr-patterns","ecc:healthcare-eval-harness","ecc:healthcare-phi-compliance","ecc:hermes-imports","ecc:hexagonal-architecture","ecc:hipaa-compliance","ecc:homelab-network-readiness","ecc:homelab-network-setup","ecc:homelab-pihole-dns","ecc:homelab-vlan-segmentation","ecc:homelab-wireguard-vpn","ecc:hookify-rules","ecc:inherit-legacy-style","ecc:intent-driven-development","ecc:inventory-demand-planning","ecc:investor-materials","ecc:investor-outreach","ecc:ios-icon-gen","ecc:iterative-retrieval","ecc:ito-basket-compare","ecc:ito-data-atlas-agent","ecc:ito-market-intelligence","ecc:ito-trade-planner","ecc:java-coding-standards","ecc:jira-integration","ecc:jpa-patterns","ecc:knowledge-ops","ecc:kotlin-coroutines-flows","ecc:kotlin-exposed-patterns","ecc:kotlin-ktor-patterns","ecc:kotlin-patterns","ecc:kotlin-testing","ecc:kubernetes-patterns","ecc:laravel-patterns","ecc:laravel-plugin-discovery","ecc:laravel-security","ecc:laravel-tdd","ecc:laravel-verification","ecc:latency-critical-systems","ecc:lead-intelligence","ecc:liquid-glass-design","ecc:llm-trading-agent-security","ecc:logistics-exception-management","ecc:make-interfaces-feel-better","ecc:manim-video","ecc:market-research","ecc:marketing-campaign","ecc:mcp-server-patterns","ecc:messages-ops","ecc:ml-adoption-playbook","ecc:mle-workflow","ecc:motion-advanced","ecc:motion-foundations","ecc:motion-patterns","ecc:motion-ui","ecc:mysql-patterns","ecc:nanoclaw-repl","ecc:nestjs-patterns","ecc:netmiko-ssh-automation","ecc:network-bgp-diagnostics","ecc:network-config-validation","ecc:network-interface-health","ecc:nextjs-turbopack","ecc:nodejs-keccak256","ecc:nutrient-document-processing","ecc:nuxt4-patterns","ecc:openclaw-persona-forge","ecc:opensource-pipeline","ecc:orch-add-feature","ecc:orch-build-mvp","ecc:orch-change-feature","ecc:orch-fix-defect","ecc:orch-pipeline","ecc:orch-refine-code","ecc:parallel-execution-optimizer","ecc:perl-patterns","ecc:perl-security","ecc:perl-testing","ecc:plan-orchestrate","ecc:plankton-code-quality","ecc:postgres-patterns","ecc:prediction-market-oracle-research","ecc:prediction-market-risk-review","ecc:prisma-patterns","ecc:product-capability","ecc:product-lens","ecc:production-audit","ecc:production-scheduling","ecc:project-flow-ops","ecc:prompt-optimizer","ecc:python-patterns","ecc:python-testing","ecc:pytorch-patterns","ecc:quality-nonconformance","ecc:quarkus-patterns","ecc:quarkus-security","ecc:quarkus-tdd","ecc:quarkus-verification","ecc:ralphinho-rfc-pipeline","ecc:react-patterns","ecc:react-performance","ecc:react-testing","ecc:recsys-pipeline-architect","ecc:recursive-decision-ledger","ecc:redis-patterns","ecc:regex-vs-llm-structured-text","ecc:remotion-video-creation","ecc:repo-scan","ecc:research-ops","ecc:returns-reverse-logistics","ecc:rules-distill","ecc:rust-patterns","ecc:rust-testing","ecc:safety-guard","ecc:santa-method","ecc:scientific-db-pubmed-database","ecc:scientific-db-uspto-database","ecc:scientific-pkg-gget","ecc:scientific-thinking-literature-review","ecc:scientific-thinking-scholar-evaluation","ecc:search-first","ecc:security-bounty-hunter","ecc:security-review","ecc:security-scan","ecc:seo","ecc:skill-comply","ecc:skill-scout","ecc:skill-stocktake","ecc:social-graph-ranker","ecc:social-publisher","ecc:springboot-patterns","ecc:springboot-security","ecc:springboot-tdd","ecc:springboot-verification","ecc:strategic-compact","ecc:swift-actor-persistence","ecc:swift-concurrency-6-2","ecc:swift-protocol-di-testing","ecc:swiftui-patterns","ecc:taste","ecc:tdd-workflow","ecc:team-agent-orchestration","ecc:team-builder","ecc:terminal-ops","ecc:tinystruct-patterns","ecc:token-budget-advisor","ecc:ui-demo","ecc:ui-to-vue","ecc:uncloud","ecc:unified-notifications-ops","ecc:verification-loop","ecc:video-editing","ecc:videodb","ecc:visa-doc-translate","ecc:vite-patterns","ecc:vue-patterns","ecc:windows-desktop-e2e","ecc:workspace-surface-audit","ecc:x-api","harness:harness","claude-mem:babysit","claude-mem:cloud-sync","claude-mem:design-is","claude-mem:do","claude-mem:how-it-works","claude-mem:knowledge-agent","claude-mem:learn-codebase","claude-mem:make-plan","claude-mem:mem-search","claude-mem:oh-my-issues","claude-mem:pathfinder","claude-mem:smart-explore","claude-mem:standup","claude-mem:timeline-report","claude-mem:version-bump","claude-mem:weekly-digests","claude-mem:what-the","claude-mem:wowerpoint","cowork-plugin-management:cowork-plugin-customizer","cowork-plugin-management:create-cowork-plugin","design:accessibility-review","design:design-critique","design:design-handoff","design:design-system","design:research-synthesis","design:user-research","design:ux-copy","anthropic-skills:consolidate-memory","anthropic-skills:docx","anthropic-skills:morning","anthropic-skills:pdf","anthropic-skills:pptx","anthropic-skills:schedule","anthropic-skills:setup-cowork","anthropic-skills:skill-creator","anthropic-skills:xlsx","dataviz","artifact-design","artifact-capabilities","update-config","keybindings-help","verify","simplify","fewer-permission-prompts","loop","schedule","claude-api","run","init","review","security-review"]},"type":"attachment","uuid":"fc51fb6e-a155-418e-a4cf-d063d78a9c42","timestamp":"2026-07-16T05:20:04.962Z","userType":"external","entrypoint":"claude-desktop","cwd":"/Users/kty/Downloads/chat/.claude/worktrees/priceless-spence-f96ade","sessionId":"06afd324-52e8-4869-b7ab-02c01d1a26dd","version":"2.1.209","gitBranch":"claude/harness-template-generalize-e719c2"}

2026-08-10T08:18:32.955725Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "for f in \"/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1.jsonl\" \"/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/69541816-ba99-427f-8dd9-3719d66a6367.jsonl\"; do jq -r 'select(.type==\"assistant\") | [(.message|type),(.message.content|type),((.message.content // []) | if type==\"array\" then map(type)|unique|join(\",\") else \"-\" end)] | @tsv' \""'$f" 2>/dev/null; done | sort | uniq -c
for f in "/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/0740a10e-595a-45e6-a7d7-6476b9eb66a1.jsonl" "/Users/kty/.claude/projects/-Users-kty-Downloads-pokeclip-mono--claude-worktrees-kty-harness-template-readme-3cf068/69541816-ba99-427f-8dd9-3719d66a6367.jsonl"; do jq -r '"'.type' \""'$f" 2>/dev/null; done | sort | uniq -c' in /Users/kty/Downloads/kty-claude-harness-template
2026-08-10T08:18:49.929005Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
 succeeded in 239ms:
 409 object	array	object
 409 assistant
1635 attachment
 156 custom-title
 159 last-prompt
  58 mode
  97 pr-link
  38 queue-operation
  13 system
 213 user

exec
/bin/zsh -lc "rg -n '"'^run_mutation |''^total='"\\"'$'"\\(\\(total \\+ 1\\)\\)' _workspace/mutate-decision-gate.sh
rg -n '"'^d[0-9]+[a-z]*'"\\(\\)' tests/decision-gate.test.sh | wc -l
git diff --check 238a979..HEAD -- template/.claude/hooks/_common.sh template/.claude/hooks/verify-before-stop.sh tests/decision-gate.test.sh _workspace/mutate-decision-gate.sh docs/decisions/2026-08-10-decision-gate.md docs/usage.md" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
114:run_mutation '게이트 자체를 무력화한다' "$STOP" \
118:run_mutation '질문 0회 조건을 지운다 (질문해도 안 풀린다)' "$COMMON" \
123:run_mutation '표지 판정을 지운다 (아무 문장이나 걸린다)' "$COMMON" \
127:run_mutation '걸린 문장을 메시지에 안 싣는다' "$STOP" \
131:run_mutation '예산 호출을 지운다 (영원히 막힌다)' "$STOP" \
135:run_mutation '탈출구 판정을 지운다 (꺼도 안 꺼진다)' "$STOP" \
142:run_mutation '인라인 코드 제외를 지운다' "$COMMON" \
146:run_mutation '따옴표 인용 제외를 지운다' "$COMMON" \
150:run_mutation '인용줄 제외를 지운다' "$COMMON" \
155:run_mutation '코드펜스 제외를 지운다' "$COMMON" \
161:run_mutation '질문 신호 제외를 지운다' "$COMMON" \
166:run_mutation '서술형 종결 요구를 지운다' "$COMMON" \
170:run_mutation 'thinking 블록까지 스캔한다' "$COMMON" \
180:run_mutation '서브에이전트 발화까지 스캔한다' "$COMMON" \
185:run_mutation '도구 입력까지 스캔한다 (자기참조 폭발)' "$COMMON" \
200:run_mutation '마지막이 아니라 첫 프롬프트를 경계로 삼는다' "$COMMON" \
208:run_mutation '상단 toolUseResult 판정을 지운다' "$COMMON" \
213:run_mutation 'tool_result 블록 판정을 지운다' "$COMMON" \
227:run_mutation '판독 불가를 통과로 위장한다 (사유 소실)' "$COMMON" \
234:run_mutation '판독 불가 사유를 안 실어 보낸다' "$STOP" \
238:run_mutation '판독 불가 사유를 안 출력한다' "$STOP" \
242:run_mutation '기록을 못 읽어도 조용히 넘어간다' "$COMMON" \
246:run_mutation '턴 시작점을 못 찾으면 전체를 훑는다' "$COMMON" \
253:run_mutation '"묻지 않았다" 예외를 지운다 (자백이 샌다)' "$COMMON" \
257:run_mutation '마침표를 무조건 종결로 되돌린다' "$COMMON" \
261:run_mutation '물결 펜스 지원을 지운다' "$COMMON" \
265:run_mutation '이중 백틱 지원을 지운다' "$COMMON" \
269:run_mutation '문자열 content 를 건너뛴다 (발화가 사라진다)' "$COMMON" \
277:run_mutation '부분 손상을 건너뛴다 (전멸일 때만 실패)' "$COMMON" \
285:run_mutation 'message 형식 검사를 지운다' "$COMMON" \
295:run_mutation 'content 형식 검사를 지운다' "$COMMON" \
305:run_mutation '정상 경로가 예상 밖 rc 를 낸다 (호출부 catch-all 검출)' "$COMMON" \
319:run_mutation '발동을 플래그가 아니라 조기 종료에 맡긴다' "$STOP" \
327:run_mutation '앞 게이트(듀얼리뷰)에서 사유를 뺀다' "$STOP" \
336:total=$((total + 1))
      59

2026-08-10T08:19:08.820679Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "rg -n 'decision-gate\\.test|결정 게이트 회귀' .github template tests docs README.md --hidden" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
.github/workflows/check-rules.yml:42:      - name: 결정 게이트 회귀 테스트
.github/workflows/check-rules.yml:43:        run: ./tests/decision-gate.test.sh
tests/decision-gate.test.sh:2:# decision-gate.test.sh — Stop 훅의 **결정 게이트**(stop:decision) 회귀 방어.
tests/decision-gate.test.sh:594:echo "결정 게이트 회귀 테스트"
tests/decision-gate.test.sh:613:echo "✓ 결정 게이트 회귀 방어 유지"
docs/decisions/2026-08-10-decision-gate.md:142:`tests/decision-gate.test.sh` **59건** + CI 스텝. 차단 · 위양성 · 발동조건 · 판독불가 8 · 탈출구 3 · 벽돌방지 2 · 순서 1 · 턴경계 5.

2026-08-10T08:19:30.726293Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
exec
/bin/zsh -lc "git diff --unified=12 238a979..HEAD -- docs/usage.md docs/decisions/2026-08-10-decision-gate.md | sed -n '1,360p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
diff --git a/docs/decisions/2026-08-10-decision-gate.md b/docs/decisions/2026-08-10-decision-gate.md
index c3d45c3..5774d41 100644
--- a/docs/decisions/2026-08-10-decision-gate.md
+++ b/docs/decisions/2026-08-10-decision-gate.md
@@ -40,31 +40,53 @@
 그리고 위양성의 가장 큰 원천이 **자기참조**다 — 이 게이트의 훅·테스트·이 ADR 이 전부 그 어휘를 데이터로 품는다. 어휘만 보면 **이 게이트를 유지보수하는 작업 자체가 매번 걸리고**, 그러면 사람이 게이트를 끈다. 꺼진 게이트는 없는 게이트다.
 
 그래서 좁히는 장치 셋을 둔다:
 
 1. **구조적 제외** — 코드펜스 · 인라인 코드 · 인용줄 · 따옴표로 감싼 부분은 안 본다. 어휘를 인용부호로 감싸 언급하는 것은 문서·설명의 정상 형태다
 2. **질문 신호 제외** — 같은 문장에 물음이 있으면 자백이 아니라 묻는 중이다
 3. **서술형 종결 요구** — 단정으로 끝나야 "내가 그렇게 했다"이다
 
 그리고 **도구 입력을 보지 않는다(발화 텍스트만 본다).** 이 패턴이 적힌 파일을 쓰는 것 자체는 결정이 아니므로 자기참조 폭발이 **원천에서** 없어진다. 사고 블록도 안 본다(저울질은 통보가 아니다). 서브에이전트 발화도 뺀다(서브에이전트는 사용자에게 물을 수 없다).
 
 **대가는 위음성 증가다.** 표현을 조금 바꾸면 빠져나간다. 그럼에도 값을 하는 이유는 겨누는 것이 적대적 회피가 아니라 **무의식적 습관**이기 때문이다 — `guard-hook-disable` 이 "막힌 에이전트의 직진 충동"을 겨눈 것과 같은 판단 구조다.
 
-### ② fail-open 은 한 곳뿐이고, 소리를 낸다
+### ①-1 어휘는 **표본**이지 분류법이 아니다 (2026-08-10 사용자 지적)
+
+저 9개는 원리에서 유도한 것이 아니라 **한 세션에서 LLM 이 실제로 쓴 문장을 관찰해 뽑은 것**이다. 사용자가 이 점을 짚었다 — *"어차피 내가 쓴 게 아니고 LLM 이 내가 말할 걸 정리해서 쓰는 것이라 그것에서 비롯한 문제가 또 발생할 것 같은데."*
+
+맞는 지적이고, 결론을 바꾼다. **목록을 좁히지 않는다.** 좁히는 규칙도 결국 같은 출처의 추측이라 추측 위에 추측을 쌓는 일이 된다. 검수가 "`별도로`·`트레이드오프` 는 단순 기술 서술에도 나온다"고 정당하게 지적했지만(→ Consequences 의 위양성 항목), 그 대응으로 어휘에 조건을 붙이는 것은 문제를 줄이는 게 아니라 **다른 자리로 옮기는 것**이다.
+
+대신 **주장을 사실에 맞춘다**:
+
+- 이것은 **관찰된 표현에 맞춘 과속방지턱**이지 "말하지 않은 결정"의 탐지기가 아니다
+- **영어 발화는 하나도 못 본다.** 표지가 전부 한국어다 — 커버리지 0인 축이 통째로 있다
+- 목록은 **새는 것을 실제로 본 뒤에만** 늘린다. 이 저장소가 게이트를 만드는 방식 그대로다(*"선제 방어는 하지 않는다 — 실제로 겪은 뒤에 강제를 추가한다"*)
+
+**어휘를 사용자 슬롯으로 빼지 않는다.** 언어·모델마다 다를 테니 그럴싸하지만, 실제로 새는 것을 보기 전에 설정을 늘리는 것은 같은 YAGNI 규칙에 걸린다. 새는 게 관측되면 그때 뺀다.
+
+### ② fail-open 은 판독 불가 하나이고, 소리를 낸다
 
 이 저장소의 원칙은 *"검사기의 유일한 치명 결함은 위음성"* 이고 애매하면 전부 fail-closed 다. **이 게이트에 예외를 하나 둔다.**
 
 대화 기록의 형식은 **하네스가 소유하지 않는다** — 도구 제공자가 정하고 예고 없이 바뀐다. 형식이 바뀌었다고 차단하면 **그 세션 안에 고칠 방법이 없다**: 기록을 고칠 수는 없으므로 어떤 행동으로도 게이트가 안 풀리고, 세션이 통째로 벽돌이 된다. 다른 게이트는 전부 "무언가를 하면 풀리는" 구조라 이 문제가 없다.
 
-**조건은 경고를 삼키지 않는 것이다.** 판독에 실패하면 사유가 마지막 게이트 메시지에 실린다. 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다. 그 침묵 자체를 변이 5건으로 붙들었다.
+**조건은 경고를 삼키지 않는 것이다.** 판독에 실패하면 사유가 **막는 게이트가 무엇이든 그 메시지에** 실린다. 조용히 통과하면 게이트가 죽은 것을 아무도 모르고, 그것이 이 저장소가 부르는 조용한 실패다.
+
+**초안은 이 약속을 지키지 못했고, 검수가 그것을 잡았다.** 처음에는 *"rc=2 가 유일한 fail-open"* 이라고 적었는데 사실이 아니었다 — 부분 손상·처리 못 한 예외·`python3` 부재가 전부 "표지 없음"과 **같은 종료 코드**로 나갔다. 고친 뒤의 계약은 이렇다:
+
+```
+0  차단     2  판독 불가(사유 있음)     3  차단 불필요     그 밖  → 판독 불가로 취급
+```
+
+정상 통과에 흔한 코드(1)를 **주지 않는 것**이 핵심이다. 그래야 크래시가 정상 통과로 위장되지 않는다. 그리고 사유는 **다섯 게이트 전부**에 싣는다 — 감사 게이트에만 실으면 앞 게이트가 먼저 막은 턴에 안 보이고, 그 플래그를 지운 다음 턴에는 조기 종료로 영영 사라진다.
 
 ### ③ 사용자 확정 3건 (2026-08-10)
 
 | 물은 것 | 확정 | 근거 |
 |---|---|---|
 | 탈출구를 둘까 | **둔다** (`ECC_DISABLED_HOOKS=stop:decision`) | 위양성이 구조적으로 나므로 사용자가 즉시 뺄 수 있어야 한다. 끄는 대입 자체는 `guard-hook-disable` 이 한 번 세운다 |
 | 어느 턴에서 도나 | **코드 + 결정 문서 + 설계 산출물** | 표지 어휘가 가장 자주 나오는 자리가 결정 문서를 쓰는 턴이다 |
 | 패턴을 얼마나 좁히나 | **좁힌 서술형 + 구조적 제외** | 자기참조 폭발을 막는 유일한 길 |
 
 **탈출구 유무가 `guard-hook-disable` 과 갈리는 이유**를 적어 둔다. 그쪽은 *"탈출구가 있으면 그것으로 나머지를 전부 끌 수 있어서"* 두지 않았다. 이쪽은 그렇지 않다 — 이 게이트를 꺼도 나머지 게이트는 그대로 살아 있고, 반대로 위양성으로 막혔을 때 사용자가 뺄 수단이 없으면 세 번 헛돌아야 한다. **비대칭이 다르면 답도 다르다.**
 
 ### ④ 순서 — 다른 게이트보다 앞이다
@@ -95,40 +117,54 @@
 - **Cons**: 아무것도 안 바꾼 턴까지 막아 대화를 방해한다
 - **Why not**: 사용자 기각
 
 ## Consequences
 
 ### Positive
 - **"혼자 정하고 한 줄 적는" 부류가 처음으로 기계에 걸린다.** ADR-0011 이 남긴 가장 큰 공백이 닫힌다
 - 걸린 문장이 메시지에 실리므로 **무엇을 물어야 하는지**가 화면에 뜬다. 안 실으면 "일단 아무거나 물어서 풀자"가 되어 게이트가 의식(儀式)이 된다
 - 질문 한 번이면 풀린다 — 비용이 낮아 게이트를 끌 동기가 약하다
 
 ### Negative
 - **위음성이 있다.** 표현을 바꾸면 빠져나간다. 좁힌 대가이고, 겨누는 것이 적대적 회피가 아니라 습관이라 감수한다
-- **위양성이 남는다.** 서술형으로 끝나면서 이 어휘를 쓰는 정당한 문장은 걸린다. 인용부호로 감싸면 빠지고, 그 안내를 차단 메시지에 넣었다
-- **fail-open 이 하나 있다.** 대화 기록 형식이 바뀌면 게이트가 사라진다 — 통과하되 사유를 마지막 메시지에 싣는다
-- 대화 기록 형식에 **의존이 하나 생겼다.** 하네스가 소유하지 않는 형식이고, 바뀌면 위 fail-open 으로 떨어진다
+- **영어 발화는 커버리지 0이다.** 표지가 전부 한국어다. 축 하나가 통째로 비어 있다
+- **위양성이 남는다.** 표지 어휘는 자백에만 나오지 않는다 — 검수가 실례를 댔다: *"기존 스캐너는 범위 밖 입력을 거부합니다"* · *"변이 테스트는 별도로 실행됩니다"* · *"이 트레이드오프는 ADR 에 설명되어 있습니다"*. 전부 결정 통보가 아닌데 걸린다. **고치지 않기로 했다**(①-1) — 인용부호나 백틱으로 감싸면 빠지고, 질문 한 번이면 풀린다
+- **판독 불가는 통과다.** 대화 기록 형식이 바뀌면 게이트가 사라진다 — 통과하되 사유를 다섯 게이트 메시지에 싣는다
+- 대화 기록 형식에 **의존이 하나 생겼다.** 하네스가 소유하지 않는 형식이고, 바뀌면 위 경로로 떨어진다
+- **Stop 훅이 매 턴 대화 기록 전체를 읽는다.** 긴 세션에서 비용이 는다(현재 실측 범위에서는 문제없음)
 
 ### 공시된 한계 — 지식 게이트를 끄면 결정 문서 턴이 빠진다
 `HARNESS_KNOWLEDGE_GATE` 를 리터럴로 비운 환경에서는 **결정 문서만** 고친 턴이 조기 종료에 걸려 결정 게이트까지 도달하지 못한다. 기본값이 켜짐이라 기본 구성에서는 정상 발동한다.
 
 **고치지 않는다(사용자 확정).** 조기 종료가 지식 플래그를 게이트 켜짐일 때만 세는 것은 *"게이트를 껐는데 예전에 남은 플래그가 읽기 전용 턴의 조기 종료를 막는"* 문제를 막으려고 넣은 것이다. 결정 게이트를 위해 그걸 되돌리면 알려진 버그 부류가 되살아난다. **한계 자체를 케이스(d30b)로 붙들었다** — 이 동작이 바뀌면 그 케이스가 빨개진다.
 
 ## 기계적 장치
 
-`tests/decision-gate.test.sh` **48건** + CI 스텝. 차단 9 · 위양성 19 · 발동조건 6 · 판독불가 5 · 탈출구 3 · 벽돌방지 2 · 순서 1 · 턴경계 3.
+`tests/decision-gate.test.sh` **59건** + CI 스텝. 차단 · 위양성 · 발동조건 · 판독불가 8 · 탈출구 3 · 벽돌방지 2 · 순서 1 · 턴경계 5.
 
 **rc 만으로 판정하지 않는다.** 결정 게이트가 통과해도 뒤의 감사 게이트가 같은 rc=2 를 내므로, 어느 게이트가 말했는지는 **메시지로만** 갈린다. 그리고 통과를 기대하는 케이스는 감사 게이트가 **실제로 말했는지**를 함께 요구한다 — 안 하면 훅이 앞에서 죽어도 초록이 난다.
 
-`_workspace/mutate-decision-gate.sh` **변이 24건 전건 적색.** 방어 제거(위음성) · 좁히는 장치 제거(위양성) · 턴 경계 흐리기 · fail-open 침묵화 · 게이트 이동.
+`_workspace/mutate-decision-gate.sh` **변이 35건 전건 적색.** 방어 제거(위음성) · 좁히는 장치 제거(위양성) · 턴 경계 흐리기 · fail-open 침묵화 · 게이트 이동 · 검수 반영분.
+
+**공시된 측정 공백:** 호출부의 "모르는 rc" 처리만 지우는 변이는 **원리적으로 초록**이다 — 정상 동작에서 그 가지에 도달하는 입력이 없다(`python3` 를 없애면 `json_get` 이 먼저 죽어 경로가 비고, 그러면 다른 가지로 빠진다). 대신 *정상 경로가 모르는 rc 를 내게 하는* 변이가 그 가지의 생존을 증명한다. 두 항목이 짝이고 하나만 보면 오판한다.
 
 ### 변이가 잡은 것 둘 — 통과 개수로는 안 보였다
 
 1. **질문 신호 판정이 죽어 있었다.** 위양성 케이스들의 종결이 "…까요/…세요"라 **서술형 요구에서 이미 걸러져 질문 판정에 도달조차 하지 않았다.** 판정 *순서*가 케이스를 무력화한 것이라 어휘를 아무리 늘려도 안 잡힌다. 서술형으로 끝나면서 묻는 문장을 케이스로 넣어 살렸다.
 2. **턴 경계의 두 판정이 서로를 가렸다.** 실제 기록은 상단 `toolUseResult` 와 `tool_result` 블록을 **항상 함께** 갖고 있다(실측 69/69). 그래서 한쪽을 지워도 다른 쪽이 막아 준다. 표식이 하나뿐인 픽스처를 만들어 각각을 독립적으로 지키게 했다.
 
 앞은 **판정 순서**가, 뒤는 **데이터의 중복**이 방어를 가린 사례다. 둘 다 "케이스가 통과한다"가 "그 방어가 지켜진다"를 뜻하지 않는 부류이고, 변이 없이는 원리적으로 안 보인다.
 
+3차로 같은 부류가 하나 더 나왔다 — 검수 반영으로 **모르는 rc 를 판독 불가로 취급**하게 만들자, 그 catch-all 이 *개별* 판독 불가 검사들을 가려버렸다(그 검사를 지워도 크래시가 catch-all 에 걸려 경고가 나왔다). 판독 불가 케이스가 **사유 조각까지** 요구하게 고쳐서 각각을 다시 격리했다. **새 방어가 옛 방어를 가리는 것**도 이 부류다.
+
+### 검수가 잡은 것 — 공시가 사실이 아니었다
+
+codex 독립 검수 1라운드(판정 보류, HIGH 5 · MEDIUM 3 · LOW 1)가 이 ADR 초안의 **핵심 주장 하나를 반증했다.** *"rc=2 가 유일한 fail-open"* 이 사실이 아니었고, 조용히 통과하는 경로가 넷 더 있었다(부분 손상 · 모르는 rc · truthy 비-dict `message` · 문자열 `content`). 게다가 경고 자체가 감사 게이트에만 실려 **앞 게이트가 먼저 막으면 사라졌다** — 경고를 삼키지 않는 것이 이 fail-open 의 유일한 조건인데 그게 안 지켜지고 있었다.
+
+가장 값진 지적은 **겨누는 문장 자체가 빠져나간 것**이었다: *"사용자에게 물어보지 않고 제 판단으로 진행했습니다"* 가 `물어` 때문에 질문으로 오인돼 통과했다. **부정이 붙으면 물음이 아니라 자백이다.**
+
+*거짓 공시는 남은 결함보다 나쁘다* 를 이 ADR 이 스스로 어겼고, 독립 컨텍스트가 그것을 잡았다.
+
 ## 관련
 - [ADR-0011](2026-08-10-self-discipline-gates.md) — 이 게이트를 후속으로 남긴 곳
 - [ADR-0008](2026-08-06-knowledge-gate-default-on.md) — 게이트 기본값과 판독 계약
 - [ADR-0007](2026-08-06-gate-scope-by-file-identity.md) — 어느 편집이 게이트 대상인가
diff --git a/docs/usage.md b/docs/usage.md
index 2ccfc88..b020935 100644
--- a/docs/usage.md
+++ b/docs/usage.md
@@ -70,25 +70,32 @@ cd ~/.claude/harness-template
 
 **탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:decision`(결정 게이트만) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) / `stop:push`(push 게이트만) 나열.
 **`guard-hook-disable` 은 과속방지턱이지 보안 경계가 아니다.** 판정이 정규식 하나라 셸을 해석하지 못한다 — `read`+`export`, 따옴표로 쪼갠 `env 'X''=off'`, 변수 조립, `eval`, 생성한 스크립트 실행은 전부 통과한다(실측). 그럼에도 값을 하는 이유는 막으려는 것이 적대적 공격자가 아니라 **막힌 에이전트의 직진 충동**이고, 그건 `HARNESS_HOOKS=off ...` 라는 직진형으로 나오기 때문이다. 제대로 막으려면 셸 파서가 필요한데, 반쯤 만든 셸 파서는 안 만든 것보다 나쁘다(막힌다고 믿게 하면서 안 막는다 — 이 저장소가 `harness.env` 판독기에서 겪은 늪).
 
 **그래서 위양성 쪽으로 기운다.** 실행 구문과 인용문을 구분하지 않아 `git grep 'HARNESS_HOOKS=off'` 같은 정당한 검색도 막힌다. 의도된 선택이다 — 따옴표 안을 건너뛰면 위양성은 사라지지만 `bash -c 'HARNESS_HOOKS=off ...'` 가 뚫린다. 둘은 문자열로 구별되지 않는 같은 모호성의 양면이고, 위양성은 메시지 한 번이 비용이지만 위음성은 **게이트가 꺼진 걸 아무도 모르는** 것이 비용이다. 차단 메시지가 위양성일 때의 대안(패턴 쪼개기·Write 도구 사용)을 함께 안내한다.
 
 **그리고 환경변수로 끌 수 없다.** 그 탈출구가 있으면 에이전트가 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다. 사용자가 정말 끄려면 셸에서 직접 `export` 하고 세션을 새로 띄우거나 `settings.json` 배선을 지운다 — 둘 다 사람이 하는 행위다.
 
 **결정 게이트가 있는 이유:** 나머지 게이트는 전부 **산출물**을 본다("코드가 검증됐나", "설명이 나왔나"). 그런데 실측된 실패의 대부분은 산출물이 아니라 **행동**이었다 — 게이트가 막을 때는 세 번 다 따랐으면서, 게이트가 없는 자리에서는 전부 혼자 정하고 보고서에 한 줄 적었다. 그 "한 줄"은 도구 호출이 아니라 문장이라 승인창도 안 뜬다. 그래서 이 게이트만 **대화 기록을 직접 읽는다**: 코드·결정이 바뀐 턴에 결정 표지 어휘를 담은 서술형 문장이 있는데 `AskUserQuestion` 이 0회면 막고, 걸린 문장을 목록으로 보여준다. **질문 한 번이면 풀린다.**
 
 **여기서는 위양성도 위음성만큼 비싸다.** 다른 검사기와 판단이 갈리는 유일한 자리다 — 위양성의 비용이 메시지 한 번이 아니라 사용자에게 가는 **불필요한 질문**이고, 그게 반복되면 질문이 소음이 되어 진짜 질문까지 무시된다. 게다가 이 게이트의 훅·테스트·ADR 이 그 어휘를 데이터로 품어서, 어휘만 보면 **게이트를 유지보수하는 작업 자체가 매번 걸린다.** 그래서 좁힌다: 코드펜스·인라인 코드·인용줄·따옴표 안은 안 보고, 같은 문장에 물음이 있으면 세지 않고, 서술형 단정으로 끝나야 센다. **도구 입력도 안 본다**(발화 텍스트만) — 그 어휘가 적힌 파일을 쓰는 것 자체는 결정이 아니다. 사고 블록과 서브에이전트 발화도 뺀다.
 
-*걸렸는데 결정이 아니라면* 백틱이나 따옴표로 감싸면 빠진다. 그래도 걸리면 사용자에게 알리고 지시를 받는다. **대가는 위음성이다** — 표현을 바꾸면 빠져나간다. 겨누는 것이 적대적 회피가 아니라 무의식적 습관이라 그래도 실효가 남는다.
+*걸렸는데 결정이 아니라면* 백틱이나 따옴표로 감싸면 빠진다. 그래도 걸리면 사용자에게 알리고 지시를 받는다.
+
+**이건 탐지기가 아니라 과속방지턱이다.** 표지 어휘는 원리에서 유도한 분류법이 아니라 **한 세션에서 실제로 쓰인 문장을 관찰해 뽑은 표본**이다. 그래서:
+
+- 표현을 조금 바꾸면 **빠져나간다**(위음성). 겨누는 것이 적대적 회피가 아니라 무의식적 습관이라 그래도 실효가 남는다
+- **영어 발화는 하나도 못 본다.** 표지가 전부 한국어다 — 축 하나가 통째로 비어 있다
+- 반대로 그 어휘는 자백에만 나오지도 않는다. `변이 테스트는 별도로 실행됩니다` 같은 **단순 기술 서술도 걸린다.** 어휘에 조건을 덧붙여 좁히지 **않기로 했다** — 그 조건도 같은 출처의 추측이라 문제를 없애는 게 아니라 옮기는 것이기 때문이다
+- 목록은 **새는 것을 실제로 본 뒤에만** 늘린다. 이 저장소가 게이트를 만드는 방식 그대로다
 
 **대화 기록을 못 읽으면 막지 않고 통과시킨다 — 이 하네스에서 유일한 fail-open 이다.** 기록 형식은 하네스가 소유하지 않아 예고 없이 바뀔 수 있는데, 그때 차단하면 **그 세션 안에 고칠 방법이 없어 통째로 벽돌이 된다**(기록을 고칠 수 없으므로 어떤 행동으로도 안 풀린다). 대신 사유가 마지막 게이트 메시지에 실린다 — 조용히 통과하면 게이트가 죽은 것을 아무도 모른다. **공시된 한계:** `HARNESS_KNOWLEDGE_GATE` 를 비운 환경에서는 결정 문서만 고친 턴이 조기 종료에 걸려 이 게이트까지 오지 않는다(기본값이 켜짐이라 기본 구성에서는 정상 발동). 자세한 근거는 [ADR-0012](decisions/2026-08-10-decision-gate.md).
 
 **push 게이트가 있는 이유:** 이 저장소는 커밋 29개를 잃은 적이 있다. 코드는 다 짜여 있었고 "아직 PR 전이니까"라며 push 를 미뤘다. 게이트는 **네트워크를 쓰지 않는다** — 로컬 remote-tracking ref 만 본다. 원격에 있는데도 ref 가 안 보이면(`remote.origin.fetch` 가 좁혀진 경우) 그 사실을 사유에 적는다. push 여부가 로컬에서 안 보이는 것 자체가 위험이기 때문이다. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
 
 ### 완료 게이트 검사 범위 (mark-needs-audit)
 
 판정 **순서가 곧 계약**이다: 개행 가드 → 물리 경로 정규화 → 듀얼리뷰 판정 → 범위 판정 → 분류 → 기록.
 
 - **프로젝트 안** — `_workspace/`·`.claude/`·문서 `*.md`·`*.markdown`(대소문자 무관)는 제외. 나머지는 게이트 4종.
   단 **문서 제외에는 예외가 둘** 있다(동작을 정의하는 마크다운이라 코드로 취급한다):
   `.claude/` 에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`), 그리고

2026-08-10T08:19:50.419766Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
codex
[HIGH] template/.claude/hooks/verify-before-stop.sh:102 — `gate_budget`가 `emit_decision_note`보다 먼저 호출되므로, 동일 지문으로 예산이 이미 3회 소진된 턴에 새로 판독 불가가 발생하면 107행에서 즉시 종료해 사유가 영구 소실된다. `3회 정상 차단 → 4번째 기록 손상` 순서가 재현 경로다. 벽돌방지 `systemMessage`에 `decision_note`를 포함하거나 판독 상태를 지문에 반영하고 회귀 케이스를 추가해야 한다.

[HIGH] template/.claude/hooks/_common.sh:424 — 엄격화가 JSON 문법과 `message`/`content` 컨테이너에서 멈춘다. 사용자 프롬프트 뒤에 유효한 JSON인 `[]`가 오면 `broken=0`인 채 448행에서 건너뛰고, assistant의 `content`가 `["범위 밖이라 그대로 뒀습니다."]`여도 464행에서 블록을 버려 rc=3으로 조용히 통과한다. 최상위 비-dict와 assistant content의 비-dict 블록·잘못된 text 필드도 판독 불가로 내려야 한다.

[MEDIUM] template/.claude/hooks/_common.sh:363 — 부정형 예외가 흔한 띄어쓰기·조사 변형을 놓친다. `사용자에게 물어 보지 않고 제 판단으로 진행했습니다.`는 `QUESTION`의 `물어`에는 걸리지만 `NEG_ASK`의 붙여 쓴 `물어보지`에는 안 걸려 통과한다. `사용자 의견을 확인도 하지 않고 가정하여 구현했습니다.`도 같은 구조다. 최소한 `물어 ?보지`, `확인(?:도)? 하지` 계열과 대응 테스트가 필요하다.

[MEDIUM] template/.claude/hooks/_common.sh:379 — 마침표 뒤 공백 조건은 파일명 위음성만 고쳤고 약어는 여전히 문장을 잘못 자른다. `나머지는 별도로 e.g. 후속 처리했습니다.`는 `별도로`와 서술형 종결이 다른 조각으로 갈라져 통과한다. 약어 처리 또는 문장 단위 판정 방식 보강이 필요하다.

[MEDIUM] template/.claude/hooks/_common.sh:395 — `split("```")`/`split("~~~")`는 일반 Markdown 펜스 파서가 아니다. 네 개 백틱 펜스 안에 삼중 백틱 예시가 들어가면 내부 산문이 코드 밖 조각으로 되살아나 위양성이 난다. ADR·usage의 무제한적인 “코드펜스는 안 본다” 약속과도 어긋난다. 줄 시작·펜스 문자·여는 길이를 추적하거나 문서 약속을 실제 지원 범위로 좁혀야 한다.

[LOW] docs/decisions/2026-08-10-decision-gate.md:45 — 새 `NEG_ASK` 예외 때문에 “같은 문장에 물음이 있으면 제외한다”는 설명은 더 이상 참이 아니다. 부정형 자백에서는 물음 신호가 있어도 제외하지 않는다고 ADR과 `docs/usage.md:80` 양쪽에 명시해야 한다.

[LOW] _workspace/mutate-decision-gate.sh:48 — `INT`·`TERM` 트랩이 `cleanup`만 실행하고 종료하지 않는다. 신호 처리 뒤 측정이 계속되면 락은 이미 제거된 상태라 다른 변이 실행과 겹칠 수 있다. `EXIT`에 cleanup을 두고 `INT`/`TERM`에서는 해당 종료 코드로 `exit`시켜야 한다.

[LOW] tests/decision-gate.test.sh:549 — 판독 불가 경고는 감사 경로와 듀얼리뷰 경로만 검증한다. 현재 설명·지식·push 호출은 존재하지만 셋 중 하나를 제거해도 59건과 35개 변이는 그대로 통과한다. 다섯 게이트 전부라는 수정 계약을 각 경로별 케이스 또는 호출 제거 변이로 붙들어야 한다.

실제 표본의 `queue-operation`·`attachment`·`last-prompt`·`custom-title`은 최상위 dict이면서 assistant가 아니어서 현재 엄격화에 의해 판독 불가로 떨어지지 않는다. `emit_decision_note`의 `${decision_note:-}` 역시 `set -u` 아래에서 안전하다.

판정: 보류
tokens used
148,209
[HIGH] template/.claude/hooks/verify-before-stop.sh:102 — `gate_budget`가 `emit_decision_note`보다 먼저 호출되므로, 동일 지문으로 예산이 이미 3회 소진된 턴에 새로 판독 불가가 발생하면 107행에서 즉시 종료해 사유가 영구 소실된다. `3회 정상 차단 → 4번째 기록 손상` 순서가 재현 경로다. 벽돌방지 `systemMessage`에 `decision_note`를 포함하거나 판독 상태를 지문에 반영하고 회귀 케이스를 추가해야 한다.

[HIGH] template/.claude/hooks/_common.sh:424 — 엄격화가 JSON 문법과 `message`/`content` 컨테이너에서 멈춘다. 사용자 프롬프트 뒤에 유효한 JSON인 `[]`가 오면 `broken=0`인 채 448행에서 건너뛰고, assistant의 `content`가 `["범위 밖이라 그대로 뒀습니다."]`여도 464행에서 블록을 버려 rc=3으로 조용히 통과한다. 최상위 비-dict와 assistant content의 비-dict 블록·잘못된 text 필드도 판독 불가로 내려야 한다.

[MEDIUM] template/.claude/hooks/_common.sh:363 — 부정형 예외가 흔한 띄어쓰기·조사 변형을 놓친다. `사용자에게 물어 보지 않고 제 판단으로 진행했습니다.`는 `QUESTION`의 `물어`에는 걸리지만 `NEG_ASK`의 붙여 쓴 `물어보지`에는 안 걸려 통과한다. `사용자 의견을 확인도 하지 않고 가정하여 구현했습니다.`도 같은 구조다. 최소한 `물어 ?보지`, `확인(?:도)? 하지` 계열과 대응 테스트가 필요하다.

[MEDIUM] template/.claude/hooks/_common.sh:379 — 마침표 뒤 공백 조건은 파일명 위음성만 고쳤고 약어는 여전히 문장을 잘못 자른다. `나머지는 별도로 e.g. 후속 처리했습니다.`는 `별도로`와 서술형 종결이 다른 조각으로 갈라져 통과한다. 약어 처리 또는 문장 단위 판정 방식 보강이 필요하다.

[MEDIUM] template/.claude/hooks/_common.sh:395 — `split("```")`/`split("~~~")`는 일반 Markdown 펜스 파서가 아니다. 네 개 백틱 펜스 안에 삼중 백틱 예시가 들어가면 내부 산문이 코드 밖 조각으로 되살아나 위양성이 난다. ADR·usage의 무제한적인 “코드펜스는 안 본다” 약속과도 어긋난다. 줄 시작·펜스 문자·여는 길이를 추적하거나 문서 약속을 실제 지원 범위로 좁혀야 한다.

[LOW] docs/decisions/2026-08-10-decision-gate.md:45 — 새 `NEG_ASK` 예외 때문에 “같은 문장에 물음이 있으면 제외한다”는 설명은 더 이상 참이 아니다. 부정형 자백에서는 물음 신호가 있어도 제외하지 않는다고 ADR과 `docs/usage.md:80` 양쪽에 명시해야 한다.

[LOW] _workspace/mutate-decision-gate.sh:48 — `INT`·`TERM` 트랩이 `cleanup`만 실행하고 종료하지 않는다. 신호 처리 뒤 측정이 계속되면 락은 이미 제거된 상태라 다른 변이 실행과 겹칠 수 있다. `EXIT`에 cleanup을 두고 `INT`/`TERM`에서는 해당 종료 코드로 `exit`시켜야 한다.

[LOW] tests/decision-gate.test.sh:549 — 판독 불가 경고는 감사 경로와 듀얼리뷰 경로만 검증한다. 현재 설명·지식·push 호출은 존재하지만 셋 중 하나를 제거해도 59건과 35개 변이는 그대로 통과한다. 다섯 게이트 전부라는 수정 계약을 각 경로별 케이스 또는 호출 제거 변이로 붙들어야 한다.

실제 표본의 `queue-operation`·`attachment`·`last-prompt`·`custom-title`은 최상위 dict이면서 assistant가 아니어서 현재 엄격화에 의해 판독 불가로 떨어지지 않는다. `emit_decision_note`의 `${decision_note:-}` 역시 `set -u` 아래에서 안전하다.

판정: 보류
