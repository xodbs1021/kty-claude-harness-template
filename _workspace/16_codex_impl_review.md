- HIGH — [verify-before-stop.sh:289](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:289), [retrieval-attestation.test.sh:120](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:120): `.needs-retrieval`의 마지막 경로가 개행 없이 EOF로 끝나는 입력 → `read`가 값을 대입하고도 실패 상태를 반환해 `while` 본문이 실행되지 않음 → 불량 목록이 빈 것으로 판정되어 플래그를 자동 삭제합니다. 중단된 `record_flag` 쓰기 등으로 `_workspace/00_design.md`만 개행 없이 남고 해당 문서에 표명이 없어도 조용히 통과합니다. 테스트 픽스처는 모든 플래그 행에 항상 개행을 붙여 이 결함을 가립니다.

- HIGH — [retrieval-attestation.test.sh:19](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:19), [retrieval-attestation.test.sh:517](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:517), [ADR-0013:136](/Users/kty/Downloads/kty-claude-harness-template/docs/decisions/2026-08-10-knowledge-retrieval-policy-decided.md:136): 설계 v3의 23번 케이스인 “정상 해제 성공 경로에서 `decision_note` 방출” 대신 전혀 다른 지식 게이트 도달 케이스가 구현됐고, 테스트는 해당 경로가 측정 불가능하다고 명시합니다. 따라서 [verify-before-stop.sh:347](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:347)의 경고 방출을 삭제하는 변이 → 25케이스와 16개 변이가 모두 초록일 수 있습니다. 그런데 ADR은 설계서의 25케이스·15변이를 구현했고 통과 기대 케이스 전부가 후속 게이트를 확인한다고 주장합니다. ADR-0012 경고 전파 방어에 대한 거짓 공시입니다.

- MEDIUM — [mutate-retrieval-gate.sh:61](/Users/kty/Downloads/kty-claude-harness-template/_workspace/mutate-retrieval-gate.sh:61), [mutate-retrieval-gate.sh:179](/Users/kty/Downloads/kty-claude-harness-template/_workspace/mutate-retrieval-gate.sh:179): 변이 전 기준 테스트가 정상 통과하는지 확인하지 않습니다. 픽스처 문제나 무관한 회귀로 기준 테스트가 항상 실패하는 입력 → 모든 변이를 “적색”으로 집계 → `red == total`이라 하네스 자체는 성공 종료합니다. 따라서 “16변이 전건 적색”이 실제 방어 때문인지 보장되지 않습니다.

- MEDIUM — [verify-before-stop.sh:358](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:358): `sort -u | tr` 파이프라인 실패 상태를 검사하지 않습니다. 제한된 `PATH`, 명령 실행 실패 또는 I/O 오류 → `pipefail`이 비영 rc를 만들지만 `set -e`가 없어 계속 진행 → 비어 있거나 부분적인 예산 키가 사용됩니다. 사용자가 불량 파일을 하나씩 고쳐도 키가 변하지 않아 카운터가 누적되고, 결국 예산 소진이 모든 게이트 플래그를 지울 수 있습니다.

- MEDIUM — [pr-reviewer.md:26](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/agents/pr-reviewer.md:26): 설계 v3은 “ADR 포함 PR” 전부의 선행 결정 인용을 검사하도록 요구하지만 구현은 ADR이 “신설”된 경우로 제한합니다. 기존 ADR의 Decision을 수정하는 PR → 관련 절에 선행 결정 인용이 없어도 이 점검을 건너뜀 → 재결정·선행 결정 모순이 조용히 승인될 수 있습니다.

참고로 산출물 첫 줄 자체가 개행 없이 끝나는 경우는 `read ... || true`가 값을 보존하므로 정상 판정됩니다. `$'\xEF\xBB\xBF'`도 macOS bash 3.2 문법에 맞으며, 금지된 `mapfile`·연관배열·`${var,,}` 사용은 없습니다.

판정: 보류
