
-- Adapted from read_lag_snes9x.lua

-- TODO: properly handle savestate loads -- probably a warning and stop tracking
-- there might be something better...

local frames
local lag_frames = {}

local FINAL_FRAME = 1000000000

local function unknown_value()
	return '?'
end

emu_name = "BizHawk"
if vba ~= nil then
	-- https://code.google.com/archive/p/vba-rerecording/wikis/LuaScriptingFunctions.wiki
	emu = vba
	emu.islagged = emu.lagged
	console = {log=print}
	client = {pause=emu.pause, getversion=unknown_value}
	movie.filename = movie.name

	gameinfo = {getromname=unknown_value, getromhash=unknown_value}
	emu_name = "VBA"
end

console.log("Started reading lag (read_lag.lua)")

-- TODO: Have a proper UI to confirm tracking start and choose the file name.
-- TODO: Warn if the file is overwritten
-- TODO: Track the script version
local LAG_FILENAME = 'lag_RENAME_ME.lua'
-- local LAG_FILENAME = 'lag_dkc1gba_3465M.lua'

f = io.open(LAG_FILENAME,"r")
if f ~= nil then
	f:close()
	console.log(string.format("ERROR (exiting): '%s' already exists: rename or delete it to avoid losing data.", LAG_FILENAME))
	return nil
end

console.log(string.format("Opening '%s' to write lag frames.", LAG_FILENAME))
f = io.open(LAG_FILENAME, 'w')
local rom_name = gameinfo.getromname()
f:write(string.format("\n-- Game: %s", rom_name))
local rom_hash = gameinfo.getromhash()
f:write(string.format("\n-- Hash: %s", rom_hash))
local movie_file_name = movie.filename():match("[^/\\]+$")
f:write(string.format("\n-- Movie: %s", movie_file_name))
-- TODO: Emulator name + version!
-- [x] Name is hard, but we can get version
local emu_version = client.getversion()
f:write(string.format("\n-- %s %s", emu_name, emu_version))
f:write("\nreturn {")
f:close()

local end_movie = false
while true do
	frames = emu.framecount()
	if frames > 0 and emu.islagged() then
		table.insert(lag_frames, frames)
	end

	if frames >= movie.length() - 1 then
		end_movie = true
	end

	if frames % 1000 == 0 or end_movie then
		if next(lag_frames) ~= nil then
			f = io.open(LAG_FILENAME, 'a')
			f:write(table.concat(lag_frames, ', '))
			f:write(', ')
			f:close()
			lag_frames = {}
		end
	end

	if end_movie then
		f = io.open(LAG_FILENAME, 'a')
		f:write(string.format("%d}\n", FINAL_FRAME))
		f:close()
		console.log(string.format("Movie paused at movie end (frame %d).", frames))
		console.log(string.format("Lag frames written to: '%s'.", LAG_FILENAME))
		client.pause()
		break
	end

	emu.frameadvance()
end
