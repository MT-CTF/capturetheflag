function ctf_map.place_base(color, pos)
	-- Spawn base
	for x = pos.x - 2, pos.x + 2 do
	for z = pos.z - 2, pos.z + 2 do
		minetest.set_node({ x = x, y = pos.y - 1, z = z },
			{ name = ctf_map.map.base_node or "ctf_map:cobble" })
	end
	end

	-- Check for trees
	for y = pos.y,     pos.y + 3 do
	for x = pos.x - 3, pos.x + 3 do
	for z = pos.z - 3, pos.z + 3 do
		local pos2 = { x = x, y = y, z = z }
		if minetest.get_node(pos2).name == "default:tree" then
			minetest.set_node(pos2, { name = "air" })
		end
	end
	end
	end

	-- Spawn chest
	local chest = { name = "ctf_map:chest_" .. color }
	local dz = 2
	if pos.z < 0 then
		dz = -2
		chest.param2 = minetest.dir_to_facedir({ x = 0, y = 0, z = -1 })
	end
	local pos3 = {
		x = pos.x,
		y = pos.y,
		z = pos.z + dz
	}
	minetest.set_node(pos3, chest)
	local inv = minetest.get_meta(pos3):get_inventory()
	inv:add_item("main", ItemStack("default:cobble 99"))
	inv:add_item("main", ItemStack("default:cobble 99"))
	inv:add_item("main", ItemStack("default:cobble 99"))
	inv:add_item("main", ItemStack("default:wood 99"))
	inv:add_item("main", ItemStack("default:stick 30"))
	inv:add_item("main", ItemStack("default:glass 5"))
	inv:add_item("main", ItemStack("default:torch 10"))
end

-- Override ctf.get_spawn to implement random spawns
local old_spawn = ctf.get_spawn
function ctf.get_spawn(team)
	local spawn = old_spawn(team)
	if not spawn then
		return
	end

	return vector.add(spawn, {
		x = math.random(-1, 1),
		y = 0,
		z = math.random(-1, 1)
	})
end
