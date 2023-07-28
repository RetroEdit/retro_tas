
-- Tracks rerecords accumulated during rewind
-- Author(s): RetroEdit
-- Version: 0.1.1 (2023-07-18)
--
-- As of version 2.9.1, Bizhawk doesn't track rerecords from rewind:
-- https://github.com/TASEmulators/BizHawk/issues/3707
-- If future versions do, this script is rendered obsolete for those versions.
-- I didn't test this with TAStudio, so it may be double-counting in that context.

local frames, prev_frames = nil, nil
local recent_rewind = false
local load_state_frame = nil

event.onloadstate(function(state_name)
	load_state_frame = emu.framecount()
end, "mark_load_state")

while true do
	frames = emu.framecount()
	if movie.mode() == "RECORD" and prev_frames ~= nil then
		if frames < prev_frames then
			if load_state_frame ~= frames then
				recent_rewind = true
			end
		elseif frames == prev_frames + 1 and recent_rewind then
			movie.setrerecordcount(movie.getrerecordcount() + 1)
			recent_rewind = false
		end
	end
	prev_frames = frames
	emu.frameadvance()
end
