사전 결정 회수: docs/decisions ADR-0005·0007·0008·0011·0015·0016·0017 + 설계 rev4·codex 구현조건(cx-9~13)·clarifier QA 5건 + 계획 rev1 듀얼 리뷰(plan-reviewer 보류 B1~B6·M1~M3 / codex 보류 11건) — 전건 반영
레퍼런스 조사: 실패(plan-reviewer가 요구한 외부 선례 조사(RFC 8785·in-toto·idempotency)의 수집 dispatch가 클라이언트 오류로 반복 실패, 사용자 승인 하에 생략 — 결과 없이 진행. 대체: digest 계약을 "발급·검증이 동일 구현 함수 1개만 사용"으로 좁혀 교차 구현 표준(JCS) 필요성 자체를 제거하고, 이 좁힘과 남는 위험을 ADR-0018에 공시)
- 걸리는 선행 결정: ADR-0005 — 단일 PR·squash, 커밋 분할은 리뷰 가독성 근거로만
- 걸리는 선행 결정: ADR-0008 — harness.env 키 신설 금지, ECC_DISABLED_HOOKS 표준 탈출구만
- 걸리는 선행 결정: ADR-0011 — 자가 발급 사전 차단 불가를 훅 주석·usage·ADR에 명문화
- 걸리는 선행 결정: ADR-0016 — json_get 금지, 자체 엄격 파서 fail-closed
- 걸리는 선행 결정: ADR-0017 — rc=2 차단·stderr 안내 승계, 전역 배선 안 함(차이 공시)
- 걸리는 선행 결정: ADR-0015 대안F — 02_research 철회 확정(kty, ADR-0018에 기록)
- 걸리는 선행 결정: ADR-0007 — publish-approve.sh는 .claude/scripts/ 정체성으로 앵커 등재

# 01_plan rev2 — 외부 발행 게이트 구현 (rev1 듀얼 보류 전건 반영)

## rev1 → rev2 변경 요지
① [cc B3·cx-3·4] 매처 생성기 폐기 → **광역 고정 매처 1건**(`Artifact` + MCP 발행 후보를 넓게 잡는 고정 정규식) + 훅 내 registry가 유일 판정. 생성기·드리프트 테스트·install 병합 중복·잔존 매처 문제 전부 소멸(비대상 도구는 registry 밖 → 즉시 exit 0, 오버헤드 무시 가능). ② [cx-1] 재발행 상태기계 신설: `used/<digest>.*` 존재 시 tier 무관 **kty 승인 요구**(재발행=재승인 단일화 — kty 확정 2번과 정합) + `active/`에 같은 digest 2개 이상이면 deny. ③ [cc B2·cx-2] 일반 영수증도 발급기 스크립트 `publish-issue-receipt.sh`로 기계화(nonce·no-clobber·스키마 검증) — 수기 발급은 감사 대상 공시. ④ [cx-5] `[비판정]` 면제는 digest 계산 **후**(로그에 digest 포함), 로그·플래그 부분 실패도 deny. ⑤ [cx-6] registry 엄격 파서: 부재·형식 오류·중복 행·읽기 실패 = deny(fail-closed). ⑥ [cx-7] Artifact payload에 파일 경로 없으면 **registry 등록 자체를 보류**(빈 값 진행 금지). ⑦ [cx-8] 3튜플 단일 정규식 문법 고정 `발행 3튜플: tool_name=<v> digest=<64hex> required_tier=<1|2>`. ⑧ [cc B1·cx-4] 롤백 서술 정정(install staging 보존으로 구 훅 잔존 실행 — 수동 정리 명령 PR 본문 공시). ⑨ [cc M1·cx] README 훅 개수는 실물 재계수 후 정정. ⑩ [cc B5·cx-10] 표명 2줄을 파일 최상단으로(이 파일이 그 형식). ⑪ digest 상호운용 비목표 선언: 발급기·게이트 모두 `_common.sh publish_digest` 단일 함수 — 교차 구현 없음.

## 목표 / 영향 범위 / 모듈 경계 (rev1과 동일한 부분은 유지, 차이만)
- 신규에서 **삭제**: scripts/gen-publish-matcher.sh · tests/publish-matcher-drift.test.sh
- 신규에 **추가**: template/.claude/scripts/publish-issue-receipt.sh(발급기 — 에이전트 사용, no-clobber·같은 digest active 중복 검사·튜플 사전 대조 후 기록)
- settings.json: 고정 매처 1건 수기 추가(형식 :24-33). registry가 유일 진실 — 매처는 관문일 뿐임을 주석.
- 모듈 경계 추가: 발급기 = 영수증 파일의 유일한 정상 생성 경로(수기·Bash 생성은 사후 감사 부류로 공시)

## 단계 (커밋 단위)
S1 envelope·digest·record_flag 이관 — rev1과 동일 + **digest 단일 구현 계약**(발급기·게이트가 같은 함수 source. 교차 구현 상호운용은 비목표 — ADR 공시). 검증 e01~e08 + mark-needs-audit 75케이스.
S2 registry(고정 매처) — publish-registry.txt(strict TSV: 도구명·min_tier·waivable, 중복·형식 오류는 소비 측에서 deny). **착수 조건 유지: 실세션 payload fixture 확보**(도구 전체 이름·payload 모양·Artifact 파일 경로 유무). Artifact 경로 미확인 시 registry에서 제외하고 공시. settings 고정 매처 1건.
S3 게이트 훅 — 판정 순서(전부 fail-closed): hook_disabled → 엄격 파싱(실패 deny) → **registry 로드**(부재·오류 deny) → 등재 여부(밖=exit 0) → digest 계산(Artifact는 그 자리 재해시) → [비판정] 면제(waivable 한정, waived.log에 시각·도구·digest append + .needs-audit — 어느 한쪽 실패도 deny) → **재발행 검사: used/<digest>.* 존재 시 승인 필수로 승격** → active/<digest>.<nonce> 탐색(0건 deny·같은 digest 2개+ deny) → 영수증 단일 파싱(키 중복 deny·tier 열거형 {1,2} — "3"/"01"/" 1"/빈값 deny) → registry min_tier 대조 → 리뷰 산출물 3튜플 정규식 정확히 1회(0·2회·불일치·파일 부재 deny) → tier2 또는 재발행이면 approval-active/* digest 일치 파일 원자 claim(ln→rm, mv -n 금지 — BSD rc=0 함정; rm 실패 deny+경고) → 영수증 ln→rm claim → .needs-audit에 used/<digest>.<nonce> append(실패 deny) → 통과. deny 메시지: digest·요구 tier·발급 절차 안내(자가 발급 용이성은 수용된 한계 — ADR).
S4 발급기·승인 스크립트·배선 — publish-issue-receipt.sh(스키마 검증·no-clobber·같은 digest active 존재 시 거부) + publish-approve.sh(kty 전용, nonce, no-clobber) + install.sh scripts/ 복사·chmod + sync 프리뷰 + harness_anchor `*/.claude/scripts/*` + 케이스 75→77. 검증: install 2회 멱등, install-hook-swap, 실행권한.
S5 회귀 테스트 — publish-receipt-gate.cases.sh **EXPECTED_CASES=44**: rev1 p01~p35(35종 — p28 드리프트 검사는 "settings 매처 존재+registry 대조" 정적 검사로 대체) + p36 같은 digest active 2개 deny / p37 used 존재+재발행 승인 없음 deny / p38 used 존재+재승인 통과 / p39 registry 부재 deny / p40 registry 중복 행 deny / p41 registry 형식 오류 deny / p42 waiver 로그 성공+플래그 실패 부분 실패 deny / p43 발급기 no-clobber(동명 발급 실패) / p44 발급기 튜플 사전 대조 실패 시 발급 거부. 러너 자기검사 4종·bash3.2 이식성 승계.
S6 변이 하네스 — 18종 + 재발행 검사 삭제/active 중복 허용/registry 오류 통과 3종 추가 = 21종 전건 적색.
S7 — 철회 확정(변경 없음).
S8 문서·ADR-0018 — rev1 + 추가: 재발행 상태기계·발급기 계약·digest 단일 구현(상호운용 비목표) 결정·조사 생략 경위(사용자 거부)와 남는 위험(클라이언트가 payload를 호출 직전 변형하면 digest 불일치 — fixture로 실측 검증이 유일 방어)·롤백 실물 서술(staging 보존→구 훅 잔존, 정리 명령).

## cx-9~13 매핑(갱신): cx-9=S3+p08·p09·튜플 정규식 / cx-10=발급기·S3 재발행 검사+p13~p17·p36~p38·p43 / cx-11=S3 append 계약+p22·p23·p42 / cx-12=S1 객체 해시+단일 구현 계약 / cx-13=S3 재해시+S8 공시(Artifact 미확인 시 등록 보류)

## 리스크·롤백(정정): [높음] 오작동=발행 정지 → registry 실측 1개부터+deny 안내+표준 탈출구 / [높음] digest 비결정성 → fixture 선확보가 착수 조건, 미확보 시 해당 도구 등록 안 함 / [중] 발행마다 감사 강제 마찰 / [중] .receipts git 추적 → D3 gitignore / 롤백 = squash revert + sync **단 설치본은 staging 보존으로 구 훅이 계속 실행됨 — 정리 명령(설치본 훅 파일·settings 항목 제거 절차)을 PR 본문에 공시**.

## 미확인: 대상 MCP 도구 전체 이름·payload 모양·Artifact 파일 경로 유무(S2 착수 조건) / PreToolUse rc=2 deny는 repo 관례로만 확인 / README 훅 개수 실물(구현 시 재계수)

# rev3 보강 — 레퍼런스 조사 반영 (2026-08-14, [rc] 수집 31건 → [re] 채택 18)
표명 갱신: `레퍼런스 조사: 조사함(rc-수집보고.md 31건 — evaluator 채택 18·기각 1(인용 교체)·보류 12(미인용), 평가 스코어카드 별도)` — rev2의 실패 표명을 대체한다.

채택 근거의 계획 반영(각 항목은 기존 단계에 편입):
1. [RC-18·20·22·23 강함] **ln 원자 소비·mv -n 금지**가 표준·실측으로 확정 — S3 판정 11의 근거 인용을 POSIX link() EEXIST·open(2) NOTES·BSD/GNU mv 상충 병기로 교체. GNU에서는 -n이 비영 종료라 플랫폼 간 신호가 반대라는 상충을 ADR에 병기.
2. [RC-3·4 보통, 유추 명시] **JCS 면제의 전제 3개를 불변식으로 명문화**: (i) 발급·검증이 같은 함수(verbatim) (ii) 해시 대상에서 비정수 수·NaN/Inf·중복 키 거부 (iii) 직렬화 도구 드리프트 방어. RFC 7515 5.3절 인용은 "문자열 대소문자 문맥의 유추"임을 ADR에 명시.
3. [전제(iii) 근거 0건 → 설계로 해소] **canonical bytes 보존·대조 신설**: 발급기가 canonical 직렬화 바이트를 `.receipts/payloads/<digest>`에 저장하고, 게이트는 소비 시 재직렬화 바이트를 저장 바이트와 **대조**한다 — 불일치 = 직렬화 드리프트 감지 → deny+진단(단순 재계산보다 강함, jq 버전 실측 불요化). S1·S3·발급기·케이스(p45 드리프트 감지 deny·p46 payloads 부재 deny)에 추가, EXPECTED_CASES=46.
4. [RC-1 강함] S3 엄격 파서에 **중복 키 거부(object_pairs_hook)·비정수 수(NaN/Inf 포함) 거부** 추가 — 발행 payload에 float가 필요한 사례 없음을 공시(있으면 문자열로).
5. [RC-9·28·12 — 내용 결합·1회 읽기] "검사한 바이트=사용한 바이트" 원칙의 근거 인용(in-toto digest 매칭·GitHub stale approval 차분 결합·Kyverno CVE 2회 fetch 사고) — ADR 근거 절.
6. [RC-24 강함] used replay 탐지 시 deny + 감사 플래그에 replay 기록(소급 폐기 대상은 없음 — 발행은 비가역, 한계 공시). [RC-25] 후속 retry token 설계 근거로 ADR에 기록.
7. [RC-30 정정 인용] 잔존 위험 "로컬 훅은 강제력 없음 — 강제는 서버 측" 근거를 Pro Git 8.3 정본 인용으로.
