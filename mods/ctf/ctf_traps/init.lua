minetest.register_node("ctf_traps:dirt", {
	description = "Unwalkable Dirt",
	tiles = {"default_dirt.png^[colorize:#bfff00:20"},
	is_ground_content = false,
	walkable = false,
	groups = {crumbly=3, soil=1}
})

minetest.register_node("ctf_traps:stone", {
	description = "Unwalkable Stone",
	tiles = {"default_stone.png^[colorize:#bfff00:20"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=1}
})

minetest.register_node("ctf_traps:cobble", {
	description = "Unwalkable Cobblestone",
	tiles = {"default_cobble.png^[colorize:#bfff00:20"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=2}
})

minetest.register_node("ctf_traps:spike", {
	description = "Spike",
	drawtype = "plantlike",
	tiles = {"ctf_traps_spike.png"},
	inventory_image = "ctf_traps_spike.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	damage_per_second = 7,
	groups = {cracky=1, level=2},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
})

minetest.register_node("ctf_traps:damage_cobble", {
	description = "Cobblestone that damages digger of enemy team",
	tiles = {"default_cobble.png^[colorize:#820000:20"},
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3, stone=2},
	on_dig = function(pos, node, digger)
		local name = digger:get_player_name()
		if not digger then
			return
		end

		local digger_team = ctf.player(name).team
		local meta = minetest.get_meta(pos)
		local placer_team = meta:get_string("placer") or "missing"
		if digger_team ~= placer_team then
			local hp = digger:get_hp()
			digger:set_hp(hp - 7)
			minetest.remove_node(pos)
			return
		end

		meta:set_string("placer", "")
		return minetest.node_dig(pos, node, digger)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local name = placer:get_player_name()
		meta:set_string("placer", ctf.player(name).team)
	end
})
