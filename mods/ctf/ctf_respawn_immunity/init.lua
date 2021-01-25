ctf_respawn_immunity = {}

local IMMUNE_TIME = 5
local immune_serial = 0
local immune_players = {}

function ctf_respawn_immunity.is_immune(player)
	return immune_players[player:get_player_name()]
end

function ctf_respawn_immunity.set_immune(player)
	immune_serial = immune_serial + 1
	immune_players[player:get_player_name()] = immune_serial
	minetest.after(1, function()
		ctf_respawn_immunity.update_effects(player)
	end)

	-- Set time out
	minetest.after(IMMUNE_TIME, function(name, id)
		if immune_players[name] == id then
			immune_players[name] = nil
			ctf_respawn_immunity.update_effects(minetest.get_player_by_name(name))
		end
	end, player:get_player_name(), immune_serial)
end

function ctf_respawn_immunity.update_effects(player)
	-- TODO: transparent player when immune
	--
	-- if immune_players[player:get_player_name()] then
	-- 	player:set_texture_mod("[multiply:#1f1")
	-- else
	-- 	player:set_texture_mod(nil)
	-- end
end

minetest.register_on_punchplayer(function(player, hitter,
		time_from_last_punch, tool_capabilities, dir, damage)
	if not player or not hitter then
		return false
	end

	local pname = player:get_player_name()
	local hname = hitter:get_player_name()
	local pteam = ctf.player(pname).team
	local hteam = ctf.player(hname).team

	if pteam ~= hteam then
		if player and ctf_respawn_immunity.is_immune(player) then
			minetest.chat_send_player(hname, minetest.colorize("#EE8822", pname ..
					" just respawned or joined," .. " and is immune to attacks!"))
			return true
		end

		if hitter and ctf_respawn_immunity.is_immune(hitter) then
			minetest.chat_send_player(hname, minetest.colorize("#FF8C00",
					"Your immunity has ended because you attacked a player"))
			immune_players[hname] = nil
			ctf_respawn_immunity.update_effects(hitter)
		end
	end
end)

minetest.register_on_joinplayer(ctf_respawn_immunity.set_immune)
minetest.register_on_respawnplayer(ctf_respawn_immunity.set_immune)
