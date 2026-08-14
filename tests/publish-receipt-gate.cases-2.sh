#!/usr/bin/env bash
# publish-receipt-gate.cases-2.sh — 판정 계약 표의 **뒷조각** (p36~p66).
#
# 표가 한 파일에 다 들어가면 1000줄을 넘어 계획서와 대조하기 어려워지므로 갈랐다.
# 머리(케이스 개수·변이 대응표·EXPECTED_CASES·CASES 목록)는 앞조각
# publish-receipt-gate.cases.sh 에 있다 — **크기의 정본은 거기 하나뿐이다.**
# 러너가 앞조각 → 뒷조각 순서로 둘 다 읽는다.
#
# 셸 이식성: macOS 기본 bash 는 3.2 다. ${var,,}·mapfile·연관배열 금지.

if [ -z "${TOK_NO_RECEIPT-}" ]; then
  echo "✗ 이 파일은 단독 실행용이 아닙니다. ./tests/publish-receipt-gate.test.sh 를 실행하세요" >&2
  exit 1
fi

# --- H. payload 파싱 순서 -------------------------------------------------

case_p36() { # 등재 도구의 payload 는 엄격하게 읽는다. **JSON 자체가 깨진 경우는 여기까지
             # 오지 않는다** — 2단 최소 파싱에서 도구 이름을 못 읽어 먼저 막힌다(p41 계열).
             # 그래서 이 행은 "최소 파싱은 통과하는데 엄격 파싱에서 걸리는" 모양을 쓴다.
  local p
  p="$(new_project)"
  run_gate "$p" "{\"tool_name\":\"$T_CREATE\",\"tool_input\":\"객체가 아님\"}"
  want_rc 2
  want_err "$TOK_PAYLOAD"
  ok 'p36 등재 도구 + tool_input 형식 오류 → deny'
}

case_p37() { # 중복 키 — 훅이 본 값과 실제 발행될 값이 갈릴 수 있다.
  local p
  p="$(new_project)"
  run_gate "$p" "{\"tool_name\":\"$T_CREATE\",\"tool_input\":{\"summary\":\"a\",\"summary\":\"b\"}}"
  want_rc 2
  want_err "$TOK_PAYLOAD"
  ok 'p37 등재 도구 + tool_input 중복 키 → deny'
}

case_p38() { # 비정수 수 — 직렬화기마다 표기가 갈린다.
  local p
  p="$(new_project)"
  run_gate "$p" "{\"tool_name\":\"$T_CREATE\",\"tool_input\":{\"estimate\":1.5}}"
  want_rc 2
  want_err "$TOK_PAYLOAD"
  ok 'p38 등재 도구 + 비정수 수 → deny'
}

case_p39() { # **순서 증명.** 미등재 도구의 payload 는 엄격 파싱 대상이 아니다 — 최상위
             # tool_name 만 읽히면 통과한다. 순서가 뒤집히면 발행과 무관한 MCP 도구의
             # 정상 호출이 이 훅 때문에 막힌다(광역 매처라 폭발 반경이 MCP 전체다).
  local p
  p="$(new_project)"
  run_gate "$p" "{\"tool_name\":\"$T_UNKNOWN\",\"tool_input\":{\"a\":1.5,\"a\":2.5}}"
  want_rc 0
  want_no_err
  ok 'p39 미등재 도구 + 엄격 파싱 위반 payload → 통과 (순서 계약)'
}

case_p40() { # 최상위 tool_name 이 둘이면 파서마다 이기는 값이 달라, 훅이 본 도구와 실행될
             # 도구가 갈릴 수 있다. 갈리면 "미등재라 통과"가 그대로 우회로가 된다.
  local p
  p="$(new_project)"
  run_gate "$p" "{\"tool_name\":\"$T_UNKNOWN\",\"tool_name\":\"$T_CREATE\",\"tool_input\":{}}"
  want_rc 2
  want_err "$TOK_TOOLNAME"
  ok 'p40 최상위 tool_name 중복 → deny'
}

case_p41() { # 도구 이름을 못 읽으면 등재 여부를 판정할 수 없다 — 모르면 막는다.
  local p
  p="$(new_project)"
  run_gate "$p" '{"tool_input":{"summary":"a"}}'
  want_rc 2
  want_err "$TOK_TOOLNAME"
  ok 'p41 tool_name 부재 → deny'
}

# --- I. Artifact ----------------------------------------------------------

case_p42() { # 파일 **내용**이 digest 에 묶여 있다. 리뷰 뒤에 파일을 갈아치우면 통과 못 한다.
             # 보장은 여기까지다 — 재해시 뒤 업로드 전에 바뀌는 창은 잔존 위험으로 공시한다.
  local p pay d f
  p="$(new_project)"
  f="$p/_workspace/artifact.bin"
  mkdir -p "$p/_workspace"
  printf 'v1' > "$f"
  pay="$(payload "$T_ARTIFACT" "{\"path\":\"$f\"}")"
  digest_of "$p" "$pay" path; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_ARTIFACT" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_ARTIFACT"
  printf 'v2 몰래 교체' > "$f"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_NO_RECEIPT"
  ok 'p42 Artifact 파일 교체 → 재해시 불일치 deny'
}

case_p43() { # 파일이 없으면 digest 를 만들 수 없다. 빈 해시로 접으면 파일 없는 발행이 통과한다.
  local p pay
  p="$(new_project)"
  pay="$(payload "$T_ARTIFACT" "{\"path\":\"$p/_workspace/없는파일.bin\"}")"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_PAYLOAD"
  ok 'p43 Artifact 파일 부재 → deny'
}

# --- J. 직렬화 드리프트 ---------------------------------------------------

case_p44() { # 영수증을 만든 환경과 지금 환경의 직렬화기가 다르면 digest 가 갈렸을 수 있다.
             # **영구 무효가 아니라 현 환경에서 소비 불가**다 — 환경을 되돌리거나 발급만
             # 다시 하면 된다(digest 는 리뷰 내용에 묶여 있으므로 리뷰 재실행은 불요).
             # 그 복구 경로를 메시지가 안내해야 한다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_CREATE" 'publish-digest/1 python3/0.0.0'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_DRIFT"
  want_file "$p/_workspace/.receipts/active/$d.n1"
  ok 'p44 영수증 정체성 불일치 → 드리프트 deny + 복구 안내'
}

case_p45() { # digest 가 아예 안 맞아 0건일 때도, **정체성이 다른 영수증이 남아 있으면**
             # 원인이 "리뷰를 안 했다"가 아니라 "직렬화가 갈렸다"일 수 있다. 일반 무영수증
             # 문구로 접으면 사용자가 영영 원인을 못 찾는다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" '2222222222222222222222222222222222222222222222222222222222222222' \
    1 '_workspace/review.md' n9 "$T_CREATE" 'publish-digest/1 python3/0.0.0'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_DRIFT"
  ok 'p45 active 0건 + 정체성 다른 영수증 존재 → 드리프트 진단 deny'
}

# --- K. claim 원자성·경합·감사 --------------------------------------------

case_p46() { # wedged — ln 은 성공했는데 rm 이 실패한 상태(used 와 active 에 같은 이름이
             # 동시에 있다). 재claim 은 EEXIST 라 자동 복구가 안 되고, 발급기도 같은 digest
             # 재발급을 거부한다. 그래서 **수동 복구 안내**와 감사 표식이 필요하다.
             # 이 상태는 replay 이기도 하므로 승인이 필요하고, 그 승인은 여기서 소모된다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  printf '{}' > "$p/_workspace/.receipts/used/$d.n1"
  write_approval "$p" "$d" a1
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_WEDGED"
  want_file "$p/_workspace/.receipts/active/$d.n1"
  want_file "$p/_workspace/.receipts/used/$d.n1"
  want_flag "wedged/$d.n1"
  ok 'p46 wedged 상태 → deny + 잔존 단언 + 감사 표식'
}

case_p47() { # 승인을 소비한 뒤 영수증 claim 이 실패하면 **그 승인은 이미 소모됐다.**
             # 조용히 끝내면 사용자는 승인이 살아 있다고 믿고 다시 시도해 또 막힌다.
             # 메시지가 "재승인이 필요하다"고 말해야 한다(동시 경합은 희귀 — 공시).
  local p pay d
  if [ "$IS_ROOT" -eq 1 ]; then
    fixture_broken 'root 로 실행 중 — 읽기전용 디렉터리 픽스처가 성립하지 않는다'
    ok 'p47 승인 소비 후 영수증 claim 실패 → deny + 재승인 안내'
    return 0
  fi
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1 "$T_TRANSITION"
  write_approval "$p" "$d" a1
  chmod 500 "$p/_workspace/.receipts/used"
  run_gate "$p" "$pay"
  chmod 700 "$p/_workspace/.receipts/used"
  want_rc 2
  want_err "$TOK_CLAIM"
  want_err "$TOK_REAPPROVE"
  want_file "$p/_workspace/.receipts/approval-used/a1"
  ok 'p47 승인 소비 후 영수증 claim 실패 → deny + 재승인 안내'
}

case_p48() { # 감사 선기록(WAL)이 실패하면 **소비하지 않는다.** 후기록으로 옮기면 이 경우
             # 영수증이 이미 소진된 채 기록만 없어져, 감사자에게는 발행이 없었던 것으로 보인다.
  local p pay d
  if [ "$IS_ROOT" -eq 1 ]; then
    fixture_broken 'root 로 실행 중 — 읽기전용 디렉터리 픽스처가 성립하지 않는다'
    ok 'p48 감사 선기록 실패 → deny + 영수증 active 잔존'
    return 0
  fi
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  chmod 500 "$p/.claude"
  run_gate "$p" "$pay"
  chmod 700 "$p/.claude"
  want_rc 2
  want_err "$TOK_WAL"
  want_file "$p/_workspace/.receipts/active/$d.n1"
  want_no_file "$p/_workspace/.receipts/used/$d.n1"
  ok 'p48 감사 선기록 실패 → deny + 영수증 active 잔존'
}

case_p49() { # 동시 호출에서 **정확히 하나만** 통과해야 한다. 둘 다 통과하면 한 번 리뷰한
             # 발행이 두 번 나간다. ln 의 EEXIST 가 그 원자성의 근거다.
  local p pay d o1 o2 r1 r2 wins
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  DID_RUN=1
  ( printf '%s' "$pay" | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
      CLAUDE_PROJECT_DIR="$p" bash "$p/.claude/hooks/guard-publish-receipt.sh" \
      >/dev/null 2>&1; echo $? > "$p/rc1" ) &
  ( printf '%s' "$pay" | env -u HARNESS_HOOKS -u ECC_DISABLED_HOOKS \
      CLAUDE_PROJECT_DIR="$p" bash "$p/.claude/hooks/guard-publish-receipt.sh" \
      >/dev/null 2>&1; echo $? > "$p/rc2" ) &
  wait
  r1="$(cat "$p/rc1" 2>/dev/null)"; r2="$(cat "$p/rc2" 2>/dev/null)"
  wins=0
  [ "$r1" = '0' ] && wins=$((wins + 1))
  [ "$r2" = '0' ] && wins=$((wins + 1))
  [ "$wins" -eq 1 ] || WHY="통과한 호출이 ${wins}건 (기대 1건) — rc=[$r1,$r2]"
  PROJ="$p"
  want_count "$p/_workspace/.receipts/active" 0
  want_count "$p/_workspace/.receipts/used" 1
  ok 'p49 동시 claim → 정확히 1건만 통과'
}

case_p50() { # receipts 디렉터리 자체가 없으면 영수증도 없다 — 통과가 아니라 deny 다.
  local p pay
  p="$(new_project)"
  rm -rf "$p/_workspace/.receipts"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_NO_RECEIPT"
  ok 'p50 receipts 디렉터리 부재 → deny'
}

case_p51() { # **정적 계약** — claim 뒤 used/ 사본을 한 번 더 파싱해 digest·tier·정체성을
             # 재대조한다. claim 은 하드링크라 정상 경로에서는 같은 내용이지만, 그 전제가
             # 깨지는 경우(경로 조작·중간 교체)를 한 번 더 붙드는 자리다. 하드링크의 성질상
             # "사본만 달라진 상태"를 이 러너 안에서 만들 수 없어 정적으로 고정한다.
  run_static 'claim 후 used 사본 재파싱' '
    a="$(marker_line CLAIM)"; b="$(marker_line CLAIM-REPARSE)"
    if [ -z "$a" ]; then printf "훅에 CLAIM 마커가 없다"
    elif [ -z "$b" ]; then printf "훅에 CLAIM-REPARSE 마커가 없다 (재대조가 사라졌다)"
    elif [ "$b" -le "$a" ]; then printf "재대조(%s)가 claim(%s)보다 앞에 있다" "$b" "$a"
    fi'
  ok 'p51 claim 뒤 used 사본 재대조가 있다 (정적)'
}

# --- L. 영수증 스키마 세부 ------------------------------------------------

case_p52() { # 비ASCII·개행 본문의 정상 통과. 한국어 본문이 발행 payload 의 기본형이라
             # 여기서 깨지면 게이트가 일상적으로 오작동한다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_COMMENT" '{"body":"첫 줄\n둘째 줄 — 정정 안내"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_COMMENT" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_COMMENT"
  run_gate "$p" "$pay"
  want_rc 0
  want_file "$p/_workspace/.receipts/used/$d.n1"
  ok 'p52 비ASCII·개행 본문 → 정상 통과'
}

case_p53() { # tier 가 bool 이면 안 된다. 파이썬에서 True == 1 이라 범위 검사만으로는
             # `"tier": true` 가 tier1 로 통과한다 — 타입까지 봐야 막힌다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_CREATE" '' 'rec["tier"] = True'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p53 tier 가 bool → deny'
}

case_p54() { # 문자열 "1" 도 거부한다 — 관용하면 tier 비교가 문자열 비교로 미끄러진다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_CREATE" '' 'rec["tier"] = "1"'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p54 tier 가 문자열 → deny'
}

case_p55() { # 범위 밖 tier.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_CREATE" '' 'rec["tier"] = 3'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p55 tier 가 범위 밖 → deny'
}

case_p56() { # 필수 필드 누락 — 8필드 고정.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_CREATE" '' 'del rec["issued_at"]'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p56 영수증 필수 필드 누락 → deny'
}

case_p57() { # 미지 필드 — 관용하면 나중에 의미를 갖는 필드가 생겼을 때 옛 영수증이 그
             # 필드 없이 통과한다(그리고 그 통과는 아무 신호도 내지 않는다).
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_CREATE" '' 'rec["extra"] = "x"'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p57 영수증 미지 필드 → deny'
}

case_p58() { # 내용 ↔ 파일명 일치. nonce 가 다르면 claim 대상 경로와 검증한 내용이 어긋난다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_CREATE" '' 'rec["nonce"] = "other"'
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p58 영수증 nonce ≠ 파일명 → deny'
}

case_p59() { # 내용 ↔ 현재 요청 일치. 파일명은 digest 로 찾았으니 맞지만, 안에 적힌 도구가
             # 다르면 그 영수증은 다른 발행을 위한 것이다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1 "$T_TRANSITION"
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_SCHEMA"
  ok 'p59 영수증 tool_name ≠ 현재 요청 → deny'
}

case_p60() { # 승인 요구는 **영수증 tier**가 정한다(registry 의 min_tier 가 아니라).
             # min_tier=1 도구여도 영수증이 tier2 면 승인이 필요하다 — 리뷰어가 위험하다고
             # 판정한 발행을 도구 분류가 되돌리지 못한다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1
  run_gate "$p" "$pay"
  want_rc 2
  want_err "$TOK_APPROVAL"
  want_file "$p/_workspace/.receipts/active/$d.n1"
  ok 'p60 min_tier=1 + 영수증 tier2 + 승인 0건 → deny'
}

case_p61() { # 면제 로그는 감사자가 **패턴을 보는** 자료다. 도구명과 digest 가 남아야
             # "이 도구에 면제가 몰린다"를 알 수 있다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_COMMENT" '{"body":"[비판정] 링크만 고침"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  run_gate "$p" "$pay"
  want_rc 0
  want_grep "$p/_workspace/.receipts/waived.log" "$T_COMMENT"
  want_grep "$p/_workspace/.receipts/waived.log" "$d"
  ok 'p61 waived.log 에 도구명·digest 가 남는다'
}

# --- M. 발급기·승인기 왕복 -------------------------------------------------

case_p62() { # 발급기 no-clobber — 같은 digest 의 active 영수증이 있으면 발급을 거부한다.
             # 허용하면 active 가 2개가 되어 게이트가 통째로 deny 로 잠긴다(p10).
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  write_receipt "$p" "$d" 1 '_workspace/review.md' n1
  printf '%s' "$pay" > "$p/_workspace/payload.json"
  run_script "$p" publish-issue-receipt.sh --payload "$p/_workspace/payload.json" \
    --tier 1 --review '_workspace/review.md'
  [ "$RC" -eq 0 ] && WHY="발급기가 중복 발급을 허용했다 (rc=0)"
  want_count "$p/_workspace/.receipts/active" 1
  ok 'p62 발급기 no-clobber — active 중복 발급 거부'
}

case_p63() { # 발급기는 3튜플을 **발급 시점에** 대조한다. 나중에 게이트에서만 걸리면
             # 사용자는 "영수증이 있는데 왜 막히나"를 겪는다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"a"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 2
  printf '%s' "$pay" > "$p/_workspace/payload.json"
  run_script "$p" publish-issue-receipt.sh --payload "$p/_workspace/payload.json" \
    --tier 1 --review '_workspace/review.md'
  [ "$RC" -eq 0 ] && WHY="튜플이 어긋났는데 발급됐다 (rc=0)"
  want_count "$p/_workspace/.receipts/active" 0
  ok 'p63 발급기 3튜플 사전 대조 실패 → 발급 거부'
}

case_p64() { # **왕복** — 발급기가 만든 영수증은 게이트를 통과해야 한다. 두 손이 같은 digest
             # 함수를 쓴다는 전제가 실제로 성립하는지 보는 유일한 케이스다.
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_CREATE" '{"summary":"왕복 검증"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_CREATE" "$d" 1
  printf '%s' "$pay" > "$p/_workspace/payload.json"
  run_script "$p" publish-issue-receipt.sh --payload "$p/_workspace/payload.json" \
    --tier 1 --review '_workspace/review.md'
  [ "$RC" -eq 0 ] || WHY="발급 실패 rc=$RC — stderr: [$ERR]"
  if [ -z "$WHY" ]; then
    run_gate "$p" "$pay"
    want_rc 0
    want_count "$p/_workspace/.receipts/used" 1
  fi
  ok 'p64 발급기 → 게이트 왕복 통과'
}

case_p65() { # 승인 스크립트가 만든 승인이 tier2 를 통과시킨다(스키마·경로 왕복).
  local p pay d
  p="$(new_project)"
  pay="$(payload "$T_TRANSITION" '{"issue":"X-1"}')"
  digest_of "$p" "$pay"; d="$DIGEST"
  make_review "$p" '_workspace/review.md' "$T_TRANSITION" "$d" 2
  write_receipt "$p" "$d" 2 '_workspace/review.md' n1 "$T_TRANSITION"
  run_script "$p" publish-approve.sh "$d"
  [ "$RC" -eq 0 ] || WHY="승인 실패 rc=$RC — stderr: [$ERR]"
  if [ -z "$WHY" ]; then
    run_gate "$p" "$pay"
    want_rc 0
    want_count "$p/_workspace/.receipts/approval-used" 1
  fi
  ok 'p65 승인 스크립트 → 게이트 왕복 통과'
}

case_p66() { # **정적 계약** — settings.json 이 이 훅을 광역 MCP 매처로 배선하고 있는가.
             # 배선이 빠지면 훅 파일은 멀쩡한데 아무데서도 안 불린다(가장 조용한 실패).
  run_static 'settings 배선' '
    python3 -c "
import json, sys
with open(sys.argv[1]) as fh:
    s = json.load(fh)
wanted = [h for e in s.get(\"hooks\", {}).get(\"PreToolUse\", [])
          for h in e.get(\"hooks\", [])
          if \"guard-publish-receipt.sh\" in h.get(\"command\", \"\")
          and e.get(\"matcher\") == \"mcp__.*\"]
if not wanted:
    sys.stdout.write(\"settings.json 에 mcp__.* 매처의 guard-publish-receipt 배선이 없다\")
elif any(h.get(\"timeout\") != 15 for h in wanted):
    sys.stdout.write(\"배선의 timeout 이 15 가 아니다\")
" '"$SETTINGS"'
  '
  ok 'p66 settings.json 광역 매처 배선 (정적)'
}

