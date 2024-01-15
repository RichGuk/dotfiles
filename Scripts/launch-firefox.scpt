if application "Firefox" is not running then
    activate application "Firefox"
else
    tell application "System Events" to tell process "Firefox"
        tell application "Firefox" to activate
        click menu item "New Window" of menu "File" of menu bar 1
        activate
    end tell
end if
