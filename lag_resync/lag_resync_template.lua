
-- Author: RetroEdit

-- FIXME: Loading data as code is poor practice
-- In future, I'd like a proper save/load interface.
package.loaded.RENAME_TO_GAME_NAME = nil
local LAG_FILENAME = "RENAME_TO_GAME_NAME.lua"
local lag_frames = require "RENAME_TO_GAME_NAME"
local lag_offset = 0
local curr_lag_index = 1

-- lag_offset and curr_lag_index may be modified
-- Sometimes it's useful when the automatic resync partially works,
-- but needs to be manually adjusted and restarted.
-- lag_offset =
-- curr_lag_index =

-- This is an adjustment for VBA movies lacking the BIOS intro.
-- However, it only works sometimes.
-- GBA BIOS
-- GBA_BIOS_OFFSET = 272
-- lag_offset = GBA_BIOS_OFFSET
-- tastudio.submitinsertframes(1, GBA_BIOS_OFFSET)

-- Excluding the apply actually made some VBA movies sync much better for some reason.
-- tastudio.applyinputchanges()

-- TODO: should be bound-checking every call like this.
-- My current hack is just to add an absurdly big entry at the end.
local next_lag_frame = lag_frames[curr_lag_index]
local next_lag_frame2 = lag_frames[curr_lag_index+1]
console.log(string.format("Resyncing from '%s'", LAG_FILENAME))
-- FIXME: This shouldn't assume it has at least two lag frames, but it's a pretty reasonable assumption mostly.
console.log(string.format("First two lag frames: %d (%d), %d (%d)",
	next_lag_frame + lag_offset,
	next_lag_frame,
	next_lag_frame2 + lag_offset,
	next_lag_frame2
))

-- TODO: These two frames could be derived from the previous
local curr_frames, latest_frames = nil, 0

latest_frames = lag_offset

-- This might make more sense when you're resuming...
-- TODO: Really, we should have a proper resume interface
-- latest_frames = lag_offset + emu.framecount()
latest_frames = emu.framecount()

-- console.log(latest_frames)

event.onexit(function()
	console.log(string.format("lag offset, index (next lag): %d, %d (%d (%d))",
		lag_offset, curr_lag_index, next_lag_frame + lag_offset, next_lag_frame))
	movie.setrerecordcounting(true)
end)

local function group_lag(lag_frames)
	local lag_runs = {}
	-- frame cannot be -1, so this provides a numeric basis.
	local prev_frame = -2
	local lag_run_start = nil
	local lag_length = nil
	for i, frame in ipairs(lag_frames) do
		if frame ~= (prev_frame + 1) then
			if lag_run_start ~= nil then
				lag_length = prev_frame - lag_run_start + 1
				table.insert(lag_runs, {lag_run_start, lag_length})
			end
			lag_run_start = frame
		end
		prev_frame = frame
	end
	if lag_run_start ~= nil then
		lag_length = prev_frame - lag_run_start + 1
		table.insert(lag_runs, {lag_run_start, lag_length})
	end
	return lag_runs
end

-- FIXME: As currently implemented,
-- this is probably negatively impacting my script's efficiency
local lag_runs = group_lag(lag_frames)
local lag_runs_index = 1
local next_lag_start = lag_runs[lag_runs_index][1]
local next_lag_length = lag_runs[lag_runs_index][2]
while next_lag_start < next_lag_frame do
	lag_runs_index = lag_runs_index + 1
	next_lag_start = lag_runs[lag_runs_index][1]
	next_lag_length = lag_runs[lag_runs_index][2]
end

-- Rough heuristic using continous lag runs to guess when loading
-- (as opposed to in-game lag)
local LAG_LOAD_THRESHOLD = 10
local queue_next_lag = false

movie.setrerecordcounting(false)
while true do
	curr_frames = emu.framecount()
	if curr_frames > latest_frames then
		if curr_frames > (latest_frames + 1) then
			console.log(string.format("ERROR: curr_frames > (latest_frames + 1) (%d, %d); exiting script", curr_frames, latest_frames))
			break
		end
		latest_frames = curr_frames
	end

	if curr_frames == latest_frames then
		-- console.log(string.format("curr %6d, latest %d", curr_frames, latest_frames))
		if emu.islagged() then
			if curr_frames ~= (next_lag_frame + lag_offset) then
				-- One extra lag frame
				lag_offset = lag_offset + 1
				console.log(string.format("%06d: +", curr_frames-1))
				tastudio.submitinsertframes(curr_frames-1, 1)
				tastudio.applyinputchanges()

				latest_frames = curr_frames + 1

			else
				-- One matching lag frame
				queue_next_lag = true
			end
		elseif curr_frames == (next_lag_frame + lag_offset) then
			-- Rough heuristic for an extra input poll
			-- A better heuristic: distinguish game loads from lag
			-- This would make it easier to account for cases where there are fewer input polls.
			-- This would also allow more convenient fixes for missing input polls
			-- TODO: allow fewer input polls to be detected and adjusted for
			if (next_lag_frame == next_lag_start) and
			next_lag_length >= LAG_LOAD_THRESHOLD then
				-- One extra input poll
				lag_offset = lag_offset + 1
				console.log(string.format("%06d: ~+ (input poll)", curr_frames-1))
				console.log("[PAUSING]")
				client.pause()
			else
				-- One fewer lag frame
				queue_next_lag = true

				lag_offset = lag_offset - 1
				console.log(string.format("%06d: -", curr_frames-1))
				tastudio.submitdeleteframes(curr_frames-1, 1)
				tastudio.applyinputchanges()
			end
		end

		if queue_next_lag then
			curr_lag_index = curr_lag_index + 1
			next_lag_frame = lag_frames[curr_lag_index]
			if next_lag_start < next_lag_frame then
				lag_runs_index = lag_runs_index + 1
				next_lag_start = lag_runs[lag_runs_index][1]
				next_lag_length = lag_runs[lag_runs_index][2]
			end

			queue_next_lag = false
		end
	end

	if curr_frames == movie.length() - 1 then
		client.pause()
		break
	end

	movie.setrerecordcounting(true)
	emu.frameadvance()
	movie.setrerecordcounting(false)
end
movie.setrerecordcounting(true)
