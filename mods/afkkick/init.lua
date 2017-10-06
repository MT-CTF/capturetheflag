--[[
Afk Kick mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is
distributed without any warranty.
]]

local MAX_INACTIVE_TIME = 300
local CHECK_INTERVAL = 1
local WARN_TIME = 20

local players = {}
local checkTimer = 0

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
	players[playerName]["lastAction"] = minetest.get_gametime()
end)

minetest.register_globalstep(function(dtime)
	local currGameTime = minetest.get_gametime()
	
	--Loop through each player in players
	for playerName,_ in pairs(players) do
		local player = minetest.get_player_by_name(playerName)
		if player then
		
			--Check for inactivity once every CHECK_INTERVAL seconds
			checkTimer = checkTimer + dtime
			if checkTimer > CHECK_INTERVAL then
				checkTimer = 0
				
				--Kick player if he/she has been inactive for longer than MAX_INACTIVE_TIME seconds
				if players[playerName]["lastAction"] + MAX_INACTIVE_TIME < currGameTime then 
					minetest.kick_player(playerName, "Kicked for inactivity")
				end
				
				--Warn player if he/she has less than WARN_TIME seconds to move or be kicked
				if players[playerName]["lastAction"] + MAX_INACTIVE_TIME - WARN_TIME < currGameTime then
					minetest.chat_send_player(playerName, "Warning, you have " .. tostring(players[playerName]["lastAction"] + MAX_INACTIVE_TIME - currGameTime) .. " seconds to move or be kicked")
				end
			end
			
			--Check if this player is doing an action
			for _,keyPressed in pairs(player:get_player_control()) do
				if keyPressed then
					players[playerName]["lastAction"] = currGameTime
				end
			end
		end
	end
end)
