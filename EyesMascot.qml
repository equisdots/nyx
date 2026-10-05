import QtQuick
import QtQuick.Shapes

// ─────────────────────────────────────────────────────────────────────────────
// EyesMascot — the "eyes" species: just a pair of manga eyes. Big vertical
// ovals, a large tracking iris with two highlights, an angry slanted lash,
// sleepy lower lids and happy upward arcs. Design box: 100 x 118 units.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: eyes

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
    readonly property real eyeOpen: eyes.blinking ? 0.10
        : (mood === "sleepy" ? 0.50
        : (mood === "surprised" ? 1.15
        : (mood === "happy" ? 0.85 : 1.0)))

    function px(v) { return v * eyes.u }
    function happyEyeArcs() {
        return "M " + px(6) + " " + px(66)
            + " C " + px(12) + " " + px(44) + " " + px(38) + " " + px(44) + " " + px(44) + " " + px(66)
            + " M " + px(56) + " " + px(66)
            + " C " + px(62) + " " + px(44) + " " + px(88) + " " + px(44) + " " + px(94) + " " + px(66);
    }

    Repeater {
        model: [-1, 1]
        delegate: Item {
            id: bigEye
            required property int modelData
            readonly property real bw: eyes.width * 0.46
            readonly property real bh: eyes.height * 0.54
            readonly property real irisD: eyes.width * 0.20
            readonly property real trackX: Math.max(0.4, (bw - irisD) / 2)
            readonly property real trackY: Math.max(0.4, (bh - irisD) / 2)

            width: bw
            height: bh
            x: eyes.width * (modelData < 0 ? 0.03 : 0.51)
                + eyes.lookX * eyes.width * 0.08
            y: eyes.height * 0.25 + eyes.lookY * eyes.height * 0.06

            Item {
                anchors.fill: parent
                visible: eyes.mood !== "happy"
                transform: Scale {
                    yScale: eyes.eyeOpen
                    origin.y: bigEye.bh / 2
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: eyes.text
                }
                Rectangle {
                    width: bigEye.irisD
                    height: width
                    radius: width / 2
                    color: eyes.tint
                    scale: eyes.mood === "surprised" ? 0.72 : 1.0
                    x: (bigEye.bw - bigEye.irisD) / 2 + eyes.lookX * bigEye.trackX
                    y: (bigEye.bh - bigEye.irisD) / 2 + eyes.lookY * bigEye.trackY
                    Rectangle {
                        width: parent.width * 0.46
                        height: width
                        radius: width / 2
                        color: eyes.crust
                        anchors.centerIn: parent
                        Rectangle {
                            width: parent.width * 0.30
                            height: width
                            radius: width / 2
                            color: Qt.rgba(1, 1, 1, 0.9)
                            x: parent.width * 0.06
                            y: parent.height * 0.06
                        }
                    }
                    Rectangle {
                        width: parent.width * 0.20
                        height: width
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, 0.7)
                        x: parent.width * 0.12
                        y: parent.height * 0.64
                    }
                }
                // Angry upper lash: slanted band over the eye top.
                Rectangle {
                    visible: eyes.mood === "angry"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: parent.height * 0.38
                    color: eyes.tint
                    transformOrigin: modelData < 0 ? Item.BottomLeft : Item.BottomRight
                    rotation: modelData < 0 ? 10 : -10
                }
                // Sleepy lower lid.
                Rectangle {
                    visible: eyes.mood === "sleepy"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height * 0.42
                    color: eyes.tint
                }
            }
        }
    }

    // Happy manga eyes: two upward arcs.
    Shape {
        anchors.fill: parent
        visible: eyes.mood === "happy"
        ShapePath {
            fillColor: "transparent"
            strokeColor: eyes.text
            strokeWidth: eyes.u * 2.8
            capStyle: ShapePath.RoundCap
            PathSvg { path: eyes.happyEyeArcs() }
        }
    }
}
