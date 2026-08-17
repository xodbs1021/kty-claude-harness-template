# Phase 3 검수 1차 통합 (2026-08-15) — [cc] 보류 · [sec] 차단 · [cx] 보류 → developer 수정 회차
## CRITICAL (차단)
1. [sec C1] _common.sh:665 publish_tool_name의 `2>&1`이 stdout 오염 → 환경 잡음(.pth 오류 등)만으로 게이트 무판정 통과(실측). 수정: 2>/dev/null + 게이트에서 반환값이 `[A-Za-z0-9_.-]+` 한 줄인지 검증, 아니면 deny(rc=3 아님).
2. [cc C-1 + cx-19 동근] guard-publish-receipt.sh:65-71 count_glob 비인용 워드 스플리팅 — 공백 경로에서 재발행=재승인 붕괴(실측, 150·266행 양쪽). used/ 열거 "실패"와 "0건" 미구분도 동근(권한 오류 시 fail-open 실측). 수정: 인용 글로브 인라인 + 디렉터리 읽기 가능성 검사 실패 시 deny + **공백 포함 경로 케이스** 추가.
## HIGH
3. [cx] settings.json 매처가 Artifact 누락(설계는 Artifact+MCP) — `mcp__.*` → Artifact 포함 형태로, p66 갱신.
4. [cx-9 잔여] 3튜플 "정확히 1회"가 grep -qE(존재만)로 구현됨 — 게이트 :228·발급기 :71 양쪽 count==1로. tier1/tier2 중복 선언 리뷰로 우회 실측됨. 케이스 추가.
5. [cc M-1 = cx-claim] 승인 claim의 rm 실패 무시(:284-287) — 영수증(:314)과 동형으로 대칭화(wedged 표식·정확한 안내·감사자 계약에 승인 쪽 동형 상태 추가). 실측: stale 승인 잔존이 신규 승인까지 EEXIST로 봉쇄.
6. [sec H1] artifact 재해시가 FIFO·/dev/zero에서 무한 정지·메모리 고갈(실측). 수정: S_ISREG 검사 + 상한 바이트 스트리밍 해시(초과 deny) + payload 크기 상한. 훅 timeout의 fail-open 여부는 미확인 — ADR 잔존 위험에 "정지로 무력화 가능성 + 실세션 검증 방법" 공시.
7. [sec H2] deny 출력이 payload·영수증 유래 문자열을 무가공 출력 — ANSI·개행으로 하네스 문구 위조 실측. 수정: deny() 한 곳에서 제어문자 치환+길이 절단, 영수증 tool_name·serializer_identity 문자집합 제약 추가.
## MEDIUM
8. [sec M1] usage.md 완전 롤백 블록: set -e + 1단계 성공 확인 + registry는 rm이 아니라 mv 보존.
9. [cx-10] 발급기 동일 digest no-clobber 비원자(동시 발급 race 실측) — tmp 작성 후 ln 원자 생성으로.
10. [cc M-2] `방법론:` 줄이 저장소 어디에도 없음 — progress.md에 구현 기록+방법론 명기(PR 본문 개수 명기는 Phase 4에서).
11. [cc L-1 = cx-23] 케이스 머리에 계획ID→구현ID 대응 3~4줄(p42→p31 등).
## LOW (같은 회차에 싸게)
[sec L1] :244 비인용 $(ls) → 인용 글로브 / [sec L2] claim ln에 심링크 소스 거부([ -L ] deny 또는 -P) / [sec L3 = cx-test] 변이 trap에 git restore 복원 / [sec L4 = cc L-3] .gitignore에 _workspace/.receipts/ 추가(계획 D3 채택) + ADR에 보존 위치 진술 / [sec L5] nonce 끝 '-' 검사 / [cc L-4] wiring_precheck 위치 문구 정정(install은 settings 병합 전 — "백업 전" 문구 한정 명시).
## 기각 (사유 기록)
- [cx CRITICAL "등재 0 = 효력 0"]: 사실이나 kty 확정 사항("미확보 도구 등록 안 함")의 의도된 출하 상태 — registry·usage·ADR 3곳 공시 확인됨([cc]도 타당 판정). 첫 등록 절차가 활성화 경로. 기각.
- [cc L-2 커밋 1955줄]: 재커밋 비용>이득 — ADR-0005 근거는 가독성이므로 PR 본문에 커밋 구성 사유 명기로 갈음.
## 확인된 것: 판정 16단 코드 일치 · 승인조건 v2 확정3+조건 9.5/10 반영 · 변이 29 전건 적색 · 케이스 66 전건(단 공백 경로 부재) · bash3.2 · 시크릿 0 · 셸 인젝션 없음(상기 외)
