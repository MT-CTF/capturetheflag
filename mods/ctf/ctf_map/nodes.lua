minetest.register_node("ctf_map:ignore", {
	description = "Artificial Ignore", -- this may need to be given a more appropriate name
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
	description = "Indestructible Glass",
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
	description = "Indestructible Stone",
	groups = {immortal = 1},
	tiles = {"default_stone.png"},
	is_ground_content = false
})

minetest.register_node("ctf_map:ind_dirt", {
	description = "Indestructible Dirt",
	groups = {immortal = 1},
	tiles = {"default_dirt.png"},
	is_ground_content = false,
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25}
	}),
})

minetest.register_node("ctf_map:ind_dirt_with_grass", {
	description = "Indestructible Dirt with Grass",
	groups = {immortal = 1},
	tiles = {"default_grass.png", "default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png",
				tileable_vertical = false}},
	is_ground_content = false,
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	}),
})

minetest.register_node("ctf_map:ind_stone_red", {
	description = "Indestructible Red Stone",
	groups = {immortal = 1},
	tiles = {"ctf_map_stone_red.png"},
	is_ground_content = false
})

minetest.register_node("ctf_map:ind_glass_red", {
	description = "Indestructible Red Glass",
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
