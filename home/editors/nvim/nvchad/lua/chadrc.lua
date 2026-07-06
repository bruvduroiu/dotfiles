-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

-- Read theme from file (set by theme-switch script)
local function get_theme()
	local f = io.open(os.getenv("HOME") .. "/.config/theme/nvim-theme", "r")
	if f then
		local name = f:read("*l")
		f:close()
		if name and name ~= "" then return name end
	end
	return "catppuccin"
end

local function get_background()
	local f = io.open(os.getenv("HOME") .. "/.config/theme/nvim-bg", "r")
	if f then
		local bg = f:read("*l")
		f:close()
		if bg and bg ~= "" then
			vim.o.background = bg
		end
	end
end

get_background()

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = get_theme(),
	transparency = true,

	hl_override = {
		Comment = { italic = true },
		["@comment"] = { italic = true },
	},
}

return M
