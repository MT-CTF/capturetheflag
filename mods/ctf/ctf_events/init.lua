local hud = hudkit()

minetest.register_on_leaveplayer(function(player)
	hud.players[player:get_player_name()] = nil
end)

local NUM_EVT = 6

ctf_events = {
	events = {}
}

function ctf_events.post(action, one, one_color, two, two_color)
	table.insert(ctf_events.events, 1, {
		action = action,
		one = one,
		one_color = one_color,
		two = two,
		two_color = two_color
	})

	while #ctf_events.events > NUM_EVT do
		table.remove(ctf_events.events, #ctf_events.events)
	end
end

function ctf_events.update_row(i, player, name, tplayer, evt)
	local idx = "ctf_events:" .. i .. "_one"
	local idxa = "ctf_events:" .. i .. "_action"
	local idx2 = "ctf_events:" .. i .. "_two"

	if not evt then
		hud:remove(player, idx)
		hud:remove(player, idxa)
		hud:remove(player, idx2)
		return
	end

	local y_pos = i * 20

	-- One
	if evt.one then
		if hud:exists(player, idx) then
			hud:change(player, idx, "text", evt.one)
			hud:change(player, idx, "number", evt.one_color.hex)
		else
			local tmp = {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = evt.one,
				number        = evt.one_color.hex,
				offset        = {x = 145, y = -y_pos},
				alignment     = {x = -1, y = 0}
			}
			hud:add(player, idx, tmp)
		end
	else
		hud:remove(player, idx)
	end

	-- Two
	if evt.two then
		if hud:exists(player, idx2) then
			hud:change(player, idx2, "text", evt.two)
			hud:change(player, idx2, "number", evt.two_color.hex)
		else
			local tmp = {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = evt.two,
				number        = evt.two_color.hex,
				offset        = {x = 175, y = -y_pos},
				alignment     = {x = 1, y = 0}
			}
			hud:add(player, idx2, tmp)
		end
	else
		hud:remove(player, idx2)
	end

	-- Action
	if evt.action then
		if hud:exists(player, idxa) then
			hud:change(player, idxa, "text", "ctf_events_" .. evt.action .. ".png")
		else
			local tmp = {
				hud_elem_type = "image",
				position      = {x = 0, y = 0.8},
				scale         = {x = 1, y = 1},
				text          = "ctf_events_" .. evt.action .. ".png",
				offset        = {x = 160, y = -y_pos},
				alignment     = {x = 0, y = 0}
			}
			hud:add(player, idxa, tmp)
		end
	else
		hud:remove(player, idxa)
	end
end

function ctf_events.update(player)
	local name = player:get_player_name()
	local tplayer = ctf.player_or_nil(name)
	if tplayer then
		for i=1, NUM_EVT do
			local evt = nil
			if #ctf_events.events >= i then
				evt = ctf_events.events[i]
			end
			ctf_events.update_row(i, player, name, tplayer, evt)
		end
	end
end

function ctf_events.update_all()
	for _, player in pairs(minetest.get_connected_players()) do
		ctf_events.update(player)
	end
end

ctf.register_on_killedplayer(function(victim, killer, tool_caps)
	local victim_color = ctf_colors.get_color(ctf.player(victim))
	local killer_color = ctf_colors.get_color(ctf.player(killer))

	local type = "sword" -- Also used for unknown attacks

	if tool_caps.damage_groups.grenade then
		type = "grenade"
	elseif tool_caps.damage_groups.rocket then
		type = "rocket"
	elseif tool_caps.damage_groups.ranged then
		type = "bullet"
	elseif tool_caps.damage_groups.sniper then
		type = "sniper"
	end

	if tool_caps.damage_groups.combat_log then
		victim = victim .. " (Combat Log)"
	elseif tool_caps.damage_groups.suicide then
		victim = victim .. " (Suicide?)"
	end

	ctf_events.post("kill_" .. type, killer, killer_color, victim, victim_color)
	ctf_events.update_all()
end)

minetest.register_on_joinplayer(function(player)
	ctf_events.update(player)
end)

ctf_match.register_on_new_match(function()
	ctf_events.events = {}
	ctf_events.update_all()
end)
