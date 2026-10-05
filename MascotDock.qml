import QtQuick
import Quickshell
import Quickshell.Io

// ═══════════════════════════════════════════════════════════════════════════
// MascotDock — the control-center panel that unfolds from the mascot notch.
//
// Self-contained: no shell imports. The host feeds `widgets` (the launcher
// grid), `quickActions` (shortcut buttons) and the palette; this component
// only draws, searches, pages and emits the chosen ids. Now-playing comes from
// `playerctl` and degrades silently when it is missing.
//
// Sections (top to bottom): header (title + search + close), hero (clock/date
// + now-playing), quick actions, widget grid, footer (paging + dots).
//
// API: open / widgets / quickActions / palette / scaleUnit / accent / joined /
//      columns / rows / panelWidth / showHero / showQuick / showSearch /
//      title / launchRequested(id) / quickRequested(id) / closeRequested().
// ═══════════════════════════════════════════════════════════════════════════

Item {
    id: dock

    property bool open: false
    property var widgets: []
    property var quickActions: []
    property var palette: ({})
    property real scaleUnit: 0.78
    property color accent: "#cba6f7"
    property bool joined: false
    property int columns: 5
    property int rows: 2
    property real panelWidth: 900
    property bool showHero: true
    property bool showQuick: true
    property bool showSearch: true
    property bool showStats: true
    property var stats: []
    property string title: "Control Center"
    property var favorites: []
    property string tab: "all"

    signal launchRequested(string id)
    signal quickRequested(string id)
    signal favoriteToggled(string id)
    signal closeRequested()

    // ── reveal ─────────────────────────────────────────────────────────────
    property real target: dock.open ? 1.0 : 0.0
    Behavior on target { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    readonly property real reveal: dock.target

    // ── scale / palette helpers ─────────────────────────────────────────────
    readonly property real effectiveScale: (dock.scaleUnit > 0 && dock.scaleUnit <= 10) ? dock.scaleUnit : 0.78
    function s(v) { return Math.round(v * dock.effectiveScale) }
    function pal(key, fallback) {
        const p = dock.palette;
        const v = (p && typeof p === "object") ? p[key] : undefined;
        return (v === undefined || v === null) ? fallback : v;
    }
    function field(item, key) {
        const v = (item && typeof item === "object") ? item[key] : undefined;
        return (v === undefined || v === null) ? "" : v;
    }
    readonly property color cBase: dock.pal("base", "#1e1e2e")
    readonly property color cSurface0: dock.pal("surface0", "#313244")
    readonly property color cSurface1: dock.pal("surface1", "#45475a")
    readonly property color cText: dock.pal("text", "#cdd6f4")
    readonly property color cSubtext: dock.pal("subtext0", "#a6adc8")
    readonly property bool cGlassOn: !!dock.pal("glassOn", false)

    // ── layout metrics ──────────────────────────────────────────────────────
    readonly property real pad: dock.s(14)
    readonly property real gap: dock.s(10)
    readonly property real headerH: dock.s(30)
    readonly property real heroH: dock.showHero ? dock.s(84) : 0
    readonly property var quickList: (dock.quickActions && dock.quickActions.length !== undefined) ? dock.quickActions : []
    readonly property int quickRows: Math.max(1, Math.ceil(dock.quickList.length / Math.max(1, dock.columns)))
    readonly property real quickItemH: dock.s(46)
    readonly property real quickH: (dock.showQuick && dock.quickList.length > 0)
        ? dock.quickRows * dock.quickItemH + (dock.quickRows - 1) * dock.gap : 0
    readonly property var statList: (dock.stats && dock.stats.length !== undefined) ? dock.stats : []
    readonly property real statH: (dock.showStats && dock.statList.length > 0) ? dock.s(44) : 0
    readonly property real statW: dock.statList.length > 0
        ? Math.floor((dock.panelWidth - 2 * dock.pad - (dock.statList.length - 1) * dock.gap) / dock.statList.length)
        : 0
    readonly property real tileH: dock.s(84)
    readonly property real tileW: Math.max(dock.s(70),
        Math.floor((dock.panelWidth - 2 * dock.pad - (dock.columns - 1) * dock.gap) / dock.columns))
    readonly property real gridH: dock.rows * dock.tileH + (dock.rows - 1) * dock.gap
    readonly property real footerH: dock.s(18)
    readonly property real panelHeight: dock.pad + dock.headerH
        + (dock.heroH > 0 ? dock.gap + dock.heroH : 0)
        + (dock.statH > 0 ? dock.gap + dock.statH : 0)
        + (dock.quickH > 0 ? dock.gap + dock.quickH : 0)
        + dock.gap + dock.gridH
        + dock.gap + dock.footerH
        + dock.pad

    implicitWidth: dock.panelWidth
    implicitHeight: dock.panelHeight
    clip: true

    // ── catalogue + search + paging ─────────────────────────────────────────
    readonly property var tileList: (dock.widgets && dock.widgets.length !== undefined) ? dock.widgets : []
    readonly property int pageSize: Math.max(1, dock.columns * dock.rows)
    property string query: ""
    property int page: 0
    onQueryChanged: dock.page = 0
    readonly property bool favMode: dock.tab === "favorites"
    readonly property var fedTiles: {
        if (!dock.favMode) return dock.tileList;
        return dock.tileList.filter(function (w) {
            return dock.favorites.indexOf(String(dock.field(w, "id"))) !== -1;
        });
    }
    function isFav(id) { return dock.favorites.indexOf(String(id)) !== -1; }
    readonly property var filteredTiles: {
        const q = dock.query.trim().toLowerCase();
        if (q === "") return dock.fedTiles;
        return dock.fedTiles.filter(function (w) {
            return String(dock.field(w, "label")).toLowerCase().indexOf(q) !== -1
                || String(dock.field(w, "id")).toLowerCase().indexOf(q) !== -1;
        });
    }
    readonly property int filteredCount: dock.filteredTiles.length
    readonly property int pageCount: Math.max(1, Math.ceil(dock.filteredCount / dock.pageSize))
    onPageCountChanged: if (dock.page > dock.pageCount - 1) dock.page = Math.max(0, dock.pageCount - 1)
    readonly property var pageTiles: dock.filteredTiles.slice(dock.page * dock.pageSize,
        dock.page * dock.pageSize + dock.pageSize)
    function prevPage() { if (dock.page > 0) dock.page -= 1 }
    function nextPage() { if (dock.page < dock.pageCount - 1) dock.page += 1 }
    function searchGo() {
        if (dock.filteredCount > 0)
            dock.launchRequested(String(dock.field(dock.filteredTiles[0], "id")));
    }
    readonly property bool canPrev: dock.page > 0
    readonly property bool canNext: dock.page < dock.pageCount - 1

    // ── clock ───────────────────────────────────────────────────────────────
    property date now: new Date()
    Timer { interval: 1000; repeat: true; running: dock.open; onTriggered: dock.now = new Date() }

    // ── now playing (playerctl, guarded) ───────────────────────────────────
    property string npStatus: ""
    property string npTitle: ""
    property string npArtist: ""
    property string npArt: ""
    readonly property bool npActive: dock.npStatus === "Playing" || dock.npStatus === "Paused"
    function updateNp(line) {
        const p = String(line).split("|");
        if (p.length < 4) return;
        dock.npStatus = p[0];
        dock.npTitle = p[1];
        dock.npArtist = p[2];
        dock.npArt = p[3];
    }
    Process {
        id: npProc
        running: dock.open
        command: ["bash", "-c",
            "while true; do printf '%s|%s|%s|%s\\n' \"$(playerctl status 2>/dev/null)\" " +
            "\"$(playerctl metadata xesam:title 2>/dev/null)\" " +
            "\"$(playerctl metadata xesam:artist 2>/dev/null)\" " +
            "\"$(playerctl metadata mpris:artUrl 2>/dev/null)\"; sleep 2; done"]
        stdout: SplitParser { onRead: data => dock.updateNp(data) }
    }
    function npCmd(args) { Quickshell.execDetached(args) }

    // ── background ──────────────────────────────────────────────────────────
    Rectangle {
        id: bg
        width: dock.panelWidth
        height: Math.max(0, dock.panelHeight * dock.reveal)
        topLeftRadius: dock.joined ? 0 : dock.s(18)
        topRightRadius: dock.joined ? 0 : dock.s(18)
        bottomLeftRadius: dock.s(18)
        bottomRightRadius: dock.s(18)
        color: Qt.rgba(dock.cBase.r, dock.cBase.g, dock.cBase.b, dock.cGlassOn ? 0.9 : 1.0)
        border.width: 1
        border.color: Qt.alpha(dock.cSurface1, dock.joined ? 0.4 : 0.9)
    }

    // ── content (unfolds downward via yScale) ───────────────────────────────
    Item {
        id: content
        width: dock.panelWidth
        height: dock.panelHeight
        opacity: dock.reveal
        transform: Scale { origin.x: 0; origin.y: 0; yScale: dock.reveal }

        // Header ────────────────────────────────────────────────────────────
        Item {
            id: header
            x: dock.pad
            y: dock.pad
            width: dock.panelWidth - 2 * dock.pad
            height: dock.headerH

            Text {
                id: titleText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: dock.title
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: dock.s(14)
                color: dock.cText
            }

            Row {
                id: tabs
                anchors.left: titleText.right
                anchors.leftMargin: dock.s(14)
                anchors.verticalCenter: parent.verticalCenter
                spacing: dock.s(4)
                Repeater {
                    model: [{ id: "all", label: "All" }, { id: "favorites", label: "Favorites" }]
                    delegate: Rectangle {
                        id: tabBtn
                        required property var modelData
                        width: tabLabel.implicitWidth + dock.s(16)
                        height: dock.s(22)
                        radius: dock.s(7)
                        color: dock.tab === modelData.id ? Qt.alpha(dock.accent, 0.18) : "transparent"
                        border.width: 1
                        border.color: dock.tab === modelData.id ? dock.accent : Qt.alpha(dock.cSurface1, 0.6)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: "Hack Nerd Font"
                            font.pixelSize: dock.s(10)
                            color: dock.cText
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { dock.tab = modelData.id; dock.page = 0; }
                        }
                    }
                }
            }

            Rectangle {
                id: closeBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: dock.s(24)
                height: dock.s(24)
                radius: dock.s(8)
                color: closeMa.containsMouse ? Qt.alpha(dock.cText, 0.08) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: dock.s(15)
                    color: closeMa.containsMouse ? dock.accent : dock.cText
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: dock.closeRequested()
                }
            }

            Rectangle {
                id: searchBox
                visible: dock.showSearch
                anchors.right: closeBtn.left
                anchors.rightMargin: dock.s(8)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(dock.s(260), parent.width - titleText.width - dock.s(80))
                height: dock.s(26)
                radius: dock.s(8)
                color: Qt.alpha(dock.cSurface0, 0.5)
                border.width: 1
                border.color: searchInput.activeFocus ? dock.accent : Qt.alpha(dock.cSurface1, 0.8)
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: dock.s(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: dock.s(13)
                    color: dock.cSubtext
                }
                TextInput {
                    id: searchInput
                    anchors.left: parent.left
                    anchors.leftMargin: dock.s(26)
                    anchors.right: parent.right
                    anchors.rightMargin: dock.s(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: dock.query
                    onTextChanged: dock.query = text
                    color: dock.cText
                    font.family: "Hack Nerd Font"
                    font.pixelSize: dock.s(11)
                    clip: true
                    Keys.onReturnPressed: dock.searchGo()
                    Keys.onEnterPressed: dock.searchGo()
                    Keys.onEscapePressed: dock.query = ""
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "Search widgets…"
                        color: Qt.alpha(dock.cSubtext, 0.6)
                        font.family: "Hack Nerd Font"
                        font.pixelSize: dock.s(11)
                        visible: searchInput.text === ""
                    }
                }
            }
        }

        // Hero ──────────────────────────────────────────────────────────────
        Rectangle {
            id: hero
            visible: dock.showHero
            x: dock.pad
            y: header.y + header.height + dock.gap
            width: dock.panelWidth - 2 * dock.pad
            height: dock.heroH
            radius: dock.s(14)
            color: Qt.alpha(dock.cSurface0, dock.cGlassOn ? 0.5 : 0.45)
            border.width: 1
            border.color: Qt.alpha(dock.cSurface1, 0.6)

            Column {
                anchors.left: parent.left
                anchors.leftMargin: dock.s(16)
                anchors.verticalCenter: parent.verticalCenter
                spacing: dock.s(2)
                Text {
                    text: Qt.formatTime(dock.now, "HH:mm")
                    font.family: "Hack Nerd Font"
                    font.weight: Font.Black
                    font.pixelSize: dock.s(30)
                    color: dock.cText
                }
                Text {
                    text: Qt.formatDate(dock.now, "ddd, d MMM")
                    font.family: "Hack Nerd Font"
                    font.pixelSize: dock.s(11)
                    color: dock.cSubtext
                }
            }

            Item {
                id: npBlock
                visible: dock.npActive
                anchors.left: parent.left
                anchors.leftMargin: dock.s(140)
                anchors.right: parent.right
                anchors.rightMargin: dock.s(12)
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height - dock.s(16)

                Rectangle {
                    id: npArt
                    anchors.verticalCenter: parent.verticalCenter
                    width: dock.s(52)
                    height: dock.s(52)
                    radius: dock.s(10)
                    color: dock.cSurface1
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: dock.npArt
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                }
                Column {
                    anchors.left: npArt.right
                    anchors.leftMargin: dock.s(10)
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(0, npBlock.width - npArt.width - dock.s(120))
                    spacing: dock.s(2)
                    Text {
                        width: parent.width
                        text: dock.npTitle
                        elide: Text.ElideRight
                        font.family: "Hack Nerd Font"
                        font.weight: Font.Black
                        font.pixelSize: dock.s(12)
                        color: dock.cText
                    }
                    Text {
                        width: parent.width
                        text: dock.npArtist
                        elide: Text.ElideRight
                        font.family: "Hack Nerd Font"
                        font.pixelSize: dock.s(11)
                        color: dock.cSubtext
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: dock.s(4)
                    Repeater {
                        model: [
                            { glyph: "󰒮", cmd: ["playerctl", "previous"] },
                            { glyph: dock.npStatus === "Playing" ? "󰏤" : "󰐊", cmd: ["playerctl", "play-pause"] },
                            { glyph: "󰒭", cmd: ["playerctl", "next"] }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: dock.s(30)
                            height: dock.s(30)
                            radius: dock.s(8)
                            color: npMa.containsMouse ? Qt.alpha(dock.accent, 0.15) : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.glyph
                                font.family: "Hack Nerd Font"
                                font.pixelSize: dock.s(15)
                                color: dock.cText
                            }
                            MouseArea {
                                id: npMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: dock.npCmd(modelData.cmd)
                            }
                        }
                    }
                }
            }

            Text {
                visible: !dock.npActive
                anchors.right: parent.right
                anchors.rightMargin: dock.s(16)
                anchors.verticalCenter: parent.verticalCenter
                text: "♪  Nothing playing"
                font.family: "Hack Nerd Font"
                font.pixelSize: dock.s(11)
                color: Qt.alpha(dock.cSubtext, 0.6)
            }
        }

        // Stats strip ───────────────────────────────────────────────────────
        Row {
            id: statsRow
            visible: dock.showStats && dock.statList.length > 0
            x: dock.pad
            y: hero.y + (dock.showHero ? dock.heroH : 0) + dock.gap
            height: dock.statH
            spacing: dock.gap
            Repeater {
                model: dock.statList
                delegate: Rectangle {
                    required property var modelData
                    readonly property real fracVal: {
                        const v = dock.field(modelData, "frac");
                        return (typeof v === "number") ? v : 0;
                    }
                    width: dock.statW
                    height: dock.statH
                    radius: dock.s(12)
                    color: Qt.alpha(dock.cSurface0, 0.45)
                    border.width: 1
                    border.color: Qt.alpha(dock.cSurface1, 0.6)
                    Column {
                        anchors.fill: parent
                        anchors.margins: dock.s(10)
                        spacing: dock.s(5)
                        Item {
                            width: parent.width
                            height: dock.s(13)
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: dock.field(modelData, "icon") + "  " + dock.field(modelData, "label")
                                font.family: "Hack Nerd Font"
                                font.pixelSize: dock.s(10)
                                color: dock.cSubtext
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: dock.field(modelData, "value")
                                font.family: "Hack Nerd Font"
                                font.weight: Font.Black
                                font.pixelSize: dock.s(11)
                                color: dock.cText
                            }
                        }
                        Rectangle {
                            width: parent.width
                            height: dock.s(3)
                            radius: height / 2
                            color: Qt.alpha(dock.cText, 0.12)
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, fracVal))
                                height: parent.height
                                radius: parent.radius
                                color: dock.accent
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }
                    }
                }
            }
        }

        // Quick actions ─────────────────────────────────────────────────────
        Grid {
            id: quickRow
            visible: dock.showQuick && dock.quickList.length > 0
            x: dock.pad
            y: hero.y + (dock.showHero ? dock.heroH : 0)
                + (dock.statH > 0 ? dock.statH + dock.gap : 0) + dock.gap
            columns: dock.columns
            columnSpacing: dock.gap
            rowSpacing: dock.gap
            Repeater {
                model: dock.quickList
                delegate: Rectangle {
                    required property var modelData
                    width: dock.tileW
                    height: dock.quickItemH
                    radius: dock.s(12)
                    color: qMa.containsMouse ? Qt.alpha(dock.accent, 0.14) : Qt.alpha(dock.cSurface0, 0.5)
                    border.width: 1
                    border.color: (dock.field(modelData, "active") === true)
                        ? dock.accent : Qt.alpha(dock.cSurface1, 0.7)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Row {
                        anchors.centerIn: parent
                        spacing: dock.s(8)
                        Text {
                            text: dock.field(modelData, "icon")
                            font.family: "Hack Nerd Font"
                            font.pixelSize: dock.s(16)
                            color: (dock.field(modelData, "active") === true) ? dock.accent : dock.cText
                        }
                        Text {
                            text: dock.field(modelData, "label")
                            font.family: "Hack Nerd Font"
                            font.pixelSize: dock.s(11)
                            color: dock.cText
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, parent.width)
                        }
                    }
                    MouseArea {
                        id: qMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dock.quickRequested(String(dock.field(modelData, "id")))
                    }
                }
            }
        }

        // Widget grid ───────────────────────────────────────────────────────
        Grid {
            id: grid
            x: dock.pad
            y: quickRow.y + ((dock.showQuick && dock.quickList.length > 0) ? dock.quickH : 0) + dock.gap
            columns: dock.columns
            columnSpacing: dock.gap
            rowSpacing: dock.gap
            Repeater {
                model: dock.pageTiles
                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    readonly property string thumbUrl: {
                        const v = dock.field(tile.modelData, "thumb");
                        return (typeof v === "string") ? v : "";
                    }
                    readonly property bool thumbReady: tile.thumbUrl !== "" && thumbImg.status === Image.Ready
                    width: dock.tileW
                    height: dock.tileH
                    radius: dock.s(12)
                    color: tMa.containsMouse ? Qt.alpha(dock.accent, 0.12) : Qt.alpha(dock.cText, 0.05)
                    border.width: 1
                    border.color: tMa.containsMouse ? dock.accent : Qt.alpha(dock.cSurface1, 0.8)
                    scale: tMa.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - dock.s(12)
                        spacing: dock.s(6)
                        Item {
                            width: parent.width
                            height: tile.thumbReady ? dock.s(36) : glyph.implicitHeight
                            Rectangle {
                                anchors.centerIn: parent
                                visible: tile.thumbReady
                                width: dock.s(58) + 2
                                height: dock.s(36) + 2
                                radius: dock.s(6)
                                color: "transparent"
                                border.width: 1
                                border.color: Qt.alpha(dock.cSurface1, 0.8)
                                Image {
                                    id: thumbImg
                                    anchors.centerIn: parent
                                    source: tile.thumbUrl
                                    width: dock.s(58)
                                    height: dock.s(36)
                                    sourceSize.width: 180
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                }
                            }
                            Text {
                                id: glyph
                                anchors.centerIn: parent
                                visible: !tile.thumbReady
                                text: dock.field(tile.modelData, "icon")
                                font.family: "Hack Nerd Font"
                                font.pixelSize: dock.s(24)
                                color: tMa.containsMouse ? dock.accent : dock.cText
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: dock.field(tile.modelData, "label")
                            elide: Text.ElideRight
                            font.family: "Hack Nerd Font"
                            font.pixelSize: dock.s(10)
                            color: dock.cText
                        }
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: dock.s(6)
                        text: dock.isFav(tile.modelData.id) ? "󰓎" : "󰓏"
                        font.family: "Hack Nerd Font"
                        font.pixelSize: dock.s(12)
                        color: dock.isFav(tile.modelData.id) ? dock.accent : Qt.alpha(dock.cText, 0.35)
                        opacity: (dock.favMode || starMa.containsMouse || dock.isFav(tile.modelData.id)) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                        MouseArea {
                            id: starMa
                            anchors.fill: parent
                            anchors.margins: -dock.s(6)
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dock.favoriteToggled(String(dock.field(tile.modelData, "id")))
                        }
                    }

                    MouseArea {
                        id: tMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (tile.modelData && tile.modelData.id !== undefined)
                                dock.launchRequested(String(tile.modelData.id));
                        }
                    }
                }
            }

            Text {
                visible: dock.filteredCount === 0
                anchors.centerIn: grid
                text: "No results"
                font.family: "Hack Nerd Font"
                font.pixelSize: dock.s(12)
                color: Qt.alpha(dock.cText, 0.5)
            }
        }

        // Footer: paging + dots ─────────────────────────────────────────────
        Item {
            id: footer
            x: dock.pad
            y: grid.y + dock.gridH + dock.gap
            width: dock.panelWidth - 2 * dock.pad
            height: dock.footerH

            Rectangle {
                id: prevBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: dock.s(22)
                height: dock.s(18)
                radius: dock.s(6)
                color: (prevMa.containsMouse && dock.canPrev) ? Qt.alpha(dock.cText, 0.06) : "transparent"
                opacity: dock.canPrev ? (prevMa.containsMouse ? 1.0 : 0.8) : 0.3
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: dock.s(14)
                    color: dock.cText
                }
                MouseArea {
                    id: prevMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: dock.canPrev ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: dock.prevPage()
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: dock.s(5)
                Repeater {
                    model: dock.pageCount
                    delegate: Rectangle {
                        required property int index
                        width: dock.s(5)
                        height: dock.s(5)
                        radius: width / 2
                        color: index === dock.page ? dock.accent : Qt.alpha(dock.cText, 0.25)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dock.page = index
                        }
                    }
                }
            }

            Rectangle {
                id: nextBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: dock.s(22)
                height: dock.s(18)
                radius: dock.s(6)
                color: (nextMa.containsMouse && dock.canNext) ? Qt.alpha(dock.cText, 0.06) : "transparent"
                opacity: dock.canNext ? (nextMa.containsMouse ? 1.0 : 0.8) : 0.3
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    font.family: "Hack Nerd Font"
                    font.pixelSize: dock.s(14)
                    color: dock.cText
                }
                MouseArea {
                    id: nextMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: dock.canNext ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: dock.nextPage()
                }
            }
        }
    }
}
