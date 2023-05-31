if application "WezTerm" is not running then
    activate application "WezTerm"
else
    tell application "System Events" to tell process "WezTerm"
        click menu item "New Window" of menu "Shell" of menu bar 1
        activate
    end tell
end if
