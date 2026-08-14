#!/usr/bin/env bash
# deploy-guard.sh — install.sh·sync.sh 가 source 하는 **배포 안전 가드**.
#
# 실사고(2026-08-10): 변이 하네스가 도는 중에 정본 트리를 워크트리로 복사해, 표지 판정이
# 빠진 훅이 세션에 들어갔다. 해시를 비교했는데도 못 봤다 — **둘 다 변이본이었으니까.**
# 변이 하네스에는 dirty 검사·락이 있었지만 배포 경로(install/sync)에는 아무것도 없었다.
#
# C안 (2026-08-10 사용자 확정 — 대안 A "락 거부+dirty 경고"·B "dirty 거부만" 기각):
#   ① 변이 락(mutate-*.lock)이 있으면 **무조건 거부.** 옵트인 없음 — 측정 중 배포는
#      언제나 틀리다(락이 남은 죽은 프로세스면 rmdir 로 사람이 걷어낸다)
#   ② 정본 트리가 dirty 면 거부하되 --allow-dirty 로 옵트인 — "템플릿 고치고 프로젝트에
#      설치해 시험"하는 정상 개발 흐름은 명시 한 번으로 지나간다. 경고만 하는 A안은
#      경고를 무시하면 사고가 그대로라 기각, 옵트인 없는 거부는 개발 흐름을 깨서 기각
#
# 판정 불가의 방향:
#   · 정본이 git 저장소가 아니면(압축 배포본 등) 락·dirty 둘 다 git 작업 트리에서만
#     생기는 상태라 검사할 것이 없다 — **생략하되 소리를 낸다**(조용한 생략 금지)
#   · git 저장소인데 status 가 실패하면(권한·손상) dirty 여부를 **모르는** 것이다 —
#     fail-closed 로 거부한다. --allow-dirty 가 이때도 탈출구다("모름"을 사용자가 감수)
#
# 이 파일은 배포되지 않는다(scripts/ 는 배포 경로 밖) — 정본 저장소에서 실행되는
# install/sync 전용이다. 파일이 없으면 호출부가 경고를 내고 진행한다(부분 복사본 대비).

# deploy_guard <TPL_ROOT> <allow_dirty: 0|1>
#   rc=0 통과 / rc=1 거부(사유는 stderr)
#
# **통과 경로의 안내는 최선 노력이다(`|| true`).** 호출부(install/sync)는 set -e 아래
# 도는데, stderr 가 닫힌 환경에서 안내 echo 하나가 실패하면 정상 설치가 통째로 죽는다 —
# 신호 핸들러의 "계약은 종료 코드지 출력이 아니다"와 같은 부류(위음성 카탈로그 14번).
# 거부 경로는 어차피 rc=1 로 끝나므로 그대로 둔다(메시지가 유실돼도 거부는 거부다).
deploy_guard() {
  local tpl="$1" allow_dirty="$2" gitdir l locks="" st
  # GIT_DIR/GIT_WORK_TREE/GIT_INDEX_FILE 소거 — git 훅 안에서 불리면 이 변수들이
  # **다른 저장소**를 가리켜, 정본에 락·dirty 가 있는데 깨끗한 남의 저장소를 검사하고
  # 통과시킨다(검수 [cx] HIGH). mark-needs-audit 의 git_toplevel 과 같은 처리다.
  if ! gitdir="$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
                 git -C "$tpl" rev-parse --git-dir 2>/dev/null)"; then
    echo "   (배포 가드 생략 — 정본이 git 저장소가 아닙니다: 락·dirty 검사 불가)" >&2 || true
    return 0
  fi
  case "$gitdir" in /*) ;; *) gitdir="$tpl/$gitdir" ;; esac

  # ① 변이 락 — 글롭이 무매치면 리터럴이 남으므로 -e 로 거른다.
  for l in "$gitdir"/mutate-*.lock; do
    [ -e "$l" ] && locks="${locks}     $l
"
  done
  if [ -n "$locks" ]; then
    {
      echo "✗ 변이 측정이 진행 중입니다 — 배포를 거부합니다:"
      printf '%s' "$locks"
      echo "  측정 중인 트리를 배포하면 주입된 변이가 프로젝트로 들어갑니다 — 실제로 겪은 사고입니다."
      echo "  측정이 끝난 뒤 다시 실행하세요. 그 프로세스가 죽어 락만 남았다면: rmdir <락 경로>"
      echo "  (이 거부에는 옵트인이 없습니다 — 측정 중 배포는 언제나 틀립니다)"
    } >&2
    return 1
  fi

  # ② dirty — status 실패는 "모름"이라 fail-closed.
  if ! st="$(env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE \
             git -C "$tpl" status --porcelain 2>/dev/null)"; then
    if [ "$allow_dirty" -eq 1 ]; then
      echo "   (배포 가드 — git status 실패, --allow-dirty 지정으로 진행합니다)" >&2 || true
      return 0
    fi
    {
      echo "✗ 정본의 git status 를 읽지 못했습니다 — dirty 여부를 모른 채 배포하지 않습니다."
      echo "  저장소 상태(권한·손상)를 확인하거나, 감수하고 진행하려면 --allow-dirty 를 붙이세요."
    } >&2
    return 1
  fi
  if [ -n "$st" ]; then
    if [ "$allow_dirty" -eq 1 ]; then
      echo "   (배포 가드 — 정본에 미커밋 변경이 있지만 --allow-dirty 지정으로 진행합니다)" >&2 || true
      return 0
    fi
    {
      echo "✗ 정본 트리에 미커밋 변경이 있습니다 — 배포를 거부합니다:"
      printf '%s\n' "$st" | head -10 | sed 's/^/     /'
      echo "  커밋된 정본만 배포하는 것이 기본입니다(무엇이 나갔는지 git 이 말할 수 있게)."
      echo "  템플릿을 고치는 중이고 그 상태로 시험 설치하려면:  --allow-dirty 를 붙이세요."
    } >&2
    return 1
  fi
  return 0
}

# wiring_precheck <대상 settings.json> — **배포 전** 훅 배선의 중복을 본다.
#   rc=0 통과(파일 없음·파싱 성공·중복 없음) / rc=1 중단(사유는 stderr)
#
# 왜 배포 **전**인가: install 의 병합은 (matcher, command) 단위로 멱등이라 중복을 새로
# 만들지는 않지만, **이미 중복인 상태를 고쳐 주지도 않는다.** 중복 배선은 같은 훅이 한
# 호출에 두 번 발화한다는 뜻이고, 발행 게이트에서 그것은 "첫 발화가 영수증을 소비하고
# 둘째 발화가 무영수증으로 차단한다"는 재현 불가능해 보이는 실패로 나온다.
# 그리고 그 상태에서 사용자는 훅이 아니라 자기 호출을 의심한다.
#
# 판정은 **명령 문자열 단위**다(matcher 는 다를 수 있다 — 다른 matcher 에 같은 훅이
# 붙어도 한 도구 호출에 둘 다 걸리면 두 번 돈다). 파싱 실패도 중단이다: 그 상태로
# 병합하면 어차피 깨지는데, 여기서 멈추면 백업 이전이라 사용자 파일이 온전하다.
wiring_precheck() {
  local dst="$1" out rc
  [ -f "$dst" ] || return 0
  out="$(python3 - "$dst" <<'PYEOF'
import json, sys
try:
    with open(sys.argv[1]) as f:
        cur = json.load(f)
except Exception as exc:
    print("settings.json 을 읽지 못했습니다: %s" % exc)
    raise SystemExit(1)
if not isinstance(cur, dict):
    print("settings.json 의 루트가 객체가 아닙니다")
    raise SystemExit(1)
dups = []
for event, entries in (cur.get("hooks") or {}).items():
    if not isinstance(entries, list):
        continue
    seen = {}
    for e in entries:
        if not isinstance(e, dict):
            continue
        for h in (e.get("hooks") or []):
            if not isinstance(h, dict):
                continue
            cmd = h.get("command")
            if not isinstance(cmd, str):
                continue
            seen.setdefault(cmd, []).append(e.get("matcher"))
    for cmd, matchers in seen.items():
        if len(matchers) > 1:
            dups.append("%s: %s  (matcher: %s)" % (event, cmd, ", ".join(str(m) for m in matchers)))
if dups:
    print("훅이 여러 항목에 중복 배선돼 있습니다 — 한 호출에 두 번 발화합니다:")
    for d in dups:
        print("  " + d)
    raise SystemExit(1)
PYEOF
)"
  rc=$?
  [ "$rc" -eq 0 ] && return 0
  {
    echo "✗ 배선 프리체크에서 멈췄습니다: $dst"
    printf '%s\n' "$out" | sed 's/^/  /'
    echo "  중복 항목을 손으로 지운 뒤 다시 실행하세요."
    echo "  (install 은 이 검사를 settings 병합·백업보다 **먼저** 돌립니다 — 대상 파일은 아직 그대로입니다.)"
  } >&2
  return 1
}
