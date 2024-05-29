if application "Chrome" is not running then
    activate application "Chrome"
else
    tell application "System Events" to tell process "Chrome"
        tell application "Chrome" to activate
        click menu item "New Window" of menu "File" of menu bar 1
        activate
    end tell
end if
