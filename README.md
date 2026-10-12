<div align="center">

```
   ╲   ╱╲   ╱    ─────────────
    ╲ ╱  ╲ ╱     N Y X
     ✕    ✕      ─────
    ╱ ╲  ╱ ╲     mascot island + notch
   ╱   ╲╱   ╲    ╲_____╱
```

**Nyx** — the self-contained Quickshell mascot island and control-center notch.

</div>

Never imports the shell core: the palette, the settings path and the live data
are injected, and the only runtime requirements are Quickshell (Wayland),
Hyprland (`hyprctl cursorpos`, socket2) and a Nerd Font.

```
nyx/
  nyx.json             registry: name, path and author of every component
  front/               the "chrome" — island/notch window + control center
    MascotsOverlay.qml  per-screen island/notch window (positions, cursor +
                        event polling, moods, dock host)
    MascotDock.qml      control center: search, hero, quick actions, grid, tabs
  mascots/             the mascots themselves
    species.json        shipped manifests: one entry per built-in species
    Mascot.qml          one instance: species resolution, bob, blink; loads a
                        custom species' QML when the manifest carries "entry"
    FlameMascot.qml     default species: little fire with mouth
    CatMascot.qml       pointy ears, stripes, whiskers, pink nose
    DogMascot.qml       floppy ears, eye patch, muzzle, tongue when happy
    EyesMascot.qml      eyes-only: pair of manga eyes with expressions
    DotsMascot.qml      colored dots that trail the cursor (no face)
    WatcherMascot.qml   digital clock retyped with a typewriter cursor
    MascotFaceEyes.qml  shared face eyes/brows (flame / cat / dog)
    MascotMetrics.js    vendored scale helpers (no shell imports)
```

## Settings (when `settingsPath` is set)

| Key | Values | Default | Meaning |
| --- | --- | --- | --- |
| `mascots.enabled` | bool | `false` | master switch |
| `mascots.species` | id or `[id, …]` | `flame` | look: one id for every mascot (or `mixed`), or an **array** = one mascot per id (the lineup). ids come from the discovered catalog |
| `mascots.count` | 1..8 | `3` | mascots in the island (string mode only; array mode uses the lineup length) |
| `mascots.size` | 0.6..1.6 | `1.0` | mascot scale |
| `mascots.position` | `top-left` … `bottom-right` | `top-center` | island position; the dock unfolds toward the screen centre (up when the island is at the bottom) |
| `mascots.appearance` | `island` `notch` | `island` | `notch` snaps to the top edge with a macOS-style silhouette (no coloured border); dock still floats |
| `mascots.notchWidth` | px (design units) | `260` | notch width; clamped to fit the mascots and to half the screen |
| `mascots.notchHeight` | px (design units) | `0` | notch height; `0` = automatic (mascot height + padding) |
| `mascots.notchOffset` | px (design units) | `0` | vertical offset; negative tucks the notch up into the screen edge |
| `mascots.notchReserve` | bool | `true` | in notch mode, reserve the top strip so maximized windows clear it (exclusive zone) |
| `mascots.dock.size` | `compact` `medium` `large` `wide` | `large` | control-center panel width preset |
| `mascots.dock.width` | px (design units) | `0` | explicit panel width (`0` = use the preset) |
| `mascots.dock.style` | `floating` `joined` | `floating` | `joined` welds the panel under the notch (notch widens + squares off) |
| `mascots.dock.columns` / `rows` | 3..7 / 1..3 | `5` / `2` | widget grid shape (page size = columns × rows) |
| `mascots.dock.hero` / `quick` / `search` | bool | `true` | show the clock + now-playing hero, quick actions and search |
| `mascots.dock.favorites` | array of widget ids | `[]` | tiles pinned to the dock's Favorites tab |
| `mascots.watcher.format` | `24` `12` | `24` | Watcher clock format |
| `mascots.watcher.seconds` | bool | `true` | show the seconds field |
| `mascots.watcher.speed` | number | `1.0` | typewriter speed multiplier |
| `mascots.watcher.moods` | bool | `true` | mood-driven effects (angry red, sleepy dim, happy bounce) |
| `mascots.watcher.eye` | bool | `false` | little tracking eye next to the clock |
| `mascots.profiles` | object | `{}` | named presets of the whole mascots block (saved in the editor) |
| `uiScale` | number | `1.0` | extra user scale |
| `bar.position` / `bar.thickness` | string / px | `top` / 48 | island margin below the bar band |

## Extending: species & notch cards

Both are **discovered** from a shipped (repo) dir and a user dir; a user file
whose `id` matches a shipped one overrides it. Drop a file and restart the shell
(or call `MascotsCatalog.refresh()` in the equisdots shell) to pick it up.

**Species** — `~/.config/hypr/mascots/species/*.json`
(shipped: `mascots/species.json`):

```json
{ "id": "moon", "label": "Moon", "icon": "󰽦", "entry": "Moon.qml", "order": 100 }
```

`entry` is a QML file next to the manifest; omit it to use a built-in kind
(`flame` `cat` `dog` `eyes` `dots` `watcher`). The QML root may declare any of
`mood`, `lookX`, `lookY`, `tint`, `crust`, `text`, `red`, `blinking`, `clock`,
`palette`, `options` — the host binds them. Enable species in Settings → Mascots;
each enabled species adds one mascot and the island width follows the count.

`customizable` lists the option names a species accepts (`["color","size"]`);
the host passes them through `options` from `settings → mascots.options.<id>`
(`color` = a palette role or `#hex`, `size` = a 0.6..1.8 content scale). A
`controls` array is the richer form: `[{"type":"color"},{"type":"size"},
{"type":"text","key":"user","label":"User","placeholder":"…","default":"…"}]`
— a `text` control stores a string under `options.<key>`. The shipped info
species (`battery`, `cpu`, `memory`, `wifi`, `volume`, `temperature`) declare
`customizable` and are built on `InfoMascot`, which applies colour and size.

`popover` (optional) is a QML file next to the manifest. A species that declares
one becomes **clickable**: clicking its mascot opens that popover in a panel
under/over the island (clicking the island again, or anywhere outside, collapses
it). The popover root's contract is `options`, `palette`, `scaleUnit`, `accent`.
The shipped `github` species uses this: the octocat opens the contribution
heatmap for `options.user` (see `mascots/GithubMascot.qml` +
`mascots/GithubPopover.qml`).

**Notch cards** — `~/.config/hypr/mascots/notch/*.json`
(shipped: the shell's `notch/defaults.json`):

```json
{ "id": "weather", "label": "Weather", "icon": "󰖐", "exec": "…" }
```

`exec` runs a shell command when the card is picked; without it the card opens
the shell panel with that `id`. Add `"enabled": false` to hide a shipped card
and `"thumb"` for a preview image.

## Public API (per screen)

`MascotsOverlay` exposes `enabled`, `species` (string or array), `mascotCatalog`,
`count`, `size`, `uiScale`,
`position`, `barPosition`, `barThickness`, `appearance`, `notchWidth`,
`notchHeight`, `notchOffset`, `notchReserve`, `dockSize`, `dockWidth`,
`dockStyle`, `dockColumns`, `dockRows`, `dockShowHero`, `dockShowQuick`,
`dockShowSearch`, `quickActions`, `quickHandler`, `stats`, `favorites`,
`watcherFormat`, `watcherSeconds`, `watcherSpeed`, `watcherMoods`,
`watcherEye`, `palette`, `settingsPath`,
`widgetStatePath`, `dockWidgetName`, `widgetRectProvider`, `widgetList` and
`widgetLauncher`. The palette object needs `base`, `surface1`, `text`, `crust`,
`red`, `yellow`, `green`, `blue`, `mauve` (colors) and `glassOn` (bool); a
Catppuccin-Mocha fallback is built in. `widgetRectProvider(name, sw, sh,
uiScale)` returns `{ x, y, w, h }` in screen coordinates for widgets that
should hide the island when they overlap it; `dockWidgetName` hides the island
entirely for that widget (e.g. a dock). `widgetList` is an array of
`{ id, label, icon }` cards shown in the click dock; an entry may also carry an
optional `thumb` (path or URL), shown instead of the icon once it loads (e.g. a
live wallpaper preview). `widgetLauncher(id)` is called when one is picked.

## Integration example

```qml
Item {
    Colors { id: themeColors }              // your palette source

    MascotsOverlay {
        palette: themeColors
        settingsPath: "~/.config/hypr/settings.json"
        widgetStatePath: "/run/user/1000/quickshell/current_widget"
        dockWidgetName: "applauncher"
        widgetRectProvider: (name, sw, sh, scale) => computeRect(name)
    }
}
```

The overlay is a click-through layer surface (`qs-mascots`, mask 0x0), one per
screen, and it never captures input.
