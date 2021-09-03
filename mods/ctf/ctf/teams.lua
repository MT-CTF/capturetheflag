-- Get or add a team
function ctf.team(name)
	if name == nil then
		return nil
	end
	if type(name) == "table" then
		if not name.add_team then
			ctf.error("team", "Invalid table given to ctf.team")
			return
		end

		return ctf.create_team(name.name, name)
	else
		local team = ctf.teams[name]
		if team then
			if not team.data or not team.players then
				ctf.warning("team", "Assertion failed, data{} or players{} not " ..
						"found in team{}")
			end
			return team
		else
			if name and name:trim() ~= "" then
				ctf.warning("team", dump(name) .. " does not exist!")
			end
			return nil
		end
	end
end

function ctf.create_team(name, data)
	ctf.log("team", "Creating team " .. name)

	ctf.teams[name] = {
		data = data,
		spawn = nil,
		players = {}
	}

	for i = 1, #ctf.registered_on_new_team do
		ctf.registered_on_new_team[i](ctf.teams[name])
	end

	return ctf.teams[name]
end

function ctf.remove_team(name)
	local team = ctf.team(name)
	if team then
		for username, player in pairs(team.players) do
			player.team = nil
		end
		for i = 1, #team.flags do
			team.flags[i].team = nil
		end
		ctf.teams[name] = nil
		return true
	else
		return false
	end
end

function ctf.list_teams(name)
	minetest.chat_send_player(name, "Teams:")
	for tname, team in pairs(ctf.teams) do
		if team and team.players then
			local numPlayers = ctf.count_players_in_team(tname)
			local details = numPlayers .. " members"
			if team.flags then
				local numFlags = 0
				for flagid, flag in pairs(team.flags) do
					numFlags = numFlags + 1
				end
				details = details .. ", " .. numFlags .. " flags"
			end

			minetest.chat_send_player(name, ">> " .. tname ..
					" (" .. details .. ")")
		end
	end
end

-- Count number of players in a team
function ctf.count_players_in_team(team)
	local count = 0
	for name, player in pairs(ctf.team(team).players) do
		count = count + 1
	end
	return count
end

function ctf.new_player(name)
	if name then
		ctf.players[name] = {
			name = name
		}
	else
		ctf.error("team", "Can't create a blank player")
		ctf.log("team", debug.traceback())
	end
end

-- get a player
function ctf.player(name)
	if not ctf.players[name] then
		ctf.new_player(name)
	end
	return ctf.players[name]
end

function ctf.player_or_nil(name)
	return ctf.players[name]
end

function ctf.chat_send_team(team, msg)
	if type(team) == "string" then
		team = ctf.team(team)
	end

	if not team then return end

	for pname, _ in pairs(team.players) do
		minetest.chat_send_player(pname, msg)
	end
end

function ctf.remove_player(name)
	ctf.log("team", "Removing player ".. dump(name))
	local player = ctf.players[name]
	if player then
		local team = ctf.team(player.team)
		if team then
			team.players[name] = nil
		end
		ctf.players[name] = nil
		return true
	else
		return false
	end
end

ctf.registered_on_join_team = {}
function ctf.register_on_join_team(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_join_team, func)
end

ctf.player_last_team = {}
local first_alloc = {}

-- Player joins team
-- Called by /join, /team join or auto allocate.
function ctf.join(name, team, force, by)
	if not name or name == "" or not team or team == "" then
		ctf.log("team", "Missing parameters to ctf.join")
		return false
	end

	local player = ctf.player(name)

	if not force and not ctf.setting("players_can_change_team")
			and player.team and ctf.team(player.team) then
		if by then
			if by == name then
				ctf.action("teams", name .. " attempted to change to " .. team)
				minetest.chat_send_player(by, "You are not allowed to switch teams, traitor!")
			else
				ctf.action("teams", by .. " attempted to change " .. name .. " to " .. team)
				minetest.chat_send_player(by, "Failed to add " .. name .. " to " .. team ..
						" as players_can_change_team = false")
			end
		else
			ctf.log("teams", "failed to add " .. name .. " to " .. team ..
					" as players_can_change_team = false")
		end
		return false
	end

	local team_data = ctf.team(team)
	if not team_data then
		if by then
			minetest.chat_send_player(by, "No such team.")
			ctf.list_teams(by)
			if by == name then
				minetest.log("action", by .. " tried to move " .. name .. " to " .. team .. ", which doesn't exist")
			else
				minetest.log("action", name .. " attempted to join " .. team .. ", which doesn't exist")
			end
		else
			ctf.log("teams", "failed to add " .. name .. " to " .. team ..
					" as team does not exist")
		end
		return false
	end

	if player.team then
		local oldteam = ctf.team(player.team)
		if oldteam then
			oldteam.players[player.name] = nil
		end
	end

	local prevteam = player.team
	player.team = team
	team_data.players[player.name] = player
	ctf.player_last_team[name] = team

	local tcolor = ctf_colors.get_color(player).css

	local join_msg
	if first_alloc[name] then
		join_msg = minetest.colorize(tcolor, name) .. " has joined the game" ..
			" (team " .. minetest.colorize(tcolor, team) .. ")"
		first_alloc[name] = false
	else
		join_msg = minetest.colorize(tcolor, name) ..
			" has joined team " .. minetest.colorize(tcolor, team)
	end

	minetest.chat_send_all("*** " .. join_msg)
	minetest.log("action", name .. " joined team " .. team)

	for i = 1, #ctf.registered_on_join_team do
		ctf.registered_on_join_team[i](name, team, prevteam)
	end
	return true
end

-- Cleans up the player lists
function ctf.clean_player_lists()
	ctf.log("utils", "Cleaning player lists")
	for _, str in pairs(ctf.players) do
		if str and str.team and ctf.teams[str.team] then
			ctf.log("utils", " - Adding player "..str.name.." to team "..str.team)
			ctf.teams[str.team].players[str.name] = str
		else
			ctf.log("utils", " - Skipping player "..str.name)
		end
	end
end

-- Automatic Allocation
function ctf.autoalloc(name, alloc_mode)
	alloc_mode = alloc_mode or ctf.setting("allocate_mode")
	if alloc_mode == 0 then
		return
	end
	local last_team = ctf.player_last_team[name]
	if last_team then
		return last_team
	end

	local max_players = ctf.setting("maximum_in_team")

	local mtot = false -- more than one team
	if next(ctf.teams) then
		mtot = true
	end

	if not mtot then
		ctf.error("autoalloc", "No teams to allocate " .. name .. " to!")
		return
	end

	if alloc_mode == 1 then
		local index = {}

		for key, team in pairs(ctf.teams) do
			if team.data.allow_joins ~= false and (max_players == -1 or
					ctf.count_players_in_team(key) < max_players) then
				table.insert(index, key)
			end
		end

		if #index == 0 then
			ctf.error("autoalloc", "No teams to join!")
		else
			return index[math.random(1, #index)]
		end
	elseif alloc_mode == 2 then
		local one = nil
		local one_count = -1
		local two = nil
		local two_count = -1
		for key, team in pairs(ctf.teams) do
			local count = ctf.count_players_in_team(key)
			if team.data.allow_joins ~= false and
					(max_players == -1 or count < max_players) then
				if count > one_count then
					two = one
					two_count = one_count
					one = key
					one_count = count
				end

				if count > two_count then
					two = key
					two_count = count
				end
			end
		end

		if not one and not two then
			ctf.error("autoalloc", "No teams to join!")
		elseif one and two then
			if math.random() > 0.5 then
				return one
			else
				return two
			end
		else
			if one then
				return one
			else
				return two
			end
		end
	elseif alloc_mode == 3 then
		local smallest = nil
		local smallest_count = 1000
		for key, team in pairs(ctf.teams) do
			local count = ctf.count_players_in_team(key)
			if team.data.allow_joins ~= false and
					(not smallest or count < smallest_count) then
				smallest = key
				smallest_count = count
			end
		end

		if not smallest then
			ctf.error("autoalloc", "No teams to join!")
		else
			return smallest
		end
	elseif alloc_mode == 4 then
		return ctf.custom_alloc(name)
	else
		ctf.error("autoalloc",
				"Unknown allocation mode: " .. alloc_mode)
	end
end

-- Custom team allocation function. Throws error
-- if unimplemented, and autoalloc mode 4 is selected
function ctf.custom_alloc()
	error("Allocation mode set to custom while " ..
			"ctf.custom_alloc hasn't been overridden!")
end

-- updates the spawn position for a team
function ctf.get_spawn(team)
	if ctf.team(team) then
		local spawn = ctf.team(team).spawn
		if not spawn then
			return nil
		end
		return vector.add(spawn, minetest.string_to_pos(ctf.setting("spawn_offset")))
	else
		return nil
	end
end

function ctf.move_to_spawn(name)
	local player = minetest.get_player_by_name(name)
	local tplayer = ctf.player(name)
	if ctf.team(tplayer.team) then
		local spawn = ctf.get_spawn(tplayer.team)
		if spawn then
			player:move_to(spawn, false)
			return true
		end
	end
	return false
end

minetest.register_on_respawnplayer(function(player)
	if not player then
		return false
	end

	return ctf.move_to_spawn(player:get_player_name())
end)

function ctf.get_territory_owner(pos)
	local largest = nil
	local largest_weight = 0
	for i = 1, #ctf.registered_on_territory_query do
		local team, weight = ctf.registered_on_territory_query[i](pos)
		if team and weight then
			if weight == -1 then
				return team
			end
			if weight > largest_weight then
				largest = team
				largest_weight = weight
			end
		end
	end
	return largest
end

minetest.register_on_newplayer(function(player)
	local name = player:get_player_name()
	local team = ctf.autoalloc(name)
	if team then
		ctf.log("autoalloc", name .. " was allocated to " .. team)
		ctf.join(name, team)
		ctf.move_to_spawn(player:get_player_name())
	end
end)

minetest.after(0, function()
	if ctf.setting("autoalloc_on_joinplayer") then
		-- Disable engine join messages if autoalloc_on_joinplayer is enabled
		function minetest.send_join_message() end
	end
end)

minetest.register_on_joinplayer(function(player)
	if not ctf.setting("autoalloc_on_joinplayer") then
		return
	end

	local name = player:get_player_name()
	if ctf.team(ctf.player(name).team) then
		minetest.log("action", name.." already in team so not allocating")
		return
	end

	first_alloc[name] = true
	local team = ctf.autoalloc(name)
	if team then
		ctf.log("autoalloc", name .. " was allocated to " .. team)
		ctf.join(name, team)
		ctf.move_to_spawn(player:get_player_name())
	end
end)

-- Disable friendly fire.
ctf.registered_on_killedplayer = {}
function ctf.register_on_killedplayer(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_killedplayer, func)
end

function ctf.can_attack(player, hitter, time_from_last_punch, tool_capabilities, dir, damage, ...)
	return true
end

function ctf.get_damage_modifier(player, tool_capabilities)
	return 0
end

ctf.registered_on_attack = {}
function ctf.register_on_attack(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf.registered_on_attack, func)
end

minetest.register_on_punchplayer(function(player, hitter,
		time_from_last_punch, tool_capabilities, dir, orig_damage, ...)
	if player and hitter then
		local pname = player:get_player_name()
		local hname = hitter:get_player_name()

		local to = ctf.player(pname)
		local from = ctf.player(hname)

		if to.team == from.team and to.team ~= "" and
				to.team ~= nil and to.name ~= from.name then
			hud_event.new(hname, {
				name  = "ctf:friendly_fire",
				color = "warning",
				value = pname .. " is on your team!",
			})
			if not ctf.setting("friendly_fire") then
				return true
			end
		end

		if ctf.can_attack(player, hitter, time_from_last_punch, tool_capabilities,
			dir, orig_damage, ...) == false
		then
			return true
		end

		local hp = player:get_hp()
		if hp <= 0 then
			return true
		end

		if tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.fleshy then
			local modifier = ctf.get_damage_modifier(hitter, tool_capabilities)
			tool_capabilities.damage_groups.fleshy = math.max(1, tool_capabilities.damage_groups.fleshy + modifier)
		end

		local damage = minetest.get_hit_params(player:get_armor_groups(), tool_capabilities, time_from_last_punch).hp
		damage = math.min(damage, hp)

		for i = 1, #ctf.registered_on_attack do
			ctf.registered_on_attack[i](
				player, hitter, time_from_last_punch,
				tool_capabilities, dir, damage, ...
			)
		end

		if hp <= damage then
			for i = 1, #ctf.registered_on_killedplayer do
				ctf.registered_on_killedplayer[i](pname, hname,	tool_capabilities)
			end
		end

		player:set_hp(hp - damage)
		return true
	end
end)
