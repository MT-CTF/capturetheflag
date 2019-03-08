local hud = hudkit()

minetest.register_on_leaveplayer(function(player)
	hud.players[player:get_player_name()] = nil
end)

local NUM_EVT = 6

ctf_events = {
	events = {}
}

function ctf_events.post(image, one, two)
	table.insert(ctf_events.events, 1, {
		image = image,
		one = one,
		two = two
	})

	while #ctf_events.events > NUM_EVT do
		table.remove(ctf_events.events, #ctf_events.events)
	end
end

function ctf_events.update_row(i, player, name, tplayer, evt)
	local idx = "ctf_events:" .. i .. "_one"
	local idxa = "ctf_events:" .. i .. "_image"
	local idx2 = "ctf_events:" .. i .. "_two"

	if not evt then
		hud:remove(player, idx)
		hud:remove(player, idxa)
		hud:remove(player, idx2)
		return
	end

	local y_pos = i * 40

	-- Killer
	if evt.one then
		local tcolor = ctf_colors.get_color(ctf.player(evt.one))
		if hud:exists(player, idx) then
			hud:change(player, idx, "text", evt.one)
			hud:change(player, idx, "number", tcolor.hex)
		else
			local tmp = {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = evt.one,
				number        = tcolor.hex,
				offset        = {x = 145, y = -y_pos},
				alignment     = {x = -1, y = 0}
			}
			hud:add(player, idx, tmp)
		end
	else
		hud:remove(player, idx)
	end

	-- Victim
	if evt.two then
		local tcolor = ctf_colors.get_color(ctf.player(evt.two))
		if hud:exists(player, idx2) then
			hud:change(player, idx2, "text", evt.two)
			hud:change(player, idx2, "number", tcolor.hex)
		else
			local tmp = {
				hud_elem_type = "text",
				position      = {x = 0, y = 0.8},
				scale         = {x = 200, y = 100},
				text          = evt.two,
				number        = tcolor.hex,
				offset        = {x = 195, y = -y_pos},
				alignment     = {x = 1, y = 0}
			}
			hud:add(player, idx2, tmp)
		end
	else
		hud:remove(player, idx2)
	end

	-- Kill weapon
	if evt.image then
		if hud:exists(player, idxa) then
			hud:change(player, idxa, "text", evt.image)
		else
			local tmp = {
				hud_elem_type = "image",
				position      = {x = 0, y = 0.8},
				scale         = {x = 2, y = 2},
				text          = evt.image,
				offset        = {x = 170, y = -y_pos},
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
		for i = 1, NUM_EVT do
			local evt
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

ctf.register_on_killedplayer(function(victim, killer, stack, tool_caps)
	local sname = stack:get_name()

	-- If wielditem name is "" but there's a special `grenade`
	-- damage_group, then set the kill weapon to a grenade
	if sname == "" and tool_caps.damage_groups.grenade then
		sname = "shooter:grenade"
	end

	-- Get inventory image of kill weapon
	local image
	if sname == "" then
		image = "wieldhand.png"
	else
		local def = minetest.registered_items[sname]
		image = (def.inventory_image ~= "") and def.inventory_image
		if not image then
			if def.tiles[1] then
				local tile = def.tiles[1]
				image = (type(tile) == "table") and tile.name or tile
			else
				image = "ctf_events_fallback.png"
			end
		end
	end
	minetest.chat_send_all(image)

	ctf_events.post(image, killer, victim)
	ctf_events.update_all()
end)

minetest.register_on_joinplayer(function(player)
	ctf_events.update(player)
end)

ctf_match.register_on_new_match(function()
	ctf_events.events = {}
	ctf_events.update_all()
end)
