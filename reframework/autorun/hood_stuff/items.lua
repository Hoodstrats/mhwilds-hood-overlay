local items = {}

-- TODO: use these to loop through and grab the fields
-- internal names of the timers for these items
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
	megaarmorskin = "_KoukaDrink_G",
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
	megaarmorskin = "Mega Armorskin",
	food = "Food",
}
-- Korean display names for items
items.item_timers_kr = {
	hotdrink = "핫 드링크",
	cooldrink = "쿨 드링크",
	immunizer = "이뮤나이저",
	dashjuice = "대시 주스",
	mightseed = "힘의 씨앗",
	mightpill = "힘의 환약",
	demonpowder = "귀인의 가루",
	demondrug = "귀인약",
	megademondrug = "대귀인약",
	adamantseed = "인내의 씨앗",
	adamantpill = "인내의 환약",
	hardshellpowder = "경화 가루",
	armorskin = "경화약",
	megaarmorskin = "대경화약",
}

-- Empty to store our config buff order if we're using manual override
items.buff_order_keys = {}

-- Point to the item icon version of the images this by default is
--Loads <gamedir>/reframework/images/image.png
items.item_info = {
	hotdrink = {
		name = "Hot Drink",
		effect = "Cold Res (Environment)",
		icon = "hood_icons/hotdrink.png",
		status_icon = "hood_icons/status_icons/hotdrink.png",
	},
	cooldrink = {
		name = "Cool Drink",
		effect = "Heat Res (Environment)",
		icon = "hood_icons/cooldrink.png",
		status_icon = "hood_icons/status_icons/cooldrink.png",
	},
	immunizer = {
		name = "Immunizer",
		effect = "Health Rejuv",
		icon = "hood_icons/immunizer.png",
		status_icon = "hood_icons/status_icons/immunizer.png",
	},
	dashjuice = {
		name = "Dash Juice",
		effect = "Stam Rejuv",
		icon = "hood_icons/dashjuice.png",
		status_icon = "hood_icons/status_icons/dashjuice.png",
	},
	mightseed = {
		name = "Might Seed",
		effect = "+10 ATK",
		icon = "hood_icons/mightseed.png",
		status_icon = "hood_icons/status_icons/attack_up_seedpill.png",
	},
	mightpill = {
		name = "Might Pill",
		effect = "+25 ATK",
		icon = "hood_icons/mightpill.png",
		status_icon = "hood_icons/status_icons/attack_up_seedpill.png",
	},
	demonpowder = {
		name = "Demon Powder",
		effect = "+10 ATK",
		icon = "hood_icons/demonpowder.png",
		status_icon = "hood_icons/status_icons/attack_up_powder.png",
	},
	demondrug = {
		name = "Demondrug",
		effect = "+7 ATK",
		icon = "hood_icons/demondrug.png",
		status_icon = "hood_icons/status_icons/attack_up_drug.png",
	},
	megademondrug = {
		name = "Mega Demondrug",
		effect = "+10 ATK",
		icon = "hood_icons/megademondrug.png",
		status_icon = "hood_icons/status_icons/attack_up_drug.png",
	},
	adamantseed = {
		name = "Adamant Seed",
		effect = "+20 DEF",
		icon = "hood_icons/adamantseed.png",
		status_icon = "hood_icons/status_icons/defense_up_seedpill.png",
	},
	adamantpill = {
		name = "Adamant Pill",
		effect = "x1.3 DEF",
		icon = "hood_icons/adamantpill.png",
		status_icon = "hood_icons/status_icons/defense_up_seedpill.png",
	},
	hardshellpowder = {
		name = "Hardshell Powder",
		effect = "+20 DEF",
		icon = "hood_icons/hardshellpowder.png",
		status_icon = "hood_icons/status_icons/defense_up_powder.png",
	},
	armorskin = {
		name = "Armorskin",
		effect = "+15 DEF",
		icon = "hood_icons/armorskin.png",
		status_icon = "hood_icons/status_icons/defense_up_drug.png",
	},
	megaarmorskin = {
		name = "Mega Armorskin",
		effect = "+25 DEF",
		icon = "hood_icons/megaarmorskin.png",
		status_icon = "hood_icons/status_icons/defense_up_drug.png",
	},
	food = {
		name = "Food",
		effect = "Provides various buffs depending on the meal.",
		icon = "hood_icons/status_icons/food.png",
		status_icon = "hood_icons/status_icons/food.png",
	},
}

items.other_misc = {
	attack_charm = "",
	defence_charm = "",
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
