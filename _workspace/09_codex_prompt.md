# 결정 게이트 — 검수 2라운드 (델타)

**파일 생성·삭제 없이 정적 독해로만 판정하고, 마지막에 반드시 `판정: 통과` 또는
`판정: 보류` 줄을 내라.** 그 줄이 없으면 이 라운드는 미수행으로 센다.

1라운드에서 네가 낸 지적 9건을 전부 반영했다. **반영이 옳은지, 그리고 반영이 새 결함을
만들지 않았는지**를 본다.

## 델타
`_workspace/09_delta.diff` (기준 `238a979` → HEAD). 전체 맥락은 저장소 안:
- `template/.claude/hooks/_common.sh` 의 `decision_scan()`
- `template/.claude/hooks/verify-before-stop.sh` 의 `(3.2)` 절 · `emit_decision_note`
- `tests/decision-gate.test.sh` (59건) · `_workspace/mutate-decision-gate.sh` (35건 전건 적색)
- `docs/decisions/2026-08-10-decision-gate.md`

## 무엇을 어떻게 고쳤나

1. **rc 계약 재정의** — 0=차단, 2=판독 불가(사유 있음), 3=차단 불필요, **그 밖=판독 불가로 취급**.
   정상 통과에 1 을 주지 않는 것이 핵심이다(크래시도 1 이라 위장됐었다).
2. **부분 손상도 판독 불가** — 한 줄이라도 JSON 파싱 실패면 fail.
3. **형식 변화 감지** — `message` 가 비-dict, `content` 가 list/str 아님 → fail. `content` 가
   문자열이면 발화로 취급.
4. **경고를 다섯 게이트 전부에** — `emit_decision_note` 를 듀얼리뷰·설명·지식·push·감사에 호출.
5. **부정형 자백 예외** — `NEG_ASK` 가 걸리면 `QUESTION` 제외를 적용하지 않는다.
6. **발동을 플래그로 다시 물음** — `decision_armed`. push 미완만으로는 안 돈다.
7. **마침표는 뒤에 공백/줄끝일 때만 종결** · `~~~` 펜스 · 이중 백틱 지원.
8. **변이 하네스 트랩이 INT/TERM 에도 복원.**
9. **어휘는 안 좁힌다**(사용자 확정) — 대신 ADR·usage 에 "표본이고 영어는 커버리지 0"을 공시.

## 특히 봐 달라

- **위 고침이 만든 새 결함.** 1라운드 수정이 2라운드 결함을 낳는 것이 이 저장소의 알려진 패턴이다
- `decision_armed` 와 조기 종료·`flags_fp`·예산의 상호작용
- `emit_decision_note` 가 `set -uo pipefail` 아래에서 안전한가. 미설정 변수 참조 경로
- 파싱 엄격화가 **정상 기록을 판독 불가로 떨어뜨리지 않는가**(위양성 쪽) — 실제 기록은
  `queue-operation`·`attachment`·`last-prompt`·`custom-title` 같은 항목도 섞여 있다
- 문서(ADR·usage)가 **여전히 검증 범위보다 넓게** 약속하는 곳이 있나

## 형식
지적마다 `[등급] 파일:줄 — 무엇이/왜/어떻게`. 추측이면 `추정` 명시. 마지막 줄에 `판정: 통과|보류`.
