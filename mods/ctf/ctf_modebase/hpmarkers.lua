local hud = mhud.init()
local hpmarker_cooldown = ctf_core.init_cooldowns()
local hpmarkers = {}

local HPMARKER_LIFETIME = 20
local HPMARKER_RANGE = 150
local HPMARKER_PLACE_INTERVAL = 5

ctf_modebase.hpmarkers = {}

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

local function add_hpmarker(pname, pteam, message, pos, owner)
	if not hud:get(pname, "hpmarker_" .. owner) then
		hud:add(pname, "hpmarker_" .. owner, {
			hud_elem_type = "waypoint",
			world_pos = pos,
			precision = 1,
			color = 0x31e800,
			text = message
		})
	else
		hud:change(pname, "hpmarker_" .. owner, {
			world_pos = pos,
			text = message
		})
	end
end

function ctf_modebase.hpmarkers.remove(pname, no_notify)
	if hpmarkers[pname] then
		hpmarkers[pname].timer:cancel()

		for teammate in pairs(ctf_teams.online_players[hpmarkers[pname].team].players) do
			if not no_notify and teammate ~= pname then
				minetest.chat_send_player(teammate, minetest.colorize("#ABCDEF", "* " .. pname .. " removed a HP marker!"))
			end

			if hud:exists(teammate, "hpmarker_" .. pname) then
				hud:remove(teammate, "hpmarker_" .. pname)
			end
		end

		hpmarkers[pname] = nil
	end
end

function ctf_modebase.hpmarkers.add(pname, msg, pos, no_notify, specific_player)
	if not ctf_modebase.in_game then return end

	local pteam = ctf_teams.get(pname)
	if not pteam then return end

	if hpmarkers[pname] then
		hpmarkers[pname].timer:cancel()
	end

	minetest.log("action", string.format("%s placed a HP marker at %s: '%s'", pname, minetest.pos_to_string(pos), msg))

	hpmarkers[pname] = {
		msg = msg, pos = pos, team = pteam,
		timer = minetest.after(HPMARKER_LIFETIME, ctf_modebase.hpmarkers.remove, pname, true),
	}

	if specific_player then
		minetest.chat_send_player(specific_player, minetest.colorize("#ABCDEF", "* " .. pname .. " placed a HP marker for you!"))

		add_hpmarker(pname          , pteam, msg, pos, pname)
		add_hpmarker(specific_player, pteam, msg, pos, pname)
	else
		for teammate in pairs(ctf_teams.online_players[pteam].players) do
			if not no_notify and teammate ~= pname then
				minetest.chat_send_player(teammate, minetest.colorize("#ABCDEF", "* " .. pname .. " placed a HP marker!"))
			end

			add_hpmarker(teammate, pteam, msg, pos, pname)
		end
	end
end

ctf_teams.register_on_allocplayer(function(player, new_team, old_team)
	local pname = player:get_player_name()

	if old_team and old_team ~= new_team then
		ctf_modebase.hpmarkers.remove(pname, true)
		hud:remove(pname)
	end

	for owner, hpmarker in pairs(hpmarkers) do
		if hpmarker.team == new_team then
			add_hpmarker(pname, new_team, hpmarker.msg, hpmarker.pos, owner)
		end
	end
end)

ctf_api.register_on_match_end(function()
	for _, hpmarker in pairs(hpmarkers) do
		hpmarker.timer:cancel()
	end
	hpmarkers = {}
	hud:remove_all()
end)

local function hpmarker_func(name, param, specific_player)
	local pteam = ctf_teams.get(name)

	if hpmarker_cooldown:get(name) then
		return false, "You can only place a HP marker every "..HPMARKER_PLACE_INTERVAL.." seconds"
	end

	if not pteam then
		return false, "You need to be in a team to use HP markers!"
	end

	local player = minetest.get_player_by_name(name)
	local pos1 = vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0)

	if param == "" then
		param = "Look here!"
	end

	local ray = minetest.raycast(
		pos1, vector.add(pos1, vector.multiply(player:get_look_dir(), HPMARKER_RANGE),
		true, false
	))
	local pointed = ray:next()

	if pointed and pointed.type == "object" and pointed.ref == player then
		pointed = ray:next()
	end

	if not pointed then
		return false, "Can't find anything to mark, too far away!"
	end

	local message = string.format("m [%s]: Heal me! My HP is %i", name, player:get_hp())
	local pos

	if pointed.type == "object" then
		local concat
		local obj = pointed.ref
		local entity = obj:get_luaentity()

		if concat then
			message = message .. " <" .. concat .. ">"
		end
	else
		pos = pointed.under
	end

	ctf_modebase.hpmarkers.add(name, message, pos, nil, specific_player)

	hpmarker_cooldown:set(name, HPMARKER_PLACE_INTERVAL)

	return true, "HP marker is placed!"
end

minetest.register_chatcommand("hp", {
	description = "Place a HP marker in your look direction",
	params = "[message]",
	privs = {interact = true, shout = true},
	func = hpmarker_func
})

minetest.register_chatcommand("hpp", {
	description = "Place a HP marker in your look direction, for a specific player",
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
					return false, "You can't place a HP marker for yourself."
				end
			else
				return false, "The given player isn't on your team!"
			end
		else
			return false, "The given player isn't online!"
		end
	end
})

minetest.register_chatcommand("hpr", {
	description = "Remove your own HP marker",
	func = function(name, param)
		ctf_modebase.hpmarkers.remove(name)

		return true, "HP Marker is removed!"
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
			local hpmarker_text = false

			if hpmarker_text then
				local success, msg = hpmarker_func(player:get_player_name(), marker_text)

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
