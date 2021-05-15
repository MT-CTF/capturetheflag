ctf_respawn_delay = {
	players = {},
}
local respawnfunc
local RESPAWN_DELAY = 5
local RESPAWN_INTERVAL = 1.1
local RESPAWN_MESSAGE = "Respawning in "

minetest.register_on_dieplayer(function(player, reason)
	local pname = player:get_player_name()
	if ctf_match.is_in_build_time() or ctf_respawn_delay.players[pname] then -- what is dead may never die
		return
	end

	ctf_respawn_delay.players[pname] = {
		old_max = player:get_properties().hp_max,
		timeleft = "waiting",
		hudid = player:hud_add({
			hud_elem_type = "text",
			position = {x=0.5, y=0.5},
			name = "respawn_delay",
			scale = {x=100, y=100},
			text = RESPAWN_MESSAGE..RESPAWN_DELAY,
			number = 0xD600AF,
			alignment = {x = 0, y = -1},
			offset = {x = 0, y = 0},
			size = {x = 2},
		})
	}
	player:set_properties({hp_max = 0})
end)

minetest.register_on_mods_loaded(function()
	ctf_respawn_delay.registered_on_respawnplayers = minetest.registered_on_respawnplayers
	minetest.registered_on_respawnplayers = {}

	table.insert(minetest.registered_on_respawnplayers, 1, function(player)
		local pname = player:get_player_name()

		if ctf_respawn_delay.players[pname] and ctf_respawn_delay.players[pname].timeleft == "waiting" then
			ctf_respawn_delay.players[pname].timeleft = RESPAWN_DELAY
			local pos = player:get_pos()
			pos.y = ctf_map.map.h/2 + 10

			player:set_pos(pos) -- Player will be stuck there because CTF 'air' is walkable
			minetest.after(RESPAWN_INTERVAL, respawnfunc, pname)

			return true
		end

		for k, func in ipairs(ctf_respawn_delay.registered_on_respawnplayers) do
			func(player)
		end

		return true
	end)
end)

function ctf_respawn_delay.respawnplayer(name)
	local player = minetest.get_player_by_name(name)

	if not player then return end

	player:hud_remove(ctf_respawn_delay.players[name].hudid)
	player:set_properties({hp_max = ctf_respawn_delay.players[name].old_max})
	player:set_hp(ctf_respawn_delay.players[name].old_max)
	ctf_respawn_delay.players[name] = nil

	for k, func in ipairs(ctf_respawn_delay.registered_on_respawnplayers) do
		func(player)
	end
end

function respawnfunc(pname)
	local player = minetest.get_player_by_name(pname)

	if not player or not ctf_respawn_delay.players[pname] then
		ctf_respawn_delay.players[pname] = nil
		return
	end

	if type(ctf_respawn_delay.players[pname].timeleft) == "string" then
		minetest.after(RESPAWN_INTERVAL, respawnfunc, pname)

		return
	end

	ctf_respawn_delay.players[pname].timeleft = ctf_respawn_delay.players[pname].timeleft - 1
	local timeleft = ctf_respawn_delay.players[pname].timeleft

	if timeleft > 0 then
		player:hud_change(ctf_respawn_delay.players[pname].hudid, "text", RESPAWN_MESSAGE..timeleft)

		minetest.after(RESPAWN_INTERVAL, respawnfunc, pname)
	else
		ctf_respawn_delay.respawnplayer(pname)
	end
end

ctf_match.register_on_new_match(function()
	for name in pairs(ctf_respawn_delay.players) do
		ctf_respawn_delay.respawnplayer(name)
	end
end)
