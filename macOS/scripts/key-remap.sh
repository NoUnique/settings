#!/usr/bin/env bash
# 키 리매핑 — Caps Lock → Esc, 우측 Command → 한/영
#
# Karabiner-Elements 없이 macOS 내장 기능만으로 처리한다.
#   앱 설치 / 드라이버 확장 승인 / 입력 모니터링 권한 전부 불필요.
#
# 두 단계로 나뉜다:
#   1) hidutil        물리 키 → 다른 키 코드로 치환
#   2) symbolichotkeys  그 키를 "이전 입력 소스 선택" 단축키로 지정
#
# ── 왜 F18인가 (LANG1이 아니라) ──────────────────────────────────
# 처음엔 우측 Command → LANG1(0x90, 한국어 키보드의 물리 한/영 키가 보내는 코드)로
# 시도했다. hidutil 매핑 자체는 적용됐지만 **macOS가 LANG1을 입력 소스 전환으로
# 받아주지 않았다**(이 맥에서 확인). 그래서 아무 데도 안 쓰이는 F18로 바꾸고,
# F18을 입력 소스 전환 단축키로 지정하는 방식으로 우회한다.
#
# ── HID usage 코드 (0x7000000xx = Keyboard/Keypad page) ─────────
#   0x39 Caps Lock   0x29 Escape   0xE7 Right GUI(⌘)   0x6D F18
#   (참고: 0x90 LANG1, 0x91 LANG2, 0xE3 Left GUI)
#
# ⚠️ 우측 Command는 더 이상 수식키가 아니다. ⌘C 등은 좌측 Command만 동작한다.
#
# hidutil 설정은 메모리에만 남아 재부팅하면 사라진다 → LaunchAgent로 로그인 시 재적용.

set -euo pipefail

LABEL="com.nounique.keyremap"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
MAPPING='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029},{"HIDKeyboardModifierMappingSrc":0x7000000E7,"HIDKeyboardModifierMappingDst":0x70000006D}]}'

# 이전 입력 소스 선택(hotkey id 60)에 F18 할당
#   parameters = (문자, 가상키코드, 수식키플래그)
#   65535   = 문자 없음
#   79      = F18의 가상 키 코드
#   8388608 = 0x800000, Function 플래그 (F키에 자동으로 붙는다)
set_hotkey() {
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 '
    <dict>
      <key>enabled</key><true/>
      <key>value</key><dict>
        <key>parameters</key><array>
          <integer>65535</integer><integer>79</integer><integer>8388608</integer>
        </array>
        <key>type</key><string>standard</string>
      </dict>
    </dict>'
}

case "${1:-on}" in
  on)
    hidutil property --set "$MAPPING" >/dev/null
    set_hotkey

    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/hidutil</string>
    <string>property</string>
    <string>--set</string>
    <string>${MAPPING}</string>
  </array>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
EOF
    launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$PLIST"
    echo "    적용 완료 (로그인 시 자동 재적용)"
    echo "    ※ symbolichotkeys 변경은 로그아웃 후 완전히 반영된다."
    ;;
  off)
    hidutil property --set '{"UserKeyMapping":[]}' >/dev/null
    launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
    rm -f "$PLIST"
    echo "    리매핑 해제 (단축키 설정은 그대로 둠)"
    ;;
  status) ;;
  *) echo "사용법: $0 [on|off|status]"; exit 1 ;;
esac

echo "    hidutil 매핑:"
hidutil property --get "UserKeyMapping" | tr -d '\n ' | sed 's/},{/}\n/g' | sed 's/^/      /'
echo
echo -n "    이전 입력 소스 단축키: "
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null \
  | awk '/^    60 =/,/^    };/' | grep -A4 parameters | tr -d '\n ,()' | sed 's/parameters//' || echo "(미설정)"
echo
launchctl print "gui/$(id -u)/${LABEL}" >/dev/null 2>&1 \
  && echo "    LaunchAgent: 등록됨" || echo "    LaunchAgent: 없음"
