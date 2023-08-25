local getpos_players = {}
function ctf_map.get_pos_from_player(name, amount, donefunc)
	getpos_players[name] = {amount = amount, func = donefunc, positions = {}}

	if amount == 2 and minetest.get_modpath("worldedit") then
		worldedit.pos1[name] = nil
		worldedit.pos2[name] = nil
		worldedit.marker_update(name)

		getpos_players[name].place_markers = true
	end

	minetest.chat_send_player(name, minetest.colorize(ctf_map.CHAT_COLOR,
			"Please punch a node or run `/ctf_map here` to supply coordinates"))
end

local function add_position(player, pos)
	pos = vector.round(pos)

	table.insert(getpos_players[player].positions, pos)
	minetest.chat_send_player(player, minetest.colorize(ctf_map.CHAT_COLOR,
			"Got pos "..minetest.pos_to_string(pos, 1)))

	if getpos_players[player].place_markers then
		if #getpos_players[player].positions == 1 then
			worldedit.pos1[player] = pos
			worldedit.mark_pos1(player)
		elseif #getpos_players[player].positions == 2 then
			worldedit.pos2[player] = pos
			worldedit.mark_pos2(player)
		end
	end

	if getpos_players[player].amount > 1 then
		getpos_players[player].amount = getpos_players[player].amount - 1
	else
		minetest.chat_send_player(player, minetest.colorize(ctf_map.CHAT_COLOR,
				"Done getting positions!"))
		getpos_players[player].func(player, getpos_players[player].positions)
		getpos_players[player] = nil
	end
end

ctf_map.register_map_command("here", function(name, params)
	local player = PlayerObj(name)

	if player then
		if getpos_players[name] then
			add_position(name, player:get_pos())
			return true
		else
			return false, "You aren't doing anything that requires coordinates"
		end
	end
end)

local function fixborder(player)
	minetest.chat_send_player(player, minetest.colorize(ctf_map.CHAT_COLOR,
		"Converting barriers. This will take a few seconds..."))

	-- From map_functions.lua
	local pos1 = getpos_players[player].positions[1]
	local pos2 = getpos_players[player].positions[2]

	local vm = VoxelManip()
	pos1, pos2 = vm:read_from_map(pos1, pos2)

	local data = vm:get_data()

	ctf_gui.old_show_formspec(player, "ctf_map:loading", {
		size = {x = 8, y = 4},
		title = "Capture The Flag Map Editor",
		description = "Converting barriers. This will take a few seconds..."
	})

	minetest.handle_async(function(d, p1, p2, barrier_nodes, t)
		local mod = {} -- All its contents will be recreated in the loop
		local Nx = p2.x - p1.x + 1
		local Ny = p2.y - p1.y + 1
		local ID_IGNORE = minetest.CONTENT_IGNORE
		local ID_WATER = minetest.get_content_id("default:water_source")
		local ID_LAVA = minetest.get_content_id("default:lava_source")
		local ID_OLD_BARRIER = minetest.get_content_id("ctf_map:ind_glass_red")
		local ID_WATER_BARRIER = minetest.get_content_id("ctf_map:ind_water")
		local ID_LAVA_BARRIER = minetest.get_content_id("ctf_map:ind_lava")

		for z = p1.z, p2.z do
			for y = p1.y, p2.y do
				for x = p1.x, p2.x do
					local vi = (z - p1.z) * Ny * Nx + (y - p1.y) * Nx + (x - p1.x) + 1
					local done = false

					if d[vi] == ID_OLD_BARRIER then
						local check_pos = { -- Check for water and lava
							((z + 1) - p1.z) * Ny * Nx + (y - p1.y) * Nx + (x - p1.x) + 1,
							((z - 1) - p1.z) * Ny * Nx + (y - p1.y) * Nx + (x - p1.x) + 1,
							(z - p1.z) * Ny * Nx + (y - p1.y) * Nx + ((x + 1) - p1.x) + 1,
							(z - p1.z) * Ny * Nx + (y - p1.y) * Nx + ((x - 1) - p1.x) + 1,
						}
						local water_count = 0
						local lava_count = 0
						for _, check_vi in ipairs(check_pos) do
							-- It is rare than water will be appearing with lava
							-- But if that happens, water takes the priority.
							if d[check_vi] == ID_WATER then
								water_count = water_count + 1
								if water_count >= 2 then
									mod[vi] = ID_WATER_BARRIER
									done = true
									break
								end
							elseif d[check_vi] == ID_LAVA then
								lava_count = lava_count + 1
								if lava_count >= 2 then
									mod[vi] = ID_LAVA_BARRIER
									done = true
									break
								end
							end
						end
					end

					if not done then
						mod[vi] = ID_IGNORE
					end
				end
			end
		end

		return mod
	end, function(d)
		vm:set_data(d)
		vm:update_liquids()
		vm:write_to_map(false)
		minetest.close_formspec(player, "ctf_map:loading")
		minetest.chat_send_player(player, minetest.colorize(ctf_map.CHAT_COLOR,
			"Done barrier convertion. " ..
			"Please check if there are any water or lava barriers not being replaced."))
	end, data, pos1, pos2, ctf_map.barrier_nodes)
	return true, "Border is being fixed. Please wait..."
end

ctf_map.register_map_command("fixborder", function(name, params)
	ctf_map.get_pos_from_player(name, 2, function()
		fixborder(name)
	end)
	return true
end)

local function setborder(player)
	minetest.chat_send_player(player, minetest.colorize(ctf_map.CHAT_COLOR,
		"Placing barriers. This will take a few seconds..."))

	-- From map_functions.lua
	local pos1 = getpos_players[player].positions[1]
	local pos2 = getpos_players[player].positions[2]
	pos1, pos2 = vector.sort(pos1, pos2)


	local vm = VoxelManip()
	local vpos1, vpos2 = vm:read_from_map(pos1, pos2)

	local data = vm:get_data()

	ctf_gui.old_show_formspec(player, "ctf_map:loading", {
		size = {x = 8, y = 4},
		title = "Capture The Flag Map Editor",
		description = "Placing barriers. This will take a few seconds..."
	})

	minetest.handle_async(function(d, vp1, vp2, p1, p2, barrier_nodes_reverse)
		local Nx = vp2.x - vp1.x + 1
		local Ny = vp2.y - vp1.y + 1
		local ID_IGNORE = minetest.CONTENT_IGNORE

		for z = vp1.z, vp2.z do
			for y = vp1.y, vp2.y do
				for x = vp1.x, vp2.x do
					local vi = (z - vp1.z) * Ny * Nx + (y - vp1.y) * Nx + (x - vp1.x) + 1

					if vector.in_area(vector.new(x,y,z), p1, p2) then
						d[vi] = barrier_nodes_reverse[d[vi]] or ID_IGNORE
					else
						d[vi] = ID_IGNORE
					end
				end
			end
		end

		return d
	end, function(d)
		vm:set_data(d)
		vm:update_liquids()
		vm:write_to_map(false)
		minetest.close_formspec(player, "ctf_map:loading")
		minetest.chat_send_player(player, minetest.colorize(ctf_map.CHAT_COLOR,
			"Barrier placed."))
	end, data, vpos1, vpos2, pos1, pos2, ctf_map.barrier_nodes_reverse)
end

ctf_map.register_map_command("setborder", function(name, params)
	ctf_map.get_pos_from_player(name, 2, function()
		setborder(name)
	end)
	return true, minetest.colorize(ctf_map.CHAT_COLOR,
		"Select two corners of where the barrier should cover.")
end)

minetest.register_on_punchnode(function(pos, _, puncher)
	puncher = PlayerName(puncher)

	if getpos_players[puncher] then
		add_position(puncher, pos)
	end
end)

minetest.register_on_leaveplayer(function(player)
	getpos_players[PlayerName(player)] = nil
end)
