--/////////////////////////////////////--
-- Mod = "HoodTimers: Buff Overlay"
-- Author = "hoodstrats"
-- Updated = "04/1/2025"
-- Version = "v1.1.1"
--/////////////////////////////////////--

local re = re
local imgui = imgui
local json = json
local hook = require("hood_stuff.hooker")
local hunter = require("hood_stuff.hunter")
local config = require("hood_stuff.config")
local settings = require("hood_stuff.settings")
-- local debug = require("hood_stuff.debug")
local draw2d = require("hood_stuff.drawd2d")

config.InitConfig()

-- use loaded to check if hunter is already init so we can just update values instead
local loaded = false

local function init_mod()
	if not hunter.hunter then
		hunter.init_hunter()
		return
	end
	loaded = true
	if config.cfg.auto_start then
		if not config.cfg.overlay then
			config.cfg.overlay = true
		end
		draw2d.Register(hunter)
	end
end

-- Add this near the other hooks at the top of your file
local function update_hook(args)
	if loaded then
		hunter.get_items()
		hunter.get_food_buffs()
		return
	end
	-- init hunter if not already loaded
	init_mod()
end

hook.HookThis("app.cHunterEffect", "update(app.HunterCharacter)", update_hook, function(retval) end)

re.on_draw_ui(function()
	if imgui.collapsing_header("--- Hood Overlay Settings ---") then
		if not hunter.hunter then
			return
		end
		settings.DrawSettings()
		-- debug.GetDebugInfo()
	end
end)

re.on_config_save(function()
	if config.cfg.overlay and not config.cfg.auto_start then
		config.cfg.overlay = false
	end
	json.dump_file("hood-timers.json", config.cfg)
end)
