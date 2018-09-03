local hud = hudkit()

local NUM_EVT = 6

ctf_events = {
	events = {}
}

local emoji = {
	kill_bullet  = ",-",
	kill_grenade = "o'",
	kill_sword   = "+--",
}

local function get_colorcodes(name)
	if not name then
		return "", ""
	end
	local color = ctf_colors.get_irc_color(name, ctf.player(name))
	local clear = "\x0F"
	if color then
		color = "\x03" .. color
	else
		color = ""
		clear = ""
	end
	return color, clear
end

function ctf_events.post_kill(action, one, two)
	table.insert(ctf_events.events, 1, {
		type = "kill",
		action = action,
		one = one,
		two = two
	})

	if minetest.global_exists("irc") and emoji[action] then
		local color1, clear1 = get_colorcodes(one)
		local color2, clear2 = get_colorcodes(two)
		local tag1  = one and (color1 .. "_" .. clear1) or ""
		local tag2  = two and (color2 .. "_" .. clear2) or ""
		local name1 = one and (tag1 .. one .. tag1) or ""
		local name2 = two and (tag2 .. two .. tag2) or ""
		irc.say((name1 .. " " .. emoji[action] .. " " .. name2):trim())
	end
end

function ctf_events.post_streak(name, streak_msg)
	table.insert(ctf_events.events, 1, {
		type = "streak",
		name = name,
		status = streak_msg
	})

	if minetest.global_exists("irc") then
		irc.say(name .. ": " .. streak_msg)
	end
end

function ctf_events.update_row(i, player, name, tplayer, evt)
	local idx = "ctf_events:" .. i .. "_one"
	local idxa = "ctf_events:" .. i .. "_action"
	local idx2 = "ctf_events:" .. i .. "_two"
	local idxn = "ctf_events:" .. i .. "_streak_name"
	local idxm = "ctf_events:" .. i .. "_streak_msg"

	if not evt then
		hud:remove(player, idx)
		hud:remove(player, idxa)
		hud:remove(player, idx2)
		hud:remove(player, idxn)
		hud:remove(player, idxm)
		return
	end

	local y_pos = i * 20

	if evt.type == "streak" then
		local pname = evt.name
		local pcolor = ctf_colors.get_color(pname, ctf.player(pname))
		if hud:exists(player, idxn) then
			hud:change(player, idxn, "text", pname)
			hud:change(player, idxn, "number", pcolor)
		else
			hud:add(player, idxn, {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = pname,
				number        = pcolor,
				offset        = {x = 145, y = -y_pos},
				alignment     = {x = -1, y = 0}
			})
		end

		if hud:exists(player, idxm) then
			hud:change(player, idxm, "text", evt.streak_msg)
		else
			hud:add(player, idxm, {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				text          = evt.streak_msg,
				number        = 0xFFFFFF,
				offset        = {x = 160, y = -y_pos},
				alignment     = {x = 0, y = 0}
			})
		end
		return
	end

	-- One
	if evt.one then
		local _, tone_hex = ctf_colors.get_color(evt.one, ctf.player(evt.one))
		if hud:exists(player, idx) then
			hud:change(player, idx, "text", evt.one)
			hud:change(player, idx, "number", tone_hex)
		else
			hud:add(player, idx, {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = evt.one,
				number        = tone_hex,
				offset        = {x = 145, y = -y_pos},
				alignment     = {x = -1, y = 0}
			})
		end
	else
		hud:remove(player, idx)
	end

	-- Two
	if evt.two then
		local _, ttwo_hex = ctf_colors.get_color(evt.two, ctf.player(evt.two))
		if hud:exists(player, idx2) then
			hud:change(player, idx2, "text", evt.two)
			hud:change(player, idx2, "number", ttwo_hex)
		else
			hud:add(player, idx2, {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = evt.two,
				number        = ttwo_hex,
				offset        = {x = 175, y = -y_pos},
				alignment     = {x = 1, y = 0}
			})
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

ctf.register_on_killedplayer(function(victim, killer, type)
	ctf_events.post_kill("kill_" .. type, killer, victim)
	ctf_events.update_all()
end)

minetest.register_on_joinplayer(function(player)
	ctf_events.update(player)
end)

minetest.register_on_leaveplayer(function(player)
	hud.players[player:get_player_name()] = nil
	ctf_events.update_all()
end)

ctf.register_on_new_match(function()
	ctf_events.events = {}
	ctf_events.update_all()
end)
