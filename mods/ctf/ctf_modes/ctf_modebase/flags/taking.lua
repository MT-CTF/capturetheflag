ctf_modebase.register_on_new_match(function(mapdef, old_mapdef)
	ctf_modebase.taken_flags = {}
	ctf_modebase.flag_taken = {}
	ctf_modebase.flag_captured = {}
end)

function ctf_modebase.drop_flags(pname)
	local flagteams = ctf_modebase.taken_flags[pname]
	if not flagteams then return end

	for _, flagteam in pairs(flagteams) do
		ctf_modebase.flag_taken[flagteam] = nil

		local fpos = vector.offset(ctf_map.current_map.teams[flagteam].flag_pos, 0, 1, 0)

		local node = minetest.get_node(fpos)

		if node.name == "ctf_modebase:flag_captured_top" or node.name == "ignore" then
			node.name = "ctf_modebase:flag_top_" .. flagteam
			minetest.set_node(fpos, node)
		else
			ctf_core.error("ctf_modebase:flag_taking", "Failed to return flag to its base!")
		end
	end

	ctf_modebase.taken_flags[pname] = nil

	ctf_modebase:get_current_mode().on_flag_drop(pname, flagteams)
end

function ctf_modebase.flag_on_punch(puncher, nodepos, node)
	local pname = PlayerName(puncher)
	local pteam = ctf_teams.get(pname)

	if not pteam then
		minetest.chat_send_player(pname, "You're not in a team, you can't take that flag!")
		return
	end

	local target_team = node.name:sub(node.name:find("top_") + 4)

	if pteam ~= target_team then
		if ctf_modebase.flag_captured[pteam] then
			minetest.chat_send_player(pname, "You can't take that flag. Your team's flag was captured!")
			return
		end

		local result = ctf_modebase:get_current_mode().can_take_flag(pname, target_team)
		if result then
			minetest.chat_send_player(pname, "You can't take that flag. Reason: " .. result)
			return
		end

		if not ctf_modebase.taken_flags[pname] then
			ctf_modebase.taken_flags[pname] = {}
		end
		table.insert(ctf_modebase.taken_flags[pname], target_team)
		ctf_modebase.flag_taken[target_team] = {p=pname, t=pteam}

		ctf_modebase:get_current_mode().on_flag_take(pname, target_team)

		minetest.set_node(nodepos, {name = "ctf_modebase:flag_captured_top", param2 = node.param2})
	else
		local flagteams = ctf_modebase.taken_flags[pname]
		if not ctf_modebase.taken_flags[pname] then
			minetest.chat_send_player(pname, "That's your flag!")
		else
			ctf_modebase.taken_flags[pname] = nil

			for _, flagteam in pairs(flagteams) do
				ctf_modebase.flag_taken[flagteam] = nil
				ctf_modebase.flag_captured[flagteam] = true
			end

			ctf_modebase:get_current_mode().on_flag_capture(pname, flagteams)
		end
	end
end

function ctf_modebase.on_flag_rightclick(...)
	if ctf_modebase.current_mode then
		ctf_modebase:get_current_mode().on_flag_rightclick(...)
	end
end

ctf_teams.register_on_allocplayer(function(player)
	ctf_modebase.drop_flags(player:get_player_name())
end)

minetest.register_on_dieplayer(function(player)
	ctf_modebase.drop_flags(player:get_player_name())
end)

minetest.register_on_leaveplayer(function(player)
	ctf_modebase.drop_flags(player:get_player_name())
end)
