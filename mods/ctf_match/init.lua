local storage = minetest.get_mod_storage()
ctf_match = {}

local claimed = ctf_flag.collect_claimed()
for i, flag in pairs(claimed) do
	flag.claimed = nil
end

dofile(minetest.get_modpath("ctf_match") .. "/matches.lua")
dofile(minetest.get_modpath("ctf_match") .. "/buildtime.lua")
dofile(minetest.get_modpath("ctf_match") .. "/chat.lua")
dofile(minetest.get_modpath("ctf_match") .. "/vote.lua")

local flag_stall_warning = minetest.parse_json(storage:get("flag_stall_warning")) or {}
ctf_flag.register_on_drop(function(name, flag)
	-- If player has already been warned, kick
	if flag_stall_warning[name] then
		minetest.kick_player(name, "You held the flag for too long!")
	-- Else, warn
	else
		minetest.chat_send_player(name,
				minetest.colorize("#FF4466", "You will be kicked the next time you don't capture the flag!"))
		flag_stall_warning[name] = true
		storage:set("flag_stall_warning", minetest.write_json(flag_stall_warning))
	end
end)

ctf.register_on_init(function()
	ctf._set("match.remove_player_on_leave",     false)
end)

ctf_match.register_on_build_time_end(function()
	minetest.sound_play({name="ctf_match_attack"}, { gain = 1.0 })
end)

minetest.register_on_leaveplayer(function(player)
	if ctf.setting("match.remove_player_on_leave") then
		ctf.remove_player(player:get_player_name())
	end
end)

if minetest.global_exists("irc") then
	ctf_match.register_on_winner(function(winner)
		if not irc.connected then return end
		irc:say("Team " .. winner .. " won!")
	end)

	ctf.register_on_new_game(function()
		if not irc.connected then return end
		irc:say("Next round!")
	end)
end

minetest.after(5, function()
	ctf_match.next()
end)
