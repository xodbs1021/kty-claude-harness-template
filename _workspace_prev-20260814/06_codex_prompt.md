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
