-- Tile all Terminal windows into a non-overlapping grid that fills the screen.
--
-- Terminal's scripting lists one "window" object per TAB, so a window with N
-- tabs shows up N times and only one of them actually controls the frame
-- (writes to the others are silently ignored). To count REAL windows we probe:
-- give each window object a unique position, read it back, and keep only the
-- ones that "stuck" (the true, controllable windows). Then we tile those.
--
-- Only needs the one-time "control Terminal" automation permission.
use framework "Foundation"
use framework "AppKit"
use scripting additions

-- 1) Main display geometry (Cocoa coords: bottom-left origin)
set theScreen to current application's NSScreen's mainScreen()
set {{fx, fy}, {fw, fh}} to theScreen's frame()           -- full display
set {{vx, vy}, {vw, vh}} to theScreen's visibleFrame()    -- minus menu bar + Dock

-- Convert the visible area to Terminal's bounds coords (top-left origin)
set uLeft to vx as integer
set uTop to (fh - (vy + vh)) as integer
set uW to vw as integer
set uH to vh as integer

tell application "Terminal"
	activate

	-- restore any minimized windows so they get tiled too
	repeat with w in windows
		try
			set miniaturized of w to false
		end try
	end repeat

	-- PASS A: find the real (controllable) windows, skipping ghost-tab duplicates
	set ids to id of every window
	set m to count ids
	if m is 0 then return
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
	set n to count winIDs
	if n is 0 then return

	-- 2) Near-square grid
	set cols to (round (n ^ 0.5) rounding up) as integer
	set rows to (round (n / cols) rounding up) as integer
	set cellH to uH / rows

	-- PASS B: place row by row; the last row stretches to fill the width
	repeat with r from 0 to rows - 1
		set startIdx to r * cols
		set inThisRow to cols
		if (startIdx + cols) > n then set inThisRow to n - startIdx
		set cellW to uW / inThisRow
		set y1 to uTop + r * cellH
		set y2 to y1 + cellH
		repeat with c from 0 to inThisRow - 1
			set theID to item (startIdx + c + 1) of winIDs
			set x1 to uLeft + c * cellW
			set x2 to x1 + cellW
			try
				set bounds of window id theID to {x1 as integer, y1 as integer, x2 as integer, y2 as integer}
			end try
		end repeat
	end repeat
end tell
