import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// WatcherMascot — the "watcher" species: a living digital clock (HH:MM:SS).
//
// Every field retypes itself with a typewriter wipe: a small cursor runs left
// over the current digits (erasing them), the value swaps, then the cursor
// runs right revealing the new digits. Hours, minutes and seconds all animate
// on every change (the seconds wipe once per second).
//
// Options (via `options`): format "24"|"12", seconds bool, speed number
// (typewriter multiplier), moods bool, eye bool.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: watcher

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

    readonly property bool optSeconds: watcher.options.seconds !== false
    readonly property string optFormat: (watcher.options.format === "12") ? "12" : "24"
    readonly property real optSpeed: Math.max(0.4, Math.min(3.0,
        (typeof watcher.options.speed === "number") ? watcher.options.speed : 1.0))
    readonly property bool optMoods: watcher.options.moods !== false
    readonly property bool optEye: watcher.options.eye === true
    readonly property string optAccent: (watcher.options.accent === true) ? "accent" : "tint"

    readonly property real fs: Math.max(8, Math.round(watcher.height * 0.44))
    readonly property real u: Math.max(1, Math.round(watcher.height * 0.05))
    readonly property color baseText: (watcher.optMoods && watcher.mood === "angry") ? watcher.red : watcher.text
    readonly property color cursorColor: (watcher.optMoods && watcher.mood === "angry") ? watcher.red : watcher.tint
    readonly property real moodOpacity: (watcher.optMoods && watcher.mood === "sleepy") ? 0.55 : 1.0
    readonly property real blinkInterval: (watcher.optMoods && watcher.mood === "sleepy")
        ? 1400 / watcher.optSpeed : 1000 / watcher.optSpeed

    property int secTick: 0
    function pad(n) { return (n < 10 ? "0" : "") + n; }

    Timer {
        interval: 250
        repeat: true
        running: watcher.visible
        onTriggered: watcher.tick()
    }

    function tick() {
        let d = new Date();
        let h24 = d.getHours();
        let h = (watcher.optFormat === "12") ? (h24 % 12 || 12) : h24;
        let H = watcher.pad(h);
        let M = watcher.pad(d.getMinutes());
        let S = watcher.pad(d.getSeconds());
        if (fH.value !== H) fH.setValue(H, true);
        if (fM.value !== M) fM.setValue(M, true);
        if (watcher.optSeconds && fS.value !== S) fS.setValue(S, true);
        watcher.secTick = d.getSeconds();
    }

    // ── one typewriter field ────────────────────────────────────────────────
    component WField: Item {
        id: wf
        property string value: "00"
        property string shown: "00"
        property real fs: 10
        property real u: 1
        property real speed: 1
        property color textColor: "#cdd6f4"
        property color cursorColor: "#cba6f7"
        property real rev: 1

        readonly property real fullW: wfText.implicitWidth
        implicitWidth: fullW
        implicitHeight: wfText.implicitHeight

        function setValue(v, animate) {
            wf.value = v;
            if (!animate || wf.shown === v) {
                wf.shown = v;
                wf.rev = 1;
                anim.stop();
                return;
            }
            anim.restart();
        }

        Item {
            id: clip
            width: wf.fullW * wf.rev
            height: wf.height
            clip: true
            Text {
                id: wfText
                text: wf.shown
                font.family: "Hack Nerd Font"
                font.weight: Font.Black
                font.pixelSize: wf.fs
                color: wf.textColor
            }
        }
        Rectangle {
            x: clip.width - wf.u
            width: wf.u
            height: wf.height
            color: wf.cursorColor
            visible: wf.rev > 0.001 && wf.rev < 0.999
        }

        SequentialAnimation {
            id: anim
            NumberAnimation { target: wf; property: "rev"; to: 0
                duration: 150 / wf.speed; easing.type: Easing.InCubic }
            PropertyAction { target: wf; property: "shown"; value: wf.value }
            NumberAnimation { target: wf; property: "rev"; to: 1
                duration: 220 / wf.speed; easing.type: Easing.OutCubic }
        }
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: watcher.u
        opacity: watcher.moodOpacity
        y: (watcher.optMoods && watcher.mood === "happy" && watcher.visible)
            ? -Math.abs(Math.sin(watcher.clock / 6)) * watcher.u * 3 : 0

        // Little watcher eye (tracks the cursor).
        Item {
            visible: watcher.optEye
            anchors.verticalCenter: parent.verticalCenter
            width: watcher.fs * 1.5
            height: watcher.fs
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: watcher.baseText
            }
            Rectangle {
                width: watcher.fs * 0.5
                height: width
                radius: width / 2
                color: watcher.crust
                x: (parent.width - width) / 2 + watcher.lookX * watcher.fs * 0.22
                y: (parent.height - height) / 2 + watcher.lookY * watcher.fs * 0.22
            }
        }

        WField {
            id: fH
            fs: watcher.fs
            u: watcher.u
            speed: watcher.optSpeed
            textColor: watcher.baseText
            cursorColor: watcher.cursorColor
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ":"
            font.family: "Hack Nerd Font"
            font.weight: Font.Black
            font.pixelSize: watcher.fs
            color: watcher.baseText
            opacity: (watcher.secTick % 2 === 0) ? 1.0 : 0.3
        }
        WField {
            id: fM
            fs: watcher.fs
            u: watcher.u
            speed: watcher.optSpeed
            textColor: watcher.baseText
            cursorColor: watcher.cursorColor
        }
        Text {
            visible: watcher.optSeconds
            anchors.verticalCenter: parent.verticalCenter
            text: ":"
            font.family: "Hack Nerd Font"
            font.weight: Font.Black
            font.pixelSize: watcher.fs
            color: watcher.baseText
            opacity: (watcher.secTick % 2 === 0) ? 1.0 : 0.3
        }
        WField {
            id: fS
            visible: watcher.optSeconds
            fs: watcher.fs
            u: watcher.u
            speed: watcher.optSpeed
            textColor: watcher.baseText
            cursorColor: watcher.cursorColor
        }
        Text {
            visible: watcher.optFormat === "12"
            anchors.verticalCenter: parent.verticalCenter
            text: (new Date().getHours() < 12) ? "AM" : "PM"
            font.family: "Hack Nerd Font"
            font.weight: Font.Black
            font.pixelSize: Math.round(watcher.fs * 0.5)
            color: Qt.alpha(watcher.baseText, 0.7)
            leftPadding: watcher.u
        }
    }
}
