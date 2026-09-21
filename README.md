# Tile Terminals

A tiny macOS utility that detects how many **Terminal.app** and **iTerm2** windows you have open and automatically arranges them into a non-overlapping grid that fills your screen.

Whichever of the two apps are running get tiled together in a single grid; neither is launched if it isn't already open.

No more dragging and resizing windows by hand — run it and every terminal window snaps into a clean layout that uses the full visible area of your main display (minus the menu bar and Dock).

## Features

- **Auto-counts real windows.** Terminal's scripting API lists one "window" per *tab*, so a window with N tabs appears N times — and only one of those actually controls the frame. Tile Terminals probes each window object to find the genuinely controllable ones and tiles only those.
- **At most two rows.** Every window keeps at least half the screen height, so a tall terminal stays readable however many you have open.
- **Fills the screen.** The last row stretches to use the full width, leaving no wasted space.
- **Restores minimized windows** so they get tiled too.
- **One permission, one time.** Only needs the "control Terminal" / "control iTerm" automation permission on first run.
- **Starts instantly.** Detects running apps with `running of application`, not System Events' `exists process` — the latter blocks for ~12 seconds when the app you ask about *isn't* running.

## Usage

### Option A — run the app (easiest)

1. Download **`Tile Terminals.app`** from this repo.
2. Move it to `/Applications` (optional).
3. Double-click it. The first time, macOS will ask you to grant permission to control Terminal — click **OK**.

> Because the app isn't notarized by Apple, the first launch may need you to right-click → **Open**, or go to **System Settings → Privacy & Security** and click **Open Anyway**.

### Option B — run the source from Script Editor

1. Open `Tile Terminals.applescript` in **Script Editor**.
2. Press the **Run** (▶) button.

### Option C — run from the command line

```bash
osascript "Tile Terminals.applescript"
```

You can also bind it to a keyboard shortcut with a tool like [Raycast](https://raycast.com), [BetterTouchTool](https://folivora.ai), or an Automator Quick Action.

## How it works

The script reads your main display's visible frame (via `NSScreen`), converts it from Cocoa's bottom-left coordinate system to the terminal's top-left bounds coordinates, then:

1. **Pass A** — assigns each window a unique probe position and reads it back; only windows whose position "stuck" are real, controllable windows (this filters out ghost tab-duplicates).
2. Computes the grid: `rows = min(n, 2)`, `cols = ceil(n / rows)`.

   iTerm has no ghost tab-duplicates, so its windows skip Pass A and are taken as-is.
3. **Pass B** — places windows row by row, stretching the final row to fill the width.

See [`Tile Terminals.applescript`](Tile%20Terminals.applescript) for the fully commented source.

## Requirements

- macOS (tested on recent versions)
- **Terminal.app** and/or **iTerm2** — at least one of them running

## License

[MIT](LICENSE)
