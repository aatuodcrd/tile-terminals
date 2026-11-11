-- Tile every Terminal AND iTerm window across your screens, at a size people can read.
--
-- Whichever of the two apps are running get tiled together (neither is launched).
--
-- Readable size: every pane gets at least minColW x minRowH pixels, so each
-- screen holds a fixed number of panes (1920x1003 -> 4 cols x 2 rows = 8).
-- Windows are placed most-recently-used first (front of the window stack),
-- filling the main screen, then the other screens. Windows that don't fit are
-- minimized to the Dock; minimized windows come back only if there is room.
-- Only windows on the desktop (Space) you are looking at are touched; other
-- desktops are left alone, so you can tile each desktop separately. (macOS gives
-- scripts no way to move windows to another desktop/Space.)
--
-- Split panes get more room: a window's weight is the number of panes in its
-- visible tab (iTerm), so a 7-pane window gets 7x the area of a 1-pane one.
-- Tabs add nothing, since only one tab shows at a time. Terminal = weight 1.
-- A window whose panes are stacked top/bottom gets a full-height column instead
-- of a half-height cell, so its pane rows don't get squashed.
--
-- Terminal's scripting lists one "window" object per TAB, so a window with N
-- tabs shows up N times and only one of them actually controls the frame. To
-- count REAL windows we probe: give each window object a unique position, read
-- it back, and keep only the ones that "stuck". iTerm has no such ghost tabs.
--
-- Needs the one-time "control Terminal"/"control iTerm" automation permission.
use framework "Foundation"
use framework "AppKit"
use scripting additions

-- Smallest readable pane: ~60 columns x ~25 lines of text plus pane chrome.
-- Calibration knobs: lower them to fit more per screen, raise for bigger text.
property minColW : 480
property minRowH : 450

-- 1) Every screen's usable area (minus menu bar + Dock), in the terminals'
-- top-left-origin coords. NSScreen's first screen is the one with the menu bar.
set screenList to current application's NSScreen's screens() as list
set mainH to item 2 of item 2 of ((item 1 of screenList)'s frame() as list)
set screens to {}
repeat with sc in screenList
	set {{vx, vy}, {vw, vh}} to sc's visibleFrame() as list
	set c to (vw div minColW) as integer
	set r to (vh div minRowH) as integer
	if c < 1 then set c to 1
	if r < 1 then set r to 1
	set end of screens to {x:vx as integer, y:(mainH - (vy + vh)) as integer, w:vw as integer, h:vh as integer, maxRows:r, cols:c, cap:c * r, used:0, wins:{}}
end repeat

-- 2) See which terminals are running (don't launch one that isn't)
-- "running" doesn't launch the app. System Events' "exists process X" is not an
-- option here: when X is NOT running it blocks ~12s on a name-resolution timeout,
-- and checking for a closed Terminal is the normal case.
set hasTerm to running of application "Terminal"
set hasITerm to running of application "iTerm"

-- 3) Collect windows as {appName, winID, weight, tall, mini}, front-most first;
-- minimized ones go last so open windows keep their place
set winRefs to {}
set miniRefs to {}
set mx to x of item 1 of screens
set my_ to y of item 1 of screens

if hasTerm then
	tell application "Terminal"
		repeat with w in windows
			try
				set miniaturized of w to false
			end try
		end repeat
	end tell
	repeat with theID in my realTerminalWindows(mx, my_)
		set end of winRefs to {appName:"Terminal", winID:(contents of theID), weight:1, tall:false, mini:false}
	end repeat
end if

if hasITerm then
	-- Accessibility only sees windows on the current desktop (minimized ones
	-- included). Without that permission, fall back to every window.
	set hereNames to missing value
	try
		tell application "System Events" to set hereNames to name of every window of process "iTerm2"
	end try
	tell application "iTerm"
		repeat with w in windows
			if hereNames is not missing value and (name of w) is not in hereNames then
				-- on another desktop: leave it where it is
			else
			set wt to 1
			set isTall to false
			set isMini to false
			try
				set isMini to miniaturized of w
			end try
			try
				set t to current tab of w
				set wt to count sessions of t
				if wt > 1 then
					set {bx1, by1, bx2, by2} to bounds of w
					set isTall to my panesStacked(columns of every session of t, rows of every session of t, bx2 - bx1, by2 - by1)
				end if
			end try
			if wt < 1 then set wt to 1
			set wRef to {appName:"iTerm", winID:(id of w), weight:wt, tall:isTall, mini:isMini}
			if isMini then
				set end of miniRefs to wRef
			else
				set end of winRefs to wRef
			end if
			end if
		end repeat
	end tell
end if
set winRefs to winRefs & miniRefs
if (count winRefs) is 0 then return

-- 4) Hand out screens: each window goes to the first screen with room for its
-- panes. A window bigger than a whole screen still gets an empty screen to itself.
set overflow to {}
repeat with wRef in winRefs
	set wRef to contents of wRef
	set placed to false
	repeat with i from 1 to count screens
		set sc to item i of screens
		set cost to my cellCost(wRef, maxRows of sc)
		if ((used of sc) + cost <= (cap of sc)) or ((used of sc) = 0) then
			set used of sc to (used of sc) + cost
			set end of wins of sc to wRef
			set item i of screens to sc
			set placed to true
			exit repeat
		end if
	end repeat
	if not placed then set end of overflow to wRef
end repeat

-- 5) Lay out each screen; minimize what didn't fit
repeat with sc in screens
	if (count wins of sc) > 0 then
		repeat with wRef in wins of sc
			if mini of wRef then my setMini(wRef, false)
		end repeat
		my layoutScreen(wins of sc, x of sc, y of sc, w of sc, h of sc, maxRows of sc, cols of sc)
	end if
end repeat
repeat with wRef in overflow
	if not (mini of wRef) then my setMini(wRef, true)
end repeat

-- Readable cells a window uses on a screen. A stacked-pane window spans the full
-- height, so it uses whole columns: 7 panes over 2 rows = 4 columns = 8 cells.
on cellCost(wRef, maxRows)
	if (tall of wRef) and maxRows <= 2 then return (((weight of wRef) + maxRows - 1) div maxRows) * maxRows
	return weight of wRef
end cellCost

-- One screen: stacked-pane windows get full-height columns on the left, whole
-- readable cells wide (only with 1-2 rows; on a tall portrait screen that column
-- would be too narrow and a full-width row is tall enough). The rest fill up to
-- maxRows equal rows; in a row each window's width is proportional to its weight.
on layoutScreen(winList, uLeft, uTop, uW, uH, maxRows, cols)
	set tallList to {}
	set restList to {}
	repeat with wRef in winList
		if (tall of wRef) and maxRows <= 2 then
			set end of tallList to contents of wRef
		else
			set end of restList to contents of wRef
		end if
	end repeat
	set x1 to uLeft
	repeat with wRef in tallList
		set x2 to x1 + uW * (cellCost(wRef, maxRows) div maxRows) / cols
		if x2 > uLeft + uW or (count winList) = 1 then set x2 to uLeft + uW
		place(wRef, x1, uTop, x2, uTop + uH)
		set x1 to x2
	end repeat
	if (count restList) is 0 then return
	set gLeft to x1
	set gW to uLeft + uW - x1
	set rowList to splitRows(restList, maxRows)
	set rows to count rowList
	set cellH to uH / rows
	repeat with r from 1 to rows
		set theRow to item r of rowList
		set rowW to 0
		repeat with wRef in theRow
			set rowW to rowW + (weight of wRef)
		end repeat
		set y1 to uTop + (r - 1) * cellH
		set x1 to gLeft
		repeat with wRef in theRow
			set x2 to x1 + gW * (weight of wRef) / rowW
			place(wRef, x1, y1, x2, y1 + cellH)
			set x1 to x2
		end repeat
	end repeat
end layoutScreen

on place(wRef, x1, y1, x2, y2)
	set theBounds to {x1 as integer, y1 as integer, x2 as integer, y2 as integer}
	try
		tell application (appName of wRef) to set bounds of window id (winID of wRef) to theBounds
	end try
end place

-- App named literally: "miniaturized" only resolves with the app's dictionary.
on setMini(wRef, flag)
	try
		if (appName of wRef) is "iTerm" then
			tell application "iTerm" to set miniaturized of window id (winID of wRef) to flag
		else
			tell application "Terminal" to set miniaturized of window id (winID of wRef) to flag
		end if
	end try
end setMini

-- Split windows into up to maxRows rows of roughly equal total weight:
-- heaviest first, each into the currently lightest row.
on splitRows(winRefs, maxRows)
	set n to count winRefs
	set k to maxRows
	if n < k then set k to n
	set rowList to {}
	set rowWt to {}
	repeat k times
		set end of rowList to {}
		set end of rowWt to 0
	end repeat
	set todo to winRefs
	repeat n times
		set best to 1
		repeat with i from 2 to count todo
			if (weight of item i of todo) > (weight of item best of todo) then set best to i
		end repeat
		set wRef to item best of todo
		if best = 1 then
			set todo to rest of todo
		else if best = (count todo) then
			set todo to items 1 thru (best - 1) of todo
		else
			set todo to (items 1 thru (best - 1) of todo) & (items (best + 1) thru -1 of todo)
		end if
		set lightest to 1
		repeat with i from 2 to k
			if (item i of rowWt) < (item lightest of rowWt) then set lightest to i
		end repeat
		set end of item lightest of rowList to wRef
		set item lightest of rowWt to (item lightest of rowWt) + (weight of wRef)
	end repeat
	return rowList
end splitRows

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
on panesStacked(colList, rowList, pxW, pxH)
	set cells to 0
	set minRows to item 1 of rowList
	repeat with k from 1 to count colList
		set cells to cells + (item k of colList) * (item k of rowList)
		if (item k of rowList) < minRows then set minRows to item k of rowList
	end repeat
	if minRows < 1 or pxW < 1 then return false
	return (pxH * cells / 2) >= (3.24 * pxW * minRows * minRows)
end panesStacked
