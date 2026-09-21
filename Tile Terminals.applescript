-- Tile every Terminal AND iTerm window into one non-overlapping grid that fills the screen.
--
-- Whichever of the two apps are running get tiled together in a single grid:
-- only Terminal -> Terminal windows; only iTerm -> iTerm windows; both -> all of them.
--
-- Terminal's scripting lists one "window" object per TAB, so a window with N
-- tabs shows up N times and only one of them actually controls the frame. To
-- count REAL windows we probe: give each window object a unique position, read
-- it back, and keep only the ones that "stuck". iTerm has no such ghost tabs,
-- so for iTerm we take every window as-is.
--
-- Needs the one-time "control Terminal"/"control iTerm" automation permission.
use framework "Foundation"
use framework "AppKit"
use scripting additions

-- 1) Main display geometry (Cocoa coords: bottom-left origin)
set theScreen to current application's NSScreen's mainScreen()
set {{fx, fy}, {fw, fh}} to theScreen's frame()           -- full display
set {{vx, vy}, {vw, vh}} to theScreen's visibleFrame()    -- minus menu bar + Dock

-- Convert the visible area to the terminal's bounds coords (top-left origin)
set uLeft to vx as integer
set uTop to (fh - (vy + vh)) as integer
set uW to vw as integer
set uH to vh as integer

-- 2) See which terminals are running (don't launch one that isn't)
-- "running" doesn't launch the app. System Events' "exists process X" is not an
-- option here: when X is NOT running it blocks ~12s on a name-resolution timeout,
-- and checking for a closed Terminal is the normal case.
set hasTerm to running of application "Terminal"
set hasITerm to running of application "iTerm"

-- 3) Collect the real, controllable windows from each running app as {appName, winID}
set winRefs to {}

if hasTerm then
	tell application "Terminal"
		activate
		repeat with w in windows
			try
				set miniaturized of w to false
			end try
		end repeat
	end tell
	repeat with theID in my realTerminalWindows(uLeft, uTop)
		set end of winRefs to {appName:"Terminal", winID:(contents of theID)}
	end repeat
end if

if hasITerm then
	tell application "iTerm"
		activate
		repeat with w in windows
			try
				set miniaturized of w to false
			end try
		end repeat
		set iIDs to id of every window
	end tell
	repeat with theID in iIDs
		set end of winRefs to {appName:"iTerm", winID:(contents of theID)}
	end repeat
end if

set n to count winRefs
if n is 0 then return

-- 4) At most 2 rows, so every window keeps at least half the screen height
set rows to 2
if n < 2 then set rows to n
set cols to (round (n / rows) rounding up) as integer
set cellH to uH / rows

-- 5) Place row by row; the last row stretches to fill the width
repeat with r from 0 to rows - 1
	set startIdx to r * cols
	set inThisRow to cols
	if (startIdx + cols) > n then set inThisRow to n - startIdx
	set cellW to uW / inThisRow
	set y1 to uTop + r * cellH
	set y2 to y1 + cellH
	repeat with c from 0 to inThisRow - 1
		set wRef to item (startIdx + c + 1) of winRefs
		set x1 to uLeft + c * cellW
		set x2 to x1 + cellW
		set theBounds to {x1 as integer, y1 as integer, x2 as integer, y2 as integer}
		try
			tell application (appName of wRef) to set bounds of window id (winID of wRef) to theBounds
		end try
	end repeat
end repeat

-- Terminal only: find the real windows, skipping ghost-tab duplicates.
on realTerminalWindows(uLeft, uTop)
	tell application "Terminal"
		set ids to id of every window
		set m to count ids
		if m is 0 then return {}
		repeat with k from 1 to m
			try
				set px to uLeft + 2 * (k - 1)
				set bounds of window id (item k of ids) to {px, uTop, px + 300, uTop + 250}
			end try
		end repeat
		set winIDs to {}
		repeat with k from 1 to m
			set theID to item k of ids
			try
				set b to bounds of window id theID
				if (item 1 of b) is (uLeft + 2 * (k - 1)) then set end of winIDs to theID
			end try
		end repeat
		return winIDs
	end tell
end realTerminalWindows
