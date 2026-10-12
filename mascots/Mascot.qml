import QtQuick
import QtQml

// ─────────────────────────────────────────────────────────────────────────────
// Mascot — one mascot instance. A pure host: it owns the bob / blink / mood
// presentation and loads the species QML (`entry`) through a Loader, injecting
// the shared mascot contract. Every species — built-in or user — lives in its
// own folder with a manifest + its entry QML; the host never hardcodes one.
//
// The mascot size is set by the host: width x 1.18.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: mascot

    property int slot: 0
    property string species: ""           // catalog id (informational)
    property string entry: ""             // QML URL of the species (Loader source)
    property string mood: "idle"
    property real lookX: 0
    property real lookY: 0
    property color tint: "#cba6f7"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property color red: "#f38ba8"
    property var palette: ({})
    property real clock: 0
    property real xPos: 0
    property real yPos: 0
    property real zSize: 12
    property var options: ({})

    readonly property real bobAmp: mood === "sleepy" ? 0.6 : (mood === "angry" ? 2.2 : 1.3)

    x: mascot.xPos + (mood === "angry" ? Math.sin(mascot.clock / 2.2) * 1.6 : 0)
    y: mascot.yPos + Math.sin((mascot.clock + mascot.slot * 24) / 26) * mascot.bobAmp

    property bool blinking: false
    Timer {
        interval: 2400 + Math.round(Math.random() * 2600)
        running: mascot.visible && mascot.mood !== "sleepy" && mascot.mood !== "surprised"
        repeat: true
        onTriggered: { mascot.blinking = true; blinkOff.restart(); }
    }
    Timer { id: blinkOff; interval: 120; onTriggered: mascot.blinking = false }

    Loader {
        id: entryLoader
        anchors.fill: parent
        source: mascot.entry
    }
    // Bind the shared contract onto the loaded species declaratively (a QML
    // `palette` property would clash with Item.palette if set imperatively).
    Binding { target: entryLoader.item; property: "mood";     value: mascot.mood }
    Binding { target: entryLoader.item; property: "lookX";    value: mascot.lookX }
    Binding { target: entryLoader.item; property: "lookY";    value: mascot.lookY }
    Binding { target: entryLoader.item; property: "tint";     value: mascot.tint }
    Binding { target: entryLoader.item; property: "crust";    value: mascot.crust }
    Binding { target: entryLoader.item; property: "text";     value: mascot.text }
    Binding { target: entryLoader.item; property: "red";      value: mascot.red }
    Binding { target: entryLoader.item; property: "blinking"; value: mascot.blinking }
    Binding { target: entryLoader.item; property: "clock";    value: mascot.clock }
    Binding { target: entryLoader.item; property: "palette";  value: mascot.palette }
    Binding { target: entryLoader.item; property: "options";  value: mascot.options }

    Text {
        visible: mascot.mood === "sleepy"
        text: "z"
        font.family: "Hack Nerd Font"
        font.pixelSize: mascot.zSize
        font.weight: Font.Black
        color: Qt.alpha(mascot.text, 0.7)
        x: mascot.width * 0.78
        y: 0 - Math.sin(mascot.clock / 30) * (mascot.zSize * 0.18)
        opacity: 0.6 + 0.4 * Math.sin(mascot.clock / 18)
    }
}
