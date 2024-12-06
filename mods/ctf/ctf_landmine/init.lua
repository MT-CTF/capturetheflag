local landmines = {
	-- core.hash_node_position(pos) -> true/false
	-- like landmines[core.hash_node_position(pos)] = true
}

local number_of_landmines = 0
local ARMING_TIME = 3

local add_landmine = function(pos)
	landmines[core.hash_node_position(pos)] = os.clock()
	number_of_landmines = number_of_landmines + 1
end

local clear_landmines = function()
	landmines = {}
	number_of_landmines = 0
end

local remove_landmine = function(pos)
	landmines[core.hash_node_position(pos)] = nil
	number_of_landmines = number_of_landmines - 1
end

local landmine_globalstep_counter = 0.0
local LANDMINE_COUNTER_THRESHOLD = 0.025

local function is_self_landmine(object_ref, pos)
	local meta = core.get_meta(pos)
	local team = meta:get_string("pteam")
	local pname = object_ref:get_player_name()
	if pname == "" then
		return nil -- the object ref is not a player
	end

	if ctf_teams.get(object_ref) == team then
		return true -- it's self landmine
	end

	return false -- it's someone else's landmine
end

local function landmine_explode(pos)
	local near_objs = ctf_core.get_players_inside_radius(pos, 3)
	local meta = core.get_meta(pos)
	local placer = meta:get_string("placer")
	local placerobj = placer and core.get_player_by_name(placer)

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
		if is_self_landmine(obj, pos) == false then
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
	description = string.format("Landmine (%ds arming time)", ARMING_TIME),
	drawtype = "nodebox",
	tiles = {
		"ctf_landmine_landmine.png",
		"ctf_landmine_landmine.png^[transformFY"
	},
	inventory_image = "ctf_landmine_landmine.png",
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
		local meta = core.get_meta(pos)
		local name = placer:get_player_name()
		local pteam = ctf_teams.get(placer)

		meta:set_string("placer", name)
		meta:set_string("pteam", pteam)
		add_landmine(pos)
	end,
	on_punch = function(pos, _node, puncher, pointed_thing)
		if not is_self_landmine(puncher, pos) then
			landmine_explode(pos)
		end
	end,
	on_dig = function(pos, node, digger)
		remove_landmine(pos)
		minetest.node_dig(pos, node, digger)
	end
})

core.register_globalstep(function(dtime)
	if number_of_landmines == 0 then return end

	landmine_globalstep_counter = landmine_globalstep_counter + dtime
	if landmine_globalstep_counter < LANDMINE_COUNTER_THRESHOLD then
		return
	end
	landmine_globalstep_counter = 0.0

	for _idx, obj in ipairs(core.get_connected_players()) do
		local pos = {
			x = math.ceil(obj:get_pos().x),
			y = math.ceil(obj:get_pos().y),
			z = math.ceil(obj:get_pos().z)
		}
		local positions_to_check = {
			pos,
			vector.add(pos, { x = 0, y = 0, z = 1}),
			vector.add(pos, { x = 1, y = 0, z = 0}),
			vector.add(pos, { x = 0, y = 0, z = -1}),
			vector.add(pos, { x = -1, y = 0, z = 0}),
			vector.add(pos, { x = 0, y = 1, z = 0}),
		}

		local current = os.clock()
		for _idx2, pos2 in ipairs(positions_to_check) do
			if current - (landmines[core.hash_node_position(pos2)] or current) >= ARMING_TIME then
				if not is_self_landmine(obj, pos2) then
					landmine_explode(pos2)
				end
			end
		end
	end
end)

ctf_api.register_on_match_end(function()
	clear_landmines()
end)
