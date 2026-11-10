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

# ── 시계 24시간제 ────────────────────────────────────────────────
# GUI: 시스템 설정 > 일반 > 날짜 및 시간 > 24시간 형식
# 전역 값(-g)이 시스템 전체 시간 형식, menuextra.clock은 메뉴 막대 시계 표시 형식.
defaults write -g AppleICUForce24HourTime -bool true
defaults write com.apple.menuextra.clock Show24Hour -bool true

# ── 메뉴 막대 오른쪽 끝 순서 ────────────────────────────────────
# 기본 배치 (오른쪽 끝에서 왼쪽으로, 제어 센터·시계 제외):
#   배터리 → 한/영 → Wi-Fi → Stats(scripts/stats.sh) → Hidden Bar(scripts/hiddenbar.sh) → 그 밖의 앱들
#
# 각 항목 위치는 그 항목을 띄우는 앱의 defaults에 "오른쪽 끝에서 잰 거리(pt)"로 저장된다.
#   NSStatusItem Preferred Position <항목>
# 값이 작을수록 오른쪽. 아래 값은 원하는 배치로 맞춘 맥에서 그대로 읽어온 것이다.
# 다른 앱 아이콘은 이보다 큰 값을 받아 왼쪽에 붙는다.
# ⌘ 누른 채 아이콘을 끌어 순서를 바꾸면 이 값이 갱신된다. 바꾸면 여기도 고칠 것.
defaults write com.apple.controlcenter      "NSStatusItem Preferred Position Battery" -float 201
defaults write com.apple.TextInputMenuAgent "NSStatusItem Preferred Position Item-0"  -float 277
defaults write com.apple.controlcenter      "NSStatusItem Preferred Position WiFi"    -float 321

killall ControlCenter 2>/dev/null || true
killall TextInputMenuAgent 2>/dev/null || true
sleep 2

echo "    배터리 백분율: $(defaults read com.apple.controlcenter BatteryShowPercentage 2>/dev/null || echo '미설정')"
echo "    현재 배터리:   $(pmset -g batt | sed -n '2p' | awk -F';' '{print $1}' | awk '{print $NF}')"
