minetest.register_node("ctf_map:unwalkable_dirt", {
	description = "Unwalkable Dirt",
	tiles = {"default_dirt.png^[colorize:#00ff00:20"},
	is_ground_content = false,
	walkable = false,
	groups = {crumbly=3, soil=1}
})

minetest.register_node("ctf_map:unwalkable_stone", {
	description = "Unwalkable Stone",
	tiles = {"default_stone.png^[colorize:#00ff00:20"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=1}
})

minetest.register_node("ctf_map:unwalkable_cobble", {
	description = "Unwalkable Cobblestone",
	tiles = {"default_cobble.png^[colorize:#00ff00:20"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=2}
})

minetest.register_node("ctf_map:spike", {
	description = "Spike",
	drawtype = "plantlike",
	tiles = {"ctf_map_spike.png"},
	inventory_image = "ctf_map_spike.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	damage_per_second = 7,
	groups = {cracky=1, level=2},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local name = placer:get_player_name()

		meta:set_string("placer", minetest.serialize({
			name = name
		}))
	end
})

local function damage_cobble_dig(pos, node, digger)
	if not digger:is_player() then return end

	local digger_name = digger:get_player_name()
	local digger_team = ctf_teams.get(digger_name)

	local meta = minetest.get_meta(pos)
	local placer_name = meta:get_string("placer")
	meta:set_string("placer", "")

	local placer_team = ctf_teams.get(placer_name)

	if digger_team == placer_team then return end

	local placerobj = minetest.get_player_by_name(placer_name)

	if placerobj then
		digger:punch(placerobj, 10, {
			damage_groups = {
				fleshy = 7,
				damage_cobble = 1,
			}
		})
	else
		digger:set_hp(digger:get_hp() - 7)
	end

	minetest.remove_node(pos)
	return true
end

minetest.register_node("ctf_map:damage_cobble", {
	description = "Cobblestone that damages digger of enemy team",
	tiles = {"default_cobble.png^[colorize:#ff0000:20"},
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3, stone=2},
	on_ranged_shoot = function(pos, node, shooter, type)
		if type == "pistol" then
			return
		end

		if not damage_cobble_dig(pos, node, shooter) then
			return minetest.dig_node(pos)
		end
	end,
	on_dig = function(pos, node, digger)
		if not damage_cobble_dig(pos, node, digger) then
			return minetest.node_dig(pos, node, digger)
		end
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		meta:set_string("placer", placer:get_player_name())
	end
})

minetest.register_node("ctf_map:reinforced_cobble", {
	description = "Reinforced Cobblestone",
	tiles = {"ctf_map_reinforced_cobble.png"},
	is_ground_content = false,
	groups = {cracky = 1, stone = 2},
	sounds = default.node_sound_stone_defaults(),
})
