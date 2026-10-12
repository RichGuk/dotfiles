pragma Singleton

// Live weather from Open-Meteo (keyless), fetched with XMLHttpRequest.
// Default model blend on purpose: the ukmo_* models return no
// precipitation_probability_max.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ------------------------------------------------------------------
    // Where. `follow` tracks the IP-detected city; `pinned` is a chosen place.
    // Detection keeps running while pinned so the popout can offer a switch
    // when it lands far away -- never switched silently.
    // ------------------------------------------------------------------
    readonly property string modeFollow: "follow"
    readonly property string modePinned: "pinned"

    readonly property string mode: store.adapter.mode || modeFollow
    readonly property var pinned: store.adapter.pinned
    readonly property var detected: store.adapter.detected

    readonly property var location:
        mode === modePinned && pinned ? pinned : detected

    readonly property string placeName:
        location ? location.name : "Locating…"
    readonly property string placeRegion:
        location ? (location.region || "") : ""

    readonly property var savedLocations: store.adapter.saved

    // ------------------------------------------------------------------
    // Have we moved away from the pin? Only meaningful while pinned.
    // ------------------------------------------------------------------
    property int awayThresholdKm: 75

    readonly property real distanceFromPinnedKm:
        (pinned && detected) ? root.distanceKm(pinned, detected) : 0

    readonly property bool awayFromPinned:
        mode === modePinned
        && !!pinned && !!detected
        && distanceFromPinnedKm > awayThresholdKm

    // Haversine.
    function distanceKm(a, b) {
        const R = 6371;
        const dLat = (b.lat - a.lat) * Math.PI / 180;
        const dLon = (b.lon - a.lon) * Math.PI / 180;
        const la1 = a.lat * Math.PI / 180;
        const la2 = b.lat * Math.PI / 180;
        const h = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(la1) * Math.cos(la2)
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 2 * R * Math.asin(Math.sqrt(h));
    }

    FileView {
        id: store

        path: (Quickshell.env("XDG_STATE_HOME")
               || Quickshell.env("HOME") + "/.local/state")
              + "/hyprland-shell/weather.json"

        watchChanges: true
        atomicWrites: true
        printErrors: false          // a missing file on first run is normal

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            // "follow" or "pinned"
            property string mode: "follow"
            // { name, region, lat, lon }
            property var pinned: null
            // last IP-detected place, kept while pinned so travel is noticed
            property var detected: null
            property string detectedAt: ""
            // saved places, same shape
            property var saved: []
        }
    }

    // ------------------------------------------------------------------
    // Choosing where
    // ------------------------------------------------------------------
    // Pin a place, switching to pinned mode.
    function select(loc) {
        store.adapter.pinned = loc;
        store.adapter.mode = root.modePinned;
    }

    function follow() {
        store.adapter.mode = root.modeFollow;
        if (!store.adapter.detected)
            root.geolocate();
    }

    function save(loc) {
        const list = (store.adapter.saved || []).slice();
        if (!list.some(l => root.sameSpot(l, loc)))
            list.push(loc);
        store.adapter.saved = list;
    }

    function forget(loc) {
        store.adapter.saved =
            (store.adapter.saved || []).filter(l => !root.sameSpot(l, loc));
    }

    // By coordinates: names collide and geocoding varies casing and region.
    function sameSpot(a, b) {
        return a && b
            && Math.abs(a.lat - b.lat) < 0.01
            && Math.abs(a.lon - b.lon) < 0.01;
    }

    // ------------------------------------------------------------------
    // IP geolocation (ip-api). Writes `detected` only, never `mode`, so it
    // cannot override a pin. Persisted, so a restart draws immediately.
    // ------------------------------------------------------------------
    property bool geolocating: false

    function geolocate() {
        if (root.geolocating) return;
        root.geolocating = true;

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            root.geolocating = false;

            if (xhr.status !== 200) {
                root.fail("geolocation failed: HTTP " + xhr.status);
                return;
            }

            try {
                const d = JSON.parse(xhr.responseText);
                if (d.status !== "success") {
                    root.fail("geolocation failed: " + (d.message || "unknown"));
                    return;
                }
                store.adapter.detected = {
                    name:   d.city,
                    region: d.regionName || d.country || "",
                    lat:    d.lat,
                    lon:    d.lon
                };
                store.adapter.detectedAt = new Date().toISOString();
            } catch (e) {
                root.fail("geolocation returned junk: " + e);
            }
        };

        // http: ip-api's free tier is http-only.
        xhr.open("GET", "http://ip-api.com/json/?fields=status,message,city,regionName,country,lat,lon");
        xhr.send();
    }

    // ------------------------------------------------------------------
    // Search by name, via Open-Meteo's geocoding API.
    // ------------------------------------------------------------------
    property var searchResults: []
    property bool searching: false

    function search(query) {
        const q = (query || "").trim();
        if (q.length < 2) {
            root.searchResults = [];
            return;
        }

        root.searching = true;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            root.searching = false;

            if (xhr.status !== 200) {
                root.searchResults = [];
                return;
            }

            try {
                const d = JSON.parse(xhr.responseText);
                root.searchResults = (d.results || []).map(r => ({
                    name:   r.name,
                    // admin1 (county/state) disambiguates same-named places.
                    region: [r.admin1, r.country].filter(Boolean).join(", "),
                    lat:    r.latitude,
                    lon:    r.longitude
                }));
            } catch (e) {
                root.searchResults = [];
            }
        };

        xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search"
            + "?name=" + encodeURIComponent(q)
            + "&count=6&language=en&format=json");
        xhr.send();
    }

    // Days in the forecast list. Open-Meteo allows up to 16.
    property int forecastDays: 7

    // ------------------------------------------------------------------
    // State
    // ------------------------------------------------------------------
    readonly property string stateLoading: "loading"
    readonly property string stateOk:      "ok"
    readonly property string stateError:   "error"

    property string state: stateLoading
    property string lastError: ""

    // Last SUCCESSFUL fetch, separate from `state`, so a failed refresh keeps
    // showing old data.
    property var fetchedAt: null

    readonly property bool stale:
        fetchedAt !== null
        && (new Date().getTime() - fetchedAt.getTime()) > staleAfterMs

    property int staleAfterMs: 2 * 60 * 60 * 1000   // two hours

    // ------------------------------------------------------------------
    // Data
    // ------------------------------------------------------------------
    property var current: null    // { temp, cond, summary, high, low, rain }
    property var forecast: []     // [{ day, date, cond, high, low, rain }]

    // Never null, for views to read fields off: QML evaluates bindings on
    // invisible items, so `visible: !!Weather.current` does not guard them.
    // `cond` must be a real glyph key.
    readonly property var blankCurrent: ({
        temp: "", cond: "wxCloudy", summary: "", high: "", low: "", rain: 0
    })

    readonly property var currentOr: current || blankCurrent

    // ------------------------------------------------------------------
    // WMO weather codes. `cond` names a key in Theme.glyphs.
    // ------------------------------------------------------------------
    readonly property var wmo: ({
        0:  { cond: "wxSunny",   summary: "Clear" },
        1:  { cond: "wxSunny",   summary: "Mainly clear" },
        2:  { cond: "wxPartly",  summary: "Partly cloudy" },
        3:  { cond: "wxCloudy",  summary: "Overcast" },
        45: { cond: "wxFog",     summary: "Fog" },
        48: { cond: "wxFog",     summary: "Freezing fog" },
        51: { cond: "wxRain",    summary: "Light drizzle" },
        53: { cond: "wxRain",    summary: "Drizzle" },
        55: { cond: "wxRain",    summary: "Heavy drizzle" },
        56: { cond: "wxRain",    summary: "Freezing drizzle" },
        57: { cond: "wxRain",    summary: "Freezing drizzle" },
        61: { cond: "wxRain",    summary: "Light rain" },
        63: { cond: "wxRain",    summary: "Rain" },
        65: { cond: "wxPouring", summary: "Heavy rain" },
        66: { cond: "wxPouring", summary: "Freezing rain" },
        67: { cond: "wxPouring", summary: "Freezing rain" },
        71: { cond: "wxSnow",    summary: "Light snow" },
        73: { cond: "wxSnow",    summary: "Snow" },
        75: { cond: "wxSnow",    summary: "Heavy snow" },
        77: { cond: "wxSnow",    summary: "Snow grains" },
        80: { cond: "wxRain",    summary: "Light showers" },
        81: { cond: "wxRain",    summary: "Showers" },
        82: { cond: "wxPouring", summary: "Heavy showers" },
        85: { cond: "wxSnow",    summary: "Snow showers" },
        86: { cond: "wxSnow",    summary: "Snow showers" },
        95: { cond: "wxStorm",   summary: "Thunderstorm" },
        96: { cond: "wxHail",    summary: "Storm with hail" },
        99: { cond: "wxHail",    summary: "Storm with hail" }
    })

    function interpret(code) {
        // Unknown codes degrade to cloud rather than an empty row.
        return root.wmo[code] || { cond: "wxCloudy", summary: "" };
    }

    function url() {
        return "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + root.location.lat
            + "&longitude=" + root.location.lon
            + "&current=temperature_2m,weather_code"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,"
            + "precipitation_probability_max"
            + "&timezone=auto"
            + "&forecast_days=" + root.forecastDays;
    }

    function refresh() {
        // No location, no fetch: nothing loads until one is detected or chosen.
        if (!root.location)
            return;

        // Only show loading when there is nothing to show yet.
        if (root.current === null)
            root.state = root.stateLoading;

        const xhr = new XMLHttpRequest();

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status !== 200) {
                root.fail("HTTP " + xhr.status);
                return;
            }

            try {
                root.apply(JSON.parse(xhr.responseText));
            } catch (e) {
                root.fail("bad response: " + e);
            }
        };

        xhr.open("GET", root.url());
        xhr.send();
    }

    function fail(reason) {
        root.lastError = reason;
        // Keep whatever data we have; `stale` lets the view say so.
        root.state = root.stateError;
        console.warn("Weather: " + reason);
    }

    function apply(data) {
        const d = data.daily;
        const c = data.current;

        // Open-Meteo returns today as daily index 0.
        const todayCode = root.interpret(d.weather_code[0]);
        const nowCode = root.interpret(c.weather_code);

        root.current = {
            temp:    Math.round(c.temperature_2m),
            cond:    nowCode.cond,
            summary: nowCode.summary,
            high:    Math.round(d.temperature_2m_max[0]),
            low:     Math.round(d.temperature_2m_min[0]),
            // Can be null on some models.
            rain:    d.precipitation_probability_max[0] ?? 0
        };

        // From index 1: today is the header, not a row.
        const out = [];
        for (let i = 1; i < d.time.length; i++) {
            const when = new Date(d.time[i]);
            const code = root.interpret(d.weather_code[i]);
            out.push({
                day:  Qt.formatDateTime(when, "ddd"),
                date: when.getDate(),
                cond: code.cond,
                high: Math.round(d.temperature_2m_max[i]),
                low:  Math.round(d.temperature_2m_min[i]),
                rain: d.precipitation_probability_max[i] ?? 0
            });
        }
        root.forecast = out;

        root.fetchedAt = new Date();
        root.lastError = "";
        root.state = root.stateOk;
    }

    Component.onCompleted: {
        // Draw stored data immediately; re-detect only if the last detection is old.
        if (root.location)
            root.refresh();

        const last = store.adapter.detectedAt
            ? new Date(store.adapter.detectedAt).getTime() : 0;
        if (new Date().getTime() - last > root.redetectAfterMs)
            root.geolocate();
    }

    // ip-api's free tier allows 45 requests a minute.
    property int redetectAfterMs: 6 * 60 * 60 * 1000

    Timer {
        interval: root.redetectAfterMs
        running: true
        repeat: true
        onTriggered: root.geolocate()
    }

    // Open-Meteo updates roughly hourly.
    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // Watches `location`, not lat/lon separately, to avoid two fetches per move.
    onLocationChanged: if (root.location) root.refresh()
}
