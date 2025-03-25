local hunter = require("hood_stuff.hunter")
local items_db = require("hood_stuff.items")
local config = require("hood_stuff.config")
local utils = require("hood_stuff.utils")

local debug = {}

function debug.GetDebugInfo()
  if imgui.collapsing_header("--- DEBUG TIMERS ---") then
    local health = utils.GetTheString(hunter.health)
    imgui.text("Health: " .. health)
    imgui.new_line()

    if hunter.food ~= nil then
      imgui.text("Food Buffs")
      imgui.text("---------")
      if hunter.food ~= nil then
        imgui.text("Food Buffs")
        imgui.text("---------")
        utils.GhettoLoopThis(hunter.food, function(k, v)
          if k == "rest" or k == "food_duration" then
            v = utils.GetTheTime(v)
          end
          imgui.text(k .. ": " .. v)
        end, true)
      end
    end
    imgui.new_line()
    imgui.text("Item Timers")
    imgui.text("---------")


    local sorted_items = utils.GetSortedTable(items_db.item_timers_en)
    for _, k in ipairs(sorted_items) do
      if config.cfg.tracker_settings[k] == false then
        goto continue
      end
      local total_seconds = hunter.items[k]
      local formatted_time = utils.GetTheTime(total_seconds)
      if total_seconds > 0 then
        imgui.text(items_db.item_timers_en[k] .. ": " .. formatted_time)
      else
        imgui.text(items_db.item_timers_en[k] .. ": expired!")
      end
      ::continue::
    end


    imgui.new_line()
    imgui.text("Do you own the Charms/Talismans")
    imgui.text("---------")

    -- FIXME: you were close to finding the issue
    -- FIXME: get item hook into those methods you posted on discord
    for k, v in pairs(hunter.charms) do
      imgui.text(v)
    end
  end
end

return debug
