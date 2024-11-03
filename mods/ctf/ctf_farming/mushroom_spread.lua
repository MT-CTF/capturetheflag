local mushroom_globalstep_counter = 0.0
local MUSHROOM_COUNTER_THRESHOLD = 5.0

minetest.register_globalstep(function(dtime)
	if not ctf_map.current_map then
		return
	end
	mushroom_globalstep_counter = mushroom_globalstep_counter + dtime
	if mushroom_globalstep_counter < MUSHROOM_COUNTER_THRESHOLD then
		return
	end
	mushroom_globalstep_counter = 0.0
	local pos1 = ctf_map.current_map.pos1
	local pos2 = ctf_map.current_map.pos2
	local x = math.random(pos1.x, pos2.x)
	local y = math.random(pos1.y, pos2.y)
	local z = math.random(pos1.z, pos2.z)
	--[[
	-- Currently we split the map into 2 parts vertically and choose one of them randomly.
	-- This way, in most circumstances, either the underground will be chosen or the areas
	-- above ground. And in the case of latter, mushroom spread will happen somewhat
	-- useful to the players. However, perhaps a better idea would be having an optional y
	-- coordinate per map and to choose only from above this. This way we'll either
	-- have more mushrooms or the same amount of mushrooms but consuming less server time.
	-- --Farooq
	--]]
	local half_x = math.floor(math.abs(pos1.x - pos2.x) / 4)
	local half_y = math.floor(math.abs(pos1.y - pos2.y) / 2)
	local half_z = math.floor(math.abs(pos1.z - pos2.z) / 4)
	local positions = minetest.find_nodes_in_area_under_air(
		{ x = x - half_x, y  = y - half_y, z = z - half_z},
		{ x = x + half_x, y = y + half_y, z = z + half_z},
		"group:soil"
	)
	for _idx, position in ipairs(positions) do
		position = {
			x = position.x,
			y = position.y + 1,
			z = position.z
		}
		if minetest.get_node_light(position) <= 4 then
			local r = math.random()
			if r >= 0.5 then
				if r <= 0.7 then
					minetest.set_node(position, { name = "flowers:mushroom_brown" })
				else
					minetest.set_node(position, { name = "flowers:mushroom_red" })
				end
			end
		end
	end
end)
