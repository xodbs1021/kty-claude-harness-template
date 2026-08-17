사전 결정 회수: docs/decisions ADR-0005·0007·0008·0011·0015·0016·0017 + 설계 rev4·cx-9~13·clarifier QA 5건 + 계획 rev1~rev3 듀얼 지적 전건(아래 닫힘 매핑)
레퍼런스 조사: 조사함(rc-수집보고.md [rc] 31건 → [re] 채택 18·기각 1(인용 교체 완료)·보류 12(본 계획 미인용) — 채택분은 "조사 반영" 절에 인용, 유추·2차출처 한계 라벨 병기)
- 걸리는 선행 결정: ADR-0005 — 단일 PR·squash, 커밋 분할은 리뷰 가독성 근거로만
- 걸리는 선행 결정: ADR-0008 — harness.env 키 신설 금지, ECC_DISABLED_HOOKS 표준 탈출구
- 걸리는 선행 결정: ADR-0011 — 자가 발급 사전 차단 불가를 훅 주석·usage·ADR 명문화
- 걸리는 선행 결정: ADR-0016 — json_get 금지, 자체 엄격 파서 fail-closed
- 걸리는 선행 결정: ADR-0017 — rc=2·stderr 안내 승계, 전역 배선 안 함(차이 공시)
- 걸리는 선행 결정: ADR-0015 대안F — 02_research 철회 확정(kty)
- 걸리는 선행 결정: ADR-0007 — publish-approve.sh는 .claude/scripts/ 정체성으로 앵커 등재
- 걸리는 선행 결정: ADR-0006/README "도메인 누출 0" — registry의 벤더 도구명은 **의도적 예외**로 ADR-0018 공시(기계 검사는 지식 어휘만 봐 안 잡힘 — check-layer-boundary.sh:71-80)

# 01_plan rev4 — 외부 발행 게이트 구현 (r1~r3 듀얼 지적 전건 반영 클린본)

## 0. 확정 전제(kty·재론 금지): TOCTOU 공시 / retry token 제외(재발행=kty 재승인 단일) / 표준 탈출구 hook_disabled "publish:receipt" 기본 ON / 단일 PR·커밋 축별 / 02_research 철회 / publish-approve.sh는 template/.claude/scripts/ 배치+install·sync 배선 / 프로젝트 층만 배선

## 1. 목표·모듈 경계 (rev2와 동일 유지)
발행 성격 MCP 호출을 PreToolUse에서 가로채 payload 결합 영수증(Tier1)+고위험 kty 승인(Tier2) 없이 통과 금지. 위조 방지 아닌 누락 방지(설계 0절). 경계: envelope·digest=_common.sh 3함수 / 영수증 상태기계=게이트 훅 단독 / 대상 판정=publish-registry.txt 단일(훅이 재판정) / 발급=publish-issue-receipt.sh(정상 경로 유일)·승인=publish-approve.sh(사람 전용) / 사후 감사=used·waived 전수 열거(플래그는 트리거).

## 2. digest 계약 (cx-12 + 조사 반영)
digest = SHA-256(canonical JSON 객체 {"schema_version":1,"tool_name":…,"tool_input":…,"artifact_sha256":…} 를 python3 json.dumps(sort_keys=True, separators=(',',':'), ensure_ascii=True)로 직렬화한 UTF-8 바이트). **JCS 면제의 전제 3개를 불변식으로 명문화**: (i) 발급·검증이 같은 함수(publish_digest 단일 구현, verbatim) — 근거 RFC 8785 1절(정규화는 두 대안 중 하나)+RFC 7515 5.3절(**유추 — 원문 문맥은 문자열 대소문자**임을 ADR에 라벨) (ii) 엄격 파서가 중복 키·비정수 수(NaN/Inf 포함) 거부 — 근거 RFC 8785의 실패원 목록 (iii) **직렬화 드리프트 방어 = 영수증에 직렬화 도구 정체성 기록**(python3 버전 문자열 + publish_digest 계약 버전) — 게이트는 자기 환경과 대조해 불일치면 "드리프트 의심" 진단과 함께 deny. ~~canonical bytes 보존·대조~~는 **폐기**(r3 [cc·cx] CRITICAL: 조회 키가 그 바이트의 digest라 대조 도달 시 항상 동일 — 논리적 항등식. payloads/ 디렉터리·p45·p46·평문 보존 문제까지 함께 소멸).
- 중복 키 보장 범위 축소(r3 cx): 훅 stdin이 원본 wire bytes가 아니라 재직렬화본이면 원본 중복 키는 이미 소실 — **보장은 "훅 stdin에 남은 중복만 거부"로 한정**하고, S2 fixture 확보 시 "stdin이 원본인지" 확인 항목 추가. 중첩 JSON 문자열 내부는 비대상(공시).
- 비정수 수: fixture 실측에서 발행 payload에 float 실재 시 **그 도구는 거부가 아니라 등록 보류 또는 필드 문자열 정규화로 분기**(r3 M1 — 실측 전 "사례 없음" 단정 철회).

## 3. 게이트 훅 판정 순서 (r3 B4·B5 정정 — 순서가 계약)
1) hook_disabled "publish:receipt" → exit 0
2) **최소 파싱: tool_name만 추출**(실패 시에도 — 매처에 걸렸는데 이름조차 못 읽으면 deny)
3) registry 로드(strict TSV: 도구명·min_tier·waivable — 부재·형식 오류·중복 행 = **deny**) → tool_name 미등재면 **exit 0**(엄격 파싱 이전이므로 무관 도구는 float·중복 키에 인질로 안 잡힘 — r3 B4 해소)
4) 등재된 경우에만 **엄격 파싱**(전체 payload: JSON 오류·필드 누락·중복 키·비정수 수 = deny)
5) digest 계산(Artifact는 file_path 파일 그 자리 재해시 — TOCTOU는 공시. 경로 필드 미확인 시 그 도구는 registry 미등재로 시작)
6) [비판정] 면제(waivable=yes 도구 한정, 본문 시작 프리픽스): waived.log에 (시각·도구·digest) append **+ .needs-audit append — 둘 중 하나라도 실패 = deny**, 둘 다 성공 시 통과
7) 재발행 검사: used/<digest>.* 존재 → 승인 필수로 승격
8) active/<digest>.<nonce> 탐색(0건 deny · 같은 digest 2개 이상 deny)
9) 영수증 단일 파싱(키 중복 deny · **tier 정수 열거형 {1,2} 외 전부 deny**("3"/"01"/" 1"/빈값 포함) · 직렬화 도구 정체성 대조(2절 (iii)) 불일치 deny)
10) registry min_tier > tier → deny
11) 리뷰 산출물의 3튜플 줄 `발행 3튜플: tool_name=<v> digest=<64hex> required_tier=<1|2>` 단일 정규식 — 정확히 1회(0·2회·불일치·파일 부재 deny), 튜플 tier ≠ 영수증 tier deny
12) **감사 흔적 선기록**(r3 B5): .needs-audit에 used/<digest>.<nonce> 예정 경로 + (tier2면 승인 nonce) append — **실패 = deny(아직 아무것도 소비 안 됨)**. 과다 기록은 무해(감사 트리거).
13) tier2 또는 재발행이면 approval-active/* 중 digest 일치 파일 원자 claim(ln→rm)
14) 영수증 원자 claim(ln→rm — mv -n 금지: BSD는 건너뛰어도 rc=0[실측 재현], GNU는 "silently fail"[문서 — 버전별 이력은 미확인 라벨]. POSIX link() EEXIST·open(2) NOTES가 근거) — ln 성공 후 rm 실패 = deny+경고(재사용 가능 상태 공시)
15) 통과. deny 메시지에는 digest·요구 tier·발급 절차 안내(자가 발급 용이성은 수용된 한계).

## 4. 단계(커밋)
S1 _common.sh: publish_digest(2절 계약)+record_flag 이관+receipts 경로 상수. 검증 e01~e08(+e09 중복 키 rc≠0·e10 비정수 rc≠0)+mark-needs-audit 75케이스.
S2 registry+settings 고정 매처 1건. **착수 조건: 실세션 fixture**(도구 전체 이름·payload 모양·stdin 원본성·Artifact 경로 유무·float 실재 여부). 미확보 도구는 등록 안 함.
S3 게이트 훅(3절 순서 그대로). **크기 계약(r3 M7): 판정 로직이 400줄 초과 시 _common.sh 유틸로 분리, 800줄 상한 준수.**
S4 발급기(publish-issue-receipt.sh: 스키마 검증·no-clobber·같은 digest active 존재 거부·직렬화 정체성 기록·튜플 사전 대조)+승인 스크립트(publish-approve.sh: nonce·no-clobber)+install/sync 배선+harness_anchor(케이스 75→77).
S5 케이스 러너: **EXPECTED_CASES=46** = p01~p35(변경: p21 Artifact 교체 deny는 "재해시 불일치 deny"로 정의 — 보장-테스트 정합) + p36 같은 digest active 2개 deny / p37 used+승인 없음 deny / p38 used+재승인 통과 / p39 registry 부재 deny / p40 중복 행 deny / p41 형식 오류 deny / p42 waived 부분 실패(로그 성공·플래그 실패) deny / p43 발급기 no-clobber / p44 발급기 튜플 사전 대조 거부 / p45(재정의) **미등재 도구 + malformed payload = exit 0**(B4 순서 증명) / p46(재정의) **직렬화 정체성 불일치 deny**. CI 스텝 **3건**(envelope→gate 러너→기존 관례 순서, r3 M7 정정).
S6 변이: 21종 + "중복 키 허용"·"비정수 허용"·"정체성 대조 삭제"·"감사 선기록을 후기록으로" 4종 = **25종 전건 적색**.
S7 철회 확정(변경 없음). S8 문서·ADR-0018: rev2 내용 + 조사 반영 절(채택 18건 인용 — RC-12는 2차출처+NVD 교차 라벨, RFC7515는 유추 라벨, GNU -n 이력 미확인 라벨) + **조사 경위 정정: "수집 31건·평가 채택 18건 완료, 보류 12건 미인용"**(r3 B1 — "사용자 거부로 생략" 문구 폐기) + 도메인 누출 의도적 예외 공시(M3) + registry 글루 배포로 프로젝트 추가 행이 install마다 소실되는 한계 공시(M2 — 리스크 절에도 추가) + 로컬 훅 강제력 없음(Pro Git 8.3 정본 인용 — RC-30 교체본).

## 5. r1~r3 지적 닫힘 매핑 (r3 M6 — 전건)
r1 [cc] B1 롤백=4절 S8 공시·r3 확인 / B2 발급기=S4 / B3 광역 매처=3절 3)단 / B4 광역 매처 채택으로 소멸(생성기 폐기) / B5 표명=본 파일 머리 2줄(치환 완료) / B6 조사=완료(표명·조사 반영 절) / M1 README 재계수=S8 / M2 registry 글루 위험=S8 공시+리스크 / M3 도메인 누출=S8 공시 // r1 [cx] 1 재발행=3절 7)·13) / 2 발급 생명주기=S4 발급기 / 3 매처 중복=광역 1건 / 4 롤백 실물=S8 / 5 면제 순서=3절 6)(digest 후) / 6 registry fail-closed=3절 3) / 7 Artifact 빈값 금지=3절 5)(미확인 시 미등재) / 8 튜플 문법=3절 11) / 9 케이스=S5 / 10·11 표명=머리 2줄 // r3 [cc] B1=머리 표명+S8 정정 / B2·B3=바이트 대조 폐기 / B4=3절 순서 / B5=3절 12) 선기록 / B6=S5·S6 갱신 / M1=2절 float 분기 / M2·M3=S8 / M4=payloads 폐기로 소멸 / M5=인용 라벨 / M6=본 절 / M7=S3 크기 계약·CI 3건 // r3 [cx] 항등식=폐기 / 중복 키 범위=2절 축소 / payloads 생명주기=폐기 / 표명=머리 치환.

## 6. 리스크·롤백: rev2와 동일 + 추가: registry 글루 배포 시 프로젝트 추가 행 install마다 소실(조용한 게이트 축소 — 공시, 완화: sync 프리뷰가 diff 표시) / 미확인: 도구 전체 이름·payload·stdin 원본성·Artifact 경로(S2 착수 조건) / PreToolUse rc=2는 repo 관례로만 확인 / README 훅 개수는 구현 시 재계수.
