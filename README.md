# Tile Terminals

A tiny macOS utility that detects how many **Terminal.app** and **iTerm2** windows you have open and automatically arranges them into a non-overlapping grid that fills your screen.

Whichever of the two apps are running get tiled together in a single grid; neither is launched if it isn't already open.

No more dragging and resizing windows by hand — run it and every terminal window snaps into a clean layout that uses the full visible area of your displays (minus the menu bar and Dock).

## Features

- **Readable size, every screen.** Each pane gets at least about 480×450 px (`minColW`/`minRowH`, roughly 60 columns × 25 lines), so a screen holds a fixed number of panes — 8 on 1920×1080, more rows on a portrait display. Windows are placed most recently used first.
- **Split panes get more room.** An iTerm window's size is weighted by the number of split panes in its visible tab — a window with 7 panes gets 7× the area of a single-pane one. Tabs don't add weight, since only one tab is visible at a time.
- **Stacked panes aren't squashed.** An iTerm window whose panes are split top/bottom gets a full-height column (landscape) or a band two rows tall (portrait). On landscape it uses whole grid columns (7 panes over 2 rows = 4 columns), so it may get a screen to itself.
- **Every desktop.** Each desktop (Space) is tiled on the screen it belongs to, including desktops you aren't looking at. Windows stay on their desktop and screen: macOS doesn't let scripts move windows between desktops, and won't reliably move one onto another screen's desktop. Full-screen apps are skipped.
- **Overflow goes to the Dock.** Windows that don't fit anywhere are minimized; minimized iTerm windows come back (to the desktop showing on the main screen) when there's room. Minimized Terminal windows are left alone.
- **No wasted space, nothing hidden.** Rows and columns stretch to fill each screen; two windows sit side by side. Tiled windows on the desktops showing now are brought in front of other apps (without jumping to another desktop).
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
2. Reads macOS's window list (`CGWindowListCopyWindowInfo`), whose window numbers are the ids iTerm and Terminal use, and asks macOS which desktop each window is on and which screen each desktop belongs to. These are read-only private calls (`CGSCopySpacesForWindows`, `CGSCopyManagedDisplaySpaces`). If they ever stop working, it falls back to the public on-screen list and tiles only the desktops showing now.
3. For each desktop: hands windows out front to back and minimizes what doesn't fit.
4. On each screen: stacked-pane windows first, then the rest in as few balanced rows as needed, each window's width proportional to its pane count.
5. Brings the tiled windows on the desktops showing now to the front.

Terminal.app windows are only tiled on desktops showing now: Terminal lists one hidden "window" per tab, and only the on-screen list can tell the real one apart.

See [`Tile Terminals.applescript`](Tile%20Terminals.applescript) for the fully commented source.

## Requirements

- macOS (tested on recent versions)
- **Terminal.app** and/or **iTerm2** — at least one of them running

## License

[MIT](LICENSE)
