ctf_match = {}

local claimed = ctf_flag.collect_claimed()
for i, flag in pairs(claimed) do
	flag.claimed = nil
end

dofile(minetest.get_modpath("ctf_match") .. "/matches.lua")
dofile(minetest.get_modpath("ctf_match") .. "/buildtime.lua")
dofile(minetest.get_modpath("ctf_match") .. "/reset.lua")
dofile(minetest.get_modpath("ctf_match") .. "/chat.lua")
dofile(minetest.get_modpath("ctf_match") .. "/vote.lua")

ctf.register_on_init(function()
	ctf._set("match.remove_player_on_leave",     false)
end)

minetest.register_on_leaveplayer(function(player)
	if ctf.setting("match.remove_player_on_leave") then
		ctf.remove_player(player:get_player_name())
	end
end)
