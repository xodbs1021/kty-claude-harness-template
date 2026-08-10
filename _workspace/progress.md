# ADR-0006 층 경계 이행 — 재작업 (2026-08-07 시작)

## 왜 재작업인가
앞선 세션에서 **커밋 29개 + raw 4.6MB 가 소실**됐다. 임시 스크래치패드에만 있었고
브랜치를 한 번도 push 하지 않았다. 경위·1차 증거는 볼트
`Projects/harness-template/specs/2026-08-07-작업물-소실-사후분석.md`.

## 이번엔 다르게 하는 것
- **작업 위치**: `~/Downloads/kty-claude-harness-template` (지속). 임시 폴더 금지
- **커밋마다 즉시 push**. 검수 통과는 push 의 전제가 아니다 — 그 착오가 29커밋을 날렸다
- 볼트에 근거(raw) 게이트가 섰다(볼트 ADR-009) — 결정 커밋에 `evidence:` 필수

## 기준점
`origin/main` = `5ce8597` (PR #14 반영). tests/ 는 3개뿐이고
`harness-env-read`·`knowledge-gate`·`install-migration`·`check-layer-boundary` 4종은 없다.

## 진행

### ⓪ harness.env 원문 판독 — 커밋 33158e2 (push 완료)
source 를 버리고 `harness_env_value()` 원문 grep 으로. exit/서브셸/return/printf 재정의
탈출 경로가 원리적으로 소멸. 실측: 정상=[pnpm tsc --noEmit] · exit 1 포함=[pnpm tsc] ·
exit 0 포함=[pnpm tsc] · 들여쓴 위장=[진짜] · 선언 2개=[]

**[cx] 라운드 1 판정: 보류** (`_workspace/03_impl_r1_codex.md`). [cc] 미실행.
 - **[MEDIUM] 회귀 — 후행 주석.** `KEY="printf ok" # note` 가 전에는 `printf ok` 였는데
   이제 `"printf ok" # note` 전체를 값으로 돌려준다 → `sh -c` 가 명령 이름으로 해석해
   **rc=127 → 타입체크가 조용히 생략된다.** codex 가 표현식 평가로 실측 확인
 - **[MEDIUM] 히어독 오인.** 물리적 행 grep 이라 히어독 본문의 같은 키를 선언으로 세어
   "2개" 판정 → 빈 값 → 생략. "최상위 대입만 센다"는 판독 모델과 불일치
 - **[MEDIUM] 회귀 테스트 0건.** 위 둘이 현재 검출되지 않는다
 - **[LOW]** `harness.env.template:1` 이 아직 "source 하는 설정"이라 안내. 지원 문법과
   CRLF/BOM 정책을 문서화해야 한다

**codex 가 확인해준 것(결함 아님):** 접두사 키(`..._EXTRA`) 미매치 · `local` 안전(전부 bash)
· 저장소에 harness.env 다른 키 소비자 없음(source 제거로 죽은 것 없음) · grep rc>=2 삼키기는
이 위협 모델에서 타당(단 "미설정"과 "읽기 실패"는 구별해 경고하는 편이 낫다)


## 완료 감사 (2026-08-07) — 판정 검증됨. 19개 주장 반증 0건, **미보고 결함 4건**
감사가 **원격에서 bare clone 을 새로 받아** 그 안에서 판정했다(로컬 ref 불신).
브랜치·커밋 2개·progress.md 원격 실재 확인 · origin/main(5ce8597) 기반 확인 ·
판독 5건 재현 5/5 일치 · 기존 테스트 43/43·70/70 직접 실행 · 볼트 근거 게이트를
**복사본에 변이 주입**해 실제로 막는 것 확인.
그리고 적대적 harness.env(exit 0/1)로 **Stop 훅을 실제 실행** — 훅이 죽지 않고 rc=2 로
정상 차단. 0축의 가치 주장이 end-to-end 로 검증됐다.

**미보고 결함 4건 (다음 세션 1순위):**
1. **회귀가 1종이 아니라 최소 4종.** 뿌리는 같다 — 따옴표 벗기기가 값의 **양 끝이
   따옴표일 때만** 동작한다:
     KEY="printf ok" # note        -> ["printf ok" # note]  rc=127  (보고했던 것)
     KEY='printf ok' # note        -> ['printf ok' # note]  rc=127
     KEY="printf ok" + 후행공백    -> ["printf ok"   ]      rc=127  **미보고**
     KEY="printf ok" + CR(CRLF)    -> ["printf ok"]         rc=127  **미보고**
   **후행 공백·CRLF 가 후행 주석보다 위험하다** — 눈에 안 보이고 의도치 않게 생긴다
   (Windows 편집, 실수로 남긴 공백).
2. **rc=127 의 실제 귀결이 "조용한 검사 생략"이다.** verify-before-stop.sh:106 이
   rc=127 을 "도구 없음 -> 생략"으로 처리한다. 즉 **후행 공백 하나로 타입체크 게이트가
   흔적 없이 사라진다.** 내 보고는 rc=127 까지만 말하고 이 귀결을 명시하지 않았다.
   Knowledge 18번이 예언한 "fail-open 을 없애려다 다른 fail-open" 이 현행 코드에 살아 있다.
3. **harness.env.template:1 이 아직 "source 하는 설정"이라 안내**하고, install.sh 가
   사용자에게 복사하는 정본인데 새 제약(후행 주석 금지·선행 공백 금지·선언 1개만)을
   한 줄도 적지 않는다. Knowledge 18번이 내린 대응책이 미이행.
4. **_common.sh 주석의 확장 안내가 부정확.** "$VAR 는 확장되지 않는다"고 썼으나 값은
   결국 sh -c 로 넘어가 **실행 시점에 확장된다**(실측: printf $HOME -> /Users/kty).
   판독 시점 미확장은 맞지만 사용자 안내로는 틀렸다.

## 다음 세션 1순위 (감사 반영)
1. **따옴표 벗기기를 고친다** — 후행 공백·CR 을 먼저 잘라내고, 따옴표를 벗기고,
   따옴표 밖 후행 주석을 처리한다. 4종을 한 번에 닫는다
2. **회귀 테스트 신설** (아래 케이스 목록)
3. harness.env.template 문서 정정 + 지원 문법 명시
4. _common.sh 확장 안내 문구 정정

## 다음 세션이 할 일 (원래 목록)
1. **후행 주석 + 히어독 오인 수정**
2. **회귀 테스트 신설.** codex 가 필요 케이스를 뽑아뒀다 — 정상 quoted/unquoted, export
   공백·탭, 선언 0/1/2개, 들여쓰기, 접두사 키, 일반·후행 주석, 히어독, 여러 줄 값,
   따옴표·백슬래시, literal $, CRLF/BOM, 읽기 오류, 그리고 exit 0/1·return·printf 재정의가
   **나머지 게이트를 종료시키지 않는** 통합 케이스
3. 남은 9축: 누출 정리(훅3+스킬1) · `.needs-vault`→`.needs-knowledge` · 훅 rename 스왑 ·
   게이트 슬롯 + sync 동작보존 · 조회 배선 · check-layer-boundary + CI · ADR 4건

## 앞선 세션의 결정 이월
- **B(계약 서술 좁히기) = 게이트 분류 축에 흡수.** "결정·설계가 나온 턴"이 아니라
  "**하네스가 아는 산출물 경로**가 편집된 턴"으로 문서에 쓴다. 별도 작업 아님
- **C(harness.env 에 결정 경로 슬롯) = 기각.** 볼트 `canon-path` 를 볼트 CI 가 이미
  검증하므로 중복이고, 사용자가 패턴 목록을 유지보수하게 만들어 자동화 목적에 역행한다.
  기각 사유를 ADR-0010 재작성에 넣는다
- **D(라운드 닫기) = 소멸.** 닫을 대상이 사라졌다
- **ADR-0010 재작성 시 반영할 것**: 주소/트리거/선택을 갈라 적고 자동화 대상 명시 ·
  "공개 포맷(Obsidian) 의존은 층 위반이 아니다, 사유화된 배치 의존이 위반이다" ·
  볼트 CI 가 보장하는 3가지(링크 무결성·인덱스 완전성·canon 포인터)를 회수 설계의 전제로 ·
  타입별 frontmatter 스키마 미정의가 남은 공백(status 59%·related-projects 27% 누락은
  대부분 "해당 없음"이라 필터를 못 짠다)
