# progress — 외부발행게이트 구현
- 2026-08-14: 설계 rev4(4R 조건부 승인) 입수, 계획 게이트부터 진입. 다음: ecc:planner → plan-reviewer 듀얼.
- 2026-08-14 계획 rev2 저장(듀얼 보류 전건+조사 생략 공시 반영). 다음: 듀얼 재검증.
- rev3 보강(조사 채택분 주입, 케이스 46) 완료. 다음: 듀얼 재검증
- rev4 클린본(r1~r3 전건 매핑) 저장. 다음: 듀얼 4라운드
- rev5(r4 전건 반영·자기완결) 저장. 다음: 듀얼 5라운드
- 2026-08-15 Phase 3 구현(브랜치 feat/publish-receipt-gate, 커밋 6): S1 digest 단일 함수(_common.sh)·S2 registry(활성 0행)·S3 게이트 16단+발급기·승인기·S4 배선/앵커(케이스 75→77)·S6 변이 29종·S8 문서(ADR-0018). 케이스 p01~p66(EXPECTED_CASES=66)·envelope e01~e10. 전 테스트 통과·변이 29 전건 적색·install 2회 멱등 실증.
  방법론: superpowers:test-driven-development 따름
- 2026-08-15 Phase 3 검수 1차 수정 회차(커밋 2): CRITICAL 2(판독기 stdout 오염·비인용 글로브)·HIGH 5(Artifact 매처·3튜플 1회·승인 rm 대칭·FIFO/크기 상한·deny 정화)·MEDIUM 4·LOW 6 반영, 기각 2건은 미반영(사유는 03_검수1차 파일). 케이스 66→**83**(p67~p83 = 검수 실측 시나리오 재현: 공백 경로·깨진 .pth·FIFO·거대 입력·ANSI 위조·승인 rm·동시 발급·심링크·권한), 변이 29→**43**. 적색→녹색 전환 실증.
  방법론: superpowers:test-driven-development 따름
- 2026-08-15 Phase 3 재검수 2차 수정 회차(커밋 1): [3축 수렴 CRITICAL] used/ 판정·차단이 **명령 치환 서브셸**에서 돌아 exit 2 가 서브셸만 죽이고 부모는 계속 간 결함 수정(chmod 300 재현이 수정 전 rc=0·영수증 소비 → 수정 후 rc=2·미소비 실증). 판정을 본셸로, p82 픽스처 chmod 000→300, 7단/13단 문구 분리, 변이 m45 신설. 함께: 정화의 유니코드 서식문자(U+2028·U+202E)·registry 실패 경로 정화 단일화·artifact open 후 fstat 재검사·롤백 `! grep` 무동작 정정·매처 표기 4곳 일치화+과대 매칭 공시·payload 상한 바이트 단위/개행 경계. 케이스 83→**86**, 변이 43→**46**.
  방법론: superpowers:test-driven-development 따름
