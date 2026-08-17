# [rc] 수집 보고 — 발행 게이트 4축 선례 (2026-08-14, research-collector)
평가 지침: 아래 각 항목의 인용 실존·출처 등급·주장-근거 갭을 독립 검증할 것. 특히 "원문 미열람" 표시 3건(RC-12·30·31)과 공백 절.

## 축1 Canonical JSON
- RC-1 RFC 8785 JCS (IETF Informational, rfc-editor.org/rfc/rfc8785.txt): 수 표현은 ECMA-262 7.1.12.1 위임, 정렬은 UTF-16 코드 유닛, 출력은 UTF-8 MUST. 중복 키 MUST NOT, IEEE754 초과 수는 문자열 권장, NaN/Inf는 오류로 종료 MUST.
- RC-2 RFC 8785 3.2.3 Note: UTF-8/UTF-32 정렬도 실무상(ASCII 키) JCS 호환 가능 — "Whether or not this is a viable option depends on the environment JCS is used in."
- RC-3 RFC 8785 1절: 불변 표현의 두 갈래 — 고정 표현에 서명(JWS 방식) vs 정규화. 정규화는 필수가 아니라 설계 선택.
- RC-4 RFC 7515 5.3절 (rfc7515.txt L981-984): "if all other parties consume whatever value the producing party emitted verbatim without attempting to compare it to an independently produced value, then the case used by the producer will not matter." — 단일 생산자·verbatim 소비면 표기 무관.
- RC-5 Matrix 명세 Appendices(spec.matrix.org/latest/appendices/): canonical JSON을 python json.dumps(ensure_ascii=False, separators, sort_keys)로 정의. float 금지, 정수 ±(2^53-1) 제한.
- RC-6 TUF 명세 4.1(theupdateframework.github.io): OLPC canonical JSON 위임 + 서명 검증 가능하면 타 포맷 허용.
- RC-7 IETF json WG 메일(Cowan 2020-07): JCS의 UTF-16 종속 비판 실존.
- RC-8 trailofbits/rfc8785.py: 순수 파이썬 JCS 구현. "stdlib json이 왜 안 되나"는 README에 없음(공백). gh 메타데이터 미수집(공백3).

## 축2 무서명 digest 결합
- RC-9 in-toto attestation v1 statement.md: subject는 digest MUST, "matched purely by digest", 불변은 가정(SHOULD NOT change).
- RC-10 SLSA v1.0 verifying-artifacts: 1단계 = subject digest 대조. 한계 공시: 빌드 플랫폼 침해 미커버, "limited benefit unless a human or automated system takes action".
- RC-11 SLSA v1.0 threats: "modify it... re-upload it using the original provenance" 위협 + subject 해시 대조 완화. "TOCTOU" 문자열은 미발견(공백4).
- RC-12 CVE-2022-47633 Kyverno(armosec.io 블로그): 매니페스트 2회 fetch(검증용/mutate용)로 TOCTOU. **원문 미열람 — 검색 요약 경유.**
- RC-13 W3C SRI: 서명 없는 순수 digest 결합 표준 + 한계 공시(비보안 맥락에선 다이제스트 자체 교체 가능).
- RC-14 pip secure-installs: 로컬 해시만 유효 — "Since this hash originates remotely, it is not a useful guard" (digest 발급 주체가 신뢰 경계).
- RC-15 apt-secure(8): 1서명+해시 체인, "does not defend against a compromise of the master server... or the key" 한계 공시.

## 축3 1회용 토큰·원자 소비
- RC-16 DJB maildir(cr.yp.to/proto/maildir.html): 유일 이름 구성 규칙, "Do not try to extract information from unique names."
- RC-17 maildir(5) qmail: tmp→new link() 순간이 배달 성공, "no locks are ever necessary", tmp 36시간 GC 규칙.
- RC-18 POSIX link() (pubs.opengroup.org): "shall atomically create a new link" + EEXIST 계약.
- RC-19 POSIX rename(): 원자적이되 기존 대상 덮어씀(1회용 소비엔 link과 성질 다름).
- RC-20 Linux open(2) NOTES: NFS에서 O_EXCL 대신 link() rc=0 = 락 성공 관용구 명문.
- RC-21 BashFAQ/045: 셸 원자 락은 mkdir·set -C(O_EXCL). test-then-create 레이스 설명.
- RC-22 BSD/macOS mv(1) + 실측: -n은 건너뛰기, EXIT STATUS는 "0 on success" — 건너뜀도 rc=0 (macOS 실측 재현: mv -n rc=0, ln 2회째 rc=1 File exists).
- RC-23 GNU coreutils mv: -n은 "silently fail", --update=none이 건너뛰기 — BSD와 의미 갈림. 9.2/9.3 변경 이력 원문 미확인(공백6).
- RC-24 RFC 6749 4.1.2 (rfc6749.txt): auth code = 10분 수명 권장 + "MUST NOT use more than once" + 재사용 탐지 시 기발급 토큰 소급 폐기 SHOULD + client_id·redirect_uri 결합.

## 축4 멱등·재시도
- RC-25 Stripe idempotent_requests: 첫 응답(500 포함) 저장·재반환, 파라미터 불일치는 오류, 24h 후 제거 가능, 실행 시작 전 실패는 미저장(재시도 가능), 민감정보 키 금지.
- RC-26 IETF draft-ietf-httpapi-idempotency-key-header-07(표준 아님): fingerprint(페이로드 체크섬) 병용, 키 재사용+다른 페이로드=422, 진행 중 재시도=409, 만료 정책 공표 SHOULD, 저엔트로피 키 열거 위험.
- RC-27 brandur.org/idempotency-keys: 파라미터 저장 이유=불일치 오류, recovery point, 24h 회수.

## 인접 — 내용 결합 승인
- RC-28 GitHub 보호 브랜치: "Dismiss stale approvals" = 새 커밋 시 승인 폐기(승인이 내용에 결합), strict 상태검사, 서명 커밋 강제.
- RC-29 GitHub commit statuses API: POST /statuses/{sha} — 검사 결과가 SHA에 결합.
- RC-30 Pro Git 8.3/8.4: "each developer can alter their own local hooks, so you can't use them as a way to enforce a commit policy" — 강제는 서버 측. **원문 미열람.**
- RC-31 GHES pre-receive hooks 문서: 푸시 전 정책 강제. **원문 미열람.**

## 공백(수집자 자인)
1. "단일 구현이면 JCS 불필요" 정면 문헌 없음 — 간접 근거 RC-2·3·4뿐. 2. ensure_ascii=True의 JCS 위반을 직접 적은 1차 문헌 없음(정황: RC-1 UTF-8 MUST + RC-5 Matrix ensure_ascii=False 선택). float/지수 표기 차이 실측 미실시. 3. RC-8 gh 메타데이터 결손. 4. SLSA에 TOCTOU 문자열 없음. 5. 에이전트 도메인 최신 선례(승인-해시 결합) 확보 실패 — 스니펫 문장이 원문에 부재(2곳 확인). 6. coreutils NEWS 미확인. 7. RC-12·30·31 원문 미열람. 8. 접속 실패 기록: cr.yp.to WebFetch 실패→curl 우회, gnu.org 429→재시도 성공.

## [re] 평가 정정 반영 (2026-08-14, research-evaluator — 채택18·보류12·기각1)
- RC-30 기각→인용 교체: 정본 인용 = Pro Git 8.3 "client-side hooks are not copied when you clone a repository. If your intent with these scripts is to enforce a policy, you'll probably want to do that on the server side" (기존 문장은 Atlassian 튜토리얼 어법 — 오귀속).
- RC-12 URL 확정: https://www.armosec.io/blog/cve-2022-47633-kyvernos-container-image-signature-verification/ + 교차 NVD CVE-2022-47633·GHSA-m3cq-xcx9-3gvm.
- RC-26 라벨: 2026-04-18 만료·no longer active — 보조 근거 한정.
- 보류 12건은 계획에 인용하지 않음(인용 시 재열람 필요). 평가 전문은 evaluator 산출(스코어카드) 참조.
