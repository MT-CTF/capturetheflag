--Spears from mod Lottweapons, originally made by Amaz

--Spears:
minetest.register_tool("spears:spear_stone", {
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
minetest.register_tool("spears:spear_mese", {
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