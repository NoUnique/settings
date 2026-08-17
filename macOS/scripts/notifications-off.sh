#!/usr/bin/env bash
# 모든 앱의 알림 끄기 (시스템 설정 > 알림 > 응용 프로그램 알림)
#
# 왜 GUI 자동화인가:
#   알림 설정은 CLI가 없다. 과거 ~/Library/Preferences/com.apple.ncprefs.plist를
#   직접 고치는 방법이 있었지만 macOS 26에는 그 파일이 존재하지 않는다(확인함).
#   저장 위치와 형식이 문서화되어 있지 않으므로 접근성 API로 UI를 조작한다.
#
# 필요 권한: 손쉬운 사용 (SETUP-LOG.md 0번 항목)
#
# 멱등하다. 새 앱을 설치하면 알림이 켜진 채로 목록에 추가되므로 그때마다 다시 실행하면 된다.
#
# 참고 — 하위 설정(긴급한 알림/중요한 알림/배지/사운드)은 건드리지 않는다.
#   "알림 허용"을 끄면 전부 enabled=false 로 비활성화되어 적용되지 않는다(확인함).
#   목록에 "중요" 같은 부제가 남아 보이는 건 저장된 값의 잔상일 뿐이다.

set -euo pipefail

open "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
sleep 3

osascript <<'APPLESCRIPT'
on goBack()
  -- 상세 화면 → 목록. 사이드바 재선택은 이미 선택된 항목이라 동작하지 않고,
  -- ⌘[ 키 입력도 루프 안에서 불안정했다. 툴바의 "뒤로" 버튼이 유일하게 안정적이다.
  tell application "System Events"
    tell process "System Settings"
      click button 1 of group 1 of group 1 of toolbar 1 of front window
    end tell
  end tell
end goBack

on appListGroup()
  -- 앱 목록은 이름이 없는 버튼들의 그룹이다. 인덱스가 버전마다 바뀔 수 있으므로
  -- "버튼이 5개 넘게 들어 있는 그룹"으로 찾는다.
  tell application "System Events"
    tell process "System Settings"
      set sa to scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of front window
      set gl to missing value
      repeat with e in (UI elements of sa)
        try
          if (count of buttons of e) > 5 then set gl to e
        end try
      end repeat
      return gl
    end tell
  end tell
end appListGroup

set gl to my appListGroup()
if gl is missing value then return "앱 목록을 찾지 못했다. 손쉬운 사용 권한을 확인할 것."
tell application "System Events" to set n to count of buttons of gl

set out to ""
repeat with i from 1 to n
  try
    -- 목록 상태 보장
    repeat 5 times
      tell application "System Events" to tell process "System Settings" to set wn to name of front window
      if wn is "알림" then exit repeat
      my goBack()
      delay 0.9
    end repeat

    set g to my appListGroup()
    tell application "System Events" to tell process "System Settings" to click button i of g
    delay 1.1

    -- 상세 화면: group 1 에 [static text "알림 허용", static text 앱이름, checkbox]
    tell application "System Events"
      tell process "System Settings"
        set g1 to group 1 of scroll area 1 of group 1 of group 3 of splitter group 1 of group 1 of front window
        set nm to value of static text 2 of g1
        set cb to checkbox "알림 허용" of g1
        set v0 to value of cb
        if v0 is 1 then click cb
      end tell
    end tell
    delay 0.5
    if v0 is 1 then
      set out to out & "  " & nm & " : 켜짐 → 끔" & linefeed
    else
      set out to out & "  " & nm & " : 이미 꺼짐" & linefeed
    end if
    my goBack()
    delay 0.9
  on error
    set out to out & "  [" & i & "] 실패" & linefeed
    try
      my goBack()
      delay 0.9
    end try
  end try
end repeat
return "앱 " & n & "개" & linefeed & out
APPLESCRIPT
