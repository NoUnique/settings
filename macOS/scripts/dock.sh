#!/usr/bin/env bash
# Dock 구성
#
# ⚠️ Finder와 휴지통은 여기서 다루지 않는다.
#    Finder는 `persistent-apps`에 들어 있지 않고 Dock이 항상 맨 왼쪽에 고정으로 그린다.
#    휴지통은 `persistent-others` 소속이라 별개다.
#
# 아이콘 하나는 아래 구조의 dict다:
#   tile-data.file-data._CFURLString      file:// URL (공백은 %20으로 인코딩)
#   tile-data.file-data._CFURLStringType  15 (= file URL)
#   tile-type                             "file-tile"
#
# 경로에 공백이 있는 앱("Google Chrome.app", "App Store.app")은 반드시 %20 인코딩할 것.
# 인코딩하지 않으면 Dock이 물음표 아이콘으로 표시한다.

set -euo pipefail

# 순서대로. 왼쪽부터 이 순서로 놓인다. (Finder는 이 앞에 자동으로 붙는다)
APPS=(
  # ── 기본 앱 ──
  "/System/Applications/Apps.app"
  "/System/Applications/App Store.app"
  "/System/Applications/System Settings.app"
  "/System/Applications/iPhone Mirroring.app"
  "/System/Applications/Notes.app"
  "/System/Applications/TV.app"
  "/System/Applications/Music.app"
  # ── 설치한 앱 ──
  "/Applications/Google Chrome.app"
  "/Applications/Ghostty.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Claude.app"
)

# 존재하지 않는 앱은 건너뛴다 (설치 순서에 따라 없을 수 있다)
MISSING=()
for p in "${APPS[@]}"; do
  [ -d "$p" ] || MISSING+=("$p")
done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "    ⚠️ 없는 앱은 건너뜀:"
  printf '      %s\n' "${MISSING[@]}"
fi

# 공백 → %20 (그 외 특수문자는 이 목록에 없다)
urlencode() { printf '%s' "${1// /%20}"; }

defaults write com.apple.dock persistent-apps -array

for p in "${APPS[@]}"; do
  [ -d "$p" ] || continue
  url="file://$(urlencode "$p")/"
  defaults write com.apple.dock persistent-apps -array-add "
    <dict>
      <key>tile-data</key>
      <dict>
        <key>file-data</key>
        <dict>
          <key>_CFURLString</key><string>${url}</string>
          <key>_CFURLStringType</key><integer>15</integer>
        </dict>
      </dict>
      <key>tile-type</key><string>file-tile</string>
    </dict>"
done

# 아이콘 크기. 기본 48, 범위 16~128.
#
# 처음엔 화면이 좁아 36까지 줄였는데 너무 작았다. 자동 숨김을 켜면 평소 자리를
# 차지하지 않으므로 크기를 줄일 이유가 사라진다 → 기본 48로 복귀.
defaults write com.apple.dock tilesize -int 48

# 자동 숨김. 커서를 화면 맨 아래로 내리면 올라온다.
defaults write com.apple.dock autohide -bool true
# 커서가 가장자리에 닿고 나서 올라오기까지의 지연(초). 기본 약 0.5로 굼뜨다.
# 0으로 두면 스치기만 해도 튀어나와 거슬리므로 작은 값을 준다.
defaults write com.apple.dock autohide-delay -float 0.15
# 올라오고 내려가는 애니메이션 속도 배수. 1보다 작을수록 빠르다.
defaults write com.apple.dock autohide-time-modifier -float 0.5

# 커서를 올렸을 때 확대하는 효과. 켜려면 아래 두 줄의 주석을 풀 것.
# defaults write com.apple.dock magnification -bool true
# defaults write com.apple.dock largesize -int 64

# "최근 사용한 응용 프로그램" 영역 끄기.
# 켜져 있으면 구분선 오른쪽에 최근 실행한 앱이 자동으로 붙는다. 고정해둔 앱과
# 중복돼 보이고, 고정 목록만 두려는 의도와 어긋난다.
# 되돌리려면: defaults write com.apple.dock show-recents -bool true && killall Dock
defaults write com.apple.dock show-recents -bool false

killall Dock 2>/dev/null || true
sleep 3

# grep 패턴 주의: `_CFURLString` 은 `_CFURLStringType` 에도 걸려 두 배로 세어진다.
N=$(defaults read com.apple.dock persistent-apps 2>/dev/null | grep -c '_CFURLString"')
echo "    Dock 재구성 완료 (${N}개 + Finder)"
