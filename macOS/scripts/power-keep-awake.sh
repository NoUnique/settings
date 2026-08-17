#!/usr/bin/env bash
# 전원 관리 — 세션을 계속 띄워두기 위한 설정
#
# 목적: Claude Code 세션 / 원격 개발 연결 유지.
# 기본값이 AC에서도 sleep 1(유휴 1분)이라 세션이 계속 끊긴다.
#
# 두 단계로 나뉜다:
#   1) 유휴 잠자기 방지  → pmset -c sleep 0        (AC 프로파일만)
#   2) 뚜껑 닫기 방지    → pmset -a disablesleep 1 (전역, 프로파일 구분 없음)
#
# caffeinate는 1)만 해결하고 2)는 못 막는다. 뚜껑 문제는 disablesleep 뿐이다.
# disablesleep은 man pmset에 문서화돼 있지 않지만 동작한다(SleepDisabled 키로 확인).

set -euo pipefail

usage() { echo "사용법: $0 [on|off|status]"; exit 1; }
MODE="${1:-on}"

status() {
  echo "    SleepDisabled : $(pmset -g | awk '/SleepDisabled/{print $2}')  (1 = 뚜껑 닫아도 안 잠듦)"
  echo "    AC sleep      : $(pmset -g custom | sed -n '/AC Power/,$p'      | awk '/^ sleep /{print $2}')"
  echo "    배터리 sleep  : $(pmset -g custom | sed -n '/Battery Power/,/AC Power/p' | awk '/^ sleep /{print $2}')"
  echo "    전원 소스     : $(pmset -g batt | head -1 | sed 's/Now drawing from //')"
}

# root가 필요한 명령. sudo 캐시가 없으면 GUI 인증 창을 띄운다.
# (Claude는 비밀번호를 입력하지 않는다. 사람이 이 창에 입력한다.)
as_root() {
  if sudo -n true 2>/dev/null; then
    sudo sh -c "$1"
  else
    osascript -e "do shell script \"$1\" with administrator privileges"
  fi
}

case "$MODE" in
  on)
    # 전원 소스와 무관하게 잠들지 않게 한다. 화면만 꺼진다.
    as_root "pmset -a sleep 0; pmset -a disablesleep 1; pmset -c displaysleep 10; pmset -b displaysleep 5; pmset -a disksleep 10"
    echo "    잠자기 방지 ON (AC + 배터리 모두)"
    status
    cat <<'EOF'

    ⚠️  배터리에서도 잠들지 않는다. 뚜껑을 닫고 가방에 넣으면 계속 돌면서 발열하고
        배터리가 마른다. 이동 시에만 잠깐 꺼두고 싶다면:

          ~/mac-setup/scripts/power-keep-awake.sh off
EOF
    ;;
  off)
    as_root "pmset -a disablesleep 0"
    echo "    뚜껑 닫기 잠자기 복구 (AC 유휴 설정은 유지)"
    status
    ;;
  status) status ;;
  *) usage ;;
esac
