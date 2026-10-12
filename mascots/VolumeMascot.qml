import QtQuick

// Volume: sink level + mute state.
InfoMascot {
    command: "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | " +
             "awk '{printf \"%d|%s\", $2*100, (index($0,\"MUTED\")?1:0)}'"
    pollMs: 2500
    formatter: function (raw) {
        let p = raw.split("|");
        let v = parseInt(p[0]);
        if (isNaN(v)) return { glyph: "󰕾", value: "--", accent: palette.text };
        let muted = p[1] === "1";
        let g = muted ? "󰝟" : (v >= 66 ? "󰕾" : (v >= 33 ? "󰖀" : "󰕿"));
        return { glyph: g, value: muted ? "mute" : v + "%", accent: muted ? palette.red : palette.text };
    }
}
