import QtQuick
import ".."

// Temperature: CPU/SoC thermal zone, colour by threshold.
InfoMascot {
    command: "t=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null); " +
             "[ -n \"$t\" ] && awk -v t=\"$t\" 'BEGIN{printf \"%d\", t/1000}'"
    pollMs: 5000
    formatter: function (raw) {
        let v = parseInt(raw);
        if (isNaN(v)) return { glyph: "󰔄", value: "--", accent: palette.text };
        let a = v >= 80 ? palette.red : (v >= 60 ? palette.yellow : palette.green);
        return { glyph: "󰔄", value: v + "°", accent: a };
    }
}
