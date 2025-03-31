local d2d = d2d
local config = require("hood_stuff.config")
local utils = require("hood_stuff.utils")
local items = require("hood_stuff.items")

local draw = {}
local font = nil
local item_icons = {
	icons = {},
	status_icons = {},
	effects = {},
}

draw.is_drawing = false

--- @param size number
--- @param bold boolean
--- @param italic boolean
--- @param font_name string
function draw.SetFontSettings(size, bold, italic, font_name)
	config.cfg.font_size = size
	config.cfg.font_name = font_name or "Tahoma"
	-- Recreate font if it already exists
	if font then
		if bold and italic then
			font = d2d.Font.new(config.cfg.font_name, config.cfg.font_size, bold, italic)
		elseif bold then
			font = d2d.Font.new(config.cfg.font_name, config.cfg.font_size, bold)
		elseif italic then
			font = d2d.Font.new(config.cfg.font_name, config.cfg.font_size, italic)
		else
			font = d2d.Font.new(config.cfg.font_name, config.cfg.font_size)
		end
	end
end

-- this can't be changed live so I added a "edit buffs" button to settings
local function InitFN()
	if font == nil then
		local font_name = config.cfg.font_name or "Tahoma"
		font = d2d.Font.new(font_name, config.cfg.font_size, config.cfg.bold_font, config.cfg.italic_font)
	end

	-- cache our new icons with d2d.Image.new
	for key, value in pairs(items.item_info) do
		local icon
		local status_icon
		local effect
		-- since we have tables inside our table
		if type(value) == "table" then
			icon = value.icon
			status_icon = value.status_icon
			effect = value.effect
		end
		if value then
			item_icons.icons[key] = d2d.Image.new(icon)
			item_icons.status_icons[key] = d2d.Image.new(status_icon)
			item_icons.effects[key] = effect
		else
			print("Item icon not found for key: " .. key)
		end
	end
end

local function display_with_columns(hunter, x, color_active, color_expired)
	local item_counter = 0
	local items_per_column = config.cfg.items_per_column or 10
	local column_width = config.cfg.space_between_columns

	-- will default to ghettolooping with sort for alphabetical if anything goes wrong
	config.loop_the_buffs(function(k, item_name)
		if config.cfg.tracker_settings[k] == false then
			return
		end
		-- Calculate column and position
		local column = math.floor(item_counter / items_per_column)
		local column_x = x + (column * column_width)
		local row_y = config.cfg.loc.y + ((item_counter % items_per_column) * config.cfg.space_between_buffs)

		if item_name ~= "Food" then
			local total_seconds = hunter.items[k]
			if total_seconds <= 0 and config.cfg.remove_expired then
				return
			end
			local formatted_time = utils.GetTheTime(total_seconds)
			local icon
			local effect
			if config.cfg.show_effect then
				effect = item_icons.effects[k]
			end
			if config.cfg.show_icons then
				icon = item_icons.icons[k]
			elseif config.cfg.show_status_icons then
				icon = item_icons.status_icons[k]
			end
			if total_seconds > 0 then
				if icon then
					-- NOTE: example of icon + timer mode
					d2d.image(icon, column_x - 40, row_y - 2, 32, 32)
					d2d.text(font, formatted_time, column_x, row_y, color_active)
				else
					d2d.text(font, item_name .. ": " .. formatted_time, column_x, row_y, color_active)
				end
				if effect then
					if config.cfg.effect_loc.x > 0 then
						d2d.text(font, effect, column_x + config.cfg.effect_loc.x, row_y, color_active)
					else
						d2d.text(font, effect, column_x + 80, row_y, color_active)
					end
				end
			else
				if icon then
					d2d.image(icon, column_x - 40, row_y - 2, 32, 32)
					d2d.text(font, ": expired!", column_x, row_y, color_expired)
				else
					d2d.text(font, item_name .. ": expired!", column_x, row_y, color_expired)
				end
			end
		else
			if hunter.food.food_duration > 0 or not config.cfg.remove_expired then
				local icon
				local formatted_time = utils.GetTheTime(hunter.food.food_duration)
				if hunter.food.food_duration > 0 then
					if config.cfg.show_icons then
						icon = item_icons.icons["food"]
					elseif config.cfg.show_status_icons then
						icon = item_icons.status_icons["food"]
					end
					if icon then
						d2d.image(icon, column_x - 40, row_y - 2, 32, 32)
						d2d.text(font, formatted_time, column_x, row_y, color_active)
					else
						d2d.text(font, "Food: " .. formatted_time, column_x, row_y, color_active)
					end
				else
					if icon then
						d2d.image(icon, column_x - 40, row_y - 2, 32, 32)
						d2d.text(font, ": expired!", column_x, row_y, color_expired)
					else
						d2d.text(font, "Food: expired!", column_x, row_y, color_expired)
					end
				end
			end
		end

		item_counter = item_counter + 1
	end)

	-- Add FPS display if enabled
	if config.cfg.fps_active then
		local fps_column = math.floor(item_counter / items_per_column)
		local fps_row = item_counter % items_per_column
		local fps_x = x + (fps_column * column_width)
		local fps_y = config.cfg.loc.y + (fps_row * config.cfg.space_between_buffs)

		d2d.text(font, "UI FPS: " .. d2d.detail.get_max_updaterate(), fps_x, fps_y, color_active)
	end

	-- Return the final Y position for other elements that might need it
	return config.cfg.loc.y + (((item_counter + 1) % items_per_column) * config.cfg.space_between_buffs)
end

local function draw_bg()
	if config.cfg.background then
		d2d.fill_rounded_rect(
			config.cfg.bg_loc.x,
			config.cfg.bg_loc.y,
			config.cfg.background_size_x,
			config.cfg.background_size_y,
			5,
			15,
			config.cfg.background_color
		)
	end
end

-- use the x and y as starting points passed in from the register function in test
function draw.DisplayBuffTimer(hunter)
	return function()
		if not config.cfg.overlay then
			return
		end
		if not hunter.hunter then
			return
		end
		-- make sure the colors coming in from the config have max alpha
		local color_active = 0xFF000000 | config.cfg.active_color
		local color_expired = 0xFF000000 | config.cfg.expired_color
		local currentY = config.cfg.loc.y
		-- set our location from here instead of passing it in
		local x = config.cfg.loc.x
		--dynamic_backdrop()
		draw_bg()
		display_with_columns(hunter, x, color_active, color_expired)
	end
end

function draw.Register(hunter)
	d2d.register(InitFN, draw.DisplayBuffTimer(hunter))
	d2d.detail.set_max_updaterate(config.cfg.max_update_rate)
	-- prevent the user from rendering the UI multiple times even when pressing hide u button
	draw.is_drawing = true
end

return draw
