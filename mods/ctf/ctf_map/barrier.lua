local c_ind_stone      = minetest.get_content_id("ctf_map:stone")
local c_ind_stone_red  = minetest.get_content_id("ctf_map:ind_stone_red")
local c_ind_glass      = minetest.get_content_id("ctf_map:ind_glass")
local c_ind_glass_red  = minetest.get_content_id("ctf_map:ind_glass_red")
local c_ignore = minetest.get_content_id("ctf_map:ignore")
local c_stone = minetest.get_content_id("default:stone")
local c_water      = minetest.get_content_id("default:water_source")
local c_air        = minetest.get_content_id("air")

function ctf_map.remove_middle_barrier()
	local r = ctf_map.map.r
	local h = ctf_map.map.h

	local min = vector.add(ctf_map.map.offset, {
		x = -r + 1,
		y = -h / 2,
		z = -1
	})
	local max = vector.add(ctf_map.map.offset, {
		x = r - 1,
		y = h / 2,
		z = 1
	})

	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(min, max)
	local a = VoxelArea:new{
		MinEdge = emin,
		MaxEdge = emax
	}
	local data = vm:get_data()
	for x = min.x, max.x do
		for y = min.y, max.y do
			local vi   = a:index(x, y,  0)
			local adj1 = a:index(x, y,  1)
			local adj2 = a:index(x, y, -1)

			if data[vi] == c_ind_glass_red then
				-- If surrounding nodes are water, replace node with water
				if data[adj1] == c_water and data[adj2] == c_water then
					data[vi] = c_water
				-- Else replace with air
				else
					data[vi] = c_air
				end
			elseif data[vi] == c_ind_stone_red then
				data[vi] = c_stone
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(data)
	vm:update_map()
end

function ctf_map.place_middle_barrier(center, r, h, direction)
	assert(direction == "x" or direction == "z")

	local min = {
		x = -r + 1,
		y = -h / 2 + 1,
		z = -r + 1,
	}
	local max = {
		x = r - 1,
		y = h / 2 - 1,
		z = r - 1,
	}

	local other = "z"
	if direction == "z" then
		other = "x"
	end

	min[direction] = -1
	max[direction] = 1
	min = vector.add(center, min)
	max = vector.add(center, max)


	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(min, max)
	local a = VoxelArea:new{
		MinEdge = emin,
		MaxEdge = emax
	}

	local data = vm:get_data()
	for x = min[other], max[other] do
		for y = min.y, max.y do
			local vi
			if other == "x" then
				vi = a:index(x, y, center.z)
			else
				vi = a:index(center.x, y, x)
			end
			if data[vi] == c_air or data[vi] == c_water then
				data[vi] = c_ind_glass_red
			elseif data[vi] == c_stone then
				data[vi] = c_ind_stone_red
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(data)
	vm:update_map()
end

-- Returns the appropriate barrier node depending on the existing node
local function get_barrier_node(c_id)
	-- If existing node is air/ind. glass/CTF ignore, return ind. glass
	-- Else return ind. stone
	if c_id == c_air or c_id == c_ind_glass or c_id == c_ignore then
		return c_ind_glass
	else
		return c_ind_stone
	end
end

function ctf_map.place_outer_barrier(center, r, h)
	local minp = vector.subtract(center, r)
	local maxp = vector.add(center, r)
	minp.y = center.y - h / 2
	maxp.y = center.y + h / 2

	minetest.log("action", "Map maker: Loading data into LVM")

	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local a = VoxelArea:new{
		MinEdge = emin,
		MaxEdge = emax
	}
	local data = vm:get_data()

	-- Left
	minetest.log("action", "Map maker: Placing left wall")
	do
		local x = center.x - r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				data[vi] = get_barrier_node(data[vi])
			end
		end
	end

	-- Right
	minetest.log("action", "Map maker: Placing right wall")
	do
		local x = center.x + r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				data[vi] = get_barrier_node(data[vi])
			end
		end
	end

	-- Front
	minetest.log("action", "Map maker: Placing front wall")
	do
		local z = center.z - r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				data[vi] = get_barrier_node(data[vi])
			end
		end
	end

	-- Back
	minetest.log("action", "Map maker: Placing back wall")
	do
		local z = center.z + r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				data[vi] = get_barrier_node(data[vi])
			end
		end
	end

	-- Bedrock
	minetest.log("action", "Map maker: Placing bedrock")
	do
		local y = minp.y
		for x = minp.x, maxp.x do
			for z = minp.z, maxp.z do
				data[a:index(x, y, z)] = c_ind_stone
			end
		end
	end

	-- Ceiling
	minetest.log("action", "Map maker: Placing ceiling")
	do
		local y = maxp.y
		for x = minp.x, maxp.x do
			for z = minp.z, maxp.z do
				data[a:index(x, y, z)] = c_ind_glass
			end
		end
	end

	minetest.log("action", "Map maker: Writing to engine!")

	vm:set_data(data)
	vm:write_to_map(data)
	vm:update_map()
end

if minetest.get_modpath("ctf") then
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
			if ctf_map.get_team_relative_z(player) < 0 and not ctf_map.can_cross(player) then
				local name = player:get_player_name()
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
end
