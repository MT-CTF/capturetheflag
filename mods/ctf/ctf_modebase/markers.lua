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
			color = ctf_teams.team[pteam].color_hex,
			text = message
		})
	else
		hud:change(pname, "marker_" .. owner, {
			world_pos = pos,
			text = message
		})
	end
end

function ctf_modebase.markers.remove(pname, no_notify)
	if markers[pname] then
		markers[pname].timer:cancel()

		for teammate in pairs(ctf_teams.online_players[markers[pname].team].players) do
			if not no_notify and teammate ~= pname then
				minetest.chat_send_player(teammate, minetest.colorize("#ABCDEF", "* " .. pname .. " removed a marker!"))
			end

			hud:remove(teammate, "marker_" .. pname)
		end

		markers[pname] = nil
	end
end

function ctf_modebase.markers.add(pname, msg, pos, no_notify)
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

	for teammate in pairs(ctf_teams.online_players[pteam].players) do
		if not no_notify and teammate ~= pname then
			minetest.chat_send_player(teammate, minetest.colorize("#ABCDEF", "* " .. pname .. " placed a marker!"))
		end

		add_marker(teammate, pteam, msg, pos, pname)
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

local function marker_func(name, param)
	local pteam = ctf_teams.get(name)

	if marker_cooldown:get(name) then
		return false, "You can only place a marker every "..MARKER_PLACE_INTERVAL.." seconds"
	end

	if not pteam then
		return false, "You need to be in a team to use markers!"
	end

	local player = minetest.get_player_by_name(name)
	local pos1 = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)

	if param == "" then
		param = "Look here!"
	end

	local ray = minetest.raycast(
		pos1, vector.add(pos1, vector.multiply(player:get_look_dir(), MARKER_RANGE),
		true, false
	))
	local pointed = ray:next()

	if pointed and pointed.type == "object" and pointed.ref == player then
		pointed = ray:next()
	end

	if not pointed then
		return false, "Can't find anything to mark, too far away!"
	end

	local message = string.format("m [%s]: %s", name, param)
	local pos

	if pointed.type == "object" then
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

		pos = obj:get_pos()
		if concat then
			message = message .. " <" .. concat .. ">"
		end
	else
		pos = pointed.under
	end

	ctf_modebase.markers.add(name, message, pos)

	marker_cooldown:set(name, MARKER_PLACE_INTERVAL)

	return true, "Marker is placed!"
end

minetest.register_chatcommand("m", {
	description = "Place a marker in your look direction",
	privs = {interact = true, shout = true},
	func = marker_func
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

			if controls.LMB then
				marker_text = ""
			elseif controls.RMB then
				marker_text = "Defend!"
			end

			if marker_text then
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
