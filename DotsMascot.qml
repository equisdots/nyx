import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// DotsMascot — the "dots" species: a cluster of small colored dots that trail
// the cursor inside the island. No face, no eyes: the cluster leans toward the
// cursor direction, swirls gently on its own and scatters/bounces with the
// mood (surprised widens the reach, sleepy droops, happy bounces, angry
// jitters). Design box: 100 x 118 units.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: dots

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

    readonly property real u: width / 100
    readonly property int dotCount: 6
    // How far the cluster reaches toward the cursor for the current mood.
    readonly property real reach: mood === "surprised" ? 1.65
        : (mood === "sleepy" ? 0.45 : (mood === "happy" ? 1.1 : 1.0))

    // One palette colour per dot (tint-based fallbacks when no palette).
    function dotColor(i) {
        let p = dots.palette || {};
        let c = [p.mauve, p.blue, p.green, p.yellow, p.red, p.text][i % 6];
        if (c === undefined || c === null) {
            c = [dots.tint, Qt.lighter(dots.tint, 1.3), Qt.darker(dots.tint, 1.2),
                 dots.red, dots.text, Qt.lighter(dots.tint, 1.5)][i % 6];
        }
        return c;
    }

    function clampX(v) { return Math.max(dots.u * 8, Math.min(dots.width - dots.u * 8, v)); }
    function clampY(v) { return Math.max(dots.u * 10, Math.min(dots.height - dots.u * 10, v)); }

    function dotX(i) {
        let cx = dots.width / 2;
        // Fan out toward the cursor: the first dot leads, the rest trail.
        let lead = 8 + i * 4.2;
        let sx = dots.lookX * dots.u * lead * dots.reach;
        let swirl = Math.sin(dots.clock / 42 + i * 1.7) * dots.u * 2.2;
        let jitter = dots.mood === "angry" ? Math.sin(dots.clock / 1.7 + i * 2.1) * dots.u * 2.4 : 0;
        let spread = (i % 2 ? 1 : -1) * dots.u * 4.6;
        return dots.clampX(cx + sx - dots.lookY * swirl + jitter + spread);
    }

    function dotY(i) {
        let cy = dots.height * 0.52;
        let trail = 5 + i * 2.6;
        let sy = dots.lookY * dots.u * trail * dots.reach;
        let swirl = Math.sin(dots.clock / 42 + i * 1.7) * dots.u * 2.2;
        let bounce = dots.mood === "happy" ? -Math.sin(dots.clock / 6 + i * 1.3) * dots.u * 3.2 : 0;
        let droop = dots.mood === "sleepy" ? dots.u * 7 : 0;
        let spread = (i % 3 - 1) * dots.u * 3.6;
        return dots.clampY(cy + sy + dots.lookX * swirl + bounce + droop + spread);
    }

    Repeater {
        model: dots.dotCount
        delegate: Rectangle {
            required property int index
            width: dots.u * (10 - (index % 3))
            height: width
            radius: width / 2
            color: dots.dotColor(index)
            x: dots.dotX(index) - width / 2
            y: dots.dotY(index) - height / 2
        }
    }
}
