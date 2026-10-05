import QtQuick
import QtQuick.Shapes

// ─────────────────────────────────────────────────────────────────────────────
// CatMascot — pointy ears (with inner ear), forehead stripes, whiskers, pink
// nose and a mood-driven mouth. Design box: 100 x 118 units, scaled by `u`.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: cat

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
    readonly property color shade: Qt.darker(cat.tint, 1.22)
    readonly property color lightenColor: Qt.lighter(cat.tint, 1.32)
    readonly property real earMood: mood === "angry" ? 1.0
        : (mood === "sleepy" ? 0.7
        : (mood === "surprised" ? 0.15
        : (mood === "happy" ? 0.35 : 0.5)))

    function px(v) { return v * cat.u }
    function ellipse(cx, cy, rx, ry) {
        return "M " + px(cx - rx) + " " + px(cy)
            + " A " + px(rx) + " " + px(ry) + " 0 1 0 " + px(cx + rx) + " " + px(cy)
            + " A " + px(rx) + " " + px(ry) + " 0 1 0 " + px(cx - rx) + " " + px(cy) + " Z";
    }
    function catEar(side) {
        let ox = side < 0 ? 4 : 96;
        let bx = side < 0 ? 46 : 54;
        let lean = side * (cat.earMood - 0.5) * 14;
        let tipX = (side < 0 ? 19 : 81) + lean;
        let tipY = 2 + (cat.mood === "surprised" ? -2 : 4 * cat.earMood);
        return "M " + px(ox) + " " + px(32)
            + " Q " + px(ox + side * 7) + " " + px(9) + " " + px(tipX) + " " + px(tipY)
            + " Q " + px(tipX - side * 10) + " " + px(tipY + 7) + " " + px(bx) + " " + px(26) + " Z";
    }
    function catEarInner(side) {
        let lean = side * (cat.earMood - 0.5) * 10;
        let tipX = (side < 0 ? 21 : 79) + lean;
        let bx = side < 0 ? 40 : 60;
        return "M " + px(side < 0 ? 13 : 87) + " " + px(27)
            + " Q " + px(side < 0 ? 17 : 83) + " " + px(13) + " " + px(tipX) + " " + px(11)
            + " Q " + px(tipX - side * 7) + " " + px(17) + " " + px(bx) + " " + px(25) + " Z";
    }
    function catStripes() {
        return "M " + px(43) + " " + px(23) + " L " + px(46) + " " + px(32)
            + " M " + px(50) + " " + px(21) + " L " + px(50) + " " + px(31)
            + " M " + px(57) + " " + px(23) + " L " + px(54) + " " + px(32);
    }
    function catWhiskers() {
        let s = "";
        s += " M " + px(40) + " " + px(76) + " L " + px(9) + " " + px(69);
        s += " M " + px(40) + " " + px(81) + " L " + px(6) + " " + px(80);
        s += " M " + px(40) + " " + px(86) + " L " + px(10) + " " + px(91);
        s += " M " + px(60) + " " + px(76) + " L " + px(91) + " " + px(69);
        s += " M " + px(60) + " " + px(81) + " L " + px(94) + " " + px(80);
        s += " M " + px(60) + " " + px(86) + " L " + px(90) + " " + px(91);
        return s;
    }
    function catNose() {
        return "M " + px(45) + " " + px(75)
            + " L " + px(55) + " " + px(75)
            + " L " + px(50) + " " + px(81) + " Z";
    }
    function catMouth() {
        if (mood === "surprised") return ellipse(50, 87, 3.4, 3.4);
        if (mood === "angry")
            return "M " + px(41) + " " + px(88) + " Q " + px(50) + " " + px(80) + " " + px(59) + " " + px(88);
        if (mood === "sleepy")
            return "M " + px(43) + " " + px(87) + " L " + px(57) + " " + px(87);
        if (mood === "happy")
            return "M " + px(50) + " " + px(82)
                + " Q " + px(46) + " " + px(92) + " " + px(38) + " " + px(86)
                + " M " + px(50) + " " + px(82)
                + " Q " + px(54) + " " + px(92) + " " + px(62) + " " + px(86);
        return "M " + px(50) + " " + px(82)
            + " Q " + px(46) + " " + px(87) + " " + px(41) + " " + px(83)
            + " M " + px(50) + " " + px(82)
            + " Q " + px(54) + " " + px(87) + " " + px(59) + " " + px(83);
    }

    // Cat ears (behind the head).
    Shape {
        anchors.fill: parent
        ShapePath {
            fillColor: cat.tint
            strokeColor: cat.tint
            strokeWidth: cat.u * 2
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: cat.catEar(-1) }
        }
        ShapePath {
            fillColor: cat.tint
            strokeColor: cat.tint
            strokeWidth: cat.u * 2
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: cat.catEar(1) }
        }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: cat.lightenColor
            PathSvg { path: cat.catEarInner(-1) }
        }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: cat.lightenColor
            PathSvg { path: cat.catEarInner(1) }
        }
    }

    // Head.
    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillColor: cat.tint
            PathSvg { path: cat.ellipse(50, 64, 47, 51) }
        }
    }

    // Stripes, whiskers, nose, mouth.
    Shape {
        anchors.fill: parent
        ShapePath {
            fillColor: "transparent"
            strokeColor: cat.shade
            strokeWidth: cat.u * 2.4
            capStyle: ShapePath.RoundCap
            PathSvg { path: cat.catStripes() }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(cat.crust, 0.5)
            strokeWidth: cat.u * 1.1
            capStyle: ShapePath.RoundCap
            PathSvg { path: cat.catWhiskers() }
        }
        ShapePath {
            fillColor: Qt.alpha(cat.red, 0.95)
            strokeColor: Qt.alpha(cat.red, 0.95)
            strokeWidth: cat.u * 1.5
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: cat.catNose() }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: cat.crust
            strokeWidth: cat.u * (cat.mood === "angry"
                || cat.mood === "surprised" ? 2.4 : 1.8)
            capStyle: ShapePath.RoundCap
            PathSvg { path: cat.catMouth() }
        }
    }

    MascotFaceEyes {
        anchors.fill: parent
        mood: cat.mood
        lookX: cat.lookX
        lookY: cat.lookY
        tint: cat.tint
        crust: cat.crust
        text: cat.text
        blinking: cat.blinking
    }
}
