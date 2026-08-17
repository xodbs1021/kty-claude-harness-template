사전 결정 회수: docs/decisions ADR-0005(커밋 분할 근거=리뷰 가독성)·0007(게이트 범위=파일 정체성)·0008(지식 게이트 기본 켜짐·harness.env 판독 계약)·0011(자기규율 게이트=방지턱)·0015(레퍼런스 게이트·02_research 명명 기각)·0016(harness.env 편집 검증·반환 계약 3분화)·0017(codex MCP 가드) + 설계 rev4·cx-9~13·clarifier QA 5건 + 계획 r1~r4 듀얼 지적 전건(7절 매핑)
레퍼런스 조사: 조사함(rc-수집보고.md [rc] 31건 → [re] 채택 18·기각 1(인용 교체 완료)·보류 12(미인용) — 채택분은 2·3절과 S8에 인용, RFC7515=유추·RC-12=2차출처+NVD 교차·GNU mv 이력=미확인 라벨 병기)
- 걸리는 선행 결정: ADR-0005 — 단일 PR·squash, 커밋 분할은 리뷰 가독성 근거로만
- 걸리는 선행 결정: ADR-0008 — harness.env 키 신설 금지(표준 탈출구만)
- 걸리는 선행 결정: ADR-0011 — 자가 발급 사전 차단 불가 명문화
- 걸리는 선행 결정: ADR-0016 — 판독 실패를 조용한 생략으로 만들지 않는다(fail-closed·json_get 미사용)
- 걸리는 선행 결정: ADR-0017 — rc=2·stderr 안내 승계, 전역 배선 안 함
- 걸리는 선행 결정: ADR-0015 대안F — 02_research 철회(kty)
- 걸리는 선행 결정: ADR-0007 — 승인·발급 스크립트는 .claude/scripts/ 정체성으로 앵커 등재
- 걸리는 선행 결정: 도메인 누출 0 원칙 — registry 벤더 도구명은 의도적 예외로 ADR-0018 공시(기계 검사 비적용 확인됨)

# 01_plan rev5 — 외부 발행 게이트 (r1~r4 전건 반영·자기완결)

## 0. kty 확정(재론 금지): TOCTOU 공시 / retry token 제외(재발행=재승인) / 표준 탈출구 기본 ON / 단일 PR / 02_research 철회 / scripts 배치·프로젝트 층만 배선

## 1. 영향 범위(자기완결 — r4 M 반영)
신규: template/.claude/hooks/guard-publish-receipt.sh · template/.claude/scripts/publish-issue-receipt.sh(발급기)·publish-approve.sh(kty 전용) · template/.claude/harness/publish-registry.txt · tests/publish-envelope.test.sh · tests/publish-receipt-gate.{test,cases}.sh · _workspace/mutate-publish-gate.sh · docs/decisions/2026-08-14-external-publish-receipt-gate.md(ADR-0018)
수정: _common.sh(publish_digest+record_flag 이관+receipts 상수) · mark-needs-audit.sh(record_flag 삭제·harness_anchor에 */.claude/scripts/* — 케이스 75→77) · settings.json(광역 고정 매처 1건) · install.sh/sync.sh(scripts·registry 배선 + **중복 배선 검출**: 같은 command가 2개 이상 매처 항목에 있으면 경고·중단 — r4 B3) · check-rules.yml(스텝 **2건**: envelope→gate 러너, 기존 순서 관례) · **SKILL.md 발행 리뷰 규약 신설**(3튜플 문법·tier 분류(판정 불명→2)·발급 단계·재발행=재승인 — 이 규약 없이 구현되면 판정 11이 100% deny이므로 같은 PR 필수) · **completion-auditor.md 검증 절차**(used·approval-used·waived 전수 열거: ①리뷰 산출물 실재 ②3튜플 일치 ③승인 연계(모든 approval_required 건 — tier1 재발행 포함) ④발행물 표본 대조 ⑤**intent 기록됐는데 used 부재 = 미소비 시도**로 해석(WAL 계약) ⑥로그 없는 waived 플래그 = 시도 흔적) · docs/usage.md(훅 표+잔존 위험+**실행 가능한 롤백 절차 명령 블록**: 설치본 훅 파일·settings 항목·registry 제거) · README(훅 개수 재계수 정정)
불변: verify-before-stop.sh · harness.env · 전역 배선

## 2. digest·영수증 계약
digest = SHA-256(canonical JSON 객체 {"schema_version":1,"tool_name":…,"tool_input":…,"artifact_sha256":…}, python3 json.dumps(sort_keys,separators,ensure_ascii=True) UTF-8). JCS 면제 전제 3불변식: (i) 발급·검증=publish_digest 단일 함수(verbatim — RFC8785 1절+RFC7515 5.3[유추 라벨]) (ii) 등재 도구 payload의 중복 키·비정수 수(NaN/Inf) 거부[RFC8785 실패원] — **보장 범위는 "훅 stdin에 남은 중복" 한정**(원본 wire 소실 가능성 공시), 중첩 JSON 문자열 내부 비대상 (iii) 드리프트 방어 = **serializer_identity**(python3 버전+계약 버전)를 영수증에 기록, 대조·진단은 3절 8)·9).
**영수증 스키마 고정(r4 M2)**: schema_version·tool_name·digest·tier·review_artifact·nonce·serializer_identity·issued_at — 8필드 전부 필수, 키 중복·누락·미지 필드 deny. 파일명 active/<digest>.<nonce>.
float 실측 분기: fixture에서 발행 payload에 float 실재 시 그 도구는 거부가 아니라 등록 보류 또는 필드 문자열 정규화(실측 전 단정 금지).

## 3. 게이트 판정 순서(순서가 계약)
1) hook_disabled "publish:receipt" → exit 0
2) 최소 파싱: **최상위 tool_name 정확히 1개**(object_pairs 검사 — 중복 tool_name 키·비문자열·추출 불가 = deny. tool_input 내부는 안 봄)[cx-14]
3) registry 로드(strict TSV — 부재·형식 오류·중복 행 deny) → 미등재 tool_name = exit 0
4) 엄격 파싱(등재 도구만): payload 전체 — JSON 오류·중복 키·비정수 수 deny
5) digest 계산(Artifact는 file_path 재해시 — TOCTOU 공시. 경로 미확인 도구는 미등재로 시작)
6) [비판정] 면제(waivable 도구·본문 시작 한정): **플래그 먼저 append → waived.log append**[cx-17 — 로그 실패 deny 시 로그 무잔재, 플래그만 남음=시도 흔적(감사자 계약 ⑥)]. 둘 다 성공 시 통과
7) 재발행 검사: used/<digest>.* 존재 → replay=true. **approval_required = (tier==2) || replay**[cx-15 단일화]
8) active/<digest>.* 탐색: 같은 digest 2개+ deny. **0건이면 드리프트 진단 서브루틴**[r4 B1⑴]: active/ 전수 열거, serializer_identity가 현 환경과 다른 영수증 존재 시 "직렬화 드리프트 의심 — 재발급 전 환경 대조" 진단으로 deny(복구 절차 안내), 아니면 일반 무영수증 deny
9) 영수증 스키마 파싱(2절 — 위반 deny). serializer_identity ≠ 현 환경 = 드리프트 의심 deny+복구 안내[정책: deny 확정, r4 B1⑶]
10) min_tier 대조 → 11) 리뷰 산출물 3튜플 단일 정규식 1회·tier 일치
12) approval 선택(approval_required 시): digest 일치 approval-active/* 열거 — **최고(最古) 1개 선택**(2개+ 허용·선택 규칙 고정), 0건 deny
13) **감사 선기록(WAL)**: .needs-audit에 intent(used 예정 경로 + approval nonce(있으면 — tier1 재발행 포함)) append — 실패 deny(미소비 상태)[cx-15 감사 연계·cx-16]
14) approval claim(ln→rm): 경합 패배 = deny. **approval 소비 후 15)에서 패배하면 그 승인은 소모 — deny 메시지에 "재승인 필요" 명시**(동시 경합 희귀·공시)[cx-15 정책]
15) 영수증 claim(ln→rm — mv -n 금지 근거는 rev4와 동일 인용). **ln 성공 후 rm 실패 = wedged**(used 존재+active 잔존 — 재claim은 EEXIST, 발급기도 거부 → 자동 복구 불가)[cx-18 정정]: deny + 수동 복구 절차(active 잔존본 quarantine/ 이동 명령) 안내 + 감사 플래그
16) 통과. deny 메시지 공통: digest·요구 tier·발급/복구 절차.

## 4. 단계: S1 유틸(e01~e10: 기존 8종+중복 키·비정수 rc≠0 — 함수 층) → S2 registry+매처(착수 조건: fixture로 도구명·payload·stdin 원본성·Artifact 경로·float 실재 + **발급기 환경 python3 정체성 == 훅 환경 정체성 실측**[r4 B1⑵]) → S3 훅(3절 그대로 — 400줄 초과 시 유틸 분리·800줄 상한) → S4 발급기·승인·배선·앵커(75→77) → S5 케이스 → S6 변이 → S7(철회) → S8 문서·ADR-0018(rev4 목록 + 조사 경위="수집 31·채택 18·보류 12 완료" + WAL 감사자 계약 + wedged·경합 정책 + 잔존 위험: Bash push·gh·curl / SendUserFile / 신규 도구 미보호 / 자가 발급 / TOCTOU / 하네스 밖 / registry 글루 배포 시 프로젝트 추가 행 소실 / **구 훅 잔존+registry 부재=광역 deny 조합**[r4 B3] / **registry 단일 파일 오류 시 발행 후보 전 도구 정지(광역 매처 폭발 반경)**[r4 M])

## 5. 테스트: EXPECTED_CASES=**55** = p01~p46(rev4 정의 유지: p45=미등재+정상 envelope+의미 오류=exit 0[범위 한정, cx-14]·p46=정체성 불일치 deny) + p47 선기록 실패 시 **영수증 active 잔존 단언** / p48 게이트 경로 중복 키 deny / p49 게이트 경로 비정수 deny / p50 매처 적중+tool_name 판독 불가 deny / p51 최상위 tool_name 중복 deny / p52 0건+정체성 불일치 영수증 존재 → 드리프트 진단 deny / p53 wedged 상태 deny+잔존 단언 / p54 approval 소비 후 영수증 경합 패배 → deny+재승인 안내 / p55 tier1 재발행의 approval-used 감사 intent 연계. **변이 25종↔케이스 대응표를 cases 파일 머리에 명시**(각 변이당 적색 케이스 ID 1개+ — "감사 선기록→후기록" 변이는 p47이 잡는다: 후기록이면 실패 시 active 소진됨)[r4 B2].

## 6. 리스크·롤백: rev4와 동일 + r4 B3·M 추가분(4절 S8 잔존 위험 목록) / 롤백은 문장이 아니라 usage.md 명령 블록(1절) / 미확인: 도구명·payload·stdin 원본성·Artifact 경로·환경 정체성(전부 S2 착수 조건), rc=2 관례.

## 7. r1~r4 닫힘 매핑: r1~r3 = rev4 5절 매핑 그대로 승계(01_plan_rev4.md — 검증됨) // r4 [cc] B1=3절 8)·9)+S2 환경 실측+정책 deny 확정 / B2=5절 대응표·p47~p51+e09·e10은 함수 층 병행 명시 / B3=1절 중복 배선 검출+usage 롤백 명령+S8 조합 리스크 / M1 폭발 반경=S8 / M2 스키마=2절 / M3 승인 다중·선기록=3절 12)·13) / M4 CI=2건 정정 / M5 영향 범위 자기완결=1절 / M6 회수 라벨=머리(원문 제목 병기) // r4 [cx] 14=3절 2)+p45 한정+p50·p51 / 15=3절 7)·12)~14)+p54·p55 / 16=WAL 계약(1절 감사자 ⑤) / 17=3절 6) 순서 역전+감사자 ⑥ / 18=3절 15) wedged 정정+p53.

## 정오표 (2026-08-14, 승인조건 codex 리뷰 반영 — 본 2건은 계획 본문을 개정한다)
- 3절 7)의 술어는 **replay 판정만** 한다(tier는 9)에서 확정). approval_required=(tier==2)||replay 의 **확정·집행은 12)~14)** — 7)의 표기는 이 해석으로 읽는다.
- p42는 rev4 정의를 **교체**한다: rev5 6) 순서(플래그 선행) 기준 — 플래그 성공·로그 실패 → deny, 로그 무잔재 + waived intent 플래그 잔존 단언.
