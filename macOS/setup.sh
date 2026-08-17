#!/usr/bin/env bash
# 새 맥 셋업 오케스트레이터
#
# 설계 원칙: 사람 개입을 앞뒤로 몰아넣고 가운데를 통으로 자동화한다.
#
#   [앞] TCC 권한 2개 켜기        ← 사람 (보안 결정)
#   [앞] sudo 비밀번호 1회 입력    ← 사람 (자격증명)
#   [중간] 전 과정 무인 자동
#   [뒤] gh 로그인 / SSH passphrase ← 사람 (자격증명)
#
# 사용법:
#   ./setup.sh          전체 실행
#   ./setup.sh --check  현재 상태만 점검

set -uo pipefail
cd "$(dirname "$0")"

BREW_BIN=/opt/homebrew/bin/brew
ok()   { printf "  \033[32m✓\033[0m %s\n" "$1"; }
skip() { printf "  \033[90m-\033[0m %s\n" "$1"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$1"; }
step() { printf "\n\033[1m▶ %s\033[0m\n" "$1"; }

# ---------------------------------------------------------------- 상태 점검
check() {
  step "현재 상태"
  # 로그인 셸과 같은 PATH에서 판정해야 git이 어느 쪽인지 정확히 나온다
  [ -x "$BREW_BIN" ] && eval "$($BREW_BIN shellenv)"
  xcode-select -p >/dev/null 2>&1 && ok "Xcode CLT" || warn "Xcode CLT 없음"
  [ -x "$BREW_BIN" ] && ok "Homebrew $($BREW_BIN --version | head -1 | cut -d' ' -f2)" || warn "Homebrew 없음"
  command -v git >/dev/null && ok "git $(git --version | cut -d' ' -f3) ($(command -v git))"
  git config --global user.name >/dev/null 2>&1 \
    && ok "git 신원 $(git config --global user.name) <$(git config --global user.email)>" \
    || warn "git 신원 미설정"
  [ -f ~/.ssh/id_ed25519 ] && ok "SSH 키 있음" || warn "SSH 키 없음"
  [ -f ~/.ssh/config ] && ok "~/.ssh/config 있음" || warn "~/.ssh/config 없음"
  osascript -e 'tell application "System Events" to get UI elements enabled' 2>/dev/null | grep -q true \
    && ok "손쉬운 사용 권한" || warn "손쉬운 사용 권한 없음 (0번 항목 참고)"
  screencapture -x /tmp/.perm_check.png 2>/dev/null && { ok "화면 기록 권한"; rm -f /tmp/.perm_check.png; } \
    || warn "화면 기록 권한 없음 (0번 항목 참고)"
}

[ "${1:-}" = "--check" ] && { check; exit 0; }

# ---------------------------------------------------------------- [앞] 사람
step "사람이 먼저 해야 하는 것"
cat <<'EOF'
  시스템 설정 > 개인정보 보호 및 보안 에서 소문자 `claude` 를 두 곳 모두 켜라.
    - 손쉬운 사용   (GUI 조작)
    - 화면 기록     (화면 확인)

  대문자 `Claude`가 아니라 소문자 `claude`다. SETUP-LOG.md 0번 참고.

  창 열기:
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
EOF
read -r -p $'\n  켰으면 Enter (건너뛰려면 s) > ' a
[ "$a" = "s" ] || check

step "sudo 인증 (한 번만 입력하면 이후 전부 무인)"
echo "  ※ 한/영 상태 확인. 비밀번호는 화면에 표시되지 않는다."
sudo -v
# 스크립트가 도는 동안 인증 유지
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill $SUDO_KEEPALIVE 2>/dev/null' EXIT

# ---------------------------------------------------------------- [중간] 자동
step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  skip "이미 설치됨: $(xcode-select -p)"
else
  # GUI 창 대신 헤드리스 설치. sudo 인증이 살아 있어야 한다.
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  PROD=$(softwareupdate -l 2>/dev/null | grep -o 'Label: Command Line Tools.*' | sed 's/^Label: //' | tail -1)
  if [ -n "$PROD" ]; then
    softwareupdate -i "$PROD" --verbose && ok "설치 완료"
  else
    warn "softwareupdate 목록에 없음 → GUI 폴백"
    xcode-select --install || true
    echo "  설치 창이 뜨면 Claude가 클릭하거나, 직접 눌러라."
  fi
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
fi

step "Homebrew"
if [ -x "$BREW_BIN" ]; then
  skip "이미 설치됨"
else
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "설치 완료"
fi
eval "$($BREW_BIN shellenv)"

step "~/.zprofile"
if grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
  skip "이미 등록됨"
else
  printf '\n# Homebrew\neval "$(/opt/homebrew/bin/brew shellenv)"\n' >> ~/.zprofile
  ok "brew shellenv 등록"
fi

step "패키지 설치 (Brewfile)"
brew bundle --file=Brewfile

step "개별 설정"
for s in scripts/*.sh; do
  [ -f "$s" ] || continue
  echo "  → $s"
  bash "$s"
done

# ---------------------------------------------------------------- [뒤] 사람
step "남은 사람 단계 — 자격증명"
cat <<'EOF'
  아래는 비밀번호/비밀키가 오가는 단계라 사람이 직접 해야 한다.

  1) GitHub 인증 + SSH 키 생성/등록
       gh auth login
     선택: GitHub.com / SSH / 키 생성 Yes / passphrase 설정 / 브라우저 인증

  2) SSH 연결 확인 (여기서 입력한 passphrase가 키체인에 저장된다)
       ssh -T git@github.com

  3) Chrome을 기본 브라우저로
       시스템 설정 > 데스크탑 및 Dock > 기본 웹 브라우저

  4) Rectangle 손쉬운 사용 권한
       시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용 > Rectangle
EOF

step "완료"
check
