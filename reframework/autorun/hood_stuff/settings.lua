local imgui = imgui
local d2d = d2d
local json = json
local re = re
local config = require("hood_stuff.config")
local draw2d = require("hood_stuff.drawd2d")
local hunter = require("hood_stuff.hunter")
local items_db = require("hood_stuff.items")
local utils = require("hood_stuff.utils")
local hook = require("hood_stuff.hooker")

local settings_ui = {}
local overlay_settings_open = false

local function ui_fps_settings()
	local changed = false
	-- the ImGuiWindowFlags are represented by their number values instead of enum
	-- https://oprypin.github.io/crystal-imgui/ImGui/ImGuiWindowFlags.html
	if not config.cfg then
		config.cfg = {
			max_update_rate = d2d.detail.get_max_updaterate(),
		}
	end

	changed, config.cfg.max_update_rate = imgui.slider_int("FPS", config.cfg.max_update_rate, 1, 60)
	if imgui.button("Toggle overlay FPS tracker", { 200, 50 }) then
		config.cfg.fps_active = not config.cfg.fps_active
	end
	imgui.same_line()
	if imgui.button("Set FPS", { 200, 50 }) then
		d2d.detail.set_max_updaterate(config.cfg.max_update_rate)
	end
end

local function manual_buff_tracking()
	local changed = false
	changed, config.cfg.manual_buff_tracking =
		imgui.checkbox("Enable Manual Buff Order (Press apply atleast once)", config.cfg.manual_buff_tracking)

	if not config.cfg.manual_buff_tracking then
		return
	end

	-- TODO: makes sure this works on a fresh install by making config.cfg.buff_order have a default order
	-- ensure that we don't have to press apply order before seeing any changes (making buffs disappear)
	if config.cfg.manual_buff_tracking and config.cfg.buff_order ~= nil then
		config.apply_buff_order()
	end

	-- Create sorted display entries by name
	local buff_entries = {}
	for k, v in pairs(items_db.item_timers_en) do
		table.insert(buff_entries, { key = k, name = v })
	end

	-- Sort alphabetically by name
	table.sort(buff_entries, function(a, b)
		return a.name < b.name
	end)

	-- Initialize buff_order if needed with positions based on alphabetical order
	if not config.cfg.buff_order then
		config.cfg.buff_order = {}
		for i, entry in ipairs(buff_entries) do
			config.cfg.buff_order[entry.key] = i
		end
	end

	-- Create position options
	local buff_count = {}
	local total_buffs = 0
	for _ in pairs(items_db.item_timers_en) do
		total_buffs = total_buffs + 1
		table.insert(buff_count, tostring(total_buffs))
	end

	imgui.text("Set display order for each buff (1 = Top, etc)")
	imgui.text("Buffs are listed in alphabetical order below")
	imgui.separator()

	-- Display alphabetically sorted buffs with their position dropdowns
	for i, entry in ipairs(buff_entries) do
		local k = entry.key
		local v = entry.name

		-- Get current position from buff_order (not alphabetical position)
		local cur_pos = config.cfg.buff_order[k] or i
		local pos_index = cur_pos

		changed, pos_index = imgui.combo(v .. " " .. "(" .. tostring(pos_index) .. ")", pos_index, buff_count)

		if changed then
			local new_pos = pos_index
			local old_pos = config.cfg.buff_order[k]

			-- Find any buff that currently has the new position and swap positions
			for other_key, other_pos in pairs(config.cfg.buff_order) do
				if other_key ~= k and other_pos == new_pos then
					config.cfg.buff_order[other_key] = old_pos
					break
				end
			end

			-- Set the new position
			config.cfg.buff_order[k] = new_pos
		end

		-- Add spacing between items
		imgui.new_line()
	end

	-- Add button to apply the order
	if imgui.button("Apply order", { 200, 50 }) then
		config.apply_buff_order()
	end
end
local function buff_selector()
	local changed = false
	if config.cfg.tracker_settings ~= nil then
		changed, config.cfg.remove_expired = imgui.checkbox("Automatically remove expired", config.cfg.remove_expired)
		utils.GhettoLoopThis(config.cfg.tracker_settings, function(k, v)
			changed, config.cfg.tracker_settings[k] =
				imgui.checkbox(items_db.item_timers_en[k], config.cfg.tracker_settings[k])
		end, true)
	end
end

local function overlay_bg_settings()
	local changed = false
	changed, config.cfg.background = imgui.checkbox("Enable Background", config.cfg.background)

	-- imgui.same_line()
	-- changed, config.cfg.background_locked =
	-- 	imgui.checkbox("Lock Background Position \n experimental feature", config.cfg.background_locked)
	imgui.new_line()
	if not config.cfg.background then
		return
	end
	changed, config.cfg.background_color = imgui.color_picker_argb("Bg Color", config.cfg.background_color)
	if not config.cfg.background_locked then
		changed, config.cfg.background_size_x = imgui.slider_int("Width", config.cfg.background_size_x, 0, 6000)
	end
	changed, config.cfg.background_size_y = imgui.slider_int("Height", config.cfg.background_size_y, 0, 6000)
	if not config.cfg.background_locked then
		changed, config.cfg.bg_loc.x = imgui.slider_int("BACKGROUND X POS", config.cfg.bg_loc.x, 0, 6000)
		changed, config.cfg.bg_loc.y = imgui.slider_int("BACKGROUND Y POS", config.cfg.bg_loc.y, 0, 2160)
	else
		config.cfg.bg_loc.x = config.cfg.loc.x
		config.cfg.bg_loc.y = config.cfg.loc.y
	end
end

local function choose_font_dropdown(changed)
	-- some common fonts
	local fonts = { "Tahoma", "Arial", "Verdana", "Times New Roman", "Courier New", "Comic Sans MS" }
	local current_font = 0

	if not config.cfg.font_name then
		config.cfg.font_name = "Tahoma" -- Default font
	end

	current_font = 0
	utils.GhettoLoopThis(fonts, function(i, font)
		if font == config.cfg.font_name then
			current_font = i
			return true
		end
	end, false)
	changed, current_font = imgui.combo("Font", current_font, fonts)
	if changed then
		config.cfg.font_name = fonts[current_font]
	end
end

local function overlay_settings()
	local changed = false
	if imgui.button(">> MORE SETTINGS <<", { 200, 50 }) then
		overlay_settings_open = not overlay_settings_open
	end
	if overlay_settings_open then
		local window_open = imgui.begin_window("Edit Overlay Settings", true, 64)
		if window_open then
			if imgui.collapsing_header("Position and Spacing") then
				imgui.new_line()
				changed, config.cfg.loc.x = imgui.slider_int("Buffs X POS", config.cfg.loc.x, 0, 6000)
				changed, config.cfg.loc.y = imgui.slider_int("Buffs Y POS", config.cfg.loc.y, 0, 2160)
				changed, config.cfg.space_between_buffs =
					imgui.slider_int("Space Between Buffs", config.cfg.space_between_buffs, 10, 1000)
				imgui.new_line()

				if config.cfg.items_per_column <= 0 then
					config.cfg.items_per_column = 16 --make sure we're 1 column to start
				end
				changed, config.cfg.items_per_column =
					imgui.slider_int("Items per column", config.cfg.items_per_column, 1, 16)
				changed, config.cfg.space_between_columns =
					imgui.slider_int("Space between columns", config.cfg.space_between_columns, 0, 1000)
				imgui.new_line()
			end

			if imgui.collapsing_header("Font Settings") then
				imgui.text("Font settings need to be set using the button below")
				imgui.text("You can type in numbers by control clicking the slider")
				changed, config.cfg.font_size = imgui.slider_int("Font Size", config.cfg.font_size, 12, 100)
				imgui.same_line()
				changed, config.cfg.bold_font = imgui.checkbox("Bold Font", config.cfg.bold_font)
				imgui.same_line()
				changed, config.cfg.italic_font = imgui.checkbox("Italic Font", config.cfg.italic_font)

				-- font dropdown
				choose_font_dropdown(changed)
				if imgui.button("Set Font Settings") then
					draw2d.SetFontSettings()
				end
			end
			if imgui.collapsing_header("Edit Font Color") then
				changed, config.cfg.expired_color = imgui.color_picker_argb("Expired Color", config.cfg.expired_color)
				changed, config.cfg.active_color = imgui.color_picker_argb("Active Color", config.cfg.active_color)
			end

			if imgui.collapsing_header("Buff Tracker (which buffs to track)") then
				buff_selector()
			end

			if imgui.collapsing_header("Manual Buff Order (you choose the order)") then
				manual_buff_tracking()
			end

			if imgui.collapsing_header("Overlay Background Settings") then
				overlay_bg_settings()
			end

			if imgui.collapsing_header("UI RENDER FPS") then
				ui_fps_settings()
			end
		else
			overlay_settings_open = false
		end
		imgui.end_window()
	end
end

function settings_ui.DrawSettings()
	local changed = false
	if imgui.button("Show overlay") then
		-- NOTE: prevent the overlay from being drawn if the draw2d is already drawing
		-- but also stops you from showing the overlay again so you have to press RESET SCRIPT
		if draw2d.is_drawing then
			return
		end
		config.cfg.overlay = true
		draw2d.Register(hunter)
	end
	imgui.same_line()

	if imgui.button("Hide overlay") then
		imgui.open_popup("Reset Scripts", 0)
		config.cfg.overlay = false
	end

	if imgui.begin_popup("Reset Scripts") then
		imgui.text("\n\nYou have to reset the script to show the overlay again.")
		imgui.text("ScriptRunner > Reset scripts \n\n")
		imgui.text("If Auto Start is off then you have press show overlay after reset.")

		if imgui.button("OK", { 400, 50 }) then
			imgui.close_current_popup()
		end

		imgui.end_popup()
	end

	imgui.same_line()

	-- NOTE: gets checked on INITHUNTER method in hunter lua
	changed, config.cfg.auto_start = imgui.checkbox("Auto start", config.cfg.auto_start)
	imgui.new_line()
	imgui.text("Enabling icons moves the buffs over to the left a bit remember to adjust the buff positions")
	changed, config.cfg.show_icons = imgui.checkbox("Show Item Icons", config.cfg.show_icons)
	if config.cfg.show_icons then
		config.cfg.show_status_icons = false
	end
	imgui.same_line()
	changed, config.cfg.show_status_icons = imgui.checkbox("Show Status Icons", config.cfg.show_status_icons)
	if config.cfg.show_status_icons then
		config.cfg.show_icons = false
	end

	imgui.same_line()
	changed, config.cfg.show_effect = imgui.checkbox("Show Effect", config.cfg.show_effect)
	imgui.same_line()
	changed, config.cfg.remove_expired = imgui.checkbox("Automatically remove expired", config.cfg.remove_expired)
	imgui.new_line()

	if config.cfg.show_effect then
		changed, config.cfg.effect_loc.x =
			imgui.slider_int("Effect X POS (What the buff does)", config.cfg.effect_loc.x, 0, 6000)
		-- changed, config.cfg.effect_loc.y = imgui.slider_int("Effect Y POS", config.cfg.effect_loc.y, 0, 2160)
	end
	-- check if we're using any of these options then give icon size slider
	if config.cfg.show_status_icons or config.cfg.show_icons then
		if config.cfg.icon_size == nil then
			config.cfg.icon_size = 32
		end
		if config.cfg.icon_size == 32 then
			config.cfg.icon_loc.x = -40
			config.cfg.icon_loc.y = -2
		end
		imgui.text("Default size is 32")
		changed, config.cfg.icon_size = imgui.slider_int("Icon Size", config.cfg.icon_size, 10, 120)
		changed, config.cfg.icon_loc.x = imgui.slider_int("Icon X POS", config.cfg.icon_loc.x, 0, 6000)
		changed, config.cfg.icon_loc.y = imgui.slider_int("Icon Y POS", config.cfg.icon_loc.y, 0, 2160)
	end

	imgui.text("FOR MORE CONTROL, PRESS THIS BUTTON, CHECK EACH DROP DOWN INSIDE NEW WINDOW")
	overlay_settings()
	imgui.new_line()

	if not imgui.collapsing_header("Preset Manager (will update eventually)") then
		return
	end
	imgui.text("This assumes your in game resolution is 1920x1080")
	if imgui.button("Load Bottom Config") then
		local bottom_pres = json.load_file("hood-timers-preset-bottom.json")
		if bottom_pres then
			config.cfg = bottom_pres
			draw2d.SetFontSettings()
		else
			re.msg("Bottom preset config file not found, using current settings")
		end
	end
	imgui.same_line()
	if imgui.button("Load Top Config") then
		local top_pres = json.load_file("hood-timers-preset-top.json")
		if top_pres then
			config.cfg = top_pres
			draw2d.SetFontSettings()
		else
			re.msg("Right preset config file not found, using current settings")
		end
	end
	imgui.same_line()
	if imgui.button("Reset") then
		local default = json.load_file("hood-timers-preset-default.json")
		if default then
			config.cfg = default
			draw2d.SetFontSettings()
		else
			re.msg("Right preset config file not found, using current settings")
		end
	end
	imgui.new_line()
end

return settings_ui
