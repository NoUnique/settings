#!/usr/bin/env bash
# ~/.zshrc 링크
#
# 저장소의 config/zsh/zshrc 를 ~/.zshrc 로 심볼릭 링크한다.
# 다음 맥에서는 저장소만 클론하면 셸 설정이 따라온다.
#
# ⚠️ ~/.zprofile 은 건드리지 않는다. PATH(brew shellenv)는 그쪽 담당이고,
#    ~/.zshrc 는 대화형 셸용이다. 자세한 이유는 파일 상단 주석 참고.

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/config/zsh/zshrc"
DST="$HOME/.zshrc"

if [ -e "$DST" ] && [ ! -L "$DST" ]; then
  mv "$DST" "$DST.bak.$(date +%Y%m%d%H%M%S)"
  echo "    기존 ~/.zshrc를 .bak으로 백업"
fi

ln -sfn "$SRC" "$DST"
echo "    $DST → $SRC"

# 문법 검사 (실행하지 않고 파싱만)
if zsh -n "$SRC" 2>/dev/null; then
  echo "    문법 검사 통과"
else
  echo "    ⚠️ 문법 오류:"
  zsh -n "$SRC" 2>&1 | sed 's/^/      /'
  exit 1
fi

# 자동완성이 실제로 로드되는지 확인
if zsh -ic 'type compdef >/dev/null 2>&1' 2>/dev/null; then
  echo "    compinit 로드 확인"
else
  echo "    ⚠️ compinit이 로드되지 않았다"
fi
