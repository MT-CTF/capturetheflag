local full_ores = {
	diamond = "default:diamond",
	mese = "default:mese_crystal",
	bronze = "default:bronze_ingot",
	steel = "default:steel_ingot",
	stone = "default:cobble",
}

local sword_materials = {
	steel   = "default:steel_ingot",
	mese    = "default:mese_crystal",
	diamond = "default:diamond",
}

-- Rocket <== Gold ingot x16 + Coal lump x5
crafting.register_recipe({
	type   = "inv",
	output = "shooter_rocket:rocket",
	items  = { "default:gold_ingot 16", "default:coal_lump 5" },
	always_known = false,
	level  = 1,
})

-- Rocket <== Mese x5 + Coal lump x5
crafting.register_recipe({
	type   = "inv",
	output = "shooter_rocket:rocket",
	items  = { "default:mese 5", "default:coal_lump 5" },
	always_known = false,
	level  = 1,
})

-- Swords
for material, craft_material in pairs(sword_materials) do
	crafting.register_recipe({
		type   = "inv",
		output = "default:sword_" .. material,
		items  = { "default:stick", craft_material .. " 2" },
		always_known = true,
		level  = 1,
	})
end

-- Pickaxes
for ore, ore_item in pairs(full_ores) do
	crafting.register_recipe({
		type   = "inv",
		output = "default:pick_" .. ore,
		items  = { "default:stick 2", ore_item .. " 3" },
		always_known = true,
		level  = 1,
	})
end

-- Bronze ingot x9 <== Copper x9 + Tin x9
crafting.register_recipe({
	type   = "inv",
	output = "default:bronze_ingot 9",
	items  = { "default:copper_ingot 8", "default:tin_ingot"},
	always_known = true,
	level  = 1,
})

-- Mese crystal x9 <== Mese block
crafting.register_recipe({
	type   = "inv",
	output = "default:mese_crystal 9",
	items  = { "default:mese"},
	always_known = true,
	level  = 1,
})

--Bronze block <== Bronze Ingot x9
crafting.register_recipe({
	type   = "inv",
	output = "default:bronzeblock",
	items  = { "default:bronze_ingot 9" },
	always_known = true,
	level  = 1,
})

--Steel block <== Steel Ingot x9
crafting.register_recipe({
	type   = "inv",
	output = "default:steelblock",
	items  = { "default:steel_ingot 9" },
	always_known = true,
	level  = 1,
})

-- Furnace <== group:stone x8
crafting.register_recipe({
	type   = "inv",
	output = "default:furnace",
	items  = { "group:stone 8" },
	always_known = true,
	level  = 1,
})

-- Team door
crafting.register_recipe({
	type   = "inv",
	output = "doors:door_steel",
	items  = { "default:steel_ingot 6" },
	always_known = true,
	level  = 1,
})

-- Reinforced Cobblestone
crafting.register_recipe({
	type   = "inv",
	output = "ctf_map:reinforced_cobble",
	items  = { "default:cobble 4", "default:steel_ingot" },
	always_known = true,
	level  = 1,
})

-- Wood x4
crafting.register_recipe({
	type   = "inv",
	output = "default:wood 4",
	items  = { "group:tree" },
	always_known = true,
	level  = 1,
})

-- Stick x4
crafting.register_recipe({
	type   = "inv",
	output = "default:stick 4",
	items  = { "default:wood" },
	always_known = true,
	level  = 1,
})

-- Torch x5
crafting.register_recipe({
	type   = "inv",
	output = "default:torch 5",
	items  = { "default:stick", "default:coal_lump" },
	always_known = true,
	level  = 1,
})

-- Ammo <== Tin ingot x3 + Coal lump x2
crafting.register_recipe({
	type   = "inv",
	output = "shooter:ammo",
	items  = { "default:tin_ingot 3", "default:coal_lump 2" },
	always_known = true,
	level  = 1,
})

-- Ammo <== Steel ingot x3 + Coal lump x2
crafting.register_recipe({
	type   = "inv",
	output = "shooter:ammo",
	items  = { "default:steel_ingot 3", "default:coal_lump 2" },
	always_known = true,
	level  = 1,
})

-- Arrow x5
crafting.register_recipe({
	type   = "inv",
	output = "shooter:arrow_white 5",
	items  = { "default:stick 5", "default:cobble" },
	always_known = true,
	level  = 1,
})

-- 7.62mm sniper rifle (unloaded)
crafting.register_recipe({
	type   = "inv",
	output = "sniper_rifles:rifle_762",
	items  = { "default:steelblock", "default:bronze_ingot 5", "default:mese_crystal", "default:wood" },
	always_known = false,
	level  = 1
})

-- Magnum sniper rifle (unloaded)
crafting.register_recipe({
	type   = "inv",
	output = "sniper_rifles:rifle_magnum",
	items  = { "default:steelblock", "default:bronzeblock", "default:diamond", "default:wood" },
	always_known = false,
	level  = 1,
})

-- Wooden ladder x4
crafting.register_recipe({
	type   = "inv",
	output = "default:ladder 4",
	items  = { "default:stick 8" },
	always_known = true,
	level  = 1,
})

-- Stick x2 <== Wooden ladder
crafting.register_recipe({
	type   = "inv",
	output = "default:stick 2",
	items  = { "default:ladder" },
	always_known = true,
	level  = 1,
})

-- Traps
crafting.register_recipe({
	type   = "inv",
	output = "ctf_traps:spike 1",
	items  = { "default:steel_ingot 5" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "ctf_traps:dirt 1",
	items  = { "default:dirt 5", "default:coal_lump" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "ctf_traps:cobble 1",
	items  = { "default:cobble 5", "default:coal_lump" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "ctf_traps:stone 1",
	items  = { "default:stone 5", "default:coal_lump" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "ctf_traps:damage_cobble 1",
	items  = { "default:cobble", "default:coal_lump 4", "default:steel_ingot 4" },
	always_known = true,
	level  = 1,
})

-- Shovels
for ore, ore_item in pairs(full_ores) do
	local show = true
	if ore == "diamond" or ore == "mese" or ore == "bronze" then
		show = false
	end

	crafting.register_recipe({
		type   = "inv",
		output = "default:shovel_" .. ore,
		items  = { "default:stick 2", ore_item },
		always_known = show,
		level  = 1,
	})
end

-- Axes
for ore, ore_item in pairs(full_ores) do
	local show = true
	if ore == "diamond" or ore == "mese" or ore == "bronze" then
		show = false
	end

	crafting.register_recipe({
		type   = "inv",
		output = "default:axe_" .. ore,
		items  = { "default:stick 2", ore_item},
		always_known = show,
		level  = 1,
	})
end

--
--- Grenade Crafts
--

crafting.register_recipe({
	type   = "inv",
	output = "grenades:frag 1",
	items  = { "default:steel_ingot 5", "default:iron_lump" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "grenades:frag_sticky 1",
	items  = { "grenades:frag", "default:stick 4" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "grenades:smoke 1",
	items  = { "default:steel_ingot 5", "default:coal_lump 4" },
	always_known = true,
	level  = 1,
})

-- crafting.register_recipe({
-- 	type   = "inv",
-- 	output = "grenades:flashbang 1",
-- 	items  = { "default:steel_ingot 5", "default:torch 5" },
-- 	always_known = true,
-- 	level  = 1,
-- })
