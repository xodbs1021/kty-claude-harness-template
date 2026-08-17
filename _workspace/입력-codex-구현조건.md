# codex 3·4라운드 리뷰 (gpt-5.6-sol · effort high · 2026-08-14)
## 3R — rev3 변경요청 (스레드 01a0001b-3354-7460-adbb-eac27da44dd1)
재검토 기준 4건 제시: ① tier 자유 입력 금지(리뷰 산출물 {tool_name,digest,required_tier} 대조 + registry min_tier + 불명 시 tier2) ② kty 승인 = digest+nonce 원자 소비(env 방식은 세션 잔존·소비 불가로 불성립) ③ [비판정] 면제도 감사 흔적 ④ 감사 플래그는 발급이 아니라 소비 순간(Bash 발급도 관측되도록) + 안정 used 경로. 기타: envelope에 도구명 결합, 재시도는 retry token 결합, 신규 mutation 미보호 잔존 위험 명시, 테스트 10종 추가.
## 4R — rev4 **조건부 승인** (스레드 01a00020-c715-7a73-9dbd-809bfcf39a6d)
기준 4건 중 ①②③ 반영, ④ 부분(영수증 nonce 출처·상태 전이 미정). **구현 착수 가능 판정.** 구현 PR 필수 조건 5건:
- [cx-9 HIGH] tier 열거형 {1,2} 엄격 검증(그 외 deny), 구조화 튜플 단일 파싱·중복 deny
- [cx-10 MED] 영수증 nonce 생명주기 확정(발급 시 부여 active/<digest>.<nonce> 권장) — 동시 claim·재사용 테스트 정합
- [cx-11 MED] .needs-audit 단일 값 덮어쓰기 방지 — 플래그는 트리거, 감사자는 used/·waived cursor 전수 열거. 감사 기록 쓰기 실패 = deny
- [cx-12 MED] envelope 길이 프레이밍 또는 canonical JSON 객체 해시(단순 연결 금지)
- [cx-13 MED] Artifact TOCTOU: 스냅샷 발행으로 실제 차단하거나 테스트·보장 범위 정합화
