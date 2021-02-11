-- Capture The Flag mod: anticoward

potential_cowards = {}
local TIMER_UPDATE_INTERVAL = 2
local COMBAT_TIMEOUT_TIME = 20
local COMBATLOG_SCORE_PENALTY = 10

--
--- Make suicides and combat logs award last puncher with kill
--

ctf.register_on_attack(function(player, hitter,
		time_from_last_punch, tool_capabilities, dir, damage)
	if player and hitter then
		local pname = player:get_player_name()
		local hname = hitter:get_player_name()

		local hp = player:get_hp() - damage
		if hp <= 0 then
			if potential_cowards[pname] then
				player:hud_remove(potential_cowards[pname].hud or 0)
				potential_cowards[pname] = nil
			end

			if potential_cowards[hname] and potential_cowards[hname].puncher == pname then
				hitter:hud_remove(potential_cowards[hname].hud or 0)
				potential_cowards[hname] = nil
			end

			return false
		end

		if not potential_cowards[pname] then
			potential_cowards[pname] = {
				hud = player:hud_add({
					hud_elem_type = "text",
					position = {x=1, y=0.3},
					name = "combat_hud",
					scale = {x = 2, y = 2},
					text = "You are in combat. If you leave/suicide your attacker will get the kill",
					number = 0xff0000,
					direction = 0,
					alignment = {x=-1, y=1},
					size = {x=1},
					z_index = 100,
				})
			}
		end

		potential_cowards[pname].timer = 0
		potential_cowards[pname].puncher = hname
		potential_cowards[pname].toolcaps = tool_capabilities
	end
end)

minetest.register_on_dieplayer(function(player, reason)
	local pname = player:get_player_name()

	if reason.type == "node_damage" or reason.type == "drown" or reason.type == "fall" then
		if potential_cowards[pname] then
			local hname = potential_cowards[pname].puncher
			local last_attacker = minetest.get_player_by_name(hname)

			if not last_attacker then
				player:hud_remove(potential_cowards[pname].hud or 0)
				potential_cowards[pname] = nil

				return
			end

			potential_cowards[pname].toolcaps.damage_groups.suicide = 1

			for i = 1, #ctf.registered_on_killedplayer do
				ctf.registered_on_killedplayer[i](
					pname,
					hname,
					last_attacker:get_wielded_item(),
					potential_cowards[pname].toolcaps
				)
			end

			if potential_cowards[hname] and potential_cowards[hname].puncher == pname then
				last_attacker:hud_remove(potential_cowards[hname].hud or 0)
				potential_cowards[hname] = nil
			end

			if potential_cowards[pname] then
				player:hud_remove(potential_cowards[pname].hud or 0)
				potential_cowards[pname] = nil
			end
		else
			for victim in pairs(potential_cowards) do
				if potential_cowards[victim].puncher == pname then
					local victimobj = minetest.get_player_by_name(victim)

					if victimobj then
						victimobj:hud_remove(potential_cowards[victim].hud or 0)
					end

					potential_cowards[victim] = nil
					break
				end
			end
		end
	end
end)

minetest.register_on_leaveplayer(function(player, timeout)
	if timeout == true then return end
	local pname = player:get_player_name()

	if potential_cowards[pname] then
		local last_attacker = minetest.get_player_by_name(potential_cowards[pname].puncher)

		if not last_attacker then return end

		potential_cowards[pname].toolcaps.damage_groups.combat_log = 1

		for i = 1, #ctf.registered_on_killedplayer do
			ctf.registered_on_killedplayer[i](
				pname,
				potential_cowards[pname].puncher,
				last_attacker:get_wielded_item(),
				potential_cowards[pname].toolcaps
			)
		end

		local main, match = ctf_stats.player(pname)

		if main and match then
			main.deaths = main.deaths + 1
			match.deaths = match.deaths + 1
			main.score = main.score - COMBATLOG_SCORE_PENALTY
			match.score = match.score - COMBATLOG_SCORE_PENALTY
			match.kills_since_death = 0
			ctf_stats.request_save()
		end

		potential_cowards[pname] = nil
	end
end)

local globtimer = 0
minetest.register_globalstep(function(dtime)
	globtimer = globtimer + dtime

	if globtimer >= TIMER_UPDATE_INTERVAL then
		for k in pairs(potential_cowards) do
			potential_cowards[k].timer = potential_cowards[k].timer + globtimer

			if potential_cowards[k].timer >= COMBAT_TIMEOUT_TIME then
				local player = minetest.get_player_by_name(k)

				if player then
					player:hud_remove(potential_cowards[k].hud or 0)
				end

				potential_cowards[k] = nil
				kill_assist.clear_assists(k)
			end
		end

		globtimer = 0
	end
end)

ctf_match.register_on_new_match(function()
	potential_cowards = {}
end)

ctf.register_on_new_game(function()
	potential_cowards = {}
end)
