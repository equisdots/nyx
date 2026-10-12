import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// Mascot — one mascot instance. Resolves the species (including the "mixed"
// rotation), owns its bob / blink state and mounts the matching species
// drawing. Live values (mood, look direction, position) come from the overlay.
//
// The mascot size is set by the host: width x 1.18.
// ─────────────────────────────────────────────────────────────────────────────

Item {
    id: mascot

    property int slot: 0
    property string species: "flame"      // built-in kind id
    property string entry: ""             // custom species: QML URL (overrides "species")
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

    readonly property bool custom: mascot.entry !== ""
    readonly property string kind: mascot.species === "mixed"
        ? ["cat", "dog", "eyes"][mascot.slot % 3]
        : mascot.species
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

    FlameMascot {
        anchors.fill: parent
        visible: !mascot.custom && mascot.kind === "flame"
        mood: mascot.mood
        lookX: mascot.lookX
        lookY: mascot.lookY
        tint: mascot.tint
        crust: mascot.crust
        text: mascot.text
        red: mascot.red
        blinking: mascot.blinking
        clock: mascot.clock
    }
    CatMascot {
        anchors.fill: parent
        visible: !mascot.custom && mascot.kind === "cat"
        mood: mascot.mood
        lookX: mascot.lookX
        lookY: mascot.lookY
        tint: mascot.tint
        crust: mascot.crust
        text: mascot.text
        red: mascot.red
        blinking: mascot.blinking
        clock: mascot.clock
    }
    DogMascot {
        anchors.fill: parent
        visible: !mascot.custom && mascot.kind === "dog"
        mood: mascot.mood
        lookX: mascot.lookX
        lookY: mascot.lookY
        tint: mascot.tint
        crust: mascot.crust
        text: mascot.text
        red: mascot.red
        blinking: mascot.blinking
        clock: mascot.clock
    }
    EyesMascot {
        anchors.fill: parent
        visible: !mascot.custom && mascot.kind === "eyes"
        mood: mascot.mood
        lookX: mascot.lookX
        lookY: mascot.lookY
        tint: mascot.tint
        crust: mascot.crust
        text: mascot.text
        red: mascot.red
        blinking: mascot.blinking
        clock: mascot.clock
    }
    DotsMascot {
        anchors.fill: parent
        visible: !mascot.custom && mascot.kind === "dots"
        mood: mascot.mood
        lookX: mascot.lookX
        lookY: mascot.lookY
        tint: mascot.tint
        crust: mascot.crust
        text: mascot.text
        red: mascot.red
        blinking: mascot.blinking
        clock: mascot.clock
        palette: mascot.palette
    }
    WatcherMascot {
        anchors.fill: parent
        visible: !mascot.custom && mascot.kind === "watcher"
        mood: mascot.mood
        lookX: mascot.lookX
        lookY: mascot.lookY
        tint: mascot.tint
        crust: mascot.crust
        text: mascot.text
        red: mascot.red
        blinking: mascot.blinking
        clock: mascot.clock
        palette: mascot.palette
        options: mascot.options
    }

    // Custom species: load the discovered QML and inject the same contract the
    // built-in species consume. Guarded so a user species that omits a property
    // still loads.
    Loader {
        id: customEntry
        anchors.fill: parent
        active: mascot.custom
        source: mascot.custom ? mascot.entry : ""
        onLoaded: {
            if (!item) return;
            const bind = (name, fn) => { try { item[name] = Qt.binding(fn); } catch (e) {} };
            bind("mood", () => mascot.mood);
            bind("lookX", () => mascot.lookX);
            bind("lookY", () => mascot.lookY);
            bind("tint", () => mascot.tint);
            bind("crust", () => mascot.crust);
            bind("text", () => mascot.text);
            bind("red", () => mascot.red);
            bind("blinking", () => mascot.blinking);
            bind("clock", () => mascot.clock);
            bind("palette", () => mascot.palette);
            bind("options", () => mascot.options);
        }
    }

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
