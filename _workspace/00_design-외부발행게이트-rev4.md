사전 결정 회수: ADR-025(듀얼 리뷰 기계 강제), ADR-0011(못 막는 것은 못 막는다고 쓴다 — 위치 설정 근거), mark-needs-audit.sh(_workspace skip·Edit|Write 한정 관측 — rev4가 감사 지점을 소비 순간으로 옮긴 이유), guard-hook-disable.sh(사용자 전용 탈출구 선례·우회 한계 자인), 실사고 2026-08-14 + codex 리뷰 3회(rev1·rev2·rev3 변경요청), kty 결정 2026-08-14("b+c 조합")
레퍼런스 조사: 조사함(codex 3라운드 리뷰 전문 — 재검토 기준 4건 포함(스레드 01a0001b-3354-7460-adbb-eac27da44dd1), 훅 실물 mark-needs-audit.sh:172·settings.json:35·guard-hook-disable.sh:48 — 이 세션 확인)

# 설계안 rev4 — 외부 발행 게이트: 누락 방지턱(b) + 고위험 kty 승인(c)

## 0. 위치 설정 (kty 확정, rev3에서 불변)

**누락 방지 방지턱이다 — 사전 위조 방지 장치가 아니다.** 영수증·승인·면제 흔적을 만드는 손과 감시받는 손이 같은 에이전트이므로 작정한 자가 발급은 사전 차단 불가 — 이 한계를 훅 주석과 본 문서에 명시하고, 진정성 검증은 completion-auditor 사후 감사가 담당한다. 실사고의 원인 유형(누락)은 이 방지턱이 구조적으로 막는다. 신뢰 앵커(HMAC)는 kty 기각.

## 1. 2단 게이트 + tier 결합 (3R cx-1 반영)

**Tier 1 — 영수증**: 대상 mutation 호출의 canonical digest(4절)에 대해 `_workspace/.receipts/active/<digest>` 존재 시 통과+원자 소비, 없으면 deny.

**Tier 2 — kty 승인 추가 요구**: 영수증 tier=2면 승인 소비도 요구(2절).

**tier는 발급자의 자유 입력이 아니다** — 세 겹으로 결합:
1. **리뷰 산출물이 `{tool_name, digest, required_tier}` 3튜플을 본문에 명시**해야 하고, 영수증의 tier가 이와 불일치하면 훅이 deny한다(영수증에 리뷰 산출물 경로가 있고, 훅이 그 파일에서 digest·tier 줄을 grep 대조 — 파일 부재·튜플 부재·불일치 전부 deny).
2. **기계 판별 가능 항목은 registry가 최소 tier를 강제**: `publish-registry.txt`의 각 도구 행에 `min_tier` 컬럼(transitionJiraIssue=2, 나머지=1). 영수증 tier < min_tier → deny.
3. 의미 판별이 애매한 발행(계약·ADR 인용, 정정 코멘트)은 리뷰 규약에 "**판정 불명 → tier 2 (fail-closed)**"로 명문화.

## 2. kty 승인 — digest+nonce 파일, 원자 소비 (3R cx-2 반영: env 방식 폐기)

- 승인 절차: kty가 **자기 터미널에서** `scripts/publish-approve.sh <digest>` 실행 → 스크립트가 nonce를 생성해 `_workspace/.receipts/approval-active/<nonce>` 파일 기록(내용: digest·승인 시각). 별도 터미널 실행이라 세션 주입 문제 없음.
- 훅 집행: tier2 영수증 통과 시 digest가 일치하는 approval 파일을 `mv approval-active/<nonce> approval-used/<nonce>` 원자 claim. 일치 파일 없으면 deny. **같은 digest 재발행도 새 nonce 필요.**
- 에이전트의 approval 파일 생성은 금지 명령 + 사후 감사 대상(0절 한계와 일관 — 사전 차단 불가 명시). rev3의 `HARNESS_PUBLISH_APPROVE` env 방식은 소비 불가·세션 잔존 문제로 **폐기**.

## 3. 감사 흔적 — 발급 순간이 아니라 소비 순간에 (3R cx-4 반영)

- **guard-publish-receipt 자신이** 통과(소비) 순간에 `.needs-audit` 플래그를 세우고, 플래그 기록값으로 **안정 경로 `used/<digest>.<nonce>`** 를 적는다(발행은 반드시 이 훅을 지나므로 Bash로 발급한 정상 영수증도 소비 시 반드시 관측됨 — mark-needs-audit의 Edit|Write 한정·_workspace skip과 무관해짐). receipts 분기는 audit 플래그만 세운다(dualreview·knowledge·retrieval은 세우지 않음).
- **completion-auditor 검증 절차 추가**(감사자 규약 문서): used 영수증마다 ① 리뷰 산출물 실재 ② 3튜플 digest·tier 일치 ③ tier2면 approval-used 존재 ④ 발행물(Jira/Artifact)과 digest 일치 여부를 표본 대조.
- used/approval-used는 무기한 보존, **no-clobber**(같은 이름 존재 시 발급 자체가 실패 — nonce가 이름에 들어가므로 충돌은 곧 재사용 시도).

## 4. canonical envelope (3R cx-5 반영)

digest = SHA-256( `schema_version` + `full_tool_name` + `canonical_tool_input`(jq -S -c 결정론 직렬화, 손실 정규화 금지) + `artifact_content_sha256`(Artifact publish일 때 파일 바이트 해시, 그 외 빈 값) ). 도구명이 결합되므로 같은 입력 모양의 다른 도구에 영수증 재사용 불가. **fail-closed**: JSON 파싱 실패·필수 필드 누락·jq/해시 도구 부재·receipts 접근 오류 전부 deny(`json_get`의 빈 문자열 관용 금지). Artifact TOCTOU(검사 후 파일 교체)는 잔존 한계로 명시.

## 5. 재시도 (3R cx-6 반영)

- 발행 API 실패 시: 훅이 아니라 **발행 결과에 결합된 retry token** — PostToolUse(실패 응답 관측) 훅이 `retry-tokens/<digest>.<nonce>` 를 생성하고, 그 token이 있을 때만 리뷰 재실행 없이 영수증 재발급 허용(token 소비형). 결과가 모호(타임아웃 등)하면 자동 재발급 금지 — 멱등 확인(발행물 실재 조회) 또는 tier 무관 kty 재승인 경로로.
- 에이전트의 "실패했다" 주장만으로는 재발급 불가.

## 6. 마찰 관리 — `[비판정]` 면제도 흔적을 남긴다 (3R cx-3 반영)

- 코멘트 본문이 `[비판정]` 프리픽스로 시작하면 영수증 면제. **단 무흔적 통과가 아니다**: 훅이 `waived.log`에 (시각·도구·digest) append + `.needs-audit` 플래그(경량 — 감사자는 waived 표본의 태그 적정성만 점검). 습관적 남용은 감사 로그에 패턴으로 드러난다.
- 면제 적용 도구는 닫힌 목록: addComment 한정(createIssue·editIssue·transition·Artifact는 면제 불가).

## 7. 게이트 대상 registry + 잔존 위험 (3R cx-7 반영)

- `publish-registry.txt`: 도구 전체 이름 + min_tier + 면제 가능 여부. settings 매처는 registry에서 생성(드리프트 테스트).
- **잔존 위험 명시 목록**(0절 위치와 일관, 전부 사후 감사 영역): ① Bash `git push`·`gh`·`curl`(코드=커밋 가드+PR, 위키=docs-check+사람 머지가 담당) ② SendUserFile(사용자 대면) ③ **신규·중립명 mutation 도구는 registry 갱신 전까지 미보호** — mutation smell 대조는 알려진 패턴만 잡는다 ④ 에이전트의 영수증·승인·waived 자가 생성.

## 8. 테스트 (3R cx-8 추가분 포함)

무영수증 deny / payload 변조 deny / **같은 입력·다른 도구명 digest 불일치** / terminal payload+tier1 영수증 deny / **리뷰 산출물 튜플-영수증 tier 불일치 deny** / tier2 승인 없음 deny·digest 일치 승인 통과·타 digest 승인 무효 / **승인 소비 후 같은 digest 재발급 deny·새 nonce 재승인 통과** / used replay deny / 동시 claim 단일 통과 / no-clobber / malformed payload deny / 유니코드·개행 canonicalization 왕복 / Artifact 파일 교체 deny / **Bash 발급 영수증도 소비 시 감사 플래그 상승·used 안정 경로 기록** / **[비판정] 면제마다 waived 로그+플래그** / **성공 호출을 실패 주장 재발급 deny·retry token 경로 통과** / matcher-registry 드리프트 / env·우회 시도 차단.

## 9. 구현 계획

guard-publish-receipt.sh + publish-approve.sh(사용자 전용) + _common.sh 유틸 + publish-registry.txt + 매처 생성 스크립트 → payload fixture 선확보 → mark-needs-audit에 02_research 패턴(초안 게이트, receipts 특수 분기는 불요 — 감사는 소비 훅이 직접) → 리뷰 규약(3튜플·tier 분류·발급 단계) 명문화 → completion-auditor 규약에 3절 검증 추가 → harness-template PR(듀얼 리뷰) → install/sync.

## 10. 열린 질문 (구현 PR에서)

waived 감사 표본 크기 / retry token의 PostToolUse 실패 판별 정확도(도구별 오류 스키마) / Artifact 스냅샷 해시 채택 여부.
