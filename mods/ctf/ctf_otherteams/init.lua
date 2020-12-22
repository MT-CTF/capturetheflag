minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()

	if not ctf.get_spawn(ctf.player(name).team) then
		local pos

		if math.random(1, 2) == 1 then
			local team = ctf.team("red")
			if team and team.flags[1] then
				pos = vector.new(team.flags[1])
			end
		else
			local team = ctf.team("blue")
			if team and team.flags[1] then
				pos = vector.new(team.flags[1])
			end
		end

		if pos then
			player:set_pos(pos)
		end
	end
end)
