local sword_ores = {
	{"wood", "default:wood"},
	{"stone", "default:cobble"},
	{"steel", "default:steel_ingot"},
	{"bronze", "default:bronze_ingot"},
	{"mese", "default:mese_crystal"},
	{"diamond", "default:diamond"},
}
local lim_ores = {
	{"wood", "default:wood"},
	{"stone", "default:cobble"},
	{"steel", "default:steel_ingot"},
}

for _, orex in pairs(sword_ores) do
	crafting.register_recipe({
		type   = "inv",
		output = "default:sword_" .. orex[1],
		items  = { "default:stick", orex[2] .. " 2" },
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
	output = "default:furnace",
	items  = { "default:cobble 10" },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "doors:door_steel",
	items  = { "default:steel 6", },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:wood 4",
	items  = { "group:tree", },
	always_known = true,
	level  = 1,
})

crafting.register_recipe({
	type   = "inv",
	output = "default:stick 4",
	items  = { "default:wood", },
	always_known = true,
	level  = 1,
})
