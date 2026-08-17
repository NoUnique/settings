#!/usr/bin/env bash
# Ghostty 설치 + 설정 링크
#
# iTerm2 대신 Ghostty를 고른 이유:
#   - 설정이 텍스트 파일 한 장(~/.config/ghostty/config)이라 git으로 관리된다.
#     iTerm2는 바이너리 plist라 버전 관리가 고약하다. "다음 맥에서 재현"이 목표인
#     이 저장소의 방향과 맞지 않는다.
#   - Quick Terminal(상단에서 내려오는 창)이 기본 내장. iTerm2의 Hotkey Window 대응.
#   - Swift + Metal 네이티브. Electron 기반(Hyper/Tabby)과 다르다.
#
# 설정 파일은 이 저장소(config/ghostty/config)에 두고 심볼릭 링크한다.
# 다음 맥에서는 저장소만 클론하면 설정이 따라온다.

set -euo pipefail
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/config/ghostty/config"
DST="$HOME/.config/ghostty/config"

brew list --cask ghostty >/dev/null 2>&1 || brew install --cask ghostty

mkdir -p "$(dirname "$DST")"

# 기존 파일이 심볼릭 링크가 아니면 백업 (사용자가 직접 쓴 설정일 수 있다)
if [ -e "$DST" ] && [ ! -L "$DST" ]; then
  mv "$DST" "$DST.bak.$(date +%Y%m%d%H%M%S)"
  echo "    기존 설정을 .bak으로 백업"
fi

ln -sfn "$SRC" "$DST"
echo "    $DST → $SRC"

# 설정 검증
#
# ⚠️ 출력 문자열로 판정하면 안 된다. 오류 메시지는 "error"가 아니라
#    `... : invalid value "...", valid values are: ...` 형태다.
#    반드시 **종료 코드**로 판정할 것 (정상 0 / 오류 1).
GHOSTTY_BIN=/Applications/Ghostty.app/Contents/MacOS/ghostty
if OUT=$("$GHOSTTY_BIN" +validate-config 2>&1); then
  echo "    설정 검증 통과"
else
  echo "    ⚠️ 설정 오류:"
  echo "$OUT" | sed 's/^/      /' | head -10
  exit 1
fi

# ── 로그인 항목 등록 ────────────────────────────────────────────
# 전역 단축키는 Ghostty 프로세스가 살아 있어야 동작한다. 재부팅 후 매번 손으로
# 실행하지 않도록 로그인 시 자동 실행으로 등록한다.
#
# hidden:true → 로그인 시 창을 띄우지 않고 조용히 실행. 부팅할 때마다 터미널 창이
#               튀어나오지 않으면서 단축키는 살아 있다.
#
# ⚠️ `macos-hidden = always` 설정(Dock/앱 전환기에서 제외)은 쓰지 않는다.
#    quick-terminal 위주 사용자를 위한 옵션이지만 문서에 단서가 있다:
#    "When the macOS application is hidden, keyboard layout changes will no longer
#     be automatic." 한/영을 쓰는 환경에서는 위험하다.
if osascript -e 'tell application "System Events" to get name of every login item' 2>/dev/null \
   | grep -q "Ghostty"; then
  echo "    로그인 항목: 이미 등록됨"
else
  osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Ghostty.app", hidden:true}' >/dev/null 2>&1
  echo "    로그인 항목: 등록 완료 (숨김 실행)"
fi

cat <<'EOF'

    Quick Terminal: ⌥⌘T (좌측 Command — 우측은 한/영 키로 바뀌어 있음)
    ※ Ghostty가 실행 중이어야 동작한다. ⌘Q로 완전히 종료하면 단축키도 죽는다.
      (창만 닫는 건 괜찮다 — quit-after-last-window-closed = false)
    설정 키 확인:   ghostty +show-config --default --docs
                    ghostty +list-actions
EOF
