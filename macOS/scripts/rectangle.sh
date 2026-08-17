#!/usr/bin/env bash
# Rectangle 설치 + 단축키 설정
#
# 단축키 설계 (키보드 위치가 곧 의미):
#     E   T      1/4 계열
#     D   F      1/3 계열
#   (왼쪽 작은 조각)  (오른쪽 큰 나머지)
#
#   ⌃⌥D 처음 1/3   +  ⌃⌥F 마지막 2/3   →  1/3 + 2/3
#   ⌃⌥E 첫번째 1/4 +  ⌃⌥T 마지막 3/4   →  1/4 + 3/4
#   ⌃⌥E           +  ⌃⌥⌘C 가운데 절반 + (⌃⌥T 반복) → 1/4 + 1/2 + 1/4
#
# 절대 위치 액션(가운데 1/3, 네번째 1/4 등)은 일부러 비운다.
# Rectangle은 같은 단축키를 반복하면 붙는 모서리를 고정한 채 폭을 순환시키므로,
# 자리마다 키를 배정할 필요가 없다. 외울 키는 D/F/E/T 넷뿐.

set -euo pipefail

D="com.knollsoft.Rectangle"
CO=786432        # ⌃⌥
COC=1835008      # ⌃⌥⌘

# --- 설치 (멱등) ---
if ! brew list --cask rectangle >/dev/null 2>&1; then
  brew install --cask rectangle
fi

# 설정을 쓰는 동안은 반드시 종료 상태여야 한다.
# Rectangle은 실행 중 설정을 메모리에 들고 있다가 종료할 때 파일에 덮어쓴다.
killall Rectangle 2>/dev/null || true
sleep 1

# --- 프리셋: 권장 설정 ---
# 첫 실행 모달에서 "권장 설정"을 누르면 세팅되는 값. 직접 써서 모달을 건너뛴다.
# (주의: 이 플래그만으로 환영 창이 완전히 안 뜨는지는 검증하지 못했다.
#  뜨면 "권장 설정"을 누른 뒤 이 스크립트를 다시 실행하면 된다.)
defaults write "$D" alternateDefaultShortcuts -bool true
defaults write "$D" subsequentExecutionMode -int 1   # 반복 실행 시 크기 순환

set_sc()   { defaults write "$D" "$1" -dict keyCode -int "$2" modifierFlags -int "$3"; }
clear_sc() { defaults write "$D" "$1" -dict; }

# --- 지정 ---
set_sc lastTwoThirds     3  "$CO"    # ⌃⌥F   마지막 2/3
set_sc firstFourth      14  "$CO"    # ⌃⌥E   첫번째 1/4
set_sc lastThreeFourths 17  "$CO"    # ⌃⌥T   마지막 3/4
set_sc centerHalf        8  "$COC"   # ⌃⌥⌘C  가운데 절반

# --- 비움 (권장 설정 기본값 제거) ---
clear_sc centerThird       # 기본 ⌃⌥F 였음 → F는 마지막 2/3 이 가져감
clear_sc lastThird         # 기본 ⌃⌥G
clear_sc firstTwoThirds    # 기본 ⌃⌥E 였음 → E는 첫번째 1/4 이 가져감
clear_sc centerTwoThirds   # 기본 ⌃⌥R

open -a Rectangle

cat <<'EOF'

Rectangle 설정 완료.

남은 수동 단계 (macOS 보안 정책상 사람이 눌러야 함):
  시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용 > Rectangle 켜기

확인:
  defaults read com.knollsoft.Rectangle
  메뉴 막대 Rectangle 아이콘 클릭 → 단축키 표시 확인
EOF
