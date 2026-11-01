#!/usr/bin/env bash
# 잠금 화면 / 화면 보호기
#
# GUI 경로:
#   시스템 설정 > 잠금 화면          디스플레이 끄기 시간, 암호 요구 시간
#   시스템 설정 > 배경화면 > 화면 보호기...   화면 보호기 시작 시간
#
# 세 값이 서로 얽혀 있다:
#   화면 보호기 시작(30분) → 디스플레이 끄기(배터리 30분 / AC 60분) → 암호 요구(1시간)
#   화면이 꺼져도 1시간 동안은 암호 없이 돌아올 수 있다는 뜻.
#
# ⚠️ 디스플레이 끄기 시간은 pmset 소관이라 scripts/power-keep-awake.sh 에서 설정한다.
#    (잠자기 방지 설정과 같은 명령에 묶여 있어 분리하면 서로 덮어쓴다)

set -euo pipefail

# ── 화면 보호기 시작: 30분 ──────────────────────────────────────
# ⚠️ -currentHost 필수. 이게 없으면 시스템 설정 UI에 반영되지 않는다.
defaults -currentHost write com.apple.screensaver idleTime -int 1800

# ── 암호 요구: 1시간 ────────────────────────────────────────────
# ⚠️ macOS 13+ 에서는 이 값이 com.apple.screensaver 에 없다.
#    defaults 로 읽어도 "(미설정)"으로 나오며 sysadminctl 로만 조회된다.
#      확인: sysadminctl -screenLock status
#    설정에는 관리자 인증이 필요하므로 자동화되지 않는다. 아래를 직접 실행할 것:
#      sysadminctl -screenLock 3600 -password -
#    (또는 시스템 설정 > 잠금 화면에서 "1시간 후" 선택)

echo "    화면 보호기 시작: $(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null)초"
echo "    암호 요구:        $(sysadminctl -screenLock status 2>&1 | grep -o '[0-9]* seconds')"
echo "    디스플레이 끄기:"
pmset -g custom 2>/dev/null | awk '/^Battery Power:/{p="배터리"} /^AC Power:/{p="AC"} /^ displaysleep/{printf "      %-8s %s분\n", p, $2}'
