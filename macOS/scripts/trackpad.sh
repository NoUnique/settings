#!/usr/bin/env bash
# 트랙패드 — 탭하여 클릭 / 두 손가락 보조 클릭
#
# GUI 경로: 시스템 설정 > 트랙패드 > 가리키기 및 클릭
#
# ⚠️ 두 손가락 우클릭이 안 되는 원인은 보통 "두 손가락 보조 클릭" 설정이 아니라
#    **탭하여 클릭이 꺼져 있는 것**이다.
#    TrackpadRightClick=1 이어도 Clicking=0 이면 두 손가락으로 *눌러야* 우클릭이 되고,
#    살짝 *대기만* 해서는 반응하지 않는다. Clicking=1 이어야 두 손가락 탭이 먹는다.
#
# 도메인이 여러 개인 이유:
#   com.apple.AppleMultitouchTrackpad              내장 트랙패드
#   com.apple.driver.AppleBluetoothMultitouch...   Magic Trackpad (외장)
#   NSGlobalDomain com.apple.mouse.tapBehavior     시스템 전역 반영용
#   -currentHost 판본도 함께 써야 확실히 반영된다.

set -euo pipefail

# 탭하여 클릭
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# 두 손가락 보조 클릭 (모서리 클릭 방식은 끔)
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadCornerSecondaryClick -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 0
defaults write NSGlobalDomain ContextMenuGesture -int 1

echo "    적용된 값:"
for k in Clicking TrackpadRightClick TrackpadCornerSecondaryClick; do
  printf "      %-30s %s\n" "$k" "$(defaults read com.apple.AppleMultitouchTrackpad $k 2>/dev/null)"
done
printf "      %-30s %s\n" "tapBehavior" "$(defaults -currentHost read NSGlobalDomain com.apple.mouse.tapBehavior 2>/dev/null)"

cat <<'EOF'

    ※ 즉시 반영되지 않으면 로그아웃 후 다시 로그인할 것.
      (트랙패드 드라이버가 설정을 다시 읽는 시점이 로그인이다)
EOF
