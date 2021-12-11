local cmd = chatcmdbuilder.register("ctf_teams", {
	description = "Team management commands",
	params = "set <player> <team> | rset <match pattern> <team>",
	privs = {
		ctf_team_admin = true,
	}
})

cmd:sub("set :player:username :team", function(name, player, team)
	if minetest.get_player_by_name(player) then
		if table.indexof(ctf_teams.current_team_list, team) == -1 then
			return false, "Unable to find team " .. dump(team)
		end

		ctf_teams.set(player, team)

		return true, string.format("Allocated %s to team %s", player, team)
	else
		return false, "Unable to find player " .. dump(player)
	end
end)

cmd:sub("rset :pattern :team", function(name, pattern, team)
	if table.indexof(ctf_teams.current_team_list, team) == -1 then
		return false, "Unable to find team " .. dump(team)
	end

	local added = {}

	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()

		if pname:match(pattern) then
			ctf_teams.set(player, team)
			table.insert(added, pname)
		end
	end

	if #added >= 1 then
		return true, "Added the following players to team " .. team .. ": " .. table.concat(added, ", ")
	else
		return false, "No player names matched the given regex, or all players that matched were locked to a team"
	end
end)

local function get_team_players(team)
	local tcolor = ctf_teams.team[team].color
	local count = 0
	local str = ""

	for player in pairs(ctf_teams.online_players[team].players) do
		count = count + 1
		str = str .. player .. ", "
	end

	return string.format("Team %s has %d players: %s", minetest.colorize(tcolor, team), count, str:sub(1, -3))
end

minetest.register_chatcommand("team", {
	description = "Get team members for 'team' or on which team is 'player' in",
	params = "<team> | player <player>",
	func = function(name, param)
		local _, pos = param:find("^player +")
		if pos then
			local player = param:sub(pos + 1)
			local pteam = ctf_teams.get(player)

			if not pteam then
				return false, "No such player: " .. player
			end

			local tcolor = ctf_teams.team[pteam].color
			return true, string.format("Player %s is in team %s", player, minetest.colorize(tcolor, pteam))
		elseif param == "" then
			local str = ""
			for _, team in ipairs(ctf_teams.current_team_list) do
				str = str .. get_team_players(team) .. "\n"
			end
			return true, str:sub(1, -2)
		else
			if not ctf_teams.team[param] or table.indexof(ctf_teams.current_team_list, param) == -1 then
				return false, "No such team: " .. param
			end

			return true, get_team_players(param)
		end
	end,
})
