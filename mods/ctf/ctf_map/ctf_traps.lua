minetest.register_node("ctf_map:unwalkable_dirt", {
	description = "Unwalkable Dirt",
	tiles = {"ctf_map_dirt.png"},
	is_ground_content = false,
	walkable = false,
	groups = {crumbly=3, soil=1}
})

minetest.register_node("ctf_map:unwalkable_stone", {
	description = "Unwalkable Stone",
	tiles = {"ctf_map_stone.png"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=1}
})

minetest.register_node("ctf_map:unwalkable_cobble", {
	description = "Unwalkable Cobblestone",
	tiles = {"ctf_map_cobble.png"},
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
})

minetest.register_node("ctf_map:damage_cobble", {
	description = "Cobblestone that damages digger of enemy team",
	tiles = {"ctf_map_damage_cobble.png"},
	is_ground_content = false,
	walkable = true,
	groups = {cracky=3, stone=2, ranged_breakable=1},
	on_dig = function(pos, node, digger, extra)
		if not digger:is_player() then return end

		local name = digger:get_player_name()
		if not digger then
			return
		end

		local digger_team = ctf_teams.get(name)
		local meta = minetest.get_meta(pos)
		local placer = minetest.deserialize(meta:get_string("placer"))

		local placer_team = placer and placer.team or "missing"
		if digger_team ~= placer_team then
			local placerobj = placer and minetest.get_player_by_name(placer.name)

			if placerobj then
				digger:punch(placerobj, 10, {
					damage_groups = {
						fleshy = 7,
						damage_cobble = 1,
					}
				}, vector.new(0, 1, 0))
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
			team = ctf_teams.get(name),
			name = name,
		}))
	end
})

minetest.register_node("ctf_map:reinforced_cobble", {
	description = "Reinforced Cobblestone",
	tiles = {"ctf_map_reinforced_cobble.png"},
	is_ground_content = false,
	groups = {cracky = 1, stone = 2},
	sounds = default.node_sound_stone_defaults(),
})

minetest.register_node("ctf_map:landmine", {
	description = "Landmine",
	drawtype = "nodebox",
	tiles = {"ctf_map_landmine.png", "ctf_map_landmine.png^[transformFY"},
	inventory_image = "ctf_map_landmine.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {cracky=1, level=2},
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.4, 0.5},
	},
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local name = placer:get_player_name()

		meta:set_string("placer", minetest.serialize({
			name = name,
			team = ctf_teams.get(name)
		}))
	end
})

minetest.register_abm({
	label = "Landmine",
	nodenames = {"ctf_map:landmine"},
	interval = 0.5,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local players = minetest.get_objects_inside_radius(pos, 2)
		local to_be_damaged = {}
		local i = 1
		local meta = minetest.get_meta(pos)
		local placer = minetest.deserialize(meta:get_string("placer"))
		local placer_team = placer.team
		local placer_obj = placer and minetest.get_player_by_name(placer.name)
		for _, v in pairs(players) do
			if v:is_player() and ctf_teams.get(v:get_player_name()) ~= placer_team then
				to_be_damaged[i] = v
				i = i + 1 -- Why Lua doesn't have += :| :| :|
			end
		end
		if i == 1 then
			return
		end
		minetest.add_particlespawner({
			amount = 20,
			time = 0.5,
			minpos = vector.subtract(pos, 3),
			maxpos = vector.add(pos, 3),
			minvel = {x = 0, y = 5, z = 0},
			maxvel = {x = 0, y = 7, z = 0},
			minacc = {x = 0, y = 1, z = 0},
			maxacc = {x = 0, y = 1, z = 0},
			minexptime = 0.3,
			maxexptime = 0.6,
			minsize = 7,
			maxsize = 10,
			collisiondetection = true,
			collision_removal = false,
			vertical = false,
			texture = "grenades_smoke.png",
		})

		minetest.add_particle({
			pos = pos,
			velocity = {x=0, y=0, z=0},
			acceleration = {x=0, y=0, z=0},
			expirationtime = 0.3,
			size = 15,
			collisiondetection = false,
			collision_removal = false,
			object_collision = false,
			vertical = false,
			texture = "grenades_boom.png",
			glow = 10
		})

		minetest.sound_play("grenades_explode", {
			pos = pos,
			gain = 1.0,
			max_hear_distance = 64,
		})

		for _, v in pairs(to_be_damaged) do
			if placer_obj then
				v:punch(placer_obj, 1, {damage_groups = {fleshy = 10}}, nil)
			else
				local chp = v:get_hp()
				v:set_hp(chp - 10)
			end
		end
		minetest.remove_node(pos)
	end
})
