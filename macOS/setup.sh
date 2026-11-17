#!/usr/bin/env bash
# 새 맥 셋업 오케스트레이터
#
# 설계 원칙: 사람 개입을 앞뒤로 몰아넣고 가운데를 통으로 자동화한다.
#
#   [0]  할 일 전체 안내 + 선택 전부 받기 ← 사람 (여기서 다 정한다)
#   [앞] TCC 권한 2개 켜기        ← 사람 (보안 결정)
#   [앞] sudo / 관리자 비밀번호    ← 사람 (자격증명)
#   [중간] 전 과정 무인 자동
#   [뒤] 앱별 손쉬운 사용 / SSH / 기본 브라우저 ← 사람
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

# ---------------------------------------------------------------- [0] 전체 안내
# 원칙: 시작하기 전에 "사람이 할 일 전부"와 "정해야 할 것 전부"를 먼저 보여주고,
#       선택은 여기서 한 번에 다 받는다. 그 뒤로는 끝날 때까지 묻지 않는다.
step "시작 전 안내 — 사람이 할 일 전체 목록"
OPT_LIST=$(sed -n 's/^cask "\([^"]*\)".*/\1/p' Brewfile.optional | tr '\n' ' ')
MAS_LIST=$(sed -n 's/^mas "\([^"]*\)".*/\1/p' Brewfile.optional | tr '\n' ' ')
cat <<EOF
  [지금, 시작 전]
    1) 선택 앱 설치 여부 고르기 (바로 아래에서 묻는다): ${OPT_LIST:-없음}
    2) SSH 키를 어디서 가져올지 고르기 (NAS 백업 복원 / gh로 새로 생성 / 나중에)
    3) 시스템 설정 > 개인정보 보호 및 보안 에서 소문자 \`claude\` 켜기
         - 손쉬운 사용
         - 화면 기록 (목록에 없으면 + 로 claude.app 추가 → Claude 앱 재시작)
    4) sudo 비밀번호 1회 (한/영 확인)
    5) 잠금 화면 암호 요구 1시간 — 관리자 비밀번호 1회 (sysadminctl)

  [자동 구간 중 — 창이 뜨면 Claude가 처리하거나 바로 알린다]
    - "인터넷에서 다운로드된 앱" 첫 실행 확인 → 열기
    - "로컬 네트워크 기기 찾기" → 기본은 허용 안 함 (NAS 등 꼭 필요한 것만 허용)
    - "○○을(를) 제어하려 함"(자동화) → 무슨 창인지 알리고 사람이 결정

  [끝난 뒤]
    6) 손쉬운 사용: Rectangle, Ghostty 켜기 → 각 앱 재시작
    7) SSH: 고른 방식대로 (NAS 복원이면 NAS 로그인 / gh auth login)
    8) 기본 브라우저 Chrome 지정 (시스템 확인 창)
    9) App Store 앱 직접 설치: ${MAS_LIST:-없음}
EOF

step "선택 — 여기서 전부 정한다"
OPTIONAL_CASKS=()
for c in $OPT_LIST; do
  read -r -p "  $c 설치할까? [y/N] > " yn </dev/tty
  [[ "$yn" =~ ^[Yy]$ ]] && OPTIONAL_CASKS+=("$c")
done

echo "  SSH 키:  1) NAS 백업에서 복원   2) gh로 새로 생성   3) 나중에"
read -r -p "  고르기 [1/2/3] > " SSH_MODE </dev/tty
case "$SSH_MODE" in 1|2) ;; *) SSH_MODE=3 ;; esac

step "선택 요약"
echo "  선택 앱:  ${OPTIONAL_CASKS[*]:-없음}"
case "$SSH_MODE" in 1) SSH_DESC="NAS 백업에서 복원" ;; 2) SSH_DESC="gh로 새로 생성" ;; *) SSH_DESC="나중에" ;; esac
echo "  SSH 키:   $SSH_DESC"
read -r -p $'  이대로 진행? [Y/n] > ' go </dev/tty
[[ "$go" =~ ^[Nn]$ ]] && { echo "  중단"; exit 1; }

# ---------------------------------------------------------------- [앞] 사람
step "권한 — 소문자 claude 켜기"
cat <<'EOF'
  대문자 `Claude`가 아니라 소문자 `claude`다. SETUP-LOG.md 0번 참고.
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
EOF
read -r -p $'\n  켰으면 Enter (건너뛰려면 s) > ' a </dev/tty
[ "$a" = "s" ] || check

step "sudo 인증 (한 번만 입력하면 이후 전부 무인)"
echo "  ※ 한/영 상태 확인. 비밀번호는 화면에 표시되지 않는다."
sudo -v
# 스크립트가 도는 동안 인증 유지
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill $SUDO_KEEPALIVE 2>/dev/null' EXIT

step "잠금 화면 암호 요구 1시간 (관리자 비밀번호)"
# 뒤로 미루면 사람이 끝까지 붙어 있어야 하므로 앞에서 처리한다
sysadminctl -screenLock 3600 -password - || warn "실패 — 나중에: sysadminctl -screenLock 3600 -password -"

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
if [ ${#OPTIONAL_CASKS[@]} -gt 0 ]; then
  brew install --cask "${OPTIONAL_CASKS[@]}" && ok "선택 앱 설치: ${OPTIONAL_CASKS[*]}"
else
  skip "선택 앱 없음"
fi

step "개별 설정"
for s in scripts/*.sh; do
  [ -f "$s" ] || continue
  echo "  → $s"
  bash "$s"
done

# ---------------------------------------------------------------- [뒤] 사람
step "남은 사람 단계"
case "$SSH_MODE" in
  1) cat <<'EOF'
  1) SSH 키 — NAS 백업에서 복원 (SETUP-LOG 27번)
       Finder ⌘K → smb://NoUnique-NAS.local/backup  (NAS 로그인)
       05_dotfiles.tar.gz 의 .ssh 복원 → 권한 700/600/644 → ssh -T git@github.com
       GitHub에 없는 키면: gh auth login (기존 키 업로드 선택)
EOF
  ;;
  2) cat <<'EOF'
  1) SSH 키 — gh로 새로 생성
       gh auth login   (GitHub.com / SSH / 키 생성 Yes / passphrase / 브라우저 인증)
       ssh -T git@github.com
EOF
  ;;
  *) echo "  1) SSH 키 — 나중에 (SETUP-LOG 27번 참고)" ;;
esac
cat <<EOF

  2) 손쉬운 사용 권한 — Rectangle, Ghostty (켠 뒤 앱 재시작)
       시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용
       Ghostty는 목록에 없으면 + 로 /Applications/Ghostty.app 추가

  3) Chrome을 기본 브라우저로
       시스템 설정 > 데스크탑 및 Dock > 기본 웹 브라우저

  4) App Store 앱 직접 설치: ${MAS_LIST:-없음}
EOF

step "완료"
check
