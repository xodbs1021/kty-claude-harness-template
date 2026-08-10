# 코드 검수 — 하네스 층 경계 이행 (ADR-0006/0008/0009/0010)

`_workspace/04_review.diff` 가 이번 변경 전체다(origin/main 5ce8597 → HEAD).

## 반드시 지킬 것
- **파일을 만들거나 지우지 마라.** `mktemp`·`rm`·`>` 리다이렉트 금지. 샌드박스가 거부해
  판정 없이 끝난 전례가 있다. **정적 독해로만** 판정하고 **반드시 판정 줄을 내라.**
- 마지막 줄에 정확히 이 형식: `판정: 통과` 또는 `판정: 보류`
- 지적은 `[등급] 파일:줄 — 무엇이 언제 어떻게 틀리는가` 형식. 등급은 CRITICAL/HIGH/MEDIUM/LOW.
  재현 조건(입력·상태)을 반드시 쓰고, 추측이면 추측이라고 밝혀라.

## 무엇을 바꿨나
1. `template/.claude/hooks/_common.sh` — `harness_env_value()` 를 awk 판독기로 재작성.
   `harness.env` 를 실행하지 않고 원문으로 읽는다. 반환 계약: rc=0 = 선언 1개를 지원
   문법으로 판독(값은 빈 문자열일 수 있다) / rc=1 = 값을 믿을 수 없음(파일 없음·읽기
   실패·선언 0개·2개 이상·문법 밖). `harness_knowledge_gate_on()`·`knowledge_gate_active()` 신설.
2. `verify-before-stop.sh` — 플래그 `.needs-vault` → `.needs-knowledge`, 게이트 메시지에서
   상위 층 구현 제거, 타입체크 생략 사유를 rc 로 구별.
3. `mark-needs-audit.sh` — `classify()` 에 `knowledge` 판정 추가(`docs/decisions/*.md`),
   설계·계획 산출물이 듀얼리뷰 + 지식 게이트를 함께 세움.
4. `install.sh` — 훅 교체를 파일 단위 cp 에서 **디렉터리 rename 스왑 2회**로. 신호 핸들러
   INT/TERM/QUIT/HUP, 핸들러 진입 직후 `set +e`, 백업은 `mktemp -d`, 중첩이 계약.
   훅 디렉터리가 심링크면 스왑을 포기하고 파일 복사로 물러서며 알린다.
5. `sync.sh` — 키 없는 설치본에 `HARNESS_KNOWLEDGE_GATE="on"` 을 **append 만** 한다.
6. `scripts/check-layer-boundary.sh` 신설 + CI.
7. 테스트 4종 신설·확장, ADR 3건 신설 + 1건 accepted 전이.

## 특히 봐 달라
- **awk 판독기의 위음성.** 지원 문법 밖인데 rc=0 을 내는 입력이 있나? 히어독 탐지가
  실제 셸과 갈리는 지점은? `LC_ALL=C` 와 BOM 3바이트 절단이 mawk/gawk/BSD awk 에서
  다르게 도나? awk 가 없는 환경은?
- **게이트가 꺼지는 방향의 실패.** 어떤 입력이 `harness_knowledge_gate_on` 을 rc=1(꺼짐)로
  만들 수 있나. 설계상 "리터럴로 빈 값" 하나뿐이어야 한다.
- **rename 스왑의 남은 창.** 신호 핸들러 자신이 죽으면? `hooks_swapped` 플래그와 실제
  파일시스템 상태가 어긋나는 순서가 있나? `trap - ` 시점은 옳은가?
- **sync.sh 의 append.** 원자적이지 않다고 공시했는데, 그 실패가 정말 안전한 방향인가?
  `grep -qE '^HARNESS_KNOWLEDGE_GATE='` 검증이 append 실패를 잡는가?
- **테스트의 위음성.** 통과만 하고 아무것도 안 잡는 케이스가 있나? 픽스처가 겨누는 결함을
  가려버리는 곳은? `install-hook-swap.test.sh` 의 mv shim 이 rc 를 삼키는 곳은 없나?
- **계약 위반.** "슬롯은 프로젝트 소유, 절대 안 덮음" 을 어디선가 어기나?
  사용자 파일을 지울 수 있는 경로가 있나?
- 문서가 **검증된 범위보다 강하게** 약속하는 곳(거짓 공시)이 있나?
