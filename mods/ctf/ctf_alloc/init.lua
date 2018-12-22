local storage = minetest.get_mod_storage()
local data = minetest.parse_json(storage:get_string("locktoteam")) or {}

local ctf_autoalloc = ctf.autoalloc
function ctf.autoalloc(name, alloc_mode)
	if data[name] then
		return data[name]
	end

	return ctf_autoalloc(name, alloc_mode)
end

ChatCmdBuilder.new("ctf_lockpt", function(cmd)
	cmd:sub(":name :team", function(name, pname, team)
		if team == "!" then
			data[pname] = nil
			storage:set_string("locktoteam", minetest.write_json(data))
			return true, "Unlocked " .. pname
		else
			data[pname] = team
			storage:set_string("locktoteam", minetest.write_json(data))
			return true, "Locked " .. pname .. " to " .. team
		end
	end)
end, {
	description = "Lock a player to a team",
	privs = {
		ctf_admin = true,
	}
})

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

	minetest.log("warning", dump(players))

	local team_count = #ctf.team_list
	local team_n = math.random(team_count)
	for _, spair in pairs(players) do
		local player     = spair.player
		local name       = player:get_player_name()
		local alloc_mode = tonumber(ctf.setting("allocate_mode"))
		local team = ctf.team_list[team_n]
		team_n = (team_n % team_count) + 1

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

		player:set_hp(20)
	end
end
