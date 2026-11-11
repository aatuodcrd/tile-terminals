# Tile Terminals

A tiny macOS utility that detects how many **Terminal.app** and **iTerm2** windows you have open and automatically arranges them into a non-overlapping grid that fills your screen.

Whichever of the two apps are running get tiled together in a single grid; neither is launched if it isn't already open.

No more dragging and resizing windows by hand — run it and every terminal window snaps into a clean layout that uses the full visible area of your displays (minus the menu bar and Dock).

## Features

- **Readable size, every screen.** Each pane gets at least about 480×450 px (`minColW`/`minRowH`, roughly 60 columns × 25 lines), so a screen holds a fixed number of panes — 8 on 1920×1080, more rows on a portrait display. Windows fill the main screen first, then your other screens, most recently used first.
- **Split panes get more room.** An iTerm window's size is weighted by the number of split panes in its visible tab — a window with 7 panes gets 7× the area of a single-pane one. Tabs don't add weight, since only one tab is visible at a time.
- **Stacked panes aren't squashed.** An iTerm window whose panes are split top/bottom gets a full-height column (landscape) or a band two rows tall (portrait). On landscape it uses whole grid columns (7 panes over 2 rows = 4 columns), so it may get a screen to itself.
- **One desktop at a time.** Only windows on the desktop (Space) you're looking at are tiled; other desktops are left alone, so you can tile each desktop separately.
- **Overflow goes to the Dock.** Windows that don't fit anywhere are minimized; minimized iTerm windows come back when there's room. (macOS doesn't let scripts move windows to another desktop/Space.) Minimized Terminal windows are left alone.
- **No wasted space.** Rows and columns stretch to fill each screen; two windows sit side by side.
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

1. Reads every display's visible frame (via `NSScreen`) and gives each a budget of readable cells (`cols × rows`).
2. Reads macOS's on-screen window list (`CGWindowListCopyWindowInfo`): it holds exactly the windows on the current desktop, front to back, and its window numbers are the ids iTerm and Terminal use. It also skips Terminal's hidden per-tab "windows". (If it can't be read, every window is used, and Terminal's ghost tabs are filtered by probing positions.)
3. Hands windows out front to back, each to the first screen with room for its panes; minimizes what doesn't fit.
4. On each screen: stacked-pane windows first, then the rest in as few balanced rows as needed, each window's width proportional to its pane count.

See [`Tile Terminals.applescript`](Tile%20Terminals.applescript) for the fully commented source.

## Requirements

- macOS (tested on recent versions)
- **Terminal.app** and/or **iTerm2** — at least one of them running

## License

[MIT](LICENSE)
