판정: 보류

- **HIGH — [check-harness-env.sh:45](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/check-harness-env.sh:45)**  
  `file_path=.claude/harness/./harness.env`처럼 실제 정본을 가리키는 유효 경로 → 정규화 전에 문자열 앵커에서 탈락하여, 잘못된 `HARNESS_TYPECHECK_CMD`도 아무 경고 없이 통과합니다. `mark-needs-audit`는 `.`·`..`·심링크를 정규화하지만 이 훅은 그러지 않으며, c07도 정규 상대경로만 검사합니다. 핵심 기능의 위음성이고 ADR의 경로 처리 공시와도 어긋납니다.

- **HIGH — [mutate-env-check-hook.sh:28](/Users/kty/Downloads/kty-claude-harness-template/_workspace/mutate-env-check-hook.sh:28), [mutate-harness-env.sh:41](/Users/kty/Downloads/kty-claude-harness-template/_workspace/mutate-harness-env.sh:41)**  
  변이 주입 후 테스트 도중 SIGINT/SIGTERM·비정상 종료 → EXIT trap은 락만 지우고 변이된 `_common.sh`/Stop 훅을 복원하지 않습니다. 따라서 변이 또는 구판 전체가 실제 소스에 남을 수 있습니다. 특히 후자는 과거 변이본 오커밋 사고를 방지한다고 공시하면서 같은 잔류 경로를 열어 둡니다.

- **MEDIUM — [check-harness-env.sh:58](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/check-harness-env.sh:58), [_common.sh:275](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/_common.sh:275)**  
  `HARNESS_KNOWLEDGE_GATE= "on"` → 훅은 “미설정으로 취급되고 해당 검사가 조용히 생략”된다고 경고하지만, 실제 지식 게이트는 rc=1에서 fail-closed로 **켜집니다**. 경고 자체는 필요하지만 결과 설명과 ADR의 “해당 검사 생략” 공시는 실물과 반대입니다.

- **MEDIUM — [check-harness-env.test.sh:60](/Users/kty/Downloads/kty-claude-harness-template/tests/check-harness-env.test.sh:60), [settings.json:25](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/settings.json:25)**  
  테스트가 훅 파일을 직접 실행할 뿐 `settings.json` 배선을 거치지 않습니다. PostToolUse 배선을 삭제하거나 matcher를 틀리게 바꾼 상태 → 실제 편집에서는 경고가 전혀 나오지 않지만 12케이스와 7변이는 그대로 통과할 수 있습니다.

rc 전수 호출부, awk의 `3`/기타 rc 매핑, 선언 2개·조기 종료·Stop rc 구별 재조준 앵커, bash 3.2 금지 문법은 정적 독해상 이상을 찾지 못했습니다.

미확인: 요청에 따라 테스트·변이 스크립트는 실행하지 않았습니다. 또한 워킹트리에는 검수 대상 밖 미추적 파일 `_workspace/39_codex_envhook_review.md`가 있었으며, 추적 대상은 모두 `git show HEAD:` 기준으로 읽었습니다.
