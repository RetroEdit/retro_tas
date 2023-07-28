
-- retro_tas: General TAS tools
-- Author(s): RetroEdit
-- Version: 0.2.0 (2023-07-20)
-- Tested on BizHawk version 2.8.0 and 2.9.1

local PIX_FONT_X, PIX_FONT_Y = 4, 7
local SCREEN_PIX_WIDTH = math.floor(client.bufferwidth() / PIX_FONT_X)
local SCREEN_PIX_HEIGHT = math.floor(client.bufferheight() / PIX_FONT_Y)
local function pix(x, y, s, fg, bg)
	gui.pixelText(x * PIX_FONT_X, y * PIX_FONT_Y, s, fg, bg, "gens")
end

local function pix_row(x, y, fg, bg)
	return function (s)
		pix(x, y, s, fg, bg)
		x = x + string.len(s)
	end
end

local function ptr_chain(addr, offsets, domain)
	if domain == nil then
		domain = "System Bus"
	end
	for i,o in ipairs(offsets) do
		addr = memory.read_u32_le(addr+o, domain)
		if addr >= 0x10000000 then
			return nil
		end
	end
	return addr
end

return {
	PIX_FONT_X = PIX_FONT_X,
	PIX_FONT_Y = PIX_FONT_Y,
	SCREEN_PIX_WIDTH = SCREEN_PIX_WIDTH,
	SCREEN_PIX_HEIGHT = SCREEN_PIX_HEIGHT,
	pix = pix,
	pix_row = pix_row,
	ptr_chain = ptr_chain
}
