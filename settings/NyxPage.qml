import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.ui.bar.edit
import qs.core
import "../catalog"

// ═══════════════════════════════════════════════════════════════════════════
// NyxPage — the Nyx plugin's own settings page (equisdots plugin standard).
//
// Ships in the plugin repo (equisdots/nyx) and is deployed by dots with the
// rest of the plugin UI to <quickshell>/ui/plugins/nyx/settings/ — the
// relative imports above resolve against that deployed path, not this repo.
//
// The widget itself lives in ui/Mascots.qml (a click-through overlay): a small
// island at the top that morphs into a dock while the app launcher is open,
// with chibi mascots that follow the cursor and react to window open/close
// events. This page edits the settings.json "mascots" section.
//
// Contract: receives the BarEditor root as `bar` (bar.s(), bar.colors).
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: root
    anchors.fill: parent

    property var bar: null
    property var host: null   // injected SDK handle (equisdots/plugin-sdk)
    // Settings scope: prefer the injected handle, fall back to the Config façade.
    readonly property var _mascots: {
        if (root.host && root.host.settings) return root.host.settings.section;
        Config.rev;
        return (Config.rawSettings && typeof Config.rawSettings.mascots === "object") ? Config.rawSettings.mascots : {};
    }
    function _writeMascots(m) {
        if (root.host && root.host.settings) { root.host.settings.setMany(m); return; }
        Config.setSetting("mascots", m);
    }

    // Same defaults Nyx's front/MascotsOverlay.qml falls back to.
    property bool mEnabled: false
    property real mSize: 1.0
    property string mSpecies: "flame"
    property int mCount: 3
    property string mPosition: "top-center"
    property string mAppearance: "island"
    property real mNotchWidth: 260
    property real mNotchHeight: 0
    property real mNotchOffset: 0
    property bool mNotchReserve: true
    property string mDockStyle: "floating"
    property string mDockSize: "large"
    property int mDockColumns: 5
    property int mDockRows: 2
    property bool mDockHero: true
    property bool mDockQuick: true
    property bool mDockSearch: true
    property string mWatcherFormat: "24"
    property bool mWatcherSeconds: true
    property real mWatcherSpeed: 1.0
    property bool mWatcherMoods: true
    property bool mWatcherEye: false
    property string mProfileName: ""
    // Lineup mode: `mascots.species` is an array of enabled species ids (one
    // mascot each, in catalog order). When false, it is the legacy single
    // string and `count` repeats it.
    property bool mLineupMode: false
    property var mLineup: []

    // ── profiles ───────────────────────────────────────────────────────────
    readonly property var profilesObj: {
        let m = root._mascots || {};
        return (m.profiles && typeof m.profiles === "object") ? m.profiles : {};
    }
    readonly property var profileNames: Object.keys(root.profilesObj)
    function currentBlock() {
        let m = root._mascots || {};
        let b = {};
        ["enabled", "species", "count", "size", "position", "appearance",
         "notchWidth", "notchHeight", "notchOffset", "notchReserve"].forEach(function (k) {
            if (m[k] !== undefined) b[k] = m[k];
        });
        if (m.dock) b.dock = m.dock;
        if (m.watcher) b.watcher = m.watcher;
        return b;
    }
    function saveProfile(name) {
        if (!name) return;
        let m = Object.assign({}, root._mascots || {});
        let p = Object.assign({}, root.profilesObj);
        p[name] = root.currentBlock();
        m.profiles = p;
        root._writeMascots(m);
    }
    function loadProfile(name) {
        let m = Object.assign({}, root._mascots || {});
        let block = root.profilesObj[name];
        if (!block) return;
        let next = Object.assign({}, block);
        next.profiles = m.profiles;
        root._writeMascots(next);
        root.syncFromConfig();
    }
    function deleteProfile(name) {
        let m = Object.assign({}, root._mascots || {});
        let p = Object.assign({}, root.profilesObj);
        delete p[name];
        m.profiles = p;
        root._writeMascots(m);
    }

    readonly property var flickable: body.item ? body.item.flickable : null

    function syncFromConfig() {
        let s = (root._mascots && typeof root._mascots === "object")
                ? root._mascots : {};
        root.mEnabled = s.enabled === true;
        root.mSize = s.size !== undefined ? s.size : 1.0;
        let sp = (typeof s.species === "string") ? s.species : "flame";
        root.mSpecies = (sp === "classic") ? "flame" : sp;
        if (Array.isArray(s.species)) {
            root.mLineupMode = true;
            root.mLineup = s.species.map(function (x) { return String(x); });
        } else {
            root.mLineupMode = false;
            root.mLineup = [];
        }
        root.mCount = Math.max(1, Math.min(3, Math.round(s.count !== undefined ? s.count : 3)));
        root.mPosition = (typeof s.position === "string" && s.position !== "") ? s.position : "top-center";
        root.mAppearance = (s.appearance === "notch") ? "notch" : "island";
        root.mNotchWidth = (typeof s.notchWidth === "number") ? s.notchWidth : 260;
        root.mNotchHeight = (typeof s.notchHeight === "number") ? s.notchHeight : 0;
        root.mNotchOffset = (typeof s.notchOffset === "number") ? s.notchOffset : 0;
        root.mNotchReserve = s.notchReserve !== false;
        let dk = (s.dock && typeof s.dock === "object") ? s.dock : {};
        root.mDockStyle = (dk.style === "joined") ? "joined" : "floating";
        root.mDockSize = (typeof dk.size === "string") ? dk.size : "large";
        root.mDockColumns = (typeof dk.columns === "number") ? dk.columns : 5;
        root.mDockRows = (typeof dk.rows === "number") ? dk.rows : 2;
        root.mDockHero = dk.hero !== false;
        root.mDockQuick = dk.quick !== false;
        root.mDockSearch = dk.search !== false;
        let wt = (s.watcher && typeof s.watcher === "object") ? s.watcher : {};
        root.mWatcherFormat = (wt.format === "12") ? "12" : "24";
        root.mWatcherSeconds = wt.seconds !== false;
        root.mWatcherSpeed = (typeof wt.speed === "number") ? wt.speed : 1.0;
        root.mWatcherMoods = wt.moods !== false;
        root.mWatcherEye = wt.eye === true;
    }
    Component.onCompleted: root.syncFromConfig()

    // Debounced commit into settings.json "mascots".
    property var _pending: ({})
    Timer { id: saveTimer; interval: 300; onTriggered: root.flush() }
    function set(key, v) {
        root._pending[key] = v;
        saveTimer.restart();
    }
    function flush() {
        let keys = Object.keys(root._pending);
        if (keys.length === 0) return;
        let base = (root._mascots && typeof root._mascots === "object")
                   ? root._mascots : {};
        root._writeMascots(Object.assign({}, base, root._pending));
        root._pending = {};
    }
    // Nested "mascots.dock" commits (merged into the existing dock object).
    property var _pendingDock: ({})
    Timer { id: saveDockTimer; interval: 300; onTriggered: root.flushDock() }
    function setDock(key, v) {
        root._pendingDock[key] = v;
        saveDockTimer.restart();
    }
    function flushDock() {
        let keys = Object.keys(root._pendingDock);
        if (keys.length === 0) return;
        let base = (root._mascots && typeof root._mascots === "object")
                   ? root._mascots : {};
        let dock = (base.dock && typeof base.dock === "object") ? base.dock : {};
        root._writeMascots(Object.assign({}, base,
            { dock: Object.assign({}, dock, root._pendingDock) }));
        root._pendingDock = {};
    }
    // Nested "mascots.watcher" commits.
    property var _pendingWatcher: ({})
    Timer { id: saveWatcherTimer; interval: 300; onTriggered: root.flushWatcher() }
    function setWatcher(key, v) {
        root._pendingWatcher[key] = v;
        saveWatcherTimer.restart();
    }
    function flushWatcher() {
        let keys = Object.keys(root._pendingWatcher);
        if (keys.length === 0) return;
        let base = (root._mascots && typeof root._mascots === "object")
                   ? root._mascots : {};
        let watcher = (base.watcher && typeof base.watcher === "object") ? base.watcher : {};
        root._writeMascots(Object.assign({}, base,
            { watcher: Object.assign({}, watcher, root._pendingWatcher) }));
        root._pendingWatcher = {};
    }
    Component.onDestruction: { root.flush(); root.flushDock(); root.flushWatcher(); }

    // ── mascot lineup (discovered species) ─────────────────────────────────
    // The editor always shows an ordered lineup (top -> bottom = left -> right
    // in the island). Editing it switches to the array form of `species`.
    readonly property var editorLineup: root.mLineupMode ? root.mLineup
        : (root.mSpecies ? [String(root.mSpecies)] : [])
    readonly property var availableSpecies: {
        let all = MascotsCatalog.mascots || [];
        let have = root.editorLineup;
        let out = [];
        for (let i = 0; i < all.length; i++)
            if (have.indexOf(String(all[i].id)) < 0) out.push(all[i]);
        return out;
    }
    function catInfo(id) {
        let m = MascotsCatalog.mascots || [];
        for (let i = 0; i < m.length; i++) if (String(m[i].id) === String(id)) return m[i];
        return { id: String(id), label: String(id), icon: "" };
    }
    function writeLineup(arr) {
        let a = arr.slice();
        root.mLineupMode = true;
        root.mLineup = a;
        root.set("species", a);
    }
    function addSpecies(id) {
        id = String(id);
        let a = root.editorLineup.slice();
        if (a.indexOf(id) < 0) a.push(id);
        root.writeLineup(a);
    }
    function removeSpecies(id) {
        id = String(id);
        let a = root.editorLineup.slice();
        let i = a.indexOf(id);
        if (i >= 0 && a.length > 1) { a.splice(i, 1); root.writeLineup(a); }
    }
    function reorderLineup(from, to) {
        let a = root.editorLineup.slice();
        if (from < 0 || from >= a.length) return;
        let moved = a.splice(from, 1)[0];
        to = Math.max(0, Math.min(a.length, to));
        a.splice(to, 0, moved);
        root.writeLineup(a);
    }

    // ── per-species appearance (settings → mascots.options.<id>) ───────────
    // A species declares what it accepts in its manifest (`customizable`).
    function speciesOpts(id) {
        let m = root._mascots || {};
        return (m.options && m.options[id]) ? m.options[id] : {};
    }
    function speciesColor(id) {
        let c = root.speciesOpts(String(id)).color;
        return (typeof c === "string") ? c : "";
    }
    function speciesSize(id) {
        let s = root.speciesOpts(String(id)).size;
        return (typeof s === "number") ? s : 1.0;
    }
    function canCustomize(id, what) {
        let info = root.catInfo(String(id));
        return Array.isArray(info.customizable) && info.customizable.indexOf(what) !== -1;
    }
    // Controls to render for a species: the manifest's `controls` array if
    // present, else one control per `customizable` entry (color / size).
    function speciesControls(id) {
        let info = root.catInfo(String(id));
        if (Array.isArray(info.controls)) return info.controls;
        if (Array.isArray(info.customizable))
            return info.customizable.map(function (t) { return { type: t }; });
        return [];
    }
    readonly property var colorRoles: ["", "text", "subtext0", "red", "green", "yellow", "blue", "mauve", "teal", "peach"]
    function patchSpeciesOpts(id, patch) {
        id = String(id);
        let opts = Object.assign({}, (root._mascots || {}).options || {});
        let next = Object.assign({}, opts[id] || {}, patch);
        if (!next.color) delete next.color;
        if (typeof next.size !== "number" || Math.abs(next.size - 1.0) < 0.001) delete next.size;
        if (Object.keys(next).length === 0) delete opts[id]; else opts[id] = next;
        root.set("options", opts);
    }
    function cycleSpeciesColor(id) {
        let i = root.colorRoles.indexOf(root.speciesColor(id));
        root.patchSpeciesOpts(id, { color: root.colorRoles[(i + 1) % root.colorRoles.length] });
    }
    function nudgeSpeciesSize(id, d) {
        let s = Math.round((root.speciesSize(id) + d) * 10) / 10;
        root.patchSpeciesOpts(id, { size: Math.max(0.6, Math.min(1.8, s)) });
    }

    // ── drag & drop state (reorder the lineup) ─────────────────────────────
    property bool dndActive: false
    property string dndId: ""
    property int dndGap: 0
    property real dndX: 0
    property real dndY: 0
    function gapAt(listY) {
        let n = root.editorLineup.length;
        let rowH = root.bar ? root.bar.s(44) : 44;
        let step = rowH + (root.bar ? root.bar.s(6) : 6);
        for (let i = 0; i < n; i++) if (listY < i * step + rowH / 2) return i;
        return n;
    }
    function commitDnd() {
        let from = root.editorLineup.indexOf(String(root.dndId));
        if (from < 0) return;
        let to = root.dndGap;
        if (to > from) to -= 1;
        if (to !== from) root.reorderLineup(from, to);
    }
    function cancelDnd() { root.dndActive = false; root.dndId = ""; }

    Loader {
        id: body
        anchors.fill: parent
        active: root.bar !== null
        sourceComponent: pageBody
    }

    Component {
        id: pageBody
        Item {
            id: pageHost
            anchors.fill: parent
            property alias flickable: pageFlick

            // Drag ghost for the lineup reorder (rendered above the page via z).
            Rectangle {
                visible: root.dndActive
                x: root.dndX - width / 2
                y: root.dndY - height / 2
                width: bar.s(160); height: bar.s(40)
                radius: bar.s(11)
                color: bar.colors.surface2
                border.width: 1
                border.color: bar.colors.mauve
                opacity: 0.96
                z: 1000
                Row {
                    anchors.centerIn: parent
                    spacing: bar.s(8)
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.catInfo(root.dndId).icon || ""
                        font.family: "Hack Nerd Font"
                        font.pixelSize: bar.s(18)
                        color: bar.colors.mauve
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.catInfo(root.dndId).label || root.dndId
                        font.family: "Hack Nerd Font"
                        font.pixelSize: bar.s(13)
                        color: bar.colors.text
                    }
                }
            }

            Flickable {
                id: pageFlick
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: pageCol.height + bar.s(16)
                ScrollBar.vertical: ScrollBar {
                    id: vScroll
                    width: bar.s(4)
                    policy: ScrollBar.AsNeeded
                    hoverEnabled: true
                    active: pageFlick.moving || vScroll.hovered
                    contentItem: Rectangle {
                        radius: bar.s(2)
                        color: bar.colors.surface2
                        opacity: vScroll.active ? 1.0 : 0.45
                    }
                    background: Item {}
                }

                Column {
                    id: pageCol
                    x: bar.s(8)
                    y: bar.s(8)
                    width: pageFlick.width - bar.s(16)
                    spacing: bar.s(12)

                    Text {
                        text: "Nyx"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(24)
                        color: bar.colors.text
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "A small click-through island at the top of the screen: it fades away while the app launcher (SUPER+D) is open (the island becomes the dock) and when a widget covers it. The mascots' eyes follow the cursor and they react with random moods (angry, surprised, happy, sleepy) when windows or widgets open and close; they fall asleep when idle."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Enabled"
                        checked: root.mEnabled
                        onToggled: { root.mEnabled = !root.mEnabled; root.set("enabled", root.mEnabled); }
                    }

                    Text {
                        text: "Species"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }

                    // Ordered lineup: drag the handle to reorder. Top -> bottom
                    // maps to left -> right in the island.
                    Item {
                        id: lineupHost
                        width: parent.width
                        height: lineupList.height

                        Column {
                            id: lineupList
                            width: parent.width
                            spacing: bar.s(6)
                            readonly property int rowH: bar.s(44)

                            Repeater {
                                model: root.editorLineup
                                delegate: Rectangle {
                                    id: lineupRow
                                    required property string modelData
                                    required property int index

                                    readonly property var info: root.catInfo(modelData)
                                    readonly property string sid: String(modelData)
                                    width: lineupList.width
                                    height: lineupList.rowH
                                    radius: bar.s(11)
                                    color: bar.colors.surface0
                                    border.width: 1
                                    border.color: bar.colors.surface1
                                    opacity: (root.dndActive && root.dndId === modelData) ? 0.35 : 1.0
                                    Behavior on opacity { NumberAnimation { duration: 120 } }

                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: bar.s(12)
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: bar.s(10)
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰹽"
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: bar.s(18)
                                            color: handleHover.containsMouse ? bar.colors.mauve : bar.colors.overlay1
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: lineupRow.info.icon || ""
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: bar.s(20)
                                            color: bar.colors.mauve
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: lineupRow.info.label || modelData
                                            font.family: "Hack Nerd Font"
                                            font.pixelSize: bar.s(14)
                                            color: bar.colors.text
                                        }
                                    }

                                    // per-species controls (from the manifest) + remove
                                    Row {
                                        anchors.right: parent.right
                                        anchors.rightMargin: bar.s(12)
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: bar.s(10)

                                        Repeater {
                                            model: root.speciesControls(lineupRow.sid)
                                            delegate: Item {
                                                id: ctl
                                                required property var modelData
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: modelData.type === "size" ? bar.s(80)
                                                     : modelData.type === "text" ? bar.s(160) : bar.s(24)
                                                height: bar.s(26)

                                                // colour
                                                Item {
                                                    id: ccCell
                                                    visible: modelData.type === "color"
                                                    anchors.fill: parent
                                                    readonly property string col: root.speciesColor(lineupRow.sid)
                                                    Rectangle {
                                                        anchors.centerIn: parent
                                                        width: bar.s(24); height: bar.s(24); radius: width / 2
                                                        color: ccCell.col === "" ? bar.colors.surface1
                                                            : (bar.colors[ccCell.col] !== undefined ? bar.colors[ccCell.col] : ccCell.col)
                                                        border.width: 1
                                                        border.color: ccHover.containsMouse ? bar.colors.mauve : bar.colors.surface1
                                                        Text {
                                                            anchors.centerIn: parent
                                                            visible: ccCell.col === ""
                                                            text: "A"
                                                            font.family: "Hack Nerd Font"
                                                            font.pixelSize: bar.s(11)
                                                            color: bar.colors.subtext0
                                                        }
                                                    }
                                                    MouseArea {
                                                        id: ccHover
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.cycleSpeciesColor(lineupRow.sid)
                                                    }
                                                }

                                                // size
                                                Row {
                                                    visible: modelData.type === "size"
                                                    anchors.centerIn: parent
                                                    spacing: bar.s(4)
                                                    Rectangle {
                                                        width: bar.s(20); height: width; radius: width / 2
                                                        color: szDownHover.containsMouse ? Qt.alpha(bar.colors.mauve, 0.15) : Qt.alpha(bar.colors.surface0, 0.5)
                                                        border.width: 1; border.color: bar.colors.surface1
                                                        Text { anchors.centerIn: parent; text: "−"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(14); color: bar.colors.text }
                                                        MouseArea { id: szDownHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.nudgeSpeciesSize(lineupRow.sid, -0.1) }
                                                    }
                                                    Text {
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width: bar.s(32); horizontalAlignment: Text.AlignHCenter
                                                        text: root.speciesSize(lineupRow.sid).toFixed(1) + "x"
                                                        font.family: "Hack Nerd Font"; font.pixelSize: bar.s(11); color: bar.colors.subtext0
                                                    }
                                                    Rectangle {
                                                        width: bar.s(20); height: width; radius: width / 2
                                                        color: szUpHover.containsMouse ? Qt.alpha(bar.colors.mauve, 0.15) : Qt.alpha(bar.colors.surface0, 0.5)
                                                        border.width: 1; border.color: bar.colors.surface1
                                                        Text { anchors.centerIn: parent; text: "+"; font.family: "Hack Nerd Font"; font.pixelSize: bar.s(14); color: bar.colors.text }
                                                        MouseArea { id: szUpHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.nudgeSpeciesSize(lineupRow.sid, 0.1) }
                                                    }
                                                }

                                                // text (e.g. a username)
                                                TextField {
                                                    id: tf
                                                    visible: modelData.type === "text"
                                                    anchors.fill: parent
                                                    text: {
                                                        let v = root.speciesOpts(lineupRow.sid)[modelData.key];
                                                        return (typeof v === "string") ? v : (modelData.default !== undefined ? String(modelData.default) : "");
                                                    }
                                                    placeholderText: modelData.placeholder || modelData.label || ""
                                                    font.family: "Hack Nerd Font"
                                                    font.pixelSize: bar.s(12)
                                                    color: bar.colors.text
                                                    placeholderTextColor: Qt.alpha(bar.colors.subtext0, 0.6)
                                                    selectByMouse: true
                                                    leftPadding: bar.s(8); rightPadding: bar.s(8)
                                                    background: Rectangle {
                                                        color: Qt.alpha(bar.colors.surface1, 0.35)
                                                        border.width: 1; border.color: bar.colors.surface1
                                                        radius: bar.s(8)
                                                    }
                                                    onEditingFinished: {
                                                        let patch = {};
                                                        patch[String(modelData.key)] = tf.text;
                                                        root.patchSpeciesOpts(lineupRow.sid, patch);
                                                    }
                                                }
                                            }
                                        }

                                        // remove
                                        Item {
                                            width: bar.s(22); height: bar.s(22)
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰅖"
                                                font.family: "Hack Nerd Font"
                                                font.pixelSize: bar.s(16)
                                                color: removeHover.containsMouse ? bar.colors.red : bar.colors.overlay1
                                            }
                                            MouseArea {
                                                id: removeHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: root.removeSpecies(lineupRow.sid)
                                            }
                                        }
                                    }

                                    // drag handle only, so the page can still scroll
                                    MouseArea {
                                        id: handleHover
                                        width: bar.s(34)
                                        height: parent.height
                                        anchors.left: parent.left
                                        hoverEnabled: true
                                        preventStealing: true
                                        property point pressPt: Qt.point(0, 0)
                                        onPressed: mouse => { pressPt = Qt.point(mouse.x, mouse.y); }
                                        onPositionChanged: mouse => {
                                            if (!pressed) return;
                                            let dist = Math.abs(mouse.x - pressPt.x) + Math.abs(mouse.y - pressPt.y);
                                            if (!root.dndActive && dist > bar.s(8)) {
                                                root.dndActive = true;
                                                root.dndId = String(modelData);
                                                root.dndGap = lineupRow.index;
                                            }
                                            if (root.dndActive) {
                                                let local = handleHover.mapToItem(lineupList, mouse.x, mouse.y);
                                                root.dndGap = root.gapAt(local.y);
                                                let p = handleHover.mapToItem(root, mouse.x, mouse.y);
                                                root.dndX = p.x; root.dndY = p.y;
                                            }
                                        }
                                        onReleased: { if (root.dndActive) root.commitDnd(); root.cancelDnd(); }
                                        onCanceled: root.cancelDnd()
                                    }
                                }
                            }
                        }

                        // insertion indicator
                        Rectangle {
                            visible: root.dndActive
                            width: lineupHost.width
                            height: bar.s(3)
                            radius: height / 2
                            color: bar.colors.mauve
                            y: Math.max(0, Math.min(lineupList.height,
                                root.dndGap * (lineupList.rowH + lineupList.spacing) - lineupList.spacing / 2))
                        }
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Drag the handle to reorder (top → bottom = left → right in the island); tap ✕ to remove. Colour and size apply to species that support them (they persist to mascots.options). Species are discovered from the shipped module and from ~/.config/hypr/mascots/species/ — drop a manifest .json + a QML file there to add your own."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: root.availableSpecies.length > 0
                        text: "Add"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    Flow {
                        width: parent.width
                        spacing: bar.s(8)
                        Repeater {
                            model: root.availableSpecies
                            delegate: Rectangle {
                                required property var modelData
                                width: addRow.implicitWidth + bar.s(22)
                                height: bar.s(36)
                                radius: height / 2
                                color: addHover.containsMouse ? bar.colors.surface2 : bar.colors.surface0
                                border.width: 1
                                border.color: bar.colors.surface1
                                Row {
                                    id: addRow
                                    anchors.centerIn: parent
                                    spacing: bar.s(8)
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.icon || "󰐕"
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: bar.s(16)
                                        color: bar.colors.mauve
                                    }
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label || modelData.id
                                        font.family: "Hack Nerd Font"
                                        font.pixelSize: bar.s(13)
                                        color: bar.colors.text
                                    }
                                }
                                MouseArea {
                                    id: addHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.addSpecies(String(modelData.id))
                                }
                            }
                        }
                    }

                    Text {
                        text: "Appearance"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "Island"
                            active: root.mAppearance !== "notch"
                            onActivated: { root.mAppearance = "island"; root.set("appearance", "island"); }
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "Notch"
                            active: root.mAppearance === "notch"
                            onActivated: { root.mAppearance = "notch"; root.set("appearance", "notch"); }
                        }
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Island is the floating pill. Notch snaps to the very top edge with a macOS-style silhouette (concave top fillets, rounded bottom, no coloured border) and is only available at the top. The widget dock still unfolds as a floating panel below and retracts the notch while it is open."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    EffectSlider {
                        visible: root.mAppearance === "notch"
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Notch width"
                        from: 140; to: 640; step: 10
                        decimals: 0
                        suffix: "px"
                        accentColor: bar.colors.mauve
                        value: root.mNotchWidth
                        onEdited: (v) => { root.mNotchWidth = v; root.set("notchWidth", v); }
                    }
                    EffectSlider {
                        visible: root.mAppearance === "notch"
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Notch height"
                        from: 0; to: 120; step: 1
                        decimals: 0
                        suffix: "px"
                        accentColor: bar.colors.mauve
                        value: root.mNotchHeight
                        onEdited: (v) => { root.mNotchHeight = v; root.set("notchHeight", v); }
                    }
                    EffectSlider {
                        visible: root.mAppearance === "notch"
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Notch offset Y"
                        from: -60; to: 60; step: 1
                        decimals: 0
                        suffix: "px"
                        accentColor: bar.colors.mauve
                        value: root.mNotchOffset
                        onEdited: (v) => { root.mNotchOffset = v; root.set("notchOffset", v); }
                    }
                    EditLabel {
                        visible: root.mAppearance === "notch"
                        bar: root.bar
                        width: parent.width
                        text: "Height 0 keeps the automatic height. Offset Y moves the notch up (negative) or down (positive); a negative value tucks the top fillets above the screen edge for a flatter top."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                    ToggleCard {
                        visible: root.mAppearance === "notch"
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Reserve top space"
                        checked: root.mNotchReserve
                        onToggled: { root.mNotchReserve = !root.mNotchReserve; root.set("notchReserve", root.mNotchReserve); }
                    }
                    EditLabel {
                        visible: root.mAppearance === "notch"
                        bar: root.bar
                        width: parent.width
                        text: "Reserve top space keeps maximized windows clear of the notch (an exclusive zone, like real hardware). Turn it off to let windows slide underneath."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: "Position"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    GridLayout {
                        width: parent.width
                        columns: 3
                        columnSpacing: bar.s(6)
                        rowSpacing: bar.s(6)
                        Repeater {
                            model: ["top-left", "top-center", "top-right",
                                    "center-left", "center", "center-right",
                                    "bottom-left", "bottom-center", "bottom-right"]
                            delegate: Rectangle {
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: bar.s(22)
                                radius: bar.s(6)
                                color: root.mPosition === modelData
                                    ? bar.colors.mauve
                                    : (posMa.containsMouse ? Qt.alpha(bar.colors.mauve, 0.12)
                                                           : Qt.alpha(bar.colors.surface0, 0.4))
                                border.width: 1
                                border.color: root.mPosition === modelData
                                    ? bar.colors.mauve : bar.colors.surface1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                MouseArea {
                                    id: posMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.mPosition = modelData;
                                        root.set("position", modelData);
                                    }
                                }
                            }
                        }
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "The island moves to the chosen corner/edge; the widget dock unfolds inward (downwards, or upwards when the island sits at the bottom)."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: !root.mLineupMode
                        text: "How many"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    GridLayout {
                        visible: !root.mLineupMode
                        width: parent.width
                        columns: 3
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰬺"
                            label: "One"
                            active: root.mCount === 1
                            onActivated: { root.mCount = 1; root.set("count", 1); }
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰬻"
                            label: "Two"
                            active: root.mCount === 2
                            onActivated: { root.mCount = 2; root.set("count", 2); }
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: "󰬼"
                            label: "Three"
                            active: root.mCount === 3
                            onActivated: { root.mCount = 3; root.set("count", 3); }
                        }
                    }

                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Size"
                        from: 0.6; to: 1.6; step: 0.1
                        decimals: 1
                        suffix: "x"
                        accentColor: bar.colors.mauve
                        value: root.mSize
                        onEdited: (v) => { root.mSize = v; root.set("size", v); }
                    }

                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: root.mEnabled
                            ? "Open the launcher (SUPER+D): the island fades away into the dock and comes back when you close it. The mascots eyes follow the cursor."
                            : "Enable to show the island; the overlay is click-through and never blocks the windows below."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: "Dock"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "The control center that unfolds when you click the island/notch: search, clock + now-playing, quick actions and a widget grid."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "Floating"
                            active: root.mDockStyle !== "joined"
                            onActivated: { root.mDockStyle = "floating"; root.setDock("style", "floating"); }
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "Joined to notch"
                            active: root.mDockStyle === "joined"
                            onActivated: { root.mDockStyle = "joined"; root.setDock("style", "joined"); }
                        }
                    }
                    GridLayout {
                        width: parent.width
                        columns: 4
                        columnSpacing: bar.s(8)
                        rowSpacing: bar.s(8)
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "S"
                            active: root.mDockSize === "compact"
                            onActivated: { root.mDockSize = "compact"; root.setDock("size", "compact"); }
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "M"
                            active: root.mDockSize === "medium"
                            onActivated: { root.mDockSize = "medium"; root.setDock("size", "medium"); }
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "L"
                            active: root.mDockSize === "large"
                            onActivated: { root.mDockSize = "large"; root.setDock("size", "large"); }
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "XL"
                            active: root.mDockSize === "wide"
                            onActivated: { root.mDockSize = "wide"; root.setDock("size", "wide"); }
                        }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Grid columns"
                        from: 3; to: 7; step: 1
                        decimals: 0
                        suffix: ""
                        accentColor: bar.colors.mauve
                        value: root.mDockColumns
                        onEdited: (v) => { root.mDockColumns = v; root.setDock("columns", v); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Grid rows"
                        from: 1; to: 3; step: 1
                        decimals: 0
                        suffix: ""
                        accentColor: bar.colors.mauve
                        value: root.mDockRows
                        onEdited: (v) => { root.mDockRows = v; root.setDock("rows", v); }
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Hero (clock + now playing)"
                        checked: root.mDockHero
                        onToggled: { root.mDockHero = !root.mDockHero; root.setDock("hero", root.mDockHero); }
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Quick actions"
                        checked: root.mDockQuick
                        onToggled: { root.mDockQuick = !root.mDockQuick; root.setDock("quick", root.mDockQuick); }
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Search field"
                        checked: root.mDockSearch
                        onToggled: { root.mDockSearch = !root.mDockSearch; root.setDock("search", root.mDockSearch); }
                    }

                    Text {
                        text: "Watcher"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Options for the Watcher species: a digital clock retyped with a typewriter cursor."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                    GridLayout {
                        width: parent.width
                        columns: 2
                        columnSpacing: bar.s(10)
                        rowSpacing: bar.s(10)
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "24-hour"
                            active: root.mWatcherFormat !== "12"
                            onActivated: { root.mWatcherFormat = "24"; root.setWatcher("format", "24"); }
                        }
                        OptionCard {
                            Layout.fillWidth: true
                            bar: root.bar
                            icon: ""
                            label: "12-hour"
                            active: root.mWatcherFormat === "12"
                            onActivated: { root.mWatcherFormat = "12"; root.setWatcher("format", "12"); }
                        }
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Show seconds"
                        checked: root.mWatcherSeconds
                        onToggled: { root.mWatcherSeconds = !root.mWatcherSeconds; root.setWatcher("seconds", root.mWatcherSeconds); }
                    }
                    EffectSlider {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Typewriter speed"
                        from: 0.5; to: 2.5; step: 0.1
                        decimals: 1
                        suffix: "x"
                        accentColor: bar.colors.mauve
                        value: root.mWatcherSpeed
                        onEdited: (v) => { root.mWatcherSpeed = v; root.setWatcher("speed", v); }
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Mood effects"
                        checked: root.mWatcherMoods
                        onToggled: { root.mWatcherMoods = !root.mWatcherMoods; root.setWatcher("moods", root.mWatcherMoods); }
                    }
                    ToggleCard {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Watcher eye"
                        checked: root.mWatcherEye
                        onToggled: { root.mWatcherEye = !root.mWatcherEye; root.setWatcher("eye", root.mWatcherEye); }
                    }

                    Text {
                        text: "Profiles"
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: bar.s(16)
                        color: bar.colors.text
                    }
                    EditLabel {
                        bar: root.bar
                        width: parent.width
                        text: "Save the current mascot + notch + dock + watcher settings as a named profile and load it later."
                        font.pixelSize: bar.s(11)
                        color: bar.colors.subtext0
                        wrapMode: Text.WordWrap
                    }
                    FieldCard {
                        width: parent.width
                        bar: root.bar
                        label: "Name"
                        value: root.mProfileName
                        placeholder: "e.g. minimal"
                        onEdited: (t) => { root.mProfileName = t; }
                    }
                    OptionCard {
                        width: parent.width
                        bar: root.bar
                        icon: ""
                        label: "Save current as profile"
                        active: false
                        onActivated: root.saveProfile(root.mProfileName)
                    }
                    Repeater {
                        model: root.profileNames
                        delegate: Item {
                            required property string modelData
                            width: parent.width
                            height: bar.s(28)
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData
                                font.family: "Hack Nerd Font"
                                font.pixelSize: bar.s(12)
                                color: bar.colors.text
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: bar.s(58); height: bar.s(22); radius: bar.s(7)
                                color: ldMa.containsMouse ? Qt.alpha(bar.colors.green, 0.2) : Qt.alpha(bar.colors.surface0, 0.4)
                                border.width: 1; border.color: bar.colors.surface1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Load"
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: bar.s(10)
                                    color: bar.colors.text
                                }
                                MouseArea {
                                    id: ldMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.loadProfile(modelData)
                                }
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: bar.s(64)
                                anchors.verticalCenter: parent.verticalCenter
                                width: bar.s(58); height: bar.s(22); radius: bar.s(7)
                                color: dlMa.containsMouse ? Qt.alpha(bar.colors.red, 0.2) : Qt.alpha(bar.colors.surface0, 0.4)
                                border.width: 1; border.color: bar.colors.surface1
                                Text {
                                    anchors.centerIn: parent
                                    text: "Delete"
                                    font.family: "Hack Nerd Font"
                                    font.pixelSize: bar.s(10)
                                    color: bar.colors.text
                                }
                                MouseArea {
                                    id: dlMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.deleteProfile(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
