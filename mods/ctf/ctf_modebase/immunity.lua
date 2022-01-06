local RESPAWN_IMMUNITY_SECONDS = 4
local immune_players = {}

function ctf_modebase.is_immune(player)
	return immune_players[PlayerName(player)] ~= nil
end

local old_get_skin = ctf_cosmetics.get_skin
ctf_cosmetics.get_skin = function(player, color)
	if ctf_modebase.is_immune(player) then
		return old_get_skin(player, color) .. "^[brighten^[multiply:#7ba5ff"
	else
		return old_get_skin(player, color)
	end
end

function ctf_modebase.give_immunity(player, remove_after)
	local pname = player:get_player_name()
	local old = immune_players[pname]

	if old then
		old:cancel()
	end

	if remove_after then
		immune_players[pname] = minetest.after(remove_after, ctf_modebase.remove_immunity, player)
	else
		immune_players[pname] = false
	end

	if old == nil then
		player:set_properties({pointable = false, textures = {ctf_cosmetics.get_skin(player)}})
		player:set_armor_groups({fleshy = 0})
	end
end

function ctf_modebase.remove_immunity(player)
	local pname = player:get_player_name()
	local old = immune_players[pname]

	if old == nil then return end
	immune_players[pname] = nil

	if old then
		old:cancel()
	end

	player:set_properties({pointable = true, textures = {ctf_cosmetics.get_skin(player)}})
	player:set_armor_groups({fleshy = 100})
end

ctf_teams.register_on_allocplayer(function(player)
	ctf_modebase.give_immunity(player, RESPAWN_IMMUNITY_SECONDS)
end)

ctf_api.register_on_respawnplayer(function(player)
	ctf_modebase.give_immunity(player, RESPAWN_IMMUNITY_SECONDS)
end)

minetest.register_on_dieplayer(function(player)
	ctf_modebase.remove_immunity(player)
	player:set_properties({pointable = false})
end)

minetest.register_on_leaveplayer(function(player)
	ctf_modebase.remove_immunity(player)
end)
