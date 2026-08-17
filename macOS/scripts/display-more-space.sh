#!/usr/bin/env bash
# 디스플레이 스케일링을 "추가 공간"(최대 정보 밀도)으로
# = 시스템 설정 > 디스플레이 > 추가 공간
#
# 기종마다 screen id도 해상도 단계도 다르므로 값을 하드코딩하지 않는다.
# `displayplacer list`에서 가장 큰 scaling:on 모드를 골라 적용한다.
#   scaling:on  = HiDPI(레티나). 논리 해상도만 넓어지고 글자는 선명하게 유지
#   scaling:off = 진짜 저해상도. 글자가 뭉갠다. 절대 고르면 안 됨

set -euo pipefail

command -v displayplacer >/dev/null || { echo "    displayplacer 없음 — 건너뜀"; exit 0; }

LIST=$(displayplacer list)

# 내장 디스플레이의 persistent screen id
SID=$(echo "$LIST" | awk '
  /^Persistent screen id:/ { id=$4 }
  /MacBook built in screen/ { print id; exit }
')
[ -n "$SID" ] || { echo "    내장 디스플레이를 찾지 못함 — 건너뜀"; exit 0; }

# scaling:on 모드 중 가로 해상도가 가장 큰 것
BEST=$(echo "$LIST" | grep "scaling:on" \
  | sed -E 's/.*res:([0-9]+)x([0-9]+).*/\1 \2/' \
  | sort -rn | head -1)
W=$(echo "$BEST" | cut -d' ' -f1)
H=$(echo "$BEST" | cut -d' ' -f2)
[ -n "$W" ] || { echo "    scaling:on 모드 없음 — 건너뜀"; exit 0; }

CUR=$(echo "$LIST" | grep -m1 "^Resolution:" | awk '{print $2}')
if [ "$CUR" = "${W}x${H}" ]; then
  echo "    이미 ${W}x${H} — 건너뜀"
  exit 0
fi

displayplacer "id:${SID} res:${W}x${H} hz:60 color_depth:8 scaling:on origin:(0,0) degree:0"
echo "    ${CUR} → ${W}x${H} (추가 공간)"
