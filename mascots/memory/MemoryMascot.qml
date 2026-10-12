import QtQuick
import ".."

// Memory: used RAM as a percentage of total.
InfoMascot {
    command: "LC_ALL=C free 2>/dev/null | awk '/^Mem:/ {printf \"%.0f\", $3/$2*100}'"
    pollMs: 5000
    formatter: function (raw) {
        let v = parseInt(raw);
        if (isNaN(v)) return { glyph: "󰍛", value: "--", accent: palette.text };
        let a = v >= 85 ? palette.red : (v >= 65 ? palette.yellow : palette.green);
        return { glyph: "󰍛", value: v + "%", accent: a };
    }
}
