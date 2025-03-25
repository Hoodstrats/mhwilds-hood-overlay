local config = require("hood_stuff.config")
local utils = require("hood_stuff.utils")
local items_db = require("hood_stuff.items")

local draw = {}
local font = nil
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
end

local function display_with_columns(width, padding, hunter, x, y, color_active, color_expired)
	local item_counter = 0
	local items_per_column = config.cfg.items_per_column or 10 -- How many items per column
	local column_width = config.cfg.space_between_columns

	utils.GhettoLoopThis(items_db.item_timers_en, function(k, item_name)
		if config.cfg.tracker_settings[k] == false then
			return
		end
		local total_seconds = hunter.items[k]
		if total_seconds <= 0 and config.cfg.remove_expired then
			return
		end
		-- Calculate column and position
		local column = math.floor(item_counter / items_per_column)
		local column_x = x + (column * column_width)
		local row_y = config.cfg.loc.y + ((item_counter % items_per_column) * config.cfg.space_between_buffs)

		local formatted_time = utils.GetTheTime(total_seconds)
		if total_seconds > 0 then
			d2d.text(font, item_name .. ": " .. formatted_time, column_x, row_y, color_active)
		else
			d2d.text(font, item_name .. ": expired!", column_x, row_y, color_expired)
		end

		item_counter = item_counter + 1
	end, true)

	if hunter.food.food_duration > 0 or not config.cfg.remove_expired then
		-- Add food duration to the next position in the column layout
		local food_column = math.floor(item_counter / items_per_column)
		local food_x = x + (food_column * column_width)
		local food_y = config.cfg.loc.y + ((item_counter % items_per_column) * config.cfg.space_between_buffs)

		local formatted_time = utils.GetTheTime(hunter.food.food_duration)
		if hunter.food.food_duration > 0 then
			d2d.text(font, "Food: " .. formatted_time, food_x, food_y, color_active)
		else
			d2d.text(font, "Food: expired!", food_x, food_y, color_expired)
		end

		item_counter = item_counter + 1
	end

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


local function dynamic_backdrop()
	-- Find the longest possible text from all items to set proper backdrop width
	local long_text = "Food: 00:00"
	-- NOTE: grab the length of the incoming string to use for the x pos on backdrop
	local width = font:measure(long_text)
	local padding = 110
	-- Check all item names to find the longest one
	utils.GhettoLoopThis(items_db.item_timers_en, function(k, item_name)
		if config.cfg.tracker_settings[k] == false then
			return
		end
		local item_text = item_name .. ": expired!"
		if font:measure(item_text) > font:measure(long_text) then
			long_text = item_text
		end
	end, true)

	-- If columns are enabled, consider two of the longest texts side by side
	if config.cfg.use_columns and config.cfg.items_per_column > 0 then
		local measured_width = font:measure(long_text)
		width = measured_width * 2 + padding -- Account for two columns
	else
		width = font:measure(long_text) + padding
	end

	-- NOTE: BACKDROP
	if config.cfg.background then
		-- x, y, width, height, corner round x, corner round y, thickness, color
		-- d2d.rounded_rect(x, config.cfg.loc.y, 355, 500, 5, 15, 5, config.cfg.background_color)
		-- x, y, width, height, corner round x, corner round y, color
		if not config.cfg.background_locked then
			d2d.fill_rounded_rect(config.cfg.bg_loc.x, config.cfg.bg_loc.y, config.cfg.background_size_x,
				config.cfg.background_size_y, 5, 15,
				config.cfg.background_color)
		else
			d2d.fill_rounded_rect(config.cfg.loc.x - 40, config.cfg.loc.y, width + padding,
				config.cfg.background_size_y, 5, 15,
				config.cfg.background_color)
		end
	end
end

-- use the x and y as starting points passed in from the register function in test
function draw.DisplayBuffTimer(hunter)
	return function()
		if not config.cfg.overlay then return end
		if not hunter.hunter then return end
		-- make sure the colors coming in from the config have max alpha
		local color_active = 0xFF000000 | config.cfg.active_color
		local color_expired = 0xFF000000 | config.cfg.expired_color
		local currentY = config.cfg.loc.y
		-- set our location from here instead of passing it in
		local x = config.cfg.loc.x

		dynamic_backdrop()

		if config.cfg.use_columns then
			display_with_columns(width, padding, hunter, x, currentY, color_active, color_expired)
		else
			-- Loop through our predefined item structure
			utils.GhettoLoopThis(items_db.item_timers_en, function(k, item_name)
				if config.cfg.tracker_settings[k] == false then
					return
				end
				local total_seconds = hunter.items[k]
				if total_seconds <= 0 and config.cfg.remove_expired then
					return
				end
				local formatted_time = utils.GetTheTime(total_seconds)
				if total_seconds > 0 then
					d2d.text(font, item_name .. ": " .. formatted_time, x, currentY, color_active)
				else
					d2d.text(font, item_name .. ": expired!", x, currentY, color_expired)
				end
				currentY = currentY + config.cfg.space_between_buffs -- Increment Y position for the next item
			end, true)

			-- food
			if hunter.food.food_duration > 0 or not config.cfg.remove_expired then
				local formatted_time = utils.GetTheTime(hunter.food.food_duration)
				if hunter.food.food_duration > 0 then
					d2d.text(font, "Food: " .. formatted_time, x, currentY, color_active)
				else
					d2d.text(font, "Food: expired!", x, currentY, color_expired)
				end
				currentY = currentY + config.cfg.space_between_buffs -- Increment Y position for the next item

				if config.cfg.fps_active then
					d2d.text(font, "UI FPS: " .. d2d.detail.get_max_updaterate(), x, currentY, color_active)
				end
			end
		end

		-- FIXME: charms are not working
		-- currentY = currentY + cfg.space -- Increment Y position for the next item
		-- if hunter.charms.attack_charm == "Attack Charm: Missing!" then
		-- 	d2d.text(font, hunter.charms.attack_charm, x, currentY, color_expired)
		-- else
		-- 	d2d.text(font, hunter.charms.attack_charm, x, currentY, color_active)
		-- end
		-- currentY = currentY + cfg.space -- Increment Y position for the next item
		-- if hunter.charms.defence_charm == "Defence Charm: Missing!" then
		-- 	d2d.text(font, hunter.charms.defence_charm, x, currentY, color_expired)
		-- else
		-- 	d2d.text(font, hunter.charms.defence_charm, x, currentY, color_active)
		-- end
	end
end

function draw.Register(hunter)
	d2d.register(InitFN, draw.DisplayBuffTimer(hunter))
	d2d.detail.set_max_updaterate(config.cfg.max_update_rate)
	-- prevent the user from rendering the UI multiple times even when pressing hide u button
	draw.is_drawing = true
end

return draw
