local items_db = require("hood_stuff.items")
local hook = require("hood_stuff.hooker")

local hunter = {
	items = {},
	charms = {},
	food = {},
}

function hunter.get_items()
	if not hunter.status then
		return
	end
	local items = hunter.status:get_field("_ItemBuff")
	if not items then
		return
	end

	-- Loop through our predefined item structure
	for item_key in pairs(items_db.item_fields) do
		local timer = items_db.get_timer(item_key, items)
		if timer ~= nil then
			hunter.items[item_key] = timer
		end
	end

	hunter.charms = items_db.get_charms(hunter)
end

function hunter.get_food_buffs()
	if not hunter.status then
		return
	end
	-- returns app.cMealEffect which we can access stuff like
	-- get_MaxHealthAdd()
	-- get_MaxStaminaAdd()
	-- get_AttackAdd()
	-- get_DefenceAdd()
	-- get_AttrResistAdd()
	-- get_DurationTimer()
	-- _MealEffect itself has timer fields:
	-- _DurationTimer
	local food_buffs = hunter.status:get_field("_MealEffect")
	if food_buffs ~= nil then
		-- hunter.Resists = {}
		-- local resists = food_buffs:get_AttrResistAdd()
		-- for i in pairs(resists) do
		-- 	hunter.Resists[i] = sdk.to_int64(resists[i])
		-- end
		hunter.food.health = food_buffs:get_MaxHealthAdd()
		hunter.food.stamina = food_buffs:get_MaxStaminaAdd()
		hunter.food.attack = food_buffs:get_AttackAdd()
		hunter.food.defence = food_buffs:get_DefenceAdd()
		hunter.food.food_duration = food_buffs:get_DurationTimer()

		local guts_result = "Guts not active"
		if food_buffs:get_IsActiveGuts_L() then
			guts_result = "Guts(L) is active"
		elseif food_buffs:get_IsActiveGuts_S() then
			guts_result = "Guts(S) is active"
		end
		hunter.food.guts = guts_result

		-- Cool/Hot Drink status
		local cool_hot_result = "Cool Hot not active"
		if food_buffs:get_IsActiveCoolHot() then
			cool_hot_result = "Cool/Hot Drink is active"
		end
		hunter.food.cool_hot = cool_hot_result

		-- Water Adjust status
		local water_adjust_result = "Water Adjust not active"
		if food_buffs:get_IsActiveWaterAdjust() then
			water_adjust_result = "Water Adjust is active"
		end
		hunter.food.water_adjust = water_adjust_result

		-- Heroic status
		local heroic_result = "Heroic not active"
		if food_buffs:get_IsActiveHeroic() then
			heroic_result = "Heroic is active"
		end
		hunter.food.heroic = heroic_result

		-- Rest status
		local rest_result = nil
		if food_buffs:get_IsActiveRestBuff() then
			rest_result = food_buffs:get_RestBuffTimer()
		end
		hunter.food.rest = rest_result

		-- Uneven status
		local uneven_result = "Uneven not active"
		if food_buffs:get_IsUnevenActive_S() then
			uneven_result = "Uneven(S) is active"
		elseif food_buffs:get_IsUnevenActive_L() then
			uneven_result = "Uneven(L) is active"
		end
		hunter.food.uneven = uneven_result

		-- get the skill effects?? from the app.MealDef.SKILL
	end
end

-- FIXME: check if this is actually getting initialized
function hunter.init_hunter()
	-- app.PlayerManager
	-- hunter.hunter = sdk.get_managed_singleton("app.PlayerManager")
	hunter.hunter = hook.GetSingleton("app.PlayerManager", false)

	if not hunter.hunter then
		return
	end
	-- app.cPlayerManageInfo
	local master = hunter.hunter:getMasterPlayer()
	if not master then
		return
	end
	-- app.HunterCharacter
	hunter.character = master:get_Character()
	if not hunter.character then
		return
	end
	-- app.cHunterStatus
	hunter.status = hunter.character:get_HunterStatus()
	if not hunter.status then
		return
	end
	-- app.cHunterHealth(here we need to grab the <HealthMgr>k__BackingField which returns a app.cHealthManager)
	-- app.cHealthManager
	local health_manager = hunter.status._Health:get_field("<HealthMgr>k__BackingField")
	if not health_manager then
		return
	end
	-- this returns a system.single
	-- current health
	hunter.health = health_manager:get_Health()

	hunter.get_items()
	hunter.get_food_buffs()
end

return hunter
