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

# --- App Nap 끄기 ---
# 화면보호기가 켜지거나 창이 다 가려지면 macOS가 VS Code를 "안 보이는 앱"으로 보고
# App Nap으로 타이머·네트워크·CPU를 아껴 쓰게 한다. 그러면 VS Code 안에서 돌던
# Codex 같은 에이전트 작업이 느려지거나 멈춘 것처럼 보인다 (SETUP-LOG 26번).
# VS Code에만 적용한다. 전역(-g)으로 끄면 모든 앱이 안 자서 배터리를 더 먹는다.
# 이 값도 앱 시작 시 읽으므로 VS Code를 완전히 종료(⌘Q)했다 다시 열어야 적용된다.
defaults write com.microsoft.VSCode NSAppSleepDisabled -bool true
echo "    VS Code App Nap: $(defaults read com.microsoft.VSCode NSAppSleepDisabled) (1 = 끔 → 화면보호기 중에도 안 느려짐)"
