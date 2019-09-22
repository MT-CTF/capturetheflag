-- mods/ctf/ctf_pos/init.lua

local teams = {}
--[[
	Team-to-player mapping
	----------------------

	teams = {
		team1 = {
			name1, name2, name3
		},
		team2 = {
			name4, name5, name6
		}
	}
]]

local players = {}
--[[
	Player-to-pos/player-to-team mapping
	------------------------------------

	players = {
		name1 = {
			pos  = {x =, y =, z =},
			team = team_name
		},
		name2 = {
			pos  = {x =, y =, z =},
			team = team_name
		}
	}
]]

local UPDATE_INTERVAL = 1
local hud = hudkit()

ctf.register_on_new_team(function(team)
	teams[team.data.name] = {
		players = {}
	}
end)

ctf.register_on_join_team(function(name, tname)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end

	-- Initialize team color
	if not teams[tname].color then
		teams[tname].color = ctf_colors.get_color(ctf.player(name)).hex
	end

	-- If player-to-team mapping already exists, remove old entry
	local old_team = players[name] and players[name].team
	if old_team then
		teams[old_team].players[table.indexof(teams[old_team].players, name)] = nil
	end

	-- Initialize player-to-pos mapping
	players[name] = {
		team = tname,
		pos  = player:get_pos()
	}

	-- Insert player name into end of table
	local idx = #teams[tname].players
	teams[tname].players[idx + 1] = name
end)

-- Update waypoint to target player
local function update_waypoint(name, target, pos)
	local player = minetest.get_player_by_name(name)
	if not player then
		-- If player doesn't exist, do nothing. The globalstep
		-- below will take care of player entry cleanups
		return
	end

	if hud:exists(player, target) then
		hud:change(player, target, "world_pos", pos)
	else
		hud:add(player, target, {
			hud_elem_type = "waypoint",
			name          = target,
			number        = teams[players[name].team].color,
			world_pos     = pos
		})
	end
end

-- Invoke update_waypoint for all players in a team, provided
-- a target player, except for the target player themselves
local function update_team(tname, target, pos)
	for _, pname in pairs(teams[tname].players) do
		if pname ~= target then
			update_waypoint(pname, target, pos)
		end
	end
end

local timer = UPDATE_INTERVAL
minetest.register_globalstep(function(dtime)
	timer = timer - dtime
	if timer > 0 then
		return
	end

	timer = UPDATE_INTERVAL

	-- Iterate over all existing players by team
	for tname, team in pairs(teams) do
		for _, pname in pairs(team.players) do
			-- If player exists, update corresponding waypoint
			-- for all team-mates. Else, remove player entry
			local player = minetest.get_player_by_name(pname)
			if player then
				update_team(tname, pname, player:get_pos())
			else
				players[pname] = nil
				teams[tname].players[pname] = nil
			end
		end
	end
end)
