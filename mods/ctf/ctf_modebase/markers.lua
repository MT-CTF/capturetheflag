local markers = {}

local MARKER_LIFETIME = 20
local MARKER_RANGE = 150

for _, team in pairs(ctf_teams.teamlist) do
	markers[team] = {timer = nil, hud = mhud.init()}
end

local function add_marker(player, message, pos)
	local pteam = ctf_teams.get(player)

	if not pteam then return false end

	if not markers[pteam].hud:get(player, "team_waypoint") then
		markers[pteam].hud:add(player, "team_waypoint", {
			hud_elem_type = "waypoint",
			world_pos = pos,
			precision = 1,
			color = ctf_teams.team[pteam].color_hex,
			text = message
		})
	else
		markers[pteam].hud:change(player, "team_waypoint", {
			world_pos = pos,
			text = message
		})
	end
end

function ctf_modebase.remove_marker(team)
	markers[team].timer = nil
	markers[team].hud:clear_all()
	markers[team].content = nil
end

function ctf_modebase.add_marker(team, message, pos)
	markers[team].content = {msg = message, pos = pos}
	markers[team].timer = minetest.after(MARKER_LIFETIME, ctf_modebase.remove_marker, team)

	for player in pairs(ctf_teams.online_players[team].players) do
		add_marker(player, message, pos)
	end
end

ctf_teams.register_on_allocplayer(function(player, team)
	if markers[team].content then
		add_marker(player, markers[team].content.msg, markers[team].content.pos)
	end
end)

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

		ctf_modebase.add_marker(pteam, message, pos)

		return true, "Marker placed!"
	end
})
