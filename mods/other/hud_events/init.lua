hud_events = {}

local hud = mhud.init()

local HUD_SHOW_TIME = 4
local HUD_SHOW_QUICK_TIME = 2
local HUD_SHOW_NEXT_TIME = 1

local HUD_COLORS = {
	primary = 0x0D6EFD,
	secondary = 0x6C757D,
	success = 0x198754,
	info = 0x0DCAF0,
	warning = 0xFFC107,
	danger = 0xDC3545,
	light = 0xF8F9FA,
	dark = 0x212529,
}

local hud_queues = {}
minetest.register_on_leaveplayer(function(player)
	hud:clear(player)
	hud_queues[player] = nil
end)

local function show_hud_event(player, huddef)
	local pname = player:get_player_name()

	if not hud:exists(player, "hud_event") then
		hud:add(player, "hud_event", {
			hud_elem_type = "text",
			position = {x = 0.5, y = 0.5},
			offset = {x = 0, y = 20},
			alignment = {x = "center", y = "down"},
			text = huddef.text,
			color = huddef.color,
		})
	else
		hud:change(player, "hud_event", {text = ""})

		minetest.after(HUD_SHOW_NEXT_TIME, function()
			player = minetest.get_player_by_name(pname)
			if not player then return end

			hud:change(player, "hud_event", {
				text = huddef.text,
				color = huddef.color
			})
		end)
	end
end

local quick_event_timer = {}
local function show_quick_hud_event(player, huddef)

	if not hud:exists(player, "hud_event_quick") then
		hud:add(player, "hud_event_quick", {
			hud_elem_type = "text",
			position = {x = 0.5, y = 0.5},
			offset = {x = 0, y = 45},
			alignment = {x = "center", y = "down"},
			text = huddef.text,
			color = huddef.color,
		})
	else
		hud:change(player, "hud_event_quick", {text = huddef.text, color = huddef.color})
	end

	quick_event_timer[player] = 0
end

local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	if timer >= 1 then
		for player, time in pairs(quick_event_timer) do
			time = time + timer

			if time >= HUD_SHOW_QUICK_TIME then
				hud:remove(player, "hud_event_quick")
				quick_event_timer[player] = nil
			else
				quick_event_timer[player] = time
			end
		end

		timer = 0
	end
end)

local function handle_hud_events(pname)
	local player = minetest.get_player_by_name(pname)
	if not player or not hud_queues[pname] then return end

	show_hud_event(player, table.remove(hud_queues[pname], 1))

	minetest.after(HUD_SHOW_TIME, function()
		player = minetest.get_player_by_name(pname)
		if not player or not hud_queues[pname] then return end

		if #hud_queues[pname] >= 1 then
			handle_hud_events(pname)
		else
			hud:remove(player, "hud_event")
			hud_queues[pname]._started = false
		end
	end)
end

function hud_events.new(player, def)
	player = PlayerObj(player)

	if not player then return end
	local pname = player:get_player_name()

	if not hud_queues[pname] then
		hud_queues[pname] = {_started = false}
	end

	if type(def) == "string" then
		def = {text = def}
	end

	if def.color then
		if type(def.color) == "string" then
			def.color = HUD_COLORS[def.color]
		end
	else
		def.color = 0x00D1FF
	end

	if not def.quick then
		table.insert(hud_queues[pname], {text = def.text, color = def.color})

		if not hud_queues[pname]._started then
			hud_queues[pname]._started = true
			handle_hud_events(pname)
		end
	else
		show_quick_hud_event(pname, def)
	end
end
