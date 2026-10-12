import QtQuick
import Quickshell
import Quickshell.Io

// ─────────────────────────────────────────────────────────────────────────────
// GithubPopover — the panel opened by the GitHub mascot: the contribution
// calendar (squares) for the configured user. Self-contained: runs its own
// fetch script; no shell/Nyx imports. Its implicit size hugs the content so the
// host panel has no dead space.
//
// Contract (host injects): options, palette, scaleUnit, accent.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: root

    property var options: ({})
    property var palette: ({})
    property real scaleUnit: 1.0
    property color accent: "#cba6f7"

    function s(v) { return v * (scaleUnit > 0 ? scaleUnit : 1.0) }

    readonly property string user: (options && options.user) ? String(options.user) : "xscriptor"
    readonly property string scriptPath: String(Qt.resolvedUrl("github_fetch.sh")).replace(/^file:\/\//, "")

    property int gridRows: 7
    property int gridCols: 0
    property var cells: []
    property string state: "loading"   // loading | ok | error

    function baseColor() {
        let c = (options && options.color) ? options.color : "";
        if (c === "") return palette.green;
        return (palette[c] !== undefined) ? palette[c] : c;
    }
    function colorFor(level) {
        if (level <= 0) return Qt.rgba(palette.text.r, palette.text.g, palette.text.b, 0.07);
        let b = baseColor();
        let a = 0.28 + 0.18 * Math.min(4, level);
        return Qt.rgba(b.r, b.g, b.b, Math.min(1.0, a));
    }

    readonly property real pad: s(18)
    readonly property real cell: Math.max(4, s(11))
    readonly property real gap: Math.max(1, s(2))
    readonly property real gridW: Math.max(1, gridCols) * cell + Math.max(0, gridCols - 1) * gap
    readonly property real gridH: gridRows * cell + Math.max(0, gridRows - 1) * gap
    readonly property real headH: s(30)

    implicitWidth: Math.max(s(240), root.gridW + root.pad * 2)
    implicitHeight: root.pad + root.headH + s(12) + root.gridH + root.pad

    Process {
        id: fetch
        running: false
        command: ["bash", root.scriptPath, root.user]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let o = JSON.parse(this.text);
                    if (o.error) { root.state = "error"; return; }
                    root.gridRows = o.rows || 7;
                    root.gridCols = o.cols || 0;
                    root.cells = o.cells || [];
                    root.state = "ok";
                } catch (e) { root.state = "error"; }
            }
        }
    }
    function reload() { root.state = "loading"; fetch.running = false; fetch.running = true; }
    Component.onCompleted: reload()

    // ── header (centred) ───────────────────────────────────────────────────
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.pad
        spacing: s(8)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf09b"
            font.family: "Hack Nerd Font"
            font.pixelSize: s(19)
            color: root.accent
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "@" + root.user
            font.family: "Hack Nerd Font"
            font.weight: Font.Black
            font.pixelSize: s(14)
            color: palette.text
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.state === "ok"
            text: "· contributions"
            font.family: "Hack Nerd Font"
            font.pixelSize: s(11)
            color: palette.subtext0 !== undefined ? palette.subtext0 : palette.text
        }
    }

    // ── body ───────────────────────────────────────────────────────────────
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.pad + root.headH + s(12)
        visible: root.state === "loading"
        text: "loading @" + root.user + "…"
        font.family: "Hack Nerd Font"
        font.pixelSize: s(12)
        color: palette.text
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.pad + root.headH + s(12)
        visible: root.state === "error"
        text: "no data for @" + root.user
        font.family: "Hack Nerd Font"
        font.pixelSize: s(12)
        color: palette.red
    }

    Item {
        id: grid
        visible: root.state === "ok"
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.pad + root.headH + s(12)
        width: root.gridW
        height: root.gridH

        Repeater {
            model: root.cells
            delegate: Rectangle {
                required property var modelData
                width: root.cell; height: root.cell
                radius: Math.max(1, root.cell * 0.22)
                color: root.colorFor(modelData.l)
                x: modelData.c * (root.cell + root.gap)
                y: modelData.r * (root.cell + root.gap)
            }
        }
    }
}
