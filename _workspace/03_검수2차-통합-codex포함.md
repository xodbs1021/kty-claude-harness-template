# Phase 3 검수 2차 통합 (2026-08-15) — [sec] 차단 · [cx] 보류 · [cc] 수신 대기 → 수정 회차 2
## 1차 지적 닫힘 확인: [sec] C1(stdout 오염)·H1(FIFO/크기)·L1~L5 전부 실측 닫힘 / [cx] Artifact 매처·3튜플 1회·승인 rm 대칭·발급 락·추적표·변이 trap 반영 확인 / 전 테스트 83/83·변이 43 적색 재확인(양축 독립 실행)
## CRITICAL (신규, [sec·cx] 독립 수렴 — 실측 재현 2건)
1. used_count의 deny가 **명령 치환 서브셸**에서 실행(guard:98-104, 호출부 :201·:346) — exit 2가 서브셸만 죽이고 부모는 빈 문자열→`[ "" -gt 0 ]` 오류→단락→replay=0. **chmod 300 used/ 한 번으로 tier1 재발행이 재승인 없이 통과, 차단 메시지 2줄 찍히는데 rc=0.** p82는 chmod 000이라 다른 deny로 거짓 초록. 수정: 판정·deny를 본셸로(8단 RECEIPTS_ACTIVE의 올바른 형태 :206-209 참조), used_count는 상태값만 반환. p82를 chmod 300으로 교체 + "서브셸 deny 재도입" 변이 추가.
## HIGH
2. [sec H2 잔존] sanitize가 유니코드 서식문자(U+2028 LINE SEP·U+202E RLO) 통과 — 렌더러에 따라 줄 위조·시각 뒤집기 부활. + :162 registry 실패 경로가 sanitize 미경유. 수정: 정화에 비ASCII 서식문자 클래스 제거(또는 비ASCII 전체를 \uXXXX 이스케이프), 모든 stderr 경로 sanitize 단일화. 영수증 문자집합도 동일 기준.
3. [cx H] artifact 해시의 stat→open 사이 종류 재확인 없음(TOCTOU — 실측 2s 정지 재현) — open 후 os.fstat으로 S_ISREG 재검사([sec L7 동일 — 심각도는 cx 실측 기준 HIGH 채택).
## MEDIUM
4. [sec M1 잔존] usage.md 롤백 확인 줄 `! grep -q ...`가 set -e 면제로 무동작(실측) — `if grep -q ...; then exit 1; fi`로 교체.
## LOW
5. [cx] payload 상한 경계: 정확히 1MiB+개행 1바이트 통과(head -c 명령치환 개행 제거) — 경계 재정의 또는 stat 기반. 6. [cx] 변이 수치 불일치: 실행 43 vs 케이스 표 m03 잔존 vs ADR 44 — 3곳 일치화. 7. [sec L6] 상한 검사 바이트/문자 단위 불일치(fail-closed지만 사유 오도) — LC_ALL=C 고정. 8. [sec INFO] ADR "폭발 반경" 서술이 구 매처(mcp__.*)로 남음 — 실제 배선(|.*Artifact.*)과 일치화 + 과대 매칭(ReadArtifactMetadata류) 공시.
## 참고: codex는 로컬에 af9022b·1ae0c1e 객체가 없어 동일 역할 커밋 2957a2f·938ef15 검토(developer 보고 해시와 불일치 — 수정 회차에서 실제 HEAD 해시 확인·보고할 것)
## [cc] 2차 도착(2026-08-15) — 판정 보류. 1차 지적 닫힘 확정(C-1·M-1 e2e 재현 rc=2, p67/p68 유효, install-hook-swap 간섭은 결함 아님 확정). 신규:
- NEW-1 = 위 CRITICAL 1과 동일(3축 수렴). 추가 요구: p82 픽스처 chmod 000→300 교체(현재는 우연의 초록), m41은 문구 어서션만 재므로 실효화 또는 정적 한계 공시. "서브셸 deny 재도입" 변이 추가.
- NEW-2 [MED] 매처 확대(mcp__.*|.*Artifact.*)가 서술 4곳(guard 주석 2·ADR:15·usage:116)에 미반영 — 일치화 + .*Artifact.* 과대 매칭(비MCP 도구) 공시.
- NEW-3 [LOW] 변이 수치 43(실물) vs 44(ADR·progress·대응표 m03 댕글링) — 3곳 일치화.
- NEW-4 [LOW] payload 상한 바이트/문자 혼용 = [sec L6]·[cx LOW]와 동일 — LC_ALL=C 고정 + 1MiB+개행 경계 정정.
- L-4 잔여(wiring_precheck 위치)는 문구 정정으로 부분 해소 — 위치 이동은 무해 판단 유지, 공시로 종결.
## 최종 수렴 (2026-08-15, 고정 HEAD 8be6ffc — 실제 이력 aebeada→02df7b3→8be6ffc)
[sec] 통과(3차) · [cc] 통과(최종 — 변이 EXIT=0·프리플라이트 대조군 검증·전 스위트) · [cx] 통과(최종 — fd 단일 관측 0.03s 즉시 실패·46=46·프리플라이트 실효). **Phase 3 종결.** 잔존(전부 공시됨): 훅 timeout 의미론 미확인·상한 잠정값·정적 케이스 3종·등재 0 출하.
