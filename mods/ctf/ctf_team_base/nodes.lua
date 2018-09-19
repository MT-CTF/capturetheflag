minetest.register_node("ctf_team_base:ind_cobble", {
	description = "Cobblestone",
	tiles = {"default_cobble.png"},
	is_ground_content = false,
	groups = {immortal = 1},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_team_base:reinforced_cobble", {
	description = "Reinforced Cobblestone",
	tiles = {"ctf_team_base_reinforced_cobble.png"},
	is_ground_content = false,
	groups = {cracky = 1, stone = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_craft({
	output = "ctf_team_base:reinforced_cobble",
	type   = "shapeless",
	recipe = {
		{"default:cobble", "default:cobble"},
		{"default:cobble", "default:cobble"}
	},
})
