#!/usr/bin/env bash
# 화면에 이미 떠 있는 알림 배너 전부 닫기
#
# notifications-off.sh는 "앞으로 올 알림"을 막는다. 이미 전달되어 우측 상단에 쌓여 있는
# 배너는 그것과 별개로 남으므로 따로 닫아야 한다.
#
# ── 배너의 접근성 경로 ────────────────────────────────────────
#   NotificationCenter 프로세스
#   └ window 1  (전체 화면 크기 1680x1050 — 이게 배너 컨테이너)
#     └ group 1 → group 1 → scroll area 1
#
#   ⚠️ scroll area 아래 구조가 배너 개수에 따라 달라진다:
#      여러 개: scroll area → group(컨테이너) → group, group, ...  ← 각각이 배너
#      한 개  : scroll area → group                                ← 이게 곧 배너
#   그래서 "static text를 직접 가진 group"을 배너로 판정한다.
#
#   같은 프로세스에 180x180 / 360x180 window가 더 있는데 그건 위젯이다(날씨 등).
#
# ── 닫기 방법 ─────────────────────────────────────────────────
#   닫기(X) 버튼은 마우스를 올려야 AX 트리에 나타난다(호버 전 buttons=0 확인).
#   `killall NotificationCenter`로는 지워지지 않는다 — DB에 남아 재표시된다.
#   따라서 cliclick으로 호버 → click button 이 유일한 경로다.
#
#   ※ 마우스를 움직이므로 백그라운드 데몬으로 상시 실행하기엔 부적절하다
#     (사용자 커서를 뺏는다). 작업 끝에 한 번씩 호출하는 용도.
#
# 필요: 손쉬운 사용 권한, cliclick

set -euo pipefail
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
command -v cliclick >/dev/null || { echo "    cliclick 없음 (brew install cliclick)"; exit 0; }

# 첫 번째 배너의 중심 좌표를 반환. 없으면 빈 문자열.
FIRST='tell application "System Events" to tell process "NotificationCenter"
  try
    set sa to scroll area 1 of group 1 of group 1 of window 1
  on error
    return ""
  end try
  set b to missing value
  repeat with g in (groups of sa)
    if (count of static texts of g) > 0 then
      set b to g
      exit repeat
    end if
    repeat with h in (groups of g)
      if (count of static texts of h) > 0 then
        set b to h
        exit repeat
      end if
    end repeat
    if b is not missing value then exit repeat
  end repeat
  if b is missing value then return ""
  set p to position of b
  set s to size of b
  return (((item 1 of p) + (item 1 of s) / 2) as integer as string) & " " & ¬
         (((item 2 of p) + (item 2 of s) / 2) as integer as string)
end tell'

CLOSE='tell application "System Events" to tell process "NotificationCenter"
  set sa to scroll area 1 of group 1 of group 1 of window 1
  repeat with g in (groups of sa)
    if (count of buttons of g) > 0 then
      click button 1 of g
      return "ok"
    end if
    repeat with h in (groups of g)
      if (count of buttons of h) > 0 then
        click button 1 of h
        return "ok"
      end if
    end repeat
  end repeat
  return "no-button"
end tell'

closed=0
for _ in $(seq 1 20); do
  coords=$(osascript -e "$FIRST" 2>/dev/null || true)
  [ -z "${coords// /}" ] && break
  read -r cx cy <<<"$coords"
  [ -n "${cy:-}" ] || break
  cliclick m:"$cx","$cy" >/dev/null; sleep 0.6
  osascript -e "$CLOSE" >/dev/null 2>&1 || true
  closed=$((closed + 1))
  sleep 0.8
done

cliclick m:840,600 >/dev/null   # 커서를 배너 영역 밖으로
left=$(osascript -e "$FIRST" 2>/dev/null || true)
if [ -z "${left// /}" ]; then
  echo "    배너 ${closed}개 닫음, 남은 것 없음"
else
  echo "    배너 ${closed}개 닫음, 아직 남아 있음"
fi
