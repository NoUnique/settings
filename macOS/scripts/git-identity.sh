#!/usr/bin/env bash
# git 전역 신원
#
# 값의 근거: GitHub 공개 저장소 커밋의 author 필드에서 확인한 실제 사용 값.
# 프로필 API의 name/email은 비공개라 답이 안 나왔다. 커밋 기록이 근거다.
#   curl -sS "https://api.github.com/repos/NoUnique/<repo>/commits?author=NoUnique" \
#     → commit.author.{name,email} 집계
# 기존 커밋과 신원이 어긋나면 GitHub 기여 그래프가 끊기므로 값을 맞춰야 한다.

set -euo pipefail

NAME="NoUnique"
EMAIL="kofmap@gmail.com"

git config --global user.name  "$NAME"
git config --global user.email "$EMAIL"

echo "    git 신원: $(git config --global user.name) <$(git config --global user.email)>"
