#!/usr/bin/env bash
# 키 반복 속도 — Vim 이동(hjkl 길게 누르기)이 느린 문제
#
# GUI: 시스템 설정 > 키보드 > 키 반복 속도 / 반복 지연 시간
#
#   KeyRepeat         반복 간격. 작을수록 빠름. UI 최댓값(가장 빠름) = 2
#   InitialKeyRepeat  반복이 시작되기 전 지연. 작을수록 짧음. UI 최솟값 = 15
#
# 둘 다 UI 한계값으로 맞춘다. defaults 로는 UI보다 더 빠르게(1 / 10) 줄 수도 있지만
# 오타가 늘 만큼 과해서 쓰지 않는다.
#
# ⚠️ 앱이 시작할 때 읽는 값이다. 이미 떠 있는 앱은 재시작해야 반영되고,
#    전체에 확실히 적용하려면 로그아웃 후 재로그인.
#
# 길게 누르면 반복 대신 악센트 창(é è ê …)이 뜨는 기능도 모든 앱에서 끈다.
#   처음엔 VS Code에만 껐는데(scripts/vscode.sh), 다른 앱에서도 반복 입력을 원해서 전역으로 바꿨다.
#   악센트 문자가 필요하면 ⌥ 조합(⌥E → é)이나 입력 소스의 문자 보기로 넣는다.

set -euo pipefail

defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
defaults write -g ApplePressAndHoldEnabled -bool false

echo "    KeyRepeat=$(defaults read -g KeyRepeat)  InitialKeyRepeat=$(defaults read -g InitialKeyRepeat)"
echo "    길게 누르기(악센트 창): $(defaults read -g ApplePressAndHoldEnabled) (0 = 꺼짐 → 모든 앱에서 키 반복)"
