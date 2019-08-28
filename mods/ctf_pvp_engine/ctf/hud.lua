ctf.hud = hudkit()
ctf.hud.parts = {}
function ctf.hud.register_part(func)
	table.insert(ctf.hud.parts, func)
end

minetest.register_on_leaveplayer(function(player)
	ctf.hud.players[player:get_player_name()] = nil
end)

ctf.register_on_join_team(function(name, tname)
	if ctf.setting("hud") then
		ctf.hud.update(minetest.get_player_by_name(name))
	end
end)

function ctf.hud.update(player)
	if not player then
		return
	end

	local name    = player:get_player_name()
	local tplayer = ctf.player(name)

	if not tplayer or not tplayer.team or not ctf.team(tplayer.team) then
		return
	end

	-- Team Identifier
	for i = 1, #ctf.hud.parts do
		ctf.hud.parts[i](player, name, tplayer)
	end
end

function ctf.hud.updateAll()
	if not ctf.setting("hud") then
		return
	end

	local players = minetest.get_connected_players()
	for i = 1, #players do
		ctf.hud.update(players[i])
	end
end

local function tick()
	ctf.hud.updateAll()
	minetest.after(10, tick)
end
minetest.after(1, tick)
