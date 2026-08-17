#!/usr/bin/env bash
# ~/.ssh/config — SSH 키 passphrase를 macOS 키체인에 연동
#
# 키 생성/GitHub 등록은 `gh auth login`이 대신해준다 (setup.sh 마지막 안내 참고).
# 하지만 gh는 passphrase 키체인 연동은 해주지 않는다. 그게 이 스크립트의 몫.
#
#   UseKeychain yes    passphrase를 키체인에 저장 → 재부팅 후에도 다시 묻지 않음
#   AddKeysToAgent yes 키를 ssh-agent에 자동 등록 → 별도 ssh-add 불필요
#
# 두 옵션 덕분에 최초 1회 접속(`ssh -T git@github.com`) 때 입력한 passphrase가
# 그대로 키체인에 들어간다.

set -euo pipefail

mkdir -p ~/.ssh
chmod 700 ~/.ssh

if grep -q "^Host github.com" ~/.ssh/config 2>/dev/null; then
  echo "    ~/.ssh/config에 github.com 항목이 이미 있음 — 건너뜀"
  exit 0
fi

cat >> ~/.ssh/config <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  UseKeychain yes
EOF

chmod 600 ~/.ssh/config
echo "    ~/.ssh/config 작성 완료"

# 검증: 키가 있으면 지문 비교 (agent 등록 여부는 ssh -T 이후에 확인 가능)
if [ -f ~/.ssh/id_ed25519.pub ]; then
  echo "    로컬 키 지문: $(ssh-keygen -lf ~/.ssh/id_ed25519.pub | awk '{print $2}')"
fi
