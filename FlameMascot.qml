import QtQuick
import QtQuick.Shapes

// ─────────────────────────────────────────────────────────────────────────────
// FlameMascot — the default little fire: teardrop with a wavy tip that wiggles
// from the base, plus a lighter inner tongue and a mood-driven mouth.
// Design box: 100 x 118 units.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: flame

    property string mood: "idle"
    property real lookX: 0
    property real lookY: 0
    property color tint: "#cba6f7"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property color red: "#f38ba8"
    property bool blinking: false
    property real clock: 0

    readonly property real u: width / 100
    readonly property color lightenColor: Qt.lighter(flame.tint, 1.32)

    function px(v) { return v * flame.u }
    function flameOuter() {
        // Main tip, small left lobe, belly and a concave lick on the right:
        // reads as fire, not as a drop.
        return "M " + px(56) + " " + px(2)
            + " C " + px(48) + " " + px(16) + " " + px(40) + " " + px(22) + " " + px(36) + " " + px(30)
            + " C " + px(30) + " " + px(24) + " " + px(21) + " " + px(28) + " " + px(17) + " " + px(44)
            + " C " + px(11) + " " + px(60) + " " + px(14) + " " + px(82) + " " + px(24) + " " + px(96)
            + " C " + px(32) + " " + px(108) + " " + px(44) + " " + px(114) + " " + px(54) + " " + px(112)
            + " C " + px(70) + " " + px(110) + " " + px(84) + " " + px(98) + " " + px(84) + " " + px(80)
            + " C " + px(84) + " " + px(62) + " " + px(76) + " " + px(54) + " " + px(77) + " " + px(40)
            + " C " + px(78) + " " + px(26) + " " + px(64) + " " + px(12) + " " + px(56) + " " + px(2) + " Z";
    }
    function flameInner() {
        // Small inner tongue under the face, tip leaning left.
        return "M " + px(50) + " " + px(58)
            + " C " + px(44) + " " + px(70) + " " + px(38) + " " + px(76) + " " + px(40) + " " + px(88)
            + " C " + px(42) + " " + px(100) + " " + px(56) + " " + px(102) + " " + px(58) + " " + px(90)
            + " C " + px(60) + " " + px(78) + " " + px(54) + " " + px(68) + " " + px(50) + " " + px(58) + " Z";
    }

    Shape {
        anchors.fill: parent
        transform: Rotation {
            origin.x: flame.px(50)
            origin.y: flame.px(112)
            angle: Math.sin(flame.clock / 26) * 3
        }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: flame.tint
            PathSvg { path: flame.flameOuter() }
        }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: flame.lightenColor
            PathSvg { path: flame.flameInner() }
        }
    }

    // Mouth (the shared face provides the eyes and brows).
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: flame.height * 0.66
        width: flame.width * (flame.mood === "happy" ? 0.28
            : (flame.mood === "surprised" ? 0.16 : 0.20))
        height: flame.mood === "happy" ? flame.height * 0.14
            : (flame.mood === "surprised" ? flame.height * 0.14 : flame.height * 0.035)
        radius: height / 2
        color: flame.crust
        Behavior on width { NumberAnimation { duration: 180 } }
        Behavior on height { NumberAnimation { duration: 180 } }
    }

    MascotFaceEyes {
        anchors.fill: parent
        mood: flame.mood
        lookX: flame.lookX
        lookY: flame.lookY
        tint: flame.tint
        crust: flame.crust
        text: flame.text
        blinking: flame.blinking
    }
}
