#!/usr/bin/env bash
# mutate-env-check-hook.sh — harness.env 편집 검증 훅(post:edit:harness-env, ADR-0016)
# 방어의 **변이 측정**. 형제 하네스(mutate-retrieval-gate 등)와 같은 계약:
#   · 대상에 미커밋 변경이 있으면 거부 (복원이 작업물을 지운다)
#   · 치환 앵커는 정확히 1회 매치해야 진행 (빈 변이 = 거짓 초록 방지)
#   · 복원 직후 git hash-object ↔ rev-parse HEAD:<경로> 대조

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1

HOOK="template/.claude/hooks/check-harness-env.sh"
COMMON="template/.claude/hooks/_common.sh"
SETTINGS="template/.claude/settings.json"
TEST="./tests/check-harness-env.test.sh"

for f in "$HOOK" "$COMMON" "$SETTINGS"; do
  if ! git diff --quiet -- "$f" || ! git diff --cached --quiet -- "$f"; then
    echo "✗ 대상에 미커밋 변경이 있습니다: $f — 먼저 커밋하고 재세요 (복원이 작업물을 지웁니다)" >&2
    exit 1
  fi
done

LOCK="$(git rev-parse --git-dir)/mutate-env-check-hook.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  echo "✗ 이미 다른 변이 측정이 돌고 있습니다: $LOCK" >&2
  echo "  (그 프로세스가 죽었다면: rmdir '$LOCK')" >&2
  exit 1
fi
cleanup() {
  # 중단(SIGINT/SIGTERM 포함) 시 변이가 실제 소스에 남지 않게 — 복원은 멱등이다
  # (HEAD 와 같으면 no-op). 락만 지우고 변이를 남기는 창이 실측 지적됐다([cx] HIGH).
  git restore --source=HEAD --worktree -- "$HOOK" "$COMMON" "$SETTINGS" 2>/dev/null
  rmdir "$LOCK" 2>/dev/null
}
trap cleanup EXIT INT TERM

if ! "$TEST" >/dev/null 2>&1; then
  echo "✗ 기준선 실패 — 변이 없이도 테스트가 빨갛습니다. 먼저 초록으로 만들고 재세요" >&2
  exit 1
fi

total=0; red=0; green=0

restore() {
  git restore --source=HEAD --worktree -- "$1" || { echo "✗ 복원 실패: $1" >&2; exit 1; }
  local w h
  w="$(git hash-object "$1")"; h="$(git rev-parse "HEAD:$1")"
  [ "$w" = "$h" ] || { echo "✗ 복원 검증 실패: $1 ($w != $h)" >&2; exit 1; }
}

mutate() {
  local name="$1" file="$2" anchor="$3" repl="$4" n
  total=$((total + 1))
  n="$(python3 - "$file" "$anchor" <<'PY'
import sys
src = open(sys.argv[1], encoding='utf-8').read()
print(src.count(sys.argv[2]))
PY
)"
  if [ "$n" != "1" ]; then
    echo "  ✗ [$name] 앵커 매치 ${n}회 (기대 1) — 빈 변이 방지로 실패 처리" >&2
    return 1
  fi
  python3 - "$file" "$anchor" "$repl" <<'PY'
import sys
p, a, r = sys.argv[1], sys.argv[2], sys.argv[3]
src = open(p, encoding='utf-8').read()
open(p, 'w', encoding='utf-8').write(src.replace(a, r, 1))
PY
  if "$TEST" >/dev/null 2>&1; then
    green=$((green + 1))
    echo "  🟢 [$name] 살아남음 — 이 방어를 지키는 케이스가 없다"
  else
    red=$((red + 1))
    echo "  🔴 [$name] 적색 (방어 확인)"
  fi
  restore "$file"
}

echo "harness.env 편집 검증 훅 변이 측정"

# 1. 판독기의 부재(rc=3) 구분 제거 — 부재가 "못 믿음"으로 접혀 안 쓰는 키에 경고(위양성)
mutate 'e01 파서의 rc=3 부재 구분 제거' "$COMMON" \
  '  if (N == 0) exit 3        # 부재 — 안 쓰는 키의 정상 상태 (반환 계약 rc=3)
  if (N > 1) exit 1' \
  '  if (N != 1) exit 1'

# 2. 파일 없음의 rc=3 제거 (rc=1 로 회귀) — 부재 클래스의 다른 반쪽
mutate 'e02 파일 없음 rc=3 제거' "$COMMON" \
  "  [ -f \"\$file\" ] || { printf '%s' ''; return 3; }" \
  "  [ -f \"\$file\" ] || { printf '%s' ''; return 1; }"

# 3. 훅이 rc=3 을 경고 대상에 포함 — c04(키 없음 침묵)가 빨개진다
mutate 'e03 훅의 부재 침묵 제거' "$HOOK" \
  '    0|3) ;;                              # 판독됨 / 부재(안 쓰는 키) — 정상, 침묵' \
  '    0) ;;'

# 4. 경고 방출 제거 — 문법 실수가 침묵으로 넘어간다(이 훅의 존재 이유 소멸)
mutate 'e04 systemMessage 방출 제거' "$HOOK" \
  'printf '"'"'{"systemMessage":"harness.env 판독 경고: %s' \
  ': # printf 제거됨 -- %s'

# 5. 경로 앵커 느슨화 — 무관 동명 파일에도 발화(위양성)
mutate 'e05 경로 앵커 느슨화' "$HOOK" \
  '  */.claude/harness/harness.env) ;;' \
  '  *harness.env) ;;'

# 6. 상대경로를 cwd 기준으로 — 다른 cwd 에서 그 파일을 못 찾아 부재로 오인(침묵)
mutate 'e06 상대경로를 cwd 기준으로' "$HOOK" \
  '  *)  envfile="$PROJECT_DIR/$file_path" ;;' \
  '  *)  envfile="$file_path" ;;'

# 7-b. 경로 물리화 제거 — `.`/`..` 경유 표기가 앵커를 피해 무경고 통과(위음성)
mutate 'e08 경로 물리화 제거' "$HOOK" \
  'env_dir="$(CDPATH='"'"''"'"' cd -P -- "$(dirname -- "$envfile")" 2>/dev/null && pwd -P)"' \
  'env_dir=""'

# 7-c. settings.json 배선 제거 — 훅 파일이 있어도 실제 편집에서 안 돈다
mutate 'e09 settings 배선 제거' "$SETTINGS" \
  '            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-harness-env.sh\"",' \
  '            "command": "true",'

# 7. 훅 비활성 접기 제거 — 탈출구 소멸
mutate 'e07 hook_disabled 접기 제거' "$HOOK" \
  'hook_disabled "$HOOK_ID" && exit 0' \
  ':'

echo
echo "총 $total 건 — 적색 $red · 초록 $green"
[ "$green" -eq 0 ] && [ "$red" -eq "$total" ]
