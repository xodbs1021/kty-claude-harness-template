판정: 보류

1.

- 심각도: HIGH
- 근거 파일: [_workspace/00_design-reference-gate.md:159](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:159), [_workspace/00_design-reference-gate.md:164](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:164), [verify-before-stop.sh:119](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:119), [verify-before-stop.sh:376](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:376)
- 시나리오: 한 파일의 첫째 줄과 둘째 줄이 모두 불량인 상태로 3회 차단 → 첫째 줄만 고치고 다시 종료. 불량 경로 집합은 여전히 같은 파일 하나이므로 예산 키 `retrieval:<경로>`가 변하지 않는다. `count=3`인 다음 호출에서 남은 둘째 줄 불량 메시지를 내기도 전에 예산 소진 분기가 모든 플래그를 삭제하고 통과시킨다. 두 독립 검사를 경로 하나로 축약하면서 실제 진전을 진전으로 인식하지 못한다. r14는 파일 집합 감소만 검사하고, r37도 단발 독립성만 검사하므로 이 경로를 잡지 못한다.

2.

- 심각도: HIGH
- 근거 파일: [_workspace/00_design-reference-gate.md:185](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:185), [SKILL.md:171](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/skills/harness-orchestrator/SKILL.md:171)
- 시나리오: 오케스트레이터가 “조사 필요”로 판정 → collector 또는 evaluator가 두 번 실패. 기존 공통 에러 처리 계약은 “결과 없이 진행하되 누락 명시”하라고 한다. 따라서 필수 조사 없이 architect·planner로 진행하거나, 작성자가 다시 `레퍼런스 조사 필요`를 반환해 같은 흐름을 반복한다. 새 파이프라인이 이 기존 규칙의 예외인지 명시되지 않아 핵심 의무가 산문 계약상으로도 보장되지 않는다.

3.

- 심각도: HIGH
- 근거 파일: [_workspace/00_design-reference-gate.md:185](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:185), [research-evaluator.md:12](/Users/kty/Downloads/kty-claude-harness-template/global-agents/research-evaluator.md:12), [research-evaluator.md:43](/Users/kty/Downloads/kty-claude-harness-template/global-agents/research-evaluator.md:43), [research-evaluator.md:60](/Users/kty/Downloads/kty-claude-harness-template/global-agents/research-evaluator.md:60)
- 시나리오: evaluator가 전건 기각 또는 `재수집 필요`를 반환. 설계에는 “평가 통과분을 주입”하는 정상 전이만 있고, 채택 0건·재수집 판정의 다음 상태가 없다. 그대로 진행하면 필요한 조사를 하지 않은 결과가 되고, collector로 무조건 되돌리면 같은 검색 공백을 무한 반복할 수 있다. 사용자 에스컬레이션·종결 판정·조사 불능 표명 중 어느 경로도 정의되지 않았다.

4.

- 심각도: MEDIUM
- 근거 파일: [_workspace/00_design-reference-gate.md:88](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:88), [_workspace/00_design-reference-gate.md:235](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:235), [retrieval-attestation.test.sh:128](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:128), [mutate-retrieval-gate.sh:92](/Users/kty/Downloads/kty-claude-harness-template/_workspace/mutate-retrieval-gate.sh:92)
- 시나리오: 현재 `mk_doc`는 모든 비어 있지 않은 파일에 둘째 줄 `본문.`을 쓴다. 설계 주장대로 r03~r06 불량 픽스처를 그대로 두면 새 둘째 줄 검사에서도 불량이다. 이 상태에서 m01·m05로 첫째 줄 검사를 무력화해도 둘째 줄 때문에 계속 차단되어 기존 케이스가 통과하고 변이가 살아남는다. 따라서 “GOOD 픽스처만 갱신·불량 픽스처 불변” 주장은 성립하지 않는다. 첫째 줄 방어를 재려는 픽스처에도 정상 둘째 줄을 넣어 두 검사를 격리해야 한다. 기존 단언 문구 자체는 불변 가능하지만 픽스처 변경 범위는 공시보다 넓다.

5.

- 심각도: MEDIUM
- 근거 파일: [_workspace/00_design-reference-gate.md:88](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:88), [_workspace/00_design-reference-gate.md:167](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:167), [mutate-retrieval-gate.sh:139](/Users/kty/Downloads/kty-claude-harness-template/_workspace/mutate-retrieval-gate.sh:139), [mutate-retrieval-gate.sh:169](/Users/kty/Downloads/kty-claude-harness-template/_workspace/mutate-retrieval-gate.sh:169)
- 시나리오: 구현에서 차단 메시지를 두 표명 안내로 바꾸거나 3.4 제목을 “산출물 머리 표명 게이트”로 일반화 → m10은 기존 메시지 두 줄을, m15는 `# (3.4) **회수 표명 게이트**`를 정확 문자열 앵커로 사용하므로 0회 매치할 수 있다. 하네스는 안전하게 실패하겠지만 변이 측정을 수행하지 못한다. “18종 앵커가 모두 첫째 줄·상태기계라 영향 없음”은 실물과 다르며 앵커 전수 재검증이 필요하다.

6.

- 심각도: MEDIUM
- 근거 파일: [_workspace/00_design-reference-gate.md:133](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:133), [_workspace/00_design-reference-gate.md:140](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:140), [_workspace/00_design-reference-gate.md:157](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:157), [_workspace/00_design-reference-gate.md:237](/Users/kty/Downloads/kty/claude-harness-template/_workspace/00_design-reference-gate.md:237)
- 시나리오: 형식 문법에는 변형과 `(` 사이 공백 자리가 없지만, 바로 아래 산문은 `조사함 (…)`을 허용한다. 또한 알고리즘의 “변형 → `(` 존재”는 변형 뒤에 공백만 허용한다는 경계를 명시하지 않는다. Bash 3.2 구현에 따라 정상 입력 `조사함 (Netflix)`이 거부되거나, 불량 입력 `조사함X(Netflix)`가 “조사함 접두어·괄호 존재·마지막 `)`” 조건으로 통과할 수 있다. 신규 케이스에는 두 입력 모두 없다. `<공백*>`도 ASCII 공백·탭·POSIX `[:space:]` 중 무엇인지 정의하지 않아 U+3000 같은 멀티바이트 공백의 판정이 로케일별로 달라질 수 있다.

7.

- 심각도: MEDIUM
- 근거 파일: [_workspace/00_design-reference-gate.md:69](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:69), [_workspace/00_design-reference-gate.md:162](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:162), [retrieval-attestation.test.sh:572](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:572), [mutate-retrieval-gate.sh:204](/Users/kty/Downloads/kty-claude-harness-template/_workspace/mutate-retrieval-gate.sh:204)
- 시나리오: 문서가 정상 두 줄이고 둘째 줄 마지막에 LF가 없음 → 둘째 `read`의 `|| [ -n "$refline" ]`이 빠진 구현은 정상 표명을 “둘째 줄 없음”으로 차단한다. 설계가 짝으로 든 r26과 m18은 문서가 아니라 `.needs-retrieval` 플래그 파일의 마지막 줄만 검사한다. r28~r40과 m19~m25에도 문서 둘째 줄 무개행 방어가 없어 이 약속은 측정되지 않는다.

8.

- 심각도: MEDIUM
- 근거 파일: [_workspace/00_design-reference-gate.md:269](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:269), [SKILL.md:139](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/skills/harness-orchestrator/SKILL.md:139), [SKILL.md:208](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/skills/harness-orchestrator/SKILL.md:208)
- 시나리오: ⑦-3 표에 적힌 자리만 갱신 → Phase 6 게이트 요약은 계속 네 플래그와 기존 실행 순서만 설명하고, 정상 흐름 테스트 시나리오도 planner 앞의 조사 파이프라인을 생략한다. 운영자가 SKILL의 요약·정상 흐름을 정본으로 따라가면 새 조사 단계가 없는 흐름을 정상으로 인식한다. 따라서 “기존 계약 자리 전수 갱신” 표는 전수가 아니다. 반면 ADR-0013 ⑴의 역사 문구는 ADR-0015가 명시적으로 갱신하도록 한 방식이라 정합 처리 자체는 타당하다.

9.

- 심각도: MEDIUM
- 근거 파일: [_workspace/00_design-reference-gate.md:18](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:18), [_workspace/00_design-reference-gate.md:140](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:140), [_workspace/00_design-reference-gate.md:283](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:283)
- 시나리오: `레퍼런스 조사: 조사함(Netflix)`처럼 대상만 있고 출처가 전혀 없는 입력도 “공백 아닌 내용”이라 기계 통과한다. 머리 계약은 `<대상·출처>`를 요구하지만 문법은 둘의 존재나 구분을 검사하지 않는다. 8절은 “지어낸 출처”는 공시하지만 “출처가 아예 없어도 통과”는 공시하지 않는다. 같은 절에 위 예산 키의 부분 수정 무인지, 조사 에이전트 실패 시 기존 무결과 진행 규칙, evaluator 재수집의 비종결 가능성도 빠져 있다.

반증하지 못한 주장:

- `mark-needs-audit.sh`의 설계 산출물 분기는 이미 듀얼리뷰·지식·retrieval 세 플래그를 기록하므로 로직 변경은 불필요하다.
- `FLAG_NAMES`는 이미 5종을 포함해 불변 주장이 맞다.
- 내부 괄호와 둘째 줄 CR은 각각 r40·r36으로 계획되어 있다.
- 실제 외부 `ecc:architect`·`ecc:planner`의 도구 권한이 정말 Read·Grep·Glob뿐인지는 저장소 밖 정의라 미확인이다.

파일 변경 및 테스트·변이 실행은 하지 않았다.
