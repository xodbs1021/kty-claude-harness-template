#!/usr/bin/env bash
# mark-needs-audit.sh 의 검사 범위 회귀 테스트.
#
# 왜 이 테스트가 존재하나 (2026-08-04 실사고): 하네스 템플릿을 고치는 작업은 늘
# PROJECT_DIR 밖의 별도 클론에서 일어나는데, 훅이 거기서 통째로 스킵돼 완료 게이트가
# 하나도 안 섰다. 게이트가 프로젝트는 지키면서 정작 하네스 자체 개발만 못 지킨 것이다.
# 범위 판정은 조용히 틀리는 종류의 버그라(플래그가 안 서도 아무 에러가 없다) 테스트로 못 박는다.
#
# 사용법: ./tests/mark-needs-audit.test.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/template/.claude/hooks/mark-needs-audit.sh"

pass=0
fail=0

# 매 케이스마다 격리된 가짜 프로젝트를 새로 만든다 — 플래그가 케이스 간에 새지 않게.
# run_case <설명> <flagged|skipped> <파일경로> [--in-repo]
#   {PROJECT} → 가짜 프로젝트 루트, {SANDBOX} → 프로젝트 밖 디렉터리로 치환된다.
#   --in-repo 면 샌드박스를 git init 해서 "프로젝트 밖이지만 저장소 안"을 만든다.
run_case() {
  local desc="$1" expect="$2" path_tpl="$3" in_repo="${4:-}"

  local project sandbox file_path actual
  project="$(mktemp -d)"
  sandbox="$(mktemp -d)"
  mkdir -p "$project/.claude"

  file_path="${path_tpl//\{PROJECT\}/$project}"
  file_path="${file_path//\{SANDBOX\}/$sandbox}"

  mkdir -p "$(dirname "$file_path")"
  : > "$file_path"

  if [ "$in_repo" = "--in-repo" ]; then
    git -C "$sandbox" init -q 2>/dev/null
  fi

  printf '{"tool_input":{"file_path":"%s"}}' "$file_path" \
    | CLAUDE_PROJECT_DIR="$project" bash "$HOOK" >/dev/null 2>&1

  actual="skipped"
  [ -s "$project/.claude/.needs-audit" ] && actual="flagged"

  if [ "$actual" = "$expect" ]; then
    printf '  ✓ %s\n' "$desc"
    pass=$((pass + 1))
  else
    printf '  ✗ %s\n      기대=%s 실제=%s\n      경로: %s\n' "$desc" "$expect" "$actual" "$file_path"
    fail=$((fail + 1))
  fi

  rm -rf "$project" "$sandbox"
}

echo "mark-needs-audit.sh — 검사 범위"

# 프로젝트 안 (기존 동작이 그대로 유지돼야 한다)
run_case "프로젝트 안 소스 → 플래그"            flagged "{PROJECT}/src/app.ts"
run_case "프로젝트 안 README → 스킵"            skipped "{PROJECT}/README.md"
run_case "프로젝트 안 _workspace → 스킵"        skipped "{PROJECT}/_workspace/scratch.ts"
run_case "설치된 글루(.claude/) → 스킵"          skipped "{PROJECT}/.claude/agents/x.md"

# 프로젝트 밖 (이번 수정의 핵심 — 예전엔 전부 skipped 였다)
run_case "밖+저장소 안, 셸 스크립트 → 플래그"    flagged "{SANDBOX}/scripts/check.sh"                    --in-repo
run_case "밖+저장소 안, 에이전트 정의 → 플래그"  flagged "{SANDBOX}/template/.claude/agents/dev.md"      --in-repo
run_case "밖+저장소 안, 스킬 정의 → 플래그"      flagged "{SANDBOX}/template/.claude/skills/s/SKILL.md"  --in-repo
run_case "밖+저장소 안, 원칙 정본 → 플래그"      flagged "{SANDBOX}/template/.claude/harness/principles.md" --in-repo
run_case "밖+저장소 안, 순수 문서 → 스킵"        skipped "{SANDBOX}/docs/usage.md"                       --in-repo
run_case "밖+저장소 밖, 임시 파일 → 스킵"        skipped "{SANDBOX}/tmpfile.ts"

echo ""
if [ "$fail" -ne 0 ]; then
  echo "✗ ${fail}개 실패 / ${pass}개 통과"
  exit 1
fi
echo "✓ ${pass}개 통과"
