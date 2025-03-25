local items = {}

local item_ids_jp = {
	"Kairiki",
	"Kairiki_G",
	"Nintai",
	"Nintai_G",
	"Jerky",
	"DashJuice",
	"Immunizer",
	"HotDrink",
	"CoolerDrink",
	"KijinDrink",
	"KijinDrink_G",
	"KoukaDrink",
	"KoukaDrink_G",
	"KijinPowder",
	"KoukaPowder",
	"KijinAmmo",
	"KoukaAmmo",
}
-- Map of item keys to their internal field names
items.item_fields = {
	hotdrink = "_HotDrink_Timer",
	cooldrink = "_CoolerDrink_Timer",
	immunizer = "_Immunizer_Timer",
	dashjuice = "_DashJuice_Timer",
	mightseed = "_Kairiki_Timer",
	mightpill = "_Kairiki_G_Timer",
	demonpowder = "_KijinPowder_Timer",
	demondrug = "_KijinDrink",
	megademondrug = "_KijinDrink_G",
	adamantseed = "_Nintai_Timer",
	adamantpill = "_Nintai_G_Timer",
	hardshellpowder = "_KoukaPowder_Timer",
	armorskin = "_KoukaDrink",
	megaarmorskin = "_KoukaDrink_G"
}

-- English display names for items
items.item_timers_en = {
	hotdrink = "Hot Drink",
	cooldrink = "Cool Drink",
	immunizer = "Immunizer",
	dashjuice = "Dash Juice",
	mightseed = "Might Seed",
	mightpill = "Might Pill",
	demonpowder = "Demon Powder",
	demondrug = "Demondrug",
	megademondrug = "Mega Demondrug",
	adamantseed = "Adamant Seed",
	adamantpill = "Adamant Pill",
	hardshellpowder = "Hardshell Powder",
	armorskin = "Armorskin",
	megaarmorskin = "Mega Armorskin"
}

items.other_misc = {
	attack_charm = "",
	defence_charm = ""
}

function items.get_timer(item, item_buff_field)
	if not item_buff_field then
		return nil
	end

	local timer_field = items.item_fields[item]
	if not timer_field then
		return nil
	end

	-- Handle special case for drink items that need nested access
	if item:find("drug") or item:find("skin") then
		local drink_obj = item_buff_field:get_field(timer_field)
		if drink_obj then
			return drink_obj:get_field("_Timer")
		else
			return nil
		end
	else
		-- Standard items with direct timer fields
		return item_buff_field:get_field(timer_field)
	end
end

-- PlayerItemParam return type of = app.user_data.PlayerItemParam
-- theres a bunch of getter methods here for everything almost
function items.get_charms(hunter)
	local pouch = hunter.hunter._Catalog:get_field("_PlayerItemParam")
	local attack_charm = pouch:get_Talisman_Attack_Add()
	local defence_charm = pouch:get_Talisman_Defence_Add()
	if attack_charm == 0 then
		items.other_misc.attack_charm = "Attack Charm: Missing!"
	else
		items.other_misc.attack_charm = "Attack Charm Equipped: " .. tostring(attack_charm)
	end
	if defence_charm == 0 then
		items.other_misc.defence_charm = "Defence Charm: Missing!"
	else
		items.other_misc.defence_charm = "Defence Charm Equipped: " .. tostring(defence_charm)
	end
	return items.other_misc
end

return items
