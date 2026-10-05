import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// MascotFaceEyes — the two face eyes shared by flame / cat / dog mascots.
//
// The pupils track the cursor: `lookX` / `lookY` are a smoothed unit vector
// (-1..1) computed by the overlay host. The travel is proportional to the eye
// size (pupil reaches the eye rim) plus a small whole-eye parallax, so the
// tracking reads at any mascot scale.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: face

    property string mood: "idle"
    property real lookX: 0
    property real lookY: 0
    property color tint: "#cba6f7"
    property color crust: "#11111b"
    property color text: "#cdd6f4"
    property bool blinking: false

    readonly property real eyeW: width * 0.26
    readonly property real eyeH: height * 0.28
    readonly property real pupilD: face.eyeW * 0.52
    readonly property real lookRange: Math.max(0.4, (face.eyeW - face.pupilD) / 2)
    readonly property real eyeOpen: face.blinking ? 0.10
        : (mood === "sleepy" ? 0.50
        : (mood === "surprised" ? 1.15
        : (mood === "angry" ? 0.85
        : (mood === "happy" ? 0.85 : 1.0))))

    Repeater {
        model: [-1, 1]
        delegate: Item {
            id: eyeRoot
            required property int modelData

            width: face.eyeW
            height: face.eyeH
            x: face.width * (modelData < 0 ? 0.20 : 0.54)
                + face.lookX * face.width * 0.06
            y: face.height * (face.mood === "surprised" ? 0.30 : 0.32)
                + face.lookY * face.height * 0.05

            Item {
                id: eyeLid
                anchors.fill: parent
                transform: Scale {
                    yScale: face.eyeOpen
                    origin.y: eyeLid.height / 2
                }
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: face.text
                }
                Rectangle {
                    visible: face.mood === "angry"
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: parent.height * 0.34
                    color: face.tint
                }
                Rectangle {
                    width: face.pupilD
                    height: face.pupilD
                    radius: width / 2
                    color: face.crust
                    x: (face.eyeW - face.pupilD) / 2 + face.lookX * face.lookRange
                    y: (face.eyeH - face.pupilD) / 2 + face.lookY * face.lookRange
                    Rectangle {
                        width: parent.width * 0.34
                        height: width
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, 0.85)
                        x: parent.width * 0.14
                        y: parent.height * 0.14
                    }
                }
            }
        }
    }

    // Brows only when the mood needs them; idle/happy stay clean.
    Repeater {
        model: [-1, 1]
        delegate: Rectangle {
            required property int modelData
            visible: face.mood === "angry" || face.mood === "surprised"
                || face.mood === "sleepy"
            width: face.width * 0.15
            height: Math.max(1, face.width * 0.026)
            radius: height / 2
            color: Qt.alpha(face.crust, 0.85)
            x: face.width * (modelData < 0 ? 0.27 : 0.60)
            y: face.height * (face.mood === "surprised" ? 0.255 : 0.275)
            rotation: face.mood === "angry" ? modelData * 22
                : (face.mood === "sleepy" ? -modelData * 10 : 0)
            Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on y { NumberAnimation { duration: 180 } }
        }
    }
}
