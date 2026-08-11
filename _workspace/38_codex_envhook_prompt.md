너는 독립 코드 검수자다. 파일 생성·삭제·수정 없이 **정적 독해로만** 판정하고, 출력 맨 위에 판정 줄: `판정: 통과` 또는 `판정: 보류` (CRITICAL/HIGH 1건이면 보류). **검증 기준 커밋 = 현재 HEAD (feat/harness-env-edit-check 브랜치)** — 워킹트리는 이 커밋과 동일하며, 다른 프로세스는 돌지 않는다.

## 검수 대상 (harness.env 편집 검증 훅 — ADR-0016)
- `template/.claude/hooks/_common.sh` — `harness_env_value` 반환 계약 3분화(rc 0/1/3, 둘째 인자)
- `template/.claude/hooks/check-harness-env.sh` — 신설 훅
- `template/.claude/hooks/verify-before-stop.sh` — 타입체크 생략 사유 분기(rc=3/1)
- `template/.claude/settings.json` — PostToolUse 배선 추가
- `tests/check-harness-env.test.sh`(12케이스) · `tests/harness-env-read.test.sh`(81 — 부재 8건 1→3, i14)
- `_workspace/mutate-env-check-hook.sh`(7변이) · `_workspace/mutate-harness-env.sh`(앵커 재조준 3건)
- `docs/decisions/2026-08-11-harness-env-edit-check.md` (ADR-0016 — 설계 근거)

## 검수 항목
1. **rc 계약 변경의 파급** — harness_env_value 의 모든 호출부(grep 으로 전수 확인)가 1↔3 구분 추가 후에도 옳게 동작하는가. 특히 지식 게이트(부재→켜짐 유지)와 install/sync·다른 훅에 숨은 호출부가 없는가.
2. **awk exit 3 경로** — awk 스크립트가 exit 3 을 낼 때 셸 case 매핑이 정확한가. awk 자체 오류(rc=2)가 부재로 위장될 길이 없는가.
3. **훅의 문법 구멍** — 경로 앵커·개행 가드·상대경로·둘째 인자 전달에 mark-needs-audit 관용구와 어긋난 곳. 침묵해야 할 입력이 경고되거나(위양성) 그 반대(위음성).
4. **테스트가 무는가** — 12+81 케이스의 단언이 헐거운 곳, 변이 7+21 의 앵커·대체가 의도와 다른 곳. 특히 재조준 3건(선언 2개 거부·조기 종료·Stop rc 구별)이 원래 재던 방어를 실제로 재는가.
5. **bash 3.2 이식성**.
6. ADR-0016 공시(못 잡는 것)와 실물의 정합.

## 출력
판정 줄 → 지적마다 심각도 + 파일:라인 + "어떤 입력 → 어떤 잘못된 결과". 한국어. 미확인은 "미확인".
