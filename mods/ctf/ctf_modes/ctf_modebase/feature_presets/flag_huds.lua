local hud = mhud.init()

local FLAG_SAFE             = {color = 0xFFFFFF, text = "Punch the enemy flag(s)! Protect your flag!"         }
local FLAG_STOLEN           = {color = 0xFF0000, text = "Kill %s, they've got your flag!"                     }
local FLAG_STOLEN_YOU       = {color = 0xFF0000, text = "You've got a flag! Run back and punch your flag!"    }
local FLAG_STOLEN_TEAMMATE  = {color = 0x22BB22, text = "Protect teammate(s) %s! They have the enemy flag!"   }
local BOTH_FLAGS_STOLEN     = {color = 0xFF0000, text = "Kill %s to allow teammate(s) %s to capture the flag!"}
local BOTH_FLAGS_STOLEN_YOU = {color = 0xFF0000, text = "You can't capture that flag until %s is killed!"     }

local function get_status(you)
	local teamname = ctf_teams.get(you)

	if not teamname then return end

	local enemy_thief = ctf_modebase.flag_taken[teamname]
	local your_thieves = {}

	for pname in pairs(ctf_modebase.team_flag_takers[teamname]) do
		table.insert(your_thieves, pname)
	end

	if #your_thieves > 0 then
		your_thieves = table.concat(your_thieves, ", ")
	else
		your_thieves = false
	end

	local status

	if enemy_thief then
		if your_thieves then
			if ctf_modebase.taken_flags[you] then
				status = table.copy(BOTH_FLAGS_STOLEN_YOU)
				status.text = status.text:format(enemy_thief)
			else
				status = table.copy(BOTH_FLAGS_STOLEN)
				status.text = status.text:format(enemy_thief, your_thieves)
			end
		else
			status = table.copy(FLAG_STOLEN)
			status.text = status.text:format(enemy_thief)
		end
	else
		if your_thieves then
			if ctf_modebase.taken_flags[you] then
				status = FLAG_STOLEN_YOU
			else
				status = table.copy(FLAG_STOLEN_TEAMMATE)
				status.text = status.text:format(your_thieves)
			end
		else
			status = FLAG_SAFE
		end
	end

	return status
end

local player_timers
local player_timer_count = 0
local function untrack_capturer(player)
	player = PlayerName(player)

	if hud:get(player, "flag_timer") then
		hud:remove(player, "flag_timer")
	end

	if player_timers and player_timers[player] then
		player_timers[player] = nil
		player_timer_count = player_timer_count - 1
	end

	if player_timer_count == 0 then
		player_timers = nil
	end
end

local timer = 0
minetest.register_globalstep(function(dtime)
	if not player_timers then return end

	timer = timer + dtime
	if timer < 1 then return end

	for pname, timeleft in pairs(player_timers) do
		if timeleft - timer <= 0 then
			ctf_modebase.drop_flags(pname)
			return
		end

		player_timers[pname] = timeleft - timer

		hud:change(pname, "flag_timer", {
			text = string.format("%dm %ds left to capture", math.floor(timeleft / 60), math.floor(timeleft % 60))
		})
	end

	timer = 0
end)

return {
	track_capturer = function(player, time)
		player = PlayerName(player)

		if not player_timers then player_timers = {} end

		player_timers[player] = time
		player_timer_count = player_timer_count + 1

		hud:add(player, "flag_timer", {
			hud_elem_type = "text",
			position = {x = 0.5, y = 0},
			alignment = {x = "center", y = "down"},
			color = 0xFF0000,
			text_scale = 2
		})
	end,
	untrack_capturer = untrack_capturer,
	clear_capturers = function()
		if not player_timers then return end

		for pname in pairs(player_timers) do
			untrack_capturer(pname)
		end

		player_timers = nil
	end,
	on_allocplayer = function(player)
		local status = get_status(player:get_player_name())

		if not hud:exists(player, "flag_status") then
			hud:add(player, "flag_status", {
				hud_elem_type = "text",
				position = {x = 1, y = 0},
				offset = {x = -6, y = 6},
				alignment = {x = "left", y = "down"},
				text = status.text,
				color = status.color,
			})
		else
			hud:change(player, "flag_status", status)
		end

		for tname, def in pairs(ctf_map.current_map.teams) do
			local flag_pos = table.copy(def.flag_pos)

			if not hud:exists(player, "flag_pos:"..tname) then
				hud:add(player, "flag_pos:"..tname, {
					hud_elem_type = "waypoint",
					waypoint_text = HumanReadable(tname).."'s base",
					color = ctf_teams.team[tname].color_hex,
					world_pos = flag_pos,
				})
			else
				hud:change(player, "flag_pos:"..tname, {
					world_pos = flag_pos,
				})
			end
		end
	end,
	update = function()
		for _, player in pairs(minetest.get_connected_players()) do
			hud:change(player, "flag_status", get_status(player:get_player_name()))
		end
	end,
	clear_huds = function()
		hud:clear_all()
	end,
}
