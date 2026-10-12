import QtQuick

// Battery: level icon + percentage, colour by level / charging state.
InfoMascot {
    command: "cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); " +
             "st=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); " +
             "printf '%s|%s' \"$cap\" \"$st\""
    pollMs: 5000
    formatter: function (raw) {
        let p = raw.split("|");
        let cap = parseInt(p[0]);
        if (isNaN(cap)) return { glyph: "󰁹", value: "--", accent: palette.text };
        let st = (p[1] || "").trim().toLowerCase();
        let steps = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        let g = (st === "charging") ? "󰂄"
            : steps[Math.max(0, Math.min(10, Math.round(cap / 10)))];
        let a = (st === "charging") ? palette.green
            : (cap <= 20 ? palette.red : palette.text);
        return { glyph: g, value: cap + "%", accent: a };
    }
}
