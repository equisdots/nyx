pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../../core"

// ═══════════════════════════════════════════════════════════════════════════
// MascotsCatalog — Nyx's discovery (mascot species + notch cards).
//
// Ships with the plugin (catalog/), deployed in the shell tree next to the
// rest of the UI. It reaches the shell only through the documented kit paths
// (`../../../../core` for PluginsCatalog).
//
// Sources, in precedence order:
//   1. the user dirs (`~/.config/hypr/mascots/species/` | `notch/`) — they win
//      on id collisions;
//   2. every installed plugin that *provides* mascots content: a plugin
//      declares `"provides": { "mascots": { "species"?, "cards"? } }` (paths
//      relative to its UI root). Nyx declares its own (`mascots`, `notch`).
//
// The scan (`mascots_scan.sh`, next to this file) merges the dirs and exposes:
//   mascots  [{ id, label, icon, entry?, builtin?, _base, ... }] — one per
//            species. `entry` (a QML file, resolved against `_base`) marks a
//            custom species; without it the species is a built-in kind.
//   things   [{ id, label, icon, thumb?, exec?, enabled?, _base, ... }] — one
//            per notch card.
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: catalog

    readonly property string home: Quickshell.env("HOME")
    // The scan script ships next to this singleton.
    readonly property string script: String(Qt.resolvedUrl("mascots_scan.sh")).replace(/^file:\/\//, "")
    readonly property string mascotsUser: home + "/.config/hypr/mascots/species"
    readonly property string thingsUser: home + "/.config/hypr/mascots/notch"

    // Provider entries: [{ plugin, rel }] for a `provides.mascots.<key>`.
    function providers(key) {
        PluginsCatalog.rev; // re-evaluate when the plugin catalog updates
        let out = [];
        let list = PluginsCatalog.plugins || [];
        for (let i = 0; i < list.length; i++) {
            let p = list[i] || {};
            let m = (p.provides && typeof p.provides === "object"
                     && p.provides.mascots && typeof p.provides.mascots === "object")
                    ? p.provides.mascots : null;
            if (m && typeof m[key] === "string" && m[key] !== "")
                out.push({ plugin: p, rel: m[key] });
        }
        return out;
    }

    readonly property var speciesDirs: {
        let ps = catalog.providers("species");
        let out = [];
        for (let i = 0; i < ps.length; i++)
            out.push(PluginsCatalog.uiPath(ps[i].plugin, ps[i].rel));
        return out;
    }
    readonly property var cardsDirs: {
        let ps = catalog.providers("cards");
        let out = [];
        for (let i = 0; i < ps.length; i++)
            out.push(PluginsCatalog.uiPath(ps[i].plugin, ps[i].rel));
        return out;
    }

    property var mascots: []
    property var things: []

    function refresh() { scan.running = false; scan.running = true }

    function orderOf(x) { return (x && x.order !== undefined) ? Number(x.order) : 1000 }
    function sortItems(a) {
        return a.slice().sort(function (x, y) {
            let ox = catalog.orderOf(x), oy = catalog.orderOf(y);
            if (ox !== oy) return ox - oy;
            return String(x.label || x.id || "").localeCompare(String(y.label || y.id || ""));
        });
    }

    // Rescan when the plugin catalog changes: a provider may have appeared,
    // been removed or moved.
    Connections {
        target: PluginsCatalog
        function onRevChanged() { catalog.refresh() }
    }

    Process {
        id: scan
        running: true
        clearEnvironment: false
        environment: ({
            MASCOTS_SHIPPED: catalog.speciesDirs.join(":"),
            MASCOTS_USER: catalog.mascotsUser,
            THINGS_SHIPPED: catalog.cardsDirs.join(":"),
            THINGS_USER: catalog.thingsUser
        })
        command: ["bash", catalog.script]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let o = JSON.parse(this.text);
                    catalog.mascots = catalog.sortItems(o.mascots || []);
                    catalog.things = catalog.sortItems(o.things || []);
                } catch (e) {}
            }
        }
    }
}
