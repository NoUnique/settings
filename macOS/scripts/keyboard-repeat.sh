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
# 관련: VS Code 에서 길게 누르면 반복 대신 악센트 창이 뜨는 문제는 scripts/vscode.sh

set -euo pipefail

defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15

echo "    KeyRepeat=$(defaults read -g KeyRepeat)  InitialKeyRepeat=$(defaults read -g InitialKeyRepeat)"
