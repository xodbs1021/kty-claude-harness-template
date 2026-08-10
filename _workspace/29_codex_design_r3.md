판정: 통과

| 항목 | 판정 | 근거 |
|---|---|---|
| [cc] H1 — rc 소비·r41/m26 | 닫힘 | Bash 3.2에서 무개행 마지막 줄의 `read`는 변수에 값을 넣고 rc=1을 반환한다. `if` 조건이 rc를 소비하고 `elif [ -n "$rline2" ]`가 정상 처리한다. m26으로 `elif`를 제거하면 해당 입력이 `else`의 누락 판정으로 들어가 r41이 적색이 된다. [`③-2`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:207), [`m26`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:404) |
| [cx] H — `실패()` 빈 사유 | 닫힘 | 세 변형이 공통 내용 검사 경로를 사용한다는 구현 계약과 `실패()`·`실패(   )` 차단 r46이 함께 있어 변형별 우회를 잡는다. [`③-1`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:170), [`r46`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:383) |
| [cx] H — 재시도 전이·비종결 | 닫힘 | 검수 보류가 architect/planner가 아닌 오케스트레이터 조사 단계로 전이되고, 조사 사이클 총 2회 상한과 소진 후 사용자 `결정 필요` 승격이 명시됐다. [`⑥-1 항목 5`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:291) |
| [cc] M1 — 판독 불가 메시지 | 닫힘 | 공통 메시지와 `TOK_RET_FLAGFAIL`, 상수 총 2건 갱신이 명시됐다. [`③-3`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:240) |
| [cc] M2 — m01·m05·m14 앵커 | 닫힘 | 구현 텍스트 보존 제약과 사후 앵커 전수 재검증이 모두 있다. [`③-A 4`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:122), [`⑦-2`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:414) |
| [cc] M3 / [cx] M — 계약 자리·CI | 닫힘 | README, ADR-0013, usage 및 CI 계약 자리가 전수표에 포함됐다. [`⑦-3`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:420) |
| [cc] M4 — 신규 케이스의 변이 대응 | 닫힘 | m30~m32가 추가됐고 r38만 기존 r21 관례에 따른 비변이 대상으로 명시됐다. [`⑦-2`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:409) |
| [cc] M5 — 사유·픽스처 명세 | 닫힘 | `mk_doc` 세 형태와 `GOOD_SECOND`, 불량 사유 7종이 구체화됐다. [`③-A`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:102), [`사유 상수`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:228) |
| [cc] M6 — 자체 선례 조사 | 닫힘 | 머리 표명이 `조사함`으로 바뀌고 선례 및 재수집 한계가 10절에 기록됐다. [`10절`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:479) |
| [cx] M — r04 격리 | 미흡 — 형식적 닫힘 | 격리 불가능성을 예외·측정 공백으로 공시했을 뿐, 원 지적이 요구한 분리 픽스처나 단독 변이는 추가하지 않았다. [`③-A`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:111), [`8절`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:460) |
| [cx] M — SP·로케일 | 미흡 — 부분 닫힘 | C 로케일과 SP 문법, r47·r48·m33은 생겼다. 다만 원 지적의 닫는 괄호 뒤 ASCII 공백 허용·비ASCII 공백 거부 경계는 별도 케이스로 고정되지 않아 일부가 형식 계약에만 남는다. [`③-1`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:161), [`r47~r48`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:385) |
| [cc] L1~L5 | 닫힘 | r02 오기, EMPTY 계약, 테스트·변이 헤더, mark-needs-audit 주석, 게이트 ID 유지 근거가 각각 실물 갱신표나 본문에 반영됐다. [`③-A`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:102), [`게이트 ID`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:85), [`⑦-3`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:434) |
| [cc] 미확인 파생 — research 에이전트 미설치 | 닫힘 | 오케스트레이터 대체 조사와 대체 불가 시 실패 경로가 정의됐다. 실제 환경별 설치·권한은 정적 검수 범위에서 미확인이다. [`⑥-1 항목 4b`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:288) |

신규 차단급: 없음.

신규 비차단 기록:

- LOW — 신규 케이스 설명이 아직 `r28~r45, 18건`으로 남아 있으나 실제 목록과 최종 상수는 r28~r48, 21건이다. [`⑦-1`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:359)
- LOW — 변이 설명이 `신규 11종`으로 남아 있으나 실제 열거와 총계는 m19~m33, 15종이다. [`⑦-2`](/Users/kty/Downloads/kty-claude-harness-template/_workspace/00_design-reference-gate.md:394)
