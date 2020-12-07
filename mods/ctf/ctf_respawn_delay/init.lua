ctf_respawn_delay = {
	players = {},
}
local respawnfunc
local RESPAWN_DELAY = 5
local RESPAWN_INTERVAL = 1.1
local RESPAWN_MESSAGE = "Respawning in "

minetest.register_on_dieplayer(function(player, reason)
	local pname = player:get_player_name()
	if ctf_match.is_in_build_time() or (reason.type == "punch" and reason.object and
	reason.object:is_player() and reason.object:get_player_name() == pname) then
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
			local pos = player:get_pos()
			pos.y = 500

			player:set_pos(pos) -- Player will be stuck there because CTF 'air' is walkable
			ctf_respawn_delay.players[pname].timeleft = RESPAWN_DELAY
			minetest.after(RESPAWN_INTERVAL, respawnfunc, pname)

			return true
		end

		for k, func in ipairs(ctf_respawn_delay.registered_on_respawnplayers) do
			func(player)
		end

		return true
	end)
end)

function respawnfunc(pname)
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
		player:hud_remove(ctf_respawn_delay.players[pname].hudid)
		player:set_properties({hp_max = ctf_respawn_delay.players[pname].old_max})
		player:set_hp(ctf_respawn_delay.players[pname].old_max)
		ctf_respawn_delay.players[pname] = nil

		for k, func in ipairs(ctf_respawn_delay.registered_on_respawnplayers) do
			func(player)
		end
	end
end
