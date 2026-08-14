#!/usr/bin/env bash
# publish-receipt-gate.cases.sh — 외부 발행 게이트의 판정 **계약 표**. 이 파일이 정본이다.
#
# 실행 파일이 아니라 publish-receipt-gate.test.sh 가 source 하는 조각이다. 러너·픽스처·
# assert 헬퍼는 전부 거기 있고 여기에는 계약 표만 둔다.
#
# **케이스 개수·ID 범위: p01~p83 (EXPECTED_CASES=83, 파일 끝에서 러너가 강제).**
# 계획 rev5 는 55를 참고값으로 적었고, 승인 조건(정정판 v2)이 요구한 추가분
# (영수증 스키마 위반 2건 · min_tier1+tier2 무승인 · WAL 직전 재검사 · tier 타입 3종 ·
# 영수증 내용↔파일명 일치 2종 · 다중 승인 결정성 · claim 후 재파싱 · 발급기/승인기 왕복)
# 을 얹어 이 파일에서 최종 확정했다. 번호는 고정이다 — 새 케이스는 **뒤에만** 붙인다.
#
# 여기서 쓰는 것(정의는 러너 쪽): new_project · new_dir · payload · digest_of ·
# identity_of · write_receipt · make_review · write_approval · run_gate · run_script ·
# run_static · fixture_broken · want_* · ok · TOK_* · T_* · HOOK · SETTINGS · IS_ROOT
#
# ── 변이 ↔ 적색 케이스 대응표 (변이 하네스: _workspace/mutate-publish-gate.sh) ──
# 각 변이는 아래 케이스 중 **하나 이상**을 빨갛게 만든다. 못 만드는 방어는 테스트가
# 아니라 문장으로만 존재하는 것이다(측정 결과: 29종 전건 적색, 2026-08-15).
# **주의**: 하네스가 재는 것은 "러너 전체가 빨개졌는가"다 — 아래 케이스 ID 는 설계상의
# 대응이고, 기계가 ID 단위로 확인하지는 않는다.
#   m01 탈출구 검사 삭제                       → p03 p04
#   m02 최상위 tool_name 중복 허용             → p40
#   m03 tool_name 판독 실패를 통과로           → p41
#   m04 registry 부재를 통과로                 → p32
#   m05 registry 중복 행 허용                  → p33
#   m06 registry 칸 수 검사를 채워넣기로       → p34
#   m07 미등재 도구도 등재로 취급(순서 역전)   → p02 p39
#   m08 엄격 파싱 → 관대 파싱                  → p37 p38
#   m09 digest 실패를 통과로                   → p43
#   m10 Artifact 재해시 생략                   → p42
#   m11 면제 플래그 선기록 삭제                → p31
#   m12 면제를 waivable 무시하고 허용          → p28
#   m13 면제 프리픽스를 부분 일치로            → p29
#   m14 replay 검사 삭제                       → p23
#   m15 active 2개를 하나로 골라 통과          → p10
#   m16 드리프트 진단 삭제                     → p45
#   m17 정체성 대조 삭제                       → p44
#   m18 영수증 미지 필드 허용                  → p57
#   m19 tier 타입 검사 완화(bool 통과)         → p53
#   m20 min_tier 대조 삭제                     → p09
#   m21 3튜플 대조 삭제                        → p14 p15 p16
#   m22 approval_required 에서 replay 항 제거  → p23 p24
#   m23 승인 선택 순서 뒤집기                  → p22
#   m24 감사 선기록 실패를 무시               → p48
#   m25 WAL 직전 used 재검사 삭제              → p26
#   m26 claim 후 used 사본 재대조 삭제         → p51
#   m27 wedged 판정 삭제                       → p46
#   m28 영수증 내용↔파일명 대조 삭제           → p58
#   m29 영수증 도구명 대조 삭제                → p59
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

# 러너를 거치지 않고 직접 돌리면 헬퍼가 하나도 없어 전 케이스가 조용히 무판정이 된다.
if [ -z "${TOK_NO_RECEIPT-}" ]; then
  echo "✗ 이 파일은 단독 실행용이 아닙니다. ./tests/publish-receipt-gate.test.sh 를 실행하세요" >&2
  exit 1
fi

# marker_line <마커> — 훅 본문의 `# [계약순서] <마커>` 줄 번호. 없으면 빈 문자열.
# 순서 계약 중 **실행 중 재현이 불가능한 것**(다른 프로세스가 그 사이에 끼어드는 경우)만
# 이 정적 검사로 붙든다. 재현 가능한 것은 전부 동적 케이스다.
marker_line() {
  grep -n "^# \[계약순서\] $1\$" "$HOOK" 2>/dev/null | head -1 | cut -d: -f1
}

# --- A. 통과·탈출구 -------------------------------------------------------

case_p01() { # 해피패스 — 유효 영수증은 통과하고 **소비된다**(active→used). 감사 플래그의
             # 기록값은 안정 경로 used/<digest>.<nonce> 다(감사자가 그 파일을 찾는다).
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  run_gate "$p" "$pay"
  want_rc 0
  want_no_err
  want_file "$p/_workspace/.receipts/used/$d.n1"
  want_no_file "$p/_workspace/.receipts/active/$d.n1"
  want_flag "used/$d.n1"
  ok 'p01 유효 영수증 → 통과 + 원자 소비 + 감사 플래그'
}

case_p02() { # 미등재 도구는 이 게이트의 대상이 아니다 — 광역 매처에 걸려도 무판정 통과.
             # 흔적도 남기지 않는다(남기면 발행과 무관한 호출이 감사 대상이 된다).
  local p pay
  p="$(new_project)"
  pay="$(payload "$T_UNKNOWN" '{"jql":"project=X"}')"
  run_gate "$p" "$pay"
  want_rc 0
  want_no_err
  want_no_flag_file
  ok 'p02 미등재 도구 → 무판정 통과'
}

case_p03() { # 표준 탈출구(개별). 기본은 켜짐이고 끄는 방법은 다른 훅과 같은 표기다.
  local p pay
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  run_gate "$p" "$pay" "ECC_DISABLED_HOOKS=$TOK_ESCAPE"
  want_rc 0
  want_no_err
  ok 'p03 ECC_DISABLED_HOOKS 탈출구 → 통과'
}

case_p04() { # 전체 탈출구.
  local p pay
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  run_gate "$p" "$pay" 'HARNESS_HOOKS=off'
  want_rc 0
  want_no_err
  ok 'p04 HARNESS_HOOKS=off → 통과'
}

case_p05() { # tier 상향은 막지 않는다 — min_tier 는 **하한**이다. 대신 tier2 영수증이므로
             # 승인이 필요하다(승인 요구는 registry 가 아니라 **영수증 tier**가 정한다).
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1
  write_approval "$p" "$d" a1
  run_gate "$p" "$pay"
  want_rc 0
  want_file "$p/_workspace/.receipts/used/$d.n1"
  want_file "$p/_workspace/.receipts/approval-used/a1"
  ok 'p05 min_tier=1 도구에 tier2 영수증+승인 → 통과'
}

# --- B. 무영수증·불일치 ---------------------------------------------------

case_p06() { # 이 게이트의 존재 이유 — 리뷰 없이 그냥 발행하는 경로를 막는다.
  local p pay
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_NO_RECEIPT"
  want_err "$TOK_BLOCK"
  ok 'p06 무영수증 → deny'
}

case_p07() { # 리뷰한 내용과 **다른 내용**을 발행하려는 경로. digest 가 갈리므로 무영수증과
             # 같은 판정으로 떨어진다 — 그게 맞다(그 payload 를 리뷰한 적이 없다).
  local p pay other d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  other="$(payload "$T_CREATE" '{"summary":"기습 수정"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  run_gate "$p" "$other"
  want_rc 2
  want_err "$TOK_NO_RECEIPT"
  want_file "$p/_workspace/.receipts/active/$d.n1"
  ok 'p07 payload 변조 → deny (영수증은 원본용으로 남는다)'
}

case_p08() { # 같은 입력 모양의 **다른 도구**에 영수증 재사용 불가 (digest 에 도구명 결합).
  local p pay other d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  other="$(payload "$T_TRANSITION" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  run_gate "$p" "$other"
  want_rc 2
  want_err "$TOK_NO_RECEIPT"
  ok 'p08 같은 입력·다른 도구 → deny'
}

case_p09() { # registry 가 강제하는 최소 등급. 기계로 판별 가능한 고위험 도구는 리뷰 규약의
             # 자율 판단에 맡기지 않는다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1","to":"Done"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_TRANSITION"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_MIN_TIER"
  ok 'p09 min_tier=2 도구에 tier1 영수증 → deny'
}

case_p10() { # 같은 digest 영수증이 둘이면 **어느 것을 소비할지 알 수 없다.** 하나를 골라
             # 통과시키면 나머지가 재사용 가능한 잔여물로 남는다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n2
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_DUP_ACTIVE"
  want_count "$p/_workspace/.receipts/active" 2
  ok 'p10 같은 digest active 2개 → deny (둘 다 잔존)'
}

case_p11() { # 영수증이 JSON 이 아니면 판독 불가 — 조용히 통과시키지 않는다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  printf '{깨진 JSON' > "$p/_workspace/.receipts/active/$d.n1"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p11 영수증 JSON 파싱 실패 → deny'
}

case_p12() { # schema_version 이 다르면 그 영수증의 의미를 이 훅이 모른다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_CREATE" '' 'rec["schema_version"] = 2'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p12 schema_version 불일치 → deny'
}

# --- C. 리뷰 산출물 3튜플 -------------------------------------------------

case_p13() { # 영수증이 가리키는 리뷰 산출물이 **실재**해야 한다. 없으면 리뷰의 증거가 없다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  write_receipt "$p" "$d" 1 '_workspace/없는리뷰.md' n1
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_TUPLE"
  ok 'p13 리뷰 산출물 파일 부재 → deny'
}

case_p14() { # 파일은 있는데 3튜플 줄이 없다 = 이 발행을 리뷰했다는 표명이 없다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  mkdir -p "$p/_workspace"
  printf '# 리뷰했습니다(라고만 적혀 있다)\n' > "$p/_workspace/review.md"
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_TUPLE"
  ok 'p14 리뷰 산출물에 3튜플 부재 → deny'
}

case_p15() { # tier 결합 — 리뷰어가 tier2 라고 판정했는데 영수증이 tier1 이면 등급 위조다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 2
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_TUPLE"
  ok 'p15 3튜플 tier 불일치 → deny'
}

case_p16() { # 다른 발행을 리뷰한 산출물을 재사용하는 경로.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" \
    '0000000000000000000000000000000000000000000000000000000000000000' 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_TUPLE"
  ok 'p16 3튜플 digest 불일치 → deny'
}

# --- D. tier2 승인 --------------------------------------------------------

case_p17() { # 승인 파일이 없으면 통과 불가. **영수증은 소비되지 않는다** — 소비했다가
             # 승인에서 막히면 재승인 때 쓸 영수증이 사라진다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1 "$T_TRANSITION"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_APPROVAL"
  want_file "$p/_workspace/.receipts/active/$d.n1"
  ok 'p17 tier2 + 승인 없음 → deny (영수증 잔존)'
}

case_p18() { # digest 가 일치하는 승인은 통과시키고 **함께 소비**한다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1 "$T_TRANSITION"
  write_approval "$p" "$d" a1
  run_gate "$p" "$pay"
  want_rc 0
  want_file "$p/_workspace/.receipts/approval-used/a1"
  want_no_file "$p/_workspace/.receipts/approval-active/a1"
  ok 'p18 tier2 + 일치 승인 → 통과 + 승인 소비'
}

case_p19() { # 다른 발행에 대한 승인은 이 발행을 통과시키지 못한다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1 "$T_TRANSITION"
  write_approval "$p" '1111111111111111111111111111111111111111111111111111111111111111' a1
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_APPROVAL"
  want_file "$p/_workspace/.receipts/approval-active/a1"
  ok 'p19 타 digest 승인만 존재 → deny (그 승인은 소비 안 됨)'
}

case_p20() { # 소비된 승인은 approval-used 에 있다. **거기 있는 것은 다시 쓰이지 않는다** —
             # 훅은 approval-active 만 본다. 같은 digest 재발행은 새 승인을 요구한다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1 "$T_TRANSITION"
  python3 -c '
import json, sys
p, d = sys.argv[1:3]
with open(p + "/_workspace/.receipts/approval-used/a1", "w") as fh:
    json.dump({"digest": d, "nonce": "a1", "issued_at": "2026-08-14T00:00:00Z"}, fh)
' "$p" "$d"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_APPROVAL"
  ok 'p20 소비된 승인(approval-used)만 존재 → deny'
}

case_p21() { # 새 nonce 로 재승인하면 통과한다 — 승인은 사람이 다시 하는 행위다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1 "$T_TRANSITION"
  python3 -c '
import json, sys
p, d = sys.argv[1:3]
with open(p + "/_workspace/.receipts/approval-used/a1", "w") as fh:
    json.dump({"digest": d, "nonce": "a1", "issued_at": "2026-08-14T00:00:00Z"}, fh)
' "$p" "$d"
  write_approval "$p" "$d" a2
  run_gate "$p" "$pay"
  want_rc 0
  want_file "$p/_workspace/.receipts/approval-used/a2"
  ok 'p21 새 nonce 재승인 → 통과'
}

case_p22() { # 승인이 여러 개여도 **결정적으로** 하나를 고른다: 파일명 사전순 첫 개.
             # 비결정적으로 고르면 어느 승인이 소비됐는지 감사자가 재현할 수 없다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1 "$T_TRANSITION"
  write_approval "$p" "$d" b-second
  write_approval "$p" "$d" a-first
  run_gate "$p" "$pay"
  want_rc 0
  want_file "$p/_workspace/.receipts/approval-used/a-first"
  want_file "$p/_workspace/.receipts/approval-active/b-second"
  ok 'p22 승인 2개 → 파일명 사전순 첫 개만 소비'
}

# --- E. 재발행(replay) ----------------------------------------------------

case_p23() { # **재발행은 재승인이다.** 같은 digest 가 이미 소비됐으면(발행이 이미 일어났으면)
             # tier1 이어도 승인을 요구한다. "실패했다"는 주장만으로는 다시 못 보낸다 —
             # 훅은 그 주장을 검증할 수 없기 때문이다(retry token 은 이번 범위 밖).
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  printf '{}' > "$p/_workspace/.receipts/used/$d.n0"
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_APPROVAL"
  want_file "$p/_workspace/.receipts/active/$d.n1"
  ok 'p23 used 존재 + tier1 재발행 + 승인 없음 → deny'
}

case_p24() { # 재승인하면 재발행이 통과한다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  printf '{}' > "$p/_workspace/.receipts/used/$d.n0"
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  write_approval "$p" "$d" a1
  run_gate "$p" "$pay"
  want_rc 0
  want_file "$p/_workspace/.receipts/used/$d.n1"
  want_file "$p/_workspace/.receipts/approval-used/a1"
  ok 'p24 used 존재 + tier1 재발행 + 승인 → 통과'
}

case_p25() { # 감사 연계 — tier1 **재발행**도 승인을 소비하므로 선기록(WAL)에 승인 nonce 가
             # 함께 남아야 한다. 안 남으면 감사자가 "이 발행이 어느 승인으로 통과했는지"를
             # 재구성할 수 없다(감사자 계약 ③).
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  printf '{}' > "$p/_workspace/.receipts/used/$d.n0"
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  write_approval "$p" "$d" a1
  run_gate "$p" "$pay"
  want_rc 0
  want_flag "publish-intent/$d.n1 approval/a1"
  ok 'p25 tier1 재발행의 감사 선기록에 승인 nonce 연계'
}

case_p26() { # **정적 계약** — WAL 선기록 직전에 used/<digest> 를 다시 본다.
             # 승인 선택과 선기록 사이에 다른 프로세스가 같은 digest 를 소비하면 replay 가
             # 새로 참이 되는데, 그 끼어듦은 이 러너 안에서 재현할 수 없다(다른 프로세스의
             # 스케줄을 잡을 방법이 없다). 그래서 "재검사가 그 자리에 있다"를 붙든다.
             # 재검사가 replay 를 새로 참으로 만들면 **deny** 다(재진입 아님 — 승인 절차를
             # 안내한다. 오케스트레이터 확정 2026-08-14).
  run_static 'WAL 직전 used 재검사' '
    a="$(marker_line WAL-RECHECK)"; b="$(marker_line WAL-WRITE)"
    if [ -z "$a" ]; then printf "훅에 WAL-RECHECK 마커가 없다 (used 재검사가 사라졌다)"
    elif [ -z "$b" ]; then printf "훅에 WAL-WRITE 마커가 없다"
    elif [ "$a" -ge "$b" ]; then printf "재검사(%s)가 선기록(%s)보다 뒤에 있다" "$a" "$b"
    fi'
  ok 'p26 WAL 직전 used 재검사가 선기록보다 앞이다 (정적)'
}

# --- F. [비판정] 면제 -----------------------------------------------------

case_p27() { # 면제도 **무흔적 통과가 아니다**: 플래그 + waived.log 둘 다 남는다.
             # 기록값은 waived/<digest> 형태로 편집 기록과 모양이 구분된다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_COMMENT" '{"body":"[비판정] 오타만 고칩니다"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  run_gate "$p" "$pay"
  want_rc 0
  want_flag "waived/$d"
  want_grep "$p/_workspace/.receipts/waived.log" "$d"
  ok 'p27 waivable 도구 + [비판정] 프리픽스 → 통과 + 흔적 2종'
}

case_p28() { # 면제 대상은 **닫힌 목록**이다. 상태를 바꾸는 발행은 프리픽스로 못 빠져나간다.
  local p pay
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"body":"[비판정] 그냥 전이합니다"}')"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_NO_RECEIPT"
  want_no_file "$p/_workspace/.receipts/waived.log"
  ok 'p28 waivable=no 도구의 [비판정] → 면제 불가 deny'
}

case_p29() { # **본문 시작 한정.** 중간에 넣어도 되면 아무 본문에나 붙여 통과할 수 있다.
  local p pay
  p="$(new_project)"
  pay="$(payload "$T_COMMENT" '{"body":"검토 결과입니다 [비판정] 아래 참조"}')"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_NO_RECEIPT"
  ok 'p29 [비판정] 이 본문 중간 → 면제 안 됨 deny'
}

case_p30() { # 순서 계약 — 면제는 replay 검사보다 **앞**이다(비판정은 판정 대상이 아니므로
             # 재발행 개념이 성립하지 않는다). 뒤로 옮기면 코멘트 정정이 승인을 요구하게 된다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_COMMENT" '{"body":"[비판정] 같은 코멘트를 또 답니다"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  printf '{}' > "$p/_workspace/.receipts/used/$d.n0"
  run_gate "$p" "$pay"
  want_rc 0
  want_flag "waived/$d"
  ok 'p30 면제는 replay 검사보다 앞이다 (used 있어도 통과)'
}

case_p31() { # 면제의 기록 순서: **플래그 먼저, 로그 나중.** 로그가 실패하면 deny 인데,
             # 이때 로그에는 아무것도 안 남고 **플래그만 남는다** — 그 플래그가 "면제를
             # 시도했다"는 흔적이다(감사자 계약 ⑥). 순서를 뒤집으면 로그만 남고 흔적이
             # 사라지거나, 실패한 시도가 흔적 없이 증발한다.
  local p pay d
  if [ "$IS_ROOT" -eq 1 ]; then
    fixture_broken 'root 로 실행 중 — 읽기전용 디렉터리 픽스처가 성립하지 않는다'
    ok 'p31 면제 로그 실패 → deny + 플래그 잔존 + 로그 무잔재'
    return 0
  fi
  p="$(new_project)"
  pay="$(payload "$T_COMMENT" '{"body":"[비판정] 오타"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  chmod 500 "$p/_workspace/.receipts"
  run_gate "$p" "$pay"
  chmod 700 "$p/_workspace/.receipts"
  want_rc 2
  want_err "$TOK_WAIVE"
  want_flag "waived/$d"
  want_no_file "$p/_workspace/.receipts/waived.log"
  ok 'p31 면제 로그 실패 → deny + 플래그 잔존 + 로그 무잔재'
}

# --- G. registry 무결성 ---------------------------------------------------

case_p32() { # 목록이 없으면 **어느 도구가 대상인지 모른다.** 모르는 상태의 통과는 곧
             # 게이트 소멸이라 fail-closed 다. 이 시점엔 digest 도 없으므로 전용 문구를 쓴다.
             # 대신 표준 탈출구 표기를 안내에 싣는다(막힌 채 방법을 모르는 상태를 안 만든다).
  local p pay
  p="$(new_project)"
  rm -f "$p/.claude/harness/publish-registry.txt"
  pay="$(payload "$T_UNKNOWN" '{"jql":"x"}')"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_REGISTRY"
  want_err "$TOK_ESCAPE"
  ok 'p32 registry 부재 → 전용 문구 deny + 탈출구 안내'
}

case_p33() { # 같은 도구가 두 행이면 어느 행이 이기는지 모른다 — min_tier 가 갈릴 수 있다.
  local p pay
  p="$(new_project)"
  printf '%s\t1\tno\t-\t-\n' "$T_CREATE" >> "$p/.claude/harness/publish-registry.txt"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_REGISTRY"
  ok 'p33 registry 중복 행 → deny'
}

case_p34() { # 칸 수가 다르면 열 의미가 통째로 밀린다.
  local p pay
  p="$(new_project)"
  printf 'synthetic__publish__extra\t1\tno\n' >> "$p/.claude/harness/publish-registry.txt"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_REGISTRY"
  ok 'p34 registry 칸 수 오류 → deny'
}

case_p35() { # waivable=yes 인데 본문 필드를 모르면 면제 판정 자체가 불가능하다 —
             # 그 상태를 관용하면 "면제 대상인데 면제가 안 되는" 조용한 어긋남이 된다.
  local p pay
  p="$(new_project)"
  printf 'synthetic__publish__badwaive\t1\tyes\t-\t-\n' >> "$p/.claude/harness/publish-registry.txt"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_REGISTRY"
  ok 'p35 waivable=yes + body_field 부재 → registry 형식 오류 deny'
}

# **뒷조각이 따로 있다**: p36~p66 은 publish-receipt-gate.cases-2.sh 에 있다(파일 크기).
# 크기의 정본(EXPECTED_CASES·CASES)은 이 파일 하나뿐이고, 러너가 둘 다 읽는다.

# --- 계약 표의 크기 -------------------------------------------------------
EXPECTED_CASES=83

CASES='case_p01 case_p02 case_p03 case_p04 case_p05 case_p06 case_p07 case_p08 case_p09 case_p10
       case_p11 case_p12 case_p13 case_p14 case_p15 case_p16 case_p17 case_p18 case_p19 case_p20
       case_p21 case_p22 case_p23 case_p24 case_p25 case_p26 case_p27 case_p28 case_p29 case_p30
       case_p31 case_p32 case_p33 case_p34 case_p35 case_p36 case_p37 case_p38 case_p39 case_p40
       case_p41 case_p42 case_p43 case_p44 case_p45 case_p46 case_p47 case_p48 case_p49 case_p50
       case_p51 case_p52 case_p53 case_p54 case_p55 case_p56 case_p57 case_p58 case_p59 case_p60
       case_p61 case_p62 case_p63 case_p64 case_p65 case_p66 case_p67 case_p68 case_p69
       case_p70 case_p71 case_p72 case_p73 case_p74 case_p75 case_p76 case_p77 case_p78
       case_p79 case_p80 case_p81 case_p82 case_p83'
