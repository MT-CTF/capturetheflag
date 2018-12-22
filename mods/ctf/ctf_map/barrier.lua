local c_stone      = minetest.get_content_id("ctf_map:ind_stone")
local c_stone_red  = minetest.get_content_id("ctf_map:ind_stone_red")
local c_glass      = minetest.get_content_id("ctf_map:ind_glass")
local c_glass_red  = minetest.get_content_id("ctf_map:ind_glass_red")
local c_map_ignore = minetest.get_content_id("ctf_map:ignore")
local c_actual_st  = minetest.get_content_id("default:stone")
local c_water      = minetest.get_content_id("default:water_source")
-- local c_water_f    = minetest.get_content_id("default:water_flowing")
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

			if data[vi] == c_glass_red then
				-- If surrounding nodes are water, replace node with water
				if data[adj1] == c_water and data[adj2] == c_water then
					data[vi] = c_water
				-- Else replace with air
				else
					data[vi] = c_air
				end
			elseif data[vi] == c_stone_red then
				data[vi] = c_actual_st
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
				data[vi] = c_glass_red
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(data)
	vm:update_map()
end


function ctf_map.place_outer_barrier(center, r, h)
	local minp = vector.subtract(center, r)
	local maxp = vector.add(center, r)
	minp.y = center.y - h / 2
	maxp.y = center.y + h / 2

	print("Loading data into LVM")

	local vm = minetest.get_voxel_manip()
	local emin, emax = vm:read_from_map(minp, maxp)
	local a = VoxelArea:new{
		MinEdge = emin,
		MaxEdge = emax
	}
	local data = vm:get_data()

	print("Placing left wall")

	-- Left
	do
		local x = center.x - r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air or data[vi] == c_glass or data[vi] == c_map_ignore then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	print("Placing right wall")

	-- Right
	do
		local x = center.x + r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air or data[vi] == c_glass or data[vi] == c_map_ignore then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	print("Placing front wall")

	-- Front
	do
		local z = center.z - r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air or data[vi] == c_glass or data[vi] == c_map_ignore then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	print("Placing back wall")

	-- Back
	do
		local z = center.z + r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air or data[vi] == c_glass or data[vi] == c_map_ignore then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	print("Placing bedrock")

	-- Bedrock
	do
		local y = minp.y
		for x = minp.x, maxp.x do
			for z = minp.z, maxp.z do
				data[a:index(x, y, z)] = c_stone
			end
		end
	end

	print("Placing ceiling")

	-- Ceiling
	do
		local y = maxp.y
		for x = minp.x, maxp.x do
			for z = minp.z, maxp.z do
				data[a:index(x, y, z)] = c_glass
			end
		end
	end

	print("Writing to engine!")

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
		if tname and tname.spawn and
				tname.spawn.z * pos.z <= 0 then -- If Z coordinate of spawn and pos have opposite signs, product is negative
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
			local pos = player:get_pos()
			local privs = minetest.get_player_privs(name)
			if tname and not privs.fly and privs.interact then
				if tname.spawn and tname.spawn.z * pos.z <= 0 then -- If Z coordinate of spawn and pos have opposite signs, product is negative
					minetest.chat_send_player(name, "Match hasn't started yet!")
					ctf.move_to_spawn(name)
				end
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
