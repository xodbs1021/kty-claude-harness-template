# 명료화 문답 (2026-08-14, kty 확정)
1. Artifact TOCTOU(검사~업로드 틈): **한계로 공시** — 발행 시점 재해시 대조까지만 보장, 틈은 잔존 위험 목록 명시 + 사후 감사. 스냅샷 기각.
2. retry token(발행 실패 재시도 훅): **이번 PR 제외** — 재발행은 kty 재승인 경로 단일화. 8절 테스트를 "실패 주장만으로 재발급 불가(deny)"까지로 축소, retry token 항목은 후속.
3. 새 훅 탈출구: **표준 탈출구 + 기본 ON** — hook_enabled "publish:receipt" (HARNESS_HOOKS/ECC_DISABLED_HOOKS 표준 경로).
4. PR 단위: **단일 PR**, 커밋만 축별 분할(ADR-0005 squash 전제).
부기(이의 없음 확정): publish-approve.sh는 template/.claude/ 하위 배치 + install/sync 배선 정합화 · 발행 게이트는 프로젝트 층에만 배선("하네스 밖 디렉터리 발행 미보호"를 잔존 위험 목록에 추가).
5. (planner 회부) 02_research 명명 게이트 vs ADR-0015 충돌: **① 이번 PR에서 철회** — 항목 삭제, ADR-0018에 철회 사유 기록. 초안 강제는 영수증 발급 절차가 담당 (kty 확정 2026-08-14).
