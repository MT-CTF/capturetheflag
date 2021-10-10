--
--- Team set/get
--

---@param player string | ObjectRef
---@param teamname string | nil
function ctf_teams.set(player, teamname)
	player = PlayerName(player)

	if not teamname then
		ctf_teams.remembered_player[player] = nil
		ctf_teams.player_team[player] = nil
		return
	end

	assert(type(teamname) == "string")
	if not (ctf_teams.player_team[player] and ctf_teams.player_team[player].locked) then
		ctf_teams.player_team[player] = {
			name = teamname,
		}

		ctf_teams.remembered_player[player] = teamname

		RunCallbacks(ctf_teams.registered_on_allocplayer, PlayerObj(player), teamname)

		return true
	end
end

---@param player string | ObjectRef
---@return boolean | string
function ctf_teams.get(player)
	player = PlayerName(player)

	if ctf_teams.player_team[player] then
		return ctf_teams.player_team[player].name
	end

	return false
end


---@param teamname string
---@return table
--- Returns a list of all players in the team 'teamname'
function ctf_teams.get_team(teamname)
	local out = {}

	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local team = ctf_teams.get(pname)

		if team and team == teamname then
			table.insert(out, pname)
		end
	end

	return out
end

---@return table
--- Returns a table where a key is team name and a value is a list of all players in the team
function ctf_teams.get_teams()
	local out = {}

	for _, player in pairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		local team = ctf_teams.get(pname)

		if team then
			if not out[team] then
				out[team] = {}
			end

			table.insert(out[team], pname)
		end
	end

	return out
end

--
--- Allocation
--

local tpos = 1
function ctf_teams.default_allocate_player(player)
	if #ctf_teams.current_team_list <= 0 then return end -- No teams initialized yet
	player = PlayerName(player)

	if not ctf_teams.remembered_player[player] then
		ctf_teams.set(player, ctf_teams.current_team_list[tpos])

		if tpos >= #ctf_teams.current_team_list then
			tpos = 1
		else
			tpos = tpos + 1
		end
	else
		ctf_teams.set(player, ctf_teams.remembered_player[player])
	end
end
ctf_teams.allocate_player = ctf_teams.default_allocate_player

function ctf_teams.dealloc_player(player)
	RunCallbacks(ctf_teams.registered_on_deallocplayer, PlayerObj(player), ctf_teams.get(player))

	ctf_teams.set(player, nil)
end

---@param teams table
-- Should be called at match start
function ctf_teams.allocate_teams(teams)
	local players = minetest.get_connected_players()
	ctf_teams.current_team_list = {}
	ctf_teams.remembered_player = {}
	tpos = 1

	for teamname, def in pairs(teams) do
		table.insert(ctf_teams.current_team_list, teamname)
	end

	table.shuffle(players)
	for _, player in ipairs(players) do
		ctf_teams.allocate_player(player)
	end
end

--
--- Other
--

---@param teamname string Name of team
---@return boolean | table,table
--- Returns 'false' if there is no current map.
---
--- Example usage: `pos1, pos2 = ctf_teams.get_team_territory("red")`
function ctf_teams.get_team_territory(teamname)
	local current_map = ctf_map.current_map
	if not current_map then return false end

	return current_map.teams[teamname].pos1, current_map.teams[teamname].pos2
end

---@param teamname string Name of team
---@param message string message to send
--- Like `minetest.chat_send_player()` but sends to all members of the given team
function ctf_teams.chat_send_team(teamname, message)
	assert(teamname and message, "Incorrect usage of chat_send_team()")
	local members = ctf_teams.get_team(teamname)

	for _, player in pairs(members) do
		minetest.chat_send_player(player, message)
	end
end
