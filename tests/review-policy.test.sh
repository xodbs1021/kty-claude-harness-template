#!/usr/bin/env bash
#
# review-policy.test.sh — 리뷰 횟수 정책(ADR-0027)의 의미 회귀 테스트.
#
# 정책: 코드 검수(Phase 3)는 커밋마다 Claude+Codex 듀얼 1라운드로 닫고, PR
# 전체는 PR 점검(Phase 4)에서만 Claude+Codex 듀얼 무지적 3라운드로 닫는다.
#
# 이 시험이 막는 실패는 하나다 — 옛 규칙(Phase 3 끝에서도 PR 전체로 무지적
# 3회 · 상한 5회)이 활성 문서로 돌아와 같은 PR 을 두 번 3라운드씩 도는 것.
# 문구 하나가 아니라 부류를 본다. Phase 3 절에 무지적 · 상한 5 · 종결 라운드가
# 나오거나, 어느 문장이든 "Phase 3" 과 무지적 3회 · 상한 5 가 함께 나오면
# 빨개진다.
#
# 역사는 검사하지 않는다. ADR 본문과 SKILL.md 의 "**왜 (…)**" 문단 · "왜 …"
# 제목 절은 옛 규칙을 인용해야 하는 자리다. 변이 케이스가 이 경계를 양쪽에서
# 잰다 — 활성 절에 심으면 빨개지고, 역사 자리에 심으면 초록 그대로다.
#
# 왜 set -e 가 없나: 위반 수를 rc 로 받는 검사라 -e 는 러너 자신을 죽인다.
# 셸 이식성: macOS 기본 bash 는 3.2 다.
#
# 사용법: ./tests/review-policy.test.sh

set -uo pipefail

TEST_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "${TEST_DIR}/.." && pwd -P)"
readonly TEST_DIR REPO_ROOT

readonly SKILL_REL='template/.claude/skills/harness-orchestrator/SKILL.md'
readonly AUTHOR_REL='template/.claude/agents/pr-author.md'
readonly REVIEWER_REL='template/.claude/agents/pr-reviewer.md'
readonly ADR_DIR_REL='docs/decisions'
readonly ADR20_REL="${ADR_DIR_REL}/2026-08-01-dual-review-rule.md"
readonly ADR25_REL="${ADR_DIR_REL}/2026-09-29-review-unit-per-pr.md"

# 활성 절의 제목 머리. 정책의 주소이므로 바뀌면 이 시험도 함께 고친다.
readonly H_GATES='### 종결 기준·라운드 규약'
readonly H_P3_RULE='#### Phase 3 (코드 검수) — '
readonly H_P4_RULE='#### Phase 4 (PR 점검) — '
readonly H_UNIT='#### 적용 단위'
readonly H_REPORT='#### 라운드 보고'
readonly H_P3_PIPE='## Phase 3: '
readonly H_P4_PIPE='## Phase 4: '

# 옛 Phase 3 삼중 규칙의 원문(ADR-0025 시절 SKILL.md 그대로). 변이가 다시 심는다.
# 백틱은 마크다운 원문이라 펼치지 않는다.
# shellcheck disable=SC2016
readonly OLD_GATES='**게이트마다 종결 조건이 다르다.** Phase 2(계획·설계)는 **`[구조]` 지적 0** 으로 닫고, Phase 3(코드 검수)·Phase 4(PR 점검)는 종전대로 **무지적 3라운드**로 닫는다.'
readonly OLD_CLOSING='- **종결 = 무지적 라운드 3회(연속 불요) ∧ 축 체크리스트 전부 커버.**'
readonly OLD_CAP='**Phase 3·4 의 라운드가 5회를 넘으면 kty 에게 회부한다** — Phase 2 의 상한은 위 전면 라운드 3회이고, 이 5회는 Phase 2 로 내려오지 않는다.'
readonly OLD_PIPE='모든 커밋이 끝나면 기준 브랜치를 동기화하고 PR 전체를 입력으로 종결 라운드(무지적 3회 + 축 체크리스트)를 돈 뒤 Phase 4 로 간다.'
readonly OLD_SINGLE='- **커밋이 하나뿐인 PR** 은 커밋별 라운드를 따로 열지 않는다 — 첫 종결 라운드가 그것을 겸하고, PR 전체의 무지적 3회로 닫는다.'
readonly OLD_PLAIN='- Phase 3 은 PR 전체 차분으로 무지적 3회를 채운 뒤 Phase 4 로 간다.'
# 같은 옛 규칙을 80자 감싸기로 두 줄에 나눈 꼴(awk -v 가 \n 을 줄바꿈으로 편다).
readonly OLD_WRAPPED='- 그 뒤 Phase 3 은 PR 전체 차분으로\n  무지적 3회를 채우고 Phase 4 로 간다.'
# shellcheck disable=SC2016
readonly OLD_AUTHOR='입력은 종결 라운드의 `phase3-review[-rN].md` 하나다.'

TMPROOT="$(mktemp -d)" || exit 1
if [[ -z "${TMPROOT}" || ! -d "${TMPROOT}" ]]; then
  echo "✗ 임시 디렉토리를 만들지 못했습니다" >&2
  exit 1
fi
readonly TMPROOT
trap 'rm -rf "${TMPROOT}"' EXIT

pass=0
fail=0
violations=0

#######################################
# 케이스 결과 한 줄을 찍고 집계한다.
# Globals:
#   pass, fail
# Arguments:
#   케이스 이름, 실패 사유(없거나 비면 통과)
#######################################
report() {
  if [[ -z "${2:-}" ]]; then
    pass=$((pass + 1))
    printf '  ✓ %s\n' "$1"
  else
    fail=$((fail + 1))
    printf '  ✗ %s — %s\n' "$1" "$2"
  fi
}

#######################################
# 마크다운에서 활성 문구만 낸다. 코드 펜스, "왜 …" 제목 절, "**왜 " 로 여는
# 문단은 역사라 뺀다. 제목 머리를 주면 그 절(같거나 얕은 제목 전까지)만 낸다.
# Arguments:
#   파일, 제목 머리(선택 — 비우면 파일 전체)
# Outputs:
#   활성 줄을 stdout 으로
#######################################
active_text() {
  awk -v want="${2:-}" '
    BEGIN { on = (want == "") }
    /^```/ { fence = !fence; next }
    fence { next }
    /^#+ / {
      lvl = match($0, /[^#]/) - 1
      if (hist && lvl <= hist_lvl) hist = 0
      if (want != "" && on && lvl <= on_lvl) on = 0
      if (want != "" && !on && index($0, want) == 1) { on = 1; on_lvl = lvl }
      if (!hist && match($0, /^#+ 왜 /)) { hist = 1; hist_lvl = lvl }
      para = 0
      if (on && !hist) print
      next
    }
    !on || hist { next }
    /^[[:space:]]*$/ { para = 0; print ""; next }
    /^\*\*왜 / { para = 1 }
    para { next }
    { print }
  ' "$1"
}

#######################################
# 80자로 감싼 줄을 문단·목록 항목 단위로 이은 뒤 문장마다 한 줄로 낸다.
# 감싼 자리에서 끊긴 문장도 한 문장으로 검사하려는 것이다.
# Outputs:
#   stdin 을 문장 단위 줄로 stdout 에
#######################################
split_sentences() {
  awk '
    function flush() {
      if (buf != "") { gsub(/\. /, ".\n", buf); print buf; buf = "" }
    }
    /^[[:space:]]*$/ { flush(); next }
    /^#/ { flush(); print; next }
    /^\|/ || /^[[:space:]]*([-*]|[0-9]+\.)[[:space:]]/ { flush() }
    {
      sub(/^[[:space:]]+/, "")
      buf = (buf == "") ? $0 : buf " " $0
    }
    END { flush() }
  '
}

#######################################
# ADR 머리의 Status 필드를 낸다. 80자로 감싸여 여러 줄일 수 있다.
# Arguments:
#   ADR 파일
# Outputs:
#   Status 필드 전체를 stdout 에
#######################################
adr_status() {
  awk '
    /^\*\*Status\*\*:/ { on = 1 }
    on && (/^[[:space:]]*$/ || /^\*\*Deciders\*\*/) { exit }
    on { print }
  ' "$1"
}

#######################################
# 위반 한 건을 기록한다.
# Globals:
#   violations
# Arguments:
#   위반 설명
#######################################
violate() {
  violations=$((violations + 1))
  printf '    위반: %s\n' "$1"
}

#######################################
# 글에 패턴이 없으면 위반이다. 글이 비면 절 자체가 없는 것이다.
# Arguments:
#   설명, 글, 확장 정규식
#######################################
need() {
  if [[ -z "$2" ]]; then
    violate "$1 — 절이 없다"
  elif ! grep -Eq -- "$3" <<< "$2"; then
    violate "$1 — /$3/ 없음"
  fi
}

#######################################
# 글에 패턴이 있으면 위반이다. 첫 걸린 줄을 함께 낸다.
# Arguments:
#   설명, 글, 확장 정규식
#######################################
deny() {
  local hit
  hit="$(grep -E -m1 -- "$3" <<< "$2")"
  if [[ -n "${hit}" ]]; then
    violate "$1 — ${hit:0:120}"
  fi
}

#######################################
# Phase 3 은 커밋 단위 1라운드로 닫히고 무지적 계수가 없어야 한다.
# Arguments:
#   SKILL.md 경로
#######################################
check_phase3() {
  local rule pipe skill_all
  rule="$(active_text "$1" "${H_P3_RULE}")"
  pipe="$(active_text "$1" "${H_P3_PIPE}")"
  skill_all="$(active_text "$1" | split_sentences)"

  need 'Phase 3 은 커밋마다' "${rule}" '커밋마다'
  need 'Phase 3 은 cc·cx 동시 1라운드' "${rule}" 'cc·cx 동시 1라운드'
  need 'Phase 3 종결은 C/H 0' "${rule}" 'CRITICAL/HIGH 0'
  need 'M/L 은 PR 로 이연 + 귀속' "${rule}" '이연.*귀속|귀속.*이연'
  need 'C/H 수정은 확인 패스' "${rule}" '확인 패스'
  need '확인 패스 한도 뒤 사용자 회부' "${rule}" '사용자에게 회부'
  need '싱글턴 교차 검증 유지' "${rule}" '싱글턴'

  local text
  for text in "${rule}" "${pipe}"; do
    deny 'Phase 3 절에 무지적 계수' "${text}" '무지적'
    deny 'Phase 3 절에 종결 라운드' "${text}" '종결 라운드'
    deny 'Phase 3 절에 상한 5' "${text}" '상한 ?5|5 ?회'
    deny 'Phase 3 절에 PR 전체 입력' "${text}" 'PR 전체를 입력'
  done

  deny '활성 문구에 종결 라운드' "${skill_all}" '종결 라운드'
  deny '활성 문구에 Phase 3·4 묶음' "${skill_all}" \
    'Phase 3·4|Phase 3 ?\(코드 검수\)·Phase 4'
  deny '한 문장에 Phase 3 과 무지적 3회·상한 5' \
    "$(grep -F 'Phase 3' <<< "${skill_all}")" \
    '무지적 ?(라운드 ?)?3|상한 ?5|5 ?회'
}

#######################################
# Phase 4 만 PR 전체 무지적 3라운드를 같은 입력 4종으로 돈다.
# Arguments:
#   SKILL.md 경로
#######################################
check_phase4() {
  local rule pipe report_text
  rule="$(active_text "$1" "${H_P4_RULE}")"
  pipe="$(active_text "$1" "${H_P4_PIPE}")"
  report_text="$(active_text "$1" "${H_REPORT}")"

  need 'Phase 4 무지적 3회' "${rule}" '무지적 라운드 3회'
  need 'Phase 4 연속 불요' "${rule}" '연속 불요'
  need 'Phase 4 전면 상한 5' "${rule}" '상한 5회'
  need 'Phase 4 입력: PR 전체 차분' "${rule}" 'PR 전체 차분'
  need 'Phase 4 입력: 현재 계획서' "${rule}" '현재 계획서'
  need 'Phase 4 입력: 차분 밖 운영 문서 목록' "${rule}" '운영 문서'
  need 'Phase 4 입력: 이연 목록' "${rule}" '이연 목록'
  need 'Phase 4 양쪽 같은 입력' "${rule}" '같은 입력'
  need 'Phase 4 마지막 M/L 확인 패스' "${rule}" '확인 패스'
  need 'Phase 4 축 체크리스트' "${rule}" '축 체크리스트'
  need 'Phase 4 파이프라인이 종결 규약을 가리킨다' "${pipe}" '무지적'
  need 'Phase 4 파이프라인 codex 동시' "${pipe}" 'codex'
  need '라운드 보고: Phase 4 무지적 계수' "${report_text}" \
    'Phase 4[^.]*무지적 계수'
}

#######################################
# 적용 단위: 커밋 하나여도 Phase 3 1라운드 뒤 Phase 4 3회, 여러 커밋은
# 커밋별 기록을 추가 리뷰 없이 통합 파일에 잇는다.
# Arguments:
#   SKILL.md 경로
#######################################
check_unit() {
  local unit gates
  unit="$(active_text "$1" "${H_UNIT}")"
  gates="$(active_text "$1" "${H_GATES}")"

  need '적용 단위: 커밋 하나뿐인 PR' "${unit}" '커밋이 하나뿐인 PR'
  need '적용 단위: 추가 리뷰 없이 통합' "${unit}" '추가 리뷰 없이'
  need '적용 단위: 통합 파일 phase3-review.md' "${unit}" 'phase3-review\.md'
  need '적용 단위: pr-author 전달' "${unit}" 'pr-author'
  need '종결 기준: Phase 4 만 무지적 3라운드' "${gates}" \
    'Phase 4[^.]*무지적 3라운드'
}

#######################################
# PR 단계 에이전트의 입력이 커밋별 기록을 잇고 종결 라운드를 말하지 않는다.
# Arguments:
#   저장소 뿌리
#######################################
check_agents() {
  local author reviewer
  author="$(active_text "$1/${AUTHOR_REL}")"
  reviewer="$(active_text "$1/${REVIEWER_REL}")"

  need 'pr-author 입력: 커밋별 기록' "${author}" '커밋별 기록'
  need 'pr-reviewer 대조: 커밋별 기록' "${reviewer}" '커밋별 기록'
  deny 'pr-author 에 종결 라운드' "${author}" '종결 라운드'
  deny 'pr-reviewer 에 종결 라운드' "${reviewer}" '종결 라운드'
}

#######################################
# 과거 결정은 본문을 두고 상태와 링크로 새 결정과 구별한다.
# Arguments:
#   저장소 뿌리
#######################################
check_adrs() {
  local status25 adr27='' f
  status25="$(adr_status "$1/${ADR25_REL}")"
  need 'ADR-0025 상태가 superseded' "${status25}" 'superseded'
  need 'ADR-0025 상태가 ADR-0027 링크' "${status25}" 'ADR-0027\]\('

  for f in "$1/${ADR_DIR_REL}"/*.md; do
    if head -n 1 "${f}" | grep -q '^# ADR-0027:'; then
      adr27="${f}"
    fi
  done
  if [[ -z "${adr27}" ]]; then
    violate 'ADR-0027 문서가 없다'
    return
  fi
  local related
  related="$(active_text "${adr27}" '## 관련')"
  need 'ADR-0027 관련: ADR-0025 인용' "${related}" 'ADR-0025'
  need 'ADR-0027 관련: ADR-0020 인용' "${related}" 'ADR-0020'
  need 'ADR-0020 후속 이력: ADR-0027' \
    "$(active_text "$1/${ADR20_REL}" '## 후속 이력')" 'ADR-0027'
}

#######################################
# 저장소 뿌리 하나에 정책 검사를 모두 돈다.
# Globals:
#   violations
# Arguments:
#   저장소 뿌리
# Outputs:
#   위반 목록을 stdout 에
# Returns:
#   0 위반 없음, 1 위반 있음
#######################################
check_policy() {
  local skill="$1/${SKILL_REL}"
  violations=0
  if [[ ! -f "${skill}" ]]; then
    violate "SKILL.md 없음: ${skill}"
    return 1
  fi
  check_phase3 "${skill}"
  check_phase4 "${skill}"
  check_unit "${skill}"
  check_agents "$1"
  check_adrs "$1"
  (( violations == 0 ))
}

#######################################
# 검사 대상 파일만 복사한 픽스처 뿌리를 만든다.
# Arguments:
#   없음
# Outputs:
#   픽스처 뿌리 경로
#######################################
new_fixture() {
  local d
  d="$(mktemp -d "${TMPROOT}/fx.XXXXXX")" || return 1
  mkdir -p "${d}/$(dirname "${SKILL_REL}")" "${d}/$(dirname "${AUTHOR_REL}")" \
    || return 1
  cp "${REPO_ROOT}/${SKILL_REL}" "${d}/${SKILL_REL}" || return 1
  cp "${REPO_ROOT}/${AUTHOR_REL}" "${d}/${AUTHOR_REL}" || return 1
  cp "${REPO_ROOT}/${REVIEWER_REL}" "${d}/${REVIEWER_REL}" || return 1
  mkdir -p "${d}/docs" && cp -R "${REPO_ROOT}/${ADR_DIR_REL}" "${d}/docs/" \
    || return 1
  printf '%s\n' "${d}"
}

#######################################
# 머리가 맞는 첫 줄 바로 뒤에 한 줄을 심는다.
# Arguments:
#   파일, 줄 머리, 심을 줄
# Returns:
#   0 심음, 1 머리를 못 찾음
#######################################
insert_after() {
  awk -v a="$2" -v t="$3" '
    { print }
    !done && index($0, a) == 1 { print t; done = 1 }
    END { exit !done }
  ' "$1" > "$1.new" && mv "$1.new" "$1"
}

#######################################
# 파일 끝에 한 줄을 붙인다.
# Arguments:
#   파일, 붙일 줄
#######################################
append_line() {
  printf '\n%s\n' "$2" >> "$1"
}

#######################################
# 파일 안의 글자열을 모두 바꾼다. 없으면 실패한다.
# Arguments:
#   파일, 찾을 글자열, 바꿀 글자열
#######################################
replace_all() {
  local body
  body="$(cat "$1")" || return 1
  [[ "${body}" == *"$2"* ]] || return 1
  printf '%s\n' "${body//"$2"/"$3"}" > "$1"
}

#######################################
# 픽스처에 변이 하나를 걸고 기대한 판정이 나오는지 잰다.
# Arguments:
#   케이스 이름, 기대(green|red), 변이 함수 이름, 변이 인자...
#######################################
mutation_case() {
  local name="$1" expect="$2" op="$3" d out
  shift 3
  if ! d="$(new_fixture)"; then
    report "${name}" '픽스처 실패'
    return
  fi
  if ! "${op}" "${d}/$1" "${@:2}"; then
    report "${name}" "변이를 걸지 못했다($1)"
    return
  fi
  out="$(check_policy "${d}")"
  local rc=$?
  if [[ "${expect}" == green && "${rc}" -eq 0 ]] \
      || [[ "${expect}" == red && "${rc}" -ne 0 ]]; then
    report "${name}"
  else
    report "${name}" "기대 ${expect}, rc=${rc}${out:+ — ${out}}"
  fi
}

main() {
  local out rc
  echo '리뷰 횟수 정책 의미 회귀 테스트 (ADR-0027)'

  out="$(check_policy "${REPO_ROOT}")"
  rc=$?
  report '현행 저장소가 정책을 지킨다' "$( ((rc == 0)) || printf '%s' "${out}")"

  mutation_case '픽스처 원본은 초록' green append_line "${ADR25_REL}" ''

  # 옛 Phase 3 삼중 규칙을 활성 자리에 되심으면 빨개져야 한다.
  mutation_case '변이: 종결 기준 머리에 옛 Phase 3·4 무지적 3라운드' red \
    insert_after "${SKILL_REL}" "${H_GATES}" "${OLD_GATES}"
  mutation_case '변이: Phase 3 절에 무지적 3회 종결' red \
    insert_after "${SKILL_REL}" "${H_P3_RULE}" "${OLD_CLOSING}"
  mutation_case '변이: 라운드 보고에 Phase 3·4 상한 5회' red \
    insert_after "${SKILL_REL}" "${H_REPORT}" "${OLD_CAP}"
  mutation_case '변이: Phase 3 파이프라인에 PR 전체 종결 라운드' red \
    insert_after "${SKILL_REL}" "${H_P3_PIPE}" "${OLD_PIPE}"
  mutation_case '변이: 적용 단위에 커밋 하나 PR 의 종결 라운드 겸함' red \
    insert_after "${SKILL_REL}" "${H_UNIT}" "${OLD_SINGLE}"
  mutation_case '변이: 종결 라운드 낱말 없이 Phase 3 무지적 3회' red \
    insert_after "${SKILL_REL}" "${H_UNIT}" "${OLD_PLAIN}"
  mutation_case '변이: 두 줄로 감싼 Phase 3 무지적 3회' red \
    insert_after "${SKILL_REL}" "${H_UNIT}" "${OLD_WRAPPED}"
  mutation_case '변이: pr-author 입력을 종결 라운드로 되돌림' red \
    insert_after "${AUTHOR_REL}" '## 입력/출력 프로토콜' "${OLD_AUTHOR}"
  mutation_case '변이: Phase 4 를 1회로 약화' red \
    replace_all "${SKILL_REL}" '무지적 라운드 3회' '무지적 라운드 1회'
  mutation_case '변이: Phase 4 연속 불요 삭제' red \
    replace_all "${SKILL_REL}" '연속 불요' '연속'
  mutation_case '변이: ADR-0025 상태를 accepted 로 되돌림' red \
    replace_all "${ADR25_REL}" 'superseded' 'accepted'

  # 역사 자리의 옛 문장은 오탐하지 않아야 한다.
  mutation_case '역사: ADR-0025 본문 끝의 옛 규칙은 초록' green \
    append_line "${ADR25_REL}" "${OLD_PIPE}"
  mutation_case '역사: ADR-0020 본문 끝의 옛 규칙은 초록' green \
    append_line "${ADR20_REL}" "${OLD_GATES}"
  mutation_case '역사: SKILL.md "**왜" 문단 안의 옛 규칙은 초록' green \
    insert_after "${SKILL_REL}" '**왜 (' "${OLD_PLAIN}"

  printf '\n통과 %d · 실패 %d\n' "${pass}" "${fail}"
  (( fail == 0 ))
}

main "$@"
