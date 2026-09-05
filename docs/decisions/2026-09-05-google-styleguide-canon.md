# ADR-0023: Google 스타일 가이드를 스타일의 최상위 정본으로 둔다

**Date**: 2026-09-05
**Status**: accepted
**Deciders**: 김태윤(지시·우선순위 확정), Claude(설계·구현)

---

## Context

하네스에는 스타일을 말하는 자리가 셋 있었고, 어느 것도 정본이 아니었다.

- `readable-writing` 스킬 — 사용자 대면 글의 문장 품질. 근거는 Plain Language·인지 부하
  이론이고, 마크다운 **서식**(줄 길이·제목·목록 들여쓰기)은 아예 다루지 않는다.
- 외부 룰셋(ecc `rules/` coding-style 등) — 언어별 관례를 짧게 나열하지만 원문 정본이
  없어 "왜 그런가"를 되짚을 수 없다.
- `developer` 에이전트 작업 원칙 2번 "주변 코드를 닮게 쓴다" — 주변이 이미 틀렸으면
  틀린 것을 복제한다.

그래서 스타일 지적은 근거를 댈 수 없었고, 리뷰에서 취향 다툼으로 번졌다. **결론이 나지
않는 축이 리뷰 시간을 먹는다.**

## Decision

**외부의 공개된 정본 하나를 최상위에 둔다: Google 스타일 가이드**
(https://github.com/google/styleguide, Apache-2.0).

1.  **`google-styleguide` 스킬을 신설한다.** 원문을 `references/` 에 사본으로 싣는다 —
    Go 3종·docguide 2종·shellguide·pyguide(약 468KB). URL 만 적어 두면 "못 읽었으니
    기억으로 쓴다"로 조용히 새고, 그게 정확히 이 정본으로 없애려던 상황이다. HTML 로만
    발행되는 언어(Java·TypeScript·JavaScript·C++)는 URL 매핑만 두고 `WebFetch` 로 읽는다.
2.  **`principles.md` 에 '스타일 정본' 절을 신설한다.** 우선순위 5단계를 못 박는다:
    Google > 제0원칙·변경 규약 > 프로필 불변식 > readable-writing > 외부 룰셋·취향.
    이 파일은 모든 판정 에이전트에 **전문 주입**되므로 강제 지점으로 가장 강하다.
3.  **Google 이 침묵하면 아래 순위가 그대로 산다.** 이건 양보가 아니라 Google 자신의
    규칙이다 — Go 가이드 `Local consistency` 절이 "가이드가 말하지 않는 지점은 주변의
    일관된 입장을 따른다"고 정한다. 그래서 프로젝트 확정 선호가 폐기되지 않는다.
4.  **기계 검사를 기존 게이트에 얹는다.** `scripts/check-style.sh` 가 저장소의 모든 Go
    모듈에서 `gofmt -l` 을 돌린다(vendor·node_modules 제외). 새 훅을 만들지 않고
    `harness.env` 의 `HARNESS_TYPECHECK_CMD` 기본값으로 넣어 Stop 훅이 매 턴 돌리게 한다.
5.  **계약에 물린다.** 오케스트레이터 주입 규칙 표(developer·code-reviewer 행), 공통 계약
    ⑤, code-reviewer dispatch 계약 ⑨, `developer` 착수 전 필수 로드 6번.

## Consequences

**좋아지는 것**

- 스타일 지적에 **정본 근거**(`파일 — 조항`)를 요구할 수 있다. 근거를 못 대면 지적하지
  않는다 — 취향 다툼이 구조적으로 사라진다.
- 새 언어가 편입돼도 정본이 이미 있다(Java·TS·JS·C++ 매핑 완비).
- `gofmt` 위반은 사람 손을 거치지 않고 Stop 게이트에서 막힌다.

**대가**

- **설치본마다 468KB 사본이 생긴다.** 상류가 바뀌면 드리프트한다 —
  `scripts/fetch-guides.sh` 로 갱신하고 `references/FETCHED` 에 취득 날짜를 남긴다.
  오프라인에서도 정본이 열리는 값이 이 중복보다 크다고 판단했다.
- **스타일 게이트가 `HARNESS_TYPECHECK_CMD` 슬롯 하나를 타입체크와 공유한다.** 프로젝트가
  타입체크를 넣으면서 값을 통째로 갈아치우면 스타일 게이트가 조용히 사라진다. 기계가
  막아주지 못하고 `harness.env.template` 주석과 프로필 3절 문구가 경고할 뿐이다.
  전용 키(`HARNESS_STYLECHECK_CMD`)를 신설하면 막히지만, `check-harness-env.sh` 의
  `KNOWN_KEYS` 와 그 테스트까지 번지므로 이번 범위에서는 하지 않았다. **미조치로 공시한다.**
- 마크다운 80자 규칙이 새로 강제된다. 기존 하네스 문서 다수가 이를 넘지만 **일괄 재포맷은
  하지 않는다** — 변경 규약 위반이다. 손대는 파일에서만 적용한다.

## Alternatives considered

- **언어별 룰을 직접 쓴다** — 정본이 우리 안에 생기면 근거를 되짚을 곳이 없고, 유지보수를
  우리가 진다. 외부 공개 정본을 빌리는 값이 자율성보다 크다.
- **URL 만 적고 사본을 안 둔다** — 네트워크 없거나 fetch 실패 시 "기억으로 쓰기"로
  퇴화한다. 정확히 이 결정이 없애려던 실패 양상이다.
- **전용 Stop 훅을 만든다** — 훅 아홉 개는 회귀 테스트를 지고 있다. 기존 게이트에 얹는
  쪽이 표면적이 작고, 대가는 위에 공시한 슬롯 공유 하나다.
