import QtQuick
import Quickshell
import Quickshell.Io

// ─────────────────────────────────────────────────────────────────────────────
// InfoMascot — base for the "useful" species: run a command on a timer and
// render a glyph + value. A species sets `command` and `formatter` (raw stdout
// -> { glyph, value, accent }); everything else is the standard mascot contract
// the host binds (mood, lookX/Y, tint, crust, text, red, blinking, clock,
// palette, options). Self-contained: no shell imports.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: info

    // injected mascot contract
    property string mood: "idle"
    property real lookX: 0
    property real lookY: 0
    property color tint: "#cba6f7"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property color red: "#f38ba8"
    property bool blinking: false
    property real clock: 0
    property var palette: ({})
    property var options: ({})

    // species config
    property string command: ""
    property int pollMs: 4000
    property var formatter: null

    // rendered state
    property string glyph: "󰋼"
    property string valueText: "…"
    property color accentColor: tint

    scale: mood === "happy" ? 1.06 : 1.0
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

    function refresh() {
        if (info.command !== "") { proc.running = false; proc.running = true; }
    }
    Component.onCompleted: refresh()
    Timer {
        interval: info.pollMs
        repeat: true
        running: info.command !== ""
        onTriggered: info.refresh()
    }

    Process {
        id: proc
        command: ["bash", "-c", info.command]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                let out = null;
                if (info.formatter) { try { out = info.formatter(raw); } catch (e) { out = null; } }
                if (out) {
                    if (out.glyph !== undefined) info.glyph = String(out.glyph);
                    if (out.value !== undefined) info.valueText = String(out.value);
                    if (out.accent !== undefined) info.accentColor = out.accent;
                } else if (raw !== "") {
                    info.valueText = raw;
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: -info.height * 0.04

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: info.glyph
            font.family: "Hack Nerd Font"
            font.pixelSize: info.height * 0.58
            color: info.accentColor
            Behavior on color { ColorAnimation { duration: 300 } }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: info.valueText
            font.family: "Hack Nerd Font"
            font.weight: Font.Black
            font.pixelSize: info.height * 0.27
            color: info.text
        }
    }
}
