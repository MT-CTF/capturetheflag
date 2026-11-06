ctf_teams.registered_on_allocplayer = {}
--- Params: player, new_team, old_team (nil on first allocation)
function ctf_teams.register_on_allocplayer(func)
	table.insert(ctf_teams.registered_on_allocplayer, func)
end
