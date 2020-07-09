ctf.register_on_init(function()
	ctf._set("match",                    false)
	ctf._set("match.destroy_team",       false)
	ctf._set("match.break_alliances",    true)
	ctf._set("match.teams",              2)
	ctf._set("match.team.1",             "red")
	ctf._set("match.team.1.color",       "red")
	ctf._set("match.team.1.pos",         "7,65,93")
	ctf._set("match.team.2",             "blue")
	ctf._set("match.team.2.color",       "blue")
	ctf._set("match.team.2.pos",         "-22,66,-78")
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

	ctf_match.create_teams()

	ctf_alloc.set_all()

	minetest.chat_send_all("Next round!")
	if minetest.global_exists("chatplus") then
		chatplus.log("Next round!")
	end
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

-- This is overriden by ctf_map
function ctf_match.create_teams()
	error("Error! Unimplemented")
end

ctf_flag.register_on_pick_up(function(name)
	physics.set(name, "ctf_match:flag_mult", { speed = 0.9 })
end)

ctf_flag.register_on_drop(function(name)
	physics.remove(name, "ctf_match:flag_mult")
end)

ctf_flag.register_on_capture(function(attname, flag)
	if not ctf.setting("match.destroy_team") then
		return
	end

	physics.remove(attname, "ctf_match:flag_mult")

	local fl_team = ctf.team(flag.team)
	if fl_team and #fl_team.flags == 0 then
		ctf.action("match", flag.team .. " was defeated.")
		ctf.remove_team(flag.team)
		minetest.chat_send_all(flag.team .. " has been defeated!")
	end

	ctf_match.check_for_winner()
end)

ctf_match.match_start_time = nil
function ctf_match.get_match_duration()
	return ctf_match.match_start_time and
		(os.time() - ctf_match.match_start_time)
end
