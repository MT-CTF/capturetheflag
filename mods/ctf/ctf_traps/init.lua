minetest.register_node("ctf_traps:dirt", {
	description = "Unwalkable Dirt",
	tiles = {"ctf_traps_dirt.png"},
	is_ground_content = false,
	walkable = false,
	groups = {crumbly=3, soil=1}
})

minetest.register_node("ctf_traps:stone", {
	description = "Unwalkable Stone",
	tiles = {"ctf_traps_stone.png"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=1}
})

minetest.register_node("ctf_traps:cobble", {
	description = "Unwalkable Cobblestone",
	tiles = {"ctf_traps_cobble.png"},
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
	tiles = {"ctf_traps_damage_cobble.png"},
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3, stone=2},
	on_dig = function(pos, node, digger, extra)
		if not digger:is_player() then return end

		local name = digger:get_player_name()
		if not digger then
			return
		end

		local digger_team = ctf.player(name).team
		local meta = minetest.get_meta(pos)
		local placer = minetest.deserialize(meta:get_string("placer"))

		local placer_team = placer and placer.team or "missing"
		if digger_team ~= placer_team then
			local placerobj = placer and minetest.get_player_by_name(placer.name)

			if placerobj then
				digger:punch(placerobj, 10, {damage_groups = {fleshy = 7}}, vector.new(0, 1, 0))
			else
				local hp = digger:get_hp()
				if hp > 0 then
					digger:set_hp(hp - 7)
				end
			end

			minetest.remove_node(pos)
			return
		end

		if not extra or extra.do_dig then
			meta:set_string("placer", "")
			return minetest.node_dig(pos, node, digger)
		end
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local name = placer:get_player_name()

		meta:set_string("placer", minetest.serialize({
			team = ctf.player(name).team,
			name = name,
		}))
	end
})
