local blacklist = {
	"ctf_ranged:smg",
	"ctf_ranged:smg_loaded",
	"ctf_ranged:rifle",
	"ctf_ranged:rifle_loaded",
	"ctf_ranged:sniper_magnum",
	"ctf_ranged:sniper_magnum_loaded",
	"ctf_mode_classes:ranged_rifle",
	"ctf_mode_classes:ranged_rifle_loaded"
}

ctf_settings.register("prevent_marker_placement", {
	type = "bool",
	label = "Prevent automatic marker placement while sniping",
	description = "Prevent placement of markers while holding ranged weapons,\nthis exludes the shotgun and pistol.",
	default = "true"
})

local hud = mhud.init()
local marker_cooldown = ctf_core.init_cooldowns()
local markers = {}

local MARKER_LIFETIME = 20
local MARKER_RANGE = 150
local MARKER_PLACE_INTERVAL = 5

ctf_modebase.markers = {}

-- Code taken from mods/mtg/mtg_binoculars, changed default FOV
function binoculars.update_player_property(player)
	local new_zoom_fov = 84

	if player:get_inventory():contains_item(
			"main", "binoculars:binoculars") then
		new_zoom_fov = 10
	elseif minetest.is_creative_enabled(player:get_player_name()) then
		new_zoom_fov = 15
	end

	-- Only set property if necessary to avoid player mesh reload
	if player:get_properties().zoom_fov ~= new_zoom_fov then
		player:set_properties({zoom_fov = new_zoom_fov})
	end
end

local function add_marker(pname, pteam, message, pos, owner)
	if not hud:get(pname, "marker_" .. owner) then
		hud:add(pname, "marker_" .. owner, {
			hud_elem_type = "waypoint",
			world_pos = pos,
			precision = 1,
			color = 0x31e800,
			text = message
		})
	else
		hud:change(pname, "marker_" .. owner, {
			world_pos = pos,
			text = message
		})
	end
end

local function check_pointed_entity(pointed, message)
	local concat
	local obj = pointed.ref
	local entity = obj:get_luaentity()
	-- If object is a player, append player name to display text
	-- Else if obj is item entity, append item description and count to str.
	if obj:is_player() then
		concat = obj:get_player_name()
	elseif entity then
		if entity.name == "__builtin:item" then
			local stack = ItemStack(entity.itemstring)
			local itemdef = minetest.registered_items[stack:get_name()]
			-- Fallback to itemstring if description doesn't exist
			-- Only use first line of itemstring
			concat = string.match(itemdef.description or entity.itemstring, "^([^\n]+)")
			concat = concat .. " " .. stack:get_count()
		end
	end
	local pos = obj:get_pos()
	if concat then
		message = message .. " <" .. concat .. ">"
	end
	return message, pos
end

function ctf_modebase.markers.remove(pname, no_notify)
	if markers[pname] then
		markers[pname].timer:cancel()

		for teammate in pairs(ctf_teams.online_players[markers[pname].team].players) do
			if not no_notify and teammate ~= pname then
				minetest.chat_send_player(teammate, minetest.colorize("#ABCDEF", "* " .. pname .. " removed a marker!"))
			end

			if hud:exists(teammate, "marker_" .. pname) then
				hud:remove(teammate, "marker_" .. pname)
			end
		end

		markers[pname] = nil
	end
end

function ctf_modebase.markers.add(pname, msg, pos, no_notify, specific_player)
	if not ctf_modebase.in_game then return end

	local pteam = ctf_teams.get(pname)
	if not pteam then return end

	if markers[pname] then
		markers[pname].timer:cancel()
	end

	minetest.log("action", string.format("%s placed a marker at %s: '%s'", pname, minetest.pos_to_string(pos), msg))

	markers[pname] = {
		msg = msg, pos = pos, team = pteam,
		timer = minetest.after(MARKER_LIFETIME, ctf_modebase.markers.remove, pname, true),
	}

	if specific_player then
		minetest.chat_send_player(specific_player, minetest.colorize("#ABCDEF", "* " .. pname .. " placed a marker for you!"))

		add_marker(pname          , pteam, msg, pos, pname)
		add_marker(specific_player, pteam, msg, pos, pname)
	else
		for teammate in pairs(ctf_teams.online_players[pteam].players) do
			if not no_notify and teammate ~= pname then
				minetest.chat_send_player(teammate, minetest.colorize("#ABCDEF", "* " .. pname .. " placed a marker!"))
			end

			add_marker(teammate, pteam, msg, pos, pname)
		end
	end
end

ctf_teams.register_on_allocplayer(function(player, new_team, old_team)
	local pname = player:get_player_name()

	if old_team and old_team ~= new_team then
		ctf_modebase.markers.remove(pname, true)
		hud:remove(pname)
	end

	for owner, marker in pairs(markers) do
		if marker.team == new_team then
			add_marker(pname, new_team, marker.msg, marker.pos, owner)
		end
	end
end)

ctf_api.register_on_match_end(function()
	for _, marker in pairs(markers) do
		marker.timer:cancel()
	end
	markers = {}
	hud:remove_all()
end)

local function marker_func(name, param, specific_player, hpmarker)
	local pteam = ctf_teams.get(name)

	if marker_cooldown:get(name) then
		return false, "You can only place a marker every "..MARKER_PLACE_INTERVAL.." seconds"
	end

	if not pteam then
		return false, "You need to be in a team to use markers!"
	end

	local player = minetest.get_player_by_name(name)
	local message
	local pos
	local pos1 = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)
	if param == "" then
		param = "Look here!"
	elseif string.len(param) > 40 then
		param = string.sub(param, 1, 40)
	end

	local ray = minetest.raycast(
		pos1, vector.add(pos1, vector.multiply(player:get_look_dir(), MARKER_RANGE),
		true, false
	))
	local pointed = ray:next()

	if pointed and pointed.type == "object" and pointed.ref == player then
		pointed = ray:next()
	end

	if pointed and vector.distance(
		pointed.under or pointed.ref:get_pos(),
		player:get_pos()
	) <= 2 then
		hpmarker = true
	end

	if pointed and hpmarker == true then
		local player_hpr = string.format("HP: %i/%i", player:get_hp(),
		player:get_properties().hp_max)
		message = string.format("m [%s]: ", name) .. player_hpr
		if vector.distance(
			pointed.under or pointed.ref:get_pos(),
			player:get_pos()
		) <= 2 then
			pos = pointed.under or pointed.ref:get_pos()
		else
			pos = player:get_pos()
		end
		if pointed then
			if pointed.type == "object" then
				message, pos = check_pointed_entity(pointed, message, pos)
			end
		end
		if param ~= "Look here!" then
			message = string.format("[HP: %i/%i] %s", player:get_hp(),
			player:get_properties().hp_max, param)
		end

		-- If the player places a marker upon death, it will resort to the below
		if player:get_hp() == 0 then
			message = string.format("m <%s> died here", name)
			if param ~= "Look here!" then message = string.format(
				"m [%s]: %s", name, param
			)
			end
		end
	else
		if not pointed then
			return false, "Can't find anything to mark, too far away!"
		end
		message = string.format("m [%s]: %s", name, param)
		if pointed.type == "object" then
			message, pos = check_pointed_entity(pointed, message)
		else
			pos = pointed.under
		end
	end

	ctf_modebase.markers.add(name, message, pos, nil, specific_player)
	marker_cooldown:set(name, MARKER_PLACE_INTERVAL)
	if hpmarker then
		return true, "HP marker is placed!"
	else
		return true, "Marker is placed!"
	end
end


minetest.register_chatcommand("mhp", {
	description = "Place a HP marker in your look direction",
	params = "",
	privs = {interact = true, shout = true},
	func = function(name, param)
		return marker_func(name, param, nil, true)
	end
})

minetest.register_chatcommand("m", {
	description = "Place a marker in your look direction",
	params = "[message]",
	privs = {interact = true, shout = true},
	func = marker_func
})

minetest.register_chatcommand("mp", {
	description = "Place a marker in your look direction, for a specific player",
	params = "<player> [message]",
	privs = {interact = true, shout = true},
	func = function(name, params)
		local pteam = ctf_teams.get(name)

		if not pteam then
			return false, "You aren't in a team!"
		end

		params = string.split(params, " ", false, 1)

		if params[1] and minetest.get_player_by_name(params[1]) then
			if (ctf_teams.get(params[1]) or "") == pteam then
				if name ~= params[1] then
					return marker_func(name, params[2] or "", params[1])
				else
					return false, "You can't place a marker for yourself."
				end
			else
				return false, "The given player isn't on your team!"
			end
		else
			return false, "The given player isn't online!"
		end
	end
})

minetest.register_chatcommand("mr", {
	description = "Remove your own marker",
	func = function(name, param)
		ctf_modebase.markers.remove(name)

		return true, "Marker is removed!"
	end
})

local check_interval = 0.3
local timer = 0
minetest.register_globalstep(function(dtime)
	timer = timer + dtime

	if timer < check_interval then return end
	timer = 0

	for _, player in pairs(minetest.get_connected_players()) do
		local controls = player:get_player_control()

		if controls.zoom then
			local marker_text = false
			local stackname = player:get_wielded_item():get_name()

			local holding_blacklisted_item = false
			if ctf_settings.get(player, "prevent_marker_placement") == true then
				for _, itemstring in ipairs(blacklist) do
					if stackname:match(itemstring) then
						holding_blacklisted_item = true
						break
					end
				end
			end

			if controls.LMB then
				marker_text = ""
			elseif controls.RMB then
				marker_text = "Defend!"
			end

			if marker_text  and not holding_blacklisted_item then
				local success, msg = marker_func(player:get_player_name(), marker_text)

				if not success and msg then
					hud_events.new(player, {
						text = msg,
						color = "warning",
						quick = true,
					})
				end
			end
		end
	end
end)
