--[[
Afk Kick mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is
distributed without any warranty.
]]

local MAX_INACTIVE_TIME = 120
local CHECK_INTERVAL = 1
local WARN_TIME = 20

local players = {}
local checkTimer = 0

local S = minetest.get_translator(minetest.get_current_modname())

minetest.register_privilege("canafk", {
    description = S("Allow to AFK without being kicked"),
})

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = {
		lastAction = minetest.get_gametime()
	}
end)

minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)

minetest.register_on_chat_message(function(playerName, message)
	-- Verify that there is a player, and that the player is online
	if not playerName or not minetest.get_player_by_name(playerName) then
		return
	end

	players[playerName]["lastAction"] = minetest.get_gametime()
end)

minetest.register_globalstep(function(dtime)
	local currGameTime = minetest.get_gametime()

	--Check for inactivity once every CHECK_INTERVAL seconds
	checkTimer = checkTimer + dtime

	local checkNow = checkTimer >= CHECK_INTERVAL
	if checkNow then
		checkTimer = checkTimer - CHECK_INTERVAL
	end

	--Loop through each player in players
	for playerName,_ in pairs(players) do
		local player = minetest.get_player_by_name(playerName)
		if player then
			--Check if this player is doing an action
			for _,keyPressed in pairs(player:get_player_control()) do
				if keyPressed then
					players[playerName]["lastAction"] = currGameTime
				end
			end

			if checkNow and not minetest.check_player_privs(player, { canafk = true }) then
				--Kick player if he/she has been inactive for longer than MAX_INACTIVE_TIME seconds
				if players[playerName]["lastAction"] + MAX_INACTIVE_TIME < currGameTime then
					minetest.kick_player(playerName, "Kicked for inactivity")
				end

				--Warn player if he/she has less than WARN_TIME seconds to move or be kicked
				if players[playerName]["lastAction"] + MAX_INACTIVE_TIME - WARN_TIME < currGameTime then
					minetest.chat_send_player(playerName, minetest.colorize("#FF8C00",
                        S("Warning, you have @1 seconds to move or be kicked",
                    tostring(players[playerName]["lastAction"] + MAX_INACTIVE_TIME - currGameTime + 1))))
				end
			end
		end
	end
end)
