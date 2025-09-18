(*
if application "WezTerm" is not running then
    activate application "WezTerm"
else
    tell application "System Events" to tell process "WezTerm"
        click menu item "New Window" of menu "Shell" of menu bar 1
        activate
    end tell
end if
*)

if application "kitty" is not running then
    activate application "kitty"
else
    tell application "System Events" to tell process "kitty"
        click menu item "New OS window" of menu "Shell" of menu bar 1
        activate
    end tell
end if
