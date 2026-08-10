# 사용법 — 하네스 템플릿

## 0. 전제 (전역 1회 설치, 템플릿은 참조만)

| 의존 | 위치 | 없으면 |
|---|---|---|
| ECC 룰 | `~/.claude/rules/ecc/` | 코딩/테스트 표준 미적용 (하네스는 동작) |
| **ECC 에이전트** (planner·architect·code-reviewer·security-reviewer·pr-test-analyzer) | ECC 플러그인(`ecc:` 접두) 또는 `~/.claude/agents/` 전역 설치본 | 설계·계획·검수·보안검수 4역할 dispatch 실패 → 오케스트레이터가 직접 대체 수행하며 "ECC 미설치" 명시 |
| superpowers 플러그인 | 플러그인 매니저 | 에이전트의 방법론 스킬 호출 실패 → 해당 단계 품질 저하 |
| claude-mem 플러그인 | 플러그인 매니저 | 착수 전 과거 기억 검색(recall) 생략됨 |
| find-skills 스킬 | `~/.claude/skills/find-skills` (`npx skills add vercel-labs/skills --skill find-skills`) | 진화 시 "만들기 전에 생태계 검색" 생략 → 바로 자체 제작으로 감 |
| codex CLI (선택) | `npm i -g @openai/codex` + `codex login`(사용자 직접) + `claude mcp add --scope user codex -- codex mcp-server` | 모든 검증 게이트(계획검증·검수·PR점검)의 듀얼 리뷰(cc/cx) 생략 — Claude 단독으로 진행하되 보고에 "듀얼 리뷰 생략" 명시 |
| `gh` CLI | PATH | PR 단계(Phase 4) 불가 |

## 1. 설치 (프로젝트당 1회)

```bash
cd ~/.claude/harness-template
./install.sh /path/to/project [프로젝트이름]
```

install이 하는 일: 글루 복사(자체 에이전트 8·스킬 2(harness-orchestrator·readable-writing)·훅 4·제0원칙) + 슬롯 스캐폴드(없을 때만) + settings.json 병합(기존 훅 보존·명령 단위 추가·백업) + CLAUDE.md 포인터 append.

설계·계획·검수·보안검수 4역할은 자체 에이전트가 아니라 **ECC 참조**(`ecc:architect`·`ecc:planner`·`ecc:code-reviewer`·`ecc:security-reviewer`)다 — 하네스 계약(판정 형식·태그·프로필 준수)은 오케스트레이터의 dispatch 계약이 프롬프트로 주입한다. 이 중 2종은 **조건부**로만 돈다: `ecc:architect`(구조적 변경 — 새 모듈/레이어·경계/데이터모델 변경·3개+ 모듈 영향 — 일 때 Phase 2 전단, plan-reviewer가 설계·계획 2-pass 검증), `ecc:security-reviewer`(보안 민감 변경 — 인증/입력/DB/파일시스템/외부API/암호화/결제/시크릿 — 일 때 Phase 3에서 검수와 병렬, CRITICAL=병합 차단). 추가로 테스트가 핵심 방어선인 변경에는 ECC의 `pr-test-analyzer`를 참조 dispatch(`[tq]` 태그) — 템플릿 소유 에이전트가 아니라 전역 ECC 재사용.

**설치 후 반드시 2개 슬롯 채우기:**
1. `.claude/harness/project-profile.md` — §1~§8 (도메인 전부: 스택·검증 명령·불변식·경계면·운영·vcs·예시). 작성 예시는 이 repo의 `examples/chat-system.profile.md`.
2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략) · `HARNESS_KNOWLEDGE_GATE` (지식 저장소 반영 게이트. **기본 켜짐**이고, 끄는 방법은 **값을 비우는 것 하나뿐**이다 — `"off"`라고 적으면 비어 있지 않으므로 켜진 것으로 읽힌다).

**`harness.env` 는 실행되지 않는다.** 확장자와 문법은 셸이지만 훅은 이 파일을 source 하지 않고 줄을 읽어 값만 뽑는다 — 1비트를 얻으려고 사용자 소유 셸 파일에 훅의 제어 흐름을 넘길 이유가 없기 때문이다(`exit 0` 한 줄로 완료 게이트 4종이 흔적 없이 사라진 실측이 있다). 대신 지원 문법이 좁다: **한 키는 정확히 한 번만**, 선언은 줄 **맨 앞**에서 시작, 값에 공백이 있으면 따옴표, 후행 주석은 따옴표 뒤에만. 어기면 그 키는 **미설정**으로 떨어지고 해당 검사가 생략된다(생략 사유는 완료 게이트 메시지에 적힌다). 전체 규칙은 `harness.env` 파일 첫머리에 있다.

**주의: 훅은 세션 시작 시 스냅샷된다** → 설치한 세션에는 발화하지 않고 **다음 세션부터** 적용.

## 2. 무엇이 재사용이고 무엇이 슬롯인가

| 층 | 파일 | 갱신 주체 |
|---|---|---|
| **글루 (재사용)** | `agents/*.md` · `skills/*/`(harness-orchestrator·readable-writing) · `hooks/*.sh` · `harness/principles.md` | `sync.sh` (템플릿 개선 시) |
| **슬롯 (프로젝트 소유)** | `harness/project-profile.md` · `harness/harness.env` | 사용자 — sync가 절대 안 덮음 |
| **참조 (전역)** | ECC 룰 · superpowers 스킬 · claude-mem | 각 시스템 업데이트 시 자동 최신 |

## 3. 일상 사용

- **개발 요청** ("~만들어줘/고쳐줘/추가해줘") → `harness-orchestrator` 스킬이 자동 트리거되어 파이프라인 실행: 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사. 머지는 항상 사용자 승인 후.
- **부분 재실행** — "검수만 다시", "PR만 다시" → 해당 단계만 돈다.
- **설계 질문** ("왜 이렇게 짰어") → `architecture-guide` 에이전트 직접 호출 (파이프라인 밖).
- **변경 질문** ("이번에 뭐 바뀌었어") → `change-explainer` 직접 호출.

## 4. 템플릿 갱신 (sync)

```bash
cd ~/.claude/harness-template
./sync.sh /path/to/project            # git pull + diff 미리보기 + 글루만 갱신
./sync.sh /path/to/project --no-pull  # 로컬 정본만으로
```

이미 설치된 프로젝트는 sync 전까지 설치 시점 스냅샷 유지(조용한 기본값). 새 설치는 항상 그 시점 최신 글루.

## 5. 강제 훅 게이트 (이 하네스의 무기)

| 훅 | 시점 | 강제 내용 |
|---|---|---|
| guard-master-commit | Bash 실행 전 | master/main 직접 `git commit` 차단 |
| guard-hook-disable | Bash 실행 전 | 에이전트가 `HARNESS_HOOKS`·`ECC_DISABLED_HOOKS`·`ECC_GATEGUARD` 를 끄려 할 때 한 번 세운다. **과속방지턱이지 방벽이 아니다** — 아래 참조. 탈출구가 **없다** |
| guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-knowledge`·`.needs-dualreview` (코드는 4종 전부 · 설계·계획 산출물은 듀얼리뷰+지식 · 결정 문서는 지식만). 검사 범위는 아래 "완료 게이트 검사 범위" 참조 |
| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → codex 듀얼리뷰 → change-explainer → **지식 저장소 반영** → **push 미완** → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |

**지식 저장소 게이트가 아는 것은 계약 하나뿐이다** — "지식 저장소가 설정돼 있으면, 결정·설계가 나온 턴은 반영 없이 끝낼 수 없다." **어디에 어떤 구조로 반영하는지는 하네스가 모른다.** 그건 사용자 층 설정(전역 `CLAUDE.md` 등)이 답하고, 하네스에는 켜짐/꺼짐 1비트만 있다. 그래서 지식 저장소를 바꿔도 하네스는 고치지 않고, 아예 안 쓰는 프로젝트에서도 그대로 돈다.

**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:knowledge`(지식 게이트만) / `stop:push`(push 게이트만) 나열.
**`guard-hook-disable` 은 과속방지턱이지 보안 경계가 아니다.** 판정이 정규식 하나라 셸을 해석하지 못한다 — `read`+`export`, 따옴표로 쪼갠 `env 'X''=off'`, 변수 조립, `eval`, 생성한 스크립트 실행은 전부 통과한다(실측). 그럼에도 값을 하는 이유는 막으려는 것이 적대적 공격자가 아니라 **막힌 에이전트의 직진 충동**이고, 그건 `HARNESS_HOOKS=off ...` 라는 직진형으로 나오기 때문이다. 제대로 막으려면 셸 파서가 필요한데, 반쯤 만든 셸 파서는 안 만든 것보다 나쁘다(막힌다고 믿게 하면서 안 막는다 — 이 저장소가 `harness.env` 판독기에서 겪은 늪).

**그래서 위양성 쪽으로 기운다.** 실행 구문과 인용문을 구분하지 않아 `git grep 'HARNESS_HOOKS=off'` 같은 정당한 검색도 막힌다. 의도된 선택이다 — 따옴표 안을 건너뛰면 위양성은 사라지지만 `bash -c 'HARNESS_HOOKS=off ...'` 가 뚫린다. 둘은 문자열로 구별되지 않는 같은 모호성의 양면이고, 위양성은 메시지 한 번이 비용이지만 위음성은 **게이트가 꺼진 걸 아무도 모르는** 것이 비용이다. 차단 메시지가 위양성일 때의 대안(패턴 쪼개기·Write 도구 사용)을 함께 안내한다.

**그리고 환경변수로 끌 수 없다.** 그 탈출구가 있으면 에이전트가 그것으로 이 훅을 끄고 나머지를 전부 끌 수 있어 존재 이유가 사라진다. 사용자가 정말 끄려면 셸에서 직접 `export` 하고 세션을 새로 띄우거나 `settings.json` 배선을 지운다 — 둘 다 사람이 하는 행위다.

**push 게이트가 있는 이유:** 이 저장소는 커밋 29개를 잃은 적이 있다. 코드는 다 짜여 있었고 "아직 PR 전이니까"라며 push 를 미뤘다. 게이트는 **네트워크를 쓰지 않는다** — 로컬 remote-tracking ref 만 본다. 원격에 있는데도 ref 가 안 보이면(`remote.origin.fetch` 가 좁혀진 경우) 그 사실을 사유에 적는다. push 여부가 로컬에서 안 보이는 것 자체가 위험이기 때문이다. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.

### 완료 게이트 검사 범위 (mark-needs-audit)

판정 **순서가 곧 계약**이다: 개행 가드 → 물리 경로 정규화 → 듀얼리뷰 판정 → 범위 판정 → 분류 → 기록.

- **프로젝트 안** — `_workspace/`·`.claude/`·문서 `*.md`·`*.markdown`(대소문자 무관)는 제외. 나머지는 게이트 4종.
  단 **문서 제외에는 예외가 둘** 있다(동작을 정의하는 마크다운이라 코드로 취급한다):
  `.claude/` 에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`), 그리고
  **프로젝트 자신이 하네스 정본일 때의 `global-agents/*.md`**. 둘 다 `*.md` 제외보다 **먼저** 판정된다.
- **프로젝트 밖 + 하네스 정본 저장소**(루트에 `template/.claude/` 존재) — 저장소 **전체**를 **프로젝트와 같은 규칙으로** 검사한다. `scripts/`·`install.sh`·`global-agents/*.md` 포함(전부 하네스 동작을 정의한다). "같은 규칙"이므로 위의 제외도 **그대로** 적용된다 — 정본 저장소 안이라도 `_workspace/`·`.claude/`·순수 문서는 게이트가 서지 않는다. 지금 읽고 있는 이 파일(`docs/usage.md`)이 그 예다.
- **프로젝트 밖 + 그 외** — `.claude/`에 앵커된 하네스 경로(`agents/`·`skills/`·`hooks/`·`harness/`·`settings.json`)만. **git 저장소가 아니어도** 발화한다.
- **설계·계획 산출물**(`_workspace/00_design*.md`·`01_plan*.md`) — 위치·git 여부와 무관하게 **듀얼리뷰 + 지식** 플래그를 세운다. 설계가 나온 턴을 반영 없이 끝내면 "왜 그렇게 정했나"가 그 자리에서 사라지고, 그 근거가 정확히 이 파일들이다.
- **결정 문서**(`docs/decisions/*.md`) — 문서 제외의 **예외**로 **지식** 플래그만 세운다. 코드가 아니므로 타입체크·변경설명·감사는 과하다. **공시된 한계:** 결정 문서를 이 경로 밖에 두면 게이트가 서지 않는다 — 하네스는 자기가 아는 경로만 알 수 있다.
- **밖 편집은 절대경로로 기록**한다. 상대경로로 적으면 프로젝트와 외부 저장소가 `README.md` 같은 흔한 경로를 공유할 때 감사자가 프로젝트 쪽 동명 파일을 보고 통과시킨다.
- 플래그를 못 쓰거나 경로에 개행이 있으면 **차단하지 않고** `systemMessage`로 알린다(PostToolUse는 항상 exit 0). git 호출이 실패했는데 조상에 `.git`이 있으면 그 사실도 알린다 — 정본 저장소가 조용히 앵커 전용으로 강등되는 것을 사람이 알 수 있게.

계약의 **기계 정본**은 `tests/mark-needs-audit.cases.sh`의 판정 표이고, 케이스 수는 같은 파일의 `EXPECTED_CASES`가 강제한다. CI가 PR마다 돌린다.

## 6. 트러블슈팅

- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 지식 저장소 반영(`.needs-knowledge`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
- **타입체크가 이상하게 실패** → `harness.env`의 명령을 셸에서 직접 실행해 확인. 도구 부재(rc=127)·타임아웃은 차단 안 하고 생략 처리된다.
- **superpowers 스킬 호출 실패** → 플러그인 설치/이름 확인: `test-driven-development`·`writing-plans`·`brainstorming`·`requesting-code-review`·`verification-before-completion`·`systematic-debugging`.
- **에이전트가 도메인을 무시** → 프로필 §가 비어 있지 않은지 확인. 오케스트레이터는 빈 §를 "검증 생략"으로 정직 보고한다.

## 7. 하네스 진화

에이전트/스킬 수정·추가는 이 repo(정본)에서 하고 커밋 → 각 프로젝트에 `sync.sh`. 구조 변경이 크면 `harness` 메타 스킬(운영/유지보수 워크플로우)을 사용. 변경 이력은 각 프로젝트 CLAUDE.md의 변경 이력 표에 기록.

### 제0원칙 판정 기준을 고칠 때

판정 기준(`principles.md`의 `rule:core` 블록)은 판정자 에이전트가 **자기 정의 안에 사본으로** 들고 있다. 참조만 두면 에이전트가 그 파일을 읽는다는 보장이 없어서다. 그래서 고치는 순서가 정해져 있다.

1. 정본 `template/.claude/harness/principles.md`의 `rule:core` 블록을 고친다.
2. 사본(`template/.claude/agents/plan-reviewer.md` 점검 항목 7)에 **그대로 복사**한다.
3. 검사한다.

```bash
./scripts/check-rule-copies.sh
```

어긋나면 종료 코드 1과 함께 diff가 나오고, CI(`.github/workflows/check-rules.yml`)가 PR을 막는다. 마커 **밖**의 문맥별 설명은 동기화 대상이 아니니 파일마다 자유롭게 써도 된다 — 판정 기준만 동기화한다. 다만 마커 줄 자체는 앞뒤 공백·설명 없이 정확히 한 줄(`<!-- rule:core:start -->` / `<!-- rule:core:end -->`, CRLF 줄끝 불가)이어야 한다. 꾸미면 마커로 인정되지 않는다 — 마커를 꾸며 판정 기준을 바꿔치기하는 길을 막기 위해서다. 같은 이유로 `template/` 아래에는 심링크와 NUL 바이트를 포함한 파일(바이너리·UTF-16 등)을 둘 수 없다 — 검사기가 내용을 확인할 수 없어 낡은 사본이 조용히 배포되는 경로가 열리기 때문이다.

판정자를 새로 추가해 사본이 늘면 `scripts/check-rule-copies.sh`의 `COPIES` 배열에 경로 한 줄을 추가해야 한다 — `template/` 안에 마커를 둔 채 등록하지 않으면 검사기가 종료 코드 1로 막는다. 그 경로는 반드시 `template/` **아래**여야 한다: 심링크·NUL·미등록 게이트가 전부 `template/`만 훑기 때문에, 밖을 가리키면 등록만 되고 정작 검사는 안 되는 사본이 생긴다(검사기가 이것도 종료 코드 1로 막는다). `..`나 심링크를 거쳐 밖으로 나가는 표기도 물리 경로로 풀어 같이 막는다. 경로에 개행이 들어간 파일은 아예 등록할 수 없다 — 개행은 경로 계산 과정에서 잘려 나가 바깥 파일을 안쪽으로 오인시키므로, 범위 판정 자체가 성립하지 않는다. 반대로 `COPIES`를 통째로 비워 둘 수도 없다 — 대조할 사본이 0개면 검사기가 지키는 것이 아무것도 없는데도 초록으로 보이므로, 빈 배열도 종료 코드 1로 막는다.
