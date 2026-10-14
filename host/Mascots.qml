import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../core"
import "../../../../core/WindowRegistry.js" as Registry
import "../../../bar"
import "../front"
import "../catalog"

// ═══════════════════════════════════════════════════════════════════════════
// Mascots — Nyx's host adapter (equisdots plugin standard).
//
// Ships in the plugin repo and is deployed with the plugin UI; the shell
// mounts it generically (ui/PluginHosts.qml) when the manifest declares
// `"host": "host/Mascots.qml"`. Running inside the shell tree it imports the
// core kit directly: the live palette, the settings file path, the
// widget-occlusion hooks, the widget list/launcher used by the dock, plus
// live data (quick-action states, system stats, persisted favorites).
//
// It also publishes `frameObstacle` — the island rects (one per screen) the
// screen frame should hug — which PluginHosts republishes through FrameBus.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    visible: false
    width: 0
    height: 0

    Colors { id: themeColors }

    Caching { id: paths }

    // ── favorites (persisted in settings.json → mascots.dock.favorites) ────
    readonly property var favorites: {
        Config.rev; // re-evaluate whenever settings mutate
        let m = Config.rawSettings.mascots || {};
        let d = m.dock || {};
        return (d.favorites && d.favorites.length !== undefined) ? d.favorites : [];
    }
    function toggleFavorite(id) {
        let m = Object.assign({}, Config.rawSettings.mascots || {});
        let d = Object.assign({}, m.dock || {});
        let f = (d.favorites && d.favorites.length !== undefined) ? d.favorites.slice() : [];
        let i = f.indexOf(String(id));
        if (i >= 0) f.splice(i, 1); else f.push(String(id));
        d.favorites = f;
        m.dock = d;
        Config.setSetting("mascots", m);
    }

    // ── quick-action states (Wi-Fi / Bluetooth / mute), polled ─────────────
    property var qaState: ({ wifi: false, bt: false, mute: false })
    function refreshQuick() { qaProc.running = false; qaProc.running = true; }
    Process {
        id: qaProc
        command: ["bash", "-c",
            "w=$(nmcli -t -f WIFI g 2>/dev/null); " +
            "b=$(bluetoothctl show 2>/dev/null | grep -c 'Powered: yes'); " +
            "m=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -c MUTED); " +
            "printf '%s|%s|%s' \"$w\" \"$b\" \"$m\""]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.trim().split("|");
                root.qaState = {
                    wifi: p[0] === "enabled",
                    bt: parseInt(p[1]) > 0,
                    mute: parseInt(p[2]) > 0
                };
            }
        }
    }
    Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: root.refreshQuick()
    }
    function runQuick(id) {
        const mgr = Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh";
        let args = null;
        if (id === "network") args = ["toggle", "network", "wifi"];
        else if (id === "bluetooth") args = ["toggle", "network", "bt"];
        else if (id === "volume") args = ["toggle", "volume"];
        else if (id === "music") args = ["toggle", "music"];
        if (args) Quickshell.execDetached([mgr].concat(args));
        else Quickshell.execDetached([mgr, "open", String(id)]);
        refreshTimer.restart();
    }
    Timer { id: refreshTimer; interval: 300; onTriggered: root.refreshQuick() }

    readonly property var quickActions: [
        { id: "network",        label: "Wi-Fi",  icon: "󰖩", active: root.qaState.wifi },
        { id: "bluetooth",      label: "BT",     icon: "󰂯", active: root.qaState.bt },
        { id: "volume",         label: "Volume", icon: "󰕾", active: !root.qaState.mute },
        { id: "music",          label: "Music",  icon: "󰝚", active: false },
        { id: "system-monitor", label: "Stats",  icon: "󰨇", active: false }
    ]

    // ── live system stats ──────────────────────────────────────────────────
    readonly property var stats: [
        { id: "cpu",  label: "CPU",  icon: "", value: SysData.cpu + "%",         frac: SysData.cpu / 100 },
        { id: "ram",  label: "RAM",  icon: "", value: SysData.ramPercent + "%",  frac: SysData.ramPercent / 100 },
        { id: "temp", label: "TEMP", icon: "", value: SysData.temp + "°",        frac: Math.min(1, SysData.temp / 100) }
    ]
    Component.onCompleted: SysData.subscribe()
    Component.onDestruction: SysData.unsubscribe()

    // Live wallpaper preview for the Davincix card: davincix repaints
    // current_wallpaper.png whenever the background changes; watching the file
    // bumps wallpaperRev so the dock thumbnail reloads with a fresh URL.
    readonly property string wallpaperPreviewPath: paths.getCacheDir("wallpaper_picker") + "/current_wallpaper.png"
    property int wallpaperRev: 0

    FileView {
        path: root.wallpaperPreviewPath
        watchChanges: true
        blockLoading: true
        onFileChanged: root.wallpaperRev++
    }

    // ── notch cards ("things") ─────────────────────────────────────────────
    // Discovered from the provider and user dirs by MascotsCatalog; a user
    // file can add a card or override a shipped one. An entry may carry
    // "exec" (a shell command) instead of opening a shell panel.
    readonly property var notchWidgets: {
        let t = MascotsCatalog.things || [];
        let out = [];
        for (let i = 0; i < t.length; i++) {
            let x = t[i];
            if (!x || x.enabled === false || !x.id) continue;
            let e = { id: String(x.id), label: x.label || String(x.id), icon: x.icon || "" };
            if (x.thumb) e.thumb = x.thumb;
            if (String(x.id) === "wallpaper")
                e.thumb = "file://" + root.wallpaperPreviewPath + "?v=" + root.wallpaperRev;
            out.push(e);
        }
        return out;
    }
    function thingExec(id) {
        let t = MascotsCatalog.things || [];
        for (let i = 0; i < t.length; i++)
            if (t[i] && String(t[i].id) === String(id) && t[i].exec) return String(t[i].exec);
        return "";
    }

    // ── overlay ────────────────────────────────────────────────────────────
    MascotsOverlay {
        palette: themeColors
        settingsPath: Quickshell.env("HOME") + "/.config/hypr/settings.json"
        widgetStatePath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell/current_widget"
        dockWidgetName: "applauncher"
        widgetRectProvider: function(name, sw, sh, scale) {
            return Registry.getLayout(name, 0, 0, sw, sh, scale);
        }
        mascotCatalog: MascotsCatalog.mascots
        widgetList: root.notchWidgets
        quickActions: root.quickActions
        quickHandler: function(id) { root.runQuick(id); }
        stats: root.stats
        favorites: root.favorites
        onFavoriteToggled: (id) => root.toggleFavorite(id)
        widgetLauncher: function(id) {
            let exec = root.thingExec(id);
            if (exec !== "") { Quickshell.execDetached(["bash", "-c", exec]); return; }
            Quickshell.execDetached([
                Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh",
                "open", String(id)
            ]);
        }
    }

    // ── frame obstacle (generic host contract) ─────────────────────────────
    // One rect per screen; the screen frame (ui/frame/Frame.qml) hugs them.
    // avoidReserve: the island is anchored to its edge, so the frame must not
    // reserve it (a strut would push the island off the screen edge).
    readonly property var frameObstacle: {
        Config.rev;
        let s = Config.rawSettings || {};
        let m = s.mascots || {};
        if (m.enabled !== true) return [];
        let uiScale = (s.uiScale !== undefined) ? s.uiScale : 1.0;
        let bar = s.bar || {};
        let out = [];
        let screens = Quickshell.screens || [];
        for (let i = 0; i < screens.length; i++) {
            let scr = screens[i];
            let k = Registry.getScale(scr.width, scr.height, uiScale);
            let o = root.obstacleFor(m, bar, scr.width, scr.height, k);
            if (o) { o.screen = scr.name; out.push(o); }
        }
        return out;
    }

    // Mirrors front/MascotsOverlay.qml geometry so the bay matches the real
    // island/notch. `k` is the shell scale (overlay.s()).
    function obstacleFor(m, bar, width, height, k) {
        var pos = String(m.position || "top-center");
        var notch = String(m.appearance || "island").toLowerCase() === "notch";
        var count = Math.max(1, Math.min(3, Math.round(Number(m.count) || 1)));
        var scale = Math.min(1.6, Math.max(0.6, Number(m.size) || 1));
        var ns = Number(m.notchHeight) || 0;
        var nw = Number(m.notchWidth) || 260;
        var nOff = Number(m.notchOffset) || 0;
        var barThick = Number(bar.thickness) || 48;
        var barBottom = String(bar.position || "top") === "bottom";

        var pillW = (48 * k * count + 32 * k) * scale;
        var pillH = 46 * k * scale;
        var notchH = notch
            ? (ns > 0 ? Math.max(pillH + 6 * k, ns * k) : Math.max(pillH + 10 * k, 38 * k))
            : pillH;
        var notchW = notch
            ? Math.max(pillW + 20 * k, Math.min(width * 0.5, Math.max(80, nw) * k))
            : pillW;
        var off = nOff * k;
        var edgeMargin = (barBottom ? 14 : barThick + 14) * k;

        function along(total, span) {
            if (pos.indexOf("left") !== -1 && pos.indexOf("center") === -1) return { a: 0, b: Math.round(span) };
            if (pos.indexOf("right") !== -1 && pos.indexOf("center") === -1) return { a: Math.round(total - span), b: Math.round(total) };
            return { a: Math.round((total - span) / 2), b: Math.round((total + span) / 2) };
        }

        var o = { avoidReserve: true };
        if (pos.indexOf("top") !== -1) {
            var at = along(width, notchW);
            o.edge = "top"; o.a = at.a; o.b = at.b;
            o.depth = notch ? (off + notchH) : (edgeMargin + pillH + off);
            return o;
        }
        if (pos.indexOf("bottom") !== -1) {
            var ab = along(width, notchW);
            o.edge = "bottom"; o.a = ab.a; o.b = ab.b;
            o.depth = height - (notch ? (off + notchH) : (edgeMargin + pillH + off));
            return o;
        }
        if (pos.indexOf("left") !== -1) {
            var al = along(height, notchH);
            o.edge = "left"; o.a = al.a; o.b = al.b;
            o.depth = notch ? (off + notchW) : (edgeMargin + pillW + off);
            return o;
        }
        if (pos.indexOf("right") !== -1) {
            var ar = along(height, notchH);
            o.edge = "right"; o.a = ar.a; o.b = ar.b;
            o.depth = width - (notch ? (off + notchW) : (edgeMargin + pillW + off));
            return o;
        }
        return null;
    }
}
