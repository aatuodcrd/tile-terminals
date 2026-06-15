# Tile Terminals

A tiny macOS utility that detects how many **Terminal.app** windows you have open and automatically arranges them into a non-overlapping grid that fills your screen.

No more dragging and resizing windows by hand — run it and every Terminal window snaps into a clean, near-square layout that uses the full visible area of your main display (minus the menu bar and Dock).

## Features

- **Auto-counts real windows.** Terminal's scripting API lists one "window" per *tab*, so a window with N tabs appears N times — and only one of those actually controls the frame. Tile Terminals probes each window object to find the genuinely controllable ones and tiles only those.
- **Near-square grid.** Picks a column/row count close to a square so the layout looks balanced no matter how many windows you have.
- **Fills the screen.** The last row stretches to use the full width, leaving no wasted space.
- **Restores minimized windows** so they get tiled too.
- **One permission, one time.** Only needs the "control Terminal" automation permission on first run.

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

The script reads your main display's visible frame (via `NSScreen`), converts it from Cocoa's bottom-left coordinate system to Terminal's top-left bounds coordinates, then:

1. **Pass A** — assigns each window a unique probe position and reads it back; only windows whose position "stuck" are real, controllable windows (this filters out ghost tab-duplicates).
2. Computes a near-square grid: `cols = ceil(sqrt(n))`, `rows = ceil(n / cols)`.
3. **Pass B** — places windows row by row, stretching the final row to fill the width.

See [`Tile Terminals.applescript`](Tile%20Terminals.applescript) for the fully commented source.

## Requirements

- macOS (tested on recent versions)
- The built-in **Terminal.app**

## License

[MIT](LICENSE)
