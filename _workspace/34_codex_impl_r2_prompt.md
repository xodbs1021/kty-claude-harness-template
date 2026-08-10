너는 독립 코드 검수자다(라운드 2 — 델타). 파일 생성·삭제·수정 없이 정적 독해로만 판정하고, 출력 맨 위에 판정 줄: `판정: 통과` 또는 `판정: 보류` (CRITICAL/HIGH 1건이면 보류).

## 배경 — 라운드 1 HIGH 는 병렬 측정 아티팩트로 반증됐다
라운드 1(`_workspace/33_codex_impl_review.md`)의 HIGH("실물 훅에 m03 잔류 `if false`")는 검수 시점에 **다른 검수자(ecc:code-reviewer)가 변이 하네스를 실측 실행 중**이어서 변이가 일시 주입된 트리를 읽은 것이다. 근거: ① 변이 실행 종료 후 `git hash-object` = `HEAD` 재확인 ② 현재 실물에 `if false` 부재 ③ 변이 직후 스위트 50/50 초록 실측. 이 항목은 닫힌 것으로 보고 재론하지 말 것(현 실물에서 재발견되면 물론 지적하라).

## 이번 라운드가 볼 것 — 라운드 1 MEDIUM 4·LOW 2 의 반영 델타
1. 사유 상수 정합 — 빈 괄호 사유가 설계 상수 그대로가 됐는가 (`verify-before-stop.sh`)
2. 두 줄 동시 불량의 동시 판정 단언 — r45 1회차가 두 사유(첫 줄이·둘째 줄이)를 요구하는가 (`tests/retrieval-attestation.test.sh`)
3. sort 폴백 미측정 — 공시로 수용됐는가(테스트 헤더 + ADR-0015 기계적 장치 절)
4. 탭 3자리 방어 — r47 이 세 자리를 전부 재고 m36·m37 이 대응하는가
5. 차단 안내의 `- 걸리는 선행 결정 없음` 형식 정정
6. m15 앵커 1회 계약
+ 이 델타가 새로 만든 차단급(CRITICAL/HIGH)이 있는가 — 그 외 새 MEDIUM/LOW 는 기록만.

## 실물
- `_workspace/31_impl.diff` (재생성 — mutate-retrieval-gate.sh 포함)
- `template/.claude/hooks/verify-before-stop.sh` · `tests/retrieval-attestation.test.sh` · `_workspace/mutate-retrieval-gate.sh`
- 설계: `_workspace/00_design-reference-gate.md` §③-2 사유 상수

## 출력
판정 줄 → 항목별 닫힘/미흡 → (있으면) 신규 차단급. 한국어. 미확인은 "미확인".
