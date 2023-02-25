minetest.register_node("ctf_map:unwalkable_dirt", {
	description = "Unwalkable Dirt",
	tiles = {"default_dirt.png^[colorize:#ffff00:19"},
	is_ground_content = false,
	walkable = false,
	groups = {crumbly=3, soil=1}
})

minetest.register_node("ctf_map:unwalkable_stone", {
	description = "Unwalkable Stone",
	tiles = {"default_stone.png^[colorize:#ffff00:17"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=1}
})

minetest.register_node("ctf_map:unwalkable_cobble", {
	description = "Unwalkable Cobblestone",
	tiles = {"default_cobble.png^[colorize:#ffff00:15"},
	is_ground_content = false,
	walkable = false,
	groups = {cracky=3, stone=2}
})

--
--- Spike Trap
--

minetest.register_node("ctf_map:spike", {
	description = "Spike\n7 DPS",
	drawtype = "plantlike",
	tiles = {"ctf_map_spike.png"},
	inventory_image = "ctf_map_spike.png",
	use_texture_alpha = "clip",
	paramtype = "light",
	paramtype2 = "meshoptions",
	sunlight_propagates = true,
	walkable = false,
	damage_per_second = 7,
	groups = {cracky=1, level=2},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
	},
	on_place = function(itemstack, placer, pointed_thing)
		local pteam = ctf_teams.get(placer)

		if pteam then
			if not ctf_core.pos_inside(pointed_thing.above, ctf_teams.get_team_territory(pteam)) then
				minetest.chat_send_player(placer:get_player_name(), "You can only place spikes in your own territory!")
				return itemstack
			end

			local newitemstack = ItemStack("ctf_map:spike_"..pteam)
			newitemstack:set_count(itemstack:get_count())

			local result = minetest.item_place(newitemstack, placer, pointed_thing, 34)

			if result then
				itemstack:set_count(result:get_count())
			end

			return itemstack
		end

		return minetest.item_place(itemstack, placer, pointed_thing, 34)
	end
})

for _, team in ipairs(ctf_teams.teamlist) do
	local spikecolor = ctf_teams.team[team].color

	minetest.register_node("ctf_map:spike_"..team, {
		description = HumanReadable(team).." Team Spike",
		drawtype = "plantlike",
		tiles = {"ctf_map_spike.png^[colorize:"..spikecolor..":150"},
		inventory_image = "ctf_map_spike.png^[colorize:"..spikecolor..":150",
		use_texture_alpha = "clip",
		paramtype = "light",
		paramtype2 = "meshoptions",
		sunlight_propagates = true,
		walkable = false,
		damage_per_second = 7,
		groups = {cracky=1, level=2},
		drop = "ctf_map:spike",
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		},
		on_place = function(itemstack, placer, pointed_thing)
			return minetest.item_place(itemstack, placer, pointed_thing, 34)
		end
	})
end

minetest.register_on_player_hpchange(function(player, hp_change, reason)
	if reason.type == "node_damage" then
		local team = ctf_teams.get(player)

		if team and reason.node == string.format("ctf_map:spike_%s", team) then
			return 0, true
		end
	end

	return hp_change
end, true)

--
-- Damage Cobble
--

local function damage_cobble_dig(pos, node, digger)
	if not digger:is_player() then return end

	local digger_name = digger:get_player_name()
	local digger_team = ctf_teams.get(digger_name)

	local meta = minetest.get_meta(pos)
	local placer_name = meta:get_string("placer")
	meta:set_string("placer", "")

	local placer_team = ctf_teams.get(placer_name)
	if placer_team ~= digger_team and not ctf_modebase.match_started then
		return
	end

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
	description = "Damage Cobble\n(Damages any enemy that breaks it)",
	tiles = {"ctf_map_damage_cobble.png"},
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

minetest.register_node("ctf_map:landmine", {
	description = "Landmine",
	drawtype = "nodebox",
	tiles = {"ctf_map_landmine.png", "ctf_map_landmine.png^[transformFY"},
	inventory_image = "ctf_map_landmine.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = true,
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

		meta:set_string("placer", name)
	end
})

minetest.register_abm({
	label = "Landmine",
	nodenames = {"ctf_map:landmine"},
	interval = 0.5,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		local placer = meta:get_string("placer")
		local is_team = 0
		local trigger = minetest.get_objects_in_area({x=pos.x-0.5, y=pos.y-0.5, z=pos.z-0.5},
				{x=pos.x+0.5, y=pos.y-0.3, z=pos.z+0.5})
		for _, v in pairs(trigger) do
			if v:is_player() and ctf_teams.get(v:get_player_name()) ~= ctf_teams.get(placer) then
				is_team = is_team + 1
				minetest.chat_send_all(tostring(ctf_teams.get(v:get_player_name())) .. " and " .. tostring(ctf_teams.get(placer)))
			end
		end
		if is_team == 0 then
			return
		else
			minetest.chat_send_all(is_team)
			local plyrs = minetest.get_objects_inside_radius(pos, 3)
			local placerobj = placer and minetest.get_player_by_name(placer)

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

			for _, v in pairs(plyrs) do
				if v:is_player() and ctf_teams.get(v:get_player_name()) ~= ctf_teams.get(placer) then
					if placerobj then
						v:punch(placerobj, 1, {damage_groups = {fleshy = 15, landmine = 1}})
					else
						local chp = v:get_hp()
						v:set_hp(chp - 15)
					end
				end
			end
			minetest.remove_node(pos)
		end
	end
})
