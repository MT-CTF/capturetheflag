hud_events = {}

local hud = mhud.init()

local HUD_SHOW_TIME = 3
local HUD_SHOW_QUICK_TIME = 2
local HUD_SHOW_NEXT_TIME = 0.6

local HUD_COLORS = {
	primary = 0x0D6EFD,
	secondary = 0x6C757D,
	success = 0x20bf5c,
	info = 0x0DCAF0,
	warning = 0xFFC107,
	danger = 0xDC3545,
	light = 0xF8F9FA,
	dark = 0x212529,
}

local hud_queues = {}
local quick_event_timer = {}

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	if hud_queues[pname] then
		hud_queues[pname].t:cancel()
		hud_queues[pname] = nil
	end

	if quick_event_timer[pname] then
		quick_event_timer[pname]:cancel()
		quick_event_timer[pname] = nil
	end
end)

local function show_quick_hud_event(player, huddef)
	local pname = player:get_player_name()

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

	if quick_event_timer[pname] then
		quick_event_timer[pname].cancel()
	end
	quick_event_timer[pname] = minetest.after(HUD_SHOW_QUICK_TIME, function()
		if not player:is_player() then return end

		hud:remove(player, "hud_event_quick")
	end)
end

local function handle_hud_events(player)
	local pname = player:get_player_name()

	local huddef = table.remove(hud_queues[pname].e, 1)

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
		hud:change(player, "hud_event", {
			text = huddef.text,
			color = huddef.color
		})
	end

	hud_queues[pname].t = minetest.after(HUD_SHOW_TIME, function()
		player = minetest.get_player_by_name(pname)

		if player then
			hud:change(player, "hud_event", {text = ""})

			hud_queues[pname].t = minetest.after(HUD_SHOW_NEXT_TIME, function()
				player = minetest.get_player_by_name(pname)

				if player then
					if #hud_queues[pname].e >= 1 then
						handle_hud_events(player)
					else
						hud:remove(player, "hud_event")
						hud_queues[pname] = nil
					end
				end
			end)
		end
	end)
end

--[[
	hud_events.new(player, {
		text = "This is a hud event",
		color = "info",
		quick = true,
	})
]]
function hud_events.new(player, def)
	player = PlayerObj(player)
	if not player then return end

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
		local pname = player:get_player_name()

		if not hud_queues[pname] then
			hud_queues[pname] = {e = {}}
		end
		table.insert(hud_queues[pname].e, {text = def.text, color = def.color})

		if not hud_queues[pname].t then
			handle_hud_events(player)
		end
	else
		show_quick_hud_event(player, def)
	end
end
