import QtQuick
import QtQuick.Shapes

// ─────────────────────────────────────────────────────────────────────────────
// DogMascot — floppy ears peeking from behind the head, an eye patch, a lighter
// muzzle, a dark nose and a tongue when happy. Design box: 100 x 118 units.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: dog

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
    readonly property color shade: Qt.darker(dog.tint, 1.30)
    readonly property color lightenColor: Qt.lighter(dog.tint, 1.28)
    readonly property real earMood: mood === "angry" ? 1.0
        : (mood === "sleepy" ? 0.7
        : (mood === "surprised" ? 0.15
        : (mood === "happy" ? 0.35 : 0.5)))

    function px(v) { return v * dog.u }
    function ellipse(cx, cy, rx, ry) {
        return "M " + px(cx - rx) + " " + px(cy)
            + " A " + px(rx) + " " + px(ry) + " 0 1 0 " + px(cx + rx) + " " + px(cy)
            + " A " + px(rx) + " " + px(ry) + " 0 1 0 " + px(cx - rx) + " " + px(cy) + " Z";
    }
    function dogMouth() {
        if (mood === "surprised") return ellipse(50, 88, 3.6, 3.6);
        if (mood === "angry")
            return "M " + px(41) + " " + px(90) + " Q " + px(50) + " " + px(81) + " " + px(59) + " " + px(90);
        if (mood === "sleepy")
            return "M " + px(43) + " " + px(88) + " L " + px(57) + " " + px(88);
        if (mood === "happy")
            return "M " + px(38) + " " + px(84) + " Q " + px(50) + " " + px(98) + " " + px(62) + " " + px(84);
        return "M " + px(50) + " " + px(78) + " L " + px(50) + " " + px(82)
            + " M " + px(44) + " " + px(83) + " Q " + px(47) + " " + px(90) + " " + px(50) + " " + px(83)
            + " Q " + px(53) + " " + px(90) + " " + px(56) + " " + px(83);
    }
    function dogTongue() {
        if (dog.mood !== "happy") return "";
        return "M " + px(43) + " " + px(86)
            + " Q " + px(43) + " " + px(101) + " " + px(50) + " " + px(101)
            + " Q " + px(57) + " " + px(101) + " " + px(57) + " " + px(86) + " Z";
    }

    // Floppy ears (behind the head).
    Shape {
        anchors.fill: parent
        transform: Rotation {
            origin.x: dog.px(22)
            origin.y: dog.px(26)
            angle: -(14 + 26 * dog.earMood)
                - (dog.mood === "happy" ? Math.sin(dog.clock / 5) * 4 : 0)
            Behavior on angle { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        }
        ShapePath {
            fillColor: Qt.darker(dog.tint, 1.30)
            strokeColor: "transparent"
            strokeWidth: 0
            PathSvg { path: dog.ellipse(6, 52, 16, 30) }
        }
    }
    Shape {
        anchors.fill: parent
        transform: Rotation {
            origin.x: dog.px(78)
            origin.y: dog.px(26)
            angle: (14 + 26 * dog.earMood)
                + (dog.mood === "happy" ? Math.sin(dog.clock / 5) * 4 : 0)
            Behavior on angle { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        }
        ShapePath {
            fillColor: Qt.darker(dog.tint, 1.30)
            strokeColor: "transparent"
            strokeWidth: 0
            PathSvg { path: dog.ellipse(94, 52, 16, 30) }
        }
    }

    // Head.
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: dog.tint
            PathSvg { path: dog.ellipse(50, 64, 47, 51) }
        }
    }

    // Eye patch, muzzle, nose.
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: Qt.darker(dog.tint, 1.16)
            PathSvg { path: dog.ellipse(67, 54, 21, 20) }
        }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: dog.lightenColor
            PathSvg { path: dog.ellipse(50, 84, 20, 14) }
        }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: dog.crust
            PathSvg { path: dog.ellipse(50, 78, 8, 6) }
        }
    }

    // Mouth + tongue when happy.
    Shape {
        anchors.fill: parent
        ShapePath {
            fillColor: "transparent"
            strokeColor: dog.crust
            strokeWidth: dog.u * (dog.mood === "angry"
                || dog.mood === "surprised" ? 2.5 : 1.9)
            capStyle: ShapePath.RoundCap
            PathSvg { path: dog.dogMouth() }
        }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: dog.mood === "happy" ? Qt.alpha(dog.red, 0.95) : "transparent"
            PathSvg { path: dog.dogTongue() }
        }
    }

    MascotFaceEyes {
        anchors.fill: parent
        mood: dog.mood
        lookX: dog.lookX
        lookY: dog.lookY
        tint: dog.tint
        crust: dog.crust
        text: dog.text
        blinking: dog.blinking
    }
}
