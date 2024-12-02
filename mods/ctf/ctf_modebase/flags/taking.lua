local function drop_flags(player, pteam)
	local pname = player:get_player_name()
	local flagteams = ctf_modebase.taken_flags[pname]
	if not flagteams then return end

	for _, flagteam in ipairs(flagteams) do
		ctf_modebase.flag_taken[flagteam] = nil

		local fpos = vector.offset(ctf_map.current_map.teams[flagteam].flag_pos, 0, 1, 0)

		minetest.load_area(fpos)
		local node = minetest.get_node(fpos)

		if node.name == "ctf_modebase:flag_captured_top" then
			node.name = "ctf_modebase:flag_top_" .. flagteam
			minetest.set_node(fpos, node)
		else
			minetest.log("error", string.format("[ctf_flags] Unable to return flag node=%s, pos=%s",
				node.name, vector.to_string(fpos))
			)
		end
	end

	if player_api.players[pname] then
		player_api.set_texture(player, 2, "blank.png")
	end

	ctf_modebase.taken_flags[pname] = nil

	ctf_modebase.skip_vote.on_flag_drop(#flagteams)
	ctf_modebase:get_current_mode().on_flag_drop(player, flagteams, pteam)
end

function ctf_modebase.drop_flags(player)
	drop_flags(player, ctf_teams.get(player))
end

function ctf_modebase.flag_on_punch(puncher, nodepos, node)
	local pname = puncher:get_player_name()
	local pteam = ctf_teams.get(pname)

	if not pteam then
		hud_events.new(puncher, {
			quick = true,
			text = "You're not in a team, you can't take that flag!",
			color = "warning",
		})
		return
	end

	local target_team = node.name:sub(node.name:find("top_") + 4)

	if pteam ~= target_team then
		if ctf_modebase.flag_captured[pteam] then
			hud_events.new(puncher, {
				quick = true,
				text = "You can't take that flag. Your team's flag was captured!",
				color = "warning",
			})
			return
		end

		local result = ctf_modebase:get_current_mode().can_take_flag(puncher, target_team)
		if result then
			hud_events.new(puncher, {
				quick = true,
				text = result,
				color = "warning",
			})
			return
		end

		if not ctf_modebase.match_started then return end

		if not ctf_modebase.taken_flags[pname] then
			ctf_modebase.taken_flags[pname] = {}
		end
		table.insert(ctf_modebase.taken_flags[pname], target_team)
		ctf_modebase.flag_taken[target_team] = {p=pname, t=pteam}

		player_api.set_texture(puncher, 2,
			"default_wood.png^([combine:16x16:4,0=wool_white.png^[colorize:"..ctf_teams.team[target_team].color..":200)"
		)

		ctf_modebase.skip_vote.on_flag_take()
		ctf_modebase:get_current_mode().on_flag_take(puncher, target_team)

		RunCallbacks(ctf_api.registered_on_flag_take, puncher, target_team)

		minetest.set_node(nodepos, {name = "ctf_modebase:flag_captured_top", param2 = node.param2})
	else
		local flagteams = ctf_modebase.taken_flags[pname]
		if not ctf_modebase.taken_flags[pname] then
			hud_events.new(puncher, {
				quick = true,
				text = "That's your flag!",
				color = "warning",
			})
		else
			ctf_modebase.taken_flags[pname] = nil

			for _, flagteam in ipairs(flagteams) do
				ctf_modebase.flag_taken[flagteam] = nil
				ctf_modebase.flag_captured[flagteam] = true
			end

			player_api.set_texture(puncher, 2, "blank.png")

			ctf_modebase.on_flag_capture(puncher, flagteams)

			ctf_modebase.skip_vote.on_flag_capture(#flagteams)
			ctf_modebase:get_current_mode().on_flag_capture(puncher, flagteams)
		end
	end
end

ctf_api.register_on_match_end(function()
	for pname in pairs(ctf_modebase.taken_flags) do
		player_api.set_texture(minetest.get_player_by_name(pname), 2, "blank.png")
	end

	ctf_modebase.taken_flags = {}
	ctf_modebase.flag_taken = {}
	ctf_modebase.flag_captured = {}
end)

ctf_teams.register_on_allocplayer(function(player, new_team, old_team)
	if ctf_modebase.taken_flags[player:get_player_name()] then
		drop_flags(player, old_team)
	else
		ctf_modebase.flag_huds.update_player(player)
	end
end)

minetest.register_on_dieplayer(function(player)
	ctf_modebase.drop_flags(player)
end)

minetest.register_on_leaveplayer(function(player)
	ctf_modebase.drop_flags(player)
end)
