import QtQuick

// Wi-Fi: connected network signal strength.
InfoMascot {
    command: "LC_ALL=C nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | " +
             "awk -F: '/^\\*/ {print $2; exit}'"
    pollMs: 8000
    formatter: function (raw) {
        let v = parseInt(raw);
        if (isNaN(v)) return { glyph: "󰖪", value: "off", accent: palette.text };
        let g = v >= 75 ? "󰤨" : (v >= 50 ? "󰤥" : (v >= 25 ? "󰤢" : "󰤟"));
        return { glyph: g, value: v + "%", accent: palette.blue };
    }
}
