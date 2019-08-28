-- TODO: delete flags if they are removed (ctf.next, or captured)
ctf.hud.register_part(function(player, name, tplayer)
	if ctf.setting("flag.waypoints") then
		for tname, team in pairs(ctf.teams) do
			for _, flag in pairs(team.flags) do
				local hud = "ctf:hud_" .. tname
				local flag_name = flag.name or tname .. "'s base"
				local color = ctf.flag_colors[team.data.color]
				if not color then
					color = "0x000000"
				end

				if ctf.hud:exists(player, hud) then
					ctf.hud:change(player, hud, "world_pos", {
						x = flag.x,
						y = flag.y,
						z = flag.z
					})
				else
					ctf.hud:add(player, hud, {
						hud_elem_type = "waypoint",
						name = flag_name,
						number = color,
						world_pos = {
							x = flag.x,
							y = flag.y,
							z = flag.z
						}
					})
				end
			end
		end
	end
end)

ctf.hud.register_part(function(player, name, tplayer)
	-- Check all flags
	local alert = nil
	local color = "0xFFFFFF"
	if ctf.setting("flag.alerts") then
		if ctf.setting("flag.alerts.neutral_alert") then
			alert = "Punch the enemy flag! Protect your flag!"
		end
		local claimed = ctf_flag.collect_claimed()
		local enemyHolder = nil
		local teamHolder = nil
		for _, flag in pairs(claimed) do
			if flag.team == tplayer.team then
				enemyHolder = flag.claimed.player
			else
				teamHolder = flag.claimed.player
			end
		end

		if teamHolder == name then
			if enemyHolder then
				alert = "You can't capture the flag until " .. enemyHolder .. " is killed!"
				color = "0xFF0000"
			else
				alert = "You've got the flag! Run back and punch your flag!"
				color = "0xFF0000"
			end
		elseif teamHolder then
			if enemyHolder then
				alert = "Kill " .. enemyHolder .. " to allow " .. teamHolder .. " to capture the flag!"
				color = "0xFF0000"
			else
				alert = "Protect " .. teamHolder .. ", they've got the enemy flag!"
				color = "0xFF0000"
			end
		elseif enemyHolder then
			alert = "Kill " .. enemyHolder .. ", they've got your flag!"
			color = "0xFF0000"
		end
	end

	-- Display alert
	if alert then
		if ctf.hud:exists(player, "ctf:hud_team_alert") then
			ctf.hud:change(player, "ctf:hud_team_alert", "text", alert)
			ctf.hud:change(player, "ctf:hud_team_alert", "number", color)
		else
			local y
			if ctf.setting("hud.teamname") then
				y = 50
			else
				y = 20
			end
			ctf.hud:add(player, "ctf:hud_team_alert", {
				hud_elem_type = "text",
				position      = {x = 1, y = 0},
				scale         = {x = 100, y = 100},
				text          = alert,
				number        = color,
				offset        = {x = -10, y = y},
				alignment     = {x = -1, y = 0}
			})
		end
	else
		ctf.hud:remove(player, "ctf:hud_team_alert")
	end
end)
