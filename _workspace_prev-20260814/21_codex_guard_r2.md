5건 중 3건은 폐쇄, 2건은 부분 폐쇄입니다. 정적 독해만 수행했고 테스트는 실행하지 않았습니다.

1. **HIGH — `GIT_DIR` 오염이 `sync`의 pull 경로에는 남아 있음**

   가드의 `rev-parse`와 `status`는 환경 변수를 정상적으로 소거합니다. 그러나 이후 [sync.sh](/Users/kty/Downloads/kty-claude-harness-template/sync.sh:43)의 `rev-parse`와 [pull](/Users/kty/Downloads/kty-claude-harness-template/sync.sh:44)은 그대로입니다.

   외부 저장소를 가리키는 `GIT_DIR`·`GIT_WORK_TREE` 환경에서 실행 → 가드는 정본을 올바르게 검사 → 이후 다른 저장소에 `pull`을 수행하거나 정본 갱신을 건너뜀. 라운드 1의 가드 위음성은 고쳤지만 배포 경로 전체의 환경 오염은 제거되지 않았습니다. 이 코드는 fix에서 새로 생긴 것은 아니지만 이번 수정으로도 남은 차단급 결함입니다.

2. **HIGH — 테스트 공백이 완전히 닫히지 않음**

   c14·c15·c17·c18은 각각 기본 설치, sync 옵트인 전달, 비-git 경고, 가드 부재 경고를 고정합니다. 하지만 [c16](/Users/kty/Downloads/kty-claude-harness-template/tests/install-hook-swap.test.sh:363)은 `--no-pull`로 실행되어 “가드가 pull보다 앞”이라는 핵심 계약을 실제로 검사하지 않습니다.

   가드를 pull 뒤·미리보기 앞으로 이동 → c16에서는 pull 자체가 비활성화됨 → 미리보기 전에 거부되어 테스트 통과 → 실제 sync에서는 락이 있는 상태로 pull 실행. 또한 `git status` 실패의 기본 거부·옵트인 경로와 오염된 `GIT_DIR` 회귀도 여전히 테스트되지 않습니다.

3. **MEDIUM — fix 커밋도 `git diff --check`를 통과하지 못함**

   원시 `.err` 로그는 삭제됐고 `_workspace/*.err` 무시 규칙도 정상입니다. 다만 새로 커밋된 [20_codex_guard_review.md](/Users/kty/Downloads/kty-claude-harness-template/_workspace/20_codex_guard_review.md:3)의 Markdown 후행 공백 6건 때문에 `git diff --check HEAD~1..HEAD`가 여전히 실패합니다. 정보 노출은 폐쇄됐지만 검증 실패라는 부수 결과가 새 형태로 남았습니다.

나머지는 폐쇄됐습니다.

- ADR은 기존 생산자 2종과 PR #19의 미래 생산자를 구분했습니다.
- c10·c11은 `empty_dir`로 프로젝트 전체의 추가 파일을 검사합니다.
- 추적 중인 `.err` 파일은 없고 `.gitignore` 규칙도 적용됩니다.

판정: 보류
