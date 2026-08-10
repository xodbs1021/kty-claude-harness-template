## 검수 결과

1. **HIGH — 가드가 정본이 아닌 다른 저장소를 검사할 수 있음**  
   [scripts/deploy-guard.sh:33](/Users/kty/Downloads/kty-claude-harness-template/scripts/deploy-guard.sh:33), [scripts/deploy-guard.sh:56](/Users/kty/Downloads/kty-claude-harness-template/scripts/deploy-guard.sh:56)

   `git -C "$tpl"` 호출에서 상속된 `GIT_DIR`·`GIT_WORK_TREE`를 제거하지 않는다. 다른 저장소를 가리키는 두 변수가 설정된 환경에서 실행하면 `-C`와 무관하게 그 저장소의 gitdir·status를 검사할 수 있다.  
   **정본에는 변이 락이나 미커밋 변경이 있음 → 외부의 깨끗한 저장소를 검사 → 아무 경고 없이 배포 허용**이라는 핵심 위음성이다. ADR의 “정본 트리를 검사한다”는 계약과 불일치한다.

2. **HIGH — 핵심 기본·sync 경로가 테스트에서 전혀 고정되지 않음**  
   [tests/install-hook-swap.test.sh:92](/Users/kty/Downloads/kty-claude-harness-template/tests/install-hook-swap.test.sh:92), [tests/install-hook-swap.test.sh:271](/Users/kty/Downloads/kty-claude-harness-template/tests/install-hook-swap.test.sh:271), [sync.sh:31](/Users/kty/Downloads/kty-claude-harness-template/sync.sh:31)

   기존 c01~c09는 모두 `--allow-dirty`로 실행되고, c10·c11·c13은 거부가 기대값이며, 유일한 성공 c12도 `--allow-dirty`를 사용한다. 따라서 **클린 git 정본에서 옵션 없이 설치가 성공하는 기본 경로가 없다**. 또한 새 케이스는 모두 `install.sh`만 호출하여 다음 ADR 계약을 전혀 검증하지 않는다.

   - sync 가드가 pull보다 먼저 실행되는지
   - `--allow-dirty`가 내부 install 호출에 전달되는지
   - `--no-pull`과의 인자 순서 조합
   - 비-git 정본의 경고 후 진행
   - status 실패의 기본 거부와 옵트인
   - 가드 파일 부재 시 경고

   예컨대 sync의 가드 호출이나 옵션 전달을 삭제해도 13개 케이스가 모두 통과할 수 있다.

3. **HIGH — 원시 Codex 실행 로그가 배포 diff에 함께 커밋됨**  
   [_workspace/13_codex_design_review.err:1](/Users/kty/Downloads/kty-claude-harness-template/_workspace/13_codex_design_review.err:1)

   대상 목록에 없는 5,510줄짜리 stderr/transcript가 추가돼 있다. 세션 ID, 로컬 절대경로, 다른 작업의 사용자 프롬프트와 저장소 운영 정보가 그대로 포함되며, 수백 건의 후행 공백 때문에 `git diff --check origin/main..HEAD`도 실패한다. 기능 변경과 무관한 실행 부산물이며 정보 노출과 검증 실패를 동시에 만든다.

4. **HIGH — ADR-0014가 존재하지 않는 세 번째 락 생산자를 “이미 사용 중”이라고 공시함**  
   [2026-08-10-deploy-path-guard.md:22](/Users/kty/Downloads/kty-claude-harness-template/docs/decisions/2026-08-10-deploy-path-guard.md:22)

   ADR은 `mutate-retrieval-gate`까지 세 하네스가 락 규약을 “이미 쓰던 것”이라고 단정하지만, 이 diff와 기준 브랜치에는 `_workspace/mutate-decision-gate.sh`와 `_workspace/mutate-harness-env.sh` 두 개뿐이다. `mutate-retrieval-gate`는 ADR과 테스트용 락 이름 외에는 존재하지 않는다.  
   **운영자가 세 측정 경로 모두 가드된다고 신뢰 → 실제로 락을 만들지 않는 경로를 배포 가드가 탐지할 수 없음**이라는 거짓 안전 공시다. 향후 PR을 뜻한다면 미래형·의존 관계로 기록해야 한다.

5. **MEDIUM — “대상 무변경”이라는 테스트 공시보다 실제 단언이 약함**  
   [tests/install-hook-swap.test.sh:274](/Users/kty/Downloads/kty-claude-harness-template/tests/install-hook-swap.test.sh:274), [tests/install-hook-swap.test.sh:289](/Users/kty/Downloads/kty-claude-harness-template/tests/install-hook-swap.test.sh:289), [2026-08-10-deploy-path-guard.md:56](/Users/kty/Downloads/kty-claude-harness-template/docs/decisions/2026-08-10-deploy-path-guard.md:56)

   c10·c11은 대상 디렉터리를 테스트가 먼저 만들고, 거부 후에는 `.claude/hooks` 존재 여부만 확인한다. 대상 전체 스냅숏이나 legacy flag 같은 기존 파일은 확인하지 않는다. 가드가 legacy 이행 뒤·hooks 생성 전에 이동해 대상 파일을 변경해도 테스트는 통과한다. rc 단독 판정은 피했지만 ADR이 공시한 “대상 디렉터리가 안 만들어졌는지/대상 무변경”까지 붙들지는 못한다.

Bash 3.2 배열 복원 관용구, 글롭 무매치 처리, 호출부의 명시적 `|| exit 1`, 통과 안내의 닫힌 stderr용 `|| true`에서는 별도 차단급 문제를 찾지 못했다. 실행 테스트는 요청대로 하지 않았다.

판정: 보류
