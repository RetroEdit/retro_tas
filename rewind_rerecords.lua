
-- Tracks rerecords accumulated during rewind
-- Author(s): RetroEdit
-- Version: 0.2.0 (2023-12-31)
--
-- As of version 2.9.1, BizHawk doesn't track rerecords from rewind:
-- https://github.com/TASEmulators/BizHawk/issues/3707
-- This script mostly works with TAStudio, but it has a few edge cases
local WRITE_LOGS = false

-- FIXME: copied from read_lag.lua
-- Probably should be encapsulated in its own file-handling library.
if WRITE_LOGS then
	local REWIND_FILENAME = 'rewind_RENAME_ME.txt'

	f = io.open(REWIND_FILENAME, 'r')
	if f ~= nil then
		f:close()
		console.log(string.format("ERROR (exiting): '%s' already exists: rename or delete it to avoid losing data.", REWIND_FILENAME))
		return nil
	end

	console.log(string.format("Opening '%s' to write rewind frames.", REWIND_FILENAME))
	f = io.open(REWIND_FILENAME, 'w')
	local rom_name = gameinfo.getromname()
	f:write(string.format("\n-- Game: %s", rom_name))
	local rom_hash = gameinfo.getromhash()
	f:write(string.format("\n-- Hash: %s", rom_hash))
	local movie_file_name = movie.filename():match("[^/\\]+$")
	f:write(string.format("\n-- Movie: %s", movie_file_name))
	local emu_name = "BizHawk"
	local emu_version = client.getversion()
	f:write(string.format("\n-- %s %s", emu_name, emu_version))
	f:write("\n")
	f:close()
end

local frames, prev_frames = nil, nil
-- This will help with some kind of weird overcounting issue
-- Where it plays one frame in play mode, then a frame in record mode when rewinding.
local prev_frames2 = nil
local recent_rewind = false
local load_state_frame = nil

local rewind_origin = nil

event.onloadstate(function(state_name)
	load_state_frame = emu.framecount()
end, "mark_load_state")

while true do
	frames = emu.framecount()
	-- console.log(emu.framecount() .. movie.mode())
	if (movie.mode() == "RECORD" or (tastudio.engaged() and movie.mode() == "PLAY")) and prev_frames ~= nil and prev_frames2 ~= nil then
		if frames < prev_frames then
			if load_state_frame ~= frames then

				if not recent_rewind then
					rewind_origin = prev_frames
				end

				recent_rewind = true
			end
		-- elseif frames == prev_frames + 1 and recent_rewind then
		-- This double frame check is annoying, but TAStudio makes it necessary
		-- But this is still insufficient...
		elseif frames == prev_frames + 1 and prev_frames == prev_frames2 + 1 and recent_rewind then
			if movie.mode() == "RECORD" then
				movie.setrerecordcount(movie.getrerecordcount() + 1)

				if WRITE_LOGS then
					f = io.open(REWIND_FILENAME, 'a')
					f:write(rewind_origin .. ', ' .. prev_frames .. '\n')
					f:close()
				end

				-- This isn't perfect because it won't reset if rerecord checkbox gets manually unchecked
				-- But that edge case will only cause at most a minor deviation with the way I use it.
				recent_rewind = false
			-- console.log("rerecord++")
			end

			-- console.log("reset: recent_rewind")
			-- recent_rewind = false
		end
	end
	prev_frames2 = prev_frames
	prev_frames = frames
	emu.frameadvance()
end
