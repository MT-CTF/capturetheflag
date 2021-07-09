local storage = minetest.get_mod_storage()
local data = minetest.parse_json(storage:get_string("locktoteam")) or {}
local S = minetest.get_translator()

-- Override autoalloc function to implement team-locking
local ctf_autoalloc = ctf.autoalloc
function ctf.autoalloc(name, alloc_mode)
	if data[name] then
		return data[name]
	end

	return ctf_autoalloc(name, alloc_mode)
end

ChatCmdBuilder.new("ctf_lock_to_team", function(cmd)
	cmd:sub(":name :team", function(name, pname, team)
		if team == "!" then
			data[pname] = nil
			storage:set_string("locktoteam", minetest.write_json(data))
			return true, S("Unlocked @1")
		else
			data[pname] = team
			storage:set_string("locktoteam", minetest.write_json(data))
			return true, S("Locked @1 to @2")
		end
	end)
end, {
	description = S("Lock a player to a team"),
	privs = {
		ctf_admin = true,
	}
})

-- Struct containing the name and score of the team with lowest cumulative score
local lowest = {}
--[[
	lowest = {
		team  =,
		score =
	}
]]

-- List of cumulative team scores indexed by team name
local scores = {}
--[[
	scores = {
		red = ,
		blue
	}
]]

local function update_lowest()
	-- Update lowest.score and lowest.team
	lowest = {}
	for tname, score in pairs(scores) do
		if tname == "red" or tname == "blue" then
			if not lowest.score or score <= lowest.score then
				lowest.score = score
				lowest.team  = tname
			end
		end
	end
end

local function calc_scores()
	-- Update the cumulative score of all teams
	for tname, team in pairs(ctf.teams) do
		local score = 0
		for pname, _ in pairs(team.players) do
			score = score + ctf_stats.player(pname).score
		end
		scores[tname] = score
	end

	update_lowest()
end

-- Override team-allocation logic
-- Allocate player into the team with the lowest cumulative score
function ctf.custom_alloc(name)
	calc_scores()
	return lowest.team
end

function table.map_inplace(t, f) -- luacheck: ignore
	for key, value in pairs(t) do
		t[key] = f(value)
	end
	return t
end

ctf_alloc = {}
function ctf_alloc.set_all()
	local players = minetest.get_connected_players()
	table.map_inplace(players, function(a)
		local stats, _ = ctf_stats.player(a:get_player_name())
		return {
			player = a,
			score = stats.score,
		}
	end)
	table.sort(players, function(a, b)
		return a.score > b.score
	end)

	local to_red = math.random(2) == 2
	for _, spair in pairs(players) do
		local player     = spair.player
		local name       = player:get_player_name()
		local alloc_mode = tonumber(ctf.setting("allocate_mode"))
		local team
		if to_red then
			team = "red"
		else
			team = "blue"
		end
		to_red = not to_red

		if alloc_mode ~= 0 and team then
			ctf.log("autoalloc", name .. " was allocated to " .. team)
			ctf.join(name, team)
		end
		ctf.move_to_spawn(name)

		if ctf.setting("match.clear_inv") then
			local inv = player:get_inventory()
			inv:set_list("main", {})
			inv:set_list("craft", {})
			give_initial_stuff(player)
		end

		player:set_hp(player:get_properties().hp_max)
	end
end
