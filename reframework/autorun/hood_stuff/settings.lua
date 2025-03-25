local config = require("hood_stuff.config")
local draw2d = require("hood_stuff.drawd2d")
local hunter = require("hood_stuff.hunter")
local items_db = require("hood_stuff.items")
local utils = require("hood_stuff.utils")

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

local function buff_selector()
	local changed = false
	if config.cfg.tracker_settings ~= nil then
		-- TODO: test Remove expired
		changed, config.cfg.remove_expired = imgui.checkbox("Automatically remove expired", config.cfg.remove_expired)
		utils.GhettoLoopThis(config.cfg.tracker_settings, function(k, v)
			changed, config.cfg.tracker_settings[k] =
					imgui.checkbox(items_db.item_timers_en[k], config.cfg.tracker_settings[k])
		end, true)
	end
end

local function overlay_bg_settings()
	local changed = false
	if imgui.button("Enable background", { 150, 50 }) then
		config.cfg.background = true
	end
	imgui.same_line()
	if imgui.button("Disable background", { 150, 50 }) then
		config.cfg.background = false
	end

	imgui.same_line()
	changed, config.cfg.background_locked = imgui.checkbox("Lock Background Position \n experimental feature",
		config.cfg.background_locked)

	imgui.new_line()
	if not config.cfg.background then
		return
	end
	changed, config.cfg.background_color = imgui.color_picker_argb("Bg Color", config.cfg.background_color)
	if not config.cfg.background_locked then
		changed, config.cfg.background_size_x = imgui.slider_int("Width", config.cfg.background_size_x, 0, 5000)
	end
	changed, config.cfg.background_size_y = imgui.slider_int("Height", config.cfg.background_size_y, 0, 5000)
	if not config.cfg.background_locked then
		changed, config.cfg.bg_loc.x = imgui.slider_int("BACKGROUND X POS", config.cfg.bg_loc.x, 0, 3840)
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
	-- TODO: turn this font settings thing into its own window
	if imgui.button("Overlay Settings") then
		overlay_settings_open = not overlay_settings_open
	end
	if overlay_settings_open then
		local window_open = imgui.begin_window("Edit Overlay Settings", true, 64)
		if window_open then
			imgui.new_line()
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
				draw2d.SetFontSettings(config.cfg.font_size, config.cfg.bold_font, config.cfg.italic_font, config.cfg.font_name)
			end

			imgui.new_line()
			changed, config.cfg.loc.x = imgui.slider_int("FONT X POS", config.cfg.loc.x, 0, 3840)
			changed, config.cfg.loc.y = imgui.slider_int("FONT Y POS", config.cfg.loc.y, 0, 2160)
			changed, config.cfg.space_between_buffs = imgui.slider_int("Space Between Buffs", config.cfg.space_between_buffs,
				10, 50)
			imgui.new_line()

			-- Check box for using columns
			if imgui.checkbox("Use columns", config.cfg.use_columns) then
				config.cfg.use_columns = not config.cfg.use_columns
			end
			if config.cfg.use_columns then
				if config.cfg.items_per_column <= 0 then
					config.cfg.items_per_column = 7
				end
				changed, config.cfg.items_per_column = imgui.slider_int("Items per column", config.cfg.items_per_column, 1, 16)
				changed, config.cfg.space_between_columns = imgui.slider_int("Space between columns",
					config.cfg.space_between_columns, 0, 1000)
			end
			imgui.new_line()

			if imgui.collapsing_header("Edit Font Color") then
				changed, config.cfg.expired_color = imgui.color_picker_argb("Expired Color", config.cfg.expired_color)
				changed, config.cfg.active_color = imgui.color_picker_argb("Active Color", config.cfg.active_color)
			end

			if imgui.collapsing_header("Buff Tracker (which buffs to track)") then
				buff_selector()
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
		-- TODO: add popup to let users know they have to reset the script to show the overlay again
		-- re.msg("You have to reset the script to show the overlay again. \n ScriptRunner > Reset scripts")
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

	imgui.same_line()
	-- opens new window
	overlay_settings()

	if not imgui.collapsing_header("Preset Manager (will update eventually)") then return end
	imgui.text("This assumes your in game resolution is 1920x1080")
	if imgui.button("Load Bottom Config") then
		local bottom_pres = json.load_file("hood-timers-preset-bottom.json")
		if bottom_pres then
			config.cfg = bottom_pres
		else
			re.msg("Bottom preset config file not found, using current settings")
		end
	end

	imgui.same_line()
	if imgui.button("Load Right Config") then
		local right_pres = json.load_file("hood-timers-preset-right.json")
		if right_pres then
			config.cfg = right_pres
		else
			re.msg("Right preset config file not found, using current settings")
		end
	end
	imgui.same_line()
	if imgui.button("Load Top Config") then
		local top_pres = json.load_file("hood-timers-preset-top.json")
		if top_pres then
			config.cfg = top_pres
		else
			re.msg("Right preset config file not found, using current settings")
		end
	end
	imgui.same_line()
	if imgui.button("Reset") then
		config.cfg = nil
		config.InitConfig()
		json.dump_file("hood-timers.json", config.cfg)
	end
end

return settings_ui
