# 01_plan — 외부 발행 게이트 구현 계획 (ecc:planner 산출, 2026-08-14)

> 오케스트레이터 주석: kty 확정으로 **S7(02_research 패턴)은 철회 확정** — 계획에서 삭제된 것으로 읽는다(철회 사유는 S8의 ADR-0018에 기록). clarifier 문답 5건은 00_clarifier_qa.md.

사전 결정 회수: docs/decisions ADR-0005·0007·0008·0011·0015·0016·0017 + 설계 rev4·codex 구현조건·clarifier QA (planner가 전문 정독)
레퍼런스 조사: 불요(설계 단계 codex 듀얼 4라운드 완료 + 하네스 자기참조 내부 작업 — 승계)
- 걸리는 선행 결정: ADR-0005 — 단일 PR·squash 전제, 커밋 분할은 리뷰 가독성으로만 정당화
- 걸리는 선행 결정: ADR-0008 — harness.env 키 신설 금지, ECC_DISABLED_HOOKS 표준 경로만
- 걸리는 선행 결정: ADR-0011 — "자가 발급 사전 차단 불가"를 훅 주석·usage·ADR에 명문화
- 걸리는 선행 결정: ADR-0016 — json_get(빈 문자열 관용) 금지, 자체 엄격 파서로 fail-closed
- 걸리는 선행 결정: ADR-0017 — PreToolUse MCP 매처·rc=2 차단·stderr 안내 승계, 단 전역 배선은 안 함(프로젝트 층만 — 차이 공시)
- 걸리는 선행 결정: ADR-0015 ⑤·대안F — 02_research 명명 규정 기각 → **kty 확정: 이번 PR에서 철회(S7 삭제)**
- 걸리는 선행 결정: ADR-0007 — publish-approve.sh 배치는 harness_anchor 정체성 기준으로

## 목표
발행 성격 MCP 호출(Jira 생성·수정·전이·코멘트, Artifact 발행)을 PreToolUse에서 가로채 payload 결합 영수증(Tier1)과 고위험 kty 승인(Tier2) 없이 통과 금지. 위조 방지가 아니라 누락 방지(설계 0절). 소비 순간 감사 흔적 → completion-auditor 사후 검증.

## 영향 범위
신규: template/.claude/hooks/guard-publish-receipt.sh · template/.claude/scripts/publish-approve.sh(D1) · template/.claude/harness/publish-registry.txt · scripts/gen-publish-matcher.sh · tests/publish-envelope.test.sh · tests/publish-receipt-gate.{test,cases}.sh · tests/publish-matcher-drift.test.sh · _workspace/mutate-publish-gate.sh · docs/decisions/2026-08-14-external-publish-receipt-gate.md(ADR-0018)
수정: _common.sh(record_flag 이관 + envelope·digest·receipts 유틸 — json_get 사용 금지) · mark-needs-audit.sh(record_flag 로컬 정의 삭제:204-214, harness_anchor에 */.claude/scripts/* 추가:150-156) · settings.json(매처 1건:24-33 형식) · install.sh(scripts 복사+chmod:74-198, registry:197 인접) · sync.sh(:66-72) · check-rules.yml(스텝 4건:23-58) · SKILL.md(발행 리뷰 규약 신설 — 듀얼 리뷰 절 :59-75 뒤) · completion-auditor.md(표 :32-42 행 추가) · docs/usage.md(:61-67 행 + 잔존 위험 7종) · README(훅 개수 7→8 정정 :52·:173)
불변(명시): verify-before-stop.sh(기존 .needs-audit만 세우므로 무수정) · harness.env 스키마 · 전역 ~/.claude 배선

## 모듈 경계
envelope·digest = _common.sh 신규 3함수(publish_digest → rc≠0시 호출부 무조건 deny) / 영수증 상태기계 = 게이트 훅 단독(active→used, approval-active→approval-used 원자 claim) / 대상 판정 = publish-registry.txt 1곳(훅이 매처를 신뢰하지 않고 registry 재판정) / 승인 발급 = publish-approve.sh(사람 전용 — 훅은 소비만) / 사후 감사 = completion-auditor 규약(플래그는 트리거, used/·waived 전수 열거가 판정 — cx-11)

## 단계 (커밋 단위, 단일 PR)
S1 envelope·digest·record_flag 이관 — digest = python3 json.dumps(sort_keys, separators, ensure_ascii) 객체 해시 {"schema_version":1,"tool_name":…,"tool_input":…,"artifact_sha256":…} (cx-12: 객체 해시라 경계 프레이밍 원리적 해결. jq 신규 의존 안 만듦). 검증: tests/publish-envelope.test.sh e01~e08 + mark-needs-audit 75케이스 전건(이관 회귀 증거).
S2 registry+매처 생성기 — 형식 `<도구명>\t<min_tier>\t<waivable>`. transitionJiraIssue=2, addComment만 waivable. **착수 조건: 실세션 payload fixture 확보(도구 전체 이름·payload 모양 — 미확보 시 진행 중단·보고)**. gen-publish-matcher.sh --check + tests/publish-matcher-drift.test.sh + CI 2스텝.
S3 게이트 훅 본체 — 판정 13단(전부 fail-closed): hook_disabled "publish:receipt"(주의: 정본은 hook_disabled — hook_enabled는 실물에 없음) → python3 엄격 파싱(실패 deny) → registry 재판정(밖이면 무판정 통과) → [비판정] 면제(waivable 도구 한정, waived.log append+플래그, 기록 실패 deny) → digest 계산(Artifact는 그 자리 재해시 — TOCTOU는 공시로) → active/<digest>.<nonce> 탐색(0건 deny) → 영수증 단일 파싱(키 중복 deny, tier 열거형 {1,2} 엄격 — cx-9) → registry min_tier 대조 → 리뷰 산출물의 `발행 3튜플:` 줄 정확히 1회 대조(0·2회·부재·불일치 deny) → tier2면 approval 원자 claim → 원자성은 ln→rm(mv -n 금지 — BSD rc=0 함정; ln 성공 후 rm 실패는 deny+경고) → 통과 직전 .needs-audit에 used/<digest>.<nonce> append(실패 deny — cx-11) → deny 메시지에 digest·요구 tier·발급 절차.
S4 승인 스크립트+배선 — publish-approve.sh(openssl/urandom nonce, no-clobber), install.sh/sync.sh 배선, harness_anchor 추가 + 케이스 75→77. 검증: install 2회 멱등·sync 무변경·install-hook-swap.test.sh.
S5 회귀 테스트 — publish-receipt-gate.cases.sh(EXPECTED_CASES=35, p01~p35 — retry token 경로 제외·p27은 "실패 주장 재발급 불가 deny"까지) + 러너(자기검사 4종·bash3.2 이식성). CI 스텝.
S6 변이 하네스 — mutate-publish-gate.sh 18종 전건 적색(tier 검사 삭제/튜플 중복 허용/min_tier 반전/ln→mv -n/rm 실패 무시/플래그 실패 무시/registry 재판정 삭제/면제 부분일치/artifact 재해시 생략/파싱 실패 통과/approval 대조 생략 등).
S7 — **철회 확정(kty)**: 02_research 패턴 추가 안 함. ADR-0018에 철회 사유(ADR-0015 대안F 존중 + 발행 게이트와 인과 없음) 기록.
S8 규약 문서+ADR-0018 — SKILL.md 발행 리뷰 규약(3튜플 형식·tier 분류: 판정 불명→tier2 fail-closed·발급 단계·재발행은 kty 재승인 단일화) · completion-auditor 검증 4항목+waived 표본 · usage.md 잔존 위험 7종(Bash push·gh·curl / SendUserFile / 신규·중립명 도구 미보호 / 자가 발급 / Artifact TOCTOU / 하네스 밖 디렉터리 / 낡은 매처) · README 훅 개수 정정 · ADR-0018(기각 대안: HMAC·env 승인·스냅샷·retry token — kty 결정 이력 포함, D1~D3).

## cx 매핑: cx-9=S3(7·9단)+p08·p09·변이 / cx-10=S1·S3(6·11단)·S4+p13~p17 / cx-11=S1·S3(4·12단)·S8+p22·p23 / cx-12=S1+e테스트 / cx-13=S3(5단 재해시)+S8 공시 — "틈 막았다" 테스트는 두지 않음(보장-테스트 정합, kty 확정 1번)

## 리스크·롤백
[높음] 게이트 오작동=발행 정지 → registry를 실측 1개(addComment)부터, deny 메시지에 절차, 표준 탈출구 / [높음] digest 비결정성(클라이언트 정규화) → payload fixture 선확보가 착수 조건 / [중] 발행마다 감사 강제 마찰 → 조정은 감사 규약 쪽 / [중] receipts git 추적 → D3(.gitignore 제안) / [낮] 낡은 매처 → registry 재판정으로 무해화. 롤백: squash revert + sync — 단 설치본 settings 배선 잔존(rc=127 무해) 공시.

## 테스트 계획: envelope e01~e08 / gate p01~p35(상세는 planner 원문 — 무영수증·변조·도구명 상이·min_tier·튜플 불일치·중복·tier 열거·승인 소비·nonce 재승인·replay·동시 claim 1건·no-clobber·malformed·유니코드·Artifact 교체·Bash 발급 감사 상승·읽기전용 deny·비판정 3종·실패주장 재발급 불가·드리프트·registry 밖 통과·탈출구·권한 오류·schema_version·해피패스·rm 실패) / 변이 18종 전건 적색 / 측정 공백 공시: python3 부재는 함수 단위만, 승인 위조 테스트는 두지 않음(설계 0절)

## ADR-0018 결정 항목: D1 배치(template/.claude/scripts/ + 앵커 추가 — 대안: harness/ 기존 경로) / D2 registry=글루(덮어씀) / D3 .receipts gitignore 제안
## 미확인: 대상 MCP 도구 전체 이름·payload 모양(S2 착수 조건) / PreToolUse rc=2 deny 해석은 repo 관례로만 확인 / Artifact payload의 파일 경로 유무(없으면 cx-13은 빈 값+공시로)
