ctf_modebase.register_on_new_match(function(mapdef, old_mapdef)
	ctf_modebase.taken_flags = {}
	ctf_modebase.flag_taken = {}
	ctf_modebase.flag_captured = {}

	for tname in pairs(mapdef.teams) do
		ctf_modebase.flag_taken[tname] = false
	end
end)

function ctf_modebase.drop_flags(pname, capture)
	local flagteams = ctf_modebase.taken_flags[pname]

	if flagteams then
		for _, flagteam in pairs(flagteams) do
			ctf_modebase.flag_taken[flagteam] = false

			if capture then
				ctf_modebase.flag_captured[flagteam] = true
			else
				local fpos = vector.offset(ctf_map.current_map.teams[flagteam].flag_pos, 0, 1, 0)

				local node = minetest.get_node(fpos)

				if node.name == "ctf_modebase:flag_captured_top" or node.name == "ignore" then
					node.name = "ctf_modebase:flag_top_" .. flagteam
					minetest.set_node(fpos, node)
				else
					ctf_core.error("ctf_modebase:flag_taking", "Failed to return flag to its base!")
				end
			end
		end

		ctf_modebase.taken_flags[pname] = nil

		if not capture then
			RunCallbacks(ctf_modebase.registered_on_flag_drop, pname, flagteams)
		end
	end
end

function ctf_modebase.flag_on_punch(puncher, nodepos, node)
	local pname = PlayerName(puncher)

	if not ctf_teams.player_team[pname] then
		minetest.chat_send_player(pname, "You're not in a team, you can't take that flag!")
		return
	end

	local pteam = ctf_teams.player_team[pname].name
	local target_team = node.name:sub(node.name:find("top_") + 4)

	if pteam ~= target_team then
		if ctf_modebase.flag_captured[pteam] then
			minetest.chat_send_player(pname, "You can't take that flag. Your team's flag was captured!")
			return
		end

		if not ctf_modebase.taken_flags[pname] then
			ctf_modebase.taken_flags[pname] = {}
		end

		table.insert(ctf_modebase.taken_flags[pname], target_team)
		ctf_modebase.flag_taken[target_team] = pname

		local result = RunCallbacks(ctf_modebase.registered_on_flag_take, pname, target_team)

		if not result then
			minetest.set_node(nodepos, {name = "ctf_modebase:flag_captured_top", param2 = node.param2})
		elseif type(result) == "string" then
			table.remove(ctf_modebase.taken_flags[pname])
			ctf_modebase.flag_taken[target_team] = nil
			minetest.chat_send_player(pname, "You can't take that flag. Reason: "..result)
		end
	else
		if not ctf_modebase.taken_flags[pname] then
			minetest.chat_send_player(pname, "That's your flag!")
		else
			local result = RunCallbacks(ctf_modebase.registered_on_flag_capture, pname, ctf_modebase.taken_flags[pname])

			if type(result) == "string" then
				minetest.chat_send_player(pname, "You can't capture. Reason: "..result)
			else
				ctf_modebase.drop_flags(pname, true)
			end
		end
	end
end

function ctf_modebase.on_flag_rightclick(...)
	RunCallbacks(ctf_modebase.registered_on_flag_rightclick, ...)
end

minetest.register_on_dieplayer(function(player)
	ctf_modebase.drop_flags(player:get_player_name())
end)

minetest.register_on_leaveplayer(function(player)
	ctf_modebase.drop_flags(player:get_player_name())
end)
