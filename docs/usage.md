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
2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략).

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
| guard-codex-invocation | Bash 실행 전 | `codex exec` 호출의 모델(`gpt-5.6-sol`)·effort(`high`) 미달 차단 — 임의 하향 금지 (2026-08-01 사용자 지시) |
| mark-needs-audit | 파일 편집 후 | 게이트 플래그 4종: `.needs-audit`·`.needs-explain`·`.needs-vault`·`.needs-dualreview` (설계·계획 산출물은 듀얼리뷰 플래그만, 코드는 4종 전부. 제외: `_workspace/` 기타·`.claude/`·`*.md`) |
| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → codex 듀얼리뷰 → change-explainer → 볼트(second brain) 반영 → completion-auditor 순서로 미이행 시 종료 차단 (rc=2. 같은 지점에서 진전 없이 3회면 경고와 함께 통과 — 게이트를 하나 지울 때마다 카운터 리셋) |

**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:dualreview`(듀얼리뷰 게이트만) / `stop:explain`(설명 게이트만) / `stop:vault`(볼트 게이트만) 나열. 예외: guard-codex-invocation은 환경변수 탈출구가 없다 — 변경은 사용자 승인 + 훅·SKILL.md 동시 갱신으로만.

## 6. 트러블슈팅

- **Stop 훅이 계속 차단** → 차단 메시지의 게이트 순서대로 처리하라: codex 듀얼리뷰(`.needs-dualreview`) → change-explainer(`.needs-explain`) → 볼트 반영(`.needs-vault`) → completion-auditor(`.needs-audit`). 각 작업을 실제로 마친 뒤에만 해당 플래그를 지운다. 게이트를 하나 지울 때마다 차단 예산이 리셋되므로 순서대로 처리하면 소진되지 않는다. 급하면 탈출구 환경변수. 같은 지점에서 진전 없이 3회면 자동 통과(그 턴의 완료 주장은 신뢰 금지).
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
