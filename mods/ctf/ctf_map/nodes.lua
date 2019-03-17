minetest.register_node("ctf_map:reinforced_cobble", {
	description = "Reinforced Cobblestone",
	tiles = {"ctf_map_reinforced_cobble.png"},
	is_ground_content = false,
	groups = {cracky = 1, stone = 2},
	sounds = default.node_sound_stone_defaults(),
})


--
-- Special nodes
--

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

	groups = {immortal = 1},
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

minetest.register_node("ctf_map:ind_glass_red", {
	description = "Indestructible Red Glass",
	drawtype = "glasslike",
	tiles = {"ctf_map_glass_red.png"},
	inventory_image = minetest.inventorycube("ctf_map_glass_red.png"),
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

minetest.register_node("ctf_map:ind_stone_red", {
	description = "Indestructible Red Stone",
	groups = {immortal = 1},
	tiles = {"ctf_map_stone_red.png"},
	is_ground_content = false
})

--
-- Indestructible nodes for building
--

-- Stone

minetest.register_node("ctf_map:stone", {
	description = "Indestructible Stone",
	tiles = {"default_stone.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:cobble", {
	description = "Cobblestone",
	tiles = {"default_cobble.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:stonebrick", {
	description = "Indestructible Stone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_stone_brick.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:stone_block", {
	description = "Indestructible Stone Block",
	tiles = {"default_stone_block.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:mossycobble", {
	description = "Indestructible Mossy Cobblestone",
	tiles = {"default_mossycobble.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:desert_stone", {
	description = "Indestructible Desert Stone",
	tiles = {"default_desert_stone.png"},
	groups = {immortal = 1},

	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:desert_cobble", {
	description = "Indestructible Desert Cobblestone",
	tiles = {"default_desert_cobble.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:desert_stonebrick", {
	description = "Indestructible Desert Stone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_desert_stone_brick.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:desert_stone_block", {
	description = "Indestructible Desert Stone Block",
	tiles = {"default_desert_stone_block.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:sandstone", {
	description = "Indestructible Sandstone",
	tiles = {"default_sandstone.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:sandstonebrick", {
	description = "Indestructible Sandstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_sandstone_brick.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:sandstone_block", {
	description = "Indestructible Sandstone Block",
	tiles = {"default_sandstone_block.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:desert_sandstone", {
	description = "Indestructible Desert Sandstone",
	tiles = {"default_desert_sandstone.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:desert_sandstone_brick", {
	description = "Indestructible Desert Sandstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_desert_sandstone_brick.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:desert_sandstone_block", {
	description = "Indestructible Desert Sandstone Block",
	tiles = {"default_desert_sandstone_block.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:silver_sandstone", {
	description = "Indestructible Silver Sandstone",
	tiles = {"default_silver_sandstone.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:silver_sandstone_brick", {
	description = "Indestructible Silver Sandstone Brick",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_silver_sandstone_brick.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:silver_sandstone_block", {
	description = "Indestructible Silver Sandstone Block",
	tiles = {"default_silver_sandstone_block.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

-- Soft / Non-Stone

minetest.register_node("ctf_map:dirt", {
	description = "Indestructible Dirt",
	tiles = {"default_dirt.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_dirt_defaults(),
})

minetest.register_node("ctf_map:dirt_with_grass", {
	description = "Indestructible Dirt with Grass",
	tiles = {"default_grass.png", "default_dirt.png",
		{name = "default_dirt.png^default_grass_side.png",
			tileable_vertical = false}},
	groups = {immortal = 1},

	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.25},
	}),
})

minetest.register_node("ctf_map:dirt_with_dry_grass", {
	description = "Indestructible Dirt with Dry Grass",
	tiles = {"default_dry_grass.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_dry_grass_side.png",
			tileable_vertical = false}},
	groups = {immortal = 1},

	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
})

minetest.register_node("ctf_map:dirt_with_snow", {
	description = "Indestructible Dirt with Snow",
	tiles = {"default_snow.png", "default_dirt.png",
		{name = "default_dirt.png^default_snow_side.png",
			tileable_vertical = false}},
	groups = {immortal = 1},

	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.15},
	}),
})

minetest.register_node("ctf_map:dirt_with_rainforest_litter", {
	description = "Indestructible Dirt with Rainforest Litter",
	tiles = {
		"default_rainforest_litter.png",
		"default_dirt.png",
		{name = "default_dirt.png^default_rainforest_litter_side.png",
			tileable_vertical = false}
	},
	groups = {immortal = 1},

	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_grass_footstep", gain = 0.4},
	}),
})

minetest.register_node("ctf_map:sand", {
	description = "Indestructible Sand",
	tiles = {"default_sand.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_sand_defaults(),
})

minetest.register_node("ctf_map:desert_sand", {
	description = "Indestructible Desert Sand",
	tiles = {"default_desert_sand.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_sand_defaults(),
})

minetest.register_node("ctf_map:silver_sand", {
	description = "Indestructible Silver Sand",
	tiles = {"default_silver_sand.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_sand_defaults(),
})


minetest.register_node("ctf_map:gravel", {
	description = "Indestructible Gravel",
	tiles = {"default_gravel.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_gravel_defaults(),
})

minetest.register_node("ctf_map:clay", {
	description = "Indestructible Clay",
	tiles = {"default_clay.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_dirt_defaults(),
})


minetest.register_node("ctf_map:snow", {
	description = "Indestructible Snow",
	tiles = {"default_snow.png"},
	inventory_image = "default_snowball.png",
	wield_image = "default_snowball.png",
	paramtype = "light",
	buildable_to = true,
	floodable = true,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
		},
	},
	groups = {immortal = 1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.15},
		dug = {name = "default_snow_footstep", gain = 0.2},
		dig = {name = "default_snow_footstep", gain = 0.2}
	})
})

minetest.register_node("ctf_map:snowblock", {
	description = "Indestructible Snow Block",
	tiles = {"default_snow.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_dirt_defaults({
		footstep = {name = "default_snow_footstep", gain = 0.15},
		dug = {name = "default_snow_footstep", gain = 0.2},
		dig = {name = "default_snow_footstep", gain = 0.2}
	})
})

minetest.register_node("ctf_map:ice", {
	description = "Indestructible Ice",
	tiles = {"default_ice.png"},
	is_ground_content = false,
	paramtype = "light",
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults(),
})

-- Trees

minetest.register_node("ctf_map:tree", {
	description = "Indestructible Tree",
	tiles = {"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("ctf_map:wood", {
	description = "Indestructible Wooden Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_wood.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("ctf_map:leaves", {
	description = "Indestructible Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"default_leaves.png"},
	special_tiles = {"default_leaves_simple.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("ctf_map:apple", {
	description = "Indestructible Apple",
	drawtype = "plantlike",
	tiles = {"default_apple.png"},
	inventory_image = "default_apple.png",
	stack_max = 99,
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	is_ground_content = false,
	selection_box = {
		type = "fixed",
		fixed = {-3 / 16, -7 / 16, -3 / 16, 3 / 16, 4 / 16, 3 / 16}
	},
	groups = {immortal = 1},
	sounds = default.node_sound_leaves_defaults()
})


minetest.register_node("ctf_map:jungletree", {
	description = "Indestructible Jungle Tree",
	tiles = {"default_jungletree_top.png", "default_jungletree_top.png",
		"default_jungletree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("ctf_map:junglewood", {
	description = "Indestructible Jungle Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_junglewood.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("ctf_map:jungleleaves", {
	description = "Indestructible Jungle Leaves",
	drawtype = "allfaces_optional",
	waving = 1,
	tiles = {"default_jungleleaves.png"},
	special_tiles = {"default_jungleleaves_simple.png"},
	paramtype = "light",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_leaves_defaults(),
})


minetest.register_node("ctf_map:pine_tree", {
	description = "Indestructible Pine Tree",
	tiles = {"default_pine_tree_top.png", "default_pine_tree_top.png",
		"default_pine_tree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("ctf_map:pine_wood", {
	description = "Indestructible Pine Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_pine_wood.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("ctf_map:pine_needles",{
	description = "Indestructible Pine Needles",
	drawtype = "allfaces_optional",
	tiles = {"default_pine_needles.png"},
	waving = 1,
	paramtype = "light",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("ctf_map:acacia_tree", {
	description = "Indestructible Acacia Tree",
	tiles = {"default_acacia_tree_top.png", "default_acacia_tree_top.png",
		"default_acacia_tree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("ctf_map:acacia_wood", {
	description = "Indestructible Acacia Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_acacia_wood.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("ctf_map:acacia_leaves", {
	description = "Indestructible Acacia Leaves",
	drawtype = "allfaces_optional",
	tiles = {"default_acacia_leaves.png"},
	special_tiles = {"default_acacia_leaves_simple.png"},
	waving = 1,
	paramtype = "light",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_leaves_defaults(),
})

minetest.register_node("ctf_map:aspen_tree", {
	description = "Indestructible Aspen Tree",
	tiles = {"default_aspen_tree_top.png", "default_aspen_tree_top.png",
		"default_aspen_tree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node
})

minetest.register_node("ctf_map:aspen_wood", {
	description = "Indestructible Aspen Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_aspen_wood.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("ctf_map:aspen_leaves", {
	description = "Indestructible Aspen Leaves",
	drawtype = "allfaces_optional",
	tiles = {"default_aspen_leaves.png"},
	waving = 1,
	paramtype = "light",
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_leaves_defaults(),
})

--
-- Ores
--

minetest.register_node("ctf_map:stone_with_coal", {
	description = "Indestructible Coal Ore",
	tiles = {"default_stone.png^default_mineral_coal.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:coalblock", {
	description = "Indestructible Coal Block",
	tiles = {"default_coal_block.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})


minetest.register_node("ctf_map:stone_with_iron", {
	description = "Indestructible Iron Ore",
	tiles = {"default_stone.png^default_mineral_iron.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:stone_with_copper", {
	description = "Indestructible Copper Ore",
	tiles = {"default_stone.png^default_mineral_copper.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:stone_with_tin", {
	description = "Indestructible Tin Ore",
	tiles = {"default_stone.png^default_mineral_tin.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:bronzeblock", {
	description = "Indestructible Bronze Block",
	tiles = {"default_bronze_block.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_metal_defaults(),
})

minetest.register_node("ctf_map:stone_with_mese", {
	description = "Indestructible Mese Ore",
	tiles = {"default_stone.png^default_mineral_mese.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:mese", {
	description = "Indestructible Mese Block",
	tiles = {"default_mese_block.png"},
	paramtype = "light",
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
	light_source = 3,
})

minetest.register_node("ctf_map:stone_with_diamond", {
	description = "Indestructible Diamond Ore",
	tiles = {"default_stone.png^default_mineral_diamond.png"},
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

-- Plantlife (non-cubic)

minetest.register_node("ctf_map:cactus", {
	description = "Indestructible Cactus",
	tiles = {"default_cactus_top.png", "default_cactus_top.png",
		"default_cactus_side.png"},
	paramtype2 = "facedir",
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults(),
	on_place = minetest.rotate_node,
})

minetest.register_node("ctf_map:ladder_wood", {
	description = "Indestructible Wooden Ladder",
	drawtype = "signlike",
	tiles = {"default_ladder_wood.png"},
	inventory_image = "default_ladder_wood.png",
	wield_image = "default_ladder_wood.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	walkable = false,
	climbable = true,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
		--wall_top = = <default>
		--wall_bottom = = <default>
		--wall_side = = <default>
	},
	groups = {immortal = 1},
	legacy_wallmounted = true,
	sounds = default.node_sound_wood_defaults(),
})

default.register_fence("ctf_map:fence_wood", {
	description = "Indestructible Wooden Fence",
	texture = "default_fence_wood.png",
	inventory_image = "default_fence_overlay.png^default_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "ctf_map:wood",
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("ctf_map:fence_acacia_wood", {
	description = "Indestructible Acacia Fence",
	texture = "default_fence_acacia_wood.png",
	inventory_image = "default_fence_overlay.png^default_acacia_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_acacia_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "ctf_map:acacia_wood",
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("ctf_map:fence_junglewood", {
	description = "Indestructible Jungle Wood Fence",
	texture = "default_fence_junglewood.png",
	inventory_image = "default_fence_overlay.png^default_junglewood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_junglewood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "ctf_map:junglewood",
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("ctf_map:fence_pine_wood", {
	description = "Indestructible Pine Fence",
	texture = "default_fence_pine_wood.png",
	inventory_image = "default_fence_overlay.png^default_pine_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_pine_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "ctf_map:pine_wood",
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults()
})

default.register_fence("ctf_map:fence_aspen_wood", {
	description = "Indestructible Aspen Fence",
	texture = "default_fence_aspen_wood.png",
	inventory_image = "default_fence_overlay.png^default_aspen_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	wield_image = "default_fence_overlay.png^default_aspen_wood.png^default_fence_overlay.png^[makealpha:255,126,126",
	material = "ctf_map:aspen_wood",
	groups = {immortal = 1},
	sounds = default.node_sound_wood_defaults()
})

minetest.register_node("ctf_map:glass", {
	description = "Indestructible Glass",
	drawtype = "glasslike_framed_optional",
	tiles = {"default_glass.png", "default_glass_detail.png"},
	paramtype = "light",
	paramtype2 = "glasslikeliquidlevel",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults(),
})

minetest.register_node("ctf_map:brick", {
	description = "Indestructible Brick Block",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"default_brick.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:meselamp", {
	description = "Indestructible Mese Lamp",
	drawtype = "glasslike",
	tiles = {"default_meselamp.png"},
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults(),
	light_source = default.LIGHT_MAX,
})

minetest.register_node("ctf_map:killnode", {
	description = "Kill Node",
	drawtype = "glasslike",
	tiles = {"ctf_map_killnode.png"},
	paramtype = "light",
	sunlight_propogates = true,
	walkable = false,
	pointable = false,
	damage_per_second = 20,
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults(),
})

-- Re-register all nodes from stairs and wool
for name, nodedef in pairs(minetest.registered_nodes) do
	if name:find("stairs") then
		nodedef = table.copy(nodedef)
		nodedef.groups = {immortal = 1}
		minetest.register_node("ctf_map:" .. name:split(":")[2], nodedef)
	elseif name:find("wool") then
		nodedef = table.copy(nodedef)
		nodedef.groups = {immortal = 1}
		minetest.register_node("ctf_map:" .. name:split(":")[2], nodedef)
	end
end

minetest.register_alias("ctf_map:ind_cobble", "ctf_map:cobble")
minetest.register_alias("ctf_map:ind_stone", "ctf_map:stone")
