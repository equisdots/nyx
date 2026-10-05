.pragma library

// ─────────────────────────────────────────────────────────────────────────────
// MascotMetrics — vendored scale helpers.
//
// The mascots module is meant to be extracted to its own repo, so it does not
// import the shell's WindowRegistry.js. Keep this file dependency-free; the
// formulas mirror the shell scale (base on 1920x1080, user uiScale on top).
// ─────────────────────────────────────────────────────────────────────────────

function getScale(mw, mh, userScale) {
    if (arguments.length === 2) {
        userScale = mh;
        mh = mw * (1080.0 / 1920.0);
    }
    if (mw <= 0 || mh <= 0) return 1.0;

    let rw = mw / 1920.0;
    let rh = mh / 1080.0;
    let r = Math.min(rw, rh);

    let baseScale = 1.0;
    if (r <= 1.0) baseScale = Math.max(0.35, Math.pow(r, 0.85));
    else baseScale = Math.pow(r, 0.5);

    return baseScale * (userScale !== undefined ? userScale : 1.0);
}

function s(val, scale) {
    return Math.round(val * scale);
}
