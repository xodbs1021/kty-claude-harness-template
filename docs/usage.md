# 사용법 — 하네스 템플릿

## 0. 전제 (전역 1회 설치, 템플릿은 참조만)

| 의존 | 위치 | 없으면 |
|---|---|---|
| ECC 룰 | `~/.claude/rules/ecc/` | 코딩/테스트 표준 미적용 (하네스는 동작) |
| superpowers 플러그인 | 플러그인 매니저 | 에이전트의 방법론 스킬 호출 실패 → 해당 단계 품질 저하 |
| claude-mem 플러그인 | 플러그인 매니저 | 착수 전 과거 기억 검색(recall) 생략됨 |
| find-skills 스킬 | `~/.claude/skills/find-skills` (`npx skills add vercel-labs/skills --skill find-skills`) | 진화 시 "만들기 전에 생태계 검색" 생략 → 바로 자체 제작으로 감 |
| `gh` CLI | PATH | PR 단계(Phase 4) 불가 |

## 1. 설치 (프로젝트당 1회)

```bash
cd ~/.claude/harness-template
./install.sh /path/to/project [프로젝트이름]
```

install이 하는 일: 글루 복사(에이전트 12·오케스트레이터·훅 4·제0원칙) + 슬롯 스캐폴드(없을 때만) + settings.json 병합(기존 훅 보존·백업) + CLAUDE.md 포인터 append.

파이프라인 확장 에이전트 2종은 **조건부**로만 돈다: `design-architect`(구조적 변경 — 새 모듈/레이어·경계/데이터모델 변경·3개+ 모듈 영향 — 일 때 Phase 2 전단, plan-reviewer가 설계·계획 2-pass 검증), `security-reviewer`(보안 민감 변경 — 인증/입력/DB/파일시스템/외부API/암호화/결제/시크릿 — 일 때 Phase 3에서 reviewer와 병렬, CRITICAL=병합 차단).

**설치 후 반드시 2개 슬롯 채우기:**
1. `.claude/harness/project-profile.md` — §1~§8 (도메인 전부: 스택·검증 명령·불변식·경계면·운영·vcs·예시). 작성 예시는 이 repo의 `examples/chat-system.profile.md`.
2. `.claude/harness/harness.env` — `HARNESS_TYPECHECK_CMD` (Stop 훅이 실행할 타입체크 한 줄. 비우면 타입체크 생략).

**주의: 훅은 세션 시작 시 스냅샷된다** → 설치한 세션에는 발화하지 않고 **다음 세션부터** 적용.

## 2. 무엇이 재사용이고 무엇이 슬롯인가

| 층 | 파일 | 갱신 주체 |
|---|---|---|
| **글루 (재사용)** | `agents/*.md` · `skills/harness-orchestrator/` · `hooks/*.sh` · `harness/principles.md` | `sync.sh` (템플릿 개선 시) |
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
| mark-needs-audit | 파일 편집 후 | `.needs-audit`·`.needs-explain` 플래그 (제외: `_workspace/`·`.claude/`·`*.md`) |
| verify-before-stop | 턴 종료 시 | 타입체크(`harness.env`) → change-explainer → completion-auditor 순서로 미이행 시 종료 차단 (rc=2, 최대 3회 후 경고와 함께 통과) |

**탈출구:** `HARNESS_HOOKS=off` (전체) 또는 `ECC_DISABLED_HOOKS`에 `pre:bash:master-guard` / `post:edit:needs-audit` / `stop:verify`(완료 게이트 전체) / `stop:explain`(설명 게이트만) 나열.

## 6. 트러블슈팅

- **Stop 훅이 계속 차단** → change-explainer/completion-auditor를 실제로 돌리고 각 플래그를 지워라. 급하면 탈출구 환경변수. 3회 후엔 자동 통과(그 턴의 완료 주장은 신뢰 금지).
- **타입체크가 이상하게 실패** → `harness.env`의 명령을 셸에서 직접 실행해 확인. 도구 부재(rc=127)·타임아웃은 차단 안 하고 생략 처리된다.
- **superpowers 스킬 호출 실패** → 플러그인 설치/이름 확인: `test-driven-development`·`writing-plans`·`brainstorming`·`requesting-code-review`·`verification-before-completion`·`systematic-debugging`.
- **에이전트가 도메인을 무시** → 프로필 §가 비어 있지 않은지 확인. 오케스트레이터는 빈 §를 "검증 생략"으로 정직 보고한다.

## 7. 하네스 진화

에이전트/스킬 수정·추가는 이 repo(정본)에서 하고 커밋 → 각 프로젝트에 `sync.sh`. 구조 변경이 크면 `harness` 메타 스킬(운영/유지보수 워크플로우)을 사용. 변경 이력은 각 프로젝트 CLAUDE.md의 변경 이력 표에 기록.
