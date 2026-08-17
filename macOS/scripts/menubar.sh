#!/usr/bin/env bash
# 메뉴 막대 / 제어 센터 설정
#
# GUI 경로: 시스템 설정 > 제어 센터 > 배터리 > 백분율 보기
# defaults로 처리되므로 GUI 자동화가 필요 없다.
#
# 제어 센터 항목들은 com.apple.controlcenter 도메인에 있다.
# 변경 후 killall ControlCenter 로 다시 읽게 해야 반영된다.

set -euo pipefail

# 배터리 백분율 표시
defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
defaults write com.apple.controlcenter BatteryShowPercentage -bool true

killall ControlCenter 2>/dev/null || true
sleep 2

echo "    배터리 백분율: $(defaults read com.apple.controlcenter BatteryShowPercentage 2>/dev/null || echo '미설정')"
echo "    현재 배터리:   $(pmset -g batt | sed -n '2p' | awk -F';' '{print $1}' | awk '{print $NF}')"
