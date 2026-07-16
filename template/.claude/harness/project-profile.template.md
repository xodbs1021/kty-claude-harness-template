# 프로젝트 프로필 — {{PROJECT_NAME}}

> **이 파일은 하네스의 유일한 도메인 슬롯이다.**
> 제네릭 에이전트·오케스트레이터는 도메인 지식을 자기 안에 담지 않는다. 대신 런타임에
> 이 파일을 읽어 "이 프로젝트가 무엇이고, 무엇을 지켜야 하며, 어떻게 검증하는가"를 배운다.
> 새 프로젝트 온보딩 = **이 파일만 채우기.** 에이전트 정의는 손대지 않는다.
>
> 작성 규칙:
> - 각 섹션 머리의 `[읽는 이]`는 이 섹션을 참조하는 에이전트다. 비우면 그 에이전트는 "해당 없음"으로 처리한다.
> - 모르는 항목은 지우지 말고 `(해당 없음)` 또는 `(미정)`으로 둔다 — 빈칸과 "없음"은 다르다.
> - 사실만 적는다. 코드에서 확인되지 않는 희망사항을 불변식에 넣지 않는다.
> - 이 파일은 **하중지지 사실**(항상 로드)이다. 세션 서사·탐색 히스토리는 여기가 아니라 claude-mem으로 간다.

---

## 1. 정체성 (identity)
`[읽는 이: 전 에이전트 · 오케스트레이터 제목 · developer/orchestrator description]`

- **한 줄 정의:** {{한 문장으로 이 시스템이 무엇인지}}
- **도메인:** {{예: 실시간 채팅 수집·분석 / 이커머스 / 사내 대시보드}}
- **주 사용자 & 기술 숙련도:** {{예: 본인(코딩 경험 적음) — 전문용어 풀어 설명 / 개발팀}}
- **1차 언어(사용자 대면 보고):** {{예: 한국어 — change-explainer·clarifier가 이 언어로 보고}}

---

## 2. 기술 스택 (stack)
`[읽는 이: developer · planner · reviewer · plan-reviewer]`

- **언어:** {{예: TypeScript}}
- **프레임워크/런타임:** {{예: Fastify · socket.io · React 19 · Vite · Node}}
- **패키지 매니저:** {{예: pnpm}}
- **핵심 디렉토리 맵** — 어디에 무엇이 있나(계획·검수 시 영향 범위 판단 기준):
  - {{예: `src/server/` — 수집·집계 서버}}
  - {{예: `src/client/` — React 대시보드}}
  - {{예: `src/shared/` — 서버·클라 공유 타입}}
  - {{예: `tests/` — Vitest}}

---

## 3. 검증 명령 (verify)
`[읽는 이: developer · reviewer · completion-auditor · pr-author · verify-before-stop 훅]`

> **`typecheck` 명령은 Stop 훅(`verify-before-stop.sh`)이 그대로 실행한다.** 형식: 셸에서 바로 도는 한 줄.
> 없거나 해당 없으면 `(없음)`으로 두면 훅이 타입체크를 건너뛴다.

- **타입체크:** {{예: `pnpm typecheck`  또는  `pnpm tsc --noEmit`}}
- **테스트:** {{예: `pnpm test`  (프레임워크: Vitest)}}
- **빌드:** {{예: `pnpm build`}}
- **린트/포맷(선택):** {{예: `pnpm lint` / `pnpm format`}}
- **브라우저·런타임 관찰 필요?** {{예: 예 — 대시보드 변경은 preview 도구로 실제 렌더 확인까지}}

---

## 4. 아키텍처 불변식 (invariants)
`[읽는 이: planner · plan-reviewer · developer · reviewer · architecture-guide]`

> 이 프로젝트에서 **어기면 버그**인 규칙들. 형식: `규칙 — 왜(안 지키면 뭐가 터지나)`.
> 여기 적힌 것이 reviewer의 "실패 시나리오" 사고와 architecture-guide 설명의 근거가 된다.
> 프로젝트 고유 규칙만. 언어 일반 관용구(불변성·작은 함수 등)는 ECC 룰이 이미 커버하므로 중복 금지.

- {{규칙}} — {{왜}}
- {{규칙}} — {{왜}}
- _(예시) 실시간 경로 vs 내구성 경로 분리 — 인메모리는 동기 즉시 갱신, 디스크 쓰기는 백그라운드 큐. 실시간 경로에 `await 파일쓰기`를 넣으면 폭주 시 화면이 멈춘다._
- _(예시) 증분 집계 — 매 주기 전체 재계산 금지. 데이터가 쌓일수록 느려지는 시한폭탄._

---

## 5. 경계면 맵 (boundaries)
`[읽는 이: planner · plan-reviewer · reviewer]`

> 데이터 shape이 계층을 넘나드는 지점. 이 프로젝트 버그의 대부분이 여기서 난다.
> reviewer의 핵심은 "존재 확인"이 아니라 **이 경계 양쪽을 동시에 열어 shape을 교차 비교**하는 것.
> 형식: `경계: A ↔ B — 공유 계약/타입 위치`.

- {{경계: A ↔ B}} — 공유 계약: {{위치}}
- _(예시) 서버 API 응답 ↔ socket.io payload ↔ React 훅 — 공유 타입: `src/shared/types.ts`_

---

## 6. 배포·운영 모델 (ops)
`[읽는 이: completion-auditor · change-explainer]`

> **"머지 = 사용자 화면 반영"이 아닐 수 있는 지점.** completion-auditor가 "운영 반영까지" 감사하려면 필요.
> 이 섹션이 비면 감사자는 코드 완료(머지·테스트)까지만 검증하고 운영 반영은 확인하지 않는다.

- **운영 서버 실행:** {{예: `node dist-server/index.js`, 포트 4010}}
- **서빙 대상(무엇을 서빙하나):** {{예: `dist/`·`dist-server/` 빌드본 — 소스가 아니라 빌드 산출물}}
- **소스→운영 반영 절차:** {{예: `pnpm build` + 서버 재시작}}
- **"반영됨" 확인법:** {{예: `ls -lt dist/assets/` 빌드 시각이 머지 시각보다 최신인지}}

---

## 7. 버전관리 정책 (vcs)
`[읽는 이: pr-author · pr-reviewer]`

> 아래는 하네스 **기본값**. 프로젝트가 다르면 해당 줄만 덮어쓴다.

- **기본 브랜치:** {{master | main}}
- **브랜치 전략:** 기능마다 기본 브랜치에서 새 브랜치 → PR → **squash merge**. 스택 PR 금지(앞 PR 머지 시 base 삭제로 뒤 PR이 닫히는 사고).
- **한 PR = 한 논리적 변경** — squash 후 커밋 하나 `revert`로 롤백.
- **커밋/PR 제목:** Conventional Commits (`feat:`·`fix:`·`refactor:`·`docs:`·`test:`·`chore:`·`perf:`).
- **머지 주체:** 사용자 승인 후에만.
- **프로젝트 예외:** {{없으면 "없음"}}

---

## 8. 도메인 예시 (examples)
`[읽는 이: clarifier · 오케스트레이터 테스트 시나리오]`

> clarifier가 "무엇이 모호한지" 감을 잡게 하는 **실제 요청 예시** 1~2개.
> 이상적으로: 표면상 명확해 보이지만 실은 결정이 숨어 있는 요청.

- _(예시) "이미지도 되게 해줘" → 어느 provider? 호버/클릭 둘 다? 저장까지? — 범위가 숨어 있음._
- {{이 프로젝트의 대표적 "애매한 요청" 예시}}

---

## 9. 참고 — 전역 의존 (이 프로젝트가 기대는 참조 시스템)
`[정보용: 사람이 읽는 메모. 에이전트는 각자 필요한 참조를 직접 호출]`

- **ECC 룰:** `~/.claude/rules/ecc/` — 언어 일반 코딩/테스트/보안 표준(항상 로드).
- **superpowers 스킬(참조, 복사 아님):** developer→`test-driven-development`, completion-auditor→`verification-before-completion`, clarifier→`brainstorming`, planner→`writing-plans`, reviewer→`requesting-code-review`/`receiving-code-review`, 디버깅→`systematic-debugging`.
- **claude-mem:** 세션 히스토리 자동 캡처 + 검색. planner/clarifier가 착수 전 "전에 이거 풀었나" 검색.
- **파일 메모리:** 하중지지 사실(핵심 규칙·확정 결정·로드맵)은 `~/.claude/projects/<proj>/memory/`(항상 로드). 이 프로필도 하중지지 사실이다.
