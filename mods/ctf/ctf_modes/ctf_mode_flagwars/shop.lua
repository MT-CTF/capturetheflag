local items_to_sell = {
	{ "default:sword_diamond 1", "default:gold_ingot 6" },
	{ "default:sword_mese 1", "default:gold_ingot 5" },
}


minetest.register_node("ctf_modes_flagwars:shop", {
	walkable = true,
	pointable = true,
	diggable = false,
	on_construct = function(pos)
		if not ctf_map.current_map then
			return
		end
		local closest_team = { team = "none", distance = -1 }
		for team, team_props in pairs(ctf_map.current_map.teams) do
			dist = vector.dist(team_props.flag_pos, pos)
			if dist < closest_team["distance"] then
				closet_team["distance"] = dist
				closest_team["team"] = team
			end
		end
		local team_number = string.match(closest_team["team"], "team\.(.*)")
		local team_color
		local i = 0
		for team, _ in pairs(ctf_teams["team"]) do
			if i == team_number then
				team_color = team
			end
			i = i + 1
		end
		local meta = minetest.get_meta(pos)
		meta:set_string("team", team_color)
	end
})
