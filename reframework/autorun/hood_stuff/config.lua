local utils = require("hood_stuff.utils")
local hook = require("hood_stuff.hooker")
local cfg = json.load_file("hood-timers.json")

-- refactor this
local config = {}

local defaults = {
	loc = { x = 0, y = 0 },
	expired_color = 0xFFFF0000,
	active_color = 0xFF00FF00,
	overlay = true,
	auto_start = true,
	remove_expired = false,
	space_between_buffs = 30,
	use_columns = false,
	items_per_column = 7,
	space_between_columns = 500,
	font_size = 25,
	bold_font = false,
	italic_font = false,
	font_name = "Arial",
	background = false,
	background_locked = false,
	background_color = 0xFF000000,
	background_size_x = 355,
	background_size_y = 500,
	fps_active = false,
	max_update_rate = 5,
	bg_loc = { x = 0, y = 0 },
	game_settings = {
		resolution = { x = 1920, y = 1080 },
	}
}

function config.InitConfig()
	if not cfg then
		cfg = defaults
	end
	-- Apply default values for any missing settings
	utils.GhettoLoopThis(defaults, function(key, value)
		if cfg[key] == nil then
			cfg[key] = value
		end
	end, false)

	if not cfg.tracker_settings then
		cfg.tracker_settings = {
			hotdrink = true,
			cooldrink = true,
			immunizer = true,
			dashjuice = true,
			mightseed = true,
			mightpill = true,
			demonpowder = true,
			demondrug = true,
			megademondrug = true,
			adamantseed = true,
			adamantpill = true,
			hardshellpowder = true,
			armorskin = true,
			megaarmorskin = true
		}
	end
	config.cfg = cfg
	-- TODO: use this eventually for the preset manager
	config.get_game_res()
end

function config.get_game_res()
	local scene_man = hook.GetSingleton("via.SceneManager", true)
	if not scene_man then
		defaults.resolution = { x = 1920, y = 1080 }
		print("scene manager not found")
		return
	end
	local screen_w, screen_h = hook.GetRes(scene_man)

	config.resolution = { screen_w, screen_h }
	-- print("found res " .. config.resolution[1] .. "x" .. config.resolution[2])
end

return config
