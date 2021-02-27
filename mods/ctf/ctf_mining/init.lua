minetest.register_on_dignode(function(pos, oldnode, digger)
	if not digger:is_player() then
		return
	end
	local nname = oldnode.name
	local pname = digger:get_player_name()
	local ndef = minetest.registered_nodes[nname]
	if ndef and ndef.groups and ndef.groups.ores then
		local main, match = ctf_stats.player(pname)
		if main and match then
			main.score  = main.score  + ndef.groups.ores
			match.score = match.score + ndef.groups.ores
			ctf_stats.request_save()
			ctf.log("ctf_mining","Added "..tostring(ndef.groups.ores).." to "..pname)
			hud_score.new(pname, {
				name = "ctf_mining:xp",
				color = 0x4444FF,
				value = ndef.groups.ores
			})
		end
	end
end)
