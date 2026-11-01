#!/usr/bin/env bash
# VS Code 관련 macOS 설정
#
# VSCodeVim 사용 시 hjkl 을 길게 누르면 커서가 계속 움직이지 않고
# 악센트 문자 선택창(ĵ ǩ ...)이 뜨는 문제.
# 원인은 macOS 의 "길게 누르면 악센트 입력" 기능(ApplePressAndHoldEnabled).
# VSCodeVim 공식 문서가 안내하는 해결법을 VS Code 에만 적용한다.
#
# ⚠️ 전역(-g)으로 끄지 않는다. 다른 앱에서는 악센트 입력이 필요할 수 있다.
#    전역으로 끄려면: defaults write -g ApplePressAndHoldEnabled -bool false
#
# ⚠️ 앱 시작 시 읽는 값이라 VS Code 를 완전히 종료(⌘Q)했다 다시 열어야 적용된다.
#    "Reload Window" 로는 안 된다.

set -euo pipefail

defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
echo "    VS Code 길게 누르기(악센트 창): $(defaults read com.microsoft.VSCode ApplePressAndHoldEnabled) (0 = 꺼짐 → 키 반복)"
