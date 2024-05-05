function ctf_modebase.update_crafts(name)
	crafting.lock_all(name)

	local current_mode = ctf_modebase:get_current_mode()

	if current_mode and current_mode.crafts then
		crafting.unlock(name, current_mode.crafts)
	end
end

ctf_api.register_on_mode_start(function()
	for _, player in pairs(minetest.get_connected_players()) do
		ctf_modebase.update_crafts(player:get_player_name())
	end
end)


minetest.register_on_joinplayer(function(player)
	ctf_modebase.update_crafts(player:get_player_name())
end)

local sword_materials = {
	steel   = "default:steel_ingot",
	mese    = "default:mese_crystal",
	diamond = "default:diamond",
}

-- Swords
for material, craft_material in pairs(sword_materials) do
	crafting.register_recipe({
		output = "ctf_melee:sword_" .. material,
		items  = { "default:stick", craft_material .. " 2" },
		always_known = false,
	})
end

local full_ores = {
	diamond = "default:diamond",
	mese = "default:mese_crystal",
	steel = "default:steel_ingot",
	stone = "default:cobble",
}

-- Pickaxes
for ore, ore_item in pairs(full_ores) do
	crafting.register_recipe({
		output = "default:pick_" .. ore,
		items  = { "default:stick 2", ore_item .. " 3" },
		always_known = true,
	})
end

-- Mese crystal x9 <== Mese block
crafting.register_recipe({
	output = "default:mese_crystal 9",
	items  = { "default:mese"},
	always_known = true,
})

-- Furnace <== group:stone x8
crafting.register_recipe({
	output = "default:furnace",
	items  = { "group:stone 8" },
	always_known = true,
})

-- Team door
crafting.register_recipe({
	output = "ctf_teams:door_steel",
	items  = { "default:steel_ingot 6" },
	always_known = true,
})

-- Cobble Stairs
crafting.register_recipe({
	output = "stairs:stair_cobble 8",
	items  = { "default:cobble 6"},
	always_known = true,
})

-- Desert Cobble Stairs
crafting.register_recipe({
	output = "stairs:stair_desert_cobble 8",
	items  = { "default:desert_cobble 6"},
	always_known = true,
})

-- Wood x4
crafting.register_recipe({
	output = "default:wood 4",
	items  = { "group:tree" },
	always_known = true,
})

-- Stick x4
crafting.register_recipe({
	output = "default:stick 4",
	items  = { "group:wood" },
	always_known = true,
})

-- Torch x5
crafting.register_recipe({
	output = "default:torch 5",
	items  = { "default:stick", "default:coal_lump" },
	always_known = true,
})

-- Wooden ladder x4
crafting.register_recipe({
	output = "default:ladder 4",
	items  = { "default:stick 8" },
	always_known = true,
})

-- Stick x2 <== Wooden ladder
crafting.register_recipe({
	output = "default:stick 2",
	items  = { "default:ladder" },
	always_known = true,
})

-- Fence x4
crafting.register_recipe({
	output = "default:fence_wood 4",
	items  = { "group:wood 4", "default:stick 2" },
	always_known = true,
})

-- Ammo
crafting.register_recipe({
	output = "ctf_ranged:ammo",
	items  = { "default:steel_ingot 2", "default:coal_lump" },
	always_known = false,
})

-- Shovels and Axes
for ore, ore_item in pairs(full_ores) do
	local show = true
	if ore == "diamond" or ore == "mese" then
		show = false
	end

	crafting.register_recipe({
		output = "default:shovel_" .. ore,
		items  = { "default:stick 2", ore_item },
		always_known = show,
	})

	crafting.register_recipe({
		output = "default:axe_" .. ore,
		items  = { "default:stick 2", ore_item},
		always_known = show,
	})
end

-- Traps

crafting.register_recipe({
	output = "ctf_map:spike",
	items  = { "default:steel_ingot 4" },
	always_known = false,
})

crafting.register_recipe({
	output = "ctf_map:damage_cobble",
	items = { "ctf_map:unwalkable_cobble", "ctf_map:spike" },
	always_known = false,
})

crafting.register_recipe({
	output = "ctf_map:reinforced_cobble 2",
	items  = { "default:cobble 6", "default:steel_ingot" },
	always_known = false,
})

crafting.register_recipe({
	output = "ctf_tnt:tnt_stick 2",
	items = { "default:papyrus", "ctf_ranged:ammo 2" },
	always_known = true,
})
crafting.register_recipe({
	output = "ctf_tnt:tnt",
	items = { "ctf_tnt:tnt_stick 8" },
	always_known = true,
})

