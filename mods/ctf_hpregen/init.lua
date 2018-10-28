local regen_interval = 10
local regen_amount = 1

local function regen_all()
	for _, player in pairs(minetest.get_connected_players()) do
		local oldhp = player:get_hp()
		if oldhp > 0 then
			local newhp = oldhp + regen_amount
			if newhp > 20 then
				newhp = 20
			end
			player:set_hp(newhp)
		end
	end
	minetest.after(regen_interval, regen_all)
end
minetest.after(regen_interval, regen_all)

ctf.register_on_killedplayer(function(vname, kname)
	local victim = minetest.get_player_by_name(vname)
	local killer = minetest.get_player_by_name(kname)
	if not killer or not victim then
		return
	end

	local vteam_pos = ctf.get_spawn(ctf.player(vname).team)
	local vpos = victim:get_pos()

	if vector.distance(vteam_pos, vpos) < 10 then
		return
	end

	local hp = killer:get_hp() + 6
	killer:set_hp(math.min(hp, 20))
end)
