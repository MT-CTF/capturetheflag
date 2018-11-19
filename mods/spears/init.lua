--Spears from mod Lottweapons, originally made by Amaz

--Spears:
minetest.register_tool("spears:stone_spear", {
	description = "Stone Spear",
	inventory_image = "lottweapons_stone_spear.png",
	wield_image = "lottweapons_stone_spear.png^[transformFX",
	range = 5,
	tool_capabilities = {
		full_punch_interval = 1.1,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=2.75, [2]=1.75, [3]=0.75}, uses=5, maxlevel=1},
		},
		damage_groups = {fleshy=3},
	}
})
minetest.register_tool("spears:mese_spear", {
	description = "Mese Spear",
	inventory_image = "lottweapons_gold_spear.png",
	wield_image = "lottweapons_gold_spear.png^[transformFX",
	range = 5,
	tool_capabilities = {
		full_punch_interval = 1.2,
		max_drop_level=1,
		groupcaps={
			snappy={times={[1]=2.2, [2]=1.2, [3]=0.20}, uses=20, maxlevel=1},
		},
		damage_groups = {fleshy=4},
	}
})
--[[
minetest.register_craft({
	output = 'spears:stone_spear',
	recipe = {
		{'', 'default:cobble', ''},
		{'default:cobble', 'group:stick', 'default:cobble'},
		{'', 'group:stick', ''},
	}
})

minetest.register_craft({
	output = 'spears:mese_spear',
	recipe = {
		{'', 'default:mese_crystal', ''},
		{'default:mese_crystal', 'group:stick', 'default:mese_crystal'},
		{'', 'group:stick', ''},
	}
})
--]]