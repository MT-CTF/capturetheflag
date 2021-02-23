ctf_teams.registered_on_allocplayer = {}
--- Params: player, team
function ctf_teams.register_on_allocplayer(func)
	table.insert(ctf_teams.registered_on_allocplayer, func)
end

ctf_teams.registered_on_deallocplayer = {}
--- Params: player, team
function ctf_teams.register_on_deallocplayer(func)
	table.insert(ctf_teams.registered_on_deallocplayer, func)
end

