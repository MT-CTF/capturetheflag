respawn_immunity = {}

local IMMUNE_TIME = 10
local immune_serial = 0
local immune_players = {}

function respawn_immunity.is_immune(player)
	return immune_players[player:get_player_name()]
end

function respawn_immunity.update_effects(player)
	-- TODO: transparent player when immune
	--
	-- if immune_players[player:get_player_name()] then
	-- 	player:set_texture_mod("[multiply:#1f1")
	-- else
	-- 	player:set_texture_mod(nil)
	-- end
end

function respawn_immunity.set_immune(player)
	immune_serial = immune_serial + 1
	immune_players[player:get_player_name()] = immune_serial
	minetest.after(1, function()
		respawn_immunity.update_effects(player)
	end)

	-- Set time out
	minetest.after(IMMUNE_TIME, function(id)
		if immune_players[player:get_player_name()] == id then
			immune_players[player:get_player_name()] = nil
			respawn_immunity.update_effects(player)
		end
	end, immune_serial)
end

table.insert(minetest.registered_on_punchplayers, 1, function(player, hitter,
		time_from_last_punch, tool_capabilities, dir, damage)
	if player and respawn_immunity.is_immune(player) then
		minetest.chat_send_player(hitter:get_player_name(),
			player:get_player_name() .. " just respawned or joined, and is immune to attacks!")
		return true
	end
end)

minetest.register_on_joinplayer(respawn_immunity.set_immune)
minetest.register_on_dieplayer(respawn_immunity.set_immune)
