import QtQuick
import ".."

// CPU: total utilisation, sampled with top, colour by load.
InfoMascot {
    command: "LC_ALL=C top -bn1 2>/dev/null | awk '/%Cpu/ {printf \"%.0f\", 100-$8; exit}'"
    pollMs: 4000
    formatter: function (raw) {
        let v = parseInt(raw);
        if (isNaN(v)) return { glyph: "󰻠", value: "--", accent: palette.text };
        let a = v >= 80 ? palette.red : (v >= 50 ? palette.yellow : palette.blue);
        return { glyph: "󰻠", value: v + "%", accent: a };
    }
}
