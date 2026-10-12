import QtQuick

// GitHub mascot: the octocat mark. Clicking it opens the contribution-graph
// popover (see GithubPopover.qml). Honours options.color / options.size.
Item {
    id: gh

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

    readonly property real contentScale: (options && typeof options.size === "number")
        ? Math.max(0.5, Math.min(2.0, options.size)) : 1.0
    function resolveColor(c) {
        if (!c) return (palette.text !== undefined ? palette.text : tint);
        return (palette && palette[c] !== undefined) ? palette[c] : c;
    }
    readonly property color col: (options && options.color) ? resolveColor(options.color) : tint

    scale: mood === "happy" ? 1.06 : 1.0
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

    Text {
        anchors.centerIn: parent
        text: "\uf09b"
        font.family: "Hack Nerd Font"
        font.pixelSize: parent.height * 0.66
        color: gh.col
        scale: gh.contentScale
        Behavior on color { ColorAnimation { duration: 300 } }
    }
}
