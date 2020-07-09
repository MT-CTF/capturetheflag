ctf_match = {}

local claimed = ctf_flag.collect_claimed()
for i, flag in pairs(claimed) do
	flag.claimed = nil
end

dofile(minetest.get_modpath("ctf_match") .. "/matches.lua")
dofile(minetest.get_modpath("ctf_match") .. "/buildtime.lua")
dofile(minetest.get_modpath("ctf_match") .. "/chat.lua")
dofile(minetest.get_modpath("ctf_match") .. "/vote.lua")

ctf.register_on_init(function()
	ctf._set("match.remove_player_on_leave",     false)
	minetest.settings:set_bool("enable_pvp", true)
end)

ctf_match.register_on_build_time_start(function()
	ctf_match.match_start_time = nil
end)

ctf_match.register_on_build_time_end(function()
	ctf_match.match_start_time = os.time()
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

ctf_match.register_on_build_time_start(function()
	shooter.config.allow_players = false
end)

ctf_match.register_on_build_time_end(function()
	shooter.config.allow_players = true
end)
