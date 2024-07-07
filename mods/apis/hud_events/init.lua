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

local hud_queues = {
	-- {}, channel 1
	-- {}, channel 2
	-- ...
}
local quick_event_timer = {}

minetest.register_on_leaveplayer(function(player)
	local pname = player:get_player_name()

	for channel=1, #hud_queues do
		if hud_queues[channel][pname] then
			hud_queues[channel][pname].t:cancel()
			hud_queues[channel][pname] = nil
		end
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
			offset = {x = 0, y = 20},
			alignment = {x = "center", y = "down"},
			text = huddef.text,
			color = huddef.color,
		})
	else
		hud:change(player, "hud_event_quick", {text = huddef.text, color = huddef.color})
	end

	if quick_event_timer[pname] then
		quick_event_timer[pname]:cancel()
	end
	quick_event_timer[pname] = minetest.after(HUD_SHOW_QUICK_TIME, function()
		if not player:is_player() then return end

		if hud:exists(player, "hud_event_quick") then
			hud:remove(player, "hud_event_quick")
		end
	end)
end

local function handle_hud_events(player, channel)
	local pname = player:get_player_name()

	local huddef = table.remove(hud_queues[channel][pname].e, 1)
	local event_name = "hud_event_"..tostring(channel)

	if not hud:exists(player, event_name) then
		hud:add(player, event_name, {
			hud_elem_type = "text",
			position = {x = 0.5, y = 0.5},
			offset = {x = 0, y = 45 + (channel - 1) * 25},
			alignment = {x = "center", y = "down"},
			text = huddef.text,
			color = huddef.color,
		})
	else
		hud:change(player, event_name, {
			text = huddef.text,
			color = huddef.color
		})
	end

	hud_queues[channel][pname].t = minetest.after(HUD_SHOW_TIME, function()
		player = minetest.get_player_by_name(pname)

		if player then
			hud:change(player, event_name, {text = ""})

			hud_queues[channel][pname].t = minetest.after(HUD_SHOW_NEXT_TIME, function()
				player = minetest.get_player_by_name(pname)

				if player then
					if #hud_queues[channel][pname].e >= 1 then
						handle_hud_events(player, channel)
					else
						hud:remove(player, event_name)
						hud_queues[channel][pname] = nil
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
		channel = an integer or nil
	})
]]
function hud_events.new(player, def)
	player = PlayerObj(player)
	if not player then return end

	if type(def) == "string" then
		def = {text = def}
	end

	def.channel = def.channel or 1

	if def.color then
		if type(def.color) == "string" then
			def.color = HUD_COLORS[def.color]
		end
	else
		def.color = 0x00D1FF
	end

	if not def.quick then
		local pname = player:get_player_name()

		while not hud_queues[def.channel] do
			table.insert(hud_queues, {})
		end

		if not hud_queues[def.channel][pname] then
			hud_queues[def.channel][pname] = {e = {}}
		end
		table.insert(hud_queues[def.channel][pname].e, {text = def.text, color = def.color, channel = def.channel})

		if not hud_queues[def.channel][pname].t then
			handle_hud_events(player, def.channel)
		end
	else
		show_quick_hud_event(player, def)
	end
end
