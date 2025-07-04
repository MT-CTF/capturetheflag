local landmines = {
	-- core.hash_node_position(vector.round(pos)) -> landmine table
	-- like landmines[core.hash_node_position(vector.round(pos))] = {s = os.clock(), p = pname, t = pteam, a = area_id}
}

local landmine_areas

local number_of_landmines = 0
local ARMING_TIME = 3
local MAX_EXPLOSIONS_PER_STEP = 2

local S = minetest.get_translator(minetest.get_current_modname())

local add_landmine = function(pos, pname, pteam)
	pos = vector.round(pos)

	local hash = core.hash_node_position(pos)
	landmines[hash] = {
		s = os.clock(),
		p = pname,
		t = pteam,
		a = landmine_areas:insert_area(
			pos:add(vector.new(-1.5, -0.5, -1.5)),
			pos:add(vector.new(1.5, 0, 1.5)),
			string.format("%d", hash)
		)
	}
	number_of_landmines = number_of_landmines + 1
end

local clear_landmines = function()
	landmines = {}
	landmine_areas = AreaStore()
	landmine_areas:set_cache_params({
		enabled = true,
		block_radius = 32,
	})

	number_of_landmines = 0
end
clear_landmines() -- Make sure values are initialized

local remove_landmine = function(pos)
	local hash = core.hash_node_position(vector.round(pos))

	landmine_areas:remove_area(landmines[hash].a)

	landmines[hash] = nil
	number_of_landmines = number_of_landmines - 1
end

local landmine_globalstep_counter = 0.0

local function is_self_landmine(object_ref, landmine)
	local pname = object_ref:get_player_name()
	if pname == "" then
		return nil -- the object ref is not a player
	end

	if not ctf_teams.get(object_ref) or ctf_teams.get(object_ref) == landmine.t then
		return true -- non-player/their landmine
	end

	return false -- it's someone else's landmine
end

local function landmine_explode(pos)
	local landmine = landmines[core.hash_node_position(vector.round(pos))]

	local near_objs = ctf_core.get_players_inside_radius(pos, 3)
	local placerobj = landmine.p and core.get_player_by_name(landmine.p)

	core.add_particlespawner({
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

	core.add_particle({
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

	core.sound_play("grenades_explode", {
		pos = pos,
		gain = 1.0,
		max_hear_distance = 64,
	})

	for _, obj in pairs(near_objs) do
		if is_self_landmine(obj, landmine) == false then
			if placerobj then
				obj:punch(
					placerobj,
					1,
					{
						damage_groups = {
							fleshy = 15,
							landmine = 1
						}
					}
				)
			else
				local chp = obj:get_hp()
				obj:set_hp(chp - 15)
			end
		end
	end
	core.remove_node(pos)
	remove_landmine(pos)
end

core.register_node("ctf_landmine:landmine", {
	description = S("Landmine (@1s arming time)", ARMING_TIME),
	drawtype = "nodebox",
	tiles = {
		"ctf_landmine_landmine.png",
		"ctf_landmine_landmine.png^[transformFY"
	},
	inventory_image = "ctf_landmine_landmine.png",
	wield_image = "ctf_landmine_landmine.png",
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
		local name = placer:get_player_name()
		local pteam = ctf_teams.get(placer)

		add_landmine(pos, name, pteam)
	end,
	on_punch = function(pos, _node, puncher, pointed_thing)
		pos = pos:round()
		local hash = core.hash_node_position(pos)

		if not is_self_landmine(puncher, landmines[hash]) then
			landmine_explode(pos)
		end
	end,
	on_dig = function(pos, node, digger)
		remove_landmine(pos)
		minetest.node_dig(pos, node, digger)
	end
})

local check_interval = 0.08
core.register_globalstep(function(dtime)
	if number_of_landmines == 0 then return end

	landmine_globalstep_counter = landmine_globalstep_counter + dtime
	if landmine_globalstep_counter < check_interval then
		return
	end
	landmine_globalstep_counter = 0.0

	local current = os.clock()
	local got = 0
	for _idx, player in ipairs(core.get_connected_players()) do
		local pos = player:get_pos()

		for id, area in pairs(landmine_areas:get_areas_for_pos(pos, false, true)) do
			local landmine = landmines[tonumber(area.data)]

			if not landmine then
				minetest.log("error", "CTF Landmines: Bad landmine index: "..area.data)
			elseif current - (landmine.s or current) >= ARMING_TIME then
				if not is_self_landmine(player, landmine) then
					local lpos = core.get_position_from_hash(tonumber(area.data))

					if lpos:distance(pos) <= 1 then -- The corners of the landmine area are more than 1 node away from lpos
						landmine_explode(lpos)
						got = got + 1

						if got >= MAX_EXPLOSIONS_PER_STEP then
							return
						end
					end
				end
			end
		end
	end
end)

ctf_api.register_on_match_end(function()
	clear_landmines()
end)
