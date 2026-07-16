# Harness Template — 도메인-무관 개발 파이프라인 하네스

프로젝트마다 재사용하는 **접착제 층(glue)**. 질문정리→계획→계획검증→개발→검수→PR→PR점검→변경설명→완료감사
파이프라인을 전문 에이전트 팀 + 강제 훅으로 실행한다. 도메인 알맹이는 프로젝트마다 **슬롯 한 파일**만 채운다.

> 상태: **Stage 5.5 완료** — 글루 전체(에이전트 12 · 오케스트레이터 · 훅 4 · 제0원칙) + install/sync + 문서. 남은 것: Stage 6 실전 인스턴스화 검증.
> 정본 repo: https://github.com/xodbs1021/kty-claude-harness-template (private) · 상세 사용법: [docs/usage.md](docs/usage.md)

## 설계 원칙 (확정)

1. **레이어 분리, 짬뽕 금지.** ECC·superpowers·claude-mem은 전역 1회 설치로 두고 템플릿은 **참조만** 한다(복사 X). 버전 드리프트·중복·비대 방지.
2. **템플릿 = 재사용 90% 접착제.** 도메인 알맹이는 프로젝트마다 채우는 **슬롯**.
3. **강제력(훅)은 템플릿이 소유한다** — superpowers엔 없는 이 하네스의 무기.

## 무엇이 재사용이고 무엇이 슬롯인가

| 구분 | 무엇 | 어디 |
|------|------|------|
| **재사용 (글루, 복사됨)** | 메타 에이전트 11개(clarifier·design-architect·planner·plan-reviewer·reviewer·security-reviewer·pr-author·pr-reviewer·change-explainer·completion-auditor·architecture-guide) + developer | `template/.claude/agents/` |
| | 강제 훅 4개(guard-master-commit·mark-needs-audit·verify-before-stop·_common) + `settings.json` 배선 | `template/.claude/hooks/` |
| | 오케스트레이터 스킬(제네릭 파이프라인) | `template/.claude/skills/` |
| **슬롯 (프로젝트마다 채움)** | 도메인 프로필 — 스택·검증 명령·아키텍처 불변식·경계면·운영 모델·예시 | `template/.claude/harness/project-profile.template.md` → 프로젝트의 `.claude/harness/project-profile.md` |
| | developer 에이전트의 도메인 구현 지식 | 프로필 §2·§4 참조로 해결(에이전트 본문은 제네릭) |
| **참조 (복사 안 함, 전역)** | ECC 룰 / superpowers 스킬 / claude-mem | `~/.claude/rules/ecc/` · superpowers·claude-mem 플러그인 |

## 전역 의존 (없으면 하네스가 반쪽)

- **ECC** (`~/.claude/rules/ecc/`): 언어 일반 코딩/테스트/보안 표준. 항상 로드.
- **superpowers** (플러그인): 방법론 스킬. 에이전트가 런타임에 **참조 호출**(복사 X). 전역 `using-superpowers` 자동 선점은 이 하네스에서 CLAUDE.md 지시로 비활성 — 오케스트레이터가 스킬 순서를 통제.
- **claude-mem** (플러그인): 세션 히스토리 **자동 캡처+검색**(디폴트 동작). planner/clarifier가 착수 전 "전에 이거 풀었나" 검색.

### 하이브리드 메모리 경계

- **파일 메모리(항상 로드, 하중지지 사실):** 핵심 규칙·확정 결정·로드맵·아키텍처 불변식·프로필. `~/.claude/projects/<proj>/memory/`.
- **claude-mem(긴 꼬리, 검색):** 세션 서사·탐색 히스토리. 자동 캡처되므로 별도 작업 불필요.
- **승격 규칙:** claude-mem 검색에서 하중지지 사실이 나오면 파일 메모리로 승격.

## 인스턴스화 흐름 (새 프로젝트)

```
1. install.sh <project>          # (Stage 5) 글루를 프로젝트 .claude/로 복사
2. .claude/harness/project-profile.md 채우기   # 슬롯 — 도메인만
3. CLAUDE.md 하네스 포인터 자동 추가             # (Stage 5) install.sh가 append
→ 이후 개발 요청 시 오케스트레이터 스킬이 트리거되어 파이프라인 실행
```

- **글루 반영:** install 시 **복사(스냅샷)**. 템플릿 개선은 `sync` 명령으로 선택 반영(조용한 기본값=안 바뀜).
- **참조 시스템:** 항상 전역 최신을 런타임에 사용 — 새 프로젝트를 깔 때마다 (그 시점 최신 글루) + (최신 ECC·superpowers·claude-mem)로 조립됨.

## 디렉토리 구조

```
~/.claude/harness-template/
├── README.md                                  # 이 문서
├── install.sh                                 # 인스턴스화 (글루 복사 + 슬롯 스캐폴드 + 병합)
├── sync.sh                                    # 글루만 갱신 (pull + diff 미리보기, 슬롯 불변)
├── template/
│   ├── CLAUDE.md.snippet                       # 프로젝트 CLAUDE.md에 append되는 포인터
│   └── .claude/
│       ├── agents/                             # 제네릭 에이전트 12 (도메인 누출 0)
│       ├── skills/harness-orchestrator/        # 파이프라인 오케스트레이터 (프로필 런타임 주입)
│       ├── hooks/                              # 강제 훅 4 (+ settings.json 배선)
│       ├── settings.json
│       └── harness/
│           ├── project-profile.template.md     # 슬롯 스키마 (9섹션)
│           ├── harness.env.template            # 타입체크 명령 슬롯
│           └── principles.md                   # 제0원칙 (글루)
├── examples/
│   └── chat-system.profile.md                  # 채팅 프로젝트 실증본(스키마 검증)
└── docs/
    └── usage.md                                # 설치→슬롯→일상 사용→sync→트러블슈팅
```

## 원본

이 템플릿은 CHZZK/SOOP 채팅 하네스(`/Users/kty/Downloads/chat/.claude/`)를 도메인-무관으로 일반화한 것이다.
채팅 도메인 알맹이는 `examples/chat-system.profile.md`에 슬롯 형태로 추출되어 있다.
