local full_ores = {
	{"stone", "default:cobble"},
	{"steel", "default:steel_ingot"},
	{"bronze", "default:bronze_ingot"},
	{"mese", "default:mese_crystal"},
	{"diamond", "default:diamond"},
}
local lim_ores = {
	{"stone", "default:cobble"},
	{"steel", "default:steel_ingot"},
}

for _, orex in pairs(full_ores) do
	crafting.register_recipe({
		type   = "inv",
		output = "default:sword_" .. orex[1],
		items  = { "default:stick", orex[2] .. " 2" },
		always_known = true,
		level  = 1,
	})
end

crafting.register_recipe({
	type   = "inv",
	output = "shooter:arrow_white 5",
	items  = { "default:stick 5", "default:cobble" },
	always_known = true,
	level  = 1,
})

for _, orex in pairs(full_ores) do
	crafting.register_recipe({
		type   = "inv",
		output = "default:pick_" .. orex[1],
		items  = { "default:stick 2", orex[2] .. " 3" },
		always_known = true,
		level  = 1,
	})
end
for _, orex in pairs(lim_ores) do
	crafting.register_recipe({
		type   = "inv",
		output = "default:shovel_" .. orex[1],
		items  = { "default:stick 2", orex[2] },
		always_known = true,
		level  = 1,
	})
end
for _, orex in pairs(lim_ores) do
	crafting.register_recipe({
		type   = "inv",
		output = "default:axe_" .. orex[1],
		items  = { "default:stick 2", orex[2] .. " 2" },
		always_known = true,
		level  = 1,
	})
end

crafting.register_recipe({
	type   = "inv",
	output = "default:bronze_ingot 9",
	items  = { "default:copper_ingot 8", "default:tin_ingot"},
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:mese_crystal 9",
	items  = { "default:mese"},
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:furnace",
	items  = { "default:cobble 10" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "doors:door_steel",
	items  = { "default:steel_ingot 6" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:wood 4",
	items  = { "group:tree" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:stick 4",
	items  = { "default:wood" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:torch 5",
	items  = { "default:stick", "default:coal_lump" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:ladder 5",
	items  = { "default:stick 7" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:stick 2",
	items  = { "default:ladder" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:wood 3",
	items  = { "default:pick_wood" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:wood 2",
	items  = { "default:sword_wood" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:wood 3",
	items  = { "default:axe_wood" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:wood 1",
	items  = { "default:shovel_wood" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "shooter:ammo 1",
	items  = { "default:steel_ingot 5", "default:coal_lump 2" },
	always_known = true,
	level  = 1,
})
