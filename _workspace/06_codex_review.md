Reading additional input from stdin...
2026-08-10T05:18:16.507480Z ERROR codex_models_manager::cache: failed to load models cache: missing field `supports_reasoning_summaries` at line 93 column 5
OpenAI Codex v0.144.5
--------
workdir: /Users/kty/Downloads/kty-claude-harness-template
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019fea1b-7a07-7232-ac15-3e03c60a2458
--------
user
# 코드 검수 — 에이전트 자기 규율 게이트 둘 (PR #16)

`_workspace/06_gates.diff` 가 변경 전체다(main 9079ac1 → HEAD). 작다.

## 반드시 지킬 것
- **파일을 만들거나 지우지 마라.** mktemp·rm·리다이렉트 금지. 정적 독해로만 판정하고
  **반드시 마지막 줄에 `판정: 통과` 또는 `판정: 보류`** 를 내라.
- 지적은 `[등급] 파일:줄 — 무엇이 언제 어떻게 틀리는가` + 재현 조건.

## 무엇인가

1. `template/.claude/hooks/guard-hook-disable.sh` (신설, PreToolUse/Bash)
   — 에이전트가 `HARNESS_HOOKS`·`ECC_DISABLED_HOOKS`·`ECC_GATEGUARD` 를 **대입**하면 rc=2 차단.
     읽기·언급은 통과. **이 훅에는 환경변수 탈출구가 없다**(의도) — 있으면 그것으로 이 훅을
     끄고 나머지를 전부 끌 수 있다.
2. `verify-before-stop.sh` 에 `stop:push` 게이트 — 로컬 커밋이 원격에 없으면 턴 종료 차단.
   네트워크를 쓰지 않고 로컬 remote-tracking ref 만 본다. origin 없으면 요구 안 함.
3. 회귀 13건 + CI 스텝.

## 특히 봐 달라

- **우회 경로.** 차단을 피해 같은 효과를 내는 명령이 있나? 예: `env HARNESS_HOOKS=off`,
  `declare -x`, `set -a; HARNESS_HOOKS=off`, base64/변수 조립, `eval`, 개행·따옴표 트릭,
  `printf` 로 셸 프로필에 써넣기. grep 기반 차단의 한계는 어디까지인가
- **위양성.** 정상 작업이 막히는 입력이 있나? 문서 편집·테스트 실행·`git grep` 등
- **push 게이트의 오탐/누락.** worktree · 얕은 클론 · detached HEAD · unborn HEAD ·
  브랜치 이름에 슬래시/특수문자 · `origin` 이 아닌 remote 이름 · 여러 remote ·
  upstream 이 다른 브랜치를 가리키는 경우. `rev-list --count` 가 실패하면 어떻게 되나
- **게이트 순서.** push 게이트를 감사보다 앞에 둔 것이 다른 게이트의 예산(MAX_BLOCKS)·
  차단 지문(flags_fp)과 어긋나지 않나. `flags_fp` 에 push 상태가 안 들어가는데 괜찮은가
- **테스트의 위음성.** 통과만 하고 안 잡는 케이스는? 픽스처(로컬 bare repo)가 겨누는
  결함을 가리는 곳은? `git init -b work` 가 구버전 git 에서 실패하면 어떻게 되나
codex
변경 diff와 관련 스크립트·테스트를 정적으로 읽고, 줄 번호 기준으로 우회·위양성·push 상태·게이트 상태기계까지 추적하겠습니다. 요청대로 어떤 파일도 만들거나 수정하지 않고 명령도 읽기 전용으로만 쓰겠습니다.
exec
/bin/zsh -lc "pwd && git status --short && git diff --no-ext-diff --unified=80 9079ac1 HEAD -- _workspace/06_gates.diff && sed -n '1,260p' _workspace/06_gates.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
/Users/kty/Downloads/kty-claude-harness-template
?? _workspace/06_codex_prompt.md
?? _workspace/06_codex_review.md
?? _workspace/06_gates.diff
diff --git a/.github/workflows/check-rules.yml b/.github/workflows/check-rules.yml
index c219e47..b5c7447 100644
--- a/.github/workflows/check-rules.yml
+++ b/.github/workflows/check-rules.yml
@@ -34,6 +34,9 @@ jobs:
       # 거짓 보고로 나오므로 rc 만이 아니라 파일 상태·잔류물·문구까지 잰다.
       - name: 훅 교체 원자성 회귀 테스트
         run: ./tests/install-hook-swap.test.sh
+      # 에이전트가 자기 규율을 우회하는 것을 막는 게이트들. 위음성이 유일한 치명 결함이다.
+      - name: 자기 규율 게이트 회귀 테스트
+        run: ./tests/self-discipline-gates.test.sh
       - name: 규칙 사본 동기화 검사
         run: ./scripts/check-rule-copies.sh
       # 층 경계 검사는 사본 대조 **뒤**다. 앞선 단계가 세운 신뢰 전제(범위·심링크·NUL)를
diff --git a/docs/usage.md b/docs/usage.md
index 808aad8..b0af8e5 100644
--- a/docs/usage.md
+++ b/docs/usage.md
@@ -61,13 +61,17 @@ cd ~/.claude/harness-template
 | 훅 | 시점 | 강제 내용 |
 |---|---|---|
 | guard-master-commit | Bash 실행 전 | master/main 직접 `git commit` 차단 |
+| guard-hook-disable | Bash 실행 전 | **에이전트가 게이트를 끄는 것**을 차단 — `HARNESS_HOOKS`·`ECC_DISABLED_HOOKS`·`ECC_GATEGUARD` **대입**만(읽기는 허용). 탈출구가 **없다** — 있으면 그것으로 나머지를 전부 끌 수 있다 |
 | guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
 | mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (코드는 4종 전부 · 설계·계획 산출물은 듀얼리뷰+지식 · 결정 문서는 지식만). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
-| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → codex 듀얼리뷰 → change-explainer → **지식 저장소 반영** → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
+| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → codex 듀얼리뷰 → change-explainer → **지식 저장소 반영** → **push 미완** → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |
 
 **지식 저장소 게이트가 아는 것은 계약 하나뿐이다** — "지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다." **어디에 어떤 구조로 반영하는지는 하네스가 모른다.** 그건 사용자 층 설정(전역 `CLAUDE.md` 등)이 답하고, 하네스에는 켜짐/꺼짐 1비트만 있다. 그래서 지식 저장소를 바꿔도 하네스는 고치지 않고, 아예 안 쓰는 프로젝트에서도 그대로 돈다.
 
-**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
+**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) / `stop:push`(push 게이트만) 나열.
+**단 `guard-hook-disable` 은 예외다 — 환경변수로 끌 수 없다.** 그 탈출구가 있으면 에이전트가 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다. 사용자가 정말 끄려면 셸에서 직접 `export` 하고 세션을 새로 띄우거나 `settings.json` 배선을 지운다 — 둘 다 사람이 하는 행위다.
+
+**push 게이트가 있는 이유:** 이 저장소는 커밋 29개를 잃은 적이 있다. 코드는 다 짜여 있었고 "아직 PR 전이니까"라며 push 를 미뤘다. 게이트는 **네트워크를 쓰지 않는다** — 로컬 remote-tracking ref 만 본다. 원격에 있는데도 ref 가 안 보이면(`remote.origin.fetch` 가 좁혀진 경우) 그 사실을 사유에 적는다. push 여부가 로컬에서 안 보이는 것 자체가 위험이기 때문이다. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
 
 ### 완료 게이트 검사 범위 (mark-needs-audit)
 
diff --git a/template/.claude/hooks/guard-hook-disable.sh b/template/.claude/hooks/guard-hook-disable.sh
new file mode 100755
index 0000000..fa5d6b8
--- /dev/null
+++ b/template/.claude/hooks/guard-hook-disable.sh
@@ -0,0 +1,58 @@
+#!/usr/bin/env bash
+# PreToolUse(Bash): **에이전트가 게이트를 스스로 끄는 것**을 차단한다.
+#
+# 왜: 이 하네스의 모든 게이트에는 탈출구가 있다(HARNESS_HOOKS=off · ECC_DISABLED_HOOKS ·
+# ECC_GATEGUARD). 탈출구는 **사용자를 위한 것**이지 막힌 에이전트를 위한 것이 아니다.
+# 그런데 지금까지 그 구분은 산문으로만 존재했다 — "제 판단으로 끄지 않겠습니다"라고
+# 말하는 것 말고는 아무것도 막지 않았다. 이 저장소가 반복해서 배운 것이 정확히
+# **산문 규칙은 어겨지고, 어겨져도 조용하다**는 것이다.
+#
+# 게이트가 성가실 때 끄고 싶어지는 순간이 바로 게이트가 일하는 순간이다. 그 순간의
+# 판단을 에이전트에게 맡기면 게이트는 있으나 마나다.
+#
+# **읽는 것은 막지 않는다.** 값을 확인하거나(`echo "$HARNESS_HOOKS"`) 문서에 적는 것은
+# 정상 작업이다. 막는 것은 **대입**뿐이다.
+#
+# 탈출구: 이 훅에는 환경변수 탈출구가 **없다.** 있으면 그 탈출구로 이 훅을 끄고
+# 나머지를 전부 끌 수 있어 존재 이유가 사라진다. guard-codex-invocation 과 같은 처리다.
+# 사용자가 정말 끄려면 셸에서 직접 export 하고 세션을 새로 띄우거나 settings.json 에서
+# 이 훅 배선을 지운다 — 둘 다 사람이 하는 행위다.
+#
+# 셸 이식성: macOS 기본 bash 는 3.2 다.
+
+set -uo pipefail
+# shellcheck source=_common.sh
+. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
+
+payload="$(cat)"
+cmd="$(printf '%s' "$payload" | json_get tool_input.command)"
+[ -z "$cmd" ] && exit 0
+
+# 감시 대상 = 게이트를 끄는 스위치들.
+# 값까지 보지 않는다 — `ECC_DISABLED_HOOKS=stop:knowledge` 처럼 **하나만** 끄는 것도
+# 에이전트가 정할 일이 아니다. 무엇을 끌지는 사용자가 정한다.
+#
+# `이름=` 형태의 **대입**만 잡는다. 앞 문자가 영숫자·밑줄·`$` 가 아니어야 하므로
+# `$ECC_DISABLED_HOOKS` 같은 참조나 `MY_ECC_GATEGUARD=` 같은 다른 이름은 안 걸린다.
+matched="$(printf '%s' "$cmd" \
+  | grep -oE '(^|[^A-Za-z0-9_$])(HARNESS_HOOKS|ECC_DISABLED_HOOKS|ECC_GATEGUARD)=' \
+  | grep -oE '(HARNESS_HOOKS|ECC_DISABLED_HOOKS|ECC_GATEGUARD)' \
+  | sort -u | tr '\n' ' ')"
+[ -z "$matched" ] && exit 0
+
+{
+  echo "[차단] 게이트를 끄려 하고 있습니다: ${matched% }"
+  echo
+  echo "이 탈출구는 **사용자를 위한 것**이지 막힌 에이전트를 위한 것이 아닙니다."
+  echo "게이트가 성가신 순간이 게이트가 일하는 순간입니다."
+  echo
+  echo "해야 할 일: 끄지 말고 **사용자에게 물으세요.**"
+  echo "  - 무엇이 막혔는지"
+  echo "  - 왜 그 게이트를 끄는 것이 옳다고 보는지"
+  echo "  - 끄지 않고 갈 수 있는 길은 없는지"
+  echo
+  echo "사용자가 끄기로 하면 사용자가 직접 셸에서 export 하거나 settings.json 배선을"
+  echo "지웁니다. 이 훅에는 환경변수 탈출구가 없습니다 — 있으면 그것으로 나머지를 전부"
+  echo "끌 수 있어 존재 이유가 사라집니다."
+} >&2
+exit 2
diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
index 756a92d..8022344 100644
--- a/template/.claude/hooks/verify-before-stop.sh
+++ b/template/.claude/hooks/verify-before-stop.sh
@@ -207,6 +207,56 @@ if knowledge_gate_active && ! hook_disabled "stop:knowledge"; then
   bump_and_block
 fi
 
+# (5.5) **커밋했는데 원격에 없다** — 이 저장소가 커밋 29개를 잃은 바로 그 상태다.
+#      그때는 "아직 PR 전이니까"라며 라운드 6개를 미뤘고, 임시 폴더째 사라졌다.
+#      검수 통과는 push 의 전제가 아니다. 커밋했으면 올라가 있어야 한다.
+#
+#      **네트워크에 의존하지 않는다.** 원격 조회가 실패했을 때 차단하면 오프라인에서
+#      세션이 벽돌이 되고, 통과시키면 정작 필요할 때 조용히 사라진다. 그래서 로컬
+#      remote-tracking ref 만 본다 — 그게 없으면 "한 번도 push 안 됨"이고, 있으면
+#      ahead 개수를 센다.
+#
+#      실측된 함정 하나: `remote.origin.fetch` 가 좁혀져 있으면 **원격에 있는데도**
+#      로컬 ref 가 없어 오탐이 난다. 그 경우를 구별해 사유에 적는다 — 그것도 고쳐야
+#      할 상태이기 때문이다(push 여부가 로컬에서 안 보이는 것 자체가 위험이다).
+if ! hook_disabled "stop:push" && git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
+  push_branch="$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)"
+  # detached HEAD 는 대상이 아니다(브랜치가 없으면 push 할 곳도 없다).
+  if [ -n "$push_branch" ] && git -C "$PROJECT_DIR" remote get-url origin >/dev/null 2>&1; then
+    push_unsent=""
+    if git -C "$PROJECT_DIR" rev-parse --verify -q "refs/remotes/origin/$push_branch" >/dev/null 2>&1; then
+      push_n="$(git -C "$PROJECT_DIR" rev-list --count "refs/remotes/origin/$push_branch..HEAD" 2>/dev/null)"
+      [ -n "$push_n" ] && [ "$push_n" != "0" ] && push_unsent="원격보다 ${push_n}개 앞서 있습니다"
+    else
+      # 원격 추적 ref 가 없다. 진짜 미push 이거나, refspec 이 좁혀져 안 보이는 것이다.
+      if git -C "$PROJECT_DIR" rev-parse --verify -q HEAD >/dev/null 2>&1; then
+        push_unsent="이 브랜치의 원격 추적 ref 가 없습니다 (한 번도 push 되지 않았거나, refspec 이 좁혀져 보이지 않습니다)"
+      fi
+    fi
+    if [ -n "$push_unsent" ]; then
+      gate_budget "push"
+      {
+        echo "[완료 차단] 커밋이 원격에 없습니다 — $push_unsent"
+        echo
+        echo "이 저장소는 이 상태로 **커밋 29개를 잃은 적이 있습니다.** 그때도 코드는"
+        echo "다 짜여 있었고, \"아직 PR 전이니까\"라며 push 를 미뤘습니다."
+        echo
+        echo "해야 할 일:"
+        echo "  git push -u origin $push_branch"
+        echo "  그리고 실제로 올라갔는지 확인하세요:"
+        echo "  git rev-list --left-right --count HEAD...origin/$push_branch   → 0 0"
+        echo
+        echo "  원격에는 있는데 위 명령이 실패한다면 refspec 이 좁혀진 것입니다:"
+        echo "  git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git fetch origin"
+        echo "  push 여부가 로컬에서 안 보이는 것 자체가 위험합니다 — 29개를 잃을 때 그랬습니다."
+        echo
+        echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:push"
+      } >&2
+      bump_and_block
+    fi
+  fi
+fi
+
 # (6) 타입체크는 통과했지만 감사자가 아직 안 돌았다.
 gate_budget "audit"
 {
diff --git a/template/.claude/settings.json b/template/.claude/settings.json
index f92dbd3..1396043 100644
--- a/template/.claude/settings.json
+++ b/template/.claude/settings.json
@@ -13,6 +13,11 @@
             "type": "command",
             "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-codex-invocation.sh\"",
             "timeout": 15
+          },
+          {
+            "type": "command",
+            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-hook-disable.sh\"",
+            "timeout": 15
           }
         ]
       }
@@ -41,4 +46,4 @@
       }
     ]
   }
-}
\ No newline at end of file
+}
diff --git a/tests/self-discipline-gates.test.sh b/tests/self-discipline-gates.test.sh
new file mode 100755
index 0000000..a282938
--- /dev/null
+++ b/tests/self-discipline-gates.test.sh
@@ -0,0 +1,159 @@
+#!/usr/bin/env bash
+# self-discipline-gates.test.sh — 에이전트가 자기 규율을 우회하는 것을 막는 두 게이트.
+#
+#   guard-hook-disable  — 게이트를 끄는 환경변수 대입을 차단한다
+#   stop:push           — 커밋했는데 원격에 없으면 턴을 못 끝낸다
+#
+# 둘 다 **조용한 실패**를 막는 장치라 위음성이 유일한 치명 결함이다. 통과시키는 순간
+# 규율은 다시 산문으로 돌아가고, 산문은 어겨져도 아무것도 안 깨진다.
+#
+# guard-hook-disable 에는 **환경변수 탈출구가 없다.** 그 사실 자체를 케이스로 붙든다 —
+# 탈출구가 생기면 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다.
+#
+# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
+# 셸 이식성: macOS 기본 bash 는 3.2 다.
+
+set -uo pipefail
+
+TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
+REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
+HOOKS="$REPO_ROOT/template/.claude/hooks"
+
+command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (json_get 의존)" >&2; exit 1; }
+command -v git     >/dev/null 2>&1 || { echo "✗ git 이 필요합니다 (push 게이트 픽스처)" >&2; exit 1; }
+for f in guard-hook-disable.sh verify-before-stop.sh _common.sh; do
+  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
+done
+
+TMPROOT="$(mktemp -d)" || exit 1
+if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
+  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
+fi
+TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
+trap 'rm -rf "$TMPROOT"' EXIT
+
+ran=0; pass=0; fail=0
+RC=999; ERR=''; DID_RUN=0
+
+report() {
+  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
+  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
+}
+
+# --- guard-hook-disable ---------------------------------------------------
+
+run_guard() {   # $1=명령문자열  [env 인자...]
+  local cmd="$1" errf="$TMPROOT/gerr.$$"
+  shift
+  RC=999; ERR=''; DID_RUN=1
+  python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd" \
+    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$TMPROOT" \
+          bash "$HOOKS/guard-hook-disable.sh" >/dev/null 2>"$errf"
+  RC=$?
+  ERR="$(cat "$errf" 2>/dev/null)"
+  rm -f "$errf"
+}
+
+gcase() {   # $1=이름 $2=명령 $3=기대rc [env 인자...]
+  local name="$1" cmd="$2" want="$3" why=''
+  shift 3
+  run_guard "$cmd" ${@+"$@"}
+  if [ "$DID_RUN" -ne 1 ]; then why='훅을 실행하지 않았다'
+  elif [ "$RC" -ne "$want" ]; then why="rc=$RC (기대 $want) / $(printf '%s' "$ERR" | head -c 120)"
+  elif [ "$want" -eq 2 ]; then
+    case "$ERR" in
+      *'사용자에게 물으세요'*) ;;
+      *) why="차단은 했으나 '물어라'를 안 냈다: $(printf '%s' "$ERR" | head -c 120)" ;;
+    esac
+  elif [ -n "$ERR" ]; then why="통과인데 stderr 가 있다: $(printf '%s' "$ERR" | head -c 120)"

exec
/bin/zsh -lc "sed -n '120,360p' _workspace/06_gates.diff && nl -ba template/.claude/hooks/guard-hook-disable.sh && nl -ba template/.claude/hooks/verify-before-stop.sh && nl -ba tests/self-discipline-gates.test.sh" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
+#      실측된 함정 하나: `remote.origin.fetch` 가 좁혀져 있으면 **원격에 있는데도**
+#      로컬 ref 가 없어 오탐이 난다. 그 경우를 구별해 사유에 적는다 — 그것도 고쳐야
+#      할 상태이기 때문이다(push 여부가 로컬에서 안 보이는 것 자체가 위험이다).
+if ! hook_disabled "stop:push" && git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
+  push_branch="$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)"
+  # detached HEAD 는 대상이 아니다(브랜치가 없으면 push 할 곳도 없다).
+  if [ -n "$push_branch" ] && git -C "$PROJECT_DIR" remote get-url origin >/dev/null 2>&1; then
+    push_unsent=""
+    if git -C "$PROJECT_DIR" rev-parse --verify -q "refs/remotes/origin/$push_branch" >/dev/null 2>&1; then
+      push_n="$(git -C "$PROJECT_DIR" rev-list --count "refs/remotes/origin/$push_branch..HEAD" 2>/dev/null)"
+      [ -n "$push_n" ] && [ "$push_n" != "0" ] && push_unsent="원격보다 ${push_n}개 앞서 있습니다"
+    else
+      # 원격 추적 ref 가 없다. 진짜 미push 이거나, refspec 이 좁혀져 안 보이는 것이다.
+      if git -C "$PROJECT_DIR" rev-parse --verify -q HEAD >/dev/null 2>&1; then
+        push_unsent="이 브랜치의 원격 추적 ref 가 없습니다 (한 번도 push 되지 않았거나, refspec 이 좁혀져 보이지 않습니다)"
+      fi
+    fi
+    if [ -n "$push_unsent" ]; then
+      gate_budget "push"
+      {
+        echo "[완료 차단] 커밋이 원격에 없습니다 — $push_unsent"
+        echo
+        echo "이 저장소는 이 상태로 **커밋 29개를 잃은 적이 있습니다.** 그때도 코드는"
+        echo "다 짜여 있었고, \"아직 PR 전이니까\"라며 push 를 미뤘습니다."
+        echo
+        echo "해야 할 일:"
+        echo "  git push -u origin $push_branch"
+        echo "  그리고 실제로 올라갔는지 확인하세요:"
+        echo "  git rev-list --left-right --count HEAD...origin/$push_branch   → 0 0"
+        echo
+        echo "  원격에는 있는데 위 명령이 실패한다면 refspec 이 좁혀진 것입니다:"
+        echo "  git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git fetch origin"
+        echo "  push 여부가 로컬에서 안 보이는 것 자체가 위험합니다 — 29개를 잃을 때 그랬습니다."
+        echo
+        echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:push"
+      } >&2
+      bump_and_block
+    fi
+  fi
+fi
+
 # (6) 타입체크는 통과했지만 감사자가 아직 안 돌았다.
 gate_budget "audit"
 {
diff --git a/template/.claude/settings.json b/template/.claude/settings.json
index f92dbd3..1396043 100644
--- a/template/.claude/settings.json
+++ b/template/.claude/settings.json
@@ -13,6 +13,11 @@
             "type": "command",
             "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-codex-invocation.sh\"",
             "timeout": 15
+          },
+          {
+            "type": "command",
+            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-hook-disable.sh\"",
+            "timeout": 15
           }
         ]
       }
@@ -41,4 +46,4 @@
       }
     ]
   }
-}
\ No newline at end of file
+}
diff --git a/tests/self-discipline-gates.test.sh b/tests/self-discipline-gates.test.sh
new file mode 100755
index 0000000..a282938
--- /dev/null
+++ b/tests/self-discipline-gates.test.sh
@@ -0,0 +1,159 @@
+#!/usr/bin/env bash
+# self-discipline-gates.test.sh — 에이전트가 자기 규율을 우회하는 것을 막는 두 게이트.
+#
+#   guard-hook-disable  — 게이트를 끄는 환경변수 대입을 차단한다
+#   stop:push           — 커밋했는데 원격에 없으면 턴을 못 끝낸다
+#
+# 둘 다 **조용한 실패**를 막는 장치라 위음성이 유일한 치명 결함이다. 통과시키는 순간
+# 규율은 다시 산문으로 돌아가고, 산문은 어겨져도 아무것도 안 깨진다.
+#
+# guard-hook-disable 에는 **환경변수 탈출구가 없다.** 그 사실 자체를 케이스로 붙든다 —
+# 탈출구가 생기면 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다.
+#
+# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
+# 셸 이식성: macOS 기본 bash 는 3.2 다.
+
+set -uo pipefail
+
+TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
+REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
+HOOKS="$REPO_ROOT/template/.claude/hooks"
+
+command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (json_get 의존)" >&2; exit 1; }
+command -v git     >/dev/null 2>&1 || { echo "✗ git 이 필요합니다 (push 게이트 픽스처)" >&2; exit 1; }
+for f in guard-hook-disable.sh verify-before-stop.sh _common.sh; do
+  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
+done
+
+TMPROOT="$(mktemp -d)" || exit 1
+if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
+  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
+fi
+TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
+trap 'rm -rf "$TMPROOT"' EXIT
+
+ran=0; pass=0; fail=0
+RC=999; ERR=''; DID_RUN=0
+
+report() {
+  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
+  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
+}
+
+# --- guard-hook-disable ---------------------------------------------------
+
+run_guard() {   # $1=명령문자열  [env 인자...]
+  local cmd="$1" errf="$TMPROOT/gerr.$$"
+  shift
+  RC=999; ERR=''; DID_RUN=1
+  python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd" \
+    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$TMPROOT" \
+          bash "$HOOKS/guard-hook-disable.sh" >/dev/null 2>"$errf"
+  RC=$?
+  ERR="$(cat "$errf" 2>/dev/null)"
+  rm -f "$errf"
+}
+
+gcase() {   # $1=이름 $2=명령 $3=기대rc [env 인자...]
+  local name="$1" cmd="$2" want="$3" why=''
+  shift 3
+  run_guard "$cmd" ${@+"$@"}
+  if [ "$DID_RUN" -ne 1 ]; then why='훅을 실행하지 않았다'
+  elif [ "$RC" -ne "$want" ]; then why="rc=$RC (기대 $want) / $(printf '%s' "$ERR" | head -c 120)"
+  elif [ "$want" -eq 2 ]; then
+    case "$ERR" in
+      *'사용자에게 물으세요'*) ;;
+      *) why="차단은 했으나 '물어라'를 안 냈다: $(printf '%s' "$ERR" | head -c 120)" ;;
+    esac
+  elif [ -n "$ERR" ]; then why="통과인데 stderr 가 있다: $(printf '%s' "$ERR" | head -c 120)"
+  fi
+  report "$name" "$why"
+}
+
+g01() { gcase '전체 비활성 대입을 막는다'         'HARNESS_HOOKS=off claude'                 2; }
+g02() { gcase '개별 비활성 대입을 막는다'         'ECC_DISABLED_HOOKS=stop:knowledge x'      2; }
+g03() { gcase 'GateGuard 끄기를 막는다'           'ECC_GATEGUARD=off ./run.sh'               2; }
+g04() { gcase 'export 형태도 막는다'              'export HARNESS_HOOKS=off'                 2; }
+# **읽기는 정상 작업이다.** 값 확인·문서 검색까지 막으면 위양성으로 죽는다.
+g05() { gcase '값을 읽는 것은 막지 않는다'        'echo "$HARNESS_HOOKS"'                    0; }
+g06() { gcase '이름만 언급하는 것은 막지 않는다'  'grep -n ECC_DISABLED_HOOKS docs/usage.md' 0; }
+g07() { gcase '접두사가 다른 변수는 막지 않는다'  'MY_ECC_GATEGUARD=1 ./x.sh'                0; }
+# **이 훅에는 탈출구가 없다.** 있으면 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있다.
+g08() { gcase '탈출구로 이 훅 자신을 끌 수 없다'   'HARNESS_HOOKS=off claude'                2 HARNESS_HOOKS=off; }
+g09() { gcase '개별 비활성으로도 이 훅을 못 끈다'  'ECC_GATEGUARD=off x'                     2 ECC_DISABLED_HOOKS=pre:bash:hook-disable; }
+
+# --- stop:push ------------------------------------------------------------
+
+new_repo() {   # $1 = yes | no | noremote
+  local pushed="$1" p
+  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
+  p="$(CDPATH='' cd -- "$p" && pwd -P)"
+  mkdir -p "$p/.claude/hooks" "$p/.claude/harness"
+  cp "$HOOKS/_common.sh" "$HOOKS/verify-before-stop.sh" "$p/.claude/hooks/"
+  git -C "$p" init -q -b work 2>/dev/null || { git -C "$p" init -q; git -C "$p" checkout -q -b work; }
+  printf 'x\n' > "$p/f.txt"
+  git -C "$p" add -A
+  git -C "$p" -c user.email=t@t -c user.name=t commit -q -m c1
+  if [ "$pushed" != 'noremote' ]; then
+    git init -q --bare "$p.git"
+    git -C "$p" remote add origin "$p.git"
+    [ "$pushed" = 'yes' ] && git -C "$p" push -q -u origin work
+  fi
+  printf 'gate-target.ts\n' > "$p/.claude/.needs-audit"
+  printf '%s\n' "$p"
+}
+
+run_stop() {   # $1=proj
+  local proj="$1" errf="$TMPROOT/serr.$$"
+  RC=999; ERR=''; DID_RUN=1
+  printf '{"stop_hook_active": false}' \
+    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
+          bash "$proj/.claude/hooks/verify-before-stop.sh" >/dev/null 2>"$errf"
+  RC=$?
+  ERR="$(cat "$errf" 2>/dev/null)"
+  rm -f "$errf"
+}
+
+pcase() {   # $1=이름 $2=yes|no|noremote $3=있어야 할 문구 $4=있으면 안 되는 문구|-
+  local name="$1" kind="$2" want="$3" forbid="$4" p why=''
+  if ! p="$(new_repo "$kind")"; then report "$name" '픽스처 실패'; return 0; fi
+  run_stop "$p"
+  if [ "$RC" -ne 2 ]; then
+    why="rc=$RC (기대 2 — 감사 플래그가 서 있으므로 어느 게이트든 막아야 한다)"
+  else
+    case "$ERR" in *"$want"*) ;; *) why="기대 문구 없음: $want / 실제 [$(printf '%s' "$ERR" | head -c 140)]" ;; esac
+    if [ -z "$why" ] && [ "$forbid" != '-' ]; then
+      case "$ERR" in *"$forbid"*) why="있으면 안 되는 문구: $forbid" ;; esac
+    fi
+  fi
+  report "$name" "$why"
+}
+
+# 미push 면 push 게이트가 감사 게이트보다 **먼저** 막아야 한다 — 커밋이 사라지는 것이
+# 감사 누락보다 비싸다.
+p01() { pcase '미push 커밋이 있으면 막는다'              no       '커밋이 원격에 없습니다'     'completion-auditor 미실행'; }
+p02() { pcase '원격 추적 ref 가 없으면 사유를 밝힌다'    no       '원격 추적 ref 가 없습니다'  '-'; }
+p03() { pcase 'push 됐으면 push 게이트는 통과한다'       yes      'completion-auditor 미실행'  '커밋이 원격에 없습니다'; }
+# origin 이 없는 저장소에서 push 를 요구하면 세션이 벽돌이 된다.
+p04() { pcase 'origin 이 없으면 push 를 요구하지 않는다'  noremote 'completion-auditor 미실행'  '커밋이 원격에 없습니다'; }
+
+# --- 러너 ----------------------------------------------------------------
+
+CASES='g01 g02 g03 g04 g05 g06 g07 g08 g09 p01 p02 p03 p04'
+EXPECTED_CASES=13
+
+case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
+case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
+if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
+  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
+  exit 1
+fi
+
+echo "자기 규율 게이트 — 무력화 차단 + push 미완 차단"
+for c in $CASES; do ran=$((ran + 1)); DID_RUN=0; "$c"; done
+
+if [ "$ran" -ne "$EXPECTED_CASES" ]; then echo "✗ 실행 ${ran}건 ≠ ${EXPECTED_CASES}건" >&2; exit 1; fi
+if [ $((pass + fail)) -ne "$ran" ]; then echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1; fi
+
+echo "— ${pass}/${ran} 통과"
+[ "$fail" -eq 0 ] || exit 1
     1	#!/usr/bin/env bash
     2	# PreToolUse(Bash): **에이전트가 게이트를 스스로 끄는 것**을 차단한다.
     3	#
     4	# 왜: 이 하네스의 모든 게이트에는 탈출구가 있다(HARNESS_HOOKS=off · ECC_DISABLED_HOOKS ·
     5	# ECC_GATEGUARD). 탈출구는 **사용자를 위한 것**이지 막힌 에이전트를 위한 것이 아니다.
     6	# 그런데 지금까지 그 구분은 산문으로만 존재했다 — "제 판단으로 끄지 않겠습니다"라고
     7	# 말하는 것 말고는 아무것도 막지 않았다. 이 저장소가 반복해서 배운 것이 정확히
     8	# **산문 규칙은 어겨지고, 어겨져도 조용하다**는 것이다.
     9	#
    10	# 게이트가 성가실 때 끄고 싶어지는 순간이 바로 게이트가 일하는 순간이다. 그 순간의
    11	# 판단을 에이전트에게 맡기면 게이트는 있으나 마나다.
    12	#
    13	# **읽는 것은 막지 않는다.** 값을 확인하거나(`echo "$HARNESS_HOOKS"`) 문서에 적는 것은
    14	# 정상 작업이다. 막는 것은 **대입**뿐이다.
    15	#
    16	# 탈출구: 이 훅에는 환경변수 탈출구가 **없다.** 있으면 그 탈출구로 이 훅을 끄고
    17	# 나머지를 전부 끌 수 있어 존재 이유가 사라진다. guard-codex-invocation 과 같은 처리다.
    18	# 사용자가 정말 끄려면 셸에서 직접 export 하고 세션을 새로 띄우거나 settings.json 에서
    19	# 이 훅 배선을 지운다 — 둘 다 사람이 하는 행위다.
    20	#
    21	# 셸 이식성: macOS 기본 bash 는 3.2 다.
    22	
    23	set -uo pipefail
    24	# shellcheck source=_common.sh
    25	. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
    26	
    27	payload="$(cat)"
    28	cmd="$(printf '%s' "$payload" | json_get tool_input.command)"
    29	[ -z "$cmd" ] && exit 0
    30	
    31	# 감시 대상 = 게이트를 끄는 스위치들.
    32	# 값까지 보지 않는다 — `ECC_DISABLED_HOOKS=stop:knowledge` 처럼 **하나만** 끄는 것도
    33	# 에이전트가 정할 일이 아니다. 무엇을 끌지는 사용자가 정한다.
    34	#
    35	# `이름=` 형태의 **대입**만 잡는다. 앞 문자가 영숫자·밑줄·`$` 가 아니어야 하므로
    36	# `$ECC_DISABLED_HOOKS` 같은 참조나 `MY_ECC_GATEGUARD=` 같은 다른 이름은 안 걸린다.
    37	matched="$(printf '%s' "$cmd" \
    38	  | grep -oE '(^|[^A-Za-z0-9_$])(HARNESS_HOOKS|ECC_DISABLED_HOOKS|ECC_GATEGUARD)=' \
    39	  | grep -oE '(HARNESS_HOOKS|ECC_DISABLED_HOOKS|ECC_GATEGUARD)' \
    40	  | sort -u | tr '\n' ' ')"
    41	[ -z "$matched" ] && exit 0
    42	
    43	{
    44	  echo "[차단] 게이트를 끄려 하고 있습니다: ${matched% }"
    45	  echo
    46	  echo "이 탈출구는 **사용자를 위한 것**이지 막힌 에이전트를 위한 것이 아닙니다."
    47	  echo "게이트가 성가신 순간이 게이트가 일하는 순간입니다."
    48	  echo
    49	  echo "해야 할 일: 끄지 말고 **사용자에게 물으세요.**"
    50	  echo "  - 무엇이 막혔는지"
    51	  echo "  - 왜 그 게이트를 끄는 것이 옳다고 보는지"
    52	  echo "  - 끄지 않고 갈 수 있는 길은 없는지"
    53	  echo
    54	  echo "사용자가 끄기로 하면 사용자가 직접 셸에서 export 하거나 settings.json 배선을"
    55	  echo "지웁니다. 이 훅에는 환경변수 탈출구가 없습니다 — 있으면 그것으로 나머지를 전부"
    56	  echo "끌 수 있어 존재 이유가 사라집니다."
    57	} >&2
    58	exit 2
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
   181	#     나온 턴은 반영 없이 끝낼 수 없다." 저장소가 어디인지·어떤 구조인지·무엇을 어느
   182	#     파일에 나눠 담는지는 **상위 층의 구현**이고 이 파일은 모른다. 알게 되면 그 저장소를
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
   210	# (5.5) **커밋했는데 원격에 없다** — 이 저장소가 커밋 29개를 잃은 바로 그 상태다.
   211	#      그때는 "아직 PR 전이니까"라며 라운드 6개를 미뤘고, 임시 폴더째 사라졌다.
   212	#      검수 통과는 push 의 전제가 아니다. 커밋했으면 올라가 있어야 한다.
   213	#
   214	#      **네트워크에 의존하지 않는다.** 원격 조회가 실패했을 때 차단하면 오프라인에서
   215	#      세션이 벽돌이 되고, 통과시키면 정작 필요할 때 조용히 사라진다. 그래서 로컬
   216	#      remote-tracking ref 만 본다 — 그게 없으면 "한 번도 push 안 됨"이고, 있으면
   217	#      ahead 개수를 센다.
   218	#
   219	#      실측된 함정 하나: `remote.origin.fetch` 가 좁혀져 있으면 **원격에 있는데도**
   220	#      로컬 ref 가 없어 오탐이 난다. 그 경우를 구별해 사유에 적는다 — 그것도 고쳐야
   221	#      할 상태이기 때문이다(push 여부가 로컬에서 안 보이는 것 자체가 위험이다).
   222	if ! hook_disabled "stop:push" && git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
   223	  push_branch="$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)"
   224	  # detached HEAD 는 대상이 아니다(브랜치가 없으면 push 할 곳도 없다).
   225	  if [ -n "$push_branch" ] && git -C "$PROJECT_DIR" remote get-url origin >/dev/null 2>&1; then
   226	    push_unsent=""
   227	    if git -C "$PROJECT_DIR" rev-parse --verify -q "refs/remotes/origin/$push_branch" >/dev/null 2>&1; then
   228	      push_n="$(git -C "$PROJECT_DIR" rev-list --count "refs/remotes/origin/$push_branch..HEAD" 2>/dev/null)"
   229	      [ -n "$push_n" ] && [ "$push_n" != "0" ] && push_unsent="원격보다 ${push_n}개 앞서 있습니다"
   230	    else
   231	      # 원격 추적 ref 가 없다. 진짜 미push 이거나, refspec 이 좁혀져 안 보이는 것이다.
   232	      if git -C "$PROJECT_DIR" rev-parse --verify -q HEAD >/dev/null 2>&1; then
   233	        push_unsent="이 브랜치의 원격 추적 ref 가 없습니다 (한 번도 push 되지 않았거나, refspec 이 좁혀져 보이지 않습니다)"
   234	      fi
   235	    fi
   236	    if [ -n "$push_unsent" ]; then
   237	      gate_budget "push"
   238	      {
   239	        echo "[완료 차단] 커밋이 원격에 없습니다 — $push_unsent"
   240	        echo
   241	        echo "이 저장소는 이 상태로 **커밋 29개를 잃은 적이 있습니다.** 그때도 코드는"
   242	        echo "다 짜여 있었고, \"아직 PR 전이니까\"라며 push 를 미뤘습니다."
   243	        echo
   244	        echo "해야 할 일:"
   245	        echo "  git push -u origin $push_branch"
   246	        echo "  그리고 실제로 올라갔는지 확인하세요:"
   247	        echo "  git rev-list --left-right --count HEAD...origin/$push_branch   → 0 0"
   248	        echo
   249	        echo "  원격에는 있는데 위 명령이 실패한다면 refspec 이 좁혀진 것입니다:"
   250	        echo "  git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' && git fetch origin"
   251	        echo "  push 여부가 로컬에서 안 보이는 것 자체가 위험합니다 — 29개를 잃을 때 그랬습니다."
   252	        echo
   253	        echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:push"
   254	      } >&2
   255	      bump_and_block
   256	    fi
   257	  fi
   258	fi
   259	
   260	# (6) 타입체크는 통과했지만 감사자가 아직 안 돌았다.
   261	gate_budget "audit"
   262	{
   263	  echo "[완료 차단] completion-auditor 미실행 — '완료'라고 말할 수 없습니다."
   264	  echo
   265	  echo "이 턴에서 바뀐 코드/설정:"
   266	  sed 's/^/  - /' "$AUDIT_FLAG" 2>/dev/null
   267	  if [ -n "$typecheck_note" ]; then
   268	    echo
   269	    echo "참고: $typecheck_note"
   270	  fi
   271	  echo
   272	  echo "해야 할 일:"
   273	  echo "  1. completion-auditor 에이전트로 완료 주장을 1차 증거로 검증한다."
   274	  echo "  2. 검증을 통과했을 때만:  rm -f .claude/.needs-audit"
   275	  echo "     감사 없이 플래그만 지우는 것은 이 게이트의 존재 이유를 없앤다."
   276	  echo
   277	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
   278	} >&2
   279	bump_and_block
     1	#!/usr/bin/env bash
     2	# self-discipline-gates.test.sh — 에이전트가 자기 규율을 우회하는 것을 막는 두 게이트.
     3	#
     4	#   guard-hook-disable  — 게이트를 끄는 환경변수 대입을 차단한다
     5	#   stop:push           — 커밋했는데 원격에 없으면 턴을 못 끝낸다
     6	#
     7	# 둘 다 **조용한 실패**를 막는 장치라 위음성이 유일한 치명 결함이다. 통과시키는 순간
     8	# 규율은 다시 산문으로 돌아가고, 산문은 어겨져도 아무것도 안 깨진다.
     9	#
    10	# guard-hook-disable 에는 **환경변수 탈출구가 없다.** 그 사실 자체를 케이스로 붙든다 —
    11	# 탈출구가 생기면 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다.
    12	#
    13	# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
    14	# 셸 이식성: macOS 기본 bash 는 3.2 다.
    15	
    16	set -uo pipefail
    17	
    18	TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    19	REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
    20	HOOKS="$REPO_ROOT/template/.claude/hooks"
    21	
    22	command -v python3 >/dev/null 2>&1 || { echo "✗ python3 이 필요합니다 (json_get 의존)" >&2; exit 1; }
    23	command -v git     >/dev/null 2>&1 || { echo "✗ git 이 필요합니다 (push 게이트 픽스처)" >&2; exit 1; }
    24	for f in guard-hook-disable.sh verify-before-stop.sh _common.sh; do
    25	  [ -f "$HOOKS/$f" ] || { echo "✗ 훅을 찾지 못했습니다: $f" >&2; exit 1; }
    26	done
    27	
    28	TMPROOT="$(mktemp -d)" || exit 1
    29	if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
    30	  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
    31	fi
    32	TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
    33	trap 'rm -rf "$TMPROOT"' EXIT
    34	
    35	ran=0; pass=0; fail=0
    36	RC=999; ERR=''; DID_RUN=0
    37	
    38	report() {
    39	  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
    40	  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
    41	}
    42	
    43	# --- guard-hook-disable ---------------------------------------------------
    44	
    45	run_guard() {   # $1=명령문자열  [env 인자...]
    46	  local cmd="$1" errf="$TMPROOT/gerr.$$"
    47	  shift
    48	  RC=999; ERR=''; DID_RUN=1
    49	  python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$cmd" \
    50	    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$TMPROOT" \
    51	          bash "$HOOKS/guard-hook-disable.sh" >/dev/null 2>"$errf"
    52	  RC=$?
    53	  ERR="$(cat "$errf" 2>/dev/null)"
    54	  rm -f "$errf"
    55	}
    56	
    57	gcase() {   # $1=이름 $2=명령 $3=기대rc [env 인자...]
    58	  local name="$1" cmd="$2" want="$3" why=''
    59	  shift 3
    60	  run_guard "$cmd" ${@+"$@"}
    61	  if [ "$DID_RUN" -ne 1 ]; then why='훅을 실행하지 않았다'
    62	  elif [ "$RC" -ne "$want" ]; then why="rc=$RC (기대 $want) / $(printf '%s' "$ERR" | head -c 120)"
    63	  elif [ "$want" -eq 2 ]; then
    64	    case "$ERR" in
    65	      *'사용자에게 물으세요'*) ;;
    66	      *) why="차단은 했으나 '물어라'를 안 냈다: $(printf '%s' "$ERR" | head -c 120)" ;;
    67	    esac
    68	  elif [ -n "$ERR" ]; then why="통과인데 stderr 가 있다: $(printf '%s' "$ERR" | head -c 120)"
    69	  fi
    70	  report "$name" "$why"
    71	}
    72	
    73	g01() { gcase '전체 비활성 대입을 막는다'         'HARNESS_HOOKS=off claude'                 2; }
    74	g02() { gcase '개별 비활성 대입을 막는다'         'ECC_DISABLED_HOOKS=stop:knowledge x'      2; }
    75	g03() { gcase 'GateGuard 끄기를 막는다'           'ECC_GATEGUARD=off ./run.sh'               2; }
    76	g04() { gcase 'export 형태도 막는다'              'export HARNESS_HOOKS=off'                 2; }
    77	# **읽기는 정상 작업이다.** 값 확인·문서 검색까지 막으면 위양성으로 죽는다.
    78	g05() { gcase '값을 읽는 것은 막지 않는다'        'echo "$HARNESS_HOOKS"'                    0; }
    79	g06() { gcase '이름만 언급하는 것은 막지 않는다'  'grep -n ECC_DISABLED_HOOKS docs/usage.md' 0; }
    80	g07() { gcase '접두사가 다른 변수는 막지 않는다'  'MY_ECC_GATEGUARD=1 ./x.sh'                0; }
    81	# **이 훅에는 탈출구가 없다.** 있으면 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있다.
    82	g08() { gcase '탈출구로 이 훅 자신을 끌 수 없다'   'HARNESS_HOOKS=off claude'                2 HARNESS_HOOKS=off; }
    83	g09() { gcase '개별 비활성으로도 이 훅을 못 끈다'  'ECC_GATEGUARD=off x'                     2 ECC_DISABLED_HOOKS=pre:bash:hook-disable; }
    84	
    85	# --- stop:push ------------------------------------------------------------
    86	
    87	new_repo() {   # $1 = yes | no | noremote
    88	  local pushed="$1" p
    89	  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
    90	  p="$(CDPATH='' cd -- "$p" && pwd -P)"
    91	  mkdir -p "$p/.claude/hooks" "$p/.claude/harness"
    92	  cp "$HOOKS/_common.sh" "$HOOKS/verify-before-stop.sh" "$p/.claude/hooks/"
    93	  git -C "$p" init -q -b work 2>/dev/null || { git -C "$p" init -q; git -C "$p" checkout -q -b work; }
    94	  printf 'x\n' > "$p/f.txt"
    95	  git -C "$p" add -A
    96	  git -C "$p" -c user.email=t@t -c user.name=t commit -q -m c1
    97	  if [ "$pushed" != 'noremote' ]; then
    98	    git init -q --bare "$p.git"
    99	    git -C "$p" remote add origin "$p.git"
   100	    [ "$pushed" = 'yes' ] && git -C "$p" push -q -u origin work
   101	  fi
   102	  printf 'gate-target.ts\n' > "$p/.claude/.needs-audit"
   103	  printf '%s\n' "$p"
   104	}
   105	
   106	run_stop() {   # $1=proj
   107	  local proj="$1" errf="$TMPROOT/serr.$$"
   108	  RC=999; ERR=''; DID_RUN=1
   109	  printf '{"stop_hook_active": false}' \
   110	    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
   111	          bash "$proj/.claude/hooks/verify-before-stop.sh" >/dev/null 2>"$errf"
   112	  RC=$?
   113	  ERR="$(cat "$errf" 2>/dev/null)"
   114	  rm -f "$errf"
   115	}
   116	
   117	pcase() {   # $1=이름 $2=yes|no|noremote $3=있어야 할 문구 $4=있으면 안 되는 문구|-
   118	  local name="$1" kind="$2" want="$3" forbid="$4" p why=''
   119	  if ! p="$(new_repo "$kind")"; then report "$name" '픽스처 실패'; return 0; fi
   120	  run_stop "$p"
   121	  if [ "$RC" -ne 2 ]; then
   122	    why="rc=$RC (기대 2 — 감사 플래그가 서 있으므로 어느 게이트든 막아야 한다)"
   123	  else
   124	    case "$ERR" in *"$want"*) ;; *) why="기대 문구 없음: $want / 실제 [$(printf '%s' "$ERR" | head -c 140)]" ;; esac
   125	    if [ -z "$why" ] && [ "$forbid" != '-' ]; then
   126	      case "$ERR" in *"$forbid"*) why="있으면 안 되는 문구: $forbid" ;; esac
   127	    fi
   128	  fi
   129	  report "$name" "$why"
   130	}
   131	
   132	# 미push 면 push 게이트가 감사 게이트보다 **먼저** 막아야 한다 — 커밋이 사라지는 것이
   133	# 감사 누락보다 비싸다.
   134	p01() { pcase '미push 커밋이 있으면 막는다'              no       '커밋이 원격에 없습니다'     'completion-auditor 미실행'; }
   135	p02() { pcase '원격 추적 ref 가 없으면 사유를 밝힌다'    no       '원격 추적 ref 가 없습니다'  '-'; }
   136	p03() { pcase 'push 됐으면 push 게이트는 통과한다'       yes      'completion-auditor 미실행'  '커밋이 원격에 없습니다'; }
   137	# origin 이 없는 저장소에서 push 를 요구하면 세션이 벽돌이 된다.
   138	p04() { pcase 'origin 이 없으면 push 를 요구하지 않는다'  noremote 'completion-auditor 미실행'  '커밋이 원격에 없습니다'; }
   139	
   140	# --- 러너 ----------------------------------------------------------------
   141	
   142	CASES='g01 g02 g03 g04 g05 g06 g07 g08 g09 p01 p02 p03 p04'
   143	EXPECTED_CASES=13
   144	
   145	case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
   146	case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
   147	if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
   148	  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
   149	  exit 1
   150	fi
   151	
   152	echo "자기 규율 게이트 — 무력화 차단 + push 미완 차단"
   153	for c in $CASES; do ran=$((ran + 1)); DID_RUN=0; "$c"; done
   154	
   155	if [ "$ran" -ne "$EXPECTED_CASES" ]; then echo "✗ 실행 ${ran}건 ≠ ${EXPECTED_CASES}건" >&2; exit 1; fi
   156	if [ $((pass + fail)) -ne "$ran" ]; then echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1; fi
   157	
   158	echo "— ${pass}/${ran} 통과"
   159	[ "$fail" -eq 0 ] || exit 1

codex
첫 독해에서 핵심 위험은 두 축입니다. 새 Bash 훅은 셸 구문을 해석하지 않고 원문에서 정확한 `NAME=`만 찾으며, push 게이트는 현재 브랜치와 같은 이름의 `origin/*`만 비교합니다. 이 두 가정이 실제 우회와 정상 Git 구성에서 어떻게 깨지는지 주변 공통 함수와 설치 경로까지 대조하겠습니다.
exec
/bin/zsh -lc "nl -ba template/.claude/hooks/_common.sh && nl -ba template/.claude/settings.json && rg -n \"settings\\.json|guard-codex-invocation|PreToolUse|remote|upstream|BLOCK_FP|MAX_BLOCKS|symbolic-ref|rev-list\" scripts tests template docs .github --glob '"'!tests/self-discipline-gates.test.sh'"' --glob '"'!template/.claude/hooks/verify-before-stop.sh'"'" in /Users/kty/Downloads/kty-claude-harness-template
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
    16	          },
    17	          {
    18	            "type": "command",
    19	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/guard-hook-disable.sh\"",
    20	            "timeout": 15
    21	          }
    22	        ]
    23	      }
    24	    ],
    25	    "PostToolUse": [
    26	      {
    27	        "matcher": "Edit|Write|MultiEdit",
    28	        "hooks": [
    29	          {
    30	            "type": "command",
    31	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/mark-needs-audit.sh\"",
    32	            "timeout": 15
    33	          }
    34	        ]
    35	      }
    36	    ],
    37	    "Stop": [
    38	      {
    39	        "hooks": [
    40	          {
    41	            "type": "command",
    42	            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/verify-before-stop.sh\"",
    43	            "timeout": 120
    44	          }
    45	        ]
    46	      }
    47	    ]
    48	  }
    49	}
tests/mark-needs-audit.test.sh:105:  printf '{}\n'              > "$r/template/.claude/settings.json"
template/CLAUDE.md.snippet:11:**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 게이트 플래그 4종 / Stop 시 타입체크(프로필 3절)+codex 듀얼리뷰+change-explainer+지식 저장소 반영+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
docs/decisions/2026-08-06-knowledge-retrieval-policy.md:11:[ADR-0009](2026-08-06-profile-canon-upstream.md)가 **조회 방향을 배선**했다 — 프로필 9절 "지식 진입점" 슬롯, `ecc:architect`·`ecc:planner` 주입, 산출물 첫 줄의 `사전 결정 회수:`.
docs/decisions/2026-08-06-knowledge-retrieval-policy.md:70:- [ADR-0009](2026-08-06-profile-canon-upstream.md) — 이 ADR이 가리키는 배관
docs/usage.md:22:install이 하는 일: 글루 복사(자체 에이전트 8·스킬 2(harness-orchestrator·readable-writing)·훅 4·제0원칙) + 슬롯 스캐폴드(없을 때만) + settings.json 병합(기존 훅 보존·명령 단위 추가·백업) + CLAUDE.md 포인터 append.
docs/usage.md:65:| guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
docs/usage.md:72:**단 `guard-hook-disable` 은 예외다 — 환경변수로 끌 수 없다.** 그 탈출구가 있으면 에이전트가 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다. 사용자가 정말 끄려면 셸에서 직접 `export` 하고 세션을 새로 띄우거나 `settings.json` 배선을 지운다 — 둘 다 사람이 하는 행위다.
docs/usage.md:74:**push 게이트가 있는 이유:** 이 저장소는 커밋 29개를 잃은 적이 있다. 코드는 다 짜여 있었고 "아직 PR 전이니까"라며 push 를 미뤘다. 게이트는 **네트워크를 쓰지 않는다** — 로컬 remote-tracking ref 만 본다. 원격에 있는데도 ref 가 안 보이면(`remote.origin.fetch` 가 좁혀진 경우) 그 사실을 사유에 적는다. push 여부가 로컬에서 안 보이는 것 자체가 위험이기 때문이다. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
docs/usage.md:82:  `.claude/` 에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`), 그리고
docs/usage.md:85:- **프로젝트 밖 + 그 외** — `.claude/`에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`)만. **git 저장소가 아니어도** 발화한다.
docs/decisions/2026-08-06-knowledge-gate-default-on.md:132:- [ADR-0009](2026-08-06-profile-canon-upstream.md) — 프로필 정본과 조회 배선
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:118:- **조회 방향**: 이행 중에 프로필 정본 위치 문제가 갈라져 나와 [ADR-0009](2026-08-06-profile-canon-upstream.md) 가 됐고, 회수 **정책**은 미설계로 [ADR-0010](2026-08-06-knowledge-retrieval-policy.md) 에 못박았다
tests/mark-needs-audit.cases.sh:74:  mkfile "$p/.claude/settings.json"
tests/mark-needs-audit.cases.sh:75:  run_hook "$p" "$p/.claude/settings.json"
tests/mark-needs-audit.cases.sh:76:  check_case '07 설치된 글루 .claude/settings.json → 스킵' 0 none ''
tests/mark-needs-audit.cases.sh:104:            # 오기록(app/.claude/settings.json)이나 무기록이 된다.
tests/mark-needs-audit.cases.sh:106:  mkfile "$repo/app/.claude/settings.json"
tests/mark-needs-audit.cases.sh:107:  run_hook "$repo/link" "$repo/app/.claude/settings.json"
tests/mark-needs-audit.cases.sh:175:case_20() { # 앵커 settings.json — 확장자가 없는 앵커.
tests/mark-needs-audit.cases.sh:177:  mkfile "$hr/template/.claude/settings.json"
tests/mark-needs-audit.cases.sh:178:  run_hook "$p" "$hr/template/.claude/settings.json"
tests/mark-needs-audit.cases.sh:179:  check_case '20 밖+정본 template/.claude/settings.json → 게이트 4종' 0 gate "$hr/template/.claude/settings.json"
tests/mark-needs-audit.cases.sh:562:case_60() { # 앵커 settings.json — 이 앵커도 지워도 나머지 전 행이 초록이었다. git 저장소가
tests/mark-needs-audit.cases.sh:565:            # 떨어져 스킵된다. 놓치던 시나리오: 남의 프로젝트 .claude/settings.json 편집.
tests/mark-needs-audit.cases.sh:567:  mkfile "$nogit/.claude/settings.json"
tests/mark-needs-audit.cases.sh:568:  run_hook "$p" "$nogit/.claude/settings.json"
tests/mark-needs-audit.cases.sh:569:  check_case '60 밖+git 아님 .claude/settings.json → 게이트 4종(절대경로)' 0 gate "$nogit/.claude/settings.json"

exec
/bin/zsh -lc "rg -n \"hooks/|HOOK|guard-master|verify-before|cp .*hook|settings\" install.sh scripts tests/install* template --glob '*.sh' --glob '*.py' --glob '*.json' --glob '*.md' && nl -ba install.sh | sed -n '1,280p' && git diff --check 9079ac1 HEAD" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
tests/install-hook-swap.test.sh:5:# 디렉터리 **안으로** 중첩되어 훅이 hooks/hooks/*.sh 로 깨졌는데 스크립트는 "설치 성공"을
tests/install-hook-swap.test.sh:10:# 그래서 케이스마다 **부수 효과**를 함께 잰다: 훅이 제자리에 있나 · 중첩(hooks/hooks)이
tests/install-hook-swap.test.sh:58:  printf 'OLD\n' > "$p/.claude/hooks/.old-marker"
tests/install-hook-swap.test.sh:61:  printf 'user\n' > "$p/.claude/hooks/custom.sh"
tests/install-hook-swap.test.sh:62:  mkdir -p "$p/.claude/hooks/lib" && printf 'lib\n' > "$p/.claude/hooks/lib/helper.sh"
tests/install-hook-swap.test.sh:111:  printf 'STALE\n' > "$p/.claude/hooks/_common.sh"
tests/install-hook-swap.test.sh:114:  elif grep -q '^STALE$' "$p/.claude/hooks/_common.sh" 2>/dev/null; then
tests/install-hook-swap.test.sh:116:  elif [ ! -f "$p/.claude/hooks/custom.sh" ]; then
tests/install-hook-swap.test.sh:118:  elif [ ! -f "$p/.claude/hooks/lib/helper.sh" ]; then
tests/install-hook-swap.test.sh:120:  elif [ -e "$p/.claude/hooks/hooks" ]; then why='중첩(hooks/hooks)이 생겼다'
tests/install-hook-swap.test.sh:137:  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then
tests/install-hook-swap.test.sh:139:  elif [ -e "$p/.claude/hooks/hooks" ]; then
tests/install-hook-swap.test.sh:140:    why='중첩(hooks/hooks)이 생겼다'
tests/install-hook-swap.test.sh:167:  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
tests/install-hook-swap.test.sh:186:  elif [ ! -f "$p/real-hooks/_common.sh" ]; then why='링크 대상에 훅이 복사되지 않았다'
tests/install-hook-swap.test.sh:203:  rm -f "$p/.claude/hooks/_common.sh"
tests/install-hook-swap.test.sh:204:  ln -s "$p/outside.txt" "$p/.claude/hooks/_common.sh" || { report "$name" '픽스처 실패: ln'; return 0; }
tests/install-hook-swap.test.sh:209:  elif [ ! -s "$p/.claude/hooks/_common.sh" ] || [ -L "$p/.claude/hooks/_common.sh" ]; then
tests/install-hook-swap.test.sh:237:  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
install.sh:9:#   settings.json                               → 병합 (기존 훅 보존, 백업 생성)
install.sh:78:#      선점되면 훅이 hooks/hooks/*.sh 로 깨지는데 메시지는 "되돌렸습니다"라고 말한다.
install.sh:91:  cp "$SRC/hooks/"*.sh "$DST/hooks/"
install.sh:92:  chmod +x "$DST/hooks/"*.sh
install.sh:101:    if ! cp -R "$DST/hooks/." "$hooks_stage/"; then
install.sh:110:  for _t in "$SRC/hooks/"*.sh; do
install.sh:114:  cp "$SRC/hooks/"*.sh "$hooks_stage/"     # 템플릿 훅만 덮어쓴다
install.sh:201:# ── 3) settings.json 병합 (기존 훅 보존) ────────────────────────────
install.sh:202:if [ -f "$DST/settings.json" ]; then
install.sh:203:  cp "$DST/settings.json" "$DST/settings.json.bak-$STAMP"
install.sh:204:  echo "   settings 백업 → settings.json.bak-$STAMP"
install.sh:206:python3 - "$DST/settings.json" "$SRC/settings.json" <<'PYEOF'
install.sh:244:print(f"   settings.json ✓  훅 배선 {added}건 추가 (기존 훅 보존)")
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
    30	# 개명 전 플래그 이행 — **배포되지 않는 이 스크립트가 맡는다.**
    31	# 기존 설치본에 미처리 지식 플래그가 옛 이름으로 남아 있을 수 있는데, 새 훅은 새 이름만
    32	# 보므로 그대로 두면 밀린 반영 의무가 **조용히 사라진다**(하네스를 갱신했을 뿐인데).
    33	# 훅 쪽에서 옛 이름을 알게 하면 배포되는 글루가 구현체 이름을 다시 품어 층 경계 검사가
    34	# 막는다 — 그래서 이행은 여기에 있다. 새 이름이 이미 있으면 **덮지 않고 이어붙인다.**
    35	legacy_flag="$DST/.needs-$(printf 'vault')"
    36	if [ -f "$legacy_flag" ]; then
    37	  if [ -s "$legacy_flag" ]; then
    38	    if cat "$legacy_flag" >> "$DST/.needs-knowledge" 2>/dev/null; then
    39	      rm -f "$legacy_flag"
    40	      echo "   플래그 이행 ✓  미처리 지식 반영 항목을 새 이름으로 옮겼습니다"
    41	    else
    42	      echo "   ⚠ 미처리 지식 반영 플래그를 새 이름으로 옮기지 못했습니다: $legacy_flag" >&2
    43	      echo "     손으로 옮기지 않으면 그 항목의 반영 의무가 사라집니다." >&2
    44	    fi
    45	  else
    46	    rm -f "$legacy_flag"
    47	  fi
    48	fi
    49	
    50	# ── 1) 글루 복사 (덮어씀) ─────────────────────────────────────────────
    51	mkdir -p "$DST/agents" "$DST/skills" "$DST/hooks" "$DST/harness"
    52	cp "$SRC/agents/"*.md "$DST/agents/"
    53	# 스킬은 디렉토리째 전부 복사한다(references/·scripts/ 포함) — 특정 스킬명·특정 파일만
    54	# 복사하는 하드코딩은 readable-writing 미배포 버그(2026-08-03 점검)를 낳았다
    55	skill_count=0
    56	for skill_dir in "$SRC/skills/"*/; do
    57	  skill_name="$(basename "$skill_dir")"
    58	  mkdir -p "$DST/skills/$skill_name"
    59	  cp -R "$skill_dir"/. "$DST/skills/$skill_name/"
    60	  skill_count=$((skill_count + 1))
    61	done
    62	# ── 1a) 훅 교체는 파일 단위가 아니라 **디렉터리 rename 스왑** ────────
    63	#
    64	# 훅을 하나씩 덮으면 신·구가 섞인 중간 상태가 **반드시** 존재한다. 순서를 바꿔도 못
    65	# 막는다 — 훅들이 _common.sh 를 공유하므로 어느 쪽을 먼저 바꾸든 창이 열린다. 그 창에서
    66	# Claude 세션이 훅을 부르면 새 훅이 옛 _common.sh 를(또는 그 반대를) 읽는다.
    67	#
    68	# 그래서 스테이징 디렉터리를 만들고 **rename 2회**로 바꾼다. 혼합 상태가 원리적으로
    69	# 불가능해진다. 대신 두 rename 사이에 훅이 **없는** 창이 생기는데, 그건 잘못된 훅이
    70	# 도는 것보다 낫다(없으면 게이트가 안 설 뿐, 틀린 판정을 내지 않는다).
    71	#
    72	# 파생 계약 셋 — 전부 앞선 검수에서 **직전 수정이 만든 결함**으로 드러난 것들이다:
    73	#   1. 신호 핸들러는 복구 후 **실제로 종료**해야 한다. 반환만 하면 후속 명령이 계속 돌아
    74	#      mv 가 기존 디렉터리 **안으로** 중첩되고, 그러고도 "설치 성공"을 보고한다.
    75	#      그리고 그 exit 에 도달하려면 핸들러 진입 직후 `set +e` 가 필요하다 — 진단 echo
    76	#      하나가 실패해도(stderr 가 닫힌 채 실행 등) set -e 가 exit 전에 죽인다.
    77	#   2. 백업 이름은 `mktemp -d` 로 유일성을 보장한다. `$$` 는 PID 재사용으로 선점될 수 있고,
    78	#      선점되면 훅이 hooks/hooks/*.sh 로 깨지는데 메시지는 "되돌렸습니다"라고 말한다.
    79	#   3. 자리를 비우려고 `rmdir` 을 먼저 하지 않는다 — 그 사이가 TOCTOU 창이다.
    80	#      중첩을 **의도된 계약**으로 명시하면(mv "$DST/hooks" "$backup/hooks") 창이 없어진다.
    81	#
    82	# 남는 창(공시): 복구 **자체**가 다시 중단되면(SIGKILL·전원 차단) 훅 디렉터리가 없는
    83	# 상태로 남는다. install.sh 재실행이 복구하지만 그 재실행도 중단되면 같은 상태가
    84	# 반복된다. 이 창은 닫히지 않았다 — 닫으려면 이 스크립트 밖의 장치가 필요하다.
    85	if [ -L "$DST/hooks" ]; then
    86	  # 사용자가 훅 디렉터리를 심볼릭 링크로 두었다. rename 스왑은 그 링크를 **일반
    87	  # 디렉터리로 갈아치운다** — 사용자의 배치를 하네스가 마음대로 바꾸는 것이라 하지 않는다.
    88	  # 파일 단위 복사로 물러서고, 원자성을 못 지킨다는 사실을 **알린다**(조용히 물러서지 않는다).
    89	  echo "   ⚠ .claude/hooks 가 심볼릭 링크입니다 — 링크를 보존하려고 파일 단위로 복사합니다." >&2
    90	  echo "     교체 도중 신·구가 섞이는 창이 열립니다. 설치 중에는 Claude 세션을 띄우지 마세요." >&2
    91	  cp "$SRC/hooks/"*.sh "$DST/hooks/"
    92	  chmod +x "$DST/hooks/"*.sh
    93	else
    94	  hooks_stage="$(mktemp -d "$DST/.hooks-stage.XXXXXX")"
    95	  hooks_backup="$(mktemp -d "$DST/.hooks-old.XXXXXX")"
    96	  # **디렉터리를 통째로 바꾸므로 기존 내용물을 먼저 스테이징으로 옮겨 심는다.**
    97	  # 이게 없으면 템플릿에 없는 사용자 파일(custom.sh·보조 파일·하위 디렉터리)이
    98	  # 재설치마다 영구 삭제된다 — 파일 단위 cp 였던 구 구현에는 없던 회귀다.
    99	  # 슬롯이 아니어도 사용자가 그 디렉터리에 둔 것을 하네스가 지울 권한은 없다.
   100	  if [ -d "$DST/hooks" ]; then
   101	    if ! cp -R "$DST/hooks/." "$hooks_stage/"; then
   102	      rm -rf "$hooks_stage" "$hooks_backup"
   103	      echo "✗ 기존 훅 디렉터리를 스테이징으로 복사하지 못했습니다 — 사용자 파일을 잃지 않으려고 중단합니다." >&2
   104	      exit 1
   105	    fi
   106	  fi
   107	  # 템플릿이 덮을 자리에 **심링크가 보존돼 있으면 먼저 치운다.** 안 그러면 cp 가 그 링크를
   108	  # 따라가 링크 대상(디렉터리 밖 사용자 파일)을 덮어쓴다 — 보존하려다 파괴하는 셈이다.
   109	  # 지우는 것은 스테이징의 링크뿐이고, 링크 대상 파일에는 손대지 않는다.
   110	  for _t in "$SRC/hooks/"*.sh; do
   111	    _b="$(basename "$_t")"
   112	    [ -L "$hooks_stage/$_b" ] && rm -f "$hooks_stage/$_b"
   113	  done
   114	  cp "$SRC/hooks/"*.sh "$hooks_stage/"     # 템플릿 훅만 덮어쓴다
   115	  chmod +x "$hooks_stage/"*.sh
   116	
   117	  on_swap_signal() {   # $1=신호 이름  $2=종료 코드
   118	    set +e             # 보고는 최선 노력, **종료 코드가 계약**이다
   119	    # 플래그가 아니라 **파일시스템 실제 상태**로 판정한다. 첫 mv 가 끝났는데 플래그를
   120	    # 세우기 전에 신호가 오는 창이 있고(bash 는 외부 명령 종료 뒤 대기 중인 trap 을
   121	    # 먼저 실행한다), 플래그를 믿으면 그 창에서 복원하지 않고 백업까지 지운다.
   122	    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
   123	      if mv "$hooks_backup/hooks" "$DST/hooks"; then
   124	        echo "[$1] 훅 교체 도중 중단 — 구판으로 되돌렸습니다." >&2
   125	        rm -rf "$hooks_stage" "$hooks_backup"
   126	      else
   127	        # 복구가 실패했다. **백업을 지우지 않는다** — 그것이 유일한 사본이다.
   128	        echo "[$1] 훅 교체 도중 중단됐고 **복구도 실패했습니다**." >&2
   129	        echo "     구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
   130	        echo "     손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
   131	        rm -rf "$hooks_stage"
   132	      fi
   133	    else
   134	      echo "[$1] 중단되었습니다 (훅 교체는 시작 전이거나 이미 끝났습니다)." >&2
   135	      rm -rf "$hooks_stage" "$hooks_backup"
   136	    fi
   137	    exit "$2"
   138	  }
   139	  # QUIT·HUP 도 잡는다: bash 는 trap 이 없으면 QUIT 를 **무시하고 rc=0 을 낸다** —
   140	  # 중단됐는데 "성공"으로 보고되는 최악의 조합이다(실측).
   141	  trap 'on_swap_signal INT  130' INT
   142	  trap 'on_swap_signal TERM 143' TERM
   143	  trap 'on_swap_signal QUIT 131' QUIT
   144	  trap 'on_swap_signal HUP  129' HUP
   145	
   146	  if [ -d "$DST/hooks" ]; then
   147	    mv "$DST/hooks" "$hooks_backup/hooks"   # 중첩은 사고가 아니라 계약이다
   148	  fi
   149	  if ! mv "$hooks_stage" "$DST/hooks"; then
   150	    # rename2 실패. **성공으로 오진단하지 않는다** — 되돌리고 실패로 끝낸다.
   151	    # 복구 mv 의 rc 를 확인한다. 실패했는데 "되돌렸습니다"를 찍고 백업을 지우면
   152	    # 유일한 사본이 사라진다.
   153	    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
   154	      if mv "$hooks_backup/hooks" "$DST/hooks"; then
   155	        echo "   구판 훅으로 되돌렸습니다." >&2
   156	        rm -rf "$hooks_backup"
   157	      else
   158	        echo "   **복구도 실패했습니다.** 구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
   159	        echo "   손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
   160	      fi
   161	    else
   162	      rm -rf "$hooks_backup"
   163	    fi
   164	    rm -rf "$hooks_stage"
   165	    echo "✗ 훅 디렉터리를 교체하지 못했습니다: $DST/hooks" >&2
   166	    exit 1
   167	  fi
   168	  trap - INT TERM QUIT HUP     # 여기부터는 되돌릴 것이 없다
   169	  rm -rf "$hooks_backup"
   170	fi
   171	hook_count="$(ls "$DST/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
   172	
   173	cp "$SRC/harness/principles.md" "$DST/harness/"
   174	echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 $hook_count · 제0원칙"
   175	
   176	# ── 1b) 전역 에이전트 배포 (~/.claude/agents/ — 프로젝트 무관 글루, 덮어씀) ──
   177	# 정본은 이 repo의 global-agents/ (전역 디렉토리는 버전 관리가 안 되므로 — ADR-0002)
   178	GLOBAL_SRC="$TPL_ROOT/global-agents"
   179	if [ -d "$GLOBAL_SRC" ] && ls "$GLOBAL_SRC"/*.md >/dev/null 2>&1; then
   180	  mkdir -p "$HOME/.claude/agents"
   181	  cp "$GLOBAL_SRC"/*.md "$HOME/.claude/agents/"
   182	  echo "   전역 에이전트 ✓  $(ls "$GLOBAL_SRC"/*.md | wc -l | tr -d ' ')종 → ~/.claude/agents/"
   183	fi
   184	
   185	# ── 2) 슬롯 스캐폴드 (없을 때만 — 도메인은 사용자가 채운다) ──────────
   186	if [ ! -f "$DST/harness/project-profile.md" ]; then
   187	  sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
   188	    > "$DST/harness/project-profile.md"
   189	  echo "   슬롯 생성 ✓  harness/project-profile.md   ← 1~9절 채우세요"
   190	else
   191	  echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
   192	fi
   193	if [ ! -f "$DST/harness/harness.env" ]; then
   194	  cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
   195	  echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
   196	  echo "                                                 (HARNESS_KNOWLEDGE_GATE 는 기본 켜짐)"
   197	else
   198	  echo "   슬롯 보존    harness/harness.env          (기존 유지)"
   199	fi
   200	
   201	# ── 3) settings.json 병합 (기존 훅 보존) ────────────────────────────
   202	if [ -f "$DST/settings.json" ]; then
   203	  cp "$DST/settings.json" "$DST/settings.json.bak-$STAMP"
   204	  echo "   settings 백업 → settings.json.bak-$STAMP"
   205	fi
   206	python3 - "$DST/settings.json" "$SRC/settings.json" <<'PYEOF'
   207	import json, os, sys
   208	dst_path, src_path = sys.argv[1], sys.argv[2]
   209	with open(src_path) as f:
   210	    ours = json.load(f)
   211	cur = {}
   212	if os.path.exists(dst_path):
   213	    with open(dst_path) as f:
   214	        cur = json.load(f)
   215	hooks = cur.setdefault("hooks", {})
   216	added = 0
   217	for event, entries in ours.get("hooks", {}).items():
   218	    lst = hooks.setdefault(event, [])
   219	    existing_cmds = {
   220	        (entry.get("matcher"), h.get("command"))
   221	        for entry in lst
   222	        for h in entry.get("hooks", [])
   223	    }
   224	    for entry in entries:
   225	        # (matcher, command) 단위 병합 — "항목에 하나라도 있으면 전체 스킵"은 같은 항목에 묶인
   226	        # 새 훅(guard-codex-invocation)이 기존 설치본에 영영 배선되지 않는 버그였고(2026-08-03),
   227	        # command만 보면 엉뚱한 matcher에 붙은 훅을 "배선됨"으로 오인한다([cx] 지적).
   228	        missing = [h for h in entry.get("hooks", [])
   229	                   if (entry.get("matcher"), h.get("command")) not in existing_cmds]
   230	        if not missing:
   231	            continue  # 전부 배선됨 (멱등)
   232	        target = next((e for e in lst if e.get("matcher") == entry.get("matcher")), None)
   233	        if target is not None:
   234	            target.setdefault("hooks", []).extend(missing)
   235	        else:
   236	            new_entry = {k: v for k, v in entry.items() if k != "hooks"}
   237	            new_entry["hooks"] = missing
   238	            lst.append(new_entry)
   239	        added += len(missing)
   240	        existing_cmds.update((entry.get("matcher"), h.get("command")) for h in missing)
   241	with open(dst_path, "w") as f:
   242	    json.dump(cur, f, ensure_ascii=False, indent=2)
   243	    f.write("\n")
   244	print(f"   settings.json ✓  훅 배선 {added}건 추가 (기존 훅 보존)")
   245	PYEOF
   246	
   247	# ── 4) CLAUDE.md 하네스 포인터 ───────────────────────────────────────
   248	if [ -f "$PROJECT/CLAUDE.md" ] && grep -q "harness-orchestrator" "$PROJECT/CLAUDE.md"; then
   249	  echo "   CLAUDE.md    포인터 이미 있음 (생략)"
   250	else
   251	  { [ -f "$PROJECT/CLAUDE.md" ] && [ -s "$PROJECT/CLAUDE.md" ] && echo ""; \
   252	    sed -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{YYYY-MM-DD}}/$TODAY/g" \
   253	        -e "s/{{한 줄 목표}}/($NAME 프로필 §1 참조)/g" \
   254	        "$TPL_ROOT/template/CLAUDE.md.snippet"; } >> "$PROJECT/CLAUDE.md"
   255	  echo "   CLAUDE.md ✓  하네스 포인터 append"
   256	fi
   257	
   258	echo ""
   259	echo "== 완료. 다음 단계:"
   260	echo "   1. $DST/harness/project-profile.md 의 1~9절 채우기 (도메인 슬롯 + 지식 진입점)"
   261	echo "   2. $DST/harness/harness.env 의 HARNESS_TYPECHECK_CMD 채우기"
   262	echo "   3. 새 Claude Code 세션 시작 (훅은 세션 시작 시 스냅샷 — 이번 세션엔 발화 안 함)"
   263	echo "   4. 개발 요청 → harness-orchestrator 스킬이 파이프라인 실행"

exec
/bin/zsh -lc "rg -n \"ECC_GATEGUARD|HARNESS_HOOKS|ECC_DISABLED_HOOKS\" . --hidden --glob '"'!.git/**'"' --glob '"'!_workspace/06_gates.diff'"' --glob '"'!_workspace/06_codex_prompt.md'"' --glob '"'!_workspace/06_codex_review.md'"' && git show 9079ac1:template/.claude/hooks/guard-codex-invocation.sh | nl -ba && git show 9079ac1:template/.claude/hooks/guard-master-commit.sh | nl -ba" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
./tests/mark-needs-audit.test.sh:181:# 앰비언트 탈출구를 **소거**하고 부른다. 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off /
./tests/mark-needs-audit.test.sh:182:# ECC_DISABLED_HOOKS 를 export 한 셸에서 도는 워크플로라, 소거하지 않으면 게이트·듀얼 행이
./tests/mark-needs-audit.test.sh:193:        | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
./README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→지식 저장소반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
./tests/mark-needs-audit.cases.sh:392:case_43() { # 탈출구 HARNESS_HOOKS=off. run_hook 이 기본으로 소거하므로 여기서만 재주입한다.
./tests/mark-needs-audit.cases.sh:396:  run_hook "$p" "$p/src/app.ts" HARNESS_HOOKS=off
./tests/mark-needs-audit.cases.sh:397:  check_case '43 HARNESS_HOOKS=off → 무변화' 0 none ''
./tests/mark-needs-audit.cases.sh:400:case_44() { # 탈출구 ECC_DISABLED_HOOKS — 훅 id 단위.
./tests/mark-needs-audit.cases.sh:404:  run_hook "$p" "$p/src/app.ts" ECC_DISABLED_HOOKS=post:edit:needs-audit
./tests/mark-needs-audit.cases.sh:405:  check_case '44 ECC_DISABLED_HOOKS=post:edit:needs-audit → 무변화' 0 none ''
./template/CLAUDE.md.snippet:11:**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 게이트 플래그 4종 / Stop 시 타입체크(프로필 3절)+codex 듀얼리뷰+change-explainer+지식 저장소 반영+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
./tests/harness-env-read.test.sh:100:# 앰비언트 탈출구를 소거한다 — 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off 를
./tests/harness-env-read.test.sh:105:  raw="$(env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
./tests/harness-env-read.test.sh:147:          | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
./tests/self-discipline-gates.test.sh:50:    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$TMPROOT" \
./tests/self-discipline-gates.test.sh:73:g01() { gcase '전체 비활성 대입을 막는다'         'HARNESS_HOOKS=off claude'                 2; }
./tests/self-discipline-gates.test.sh:74:g02() { gcase '개별 비활성 대입을 막는다'         'ECC_DISABLED_HOOKS=stop:knowledge x'      2; }
./tests/self-discipline-gates.test.sh:75:g03() { gcase 'GateGuard 끄기를 막는다'           'ECC_GATEGUARD=off ./run.sh'               2; }
./tests/self-discipline-gates.test.sh:76:g04() { gcase 'export 형태도 막는다'              'export HARNESS_HOOKS=off'                 2; }
./tests/self-discipline-gates.test.sh:78:g05() { gcase '값을 읽는 것은 막지 않는다'        'echo "$HARNESS_HOOKS"'                    0; }
./tests/self-discipline-gates.test.sh:79:g06() { gcase '이름만 언급하는 것은 막지 않는다'  'grep -n ECC_DISABLED_HOOKS docs/usage.md' 0; }
./tests/self-discipline-gates.test.sh:80:g07() { gcase '접두사가 다른 변수는 막지 않는다'  'MY_ECC_GATEGUARD=1 ./x.sh'                0; }
./tests/self-discipline-gates.test.sh:82:g08() { gcase '탈출구로 이 훅 자신을 끌 수 없다'   'HARNESS_HOOKS=off claude'                2 HARNESS_HOOKS=off; }
./tests/self-discipline-gates.test.sh:83:g09() { gcase '개별 비활성으로도 이 훅을 못 끈다'  'ECC_GATEGUARD=off x'                     2 ECC_DISABLED_HOOKS=pre:bash:hook-disable; }
./tests/self-discipline-gates.test.sh:110:    | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
./docs/decisions/2026-08-06-gate-scope-by-file-identity.md:82:  피해 방향이 "과하게 섬"이고 탈출구(`ECC_DISABLED_HOOKS=post:edit:needs-audit`)가 있어 감수한다
./docs/usage.md:64:| guard-hook-disable | Bash 실행 전 | **에이전트가 게이트를 끄는 것**을 차단 — `HARNESS_HOOKS`·`ECC_DISABLED_HOOKS`·`ECC_GATEGUARD` **대입**만(읽기는 허용). 탈출구가 **없다** — 있으면 그것으로 나머지를 전부 끌 수 있다 |
./docs/usage.md:71:**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) / `stop:push`(push 게이트만) 나열.
./_workspace/05_codex_r2.md:1759:    27	#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/05_codex_r2.md:1760:    28	#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./_workspace/05_codex_r2.md:1762:    30	  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/05_codex_r2.md:1765:    33	  case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/05_codex_r2.md:2307:   100	# 앰비언트 탈출구를 소거한다 — 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off 를
./_workspace/05_codex_r2.md:2312:   105	  raw="$(env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
./_workspace/05_codex_r2.md:2354:   147	          | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
./_workspace/05_codex_r2.md:3047:561:+./README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
./_workspace/05_codex_r2.md:3193:   126	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/05_codex_r2.md:3217:   150	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/05_codex_r2.md:3225:   158	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
./_workspace/05_codex_r2.md:3239:   172	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./_workspace/04_review.diff:212:+ #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/04_review.diff:213:+ #   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./_workspace/04_review.diff:215:+   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/04_review.diff:218:+   case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/04_review.diff:407:+       echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_review.diff:431:+     echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/04_review.diff:439:+ #     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
./_workspace/04_review.diff:561:+./README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
./_workspace/04_review.diff:601:+./_workspace/03_impl_r1_codex.md:76: #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/04_review.diff:602:+./_workspace/03_impl_r1_codex.md:79:   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/04_review.diff:618:+./_workspace/03_impl_r1_codex.md:271:       echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_review.diff:619:+./_workspace/03_impl_r1_codex.md:295:     echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/04_review.diff:640:+./tests/mark-needs-audit.cases.sh:392:case_43() { # 탈출구 HARNESS_HOOKS=off. run_hook 이 기본으로 소거하므로 여기서만 재주입한다.
./_workspace/04_review.diff:641:+./tests/mark-needs-audit.cases.sh:396:  run_hook "$p" "$p/src/app.ts" HARNESS_HOOKS=off
./_workspace/04_review.diff:642:+./tests/mark-needs-audit.cases.sh:397:  check_case '43 HARNESS_HOOKS=off → 무변화' 0 none ''
./_workspace/04_review.diff:650:+./tests/mark-needs-audit.test.sh:181:# 앰비언트 탈출구를 **소거**하고 부른다. 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off /
./_workspace/04_review.diff:651:+./tests/mark-needs-audit.test.sh:193:        | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
./_workspace/04_review.diff:655:+./docs/usage.md:66:**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:vault`(볼트 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./_workspace/04_review.diff:657:+./template/CLAUDE.md.snippet:11:**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 완료·설명 게이트 플래그 / Stop 시 타입체크(프로필 §3)+change-explainer+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
./_workspace/04_review.diff:680:+./template/.claude/hooks/_common.sh:22:#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/04_review.diff:681:+./template/.claude/hooks/_common.sh:25:  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/04_review.diff:693:+./template/.claude/hooks/verify-before-stop.sh:119:      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_review.diff:694:+./template/.claude/hooks/verify-before-stop.sh:143:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/04_review.diff:695:+./template/.claude/hooks/verify-before-stop.sh:165:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./_workspace/04_review.diff:696:+./template/.claude/hooks/verify-before-stop.sh:190:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:vault"
./_workspace/04_review.diff:697:+./template/.claude/hooks/verify-before-stop.sh:212:  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_review.diff:700:+./template/.claude/hooks/guard-master-commit.sh:60:  echo "  HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_review.diff:758:+    22	#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/04_review.diff:759:+    23	#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./_workspace/04_review.diff:761:+    25	  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/04_review.diff:764:+    28	  case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/04_review.diff:943:+   119	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_review.diff:967:+   143	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/04_review.diff:975:+   151	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
./_workspace/04_review.diff:989:+   165	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./_workspace/04_review.diff:1014:+   190	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:vault"
./_workspace/04_review.diff:1036:+   212	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_review.diff:1150:+   120	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_review.diff:1991:-**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:vault`(볼트 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./_workspace/04_review.diff:1992:+**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./_workspace/04_review.diff:2816:-    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:vault"
./_workspace/04_review.diff:2817:+    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:knowledge"
./_workspace/04_review.diff:2883:-**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 완료·설명 게이트 플래그 / Stop 시 타입체크(프로필 §3)+change-explainer+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
./_workspace/04_review.diff:2884:+**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 게이트 플래그 4종 / Stop 시 타입체크(프로필 3절)+codex 듀얼리뷰+change-explainer+지식 저장소 반영+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
./_workspace/04_review.diff:3205:+# 앰비언트 탈출구를 소거한다 — 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off 를
./_workspace/04_review.diff:3210:+  raw="$(env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
./_workspace/04_review.diff:3252:+          | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
./template/.claude/hooks/_common.sh:27:#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./template/.claude/hooks/_common.sh:28:#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./template/.claude/hooks/_common.sh:30:  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./template/.claude/hooks/_common.sh:33:  case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/04_codex_review.md:298:+ #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/04_codex_review.md:299:+ #   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./_workspace/04_codex_review.md:301:+   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/04_codex_review.md:304:+   case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/04_codex_review.md:406:    24	#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/04_codex_review.md:407:    25	#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./_workspace/04_codex_review.md:409:    27	  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/04_codex_review.md:412:    30	  case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/04_codex_review.md:760:   126	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_codex_review.md:784:   150	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/04_codex_review.md:792:   158	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
./_workspace/04_codex_review.md:806:   172	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./_workspace/04_codex_review.md:839:   205	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:knowledge"
./_workspace/04_codex_review.md:861:   227	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_codex_review.md:1003:   140	# 위음성은 조용하고 오탐은 탈출구(ECC_DISABLED_HOOKS)가 있다 — 그래서 단순한 쪽을 택했다.
./_workspace/04_codex_review.md:1180:   126	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_codex_review.md:1204:   150	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/04_codex_review.md:1212:   158	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
./_workspace/04_codex_review.md:1226:   172	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./_workspace/04_codex_review.md:1259:   205	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:knowledge"
./_workspace/04_codex_review.md:1281:   227	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/04_codex_review.md:1944:   100	# 앰비언트 탈출구를 소거한다 — 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off 를
./_workspace/04_codex_review.md:1949:   105	  raw="$(env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS CLAUDE_PROJECT_DIR="$proj" \
./_workspace/04_codex_review.md:1991:   147	          | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS ${@+"$@"} CLAUDE_PROJECT_DIR="$proj" \
./_workspace/04_codex_review.md:3162:   181	# 앰비언트 탈출구를 **소거**하고 부른다. 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off /
./_workspace/04_codex_review.md:3163:   182	# ECC_DISABLED_HOOKS 를 export 한 셸에서 도는 워크플로라, 소거하지 않으면 게이트·듀얼 행이
./_workspace/04_codex_review.md:3174:   193	        | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
./_workspace/04_codex_review.md:3711:    70	**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./_workspace/04_codex_review.md:4182:    11	**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 게이트 플래그 4종 / Stop 시 타입체크(프로필 3절)+codex 듀얼리뷰+change-explainer+지식 저장소 반영+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
./_workspace/04_codex_review.md:4675: #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/04_codex_review.md:4676: #   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./_workspace/04_codex_review.md:4678:   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/04_codex_review.md:4681:   case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/04_codex_review.md:4986:-**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:vault`(볼트 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./_workspace/04_codex_review.md:4987:+**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./_workspace/04_codex_review.md:5052: # 위음성은 조용하고 오탐은 탈출구(ECC_DISABLED_HOOKS)가 있다 — 그래서 단순한 쪽을 택했다.
./_workspace/04_codex_review.md:5446:@@ -401,70 +401,70 @@ case_44() { # 탈출구 ECC_DISABLED_HOOKS — 훅 id 단위.
./_workspace/04_codex_review.md:5450:   run_hook "$p" "$p/src/app.ts" ECC_DISABLED_HOOKS=post:edit:needs-audit
./_workspace/04_codex_review.md:5451:   check_case '44 ECC_DISABLED_HOOKS=post:edit:needs-audit → 무변화' 0 none ''
./_workspace/04_codex_review.md:5861:docs/usage.md:70:**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./_workspace/04_codex_review.md:5952:    82	  피해 방향이 "과하게 섬"이고 탈출구(`ECC_DISABLED_HOOKS=post:edit:needs-audit`)가 있어 감수한다
./_workspace/04_codex_review.md:5968:./README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
./_workspace/04_codex_review.md:6030:    63	대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
./_workspace/04_codex_review.md:6482:[MEDIUM] README.md:63 — 현재 동작 설명이 여전히 `.needs-vault`, `stop:vault`, 볼트 고유 구현을 사용한다. 사용자가 이 문서대로 `ECC_DISABLED_HOOKS=stop:vault`를 설정하면 새 `stop:knowledge` 게이트는 꺼지지 않으며, ADR-0006의 “구현 누출 0” 공시와도 충돌한다.
./_workspace/04_codex_review.md:6511:[MEDIUM] README.md:63 — 현재 동작 설명이 여전히 `.needs-vault`, `stop:vault`, 볼트 고유 구현을 사용한다. 사용자가 이 문서대로 `ECC_DISABLED_HOOKS=stop:vault`를 설정하면 새 `stop:knowledge` 게이트는 꺼지지 않으며, ADR-0006의 “구현 누출 0” 공시와도 충돌한다.
./_workspace/03_impl_r1_codex.md:76: #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/03_impl_r1_codex.md:77: #   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./_workspace/03_impl_r1_codex.md:79:   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/03_impl_r1_codex.md:82:   case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/03_impl_r1_codex.md:271:       echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/03_impl_r1_codex.md:295:     echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/03_impl_r1_codex.md:303: #     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
./_workspace/03_impl_r1_codex.md:425:./README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
./_workspace/03_impl_r1_codex.md:465:./_workspace/03_impl_r1_codex.md:76: #   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/03_impl_r1_codex.md:466:./_workspace/03_impl_r1_codex.md:79:   if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/03_impl_r1_codex.md:482:./_workspace/03_impl_r1_codex.md:271:       echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/03_impl_r1_codex.md:483:./_workspace/03_impl_r1_codex.md:295:     echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/03_impl_r1_codex.md:504:./tests/mark-needs-audit.cases.sh:392:case_43() { # 탈출구 HARNESS_HOOKS=off. run_hook 이 기본으로 소거하므로 여기서만 재주입한다.
./_workspace/03_impl_r1_codex.md:505:./tests/mark-needs-audit.cases.sh:396:  run_hook "$p" "$p/src/app.ts" HARNESS_HOOKS=off
./_workspace/03_impl_r1_codex.md:506:./tests/mark-needs-audit.cases.sh:397:  check_case '43 HARNESS_HOOKS=off → 무변화' 0 none ''
./_workspace/03_impl_r1_codex.md:514:./tests/mark-needs-audit.test.sh:181:# 앰비언트 탈출구를 **소거**하고 부른다. 이 저장소를 고치는 작업 자체가 HARNESS_HOOKS=off /
./_workspace/03_impl_r1_codex.md:515:./tests/mark-needs-audit.test.sh:193:        | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
./_workspace/03_impl_r1_codex.md:519:./docs/usage.md:66:**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:vault`(볼트 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.
./_workspace/03_impl_r1_codex.md:521:./template/CLAUDE.md.snippet:11:**강제 훅 (`.claude/settings.json`, 커밋됨):** 기본 브랜치 직접 커밋 차단 / 코드·설정 편집 시 완료·설명 게이트 플래그 / Stop 시 타입체크(프로필 §3)+change-explainer+completion-auditor 미실행이면 종료 차단. 무한루프 가드 3회. 탈출구 `HARNESS_HOOKS=off` 또는 `ECC_DISABLED_HOOKS`.
./_workspace/03_impl_r1_codex.md:544:./template/.claude/hooks/_common.sh:22:#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/03_impl_r1_codex.md:545:./template/.claude/hooks/_common.sh:25:  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/03_impl_r1_codex.md:557:./template/.claude/hooks/verify-before-stop.sh:119:      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/03_impl_r1_codex.md:558:./template/.claude/hooks/verify-before-stop.sh:143:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/03_impl_r1_codex.md:559:./template/.claude/hooks/verify-before-stop.sh:165:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./_workspace/03_impl_r1_codex.md:560:./template/.claude/hooks/verify-before-stop.sh:190:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:vault"
./_workspace/03_impl_r1_codex.md:561:./template/.claude/hooks/verify-before-stop.sh:212:  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/03_impl_r1_codex.md:564:./template/.claude/hooks/guard-master-commit.sh:60:  echo "  HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/03_impl_r1_codex.md:622:    22	#   HARNESS_HOOKS=off                         → 세 훅 모두 비활성
./_workspace/03_impl_r1_codex.md:623:    23	#   ECC_DISABLED_HOOKS=stop:verify,...        → id 로 개별 비활성
./_workspace/03_impl_r1_codex.md:625:    25	  if [ "${HARNESS_HOOKS:-}" = "off" ]; then
./_workspace/03_impl_r1_codex.md:628:    28	  case ",${ECC_DISABLED_HOOKS:-}," in
./_workspace/03_impl_r1_codex.md:807:   119	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/03_impl_r1_codex.md:831:   143	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./_workspace/03_impl_r1_codex.md:839:   151	#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
./_workspace/03_impl_r1_codex.md:853:   165	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./_workspace/03_impl_r1_codex.md:878:   190	    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:vault"
./_workspace/03_impl_r1_codex.md:900:   212	  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./_workspace/03_impl_r1_codex.md:1014:   120	      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./template/.claude/hooks/guard-master-commit.sh:60:  echo "  HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./template/.claude/hooks/guard-hook-disable.sh:4:# 왜: 이 하네스의 모든 게이트에는 탈출구가 있다(HARNESS_HOOKS=off · ECC_DISABLED_HOOKS ·
./template/.claude/hooks/guard-hook-disable.sh:5:# ECC_GATEGUARD). 탈출구는 **사용자를 위한 것**이지 막힌 에이전트를 위한 것이 아니다.
./template/.claude/hooks/guard-hook-disable.sh:13:# **읽는 것은 막지 않는다.** 값을 확인하거나(`echo "$HARNESS_HOOKS"`) 문서에 적는 것은
./template/.claude/hooks/guard-hook-disable.sh:32:# 값까지 보지 않는다 — `ECC_DISABLED_HOOKS=stop:knowledge` 처럼 **하나만** 끄는 것도
./template/.claude/hooks/guard-hook-disable.sh:36:# `$ECC_DISABLED_HOOKS` 같은 참조나 `MY_ECC_GATEGUARD=` 같은 다른 이름은 안 걸린다.
./template/.claude/hooks/guard-hook-disable.sh:38:  | grep -oE '(^|[^A-Za-z0-9_$])(HARNESS_HOOKS|ECC_DISABLED_HOOKS|ECC_GATEGUARD)=' \
./template/.claude/hooks/guard-hook-disable.sh:39:  | grep -oE '(HARNESS_HOOKS|ECC_DISABLED_HOOKS|ECC_GATEGUARD)' \
./template/.claude/hooks/verify-before-stop.sh:126:      echo "탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./template/.claude/hooks/verify-before-stop.sh:150:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:dualreview"
./template/.claude/hooks/verify-before-stop.sh:158:#     (완료 감사와 별개로 이 게이트만 끄려면 ECC_DISABLED_HOOKS=stop:explain)
./template/.claude/hooks/verify-before-stop.sh:172:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:explain"
./template/.claude/hooks/verify-before-stop.sh:205:    echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:knowledge"
./template/.claude/hooks/verify-before-stop.sh:253:        echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=stop:push"
./template/.claude/hooks/verify-before-stop.sh:277:  echo "차단 $((count + 1))/${MAX_BLOCKS}.  탈출구: HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
./template/.claude/hooks/mark-needs-audit.sh:141:# 위음성은 조용하고 오탐은 탈출구(ECC_DISABLED_HOOKS)가 있다 — 그래서 단순한 쪽을 택했다.
     1	#!/usr/bin/env bash
     2	# codex 호출 규율 훅 (2026-08-01 kty 지시)
     3	# 모든 `codex exec` 호출은 모델 gpt-5.6-sol + effort high 고정.
     4	# 오케스트레이터가 "작업이 작다/비용" 이유로 임의 하향한 사고의 재발을 기계로 차단한다.
     5	# 변경이 필요하면 이 훅과 하네스 SKILL.md를 함께 고친다 — 사용자 승인 필수.
     6	#
     7	# 검사 방식 (2026-08-03 재작성 — codex 교차 리뷰 [cx] 지적 반영):
     8	#   shlex 토큰화로 명령 위치의 `codex exec` 호출을 찾고, **호출별로** 그 호출의 인자에서
     9	#   모델·effort를 검사한다. 이유:
    10	#   - 전체 문자열 검사는 "금지 호출; 규정 호출" 연쇄에서 뒤 호출의 옵션이 앞 호출을 가려줬다.
    11	#   - 인용 문자열은 한 토큰이 되므로 커밋 메시지·문서 속 "codex exec"(연결자 포함) 오탐이 없다.
    12	#   - 환경변수 접두(FOO=1 codex …)·예약어(if/then/! …) 뒤의 호출도 명령 위치로 인식한다.
    13	#   알려진 한계(위협 모델 밖 — 기록만): 백틱 치환 내부, 인자 있는 접두 옵션 뒤(sudo -u user /
    14	#   env -u FOO), brace group({ … ; }) 내부는 못 보고, "command -v codex exec" 같은 조회 문자열은
    15	#   오탐 차단될 수 있다. 게이트는 정직한 드리프트 방지용이지 적대 방어가 아니다.
    16	set -u
    17	input=$(cat)
    18	
    19	verdict=$(printf '%s' "$input" | python3 -c '
    20	import json, re, shlex, sys
    21	
    22	try:
    23	    cmd = json.load(sys.stdin).get("tool_input", {}).get("command", "")
    24	except Exception:
    25	    cmd = ""
    26	if not cmd:
    27	    print("OK"); sys.exit(0)
    28	
    29	MODEL_TOKEN = re.compile(r"^[\x27\x22]?gpt-5\.6-sol[\x27\x22]?$")
    30	# 값 전체 인용(-c "model_reasoning_effort=high")도 허용 — 앞 인용부호 미허용은 오탐이었다(3차 [cx])
    31	EFFORT_TOKEN = re.compile(r"^[\x27\x22]?model_reasoning_effort=[\x27\x22]?high[\x27\x22]?$")
    32	EFFORT_ANY = re.compile(r"^[\x27\x22]?model_reasoning_effort=")
    33	
    34	def check_calls(calls):
    35	    # 옵션은 토큰 쌍(-m 값 / -c 값)으로 검사한다 — 문자열 부분 일치는 프롬프트 본문에
    36	    # 들어 있는 "model_reasoning_effort=high" 문구를 옵션으로 오인했다(2차 [cx] 지적).
    37	    for seg in calls:
    38	        ok_model = any(seg[k] == "-m" and MODEL_TOKEN.match(seg[k + 1])
    39	                       for k in range(len(seg) - 1))
    40	        # effort는 "high 지정이 하나 있다"가 아니라 "effort 지정 전부가 high"여야 한다
    41	        # — 중복 -c(…high -c …low)는 마지막 값이 이겨 하향 통과였다(3차 [cx])
    42	        effort_vals = [seg[k + 1] for k in range(len(seg) - 1)
    43	                       if seg[k] == "-c" and EFFORT_ANY.match(seg[k + 1])]
    44	        ok_effort = bool(effort_vals) and all(EFFORT_TOKEN.match(v) for v in effort_vals)
    45	        if not ok_model:
    46	            return "MODEL"
    47	        if not ok_effort:
    48	            return "EFFORT"
    49	    return "OK"
    50	
    51	def tokenize(text):
    52	    # 줄 연속(backslash-개행)은 공백으로, 나머지 개행은 명령 구분자로 치환 —
    53	    # 여러 줄 명령의 2번째 이후 호출 미탐(2차 [cx])과 줄 연속 호출 오탐(3차 [cx]) 방지.
    54	    # 인용 문자열 내부의 개행도 치환되지만, 이 훅은 분석만 하고 실행하지 않으므로 무해하다.
    55	    text = text.replace("\\\n", " ").replace("\n", " ; ")
    56	    lex = shlex.shlex(text, posix=False, punctuation_chars=True)
    57	    lex.whitespace_split = True
    58	    return list(lex)
    59	
    60	try:
    61	    tokens = tokenize(cmd)
    62	except ValueError:
    63	    # 인용 불일치·heredoc 등 파싱 불가 → 구식 보수 검사로 폴백:
    64	    # 명령 위치 codex exec 이 보이면 문자열 전체에서 옵션을 요구한다.
    65	    if re.search(r"(^|[|;&(\n])\s*codex\s+exec(\s|$)", cmd):
    66	        print(check_calls([cmd.split()]))
    67	    else:
    68	        print("OK")
    69	    sys.exit(0)
    70	
    71	CONNECTORS = {";", "&", "&&", "|", "||", "(", ")", ";;", "|&"}
    72	TRANSPARENT = {"if", "then", "elif", "else", "while", "until", "do", "!", "time", "sudo", "env", "command"}
    73	ASSIGN_RE = re.compile(r"[A-Za-z_][A-Za-z_0-9]*=")
    74	
    75	calls = []
    76	cmd_pos = True
    77	i = 0
    78	while i < len(tokens):
    79	    t = tokens[i]
    80	    if t in CONNECTORS or "\n" in t:
    81	        cmd_pos = True
    82	        i += 1
    83	        continue
    84	    if cmd_pos:
    85	        # 예약어·환경변수 접두·그 옵션(-i, -u user …)은 건너뛰고 명령 위치 유지
    86	        # — env/sudo/command 의 옵션 뒤 호출 미탐 방지(2차 [cx])
    87	        if t in TRANSPARENT or ASSIGN_RE.match(t) or t.startswith("-"):
    88	            i += 1
    89	            continue
    90	        if t == "codex" and i + 1 < len(tokens) and tokens[i + 1] == "exec":
    91	            j = i + 2
    92	            seg = []
    93	            while j < len(tokens) and tokens[j] not in CONNECTORS:
    94	                seg.append(tokens[j])
    95	                j += 1
    96	            calls.append(seg)
    97	            i = j
    98	            continue
    99	        cmd_pos = False
   100	    i += 1
   101	
   102	print(check_calls(calls))
   103	' 2>/dev/null)
   104	
   105	case "$verdict" in
   106	  MODEL)
   107	    echo '[Hook 차단] codex exec 는 -m gpt-5.6-sol 필수 — kty 고정 지시. 모델 교체는 사용자 승인 + 훅·SKILL.md 동시 갱신으로만. (연쇄 명령이면 모든 codex exec 호출 각각에 옵션을 명시할 것)' >&2
   108	    exit 2 ;;
   109	  EFFORT)
   110	    echo '[Hook 차단] codex exec 는 -c model_reasoning_effort="high" 필수 — kty 고정 지시, 임의 하향 금지. 낮춰야 할 사유가 있으면 사용자에게 먼저 승인받을 것. (연쇄 명령이면 모든 codex exec 호출 각각에 옵션을 명시할 것)' >&2
   111	    exit 2 ;;
   112	esac
   113	exit 0
     1	#!/usr/bin/env bash
     2	# PreToolUse(Bash): master/main 브랜치 위에서의 `git commit` 을 차단한다.
     3	#
     4	# 근거: 버전관리 정책 — "기본 브랜치 직접 커밋 금지.
     5	#       기능마다 기본 브랜치에서 새 브랜치 → PR → squash merge."
     6	#       (프로필 §7 vcs 참조.)
     7	#
     8	# `gh pr merge` 는 일부러 차단하지 않는다. 훅은 "사용자가 승인한 머지"와
     9	# "모델이 독단으로 하는 머지"를 구분할 수 없기 때문이다.
    10	#
    11	# 알려진 한계: 명령 문자열에 git commit 이 들어간 비커밋 명령
    12	# (예: echo "git commit") 도 차단된다. 탈출구로 우회한다.
    13	
    14	set -uo pipefail
    15	# shellcheck source=_common.sh
    16	. "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
    17	
    18	HOOK_ID="pre:bash:master-guard"
    19	hook_disabled "$HOOK_ID" && exit 0
    20	
    21	payload="$(cat)"
    22	cmd="$(printf '%s' "$payload" | json_get tool_input.command)"
    23	[ -z "$cmd" ] && exit 0
    24	
    25	# symbolic-ref 는 unborn HEAD(커밋 0개)에서도 브랜치명을 준다. 실패(detached)면
    26	# rev-parse 폴백 → "HEAD" 는 아래 case 에 안 걸려 통과된다(의도).
    27	branch="$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null)" \
    28	  || branch="$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)" \
    29	  || exit 0
    30	case "$branch" in
    31	  master|main) ;;
    32	  *) exit 0 ;;
    33	esac
    34	
    35	# 초기 커밋(HEAD 미존재)은 허용 — 신생 repo 의 첫 커밋은 기본 브랜치에 앉는 것이
    36	# 관례고, base 커밋 없이는 PR 흐름 자체가 성립하지 않는다. (의도된 fail-open)
    37	git -C "$PROJECT_DIR" rev-parse --verify -q HEAD >/dev/null 2>&1 || exit 0
    38	
    39	# `git commit ...` 과 `git -C dir commit ...` / `git -c k=v commit ...` 를 잡는다.
    40	# 앞에 오는 문자가 영숫자/밑줄/하이픈이 아니어야 하므로 `&&`, `;`, 줄머리 뒤도 걸린다.
    41	if ! printf '%s' "$cmd" | grep -Eq \
    42	  -e '(^|[^[:alnum:]_-])git[[:space:]]+commit([[:space:]]|$)' \
    43	  -e '(^|[^[:alnum:]_-])git[[:space:]]+-[^[:space:]]+([[:space:]]+[^-][^[:space:]]*)?[[:space:]]+commit([[:space:]]|$)'
    44	then
    45	  exit 0
    46	fi
    47	
    48	{
    49	  echo "[정책 차단] 기본 브랜치 직접 커밋 금지 — 버전관리 정책(프로필 §7)"
    50	  echo
    51	  echo "현재 브랜치: $branch"
    52	  echo "차단된 명령: $(printf '%s' "$cmd" | cut -c1-120)"
    53	  echo
    54	  echo "해야 할 일:"
    55	  echo "  git checkout -b feature/<이름>   # 기본 브랜치에서 새 브랜치"
    56	  echo "  git commit ...                   # 브랜치 위에서 커밋"
    57	  echo "  gh pr create ...                 # PR → squash merge (머지는 사용자 승인 후)"
    58	  echo
    59	  echo "정말 기본 브랜치에 직접 커밋해야 한다면:"
    60	  echo "  HARNESS_HOOKS=off  또는  ECC_DISABLED_HOOKS=$HOOK_ID"
    61	} >&2
    62	exit 2

codex
검수 결과, 핵심 보장 두 개 모두 우회 가능하여 보류입니다.

[치명] template/.claude/hooks/guard-hook-disable.sh:37 — 셸을 해석하지 않고 연속된 `NAME=` 문자열만 찾으므로 간접 대입을 전혀 막지 못한다. 재현 조건: `read HARNESS_HOOKS <<< off; export HARNESS_HOOKS; claude`, `env 'HARNESS_HOOKS''=off' claude`, `HARNESS_HOOKS\\<개행>=off claude`, 변수 조립·base64·생성한 스크립트 실행은 모두 rc=0이다. `set -a`와 `printf -v` 조합, `eval` 입력 조립도 동일하다. 이 방식으로 새 프로세스의 나머지 훅을 모두 끌 수 있다.

[치명] template/.claude/hooks/verify-before-stop.sh:25 — push 판정보다 먼저 “플래그 없음”으로 종료한다. 재현 조건: 듀얼리뷰·설명·지식·감사를 선행해 `.needs-*`를 모두 지운 뒤 로컬 커밋만 만들고 push하지 않은 상태에서 Stop을 호출하면 line 25에서 rc=0으로 끝나 line 222에 도달하지 않는다. Bash로 커밋을 만들어 PostToolUse 플래그가 서지 않은 경우도 같다.

[높음] template/.claude/hooks/guard-hook-disable.sh:38 — 실행 구문과 데이터·인용문·주석을 구분하지 않아 정상 작업을 차단한다. 재현 조건: `git grep -n 'HARNESS_HOOKS=off'`, 해당 문구를 `printf`/heredoc으로 문서나 테스트 픽스처에 기록하기, `bash -c 'echo HARNESS_HOOKS=off'` 모두 실제 환경변수 대입 여부와 무관하게 rc=2다. “읽기·언급은 통과” 계약과 충돌한다.

[높음] template/.claude/hooks/verify-before-stop.sh:225 — 구성된 upstream 대신 `origin/<현재 로컬 브랜치명>`을 하드코딩한다. 재현 조건: 로컬 `work`가 `origin/review/work`를 추적하거나, `origin`도 존재하지만 실제 upstream이 `fork/work`인 상태에서 정상 push하면 `origin/work`가 없어 계속 차단된다. 반대로 origin이 전혀 없으면 다른 remote에 미push 커밋이 있어도 의도대로 전부 생략된다.

[높음] template/.claude/hooks/verify-before-stop.sh:227 — “원격에 있음”의 증거가 수정 가능한 로컬 ref뿐이다. 재현 조건: 미push 커밋에서 `git update-ref refs/remotes/origin/work HEAD`를 실행하면 서버에는 아무것도 올라가지 않았지만 `origin/work..HEAD`가 0이 되어 통과한다. 네트워크를 쓰지 않는 이상 실제 push 여부를 보장할 수 없으므로 현재 보안 문구보다 약한 “로컬 관측상 백업됨” 게이트다.

[높음] template/.claude/hooks/verify-before-stop.sh:43 — push 진행 상태와 브랜치가 차단 지문에 없다. 재현 조건: 네 커밋 ahead 상태에서 Stop→한 커밋만 push를 세 번 반복하면 실제 진전에도 지문은 계속 `push|a`이고 count가 3에 도달한다. 다음 Stop에서 line 60–65가 남은 미push 커밋뿐 아니라 감사 플래그까지 지우고 통과시킨다. 서로 다른 브랜치의 push 차단도 같은 예산을 공유한다.

[중간] template/.claude/hooks/verify-before-stop.sh:228 — `rev-list --count` 실패를 “ahead 0”처럼 통과시킨다. 재현 조건: 검증과 계산 사이 ref가 사라지거나, remote-tracking ref가 읽을 수 없는 객체를 가리키거나, 저장소 객체 읽기가 실패하면 `push_n`이 빈 문자열이 되고 push 게이트가 조용히 생략된다. rc를 별도로 검사해야 한다.

[중간] template/.claude/hooks/verify-before-stop.sh:230 — remote-tracking ref 부재를 곧바로 “로컬 커밋이 원격에 없음”으로 처리한다. 재현 조건: `origin/main`에서 새 `work` 브랜치만 만들고 아직 새 커밋이 없는 상태에서도 `origin/work`가 없다는 이유로 push를 요구한다. HEAD 커밋은 이미 `origin/main`에 존재하므로 메시지와 실제 판정이 다르다.

[중간] tests/self-discipline-gates.test.sh:102 — 모든 push 테스트가 `.needs-audit`를 강제로 세워 line 25의 조기 종료 결함을 가린다. 또한 p01과 p02는 둘 다 같은 `kind=no` 픽스처라 remote ref 부재 경로만 실행하며, “한 번 push한 뒤 두 번째 로컬 커밋” 픽스처가 없어 `rev-list --count` 경로는 한 번도 검증하지 않는다.

[중간] tests/self-discipline-gates.test.sh:73 — guard 테스트가 연속된 `NAME=` 네 형태와 등호 없는 언급만 검사한다. 재현 조건: 위의 `read`, `printf -v`, 따옴표 분할, 줄 연속, 생성 스크립트 및 `git grep 'NAME=값'` 사례를 추가하면 우회 또는 위양성이 드러난다.

worktree와 슬래시 포함 브랜치는 현재 인용 방식상 특별한 결함이 없고, detached/unborn HEAD 및 origin 부재는 명시적으로 생략하도록 구현됐다. `git init -b work`는 구버전에서 실패해도 fallback이 있어 그 자체는 문제없지만, 픽스처 함수가 이후 Git 명령들의 rc를 확인하지 않아 환경별 초기화 실패를 명확한 “픽스처 실패”로 보고하지는 못한다.

판정: 보류
tokens used
71,780
검수 결과, 핵심 보장 두 개 모두 우회 가능하여 보류입니다.

[치명] template/.claude/hooks/guard-hook-disable.sh:37 — 셸을 해석하지 않고 연속된 `NAME=` 문자열만 찾으므로 간접 대입을 전혀 막지 못한다. 재현 조건: `read HARNESS_HOOKS <<< off; export HARNESS_HOOKS; claude`, `env 'HARNESS_HOOKS''=off' claude`, `HARNESS_HOOKS\\<개행>=off claude`, 변수 조립·base64·생성한 스크립트 실행은 모두 rc=0이다. `set -a`와 `printf -v` 조합, `eval` 입력 조립도 동일하다. 이 방식으로 새 프로세스의 나머지 훅을 모두 끌 수 있다.

[치명] template/.claude/hooks/verify-before-stop.sh:25 — push 판정보다 먼저 “플래그 없음”으로 종료한다. 재현 조건: 듀얼리뷰·설명·지식·감사를 선행해 `.needs-*`를 모두 지운 뒤 로컬 커밋만 만들고 push하지 않은 상태에서 Stop을 호출하면 line 25에서 rc=0으로 끝나 line 222에 도달하지 않는다. Bash로 커밋을 만들어 PostToolUse 플래그가 서지 않은 경우도 같다.

[높음] template/.claude/hooks/guard-hook-disable.sh:38 — 실행 구문과 데이터·인용문·주석을 구분하지 않아 정상 작업을 차단한다. 재현 조건: `git grep -n 'HARNESS_HOOKS=off'`, 해당 문구를 `printf`/heredoc으로 문서나 테스트 픽스처에 기록하기, `bash -c 'echo HARNESS_HOOKS=off'` 모두 실제 환경변수 대입 여부와 무관하게 rc=2다. “읽기·언급은 통과” 계약과 충돌한다.

[높음] template/.claude/hooks/verify-before-stop.sh:225 — 구성된 upstream 대신 `origin/<현재 로컬 브랜치명>`을 하드코딩한다. 재현 조건: 로컬 `work`가 `origin/review/work`를 추적하거나, `origin`도 존재하지만 실제 upstream이 `fork/work`인 상태에서 정상 push하면 `origin/work`가 없어 계속 차단된다. 반대로 origin이 전혀 없으면 다른 remote에 미push 커밋이 있어도 의도대로 전부 생략된다.

[높음] template/.claude/hooks/verify-before-stop.sh:227 — “원격에 있음”의 증거가 수정 가능한 로컬 ref뿐이다. 재현 조건: 미push 커밋에서 `git update-ref refs/remotes/origin/work HEAD`를 실행하면 서버에는 아무것도 올라가지 않았지만 `origin/work..HEAD`가 0이 되어 통과한다. 네트워크를 쓰지 않는 이상 실제 push 여부를 보장할 수 없으므로 현재 보안 문구보다 약한 “로컬 관측상 백업됨” 게이트다.

[높음] template/.claude/hooks/verify-before-stop.sh:43 — push 진행 상태와 브랜치가 차단 지문에 없다. 재현 조건: 네 커밋 ahead 상태에서 Stop→한 커밋만 push를 세 번 반복하면 실제 진전에도 지문은 계속 `push|a`이고 count가 3에 도달한다. 다음 Stop에서 line 60–65가 남은 미push 커밋뿐 아니라 감사 플래그까지 지우고 통과시킨다. 서로 다른 브랜치의 push 차단도 같은 예산을 공유한다.

[중간] template/.claude/hooks/verify-before-stop.sh:228 — `rev-list --count` 실패를 “ahead 0”처럼 통과시킨다. 재현 조건: 검증과 계산 사이 ref가 사라지거나, remote-tracking ref가 읽을 수 없는 객체를 가리키거나, 저장소 객체 읽기가 실패하면 `push_n`이 빈 문자열이 되고 push 게이트가 조용히 생략된다. rc를 별도로 검사해야 한다.

[중간] template/.claude/hooks/verify-before-stop.sh:230 — remote-tracking ref 부재를 곧바로 “로컬 커밋이 원격에 없음”으로 처리한다. 재현 조건: `origin/main`에서 새 `work` 브랜치만 만들고 아직 새 커밋이 없는 상태에서도 `origin/work`가 없다는 이유로 push를 요구한다. HEAD 커밋은 이미 `origin/main`에 존재하므로 메시지와 실제 판정이 다르다.

[중간] tests/self-discipline-gates.test.sh:102 — 모든 push 테스트가 `.needs-audit`를 강제로 세워 line 25의 조기 종료 결함을 가린다. 또한 p01과 p02는 둘 다 같은 `kind=no` 픽스처라 remote ref 부재 경로만 실행하며, “한 번 push한 뒤 두 번째 로컬 커밋” 픽스처가 없어 `rev-list --count` 경로는 한 번도 검증하지 않는다.

[중간] tests/self-discipline-gates.test.sh:73 — guard 테스트가 연속된 `NAME=` 네 형태와 등호 없는 언급만 검사한다. 재현 조건: 위의 `read`, `printf -v`, 따옴표 분할, 줄 연속, 생성 스크립트 및 `git grep 'NAME=값'` 사례를 추가하면 우회 또는 위양성이 드러난다.

worktree와 슬래시 포함 브랜치는 현재 인용 방식상 특별한 결함이 없고, detached/unborn HEAD 및 origin 부재는 명시적으로 생략하도록 구현됐다. `git init -b work`는 구버전에서 실패해도 fallback이 있어 그 자체는 문제없지만, 픽스처 함수가 이후 Git 명령들의 rc를 확인하지 않아 환경별 초기화 실패를 명확한 “픽스처 실패”로 보고하지는 못한다.

판정: 보류
