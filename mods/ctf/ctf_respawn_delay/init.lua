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

		if ctf_respawn_delay.players[pname] then
			-- Since the player is still dead the client can send respawn actions
			-- https://github.com/minetest/minetest/blob/4152227f17315a9cf9038266d9f9bb06e21e3424/src/network/serverpackethandler.cpp#L895
			-- We should ignore those
			if ctf_respawn_delay.players[pname].timeleft == "waiting" then
				ctf_respawn_delay.players[pname].timeleft = RESPAWN_DELAY
				local pos = player:get_pos()
				pos.y = ctf_map.map.h/2 + 10

				player:set_pos(pos) -- Player will be stuck there because CTF 'air' is walkable
				minetest.after(RESPAWN_INTERVAL, respawnfunc, pname)
			end

			return true
		end

		for k, func in ipairs(ctf_respawn_delay.registered_on_respawnplayers) do
			func(player)
		end

		return true
	end)
end)

function respawnplayer(player, pname)
	player:hud_remove(ctf_respawn_delay.players[pname].hudid)
	player:set_properties({hp_max = ctf_respawn_delay.players[pname].old_max})
	player:set_hp(ctf_respawn_delay.players[pname].old_max)

	for k, func in ipairs(ctf_respawn_delay.registered_on_respawnplayers) do
		func(player)
	end
end

function respawnfunc(pname)
	if not ctf_respawn_delay.players[pname] then
		return
	end

	local player = minetest.get_player_by_name(pname)
	if not player then
		ctf_respawn_delay.players[pname] = nil
		return
	end

	ctf_respawn_delay.players[pname].timeleft = ctf_respawn_delay.players[pname].timeleft - 1
	local timeleft = ctf_respawn_delay.players[pname].timeleft

	if timeleft > 0 then
		player:hud_change(ctf_respawn_delay.players[pname].hudid, "text", RESPAWN_MESSAGE..timeleft)

		minetest.after(RESPAWN_INTERVAL, respawnfunc, pname)
	else
		respawnplayer(player, pname)
		ctf_respawn_delay.players[pname] = nil
	end
end

ctf_match.register_on_new_match(function()
	for pname in pairs(ctf_respawn_delay.players) do
		local player = minetest.get_player_by_name(pname)
		if player then
			respawnplayer(player, pname)
		end
	end

	ctf_respawn_delay.players = {}
end)

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()
	if ctf_respawn_delay.players[pname] then
		player:set_properties({hp_max = ctf_respawn_delay.players[pname].old_max})
		ctf_respawn_delay.players[pname] = nil
	end
end)
