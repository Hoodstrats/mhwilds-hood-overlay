local json = json
local utils = require("hood_stuff.utils")
local hook = require("hood_stuff.hooker")
local cfg = json.load_file("hood-timers.json")
local items_db = require("hood_stuff.items")

-- refactor this
local config = {}

local defaults = {
	loc = { x = 0, y = 0 },
	effect_loc = { x = 80, y = 0 },
	expired_color = 0xFFFF0000,
	active_color = 0xFF00FF00,
	overlay = true,
	auto_start = true,
	remove_expired = false,
	manual_buff_tracking = false,
	show_icons = true,
	show_status_icons = false,
	show_effect = false,
	space_between_buffs = 30,
	items_per_column = 16, -- 1 column
	space_between_columns = 500,
	font_size = 25,
	bold_font = false,
	italic_font = false,
	font_name = "Arial",
	background = false,
	-- background_locked = false,
	background_color = 0xFF000000,
	background_size_x = 355,
	background_size_y = 500,
	fps_active = false,
	max_update_rate = 5,
	bg_loc = { x = 0, y = 0 },
	game_settings = {
		resolution = { x = 1920, y = 1080 },
	},
}

function config.Reset()
	cfg = defaults
	json.dump_file("hood-timers.json", cfg)
end

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
			megaarmorskin = true,
			food = true,
		}
		-- NOTE: make sure our new settings our set just incase
		utils.GhettoLoopThis(cfg.tracker_settings, function(key, value)
			if cfg.tracker_settings[key] == nil then
				cfg.tracker_settings[key] = value
			end
		end, false)
		-- init our default config order if manual is checked
		-- made it different from the original alphabetical order to tell
		if not cfg.buff_order then
			cfg.buff_order = {
				hotdrink = 1,
				cooldrink = 2,
				immunizer = 3,
				dashjuice = 4,
				mightseed = 5,
				mightpill = 6,
				demonpowder = 7,
				demondrug = 8,
				megademondrug = 9,
				adamantseed = 10,
				adamantpill = 11,
				hardshellpowder = 12,
				armorskin = 13,
				megaarmorskin = 14,
				food = 15,
			}
		end
	end
	config.cfg = cfg
	-- TODO: use this eventually for the preset manager
	-- config.get_game_res()

	-- NOTE: the new manual buff tracking
	if config.cfg.manual_buff_tracking then
		config.apply_buff_order()
	end
end

function config.apply_buff_order()
	if not config.cfg.buff_order then
		return
	end

	-- Create a sorted keys array that we'll use for traversal
	local sorted_keys = {}
	for k, _ in pairs(items_db.item_timers_en) do
		table.insert(sorted_keys, k)
	end

	-- Sort the keys by their position in buff_order
	table.sort(sorted_keys, function(a, b)
		local pos_a = config.cfg.buff_order[a] or 999
		local pos_b = config.cfg.buff_order[b] or 999
		return pos_a < pos_b
	end)

	-- Store the sorted keys for use in traversal
	items_db.buff_order_keys = sorted_keys
end

-- Add this helper function to iterate items in the custom order
function config.loop_the_buffs(func)
	-- check if we're even using manual or if the buff order is empty
	if not items_db.buff_order_keys or not config.cfg.manual_buff_tracking then
		-- If no custom order is set, use standard iteration
		utils.GhettoLoopThis(items_db.item_timers_en, function(k, item_name)
			func(k, item_name)
		end, true)
	else
		-- Use the pre-sorted keys to iterate in the desired order
		for _, k in ipairs(items_db.buff_order_keys) do
			func(k, items_db.item_timers_en[k])
		end
	end
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
