local hud = mhud.init()
local markers = {}

local MARKER_LIFETIME = 20
local MARKER_RANGE = 150

ctf_modebase.markers = {}

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

function ctf_modebase.markers.remove(pname)
	if markers[pname] then
		markers[pname].timer.cancel()

		for teammate in pairs(ctf_teams.online_players[markers[pname].team].players) do
			hud:remove(teammate, "marker_" .. pname)
		end

		markers[pname] = nil
	end
end

function ctf_modebase.markers.add(pname, msg, pos)
	local pteam = ctf_teams.get(pname)
	if not pteam then return end

	if markers[pname] then
		markers[pname].timer.cancel()
	end

	markers[pname] = {
		msg = msg, pos = pos, team = pteam,
		timer = minetest.after(MARKER_LIFETIME, ctf_modebase.markers.remove, pname),
	}

	for teammate in pairs(ctf_teams.online_players[pteam].players) do
		add_marker(teammate, pteam, msg, pos, pname)
	end
end

ctf_teams.register_on_allocplayer(function(player, team)
	local pname = player:get_player_name()

	ctf_modebase.markers.remove(pname)
	hud:remove(pname)

	for teammate, marker in pairs(markers) do
		if marker.team == team then
			add_marker(pname, team, marker.msg, marker.pos, teammate)
		end
	end
end)

function ctf_modebase.markers.on_match_end()
	for _, marker in pairs(markers) do
		marker.timer():cancel()
	end
	markers = {}
	hud:remove_all()
end

minetest.register_chatcommand("m", {
	description = "Place a marker in your look direction",
	privs = {interact = true, shout = true},
	func = function(name, param)
		local pteam = ctf_teams.get(name)

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
					concat = itemdef.description or entity.itemstring
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

		return true, "Marker is placed!"
	end
})

minetest.register_chatcommand("mr", {
	description = "Remove your own marker",
	func = function(name, param)
		ctf_modebase.markers.remove(name)
		return true, "Marker is removed!"
	end
})
