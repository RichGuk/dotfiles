pragma Singleton

// Battery and power profile, through Quickshell's UPower service.
// Hides itself (present = false) when UPower reports no battery, as on a desktop.

import QtQuick
import Quickshell
import Quickshell.Services.UPower
// Battery glyph is an index into a ramp, so it is resolved here rather than in the views.
import qs.theme

Singleton {
    id: root

    readonly property var device: UPower.displayDevice

    readonly property bool present:
        !!device
        && device.isPresent
        && device.type === UPowerDeviceType.Battery

    // Quickshell scales UPower's percentage to 0..1 on the way in.
    // healthPercentage is NOT transformed and really is 0..100.
    readonly property int percent:
        present ? Math.round(device.percentage * 100) : 0

    readonly property real fraction: present ? device.percentage : 0

    // ------------------------------------------------------------------
    // State. `onAc` comes from UPower, not the device state: a full battery
    // on mains reports FullyCharged, not Charging.
    // ------------------------------------------------------------------
    readonly property bool onAc: !UPower.onBattery

    readonly property bool charging: present && (
        device.state === UPowerDeviceState.Charging
        || device.state === UPowerDeviceState.PendingCharge)

    readonly property bool fullyCharged:
        present && device.state === UPowerDeviceState.FullyCharged

    readonly property bool discharging: present && (
        device.state === UPowerDeviceState.Discharging
        || device.state === UPowerDeviceState.PendingDischarge)

    // ------------------------------------------------------------------
    // Numbers worth showing.
    // ------------------------------------------------------------------
    // 0 when unknown -- UPower reports 0, not null, for a while after a state change.
    readonly property real secondsRemaining:
        !present ? 0
        : charging ? device.timeToFull
        : discharging ? device.timeToEmpty
        : 0

    // Watts, always positive; direction is the state.
    readonly property real watts: present ? device.changeRate : 0

    readonly property real energy: present ? device.energy : 0
    readonly property real energyCapacity: present ? device.energyCapacity : 0

    readonly property bool healthKnown:
        present && device.healthSupported && device.healthPercentage > 0
    readonly property int health:
        healthKnown ? Math.round(device.healthPercentage) : 0

    // ------------------------------------------------------------------
    // How the bar should draw it.
    // ------------------------------------------------------------------
    readonly property bool critical:
        present && discharging && percent <= Theme.batteryCriticalAt
    readonly property bool low:
        present && discharging && percent <= Theme.batteryWarnAt

    readonly property string glyph: {
        if (!present) return Theme.glyph("batteryOff");
        if (root.critical) return Theme.glyph("batteryAlert");

        // Bolt ramp whenever on mains, not only while charging.
        return Theme.batteryGlyph(root.percent, root.onAc);
    }

    readonly property color color:
        !present ? Theme.barDim
        : root.critical ? Theme.attention
        : root.low ? Theme.warning
        : Theme.barText

    readonly property string statusLine: {
        if (!present) return "No battery";
        if (root.fullyCharged) return root.onAc ? "Fully charged" : "Full";
        if (root.secondsRemaining > 0) {
            return root.formatSpan(root.secondsRemaining)
                 + (root.charging ? " until full" : " remaining");
        }
        if (root.charging) return "Charging";
        if (root.discharging) return "Estimating…";
        return root.onAc ? "On mains" : "Unknown";
    }

    function formatSpan(seconds) {
        const total = Math.round(seconds / 60);
        const h = Math.floor(total / 60);
        const m = total % 60;
        if (h <= 0) return m + "m";
        return h + "h " + m + "m";
    }

    // ------------------------------------------------------------------
    // Peripherals with their own batteries.
    // ------------------------------------------------------------------
    readonly property var peripherals: {
        const out = [];
        if (!UPower.devices) return out;
        for (const d of UPower.devices.values) {
            if (!d || !d.ready || !d.isPresent) continue;
            if (d === UPower.displayDevice) continue;
            // The laptop's own battery is already the display device.
            if (d.type === UPowerDeviceType.LinePower) continue;
            if (d.type === UPowerDeviceType.Battery) continue;
            if (!(d.percentage > 0)) continue;   // 0..1, see above
            out.push(d);
        }
        return out;
    }

    // The one the bar shows when there is no battery of our own, as on a desktop.
    readonly property var lowestPeripheral: {
        let low = null;
        for (const d of root.peripherals) {
            if (!low || d.percentage < low.percentage) low = d;
        }
        return low;
    }

    // Whether the bar module has anything to show at all.
    readonly property bool anything: present || !!lowestPeripheral

    // Just an icon; the percentage only matters when the machine itself is
    // running on battery. Everything else is in the popout.
    readonly property string barText: {
        if (!present) return Theme.glyph("battery");
        if (!onAc) return root.glyph + " " + root.percent + "%";
        return root.glyph;
    }

    // Our own battery wins; otherwise a low peripheral still tints the icon.
    readonly property color barColor: {
        if (root.critical || root.low) return root.color;
        if (!lowestPeripheral) return root.present ? root.color : Theme.barText;
        const p = peripheralPercent(lowestPeripheral);
        return p <= Theme.batteryCriticalAt ? Theme.attention
             : p <= Theme.batteryWarnAt ? Theme.warning
             : Theme.barText;
    }

    function peripheralGlyph(type) {
        switch (type) {
        case UPowerDeviceType.Mouse:       return Theme.glyph("mouse");
        case UPowerDeviceType.Keyboard:    return Theme.glyph("keyboard");
        case UPowerDeviceType.Headset:     return Theme.glyph("headset");
        case UPowerDeviceType.Headphones:  return Theme.glyph("headset");
        case UPowerDeviceType.GamingInput: return Theme.glyph("gamepad");
        case UPowerDeviceType.Phone:       return Theme.glyph("phone");
        default:                           return Theme.glyph("battery");
        }
    }

    // 0..100, so callers do not have to remember the transform.
    function peripheralPercent(d) {
        return d ? Math.round(d.percentage * 100) : 0;
    }

    function peripheralLabel(d) {
        if (!d) return "";
        return d.model || d.nativePath || "Unknown device";
    }

    // ------------------------------------------------------------------
    // Power profiles (power-profiles-daemon). Performance may be absent, hence
    // hasPerformanceProfile. With ppd missing this reads Balanced and setting
    // it silently does nothing; there is no property to detect that.
    // ------------------------------------------------------------------
    readonly property int profile: PowerProfiles.profile

    function setProfile(p) {
        PowerProfiles.profile = p;
    }

    readonly property var profileOptions: {
        const out = [
            { value: PowerProfile.PowerSaver, label: "Power saver",
              glyph: "leaf" },
            { value: PowerProfile.Balanced, label: "Balanced",
              glyph: "scaleBalance" }
        ];
        if (PowerProfiles.hasPerformanceProfile) {
            out.push({ value: PowerProfile.Performance, label: "Performance",
                       glyph: "speedometer" });
        }
        return out;
    }

    readonly property string degradedReason: {
        switch (PowerProfiles.degradationReason) {
        case PerformanceDegradationReason.LapDetected:
            return "Throttled: on your lap";
        case PerformanceDegradationReason.HighTemperature:
            return "Throttled: running hot";
        default:
            return "";
        }
    }
}
