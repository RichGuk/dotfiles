if application "Firefox" is not running then
    activate application "Firefox"
else
    tell application "System Events" to tell process "Firefox"
        tell application "Firefox" to activate
        keystroke "n" using command down
        activate
    end tell
end if
