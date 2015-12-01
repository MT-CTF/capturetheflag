minetest.register_node("ctf_barrier:ind_glass", {
	description = "You cheater you!",
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

minetest.register_node("ctf_barrier:ind_stone", {
	description = "Cheater!",
	groups = {immortal = 1},
	tiles = {"default_stone.png"},
	is_ground_content = false
})

minetest.register_node("ctf_barrier:ind_glass_red", {
	description = "You cheater you!",
	drawtype = "glasslike",
	tiles = {"ctf_barrier_red.png"},
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

local c_stone      = minetest.get_content_id("ctf_barrier:ind_stone")
local c_glass      = minetest.get_content_id("ctf_barrier:ind_glass")
local c_glass_red  = minetest.get_content_id("ctf_barrier:ind_glass_red")
local c_water      = minetest.get_content_id("default:water_source")
local c_water_f    = minetest.get_content_id("default:water_flowing")
local c_air        = minetest.get_content_id("air")
local r            = tonumber(minetest.setting_get("barrier"))
minetest.register_on_generated(function(minp, maxp, seed)
	if not ((minp.x <= -r and maxp.x >= -r)
			or (minp.x <= r and maxp.x >= r)
			or (minp.y <= -r and maxp.x >= -r)
			or (minp.y <= r and maxp.x >= r)
			or (minp.z <= -r and maxp.z >= -r)
			or (minp.z <= 0 and maxp.z >= 0)
			or (minp.z <= r and maxp.z >= r and ctf_match.build_timer > 0)) then
		return
	end

	-- Set up voxel manip
	local t1 = os.clock()
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local a = VoxelArea:new{
			MinEdge={x=emin.x, y=emin.y, z=emin.z},
			MaxEdge={x=emax.x, y=emax.y, z=emax.z},
	}
	local data = vm:get_data()

	-- Left
	if minp.x <= -r and maxp.x >= -r then
		local x = -r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)

				if data[vi] == c_air or data[vi] == c_glass then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	-- Right
	if minp.x <= r and maxp.x >= r then
		local x = r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air or data[vi] == c_glass then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	-- Front
	if minp.z <= -r and maxp.z >= -r then
		local z = -r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air or data[vi] == c_glass then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	-- Back
	if minp.z <= r and maxp.z >= r then
		local z = r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air or data[vi] == c_glass then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	-- Barrier
	if minp.z <= 0 and maxp.z >= 0 and ctf_match.build_timer > 0 then
		local z = 0
		local x1 = minp.x
		if x1 < -r then x1 = -r end
		local x2 = maxp.x
		if x2 > r then x2 = r end
		for x = x1, x2 do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				local node = data[vi]
				if node == c_air or node == c_glass_red or
						node == c_water or node == c_water_f then
					data[vi] = c_glass_red
				end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(data)
end)

ctf_match.register_on_build_time_end(function()
	local min = {
		x = -r + 1,
		y = -r,
		z = -1
	}
	local max = {
		x = r - 1,
		y = r,
		z = 1
	}

	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(min, max)
	local a = VoxelArea:new{
		MinEdge = emin,
		MaxEdge = emax
	}
	local data = vm:get_data()
	for x = min.x, max.x do
		for y = min.y, max.y do
			local vi = a:index(x, y, 0)
			if data[vi] == c_glass_red then
				data[vi] = c_air
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(data)
	vm:update_map()
end)

--[[minetest.register_abm({
	nodenames = {"ctf_barrier:ind_glass_red"},
	interval = 10.0, -- Run every 10 seconds
	chance = 2, -- Select every 1 in 50 nodes
	action = function(pos, node, active_object_count, active_object_count_wider)
		if ctf_match.build_timer > 0 then
			return
		end

		minetest.set_node(pos, {name = "air"})
	end
})]]

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if ctf_match.build_timer <= 0 then
		return old_is_protected(pos, name)
	end

	local tname = ctf.player(name).team
	if tname and
			(tname == "blue" and pos.z >= 0) or (tname == "red" and pos.z <= 0) then
		minetest.chat_send_player(name, "Can't dig beyond the barrier!")
		return true
	else
		return old_is_protected(pos, name)
	end
end

local function pos_check()
	if ctf_match.build_timer <= 0 then
		return
	end

	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local tname = ctf.player(name).team
		local pos = player:getpos()
		if tname and
				(tname == "blue" and pos.z >= 0) or (tname == "red" and pos.z <= 0) then
			minetest.chat_send_player(name, "Match hasn't started yet!")
			ctf.move_to_spawn(name)
		end
	end

	if ctf_match.build_timer > 0.2 then
		minetest.after(0.2, pos_check)
	end
end

ctf_match.register_on_build_time_start(function()
	minetest.after(0.2, pos_check)
end)
