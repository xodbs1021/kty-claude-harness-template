판정: 보류

## 라운드 1 차단급 닫힘 확인

| 라운드 1 항목 | 판정 | 근거 |
|---|---|---|
| [cc·cx] 불량 픽스처 격리 | **미흡** | 일반 불량 첫 줄에 `GOOD_SECOND`를 넣는 방향은 맞다([설계:99](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:99)). 그러나 `r04`의 `EMPTY`는 실제 0바이트 파일이어야 하므로 정상 둘째 줄을 동시에 넣을 수 없다([테스트:195](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:195)). 첫 줄 빈 파일 방어를 제거해도 둘째 줄 누락이 대신 차단하는 겹침이 남는다. |
| [cc] 공통 헤드라인·`TOK_RET` 정책 | **닫힘** | 공통 헤드라인과 새 토큰 값을 명시했다([설계:195](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:195)). 기존 테스트가 상수 참조 구조라는 실물([테스트:49](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:49))과도 맞는다. |
| [cc·cx] m10·m15 앵커 무효화 | **닫힘** | 두 앵커 재조준과 전수 1회 매치 확인이 명시됐다([설계:107](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:107), [설계:331](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:331)). |
| [cc] `plan-reviewer.md` 계약 자리 누락 | **닫힘** | ⑦-3에 실물 파일 갱신이 들어갔고([설계:357](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:357)), r38도 네 자리로 확장됐다([설계:314](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:314)). |
| [cc] 결정 게이트 위양성 | **닫힘** | 불요·실패 사유를 보고할 때 백틱/따옴표로 감싸는 계약과 한계 공시가 모두 있다([설계:259](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:259), [설계:383](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:383)). |
| [cc·cx] 문서 둘째 줄 무개행 방어 | **닫힘** | 읽기 관용구와 r41·m26이 정확히 대응한다([설계:179](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:179), [설계:319](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:319), [설계:341](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:341)). |
| [cx] 파일 내 부분 진전 예산 리셋 | **닫힘** | 불량 항목을 `<경로>#1/#2`로 분리하며 r45·m28도 붙었다([설계:182](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:182), [설계:324](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:324), [설계:343](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:343)). `flags_fp`에는 계속 존재 비트만 둬 r24 계약도 보존한다. |
| [cx] 조사 실패와 기존 무결과 진행 규칙 충돌 | **닫힘** | 기존 규칙의 적용 방법과 `실패(<시도 — 사유>)` 표명 자리를 명시했다([설계:237](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:237)). 단, 아래 신규 HIGH의 재시도 전이는 별개로 남는다. |
| [cx] evaluator 전건 기각·재수집 비종결 | **닫힘** | 재수집 1회 상한, 채택 0건 결과 주입, 이후 실패 접기가 정의됐다([설계:229](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:229)). |

라운드 1 MEDIUM·LOW 중 ADR 역참조, 조사 필요 기준·비용, Phase 6 요약·정상 흐름, 유의어·전각 괄호 공시는 문구상 닫혔다. 공백·로케일 계약과 픽스처 방어 밀도는 아래와 같이 미흡하다. 외부 `ecc:architect`·`ecc:planner`의 실제 도구 권한은 저장소 밖 정의이므로 **미확인**이다.

## 신규 지적

### HIGH — `실패` 변형의 빈 사유 우회를 모든 계획 테스트·변이가 놓친다

- 근거: [설계:149](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:149), [설계:163](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:163), [설계:307](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:307), [설계:323](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:323), [설계:334](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:334)
- 시나리오: 구현자가 `조사함`·`불요`에만 내용 비어 있지 않음 검사를 적용하고 `실패` 분기는 변형 인식 즉시 통과시킨다. 그러면 `레퍼런스 조사: 실패()` 또는 `실패(   )`가 통과한다.
- r33은 `조사함()`, r34는 `불요(   )`만 검사한다. r44는 정상 `실패(<사유>)`만 검사하고 m29도 `실패` 변형의 존재만 잰다. 따라서 위 결함이 있어도 r28~r45와 m19~m29가 전부 기대대로 끝날 수 있다.
- 조사 필요 작업을 빈 `실패()` 한 줄로 면제하므로 새 변형이 만든 핵심 기계 우회다.

### HIGH — 검수의 “조사 재시도 필요” 판정에서 조사 파이프라인으로 돌아가는 전이가 없다

- 근거: [설계:237](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:237), [설계:264](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:264), [설계:271](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:271), [SKILL.md:99](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/skills/harness-orchestrator/SKILL.md:99), [SKILL.md:102](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/skills/harness-orchestrator/SKILL.md:102)
- 시나리오: collector/evaluator 실패 → 작성자가 `실패(...)` 표명 → plan-reviewer가 “사유 불충분, 조사 재시도 필요”로 보류한다. 기존 Phase 2 보류 전이는 architect 또는 planner에게만 되돌린다. 두 작성자는 조사 dispatch 주체가 아니므로 재시도를 수행할 수 없다.
- 결과는 같은 `실패` 반복, 거짓 `조사함` 수정, 또는 비종결이다. “검수가 재시도 필요성을 심사한다”는 계약의 판정 결과를 소비하는 전이가 빠졌다. 보류 사유가 조사 재시도이면 오케스트레이터의 collector 단계로 돌아간다는 경로와 총 재시도 상한이 필요하다.

### MEDIUM — `r04`는 기존 첫 줄 방어를 격리할 수 없다

- 근거: [설계:99](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:99), [테스트:128](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:128), [테스트:195](/Users/kty/Downloads/kty-claude-harness-template/tests/retrieval-attestation.test.sh:195)
- 시나리오: `EMPTY`를 계속 0바이트로 만들면 둘째 줄도 불량이라 첫 줄 빈 파일 판정을 제거한 변이가 살아남는다. 정상 둘째 줄을 넣으면 더는 “빈 파일” 케이스가 아니다.
- 첫 줄 빈 줄과 0바이트 파일을 분리하거나, 해당 방어 제거 변이를 별도 격리 픽스처로 재야 한다.

### MEDIUM — `<SP>`와 C 로케일 주장이 기계 계획으로 고정되지 않았다

- 근거: [설계:149](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:149), [설계:151](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:151), [설계:160](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:160), [verify-before-stop.sh:11](/Users/kty/Downloads/kty-claude-harness-template/template/.claude/hooks/verify-before-stop.sh:11)
- 시나리오: 훅은 현재 로케일을 고정하지 않는다. 구현도 현행처럼 `tr -d '[:space:]'`만 사용하면 실행 환경의 문자 분류에 따라 U+3000만 든 내용의 판정이 달라질 수 있다. v2의 “C 로케일 바이트 판정으로 통과” 공시는 구현 지시나 테스트로 고정되지 않았다.
- r43은 변형 뒤 ASCII 공백 하나만 잰다. 콜론 뒤/닫는 괄호 뒤 공백, 탭, 비ASCII 공백 거부 경로는 측정되지 않는다.

### MEDIUM — ⑦-3 전수표에서 CI의 실물 계약 자리가 빠졌다

- 근거: [설계:350](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:350), [check-rules.yml:44](/Users/kty/Downloads/kty-claude-harness-template/.github/workflows/check-rules.yml:44)
- 시나리오: ⑦-3에 적힌 파일만 갱신하면 CI 주석과 단계 이름은 계속 “회수 표명 게이트(ADR-0013)”라고 안내한다. 실제 테스트는 ADR-0015의 머리 표명 2종을 검사하므로 운영자가 CI 표시만 보고 둘째 줄 계약을 알 수 없다.
- 기능 실행 자체는 유지되지만 “기존 계약 자리 전수 갱신” 주장은 성립하지 않는다.

CRITICAL은 발견하지 못했다. 파일 변경과 테스트·변이 실행은 하지 않았다.
