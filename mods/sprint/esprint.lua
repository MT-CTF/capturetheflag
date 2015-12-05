--[[
Sprint mod for Minetest by GunshipPenguin

To the extent possible under law, the author(s)
have dedicated all copyright and related and neighboring rights
to this software to the public domain worldwide. This software is
distributed without any warranty.
]]

local players = {}
local staminaHud = {}

minetest.register_on_joinplayer(function(player)
	local playerName = player:get_player_name()

	players[playerName] = {
		sprinting = false,
		timeOut = 0,
		stamina = SPRINT_STAMINA,
		shouldSprint = false,
	}
	if SPRINT_HUDBARS_USED then
		hb.init_hudbar(player, "sprint")
	else
		players[playerName].hud = player:hud_add({
			hud_elem_type = "statbar",
			position = {x=0.5,y=1},
			size = {x=24, y=24},
			text = "sprint_stamina_icon.png",
			number = 20,
			alignment = {x=0,y=1},
			offset = {x=-263, y=-110},
			}
		)
	end
end)
minetest.register_on_leaveplayer(function(player)
	local playerName = player:get_player_name()
	players[playerName] = nil
end)
minetest.register_globalstep(function(dtime)
	--Get the gametime
	local gameTime = minetest.get_gametime()

	--Loop through all connected players
	for playerName,playerInfo in pairs(players) do
		local player = minetest.get_player_by_name(playerName)
		if player ~= nil then
			--Check if the player should be sprinting
			if player:get_player_control()["aux1"] and player:get_player_control()["up"] then
				players[playerName]["shouldSprint"] = true
			else
				players[playerName]["shouldSprint"] = false
			end

			--If the player is sprinting, create particles behind him/her
			if playerInfo["sprinting"] == true and gameTime % 0.1 == 0 then
				local numParticles = math.random(1, 2)
				local playerPos = player:getpos()
				local playerNode = minetest.get_node({x=playerPos["x"], y=playerPos["y"]-1, z=playerPos["z"]})
				if playerNode["name"] ~= "air" then
					for i=1, numParticles, 1 do
						minetest.add_particle({
							pos = {x=playerPos["x"]+math.random(-1,1)*math.random()/2,y=playerPos["y"]+0.1,z=playerPos["z"]+math.random(-1,1)*math.random()/2},
							velocity = {x=0, y=5, z=0},
							acceleration = {x=0, y=-13, z=0},
							expirationtime = math.random(),
							size = math.random()+0.5,
							collisiondetection = true,
							vertical = false,
							texture = "sprint_particle.png",
						})
					end
				end
			end

			--Adjust player states
			if players[playerName]["shouldSprint"] == true then --Stopped
				setSprinting(playerName, true)
			elseif players[playerName]["shouldSprint"] == false then
				setSprinting(playerName, false)
			end

			--Lower the player's stamina by dtime if he/she is sprinting and set his/her state to 0 if stamina is zero
			if playerInfo["sprinting"] == true then
				playerInfo["stamina"] = playerInfo["stamina"] - dtime
				if playerInfo["stamina"] <= 0 then
					playerInfo["stamina"] = 0
					setSprinting(playerName, false)
				end

			--Increase player's stamina if he/she is not sprinting and his/her stamina is less than SPRINT_STAMINA
			elseif playerInfo["sprinting"] == false and playerInfo["stamina"] < SPRINT_STAMINA then
				playerInfo["stamina"] = playerInfo["stamina"] + dtime
			end
			-- Cap stamina at SPRINT_STAMINA
			if playerInfo["stamina"] > SPRINT_STAMINA then
				playerInfo["stamina"] = SPRINT_STAMINA
			end

			--Update the players's hud sprint stamina bar

			if SPRINT_HUDBARS_USED then
				hb.change_hudbar(player, "sprint", playerInfo["stamina"])
			else
				local numBars = (playerInfo["stamina"]/SPRINT_STAMINA)*20
				player:hud_change(playerInfo["hud"], "number", numBars)
			end
		end
	end
end)

function setSprinting(playerName, sprinting) --Sets the state of a player (0=stopped/moving, 1=sprinting)
	local player = minetest.get_player_by_name(playerName)
	if players[playerName] then
		players[playerName]["sprinting"] = sprinting
		if sprinting == true then
			player:set_physics_override({speed=SPRINT_SPEED,jump=SPRINT_JUMP})
		elseif sprinting == false then
			player:set_physics_override({speed=1.0,jump=1.0})
		end
		return true
	end
	return false
end
