ctf.register_on_init(function()
	ctf._set("match",                    false)
	ctf._set("match.destroy_team",       false)
	ctf._set("match.break_alliances",    true)
	ctf._set("match.teams",              "")
	ctf._set("match.clear_inv",          false)
end)

ctf_match.registered_on_new_match = {}
function ctf_match.register_on_new_match(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf_match.registered_on_new_match, func)
end

ctf_match.registered_on_winner = {}
function ctf_match.register_on_winner(func)
	if ctf._mt_loaded then
		error("You can't register callbacks at game time!")
	end
	table.insert(ctf_match.registered_on_winner, func)
end


-- Load next match. May be overrided
function ctf_match.next()
	for i = 1, #ctf_match.registered_on_new_match do
		ctf_match.registered_on_new_match[i]()
	end

	ctf.reset()
	-- Note: ctf.reset calls register_on_new_game, below.
end

-- Check for winner
local game_won = false
function ctf_match.check_for_winner()
	local winner
	for name, team in pairs(ctf.teams) do
		if winner then
			return
		end
		winner = name
	end

	-- There is a winner!
	if not game_won then
		game_won = true
		ctf.action("match", winner .. " won!")
		minetest.chat_send_all("Team " .. winner .. " won!")
		for i = 1, #ctf_match.registered_on_winner do
			ctf_match.registered_on_winner[i](winner)
		end
		minetest.after(2, function()
			game_won = false
			if ctf.setting("match") then
				ctf_match.next()
			end
		end)
	end
end

ctf.register_on_new_game(function()
	local teams = ctf.setting("match.teams")
	if teams:trim() == "" then
		return
	end
	ctf.log("match", "Setting up new game!")

	teams = teams:split(";")
	for i, v in pairs(teams) do
		local team = v:split(",")
		if #team == 5 then
			local name  = team[1]:trim()
			local color = team[2]:trim()
			local x     = tonumber(team[3]:trim())
			local y     = tonumber(team[4]:trim())
			local z     = tonumber(team[5]:trim())
			local flag  = {
				x = x,
				y = y,
				z = z
			}

			ctf.team({
				name     = name,
				color    = color,
				add_team = true
			})

			ctf_flag.add(name, flag)

			minetest.after(0, function()
				ctf_flag.assert_flag(flag)
			end)
		else
			ctf.warning("match", "Invalid team setup: " .. dump(v))
		end
	end

	for i, player in pairs(minetest.get_connected_players()) do
		local name       = player:get_player_name()
		local alloc_mode = tonumber(ctf.setting("allocate_mode"))
		local team       = ctf.autoalloc(name, alloc_mode)

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

	minetest.set_timeofday(0.4)

	minetest.chat_send_all("Next round!")
	if minetest.global_exists("chatplus") then
		chatplus.log("Next round!")
	end
end)

ctf_flag.register_on_capture(function(attname, flag)
	if not ctf.setting("match.destroy_team") then
		return
	end

	local fl_team = ctf.team(flag.team)
	if fl_team and #fl_team.flags == 0 then
		ctf.action("match", flag.team .. " was defeated.")
		ctf.remove_team(flag.team)
		minetest.chat_send_all(flag.team .. " has been defeated!")
	end

	ctf_match.check_for_winner()
end)
