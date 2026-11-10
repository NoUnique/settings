#!/usr/bin/env bash
# Hidden Bar 설치 + 메뉴 막대 접기 설정
#
# Stats 왼쪽의 메뉴 막대 아이콘을 전부 접었다 폈다 한다.
#
#   접힘:  ‹  [Stats]  Wi-Fi  한  배터리
#   펼침:  … Claude  ChatGPT  Notion  |  ›  [Stats]  Wi-Fi  한  배터리
#
# Hidden Bar는 아이콘 두 개를 띄운다.
#   화살표(hiddenbar_expandcollapse) — 누르면 접기/펴기
#   구분선(hiddenbar_separate)       — 이 왼쪽에 있는 아이콘이 접힌다
# 접을 때는 구분선 길이를 화면보다 길게 늘려서 왼쪽 아이콘들을 화면 밖으로 밀어낸다.

set -euo pipefail
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

D="com.dwarvesv.minimalbar"
APP="/Applications/Hidden Bar.app"

brew list --cask hiddenbar >/dev/null 2>&1 || brew install --cask hiddenbar

killall "Hidden Bar" 2>/dev/null || true
sleep 1

# --- 위치 ---
# 메뉴 막대 위치는 오른쪽 끝에서 잰 거리(scripts/menubar.sh 참고). 값이 작을수록 오른쪽.
#   Stats(359) < 화살표(365) < 구분선(372)  → Stats 바로 왼쪽에 › | 순서로 붙는다
# 다른 앱 아이콘은 이보다 큰 값이라 구분선 왼쪽에 놓이고, 접으면 숨겨진다.
defaults write "$D" "NSStatusItem Preferred Position hiddenbar_expandcollapse" -float 365
defaults write "$D" "NSStatusItem Preferred Position hiddenbar_separate"       -float 372

# --- 옵션 ---
# 로그인 시 시작. 앱이 시작할 때 이 값을 보고 SMAppService로 스스로 등록한다.
defaults write "$D" isAutoStart -bool true
# 실행할 때마다 설정 창 띄우기(기본 켬) → 끔. 로그인할 때마다 창이 뜨지 않게.
defaults write "$D" isShowPreferences -bool false
# 나머지는 앱 기본값 그대로: 펼친 뒤 10초 지나면 자동으로 접힘, 클릭해야 펼침.

open -a "$APP"
echo "    Hidden Bar 실행 — Stats 왼쪽 ‹ 를 누르면 접힌 아이콘이 펼쳐진다 (10초 뒤 자동으로 접힘)"
