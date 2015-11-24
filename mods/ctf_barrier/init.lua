minetest.register_node("ctf_barrier:ind_glass", {
	description = "You cheater you!",
	drawtype = "glasslike_framed_optional",
	tiles = {"default_glass.png", "default_glass_detail.png"},
	inventory_image = minetest.inventorycube("default_glass.png"),
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = true,
	groups = {immortal = 1},
	sounds = default.node_sound_glass_defaults()
})
local lim = ctf.setting("match.map_reset_limit")
local c_glass  = minetest.get_content_id("ctf_barrier:ind_glass")
local c_stone  = minetest.get_content_id("ctf_flag:ind_base")
local c_air  = minetest.get_content_id("air")
local r = tonumber(minetest.setting_get("barrier"))
minetest.register_on_generated(function(minp, maxp, seed)
	if not ((minp.x < -r and maxp.x > -r)
			or (minp.x < r and maxp.x > r)
			or (minp.y < -r and maxp.x > -r)
			or (minp.y < r and maxp.x > r)
			or (minp.z < -r and maxp.z > -r)
			or (minp.z < r and maxp.z > r)) then
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
	local dist = 3

	-- Left
	if minp.x < -r and maxp.x > -r then
		local x = -r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	-- Right
	if minp.x < r and maxp.x > r then
		local x = r
		for z = minp.z, maxp.z do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	-- Front
	if minp.z < -r and maxp.z > -r then
		local z = -r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	-- Back
	if minp.z < r and maxp.z > r then
		local z = r
		for x = minp.x, maxp.x do
			for y = minp.y, maxp.y do
				local vi = a:index(x, y, z)
				if data[vi] == c_air then
					data[vi] = c_glass
				else
					data[vi] = c_stone
				end
			end
		end
	end

	vm:set_data(data)
	vm:write_to_map(data)
end)
