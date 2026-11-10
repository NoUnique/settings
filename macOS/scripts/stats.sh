#!/usr/bin/env bash
# Stats 설치 + 메뉴 막대 시스템 모니터 설정
#
# 메뉴 막대에 CPU/GPU/메모리 사용량을 실시간으로 띄운다. macOS 기본 기능에는 없다.
# iStat Menus(유료) 대신 무료 오픈소스 Stats(exelban/stats)를 쓴다.
#
# 아래 값은 사용자가 직접 맞춘 상태를 그대로 옮긴 것이다 (2026-11-03, SETUP-LOG 23번):
#   표시 항목     CPU · GPU · RAM · 네트워크 (나머지는 안 보임)
#   모양          CPU/GPU/RAM = 세로 라벨 + 선 그래프, 네트워크 = 업/다운 속도
#   합치기        켬 (메뉴 막대 아이콘 하나로 묶음)
#   위치          Wi-Fi 바로 왼쪽 (scripts/menubar.sh의 배치와 짝)
#   로그인 시 시작 켬
#   업데이트      한 달에 한 번

set -euo pipefail
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

D="eu.exelban.Stats"

brew list --cask stats >/dev/null 2>&1 || brew install --cask stats

# 설정을 쓰는 동안은 종료 상태여야 한다. 실행 중이면 종료할 때 메모리 값으로 덮어쓴다.
killall Stats 2>/dev/null || true
sleep 1

# --- 모듈 / 위젯 ---
# <모듈>_widget: 켤 위젯 목록(쉼표 구분). 빈 문자열이면 메뉴 막대에 안 보인다.
# <모듈>_<위젯>_position: 모듈 안에서의 위젯 순서. label이 0이라 라벨이 그래프 앞에 붙는다.
defaults write "$D" CPU_state -bool true
defaults write "$D" CPU_widget "line_chart,label"
defaults write "$D" CPU_label_position -int 0
defaults write "$D" CPU_lineChart_position -int 1

defaults write "$D" GPU_state -bool true
defaults write "$D" GPU_widget "line_chart,label"
defaults write "$D" GPU_label_position -int 0
defaults write "$D" GPU_lineChart_position -int 1

defaults write "$D" RAM_state -bool true
defaults write "$D" RAM_widget "label,line_chart"
defaults write "$D" RAM_label_position -int 0
defaults write "$D" RAM_lineChart_position -int 1

defaults write "$D" Network_state -bool true
defaults write "$D" Network_widget speed

# 아래 둘은 모듈은 켜져 있지만 위젯이 없어서 메뉴 막대에 안 보이는 상태 (현재 상태 그대로).
defaults write "$D" Battery_state -bool true
defaults write "$D" Battery_widget ""
defaults write "$D" Sensors_state -bool true
defaults write "$D" Sensors_widget ""

defaults write "$D" Disk_state      -bool false
defaults write "$D" Bluetooth_state -bool false
defaults write "$D" Clock_state     -bool false

# 모든 모듈을 메뉴 막대 아이콘 하나로 합친다 (설정 > 전체 모듈)
defaults write "$D" CombinedModules -bool true
defaults write "$D" CombinedModules_icon -bool false

# 메뉴 막대 위치: 오른쪽 끝에서 잰 거리. Wi-Fi(321)보다 조금 큰 값 → Wi-Fi 바로 왼쪽.
defaults write "$D" "NSStatusItem Preferred Position CombinedModules" -float 359

# --- 업데이트 ---
# 값: "Silent" / "At start" / "Once per day" / "Once per week" / "Once per month" / "Never"
defaults write "$D" update-interval "Once per month"

# --- 첫 실행 마법사 건너뛰기 ---
# Stats는 setupProcess 또는 runAtLoginInitialized 키가 있으면 마법사를 띄우지 않는다.
defaults write "$D" setupProcess -bool true
defaults write "$D" runAtLoginInitialized -bool true

# --- 로그인 시 시작 ---
# ⚠️ Stats 버그: runAtLoginInitialized는 있는데 LaunchAtLoginNext가 없으면, 다음 실행 때
#    LaunchAtLogin.migrate()가 옛 방식 등록 상태(없음)를 그대로 옮겨 자동 시작을 꺼버린다.
#    (마법사에서 켰는데 재시작하자 설정 화면 스위치가 꺼져 있던 원인. Kit/helpers.swift)
#    LaunchAtLoginNext를 미리 써두면 migrate()가 아무것도 하지 않는다.
defaults write "$D" LaunchAtLoginNext -bool true

# 앱 자체 스위치(SMAppService)는 셸에서 켤 수 없어서 로그인 항목을 직접 등록한다.
# 이 방식으로 등록하면 Stats 설정 화면의 "로그인 시 시작" 스위치는 꺼진 채로 보이지만
# 로그인 시 실행은 된다. 스위치까지 켜두고 싶으면 설정 화면에서 직접 켜면 된다.
if osascript -e 'tell application "System Events" to get name of every login item' 2>/dev/null \
   | grep -q "Stats"; then
  echo "    로그인 항목: 이미 등록됨"
else
  osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Stats.app", hidden:true}' >/dev/null 2>&1
  echo "    로그인 항목: 등록 완료"
fi

open -a /Applications/Stats.app
echo "    Stats 실행 — 메뉴 막대: [CPU 그래프][GPU 그래프][RAM 그래프][네트워크 속도]  Wi-Fi  한/영  배터리"
