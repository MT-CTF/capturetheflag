minetest.register_node("ctf_map:ignore", {
	description = "MyAir (you hacker you!)",
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = true,
	walkable     = true,
	pointable    = false,
	diggable     = false,
	buildable_to = false,
	air_equivalent = true,
	drop = "",
	groups = {not_in_creative_inventory=1}
})

minetest.register_node("ctf_map:ind_glass", {
	description = "You cheater you!",
	drawtype = "glasslike_framed_optional",
	tiles = {"default_glass.png", "default_glass_detail.png"},
	inventory_image = minetest.inventorycube("default_glass.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	buildable_to = false,
	pointable = false,
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults()
})

minetest.register_node("ctf_map:ind_stone", {
	description = "Cheater!",
	groups = {immortal = 1},
	tiles = {"default_stone.png"},
	is_ground_content = false
})

minetest.register_node("ctf_map:ind_stone_red", {
	description = "Cheater!",
	groups = {immortal = 1},
	tiles = {"ctf_map_stone_red.png"},
	is_ground_content = false
})

minetest.register_node("ctf_map:ind_glass_red", {
	description = "You cheater you!",
	drawtype = "glasslike",
	tiles = {"ctf_map_glass_red.png"},
	inventory_image = minetest.inventorycube("default_glass.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	buildable_to = false,
	use_texture_alpha = false,
	alpha = 0,
	pointable = false,
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults()
})
