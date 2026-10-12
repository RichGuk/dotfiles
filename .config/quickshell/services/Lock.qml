pragma Singleton

// Session lock state and PAM authentication, reached via `qs ipc call lock lock`.
// PAM lives here, not in the per-screen surface, so there is one conversation
// however many monitors. Nothing here locks on its own; only the calls below do.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

Singleton {
    id: root

    property bool locked: false

    // Set from the surface once the compositor confirms the lock is up.
    property bool secure: false

    readonly property bool busy: pam.active

    // Captured, not bound to pam.message: PAM clears it when the conversation ends.
    property string message: ""
    property bool messageIsError: false

    // So the surface can clear its field after a failed attempt.
    signal failed()

    function lock() {
        root.locked = true;
    }

    function unlock() {
        root.locked = false;
    }

    // Held only until PAM asks for it, then cleared.
    property string _pending: ""

    function authenticate(password) {
        if (pam.active) return;
        root.message = "";
        root.messageIsError = false;
        root._pending = password;
        pam.start();
    }

    PamContext {
        id: pam

        // Reuses hyprlock's PAM service file.
        config: "hyprlock"

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root._pending);
                return;
            }
            // Non-prompt messages are where "account expired" and friends arrive.
            if (pam.message) {
                root.message = pam.message;
                root.messageIsError = pam.messageIsError;
            }
        }

        onCompleted: result => {
            root._pending = "";
            if (result === PamResult.Success) {
                root.unlock();
            } else {
                // PAM's wording when it gave one; never silence, which reads as
                // a dropped keystroke.
                root.message = pam.message || "Incorrect password";
                root.messageIsError = true;
                root.failed();
            }
        }

        onError: err => {
            root._pending = "";
            console.warn("Lock: PAM error", err);
            root.message = "Authentication unavailable";
            root.messageIsError = true;
            root.failed();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }

        // Kept so a stuck lock can be released over SSH.
        function unlock(): void {
            root.unlock();
        }

        function status(): string {
            return root.locked ? "locked" : "unlocked";
        }
    }
}
