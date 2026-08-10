Reading additional input from stdin...
2026-08-10T04:15:10.652672Z ERROR codex_models_manager::cache: failed to load models cache: missing field `supports_reasoning_summaries` at line 93 column 5
OpenAI Codex v0.144.5
--------
workdir: /Users/kty/Downloads/kty-claude-harness-template
model: gpt-5.6-sol
provider: openai
approval: never
sandbox: read-only
reasoning effort: high
reasoning summaries: none
session id: 019fe9e1-b5aa-74b3-ac01-876fa58b4408
--------
user
# 검수 라운드 2 — 라운드 1 지적을 고친 델타

라운드 1(당신과 Claude 리뷰어)이 찾은 결함을 고쳤다. `_workspace/05_delta.diff` 가 그 수정이고,
전체 변경은 `_workspace/04_review.diff` 다.

## 반드시 지킬 것
- **파일을 만들거나 지우지 마라.** `mktemp`·`rm`·`>` 금지. 정적 독해로만 판정하고
  **반드시 마지막 줄에 `판정: 통과` 또는 `판정: 보류`** 를 내라.
- 지적은 `[등급] 파일:줄 — 무엇이 언제 어떻게 틀리는가` + 재현 조건.

## 무엇을 어떻게 고쳤나
1. **install.sh 사용자 파일 삭제** — 기존 훅 디렉터리 내용물을 먼저 스테이징에 `cp -R` 로
   심고 템플릿 `*.sh` 만 덮는다. 실패하면 중단(exit 1).
2. **신호 창** — 핸들러가 `hooks_swapped` 플래그가 아니라 **파일시스템 실제 상태**로 판정한다
   (`[ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]`). 플래그 변수는 삭제했다.
3. **복구 mv 실패** — rc 를 확인하고, 실패하면 "되돌렸습니다"를 찍지 않고 **백업을 지우지 않는다**.
4. **여러 줄 인용** — awk 판독기가 `OPENQ` 를 줄 너머로 이어받는다. 인용이 열린 줄은 선언
   판정에서 제외하고, EOF 까지 안 닫히면 rc=1.
5. **`<<\EOF`** — 종결어 탐지가 백슬래시 접두를 처리한다.
6. **`KEY=""#on`** — 닫는 따옴표 뒤에 공백을 요구한다. 없으면 문법 밖(rc=1).
   `KEY=#on` 은 값 `#on` 그대로. 등호 뒤 선행 공백도 문법 밖.
7. **sync.sh append 절단** — 검증을 `grep -qxF 'HARNESS_KNOWLEDGE_GATE="on"'` 완전 일치로.
8. **check-layer-boundary 범위** — `template/` + `global-agents/` 둘 다 스캔. `global-agents/`
   의 실제 누출을 걷어냈다.
9. **옛 플래그 이행** — 배포되지 않는 `install.sh` 가 옛 이름 플래그를 새 이름으로 옮긴다
   (훅이 옛 이름을 알면 층 경계 검사가 막으므로).

## 특히 봐 달라
- 위 수정들이 **새 결함을 만들지 않았나.** 특히 4·6 은 파서 의미를 바꿨다 — 정상 입력이
  rc=1 로 떨어지는 회귀가 있나?
- `OPENQ` 추적이 셸과 갈리는 지점(`$'...'`·`\'` 이스케이프·백틱·`$(...)` 안의 인용)은?
- 2번에서 플래그를 없앴는데, 파일시스템 판정만으로 **복원하면 안 되는 상황에 복원**하는
  경로가 있나?
- 1번의 `cp -R "$DST/hooks/."` 가 심링크·특수 파일·권한을 어떻게 다루나. 스테이징에 옛
  훅이 남아 템플릿에서 **삭제된** 훅이 영원히 살아남는 문제는?
- 8번에서 스캔 범위가 둘이 되며 보고 경로·개수 계산이 어긋나는 곳은?
- 테스트가 위 수정을 실제로 붙드나. 통과만 하고 안 잡는 케이스는?
codex
델타와 전체 diff를 함께 대조하고, 설치 트랜잭션·파서·경계 검사·테스트의 실제 포착력을 순서대로 정적 검수하겠습니다. 파일 변경 없이 읽기 전용 명령만 사용하겠습니다.
exec
/bin/zsh -lc "wc -l _workspace/05_delta.diff _workspace/04_review.diff && sed -n '1,240p' _workspace/05_delta.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
    1416 _workspace/05_delta.diff
    3950 _workspace/04_review.diff
    5366 total
diff --git a/install.sh b/install.sh
index 8a6c9bb..4cb0f82 100755
--- a/install.sh
+++ b/install.sh
@@ -39,10 +39,112 @@ for skill_dir in "$SRC/skills/"*/; do
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
+  # **디렉터리를 통째로 바꾸므로 기존 내용물을 먼저 스테이징으로 옮겨 심는다.**
+  # 이게 없으면 템플릿에 없는 사용자 파일(custom.sh·보조 파일·하위 디렉터리)이
+  # 재설치마다 영구 삭제된다 — 파일 단위 cp 였던 구 구현에는 없던 회귀다.
+  # 슬롯이 아니어도 사용자가 그 디렉터리에 둔 것을 하네스가 지울 권한은 없다.
+  if [ -d "$DST/hooks" ]; then
+    if ! cp -R "$DST/hooks/." "$hooks_stage/"; then
+      rm -rf "$hooks_stage" "$hooks_backup"
+      echo "✗ 기존 훅 디렉터리를 스테이징으로 복사하지 못했습니다 — 사용자 파일을 잃지 않으려고 중단합니다." >&2
+      exit 1
+    fi
+  fi
+  cp "$SRC/hooks/"*.sh "$hooks_stage/"     # 템플릿 훅만 덮어쓴다
+  chmod +x "$hooks_stage/"*.sh
+
+  on_swap_signal() {   # $1=신호 이름  $2=종료 코드
+    set +e             # 보고는 최선 노력, **종료 코드가 계약**이다
+    # 플래그가 아니라 **파일시스템 실제 상태**로 판정한다. 첫 mv 가 끝났는데 플래그를
+    # 세우기 전에 신호가 오는 창이 있고(bash 는 외부 명령 종료 뒤 대기 중인 trap 을
+    # 먼저 실행한다), 플래그를 믿으면 그 창에서 복원하지 않고 백업까지 지운다.
+    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
+      if mv "$hooks_backup/hooks" "$DST/hooks"; then
+        echo "[$1] 훅 교체 도중 중단 — 구판으로 되돌렸습니다." >&2
+        rm -rf "$hooks_stage" "$hooks_backup"
+      else
+        # 복구가 실패했다. **백업을 지우지 않는다** — 그것이 유일한 사본이다.
+        echo "[$1] 훅 교체 도중 중단됐고 **복구도 실패했습니다**." >&2
+        echo "     구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
+        echo "     손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
+        rm -rf "$hooks_stage"
+      fi
+    else
+      echo "[$1] 중단되었습니다 (훅 교체는 시작 전이거나 이미 끝났습니다)." >&2
+      rm -rf "$hooks_stage" "$hooks_backup"
+    fi
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
+  fi
+  if ! mv "$hooks_stage" "$DST/hooks"; then
+    # rename2 실패. **성공으로 오진단하지 않는다** — 되돌리고 실패로 끝낸다.
+    # 복구 mv 의 rc 를 확인한다. 실패했는데 "되돌렸습니다"를 찍고 백업을 지우면
+    # 유일한 사본이 사라진다.
+    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
+      if mv "$hooks_backup/hooks" "$DST/hooks"; then
+        echo "   구판 훅으로 되돌렸습니다." >&2
+        rm -rf "$hooks_backup"
+      else
+        echo "   **복구도 실패했습니다.** 구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
+        echo "   손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
+      fi
+    else
+      rm -rf "$hooks_backup"
+    fi
+    rm -rf "$hooks_stage"
+    echo "✗ 훅 디렉터리를 교체하지 못했습니다: $DST/hooks" >&2
+    exit 1
+  fi
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
@@ -61,6 +163,26 @@ if [ ! -f "$DST/harness/project-profile.md" ]; then
 else
   echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
 fi
+# 개명 전 플래그 이행 — **배포되지 않는 이 스크립트가 맡는다.**
+# 기존 설치본에 미처리 지식 플래그가 옛 이름으로 남아 있을 수 있는데, 새 훅은 새 이름만
+# 보므로 그대로 두면 밀린 반영 의무가 **조용히 사라진다**(하네스를 갱신했을 뿐인데).
+# 훅 쪽에서 옛 이름을 알게 하면 배포되는 글루가 구현체 이름을 다시 품어 층 경계 검사가
+# 막는다 — 그래서 이행은 여기에 있다. 새 이름이 이미 있으면 **덮지 않고 이어붙인다.**
+legacy_flag="$DST/.needs-$(printf 'vault')"
+if [ -f "$legacy_flag" ]; then
+  if [ -s "$legacy_flag" ]; then
+    if cat "$legacy_flag" >> "$DST/.needs-knowledge" 2>/dev/null; then
+      rm -f "$legacy_flag"
+      echo "   플래그 이행 ✓  미처리 지식 반영 항목을 새 이름으로 옮겼습니다"
+    else
+      echo "   ⚠ 미처리 지식 반영 플래그를 새 이름으로 옮기지 못했습니다: $legacy_flag" >&2
+      echo "     손으로 옮기지 않으면 그 항목의 반영 의무가 사라집니다." >&2
+    fi
+  else
+    rm -f "$legacy_flag"
+  fi
+fi
+
 if [ ! -f "$DST/harness/harness.env" ]; then
   cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
   echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
diff --git a/scripts/check-layer-boundary.sh b/scripts/check-layer-boundary.sh
new file mode 100755
index 0000000..b5edb6a
--- /dev/null
+++ b/scripts/check-layer-boundary.sh
@@ -0,0 +1,166 @@
+#!/usr/bin/env bash
+# check-layer-boundary.sh — 하네스 글루에 **상위 층 구현**이 새면 종료 코드 1.
+#
+# 층은 셋이고, 각자 따로 설치돼도 돌아가야 한다는 것이 요구다.
+#
+#   상위 ┃ 지식 저장소   구현체. 하네스를 모른다
+#   접착 ┃ 사용자 층     전역 CLAUDE.md — 어느 저장소를 쓰는지는 여기서만 안다
+#   하위 ┃ 하네스        계약만 소유. "설정돼 있으면 반영 없이 끝낼 수 없다"
+#
+# 소유권이 **하위**에 있는 게 핵심이다. 반대로 두면 인터페이스를 알기 위해 상위가
+# 있어야 해서 단독 작동이 깨진다. 그런데 완료를 강제하는 기계가 하네스뿐이라, 갈 곳이
+# 없는 상위 층 지식이 자꾸 글루로 흘러든다 — 실제로 13곳까지 샜었다.
+#
+# **이 경계는 grep 으로 판정 가능하다.** 조회 라우팅 같은 "행동"과 달리 "글루에 상위 층
+# 구현이 적혀 있나"는 기계가 100% 답한다. 그래서 산문 규칙으로 두지 않는다 —
+# 산문 규칙은 어겨지고, 어겨져도 아무것도 안 깨져서 아무도 모른다.
+#
+# 이 검사는 README 가 선언한 **"도메인 누출 0"을 처음으로 기계가 지키게 한다.**
+# 특정 저장소에 한정되지 않는다 — 어떤 상위 층 구현이든 같은 이유로 막힌다.
+#
+# ── 위양성 쪽으로 기운다 ─────────────────────────────────────────────
+# 관용구 패턴은 무관한 조합에도 걸릴 수 있다. 그 대가를 받아들인다 — 누출이 조용히
+# 통과하는 것보다 사람이 한 번 보고 문구를 고치는 편이 싸다. 걸렸는데 정당한 표현 같으면
+# **패턴을 좁히지 말고 그 문구를 계약 수준으로 다시 써라.** 그게 이 검사의 목적이다.
+#
+# 사용법: ./scripts/check-layer-boundary.sh
+# 회귀 테스트: ./tests/check-layer-boundary.test.sh (CI에서 이 검사보다 **먼저** 돈다)
+
+set -euo pipefail
+
+# CDPATH='' — CDPATH 가 설정된 셸에서 상대 경로로 부르면 cd 가 이동 경로를 stdout 에
+# 찍어 ROOT 가 두 줄이 된다(절대 경로 호출로는 재현 안 됨). 형제 검사기와 같은 처리.
+ROOT="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
+
+# 스캔 범위는 **배포물 전부**다. 범위를 넓히면 문서·ADR·테스트의 정당한 인용이 죄다
+# 위양성이 되므로 배포되지 않는 것은 넣지 않는다 — 이 저장소의 ADR 은 무엇이 새어
+# 있었는지 기록해야 하므로 그 표현을 반드시 담는다.
+#
+# **배포 경로가 둘이라는 것이 함정이었다.** install.sh 는 `template/.claude/` 를 프로젝트로
+# 복사하고, 그와 별도로 `global-agents/*.md` 를 `~/.claude/agents/` 로 배포한다. 범위를
+# template/ 하나로 잡았더니 global-agents/ 에 실제 누출이 있는데도 CI 가 초록이었다
+# (codex 검수에서 적발). 배포되는 것은 전부 본다.
+DEFAULT_ROOTS="$ROOT/template
+$ROOT/global-agents"
+# 회귀 테스트가 픽스처 트리를 겨누려고 이 값을 덮는다. 그 외에는 덮지 마라.
+SCAN_ROOTS="${HARNESS_LAYER_SCAN_ROOT:-$DEFAULT_ROOTS}"
+
+# 범위 중 **하나라도** 없으면 거부한다. 하나가 조용히 빠지면 그만큼 감시가 사라진다.
+while IFS= read -r r; do
+  [ -n "$r" ] || continue
+  if [ ! -d "$r" ]; then
+    echo "✗ 스캔 범위가 디렉토리가 아닙니다: $r" >&2
+    exit 1
+  fi
+done <<EOF
+$SCAN_ROOTS
+EOF
+
+WORK="$(mktemp -d)"
+if [ -z "$WORK" ] || [ ! -d "$WORK" ]; then
+  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2
+  exit 1
+fi
+trap 'rm -rf "$WORK"' EXIT
+
+# ── 금지 표현 ─────────────────────────────────────────────────────────
+# 한 줄에 `ERE 패턴<TAB>왜 상위 층인가`. 메시지가 있어야 걸린 사람이 무엇을 계약 수준으로
+# 다시 써야 하는지 안다. "금지됐다"만 알려주는 검사는 우회당한다.
+# 히어독을 **인용**한다(<<'PATTERNS'): 패턴 안의 $ · 백슬래시가 셸에 먹히면 안 된다.
+PATTERNS_FILE="$WORK/patterns"
+cat > "$PATTERNS_FILE" <<'PATTERNS'
+second[ -]brain	특정 지식 저장소의 이름. 하네스는 저장소가 무엇인지 몰라야 한다
+[Oo]bsidian	특정 도구 이름. 저장소를 바꾸면 이 문구가 거짓이 된다
+볼트	특정 지식 저장소의 이름
+_CLAUDE\.md	상위 층 저장소 안의 파일 이름. 그 파일이 없는 환경에서는 지킬 수 없는 요구가 된다
+4종 세트	상위 층이 지식을 어느 파일로 나눠 담는지의 구조. 하네스가 알 필요 없다
+discussion-log	상위 층 저장소의 파일 이름
+Projects/<name>	상위 층 저장소의 폴더 구조
+needs-vault	구현체 이름이 붙은 플래그. 계약 이름(.needs-knowledge)을 써라
+PATTERNS
+
+# ── 사전 조건: 스캔할 수 없는 대상이 있으면 결과 전체를 믿을 수 없다 ──
+# 형제 검사기(check-rule-copies.sh)의 ①②③ 과 같은 층위다. 심링크가 있으면 grep -r 은
+# 건너뛰는데 install.sh 의 cp 는 실체를 배포한다 — 검사되지 않은 파일이 배포되는 창이
+# 열린다. NUL 보유 파일은 토큰 바이트열이 원리적으로 안 보인다(UTF-16 도 같은 층위).
+#
+# find -print0 을 **파일로 받는다.** 명령 치환으로 받으면 셸이 NUL 을 버려 루프가 한 번도

exec
/bin/zsh -lc "sed -n '241,520p' _workspace/05_delta.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
+# 안 돌고, 검사기는 "위반 0건"으로 초록불을 낸다.
+FILES="$WORK/files"
+: > "$FILES"
+while IFS= read -r r; do
+  [ -n "$r" ] || continue
+  find "$r" -print0 >> "$FILES"
+done <<EOF
+$SCAN_ROOTS
+EOF
+
+bad_pre=0
+while IFS= read -r -d '' p; do
+  if [ -L "$p" ]; then
+    echo "✗ 심링크가 스캔 범위 안에 있습니다: ${p#"$ROOT"/}" >&2
+    bad_pre=1
+    continue
+  fi
+  [ -f "$p" ] || continue
+  if ! LC_ALL=C tr -d '\000' < "$p" | cmp -s - "$p"; then
+    echo "✗ NUL 바이트를 가진 파일이 있어 내용을 믿을 수 없습니다: ${p#"$ROOT"/}" >&2
+    bad_pre=1
+  fi
+done < "$FILES"
+
+if [ "$bad_pre" -ne 0 ]; then
+  echo "" >&2
+  echo "스캔할 수 없는 대상이 트리에 있으면 그 트리에 대한 스캔 결과 전체를 믿을 수 없습니다." >&2
+  echo "제거한 뒤 다시 돌리세요." >&2
+  exit 1
+fi
+
+# ── 스캔 ─────────────────────────────────────────────────────────────
+# hits 를 파이프·서브셸 안에서 올리면 증가분이 부모로 안 돌아온다(서브셸 변수 누수).
+# 그래서 출력은 모아 두고 개수는 파일로 센다.
+REPORT="$WORK/report"
+: > "$REPORT"
+scanned=0
+
+while IFS= read -r -d '' f; do
+  [ -f "$f" ] || continue
+  scanned=$((scanned + 1))
+  rel="${f#"$ROOT"/}"
+  while IFS="$(printf '\t')" read -r pat why; do
+    [ -n "$pat" ] || continue
+    # grep rc: 0=매치 1=무매치 **2 이상=오류**. `|| true` 로 뭉뚱그리면 읽기 실패까지
+    # 삼켜 스캔이 통째로 실패해도 조용히 초록이 된다.
+    set +e
+    out="$(grep -nE -- "$pat" "$f")"
+    rc=$?
+    set -e
+    if [ "$rc" -ge 2 ]; then
+      echo "✗ 스캔 실패(rc=$rc): $rel  패턴 [$pat]" >&2
+      exit 1
+    fi
+    if [ "$rc" -eq 0 ]; then
+      printf '%s\n' "$out" | sed "s|^|  $rel:|" >> "$REPORT"
+      printf '      ↑ %s\n' "$why" >> "$REPORT"
+    fi
+  done < "$PATTERNS_FILE"
+done < "$FILES"
+
+# 스캔 대상이 0개면 "0건 위반"을 찍고 통과한다 — 공허한 초록이다.
+# 배포물이 하나도 없을 리 없으므로 그건 범위 설정이 틀린 것이다.
+if [ "$scanned" -eq 0 ]; then
+  echo "✗ 스캔한 파일이 0개입니다 (범위 설정을 확인하세요):" >&2
+  printf '%s\n' "$SCAN_ROOTS" | sed 's/^/    /' >&2
+  exit 1
+fi
+
+if [ -s "$REPORT" ]; then
+  cat "$REPORT" >&2
+  echo "" >&2
+  echo "✗ 하네스 글루에 상위 층 구현이 샜습니다." >&2
+  echo "  계약만 남기고 구현은 사용자 층으로 옮기세요 — 하네스는 지식 저장소가" >&2
+  echo "  어디이고 어떤 구조인지 몰라야 그 저장소 없이도 돌아갑니다." >&2
+  exit 1
+fi
+
+echo "✓ 층 경계 유지 — 배포물 ${scanned}개에 상위 층 구현 0건"
diff --git a/sync.sh b/sync.sh
index 898f1dd..cdf1416 100755
--- a/sync.sh
+++ b/sync.sh
@@ -106,12 +106,18 @@ echo ""
 # 실제로 읽히는지 확인하고, 안 읽히면 조용히 넘어가지 않고 알린다.
 if [ "$add_gate_key" -eq 1 ]; then
   envf="$DST/harness/harness.env"
+  # 검증은 **완성된 줄 전체**를 요구한다. `^HARNESS_KNOWLEDGE_GATE=` 로만 보면
+  # append 가 등호 직후에서 잘려 `HARNESS_KNOWLEDGE_GATE=` 만 남은 경우까지 통과시키는데,
+  # 그 잘린 줄은 파서에게 **완벽히 유효한 "리터럴 빈 값"** 이라 게이트를 끈다.
+  # 즉 "실패 방향은 안전하다"가 이 한 지점에서만 성립하지 않아서, 여기서 막는다.
   if { printf '\n# 지식 반영 게이트 (하네스가 나중에 추가한 슬롯). 끄려면 값을 비운다 —\n# "off" 라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다. 이 줄이 없어도 켜짐이다.\nHARNESS_KNOWLEDGE_GATE="on"\n' >> "$envf"; } 2>/dev/null \
-     && grep -qE '^HARNESS_KNOWLEDGE_GATE=' "$envf" 2>/dev/null; then
+     && grep -qxF 'HARNESS_KNOWLEDGE_GATE="on"' "$envf" 2>/dev/null; then
     echo "   슬롯 키 추가 ✓  harness/harness.env  HARNESS_KNOWLEDGE_GATE=\"on\""
   else
-    echo "   ⚠ harness/harness.env 에 HARNESS_KNOWLEDGE_GATE 를 추가하지 못했습니다(권한·디스크)." >&2
-    echo "     동작은 그대로입니다(키가 없으면 켜짐). 손으로 넣으려면 위 한 줄을 추가하세요." >&2
+    echo "   ⚠ harness/harness.env 에 HARNESS_KNOWLEDGE_GATE 를 온전히 추가하지 못했습니다." >&2
+    echo "     **파일 끝에 잘린 줄이 남았을 수 있습니다.** 그 상태로 두면 지식 게이트가" >&2
+    echo "     꺼진 것으로 읽힐 수 있으니 파일 끝을 직접 확인하고, 다음 한 줄로 고치세요:" >&2
+    echo '       HARNESS_KNOWLEDGE_GATE="on"' >&2
   fi
 fi
 
diff --git a/template/.claude/harness/project-profile.template.md b/template/.claude/harness/project-profile.template.md
index 669773c..af3b0c6 100644
--- a/template/.claude/harness/project-profile.template.md
+++ b/template/.claude/harness/project-profile.template.md
@@ -115,7 +115,28 @@
 
 ---
 
-## 9. 참고 — 전역 의존 (이 프로젝트가 기대는 참조 시스템)
+## 9. 지식 진입점 (knowledge entry)
+`[읽는 이: ecc:architect · ecc:planner — 착수 **전**에 이 경로를 읽는다]`
+
+> 이 프로젝트에 관해 **전에 무엇을 정했는지** 를 찾아 들어가는 단 하나의 경로.
+> 하네스는 그 너머의 구조를 모른다 — 경로 하나만 알고, 분류·형식은 그쪽 규약이 정한다.
+>
+> **왜 필요한가:** 지금까지 지식은 쓰기 전용이었다. 착수 전에 회수하는 단계가 없어
+> 같은 결정을 매번 다시 내리고, 그 재결정이 또 저장됐다. 이 슬롯이 반대 방향을 연다.
+
+- **진입점:** {{지식 저장소에서 이 프로젝트로 들어가는 경로 — 인덱스·목차 파일 하나}}
+- 비워두면 회수 단계를 생략한다(회수할 지식이 아직 없는 새 프로젝트).
+
+`ecc:architect`·`ecc:planner` 는 착수 전 이 경로를 읽고, 산출물 **첫 줄**에
+`사전 결정 회수: <읽은 경로>` 를 낸다. 읽을 것이 없었으면 `사전 결정 회수: 없음(<사유>)`.
+
+**이 줄은 존재·형식만 검증된다.** 진짜 읽었는지는 기계가 못 본다 — 강제가 아니라 표명이다.
+그 한계를 알고도 두는 이유는, 표명조차 없으면 회수 단계가 있었는지 **사후에도** 알 수 없기
+때문이다.
+
+---
+
+## 10. 참고 — 전역 의존 (이 프로젝트가 기대는 참조 시스템)
 `[정보용: 사람이 읽는 메모. 에이전트는 각자 필요한 참조를 직접 호출]`
 
 - **ECC 룰:** `~/.claude/rules/ecc/` — 언어 일반 코딩/테스트/보안 표준(항상 로드).
diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
index 997b8e0..7fe0551 100644
--- a/template/.claude/hooks/_common.sh
+++ b/template/.claude/hooks/_common.sh
@@ -11,6 +11,9 @@ EXPLAIN_FLAG="$STATE_DIR/.needs-explain"
 # 지식 저장소 반영 게이트. 이름은 **계약 수준**이다 — 예전 이름은 특정 구현체를 가리켰고,
 # 그래서 그 구현체를 안 쓰는 환경에서 하네스가 없는 구조를 요구하게 됐다.
 KNOWLEDGE_FLAG="$STATE_DIR/.needs-knowledge"
+# 개명 전 이름의 미처리 플래그는 **install.sh 가 갱신 시점에 새 이름으로 옮긴다.**
+# 여기서 옛 이름을 알면 배포되는 글루가 구현체 이름을 다시 품게 되고, 층 경계 검사가
+# (옳게) 막는다. 배포되지 않는 설치 스크립트가 이행을 맡는 것이 층에 맞다.
 DUALREVIEW_FLAG="$STATE_DIR/.needs-dualreview"
 BLOCK_COUNT="$STATE_DIR/.stop-block-count"
 BLOCK_FP="$STATE_DIR/.stop-block-fp"    # 마지막 차단 지문(게이트|플래그 상태) — 진전 인지 리셋용
@@ -54,8 +57,8 @@ hook_disabled() {
 # 세어진다. 셋 다 눈에 보이지 않는다.
 #
 # 그래서 **순서가 계약이다**:
-#   ① 파일 첫머리 BOM 제거 → ② 각 줄 후행 CR 제거 → ③ 히어독 본문 배제 →
-#   ④ 선언 판정 → ⑤ 값 앞 공백 절단 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 **밖** 후행 주석
+#   ① 파일 첫머리 BOM 제거 → ② 각 줄 후행 CR 제거 → ③ **줄을 넘는 인용 상태** 추적 →
+#   ④ 히어독 본문 배제 → ⑤ 선언 판정 → ⑥ 따옴표 벗기기 → ⑦ 따옴표 **밖** 후행 주석
 #   → ⑧ 남은 후행 공백 절단
 #
 # ── 반환 계약 ──────────────────────────────────────────────────────────
@@ -71,21 +74,26 @@ hook_disabled() {
 # ── 지원 문법 (좁게 고정했다. 이 밖은 전부 rc=1) ───────────────────────
 #   KEY=값  ·  export KEY=값   (export 뒤는 공백 또는 탭)
 #   값: "겹따옴표"  ·  '홑따옴표'  ·  인용 없는 평문
-#   따옴표 뒤에는 공백과 `# 주석` 만 올 수 있다
-#   인용 없는 값은 **공백에 이어지는 `#`** 부터가 주석이다 (`a#b` 의 `#` 은 값의 일부)
-#   값 자리가 `#` 로 시작하면 값은 비어 있는 것으로 본다
+#   닫는 따옴표 뒤에는 **공백**과 `# 주석` 만 올 수 있다 (`""#on` 은 문법 밖 — 셸에서
+#     그 값은 `#on` 이라 비어 있지 않은데, 주석으로 읽으면 게이트가 꺼지는 방향이다)
+#   인용 없는 값은 **공백에 이어지는 `#`** 부터가 주석이다 (`a#b`·`#on` 은 값 그대로)
 # ── 지원하지 않는 것 (조용히 절반만 읽지 않고 rc=1 로 떨어진다) ────────
-#   백슬래시 이스케이프 · 한 줄에 인용 조각 여러 개(`"a"b`) · 여러 줄 값 ·
-#   닫히지 않은 따옴표
+#   등호 바로 뒤의 공백(`KEY= x`) · 백슬래시 이스케이프 · 한 줄에 인용 조각 여러 개 ·
+#   여러 줄 값 · 닫히지 않은 따옴표
 #
 # 판독 모델: **선행 공백이 없는 최상위 대입만** 선언으로 센다. 조건문·함수 본문 안의
 # 대입은 실행되지 않을 수도 있어 원문만으로는 발효 여부를 알 수 없다.
 # 선언이 2개 이상이면 어느 것이 이기는지 원문으로 알 수 없으므로 rc=1 이다.
 #
-# 히어독: `<<WORD`·`<<-WORD`·`<<'WORD'` 을 **따옴표 상태를 보며** 찾아 본문을 건너뛴다
-# (`"a << b"` 는 히어독이 아니다). 탐지가 어느 쪽으로 틀려도 결과는 rc=1 로 수렴한다 —
-# 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다. EOF 까지 안 닫히면
-# 탐지가 빗나간 것이므로 역시 rc=1. 한 줄에 히어독이 둘이면 첫 개만 본다.
+# **인용 상태는 줄을 넘어 이어진다.** 셸의 인용은 개행에서 끝나지 않으므로, 다른 키의
+# 여러 줄 값 본문 안에 이 키가 나타나도 그건 선언이 아니다. 이걸 줄 단위로만 보면
+# `NOTES='...(개행)KEY=(개행)...'` 이 유일한 선언으로 판독돼 게이트가 꺼진다(실측).
+#
+# 히어독: `<<WORD`·`<<-WORD`·`<<'WORD'`·`<<"WORD"`·`<<\WORD` 를 인용 상태를 보며 찾아
+# 본문을 건너뛴다(`"a << b"` 는 히어독이 아니다). 탐지가 어느 쪽으로 틀려도 결과는 rc=1 로
+# 수렴한다 — 히어독을 놓치면 선언이 2개가 되고, 없는 히어독을 만들면 0개가 된다.
+# EOF 까지 히어독이나 인용이 안 닫히면 파일을 못 믿는 것이므로 역시 rc=1.
+# 한 줄에 히어독이 둘이면 첫 개만 본다.
 #
 # 알려진 한계: 값 안의 `$VAR`·`$(...)` 는 **판독 시점에 확장되지 않는다** — 원문 그대로
 # 값이 된다. 다만 그 값은 결국 `sh -c` 로 넘어가므로 **실행 시점에는 확장된다**
@@ -107,30 +115,42 @@ function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
 function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
 
 # 히어독 시작을 찾는다. 따옴표 안의 `<<` 와 주석 뒤의 `<<` 는 히어독이 아니다.
-function scan_heredoc(s,   n, i, j, c, q, t, dash) {
-  n = length(s); i = 1; q = ""
+# 인용 상태 OPENQ 는 **줄을 넘어 이어진다.** 셸의 인용은 개행에서 끝나지 않기 때문이다 —
+# 다른 키의 여러 줄 값 본문 안에 우리 키가 있으면 그건 선언이 아니다. 이걸 줄 단위로만
+# 보면 다른 키의 여러 줄 값 안에 있는 우리 키가 유일한 선언으로 판독돼
+# **게이트가 꺼진다**(실측). 그래서 이 함수는 줄마다 OPENQ 를 이어받아 갱신한다.
+function scan_line(s,   n, i, j, c, t, dash) {
+  n = length(s); i = 1
   while (i <= n) {
     c = substr(s, i, 1)
-    if (q != "") { if (c == q) q = ""; i++; continue }
-    if (c == "\"" || c == SQ) { q = c; i++; continue }
+    if (OPENQ != "") { if (c == OPENQ) OPENQ = ""; i++; continue }
+    if (c == "\\") { i += 2; continue }                            # 백슬래시 이스케이프
+    if (c == "\"" || c == SQ) { OPENQ = c; i++; continue }
     if (c == "#" && (i == 1 || substr(s, i - 1, 1) == " " || substr(s, i - 1, 1) == "\t")) return
     if (c == "<" && substr(s, i + 1, 1) == "<") {
-      if (substr(s, i + 2, 1) == "<") { i += 3; continue }        # <<< 는 히어스트링
+      if (substr(s, i + 2, 1) == "<") { i += 3; continue }         # <<< 는 히어스트링
       j = i + 2; dash = 0
       if (substr(s, j, 1) == "-") { dash = 1; j++ }
       while (substr(s, j, 1) == " " || substr(s, j, 1) == "\t") j++
-      t = ""; c = substr(s, j, 1)
-      if (c == "\"" || c == SQ) {                                  # <<"EOF" · <<EOF
+      t = ""
+      # 종결어 인용은 세 형태다: 인용 없음 · 따옴표로 감싼 형태 · 백슬래시 접두
+      # 백슬래시 형태를 빠뜨리면 본문을 안 건너뛰어 그 안의 키가 선언으로 세어진다.
+      c = substr(s, j, 1)
+      if (c == "\\") j++
+      c = substr(s, j, 1)
+      if (c == "\"" || c == SQ) {
         j++
         while (j <= n && substr(s, j, 1) != c) { t = t substr(s, j, 1); j++ }
+        j++
       } else {
         while (j <= n) {
           c = substr(s, j, 1)
           if (c ~ /[A-Za-z0-9_.\/-]/) { t = t c; j++ } else break
         }
       }
-      if (t != "") { INHD = 1; HTERM = t; HDASH = dash }
-      return
+      if (t != "") { INHD = 1; HTERM = t; HDASH = dash; return }
+      i = j
+      continue
     }
     i++
   }
@@ -138,26 +158,33 @@ function scan_heredoc(s,   n, i, j, c, q, t, dash) {
 
 # 지원 문법대로 값을 판독한다. 문법 밖이면 BAD 를 세운다(빈 값으로 위장하지 않는다).
 function parse_value(v,   q, rest, e, out, tail, i, c, p) {
-  # 여기서는 **앞** 공백만 턴다. 뒤 공백은 갈래마다 다른 자리에서 털린다 —
-  # 인용 값은 닫는 따옴표 뒤(tail)에서, 인용 없는 값은 반환 직전 rtrim(out) 에서.
-  # 여기서 한 번 더 rtrim 하면 어느 변이로도 죽지 않는 죽은 줄이 된다(변이 측정으로 확인).
-  v = ltrim(v)
   if (v == "") return ""
+  # **등호 바로 뒤의 공백은 지원하지 않는다(rc=1).** 셸은 `KEY= x` 를 "빈 값 대입 + 명령 x"
+  # 로 읽는데, 관대하게 값으로 삼으면 셸과 반대 방향으로 갈리고, 빈 값으로 삼으면
+  # `KEY=  "on"` 이 조용히 게이트를 끈다. 어느 쪽도 안전하지 않아 문법 밖으로 돌린다.
+  if (substr(v, 1, 1) == " " || substr(v, 1, 1) == "\t") { BAD = 1; return "" }
   q = substr(v, 1, 1)
   if (q == "\"" || q == SQ) {
     rest = substr(v, 2)
     e = index(rest, q)
     if (e == 0) { BAD = 1; return "" }                             # 닫히지 않은 따옴표
     out = substr(rest, 1, e - 1)
-    tail = ltrim(substr(rest, e + 1))
-    if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음
+    tail = substr(rest, e + 1)
+    if (tail != "") {
+      # 닫는 따옴표 **바로 뒤**에는 공백이 와야 한다. `KEY=""#on` 은 셸에서 값이 `#on`
+      # (비어 있지 않다)인데, 여기서 `#` 을 주석으로 받으면 빈 값이 되어 **게이트가 꺼진다.**
+      if (substr(tail, 1, 1) != " " && substr(tail, 1, 1) != "\t") { BAD = 1; return "" }
+      tail = ltrim(tail)
+      if (tail != "" && substr(tail, 1, 1) != "#") { BAD = 1; return "" }   # 따옴표 뒤 잡음

exec
/bin/zsh -lc "sed -n '521,820p' _workspace/05_delta.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
+    }
     return out
   }
-  if (q == "#") return ""                                          # 값 자리가 통째로 주석
+  # 인용 없는 값에서 `#` 은 **공백 뒤에서만** 주석을 연다. `KEY=#on` 의 값은 셸에서
+  # `#on` 이다 — 여기서 빈 값으로 읽으면 그 역시 게이트를 끄는 방향이다.
   out = ""
   for (i = 1; i <= length(v); i++) {
     c = substr(v, i, 1)
-    if (c == "#") {
+    if (c == "#" && i > 1) {
       p = substr(v, i - 1, 1)
       if (p == " " || p == "\t") break
     }
@@ -168,7 +195,7 @@ function parse_value(v,   q, rest, e, out, tail, i, c, p) {
 
 BEGIN {
   SQ = sprintf("%c", 39)
-  N = 0; FOUND = ""; INHD = 0; HTERM = ""; HDASH = 0; BAD = 0
+  N = 0; FOUND = ""; INHD = 0; HTERM = ""; HDASH = 0; BAD = 0; OPENQ = ""
   RX = "^(export[ \t]+)?" key "="
 }
 {
@@ -183,15 +210,21 @@ BEGIN {
     next
   }
 
-  # 선언 판정이 히어독 시작 판정보다 **먼저**다: `KEY=v <<EOF` 의 대입은 실제로 발효한다.
-  if (line ~ RX) {
-    N++
-    if (N == 1) FOUND = substr(line, index(line, "=") + 1)
+  # **인용이 이전 줄에서 열린 채면 이 줄은 값의 본문이지 선언이 아니다.**
+  # 이 검사가 없으면 다른 키의 여러 줄 값 안에 있는 우리 키가 유일한 선언으로 판독돼
+  # 게이트가 꺼진다(실측). 판정 전에 물어야 한다.
+  if (OPENQ == "") {
+    # 선언 판정이 히어독 시작 판정보다 **먼저**다: `KEY=v <<EOF` 의 대입은 실제로 발효한다.
+    if (line ~ RX) {
+      N++
+      if (N == 1) FOUND = substr(line, index(line, "=") + 1)
+    }
   }
-  scan_heredoc(line)
+  scan_line(line)
 }
 END {
   if (INHD) exit 1          # 히어독이 EOF 까지 안 닫혔다 = 탐지가 빗나갔다
+  if (OPENQ != "") exit 1   # 인용이 EOF 까지 안 닫혔다 = 파일을 못 믿는다
   if (N != 1) exit 1
   v = parse_value(FOUND)
   if (BAD) exit 1
diff --git a/template/.claude/hooks/mark-needs-audit.sh b/template/.claude/hooks/mark-needs-audit.sh
index 99109e1..5ce8262 100644
--- a/template/.claude/hooks/mark-needs-audit.sh
+++ b/template/.claude/hooks/mark-needs-audit.sh
@@ -9,7 +9,8 @@
 #   프로젝트 안       — _workspace/·.claude/·순수 *.md|*.markdown(대소문자 무관) 를 뺀 전부
 #   밖 + 하네스 정본  — 저장소(루트에 template/.claude/) **전체**를 프로젝트와 같은 규칙으로
 #   밖 + 그 외        — .claude/ 앵커에 걸린 하네스 파일만 (git 저장소일 필요 없음)
-#   설계·계획 산출물  — 위치·git 무관하게 _workspace/00_design*.md·01_plan*.md 는 듀얼리뷰만
+#   설계·계획 산출물  — 위치·git 무관하게 _workspace/00_design*.md·01_plan*.md 는 듀얼리뷰+지식
+#   결정 문서        — docs/decisions/*.md 는 문서 제외의 예외로 지식만
 #
 # 왜 이렇게 넓나 (2026-08-04 실사고): 하네스 자신을 고치는 작업은 **늘** 별도 클론에서
 # 일어나는데 훅이 프로젝트 밖을 통째로 스킵해, 게이트가 프로젝트는 지키면서 정작 하네스
@@ -152,7 +153,7 @@ harness_anchor() {
   return 1
 }
 
-# classify <기준 상대경로> <기준 디렉토리> — gate 또는 skip 을 stdout 에.
+# classify <기준 상대경로> <기준 디렉토리> — gate · knowledge · skip 을 stdout 에.
 # 프로젝트 안(4a)과 밖-하네스정본(4b)이 **같은 규칙**을 쓰도록 공유한다.
 #
 # 순서가 계약이다:
@@ -177,6 +178,16 @@ classify() {
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
@@ -235,10 +246,16 @@ abs="$(physical_path "$file_path")"
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
 
@@ -270,6 +287,12 @@ else
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
diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
index 324c882..756a92d 100644
--- a/template/.claude/hooks/verify-before-stop.sh
+++ b/template/.claude/hooks/verify-before-stop.sh
@@ -178,8 +178,8 @@ fi
 #     (2026-08-02 kty — 산문 규칙이 세션 내내 0회 이행된 실사고의 기계화)
 #
 #     **이 훅이 아는 것은 계약 하나뿐이다**: "지식 저장소가 설정돼 있으면, 결정·설계가
-#     나온 턴은 반영 없이 끝낼 수 없다." 저장소가 어디인지·어떤 구조인지·무엇을 4종
-#     세트라 부르는지는 **상위 층의 구현**이고 이 파일은 모른다. 알게 되면 그 저장소를
+#     나온 턴은 반영 없이 끝낼 수 없다." 저장소가 어디인지·어떤 구조인지·무엇을 어느
+#     파일에 나눠 담는지는 **상위 층의 구현**이고 이 파일은 모른다. 알게 되면 그 저장소를
 #     안 쓰는 환경에서 하네스가 없는 구조를 요구하게 된다(제0원칙 4 — 구체가 아닌 계약).
 #     어디에 어떻게 저장했는지의 검증은 그 저장소 자신의 규약이 한다.
 if knowledge_gate_active && ! hook_disabled "stop:knowledge"; then
diff --git a/template/.claude/skills/harness-orchestrator/SKILL.md b/template/.claude/skills/harness-orchestrator/SKILL.md
index 7a4bfd2..e96246b 100644
--- a/template/.claude/skills/harness-orchestrator/SKILL.md
+++ b/template/.claude/skills/harness-orchestrator/SKILL.md
@@ -27,8 +27,8 @@ description: 이 프로젝트의 개발 작업 전체를 조율하는 오케스
 | 에이전트 | 주입할 프로필 섹션 | 추가 동봉 |
 |---|---|---|
 | clarifier | §1 정체성 · §8 도메인 예시 | mem-search 결과 |
-| ecc:architect (설계) | §2 · §4 · §5 | principles.md · mem-search 결과 · dispatch 계약(아래) |
-| ecc:planner (계획) | §2 스택 · §4 불변식 · §5 경계면 · §7 vcs | principles.md · mem-search 결과 · (구조적이면) 설계서 경로 · dispatch 계약(아래) |
+| ecc:architect (설계) | §2 · §4 · §5 · **9절 지식 진입점** | principles.md · mem-search 결과 · dispatch 계약(아래) |
+| ecc:planner (계획) | §2 스택 · §4 불변식 · §5 경계면 · §7 vcs · **9절 지식 진입점** | principles.md · mem-search 결과 · (구조적이면) 설계서 경로 · dispatch 계약(아래) |
 | plan-reviewer | §4 · §5 · §7 | principles.md |
 | developer | §2 · §3 검증 · §4 · §5 | principles.md · 계획서 경로 · harness.env(타입체크 정본) |
 | ecc:code-reviewer (검수) | §3 · §4 · §5 | principles.md · harness.env · dispatch 계약(아래) |
@@ -46,8 +46,8 @@ description: 이 프로젝트의 개발 작업 전체를 조율하는 오케스
 
 | 에이전트 | 역할 | dispatch 시 프롬프트로 요구할 것 |
 |---|---|---|
-| `ecc:architect` | 설계서 (구조적 변경만) | 출력 형식: 설계 목표 / 모듈 경계(공개 인터페이스 시그니처 수준) / 데이터 흐름 / 패턴 선택과 대안(결정·대안·트레이드오프 필수 — 대안 없는 설계서는 검증 불가) / 기존 구조 영향(파일:라인 근거) / 마이그레이션 순서 힌트. 구조적이지 않다고 판명되면 억지 설계 말고 "planner 직행 권고" 반환 → 오케스트레이터가 `_workspace/00_design.md` 저장 |
-| `ecc:planner` | 구현 계획서 | 출력 형식: 목표 / 영향 범위(파일:라인) / 모듈 경계(제0원칙 — '실제로 바뀔 축'만) / 단계(PR 단위, 단계마다 검증 방법·리스크) / 리스크·롤백 / 테스트 계획. 요구가 실은 모호하면 강행 말고 "clarifier 회부 필요" 반환 → 오케스트레이터가 `_workspace/01_plan.md` 저장 |
+| `ecc:architect` | 설계서 (구조적 변경만) | 출력 **첫 줄**: `사전 결정 회수: <읽은 경로>` (프로필 9절의 진입점을 착수 **전**에 읽는다. 비었거나 읽을 것이 없으면 `사전 결정 회수: 없음(<사유>)`). 이어서 — 출력 형식: 설계 목표 / 모듈 경계(공개 인터페이스 시그니처 수준) / 데이터 흐름 / 패턴 선택과 대안(결정·대안·트레이드오프 필수 — 대안 없는 설계서는 검증 불가) / 기존 구조 영향(파일:라인 근거) / 마이그레이션 순서 힌트. 구조적이지 않다고 판명되면 억지 설계 말고 "planner 직행 권고" 반환 → 오케스트레이터가 `_workspace/00_design.md` 저장 |
+| `ecc:planner` | 구현 계획서 | 출력 **첫 줄**: `사전 결정 회수: <읽은 경로>` (프로필 9절의 진입점을 착수 **전**에 읽는다. 비었거나 읽을 것이 없으면 `사전 결정 회수: 없음(<사유>)`). 이어서 — 출력 형식: 목표 / 영향 범위(파일:라인) / 모듈 경계(제0원칙 — '실제로 바뀔 축'만) / 단계(PR 단위, 단계마다 검증 방법·리스크) / 리스크·롤백 / 테스트 계획. 요구가 실은 모호하면 강행 말고 "clarifier 회부 필요" 반환 → 오케스트레이터가 `_workspace/01_plan.md` 저장 |
 | `ecc:code-reviewer` | 코드 검수 | ① 판정 줄 필수: `판정: 통과/보류` — CRITICAL 1건이면 보류 ② 지적마다 심각도(CRITICAL/HIGH/MEDIUM/LOW) + "어떤 입력 → 어떤 잘못된 결과" 시나리오 ③ 지적마다 카테고리 태그 `[경계면] [불변식] [제0원칙] [품질] [테스트] [성능] [접근성]`…(진화 신호 축적용) ④ §3 타입체크·테스트 명령을 직접 실행해 확인(보고만 믿지 않기) ⑤ developer 출력의 `방법론: superpowers:test-driven-development 따름` 줄 확인 — 없으면 미준수 지적 ⑥ §5 경계면은 양쪽 코드를 동시에 열어 shape 교차 비교 ⑦ 수정하지 않기 — 관찰·판정만 |
 | `ecc:security-reviewer` | 보안 검수 (트리거 시만) | ① 판정 줄 필수: `판정: 통과/차단` — CRITICAL 1건이면 차단 ② **수정 금지** — 발견·판정만(Edit/Write 도구가 있어도 사용하지 않게 명시) ③ 지적마다 "어떤 입력 → 어떤 경로 → 무슨 피해" 시나리오(입력→도달 경로를 실제 코드로 특정) ④ 시크릿이 이미 커밋됐으면 로테이션 필요 명시(히스토리 제거만으론 불안전) ⑤ 확신 없는 항목은 "미확인 — 검증 방법"으로 분류, 통과로 밀지 않기 |
 
@@ -93,6 +93,7 @@ codex exec --sandbox read-only -m gpt-5.6-sol -c model_reasoning_effort="high" "
 
 **구조적 변경이면 (2-pass):**
 1. `ecc:architect`를 dispatch 계약대로 호출해 설계서를 받는다 — 모듈 경계·계약·패턴·대안 트레이드오프. 오케스트레이터가 `_workspace/00_design.md`에 저장.
+   **첫 줄에 `사전 결정 회수:` 가 있는지 확인한다** — 없으면 회수 단계를 건너뛴 것이므로 되돌린다. 이 줄은 존재·형식만 검증된다(진짜 읽었는지는 기계가 못 본다 — 강제가 아니라 표명이다).
 2. `plan-reviewer` **1차 pass(설계만)**: 제0원칙·계약 명시성·불변식 충돌·과설계를 검증. 보류면 ecc:architect로 루프.
 3. `ecc:planner`가 설계서를 입력으로 구현 계획서를 작성. 오케스트레이터가 `_workspace/01_plan.md`에 저장.
 4. `plan-reviewer` **2차 pass(계획+정합성)**: 기존 점검 전체 + 설계↔계획 정합성. 보류면 ecc:planner로 루프.
diff --git a/tests/check-layer-boundary.test.sh b/tests/check-layer-boundary.test.sh
new file mode 100755
index 0000000..b576899
--- /dev/null
+++ b/tests/check-layer-boundary.test.sh
@@ -0,0 +1,238 @@
+#!/usr/bin/env bash
+# check-layer-boundary.test.sh — 층 경계 검사기의 회귀 테스트.
+#
+# 이 검사기의 유일한 치명 결함은 **위음성**이다. 누출을 통과시키는 순간 층 경계는
+# 다시 산문으로 돌아가고, 산문 규칙은 어겨져도 아무것도 안 깨져서 아무도 모른다.
+# 그래서 케이스마다 "그 패턴 **하나만**" 심은 픽스처를 쓴다 — 한 패턴을 목록에서
+# 지웠을 때 **그 케이스만** 빨개져야 방어를 지키는 것이다. 다른 케이스가 대신
+# 빨개지는 것은 그 방어를 지키는 게 아니다.
+#
+# 사전 조건(심링크·NUL·빈 범위)도 케이스로 붙든다. "스캔할 수 없는 대상이 트리에
+# 있으면 결과 전체를 믿을 수 없다"는 계약이고, 그 계약이 사라지면 검사되지 않은
+# 파일이 배포되는 창이 조용히 열린다.
+#
+# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트라 -e 는 러너 자신을 죽인다.
+# 셸 이식성: macOS 기본 bash 는 3.2 다.
+#
+# 사용법: ./tests/check-layer-boundary.test.sh
+
+set -uo pipefail
+
+TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
+REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
+CHECKER="$REPO_ROOT/scripts/check-layer-boundary.sh"
+
+[ -f "$CHECKER" ] || { echo "✗ 검사기를 찾지 못했습니다: $CHECKER" >&2; exit 1; }
+
+TMPROOT="$(mktemp -d)" || exit 1
+if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
+  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2
+  exit 1
+fi
+TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
+trap 'rm -rf "$TMPROOT"' EXIT
+
+ran=0; pass=0; fail=0
+OUT=''; RC=999; DID_RUN=0; FIXTURE_FAIL=''
+
+report() {
+  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
+  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
+}
+
+# new_tree — 깨끗한 배포물 트리(위반 0건)를 만들고 경로를 낸다.
+# 정상 문구를 일부러 담는다: 계약 표현("지식 저장소")은 통과해야 하고, 통과하지
+# 못하면 이 검사기는 쓸 수가 없다.
+new_tree() {
+  local d
+  d="$(mktemp -d "$TMPROOT/tree.XXXXXX")" || { FIXTURE_FAIL='mktemp 실패'; return 1; }
+  mkdir -p "$d/.claude/hooks" "$d/.claude/skills/x" || { FIXTURE_FAIL='골격 실패'; return 1; }
+  printf '%s\n' '# 지식 저장소 반영 게이트. 저장소가 어디인지는 사용자 층이 답한다.' \
+    > "$d/.claude/hooks/verify.sh"
+  printf '%s\n' '완료 게이트 4종을 세운다. .needs-knowledge 는 계약 이름이다.' \
+    > "$d/.claude/skills/x/SKILL.md"
+  printf '%s\n' 'HARNESS_KNOWLEDGE_GATE="on"' > "$d/.claude/harness.env"
+  printf '%s\n' "$d"
+}
+
+run_checker() {   # $1 = 스캔 범위 (덮어쓰기)
+  OUT=''; RC=999; DID_RUN=1
+  OUT="$(HARNESS_LAYER_SCAN_ROOT="$1" "$CHECKER" 2>&1)"
+  RC=$?
+}
+
+# 덮어쓰기 **없이** 돌린다 — 검사기가 스스로 정한 기본 범위를 그대로 쓴다.
+run_checker_default() {
+  OUT=''; RC=999; DID_RUN=1
+  OUT="$(env -u HARNESS_LAYER_SCAN_ROOT "$CHECKER" 2>&1)"
+  RC=$?
+}
+
+# leak_case <이름> <심을 문구> <보고에 나와야 할 조각>
+# 깨끗한 트리에 그 문구 **하나만** 심는다.
+leak_case() {
+  local name="$1" text="$2" token="$3" d why=''
+  if ! d="$(new_tree)"; then report "$name" "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
+  printf '%s\n' "$text" > "$d/.claude/hooks/leaky.sh"
+  run_checker "$d"
+  if [ "$DID_RUN" -ne 1 ]; then
+    why='검사기를 실행하지 않았다'
+  elif [ "$RC" -eq 0 ]; then
+    why='누출을 통과시켰다 (rc=0)'
+  elif [ "$RC" -ne 1 ]; then
+    why="rc=$RC (기대 1) / $(printf '%s' "$OUT" | head -c 200)"
+  else
+    case "$OUT" in
+      *"$token"*) ;;
+      *) why="보고에 [$token] 이 없다: $(printf '%s' "$OUT" | head -c 200)" ;;
+    esac
+    if [ -z "$why" ]; then
+      case "$OUT" in
+        *'leaky.sh'*) ;;
+        *) why="어느 파일인지 보고하지 않았다: $(printf '%s' "$OUT" | head -c 200)" ;;
+      esac
+    fi
+  fi
+  report "$name" "$why"
+}
+
+# --- 케이스 --------------------------------------------------------------
+
+c01() {
+  local d why=''
+  if ! d="$(new_tree)"; then report '깨끗한 트리는 통과한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
+  run_checker "$d"
+  if [ "$RC" -ne 0 ]; then why="rc=$RC (기대 0) / $OUT"; fi
+  report '깨끗한 트리는 통과한다 (계약 표현은 위양성이 아니다)' "$why"
+}
+
+c02() { leak_case '저장소 이름 — second brain'     'second brain 에 반영한다'       'second'; }
+c03() { leak_case '도구 이름 — Obsidian'            'Obsidian 을 연다'               'Obsidian'; }
+c04() { leak_case '저장소 이름 — 볼트'               '이 저장소에 반영한다 볼트'      '볼트'; }
+c05() { leak_case '상위 층 파일 — _CLAUDE.md'        '_CLAUDE.md 를 전문 읽는다'      '_CLAUDE'; }
+c06() { leak_case '상위 층 구조 — 4종 세트'          '4종 세트로 반영한다'            '4종 세트'; }
+c07() { leak_case '상위 층 파일 — discussion-log'    'discussion-log 에 적는다'       'discussion-log'; }
+c08() { leak_case '상위 층 폴더 — Projects/<name>'   'Projects/<name>/ 아래에 둔다'   'Projects'; }
+c09() { leak_case '구현체 이름 플래그 — needs-vault' 'rm -f .claude/.needs-vault'     'needs-vault'; }
+
+# 첫 건에서 멈추면 한 번 고칠 때마다 다시 돌려야 하고, 남은 누출이 몇 개인지 모른다.
+c10() {
+  local d why=''
+  if ! d="$(new_tree)"; then report '위반이 여러 파일이면 전부 보고한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
+  printf '%s\n' '볼트에 반영' > "$d/.claude/hooks/a.sh"
+  printf '%s\n' '_CLAUDE.md 읽기' > "$d/.claude/hooks/b.sh"
+  run_checker "$d"

exec
/bin/zsh -lc "sed -n '821,1140p' _workspace/05_delta.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
+  if [ "$RC" -ne 1 ]; then
+    why="rc=$RC (기대 1)"
+  else
+    case "$OUT" in *'a.sh'*) ;; *) why='a.sh 를 보고하지 않았다' ;; esac
+    if [ -z "$why" ]; then
+      case "$OUT" in *'b.sh'*) ;; *) why='b.sh 를 보고하지 않았다 (첫 건에서 멈췄다)' ;; esac
+    fi
+  fi
+  report '위반이 여러 파일이면 전부 보고한다' "$why"
+}
+
+# 사전 조건 — 스캔할 수 없는 대상이 있으면 결과 전체를 믿을 수 없다.
+c11() {
+  local d why=''
+  if ! d="$(new_tree)"; then report '심링크가 있으면 거부한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
+  if ! ln -s "$d/.claude/hooks/verify.sh" "$d/.claude/hooks/link.sh" 2>/dev/null; then
+    report '심링크가 있으면 거부한다' '픽스처 실패: ln -s'; return 0
+  fi
+  run_checker "$d"
+  if [ "$RC" -eq 0 ]; then why='심링크가 있는데 통과시켰다'
+  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
+  else
+    case "$OUT" in *'심링크'*) ;; *) why="사유가 심링크가 아니다: $(printf '%s' "$OUT" | head -c 160)" ;; esac
+  fi
+  report '심링크가 있으면 거부한다' "$why"
+}
+
+c12() {
+  local d why=''
+  if ! d="$(new_tree)"; then report 'NUL 보유 파일이 있으면 거부한다' "픽스처 실패: $FIXTURE_FAIL"; return 0; fi
+  printf 'A\000B\n' > "$d/.claude/hooks/nul.sh"
+  run_checker "$d"
+  if [ "$RC" -eq 0 ]; then why='NUL 파일이 있는데 통과시켰다'
+  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
+  else
+    case "$OUT" in *'NUL'*) ;; *) why="사유가 NUL 이 아니다: $(printf '%s' "$OUT" | head -c 160)" ;; esac
+  fi
+  report 'NUL 보유 파일이 있으면 거부한다' "$why"
+}
+
+# 빈 목록 = 공허한 초록. 0개를 스캔하고 "위반 0건"을 찍으면 아무것도 증명하지 않는다.
+c13() {
+  local d why=''
+  if ! d="$(mktemp -d "$TMPROOT/empty.XXXXXX")"; then
+    report '스캔 대상이 0개면 거부한다' '픽스처 실패'; return 0
+  fi
+  run_checker "$d"
+  if [ "$RC" -eq 0 ]; then why='파일이 하나도 없는데 초록불을 냈다'
+  elif [ "$RC" -ne 1 ]; then why="rc=$RC (기대 1)"
+  fi
+  report '스캔 대상이 0개면 거부한다 (공허한 초록 방지)' "$why"
+}
+
+c14() {
+  local why=''
+  run_checker "$TMPROOT/그런디렉토리없음"
+  if [ "$RC" -eq 0 ]; then why='없는 범위인데 통과시켰다'; fi
+  report '스캔 범위가 없으면 거부한다' "$why"
+}
+
+# **기본 스캔 범위**를 겨누는 유일한 케이스.
+#
+# 다른 케이스는 전부 HARNESS_LAYER_SCAN_ROOT 로 픽스처 트리를 겨눈다 — 그래서 기본 범위가
+# 빠져도 전건 초록이다. 실제로 그랬다: 배포 경로가 둘(template/ 와 global-agents/)인데
+# 범위를 template/ 하나로 잡아, global-agents/ 에 실제 누출이 있는데도 CI 가 초록이었다
+# (codex 검수 적발). 범위 누락은 **검사기가 아무것도 안 보면서 초록을 내는** 부류라
+# 다른 어떤 케이스로도 안 잡힌다.
+c15() {
+  local why='' full_n tpl_n
+  DID_RUN=1
+  # 기본 범위(덮지 않음)로 돌린 파일 수
+  run_checker_default
+  if [ "$RC" -ne 0 ]; then
+    report '기본 스캔 범위가 배포 경로를 전부 덮는다' "기본 범위에서 rc=$RC / $OUT"; return 0
+  fi
+  full_n="$(printf '%s' "$OUT" | sed -n 's/.*배포물 \([0-9][0-9]*\)개.*/\1/p')"
+  # template/ 만 덮었을 때의 파일 수
+  run_checker "$REPO_ROOT/template"
+  tpl_n="$(printf '%s' "$OUT" | sed -n 's/.*배포물 \([0-9][0-9]*\)개.*/\1/p')"
+  if [ -z "$full_n" ] || [ -z "$tpl_n" ]; then
+    why="파일 수를 읽지 못했다 (full=[$full_n] tpl=[$tpl_n])"
+  elif [ "$full_n" -le "$tpl_n" ]; then
+    why="기본 범위가 template/ 하나뿐이다 (${full_n}개 ≤ ${tpl_n}개) — 다른 배포 경로가 감시 밖이다"
+  fi
+  report '기본 스캔 범위가 배포 경로를 전부 덮는다' "$why"
+}
+
+# --- 러너 ----------------------------------------------------------------
+
+CASES='c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12 c13 c14 c15'
+EXPECTED_CASES=15
+
+case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
+case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
+if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
+  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
+  exit 1
+fi
+
+echo "층 경계 검사기 — 누출 적발 + 사전 조건"
+for c in $CASES; do
+  ran=$((ran + 1)); DID_RUN=0; FIXTURE_FAIL=''
+  "$c"
+done
+
+if [ "$ran" -ne "$EXPECTED_CASES" ]; then
+  echo "✗ 실행 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건" >&2; exit 1
+fi
+if [ $((pass + fail)) -ne "$ran" ]; then
+  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1
+fi
+
+echo "— ${pass}/${ran} 통과"
+[ "$fail" -eq 0 ] || exit 1
diff --git a/tests/harness-env-read.test.sh b/tests/harness-env-read.test.sh
index e77e59d..0f6140e 100755
--- a/tests/harness-env-read.test.sh
+++ b/tests/harness-env-read.test.sh
@@ -265,7 +265,7 @@ p14() { pcase '후행 주석 — 겹따옴표'                  0 'printf ok' "$
 p15() { pcase '후행 주석 — 홑따옴표'                  0 'printf ok' "$KEY='printf ok' # note"$'\n'; }
 p16() { pcase '후행 주석 — 인용 없음'                 0 'mypy'      "$KEY=mypy # note"$'\n'; }
 p17() { pcase '값 안의 # 은 주석이 아니다'            0 'a#b'       "$KEY=a#b"$'\n'; }
-p18() { pcase '값 자리가 통째로 주석'                 0 ''          "$KEY= # note"$'\n'; }
+p18() { pcase '등호 뒤 공백은 문법 밖 (셸과 갈리는 자리)' 1 ''      "$KEY= # note"$'\n'; }
 p19() { pcase '후행 공백 (눈에 안 보인다)'            0 'printf ok' "$KEY=\"printf ok\"   "$'\n'; }
 p20() { pcase '후행 탭'                               0 'printf ok' "$KEY=\"printf ok\""$'\t\n'; }
 p21() { pcase 'CRLF 줄끝'                             0 'printf ok' "$KEY=\"printf ok\""$'\r\n'; }
@@ -293,7 +293,7 @@ p42() { pcase 'harness.env 파일이 없다'               1 ''          '__NOFI
 p43() { pcase '빈 파일'                               1 ''          ''; }
 # 값의 앞·뒤 공백은 **서로 다른 자리**에서 털린다. 각각 따로 붙든다 —
 # 한쪽만 재면 다른 쪽을 지워도 초록이다(변이 측정에서 실제로 그랬다).
-p45() { pcase '등호 뒤 선행 공백 + 겹따옴표'          0 'printf ok' "$KEY=  \"printf ok\""$'\n'; }
+p45() { pcase '등호 뒤 선행 공백은 문법 밖'           1 ''          "$KEY=  \"printf ok\""$'\n'; }
 p46() { pcase '인용 없는 값의 후행 공백'              0 'mypy'      "$KEY=mypy   "$'\n'; }
 p47() { pcase '인용 없는 값의 후행 탭'                0 'mypy'      "$KEY=mypy"$'\t\n'; }
 
@@ -387,6 +387,27 @@ g08() { gcase '주석 처리된 선언으로는 못 끈다'      on  "# $GKEY=\"
 g09() { gcase 'harness.env 가 없으면 켜짐'         on  '__NOFILE__'; }
 g10() { gcase 'CRLF 로 비워도 꺼진다'              off "$GKEY=\"\""$'\r\n'; }
 
+
+# --- 듀얼 검수(2026-08-10)가 찾은 경로 ---------------------------------
+# 넷 다 **게이트를 끄는 방향**으로 틀리던 자리다. 이 방향의 오류가 이 설계에서 가장 나쁘다.
+
+p48() { pcase '다른 키의 여러 줄 값 안에 있는 키는 선언이 아니다' 1 '' \
+        "NOTES='example:"$'\n'"$KEY="$'\n'"end'"$'\n'; }
+p49() { pcase '히어독 <<\EOF (백슬래시 인용) 본문도 건너뛴다' 0 'printf ok' \
+        'cat <<\EOF'$'\n'"$KEY=\"evil\""$'\n''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
+p50() { pcase '닫는 따옴표 뒤 공백 없는 # 는 주석이 아니다'    1 '' \
+        "$KEY=\"\"#on"$'\n'; }
+p51() { pcase '인용 없는 값이 # 로 시작하면 값 그대로다'        0 '#on' \
+        "$KEY=#on"$'\n'; }
+p52() { pcase '인용이 EOF 까지 안 닫히면 파일을 못 믿는다'      1 '' \
+        "$KEY=\"printf ok\""$'\n'"NOTES='열고 안 닫음"$'\n'; }
+
+g11() { gcase '여러 줄 값 안의 키로는 못 끈다'  on \
+        "NOTES='example:"$'\n'"$GKEY="$'\n'"end'"$'\n'; }
+g12() { gcase '히어독 <<\EOF 본문으로는 못 끈다' on \
+        'cat <<\EOF'$'\n'"$GKEY=\"\""$'\n''EOF'$'\n'; }
+g13() { gcase '""#on 으로는 못 끈다'            on  "$GKEY=\"\"#on"$'\n'; }
+
 # --- 러너 ----------------------------------------------------------------
 
 CASES='
@@ -394,12 +415,13 @@ p01 p02 p03 p04 p05 p06 p07 p08 p09 p10
 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20
 p21 p22 p23 p24 p25 p26 p27 p28 p29 p30
 p31 p32 p33 p34 p35 p36 p37 p38 p39 p40
-p41 p42 p43 p44 p45 p46 p47
+p41 p42 p43 p44 p45 p46 p47 p48 p49 p50 p51 p52
 i01 i02 i03 i04 i05 i06 i07 i08 i09 i10
 i11 i12 i13
 g01 g02 g03 g04 g05 g06 g07 g08 g09 g10
+g11 g12 g13
 '
-EXPECTED_CASES=70
+EXPECTED_CASES=78
 
 # 목록 자체의 중복·누락을 먼저 본다. 실행 수만 세면 "하나 중복 + 하나 누락"이 상쇄돼
 # 그대로 초록이 된다 — 목록을 직접 봐야 그 조합이 잡힌다.
diff --git a/tests/install-hook-swap.test.sh b/tests/install-hook-swap.test.sh
new file mode 100755
index 0000000..1ba817b
--- /dev/null
+++ b/tests/install-hook-swap.test.sh
@@ -0,0 +1,246 @@
+#!/usr/bin/env bash
+# install-hook-swap.test.sh — 훅 디렉터리 rename 스왑의 회귀 테스트.
+#
+# 이 축의 실패는 **거짓 성공**으로 나온다. 앞선 검수에서 실제로 그랬다 — mv 가 기존
+# 디렉터리 **안으로** 중첩되어 훅이 hooks/hooks/*.sh 로 깨졌는데 스크립트는 "설치 성공"을
+# 찍었고, 신호로 죽었는데 rc=0 이 나왔다. 그래서 여기서는 rc 만 보지 않는다.
+#
+# **rc 단독 판정은 약하다.** 신호 종료 코드는 128+신호번호라는 관례값이라, 핸들러가 제대로
+# 돌아 exit 143 한 것과 핸들러가 아예 없어 커널 기본 처리로 죽은 것이 같은 143 을 낸다.
+# 그래서 케이스마다 **부수 효과**를 함께 잰다: 훅이 제자리에 있나 · 중첩(hooks/hooks)이
+# 생겼나 · 임시 디렉터리가 남았나 · 진단 문구가 나왔나.
+#
+# 중단 주입은 타이밍이 아니라 **shim** 으로 한다. PATH 앞에 놓은 mv 가 호출 횟수를 세다가
+# 두 번째(스테이징 → 제자리)에서 부모에게 신호를 보낸다 — 그러면 "옛것은 치웠고 새것은
+# 아직 안 들어온" 그 창에서 정확히 멈춘다. shim 은 실제 mv 의 rc 를 **절대 삼키지 않는다**
+# (rc 를 버리는 shim 은 픽스처의 실패를 조용히 성공으로 바꾼다 — 실측된 함정이다).
+#
+# 그리고 **주입이 실제로 걸렸는지를 판정에 넣는다.** 빗나가면 설치가 그냥 완주해 기대값이
+# 우연히 충족되고, 케이스는 아무것도 안 잰 채 통과 도장을 찍는다.
+#
+# 왜 set -e 가 없나: 비영 rc 를 assert 하는 테스트다.
+# 사용법: ./tests/install-hook-swap.test.sh
+
+set -uo pipefail
+
+TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
+REPO_ROOT="$(CDPATH='' cd -- "$TEST_DIR/.." && pwd -P)"
+INSTALL="$REPO_ROOT/install.sh"
+
+[ -f "$INSTALL" ] || { echo "✗ install.sh 를 찾지 못했습니다" >&2; exit 1; }
+
+TMPROOT="$(mktemp -d)" || exit 1
+if [ -z "$TMPROOT" ] || [ ! -d "$TMPROOT" ]; then
+  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2; exit 1
+fi
+TMPROOT="$(CDPATH='' cd -- "$TMPROOT" && pwd -P)"
+trap 'rm -rf "$TMPROOT"' EXIT
+
+REAL_MV="$(command -v mv)"
+[ -n "$REAL_MV" ] || { echo "✗ mv 를 찾지 못했습니다" >&2; exit 1; }
+
+ran=0; pass=0; fail=0
+RC=999; OUT=''; DID_RUN=0
+
+report() {
+  if [ -z "$2" ]; then pass=$((pass + 1)); printf '  ✓ %s\n' "$1"
+  else fail=$((fail + 1)); printf '  ✗ %s — %s\n' "$1" "$2"; fi
+}
+
+# new_project — 하네스가 이미 한 번 설치된 프로젝트. 구판임을 알아볼 수 있게 표식을
+# 넣는다 — "복원됐나"를 판정하려면 구판이 식별 가능해야 한다.
+new_project() {
+  local p
+  p="$(mktemp -d "$TMPROOT/proj.XXXXXX")" || return 1
+  p="$(CDPATH='' cd -- "$p" && pwd -P)"
+  "$INSTALL" "$p" >/dev/null 2>&1 || return 1
+  # 구판 식별 표식 — "복원됐나"를 판정하려면 구판이 식별 가능해야 한다.
+  printf 'OLD\n' > "$p/.claude/hooks/.old-marker"
+  # **사용자 파일** — 템플릿에 없는 것. 디렉터리를 통째로 바꾸는 설계에서 이게 사라지면
+  # 데이터 파괴다. 구 구현(파일 단위 cp)에는 없던 회귀이므로 케이스로 붙든다.
+  printf 'user\n' > "$p/.claude/hooks/custom.sh"
+  mkdir -p "$p/.claude/hooks/lib" && printf 'lib\n' > "$p/.claude/hooks/lib/helper.sh"
+  printf '%s\n' "$p"
+}
+
+# make_mv_shim <디렉터리> <몇 번째 호출에서> <신호이름|FAIL>
+make_mv_shim() {
+  local dir="$1" nth="$2" action="$3"
+  mkdir -p "$dir" || return 1
+  cat > "$dir/mv" <<SHIM
+#!/usr/bin/env bash
+n_file="$dir/.count"
+n=\$(cat "\$n_file" 2>/dev/null || echo 0)
+n=\$((n + 1))
+printf '%s\n' "\$n" > "\$n_file"
+if [ "\$n" -eq $nth ]; then
+  printf 'HIT\n' > "$dir/.hit"
+  if [ "$action" = FAIL ]; then
+    exit 1
+  fi
+  kill -$action \$PPID 2>/dev/null
+  sleep 5          # 신호가 처리될 시간. 핸들러가 exit 하므로 여기까지 오지 않는다
+  exit 1
+fi
+exec "$REAL_MV" "\$@"     # **실제 rc 를 그대로 돌려준다** — 삼키면 픽스처가 결함을 가린다
+SHIM
+  chmod +x "$dir/mv"
+}
+
+run_install() {   # $1=프로젝트  [$2=shim 디렉터리]
+  RC=999; OUT=''; DID_RUN=1
+  if [ -n "${2-}" ]; then
+    OUT="$(PATH="$2:$PATH" "$INSTALL" "$1" 2>&1)"
+  else
+    OUT="$("$INSTALL" "$1" 2>&1)"
+  fi
+  RC=$?
+}
+
+# leftovers <프로젝트> — 스테이징·백업 임시 디렉터리가 남았나
+leftovers() {
+  ls -a "$1/.claude" 2>/dev/null | grep -cE '^\.hooks-(stage|old)\.'
+}
+
+# --- 케이스 --------------------------------------------------------------
+
+c01() {
+  local name='정상 설치 — 템플릿 훅은 갱신, 사용자 파일은 보존' p why=''
+  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
+  # 템플릿 소유 파일을 오염시켜 둔다. 재설치가 이걸 덮어써야 "갱신"이다.
+  printf 'STALE\n' > "$p/.claude/hooks/_common.sh"
+  run_install "$p"
+  if [ "$RC" -ne 0 ]; then why="rc=$RC"
+  elif grep -q '^STALE$' "$p/.claude/hooks/_common.sh" 2>/dev/null; then
+    why='템플릿 훅이 갱신되지 않았다'
+  elif [ ! -f "$p/.claude/hooks/custom.sh" ]; then
+    why='**사용자 파일 custom.sh 가 삭제됐다** (디렉터리 교체가 데이터를 파괴한다)'
+  elif [ ! -f "$p/.claude/hooks/lib/helper.sh" ]; then
+    why='**사용자 하위 디렉터리 lib/ 가 삭제됐다**'
+  elif [ -e "$p/.claude/hooks/hooks" ]; then why='중첩(hooks/hooks)이 생겼다'
+  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
+  fi
+  report "$name" "$why"
+}
+
+# 중단 주입 — 두 rename 사이에서 멈춘다.
+interrupt_case() {   # $1=이름 $2=신호 $3=기대rc
+  local name="$1" sig="$2" want_rc="$3" p shim why=''
+  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
+  shim="$TMPROOT/shim.$sig.$$"
+  if ! make_mv_shim "$shim" 2 "$sig"; then report "$name" '픽스처 실패: shim'; return 0; fi
+  run_install "$p" "$shim"
+  if [ ! -f "$shim/.hit" ]; then
+    why='주입이 빗나갔다 (mv 가 2번째로 불리지 않았다 — 설치가 그냥 완주했다)'

exec
/bin/zsh -lc "sed -n '1141,1416p' _workspace/05_delta.diff" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
+  elif [ "$RC" -ne "$want_rc" ]; then
+    why="rc=$RC (기대 $want_rc)"
+  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then
+    why='구판으로 되돌리지 못했다 (훅 디렉터리가 사라졌다)'
+  elif [ -e "$p/.claude/hooks/hooks" ]; then
+    why='중첩(hooks/hooks)이 생겼다'
+  elif [ "$(leftovers "$p")" != '0' ]; then
+    why='임시 디렉터리가 남았다'
+  else
+    case "$OUT" in
+      *'되돌렸습니다'*) ;;
+      *) why="복구를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
+    esac
+  fi
+  report "$name" "$why"
+}
+
+c02() { interrupt_case '교체 도중 INT  — 구판 복원 + rc=130' INT  130; }
+c03() { interrupt_case '교체 도중 TERM — 구판 복원 + rc=143' TERM 143; }
+# QUIT·HUP 이 따로 중요한 이유: trap 이 없으면 bash 가 QUIT 를 **무시하고 rc=0** 을 낸다 —
+# 중단됐는데 "설치 성공"으로 보고되는 최악의 조합이다(실측).
+c04() { interrupt_case '교체 도중 QUIT — 구판 복원 + rc=131' QUIT 131; }
+c05() { interrupt_case '교체 도중 HUP  — 구판 복원 + rc=129' HUP  129; }
+
+c06() {
+  local name='rename2 실패 — 성공으로 오진단하지 않고 구판 복원' p shim why=''
+  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
+  shim="$TMPROOT/shim.fail.$$"
+  if ! make_mv_shim "$shim" 2 FAIL; then report "$name" '픽스처 실패: shim'; return 0; fi
+  run_install "$p" "$shim"
+  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
+  elif [ "$RC" -eq 0 ]; then why='실패했는데 rc=0 (성공으로 오진단)'
+  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
+  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
+  else
+    case "$OUT" in
+      *'교체하지 못했습니다'*) ;;
+      *) why="실패를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
+    esac
+  fi
+  report "$name" "$why"
+}
+
+c07() {
+  local name='훅 디렉터리가 심링크면 링크를 보존하고 알린다' p why=''
+  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
+  "$REAL_MV" "$p/.claude/hooks" "$p/real-hooks" || { report "$name" '픽스처 실패: mv'; return 0; }
+  ln -s "$p/real-hooks" "$p/.claude/hooks" || { report "$name" '픽스처 실패: ln'; return 0; }
+  run_install "$p"
+  if [ "$RC" -ne 0 ]; then why="rc=$RC"
+  elif [ ! -L "$p/.claude/hooks" ]; then why='심링크를 일반 디렉터리로 갈아치웠다 (사용자 배치 파괴)'
+  elif [ ! -f "$p/real-hooks/_common.sh" ]; then why='링크 대상에 훅이 복사되지 않았다'
+  else
+    case "$OUT" in
+      *'심볼릭 링크'*) ;;
+      *) why='원자성을 못 지킨다는 사실을 알리지 않았다 (조용히 물러섰다)' ;;
+    esac
+  fi
+  report "$name" "$why"
+}
+
+# 핸들러 진입 직후의 `set +e` 를 지키는 유일한 케이스.
+#
+# 왜 따로 필요한가: 다른 중단 케이스는 진단 echo 가 **성공**하므로 set +e 가 있든 없든
+# exit 에 도달한다. 그래서 그 줄을 지워도 전건 초록이다 — 실제로 앞선 세션에서 그 한 줄을
+# 지워도 스위트 19/19 가 그대로였다. 버그는 **stderr 가 닫힌 상태에서만** 재현되는데
+# 테스트 하네스가 출력을 2>&1 로 합칠 뿐 닫지 않았기 때문이다.
+#
+# 여기서는 stderr 를 **닫고**(2>&-) 돌린다. echo 가 실패하고, set -e 가 살아 있으면
+# 핸들러가 exit 143 에 도달하지 못하고 rc=1 로 끝난다 — 신호로 죽은 건지 실패한 건지
+# 구별이 사라지는 그 상태다.
+#
+# 한계(공시): stderr 가 닫혔으므로 진단 문구는 잴 수 없다. 종료 코드와 파일 상태만 본다.
+c08() {
+  local name='stderr 가 닫힌 채 TERM — 진단은 못 내도 종료 코드 계약은 지킨다' p shim why=''
+  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
+  shim="$TMPROOT/shim.noerr.$$"
+  if ! make_mv_shim "$shim" 2 TERM; then report "$name" '픽스처 실패: shim'; return 0; fi
+  DID_RUN=1
+  PATH="$shim:$PATH" "$INSTALL" "$p" >/dev/null 2>&-
+  RC=$?
+  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
+  elif [ "$RC" -ne 143 ]; then why="rc=$RC (기대 143 — set +e 가 없으면 1 이 된다)"
+  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
+  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
+  fi
+  report "$name" "$why"
+}
+
+# --- 러너 ----------------------------------------------------------------
+
+CASES='c01 c02 c03 c04 c05 c06 c07 c08'
+EXPECTED_CASES=8
+
+case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
+case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
+if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
+  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
+  exit 1
+fi
+
+echo "훅 교체 원자성 — rename 스왑 + 중단 복구"
+for c in $CASES; do
+  ran=$((ran + 1)); DID_RUN=0
+  "$c"
+done
+
+if [ "$ran" -ne "$EXPECTED_CASES" ]; then echo "✗ 실행 ${ran}건 ≠ ${EXPECTED_CASES}건" >&2; exit 1; fi
+if [ $((pass + fail)) -ne "$ran" ]; then echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1; fi
+
+echo "— ${pass}/${ran} 통과"
+[ "$fail" -eq 0 ] || exit 1
diff --git a/tests/mark-needs-audit.cases.sh b/tests/mark-needs-audit.cases.sh
index 85db753..73ac931 100644
--- a/tests/mark-needs-audit.cases.sh
+++ b/tests/mark-needs-audit.cases.sh
@@ -53,18 +53,18 @@ case_04() { # _workspace/ 는 스크래치 — 설계·계획 파일명이 아
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
@@ -199,7 +199,7 @@ case_23() { # B1 본체 — 밖 설계 문서에도 듀얼리뷰 게이트가 
   local p hr; p="$(new_project)"; hr="$(new_harness_repo)"
   mkfile "$hr/_workspace/00_design.md"
   run_hook "$p" "$hr/_workspace/00_design.md"
-  check_case '23 밖+정본 _workspace/00_design.md → 듀얼리뷰만(절대경로)' 0 dual "$hr/_workspace/00_design.md"
+  check_case '23 밖+정본 _workspace/00_design.md → 듀얼리뷰+지식(절대경로)' 0 designdoc "$hr/_workspace/00_design.md"
 }
 
 case_24() { # 순서계약 (나) — 정본 저장소가 **자기 자신에 설치한** 소비 사본은 스킵.
@@ -305,14 +305,14 @@ case_34() { # D2 본체 — **이 세션 형태**. _workspace/ 가 어느 git 
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
@@ -428,7 +428,7 @@ case_46() { # 순서계약 (가) — 듀얼 판정은 정규화 **뒤**.
   local p; p="$(new_project)"
   mkfile "$p/_workspace/01_plan.md"
   run_hook "$p" '_workspace/01_plan.md'
-  check_case '46 상대경로 입력 _workspace/01_plan.md → 듀얼리뷰만' 0 dual '_workspace/01_plan.md'
+  check_case '46 상대경로 입력 _workspace/01_plan.md → 듀얼리뷰+지식' 0 designdoc '_workspace/01_plan.md'
 }
 
 case_47() { # 순서계약 (가) — 기록값 축. 듀얼 판정을 정규화 앞으로 되돌리면 판정은 살아도
@@ -437,7 +437,7 @@ case_47() { # 순서계약 (가) — 기록값 축. 듀얼 판정을 정규화 
   local p; p="$(new_project)"
   mkfile "$p/.claude/../_workspace/00_design.md"
   run_hook "$p" "$p/.claude/../_workspace/00_design.md"
-  check_case '47 .claude/../_workspace/00_design.md → 듀얼리뷰만(정규화된 값)' 0 dual '_workspace/00_design.md'
+  check_case '47 .claude/../_workspace/00_design.md → 듀얼리뷰+지식(정규화된 값)' 0 designdoc '_workspace/00_design.md'
 }
 
 case_48() { # H1 — global-agents/ 는 전역 에이전트 **정본**이고 install/sync 가 배포한다.
@@ -501,7 +501,7 @@ case_55() { # 3단계 대소문자 축 — 듀얼 매칭은 소문자화해 비
   local p; p="$(new_project)"
   mkfile "$p/_workspace/00_Design.md"
   run_hook "$p" "$p/_workspace/00_Design.md"
-  check_case '55 _workspace/00_Design.md(대문자) → 듀얼리뷰만(원본 대소문자로 기록)' 0 dual '_workspace/00_Design.md'
+  check_case '55 _workspace/00_Design.md(대문자) → 듀얼리뷰+지식(원본 대소문자로 기록)' 0 designdoc '_workspace/00_Design.md'
 }
 
 # === F. 3중 검수에서 추가된 행 ============================================
@@ -650,7 +650,7 @@ case_66() { # 듀얼 글롭의 접미사 축 — 00_design* 쪽. 케이스 06 
   local p; p="$(new_project)"
   mkfile "$p/_workspace/00_design.v2.md"
   run_hook "$p" "$p/_workspace/00_design.v2.md"
-  check_case '66 프로젝트 안 _workspace/00_design.v2.md → 듀얼리뷰만' 0 dual '_workspace/00_design.v2.md'
+  check_case '66 프로젝트 안 _workspace/00_design.v2.md → 듀얼리뷰+지식' 0 designdoc '_workspace/00_design.v2.md'
 }
 
 # === G. PR 점검(C1)에서 추가된 행 — 물리 경로 정규화 축 ====================
@@ -720,11 +720,39 @@ case_70() { # 케이스 69 의 `.` 쪽 거울상 — 판정이 아니라 **기
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
@@ -732,4 +760,4 @@ CASES='case_01 case_02 case_03 case_04 case_05 case_06 case_07 case_08 case_09 c
        case_34 case_35 case_36 case_37 case_38 case_39 case_40 case_41 case_42 case_43 case_44
        case_45 case_46 case_47 case_48 case_49 case_50 case_51 case_52 case_53 case_54 case_55
        case_56 case_57 case_58 case_59 case_60 case_61 case_62 case_63 case_64 case_65 case_66
-       case_67 case_68 case_69 case_70'
+       case_67 case_68 case_69 case_70 case_71 case_72 case_73'
diff --git a/tests/mark-needs-audit.test.sh b/tests/mark-needs-audit.test.sh
index e4a4d22..23e88e3 100755
--- a/tests/mark-needs-audit.test.sh
+++ b/tests/mark-needs-audit.test.sh
@@ -249,15 +249,21 @@ flag_bytes() {
 # verdict_mismatch <gate|dual|none> <값> — 어긋난 사유를 내고, 맞으면 아무것도 안 낸다.
 # <값>은 **줄 목록**이다 — 여러 줄이면 줄 수와 기록 **순서**까지 계약이 된다(케이스 58).
 # 기대 바이트열은 각 줄 뒤에 개행 하나씩: record_flag 가 printf '%s\n' 로 덧붙이므로.
-# gate = 4종 전부가 그 바이트열 / dual = .needs-dualreview 만, 나머지는 부재·공백
-# none = 4종 전부 부재·공백
+# gate      = 4종 전부가 그 바이트열
+# designdoc = .needs-dualreview + .needs-knowledge (설계·계획 산출물)
+# knowledge = .needs-knowledge 만 (결정 문서 — 코드가 아니라 게이트 4종은 과하다)
+# none      = 4종 전부 부재·공백
 verdict_mismatch() {
   local kind="$1" value="$2" f want
   for f in $FLAG_NAMES; do
     want=''
     case "$kind" in
       gate) want="$value"$'\n' ;;
-      dual) [ "$f" = '.needs-dualreview' ] && want="$value"$'\n' ;;
+      designdoc)
+        case "$f" in
+          .needs-dualreview|.needs-knowledge) want="$value"$'\n' ;;
+        esac ;;
+      knowledge) [ "$f" = '.needs-knowledge' ] && want="$value"$'\n' ;;
       none) want='' ;;
       *)    printf '알 수 없는 기대 판정: %s' "$kind"; return 0 ;;
     esac

codex
델타의 핵심 구현은 확인했습니다. 이제 실제 파일의 주변 제어 흐름과 라운드 1 전체 변경을 교차 확인하겠습니다. 특히 신호 핸들러의 상태 판정이 “설치 전/교체 후” 상태를 오인하는지, 파서의 전역 `OPENQ`가 셸 문법과 어디서 달라지는지에 집중하고 있습니다.
exec
/bin/zsh -lc "nl -ba install.sh | sed -n '1,235p'; nl -ba template/.claude/hooks/_common.sh | sed -n '1,285p'; nl -ba scripts/check-layer-boundary.sh | sed -n '1,220p'" in /Users/kty/Downloads/kty-claude-harness-template
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
    76	  # **디렉터리를 통째로 바꾸므로 기존 내용물을 먼저 스테이징으로 옮겨 심는다.**
    77	  # 이게 없으면 템플릿에 없는 사용자 파일(custom.sh·보조 파일·하위 디렉터리)이
    78	  # 재설치마다 영구 삭제된다 — 파일 단위 cp 였던 구 구현에는 없던 회귀다.
    79	  # 슬롯이 아니어도 사용자가 그 디렉터리에 둔 것을 하네스가 지울 권한은 없다.
    80	  if [ -d "$DST/hooks" ]; then
    81	    if ! cp -R "$DST/hooks/." "$hooks_stage/"; then
    82	      rm -rf "$hooks_stage" "$hooks_backup"
    83	      echo "✗ 기존 훅 디렉터리를 스테이징으로 복사하지 못했습니다 — 사용자 파일을 잃지 않으려고 중단합니다." >&2
    84	      exit 1
    85	    fi
    86	  fi
    87	  cp "$SRC/hooks/"*.sh "$hooks_stage/"     # 템플릿 훅만 덮어쓴다
    88	  chmod +x "$hooks_stage/"*.sh
    89	
    90	  on_swap_signal() {   # $1=신호 이름  $2=종료 코드
    91	    set +e             # 보고는 최선 노력, **종료 코드가 계약**이다
    92	    # 플래그가 아니라 **파일시스템 실제 상태**로 판정한다. 첫 mv 가 끝났는데 플래그를
    93	    # 세우기 전에 신호가 오는 창이 있고(bash 는 외부 명령 종료 뒤 대기 중인 trap 을
    94	    # 먼저 실행한다), 플래그를 믿으면 그 창에서 복원하지 않고 백업까지 지운다.
    95	    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
    96	      if mv "$hooks_backup/hooks" "$DST/hooks"; then
    97	        echo "[$1] 훅 교체 도중 중단 — 구판으로 되돌렸습니다." >&2
    98	        rm -rf "$hooks_stage" "$hooks_backup"
    99	      else
   100	        # 복구가 실패했다. **백업을 지우지 않는다** — 그것이 유일한 사본이다.
   101	        echo "[$1] 훅 교체 도중 중단됐고 **복구도 실패했습니다**." >&2
   102	        echo "     구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
   103	        echo "     손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
   104	        rm -rf "$hooks_stage"
   105	      fi
   106	    else
   107	      echo "[$1] 중단되었습니다 (훅 교체는 시작 전이거나 이미 끝났습니다)." >&2
   108	      rm -rf "$hooks_stage" "$hooks_backup"
   109	    fi
   110	    exit "$2"
   111	  }
   112	  # QUIT·HUP 도 잡는다: bash 는 trap 이 없으면 QUIT 를 **무시하고 rc=0 을 낸다** —
   113	  # 중단됐는데 "성공"으로 보고되는 최악의 조합이다(실측).
   114	  trap 'on_swap_signal INT  130' INT
   115	  trap 'on_swap_signal TERM 143' TERM
   116	  trap 'on_swap_signal QUIT 131' QUIT
   117	  trap 'on_swap_signal HUP  129' HUP
   118	
   119	  if [ -d "$DST/hooks" ]; then
   120	    mv "$DST/hooks" "$hooks_backup/hooks"   # 중첩은 사고가 아니라 계약이다
   121	  fi
   122	  if ! mv "$hooks_stage" "$DST/hooks"; then
   123	    # rename2 실패. **성공으로 오진단하지 않는다** — 되돌리고 실패로 끝낸다.
   124	    # 복구 mv 의 rc 를 확인한다. 실패했는데 "되돌렸습니다"를 찍고 백업을 지우면
   125	    # 유일한 사본이 사라진다.
   126	    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
   127	      if mv "$hooks_backup/hooks" "$DST/hooks"; then
   128	        echo "   구판 훅으로 되돌렸습니다." >&2
   129	        rm -rf "$hooks_backup"
   130	      else
   131	        echo "   **복구도 실패했습니다.** 구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
   132	        echo "   손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
   133	      fi
   134	    else
   135	      rm -rf "$hooks_backup"
   136	    fi
   137	    rm -rf "$hooks_stage"
   138	    echo "✗ 훅 디렉터리를 교체하지 못했습니다: $DST/hooks" >&2
   139	    exit 1
   140	  fi
   141	  trap - INT TERM QUIT HUP     # 여기부터는 되돌릴 것이 없다
   142	  rm -rf "$hooks_backup"
   143	fi
   144	hook_count="$(ls "$DST/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
   145	
   146	cp "$SRC/harness/principles.md" "$DST/harness/"
   147	echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 $hook_count · 제0원칙"
   148	
   149	# ── 1b) 전역 에이전트 배포 (~/.claude/agents/ — 프로젝트 무관 글루, 덮어씀) ──
   150	# 정본은 이 repo의 global-agents/ (전역 디렉토리는 버전 관리가 안 되므로 — ADR-0002)
   151	GLOBAL_SRC="$TPL_ROOT/global-agents"
   152	if [ -d "$GLOBAL_SRC" ] && ls "$GLOBAL_SRC"/*.md >/dev/null 2>&1; then
   153	  mkdir -p "$HOME/.claude/agents"
   154	  cp "$GLOBAL_SRC"/*.md "$HOME/.claude/agents/"
   155	  echo "   전역 에이전트 ✓  $(ls "$GLOBAL_SRC"/*.md | wc -l | tr -d ' ')종 → ~/.claude/agents/"
   156	fi
   157	
   158	# ── 2) 슬롯 스캐폴드 (없을 때만 — 도메인은 사용자가 채운다) ──────────
   159	if [ ! -f "$DST/harness/project-profile.md" ]; then
   160	  sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
   161	    > "$DST/harness/project-profile.md"
   162	  echo "   슬롯 생성 ✓  harness/project-profile.md   ← §1~§8 채우세요"
   163	else
   164	  echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
   165	fi
   166	# 개명 전 플래그 이행 — **배포되지 않는 이 스크립트가 맡는다.**
   167	# 기존 설치본에 미처리 지식 플래그가 옛 이름으로 남아 있을 수 있는데, 새 훅은 새 이름만
   168	# 보므로 그대로 두면 밀린 반영 의무가 **조용히 사라진다**(하네스를 갱신했을 뿐인데).
   169	# 훅 쪽에서 옛 이름을 알게 하면 배포되는 글루가 구현체 이름을 다시 품어 층 경계 검사가
   170	# 막는다 — 그래서 이행은 여기에 있다. 새 이름이 이미 있으면 **덮지 않고 이어붙인다.**
   171	legacy_flag="$DST/.needs-$(printf 'vault')"
   172	if [ -f "$legacy_flag" ]; then
   173	  if [ -s "$legacy_flag" ]; then
   174	    if cat "$legacy_flag" >> "$DST/.needs-knowledge" 2>/dev/null; then
   175	      rm -f "$legacy_flag"
   176	      echo "   플래그 이행 ✓  미처리 지식 반영 항목을 새 이름으로 옮겼습니다"
   177	    else
   178	      echo "   ⚠ 미처리 지식 반영 플래그를 새 이름으로 옮기지 못했습니다: $legacy_flag" >&2
   179	      echo "     손으로 옮기지 않으면 그 항목의 반영 의무가 사라집니다." >&2
   180	    fi
   181	  else
   182	    rm -f "$legacy_flag"
   183	  fi
   184	fi
   185	
   186	if [ ! -f "$DST/harness/harness.env" ]; then
   187	  cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
   188	  echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
   189	  echo "                                                 (HARNESS_KNOWLEDGE_GATE 는 기본 켜짐)"
   190	else
   191	  echo "   슬롯 보존    harness/harness.env          (기존 유지)"
   192	fi
   193	
   194	# ── 3) settings.json 병합 (기존 훅 보존) ────────────────────────────
   195	if [ -f "$DST/settings.json" ]; then
   196	  cp "$DST/settings.json" "$DST/settings.json.bak-$STAMP"
   197	  echo "   settings 백업 → settings.json.bak-$STAMP"
   198	fi
   199	python3 - "$DST/settings.json" "$SRC/settings.json" <<'PYEOF'
   200	import json, os, sys
   201	dst_path, src_path = sys.argv[1], sys.argv[2]
   202	with open(src_path) as f:
   203	    ours = json.load(f)
   204	cur = {}
   205	if os.path.exists(dst_path):
   206	    with open(dst_path) as f:
   207	        cur = json.load(f)
   208	hooks = cur.setdefault("hooks", {})
   209	added = 0
   210	for event, entries in ours.get("hooks", {}).items():
   211	    lst = hooks.setdefault(event, [])
   212	    existing_cmds = {
   213	        (entry.get("matcher"), h.get("command"))
   214	        for entry in lst
   215	        for h in entry.get("hooks", [])
   216	    }
   217	    for entry in entries:
   218	        # (matcher, command) 단위 병합 — "항목에 하나라도 있으면 전체 스킵"은 같은 항목에 묶인
   219	        # 새 훅(guard-codex-invocation)이 기존 설치본에 영영 배선되지 않는 버그였고(2026-08-03),
   220	        # command만 보면 엉뚱한 matcher에 붙은 훅을 "배선됨"으로 오인한다([cx] 지적).
   221	        missing = [h for h in entry.get("hooks", [])
   222	                   if (entry.get("matcher"), h.get("command")) not in existing_cmds]
   223	        if not missing:
   224	            continue  # 전부 배선됨 (멱등)
   225	        target = next((e for e in lst if e.get("matcher") == entry.get("matcher")), None)
   226	        if target is not None:
   227	            target.setdefault("hooks", []).extend(missing)
   228	        else:
   229	            new_entry = {k: v for k, v in entry.items() if k != "hooks"}
   230	            new_entry["hooks"] = missing
   231	            lst.append(new_entry)
   232	        added += len(missing)
   233	        existing_cmds.update((entry.get("matcher"), h.get("command")) for h in missing)
   234	with open(dst_path, "w") as f:
   235	    json.dump(cur, f, ensure_ascii=False, indent=2)
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
   122	function scan_line(s,   n, i, j, c, t, dash) {
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
   136	      # 종결어 인용은 세 형태다: 인용 없음 · 따옴표로 감싼 형태 · 백슬래시 접두
   137	      # 백슬래시 형태를 빠뜨리면 본문을 안 건너뛰어 그 안의 키가 선언으로 세어진다.
   138	      c = substr(s, j, 1)
   139	      if (c == "\\") j++
   140	      c = substr(s, j, 1)
   141	      if (c == "\"" || c == SQ) {
   142	        j++
   143	        while (j <= n && substr(s, j, 1) != c) { t = t substr(s, j, 1); j++ }
   144	        j++
   145	      } else {
   146	        while (j <= n) {
   147	          c = substr(s, j, 1)
   148	          if (c ~ /[A-Za-z0-9_.\/-]/) { t = t c; j++ } else break
   149	        }
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
    35	# 스캔 범위는 **배포물 전부**다. 범위를 넓히면 문서·ADR·테스트의 정당한 인용이 죄다
    36	# 위양성이 되므로 배포되지 않는 것은 넣지 않는다 — 이 저장소의 ADR 은 무엇이 새어
    37	# 있었는지 기록해야 하므로 그 표현을 반드시 담는다.
    38	#
    39	# **배포 경로가 둘이라는 것이 함정이었다.** install.sh 는 `template/.claude/` 를 프로젝트로
    40	# 복사하고, 그와 별도로 `global-agents/*.md` 를 `~/.claude/agents/` 로 배포한다. 범위를
    41	# template/ 하나로 잡았더니 global-agents/ 에 실제 누출이 있는데도 CI 가 초록이었다
    42	# (codex 검수에서 적발). 배포되는 것은 전부 본다.
    43	DEFAULT_ROOTS="$ROOT/template
    44	$ROOT/global-agents"
    45	# 회귀 테스트가 픽스처 트리를 겨누려고 이 값을 덮는다. 그 외에는 덮지 마라.
    46	SCAN_ROOTS="${HARNESS_LAYER_SCAN_ROOT:-$DEFAULT_ROOTS}"
    47	
    48	# 범위 중 **하나라도** 없으면 거부한다. 하나가 조용히 빠지면 그만큼 감시가 사라진다.
    49	while IFS= read -r r; do
    50	  [ -n "$r" ] || continue
    51	  if [ ! -d "$r" ]; then
    52	    echo "✗ 스캔 범위가 디렉토리가 아닙니다: $r" >&2
    53	    exit 1
    54	  fi
    55	done <<EOF
    56	$SCAN_ROOTS
    57	EOF
    58	
    59	WORK="$(mktemp -d)"
    60	if [ -z "$WORK" ] || [ ! -d "$WORK" ]; then
    61	  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2
    62	  exit 1
    63	fi
    64	trap 'rm -rf "$WORK"' EXIT
    65	
    66	# ── 금지 표현 ─────────────────────────────────────────────────────────
    67	# 한 줄에 `ERE 패턴<TAB>왜 상위 층인가`. 메시지가 있어야 걸린 사람이 무엇을 계약 수준으로
    68	# 다시 써야 하는지 안다. "금지됐다"만 알려주는 검사는 우회당한다.
    69	# 히어독을 **인용**한다(<<'PATTERNS'): 패턴 안의 $ · 백슬래시가 셸에 먹히면 안 된다.
    70	PATTERNS_FILE="$WORK/patterns"
    71	cat > "$PATTERNS_FILE" <<'PATTERNS'
    72	second[ -]brain	특정 지식 저장소의 이름. 하네스는 저장소가 무엇인지 몰라야 한다
    73	[Oo]bsidian	특정 도구 이름. 저장소를 바꾸면 이 문구가 거짓이 된다
    74	볼트	특정 지식 저장소의 이름
    75	_CLAUDE\.md	상위 층 저장소 안의 파일 이름. 그 파일이 없는 환경에서는 지킬 수 없는 요구가 된다
    76	4종 세트	상위 층이 지식을 어느 파일로 나눠 담는지의 구조. 하네스가 알 필요 없다
    77	discussion-log	상위 층 저장소의 파일 이름
    78	Projects/<name>	상위 층 저장소의 폴더 구조
    79	needs-vault	구현체 이름이 붙은 플래그. 계약 이름(.needs-knowledge)을 써라
    80	PATTERNS
    81	
    82	# ── 사전 조건: 스캔할 수 없는 대상이 있으면 결과 전체를 믿을 수 없다 ──
    83	# 형제 검사기(check-rule-copies.sh)의 ①②③ 과 같은 층위다. 심링크가 있으면 grep -r 은
    84	# 건너뛰는데 install.sh 의 cp 는 실체를 배포한다 — 검사되지 않은 파일이 배포되는 창이
    85	# 열린다. NUL 보유 파일은 토큰 바이트열이 원리적으로 안 보인다(UTF-16 도 같은 층위).
    86	#
    87	# find -print0 을 **파일로 받는다.** 명령 치환으로 받으면 셸이 NUL 을 버려 루프가 한 번도
    88	# 안 돌고, 검사기는 "위반 0건"으로 초록불을 낸다.
    89	FILES="$WORK/files"
    90	: > "$FILES"
    91	while IFS= read -r r; do
    92	  [ -n "$r" ] || continue
    93	  find "$r" -print0 >> "$FILES"
    94	done <<EOF
    95	$SCAN_ROOTS
    96	EOF
    97	
    98	bad_pre=0
    99	while IFS= read -r -d '' p; do
   100	  if [ -L "$p" ]; then
   101	    echo "✗ 심링크가 스캔 범위 안에 있습니다: ${p#"$ROOT"/}" >&2
   102	    bad_pre=1
   103	    continue
   104	  fi
   105	  [ -f "$p" ] || continue
   106	  if ! LC_ALL=C tr -d '\000' < "$p" | cmp -s - "$p"; then
   107	    echo "✗ NUL 바이트를 가진 파일이 있어 내용을 믿을 수 없습니다: ${p#"$ROOT"/}" >&2
   108	    bad_pre=1
   109	  fi
   110	done < "$FILES"
   111	
   112	if [ "$bad_pre" -ne 0 ]; then
   113	  echo "" >&2
   114	  echo "스캔할 수 없는 대상이 트리에 있으면 그 트리에 대한 스캔 결과 전체를 믿을 수 없습니다." >&2
   115	  echo "제거한 뒤 다시 돌리세요." >&2
   116	  exit 1
   117	fi
   118	
   119	# ── 스캔 ─────────────────────────────────────────────────────────────
   120	# hits 를 파이프·서브셸 안에서 올리면 증가분이 부모로 안 돌아온다(서브셸 변수 누수).
   121	# 그래서 출력은 모아 두고 개수는 파일로 센다.
   122	REPORT="$WORK/report"
   123	: > "$REPORT"
   124	scanned=0
   125	
   126	while IFS= read -r -d '' f; do
   127	  [ -f "$f" ] || continue
   128	  scanned=$((scanned + 1))
   129	  rel="${f#"$ROOT"/}"
   130	  while IFS="$(printf '\t')" read -r pat why; do
   131	    [ -n "$pat" ] || continue
   132	    # grep rc: 0=매치 1=무매치 **2 이상=오류**. `|| true` 로 뭉뚱그리면 읽기 실패까지
   133	    # 삼켜 스캔이 통째로 실패해도 조용히 초록이 된다.
   134	    set +e
   135	    out="$(grep -nE -- "$pat" "$f")"
   136	    rc=$?
   137	    set -e
   138	    if [ "$rc" -ge 2 ]; then
   139	      echo "✗ 스캔 실패(rc=$rc): $rel  패턴 [$pat]" >&2
   140	      exit 1
   141	    fi
   142	    if [ "$rc" -eq 0 ]; then
   143	      printf '%s\n' "$out" | sed "s|^|  $rel:|" >> "$REPORT"
   144	      printf '      ↑ %s\n' "$why" >> "$REPORT"
   145	    fi
   146	  done < "$PATTERNS_FILE"
   147	done < "$FILES"
   148	
   149	# 스캔 대상이 0개면 "0건 위반"을 찍고 통과한다 — 공허한 초록이다.
   150	# 배포물이 하나도 없을 리 없으므로 그건 범위 설정이 틀린 것이다.
   151	if [ "$scanned" -eq 0 ]; then
   152	  echo "✗ 스캔한 파일이 0개입니다 (범위 설정을 확인하세요):" >&2
   153	  printf '%s\n' "$SCAN_ROOTS" | sed 's/^/    /' >&2
   154	  exit 1
   155	fi
   156	
   157	if [ -s "$REPORT" ]; then
   158	  cat "$REPORT" >&2
   159	  echo "" >&2
   160	  echo "✗ 하네스 글루에 상위 층 구현이 샜습니다." >&2
   161	  echo "  계약만 남기고 구현은 사용자 층으로 옮기세요 — 하네스는 지식 저장소가" >&2
   162	  echo "  어디이고 어떤 구조인지 몰라야 그 저장소 없이도 돌아갑니다." >&2
   163	  exit 1
   164	fi
   165	
   166	echo "✓ 층 경계 유지 — 배포물 ${scanned}개에 상위 층 구현 0건"

exec
/bin/zsh -lc "rg -n \"harness_env_value|HARNESS_TYPECHECK_CMD|HARNESS_KNOWLEDGE_GATE|check-layer-boundary|install-hook-swap\" template tests scripts README.md Makefile .github 2>/dev/null; nl -ba tests/harness-env-read.test.sh | sed -n '1,460p'; nl -ba tests/install-hook-swap.test.sh | sed -n '1,290p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
.github/workflows/check-rules.yml:32:        run: ./tests/check-layer-boundary.test.sh
.github/workflows/check-rules.yml:36:        run: ./tests/install-hook-swap.test.sh
.github/workflows/check-rules.yml:42:        run: ./scripts/check-layer-boundary.sh
template/CLAUDE.md.snippet:13:**지식 저장소 연결은 사용자 층에 있다:** 하네스가 아는 것은 계약 하나뿐이다 — *"지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다."* **어디에 어떤 구조로 반영하는지는 하네스가 모르고, 알아서도 안 된다.** 그 답은 **전역 `CLAUDE.md`(사용자 층)** 이 갖는다 — 거기에 없으면 이 게이트는 무엇을 하라는 건지 알 수 없는 요구가 된다. 지식 저장소를 쓰지 않는 환경이면 `.claude/harness/harness.env` 의 `HARNESS_KNOWLEDGE_GATE` 를 **비워서** 끈다(기본 켜짐, `"off"` 는 켜진 것으로 읽힌다).
README.md:93:대안: "세션 끝나면 어디에든 정리해라" 산문 규칙. → 세션 내내 0회 이행된 실사고. 코드·설정이 바뀐 턴은 **지식 저장소 반영** 또는 불요 사유 기록 없이 종료 불가(`.needs-knowledge` + Stop 훅 `stop:knowledge`). 하네스가 아는 것은 계약 하나뿐이다 — 저장소가 **어디이고 어떤 구조인지는 사용자 층 설정이 답한다**(ADR-0006). completion-auditor가 반영 증거(커밋 해시·파일 실존)를 1차 증거로 검증한다 — 코드가 끝나도 지식이 안 남았으면 완료가 아니다. 게이트는 기본 켜짐이고 `harness.env` 의 `HARNESS_KNOWLEDGE_GATE` 를 비워서만 끈다(ADR-0008).
README.md:181:- `HARNESS_TYPECHECK_CMD`가 프로필 §3과 harness.env 두 곳에 기입됨 — SSOT 위반. harness.env를 기계 정본으로, §3은 참조 표기로 정리.
scripts/check-layer-boundary.sh:2:# check-layer-boundary.sh — 하네스 글루에 **상위 층 구현**이 새면 종료 코드 1.
scripts/check-layer-boundary.sh:26:# 사용법: ./scripts/check-layer-boundary.sh
scripts/check-layer-boundary.sh:27:# 회귀 테스트: ./tests/check-layer-boundary.test.sh (CI에서 이 검사보다 **먼저** 돈다)
tests/install-hook-swap.test.sh:2:# install-hook-swap.test.sh — 훅 디렉터리 rename 스왑의 회귀 테스트.
tests/install-hook-swap.test.sh:22:# 사용법: ./tests/install-hook-swap.test.sh
tests/harness-env-read.test.sh:11:#   [파서]   harness_env_value 의 반환 계약. rc(0=판독됨 / 1=믿을 수 없음)와 **값의 바이트**.
tests/harness-env-read.test.sh:56:KEY='HARNESS_TYPECHECK_CMD'
tests/harness-env-read.test.sh:65:GKEY='HARNESS_KNOWLEDGE_GATE'
tests/harness-env-read.test.sh:97:# read_value <proj> — harness_env_value 를 부르고 VAL(바이트 보존)·VRC·VERR 을 채운다.
tests/harness-env-read.test.sh:108:           harness_env_value "$1"; rc=$?
tests/check-layer-boundary.test.sh:2:# check-layer-boundary.test.sh — 층 경계 검사기의 회귀 테스트.
tests/check-layer-boundary.test.sh:17:# 사용법: ./tests/check-layer-boundary.test.sh
tests/check-layer-boundary.test.sh:23:CHECKER="$REPO_ROOT/scripts/check-layer-boundary.sh"
tests/check-layer-boundary.test.sh:54:  printf '%s\n' 'HARNESS_KNOWLEDGE_GATE="on"' > "$d/.claude/harness.env"
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
   268	p18() { pcase '등호 뒤 공백은 문법 밖 (셸과 갈리는 자리)' 1 ''      "$KEY= # note"$'\n'; }
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
   296	p45() { pcase '등호 뒤 선행 공백은 문법 밖'           1 ''          "$KEY=  \"printf ok\""$'\n'; }
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
   390	
   391	# --- 듀얼 검수(2026-08-10)가 찾은 경로 ---------------------------------
   392	# 넷 다 **게이트를 끄는 방향**으로 틀리던 자리다. 이 방향의 오류가 이 설계에서 가장 나쁘다.
   393	
   394	p48() { pcase '다른 키의 여러 줄 값 안에 있는 키는 선언이 아니다' 1 '' \
   395	        "NOTES='example:"$'\n'"$KEY="$'\n'"end'"$'\n'; }
   396	p49() { pcase '히어독 <<\EOF (백슬래시 인용) 본문도 건너뛴다' 0 'printf ok' \
   397	        'cat <<\EOF'$'\n'"$KEY=\"evil\""$'\n''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
   398	p50() { pcase '닫는 따옴표 뒤 공백 없는 # 는 주석이 아니다'    1 '' \
   399	        "$KEY=\"\"#on"$'\n'; }
   400	p51() { pcase '인용 없는 값이 # 로 시작하면 값 그대로다'        0 '#on' \
   401	        "$KEY=#on"$'\n'; }
   402	p52() { pcase '인용이 EOF 까지 안 닫히면 파일을 못 믿는다'      1 '' \
   403	        "$KEY=\"printf ok\""$'\n'"NOTES='열고 안 닫음"$'\n'; }
   404	
   405	g11() { gcase '여러 줄 값 안의 키로는 못 끈다'  on \
   406	        "NOTES='example:"$'\n'"$GKEY="$'\n'"end'"$'\n'; }
   407	g12() { gcase '히어독 <<\EOF 본문으로는 못 끈다' on \
   408	        'cat <<\EOF'$'\n'"$GKEY=\"\""$'\n''EOF'$'\n'; }
   409	g13() { gcase '""#on 으로는 못 끈다'            on  "$GKEY=\"\"#on"$'\n'; }
   410	
   411	# --- 러너 ----------------------------------------------------------------
   412	
   413	CASES='
   414	p01 p02 p03 p04 p05 p06 p07 p08 p09 p10
   415	p11 p12 p13 p14 p15 p16 p17 p18 p19 p20
   416	p21 p22 p23 p24 p25 p26 p27 p28 p29 p30
   417	p31 p32 p33 p34 p35 p36 p37 p38 p39 p40
   418	p41 p42 p43 p44 p45 p46 p47 p48 p49 p50 p51 p52
   419	i01 i02 i03 i04 i05 i06 i07 i08 i09 i10
   420	i11 i12 i13
   421	g01 g02 g03 g04 g05 g06 g07 g08 g09 g10
   422	g11 g12 g13
   423	'
   424	EXPECTED_CASES=78
   425	
   426	# 목록 자체의 중복·누락을 먼저 본다. 실행 수만 세면 "하나 중복 + 하나 누락"이 상쇄돼
   427	# 그대로 초록이 된다 — 목록을 직접 봐야 그 조합이 잡힌다.
   428	case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
   429	case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
   430	if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
   431	  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 중복됐거나 빠졌습니다" >&2
   432	  exit 1
   433	fi
   434	
   435	echo "harness.env 원문 판독 — 반환 계약 + 게이트 통합"
   436	for c in $CASES; do
   437	  ran=$((ran + 1))
   438	  DID_RUN=0
   439	  FIXTURE_FAIL=''
   440	  "$c"
   441	done
   442	
   443	if [ "$ran" -ne "$EXPECTED_CASES" ]; then
   444	  echo "✗ 실행 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건 — 케이스가 조용히 빠졌습니다" >&2
   445	  exit 1
   446	fi
   447	if [ $((pass + fail)) -ne "$ran" ]; then
   448	  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건 — 중복 판정했거나 판정을 건너뛰었습니다" >&2
   449	  exit 1
   450	fi
   451	
   452	echo "— ${pass}/${ran} 통과"
   453	[ "$fail" -eq 0 ] || exit 1
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
    57	  # 구판 식별 표식 — "복원됐나"를 판정하려면 구판이 식별 가능해야 한다.
    58	  printf 'OLD\n' > "$p/.claude/hooks/.old-marker"
    59	  # **사용자 파일** — 템플릿에 없는 것. 디렉터리를 통째로 바꾸는 설계에서 이게 사라지면
    60	  # 데이터 파괴다. 구 구현(파일 단위 cp)에는 없던 회귀이므로 케이스로 붙든다.
    61	  printf 'user\n' > "$p/.claude/hooks/custom.sh"
    62	  mkdir -p "$p/.claude/hooks/lib" && printf 'lib\n' > "$p/.claude/hooks/lib/helper.sh"
    63	  printf '%s\n' "$p"
    64	}
    65	
    66	# make_mv_shim <디렉터리> <몇 번째 호출에서> <신호이름|FAIL>
    67	make_mv_shim() {
    68	  local dir="$1" nth="$2" action="$3"
    69	  mkdir -p "$dir" || return 1
    70	  cat > "$dir/mv" <<SHIM
    71	#!/usr/bin/env bash
    72	n_file="$dir/.count"
    73	n=\$(cat "\$n_file" 2>/dev/null || echo 0)
    74	n=\$((n + 1))
    75	printf '%s\n' "\$n" > "\$n_file"
    76	if [ "\$n" -eq $nth ]; then
    77	  printf 'HIT\n' > "$dir/.hit"
    78	  if [ "$action" = FAIL ]; then
    79	    exit 1
    80	  fi
    81	  kill -$action \$PPID 2>/dev/null
    82	  sleep 5          # 신호가 처리될 시간. 핸들러가 exit 하므로 여기까지 오지 않는다
    83	  exit 1
    84	fi
    85	exec "$REAL_MV" "\$@"     # **실제 rc 를 그대로 돌려준다** — 삼키면 픽스처가 결함을 가린다
    86	SHIM
    87	  chmod +x "$dir/mv"
    88	}
    89	
    90	run_install() {   # $1=프로젝트  [$2=shim 디렉터리]
    91	  RC=999; OUT=''; DID_RUN=1
    92	  if [ -n "${2-}" ]; then
    93	    OUT="$(PATH="$2:$PATH" "$INSTALL" "$1" 2>&1)"
    94	  else
    95	    OUT="$("$INSTALL" "$1" 2>&1)"
    96	  fi
    97	  RC=$?
    98	}
    99	
   100	# leftovers <프로젝트> — 스테이징·백업 임시 디렉터리가 남았나
   101	leftovers() {
   102	  ls -a "$1/.claude" 2>/dev/null | grep -cE '^\.hooks-(stage|old)\.'
   103	}
   104	
   105	# --- 케이스 --------------------------------------------------------------
   106	
   107	c01() {
   108	  local name='정상 설치 — 템플릿 훅은 갱신, 사용자 파일은 보존' p why=''
   109	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   110	  # 템플릿 소유 파일을 오염시켜 둔다. 재설치가 이걸 덮어써야 "갱신"이다.
   111	  printf 'STALE\n' > "$p/.claude/hooks/_common.sh"
   112	  run_install "$p"
   113	  if [ "$RC" -ne 0 ]; then why="rc=$RC"
   114	  elif grep -q '^STALE$' "$p/.claude/hooks/_common.sh" 2>/dev/null; then
   115	    why='템플릿 훅이 갱신되지 않았다'
   116	  elif [ ! -f "$p/.claude/hooks/custom.sh" ]; then
   117	    why='**사용자 파일 custom.sh 가 삭제됐다** (디렉터리 교체가 데이터를 파괴한다)'
   118	  elif [ ! -f "$p/.claude/hooks/lib/helper.sh" ]; then
   119	    why='**사용자 하위 디렉터리 lib/ 가 삭제됐다**'
   120	  elif [ -e "$p/.claude/hooks/hooks" ]; then why='중첩(hooks/hooks)이 생겼다'
   121	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   122	  fi
   123	  report "$name" "$why"
   124	}
   125	
   126	# 중단 주입 — 두 rename 사이에서 멈춘다.
   127	interrupt_case() {   # $1=이름 $2=신호 $3=기대rc
   128	  local name="$1" sig="$2" want_rc="$3" p shim why=''
   129	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   130	  shim="$TMPROOT/shim.$sig.$$"
   131	  if ! make_mv_shim "$shim" 2 "$sig"; then report "$name" '픽스처 실패: shim'; return 0; fi
   132	  run_install "$p" "$shim"
   133	  if [ ! -f "$shim/.hit" ]; then
   134	    why='주입이 빗나갔다 (mv 가 2번째로 불리지 않았다 — 설치가 그냥 완주했다)'
   135	  elif [ "$RC" -ne "$want_rc" ]; then
   136	    why="rc=$RC (기대 $want_rc)"
   137	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then
   138	    why='구판으로 되돌리지 못했다 (훅 디렉터리가 사라졌다)'
   139	  elif [ -e "$p/.claude/hooks/hooks" ]; then
   140	    why='중첩(hooks/hooks)이 생겼다'
   141	  elif [ "$(leftovers "$p")" != '0' ]; then
   142	    why='임시 디렉터리가 남았다'
   143	  else
   144	    case "$OUT" in
   145	      *'되돌렸습니다'*) ;;
   146	      *) why="복구를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
   147	    esac
   148	  fi
   149	  report "$name" "$why"
   150	}
   151	
   152	c02() { interrupt_case '교체 도중 INT  — 구판 복원 + rc=130' INT  130; }
   153	c03() { interrupt_case '교체 도중 TERM — 구판 복원 + rc=143' TERM 143; }
   154	# QUIT·HUP 이 따로 중요한 이유: trap 이 없으면 bash 가 QUIT 를 **무시하고 rc=0** 을 낸다 —
   155	# 중단됐는데 "설치 성공"으로 보고되는 최악의 조합이다(실측).
   156	c04() { interrupt_case '교체 도중 QUIT — 구판 복원 + rc=131' QUIT 131; }
   157	c05() { interrupt_case '교체 도중 HUP  — 구판 복원 + rc=129' HUP  129; }
   158	
   159	c06() {
   160	  local name='rename2 실패 — 성공으로 오진단하지 않고 구판 복원' p shim why=''
   161	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   162	  shim="$TMPROOT/shim.fail.$$"
   163	  if ! make_mv_shim "$shim" 2 FAIL; then report "$name" '픽스처 실패: shim'; return 0; fi
   164	  run_install "$p" "$shim"
   165	  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
   166	  elif [ "$RC" -eq 0 ]; then why='실패했는데 rc=0 (성공으로 오진단)'
   167	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
   168	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   169	  else
   170	    case "$OUT" in
   171	      *'교체하지 못했습니다'*) ;;
   172	      *) why="실패를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
   173	    esac
   174	  fi
   175	  report "$name" "$why"
   176	}
   177	
   178	c07() {
   179	  local name='훅 디렉터리가 심링크면 링크를 보존하고 알린다' p why=''
   180	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   181	  "$REAL_MV" "$p/.claude/hooks" "$p/real-hooks" || { report "$name" '픽스처 실패: mv'; return 0; }
   182	  ln -s "$p/real-hooks" "$p/.claude/hooks" || { report "$name" '픽스처 실패: ln'; return 0; }
   183	  run_install "$p"
   184	  if [ "$RC" -ne 0 ]; then why="rc=$RC"
   185	  elif [ ! -L "$p/.claude/hooks" ]; then why='심링크를 일반 디렉터리로 갈아치웠다 (사용자 배치 파괴)'
   186	  elif [ ! -f "$p/real-hooks/_common.sh" ]; then why='링크 대상에 훅이 복사되지 않았다'
   187	  else
   188	    case "$OUT" in
   189	      *'심볼릭 링크'*) ;;
   190	      *) why='원자성을 못 지킨다는 사실을 알리지 않았다 (조용히 물러섰다)' ;;
   191	    esac
   192	  fi
   193	  report "$name" "$why"
   194	}
   195	
   196	# 핸들러 진입 직후의 `set +e` 를 지키는 유일한 케이스.
   197	#
   198	# 왜 따로 필요한가: 다른 중단 케이스는 진단 echo 가 **성공**하므로 set +e 가 있든 없든
   199	# exit 에 도달한다. 그래서 그 줄을 지워도 전건 초록이다 — 실제로 앞선 세션에서 그 한 줄을
   200	# 지워도 스위트 19/19 가 그대로였다. 버그는 **stderr 가 닫힌 상태에서만** 재현되는데
   201	# 테스트 하네스가 출력을 2>&1 로 합칠 뿐 닫지 않았기 때문이다.
   202	#
   203	# 여기서는 stderr 를 **닫고**(2>&-) 돌린다. echo 가 실패하고, set -e 가 살아 있으면
   204	# 핸들러가 exit 143 에 도달하지 못하고 rc=1 로 끝난다 — 신호로 죽은 건지 실패한 건지
   205	# 구별이 사라지는 그 상태다.
   206	#
   207	# 한계(공시): stderr 가 닫혔으므로 진단 문구는 잴 수 없다. 종료 코드와 파일 상태만 본다.
   208	c08() {
   209	  local name='stderr 가 닫힌 채 TERM — 진단은 못 내도 종료 코드 계약은 지킨다' p shim why=''
   210	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   211	  shim="$TMPROOT/shim.noerr.$$"
   212	  if ! make_mv_shim "$shim" 2 TERM; then report "$name" '픽스처 실패: shim'; return 0; fi
   213	  DID_RUN=1
   214	  PATH="$shim:$PATH" "$INSTALL" "$p" >/dev/null 2>&-
   215	  RC=$?
   216	  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
   217	  elif [ "$RC" -ne 143 ]; then why="rc=$RC (기대 143 — set +e 가 없으면 1 이 된다)"
   218	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
   219	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   220	  fi
   221	  report "$name" "$why"
   222	}
   223	
   224	# --- 러너 ----------------------------------------------------------------
   225	
   226	CASES='c01 c02 c03 c04 c05 c06 c07 c08'
   227	EXPECTED_CASES=8
   228	
   229	case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
   230	case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
   231	if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
   232	  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
   233	  exit 1
   234	fi
   235	
   236	echo "훅 교체 원자성 — rename 스왑 + 중단 복구"
   237	for c in $CASES; do
   238	  ran=$((ran + 1)); DID_RUN=0
   239	  "$c"
   240	done
   241	
   242	if [ "$ran" -ne "$EXPECTED_CASES" ]; then echo "✗ 실행 ${ran}건 ≠ ${EXPECTED_CASES}건" >&2; exit 1; fi
   243	if [ $((pass + fail)) -ne "$ran" ]; then echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1; fi
   244	
   245	echo "— ${pass}/${ran} 통과"
   246	[ "$fail" -eq 0 ] || exit 1

exec
/bin/zsh -lc "git status --short; git diff --stat; rg -n '"'^diff --git '"' _workspace/04_review.diff _workspace/05_delta.diff; sed -n '1,220p' .github/workflows/check-rules.yml; nl -ba sync.sh | sed -n '75,145p'; rg -n \"needs-vault|needs-knowledge|global-agents|HARNESS_LAYER_SCAN_ROOT\" _workspace/04_review.diff | head -n 120" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
?? _workspace/05_codex_r2.md
?? _workspace/05_codex_r2_prompt.md
?? _workspace/05_delta.diff
_workspace/05_delta.diff:1:diff --git a/install.sh b/install.sh
_workspace/05_delta.diff:148:diff --git a/scripts/check-layer-boundary.sh b/scripts/check-layer-boundary.sh
_workspace/05_delta.diff:320:diff --git a/sync.sh b/sync.sh
_workspace/05_delta.diff:346:diff --git a/template/.claude/harness/project-profile.template.md b/template/.claude/harness/project-profile.template.md
_workspace/05_delta.diff:380:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
_workspace/05_delta.diff:571:diff --git a/template/.claude/hooks/mark-needs-audit.sh b/template/.claude/hooks/mark-needs-audit.sh
_workspace/05_delta.diff:642:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
_workspace/05_delta.diff:657:diff --git a/template/.claude/skills/harness-orchestrator/SKILL.md b/template/.claude/skills/harness-orchestrator/SKILL.md
_workspace/05_delta.diff:691:diff --git a/tests/check-layer-boundary.test.sh b/tests/check-layer-boundary.test.sh
_workspace/05_delta.diff:935:diff --git a/tests/harness-env-read.test.sh b/tests/harness-env-read.test.sh
_workspace/05_delta.diff:1001:diff --git a/tests/install-hook-swap.test.sh b/tests/install-hook-swap.test.sh
_workspace/05_delta.diff:1253:diff --git a/tests/mark-needs-audit.cases.sh b/tests/mark-needs-audit.cases.sh
_workspace/05_delta.diff:1388:diff --git a/tests/mark-needs-audit.test.sh b/tests/mark-needs-audit.test.sh
_workspace/04_review.diff:1:diff --git a/.github/workflows/check-rules.yml b/.github/workflows/check-rules.yml
_workspace/04_review.diff:25:diff --git a/_workspace/03_impl_r1.diff b/_workspace/03_impl_r1.diff
_workspace/04_review.diff:131:diff --git a/_workspace/03_impl_r1_codex.md b/_workspace/03_impl_r1_codex.md
_workspace/04_review.diff:1278:diff --git a/_workspace/mutate-harness-env.sh b/_workspace/mutate-harness-env.sh
_workspace/04_review.diff:1483:diff --git a/_workspace/mutation-harness-env-2026-08-10.txt b/_workspace/mutation-harness-env-2026-08-10.txt
_workspace/04_review.diff:1545:diff --git a/_workspace/progress.md b/_workspace/progress.md
_workspace/04_review.diff:1645:diff --git a/docs/decisions/2026-08-05-knowledge-store-layer-boundary.md b/docs/decisions/2026-08-05-knowledge-store-layer-boundary.md
_workspace/04_review.diff:1683:diff --git a/docs/decisions/2026-08-06-knowledge-gate-default-on.md b/docs/decisions/2026-08-06-knowledge-gate-default-on.md
_workspace/04_review.diff:1810:diff --git a/docs/decisions/2026-08-06-knowledge-retrieval-policy.md b/docs/decisions/2026-08-06-knowledge-retrieval-policy.md
_workspace/04_review.diff:1886:diff --git a/docs/decisions/2026-08-06-profile-canon-upstream.md b/docs/decisions/2026-08-06-profile-canon-upstream.md
_workspace/04_review.diff:1965:diff --git a/docs/usage.md b/docs/usage.md
_workspace/04_review.diff:2005:diff --git a/install.sh b/install.sh
_workspace/04_review.diff:2104:diff --git a/scripts/check-layer-boundary.sh b/scripts/check-layer-boundary.sh
_workspace/04_review.diff:2256:diff --git a/sync.sh b/sync.sh
_workspace/04_review.diff:2308:diff --git a/template/.claude/harness/harness.env.template b/template/.claude/harness/harness.env.template
_workspace/04_review.diff:2375:diff --git a/template/.claude/harness/project-profile.template.md b/template/.claude/harness/project-profile.template.md
_workspace/04_review.diff:2409:diff --git a/template/.claude/hooks/_common.sh b/template/.claude/hooks/_common.sh
_workspace/04_review.diff:2630:diff --git a/template/.claude/hooks/mark-needs-audit.sh b/template/.claude/hooks/mark-needs-audit.sh
_workspace/04_review.diff:2709:diff --git a/template/.claude/hooks/verify-before-stop.sh b/template/.claude/hooks/verify-before-stop.sh
_workspace/04_review.diff:2821:diff --git a/template/.claude/skills/harness-orchestrator/SKILL.md b/template/.claude/skills/harness-orchestrator/SKILL.md
_workspace/04_review.diff:2875:diff --git a/template/CLAUDE.md.snippet b/template/CLAUDE.md.snippet
_workspace/04_review.diff:2890:diff --git a/tests/check-layer-boundary.test.sh b/tests/check-layer-boundary.test.sh
_workspace/04_review.diff:3100:diff --git a/tests/harness-env-read.test.sh b/tests/harness-env-read.test.sh
_workspace/04_review.diff:3537:diff --git a/tests/install-hook-swap.test.sh b/tests/install-hook-swap.test.sh
_workspace/04_review.diff:3778:diff --git a/tests/mark-needs-audit.cases.sh b/tests/mark-needs-audit.cases.sh
_workspace/04_review.diff:3913:diff --git a/tests/mark-needs-audit.test.sh b/tests/mark-needs-audit.test.sh
# 규칙 정본과 판정자 사본이 어긋난 채로 머지되는 걸 막는다.
# 사본이 낡아도 아무것도 안 깨지던 상태가 이 저장소의 유일한 조용한 실패였다.
name: check-rules

permissions:
  contents: read

on:
  push:
    branches: [main]
  pull_request:

jobs:
  rule-copies:
    # 검사기를 신뢰할 근거를 먼저 만든다 — 회귀 테스트가 먼저, 사본 대조가 뒤.
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          # 이 워크스페이스에서 PR 이 작성한 셸 스크립트를 실행한다 —
          # .git/config 에 토큰을 남기지 않는다.
          persist-credentials: false
      - name: 검사기 회귀 테스트
        run: ./tests/check-rule-copies.test.sh
      - name: 완료 게이트 검사 범위 회귀 테스트
        run: ./tests/mark-needs-audit.test.sh
      # harness.env 를 실행하지 않고 원문으로 읽는 파서의 회귀 방어.
      # 여기가 조용히 틀리면 값에 쓰레기가 섞여 rc=127 이 되고 타입체크 게이트가 사라진다.
      - name: harness.env 원문 판독 회귀 테스트
        run: ./tests/harness-env-read.test.sh
      - name: 층 경계 검사기 회귀 테스트
        run: ./tests/check-layer-boundary.test.sh
      # 훅 교체 도중 중단되면 구판으로 되돌아가는가. 이 축의 실패는 "설치 성공"이라는
      # 거짓 보고로 나오므로 rc 만이 아니라 파일 상태·잔류물·문구까지 잰다.
      - name: 훅 교체 원자성 회귀 테스트
        run: ./tests/install-hook-swap.test.sh
      - name: 규칙 사본 동기화 검사
        run: ./scripts/check-rule-copies.sh
      # 층 경계 검사는 사본 대조 **뒤**다. 앞선 단계가 세운 신뢰 전제(범위·심링크·NUL)를
      # 그대로 이어받는다 — 적힌 결합이다.
      - name: 층 경계 검사 (글루에 상위 층 구현이 샜나)
        run: ./scripts/check-layer-boundary.sh
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
   109	  # 검증은 **완성된 줄 전체**를 요구한다. `^HARNESS_KNOWLEDGE_GATE=` 로만 보면
   110	  # append 가 등호 직후에서 잘려 `HARNESS_KNOWLEDGE_GATE=` 만 남은 경우까지 통과시키는데,
   111	  # 그 잘린 줄은 파서에게 **완벽히 유효한 "리터럴 빈 값"** 이라 게이트를 끈다.
   112	  # 즉 "실패 방향은 안전하다"가 이 한 지점에서만 성립하지 않아서, 여기서 막는다.
   113	  if { printf '\n# 지식 반영 게이트 (하네스가 나중에 추가한 슬롯). 끄려면 값을 비운다 —\n# "off" 라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다. 이 줄이 없어도 켜짐이다.\nHARNESS_KNOWLEDGE_GATE="on"\n' >> "$envf"; } 2>/dev/null \
   114	     && grep -qxF 'HARNESS_KNOWLEDGE_GATE="on"' "$envf" 2>/dev/null; then
   115	    echo "   슬롯 키 추가 ✓  harness/harness.env  HARNESS_KNOWLEDGE_GATE=\"on\""
   116	  else
   117	    echo "   ⚠ harness/harness.env 에 HARNESS_KNOWLEDGE_GATE 를 온전히 추가하지 못했습니다." >&2
   118	    echo "     **파일 끝에 잘린 줄이 남았을 수 있습니다.** 그 상태로 두면 지식 게이트가" >&2
   119	    echo "     꺼진 것으로 읽힐 수 있으니 파일 끝을 직접 확인하고, 다음 한 줄로 고치세요:" >&2
   120	    echo '       HARNESS_KNOWLEDGE_GATE="on"' >&2
   121	  fi
   122	fi
   123	
   124	echo ""
   125	echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)의 **값**은 그대로입니다."
201:+ VAULT_FLAG="$STATE_DIR/.needs-vault"
561:+./README.md:63:대안: "검수해라, 설명해라"를 산문 지시로. → 실사고(§5)로 증명됐듯 산문은 생략된다. `PreToolUse`(기본 브랜치 커밋 차단 + codex 호출 규율)·`PostToolUse`(게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview`)·`Stop`(타입체크→듀얼리뷰→설명→볼트반영→감사 미이행 시 종료 차단)은 모델의 선의와 무관하게 발화한다. superpowers가 방법론을 주지만 강제력이 없다 — 훅이 그 빈자리를 채운다. 단 벽돌 방지(같은 지점에서 진전 없이 3회면 경고와 통과 — 게이트를 지울 때마다 카운터 리셋이라 순차 처리로는 소진 안 됨)와 탈출구(`HARNESS_HOOKS=off`, 게이트별 `ECC_DISABLED_HOOKS`)를 항상 남긴다: 강제 장치가 세션을 인질로 잡으면 안 된다. 예외: guard-codex-invocation에는 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만(⑪).
658:+./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:30:| `template/.claude/hooks/verify-before-stop.sh` | `.needs-vault` |
659:+./docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:31:| `template/.claude/hooks/_common.sh` | `.needs-vault` |
679:+./template/.claude/skills/harness-orchestrator/SKILL.md:133:**이 게이트는 산문이 아니라 훅으로 강제된다** (`.claude/settings.json`). 코드/설정을 편집하면 `.claude/.needs-audit`·`.needs-explain`·`.needs-vault` 플래그가 서고, Stop 훅이 타입체크(§3, `harness.env`) + 설명 + **볼트 반영** + 감사 없이는 턴 종료를 막는다(rc=2). 감사자가 검증을 통과시킨 **뒤에만** `rm -f .claude/.needs-audit` — 감사 없이 플래그만 지우는 것은 게이트 무력화다. 같은 지점에서 진전 없이 3회 차단되면 벽돌 방지 통과되며(게이트를 지울 때마다 카운터 리셋), 그때는 완료 주장을 신뢰하지 말 것.
747:+    11	VAULT_FLAG="$STATE_DIR/.needs-vault"
1011:+   187	    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-vault"
1630:+3. 남은 9축: 누출 정리(훅3+스킬1) · `.needs-vault`→`.needs-knowledge` · 훅 rename 스왑 ·
1671:+- **플래그 개명**: `.needs-vault` → `.needs-knowledge`
1912:+하네스는 배포본이 놓일 **자리만** 제공한다 — `install.sh` 가 슬롯으로 스캐폴드하고 `sync.sh` 는 절대 덮지 않는다. 정본을 어디에 어떤 이름으로 두는지는 **하네스의 관심사가 아니다.** [ADR-0006](2026-08-05-knowledge-store-layer-boundary.md)의 층 계약 그대로이고, [ADR-0002](2026-07-20-global-agents-layer.md)가 전역 에이전트에 대해 같은 패턴을 이미 풀었다.
1984:-| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview` (설계·계획 산출물은 듀얼리뷰 플래그만, 코드는 4종 전부). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
1986:+| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (설계·계획 산출물은 듀얼리뷰 플래그만, 코드는 4종 전부). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
2000:-- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 볼트 반영(`.needs-vault`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
2001:+- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 지식 저장소 반영(`.needs-knowledge`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
2095: # 정본은 이 repo의 global-agents/ (전역 디렉토리는 버전 관리가 안 되므로 — ADR-0002)
2148:+SCAN_ROOT="${HARNESS_LAYER_SCAN_ROOT:-$ROOT/template}"
2175:+needs-vault	구현체 이름이 붙은 플래그. 계약 이름(.needs-knowledge)을 써라
2417:-VAULT_FLAG="$STATE_DIR/.needs-vault"
2420:+KNOWLEDGE_FLAG="$STATE_DIR/.needs-knowledge"
2693:-#   .needs-vault      → 볼트(second brain) 반영 또는 불요 사유 기록 강제 (2026-08-02 kty —
2695:+#   .needs-knowledge  → 지식 저장소 반영 또는 불요 사유 기록 강제 (2026-08-02 kty —
2810:-    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-vault"
2812:+    echo "  4. 2 또는 3을 마친 뒤에만:  rm -f .claude/.needs-knowledge"
2859:-**이 게이트는 산문이 아니라 훅으로 강제된다** (`.claude/settings.json`). 코드/설정을 편집하면 `.claude/.needs-audit`·`.needs-explain`·`.needs-vault` 플래그가 서고, Stop 훅이 타입체크(§3, `harness.env`) + 설명 + **볼트 반영** + 감사 없이는 턴 종료를 막는다(rc=2). 감사자가 검증을 통과시킨 **뒤에만** `rm -f .claude/.needs-audit` — 감사 없이 플래그만 지우는 것은 게이트 무력화다. 같은 지점에서 진전 없이 3회 차단되면 벽돌 방지 통과되며(게이트를 지울 때마다 카운터 리셋), 그때는 완료 주장을 신뢰하지 말 것.
2860:+**이 게이트는 산문이 아니라 훅으로 강제된다** (`.claude/settings.json`). 코드/설정을 편집하면 `.claude/.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` 플래그가 서고, Stop 훅이 타입체크(3절, `harness.env`) + 듀얼 리뷰 + 설명 + **지식 저장소 반영** + 감사 없이는 턴 종료를 막는다(rc=2). 감사자가 검증을 통과시킨 **뒤에만** `rm -f .claude/.needs-audit` — 감사 없이 플래그만 지우는 것은 게이트 무력화다. 같은 지점에서 진전 없이 3회 차단되면 벽돌 방지 통과되며(게이트를 지울 때마다 카운터 리셋), 그때는 완료 주장을 신뢰하지 말 것.
2862:-**볼트(second brain) 반영 게이트 (2026-08-02 kty 확정 — 실사고 재발 방지):** 결정·설계·개발작업이 나온 턴은 종료 전에 볼트 `Projects/<name>/` **4종 세트**(discussion-log + decisions/ADR + architecture + index)에 반영하고, raw 산출물(설계 전문 등)은 `specs/`에 보존한다 — **raw와 요약 둘 다**. 반영할 지식이 없으면 불요 사유를 progress.md에 기록. 절차: ① 볼트 `_CLAUDE.md` **전문** 읽기(부분 독해 금지 — head -N 사고 전례) ② 반영·커밋(볼트 자체 pre-commit 훅이 4종 세트를 재검증) ③ `rm -f .claude/.needs-vault`. **completion-auditor 검증 항목에 포함**: 볼트 커밋 해시·파일 실존을 1차 증거로 확인, 불요 판정이면 사유 타당성 심사. 캐논 정의는 볼트 `_CLAUDE.md`가 정본(팀 위키 반영은 kty 명시 지시 시에만 — 볼트 규칙 준수).
2867:+절차: ① 사용자 층이 가리키는 규약을 **전문** 읽는다(부분 독해 금지 — `head -N` 사고 전례) ② 그 규약대로 반영하고 **확인 가능한 증거**(커밋 해시·파일 경로)를 확보한다. 결론만이 아니라 그 판단을 만든 **근거(raw)** 도 규약이 정한 자리에 함께 남긴다 — 요약만 남기면 "왜 그렇게 정했나"가 복원 불가능해진다 ③ `rm -f .claude/.needs-knowledge`.
2947:+  printf '%s\n' '완료 게이트 4종을 세운다. .needs-knowledge 는 계약 이름이다.' \
2955:+  OUT="$(HARNESS_LAYER_SCAN_ROOT="$1" "$CHECKER" 2>&1)"
3004:+c09() { leak_case '구현체 이름 플래그 — needs-vault' 'rm -f .claude/.needs-vault'     'needs-vault'; }
3244:+  printf 'gate-target.ts\n' > "$proj/.claude/.needs-knowledge"
3847: case_48() { # H1 — global-agents/ 는 전역 에이전트 **정본**이고 install/sync 가 배포한다.
3921:-FLAG_NAMES='.needs-audit .needs-explain .needs-vault .needs-dualreview'
3922:+FLAG_NAMES='.needs-audit .needs-explain .needs-knowledge .needs-dualreview'
3933:+# designdoc = .needs-dualreview + .needs-knowledge (설계·계획 산출물)
3934:+# knowledge = .needs-knowledge 만 (결정 문서 — 코드가 아니라 게이트 4종은 과하다)
3945:+          .needs-dualreview|.needs-knowledge) want="$value"$'\n' ;;
3947:+      knowledge) [ "$f" = '.needs-knowledge' ] && want="$value"$'\n' ;;

exec
/bin/zsh -lc "nl -ba template/.claude/harness/harness.env.template; nl -ba template/.claude/hooks/verify-before-stop.sh | sed -n '80,185p'; nl -ba tests/harness-env-read.test.sh | sed -n '248,425p'; nl -ba tests/check-layer-boundary.test.sh | sed -n '175,245p'; nl -ba tests/install-hook-swap.test.sh | sed -n '105,230p'" in /Users/kty/Downloads/kty-claude-harness-template
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
   268	p18() { pcase '등호 뒤 공백은 문법 밖 (셸과 갈리는 자리)' 1 ''      "$KEY= # note"$'\n'; }
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
   296	p45() { pcase '등호 뒤 선행 공백은 문법 밖'           1 ''          "$KEY=  \"printf ok\""$'\n'; }
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
   390	
   391	# --- 듀얼 검수(2026-08-10)가 찾은 경로 ---------------------------------
   392	# 넷 다 **게이트를 끄는 방향**으로 틀리던 자리다. 이 방향의 오류가 이 설계에서 가장 나쁘다.
   393	
   394	p48() { pcase '다른 키의 여러 줄 값 안에 있는 키는 선언이 아니다' 1 '' \
   395	        "NOTES='example:"$'\n'"$KEY="$'\n'"end'"$'\n'; }
   396	p49() { pcase '히어독 <<\EOF (백슬래시 인용) 본문도 건너뛴다' 0 'printf ok' \
   397	        'cat <<\EOF'$'\n'"$KEY=\"evil\""$'\n''EOF'$'\n'"$KEY=\"printf ok\""$'\n'; }
   398	p50() { pcase '닫는 따옴표 뒤 공백 없는 # 는 주석이 아니다'    1 '' \
   399	        "$KEY=\"\"#on"$'\n'; }
   400	p51() { pcase '인용 없는 값이 # 로 시작하면 값 그대로다'        0 '#on' \
   401	        "$KEY=#on"$'\n'; }
   402	p52() { pcase '인용이 EOF 까지 안 닫히면 파일을 못 믿는다'      1 '' \
   403	        "$KEY=\"printf ok\""$'\n'"NOTES='열고 안 닫음"$'\n'; }
   404	
   405	g11() { gcase '여러 줄 값 안의 키로는 못 끈다'  on \
   406	        "NOTES='example:"$'\n'"$GKEY="$'\n'"end'"$'\n'; }
   407	g12() { gcase '히어독 <<\EOF 본문으로는 못 끈다' on \
   408	        'cat <<\EOF'$'\n'"$GKEY=\"\""$'\n''EOF'$'\n'; }
   409	g13() { gcase '""#on 으로는 못 끈다'            on  "$GKEY=\"\"#on"$'\n'; }
   410	
   411	# --- 러너 ----------------------------------------------------------------
   412	
   413	CASES='
   414	p01 p02 p03 p04 p05 p06 p07 p08 p09 p10
   415	p11 p12 p13 p14 p15 p16 p17 p18 p19 p20
   416	p21 p22 p23 p24 p25 p26 p27 p28 p29 p30
   417	p31 p32 p33 p34 p35 p36 p37 p38 p39 p40
   418	p41 p42 p43 p44 p45 p46 p47 p48 p49 p50 p51 p52
   419	i01 i02 i03 i04 i05 i06 i07 i08 i09 i10
   420	i11 i12 i13
   421	g01 g02 g03 g04 g05 g06 g07 g08 g09 g10
   422	g11 g12 g13
   423	'
   424	EXPECTED_CASES=78
   425	
   175	  report '스캔 대상이 0개면 거부한다 (공허한 초록 방지)' "$why"
   176	}
   177	
   178	c14() {
   179	  local why=''
   180	  run_checker "$TMPROOT/그런디렉토리없음"
   181	  if [ "$RC" -eq 0 ]; then why='없는 범위인데 통과시켰다'; fi
   182	  report '스캔 범위가 없으면 거부한다' "$why"
   183	}
   184	
   185	# **기본 스캔 범위**를 겨누는 유일한 케이스.
   186	#
   187	# 다른 케이스는 전부 HARNESS_LAYER_SCAN_ROOT 로 픽스처 트리를 겨눈다 — 그래서 기본 범위가
   188	# 빠져도 전건 초록이다. 실제로 그랬다: 배포 경로가 둘(template/ 와 global-agents/)인데
   189	# 범위를 template/ 하나로 잡아, global-agents/ 에 실제 누출이 있는데도 CI 가 초록이었다
   190	# (codex 검수 적발). 범위 누락은 **검사기가 아무것도 안 보면서 초록을 내는** 부류라
   191	# 다른 어떤 케이스로도 안 잡힌다.
   192	c15() {
   193	  local why='' full_n tpl_n
   194	  DID_RUN=1
   195	  # 기본 범위(덮지 않음)로 돌린 파일 수
   196	  run_checker_default
   197	  if [ "$RC" -ne 0 ]; then
   198	    report '기본 스캔 범위가 배포 경로를 전부 덮는다' "기본 범위에서 rc=$RC / $OUT"; return 0
   199	  fi
   200	  full_n="$(printf '%s' "$OUT" | sed -n 's/.*배포물 \([0-9][0-9]*\)개.*/\1/p')"
   201	  # template/ 만 덮었을 때의 파일 수
   202	  run_checker "$REPO_ROOT/template"
   203	  tpl_n="$(printf '%s' "$OUT" | sed -n 's/.*배포물 \([0-9][0-9]*\)개.*/\1/p')"
   204	  if [ -z "$full_n" ] || [ -z "$tpl_n" ]; then
   205	    why="파일 수를 읽지 못했다 (full=[$full_n] tpl=[$tpl_n])"
   206	  elif [ "$full_n" -le "$tpl_n" ]; then
   207	    why="기본 범위가 template/ 하나뿐이다 (${full_n}개 ≤ ${tpl_n}개) — 다른 배포 경로가 감시 밖이다"
   208	  fi
   209	  report '기본 스캔 범위가 배포 경로를 전부 덮는다' "$why"
   210	}
   211	
   212	# --- 러너 ----------------------------------------------------------------
   213	
   214	CASES='c01 c02 c03 c04 c05 c06 c07 c08 c09 c10 c11 c12 c13 c14 c15'
   215	EXPECTED_CASES=15
   216	
   217	case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
   218	case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"
   219	if [ "$case_total" -ne "$EXPECTED_CASES" ] || [ "$case_uniq" -ne "$EXPECTED_CASES" ]; then
   220	  echo "✗ CASES 목록 ${case_total}건(유일 ${case_uniq}건) ≠ 기대 ${EXPECTED_CASES}건" >&2
   221	  exit 1
   222	fi
   223	
   224	echo "층 경계 검사기 — 누출 적발 + 사전 조건"
   225	for c in $CASES; do
   226	  ran=$((ran + 1)); DID_RUN=0; FIXTURE_FAIL=''
   227	  "$c"
   228	done
   229	
   230	if [ "$ran" -ne "$EXPECTED_CASES" ]; then
   231	  echo "✗ 실행 ${ran}건 ≠ 기대 ${EXPECTED_CASES}건" >&2; exit 1
   232	fi
   233	if [ $((pass + fail)) -ne "$ran" ]; then
   234	  echo "✗ 판정 $((pass + fail))건 ≠ 실행 ${ran}건" >&2; exit 1
   235	fi
   236	
   237	echo "— ${pass}/${ran} 통과"
   238	[ "$fail" -eq 0 ] || exit 1
   105	# --- 케이스 --------------------------------------------------------------
   106	
   107	c01() {
   108	  local name='정상 설치 — 템플릿 훅은 갱신, 사용자 파일은 보존' p why=''
   109	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   110	  # 템플릿 소유 파일을 오염시켜 둔다. 재설치가 이걸 덮어써야 "갱신"이다.
   111	  printf 'STALE\n' > "$p/.claude/hooks/_common.sh"
   112	  run_install "$p"
   113	  if [ "$RC" -ne 0 ]; then why="rc=$RC"
   114	  elif grep -q '^STALE$' "$p/.claude/hooks/_common.sh" 2>/dev/null; then
   115	    why='템플릿 훅이 갱신되지 않았다'
   116	  elif [ ! -f "$p/.claude/hooks/custom.sh" ]; then
   117	    why='**사용자 파일 custom.sh 가 삭제됐다** (디렉터리 교체가 데이터를 파괴한다)'
   118	  elif [ ! -f "$p/.claude/hooks/lib/helper.sh" ]; then
   119	    why='**사용자 하위 디렉터리 lib/ 가 삭제됐다**'
   120	  elif [ -e "$p/.claude/hooks/hooks" ]; then why='중첩(hooks/hooks)이 생겼다'
   121	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   122	  fi
   123	  report "$name" "$why"
   124	}
   125	
   126	# 중단 주입 — 두 rename 사이에서 멈춘다.
   127	interrupt_case() {   # $1=이름 $2=신호 $3=기대rc
   128	  local name="$1" sig="$2" want_rc="$3" p shim why=''
   129	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   130	  shim="$TMPROOT/shim.$sig.$$"
   131	  if ! make_mv_shim "$shim" 2 "$sig"; then report "$name" '픽스처 실패: shim'; return 0; fi
   132	  run_install "$p" "$shim"
   133	  if [ ! -f "$shim/.hit" ]; then
   134	    why='주입이 빗나갔다 (mv 가 2번째로 불리지 않았다 — 설치가 그냥 완주했다)'
   135	  elif [ "$RC" -ne "$want_rc" ]; then
   136	    why="rc=$RC (기대 $want_rc)"
   137	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then
   138	    why='구판으로 되돌리지 못했다 (훅 디렉터리가 사라졌다)'
   139	  elif [ -e "$p/.claude/hooks/hooks" ]; then
   140	    why='중첩(hooks/hooks)이 생겼다'
   141	  elif [ "$(leftovers "$p")" != '0' ]; then
   142	    why='임시 디렉터리가 남았다'
   143	  else
   144	    case "$OUT" in
   145	      *'되돌렸습니다'*) ;;
   146	      *) why="복구를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
   147	    esac
   148	  fi
   149	  report "$name" "$why"
   150	}
   151	
   152	c02() { interrupt_case '교체 도중 INT  — 구판 복원 + rc=130' INT  130; }
   153	c03() { interrupt_case '교체 도중 TERM — 구판 복원 + rc=143' TERM 143; }
   154	# QUIT·HUP 이 따로 중요한 이유: trap 이 없으면 bash 가 QUIT 를 **무시하고 rc=0** 을 낸다 —
   155	# 중단됐는데 "설치 성공"으로 보고되는 최악의 조합이다(실측).
   156	c04() { interrupt_case '교체 도중 QUIT — 구판 복원 + rc=131' QUIT 131; }
   157	c05() { interrupt_case '교체 도중 HUP  — 구판 복원 + rc=129' HUP  129; }
   158	
   159	c06() {
   160	  local name='rename2 실패 — 성공으로 오진단하지 않고 구판 복원' p shim why=''
   161	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   162	  shim="$TMPROOT/shim.fail.$$"
   163	  if ! make_mv_shim "$shim" 2 FAIL; then report "$name" '픽스처 실패: shim'; return 0; fi
   164	  run_install "$p" "$shim"
   165	  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
   166	  elif [ "$RC" -eq 0 ]; then why='실패했는데 rc=0 (성공으로 오진단)'
   167	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
   168	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   169	  else
   170	    case "$OUT" in
   171	      *'교체하지 못했습니다'*) ;;
   172	      *) why="실패를 알리지 않았다: $(printf '%s' "$OUT" | tail -c 200)" ;;
   173	    esac
   174	  fi
   175	  report "$name" "$why"
   176	}
   177	
   178	c07() {
   179	  local name='훅 디렉터리가 심링크면 링크를 보존하고 알린다' p why=''
   180	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   181	  "$REAL_MV" "$p/.claude/hooks" "$p/real-hooks" || { report "$name" '픽스처 실패: mv'; return 0; }
   182	  ln -s "$p/real-hooks" "$p/.claude/hooks" || { report "$name" '픽스처 실패: ln'; return 0; }
   183	  run_install "$p"
   184	  if [ "$RC" -ne 0 ]; then why="rc=$RC"
   185	  elif [ ! -L "$p/.claude/hooks" ]; then why='심링크를 일반 디렉터리로 갈아치웠다 (사용자 배치 파괴)'
   186	  elif [ ! -f "$p/real-hooks/_common.sh" ]; then why='링크 대상에 훅이 복사되지 않았다'
   187	  else
   188	    case "$OUT" in
   189	      *'심볼릭 링크'*) ;;
   190	      *) why='원자성을 못 지킨다는 사실을 알리지 않았다 (조용히 물러섰다)' ;;
   191	    esac
   192	  fi
   193	  report "$name" "$why"
   194	}
   195	
   196	# 핸들러 진입 직후의 `set +e` 를 지키는 유일한 케이스.
   197	#
   198	# 왜 따로 필요한가: 다른 중단 케이스는 진단 echo 가 **성공**하므로 set +e 가 있든 없든
   199	# exit 에 도달한다. 그래서 그 줄을 지워도 전건 초록이다 — 실제로 앞선 세션에서 그 한 줄을
   200	# 지워도 스위트 19/19 가 그대로였다. 버그는 **stderr 가 닫힌 상태에서만** 재현되는데
   201	# 테스트 하네스가 출력을 2>&1 로 합칠 뿐 닫지 않았기 때문이다.
   202	#
   203	# 여기서는 stderr 를 **닫고**(2>&-) 돌린다. echo 가 실패하고, set -e 가 살아 있으면
   204	# 핸들러가 exit 143 에 도달하지 못하고 rc=1 로 끝난다 — 신호로 죽은 건지 실패한 건지
   205	# 구별이 사라지는 그 상태다.
   206	#
   207	# 한계(공시): stderr 가 닫혔으므로 진단 문구는 잴 수 없다. 종료 코드와 파일 상태만 본다.
   208	c08() {
   209	  local name='stderr 가 닫힌 채 TERM — 진단은 못 내도 종료 코드 계약은 지킨다' p shim why=''
   210	  if ! p="$(new_project)"; then report "$name" '픽스처 실패'; return 0; fi
   211	  shim="$TMPROOT/shim.noerr.$$"
   212	  if ! make_mv_shim "$shim" 2 TERM; then report "$name" '픽스처 실패: shim'; return 0; fi
   213	  DID_RUN=1
   214	  PATH="$shim:$PATH" "$INSTALL" "$p" >/dev/null 2>&-
   215	  RC=$?
   216	  if [ ! -f "$shim/.hit" ]; then why='주입이 빗나갔다'
   217	  elif [ "$RC" -ne 143 ]; then why="rc=$RC (기대 143 — set +e 가 없으면 1 이 된다)"
   218	  elif [ ! -f "$p/.claude/hooks/.old-marker" ]; then why='구판으로 되돌리지 못했다'
   219	  elif [ "$(leftovers "$p")" != '0' ]; then why='임시 디렉터리가 남았다'
   220	  fi
   221	  report "$name" "$why"
   222	}
   223	
   224	# --- 러너 ----------------------------------------------------------------
   225	
   226	CASES='c01 c02 c03 c04 c05 c06 c07 c08'
   227	EXPECTED_CASES=8
   228	
   229	case_total="$(printf '%s\n' $CASES | wc -l | tr -d ' ')"
   230	case_uniq="$(printf '%s\n' $CASES | sort | uniq | wc -l | tr -d ' ')"

codex
현재까지 두 가지 실질 결함이 선명합니다. 혼합 인용 히어독은 여전히 본문 속 빈 게이트 선언을 실제 선언으로 오인할 수 있고, 훅 스왑은 대상 디렉터리가 창 사이에 재생성되면 `mv`의 “기존 디렉터리 안으로 이동” 의미가 다시 살아납니다. 설치 이행 순서와 메타데이터 보존도 추가로 좁혀 보고 있습니다.
exec
/bin/zsh -lc "MANPAGER=cat man cp | col -b | sed -n '1,220p'; MANPAGER=cat man mv | col -b | sed -n '1,180p'; nl -ba install.sh | sed -n '65,190p'; nl -ba install.sh | sed -n '194,260p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
/usr/bin/man: line 1314: cannot create temp file for here document: Operation not permitted

/usr/bin/man: line 1314: cannot create temp file for here document: Operation not permitted

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
    76	  # **디렉터리를 통째로 바꾸므로 기존 내용물을 먼저 스테이징으로 옮겨 심는다.**
    77	  # 이게 없으면 템플릿에 없는 사용자 파일(custom.sh·보조 파일·하위 디렉터리)이
    78	  # 재설치마다 영구 삭제된다 — 파일 단위 cp 였던 구 구현에는 없던 회귀다.
    79	  # 슬롯이 아니어도 사용자가 그 디렉터리에 둔 것을 하네스가 지울 권한은 없다.
    80	  if [ -d "$DST/hooks" ]; then
    81	    if ! cp -R "$DST/hooks/." "$hooks_stage/"; then
    82	      rm -rf "$hooks_stage" "$hooks_backup"
    83	      echo "✗ 기존 훅 디렉터리를 스테이징으로 복사하지 못했습니다 — 사용자 파일을 잃지 않으려고 중단합니다." >&2
    84	      exit 1
    85	    fi
    86	  fi
    87	  cp "$SRC/hooks/"*.sh "$hooks_stage/"     # 템플릿 훅만 덮어쓴다
    88	  chmod +x "$hooks_stage/"*.sh
    89	
    90	  on_swap_signal() {   # $1=신호 이름  $2=종료 코드
    91	    set +e             # 보고는 최선 노력, **종료 코드가 계약**이다
    92	    # 플래그가 아니라 **파일시스템 실제 상태**로 판정한다. 첫 mv 가 끝났는데 플래그를
    93	    # 세우기 전에 신호가 오는 창이 있고(bash 는 외부 명령 종료 뒤 대기 중인 trap 을
    94	    # 먼저 실행한다), 플래그를 믿으면 그 창에서 복원하지 않고 백업까지 지운다.
    95	    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
    96	      if mv "$hooks_backup/hooks" "$DST/hooks"; then
    97	        echo "[$1] 훅 교체 도중 중단 — 구판으로 되돌렸습니다." >&2
    98	        rm -rf "$hooks_stage" "$hooks_backup"
    99	      else
   100	        # 복구가 실패했다. **백업을 지우지 않는다** — 그것이 유일한 사본이다.
   101	        echo "[$1] 훅 교체 도중 중단됐고 **복구도 실패했습니다**." >&2
   102	        echo "     구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
   103	        echo "     손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
   104	        rm -rf "$hooks_stage"
   105	      fi
   106	    else
   107	      echo "[$1] 중단되었습니다 (훅 교체는 시작 전이거나 이미 끝났습니다)." >&2
   108	      rm -rf "$hooks_stage" "$hooks_backup"
   109	    fi
   110	    exit "$2"
   111	  }
   112	  # QUIT·HUP 도 잡는다: bash 는 trap 이 없으면 QUIT 를 **무시하고 rc=0 을 낸다** —
   113	  # 중단됐는데 "성공"으로 보고되는 최악의 조합이다(실측).
   114	  trap 'on_swap_signal INT  130' INT
   115	  trap 'on_swap_signal TERM 143' TERM
   116	  trap 'on_swap_signal QUIT 131' QUIT
   117	  trap 'on_swap_signal HUP  129' HUP
   118	
   119	  if [ -d "$DST/hooks" ]; then
   120	    mv "$DST/hooks" "$hooks_backup/hooks"   # 중첩은 사고가 아니라 계약이다
   121	  fi
   122	  if ! mv "$hooks_stage" "$DST/hooks"; then
   123	    # rename2 실패. **성공으로 오진단하지 않는다** — 되돌리고 실패로 끝낸다.
   124	    # 복구 mv 의 rc 를 확인한다. 실패했는데 "되돌렸습니다"를 찍고 백업을 지우면
   125	    # 유일한 사본이 사라진다.
   126	    if [ -d "$hooks_backup/hooks" ] && [ ! -e "$DST/hooks" ]; then
   127	      if mv "$hooks_backup/hooks" "$DST/hooks"; then
   128	        echo "   구판 훅으로 되돌렸습니다." >&2
   129	        rm -rf "$hooks_backup"
   130	      else
   131	        echo "   **복구도 실패했습니다.** 구판이 여기 남아 있습니다: $hooks_backup/hooks" >&2
   132	        echo "   손으로 옮기세요:  mv '$hooks_backup/hooks' '$DST/hooks'" >&2
   133	      fi
   134	    else
   135	      rm -rf "$hooks_backup"
   136	    fi
   137	    rm -rf "$hooks_stage"
   138	    echo "✗ 훅 디렉터리를 교체하지 못했습니다: $DST/hooks" >&2
   139	    exit 1
   140	  fi
   141	  trap - INT TERM QUIT HUP     # 여기부터는 되돌릴 것이 없다
   142	  rm -rf "$hooks_backup"
   143	fi
   144	hook_count="$(ls "$DST/hooks"/*.sh 2>/dev/null | wc -l | tr -d ' ')"
   145	
   146	cp "$SRC/harness/principles.md" "$DST/harness/"
   147	echo "   글루 ✓  에이전트 $(ls "$DST/agents" | wc -l | tr -d ' ') · 스킬 $skill_count · 훅 $hook_count · 제0원칙"
   148	
   149	# ── 1b) 전역 에이전트 배포 (~/.claude/agents/ — 프로젝트 무관 글루, 덮어씀) ──
   150	# 정본은 이 repo의 global-agents/ (전역 디렉토리는 버전 관리가 안 되므로 — ADR-0002)
   151	GLOBAL_SRC="$TPL_ROOT/global-agents"
   152	if [ -d "$GLOBAL_SRC" ] && ls "$GLOBAL_SRC"/*.md >/dev/null 2>&1; then
   153	  mkdir -p "$HOME/.claude/agents"
   154	  cp "$GLOBAL_SRC"/*.md "$HOME/.claude/agents/"
   155	  echo "   전역 에이전트 ✓  $(ls "$GLOBAL_SRC"/*.md | wc -l | tr -d ' ')종 → ~/.claude/agents/"
   156	fi
   157	
   158	# ── 2) 슬롯 스캐폴드 (없을 때만 — 도메인은 사용자가 채운다) ──────────
   159	if [ ! -f "$DST/harness/project-profile.md" ]; then
   160	  sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
   161	    > "$DST/harness/project-profile.md"
   162	  echo "   슬롯 생성 ✓  harness/project-profile.md   ← §1~§8 채우세요"
   163	else
   164	  echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
   165	fi
   166	# 개명 전 플래그 이행 — **배포되지 않는 이 스크립트가 맡는다.**
   167	# 기존 설치본에 미처리 지식 플래그가 옛 이름으로 남아 있을 수 있는데, 새 훅은 새 이름만
   168	# 보므로 그대로 두면 밀린 반영 의무가 **조용히 사라진다**(하네스를 갱신했을 뿐인데).
   169	# 훅 쪽에서 옛 이름을 알게 하면 배포되는 글루가 구현체 이름을 다시 품어 층 경계 검사가
   170	# 막는다 — 그래서 이행은 여기에 있다. 새 이름이 이미 있으면 **덮지 않고 이어붙인다.**
   171	legacy_flag="$DST/.needs-$(printf 'vault')"
   172	if [ -f "$legacy_flag" ]; then
   173	  if [ -s "$legacy_flag" ]; then
   174	    if cat "$legacy_flag" >> "$DST/.needs-knowledge" 2>/dev/null; then
   175	      rm -f "$legacy_flag"
   176	      echo "   플래그 이행 ✓  미처리 지식 반영 항목을 새 이름으로 옮겼습니다"
   177	    else
   178	      echo "   ⚠ 미처리 지식 반영 플래그를 새 이름으로 옮기지 못했습니다: $legacy_flag" >&2
   179	      echo "     손으로 옮기지 않으면 그 항목의 반영 의무가 사라집니다." >&2
   180	    fi
   181	  else
   182	    rm -f "$legacy_flag"
   183	  fi
   184	fi
   185	
   186	if [ ! -f "$DST/harness/harness.env" ]; then
   187	  cp "$SRC/harness/harness.env.template" "$DST/harness/harness.env"
   188	  echo "   슬롯 생성 ✓  harness/harness.env          ← HARNESS_TYPECHECK_CMD 채우세요"
   189	  echo "                                                 (HARNESS_KNOWLEDGE_GATE 는 기본 켜짐)"
   190	else
   194	# ── 3) settings.json 병합 (기존 훅 보존) ────────────────────────────
   195	if [ -f "$DST/settings.json" ]; then
   196	  cp "$DST/settings.json" "$DST/settings.json.bak-$STAMP"
   197	  echo "   settings 백업 → settings.json.bak-$STAMP"
   198	fi
   199	python3 - "$DST/settings.json" "$SRC/settings.json" <<'PYEOF'
   200	import json, os, sys
   201	dst_path, src_path = sys.argv[1], sys.argv[2]
   202	with open(src_path) as f:
   203	    ours = json.load(f)
   204	cur = {}
   205	if os.path.exists(dst_path):
   206	    with open(dst_path) as f:
   207	        cur = json.load(f)
   208	hooks = cur.setdefault("hooks", {})
   209	added = 0
   210	for event, entries in ours.get("hooks", {}).items():
   211	    lst = hooks.setdefault(event, [])
   212	    existing_cmds = {
   213	        (entry.get("matcher"), h.get("command"))
   214	        for entry in lst
   215	        for h in entry.get("hooks", [])
   216	    }
   217	    for entry in entries:
   218	        # (matcher, command) 단위 병합 — "항목에 하나라도 있으면 전체 스킵"은 같은 항목에 묶인
   219	        # 새 훅(guard-codex-invocation)이 기존 설치본에 영영 배선되지 않는 버그였고(2026-08-03),
   220	        # command만 보면 엉뚱한 matcher에 붙은 훅을 "배선됨"으로 오인한다([cx] 지적).
   221	        missing = [h for h in entry.get("hooks", [])
   222	                   if (entry.get("matcher"), h.get("command")) not in existing_cmds]
   223	        if not missing:
   224	            continue  # 전부 배선됨 (멱등)
   225	        target = next((e for e in lst if e.get("matcher") == entry.get("matcher")), None)
   226	        if target is not None:
   227	            target.setdefault("hooks", []).extend(missing)
   228	        else:
   229	            new_entry = {k: v for k, v in entry.items() if k != "hooks"}
   230	            new_entry["hooks"] = missing
   231	            lst.append(new_entry)
   232	        added += len(missing)
   233	        existing_cmds.update((entry.get("matcher"), h.get("command")) for h in missing)
   234	with open(dst_path, "w") as f:
   235	    json.dump(cur, f, ensure_ascii=False, indent=2)
   236	    f.write("\n")
   237	print(f"   settings.json ✓  훅 배선 {added}건 추가 (기존 훅 보존)")
   238	PYEOF
   239	
   240	# ── 4) CLAUDE.md 하네스 포인터 ───────────────────────────────────────
   241	if [ -f "$PROJECT/CLAUDE.md" ] && grep -q "harness-orchestrator" "$PROJECT/CLAUDE.md"; then
   242	  echo "   CLAUDE.md    포인터 이미 있음 (생략)"
   243	else
   244	  { [ -f "$PROJECT/CLAUDE.md" ] && [ -s "$PROJECT/CLAUDE.md" ] && echo ""; \
   245	    sed -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{YYYY-MM-DD}}/$TODAY/g" \
   246	        -e "s/{{한 줄 목표}}/($NAME 프로필 §1 참조)/g" \
   247	        "$TPL_ROOT/template/CLAUDE.md.snippet"; } >> "$PROJECT/CLAUDE.md"
   248	  echo "   CLAUDE.md ✓  하네스 포인터 append"
   249	fi
   250	
   251	echo ""
   252	echo "== 완료. 다음 단계:"
   253	echo "   1. $DST/harness/project-profile.md 의 §1~§8 채우기 (도메인 슬롯)"
   254	echo "   2. $DST/harness/harness.env 의 HARNESS_TYPECHECK_CMD 채우기"
   255	echo "   3. 새 Claude Code 세션 시작 (훅은 세션 시작 시 스냅샷 — 이번 세션엔 발화 안 함)"
   256	echo "   4. 개발 요청 → harness-orchestrator 스킬이 파이프라인 실행"

exec
/bin/zsh -lc "rg -n -e 'second[ -]brain' -e '[Oo]bsidian' -e '볼트' -e '_CLAUDE\\.md' -e '4종 세트' -e 'discussion-log' -e 'Projects/<name>' -e 'needs-vault' template global-agents || true; find template global-agents -type f | sed -n '1,160p'; nl -ba global-agents/*.md | sed -n '1,260p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
template/.claude/settings.json
template/.claude/agents/completion-auditor.md
template/.claude/agents/clarifier.md
template/.claude/agents/developer.md
template/.claude/agents/change-explainer.md
template/.claude/agents/architecture-guide.md
template/.claude/agents/pr-reviewer.md
template/.claude/agents/plan-reviewer.md
template/.claude/agents/pr-author.md
template/.claude/harness/harness.env.template
template/.claude/harness/principles.md
template/.claude/harness/project-profile.template.md
template/.claude/hooks/verify-before-stop.sh
template/.claude/hooks/guard-codex-invocation.sh
template/.claude/hooks/mark-needs-audit.sh
template/.claude/hooks/guard-master-commit.sh
template/.claude/hooks/_common.sh
template/.claude/skills/readable-writing/SKILL.md
template/.claude/skills/harness-orchestrator/SKILL.md
template/CLAUDE.md.snippet
global-agents/research-evaluator.md
global-agents/research-collector.md
usage: nl [-p] [-b type] [-d delim] [-f type] [-h type] [-i incr] [-l num]
          [-n format] [-s sep] [-v startnum] [-w width] [file]

exec
/bin/zsh -lc "rg -n \"§1~§8|§1～§8|1~8|9절|지식 진입점|PROJECT_NAME|project-profile\" README.md docs install.sh sync.sh template global-agents | sed -n '1,240p'; nl -ba template/.claude/harness/project-profile.template.md | sed -n '100,165p'; nl -ba template/.claude/skills/harness-orchestrator/SKILL.md | sed -n '15,115p'" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
install.sh:8:#   슬롯(project-profile.md · harness.env)      → 없을 때만 스캐폴드, 절대 안 덮음
install.sh:159:if [ ! -f "$DST/harness/project-profile.md" ]; then
install.sh:160:  sed "s/{{PROJECT_NAME}}/$NAME/g" "$SRC/harness/project-profile.template.md" \
install.sh:161:    > "$DST/harness/project-profile.md"
install.sh:162:  echo "   슬롯 생성 ✓  harness/project-profile.md   ← §1~§8 채우세요"
install.sh:164:  echo "   슬롯 보존    harness/project-profile.md   (기존 유지)"
install.sh:245:    sed -e "s/{{PROJECT_NAME}}/$NAME/g" -e "s/{{YYYY-MM-DD}}/$TODAY/g" \
install.sh:253:echo "   1. $DST/harness/project-profile.md 의 §1~§8 채우기 (도메인 슬롯)"
README.md:51:| **슬롯** (프로젝트 소유, 절대 안 덮음) | `project-profile.md`(도메인 전부: 스택·검증·불변식·경계면·운영·vcs·예시) · `harness.env`(타입체크 명령) | 사용자 |
README.md:162:│           ├── project-profile.template.md     # 슬롯 스키마 (9섹션)
sync.sh:125:echo "== sync 완료 ($changed개 글루 갱신). 슬롯(project-profile.md·harness.env)의 **값**은 그대로입니다."
template/CLAUDE.md.snippet:1:## 하네스: {{PROJECT_NAME}}
template/CLAUDE.md.snippet:9:**도메인 슬롯:** 이 프로젝트의 스택·아키텍처 불변식·경계면·운영 모델·검증 명령은 `.claude/harness/project-profile.md`에 있다.
docs/usage.md:27:1. `.claude/harness/project-profile.md` — §1~§8 (도메인 전부: 스택·검증 명령·불변식·경계면·운영·vcs·예시). 작성 예시는 이 repo의 `examples/chat-system.profile.md`.
docs/usage.md:39:| **슬롯 (프로젝트 소유)** | `harness/project-profile.md` · `harness/harness.env` | 사용자 — sync가 절대 안 덮음 |
docs/decisions/2026-08-06-knowledge-retrieval-policy.md:11:[ADR-0009](2026-08-06-profile-canon-upstream.md)가 **조회 방향을 배선**했다 — 프로필 9절 "지식 진입점" 슬롯, `ecc:architect`·`ecc:planner` 주입, 산출물 첫 줄의 `사전 결정 회수:`.
docs/decisions/2026-08-06-knowledge-retrieval-policy.md:65:- `사전 결정 회수:` 줄을 보고 회수가 검증된다고 오해할 여지가 남는다 — 그래서 그 줄을 내는 모든 자리(프로필 9절 · 오케스트레이터 스킬 · ADR-0009)에 "표명이지 강제가 아니다"를 함께 적었다
docs/decisions/2026-08-06-profile-canon-upstream.md:11:`project-profile.md` 는 이 하네스에서 **도메인 지식이 사는 단 하나의 파일**이다 — 스택 · 검증 명령 · 아키텍처 불변식 · 경계면 · 운영 모델. 오케스트레이터가 dispatch 마다 해당 절 전문을 프롬프트에 동봉한다. 이 파일이 낡거나 사라지면 파이프라인 전체가 도메인을 잃고, 에이전트들은 아무 근거 없이 그럴듯한 답을 만들기 시작한다.
docs/decisions/2026-08-06-profile-canon-upstream.md:23:**② 조회 방향을 배선한다 — 프로필 9절 "지식 진입점".**
docs/decisions/2026-08-06-profile-canon-upstream.md:63:- **기존 설치본에서는 조회 축이 수동이다.** 프로필 9절 슬롯은 사용자 산문이라 `sync.sh` 가 자동으로 넣지 않는다(슬롯은 절대 안 덮는다는 계약이 더 무겁다). 신규 설치는 `install.sh` 가 스캐폴드한다
docs/decisions/2026-08-06-profile-canon-upstream.md:68:새 9절이 들어가면서 기존 "참고 — 전역 의존" 이 10절이 됐다. 절 번호는 오케스트레이터 dispatch 표가 참조하는 **계약**이라 함께 고쳤다.
docs/decisions/2026-08-05-knowledge-store-layer-boundary.md:78:### C. `project-profile.md` 에 §10 "지식 저장소" 슬롯 신설
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

exec
/bin/zsh -lc "rg -n \"sync|슬롯 키 추가|append|HARNESS_KNOWLEDGE_GATE=\\\"on\\\"\" tests | sed -n '1,220p'; rg -n \"legacy_flag|플래그 이행|needs-\\"'$'"\\(printf|needs-vault\" tests install.sh; rg -n \"project-profile.*§1~§8|9절|지식 진입점\" tests docs/usage.md README.md install.sh sync.sh" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
tests/check-rule-copies.test.sh:382:            # 트레일러 문구까지 요구해 sync_fail 경로의 안내가 살아 있음을 고정한다
tests/mark-needs-audit.cases.sh:443:case_48() { # H1 — global-agents/ 는 전역 에이전트 **정본**이고 install/sync 가 배포한다.
tests/check-layer-boundary.test.sh:54:  printf '%s\n' 'HARNESS_KNOWLEDGE_GATE="on"' > "$d/.claude/harness.env"
install.sh:166:# 개명 전 플래그 이행 — **배포되지 않는 이 스크립트가 맡는다.**
install.sh:171:legacy_flag="$DST/.needs-$(printf 'vault')"
install.sh:172:if [ -f "$legacy_flag" ]; then
install.sh:173:  if [ -s "$legacy_flag" ]; then
install.sh:174:    if cat "$legacy_flag" >> "$DST/.needs-knowledge" 2>/dev/null; then
install.sh:175:      rm -f "$legacy_flag"
install.sh:176:      echo "   플래그 이행 ✓  미처리 지식 반영 항목을 새 이름으로 옮겼습니다"
install.sh:178:      echo "   ⚠ 미처리 지식 반영 플래그를 새 이름으로 옮기지 못했습니다: $legacy_flag" >&2
install.sh:182:    rm -f "$legacy_flag"
tests/check-layer-boundary.test.sh:116:c09() { leak_case '구현체 이름 플래그 — needs-vault' 'rm -f .claude/.needs-vault'     'needs-vault'; }
install.sh:162:  echo "   슬롯 생성 ✓  harness/project-profile.md   ← §1~§8 채우세요"
install.sh:253:echo "   1. $DST/harness/project-profile.md 의 §1~§8 채우기 (도메인 슬롯)"
docs/usage.md:27:1. `.claude/harness/project-profile.md` — §1~§8 (도메인 전부: 스택·검증 명령·불변식·경계면·운영·vcs·예시). 작성 예시는 이 repo의 `examples/chat-system.profile.md`.

exec
/bin/zsh -lc "find . -maxdepth 2 -type d -print | sort; find examples -type f -maxdepth 2 -print 2>/dev/null; rg -n -e 'second[ -]brain' -e '[Oo]bsidian' -e '볼트' -e '_CLAUDE\\.md' -e '4종 세트' -e 'discussion-log' -e 'Projects/<name>' -e 'needs-vault' examples 2>/dev/null || true" in /Users/kty/Downloads/kty-claude-harness-template
 succeeded in 0ms:
.
./.git
./.git/hooks
./.git/info
./.git/logs
./.git/objects
./.git/refs
./.github
./.github/workflows
./_workspace
./docs
./docs/decisions
./examples
./global-agents
./scripts
./template
./template/.claude
./tests
examples/chat-system.profile.md

2026-08-10T04:20:55.793359Z ERROR codex_models_manager::manager: failed to renew cache TTL: missing field `supports_reasoning_summaries` at line 93 column 5
codex
정적 독해 결과, 차단 결함이 남아 있습니다. 테스트는 지시대로 실행하지 않았고 파일도 변경하지 않았습니다.

[CRITICAL] template/.claude/hooks/_common.sh:138 — 혼합 인용 히어독 종결어를 앞부분까지만 읽어, 본문 속 빈 게이트 선언이 실제 선언으로 판독된다.

재현 조건:

```sh
cat <<E\OF
E
HARNESS_KNOWLEDGE_GATE=""
EOF
```

셸의 실제 종결어는 `EOF`지만 파서는 `E`로 저장합니다. 첫 `E`에서 히어독을 끝내고 본문의 `HARNESS_KNOWLEDGE_GATE=""`를 유일한 선언으로 읽어 rc=0·빈 값을 반환하므로 지식 게이트가 꺼집니다. `<<\EOF`만 검사하는 테스트로는 `<<E\OF`·`<<'E'OF`를 잡지 못합니다.

[HIGH] install.sh:87 — 기존 훅 안의 심링크를 스테이징에 보존한 뒤 템플릿 복사가 그 링크를 따라가 외부 사용자 파일을 덮어쓴다.

재현 조건: `.claude/hooks/_common.sh`를 프로젝트 밖의 중요 파일로 향하는 심링크로 둔 뒤 재설치합니다. `cp -R`이 링크를 스테이지에 복제하고, 다음 `cp`와 `chmod`가 목적지 링크의 실체를 덮고 실행 권한까지 바꿉니다. 테스트의 심링크 케이스는 훅 디렉터리 자체만 다루며 내부 심링크는 다루지 않습니다.

[HIGH] install.sh:95 — 파일시스템 조건이 “새 훅 설치 완료”와 “다른 프로세스가 대상 디렉터리를 재생성함”을 구분하지 못해 구판 백업을 삭제한다.

재현 조건: 첫 `mv` 뒤 두 rename 사이에 다른 설치나 프로세스가 `$DST/hooks`를 생성하고 TERM을 보냅니다. 핸들러는 대상이 존재한다는 이유로 106행 분기로 가서 구판 백업을 삭제합니다. 신호가 없으면 122행의 `mv`가 실패하지 않고 스테이지를 기존 디렉터리 안에 중첩시킬 수 있습니다. 현재 테스트는 이 창에서 대상 디렉터리가 계속 없다는 조건만 검사합니다.

[HIGH] install.sh:141 — 새 훅을 활성화하고 trap을 해제한 뒤에야 옛 플래그를 이행해, 중간 실패·신호가 미처리 의무를 무력화한다.

재현 조건: 비어 있지 않은 옛 플래그가 있는 프로젝트에서 `$HOME/.claude/agents` 생성을 실패시키거나 141~174행 사이에 신호를 보냅니다. 새 `_common.sh`는 이미 옛 플래그를 모르지만 이행은 실행되지 않아, 다음 Stop 훅이 기존 지식 반영 의무를 보지 못합니다.

[MEDIUM] template/.claude/hooks/_common.sh:126 — `OPENQ`가 이스케이프와 중첩 셸 문맥을 이해하지 못해 정상 셸 입력까지 rc=1로 만든다.

재현 조건:

```sh
NOTES="a\"b"
HARNESS_TYPECHECK_CMD="false"
```

이스케이프된 `\"`를 닫는 따옴표로 오인해 두 번째 선언을 인용 내부로 처리합니다. `$'can\'t'`, 백틱, `$(...)` 안의 독립된 인용도 같은 단일 상태 문제를 가집니다. 그 결과 정상 타입체크 명령이 “읽지 못함”이 되어 검사가 생략됩니다.

[MEDIUM] template/.claude/hooks/_common.sh:165 — 셸에서 유효하고 이전 파서가 지원하던 빈 대입+주석을 전부 문법 오류로 바꿨다.

재현 조건:

```sh
HARNESS_KNOWLEDGE_GATE= # intentionally disabled
```

이는 셸에서 명확한 빈 대입이지만 새 파서는 rc=1을 반환해 기본값인 게이트 켜짐으로 바꿉니다. `tests/harness-env-read.test.sh:268`은 이 호환성 회귀를 실패로 잡지 않고 새 기대값으로 고정합니다.

[MEDIUM] install.sh:74 — 교체된 훅 디렉터리가 기존 디렉터리 대신 `mktemp -d`의 메타데이터를 물려받는다.

재현 조건: 기존 `.claude/hooks`가 0755 또는 별도 ACL을 가진 공유 프로젝트에서 재설치합니다. 스테이지 최상위는 기본 0700으로 생성되고 이를 원래 디렉터리 메타데이터로 복원하는 처리가 없어 다른 사용자의 탐색·실행이 막힐 수 있습니다. 일반 `cp -R`도 보존 모드가 아니므로 사용자 메타데이터 보존 계약을 제공하지 않습니다.

[MEDIUM] install.sh:81 — 템플릿에서 삭제·개명된 옛 훅이 계속 보존되고 기존 settings 배선도 제거되지 않는다.

재현 조건: 이전 버전에 `old-hook.sh`와 그 settings 항목이 있었고 새 버전에서 둘을 삭제한 뒤 재설치합니다. 옛 파일은 스테이지로 복사되고, settings 병합은 추가만 하므로 옛 훅이 계속 발화합니다. 삭제가 보안 수정이어도 구버전 동작이 영구 잔류합니다.

[MEDIUM] tests/install-hook-swap.test.sh:159 — “복구 mv 자체의 실패” 수정은 테스트가 붙들지 않는다.

재현 조건: 두 번째 `mv`뿐 아니라 복구에 쓰이는 세 번째 `mv`도 실패시키는 shim으로 검사합니다. 현재 c06은 두 번째 호출만 실패시키고 복구 호출은 항상 성공시키므로, 백업 보존과 “되돌렸습니다” 금지 분기가 회귀해도 발견하지 못합니다. 내부 심링크·권한·옛 플래그 이행·대상 재생성 충돌도 빠져 있습니다.

[LOW] tests/check-layer-boundary.test.sh:192 — 기본 범위 테스트가 `global-agents/` 자체를 확인하지 않고 파일 수 증가만 확인한다.

재현 조건: `DEFAULT_ROOTS`에서 `global-agents`를 빼고 위반 없는 파일이 있는 `examples`를 넣습니다. 전체 파일 수는 여전히 `template` 단독보다 커서 c15가 통과하지만 전역 에이전트는 감시 밖입니다. 현재 구현의 보고 경로와 합산 개수 자체는 정적으로는 맞습니다.

[LOW] install.sh:162 — 새 프로필 9절을 추가했지만 설치 안내와 사용 문서는 계속 §1~§8만 작성하라고 한다.

재현 조건: 신규 설치 안내만 따라 프로필을 채우면 9절에 `{{지식 저장소에서...}}`가 남습니다. 오케스트레이터는 이를 진입점으로 주입하고 읽으라고 요구하므로 조회 단계가 실패하거나 형식적 “없음”으로 끝납니다. 기존 설치본에는 9절 추가 안내도 없습니다.

`<<\EOF` 접두형, `KEY=""#on`, `KEY=#on`, sync의 완전 일치 검증, 두 기본 스캔 루트의 현재 합산 구현, 복구 실패 시 백업을 남기는 본문 분기는 각각 의도대로 읽힙니다. 그러나 위 CRITICAL fail-open과 사용자 파일 손상 경로 때문에 승인할 수 없습니다.

판정: 보류
tokens used
131,309
정적 독해 결과, 차단 결함이 남아 있습니다. 테스트는 지시대로 실행하지 않았고 파일도 변경하지 않았습니다.

[CRITICAL] template/.claude/hooks/_common.sh:138 — 혼합 인용 히어독 종결어를 앞부분까지만 읽어, 본문 속 빈 게이트 선언이 실제 선언으로 판독된다.

재현 조건:

```sh
cat <<E\OF
E
HARNESS_KNOWLEDGE_GATE=""
EOF
```

셸의 실제 종결어는 `EOF`지만 파서는 `E`로 저장합니다. 첫 `E`에서 히어독을 끝내고 본문의 `HARNESS_KNOWLEDGE_GATE=""`를 유일한 선언으로 읽어 rc=0·빈 값을 반환하므로 지식 게이트가 꺼집니다. `<<\EOF`만 검사하는 테스트로는 `<<E\OF`·`<<'E'OF`를 잡지 못합니다.

[HIGH] install.sh:87 — 기존 훅 안의 심링크를 스테이징에 보존한 뒤 템플릿 복사가 그 링크를 따라가 외부 사용자 파일을 덮어쓴다.

재현 조건: `.claude/hooks/_common.sh`를 프로젝트 밖의 중요 파일로 향하는 심링크로 둔 뒤 재설치합니다. `cp -R`이 링크를 스테이지에 복제하고, 다음 `cp`와 `chmod`가 목적지 링크의 실체를 덮고 실행 권한까지 바꿉니다. 테스트의 심링크 케이스는 훅 디렉터리 자체만 다루며 내부 심링크는 다루지 않습니다.

[HIGH] install.sh:95 — 파일시스템 조건이 “새 훅 설치 완료”와 “다른 프로세스가 대상 디렉터리를 재생성함”을 구분하지 못해 구판 백업을 삭제한다.

재현 조건: 첫 `mv` 뒤 두 rename 사이에 다른 설치나 프로세스가 `$DST/hooks`를 생성하고 TERM을 보냅니다. 핸들러는 대상이 존재한다는 이유로 106행 분기로 가서 구판 백업을 삭제합니다. 신호가 없으면 122행의 `mv`가 실패하지 않고 스테이지를 기존 디렉터리 안에 중첩시킬 수 있습니다. 현재 테스트는 이 창에서 대상 디렉터리가 계속 없다는 조건만 검사합니다.

[HIGH] install.sh:141 — 새 훅을 활성화하고 trap을 해제한 뒤에야 옛 플래그를 이행해, 중간 실패·신호가 미처리 의무를 무력화한다.

재현 조건: 비어 있지 않은 옛 플래그가 있는 프로젝트에서 `$HOME/.claude/agents` 생성을 실패시키거나 141~174행 사이에 신호를 보냅니다. 새 `_common.sh`는 이미 옛 플래그를 모르지만 이행은 실행되지 않아, 다음 Stop 훅이 기존 지식 반영 의무를 보지 못합니다.

[MEDIUM] template/.claude/hooks/_common.sh:126 — `OPENQ`가 이스케이프와 중첩 셸 문맥을 이해하지 못해 정상 셸 입력까지 rc=1로 만든다.

재현 조건:

```sh
NOTES="a\"b"
HARNESS_TYPECHECK_CMD="false"
```

이스케이프된 `\"`를 닫는 따옴표로 오인해 두 번째 선언을 인용 내부로 처리합니다. `$'can\'t'`, 백틱, `$(...)` 안의 독립된 인용도 같은 단일 상태 문제를 가집니다. 그 결과 정상 타입체크 명령이 “읽지 못함”이 되어 검사가 생략됩니다.

[MEDIUM] template/.claude/hooks/_common.sh:165 — 셸에서 유효하고 이전 파서가 지원하던 빈 대입+주석을 전부 문법 오류로 바꿨다.

재현 조건:

```sh
HARNESS_KNOWLEDGE_GATE= # intentionally disabled
```

이는 셸에서 명확한 빈 대입이지만 새 파서는 rc=1을 반환해 기본값인 게이트 켜짐으로 바꿉니다. `tests/harness-env-read.test.sh:268`은 이 호환성 회귀를 실패로 잡지 않고 새 기대값으로 고정합니다.

[MEDIUM] install.sh:74 — 교체된 훅 디렉터리가 기존 디렉터리 대신 `mktemp -d`의 메타데이터를 물려받는다.

재현 조건: 기존 `.claude/hooks`가 0755 또는 별도 ACL을 가진 공유 프로젝트에서 재설치합니다. 스테이지 최상위는 기본 0700으로 생성되고 이를 원래 디렉터리 메타데이터로 복원하는 처리가 없어 다른 사용자의 탐색·실행이 막힐 수 있습니다. 일반 `cp -R`도 보존 모드가 아니므로 사용자 메타데이터 보존 계약을 제공하지 않습니다.

[MEDIUM] install.sh:81 — 템플릿에서 삭제·개명된 옛 훅이 계속 보존되고 기존 settings 배선도 제거되지 않는다.

재현 조건: 이전 버전에 `old-hook.sh`와 그 settings 항목이 있었고 새 버전에서 둘을 삭제한 뒤 재설치합니다. 옛 파일은 스테이지로 복사되고, settings 병합은 추가만 하므로 옛 훅이 계속 발화합니다. 삭제가 보안 수정이어도 구버전 동작이 영구 잔류합니다.

[MEDIUM] tests/install-hook-swap.test.sh:159 — “복구 mv 자체의 실패” 수정은 테스트가 붙들지 않는다.

재현 조건: 두 번째 `mv`뿐 아니라 복구에 쓰이는 세 번째 `mv`도 실패시키는 shim으로 검사합니다. 현재 c06은 두 번째 호출만 실패시키고 복구 호출은 항상 성공시키므로, 백업 보존과 “되돌렸습니다” 금지 분기가 회귀해도 발견하지 못합니다. 내부 심링크·권한·옛 플래그 이행·대상 재생성 충돌도 빠져 있습니다.

[LOW] tests/check-layer-boundary.test.sh:192 — 기본 범위 테스트가 `global-agents/` 자체를 확인하지 않고 파일 수 증가만 확인한다.

재현 조건: `DEFAULT_ROOTS`에서 `global-agents`를 빼고 위반 없는 파일이 있는 `examples`를 넣습니다. 전체 파일 수는 여전히 `template` 단독보다 커서 c15가 통과하지만 전역 에이전트는 감시 밖입니다. 현재 구현의 보고 경로와 합산 개수 자체는 정적으로는 맞습니다.

[LOW] install.sh:162 — 새 프로필 9절을 추가했지만 설치 안내와 사용 문서는 계속 §1~§8만 작성하라고 한다.

재현 조건: 신규 설치 안내만 따라 프로필을 채우면 9절에 `{{지식 저장소에서...}}`가 남습니다. 오케스트레이터는 이를 진입점으로 주입하고 읽으라고 요구하므로 조회 단계가 실패하거나 형식적 “없음”으로 끝납니다. 기존 설치본에는 9절 추가 안내도 없습니다.

`<<\EOF` 접두형, `KEY=""#on`, `KEY=#on`, sync의 완전 일치 검증, 두 기본 스캔 루트의 현재 합산 구현, 복구 실패 시 백업을 남기는 본문 분기는 각각 의도대로 읽힙니다. 그러나 위 CRITICAL fail-open과 사용자 파일 손상 경로 때문에 승인할 수 없습니다.

판정: 보류
